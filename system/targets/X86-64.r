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

	patch-stack-offset: func [name [word!] offset [integer!] /local pos][
		if pos: find/skip emitter/stack name 2 [
			pos/2: offset
		]
	]

	emit-arg-spills: func [locals [block!] /local regs offset name type count][
		regs: [
			#{57}		;-- PUSH rdi
			#{56}		;-- PUSH rsi
			#{52}		;-- PUSH rdx
			#{51}		;-- PUSH rcx
			#{4150}		;-- PUSH r8
			#{4151}		;-- PUSH r9
		]
		offset: 0
		count: 0
		parse locals [
			opt block!
			any [
				set name word! set type block! (
					count: count + 1
					if count > length? regs [
						compiler/throw-error "x86-64 functions with more than 6 arguments are not implemented yet"
					]
					offset: offset - stack-width
					emit pick regs count
					patch-stack-offset name offset
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

	emit-local-ref: func [
		name [word! object!]
		opcode [binary!]
		/local offset
	][
		if object? name [name: compiler/unbox name]
		offset: emitter/local-offset? name
		unless offset [
			compiler/throw-error ["unknown local variable:" name]
		]
		unless all [offset >= -128 offset <= 127] [
			compiler/throw-error "x86-64 local offset wider than disp8 is not implemented yet"
		]
		emit opcode
		emit to-bin8 offset
	]

	emit-load-ecx: func [value /local type][
		case [
			integer? value [
				emit #{B9}							;-- MOV ecx, imm32
				emit to-bin32 value
			]
			word? value [
				type: compiler/get-type value
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
			true [
				compiler/throw-error ["x86-64 secondary operand not supported yet:" mold value]
			]
		]
	]

	on-init: :noop
	on-global-prolog: func [runtime? [logic!] type [word!]][]
	on-global-epilog: func [runtime? [logic!] type [word!]][]
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
	emit-prolog: func [name [word!] locals [block!] bitmap [integer!] /local locals-size][
		locals-offset: (argument-count? locals) * stack-width
		locals-size: either find locals /local [
			emitter/calc-locals-offsets find locals /local
		][0]
		emit #{55}									;-- PUSH rbp
		emit #{4889E5}								;-- MOV rbp, rsp
		emit-arg-spills locals
		if locals-size <> 0 [
			emit-reserve-stack (round/to/ceiling locals-size stack-width) / stack-width
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
	emit-float-trash-last: :unsupported
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
	]
	emit-call-import: func [
		args [block!]
		fspec [block!]
		spec [block!]
		attribs [block! none!]
		/local n
	][
		n: fspec/1
		if n > 6 [
			compiler/throw-error ["x86-64 imported function with more than 6 arguments is not implemented yet:" n]
		]
		repeat i n [
			emit pick [
				#{5F}		;-- POP rdi
				#{5E}		;-- POP rsi
				#{5A}		;-- POP rdx
				#{59}		;-- POP rcx
				#{4158}		;-- POP r8
				#{4159}		;-- POP r9
			] i
		]
		emit #{FF15}								;-- CALL qword [rip+disp32]
		emit-reloc-disp32 spec
	]
	emit-call-native: func [
		args [block!] fspec [block!] spec [block!] attribs [block! none!]
		/routine name [word!]
		/local n
	][
		if routine [
			compiler/throw-error "x86-64 routine calls are not implemented yet"
		]
		n: fspec/1
		if n > 6 [
			compiler/throw-error "x86-64 functions with more than 6 arguments are not implemented yet"
		]
		repeat i n [
			emit pick [
				#{5F}		;-- POP rdi
				#{5E}		;-- POP rsi
				#{5A}		;-- POP rdx
				#{59}		;-- POP rcx
				#{4158}		;-- POP r8
				#{4159}		;-- POP r9
			] i
		]
		emit #{E8}									;-- CALL rel32
		emit-reloc-disp32 spec
	]
	emit-not: :unsupported
	emit-pop: :unsupported
	emit-integer-operation: func [name [word!] args [block!] /local right imm?][
		emit-load args/1
		right: compiler/unbox args/2
		if char? right [right: to integer! right]
		if logic? right [right: to integer! right]
		imm?: integer? right
		case [
			find comparison-op name [
				either imm? [
					either any [
						all [integer? right zero? right]
						all [logic? right not right]
					][
						emit #{85C0}				;-- TEST eax, eax
					][
						emit #{3D}					;-- CMP eax, imm32
						emit to-bin32 right
					]
				][
					emit-load-ecx right
					emit #{39C8}					;-- CMP eax, ecx
				]
			]
			imm? [
				switch/default name [
					+	[emit #{05} emit to-bin32 right]	;-- ADD eax, imm32
					-	[emit #{2D} emit to-bin32 right]	;-- SUB eax, imm32
					*	[emit #{69C0} emit to-bin32 right]	;-- IMUL eax, eax, imm32
					and [emit #{25} emit to-bin32 right]	;-- AND eax, imm32
					or	[emit #{0D} emit to-bin32 right]	;-- OR eax, imm32
					xor [emit #{35} emit to-bin32 right]	;-- XOR eax, imm32
					<<	[emit #{C1E0} emit to-bin8 right]	;-- SHL eax, imm8
					>>	[emit #{C1F8} emit to-bin8 right]	;-- SAR eax, imm8
					-**	[emit #{C1E8} emit to-bin8 right]	;-- SHR eax, imm8
				][
					compiler/throw-error ["x86-64 integer op not supported yet:" mold name]
				]
			]
			true [
				emit-load-ecx right
				switch/default name [
					+	[emit #{01C8}]					;-- ADD eax, ecx
					-	[emit #{29C8}]					;-- SUB eax, ecx
					*	[emit #{0FAFC1}]				;-- IMUL eax, ecx
					and [emit #{21C8}]					;-- AND eax, ecx
					or	[emit #{09C8}]					;-- OR eax, ecx
					xor [emit #{31C8}]					;-- XOR eax, ecx
					<<	[emit #{D3E0}]					;-- SHL eax, cl
					>>	[emit #{D3F8}]					;-- SAR eax, cl
					-**	[emit #{D3E8}]					;-- SHR eax, cl
				][
					compiler/throw-error ["x86-64 integer op not supported yet:" mold name]
				]
			]
		]
	]
	emit-float-operation: :unsupported
	emit-throw: :unsupported
	emit-alt-last: :unsupported
	emit-log-b: :unsupported
	emit-variable: func [name [word! object!]][
		emit-load name
	]
	emit-argument: func [arg fspec [block!] /local value][
		if arg = #_ [exit]
		value: compiler/unbox arg
		either word? value [
			emit-load value
			emit-push <last>
		][
			if logic? value [value: to integer! value]
			unless any [integer? value char? value][
				compiler/throw-error ["x86-64 literal argument not supported yet:" mold value]
			]
			emit-push value
		]
	]
	emit-load: func [value /local type][
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
			word? value [
				type: compiler/get-type value
				either emitter/local-offset? value [
					switch/default type/1 [
						byte!	 [emit-local-ref value #{0FB645}]	;-- MOVZX eax, byte [rbp+disp8]
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
					][
						compiler/throw-error ["x86-64 local load type not supported yet:" mold type/1]
					]
				][
					switch/default type/1 [
						byte!	 [emit-global-ref value #{0FB605}]	;-- MOVZX eax, byte [RIP+disp32]
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
					][
						compiler/throw-error ["x86-64 load type not supported yet:" mold type/1]
					]
				]
			]
			true [
				compiler/throw-error ["x86-64 load not supported yet:" mold value]
			]
		]
	]
	emit-load-literal: :unsupported
	emit-load-literal-ptr: func [spec [block!]][
		emit #{488D05}								;-- LEA rax, [RIP+disp32]
		emit-reloc-disp32 spec
	]
	emit-store: func [
		name [word!] value
		spec [block! none!]
		/by-value slots [integer!]
		/local type opcode local?
	][
		if by-value [
			compiler/throw-error "x86-64 by-value store is not implemented yet"
		]
		if logic? value [value: to integer! value]
		if all [
			value <> <last>
			not find [string! paren! binary!] type?/word value
		][
			emit-load value
		]
		type: compiler/get-variable-spec name
		local?: emitter/local-offset? name
		either local? [
			opcode: switch/default type/1 [
				byte!	 [#{8845}]					;-- MOV [rbp+disp8], al
				int8!	 [#{8845}]
				uint8!	 [#{8845}]
				int16!	 [#{668945}]				;-- MOV [rbp+disp8], ax
				uint16!	 [#{668945}]
				integer! [#{8945}]					;-- MOV [rbp+disp8], eax
				int32!	 [#{8945}]
				uint32!	 [#{8945}]
				int64!	 [#{488945}]				;-- MOV [rbp+disp8], rax
				uint64!	 [#{488945}]
				pointer! [#{488945}]
				c-string! [#{488945}]
			][
				compiler/throw-error ["x86-64 local store type not supported yet:" mold type/1]
			]
			emit-local-ref name opcode
		][
			opcode: switch/default type/1 [
				byte!	 [#{8805}]					;-- MOV [RIP+disp32], al
				int8!	 [#{8805}]
				uint8!	 [#{8805}]
				int16!	 [#{668905}]				;-- MOV [RIP+disp32], ax
				uint16!	 [#{668905}]
				integer! [#{8905}]					;-- MOV [RIP+disp32], eax
				int32!	 [#{8905}]
				uint32!	 [#{8905}]
				int64!	 [#{488905}]				;-- MOV [RIP+disp32], rax
				uint64!	 [#{488905}]
				pointer! [#{488905}]
				c-string! [#{488905}]
			][
				compiler/throw-error ["x86-64 store type not supported yet:" mold type/1]
			]
			emit-global-ref name opcode
		]
	]
	emit-load-path: :unsupported
	emit-store-path: :unsupported
	emit-init-path: :unsupported
	emit-access-path: :unsupported
	emit-access-register: :unsupported
	emit-move-path-alt: :unsupported
	emit-push-struct: :unsupported
	emit-load-union-tag: :unsupported
	emit-variant-check: :unsupported
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
	emit-save-last: :unsupported
	emit-restore-last: :unsupported
	emit-get-stack: :unsupported
	emit-set-stack: :unsupported
	emit-get-pc: :unsupported
	emit-get-overflow: :unsupported
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
	emit-alloc-stack: :unsupported
	emit-free-stack: :unsupported
	emit-clear-slot: func [name [word!]][
		emit-local-ref name #{C645}					;-- MOV byte [rbp+disp8], 0
		emit #{00}
	]
	emit-open-catch: :unsupported
	emit-close-catch: :unsupported
	emit-read-io: :unsupported
	emit-io-read: :unsupported
	emit-io-write: :unsupported
	emit-fpu-init: :unsupported
	emit-fpu-get: :unsupported
	emit-fpu-set: :unsupported
	emit-fpu-update: :unsupported
	emit-push: func [value][
		either value = <last> [
			emit #{50}									;-- PUSH rax
		][
			either all [integer? value value >= -128 value <= 127][
				emit #{6A}
				emit to-bin8 value
			][
				emit #{48B8}							;-- MOV rax, imm64
				emit to-bin64 value
				emit #{50}								;-- PUSH rax
			]
		]
	]
	emit-push-all: :unsupported
	emit-pop-all: :unsupported
	emit-atomic-cas: :unsupported
	emit-atomic-load: :unsupported
	emit-atomic-store: :unsupported
	emit-atomic-math: :unsupported
	emit-atomic-fence: :unsupported
	emit-init-sub: :unsupported
	emit-return-sub: :unsupported
	emit-call-sub: :unsupported
]
