Red/System [
	Title: "Red/System x86-64 pointer parity smoke test"
]

#if target = 'X86-64 [
	#either OS = 'Windows [
		#import [
			"kernel32.dll" stdcall [
				sys-exit: "ExitProcess" [
					status [integer!]
				]
			]
		]
	][
		#syscall [
			sys-exit: 60 [
				status [integer!]
			]
		]
	]

	pair!: alias struct! [
		a [pointer! [integer!]]
		b [pointer! [integer!]]
	]

	pointer-hex: as byte-ptr! DEADBEEFh

	read-pointer: func [
		value [pointer! [integer!]]
		return: [integer!]
	][
		value/value
	]

	check: func [
		return: [integer!]
		/local
			source [struct! [n [integer!] m [integer!]]]
			box    [pair!]
	][
		source: declare struct! [n [integer!] m [integer!]]
		box: declare pair!
		source/n: 42
		source/m: 84
		box/a: as pointer! [integer!] source
		box/b: box/a + 1

		if 42 <> read-pointer box/a [return 1]
		if 84 <> read-pointer box/b [return 2]
		if pointer-hex <> as byte-ptr! DEADBEEFh [return 3]
		0
	]

	sys-exit check
]
