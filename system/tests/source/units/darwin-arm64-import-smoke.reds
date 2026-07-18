Red/System [
	Title: "Darwin ARM64 dynamic import smoke test"
]

#import [
	"/usr/lib/libSystem.B.dylib" cdecl [
		puts: "puts" [
			text [c-string!]
			return: [integer!]
		]
	]
]

#syscall [
	sys-exit: 1 [status [integer!]]
]

result: puts "darwin-arm64-import-ok"
sys-exit either result >= 0 [0][1]
