Red/System [
	Title:	"A Poller using IOCP on Windows"
	Author: "Xie Qingtian"
	File: 	%poller.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum iocp-op-code! [
	IOCP_OP_NONE
	IOCP_OP_ACCEPT
	IOCP_OP_CONN
	IOCP_OP_READ
	IOCP_OP_WRITE
	IOCP_OP_READ_UDP
	IOCP_OP_WRITE_UDP
]

poller!: alias struct! [
	maxn	[integer!]
	port	[int-ptr!]
	events	[OVERLAPPED_ENTRY!]
	evt-cnt [integer!]
]

iocp: context [

	bind: func [
		p		[int-ptr!]
		data	[sockdata!]
		/local
			poller	[poller!]
			port	[int-ptr!]
	][
		poller: as poller! p
		if null? data/port [
			port: CreateIoCompletionPort as int-ptr! data/sock poller/port null 0
			if port <> poller/port [
				probe "iocp bind error"
			]
			data/port: port
		]
	]
]

poll: context [
	init: func [
		return: [int-ptr!]
		/local
			p	[poller!]
	][
		p: as poller! alloc0 size? poller!
		p/maxn: 65536
		p/port: CreateIoCompletionPort INVALID_HANDLE null null 0
		assert p/port <> INVALID_HANDLE

		sockdata/init

		as int-ptr! p
	]

	exit: func [
		ref		[int-ptr!]
		/local
			p	[poller!]
	][
		p: as poller! ref
		CloseHandle p/port
		if p/events <> null [
			free as byte-ptr! p/events
		]
		free as byte-ptr! p
	]

	kill: func [][]

	insert: func [
		ref		[int-ptr!]
		sock	[int-ptr!]
		events	[integer!]
		data	[int-ptr!]
	][
		
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
			data	[sockdata!]
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
				data: as sockdata! e/lpOverlapped
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