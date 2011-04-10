REBOL [
	Title:   "Red/System Win32 runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

prolog {
	#include %common.reds
	
	#define WIN_STD_INPUT_HANDLE	-10
	#define WIN_STD_OUTPUT_HANDLE	-11
	#define WIN_STD_ERROR_HANDLE	-12

	#import [
		"kernel32.dll" stdcall [
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
				;return:	[integer!]
			]
			SetConsoleTextAttribute: "SetConsoleTextAttribute" [
				handle 		[integer!]
				attributes  [integer!]
				;return:		[integer!]
			]
			quit: "ExitProcess" [
				code		[integer!]
			]
		]
	]

	newline: "^^/"

	stdout: GetStdHandle WIN_STD_OUTPUT_HANDLE
	written: struct [value [integer!]]

	prin: func [s [c-string!] return: [integer!]][
		WriteFile stdout s length? s written 0
	]

	print: func [s [c-string!] return: [integer!]][
		prin s
		WriteFile stdout newline 1 written 0
	]

	set-pen-color: func [color [integer!]][
		SetConsoleTextAttribute stdout color
	]

	set-colors: func [pen [integer!] bg [integer!]][
		SetConsoleTextAttribute stdout bg * 16 or pen
	]

	black:   0
	blue: 	 1
	green:	 2
	red:	 4
	cyan:  	 blue or green
	magenta: blue or red
	yellow:  green or red
	white:   blue or green or red

	light-blue:  blue  or 8
	light-green: green or 8
	light-red: 	 red   or 8
}

epilog {
	quit 0
}
