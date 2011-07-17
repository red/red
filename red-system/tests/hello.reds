Red/System [
	Title:   "Red/System small demo app"
	Author:  "Nenad Rakocevic"
	File: 	 %hello.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#either OS = 'Windows [
	#import [
		"kernel32.dll" stdcall [
			SetConsoleTextAttribute: "SetConsoleTextAttribute" [
				handle 		[integer!]
				attributes  [integer!]
				return:		[integer!]
			]
		]
	]
	
	set-pen-color: func [color [integer!]][
		SetConsoleTextAttribute stdout color
	]

	black:   0
	blue: 	 1
	green:	 2
	red:	 4
][
	set-pen-color: func [color [integer!]][
		either color = white [
			prin "^[[0m"
		][ 
			prin "^[["
			prin-int either color >= 7 [1][0]
			prin ";3"
			prin-int color and 7	;-- mask only right 3 bits for color
			prin "m"
		]
	]
	
	black:   0
	red: 	 1
	green:	 2
	blue:	 4
]

cyan:  	 blue or green
magenta: blue or red
yellow:  green or red
white:   blue or green or red

light-blue:  blue  or 8
light-green: green or 8
light-red: 	 red   or 8

prin-logo: does [
	set-pen-color light-red
	prin "R"
	set-pen-color white
	prin "ed"
]

draw-hline: func [size [integer!] alt [integer!] /local c [integer!]][
	c: size							;-- local variable is not necessary, just for the demo
	until [
		either positive? alt [		;-- print * and - alternatively
			alt: either alt = 1 [
				prin "*"
				2
			][
				prin "-" 
				1
			]
		][
			prin "-"				;-- print - only
		]
		c: c - 1
		zero? c
	]
	prin "^/"
]

draw-vline: does [prin "|"]

pad: func [n [integer!]][
	while [n > 0][prin " " n: n - 1] ;-- could have used UNTIL, just for the demo
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
print "/System v0.2.0 beta^/"

size: 20
until [
	banner size
	size: size + 2
	size = 40
]
