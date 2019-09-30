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
#define SEC_I_CONTINUE_NEEDED			00090312h
#define SEC_E_INCOMPLETE_MESSAGE		80090318h
#define SEC_E_INCOMPLETE_CREDENTIALS	00090320h
#define SEC_I_RENEGOTIATE				00090321h

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
	cert-ctx	[CERT_CONTEXT]			;-- certificate context
]

tls: context [

	sspi-flags-client: ISC_REQ_SEQUENCE_DETECT or
		ISC_REQ_REPLAY_DETECT or
		ISC_REQ_CONFIDENTIALITY or
		ISC_REQ_EXTENDED_ERROR or
		ISC_REQ_ALLOCATE_MEMORY or
		ISC_REQ_MANUAL_CRED_VALIDATION or
		ISC_REQ_STREAM

	sspi-flags-server: ISC_REQ_SEQUENCE_DETECT or
		ISC_REQ_REPLAY_DETECT or
		ISC_REQ_CONFIDENTIALITY or
		ISC_REQ_ALLOCATE_MEMORY or
		ASC_REQ_EXTENDED_ERROR or
		ASC_REQ_STREAM

	create-credentials: func [
		client?		[logic!]			;-- Is it client side?
		cert-ctx	[CERT_CONTEXT]
		hcred		[SecHandle!]		;-- OUT: Security handle in hcred
		return:		[integer!]			;-- return status code
		/local
			scred	[SCHANNEL_CRED value]
			status	[integer!]
			expiry	[tagFILETIME value]
			flags	[integer!]
			ptr		[ptr-value!]
	][
		;zero-memory as byte-ptr! :scred size? SCHANNEL_CRED
		;scred/dwVersion: 4		;-- SCHANNEL_CRED_VERSION

		;if cert-ctx <> null [
		;	ptr/value: as int-ptr! cert-ctx
		;	scred/cCreds: 1
		;	scred/paCred: as int-ptr! :ptr
		;]

		;flags: SCH_USE_STRONG_CRYPTO
		;if client? [flags: flags or SCH_CRED_NO_DEFAULT_CREDS]
		;scred/dwFlags: flags

		;either client? [flags: 2][flags: 1]		;-- Credential use flags
		;status: platform/SSPI/AcquireCredentialsHandleW
		;	null		;-- name of principal
		;	#u16 "Microsoft Unified Security Protocol Provider"
		;	flags
		;	null
		;	as int-ptr! :scred
		;	null
		;	null
		;	hcred
		;	:expiry

		;if status <> 0 [
		;	status: GetLastError
		;	either status = 8009030Dh [		;-- SEC_E_UNKNOWN_CREDENTIALS
		;		status: -1					;-- needs administrator rights
		;	][
		;		status: -2
		;	]
		;]
		status
	]

	create: func [
		data		[tls-data!]
		/local
			buf		[red-binary!]
	][
		;buf: as red-binary! (object/get-values data/port) + port/field-data
		;if TYPE_OF(buf) <> TYPE_BINARY [
		;	binary/make-at as cell! buf MAX_SSL_MSG_LENGTH * 2
		;]
		;data/send-buf: buf/node
	]

	release-context: func [
		data	[tls-data!]
	][
		;if SecIsValidHandle(data/credential) [
		;	platform/SSPI/FreeCredentialsHandle data/credential
		;]
		;platform/SSPI/DeleteSecurityContext data/security
	]

	negotiate: func [
		data		[tls-data!]
		return:		[logic!]
		/local
			indesc		[SecBufferDesc! value]
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
			s			[series!]
			client?		[logic!]
			state		[integer!]
	][
;		state: data/iocp/state
;		client?: state and IO_STATE_CLIENT <> 0

;		;-- allocate 2 SecBuffer! on stack for buffer
;		inbuf-1: as SecBuffer! system/stack/allocate (size? SecBuffer!) >> 1
;		inbuf-2: inbuf-1 + 1
;		outbuf-1: as SecBuffer! system/stack/allocate (size? SecBuffer!) >> 1
;		outbuf-2: outbuf-1 + 1

;		buflen: data/buf-len

;		if data/iocp/event = IO_EVT_READ [
;			buflen: data/iocp/transferred
;		]

;		if state and IO_STATE_READING <> 0 [
;			s: as series! data/send-buf/value
;			pbuffer: as byte-ptr! s/offset
;			data/iocp/state: state and (not IO_STATE_READING)
;			socket/recv
;						as-integer data/iocp/device
;						pbuffer + buflen
;						MAX_SSL_MSG_LENGTH * 2 - buflen
;						as iocp-data! data 
;			return false
;		]

;		forever [
;			;-- setup input buffers
;			inbuf-1/BufferType: 2		;-- SECBUFFER_TOKEN
;			inbuf-1/cbBuffer: buflen
;			inbuf-2/BufferType: 0		;-- SECBUFFER_EMPTY
;			inbuf-2/cbBuffer: 0
;			inbuf-2/pvBuffer: null
;			indesc/ulVersion: 0
;			indesc/cBuffers: 2
;			indesc/pBuffers: inbuf-1

;			;-- setup output buffers
;			outbuf-1/BufferType: 2
;			outbuf-1/cbBuffer: 0
;			outbuf-1/pvBuffer: null
;			outdesc/ulVersion: 0
;			outdesc/cBuffers: 1
;			outdesc/pBuffers: outbuf-1

;			pbuffer: null
;			either zero? data/security [
;				create data
;				sec-handle: null
;				sec-handle2: as SecHandle! :data/security
;				if client? [indesc: null]
;				inbuf-1/pvBuffer: null
;				io/pin-memory data/send-buf
;			][
;				sec-handle: as SecHandle! :data/security
;				sec-handle2: null
;				s: as series! data/send-buf/value
;				pbuffer: as byte-ptr! s/offset
;				inbuf-1/pvBuffer: pbuffer
;			]

;			attr: 0
;			either client? [
;				ret: platform/SSPI/InitializeSecurityContext
;					data/credential
;					sec-handle
;					0
;					sspi-flags-client
;					0
;					10h			;-- SECURITY_NATIVE_DREP
;					indesc
;					0
;					sec-handle2
;					outdesc
;					:attr
;					:expiry
;			][
;				outbuf-2/BufferType: 0		;-- SECBUFFER_EMPTY
;				outbuf-2/cbBuffer: 0
;				outbuf-2/pvBuffer: null
;				outdesc/cBuffers: 2
;				ret: platform/SSPI/AcceptSecurityContext
;					data/credential
;					sec-handle
;					indesc
;					sspi-flags-server
;					0
;					sec-handle2
;					outdesc
;					:attr
;					:expiry
;			]

;probe ["ret: " as int-ptr! ret]
;			switch ret [
;				SEC_I_CONTINUE_NEEDED [
;					;-- this error means that information we provided in contextData is not enough to generate SSL token.
;					;-- We'll ask other party for more information by sending our unfinished "token",
;					;-- and then we will start all over - from the response that we'll get from the other party.
;					extra-buf: inbuf-2
;					if all [
;						not client?
;						inbuf-2/BufferType <> 5		;-- SECBUFFER_EXTRA
;					][
;						extra-buf: outbuf-2
;					]
;					if all [
;						extra-buf/BufferType = 5
;						extra-buf/cbBuffer > 0
;					][
;						;-- part of data is digested and is not needed to be supplied again.
;						;-- So we shift our leftover into the beginning
;						move-memory pbuffer pbuffer + (buflen - extra-buf/cbBuffer) extra-buf/cbBuffer
;						buflen: cbBuffer
;						data/buf-len: buflen
;						continue		;-- start all over again
;					]
;					if all [
;						outbuf-1/cbBuffer > 0
;						outbuf-1/pvBuffer <> null
;					][
;						if 0 > socket/send
;							as-integer data/iocp/device
;							outbuf-1/pvBuffer
;							outbuf-1/cbBuffer
;							as iocp-data! data [
;							platform/SSPI/FreeContextBuffer outbuf-1/pvBuffer
;							release-context data
;						]
;						data/iocp/state: state or IO_STATE_READING
;					]
;				]
;				SEC_E_INCOMPLETE_MESSAGE [
;					socket/recv
;						as-integer data/iocp/device
;						pbuffer + buflen
;						MAX_SSL_MSG_LENGTH * 2 - buflen
;						as iocp-data! data
;					return false
;				]
;				SEC_I_INCOMPLETE_CREDENTIALS [return false]
;				0	[		;-- S_OK
;					either client? [
;						data/event: IO_EVT_CONNECT
;					][
;						data/event: IO_EVT_ACCEPT
;					]
;					return true
;				]
;				default [
;					probe ["InitializeSecurityContext Error " ret]
;					return false
;				]
;			]
;		]
		false
	]
]