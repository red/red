Red/System [
	Title: "Red/System x86-64 stack argument smoke test"
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

	check-seven: func [
		a [integer!]
		b [integer!]
		c [integer!]
		d [integer!]
		e [integer!]
		f [integer!]
		g [integer!]
		return: [integer!]
		/local score [integer!]
	][
		score: 0
		if a = 11 [score: score + 1]
		if b = 22 [score: score + 1]
		if c = 33 [score: score + 1]
		if d = 44 [score: score + 1]
		if e = 55 [score: score + 1]
		if f = 66 [score: score + 1]
		if g = 77 [score: score + 1]
		score
	]

	msg: "OK^/"
	score: 0
	score: check-seven 11 22 33 44 55 66 77
	if score = 7 [
		sys-write 1 msg 3
	]
	sys-exit 0
]
