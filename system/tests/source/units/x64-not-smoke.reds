Red/System [
	Title: "Red/System x86-64 NOT smoke test"
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

	score: 0
	n: 0

	if not false [score: score + 1]
	if not true [
		score: 0
	]

	n: not 0
	if n = -1 [score: score + 1]

	if score = 2 [
		sys-write 1 "OK^/" 3
		sys-exit 0
	]
	sys-exit 1
]
