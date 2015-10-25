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

get-cmdline-arg: func [
	return: [red-value!]
	/local
		args [byte-ptr!]
][
	#either OS = 'Windows [
		args: platform/GetCommandLine
		while [
			not all [
				any [args/1 = #" " args/1 = null-byte]
				args/2 = null-byte
			]
		][
			args: args + 2
		]								 					;-- returns position after first space
		either all [args/1 = null-byte args/2 = null-byte][
			none/push
		][
			string/load as-c-string args platform/lstrlen args UTF-16LE
		]
	][
		;; TODO
		none/push
	]
]