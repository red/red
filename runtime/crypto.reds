Red/System [
	Title:	"cryptographic API"
	Author: "Qingtian Xie"
	File: 	%crypto.reds
	Tabs:	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

crypto: context [

	_md5:	0
	_sha1:	0
	_crc32: 0

	init: does [
		_md5:	symbol/make "md5"
		_sha1:	symbol/make "sha1"
		_crc32: symbol/make "crc32"
	]

	#enum crypto-algorithm! [
		ALG_CRC32
		ALG_MD5
		ALG_SHA1
	]

	crc32-table: declare int-ptr!
	crc32-table: null

	make-crc32-table: func [
		/local
			c	[integer!]
			n	[integer!]
			k	[integer!]
	][
		n: 1
		crc32-table: as int-ptr! allocate 256 * size? integer!
		until [
			c: n - 1
			k: 0
			until [
				c: either zero? (c and 1) [c >>> 1][c >>> 1 xor EDB88320h]
				k: k + 1
				k = 8
			]
			crc32-table/n: c
			n: n + 1
			n = 257
		]
	]

	CRC32: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[integer!]
		/local
			c	[integer!]
			n	[integer!]
			i	[integer!]
	][
		c: FFFFFFFFh
		n: 1

		if crc32-table = null [make-crc32-table]

		len: len + 1
		while [n < len][
			i: c xor (as-integer data/n) and FFh + 1
			c: c >>> 8 xor crc32-table/i
			n: n + 1
		]

		not c
	]

	MD5: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[byte-ptr!]
	][
		get-digest data len ALG_MD5
	]

	SHA1: func [
		data	[byte-ptr!]
		len		[integer!]
		return:	[byte-ptr!]
	][
		get-digest data len ALG_SHA1
	]

#switch OS [
	Windows [
		#import [
			"advapi32.dll" stdcall [
				CryptAcquireContext: "CryptAcquireContextW" [
					handle-ptr	[int-ptr!]
					container	[c-string!]
					provider	[c-string!]
					type		[integer!]
					flags		[integer!]
					return:		[integer!]
				]
				CryptCreateHash: "CryptCreateHash" [
					provider 	[integer!]
					algorithm	[integer!]
					hmackey		[int-ptr!]
					flags		[integer!]
					handle-ptr	[int-ptr!]
					return:		[integer!]
				]
				CryptHashData:	"CryptHashData" [
					handle		[integer!]
					data		[byte-ptr!]
					dataLen		[integer!]
					flags		[integer!]
					return:		[integer!]
				]
				CryptGetHashParam: "CryptGetHashParam" [
					handle		[integer!]
					param		[integer!]
					buffer		[byte-ptr!]
					written		[int-ptr!]
					flags		[integer!]
					return:		[integer!]
				]
				CryptDestroyHash:	"CryptDestroyHash" [
					handle		[integer!]
					return:		[integer!]
				]
				CryptReleaseContext: "CryptReleaseContext" [
					handle		[integer!]
					flags		[integer!]
					return:		[integer!]
				]
			]
		]

		#define PROV_RSA_FULL 			1
		#define CRYPT_VERIFYCONTEXT     F0000000h
		#define HP_HASHVAL              0002h  					;-- Get hash value
		#define CALG_MD5				00008003h
		#define CALG_SHA1				00008004h

		get-digest: func [
			data	[byte-ptr!]
			len		[integer!]
			type	[integer!]
			return:	[byte-ptr!]
			/local
				provider [integer!]
				handle [integer!]
				hash	[byte-ptr!]
				size	[integer!]
		][
			hash: as byte-ptr! "0000000000000000000"
			provider: 0
			handle: 0
			size: either type = ALG_MD5 [type: CALG_MD5 16][type: CALG_SHA1 20]
			CryptAcquireContext :provider null null PROV_RSA_FULL CRYPT_VERIFYCONTEXT
			CryptCreateHash provider type null 0 :handle
			CryptHashData handle data len 0
			CryptGetHashParam handle HP_HASHVAL hash :size 0
			CryptDestroyHash handle
			CryptReleaseContext provider 0
			hash
		]
	]
	Linux [
		;-- Using User-space interface for Kernel Crypto API
		;-- Exists in kernel starting from Linux 2.6.38
		#import [
			LIBC-file cdecl [
				socket: "socket" [
					family	[integer!]
					type	[integer!]
					protocl	[integer!]
					return: [integer!]
				]
				sock-bind: "bind" [
					fd 		[integer!]
					addr	[byte-ptr!]
					addrlen [integer!]
					return:	[integer!]
				]
				accept:	"accept" [
					fd		[integer!]
					addr	[byte-ptr!]
					addrlen	[int-ptr!]
					return:	[integer!]
				]
				read:	"read" [
					fd		[integer!]
					buf	    [byte-ptr!]
					size	[integer!]
					return:	[integer!]
				]
				close:	"close" [
					fd		[integer!]
					return:	[integer!]
				]
			]
		]

		#define AF_ALG 					38
		#define SOCK_SEQPACKET 			5

		;struct sockaddr_alg {					;-- 88 bytes
		;    __u16   salg_family;
		;    __u8    salg_type[14];				;-- offset: 2
		;    __u32   salg_feat;					;-- offset: 16
		;    __u32   salg_mask;
		;    __u8    salg_name[64];				;-- offset: 24
		;};

		get-digest: func [
			data		[byte-ptr!]
			len			[integer!]
			type		[integer!]
			return:		[byte-ptr!]
			/local
				fd		[integer!]
				opfd	[integer!]
				sa		[byte-ptr!]
				alg		[c-string!]
				hash	[byte-ptr!]
				size	[integer!]
		][
			hash: as byte-ptr! "0000000000000000000"
			sa: allocate 88
			set-memory sa #"^@" 88
			sa/1: as-byte AF_ALG
			copy-memory sa + 2 as byte-ptr! "hash" 4
			either type = ALG_MD5 [
				alg: "md5"
				size: 16
			][
				alg: "sha1"
				size: 20
			]
			copy-memory sa + 24 as byte-ptr! alg 4
			fd: socket AF_ALG SOCK_SEQPACKET 0
			sock-bind fd sa 88
			opfd: accept fd null null
			write opfd as c-string! data len
			read opfd hash size
			close opfd
			close fd
			free sa
			hash
		]
	]
	#default [											;-- MacOSX,Android,Syllable,FreeBSD
		;-- Using OpenSSL Crypto library
		#switch OS [
			MacOSX [
				#define LIBCRYPTO-file "libcrypto.dylib"
			]
			FreeBSD [
				#define LIBCRYPTO-file "libcrypto.so.7"
			]
			#default [
				#define LIBCRYPTO-file "libcrypto.so"
			]
		]
		#import [
			LIBCRYPTO-file cdecl [
				compute-md5: "MD5" [
					data	[byte-ptr!]
					len		[integer!]
					output	[byte-ptr!]
					return: [byte-ptr!]
				]
				compute-sha1: "SHA1" [
					data	[byte-ptr!]
					len		[integer!]
					output	[byte-ptr!]
					return: [byte-ptr!]
				]
			]
		]

		;typedef struct MD5state_st						;-- 92 bytes
		;	{
		;	MD5_LONG A,B,C,D;
		;	MD5_LONG Nl,Nh;
		;	MD5_LONG data[MD5_LBLOCK];
		;	unsigned int num;
		;	} MD5_CTX;

		get-digest: func [
			data		[byte-ptr!]
			len			[integer!]
			type		[integer!]
			return:		[byte-ptr!]
			/local
				fd		[integer!]
				opfd	[integer!]
				sa		[byte-ptr!]
				alg		[c-string!]
				hash	[byte-ptr!]
				size	[integer!]
		][
			hash: as byte-ptr! "0000000000000000000"
			either type = ALG_MD5 [
				compute-md5 data len hash
			][
				compute-sha1 data len hash
			]
			hash
		]
	]]
]
