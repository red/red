Red/System [
	Title:	"cryptographic API"
	Author: "Qingtian Xie" "Yongzhao Huang"
	File: 	%crypto.reds
	Tabs:	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

crypto: context [

	_tcp:		0
	_md5:		0
	_sha1:		0
	_crc32: 	0
	_adler32:	0
	_sha256:	0
	_sha384:	0
	_sha512:	0
	_hash:		0
	errno:		as int-ptr! 0

	init: does [
		_tcp:		symbol/make "tcp"
		_md5:		symbol/make "md5"
		_sha1:		symbol/make "sha1"
		_crc32: 	symbol/make "crc32"
		_adler32:	symbol/make "adler32"
		_sha256:	symbol/make "sha256"
		_sha384:	symbol/make "sha384"
		_sha512:	symbol/make "sha512"
		_hash:		symbol/make "hash"
		#if OS <> 'Windows [errno: get-errno-ptr]
	]

	#enum crypto-algorithm! [
		ALG_CRC_IP
		ALG_CRC32
		ALG_MD5
		ALG_SHA1
		ALG_SHA256
		ALG_SHA384
		ALG_SHA512
		ALG_HASH
	]

	crc32-table: as int-ptr! 0

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


	alg-digest-size: func [
		"Return the size of a digest result for a given algorithm."
		type	[integer!]
		return:	[integer!]
	][
		switch type [
			ALG_MD5		[16]
			ALG_SHA1    [20]
			ALG_SHA256  [32]
			ALG_SHA384  [48]
			ALG_SHA512  [64]
			default		[ 0]
		]
	]

	alg-from-symbol: func [
		"Return the algorithm ID for a given symbol."
		sym		[integer!]
		return: [integer!]
	][
		case [
			sym = _tcp    [ALG_CRC_IP]
			sym = _crc32  [ALG_CRC32]
			sym = _md5    [ALG_MD5]
			sym = _sha1   [ALG_SHA1]
			sym = _sha256 [ALG_SHA256]
			sym = _sha384 [ALG_SHA384]
			sym = _sha512 [ALG_SHA512]
		]
	]

	CRC32: func [
		"Calculate the CRC32b value for the input data."
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

	CRC_IP: func [
		"Calculate IP CRC per RFC1071"
		data	[byte-ptr!]
		len		[integer!]
		return:	[integer!]
		/local
			sum [integer!]
	][
		sum: 0

		while [len > 1][
			;-- Operate on 2 separate bytes. We don't have a UINT16 type.
			sum: sum + (((as-integer data/1) << 8) or as-integer data/2)
			data: data + 2
			len: len - 2
		]

		;-- Add left-over byte, if any
		if len > 0 [sum: sum + (as-integer data/value)]

		;-- Fold 32-bit sum to 16 bits
		sum: (sum >> 16) + (sum and FFFFh)		;-- Add high-16 to low-16
		sum: sum + (sum >> 16)					;-- Add carry
		FFFFh and not sum						;-- 1's complement, then truncate
	]

	get-hmac: func [
		data		[byte-ptr!]
		len			[integer!]
		key-data	[byte-ptr!]
		key-len		[integer!]
		alg-sym		[integer!]	"Algorithm symbol value. e.g., _crc32"
		return:		[byte-ptr!]
	][
		either any [alg-sym = _crc32  alg-sym = _tcp  alg-sym = _hash alg-sym = _adler32][
			print-line "The selected algorithm doesn't support HMAC calculation"
			return as byte-ptr! ""
		][
			calc-hmac  data len  key-data key-len  alg-from-symbol alg-sym
		]
	]

	; https://www.ietf.org/rfc/rfc4868.txt
	calc-hmac: func [
		data		[byte-ptr!]						;-- message
		len			[integer!]
		key-data	[byte-ptr!]						;-- key/password
		key-len		[integer!]
		type		[crypto-algorithm!]
		return:		[byte-ptr!]
		/local
			block-size	[integer!]
			n			[integer!]
			hash-len	[integer!]					;-- set based on the algorithm used
			hkey-data	[byte-ptr!]					;-- hashed key (used if key > block-size)
			ipad		[byte-ptr!]					;-- inner padding - key XORd with ipad
			opad		[byte-ptr!]					;-- outer padding - key XORd with opad
			idata		[byte-ptr!]					;-- holds ipad+data for hashing
			odata		[byte-ptr!]					;-- holds opad+ihash for hashing
			ihash		[byte-ptr!]					;-- hash of ipad+data
			ohash		[byte-ptr!]					;-- hash of opad+ihash
	][
		block-size: switch type [
			ALG_SHA384 ALG_SHA512 [128]
			default [64]
		]
		hash-len: alg-digest-size type

		hkey-data: null
		if key-len > block-size [					;-- Keys longer than block size get digested
			key-data: get-digest key-data key-len type
			hkey-data: key-data						;-- Use this to free hashed key later
			key-len: hash-len
		]

		ipad: allocate block-size					;-- Set up inner and outer padding blocks
		opad: allocate block-size
		set-memory ipad #"^@" block-size			;-- Zero them out
		set-memory opad #"^@" block-size
		copy-memory ipad key-data key-len			;-- Put the key data in them
		copy-memory opad key-data key-len

		n: 0
		loop block-size [							;-- XOR the padding blocks with their fixed byte value
			n: n + 1
			ipad/n: ipad/n xor #"^(36)"
			opad/n: opad/n xor #"^(5C)"
		]

		;-- Pseudocode of what we want to do to get the final result:
		;		return hash(join opad hash(join ipad data))

		idata: allocate block-size + len					;-- Space for ipad + message-data
		set-memory idata #"^@" block-size + len
		copy-memory idata ipad block-size					;-- Put ipad data in
		copy-memory (idata + block-size) data len			;-- Append message data

		ihash: get-digest idata (block-size + len) type		;-- Hash ipad+data

		odata: allocate block-size + hash-len				;-- Space for opad + hash result
		set-memory odata #"^@" block-size + hash-len
		copy-memory odata opad block-size					;-- Put opad data in
		copy-memory (odata + block-size) ihash hash-len		;-- Append ipad + message-data hash result

		ohash: get-digest odata (block-size + hash-len) type	;-- Hash opad + hash(ipad data)

		if hkey-data <> null [free hkey-data]				;-- Only done if the key was big and got hashed

		free ipad
		free opad
		free idata
		free odata
		free ihash

		ohash												;-- Caller MUST free this
	]

	HASH_STRING: func [
		;"Return a case insensitive hash value"
		;"Return a case sensitive hash value"
		data	[byte-ptr!]
		len		[integer!]	"Data length"
		size	[integer!]	"Size of the hash table."
		return:	[integer!]
	][
		print-line "** /hash support not yet implemented; algorithm TBD."
		if size < 1 [size: 1]
		return 0
	]

	known-method?: func [
		"Return true if the given symbol is supported."
		sym		[integer!]
		return: [logic!]
	][
		any [
			sym = _tcp
			sym = _crc32
			sym = _adler32
			sym = _md5
			sym = _sha1
			sym = _sha256
			sym = _sha384
			sym = _sha512
			sym = _hash
		]
	]

	#define A32-BASE 65521
	#define A32-NMAX 5552

	adler32: func [
		data    [byte-ptr!]
		length  [integer!]
		return: [integer!]
		/local
			buf  [byte-ptr!]
			s1   [integer!]
			s2 	 [integer!]
			i    [integer!]
			k    [integer!]
	][
		buf: data
		s1: 1
		s2: 0
		while [length > 0] [
			if length < A32-NMAX [
				k: length
			]
			if length >= A32-NMAX [
				k: A32-NMAX
			]
			i: k / 16
			if i <> 0 [
				until [
					s1: s1 + (as-integer buf/1)
					s2: s2 + s1
					s1: s1 + (as-integer buf/2)
					s2: s2 + s1
					s1: s1 + (as-integer buf/3)
					s2: s2 + s1
					s1: s1 + (as-integer buf/4)
					s2: s2 + s1
					s1: s1 + (as-integer buf/5)
					s2: s2 + s1
					s1: s1 + (as-integer buf/6)
					s2: s2 + s1
					s1: s1 + (as-integer buf/7)
					s2: s2 + s1
					s1: s1 + (as-integer buf/8)
					s2: s2 + s1
					s1: s1 + (as-integer buf/9)
					s2: s2 + s1
					s1: s1 + (as-integer buf/10)
					s2: s2 + s1
					s1: s1 + (as-integer buf/11)
					s2: s2 + s1
					s1: s1 + (as-integer buf/12)
					s2: s2 + s1
					s1: s1 + (as-integer buf/13)
					s2: s2 + s1
					s1: s1 + (as-integer buf/14)
					s2: s2 + s1
					s1: s1 + (as-integer buf/15)
					s2: s2 + s1
					s1: s1 + (as-integer buf/16)
					s2: s2 + s1
					i: i - 1
					buf: buf + 16
					i = 0
				]
			]
			i: k % 16
			while [i <> 0] [
				s1: s1 + as integer! buf/value
				buf: buf + 1
				s2: s2 + s1
				i: i - 1
			]

			s1: s1 % A32-BASE
			s2: s2 % A32-BASE

			length: length - k
		]
		k: s2 << 16
		k or s1
	]

	#if OS <> 'Windows [
	#import [
		LIBC-file cdecl [
			open2: "open" [
				path	[c-string!]
				flags	[integer!]
				return: [integer!]
			]
			_read:	"read" [
				fd		[integer!]
				buf	    [byte-ptr!]
				size	[integer!]
				return:	[integer!]
			]
			_close:	"close" [
				fd		[integer!]
				return:	[integer!]
			]
		]
	]

	#case [
		any [OS = 'FreeBSD OS = 'macOS] [
			#import [
			LIBC-file cdecl [
				get-errno-ptr: "__error" [
					return: [int-ptr!]
				]
			]]
		]
		true [
			#import [
			LIBC-file cdecl [
				get-errno-ptr: "__errno_location" [
					return: [int-ptr!]
				]
			]]
		]
	]

	urandom: func [
		buffer	[byte-ptr!]							;-- buffer to receive data
		size	[integer!]							;-- size of the buffer
		return: [logic!]
		/local
			fd	[integer!]
			n	[integer!]
	][
		fd: open2 "/dev/urandom" O_RDONLY
		if fd < 0 [return false]

		;@@ cache fd
		while [size > 0][
			until [
			 	n: _read fd buffer size
			 	not all [n < 0 errno/value = 4]		;-- 4: EINTR
			]
			if n < 0 [
				_close fd
				return false
			]
			buffer: buffer + n
			size: size - n
		]
		_close fd
		true
	]]

	#case [
	OS = 'Windows [
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
				CryptGenRandom: "CryptGenRandom" [
					handle		[integer!]
					size		[integer!]
					buffer		[byte-ptr!]
					return:		[logic!]
				]
			]
			#if debug? = yes [
				"kernel32.dll" stdcall [
					GetLastError: "GetLastError" [
						return:		[integer!]
					]
				]
			]
		]

		;#define PROV_RSA_FULL 			1                       ;-- Doesn't provide beyond SHA1
		#define PROV_RSA_AES            24
		#define CRYPT_VERIFYCONTEXT     F0000000h				;-- Says we're using ephemeral, not stored, keys
		#define HP_HASHVAL              0002h  					;-- Flag saying get/set-hash param is a hash value
		#define CALG_MD5				00008003h
		#define CALG_SHA1				00008004h
		#define CALG_SHA_256	        0000800Ch
		#define CALG_SHA_384	        0000800Dh
		#define CALG_SHA_512	        0000800Eh

		provider: 0
		init-provider: does [CryptAcquireContext :provider null null PROV_RSA_AES CRYPT_VERIFYCONTEXT]

		urandom: func [
			buffer	[byte-ptr!]							;-- buffer to receive data
			size	[integer!]							;-- size of the buffer
			return: [logic!]
		][
			CryptGenRandom provider size buffer
		]

		get-digest: func [
			data	[byte-ptr!]
			len		[integer!]
			type	[crypto-algorithm!]
			return:	[byte-ptr!]							;-- caller should free it
			/local
				handle	[integer!]
				hash	[byte-ptr!]
				size	[integer!]
		][
			; The hash buffer needs to be big enough to hold the longest result.
			hash: allocate 64							;-- caller should free it
			handle: 0
			size: alg-digest-size type
			type: switch type [							;-- Convert type from enum to Windows code
				ALG_MD5     [CALG_MD5]
				ALG_SHA1    [CALG_SHA1]
				ALG_SHA256  [CALG_SHA_256]
				ALG_SHA384  [CALG_SHA_384]
				ALG_SHA512  [CALG_SHA_512]
				default [
					fire [TO_ERROR(script invalid-arg) type]
					0	;-- Either need to leave out this default or make the compiler happy by not changing type's datatype.
				]
			]

			CryptCreateHash provider type null 0 :handle
			CryptHashData handle data len 0
			CryptGetHashParam handle HP_HASHVAL hash :size 0
			CryptDestroyHash handle
			;CryptReleaseContext provider 0				;@@ release it when exit Red
			hash
		]
	]
	all [OS = 'Linux target <> 'ARM][
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
				_write: "write" [
					fd		[integer!]
					buffer	[c-string!]
					count	[integer!]
					return: [integer!]
				]
				syscall: "syscall" [
					[variadic]
					return:	[integer!]
				]
			]
		]

		#define SYS_getrandom			355		;-- system call for x86
		#define GRND_NONBLOCK			1
		#define GRND_RANDOM				2
		#define AF_ALG 					38
		#define SOCK_SEQPACKET 			5

		has_getrandom?: yes						;-- need linux kernel 3.17 or newer

		getrandom: func [
			buffer		[byte-ptr!]
			size		[integer!]
			blocking?	[logic!]
			return:		[integer!]				;-- 1: success, 0: no getrandom(), -1: error
			/local
				n		[integer!]
				flags	[integer!]
				err		[integer!]
		][
			unless has_getrandom? [return 0]

			flags: either blocking? [0][GRND_NONBLOCK]
			while [size > 0][
				n: syscall [SYS_getrandom buffer size flags]

				err: errno/value
				if n < 0 [
					if any [err = ENOSYS err = EPERM][
						has_getrandom?: no
						return 0
					]
					if all [err = EAGAIN not blocking?][
						return 0
					]
					if err = EINTR [
						;@@ check SIGINT, that means it's from keyboard, should return -1
						continue
					]
					return -1
				]
				buffer: buffer + n
				size: size - n
			]
			1
		]

		;struct sockaddr_alg {					;-- 88 bytes
		;    __u16   salg_family;
		;    __u8    salg_type[14];				;-- offset: 2
		;    __u32   salg_feat;					;-- offset: 16
		;    __u32   salg_mask;
		;    __u8    salg_name[64];				;-- offset: 24  See /proc/crypto and search for "name"
		;};

		get-digest: func [						;@@ use LIBCRYPTO if possible, a bit heavy to use kernel crypto here
			data		[byte-ptr!]
			len			[integer!]
			type		[integer!]
			return:		[byte-ptr!]				;-- caller should free it
			/local
				fd		[integer!]
				opfd	[integer!]
				sa		[byte-ptr!]
				alg		[c-string!]
				hash	[byte-ptr!]
				size	[integer!]
		][
			; The hash buffer needs to be big enough to hold the longest result.
			hash: allocate 64					;-- caller should free it
			sa: allocate 88
			set-memory sa #"^@" 88
			sa/1: as-byte AF_ALG
			copy-memory sa + 2 as byte-ptr! "hash" 4
			alg: switch type [							;-- Convert type from enum to alg name
				ALG_MD5     ["md5"]
				ALG_SHA1    ["sha1"]
				ALG_SHA256  ["sha256"]
				ALG_SHA384  ["sha384"]
				ALG_SHA512  ["sha512"]
				default [
					fire [TO_ERROR(script invalid-arg) type]
					""	;-- Either need to leave out this default or make the compiler happy by not changing type's datatype.
				]
			]
			copy-memory sa + 24 as byte-ptr! alg length? alg
			fd: socket AF_ALG SOCK_SEQPACKET 0
			sock-bind fd sa 88
			opfd: accept fd null null
			_write opfd as c-string! data len
			_read opfd hash alg-digest-size type
			_close opfd
			_close fd
			free sa
			hash
		]
	]
	true [											;-- macOS,Android,Syllable,FreeBSD,Linux-ARM
		;-- Using OpenSSL Crypto library
		#switch OS [
			macOS [
				#define LIBCRYPTO-file "libcrypto.dylib"
			]
			FreeBSD [
				#define LIBCRYPTO-file "libcrypto.so.8"
			]
			RPi [
				#define LIBCRYPTO-file "libcrypto.so.1.1"
			]
			#default [
				#define LIBCRYPTO-file "libcrypto.so.1.0.2"
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
				compute-sha256: "SHA256" [
					data	[byte-ptr!]
					len		[integer!]
					output	[byte-ptr!]
					return: [byte-ptr!]
				]
				compute-sha384: "SHA384" [
					data	[byte-ptr!]
					len		[integer!]
					output	[byte-ptr!]
					return: [byte-ptr!]
				]
				compute-sha512: "SHA512" [
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
			return:		[byte-ptr!]						;-- caller should free it
			/local
				hash	[byte-ptr!]
		][
			hash: allocate 64							;-- caller should free it
			switch type [
				ALG_MD5     [compute-md5 data len hash]
				ALG_SHA1    [compute-sha1 data len hash]
				ALG_SHA256  [compute-sha256 data len hash]
				ALG_SHA384  [compute-sha384 data len hash]
				ALG_SHA512  [compute-sha512 data len hash]
				default [
					fire [TO_ERROR(script invalid-arg) type]
					0	;-- Either need to leave out this default or make the compiler happy by not changing type's datatype.
				]
			]
			hash
		]
	]]
]
