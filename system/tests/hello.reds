Red/System [
	Title:   "Red/System small demo app"
	Author:  "Nenad Rakocevic"
	File: 	 %hello.reds
	Tabs:	 4
	Version: 1.0.2.4
	Company: "FullStack Technologies"
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
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
			print "^[[0m"
		][ 
			print [
				"^[[" either color >= 7 [1][0] ";3"
				color and 7	"m"					;-- mask only right 3 bits for color
			]
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

print-logo: does [
	set-pen-color light-red
	print "R"
	set-pen-color white
	print "ed"
]

draw-hline: func [size [integer!] alt [integer!] /local c [integer!]][
	c: size							;-- local variable is not necessary, just for the demo
	until [
		either positive? alt [		;-- print * and - alternatively
			alt: either alt = 1 [
				print "*"
				2
			][
				print "-" 
				1
			]
		][
			print "-"				;-- print - only
		]
		c: c - 1
		zero? c
	]
	print newline
]

draw-vline: does [print "|"]

pad: func [n [integer!]][
	while [n > 0][print space n: n - 1] ;-- could have used UNTIL, just for the demo
]

banner: func [width [integer!]][
	draw-hline width 1
	draw-vline
	pad (width - 16) / 2 - 1
	print "Hello " 
	print-logo
	print " World!"
	pad ((width - 16) / 2) - 1		;-- just showing nested parenthesis support
	draw-vline
	print newline
	draw-hline width 0
]

print-logo
print ["/System" lf lf]

size: 20
until [
	banner size
	size: size + 2
	size = 40
]
