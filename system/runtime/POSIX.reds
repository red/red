Red/System [
	Title:   "Red/System POSIX runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %POSIX.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define OS_DIR_SEP 47						;-- #"/"

#import [									;-- mandatory C bindings
	LIBC-file cdecl [
		sigaction: "sigaction" [
			signum	[integer!]
			action	[sigaction!]
			oldact	[sigaction!]
			return: [integer!]
		]
		sigemptyset: "sigemptyset" [
			mask	[integer!]
			return: [integer!]
		]
	]
]

stdin:  0
stdout: 1
stderr: 2

#if use-natives? = yes [
	prin: func [s [c-string!] return: [integer!]][
		write stdout s length? s
	]
]

;====== Catching runtime errors ======

;; sources:
;;		http://www.kernel.org/doc/man-pages/online/pages/man2/sigaction.2.html

#include %POSIX-signals.reds

posix-startup-ctx: context [

	UCTX_DEFINITION

	***-on-signal: func [
		[cdecl]
		signal	[integer!]
		info	[siginfo!]
		ctx		[_ucontext!]
		/local code error
	][
		error: 99								;-- default unknown error
		code: info/code
		
		system/debug: declare __stack!			;-- allocate a __stack! struct
		system/debug/frame: as int-ptr! UCTX_GET_STACK_FRAME(ctx)
		system/debug/top: 	as int-ptr! UCTX_GET_STACK_TOP(ctx)

		error: switch signal [
			SIGILL [
				switch code [
					ILL_ILLOPC [17]				;-- illegal opcode
					ILL_ILLOPN [23]				;-- illegal operand
					ILL_ILLADR [24]				;-- illegal addressing mode
					ILL_ILLTRP [25]				;-- illegal trap
					ILL_PRVOPC [15]				;-- privileged opcode
					ILL_PRVREG [31]				;-- privileged register
					ILL_COPROC [26]				;-- coprocessor error
					ILL_BADSTK [19]				;-- internal stack error
					default    [99]
				]
			]
			SIGBUS [
				switch code [
					BUS_ADRALN    [2]			;-- invalid address alignment
					BUS_ADRERR   [27]			;-- non-existant physical address
					BUS_OBJERR   [28]			;-- object specific hardware error
					BUS_MCERR_AR [29]			;-- hardware memory error consumed (action required)
					BUS_MCERR_AO [30]			;-- hardware memory error consumed (action optional)
					default      [34]
				]
			]
			SIGFPE [
				switch code [
					FPE_INTDIV [13]				;-- integer divide by zero
					FPE_INTOVF [14]				;-- integer overflow
					FPE_FLTDIV  [7]				;-- floating point divide by zero
					FPE_FLTOVF [10]				;-- floating point overflow
					FPE_FLTUND [12]				;-- floating point underflow
					FPE_FLTRES  [8]				;-- floating point inexact result
					FPE_FLTINV  [9]				;-- floating point invalid operation
					FPE_FLTSUB  [5]				;-- subscript out of range
					default    [33]
				]
			]
			SIGSEGV [
				switch code [
					SEGV_MAPERR  [1]			;-- address not mapped to object
					SEGV_ACCERR [16]			;-- invalid permissions for mapped object
					default     [32]
				]
			]
		]

		***-on-quit error UCTX_INSTRUCTION(ctx)
	]

	init: func [
		/local
			__sigaction-options [sigaction!]
	][
		__sigaction-options: declare sigaction!

		__sigaction-options/sigaction: 	as-integer :***-on-signal
		__sigaction-options/flags: 		SA_SIGINFO ;or SA_RESTART

		sigaction SIGILL  __sigaction-options as sigaction! 0
		sigaction SIGBUS  __sigaction-options as sigaction! 0
		sigaction SIGFPE  __sigaction-options as sigaction! 0
		sigaction SIGSEGV __sigaction-options as sigaction! 0
	]
]

#if OS <> 'MacOSX [								;-- OS X has it's own start code
	#switch type [
		dll [
			***-dll-entry-point: func [
				[cdecl]
			][
				#either red-pass? = no [		;-- only for pure R/S DLLs
					***-boot-rs
					on-load
					***-main
				][
					on-load
				]
			]
		]
		exe [
			posix-startup-ctx/init
		]
	]
]
