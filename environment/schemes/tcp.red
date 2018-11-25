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

write-socket: routine [
	p		[object!]
	data	[string!]
][
	0
]

read-socket: routine [
	p		[object!]
][
	0
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
	open: func [port [port!] /local spec][
		probe "open port"
	]

	insert: func [port data][write-socket port data]

	copy: func [port][read-socket port]

	close: func [port [port!]][
		;TBD ;-- wait until IO finishes or timeout
		port/state/closed?: yes
		port/state/info: none
	]
]

register-scheme 'tcp tcp-scheme