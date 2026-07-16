Red/System [
	Title: "Red/System ARM64 scalar floating-point smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	check: func [
		return: [integer!]
		/local
			f   [float!]
			f32 [float32!]
			i   [integer!]
	][
		f: as float! 1
		f: f + as float! 2.5
		if f <> as float! 3.5 [sys-exit 1]

		f: f - as float! 1.5
		if f <> as float! 2.0 [sys-exit 2]

		f: (f * as float! 4.0) / as float! 2.0
		if f <> as float! 4.0 [sys-exit 3]

		i: as integer! f
		if i <> 4 [sys-exit 4]

		f: as float! i
		if f <> as float! 4.0 [sys-exit 5]

		f32: as float32! 2.5
		if f32 <> as float32! 2.5 [sys-exit 6]

		f: as float! f32
		if f <> as float! 2.5 [sys-exit 7]
		0
	]

	sys-exit check
]
