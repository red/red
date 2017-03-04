Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %common.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define zero? 		  [0 =]
#define positive?	  [0 < ]				;-- space required after the lesser-than symbol
#define negative?	  [0 > ]
#define negate		  [0 -]
#define null?		  [null =]

#define halt		  [quit 0]
#define forever		  [while [true]]
#define does		  [func []]
#define unless		  [if not]
#define	raise-error	  ***-on-quit
#define probe		  print-line
 
#define as-byte		  [as byte!]
#define as-logic	  [as logic!]
#define as-integer	  [as integer!]
#define as-float	  [as float!]
#define as-float32	  [as float32!]
#define as-c-string	  [as c-string!]
 
#define null-byte	  #"^(00)"
#define yes			  true
#define no			  false
#define on			  true
#define off			  false

#define byte-ptr!	  [pointer! [byte!]]
#define int-ptr!	  [pointer! [integer!]]
#define float32-ptr!  [pointer! [float32!]]

#define make-c-string [as c-string! allocate]

#define type-logic!		1					;-- type ID list for 'typeinfo attribut
#define type-integer!	2
#define type-byte!	    3
#define type-float32!	4
#define type-float64!	5					;-- float! is just an alias for float64!
#define type-float!		5
#define type-c-string!  6
#define type-byte-ptr!  7
#define type-int-ptr!	8
#define type-function!	9
#define type-struct!	1000
#define any-struct?		[1000 <=]
#define alias?  		[1001 <=]

#define CATCH_ALL_EXCEPTIONS -1

;-- Global variables definition --
stdout:		-1								;-- uninitialized default value
stdin:		-1								;-- uninitialized default value
stderr:		-1								;-- uninitialized default value

newline: "^/"

lf:  	 #"^/"								;-- Line-feed
cr:  	 #"^M"
tab: 	 #"^-"
space:	 #" "
slash:	 #"/"
esc:	 #"^["

pi: 3.141592653589793

str-array!: alias struct! [
	item [c-string!]
]

typed-value!: alias struct! [
	type	 [integer!]	
	value	 [integer!]
	_padding [integer!]						;-- extra space for 64-bit values
]

typed-float32!: alias struct! [
	type	 [integer!]	
	value	 [float32!]
	_padding [integer!]						;-- extra space for 64-bit values	
]

typed-float!: alias struct! [
	type	 [integer!]	
	value	 [float!]
]

re-throw: func [/local id [integer!]][
	id: system/thrown						;-- system/* cannot be passed as argument for now
	throw id								;-- let the exception pass through
]

#switch OS [
	Windows  [#define LIBREDRT-file "libRedRT.dll"]
	MacOSX	 [#define LIBREDRT-file "libRedRT.dylib"]
	#default [#define LIBREDRT-file "libRedRT.so"]
]

#include %system.reds
#include %lib-names.reds

#either use-natives? = no [					;-- C bindings or native counterparts
	#include %libc.reds
][
	#include %lib-natives.reds
]

#switch OS [								;-- loading OS-specific bindings
	Windows  [
		#either type = 'drv [
			#include %win32-driver.reds
		][
			#include %win32.reds
		]
	]
	Syllable [#include %syllable.reds]
	MacOSX	 [#include %darwin.reds]
	Android	 [#include %android.reds]
	FreeBSD	 [#include %freebsd.reds]
	#default [#include %linux.reds]
]


#if type = 'exe [
	#switch target [						;-- do not raise exceptions as we use some C functions may cause exception
		IA-32 [
			system/fpu/control-word: 037Fh
			system/fpu/update
		]
		ARM [
			system/fpu/option/rounding:  FPU_VFP_ROUNDING_NEAREST
			system/fpu/mask/overflow:	 yes
			system/fpu/mask/zero-divide: yes
			system/fpu/mask/invalid-op:  yes
			system/fpu/update
		]
	]
]

#if type <> 'drv [

	#include %utils.reds					;-- load additional utility functions


	#if debug? = yes [#include %debug.reds]	;-- loads optionally debug functions

	;-- Run-time error handling --
	
	__set-stack-on-crash: func [
		return: [int-ptr!]
		/local address frame top
	][
		top: system/stack/frame				;-- skip the set-stack-on-crash stack frame 
		frame: as int-ptr! top/value
		top: top + 1
		address: as int-ptr! top/value
		top: frame + 2

		system/debug: declare __stack!		;-- allocate a __stack! struct
		system/debug/frame: frame
		system/debug/top: top
		address
	]
	
	#if target = 'ARM [
		***-on-div-error: func [			;-- special error handler wrapper for _div_ intrinsic
			code [integer!]
			/local
				address [int-ptr!]
		][
			address: __set-stack-on-crash
			***-on-quit code as-integer address
		]
	]

	***-on-quit: func [						;-- global exit handler
		status  [integer!]
		address [integer!]
		/local 
			msg [c-string!]
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
				27	["non-existent physical address"]
				28	["object specific hardware error"]
				29	["hardware memory error consumed AR"]
				30	["hardware memory error consumed AO"]
				31	["privileged register"]
				32	["segmentation fault"]	;-- generic SIGSEGV message
				33	["FPU error"]			;-- generic SIGFPE message
				34	["Bus error"]			;-- generic SIGBUS message

				95	["no CATCH for THROW"]
				98	["assertion failed"]
				99	["unknown error"]

				100	["no value matched in CASE"]
				101	["no value matched in SWITCH"]

				default ["unknown error code!"]
			]
			print msg

			#either debug? = yes [
				if null? system/debug [__set-stack-on-crash]
				__print-debug-line  as byte-ptr! address
				__print-debug-stack as byte-ptr! address
			][
				print [lf "*** at: " as byte-ptr! address "h" lf]
			]
		]

		#if OS = 'Windows [					;-- special exit handler for Windows
			win32-startup-ctx/on-quit
		]
		quit status
	]
	
	***-uncaught-exception: does [
		either system/thrown = 0BADCAFEh [	;-- RED_THROWN_ERROR exception value (label not defined if R/S used standalone)
			***-on-quit 0 0					;-- Red error, normal exit
		][
			***-on-quit 95 as-integer system/pc ;-- Red/System uncaught exception, report it
		]
	]
]

#if type = 'exe [
	push system/stack/frame					;-- save previous frame pointer
	push 0									;-- exception return address slot
	push 0									;-- exception threshold
	system/stack/frame: system/stack/top	;-- reposition frame pointer just after the catch slots
]
push CATCH_ALL_EXCEPTIONS					;-- exceptions root barrier
push :***-uncaught-exception				;-- root catch (also keeps stack aligned on 64-bit)

#if type = 'dll [
	#if libRedRT? = yes [
		#switch OS [								;-- init OS-specific handlers
			Windows  [win32-startup-ctx/init]
			Syllable []
			#default [posix-startup-ctx/init]
		]
	]
]