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
	data	[any-type!]
][
	socket/write p data
]

read-socket: routine [
	p		[object!]
][
	socket/read p
]

close-socket: routine [
	p		[object!]
][
	socket/close p
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

	insert: func [
		port [port!]
		data [binary! string!]
	][
		write-socket port data
	]

	copy: func [port [port!]][read-socket port]

	close: func [port [port!]][
		port/state/closed?: yes
		port/state/info: none
		close-socket port
	]
]

register-scheme 'tcp tcp-scheme