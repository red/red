Red/System [
	Title: "Red/System x86-64 wide stack argument offset smoke test"
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

	check-wide: func [
		f01 [float!] f02 [float!] f03 [float!] f04 [float!] f05 [float!]
		f06 [float!] f07 [float!] f08 [float!] f09 [float!] f10 [float!]
		f11 [float!] f12 [float!] f13 [float!] f14 [float!] f15 [float!]
		f16 [float!] f17 [float!] f18 [float!] f19 [float!] f20 [float!]
		f21 [float!] f22 [float!] f23 [float!] f24 [float!] f25 [float!]
		f26 [float!] f27 [float!] f28 [float!] f29 [float!] f30 [float!]
		marker [integer!]
		tail [float!]
		return: [integer!]
		/local score [integer!]
	][
		score: 0
		if f01 = 1.0 [score: score + 1]
		if f30 = 30.0 [score: score + 2]
		if marker = 12345 [score: score + 4]
		if tail = 31.0 [score: score + 8]
		score
	]

	msg: "OK^/"
	score: 0
	score: check-wide
		1.0 2.0 3.0 4.0 5.0
		6.0 7.0 8.0 9.0 10.0
		11.0 12.0 13.0 14.0 15.0
		16.0 17.0 18.0 19.0 20.0
		21.0 22.0 23.0 24.0 25.0
		26.0 27.0 28.0 29.0 30.0
		12345
		31.0
	if score <> 15 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
