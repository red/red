Red/System [
	Title:   "Red/System small demo app"
	Author:  "Nenad Rakocevic"
	File: 	 %hello.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

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
		zero? c
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
print "/System v0.1.1 alpha^/"

size: 20
until [
	banner size
	size: size + 2
	size = 40
]
