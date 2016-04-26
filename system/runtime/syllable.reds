Red/System [
	Title:   "Red/System Syllable runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %syllable.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define OS_TYPE		3

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
		quit: 6 [							;-- "exit" syscall
			status	[integer!]
		]
	]
]

;-------------------------------------------
;-- Retrieve command-line information from stack
;-------------------------------------------
#if type = 'exe [
	#either use-natives? = yes [
		pop										;-- dummy value
		system/args-list: as str-array! pop		;-- &argv
		system/env-vars:  as str-array! pop		;-- &envp

	][
		;-- the current stack is pointing to main(int argc, void **argv, void **envp) C layout
		;-- we avoid the double indirection by reusing our variables from %start.reds
		system/args-list: as str-array! ***__argv
		system/env-vars:  as str-array! ***__envp
	]

	***-get-argc: func [/local c argv][
		argv: system/args-list
		c: 0
		while [argv/item <> null][
			c: c + 1
			argv: argv + 1
		]
		system/args-count: c
	]
	***-get-argc
]
	
#include %linux-sigaction.reds
#include %POSIX.reds
