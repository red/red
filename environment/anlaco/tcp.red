Red [
	Title:   "TCP Client for Red"
	Author:  "ANLACO"
	File: 	 %tcp.red
	Tabs:	 4
	Rights:  "Copyright (C) 2026 ANLACO. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Version: 0.2.6
	Notes: {
		Simple TCP client implementation using OS-level bindings.
		Non-blocking I/O cooperative, single-connection.
		Linux and Windows. macOS pending (v1.x+).
	}
]

tcp: context [
	INVALID_SOCKET: -1
	connected?: false

	#system [
		#either OS = 'Windows [
			#import [
				"ws2_32.dll" stdcall [
					WSAStartup: "WSAStartup" [
						version     [integer!]
						wsadata     [byte-ptr!]
						return:     [integer!]
					]
					WSACleanup: "WSACleanup" [
						return:     [integer!]
					]
					tcp-socket-func: "socket" [
						af          [integer!]
						type        [integer!]
						protocol    [integer!]
						return:     [integer!]
					]
					tcp-connect-func: "connect" [
						s           [integer!]
						name        [byte-ptr!]
						namelen     [integer!]
						return:     [integer!]
					]
					tcp-send-func: "send" [
						s           [integer!]
						buf         [byte-ptr!]
						len         [integer!]
						flags       [integer!]
						return:     [integer!]
					]
					tcp-recv-func: "recv" [
						s           [integer!]
						buf         [byte-ptr!]
						len         [integer!]
						flags       [integer!]
						return:     [integer!]
					]
					closesocket: "closesocket" [
						s           [integer!]
						return:     [integer!]
					]
					tcp-inet-addr: "inet_addr" [
						cp          [c-string!]
						return:     [integer!]
					]
					tcp-gethostbyname: "gethostbyname" [
						name        [c-string!]
						return:     [int-ptr!]
					]
					tcp-htons: "htons" [
						hostshort   [integer!]
						return:     [integer!]
					]
					ioctlsocket: "ioctlsocket" [
						s           [integer!]
						cmd         [integer!]
						argp        [int-ptr!]
						return:     [integer!]
					]
					WSAPoll: "WSAPoll" [
						fds         [byte-ptr!]
						nfds        [integer!]
						timeout     [integer!]
						return:     [integer!]
					]
					WSAGetLastError: "WSAGetLastError" [
						return:     [integer!]
					]
					tcp-setsockopt: "setsockopt" [
						s           [integer!]
						level       [integer!]
						optname     [integer!]
						optval      [byte-ptr!]
						optlen      [integer!]
						return:     [integer!]
					]
				]
			]

			#define AF_INET         2
			#define SOCK_STREAM     1
			#define IPPROTO_TCP     6
			#define INVALID_SOCKET  -1
			#define SOCKET_ERROR    -1
			#define FIONBIO         2147772030
			#define WSAEWOULDBLOCK  10035
			#define SOL_SOCKET      65535
			#define SO_RCVTIMEO     4102
			#define SO_SNDTIMEO     4101
			#define POLLRDNORM      256
		][
			#import [
				LIBC-file cdecl [
					tcp-socket-func: "socket" [
						domain      [integer!]
						type        [integer!]
						protocol    [integer!]
						return:     [integer!]
					]
					tcp-connect-func: "connect" [
						sockfd      [integer!]
						addr        [byte-ptr!]
						addrlen     [integer!]
						return:     [integer!]
					]
					tcp-send-func: "send" [
						sockfd      [integer!]
						buf         [byte-ptr!]
						len         [integer!]
						flags       [integer!]
						return:     [integer!]
					]
					tcp-recv-func: "recv" [
						sockfd      [integer!]
						buf         [byte-ptr!]
						len         [integer!]
						flags       [integer!]
						return:     [integer!]
					]
					tcp-close-func: "close" [
						fd          [integer!]
						return:     [integer!]
					]
					tcp-inet-addr: "inet_addr" [
						cp          [c-string!]
						return:     [integer!]
					]
					tcp-gethostbyname: "gethostbyname" [
						name        [c-string!]
						return:     [int-ptr!]
					]
					tcp-htons: "htons" [
						hostshort   [integer!]
						return:     [integer!]
					]
					tcp-setsockopt: "setsockopt" [
						sockfd      [integer!]
						level       [integer!]
						optname     [integer!]
						optval      [byte-ptr!]
						optlen      [integer!]
						return:     [integer!]
					]
					tcp-fcntl: "fcntl" [
						[variadic]
						return:     [integer!]
					]
					tcp-poll-func: "poll" [
						fds         [byte-ptr!]
						nfds        [integer!]
						timeout     [integer!]
						return:     [integer!]
					]
				]
			]

			#define AF_INET         2
			#define SOCK_STREAM     1
			#define IPPROTO_TCP     6
			#define INVALID_SOCKET  -1
			#define SOCKET_ERROR    -1
			#define TCP_EWOULDBLOCK 11
			#define SOL_SOCKET      1
			#define SO_RCVTIMEO     20
			#define SO_SNDTIMEO     21
			#define TCP_POLLIN      0001h
			#define TCP_O_NONBLOCK  2048
			#define TCP_F_GETFL     3
			#define TCP_F_SETFL     4
		]

		tcp-pollfd!: alias struct! [
			fd		[integer!]
			events	[integer!]
		]

		hostent!: alias struct! [
			h_name      [int-ptr!]
			h_aliases   [int-ptr!]
			h_addrtype  [integer!]
			h_length    [integer!]
			h_addr_list [int-ptr!]
		]

		tcp-socket: 0
		tcp-errno:  0

		sys-init: func [
			return: [logic!]
			/local
				wsadata [byte-ptr!]
		][
			#either OS = 'Windows [
				wsadata: allocate 400
				if SOCKET_ERROR = WSAStartup 0202h wsadata [
					free wsadata
					return false
				]
				free wsadata
			][]
			true
		]

		sys-cleanup: func [][
			#either OS = 'Windows [
				WSACleanup
			][]
		]

		sys-connect: func [
			host        [c-string!]
			port        [integer!]
			return:     [integer!]
			/local
				sock        [integer!]
				addr        [byte-ptr!]
				ip          [integer!]
				he          [hostent!]
				ip-ptr      [int-ptr!]
				ip-addr-ptr [int-ptr!]
				addr-list   [int-ptr!]
				port-val    [integer!]
		][
			sock: tcp-socket-func AF_INET SOCK_STREAM IPPROTO_TCP
			if sock = INVALID_SOCKET [return INVALID_SOCKET]

			addr: allocate 16
			set-memory addr as byte! 0 16

			addr/1: as byte! (AF_INET and FFh)
			addr/2: as byte! 0

			port-val: tcp-htons port
			addr/3: as byte! (port-val and FFh)
			addr/4: as byte! ((port-val >> 8) and FFh)

			ip: tcp-inet-addr host
			either ip <> -1 [
				ip-ptr: as int-ptr! (addr + 4)
				ip-ptr/value: ip
			][
				he: as hostent! tcp-gethostbyname host
				if he = null [
					free addr
					#either OS = 'Windows [closesocket sock][tcp-close-func sock]
					return INVALID_SOCKET
				]

				addr-list: he/h_addr_list
				if addr-list = null [
					free addr
					#either OS = 'Windows [closesocket sock][tcp-close-func sock]
					return INVALID_SOCKET
				]

				ip-addr-ptr: as int-ptr! addr-list/value
				if ip-addr-ptr = null [
					free addr
					#either OS = 'Windows [closesocket sock][tcp-close-func sock]
					return INVALID_SOCKET
				]

				ip-ptr: as int-ptr! (addr + 4)
				ip-ptr/value: ip-addr-ptr/value
			]

			if SOCKET_ERROR = tcp-connect-func sock addr 16 [
				free addr
				#either OS = 'Windows [closesocket sock][tcp-close-func sock]
				return INVALID_SOCKET
			]

			free addr
			tcp-socket: sock
			sock
		]

		sys-send: func [
			data        [byte-ptr!]
			length      [integer!]
			return:     [integer!]
		][
			tcp-send-func tcp-socket data length 0
		]

		sys-receive: func [
			buffer      [byte-ptr!]
			size        [integer!]
			return:     [integer!]
			/local
				result  [integer!]
		][
			result: tcp-recv-func tcp-socket buffer size 0
			if result < 0 [
				#either OS = 'Windows [
					tcp-errno: WSAGetLastError
				][
					tcp-errno: TCP_EWOULDBLOCK
				]
			]
			result
		]

		sys-close: func [
			return:     [logic!]
		][
			if tcp-socket <> 0 [
				#either OS = 'Windows [
					closesocket tcp-socket
				][
					tcp-close-func tcp-socket
				]
				tcp-socket: 0
			]
			true
		]

		sys-set-nonblocking: func [
			enable      [logic!]
			return:     [logic!]
			/local
				flags   [integer!]
				arg     [integer!]
				ptr     [int-ptr!]
		][
			if tcp-socket = 0 [return false]
			#either OS = 'Windows [
				ptr: as int-ptr! allocate 4
				either enable [ptr/value: 1][ptr/value: 0]
				flags: ioctlsocket tcp-socket FIONBIO ptr
				free as byte-ptr! ptr
				flags = 0
			][
				flags: tcp-fcntl [tcp-socket TCP_F_GETFL 0]
				if flags = -1 [return false]
				either enable [
					arg: flags or TCP_O_NONBLOCK
				][
					arg: flags and (not TCP_O_NONBLOCK)
				]
				(tcp-fcntl [tcp-socket TCP_F_SETFL arg]) = 0
			]
		]

		sys-readable: func [
			timeout-ms  [integer!]
			return:     [logic!]
			/local
				pfd     [tcp-pollfd!]
				result  [integer!]
		][
			if tcp-socket = 0 [return false]
			#either OS = 'Windows [
				pfd: as tcp-pollfd! allocate 8
				set-memory as byte-ptr! pfd as byte! 0 8
				pfd/fd: tcp-socket
				pfd/events: POLLRDNORM
				result: WSAPoll as byte-ptr! pfd 1 timeout-ms
				free as byte-ptr! pfd
			][
				pfd: declare tcp-pollfd!
				pfd/fd: tcp-socket
				pfd/events: TCP_POLLIN
				result: tcp-poll-func as byte-ptr! pfd 1 timeout-ms
			]
			result > 0
		]

		sys-set-timeout: func [
			ms          [integer!]
			return:     [logic!]
			/local
				tv      [byte-ptr!]
				tv-ptr  [int-ptr!]
				result  [integer!]
		][
			if tcp-socket = 0 [return false]
			#either OS = 'Windows [
				tv: allocate 4
				tv-ptr: as int-ptr! tv
				tv-ptr/value: ms
				result: tcp-setsockopt tcp-socket SOL_SOCKET SO_RCVTIMEO tv 4
				free tv
			][
				tv: allocate 8
				set-memory tv as byte! 0 8
				tv-ptr: as int-ptr! tv
				tv-ptr/value: ms / 1000
				tv-ptr: tv-ptr + 1
				tv-ptr/value: (ms % 1000) * 1000
				result: tcp-setsockopt tcp-socket SOL_SOCKET SO_RCVTIMEO tv 8
				free tv
			]
			result = 0
		]

		sys-last-error: func [
			return:     [integer!]
		][
			#either OS = 'Windows [
				WSAGetLastError
			][
				tcp-errno
			]
		]
	]

	_init: routine [
		return: [logic!]
	][
		sys-init
	]

	_connect: routine [
		host    [binary!]
		port    [integer!]
		return: [integer!]
		/local
			chost [c-string!]
	][
		chost: as c-string! binary/rs-head host
		sys-connect chost port
	]

	_send: routine [
		data    [binary!]
		len     [integer!]
		return: [integer!]
		/local
			buffer [byte-ptr!]
	][
		buffer: binary/rs-head data
		sys-send buffer len
	]

	_receive: routine [
		buffer  [binary!]
		size    [integer!]
		return: [integer!]
		/local
			buf [byte-ptr!]
	][
		buf: binary/rs-head buffer
		sys-receive buf size
	]

	_close: routine [
		return: [logic!]
	][
		sys-close
	]

	_cleanup: routine [][
		sys-cleanup
	]

	_set-nonblocking: routine [
		enable  [logic!]
		return: [logic!]
	][
		sys-set-nonblocking enable
	]

	_readable: routine [
		timeout-ms  [integer!]
		return:     [logic!]
	][
		sys-readable timeout-ms
	]

	_set-timeout: routine [
		ms      [integer!]
		return: [logic!]
	][
		sys-set-timeout ms
	]

	_last-error: routine [
		return: [integer!]
	][
		sys-last-error
	]

	connect: func [
		"Connects to a TCP server"
		host [string!] "Server address"
		port [integer!] "Server port"
		return: [logic!]
		/local host-bin
	][
		if connected? [close]

		if not _init [
			print "Error: could not initialize networking"
			return false
		]

		host-bin: append to binary! host #{00}

		either INVALID_SOCKET <> _connect host-bin port [
			connected?: true
			true
		][
			_cleanup
			print "Error: could not connect to server"
			false
		]
	]

	send: func [
		"Sends data to the server"
		data [string! binary!] "Data to send"
		return: [logic!]
		/local
			bytes [integer!]
			buffer [binary!]
	][
		if not connected? [
			print "Error: no connection established"
			return false
		]

		buffer: either binary? data [data][to binary! data]
		bytes: _send buffer length? buffer

		either bytes > 0 [
			true
		][
			print "Error: could not send data"
			false
		]
	]

	receive: func [
		"Receives data from the server"
		size [integer!] "Maximum size to receive"
		return: [binary! none!]
		/local
			buffer [binary!]
			bytes [integer!]
	][
		if not connected? [
			print "Error: no connection established"
			return none
		]

		buffer: make binary! size
		insert/dup buffer #{00} size

		bytes: _receive buffer size

		either bytes > 0 [
			copy/part buffer bytes
		][
			if bytes = 0 [
				connected?: false
			]
			if bytes < 0 [
			]
			none
		]
	]

	close: func [
		"Closes the TCP connection"
		return: [logic!]
	][
		if connected? [
			_close
			_cleanup
			connected?: false
		]
		true
	]

	set-nonblocking: func [
		"Enables or disables non-blocking mode on the socket"
		enable [logic!]
		return: [logic!]
	][
		if not connected? [
			print "Error: no connection established"
			return false
		]
		_set-nonblocking enable
	]

	readable?: func [
		"Checks if data is available without blocking (poll with timeout 0)"
		return: [logic!]
	][
		if not connected? [return false]
		_readable 0
	]

	set-timeout: func [
		"Sets a blocking timeout for receive (milliseconds, 0 = no timeout)"
		ms [integer!]
		return: [logic!]
	][
		if not connected? [
			print "Error: no connection established"
			return false
		]
		_set-timeout ms
	]

	last-error: func [
		"Returns the last socket error as an object {code message}"
		return: [object!]
		/local err-code
	][
		err-code: _last-error
		make object! [
			code: err-code
			message: case [
				err-code = 0     ["OK"]
				err-code = 11    ["EAGAIN: no data available (non-blocking)"]
				err-code = 10035 ["WSAEWOULDBLOCK: no data available (non-blocking)"]
				true             [rejoin ["Error code: " err-code]]
			]
		]
	]

	receive-available: func [
		"Non-blocking receive: returns data or none if nothing available"
		size [integer!]
		return: [binary! none!]
	][
		if not connected? [return none]
		either readable? [receive size][none]
	]
]