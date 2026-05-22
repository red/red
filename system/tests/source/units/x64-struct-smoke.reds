Red/System [
	Title: "Red/System x86-64 struct smoke test"
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

	point!: alias struct! [
		x [integer!]
		y [float!]
	]

	p: declare point!
	score: 0
	p/x: 11
	p/y: as float! 2.5

	if p/x = 11 [score: score + 1]
	if p/y = as float! 2.5 [score: score + 1]

	if score = 2 [
		sys-write 1 "OK^/" 3
	]
	sys-exit 0
]
