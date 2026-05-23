Red/System [
	Title: "Red/System x86-64 catch/throw runtime test"
]

#if target = 'X86-64 [
	#syscall [
		sys-write: 1 [
			fd  [integer!]
			buf [c-string!]
			len [integer!]
		]
		sys-exit: 60 [
			status [integer!]
		]
	]

	main: func [
		return: [integer!]
	][
		system/thrown: 0
		catch 1 [
			throw 1
		]
		if system/thrown = 1 [
			sys-write 1 "OK^/" 3
			return 0
		]
		1
	]

	status: main
	sys-exit status
]
