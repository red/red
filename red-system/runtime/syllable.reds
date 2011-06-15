Red/System [
	Title:   "Red/System Syllable runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %syllable.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define OS_TYPE		3
#define LIBC-file	"libc.so.2"

#syscall [
	write: 4 [
		fd		[integer!]
		buffer	[c-string!]
		count	[integer!]
		return: [integer!]
	]
	quit: 6 [					;-- "exit" syscall
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