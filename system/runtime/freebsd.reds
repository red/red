Red/System [
	Title:   "Red/System FreeBSD runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %freebsd.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
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

sigaction!: alias struct! [
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

;; sources:
;;  http://fxr.watson.org/fxr/source/sys/ucontext.h?v=FREEBSD10#L54
;;  http://fxr.watson.org/fxr/source/x86/include/ucontext.h?v=FREEBSD10;im=10#L92,162

#define UCTX_DEFINITION [
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
]

#define UCTX_INSTRUCTION(ctx)		[ctx/mc_eip]
#define UCTX_GET_STACK_TOP(ctx)		[ctx/mc_esp]
#define UCTX_GET_STACK_FRAME(ctx)	[ctx/mc_ebp]

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

#include %POSIX.reds
