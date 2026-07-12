Red/System [
	Title: "Red/System x86-64 hidden struct return smoke test"
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

	large!: alias struct! [
		a [integer!]
		b [integer!]
		c [integer!]
		d [integer!]
	]

	build-large: func [
		base   [integer!]
		factor [integer!]
		return: [large! value]
		/local result [large! value]
	][
		result/a: base
		result/b: factor
		result/c: base + factor
		result/d: base * factor
		result
	]

	msg: "OK^/"
	result: declare large!
	result: build-large 40 2
	if result/a <> 40 [sys-exit 1]
	if result/b <> 2 [sys-exit 2]
	if result/c <> 42 [sys-exit 3]
	if result/d <> 80 [sys-exit 4]
	sys-write 1 msg 3
	sys-exit 0
]
