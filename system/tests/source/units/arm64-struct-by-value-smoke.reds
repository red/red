Red/System [
	Title: "Red/System ARM64 struct by-value ABI smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	pair!: alias struct! [left [integer!] right [integer!]]
	quad!: alias struct! [a [integer!] b [integer!] c [integer!] d [integer!]]
	large!: alias struct! [a [integer!] b [integer!] c [integer!] d [integer!] e [integer!] f [integer!]]

	sum-pair: func [value [pair! value] return: [integer!]][
		value/left + value/right
	]

	sum-quad: func [value [quad! value] return: [integer!]][
		value/a + value/b + value/c + value/d
	]
	return-pair: func [value [pair! value] return: [pair! value]][value]
	return-quad: func [value [quad! value] return: [quad! value]][value]
	return-local-pair: func [value [pair! value] return: [pair! value] /local tmp [pair! value]][
		tmp/left: value/left + 1
		tmp/right: value/right + 1
		tmp
	]
	return-local-quad: func [value [quad! value] return: [quad! value] /local tmp [quad! value]][
		tmp/a: value/a
		tmp/b: value/b
		tmp/c: value/c
		tmp/d: value/d
		tmp
	]
	return-large: func [value [large! value] marker [integer!] return: [large! value]][
		if marker <> 99 [sys-exit 8]
		value
	]

	p: declare pair!
	q: declare quad!
	rp: declare pair!
	rq: declare quad!
	l: declare large!
	rl: declare large!
	p/left: 12
	p/right: 30
	if 42 <> sum-pair p [sys-exit 1]

	q/a: 1
	q/b: 2
	q/c: 4
	q/d: 8
	if 15 <> sum-quad q [sys-exit 2]

	rp: return-pair p
	if rp/left <> 12 [sys-exit 3]
	if rp/right <> 30 [sys-exit 4]
	rq: return-quad q
	if rq/a <> 1 [sys-exit 5]
	if rq/d <> 8 [sys-exit 6]
	rp: return-local-pair p
	if rp/left <> 13 [sys-exit 10]
	if rp/right <> 31 [sys-exit 11]
	rq: return-local-quad q
	if rq/a <> 1 [sys-exit 12]
	if rq/d <> 8 [sys-exit 13]

	l/a: 1
	l/b: 2
	l/c: 3
	l/d: 4
	l/e: 5
	l/f: 6
	return-large l 99
	if l/a <> 1 [sys-exit 14]
	if l/f <> 6 [sys-exit 15]
	rl: return-large l 99
	if rl/a <> 1 [sys-exit 7]
	if rl/f <> 6 [sys-exit 9]
	sys-exit 0
]
