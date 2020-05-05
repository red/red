Red/System [
	Title:	"Compress and Decompress functions for Red's runtime"
	Author: "bitbegin"
	File: 	%compress.reds
	Tabs:	4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- deflate used for Red's runtime

#include %deflate.reds

;-- gzip-uncompress function
#define GZIP_FTEXT		1
#define GZIP_FHCRC		2
#define GZIP_FEXTRA		4
#define GZIP_FNAME		8
#define GZIP_FCOMMENT	16

#enum INFLATE-GZIP! [
	INFLATE-GZIP-OK
	INFLATE-GZIP-LEN
	INFLATE-GZIP-HDR
]

#enum DEFLATE-GZIP! [
	DEFLATE-GZIP-OK
	DEFLATE-GZIP-LEN
	DEFLATE-GZIP-BUFF
]

#enum INFLATE-ZLIB! [
	INFLATE-ZLIB-OK
	INFLATE-ZLIB-LEN
	INFLATE-ZLIB-HDR
]

#enum DEFLATE-ZLIB! [
	DEFLATE-ZLIB-OK
	DEFLATE-ZLIB-LEN
	DEFLATE-ZLIB-BUFF
]

gzip-uncompress: func [
	dest		[byte-ptr!]
	dest-len	[int-ptr!]
	src			[byte-ptr!]
	src-len		[integer!]
	return:		[integer!]
	/local
		flga	[integer!]
		start	[byte-ptr!]
		xlen	[integer!]
		c		[integer!]
		crc		[integer!]
		p		[byte-ptr!]
		dlen	[integer!]
		res		[integer!]
][
	if src-len < 18 [
		return INFLATE-GZIP-HDR
	]

	;-- gzip header
	if any [
		src/1 <> #"^(1F)"
		src/2 <> #"^(8B)"
	][
		return INFLATE-GZIP-HDR
	]

	;--check method is deflate
	if src/3 <> #"^(08)" [
		return INFLATE-GZIP-HDR
	]

	flga: as integer! src/4
	;--check that reserved bits are zero
	if flga and E0h <> 0 [
		return INFLATE-GZIP-HDR
	]

	;--find start of compressed data
	;--skip base header of 10 bytes
	start: src + 10
	;--skip extra data if present
	if flga and GZIP_FEXTRA <> 0 [
		xlen: (as integer! start/2) << 8 + as integer! start/1
		if xlen > (src-len - 12) [
			return INFLATE-GZIP-HDR
		]
		start: start + xlen + 2
	]

	;--skip file comment if present
	if flga and GZIP_FNAME <> 0 [
		c: 0
		until [
			if start >= (src + src-len) [
				return INFLATE-GZIP-HDR
			]
			c: as integer! start/value
			start: start + 1
			c = 0
		]
	]

	if flga and GZIP_FCOMMENT <> 0 [
		c: 0
		until [
			if start >= (src + src-len) [
				return INFLATE-GZIP-HDR
			]
			c: as integer! start/value
			start: start + 1
			c = 0
		]
	]

	;--check header crc if present
	if flga and GZIP_FHCRC <> 0 [
		if start >= (src + src-len - 2) [
			return INFLATE-GZIP-HDR
		]
		crc: (as integer! start/2) << 8 + as integer! start/1
		c: crypto/CRC32 src as integer! start - src
		if crc <> (c and FFFFh) [
			return INFLATE-GZIP-HDR
		]
		start: start + 2
	]

	;--get decompressed length
	p: src + src-len - 4
	dlen: (as integer! p/4) << 24
	dlen: (as integer! p/3) << 16 + dlen
	dlen: (as integer! p/2) << 8 + dlen
	dlen: (as integer! p/1) + dlen

	if dlen > dest-len/1 [
		dest-len/1: dlen
		return INFLATE-GZIP-LEN
	]

	;--get crc32 of decompressed data
	p: src + src-len - 8
	crc: (as integer! p/4) << 24
	crc: (as integer! p/3) << 16 + crc
	crc: (as integer! p/2) << 8 + crc
	crc: (as integer! p/1) + crc

	c: as integer! src + src-len - start - 8
	res: deflate/uncompress dest dest-len start c
	if res <> 0 [return res]

	either dlen > dest-len/1 [
		return INFLATE-GZIP-HDR
	][dest-len/1: dlen]

	;--check CRC32 checksum
	c: crypto/CRC32 dest dlen
	if crc <> c [
		return INFLATE-GZIP-HDR
	]

	INFLATE-GZIP-OK
]

gzip-compress: func [
	dest		[byte-ptr!]
	dest-len	[int-ptr!]
	src			[byte-ptr!]
	src-len		[integer!]
	return:		[integer!]
	/local
		dstart	[byte-ptr!]
		dend	[byte-ptr!]
		res		[integer!]
		crc		[integer!]
][
	;-- check if data is already compressed
	if all [src-len > 2 src/1 = #"^(1F)" src/2 = #"^(8B)" src/3 = #"^(08)"][
		dest-len/value: src-len
		either dest-len/value < src-len [
			return DEFLATE-GZIP-LEN
		][
			copy-memory dest src src-len
			return DEFLATE-GZIP-OK
		]
	]
	
	if dest-len/1 < 18 [
		dest-len/1: 18 + src-len
		return DEFLATE-GZIP-BUFF
	]
	dstart: dest
	dend: dest + dest-len/1
	;-- header
	dest/1: #"^(1F)"			;-- ID1
	dest/2: #"^(8B)"			;-- ID2
	dest/3: #"^(08)"			;-- CM (compression method)
	dest/4: #"^(00)"			;-- FLG
	dest/5: #"^(00)"			;-- MTIME (4 bytes)
	dest/6: #"^(00)"
	dest/7: #"^(00)"
	dest/8: #"^(00)"
	dest/9: #"^(04)"			;-- XFL
	dest/10: #"^(04)"			;-- OS
	dest: dest + 10
	dest-len/1: dest-len/1 - 10
	res: deflate/compress dest dest-len src src-len
	if res <> 0 [
		dest-len/1: dest-len/1 + 18
		return res
	]
	dest: dest + dest-len/1
	dest-len/1: dest-len/1 + 18
	if dest + 8 > dend [
		return DEFLATE-GZIP-LEN
	]
	crc: crypto/CRC32 src src-len
	dest/1: as byte! crc
	dest/2: as byte! crc >> 8
	dest/3: as byte! crc >> 16
	dest/4: as byte! crc >> 24
	dest/5: as byte! src-len
	dest/6: as byte! src-len >> 8
	dest/7: as byte! src-len >> 16
	dest/8: as byte! src-len >> 24
	DEFLATE-GZIP-OK
]

zlib-uncompress: func [
	dest		[byte-ptr!]
	dest-len	[int-ptr!]
	src			[byte-ptr!]
	src-len		[integer!]
	return:		[integer!]
	/local
		a		[integer!]
		b		[integer!]
		p		[byte-ptr!]
		crc		[integer!]
		c		[integer!]
		res		[integer!]
][
	;--check format
	;--check checksum
	a: as integer! src/1
	b: as integer! src/2
	if 256 * a + b % 31 <> 0 [
		return INFLATE-ZLIB-HDR
	]
	;--check method is deflate
	if a and 0Fh <> 8 [
		return INFLATE-ZLIB-HDR
	]
	;--check window size is valid
	if a >> 4 > 7 [
		return INFLATE-ZLIB-HDR
	]
	;--check there is no preset dictionary
	if b and 20h <> 0 [
		return INFLATE-ZLIB-HDR
	]
	;--get adler32 checksum
	p: src + src-len - 4
	crc: (as integer! p/1) << 24
	crc: (as integer! p/2) << 16 + crc
	crc: (as integer! p/3) << 8 + crc
	crc: (as integer! p/4) + crc

	res: deflate/uncompress dest dest-len src + 2 src-len - 6
	if res <> 0 [return res]

	c: crypto/adler32 dest dest-len/1
	;--chcek adler32 checksum
	if crc <> c [
		return INFLATE-ZLIB-HDR
	]
	INFLATE-ZLIB-OK
]

zlib-compress: func [
	dest		[byte-ptr!]
	dest-len	[int-ptr!]
	src			[byte-ptr!]
	src-len		[integer!]
	return:		[integer!]
	/local
		dend	[byte-ptr!]
		res		[integer!]
		crc		[integer!]
][
	if dest-len/1 < 6 [
		dest-len/1: 6 + src-len
		return DEFLATE-ZLIB-BUFF
	]
	dend: dest + dest-len/1
	dest/1: #"^(78)"
	dest/2: #"^(01)"
	dest: dest + 2
	dest-len/1: dest-len/1 - 2
	res: deflate/compress dest dest-len src src-len
	if res <> 0 [
		dest-len/1: dest-len/1 + 6
		return res
	]
	dest: dest + dest-len/1
	dest-len/1: dest-len/1 + 6
	if dest + 4 > dend [
		return DEFLATE-ZLIB-LEN
	]
	crc: crypto/adler32 src src-len
	dest/1: as byte! crc >> 24
	dest/2: as byte! crc >> 16
	dest/3: as byte! crc >> 8
	dest/4: as byte! crc
	DEFLATE-ZLIB-OK
]
