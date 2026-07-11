Red/System [
	Title: "Red/System x86-64 mixed overflow smoke test"
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

	check-mixed-overflow: func [
		a [integer!]
		b [integer!]
		c [integer!]
		d [integer!]
		e [integer!]
		f [integer!]
		g [integer!]
		h [float!]
		i [float!]
		j [float!]
		k [float!]
		l [float!]
		m [float!]
		n [float!]
		o [float!]
		p [float!]
		return: [integer!]
		/local score [integer!]
	][
		score: 0
		if a = 1 [score: score + 1]
		if b = 2 [score: score + 1]
		if c = 3 [score: score + 1]
		if d = 4 [score: score + 1]
		if e = 5 [score: score + 1]
		if f = 6 [score: score + 1]
		if g = 7 [score: score + 1]
		if h = 8.0 [score: score + 1]
		if i = 9.0 [score: score + 1]
		if j = 10.0 [score: score + 1]
		if k = 11.0 [score: score + 1]
		if l = 12.0 [score: score + 1]
		if m = 13.0 [score: score + 1]
		if n = 14.0 [score: score + 1]
		if o = 15.0 [score: score + 1]
		if p = 16.0 [score: score + 1]
		score
	]

	msg: "OK^/"
	score: 0
	score: check-mixed-overflow
		1 2 3 4 5 6 7
		8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0
	if score <> 16 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
