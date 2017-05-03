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

#define CP_UTF8					 65001

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
			GetCommandLine: "GetCommandLineW" [
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
			LocalFree: "LocalFree" [
				hMem		[int-ptr!]
				return:		[int-ptr!]
			]
			WideCharToMultiByte: "WideCharToMultiByte" [
				CodePage			[integer!]
				dwFlags				[integer!]
				lpWideCharStr		[c-string!]
				cchWideChar			[integer!]
				lpMultiByteStr		[byte-ptr!]
				cbMultiByte			[integer!]
				lpDefaultChar		[c-string!]
				lpUsedDefaultChar	[integer!]
				return:				[integer!]
			]
		]
		"shell32.dll" stdcall [
			CommandLineToArgvW: "CommandLineToArgvW" [
				lpCmdLine	[byte-ptr!]
				pNumArgs	[int-ptr!]
				return:		[int-ptr!]
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
	;-- Retrieve command-line information
	;-------------------------------------------
	on-start: func [/local c n argv args len src dst][
		c: 0
		args: CommandLineToArgvW as byte-ptr! GetCommandLine :c
		
		argv: as int-ptr! allocate c + 1 * size? int-ptr!
		src: args
		dst: argv

		either null? src [
			probe "CommandLineToArgvW failed!"
		][
			n: c
			while [n > 0][
				len: WideCharToMultiByte CP_UTF8 0 as-c-string src/value -1 null 0 null 0
				dst/value: as-integer allocate len
				WideCharToMultiByte CP_UTF8 0 as-c-string src/value -1 as byte-ptr! dst/value len null 0

				dst: dst + 1
				src: src + 1
				n: n - 1
			]
			LocalFree args
		]
		dst/value: 0
		
		system/args-list: as str-array! argv
		system/args-count: c
		system/env-vars: null
		memory-blocks/argv: argv
	]
	
	on-quit: func [/local arg][
		if memory-blocks/argv <> null [
			arg: memory-blocks/argv
			while [arg/value <> 0][
				free as byte-ptr! arg/value
				arg: arg + 1
			]
			free as byte-ptr! memory-blocks/argv
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
				#either red-pass? = no [			;-- only for pure R/S DLLs
					***-boot-rs
					on-load hinstDLL
					***-main
				][
					on-load hinstDLL
				]
			]
			DLL_THREAD_ATTACH  [on-new-thread  hinstDLL]
			DLL_THREAD_DETACH  [on-exit-thread hinstDLL]
			DLL_PROCESS_DETACH [on-unload 	   hinstDLL]
		]
		true										 ;-- true: load DLL, false: abort loading
	]
]