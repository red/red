REBOL [
	Title:   "Red/System x86-64 code emitter"
	Author:  "Red Foundation"
	File: 	 %X86-64.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

make-profilable make target-class [
	target: 'X86-64
	little-endian?: yes
	struct-align-size:	8
	ptr-size:			8
	default-align:		8
	stack-width:		8
	stack-slot-max:		8
	args-offset:		16
	branch-offset-size:	4
	locals-offset:		32
	def-locals-offset:	32
	last-math-op:		none
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
	
	unsupported: does [
		compiler/throw-error "Linux x86-64 backend code generation is not implemented yet"
	]

	noop: does []
	call-arg-index: 0
	call-arg-types: copy []
	call-stack-slots: 0
	call-pad-slots: 0
	call-extra-slots: 0
	call-shadow-slots: 0
	call-variadic?: no
	call-float-reg-count: 0

	win64?: does [
		compiler/job/OS = 'Windows
	]

	emit-reloc-disp32: func [spec [block!]][
		append spec/3 emitter/tail-ptr
		emit to-bin32 0
		unless empty? emitter/chunks/queue [
			append/only
				second last emitter/chunks/queue
				back tail spec/3
		]
	]

	add-condition: func [op [word!] data [binary!]][
		op: either '- = third op: find conditions op [op/2][
			pick op pick [2 3] signed?
		]
		data/(length? data): (to char! last data) or (to char! first op)
		data
	]

	emit-global-ref: func [
		name [word! object! block!]
		opcode [binary!]
		/local spec
	][
		if object? name [name: compiler/unbox name]
		spec: either block? name [name][emitter/symbols/:name]
		if none? spec [
			compiler/throw-error ["unknown variable:" name]
		]
		if spec/1 <> 'global [
			compiler/throw-error ["x86-64 variable kind not supported yet:" mold spec/1]
		]
		emit opcode
		emit-reloc-disp32 spec
	]

	import-var?: func [name [word! object!] /local spec][
		if object? name [name: compiler/unbox name]
		all [
			spec: emitter/symbols/:name
			spec/1 = 'import-var
		]
	]

	emit-import-var-address: func [
		name [word! object!]
		/local spec
	][
		if object? name [name: compiler/unbox name]
		spec: emitter/symbols/:name
		unless all [spec spec/1 = 'import-var][
			compiler/throw-error ["x86-64 import variable expected:" name]
		]
		emit #{488B05}								;-- MOV rax, [RIP+disp32]
		emit-reloc-disp32 spec
	]

	emit-load-import-var: func [
		name [word! object!]
		type [block!]
		/into-ecx
		/local opcode
	][
		if into-ecx [emit #{50}]					;-- PUSH rax
		emit-import-var-address name
		opcode: switch/default type/1 [
			byte!	 [either into-ecx [#{0FB608}][#{0FB600}]]
			int8!	 [either into-ecx [#{0FBE08}][#{0FBE00}]]
			uint8!	 [either into-ecx [#{0FB608}][#{0FB600}]]
			int16!	 [either into-ecx [#{0FBF08}][#{0FBF00}]]
			uint16!	 [either into-ecx [#{0FB708}][#{0FB700}]]
			integer! [either into-ecx [#{8B08}][#{8B00}]]
			int32!	 [either into-ecx [#{8B08}][#{8B00}]]
			uint32!	 [either into-ecx [#{8B08}][#{8B00}]]
			int64!	 [either into-ecx [#{488B08}][#{488B00}]]
			uint64!	 [either into-ecx [#{488B08}][#{488B00}]]
			pointer! [either into-ecx [#{488B08}][#{488B00}]]
			c-string! [either into-ecx [#{488B08}][#{488B00}]]
			function! [either into-ecx [#{488B08}][#{488B00}]]
			subroutine! [either into-ecx [#{488B08}][#{488B00}]]
			struct!	 [either into-ecx [#{488B08}][#{488B00}]]
			union!	 [either into-ecx [#{488B08}][#{488B00}]]
			float!	 [#{C5FB1000}]
			float64! [#{C5FB1000}]
			float32! [#{C5FA1000}]
		][
			compiler/throw-error ["x86-64 import variable load type not supported yet:" mold type/1]
		]
		emit opcode
		if into-ecx [emit #{58}]					;-- POP rax
	]

	emit-store-import-var: func [
		name [word! object!]
		type [block!]
		/local opcode
	][
		either compiler/any-float? type [
			emit-import-var-address name
			opcode: switch/default type/1 [
				float!	 [#{C5FB1100}]
				float64! [#{C5FB1100}]
				float32! [#{C5FA1100}]
			][
				compiler/throw-error ["x86-64 import variable store type not supported yet:" mold type/1]
			]
			emit opcode
		][
			emit #{50}								;-- PUSH rax
			emit-import-var-address name
			emit #{59}								;-- POP rcx
			opcode: switch/default type/1 [
				byte!	 [#{8808}]
				int8!	 [#{8808}]
				uint8!	 [#{8808}]
				int16!	 [#{668908}]
				uint16!	 [#{668908}]
				integer! [#{8908}]
				int32!	 [#{8908}]
				uint32!	 [#{8908}]
				int64!	 [#{488908}]
				uint64!	 [#{488908}]
				pointer! [#{488908}]
				c-string! [#{488908}]
				function! [#{488908}]
				subroutine! [#{488908}]
			][
				compiler/throw-error ["x86-64 import variable store type not supported yet:" mold type/1]
			]
			emit opcode
		]
	]

	emit-load-int64-literal: func [value type [word!] /local hex][
		hex: compiler/int64-hex value type
		emit #{48B8}								;-- MOV rax, imm64
		emit reverse debase/base hex 16
	]

	patch-stack-offset: func [name [word!] offset [integer!] /local pos][
		if pos: find/skip emitter/stack name 2 [
			pos/2: offset
		]
	]

	stack-arg-count?: func [n [integer!]][max 0 n - 6]
	stack-pad-count?: func [n [integer!] /local count][
		count: either win64? [max 0 n - 4][stack-arg-count? n]
		either odd? count [1][0]
	]
	emit-call-stack-cleanup: func [n [integer!] /local slots size][
		slots: call-stack-slots + call-pad-slots + call-extra-slots + call-shadow-slots
		if positive? slots [
			size: slots * stack-width
			either size > 127 [
				emit #{4881C4}						;-- ADD rsp, imm32
				emit to-bin32 size
			][
				emit #{4883C4}						;-- ADD rsp, imm8
				emit to-bin8 size
			]
		]
	]

	emit-call-register-loads: func [/local types int-reg float-reg stack-offset stack-write-offset type slot][
		types: reverse copy call-arg-types
		int-reg: 0
		float-reg: 0
		stack-offset: 0
		stack-write-offset: 0
		call-stack-slots: 0
		call-shadow-slots: 0
		slot: 0
		if win64? [
			foreach type types [
				slot: slot + 1
				either slot <= 4 [
					either compiler/any-float? type [
						either positive? stack-offset [
							unless stack-offset <= 127 [
								compiler/throw-error "x86-64 stack argument offset wider than disp8 is not implemented yet"
							]
							emit either type/1 = 'float32! [#{F30F10}][#{F20F10}]
							emit pick [#{0424} #{0C24} #{1424} #{1C24}] slot
							emit to-bin8 stack-offset
							if call-variadic? [
								emit pick [#{488B0C24} #{488B1424} #{4C8B0424} #{4C8B0C24}] slot
								emit to-bin8 stack-offset
							]
						][
							emit either type/1 = 'float32! [#{F30F10}][#{F20F10}]
							emit pick [#{0424} #{0C24} #{1424} #{1C24}] slot
							if call-variadic? [
								emit pick [#{488B0C24} #{488B1424} #{4C8B0424} #{4C8B0C24}] slot
							]
							emit #{4883C408}			;-- ADD rsp, 8
						]
						float-reg: float-reg + 1
					][
						either positive? stack-offset [
							unless stack-offset <= 127 [
								compiler/throw-error "x86-64 stack argument offset wider than disp8 is not implemented yet"
							]
							emit pick [
								#{488B4C24}	;-- MOV rcx, [rsp+disp8]
								#{488B5424}	;-- MOV rdx, [rsp+disp8]
								#{4C8B4424}	;-- MOV r8,  [rsp+disp8]
								#{4C8B4C24}	;-- MOV r9,  [rsp+disp8]
							] slot
							emit to-bin8 stack-offset
							stack-offset: stack-offset + stack-width
						][
							emit pick [
								#{59}		;-- POP rcx
								#{5A}		;-- POP rdx
								#{4158}		;-- POP r8
								#{4159}		;-- POP r9
							] slot
						]
						int-reg: int-reg + 1
					]
				][
					if stack-write-offset <> stack-offset [
						unless all [stack-offset <= 127 stack-write-offset <= 127][
							compiler/throw-error "x86-64 stack argument compaction offset wider than disp8 is not implemented yet"
						]
						emit #{488B4424}			;-- MOV rax, [rsp+disp8]
						emit to-bin8 stack-offset
						emit #{48894424}			;-- MOV [rsp+disp8], rax
						emit to-bin8 stack-write-offset
					]
					stack-offset: stack-offset + stack-width
					stack-write-offset: stack-write-offset + stack-width
				]
			]
			call-shadow-slots: 4
		][
			foreach type types [
				either compiler/any-float? type [
					either float-reg < 8 [
						either positive? stack-offset [
							unless stack-offset <= 127 [
								compiler/throw-error "x86-64 stack argument offset wider than disp8 is not implemented yet"
							]
							emit either type/1 = 'float32! [#{F30F10}][#{F20F10}]
							emit pick [#{4424} #{4C24} #{5424} #{5C24} #{6424} #{6C24} #{7424} #{7C24}] float-reg + 1
							emit to-bin8 stack-offset
							stack-offset: stack-offset + stack-width
						][
							emit either type/1 = 'float32! [#{F30F10}][#{F20F10}]
							emit pick [#{0424} #{0C24} #{1424} #{1C24} #{2424} #{2C24} #{3424} #{3C24}] float-reg + 1
							emit #{4883C408}			;-- ADD rsp, 8
						]
						float-reg: float-reg + 1
					][
						if stack-write-offset <> stack-offset [
							unless all [stack-offset <= 127 stack-write-offset <= 127][
								compiler/throw-error "x86-64 stack argument compaction offset wider than disp8 is not implemented yet"
							]
							emit #{488B4424}			;-- MOV rax, [rsp+disp8]
							emit to-bin8 stack-offset
							emit #{48894424}			;-- MOV [rsp+disp8], rax
							emit to-bin8 stack-write-offset
						]
						stack-offset: stack-offset + stack-width
						stack-write-offset: stack-write-offset + stack-width
					]
				][
					either int-reg < 6 [
						either positive? stack-offset [
							unless stack-offset <= 127 [
								compiler/throw-error "x86-64 stack argument offset wider than disp8 is not implemented yet"
							]
							emit pick [
								#{488B7C24}	;-- MOV rdi, [rsp+disp8]
								#{488B7424}	;-- MOV rsi, [rsp+disp8]
								#{488B5424}	;-- MOV rdx, [rsp+disp8]
								#{488B4C24}	;-- MOV rcx, [rsp+disp8]
								#{4C8B4424}	;-- MOV r8,  [rsp+disp8]
								#{4C8B4C24}	;-- MOV r9,  [rsp+disp8]
							] int-reg + 1
							emit to-bin8 stack-offset
							stack-offset: stack-offset + stack-width
						][
							emit pick [
								#{5F}		;-- POP rdi
								#{5E}		;-- POP rsi
								#{5A}		;-- POP rdx
								#{59}		;-- POP rcx
								#{4158}		;-- POP r8
								#{4159}		;-- POP r9
							] int-reg + 1
						]
						int-reg: int-reg + 1
					][
						if stack-write-offset <> stack-offset [
							unless all [stack-offset <= 127 stack-write-offset <= 127][
								compiler/throw-error "x86-64 stack argument compaction offset wider than disp8 is not implemented yet"
							]
							emit #{488B4424}			;-- MOV rax, [rsp+disp8]
							emit to-bin8 stack-offset
							emit #{48894424}			;-- MOV [rsp+disp8], rax
							emit to-bin8 stack-write-offset
						]
						stack-offset: stack-offset + stack-width
						stack-write-offset: stack-write-offset + stack-width
					]
				]
			]
		]
		call-stack-slots: stack-offset / stack-width
		call-float-reg-count: float-reg
	]

	emit-arg-spills: func [locals [block!] /local regs offset name type count stack-offset int-count float-count stack-count slot][
		regs: [
			#{57}		;-- PUSH rdi
			#{56}		;-- PUSH rsi
			#{52}		;-- PUSH rdx
			#{51}		;-- PUSH rcx
			#{4150}		;-- PUSH r8
			#{4151}		;-- PUSH r9
		]
		offset: -2 * stack-width
		count: 0
		int-count: 0
		float-count: 0
		stack-count: 0
		parse locals [
			opt block!
			any [
				set name word! set type block! (
					count: count + 1
					either win64? [
						either count <= 4 [
							offset: offset - stack-width
							either compiler/any-float? type [
								emit #{4883EC08}		;-- SUB rsp, 8
								emit either type/1 = 'float32! [#{F30F11}][#{F20F11}]
								emit pick [#{45} #{4D} #{55} #{5D}] count
								emit to-bin8 offset
							][
								emit pick [#{51} #{52} #{4150} #{4151}] count
							]
							patch-stack-offset name offset
						][
							stack-offset: 16 + ((count - 1) * stack-width)
							patch-stack-offset name stack-offset
						]
					][
						either compiler/any-float? type [
							either float-count < 8 [
								offset: offset - stack-width
								emit #{4883EC08}		;-- SUB rsp, 8
								emit either type/1 = 'float32! [#{F30F11}][#{F20F11}]
								emit pick [#{45} #{4D} #{55} #{5D} #{65} #{6D} #{75} #{7D}] float-count + 1
								emit to-bin8 offset
								patch-stack-offset name offset
								float-count: float-count + 1
							][
								stack-offset: 16 + (stack-count * stack-width)
								patch-stack-offset name stack-offset
								stack-count: stack-count + 1
							]
						][
							either int-count < length? regs [
								offset: offset - stack-width
								emit pick regs int-count + 1
								patch-stack-offset name offset
								int-count: int-count + 1
							][
								stack-offset: 16 + (stack-count * stack-width)
								patch-stack-offset name stack-offset
								stack-count: stack-count + 1
							]
						]
					]
				)
				| set-word! block!
				| /local break
			]
		]
	]

	argument-count?: func [locals [block!] /local count name type][
		count: 0
		parse locals [
			opt block!
			any [
				set name word! set type block! (count: count + 1)
				| set-word! block!
				| /local break
			]
		]
		count
	]
	register-argument-count?: func [locals [block!] /local count name type int-count float-count][
		count: 0
		int-count: 0
		float-count: 0
		parse locals [
			opt block!
			any [
				set name word! set type block! (
					either win64? [
						if count < 4 [count: count + 1]
					][
						either compiler/any-float? type [
							if float-count < 8 [
								count: count + 1
								float-count: float-count + 1
							]
						][
							if int-count < 6 [
								count: count + 1
								int-count: int-count + 1
							]
						]
					]
				)
				| set-word! block!
				| /local break
			]
		]
		count
	]

	emit-local-ref: func [
		name [word! object!]
		opcode [binary!]
		/local offset wide-op
	][
		if object? name [name: compiler/unbox name]
		offset: emitter/local-offset? name
		unless offset [
			compiler/throw-error ["unknown local variable:" name]
		]
		either all [offset >= -128 offset <= 127] [
			emit opcode
			emit to-bin8 offset
		][
			wide-op: copy/part opcode (length? opcode) - 1
			append wide-op to-char (to integer! last opcode) + 64
			emit wide-op
			emit to-bin32 offset
		]
	]

	emit-load-ecx: func [value /local type][
		case [
			block? value [
				if empty? value [exit]
				if word? value/1 [
					if any [
						find comparison-op value/1
						find math-op value/1
						find bitwise-op value/1
						find bitshift-op value/1
					][
						emit #{50}					;-- PUSH rax
						emit-integer-operation value/1 next value
						emit #{4889C1}				;-- MOV rcx, rax
						emit #{58}					;-- POP rax
						exit
					]
				]
				compiler/throw-error ["x86-64 secondary operand not supported yet:" mold value]
			]
			integer? value [
				emit #{B9}							;-- MOV ecx, imm32
				emit to-bin32 value
			]
			issue? value [
				type: compiler/int64-literal-info value
				emit #{50}							;-- PUSH rax
				emit-load-int64-literal value type/1
				emit #{4889C1}						;-- MOV rcx, rax
				emit #{58}							;-- POP rax
			]
			object? value [
				type: compiler/resolve-aliased value/type
				emit #{50}							;-- PUSH rax
				emit-load value
				emit either find [pointer! c-string! function! subroutine! struct! union! int64! uint64!] type/1 [
					#{4889C1}						;-- MOV rcx, rax
				][
					#{89C1}							;-- MOV ecx, eax
				]
				emit #{58}							;-- POP rax
			]
			word? value [
				type: compiler/get-type value
				if all [
					not emitter/local-offset? value
					import-var? value
				][
					emit-load-import-var/into-ecx value type
					exit
				]
				switch/default type/1 [
					byte! [
						either emitter/local-offset? value [
							emit-local-ref value #{0FB64D}	;-- MOVZX ecx, byte [rbp+disp8]
						][
							emit-global-ref value #{0FB60D}	;-- MOVZX ecx, byte [RIP+disp32]
						]
					]
					int8! [
						either emitter/local-offset? value [
							emit-local-ref value #{0FBE4D}	;-- MOVSX ecx, byte [rbp+disp8]
						][
							emit-global-ref value #{0FBE0D}	;-- MOVSX ecx, byte [RIP+disp32]
						]
					]
					uint8! [
						either emitter/local-offset? value [
							emit-local-ref value #{0FB64D}
						][
							emit-global-ref value #{0FB60D}
						]
					]
					int16! [
						either emitter/local-offset? value [
							emit-local-ref value #{0FBF4D}	;-- MOVSX ecx, word [rbp+disp8]
						][
							emit-global-ref value #{0FBF0D}	;-- MOVSX ecx, word [RIP+disp32]
						]
					]
					uint16! [
						either emitter/local-offset? value [
							emit-local-ref value #{0FB74D}	;-- MOVZX ecx, word [rbp+disp8]
						][
							emit-global-ref value #{0FB70D}	;-- MOVZX ecx, word [RIP+disp32]
						]
					]
					integer! [
						either emitter/local-offset? value [
							emit-local-ref value #{8B4D}	;-- MOV ecx, [rbp+disp8]
						][
							emit-global-ref value #{8B0D}	;-- MOV ecx, [RIP+disp32]
						]
					]
					int64! [
						either emitter/local-offset? value [
							emit-local-ref value #{488B4D}	;-- MOV rcx, [rbp+disp8]
						][
							emit-global-ref value #{488B0D}	;-- MOV rcx, [RIP+disp32]
						]
					]
					uint64! [
						either emitter/local-offset? value [
							emit-local-ref value #{488B4D}
						][
							emit-global-ref value #{488B0D}
						]
					]
					pointer! [
						either emitter/local-offset? value [
							emit-local-ref value #{488B4D}
						][
							emit-global-ref value #{488B0D}
						]
					]
					struct! [
						either emitter/local-offset? value [
							emit-local-ref value #{488B4D}
						][
							emit-global-ref value #{488B0D}
						]
					]
					union! [
						either emitter/local-offset? value [
							emit-local-ref value #{488B4D}
						][
							emit-global-ref value #{488B0D}
						]
					]
					int32! [
						either emitter/local-offset? value [
							emit-local-ref value #{8B4D}
						][
							emit-global-ref value #{8B0D}
						]
					]
					uint32! [
						either emitter/local-offset? value [
							emit-local-ref value #{8B4D}
						][
							emit-global-ref value #{8B0D}
						]
					]
				][
					compiler/throw-error ["x86-64 secondary operand type not supported yet:" mold type/1]
				]
			]
			path? value [
				type: compiler/resolve-path-type value
				emit #{50}							;-- PUSH rax
				emit-load value
				emit either find [pointer! c-string! function! subroutine! struct! union! int64! uint64!] type/1 [
					#{4889C1}						;-- MOV rcx, rax
				][
					#{89C1}							;-- MOV ecx, eax
				]
				emit #{58}							;-- POP rax
			]
			true [
				compiler/throw-error ["x86-64 secondary operand not supported yet:" mold value]
			]
		]
	]

	emit-float-ref: func [
		name [word! object! block!]
		opcode [binary!]
	][
		if object? name [name: compiler/unbox name]
		either block? name [
			emit-global-ref name opcode
		][
			either emitter/local-offset? name [
				emit-local-ref name opcode
			][
				either import-var? name [
					emit-load-import-var name compiler/get-type name
				][
					emit-global-ref name opcode
				]
			]
		]
	]

	on-init: :noop
	on-global-prolog: func [runtime? [logic!] type [word!]][
		if all [
			win64?
			runtime?
			type = 'exe
		][
			emit-reserve-stack 1					;-- align root stack before Win64 calls
		]
	]
	on-global-epilog: func [runtime? [logic!] type [word!]][
		unless runtime? [
			either compiler/job/need-main? [
				emit #{4889EC}						;-- MOV rsp, rbp
				emit-pop							;-- pop exceptions threshold slot
				emit-pop							;-- pop exceptions address slot
				emit-pop							;-- pop arguments/locals bitarray slot
				emit #{5D}							;-- POP rbp
				emit-epilog/closing '***_start [] 0 0
			][
				emit-load 0
			]
		]
	]
	on-root-level-entry: :noop
	on-finalize: :noop
	patch-call: func [code-buf rel-ptr dst-ptr][
		change/part
			at code-buf rel-ptr
			to-bin32 dst-ptr - rel-ptr - branch-offset-size
			4
	]
	patch-jump-back: func [buffer [binary!] offset [integer!]][
		change at buffer offset to-bin32 negate offset + 4 - 1
	]
	patch-jump-point: func [buffer [binary!] ptr [integer!] exit-point [integer!]][
		change/part at buffer ptr to-bin32 exit-point - ptr - branch-offset-size 4
	]
	patch-sub-call: :unsupported
	emit-prolog: func [name [word!] locals [block!] bitmap [integer!] /local locals-size reg-count local-slots][
		reg-count: register-argument-count? locals
		locals-offset: 2 * stack-width + (reg-count * stack-width)
		locals-size: either find locals /local [
			emitter/calc-locals-offsets find locals /local
		][0]
		emit #{55}									;-- PUSH rbp
		emit #{4889E5}								;-- MOV rbp, rsp
		emit #{6A00}								;-- PUSH 0		; catch ID
		emit #{6A00}								;-- PUSH 0		; catch resume address
		emit-arg-spills locals
		local-slots: (round/to/ceiling locals-size stack-width) / stack-width
		if locals-size <> 0 [
			emit-reserve-stack local-slots
		]
		if odd? reg-count + local-slots [
			emit-reserve-stack 1
		]
		reduce [locals-size 0]
	]
	emit-epilog: func [
		name [word!] locals [block!] args-size [integer!] locals-size [integer!] /with slots [integer! none!] /closing
	][
		if slots [
			compiler/throw-error "x86-64 function epilog shape is not implemented yet"
		]
		if closing [emit-load 0]
		emit #{C9}									;-- LEAVE
		emit #{C3}									;-- RET
	]
	emit-stack-align-prolog: :noop
	emit-stack-align-epilog: :noop
	emit-stack-align: :noop
	emit-float-trash-last: :noop
	emit-casting: func [value [object!] alt? [logic!] /push /local type][
		type: compiler/get-type value/data
		case [
			value/type/1 = 'logic! [
				emit either compiler/int64? type [#{4885C0}][#{85C0}]
				emit #{0F95C0}						;-- SETNZ al
				emit #{0FB6C0}						;-- MOVZX eax, al
			]
			all [
				compiler/integer-type? value/type
				compiler/integer-type? type
			][]										;-- integer loads already widen/truncate through eax/rax
			all [
				find [float! float32! float64!] value/type/1
				compiler/integer-type? type
			][
				emit either compiler/int64? type [
					either value/type/1 = 'float32! [#{C4E1FA2AC0}][#{C4E1FB2AC0}]
				][
					either value/type/1 = 'float32! [#{C5FA2AC0}][#{C5FB2AC0}]
				]
			]
			all [
				compiler/integer-type? value/type
				find [float! float32! float64!] type/1
			][
				emit either compiler/int64? value/type [
					either type/1 = 'float32! [#{C4E1FA2CC0}][#{C4E1FB2CC0}]
				][
					either type/1 = 'float32! [#{C5FA2CC0}][#{C5FB2CC0}]
				]
			]
			all [
				value/type/1 = 'float32!
				find [float! float64!] type/1
			][
				emit #{C5FB5AC0}					;-- VCVTSD2SS xmm0, xmm0, xmm0
			]
			all [
				find [float! float64!] value/type/1
				type/1 = 'float32!
			][
				emit #{C5FA5AC0}					;-- VCVTSS2SD xmm0, xmm0, xmm0
			]
		]
	]
	emit-call-syscall: func [args [block!] fspec [block!] attribs [block! none!] /local pops n][
		n: fspec/1
		if n > 6 [
			compiler/throw-error ["x86-64 syscall with too many args:" n]
		]
		while [n > 0][
			emit pick [
				#{5F}		;-- POP rdi
				#{5E}		;-- POP rsi
				#{5A}		;-- POP rdx
				#{415A}		;-- POP r10
				#{4158}		;-- POP r8
				#{4159}		;-- POP r9
			] n
			n: n - 1
		]
		emit #{B8}									;-- MOV eax, syscall number
		emit to-bin32 last fspec
		emit #{0F05}								;-- SYSCALL
		call-arg-index: 0
		clear call-arg-types
		call-stack-slots: 0
		call-pad-slots: 0
		call-extra-slots: 0
		call-shadow-slots: 0
		call-variadic?: no
		call-float-reg-count: 0
	]
	emit-variadic-data: func [args [block!] /local total data-slots][
		if args/1 <> #typed [
			compiler/throw-error "x86-64 non-typed variadic calls are not implemented yet"
		]
		total: (length? args/2) / 3
		data-slots: total * 3
		emit #{4889E0}								;-- MOV rax, rsp
		emit-push <last>								;-- typed-value list pointer
		emit-push total								;-- typed-value count
		call-extra-slots: data-slots
		call-arg-index: 2
		clear call-arg-types
		append/only call-arg-types [integer!]
		append/only call-arg-types [pointer! [integer!]]
	]
	emit-call-import: func [
		args [block!]
		fspec [block!]
		spec [block!]
		attribs [block! none!]
		/local n
	][
		n: fspec/1
		call-variadic?: to logic! compiler/find-attribute fspec/4 'variadic
		if args/1 = #typed [emit-variadic-data args]
		emit-call-register-loads
		if win64? [emit-reserve-stack 4]
		if all [not win64? compiler/find-attribute fspec/4 'variadic] [
			emit #{B0}								;-- MOV al, imm8 (SysV variadic FP register count)
			emit to-bin8 call-float-reg-count
		]
		emit either win64? [#{FF15}][#{E8}]			;-- CALL [rip+disp32] / rel32
		emit-reloc-disp32 spec
		emit-call-stack-cleanup n
		call-arg-index: 0
		clear call-arg-types
		call-stack-slots: 0
		call-pad-slots: 0
		call-extra-slots: 0
		call-shadow-slots: 0
		call-variadic?: no
		call-float-reg-count: 0
	]
	emit-call-native: func [
		args [block!] fspec [block!] spec [block!] attribs [block! none!]
		/routine name [word!]
		/local n
	][
		n: fspec/1
		if args/1 = #typed [emit-variadic-data args]
		emit-call-register-loads
		if win64? [emit-reserve-stack 4]
		emit #{E8}									;-- CALL rel32
		emit-reloc-disp32 spec
		emit-call-stack-cleanup n
		call-arg-index: 0
		clear call-arg-types
		call-stack-slots: 0
		call-pad-slots: 0
		call-extra-slots: 0
		call-shadow-slots: 0
		call-variadic?: no
		call-float-reg-count: 0
	]
	emit-not: func [value [word! char! tag! integer! logic! path! string! object!] /local opcodes type boxed][
		if verbose >= 3 [print [">>>emitting NOT" mold value]]

		if object? value [boxed: value]
		value: compiler/unbox value
		if block? value [value: <last>]

		opcodes: [
			logic!	 [emit #{3401}]					;-- XOR al, 1
			byte!	 [emit #{F6D0}]					;-- NOT al
			int8!	 [emit #{F6D0}]
			uint8!	 [emit #{F6D0}]
			int16!	 [emit #{66F7D0}]				;-- NOT ax
			uint16!	 [emit #{66F7D0}]
			integer! [emit #{F7D0}]					;-- NOT eax
			int32!	 [emit #{F7D0}]
			uint32!	 [emit #{F7D0}]
			int64!	 [emit #{48F7D0}]				;-- NOT rax
			uint64!	 [emit #{48F7D0}]
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
				if find [pointer! c-string! struct! union!] type [
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
			string! [
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
	emit-pop: does [
		if verbose >= 3 [print ">>>emitting POP"]
		emit #{58}									;-- POP rax
	]
	emit-integer-operation: func [
		name [word!]
		args [block!]
		/local right imm? type wide? right-block? right-type scale right-loaded? left-type mod? signed-op?
	][
		type: compiler/resolve-aliased compiler/resolve-expr-type args/1
		right: compiler/unbox args/2
		right-block?: block? right
		right-loaded?: no
		if right-block? [
			right-type: compiler/resolve-expr-type args/2
			emit either find [pointer! c-string! function! subroutine! struct! union! int64! uint64!] right-type/1 [
				#{4889C1}							;-- MOV rcx, rax
			][
				#{89C1}								;-- MOV ecx, eax
			]
			right-loaded?: yes
		]
		emit-load args/1
		if char? right [right: to integer! right]
		if logic? right [right: to integer! right]
		imm?: all [not right-block? integer? right]
		wide?: find [pointer! c-string! function! subroutine! struct! union! any-pointer! int64! uint64!] type/1
		scale: 1
		if all [
			find [+ -] name
			not compiler/any-pointer? compiler/resolve-expr-type args/2
		][
			scale: switch/default type/1 [
				pointer! [emitter/size-of? type/2/1]
				struct!  [emitter/member-offset? type/2 none]
				union!   [emitter/union-size? type/2]
			][1]
			if scale > 1 [
				either imm? [
					right: right * scale
				][
					unless right-loaded? [emit-load-ecx right]
					emit #{4869C9}					;-- IMUL rcx, rcx, imm32
					emit to-bin32 scale
					right-loaded?: yes
				]
			]
		]
		mod?: select mod-rem-func name
		if any [name = divide-sym mod?] [
			unless right-block? [emit-load-ecx right]
			signed-op?: compiler/signed-integer? type
			either signed-op? [
				emit either wide? [#{4899}][#{99}]		;-- CQO/CDQ
				emit either wide? [#{48F7F9}][#{F7F9}]	;-- IDIV rcx/ecx
			][
				emit either wide? [#{4831D2}][#{31D2}]	;-- XOR rdx/edx, rdx/edx
				emit either wide? [#{48F7F1}][#{F7F1}]	;-- DIV rcx/ecx
			]
			if mod? [
				emit either wide? [#{4889D0}][#{89D0}]	;-- MOV rax/eax, rdx/edx
				if all [signed-op? mod? <> 'rem][
					emit either wide? [
						#{4885C0790B4885C9790348F7D94801C8}
					][
						#{85C0790885C97902F7D901C8}
					]
				]
			]
			last-math-op: divide-sym
			exit
		]
		case [
			find comparison-op name [
				either imm? [
					either any [
						all [integer? right zero? right]
						all [logic? right not right]
					][
						emit either wide? [#{4885C0}][#{85C0}] ;-- TEST rax/eax, rax/eax
					][
						emit either wide? [#{483D}][#{3D}] ;-- CMP rax/eax, imm32
						emit to-bin32 right
					]
					][
						unless right-loaded? [emit-load-ecx right]
						emit either wide? [#{4839C8}][#{39C8}] ;-- CMP rax/eax, rcx/ecx
					]
				]
			imm? [
				switch/default name [
					+	[either wide? [emit #{48}][] emit #{05} emit to-bin32 right]	;-- ADD rax/eax, imm32
					-	[either wide? [emit #{48}][] emit #{2D} emit to-bin32 right]	;-- SUB rax/eax, imm32
					*	[either wide? [emit #{48}][] emit #{69C0} emit to-bin32 right]	;-- IMUL rax/eax, rax/eax, imm32
					and [either wide? [emit #{48}][] emit #{25} emit to-bin32 right]	;-- AND rax/eax, imm32
					or	[either wide? [emit #{48}][] emit #{0D} emit to-bin32 right]	;-- OR rax/eax, imm32
					xor [either wide? [emit #{48}][] emit #{35} emit to-bin32 right]	;-- XOR rax/eax, imm32
					<<	[either wide? [emit #{48}][] emit #{C1E0} emit to-bin8 right]	;-- SHL rax/eax, imm8
					>>	[either wide? [emit #{48}][] emit #{C1F8} emit to-bin8 right]	;-- SAR rax/eax, imm8
					-**	[either wide? [emit #{48}][] emit #{C1E8} emit to-bin8 right]	;-- SHR rax/eax, imm8
				][
					compiler/throw-error ["x86-64 integer op not supported yet:" mold name]
				]
			]
			true [
				unless right-loaded? [emit-load-ecx right]
				switch/default name [
					+	[emit either wide? [#{4801C8}][#{01C8}]]	;-- ADD rax/eax, rcx/ecx
					-	[emit either wide? [#{4829C8}][#{29C8}]]	;-- SUB rax/eax, rcx/ecx
					*	[emit either wide? [#{480FAFC1}][#{0FAFC1}]] ;-- IMUL rax/eax, rcx/ecx
					and [emit either wide? [#{4821C8}][#{21C8}]]	;-- AND rax/eax, rcx/ecx
					or	[emit either wide? [#{4809C8}][#{09C8}]]	;-- OR rax/eax, rcx/ecx
					xor [emit either wide? [#{4831C8}][#{31C8}]]	;-- XOR rax/eax, rcx/ecx
					<<	[emit either wide? [#{48D3E0}][#{D3E0}]]	;-- SHL rax/eax, cl
					>>	[emit either wide? [#{48D3F8}][#{D3F8}]]	;-- SAR rax/eax, cl
					-**	[emit either wide? [#{48D3E8}][#{D3E8}]]	;-- SHR rax/eax, cl
				][
					compiler/throw-error ["x86-64 integer op not supported yet:" mold name]
				]
			]
		]
		last-math-op: name
	]
	emit-float-operation: func [
		name [word!] args [block!]
		/local type right-type single? store-op cmp-op
	][
		if verbose >= 3 [print [">>>inlining float op:" mold name mold args]]
		type: compiler/resolve-expr-type args/1
		right-type: compiler/resolve-expr-type args/2
		single?: all [type/1 = 'float32! right-type/1 = 'float32!]
		store-op: either single? [#{C5FA110424}][#{C5FB110424}]
		cmp-op: either single? [#{C5F82E0424}][#{C5F92E0424}]
		case [
			find comparison-op name [
				emit-load args/2
				emit #{4883EC08}					;-- SUB rsp, 8
				emit store-op						;-- MOVS[S/D] [rsp], xmm0
				emit-load args/1
				emit cmp-op							;-- UCOMIS[S/D] xmm0, [rsp]
				emit #{488D642408}					;-- LEA rsp, [rsp+8] without clobbering flags
			]
			find [+ *] name [
				emit-load args/1
				emit #{4883EC08}
				emit store-op
				emit-load args/2
				emit switch name [
					+ [either single? [#{C5FA580424}][#{C5FB580424}]] ;-- VADDS[S/D] xmm0, xmm0, [rsp]
					* [either single? [#{C5FA590424}][#{C5FB590424}]] ;-- VMULS[S/D] xmm0, xmm0, [rsp]
				]
				emit #{4883C408}
			]
			find [- /] name [
				emit-load args/2
				emit #{4883EC08}
				emit store-op
				emit-load args/1
				emit switch name [
					- [either single? [#{C5FA5C0424}][#{C5FB5C0424}]] ;-- VSUBS[S/D] xmm0, xmm0, [rsp]
					/ [either single? [#{C5FA5E0424}][#{C5FB5E0424}]] ;-- VDIVS[S/D] xmm0, xmm0, [rsp]
				]
				emit #{4883C408}
			]
			true [
				compiler/throw-error "unsupported operation on floats"
			]
		]
	]
	emit-throw: func [value [integer! word!] /thru][
		emit-load value
		if thru [emit #{EB01}]						;-- jump over initial LEAVE
		emit #{C9}									;-- LEAVE
		emit #{483B45F8}							;-- CMP [rbp-8], rax
		emit #{72F9}								;-- JB back to LEAVE
		emit #{4889C2}								;-- MOV rdx, rax
		emitter/access-path to set-path! 'system/thrown <last>
		emit #{488B7DF0}							;-- MOV rdi, [rbp-16]
		emit #{4885FF}								;-- TEST rdi, rdi
		emit #{7506}								;-- JNZ resume
		emit #{5F}									;-- POP rdi
		emit #{4885FF}								;-- TEST rdi, rdi
		emit #{7402}								;-- JZ end
		emit #{FFE7}								;-- resume: JMP rdi
	]
	emit-alt-last: :unsupported
	emit-log-b: func [type][
		if type = 'byte! [emit #{0FB6C0}]			;-- MOVZX eax, al
		emit #{0FBDC0}								;-- BSR eax, eax
	]
	emit-variable: func [name [word! object!]][
		emit-load name
	]
	emit-argument: func [arg fspec [block!] /local value arg-type][
		if arg = #_ [
			if compiler/find-attribute fspec/4 'typed [
				call-arg-index: call-arg-index + 1
				append/only call-arg-types [integer!]
				emit-push 0
			]
			exit
		]
		if any [
			zero? call-arg-index
			all [
				not compiler/find-attribute fspec/4 'variadic
				call-arg-index >= fspec/1
			]
		][
			call-arg-index: 0
			clear call-arg-types
			call-stack-slots: 0
			call-pad-slots: stack-pad-count? fspec/1
			if positive? call-pad-slots [
				emit #{6A00}						;-- PUSH 0 stack-argument alignment pad
			]
		]
		call-arg-index: call-arg-index + 1
		arg-type: compiler/get-type arg
		append/only call-arg-types arg-type
		value: compiler/unbox arg
		if block? value [value: <last>]
		either get-word? value [
			value: to word! value
			emit #{488D05}						;-- LEA rax, [RIP+disp32]
			emit-reloc-disp32 emitter/get-func-ref value
			emit-push <last>
		][
			if compiler/any-float? arg-type [
				emit-load arg
				emit #{4883EC08}				;-- SUB rsp, 8
				emit either arg-type/1 = 'float32! [#{C5FA110424}][#{C5FB110424}]
				exit
			]
			either path? value [
				emit-load value
				emit-push <last>
			][
				if value = <last> [
					emit-push <last>
					exit
				]
				either word? value [
					emit-load value
					emit-push <last>
				][
					if string? value [
						emit-load-literal [c-string!] value
						emit-push <last>
						exit
					]
					if issue? value [
						emit-load value
						emit-push <last>
						exit
					]
					if logic? value [value: to integer! value]
					unless any [integer? value char? value][
						compiler/throw-error ["x86-64 literal argument not supported yet:" mold value]
					]
					emit-push value
				]
			]
		]
	]
	emit-load: func [value /with cast [object!] /local type spec][
		if block? value [value: <last>]
		case [
			value = <last> []
			object? value [
				emit-load compiler/unbox value
				emit-casting value no
			]
			any [integer? value char? value logic? value] [
				if logic? value [value: to integer! value]
				either all [integer? value value >= -2147483648 value <= 2147483647][
					emit #{B8}						;-- MOV eax, imm32
					emit to-bin32 value
				][
					emit #{48B8}					;-- MOV rax, imm64
					emit to-bin64 value
				]
			]
			issue? value [
				spec: compiler/int64-literal-info value
				emit-load-int64-literal value spec/1
			]
			decimal? value [
				spec: emitter/store-value none value [float!]
				emit-float-ref spec/2 #{C5FB1005}
			]
			string? value [
				emit-load-literal [c-string!] value
			]
			path? value [
				emitter/access-path value none
			]
			paren? value [
				emit-load-literal none value
			]
			get-word? value [
				value: to word! value
				either emitter/local-offset? value [
					emit-local-ref value #{488D45}		;-- LEA rax, [rbp+disp8]
				][
					either import-var? value [
						emit-import-var-address value
					][
						emit #{488D05}					;-- LEA rax, [RIP+disp32]
						emit-reloc-disp32 emitter/get-symbol-ref value
					]
				]
			]
			word? value [
				type: compiler/get-type value
				either emitter/local-offset? value [
					switch/default type/1 [
						byte!	 [emit-local-ref value #{0FB645}]	;-- MOVZX eax, byte [rbp+disp8]
						logic!	 [emit-local-ref value #{0FB645}]
						int8!	 [emit-local-ref value #{0FBE45}]	;-- MOVSX eax, byte [rbp+disp8]
						uint8!	 [emit-local-ref value #{0FB645}]
						int16!	 [emit-local-ref value #{0FBF45}]	;-- MOVSX eax, word [rbp+disp8]
						uint16!	 [emit-local-ref value #{0FB745}]	;-- MOVZX eax, word [rbp+disp8]
						integer! [emit-local-ref value #{8B45}]		;-- MOV eax, [rbp+disp8]
						int32!	 [emit-local-ref value #{8B45}]
						uint32!	 [emit-local-ref value #{8B45}]
						int64!	 [emit-local-ref value #{488B45}]	;-- MOV rax, [rbp+disp8]
						uint64!	 [emit-local-ref value #{488B45}]
						pointer! [emit-local-ref value #{488B45}]
						c-string! [emit-local-ref value #{488B45}]
						function! [emit-local-ref value #{488B45}]
						subroutine! [emit-local-ref value #{488B45}]
						struct!	 [emit-local-ref value #{488B45}]
						union!	 [emit-local-ref value #{488B45}]
						float!	 [emit-float-ref value #{C5FB1045}]
						float64! [emit-float-ref value #{C5FB1045}]
						float32! [emit-float-ref value #{C5FA1045}]
					][
						compiler/throw-error ["x86-64 local load type not supported yet:" mold type/1]
					]
				][
					if import-var? value [
						emit-load-import-var value type
						exit
					]
					switch/default type/1 [
						byte!	 [emit-global-ref value #{0FB605}]	;-- MOVZX eax, byte [RIP+disp32]
						logic!	 [emit-global-ref value #{0FB605}]
						int8!	 [emit-global-ref value #{0FBE05}]	;-- MOVSX eax, byte [RIP+disp32]
						uint8!	 [emit-global-ref value #{0FB605}]
						int16!	 [emit-global-ref value #{0FBF05}]	;-- MOVSX eax, word [RIP+disp32]
						uint16!	 [emit-global-ref value #{0FB705}]	;-- MOVZX eax, word [RIP+disp32]
						integer! [emit-global-ref value #{8B05}]		;-- MOV eax, [RIP+disp32]
						int32!	 [emit-global-ref value #{8B05}]
						uint32!	 [emit-global-ref value #{8B05}]
						int64!	 [emit-global-ref value #{488B05}]		;-- MOV rax, [RIP+disp32]
						uint64!	 [emit-global-ref value #{488B05}]
						pointer! [emit-global-ref value #{488B05}]
						c-string! [emit-global-ref value #{488B05}]
						function! [emit-global-ref value #{488B05}]
						subroutine! [emit-global-ref value #{488B05}]
						struct!	 [emit-global-ref value #{488B05}]
						union!	 [emit-global-ref value #{488B05}]
						float!	 [emit-float-ref value #{C5FB1005}]
						float64! [emit-float-ref value #{C5FB1005}]
						float32! [emit-float-ref value #{C5FA1005}]
					][
						compiler/throw-error ["x86-64 load type not supported yet:" mold type/1]
					]
				]
			]
			true [
				compiler/throw-error ["x86-64 load not supported yet:" mold value]
			]
		]
		if all [
			with
			any [
				decimal? compiler/unbox value
				decimal? compiler/unbox cast/data
			]
		][
			emit-casting cast no
		]
	]
	emit-load-literal: func [type [block! none!] value /local spec][
		unless type [type: compiler/get-type value]
		spec: emitter/store-value none value type
		emit-load-literal-ptr spec/2
	]
	emit-load-literal-ptr: func [spec [block!]][
		emit #{488D05}								;-- LEA rax, [RIP+disp32]
		emit-reloc-disp32 spec
	]
	emit-init-path: func [name [word! get-word!]][
		if get-word? name [name: to word! name]
		either emitter/local-offset? name [
			emit-local-ref name #{488B45}			;-- MOV rax, [rbp+disp8]
		][
			either import-var? name [
				emit-import-var-address name
			][
				emit-global-ref name #{488B05}		;-- MOV rax, [RIP+disp32]
			]
		]
	]
	emit-store: func [
		name [word!] value
		spec [block! none!]
		/by-value slots [integer!]
		/local type agg-type source-type opcode local?
	][
		if by-value [
			compiler/throw-error "x86-64 by-value store is not implemented yet"
		]
		type: compiler/get-variable-spec name
		agg-type: compiler/resolve-aliased type
		if all [
			block? value
			empty? value
			find [struct! union!] agg-type/1
		][
			exit
		]
		if find [struct! union!] agg-type/1 [
			type: [pointer!]
		]
		if logic? value [value: to integer! value]
		if all [
			value <> <last>
			find [string! paren! binary!] type?/word value
			compiler/any-pointer? type
		][
			either spec [
				emit-load-literal-ptr spec/2
			][
				emit-load value
			]
		]
		if all [
			value <> <last>
			not find [string! paren! binary!] type?/word value
		][
			source-type: compiler/get-type value
			emit-load value
			case [
				all [
					type/1 = 'float32!
					find [float! float64!] source-type/1
				][
					emit #{C5FB5AC0}				;-- VCVTSD2SS xmm0, xmm0, xmm0
				]
				all [
					find [float! float64!] type/1
					source-type/1 = 'float32!
				][
					emit #{C5FA5AC0}				;-- VCVTSS2SD xmm0, xmm0, xmm0
				]
			]
		]
		local?: emitter/local-offset? name
		either local? [
			opcode: switch/default type/1 [
				byte!	 [#{8845}]					;-- MOV [rbp+disp8], al
				int8!	 [#{8845}]
				uint8!	 [#{8845}]
				logic!	 [#{8845}]
				int16!	 [#{668945}]				;-- MOV [rbp+disp8], ax
				uint16!	 [#{668945}]
				integer! [#{8945}]					;-- MOV [rbp+disp8], eax
				int32!	 [#{8945}]
				uint32!	 [#{8945}]
				int64!	 [#{488945}]				;-- MOV [rbp+disp8], rax
				uint64!	 [#{488945}]
				pointer! [#{488945}]
				c-string! [#{488945}]
				float!	 [#{C5FB1145}]			;-- VMOVSD [rbp+disp8], xmm0
				float64! [#{C5FB1145}]
				float32! [#{C5FA1145}]			;-- VMOVSS [rbp+disp8], xmm0
			][
				compiler/throw-error ["x86-64 local store type not supported yet:" mold type/1]
			]
			emit-local-ref name opcode
		][
			if import-var? name [
				emit-store-import-var name type
				exit
			]
			opcode: switch/default type/1 [
				byte!	 [#{8805}]					;-- MOV [RIP+disp32], al
				int8!	 [#{8805}]
				uint8!	 [#{8805}]
				logic!	 [#{8805}]
				int16!	 [#{668905}]				;-- MOV [RIP+disp32], ax
				uint16!	 [#{668905}]
				integer! [#{8905}]					;-- MOV [RIP+disp32], eax
				int32!	 [#{8905}]
				uint32!	 [#{8905}]
				int64!	 [#{488905}]				;-- MOV [RIP+disp32], rax
				uint64!	 [#{488905}]
				pointer! [#{488905}]
				c-string! [#{488905}]
				float!	 [#{C5FB1105}]			;-- VMOVSD [RIP+disp32], xmm0
				float64! [#{C5FB1105}]
				float32! [#{C5FA1105}]			;-- VMOVSS [RIP+disp32], xmm0
			][
				compiler/throw-error ["x86-64 store type not supported yet:" mold type/1]
			]
			emit-global-ref name opcode
		]
	]
	emit-load-path: func [
		path [path!]
		type [word!]
		parent [block! none!]
		/local spec offset mtype size signed? idx
	][
		if verbose >= 3 [print [">>>loading path:" mold path]]
		switch type [
			c-string! [
				unless parent [emit-init-path path/1]
				idx: path/2
				either integer? idx [
					offset: idx - 1
					either zero? offset [
						emit #{0FB600}				;-- MOVZX eax, byte [rax]
					][
						emit #{0FB680}				;-- MOVZX eax, byte [rax+disp32]
						emit to-bin32 offset
					]
				][
					emit-load-ecx idx
					emit #{FFC9}					;-- DEC ecx, one-based index
					emit #{0FB60408}				;-- MOVZX eax, byte [rax+rcx]
				]
				set-width 4
			]
			pointer! [
				spec: compiler/resolve-type to word! path/1
				emit-init-path path/1
				mtype: spec/2
				set-width/type mtype/1
				size: emitter/size-of? mtype
				signed?: compiler/signed-integer? mtype
				idx: either path/2 = 'value [1][path/2]
				unless integer? idx [
					compiler/throw-error "x86-64 pointer variable indexes are not implemented yet"
				]
				offset: (idx - 1) * size
				case [
					compiler/any-float? mtype [
						either size = 4 [
							either zero? offset [
								emit #{C5FA1000}	;-- VMOVSS xmm0, [rax]
							][
								emit #{C5FA1080}	;-- VMOVSS xmm0, [rax+disp32]
								emit to-bin32 offset
							]
						][
							either zero? offset [
								emit #{C5FB1000}	;-- VMOVSD xmm0, [rax]
							][
								emit #{C5FB1080}	;-- VMOVSD xmm0, [rax+disp32]
								emit to-bin32 offset
							]
						]
					]
					all [size = 8 not compiler/any-float? mtype] [
						either zero? offset [
							emit #{488B00}			;-- MOV rax, [rax]
						][
							emit #{488B80}			;-- MOV rax, [rax+disp32]
							emit to-bin32 offset
						]
					]
					all [size = 4 not compiler/any-float? mtype] [
						either zero? offset [
							emit #{8B00}			;-- MOV eax, [rax]
						][
							emit #{8B80}			;-- MOV eax, [rax+disp32]
							emit to-bin32 offset
						]
					]
					all [size = 2 not compiler/any-float? mtype] [
						either signed? [
							either zero? offset [
								emit #{0FBF00}		;-- MOVSX eax, word [rax]
							][
								emit #{0FBF80}
								emit to-bin32 offset
							]
						][
							either zero? offset [
								emit #{0FB700}		;-- MOVZX eax, word [rax]
							][
								emit #{0FB780}
								emit to-bin32 offset
							]
						]
					]
					all [size = 1 not compiler/any-float? mtype] [
						either signed? [
							either zero? offset [
								emit #{0FBE00}		;-- MOVSX eax, byte [rax]
							][
								emit #{0FBE80}
								emit to-bin32 offset
							]
						][
							either zero? offset [
								emit #{0FB600}		;-- MOVZX eax, byte [rax]
							][
								emit #{0FB680}
								emit to-bin32 offset
							]
						]
					]
					true [
						compiler/throw-error ["x86-64 pointer load type not supported yet:" mold mtype/1]
					]
				]
			]
			struct! union! [
				spec: either parent [parent][second compiler/resolve-type to word! path/1]
				unless parent [emit-init-path path/1]
				mtype: compiler/resolve-type/with path/2 spec
				set-width/type mtype/1
				offset: emitter/member-offset? spec path/2
				size: emitter/size-of? mtype
				signed?: compiler/signed-integer? mtype
				case [
					compiler/any-float? mtype [
						either size = 4 [
							either zero? offset [
								emit #{C5FA1000}	;-- VMOVSS xmm0, [rax]
							][
								emit #{C5FA1080}	;-- VMOVSS xmm0, [rax+disp32]
								emit to-bin32 offset
							]
						][
							either zero? offset [
								emit #{C5FB1000}	;-- VMOVSD xmm0, [rax]
							][
								emit #{C5FB1080}	;-- VMOVSD xmm0, [rax+disp32]
								emit to-bin32 offset
							]
						]
					]
					all [size = 8 not compiler/any-float? mtype] [
						either zero? offset [
							emit #{488B00}			;-- MOV rax, [rax]
						][
							emit #{488B80}			;-- MOV rax, [rax+disp32]
							emit to-bin32 offset
						]
					]
					all [size = 4 not compiler/any-float? mtype] [
						either zero? offset [
							emit #{8B00}			;-- MOV eax, [rax]
						][
							emit #{8B80}			;-- MOV eax, [rax+disp32]
							emit to-bin32 offset
						]
					]
					all [size = 2 not compiler/any-float? mtype] [
						either signed? [
							either zero? offset [
								emit #{0FBF00}		;-- MOVSX eax, word [rax]
							][
								emit #{0FBF80}		;-- MOVSX eax, word [rax+disp32]
								emit to-bin32 offset
							]
						][
							either zero? offset [
								emit #{0FB700}		;-- MOVZX eax, word [rax]
							][
								emit #{0FB780}		;-- MOVZX eax, word [rax+disp32]
								emit to-bin32 offset
							]
						]
					]
					all [size = 1 not compiler/any-float? mtype] [
						either signed? [
							either zero? offset [
								emit #{0FBE00}		;-- MOVSX eax, byte [rax]
							][
								emit #{0FBE80}		;-- MOVSX eax, byte [rax+disp32]
								emit to-bin32 offset
							]
						][
							either zero? offset [
								emit #{0FB600}		;-- MOVZX eax, byte [rax]
							][
								emit #{0FB680}		;-- MOVZX eax, byte [rax+disp32]
								emit to-bin32 offset
							]
						]
					]
					true [
						compiler/throw-error ["x86-64 path load type not supported yet:" mold mtype/1]
					]
				]
			]
			true [
				compiler/throw-error ["x86-64 load path type not supported yet:" mold type]
			]
		]
	]
	emit-store-path: func [
		path [set-path!]
		type [word!]
		value
		parent [block! none!]
		/local spec offset mtype size signed? source-type last? base value-reg idx
	][
		if verbose >= 3 [print [">>>storing path:" mold path mold value]]
		switch type [
			c-string! [
				unless parent [emit-init-path path/1]
				idx: path/2
				if value <> <last> [
					emit #{50}						;-- PUSH rax
					emit-load value
					emit #{5A}						;-- POP rdx
				]
				last?: value = <last>
				base: either last? [#{00}][#{02}]
				either integer? idx [
					offset: idx - 1
					case [
						zero? offset [
							emit rejoin [#{88} base] ;-- MOV [base], al
						]
						true [
							emit rejoin [#{88} either last? [#{80}][#{82}]]
							emit to-bin32 offset
						]
					]
				][
					emit-load-ecx idx
					emit #{FFC9}					;-- DEC ecx, one-based index
					emit either last? [
						#{880408}					;-- MOV [rax+rcx], al
					][
						#{88040A}					;-- MOV [rdx+rcx], al
					]
				]
			]
			pointer! [
				spec: compiler/resolve-type to word! path/1
				emit-init-path path/1
				mtype: spec/2
				set-width/type mtype/1
				size: emitter/size-of? mtype
				idx: either path/2 = 'value [1][path/2]
				unless integer? idx [
					compiler/throw-error "x86-64 pointer variable indexes are not implemented yet"
				]
				offset: (idx - 1) * size
				source-type: either value = <last> [compiler/last-type][compiler/get-type value]
				last?: value = <last>
				if value <> <last> [
					emit #{50}						;-- PUSH rax
					emit-load value
					case [
						all [
							compiler/integer-type? source-type
							find [float! float32! float64!] mtype/1
						][
							emit either mtype/1 = 'float32! [
								either compiler/int64? source-type [#{C4E1FA2AC0}][#{C5FA2AC0}]
							][
								either compiler/int64? source-type [#{C4E1FB2AC0}][#{C5FB2AC0}]
							]
						]
						all [
							source-type/1 = 'float32!
							find [float! float64!] mtype/1
						][
							emit #{C5FA5AC0}		;-- VCVTSS2SD xmm0, xmm0, xmm0
						]
						all [
							find [float! float64!] source-type/1
							mtype/1 = 'float32!
						][
							emit #{C5FB5AC0}		;-- VCVTSD2SS xmm0, xmm0, xmm0
						]
					]
					emit #{5A}						;-- POP rdx
				]
				base: either last? [#{00}][#{02}]
				value-reg: either last? [#{10}][#{02}]
				case [
					compiler/any-float? mtype [
						either size = 4 [
							either zero? offset [
								emit rejoin [#{C5FA11} base]	;-- VMOVSS [base], xmm0
							][
								emit rejoin [#{C5FA11} either last? [#{80}][#{82}]]
								emit to-bin32 offset
							]
						][
							either zero? offset [
								emit rejoin [#{C5FB11} base]	;-- VMOVSD [base], xmm0
							][
								emit rejoin [#{C5FB11} either last? [#{80}][#{82}]]
								emit to-bin32 offset
							]
						]
					]
					all [size = 8 not compiler/any-float? mtype] [
						either zero? offset [
							emit rejoin [#{4889} value-reg]	;-- MOV [base], r64
						][
							emit rejoin [#{4889} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
					all [size = 4 not compiler/any-float? mtype] [
						either zero? offset [
							emit rejoin [#{89} value-reg]	;-- MOV [base], r32
						][
							emit rejoin [#{89} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
					all [size = 2 not compiler/any-float? mtype] [
						either zero? offset [
							emit rejoin [#{6689} value-reg]	;-- MOV [base], r16
						][
							emit rejoin [#{6689} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
					all [size = 1 not compiler/any-float? mtype] [
						either zero? offset [
							emit rejoin [#{88} value-reg]	;-- MOV [base], r8
						][
							emit rejoin [#{88} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
					true [
						compiler/throw-error ["x86-64 pointer store type not supported yet:" mold mtype/1]
					]
				]
			]
			struct! union! [
				spec: either parent [parent][second compiler/resolve-type to word! path/1]
				unless parent [emit-init-path path/1]
				mtype: compiler/resolve-type/with path/2 spec
				set-width/type mtype/1
				offset: emitter/member-offset? spec path/2
				size: emitter/size-of? mtype
				if all [
					paren? value
					find [struct! union!] mtype/1
				][
					exit
				]
				if set-path? path [emit-store-union-tag spec path/2 'rax]
				source-type: either value = <last> [compiler/last-type][compiler/get-type value]
				last?: value = <last>
				if value <> <last> [
					emit #{50}						;-- PUSH rax
					emit-load value
					case [
						all [
							compiler/integer-type? source-type
							find [float! float32! float64!] mtype/1
						][
							emit either mtype/1 = 'float32! [
								either compiler/int64? source-type [#{C4E1FA2AC0}][#{C5FA2AC0}]
							][
								either compiler/int64? source-type [#{C4E1FB2AC0}][#{C5FB2AC0}]
							]
						]
						all [
							source-type/1 = 'float32!
							find [float! float64!] mtype/1
						][
							emit #{C5FA5AC0}		;-- VCVTSS2SD xmm0, xmm0, xmm0
						]
						all [
							find [float! float64!] source-type/1
							mtype/1 = 'float32!
						][
							emit #{C5FB5AC0}		;-- VCVTSD2SS xmm0, xmm0, xmm0
						]
					]
					emit #{5A}						;-- POP rdx
				]
				base: either last? [#{00}][#{02}]	;-- last: [rax], loaded value: [rdx]
				value-reg: either last? [#{10}][#{02}]
				case [
					compiler/any-float? mtype [
						either size = 4 [
							either zero? offset [
								emit rejoin [#{C5FA11} base]	;-- VMOVSS [base], xmm0
							][
								emit rejoin [#{C5FA11} either last? [#{80}][#{82}]]
								emit to-bin32 offset
							]
						][
							either zero? offset [
								emit rejoin [#{C5FB11} base]	;-- VMOVSD [base], xmm0
							][
								emit rejoin [#{C5FB11} either last? [#{80}][#{82}]]
								emit to-bin32 offset
							]
						]
					]
					all [size = 8 not compiler/any-float? mtype] [
						either zero? offset [
							emit rejoin [#{4889} value-reg]	;-- MOV [base], r64
						][
							emit rejoin [#{4889} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
					all [size = 4 not compiler/any-float? mtype] [
						either zero? offset [
							emit rejoin [#{89} value-reg]	;-- MOV [base], r32
						][
							emit rejoin [#{89} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
					all [size = 2 not compiler/any-float? mtype] [
						either zero? offset [
							emit rejoin [#{6689} value-reg]	;-- MOV [base], r16
						][
							emit rejoin [#{6689} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
					all [size = 1 not compiler/any-float? mtype] [
						either zero? offset [
							emit rejoin [#{88} value-reg]	;-- MOV [base], r8
						][
							emit rejoin [#{88} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
					true [
						compiler/throw-error ["x86-64 path store type not supported yet:" mold mtype/1]
					]
				]
			]
			true [
				compiler/throw-error ["x86-64 store path type not supported yet:" mold type]
			]
		]
	]
	emit-access-path: func [
		path [path! set-path!]
		spec [block! none!]
		/local offset mtype field size signed?
	][
		if verbose >= 3 [print [">>>accessing path:" mold path]]
		unless spec [
			spec: second compiler/resolve-type to word! path/1
			emit-init-path path/1
		]
		mtype: compiler/resolve-type/with path/2 spec
		field: select spec path/2
		offset: emitter/member-offset? spec path/2
		either find [struct! union!] mtype/1 [
			unless zero? offset [
				emit #{488D80}						;-- LEA rax, [rax+disp32]
				emit to-bin32 offset
			]
		][
			size: emitter/size-of? mtype
			signed?: compiler/signed-integer? mtype
			case [
				compiler/any-float? mtype [
					either size = 4 [
						either zero? offset [
							emit #{C5FA1000}		;-- VMOVSS xmm0, [rax]
						][
							emit #{C5FA1080}
							emit to-bin32 offset
						]
					][
						either zero? offset [
							emit #{C5FB1000}		;-- VMOVSD xmm0, [rax]
						][
							emit #{C5FB1080}
							emit to-bin32 offset
						]
					]
				]
				all [size = 8 not compiler/any-float? mtype] [
					either zero? offset [
						emit #{488B00}				;-- MOV rax, [rax]
					][
						emit #{488B80}
						emit to-bin32 offset
					]
				]
				all [size = 4 not compiler/any-float? mtype] [
					either zero? offset [
						emit #{8B00}				;-- MOV eax, [rax]
					][
						emit #{8B80}
						emit to-bin32 offset
					]
				]
				all [size = 2 not compiler/any-float? mtype] [
					either signed? [
						either zero? offset [
							emit #{0FBF00}			;-- MOVSX eax, word [rax]
						][
							emit #{0FBF80}
							emit to-bin32 offset
						]
					][
						either zero? offset [
							emit #{0FB700}			;-- MOVZX eax, word [rax]
						][
							emit #{0FB780}
							emit to-bin32 offset
						]
					]
				]
				all [size = 1 not compiler/any-float? mtype] [
					either signed? [
						either zero? offset [
							emit #{0FBE00}			;-- MOVSX eax, byte [rax]
						][
							emit #{0FBE80}
							emit to-bin32 offset
						]
					][
						either zero? offset [
							emit #{0FB600}			;-- MOVZX eax, byte [rax]
						][
							emit #{0FB680}
							emit to-bin32 offset
						]
					]
				]
				true [
					compiler/throw-error ["x86-64 nested path type not supported yet:" mold mtype/1]
				]
			]
		]
	]
	emit-access-register: func [reg [word!] set? [logic!] value /local opcode][
		if verbose >= 3 [print [">>>emitting ACCESS-REGISTER" mold value]]
		if all [set? not tag? value][emit-load value]
		case [
			reg = 'rax [
				if set? [exit]
			]
			reg = 'rbx [
				emit either set? [#{4889C3}][#{488BC3}]
			]
			reg = 'rcx [
				emit either set? [#{4889C1}][#{488BC1}]
			]
			reg = 'rdx [
				emit either set? [#{4889C2}][#{488BC2}]
			]
			reg = 'rsp [
				emit either set? [#{4889C4}][#{488BC4}]
			]
			reg = 'rbp [
				emit either set? [#{4889C5}][#{488BC5}]
			]
			reg = 'rsi [
				emit either set? [#{4889C6}][#{488BC6}]
			]
			reg = 'rdi [
				emit either set? [#{4889C7}][#{488BC7}]
			]
			reg = 'r8 [
				emit either set? [#{4989C0}][#{4C8BC0}]
			]
			reg = 'r9 [
				emit either set? [#{4989C1}][#{4C8BC1}]
			]
			reg = 'r10 [
				emit either set? [#{4989C2}][#{4C8BC2}]
			]
			reg = 'r11 [
				emit either set? [#{4989C3}][#{4C8BC3}]
			]
			reg = 'r12 [
				emit either set? [#{4989C4}][#{4C8BC4}]
			]
			reg = 'r13 [
				emit either set? [#{4989C5}][#{4C8BC5}]
			]
			reg = 'r14 [
				emit either set? [#{4989C6}][#{4C8BC6}]
			]
			reg = 'r15 [
				emit either set? [#{4989C7}][#{4C8BC7}]
			]
			true [
				compiler/throw-error ["x86-64 system/cpu register not supported yet:" mold reg]
			]
		]
	]
	emit-move-path-alt: :unsupported
	emit-push-struct: :unsupported
	emit-store-union-tag: func [spec [block!] name [word!] reg [word!] /local id tag type][
		if all [
			compiler/tagged-union? spec
			id: compiler/union-variant-id? spec name
		][
			tag: compiler/union-tag-type? spec
			type: tag/1
			switch type [
				uint8! [
					emit either reg = 'rax [#{C600}][#{C602}]
					emit to-bin8 id
				]
				uint16! [
					emit either reg = 'rax [#{66C700}][#{66C702}]
					emit to-bin16 id
				]
				uint32! [
					emit either reg = 'rax [#{C700}][#{C702}]
					emit to-bin32 id
				]
			]
		]
	]
	emit-load-union-tag: func [spec [block!] /local tag type][
		tag: compiler/union-tag-type? spec
		type: tag/1
		switch type [
			uint8!  [emit #{0FB600}]
			uint16! [emit #{0FB700}]
			uint32! [emit #{8B00}]
		]
		set-width 4
	]
	emit-variant-check: func [spec [block!] id [integer!]][
		emit-load-union-tag spec
		emit #{3D}
		emit to-bin32 id
		emit #{0F94C0}
		emit #{0FB6C0}
		set-width 4
	]
	emit-boolean-switch: func [op [word! none!]][
		either op [
			emit add-condition op copy #{0F90}			;-- SETcc al
			emit #{C0}
			emit #{0FB6C0}								;-- MOVZX eax, al
			reduce [0 0]
		][
			emit #{31C0}								;-- XOR eax, eax
			emit #{EB03}								;-- JMP _exit
			emit #{31C0}								;-- XOR eax, eax
			emit #{40}									;-- INC eax
			reduce [3 7]
		]
	]

	construct-jump: func [
		op [word! none!]
		size [integer!]
		back? [logic! none!]
		/local opcode o short? dir
	][
		o: size * dir: pick [-1 1] yes = back?
		short?: to logic! all [-126 <= o o <= 127]
		opcode: pick pick [
			[#{EB} #{E9}]
			[#{70} #{0F80}]
			[#{7A} #{0F8A}]
		] either op = 'parity [3][none? op] short?
		if all [op op <> 'parity][
			opcode: add-condition op copy opcode
		]
		if back? [
			size: size + (length? opcode) + (pick [1 4] short?)
			o: size * dir
		]
		o: either short? [to-bin8 o][to-bin32 o]
		reduce [size rejoin [opcode o]]
	]

	emit-branch: func [
		code [binary!]
		op [word! block! logic! none!]
		offset [integer! none!]
		parity [none! logic!]
		/back?
		/local size jump jxx jump-code
	][
		size: (length? code) - any [offset 0]
		jump: copy #{}
		jxx: [second set [size jump-code] construct-jump op size back?]
		either none? op [
			append jump do jxx
		][
			op: case [
				block? op [
					op: op/1
					either logic? op [pick [= <>] op][op]
				]
				logic? op [pick [= <>] op]
				true [opposite? op]
			]
			append jump do jxx
		]
		insert any [all [back? tail code] code] jump
		length? jump
	]

	emit-jump-point: func [type [block!]][
		emit #{E9}									;-- JMP rel32
		emit-reloc-disp32 compose/only [- - (type)]
	]
	emit-start-loop: func [spec [block! none!] name [word! none!]][
		either spec [
			emit-global-ref spec/2 #{8905}			;-- MOV [rip+disp32], eax
		][
			emit-local-ref name #{8945}				;-- MOV [rbp+disp8], eax
		]
	]
	emit-end-loop: func [spec [block! none!] name [word! none!]][
		either spec [
			emit-global-ref spec/2 #{8B05}			;-- MOV eax, [rip+disp32]
		][
			emit-local-ref name #{8B45}				;-- MOV eax, [rbp+disp8]
		]
		emit #{83E801}								;-- SUB eax, 1
	]
	emit-move-path-alt: func [/pair][
		either pair [
			emit #{50}								;-- PUSH rax
		][
			emit #{4889C2}							;-- MOV rdx, rax
		]
	]
	emit-save-last: does [
		last-saved?: yes
		either compiler/any-float? compiler/last-type [
			emit #{4883EC10}						;-- SUB rsp, 16
			emit either compiler/last-type/1 = 'float32! [#{C5FA110424}][#{C5FB110424}]
		][
			emit #{4883EC10}						;-- SUB rsp, 16
			emit #{48890424}						;-- MOV [rsp], rax
		]
	]
	emit-restore-last: does [
		either compiler/any-float? compiler/last-type [
			emit either compiler/last-type/1 = 'float32! [#{C5FA100424}][#{C5FB100424}]
			emit #{4883C410}						;-- ADD rsp, 16
		][
			emit #{488B0424}						;-- MOV rax, [rsp]
			emit #{4883C410}						;-- ADD rsp, 16
		]
	]
	emit-set-stack: func [value /frame][
		if verbose >= 3 [print [">>>emitting SET-STACK" mold value]]
		unless tag? value [emit-load value]
		either frame [
			emit #{4889C5}							;-- MOV rbp, rax
		][
			emit #{4889C4}							;-- MOV rsp, rax
		]
	]
	emit-get-stack: func [/frame][
		if verbose >= 3 [print ">>>emitting GET-STACK"]
		either frame [
			emit #{4889E8}							;-- MOV rax, rbp
		][
			emit #{4889E0}							;-- MOV rax, rsp
		]
	]
	emit-get-pc: func [/local][
		emit #{E800000000}							;-- CALL next
		emit-pop									;-- get RIP in rax
		5											;-- return adjustment offset (CALL size)
	]
	emit-get-overflow: does [
		either last-math-op = divide-sym [
			emit #{B800000000}					;-- MOV eax, 0
		][
			emit #{0F90C0}						;-- SETO al
			emit #{0FB6C0}						;-- MOVZX eax, al
		]
	]
	emit-reserve-stack: func [slots [integer!] /local size][
		size: slots * stack-width
		either size > 127 [
			emit #{4881EC}							;-- SUB rsp, imm32
			emit to-bin32 size
		][
			emit #{4883EC}							;-- SUB rsp, imm8
			emit to-bin8 size
		]
	]
	emit-release-stack: func [slots [integer!] /bytes][]
	emit-alloc-stack: func [zeroed? [logic!]][
		if zeroed? [emit #{4889C1}]				;-- MOV rcx, rax
		emit #{48C1E003}							;-- SHL rax, 3
		emit #{4829C4}								;-- SUB rsp, rax
		if zeroed? [
			emit #{4889E7}							;-- MOV rdi, rsp
			emit #{31C0}							;-- XOR eax, eax
			emit #{F348AB}							;-- REP STOSQ
		]
	]
	emit-free-stack: does [
		emit #{48C1E003}							;-- SHL rax, 3
		emit #{4801C4}								;-- ADD rsp, rax
	]
	emit-clear-slot: func [name [word!]][
		emit-local-ref name #{C645}					;-- MOV byte [rbp+disp8], 0
		emit #{00}
	]
	emit-open-catch: func [body-size [integer!] global? [logic!]][
		either global? [
			emit #{55}								;-- PUSH rbp
			emit #{4889E5}							;-- MOV rbp, rsp
			emit #{6A00}							;-- PUSH 0		; catch ID
			emit #{6A00}							;-- PUSH 0		; catch resume address
			emit #{488945F8}						;-- MOV [rbp-8], rax
			emit #{E800000000}						;-- CALL next
			emit #{58}								;-- POP rax
			emit #{4805}							;-- ADD rax, body-size + catch prolog tail
			emit to-bin32 body-size + 11
			emit #{488945F0}						;-- MOV [rbp-16], rax
			28
		][
			emit #{FF75F8}							;-- PUSH [rbp-8]		; save old catch value
			emit #{FF75F0}							;-- PUSH [rbp-16]		; save old resume address
			emit #{488945F8}						;-- MOV [rbp-8], rax
			emit #{E800000000}						;-- CALL next
			emit #{58}								;-- POP rax
			emit #{4805}							;-- ADD rax, body-size + catch prolog tail
			emit to-bin32 body-size + 11
			emit #{488945F0}						;-- MOV [rbp-16], rax
			26
		]
	]
	emit-close-catch: func [offset [integer!] level [integer!] global? [logic!] callback? [logic!]][
		either global? [
			emit #{488D65F0}						;-- LEA rsp, [rbp-16]
			emit #{58}								;-- POP rax
			emit #{58}								;-- POP rax
			emit #{C9}								;-- LEAVE
		][
			offset: offset + locals-offset + ((level + 1) * stack-width)
			either offset > 127 [
				emit #{4889EC}						;-- MOV rsp, rbp
				emit #{4881EC}						;-- SUB rsp, imm32
				emit to-bin32 offset
			][
				emit #{488D65}						;-- LEA rsp, [rbp-offset]
				emit to-char 256 - offset
			]
			emit #{8F45F0}							;-- POP [rbp-16]
			emit #{8F45F8}							;-- POP [rbp-8]
		]
	]
	emit-read-io: :unsupported
	emit-io-read: :unsupported
	emit-io-write: :unsupported
	emit-fpu-init: :unsupported
	emit-fpu-get: :unsupported
	emit-fpu-set: :unsupported
	emit-fpu-update: :unsupported
	emit-push: func [value][
		if verbose >= 3 [print [">>>pushing" mold value]]
		if logic? value [value: to integer! value]
		either value = <last> [
			emit #{50}									;-- PUSH rax
		][
			either all [integer? value value >= -128 value <= 127][
				emit #{6A}
				emit to-bin8 value
			][
				either integer? value [
					emit #{48B8}						;-- MOV rax, imm64
					emit to-bin64 value
				][
					emit-load value
				]
				emit #{50}								;-- PUSH rax
			]
		]
	]
	emit-push-all: does [
		emit #{50}								;-- PUSH rax
		emit #{51}								;-- PUSH rcx
		emit #{52}								;-- PUSH rdx
		emit #{53}								;-- PUSH rbx
		emit #{55}								;-- PUSH rbp
		emit #{56}								;-- PUSH rsi
		emit #{57}								;-- PUSH rdi
		emit #{4150}							;-- PUSH r8
		emit #{4151}							;-- PUSH r9
		emit #{4152}							;-- PUSH r10
		emit #{4153}							;-- PUSH r11
		emit #{4154}							;-- PUSH r12
		emit #{4155}							;-- PUSH r13
		emit #{4156}							;-- PUSH r14
		emit #{4157}							;-- PUSH r15
		emit #{9C}								;-- PUSHFQ
		emit #{4889E0}							;-- MOV rax, rsp
		emit #{4883E4F0}						;-- AND rsp, -16
		emit #{4881EC10020000}					;-- SUB rsp, 528
		emit #{0FAE0424}						;-- FXSAVE [rsp]
		emit #{4889842400020000}				;-- MOV [rsp+512], rax
	]
	emit-pop-all: does [
		emit #{0FAE0C24}						;-- FXRSTOR [rsp]
		emit #{488B842400020000}				;-- MOV rax, [rsp+512]
		emit #{4889C4}							;-- MOV rsp, rax
		emit #{9D}								;-- POPFQ
		emit #{415F}							;-- POP r15
		emit #{415E}							;-- POP r14
		emit #{415D}							;-- POP r13
		emit #{415C}							;-- POP r12
		emit #{415B}							;-- POP r11
		emit #{415A}							;-- POP r10
		emit #{4159}							;-- POP r9
		emit #{4158}							;-- POP r8
		emit #{5F}								;-- POP rdi
		emit #{5E}								;-- POP rsi
		emit #{5D}								;-- POP rbp
		emit #{5B}								;-- POP rbx
		emit #{5A}								;-- POP rdx
		emit #{59}								;-- POP rcx
		emit #{58}								;-- POP rax
	]
	emit-atomic-cas: :unsupported
	emit-atomic-load: :unsupported
	emit-atomic-store: :unsupported
	emit-atomic-math: :unsupported
	emit-atomic-fence: :unsupported
	emit-init-sub: :unsupported
	emit-return-sub: :unsupported
	emit-call-sub: :unsupported
]
