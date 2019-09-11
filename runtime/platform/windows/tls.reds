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

SChannel: context [
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
		zero-memory as byte-ptr! :scred size? SCHANNEL_CRED
		scred/dwVersion: 4		;-- SCHANNEL_CRED_VERSION

		if cert-ctx <> null [
			ptr/value: as int-ptr! cert-ctx
			scred/cCreds: 1
			scred/paCred: as int-ptr! :ptr
		]

		flags: SCH_USE_STRONG_CRYPTO
		if client? [flags: flags or SCH_CRED_NO_DEFAULT_CREDS]
		scred/dwFlags: flags

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
			status: GetLastError
			either status = 8009030Dh [		;-- SEC_E_UNKNOWN_CREDENTIALS
				status: -1					;-- needs administrator rights
			][
				status: -2
			]
		]
		status
	]

	negotiate: func [
		client?		[logic!]
		return:		[logic!]
		/local
			sspi-flags	[integer!]
			indesc		[SecBufferDesc! value]
			outdesc		[SecBufferDesc! value]
			outbufs		[SecBuffer! value]
			inbufs		[SecBuffer!]
	][
		;-- allocate 2 SecBuffer! on stack for inbufs
		inbufs: as SecBuffer! system/stack/allocate (size? SecBuffer!) >> 1

		sspi-flags: ISC_REQ_SEQUENCE_DETECT or
			ISC_REQ_REPLAY_DETECT or
			ISC_REQ_CONFIDENTIALITY or
			ISC_REQ_EXTENDED_ERROR or
			ISC_REQ_ALLOCATE_MEMORY or
			ISC_REQ_STREAM

		outdesc/ulVersion: 0
		outdesc/cBuffers: 1
		outdesc/pBuffers: :outbufs

		true
	]

	init: func [
		
	][
		
	]
]