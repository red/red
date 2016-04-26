Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %start.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %lib-names.reds

__stack!: alias struct! [
	top		[pointer! [integer!]]
	frame	[pointer! [integer!]]
]

__cpu!: alias struct! [
	edx     [integer!]
]

system: declare struct! [							;-- trimmed down temporary system definition
	stack		[__stack!]							;-- stack virtual access
	cpu         [__cpu!]                            ;-- cpu virtual access
]


#switch OS [
	Windows []										;-- nothing to do, initialization occurs in DLL init entry point
	MacOSX  []										;-- nothing to do @@
	FreeBSD [
		#import [ LIBC-file cdecl [
			***__atexit: "atexit" [fun [pointer! [byte!]]]
			***__exit: "exit" [code [integer!]]]
		]

		;; The dynamic linker passes a routine for calling destructors in linked libraries
		;; in the edx cpu register. We use the pointer! [byte!] type since function pointer
		;; variables can't be passed to a function.
		***__rtld_cleanup: as pointer! [byte!] system/cpu/edx

		;; Clear the frame pointer. The SVR4 ELF/i386 ABI suggests this, to
		;; mark the outermost frame.
		system/stack/frame: as pointer! [integer!] 0

		;; Extract arguments from the call stack (which was setup by the kernel).
		***__argc: pop
		***__argv: system/stack/top

		;; Align the stack to a 128-bit boundary, to prevent misaligned access penalities.
		system/stack/top: as pointer! [integer!] (FFFFFFF0h and as integer! ***__argv)

		;; Register the clean up routine.
		***__atexit ***__rtld_cleanup

		;; We need to take care of exiting the program ourselves, there's nowhere to
		;; return to.
		***__redprog: as function! [] :***_start
		***__redprog
		***__exit 0

		;; The FreeBSD libc expects these symbols to be present. They're usually provided by %crt1.o.
		environ: as struct! [item [c-string!]] 0
		__progname: as c-string! 0
		#export [environ __progname]
	]

	Syllable [
		#import [LIBC-file cdecl [
			libc-start: "__libc_start_main" [
				main 			[function! []]
				argv 			[pointer! [integer!]]
				envp 			[pointer! [integer!]]
				init 			[function! []]
				finish 			[function! []]
				stack-end 		[pointer! [integer!]]
			]
		]]

		;; Clear the frame pointer. The SVR4 ELF/i386 ABI suggests this, to
		;; mark the outermost frame.
		system/stack/frame: as pointer! [integer!] 0

		;; Extract arguments from the call stack (which was setup by the
		;; kernel).
		;; esp:   dummy value
		;; esp+4: **argv
		***__argv: system/stack/top + 1
		***__argv: as [pointer! [integer!]] ***__argv/value
		;; esp+8: **envp
		***__envp: system/stack/top + 2
		***__envp: as [pointer! [integer!]] ***__envp/value

		;; Before pushing arguments for `libc-start`, align the stack to a
		;; 128-bit boundary, to prevent misaligned access penalities.
		system/stack/top: as pointer! [integer!] (FFFFFFF0h and as integer! ***__argv)

		;; The call to `libc-start` takes 6 4-byte arguments (passed on the
		;; stack). To keep the stack 128-bit aligned even after the call, we
		;; push some garbage.
		push 0
		push 0

		;; Finally, call into libc's startup routine.
		***__stack_end: system/stack/top
		libc-start :***_start ***__argv ***__envp null null ***__stack_end		
	]
	
	Android [
		#import [LIBC-file cdecl [
			libc-init: "__libc_init" [
				args 			[pointer! [integer!]]
				onexit 			[function! []]
				main 			[function! []]
				structors		[pointer! [integer!]]
			]
		]]
		
		;; Clear the frame pointer. The SVR4 ELF/i386 ABI suggests this, to
		;; mark the outermost frame.
		system/stack/frame: as pointer! [integer!] 0

		;; Extract arguments from the call stack (which was setup by the
		;; kernel).
		***__argc: pop
		***__argv: system/stack/top
		
		system/stack/top: system/stack/top - 4			;-- simulate a structors struct on stack
		push 0											;-- fini
		push 0											;-- init
		push 0											;-- preinit

		;; Before pushing arguments for `libc-start`, align the stack to a
		;; 128-bit boundary, to prevent misaligned access penalities.
		;system/stack/top: as pointer! [integer!] (FFFFFFF0h and as integer! ***__argv)
		
		;; Finally, call into Bionic's startup routine.
		libc-init ***__argv - 1 null :***_start ***__argv - 16
	]
	
	#default [										;-- for SVR4 fully conforming UNIX platforms
		#import [LIBC-file cdecl [
			libc-start: "__libc_start_main" [
				main 			[function! []]
				argc 			[integer!]
				argv 			[pointer! [integer!]]
				init 			[function! []]
				finish 			[function! []]
				loader-finish 	[function! []]
				stack-end 		[pointer! [integer!]]
			]
		]]

		;; Clear the frame pointer. The SVR4 ELF/i386 ABI suggests this, to
		;; mark the outermost frame.
		system/stack/frame: as pointer! [integer!] 0

		;; Extract arguments from the call stack (which was setup by the
		;; kernel).
		***__argc: pop
		***__argv: system/stack/top

		;; Before pushing arguments for `libc-start`, align the stack to a
		;; 128-bit boundary, to prevent misaligned access penalities.
		system/stack/top: as pointer! [integer!] (FFFFFFF0h and as integer! ***__argv)

		;; The call to `libc-start` takes 7 4-byte arguments (passed on the
		;; stack). To keep the stack 128-bit aligned even after the call, we
		;; push some garbage.
		push 0

		;; Finally, call into libc's startup routine.
		***__stack_end: system/stack/top
		libc-start :***_start ***__argc ***__argv null null null ***__stack_end
	]
]
