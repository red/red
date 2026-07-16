Red/System [
	Title: "Red/System ARM64 write syscall and literal smoke test"
]

#if target = 'ARM64 [
	#syscall [
		sys-write: 64 [fd [integer!] buf [c-string!] len [integer!]]
		sys-exit: 93 [status [integer!]]
	]

	msg: "ARM64-OK^/"
	sys-write 1 msg 9
	sys-exit 0
]
