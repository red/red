Red/System [
	Title: "Red/System ARM64 floating-point ABI smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	add-float: func [a [float!] b [float!] return: [float!]][a + b]
	add-float32: func [a [float32!] b [float32!] return: [float32!]][a + b]

	check-mixed: func [
		a [integer!] b [float!] c [integer!] d [float!]
		return: [float!]
	][
		b + d + as float! (a + c)
	]

	sum-nine: func [
		a [float!] b [float!] c [float!] d [float!] e [float!]
		f [float!] g [float!] h [float!] i [float!]
		return: [float!]
	][
		a + b + c + d + e + f + g + h + i
	]

	f: add-float 1.25 2.25
	if f <> as float! 3.5 [sys-exit 1]

	f32: add-float32 (as float32! 1.5) (as float32! 2.5)
	if f32 <> as float32! 4.0 [sys-exit 2]

	f: check-mixed 2 3.5 4 5.5
	if f <> as float! 15.0 [sys-exit 3]

	f: sum-nine 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0
	if f <> as float! 45.0 [sys-exit 4]

	f: (add-float 1.0 2.0) + (add-float 3.0 4.0)
	if f <> as float! 10.0 [sys-exit 5]

	sys-exit 0
]
