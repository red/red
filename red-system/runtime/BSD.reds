Red/System [
	Title:   "Red/System BSD common runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %BSD.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#define SA_SIGINFO   0040h
#define SA_RESTART   0002h

sigaction!: alias struct! [
;	handler		[integer!]					;-- Warning: compiled as C union on most UNIX
	sigaction	[integer!]					;-- Warning: compiled as union on most UNIX
	mask		[integer!]					;@@ it's an array, not sure this definition is correct
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
	;... remaining fields not used
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

	print: func [s [c-string!] return: [integer!]][
		prin s
		write stdout newline 1
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

***-on-signal: func [
	[callback]
	signal	[integer!]
	info	[siginfo!]
	ctx		[byte-ptr!]
	/local code error
][
	error: 99								;-- default unknown error
	code: info/code
	
	if signal = SIGILL [
		if code = 1 [error: 17]				;-- illegal opcode
		if code = 2 [error: 25]				;-- illegal trap
		if code = 3 [error: 15]				;-- privileged opcode
		if code = 4 [error: 23]				;-- illegal operand
		if code = 5 [error: 24]				;-- illegal addressing mode
		if code = 6 [error: 31]				;-- privileged register
		if code = 7 [error: 26]				;-- coprocessor error
		if code = 8 [error: 19]				;-- internal stack error
	]
	if signal = SIGBUS [
		if code = 1 [error:  2]				;-- invalid address alignment
		if code = 2 [error:  1]				;-- non-existant physical address
		if code = 3 [error: 28]				;-- object specific hardware error
		if code = 4 [error: 29]				;-- hardware memory error consumed (action required)
		if code = 5 [error: 30]				;-- hardware memory error consumed (action optional)
	]
	if signal = SIGFPE [
		if code = 1 [error:  7]				;-- floating point divide by zero
		if code = 2 [error: 10]				;-- floating point overflow
		if code = 3 [error: 12]				;-- floating point underflow
		if code = 4 [error:  8]				;-- floating point inexact result
		if code = 5 [error:  9]				;-- floating point invalid operation
		if code = 6 [error:  5]				;-- subscript out of range
		if code = 7 [error: 13]				;-- integer divide by zero
		if code = 8 [error: 14]				;-- integer overflow
	]
	if signal = SIGSEGV [
		if code = 1 [error:  1]				;-- address not mapped to object
		if code = 2 [error: 16]				;-- invalid permissions for mapped object
	]

	***-on-quit error info/address
]

__sigaction-options: declare sigaction!

__sigaction-options/sigaction: 	as-integer :***-on-signal
__sigaction-options/mask: 		0
__sigaction-options/flags: 		SA_SIGINFO ;or SA_RESTART

sigaction SIGILL  __sigaction-options as sigaction! 0
sigaction SIGBUS  __sigaction-options as sigaction! 0
sigaction SIGFPE  __sigaction-options as sigaction! 0
sigaction SIGSEGV __sigaction-options as sigaction! 0
