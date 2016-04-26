Red/System [
	Title:   "Red/System native implementations of basic functions"
	Author:  "Nenad Rakocevic"
	File: 	 %lib-natives.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]


allocate:  func [						;-- needs a Red/System native implementation
	size		[integer!]
	return:		[byte-ptr!]
][
	;TBD
]

free: func [							;-- needs a Red/System native implementation
	buffer		[byte-ptr!]
][
	;TBD
]

set-memory: func [						;; fill a memory buffer with the same given byte ;;
	target		[byte-ptr!]				;; pointer to start of the buffer ;;
	filler		[byte!]					;; filler byte ;;
	size		[integer!]				;; size of the buffer to fill ;;
	return:		[byte-ptr!]				;; returns the start of the buffer ;;
][
	unless zero? size [
		until [
			target/1: filler
			target: target + 1
			size: size - 1
			zero? size
		]
	]
	target
]

copy-memory: func [						;; copy a memory buffer to a new region in a safe way ;; 
	target		[byte-ptr!]				;; target start address ;;
	source		[byte-ptr!]				;; source start address ;;
	size		[integer!]				;; number of bytes to copy ;;
	return:		[byte-ptr!]				;; returns the target start address ;;
	/local c
][
	unless any [zero? size source = target][
		either source < target [
			until [
				target/size: source/size
				size: size - 1
				zero? size
			]
		][
			c: 0
			until [
				target/c: source/c
				c: c + 1
				size: size - 1
				zero? size
			]
		]
	]
	target
]

compare-memory: func [				;; compare two blocks of memory ;; 
	ptr1		[byte-ptr!]     	;; pointer to block of memory ;;
	ptr2		[byte-ptr!]     	;; pointer to block of memory ;;
	size		[integer!]      	;; number of bytes to compare ;;
	return:		[integer!]
	/local
		n		[integer!]
][
	if any [zero? size ptr1 = ptr2][return 0]
	n: 0
	until [
		n: n + 1
		size: size - 1
		any [ptr1/n <> ptr2/n zero? size]
	]
	ptr1/n - ptr2/n
]

length?: func [							;; return the number of characters from a c-string value ;;
	s 		[c-string!]					;; c-string value ;;
	return: [integer!]
	/local base
][
	base: s
	while [s/1 <> null-byte][s: s + 1]
	as-integer s - base 				;-- do not count the terminal zero
]

#if type <> 'drv [

	;-- Debugging helper functions --

	prin-int: func [i [integer!] return: [integer!] /local s c n][
		;-- modified version of form-signed by Rudolf W. MEIJER (https://gist.github.com/952998)
		;-- used in signal handlers, so dynamic allocation removed to limit interferences

		if zero? i [prin "0" return 0]
		s: "-0000000000"					;-- 11 bytes wide
		if i = -2147483648 [prin "-2147483648" return i]
		n: negative? i
		if n [i: negate i]
		c: 11
		while [i <> 0][
			s/c: #"0" + (i // 10)
			i: i / 10
			c: c - 1
		]
		if n [s/c: #"-" c: c - 1]
		prin s + c
		i
	]

	prin-hex: func [i [integer!] return: [integer!] /local s c d ret][
		;-- modified version of form-hex by Rudolf W. MEIJER (https://gist.github.com/952998)
		;-- used in signal handlers, so dynamic allocation removed to limit interferences 

		if zero? i [prin "0" return i]
		s: "00000000"
		c: 8
		ret: i
		until [
			d: i // 16
			if d > 9 [d: d + 7]				;-- 7 = (#"A" - 1) - #"9"
			s/c: #"0" + d
			i: i >>> 4
			c: c - 1
			zero? c							;-- iterate on all 8 bytes to overwrite previous values
		]
		prin s
		ret
	]

]
