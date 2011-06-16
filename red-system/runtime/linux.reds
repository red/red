Red/System [
	Title:   "Red/System Linux runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %linux.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define OS_TYPE		2
#define LIBC-file	"libc.so.6"

#syscall [
	write: 4 [
		fd		[integer!]
		buffer	[c-string!]
		count	[integer!]
		return: [integer!]
	]
	quit: 1 [								;-- "exit" syscall
		status	[integer!]
	]
]

sigaction!: alias struct! [
;	handler		[integer!]					;-- Warning: compiled as C union on most UNIX
	sigaction	[integer!]					;-- Warning: compiled as union on most UNIX
	mask		[integer!]					;-- it is a bit-array, but integer! should be safe enough
	flags		[integer!]
	restorer	[integer!]					;-- unused
]

siginfo!: alias struct! [
	signal		[integer!]
	error		[integer!]
	code		[integer!]
	address		[integer!]					;-- this field is a C union, dependent on signal
]


#import [									;-- mandatory C bindings
	LIBC-file cdecl [
		sigaction: "sigaction" [
			signum	[integer!]
			action	[sigaction!]
			oldact	[sigaction!]
		]
	]
]

stdin:  0
stdout: 1
stderr: 2

prin: func [s [c-string!] return: [integer!]][
	write stdout s length? s
]

print: func [s [c-string!] return: [integer!]][
	prin s
	write stdout newline 1
]

;-- Catching runtime errors --

;; sources:
;;		http://www.kernel.org/doc/man-pages/online/pages/man2/sigaction.2.html
;; 		http://fxr.watson.org/fxr/source/include/asm-generic/siginfo.h?v=linux-2.6;im=excerpts#L161

#define	SIGILL		 4						;-- Illegal instruction
#define SIGBUS		 7						;-- Bus access error
#define	SIGFPE		 8						;-- Floating point error
#define	SIGSEGV		11						;-- Segmentation violation

#define SA_SIGINFO   00000004h				;-- Linux-specific value
#define SA_RESTART   10000000h				;-- Linux-specific value


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
		if code = 2 [error: 23]				;-- illegal operand
		if code = 3 [error: 24]				;-- illegal addressing mode
		if code = 4 [error: 25]				;-- illegal trap
		if code = 5 [error: 15]				;-- privileged opcode
		if code = 6 [error: 26]				;-- coprocessor error
		if code = 7 [error: 19]				;-- internal stack error
	]
	if signal = SIGBUS [
		if code = 1 [error:  2]				;-- invalid address alignment
		if code = 2 [error: 27]				;-- non-existant physical address
		if code = 3 [error: 28]				;-- object specific hardware error
		if code = 4 [error: 29]				;-- hardware memory error consumed (action required)
		if code = 5 [error: 30]				;-- hardware memory error consumed (action optional)
	]
	if signal = SIGFPE [
		if code = 1 [error: 13]				;-- integer divide by zero
		if code = 2 [error: 14]				;-- integer overflow
		if code = 3 [error:  7]				;-- floating point divide by zero
		if code = 4 [error: 10]				;-- floating point overflow
		if code = 5 [error: 12]				;-- floating point underflow
		if code = 6 [error:  8]				;-- floating point inexact result
		if code = 7 [error:  9]				;-- floating point invalid operation
		if code = 8 [error:  5]				;-- subscript out of range
	]
	if signal = SIGSEGV [
		if code = 1 [error:  1]				;-- address not mapped to object
		if code = 2 [error: 16]				;-- invalid permissions for mapped object
	]

	***-on-quit error info/address
]

__sigaction-options: struct sigaction!

__sigaction-options/sigaction: 	as-integer :***-on-signal
__sigaction-options/mask: 		0
__sigaction-options/flags: 		SA_SIGINFO ;or SA_RESTART
__sigaction-options/restorer:	0

sigaction SIGILL  __sigaction-options as sigaction! 0
sigaction SIGBUS  __sigaction-options as sigaction! 0
sigaction SIGFPE  __sigaction-options as sigaction! 0
sigaction SIGSEGV __sigaction-options as sigaction! 0
