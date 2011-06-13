Red/System [
	Title:   "Red/System Win32 runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define LIBC-file	"msvcrt.dll"

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
			return:		[integer!]
		]
		quit: "ExitProcess" [
			code		[integer!]
		]
	]
]

stdout: GetStdHandle WIN_STD_OUTPUT_HANDLE
__written: struct [value [integer!]]

prin: func [s [c-string!] return: [integer!]][
	WriteFile stdout s length? s __written 0
]

print: func [s [c-string!] return: [integer!]][
	prin s
	WriteFile stdout newline 1 __written 0
]
