Red/System [
	Title: "Red/System ARM64 homogeneous floating aggregate ABI smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	pair64!: alias struct! [x [float!] y [float!]]
	triple64!: alias struct! [x [float!] y [float!] z [float!]]
	quad64!: alias struct! [a [float!] b [float!] c [float!] d [float!]]
	quad32!: alias struct! [a [float32!] b [float32!] c [float32!] d [float32!]]
	hfa-box!: alias struct! [value [triple64! value]]

	sum64: func [value [pair64! value] return: [float!]][value/x + value/y]
	sum-triple64: func [value [triple64! value] return: [float!]][
		value/x + value/y + value/z
	]
	return-triple64: func [return: [triple64! value] /local value [triple64! value]][
		value/x: 1.0
		value/y: 2.0
		value/z: 3.0
		value
	]
	return-quad64: func [return: [quad64! value] /local value [quad64! value]][
		value/a: 1.0
		value/b: 2.0
		value/c: 3.0
		value/d: 4.0
		value
	]
	sum32: func [value [quad32! value] return: [float32!]][
		value/a + value/b + value/c + value/d
	]
	check-spilled64: func [
		a [float!] b [float!] c [float!] d [float!] e [float!] f [float!] g [float!]
		value [pair64! value] tail [float!] marker [integer!]
		return: [integer!]
	][
		either all [
			a = 1.0 b = 2.0 c = 3.0 d = 4.0 e = 5.0 f = 6.0 g = 7.0
			value/x = 1.25 value/y = 2.75 tail = 8.0 marker = 42
		][1][0]
	]
	check-spilled32: func [
		a [float32!] b [float32!] c [float32!] d [float32!]
		e [float32!] f [float32!] g [float32!]
		value [quad32! value] tail [float32!] marker [integer!]
		return: [integer!]
	][
		either all [
			a = as float32! 1.0 b = as float32! 2.0
			c = as float32! 3.0 d = as float32! 4.0
			e = as float32! 5.0 f = as float32! 6.0 g = as float32! 7.0
			value/a = as float32! 1.0 value/b = as float32! 2.0
			value/c = as float32! 3.0 value/d = as float32! 4.0
			tail = as float32! 8.0 marker = 42
		][1][0]
	]

	p64: declare pair64!
	t64: declare triple64!
	q64: declare quad64!
	p32: declare quad32!
	hfa-box: declare hfa-box!
	p64/x: as float! 1.25
	p64/y: as float! 2.75
	f: sum64 p64
	if f <> as float! 4.0 [sys-exit 1]

	t64: return-triple64
	if t64/x <> 1.0 [sys-exit 5]
	if t64/y <> 2.0 [sys-exit 6]
	if t64/z <> 3.0 [sys-exit 7]
	q64: return-quad64
	if q64/a <> 1.0 [sys-exit 8]
	if q64/d <> 4.0 [sys-exit 9]
	if 6.0 <> sum-triple64 return-triple64 [sys-exit 10]
	hfa-box/value: return-triple64
	if hfa-box/value/z <> 3.0 [sys-exit 11]

	p32/a: as float32! 1.0
	p32/b: as float32! 2.0
	p32/c: as float32! 3.0
	p32/d: as float32! 4.0
	f32: sum32 p32
	if f32 <> as float32! 10.0 [sys-exit 2]

	if 1 <> check-spilled64 1.0 2.0 3.0 4.0 5.0 6.0 7.0 p64 8.0 42 [sys-exit 3]
	if 1 <> check-spilled32
		(as float32! 1.0) (as float32! 2.0) (as float32! 3.0) (as float32! 4.0)
		(as float32! 5.0) (as float32! 6.0) (as float32! 7.0)
		p32 (as float32! 8.0) 42
	[sys-exit 4]
	sys-exit 0
]
