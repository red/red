Red/System [
	Title:   "Red/System small demo app"
	Author:  "Nenad Rakocevic"
	File: 	 %hello.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;-- Minimal runtime environment ---

#define WIN_STD_INPUT_HANDLE	-10
#define WIN_STD_OUTPUT_HANDLE	-11
#define WIN_STD_ERROR_HANDLE	-12

#import [
	"kernel32.dll" [
		VirtualAlloc: "VirtualAlloc" [
			address		[struct! [chunk [binary!]]]
			size		[integer!]
			type		[integer!]
			protection	[integer!]
			return: 	[integer!]
		]
		GetStdHandle: "GetStdHandle" [
		  	type		[integer!]
		  	return:		[integer!]
		]
		WriteConsole: "WriteConsoleA" [
		  	handle		[integer!]
		  	buffer		[string!]
		  	len			[integer!]
		  	written		[struct! [value [integer!]]]
		  	reserved	[integer!]
		  	;return:	[integer!]
		]
		SetConsoleTextAttribute: "SetConsoleTextAttribute" [
			handle 		[integer!]
		  	attributes  [integer!]
		  	;return:		[integer!]
		]
		ExitProcess: "ExitProcess" [
  			code		[integer!]
  		]
	]
]

newline: "^/"

stdout: GetStdHandle WIN_STD_OUTPUT_HANDLE
written: struct [value [integer!]]

prin: func [s [string!] return: [integer!]][
	WriteConsole stdout s length? s written 0
]

print: func [s [string!] return: [integer!]][
	prin s
	WriteConsole stdout "^/" 1 written 0
]

set-pen-color: func [color [integer!]][
	SetConsoleTextAttribute stdout color
]

set-colors: func [pen [integer!] bg [integer!]][
	SetConsoleTextAttribute stdout (bg * 16) or pen		;-- parenthesis are optional here
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

;--- end of runtime environment ---


prin-logo: func [][
	set-pen-color light-red
	prin "R"
	set-pen-color white
	prin "ed"
]

draw-hline: func [size [integer!] alt [integer!] /local c [integer!]][
	c: size							;-- local variable is not necessary, just for the demo
	until [
		either alt > 0 [			;-- print * and - alternatively
			either alt = 1 [
				prin "*"
				alt: 2
			][
				prin "-" 
				alt: 1
			]
		][
			prin "-"				;-- print - only
		]
		c: c - 1
		c = 0
	]
	prin "^/"
]

draw-vline: func [][prin "|"]

pad: func [n [integer!]][
	while [n > 0][prin " " n: n - 1]	;-- could have used UNTIL, just for the demo
]

banner: func [width [integer!]][
	draw-hline width 1
	draw-vline
	pad (width - 16) / 2 - 1
	prin "Hello " 
	prin-logo
	prin " World!"
	pad ((width - 16) / 2) - 1		;-- just showing nested parenthesis support
	draw-vline
	prin newline
	draw-hline width 0
]

prin-logo
print "/System v0.1.0 alpha 1^/"

size: 20
until [
	banner size
	size: size + 2
	size = 40
]

ExitProcess 0						;-- required for now
									;-- should be part of runtime exit handler
