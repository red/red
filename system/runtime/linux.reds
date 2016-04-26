Red/System [
	Title:   "Red/System Linux runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %linux.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define OS_TYPE		2

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
#if type = 'exe [
	#either use-natives? = yes [
		system/args-count:	pop
		system/args-list:	as str-array! system/stack/top
		system/env-vars:	system/args-list + system/args-count + 1
	][
		;-- the current stack is pointing to main(int argc, void **argv, void **envp) C layout
		;-- we avoid the double indirection by reusing our variables from %start.reds
		system/args-count:	***__argc
		system/args-list:	as str-array! ***__argv
		system/env-vars:	system/args-list + system/args-count + 1
	]
]

#include %linux-sigaction.reds
#include %POSIX.reds
