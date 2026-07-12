Red/System [
	Title: "Red/System x86-64 variadic smoke test"
]

#include %../../../../system/runtime/lib-names.reds

#if target = 'X86-64 [
	#either OS = 'Windows [
		#import [
			LIBC-file cdecl [
				sys-write: "_write" [
					fd	[integer!]
					buf [c-string!]
					len [integer!]
				]
			]
		]

		#import [
			"kernel32.dll" stdcall [
				sys-exit: "ExitProcess" [
					status [integer!]
				]
			]
		]
	][
		#syscall [
			sys-write: 1 [
				fd  [integer!]
				buf [c-string!]
				len [integer!]
			]
			sys-exit: 60 [
				status [integer!]
			]
		]
	]

	check-variadic: func [
		[variadic]
		count [integer!]
		list  [vararg-ptr!]
		size  [integer!]
		return: [integer!]
		/local score [integer!]
	][
		score: 0
		if count = 4 [score: score + 1]
		if (as-integer list/1) = 11 [score: score + 1]
		if (as-integer list/2) = 22 [score: score + 1]
		if (as-integer list/3) = 33 [score: score + 1]
		if (as-integer list/4) = 44 [score: score + 1]
		if size = 32 [score: score + 1]
		score
	]

	check-variadic-logic: func [
		[variadic]
		count [integer!]
		list  [vararg-ptr!]
		size  [integer!]
		return: [integer!]
		/local score [integer!] flag? [logic!]
	][
		score: 0
		flag?: as-logic list/1
		if not flag? [score: score + 1]
		flag?: as-logic list/2
		if flag? [score: score + 1]
		if size = 16 [score: score + 1]
		score
	]

	msg: "OK^/"
	score: 0
	score: check-variadic [11 22 33 44]
	score: score + check-variadic-logic [0 0000000100000000h]

	if score <> 9 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
