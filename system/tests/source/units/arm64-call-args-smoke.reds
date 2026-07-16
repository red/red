Red/System [
	Title: "Red/System ARM64 scalar call argument smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	add-two: func [a [integer!] b [integer!] return: [integer!]][a + b]

	sum-ten: func [
		a [integer!] b [integer!] c [integer!] d [integer!] e [integer!]
		f [integer!] g [integer!] h [integer!] i [integer!] j [integer!]
		return: [integer!]
	][
		a + b + c + d + e + f + g + h + i + j
	]

	status: sum-ten 1 2 3 4 5 6 7 8 9 10
	if status <> 55 [sys-exit status]
	status: add-two 10 (add-two 20 3)
	either status = 33 [sys-exit 0][sys-exit status]
]
