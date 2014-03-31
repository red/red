Red/System [
	Title:   "Red/System BSD common runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %BSD.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define SA_SIGINFO  		0040h
#define SA_RESTART   		0002h

sigaction!: alias struct! [
;	handler		[integer!]					;-- Warning: compiled as C union on most UNIX
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
;;	http://fxr.watson.org/fxr/source/sys/signal.h?v=FREEBSD82
;;  http://fxr.watson.org/fxr/source/sys/signal.h?v=NETBSD5
;;	http://fxr.watson.org/fxr/source/sys/signal.h?v=OPENBSD
;;  http://fxr.watson.org/fxr/source/bsd/sys/signal.h?v=xnu-1456.1.26;im=excerpts

#define	SIGILL		 4						;-- Illegal instruction
#define SIGBUS		10						;-- Bus access error
#define	SIGFPE		 8						;-- Floating point error
#define	SIGSEGV		11						;-- Segmentation violation

bsd-startup-ctx: context [
	#switch OS [								;@@ also CPU-dependent
		MacOSX [
			_mcontext!: alias struct! [
				trapno		[integer!]			;-- _STRUCT_X86_EXCEPTION_STATE32 inlined
				err			[integer!]
				faultvaddr	[integer!]
				eax			[integer!]			;-- _STRUCT_X86_THREAD_STATE32 inlined
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
		#default [								;-- FreeBSD definition
			_mcontext!: alias struct! [
				onstack		[integer!]
				gs			[integer!]
				fs			[integer!]
				es			[integer!]
				ds			[integer!]
				edi			[integer!]
				esi			[integer!]
				ebp			[integer!]
				isp			[integer!]
				ebx			[integer!]
				edx			[integer!]
				ecx			[integer!]
				eax			[integer!]
				trapno		[integer!]
				err			[integer!]
				eip			[integer!]
				cs			[integer!]
				eflags		[integer!]
				esp			[integer!]
				ss			[integer!]
				mc_len		[integer!]
				fpformat	[integer!]
				ownedfp		[integer!]
				;... remaining fields skipped
			]
			_ucontext!: alias struct! [
				sigmask0	[integer!]			;-- __sigset defined as an array of 4 uint32
				sigmask1	[integer!]
				sigmask2	[integer!]
				sigmask3	[integer!]
				mcontext	[_mcontext!]
				link		[_ucontext!]
				ss_sp		[byte-ptr!]			;-- stack_t struct inlined
				ss_size		[integer!]
				ss_flags	[integer!]
				flags		[integer!]
				;... remaining fields skipped
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
					2 [25]						;-- illegal trap
					3 [15]						;-- privileged opcode
					4 [23]						;-- illegal operand
					5 [24]						;-- illegal addressing mode
					6 [31]						;-- privileged register
					7 [26]						;-- coprocessor error
					8 [19]						;-- internal stack error
					default [99]
				]
			]
			SIGBUS [
				switch code [
					1 [2]						;-- invalid address alignment
					2 [1]						;-- non-existant physical address
					3 [28]						;-- object specific hardware error
					4 [29]						;-- hardware memory error consumed (action required)
					5 [30]						;-- hardware memory error consumed (action optional)
					default [34]
				]
			]
			SIGFPE [
				switch code [
					1 [7]						;-- floating point divide by zero
					2 [10]						;-- floating point overflow
					3 [12]						;-- floating point underflow
					4 [8]						;-- floating point inexact result
					5 [9]						;-- floating point invalid operation
					6 [5]						;-- subscript out of range
					7 [13]						;-- integer divide by zero
					8 [14]						;-- integer overflow
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

		***-on-quit error ctx/mcontext/eip
	]

	init: does [
		__sigaction-options: declare sigaction!

		__sigaction-options/sigaction: 	as-integer :***-on-signal
		__sigaction-options/mask: 		0
		__sigaction-options/flags: 		SA_SIGINFO ;or SA_RESTART

		sigaction SIGILL  __sigaction-options as sigaction! 0
		sigaction SIGBUS  __sigaction-options as sigaction! 0
		sigaction SIGFPE  __sigaction-options as sigaction! 0
		sigaction SIGSEGV __sigaction-options as sigaction! 0
	]
]

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
			***-main
			bsd-startup-ctx/init
			on-load argc argv envp apple pvars
		]
	]
	exe [
		bsd-startup-ctx/init
	]
]