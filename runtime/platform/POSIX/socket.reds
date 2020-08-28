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

	send: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		return:		[integer!]
		/local
			n		[integer!]
			io-port	[iocp!]
			state	[integer!]
	][
		;#if debug? = yes [if verbose > 0 [print-line "socket/send"]]

		state: data/state
		if state and IO_STATE_PENDING_WRITE = IO_STATE_PENDING_WRITE [
			iocp/add-pending data buffer length IO_EVT_WRITE
			return -1
		]

		data/write-buf: buffer
		data/write-buflen: length
		n: iocp/write-io data

		io-port: data/io-port
		either n = length [
			data/event: IO_EVT_WRITE
			iocp/post io-port data
		][
			case [
				zero? state [
					data/state: IO_STATE_PENDING_WRITE
					iocp/add io-port sock EPOLLOUT or EPOLLET data
				]
				state and EPOLLOUT = 0 [
					data/state: state or IO_STATE_PENDING_WRITE
					iocp/modify io-port sock EPOLLIN or EPOLLOUT or EPOLLET data
				]
				true [data/state: state or IO_STATE_WRITING]
			]
			if n < 0 [n: 0]
			data/write-buf: buffer + n
			data/write-buflen: length - n
		]
		n
	]

	recv: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
		return:		[integer!]
		/local
			n		[integer!]
			state	[integer!]
	][
		state: data/state
		if state and IO_STATE_PENDING_READ = IO_STATE_PENDING_READ [
			iocp/add-pending data buffer length IO_EVT_READ
			return -1
		]

		data/read-buf: buffer
		data/read-buflen: length
		n: iocp/read-io data

		case [
			n > 0 [
				data/event: IO_EVT_READ
				data/transferred: n
				iocp/post data/io-port data
			]
			n < 0 [
				data/read-buf: buffer
				data/read-buflen: length
				case [
					zero? state [
						data/state: IO_STATE_PENDING_READ
						iocp/add data/io-port sock EPOLLIN or EPOLLET data
					]
					state and EPOLLIN = 0 [
						data/state: state or IO_STATE_PENDING_READ
						iocp/modify data/io-port sock EPOLLIN or EPOLLOUT or EPOLLET data
					]
					true [data/state: state or IO_STATE_READING]
				]
			]
			zero? n [
				data/transferred: 0
				data/event: IO_EVT_CLOSE
				iocp/post data/io-port data
			]
		]
		n
	]

	usend: func [	;-- for UDP
		sock		[integer!]
		addr		[sockaddr_in6!]
		addr-sz		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[iocp-data!]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/usend"]]
		libC.sendto sock buffer length 0 addr addr-sz
	]

	urecv: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		addr		[sockaddr_in6!]
		addr-sz		[int-ptr!]
		data		[sockdata!]
	][

	]

	set-option: func [
		fd			[integer!]
		name		[integer!]
		value		[integer!]
	][
		setsockopt fd SOL_SOCKET name as c-string! :value size? integer!
	]

	close: func [
		sock	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "socket/close"]]
print-line "socket/close"
		LibC.close sock
print-line "socket/close done"
	]
]