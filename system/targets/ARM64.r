REBOL [
	Title:   "Red/System ARM64 code emitter"
	Author:  "Red Foundation"
	File:    %ARM64.r
	Tabs:    4
	Rights:  "Copyright (C) 2011-2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

make-profilable make target-class [
	target:             'ARM64
	little-endian?:     yes
	struct-align-size:  8
	ptr-size:           8
	default-align:      8
	stack-width:        8
	stack-slot-max:     8
	args-offset:        16
	branch-offset-size: 4
	locals-offset:      32
	def-locals-offset:  32
	insn-size:          4
	native-ref-one-based?: yes
	pc-as-pointer?:     yes
	stack-bitmap-counts?: yes
	stateful-calls?:     yes

	noop: does []
	call-arg-index: 0
	call-arg-types: copy []
	call-stack-slots: 0
	call-pad-slots: 0
	call-extra-slots: 0
	call-shadow-slots: 0
	call-variadic?: no
	call-float-reg-count: 0
	call-struct-temp-slots: 0
	by-value-args: copy []
	saved-last-wide?: no
	saved-last-float?: no
	saved-last-float32?: no
	last-math-op: none
	last-math-wide?: no
	last-math-signed?: yes
	last-math-width: 4
	conditions: make hash! [
	;-- name ----------- signed -- unsigned --
		overflow?          6         -
		not-overflow?      7         -
		=                  0         0
		<>                 1         1
		signed?            4         -
		unsigned?          5         -
		even?              0         -
		odd?               1         -
		<                  11        3
		>=                 10        2
		<=                 13        9
		>                  12        8
	]

	unsupported-port-io: does [
		compiler/throw-error "ARM64 port I/O is not supported"
	]

	;-- A64 instructions are written as little-endian 32-bit words.
	opcode-int: func [value [integer! binary!]][
		either integer? value [value][to integer! head value]
	]
	emit-i32: func [value [integer! binary!] /local n][
		n: opcode-int value
		emit to-bin32 n
	]

	emit-mov-imm32: func [value [integer! char!] /reg rd [integer!] /local v][
		rd: any [rd 0]
		v: to integer! value
		emit-i32 1384120320 or ((v and 65535) * 32) or rd       ; MOVZ Wd, #lo16
		if any [negative? v not zero? shift/logical v -16][
			emit-i32 1920991232 or (((shift/logical v -16) and 65535) * 32)
				or 2097152 or rd                                  ; MOVK Wd, #hi16, LSL #16
		]
	]

	emit-mov-imm64: func [value type [word!] /reg rd [integer!] /local hex half digits part opcode][
		rd: any [rd 0]
		hex: compiler/int64-hex value type
		repeat i 4 [
			half: i - 1
			digits: copy/part skip hex 12 - (half * 4) 4
			part: to integer! debase/base digits 16
			opcode: either zero? half [#{D2800000}][#{F2800000}]
			emit-i32 (opcode-int opcode) or (part * 32) or (half * 2097152) or rd
		]
	]

	emit-load-integer: func [value [integer! char!]][
		emit-mov-imm32 value
	]

	emit-page-ref: func [spec [block!] reg [integer!] /local ref][
		ref: reduce [emitter/tail-ptr reg]
		append/only spec/3 ref
		unless empty? emitter/chunks/queue [
			append/only second last emitter/chunks/queue ref
		]
		emit-i32 (to integer! #{90000000}) or reg              ; ADRP xN, symbol
		emit-i32 (to integer! #{91000000}) or (reg * 32) or reg ; ADD xN, xN, :lo12:symbol
	]

	emit-global-address: func [name [word! object! block!] reg [integer!] /local spec][
		if object? name [name: compiler/unbox name]
		spec: either block? name [name][all [word? name emitter/get-symbol-ref name]]
		unless spec [compiler/throw-error ["unknown ARM64 symbol:" mold name]]
		emit-page-ref spec reg
		if spec/1 = 'import-var [
			emit-i32 (to integer! #{F9400000}) or (reg * 32) or reg ; LDR xN, [xN]
		]
	]

	wide-type?: func [type [block!]][
		to logic! find [
			int64! uint64! pointer! c-string! function! subroutine!
			struct! union! any-pointer!
		] type/1
	]

	float32-type?: func [type [block!]][type/1 = 'float32!]

	emit-load-float-literal: func [value type [block!] /reg rd [integer!] /local spec][
		rd: any [rd 0]
		spec: emitter/store-value none value type
		emit-global-address spec/2 16
		emit-i32 (to integer! either float32-type? type [#{BD400200}][#{FD400200}]) or rd
		compiler/last-type: type
	]

	emit-load-float-global: func [name type [block!] /reg rd [integer!]][
		rd: any [rd 0]
		emit-global-address name 16
		emit-i32 (to integer! either float32-type? type [#{BD400200}][#{FD400200}]) or rd
	]

	emit-store-float-global: func [name type [block!]][
		emit-global-address name 16
		emit-i32 either float32-type? type [#{BD000200}][#{FD000200}]
	]

	emit-load-global: func [name [word! object! block!] type [block!] /reg rd [integer!] /local opcode][
		rd: any [rd 0]
		if compiler/any-float? type [emit-load-float-global/reg name type rd exit]
		emit-global-address name 16
		opcode: switch/default type/1 [
			byte!       [#{39400200}]
			logic!      [#{39400200}]
			int8!       [#{39C00200}]
			uint8!      [#{39400200}]
			int16!      [#{79C00200}]
			uint16!     [#{79400200}]
			integer!    [#{B9400200}]
			int32!      [#{B9400200}]
			uint32!     [#{B9400200}]
			int64!      [#{F9400200}]
			uint64!     [#{F9400200}]
			pointer!    [#{F9400200}]
			c-string!   [#{F9400200}]
			function!   [#{F9400200}]
			subroutine! [#{F9400200}]
			struct!     [#{F9400200}]
			union!      [#{F9400200}]
		][compiler/throw-error ["ARM64 global load type is not implemented:" mold type/1]]
		emit-i32 (opcode-int opcode) or rd
	]

	emit-store-global: func [name [word! object! block!] type [block!] /local opcode][
		if compiler/any-float? type [emit-store-float-global name type exit]
		emit-global-address name 16
		opcode: switch/default type/1 [
			byte!       [#{39000200}]
			logic!      [#{39000200}]
			int8!       [#{39000200}]
			uint8!      [#{39000200}]
			int16!      [#{79000200}]
			uint16!     [#{79000200}]
			integer!    [#{B9000200}]
			int32!      [#{B9000200}]
			uint32!     [#{B9000200}]
			int64!      [#{F9000200}]
			uint64!     [#{F9000200}]
			pointer!    [#{F9000200}]
			c-string!   [#{F9000200}]
			function!   [#{F9000200}]
			subroutine! [#{F9000200}]
			struct!     [#{F9000200}]
			union!      [#{F9000200}]
		][compiler/throw-error ["ARM64 global store type is not implemented:" mold type/1]]
		emit-i32 opcode
	]

	patch-stack-offset: func [name [word! tag!] offset [integer!] /local pos][
		if pos: find/skip emitter/stack name 2 [pos/2: offset]
	]

	emit-register-offset: func [
		base [integer!] target [integer!] offset [integer!] scratch [integer!]
		/local opcode
	][
		if zero? offset [
			emit-i32 (to integer! #{AA0003E0}) or (base * 65536) or target
			exit
		]
		emit-mov-imm64/reg (abs offset) 'uint64! scratch
		opcode: either negative? offset [#{CB000000}][#{8B000000}]
		emit-i32 (opcode-int opcode) or (scratch * 65536) or (base * 32) or target
	]

	emit-adjust-stack: func [size [integer!] release? [logic!] /local pages chunk tail opcode][
		unless positive? size [exit]
		pages: to integer! (size / 4096)
		tail: size // 4096
		opcode: either release? [#{914003FF}][#{D14003FF}]
		while [positive? pages][
			chunk: min pages 4095
			emit-i32 (opcode-int opcode) or (chunk * 1024)
			pages: pages - chunk
		]
		if positive? tail [
			opcode: either release? [#{910003FF}][#{D10003FF}]
			emit-i32 (opcode-int opcode) or (tail * 1024)
		]
	]

	emit-sp-offset-address: func [
		target [integer!] offset [integer!] protected [integer! none!]
		/local amount opcode
	][
		emit-i32 (to integer! #{910003E0}) or target             ; ADD xTarget, sp, #0
		if zero? offset [exit]
		amount: 17
		if any [amount = target amount = protected][amount: 15]
		emit-mov-imm64/reg (abs offset) 'uint64! amount
		opcode: either negative? offset [#{CB000000}][#{8B000000}]
		emit-i32 (opcode-int opcode) or (amount * 65536) or (target * 32) or target
	]

	emit-frame-insn: func [base [binary!] offset [integer!] reg [integer!] /local address][
		if any [offset < -256 offset > 255][
			address: either reg = 16 [17][16]
			emit-register-offset 29 address offset address
			emit-i32 (opcode-int base) or (address * 32) or reg
			exit
		]
		emit-i32 (opcode-int base) or ((offset and 511) * 4096) or (29 * 32) or reg
	]

	emit-frame-fp-insn: func [base [binary!] offset [integer!] reg [integer!]][
		emit-frame-insn base offset reg
	]

	emit-load-local: func [name [word!] type [block!] /reg rd [integer!] /local offset opcode][
		rd: any [rd 0]
		offset: emitter/local-offset? name
		unless offset [compiler/throw-error ["unknown ARM64 local:" name]]
		if compiler/any-float? type [
			emit-frame-fp-insn either float32-type? type [#{BC400000}][#{FC400000}] offset rd
			exit
		]
		opcode: switch/default type/1 [
			byte!       [#{38400000}]
			logic!      [#{38400000}]
			int8!       [#{38C00000}]
			uint8!      [#{38400000}]
			int16!      [#{78C00000}]
			uint16!     [#{78400000}]
			integer!    [#{B8400000}]
			int32!      [#{B8400000}]
			uint32!     [#{B8400000}]
			int64!      [#{F8400000}]
			uint64!     [#{F8400000}]
			pointer!    [#{F8400000}]
			c-string!   [#{F8400000}]
			function!   [#{F8400000}]
			subroutine! [#{F8400000}]
			struct!     [#{F8400000}]
			union!      [#{F8400000}]
		][compiler/throw-error ["ARM64 local load type is not implemented:" mold type/1]]
		emit-frame-insn opcode offset rd
	]

	emit-store-local: func [name [word!] type [block!] /local offset opcode][
		offset: emitter/local-offset? name
		unless offset [compiler/throw-error ["unknown ARM64 local:" name]]
		if compiler/any-float? type [
			emit-frame-fp-insn either float32-type? type [#{BC000000}][#{FC000000}] offset 0
			exit
		]
		opcode: switch/default type/1 [
			byte!       [#{38000000}]
			logic!      [#{38000000}]
			int8!       [#{38000000}]
			uint8!      [#{38000000}]
			int16!      [#{78000000}]
			uint16!     [#{78000000}]
			integer!    [#{B8000000}]
			int32!      [#{B8000000}]
			uint32!     [#{B8000000}]
			int64!      [#{F8000000}]
			uint64!     [#{F8000000}]
			pointer!    [#{F8000000}]
			c-string!   [#{F8000000}]
			function!   [#{F8000000}]
			subroutine! [#{F8000000}]
			struct!     [#{F8000000}]
			union!      [#{F8000000}]
		][compiler/throw-error ["ARM64 local store type is not implemented:" mold type/1]]
		emit-frame-insn opcode offset 0
	]

	emit-clear-slot: func [name [word!] /local offset][
		offset: emitter/local-offset? name
		unless offset [compiler/throw-error ["unknown ARM64 local:" name]]
		emit-frame-insn #{38000000} offset 31                  ; STURB wzr, [x29, #offset]
	]

	emit-local-address: func [name [word!] /local offset][
		offset: emitter/local-offset? name
		unless offset [compiler/throw-error ["unknown ARM64 local:" name]]
		emit-register-offset 29 0 offset 16
	]

	emit-load: func [value /with cast [object!] /local raw raw-type local-spec type info][
		if block? value [value: <last>]
		case [
			value = <last> []
			object? value [
				raw: compiler/unbox value
				type: compiler/resolve-aliased value/type
				case [
					all [compiler/any-float? type any [decimal? raw issue? raw]] [
						emit-load-float-literal raw type
					]
					all [find [int64! uint64!] type/1 any [integer? raw issue? raw]] [
						emit-mov-imm64 raw type/1
					]
					true [
						emit-load raw
						emit-casting value no
					]
				]
			]
			logic? value [
				emit-load-integer to integer! value
				emit-i32 #{7100001F}                              ; CMP w0, #0
			]
			any [integer? value char? value] [emit-load-integer value]
			issue? value [
				info: compiler/int64-literal-info value
				either info [
					emit-mov-imm64 value info/1
				][
					type: either all [with cast/type/1 = 'float32!][[float32!]][[float!]]
					emit-load-float-literal value type
				]
			]
			decimal? value [
				type: either all [with cast/type/1 = 'float32!][[float32!]][[float!]]
				emit-load-float-literal value type
			]
			string? value [emit-load-literal [c-string!] value]
			paren? value [emit-load-literal none value]
			path? value [emitter/access-path value none]
			get-word? value [
				value: to word! value
				type: compiler/resolve-aliased compiler/get-type value
				either emitter/local-offset? value [
					either type/1 = 'function! [
						emit-load-local value type
					][
						emit-local-address value
					]
				][
					emit-global-address value 0
				]
			]
			word? value [
				raw-type: compiler/get-type value
				type: compiler/resolve-aliased raw-type
				either emitter/local-offset? value [
					either any [
					find by-value-args value
					all [block? raw-type 'value = last raw-type]
					all [compiler/locals local-spec: select compiler/locals value 'value = last local-spec]
					all [find [struct! union!] type/1 'value = last type]
				][
						emit-local-address value
					][
						emit-load-local value type
					]
				][
					emit-load-global value type
				]
			]
			'else [
			raw: compiler/unbox value
			compiler/throw-error ["ARM64 load is not implemented for:" mold raw]
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
		emit-page-ref spec 0
	]

	emit-push: func [value][
		either tag? value [
			case [
				value = <last> []
				value = <ret-ptr> [
					unless <ret-ptr> = emitter/stack/1 [
						compiler/throw-error "ARM64 return pointer is not available in this frame"
					]
					emit-frame-insn #{F8400000} emitter/stack/2 0
				]
				true [
					emit-i32 (to integer! #{910003E0}) or ((call-arg-index * 16) * 1024)
				]
			]
		][
			unless value = <last> [emit-load value]
	]
		emit-i32 #{D10023FF}                                  ; SUB sp, sp, #8
		emit-i32 #{910003F0}                                  ; MOV x16, sp
		emit-i32 #{F9000200}                                  ; STR x0, [x16]
	]

	emit-pop: does [
		if verbose >= 3 [print ">>>emitting POP"]
		emit-i32 #{910003F0}                                  ; MOV x16, sp
		emit-i32 #{F9400200}                                  ; LDR x0, [x16]
		emit-i32 #{910023FF}                                  ; ADD sp, sp, #8
	]

	emit-pop-arg: func [reg [integer!]][
		emit-i32 (to integer! #{F94003E0}) or reg              ; LDR xN, [sp]
		emit-i32 #{910043FF}                                  ; ADD sp, sp, #16
	]

	emit-sp-insn: func [
		base [binary!] offset [integer!] reg [integer!]
		/local scaled scale address amount opcode
	][
		scale: either any [base = #{BC400000} base = #{BC000000}][4][8]
		scaled: switch base [
			#{F8400000} [#{F9400000}]
			#{F8000000} [#{F9000000}]
			#{FC400000} [#{FD400000}]
			#{FC000000} [#{FD000000}]
			#{BC400000} [#{BD400000}]
			#{BC000000} [#{BD000000}]
		]
		if all [scaled not negative? offset zero? offset // scale offset / scale <= 4095][
			emit-i32 (opcode-int scaled) or ((offset / scale) * 1024) or (31 * 32) or reg
			exit
		]
		if any [offset < -256 offset > 255][
			address: either reg = 16 [17][16]
			emit-sp-offset-address address offset reg
			emit-i32 (opcode-int base) or (address * 32) or reg
			exit
		]
		emit-i32 (opcode-int base) or ((offset and 511) * 4096) or (31 * 32) or reg
	]

	reset-call-state: does [
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

	emit-reserve-call-struct-temps: func [slots [integer!] /local size][
		size: round/to/ceiling slots * stack-width 16
		emit-reserve-stack slots
		call-extra-slots: call-extra-slots + size
		call-struct-temp-slots: slots
	]

	emit-typed-int64-padding: func [fspec [block!] type [block!]][
		if all [
			compiler/find-attribute fspec/4 'typed
			find [int64! uint64!] type/1
		][
			emit-i32 #{D360FC11}                              ; LSR x17, x0, #32
			emit-i32 #{B90013F1}                              ; STR w17, [sp, #16]
		]
	]

	emit-argument: func [arg fspec [block!] /local value arg-type][
		if arg = #_ [
			if compiler/find-attribute fspec/4 'typed [
				emit-i32 #{D10043FF}                              ; SUB sp, sp, #16
				emit-i32 #{F90003FF}                              ; STR xzr, [sp]
				call-arg-index: call-arg-index + 1
				append/only call-arg-types [integer!]
			]
			exit
		]
		if tag? arg [
			case [
				arg = <last> []
				arg = <ret-ptr> [
					unless <ret-ptr> = emitter/stack/1 [
						compiler/throw-error "ARM64 return pointer is not available in this frame"
					]
					emit-frame-insn #{F8400000} emitter/stack/2 0
				]
				true [
					emit-i32 (to integer! #{910003E0}) or ((call-arg-index * 16) * 1024)
				]
			]
			emit-i32 #{D10043FF}                              ; SUB sp, sp, #16
			emit-i32 #{F90003E0}                              ; STR x0, [sp]
			call-arg-index: call-arg-index + 1
			append/only call-arg-types [pointer! [byte!]]
			exit
		]
		value: compiler/unbox arg
		if block? value [value: <last>]
		arg-type: compiler/resolve-aliased compiler/get-type arg
		either compiler/any-float? arg-type [
			emit-load arg
			emit-i32 #{D10043FF}                              ; SUB sp, sp, #16
			emit-i32 either float32-type? arg-type [#{BC0003E0}][#{FC0003E0}] ; STUR s0/d0, [sp]
		][
			unless value = <last> [
				either object? arg [emit-load arg][emit-load value]
			]
			emit-i32 #{D10043FF}                              ; SUB sp, sp, #16
			emit-i32 #{F90003E0}                              ; STR x0, [sp]
			emit-typed-int64-padding fspec arg-type
		]
		call-arg-index: call-arg-index + 1
		append/only call-arg-types arg-type
	]

	emit-variadic-data: func [
		args [block!]
		/local item-count total data-size packed-size source target
	][
		item-count: length? args/2
		total: either args/1 = #typed [item-count / 3][item-count]
		data-size: item-count * stack-width
		packed-size: round/to/ceiling data-size 16
		;-- Compact the low eight bytes of each aligned staging cell into
		;-- the 24-byte typed-value records used by the 64-bit runtime.
		emit-adjust-stack packed-size no
		repeat i item-count [
			source: packed-size + ((i - 1) * 16)
			target: (i - 1) * stack-width
			emit-sp-insn #{F8400000} source 16
			emit-sp-insn #{F8000000} target 16
		]

		emit-i32 #{910003F0}                                  ; MOV x16, sp (list pointer)
		emit-i32 either args/1 = #typed [#{D10083FF}][#{D100C3FF}] ; SUB sp, sp, #32/#48
		emit-mov-imm32 total
		emit-i32 #{F90003E0}                                  ; STR x0, [sp] (count)
		emit-i32 #{F9000BF0}                                  ; STR x16, [sp, #16] (list)
		unless args/1 = #typed [
			emit-mov-imm32 data-size
			emit-i32 #{F90013E0}                               ; STR x0, [sp, #32] (byte size)
		]
		call-extra-slots: (item-count * 16) + packed-size
		call-arg-index: either args/1 = #typed [2][3]
		clear call-arg-types
		append/only call-arg-types [integer!]
		append/only call-arg-types [pointer! [integer!]]
		unless args/1 = #typed [append/only call-arg-types [integer!]]
	]

	emit-call-syscall: func [
		args [block!] fspec [block!] attribs [block! none!]
		/local n
	][
		n: call-arg-index
		if n > 6 [compiler/throw-error ["ARM64 syscall with too many args:" n]]
		repeat reg n [emit-pop-arg reg - 1]
		emit-mov-imm32/reg last fspec 8                      ; x8 = syscall number
		emit-i32 #{D4000001}                                  ; SVC #0
		reset-call-state
	]

	prepare-call-args: func [
		n [integer!]
		/indirect-result
		/local types classes type int-reg fp-reg stack-size out-size source target class first?
			aggregate-stack-left aggregate-stack-base aggregate-field-size
	][
		types: reverse copy/deep call-arg-types
		classes: make block! n
		int-reg: fp-reg: stack-size: aggregate-stack-left: 0
		first?: yes
		foreach type types [
			type: compiler/resolve-aliased type
			case [
				all [indirect-result first?] [
					append/only classes reduce ['result 8 type]
				]
				all [5 <= length? type type/2 = 'arm64-aggregate] [
					if type/5 = 1 [
						either type/3 = 'hfa [
							if (fp-reg + type/4) > 8 [
								fp-reg: 8
								aggregate-stack-left: type/4
							]
						][
							if (int-reg + type/4) > 8 [
								int-reg: 8
								aggregate-stack-left: type/4
							]
						]
						if positive? aggregate-stack-left [
							aggregate-field-size: either float32-type? type [4][8]
							aggregate-stack-base: stack-size
			stack-size: stack-size + (round/to/ceiling
				(type/4 * aggregate-field-size) 8)
						]
					]
					either positive? aggregate-stack-left [
						target: aggregate-stack-base + ((type/5 - 1) * aggregate-field-size)
						append/only classes reduce ['stack target type aggregate-field-size]
						aggregate-stack-left: aggregate-stack-left - 1
					][
						either type/3 = 'hfa [
							append/only classes reduce ['fp fp-reg type]
							fp-reg: fp-reg + 1
						][
							append/only classes reduce ['int int-reg type]
							int-reg: int-reg + 1
						]
					]
				]
				compiler/any-float? type [
					either fp-reg < 8 [
						append/only classes reduce ['fp fp-reg type]
						fp-reg: fp-reg + 1
					][
						append/only classes reduce ['stack stack-size type]
						stack-size: stack-size + 8
					]
				]
				true [
					either int-reg < 8 [
						append/only classes reduce ['int int-reg type]
						int-reg: int-reg + 1
					][
						append/only classes reduce ['stack stack-size type]
						stack-size: stack-size + 8
					]
				]
			]
			first?: no
		]

		out-size: round/to/ceiling stack-size 16
		if positive? out-size [
			emit-adjust-stack out-size no
		]
		repeat i n [
			class: classes/:i
			source: out-size + ((i - 1) * 16)
			switch class/1 [
				int [emit-sp-insn #{F8400000} source class/2]
				result [emit-sp-insn #{F8400000} source 8]
				fp [
					emit-sp-insn either float32-type? class/3 [#{BC400000}][#{FC400000}]
						source class/2
				]
				stack [
					target: class/2
					either all [4 <= length? class class/4 = 4][
						emit-sp-insn #{B8400000} source 16
						emit-sp-insn #{B8000000} target 16
					][
						emit-sp-insn #{F8400000} source 16
						emit-sp-insn #{F8000000} target 16
					]
				]
			]
		]
		(n * 16) + out-size
	]

	emit-call-stack-cleanup: func [size [integer!]][
		emit-adjust-stack size yes
	]

	emit-call-native: func [
		args [block!] fspec [block!] spec [block!] attribs [block! none!]
		/routine name [word!]
		/local n target target-type path-target? call-reg
	][
		if all [compiler/variadic? args/1 fspec/3 <> 'cdecl][emit-variadic-data args]
		n: call-arg-index
		path-target?: no
		if routine [
			target: either all [2 <= length? fspec 'local = last fspec][
				pick tail fspec -2
			][
				name
			]
			if find form target slash [
				emitter/access-path to path! target none
				emit-i32 #{AA0003E9}                          ; MOV x9, x0
				path-target?: yes
			]
		]
		call-stack-slots: (prepare-call-args n) + call-extra-slots
		either routine [
			call-reg: either path-target? [9][16]
			unless path-target? [
				target-type: compiler/resolve-aliased compiler/get-type target
				either emitter/local-offset? target [
					emit-load-local/reg target target-type 16
				][
					emit-load-global/reg target target-type 16
				]
			]
			emit-i32 (to integer! #{D63F0000}) or (call-reg * 32) ; BLR xN
		][
			append spec/3 emitter/tail-ptr
			unless empty? emitter/chunks/queue [
				append/only second last emitter/chunks/queue back tail spec/3
			]
			emit-i32 #{94000000}                              ; BL native
		]
		emit-call-stack-cleanup call-stack-slots
		reset-call-state
	]

	emit-call-import: func [
		args [block!] fspec [block!] spec [block!] attribs [block! none!]
		/local n indirect-result?
	][
		if all [compiler/variadic? args/1 fspec/3 <> 'cdecl][emit-variadic-data args]
		n: call-arg-index
		indirect-result?: to logic! emitter/struct-ptr? fspec/4
		call-stack-slots: (either indirect-result? [
			prepare-call-args/indirect-result n
		][
			prepare-call-args n
		]) + call-extra-slots
		append spec/3 emitter/tail-ptr
		unless empty? emitter/chunks/queue [
			append/only second last emitter/chunks/queue back tail spec/3
		]
		emit-i32 #{94000000}                                  ; BL import@plt
		emit-call-stack-cleanup call-stack-slots
		reset-call-state
	]

	emit-store: func [
		name [word!] value spec [block! none!]
		/by-value slots [integer!]
		/local type source-type literal-pointer? offset hfa field-size opcode i
	][
		if by-value [
			hfa: homogeneous-aggregate? spec
			if all [slots > 2 not hfa/1][exit]           ; hidden return pointer was written by callee
			either offset: emitter/local-offset? name [
			either hfa/1 [
					field-size: either hfa/2 [4][8]
				opcode: either hfa/2 [#{BC000000}][#{FC000000}]
				repeat i hfa/3 [
					emit-frame-fp-insn opcode offset + ((i - 1) * field-size) i - 1
				]
			][
				repeat i slots [
					emit-frame-insn #{F8000000} offset + ((i - 1) * stack-width) i - 1
				]
			]
			][
				emit-global-address name 16
				emit-i32 #{F9400210}                      ; LDR x16, [x16]
				either hfa/1 [
					field-size: either hfa/2 [4][8]
					opcode: either hfa/2 [#{BD000000}][#{FD000000}]
					repeat i hfa/3 [
						emit-i32 (opcode-int opcode)
							or (((i - 1) * field-size / field-size) * 1024)
							or (16 * 32) or (i - 1)
					]
				][
					repeat i slots [
						emit-i32 (to integer! #{F9000000})
							or ((i - 1) * 1024) or (16 * 32) or (i - 1)
					]
				]
			]
			exit
		]
		if block? value [value: <last>]
		if logic? value [value: to integer! value]
		type: compiler/resolve-aliased compiler/get-variable-spec name
		unless value = <last> [
			literal-pointer?: all [
				find [string! paren! binary!] type?/word value
				compiler/any-pointer? type
			]
			case [
				all [binary? value float32-type? type][
					emit-load-float-literal value [float32!]
				]
				literal-pointer? [
					unless all [spec compiler/job/PIC? not emitter/libc-init?][
					either spec [emit-load-literal-ptr spec/2][emit-load value]
					]
				]
				true [
					source-type: compiler/resolve-aliased compiler/get-type value
					emit-load value
					case [
						all [type/1 = 'int64! compiler/signed-integer? source-type not wide-type? source-type][
							emit-i32 #{93407C00}           ; SXTW x0, w0
						]
						all [float32-type? type compiler/any-float? source-type not float32-type? source-type][
							emit-i32 #{1E624000}               ; FCVT s0, d0
						]
						all [compiler/any-float? type not float32-type? type float32-type? source-type][
							emit-i32 #{1E22C000}               ; FCVT d0, s0
						]
					]
				]
			]
		]
		either emitter/local-offset? name [
			emit-store-local name type
		][
			emit-store-global name type
		]
	]

	emit-float-register-cast: func [source-type target-type [block!] reg [integer!]][
		if (float32-type? source-type) <> (float32-type? target-type) [
			emit-i32 (to integer! either float32-type? target-type [#{1E624000}][#{1E22C000}])
				or (reg * 33)                                    ; FCVT sN,dN / dN,sN
		]
	]

	emit-load-float-alt: func [
		value source-type type [block!] result-single? [logic!]
		/local raw source-single? target-single? wide?
	][
		raw: compiler/unbox/deep value
		if object? value [
			source-type: compiler/resolve-aliased compiler/get-type value/data
		]
		source-single?: float32-type? source-type
		target-single?: float32-type? type
		if compiler/integer-type? source-type [
			wide?: compiler/int64? source-type
			case [
				integer? raw [
					either wide? [
						emit-mov-imm64/reg raw source-type/1 1
					][
						emit-mov-imm32/reg raw 1
					]
				]
				issue? raw [
					emit-mov-imm64/reg raw source-type/1 1
				]
				word? raw [
					either emitter/local-offset? raw [
						emit-load-local/reg raw source-type 1
					][
						unless select emitter/symbols raw [
							raw: compiler/resolve-ns raw
						]
						emit-load-global/reg raw source-type 1
					]
				]
				path? raw [
					emit-i32 either result-single? [#{1E204002}][#{1E604002}] ; preserve s0/d0 in v2
					emitter/access-path raw none
					emit-i32 either wide? [#{AA0003E1}][#{2A0003E1}] ; MOV x1/w1, x0/w0
					emit-i32 either result-single? [#{1E204040}][#{1E604040}] ; restore v0 from v2
				]
				true [compiler/throw-error ["ARM64 alternate integer-to-float load is not implemented for:" mold raw]]
			]
			emit-int-to-float/reg source-type type 1
			exit
		]
		case [
			any [decimal? raw issue? raw] [
				emit-load-float-literal/reg raw type 1
				exit
			]
			word? raw [
				either emitter/local-offset? raw [
					emit-load-local/reg raw source-type 1
				][
					emit-load-global/reg raw source-type 1
				]
			]
			path? raw [
				emit-i32 either result-single? [#{1E204002}][#{1E604002}] ; preserve s0/d0 in v2
				emitter/access-path raw none
				emit-i32 either source-single? [#{1E204001}][#{1E604001}] ; source to s1/d1
				emit-float-register-cast source-type type 1
				emit-i32 either result-single? [#{1E204040}][#{1E604040}] ; restore v0 from v2
				exit
			]
			true [compiler/throw-error ["ARM64 alternate float load is not implemented for:" mold raw]]
		]
		emit-float-register-cast source-type type 1
	]

	emit-int-to-float: func [
		from-type to-type [block!]
		/reg index [integer!]
		/from source-index [integer!]
		/local wide? single? signed-cast? opcode
	][
		index: any [index 0]
		source-index: any [source-index index]
		from-type: compiler/resolve-aliased from-type
		to-type: compiler/resolve-aliased to-type
		wide?: compiler/int64? from-type
		single?: float32-type? to-type
		signed-cast?: compiler/signed-integer? from-type
		opcode: either wide? [
			either signed-cast? [
				either single? [#{9E220000}][#{9E620000}]
			][
				either single? [#{9E230000}][#{9E630000}]
			]
		][
			either signed-cast? [
				either single? [#{1E220000}][#{1E620000}]
			][
				either single? [#{1E230000}][#{1E630000}]
			]
		]
		emit-i32 (opcode-int opcode) or index or (source-index * 32)
	]

	emit-float-operation: func [
		name [word!] args [block!]
		/local type right-type op-type source-type left-source-type right-source-type right left
			nested-right? nested-left? single? saved? opcode
	][
		type: compiler/resolve-aliased compiler/resolve-expr-type args/1
		right-type: compiler/resolve-aliased compiler/resolve-expr-type args/2
		single?: to logic! any [float32-type? type float32-type? right-type]
		op-type: reduce [either single? ['float32!]['float!]]
		right: compiler/unbox args/2
		left: compiler/unbox args/1
		nested-right?: any [block? right right = <last>]
		nested-left?: any [block? left left = <last>]
		saved?: last-saved?
		left-source-type: either object? args/1 [
			compiler/resolve-aliased compiler/get-type args/1/data
		][type]
		right-source-type: either object? args/2 [
			compiler/resolve-aliased compiler/get-type args/2/data
		][right-type]

		if all [
			nested-right?
			object? args/2
			compiler/integer-type? source-type: compiler/resolve-expr-type args/2/data
		][
			emit-int-to-float/reg/from source-type op-type either saved? [1][0] 0
		]
		if all [
			nested-left?
			object? args/1
			compiler/integer-type? left-source-type
		][
			emit-int-to-float left-source-type op-type
		]
		if all [nested-left? compiler/any-float? left-source-type][
			emit-float-register-cast left-source-type op-type 0
		]
		if all [nested-right? compiler/any-float? right-source-type][
			emit-float-register-cast right-source-type op-type either saved? [1][0]
		]
		if all [nested-right? not saved?][
			emit-i32 either single? [#{1E204001}][#{1E604001}] ; FMOV s1/d1, s0/d0
		]
		last-saved?: no
		unless nested-left? [
			emit-load args/1
			if compiler/any-float? type [emit-float-register-cast type op-type 0]
		]
		unless nested-right? [emit-load-float-alt args/2 right-source-type op-type single?]

		either find comparison-op name [
			signed?: yes
			emit-i32 either single? [#{1E212000}][#{1E612000}] ; FCMP s0/d0, s1/d1
		][
			opcode: select either single? [[
				+ #{1E212800} - #{1E213800} * #{1E210800} / #{1E211800}
			]][[
				+ #{1E612800} - #{1E613800} * #{1E610800} / #{1E611800}
			]] name
			unless opcode [compiler/throw-error ["ARM64 float op is not implemented:" mold name]]
			emit-i32 opcode
		]
	]

	emit-variable: func [name [word! object!]][emit-load name]

	emit-memory-address-offset: func [base [integer!] offset [integer!] /local scratch][
		scratch: either base = 16 [17][16]
		emit-register-offset base 0 offset scratch
	]

	emit-load-memory: func [type [block!] base offset [integer!] /local opcode][
		type: compiler/resolve-aliased type
		if any [offset < -256 offset > 255][
			emit-memory-address-offset base offset
			base: offset: 0
		]
		opcode: switch/default type/1 [
			byte!       [#{38400000}]
			logic!      [#{38400000}]
			int8!       [#{38C00000}]
			uint8!      [#{38400000}]
			int16!      [#{78C00000}]
			uint16!     [#{78400000}]
			integer!    [#{B8400000}]
			int32!      [#{B8400000}]
			uint32!     [#{B8400000}]
			int64!      [#{F8400000}]
			uint64!     [#{F8400000}]
			pointer!    [#{F8400000}]
			c-string!   [#{F8400000}]
			function!   [#{F8400000}]
			subroutine! [#{F8400000}]
			struct!     [#{F8400000}]
			union!      [#{F8400000}]
			float32!    [#{BC400000}]
			float!      [#{FC400000}]
			float64!    [#{FC400000}]
		][compiler/throw-error ["ARM64 memory load type is not implemented:" mold type/1]]
		emit-i32 (opcode-int opcode) or ((offset and 511) * 4096) or (base * 32)
	]

	emit-store-memory: func [type [block!] base offset [integer!] /local opcode value-reg][
		type: compiler/resolve-aliased type
		if any [offset < -256 offset > 255][
			emit-memory-address-offset base offset
			base: offset: 0
		]
		value-reg: 2
		opcode: switch/default type/1 [
			byte!       [#{38000000}]
			logic!      [#{38000000}]
			int8!       [#{38000000}]
			uint8!      [#{38000000}]
			int16!      [#{78000000}]
			uint16!     [#{78000000}]
			integer!    [#{B8000000}]
			int32!      [#{B8000000}]
			uint32!     [#{B8000000}]
			int64!      [#{F8000000}]
			uint64!     [#{F8000000}]
			pointer!    [#{F8000000}]
			c-string!   [#{F8000000}]
			function!   [#{F8000000}]
			subroutine! [#{F8000000}]
			struct!     [#{F8000000}]
			union!      [#{F8000000}]
			float32!    [#{BC000000}]
			float!      [#{FC000000}]
			float64!    [#{FC000000}]
		][compiler/throw-error ["ARM64 memory store type is not implemented:" mold type/1]]
		emit-i32 (opcode-int opcode) or ((offset and 511) * 4096) or (base * 32) or value-reg
	]

	emit-pointer-index-address: func [idx pointee [block!] /local scale][
		if idx = 'value [idx: 1]
		scale: emitter/size-of? pointee
		either integer? idx [
			emit-memory-address-offset 0 (idx - 1) * scale
		][
			emit-load-alt idx [integer!]
			emit-i32 #{51000421}                              ; SUB w1, w1, #1
			emit-i32 #{93407C21}                              ; SXTW x1, w1
			if scale > 1 [
				emit-mov-imm32/reg scale 16
				emit-i32 #{9B107C21}                           ; MUL x1, x1, x16
			]
			emit-i32 #{8B010000}                              ; ADD x0, x0, x1
		]
	]

	emit-init-path: func [name [word! get-word!]][emit-load to word! name]

	emit-access-path: func [
		path [path! set-path!] spec [block! none!] /short
		/local name type field offset aggregate? address? alias
	][
		unless spec [
			name: to word! path/1
			spec: second compiler/resolve-type name
			emit-load name
		]
		if short [return spec]
		type: compiler/resolve-type/with path/2 spec
		if all [block? type 'value = last type alias: compiler/find-aliased type/1][
			type: append copy alias 'value
		]
		field: select spec path/2
		offset: emitter/member-offset? spec path/2
		if set-path? path [emit-store-union-tag spec path/2 0]
		aggregate?: all [find [struct! union!] type/1 'value = last field]
		address?: all [get-word? first head path tail? skip path 2]
		either any [aggregate? address?] [
			if positive? offset [emit-memory-address-offset 0 offset]
		][
			emit-load-memory type 0 offset
		]
	]

	emit-load-path: func [path [path!] type [word!] parent [block! none!] /local full pointee][
		switch type [
			struct! union! [emit-access-path path parent]
			pointer! c-string! [
				full: either parent [
					compiler/resolve-type/with path/1 parent
				][
					emit-load path/1
					compiler/resolve-type path/1
				]
				pointee: either type = 'c-string! [[byte!]][full/2]
				emit-pointer-index-address path/2 pointee
				emit-load-memory pointee 0 0
			]
		]
	]

	emit-move-path-alt: func [/pair /with type [block!] /local resolved][
		resolved: compiler/resolve-aliased/silent any [type compiler/last-type]
		either all [resolved compiler/any-float? resolved] [
			emit-i32 either float32-type? resolved [#{1E204002}][#{1E604002}] ; FMOV s2/d2, s0/d0
		][
			emit-i32 #{AA0003E2}                              ; MOV x2, x0
		]
	]

	emit-store-path: func [
		path [set-path!] kind [word!] value parent [block! none!]
		/local full type pointee offset base-spec field alias slots hfa aggregate-size remaining width opcode i field-size inline?
	][
		if all [
			value = <last>
			block? compiler/last-type
			'value = last compiler/last-type
		][
			slots: emitter/struct-slots? compiler/last-type
			hfa: homogeneous-aggregate? compiler/last-type
			if all [slots > 2 not hfa/1][exit]          ; callee wrote through the hidden destination
			either hfa/1 [
				repeat i hfa/3 [
					emit-i32 (to integer! either hfa/2 [#{1E204008}][#{1E604008}])
						or ((i - 1) * 33)                    ; FMOV v(8+i-1), v(i-1)
				]
			][
				emit-i32 #{AA0003E2}                       ; MOV x2, x0
				if slots = 2 [emit-i32 #{AA0103E3}]        ; MOV x3, x1
			]
			unless base-spec: parent [base-spec: emit-access-path/short path parent]
			type: compiler/resolve-type/with path/2 base-spec
			if all [block? type 'value = last type alias: compiler/find-aliased type/1][
				type: append copy alias 'value
			]
			field: select base-spec path/2
			offset: emitter/member-offset? base-spec path/2
			inline?: all [find [struct! union!] type/1 'value = last field]
			unless inline? [
				emit-load-memory [uint64!] 0 offset
				offset: 0
			]
			either hfa/1 [
				field-size: either hfa/2 [4][8]
				opcode: either hfa/2 [#{BC000000}][#{FC000000}]
				repeat i hfa/3 [
					emit-i32 (opcode-int opcode)
						or ((offset + ((i - 1) * field-size)) * 4096)
						or ((i + 7))
				]
			][
				aggregate-size: emitter/size-of? compiler/last-type
				repeat i slots [
					remaining: aggregate-size - ((i - 1) * stack-width)
					width: min stack-width remaining
					opcode: switch width [
						1 [#{38000000}]
						2 [#{78000000}]
						4 [#{B8000000}]
						8 [#{F8000000}]
					]
					emit-i32 (opcode-int opcode)
						or ((offset + ((i - 1) * stack-width)) * 4096)
						or (i + 1)
				]
			]
			exit
		]
		base-spec: parent
		if value <> <last> [
			unless parent [emit-init-path path/1]
			emit-i32 #{D10043FF}                              ; SUB sp, sp, #16
			emit-i32 #{F90003E0}                              ; STR x0, [sp]
			emit-load value
			emit-move-path-alt/with either object? value [value/type][compiler/last-type]
			emit-i32 #{F94003E0}                              ; LDR x0, [sp]
			emit-i32 #{910043FF}                              ; ADD sp, sp, #16
		]
		if all [value = <last> not parent][
			emit-move-path-alt/with compiler/last-type
			emit-init-path path/1
		]

		switch kind [
			pointer! c-string! [
				full: either parent [compiler/resolve-type/with path/1 parent][compiler/resolve-type path/1]
				pointee: either kind = 'c-string! [[byte!]][full/2]
				emit-pointer-index-address path/2 pointee
				emit-store-memory pointee 0 0
			]
			struct! union! [
				unless base-spec [base-spec: second compiler/resolve-type to word! path/1]
				emit-store-union-tag base-spec path/2 0
				type: compiler/resolve-type/with path/2 base-spec
				if all [block? type 'value = last type alias: compiler/find-aliased type/1][
					type: append copy alias 'value
				]
				field: select base-spec path/2
				offset: emitter/member-offset? base-spec path/2
				if all [find [struct! union!] type/1 'value = last field][exit]
				emit-store-memory type 0 offset
			]
		]
	]

	emit-store-union-tag: func [spec [block!] name [word!] reg [integer!] /local id tag type opcode][
		if all [compiler/tagged-union? spec id: compiler/union-variant-id? spec name][
			tag: compiler/union-tag-type? spec
			type: tag/1
			emit-mov-imm32/reg id 17
			opcode: switch type [
				uint8!  [#{38000011}]
				uint16! [#{78000011}]
				uint32! [#{B8000011}]
			]
			emit-i32 (opcode-int opcode) or (reg * 32)
		]
	]

	emit-load-union-tag: func [spec [block!] /local tag type][
		tag: compiler/union-tag-type? spec
		type: tag/1
		emit-load-memory reduce [type] 0 0
	]

	emit-variant-check: func [spec [block!] id [integer!]][
		emit-load-union-tag spec
		if id <= 4095 [
			emit-i32 (to integer! #{7100001F}) or (id * 1024)
		][
			emit-mov-imm32/reg id 1
			emit-i32 #{6B01001F}
		]
		emit-cset 0                                           ; EQ
	]

	emit-push-struct: func [
		slots [integer!]
		/aggregate type [block!]
		/returned
		/local hfa field-type field-size i descriptor register-result?
	][
		hfa: homogeneous-aggregate? any [type compiler/last-type]
		register-result?: all [returned any [hfa/1 slots <= 2]]
		case [
			all [register-result? hfa/1] [
				field-type: reduce [either hfa/2 ['float32!]['float!]]
				for i hfa/3 1 -1 [
					emit-i32 #{D10043FF}                          ; SUB sp, sp, #16
					emit-i32 (to integer! either hfa/2 [#{BC0003E0}][#{FC0003E0}])
						or (i - 1)                                  ; STR sN/dN, [sp]
					descriptor: reduce [field-type/1 'arm64-aggregate 'hfa hfa/3 i]
					append/only call-arg-types descriptor
					call-arg-index: call-arg-index + 1
				]
			]
			register-result? [
				for i slots 1 -1 [
					emit-i32 #{D10043FF}                          ; SUB sp, sp, #16
					emit-i32 (to integer! #{F90003E0}) or (i - 1) ; STR xN, [sp]
					descriptor: reduce ['uint64! 'arm64-aggregate 'integer slots i]
					append/only call-arg-types descriptor
					call-arg-index: call-arg-index + 1
				]
			]
			hfa/1 [
				emit-i32 #{AA0003E3}                          ; MOV x3, x0
				field-type: reduce [either hfa/2 ['float32!]['float!]]
				field-size: either hfa/2 [4][8]
				for i hfa/3 1 -1 [
					emit-load-memory field-type 3 (i - 1) * field-size
					emit-i32 #{D10043FF}                      ; SUB sp, sp, #16
					emit-i32 either hfa/2 [#{BC0003E0}][#{FC0003E0}]
					descriptor: reduce [field-type/1 'arm64-aggregate 'hfa hfa/3 i]
					append/only call-arg-types descriptor
					call-arg-index: call-arg-index + 1
				]
			]
			true [
				emit-i32 #{AA0003E3}                          ; MOV x3, x0
				for i slots 1 -1 [
					emit-load-memory [uint64!] 3 (i - 1) * stack-width
					emit-i32 #{D10043FF}                      ; SUB sp, sp, #16
					emit-i32 #{F90003E0}                      ; STR x0, [sp]
					descriptor: reduce ['uint64! 'arm64-aggregate 'integer slots i]
					append/only call-arg-types descriptor
					call-arg-index: call-arg-index + 1
				]
			]
		]
	]

	emit-push-struct-ref: func [slots [integer!] /local offset i slot-offset][
		if call-struct-temp-slots < slots [
			compiler/throw-error "ARM64 struct argument temporary stack space was not reserved"
		]
		offset: ((length? call-arg-types) * 16)
			+ ((call-struct-temp-slots - slots) * stack-width)
		emit-sp-offset-address 16 offset 0
		repeat i slots [
			slot-offset: (i - 1) * stack-width
			either slot-offset <= 32760 [
				emit-i32 (to integer! #{F9400011}) or ((i - 1) * 1024) ; LDR x17, [x0, #slot]
				emit-i32 (to integer! #{F9000211}) or ((i - 1) * 1024) ; STR x17, [x16, #slot]
			][
				emit-register-offset 0 15 slot-offset 15
				emit-i32 #{F94001F1}                              ; LDR x17, [x15]
				emit-register-offset 16 15 slot-offset 15
				emit-i32 #{F90001F1}                              ; STR x17, [x15]
			]
		]
		call-struct-temp-slots: call-struct-temp-slots - slots
		emit-i32 #{AA1003E0}                                  ; MOV x0, x16
		emit-i32 #{D10043FF}                                  ; SUB sp, sp, #16
		emit-i32 #{F90003E0}                                  ; STR x0, [sp]
		append/only call-arg-types [pointer! [byte!]]
		call-arg-index: call-arg-index + 1
	]

	classify-hfa-member: func [type [block!] /local resolved][
		resolved: compiler/resolve-aliased type
		case [
			find [float! float64!] resolved/1 [reduce [yes no 1]]
			resolved/1 = 'float32! [reduce [yes yes 1]]
			all [find [struct! union!] resolved/1 'value = last type] [
				classify-hfa-fields resolved
			]
			true [reduce [no no 0]]
		]
	]

	classify-hfa-fields: func [
		resolved [block!]
		/local members union? kind count valid? name field nested
	][
		union?: resolved/1 = 'union!
		members: resolved/2
		if all [not empty? members block? members/1][members: next members]
		if union? [members: compiler/union-members members]
		kind: none
		count: 0
		valid?: yes
		foreach [name field] members [
			nested: classify-hfa-member field
			unless nested/1 [valid?: no break]
			if all [logic? kind kind <> nested/2][valid?: no break]
			kind: nested/2
			count: either union? [max count nested/3][count + nested/3]
		]
		reduce [all [valid? count >= 1 count <= 4] any [kind no] count]
	]

	homogeneous-aggregate?: func [type [block!] /local resolved][
		resolved: compiler/resolve-aliased type
		unless find [struct! union!] resolved/1 [return reduce [no no 0]]
		classify-hfa-fields resolved
	]

	emit-move-alt: func [wide? [logic!]][
		emit-i32 either wide? [#{AA0003E1}][#{2A0003E1}] ; MOV x1/w1, x0/w0
	]

	emit-normalize-fixed-int-result: func [
		type [block!] /reg index [integer!]
		/local bits opcode
	][
		index: any [index 0]
		bits: index * 33
		switch type/1 [
			byte!  [opcode: #{53001C00}]                       ; UXTB wN, wN
			int8!  [opcode: #{13001C00}]                       ; SXTB wN, wN
			uint8! [opcode: #{53001C00}]                       ; UXTB wN, wN
			int16! [opcode: #{13003C00}]                       ; SXTH wN, wN
			uint16! [opcode: #{53003C00}]                      ; UXTH wN, wN
		]
		if opcode [emit-i32 (opcode-int opcode) or bits]
	]

	emit-divide-by-zero-check: func [wide? [logic!] /local spec][
		unless compiler/job/debug? [exit]
		spec: emitter/symbols/***-on-div-error
		emit-i32 either wide? [#{F100003F}][#{7100003F}] ; CMP x1/w1, #0
		emit-i32 encode-branch 12 1                       ; B.NE divide
		emit-mov-imm32 13                                 ; integer divide by zero
		append spec/3 emitter/tail-ptr
		unless empty? emitter/chunks/queue [
			append/only second last emitter/chunks/queue back tail spec/3
		]
		emit-i32 #{94000000}                              ; BL ***-on-div-error
	]

	emit-load-alt: func [
		value type [block!]
		/local raw info source-type load-type single? wide? signed-cast? opcode
	][
		raw: compiler/unbox/deep value
		source-type: all [object? value compiler/resolve-aliased compiler/get-type value/data]
		if any [char? raw logic? raw][raw: to integer! raw]
		if all [
			compiler/integer-type? type
			any [
				decimal? raw
				all [
					object? value
					compiler/any-float? source-type
				]
			]
		][
			if decimal? raw [source-type: [float!]]
			single?: float32-type? source-type
			case [
				any [decimal? raw issue? raw] [emit-load-float-literal/reg raw source-type 1]
				word? raw [
					either emitter/local-offset? raw [
						emit-load-local/reg raw source-type 1
					][
						emit-load-global/reg raw source-type 1
					]
				]
				path? raw [
					emit-i32 #{AA0003E2}                           ; preserve x0
					emitter/access-path raw none
					emit-i32 either single? [#{1E204001}][#{1E604001}]
					emit-i32 #{AA0203E0}                           ; restore x0
				]
				true [compiler/throw-error ["ARM64 alternate float cast is not implemented for:" mold raw]]
			]
			wide?: any [compiler/int64? type compiler/any-pointer? type]
			signed-cast?: compiler/signed-integer? type
			opcode: either wide? [
				either signed-cast? [
					either single? [#{9E380000}][#{9E780000}]
				][
					either single? [#{9E390000}][#{9E790000}]
				]
			][
				either signed-cast? [
					either single? [#{1E380000}][#{1E780000}]
				][
					either single? [#{1E390000}][#{1E790000}]
				]
			]
			emit-i32 (opcode-int opcode) or 33                 ; FCVTZ[S/U] x1/w1, s1/d1
			switch type/1 [
				byte! uint8! [emit-i32 #{53001C21}]              ; UXTB w1, w1
				int8!       [emit-i32 #{13001C21}]              ; SXTB w1, w1
				uint16!     [emit-i32 #{53003C21}]              ; UXTH w1, w1
				int16!      [emit-i32 #{13003C21}]              ; SXTH w1, w1
			]
			exit
		]
		load-type: any [source-type type]
		case [
			integer? raw [
				either find [int64! uint64!] load-type/1 [
					emit-mov-imm64/reg raw load-type/1 1
				][
					emit-mov-imm32/reg raw 1
				]
			]
			issue? raw [
				info: compiler/int64-literal-info raw
				unless info [compiler/throw-error ["ARM64 alternate issue literal is not implemented:" mold raw]]
				emit-mov-imm64/reg raw info/1 1
			]
			word? raw [
				either emitter/local-offset? raw [
					emit-load-local/reg raw load-type 1
				][
					unless select emitter/symbols raw [
						raw: compiler/resolve-ns raw
					]
					emit-load-global/reg raw load-type 1
				]
			]
			path? raw [
				emit-i32 #{AA0003E2}                           ; preserve x0
				emitter/access-path raw none
				emit-i32 either wide-type? load-type [#{AA0003E1}][#{2A0003E1}]
				emit-i32 #{AA0203E0}                           ; restore x0
			]
			true [compiler/throw-error ["ARM64 alternate load is not implemented for:" mold raw]]
		]
		case [
			type/1 = 'logic! [
				emit-i32 either wide-type? load-type [#{F100003F}][#{7100003F}] ; CMP x1/w1, #0
				emit-i32 #{1A9F07E1}                          ; CSET w1, NE
			]
			compiler/integer-type? type [
				switch type/1 [
					byte! uint8! [emit-i32 #{53001C21}]          ; UXTB w1, w1
					int8!       [emit-i32 #{13001C21}]          ; SXTB w1, w1
					uint16!     [emit-i32 #{53003C21}]          ; UXTH w1, w1
					int16!      [emit-i32 #{13003C21}]          ; SXTH w1, w1
				]
				if all [wide-type? type compiler/signed-integer? load-type not wide-type? load-type][
					emit-i32 #{93407C21}                          ; SXTW x1, w1
				]
			]
			all [compiler/any-pointer? type compiler/signed-integer? load-type not wide-type? load-type][
				emit-i32 #{93407C21}                          ; SXTW x1, w1
			]
		]
	]

	emit-integer-operation: func [
		name [word!] args [block!]
		/local type right-type right left nested-right? nested-left? saved? imm? wide? opcode mod-kind scale pointer-op? limit op-key
	][
		type: compiler/resolve-aliased compiler/resolve-expr-type args/1
		right-type: compiler/resolve-aliased compiler/resolve-expr-type args/2
		set-width/type type/1
		signed?: compiler/signed-integer? type
		wide?: wide-type? type
		right: compiler/unbox args/2
		left: compiler/unbox args/1
		nested-right?: any [block? right right = <last>]
		nested-left?: any [block? left left = <last>]
		if any [char? right logic? right][right: to integer! right]
		imm?: integer? right
		if object? args/2 [imm?: no]
		scale: 1
		pointer-op?: all [
			find [+ -] name
			find [pointer! c-string! struct! union! any-pointer!] type/1
			not compiler/any-pointer? right-type
		]
		if pointer-op? [
			scale: switch/default type/1 [
				pointer! [emitter/size-of? type/2]
				c-string! [1]
				struct! [emitter/member-offset? type/2 none]
				union! [emitter/union-size? type/2]
			][1]
			if imm? [right: right * scale]
		]

		saved?: last-saved?
		if all [nested-right? object? args/2][emit-casting args/2 saved?]
		if nested-right? [
			unless saved? [emit-move-alt wide?]
		]
		last-saved?: no

		unless nested-left? [
			emit-load args/1
		]
		if all [nested-left? object? args/1][emit-casting args/1 no]

		;-- A64 arithmetic immediates are unsigned 12-bit values. Other operators
		;-- use the same register path as non-literal right operands.
		if all [
			imm?
			any [
				not any [find [+ -] name find comparison-op name]
				right < 0
				right > 4095
			]
		][
			imm?: no
		]
		unless imm? [
			unless any [block? right right = <last>][
				emit-load-alt args/2 right-type
			]
			if all [wide? not wide-type? right-type compiler/signed-integer? right-type][
				emit-i32 #{93407C21}                          ; SXTW x1, w1
			]
			if pointer-op? [
				unless compiler/int64? right-type [emit-i32 #{93407C21}] ; SXTW x1, w1
				if scale > 1 [
					emit-mov-imm32/reg scale 16
					emit-i32 #{9B107C21}                       ; MUL x1, x1, x16
				]
			]
		]

		mod-kind: select mod-rem-func name
		if any [name = divide-sym mod-kind][
			emit-divide-by-zero-check wide?
			if all [compiler/overflow-check? signed? width = 4][
				emit-i32 #{3100043F}                          ; CMN w1, #1
				emit-i32 encode-branch 16 1                  ; B.NE divide
				emit-i32 #{52B00010}                          ; MOV w16, #80000000h
				emit-i32 #{6B10001F}                          ; CMP w0, w16
				emit-overflow-branch 0                       ; B.EQ overflow
			]
			if mod-kind [
				emit-i32 either wide? [#{AA0003E2}][#{2A0003E2}] ; preserve dividend
			]
			opcode: either wide? [
				either signed? [#{9AC10C00}][#{9AC10800}]
			][
				either signed? [#{1AC10C00}][#{1AC10800}]
			]
			either mod-kind [
				emit-i32 ((opcode-int opcode) or 3)         ; quotient in x3/w3
				emit-i32 either wide? [#{9B018860}][#{1B018860}] ; dividend - quotient * divisor
				if all [signed? mod-kind = 'mod][
					emit-i32 either wide? [#{F100001F}][#{7100001F}] ; CMP x0/w0, #0
					emit-i32 encode-branch 16 5                 ; B.PL done
					emit-i32 either wide? [#{F100003F}][#{7100003F}] ; CMP x1/w1, #0
					emit-i32 either wide? [#{DA815421}][#{5A815421}] ; CNEG x1/w1, x1/w1, MI
					emit-i32 either wide? [#{8B010000}][#{0B010000}] ; ADD x0/w0, x0/w0, x1/w1
				]
			][
				emit-i32 opcode
			]
			emit-normalize-fixed-int-result type
			last-math-op: divide-sym
			last-math-wide?: wide?
			last-math-signed?: signed?
			last-math-width: width
			exit
		]

		;-- Logical shifts of signed narrow values operate on their fixed-width
		;-- representation rather than on the sign extension in the full register.
		if all [name = '-** signed? width < 4][
			emit-i32 either width = 1 [#{53001C00}][#{53003C00}]
		]

		case [
			find comparison-op name [
				either imm? [
					opcode: either wide? [#{F100001F}][#{7100001F}]
					emit-i32 (opcode-int opcode) or (right * 1024)
				][
					emit-i32 either wide? [#{EB01001F}][#{6B01001F}]
				]
			]
			all [imm? find [+ -] name] [
				opcode: either wide? [
					either name = '- [#{F1000000}][#{B1000000}]
				][
					either name = '- [#{71000000}][#{31000000}]
				]
				emit-i32 (opcode-int opcode) or (right * 1024)
			]
			true [
				unless imm? [
					if all [compiler/overflow-check? name = left-shift-sym width = 4][
						emit-i32 #{2A0003E3}                  ; MOV w3, w0
					]
					either name = '* [
					;-- Keep the full product in x3 for system/cpu/overflow?.
					;-- x2 is used to preserve left operands while evaluating expressions.
					either wide? [
						emit-i32 either signed? [#{9B417C03}][#{9BC17C03}] ; SMULH/UMULH x3
						emit-i32 #{9B017C00}                  ; MUL x0, x0, x1
					][
						emit-i32 either signed? [#{9B217C03}][#{9BA17C03}] ; SMULL/UMULL x3
						emit-i32 #{2A0303E0}                  ; MOV w0, w3
					]
				][
					op-key: either all [find [>>] name not signed?][first [-**]][name]
					opcode: select either wide? [[
						+ #{AB010000} - #{EB010000}
						and #{8A010000} or #{AA010000} xor #{CA010000}
						<< #{9AC12000} >> #{9AC12800} -** #{9AC12400}
					]][[
						+ #{2B010000} - #{6B010000}
						and #{0A010000} or #{2A010000} xor #{4A010000}
						<< #{1AC12000} >> #{1AC12800} -** #{1AC12400}
					]] op-key
					unless opcode [compiler/throw-error ["ARM64 integer op is not implemented:" mold name]]
					emit-i32 opcode
				]
				]
			]
		]
		if all [compiler/overflow-check? name = left-shift-sym][
			either width = 4 [
				emit-i32 either signed? [#{1AC12802}][#{1AC12402}] ; ASRV/LSRV w2, w0, w1
				emit-i32 #{6B03005F}                          ; CMP w2, w3
				emit-overflow-branch 1                       ; B.NE overflow
			][
				limit: either width = 1 [255][65535]
				emit-mov-imm32/reg limit 16
				emit-i32 #{6B10001F}                          ; CMP w0, w16
				emit-overflow-branch 8                       ; B.HI overflow
			]
		]
		if all [compiler/overflow-check? find [+ - *] name][
			case [
				all [find [4 8] width name = '*][
					either signed? [
						emit-i32 either width = 8 [
							#{937FFC01}                          ; ASR x1, x0, #63
						][
							#{93407C01}                          ; SXTW x1, w0
						]
						emit-i32 #{EB01007F}                  ; CMP x3, x1
					][
						emit-i32 either width = 8 [
							#{F100007F}                          ; CMP x3, #0
						][
							#{EB00007F}                          ; CMP x3, x0
						]
					]
					emit-overflow-branch 1                   ; B.NE overflow
				]
				find [4 8] width [
					emit-overflow-branch case [
						signed? [6]                         ; B.VS
						name = '+ [2]                       ; B.CS
						true [3]                            ; B.CC
					]
				]
				signed? [
					limit: either width = 1 [127][32767]
					emit-mov-imm32/reg limit 16
					emit-i32 #{6B10001F}                          ; CMP w0, w16
					emit-overflow-branch 12                      ; B.GT overflow
					limit: either width = 1 [-128][-32768]
					emit-mov-imm32/reg limit 16
					emit-i32 #{6B10001F}                          ; CMP w0, w16
					emit-overflow-branch 11                      ; B.LT overflow
				]
				all [not signed? name = '-][
					emit-overflow-branch 3                       ; B.CC overflow
				]
				true [
					limit: either width = 1 [255][65535]
					emit-mov-imm32/reg limit 16
					emit-i32 #{6B10001F}                          ; CMP w0, w16
					emit-overflow-branch 8                       ; B.HI overflow
				]
			]
		]
		unless find comparison-op name [emit-normalize-fixed-int-result type]
		last-math-op: name
		last-math-wide?: wide?
		last-math-signed?: signed?
		last-math-width: width
	]

	condition-code: func [op [word!] /local row][
		row: find conditions op
		if any [not row row/2 = '-][compiler/throw-error ["ARM64 condition is not implemented:" mold op]]
		either signed? [row/2][row/3]
	]

	emit-cset: func [cond [integer!] /reg index [integer!]][
		index: any [index 0]
		emit-i32 (to integer! #{1A9F07E0}) or (((cond xor 1) and 15) * 4096) or index
	]

	encode-branch: func [delta [integer!] cond [integer! none!] /local imm][
		unless zero? delta // 4 [compiler/throw-error "unaligned ARM64 branch"]
		imm: delta / 4
		either cond [
			if any [imm < -262144 imm > 262143][compiler/throw-error "ARM64 conditional branch is out of range"]
			(to integer! #{54000000}) or ((imm and 524287) * 32) or cond
		][
			if any [imm < -33554432 imm > 33554431][compiler/throw-error "ARM64 branch is out of range"]
			(to integer! #{14000000}) or (imm and 67108863)
		]
	]

	encode-adr: func [delta [integer!] reg [integer!] /local encoded][
		if any [delta < -1048576 delta > 1048575][
			compiler/throw-error "ARM64 ADR target is out of range"
		]
		encoded: delta and 2097151
		(to integer! #{10000000})
			or ((encoded and 3) * 536870912)
			or (((encoded / 4) and 524287) * 32)
			or reg
	]

	emit-branch: func [
		code [binary!] op [word! block! logic! none!]
		offset [integer! none!] parity [logic! none!]
		/back?
		/local distance cond original keep? bytes far-distance
	][
		distance: (length? code) - any [offset 0]
		cond: none
		unless none? op [
			original: op
			keep?: block? op
			op: case [
				keep? [either logic? op/1 [pick [= <>] op/1][op/1]]
				logic? op [pick [= <>] op]
				true [opposite? op]
			]
			cond: either all [parity not logic? original][
				;-- FCMP sets NZCV=0011 for unordered operands. These mappings
				;-- make ordered comparisons false while preserving <> as true.
				select either keep? [[
					= 0 <> 1 < 4 <= 9 > 12 >= 10
				]][[
					= 1 <> 0 < 5 <= 8 > 13 >= 11
				]] either keep? [op][original]
			][
				condition-code op
			]
		]
		distance: either back? [negate distance][distance + 4]
		if all [cond any [distance < -1048576 distance > 1048572]][
			bytes: make binary! 8
			append bytes to-bin32 encode-branch 8 (cond xor 1)
			far-distance: either back? [distance - 4][distance]
			append bytes to-bin32 encode-branch far-distance none
			insert any [all [back? tail code] code] bytes
			return 8
		]
		insert any [all [back? tail code] code] to-bin32 encode-branch distance cond
		4
	]

	patch-jump-point: func [
		buffer [binary!] ptr [integer!] exit-point [integer!]
		/local bytes original cond
	][
		bytes: copy/part at buffer ptr 4
		reverse bytes
		original: to integer! bytes
		cond: either (original and (to integer! #{FF000000})) = (to integer! #{54000000})[
			original and 15
		][none]
		change/part at buffer ptr to-bin32 encode-branch exit-point - ptr cond 4
	]

	patch-jump-back: func [buffer [binary!] offset [integer!]][
		change/part at buffer offset to-bin32 encode-branch negate (offset - 1) none 4
	]

	emit-jump-point: func [type [block!]][
		append type emitter/tail-ptr
		unless empty? emitter/chunks/queue [
			append/only second last emitter/chunks/queue back tail type
		]
		emit-i32 #{14000000}
	]

	emit-save-last: does [
		last-saved?: no
		emit-i32 #{D10043FF}                                  ; SUB sp, sp, #16
		either compiler/any-float? compiler/last-type [
			saved-last-float?: yes
			saved-last-float32?: float32-type? compiler/last-type
			emit-i32 either saved-last-float32? [#{BC0003E0}][#{FC0003E0}] ; STUR s0/d0, [sp]
		][
			saved-last-float?: no
			saved-last-wide?: wide-type? compiler/resolve-aliased compiler/last-type
			emit-i32 #{F90003E0}                               ; STR x0, [sp]
		]
	]

	emit-restore-last: does [
		either saved-last-float? [
			emit-i32 either saved-last-float32? [#{1E204001}][#{1E604001}] ; FMOV s1/d1, s0/d0
			emit-i32 either saved-last-float32? [#{BC4003E0}][#{FC4003E0}] ; LDUR s0/d0, [sp]
		][
			emit-move-alt saved-last-wide?
			emit-i32 #{F94003E0}                               ; LDR x0, [sp]
		]
		emit-i32 #{910043FF}                                  ; ADD sp, sp, #16
		last-saved?: yes
	]

	emit-not: func [value /local raw type][
		raw: compiler/unbox value
		if block? raw [raw: <last>]
		type: compiler/resolve-aliased compiler/get-type value
		unless raw = <last> [emit-load value]
		either type/1 = 'logic! [
			emit-i32 #{52000000}                              ; EOR w0, w0, #1
		][
			unless compiler/integer-type? type [
				compiler/throw-error ["ARM64 NOT type is not implemented:" mold type/1]
			]
			emit-i32 either wide-type? type [#{AA2003E0}][#{2A2003E0}] ; MVN x0/w0, x0/w0
			emit-normalize-fixed-int-result type
		]
	]

	emit-boolean-switch: func [op [word! none!]][
		either op [
			emit-cset condition-code op
			reduce [0 0]
		][
			emit-mov-imm32 0
			emit-i32 encode-branch 8 none
			emit-mov-imm32 1
			reduce [4 12]
		]
	]

	emit-start-loop: func [spec [block! none!] name [word! none!]][
		either spec [
			emit-store-global spec/2 [integer!]
		][
			emit-store-local name [integer!]
		]
	]

	emit-end-loop: func [spec [block! none!] name [word! none!]][
		either spec [
			emit-load-global spec/2 [integer!]
		][
			emit-load-local name [integer!]
		]
		emit-i32 #{71000400}                                  ; SUBS w0, w0, #1
	]

	emit-get-overflow: does [
		case [
			last-math-op = divide-sym [emit-mov-imm32 0]
			last-math-op = '* [
				either last-math-wide? [
					either last-math-signed? [
						emit-i32 #{937FFC01}                  ; ASR x1, x0, #63
						emit-i32 #{EB01007F}                  ; CMP x3, x1
					][
						emit-i32 #{F100007F}                  ; CMP x3, #0
					]
				][
					either last-math-signed? [
						emit-i32 #{93407C61}                  ; SXTW x1, w3
						emit-i32 #{EB01007F}                  ; CMP x3, x1
					][
						emit-i32 #{2A0303E1}                  ; MOV w1, w3
						emit-i32 #{EB01007F}                  ; CMP x3, x1
					]
				]
				emit-cset 1                                  ; NE
			]
			true [
				emit-cset case [
					last-math-signed? [6]                  ; VS
					last-math-op = '+ [2]                  ; CS
					true [3]                                ; CC
				]
			]
		]
	]

	emit-overflow-epilog-no-ovf: does [
		emit-mov-imm32 0
		emit-i32 encode-branch 8 none                         ; skip true arm
	]

	emit-overflow-epilog-ovf: does [
		emit-mov-imm32 1
	]

	emit-overflow-branch: func [cond [integer!]][
		append last emitter/overflow-jumps emitter/tail-ptr
		unless empty? emitter/chunks/queue [
			append/only second last emitter/chunks/queue back tail last emitter/overflow-jumps
		]
		emit-i32 (opcode-int #{54000000}) or cond
	]

	emit-atomic-load: func [order [word!]][
		if verbose >= 3 [print [">>>emitting ATOMIC-LOAD" mold order]]
		emit-i32 #{88DFFC00}                                  ; LDAR w0, [x0]
		emit-i32 #{D5033BBF}                                  ; DMB ish
	]

	emit-atomic-store: func [value order [word!]][
		if verbose >= 3 [print [">>>emitting ATOMIC-STORE" mold value mold order]]
		emit-i32 #{AA0003E2}                                  ; MOV x2, x0
		emit-load value
		emit-i32 #{D5033BBF}                                  ; DMB ish
		emit-i32 #{889FFC40}                                  ; STLR w0, [x2]
	]

	emit-atomic-math: func [
		op [word!] right-op old? [logic!] ret? [logic!] order [word!]
		/local opcode
	][
		if verbose >= 3 [
			print [">>>emitting ATOMIC-MATH-OP" mold op mold right-op mold old? mold ret? mold order]
		]
		emit-i32 #{AA0003E3}                                  ; MOV x3, x0
		emit-load right-op
		emit-i32 #{2A0003E5}                                  ; MOV w5, w0
		emit-i32 #{D5033BBF}                                  ; DMB ish
		                                                            ; loop:
		emit-i32 #{885FFC61}                                  ;   LDAXR w1, [x3]
		opcode: switch op [
			add [#{0B050022}]                                   ;   ADD w2, w1, w5
			sub [#{4B050022}]                                   ;   SUB w2, w1, w5
			or  [#{2A050022}]                                   ;   ORR w2, w1, w5
			xor [#{4A050022}]                                   ;   EOR w2, w1, w5
			and [#{0A050022}]                                   ;   AND w2, w1, w5
		]
		emit-i32 opcode
		emit-i32 #{8804FC62}                                  ;   STLXR w4, w2, [x3]
		emit-i32 #{7100009F}                                  ;   CMP w4, #0
		emit-i32 encode-branch -16 1                          ;   B.NE loop
		emit-i32 #{D5033BBF}                                  ; DMB ish
		case [
			old? [emit-i32 #{2A0103E0}]                         ; MOV w0, w1
			ret? [emit-i32 #{2A0203E0}]                         ; MOV w0, w2
		]
	]

	emit-atomic-cas: func [check value ret? [logic!] order [word!]][
		if verbose >= 3 [
			print [">>>emitting ATOMIC-CAS" mold check mold value mold ret? mold order]
		]
		emit-i32 #{AA0003E3}                                  ; MOV x3, x0
		emit-load value
		emit-i32 #{2A0003E2}                                  ; MOV w2, w0
		emit-load check
		emit-i32 #{2A0003E5}                                  ; MOV w5, w0
		emit-i32 #{D5033BBF}                                  ; DMB ish
		                                                            ; loop:
		emit-i32 #{885FFC61}                                  ;   LDAXR w1, [x3]
		emit-i32 #{6B05003F}                                  ;   CMP w1, w5
		emit-i32 encode-branch 24 1                           ;   B.NE fail
		emit-i32 #{8804FC62}                                  ;   STLXR w4, w2, [x3]
		emit-i32 #{7100009F}                                  ;   CMP w4, #0
		emit-i32 encode-branch -20 1                          ;   B.NE loop
		emit-mov-imm32 1
		emit-i32 encode-branch 12 none                        ;   B done
		                                                            ; fail:
		emit-i32 #{D5033F5F}                                  ;   CLREX
		emit-mov-imm32 0
		                                                            ; done:
		emit-i32 #{D5033BBF}                                  ; DMB ish
	]

	emit-atomic-fence: does [
		if verbose >= 3 [print ">>>emitting ATOMIC-FENCE"]
		emit-i32 #{D5033BBF}                                  ; DMB ish
	]

	emit-throw: func [value [integer! word!] /thru][
		emit-load value
		unless thru [
			emit-i32 #{910003BF}                              ; MOV sp, x29
			emit-i32 #{A8C17BFD}                              ; LDP x29, x30, [sp], #16
		]
		                                                            ; loop:
		emit-frame-insn #{B8400000} -8 1                    ;   LDUR w1, [x29, #-8]
		emit-i32 #{6B00003F}                                  ;   CMP w1, w0
		emit-i32 encode-branch 16 2                           ;   B.HS found
		emit-i32 #{910003BF}                                  ;   MOV sp, x29
		emit-i32 #{A8C17BFD}                                  ;   LDP x29, x30, [sp], #16
		emit-i32 encode-branch -20 none                       ;   B loop
		                                                            ; found:
		emit-i32 #{2A0003E2}                                  ; MOV w2, w0
		emitter/access-path to set-path! 'system/thrown <last>
		emit-frame-insn #{F8400000} -16 1                   ; LDUR x1, [x29, #-16]
		emit-i32 #{F100003F}                                  ; CMP x1, #0
		emit-i32 encode-branch 8 0                            ; B.EQ fallback
		emit-i32 #{D61F0020}                                  ; BR x1
		emit-i32 #{D61F03C0}                                  ; fallback: BR x30
	]

	emit-open-catch: func [body-size [integer!] global? [logic!]][
		global?: all [global? not compiler/job/need-main?]
		either global? [
			emit-i32 #{A9BF7BFD}                              ; STP x29, x30, [sp, #-16]!
			emit-i32 #{910003FD}                              ; MOV x29, sp
			emit-i32 #{D10083FF}                              ; SUB sp, sp, #32
			emit-frame-insn #{F8000000} -8 0                 ; STUR x0, [x29, #-8]
			emit-frame-insn #{F8000000} -24 31               ; bitmap barrier slot
			emit-frame-insn #{F8000000} -32 31               ; parent frame slot
		][
			emit-i32 #{D10043FF}                              ; SUB sp, sp, #16
			emit-frame-insn #{F8400000} -8 2                 ; LDUR x2, [x29, #-8]
			emit-i32 #{F90003E2}                              ; STR x2, [sp]
			emit-frame-insn #{F8400000} -16 3                ; LDUR x3, [x29, #-16]
			emit-i32 #{F90007E3}                              ; STR x3, [sp, #8]
			emit-frame-insn #{F8000000} -8 0                 ; STUR x0, [x29, #-8]
		]
		emit-i32 encode-adr body-size + 8 2                  ; ADR x2, catch close
		emit-frame-insn #{F8000000} -16 2                   ; STUR x2, [x29, #-16]
		32
	]

	emit-close-catch: func [
		offset [integer!] level [integer!] global? [logic!] callback? [logic!]
		/local frame-size stack-offset
	][
		global?: all [global? not compiler/job/need-main?]
		either global? [
			emit-i32 #{910003BF}                              ; MOV sp, x29
			emit-i32 #{A8C17BFD}                              ; LDP x29, x30, [sp], #16
		][
			frame-size: round/to/ceiling locals-offset + offset 16
			stack-offset: frame-size + ((level + 1) * 16)
			emit-i32 #{910003BF}                              ; MOV sp, x29
			emit-adjust-stack stack-offset no
			emit-i32 #{A8C10FE2}                              ; LDP x2, x3, [sp], #16
			emit-frame-insn #{F8000000} -8 2                 ; STUR x2, [x29, #-8]
			emit-frame-insn #{F8000000} -16 3                ; STUR x3, [x29, #-16]
		]
	]

	emit-set-stack: func [value /frame][
		unless tag? value [emit-load value]
		emit-i32 either frame [#{AA0003FD}][#{9100001F}] ; MOV x29/sp, x0
	]

	emit-get-stack: func [/frame][
		emit-i32 either frame [#{AA1D03E0}][#{910003E0}] ; MOV x0, x29/sp
	]

	emit-get-pc: does [
		emit-i32 #{10000000}                                  ; ADR x0, .
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

	argument-slot-count?: func [locals [block!] /local count name type][
		count: either emitter/struct-ptr? locals [1][0]
		parse locals [
			opt block!
			any [
				set name word! set type block! (
					count: count + either 'value = last type [emitter/struct-slots? type][1]
				)
				| set-word! block!
				| /local break
			]
		]
		count
	]

	emit-prolog: func [
		name [word!] locals [block!] bitmap [integer!]
		/local argc arg-slots slots base i hfa field-type field-size locals-size frame-size offset int-reg fp-reg stack-arg arg-name arg-type resolved pos ret-ptr? fspec external? pointer-reg slot-offset
	][
		clear by-value-args
		argc: argument-count? locals
		arg-slots: argument-slot-count? locals
		ret-ptr?: to logic! emitter/struct-ptr? locals
		fspec: select compiler/functions name
		external?: to logic! all [fspec compiler/external-abi-call? fspec]
		locals-offset: 4 * stack-width + (arg-slots * stack-width)
		locals-size: either pos: find locals /local [emitter/calc-locals-offsets pos][0]
		frame-size: round/to/ceiling locals-offset + locals-size 16

		emit-i32 #{A9BF7BFD}                                  ; STP x29, x30, [sp, #-16]!
		emit-i32 #{910003FD}                                  ; MOV x29, sp
		if positive? frame-size [
			emit-adjust-stack frame-size no
		]

		;-- catch ID, resume address, bitmap offset, and parent Red frame
		emit-frame-insn #{F8000000} -8 31
		emit-frame-insn #{F8000000} -16 31
		emit-mov-imm32/reg bitmap 16
		emit-frame-insn #{F8000000} -24 16
		emit-frame-insn #{F8000000} -32 31

		offset: -40
		int-reg: fp-reg: stack-arg: 0
		if ret-ptr? [
			emit-frame-insn #{F8000000} offset either external? [8][0]
			patch-stack-offset <ret-ptr> offset
			offset: offset - stack-width
			int-reg: either external? [0][1]
		]
		parse locals [
			opt block!
			any [
				set arg-name word! set arg-type block! (
					resolved: compiler/resolve-aliased arg-type
					either 'value = last arg-type [
						slots: emitter/struct-slots? arg-type
						hfa: homogeneous-aggregate? arg-type
						append by-value-args arg-name
						base: offset - ((slots - 1) * stack-width)
						case [
							all [external? not hfa/1 slots > 2][
								either int-reg < 8 [
									pointer-reg: int-reg
									int-reg: int-reg + 1
								][
									emit-frame-insn #{F8400000} 16 + (stack-arg * 8) 16
									pointer-reg: 16
									stack-arg: stack-arg + 1
								]
								repeat i slots [
									slot-offset: (i - 1) * stack-width
									either slot-offset <= 32760 [
										emit-i32 (to integer! #{F9400011}) or (pointer-reg * 32)
											or ((i - 1) * 1024)       ; LDR x17, [xN, #slot]
									][
										emit-register-offset pointer-reg 15 slot-offset 15
										emit-i32 #{F94001F1}       ; LDR x17, [x15]
									]
									emit-frame-insn #{F8000000} base + slot-offset 17
								]
							]
							all [hfa/1 fp-reg + hfa/3 <= 8][
								field-type: reduce [either hfa/2 ['float32!]['float!]]
								field-size: either hfa/2 [4][8]
								repeat i hfa/3 [
									emit-frame-fp-insn either hfa/2 [#{BC000000}][#{FC000000}]
										base + ((i - 1) * field-size) fp-reg
									fp-reg: fp-reg + 1
								]
							]
							all [not hfa/1 int-reg + slots <= 8][
							repeat i slots [
								emit-frame-insn #{F8000000} base + ((i - 1) * 8) int-reg
								int-reg: int-reg + 1
							]
							]
							true [
								either hfa/1 [
									fp-reg: 8
									field-size: either hfa/2 [4][8]
									repeat i hfa/3 [
										emit-frame-fp-insn either hfa/2 [#{BC400000}][#{FC400000}]
											16 + (stack-arg * 8) + ((i - 1) * field-size) 16
										emit-frame-fp-insn either hfa/2 [#{BC000000}][#{FC000000}]
											base + ((i - 1) * field-size) 16
									]
									stack-arg: stack-arg + slots
								][
									int-reg: 8
									repeat i slots [
										emit-frame-insn #{F8400000} 16 + (stack-arg * 8) 16
										emit-frame-insn #{F8000000} base + ((i - 1) * 8) 16
										stack-arg: stack-arg + 1
									]
								]
							]
						]
						patch-stack-offset arg-name base
						offset: base - stack-width
					][
						either compiler/any-float? resolved [
							either fp-reg < 8 [
								emit-frame-fp-insn either float32-type? resolved [#{BC000000}][#{FC000000}]
									offset fp-reg
								fp-reg: fp-reg + 1
							][
								emit-frame-fp-insn either float32-type? resolved [#{BC400000}][#{FC400000}]
									16 + (stack-arg * 8) 16
								emit-frame-fp-insn either float32-type? resolved [#{BC000000}][#{FC000000}]
									offset 16
								stack-arg: stack-arg + 1
							]
						][
							either int-reg < 8 [
								emit-frame-insn #{F8000000} offset int-reg
								int-reg: int-reg + 1
							][
								emit-frame-insn #{F8400000} 16 + (stack-arg * 8) 16
								emit-frame-insn #{F8000000} offset 16
								stack-arg: stack-arg + 1
							]
						]
						patch-stack-offset arg-name offset
						offset: offset - stack-width
					]
				)
				| set-word! block!
				| /local break
			]
		]
		reduce [locals-size 0]
	]

	emit-epilog: func [
		name [word!] locals [block!] args-size [integer!] locals-size [integer!]
		/with slots [integer! none!] /closing
		/local ret-ptr? ret-type hfa field-size opcode i offset
	][
		if slots [
			ret-ptr?: to logic! emitter/struct-ptr? locals
			either ret-ptr? [
				unless <ret-ptr> = emitter/stack/1 [
					compiler/throw-error ["Function" name "has no return pointer in" mold locals]
				]
				emit-frame-insn #{F8400000} emitter/stack/2 16 ; LDR x16, [x29, #ret-ptr]
				repeat i slots [
					offset: (i - 1) * stack-width
					emit-i32 (to integer! #{F9400000}) or ((i - 1) * 1024) or 17
					emit-i32 (to integer! #{F9000000}) or ((i - 1) * 1024) or (16 * 32) or 17
				]
				emit-i32 #{AA1003E0}                      ; MOV x0, x16
			][
				ret-type: select locals compiler/return-def
				hfa: homogeneous-aggregate? ret-type
				either hfa/1 [
					emit-i32 #{AA0003F0}                    ; MOV x16, x0
					field-size: either hfa/2 [4][8]
					opcode: either hfa/2 [#{BC400000}][#{FC400000}]
					repeat i hfa/3 [
						offset: (i - 1) * field-size
						emit-i32 (opcode-int opcode) or (offset * 4096)
							or (16 * 32) or (i - 1)
					]
				][
					if slots = 2 [emit-i32 #{F9400401}]     ; LDR x1, [x0, #8]
					emit-i32 #{F9400000}                    ; LDR x0, [x0]
				]
			]
		]
		if closing [emit-load 0]
		emit-i32 #{910003BF}                                  ; MOV sp, x29
		emit-i32 #{A8C17BFD}                                  ; LDP x29, x30, [sp], #16
		emit-i32 #{D65F03C0}                                  ; RET
	]

	patch-call: func [code-buf rel-ptr dst-ptr][
		change/part at code-buf rel-ptr
			to-bin32 ((to integer! #{94000000}) or (((dst-ptr - rel-ptr) / 4) and 67108863))
			4
	]

	emit-reserve-stack: func [slots [integer!] /local size][
		size: round/to/ceiling slots * stack-width 16
		emit-adjust-stack size no
	]
	emit-release-stack: func [slots [integer!] /bytes][]

	on-init: :noop
	on-global-prolog: func [runtime? [logic!] type [word!]][]
	on-global-epilog: func [runtime? [logic!] type [word!]][
		unless runtime? [
			either all [compiler/job/runtime? compiler/job/need-main?][
				emit-i32 #{F9400FB0}                          ; LDR x16, [x29, #24], saved main frame
				emit-i32 #{AA1003FD}                          ; MOV x29, x16
				emit-epilog/closing '***_start [] 0 0
			][
				emit-load 0
			]
		]
	]
	on-root-level-entry: :noop
	on-finalize: :noop

	emit-stack-align-prolog: func [args [block!] fspec [block!]][]
	emit-stack-align-epilog: func [args [block!]][]
	emit-stack-align: :noop
	emit-float-trash-last: :noop
	emit-casting: func [
		value [object!] alt? [logic!] /push
		/local from-type to-type from-wide? to-wide? single? signed-cast? opcode
			index register-bits source-bits
	][
		index: either alt? [1][0]
		register-bits: index * 33
		source-bits: index * 32
		from-type: compiler/resolve-aliased compiler/get-type value/data
		to-type: compiler/resolve-aliased value/type
		from-wide?: any [compiler/int64? from-type compiler/any-pointer? from-type]
		to-wide?: any [compiler/int64? to-type compiler/any-pointer? to-type]
		case [
			all [
				value/keep?
				to-type/1 = 'float32!
				from-type/1 = 'integer!
			][
				emit-i32 (opcode-int #{1E270000}) or register-bits ; FMOV sN, wN
			]
			all [
				value/keep?
				to-type/1 = 'integer!
				from-type/1 = 'float32!
			][
				emit-i32 (opcode-int #{1E260000}) or register-bits ; FMOV wN, sN
			]
			all [
				to-type/1 = 'logic!
				any [compiler/integer-type? from-type compiler/any-pointer? from-type]
			][
				opcode: either from-wide? [#{F100001F}][#{7100001F}]
				emit-i32 (opcode-int opcode) or source-bits         ; CMP xN/wN, #0
				emit-cset/reg 1 index                              ; CSET wN, NE
			]
			all [compiler/integer-type? to-type compiler/integer-type? from-type][
				emit-normalize-fixed-int-result/reg to-type index
				if all [to-type/1 = 'int64! compiler/signed-integer? from-type not from-wide?][
					emit-i32 (opcode-int #{93407C00}) or register-bits ; SXTW xN, wN
				]
			]
			all [
				compiler/any-pointer? to-type
				compiler/signed-integer? from-type
				not from-wide?
			][
				emit-i32 (opcode-int #{93407C00}) or register-bits ; SXTW xN, wN
			]
			all [compiler/any-float? to-type compiler/integer-type? from-type][
				single?: float32-type? to-type
				signed-cast?: compiler/signed-integer? from-type
				opcode: either from-wide? [
					either signed-cast? [
						either single? [#{9E220000}][#{9E620000}]
					][
						either single? [#{9E230000}][#{9E630000}]
					]
				][
					either signed-cast? [
						either single? [#{1E220000}][#{1E620000}]
					][
						either single? [#{1E230000}][#{1E630000}]
					]
				]
				emit-i32 (opcode-int opcode) or register-bits
			]
			all [compiler/integer-type? to-type compiler/any-float? from-type][
				single?: float32-type? from-type
				signed-cast?: compiler/signed-integer? to-type
				opcode: either to-wide? [
					either signed-cast? [
						either single? [#{9E380000}][#{9E780000}]
					][
						either single? [#{9E390000}][#{9E790000}]
					]
				][
					either signed-cast? [
						either single? [#{1E380000}][#{1E780000}]
					][
						either single? [#{1E390000}][#{1E790000}]
					]
				]
				emit-i32 (opcode-int opcode) or register-bits
				emit-normalize-fixed-int-result/reg to-type index
			]
			all [float32-type? to-type compiler/any-float? from-type not float32-type? from-type][
				emit-i32 (opcode-int #{1E624000}) or register-bits ; FCVT sN, dN
			]
			all [compiler/any-float? to-type float32-type? from-type not float32-type? to-type][
				emit-i32 (opcode-int #{1E22C000}) or register-bits ; FCVT dN, sN
			]
			all [to-type/1 = 'logic! compiler/any-float? from-type][
				opcode: either float32-type? from-type [#{1E202008}][#{1E602008}]
				emit-i32 (opcode-int opcode) or source-bits     ; FCMP sN/dN, #0
				emit-cset/reg 1 index                          ; CSET wN, NE
			]
		]
	]

	patch-sub-call: func [buffer [binary!] ptr [integer!] offset [integer!] /local delta][
		delta: negate offset
		unless zero? delta // 4 [compiler/throw-error "unaligned ARM64 subroutine call"]
		if any [delta < -134217728 delta > 134217724][
			compiler/throw-error "ARM64 subroutine call is out of range"
		]
		change/part at buffer ptr
			to-bin32 ((opcode-int #{94000000}) or ((delta / 4) and 67108863))
			4
	]
	emit-alt-last: :noop
	emit-log-b: func [type][
		emit-i32 #{910023FF}                                  ; finish releasing 16-byte native arg cell
		emit-i32 #{5AC01000}                                  ; CLZ w0, w0
		emit-mov-imm32/reg 31 1
		emit-i32 #{4B000020}                                  ; SUB w0, w1, w0
		call-arg-index: call-arg-index - 1
		take/last call-arg-types
	]
	emit-access-register: func [reg [word!] set? [logic!] value /local name kind number opcode][
		if verbose >= 3 [print [">>>emitting ACCESS-REGISTER" reg]]
		if all [set? not tag? value][emit-load value]
		if reg = 'sp [
			emit-i32 either set? [#{9100001F}][#{910003E0}]
			exit
		]
		name: form reg
		kind: first name
		unless find "xw" kind [
			compiler/throw-error ["ARM64 system/cpu register is invalid:" reg]
		]
		number: attempt [to integer! next name]
		unless all [integer? number number >= 0 number <= 30][
			compiler/throw-error ["ARM64 system/cpu register is invalid:" reg]
		]
		if zero? number [exit]
		opcode: either kind = #"x" [#{AA0003E0}][#{2A0003E0}]
		emit-i32 (opcode-int opcode) or either set? [number][number * 65536]
	]
	emit-alloc-stack: func [zeroed? [logic!]][
		emit-i32 #{91000400}                                  ; ADD x0, x0, #1
		emit-i32 #{D341FC00}                                  ; LSR x0, x0, #1
		emit-i32 #{D37FF800}                                  ; LSL x0, x0, #1 (round slots to even)
		if zeroed? [emit-i32 #{AA0003E1}]                    ; MOV x1, x0
		emit-i32 #{CB206FFF}                                  ; SUB sp, sp, x0, LSL #3
		if zeroed? [
			emit-i32 #{910003E2}                              ; MOV x2, sp
			emit-i32 #{B4000081}                              ; CBZ x1, done
			emit-i32 #{F800845F}                              ; loop: STR xzr, [x2], #8
			emit-i32 #{F1000421}                              ; SUBS x1, x1, #1
			emit-i32 encode-branch -8 1                     ; B.NE loop
		]
	]
	emit-free-stack: does [
		emit-i32 #{91000400}                                  ; ADD x0, x0, #1
		emit-i32 #{D341FC00}                                  ; LSR x0, x0, #1
		emit-i32 #{D37FF800}                                  ; LSL x0, x0, #1 (round slots to even)
		emit-i32 #{8B206FFF}                                  ; ADD sp, sp, x0, LSL #3
	]
	emit-read-io: :unsupported-port-io
	emit-io-read: :unsupported-port-io
	emit-io-write: :unsupported-port-io
	emit-fpu-get: func [
		/type
		/options option [word!]
		/masks mask [word!]
		/cword
		/status
		/local bit bits
	][
		case [
			type [
				emit-mov-imm32 3                             ; FPU_TYPE_VFP
			]
			status [
				emit-i32 #{D53B4420}                          ; MRS x0, FPSR
				emit-mov-imm32/reg 159 1
				emit-i32 #{0A010000}                          ; AND w0, w0, w1
			]
			cword [
				emit-i32 #{D53B4400}                          ; MRS x0, FPCR
			]
			options [
				emit-i32 #{D53B4400}                          ; MRS x0, FPCR
				set [bits bit] switch/default option [
					rounding      [2 22]
					flush-to-zero [1 24]
					NaN-mode      [1 25]
				][compiler/throw-error ["invalid ARM64 FPU option name:" option]]
				emit-i32 (opcode-int #{53000000}) or (bit * 65536)
					or ((bit + bits - 1) * 1024)
			]
			masks [
				emit-i32 #{D53B4400}                          ; MRS x0, FPCR
				bit: switch/default mask [
					precision   [12]
					underflow   [11]
					overflow    [10]
					zero-divide [9]
					denormal    [15]
					invalid-op  [8]
				][compiler/throw-error ["invalid ARM64 FPU mask name:" mask]]
				emit-i32 (opcode-int #{53000000}) or (bit * 65536) or (bit * 1024)
				emit-i32 #{52000000}                          ; EOR w0, w0, #1
			]
		]
	]
	emit-fpu-set: func [
		value
		/options option [word!]
		/masks mask [word!]
		/cword
		/local raw bit bits clear-mask new-bits
	][
		either cword [
			emit-load value
		][
			raw: compiler/unbox value
			if logic? raw [raw: to integer! raw]
			unless integer? raw [
				compiler/throw-error "ARM64 FPU option values must be integer literals"
			]
			emit-i32 #{D53B4400}                              ; MRS x0, FPCR
			case [
				options [
					set [bits bit] switch/default option [
						rounding      [2 22]
						flush-to-zero [1 24]
						NaN-mode      [1 25]
					][compiler/throw-error ["invalid ARM64 FPU option name:" option]]
					clear-mask: ((shift/left 1 bits) - 1) * shift/left 1 bit
					new-bits: raw * shift/left 1 bit
				]
				masks [
					bit: switch/default mask [
						precision   [12]
						underflow   [11]
						overflow    [10]
						zero-divide [9]
						denormal    [15]
						invalid-op  [8]
					][compiler/throw-error ["invalid ARM64 FPU mask name:" mask]]
					clear-mask: shift/left 1 bit
					new-bits: either zero? raw [clear-mask][0]
				]
			]
			emit-mov-imm32/reg clear-mask 1
			emit-i32 #{0A210000}                              ; BIC w0, w0, w1
			unless zero? new-bits [
				emit-mov-imm32/reg new-bits 1
				emit-i32 #{2A010000}                          ; ORR w0, w0, w1
			]
		]
		emit-i32 #{D51B4400}                                  ; MSR FPCR, x0
	]
	emit-fpu-update: :noop
	emit-fpu-init: does [
		emit-mov-imm32 0
		emit-i32 #{D51B4400}                                  ; MSR FPCR, x0
		emit-i32 #{D51B4420}                                  ; MSR FPSR, x0
	]
	emit-push-all: has [offset first-reg second-reg][
		emit-i32 (opcode-int #{D10003FF}) or (784 * 1024)    ; SUB sp, sp, #784
		repeat i 15 [
			first-reg: (i - 1) * 2
			second-reg: first-reg + 1
			offset: (i - 1) * 16
			emit-i32 (opcode-int #{A9000000}) or ((offset / 8) * 32768)
				or (second-reg * 1024) or (31 * 32) or first-reg
		]
		emit-sp-insn #{F8000000} 240 30                    ; STR x30, [sp, #240]
		emit-i32 #{D53B4210}                                  ; MRS x16, NZCV
		emit-sp-insn #{F8000000} 248 16
		emit-i32 #{D53B4410}                                  ; MRS x16, FPCR
		emit-sp-insn #{F8000000} 256 16
		emit-i32 #{D53B4430}                                  ; MRS x16, FPSR
		emit-sp-insn #{F8000000} 264 16
		repeat i 16 [
			first-reg: (i - 1) * 2
			second-reg: first-reg + 1
			offset: 272 + ((i - 1) * 32)
			emit-i32 (opcode-int #{AD000000}) or ((offset / 16) * 32768)
				or (second-reg * 1024) or (31 * 32) or first-reg
		]
	]
	emit-pop-all: has [offset first-reg second-reg][
		repeat i 16 [
			first-reg: (i - 1) * 2
			second-reg: first-reg + 1
			offset: 272 + ((i - 1) * 32)
			emit-i32 (opcode-int #{AD400000}) or ((offset / 16) * 32768)
				or (second-reg * 1024) or (31 * 32) or first-reg
		]
		emit-sp-insn #{F8400000} 248 16
		emit-i32 #{D51B4210}                                  ; MSR NZCV, x16
		emit-sp-insn #{F8400000} 256 16
		emit-i32 #{D51B4410}                                  ; MSR FPCR, x16
		emit-sp-insn #{F8400000} 264 16
		emit-i32 #{D51B4430}                                  ; MSR FPSR, x16
		emit-sp-insn #{F8400000} 240 30                    ; LDR x30, [sp, #240]
		repeat i 15 [
			first-reg: (i - 1) * 2
			second-reg: first-reg + 1
			offset: (i - 1) * 16
			emit-i32 (opcode-int #{A9400000}) or ((offset / 8) * 32768)
				or (second-reg * 1024) or (31 * 32) or first-reg
		]
		emit-i32 (opcode-int #{910003FF}) or (784 * 1024)    ; ADD sp, sp, #784
	]
	emit-init-sub: does [
		if verbose >= 3 [print ">>>emitting INIT subroutine"]
		emit-i32 #{D10043FF}                                  ; SUB sp, sp, #16
		emit-i32 #{F90003FE}                                  ; STR x30, [sp]
	]
	emit-return-sub: does [
		if verbose >= 3 [print ">>>emitting RET from subroutine"]
		emit-i32 #{F94003FE}                                  ; LDR x30, [sp]
		emit-i32 #{910043FF}                                  ; ADD sp, sp, #16
		emit-i32 #{D65F03C0}                                  ; RET
	]
	emit-call-sub: func [name [word!] spec [block!]][
		if verbose >= 3 [print [">>>emitting CALL subroutine" name]]
		append spec/3 emitter/tail-ptr
		emit-i32 #{94000000}                                  ; BL subroutine
		unless empty? emitter/chunks/queue [
			append/only second last emitter/chunks/queue back tail spec/3
		]
	]
]
