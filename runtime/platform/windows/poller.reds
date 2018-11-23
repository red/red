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

g-poller: as int-ptr! 0

#enum iocp-op-code! [
	IOCP_OP_NONE
	IOCP_OP_ACCEPT
	IOCP_OP_CONN
	IOCP_OP_READ
	IOCP_OP_WRITE
	IOCP_OP_READ_UDP
	IOCP_OP_WRITE_UDP
]

iocp-data!: alias struct! [
	ovlap	[OVERLAPPED! value]		;-- the overlapped struct
	cell	[cell! value]			;-- the port! cell
	port	[int-ptr!]				;-- the bound iocp port
	sock	[integer!]				;-- the socket
	accept	[integer!]				;-- the accept socket
	buffer	[byte-ptr!]				;-- buffer for iocp poller
	code	[integer!]				;-- operation code @@ change to uint8
	state	[integer!]				;-- @@ change to unit8
]

poller!: alias struct! [
	maxn	[integer!]
	port	[int-ptr!]
	events	[OVERLAPPED_ENTRY!]
	evt-cnt [integer!]
]

iocp: context [
	create-data: func [
		sock	[integer!]
		return: [iocp-data!]
		/local
			data [iocp-data!]
	][
		;@@ TBD get iocp-data from the cache first
		data: as iocp-data! alloc0 size? iocp-data!
		data/sock: sock
		data
	]

	bind: func [
		p		[int-ptr!]
		data	[iocp-data!]
		/local
			poller	[poller!]
			port	[int-ptr!]
	][
		poller: as poller! p
		port: CreateIoCompletionPort as int-ptr! data/sock poller/port null 0
		if port <> poller/port [
			probe "iocp bind error"
		]
		data/port: port
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
			data	[iocp-data!]
	][
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
			switch data/code [
				IOCP_OP_ACCEPT []
				default [probe ["operation " data/code]]
			]
			i: i + 1
		]
		0
	]
]