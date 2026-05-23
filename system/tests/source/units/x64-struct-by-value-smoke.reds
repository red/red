Red/System [
	Title: "Red/System x86-64 struct by-value smoke test"
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

	pair!: alias struct! [
		left  [integer!]
		right [integer!]
	]

	quad!: alias struct! [
		a [integer!]
		b [integer!]
		c [integer!]
		d [integer!]
	]

	sept!: alias struct! [
		a [integer!]
		b [integer!]
		c [integer!]
		d [integer!]
		e [integer!]
		f [integer!]
		g [integer!]
	]

	sum-pair: func [
		value [pair! value]
		return: [integer!]
	][
		value/left + value/right
	]

	sum-quad: func [
		value [quad! value]
		return: [integer!]
	][
		value/a + value/b + value/c + value/d
	]

	sum-sept: func [
		value [sept! value]
		return: [integer!]
	][
		value/a + value/b + value/c + value/d + value/e + value/f + value/g
	]

	p: declare pair!
	q: declare quad!
	s: declare sept!
	p/left: 12
	p/right: 30
	if 42 <> sum-pair p [sys-exit 1]

	q/a: 1
	q/b: 2
	q/c: 4
	q/d: 8
	if 15 <> sum-quad q [sys-exit 2]

	s/a: 1
	s/b: 2
	s/c: 3
	s/d: 4
	s/e: 5
	s/f: 6
	s/g: 7
	if 28 <> sum-sept s [sys-exit 3]
	sys-exit 0
]
