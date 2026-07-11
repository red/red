Red/System [
	Title: "Red/System x86-64 secondary call operand smoke test"
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

	add-three: func [
		value [integer!]
		return: [integer!]
	][
		value + 3
	]

	if 10 <> add-three 7 [sys-exit 1]
	if 13 <> (10 + add-three 0) [sys-exit 2]
	sys-exit 0
]
