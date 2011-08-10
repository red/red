Red/System [
	Title:   "Red/System runtime debugging functions"
	Author:  "Nenad Rakocevic"
	File: 	 %debug.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

;-------------------------------------------
;-- Print an integer as hex number on screen, limited to n characters
;-------------------------------------------
prin-hex-chars: func [
	i [integer!]							;-- input integer to print
	n [integer!]							;-- max number of characters to print (right-aligned)
	return: [integer!]						;-- return the input integer (pass-thru)
	/local s c d ret
][
	s: "00000000"
	if zero? i [
		print s + (8 - n) 
		return i
	]
	c: 8
	ret: i
	until [
		d: i // 16
		if d > 9 [d: d + 7]					;-- 7 = (#"A" - 1) - #"9"
		s/c: #"0" + d
		i: i >>> 4
		c: c - 1
		zero? c								;-- iterate on all 8 bytes to overwrite previous values
	]
	prin s + (8 - n)
	ret
]

;-------------------------------------------
;-- Dump memory on screen in hex format
;-------------------------------------------
dump-memory: func [
	address	[byte-ptr!]						;-- memory address where the dump starts
	unit	[integer!]						;-- size of memory chunks to print in hex format (1 or 4 bytes)
	return: [byte-ptr!]						;-- return the pointer (pass-thru)
	/local offset ascii i byte int-ptr data-ptr
][	
	assert any [unit = 1 unit = 4]
	
	print ["^/Hex dump from: " address "h^/" lf]

	offset: 0
	ascii: "                "
	
	data-ptr: address
	until [
		print [address ": "]
		i: 0
		until [
			i: i + 1
			
			if unit = 1 [
				prin-hex-chars as-integer address/value 2
				address: address + 1
				print either i = 8 ["  "][" "]
			]
			if all [unit = 4 zero? (i // 4)][
				int-ptr: as int-ptr! address
				prin-hex int-ptr/value
				address: address + 4
				print either i = 8 ["  "][" "]
			]
			
			byte: data-ptr/value
			ascii/i: either byte < as-byte 32 [
				either byte = null-byte [#"."][#"^(FE)"]
			][
				byte
			]
			
			data-ptr: data-ptr + 1
			i = 16
		]
		print [space ascii lf]
		offset: offset + 16
		offset = 128
	]
	address
]

;-------------------------------------------
;-- Dump memory on screen in hex format as array of bytes (handy wrapper on dump-hex)
;-------------------------------------------
dump-hex: func [
	address	[byte-ptr!]						;-- memory address where the dump starts
	return: [byte-ptr!]						;-- return the pointer (pass-thru)
][	
	dump-memory address 1
]

;-------------------------------------------
;-- Dump memory on screen in hex format as array of 32-bit integers (handy wrapper on dump-hex)
;-------------------------------------------
dump-hex4: func [
	address	[byte-ptr!]						;-- memory address where the dump starts
	return: [byte-ptr!]						;-- return the pointer (pass-thru)
][	
	dump-memory address 4
]

