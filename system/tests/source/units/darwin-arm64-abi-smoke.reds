Red/System [
	Title: "Darwin ARM64 native ABI interoperability smoke test"
]

#if ABI = 'apple-aarch64 [
	#syscall [quit: 1 [status [integer!]]]

	pair32!: alias struct! [left [integer!] right [integer!]]
	large!: alias struct! [
		a [integer!] b [integer!] c [integer!]
		d [integer!] e [integer!] f [integer!]
	]
	hfa2!: alias struct! [x [float!] y [float!]]
	triple8!: alias struct! [a [uint8!] b [uint8!] c [uint8!]]

	#import [
		"libdarwin-arm64-abi-helper.dylib" cdecl [
			check-narrow-registers: "check_narrow_registers" [
				i8 [int8!] u8 [uint8!] i16 [int16!] u16 [uint16!]
				i32 [int32!] u32 [uint32!] i64 [int64!] u64 [uint64!]
				return: [integer!]
			]
			check-compact-stack: "check_compact_stack" [
				r0 [int64!] r1 [int64!] r2 [int64!] r3 [int64!]
				r4 [int64!] r5 [int64!] r6 [int64!] r7 [int64!]
				i8 [int8!] u8 [uint8!] i16 [int16!] u16 [uint16!]
				i32 [int32!] u32 [uint32!] i64 [int64!] u64 [uint64!]
				return: [integer!]
			]
			check-compact-fp-stack: "check_compact_fp_stack" [
				d0 [float!] d1 [float!] d2 [float!] d3 [float!]
				d4 [float!] d5 [float!] d6 [float!] d7 [float!]
				f0 [float32!] f1 [float32!] d8 [float!]
				return: [integer!]
			]
			check-variadic: "check_variadic" [[variadic]
				marker [integer!]
				return: [integer!]
			]
			check-variadic-after-stack: "check_variadic_after_stack" [[variadic]
				a0 [integer!] a1 [integer!] a2 [integer!] a3 [integer!] a4 [integer!]
				a5 [integer!] a6 [integer!] a7 [integer!] a8 [integer!]
				return: [integer!]
			]
			check-objc-dispatch: "check_objc_dispatch" [[variadic objc]
				receiver [uint64!] selector [uint64!]
				return: [integer!]
			]
			check-objc-compact-stack: "check_objc_compact_stack" [[variadic objc]
				receiver [uint64!] selector [uint64!]
				return: [integer!]
			]
			check-pair: "check_pair" [
				value [pair32! value] marker [integer!]
				return: [integer!]
			]
			check-large: "check_large" [
				value [large! value] marker [integer!]
				return: [integer!]
			]
			check-hfa: "check_hfa" [
				value [hfa2! value] marker [integer!]
				return: [integer!]
			]
			check-triple-stack: "check_triple_stack" [
				r0 [int64!] r1 [int64!] r2 [int64!] r3 [int64!]
				r4 [int64!] r5 [int64!] r6 [int64!] r7 [int64!]
				value [triple8! value] tail [uint16!]
				return: [integer!]
			]
			check-hfa-stack: "check_hfa_stack" [
				d0 [float!] d1 [float!] d2 [float!] d3 [float!]
				d4 [float!] d5 [float!] d6 [float!] d7 [float!]
				value [hfa2! value] tail [float32!]
				return: [integer!]
			]
			invoke-compact-callback: "invoke_compact_callback" [
				fn [function! [
					r0 [int64!] r1 [int64!] r2 [int64!] r3 [int64!]
					r4 [int64!] r5 [int64!] r6 [int64!] r7 [int64!]
					i8 [int8!] u8 [uint8!] i16 [int16!] u16 [uint16!]
					i32 [int32!] u32 [uint32!] i64 [int64!] u64 [uint64!]
					return: [integer!]
				]]
				return: [integer!]
			]
			invoke-pair-callback: "invoke_pair_callback" [
				fn [function! [
					value [pair32! value] marker [integer!]
					return: [integer!]
				]]
				return: [integer!]
			]
			invoke-triple-stack-callback: "invoke_triple_stack_callback" [
				fn [function! [
					r0 [int64!] r1 [int64!] r2 [int64!] r3 [int64!]
					r4 [int64!] r5 [int64!] r6 [int64!] r7 [int64!]
					value [triple8! value] tail [uint16!]
					return: [integer!]
				]]
				return: [integer!]
			]
			invoke-hfa-stack-callback: "invoke_hfa_stack_callback" [
				fn [function! [
					d0 [float!] d1 [float!] d2 [float!] d3 [float!]
					d4 [float!] d5 [float!] d6 [float!] d7 [float!]
					value [hfa2! value] tail [float32!]
					return: [integer!]
				]]
				return: [integer!]
			]
		]
	]

	compact-callback: func [
		[cdecl]
		r0 [int64!] r1 [int64!] r2 [int64!] r3 [int64!]
		r4 [int64!] r5 [int64!] r6 [int64!] r7 [int64!]
		i8 [int8!] u8 [uint8!] i16 [int16!] u16 [uint16!]
		i32 [int32!] u32 [uint32!] i64 [int64!] u64 [uint64!]
		return: [integer!]
	][
		either all [
			r0 = 10 r1 = 11 r2 = 12 r3 = 13 r4 = 14 r5 = 15 r6 = 16 r7 = 17
			i8 = as int8! -2 u8 = as uint8! 250
			i16 = as int16! -300 u16 = as uint16! 60000
			i32 = as int32! -123456 u32 = as uint32! 4000000000
			i64 = as int64! -3 u64 = as uint64! 0000000100000004h
		][1][0]
	]

	pair-callback: func [
		[cdecl]
		value [pair32! value]
		marker [integer!]
		return: [integer!]
	][
		either all [value/left = 20 value/right = 22 marker = 7][1][0]
	]

	triple-stack-callback: func [
		[cdecl]
		r0 [int64!] r1 [int64!] r2 [int64!] r3 [int64!]
		r4 [int64!] r5 [int64!] r6 [int64!] r7 [int64!]
		value [triple8! value] tail [uint16!]
		return: [integer!]
	][
		either all [
			r0 = 10 r1 = 11 r2 = 12 r3 = 13 r4 = 14 r5 = 15 r6 = 16 r7 = 17
			value/a = as uint8! 1 value/b = as uint8! 2 value/c = as uint8! 3
			tail = as uint16! 60000
		][1][0]
	]

	hfa-stack-callback: func [
		[cdecl]
		d0 [float!] d1 [float!] d2 [float!] d3 [float!]
		d4 [float!] d5 [float!] d6 [float!] d7 [float!]
		value [hfa2! value] tail [float32!]
		return: [integer!]
	][
		either all [
			d0 = 1.0 d1 = 2.0 d2 = 3.0 d3 = 4.0
			d4 = 5.0 d5 = 6.0 d6 = 7.0 d7 = 8.0
			value/x = 1.25 value/y = 2.75 tail = as float32! 9.5
		][1][0]
	]

	if 1 <> check-narrow-registers
		(as int8! -2) (as uint8! 250) (as int16! -300) (as uint16! 60000)
		(as int32! -123456) (as uint32! 4000000000)
		(as int64! -3) (as uint64! 0000000100000004h)
	[quit 1]

	if 1 <> check-compact-stack
		10 11 12 13 14 15 16 17
		(as int8! -2) (as uint8! 250) (as int16! -300) (as uint16! 60000)
		(as int32! -123456) (as uint32! 4000000000)
		(as int64! -3) (as uint64! 0000000100000004h)
	[quit 2]

	if 1 <> check-compact-fp-stack
		1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0
		(as float32! 9.25) (as float32! 10.5) 11.75
	[quit 3]

	if 1 <> check-variadic [
		77 -9 2.5 123 (as uint64! 0000000100000004h)
	][quit 4]
	if 1 <> check-variadic-after-stack [
		10 11 12 13 14 15 16 17 18 42
	][quit 14]
	if 1 <> check-objc-dispatch [
		(as uint64! 0000000100000001h)
		(as uint64! 0000000100000002h)
		(as float32! 1.25) 2.5
		(as uint8! 250) (as int16! -300)
		(as uint64! 0000000100000004h)
	][quit 15]
	if 1 <> check-objc-compact-stack [
		(as uint64! 0000000100000001h)
		(as uint64! 0000000100000002h)
		10 11 12 13 14 15
		(as int8! -2) (as uint8! 250)
		(as int16! -300) (as uint16! 60000)
		(as int32! -123456)
	][quit 16]

	pair: declare pair32!
	pair/left: 20
	pair/right: 22
	if 1 <> check-pair pair 7 [quit 5]

	large: declare large!
	large/a: 1 large/b: 2 large/c: 3
	large/d: 4 large/e: 5 large/f: 6
	if 1 <> check-large large 8 [quit 6]

	hfa: declare hfa2!
	hfa/x: 1.25
	hfa/y: 2.75
	if 1 <> check-hfa hfa 9 [quit 7]

	triple: declare triple8!
	triple/a: as uint8! 1
	triple/b: as uint8! 2
	triple/c: as uint8! 3
	if 1 <> check-triple-stack
		10 11 12 13 14 15 16 17 triple (as uint16! 60000)
	[quit 10]
	if 1 <> check-hfa-stack
		1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 hfa (as float32! 9.5)
	[quit 11]
	if 1 <> invoke-compact-callback :compact-callback [quit 8]
	if 1 <> invoke-pair-callback :pair-callback [quit 9]
	if 1 <> invoke-triple-stack-callback :triple-stack-callback [quit 12]
	if 1 <> invoke-hfa-stack-callback :hfa-stack-callback [quit 13]

	quit 0
]
