Red/System [
	Title:   "Red/System Win32 runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define OS_TYPE		1

#define WIN_STD_INPUT_HANDLE	-10
#define WIN_STD_OUTPUT_HANDLE	-11
#define WIN_STD_ERROR_HANDLE	-12

#define DLL_PROCESS_ATTACH 		 1
#define DLL_THREAD_ATTACH  		 2
#define DLL_THREAD_DETACH  		 3
#define DLL_PROCESS_DETACH 		 0

#define OS_DIR_SEP				 92		;-- #"\"

#if use-natives? = yes [
	#import [
		"kernel32.dll" stdcall [
			quit: "ExitProcess" [
				code		[integer!]
			]
		]
	]
	
	prin: func [s [c-string!] return: [c-string!] /local written][
		written: declare struct! [value [integer!]]
		WriteFile stdout s length? s written 0
		s
	]
]

win32-startup-ctx: context [

	;-- Catching runtime errors --
	;; source: http://msdn.microsoft.com/en-us/library/aa363082(v=VS.85).aspx
	
	SEH_EXCEPTION_POINTERS: alias struct! [
		error [
			struct! [
				code		[integer!]
				flags		[integer!]
				records		[integer!]
				address		[integer!]
				nb-params	[integer!]
				info		[integer!]
			]
		]
		context [
			struct! [
				flags 		[integer!]
				Dr0			[integer!]
				Dr1			[integer!]
				Dr2			[integer!]
				Dr3			[integer!]
				Dr6			[integer!]
				Dr7			[integer!]
			]
		]
		; remaining fields skipped
	]
	
	#import [
		"kernel32.dll" stdcall [
			GetCommandLine: "GetCommandLineA" [
				return:		[c-string!]
			]
			SetErrorMode: "SetErrorMode" [
				mode		[integer!]
				return:		[integer!]
			]
			SetUnhandledExceptionFilter: "SetUnhandledExceptionFilter" [
				handler 	[function! [record [SEH_EXCEPTION_POINTERS] return: [integer!]]]
			]
			GetStdHandle: "GetStdHandle" [
				type		[integer!]
				return:		[integer!]
			]
			WriteFile: "WriteFile" [
				handle		[integer!]
				buffer		[c-string!]
				len			[integer!]
				written		[int-ptr!]
				overlapped	[integer!]
				return:		[integer!]
			]
		]
	]

	exception-filter: func [
		[stdcall]
		record  [SEH_EXCEPTION_POINTERS]
		return: [integer!]
		/local code error base p
	][
		base: (as int-ptr! record/context) 			;-- point to flags
		p: base
		
		if 0001007Fh = p/value [					;-- check if CONTEXT layout is full
			system/debug: declare __stack!			;-- allocate a __stack! struct
			p: base + 45							;-- extract ebp
			system/debug/frame: as int-ptr! p/value
			p: base + 49							;-- extract esp
			system/debug/top: as int-ptr! p/value
		]
		
		error: 99									;-- default unknown error
		code: record/error/code
		error: switch code [
			C0000005h [1]							;-- access violation 
			80000002h [2]							;-- datatype misalignment
			80000003h [3]							;-- breakpoint
			80000004h [4]							;-- single step
			C000008Ch [5]							;-- array bounds exceeded
			C000008Dh [6]							;-- float denormal operand	
			C000008Eh [7]							;-- float divide by zero
			C000008Fh [8]							;-- float inexact result
			C0000090h [9]							;-- float invalid operation
			C0000091h [10]							;-- float overflow
			C0000092h [11]							;-- float stack check
			C0000093h [12]							;-- float underflow
			C0000094h [13]							;-- integer divide by zero
			C0000095h [14]							;-- integer overflow
			C0000096h [15]							;-- privileged instruction
			C0000006h [16]							;-- in page error
			C000001Dh [17]							;-- illegal instruction
			C0000025h [18]							;-- non-continuable exception
			C00000FDh [19]							;-- stack overflow
			C0000026h [20]							;-- invalid disposition
			80000001h [21]							;-- guard page
			C0000008h [22]							;-- invalid handle
			C000013Ah [0]							;-- CTRL-C exit
			default	  [99]
		]

		***-on-quit error record/error/address
		1											;-- EXCEPTION_EXECUTE_HANDLER, forces termination
	]

	;-- Runtime functions --
	
	x87-cword: 0									;-- store previous control word in case it needs
													;-- to be restored (on callbacks exit e.g.)
	memory-blocks: declare struct! [
		argv	[pointer! [integer!]]
	]
	
	;-------------------------------------------
	;-- Initialize environment
	;-------------------------------------------
	init: does [
		SetUnhandledExceptionFilter :exception-filter
		SetErrorMode 1								;-- probably superseded by SetUnhandled...
		
		;-- Runtime globals --
		stdin:  GetStdHandle WIN_STD_INPUT_HANDLE
		stdout: GetStdHandle WIN_STD_OUTPUT_HANDLE
		stderr: GetStdHandle WIN_STD_ERROR_HANDLE

		#if type = 'exe [
			#if use-natives? = no [on-start]		;-- allocate is not yet implemented as native function
		]
	]

	;-------------------------------------------
	;-- Retrieve command-line information from stack
	;-------------------------------------------
	on-start: func [/local c argv s][
		c: 1											;-- account for executable name
		argv: as pointer! [integer!] allocate 256 * 4	;-- max argc = 256

		s: GetCommandLine
		argv/1: as-integer s

		;-- Build argv array in a newly allocated buffer, but reuse GetCommandLine buffer
		;-- to store tokenized strings by replacing each new first space byte by a null byte
		;-- to avoid allocating a new buffer for each new token. Might create side-effects
		;-- if GetCommandLine buffer is shared, but side-effects should be rare and minor issues.

		while [s/1 <> null-byte][					;-- iterate other all command line bytes
			if s/1 = #" " [							;-- space detected
				s/1: null-byte						;-- mark previous token's end
				until [s: s + 1 s/1 <> #" "]		;-- consume extra spaces
				either s/1 = null-byte [			;-- end of string?
					s: s - 1						;-- adjust s so that main loop test exits
				][
					c: c + 1						;-- one more token
					argv/c: as-integer s			;-- save new token start address in argv array
				]
			]
			if s/1 = #"^"" [
				until [s: s + 1 s/1 = #"^""]		;-- skip "..."
			]
			s: s + 1
		]
		system/args-count: c
		c: c + 1									;-- add a null entry at argv's end to match UNIX layout
		argv/c: 0									;-- end of argv array marker

		system/args-list: as str-array! argv
		system/env-vars: null

		memory-blocks/argv: argv
	]
	
	on-quit: does [
		if memory-blocks/argv <> null [
			free as byte-ptr! memory-blocks/argv	;-- free call is safe here (defined in all cases)
		]
	]
	
	#if type = 'exe [init]							;-- call init codes for executables only
]

#if type = 'dll [
	;-- source: http://msdn.microsoft.com/en-us/library/windows/desktop/ms682596(v=vs.85).aspx
	
	***-dll-entry-point: func [
		[callback]
		hinstDLL   [integer!]						;-- handle to DLL module
		fdwReason  [integer!]						;-- reason for calling function
		lpReserved [integer!]						;-- reserved
		return:    [logic!]
	][
		switch fdwReason [
			DLL_PROCESS_ATTACH [
				***-main
				win32-startup-ctx/init				;-- init Windows-specific handlers
				on-load hinstDLL
			]
			DLL_THREAD_ATTACH  [on-new-thread  hinstDLL]
			DLL_THREAD_DETACH  [on-exit-thread hinstDLL]
			DLL_PROCESS_DETACH [on-unload 	   hinstDLL]
		]
		true										 ;-- true: load DLL, false: abort loading
	]
]