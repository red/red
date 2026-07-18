Red/System [
	Title: "Darwin ARM64 minimal executable smoke test"
]

#syscall [
	sys-exit: 1 [status [integer!]]
]

n: 40 + 2
sys-exit either n = 42 [0][1]
