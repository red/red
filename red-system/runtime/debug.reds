Red/System [
	Title:   "Red/System runtime debugging functions"
	Author:  "Nenad Rakocevic"
	File: 	 %debug.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]


__line-record!: alias struct! [				;-- debug lines records associating code addresses and source lines
	address [byte-ptr!]						;-- native code pointer
	line	[integer!]						;-- source line number
	file	[integer!]						;-- source file name c-string offset (from first record)
]

__debug-lines: declare __line-record!		;-- pointer to first debug-lines record (set at link-time)

;-------------------------------------------
;-- Calculate line number for a runtime error and print it (internal function).
;-------------------------------------------
__print-debug-line: func [
	address [byte-ptr!]						;-- memory address where the runtime error happened
	/local base records
][
	records: __debug-lines
	base: as byte-ptr! records

	while [records/address < address][		;-- search for the closest record
		records: records + 1
	]
	if records/address > address [			;-- if not an exact match, use the closest lower record
		records: records - 1
	]
	print [
		lf "*** in file: " as-c-string base + records/file
		lf "*** at line: " records/line
		lf
	]
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
		s: "00000000"
		prin s + (8 - n) 
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
	nb		[integer!]						;-- number of lines to print
	return: [byte-ptr!]						;-- return the pointer (pass-thru)
	/local offset ascii i byte int-ptr data-ptr limit
][	
	assert any [unit = 1 unit = 4]
	
	print ["^/Hex dump from: " address "h^/" lf]

	offset: 0
	ascii: "                "
	limit: nb * 16
	
	data-ptr: address
	until [
		print [address ": "]
		i: 0
		until [
			i: i + 1
			
			if unit = 1 [
				prin-hex-chars as-integer address/value 2
				address: address + 1
				prin either i = 8 ["  "][" "]
			]
			if all [unit = 4 zero? (i // 4)][
				int-ptr: as int-ptr! address
				prin-hex int-ptr/value
				address: address + 4
				prin either i = 8 ["  "][" "]
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
		offset = limit
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
	dump-memory address 1 8
]

;-------------------------------------------
;-- Dump memory on screen in hex format as array of 32-bit integers (handy wrapper on dump-hex)
;-------------------------------------------
dump-hex4: func [
	address	[int-ptr!]						;-- memory address where the dump starts
	return: [int-ptr!]						;-- return the pointer (pass-thru)
][	
	as int-ptr! dump-memory as byte-ptr! address 4 8
]

;-------------------------------------------
;-- Show FPU all internal options and exception masks
;-------------------------------------------
show-fpu-info: func [/local value][
	#switch target [
		IA-32 [
			print-wide [
				"FPU type:"
				switch system/fpu/type [
					FPU_TYPE_X87 ["x87"]
					FPU_TYPE_SSE ["SSE"]
					default 	 ["unknown"]
				]
				lf
			]
			print-wide [
				"- control word:" as byte-ptr! system/fpu/control-word
				lf
			]
			print-wide [
				"- rounding    :"
				switch system/fpu/option/rounding [
					FPU_X87_ROUNDING_NEAREST ["nearest"]
					FPU_X87_ROUNDING_DOWN	 ["toward -INF"]
					FPU_X87_ROUNDING_UP		 ["toward +INF"]
					FPU_X87_ROUNDING_ZERO	 ["toward zero"]
				]
				lf
			]
			print-wide [
				"- precision   :"
				switch system/fpu/option/precision [
					FPU_X87_PRECISION_SINGLE	 ["single (32-bit)"]
					FPU_X87_PRECISION_DOUBLE	 ["double (64-bit)"]
					FPU_X87_PRECISION_DOUBLE_EXT ["double extended (80-bit)"]
				]
				lf
			]
			print-line "- raise exceptions for:"
			print-wide ["    - precision  :" either system/fpu/mask/precision   ["no"]["yes"] lf]
			print-wide ["    - underflow  :" either system/fpu/mask/underflow   ["no"]["yes"] lf]
			print-wide ["    - overflow   :" either system/fpu/mask/overflow    ["no"]["yes"] lf]
			print-wide ["    - zero-divide:" either system/fpu/mask/zero-divide ["no"]["yes"] lf]
			print-wide ["    - denormal   :" either system/fpu/mask/denormal    ["no"]["yes"] lf]
			print-wide ["    - invalid-op :" either system/fpu/mask/invalid-op  ["no"]["yes"] lf]
		]
		ARM [
			value: switch system/fpu/type [
				FPU_TYPE_VFP ["VFP"]
				default 	 ["unknown"]
			]
			print-wide ["FPU type:" value lf]
		]
	]
]