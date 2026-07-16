Red/System [
	Title: "Red/System ARM64 homogeneous floating aggregate ABI smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	pair64!: alias struct! [x [float!] y [float!]]
	quad32!: alias struct! [a [float32!] b [float32!] c [float32!] d [float32!]]

	sum64: func [value [pair64! value] return: [float!]][value/x + value/y]
	sum32: func [value [quad32! value] return: [float32!]][
		value/a + value/b + value/c + value/d
	]

	p64: declare pair64!
	p32: declare quad32!
	p64/x: as float! 1.25
	p64/y: as float! 2.75
	f: sum64 p64
	if f <> as float! 4.0 [sys-exit 1]

	p32/a: as float32! 1.0
	p32/b: as float32! 2.0
	p32/c: as float32! 3.0
	p32/d: as float32! 4.0
	f32: sum32 p32
	if f32 <> as float32! 10.0 [sys-exit 2]
	sys-exit 0
]
