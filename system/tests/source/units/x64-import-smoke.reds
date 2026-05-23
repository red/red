Red/System [
	Title: "Red/System x86-64 import smoke test"
]

#include %../../../../system/runtime/lib-names.reds

#if target = 'X86-64 [
	#syscall [
		sys-exit: 60 [
			status [integer!]
		]
	]
]

#either OS = 'Windows [
	#import [
		LIBC-file cdecl [
			test-write: "_write" [
				fd		[integer!]
				buf		[c-string!]
				len		[integer!]
				return: [integer!]
			]
		]
	]
][
	#import [
		LIBC-file cdecl [
			test-write: "write" [
				fd		[integer!]
				buf		[c-string!]
				len		[integer!]
				return: [integer!]
			]
		]
	]
]

main: func [
	return: [integer!]
][
	either (test-write 1 s 6) = 6 [0][1]
]

s: "hello^/"
status: main
sys-exit status
