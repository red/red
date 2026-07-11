Red/System [
	Title: "Red/System x86-64 size smoke test"
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

	if (size? pointer!) = 8 [score: score + 1]
	if (size? c-string!) = 8 [score: score + 1]
	if (size? function!) = 8 [score: score + 1]
	if (size? int64!) = 8 [score: score + 1]
	if (size? uint64!) = 8 [score: score + 1]

	if score = 5 [
		sys-write 1 "OK^/" 3
		sys-exit 0
	]
	sys-exit 1
]
