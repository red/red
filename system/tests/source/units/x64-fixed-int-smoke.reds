Red/System [
	Title: "Red/System x86-64 fixed-width scalar smoke test"
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

	check-scalars: func [
		a [int8!]
		b [uint8!]
		c [int16!]
		d [uint16!]
		return: [integer!]
		/local
			score [integer!]
			la [int8!]
			lb [uint8!]
			lc [int16!]
			ld [uint16!]
			raw [byte!]
	][
		score: 0
		la: a
		lb: b
		lc: c
		ld: d
		raw: #"A"

		if la = -7 [score: score + 1]
		if lb = 250 [score: score + 1]
		if lc = -300 [score: score + 1]
		if ld = 60000 [score: score + 1]
		if la = a [score: score + 1]
		if lb = b [score: score + 1]
		if lc = c [score: score + 1]
		if ld = d [score: score + 1]
		if raw = #"A" [score: score + 1]
		score
	]

	msg: "OK^/"
	score: 0
	score: check-scalars
		as int8! -7
		as uint8! 250
		as int16! -300
		as uint16! 60000
	if score = 9 [
		sys-write 1 msg 3
	]
	sys-exit 0
]
