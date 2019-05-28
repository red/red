Red/System [
	Title:	"Functions for I/O"
	Author: "Xie Qingtian"
	File: 	%ports.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

g-poller: as int-ptr! 0

#include %sockdata.reds
;#include %usb.reds

#either OS = 'Windows [
	DATA-COMMON!: alias struct! [
		ovlap	[OVERLAPPED! value]
		cell	[cell! value]			;-- the port! cell
		fd		[integer!]				;-- the fd
		bind	[int-ptr!]				;-- the bound port
	]
	#include %socket-win32.reds
	#include %usb-win32.reds
	#include %poller-iocp.reds
][
	DATA-COMMON!: alias struct! [
		cell	[cell! value]
		fd		[integer!]
	]
	#include %socket-posix.reds
	#case [
		any [OS = 'macOS OS = 'FreeBSD][
			#include %usb-macos.reds
			#include %poller-kqueue.reds
		]
		any [OS = 'Linux OS = 'Android][
			#include %usb-linux.reds
			#include %poller-epoll.reds
		]
		true [
			#include %poller-poll.reds
		]
	]
]

get-port-sym: func [
	red-port	[red-object!]
	return:		[integer!]
	/local
		spec	[red-object!]
		scheme	[red-word!]
][
	spec: as red-object! (object/get-values red-port) + port/field-spec
	scheme: as red-word! (object/get-values spec)
	symbol/resolve scheme/symbol
]

create-socket-data: func [
	socket	[integer!]
	return: [sockdata!]
	/local
		data [sockdata!]
][
	;@@ TBD get sockdata from the cache first
	data: as sockdata! alloc0 size? sockdata!
	data/sock: socket
	data
]

create-red-port: func [
	proto		[red-object!]
	sock		[integer!]
	return:		[red-object!]
	/local
		p		[red-object!]
		data	[sockdata!]
][
	data: create-socket-data sock
	sockdata/insert sock as int-ptr! data
	p: port/make none-value object/get-values proto TYPE_NONE
	block/rs-append red-port-buffer as cell! p
	copy-cell as cell! p as cell! :data/cell
	store-port-data as int-ptr! data p
	p
]

store-port-data: func [
	data		[int-ptr!]
	red-port	[red-object!]
	/local
		state	[red-object!]
][
	state: as red-object! (object/get-values red-port) + port/field-state
	integer/make-at (object/get-values state) + 1 as-integer data
]

get-port-data: func [
	red-port	[red-object!]
	return:		[int-ptr!]
	/local
		state	[red-object!]
		int		[red-integer!]
][
	state: as red-object! (object/get-values red-port) + port/field-state
	int: as red-integer! (object/get-values state) + 1
	either TYPE_OF(int) = TYPE_NONE [null][as int-ptr! int/value]
]

get-port-pipe: func [
	red-port	[red-object!]
	addr		[int-ptr!]
	type		[int-ptr!]
	return:		[integer!]
	/local
		state	[red-object!]
		int		[red-integer!]
		word	[red-word!]
		sym		[integer!]
][
	state: as red-object! (object/get-values red-port) + port/field-state
	int: as red-integer! (object/get-values state) + 5
	if TYPE_OF(int) = TYPE_INEGER [
		addr/value: int/value
		return 1
	]
	if TYPE_OF(int) <> TYPE_WORD [
		return -1
	]
	word: as red-word! int
	sym: symbol/resolve word/symbol
	if sym = words/control [
		type/value: PIPE-TYPE-CONTROL
		return 0
	]
	if sym = words/isochronous [
		type/value: PIPE-TYPE-ISOCH
		return 0
	]
	if sym = words/bulk [
		type/value: PIPE-TYPE-BULK
		return 0
	]
	if sym = words/interrupt [
		type/value: PIPE-TYPE-INTERRUPT
		return 0
	]
	return -1
]

get-port-read-size: func [
	red-port	[red-object!]
	return:		[integer!]
	/local
		state	[red-object!]
		int		[red-integer!]
][
	state: as red-object! (object/get-values red-port) + port/field-state
	int: as red-integer! (object/get-values state) + 6
	either TYPE_OF(int) = TYPE_INEGER [int/value][0]
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

usb-start: func [
	red-port	[red-object!]
	host		[red-string!]
][
	if null? g-poller [g-poller: poll/init]
	usb/init
	print-line "start"
	usb/open red-port host
	print-line "end"
	call-awake red-port red-port IO_EVT_CONNECT
]

start-red-port: func [
	red-port	[red-object!]
	/local
		values	[red-value!]
		spec	[red-object!]
		state	[red-object!]
		closed?	[red-logic!]
		host	[red-string!]
		p		[red-integer!]
		scheme	[red-word!]
		sym		[integer!]
][
	values: object/get-values red-port
	state: as red-object! values + port/field-state
	p: as red-integer! (object/get-values state) + 1
	if TYPE_OF(p) <> TYPE_NONE [exit]

	spec:	as red-object! values + port/field-spec
	values: object/get-values spec
	scheme: as red-word! values				;-- TBD: check scheme
	sym: symbol/resolve scheme/symbol
	host:	as red-string! values + 2
	p:		as red-integer! values + 3
	case [
		sym = words/tcp [
			either TYPE_NONE = TYPE_OF(host) [		;-- start a tcp server
				tcp-server red-port p
			][
				tcp-client red-port host p
			]
		]
		sym = words/usb [
			usb-start red-port host
		]
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

