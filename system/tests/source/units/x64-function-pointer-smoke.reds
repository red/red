Red/System [
	Title: "Red/System x86-64 function pointer smoke test"
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

	box!: alias struct! [
		apply [unary-int!]
	]

	inc: func [value [integer!] return: [integer!]][
		value + 1
	]

	local-call: func [
		value [integer!]
		return: [integer!]
		/local fn [unary-int!]
	][
		fn: as unary-int! :inc
		fn value
	]

	holder: declare box!
	holder/apply: as unary-int! :inc

	if 6 <> local-call 5 [
		sys-exit 1
	]
	if 8 <> holder/apply 7 [
		sys-exit 2
	]
	sys-exit 0
]
