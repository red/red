Red/System [
	Title:   "Red/System Linux runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %linux.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define LIBC-file	"libc.so.6"

#syscall [
	write: 4 [
		fd		[integer!]
		buffer	[c-string!]
		count	[integer!]
		return: [integer!]
	]
	quit: 1 [					;-- "exit" syscall
		status	[integer!]
	]
]

stdin:  0
stdout: 1
stderr: 2

prin: func [s [c-string!] return: [integer!]][
	write stdout s length? s
]

print: func [s [c-string!] return: [integer!]][
	prin s
	write stdout newline 1
]
