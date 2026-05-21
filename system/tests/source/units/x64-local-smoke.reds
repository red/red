Red/System [
	Title: "Red/System x86-64 local variable smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	add4-local: func [
		value [integer!]
		return: [integer!]
		/local tmp [integer!]
	][
		tmp: value + 4
		tmp
	]

	status: 0
	status: add4-local 3
	sys-exit status
]
