Red/System [
	Title:   "Red/System runtime debugging functions"
	Author:  "Nenad Rakocevic"
	File: 	 %debug.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]


__line-record!: alias struct! [				;-- debug lines records associating code addresses and source lines
	address [byte-ptr!]						;-- native code pointer
	line	[integer!]						;-- source line number
	file	[integer!]						;-- source file name c-string offset (from first record)
]

__func-record!: alias struct! [				;-- debug lines records associating code addresses and source lines
	entry	[byte-ptr!]						;-- entry point of the funcion
	name	[integer!]						;-- function's name c-string offset (from first record)
	arity	[integer!]						;-- function's arity
	args	[byte-ptr!]						;-- array of arguments types pointer
]

__debug-lines: declare __line-record!		;-- pointer to first debug-lines record (set at link-time)
__debug-funcs: declare __func-record!		;-- pointer to first debug-funcs record (set at link-time)

__debug-lines-nb: 0							;-- number of line records to consult (set at link-time)
__debug-funcs-nb: 0							;-- number of function records to consult (set at link-time)

;-------------------------------------------
;-- Calculate line number for a runtime error and print it (internal function).
;-------------------------------------------
__print-debug-line: func [
	address [byte-ptr!]						;-- memory address where the runtime error happened
	/local base records nb
][
	records: __debug-lines
	base: as byte-ptr! records

	nb: __debug-lines-nb
	while [records/address < address][		;-- search for the closest record
		records: records + 1
		nb: nb - 1
		if zero? nb [
			print [lf "*** Cannot determine source file/line info." lf]
			exit
		]
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
;-- Dump the native call stack (internal function).
;-------------------------------------------
__print-debug-stack: func [
	address [byte-ptr!]						;-- memory address where the runtime error happened
	/local ret base records nb next end top frame s value lines pf [pointer! [float!]] unused
][
	base:	as byte-ptr! __debug-funcs
	frame:	system/debug/frame
	ret:	as int-ptr! address
	top:	frame + 2
	lines:	40								;-- max number of lines displayed
	print-line "***"
	
	until [
		nb: __debug-funcs-nb
		records: __debug-funcs
		until [
			either nb = 1 [
				end: records/entry + 00010000h	;-- set arbitrary limit of 100KB for last func size
			][
				next: records + 1
				end: next/entry
			]
			if all [
				records/entry <= ret
				ret < end
			][
				break
			]
			records: records + 1
			nb: nb - 1
			zero? nb
		]
		unless zero? nb [
			print ["***   stack: " as-c-string base + records/name]
			if records/args = as int-ptr! -1 [
				print [lf lf]
				exit						;-- exit if a "barrier" function is encountered (set by linker)
			]
			s: as-c-string base + records/args

			unless zero? records/arity [
				loop records/arity [
					print #" "
					value: top/value
					switch as-integer s/1 [
						type-logic!	   [print as-logic value]
						type-integer!  [print value]
						type-byte!	   [prin-molded-byte as byte! value]
						type-float32!  [print as float32! value]
						type-float!	   [
							pf: as pointer! [float!] top
							unused: prin-float pf/value
							top: top + 1
						]
						type-c-string! [
							#either debug-safe? = yes [
								print [as byte-ptr! value #"h"]
							][
								prin-byte #"^""
								prin-only as-c-string value 12
								if 12 < length? as-c-string value [prin-byte #">"]
								prin-byte #"^""
							]
						]
						default		   [print [as byte-ptr! value #"h"]]
					]
					top: top + 1
					s: s + 1
				]
			]
			print lf
			lines: lines - 1
		]
		
		top: frame
		frame: as int-ptr! top/value
		top: top + 1
		ret: as int-ptr! top/value
		top: frame + 2
		
		any [zero? nb zero? lines]
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
;-- Show all FPU internal options and exception masks
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
		]
		ARM [
			value: switch system/fpu/type [
				FPU_TYPE_VFP ["VFP"]
				default 	 ["unknown"]
			]
			print-wide ["FPU type:" value lf]
			print-wide [
				"- control word:" as byte-ptr! system/fpu/control-word
				lf
			]
			value: switch system/fpu/option/rounding [
				FPU_VFP_ROUNDING_NEAREST ["nearest"]
				FPU_VFP_ROUNDING_UP		 ["toward +INF"]
				FPU_VFP_ROUNDING_DOWN	 ["toward -INF"]
				FPU_VFP_ROUNDING_ZERO	 ["toward zero"]
			]
			print-wide ["- rounding    :" value	lf]
			print-wide ["- NaN default :" system/fpu/option/NaN-mode lf]
			print-wide ["- flush2zero  :" system/fpu/option/flush-to-zero lf]

		]
	]
	
	print-line "- raise exceptions for:"
	value: either system/fpu/mask/precision   ["no"]["yes"] print-wide ["    - precision  :" value lf]
	value: either system/fpu/mask/underflow   ["no"]["yes"] print-wide ["    - underflow  :" value lf]
	value: either system/fpu/mask/overflow    ["no"]["yes"] print-wide ["    - overflow   :" value lf]
	value: either system/fpu/mask/zero-divide ["no"]["yes"] print-wide ["    - zero-divide:" value lf]
	value: either system/fpu/mask/denormal    ["no"]["yes"] print-wide ["    - denormal   :" value lf]
	value: either system/fpu/mask/invalid-op  ["no"]["yes"] print-wide ["    - invalid-op :" value lf]
]