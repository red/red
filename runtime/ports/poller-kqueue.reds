Red/System [
	Title:	"A poller base on kqueue"
	Author: "Xie Qingtian"
	File: 	%poller-kqueue.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

poller!: alias struct! [
	maxn		[integer!]
	kqfd		[integer!]				;-- the kqueue fd
	events		[kevent!]				;-- the events
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
		p/kqfd: _kqueue
		assert p/kqfd > 0

		p/ready-socks: deque/create 1024

		if -1 = socketpair 1 SOCK_STREAM 0 :p/pair-1 [
			probe "!!! create pair fail !!!"
		]
		socket/set-nonblocking p/pair-1
		socket/set-nonblocking p/pair-2

		ptr: socket/create-data p/pair-2
probe ["init pair: " p/pair-1 " " p/pair-2]
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
		_close p/kqfd
		if p/events <> null [
			free as byte-ptr! p/events
		]
		free as byte-ptr! p
	]

	_modify: func [
		ref		[int-ptr!]
		evs		[kevent!]
		cnt		[integer!]
		/local
			p	[poller!]
			res [integer!]
	][
		p: as poller! ref
		probe ["kqfd " p/kqfd]
		res: _kevent p/kqfd evs cnt null 0 null
		?? res
		if 0 > res [
			probe ["change kevent failed, errno: " errno/value]
		]
	]

	add: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
		/local
			e2	[kevent! value]
			e1	[kevent! value]
			e	[kevent!]
			ev	[integer!]
			n	[integer!]
	][
		ev: EV_ADD
		if events and EPOLLET <> 0 [ev: ev or EV_CLEAR]

		e: as kevent! :e1
		n: 0
probe ["add sock: " sock]
		if events and EPOLLIN <> 0 [
			EV_SET(e sock EVFILT_READ ev 0 null data)
			n: n + 1
			e: e + 1
		]
		if events and EPOLLOUT <> 0 [
			EV_SET(e sock EVFILT_WRITE ev 0 null data)
			n: n + 1
		]
		_modify ref :e1 n
	]

	add-user: func [
		ref			[int-ptr!]
		fd			[integer!]
		data		[int-ptr!]
		/local
			e		[kevent! value]
			ev		[integer!]
	][
		ev: EV_ADD or EV_ENABLE or EV_CLEAR or EV_ONESHOT
		EV_SET(e fd EVFILT_USER ev 0 NULL data)
		_modify ref :e 1
	]

	trigger-user: func [
		ref			[int-ptr!]
		fd			[integer!]
		data		[int-ptr!]
		/local
			e		[kevent! value]
			ev		[integer!]
	][
		EV_SET(e fd EVFILT_USER 0 NOTE_TRIGGER NULL data)
		_modify ref :e 1
	]

	remove: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
		/local
			e2	[kevent! value]
			e1	[kevent! value]
			e	[kevent!]
			ev	[integer!]
			n	[integer!]
	][
		ev: EV_DELETE
		e: as kevent! :e1
		n: 0
probe ["remove sock: " sock]
		if events and EPOLLIN <> 0 [
			EV_SET(e sock EVFILT_READ ev 0 null null)
			n: n + 1
			e: e + 1
		]
		if events and EPOLLOUT <> 0 [
			EV_SET(e sock EVFILT_WRITE ev 0 null null)
			n: n + 1
		]
		_modify ref :e1 n
	]

	modify: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][
		probe "kqueue/modify"
		add ref sock events data
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
		;if zero? sdata/state [deque/push p/ready-socks as int-ptr! sdata]
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
			e		[kevent!]
			data	[sockdata!]
			bin		[red-binary!]
			msg		[red-object!]
			ret		[red-logic!]
			close?	[logic!]
			n		[integer!]
			acpt	[integer!]
			type	[integer!]
			saddr	[sockaddr_in! value]
			err		[integer!]
			_tm		[timespec! value]
			tm		[timespec!]
			red-port [red-object!]
			comm	[DATA-COMMON!]
			sym		[integer!]
			usbdata	[USB-DATA!]
			pNode				[INTERFACE-INFO-NODE!]
			rthread				[BARRIER-THREAD!]
			list				[list-entry!]
			input-report		[INPUT-REPORT!]
			buf					[byte-ptr!]
	][
		#if debug? = yes [print-line "poll/wait"]

		err: 0
		p: as poller! either null? ref [g-poller][ref]
		if null? p/events [
			p/nevents: 512
			p/events: as kevent! allocate p/nevents * size? kevent!
		]
		queue: p/ready-socks

		either timeout < 0 [
			tm: null
		][
			tm: :_tm
			tm/sec: timeout / 1000
			tm/nsec: timeout % 1000 * 1000000
		]

		forever [
			close?: no
			cnt: _kevent p/kqfd null 0 p/events p/nevents tm
			if cnt < 0 [return 0]

			if cnt = p/nevents [		;-- TBD: extend events buffer
				0
			]
?? cnt
			i: 0
			while [i < cnt][
				e: p/events + i
				comm: as DATA-COMMON! e/udata
				red-port: as red-object! :comm/cell
				sym: get-port-sym red-port
				if sym = words/tcp [
					data: as sockdata! e/udata
					msg: red-port
	probe ["code: " data/code " " as-integer e/ident " " e/filter and FFFFh " " e/filter >>> 16 ]
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
						SOCK_OP_WROTE		[
							i: i + 1
							continue
						]
						default				[probe ["wrong socket code: " data/code]]
					]
				]
				if sym = words/usb [
					usbdata: as USB-DATA! e/udata
					msg: red-port
					switch usbdata/code [
						SOCK_OP_ACCEPT	[
							;msg: create-red-port red-port data/accept
							type: IO_EVT_ACCEPT
						]
						SOCK_OP_CONN	[type: IO_EVT_CONNECT]
						SOCK_OP_READ	[
							pNode: usbdata/dev/interface
							rthread: as BARRIER-THREAD! pNode/read-thread
							list: rthread/list
							print-line "usb len:"
							either 0 = dlink/length? list [
								print-line 0
								bin: binary/load null 0
							][
								input-report: as INPUT-REPORT! dlink/remove-head list
								buf: as byte-ptr! (input-report + 1)
								either buf/1 = #"^(00)" [
									print-line input-report/length - 1
									bin: binary/load buf + 1 input-report/length - 1
								][
									print-line input-report/length
									bin: binary/load buf input-report/length
								]
								free as byte-ptr! input-report
							]
							copy-cell as cell! bin (object/get-values red-port) + port/field-data
							stack/pop 1
							type: IO_EVT_READ
						]
						SOCK_OP_WRITE	[type: IO_EVT_WROTE]
						SOCK_OP_READ_UDP	[0]
						SOCK_OP_WRITE_UDP	[0]
						default			[probe ["wrong sock code: " usbdata/code]]
					]
				]
				call-awake red-port msg type
				ret: as red-logic! stack/arguments
				if ret/value [close?: yes]
				i: i + 1
			]
			if close? [return 1]
		]
		0
	]
]