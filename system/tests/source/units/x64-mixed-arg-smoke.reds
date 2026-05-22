Red/System [
	Title: "Red/System x86-64 mixed argument smoke test"
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

	check-mixed: func [
		a [integer!]
		b [integer!]
		c [integer!]
		d [integer!]
		e [integer!]
		f [integer!]
		g [integer!]
		h [float!]
		return: [integer!]
		/local score [integer!]
	][
		score: 0
		if a = 1 [score: score + 1]
		if b = 2 [score: score + 2]
		if c = 3 [score: score + 4]
		if d = 4 [score: score + 8]
		if e = 5 [score: score + 16]
		if f = 6 [score: score + 32]
		if g = 7 [score: score + 64]
		if h = 8.5 [score: score + 128]
		score
	]

	msg: "OK^/"
	score: 0
	score: check-mixed 1 2 3 4 5 6 7 8.5
	if score <> 255 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
