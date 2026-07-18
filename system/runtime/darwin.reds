Red/System [
	Title:   "Red/System MacOS X runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %darwin.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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
	mprotect: 74 [							;-- protect protected-data page(s) in dylibs
		address	[byte-ptr!]
		size	[integer!]
		prot	[integer!]
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

#either ABI = 'apple-aarch64 [
	sigaction!: alias struct! [
		sigaction	[byte-ptr!]				;-- union __sigaction_u
		mask		[integer!]					;-- sigset_t
		flags		[integer!]
	]
][
	sigaction!: alias struct! [
		sigaction	[integer!]					;-- Warning: compiled as union on most UNIX
		mask		[integer!]					;-- bit array
		flags		[integer!]
	]
]

siginfo!: alias struct! [
	signal		[integer!]
	error		[integer!]
	code		[integer!]
	pid			[integer!]
	uid			[integer!]
	status		[integer!]
	address		[#either ABI = 'apple-aarch64 [byte-ptr!][integer!]] ;-- signal-dependent union
	;... remaining fields skipped
]

;; sources:
;;  http://fxr.watson.org/fxr/source/bsd/sys/_structs.h?v=xnu-1456.1.26#L124,126
;;  http://fxr.watson.org/fxr/source/bsd/i386/_structs.h?v=xnu-1456.1.26#L92,95

#define UCTX_DEFINITION [
	#either ABI = 'apple-aarch64 [
		_arm-thread-state64!: alias struct! [
			x0 [int-ptr!] x1 [int-ptr!] x2 [int-ptr!] x3 [int-ptr!]
			x4 [int-ptr!] x5 [int-ptr!] x6 [int-ptr!] x7 [int-ptr!]
			x8 [int-ptr!] x9 [int-ptr!] x10 [int-ptr!] x11 [int-ptr!]
			x12 [int-ptr!] x13 [int-ptr!] x14 [int-ptr!] x15 [int-ptr!]
			x16 [int-ptr!] x17 [int-ptr!] x18 [int-ptr!] x19 [int-ptr!]
			x20 [int-ptr!] x21 [int-ptr!] x22 [int-ptr!] x23 [int-ptr!]
			x24 [int-ptr!] x25 [int-ptr!] x26 [int-ptr!] x27 [int-ptr!]
			x28 [int-ptr!]
			fp [int-ptr!]
			lr [int-ptr!]
			sp [int-ptr!]
			pc [int-ptr!]
			cpsr [integer!]
			pad [integer!]
		]

		_mcontext!: alias struct! [
			fault-address [int-ptr!]			;-- arm_exception_state64
			esr			[integer!]
			exception	[integer!]
			state		[_arm-thread-state64! value]
			;... arm_neon_state64 skipped
		]

		_ucontext!: alias struct! [
			onstack		[integer!]
			sigmask		[integer!]
			ss_sp		[byte-ptr!]			;-- stack_t struct inlined
			ss_size		[int-ptr!]
			ss_flags	[integer!]
			ss_pad		[integer!]
			link		[_ucontext!]
			mcsize		[int-ptr!]
			mcontext	[_mcontext!]
		]
	][
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
]

#define UCTX_INSTRUCTION(ctx) [
	#either ABI = 'apple-aarch64 [ctx/mcontext/state/pc][ctx/mcontext/eip]
]
#define UCTX_GET_STACK_TOP(ctx) [
	#either ABI = 'apple-aarch64 [ctx/mcontext/state/sp][ctx/mcontext/esp]
]
#define UCTX_GET_STACK_FRAME(ctx) [
	#either ABI = 'apple-aarch64 [ctx/mcontext/state/fp][ctx/mcontext/ebp]
]

;-------------------------------------------
;-- Retrieve command-line information from stack
;-------------------------------------------
#if type = 'exe [
	#either ABI = 'apple-aarch64 [
		system/args-count: 	as integer! system/cpu/x19
		system/args-list: 	as str-array! system/cpu/x20
	][
		system/args-count: 	pop
		system/args-list: 	as str-array! system/stack/top
	]
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
			system/image: ***-exec-image
			#either ABI = 'apple-aarch64 [
				system/image/base: (as byte-ptr! ***-exec-image) - (as integer! system/image/base)
			][
				system/image/base: as byte-ptr! system/cpu/ebx - system/image/code
			]

			***-init-system-image

			if system/image/rodata-size > 0 [		;-- lock protected data read-only after dyld relocations
				mprotect
					system/image/base + system/image/rodata
					system/image/rodata-size
					1							;-- PROT_READ
			]

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
		#if all [ABI = 'apple-aarch64 PIC? = yes][
			system/image/base: (as byte-ptr! ***-exec-image) - (as integer! system/image/base)
		]
		posix-startup-ctx/init
	]
]
