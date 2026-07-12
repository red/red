Red/System [
	Title: "Red/System x86-64 float comparison smoke test"
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
	value: 123.456
	limit: 1e17

	if value >= limit [sys-exit 1]
	if value > limit [sys-exit 2]
	if not value < limit [sys-exit 3]
	if not value <= limit [sys-exit 4]
	if not limit >= value [sys-exit 5]
	if not limit > value [sys-exit 6]
	if limit < value [sys-exit 7]
	if limit <= value [sys-exit 8]

	sys-write 1 msg 3
	sys-exit 0
]
