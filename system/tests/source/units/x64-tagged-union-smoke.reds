Red/System [
	Title: "Red/System x86-64 tagged union smoke test"
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

	choice!: alias union! [
		[variant]
		i32 [integer!]
		u8  [uint8!]
	]

	v: declare choice!
	score: 0

	v/i32: 123
	if variant? v 'i32 [score: score + 1]
	if not variant? v 'u8 [score: score + 1]
	if v/i32 = 123 [score: score + 1]

	if score = 3 [
		sys-write 1 "OK^/" 3
		sys-exit 0
	]
	sys-exit 1
]
