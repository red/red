Red/System [
	Title:   "Red/System runtime OS-independent runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %utils.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define BACK_TO_CONSOLE [
	#if any [OS = 'macOS OS = 'Windows OS = 'Linux][
		#if GUI-engine = 'terminal [exec/gui/back-to-console]
	]	
]

#define ENTER_TUI [
	#if any [OS = 'macOS OS = 'Windows OS = 'Linux][
		#if GUI-engine = 'terminal [exec/gui/enter-tui]
	]
]

;-------------------------------------------
;-- Print a given number of characters at max from a c-string
;-------------------------------------------
prin-only: func [s [c-string!] len [integer!] return: [c-string!] /local p][
	p: s
	while [p/1 <> null-byte][
		if zero? len [break]
		prin-byte p/1
		p: p + 1
		len: len - 1
	]
	s
]

;-------------------------------------------
;-- Print a byte value in source format (MOLD-ed format)
;-------------------------------------------
prin-molded-byte: func [b [byte!] /local i c][
	prin {#"}
	i: as-integer b
	switch i [
		00h [prin "^^@"]
		09h [prin "^^-"]
		0Ah [prin "^^/"]
		1Bh [prin "^^]"]
		default [
			if i <= 1Fh [
				c: #"A" + i - 1
				prin-byte #"^^"
				prin-byte c
			]
			if all [i > 1Fh i <= 7Fh][prin-byte b]
			if i > 7Fh [prin "^^(" prin-2hex i prin-byte #")"]
		]
	]
	prin-byte #"^""
]

;-------------------------------------------
;-- Print in console a single byte as an ASCII character
;-------------------------------------------
prin-byte: func [
	c 		[byte!]							;-- ASCII value to print
	return: [byte!]
	/local char
][
	char: " "
	char/1: c
	prin char
	c
]

;-------------------------------------------
;-- Print a 64-bit integer stored as two 32-bit words
;-------------------------------------------
prin-uint64-parts: func [
	lo		[integer!]
	hi		[integer!]
	/local
		s	[c-string!]
		c	[integer!]
		value [uint64!]
		rem	[integer!]
][
	value: ((as uint64! as uint32! hi) << 32) or (as uint64! as uint32! lo)
	if value = as uint64! 0 [prin "0" exit]
	s: "00000000000000000000"				;-- max 20 digits
	c: 20
	until [
		rem: as integer! value % as uint64! 10
		s/c: #"0" + rem
		c: c - 1
		value: value / as uint64! 10
		value = as uint64! 0
	]
	prin s + c
]

;-------------------------------------------
;-- Print an int64! value stored as two 32-bit words
;-------------------------------------------
prin-int64-parts: func [
	lo		[integer!]
	hi		[integer!]
][
	if hi < 0 [
		prin "-"
		lo: (not lo) + 1
		hi: not hi
		if zero? lo [hi: hi + 1]
	]
	prin-uint64-parts lo hi
]

;-------------------------------------------
;-- Low-level polymorphic print function 
;-- (not intended to be called directly)
;-------------------------------------------
_print: func [
	count	[integer!]						;-- typed values count
	list	[typed-value!]					;-- pointer on first typed value
	spaced?	[logic!]						;-- if TRUE, insert a space between items
	/local 
		fp		 [typed-float!]
		fp32	 [typed-float32!]
		unused	 [float!]
		unused32 [float32!]
		s		 [c-string!]
		c		 [byte!]
		len		 [integer!]
		_i		 [integer!]
][
	BACK_TO_CONSOLE
		until [
			switch list/type [
			type-logic!	   [either as-logic as integer! list/value [prin "true"][prin "false"]]
			type-integer!  [prin-int as integer! list/value]
			type-int8!	   [prin-int as integer! list/value]
			type-uint8!	   [prin-int as integer! list/value]
			type-int16!	   [prin-int as integer! list/value]
			type-uint16!   [prin-int as integer! list/value]
			type-uint32!   [prin-uint64-parts as integer! list/value 0]
			type-int64!	   [prin-int64-parts as integer! list/value list/_padding]
			type-uint64!   [prin-uint64-parts as integer! list/value list/_padding]
			type-float!    [fp: as typed-float! list unused: prin-float fp/value]
			type-float32!  [fp32: as typed-float32! list unused32: prin-float32 fp32/value]
			type-byte!     [_i: as integer! list/value prin-byte as-byte _i]
			type-c-string! [s: as-c-string list/value prin s]
			default 	   [prin-hex as integer! list/value]
		]
		count: count - 1
		
		if all [spaced? count <> 0][
			switch list/type [
				type-c-string! [
					len: length? s
					s: s + len - 1
					c: s/1
				]
				type-byte! [
					_i: as integer! list/value
					c: as-byte _i
				]
				default [
					c: null-byte
				]
			]
			if all [
				c <> #" "
				c <> #"^/"
				c <> #"^M"
				c <> #"^-"
			][
				prin " "
			]
		]
		list: list + 1
		zero? count
	]
	fflush 0
	ENTER_TUI
]

;-------------------------------------------
;-- Polymorphic print in console
;-- (inserts a space character between each item)
;-------------------------------------------
print-wide: func [
	[typed]	count [integer!] list [typed-value!]
][
	_print count list yes
]

;-------------------------------------------
;-- Polymorphic print in console
;-------------------------------------------
print: func [
	[typed]	count [integer!] list [typed-value!]
][
	_print count list no
]

;-------------------------------------------
;-- Polymorphic print in console, with a line-feed 
;-------------------------------------------
print-line: func [
	[typed]	count [integer!] list [typed-value!]
][
	_print count list no
	prin-byte lf
]

#enum trigonometric-type! [
	TYPE_TANGENT
	TYPE_COSINE
	TYPE_SINE
]

degree-to-radians: func [
	val		[float!]
	type	[integer!]
	return: [float!]
	/local
		factor [float!]
][
	val: fmod val 360.0
	if any [val > 180.0 val < -180.0] [
		factor: either val < 0.0 [360.0][-360.0]
		val: val + factor
	]
	if any [val > 90.0 val < -90.0] [
		if type = TYPE_TANGENT [
			factor: either val < 0.0 [180.0][-180.0]
			val: val + factor
		]
		if type = TYPE_SINE [
			factor: either val < 0.0 [-180.0][180.0]
			val: factor - val
		]
	]
	val: val * PI / 180.0			;-- to radians
	val
]

equal-string?: func [
	str1	[c-string!]
	str2	[c-string!]
	return: [logic!]
	/local
		size [integer!]
		size2 [integer!]
		c	 [byte!]
][
	size: length? str1
	size2: length? str2
	if size <> size2 [return no]
	
	while [c: str1/1 c <> null-byte][
		if c <> str2/1 [return no]
		str1: str1 + 1
		str2: str2 + 1
	]
	yes
]
