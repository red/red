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
;;	format: 	  'PE  | 'ELF | 'Mach-o			;-- file format
;;	type: 		  'exe | 'obj | 'lib | 'dll		;-- file type
;;	target:		  'IA-32						;-- CPU or VM target
;;	sub-system:	  'GUI | 'console				;-- type of user interface
;;	runtime?:	   yes | no						;-- yes => include Red/System runtime
;;	PIC?:		   yes | no						;-- compile using Position Independent Code
;;  base-address: <integer!>					;-- base image memory address
;;-------------------------------------------

;-------------------------
MSDOS [									; Windows default target
	format: 	'PE
	type:		'exe
	sub-system: 'console
]
;-------------------------
WinGUI [
	format: 	'PE
	type:		'exe
	sub-system: 'GUI
]
;-------------------------
;WinDLL [								; not supported yet
;	;sub-system: 'GUI					; @@ check if required
;	format: 	'PE
;	type:		'DLL
;]
;-------------------------
Linux [									; Linux default target
	format: 	'ELF
	type:		'exe
]
;-------------------------
;LinSO [								; not supported yet
;	format: 	'ELF
;	type:		'DLL
;	PIC?:		yes
;]
;-------------------------
Syllable [
	format: 	'ELF
	type:		'exe
	base-address: -2147483648			; 80000000h
]
;-------------------------
;Darwin [								; not supported yet
;	format: 	'Mach-o
;	type:		'exe
;	sub-system: 'console
;]
;-------------------------
;OSX [									; not supported yet
;	format: 	'Mach-o
;	type:		'exe
;	sub-system: 'GUI
;]
;-------------------------