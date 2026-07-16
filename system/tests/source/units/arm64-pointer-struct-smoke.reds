Red/System [
	Title: "Red/System ARM64 pointer and struct smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	pair!: alias struct! [left [integer!] right [integer!]]
	cell!: alias struct! [left [integer!] right [integer!]]

	pair: declare pair!
	p: declare pointer! [integer!]
	i: 2

	p: as pointer! [integer!] pair
	p/value: 41
	p/2: 1
	if p/value <> 41 [sys-exit 1]
	if p/2 <> 1 [sys-exit 2]
	if pair/left <> 41 [sys-exit 3]
	if pair/right <> 1 [sys-exit 4]

	cells: declare struct! [
		a [cell! value]
		b [cell! value]
	]
	p: as pointer! [integer!] cells
	p/1: 11
	p/2: 22
	p/3: 33
	p/4: 44
	if p/i <> 22 [sys-exit 5]
	i: i + 2
	if p/i <> 44 [sys-exit 6]
	p/i: 66
	if cells/b/right <> 66 [sys-exit 7]
	cells/b/left: 88
	if cells/b/left <> 88 [sys-exit 9]

	record: as cell! cells
	record: record + 1
	record/left: 77
	if cells/b/left <> 77 [sys-exit 8]

	sys-exit 0
]
