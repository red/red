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

tcp-client: routine [
	p		[port!]
	host	[string!]
	port	[integer!]
][
	if null? g-poller [g-poller: poll/init]
	0
]

tcp-server: routine [
	p		[port!]
	port	[integer!]
	/local
		fd	[integer!]
		acp [integer!]
][
	if null? g-poller [g-poller: poll/init]
	fd: socket/create AF_INET SOCK_STREAM IPPROTO_TCP
	socket/bind fd port AF_INET
	acp: socket/create AF_INET SOCK_STREAM IPPROTO_TCP
	socket/accept p fd acp
]

write-socket: routine [
	p		[port!]
	data	[string!]
][
	0
]

read-socket: routine [
	p		[port!]
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
		spec: port/spec
		either spec/host [
			tcp-client port spec/host spec/port
		][
			tcp-server port spec/port
		]
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