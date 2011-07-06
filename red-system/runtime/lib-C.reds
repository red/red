Red/System [
	Title:   "Red/System C library bindings"
	Author:  "Nenad Rakocevic"
	File: 	 %lib-C.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
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
			command		[c-string!]
			return:		[integer!]
		]
		quit:		 "exit" [
			status		[integer!]
		]
		print: 		 "puts" [
			str			[c-string!]
		]
		printf-1: 	 "printf" [
			format		[c-string!]
			str			[integer!]		;-- placeholder for any type
		]
	]
]

prin: func [s [c-string!]][
	printf-1 "%s" as-integer s
]

prin-int: func [i [integer!]][
	printf-1 "%i" i
]

prin-hex: func [i [integer!]][
	printf-1 "%08X" i	
]