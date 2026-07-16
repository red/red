Red/System [
	Title: "Red/System ARM64 integer and control-flow smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	early-return: func [value [integer!] return: [integer!]][
		if value = 7 [return 42]
		1
	]

	check: func [
		return: [integer!]
		/local
			a     [integer!]
			b     [integer!]
			shift [integer!]
			u     [uint32!]
	][
		a: 100 / 7
		if a <> 14 [sys-exit 1]
		a: -100 % 7
		if a <> -2 [sys-exit 2]
		a: -100 // 7
		if a <> 5 [sys-exit 3]

		a: 13 * 17
		if a <> 221 [sys-exit 4]
		a: (a and 255) xor 85
		if a <> 136 [sys-exit 5]

		shift: 5
		a: 3 << shift
		if a <> 96 [sys-exit 6]
		a: -64 >> 2
		if a <> -16 [sys-exit 7]
		u: (as uint32! 80000000h) >>> 31
		if u <> as uint32! 1 [sys-exit 8]

		a: not 0
		if a <> -1 [sys-exit 9]
		if not (13 < 17) [sys-exit 10]
		if (as uint32! FFFFFFFFh) <= (as uint32! 7FFFFFFFh) [sys-exit 11]

		a: 0
		loop 5 [
			a: a + 1
			if a = 3 [break]
		]
		if a <> 3 [sys-exit 12]

		b: 0
		while [b < 4][b: b + 1]
		if b <> 4 [sys-exit 13]

		0
	]

	status: check
	if status <> 0 [sys-exit status]
	status: early-return 7
	if status <> 42 [sys-exit 14]
	status: early-return 0
	if status <> 1 [sys-exit 15]
	sys-exit 0
]
