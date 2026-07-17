Red/System [
	Title: "Red/System ARM64 function pointer and callback smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	unary-int!: alias function! [value [integer!] return: [integer!]]
	nine-int!: alias function! [
		a [integer!] b [integer!] c [integer!] d [integer!] e [integer!]
		f [integer!] g [integer!] h [integer!] i [integer!]
		return: [integer!]
	]
	box!: alias struct! [apply [unary-int!]]
	wide-box!: alias struct! [apply [nine-int!]]

	inc: func [value [integer!] return: [integer!]][value + 1]
	sum-nine: func [
		a [integer!] b [integer!] c [integer!] d [integer!] e [integer!]
		f [integer!] g [integer!] h [integer!] i [integer!]
		return: [integer!]
	][a + b + c + d + e + f + g + h + i]

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
	wide-holder: declare wide-box!
	holder/apply: as unary-int! :inc
	wide-holder/apply: as nine-int! :sum-nine

	if 6 <> local-call 5 [sys-exit 1]
	if 8 <> holder/apply 7 [sys-exit 2]
	if nullable-local <> 0 [sys-exit 3]
	if 45 <> wide-holder/apply 1 2 3 4 5 6 7 8 9 [sys-exit 4]
	sys-exit 0
]
