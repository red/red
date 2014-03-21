Red/System [
	Title:   "Red/System POSIX runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %POSIX.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#either OS = 'Android [						;-- Damn FrankenSystem!
	sigaction!: alias struct! [
		handler		[integer!]				;-- Warning: compiled as C union on most UNIX
		mask		[integer!]				;-- bit array
		flags		[integer!]
		;... remaining fields skipped
	]
][
	sigaction!: alias struct! [
		handler		[integer!]				;-- Warning: compiled as union on most UNIX
		mask0		[integer!]				;-- glibc/Hurd insane inheritage...
		mask1		[integer!]	
		mask2		[integer!]	
		mask3		[integer!]	
		mask4		[integer!]	
		mask5		[integer!]
		mask6		[integer!]	
		mask7		[integer!]	
		mask8		[integer!]	
		mask9		[integer!]	
		mask10		[integer!]	
		mask11		[integer!]	
		mask12		[integer!]	
		mask13		[integer!]	
		mask14		[integer!]	
		mask15		[integer!]	
		mask16		[integer!]	
		mask17		[integer!]	
		mask18		[integer!]	
		mask19		[integer!]	
		mask20		[integer!]	
		mask21		[integer!]	
		mask22		[integer!]	
		mask23		[integer!]	
		mask24		[integer!]	
		mask25		[integer!]	
		mask26		[integer!]	
		mask27		[integer!]	
		mask28		[integer!]	
		mask29		[integer!]	
		mask30		[integer!]	
		mask31		[integer!]
		flags		[integer!]
	]
]

siginfo!: alias struct! [
	signal		[integer!]
	error		[integer!]
	code		[integer!]
	address		[integer!]					;-- this field is a C union, dependent on signal
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
;; 		http://fxr.watson.org/fxr/source/include/asm-generic/siginfo.h?v=linux-2.6;im=excerpts#L161

#include %POSIX-signals.reds

posix-startup-ctx: context [
	#switch target [
		IA-32 [
			_ucontext!: alias struct! [
				flags 		[integer!]
				link		[_ucontext!]
				ss_sp		[byte-ptr!]			;-- stack_t struct inlined
				ss_flags	[integer!]
				ss_size		[integer!]
				gs			[integer!]			;-- sigcontext struct inlined
				fs			[integer!]
				es			[integer!]
				ds			[integer!]
				edi			[integer!]
				esi			[integer!]
				ebp			[integer!]
				esp			[integer!]
				ebx			[integer!]
				edx			[integer!]
				ecx			[integer!]
				eax			[integer!]
				trapno		[integer!]
				err			[integer!]
				eip			[integer!]
				cs			[integer!]
				eflags		[integer!]
				esp_at_sig	[integer!]
				ss			[integer!]
				fpstate		[int-ptr!]
				oldmask		[integer!]
				cr2			[integer!]
				;sigmask	[...]				;-- 128 byte array ignored
			]
		]
		ARM [
			_ucontext!: alias struct! [
				flags 		[integer!]
				link		[_ucontext!]
				ss_sp		[byte-ptr!]			;-- stack_t struct inlined
				ss_flags	[integer!]
				ss_size		[integer!]
				trap_no		[integer!]
				error_code	[integer!]
				oldmask		[integer!]
				arm_r0		[integer!]
				arm_r1		[integer!]
				arm_r2		[integer!]
				arm_r3		[integer!]
				arm_r4		[integer!]
				arm_r5		[integer!]
				arm_r6		[integer!]
				arm_r7		[integer!]
				arm_r8		[integer!]
				arm_r9		[integer!]
				arm_r10		[integer!]
				arm_fp		[integer!]
				arm_ip		[integer!]
				arm_sp		[integer!]
				arm_lr		[integer!]
				arm_pc		[integer!]
				arm_cpsr	[integer!]
				fault_address [integer!]
				;sigmask	[...]				;-- 128 byte array ignored
			]
		]
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

		#switch target [
			IA-32 [***-on-quit error ctx/eip]
			ARM	  [***-on-quit error ctx/arm_pc]
		]
	]

	init: does [
		__sigaction-options: declare sigaction!

		__sigaction-options/handler: 	as-integer :***-on-signal
		__sigaction-options/flags: 		SA_SIGINFO ;or SA_RESTART

		sigaction SIGILL  __sigaction-options as sigaction! 0
		sigaction SIGBUS  __sigaction-options as sigaction! 0
		sigaction SIGFPE  __sigaction-options as sigaction! 0
		sigaction SIGSEGV __sigaction-options as sigaction! 0
	]
]

#switch type [
	dll [
		***-dll-entry-point: func [
			[cdecl]
		][
			***-main
			posix-startup-ctx/init
			on-load
		]
	]
	exe [
		posix-startup-ctx/init
	]
]