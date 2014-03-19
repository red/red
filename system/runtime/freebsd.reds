Red/System [
	Title:   "Red/System FreeBSD runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %freebsd.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define OS_TYPE		6

#syscall [
	write: 4 [
		fd		[integer!]
		buffer	[c-string!]
		count	[integer!]
		return: [integer!]
	]
]

#if use-natives? = yes [
	#syscall [
		quit: 1 [							;-- "exit" syscall
			status	[integer!]
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

;-- Catching runtime errors --

;; sources:
;;  http://fxr.watson.org/fxr/source/sys/signal.h?v=FREEBSD10

#define	SIGILL		 4						;-- Illegal instruction
#define	SIGBUS		10						;-- Bus access error
#define	SIGFPE		 8						;-- Floating point error
#define	SIGSEGV		11						;-- Segmentation violation

#define SA_SIGINFO	0040h
#define SA_RESTART	0002h

#define ILL_ILLOPC		1
#define ILL_ILLOPN		2
#define ILL_ILLADR		3
#define ILL_ILLTRP		4
#define ILL_PRVOPC		5
#define ILL_PRVREG		6
#define ILL_COPROC		7
#define ILL_BADSTK		8

#define BUS_ADRALN		1
#define BUS_ADRERR		2
#define BUS_OBJERR		3

#define SEGV_MAPERR		1
#define SEGV_ACCERR		2

#define FPE_INTOVF		1
#define FPE_INTDIV		2
#define FPE_FLTDIV		3
#define FPE_FLTOVF		4
#define FPE_FLTUND		5
#define FPE_FLTRES		6
#define FPE_FLTINV		7
#define FPE_FLTSUB		8

sigaction!: alias struct! [
;	handler		[integer!]					;-- Warning: compiled as C union on most UNIX
	sigaction	[integer!]					;-- Warning: compiled as union on most UNIX
	flags		[integer!]
	mask0		[integer!]					;-- array of 4 uint32
	mask1		[integer!]
	mask2		[integer!]
	mask3		[integer!]
]

siginfo!: alias struct! [
	signal		[integer!]
	error		[integer!]
	code		[integer!]
	pid			[integer!]
	uid			[integer!]
	status		[integer!]
	address		[integer!]					;-- this field is a C union, dependent on signal
	;... remaining fields skipped
]

#import [									;-- mandatory C bindings
	LIBC-file cdecl [
		sigaction: "sigaction" [
			signum	[integer!]
			action	[sigaction!]
			oldact	[sigaction!]
			return: [integer!]
		]
	]
]

freebsd-startup-ctx: context [
	_ucontext!: alias struct! [
		sigmask0	[integer!]			;-- __sigset defined as an array of 4 uint32 
		sigmask1	[integer!]
		sigmask2	[integer!]
		sigmask3	[integer!]
		onstack		[integer!]			;-- mcontext_t inlined
		mc_gs		[integer!]
		mc_fs		[integer!]
		mc_es		[integer!]
		mc_ds		[integer!]
		mc_edi		[integer!]
		mc_esi		[integer!]
		mc_ebp		[integer!]
		mc_isp		[integer!]
		mc_ebx		[integer!]
		mc_edx		[integer!]
		mc_ecx		[integer!]
		mc_eax		[integer!]
		mc_trapno	[integer!]
		mc_err		[integer!]
		mc_eip		[integer!]
		mc_cs		[integer!]
		mc_eflags	[integer!]
		mc_esp		[integer!]
		mc_ss		[integer!]
		mc_len		[integer!]
		mc_fpformat	[integer!]
		mc_ownedfp	[integer!]
		mc_flags	[integer!]
		;... remaining fields skipped
	]

	***-on-signal: func [
		[cdecl]
		signal	[integer!]
		info	[siginfo!]
		ctx		[_ucontext!]
		/local code error
	][
		error: 99								;-- default unknown error
		code: info/code

		error: switch signal [
			SIGILL [
				switch code [
					ILL_ILLOPC [17]				;-- illegal opcode
					ILL_ILLTRP [25]				;-- illegal trap
					ILL_PRVOPC [15]				;-- privileged opcode
					ILL_ILLOPN [23]				;-- illegal operand
					ILL_ILLADR [24]				;-- illegal addressing mode
					ILL_PRVREG [31]				;-- privileged register
					ILL_COPROC [26]				;-- coprocessor error
					ILL_BADSTK [19]				;-- internal stack error
					default    [99]
				]
			]
			SIGBUS [
				switch code [
					BUS_ADRALN  [2]				;-- invalid address alignment
					BUS_ADRERR  [1]				;-- non-existant physical address
					BUS_OBJERR [28]				;-- object specific hardware error
					default    [34]
				]
			]
			SIGFPE [
				switch code [
					FPE_FLTDIV  [7]				;-- floating point divide by zero
					FPE_FLTOVF [10]				;-- floating point overflow
					FPE_FLTUND [12]				;-- floating point underflow
					FPE_FLTRES  [8]				;-- floating point inexact result
					FPE_FLTINV  [9]				;-- floating point invalid operation
					FPE_FLTSUB  [5]				;-- subscript out of range
					FPE_INTDIV [13]				;-- integer divide by zero
					FPE_INTOVF [14]				;-- integer overflow
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

		***-on-quit error ctx/mc_eip
	]

	init: does [
		__sigaction-options: declare sigaction!

		__sigaction-options/sigaction: 	as-integer :***-on-signal
		__sigaction-options/flags: 		SA_SIGINFO ;or SA_RESTART
		__sigaction-options/mask0: 0
		__sigaction-options/mask1: 0
		__sigaction-options/mask2: 0
		__sigaction-options/mask3: 0

		sigaction SIGILL  __sigaction-options as sigaction! 0
		sigaction SIGBUS  __sigaction-options as sigaction! 0
		sigaction SIGFPE  __sigaction-options as sigaction! 0
		sigaction SIGSEGV __sigaction-options as sigaction! 0
	]
]

;-------------------------------------------
;-- Retrieve command-line information from stack
;-------------------------------------------
#if type = 'exe [
	#either use-natives? = yes [
		system/args-count:	pop
		system/args-list:	as str-array! system/stack/top
		system/env-vars:	system/args-list + system/args-count + 1
	][
		;-- the current stack is pointing to main(int argc, void **argv, void **envp) C layout
		;-- we avoid the double indirection by reusing our variables from %start.reds
		system/args-count:	***__argc
		system/args-list:	as str-array! ***__argv
		system/env-vars:	system/args-list + system/args-count + 1
	]
]

#switch type [
	dll [
		***-dll-entry-point: func [[cdecl]] [
			***-main
			freebsd-startup-ctx/init
			on-load
		]
	]
	exe [
		freebsd-startup-ctx/init
	]
]
