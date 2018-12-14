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
		errno: get-errno-ptr
		p: as poller! alloc0 size? poller!
		p/maxn: 65536
		p/epfd: epoll_create1 00080000h
		assert p/epfd > 0

		sockdata/init
		sock-readbuf: allocate 1024 * 1024

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

	_modify: func [
		ref		[int-ptr!]
		sock	[integer!]
		evts	[integer!]
		data	[int-ptr!]
		op		[integer!]
		/local
			p	[poller!]
			ev	[epoll_event! value]
	][
		p: as poller! ref
		ev/ptr: data
		ev/events: evts
		if 0 <> epoll_ctl p/epfd op sock :ev [
			probe ["epoll_ctl error! fd: " sock " op: " op]
		]
	]

	add: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][
		_modify ref sock events data EPOLL_CTL_ADD
	]

	remove: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][
		_modify ref sock events data EPOLL_CTL_DEL
	]

	modify: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][
		_modify ref sock events data EPOLL_CTL_MOD
	]

	update: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][
		
	]

	wait: func [
		ref			[int-ptr!]
		timeout		[integer!]
		return:		[integer!]
		/local
			p		[poller!]
			cnt		[integer!]
			i		[integer!]
			e		[epoll_event!]
			data	[sockdata!]
			bin		[red-binary!]
			msg		[red-object!]
			n		[integer!]
			acpt	[integer!]
			type	[integer!]
			saddr	[sockaddr_in! value]
			err		[integer!]
			red-port [red-object!]
	][
		#if debug? = yes [print-line "poll/wait"]

		forever [
			p: as poller! either null? ref [g-poller][ref]
			if null? p/events [
				p/nevents: 512
				p/events: as epoll_event! allocate p/nevents * size? epoll_event!
			]

			cnt: epoll_wait p/epfd p/events p/nevents timeout
			if all [cnt < 0 errno/value = EINTR][return 0]

			if cnt = p/nevents [		;-- TBD: extend events buffer
				0
			]
?? cnt
			i: 0
			while [i < cnt][
				e: p/events + i
				data: as sockdata! e/ptr
				red-port: as red-object! :data/cell
				msg: red-port
probe ["code: " data/code]
				switch data/code [
					SOCK_OP_ACCEPT	[
						n: size? sockaddr_in!
						acpt: _accept data/sock as byte-ptr! :saddr :n
						?? acpt
						if acpt = -1 [
							err: errno/value
							i: i + 1
							continue
						]
						socket/set-nonblocking acpt
						msg: create-red-port red-port acpt
						type: IO_EVT_ACCEPT
					]
					SOCK_OP_CONN	[type: IO_EVT_CONNECT]
					SOCK_OP_READ	[
						socket/read red-port
						i: i + 1
						continue
					]
					SOCK_OP_WRITE	[
						socket/write red-port data/buffer
						i: i + 1
						continue
					]
					SOCK_OP_READ_UDP	[0]
					SOCK_OP_WRITE_UDP	[0]
					default				[probe ["wrong socket code: " data/code]]
				]
				call-awake red-port msg type
				i: i + 1
			]
		]
		0
	]
]