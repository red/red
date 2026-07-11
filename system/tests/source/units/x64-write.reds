Red/System [
	Title: "Red/System x86-64 write syscall smoke test"
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

	msg: "OK^/"
	sys-write 1 msg 3
	sys-exit 0
]
