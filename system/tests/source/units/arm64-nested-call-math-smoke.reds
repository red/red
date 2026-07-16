Red/System [
	Title: "ARM64 nested call arithmetic smoke test"
]

#if target = 'ARM64 [
	#syscall [
		sys-exit: 93 [status [integer!]]
	]

	ident: func [value [integer!] return: [integer!]][value]

	result: (3 * ident 1) + (3 * ident 2)
	either result = 9 [sys-exit 0][sys-exit result]
]
