Red/System [
	Title: "Red/System x86-64 function smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	answer: func [return: [integer!]][
		3 + 4
	]

	status: 0
	status: answer
	sys-exit status
]
