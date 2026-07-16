Red/System [
	Title: "Red/System ARM64 ELF import smoke test"
]

#if target = 'ARM64 [
	#import ["libc.so.6" cdecl [
		puts: "puts" [text [c-string!] return: [integer!]]
	]]
	#syscall [sys-exit: 93 [status [integer!]]]

	puts "arm64-import-ok"
	sys-exit 0
]
