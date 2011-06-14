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
;;  OS:			  'Windows | 'Linux | 'MacOSX | 'Syllable	;-- operating system name
;;	format: 	  'PE  | 'ELF | 'Mach-o			;-- file format
;;	type: 		  'exe | 'obj | 'lib | 'dll		;-- file type
;;	target:		  'IA-32						;-- CPU or VM target
;;	sub-system:	  'GUI | 'console				;-- type of user interface
;;	PIC?:		   yes | no						;-- generate Position Independent Code
;;  base-address: <integer!>					;-- base image memory address
;;  C-binding?:	   yes | no						;-- use C bindings instead of native functions
;;-------------------------------------------

;-------------------------
MSDOS [									; Windows default target
	OS:			'Windows
	format: 	'PE
	type:		'exe
	sub-system: 'console
]
;-------------------------
WinGUI [
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
]
;-------------------------
;LinSO [								; not supported yet
;	OS:			'Linux
;	format: 	'ELF
;	type:		'DLL
;	PIC?:		yes
;]
;-------------------------
Syllable [
	OS:			'Syllable
	format: 	'ELF
	type:		'exe
	base-address: -2147483648			; 80000000h
]
;-------------------------
;Darwin [								; not supported yet
;	OS:			'MacOSX
;	format: 	'Mach-o
;	type:		'exe
;	sub-system: 'console
;]
;-------------------------
;OSX [									; not supported yet
;	OS:			'MacOSX
;	format: 	'Mach-o
;	type:		'exe
;	sub-system: 'GUI
;]
;-------------------------