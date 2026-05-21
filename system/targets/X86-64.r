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

	on-init: :noop
	on-global-prolog: func [runtime? [logic!] type [word!]][]
	on-global-epilog: func [runtime? [logic!] type [word!]][]
	on-root-level-entry: :noop
	on-finalize: :noop
	patch-call: :unsupported
	patch-jump-back: :unsupported
	patch-jump-point: :unsupported
	patch-sub-call: :unsupported
	emit-prolog: :unsupported
	emit-epilog: :unsupported
	emit-stack-align-prolog: :unsupported
	emit-stack-align-epilog: :unsupported
	emit-stack-align: :unsupported
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
	emit-call-import: :unsupported
	emit-call-native: :unsupported
	emit-not: :unsupported
	emit-pop: :unsupported
	emit-integer-operation: func [name [word!] args [block!] /local right][
		emit-load args/1
		right: compiler/unbox args/2
		unless integer? right [
			compiler/throw-error ["x86-64 integer op right operand not supported yet:" mold right]
		]
		switch/default name [
			+	[emit #{05} emit to-bin32 right]		;-- ADD eax, imm32
			-	[emit #{2D} emit to-bin32 right]		;-- SUB eax, imm32
			*	[emit #{69C0} emit to-bin32 right]		;-- IMUL eax, eax, imm32
			and [emit #{25} emit to-bin32 right]		;-- AND eax, imm32
			or	[emit #{0D} emit to-bin32 right]		;-- OR eax, imm32
			xor [emit #{35} emit to-bin32 right]		;-- XOR eax, imm32
			<<	[emit #{C1E0} emit to-bin8 right]		;-- SHL eax, imm8
			>>	[emit #{C1F8} emit to-bin8 right]		;-- SAR eax, imm8
			-**	[emit #{C1E8} emit to-bin8 right]		;-- SHR eax, imm8
		][
			compiler/throw-error ["x86-64 integer op not supported yet:" mold name]
		]
	]
	emit-float-operation: :unsupported
	emit-throw: :unsupported
	emit-alt-last: :unsupported
	emit-log-b: :unsupported
	emit-variable: :unsupported
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
				switch/default type/1 [
					integer! [emit-global-ref value #{8B05}]		;-- MOV eax, [RIP+disp32]
					int32!	 [emit-global-ref value #{8B05}]
					uint32!	 [emit-global-ref value #{8B05}]
					int64!	 [emit-global-ref value #{488B05}]		;-- MOV rax, [RIP+disp32]
					uint64!	 [emit-global-ref value #{488B05}]
					pointer! [emit-global-ref value #{488B05}]
					c-string! [emit-global-ref value #{488B05}]
				][
					compiler/throw-error ["x86-64 load type not supported yet:" mold type/1]
				]
			]
			true [
				compiler/throw-error ["x86-64 load not supported yet:" mold value]
			]
		]
	]
	emit-load-literal: :unsupported
	emit-load-literal-ptr: :unsupported
	emit-store: func [
		name [word!] value
		spec [block! none!]
		/by-value slots [integer!]
		/local type opcode
	][
		if by-value [
			compiler/throw-error "x86-64 by-value store is not implemented yet"
		]
		if logic? value [value: to integer! value]
		if value <> <last> [
			emit-load value
		]
		type: compiler/get-variable-spec name
		opcode: switch/default type/1 [
			byte!	 [#{8805}]						;-- MOV [RIP+disp32], al
			int8!	 [#{8805}]
			uint8!	 [#{8805}]
			int16!	 [#{668905}]					;-- MOV [RIP+disp32], ax
			uint16!	 [#{668905}]
			integer! [#{8905}]						;-- MOV [RIP+disp32], eax
			int32!	 [#{8905}]
			uint32!	 [#{8905}]
			int64!	 [#{488905}]					;-- MOV [RIP+disp32], rax
			uint64!	 [#{488905}]
			pointer! [#{488905}]
			c-string! [#{488905}]
		][
			compiler/throw-error ["x86-64 store type not supported yet:" mold type/1]
		]
		emit-global-ref name opcode
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
	emit-reserve-stack: :unsupported
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
