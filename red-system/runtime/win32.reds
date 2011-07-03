Red/System [
	Title:   "Red/System Win32 runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define OS_TYPE		1
#define LIBC-file	"msvcrt.dll"

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

prin: func [s [c-string!] return: [integer!] /local written][
	written: struct [value [integer!]]
	WriteFile stdout s length? s written 0
]

print: func [s [c-string!] return: [integer!]][
	prin s
	prin newline
]
