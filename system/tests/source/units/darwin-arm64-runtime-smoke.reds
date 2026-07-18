Red/System [
	Title: "Darwin ARM64 runtime startup smoke test"
]

#syscall [
	sys-exit: 1 [status [integer!]]
]

sys-exit either all [
	system/args-count = 2
	system/args-list <> null
][0][1]
