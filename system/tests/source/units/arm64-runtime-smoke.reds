Red/System [
	Title: "Red/System ARM64 runtime smoke test"
]

#if target = 'ARM64 [
	check: func [a [integer!] b [integer!] return: [integer!]][
		a * 10 + b
	]

	if system/args-count < 1 [quit 21]
	n: check 4 2
	if n <> 42 [quit 22]
	print-line ["arm64-runtime-ok " system/args-count]
]
