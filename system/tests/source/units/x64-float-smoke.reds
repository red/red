Red/System [
	Title: "Red/System x86-64 float smoke test"
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

	check-floats: func [
		return: [integer!]
		/local
			score [integer!]
			i     [integer!]
			f     [float!]
			f32   [float32!]
	][
		score: 0

		f: as float! 1
		f: f + as float! 2.5
		if f = as float! 3.5 [score: score + 1]

		f: f - as float! 1.5
		if f = as float! 2.0 [score: score + 1]

		f: f * as float! 4.0
		f: f / as float! 2.0
		if f = as float! 4.0 [score: score + 1]

		i: as integer! f
		if i = 4 [score: score + 1]

		f32: as float32! 2.5
		if f32 = as float32! 2.5 [score: score + 1]

		score
	]

	msg: "OK^/"
	score: 0
	score: check-floats
	if score = 5 [
		sys-write 1 msg 3
	]
	sys-exit 0
]
