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
#define any-struct?		[1000 <=]
#define alias?  		[1001 <=]

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
	switch type [
		type-integer!   ["integer!"]
		type-c-string!  ["c-string!"]
		type-logic! 	["logic!"]
		type-byte! 	    ["byte!"]
		type-byte-ptr!  ["pointer! [byte!]"]
		type-int-ptr!   ["pointer! [integer!]"]
		type-struct!    ["struct!"]
		type-function!  ["function!"]
		default			[either alias? type ["alias"]["not valid type"]]
	]
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
		
		msg: switch status [
			1	["access violation"]
			2	["invalid alignment"]
			3	["breakpoint"]
			4	["single step"]
			5	["bounds exceeded"]
			6	["float denormal operan"]
			7	["float divide by zero"]
			8	["float inexact result"]
			9	["float invalid operation"]
			10	["float overflow"]
			11	["float stack check"]
			12	["float underflow"]
			13	["integer divide by zero"]
			14	["integer overflow"]
			15	["privileged instruction"]
			16	["invalid virtual address"]
			17	["illegal instruction"]
			18	["non-continuable exception"]
			19	["stack error or overflow"]
			20	["invalid disposition"]
			21	["guard page"]
			22	["invalid handle"]
			23	["illegal operand"]
			24	["illegal addressing mode"]
			25	["illegal trap"]
			26	["coprocessor error"]
			27	["non-existant physical address"]
			28	["object specific hardware error"]		
			29	["hardware memory error consumed AR"]
			30	["hardware memory error consumed AO"]
			31	["privileged register"]
		
			96	["virtual memory release failed"]
			97	["out of memory"]
			98	["assertion failed"]
			99	["unknown error"]
		
			100	["no value matched in CASE"]
			101	["no value matched in SWITCH"]
			
			default ["unknown error code!"]
		]
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
