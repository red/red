Red/System [
	Title:	"IOCP on Windows"
	Author: "Xie Qingtian"
	File: 	%iocp.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define IO_STATE_TLS_DONE		1000h
#define IO_STATE_CLIENT			2000h
#define IO_STATE_READING		4000h
#define IO_STATE_WRITING		8000h

iocp-event-handler!: alias function! [
	data		[int-ptr!]
]

iocp!: alias struct! [
	maxn	[integer!]
	port	[int-ptr!]
	events	[OVERLAPPED_ENTRY!]
	evt-cnt [integer!]
]

#define IOCP_DATA_FIELDS [
	Internal		[int-ptr!]				;-- inline OVERLAPPED struct begin
	InternalHigh	[int-ptr!]
	Offset			[integer!]				;-- or Pointer [int-ptr!]
	OffsetHigh		[integer!]
	hEvent			[int-ptr!]				;-- inline OVERLAPPED struct end
	;--
	device			[handle!]				;-- device handle
	event-handler	[iocp-event-handler!]
	event			[integer!]
	type			[integer!]				;-- TCP, UDP, TLS, etc
	state			[integer!]
	transferred		[integer!]				;-- number of bytes transferred
	accept-sock		[integer!]
	accept-addr		[byte-ptr!]	
]

iocp-data!: alias struct! [
	IOCP_DATA_FIELDS
]

sockdata!: alias struct! [
	iocp		[iocp-data! value]
	port		[red-object! value]		;-- red port! cell
	flags		[integer!]
	send-buf	[node!]					;-- send buffer
	addrinfo	[int-ptr!]
]

udp-data!: alias struct! [
	iocp		[iocp-data! value]
	port		[red-object! value]		;-- red port! cell
	flags		[integer!]
	send-buf	[node!]					;-- send buffer
	addr		[sockaddr_in6! value]	;-- IPv4 or IPv6 address
	addr-sz		[integer!]
]

dns-data!: alias struct! [
	IOCP_DATA_FIELDS
	port		[red-object! value]		;-- red port! cell
	flags		[integer!]
	send-buf	[node!]
	addr		[sockaddr_in6! value]	;-- IPv4 or IPv6 address
	addr-sz		[integer!]
	addrinfo	[int-ptr!]
]

file-data!: alias struct! [
	IOCP_DATA_FIELDS
	port		[red-object! value]		;-- red port! cell
	flags		[integer!]
	buffer		[node!]					;-- buffer node!
]

iocp: context [
	verbose: 0

	create: func [
		return: [iocp!]
		/local
			p	[iocp!]
	][
		p: as iocp! alloc0 size? iocp!
		p/maxn: 65536
		p/port: CreateIoCompletionPort INVALID_HANDLE null null 0
		assert p/port <> INVALID_HANDLE
		p
	]

	close: func [
		p [iocp!]
	][
		#if debug? = yes [print-line "iocp/close"]

		CloseHandle p/port
		p/port: null
		if p/events <> null [
			free as byte-ptr! p/events
			p/events: null
		]
		free as byte-ptr! p
	]

	post: func [
		p		[iocp!]
		data	[iocp-data!]
		return:	[logic!]
	][
		0 <> PostQueuedCompletionStatus p/port data/transferred null as OVERLAPPED! data
	]

	bind: func [
		"bind a device handle to the I/O completion port"
		p		[iocp!]
		handle	[int-ptr!]
		/local
			port [int-ptr!]
	][
		port: CreateIoCompletionPort handle p/port null 0
		if port <> p/port [
			probe "iocp bind error"
		]
	]

	wait: func [
		"wait I/O completion events and dispatch them"
		p			[iocp!]
		timeout		[integer!]			;-- time in ms, -1: infinite
		return:		[integer!]
		/local
			res		[integer!]
			cnt		[integer!]
			err		[integer!]
			i		[integer!]
			e		[OVERLAPPED_ENTRY!]
			data	[iocp-data!]
			evt		[integer!]
	][
		if null? p/events [
			p/evt-cnt: 512
			p/events: as OVERLAPPED_ENTRY! allocate p/evt-cnt * size? OVERLAPPED_ENTRY!
		]

		cnt: 0
		res: GetQueuedCompletionStatusEx p/port p/events p/evt-cnt :cnt timeout no
		if zero? res [
			err: GetLastError
			return 0
		]

		if cnt = p/evt-cnt [			;-- TBD: extend events buffer
			0
		]

		i: 0
?? cnt
		while [i < cnt][
			e: p/events + i
			data: as iocp-data! e/lpOverlapped
			data/transferred: e/dwNumberOfBytesTransferred
			
probe [data " " data/event " " data/type " " data/state " "]

			evt: data/event

			switch data/type [
				IOCP_TYPE_DNS [
					switch evt [
						IO_EVT_WRITE [
							dns/recv as dns-data! data
							i: i + 1
							continue
						]
						IO_EVT_READ [
							either dns/parse-data as dns-data! data [
								data/event: IO_EVT_LOOKUP
							][
								i: i + 1
								continue
							]
						]
						default [0]
					]
				]
				IOCP_TYPE_TLS [
					either data/state and IO_STATE_TLS_DONE <> 0 [
						switch evt [
							IO_EVT_READ [
								unless tls/decode as tls-data! data [
									i: i + 1
									continue
								]
							]
							IO_EVT_WRITE [
								0
							]
							default [0]
						]
					][
						if all [
							evt <> IO_EVT_ACCEPT
							not tls/negotiate as tls-data! data
						][
							i: i + 1
							continue
						]
					]
				]
				default [0]
			]

			if evt > 0 [data/event-handler as int-ptr! data]
			i: i + 1
		]
		1
	]
]