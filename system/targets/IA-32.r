REBOL [
	Title:   "Red/System IA-32 code emitter"
	Author:  "Nenad Rakocevic"
	File: 	 %IA-32.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

make-profilable make target-class [
	target: 'IA-32
	little-endian?: yes
	struct-align-size: 	4
	ptr-size: 			4
	default-align:		4
	stack-width:		4
	stack-slot-max:		8							;-- size of biggest datatype on stack (float64!)
	args-offset:		8							;-- stack frame offset to arguments (ebp + ret-addr)
	branch-offset-size:	4							;-- size of JMP offset
	locals-offset:		8							;-- offset from frame pointer to local variables (catch ID + addr)
	
	fpu-cword: none									;-- x87 control word reference in emitter/symbols
	fpu-flags: to integer! #{037A}					;-- default control word, division by zero
													;-- and invalid operands raise exceptions.
	conditions: make hash! [
	;-- name ----------- signed --- unsigned --
		overflow?		 #{00}		-
		not-overflow?	 #{01}		-	
		=				 #{04}		-
		<>				 #{05}		-
		signed?			 #{08}		-
		unsigned?		 #{09}		-
		even?			 #{0A}		-
		odd?			 #{0B}		-
		<				 #{0C}		#{02}
		>=				 #{0D}		#{03}
		<=				 #{0E}		#{06}
		>				 #{0F}		#{07}
	]
	
	patch-floats-definition: func [mode [word!] /local value][
		value: pick [unsigned signed] mode = 'set
		foreach w [float! float64! float32!][
			poke find emitter/datatypes w 3 value	;-- force unsigned comparisons (x87 FPU specific)
		]
	]
	
	on-init: has [offset][
		if PIC? [
			offset: emit-get-pc/ebx
			emit #{83EB}							;-- SUB ebx, <offset>	; adjust to beginning of CODE segment
			emit to-bin8 offset
		]	
	]
	
	on-global-prolog: func [runtime? [logic!] type [word!] /local offset][
		patch-floats-definition 'set
		if runtime? [
			if type = 'exe [emit-fpu-init]
			fpu-cword: emitter/store-value none fpu-flags [integer!]
		]
	]
	
	on-global-epilog: func [runtime? [logic!] type [word!]][
		if runtime? [patch-floats-definition 'unset] ;-- restore definitions for next compilation jobs
		if all [
			not runtime?
			compiler/job/need-main?
		][
			emit #{89EC}							;-- MOV esp, ebp
			emit-pop								;-- pop exceptions threshold slot
			emit-pop								;-- pop exceptions address slot
			emit #{5D}								;-- POP ebp
			args: switch/default compiler/job/OS [
				Syllable [6]
			][7]
			emit-epilog '***_start [] args * 4 0	;-- restore all before returning in __libc_start_main()
		]
	]
	
	add-condition: func [op [word!] data [binary!]][
		op: either '- = third op: find conditions op [op/2][
			pick op pick [2 3] signed?
		]
		data/(length? data): (to char! last data) or (to char! first op) ;-- REBOL2's awful binary! handling
		data
	]
	
	adjust-disp32: func [lcode [binary! block!] offset [binary!] /local code byte][
		if 4 = length? offset [
			lcode: copy/deep lcode
			code: either block? lcode [first back find lcode 'offset][lcode]
			change byte: back tail code byte xor #{C0}	;-- switch to 32-bit displacement mode
		]
		lcode
	]

	emit-variable: func [
		name  [word! object!] 
		gcode [binary! block! none!]					;-- global opcodes
		pcode [binary! block! none!]					;-- PIC opcodes
		lcode [binary! block!] 							;-- local opcodes
		/local offset byte code spec
	][
		if object? name [name: compiler/unbox name]
		
		case [
			offset: emitter/local-offset? name [
				offset: stack-encode offset 			;-- local variable case
				either block? lcode: adjust-disp32 lcode offset [
					emit reduce bind lcode 'offset
				][
					emit lcode
					emit offset
				]
			]
			PIC? [										;-- global variable case (PIC version)
				spec: emitter/symbols/:name
				either spec/1 = 'import-var [
					emit #{8BB3}					;-- MOV esi, [ebx+<import disp>]
					emit-reloc-addr spec
					emit (#{FF7E} and copy pcode) or #{0004} ;-- [ebx+<disp>] => [esi]
				][
					either block? pcode [
						foreach code reduce pcode [
							either code = 'address [
								emit-reloc-addr spec
							][
								emit code
							]
						]
					][
						emit pcode
						emit-reloc-addr spec
					]
				]
			]
			'global [									;-- global variable case
				spec: emitter/symbols/:name
				either spec/1 = 'import-var [
					emit #{8B3D}					;-- MOV edi, [<import>]
					emit-reloc-addr spec
					emit (#{FF7E} and copy pcode) or #{0005} ;-- [ebx+<disp>] => [edi]
				][
					either block? gcode [
						foreach code reduce gcode [
							either code = 'address [
								emit-reloc-addr spec
							][
								emit code
							]
						]
					][
						emit gcode
						emit-reloc-addr spec
					]
				]
			]
		]
	]
	
	emit-float: func [opcode [binary!]][
		emit either width = 4 [opcode and #{F9FF}][opcode]
	]

	emit-float-arg: func [arg opcode [binary!]][
		emit switch/default first compiler/get-type arg [
			float32! [opcode and #{F9FF}]
			integer! [opcode and #{F0FF} or #{0B00}]
		][
			opcode
		]
	]	
	emit-float-variable: func [
		name [word! object!] gcode [binary!] pcode [binary!] lcode [binary!]
		/local codes type
	][
		codes: [gcode pcode lcode]
		switch type: first compiler/get-type name [
			float32! [foreach c codes [set c (get c) and #{F9FF}]]
			integer! [foreach c codes [set c (get c) and #{F0FF} or #{0B00}]]
		]
		emit-variable name gcode pcode lcode
		type
	]
	
	load-float-variable: func [name [word! object!]][
		emit-float-variable name
			#{DD05}									;-- FLD [value]			; global
			#{DD83}									;-- FLD [ebx+disp]		; PIC
			#{DD45}									;-- FLD [ebp+n]			; local
	]
	
	store-float-variable: func [name [word! object!]][
		emit-float-variable name
			#{DD1D}									;-- FSTP [name]			; global
			#{DD9B}									;-- FSTP [ebx+disp]		; PIC
			#{DD5D}									;-- FSTP [ebp+n]		; local
	]
		
	emit-poly: func [spec [block!] /local w to-bin][	;-- polymorphic code generation
		spec: reduce spec
		w: either width = 8 [4][width]				;-- use splitted 32-bit access for 64-bit word
		emit switch w [
			1 [spec/1]								;-- 8-bit
			2 [emit #{66} spec/2]					;-- 16-bit
			4 [spec/2]								;-- 32-bit
		]
		to-bin: get select [1 to-bin8 2 to-bin16 4 to-bin32] w
		case/all [
			2 < length? spec [emit to-bin to integer! compiler/unbox spec/3] ;-- emit displacement or immediate
			3 < length? spec [emit to-bin to integer! compiler/unbox spec/4] ;-- emit displacement or immediate
		]	
	]
	
	emit-variable-poly: func [							;-- polymorphic variable access generation
		name [word! object!]
		    g8 [binary!] 		g32 [binary!]			;-- opcodes for global variables
		    p8 [binary!] 		p32 [binary!]			;-- opcodes for global variables (PIC)
			l8 [binary! block!] l32 [binary! block!]	;-- opcodes for local variables
	][
		with-width-of name [
			switch width [
				1 [emit-variable name g8 p8 l8]					;-- 8-bit
				2 [emit #{66} emit-variable name g32 p32 l32]	;-- 16-bit
				4 [emit-variable name g32 p32 l32]				;-- 32-bit
			]
		]
	]
	
	emit-indirect-call: func [spec [block!]][
		either PIC? [
			emit #{8B83}							;-- MOV eax, [ebx+disp]	; PIC
			emit-reloc-addr spec
			emit #{FFD0} 							;-- CALL eax
		][
			emit #{FF15}							;-- CALL FAR [addr]		; global
			emit-reloc-addr spec
		]
	]
	
	emit-alloc-stack: does [
		emit #{29C4}								;-- SUB esp, eax
		emit #{83E4FC}								;-- AND esp, -4		; align to lower bound
	]
	
	emit-free-stack: does [
		emit #{F7D8}								;-- NEG eax
		emit #{83E0FC}								;-- AND eax, -4
		emit #{F7D8}								;-- NEG eax			; align to upper bound
		emit #{01C4}								;-- ADD esp, eax
	]
	
	emit-reserve-stack: func [slots [integer!] /local size][
		size: slots * stack-width
		either size > 127 [
			emit #{81EC}							;-- SUB esp, bytes	; 32-bit displacement
			emit to-bin32 size
		][
			emit #{83EC}							;-- SUB esp, bytes	; 8-bit displacement
			emit to-bin8 size
		]
	]
	
	emit-release-stack: func [slots [integer!] /bytes /local size][
		size: either bytes [slots][slots * stack-width]
		either size > 127 [
			emit #{81C4}							;-- ADD esp, bytes	; 32-bit displacement
			emit to-bin32 size
		][
			emit #{83C4}							;-- ADD esp, bytes	; 8-bit displacement
			emit to-bin8 size
		]		
	]
	
	emit-move-path-alt: does [
		emit #{89C2}								;-- MOV edx, eax
	]
	
	emit-save-last: does [
		last-saved?: yes
		unless compiler/any-float? compiler/last-type [
			emit #{50}								;-- PUSH eax
		]
	]
	
	emit-restore-last: does [
		unless find [float! float64! float32!] compiler/last-type/1 [
			emit #{5A}					   			;-- POP edx
		]
	]
	
	emit-casting: func [value [object!] alt? [logic!] /push /local type old][
		type: compiler/get-type value/data	
		case [
			value/type/1 = 'logic! [
				if verbose >= 3 [print [">>>converting from" mold/flat type/1 "to logic!"]]
				old: width
				set-width/type type/1
				emit #{31FF}						;--		   XOR edi, edi
				either alt? [
					emit-poly [#{80FA00} #{83FA00}]	;-- 	   CMP rD, 0
					emit #{7401}					;--        JZ _exit
					emit #{47}						;-- 	   INC edi
					emit #{89FA}					;-- _exit: MOV edx, edi
				][
					emit-poly [#{3C00} #{83F800}]	;-- 	   CMP rA, 0
					emit #{7401}					;--        JZ _exit
					emit #{47}						;-- 	   INC edi
					emit #{89F8}					;-- _exit: MOV eax, edi
				]
				width: old
			]
			all [value/type/1 = 'integer! type/1 = 'byte!][
				if verbose >= 3 [print ">>>converting from byte! to integer! "]
				emit pick [#{81E2} #{25}] alt?    	;-- AND edx|eax, 000000FFh 
				emit to-bin32 255
			]
			all [value/type/1 = 'integer! find [float! float64! float32!] type/1][
				if verbose >= 3 [print [">>>converting from" type/1 "to integer!"]]
				emit #{83EC04}						;-- SUB esp, 4
				either compiler/job/cpu-version >= 4.0 [ ;-- Only CPUs with SSE3, >= Pentium 4
					emit #{DB0C24}					;-- FISTTP dword [esp]	; save as 32-bit truncated
				][
					emit-push to integer! #{0E7F}	;-- set FPU_X87_ROUNDING_ZERO mode
					emit #{D92C24}					;-- FLDCW [esp]
					emit #{83C404}					;-- ADD esp, 4			; free space
					emit #{DB1C24}					;-- FISTP dword [esp]	; save as 32-bit
					emit #{D92D}					;-- FLDCW [<word>]	 	; global
					emit-reloc-addr fpu-cword/2		;-- one-based index
				]
				unless push [
					either alt? [
						emit #{5A}					;-- POP edx
					][
						emit #{58}					;-- POP eax
					]
				]
			]
			all [value/type/1 = 'float32! type/1 = 'integer!][
				if verbose >= 3 [print ">>>converting from integer! to float32!"]
				either alt? [
					emit #{52}						;-- PUSH edx
				][
					emit #{50}						;-- PUSH eax
				]
				emit #{DB0424}						;-- FILD dword [esp]	; load as 32-bit
				either push [
					emit #{D91C24}					;-- FSTP dword [esp]	; save as 32-bit
				][
					emit #{83C404}					;-- ADD esp, 4			; free space
				]
			]
			all [find [float! float64!] value/type/1 type/1 = 'integer!][
				if verbose >= 3 [print ">>>converting from integer! to float!"]
				either alt? [
					emit #{52}						;-- PUSH edx
				][
					emit #{50}						;-- PUSH eax
				]
				emit #{DB0424}						;-- FILD dword [esp]	; load as 32-bit
				either push [
					emit #{83EC04}					;-- SUB esp, 4			; alloc more space for 64-bit float
					emit #{DD1C24}					;-- FSTP qword [esp]	; save as 64-bit
				][
					emit #{83C404}					;-- ADD esp, 4			; free space
				]
			]
			all [find [float! float64!] value/type/1 type/1 = 'float32!][
				if verbose >= 3 [print ">>>converting from float32! to float!"]
				emit #{83EC08}						;-- SUB esp, 8			; alloc space for 64-bit float
				emit #{DD1C24}						;-- FSTP qword [esp]	; save as 64-bit
				emit #{DD0424}						;-- FLD qword [esp]		; load as 64-bit
				emit #{83C408}						;-- ADD esp, 8			; free space
			]
			all [value/type/1 = 'float32! find [float! float64!] type/1][
				if verbose >= 3 [print ">>>converting from float! to float32!"]
				emit #{83EC04}						;-- SUB esp, 4			; alloc space for 32-bit float
				emit #{D91C24}						;-- FSTP dword [esp]	; save as 32-bit
				emit #{D90424}						;-- FLD dword [esp]		; load as 32-bit
				emit #{83C404}						;-- ADD esp, 4			; free space
			]
		]
	]

	emit-load-literal: func [type [block! none!] value /local spec][	
		unless type [type: compiler/get-type value]
		spec: emitter/store-value none value type
		either PIC? [
			emit #{8D83}							;-- LEA eax, [ebx+disp] ; PIC
		][
			emit #{B8}								;-- MOV eax, value		; global
		]
		emit-reloc-addr spec/2						;-- one-based index
	]
	
	emit-load-literal-ptr: func [spec [block!]][
		emit #{8D83}								;-- LEA eax, [ebx+disp] ; PIC
		emit-reloc-addr spec
	]
	
	emit-fpu-get: func [
		/type
		/options option [word!]
		/masks mask [word!]
		/cword
		/local value bit 
	][
		unless type [
			either PIC? [
				emit #{8B83}						;-- MOV eax, [ebx+disp]	 ; PIC
			][
				emit #{A1}							;-- MOV eax, [fpu-cword] ; global
			]
			emit-reloc-addr fpu-cword/2				;-- one-based index
		]
		case [
			type [
				; hardcoded value for now (FPU_X87)
				emit #{31C0}						;--	XOR eax, eax
				emit #{40}							;--	INC eax				; eax: 1
			]								
			options [
				emit #{25}							;-- AND eax, <value>
				set [value bit] switch/default option [
					rounding  [[#{00000C00} 10]]
					precision [[#{00000300} 8]]
				][
					compiler/throw-error ["invalid FPU option name:" option]
				]
				emit reverse copy value
			]
			masks [
				bit: switch/default mask [
					precision	[5]
					underflow	[4]
					overflow	[3]
					zero-divide [2]
					denormal	[1]
					invalid-op  [0]
				][
					compiler/throw-error ["invalid FPU mask name:" mask]
				]
				emit #{25}							;-- AND eax, 2^bit
				emit to-bin32 shift/left 1 bit
			]
			;cword []								;-- control word is already in eax
		]
		unless any [type cword][					;-- align result on right side
			emit #{C1E8}							;-- SHR eax, <bit>
			emit to-bin8 bit
		]
	]
	
	emit-access-register: func [reg [word!] set? [logic!] value /local opcode][
		if verbose >= 3 [print [">>>emitting ACCESS-REGISTER" mold value]]
		if all [set? not tag? value][emit-load value]
		
		unless reg = 'eax [
			opcode: #"^(C0)"
			reg: (index? find [eax ecx edx ebx esp ebp esi edi] reg) - 1
			unless set? [reg: shift/left reg 3]
			emit join #{89} opcode or reg			;-- MOV <reg>, eax	; set
		]											;-- MOV eax, <reg>	; get
	]
	
	emit-fpu-set: func [
		value
		/options option [word!]
		/masks mask [word!]
		/cword
		/local bit
	][
		value: to integer! value	
		unless cword [
			either PIC? [
				emit #{8B83}						;-- MOV eax, [ebx+disp]	 ; PIC
			][
				emit #{A1}							;-- MOV eax, [fpu-cword] ; global
			]
			emit-reloc-addr fpu-cword/2				;-- one-based index
			emit #{25}								;-- AND eax, 2^bit
		]
		case [
			options [
				set [mask bit] switch/default option [
					rounding  [[#{00000C00} 10]]
					precision [[#{00000300} 8]]
				][
					compiler/throw-error ["invalid FPU option name:" option]
				]
				emit reverse complement mask
			]
			masks [
				bit: switch/default mask [
					precision	[5]
					underflow	[4]
					overflow	[3]
					zero-divide [2]
					denormal	[1]
					invalid-op  [0]
				][
					compiler/throw-error ["invalid FPU mask name:" mask]
				]
				emit to-bin32 complement shift/left 1 bit
			]
		]
		either cword [
			emit #{B8}								;-- MOV eax, <value>
		][
			value: shift/left value bit
			emit #{0D}								;-- OR eax, <value>	
		]
		emit to-bin32 value
		
		either PIC? [
			emit #{8983}							;-- MOV [ebx+disp], eax	  ; PIC
		][
			emit #{A3}								;-- MOV [fpu-cword], eax  ; global
		]
		emit-reloc-addr fpu-cword/2					;-- one-based index
	]
	
	emit-fpu-update: does [
		either PIC? [								;-- load 16-bit control word
			emit #{D9AB}							;-- FLDCW [ebx+disp]	; PIC
		][
			emit #{D92D}							;-- FLDCW <word>	 	; global
		]
		emit-reloc-addr fpu-cword/2					;-- one-based index
	]
	
	emit-fpu-init: does [
		emit #{9BDBE3}								;-- FINIT			; init x87 FPU
	]
	
	emit-get-overflow: does [
		emit #{0F90C0}								;-- SETO al
		emit #{83E001}								;-- AND eax, 1
	]
	
	emit-get-pc: func [/ebx][
		emit #{E800000000}							;-- CALL next		; call the next instruction
		either ebx [
			emit #{5B}								;-- POP ebx			; get eip in ebx
		][
			emit-pop								;-- get eip in eax
		]
		5											;-- return adjustment offset (CALL size)
	]
	
	emit-set-stack: func [value /frame][
		if verbose >= 3 [print [">>>emitting SET-STACK" mold value]]
		unless tag? value [emit-load value]
		either frame [
			emit #{89C5}							;-- MOV ebp, eax		
		][
			emit #{89C4}							;-- MOV esp, eax
		]
	]
	
	emit-get-stack: func [/frame][
		if verbose >= 3 [print ">>>emitting GET-STACK"]
		either frame [
			emit #{89E8}							;-- MOV eax, ebp			
		][
			emit #{89E0}							;-- MOV eax, esp
		]
	]
	
	emit-pop: does [
		if verbose >= 3 [print ">>>emitting POP"]
		emit #{58}									;-- POP eax
	]

	emit-log-b: func [type][
		if type = 'byte! [emit #{25FF000000}]		;-- AND eax, 0xFF
		emit #{0FBDC0}								;-- BSR eax, eax
	]

	emit-not: func [value [word! char! tag! integer! logic! path! string! object!] /local opcodes type boxed][
		if verbose >= 3 [print [">>>emitting NOT" mold value]]
		
		if object? value [boxed: value]
		value: compiler/unbox value
		if block? value [value: <last>]

		opcodes: [
			logic!	 [emit #{3401}]					;-- XOR al, 1			; invert 0<=>1
			byte!	 [emit #{F6D0}]					;-- NOT al				; @@ missing 16-bit support									
			integer! [emit #{F7D0}]					;-- NOT eax
		]
		switch type?/word value [
			logic! [
				emit-load not value
			]
			char! [
				emit-load value
				do opcodes/byte!
			]
			integer! [
				emit-load value
				do opcodes/integer!
			]
			word! [
				emit-load value
				type: either boxed [
					emit-casting boxed no
					boxed/type/1
				][
					first compiler/resolve-aliased compiler/get-variable-spec value
				]
				if find [pointer! c-string! struct!] type [ ;-- type casting trap
					type: 'logic!
				]
				switch type opcodes
			]
			tag! [
				if boxed [
					emit-casting boxed no
					compiler/last-type: boxed/type
				]
				switch compiler/last-type/1 opcodes
			]
			string! [								;-- type casting trap
				emit-load value
				if boxed [emit-casting boxed no]
				do opcodes/logic!
			]
			path! [
				emitter/access-path value none
				either boxed [
					emit-casting boxed no
					switch boxed/type/1 opcodes 
				][
					type: compiler/resolve-path-type value
					compiler/last-type: type
					switch type/1 opcodes
				]
			]
		]
	]
	
	emit-boolean-switch: does [
		emit #{31C0}								;-- 	  XOR eax, eax	; eax = 0 (FALSE)
		emit #{EB03}								;-- 	  JMP _exit
		emit #{31C0}								;--		  XOR eax, eax
		emit #{40}									;--		  INC eax		; eax = 1 (TRUE)
													;-- _exit:
		reduce [3 7]								;-- [offset-TRUE offset-FALSE]
	]
	
	emit-load: func [
		value [char! logic! integer! word! string! path! paren! get-word! object! decimal!]
		/alt
		/with cast [object!]
		/local offset spec
	][
		if verbose >= 3 [print [">>>loading" mold value]]
		alt: to logic! alt
		
		switch type?/word value [
			char! [
				emit #{B0}							;-- MOV al, value
				emit value
			]
			logic! [
				emit #{31C0}						;-- XOR eax, eax		; eax = 0 (FALSE)	
				if value [
					emit #{40}						;-- INC eax				; eax = 1 (TRUE)
				]
			]
			integer! [
				emit #{B8}							;-- MOV eax, value
				emit to-bin32 value
			]
			decimal! [
				set-width any [cast value]
				emit-push any [cast value]
				emit-float #{DD0424}				;-- FLD [esp]
				emit #{83C4} 						;-- ADD esp, 8|4
				emit to-bin8 pick [4 8] to logic! all [cast cast/type/1 = 'float32!]
			]
			word! [
				with-width-of value [
					case [
						compiler/any-float? compiler/get-variable-spec value [
							load-float-variable value
						]
						all [
							offset: emitter/local-offset? value
							'value = last select compiler/locals value
						][							;-- struct on stack case
							either 127 < abs offset [
								emit #{8D85}		;-- LEA eax, [ebp+n]	; 32-bit displacement
								emit to-bin32 offset
							][
								emit #{8D45}		;-- LEA eax, [ebp+n]	; 8-bit displacement
								emit to-bin8 offset
							]
						]
						'else [
							either alt [
								emit-variable-poly value
									#{8A15} #{8B15}	;-- MOV rD, [value]		; global
									#{8A93} #{8B93}	;-- MOV rD, [ebx+disp]	; PIC
									#{8A55} #{8B55}	;-- MOV rD, [ebp+n]		; local
							][
								emit-variable-poly value
									#{A0}   #{A1}	;-- MOV rA, [value]		; global
									#{8A83} #{8B83}	;-- MOV rA, [ebx+disp]	; PIC
									#{8A45} #{8B45}	;-- MOV rA, [ebp+n]		; local	
							]
						]
					]
				]
			]
			get-word! [
				value: to word! value
				either any [
					all [
						spec: select compiler/functions value
						spec/2 = 'routine
					]
					all [
						emitter/local-offset? value
						'function! = first compiler/get-type value
					]
				][
					either alt [
						emit-variable value
							#{8B15}					;-- MOV edx, [value]	; global
							#{8B93}					;-- MOV edx, [ebx+disp]	; PIC
							#{8B55}					;-- MOV edx, [ebp+n]	; local
					][
						emit-variable value
							#{A1}					;-- MOV eax, [value]	; global
							#{8B83}					;-- MOV eax, [ebx+disp]	; PIC
							#{8B45}					;-- MOV eax, [ebp+n]	; local	
					]
				][
					either offset: emitter/local-offset? value [
						offset: stack-encode offset	;-- n
						emit adjust-disp32 pick [
							#{8D55}					;-- LEA edx, [ebp+n]	; local
							#{8D45}					;-- LEA eax, [ebp+n]	; local
						] alt offset
						emit offset
					][
						either PIC? [
							emit pick [
								#{8D93}				;-- LEA edx, [ebx+disp] ; &name
								#{8D83}				;-- LEA eax, [ebx+disp] ; &name
							] alt
						][
							emit pick [
								#{BA}				;-- MOV edx, &name
								#{B8}				;-- MOV eax, &name
							] alt
						]
						emit-reloc-addr emitter/get-symbol-ref value	;-- symbol address
					]
				]
			]
			string! [
				emit-load-literal [c-string!] value
			]
			path! [
				emitter/access-path value none
			]
			paren! [
				emit-load-literal none value
			]
			object! [
				unless any [block? value/data value/data = <last>][
					either alt [
						emit-load/alt/with value/data value
					][
						emit-load/with value/data value
					]
					set-width value
				]
				;emit-casting value no
				;compiler/last-type: value/type
			]
		]
	]
	
	emit-store: func [
		name [word!] value [char! logic! integer! word! string! paren! tag! get-word! decimal!]
		spec [block! none!]
		/by-value slots [integer!]
		/local store-dword type offset
	][
		if verbose >= 3 [print [">>>storing" mold name mold value]]
		if value = <last> [value: 'last]			;-- force word! code path in switch block
		if logic? value [value: to integer! value]	;-- TRUE -> 1, FALSE -> 0
		
		store-dword: [
			emit-variable name
				#{C705}								;-- MOV dword [name], value		; global
				#{C783}								;-- MOV dword [ebx+disp], value	; PIC
				#{C745}								;-- MOV dword [ebp+n], value	; local
		]
				
		switch type?/word value [
			char! [
				emit-variable name
					#{C605}							;-- MOV byte [name], value		; global
					#{C683}							;-- MOV byte [ebx+disp], value	; PIC
					#{C645}							;-- MOV byte [ebp+n], value		; local
				emit value
			]
			integer! [
				do store-dword
				emit to-bin32 value
			]
			decimal! [
				store-float-variable name
			]
			word! [
				case [
					compiler/any-float? compiler/get-variable-spec name [
						store-float-variable name
					]
					by-value [
						if slots <= 2 [				 ;-- if > 2, copied already, do nothing
							either offset: emitter/local-offset? name [
								if slots = 2 [
									set-width/type last spec/2
									emit-poly [#{8895} #{8995}]	;-- MOV [ebp+n+4], rD
									emit to-bin32 offset + 4
								]
								set-width/type spec/2/2
								emit-poly [#{8885} #{8985}]		;-- MOV [ebp+n], rA
								emit to-bin32 offset
							][
								emit-variable name
									#{8B35}			;-- MOV esi, [value1]	; global
									#{8BB3}			;-- MOV esi, [ebx+disp]	; PIC	@@
									#{8B75}			;-- MOV esi, [ebp+n]	; local

								if slots = 2 [
									set-width/type last spec/2
									emit-poly [#{8856} #{8956}]	;-- MOV [esi+4], rD
									emit #{04}
								]
								set-width/type spec/2/2
								emit-poly [#{8806} #{8906}]	;-- MOV [esi], rA
							]
						]
					]
					'else [
						set-width name
						emit-variable-poly name
							#{A2} 	#{A3}			;-- MOV [name], rA		; global
							#{8883} #{8983}			;-- MOV [ebx+disp], rA	; PIC
							#{8845} #{8945}			;-- MOV [ebp+n], rA		; local
					]
				]
			]
			get-word! [
				either emitter/local-offset? to word! value [
					emit-store name <last> none
				][
					value: emitter/get-symbol-ref to word! value	;-- symbol address
					either PIC? [
						emit #{8D83}				;-- LEA eax, [ebx+disp]	; PIC
						emit-reloc-addr value
						emit-variable name
							#{A3}					;-- MOV [name], eax		; global
							#{8983}					;-- MOV [ebx+disp], eax	; PIC
							#{8945}					;-- MOV [ebp+n], eax	; local
					][
						do store-dword
						emit-reloc-addr value
					]
				]
			]
			string!
			paren! [
				either PIC? [
					emit-variable name
						#{A3}						;-- MOV [name], eax		; global
						#{8983}						;-- MOV [ebx+disp], eax	; PIC
						#{8945}						;-- MOV [ebp+n], eax	; local
				][
					do store-dword
					emit-reloc-addr spec/2
				]
			]
		]
	]
	
	emit-init-path: func [name [word! get-word!]][
		emit-variable to word! name
			#{A1}									;-- MOV eax, [name]			; global
			#{8B83}									;-- MOV eax, [ebx+disp]		; PIC
			#{8B45}									;-- MOV eax, [ebp+n]		; local
	]
	
	emit-access-path: func [
		path [path! set-path!] spec [block! none!] /short /local offset type saved name
	][
		if verbose >= 3 [print [">>>accessing path:" mold path]]

		unless spec [
			name: to word! path/1
			spec: second compiler/resolve-type name
			emit-load name
		]
		if short [return spec]
		
		saved: width
		type: compiler/resolve-type/with path/2 spec

		set-width/type type/1						;-- adjust operations width to member value size
		offset: emitter/member-offset? spec path/2
		
		either any [
			all [type/1 = 'struct! 'value = last spec/(path/2)]
			all [
				get-word? first head path
				tail? skip path 2
			]
		][
			emit #{05}							 	;--	ADD eax, <offset>
			emit to-bin32 offset
		][
			either compiler/any-float? type [
				either zero? offset [
					emit-float #{DD00}				;-- FLD [eax]
				][
					emit-float #{DD80}				;-- FLD [eax+offset]
					emit to-bin32 offset
				]
			][
				either zero? offset [
					emit-poly [#{8A00} #{8B00}]		;-- MOV rA, [eax]
				][
					emit-poly [#{8A80} #{8B80}]		;-- MOV rA, [eax+offset]
					emit to-bin32 offset
				]
			]
		]
		width: saved
	]
		
	emit-load-index: func [idx [word!]][
		unless compiler/local-variable? idx [idx: compiler/resolve-ns idx]
		emit-variable idx
			#{8B3D}									;-- MOV edi, [idx]		; global
			#{8BBB}									;-- MOV edi, [ebx+disp]	; PIC
			#{8B7D}									;-- MOV edi, [ebp+n]	; local
		emit #{4F}									;-- DEC edi				; one-based index
	]
	
	emit-c-string-path: func [path [path! set-path!] parent [block! none!] /local opcodes idx][
		either parent [
			emit #{89C6} 							;-- MOV esi, eax		; nested access
		][
			emit-variable path/1
				#{8B35}								;-- MOV esi, [value1]	; global
				#{8BB3}								;-- MOV esi, [ebx+disp]	; PIC	@@
				#{8B75}								;-- MOV esi, [ebp+n]	; local
		]
		opcodes: pick [[							;-- store path opcodes --
				#{8816}								;-- MOV [esi], dl			; first	
				#{8896}								;-- MOV [esi + idx], dl 	; n-th
				#{88143E}							;-- MOV [esi + edi], dl 	; variable index
			][										;-- load path opcodes --
				#{8A06}								;-- MOV al, [esi]			; first
				#{8A86}								;-- MOV al, [esi + idx]		; n-th
				#{8A043E}							;-- MOV al, [esi + edi]		; variable index
		]] set-path? path
		
		either integer? idx: path/2 [
			either zero? idx: idx - 1 [				;-- indexes are one-based
				emit opcodes/1
			][
				emit opcodes/2
				emit to-bin32 idx
			]
		][
			emit-load-index idx
			emit opcodes/3
		]
	]
	
	emit-pointer-path: func [
		path [path! set-path!] parent [block! none!] /local opcodes idx type offset
	][
		type: either parent [
			compiler/resolve-type/with path/1 parent
		][
			emit-init-path path/1
			compiler/resolve-type path/1
		]
		set-width/type type/2/1						;-- adjust operations width to pointed value size
		idx: either path/2 = 'value [1][path/2]
		
		either compiler/any-float? type/2 [
			opcodes: pick [[						;-- store path opcodes --
				#{DD18}								;-- FSTP [eax]
				#{DD98}								;-- FSTP [eax + <idx> * sizeof(p/value)]
				#{DD1C}								;-- FSTP [eax + edi * sizeof(p/value)]
			][										;-- load path opcodes --
				#{DD00}								;-- FLD [eax]
				#{DD80}								;-- FLD [eax + <idx> * sizeof(p/value)]
				#{DD04}								;-- FLD [eax + edi * sizeof(p/value)]
			]] set-path? path

			either integer? idx [
				either zero? idx: idx - 1 [			;-- indexes are one-based
					emit-float opcodes/1
				][
					offset: idx * emitter/size-of? type/2/1	;-- scaled index up
					emit-float opcodes/2
					emit to-bin32 offset
				]
			][
				emit-load-index idx
				emit-float opcodes/3
				emit select [4 #{B8} 8 #{F8}] width
			]
		][
			opcodes: pick [[						;-- store path opcodes --
				[#{8810} #{8910}]					;-- MOV [eax], rD
				[#{8890} #{8990}]					;-- MOV [eax + <idx> * sizeof(p/value)], rD
				[#{881438} #{8914B8}]				;-- MOV [eax + edi * sizeof(p/value)], rD
			][										;-- load path opcodes --
				[#{8A00} #{8B00}]					;-- MOV rA, [eax]
				[#{8A80} #{8B80}]					;-- MOV rA, [eax + <idx> * sizeof(p/value)]
				[#{8A0438} #{8B04B8}]				;-- MOV rA, [eax + edi * sizeof(p/value)]
			]] set-path? path

			either integer? idx [
				either zero? idx: idx - 1 [			;-- indexes are one-based
					emit-poly opcodes/1
				][
					offset: idx * emitter/size-of? type/2/1	;-- scaled index up
					emit-poly opcodes/2
					emit to-bin32 offset
				]
			][
				emit-load-index idx
				emit-poly opcodes/3
			]
		]
	]
	
	emit-load-path: func [path [path!] type [word!] parent [block! none!] /local idx][
		if verbose >= 3 [print [">>>loading path:" mold path]]

		switch type [
			c-string! [emit-c-string-path path parent]
			pointer!  [emit-pointer-path  path parent]
			struct!   [emit-access-path   path parent]
		]
	]

	emit-store-path: func [
		path [set-path!] type [word!] value parent [block! none!]
		/local idx offset type2 spec by-val? slots
	][
		if verbose >= 3 [print [">>>storing path:" mold path mold value]]
		
		either value = <last> [
			if by-val?: 'value = last compiler/last-type [
				slots: emitter/struct-slots? compiler/last-type
				if 2 < slots [exit]					;-- big struct by value do not need post-processing
				if slots = 2 [emit #{52}]			;-- PUSH edx				; saved edx struct member
				emit #{89C2}						;-- MOV edx, eax
			]
		][
			if parent [emit #{89C2}]				;-- MOV edx, eax			; save value/address
			emit-load value
			all [
				object? value
				not all [decimal? value/data 'float32! = value/type/1]
				emit-casting value no
			]
			unless all [
				type = 'struct!
				word? path/2
				spec: any [parent second compiler/resolve-type path/1]
				type2: select spec path/2
				compiler/any-float? type2
			][emit #{92}]							;-- XCHG eax, edx			; save value/restore address
		]

		switch type [
			c-string! [emit-c-string-path path parent]
			pointer!  [emit-pointer-path  path parent]
			struct!   [
				unless parent [parent: emit-access-path/short path parent]
				type: compiler/resolve-type/with path/2 parent
				
				set-width/type type/1				;-- adjust operations width to member value size
				offset: emitter/member-offset? parent path/2
				
				case [
					by-val? [						;-- small struct returned by value
						case [
							all [type/1 = 'struct! 'value = last parent/(path/2)][
								if offset <> 0 [
									emit #{05}		;--	ADD eax, <offset>
									emit to-bin32 offset
								]
							]
							zero? offset [
								emit #{8B00}		;-- MOV eax, [eax]
							]
							offset < 127 [
								emit #{8B40}		;-- MOV eax, [eax+<offset>] ; 8-bit disp
								emit to-bin8 offset
							]
							'else [
								emit #{8B80}		;-- MOV eax, [eax+<offset>] ; 32-bit disp
								emit to-bin32 offset
							]
						]
						set-width/type type/2/2
						emit-poly [#{8810} #{8910}] ;-- MOV [eax], rD

						if slots = 2 [
							set-width/type last type/2
							emit #{5A}					;-- POP edx
							emit-poly [#{8850} #{8950}]	;-- MOV [eax+4], rD
							emit #{04}
						]
					]
					compiler/any-float? type [
						either zero? offset [
							emit-float #{DD18}		;-- FSTP [eax]
						][
							emit-float #{DD98}		;-- FSTP [eax+offset]
							emit to-bin32 offset
						]
					]
					'else [
						either zero? offset [
							emit-poly [#{8810} #{8910}] ;-- MOV [eax], rD
						][
							emit-poly [#{8890} #{8990}]	;-- MOV [eax+offset], rD
							emit to-bin32 offset
						]
					]
				]
			]
		]
	]
	
	emit-start-loop: does [
		emit #{50}									;-- PUSH eax
	]
	
	emit-end-loop: does [
		emit #{58} 									;-- POP eax
		emit #{83E801}								;-- SUB eax, 1
	]
	
	patch-jump-back: func [buffer [binary!] offset [integer!]][
		change at buffer offset to-bin32 negate offset + 4 - 1
	]
	
	patch-jump-point: func [buffer [binary!] ptr [integer!] exit-point [integer!]][
		change at buffer ptr to-bin32 exit-point - ptr - branch-offset-size
	]
	
	emit-jump-point: func [type [block!]][
		if verbose >= 3 [print ">>>emitting jump point"]
		emit #{E9}									;-- JMP imm32
		emit-reloc-addr compose/only [- - (type)]
	]

	emit-branch: func [
		code [binary!]
		op [word! block! logic! none!]
		offset [integer! none!]
		/back?
		/local size imm8? opcode jmp
	][
		if verbose >= 3 [print [">>>inserting branch" either op [join "cc: " mold op][""]]]
		
		size: (length? code) - any [offset 0]				;-- offset from the code's head
		imm8?: size <= either back? [126][127]				;-- account 2 bytes for JMP imm8
		opcode: either not none? op [						;-- explicitly test for none
			op: case [
				block? op [									;-- [cc] => keep
					op: op/1
					either logic? op [pick [= <>] op][op]	;-- [logic!] or [cc]
				]
				logic? op [pick [= <>] op]					;-- test for TRUE/FALSE
				'else 	  [opposite? op]					;-- 'cc => invert condition
			]
			add-condition op copy pick [#{70} #{0F80}] imm8? ;-- Jcc offset 	; 8/32-bit displacement
		][
			pick [#{EB} #{E9}] imm8?						;-- JMP offset 	; 8/32-bit displacement
		]
		if back? [size: negate (size + (length? opcode) + pick [1 4] imm8?)]
		jmp: rejoin [opcode either imm8? [to-bin8 size][to-bin32 size]]
		insert any [all [back? tail code] code] jmp
		length? jmp
	]
	
	emit-push-struct: func [slots [integer!]][		;-- number of 32-bit slots
		either slots <= 5 [							;-- 5 is the breaking point where the loop takes less opcodes
			repeat i slots - 1 [
				emit #{FF70}						;-- PUSH [eax+i*<stack-width>] for i > 0
				emit to-bin8 slots - i * stack-width
			]
			emit #{FF30}							;-- PUSH [eax]
		][
			emit-reserve-stack slots
			emit #{89C6}							;-- MOV esi, eax
			emit #{89E7}							;-- MOV edi, esp
			emit #{B9}								;-- MOV ecx, <size>
			emit to-bin32 slots
			emit #{F3A5}							;-- REP MOVS
		]
	]
	
	emit-push: func [
		value [char! logic! integer! word! block! string! tag! path! get-word! object! decimal!]
		/with cast [object!]
		/cdecl										;-- external call
		/keep
		/local spec type offset conv-int-float? float?
	][
		if verbose >= 3 [print [">>>pushing" mold value]]
		if block? value [value: <last>]
		
		switch type?/word value [
			tag! [									;-- == <last>
				either value = <last> [
					either compiler/any-float? compiler/last-type [
						set-width/type any [all [cast cast/type] compiler/last-type]
						emit #{83EC}				;-- SUB esp, 8|4
						emit to-bin8 width
						emit-float #{DD1C24}		;-- FSTP [esp]
					][
						emit #{50}					;-- PUSH eax
					]
				][									;-- <ret-ptr> and <args-top> cases
					either value = <ret-ptr> [
						offset: stack-encode args-offset
						emit adjust-disp32 #{FF75} offset ;-- PUSH [ebp+<offset>]
						emit offset
					][
						emit #{8D8424}				;-- LEA eax, [esp+<args-top>]
						emit to-bin32 to integer! value
						emit #{50}					;-- PUSH eax
					]
				]
			]
			logic! [
				emit #{31C0}						;--	XOR eax, eax		; eax = 0 (FALSE)	
				if value [
					emit #{40}						;--	INC eax				; eax = 1 (TRUE)
				]
				emit #{50}							;-- PUSH eax
			]
			char! [
				emit #{6A}							;-- PUSH value
				emit value
			]
			integer! [
				either all [-128 <= value value <= 127][
					emit #{6A}						;-- PUSH imm8
					emit to-bin8 value
				][
					emit #{68}						;-- PUSH imm32		
					emit to-bin32 value	
				]
			]
			decimal! [
				value: either all [cast cast/type/1 = 'float32! not cdecl][
					IEEE-754/to-binary32/rev value
				][
					value: IEEE-754/to-binary64/rev value
					emit #{68}						;-- PUSH high part		
					emit at value 5
					value
				]
				emit #{68}							;-- PUSH low part
				emit copy/part value 4
			]
			word! [
				type: compiler/get-variable-spec value
				case [
					all [
						'value = last type
						offset: emitter/local-offset? value
					][
						emit-variable value
							none
							none
							#{8D45}					;-- LEA eax, [ebp+n]	; local struct
						emit #{50}					;-- PUSH eax
					]
					compiler/any-float? type [
						either cdecl [width: 8][	;-- promote to C double if required
							set-width/type any [all [cast cast/type] type]
						]

						emit #{83EC}				;-- SUB esp, 8|4
						emit to-bin8 width
						load-float-variable value
						emit-float #{DD1C24}		;-- FSTP [esp]			; push double on stack
					]
					'else [
						emit-variable value
							#{FF35}					;-- PUSH [value]		; global
							#{FFB3}					;-- PUSH [ebx+disp]		; PIC
							#{FF75}					;-- PUSH [ebp+n]		; local
					]
				]
			]
			get-word! [
				value: to word! value
				either offset: emitter/local-offset? value [
					either 'function! = first compiler/get-type value [
						emit-variable value
							none
							none
							#{FF75}					;-- PUSH [ebp+n]		; local
					][
						emit-variable value
							none
							none
							#{8D45}					;-- LEA eax, [ebp+n]	; local
						emit #{50}					;-- PUSH eax
					]
				][
					either PIC? [
						emit #{8D83}				;-- LEA eax, [ebx+disp]	; PIC
						emit-reloc-addr emitter/get-symbol-ref value
						emit #{50}					;-- PUSH eax
					][
						emit #{68}					;-- PUSH &value			; global
						emit-reloc-addr emitter/get-symbol-ref value
					]
				]
			]
			string! [
				spec: emitter/store-value none value [c-string!]
				either PIC? [
					emit #{8D83}					;-- LEA eax, [ebx+disp]	; PIC
					emit-reloc-addr spec/2			;-- one-based index
					emit #{50}						;-- PUSH eax
				][
					emit #{68}						;-- PUSH value			; global
					emit-reloc-addr spec/2			;-- one-based index
				]
				
			]
			path! [
				emitter/access-path value none
				compiler/last-type: either cast [
					emit-casting cast no
					cast/type
				][
					compiler/resolve-path-type value
				]
				unless keep [emit-push <last>]
			]
			object! [
				type: compiler/get-type value/data
				float?: find [float! float64! float32!] value/type/1
				
				conv-int-float?: any [
					all [float?	type/1 = 'integer!]
					all [
						find [float! float64! float32!] type/1
						value/type/1 = 'integer!
					]
				]
				all [
					conv-int-float?
					not find [block! tag!] type?/word value/data
					emit-load value/data
				]
				either keep [emit-casting value no][
					unless all [float? decimal? value/data][
						emit-casting/push value no
					]
				]
				
				unless conv-int-float? [
					either cdecl [
						emit-push/with/cdecl value/data value
					][
						emit-push/with value/data value
					]
				]
			]
		]
	]
	
	emit-sign-extension: does [
		emit switch width [
			1 [#{6698}]								;-- CBW			; extend AL to AX
			2 [#{6699}]								;-- CWD			; extend AX to DX:AX
			4 [#{99}]								;-- CDQ			; extend EAX to EDX:EAX
		]
	]
	
	emit-bitshift-op: func [name [word!] a [word!] b [word!] args [block!] /local c value][
		switch b [
			ref [
				emit-variable args/2
					#{8A0D}							;-- MOV cl, byte [value]	; global
					#{8A8B}							;-- MOV cl, byte [ebx+disp]	; PIC
					#{8A4D}							;-- MOV cl, byte [ebp+n]	; local
			]
			reg [emit #{88D1}]						;-- MOV cl, dl
		]
		switch name [
			<<  [
				emit-poly pick [
					[#{C0E0} #{C1E0}]				;-- SAL|SHL rA, value
					[#{D2E0} #{D3E0}]				;-- SAL|SHL rA, cl
				] b = 'imm
			]
			>>  [
				emit-poly pick [
					[#{C0F8} #{C1F8}]				;-- SAR rA, value
					[#{D2F8} #{D3F8}]				;-- SAR rA, cl
				] b = 'imm
			]
			-** [
				emit-poly pick [
					[#{C0E8} #{C1E8}]				;-- SHR rA, value
					[#{D2E8} #{D3E8}]				;-- SHR rA, cl
				] b = 'imm
			]
		]
		if b = 'imm [
			c: select [1 7 2 15 4 31] width
			value: compiler/unbox args/2		
			unless all [0 <= value value <= c][		
				compiler/backtrack name
				compiler/throw-error rejoin [
					"a value in 0-" c " range is required for this shift operation"
				]
			]
			emit to-bin8 value
		]
	]
	
	emit-bitwise-op: func [name [word!] a [word!] b [word!] args [block!] /local code][		
		code: select [
			and [
				#{25}								;-- AND eax, value
				#{21D0}								;-- AND eax, edx		; commutable op
			]
			or [
				#{0D}								;-- OR eax, value
				#{09D0}								;-- OR eax, edx			; commutable op
			]
			xor [
				#{35}								;-- XOR eax, value
				#{31D0}								;-- XOR eax, edx		; commutable op
			]
		] name
		
		switch b [
			imm [
				emit code/1							;-- <OP> eax, value
				emit to-bin32 compiler/unbox args/2
			]
			ref [
				emit-load/alt args/2
				if object? args/2 [emit-casting args/2 yes]
				emit code/2
			]
			reg [emit code/2]						;-- <OP> eax, edx		; commutable op
		]
	]
	
	emit-comparison-op: func [name [word!] a [word!] b [word!] args [block!] /local op-poly][
		op-poly: [emit-poly [#{38D0} #{39D0}]]		;-- CMP rA, rD			; not commutable op
		
		switch b [
			imm [
				emit-poly [#{3C} #{3D} args/2]		;-- CMP rA, value
			]
			ref [
				emit-load/alt args/2
				if object? args/2 [emit-casting args/2 yes]
				do op-poly
			]
			reg [
				do op-poly
			]
		]
	]
	
	emit-math-op: func [
		name [word!] a [word!] b [word!] args [block!]
		/local mod? scale c type arg2 op-poly
	][
		;-- eax = a, edx = b
		if find mod-rem-op name [					;-- work around unaccepted '// and '%
			mod?: select mod-rem-func name			;-- convert operators to words (easier to handle)
			name: first [/]							;-- work around unaccepted '/ 
		]
		arg2: compiler/unbox args/2
		
		if all [
			find [+ -] name							;-- pointer arithmetic only allowed for + & -
			type: compiler/resolve-aliased compiler/resolve-expr-type args/1
			not compiler/any-pointer? compiler/resolve-expr-type args/2	;-- no scaling if both operands are pointers		
			scale: switch type/1 [
				pointer! [emitter/size-of? type/2/1]		  ;-- scale factor: size of pointed value
				struct!  [emitter/member-offset? type/2 none] ;-- scale factor: total size of the struct
			]
			scale > 1
		][
			either compiler/literal? arg2 [
				arg2: arg2 * scale					;-- 'b is a literal, so scale it directly
			][
				either b = 'reg [
					emit #{92}						;-- XCHG eax, edx		; put operands in right order
				][									;-- 'b will now be stored in reg, so save 'a			
					emit-poly [#{88C2} #{89C2}]		;-- MOV rD, rA
					emit-load args/2
				]
				emit-math-op '* 'reg 'imm reduce [arg2 scale]
				if name = '- [emit #{92}]			;-- XCHG eax, edx		; put operands in right order
				b: 'reg
			]
		]
		;-- eax = a, edx = b
		switch name [
			+ [
				op-poly: [
					emit-poly [#{00D0} #{01D0}]		;-- ADD rA, rD			; commutable op
				]
				switch b [
					imm [
						emit-poly either arg2 = 1 [	;-- trivial optimization
							[#{FEC0} #{40}]			;-- INC rA
						][
							[#{04} #{05} arg2] 		;-- ADD rA, value
						]
					]
					ref [
						emit-load/alt args/2
						do op-poly
					]
					reg [do op-poly]
				]
			]
			- [
				op-poly: [
					emit-poly [#{28D0} #{29D0}] 	;-- SUB rA, rD			; not commutable op
				]
				switch b [
					imm [
						emit-poly either arg2 = 1 [ ;-- trivial optimization
							[#{FEC8} #{48}]			;-- DEC rA
						][
							[#{2C} #{2D} arg2] 		;-- SUB rA, value
						]
					]
					ref [
						emit-load/alt args/2
						do op-poly
					]
					reg [do op-poly]
				]
			]
			* [
				op-poly: [
					emit-poly [#{F6EA} #{F7EA}] 	;-- IMUL rD 			; commutable op
				]
				switch b [
					imm [
						either all [
							not zero? arg2
							c: power-of-2? arg2		;-- trivial optimization for b=2^n
						][
							either width = 1 [
								emit #{C0E0}		;-- SHL al, log2(b)	; 8-bit unsigned
							][
								emit-poly [#{C0ED} #{C1E0}]	;-- SAL rA, log2(b) ; signed
							]
							emit to-bin8 c
						][
							unless width = 1 [emit #{52}]  ;-- PUSH edx	; save edx from corruption for 16/32-bit ops
							with-width-of/alt args/2 [							
								emit-poly [#{B2} #{BA} args/2] ;-- MOV rD, value
							]
							emit #{89D1}				   ;-- MOV ecx, edx
							emit-poly [#{F6E9} #{F7E9}]	   ;-- IMUL rC		; result in ax|eax|edx:eax
							unless width = 1 [emit #{5A}]  ;-- POP edx
						]
					]
					ref [
						emit #{52}					;-- PUSH edx	; save edx from corruption
						emit-load/alt args/2
						do op-poly
						emit #{5A}					;-- POP edx
					]
					reg [do op-poly]
				]
			]
			/ [
				op-poly: [
					either width = 1 [				;-- 8-bit unsigned
						emit #{B400}				;-- MOV ah, 0			; clean-up garbage in ah
						emit #{F6F1}				;-- DIV cl
					][
						emit-sign-extension			;-- 16/32-bit signed
						emit-poly [#{F6F9} #{F7F9}]	;-- IDIV rC ; rA / rC
					]
				]
				switch b [
					imm [							;-- SAR usage http://www.arl.wustl.edu/~lockwood/class/cs306/books/artofasm/Chapter_6/CH06-3.html#HEADING3-120
						emit #{52}					;-- PUSH edx	; save edx from corruption
						with-width-of/alt args/2 [							
							emit-poly [#{B2} #{BA} args/2] ;-- MOV rD, value
						]
						emit #{89D1}				;-- MOV ecx, edx
						do op-poly
					]
					ref [
						emit #{52}					;-- PUSH edx	; save edx from corruption
						emit-load/alt args/2
						emit #{89D1}				;-- MOV ecx, edx
						do op-poly
					]
					reg [
						emit #{89D1}				;-- MOV ecx, edx		; ecx = b
						do op-poly
					]
				]
				if mod? [
					emit-poly [#{88E0} #{89D0}]		;-- MOV rA, remainder	; remainder from ah|dx|edx
					if all [mod? <> 'rem width > 1][;-- modulo, not remainder
					;-- Adjust modulo result to be mathematically correct:
					;-- 	if modulo < 0 [
					;--			if divisor < 0  [divisor: negate divisor]
					;--			modulo: modulo + divisor
					;--		]
						c: to-bin8 select [1 7 2 15 4 31] width		;-- support for possible int8 type
						emit #{0FBAE0}				;--   	  BT rA, 7|15|31 ; @@ better way ?
						emit c
						emit #{730A}				;-- 	  JNC exit		 ; (won't work with ax)
						emit #{0FBAE1}				;-- 	  BT rC, 7|15|31 ; @@ better way ?
						emit c
						emit #{7302}				;-- 	  JNC add		 ; (won't work with ax)
						emit-poly [#{F6D9} #{F7D9}]	;--		  NEG rC
						emit-poly [#{00C8} #{01C8}]	;-- add:  ADD rA, rC
					]								;-- exit:
				]
				if any [							;-- in case edx was saved on stack
					all [b = 'imm any [mod? not c]]
					b = 'ref
				][
					emit #{5A}						;-- POP edx
				]
			]
		]
	]
	
	emit-integer-operation: func [name [word!] args [block!] /local a b sorted? left right][
		if verbose >= 3 [print [">>>inlining integer op:" mold name mold args]]

		set-width args/1							;-- set reg/mem access width
		set [a b] get-arguments-class args
		last-saved?: no								;-- reset flag

		;-- First operand processing
		left:  compiler/unbox args/1
		right: compiler/unbox args/2
		
		switch to path! reduce [a b] [
			imm/imm	[emit-poly [#{B0} #{B8} args/1]];-- MOV rA, a
			imm/ref [emit-load args/1]				;-- eax = a
			imm/reg [								;-- eax = b
				if path? right [
					emit-load args/2				;-- late path loading
					if object? args/2 [
						emit-casting args/2 no
					]
				]
				emit-poly [#{88C2} #{89C2}]			;-- MOV rD, rA
				emit-poly [#{B0} #{B8} args/1]		;-- MOV rA, a		; eax = a, edx = b
			]
			ref/imm [emit-load args/1]
			ref/ref [emit-load args/1]
			ref/reg [								;-- eax = b
				if path? right [
					emit-load args/2				;-- late path loading
				]
				emit-poly [#{88C2} #{89C2}]			;-- MOV rD, rA	
				emit-load args/1					;-- eax = a, edx = b
			]
			reg/imm [								;-- eax = a (or edx = a if last-saved)
				if path? left [
					emit-load args/1				;-- late path loading
				]
				if last-saved? [emit #{92}]			;-- XCHG eax, edx	; eax = a
			]
			reg/ref [								;-- eax = a (or edx = a if last-saved)
				if path? left [
					emit-load args/1				;-- late path loading
				]
				if last-saved? [emit #{92}]			;-- XCHG eax, edx	; eax = a
			]
			reg/reg [								;-- eax = b, edx = a
				if path? left [
					if any [
						args/2 = <last>				;-- inlined statement
						block? right				;-- function call
					][								;-- edx = b
						emit #{92}					;-- XCHG eax, edx
						sorted?: yes				;-- eax = a, edx = b
					]
					emit-load args/1				;-- late path loading
				]
				if path? right [
					emit #{92}						;-- XCHG eax, edx	; eax = b, edx = a
					emit-load args/2
				]
				unless sorted? [emit #{92}]			;-- XCHG eax, edx	; eax = a, edx = b
			]
		]
		if object? args/1 [emit-casting args/1 no]	;-- do runtime conversion on eax if required

		;-- Operator and second operand processing
		either all [
			object? args/2
			find [imm reg] b
			args/2/type/1 <> 'integer!				;-- skip explicit casting to integer! (implicit)
		][
			emit-casting args/2 yes					;-- do runtime conversion on edx if required
		][
			implicit-cast right
		]
		case [
			find comparison-op name [emit-comparison-op name a b args]
			find math-op	   name	[emit-math-op		name a b args]
			find bitwise-op	   name	[emit-bitwise-op	name a b args]
			find bitshift-op   name [emit-bitshift-op   name a b args]
		]
	]
	
	emit-float-trash-last: does [
		if verbose >= 3 [print ">>>cleaning FPU stack base"]
		emit #{DDD8}								;-- FSTP st0
	]
	
	emit-float-comparison-op: func [
		name [word!] a [word!] b [word!] args [block!] reversed? [logic!]
		/local spec float32?
	][
		if reversed? [emit #{D9C9}]					;-- FXCH st0, st1
		
		either compiler/job/cpu-version >= 6.0	[	;-- support for FCOMI* only with P6+
			emit #{DFF1}							;-- FCOMIP st0, st1
			emit-float-trash-last					;-- pop 2nd argument
		][
			emit #{D8D9}							;-- FCOMP st0, st1
			emit #{DDD8}							;-- FSTP st0		; pop 2nd argument
			emit #{9BDFE0}							;-- FSTSW ax		; move FPU flags to ax
			emit #{9B}								;-- FWAIT			; wait for FPU->CPU transfer completion
			emit #{9E}								;-- SAHF			; move flags to CPU status flags
		]
	]
	
	emit-float-math-op: func [
		name [word!] a [word!] b [word!] args [block!] reversed? [logic!]
		/local mod? scale c type spec
	][
		all [
			find [+ -] name	
			any [
				compiler/any-pointer? compiler/get-type args/1
				compiler/any-pointer? compiler/get-type args/2
			]
			compiler/throw-error "unsupported operation with float numbers"
		]
		
		if find mod-rem-op name [					;-- work around unaccepted '// and '%
			mod?: select mod-rem-func name			;-- convert operators to words (easier to handle)
			name: first [/]							;-- work around unaccepted '/ 
		]
		set-width args/1
		emit switch name [
			+ [#{DEC1}]								;-- FADDP st0, st1
			- [pick [#{DEE1} #{DEE9}] reversed?]	;-- FSUB[R]P st0, st1
			* [#{DEC9}]								;-- FMULP st0, st1
			/ [
				if all [mod? not reversed?][
					emit #{D9C9}					;-- FXCH st0, st1		; for modulo/remainder ops
				]
				switch/default mod? [
					mod [#{D9F8}]					;-- FPREM st0, st1		; floating point remainder
					rem [#{D9F8}]					;-- FPREM st0, st1 		; floating point remainder
					;rem [#{D9F5}]					;-- FPREM1 st0, st1 	; rounded remainder (IEEE)
				][pick [#{DEF1} #{DEF9}] reversed?]	;-- FDIV[R]P st0, st1
			]
		]
		if mod? [									;-- Trash st1 to keep the stack clean
			emit #{D9C9}							;-- FXCH st0, st1		; st1 <=> st0
			emit-float-trash-last					;-- drop st0
		]
	]

	emit-float-operation: func [
		name [word!] args [block!] 
		/local a b left right spec load-from-stack reversed? type
	][
		if verbose >= 3 [print [">>>inlining float op:" mold name mold args]]

		if find comparison-op name [reverse args] 	;-- arguments will be pushed in reverse order
		
		set [a b] get-arguments-class args

		;-- First operand processing
		left:  compiler/unbox args/1
		right: compiler/unbox args/2
		set-width left
		
		load-from-stack: [
			emit-float #{DD0424}					;-- FLD [esp]
			emit #{83C4} 							;-- ADD esp, 8|4
			emit to-bin8 width		
		]
		switch a [									;-- load left operand on FPU stack
			imm [
				spec: emitter/store-value none args/1 compiler/get-type args/1
				either PIC? [
					emit-float-arg args/1 #{DD83}	;-- FLD [ebx+disp]	; PIC
				][
					emit-float-arg args/1 #{DD05}	;-- FLD [<float>]	; global
				]
				emit-reloc-addr spec/2
				set-width args/1
			]
			ref [
				type: load-float-variable left
				all [
					object? args/1
					not find [float32! integer!] type
					emit-casting args/1 no
				]
			]
			reg [
				if object? args/1 [
					if block? left [emit-casting args/1 no]
					set-width/type compiler/last-type: args/1/type
				]
				if path? left [emit-push/keep args/1] ;-- late path loading
			]
		]		
		switch b [									;-- load right operand on FPU stack
			imm [
				spec: emitter/store-value none args/2 compiler/get-type args/2
				either PIC? [
					emit-float-arg args/2 #{DD83}	;-- FLD [ebx+disp]	; PIC
				][
					emit-float-arg args/2 #{DD05}	;-- FLD [<float>]	; global
				]
				emit-reloc-addr spec/2
			]
			ref [
				type: load-float-variable right
				all [
					object? args/2
					not find [float32! integer!] type
					emit-casting args/2 no
				]
			]
			reg [
				if all [object? args/2 block? right][
					emit-casting args/2 no
				]
				if path? right [emit-push/keep args/2] ;-- late path loading
			]
		]
		
		reversed?: to logic! all [b = 'reg any [
			all [a = 'ref block? right]
			all [a = 'imm block? right]
			all [path? left block? right]
		]]
		case [
			find comparison-op name [emit-float-comparison-op name a b args reversed?]
			find math-op	   name	[emit-float-math-op		  name a b args reversed?]
			true [
				compiler/throw-error "unsupported operation on floats"
			]
		]
	]
	
	emit-cdecl-pop: func [spec [block!] args [block!] /local size slots][
		size: emitter/arguments-size? spec/4
		if all [
			spec/2 = 'syscall
			compiler/job/syscall = 'BSD
		][
			size: size + stack-width				;-- account for extra space
		]
		if issue? args/1 [							;-- test for variadic call
			size: call-arguments-size? args/2
			if spec/2 = 'native [
				size: size + pick [12 8] args/1 = #typed 	;-- account for extra arguments
			]
		]
		all [
			spec/2 = 'import
			compiler/job/OS <> 'Windows
			slots: emitter/struct-slots?/check spec/4
			not all [
				compiler/job/OS = 'MacOSX			;-- on macOS, <ptr> is used for slots > 2 only
				slots <= 2
			]
			size: size - stack-width				;-- hidden pointer is freed by callee
		]
		if size > 0 [emit-release-stack/bytes size]
	]
	
	patch-call: func [code-buf rel-ptr dst-ptr][
		change										;-- CALL NEAR disp size
			at code-buf rel-ptr
			to-bin32 dst-ptr - rel-ptr - ptr-size
	]
	
	emit-argument: func [arg fspec [block!]][
		if arg = #_ [exit]							;-- place-holder, no code to emit
		
		either all [
			object? arg
			any [arg/type = 'logic! 'byte! = first compiler/get-type arg/data]
			not path? arg/data
		][
			unless block? arg [emit-load arg]		;-- block! means last value is already in eax (func call)
			emit-casting arg no
			compiler/last-type: arg/type			;-- for inline unary functions
			emit-push <last>
		][
			if block? arg [arg: <last>]
			either all [
				fspec/3 = 'cdecl 
				compiler/find-attribute fspec/4 'variadic	;-- only for vararg C functions
			][
				emit-push/cdecl arg					;-- promote float32! to float!
			][
				emit-push arg
			]
		]
	]
		
	emit-call-syscall: func [args [block!] fspec [block!] attribs [block! none!]][
		switch compiler/job/syscall [
			BSD [									; http://www.freebsd.org/doc/en/books/developers-handbook/book.html#X86-SYSTEM-CALLS
				emit #{83EC04}						;-- SUB esp, 4		; extra entry (BSD convention)			
			]
			Linux [
				if PIC? [
					emit #{53}						;-- PUSH ebx
					emit #{83C404}					;-- ADD esp, 4
				]
				if fspec/1 >= 6 [
					emit #{89E8}					;-- MOV eax, ebp	; save frame pointer
				]
				repeat c fspec/1 [
					emit pick [
						#{5B}						;-- POP ebx			; get 1st arg in reg
						#{59}						;-- POP ecx			; get 2nd arg in reg
						#{5A}						;-- POP edx			; get 3rd arg in reg
						#{5E}						;-- POP esi			; get 4th arg in reg
						#{5F}						;-- POP edi			; get 5th arg in reg
						#{5D}						;-- POP ebp			; get 6th arg in reg
					] 1 + fspec/1 - c
				]
				if PIC? [
					emit #{8B5C24}					;-- MOV ebx, [esp-c-1]
					emit to-bin8 negate (fspec/1 + 1) * 4
					emit #{53}						;-- PUSH ebx
				]
				if fspec/1 >= 6 [
					emit #{50}						;-- PUSH eax		; save frame pointer on stack
				]
			]
		]
		emit #{B8}									;-- MOV eax, code
		emit to-bin32 last fspec
		emit #{CD80}								;-- INT 0x80		; syscall
		switch compiler/job/syscall [
			BSD [emit-cdecl-pop fspec args]			;-- BSD syscall cconv (~ cdecl)
			Linux [
				if fspec/1 >= 6 [emit #{5D}]		;-- POP ebp			; restore frame pointer
				if PIC? [emit #{5B}]				;-- POP ebx			; restore IP-relative pointer
			]
		]
	]
	
	emit-variadic-data: func [args [block!] /local total][
		emit-push call-arguments-size? args/2		;-- push arguments total size in bytes 
													;-- (required to clear stack on stdcall return)
		emit #{8D742404}							;-- LEA esi, [esp+4]	; skip last pushed value
		emit #{56}									;-- PUSH esi			; push arguments list pointer
		total: length? args/2
		if args/1 = #typed [total: total / 3]		;-- typed args have 3 components
		emit-push total								;-- push arguments count
	]
	
	emit-call-import: func [args [block!] fspec [block!] spec [block!] attribs [block! none!] /local cdecl?][
		cdecl?: fspec/3 = 'cdecl
		if all [issue? args/1 not cdecl?][emit-variadic-data args]

		either compiler/job/OS = 'MacOSX [
			either PIC? [
				emit #{8D83}						;-- LEA eax, [ebx+disp]	; PIC
			][
				emit #{B8}							;-- MOV eax, addr		; global
			]
			emit-reloc-addr spec
			emit #{FFD0} 							;-- CALL eax		; direct call
		][
			emit-indirect-call spec
		]
		if cdecl? [emit-cdecl-pop fspec args]		;-- add calling cleanup when required
	]

	emit-call-native: func [
		args [block!] fspec [block!] spec [block!] attribs [block! none!]
		/routine name [word!]
		/local cdecl?
	][
		cdecl?: fspec/3 = 'cdecl
		
		either routine [
			either 'local = last fspec [
				name: pick tail fspec -2
				either find form name slash [
					emitter/access-path name none
				][
					emit-variable name none	none #{8B45} ;-- MOV eax, [ebp+n]	; local	
				]
				emit #{FFD0} 						;-- CALL eax			; direct call
			][
				emit-indirect-call spec
			]
		][
			if all [issue? args/1 not cdecl?][emit-variadic-data args]
			emit #{E8}								;-- CALL NEAR disp
			emit-reloc-addr spec					;-- 32-bit relative displacement
		]
		if cdecl? [emit-cdecl-pop fspec args]		;-- in case of non-default calling convention
	]
	
	emit-stack-align: does [
		emit #{89E7}								;-- MOV edi, esp
		emit #{83E4F0}								;-- AND esp, -16
		emit #{89F8}								;-- MOV eax, edi
	]

	emit-stack-align-prolog: func [args [block!] fspec [block!] /local offset][
		if compiler/job/stack-align-16? [
			emit #{89E7}							;-- MOV edi, esp
			emit #{83E4F0}							;-- AND esp, -16
			offset: 4 + either issue? args/1 [		;-- account for saved edi
				all [
					args/1 = #variadic
					fspec/3 <> 'cdecl
					offset: offset + 12				;-- account for extra variadic slots
				]
				call-arguments-size? args/2
			][
				emitter/arguments-size? fspec/4
			]
			
			unless zero? offset: offset // 16 [
				emit #{83EC}						;-- SUB esp, offset		; ensure call will be 16-bytes aligned
				emit to-bin8 16 - offset
			]
			emit #{57}								;-- PUSH edi
		]
	]
	
	emit-stack-align-epilog: func [args [block!]][
		if compiler/job/stack-align-16? [
			emit #{5C}								;-- POP esp
		]
	]
	
	emit-throw: func [value [integer! word!] /thru][
		emit-load value
		if verbose >= 3 [print [">>>emitting THROW" value]]

		if thru [emit #{EB01}]						;--			JMP _1st
		emit #{C9}									;-- _loop:	LEAVE
		emit #{3945FC}								;--	_1st:	CMP [ebp-4], eax ; compare with catch flag
		emit #{72FA}								;-- 		JB _loop
		emit #{89C2}								;--			MOV edx, eax
		emitter/access-path to set-path! 'system/thrown <last>
		
		emit #{8B7DF8}								;--			MOV edi, [ebp-8]
		emit #{83FF00}								;--			CMP edi, 0
		emit #{7402}								;--			JZ _next
		emit #{FFE7}								;--			JMP edi		; resume in caller
		emit #{5F}									;-- _next:	POP edi		; read return address
		emit #{83FF00}								;--			CMP edi, 0
		emit #{7402}								;--			JZ _end
		emit #{FFE7}								;--			JMP edi		; resume in caller
													;-- _end:
	]
	
	emit-open-catch: func [body-size [integer!]][
		if verbose >= 3 [print ">>>emitting CATCH prolog"]
		emit #{FF75FC}						 		;--	PUSH [ebp-4]		; save old catch value
		emit #{FF75F8}						 		;--	PUSH [ebp-8]		; save old catch address
		emit #{8945FC}								;-- MOV  [ebp-4], eax	; rewrite the catch ID
		emit #{E800000000}							;-- CALL next			; push eip on stack
		emit #{58}									;-- POP eax
		emit #{05}							 		;--	ADD eax, <offset>
		emit to-bin32 body-size + 9					;-- account for catch-frame opcodes after `CALL next`
		emit #{8945F8}							 	;--	MOV [ebp-8], eax
		23											;-- return size of (catch-frame + extra) opcodes
	]
	
	emit-close-catch: func [offset [integer!] global [logic!] callback? [logic!]][
		if verbose >= 3 [print ">>>emitting CATCH epilog"]
		offset: offset + (2 * 8)					;-- account for the 2 catch slots + 2 saved slots
		if callback? [offset: offset + 12]			;-- account for ebx,esi,edi saving slots
		
		either offset > 127 [
			emit #{89EC}							;-- MOV esp, ebp
			emit #{81EC}							;-- SUB esp, locals-size	; 32-bit
			emit to-bin32 offset
		][
			emit #{8D65}							;-- LEA esp, [ebp-locals]
			emit to-char 256 - offset
		]
		emit #{8F45F8}								;-- POP [ebp-8]
		emit #{8F45FC}								;-- POP [ebp-4]
	]

	emit-prolog: func [name [word!] locals [block!] locals-size [integer!] /local fspec attribs offset][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "prolog"]]

		fspec: select compiler/functions name
		attribs: compiler/get-attributes fspec/4
			
		emit #{55}									;-- PUSH ebp
		emit #{89E5}								;-- MOV ebp, esp

		emit-push pick [-2 0] to logic! all [		;-- push catch ID
			attribs find attribs 'catch
		]
		emit-push 0									;-- reserve slot for catch resume address

		unless zero? locals-size [
			emit-reserve-stack (round/to/ceiling locals-size stack-width) / stack-width
		]
		if any [
			fspec/5 = 'callback
			all [attribs any [find attribs 'cdecl find attribs 'stdcall]]
		][
			emit #{53}								;-- PUSH ebx
			emit #{56}								;-- PUSH esi
			emit #{57}								;-- PUSH edi
			
			if PIC? [
				offset: emit-get-pc/ebx
				emit #{81EB}						;-- SUB ebx, <offset>
				emit to-bin32 emitter/tail-ptr + 1 - offset	;-- +1 adjustment for CALL first opcode
			]
		]
	]

	emit-epilog: func [
		name [word!] locals [block!] args-size [integer!] locals-size [integer!] /with slots [integer! none!]
		/local fspec attribs vars offset
	][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "epilog"]]
		
		if slots [
			case [
				slots = 1 [emit #{8B00}]			;-- MOV eax, [eax]
				slots = 2 [
					emit #{8B5004}					;-- MOV edx, [eax+4]
					emit #{8B00}					;-- MOV eax, [eax]
				]
				'else [
					vars: emitter/stack
					unless tag? vars/1 [
						compiler/throw-error ["Function" name "has no return pointer in" mold locals]
					]
					emit #{8B7D}					;-- MOV edi, [ebp+<ptr>]
					emit to-bin8 vars/2
					;@@ needs 32-bit disp also !!
					emit #{89C6}					;-- MOV esi, eax
					emit #{B9}						;-- MOV ecx, <size>
					emit to-bin32 slots
					emit #{F3A5}					;-- REP MOVS
				]
			]
		]
		
		fspec: select compiler/functions name
		if any [
			fspec/5 = 'callback
			all [
				attribs: compiler/get-attributes fspec/4
				any [find attribs 'cdecl find attribs 'stdcall]
			]
		][
			offset: locals-size + locals-offset
			emit #{8DA5}							;-- LEA esp, [ebp-<offset>]
			emit to-bin32 negate offset + 12		;-- account for 3 saved regs
			emit #{5F}								;-- POP edi
			emit #{5E}								;-- POP esi
			emit #{5B}								;-- POP ebx
		]
		emit #{C9}									;-- LEAVE			; catch flag is skipped
		either any [
			zero? args-size
			fspec/3 = 'cdecl
		][
			;; cdecl: Leave original arguments on stack, popped by caller.
			emit #{C3}								;-- RET
		][
			;; stdcall/reds: Consume original arguments from stack.
			either compiler/check-variable-arity? locals [
				emit #{5E}							;-- POP esi			; retrieve the return address
				emit #{59}							;-- POP ecx			; skip arguments count
				emit #{59}							;-- POP ecx			; skip arguments pointer
				emit #{59}							;-- POP ecx			; get stack offset
				emit #{01CC}						;-- ADD esp, ecx	; skip arguments list (clears stack)
				emit #{56}							;-- PUSH esi		; push return address
				emit #{C3}							;-- RET
			][
				emit #{C2}							;-- RET args-size
				emit to-bin16 round/to/ceiling args-size 4
			]
		]
	]
]
