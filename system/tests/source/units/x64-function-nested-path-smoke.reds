Red/System [
	Title: "Red/System x86-64 function nested path smoke test"
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

	unary-int!: alias function! [
		value [integer!]
		return: [integer!]
	]

	inner!: alias struct! [
		apply [unary-int!]
	]

	outer!: alias struct! [
		inner [inner! value]
	]

	inc: func [value [integer!] return: [integer!]][
		value + 1
	]

	holder: declare outer!
	holder/inner/apply: as unary-int! :inc

	if 8 <> holder/inner/apply 7 [
		sys-exit 1
	]
	sys-exit 0
]
