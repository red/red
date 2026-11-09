Red/System [
	Title:   "Red/System IA-32 instruction encoding test source, PIC"
	File: 	 %ia32-encoding-pic.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Config:  [cpu-version: 1.0]
]

;-- Compiled as a Linux shared library (PIC code) by ia32-encoding-test.r, which checks the emitted code; never run.

ia32-pic-cast: func [f [float!] return: [integer!]][
	as integer! f									;-- FISTP path: FLDCW restores the control word, [ebx+disp]
]

#export [ia32-pic-cast]
