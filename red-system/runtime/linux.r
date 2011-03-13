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
		_exit: 1 [
			status	[integer!]
		]
	]
	
	write 1 "Hello World!^^/" 13
}

epilog {
	_exit 42
}
