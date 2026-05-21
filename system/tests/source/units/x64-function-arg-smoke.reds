Red/System [
	Title: "Red/System x86-64 function argument smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	sub-values: func [
		left  [integer!]
		right [integer!]
		return: [integer!]
	][
		left - right
	]

	status: 0
	status: sub-values 9 4
	sys-exit status
]
