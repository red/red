Red/System [
	Title: "Darwin ARM64 runtime startup smoke test"
]

#syscall [
	sys-exit: 1 [status [integer!]]
]

#if ABI = 'apple-aarch64 [
	protected-values: protect [10 20]

	#import [
		"libdarwin-arm64-abi-helper.dylib" cdecl [
			check-readonly: "check_readonly" [
				address [byte-ptr!]
				return: [integer!]
			]
		]
	]
]

sys-exit either all [
	system/args-count = 2
	system/args-list <> null
	#if ABI = 'apple-aarch64 [
		1 = check-readonly as byte-ptr! protected-values
	]
][0][1]
