REBOL [
	Title:   "Red/System IA32 code emitter"
	Author:  "Nenad Rakocevic"
	File: 	 %IA32.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

make target-class [
	target: 'IA32
	little-endian?: yes
	struct-align-size: 	4
	ptr-size: 			4
	default-align:		4
	stack-width:		4
	branch-offset-size:	4							;-- size of JMP offset
	
	conditions: make hash! [
		overflow?		 #{00}
		not-overflow?	 #{01}			
		=				 #{04}
		<>				 #{05}
		even?			 #{0A}
		odd?			 #{0B}
		<				 #{0C}
		>=				 #{0D}
		<=				 #{0E}
		>				 #{0F}
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

	emit-load-literal: func [type [block! none!] value /local spec][
		unless type [type: compiler/get-mapped-type value]
		spec: emitter/store-value none value type
		emit #{B8}							;-- MOV eax, value
		emit-reloc-addr spec/2				;-- one-based index
	]
		
	emit-not: func [value [word! tag! integer! logic! path!] /local opcodes][
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
				switch first compiler/get-variable-spec value opcodes
			]
			tag! [
				switch compiler/last-type opcodes
			]
			path! [
				emitter/access-path value none
				do opcodes/integer!
			]
		]
	]
	
	emit-to-logic: func [type [word! block!]][
		type: compiler/blockify type
		if verbose >= 3 [print [">>>converting to logic! from:" mold type/1]]
		
		set-width/type type/1
		emit-poly [#{3C} #{3D} 0]					;-- 	   CMP rA, 0
		emit #{7403}								;--        JZ _exit
		emit #{31C0}								;--        XOR eax, eax
		emit #{40}									;-- 	   INC eax
													;-- _exit:
	]
	
	emit-boolean-switch: does [
		emit #{31C0}								;-- 	  XOR eax, eax	; eax = 0 (FALSE)
		emit #{EB03}								;-- 	  JMP _exit
		emit #{31C0}								;--		  XOR eax, eax
		emit #{40}									;--		  INC eax		; eax = 1 (TRUE)
													;-- _exit:
		reduce [3 7]								;-- [offset-TRUE offset-FALSE]
	]
	
	emit-load: func [value [char! logic! integer! word! string! struct! path! paren!]][
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
		name [word!] value [char! logic! integer! word! string! paren! tag!] spec [block! none!]
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
			string! [
				do store-dword
				emit-reloc-addr spec/2
			]
			paren! [
				do store-dword
				either value/1 = 'pointer [
					emit to-bin32 0
				][
					emit-reloc-addr spec/2
				]
			]
		]
	]
	
	emit-init-path: func [name [word!]][
		emit-variable name
			#{A1}									;-- MOV eax, [name]			; global
			#{8B45}									;-- MOV eax, [ebp+n]		; local
	]
	
	emit-access-path: func [path [path! set-path!] spec [block! none!] /short /local offset][
		if verbose >= 3 [print [">>>accessing path:" mold path]]

		unless spec [
			spec: second compiler/resolve-type path/1
			emit-init-path path/1
		]
		if short [return spec]
		
		either zero? offset: emitter/member-offset? spec path/2 [
			emit #{8B00}							;-- MOV eax, [eax]
		][
			emit #{8B80}							;-- MOV eax, [eax+offset]
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
				[#{} #{8910}  ]						;-- MOV [eax], dx|edx
				[#{} #{8990}  ]						;-- MOV [eax + idx * sizeof(p/value)], dx|edx
				[#{} #{891498}]						;-- MOV [eax + ebx * sizeof(p/value)], dx|edx
			][										;-- load path opcodes --
				[#{} #{8B00}  ]						;-- MOV ax|eax, [eax]
				[#{} #{8B80}  ]						;-- MOV ax|eax, [eax + idx * sizeof(p/value)]
				[#{} #{8B0498}]						;-- MOV ax|eax, [eax + ebx * sizeof(p/value)]
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
				either zero? offset: emitter/member-offset? parent path/2 [
					emit #{8910}					;-- MOV [eax], edx
				][
					emit #{8990}					;-- MOV [eax+offset], edx
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
				block? op [op/1]							;-- [cc] => keep
				logic? op [pick [= <>] op]					;-- test for TRUE/FALSE
				'else 	  [opposite? op]					;-- 'cc => invert condition
			]
			conditions/:op or pick [#{70} #{0780}] imm8?	;-- Jcc offset 	; 8/32-bit displacement
		][
			pick [#{EB} #{E9}] imm8?						;-- JMP offset 	; 8/32-bit displacement
		]
		if back [size: negate (size + (length? opcode) + pick [1 4] imm8?)]
		jmp: rejoin [opcode either imm8? [to-bin8 size][to-bin32 size]]
		insert any [all [back tail code] code] jmp
		length? jmp
	]
	
	emit-push: func [value [char! logic! integer! word! block! string! tag! path!] /local spec type][
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
				emit-variable-poly args/2
					#{8A15} #{8B15}					;-- MOV rD, [value]		; global
					#{8A55} #{8B55}					;-- MOV rD, [ebp+n]		; local
				emit-poly [#{38D0} #{39D0}]			;-- CMP rA, rD			; commutable op				
			]
			reg [
				if a = 'reg [						;-- eax = b, edx = a
					emit #{92}						;-- XCHG eax, edx		; swap
				]
				emit-poly [#{38D0} #{39D0}]			;-- CMP rA, rD			; not commutable op
			]
		]
	]
	
	emit-math-op: func [name [word!] a [word!] b [word!] args [block!] /local mod? scale c][
		if name = first [//][						;-- work around unaccepted '// 
			name: first [/]							;-- work around unaccepted '/ 
			mod?: yes
		]
		if all [
			find [+ -] name							;-- pointer arithmetic only allowed for + & -
			block? type: any [
				all [word? args/1 compiler/resolve-type args/1]
				all [path? args/1 compiler/resolve-path-type args/1]
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
			;TBD: check for 0 divider both at compilation-time and runtime
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
								#{F63D} #{F73D}		;-- IDIV word|dword [value]	; global
								#{F67D} #{F77D}		;-- IDIV word|dword [ebp+n]	; local
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
					emit-poly [#{88E0} #{89D0}]		;-- MOV rA, remainder	; remainder in al|ax|eax
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
			find [+ - * / //]  name	[emit-math-op		name a b args]
			find [and or xor]  name	[emit-bitwise-op	name a b args]
		]
	]
	
	emit-get-address: func [name [word!]][
		if verbose >= 3 [print [">>>getting address of:" mold name]]
		
		emit #{B8}									;-- MOV eax, &name
		emit-reloc-addr emitter/get-func-ref name	;-- symbol address
	]
	
	emit-cdecl-pop: func [spec [block!] /local size][
		size: emitter/arguments-size? spec/4
		if spec/3 = 'gcc45 [
			;TBD: align on 16 bytes boundary
			;     see http://en.wikipedia.org/wiki/X86_calling_conventions#cdecl
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
				repeat c fspec/1 [
					emit pick [
						#{5B}						;-- POP ebx			; get 1st arg in reg
						#{59}						;-- POP ecx			; get 2nd arg in reg
						#{5A}						;-- POP edx			; get 3rd arg in reg
						#{5E}						;-- POP esi			; get 4th arg in reg
						#{5F}						;-- POP edi			; get 5th arg in reg
					] 1 + fspec/1 - c
				]
				emit #{B8}							;-- MOV eax, code
				emit to-bin32 last fspec
				emit #{CD80}						;-- INT 0x80		; syscall
			]
			import [
				emit #{FF15}						;-- CALL FAR [addr]
				emit-reloc-addr spec
				if find [cdecl gcc45] fspec/3 [		;-- add calling cleanup when required
					emit-cdecl-pop fspec
				]			
			]
			native [
				emit #{E8}							;-- CALL NEAR disp
				emit-reloc-addr spec				;-- 32-bit relative displacement place-holder
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

	emit-prolog: func [name [word!] locals [block!] args-size [integer!]][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "prolog"]]
		
		emit #{55}									;-- PUSH ebp
		emit #{89E5}								;-- MOV ebp, esp
		unless zero? args-size [
			emit #{83EC}							;-- SUB esp, locals-size
			emit to-char align-to args-size 4
		]
	]

	emit-epilog: func [name [word!] locals [block!] locals-size [integer!]][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "epilog"]]
		
		emit #{C9}									;-- LEAVE
		either zero? locals-size [
			emit #{C3}								;-- RET
		][
			emit #{C2}								;-- RETN args-size
			emit to-bin16 align-to locals-size 4
		]
	]
]