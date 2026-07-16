Red/System [
	Title: "Red/System ARM64 function variable smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	op!: alias function! [
		left [integer!]
		right [integer!]
		return: [integer!]
	]

	add-values: func [left [integer!] right [integer!] return: [integer!]][left + right]
	sub-values: func [left [integer!] right [integer!] return: [integer!]][left - right]

	call-local: func [
		return: [integer!]
		/local op-local [op!]
	][
		op-local: as op! :sub-values
		op-local 9 4
	]

	op-global: as op! :add-values
	result: op-global 2 3
	if result <> 5 [sys-exit 1]
	result: call-local
	if result <> 5 [sys-exit 2]
	sys-exit 0
]
