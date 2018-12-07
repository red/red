Red/System [
	Title:	"epoll on Linux"
	Author: "Xie Qingtian"
	File: 	%poller.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

g-poller: as int-ptr! 0

#enum sock-op-code! [
	SOCK_OP_NONE
	SOCK_OP_ACCEPT
	SOCK_OP_CONN
	SOCK_OP_READ
	SOCK_OP_WRITE
	SOCK_OP_READ_UDP
	SOCK_OP_WRITE_UDP
]

poller!: alias struct! [
	maxn	[integer!]
	epfd	[integer!]				;-- the epoll fd
	events	[epoll_event!]			;-- the events
	nevents [integer!]				;-- the events count
]

poll: context [
	init: func [
		return: [int-ptr!]
		/local
			p	[poller!]
	][
		p: as poller! alloc0 size? poller!
		p/maxn: 65536
		p/epfd: epoll_create1 00080000h
		assert p/epfd > 0

		sockdata/init

		as int-ptr! p
	]

	exit: func [
		ref		[int-ptr!]
		/local
			p	[poller!]
	][
		p: as poller! ref
		_close p/epfd
		if p/events <> null [
			free as byte-ptr! p/events
		]
		free as byte-ptr! p
	]

	kill: func [][]

	add: func [
		ref		[int-ptr!]
		sock	[int-ptr!]
		events	[integer!]
		data	[int-ptr!]
		/local
			p	[poller!]
	][
		p: as poller! ref
		epoll_ctl sock 
	]

	remove: func [][]

	modify: func [][]

	wait: func [
		ref			[int-ptr!]
		timeout		[integer!]
		return:		[integer!]
		/local
			p		[poller!]
			res		[integer!]
			cnt		[integer!]
			err		[integer!]
			i		[integer!]
			e		[OVERLAPPED_ENTRY!]
			data	[iocp-data!]
			bin		[red-binary!]
			msg		[red-object!]
			type	[integer!]
			red-port [red-object!]
	][
		#if debug? = yes [print-line "poll/wait"]

		forever [
			p: as poller! either null? ref [g-poller][ref]
			if null? p/events [
				p/evt-cnt: 512
				p/events: as OVERLAPPED_ENTRY! allocate p/evt-cnt * size? OVERLAPPED_ENTRY!
			]

			cnt: 0
			res: GetQueuedCompletionStatusEx p/port p/events p/evt-cnt :cnt timeout no
			err: GetLastError
			if all [res <> 0 err = WAIT_TIMEOUT][return 0]

			if cnt = p/evt-cnt [			;-- TBD: extend events buffer
				0
			]

			i: 0
			while [i < cnt][
				e: p/events + i
				data: as iocp-data! e/lpOverlapped
				red-port: as red-object! :data/cell
				msg: red-port
				switch data/code [
					IOCP_OP_ACCEPT	[
						msg: create-red-port red-port data/accept
						type: IO_EVT_ACCEPT
					]
					IOCP_OP_CONN	[type: IO_EVT_CONNECT]
					IOCP_OP_READ	[
						bin: binary/load data/buffer e/dwNumberOfBytesTransferred
						copy-cell as cell! bin (object/get-values red-port) + port/field-data
						stack/pop 1
						type: IO_EVT_READ
					]
					IOCP_OP_WRITE	[type: IO_EVT_WROTE]
					IOCP_OP_READ_UDP	[0]
					IOCP_OP_WRITE_UDP	[0]
					default			[probe ["wrong iocp code: " data/code]]
				]
				call-awake red-port msg type
				i: i + 1
			]
		]
		0
	]
]