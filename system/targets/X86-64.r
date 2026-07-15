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
	fpu-cword:			none							;-- MXCSR/control word reference in emitter/symbols
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

	noop: does []
	call-arg-index: 0
	call-arg-types: copy []
	call-stack-slots: 0
	call-pad-slots: 0
	call-extra-slots: 0
	call-shadow-slots: 0
	call-variadic?: no
	call-float-reg-count: 0
	by-value-args: copy []
	call-struct-temp-slots: 0
	saved-last-wide?: no

	win64?: does [
		compiler/job/ABI = 'win64
	]

	patch-floats-definition: func [mode [word!] /local value][
		value: pick [unsigned signed] mode = 'set
		foreach w [float! float64! float32!][
			poke find emitter/datatypes w 3 value
		]
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

	emit-index-sib: func [
		base [word!]
		size [integer!]
		/local scale base-code
	][
		scale: select [1 0 2 64 4 128 8 192] size
		unless scale [
			emit #{4869C9}							;-- IMUL rcx, rcx, imm32
			emit to-bin32 size
			scale: 0
		]
		base-code: switch/default base [
			rax [0]
			rdx [2]
		][
			compiler/throw-error ["x86-64 indexed base register not supported yet:" base]
		]
		emit to-bin8 scale + 8 + base-code			;-- SIB: scale, rcx index, base
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
		spec: either block? name [name][all [word? name select emitter/symbols name]]
		if none? spec [
			compiler/throw-error ["unknown variable:" name]
		]
		unless find [global constant] spec/1 [
			compiler/throw-error ["x86-64 variable kind not supported yet:" mold spec/1]
		]
		emit opcode
		emit-reloc-disp32 spec
	]

	import-var?: func [name [word! object! path!] /local spec][
		if object? name [name: compiler/unbox name]
		unless word? name [return false]
		spec: select emitter/symbols name
		all [
			spec
			spec/1 = 'import-var
		]
	]

	emit-import-var-address: func [
		name [word! object!]
		/local spec
	][
		if object? name [name: compiler/unbox name]
		spec: all [word? name select emitter/symbols name]
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
			logic!	 [either into-ecx [#{0FB608}][#{0FB600}]]
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
				logic!	 [#{8808}]
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

	patch-stack-offset: func [name [word! tag!] offset [integer!] /local pos][
		if pos: find/skip emitter/stack name 2 [
			pos/2: offset
		]
	]

	hidden-ret-ptr?: func [fspec [block!] /local ret size][
		to logic! any [
			emitter/struct-ptr? fspec/4
			all [
				win64?
				compiler/external-abi-call? fspec
				ret: select fspec/4 compiler/return-def
				'value = last ret
				size: emitter/struct-size? ret
				not find [1 2 4 8] size
			]
		]
	]
	external-abi?: func [fspec [block!] /local attrs][
		to logic! all [
			attrs: compiler/get-attributes fspec
			any [find attrs 'cdecl find attrs 'stdcall]
		]
	]
	sysv-merge-class: func [classes [block!] index [integer!] class [word!] /local old][
		old: pick classes index
		poke classes index case [
			any [old = 'integer class = 'integer] ['integer]
			old = 'no-class [class]
			true [old]
		]
	]
	sysv-mark-class: func [classes [block!] offset [integer!] size [integer!] class [word!] /local first-index last-index][
		if zero? size [exit]
		first-index: (to integer! (offset / stack-width)) + 1
		last-index: (to integer! ((offset + size - 1) / stack-width)) + 1
		for index first-index last-index 1 [
			sysv-merge-class classes index class
		]
	]
	sysv-classify-type: func [type [block!] offset [integer!] classes [block!] /local resolved size class][
		resolved: compiler/resolve-aliased type
		either all [
			'value = last type
			find [struct! union!] resolved/1
		][
			sysv-classify-spec resolved/2 offset classes
		][
			size: emitter/size-of? type
			unless size [size: emitter/size-of? resolved]
			class: either compiler/any-float? resolved ['sse]['integer]
			sysv-mark-class classes offset size class
		]
	]
	sysv-classify-spec: func [spec [block!] base [integer!] classes [block!] /local payload members][
		either compiler/union-spec? spec [
			payload: emitter/union-payload-offset? spec
			if compiler/tagged-union? spec [
				sysv-classify-type spec/2 base classes
			]
			members: compiler/union-members spec
			foreach [name type] members [
				sysv-classify-type type (base + payload) classes
			]
		][
			foreach [name type] spec [
				sysv-classify-type type (base + emitter/member-offset? spec name) classes
			]
		]
	]
	sysv-aggregate-classes: func [type [block!] /local resolved spec size slots classes][
		resolved: compiler/resolve-aliased type
		spec: resolved/2
		size: emitter/struct-size?/direct spec
		if size > 16 [return [memory]]
		slots: round/ceiling size / stack-width
		classes: make block! slots
		insert/dup classes 'no-class slots
		sysv-classify-spec spec 0 classes
		replace/all classes 'no-class 'integer
		classes
	]
	emit-call-stack-cleanup: func [n [integer!] /local slots size pad-slots][
		pad-slots: either n = length? call-arg-types [call-pad-slots][0]
		slots: call-stack-slots + pad-slots + call-extra-slots + call-shadow-slots
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
	emit-normalize-sysv-return: func [fspec [block!] /local ret classes][
		unless all [
			not win64?
			compiler/external-abi-call? fspec
			ret: select fspec/4 compiler/return-def
			'value = last ret
			not emitter/struct-ptr? fspec/4
		][exit]
		classes: sysv-aggregate-classes ret
		case [
			classes = [sse] [
				emit #{66480F7EC0}				;-- MOVQ rax, xmm0
			]
			classes = [integer sse] [
				emit #{66480F7EC2}				;-- MOVQ rdx, xmm0
			]
			classes = [sse integer] [
				emit #{4889C2}					;-- MOV rdx, rax
				emit #{66480F7EC0}				;-- MOVQ rax, xmm0
			]
			classes = [sse sse] [
				emit #{66480F7EC0}				;-- MOVQ rax, xmm0
				emit #{66480F7ECA}				;-- MOVQ rdx, xmm1
			]
			true []
		]
	]
	emit-align-call-stack: func [/local live-slots source-offset target-offset][
		live-slots: call-stack-slots + call-extra-slots + call-shadow-slots
		call-pad-slots: either odd? live-slots [1][0]
		if positive? call-pad-slots [
			emit-reserve-stack call-pad-slots
			repeat index call-stack-slots [
				target-offset: (index - 1) * stack-width
				source-offset: target-offset + stack-width
				emit-rsp-ref #{488B4424} #{488B8424} source-offset	;-- MOV rax, [rsp+source]
				emit-rsp-ref #{48894424} #{48898424} target-offset	;-- MOV [rsp+target], rax
			]
		]
	]
	emit-reserve-call-struct-temps: func [slots [integer!]][
		emit-reserve-stack slots
		call-extra-slots: call-extra-slots + slots
		call-struct-temp-slots: slots
	]
	emit-rsp-ref: func [
		disp8-opcode [binary!]
		disp32-opcode [binary!]
		offset [integer!]
	][
		either offset <= 127 [
			emit disp8-opcode
			emit to-bin8 offset
		][
			emit disp32-opcode
			emit to-bin32 offset
		]
	]

	emit-call-register-loads: func [
		n [integer!]
		/local types int-reg float-reg stack-offset stack-write-offset type slot
			force-stack? aggregate-stack?
	][
		types: either zero? n [
			copy []
		][
			reverse copy/part skip tail call-arg-types negate n n
		]
		int-reg: 0
		float-reg: 0
		stack-offset: 0
		stack-write-offset: 0
		call-stack-slots: 0
		call-shadow-slots: 0
		slot: 0
		either win64? [
			foreach type types [
				slot: slot + 1
				either slot <= 4 [
					either compiler/any-float? type [
						either positive? stack-offset [
							emit either type/1 = 'float32! [#{F30F10}][#{F20F10}]
							emit-rsp-ref
								pick [#{4424} #{4C24} #{5424} #{5C24}] slot
								pick [#{8424} #{8C24} #{9424} #{9C24}] slot
								stack-offset
							if call-variadic? [
								emit-rsp-ref
									pick [#{488B4C24} #{488B5424} #{4C8B4424} #{4C8B4C24}] slot
									pick [#{488B8C24} #{488B9424} #{4C8B8424} #{4C8B8C24}] slot
									stack-offset
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
							emit-rsp-ref
								pick [
									#{488B4C24}	;-- MOV rcx, [rsp+disp8]
									#{488B5424}	;-- MOV rdx, [rsp+disp8]
									#{4C8B4424}	;-- MOV r8,  [rsp+disp8]
									#{4C8B4C24}	;-- MOV r9,  [rsp+disp8]
								] slot
								pick [
									#{488B8C24}	;-- MOV rcx, [rsp+disp32]
									#{488B9424}	;-- MOV rdx, [rsp+disp32]
									#{4C8B8424}	;-- MOV r8,  [rsp+disp32]
									#{4C8B8C24}	;-- MOV r9,  [rsp+disp32]
								] slot
								stack-offset
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
						emit-rsp-ref #{488B4424} #{488B8424} stack-offset		;-- MOV rax, [rsp+disp]
						emit-rsp-ref #{48894424} #{48898424} stack-write-offset	;-- MOV [rsp+disp], rax
					]
					stack-offset: stack-offset + stack-width
					stack-write-offset: stack-write-offset + stack-width
				]
			]
			call-shadow-slots: 4
		][
			foreach type types [
				force-stack?: no
				if 2 <= length? type [
					case [
						type/2 = 'sysv-memory [force-stack?: yes]
						type/2 = 'sysv-aggregate [
							if type/6 = 1 [
								aggregate-stack?: any [
									(int-reg + type/4) > 6
									(float-reg + type/5) > 8
								]
							]
							force-stack?: aggregate-stack?
						]
						true []
					]
				]
				either force-stack? [
					if stack-write-offset <> stack-offset [
						emit-rsp-ref #{488B4424} #{488B8424} stack-offset		;-- MOV rax, [rsp+disp]
						emit-rsp-ref #{48894424} #{48898424} stack-write-offset	;-- MOV [rsp+disp], rax
					]
					stack-offset: stack-offset + stack-width
					stack-write-offset: stack-write-offset + stack-width
				][either compiler/any-float? type [
					either float-reg < 8 [
						either positive? stack-offset [
							emit either type/1 = 'float32! [#{F30F10}][#{F20F10}]
							emit-rsp-ref
								pick [#{4424} #{4C24} #{5424} #{5C24} #{6424} #{6C24} #{7424} #{7C24}] float-reg + 1
								pick [#{8424} #{8C24} #{9424} #{9C24} #{A424} #{AC24} #{B424} #{BC24}] float-reg + 1
								stack-offset
							stack-offset: stack-offset + stack-width
						][
							emit either type/1 = 'float32! [#{F30F10}][#{F20F10}]
							emit pick [#{0424} #{0C24} #{1424} #{1C24} #{2424} #{2C24} #{3424} #{3C24}] float-reg + 1
							emit #{4883C408}			;-- ADD rsp, 8
						]
						float-reg: float-reg + 1
					][
						if stack-write-offset <> stack-offset [
							emit-rsp-ref #{488B4424} #{488B8424} stack-offset		;-- MOV rax, [rsp+disp]
							emit-rsp-ref #{48894424} #{48898424} stack-write-offset	;-- MOV [rsp+disp], rax
						]
						stack-offset: stack-offset + stack-width
						stack-write-offset: stack-write-offset + stack-width
					]
				][
					either int-reg < 6 [
						either positive? stack-offset [
							emit-rsp-ref
								pick [
									#{488B7C24}	;-- MOV rdi, [rsp+disp8]
									#{488B7424}	;-- MOV rsi, [rsp+disp8]
									#{488B5424}	;-- MOV rdx, [rsp+disp8]
									#{488B4C24}	;-- MOV rcx, [rsp+disp8]
									#{4C8B4424}	;-- MOV r8,  [rsp+disp8]
									#{4C8B4C24}	;-- MOV r9,  [rsp+disp8]
								] int-reg + 1
								pick [
									#{488BBC24}	;-- MOV rdi, [rsp+disp32]
									#{488BB424}	;-- MOV rsi, [rsp+disp32]
									#{488B9424}	;-- MOV rdx, [rsp+disp32]
									#{488B8C24}	;-- MOV rcx, [rsp+disp32]
									#{4C8B8424}	;-- MOV r8,  [rsp+disp32]
									#{4C8B8C24}	;-- MOV r9,  [rsp+disp32]
								] int-reg + 1
								stack-offset
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
							emit-rsp-ref #{488B4424} #{488B8424} stack-offset		;-- MOV rax, [rsp+disp]
							emit-rsp-ref #{48894424} #{48898424} stack-write-offset	;-- MOV [rsp+disp], rax
						]
						stack-offset: stack-offset + stack-width
						stack-write-offset: stack-write-offset + stack-width
					]
				]]
			]
		]
		call-stack-slots: stack-offset / stack-width
		call-float-reg-count: float-reg
	]

	emit-load-win64-arg-slot: func [index [integer!] /local src-offset][
		either index <= 4 [
			emit pick [
				#{4889C8}		;-- MOV rax, rcx
				#{4889D0}		;-- MOV rax, rdx
				#{4C89C0}		;-- MOV rax, r8
				#{4C89C8}		;-- MOV rax, r9
			] index
		][
			src-offset: 16 + ((index - 1) * stack-width)
			emit-rbp-ref src-offset #{488B45}		;-- MOV rax, [rbp+disp]
		]
	]
	emit-copy-rax-to-r11: func [size [integer!] /local qwords remainder offset][
		qwords: to integer! (size / stack-width)
		remainder: size // stack-width
		repeat index qwords [
			offset: (index - 1) * stack-width
			case [
				zero? offset [emit #{4C8B10}]				;-- MOV r10, [rax]
				offset <= 127 [emit #{4C8B50} emit to-bin8 offset]
				true [emit #{4C8B90} emit to-bin32 offset]
			]
			case [
				zero? offset [emit #{4D8913}]				;-- MOV [r11], r10
				offset <= 127 [emit #{4D8953} emit to-bin8 offset]
				true [emit #{4D8993} emit to-bin32 offset]
			]
		]
		offset: qwords * stack-width
		if remainder >= 4 [
			case [
				zero? offset [emit #{448B10}]
				offset <= 127 [emit #{448B50} emit to-bin8 offset]
				true [emit #{448B90} emit to-bin32 offset]
			]
			case [
				zero? offset [emit #{458913}]
				offset <= 127 [emit #{458953} emit to-bin8 offset]
				true [emit #{458993} emit to-bin32 offset]
			]
			offset: offset + 4
			remainder: remainder - 4
		]
		if remainder >= 2 [
			case [
				zero? offset [emit #{66448B10}]
				offset <= 127 [emit #{66448B50} emit to-bin8 offset]
				true [emit #{66448B90} emit to-bin32 offset]
			]
			case [
				zero? offset [emit #{66458913}]
				offset <= 127 [emit #{66458953} emit to-bin8 offset]
				true [emit #{66458993} emit to-bin32 offset]
			]
			offset: offset + 2
			remainder: remainder - 2
		]
		if remainder = 1 [
			case [
				zero? offset [emit #{448A10}]
				offset <= 127 [emit #{448A50} emit to-bin8 offset]
				true [emit #{448A90} emit to-bin32 offset]
			]
			case [
				zero? offset [emit #{458813}]
				offset <= 127 [emit #{458853} emit to-bin8 offset]
				true [emit #{458893} emit to-bin32 offset]
			]
		]
	]
	emit-copy-rbp-slots: func [source [integer!] target [integer!] slots [integer!] /local part][
		repeat index slots [
			part: (index - 1) * stack-width
			emit-rbp-ref (source + part) #{4C8B55}	;-- MOV r10, [rbp+source]
			emit-rbp-ref (target + part) #{4C8955}	;-- MOV [rbp+target], r10
		]
	]
	emit-store-sysv-float-arg: func [index [integer!] offset [integer!]][
		emit #{F20F11}							;-- MOVSD [rbp+disp], xmmN
		either all [offset >= -128 offset <= 127] [
			emit pick [#{45} #{4D} #{55} #{5D} #{65} #{6D} #{75} #{7D}] index
			emit to-bin8 offset
		][
			emit pick [#{85} #{8D} #{95} #{9D} #{A5} #{AD} #{B5} #{BD}] index
			emit to-bin32 offset
		]
	]

	emit-arg-spills: func [
		locals [block!]
		/local regs offset name type count stack-offset int-count float-count stack-count
			slot ret-ptr? agg-slots agg-size base external? classes class int-needed
			float-needed aggregate-stack?
	][
		clear by-value-args
		regs: [
			#{57}		;-- PUSH rdi
			#{56}		;-- PUSH rsi
			#{52}		;-- PUSH rdx
			#{51}		;-- PUSH rcx
			#{4150}		;-- PUSH r8
			#{4151}		;-- PUSH r9
		]
		offset: -4 * stack-width
		count: 0
		int-count: 0
		float-count: 0
		stack-count: 0
		external?: external-abi? locals
		ret-ptr?: to logic! emitter/struct-ptr? locals
		if ret-ptr? [
			offset: offset - stack-width
			either win64? [
				emit #{51}							;-- PUSH rcx
				patch-stack-offset <ret-ptr> offset
				count: 1
			][
				emit #{57}							;-- PUSH rdi
				patch-stack-offset <ret-ptr> offset
				int-count: 1
			]
		]
		parse locals [
			opt block!
			any [
				set name word! set type block! (
					agg-slots: none
					agg-size: none
					if 'value = last type [
						append by-value-args name
						agg-slots: emitter/struct-slots? type
						agg-size: emitter/struct-size? type
					]
					either win64? [
						either all [
							external?
							agg-slots
							not find [1 2 4 8] agg-size
						][
							count: count + 1
							emit-load-win64-arg-slot count
							base: offset - (agg-slots * stack-width)
							emit-reserve-stack agg-slots
							emit-rbp-ref base #{4C8D5D}	;-- LEA r11, [rbp+base]
							emit-copy-rax-to-r11 agg-size
							patch-stack-offset name base
							offset: base
						][either all [agg-slots agg-slots > 1] [
							base: offset - (agg-slots * stack-width)
							emit-reserve-stack agg-slots
							repeat i agg-slots [
								count: count + 1
								emit-store-arg-slot count base + ((i - 1) * stack-width)
							]
							patch-stack-offset name base
							offset: base
						][
							count: count + 1
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
								offset: offset - stack-width
								emit-reserve-stack 1
								emit-rbp-ref stack-offset #{488B45}	;-- MOV rax, [rbp+disp]
								emit-rbp-ref offset #{488945}		;-- MOV [rbp+disp], rax
								patch-stack-offset name offset
							]
						]]
					][
						either all [external? agg-slots] [
							classes: sysv-aggregate-classes type
							int-needed: 0
							float-needed: 0
							unless classes/1 = 'memory [
								foreach class classes [
									either class = 'sse [
										float-needed: float-needed + 1
									][
										int-needed: int-needed + 1
									]
								]
							]
							aggregate-stack?: any [
								classes/1 = 'memory
								(int-count + int-needed) > 6
								(float-count + float-needed) > 8
							]
							base: offset - (agg-slots * stack-width)
							emit-reserve-stack agg-slots
							either aggregate-stack? [
								stack-offset: 16 + (stack-count * stack-width)
								emit-copy-rbp-slots stack-offset base agg-slots
								stack-count: stack-count + agg-slots
							][
								index: 0
								foreach class classes [
									either class = 'sse [
										float-count: float-count + 1
										emit-store-sysv-float-arg float-count base + (index * stack-width)
									][
										int-count: int-count + 1
										emit-store-arg-slot int-count base + (index * stack-width)
									]
									index: index + 1
								]
							]
							patch-stack-offset name base
							offset: base
						][either all [agg-slots agg-slots > 1] [
							base: offset - (agg-slots * stack-width)
							emit-reserve-stack agg-slots
							repeat i agg-slots [
								either int-count < length? regs [
									int-count: int-count + 1
									emit-store-arg-slot int-count base + ((i - 1) * stack-width)
								][
									stack-offset: 16 + (stack-count * stack-width)
									emit-rbp-ref stack-offset #{488B45}	;-- MOV rax, [rbp+disp]
									emit-rbp-ref base + ((i - 1) * stack-width) #{488945} ;-- MOV [rbp+disp], rax
									stack-count: stack-count + 1
								]
							]
							patch-stack-offset name base
							offset: base
						][either compiler/any-float? type [
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
								offset: offset - stack-width
								emit-reserve-stack 1
								emit-rbp-ref stack-offset #{488B45}	;-- MOV rax, [rbp+disp]
								emit-rbp-ref offset #{488945}		;-- MOV [rbp+disp], rax
								patch-stack-offset name offset
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
								offset: offset - stack-width
								emit-reserve-stack 1
								emit-rbp-ref stack-offset #{488B45}	;-- MOV rax, [rbp+disp]
								emit-rbp-ref offset #{488945}		;-- MOV [rbp+disp], rax
								patch-stack-offset name offset
								stack-count: stack-count + 1
							]
						]]]
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
	register-argument-count?: func [locals [block!] /local count name type ret-ptr? agg-slots][
		count: 0
		ret-ptr?: to logic! emitter/struct-ptr? locals
		if ret-ptr? [count: 1]
		parse locals [
			opt block!
			any [
				set name word! set type block! (
					agg-slots: either 'value = last type [emitter/struct-slots? type][1]
					count: count + agg-slots
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
	emit-rbp-ref: func [
		offset [integer!]
		opcode [binary!]
		/local wide-op
	][
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
	emit-store-arg-slot: func [
		index [integer!]
		offset [integer!]
		/local src-offset
	][
		either win64? [
			either index <= 4 [
				emit-rbp-ref offset pick [
					#{48894D}						;-- MOV [rbp+disp], rcx
					#{488955}						;-- MOV [rbp+disp], rdx
					#{4C8945}						;-- MOV [rbp+disp], r8
					#{4C894D}						;-- MOV [rbp+disp], r9
				] index
			][
				src-offset: 16 + ((index - 1) * stack-width)
				emit-rbp-ref src-offset #{488B45}	;-- MOV rax, [rbp+disp]
				emit-rbp-ref offset #{488945}		;-- MOV [rbp+disp], rax
			]
		][
			either index <= 6 [
				emit-rbp-ref offset pick [
					#{48897D}						;-- MOV [rbp+disp], rdi
					#{488975}						;-- MOV [rbp+disp], rsi
					#{488955}						;-- MOV [rbp+disp], rdx
					#{48894D}						;-- MOV [rbp+disp], rcx
					#{4C8945}						;-- MOV [rbp+disp], r8
					#{4C894D}						;-- MOV [rbp+disp], r9
				] index
			][
				src-offset: 16 + ((index - 6) * stack-width)
				emit-rbp-ref src-offset #{488B45}	;-- MOV rax, [rbp+disp]
				emit-rbp-ref offset #{488945}		;-- MOV [rbp+disp], rax
			]
		]
	]

	emit-load-ecx: func [value /local type][
		case [
			value = <last> [
				type: compiler/resolve-aliased compiler/last-type
				emit either find [pointer! c-string! function! subroutine! struct! union! int64! uint64!] type/1 [
					#{4889C1}						;-- MOV rcx, rax
				][
					#{89C1}							;-- MOV ecx, eax
				]
			]
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
			decimal? value [
				emit #{50}							;-- PUSH rax
				emit-load value
				emit #{F20F2CC8}					;-- CVTTSD2SI ecx, xmm0
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
			get-word? value [
				emit #{50}							;-- PUSH rax
				emit-load value
				emit #{4889C1}						;-- MOV rcx, rax
				emit #{58}							;-- POP rax
			]
			word? value [
				type: compiler/get-type value
				unless block? type [
					value: compiler/resolve-ns value
					type: compiler/get-type value
				]
				unless block? type [
					compiler/throw-error ["x86-64 secondary operand has no type:" mold value]
				]
				type: compiler/resolve-aliased type
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
					logic! [
						either emitter/local-offset? value [
							emit-local-ref value #{0FB64D}
						][
							emit-global-ref value #{0FB60D}
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
					c-string! [
						either emitter/local-offset? value [
							emit-local-ref value #{488B4D}
						][
							emit-global-ref value #{488B0D}
						]
					]
					function! [
						either emitter/local-offset? value [
							emit-local-ref value #{488B4D}
						][
							emit-global-ref value #{488B0D}
						]
					]
					subroutine! [
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
					float! [
						emit #{50}					;-- PUSH rax
						emit-load value
						emit #{F20F2CC8}			;-- CVTTSD2SI ecx, xmm0
						emit #{58}					;-- POP rax
					]
					float64! [
						emit #{50}					;-- PUSH rax
						emit-load value
						emit #{F20F2CC8}			;-- CVTTSD2SI ecx, xmm0
						emit #{58}					;-- POP rax
					]
					float32! [
						emit #{50}					;-- PUSH rax
						emit-load value
						emit #{F30F2CC8}			;-- CVTTSS2SI ecx, xmm0
						emit #{58}					;-- POP rax
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
		patch-floats-definition 'set
		if runtime? [
			fpu-cword: emitter/store-value none 40704 [integer!]
		]
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
	on-finalize: does [
		patch-floats-definition 'unset
	]
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
	patch-sub-call: func [buffer [binary!] ptr [integer!] offset [integer!]][
		change/part at buffer ptr to-bin32 negate offset + 5 - 1 4
	]
	emit-sysv-aggregate-return: func [classes [block!]][
		case [
			classes = [integer] [
				emit #{488B00}						;-- MOV rax, [rax]
			]
			classes = [sse] [
				emit #{F20F1000}					;-- MOVSD xmm0, [rax]
			]
			classes = [integer integer] [
				emit #{488B5008}					;-- MOV rdx, [rax+8]
				emit #{488B00}						;-- MOV rax, [rax]
			]
			classes = [integer sse] [
				emit #{F20F104008}				;-- MOVSD xmm0, [rax+8]
				emit #{488B00}						;-- MOV rax, [rax]
			]
			classes = [sse integer] [
				emit #{F20F1000}					;-- MOVSD xmm0, [rax]
				emit #{488B4008}					;-- MOV rax, [rax+8]
			]
			classes = [sse sse] [
				emit #{F20F1000}					;-- MOVSD xmm0, [rax]
				emit #{F20F104808}				;-- MOVSD xmm1, [rax+8]
			]
			true [compiler/throw-error ["unsupported SysV aggregate return classes:" mold classes]]
		]
	]
	emit-hidden-return-copy: func [vars [block!] size [integer!]][
		unless tag? vars/1 [
			compiler/throw-error "Function has no aggregate return pointer"
		]
		emit-rbp-ref vars/2 #{4C8B5D}			;-- MOV r11, [rbp+ret-ptr]
		emit-copy-rax-to-r11 size
		emit #{4C89D8}							;-- MOV rax, r11
	]
	emit-prolog: func [name [word!] locals [block!] bitmap [integer!] /local locals-size reg-count local-slots][
		reg-count: register-argument-count? locals
		locals-offset: 4 * stack-width + (reg-count * stack-width)
		locals-size: either find locals /local [
			emitter/calc-locals-offsets find locals /local
		][0]
		emit #{55}									;-- PUSH rbp
		emit #{4889E5}								;-- MOV rbp, rsp
		emit #{6A00}								;-- PUSH 0		; catch ID
		emit #{6A00}								;-- PUSH 0		; catch resume address
		emit-push bitmap							;-- args/locals bitmap offset
		emit #{6A00}								;-- last known parent Red frame
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
		/local vars ret-ptr? ret ret-size sysv-classes
	][
		if slots [
			ret-ptr?: to logic! emitter/struct-ptr? locals
			ret: select locals compiler/return-def
			ret-size: emitter/struct-size? ret
			either all [
				not win64?
				external-abi? locals
				not ret-ptr?
			][
				sysv-classes: sysv-aggregate-classes ret
				emit-sysv-aggregate-return sysv-classes
			][either ret-ptr? [
				vars: emitter/stack
				emit-hidden-return-copy vars ret-size
			][
				case [
					slots = 1 [
						emit #{488B00}				;-- MOV rax, [rax]
					]
					slots = 2 [
						emit #{488B5008}			;-- MOV rdx, [rax+8]
						emit #{488B00}				;-- MOV rax, [rax]
					]
					true [
						vars: emitter/stack
						emit-hidden-return-copy vars ret-size
					]
				]
			]]
		]
		if closing [emit-load 0]
		emit #{C9}									;-- LEAVE
		emit #{C3}									;-- RET
	]
	emit-stack-align-prolog: func [args [block!] fspec [block!]][
		if compiler/job/stack-align-16? [
			emit #{4889E0}							;-- MOV rax, rsp
			emit #{4883E4F0}						;-- AND rsp, -16
			emit #{4883EC10}						;-- SUB rsp, 16
			emit #{4889442408}						;-- MOV [rsp+8], rax
		]
	]
	emit-stack-align-epilog: func [args [block!]][
		if compiler/job/stack-align-16? [
			emit #{488B642408}						;-- MOV rsp, [rsp+8]
		]
	]
	emit-stack-align: :noop
	emit-float-trash-last: :noop
	emit-casting: func [
		value [object!]
		alt? [logic!]
		/push
		/local type to-width
	][
		type: compiler/get-type value/data
		case [
			value/type/1 = 'logic! [
				emit case [
					any [compiler/int64? type compiler/any-pointer? type] [#{4885C0}]
					all [compiler/integer-type? type (compiler/integer-width? type) = 1] [#{84C0}]
					all [compiler/integer-type? type (compiler/integer-width? type) = 2] [#{6685C0}]
					true [#{85C0}]
				]
				emit #{0F95C0}						;-- SETNZ al
				emit #{0FB6C0}						;-- MOVZX eax, al
			]
			all [
				compiler/any-pointer? value/type
				compiler/signed-integer? type
				not compiler/int64? type
			][
				emit #{4863C0}						;-- MOVSXD rax, eax
			]
			all [
				compiler/integer-type? value/type
				compiler/integer-type? type
			][
				to-width: compiler/integer-width? value/type
				if to-width < 4 [
					emit case [
						to-width = 1 [
							either compiler/signed-integer? value/type [#{0FBEC0}][#{0FB6C0}]
						]
						true [
							either compiler/signed-integer? value/type [#{0FBFC0}][#{0FB7C0}]
						]
					]
				]
				if all [
					value/type/1 = 'int64!
					compiler/signed-integer? type
					not compiler/int64? type
				][
					emit #{4863C0}					;-- MOVSXD rax, eax
				]
			]
			all [
				find [float! float32! float64!] value/type/1
				compiler/integer-type? type
			][
				either all [value/keep? value/type/1 = 'float32! type/1 = 'integer!][
					emit #{C5F96EC0}				;-- VMOVD xmm0, eax
				][
					emit either compiler/int64? type [
						either value/type/1 = 'float32! [#{C4E1FA2AC0}][#{C4E1FB2AC0}]
					][
						either value/type/1 = 'float32! [#{C5FA2AC0}][#{C5FB2AC0}]
					]
				]
			]
			all [
				compiler/integer-type? value/type
				find [float! float32! float64!] type/1
			][
				either all [value/keep? value/type/1 = 'integer! type/1 = 'float32!][
					emit #{C5F97EC0}				;-- VMOVD eax, xmm0
				][
					emit either compiler/int64? value/type [
						either type/1 = 'float32! [#{C4E1FA2CC0}][#{C4E1FB2CC0}]
					][
						either type/1 = 'float32! [#{C5FA2CC0}][#{C5FB2CC0}]
					]
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
		call-struct-temp-slots: 0
	]
	emit-variadic-data: func [args [block!] /local total data-slots byte-size][
		either args/1 = #typed [
			total: (length? args/2) / 3
			data-slots: total * 3
			emit #{4889E0}							;-- MOV rax, rsp
			emit #{50}								;-- PUSH rax, typed-value list pointer
			emit-push total							;-- typed-value count
			call-extra-slots: data-slots
			call-arg-index: 2
			clear call-arg-types
			append/only call-arg-types [integer!]
			append/only call-arg-types [pointer! [integer!]]
		][
			total: length? args/2
			byte-size: total * stack-width
			emit-push byte-size						;-- arguments total size in bytes
			emit #{488D442408}						;-- LEA rax, [rsp+8], skip byte-size slot
			emit #{50}								;-- PUSH rax, argument list pointer
			emit-push total							;-- argument count
			call-extra-slots: (call-arguments-size? args/2) / stack-width
			call-arg-index: 3
			clear call-arg-types
			append/only call-arg-types [integer!]
			append/only call-arg-types [pointer! [integer!]]
			append/only call-arg-types [integer!]
		]
	]
	emit-call-import: func [
		args [block!]
		fspec [block!]
		spec [block!]
		attribs [block! none!]
		/local n
	][
		call-variadic?: to logic! compiler/find-attribute fspec/4 'variadic
		if all [compiler/variadic? args/1 fspec/3 <> 'cdecl][emit-variadic-data args]
		n: length? call-arg-types
		emit-call-register-loads n
		emit-align-call-stack
		if win64? [emit-reserve-stack 4]
		if all [not win64? compiler/find-attribute fspec/4 'variadic] [
			emit #{B0}								;-- MOV al, imm8 (SysV variadic FP register count)
			emit to-bin8 call-float-reg-count
		]
		emit either win64? [#{FF15}][#{E8}]			;-- CALL [rip+disp32] / rel32
		emit-reloc-disp32 spec
		emit-normalize-sysv-return fspec
		emit-call-stack-cleanup n
		call-arg-index: max 0 call-arg-index - n
		remove/part skip tail call-arg-types negate n n
		call-stack-slots: 0
		call-pad-slots: 0
		call-extra-slots: 0
		call-shadow-slots: 0
		call-variadic?: no
		call-float-reg-count: 0
		call-struct-temp-slots: 0
	]
	emit-call-native: func [
		args [block!] fspec [block!] spec [block!] attribs [block! none!]
		/routine name [word!]
		/local n target
	][
		if all [compiler/variadic? args/1 fspec/3 <> 'cdecl][emit-variadic-data args]
		n: length? call-arg-types
		emit-call-register-loads n
		emit-align-call-stack
		if win64? [emit-reserve-stack 4]
		either routine [
			target: either all [2 <= length? fspec 'local = last fspec][
				pick tail fspec -2
			][
				name
			]
			either find form target slash [
				emitter/access-path target none
			][
				either emitter/local-offset? target [
					emit-local-ref target #{488B45}	;-- MOV rax, [rbp+disp]
				][
					emit-global-ref target #{488B05}	;-- MOV rax, [RIP+disp32]
				]
			]
			emit #{FFD0}								;-- CALL rax
		][
			emit #{E8}								;-- CALL rel32
			emit-reloc-disp32 spec
		]
		emit-normalize-sysv-return fspec
		emit-call-stack-cleanup n
		call-arg-index: max 0 call-arg-index - n
		remove/part skip tail call-arg-types negate n n
		call-stack-slots: 0
		call-pad-slots: 0
		call-extra-slots: 0
		call-shadow-slots: 0
		call-variadic?: no
		call-float-reg-count: 0
		call-struct-temp-slots: 0
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
		type: any [all [boxed boxed/type] compiler/last-type]
		if block? type [
			switch type/1 [
				byte!  [emit #{0FB6C0}]				;-- MOVZX eax, al
				int8!  [emit #{0FBEC0}]				;-- MOVSX eax, al
				uint8! [emit #{0FB6C0}]				;-- MOVZX eax, al
				int16! [emit #{0FBFC0}]				;-- MOVSX eax, ax
				uint16! [emit #{0FB7C0}]				;-- MOVZX eax, ax
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
		/local right right-source imm? type wide? right-block? right-last? right-type scale right-loaded? right-signed? left-type mod? signed-op? ptr-wide-imm? cast-width cast-mask cast-sign
	][
		type: compiler/resolve-aliased compiler/resolve-expr-type args/1
		if all [object? args/1 logic? args/1/keep?] [compiler/cast args/1]
		set-width/type type/1
		right: either all [object? args/2 logic? args/2/keep?] [
			compiler/cast args/2
		][
			compiler/unbox args/2
		]
		right-block?: block? right
		right-last?: right = <last>
		right-loaded?: no
		right-signed?: no
		if any [right-block? right-last?] [
			right-type: compiler/resolve-expr-type args/2
			right-signed?: compiler/signed-integer? right-type
			right-loaded?: yes
		]
		if char? right [right: to integer! right]
		if logic? right [right: to integer! right]
		right-source: either object? args/2 [args/2][right]
		imm?: all [not right-block? integer? right]
		if all [
			imm?
			object? args/2
			compiler/integer-type? args/2/type
			(cast-width: compiler/integer-width? args/2/type) < 4
		][
			cast-mask: either cast-width = 1 [255][65535]
			right: right and cast-mask
			if compiler/signed-integer? args/2/type [
				cast-sign: either cast-width = 1 [128][32768]
				if right >= cast-sign [right: right - (cast-mask + 1)]
			]
		]
		if not imm? [
			right-signed?: compiler/signed-integer? compiler/resolve-expr-type args/2
		]
		signed?: compiler/signed-integer? type
		wide?: find [pointer! c-string! function! subroutine! struct! union! any-pointer! int64! uint64!] type/1
		ptr-wide-imm?: find [pointer! c-string! function! subroutine! struct! union! any-pointer!] type/1
		if all [any [right-block? right-last?] not last-saved?][
			emit either wide? [#{4889C1}][#{89C1}] ;-- MOV rcx/ecx, rax/eax
		]
		last-saved?: no
		emit-load args/1
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
					unless right-loaded? [emit-load-ecx right-source]
					if right-signed? [emit #{4863C9}]	;-- MOVSXD rcx, ecx
					emit #{4869C9}					;-- IMUL rcx, rcx, imm32
					emit to-bin32 scale
					right-loaded?: yes
				]
			]
		]
		if all [
			right-signed?
			not imm?
			not right-block?
			find [+ -] name
			find [pointer! c-string! struct! union! any-pointer!] type/1
		][
			unless right-loaded? [emit-load-ecx right-source]
			emit #{4863C9}							;-- MOVSXD rcx, ecx
			right-loaded?: yes
		]
		mod?: select mod-rem-func name
		if any [name = divide-sym mod?] [
			unless right-block? [emit-load-ecx right-source]
			signed-op?: compiler/signed-integer? type
			either signed-op? [
				if all [compiler/overflow-check? width = 4 not wide?][
					emit-overflow-check-division
				]
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
		if all [name = '-** find [int8! int16!] type/1][
			emit switch type/1 [
				int8!  [#{25FF000000}]				;-- AND eax, FFh
				int16! [#{25FFFF0000}]				;-- AND eax, FFFFh
			]
		]
		if all [
			compiler/overflow-check?
			name = first [<<]
			imm?
			find [1 2 4] width
		][
			emit-overflow-check-shift right
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
						either all [wide? ptr-wide-imm? integer? right negative? right][
							emit-load-ecx right-source
							emit #{4839C8}			;-- CMP rax, rcx
						][
							emit either wide? [#{483D}][#{3D}] ;-- CMP rax/eax, imm32
							emit to-bin32 right
						]
					]
					][
						unless right-loaded? [emit-load-ecx right-source]
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
					>>	[either wide? [emit #{48}][] emit either signed? [#{C1F8}][#{C1E8}] emit to-bin8 right] ;-- SAR|SHR rax/eax, imm8
					-**	[either wide? [emit #{48}][] emit #{C1E8} emit to-bin8 right]	;-- SHR rax/eax, imm8
				][
					compiler/throw-error ["x86-64 integer op not supported yet:" mold name]
				]
			]
			true [
				unless right-loaded? [emit-load-ecx right-source]
				switch/default name [
					+	[emit either wide? [#{4801C8}][#{01C8}]]	;-- ADD rax/eax, rcx/ecx
					-	[emit either wide? [#{4829C8}][#{29C8}]]	;-- SUB rax/eax, rcx/ecx
					*	[emit either wide? [#{480FAFC1}][#{0FAFC1}]] ;-- IMUL rax/eax, rcx/ecx
					and [emit either wide? [#{4821C8}][#{21C8}]]	;-- AND rax/eax, rcx/ecx
					or	[emit either wide? [#{4809C8}][#{09C8}]]	;-- OR rax/eax, rcx/ecx
					xor [emit either wide? [#{4831C8}][#{31C8}]]	;-- XOR rax/eax, rcx/ecx
					<<	[emit either wide? [#{48D3E0}][#{D3E0}]]	;-- SHL rax/eax, cl
					>>	[emit either wide? [
							either signed? [#{48D3F8}][#{48D3E8}]
						][
							either signed? [#{D3F8}][#{D3E8}]
						]]								;-- SAR|SHR rax/eax, cl
					-**	[emit either wide? [#{48D3E8}][#{D3E8}]]	;-- SHR rax/eax, cl
				][
					compiler/throw-error ["x86-64 integer op not supported yet:" mold name]
				]
			]
		]
		if all [compiler/overflow-check? find [+ - *] name not wide?][
			case [
				width = 4 [
					emit-overflow-jcc either any [signed? name = '*][#{00}][#{02}]
				]
				all [not signed? find [1 2] width name = '-][
					emit-overflow-jcc #{02}			;-- JC: unsigned underflow
				]
				all [not signed? find [1 2] width][
					emit #{3D}						;-- CMP eax, maximum value
					emit to-bin32 either width = 1 [255][65535]
					emit-overflow-jcc #{07}			;-- JA
				]
				all [signed? find [1 2] width][
					emit #{3D}
					emit to-bin32 either width = 1 [127][32767]
					emit-overflow-jcc #{0F}			;-- JG
					emit #{3D}
					emit to-bin32 either width = 1 [-128][-32768]
					emit-overflow-jcc #{0C}			;-- JL
				]
			]
		]
		if not find comparison-op name [
			switch type/1 [
				byte!  [emit #{0FB6C0}]				;-- MOVZX eax, al
				int8!  [emit #{0FBEC0}]				;-- MOVSX eax, al
				uint8! [emit #{0FB6C0}]				;-- MOVZX eax, al
				int16! [emit #{0FBFC0}]				;-- MOVSX eax, ax
				uint16! [emit #{0FB7C0}]				;-- MOVZX eax, ax
			]
		]
		last-math-op: name
	]
	emit-float-operation: func [
		name [word!] args [block!]
		/local type right-type single? store-op cmp-op right-block? left-block? left-last? pre-saved? left-expr left-expr-type load-float-op
	][
		if verbose >= 3 [print [">>>inlining float op:" mold name mold args]]
		type: compiler/resolve-expr-type args/1
		right-type: compiler/resolve-expr-type args/2
		single?: any [type/1 = 'float32! right-type/1 = 'float32!]
		left-expr: compiler/unbox args/1
		left-expr-type: either block? left-expr [compiler/get-type left-expr][none]
		right-block?: block? compiler/unbox args/2
		left-block?: block? left-expr
		left-last?: any [args/1 = <last> left-block?]
		pre-saved?: last-saved?
		store-op: either single? [#{C5FA110424}][#{C5FB110424}]
		cmp-op: either single? [#{C5F82E0424}][#{C5F92E0424}]
		load-float-op: func [arg /local value spec][
			value: compiler/unbox arg
			either all [single? decimal? value][
				spec: emitter/store-value none value [float32!]
				emit-float-ref spec/2 #{C5FA1005}
				compiler/last-type: [float32!]
			][
				emit-load arg
			]
		]
		case [
			find comparison-op name [
				signed?: no								;-- UCOMIS[S/D] uses CF/ZF/PF, not signed integer flags
				either all [left-block? right-block? pre-saved?][
					emit either single? [#{0F2EC1}][#{660F2EC1}] ;-- UCOMIS[S/D] xmm0, xmm1
					last-saved?: no
				][
					if all [
						left-last?
						any [
							compiler/integer-type? compiler/last-type
							all [object? args/1 compiler/integer-type? left-expr-type]
						]
					][
						emit either compiler/int64? any [left-expr-type compiler/last-type] [
							either type/1 = 'float32! [#{C4E1FA2AC0}][#{C4E1FB2AC0}]
						][
							either type/1 = 'float32! [#{C5FA2AC0}][#{C5FB2AC0}]
						]
						compiler/last-type: type
					]
					either left-last? [
						emit #{4883EC10}				;-- SUB rsp, 16
						emit store-op					;-- MOVS[S/D] [rsp], xmm0
						last-saved?: yes
						saved-last-wide?: yes
						load-float-op args/2
						emit either single? [#{F30F10C8}][#{F20F10C8}] ;-- MOVS[S/D] xmm1, xmm0
						emit either single? [#{C5FA100424}][#{C5FB100424}]
						emit #{488D642410}				;-- LEA rsp, [rsp+16] without clobbering flags
						emit either single? [#{0F2EC1}][#{660F2EC1}] ;-- UCOMIS[S/D] xmm0, xmm1
					][
						load-float-op args/2
						emit #{4883EC10}				;-- SUB rsp, 16
						emit store-op					;-- MOVS[S/D] [rsp], xmm0
						last-saved?: yes
						saved-last-wide?: yes
						load-float-op args/1
						emit cmp-op						;-- UCOMIS[S/D] xmm0, [rsp]
						emit #{488D642410}				;-- LEA rsp, [rsp+16] without clobbering flags
					]
					last-saved?: no
				]
			]
			find [+ *] name [
				if all [
					left-last?
					any [
						compiler/integer-type? compiler/last-type
						all [object? args/1 compiler/integer-type? left-expr-type]
					]
				][
					emit either compiler/int64? any [left-expr-type compiler/last-type] [
						either type/1 = 'float32! [#{C4E1FA2AC0}][#{C4E1FB2AC0}]
					][
						either type/1 = 'float32! [#{C5FA2AC0}][#{C5FB2AC0}]
					]
					compiler/last-type: type
				]
				case [
					all [left-block? right-block? pre-saved?][
						emit switch name [
							+ [either single? [#{F30F58C1}][#{F20F58C1}]] ;-- ADD[S/D] xmm0, xmm1
							* [either single? [#{F30F59C1}][#{F20F59C1}]] ;-- MUL[S/D] xmm0, xmm1
						]
						last-saved?: no
					]
					right-block? [
					load-float-op args/2
					emit #{4883EC10}
					emit store-op
					last-saved?: yes
					saved-last-wide?: yes
					load-float-op args/1
					]
					true [
					load-float-op args/1
					emit #{4883EC10}
					emit store-op
					last-saved?: yes
					saved-last-wide?: yes
					load-float-op args/2
					]
				]
				unless all [left-block? right-block? pre-saved?][
					emit switch name [
						+ [either single? [#{C5FA580424}][#{C5FB580424}]] ;-- VADDS[S/D] xmm0, xmm0, [rsp]
						* [either single? [#{C5FA590424}][#{C5FB590424}]] ;-- VMULS[S/D] xmm0, xmm0, [rsp]
					]
					emit #{4883C410}
					last-saved?: no
				]
			]
			find [- /] name [
				if all [
					left-last?
					any [
						compiler/integer-type? compiler/last-type
						all [object? args/1 compiler/integer-type? left-expr-type]
					]
				][
					emit either compiler/int64? any [left-expr-type compiler/last-type] [
						either type/1 = 'float32! [#{C4E1FA2AC0}][#{C4E1FB2AC0}]
					][
						either type/1 = 'float32! [#{C5FA2AC0}][#{C5FB2AC0}]
					]
					compiler/last-type: type
				]
				case [
					all [left-block? right-block? pre-saved?][
						emit switch name [
							- [either single? [#{F30F5CC1}][#{F20F5CC1}]] ;-- SUB[S/D] xmm0, xmm1
							/ [either single? [#{F30F5EC1}][#{F20F5EC1}]] ;-- DIV[S/D] xmm0, xmm1
						]
						last-saved?: no
					]
					left-last? [
					emit #{4883EC10}
					emit store-op
					last-saved?: yes
					saved-last-wide?: yes
					load-float-op args/2
					emit either single? [#{C5FA100C24}][#{C5FB100C24}] ;-- VMOVS[S/D] xmm1, [rsp]
					emit switch name [
						- [either single? [#{C5F25CC0}][#{C5F35CC0}]] ;-- VSUBS[S/D] xmm0, xmm1, xmm0
							/ [either single? [#{C5F25EC0}][#{C5F35EC0}]] ;-- VDIVS[S/D] xmm0, xmm1, xmm0
						]
					]
					true [
					load-float-op args/2
					emit #{4883EC10}
					emit store-op
					last-saved?: yes
					saved-last-wide?: yes
					load-float-op args/1
					emit switch name [
						- [either single? [#{C5FA5C0424}][#{C5FB5C0424}]] ;-- VSUBS[S/D] xmm0, xmm0, [rsp]
							/ [either single? [#{C5FA5E0424}][#{C5FB5E0424}]] ;-- VDIVS[S/D] xmm0, xmm0, [rsp]
						]
					]
				]
				unless all [left-block? right-block? pre-saved?][
					emit #{4883C410}
					last-saved?: no
				]
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
		emit #{483945F8}							;-- CMP [rbp-8], rax
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
	emit-alt-last: :noop
	emit-log-b: func [type][
		if type = 'byte! [emit #{0FB6C0}]			;-- MOVZX eax, al
		emit #{0FBDC0}								;-- BSR eax, eax
		call-arg-index: 0
		clear call-arg-types
		call-stack-slots: 0
		call-pad-slots: 0
		call-extra-slots: 0
		call-shadow-slots: 0
		call-variadic?: no
		call-float-reg-count: 0
		call-struct-temp-slots: 0
	]
	emit-variable: func [name [word! object!]][
		emit-load name
	]
	emit-load-integer: func [value [integer!]][
		switch/default value [
			 0 [emit #{31C0}]						;-- XOR eax, eax
			 1 [emit #{31C0FFC0}]					;-- XOR eax, eax; INC eax
			-1 [either all [width = 8 signed?][emit #{4831C048FFC8}][emit #{31C0FFC8}]]
		][
			either all [
				value >= -2147483648
				value <= 2147483647
				any [width <> 8 not signed? not negative? value]
			][
				emit #{B8}							;-- MOV eax, imm32
				emit to-bin32 value
			][
				emit #{48B8}						;-- MOV rax, imm64
				emit to-bin64 value
			]
		]
	]
	emit-typed-int64-padding: func [fspec [block!] type [block!]][
		if all [
			compiler/find-attribute fspec/4 'typed
			find [int64! uint64!] type/1
		][
			emit #{8B442404}						;-- MOV eax, [rsp+4] ; high half of value
			emit #{89442408}						;-- MOV [rsp+8], eax ; typed-value/_padding
		]
	]
	emit-argument: func [arg fspec [block!] /local value arg-type argc hidden?][
		argc: compiler/get-arity fspec/4
		hidden?: hidden-ret-ptr? fspec
		if hidden? [argc: argc + 1]
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
				call-arg-index >= argc
			]
		][
			call-arg-index: 0
			clear call-arg-types
			call-stack-slots: 0
			call-pad-slots: 0
		]
		call-arg-index: call-arg-index + 1
		if tag? arg [
			append/only call-arg-types [pointer! [byte!]]
			emit-push arg
			exit
		]
		arg-type: compiler/get-type arg
		append/only call-arg-types arg-type
		value: compiler/unbox arg
		if block? value [value: <last>]
		either get-word? value [
			value: to word! value
			either emitter/local-offset? value [
				either 'function! = first compiler/get-type value [
					emit-local-ref value #{488B45}	;-- MOV rax, [rbp+disp8]
				][
					emit-local-ref value #{488D45}	;-- LEA rax, [rbp+disp8]
				]
			][
				either import-var? value [
					emit-import-var-address value
				][
					emit #{488D05}					;-- LEA rax, [RIP+disp32]
					emit-reloc-disp32 emitter/get-symbol-ref value
				]
			]
			compiler/last-type: arg-type
			emit-push <last>
		][
			if object? arg [
				emit-load arg
				compiler/last-type: arg-type
				emit-push <last>
				emit-typed-int64-padding fspec arg-type
				exit
			]
			if compiler/any-float? arg-type [
				emit-load arg
				emit #{4883EC08}				;-- SUB rsp, 8
				emit either arg-type/1 = 'float32! [#{C5FA110424}][#{C5FB110424}]
				exit
			]
			either path? value [
				emit-load value
				compiler/last-type: arg-type
				emit-push <last>
			][
				if value = <last> [
					compiler/last-type: arg-type
					emit-push <last>
					emit-typed-int64-padding fspec arg-type
					exit
				]
				either word? value [
					emit-load value
					compiler/last-type: arg-type
					emit-push <last>
					emit-typed-int64-padding fspec arg-type
				][
					if tag? value [
						emit-push value
						exit
					]
					if string? value [
						emit-load-literal [c-string!] value
						compiler/last-type: arg-type
						emit-push <last>
						exit
					]
					if issue? value [
						emit-load value
						compiler/last-type: arg-type
						emit-push <last>
						emit-typed-int64-padding fspec arg-type
						exit
					]
					if logic? value [value: to integer! value]
					unless any [integer? value char? value][
						compiler/throw-error ["x86-64 literal argument not supported yet:" mold value]
					]
					emit-push value
					emit-typed-int64-padding fspec arg-type
				]
			]
		]
	]
	emit-load: func [value /with cast [object!] /local type spec local-spec resolved-type load-type field][
		if block? value [value: <last>]
		case [
			value = <last> []
			object? value [
				emit-load compiler/unbox value
				emit-casting value no
			]
			any [integer? value char? value logic? value] [
				if logic? value [value: to integer! value]
				either integer? value [
					emit-load-integer value
				][
					emit #{B8}						;-- MOV eax, imm32
					emit to-bin32 value
				]
			]
			issue? value [
				either spec: compiler/int64-literal-info value [
					emit-load-int64-literal value spec/1
				][
					type: either all [with cast/type/1 = 'float32!][[float32!]][[float!]]
					spec: emitter/store-value none value type
					emit-float-ref spec/2 either type/1 = 'float32! [#{C5FA1005}][#{C5FB1005}]
					compiler/last-type: type
				]
			]
			decimal? value [
				type: either all [with cast/type/1 = 'float32!][[float32!]][[float!]]
				spec: emitter/store-value none value type
				emit-float-ref spec/2 either type/1 = 'float32! [#{C5FA1005}][#{C5FB1005}]
				compiler/last-type: type
			]
			string? value [
				emit-load-literal [c-string!] value
			]
			path? value [
				either all [
					2 = length? value
					spec: compiler/resolve-aliased compiler/resolve-type to word! value/1
					find [struct! union!] spec/1
					spec: spec/2
					field: select spec value/2
					block? field
					'value = last field
				][
					emit-init-path value/1
					emit-access-path value spec
				][
					emitter/access-path value none
				]
			]
			paren? value [
				emit-load-literal none value
			]
			get-word? value [
				value: to word! value
				either emitter/local-offset? value [
					either 'function! = first compiler/get-type value [
						emit-local-ref value #{488B45}	;-- MOV rax, [rbp+disp8]
					][
						emit-local-ref value #{488D45}	;-- LEA rax, [rbp+disp8]
					]
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
				load-type: compiler/resolve-aliased type
				either emitter/local-offset? value [
					either all [
						resolved-type: load-type
						find [struct! union!] resolved-type/1
						any [
							find by-value-args value
							'value = last type
							'value = last resolved-type
							all [
								local-spec: select compiler/locals value
								'value = last local-spec
							]
						]
					][
						emit-local-ref value #{488D45}	;-- LEA rax, [rbp+disp8]
					][
					switch/default load-type/1 [
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
					]
				][
					if import-var? value [
						emit-load-import-var value load-type
						exit
					]
					switch/default load-type/1 [
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
	]
	emit-load-literal: func [type [block! none!] value /local spec][
		unless type [type: compiler/get-type value]
		spec: emitter/store-value none value type
		emit-load-literal-ptr spec/2
		compiler/last-type: type
	]
	emit-load-literal-ptr: func [spec [block!]][
		emit #{488D05}								;-- LEA rax, [RIP+disp32]
		emit-reloc-disp32 spec
	]
	emit-init-path: func [name [word! get-word!] /local type resolved-type local-spec][
		if get-word? name [name: to word! name]
		either emitter/local-offset? name [
			type: compiler/get-type name
			resolved-type: compiler/resolve-aliased type
			either all [
				find [struct! union!] resolved-type/1
				any [
					find by-value-args name
					'value = last type
					'value = last resolved-type
					all [
						local-spec: select compiler/locals name
						'value = last local-spec
					]
				]
			][
				emit-local-ref name #{488D45}		;-- LEA rax, [rbp+disp8]
			][
				emit-local-ref name #{488B45}		;-- MOV rax, [rbp+disp8]
			]
		][
			either import-var? name [
				emit-import-var-address name
				type: compiler/get-type name
				resolved-type: compiler/resolve-aliased type
				if find [struct! union!] resolved-type/1 [
					emit #{488B00}						;-- MOV rax, [rax]
				]
			][
				type: compiler/get-type name
				resolved-type: compiler/resolve-aliased type
				either all [
					find [struct! union!] resolved-type/1
					any [
						'value = last type
						'value = last resolved-type
					]
				][
					emit-global-ref name #{488D05}	;-- LEA rax, [RIP+disp32]
				][
					emit-global-ref name #{488B05}	;-- MOV rax, [RIP+disp32]
				]
			]
		]
	]
	emit-store: func [
		name [word!] value
		spec [block! none!]
		/by-value slots [integer!]
		/local type agg-type store-type source-type opcode local?
	][
		if by-value [
			if slots > 2 [exit]
			either offset: emitter/local-offset? name [
				either slots = 1 [
					emit-local-ref name #{488945}		;-- MOV [rbp+disp8], rax
				][
					either all [offset >= -128 offset <= 127][
						emit #{488945}				;-- MOV [rbp+disp8], rax
						emit to-bin8 offset
						emit #{488955}				;-- MOV [rbp+disp8], rdx
						emit to-bin8 offset + 8
					][
						emit #{488985}				;-- MOV [rbp+disp32], rax
						emit to-bin32 offset
						emit #{488995}				;-- MOV [rbp+disp32], rdx
						emit to-bin32 offset + 8
					]
				]
			][
				either slots = 1 [
					emit #{50}						;-- PUSH rax
					emit-init-path name
					emit #{5A}						;-- POP rdx
					emit #{488910}					;-- MOV [rax], rdx
				][
					emit #{50}						;-- PUSH rax
					emit #{52}						;-- PUSH rdx
					emit-init-path name
					emit #{5A}						;-- POP rdx
					emit #{59}						;-- POP rcx
					emit #{488908}					;-- MOV [rax], rcx
					emit #{48895008}				;-- MOV [rax+8], rdx
				]
			]
			exit
		]
		type: compiler/get-variable-spec name
		agg-type: compiler/resolve-aliased type
		store-type: either block? agg-type [agg-type][type]
		if all [binary? value store-type/1 = 'float32!][
			emit #{B8}								;-- MOV eax, imm32
			emit copy/part value 4
			emit #{C5F96EC0}						;-- VMOVD xmm0, eax
		]
		if all [
			block? value
			empty? value
			find [struct! union!] agg-type/1
		][
			exit
		]
		if all [
			find [struct! union!] agg-type/1
			not all [
				object? value
				find [struct! union!] value/type/1
				not empty? value/data
			]
		][
			type: [pointer!]
			store-type: type
		]
		if logic? value [value: to integer! value]
		if all [
			value <> <last>
			find [string! paren! binary!] type?/word value
			compiler/any-pointer? type
		][
			unless all [spec compiler/job/PIC? not emitter/libc-init?][
				either spec [
					emit-load-literal-ptr spec/2
				][
					emit-load value
				]
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
					type/1 = 'int64!
					compiler/signed-integer? source-type
					not compiler/int64? source-type
				][
					emit #{4863C0}					;-- MOVSXD rax, eax
				]
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
			opcode: switch/default store-type/1 [
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
				function! [#{488945}]
				subroutine! [#{488945}]
				float!	 [#{C5FB1145}]			;-- VMOVSD [rbp+disp8], xmm0
				float64! [#{C5FB1145}]
				float32! [#{C5FA1145}]			;-- VMOVSS [rbp+disp8], xmm0
			][
				switch/default type/1 [
					function! [#{488945}]
					subroutine! [#{488945}]
				][
					compiler/throw-error ["x86-64 local store type not supported yet:" mold type/1]
				]
			]
			emit-local-ref name opcode
		][
			if import-var? name [
				emit-store-import-var name store-type
				exit
			]
			opcode: switch/default store-type/1 [
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
				function! [#{488905}]
				subroutine! [#{488905}]
				float!	 [#{C5FB1105}]			;-- VMOVSD [RIP+disp32], xmm0
				float64! [#{C5FB1105}]
				float32! [#{C5FA1105}]			;-- VMOVSS [RIP+disp32], xmm0
			][
				switch/default type/1 [
					function! [#{488905}]
					subroutine! [#{488905}]
				][
					compiler/throw-error ["x86-64 store type not supported yet:" mold type/1]
				]
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
					emit #{4863C9}				;-- MOVSXD rcx, ecx
					emit #{0FB60408}				;-- MOVZX eax, byte [rax+rcx]
				]
				set-width 4
			]
			pointer! [
				spec: either parent [
					compiler/resolve-type/with path/1 parent
				][
					emit-init-path path/1
					compiler/resolve-type to word! path/1
				]
				mtype: spec/2
				set-width/type mtype/1
				size: emitter/size-of? mtype
				signed?: compiler/signed-integer? mtype
				idx: either path/2 = 'value [1][path/2]
				either integer? idx [
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
								emit #{488B00}		;-- MOV rax, [rax]
							][
								emit #{488B80}		;-- MOV rax, [rax+disp32]
								emit to-bin32 offset
							]
						]
						all [size = 4 not compiler/any-float? mtype] [
							either zero? offset [
								emit #{8B00}		;-- MOV eax, [rax]
							][
								emit #{8B80}		;-- MOV eax, [rax+disp32]
								emit to-bin32 offset
							]
						]
						all [size = 2 not compiler/any-float? mtype] [
							either signed? [
								either zero? offset [
									emit #{0FBF00}	;-- MOVSX eax, word [rax]
								][
									emit #{0FBF80}
									emit to-bin32 offset
								]
							][
								either zero? offset [
									emit #{0FB700}	;-- MOVZX eax, word [rax]
								][
									emit #{0FB780}
									emit to-bin32 offset
								]
							]
						]
						all [size = 1 not compiler/any-float? mtype] [
							either signed? [
								either zero? offset [
									emit #{0FBE00}	;-- MOVSX eax, byte [rax]
								][
									emit #{0FBE80}
									emit to-bin32 offset
								]
							][
								either zero? offset [
									emit #{0FB600}	;-- MOVZX eax, byte [rax]
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
				][
					emit-load-ecx idx
					emit #{FFC9}					;-- DEC ecx, one-based index
					emit #{4863C9}				;-- MOVSXD rcx, ecx
					case [
						compiler/any-float? mtype [
							emit either size = 4 [
								#{C5FA1004}			;-- VMOVSS xmm0, [rax+rcx*scale]
							][
								#{C5FB1004}			;-- VMOVSD xmm0, [rax+rcx*scale]
							]
							emit-index-sib 'rax size
						]
						all [size = 8 not compiler/any-float? mtype] [
							emit #{488B04}			;-- MOV rax, [rax+rcx*scale]
							emit-index-sib 'rax size
						]
						all [size = 4 not compiler/any-float? mtype] [
							emit #{8B04}			;-- MOV eax, [rax+rcx*scale]
							emit-index-sib 'rax size
						]
						all [size = 2 not compiler/any-float? mtype] [
							emit either signed? [#{0FBF04}][#{0FB704}]
							emit-index-sib 'rax size
						]
						all [size = 1 not compiler/any-float? mtype] [
							emit either signed? [#{0FBE04}][#{0FB604}]
							emit-index-sib 'rax size
						]
						true [
							compiler/throw-error ["x86-64 pointer load type not supported yet:" mold mtype/1]
						]
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
				either all [
					get-word? first head path
					tail? skip path 2
				][
					unless zero? offset [
						emit #{488D80}				;-- LEA rax, [rax+disp32]
						emit to-bin32 offset
					]
				][
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
		/local spec offset mtype field size signed? source-type last? base value-reg idx aggregate-by-value? aggregate-size
	][
		if verbose >= 3 [print [">>>storing path:" mold path mold value]]
		switch type [
			c-string! [
				idx: path/2
				last?: value = <last>
				unless parent [
					either last? [
						emit #{50}					;-- PUSH rax, save value
						emit-init-path path/1
						emit #{5A}					;-- POP rdx
					][
						emit-init-path path/1
					]
				]
				if value <> <last> [
					emit #{50}						;-- PUSH rax
					emit-load value
					emit #{5A}						;-- POP rdx
				]
				base: either last? [#{00}][#{02}]
				either integer? idx [
					offset: idx - 1
					case [
						zero? offset [
							emit rejoin [#{88} either last? [#{10}][base]] ;-- MOV [base], r8
						]
						true [
							emit rejoin [#{88} either last? [#{90}][#{82}]]
							emit to-bin32 offset
						]
					]
				][
					emit-load-ecx idx
					emit #{FFC9}					;-- DEC ecx, one-based index
					emit #{4863C9}				;-- MOVSXD rcx, ecx
					emit either last? [
						#{881408}					;-- MOV [rax+rcx], dl
					][
						#{88040A}					;-- MOV [rdx+rcx], al
					]
				]
			]
			pointer! [
				spec: either parent [
					compiler/resolve-type/with path/1 parent
				][
					compiler/resolve-type to word! path/1
				]
				mtype: spec/2
				set-width/type mtype/1
				size: emitter/size-of? mtype
				idx: either path/2 = 'value [1][path/2]
				source-type: either value = <last> [compiler/last-type][compiler/get-type value]
				last?: value = <last>
				unless parent [
					either last? [
						emit #{50}					;-- PUSH rax, save value
						emit-init-path path/1
						emit #{5A}					;-- POP rdx
					][
						emit-init-path path/1
					]
				]
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
				either integer? idx [
					offset: (idx - 1) * size
					case [
						compiler/any-float? mtype [
							either size = 4 [
								either zero? offset [
									emit rejoin [#{C5FA11} base] ;-- VMOVSS [base], xmm0
								][
									emit rejoin [#{C5FA11} either last? [#{80}][#{82}]]
									emit to-bin32 offset
								]
							][
								either zero? offset [
									emit rejoin [#{C5FB11} base] ;-- VMOVSD [base], xmm0
								][
									emit rejoin [#{C5FB11} either last? [#{80}][#{82}]]
									emit to-bin32 offset
								]
							]
						]
						all [size = 8 not compiler/any-float? mtype] [
							either zero? offset [
								emit rejoin [#{4889} value-reg] ;-- MOV [base], r64
							][
								emit rejoin [#{4889} either last? [#{90}][#{82}]]
								emit to-bin32 offset
							]
						]
						all [size = 4 not compiler/any-float? mtype] [
							either zero? offset [
								emit rejoin [#{89} value-reg] ;-- MOV [base], r32
							][
								emit rejoin [#{89} either last? [#{90}][#{82}]]
								emit to-bin32 offset
							]
						]
						all [size = 2 not compiler/any-float? mtype] [
							either zero? offset [
								emit rejoin [#{6689} value-reg] ;-- MOV [base], r16
							][
								emit rejoin [#{6689} either last? [#{90}][#{82}]]
								emit to-bin32 offset
							]
						]
						all [size = 1 not compiler/any-float? mtype] [
							either zero? offset [
								emit rejoin [#{88} value-reg] ;-- MOV [base], r8
							][
								emit rejoin [#{88} either last? [#{90}][#{82}]]
								emit to-bin32 offset
							]
						]
						true [
							compiler/throw-error ["x86-64 pointer store type not supported yet:" mold mtype/1]
						]
					]
				][
					emit-load-ecx idx
					emit #{FFC9}					;-- DEC ecx, one-based index
					emit #{4863C9}				;-- MOVSXD rcx, ecx
					case [
						compiler/any-float? mtype [
							emit either size = 4 [
								#{C5FA1104}
							][
								#{C5FB1104}
							]
							emit-index-sib either last? ['rax]['rdx] size
						]
						all [size = 8 not compiler/any-float? mtype] [
							emit either last? [#{488914}][#{488904}]
							emit-index-sib either last? ['rax]['rdx] size
						]
						all [size = 4 not compiler/any-float? mtype] [
							emit either last? [#{8914}][#{8904}]
							emit-index-sib either last? ['rax]['rdx] size
						]
						all [size = 2 not compiler/any-float? mtype] [
							emit either last? [#{668914}][#{668904}]
							emit-index-sib either last? ['rax]['rdx] size
						]
						all [size = 1 not compiler/any-float? mtype] [
							emit either last? [#{8814}][#{8804}]
							emit-index-sib either last? ['rax]['rdx] size
						]
						true [
							compiler/throw-error ["x86-64 pointer store type not supported yet:" mold mtype/1]
						]
					]
				]
			]
			struct! union! [
				spec: either parent [parent][second compiler/resolve-type to word! path/1]
				mtype: compiler/resolve-type/with path/2 spec
				field: select spec path/2
				set-width/type mtype/1
				offset: emitter/member-offset? spec path/2
				size: emitter/size-of? mtype
				aggregate-by-value?: all [
					find [struct! union!] mtype/1
					'value = last field
				]
				if all [
					paren? value
					find [struct! union!] mtype/1
					aggregate-by-value?
				][
					exit
				]
				source-type: either value = <last> [compiler/last-type][compiler/get-type value]
				last?: value = <last>
				if all [find [struct! union!] mtype/1 not aggregate-by-value?][size: stack-width]
				if all [
					last?
					aggregate-by-value?
					find [struct! union!] mtype/1
				][
					size: emitter/struct-slots? mtype
					either size = 1 [
						aggregate-size: either mtype/1 = 'union! [
							emitter/union-size? mtype/2
						][
							emitter/member-offset? mtype/2 none
						]
						emit #{50}					;-- PUSH rax
						unless parent [emit-init-path path/1]
						emit #{5A}					;-- POP rdx
						case [
							1 = aggregate-size [
								either zero? offset [
									emit #{8810}	;-- MOV [rax], dl
								][
									emit #{8890}
									emit to-bin32 offset
								]
							]
							2 = aggregate-size [
								either zero? offset [
									emit #{668910}	;-- MOV [rax], dx
								][
									emit #{668990}
									emit to-bin32 offset
								]
							]
							4 = aggregate-size [
								either zero? offset [
									emit #{8910}	;-- MOV [rax], edx
								][
									emit #{8990}
									emit to-bin32 offset
								]
							]
							true [
								either zero? offset [
									emit #{488910}	;-- MOV [rax], rdx
								][
									emit #{488990}
									emit to-bin32 offset
								]
							]
						]
					][
						emit #{50}					;-- PUSH rax
						emit #{52}					;-- PUSH rdx
						unless parent [emit-init-path path/1]
						emit #{5A}					;-- POP rdx
						emit #{59}					;-- POP rcx
						either zero? offset [
							emit #{488908}			;-- MOV [rax], rcx
							emit #{48895008}		;-- MOV [rax+8], rdx
						][
							emit #{488988}
							emit to-bin32 offset
							emit #{488990}
							emit to-bin32 offset + stack-width
						]
					]
					exit
				]
				if all [
					last?
					not aggregate-by-value?
					find [struct! union!] mtype/1
					block? source-type
					'value = last source-type
				][
					size: emitter/struct-slots? source-type
					either size = 1 [
						emit #{50}					;-- PUSH rax
						unless parent [emit-init-path path/1]
						either zero? offset [
							emit #{488B00}			;-- MOV rax, [rax]
						][
							emit #{488B80}			;-- MOV rax, [rax+disp32]
							emit to-bin32 offset
						]
						emit #{5A}					;-- POP rdx
						emit #{488910}				;-- MOV [rax], rdx
					][
						emit #{50}					;-- PUSH rax
						emit #{52}					;-- PUSH rdx
						unless parent [emit-init-path path/1]
						either zero? offset [
							emit #{488B00}			;-- MOV rax, [rax]
						][
							emit #{488B80}			;-- MOV rax, [rax+disp32]
							emit to-bin32 offset
						]
						emit #{5A}					;-- POP rdx
						emit #{59}					;-- POP rcx
						emit #{488908}				;-- MOV [rax], rcx
						emit #{48895008}			;-- MOV [rax+8], rdx
					]
					exit
				]
				unless parent [
					either last? [
						emit #{52}					;-- PUSH rdx, save assigned value
						emit-init-path path/1
						emit #{5A}					;-- POP rdx
					][
						emit-init-path path/1
					]
				]
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
				if set-path? path [
					emit-store-union-tag spec path/2 either last? ['rax]['rdx]
				]
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
		if set-path? path [
			emit #{50}								;-- PUSH rax
			emit-store-union-tag spec path/2 'rax
			emit #{58}								;-- POP rax
		]
		either any [
			all [
				find [struct! union!] mtype/1
				'value = last field
			]
			all [
				get-word? first head path
				tail? skip path 2
			]
		][
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
	emit-push-struct: func [
		slots [integer!]
		/sysv type [block!]
		/local classes class descriptors int-count float-count index base-type descriptor
	][										;-- number of 64-bit stack slots
		either sysv [
			classes: sysv-aggregate-classes type
			either classes/1 = 'memory [
				repeat index slots [
					append/only call-arg-types [integer! sysv-memory]
				]
			][
				int-count: 0
				float-count: 0
				foreach class classes [
					either class = 'sse [
						float-count: float-count + 1
					][
						int-count: int-count + 1
					]
				]
				descriptors: make block! slots
				index: 0
				foreach class classes [
					index: index + 1
					base-type: either class = 'sse ['float!]['integer!]
					descriptor: reduce [
						base-type 'sysv-aggregate slots int-count float-count index
					]
					append/only descriptors descriptor
				]
				foreach descriptor reverse descriptors [
					append/only call-arg-types descriptor
				]
			]
		][
			repeat index slots [
				append/only call-arg-types [integer!]
			]
		]
		either slots <= 5 [
			repeat i slots - 1 [
				emit #{FF70}						;-- PUSH qword [rax+i*<stack-width>] for i > 0
				emit to-bin8 slots - i * stack-width
			]
			emit #{FF30}							;-- PUSH qword [rax]
		][
			emit-reserve-stack slots
			emit #{4C8D1C24}						;-- LEA r11, [rsp]
				emit-copy-rax-to-r11 (slots * stack-width)
		]
	]
	emit-push-struct-ref: func [slots [integer!] /local offset][
		if call-struct-temp-slots < slots [
			compiler/throw-error "x86-64 struct argument temporary stack space was not reserved"
		]
		offset: ((length? call-arg-types) + call-struct-temp-slots - slots) * stack-width
		call-struct-temp-slots: call-struct-temp-slots - slots
		either offset <= 127 [
			emit #{4C8D5C24}						;-- LEA r11, [rsp+disp8]
			emit to-bin8 offset
		][
			emit #{4C8D9C24}						;-- LEA r11, [rsp+disp32]
			emit to-bin32 offset
		]
		emit-copy-rax-to-r11 (slots * stack-width)
		emit #{4C89D8}							;-- MOV rax, r11
		append/only call-arg-types [pointer! [byte!]]
		emit #{50}								;-- PUSH rax
	]
	emit-store-union-tag: func [spec [block!] name [word!] reg [word!] /local id tag type][
		if all [
			compiler/tagged-union? spec
			id: compiler/union-variant-id? spec name
		][
			tag: compiler/union-tag-type? spec
			type: tag/1
			switch type [
				uint8! [
					emit switch/default reg [
						rax [#{C600}]				;-- MOV byte [rax], imm8
						rdx [#{C602}]				;-- MOV byte [rdx], imm8
					][compiler/throw-error ["x86-64 union tag base register not supported:" reg]]
					emit to-bin8 id
				]
				uint16! [
					emit switch/default reg [
						rax [#{66C700}]				;-- MOV word [rax], imm16
						rdx [#{66C702}]				;-- MOV word [rdx], imm16
					][compiler/throw-error ["x86-64 union tag base register not supported:" reg]]
					emit to-bin16 id
				]
				uint32! [
					emit switch/default reg [
						rax [#{C700}]				;-- MOV dword [rax], imm32
						rdx [#{C702}]				;-- MOV dword [rdx], imm32
					][compiler/throw-error ["x86-64 union tag base register not supported:" reg]]
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
			emit #{EB04}								;-- JMP _exit
			emit #{31C0}								;-- XOR eax, eax
			emit #{FFC0}								;-- INC eax
			reduce [4 8]
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
		/local size jump jxx jp jcc unord-jumps-to-true? flip? jump-code
	][
		size: (length? code) - any [offset 0]
		jump: copy #{}
		jxx: [second set [size jump-code] construct-jump op size back?]
		jp:  [second set [size jump-code] construct-jump 'parity size back?]
		either none? op [
			append jump do jxx
		][
			flip?: no
			op: case [
				block? op [
					op: op/1
					either logic? op [pick [= <>] op][op]
				]
				logic? op [pick [= <>] op]
				true [
					flip?: yes
					opposite? op
				]
			]
			unord-jumps-to-true?: either flip? [
				op <> '=
			][
				op = first [<>]
			]
			if all [
				parity
				either unord-jumps-to-true? [
					find [< = <=] op
				][
					find [> <> >=] op
				]
			][
				parity: no
			]
			either not parity [
				append jump do jxx
			][
				either back? [
					either unord-jumps-to-true? [
						append jump do jp
						append jump do jxx
					][
						size: size + 2
						jcc: do jxx
						append jump rejoin [#{7A} to-bin8 length? jcc]
						append jump jcc
					]
				][
					either unord-jumps-to-true? [
						jcc: do jxx
						size: size + length? jcc
						append jump do jp
						append jump jcc
					][
						jcc: do jxx
						append jump rejoin [#{7A} to-bin8 length? jcc]
						append jump jcc
					]
				]
			]
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
		emit #{4889C2}								;-- MOV rdx, rax
	]
	emit-save-last: does [
		last-saved?: yes
		saved-last-wide?: any [
			compiler/int64? compiler/last-type
			compiler/any-pointer? compiler/last-type
			find [function! subroutine! struct! union!] compiler/last-type/1
		]
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
			emit either compiler/last-type/1 = 'float32! [#{F30F10C8}][#{F20F10C8}] ;-- MOVS[S/D] xmm1, xmm0 ; right operand
			emit either compiler/last-type/1 = 'float32! [#{C5FA100424}][#{C5FB100424}]
			emit #{4883C410}						;-- ADD rsp, 16
		][
			emit #{4889C1}							;-- MOV rcx, rax ; right operand
			emit either saved-last-wide? [
				#{488B0424}							;-- MOV rax, [rsp]
			][
				#{8B0424}							;-- MOV eax, [rsp]
			]
			emit #{4883C410}						;-- ADD rsp, 16
			last-saved?: yes
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
		compiler/last-type: [pointer! [byte!]]
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

	emit-overflow-epilog-no-ovf: does [
		emit #{31C0}							;-- XOR eax, eax
		emit #{EB05}							;-- JMP over MOV eax, 1
	]
	emit-overflow-epilog-ovf: does [
		emit #{B8}
		emit to-bin32 1
	]
	emit-overflow-jcc: func [cc-byte [binary!] /local opcode][
		opcode: copy #{0F80}
		opcode/2: (to char! opcode/2) or (to char! cc-byte/1)
		emit opcode
		emit-reloc-disp32 compose/only [- - (last emitter/overflow-jumps)]
	]
	emit-overflow-check-division: does [
		emit #{3D}							;-- CMP eax, 80000000h
		emit #{00000080}
		emit #{7509}							;-- JNE past divisor check
		emit #{83F9FF}						;-- CMP ecx, -1
		emit-overflow-jcc #{04}				;-- JE overflow
	]
	emit-overflow-check-shift: func [n [integer!] /local mask bias bits][
		if n = 0 [exit]
		bits: 8 * width
		either all [signed? width = 4][
			mask: to-bin32 shift/left -1 32 - n
			bias: to-bin32 shift/left 1 31 - n
			emit #{8D90}						;-- LEA edx, [eax + bias]
			emit bias
			emit #{F7C2}						;-- TEST edx, mask
			emit mask
		][
			switch width [
				1 [emit #{F6C0} emit to-bin8 shift/left -1 8 - n]
				2 [emit #{66F7C0} emit to-bin16 shift/left -1 16 - n]
				4 [emit #{F7C0} emit to-bin32 shift/left -1 32 - n]
			]
		]
		emit-overflow-jcc #{05}				;-- JNZ overflow
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
		global?: all [global? not compiler/job/need-main?]
		either global? [
			emit #{55}								;-- PUSH rbp
			emit #{4889E5}							;-- MOV rbp, rsp
			emit #{6A00}							;-- PUSH 0		; catch ID
			emit #{6A00}							;-- PUSH 0		; catch resume address
			emit-push -1							;-- args/locals bitmap barrier
			emit #{6A00}							;-- last known parent Red frame
			emit #{488945F8}						;-- MOV [rbp-8], rax
			emit #{E800000000}						;-- CALL next
			emit #{58}								;-- POP rax
			emit #{4805}							;-- ADD rax, body-size + catch prolog tail
			emit to-bin32 body-size + 11
			emit #{488945F0}						;-- MOV [rbp-16], rax
			32
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
	emit-close-catch: func [
		offset [integer!]
		level [integer!]
		global? [logic!]
		callback? [logic!]
		/local local-slots reg-count
	][
		global?: all [global? not compiler/job/need-main?]
		either global? [
			emit #{488D65F0}						;-- LEA rsp, [rbp-16]
			emit #{58}								;-- POP rax
			emit #{58}								;-- POP rax
			emit #{C9}								;-- LEAVE
		][
			local-slots: (round/to/ceiling offset stack-width) / stack-width
			reg-count: (locals-offset / stack-width) - 4
			offset: (local-slots * stack-width) + locals-offset + ((level + 1) * 2 * stack-width)
			if odd? reg-count + local-slots [offset: offset + stack-width]
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
	emit-read-io: func [type][
		emit-io-read type
	]
	emit-io-read: func [type][
		if verbose >= 3 [print ">>>emitting SYSTEM/IO/READ"]

		emit #{89C2}								;-- MOV edx, eax
		switch type [
			byte!	 [
				emit #{EC}							;-- IN al, dx
				emit #{25FF000000}					;-- AND eax, 0xFF
			]
			integer! [emit #{ED}]					;-- IN eax, dx
		]
	]
	emit-io-write: func [type][
		if verbose >= 3 [print ">>>emitting SYSTEM/IO/WRITE"]

		switch type [
			byte!	 [emit #{EE}]					;-- OUT dx, al
			integer! [emit #{EF}]					;-- OUT dx, eax
		]
	]
	emit-fpu-get: func [
		/type
		/options option [word!]
		/masks mask [word!]
		/cword
		/status
		/local bit
	][
		unless any [type status][
			emit #{8B05}							;-- MOV eax, [RIP+disp32]
			emit-reloc-disp32 fpu-cword/2
		]
		case [
			type [
				emit #{B802000000}					;-- MOV eax, FPU_TYPE_SSE
			]
			status [
				emit #{4883EC08}					;-- SUB rsp, 8
				emit #{0FAE1C24}					;-- STMXCSR [rsp]
				emit #{8B0424}						;-- MOV eax, [rsp]
				emit #{4883C408}					;-- ADD rsp, 8
				emit #{83E03F}						;-- AND eax, 3Fh
			]
			options [
				set [bit] switch/default option [
					rounding  [13]
					precision [0]					;-- SSE has no x87 precision-control field
				][
					compiler/throw-error ["invalid FPU option name:" option]
				]
				either option = 'precision [
					emit #{31C0}					;-- XOR eax, eax
				][
					emit #{25}						;-- AND eax, 6000h
					emit to-bin32 24576
					emit #{C1E8}					;-- SHR eax, 13
					emit to-bin8 bit
				]
			]
			masks [
				bit: switch/default mask [
					precision	[12]
					underflow	[11]
					overflow	[10]
					zero-divide [9]
					denormal	[8]
					invalid-op  [7]
				][
					compiler/throw-error ["invalid FPU mask name:" mask]
				]
				emit #{25}							;-- AND eax, 2^bit
				emit to-bin32 shift/left 1 bit
				emit #{C1E8}						;-- SHR eax, bit
				emit to-bin8 bit
			]
		]
	]
	emit-fpu-set: func [
		value
		/options option [word!]
		/masks mask [word!]
		/cword
		/local bit clear-mask
	][
		either cword [
			emit-load value
		][
			emit #{8B05}							;-- MOV eax, [RIP+disp32]
			emit-reloc-disp32 fpu-cword/2
			case [
				options [
					if option = 'precision [exit]
					bit: switch/default option [
						rounding [13]
					][
						compiler/throw-error ["invalid FPU option name:" option]
					]
					clear-mask: complement 24576
					emit #{25}						;-- AND eax, ~6000h
					emit to-bin32 clear-mask
					emit #{0D}						;-- OR eax, value << bit
					emit to-bin32 shift/left to integer! value bit
				]
				masks [
					bit: switch/default mask [
						precision	[12]
						underflow	[11]
						overflow	[10]
						zero-divide [9]
						denormal	[8]
						invalid-op  [7]
					][
						compiler/throw-error ["invalid FPU mask name:" mask]
					]
					clear-mask: complement shift/left 1 bit
					emit #{25}						;-- AND eax, ~(1 << bit)
					emit to-bin32 clear-mask
					emit #{0D}						;-- OR eax, value << bit
					emit to-bin32 shift/left to integer! value bit
				]
			]
		]
		emit #{8905}								;-- MOV [RIP+disp32], eax
		emit-reloc-disp32 fpu-cword/2
	]
	emit-fpu-update: does [
		emit #{0FAE15}								;-- LDMXCSR [RIP+disp32]
		emit-reloc-disp32 fpu-cword/2
	]
	emit-fpu-init: does [
		emit #{0FAE15}								;-- LDMXCSR [RIP+disp32]
		emit-reloc-disp32 fpu-cword/2
	]
	emit-push: func [value][
		if verbose >= 3 [print [">>>pushing" mold value]]
		if logic? value [value: to integer! value]
		either tag? value [
			either value = <last> [
				either all [
					block? compiler/last-type
					compiler/any-float? compiler/last-type
				][
					emit #{4883EC08}				;-- SUB rsp, 8
					emit either compiler/last-type/1 = 'float32! [#{F30F110424}][#{F20F110424}]
				][
					emit #{50}						;-- PUSH rax
				]
			][
				either value = <ret-ptr> [
					emit #{488D85}					;-- LEA rax, [rbp+args-offset]
					emit to-bin32 args-offset
					emit #{50}						;-- PUSH rax
				][
					emit #{488D8424}				;-- LEA rax, [rsp+<args-top>]
					emit to-bin32 to integer! value
					emit #{50}						;-- PUSH rax
				]
			]
		][
			either all [integer? value value >= -128 value <= 127][
				emit #{6A}
				emit to-bin8 value
			][
				either integer? value [
					emit #{48B8}					;-- MOV rax, imm64
					emit to-bin64 value
				][
					emit-load value
				]
				emit #{50}							;-- PUSH rax
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
	emit-atomic-load: func [order [word!]][
		if verbose >= 3 [print [">>>emitting ATOMIC-LOAD" mold order]]
		emit #{8B00}								;-- MOV eax, [rax]
	]
	emit-atomic-store: func [value order [word!]][
		if verbose >= 3 [print [">>>emitting ATOMIC-STORE" mold value mold order]]
		emit #{4889C6}								;-- MOV rsi, rax
		emit-load value
		emit #{8906}								;-- MOV [rsi], eax
		emit-atomic-fence
	]
	emit-atomic-math: func [op [word!] right-op old? [logic!] ret? [logic!] order [word!]][
		if verbose >= 3 [print [">>>emitting ATOMIC-MATH-OP" mold op mold right-op mold ret? mold order]]
		emit #{4889C6}								;-- MOV rsi, rax
		emit-load right-op
		either any [old? ret?][
			either find [add sub] op [
				emit #{89C2}						;-- MOV edx, eax
				if op = 'sub [emit #{F7D8}]			;-- NEG eax
				emit #{F00FC106}					;-- LOCK XADD [rsi], eax
				if all [ret? not old?][
					emit either op = 'add [
						#{01D0}						;-- ADD eax, edx
					][
						#{29D0}						;-- SUB eax, edx
					]
				]
			][
				emit #{57}							;-- PUSH rdi
				emit #{89C7}						;-- MOV edi, eax
				emit #{8B06}						;-- MOV eax, [rsi]
				emit #{89C1}						;-- loop: MOV ecx, eax
				if old? [emit #{89C2}]				;-- MOV edx, eax
				switch op [
					or  [emit #{09F9}]				;-- OR  ecx, edi
					xor [emit #{31F9}]				;-- XOR ecx, edi
					and [emit #{21F9}]				;-- AND ecx, edi
				]
				emit #{F00FB10E}					;-- LOCK CMPXCHG [rsi], ecx
				emit either old? [#{75F4}][#{75F6}]	;-- JNE loop
				emit either all [ret? not old?][
					#{89C8}							;-- MOV eax, ecx
				][
					#{89D0}							;-- MOV eax, edx
				]
				emit #{5F}							;-- POP rdi
			]
		][
			emit switch op [
				add  [#{F00106}]					;-- LOCK ADD [rsi], eax
				sub  [#{F02906}]					;-- LOCK SUB [rsi], eax
				or   [#{F00906}]					;-- LOCK OR  [rsi], eax
				xor  [#{F03106}]					;-- LOCK XOR [rsi], eax
				and  [#{F02106}]					;-- LOCK AND [rsi], eax
			]
		]
	]
	emit-atomic-cas: func [check value ret? [logic!] order [word!]][
		if verbose >= 3 [print [">>>emitting ATOMIC-CAS" mold check mold value ret? mold order]]
		emit #{4889C6}								;-- MOV rsi, rax
		emit-load value
		emit-move-path-alt							;-- load new value in edx
		emit-load check								;-- load check value in eax
		emit #{F00FB116}							;-- LOCK CMPXCHG [rsi], edx
		if ret? [
			emit #{0F94C0}							;-- SETE al
			emit #{0FB6C0}							;-- MOVZX eax, al
		]
	]
	emit-atomic-fence: does [
		if verbose >= 3 [print ">>>emitting ATOMIC-FENCE"]
		emit #{0FAEF0}								;-- MFENCE
	]
	emit-init-sub: :noop
	emit-return-sub: does [
		if verbose >= 3 [print ">>>emitting RET from subroutine"]
		emit #{C3}									;-- RET
	]
	emit-call-sub: func [name [word!] spec [block!]][
		if verbose >= 3 [print [">>>emitting CALL subroutine" name]]
		emit #{E8}									;-- CALL NEAR disp32
		append spec/3 emitter/tail-ptr
		emit to-bin32 0
		unless empty? emitter/chunks/queue [
			append/only
				second last emitter/chunks/queue
				back tail spec/3
		]
	]
]
