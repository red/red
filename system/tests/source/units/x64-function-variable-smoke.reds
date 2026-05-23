Red/System [
	Title: "Red/System x86-64 function variable smoke test"
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

	op!: alias function! [
		left  [integer!]
		right [integer!]
		return: [integer!]
	]

	add-values: func [
		left  [integer!]
		right [integer!]
		return: [integer!]
	][
		left + right
	]

	sub-values: func [
		left  [integer!]
		right [integer!]
		return: [integer!]
	][
		left - right
	]

	call-local: func [
		return: [integer!]
		/local
			op-local [op!]
			result   [integer!]
	][
		op-local: as op! :sub-values
		result: op-local 9 4
		result
	]

	msg: "OK^/"
	score: 0
	result: 0
	op-global: as op! :add-values

	result: op-global 2 3
	if result = 5 [score: score + 1]
	result: call-local
	if result = 5 [score: score + 2]

	if score <> 3 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
