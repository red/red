Red/System [
	Title: "Red/System x86-64 float argument smoke test"
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

	add-float: func [
		a [float!]
		b [float!]
		return: [float!]
	][
		a + b
	]

	add-float32: func [
		a [float32!]
		b [float32!]
		return: [float32!]
	][
		a + b
	]

	msg: "OK^/"
	score: 0
	f: add-float 1.25 2.25
	f32: add-float32 as float32! 1.5 as float32! 2.5
	if f = as float! 3.5 [
		score: score + 1
	]
	if f32 = as float32! 4.0 [
		score: score + 1
	]
	if score = 2 [
		sys-write 1 msg 3
	]
	sys-exit 0
]
