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
	verbose: 1

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
	][
		either type = AF_INET [		;-- IPv4
			p: htons port
			saddr/sin_family: p << 16 or type
			saddr/sin_addr: 0
			saddr/sa_data1: 0
			saddr/sa_data2: 0
			WS2.bind sock as int-ptr! :saddr size? saddr
		][							;-- IPv6
			0
		]
	]

	listen: func [
		sock	[integer!]
		backlog	[integer!]
		return:	[integer!]
	][
		WS2.listen sock backlog
	]

	accept: func [
		sock	 [integer!]
		data	 [iocp-data!]
		/local
			n		 [integer!]
			AcceptEx [AcceptEx!]
	][
		if null? data/accept-addr [		;-- make address buffer
			data/accept-addr: alloc0 256
		]

		n: 0
		data/event: SOCK_EVT_ACCEPT
		data/accept-sock: create AF_INET SOCK_STREAM IPPROTO_TCP

		AcceptEx: as AcceptEx! AcceptEx-func
		AcceptEx sock data/accept-sock data/accept-addr 0 128 128 :n as int-ptr! data
	]

	connect: func [
		sock		[integer!]
		addr		[c-string!]
		port		[integer!]
		type		[integer!]
		data		[iocp-data!]
		/local
			n		[integer!]
			saddr	[sockaddr_in! value]
			ConnectEx [ConnectEx!]
	][
		data/event: SOCK_EVT_CONNECT
		n: 0
		port: htons port
		saddr/sin_family: port << 16 or type
		saddr/sin_addr: inet_addr addr
		saddr/sa_data1: 0
		saddr/sa_data2: 0
		ConnectEx: as ConnectEx! ConnectEx-func
		ConnectEx sock as int-ptr! :saddr size? saddr null 0 :n as int-ptr! data
	]

	write: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		/local
			wsbuf	[WSABUF! value]
			n		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/write"]]

		wsbuf/len: length
		wsbuf/buf: buffer
		data/event: SOCK_EVT_WRITE
		n: 0
		WSASend sock :wsbuf 1 :n 0 as OVERLAPPED! data null
	]

	read: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		/local
			wsbuf	[WSABUF! value]
			n		[integer!]
			flags	[integer!]
	][
		wsbuf/len: length
		wsbuf/buf: buffer
		data/event: SOCK_EVT_READ
		n: 0
		flags: 0
		if 0 <> WSARecv sock :wsbuf 1 :n :flags as OVERLAPPED! data null [
			exit
		]
	]

	close: func [
		sock	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/close"]]

		closesocket sock
	]
]