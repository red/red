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

iocp-data!: alias struct! [
	ovlap	[OVERLAPPED value]		;-- the overlapped struct
	cell	[red-value! value]		;-- the port! cell
	port	[int-ptr!]				;-- the bound iocp port
	sock	[int-ptr!]				;-- the socket
	accept	[int-ptr!]				;-- the accept socket
	buffer	[byte-ptr!]				;-- buffer for iocp poller
	code	[integer!]				;-- operation code @@ change to uint8
	state	[integer!]				;-- @@ change to unit8
]

poller!: alias struct! [
	maxn	[integer!]
	port	[int-ptr!]
	events	[OVERLAPPED_ENTRY]
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
		data: alloc0 size? iocp-data!
		data/sock: sock
		data
	]

	bind: func [
		p		[int-ptr!]
		data	[iocp-data!]
		/local
			pp		[poller!]
			port	[integer!]
	][
		pp: as poller! p
		port: CreateIoCompletionPort data/sock pp/port null 0
		if port <> pp/port [
			probe "iocp bind error"
		]
		data/port: port
	]
]

poller: context [
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

	

	poll: func [
		ref			[int-ptr!]
		poller-func	[int-ptr!]
		timeout		[integer!]
		return:		[integer!]
		/local
			p		[poller!]
			res		[integer!]
			cnt		[integer!]
			err		[integer!]
			i		[integer!]
			e		[OVERLAPPED_ENTRY]
			data	[iocp-data!]
	][
		p: as poller! ref
		if null? p/events [
			p/evt-cnt: 512
			p/events: as OVERLAPPED_ENTRY allocate p/evt-cnt * size? OVERLAPPED_ENTRY
		]

		cnt: 0
		res: GetQueuedCompletionStatusEx p/port p/events p/evt-cnt :cnt timeout

		err: GetLastError
		if all [res <> 0 err = WAIT_TIMEOUT][return 0]

		if cnt = p/evt-cnt [			;-- extend events buffer
			0
		]

		i: 0
		while [i < cnt][
			e: p/events + i
			data: as iocp-data! e/lpOverlapped
			
			i: i + 1
		]
	]
]