Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %common.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
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


system: declare struct! [					;-- store runtime accessible system values
	reserved 	[integer!]					;-- place-holder to not have an empty structure
]


#switch OS [								;-- loading OS-specific bindings
	Windows  [#include %win32.reds]
	Syllable [#include %syllable.reds]
	#default [#include %linux.reds]
]

#either use-natives? = no [					;-- C bindings or native counterparts
	#include %lib-C.reds
][
	#include %lib-natives.reds
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
