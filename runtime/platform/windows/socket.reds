Red/System [
	Title:	"Socket implementation on Windows"
	Author: "Xie Qingtian"
	File: 	%socket.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define AF_INET6	23

store-iocp-data: func [
	data		[iocp-data!]
	red-port	[red-object!]
	/local
		values	 [red-value!]
		state	 [red-object!]	 
][
	values: object/get-values red-port
	state: as red-object! values + port/field-state
	integer/make-at (object/get-values state) + 1 as-integer data
]

create-red-port: func [
	sock		[integer!]
	return:		[red-object!]
	/local
		p		[red-object!]
		data	[iocp-data!]
][
	data: iocp/create-data sock
	sockdata/insert sock as int-ptr! data
	p: port/make none-value stack/push* TYPE_NONE
	store-iocp-data data p
	p
]

socket: context [

	create: func [
		family		[integer!]
		type		[integer!]
		protocal	[integer!]
		return:		[integer!]
		/local
			fd		[integer!]
	][
		fd: WSASocketW family type protocal null 0 1		;-- OVERLAPPED
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
			a		[integer!]
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
			n		 [integer!]
			data	 [iocp-data!]
			AcceptEx [AcceptEx!]
	][
		data: as iocp-data! sockdata/get sock
		if null? data [
			data: iocp/create-data sock
			sockdata/insert sock as int-ptr! data
		]

		store-iocp-data data red-port

		copy-cell as cell! red-port as cell! :data/cell
		iocp/bind g-poller data

		set-memory as byte-ptr! data null-byte size? OVERLAPPED!
		if null? data/buffer [		;-- make address buffer
			data/buffer: alloc0 128
		]

		n: 0
		data/code: IOCP_OP_ACCEPT
		data/accept: acpt
		AcceptEx: as AcceptEx! AcceptEx-func
		unless AcceptEx sock acpt data/buffer 0 128 128 :n as int-ptr! data [
			;-- not ready yet, check it later in poll
			exit
		]
		probe "Accept ok"

		;-- do not post the completion notification as we're processing it now
		SetFileCompletionNotificationModes as int-ptr! acpt 1

		n: 1
		ioctlsocket acpt FIONBIO :n
		n: 1
		setsockopt acpt IPPROTO_TCP 1 as c-string! :n size? n		;-- TCP_NODELAY: 1

		
	]

	connect: func [
		sock	[integer!]
		addr	[c-string!]
		port	[integer!]
		type	[integer!]
	][
		
	]
]