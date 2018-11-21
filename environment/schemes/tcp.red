Red [
	Title:   "TCP protocol"
	Author:  "Xie Qingtian"
	File: 	 %tcp.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

tcp-scheme: context [
	verbose: 0

	s-copy: :system/words/copy
	s-find: :system/words/find

	throw-error: func [msg][
		unless string? msg [msg: form reduce msg]
		cause-error 'access 'invalid-spec [msg]
	]
	
	;--- Port actions ---
	
	open: func [port /local psi ref res http cmd value][
		probe "open port"
		probe port
	]
	
	insert: func [port data /local cmd address msg res psi get-tx?][

	]
	
	copy: func [port][
		also port/data port/data: none
	]

	close: func [port][
		;-- wait until IO finishes or timeout
		port/state/closed?: yes
		port/state/info: none
	]
]

register-scheme 'tcp tcp-scheme

open tcp://:8501