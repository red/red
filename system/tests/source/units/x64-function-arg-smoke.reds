Red/System [
	Title: "Red/System x86-64 function argument smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	add4: func [value [integer!] return: [integer!]][
		value + 4
	]

	status: 0
	status: add4 3
	sys-exit status
]
