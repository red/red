Red/System [
	Title: "Red/System x86-64 float stack argument smoke test"
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

	check-nine-floats: func [
		a [float!]
		b [float!]
		c [float!]
		d [float!]
		e [float!]
		f [float!]
		g [float!]
		h [float!]
		i [float!]
		return: [integer!]
		/local score [integer!]
	][
		score: 0
		if a = 1.0 [score: score + 1]
		if b = 2.0 [score: score + 2]
		if c = 3.0 [score: score + 4]
		if d = 4.0 [score: score + 8]
		if e = 5.0 [score: score + 16]
		if f = 6.0 [score: score + 32]
		if g = 7.0 [score: score + 64]
		if h = 8.0 [score: score + 128]
		if i = 9.0 [score: score + 256]
		score
	]

	msg: "OK^/"
	score: 0
	score: check-nine-floats 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0
	if score <> 511 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
