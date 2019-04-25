Red [
	Title:   "usb protocol"
	Author:  "bitbegin"
	File: 	 %usb.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

write-usb: routine [
	p		[object!]
	data	[any-type!]
][
	usb/write p data
]

read-usb: routine [
	p		[object!]
][
	usb/read p
]

close-usb: routine [
	p		[object!]
][
	usb/close p
]

usb-scheme: context [
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
		port/state/closed?: false
	]

	insert: func [
		port [port!]
		data [binary! string!]
	][
		unless port/state/closed? [write-usb port data]
	]

	copy: func [port [port!]][
		unless port/state/closed? [
			read-usb port
		]
	]

	close: func [port [port!]][
		unless port/state/closed? [
			close-usb port
			port/state/closed?: yes
			port/state/info: none
			port/state/sub: none
		]
	]
]

register-scheme 'usb usb-scheme