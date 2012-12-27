Red [
	Title:	"Red console"
	Author: "Nenad Rakocevic"
	File: 	%console.red
	Tabs: 	4
	Rights: "Copyright (C) 2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#system-global [
	#import [
		"kernel32.dll" stdcall [
			AttachConsole: "AttachConsole" [
				processID		[integer!]
				return:			[integer!]
			]
			SetConsoleTitle: "SetConsoleTitleA" [
				title			[c-string!]
				return:			[integer!]
			]
			ReadConsole: "ReadConsoleA" [
				consoleInput	[integer!]
				buffer			[byte-ptr!]
				charsToRead		[integer!]
				numberOfChars	[int-ptr!]
				inputControl	[int-ptr!]
				return:			[integer!]
			]
		]
	]
]

init-console: routine [
	str [string!]
	/local
		ret
][
	;ret: AttachConsole -1
	;if zero? ret [print-line "ReadConsole failed!" halt]
	
	ret: SetConsoleTitle as c-string! string/rs-head str
	if zero? ret [print-line "ReadConsole failed!" halt]
]

input: routine [
	/local
		len ret str buffer
][
	len: 0
	buffer: allocate 128
	ret: ReadConsole stdin buffer 127 :len null
	if zero? ret [print-line "ReadConsole failed!" halt]
	len: len + 1
	buffer/len: null-byte
	str: string/load as c-string! buffer len
	free buffer
	SET_RETURN(str)
]

quit: :halt
q: :quit

init-console "Red Console (Xmas demo edition!)"

print {
-=== Red Console pre-alpha version ===-
(only Latin-1 input supported)
}

while [true][
	prin "red>> "
	unless tail? line: input [
		code: load line
		unless tail? code [
			result: do code
			unless unset? result [
				prin "== "
				probe result
			]
		]
	]
]