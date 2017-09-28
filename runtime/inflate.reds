Red/System [
	Title:	"Decompression Algorithm for the Deflate Compressed Data Format"
	Author: "Yongzhao Huang"
	File: 	%inflate.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Yongzhao Huang. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

deflate: context [

	init?: no

	TREE!: alias struct! [
		table [int-ptr!]
		trans [int-ptr!]
	]

	init-TREE: func [
		a [TREE!]
		/local
			buf [int-ptr!]
	][
		buf: as int-ptr! allocate 304 * size? integer!
		a/table: buf
		a/trans: buf + 16
	]

	DATA!: alias struct! [
		source 		[byte-ptr!]
		tag 		[integer!]
		bitcount	[integer!]
		dest 		[byte-ptr!]
		destLen 	[int-ptr!]
		ltree 		[TREE! value]
		dtree 		[TREE! value]
	]

	sltree: declare TREE!
	sdtree: declare TREE!

	;--extra bits and base tables for length codes
	length-bits: as int-ptr! 0
	length-base: as int-ptr! 0

	;--extra bits and base table for distance codes
	dist-bits: as int-ptr! 0  
	dist-base: as int-ptr! 0

	;--special ordring of code length  code
	clcidx: [16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15]

	;--build extra bits and base tables
	build-bits-base: func[
		bits 	[int-ptr!]
		base	[int-ptr!]
		delta 	[integer!]
		first 	[integer!]
		/local
			i 	[integer!]
			sum [integer!]
			j	[integer!]
	][
		;--build bits table
		i: 1
		until[
			bits/i: 0
			i: i + 1
			i = (delta + 1)
		]

		i: 1
		until[
			j: i + delta
			bits/j: i - 1 / delta
			i: i + 1
			i = (31 - delta)
		]

		;--build base table
		sum: first
		i: 1
		until[
			base/i: sum
			sum: sum + (1 << (bits/i))
			i: i + 1
			i = 31
		]
	]

	;--build the fixed huffman trees
	build-fixed-trees: function [
		lt 		[TREE!]
		dt 		[TREE!]
		/local
			i 	[integer!]
			j 	[integer!]
	][
		;--build fixed length tree
		init-TREE lt
		init-TREE dt
		i: 1
		until[
			lt/table/i: 0
			i: i + 1
			i = 8
		]
		lt/table/8: 24
		lt/table/9: 152
		lt/table/10: 112
		i: 1
		until [
			lt/trans/i: 256 + i - 1
			i: i + 1
			i = 25

		]
		i: 1
		until [
			j: i + 24
			lt/trans/j: i - 1
			i: i + 1
			i = 145

		]
		i: 1
		until [
			j: 168 + i
			lt/trans/j: 280 + i - 1
			i: i + 1
			i = 9
		]

		i: 1
		until [
			j: 176 + i
			lt/trans/j: 144 + i - 1
			i: i + 1
			i = 113
		]

		;--build fixed distance tree
		i: 1
		until[
			dt/table/i: 0
			i: i + 1
			i = 6
		]

		dt/table/6: 32

		i: 1
		until[
			dt/trans/i: i - 1
			i: i + 1
			i = 33
		]
	]

	;--given an array of code length,build a tree
	build-tree: func [
		t 			[TREE! ]
		lengths 	[byte-ptr!]
		num 		[integer!]
		/local
			offs 	[int-ptr!]
			i 		[integer!]
			sum 	[integer!]
			j 		[integer!]
			l 		[integer!]
			k 		[integer!]
	][
		offs: system/stack/allocate 16

		;--clear code length count table
		i: 1
		until [
			t/table/i: 0
			i: i + 1
			i = 17
		]

		;--scan symbole lengths, and sum code length counts
		i: 1
		until[
			j: (as-integer lengths/i) + 1
			t/table/j: t/table/j + 1
			i: i + 1
			i = (num + 1)
		]
		t/table/1: 0

		;--compute offset table for distribution sort
		i: 1
		sum: 0
		until[
			offs/i: sum
			sum: sum + t/table/i
			i: i + 1
			i = 17
		]

		;--create code->symbol translation table (symbol sorted)
		i: 1
		until[
			j: as-integer lengths/i
			k: j + 1
			l: offs/k
			if j > 0 [
				l: l + 1
				t/trans/l: i - 1
				offs/k: offs/k + 1

			]
			i: i + 1
			i = (num + 1)

		]
	]


	;--get one bit from source stream
	getbit: func [
		d 			[DATA!]
		return: 	[integer!]

		/local
			bit 	 	[integer!]
			j 			[integer!]
			l			[int-ptr!]
			_bitcount	[integer!]
	][
		;--check if tag is empty
		_bitcount: d/bitcount
		d/bitcount: d/bitcount - 1
		if _bitcount = 0 [
			;--load next tag
			d/tag: as integer! d/source/value
			d/source: d/source + 1
			d/bitcount: 7
		]
		;--shift bit out of tag
		j: d/tag
		d/tag: d/tag >> 1
		j and 01h
	]

	;--read a num bit value from a stream and add base
	read-bits: func [
		d 			[DATA! ]
		num 		[integer!]
		base 		[integer!]
		return: 	[integer!]
		/local
			i 		[integer!]
			val 	[integer!]
			limit 	[integer!]
			mask 	[integer!]
	][
		val: 0
		;--read num bits
		if num <> 0 [
			limit: 1 << num
			mask: 1
			until[
				i: getbit d
				if i <> 0 [
					val: val + mask
				]
				mask: mask * 2
				mask >= limit
			]
		]
			val + base
		]

	;--given a data stream and a tree,decode a symbol
	decode-symbol: func [
		d 		[DATA! ]
		t 		[TREE! ]
		return: [integer!]
		 /local
		 	sum [integer!]
		 	cur [integer!]
		 	len [integer!]
			 i 	[integer!]
			 j 	[integer!]
			 l 	[integer!]
	][
		sum: 0
		cur: 0
		len: 1

		until[
			i: getbit d
			cur: 2 * cur + i
			len: len + 1
			j: t/table/len
			sum: sum + j
			cur: cur - j
			cur < 0
		]
		l: sum + cur + 1
		t/trans/l

	]

	;--given a data stream,decode dynamic trees from it
	decode-trees: func [
	   d 	[DATA! ]
	   lt 	[TREE! ]
	   dt	[TREE! ]
	   /local
		code-tree 	[TREE! value]
		lengths		[byte-ptr!]
	  	hlit 		[integer!]
	   	hdist 		[integer!]
	   	hclen 		[integer!]
	  	i 			[integer!]
	   	num 		[integer!]
	 	length 		[integer!]
	   	clen 		[integer!]
	   	j 			[integer!]
	   	sym 		[integer!]
	  	prev 		[integer!]
		l 			[integer!]
		buf			[int-ptr!]
	][
		buf: system/stack/allocate 384
		code-tree/table: buf
		code-tree/trans: buf + 16

		lengths: as byte-ptr! buf + 304

		;--get 5 bits HLIT (257-286)
		hlit: read-bits d 5 257
		;--get 5 bits HDIST (1-32)
		hdist: read-bits d 5 1
		;--get 4 bits HCLEN (4-19)
		hclen: read-bits d 4 4
		i: 1
		until [
			lengths/i: as byte! 0
			i: i + 1
			i = 20
		]

		;--read code lengths for code lengte alphabet
		i: 1
		until [
			;--get 3 bits code length (0-7)
			clen: read-bits d 3 0
			j: clcidx/i + 1
			lengths/j: as byte! clen
			i: i + 1
			i = (hclen + 1)

		]

		;--build code length tree
		build-tree code-tree lengths 19

		;--decode code lengths for the dynamic trees
		num: 0
		until [
			sym: decode-symbol d code-tree
			switch sym [
				16 [
					;--copy previous code length 3-6 times (read 2 bits)
					j: num - 1 + 1
					prev: as-integer lengths/j
					length: read-bits d 2 3
					until [
						l: num + 1
						lengths/l: as-byte prev
						num: num + 1
						length: length - 1
						length = 0
					]
				]
				17 [
					;--repeat code length 0 for 3-10 times (read 3 bits)
					length: read-bits d 3 3
					until [
						l: num + 1
						lengths/l: as-byte 0
						num: num + 1
						length: length - 1
						length = 0
					]
				]
				18 [
					;--repeat code length 0 for 11-138 times (read 7 bits)
					length: read-bits d 7 11
					until [
						l: num + 1
						lengths/l: as-byte 0
						num: num + 1
						length: length - 1
						length = 0
					]
				]
				default [
					l: num + 1
					lengths/l: as-byte sym
					num: num + 1
				]
			]
			num >= (hlit + hdist)
		]
		;--build dynamic trees
		build-tree lt lengths hlit
		build-tree dt (lengths + hlit) hdist
	]

	;--given a stream and two trees, inflate a block of data
	inflate-block-data: func [
		d 		[DATA! ]
		lt 		[TREE! ]
		dt 		[TREE! ]
		return: [integer!]
		/local
			start 	[byte-ptr!]
			sym 	[integer!]
			length 	[integer!]
			dist 	[integer!]
			offs 	[integer!]
			i 		[integer!]
			j 		[integer!]
			l 		[integer!]
			k 		[integer!]
	][
		;--remember current output position
		start: d/dest
		l: 1
		until [
			sym: decode-symbol d lt
			;--check for end of block

			if sym = 256 [
				d/destLen/value: d/destLen/value + (d/dest - start)
				break
			]

			if sym < 256 [
				d/dest/value: as byte! sym
				d/dest: d/dest + 1
			]

			if sym > 256 [
				sym: sym - 257
				k: sym + 1
				;--possibly get more bits from length code
				length: read-bits d length-bits/k length-base/k
				dist: decode-symbol d dt
				;--possibly get more bits from distance code
				k: dist + 1
				offs: read-bits d dist-bits/k dist-base/k

				;--copy match
				i: 1
				until [
					j: i - offs
					d/dest/i: d/dest/j
					i: i + 1
					i = (length + 1)
				]
				d/dest: d/dest + length
			]
			l < 0
		]
		0
	]


	;--inflate an uncompressed block of data
	inflate-uncompressed-block: func[
		d 			[DATA! ]
		return: 	[integer!]
		/local
			length 		[integer!]
			invlength 	[integer!]
			i 			[integer!]
			j			[byte-ptr!]
			l 			[byte-ptr!]
			a 			[integer!]
	][
		;--get length
		length: as integer! d/source/2
		length: 256 * length + (as-integer d/source/1)
		;--get one's complement of length
		invlength: as integer! d/source/4
		invlength: 256 * invlength + (as-integer d/source/3)

		;--check length
		d/source: d/source + 4
		;--copy block
		i: length
		until [
			d/dest/value: d/source/value
			d/dest: d/dest + 1
			d/source: d/source + 1			
			i: i - 1
			i = 0
		]

		;--make sure we start next block on a byte boundary
		d/bitcount: 0
		d/destLen/value: d/destLen/value + length
		0
	]

	;--inflate a block of data compressed with fixed huffman trees
	inflate-fixed-block: func [d [DATA!]][
		inflate-block-data d sltree sdtree
	]

	;--inflate a block of data compressed with dynamic huffman trees
	inflata-dynamic-block: func [d [DATA!] /local buf [int-ptr!]][
		buf: system/stack/allocate 608

		;init-TREE d/ltree
		d/ltree/table: buf
		d/ltree/trans: buf + 16

		;init-TREE d/dtree
		d/dtree/table: buf + 304		;-- 16 + 288
		d/dtree/trans: buf + 320		;-- 304 + 16

		;--decode trees from stream
		decode-trees d d/ltree d/dtree

		;--decode block using decoded trees
		inflate-block-data d d/ltree d/dtree
	]

	;--initialize global (static) data
	init: func [][
		;init the length/dist-bits/base
		;--init bits and base tables for length codes
		length-bits: as int-ptr! allocate 30 * size? integer! 
		length-base: as int-ptr! allocate 30 * size? integer!

		;--init bits and base table for distance codes
		dist-bits: as int-ptr! allocate 30 * size? integer!  
		dist-base: as int-ptr! allocate 30 * size? integer!

		;--build fixed huffman trees
		build-fixed-trees sltree sdtree
		;--build extra bits and base tables
		build-bits-base length-bits length-base 4 3
		build-bits-base dist-bits dist-base 2 1
		;--fix a special carse
		length-bits/29: 0
		length-base/29: 258
	]

	;--if complete the uncompress work, call this function to free these allocated heap-bolcks 
	free-block: func [][
		free as byte-ptr! length-bits
		free as byte-ptr! length-base
		free as byte-ptr! dist-base
		free as byte-ptr! dist-bits
		free as byte-ptr! sltree/trans
 		free as byte-ptr! sltree/table
 		free as byte-ptr! sdtree/trans
 		free as byte-ptr! sdtree/table
	]

	;--inflate stream from source to dest
	uncompress: func [
		dest 		[byte-ptr!]
		destLen 	[int-ptr!]
		source 		[byte-ptr!]
		sourceLen 	[integer!]
		return:		[integer!]
		/local
			bfinal	[integer!]
			d		[DATA! value]
			btype	[integer!]
			res		[integer!]
	][
		unless init? [init?: yes init]

		;--initialise data
		d/source: source
		d/bitcount: 0
		d/dest: dest
		d/destLen: destLen
		destLen/value: 0

		until [
			;--read final block flag
			bfinal: getbit d
			;--read block type (2 bits)
			btype: read-bits d 2 0
			switch btype [
				0 [
					;--decompress uncompressed block
					res: inflate-uncompressed-block d
				]
				1 [
					;--decompress block with fixed huffman trees
					inflate-fixed-block d
				]
				2 [
					;--decompress block with dynamic huffman trees
					inflata-dynamic-block d
				]
				default [0]
			]
			;--if res!=ok return error
			bfinal <> 0
		]
		return 0
	]
] ;-- end inflate context


;-- gzip-uncompress function
#define GZIP_FTEXT		1
#define GZIP_FHCRC		2
#define GZIP_FEXTRA		4
#define GZIP_FNAME		8
#define GZIP_FCOMMENT	16

gzip-uncompress: func [
	dest		[byte-ptr!]
	destLen		[int-ptr!]
	source		[byte-ptr!]
	sourceLen	[integer!]
	return:		[integer!]
	/local
		src		[byte-ptr!]
		dst		[byte-ptr!]
		start	[byte-ptr!]
		dlen	[integer!]
		crc		[integer!]
		flg		[byte!]
		xlen	[integer!]
		hcrc	[integer!]
		i		[integer!]
		res		[integer!]
		a		[integer!]
		b		[integer!]
		c		[integer!]
		flga	[integer!]
][
	src: source
	dst: dest
	;--check format
	;--check id bytes
	a: as integer! src/1
	b: as integer! src/2
	if  any[(a <> 1Fh) b <> 8Bh] [
		return -3
	]
	;--check method is deflate
	a: as integer! src/3
	if a <> 8 [
		return -3
	]
	;--get flag byte
	flg: src/4
	flga: as integer! flg
	;--check that reserved bits are zero
	if (flga and E0h) <> 0 [
		return -3
	]
	;--find start of compressed data
	;--skip base header of 10 bytes
	start: src + 10
	;--skip extra data if present
	if (flga and GZIP_FEXTRA) <> 0 [
		xlen: as integer! start/2
		b: as integer! start/1
		xlen: xlen * 256 + b
		start: start + xlen + 2
	]

	;--skip file comment if present
	if (flga and GZIP_FNAME) <> 0 [
		c: 0
		until [
			c: as integer! start/value
			start: start + 1
			c = 0
		]
	]
	if (flga and GZIP_FCOMMENT) <> 0 [
		c: 0
		until [
			c: as integer! start/value
			start: start + 1
			c = 0
		]
	]

	;--check header crc if present
	if (flga and GZIP_FHCRC) <> 0 [
		hcrc: as integer! start/2
		a: as integer! start/1
		hcrc: 256 * hcrc + a
		i: crypto/CRC32 src size? (start - src)
		if (hcrc <> (i and FFFFh)) [
			return -3
		]
		start: start + 2
	]

	;--get decompressed length
	dlen: as integer! src/sourceLen
	b: sourceLen - 1
	a: as integer! src/b
	dlen: 256 * dlen + a
	b: sourceLen - 2
	a: as integer! src/b
	dlen: 256 * dlen + a
	b: sourceLen - 3
	a: as integer! src/b
	dlen: 256 * dlen + a
	if null? dest [
		destLen/value: dlen
		return 0
	]

	;--get crc32 of decompressed data
	b: sourceLen - 4
	crc: as integer! src/b
	b: sourceLen - 5
	a: as integer! src/b
	crc: 256 * crc + a
	b: sourceLen - 6
	a: as integer! src/b
	crc: 256 * crc + a
	b: sourceLen - 7
	a: as integer! src/b
	crc: 256 * crc + a

	;--decompress data
	a: as-integer (src + sourceLen - start - 8)
	res: deflate/uncompress dst destLen start a
	if res <> 0 [
		return -3
	]
	if (destLen/value) <> dlen [
		return -3
	]

	;--check CRC32 checksum
	c: crypto/CRC32 dst dlen    ;this func is in the crypto.reds
	if crc <> c [
		return -3
	]
	return 0
]

;--zlib-uncompress function
zlib-uncompress: func[
	dest		[byte-ptr!]
	destLen		[int-ptr!]
	source		[byte-ptr!]
	sourceLen	[integer!]
	return:		[integer!]
	/local
		src		[byte-ptr!]
		dst		[byte-ptr!]
		a32		[integer!]
		cmf		[byte!]
		flg		[byte!]
		a		[integer!]
		b		[integer!]
		c		[integer!]
		res		[integer!]
][
	src: source
	dst: dest
	;--get header bytes
	cmf: src/1
	flg: src/2
	;--check format
	;--check checksum
	a: as integer! cmf
	b: as integer! flg
	if ((256 * a + flg) % 31) <> 0 [
		return -3
	]
	;--check method is deflate
	if (a and 0Fh) <> 8 [
		return -3
	]
	;--check window size is valid
	if (a >> 4) > 7 [
		return -3
	]
	;--check there is no preset dictionary
	if (b and 20h) <> 0 [
		return -3
	]
	;--get adler32 checksum
	b: sourceLen - 3
	a32: as integer! src/b
	b: sourceLen - 2
	a: as integer! src/b
	a32: 256 * a32 + a
	b: sourceLen - 1
	a: as integer! src/b
	a32: 256 * a32 + a
	b: sourceLen
	a: as integer! src/b
	a32: 256 * a32 + a

	;--inflate
	res: deflate/uncompress dst destLen (src + 2) (sourceLen - 6)
	if res <> 0 [
		return -3
	]

	c: crypto/adler32 dst destLen/value  ;this func is in the crypto.reds
	;--chcek adler32 checksum
	if a32 <> c [
		return -3
	]
	return 0
]