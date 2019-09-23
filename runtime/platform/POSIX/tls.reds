Red/System [
	Title:   "TLS support on POSIX"
	Author:  "Xie Qingtian"
	File:	 %tls.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define SSL_ERROR_SSL			1
#define SSL_ERROR_WANT_READ		2
#define SSL_ERROR_WANT_WRITE	3
#define SSL_ERROR_WANT_X509_LOOKUP	4

tls: context [

	server-ctx: as int-ptr! 0
	client-ctx: as int-ptr! 0

	create: func [
		td		[tls-data!]
		client? [logic!]
		/local
			ctx	[int-ptr!]
			ssl [int-ptr!]
			fd	[integer!]
	][
		if null? td/ssl [
			either client? [
				if null? client-ctx [client-ctx: SSL_CTX_new TLS_client_method]
				?? client-ctx
				ctx: client-ctx
			][
				if null? server-ctx [server-ctx: SSL_CTX_new TLS_server_method]
				ctx: server-ctx
			]
			ssl: SSL_new ctx
			?? ssl
			td/ssl: ssl
			if null? ssl [probe "SSL_new failed" exit]

			fd: as-integer td/iocp/device
			?? fd
			probe SSL_set_fd ssl fd
			either client? [
				SSL_set_connect_state ssl
			][
				SSL_set_accept_state ssl
			]
		]
	]

	update-td: func [
		td	[tls-data!]
		evt [integer!]
		/local
			state [integer!]
	][
		state: td/iocp/state
		either zero? state [
			iocp/add td/iocp/io-port as-integer td/iocp/device evt or EPOLLET as iocp-data! td
		][
			iocp/modify td/iocp/io-port as-integer td/iocp/device evt or EPOLLET as iocp-data! td
			evt: state or evt
		]
		td/iocp/state: evt
	]

	negotiate: func [
		td		[tls-data!]
		return: [logic!]
		/local
			ssl [int-ptr!]
			ret [integer!]
	][
		probe "negotiate...................."
		ssl: td/ssl
		?? ssl
		ret: SSL_do_handshake ssl
		?? ret
		either ret = 1 [td/iocp/state: IO_STATE_TLS_DONE yes][
			ret: SSL_get_error ssl ret
			?? ret
			switch ret [
				SSL_ERROR_WANT_READ [
					probe "want read"
					update-td td EPOLLIN
				]
				SSL_ERROR_WANT_WRITE [
					probe "want write"
					update-td td EPOLLOUT
				]
				default [probe "error when do handshake"]
			]
			no
		]
	]

	
]