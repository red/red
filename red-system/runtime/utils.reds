Red/System [
	Title:   "Red/System runtime OS-independent runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %utils.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

newline: "^/"							

lf:  	 #"^/"								;-- Line-feed
cr:  	 #"^M"
tab: 	 #"^-"
space:	 #" "
slash:	 #"/"

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
;-- Low-level polymorphic print function 
;-- (not intended to be called directly)
;-------------------------------------------
_print: func [
	count	[integer!]						;-- typed values count
	list	[typed-value!]					;-- pointer on first typed value
	spaced?	[logic!]						;-- if TRUE, insert a space between items
	/local fp [typed-float!]
][
	until [
		switch list/type [
			type-logic!	   [prin either as-logic list/value ["true"]["false"]]
			type-integer!  [prin-int list/value]
			type-float!    [fp: as typed-float! list prin-float fp/value]
			type-float32!  [prin-float32 as-float32 list/value]
			type-byte!     [prin-byte as-byte list/value]
			type-c-string! [prin as-c-string list/value]
			default 	   [prin-hex list/value]
		]
		list: list + 1
		count: count - 1
		if all [spaced? count <> 0][prin " "]
		zero? count
	]
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
	prin newline
]