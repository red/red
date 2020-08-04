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
#define SSL_CTRL_SET_MIN_PROTO_VERSION          123
#define SSL_CTRL_SET_MAX_PROTO_VERSION          124

tls: context [

	server-ctx: as int-ptr! 0
	client-ctx: as int-ptr! 0

	create-private-key: func [
		return: [int-ptr!]
		/local
			bn	[int-ptr!]
			rsa [int-ptr!]
			prv [int-ptr!]
	][
		bn: BN_new
		BN_set_word bn 17
		rsa: RSA_new
		RSA_generate_key_ex rsa 2048 bn null
		prv: EVP_PKEY_new
		EVP_PKEY_set1_RSA prv rsa
		RSA_free rsa
		BN_free bn
		return prv
	]

	create-certificate: func [
		pkey	[int-ptr!]		;-- private key
		return: [int-ptr!]
		/local
			cert	[int-ptr!]
			name	[int-ptr!]
	][
		cert: X509_new
		ASN1_INTEGER_set X509_get_serialNumber cert 1
		X509_time_adj_ex X509_getm_notBefore cert 0 0 0
		X509_time_adj_ex X509_getm_notAfter cert 365 0 0
		X509_set_pubkey cert pkey
		
		name: X509_get_subject_name cert
		X509_NAME_add_entry_by_txt name "C" 1001h "CA" -1 -1 0
		X509_NAME_add_entry_by_txt name "O" 1001h "Red Language" -1 -1 0
		X509_NAME_add_entry_by_txt name "CN" 1001h "localhost" -1 -1 0
		X509_set_issuer_name cert name

		X509_sign cert pkey EVP_sha1
		cert
	]

	load-cert: func [
		ctx			[int-ptr!]
		cert		[red-string!]
		return:		[integer!]
		/local
			len		[integer!]
			str		[c-string!]
			bio		[int-ptr!]
			x509	[int-ptr!]
	][
		len: -1
		str: unicode/to-utf8 cert :len

		bio: BIO_new_mem_buf str len
		if null? bio [return 1]
		x509: PEM_read_bio_X509 bio null null null
		BIO_free bio
		if null? x509 [
			return 2
		]
		if 1 <> SSL_CTX_use_certificate ctx x509 [
			X509_free x509
			return 3
		]
		X509_free x509
		0
	]

	link-private-key: func [
		ctx			[int-ptr!]
		key			[red-string!]
		pwd			[red-string!]
		return:		[integer!]
		/local
			len		[integer!]
			str		[c-string!]
			bio		[int-ptr!]
			rsa		[int-ptr!]
	][
		len: -1
		str: unicode/to-utf8 key :len

		bio: BIO_new_mem_buf str len
		if null? bio [return 1]
		rsa: PEM_read_bio_RSAPrivateKey bio null null null
		BIO_free bio
		if null? rsa [
			return 2
		]
		if 1 <> SSL_CTX_use_RSAPrivateKey ctx rsa [
			RSA_free rsa
			return 3
		]
		if 1 <> SSL_CTX_check_private_key ctx [
			return 4
		]
		RSA_free rsa
		0
	]

	create-cert-ctx: func [
		data		[tls-data!]
		ctx			[int-ptr!]
		return:		[integer!]
		/local
			values	[red-value!]
			proto	[red-integer!]
			extra	[red-block!]
			cert	[red-string!]
			chain	[red-string!]
			key		[red-string!]
			pwd		[red-string!]
			ret		[integer!]
	][
		values: object/get-values data/port
		extra: as red-block! values + port/field-extra
		if TYPE_OF(extra) <> TYPE_BLOCK [return 1]
		proto: as red-integer! block/select-word extra word/load "min-protocol" no
		if TYPE_OF(proto) = TYPE_INTEGER [
			SSL_CTX_ctrl ctx SSL_CTRL_SET_MIN_PROTO_VERSION proto/value null
		]
		proto: as red-integer! block/select-word extra word/load "max-protocol" no
		if TYPE_OF(proto) = TYPE_INTEGER [
			SSL_CTX_ctrl ctx SSL_CTRL_SET_MAX_PROTO_VERSION proto/value null
		]
		cert: as red-string! block/select-word extra word/load "cert" no
		if TYPE_OF(cert) <> TYPE_STRING [return 2]
		chain: as red-string! block/select-word extra word/load "chain-cert" no
		key: as red-string! block/select-word extra word/load "key" no
		pwd: as red-string! block/select-word extra word/load "password" no
		if 0 <> load-cert ctx cert [
			return 3
		]
		link-private-key ctx key pwd
		;if TYPE_OF(chain) = TYPE_STRING [
		;	load-cert ctx chain
		;]
		return 0
	]

	create: func [
		td		[tls-data!]
		client? [logic!]
		/local
			ctx		[int-ptr!]
			ssl		[int-ptr!]
			fd		[integer!]
			err		[integer!]
			pk		[int-ptr!]
			cert	[int-ptr!]
	][
		if null? td/ssl [
			either client? [
				if null? client-ctx [client-ctx: SSL_CTX_new TLS_client_method]
				ctx: client-ctx
			][
				if null? server-ctx [
					server-ctx: SSL_CTX_new TLS_server_method
				]
				ctx: server-ctx
			]
			create-cert-ctx td ctx
			ssl: SSL_new ctx

			td/ssl: ssl
			if null? ssl [probe "SSL_new failed" exit]

			fd: as-integer td/iocp/device
			if zero? SSL_set_fd ssl fd [
				probe "SSL_set_fd error"
			]
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
		ssl: td/ssl
		ret: SSL_do_handshake ssl
		either ret = 1 [td/iocp/state: IO_STATE_TLS_DONE yes][
			ret: SSL_get_error ssl ret
			switch ret [
				SSL_ERROR_WANT_READ [
					update-td td EPOLLIN
				]
				SSL_ERROR_WANT_WRITE [
					update-td td EPOLLOUT
				]
				default [probe "error when do handshake"]
			]
			no
		]
	]
]