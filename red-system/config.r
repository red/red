REBOL [
	Title:   "Red/System preconfigured compilation target definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %config.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;;-------------------------------------------
;;     Compilation Target Options
;;-------------------------------------------
;;	OS:				'Windows | 'Linux | 'MacOSX | 'Syllable	;-- operating system name
;;	format:			'PE  | 'ELF | 'Mach-o		;-- file format
;;	type:			'exe | 'obj | 'lib | 'dll	;-- file type
;;	target:			'IA32						;-- CPU or VM target
;;	sub-system:		'GUI | 'console				;-- type of user interface
;;	PIC?:			yes | no					;-- generate Position Independent Code
;;	base-address:	<integer!>					;-- base image memory address
;;	use-natives?:	yes | no					;-- use native functions instead of C bindings (when possible)
;;	dynamic-linker:	none | <string!>			;-- ELF dynamic linker ("interpreter") to use
;;  syscalls:		'Linux | 'BSD				;-- syscalls calling convention (default to Linux)
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
	use-natives?: yes
	syscall:	'BSD
]
;-------------------------
;OSX [									; not supported yet
;	OS:			'MacOSX
;	format: 	'Mach-o
;	type:		'exe
;	sub-system: 'GUI
;]
;-------------------------
