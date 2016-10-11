Red/System [
	Title:   "Red/System shared library sample script"
	Author:  "Nenad Rakocevic"
	File: 	 %shared-lib.reds
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Note: {
		Compile this script from red-system folder with:
		
		do/args %rsc.r "-dlib %tests/shared-lib.reds"
	}
]

;-- The following callbacks are all optional and do not need to be added to export block.
;-- If you use them, pay attention to platform-specific function prototypes

#switch OS [
	Windows [
		;-- Raised when the DLL is loaded ('load/library from REBOL)
		on-load: func [handle [integer!]][
			print-line "on-load executed"
		]

		;-- Raised when the DLL is unloaded ('free from REBOL)
		on-unload: func [handle [integer!]][
			print-line "on-unload executed"
		]

		;-- Raised when a new thread is launched
		on-new-thread: func [handle [integer!]][
			print-line "on-new-thread executed"
		]

		;-- Raised when a thread is exiting
		on-exit-thread: func [handle [integer!]][
			print-line "on-exit-thread executed"
		]
	]
	MacOSX [
		;-- Raised when the DLL is loaded ('load/library from REBOL)
		on-load: func [
			argc	[integer!]
			argv	[struct! [s [c-string!]]]
			envp	[struct! [s [c-string!]]]
			apple	[struct! [s [c-string!]]]			;-- ??
			pvars	[program-vars!]
		][
			print-line "on-load executed"
		]

		;-- Raised when the DLL is unloaded ('free from REBOL)
		on-unload: func [[cdecl]][
			print-line "on-unload executed"
		]
	]
	#default [											;-- Linux
		;-- Raised when the DLL is loaded ('load/library from REBOL)
		on-load: func [][
			print-line "on-load executed"
		]

		;-- Raised when the DLL is unloaded ('free from REBOL)
		on-unload: func [[cdecl]][
			print-line "on-unload executed"
		]
	]
]

;-- Global variables can be exported too
i: 56

;-- Function are exported as is
foo: func [
	a		[integer!]
	return: [integer!]
][
	?? i
	a + 1
]

;-- This function should trigger a runtime error
;-- that should be caught by Red/System's runtime
;-- Test it from DOS console, with a C loader.
bar: func [][1 / 0]

;-- This compiler directive defines what symbols (global variable or function)
;-- will be exposed by the DLL to the host program.
;#export [foo bar i]

;-- Alternatively, you can force a calling convention on exported
;-- functions, only stdcall and cdecl are supported. Cdecl is the default one.

#export stdcall [foo bar i]