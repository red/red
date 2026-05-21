Red/System [
	Title: "Red/System x86-64 branch and loop smoke test"
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
	len: 0

	loop 5 [
		len: len + 1
		if len = 3 [
			break
		]
	]

	if len = 3 [
		sys-write 1 msg len
	]
	sys-exit 0
]
