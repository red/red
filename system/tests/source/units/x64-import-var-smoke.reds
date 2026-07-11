Red/System [
	Title: "Red/System x86-64 shared-library imported data smoke test"
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
		"libx64test-dll1.so" cdecl [
			x64-i: "i" [integer!]
		]
	]

	msg: "OK^/"

	if x64-i <> 56 [
		sys-exit 1
	]

	x64-i: 41

	if x64-i <> 41 [
		sys-exit 2
	]

	sys-write 1 msg 3
	sys-exit 0
]
