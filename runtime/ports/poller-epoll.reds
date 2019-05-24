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

poller!: alias struct! [
	maxn		[integer!]
	epfd		[integer!]				;-- the epoll fd
	events		[epoll_event!]			;-- the events
	nevents		[integer!]				;-- the events count
	pair-1		[integer!]
	pair-2		[integer!]
	ready-socks	[deque!]				;-- a queue for ready socket
]

poll: context [

	init: func [
		return: [int-ptr!]
		/local
			p	[poller!]
			ptr [sockdata!]
	][
		errno: get-errno-ptr
		p: as poller! alloc0 size? poller!
		p/maxn: 65536
		p/epfd: epoll_create1 00080000h
		assert p/epfd > 0

		p/ready-socks: deque/create 1024

		if -1 = socketpair 1 SOCK_STREAM 0 :p/pair-1 [
			probe "!!! create pair fail !!!"
		]
		socket/set-nonblocking p/pair-1
		socket/set-nonblocking p/pair-2

		ptr: socket/create-data p/pair-2
		add as int-ptr! p p/pair-2 EPOLLIN or EPOLLET as int-ptr! ptr

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
		_close p/pair-1
		_close p/pair-2
		_close p/epfd
		if p/events <> null [
			free as byte-ptr! p/events
		]
		free as byte-ptr! p
	]

	kill: func [
		ref		[int-ptr!]
		/local
			p	[poller!]
	][
		p: as poller! ref
		_send p/pair-1 as byte-ptr! "k" 1 0
	]

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

	push-ready: func [
		ref		[int-ptr!]
		sdata	[sockdata!]
		/local
			p	[poller!]
	][
		p: as poller! ref
		deque/push p/ready-socks as int-ptr! sdata
	]

	pulse: func [
		ref		[int-ptr!]
		/local
			p	[poller!]
	][
		p: as poller! ref
		_send p/pair-1 as byte-ptr! "p" 1 0
	]

	wait: func [
		ref			[int-ptr!]
		timeout		[integer!]
		return:		[integer!]
		/local
			p		[poller!]
			queue	[deque!]
			cnt		[integer!]
			i		[integer!]
			e		[epoll_event!]
			data	[sockdata!]
			bin		[red-binary!]
			msg		[red-object!]
			ret		[red-logic!]
			n		[integer!]
			acpt	[integer!]
			type	[integer!]
			saddr	[sockaddr_in! value]
			err		[integer!]
			red-port [red-object!]
			close?	[logic!]
			comm	[DATA-COMMON!]
			sym		[integer!]
			usbdata	[USB-DATA!]
			pNode				[INTERFACE-INFO-NODE!]
			handle	[integer!]
			wthread	[ONESHOT-THREAD!]
			rthread	[ONESHOT-THREAD!]
			len		[integer!]
	][
		#if debug? = yes [print-line "poll/wait"]

		err: 0
		p: as poller! either null? ref [g-poller][ref]
		if null? p/events [
			p/nevents: 512
			p/events: as epoll_event! allocate p/nevents * size? epoll_event!
		]
		queue: p/ready-socks

		forever [
			close?: no
			cnt: epoll_wait p/epfd p/events p/nevents timeout
			if all [cnt < 0 errno/value = EINTR][return 0]

			if cnt = p/nevents [		;-- TBD: extend events buffer
				0
			]
?? cnt
			i: 0
			while [i < cnt][
				e: p/events + i
				comm: as DATA-COMMON! e/ptr
				red-port: as red-object! :comm/cell
				sym: get-port-sym red-port
				if sym = words/tcp [
					data: as sockdata! e/ptr
					msg: red-port
	probe ["code: " data/code]
					switch data/code [
						SOCK_OP_NONE	[				;-- impluse event
							_recv data/sock sock-readbuf 1024 * 1024 0
							n: 0
							while [queue/size > 0][
								n: n + 1
								data: as sockdata! deque/take queue
								red-port: as red-object! :data/cell
								switch data/code [
									SOCK_OP_CONN  [type: IO_EVT_CONNECT]
									SOCK_OP_READ  [type: IO_EVT_READ]
									SOCK_OP_WROTE [type: IO_EVT_WROTE]
									SOCK_OP_READ_UDP	[0]
									SOCK_OP_WRITE_UDP	[0]
									SOCK_OP_CLOSE [
										sockdata/remove data/sock
										remove g-poller data/sock 0 null
										_close data/sock
										free as byte-ptr! data
										type: IO_EVT_CLOSE
										close?: yes
									]
									default				[probe ["wrong socket code: " data/code]]
								]
								call-awake red-port red-port type
								ret: as red-logic! stack/arguments
								if ret/value [close?: yes]
							]
							i: i + 1
							continue
						]
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
					ret: as red-logic! stack/arguments
					if ret/value [close?: yes]
					i: i + 1
				]
				if sym = words/usb [
					usbdata: as USB-DATA! e/ptr
					msg: red-port
					switch usbdata/code [
						SOCK_OP_ACCEPT	[
							;msg: create-red-port red-port data/accept
							type: IO_EVT_ACCEPT
						]
						SOCK_OP_CONN	[type: IO_EVT_CONNECT]
						SOCK_OP_READ	[
							pNode: usbdata/dev/interface
							rthread: as ONESHOT-THREAD! pNode/read-thread
							handle: 0
							_read rthread/pipe/in as byte-ptr! :handle 4
							print-line "usb len:"
							print-line rthread/actual-len
							bin: binary/load rthread/buffer rthread/actual-len
							copy-cell as cell! bin (object/get-values red-port) + port/field-data
							stack/pop 1
							type: IO_EVT_READ
						]
						SOCK_OP_WRITE	[
							pNode: usbdata/dev/interface
							wthread: as ONESHOT-THREAD! pNode/write-thread
							handle: 0
							_read wthread/pipe/in as byte-ptr! :handle 4
							type: IO_EVT_WROTE
						]
						SOCK_OP_READ_UDP	[0]
						SOCK_OP_WRITE_UDP	[0]
						default			[probe ["wrong sock code: " usbdata/code]]
					]
					call-awake red-port msg type
					ret: as red-logic! stack/arguments
					if ret/value [close?: yes]
					i: i + 1
				]
			]
			if close? [return 1]
		]
		0
	]
]