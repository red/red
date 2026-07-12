Red/System [
	Title: "Red/System x86-64 overflow flag smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	main: func [
		return: [integer!]
		/local x a b n of?
	][
		x: 2147483647
		a: x + 1
		of?: system/cpu/overflow?
		if not of? [return 1]

		x: 1000
		a: x * 2000
		of?: system/cpu/overflow?
		if of? [return 2]

		x: 2147483647
		a: x / -1
		of?: system/cpu/overflow?
		if of? [return 3]

		of?: overflow? [n: 100 * 200]
		if of? [return 4]

		x: 2147483647
		of?: overflow? [n: x + 1]
		if not of? [return 5]

		of?: overflow? [n: 1 << 31]
		if not of? [return 6]

		a: -2147483648
		b: -1
		of?: overflow? [n: a / b]
		if not of? [return 7]

		n: 0
		of?: overflow? [
			n: n + 1
			a: 2147483647 + 1
			n: n + 100
		]
		if not of? [return 8]
		if n <> 1 [return 9]

		0
	]

	sys-exit main
]
