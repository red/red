Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %common.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define zero? 		  [0 =]
#define positive?	  [0 < ]				;-- space required after the lesser-than symbol
#define negative?	  [0 > ]
#define negate		  [0 -]
 
#define forever		  [while [true]]
#define does		  [func []]
#define unless		  [if not]
 
#define as-byte		  [as byte!]
#define as-logic	  [as logic!]
#define as-integer	  [as integer!]
#define as-c-string	  [as c-string!]
 
#define null-byte	  #"^(00)"
#define yes			  true
#define no			  false
#define on			  true
#define off			  false

#define byte-ptr!	  [pointer! [byte!]]
#define make-c-string [as c-string! allocate]


newline: 	"^/"
stdout:		-1								;-- uninitialized default value
stdin:		-1								;-- uninitialized default value
stderr:		-1								;-- uninitialized default value


system: struct [							;-- store runtime accessible system values
	reserved 	[integer!]					;-- place-holder to not have an empty structure
]


#switch OS [								;-- loading OS-specific bindings
	Windows  [#include %win32.reds]
	Syllable [#include %syllable.reds]
	#default [#include %linux.reds]
]

#either use-natives? = no [					;-- C bindings that have native counterparts
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
		]
	]
][
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

	length?: func [							;; return the number of characters from a c-string value ;;
		s 		[c-string!]					;; c-string value ;;
		return: [integer!]
		/local base
	][
		base: s
		while [s/1 <> null-byte][s: s + 1]
		as-integer s - base 				;-- do not count the terminal zero
	]
]


;-- Debugging helper functions --

prin-int: func [i [integer!] /local s c n][
	;-- modified version of form-signed by Rudolf W. MEIJER (https://gist.github.com/952998)
	;-- used in signal handlers, so dynamic allocation removed to limit interferences
	
	if zero? i [prin "0" exit]
	s: "-2147483648"						;-- 11 bytes wide
	if i = -2147483648 [prin s exit]
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
]

prin-hex: func [i [integer!] /local s c d][
	;-- modified version of form-hex by Rudolf W. MEIJER (https://gist.github.com/952998)
	;-- used in signal handlers, so dynamic allocation removed to limit interferences 
	
	if zero? i [prin "0" exit]
	s: "00000000"
	c: 8
	until [
		d: i // 16
		if d > 9 [d: d + 7]					;-- 7 = (#"A" - 1) - #"9"
		s/c: #"0" + d
		i: i >>> 4
		c: c - 1
		zero? c								;-- iterate on all 8 bytes to overwrite previous values
	]
	prin s
]

***-on-quit: func [							;-- global exit handler
	status [integer!]
	address [integer!]
	/local msg
][
	unless zero? status [
		prin "*** Runtime Error "
		prin-int status
		prin ": "
		
		if status =  1 [msg: "access violation"]
		if status =  2 [msg: "invalid alignment"]
		if status =  3 [msg: "breakpoint"]
		if status =  4 [msg: "single step"]
		if status =  5 [msg: "bounds exceeded"]
		if status =  6 [msg: "float denormal operan"]
		if status =  7 [msg: "float divide by zero"]
		if status =  8 [msg: "float inexact result"]
		if status =  9 [msg: "float invalid operation"]
		if status = 10 [msg: "float overflow"]
		if status = 11 [msg: "float stack check"]
		if status = 12 [msg: "float underflow"]
		if status = 13 [msg: "integer divide by zero"]
		if status = 14 [msg: "integer overflow"]
		if status = 15 [msg: "privileged instruction"]
		if status = 16 [msg: "invalid virtual address"]
		if status = 17 [msg: "illegal instruction"]
		if status = 18 [msg: "non-continuable exception"]
		if status = 19 [msg: "stack error or overflow"]
		if status = 20 [msg: "invalid disposition"]
		if status = 21 [msg: "guard page"]
		if status = 22 [msg: "invalid handle"]
		if status = 23 [msg: "illegal operand"]
		if status = 24 [msg: "illegal addressing mode"]
		if status = 25 [msg: "illegal trap"]
		if status = 26 [msg: "coprocessor error"]
		if status = 27 [msg: "non-existant physical address"]
		if status = 28 [msg: "object specific hardware error"]		
		if status = 29 [msg: "hardware memory error consumed AR"]
		if status = 30 [msg: "hardware memory error consumed AO"]
		if status = 99 [msg: "unknown error"]
		
		prin msg
		
		unless zero? address [
			prin "^/*** at: "
			prin-hex address
			prin "h"
		]
		prin newline
	]
	quit status
]
