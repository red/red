Red/System [
	Title: "Red/System x86-64 pointer smoke test"
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

	pair!: alias struct! [
		left  [integer!]
		right [integer!]
	]

	pair: declare pair!
	p: declare pointer! [integer!]
	score: 0

	p: as pointer! [integer!] pair
	p/value: 41
	p/2: 1

	if p/value = 41 [score: score + 1]
	if p/2 = 1 [score: score + 1]
	if pair/left = 41 [score: score + 1]
	if pair/right = 1 [score: score + 1]

	if score = 4 [
		sys-write 1 "OK^/" 3
		sys-exit 0
	]
	sys-exit 1
]
