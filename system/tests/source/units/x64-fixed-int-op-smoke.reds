Red/System [
	Title: "Red/System x86-64 fixed-width integer operation smoke test"
]

#if target = 'X86-64 [
	#either OS = 'Windows [
		#import [
			"kernel32.dll" stdcall [
				sys-exit: "ExitProcess" [
					status [integer!]
				]
			]
		]
	][
		#syscall [
			sys-exit: 60 [
				status [integer!]
			]
		]
	]

	int64-parts!: alias struct! [
		lo [integer!]
		hi [integer!]
	]

	check-small: func [
		return: [integer!]
		/local
			i8  [int8!]
			u8  [uint8!]
			i16 [int16!]
			u16 [uint16!]
	][
		i8: (as int8! -100) + (as int8! 7)
		if i8 <> as int8! -93 [return 1]

		i8: (as int8! -100) * (as int8! 7)
		if i8 <> as int8! 68 [return 2]

		i8: (as int8! -100) % (as int8! 7)
		if i8 <> as int8! -2 [return 3]

		i8: (as int8! -100) // (as int8! 7)
		if i8 <> as int8! 5 [return 4]

		i8: (as int8! -64) >>> 2
		if i8 <> as int8! 48 [return 5]

		u8: (as uint8! 250) + (as uint8! 10)
		if u8 <> as uint8! 4 [return 6]

		u8: (as uint8! 250) % (as uint8! 11)
		if u8 <> as uint8! 8 [return 7]

		u8: (as uint8! 240) >>> 4
		if u8 <> as uint8! 15 [return 8]

		i16: (as int16! -21846) or (as int16! 3855)
		if i16 <> as int16! -20561 [return 9]

		u16: (as uint16! 60000) xor (as uint16! 3855)
		if u16 <> as uint16! 58735 [return 10]

		0
	]

	check-wide: func [
		return: [integer!]
		/local
			i64 [int64!]
			u64 [uint64!]
			parts [int64-parts!]
			shift [integer!]
	][
		i64: (as int64! 0000000100000000h) * (as int64! 3)
		parts: as int64-parts! :i64
		if any [parts/lo <> 0 parts/hi <> 3] [return 11]

		i64: (as int64! FFFFFFFAFFFFFFF8h) / (as int64! 3)
		parts: as int64-parts! :i64
		if any [parts/lo <> 55555553h parts/hi <> -2] [return 12]

		i64: (as int64! FFFFFFFAFFFFFFF8h) // (as int64! 3)
		parts: as int64-parts! :i64
		if any [parts/lo <> 2 parts/hi <> 0] [return 13]

		shift: 33
		i64: (as int64! 1) << shift
		parts: as int64-parts! :i64
		if any [parts/lo <> 0 parts/hi <> 2] [return 14]

		i64: (as int64! 8000000000000000h) >> 63
		parts: as int64-parts! :i64
		if any [parts/lo <> -1 parts/hi <> -1] [return 15]

		u64: (as uint64! FFFFFFFFFFFFFFFFh) / (as uint64! 0000000100000001h)
		parts: as int64-parts! :u64
		if any [parts/lo <> -1 parts/hi <> 0] [return 16]

		u64: (as uint64! F000000000000000h) >>> 60
		parts: as int64-parts! :u64
		if any [parts/lo <> 15 parts/hi <> 0] [return 17]

		if not ((as uint64! FFFFFFFFFFFFFFFFh) > (as uint64! 7FFFFFFFFFFFFFFFh)) [return 18]

		0
	]

	result: check-small
	if result <> 0 [sys-exit result]

	result: check-wide
	sys-exit result
]
