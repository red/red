Red/System [
	Title: "Red/System ARM64 syscall smoke test"
]

#if target = 'ARM64 [
	#syscall [
		sys-exit: 93 [
			status [integer!]
		]
	]

	sys-exit 0
]
