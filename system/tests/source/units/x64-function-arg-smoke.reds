Red/System [
	Title: "Red/System x86-64 function argument smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	add-values: func [
		left  [integer!]
		right [integer!]
		return: [integer!]
	][
		left + right
	]

	status: 0
	status: add-values 3 4
	sys-exit status
]
