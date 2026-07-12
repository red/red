Red/System [
	Title: "Red/System x86-64 argument count smoke test"
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

	sample!: alias struct! [
		value [integer!]
	]

	add-to-sample: func [
		sample [sample!]
		amount [integer!]
		return: [integer!]
	][
		sample/value + amount
	]

	msg: "OK^/"
	sample: declare sample!
	sample/value: 40
	if (add-to-sample sample 2) <> 42 [sys-exit 1]
	sys-write 1 msg 3
	sys-exit 0
]
