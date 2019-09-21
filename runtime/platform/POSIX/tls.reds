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

tls-data!: alias struct! [
	iocp		[iocp-data! value]
	port		[red-object! value]		;-- red port! cell
	send-buf	[node!]					;-- send buffer
	ssl			[int-ptr!]
	connected?	[logic!]
]

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
				ctx: client-ctx
			][
				if null? server-ctx [server-ctx: SSL_CTX_new TLS_server_method]
				ctx: server-ctx
			]
			ssl: SSL_new ctx
			td/ssl: ssl
			if null? ssl [probe "SSL_new failed" exit]

			fd: as-integer td/iocp/device
			SSL_set_fd ssl fd
			either client? [
				SSL_set_connect_state ssl
			][
				SSL_set_accept_state ssl
			]
			either zero? td/iocp/state [
				iocp/add td/iocp/io-port fd EPOLLIN or EPOLLOUT or EPOLLET as iocp-data! td
			][
				iocp/modify td/iocp/io-port fd EPOLLIN or EPOLLOUT or EPOLLET as iocp-data! td
			]
		]
	]

	negotiate: func [
		td		[tls-data!]
		/local
			ssl [int-ptr!]
			ret [integer!]
	][
		ssl: td/ssl
		ret: SSL_do_handshake ssl
		either ret = 1 [td/connected?: yes][
			switch SSL_get_error ssl ret [
				SSL_ERROR_WANT_READ [
					
				]
				SSL_ERROR_WANT_WRITE [
					
				]
				default [probe "error when do handshake" exit]
			]
		]
	]
]