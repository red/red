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
#define type-function!	7
#define type-struct!	1000
#define alias?  [1001 <=]
#define any-struct?		[1000 <=]

;-- Global variables definition --
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
	pc			[byte-ptr!]					;-- CPU program counter value
	alias		[integer!]					;-- aliases ID virtual access
]

;-------------------------------------------
;-- Convert a type ID to a c-string!
;-------------------------------------------
form-type: func [
	type 	[integer!]				  		;-- type ID
	return: [c-string!]						;-- type representation as c-string
][
	if type = type-integer!    [return "integer!"]
	if type = type-c-string!   [return "c-string!"]
	if type = type-logic! 	   [return "logic!"]
	if type = type-byte! 	     [return "byte!"]
	if type = type-byte-ptr!   [return "pointer! [byte!]"]
	if type = type-int-ptr!    [return "pointer! [integer!]"]
	if type = type-struct!     [return "struct!"]
	if type = type-function!   [return "function!"]
	if alias? type             [return "alias"]
	"not valid type"
]

#switch OS [
	Windows  [#define LIBC-file	"msvcrt.dll"]
	Syllable [#define LIBC-file	"libc.so.2"]
	MacOSX	 [#define LIBC-file	"libc.dylib"]
	#default [
		#either config-name = 'Android [	;-- @@ see if declaring it as an OS wouldn't be too costly
			#define LIBC-file	"libc.so"
		][
			#define LIBC-file	"libc.so.6"	;-- Linux
		]
	]
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

#include %utils.reds						;-- load additional utility functions

#if debug? = yes [#include %debug.reds]		;-- loads optionally debug functions

;-- Run-time error handling --

#define RED_ERR_VMEM_RELEASE_FAILED		96
#define RED_ERR_VMEM_OUT_OF_MEMORY		97

***-on-quit: func [							;-- global exit handler
	status [integer!]
	address [integer!]
	/local msg
][
	unless zero? status [
		print [lf "*** Runtime Error " status ": "]
		
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
		if status = 98 [msg: "assertion failed"]
		if status = 99 [msg: "unknown error"]
		
		print msg
		
		#either debug? = yes [
			__print-debug-line as byte-ptr! address
		][
			print [lf "*** at: " as byte-ptr! address "h" lf]
		]
	]
	
	#if OS = 'Windows [						;-- special exit handler for Windows
		***-on-win32-quit
	]
	quit status
]
