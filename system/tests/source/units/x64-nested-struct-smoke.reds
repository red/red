Red/System [
	Title: "Red/System x86-64 nested struct smoke test"
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

	inner!: alias struct! [
		x [integer!]
		y [integer!]
	]

	outer!: alias struct! [
		left  [integer!]
		sub   [inner! value]
		right [integer!]
	]

	o: declare outer!
	score: 0

	o/left: 1
	o/sub/x: 2
	o/sub/y: 3
	o/right: 4

	if o/left = 1 [score: score + 1]
	if o/sub/x = 2 [score: score + 1]
	if o/sub/y = 3 [score: score + 1]
	if o/right = 4 [score: score + 1]

	if score = 4 [
		sys-write 1 "OK^/" 3
		sys-exit 0
	]
	sys-exit 1
]
