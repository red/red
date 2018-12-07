Red/System [
	Title:	"Socket implementation on POSIX"
	Author: "Xie Qingtian"
	File: 	%socket.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

socket-data!: alias struct! [
	cell	[cell! value]			;-- the port! cell
	sock	[integer!]				;-- the socket
	buflen	[integer!]				;-- buffer length
	buffer	[byte-ptr!]				;-- buffer for iocp poller
	code	[integer!]				;-- operation code @@ change to uint8
	state	[integer!]				;-- @@ change to unit8
]

socket: context [

	create-data: func [
		socket	[integer!]
		return: [socket-data!]
		/local
			data [socket-data!]
	][
		;@@ TBD get iocp-data from the cache first
		data: as socket-data! alloc0 size? socket-data!
		data/sock: socket
		data
	]

	create: func [
		family		[integer!]
		type		[integer!]
		protocal	[integer!]
		return:		[integer!]
		/local
			fd		[integer!]
			flag	[integer!]
	][
		fd: _socket family type protocal
		flag: fcntl [fd F_GETFL 0]
		fcntl [fd F_SETFL flag or O_NONBLOCK]
		assert fd >= 0
		fd
	]

	bind: func [
		sock	[integer!]
		port	[integer!]
		type	[integer!]
		return: [integer!]
		/local
			saddr	[sockaddr_in! value]
			p		[integer!]
	][
		either type = AF_INET [		;-- IPv4
			p: htons port
			saddr/sin_family: p << 16 or type
			saddr/sin_addr: 0
			saddr/sa_data1: 0
			saddr/sa_data2: 0
			if 0 <> _bind sock as int-ptr! :saddr size? saddr [
				probe "bind fail"
			]
			listen sock 1024
			0
		][							;-- IPv6
			0
		]
	]

	accept: func [
		red-port [red-object!]
		sock	 [integer!]
		acpt	 [integer!]
		/local
			n	[integer!]
			evt	[epoll_event! value]
	][
		data: as iocp-data! sockdata/get sock
		if null? data [
			data: create-data sock
			sockdata/insert sock as int-ptr! data
		]
		copy-cell as cell! red-port as cell! :data/cell
		store-socket-data as int-ptr! data red-port

		evt/events: EPOLLIN | EPOLLET
		poll/add g-poller EPOLL_CTL_ADD sock 
		n: 0
		data/code: IOCP_OP_ACCEPT
	]

	connect: func [
		red-port	[red-object!]
		sock		[integer!]
		addr		[c-string!]
		port		[integer!]
		type		[integer!]
		/local
			n		[integer!]
			data	[iocp-data!]
			saddr	[sockaddr_in! value]
			ConnectEx [ConnectEx!]
	][
		data: as iocp-data! sockdata/get sock
		if null? data [
			data: iocp/create-data sock
			sockdata/insert sock as int-ptr! data
		]
		copy-cell as cell! red-port as cell! :data/cell
		store-iocp-data data red-port
		iocp/bind g-poller data

		set-memory as byte-ptr! data null-byte size? OVERLAPPED!

		either type = AF_INET [		;-- IPv4
			saddr/sin_family: type
			saddr/sin_addr: 0
			saddr/sa_data1: 0
			saddr/sa_data2: 0
			if 0 <> _bind sock as int-ptr! :saddr size? saddr [
				probe "bind fail in connect"
			]
		][
			0
		]

		data/code: IOCP_OP_CONN
		n: 0
		port: htons port
		saddr/sin_family: port << 16 or type
		saddr/sin_addr: inet_addr addr
		ConnectEx: as ConnectEx! ConnectEx-func
		unless ConnectEx sock as int-ptr! :saddr size? saddr null 0 :n as int-ptr! data [
			exit
		]

		probe "Connect ok"

		;-- do not post the completion notification as we're processing it now
		SetFileCompletionNotificationModes as int-ptr! sock 1
		call-awake red-port red-port IO_EVT_ACCEPT
	]

	write: func [
		red-port	[red-object!]
		data		[red-value!]
		/local
			bin		[red-binary!]
			pbuf	[WSABUF! value]
			iodata	[iocp-data!]
			n		[integer!]
	][
		iodata: get-iocp-data red-port
		iocp/bind g-poller iodata

		switch TYPE_OF(data) [
			TYPE_BINARY [
				bin: as red-binary! data
				pbuf/len: binary/rs-length? bin
				pbuf/buf: binary/rs-head bin
			]
			TYPE_STRING [0]
			default [0]
		]

		iodata/code: IOCP_OP_WRITE
		n: 0
		if 0 <> WSASend iodata/sock :pbuf 1 :n 0 as OVERLAPPED! iodata null [
			exit
		]

		probe "Socket Write OK"
	]

	read: func [
		red-port	[red-object!]
		/local
			iodata	[iocp-data!]
			pbuf	[WSABUF!]
			n		[integer!]
			flags	[integer!]
	][
		iodata: get-iocp-data red-port
		pbuf: as WSABUF! :iodata/buflen
		if null? pbuf/buf [
			pbuf/len: 1024 * 1024
			pbuf/buf: allocate 1024 * 1024
		]
		iocp/bind g-poller iodata

		iodata/code: IOCP_OP_READ
		n: 0
		flags: 0
		if 0 <> WSARecv iodata/sock pbuf 1 :n :flags as OVERLAPPED! iodata null [
			exit
		]
		probe "Socket read OK"
	]

	close: func [
		red-port	[red-object!]
		/local
			iodata	[iocp-data!]
	][
		iodata: get-iocp-data red-port
		if iodata/buffer <> null [
			free iodata/buffer
			iodata/buffer: null
		]
		closesocket iodata/sock
	]
]