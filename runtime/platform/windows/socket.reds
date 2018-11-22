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
			-1
		][							;-- IPv6
			0
		]
	]

	accept: func [
		red-port [red-port!]
		sock	 [integer!]
		acpt	 [integer!]
		/local
			n	 [integer!]
			data [iocp-data!]
			AcceptEx [AcceptEx!]
	][
		data: as iocp-data! sockdata/get sock
		if null? data [
			data: iocp/create-data sock
			sockdata/insert sock as int-ptr! data
		]
		copy-cell as cell! red-port as cell! :data/cell
		iocp/bind g-poller data

		set-memory as byte-ptr! data null-byte size? OVERLAPPED!
		if null? data/buffer [		;-- make address buffer
			data/buffer: alloc0 128
		]

		n: 0
		data/accept: acpt
		AcceptEx: as AcceptEx! AcceptEx-func
		if AcceptEx sock acpt data/buffer 0 128 128 :n as int-ptr! data [
			probe "Accept done"
			
		]
	]

	connect: func [
		sock	[integer!]
		addr	[c-string!]
		port	[integer!]
		type	[integer!]
	][
		
	]
]