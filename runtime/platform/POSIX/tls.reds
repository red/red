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
		chain?		[logic!]
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
		either chain? [
			if 1 <> SSL_CTX_ctrl ctx SSL_CTRL_CHAIN_CERT 1 x509 [
				X509_free x509
				return 3
			]
		][
			if 1 <> SSL_CTX_use_certificate ctx x509 [
				X509_free x509
				return 4
			]
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
			pkey	[int-ptr!]
	][
		len: -1
		str: unicode/to-utf8 key :len

		bio: BIO_new_mem_buf str len
		if null? bio [return 1]
		pkey: PEM_read_bio_PrivateKey bio null null null
		BIO_free bio
		if null? pkey [
			return 2
		]
		if 1 <> SSL_CTX_use_PrivateKey ctx pkey [
			EVP_PKEY_free pkey
			return 3
		]
		if 1 <> SSL_CTX_check_private_key ctx [
			EVP_PKEY_free pkey
			return 4
		]
		EVP_PKEY_free pkey
		0
	]

	store-identity: func [
		data		[tls-data!]
		ssl_ctx		[int-ptr!]
		certs-blk	[red-block!]
		return:		[logic!]
		/local
			extra	[red-block!]
			proto	[red-integer!]
			certs	[red-block!]
			head	[red-string!]
			tail	[red-string!]
			first?	[logic!]
			key		[red-string!]
			pwd		[red-string!]
	][
		extra: certs-blk
		if TYPE_OF(extra) <> TYPE_BLOCK [return false]
		proto: as red-integer! block/select-word extra word/load "min-protocol" no
		if TYPE_OF(proto) = TYPE_INTEGER [
			SSL_CTX_ctrl ssl_ctx SSL_CTRL_SET_MIN_PROTO_VERSION proto/value null
		]
		proto: as red-integer! block/select-word extra word/load "max-protocol" no
		if TYPE_OF(proto) = TYPE_INTEGER [
			SSL_CTX_ctrl ssl_ctx SSL_CTRL_SET_MAX_PROTO_VERSION proto/value null
		]
		certs: as red-block! block/select-word extra word/load "certs" no
		if TYPE_OF(certs) <> TYPE_BLOCK [return false]
		head: as red-string! block/rs-head certs
		tail: as red-string! block/rs-tail certs
		first?: yes
		while [head < tail][
			if TYPE_OF(head) = TYPE_STRING [
				if 0 <> load-cert ssl_ctx head not first? [
					IODebug("load cert failed!!!")
					return false
				]
				if first? [
					first?: no
					key: as red-string! block/select-word extra word/load "key" no
					pwd: as red-string! block/select-word extra word/load "password" no
					if 0 <> link-private-key ssl_ctx key pwd [
						IODebug("link key failed!!!")
						return false
					]
				]
			]
			head: head + 1
		]
		not first?
	]

	verify-cb: func [
		[cdecl]
		ok		[integer!]
		ctx		[int-ptr!]
		return:	[integer!]
	][
		print-line ["verify: " ok]
		ok
	]

	store-roots: func [
		data		[tls-data!]
		ssl_ctx		[int-ptr!]
		return:		[logic!]
		/local
			values	[red-value!]
			extra	[red-block!]
			accept?	[red-logic!]
			builtin? [red-logic!]
			roots	[red-block!]
			store	[int-ptr!]
			head	[red-string!]
			tail	[red-string!]
			len		[integer!]
			str		[c-string!]
			bio		[int-ptr!]
			x509	[int-ptr!]
	][
		values: object/get-values data/port
		extra: as red-block! values + port/field-extra
		if TYPE_OF(extra) <> TYPE_BLOCK [return false]
		accept?: as red-logic! block/select-word extra word/load "accept-invalid-cert" no
		if all [
			TYPE_OF(accept?) = TYPE_LOGIC
			accept?/value
		][
			SSL_CTX_set_verify ssl_ctx SSL_VERIFY_NONE null
			return true
		]
		SSL_CTX_set_verify ssl_ctx SSL_VERIFY_PEER null ;as int-ptr! :verify-cb
		builtin?: as red-logic! block/select-word extra word/load "disable-builtin-roots" no
		if all [
			TYPE_OF(builtin?) = TYPE_LOGIC
			builtin?/value
		][
			store: X509_STORE_new
			SSL_CTX_set_cert_store ssl_ctx store
		]
		roots: as red-block! block/select-word extra word/load "roots" no
		if TYPE_OF(roots) = TYPE_BLOCK [
			head: as red-string! block/rs-head roots
			tail: as red-string! block/rs-tail roots
			while [head < tail][
				if TYPE_OF(head) = TYPE_STRING [
					len: -1
					str: unicode/to-utf8 head :len

					bio: BIO_new_mem_buf str len
					if null? bio [head: head + 1 continue]
					x509: PEM_read_bio_X509 bio null null null
					BIO_free bio
					if null? x509 [
						head: head + 1 continue
					]
					X509_STORE_add_cert store x509
					X509_free x509
				]
				head: head + 1
			]
		]
		true
	]

	get-domain: func [
		data		[red-block!]
		return:		[c-string!]
		/local
			domain	[red-string!]
			len		[integer!]
			name	[c-string!]
	][
		if TYPE_OF(data) <> TYPE_BLOCK [return null]
		domain: as red-string! block/select-word data word/load "domain" no
		if TYPE_OF(domain) <> TYPE_STRING [return null]
		len: -1
		name: unicode/to-utf8 domain :len
		if zero? len [return null]
		name
	]

	server-name-cb: func [
		[cdecl]
		ssl			[int-ptr!]
		ad			[int-ptr!]
		arg			[int-ptr!]
		return:		[integer!]
		/local
			td		[tls-data!]
			s		[series!]
			p pp e	[ptr-ptr!]
			name	[c-string!]
	][
		td: as tls-data! arg
		assert td/certs <> null

		name: SSL_get_servername ssl TLSEXT_NAMETYPE_host_name
		if any [
			name = null
			name/1 = #"^@"
		][return SSL_TLSEXT_ERR_NOACK]

		s: as series! td/certs/value
		p: as ptr-ptr! s/offset
		e: as ptr-ptr! s/tail
		while [p < e][
			if zero? strcmp name as c-string! p/value [
				pp: p + 1
				SSL_set_SSL_CTX ssl pp/value
				return SSL_TLSEXT_ERR_OK
			]
			p: p + 2
		]
		SSL_TLSEXT_ERR_OK
	]

	setup-server-certs: func [
		td		[tls-data!]
		extra	[red-block!]
		return: [logic!]
		/local
			vhost [red-block!]
			cert  [red-block!]
			end   [red-block!]
			ctx new-ctx [int-ptr!]
			pk	  [int-ptr!]
			cert? [logic!]
			cb?   [logic!]
			name  [c-string!]
	][
		vhost: as red-block! block/select-word extra word/load "virtual-host" no
		either TYPE_OF(vhost) = TYPE_BLOCK [
			cert: as red-block! block/rs-head vhost
			end: as red-block! block/rs-tail vhost
		][
			cert: extra
			end: extra + 1
		]

		cb?: cert + 1 < end
		if cb? [td/certs: alloc-fixed-series 8 * size? int-ptr! 1 0]

		cert?: no
		while [cert < end][
			new-ctx: SSL_CTX_new TLS_server_method
			either store-identity td new-ctx cert [
				cert?: yes
				SSL_CTX_set_mode(new-ctx 5)  ;-- SSL_MODE_ENABLE_PARTIAL_WRITE or SSL_MODE_AUTO_RETRY
				SSL_CTX_set_cipher_list new-ctx "ECDHE+AES:@STRENGTH:+AES256"

				if cb? [
					name: get-domain cert
					if null? name [
						IODebug("setup-server-certs: no domain name provided")
						SSL_CTX_free new-ctx
						return false
					]
					array/append-ptr td/certs as int-ptr! strdup name
					array/append-ptr td/certs new-ctx

					SSL_CTX_callback_ctrl new-ctx 53 as int-ptr! :server-name-cb
					SSL_CTX_ctrl new-ctx 54 0 as int-ptr! td
				]
				ctx: new-ctx
			][
				SSL_CTX_free new-ctx
			]
			cert: cert + 1
		]
		unless cert? [
			ctx: SSL_CTX_new TLS_server_method
			pk: create-private-key
			SSL_CTX_use_certificate ctx create-certificate pk
			SSL_CTX_use_PrivateKey ctx pk
		]
		server-ctx: ctx
		true
	]

	create: func [
		td		[tls-data!]
		client? [logic!]
		/local
			ctx		[int-ptr!]
			ssl		[int-ptr!]
			fd		[integer!]
			values	[red-value!]
			extra	[red-block!]
	][
		IODebug("tls/create")
		ERR_clear_error
		if null? td/ssl [
			values: object/get-values td/port
			extra: as red-block! values + port/field-extra
			either client? [
				if null? client-ctx [
					client-ctx: SSL_CTX_new TLS_client_method
					store-identity td client-ctx extra
					store-roots td client-ctx
					SSL_CTX_set_mode(client-ctx 5)  ;-- SSL_MODE_ENABLE_PARTIAL_WRITE 1 or SSL_MODE_AUTO_RETRY 4
					SSL_CTX_set_default_verify_paths client-ctx
					SSL_CTX_set_cipher_list client-ctx "DEFAULT:!aNULL:!eNULL:!MD5:!3DES:!DES:!RC4:!IDEA:!SEED:!aDSS:!SRP:!PSK"
				]
				ctx: client-ctx
			][
				setup-server-certs td extra
				ctx: server-ctx
			]

			ssl: SSL_new ctx
			td/ssl: ssl
			if null? ssl [probe "SSL_new failed" exit]

			fd: as-integer td/device
			if zero? SSL_set_fd ssl fd [
				probe "SSL_set_fd error"
			]
			either client? [
				SSL_ctrl ssl SSL_CTRL_SET_TLSEXT_HOSTNAME TLSEXT_NAMETYPE_host_name as int-ptr! get-domain extra
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
		state: td/state
		either state and IO_STATE_RW = 0 [
			iocp/add td/io-port as-integer td/device evt or EPOLLET as iocp-data! td
		][
			if state <> evt [iocp/modify td/io-port as-integer td/device evt or EPOLLET as iocp-data! td]
		]
		td/state: state or evt
	]

	negotiate: func [
		td		[tls-data!]
		return: [integer!]		;-- 0: continue, 1: success, -1: error
		/local
			ssl [int-ptr!]
			ret [integer!]
			p	[red-object!]
	][
		IODebug("tls/negotiate")
		ssl: td/ssl
		ret: SSL_do_handshake ssl
		either ret = 1 [
			iocp/remove td/io-port as-integer td/device td/state as iocp-data! td
			td/state: td/state and (not IO_STATE_RW) or IO_STATE_TLS_DONE
			1
		][
			ret: SSL_get_error ssl ret
			switch ret [
				SSL_ERROR_WANT_READ [
					update-td td EPOLLIN
				]
				SSL_ERROR_WANT_WRITE [
					update-td td EPOLLOUT
				]
				default [
					check-errors ret
					ERR_clear_error
					either td/state and IO_STATE_CLIENT <> 0 [	;-- tls client
						td/event: IO_EVT_CLOSE
						td/state: td/state or IO_STATE_ERROR
					][
						td/event: IO_EVT_ERROR
						SSL_free ssl
						td/ssl: null
						if td/state <> 0 [
							iocp/remove td/io-port as-integer td/device td/state as iocp-data! td
						]
						socket/close as-integer td/device
						td/device: IO_INVALID_DEVICE
						td/io-port/n-ports: td/io-port/n-ports - 1
					]
					return -1
				]
			]
			0
		]
	]

	check-errors: func [code [integer!] /local buf [c-string!]][
		IODebug(["check errors" code])
		buf: as c-string! system/stack/allocate 64
		until [				;-- clear the error stack in openssl
			code: ERR_get_error
			if code <> 0 [
				buf/1: null-byte
				ERR_error_string code buf
				IODebug(buf)
			]
			zero? code
		]
		IODebug("check errors finish")
	]

	free-handle: func [
		td		[tls-data!]
		/local
			ssl [int-ptr!]
			ret state sock [integer!]
	][
		ssl: td/ssl
		IODebug(["native tls free handle" td/state td/device])
		if all [ssl <> null td/state and IO_STATE_ERROR = 0][
			ret: SSL_get_shutdown ssl
			?? ret
			if ret = 0 [	;-- no shutdown yet
				ERR_clear_error
				ret: SSL_shutdown ssl	;@@ this API will crash silently if fd was closed
				?? ret
				if ret < 0 [
					ret: SSL_get_error ssl ret
					check-errors -1
					if ret = SSL_ERROR_WANT_WRITE [
						state: td/state
						sock: as-integer td/device
						case [
							state and IO_STATE_RW = 0 [
								td/state: state or IO_STATE_PENDING_WRITE
								iocp/add td/io-port sock EPOLLOUT or EPOLLET as iocp-data! td
							]
							state and EPOLLOUT = 0 [
								td/state: state or IO_STATE_PENDING_WRITE
								iocp/modify td/io-port sock EPOLLIN or EPOLLOUT or EPOLLET as iocp-data! td
							]
							true [td/state: state or IO_STATE_WRITING]
						]
						td/state: IO_STATE_CLOSING or td/state
						exit
					]
				]
			]
		]

		;-- the close_notify was sent
		;-- we don't care about the reply from the peer
		if ssl <> null [SSL_free ssl td/ssl: null]
		socket/close as-integer td/device
		td/device: IO_INVALID_DEVICE
		IODebug("native tls free handle done")
	]
]