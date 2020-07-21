Red/System [
	Title:   "TLS support on Windows"
	Author:  "Xie Qingtian"
	File:	 %tls.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define MAX_SSL_MSG_LENGTH				17408
#define SEC_OK							0
#define SEC_I_CONTINUE_NEEDED			00090312h
#define SEC_E_INCOMPLETE_MESSAGE		80090318h
#define SEC_E_INCOMPLETE_CREDENTIALS	00090320h
#define SEC_I_RENEGOTIATE				00090321h

#define ECC_256_MAGIC_NUMBER			20h
#define ECC_384_MAGIC_NUMBER			30h
#define BCRYPT_ECDSA_PRIVATE_P256_MAGIC 32534345h  ;-- ECS2
#define BCRYPT_ECDSA_PRIVATE_P384_MAGIC 34534345h  ;-- ECS4
#define BCRYPT_ECDSA_PRIVATE_P521_MAGIC 36534345h  ;-- ECS6

#define SecIsValidHandle(x)	[
	all [x/dwLower <> (as int-ptr! -1) x/dwUpper <> (as int-ptr! -1)]
]

tls-data!: alias struct! [
	iocp		[iocp-data! value]
	port		[red-object! value]		;-- red port! cell
	send-buf	[node!]					;-- send buffer
	buf-len		[integer!]
	credential	[SecHandle! value]		;-- credential handle
	security	[int-ptr!]				;-- security context handle lower
	security2	[int-ptr!]				;-- security context handle upper
	;-- SecPkgContext_StreamSizes
	ctx-max-msg	[integer!]
	ctx-header	[integer!]
	ctx-trailer	[integer!]
]

tls: context [
	verbose: 0

	cert-client: as CERT_CONTEXT 0
	cert-server: as CERT_CONTEXT 0
	user-store: as int-ptr! 0
	machine-store: as int-ptr! 0

	sspi-flags-client: ISC_REQ_SEQUENCE_DETECT or
		ISC_REQ_REPLAY_DETECT or
		ISC_REQ_CONFIDENTIALITY or
		ISC_REQ_EXTENDED_ERROR or
		ISC_REQ_MANUAL_CRED_VALIDATION or
		ISC_REQ_STREAM

	sspi-flags-server: ISC_REQ_SEQUENCE_DETECT or
		ISC_REQ_REPLAY_DETECT or
		ISC_REQ_CONFIDENTIALITY or
		ASC_REQ_EXTENDED_ERROR or
		ASC_REQ_STREAM

	cert-to-bin: func [
		cert		[byte-ptr!]
		len			[integer!]
		ret-len		[int-ptr!]
		return:		[byte-ptr!]
		/local
			result	[byte-ptr!]
	][
		either CryptStringToBinaryA cert len 7 null ret-len null null [
			result: allocate ret-len/value
			CryptStringToBinaryA cert len 7 result ret-len null null
			result
		][
			probe "cert-to-bin failed"
			null
		]
	]

	decode-cert: func [
		private-key	[byte-ptr!]
		key-len		[integer!]
		blob-size	[int-ptr!]
		cert-type	[int-ptr!]
		return:		[byte-ptr!]
		/local
			result		[byte-ptr!]
			key-type	[integer!]
			blob-sz		[integer!]
	][
		result: null
		key-type: 43		;-- PKCS_RSA_PRIVATE_KEY
		blob-sz: 0

		unless CryptDecodeObjectEx
				00010001h
				as c-string! key-type
				private-key
				key-len
				0 null null
				:blob-sz [
			key-type: 82	;-- X509_ECC_PRIVATE_KEY
			unless CryptDecodeObjectEx
					00010001h
					as c-string! key-type
					private-key
					key-len
					0 null null
					:blob-sz [
				key-type: 0
			]
		]

		if key-type <> 0 [
			result: allocate blob-size/value
			CryptDecodeObjectEx
				00010001h
				as c-string! key-type
				private-key
				key-len
				0 null
				result
				:blob-sz
			blob-size/value: blob-sz
			cert-type/value: key-type
		]
		result
	]

	link-rsa-key: func [
		ctx		[CERT_CONTEXT]
		blob	[byte-ptr!]
		size	[integer!]
	][
		;TBD
	]

	link-private-key: func [
		ctx			[CERT_CONTEXT]
		blob		[byte-ptr!]
		type		[integer!]
		/local
			status		[integer!]
			pub-blob	[CRYPT_BIT_BLOB]
			key-info	[CRYPT_ECC_PRIVATE_KEY_INFO]
			pub-size	[integer!]
			priv-size	[integer!]
			blob-size	[integer!]
			pub-buf		[byte-ptr!]
			priv-buf	[byte-ptr!]
			key-blob	[BCRYPT_ECCKEY_BLOB]
			provider	[ptr-value!]
			nc-buf		[BCryptBuffer! value]
			nc-desc		[BCryptBufferDesc! value]
			prov-info	[CRYPT_KEY_PROV_INFO value]
			h-key		[ptr-value!]
			type-str	[c-string!]
	][
		either type = 43 [
			type-str: #u16 "RSAPRIVATEBLOB"
		][
			type-str: #u16 "ECCPRIVATEBLOB"
		]
		pub-blob: ctx/pCertInfo/SubjectPublicKeyInfo/PublicKey
		key-info: as CRYPT_ECC_PRIVATE_KEY_INFO blob
		pub-size: pub-blob/cbData - 1
		priv-size: key-info/PrivateKey/cbData
		blob-size: pub-size + priv-size + size? BCRYPT_ECCKEY_BLOB
		pub-buf: pub-blob/pbData + 1
		priv-buf: key-info/PrivateKey/pbData
		key-blob: as BCRYPT_ECCKEY_BLOB allocate blob-size

		if key-blob <> null [
			key-blob/dwMagic: switch priv-size [
				ECC_256_MAGIC_NUMBER [BCRYPT_ECDSA_PRIVATE_P256_MAGIC]
				ECC_384_MAGIC_NUMBER [BCRYPT_ECDSA_PRIVATE_P384_MAGIC]
				default [BCRYPT_ECDSA_PRIVATE_P521_MAGIC]
			]
			key-blob/cbKey: priv-size
			copy-memory as byte-ptr! (key-blob + 1) pub-buf pub-size
			copy-memory (as byte-ptr! key-blob + 1) + pub-size priv-buf priv-size

			either zero? NCryptOpenStorageProvider
				provider
				#u16 "Microsoft Software Key Storage Provider"
				0 [
				nc-buf/cbBuffer: 11 * 2	;-- bytes of the pvBuffer
				nc-buf/BufferType: 45	;-- NCRYPTBUFFER_PKCS_KEY_NAME
				nc-buf/pvBuffer: as byte-ptr! #u16 "RedAliasKey"
				nc-desc/ulVersion: 0
				nc-desc/cBuffers: 1
				nc-desc/pBuffers: nc-buf

				zero-memory as byte-ptr! :prov-info size? CRYPT_KEY_PROV_INFO
				prov-info/pwszContainerName: #u16 "RedAliasKey"
				prov-info/pwszProvName: #u16 "Microsoft Software Key Storage Provider"

				if zero? NCryptImportKey
					provider/value
					null
					type-str
					as int-ptr! :nc-desc
					h-key
					as byte-ptr! key-blob
					:blob-size
					80h	[	;-- NCRYPT_OVERWRITE_KEY_FLAG
					NCryptFreeObject h-key/value
				]

				NCryptFreeObject provider/value
				unless CertSetCertificateContextProperty ctx 2 0 as byte-ptr! :prov-info [
					probe "CertSetCertificateContextProperty failed"
				]
				free as byte-ptr! key-blob
			][
				probe "NCryptOpenStorageProvider failed"
			]
		]
	]

	load-cert: func [
		cert		[c-string!]
		pkey		[c-string!]
		return:		[CERT_CONTEXT]
		/local
			cert-bin	[byte-ptr!]
			pkey-bin	[byte-ptr!]
			decoded		[byte-ptr!]
			file		[integer!]
			size		[integer!]
			len			[integer!]
			buffer		[byte-ptr!]
			key-type	[integer!]
			ctx			[CERT_CONTEXT]
	][
		file: simple-io/open-file cert simple-io/RIO_READ no
		if file < 0 [
			probe ["cannot read file: " cert]
			return null
		]
		size: simple-io/file-size? file
		buffer: allocate size
		len: simple-io/read-data file buffer size
		simple-io/close-file file

		cert-bin: cert-to-bin buffer len :size
		ctx: CertCreateCertificateContext 00010001h cert-bin size
		if null? ctx [
			probe "CertCreateCertificateContext failed"
			return null
		]

		free buffer
		free cert-bin
		file: simple-io/open-file pkey simple-io/RIO_READ no
		if file < 0 [
			probe ["cannot read file: " pkey]
			return ctx
		]
		size: simple-io/file-size? file
		buffer: allocate size
		len: simple-io/read-data file buffer size
		simple-io/close-file file

		key-type: 0
		pkey-bin: cert-to-bin buffer len :size
		decoded: decode-cert pkey-bin size :len :key-type
		if decoded <> null [
			link-private-key ctx decoded key-type
		]
		free buffer
		free pkey-bin
		free decoded
		ctx
	]

	create-credentials: func [
		hcred		[SecHandle!]		;-- OUT: Security handle in hcred
		cert-ctx	[CERT_CONTEXT]
		client?		[logic!]			;-- Is it client side?
		return:		[integer!]			;-- return status code
		/local
			scred	[SCHANNEL_CRED value]
			status	[integer!]
			expiry	[tagFILETIME value]
			flags	[integer!]
			ptr		[ptr-value!]
	][
		zero-memory as byte-ptr! :scred size? SCHANNEL_CRED
		scred/dwVersion: 4		;-- SCHANNEL_CRED_VERSION

		if cert-ctx <> null [
			ptr/value: as int-ptr! cert-ctx
			scred/cCreds: 1
			scred/paCred: as int-ptr! :ptr
		]
		
		scred/dwFlags: SCH_USE_STRONG_CRYPTO

		either client? [flags: 2][flags: 1]		;-- Credential use flags
		status: platform/SSPI/AcquireCredentialsHandleW
			null		;-- name of principal
			#u16 "Microsoft Unified Security Protocol Provider"
			flags
			null
			as int-ptr! :scred
			null
			null
			hcred
			:expiry

		if status <> 0 [
			flags: status
			status: GetLastError
			probe ["status error: " as int-ptr! status " " as int-ptr! status]
			either status = 8009030Dh [		;-- SEC_E_UNKNOWN_CREDENTIALS
				status: -1					;-- needs administrator rights
			][
				status: -2
			]
		]
		status
	]

	create: func [
		data		[tls-data!]
		/local
			buf		[red-binary!]
	][
		buf: as red-binary! (object/get-values data/port) + port/field-data
		if TYPE_OF(buf) <> TYPE_BINARY [
			binary/make-at as cell! buf MAX_SSL_MSG_LENGTH * 4
		]
		data/send-buf: buf/node
	]

	release-context: func [
		data	[tls-data!]
	][
		if SecIsValidHandle(data/credential) [
			platform/SSPI/FreeCredentialsHandle data/credential
		]
		platform/SSPI/DeleteSecurityContext :data/security
	]

	find-certificate: func [
		user-store? [logic!]
		return:		[CERT_CONTEXT]
		/local
			cert-ctx	[CERT_CONTEXT]
			eku			[CERT_ENHKEY_USAGE value]
			err			[integer!]
			store		[int-ptr!]
			flags		[integer!]
			auth		[ptr-value!]
	][
		either user-store? [
			store: user-store
			flags: 0001C000h		;-- CERT_STORE_OPEN_EXISTING_FLAG or CERT_STORE_READONLY_FLAG or CERT_SYSTEM_STORE_CURRENT_USER
			auth/value: as int-ptr! "1.3.6.1.5.5.7.3.2"		;-- szOID_PKIX_KP_CLIENT_AUTH
		][
			store: machine-store
			flags: 0002C000h		;-- CERT_STORE_OPEN_EXISTING_FLAG or CERT_STORE_READONLY_FLAG or CERT_SYSTEM_STORE_LOCAL_MACHINE
			auth/value: as int-ptr! "1.3.6.1.5.5.7.3.1"		;-- szOID_PKIX_KP_SERVER_AUTH
		]

		eku/rgpszUsageIdentifier: as c-string! :auth
		store: CertOpenStore
			as c-string! 10			;-- CERT_STORE_PROV_SYSTEM
			0
			null
			flags
			#u16 "My"

		if null? store [
			err: GetLastError
			probe ["open Cert store error: " err]
		]
		either user-store? [user-store: store][machine-store: store]

		cert-ctx: null
		eku/cUsageIdentifier: 1
		while [
			cert-ctx: CertFindCertificateInStore
				store
				1			;-- X509_ASN_ENCODING
				1			;-- CERT_FIND_OPTIONAL_ENHKEY_USAGE_FLAG
				000A0000h	;-- CERT_FIND_ENHKEY_USAGE
				as byte-ptr! :eku
				cert-ctx
			cert-ctx <> null
		][
			return cert-ctx
		]
		null
	]

	get-credential: func [
		data		[tls-data!]
		user-store? [logic!]
		return:		[CERT_CONTEXT]
		/local
			issuer-list	[SecPkgContext_IssuerListInfoEx! value]
			cred		[SecHandle! value]
			status		[integer!]
			cert-ctx	[CERT_CONTEXT]
			eku			[CERT_ENHKEY_USAGE value]
			err			[integer!]
			store		[int-ptr!]
			flags		[integer!]
	][
		;-- Read list of trusted issuers from schannel.
		;-- 
		;-- Note the a server will NOT send an issuer list if it has the registry key
		;-- HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL
		;-- has a DWORD value called SendTrustedIssuerList set to 0
		status: platform/SSPI/QueryContextAttributesW
			as SecHandle! :data/security
			59h			;-- SECPKG_ATTR_ISSUER_LIST_EX
			as byte-ptr! :issuer-list

		if status <> 0 [
			probe ["Querying issuer list info failed: " status]
			return null
		]

		;-- Now go ask for the client credentials
		either issuer-list/cIssuers <> 0 [
			0		;-- TBD get certificate by issuer

		][			;-- Select any valid certificate, regardless of issuer
			return find-certificate user-store?
		]
		null
	]

	negotiate: func [
		data		[tls-data!]
		return:		[logic!]
		/local
			_indesc		[SecBufferDesc! value]
			indesc		[SecBufferDesc!]
			outdesc		[SecBufferDesc! value]
			outbuf-1	[SecBuffer!]
			outbuf-2	[SecBuffer!]
			inbuf-1		[SecBuffer!]
			inbuf-2		[SecBuffer!]
			extra-buf	[SecBuffer!]
			expiry		[tagFILETIME value]
			ret			[integer!]
			attr		[integer!]
			buflen		[integer!]
			sec-handle	[SecHandle!]
			sec-handle2	[SecHandle!]
			pbuffer		[byte-ptr!]
			outbuffer	[byte-ptr!]
			s			[series!]
			client?		[logic!]
			state		[integer!]
			credential	[SecHandle! value]
			cert		[CERT_CONTEXT]
			ctx-size	[SecPkgContext_StreamSizes value]
	][
		state: data/iocp/state
		client?: state and IO_STATE_CLIENT <> 0

		;-- allocate 2 SecBuffer! on stack for buffer
		inbuf-1: as SecBuffer! system/stack/allocate (size? SecBuffer!) >> 1
		inbuf-2: inbuf-1 + 1
		outbuf-1: as SecBuffer! system/stack/allocate (size? SecBuffer!) >> 1
		outbuf-2: outbuf-1 + 1

		buflen: data/buf-len

		if null? data/security [
			create data
			either client? [cert: null][cert: find-certificate no]
			create-credentials as SecHandle! :data/credential cert client?
		]

		s: as series! data/send-buf/value
		pbuffer: as byte-ptr! s/offset
		outbuffer: pbuffer + (MAX_SSL_MSG_LENGTH * 2)

		switch data/iocp/event [
			IO_EVT_READ [buflen: data/iocp/transferred]
			IO_EVT_ACCEPT [
				state: state or IO_STATE_READING
			]
			default [0]
		]

		if state and IO_STATE_READING <> 0 [
			data/iocp/state: state and (not IO_STATE_READING)
			socket/recv
						as-integer data/iocp/device
						pbuffer + buflen
						MAX_SSL_MSG_LENGTH * 2 - buflen
						as iocp-data! data 
			return false
		]

		indesc: as SecBufferDesc! :_indesc

		forever [
			;-- setup input buffers
			inbuf-1/BufferType: 2		;-- SECBUFFER_TOKEN
			inbuf-1/cbBuffer: buflen
			inbuf-1/pvBuffer: pbuffer
			inbuf-2/BufferType: 0		;-- SECBUFFER_EMPTY
			inbuf-2/cbBuffer: 0
			inbuf-2/pvBuffer: null
			indesc/ulVersion: 0
			indesc/cBuffers: 2
			indesc/pBuffers: inbuf-1

			;-- setup output buffers
			outbuf-1/BufferType: 2
			outbuf-1/cbBuffer: MAX_SSL_MSG_LENGTH * 2
			outbuf-1/pvBuffer: outbuffer
			outdesc/ulVersion: 0
			outdesc/cBuffers: 1
			outdesc/pBuffers: outbuf-1

			either null? data/security [
				sec-handle: null
				sec-handle2: as SecHandle! :data/security
				if client? [
					indesc: null
					inbuf-1/pvBuffer: null
				]
				io/pin-memory data/send-buf
			][
				sec-handle: as SecHandle! :data/security
				sec-handle2: null
			]

			attr: 0
			either client? [
				ret: platform/SSPI/InitializeSecurityContextW
					data/credential
					sec-handle
					null
					sspi-flags-client
					0
					10h			;-- SECURITY_NATIVE_DREP
					indesc
					0
					sec-handle2
					outdesc
					:attr
					:expiry
			][
				outbuf-2/BufferType: 0		;-- SECBUFFER_EMPTY
				outbuf-2/cbBuffer: 0
				outbuf-2/pvBuffer: null
				outdesc/cBuffers: 2
				ret: platform/SSPI/AcceptSecurityContext
					data/credential
					sec-handle
					indesc
					sspi-flags-server
					0
					sec-handle2
					outdesc
					:attr
					:expiry
			]

			switch ret [
				SEC_OK
				SEC_I_CONTINUE_NEEDED [
					;-- this error means that information we provided in contextData is not enough to generate SSL token.
					;-- We'll ask other party for more information by sending our unfinished "token",
					;-- and then we will start all over - from the response that we'll get from the other party.
					extra-buf: inbuf-2
					if all [
						not client?
						inbuf-2/BufferType <> 5		;-- SECBUFFER_EXTRA
					][
						extra-buf: outbuf-2
					]
					if all [
						outbuf-1/cbBuffer > 0
						outbuf-1/pvBuffer <> null
					][
						data/iocp/state: state or IO_STATE_READING
						if 0 > socket/send
							as-integer data/iocp/device
							outbuf-1/pvBuffer
							outbuf-1/cbBuffer
							as iocp-data! data [
								probe "handshake send error"
								release-context data
							]
					]

					if ret = SEC_OK [
						data/iocp/state: state or IO_STATE_TLS_DONE
						platform/SSPI/QueryContextAttributesW
							sec-handle
							4			;-- SECPKG_ATTR_STREAM_SIZES
							as byte-ptr! :ctx-size
						data/ctx-max-msg: ctx-size/cbMaximumMessage
						data/ctx-header: ctx-size/cbHeader
						data/ctx-trailer: ctx-size/cbTrailer

						data/buf-len: 0
						either client? [extra-buf: inbuf-2][extra-buf: outbuf-2]
						if extra-buf/BufferType = 5 [
							0
						]

						either client? [
							data/iocp/event: IO_EVT_CONNECT
						][
							data/iocp/event: IO_EVT_ACCEPT
						]
						io/pin-memory data/send-buf

						OS-Sleep 100
						return true
					]

					either all [
						extra-buf/BufferType = 5
						extra-buf/cbBuffer > 0
					][
						;-- part of data is digested and is not needed to be supplied again.
						;-- So we shift our leftover into the beginning
						move-memory pbuffer pbuffer + (buflen - extra-buf/cbBuffer) extra-buf/cbBuffer
						buflen: extra-buf/cbBuffer
						data/buf-len: buflen
						continue		;-- start all over again
					][return false]
				]
				SEC_E_INCOMPLETE_MESSAGE [
					socket/recv
						as-integer data/iocp/device
						pbuffer + buflen
						MAX_SSL_MSG_LENGTH * 2 - buflen
						as iocp-data! data
					data/iocp/state: state and (not IO_STATE_READING)
					return false
				]
				SEC_E_INCOMPLETE_CREDENTIALS [
					cert-client: get-credential data yes
					if null? cert-client [return false]
					create-credentials as SecHandle! :data/credential cert-client client? 
				]
				default [
					probe ["InitializeSecurityContext Error " ret]
					return false
				]
			]
		]
		false
	]

	encode: func [
		output	[byte-ptr!]
		buffer	[byte-ptr!]
		length	[integer!]
		data	[tls-data!]
		return: [integer!]
		/local
			buffer4	[secbuffer! value]
			buffer3	[secbuffer! value]
			buffer2	[SecBuffer! value]
			buffer1	[SecBuffer! value]
			sbin	[SecBufferDesc! value]
			size	[integer!]
			len2	[integer!]
			max-len	[integer!]
			status	[integer!]
			out-sz	[integer!]
	][
		copy-memory output + data/ctx-header buffer length
		size: 0
		out-sz: 0
		max-len: data/ctx-max-msg
		while [size < length][
			len2: length - size
			if len2 > max-len [len2: max-len]

			buffer1/BufferType: 7		;-- SECBUFFER_STREAM_HEADER
			buffer1/cbBuffer: data/ctx-header
			buffer1/pvBuffer: output

			output: output + data/ctx-header
			buffer2/BufferType: 1		;-- SECBUFFER_DATA
			buffer2/cbBuffer: len2
			buffer2/pvBuffer: output

			buffer3/BufferType: 6		;-- SECBUFFER_STREAM_TRAILER
			buffer3/cbBuffer: data/ctx-trailer
			buffer3/pvBuffer: output + len2

			buffer4/BufferType: 0		;-- SECBUFFER_EMPTY
			buffer4/cbBuffer: 0
			buffer4/pvBuffer: null

			sbin/ulVersion: 0
			sbin/pBuffers: :buffer1
			sbin/cBuffers: 4

			status: platform/SSPI/EncryptMessage
				as SecHandle! :data/security
				0
				sbin
				0
			if status <> 0 [return 0]
			out-sz: buffer1/cbBuffer + buffer2/cbBuffer + buffer3/cbBuffer
			size: size + len2
		]
		out-sz
	]

	send: func [
		sock		[integer!]
		buffer		[byte-ptr!]
		length		[integer!]
		data		[tls-data!]
		return:		[integer!]
		/local
			wsbuf	[WSABUF! value]
			err		[integer!]
			outbuf	[byte-ptr!]
			s		[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tls/send"]]

		s: as series! data/send-buf/value
		outbuf: as byte-ptr! s/offset
		length: encode outbuf buffer length data
		wsbuf/len: length
		wsbuf/buf: outbuf
		data/iocp/event: IO_EVT_WRITE

		unless zero? WSASend sock :wsbuf 1 null 0 as OVERLAPPED! data null [	;-- error
			err: GetLastError
			either ERROR_IO_PENDING = err [return ERROR_IO_PENDING][return -1]
		]
		0
	]

	decode: func [
		data	[tls-data!]
		return: [logic!]
		/local
			bin	[red-binary!]
			s	[series!]
			len [integer!]
			buffer4	[secbuffer! value]
			buffer3	[secbuffer! value]
			buffer2	[SecBuffer! value]
			buffer1	[SecBuffer! value]
			sbin	[SecBufferDesc! value]
			size	[integer!]
			len2	[integer!]
			max-len	[integer!]
			status	[integer!]
			out-sz	[integer!]
			buf		[SecBuffer!]
			i		[integer!]
			pbuffer	[byte-ptr!]
	][
		bin: as red-binary! (object/get-values as red-object! :data/port) + port/field-data
		s: GET_BUFFER(bin)
		pbuffer: as byte-ptr! s/offset

		buffer1/BufferType: 1		;-- SECBUFFER_DATA
		buffer1/cbBuffer: data/iocp/transferred
		buffer1/pvBuffer: as byte-ptr! s/offset
 
		buffer2/BufferType: 0
		buffer3/BufferType: 0
		buffer4/BufferType: 0		;-- SECBUFFER_EMPTY

		sbin/ulVersion: 0
		sbin/pBuffers: :buffer1
		sbin/cBuffers: 4

		status: platform/SSPI/DecryptMessage
			as SecHandle! :data/security
			sbin
			0
			null
		switch status [
			0	[		;-- Wow! success!
				len: 0
				buf: :buffer1
				loop 3 [
					buf: buf + 1
					if buf/BufferType = 1 [
						move-memory (as byte-ptr! s/offset) + len buf/pvBuffer buf/cbBuffer
						len: len + buf/cbBuffer
					]
				]
				buf: :buffer1
				loop 3 [
					buf: buf + 1
					if buf/BufferType = 5 [	;-- some leftover, save it
						0
					]
				]
			]
			SEC_E_INCOMPLETE_MESSAGE [		;-- needs more data
				len2: data/buf-len + data/iocp/transferred
				data/buf-len: len2
				socket/recv
					as-integer data/iocp/device
					pbuffer + len2
					s/size - len2
					as iocp-data! data
				return false
			]
			00090317h [		;-- SEC_I_CONTEXT_EXPIRED
				data/iocp/event: IO_EVT_CLOSE
				len: 0
			]
			default [probe ["error in tls/decode: " as int-ptr! status]]
		]
		data/iocp/transferred: len
		true
	]
]