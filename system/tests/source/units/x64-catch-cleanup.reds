Red/System [
	Title: "Red/System x86-64 catch cleanup test"
]

#if target = 'X86-64 [
	#syscall [
		sys-write: 1 [
			fd  [integer!]
			buf [c-string!]
			len [integer!]
		]
		sys-exit: 60 [status [integer!]]
	]

	inner: func [
		a [integer!]
		b [integer!]
		c [integer!]
		/local d e f g h i [integer!]
	][
		d: 4 e: 5 f: 6 g: 7 h: 8 i: 9
		catch 1 [a: a + b + c + d + e + f + g + h + i]
		throw 2
	]

	system/thrown: 0
	catch 2 [inner 1 2 3]
	if system/thrown = 2 [
		sys-write 1 "OK^/" 3
		sys-exit 0
	]
	sys-exit 1
]
