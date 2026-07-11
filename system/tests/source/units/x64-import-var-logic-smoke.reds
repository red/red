Red/System [
	Title: "Red/System x86-64 shared-library imported logic data smoke test"
]

#if all [target = 'X86-64 OS <> 'Windows] [
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

	#import [
		"libx64import-extra.so" cdecl [
			x64-flag: "x64-flag" [logic!]
		]
	]

	msg: "OK^/"

	if not x64-flag [
		sys-exit 1
	]

	x64-flag: no

	if x64-flag [
		sys-exit 2
	]

	sys-write 1 msg 3
	sys-exit 0
]
