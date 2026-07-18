Red/System [
	Title: "Darwin ARM64 imported variable smoke test"
]

#import [
	"/usr/lib/libSystem.B.dylib" cdecl [
		libc-optind: "optind" [integer!]
	]
]

#syscall [
	sys-exit: 1 [status [integer!]]
]

if libc-optind <= 0 [sys-exit 1]
libc-optind: 7
if libc-optind <> 7 [sys-exit 2]
optind-ptr: :libc-optind
if optind-ptr/value <> 7 [sys-exit 3]
optind-ptr/value: 9
if libc-optind <> 9 [sys-exit 4]
sys-exit 0
