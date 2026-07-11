Red/System [
	Title: "Red/System x86-64 system/cpu register smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]

	check-rcx: func [
		return: [integer!]
		/local value [pointer! [integer!]]
	][
		system/cpu/rcx: as pointer! [integer!] 42
		value: system/cpu/rcx
		either value = as pointer! [integer!] 42 [0][1]
	]

	sys-exit check-rcx
]
