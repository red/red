Red/System [
	Title: "Red/System x86-64 typed variadic smoke test"
]

#include %../../../../system/runtime/lib-names.reds

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

	check-typed: func [
		[typed]
		count [integer!]
		list  [typed-value!]
		return: [integer!]
		/local score [integer!]
	][
		score: 0
		if count = 8 [score: score + 1]
		if all [list/type = type-int8! (as integer! list/value) = -2] [score: score + 1]
		list: list + 1
		if all [list/type = type-uint8! (as integer! list/value) = 250] [score: score + 1]
		list: list + 1
		if all [list/type = type-int16! (as integer! list/value) = -300] [score: score + 1]
		list: list + 1
		if all [list/type = type-uint16! (as integer! list/value) = 60000] [score: score + 1]
		list: list + 1
		if all [list/type = type-int32! (as integer! list/value) = -123456] [score: score + 1]
		list: list + 1
		if all [list/type = type-uint32! (as integer! list/value) = -1] [score: score + 1]
		list: list + 1
		if all [list/type = type-int64! (as integer! list/value) = -3 list/_padding = -1] [score: score + 1]
		list: list + 1
		if all [list/type = type-uint64! (as integer! list/value) = -1 list/_padding = 0] [score: score + 1]
		score
	]

	score: check-typed [
		as int8! -2
		as uint8! 250
		as int16! -300
		as uint16! 60000
		as int32! -123456
		as uint32! 4294967295
		as int64! -3
		as uint64! 4294967295
	]

	either score = 9 [
		sys-exit 0
	][
		sys-exit score
	]
]
