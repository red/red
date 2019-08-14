Red/System [
	Title:	"IOCP on Linux"
	Author: "Xie Qingtian"
	File: 	%iocp.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	NOTE: {
		This is not a completed IOCP implementation on Linux.
	}
]

#define IO_STATE_READ_DONE	4000h
#define IO_STATE_WRITE_DONE	8000h

iocp-event-handler!: alias function! [
	data		[int-ptr!]
]

iocp!: alias struct! [
	maxn		[integer!]
	epfd		[integer!]				;-- the epoll fd
	events		[epoll_event!]			;-- the events
	nevents		[integer!]				;-- the events count
	pair-1		[integer!]
	pair-2		[integer!]
	ready-socks	[deque!]				;-- a queue for ready socket
	posted?		[logic!]
]

pending-data!: alias struct! [
	header			[list-entry! value]
	buffer			[byte-ptr!]
	buflen			[integer!]
]

iocp-data!: alias struct! [
	io-port			[iocp!]				;--	iocp! handle
	device			[handle!]			;-- device handle. e.g. socket
	event-handler	[iocp-event-handler!]
	event			[integer!]
	transferred		[integer!]			;-- number of bytes transferred
	read-buf		[byte-ptr!]
	read-buflen		[integer!]
	write-buf		[byte-ptr!]
	write-buflen	[integer!]		
	state			[integer!]
	pending-read	[pending-data!]
	pending-write	[pending-data!]
]

iocp: context [
	verbose: 0

	create: func [
		return: [iocp!]
		/local
			p	[iocp!]
			ptr [iocp-data!]
	][
		errno: get-errno-ptr
		p: as iocp! alloc0 size? iocp!
		p/maxn: 65536
		p/epfd: epoll_create1 00080000h
		assert p/epfd > 0

		p/ready-socks: deque/create 1024

		if -1 = socketpair 1 SOCK_STREAM 0 :p/pair-1 [
			probe "!!! create pair fail !!!"
		]
		socket/set-nonblocking p/pair-1
		socket/set-nonblocking p/pair-2

		ptr: as iocp-data! alloc0 size? iocp-data!
		ptr/device: as handle! p/pair-2
		ptr/event: IO_EVT_PULSE
		add p p/pair-2 EPOLLIN or EPOLLET ptr
		p
	]
 
	close: func [
		p [iocp!]
	][
		#if debug? = yes [print-line "iocp/close"]

		LibC.close p/pair-1
		LibC.close p/pair-2
		LibC.close p/epfd
		if p/events <> null [
			free as byte-ptr! p/events
		]
		free as byte-ptr! p
	]

	bind: func [
		"bind a device handle to the I/O completion port"
		p		[iocp!]
		handle	[int-ptr!]
	][
	]

	wait: func [
		"wait I/O completion events and dispatch them"
		p			[iocp!]
		timeout		[integer!]			;-- time in ms, -1: infinite
		return:		[integer!]
		/local
			queue	[deque!]
			cnt		[integer!]
			i		[integer!]
			e		[epoll_event!]
			data	[iocp-data!]
			n		[integer!]
			err		[integer!]
			sock	[integer!]
			datalen [integer!]
			evt		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "iocp/wait"]]

		err: 0
		if null? p/events [
			p/nevents: 512
			p/events: as epoll_event! allocate p/nevents * size? epoll_event!
		]
		queue: p/ready-socks

		cnt: epoll_wait p/epfd p/events p/nevents timeout
		if all [cnt < 0 errno/value = EINTR][return 0]
?? cnt
		if cnt = p/nevents [		;-- TBD: extend events buffer
			0
		]

		i: 0
		while [i < cnt][
			e: p/events + i
			data: as iocp-data! e/ptr
			evt: data/event
			sock: as-integer data/device
			either evt = IO_EVT_PULSE [
				datalen: 0
				n: LibC.recv sock as byte-ptr! :datalen 4 0
				assert n = 1

				p/posted?: no
				n: queue/size
				loop n [
					data: as iocp-data! deque/take queue
					evt: data/event
					probe ["pluse event: " evt]
					case [
						evt and IO_EVT_READ <> 0 [
							data/event: IO_EVT_READ
							data/event-handler as int-ptr! data
							if all [
								null? data/pending-read
								data/event = IO_EVT_NONE
							][
								data/event: evt and (not IO_EVT_READ)
							]
						]
						evt and IO_EVT_WRITE <> 0 [
							data/event: IO_EVT_WRITE
							data/event-handler as int-ptr! data
							if all [
								null? data/pending-write
								data/event = IO_EVT_NONE
							][
								data/event: evt and (not IO_EVT_WRITE)
							]
						]
						true [data/event-handler as int-ptr! data]
					]
				]
			][
				probe ["ready event: " evt " " e/events]
				case [
					all [
						e/events and EPOLLIN <> 0
						evt and IO_EVT_READ <> 0
					][
						either data/pending-read <> null [
							0 ;;TBD
						][
probe [sock " " data/read-buf " " data/read-buflen]
							if data/state and IO_STATE_READ_DONE = 0 [
								n: LibC.recv sock data/read-buf data/read-buflen 0
	probe errno/value
	probe ["read data: " n]
								data/transferred: n
								data/event: IO_EVT_READ
								data/event-handler as int-ptr! data
								if data/event = IO_EVT_NONE [
									data/event: evt and (not IO_EVT_READ)
								]
							]
						]
					]
					all [
						e/events and EPOLLOUT <> 0
						evt and IO_EVT_WRITE <> 0
					][
						either data/pending-write <> null [
							0 ;; TBD
						][
							if data/state and IO_STATE_WRITE_DONE = 0 [
								datalen: data/write-buflen
								n: LibC.send sock data/write-buf datalen 0
								either n = datalen [
									data/write-buf: null
									data/event: IO_EVT_WRITE
									data/event-handler as int-ptr! data
									if data/event = IO_EVT_NONE [
										data/event: evt and (not IO_EVT_WRITE)
									]
								][	;-- remaining data to be sent
									data/write-buf: data/write-buf + n
									data/write-buflen: data/write-buflen - n
								]
							]
						]
					]
					zero? evt [probe "why zero?"]
					true [data/event-handler as int-ptr! data]
				]
			]
			i: i + 1
		]
		1
	]

	create-pending: func [
		buffer	[byte-ptr!]
		len		[integer!]
		return: [pending-data!]
		/local
			pending [pending-data!]
	][
		pending: as pending-data! allocate size? pending-data!
		dlink/init as list-entry! pending
		pending/buffer: buffer		;-- save previous data
		pending/buflen: len
		pending
	]

	add-pending: func [
		data	[iocp-data!]
		buffer	[byte-ptr!]
		len		[integer!]
		evt		[integer!]		;-- can only be READ and WRITE event
		/local
			pending	[pending-data!]
	][
		switch evt [
			IO_EVT_READ [
				pending: data/pending-read
				if null? pending [
					pending: create-pending data/read-buf data/read-buflen
					data/pending-read: pending
					data/read-buflen: 1
				]
				data/read-buflen: data/read-buflen + 1
			]
			IO_EVT_WRITE [
				pending: data/pending-write
				if null? pending [
					pending: create-pending data/read-buf data/read-buflen
					data/pending-write: pending
					data/write-buflen: 1
				]
				data/write-buflen: data/write-buflen + 1
			]
			default [exit]
		]
		dlink/append
			as list-entry! pending
			as list-entry! create-pending buffer len
	]

	kill: func [
		p	[iocp!]
	][
		LibC.send p/pair-1 as byte-ptr! "k" 1 0
	]

	_modify: func [
		epfd	[integer!]
		sock	[integer!]
		evts	[integer!]
		data	[iocp-data!]
		op		[integer!]
		/local
			ev	[epoll_event! value]
	][
		ev/ptr: as int-ptr! data
		ev/events: evts
		if 0 <> epoll_ctl epfd op sock :ev [
			probe ["epoll_ctl error! fd: " sock " op: " op]
		]
	]

	add: func [
		p		[iocp!]
		sock	[integer!]
		events	[integer!]
		data	[iocp-data!]
	][
		_modify p/epfd sock events data EPOLL_CTL_ADD
	]

	remove: func [
		p		[iocp!]
		sock	[integer!]
		events	[integer!]
		data	[iocp-data!]
	][
		_modify p/epfd sock events data EPOLL_CTL_DEL
	]

	modify: func [
		p		[iocp!]
		sock	[integer!]
		events	[integer!]
		data	[iocp-data!]
	][
		_modify p/epfd sock events data EPOLL_CTL_MOD
	]

	post: func [
		p		[iocp!]
		data	[iocp-data!]
	][
		deque/push p/ready-socks as int-ptr! data
		unless p/posted? [
			p/posted?: yes
			LibC.send p/pair-1 as byte-ptr! "p" 1 0
		]
	]

	push-data: func [
		p		[iocp!]
		sdata	[iocp-data!]
	][
		deque/push p/ready-socks as int-ptr! sdata
	]

	pulse: func [
		p		[iocp!]
	][
		LibC.send p/pair-1 as byte-ptr! "p" 1 0
	]
]