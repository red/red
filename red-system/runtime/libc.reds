Red/System [
	Title:   "Red/System C library bindings"
	Author:  "Nenad Rakocevic"
	File: 	 %lib-C.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#import [
	LIBC-file cdecl [
		allocate:	 "malloc" [
			size		[integer!]
			return:		[byte-ptr!]
		]
		free:		 "free" [
			block		[byte-ptr!]
		]
		set-memory:	 "memset" [
			target		[byte-ptr!]
			filler		[byte!]
			size		[integer!]
			return:		[byte-ptr!]
		]
		copy-memory: "memmove" [
			target		[byte-ptr!]
			source		[byte-ptr!]
			size		[integer!]
			return:		[byte-ptr!]
		]
		length?:	 "strlen" [
			buffer		[c-string!]
			return:		[integer!]
		]
		quit:		 "exit" [
			status		[integer!]
		]
		putchar: 	 "putchar" [
			char		[byte!]
		]
		printf: 	 "printf" [[variadic]]
	]
]

prin: func [s [c-string!] return: [c-string!] /local p][
	p: s
	while [p/1 <> null-byte][
		putchar p/1
		p: p + 1
	]
	s
]

prin-int: func [i [integer!] return: [integer!]][
	printf ["%i" i]
	i
]

prin-hex: func [i [integer!] return: [integer!]][
	printf ["%08X" i]
	i
]

prin-float: func [f [float!] return: [float!]][
	printf ["%.14g" f]
	f
]

prin-float32: func [f [float32!] return: [float32!]][
	printf ["%.7g" as-float f]
	f
]
