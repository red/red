Red/System [
	Title:	"Socket implementation on POSIX"
	Author: "Xie Qingtian"
	File: 	%socket.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

sockdata!: alias struct! [
	iocp		[iocp-data! value]
	port		[red-object! value]		;-- red port! cell
	send-buf	[node!]					;-- send buffer
]

socket: context [
	verbose: 1

	set-nonblocking: func [
		fd			[integer!]
		return:		[integer!]
		/local
			flag	[integer!]
	][
		flag: fcntl [fd F_GETFL 0]
		either -1 = fcntl [fd F_SETFL flag or O_NONBLOCK] [-1][0]
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
		fd: LibC.socket family type protocal
		assert fd >= 0
		flag: fcntl [fd F_GETFL 0]
		fcntl [fd F_SETFL flag or O_NONBLOCK]
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
			LibC.bind sock as byte-ptr! :saddr size? saddr
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
		ret: LibC.listen sock backlog
		data/event: IO_EVT_ACCEPT
		data/state: EPOLLIN
		iocp/add data/io-port sock EPOLLIN or EPOLLET data
		ret
	]

	accept: func [
		sock		[integer!]
		return:		[integer!]
		/local
			n		[integer!]
			saddr	[sockaddr_in! value]
			acpt	[integer!]
	][
		n: size? sockaddr_in!
		acpt: libC.accept sock as byte-ptr! :saddr :n
		if acpt = -1 [return 0]
		socket/set-nonblocking acpt
		acpt
	]

	connect: func [
		sock		[integer!]
		addr		[c-string!]
		port		[integer!]
		type		[integer!]
		data		[iocp-data!]
		/local
			saddr	[sockaddr_in! value]
	][
		data/event: IO_EVT_CONNECT
		port: htons port
		saddr/sin_family: port << 16 or type
		saddr/sin_addr: inet_addr addr
		saddr/sa_data1: 0
		saddr/sa_data2: 0
		either zero? LibC.connect sock as int-ptr! :saddr size? saddr [
			iocp/post data/io-port data
		][
			data/state: EPOLLOUT
			iocp/add data/io-port sock EPOLLOUT or EPOLLET data
		]
	]

	write: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		/local
			n		[integer!]
			io-port	[iocp!]
			state	[integer!]
	][
		;#if debug? = yes [if verbose > 0 [print-line "socket/write"]]

probe ["socket/write/event: " data/event]

		if data/event and IO_EVT_WRITE = 1 [	;-- we need to use pending list
			iocp/add-pending data buffer length IO_EVT_WRITE
			exit
		]

		state: data/state
		data/event: data/event or IO_EVT_WRITE
		data/state: state and (not IO_STATE_WRITE_DONE) 

		n: LibC.send sock buffer length 0 

probe ["socket/write: " length " " n]

		io-port: data/io-port
		either n = length [
			data/state: state or IO_STATE_WRITE_DONE
			iocp/post io-port data
		][
			either zero? state [
				data/state: EPOLLOUT
				iocp/add io-port sock EPOLLOUT or EPOLLET data
			][
				if state and EPOLLOUT = 0 [
					data/state: state or EPOLLOUT or EPOLLET
					iocp/modify io-port sock data/state data
				]
			]
			if n < 0 [n: 0]
			data/write-buf: buffer + n
			data/write-buflen: length - n
		]
	]

	read: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		/local
			n		[integer!]
			state	[integer!]
	][
		assert data/event and IO_EVT_READ = 0
		if data/event and IO_EVT_READ = 1 [		;-- we need to use pending list
			iocp/add-pending data buffer length IO_EVT_READ
			exit
		]

		state: data/state
		data/event: data/event or IO_EVT_READ
		data/state: state and (not IO_STATE_READ_DONE) 
		n: LibC.recv sock buffer length 0
probe ["socket/read: " n]
		either n >= 0 [
			data/transferred: n
			data/state: state or IO_STATE_READ_DONE
			iocp/post data/io-port data
		][
			data/read-buf: buffer
			data/read-buflen: length
			either zero? state [
				data/state: EPOLLIN
				iocp/add data/io-port sock EPOLLIN or EPOLLET data
			][
				if state and EPOLLIN = 0 [
					data/state: state or EPOLLIN or EPOLLET
					iocp/modify data/io-port sock data/state data
				]
			]
		]
	]

	close: func [
		sock	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/close"]]

		LibC.close sock
	]
]