Red/System [
	Title: "Red/System x86-64 stack smoke test"
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

	status: 0
	push 6
	status: pop

	if status = 6 [
		sys-write 1 "OK^/" 3
		sys-exit 0
	]
	sys-exit 1
]
