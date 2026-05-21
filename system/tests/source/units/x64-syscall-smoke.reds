Red/System [
	Title: "Red/System x86-64 syscall smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	status: 0
	status: 7
	sys-exit status
]
