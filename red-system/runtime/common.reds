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
#define null?		  [null =]
 
#define forever		  [while [true]]
#define does		  [func []]
#define unless		  [if not]
#define	raise-error	  ***-on-quit
 
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
#define int-ptr!	  [pointer! [integer!]]
#define make-c-string [as c-string! allocate]

#define type-logic!		1					;-- type ID list for 'typeinfo attribut
#define type-integer!	2
#define type-byte!	    3
#define type-c-string!  4
#define type-byte-ptr!  5
#define type-int-ptr!	6
#define type-struct!	7
#define type-function!	8


newline: 	"^/"							;-- Line-feed (LF) global definition
stdout:		-1								;-- uninitialized default value
stdin:		-1								;-- uninitialized default value
stderr:		-1								;-- uninitialized default value


str-array!: alias struct! [
	item [c-string!]
]

typed-value!: alias struct! [
	value	[integer!]
	type	[integer!]	
]

__stack!: alias struct! [
	top		[int-ptr!]
	frame	[int-ptr!]
]

system: declare struct! [					;-- store runtime accessible system values
	args-count	[integer!]					;-- command-line arguments count (do not move member)
	args-list	[str-array!]				;-- command-line arguments array pointer (do not move member)
	env-vars 	[str-array!]				;-- environment variables array pointer (always null for Windows)
	stack		[__stack!]					;-- stack virtual access
]

;-------------------------------------------
;-- Convert a type ID to a c-string!
;-------------------------------------------
to-type: func [
	type 	[integer!]						;-- type ID
	return: [c-string!]						;-- type representation as c-string
	/local msg
][
	if type = type-logic! 	 [msg: "logic!"]
	if type = type-integer!  [msg: "integer!"]
	if type = type-byte! 	 [msg: "byte!"]
	if type = type-c-string! [msg: "c-string!"]
	if type = type-byte-ptr! [msg: "pointer! [byte!]"]
	if type = type-int-ptr!  [msg: "pointer! [integer!]"]
	if type = type-struct!   [msg: "struct!"]
	if type = type-function! [msg: "function!"]
	msg	
]

#switch OS [
	Windows  [#define LIBC-file	"msvcrt.dll"]
	Syllable [#define LIBC-file	"libc.so.2"]
	MacOSX	 [#define LIBC-file	"libc.dylib"]
	#default [#define LIBC-file	"libc.so.6"]
]

#either use-natives? = no [					;-- C bindings or native counterparts
	#include %lib-C.reds
][
	#include %lib-natives.reds
]

#switch OS [								;-- loading OS-specific bindings
	Windows  [#include %win32.reds]
	Syllable [#include %syllable.reds]
	MacOSX	 [#include %darwin.reds]
	#default [#include %linux.reds]
]

#if debug? = yes [#include %debug.reds]


;-- Run-time error handling --

#define RED_ERR_VMEM_RELEASE_FAILED		96
#define RED_ERR_VMEM_OUT_OF_MEMORY		97

***-on-quit: func [							;-- global exit handler
	status [integer!]
	address [integer!]
	/local msg
][
	unless zero? status [
		prin "^/*** Runtime Error "
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
		if status = 31 [msg: "privileged register"]
		
		if status = 96 [msg: "virtual memory release failed"]
		if status = 97 [msg: "out of memory"]
		if status = 98 [msg: "assertion failed at line "]
		if status = 99 [msg: "unknown error"]
		
		prin msg
		
		either status = 98 [
			prin as-c-string address
		][
			unless zero? address [
				prin "^/*** at: "
				prin-hex address
				prin "h"
			]
		]
		prin newline
	]
	
	#if OS = 'Windows [						;-- special exit handler for Windows
		***-on-win32-quit
	]
	quit status
]
