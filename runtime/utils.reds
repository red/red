Red/System [
	Title:   "Red runtime utility functions"
	Author:  "Nenad Rakocevic"
	File: 	 %utils.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#either OS = 'Windows [
	find-space-UTF16LE: func [
		args	[byte-ptr!]
		return: [byte-ptr!]
	][
		while [
			not all [
				any [args/1 = #" " args/1 = null-byte]
				args/2 = null-byte
			]
		][
			args: args + 2
		]
		args											;-- returns position after first space
	]
][

]

get-cmdline-name: func [
	return: [red-value!]
	/local
		args  [byte-ptr!]
		cmd   [byte-ptr!]
		len	  [integer!]
		saved [byte!]
][
	#either OS = 'Windows [
		cmd: platform/GetCommandLine
		args: find-space-UTF16LE cmd
		saved: args/1
		args/1: null-byte								;-- force a terminal NUL
		len: platform/lstrlen cmd
		args/1: saved									;-- restore the changed byte
		
		as red-value! file/load as-c-string cmd len UTF-16LE
	][
		;; TODO
		as red-value! none-value
	]
]

get-cmdline-args: func [
	return: [red-value!]
	/local
		args [byte-ptr!]
][
	#either OS = 'Windows [
		args: find-space-UTF16LE platform/GetCommandLine
		
		as red-value! either all [
			args/1 = null-byte
			args/2 = null-byte
		][
			none-value
		][
			args: args + 2								;-- skip extra space
			string/load as-c-string args platform/lstrlen args UTF-16LE
		]
	][
		;; TODO
		as red-value! none-value
	]
]