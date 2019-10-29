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

#define PENDING_IO_FLAG		1

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
		data	[iocp-data!]
		return:	[integer!]
		/local
			ret	[integer!]
	][
		ret: WS2.listen sock backlog
		if zero? ret [acceptex sock data]
		ret
	]

	acceptex: func [
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
		data/event: IO_EVT_ACCEPT
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
			ret		[integer!]
			saddr	[sockaddr_in! value]
			ConnectEx [ConnectEx!]
	][
		data/event: IO_EVT_CONNECT
		n: 0
		port: htons port
		saddr/sin_family: port << 16 or type
		saddr/sin_addr: inet_addr addr
		saddr/sa_data1: 0
		saddr/sa_data2: 0
		ConnectEx: as ConnectEx! ConnectEx-func
		ret: ConnectEx sock as int-ptr! :saddr size? saddr null 0 :n as int-ptr! data	
	]

	uconnect: func [
		sock		[integer!]
		addr		[c-string!]
		port		[integer!]
		type		[integer!]
		/local
			n		[integer!]
			ret		[integer!]
			saddr	[sockaddr_in! value]
	][
		n: 0
		port: htons port
		saddr/sin_family: port << 16 or type
		saddr/sin_addr: inet_addr addr
		saddr/sa_data1: 0
		saddr/sa_data2: 0
		ret: WSAConnect sock :saddr size? saddr null null null null
	]
	
	send: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		return:		[integer!]
		/local
			wsbuf	[WSABUF! value]
			err		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/write"]]

		wsbuf/len: length
		wsbuf/buf: buffer
		data/event: IO_EVT_WRITE

		unless zero? WSASend sock :wsbuf 1 null 0 as OVERLAPPED! data null [	;-- error
			err: GetLastError
			?? err
			either ERROR_IO_PENDING = err [return ERROR_IO_PENDING][return -1]
		]
		0
	]

	recv: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		return:		[integer!]
		/local
			wsbuf	[WSABUF! value]
			flags	[integer!]
	][
		wsbuf/len: length
		wsbuf/buf: buffer
		data/event: IO_EVT_READ
		flags: 0
		WSARecv sock :wsbuf 1 null :flags as OVERLAPPED! data null
	]

	usend: func [	;-- for UDP
		sock		[integer!]
		addr		[sockaddr_in6!]
		addr-sz		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		/local
			wsbuf	[WSABUF! value]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/write"]]

		wsbuf/len: length
		wsbuf/buf: buffer
		data/event: IO_EVT_WRITE
		WSASendTo sock :wsbuf 1 null 0 addr addr-sz as OVERLAPPED! data null
	]

	urecv: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		addr		[sockaddr_in6!]
		addr-sz		[int-ptr!]
		data		[sockdata!]
		/local
			wsbuf	[WSABUF! value]
			res		[integer!]
	][
		wsbuf/len: length
		wsbuf/buf: buffer
		data/iocp/event: IO_EVT_READ
		?? addr
		probe addr-sz/value
		res: WSARecvFrom sock :wsbuf 1 null :data/flags addr addr-sz as OVERLAPPED! data null
		?? res
		if res <> 0 [
			res: GetLastError
			?? res
		]
	]

	set-option: func [
		fd			[integer!]
		name		[integer!]
		value		[integer!]
	][
		probe "set-option"
		probe setsockopt fd SOL_SOCKET name as c-string! :value size? integer!
	]

	close: func [
		sock	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/close"]]

		closesocket sock
	]
]