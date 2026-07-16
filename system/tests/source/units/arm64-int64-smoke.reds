Red/System [
	Title: "Red/System ARM64 64-bit integer smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	add-wide: func [a [int64!] b [int64!] return: [int64!]][a + b]

	check: func [
		return: [integer!]
		/local
			i     [int64!]
			u     [uint64!]
			shift [integer!]
	][
		i: (as int64! 0000000100000000h) * (as int64! 3)
		if i <> as int64! 0000000300000000h [sys-exit 1]

		i: (as int64! FFFFFFFAFFFFFFF8h) / (as int64! 3)
		if i <> as int64! FFFFFFFE55555553h [sys-exit 2]

		i: (as int64! FFFFFFFAFFFFFFF8h) % (as int64! 3)
		if i <> as int64! FFFFFFFFFFFFFFFFh [sys-exit 3]

		i: (as int64! FFFFFFFAFFFFFFF8h) // (as int64! 3)
		if i <> as int64! 0000000000000002h [sys-exit 4]

		shift: 33
		i: (as int64! 1) << shift
		if i <> as int64! 0000000200000000h [sys-exit 5]

		i: (as int64! 8000000000000000h) >> 63
		if i <> as int64! FFFFFFFFFFFFFFFFh [sys-exit 6]

		u: (as uint64! FFFFFFFFFFFFFFFFh) / (as uint64! 0000000100000001h)
		if u <> as uint64! 00000000FFFFFFFFh [sys-exit 7]

		u: (as uint64! F000000000000000h) >>> 60
		if u <> as uint64! 000000000000000Fh [sys-exit 8]

		if not ((as uint64! FFFFFFFFFFFFFFFFh) > (as uint64! 7FFFFFFFFFFFFFFFh)) [
			sys-exit 9
		]

		i: add-wide (as int64! 0000000100000000h) (as int64! 0000000200000000h)
		if i <> as int64! 0000000300000000h [sys-exit 10]

		i: not (as int64! 00000000FFFFFFFFh)
		if i <> as int64! FFFFFFFF00000000h [sys-exit 11]

		0
	]

	sys-exit check
]
