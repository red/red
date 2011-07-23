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
			2 < length? spec [emit to-bin to integer! spec/3]	;-- emit displacement or immediate
			3 < length? spec [emit to-bin to integer! spec/4]	;-- emit displacement or immediate
		]	
	]
	
	emit-variable-poly: func [							;-- polymorphic variable access generation
		name [word!]
		    g8 [binary!] 		g32 [binary!]			;-- opcodes for global variables
			l8 [binary! block!] l32 [binary! block!]	;-- opcodes for local variables
	][
		switch width [
			1 [emit-variable name g8 l8]				;-- 8-bit
			2 [emit #{66} emit-variable name g32 l32]	;-- 16-bit
			4 [emit-variable name g32 l32]				;-- 32-bit
		]
	]
	
	emit-save-last: does [
		emit #{89C2}								;-- MOV edx, eax
	]
	
	emit-casting: func [spec [block!] alt? [logic!] /local old][
		case [
			spec/1 = 'logic! [
				if verbose >= 3 [print [">>>converting from" mold/flat spec/2 "to logic!"]]
				old: width
				set-width/type spec/2
				either alt? [
					emit-poly [#{80FA00} #{83FA00}]		;-- 	   CMP rD, 0
					emit #{7403}						;--        JZ _exit
					emit #{31D2}						;--        XOR edx, edx
					emit #{42}							;-- 	   INC edx
				][										;-- _exit:
					emit-poly [#{3C00} #{83F800}]		;-- 	   CMP rA, 0
					emit #{7403}						;--        JZ _exit
					emit #{31C0}						;--        XOR eax, eax
					emit #{40}							;-- 	   INC eax
				]										;-- _exit:
				width: old
			]
			all [spec/1 = 'integer!	spec/2 = 'byte!][
				if verbose >= 3 [print ">>>converting from byte! to integer! "]
				emit pick [#{81E2} #{25}] alt?		;-- AND edx|eax, 000000FFh
				emit to-bin32 255
			]
		]
	]

	emit-load-literal: func [type [block! none!] value /local spec][	
		unless type [type: compiler/get-mapped-type value]
		spec: emitter/store-value none value type
		emit #{B8}									;-- MOV eax, value
		emit-reloc-addr spec/2						;-- one-based index
	]
		
	emit-not: func [value [word! tag! integer! logic! path! string!] /local opcodes][
		if verbose >= 3 [print [">>>emitting NOT" mold value]]
		
		opcodes: [
			logic!	 [emit #{3401}]					;-- XOR al, 1			; invert 0<=>1
			byte!	 [emit #{F6D0}]					;-- NOT al				; @@ missing 16-bit support									
			integer! [emit #{F7D0}]					;-- NOT eax
		]
		switch type?/word value [
			logic! [
				emit-load not value
			]
			integer! [
				emit-load value
				do opcodes/integer!
			]
			word! [
				emit-load value
				type: first compiler/get-variable-spec value
				if find [pointer! c-string! struct!] type [ ;-- type casting trap
					type: 'logic!
				]
				switch type opcodes
			]
			tag! [
				switch compiler/last-type opcodes
			]
			string! [								;-- type casting trap
				emit-load value
				do opcodes/logic!
			]
			path! [
				emitter/access-path value none
				do opcodes/integer!
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
	
	emit-load: func [value [char! logic! integer! word! string! struct! path! paren! get-word!]][
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
				set-width value
				emit-variable-poly value
					#{A0}   #{A1}					;-- MOV rA, [value]		; global
					#{8A45} #{8B45}					;-- MOV rA, [ebp+n]		; local	
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
		]
	]
	
	emit-store: func [
		name [word!] value [char! logic! integer! word! string! paren! tag! get-word!] spec [block! none!]
		/local store-dword
	][
		if verbose >= 3 [print [">>>storing" mold name mold value]]
		if value = <last> [value: 'last]
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
				if value <> 'last [
					emit-variable-poly value
						#{A0}   #{A1}				;-- MOV rA, [value]		; global
						#{8A45} #{8B45}				;-- MOV rA, [ebp+n]		; local	
				]
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
	
	emit-access-path: func [path [path! set-path!] spec [block! none!] /short /local offset type][
		if verbose >= 3 [print [">>>accessing path:" mold path]]

		unless spec [
			spec: second compiler/resolve-type path/1
			emit-init-path path/1
		]
		if short [return spec]
		
		type: first compiler/resolve-type/with path/2 spec
		set-width/type type							;-- adjust operations width to member value size

		either zero? offset: emitter/member-offset? spec path/2 [
			emit-poly [#{8A00} #{8B00}]				;-- MOV rA, [eax]
		][
			emit-poly [#{8A80} #{8B80}]				;-- MOV rA, [eax+offset]
			emit to-bin32 offset
		]
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
				emit to-bin32 idx * emitter/size-of? 'integer!
			]
		][
			emit-load-index idx
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
		value [char! logic! integer! word! block! string! tag! path! get-word!]
		/local spec type
	][
		if verbose >= 3 [print [">>>pushing" mold value]]
		
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
			block! [								;-- pointer
				; @@ (still required?)
			]
			string! [
				spec: emitter/store-value none value [c-string!]
				emit #{68}							;-- PUSH value
				emit-reloc-addr spec/2				;-- one-based index
			]
			path! [
				emitter/access-path value none
				emit-push <last>
			]
		]
	]
	
	emit-sign-extension: does [
		emit switch width [
			1 [#{6698}]								;-- extend AL to AX
			2 [#{6699}]								;-- extend AX to DX:AX
			4 [#{99}]								;-- extend EAX to EDX:EAX
		]
	]
	
	emit-bitshift-op: func [name [word!] a [word!] b [word!] args [block!] /local c][
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
			unless all [0 <= args/2 args/2 <= c][		
				compiler/backtrack name
				compiler/throw-error rejoin [
					"a value in 0-" c " range is required for this shift operation"
				]
			]
			emit to-bin8 args/2
		]
	]
	
	emit-bitwise-op: func [name [word!] a [word!] b [word!] args [block!] /local code][		
		code: select [
			and [
				#{25}								;-- AND eax, value
				#{2305}								;-- AND eax, [value]	; global
				#{2345}								;-- AND eax, [ebp+n]	; local
				#{21D0}								;-- AND eax, edx		; commutable op
			]
			or [
				#{0D}								;-- OR eax, value
				#{0B05}								;-- OR eax, [value]		; global
				#{0B45}								;-- OR eax, [ebp+n]		; local
				#{09D0}								;-- OR eax, edx			; commutable op				
			]
			xor [
				#{35}								;-- XOR eax, value
				#{3305}								;-- XOR eax, [value]	; global
				#{3345}								;-- XOR eax, [ebp+n]	; local
				#{31D0}								;-- XOR eax, edx		; commutable op			
			]
		] name
		
		switch b [
			imm [
				emit code/1							;-- <OP> eax, value
				emit to-bin32 args/2
			]
			ref [
				emit-variable args/2
					code/2							;-- <OP> eax, [value]	; global
					code/3							;-- <OP> eax, [ebp+n]	; local
			]
			reg [emit code/4]						;-- <OP> eax, edx		; commutable op
		]
	]
	
	emit-comparison-op: func [name [word!] a [word!] b [word!] args [block!]][
		switch b [
			imm [
				emit-poly [#{3C} #{3D} args/2]		;-- CMP rA, value
			]
			ref [
				with-right-casting [		
					emit-variable-poly args/2
						#{8A15} #{8B15}				;-- MOV rD, [value]		; global
						#{8A55} #{8B55}				;-- MOV rD, [ebp+n]		; local
				]				
				emit-poly [#{38D0} #{39D0}]			;-- CMP rA, rD			; not commutable op				
			]
			reg [
				with-right-casting [
					if a = 'reg [					;-- eax = b, edx = a
						emit #{92}					;-- XCHG eax, edx		; swap
					]
				]
				emit-poly [#{38D0} #{39D0}]			;-- CMP rA, rD			; not commutable op
			]
		]
	]
	
	emit-math-op: func [name [word!] a [word!] b [word!] args [block!] /local mod? scale c][
		if find [// ///] name [						;-- work around unaccepted '// and '///
			mod?: select [// mod /// rem] name		;-- convert operators to words (easier to handle)
			name: first [/]							;-- work around unaccepted '/ 
		]
		if all [
			find [+ -] name							;-- pointer arithmetic only allowed for + & -
			block? type: any [
				all [word? args/1 compiler/resolve-type args/1]
				all [path? args/1 compiler/resolve-path-type args/1]
				all [block? args/1 compiler/resolve-aliased compiler/last-type]
			]
			scale: switch type/1 [
				pointer! [emitter/size-of? type/2/1]		;-- scale factor: size of pointed value
				struct!  [emitter/member-offset? type/2 none] ;-- scale factor: total size of the struct
			]
		][	
			either compiler/literal? args/2 [
				args/2: args/2 * scale				;-- 'b is a literal, so scale it directly
			][
				if find [imm ref] a [				;-- 'b will now be stored in reg, so save 'a
					emit-poly [#{88C2} #{89C2}]		;-- MOV rD, rA
				]
				emit-operation '* reduce [args/2 scale] ;-- 'b is a reference, emit code
				if name = '- [emit #{92}]			;-- XCHG eax, edx		; put operands in right order
				b: 'reg
			]
		]
		switch name [
			+ [
				switch b [
					imm [
						emit-poly either args/2 = 1 [	;-- trivial optimization
							[#{FEC0} #{40}]			;-- INC rA
						][
							[#{04} #{05} args/2] 	;-- ADD rA, value
						]
					]
					ref [
						emit-variable-poly args/2
							#{0205} #{0305}			;-- ADD rA, [value]		; global
							#{0245} #{0345}			;-- ADD rA, [ebp+n]		; local
					]
					reg [
						emit-poly [#{00D0} #{01D0}]	;-- ADD rA, rD			; commutable op
					]
				]
			]
			- [
				switch b [
					imm [
						emit-poly either args/2 = 1 [ ;-- trivial optimization
							[#{FEC8} #{48}]			;-- DEC rA
						][
							[#{2C} #{2D} args/2] 	;-- SUB rA, value
						]
					]
					ref [
						emit-variable-poly args/2
							#{2A05} #{2B05}			;-- SUB rA, [value]		; global
							#{2A45} #{2B45}			;-- SUB rA, [ebp+n]		; local
					]
					reg [
						if a = 'reg [				;-- eax = b, edx = a
							emit #{92}				;-- XCHG eax, edx		; swap
						]
						emit-poly [#{28D0} #{29D0}] ;-- SUB rA, rD			; not commutable op
					]
				]
			]
			* [
				switch b [
					imm [
						either all [
							not zero? args/2
							c: power-of-2? args/2	;-- trivial optimization for b=2^n
						][
							either width = 1 [
								emit #{C0E0}		;-- SHL al, log2(b)	; 8-bit unsigned
							][
								emit-poly [#{C0ED} #{C1E0}]	;-- SAL rA, log2(b) ; signed
							]
							emit to-bin8 c
						][
							emit-poly [#{B2} #{BA} args/2] ;-- MOV rD, value
							emit-poly [#{F6EA} #{F7EA}]	 ;-- IMUL rD		; result in ax|eax|edx:eax
						]
					]
					ref [
						emit-variable-poly args/2
							#{F62D}	#{F72D}			;-- IMUL [value]		; global
							#{F66D}	#{F76D}			;-- IMUL [ebp+n]		; local
					]
					reg [
						emit-poly [#{F6EA} #{F7EA}] ;-- IMUL rD 			; commutable op
					]
				]
			]
			/ [
				div-poly: [
					either width = 1 [				;-- 8-bit unsigned
						emit #{B400}				;-- MOV ah, 0			; clean-up garbage in ah
						emit #{F6F3}				;-- DIV bl
					][
						emit-sign-extension			;-- 16/32-bit signed
						emit-poly [#{F6FB} #{F7FB}]	;-- IDIV rB ; rA / rB
					]
				]
				switch b [
					imm [
						either all [
							not mod?				;-- do not use shifts if modulo
							c: power-of-2? args/2
						][							;-- trivial optimization for b=2^n
							either width = 1 [
								emit #{C0E8}		;-- SHR al, log2(b)	; 8-bit unsigned
							][
								emit-poly [#{C0F8} #{C1F8}]	;-- SAR rA, log2(b)	; signed
							]
							emit to-bin8 c
						][
							emit-poly [#{B3} #{BB} args/2] ;-- MOV rB, value
							do div-poly
						]
					]
					ref [
						either width = 1 [
							emit #{B400}			;-- MOV ah, 0			; clean-up garbage in ah
							emit-variable args/2
								#{F635}				;-- DIV byte [value]	; global
								#{F675}				;-- DIV byte [ebp+n]	; local
						][
							emit-sign-extension
							emit-variable-poly args/2
								#{8A1D} #{8B1D}		;-- MOV rB, word|dword [value]	; global
								#{8A5D} #{8B5D}		;-- MOV rB, word|dword [ebp+n]	; local
							do div-poly
						]
					]
					reg [
						either a = 'reg [			;-- eax = b, edx = a
							emit #{92}				;-- XCHG eax, edx		; swap, eax = a, edx = b
							emit #{89D3}			;-- MOV ebx, edx		; ebx = b
						][
							emit #{89C3}			;-- MOV ebx, eax		; ebx = b
						]
						do div-poly
					]
				]
				if mod? [
					emit-poly [#{88E0} #{89D0}]		;-- MOV rA, remainder	; remainder from ah|dx|edx
					if all [mod? <> 'rem width > 1][;-- modulo, not remainder
					;-- Adjust modulo result to be mathematically correct:
					;-- 	if modulo < 0 [
					;--			if divider < 0  [divider: negate divider]
					;--			modulo: modulo + divider
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
			]
		]
		;TBD: test overflow and raise exception ? (or store overflow flag in a variable??)
		; JNO? (Jump if No Overflow)
	]
	
	emit-operation: func [name [word!] args [block!] /local a b c][
		if verbose >= 3 [print [">>>inlining op:" mold name mold args]]
		
		set-width args/1							;-- set reg/mem access width
		c: 1
		foreach op [a b][	
			set op either args/:c = <last> [
				 'reg								;-- value in eax
			][
				switch type?/word args/:c [
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
		if find [imm ref] a [						;-- load eax with 1st operand
			if b = 'reg [							;-- 2nd operand in eax, save it in edx
				emit-poly [#{88C2} #{89C2}]			;-- MOV rD, rA
			]
			either a = 'imm [
				emit-poly [#{B0} #{B8} args/1]		;-- MOV rA, a
			][
				emit-load args/1
			]
		]
		;-- Operator and second operand processing
		case [
			find comparison-op name [emit-comparison-op name a b args]
			find math-op	   name	[emit-math-op		name a b args]
			find bitwise-op	   name	[emit-bitwise-op	name a b args]
			find bitshift-op   name [emit-bitshift-op   name a b args]
		]
	]
	
	emit-cdecl-pop: func [spec [block!] /local size][
		size: emitter/arguments-size? spec/4
		if all [
			spec/2 = 'syscall
			compiler/job/syscall = 'BSD
		][
			size: size  + 1							;-- account for extra space
		]
		emit #{83C4}								;-- ADD esp, n
		emit to-bin8 size
	]
	
	emit-call: func [name [word!] args [block!] sub? [logic!] /local spec fspec type res][
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
						repeat c fspec/1 [
							emit pick [
								#{5B}				;-- POP ebx			; get 1st arg in reg
								#{59}				;-- POP ecx			; get 2nd arg in reg
								#{5A}				;-- POP edx			; get 3rd arg in reg
								#{5E}				;-- POP esi			; get 4th arg in reg
								#{5F}				;-- POP edi			; get 5th arg in reg
							] 1 + fspec/1 - c
						]
					]
				]
				emit #{B8}							;-- MOV eax, code
				emit to-bin32 last fspec
				emit #{CD80}						;-- INT 0x80		; syscall
				if compiler/job/syscall = 'BSD [
					emit-cdecl-pop fspec			;-- BSD syscall cconv ~ cdecl 
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
					emit-cdecl-pop fspec
				]			
			]
			native [
				emit #{E8}							;-- CALL NEAR disp
				emit-reloc-addr spec				;-- 32-bit relative displacement place-holder
				if fspec/3 = 'cdecl [				;-- in case of not default calling convention
					emit-cdecl-pop fspec
				]
			]
			inline [
				if block? args/1 [args/1: <last>]		;-- works only for unary functions	
				do select [
					not	[emit-not args/1]
				] name
			]
			op	[
				emit-operation name args
				if sub? [emitter/logic-to-integer name]
				unless find comparison-op name [		;-- comparison always return a logic!
					res: compiler/argument-type? args/1	;-- other ops return type of the first argument	
				]
			]
		]
		res
	]
	
	emit-stack-align-prolog: func [args [block!] /local offset][
		if compiler/job/stack-align-16? [
			emit #{89E7}							;-- MOV edi, esp
			emit #{83E4F0}							;-- AND esp, -16
			offset: 1 + length? args				;-- account for saved edi
			unless zero? offset: offset // 4 [
				emit #{83EC}						;-- SUB esp, offset		; ensure call will be 16-bytes aligned
				emit to-bin8 (4 - offset) * 4
			]
			emit #{57}								;-- PUSH edi
		]
	]
	
	emit-stack-align-epilog: func [args [block!]][
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
			emit to-char align-to locals-size 4
		]
		fspec: select compiler/functions name
		if all [block? fspec/4/1 find fspec/4/1 'callback] [
			emit #{53}								;-- PUSH ebx
			emit #{56}								;-- PUSH esi
			emit #{57}								;-- PUSH edi
		]
	]

	emit-epilog: func [name [word!] locals [block!] args-size [integer!] /local fspec][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "epilog"]]

		fspec: select compiler/functions name
		if all [block? fspec/4/1 find fspec/4/1 'callback] [
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
			emit #{C2}								;-- RET args-size
			emit to-bin16 align-to args-size 4
		]
	]
	
	emit-read-args: does [
		emit #{8B35}								;-- MOV esi, [system]
		emit-reloc-addr emitter/symbols/system
		either compiler/job/OS = 'Syllable [
			emit #{58}									;-- POP eax				; dummy
			emit #{58}									;-- POP eax
			emit #{894604}								;-- MOV [esi+4], eax	; &argv
			emit #{58}									;-- POP eax
			emit #{894608}								;-- MOV [esi+8], eax	; &envp
		][
			emit #{58}									;-- POP eax
			emit #{8906}								;-- MOV [esi], eax		; argc
			emit #{896604}								;-- MOV [esi+4], esp	; argv[0]
		]
	]
]
