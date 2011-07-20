Red/System [
	Title:   "Red/System Win32 runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#define OS_TYPE		1

#define WIN_STD_INPUT_HANDLE	-10
#define WIN_STD_OUTPUT_HANDLE	-11
#define WIN_STD_ERROR_HANDLE	-12

SEH_EXCEPTION_RECORD: alias struct! [
	error [
		struct! [
			code		[integer!]
			flags		[integer!]
			records		[integer!]
			address		[integer!]
			; remaining fields skipped
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
			handler 	[function! [record [SEH_EXCEPTION_RECORD] return: [integer!]]]
		]
		GetStdHandle: "GetStdHandle" [
			type		[integer!]
			return:		[integer!]
		]
		WriteFile: "WriteFile" [
			handle		[integer!]
			buffer		[c-string!]
			len			[integer!]
			written		[struct! [value [integer!]]]
			overlapped	[integer!]
			return:		[integer!]
		]
	]
]

#if use-natives? = yes [
	#import [
		"kernel32.dll" stdcall [
			quit: "ExitProcess" [
				code		[integer!]
			]
		]
	]
]

;-- Catching runtime errors --

;; source: http://msdn.microsoft.com/en-us/library/aa363082(v=VS.85).aspx

exception-filter: func [
	[callback]
	record  [SEH_EXCEPTION_RECORD]
	return: [integer!]
	/local code error
][
	error: 99									;-- default unknown error
	code: record/error/code
	if code = C0000005h [error:  1]				;-- access violation 
	if code = 80000002h [error:  2]				;-- datatype misalignment
	if code = 80000003h [error:  3]				;-- breakpoint
	if code = 80000004h [error:  4]				;-- single step
	if code = C000008Ch [error:  5]				;-- array bounds exceeded
	if code = C000008Dh [error:  6]				;-- float denormal operand	
	if code = C000008Eh [error:  7]				;-- float divide by zero
	if code = C000008Fh [error:  8]				;-- float inexact result
	if code = C0000090h [error:  9]				;-- float invalid operation
	if code = C0000091h [error: 10]				;-- float overflow
	if code = C0000092h [error: 11]				;-- float stack check
	if code = C0000093h [error: 12]				;-- float underflow
	if code = C0000094h [error: 13]				;-- integer divide by zero
	if code = C0000095h [error: 14]				;-- integer overflow
	if code = C0000096h [error: 15]				;-- privileged instruction
	if code = C0000006h [error: 16]				;-- in page error
	if code = C000001Dh [error: 17]				;-- illegal instruction
	if code = C0000025h [error: 18]				;-- non-continuable exception
	if code = C00000FDh [error: 19]				;-- stack overflow
	if code = C0000026h [error: 20]				;-- invalid disposition
	if code = 80000001h [error: 21]				;-- guard page
	if code = C0000008h [error: 22]				;-- invalid handle
	if code = C000013Ah [error:  0]				;-- CTRL-C exit

	***-on-quit error record/error/address
	1
]

SetUnhandledExceptionFilter :exception-filter
SetErrorMode 1									;-- probably superseded by SetUnhandled...


;-- Runtime globals --

stdin:  GetStdHandle WIN_STD_INPUT_HANDLE
stdout: GetStdHandle WIN_STD_OUTPUT_HANDLE
stderr: GetStdHandle WIN_STD_ERROR_HANDLE


;-- Runtime functions --

__win32-memory-blocks: declare struct! [
	argv	[pointer! [integer!]]
]

#if use-natives? = yes [
	prin: func [s [c-string!] return: [c-string!] /local written][
		written: declare struct! [value [integer!]]
		WriteFile stdout s length? s written 0
		s
	]

	print: func [s [c-string!] return: [c-string!]][
		prin s
		prin newline
		s
	]
]

***-on-start: func [/local c argv s args][
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
	
	__win32-memory-blocks/argv: argv
]

***-on-win32-quit: does [
	free as byte-ptr! __win32-memory-blocks/argv
]