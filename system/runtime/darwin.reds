Red/System [
	Title:   "Red/System MacOS X runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %darwin.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define OS_TYPE		4

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
	mask		[integer!]					;-- bit array
	flags		[integer!]
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
;;  http://fxr.watson.org/fxr/source/bsd/sys/_structs.h?v=xnu-1456.1.26#L124,126
;;  http://fxr.watson.org/fxr/source/bsd/i386/_structs.h?v=xnu-1456.1.26#L92,95

#define UCTX_DEFINITION [
	_mcontext!: alias struct! [
		trapno		[integer!]				;-- _STRUCT_X86_EXCEPTION_STATE32 inlined
		err			[integer!]
		faultvaddr	[integer!]
		eax			[integer!]				;-- _STRUCT_X86_THREAD_STATE32 inlined
		ebx			[integer!]
		ecx			[integer!]
		edx			[integer!]
		edi			[integer!]
		esi			[integer!]
		ebp			[integer!]
		esp			[integer!]
		ss			[integer!]
		eflags		[integer!]
		eip			[integer!]
		cs			[integer!]
		ds			[integer!]
		es			[integer!]
		fs			[integer!]
		gs			[integer!]
		;... _STRUCT_X86_FLOAT_STATE32 skipped
	]

	_ucontext!: alias struct! [
		onstack		[integer!]
		sigmask		[integer!]
		ss_sp		[byte-ptr!]			;-- stack_t struct inlined
		ss_size		[integer!]
		ss_flags	[integer!]
		link		[_ucontext!]
		mcsize		[integer!]
		mcontext	[_mcontext!]
	]
]

#define UCTX_INSTRUCTION(ctx)		[ctx/mcontext/eip]
#define UCTX_GET_STACK_TOP(ctx)		[ctx/mcontext/esp]
#define UCTX_GET_STACK_FRAME(ctx)	[ctx/mcontext/ebp]

;-------------------------------------------
;-- Retrieve command-line information from stack
;-------------------------------------------
#if type = 'exe [
	system/args-count: 	pop
	system/args-list: 	as str-array! system/stack/top
	system/env-vars: 	system/args-list + system/args-count + 1
]

#include %POSIX.reds

#switch type [
	dll [
		program-vars!: alias struct! [
			mh				[byte-ptr!]
			NXArgcPtr		[int-ptr!]
			NXArgcPtr		[struct! [p [struct! [s [c-string!]]]]]
			environPtr		[struct! [p [struct! [s [c-string!]]]]]
			__prognamePtr	[struct! [s [c-string!]]]
		]

		***-dll-entry-point: func [
			[cdecl]
			argc	[integer!]
			argv	[struct! [s [c-string!]]]
			envp	[struct! [s [c-string!]]]
			apple	[struct! [s [c-string!]]]
			pvars	[program-vars!]
		][
			#either red-pass? = no [					;-- only for pure R/S DLLs
				***-boot-rs
				on-load argc argv envp apple pvars
				***-main
			][
				on-load argc argv envp apple pvars
			]
		]
	]
	exe [
		posix-startup-ctx/init
	]
]
