Red/System [
	Title:   "Red/System MacOS X runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %darwin.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#define OS_TYPE		4

#syscall [
	write: 4 [
		fd		[integer!]
		buffer	[c-string!]
		count	[integer!]
		return: [integer!]
	]
]

#if use-natives? = yes [
	#syscall [
		quit: 1 [							;-- "exit" syscall
			status	[integer!]
		]
	]
]

;-------------------------------------------
;-- Retrieve command-line information from stack
;-------------------------------------------
system/args-count: 	pop
system/args-list: 	as str-array! system/stack/top
system/env-vars: 	system/args-list + system/args-count + 1


#include %BSD.reds
