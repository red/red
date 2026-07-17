Red/System [
	Title: "Red/System ARM64 ELF imported variable smoke test"
]

#if target = 'ARM64 [
	#import ["libc.so.6" cdecl [
		libc-optind: "optind" [integer!]
	]]
	#syscall [sys-exit: 93 [status [integer!]]]

	if libc-optind <= 0 [sys-exit 1]
	libc-optind: 7
	if libc-optind <> 7 [sys-exit 2]
	optind-ptr: :libc-optind
	if optind-ptr/value <> 7 [sys-exit 3]
	optind-ptr/value: 9
	if libc-optind <> 9 [sys-exit 4]
	sys-exit 0
]
