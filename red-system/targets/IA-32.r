REBOL [
	Title:   "Red/System IA-32 code emitter"
	Author:  "Nenad Rakocevic"
	File: 	 %IA-32.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

make target-class [
	target: 'IA-32
	little-endian?: yes
	struct-align-size: 	4
	ptr-size: 			4
	default-align:		4
	stack-width:		4
	args-offset:		8							;-- stack frame offset to arguments (esp + ebp)
	branch-offset-size:	4							;-- size of JMP offset
	
	conditions: make hash! [
	;-- name ----------- signed --- unsigned --
		overflow?		 #{00}		-
		not-overflow?	 #{01}		-	
		=				 #{04}		-
		<>				 #{05}		-
		signed?			 #{08}		-
		unsigned?		 #{09}
		even?			 #{0A}		-
		odd?			 #{0B}		-
		<				 #{0C}		#{02}
		>=				 #{0D}		#{03}
		<=				 #{0E}		#{06}
		>				 #{0F}		#{07}
	]
	
	add-condition: func [op [word!] data [binary!]][
		op: either '- = third op: find conditions op [op/2][
			pick op pick [2 3] signed?
		]
		data/(length? data): (to char! last data) or (to char! first op) ;-- REBOL2's awful binary! handling
		data
	]
		
	emit-poly: func [spec [block!] /local to-bin][	;-- polymorphic code generation
		spec: reduce spec
		emit switch width [
			1 [spec/1]								;-- 8-bit
			2 [emit #{66} spec/2]					;-- 16-bit
			4 [spec/2]								;-- 32-bit
			;8 not yet supported
		]
		to-bin: get select [1 to-bin8 2 to-bin16 4 to-bin32] width
		case/all [
			2 < length? spec [emit to-bin to integer! compiler/unbox spec/3] ;-- emit displacement or immediate
			3 < length? spec [emit to-bin to integer! compiler/unbox spec/4] ;-- emit displacement or immediate
		]	
	]
	
	emit-variable-poly: func [							;-- polymorphic variable access generation
		name [word! object!]
		    g8 [binary!] 		g32 [binary!]			;-- opcodes for global variables
			l8 [binary! block!] l32 [binary! block!]	;-- opcodes for local variables
	][
		with-width-of name [
			switch width [
				1 [emit-variable name g8 l8]				;-- 8-bit
				2 [emit #{66} emit-variable name g32 l32]	;-- 16-bit
				4 [emit-variable name g32 l32]				;-- 32-bit
			]
		]
	]
	
	emit-save-last: does [
		last-saved?: yes
		emit #{50}									;-- PUSH eax
	]
	
	emit-restore-last: does [
		emit #{5A}					   				;-- POP edx
	]
	
	emit-casting: func [value [object!] alt? [logic!] /local old][
		type: compiler/get-type value/data	
		case [
			value/type/1 = 'logic! [
				if verbose >= 3 [print [">>>converting from" mold/flat type/1 "to logic!"]]
				old: width
				set-width/type type/1
				emit #{31DB}						;--		   XOR ebx, ebx
				either alt? [
					emit-poly [#{80FA00} #{83FA00}]	;-- 	   CMP rD, 0
					emit #{7401}					;--        JZ _exit
					emit #{43}						;-- 	   INC ebx
					emit #{89DA}					;-- _exit: MOV edx, ebx
				][
					emit-poly [#{3C00} #{83F800}]	;-- 	   CMP rA, 0
					emit #{7401}					;--        JZ _exit
					emit #{43}						;-- 	   INC ebx
					emit #{89D8}					;-- _exit: MOV eax, ebx
				]
				width: old
			]
			all [value/type/1 = 'integer! type/1 = 'byte!][
				if verbose >= 3 [print ">>>converting from byte! to integer! "]
				emit pick [#{81E2} #{25}] alt?    	;-- AND edx|eax, 000000FFh 
				emit to-bin32 255
			]
		]
	]

	emit-load-literal: func [type [block! none!] value /local spec][	
		unless type [type: compiler/get-type value]
		spec: emitter/store-value none value type
		emit #{B8}									;-- MOV eax, value
		emit-reloc-addr spec/2						;-- one-based index
	]
	
	emit-get-pc: does [
		emit #{E800000000}							;-- CALL next		; call the next instruction
		emit-pop									;-- get eip in eax
	]
	
	emit-set-stack: func [value /frame][
		if verbose >= 3 [print [">>>emitting SET-STACK" mold value]]
		emit-load value
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
				if boxed [emit-casting boxed no]
				type: first compiler/resolve-aliased compiler/get-variable-spec value
				if find [pointer! c-string! struct!] type [ ;-- type casting trap
					type: 'logic!
				]
				switch type opcodes
			]
			tag! [
				if boxed [emit-casting boxed no]
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
					do opcodes/integer!
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
		value [char! logic! integer! word! string! struct! path! paren! get-word! object!]
		/alt
	][
		if verbose >= 3 [print [">>>loading" mold value]]
		
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
			word! [
				with-width-of value [
					either alt [
						emit-variable-poly value
							#{8A15} #{8B15}			;-- MOV rD, [value]		; global
							#{8A55} #{8B55}			;-- MOV rD, [ebp+n]		; local
					][
						emit-variable-poly value
							#{A0}   #{A1}			;-- MOV rA, [value]		; global
							#{8A45} #{8B45}			;-- MOV rA, [ebp+n]		; local	
					]
				]
			]
			get-word! [
				emit #{B8}							;-- MOV eax, &name
				emit-reloc-addr emitter/get-func-ref to word! value	;-- symbol address
			]
			string! [
				emit-load-literal [c-string!] value
			]
			struct! [
				;TBD @@
			]
			path! [
				emitter/access-path value none
			]
			paren! [
				emit-load-literal none value
			]
			object! [
				unless any [block? value/data value/data = <last>][
					either alt [emit-load/alt value/data][emit-load value/data]
				]
			]
		]
	]
	
	emit-store: func [
		name [word!] value [char! logic! integer! word! string! paren! tag! get-word!] spec [block! none!]
		/local store-dword
	][
		if verbose >= 3 [print [">>>storing" mold name mold value]]
		if value = <last> [value: 'last]			;-- force word! code path in switch block
		if logic? value [value: to integer! value]	;-- TRUE -> 1, FALSE -> 0
		
		store-dword: [
			emit-variable name
				#{C705}								;-- MOV dword [name], value		; global
				#{C745}								;-- MOV dword [ebp+n], value	; local
		]
		
		switch type?/word value [
			char! [
				emit-variable name
					#{C605}							;-- MOV byte [name], value
					#{C645}							;-- MOV byte [ebp+n], value
				emit value
			]
			integer! [
				do store-dword
				emit to-bin32 value
			]
			word! [
				set-width name				
				emit-variable-poly name
					#{A2} 	#{A3}					;-- MOV [name], rA		; global variable
					#{8845} #{8945}					;-- MOV [ebp+n], rA		; local variable
			]
			get-word! [
				do store-dword
				emit-reloc-addr emitter/get-func-ref to word! value	;-- symbol address
			]
			string! [
				do store-dword
				emit-reloc-addr spec/2
			]
			paren! [
				do store-dword
				emit-reloc-addr spec/2
			]
		]
	]
	
	emit-init-path: func [name [word!]][
		emit-variable name
			#{A1}									;-- MOV eax, [name]			; global
			#{8B45}									;-- MOV eax, [ebp+n]		; local
	]
	
	emit-access-path: func [
		path [path! set-path!] spec [block! none!] /short /local offset type saved
	][
		if verbose >= 3 [print [">>>accessing path:" mold path]]

		unless spec [
			spec: second compiler/resolve-type path/1
			emit-init-path path/1
		]
		if short [return spec]
		
		saved: width
		type: first compiler/resolve-type/with path/2 spec
		set-width/type type							;-- adjust operations width to member value size

		either zero? offset: emitter/member-offset? spec path/2 [
			emit-poly [#{8A00} #{8B00}]				;-- MOV rA, [eax]
		][
			emit-poly [#{8A80} #{8B80}]				;-- MOV rA, [eax+offset]
			emit to-bin32 offset
		]
		width: saved
	]
		
	emit-load-index: func [idx [word!]][
		emit-variable idx
			#{8B1D}									;-- MOV ebx, [idx]		; global
			#{8B5D}									;-- MOV ebx, [ebp+n]	; local
		emit #{4B}									;-- DEC ebx				; one-based index
	]
	
	emit-c-string-path: func [path [path! set-path!] parent [block! none!] /local opcodes idx][
		either parent [
			emit #{89C6} 							;-- MOV esi, eax		; nested access
		][
			emit-variable path/1
				#{8B35}								;-- MOV esi, [value1]	; global
				[
					#{8D45}							;-- LEA eax, [ebp+n]	; local
					offset							;-- n
					#{8B30}							;-- MOV esi, [eax]
				]
		]
		opcodes: pick [[							;-- store path opcodes --
				#{8816}								;-- MOV [esi], dl			; first	
				#{8896}								;-- MOV [esi + idx], dl 	; n-th
				#{88141E}							;-- MOV [esi + ebx], dl 	; variable index
			][										;-- load path opcodes --
				#{8A06}								;-- MOV al, [esi]			; first
				#{8A86}								;-- MOV al, [esi + idx]		; n-th
				#{8A041E}							;-- MOV al, [esi + ebx]		; variable index
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
		path [path! set-path!] parent [block! none!] /local opcodes idx type
	][
		opcodes: pick [[							;-- store path opcodes --
				[#{8810} #{8910}]					;-- MOV [eax], rD
				[#{8890} #{8990}]					;-- MOV [eax + idx * sizeof(p/value)], rD
				[#{881418} #{891498}]				;-- MOV [eax + ebx * sizeof(p/value)], rD
			][										;-- load path opcodes --
				[#{8A00} #{8B00}]					;-- MOV rA, [eax]
				[#{8A80} #{8B80}]					;-- MOV rA, [eax + idx * sizeof(p/value)]
				[#{8A0418} #{8B0498}]				;-- MOV rA, [eax + ebx * sizeof(p/value)]
		]] set-path? path
		
		type: either parent [
			compiler/resolve-type/with path/1 parent
		][
			emit-init-path path/1
			type: compiler/resolve-type path/1
		]
		set-width/type type/2/1						;-- adjust operations width to pointed value size
		idx: either path/2 = 'value [1][path/2]

		either integer? idx [
			either zero? idx: idx - 1 [				;-- indexes are one-based
				emit-poly opcodes/1
			][
				emit-poly opcodes/2
				emit to-bin32 idx * emitter/size-of? type/2/1
			]
		][
			emit-load-index idx						; @@ missing scaling factor ???
			emit-poly opcodes/3
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

	emit-store-path: func [path [set-path!] type [word!] value parent [block! none!] /local idx offset][
		if verbose >= 3 [print [">>>storing path:" mold path mold value]]

		if parent [emit #{89C2}]					;-- MOV edx, eax			; save value/address
		unless value = <last> [emit-load value]
		emit #{92}									;-- XCHG eax, edx			; save value/restore address

		switch type [
			c-string! [emit-c-string-path path parent]
			pointer!  [emit-pointer-path  path parent]
			struct!   [
				unless parent [parent: emit-access-path/short path parent]
				type: first compiler/resolve-type/with path/2 parent
				set-width/type type					;-- adjust operations width to member value size
				
				either zero? offset: emitter/member-offset? parent path/2 [
					emit-poly [#{8810} #{8910}] 	;-- MOV [eax], rD
				][
					emit-poly [#{8890} #{8990}]		;-- MOV [eax+offset], rD
					emit to-bin32 offset
				]
			]
		]
	]
	
	patch-exit-call: func [code-buf [binary!] ptr [integer!] exit-point [integer!]][
		change at code-buf ptr to-bin32 exit-point - ptr - branch-offset-size
	]
	
	emit-exit: does [
		emit #{E9}									;-- JMP imm32
		emit-reloc-addr compose/only [- - (emitter/exits)]
	]

	emit-branch: func [
		code [binary!]
		op [word! block! logic! none!]
		offset [integer! none!]
		/back
		/local size imm8? opcode jmp
	][
		if verbose >= 3 [print [">>>inserting branch" either op [join "cc: " mold op][""]]]
		
		size: (length? code) - any [offset 0]				;-- offset from the code's head
		imm8?: size <= either back [126][127]				;-- account 2 bytes for JMP imm8
		opcode: either not none? op [						;-- explicitly test for none
			op: case [
				block? op [									;-- [cc] => keep
					op: op/1
					either logic? op [pick [= <>] op][op]	;-- [logic!] or [cc]
				]
				logic? op [pick [= <>] op]					;-- test for TRUE/FALSE
				'else 	  [opposite? op]					;-- 'cc => invert condition
			]
			add-condition op copy pick [#{70} #{0F80}] imm8?		;-- Jcc offset 	; 8/32-bit displacement
		][
			pick [#{EB} #{E9}] imm8?						;-- JMP offset 	; 8/32-bit displacement
		]
		if back [size: negate (size + (length? opcode) + pick [1 4] imm8?)]
		jmp: rejoin [opcode either imm8? [to-bin8 size][to-bin32 size]]
		insert any [all [back tail code] code] jmp
		length? jmp
	]
	
	emit-push: func [
		value [char! logic! integer! word! block! string! tag! path! get-word! object!]
		/with cast [object!]
		/local spec type
	][
		if verbose >= 3 [print [">>>pushing" mold value]]
		if block? value [value: <last>]
		
		switch type?/word value [
			tag! [									;-- == <last>
				emit #{50}							;-- PUSH eax
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
			word! [
				type: first compiler/get-variable-spec value
				either find [c-string! struct! pointer!] type [
					emit-variable value
						#{FF35}						;-- PUSH [value]		; global
						#{FF75}						;-- PUSH [ebp+n]		; local
				][
					emit-variable value
						#{FF35}						;-- PUSH dword [value]	; global
						[	
							#{8D45}					;-- LEA eax, [ebp+n]	; local
							offset					;-- n
							#{FF30}					;-- PUSH dword [eax]
						]
				]
			]
			get-word! [
				emit #{68}							;-- PUSH &value
				emit-reloc-addr emitter/get-func-ref to word! value	;-- value memory address
			]
			string! [
				spec: emitter/store-value none value [c-string!]
				emit #{68}							;-- PUSH value
				emit-reloc-addr spec/2				;-- one-based index
			]
			path! [
				emitter/access-path value none
				if cast [emit-casting cast no]
				emit-push <last>
			]
			object! [
				either path? value/data [
					emit-push/with value/data value
				][
					emit-push value/data
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
		if find [// ///] name [						;-- work around unaccepted '// and '///
			mod?: select [// mod /// rem] name		;-- convert operators to words (easier to handle)
			name: first [/]							;-- work around unaccepted '/ 
		]
		arg2: compiler/unbox args/2
		
		if all [
			find [+ -] name							;-- pointer arithmetic only allowed for + & -
			type: compiler/resolve-expr-type args/1
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
					emit-poly [#{F6EA} #{F7EA}] ;-- IMUL rD 			; commutable op
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
							emit #{89D3}				   ;-- MOV ebx, edx
							emit-poly [#{F6EB} #{F7EB}]	   ;-- IMUL rB		; result in ax|eax|edx:eax
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
						emit #{F6F3}				;-- DIV bl
					][
						emit-sign-extension			;-- 16/32-bit signed
						emit-poly [#{F6FB} #{F7FB}]	;-- IDIV rB ; rA / rB
					]
				]
				switch b [
					imm [							;-- SAR usage http://www.arl.wustl.edu/~lockwood/class/cs306/books/artofasm/Chapter_6/CH06-3.html#HEADING3-120
						emit #{52}					;-- PUSH edx	; save edx from corruption
						with-width-of/alt args/2 [							
							emit-poly [#{B2} #{BA} args/2] ;-- MOV rD, value
						]
						emit #{89D3}				;-- MOV ebx, edx
						do op-poly
					]
					ref [
						emit #{52}					;-- PUSH edx	; save edx from corruption
						emit-load/alt args/2
						emit #{89D3}				;-- MOV ebx, edx
						do op-poly
					]
					reg [
						emit #{89D3}				;-- MOV ebx, edx		; ebx = b
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
						emit #{0FBAE3}				;-- 	  BT rB, 7|15|31 ; @@ better way ?
						emit c
						emit #{7302}				;-- 	  JNC add		 ; (won't work with ax)
						emit-poly [#{F6DB} #{F7DB}]	;--		  NEG rB
						emit-poly [#{00D8} #{01D8}]	;-- add:  ADD rA, rB
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
		;TBD: test overflow and raise exception ? (or store overflow flag in a variable??)
		; JNO? (Jump if No Overflow)
	]
	
	emit-operation: func [name [word!] args [block!] /local a b c sorted? arg left right][
		if verbose >= 3 [print [">>>inlining op:" mold name mold args]]

		set-width args/1							;-- set reg/mem access width
		c: 1
		foreach op [a b][
			arg: either object? args/:c [compiler/cast args/:c][args/:c]		
			set op either arg = <last> [
				 'reg								;-- value in eax
			][
				switch type?/word arg [
					char! 	 ['imm]		 			;-- add or mov to al
					integer! ['imm] 				;-- add or mov to eax
					word! 	 ['ref] 				;-- fetch value
					block!   ['reg] 				;-- value in eax (or in edx)
					path!    ['reg] 				;-- value in eax (or in edx)
				]
			]
			c: c + 1
		]
		if verbose >= 3 [?? a ?? b]					;-- a and b hold addressing modes for operands

		;-- First operand processing
		left:  compiler/unbox args/1
		right: compiler/unbox args/2
		
		switch to path! reduce [a b] [
			imm/imm	[emit-poly [#{B0} #{B8} args/1]];-- MOV rA, a
			imm/ref [emit-load args/1]				;-- eax = a
			imm/reg [								;-- eax = b
				if path? right [
					emit-load args/2				;-- late path loading
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
					if block? args/2 [				;-- edx = b
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
		last-saved?: no								;-- reset flag
		if object? args/1 [emit-casting args/1 no]	;-- do runtime conversion on eax if required

		;-- Operator and second operand processing
		either all [object? args/2 find [imm reg] b][
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
	
	emit-cdecl-pop: func [spec [block!] args [block!] /local size][
		size: emitter/arguments-size? spec/4
		if all [
			spec/2 = 'syscall
			compiler/job/syscall = 'BSD
		][
			size: size + stack-width				;-- account for extra space
		]
		if issue? args/1 [							;-- test for variadic call
			size: length? args/2
			if spec/2 = 'native [
				size: size + pick [3 2] args/1 = #typed 	;-- account for extra arguments
			]
			size: size * stack-width
		]
		emit #{83C4}								;-- ADD esp, n
		emit to-bin8 size
	]
	
	patch-call: func [code-buf rel-ptr dst-ptr][
		change										;-- CALL NEAR disp size
			at code-buf rel-ptr
			to-bin32 dst-ptr - rel-ptr - ptr-size
	]
	
	emit-argument: func [arg func-type [word!]][
		either all [
			object? arg
			any [arg/type = 'logic! 'byte! = first compiler/get-type arg/data]
			not path? arg/data
		][
			unless block? arg [emit-load arg]		;-- block! means last value is already in eax (func call)
			emit-casting arg no
			emit-push <last>
			compiler/last-type: arg/type			;-- for inline unary functions
		][
			emit-push either block? arg [<last>][arg]
		]
	]
	
	emit-call: func [name [word!] args [block!] sub? [logic!] /local spec fspec type res total][
		if verbose >= 3 [print [">>>calling:" mold name mold args]]
		
		fspec: select compiler/functions name
		type: first spec: any [
			select emitter/symbols name				;@@
			next fspec
		]
		switch type [								;-- call or inline the function
			syscall [								;TBD: add support for SYSENTER/SYSEXIT
				switch compiler/job/syscall [
					BSD [							; http://www.freebsd.org/doc/en/books/developers-handbook/book.html#X86-SYSTEM-CALLS
						emit #{83EC04}				;-- SUB esp, 4		; extra entry (BSD convention)			
					]
					Linux [
						if fspec/1 >= 6 [
							emit #{89E8}			;-- MOV eax, ebp	; save frame pointer
						]
						repeat c fspec/1 [
							emit pick [
								#{5B}				;-- POP ebx			; get 1st arg in reg
								#{59}				;-- POP ecx			; get 2nd arg in reg
								#{5A}				;-- POP edx			; get 3rd arg in reg
								#{5E}				;-- POP esi			; get 4th arg in reg
								#{5F}				;-- POP edi			; get 5th arg in reg
								#{5D}				;-- POP ebp			; get 6th arg in reg
							] 1 + fspec/1 - c
						]
						if fspec/1 >= 6 [
							emit #{50}				;-- PUSH eax		; save frame pointer on stack
						]
					]
				]
				emit #{B8}							;-- MOV eax, code
				emit to-bin32 last fspec
				emit #{CD80}						;-- INT 0x80		; syscall
				switch compiler/job/syscall [
					BSD [emit-cdecl-pop fspec args]	;-- BSD syscall cconv (~ cdecl)
					Linux [
						if fspec/1 >= 6 [emit #{5D}];-- POP ebp			; restore frame pointer
					]
				]
			]
			import [
				either compiler/job/OS = 'MacOSX [
					emit #{B8}						;-- MOV eax, addr
					emit-reloc-addr spec
					emit #{FFD0} 					;-- CALL eax		; direct call
				][	
					emit #{FF15}					;-- CALL FAR [addr]	; indirect call
					emit-reloc-addr spec
				]
				if fspec/3 = 'cdecl [				;-- add calling cleanup when required
					emit-cdecl-pop fspec args
				]			
			]
			native [
				if issue? args/1 [					;-- variadic call
					emit-push 4 * length? args/2	;-- push arguments total size in bytes 
													;-- (required to clear stack on stdcall return)
					emit #{8D742404}				;-- LEA esi, [esp+4]	; skip last pushed value
					emit #{56}						;-- PUSH esi			; push arguments list pointer
					total: length? args/2
					if args/1 = #typed [total: total / 2]
					emit-push total					;-- push arguments count
				]
				emit #{E8}							;-- CALL NEAR disp
				emit-reloc-addr spec				;-- 32-bit relative displacement place-holder
				if fspec/3 = 'cdecl [				;-- in case of non-default calling convention
					emit-cdecl-pop fspec args
				]
			]
			inline [
				if block? args/1 [args/1: <last>]	;-- works only for unary functions	
				do select [
					not			[emit-not args/1]
					push		[emit-push args/1]
					pop			[emit-pop]
				] name
				if name = 'not [res: compiler/get-type args/1]
			]
			op	[
				emit-operation name args
				if sub? [emitter/logic-to-integer name]
				unless find comparison-op name [		;-- comparison always return a logic!
					res: any [
						;all [object? args/1 args/1/type]
						all [not sub? block? args/1 compiler/last-type]
						compiler/get-type args/1	;-- other ops return type of the first argument	
					]
				]
			]
		]
		res
	]
	
	emit-stack-align-prolog: func [args-nb [integer!] /local offset][
		if compiler/job/stack-align-16? [
			emit #{89E7}							;-- MOV edi, esp
			emit #{83E4F0}							;-- AND esp, -16
			offset: 1 + args-nb 					;-- account for saved edi
			unless zero? offset: offset // 4 [
				emit #{83EC}						;-- SUB esp, offset		; ensure call will be 16-bytes aligned
				emit to-bin8 (4 - offset) * 4
			]
			emit #{57}								;-- PUSH edi
		]
	]
	
	emit-stack-align-epilog: func [args-nb [integer!]][
		if compiler/job/stack-align-16? [
			emit #{5C}								;-- POP esp
		]
	]

	emit-prolog: func [name [word!] locals [block!] locals-size [integer!] /local fspec][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "prolog"]]

		emit #{55}									;-- PUSH ebp
		emit #{89E5}								;-- MOV ebp, esp
		unless zero? locals-size [
			emit #{83EC}							;-- SUB esp, locals-size
			emit to-char round/to/ceiling locals-size 4		;-- limits total local variables size to 255 bytes
		]
		fspec: select compiler/functions name
		if all [block? fspec/4/1 fspec/5 = 'callback][
			emit #{53}								;-- PUSH ebx
			emit #{56}								;-- PUSH esi
			emit #{57}								;-- PUSH edi
		]
	]

	emit-epilog: func [
		name [word!] locals [block!] args-size [integer!] locals-size [integer!]
		/local fspec
	][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "epilog"]]

		fspec: select compiler/functions name
		if all [block? fspec/4/1 fspec/5 = 'callback][
			emit #{5F}								;-- POP edi
			emit #{5E}								;-- POP esi
			emit #{5B}								;-- POP ebx
		]
		emit #{C9}									;-- LEAVE
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
				emit #{5B}							;-- POP ebx			; skip arguments count
				emit #{5B}							;-- POP ebx			; skip arguments pointer
				emit #{5B}							;-- POP ebx			; get stack offset
				emit #{01DC}						;-- ADD esp, ebx	; skip arguments list (clears stack)
				emit #{56}							;-- PUSH esi		; push return address
				emit #{C3}							;-- RET
			][
				emit #{C2}							;-- RET args-size
				emit to-bin16 round/to/ceiling args-size 4
			]
		]
	]
]
