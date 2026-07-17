REBOL [
	Title: "Generate the ARM64 long conditional branch smoke test"
]

generate-arm64-long-branch-smoke: func [output [file!] /local source iterations][
	iterations: 70000
	source: make string! 4000000
	append source {Red/System [
	Title: "Generated ARM64 long conditional branch smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	long-forward: func [flag [logic!] return: [integer!] /local value [integer!]][
		value: 0
		if flag [
}
	repeat i iterations [append source "^-^-^-value: value + 1^/"]
	append source rejoin [{		]
		value
	]

	long-backward: func [return: [integer!] /local value [integer!]][
		value: 0
		until [
}]
	repeat i iterations [append source "^-^-^-value: value + 1^/"]
	append source rejoin [
		"^-^-^-value = " iterations "^/"
		{^-^-]
		value
	]

	if (long-forward false) <> 0 [sys-exit 1]
	if (long-forward true) <> } iterations { [sys-exit 2]
	if long-backward <> } iterations { [sys-exit 3]
	sys-exit 0
]
}]
	write output source
]
