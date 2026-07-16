Red/System [
	Title: "Red/System ARM64 scalar function smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	add4-local: func [
		value [integer!]
		return: [integer!]
		/local tmp [integer!]
	][
		tmp: value + 4
		tmp
	]

	status: add4-local 3
	either status = 7 [sys-exit 0][sys-exit status]
]
