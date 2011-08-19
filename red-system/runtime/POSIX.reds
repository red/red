Red/System [
	Title:   "Red/System POSIX runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %POSIX.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
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

;-- Catching runtime errors --

;; sources:
;;		http://www.kernel.org/doc/man-pages/online/pages/man2/sigaction.2.html
;; 		http://fxr.watson.org/fxr/source/include/asm-generic/siginfo.h?v=linux-2.6;im=excerpts#L161

#define	SIGILL		 4						;-- Illegal instruction
#define SIGBUS		 7						;-- Bus access error
#define	SIGFPE		 8						;-- Floating point error
#define	SIGSEGV		11						;-- Segmentation violation

_ucontext!: alias struct! [
	flags 		[integer!]
	link		[_ucontext!]
	ss_sp		[byte-ptr!]					;-- stack_t struct inlined
	ss_flags	[integer!]
	ss_size		[integer!]
	gs			[integer!]					;-- sigcontext struct inlined
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
	;sigmask	[...]						;-- 128 byte array ignored
]

***-on-signal: func [
	[callback]
	signal	[integer!]
	info	[siginfo!]
	ctx		[_ucontext!]
	/local code error
][
	error: 99								;-- default unknown error
	code: info/code
	
	if signal = SIGILL [
		if code = 1 [error: 17]				;-- illegal opcode
		if code = 2 [error: 23]				;-- illegal operand
		if code = 3 [error: 24]				;-- illegal addressing mode
		if code = 4 [error: 25]				;-- illegal trap
		if code = 5 [error: 15]				;-- privileged opcode
		if code = 6 [error: 31]				;-- privileged register
		if code = 7 [error: 26]				;-- coprocessor error
		if code = 8 [error: 19]				;-- internal stack error
	]
	if signal = SIGBUS [
		if code = 1 [error:  2]				;-- invalid address alignment
		if code = 2 [error: 27]				;-- non-existant physical address
		if code = 3 [error: 28]				;-- object specific hardware error
		if code = 4 [error: 29]				;-- hardware memory error consumed (action required)
		if code = 5 [error: 30]				;-- hardware memory error consumed (action optional)
	]
	if signal = SIGFPE [
		if code = 1 [error: 13]				;-- integer divide by zero
		if code = 2 [error: 14]				;-- integer overflow
		if code = 3 [error:  7]				;-- floating point divide by zero
		if code = 4 [error: 10]				;-- floating point overflow
		if code = 5 [error: 12]				;-- floating point underflow
		if code = 6 [error:  8]				;-- floating point inexact result
		if code = 7 [error:  9]				;-- floating point invalid operation
		if code = 8 [error:  5]				;-- subscript out of range
	]
	if signal = SIGSEGV [
		if code = 1 [error:  1]				;-- address not mapped to object
		if code = 2 [error: 16]				;-- invalid permissions for mapped object
	]

	***-on-quit error ctx/eip
]

__sigaction-options: declare sigaction!

__sigaction-options/handler: 	as-integer :***-on-signal
__sigaction-options/flags: 		SA_SIGINFO ;or SA_RESTART

sigaction SIGILL  __sigaction-options as sigaction! 0
sigaction SIGBUS  __sigaction-options as sigaction! 0
sigaction SIGFPE  __sigaction-options as sigaction! 0
sigaction SIGSEGV __sigaction-options as sigaction! 0
