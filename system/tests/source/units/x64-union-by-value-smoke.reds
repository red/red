Red/System [
	Title: "Red/System x86-64 union by-value smoke test"
]

#if target = 'X86-64 [
	#either OS = 'Windows [
		#import [
			"kernel32.dll" stdcall [
				sys-exit: "ExitProcess" [
					status [integer!]
				]
			]
		]
	][
		#syscall [
			sys-exit: 60 [
				status [integer!]
			]
		]
	]

	raw!: alias union! [
		i [integer!]
		p [pointer! [integer!]]
	]

	point!: alias struct! [
		x [integer!]
		y [integer!]
	]

	shape!: alias union! [
		[variant]
		point [point! value]
		id    [integer!]
	]

	copy-raw: func [
		value [raw! value]
		return: [integer!]
	][
		value/i
	]

	sum-shape: func [
		value [shape! value]
		return: [integer!]
	][
		either variant? value 'point [
			value/point/x + value/point/y
		][
			0
		]
	]

	shape-is-point: func [
		value [shape! value]
		return: [logic!]
	][
		variant? value 'point
	]

	shape-x: func [
		value [shape! value]
		return: [integer!]
	][
		value/point/x
	]

	shape-y: func [
		value [shape! value]
		return: [integer!]
	][
		value/point/y
	]

	v: declare raw!
	shape: declare shape!
	v/i: 4321
	if 4321 <> copy-raw v [sys-exit 1]

	shape/point/x: 12
	if not variant? shape 'point [sys-exit 2]
	shape/point/y: 34
	if not shape-is-point shape [sys-exit 3]
	if 12 <> shape-x shape [sys-exit 4]
	if 34 <> shape-y shape [sys-exit 5]
	if 46 <> sum-shape shape [sys-exit 6]

	shape/id: 99
	if 0 <> sum-shape shape [sys-exit 7]
	sys-exit 0
]
