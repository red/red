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

	nullable-local: func [
		return: [integer!]
		/local fn [unary-int!]
	][
		fn: as unary-int! 0
		if :fn <> null [return 1]
		fn: as unary-int! :inc
		if :fn = null [return 2]
		if 10 <> fn 9 [return 3]
		0
	]

	holder: declare box!
	holder/apply: as unary-int! :inc

	if 6 <> local-call 5 [
		sys-exit 1
	]
	if 8 <> holder/apply 7 [
		sys-exit 2
	]
	if nullable-local <> 0 [
		sys-exit 3
	]
	sys-exit 0
]
