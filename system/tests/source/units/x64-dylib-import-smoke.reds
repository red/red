Red/System [
	Title: "Red/System x86-64 shared-library import smoke test"
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
			x64-add-one: "add-one" [
				value   [integer!]
				return: [integer!]
			]
		]
	]

	msg: "OK^/"
	len: 0
	len: x64-add-one 2
	sys-write 1 msg len
	sys-exit 0
]
