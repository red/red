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
	
	unsupported: does [
		compiler/throw-error "Linux x86-64 backend code generation is not implemented yet"
	]

	noop: does []

	emit-reloc-disp32: func [spec [block!]][
		append spec/3 emitter/tail-ptr
		emit to-bin32 0
	]

	emit-global-ref: func [
		name [word! object!]
		opcode [binary!]
		/local spec
	][
		if object? name [name: compiler/unbox name]
		spec: emitter/symbols/:name
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
	patch-jump-back: :unsupported
	patch-jump-point: :unsupported
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
	emit-casting: :unsupported
	emit-call-syscall: func [args [block!] fspec [block!] attribs [block! none!] /local pops n][
		pops: [
			#{5F}		;-- POP rdi
			#{5E}		;-- POP rsi
			#{5A}		;-- POP rdx
			#{415A}		;-- POP r10
			#{4158}		;-- POP r8
			#{4159}		;-- POP r9
		]
		n: fspec/1
		if n > length? pops [
			compiler/throw-error ["x86-64 syscall with too many args:" n]
		]
		while [n > 0][
			emit pick pops n
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
		/local pops n
	][
		pops: [
			#{5F}		;-- POP rdi
			#{5E}		;-- POP rsi
			#{5A}		;-- POP rdx
			#{59}		;-- POP rcx
			#{4158}		;-- POP r8
			#{4159}		;-- POP r9
		]
		n: fspec/1
		if n > length? pops [
			compiler/throw-error ["x86-64 imported function with more than 6 arguments is not implemented yet:" n]
		]
		while [n > 0][
			emit pick pops n
			n: n - 1
		]
		emit #{FF15}								;-- CALL qword [rip+disp32]
		emit-reloc-disp32 spec
	]
	emit-call-native: func [
		args [block!] fspec [block!] spec [block!] attribs [block! none!]
		/routine name [word!]
		/local pops n
	][
		if routine [
			compiler/throw-error "x86-64 routine calls are not implemented yet"
		]
		pops: [
			#{5F}		;-- POP rdi
			#{5E}		;-- POP rsi
			#{5A}		;-- POP rdx
			#{59}		;-- POP rcx
			#{4158}		;-- POP r8
			#{4159}		;-- POP r9
		]
		n: fspec/1
		if n > length? pops [
			compiler/throw-error "x86-64 functions with more than 6 arguments are not implemented yet"
		]
		while [n > 0][
			emit pick pops n
			n: n - 1
		]
		emit #{E8}									;-- CALL rel32
		emit-reloc-disp32 spec
	]
	emit-not: :unsupported
	emit-pop: :unsupported
	emit-integer-operation: func [name [word!] args [block!] /local right imm?][
		emit-load args/1
		right: compiler/unbox args/2
		imm?: integer? right
		either imm? [
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
		][
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
	emit-boolean-switch: :unsupported
	emit-branch: :unsupported
	emit-jump-point: :unsupported
	emit-start-loop: :unsupported
	emit-end-loop: :unsupported
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
	emit-clear-slot: :unsupported
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
