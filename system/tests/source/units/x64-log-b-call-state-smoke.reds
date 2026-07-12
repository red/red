Red/System [
	Title: "Red/System x86-64 log-b call state smoke test"
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

	add: func [a [integer!] b [integer!] return: [integer!]][
		a + b
	]

	msg: "OK^/"
	bits: log-b 2
	if bits <> 1 [sys-exit 1]
	if (add 40 2) <> 42 [sys-exit 2]
	sys-write 1 msg 3
	sys-exit 0
]
