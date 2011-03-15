REBOL [
	Title:   "Red/System Linux runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %linux.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

prolog {	
	#syscall [
		write: 4 [
			fd		[integer!]
			buffer	[string!]
			count	[integer!]
			return: [integer!]
		]
		exit: 1 [
			status	[integer!]
		]
	]
	
	newline: "^^/"
	stdout: 1

	prin: func [s [string!] return: [integer!]][
		write stdout s length? s
	]

	print: func [s [string!] return: [integer!]][
		prin s
		write stdout "^^/" 1
	]

	set-pen-color: func [color [integer!]][
		;-- not supported for now
	]

	set-colors: func [pen [integer!] bg [integer!]][
		;-- not supported for now
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
	exit 0
}
