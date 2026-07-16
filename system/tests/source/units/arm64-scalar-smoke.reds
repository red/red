Red/System [
	Title: "Red/System ARM64 scalar and branch smoke test"
]

#if target = 'ARM64 [
	#syscall [
		sys-exit: 93 [status [integer!]]
	]

	status: 0
	status: 3 + 4
	either status = 7 [
		sys-exit 0
	][
		sys-exit status
	]
]
