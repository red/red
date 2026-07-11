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
		list  [pointer! [integer!]]
		size  [integer!]
		return: [integer!]
		/local score [integer!]
	][
		score: 0
		if count = 4 [score: score + 1]
		if list/1 = 11 [score: score + 1]
		if list/2 = 22 [score: score + 1]
		if list/3 = 33 [score: score + 1]
		if list/4 = 44 [score: score + 1]
		if size = 16 [score: score + 1]
		score
	]

	msg: "OK^/"
	score: 0
	score: check-variadic [11 22 33 44]

	if score <> 6 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
