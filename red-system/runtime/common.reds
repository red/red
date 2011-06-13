Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %common.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define zero? 		[0 =]
#define positive?	[0 < ]			;-- space required after the lesser-than symbol
#define negative?	[0 > ]
#define negate		[0 -]

#define forever		[while [true]]
#define does		[func []]
#define unless		[if not]

#define as-byte		[as byte!]
#define as-logic	[as logic!]
#define as-integer	[as integer!]
#define as-c-string	[as c-string!]

#define null-char	#"^(00)"
#define yes			true
#define no			false
#define on			true
#define off			false

#define byte-ptr!	c-string!


null: 		pointer [integer!]		;-- null pointer declaration
newline: 	"^/"
stdout:		-1						;-- uninitialized default value
stdin:		-1						;-- uninitialized default value
stderr:		-1						;-- uninitialized default value


#switch OS [						;-- loading OS-specific bindings
	Windows  [#include %win32.reds]
	Syllable [#include %syllable.reds]
	#default [#include %linux.reds]
]


#either C-binding? = yes [
	#import [
		LIBC-file cdecl [
			allocate: "malloc" [
				size		[integer!]
				return:		[byte-ptr!]
			]
			free: "free" [
				block		[byte-ptr!]
			]
			set-memory:  "memset" [
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
			length?: 	 "strlen" [
				command		[c-string!]
				return:		[integer!]
			]
		]
	]
][
	allocate:  func [						;-- needs a Red/System native implementation
		size		[integer!]
		return:		[byte-ptr!]
	][
		;TBD
	]
	
	free: "free" [							;-- needs a Red/System native implementation
		buffer		[byte-ptr!]
	][
		;TBD
	]
	
	set-memory: func [						;; fill a memory buffer with the same byte ;;
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

	length?: func [							;; return the number of characters from a c-string value ;;
		s 		[c-string!]					;; c-string value ;;
		return: [integer!]
		/local base
	][
		base: s
		while [s/1 <> null-char][s: s + 1]
		as-integer s - base 		;-- do not count the terminal zero
	]
]

***-on-quit: func [status [integer!]][	;-- global exit handler
	;TBD: insert runtime error handler here
	quit status
]