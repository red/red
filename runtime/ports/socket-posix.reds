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

#enum sock-op-code! [
	SOCK_OP_NONE
	SOCK_OP_ACCEPT
	SOCK_OP_CONN
	SOCK_OP_READ
	SOCK_OP_WRITE
	SOCK_OP_READ_UDP
	SOCK_OP_WRITE_UDP
]

sockdata!: alias struct! [
	cell	[cell! value]			;-- the port! cell
	sock	[integer!]				;-- the socket
	offset	[integer!]				;-- offset of the buffer
	buflen	[integer!]				;-- buffer length
	buffer	[node!]
	code	[integer!]				;-- operation code @@ change to uint8
	state	[integer!]				;-- @@ change to unit8
]

sock-readbuf: as byte-ptr! 0

socket: context [
	verbose: 1

	create-data: func [
		socket	[integer!]
		return: [sockdata!]
		/local
			data [sockdata!]
	][
		;@@ TBD get iocp-data from the cache first
		data: as sockdata! alloc0 size? sockdata!
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
		#if debug? = yes [if verbose > 0 [print-line "socket/bind"]]

		either type = AF_INET [		;-- IPv4
			p: htons port
			saddr/sin_family: p << 16 or type
			saddr/sin_addr: 0
			saddr/sa_data1: 0
			saddr/sa_data2: 0
			if 0 <> _bind sock as byte-ptr! :saddr size? saddr [
				probe "bind fail"
			]
			_listen sock 1024
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
			data [sockdata!]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/accept"]]

		data: as sockdata! sockdata/get sock
		if null? data [
			data: create-data sock
			sockdata/insert sock as int-ptr! data
		]
		copy-cell as cell! red-port as cell! :data/cell
		store-socket-data as int-ptr! data red-port

		data/code: SOCK_OP_ACCEPT
		poll/add g-poller sock EPOLLIN or EPOLLET as int-ptr! data
	]

	connect: func [
		red-port	[red-object!]
		sock		[integer!]
		addr		[c-string!]
		port		[integer!]
		type		[integer!]
		/local
			n		[integer!]
			data	[sockdata!]
			saddr	[sockaddr_in! value]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/connect"]]

		data: as sockdata! sockdata/get sock
		if null? data [
			data: create-data sock
			sockdata/insert sock as int-ptr! data
		]
		copy-cell as cell! red-port as cell! :data/cell
		store-socket-data as int-ptr! data red-port

		either type = AF_INET [		;-- IPv4
			port: htons port
			saddr/sin_family: port << 16 or type
			saddr/sin_addr: inet_addr addr
			saddr/sa_data1: 0
			saddr/sa_data2: 0
		][
			0
		]

		data/code: SOCK_OP_CONN
		either zero? _connect sock as int-ptr! :saddr size? saddr [	;-- succeed
			probe "connect OK"
		][
			poll/add g-poller sock EPOLLOUT as int-ptr! data
		]
	]

	write: func [
		red-port	[red-object!]
		data		[red-value!]
		/local
			bin		[red-binary!]
			pbuf	[byte-ptr!]
			len		[integer!]
			iodata	[sockdata!]
			n		[integer!]
	][
		iodata: as sockdata! get-socket-data red-port

		switch TYPE_OF(data) [
			TYPE_BINARY [
				bin: as red-binary! data
				len: binary/rs-length? bin
				pbuf: binary/rs-head bin
			]
			TYPE_STRING [0]
			default [0]
		]

		iodata/code: SOCK_OP_WRITE
		n: _send iodata/sock pbuf len 0
		either n = len [
			call-awake red-port red-port IO_EVT_WROTE
		][
			probe ["write wait: " n]
			0 ;poll/add g-poller so
		]
	]

	read: func [
		red-port	[red-object!]
		/local
			iodata	[sockdata!]
			n		[integer!]
			bin		[red-binary!]
	][
		iodata: as sockdata! get-socket-data red-port
		iodata/code: SOCK_OP_READ
		n: _recv iodata/sock sock-readbuf 1024 * 1024 0
		either n >= 0 [
			bin: binary/load sock-readbuf n
			copy-cell as cell! bin (object/get-values red-port) + port/field-data
			stack/pop 1
			call-awake red-port red-port IO_EVT_READ
		][
			probe "Socket read OK"		
		]
	]

	close: func [
		red-port	[red-object!]
		/local
			iodata	[sockdata!]
	][
		iodata: as sockdata! get-socket-data red-port
		_close iodata/sock
	]
]