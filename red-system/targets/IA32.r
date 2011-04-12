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
	struct-align-size: 4
	ptr-size: 4
	
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
	
	emit-length?: func [value [word! string! struct! tag!] /local spec size][
		if verbose >= 3 [print [">>>inlining: length?" mold value]]
		if value = <last> [value: 'last]
		
		switch type?/word value [
			word! [
				either value = 'last [
					emit #{89C6} 					;--       MOV esi, eax
				][
					emit-variable value
						#{BE}						;--       MOV esi, [value]		; global
						#{8B75}						;--		  MOV esi, [ebp+n]		; local
					emit #{89F0}					;--		  MOV eax, esi
					emit #{4E}						;-- 	  DEC esi
				]
				emit #{46}							;-- Loop: INC esi
				emit #{803E00}						;-- 	  CMP byte [esi], 0
				emit #{75FA}						;--		  JNZ Loop
				emit #{29C6}						;--		  SUB esi, eax			; do not count the null byte
				emit #{89F0}						;--		  MOV eax, esi
			]
			string! [
				;TBD: support or throw error?
			]
			struct! [
				size: 0
				foreach [n type] emitter/get-symbol-spec value [
					size: size + select emitter/datatypes type
				]
				size
			]
		]
	]
	
	emit-boolean-switch: does [
		emit #{31C0}								;-- 	  XOR eax, eax		; eax = 0 (FALSE)
		emit #{EB03}								;-- 	  JMP _exit
		emit #{31C0}								;--		  XOR eax, eax
		emit #{40}									;--		  INC eax			; eax = 1 (TRUE)
													;-- _exit:
		3											;-- offset to branch to TRUE part
	]
	
	emit-last: func [value [integer! word! string! struct! logic!] /local spec][
		switch type?/word value [
			logic!   [
				emit #{31C0}						;-- XOR eax, eax		; eax = 0 (FALSE)	
				if value [
					emit #{40}						;-- INC eax				; eax = 1 (TRUE)
				]
			]
			integer! [
				emit #{B8}							;-- MOV eax, value
				emit to-bin32 value
			]
			word!   [
				emit-variable value
					#{A1}							;-- MOV eax, [value]	; global
					#{8B45}							;-- MOV eax, [ebp+n]	; local
			]
			string! [
				spec: emitter/set-global reduce [emitter/make-noname [c-string!]] value
				emit #{}							;-- MOV eax, [string]
				emit-reloc-addr spec/2				;-- one-based index
			]
			struct! [
			
			]
		]
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
		imm8?: either back [size <= 126][size <= 127]		;-- account 2 bytes for JMP imm8
		opcode: either op [
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
	
	emit-push: func [value [logic! integer! word! block! string!] /local spec type gcode lcode][
		if verbose >= 3 [print [">>>pushing" mold value]]
		
		switch type?/word value [
			logic! [
				emit #{31C0}						;--	XOR eax, eax		; eax = 0 (FALSE)	
				if value [
					emit #{40}						;--	INC eax				; eax = 1 (TRUE)
				]
				emit #{50}							;-- PUSH eax
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
				type: first emitter/get-symbol-spec value
				either find [string! binary! struct!] type [
					gcode: #{68}					;-- PUSH imm32			; global value
					lcode: #{FF75}					;-- PUSH [ebp+n]		; local value
				][
					gcode: #{FF35}					;-- PUSH dword [value]	;TBD: test value size
					lcode: [
						#{8D45}						;-- LEA eax, [ebp+n]
						offset						;-- n
						#{FF30}						;-- PUSH dword [eax]
					]
				]
				emit-variable value gcode lcode			
			]
			block! [								;-- pointer
				;TBD
			]
			string! [
				spec: emitter/set-global reduce [emitter/make-noname [c-string!]] value
				emit #{68}							;-- PUSH value
				emit-reloc-addr spec/2				;-- one-based index
			]
		]
	]
	
	emit-path-access: func [/struct offset [integer!] /head name [word!] /store value [integer! word! tag!]][
		either head [
			either struct [
				either store [
					if value <> <last> [
						either integer? value [
							emit #{B8}				;-- MOV eax, value
							emit to-bin32 value
						][
							emit-variable value
								#{A1}				;-- MOV eax, [value]		; global
								#{8B45}				;-- MOV eax, [ebp+n]		; local
						]
					]
					emit-variable name
						#{BA}						;-- MOV edx, name			; global
						#{8B55}						;-- MOV edx, [ebp+n]		; local
					emit #{8942}					;-- MOV [edx+offset], eax
					emit to-bin8 offset
				][
					emit-variable name
						#{BA}						;-- MOV edx, name			; global
						#{8B75}						;-- MOV edx, [ebp+n]		; local
					emit #{8B42}					;-- MOV eax, [edx+offset]
					emit to-bin8 offset
				]
			][
				emit-variable name
					#{8B15}							;-- MOV edx, [name]			; global
					#{8B55}							;-- MOV edx, [ebp+n]		; local
				if store [
					either integer? value [
						emit #{C700}				;-- MOV dword [edx], value
						emit to-bin32 value
					][
						if value <> <last> [
							emit-variable value
								#{A1}				;-- MOV eax, [value] 		; global
								#{8B45}				;-- MOV eax, [ebp+n] 		; local
						]
						emit #{8902}				;-- MOV dword [edx], eax
					]
				]
			]
		][
			either store [
				either value = <last> [
					emit #{8B10}					;-- MOV edx, [eax]
				][
					emit #{8B15}					;-- MOV edx, [value]
					emit to-bin32 value
				]
				either struct [
					emit #{8950}					;-- MOV [eax+offset], edx
					emit to-bin8 offset
				][
					emit #{8910}					;-- MOV [eax], edx
				]
			][
				either struct [
					emit #{8B40}					;-- MOV eax, [eax+offset]
					emit to-bin8 offset
				][
					emit #{8B00}					;-- MOV eax, [eax]
				]
			]
		]
	]
		
	emit-store: func [name [word!] value [integer! word! string! struct! tag!] /local spec][
		if verbose >= 3 [print [">>>storing" mold name mold value]]
		if value = <last> [value: 'last]
		
;TBD: pass value in EAX ?
		spec: select emitter/symbols name
		switch type?/word value [
			integer! [
				emit-variable name
					#{C705}							;-- MOV [name], value	; (32-bit only!!!)
					#{C745}							;-- MOV [ebp+n], value	; (32-bit only!!!)					
				emit to-bin32 value
			]
			word! [
				if value <> 'last [
					emit-variable value
						#{A1}						;-- MOV eax, [value]	; global
						#{8B45}						;-- MOV eax, [ebp+n]	; local
				]
				emit-variable name
					#{A3}							;-- MOV [name], eax		; global variable
					#{8945}							;-- MOV [ebp+n], eax	; local variable
			]
			string! [
				if find emitter/stack name [
					spec: emitter/set-global reduce [emitter/make-noname [c-string!]] value
					emit-variable name
						#{}							;-- no code to emit, handled by higher layer
						#{C745}						;-- MOV [ebp+n], value
					emit-reloc-addr spec/2
				]
			]
			struct! [
				;-- nothing to emit
			]
		]
	]
	
	emit-operation: func [name [word!] args [block!] /local a b c boolean-op code][
		if verbose >= 3 [print [">>>inlining op:" mold name mold args]]
		
		c: 1
		foreach op [a b][	
			set op either args/:c = <last> [
				 'reg								;-- value in eax
			][
				switch type?/word args/:c [
					integer! ['imm] 				;-- add or mov to eax
					word! 	 ['ref] 				;-- fetch value
					block!   ['reg] 				;-- value in eax (or in edx)
					path!    ['reg] 				;-- value in eax
				]
			]
			c: c + 1
		]
		if verbose >= 3 [?? a ?? b]
		
		if find [imm ref] a [						;-- load eax with 1st operand
			if b = 'reg [							;-- 2nd operand in eax, save it in edx
				emit #{89C2}						;-- MOV edx, eax
			]
			either a = 'imm [
				emit #{B8}							;-- MOV eax, a
				emit to-bin32 args/1
			][
				emit-variable args/1
					#{A1}							;-- MOV eax, [a]		; global
					#{8B45}							;-- MOV eax, [ebp+n]	; local
			]
		]
		;-- Math operations --
		switch name [
			+ [
				switch b [
					imm [
						either args/2 = 1 [			;-- trivial optimization
							emit #{40}				;-- INC eax
						][
							emit #{05}				;-- ADD eax, value
							emit to-bin32 args/2
						]
					]
					ref [	
						emit-variable args/2
							#{0305}					;-- ADD eax, [value]	; global
							#{0345}					;-- ADD eax, [ebp+n]	; local
					]
					reg [emit #{01D0}]				;-- ADD eax, edx		; commutable op
				]
			]
			- [
				switch b [
					imm [
						either args/2 = 1 [			;-- trivial optimization
							emit #{48}				;-- DEC eax
						][
							emit #{2D}				;-- SUB eax, value
							emit to-bin32 args/2
						]
					]
					ref [
						emit-variable args/2
							#{2B05}					;-- SUB eax, [value]	; global
							#{2B45}					;-- SUB eax, [ebp+n]	; local
					]
					reg [
						if a = 'reg [				;-- eax = b, edx = a
							emit #{92}				;-- XCHG eax, edx		; swap
						]
						emit #{29D0}				;-- SUB eax, edx		; not commutable op
					]
				]
			]
			* [
				switch b [
					imm [
						either c: power-of-2? args/2 [		;-- trivial optimization for b=2^n
							emit #{C1E0}			;-- SAL eax, log2(b)
							emit to-bin8 c
						][
							emit #{69C0}			;-- IMUL eax, value
							emit to-bin32 args/2
						]
					]
					ref [
						emit-variable args/2
							#{0FAF05}				;-- IMUL eax, [value]	; global
							#{0FAF45}				;-- IMUL eax, [ebp+n]	; local
					]
					reg [emit #{0FAFC2}]			;-- IMUL eax, edx 		; commutable op
				]
			]
			/ [
				switch b [
			;TBD: check for 0 divider both at compilation-time and runtime
					imm [
						either c: power-of-2? args/2 [		;-- trivial optimization for b=2^n
							emit #{C1F8}			;-- SAR eax, log2(b)
							emit to-bin8 c
						][
							emit #{BB}				;-- MOV ebx, value
							emit to-bin32 args/2
							emit #{31D2}			;-- XOR edx, edx		; edx = 0
							emit #{F7FB}			;-- IDIV ebx			; edx:eax / ebx => eax,edx
						]
					]
					ref [
						emit #{31D2}				;-- XOR edx, edx		; edx = 0
						emit-variable args/2
							#{F73D}					;-- IDIV dword [value]	; global
							#{F77D}					;-- IDIV dword [ebp+n]	; local
					]
					reg [
						either a = 'reg [			;-- eax = b, edx = a
							emit #{92}				;-- XCHG eax, edx		; swap, eax = a, edx = b
							emit #{89D3}			;-- MOV ebx, edx		; ebx = b
						][
							emit #{89C3}			;-- MOV ebx, eax		; ebx = b
						]
						emit #{31D2}				;-- XOR edx, edx		; edx = 0
						emit #{F7FB}				;-- IDIV ebx 			; not commutable op
					]
				]
			]
		]
		;TBD: test overflow and raise exception ? (or store overflow flag in a variable??)
		; JNO? (Jump if No Overflow)
		
		if find comparison-op name [
			switch b [
				imm [
					emit #{3D}						;-- CMP eax, value
					emit to-bin32 args/2
				]
				ref [
					emit-variable args/2
						#{8B15}						;-- MOV edx, [value]	; global
						#{8B55}						;-- MOV edx, [ebp+n]	; local
					emit #{39D0}					;-- CMP eax, edx		; commutable op
				]
				reg [
					if a = 'reg [					;-- eax = b, edx = a
						emit #{92}					;-- XCHG eax, edx		; swap
					]
					emit #{39D0}					;-- CMP eax, edx		; not commutable op
				]
			]
		]
		
		;-- Boolean operations --
		boolean-op: [
			switch b [
				imm [
					emit code/1						;-- <OP> eax, value
					emit to-bin32 args/2
				]
				ref [
					emit-variable args/2
						code/2						;-- <OP> eax, [value]	; global
						code/3						;-- <OP> eax, [ebp+n]	; local
				]
				reg [emit code/4]					;-- <OP> eax, edx		; commutable op
			]
		]		
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
		if code [do boolean-op]
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
	
	emit-call: func [name [word!] args [block!] /sub /local spec fspec][
		if verbose >= 3 [print [">>>calling:" mold name mold args]]

		fspec: select compiler/functions name
		spec: any [
			select emitter/symbols name
			next fspec
		]
		case [
			not find [inline op] spec/1 [			;-- push function's arguments on stack
				foreach arg args [
					switch/default type?/word arg [
						binary! [emit arg]
						block!  [
							emit-call/sub arg/1 next arg
							emit #{50}				;-- PUSH eax		; push returned value
						]
					][
						emit-push arg
					]
				]
			]
			spec/1 = 'op [
				if block? args/1 [
					emit-call/sub args/1/1 next args/1
					if block? args/2 [				;-- save first argument result in another register
						emit #{89C2}				;-- MOV edx, eax
					]
				]
				if block? args/2 [
					emit-call/sub args/2/1 next args/2	;-- result in eax
				]
			]
		]
		switch spec/1 [								;-- call or inline the function
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
				do select [
					length? [emit-length? args/1]
				] name
			]
			op	[
				emit-operation name args
				if sub [emitter/logic-to-integer name]
				<last>
			]
		]
	]

	emit-prolog: func [name locals [block!] args-size [integer!]][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "prolog"]]
		
		emit #{55}									;-- PUSH ebp
		emit #{89E5}								;-- MOV ebp, esp
		unless zero? args-size [
			emit #{83EC}							;-- SUB esp, locals-size
			emit to-char align-to args-size 4
		]
	]

	emit-epilog: func [name locals [block!] locals-size [integer!]][
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