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
		/local x a of?
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

		0
	]

	sys-exit main
]
