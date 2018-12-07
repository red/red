Red/System [
	Title:	"Functions for I/O"
	Author: "Xie Qingtian"
	File: 	%IO.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

g-poller: as int-ptr! 0

sockaddr_in!: alias struct! [				;-- 16 bytes
	sin_family	[integer!]					;-- family and port
	sin_addr	[integer!]
	sa_data1	[integer!]
	sa_data2	[integer!]
]

#if OS <> 'Windows [#include %POSIX/definitions.reds]

store-socket-data: func [
	data		[int-ptr!]
	red-port	[red-object!]
	/local
		state	[red-object!]
][
	state: as red-object! (object/get-values red-port) + port/field-state
	integer/make-at (object/get-values state) + 1 as-integer data
]

get-socket-data: func [
	red-port	[red-object!]
	return:		[int-ptr!]
	/local
		state	[red-object!]
		int		[red-integer!]
][
	state: as red-object! (object/get-values red-port) + port/field-state
	int: as red-integer! (object/get-values state) + 1
	as int-ptr! int/value
]

tcp-client: func [
	p		[red-object!]
	host	[red-string!]
	port	[red-integer!]
	/local
		fd	[integer!]
		n	[integer!]
		s	[c-string!]
][
	if null? g-poller [g-poller: poll/init]
	fd: socket/create AF_INET SOCK_STREAM IPPROTO_TCP

	n: -1
	s: unicode/to-utf8 host :n
	socket/connect p fd s port/value AF_INET
]

tcp-server: func [
	p		[red-object!]
	port	[red-integer!]
	/local
		fd	[integer!]
		acp [integer!]
][
	if null? g-poller [g-poller: poll/init]
	fd: socket/create AF_INET SOCK_STREAM IPPROTO_TCP
	socket/bind fd port/value AF_INET
	#either OS = 'Windows [
		acp: socket/create AF_INET SOCK_STREAM IPPROTO_TCP
	][
		acp: 0
	]
	socket/accept p fd acp
]

start-red-port: func [
	red-port	[red-object!]
	/local
		values	[red-value!]
		spec	[red-object!]
		host	[red-string!]
		p		[red-integer!]
		scheme	[red-word!]
][
	spec:	as red-object! (object/get-values red-port) + port/field-spec
	values: object/get-values spec
	scheme: as red-word! values				;-- TBD: check scheme
	host:	as red-string! values + 2
	p:		as red-integer! values + 3
	either TYPE_NONE = TYPE_OF(host) [		;-- start a tcp server
		tcp-server red-port p
	][
		tcp-client red-port host p
	]
]

call-awake: func [
	red-port	[red-object!]
	msg			[red-object!]
	op			[io-event-type!]
	/local
		values	 [red-value!]
		awake	 [red-function!]
		event	 [red-event! value]
][
	values: object/get-values red-port
	awake: as red-function! values + port/field-awake
	event/header: TYPE_EVENT
	event/type: op
	event/msg: as byte-ptr! msg
	stack/mark-func words/_awake awake/ctx
	stack/push as red-value! :event
	port/call-function awake awake/ctx
	stack/reset
]