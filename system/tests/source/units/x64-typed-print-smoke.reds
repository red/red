Red/System [
	Title: "Red/System x86-64 typed print smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	print "OK"
	sys-exit 0
]
