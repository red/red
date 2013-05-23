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

sigaction!: alias struct! [
	handler		[integer!]					;-- Warning: compiled as union on most UNIX
	mask0		[integer!]					;-- glibc/Hurd insane inheritage...
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

#define	SIGILL		 4						;-- Illegal instruction
#define SIGBUS		 7						;-- Bus access error
#define	SIGFPE		 8						;-- Floating point error
#define	SIGSEGV		11						;-- Segmentation violation

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
					1 [17]						;-- illegal opcode
					2 [23]						;-- illegal operand
					3 [24]						;-- illegal addressing mode
					4 [25]						;-- illegal trap
					5 [15]						;-- privileged opcode
					6 [31]						;-- privileged register
					7 [26]						;-- coprocessor error
					8 [19]						;-- internal stack error
					default [99]
				]
			]
			SIGBUS [
				switch code [
					1 [2]						;-- invalid address alignment
					2 [27]						;-- non-existant physical address
					3 [28]						;-- object specific hardware error
					4 [29]						;-- hardware memory error consumed (action required)
					5 [30]						;-- hardware memory error consumed (action optional)
					default [34]
				]
			]
			SIGFPE [
				switch code [
					1 [13]						;-- integer divide by zero
					2 [14]						;-- integer overflow
					3 [7]						;-- floating point divide by zero
					4 [10]						;-- floating point overflow
					5 [12]						;-- floating point underflow
					6 [8]						;-- floating point inexact result
					7 [9]						;-- floating point invalid operation
					8 [5]						;-- subscript out of range
					default [33]
				]
			]
			SIGSEGV [
				switch code [
					1 [1]						;-- address not mapped to object
					2 [16]						;-- invalid permissions for mapped object
					default [32]
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