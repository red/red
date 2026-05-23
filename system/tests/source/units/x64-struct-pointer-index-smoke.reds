Red/System [
	Title: "Red/System x86-64 struct pointer variable index smoke test"
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

	cell!: alias struct! [
		left  [integer!]
		right [integer!]
	]

	p: declare pointer! [integer!]
	i: 2
	score: 0
	msg: "OK^/"

	cells: declare struct! [
		a [cell! value]
		b [cell! value]
	]

	p: as pointer! [integer!] cells
	p/1: 11
	p/2: 22
	p/3: 33
	p/4: 44

	if p/i = 22 [score: score + 1]
	i: i + 2
	if p/i = 44 [score: score + 2]

	p/i: 66
	if cells/b/right = 66 [score: score + 4]

	if score <> 7 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
