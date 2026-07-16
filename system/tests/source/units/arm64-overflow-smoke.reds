Red/System [
	Title: "ARM64 overflow block smoke test"
]

#if target = 'ARM64 [
	#syscall [
		sys-exit: 93 [status [integer!]]
	]

	value: declare integer!
	flag: declare logic!
	flag: overflow? [value: 1 + 1]
	either flag [sys-exit 1][sys-exit 0]
]
