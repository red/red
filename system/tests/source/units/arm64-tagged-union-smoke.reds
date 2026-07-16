Red/System [
	Title: "Red/System ARM64 tagged union smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	point!: alias struct! [x [integer!] y [integer!]]
	shape!: alias union! [
		[variant]
		point [point! value]
		id [integer!]
	]

	shape: declare shape!
	shape/point/x: 12
	shape/point/y: 34
	if not variant? shape 'point [sys-exit 1]
	if shape/point/x <> 12 [sys-exit 2]
	if shape/point/y <> 34 [sys-exit 3]

	shape/id: 99
	if variant? shape 'point [sys-exit 4]
	if not variant? shape 'id [sys-exit 5]
	if shape/id <> 99 [sys-exit 6]
	sys-exit 0
]
