Red/System [
	Title: "Red/System x86-64 PLT import smoke test"
]

#include %../../../../system/runtime/lib-names.reds

#if target = 'X86-64 [
	#either OS = 'Windows [
		#import [
			LIBC-file cdecl [
				test-getpid: "_getpid" [
					return: [integer!]
				]
				test-write: "_write" [
					fd		[integer!]
					buf		[c-string!]
					len		[integer!]
					return: [integer!]
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
			sys-exit: 60 [
				status [integer!]
			]
		]

		#import [
			LIBC-file cdecl [
				test-getpid: "getpid" [
					return: [integer!]
				]
				test-write: "write" [
					fd		[integer!]
					buf		[c-string!]
					len		[integer!]
					return: [integer!]
				]
			]
		]
	]

	msg: "OK^/"
	pid: 0
	wrote: 0

	pid: test-getpid
	if pid <= 0 [
		sys-exit 1
	]

	wrote: test-write 1 msg 3
	if wrote <> 3 [
		sys-exit 2
	]

	sys-exit 0
]
