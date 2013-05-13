REBOL [
	Title:   "Red/System preconfigured compilation target definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %config.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;;-------------------------------------------
;;     Compilation Target Options
;;-------------------------------------------
;;	OS:				'Windows | 'Linux | 'MacOSX | 'Syllable	;-- operating system name
;;	format:			'PE  | 'ELF | 'Mach-o		;-- file format
;;	type:			'exe | 'obj | 'lib | 'dll	;-- file type
;;	target:			'IA-32 | 'ARM				;-- CPU or VM target
;;  cpu-version:	<decimal!>					;-- CPU version (default for IA-32: 6.0, Pentium Pro, for ARM: 5.0)
;;	sub-system:		'GUI | 'console				;-- type of user interface
;;	PIC?:			yes | no					;-- generate Position Independent Code
;;	base-address:	<integer!>					;-- base image memory address
;;	use-natives?:	yes | no					;-- use native functions instead of C bindings (when possible)
;;	dynamic-linker:	none | <string!>			;-- ELF dynamic linker ("interpreter") to use
;;  syscall:		'Linux | 'BSD				;-- syscalls calling convention (default to Linux)
;;  stack-align-16?: yes | no					;-- yes => align stack to 16 bytes (default: no)
;;  literal-pool?:	yes | no					;-- yes => use pools to store literals, no => store them inlined (default: no)
;;	icon-file:		none | <file!>				;-- .ico file for Windows executable (temporary option)
;;-------------------------------------------

;-------------------------
MSDOS [									; Windows default target
	OS:			'Windows
	format: 	'PE
	type:		'exe
	sub-system: 'console
]
;-------------------------
Windows [
	OS:			'Windows
	format: 	'PE
	type:		'exe
	sub-system: 'GUI
	icon-file:  %cws.ico	
]
;-------------------------
;WinDLL [								; not supported yet
;	OS:			'Windows
;	;sub-system: 'GUI					; @@ check if required
;	format: 	'PE
;	type:		'DLL
;]
;-------------------------
Linux [									; Linux default target
	OS:			'Linux
	format: 	'ELF
	type:		'exe
	dynamic-linker: "/lib/ld-linux.so.2"
]
;-------------------------
;LinSO [								; not supported yet
;	OS:			'Linux
;	format: 	'ELF
;	type:		'DLL
;	PIC?:		yes
;	dynamic-linker: "/lib/ld-linux.so.2"
;]
;-------------------------
Android [
	OS:			'Linux
	format:		'ELF
	target:		'ARM
	type:		'exe
	base-address: 32768					; 8000h
	dynamic-linker: "/system/bin/linker"
]
;-------------------------
Linux-ARM [
	OS:			'Linux
	format:		'ELF
	target:		'ARM
	type:		'exe
	base-address: 32768					; 8000h
	dynamic-linker: "/lib/ld-linux.so.3"
]
;-------------------------
Syllable [
	OS:			'Syllable
	format: 	'ELF
	type:		'exe
	base-address: -2147483648			; 80000000h
]
;-------------------------
Darwin [
	OS:			'MacOSX
	format: 	'Mach-O
	type:		'exe
	sub-system: 'console
	syscall:	'BSD
	stack-align-16?: yes
]
;-------------------------
;OSX [									; not supported yet
;	OS:			'MacOSX
;	format: 	'Mach-o
;	type:		'exe
;	sub-system: 'GUI
;]
;-------------------------
