Red/System [
	Title:	"A Hash Table Implementation"
	Author: "Xie Qingtian"
	File: 	%hashtable.reds
	Tabs:	4
	Rights: "Copyright (C) 2014-2015 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		Algorithm: Open addressing, quadratic probing.
	}
]

#define HASH_TABLE_ERR_OK 0
#define HASH_TABLE_ERR_REHASH 1
#define HASH_TABLE_ERR_REBUILT 2

array: context [

	length?: func [
		node	[node!]
		return: [integer!]
		/local
			s	[series!]
	][
		s: as series! node/value
		as-integer s/tail - s/offset
	]

	clear: func [
		node	[node!]
		/local
			s	[series!]
	][
		s: as series! node/value
		s/tail: s/offset
	]

	append-int: func [
		node	[node!]
		val		[integer!]
		/local
			s	[series!]
			p	[int-ptr!]
	][
		s: as series! node/value
		p: as int-ptr! alloc-tail-unit s size? integer!
		p/value: val
	]

	find-int: func [
		node	[node!]
		val		[integer!]
		return: [integer!]		;-- return offset if found, -1 if not found
		/local
			s	[series!]
			p	[int-ptr!]
			pp	[int-ptr!]
			e	[int-ptr!]
	][
		s: as series! node/value
		p: as int-ptr! s/offset
		e: as int-ptr! s/tail
		pp: p
		while [p < e][
			if p/value = val [
				return as-integer p - pp
			]
			p: p + 1
		]
		-1
	]

	pick-int: func [
		node		[node!]
		idx			[integer!]		;-- 1-based index
		return:		[integer!]
		/local
			s		[series!]
			p		[int-ptr!]
	][
		s: as series! node/value
		p: as int-ptr! s/offset
		assert p + idx - 1 < as int-ptr! s/tail
		p/idx
	]

	append-ptr: func [
		node	[node!]
		val		[int-ptr!]
		/local
			s	[series!]
			p	[ptr-ptr!]
	][
		s: as series! node/value
		p: as ptr-ptr! alloc-tail-unit s size? int-ptr!	
		p/value: val
	]

	find-ptr: func [
		node	[node!]
		val		[int-ptr!]
		return: [integer!]		;-- return offset if found, -1 if not found
		/local
			s	[series!]
			p	[ptr-ptr!]
			pp	[ptr-ptr!]
			e	[ptr-ptr!]
	][
		s: as series! node/value
		p: as ptr-ptr! s/offset
		e: as ptr-ptr! s/tail
		pp: p
		while [p < e][
			if p/value = val [
				return as-integer p - pp
			]
			p: p + 1
		]
		-1
	]

	pick-ptr: func [
		node		[node!]
		idx			[integer!]		;-- 1-based index
		return:		[node!]
		/local
			s		[series!]
			p		[ptr-ptr!]
	][
		s: as series! node/value
		p: as ptr-ptr! s/offset
		p: p + idx - 1
		assert p < as ptr-ptr! s/tail
		p/value
	]

	poke-ptr: func [
		node		[node!]
		idx			[integer!]		;-- 1-based index
		val			[int-ptr!]
		/local
			s		[series!]
			p		[ptr-ptr!]
	][
		s: as series! node/value
		p: as ptr-ptr! s/offset
		p: p + idx - 1
		assert p < as ptr-ptr! s/tail
		p/value: val
	]

	remove-at: func [
		node	[node!]
		offset	[integer!]			;-- bytes
		len		[integer!]			;-- bytes
		/local
			s	[series!]
			p	[byte-ptr!]
	][
		s: as series! node/value

		p: (as byte-ptr! s/offset) + offset

		assert p + len <= (as byte-ptr! s/tail)

		move-memory
			p
			p + len
			as-integer (as byte-ptr! s/tail) - (p + len)

		s/tail: as cell! (as byte-ptr! s/tail) - len
	]
]

#define MAP_KEY_DELETED		[0]

#define HASH_TABLE_HASH		0
#define HASH_TABLE_MAP		1
#define HASH_TABLE_SYMBOL	2
#define HASH_TABLE_INTEGER	3

#define HASH_SYMBOL_BLOCK	1
#define HASH_SYMBOL_CONTEXT	2

#define _HT_HASH_UPPER		0.77

#define _BUCKET_IS_EMPTY(flags i s)			[flags/i >> s and 2 = 2]
#define _BUCKET_IS_NOT_EMPTY(flags i s)		[flags/i >> s and 2 <> 2]
#define _BUCKET_IS_DEL(flags i s)			[flags/i >> s and 1 = 1]
#define _BUCKET_IS_NOT_DEL(flags i s)		[flags/i >> s and 1 <> 1]
#define _BUCKET_IS_EITHER(flags i s)		[flags/i >> s and 3 > 0]
#define _BUCKET_IS_HAS_KEY(flags i s)		[flags/i >> s and 3 = 0]
#define _BUCKET_SET_DEL_TRUE(flags i s)		[flags/i: 1 << s or flags/i]
#define _BUCKET_SET_DEL_FALSE(flags i s)	[flags/i: (not 1 << s) and flags/i]
#define _BUCKET_SET_EMPTY_FALSE(flags i s)	[flags/i: (not 2 << s) and flags/i]
#define _BUCKET_SET_BOTH_FALSE(flags i s)	[flags/i: (not 3 << s) and flags/i]

#define _HT_CAL_FLAG_INDEX(i idx shift) [
	idx: i >> 4 + 1
	shift: i and 0Fh << 1
]

#define MURMUR_HASH_3_X86_32_C1		CC9E2D51h
#define MURMUR_HASH_3_X86_32_C2		1B873593h

#define MURMUR_HASH_ROTL_32(x r) [
	x << r or (x >>> (32 - r))
]

hash-secret: 0

hash-string: func [
	str		[red-string!]
	case?	[logic!]
	return: [integer!]
	/local s [series!] unit [integer!] p [byte-ptr!] p4 [int-ptr!] k1 [integer!]
		h1 [integer!] tail [byte-ptr!] len [integer!] head [integer!] sc [red-slice!]
][
	s: GET_BUFFER(str)
	unit: GET_UNIT(s)
	head: str/head
	p: (as byte-ptr! s/offset) + (head << (log-b unit))

	sc: as red-slice! str
	either all [TYPE_OF(sc) = TYPE_SLICE sc/length >= 0][
		len: sc/length
		tail: p + (len << (log-b unit))
		len: len << 2
	][
		tail: as byte-ptr! s/tail
		len: (as-integer tail - p) >> (log-b unit) << 2
	]
	h1: hash-secret						;-- seed

	;-- body
	while [p < tail][
		k1: switch unit [
			Latin1 [as-integer p/value]
			UCS-2  [(as-integer p/2) << 8 + p/1]
			UCS-4  [p4: as int-ptr! p p4/value]
		]
		unless case? [k1: case-folding/change-char k1 yes]
		k1: k1 * MURMUR_HASH_3_X86_32_C1
		k1: MURMUR_HASH_ROTL_32(k1 15)
		k1: k1 * MURMUR_HASH_3_X86_32_C2

		h1: h1 xor k1
		h1: MURMUR_HASH_ROTL_32(h1 13)
		h1: h1 * 5 + E6546B64h
		p: p + unit
	]

	;-- finalization
	h1: h1 xor len
	h1: h1 >>> 16 xor h1
	h1: h1 * 85EBCA6Bh
	h1: h1 >>> 13 xor h1
	h1: h1 * C2B2AE35h
	h1: h1 >>> 16 xor h1
	h1
]

murmur3-x86-32: func [
	key		[byte-ptr!]
	len		[integer!]
	return: [integer!]
	/local data [byte-ptr!] nblocks [integer!] blocks [int-ptr!] p [int-ptr!]
		i [integer!] k1 [integer!] h1 [integer!] tail [byte-ptr!] n [integer!]
][
	assert len > 0

	data: key
	nblocks: len / 4
	h1: hash-secret						;-- seed

	;-- body
	blocks: as int-ptr! (data + (nblocks * 4))
	i: 0 - nblocks
	while [negative? i][
		p: blocks + i
		k1: p/value						;@@ do endian-swapping if needed
		k1: k1 * MURMUR_HASH_3_X86_32_C1
		k1: MURMUR_HASH_ROTL_32(k1 15)
		k1: k1 * MURMUR_HASH_3_X86_32_C2

		h1: h1 xor k1
		h1: MURMUR_HASH_ROTL_32(h1 13)
		h1: h1 * 5 + E6546B64h
		i: i + 1
	]

	;-- tail
	n: len and 3
	if positive? n [
		k1: 0
		tail: data + (nblocks * 4)
		if n = 3 [k1: (as-integer tail/3) << 16 xor k1]
		if n > 1 [k1: (as-integer tail/2) << 8  xor k1]
		k1: (as-integer tail/1) xor k1
		k1: k1 * MURMUR_HASH_3_X86_32_C1
		k1: MURMUR_HASH_ROTL_32(k1 15)
		k1: k1 * MURMUR_HASH_3_X86_32_C2
		h1: h1 xor k1
	]

	;-- finalization
	h1: h1 xor len
	h1: h1 >>> 16 xor h1
	h1: h1 * 85EBCA6Bh
	h1: h1 >>> 13 xor h1
	h1: h1 * C2B2AE35h
	h1: h1 >>> 16 xor h1
	h1
]

murmur3-x86-int: func [h1 [integer!] return: [integer!]][
	h1: h1 >>> 16 xor h1
	h1: h1 * 85EBCA6Bh
	h1: h1 >>> 13 xor h1
	h1: h1 * C2B2AE35h
	h1: h1 >>> 16 xor h1
	h1
]

_hashtable: context [
	str-buffer: as byte-ptr! 0
	str-buffer-sz: 256
	refresh-buffer: as red-hash! 0

	hashtable!: alias struct! [
		size		[integer!]
		indexes		[node!]
		chains		[node!]
		flags		[node!]
		keys		[node!]
		blk			[node!]
		n-occupied	[integer!]
		n-buckets	[integer!]
		upper-bound	[integer!]
		type		[integer!]
	]
	
	mark: func [
		table [node!]
		/local
			s	 [series!]
			h	 [hashtable!]
			val	 [red-value!]
			end	 [red-value!]
			p	 [ptr-ptr!]
			e	 [ptr-ptr!]
			type	 [integer!]
	][
		collector/keep table
		s: as series! table/value
		h: as hashtable! s/offset
		type: h/type
		if type = HASH_TABLE_HASH [
			collector/keep h/indexes
			collector/keep h/chains
			s: as series! h/chains/value
			p: as ptr-ptr! s/offset
			e: as ptr-ptr! s/tail
			while [p < e][
				if p/value <> null [collector/keep p/value]
				p: p + 1
			]
		]
		collector/keep h/flags
		collector/keep h/keys
		if type > 1 [collector/keep h/blk]
	]

	sweep: func [
		table [node!]
		/local
			s	 [series!]
			h	 [hashtable!]
			val	 [red-value!]
			end	 [red-value!]
			obj  [red-object!]
			node [node!]
	][
		s: as series! table/value
		h: as hashtable! s/offset

		assert h/type = HASH_TABLE_INTEGER

		s: as series! h/blk/value
		val: s/offset
		end: s/tail
		while [val < end][
			node: as node! val/data1
			if node <> null [
				s: as series! node/value
				either s/flags and flag-gc-mark = 0 [
					delete-key table as-integer node
					val/data1: 0
				][	;-- check owner
					obj: as red-object! val + 2
					s: as series! obj/ctx/value
					if s/flags and flag-gc-mark = 0 [
						delete-key table as-integer node
						val/data1: 0
					]
				]
			]
			val: val + 4
		]
	]

	round-up: func [
		n		[integer!]
		return: [integer!]
	][
		n: n - 1
		n: n >> 1 or n
		n: n >> 2 or n
		n: n >> 4 or n
		n: n >> 8 or n
		n: n >> 16 or n
		n + 1
	]

	hash-symbol: func [
		sym		[red-symbol!]
		return: [integer!]
		/local
			s	[series!]
			len [integer!]
	][
		s: as series! sym/cache/value
		len: as-integer s/tail - s/offset
		murmur3-x86-32
			to-lower as byte-ptr! s/offset len
			len
	]

	hash-value: func [
		key		[red-value!]
		case?	[logic!]
		return: [integer!]
		/local
			value  [red-value!]
			sym    [red-string!]
			sign   [integer!]
			result [integer!]
			s      [series!]
	][
		switch TYPE_OF(key) [
			TYPE_INTEGER [murmur3-x86-int key/data2]
			TYPE_ALL_WORD [symbol/resolve key/data2]
			TYPE_SYMBOL [hash-symbol as red-symbol! key]
			TYPE_ANY_STRING [
				hash-string as red-string! key case?
			]
			TYPE_CHAR [murmur3-x86-int key/data2]
			TYPE_FLOAT
			TYPE_PAIR
			TYPE_PERCENT
			TYPE_TIME [
				murmur3-x86-32 (as byte-ptr! key) + 8 8
			]
			TYPE_POINT2D [
				murmur3-x86-32 (as byte-ptr! key) + 4 8
			]
			TYPE_POINT3D [
				murmur3-x86-32 (as byte-ptr! key) + 8 12
			]
			TYPE_NONE  [-1]
			TYPE_UNSET [-2]
			TYPE_MONEY [
				value: copy-cell key stack/push*
				sign: money/get-sign as red-money! value
				value/header: TYPE_MONEY			;-- implicit reset of all header flags
				money/set-sign as red-money! value sign
				result: murmur3-x86-32 as byte-ptr! value size? cell!
				stack/pop 1
				result
			]
			TYPE_BINARY [
				sym: as red-string! key
				s: GET_BUFFER(sym)
				murmur3-x86-32
					(as byte-ptr! s/offset) + sym/head
					(as-integer s/tail - s/offset) - sym/head
			]
			TYPE_TUPLE [
				murmur3-x86-32 (as byte-ptr! key) + 4 TUPLE_SIZE?(key)
			]
			TYPE_DATE
			TYPE_TRIPLE
			TYPE_TYPESET
			TYPE_FUNCTION
			TYPE_OP [murmur3-x86-32 (as byte-ptr! key) + 4 12]
			TYPE_OBJECT
			TYPE_ERROR
			TYPE_PORT [murmur3-x86-int key/data1]
			TYPE_DATATYPE
			TYPE_LOGIC [key/data1]
			TYPE_ACTION
			TYPE_NATIVE [key/data3]
			TYPE_MAP
			TYPE_HANDLE
			TYPE_EVENT [murmur3-x86-int key/data2]
			TYPE_IMAGE
			TYPE_ANY_BLOCK [							;-- use head and node
				murmur3-x86-32 (as byte-ptr! key) + 4 8
			]
			default [assert false 0]
		]
	]

	put-all: func [
		node	[node!]
		head	[integer!]
		skip	[integer!]
		/local s [series!] h [hashtable!] i [integer!] end [red-value!]
			value [red-value!] key [red-value!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		s: as series! h/blk/value
		end: s/tail
		i: head
		while [
			value: s/offset + i
			value < end
		][
			either h/type = HASH_TABLE_MAP [
				key: get node value 0 0 COMP_STRICT_EQUAL no no
				either key = null [
					map/preprocess-key value
					put node value
				][
					copy-cell value + 1 key + 1
					move-memory 
						as byte-ptr! value
						as byte-ptr! value + 2
						as-integer s/tail - (value + 2)
					s/tail: s/tail - 2
					end: s/tail
					i: i - skip
				]
			][
				put node value
			]
			i: i + skip
		]
	]

	_alloc-bytes: func [
		size	[integer!]						;-- number of 16 bytes cells to preallocate
		return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
		/local
			node [int-ptr!]
			s	 [series!]
	][
		node: alloc-bytes size
		s: as series! node/value
		s/tail: as cell! (as byte-ptr! s/offset) + s/size
		fill 
			as byte-ptr! s/offset
			as byte-ptr! s/tail
			#"^@"
		node
	]

	_alloc-bytes-filled: func [
		size	[integer!]						;-- number of 16 bytes cells to preallocate
		byte	[byte!]
		return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
		/local
			node [node!]
			s	 [series!]
	][
		node: alloc-bytes size
		s: as series! node/value
		s/tail: as cell! (as byte-ptr! s/offset) + s/size
		fill 
			as byte-ptr! s/offset
			as byte-ptr! s/tail
			byte
		node
	]

	fill-series: func [
		node	[node!]
		byte	[byte!]
		/local
			s	[series!]
	][
		s: as series! node/value
		fill 
			as byte-ptr! s/offset
			(as byte-ptr! s/offset) + s/size
			byte
	]

	copy-context: func [
		ctx		[red-context!]
		node	[node!]
		return: [node!]
		/local
			s	[series!]
			h	[hashtable!]
			ss	[series!]
			hh	[hashtable!]
			b	[node!]
			k	[node!]
			a	[logic!]
	][
		s: as series! ctx/symbols/value
		h: as hashtable! s/offset

		ss: as series! node/value
		hh: as hashtable! ss/offset
		copy-memory as byte-ptr! hh as byte-ptr! h size? hashtable!
		b: copy-series as series! h/blk/value
		hh/blk: b
		k: copy-series as series! h/keys/value
		hh/keys: k
		hh/flags: copy-series as series! h/flags/value

		node
	]

	init: func [
		size	[integer!]
		blk		[red-block!]
		type	[integer!]
		vsize	[integer!]
		return: [node!]
		/local
			node		[node!]
			flags		[node!]
			keys		[node!]
			indexes		[node!]
			chains		[node!]
			s			[series!]
			ss			[series!]
			h			[hashtable!]
			f-buckets	[float!]
			fsize		[float!]
			skip		[integer!]
			saved		[logic!]
	][
		node: _alloc-bytes-filled size? hashtable! #"^(00)"
		if type = HASH_TABLE_SYMBOL [
			if null? str-buffer [str-buffer: allocate str-buffer-sz]
			if all [vsize = HASH_SYMBOL_CONTEXT blk <> null][
				return copy-context as red-context! blk node
			]
			if size >= 4000 [size: size << 1]		;-- global context
		]

		s: as series! node/value
		h: as hashtable! s/offset
		h/type: type
		if type = HASH_TABLE_INTEGER [h/indexes: as node! vsize + 1 << 4]

		if size < 4 [size: 4]
		fsize: as-float size
		f-buckets: fsize / _HT_HASH_UPPER
		skip: either type = HASH_TABLE_MAP [2][1]
		h/n-buckets: round-up as-integer f-buckets
		f-buckets: as-float h/n-buckets
		h/upper-bound: as-integer f-buckets * _HT_HASH_UPPER
		flags: _alloc-bytes-filled h/n-buckets >> 2 #"^(AA)"
		keys: _alloc-bytes h/n-buckets * size? int-ptr!

		indexes: null
		if type = HASH_TABLE_HASH [
			indexes: _alloc-bytes-filled size * size? integer! #"^(FF)"
			h/indexes: indexes
			chains: alloc-bytes 4 * size? node!
			h/chains: chains
		]
		h/flags: flags
		h/keys: keys
		either any [type = HASH_TABLE_INTEGER blk = null][
			h/blk: alloc-cells size
		][
			h/blk: blk/node
			saved: collector/active?
			collector/active?: no							;-- turn off GC
			put-all node blk/head skip
			collector/active?: saved
		]
		node
	]

	rehash: func [
		node			[node!]
		new-buckets		[integer!]
		/local
			flags		[node!]
			s			[series!]
			h			[hashtable!]
			n-buckets	[integer!]
			new-size	[integer!]
			f			[float!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		f: as-float new-buckets
		new-buckets: round-up as-integer f * 1.5
		f: as-float new-buckets
		new-size: as-integer f * _HT_HASH_UPPER
		if new-buckets < 4 [new-buckets: 4]

		h/size: 0
		h/n-occupied: 0
		h/upper-bound: new-size
		h/n-buckets: new-buckets
		array/clear h/chains
		flags: _alloc-bytes-filled new-buckets >> 2 #"^(AA)"
		h/flags: flags
		h/keys: _alloc-bytes new-buckets * size? int-ptr!

		put-all node 0 1
	]

	resize-map: func [
		node			[node!]
		new-buckets		[integer!]
		/local
			s			[series!]
			h			[hashtable!]
			n-buckets	[integer!]
			new-size	[integer!]
			f			[float!]
			flags		[node!]
			new-blk		[node!]
			i sz		[integer!]
			end			[red-value!]
			value		[red-value!]
			key			[red-value!]
			len	vsize	[integer!]
			k			[int-ptr!]
			slot		[red-value!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		new-buckets: round-up new-buckets
		f: as-float new-buckets
		new-size: as-integer f * _HT_HASH_UPPER + 0.5
		if new-buckets < 4 [new-buckets: 4]

		sz: h/size
		h/size: 0
		h/n-occupied: 0
		h/upper-bound: new-size
		h/n-buckets: new-buckets
		flags: _alloc-bytes-filled new-buckets >> 2 #"^(AA)"
		h/flags: flags
		h/keys: _alloc-bytes new-buckets * size? int-ptr!

		vsize: as integer! h/indexes
		len: vsize >> 4
		vsize: vsize - size? red-value!

		s: as series! h/blk/value
		end: s/tail
		i: 0
		h/blk: alloc-cells sz * len
		while [
			value: s/offset + i
			value < end
		][
			k: as int-ptr! value
			if value/header = TYPE_UNSET [
				slot: put-key node k/2
				copy-memory as byte-ptr! slot as byte-ptr! (value + 1) vsize
			]
			i: i + len
		]
	]

	resize: func [
		node			[node!]
		new-buckets		[integer!]
		/local
			s			[series!]
			h			[hashtable!]
			k			[red-value!]
			i			[integer!]
			j			[integer!]
			mask		[integer!]
			step		[integer!]
			keys		[int-ptr!]
			hash		[integer!]
			n-buckets	[integer!]
			blk			[red-value!]
			new-size	[integer!]
			tmp			[integer!]
			break?		[logic!]
			flags		[int-ptr!]
			new-flags	[int-ptr!]
			ii			[integer!]
			sh			[integer!]
			f			[float!]
			idx			[integer!]
			int?		[logic!]
			int-key		[int-ptr!]
			new-flags-node [node!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		int?: h/type = HASH_TABLE_INTEGER
		s: as series! h/blk/value
		blk: s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		n-buckets: h/n-buckets
		j: 0
		new-buckets: round-up new-buckets
		if new-buckets < 4 [new-buckets: 4]
		f: as-float new-buckets
		new-size: as-integer f * _HT_HASH_UPPER + 0.5

		either h/size >= new-size [j: 1][
			new-flags-node: _alloc-bytes-filled new-buckets >> 2 #"^(AA)"
			s: as series! new-flags-node/value
			new-flags: as int-ptr! s/offset
			if n-buckets < new-buckets [
				s: expand-series as series! h/keys/value new-buckets * size? int-ptr!
				s/tail: as cell! (as byte-ptr! s/offset) + s/size
			]
		]
		if zero? j [
			s: as series! h/keys/value
			keys: as int-ptr! s/offset
			until [
				_HT_CAL_FLAG_INDEX(j ii sh)
				j: j + 1
				if _BUCKET_IS_HAS_KEY(flags ii sh) [
					idx: keys/j
					mask: new-buckets - 1
					_BUCKET_SET_DEL_TRUE(flags ii sh)
					break?: no
					until [									;-- kick-out process
						step: 0
						either int? [
							int-key: as int-ptr! ((as byte-ptr! blk) + idx)
							hash: int-key/2
						][
							k: blk + (idx and 7FFFFFFFh)
							hash: hash-value k no
						]
						i: hash and mask
						_HT_CAL_FLAG_INDEX(i ii sh)
						while [_BUCKET_IS_NOT_EMPTY(new-flags ii sh)][
							step: step + 1
							i: i + step and mask
							_HT_CAL_FLAG_INDEX(i ii sh)
						]
						i: i + 1
						_BUCKET_SET_EMPTY_FALSE(new-flags ii sh)
						either all [
							i <= n-buckets
							_BUCKET_IS_HAS_KEY(flags ii sh)
						][
							tmp: keys/i keys/i: idx idx: tmp
							_BUCKET_SET_DEL_TRUE(flags ii sh)
						][
							keys/i: idx
							break?: yes
						]
						break?
					]
				]
				j = n-buckets
			]
			;@@ if h/n-buckets > new-buckets []			;-- shrink the hash table
			h/flags: new-flags-node
			h/n-buckets: new-buckets
			if h/type <> HASH_TABLE_MAP [h/n-occupied: h/size]
			h/upper-bound: new-size
		]
	]

	put-key: func [
		node	[node!]
		key		[integer!]
		return: [red-value!]
		/local
			s [series!] h [hashtable!] x [integer!] i [integer!] site [integer!]
			last [integer!] mask [integer!] step [integer!] keys [int-ptr!]
			hash [integer!] n-buckets [integer!] flags [int-ptr!] ii [integer!]
			sh [integer!] blk [byte-ptr!] idx [integer!] del? [logic!] k [int-ptr!]
			vsize [integer!] blk-node [series!] len [integer!] value [red-value!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		if h/n-occupied >= h/upper-bound [			;-- update the hash table
			vsize: either h/n-buckets > (h/size << 1) [-1][1]
			n-buckets: h/n-buckets + vsize
			resize-map node n-buckets
		]

		vsize: as integer! h/indexes
		blk-node: as series! h/blk/value
		blk: as byte-ptr! blk-node/offset
		len: as-integer blk-node/tail - as cell! blk

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		n-buckets: h/n-buckets + 1
		x:	  n-buckets
		site: n-buckets
		mask: n-buckets - 2
		hash: key
		i: hash and mask
		_HT_CAL_FLAG_INDEX(i ii sh)
		i: i + 1									;-- 1-based index
		either _BUCKET_IS_EMPTY(flags ii sh) [x: i][
			step: 0
			last: i
			while [
				del?: _BUCKET_IS_DEL(flags ii sh)
				k: as int-ptr! blk + keys/i
				all [
					_BUCKET_IS_NOT_EMPTY(flags ii sh)
					any [
						del?
						k/2 <> key
					]
				]
			][
				if del? [site: i]
				i: i + step and mask
				_HT_CAL_FLAG_INDEX(i ii sh)
				i: i + 1
				step: step + 1
				if i = last [x: site break]
			]
			if x = n-buckets [
				x: either all [
					_BUCKET_IS_EMPTY(flags ii sh)
					site <> n-buckets
				][site][i]
			]
		]
		_HT_CAL_FLAG_INDEX((x - 1) ii sh)
		case [
			_BUCKET_IS_EMPTY(flags ii sh) [
				k: as int-ptr! alloc-tail-unit blk-node vsize
				k/2: key
				keys/x: len
				_BUCKET_SET_BOTH_FALSE(flags ii sh)
				h/size: h/size + 1
				h/n-occupied: h/n-occupied + 1
			]
			_BUCKET_IS_DEL(flags ii sh) [
				k: as int-ptr! blk + keys/x
				k/2: key
				_BUCKET_SET_BOTH_FALSE(flags ii sh)
				h/size: h/size + 1
			]
			true [k: as int-ptr! blk + keys/x]
		]
		len: vsize >> 4
		value: as cell! k
		loop len [
			value/header: TYPE_UNSET
			value: value + 1
		]
		(as cell! k) + 1
	]

	delete-key: func [
		node	[node!]
		key		[integer!]
		return: [red-value!]
		/local
			s [series!] h [hashtable!] i [integer!] flags [int-ptr!] last [integer!]
			mask [integer!] step [integer!] keys [int-ptr!] hash [integer!]
			ii [integer!] sh [integer!] blk [byte-ptr!] k [int-ptr!]
	][
		s: as series! node/value
		h: as hashtable! s/offset
		assert h/n-buckets > 0

		s: as series! h/blk/value
		blk: as byte-ptr! s/offset

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		mask: h/n-buckets - 1
		hash: key
		i: hash and mask
		_HT_CAL_FLAG_INDEX(i ii sh)
		i: i + 1
		last: i
		step: 0
		while [
			k: as int-ptr! blk + keys/i
			all [
				_BUCKET_IS_NOT_EMPTY(flags ii sh)
				any [
					_BUCKET_IS_DEL(flags ii sh)
					k/2 <> key
				]
			]
		][
			i: i + step and mask
			_HT_CAL_FLAG_INDEX(i ii sh)
			i: i + 1
			step: step + 1
			if i = last [return null]
		]

		either _BUCKET_IS_EITHER(flags ii sh) [null][
			_BUCKET_SET_DEL_TRUE(flags ii sh)
			h/size: h/size - 1
			k: as int-ptr! blk + keys/i
			k/value: TYPE_VALUE
			(as cell! k) + 1
		]
	]

	get-value: func [
		node	[node!]
		key		[integer!]
		return: [red-value!]
		/local
			s [series!] h [hashtable!] i [integer!] flags [int-ptr!] last [integer!]
			mask [integer!] step [integer!] keys [int-ptr!] hash [integer!]
			ii [integer!] sh [integer!] blk [byte-ptr!] k [int-ptr!]
	][
		s: as series! node/value
		h: as hashtable! s/offset
		assert h/n-buckets > 0

		s: as series! h/blk/value
		blk: as byte-ptr! s/offset

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		mask: h/n-buckets - 1
		hash: key
		i: hash and mask
		_HT_CAL_FLAG_INDEX(i ii sh)
		i: i + 1
		last: i
		step: 0
		while [
			k: as int-ptr! blk + keys/i
			all [
				_BUCKET_IS_NOT_EMPTY(flags ii sh)
				any [
					_BUCKET_IS_DEL(flags ii sh)
					k/2 <> key
				]
			]
		][
			i: i + step and mask
			_HT_CAL_FLAG_INDEX(i ii sh)
			i: i + 1
			step: step + 1
			if i = last [return null]
		]

		either _BUCKET_IS_EITHER(flags ii sh) [null][
			(as cell! blk + keys/i) + 1
		]
	]

	put: func [
		node	[node!]
		key 	[red-value!]
		return: [red-value!]
		/local
			err [integer!]
	][
		err: 0
		put-err node key :err
	]

	put-err: func [
		node	[node!]
		key 	[red-value!]
		errcode	[int-ptr!]
		return: [red-value!]
		/local
			s [series!] h [hashtable!] x [integer!] i [integer!] site [integer!]
			last [integer!] mask [integer!] step [integer!] keys [int-ptr!]
			hash [integer!] n-buckets [integer!] flags [int-ptr!] ii [integer!]
			sh [integer!] continue? saved [logic!] blk [red-value!] idx [integer!]
			type [integer!] del? chain? [logic!] indexes chain [int-ptr!] k [red-value!]
	][
		s: as series! node/value
		h: as hashtable! s/offset
		type: h/type

		errcode/value: HASH_TABLE_ERR_OK
		if h/n-occupied >= h/upper-bound [			;-- update the hash table
			idx: either h/n-buckets > (h/size << 1) [-1][1]
			n-buckets: h/n-buckets + idx
			either type = HASH_TABLE_HASH [
				rehash node n-buckets
				errcode/value: HASH_TABLE_ERR_REBUILT
				return key
			][
				if type = HASH_TABLE_MAP [n-buckets: h/n-buckets + 1]
				resize node n-buckets
			]
			s: as series! node/value
			h: as hashtable! s/offset
		]

		saved: collector/active?
		collector/active?: no						;-- turn off GC

		s: as series! h/blk/value
		idx: (as-integer (key - s/offset)) >> 4
		blk: s/offset

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		n-buckets: h/n-buckets + 1
		x:	  n-buckets
		site: n-buckets
		mask: n-buckets - 2
		hash: hash-value key no
		i: hash and mask
		_HT_CAL_FLAG_INDEX(i ii sh)
		i: i + 1									;-- 1-based index
		either _BUCKET_IS_EMPTY(flags ii sh) [x: i][
			step: 0
			last: i
			continue?: yes
			while [
				del?: _BUCKET_IS_DEL(flags ii sh)
				all [
					continue?
					_BUCKET_IS_NOT_EMPTY(flags ii sh)
					any [
						del?
						type = HASH_TABLE_HASH
						not actions/compare blk + keys/i key COMP_STRICT_EQUAL
					]
				]
			][
				either del? [site: i][
					if type = HASH_TABLE_HASH [
						chain?: keys/i < 0
						either chain? [
							chain: array/pick-ptr h/chains 0 - keys/i
							k: blk + array/pick-int chain 1
						][
							k: blk + keys/i
						]
						if all [
							TYPE_OF(k) = TYPE_OF(key)
							actions/compare k key COMP_EQUAL
						][
							unless chain? [
								chain: alloc-bytes 4 * size? integer!
								array/append-ptr h/chains chain
								array/append-int chain keys/i
								keys/i: 0 - ((array/length? h/chains) >> log-b size? int-ptr!)
							]
							array/append-int chain idx
							x: i
							break
						]
					]
				]

				i: i + step and mask
				_HT_CAL_FLAG_INDEX(i ii sh)
				i: i + 1
				step: step + 1
				if i = last [x: site continue?: no]
			]
			if x = n-buckets [
				x: either all [
					_BUCKET_IS_EMPTY(flags ii sh)
					site <> n-buckets
				][site][i]
			]
		]
		_HT_CAL_FLAG_INDEX((x - 1) ii sh)
		either _BUCKET_IS_EMPTY(flags ii sh) [
			keys/x: idx
			_BUCKET_SET_BOTH_FALSE(flags ii sh)
			h/size: h/size + 1
			h/n-occupied: h/n-occupied + 1
		][
			if _BUCKET_IS_DEL(flags ii sh) [
				keys/x: idx
				_BUCKET_SET_BOTH_FALSE(flags ii sh)
				h/size: h/size + 1
			]
		]
		if type = HASH_TABLE_HASH [
			s: as series! h/indexes/value
			if idx << 2 >= s/size [
				s: expand-series-filled s idx << 3 #"^(FF)"
				s/tail: as cell! (as byte-ptr! s/offset) + s/size
			]
			indexes: as int-ptr! s/offset
			idx: idx + 1
			indexes/idx: x
		]
		collector/active?: saved
		key
	]

	get-next: func [
		node	[node!]
		key		[red-value!]
		start	[int-ptr!]
		end		[int-ptr!]
		pace	[int-ptr!]
		return: [red-value!]
		/local
			s [series!] h [hashtable!] i [integer!] flags [int-ptr!]
			last [integer!] mask [integer!] step [integer!] keys [int-ptr!]
			hash [integer!] ii [integer!] sh [integer!] blk [red-value!]
			idx [integer!] k [red-value!] key-type [integer!] n [integer!]
	][
		s: as series! node/value
		h: as hashtable! s/offset
		assert h/n-buckets > 0

		n: 0
		key-type: TYPE_OF(key)
		s: as series! h/blk/value
		blk: s/offset

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		mask: h/n-buckets - 1
		i: start/value
		if i = -1 [
			hash: hash-value key no
			i: hash and mask
			end/value: i + 1
		]
		_HT_CAL_FLAG_INDEX(i ii sh)
		i: i + 1
		last: end/value
		step: pace/value
		while [_BUCKET_IS_NOT_EMPTY(flags ii sh)][
			k: blk + keys/i
			if all [
				_BUCKET_IS_HAS_KEY(flags ii sh)
				TYPE_OF(k) = key-type
				actions/compare k key COMP_EQUAL
			][
				start/value: i + step and mask
				pace/value: step + 1
				return k
			]

			i: i + step and mask
			_HT_CAL_FLAG_INDEX(i ii sh)
			i: i + 1
			step: step + 1
			if i = last [break]
		]
		null
	]

	get: func [
		node	 [node!]
		key		 [red-value!]
		head	 [integer!]
		skip	 [integer!]
		op		 [comparison-op!]
		last?	 [logic!]
		reverse? [logic!]
		return:  [red-value!]
		/local
			s		[series!]
			h		[hashtable!]
			i		[integer!]
			flags	[int-ptr!]
			last	[integer!]
			mask	[integer!]
			step	[integer!]
			keys	[int-ptr!]
			hash	[integer!]
			ii		[integer!]
			sh		[integer!]
			blk		[red-value!]
			k		[red-value!]
			idx		[integer!]
			chain	[node!]
			p-idx	[int-ptr!]
			sz		[integer!]
			find?	[logic!]
			hash?	[logic!]
			chain?	[logic!]
			align   [integer!]
			type	[integer!]
			key-type [integer!]
			last-idx [integer!]
			saved-type	[integer!]
			set-header? [logic!]
	][
		s: as series! node/value
		h: as hashtable! s/offset
		assert h/n-buckets > 0

		type: h/type
		hash?: type = HASH_TABLE_HASH
		key-type: TYPE_OF(key)
		set-header?: all [type = HASH_TABLE_MAP ANY_WORD?(key-type)]
		if set-header? [
			saved-type: key-type
			key-type: TYPE_SET_WORD
			key/header: TYPE_SET_WORD	;-- set the header here for actions/compare, restore back later
		]

		s: as series! h/blk/value
		if reverse? [
			last?: yes
		]
		last-idx: either last? [-1][(as-integer (s/tail - s/offset)) >> 4]
		blk: s/offset

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		mask: h/n-buckets - 1
		hash: hash-value key no
		i: hash and mask
		_HT_CAL_FLAG_INDEX(i ii sh)
		i: i + 1
		last: i
		step: 0
		find?: no
		while [
			k: blk + keys/i
			all [
				_BUCKET_IS_NOT_EMPTY(flags ii sh)
				any [
					_BUCKET_IS_DEL(flags ii sh)
					hash?
					all [key-type <> TYPE_SLICE TYPE_OF(k) <> key-type]
					not actions/compare k key op
				]
			]
		][
			if hash? [
				chain?: keys/i < 0
				either chain? [
					chain: array/pick-ptr h/chains 0 - keys/i
					s: as series! chain/value
					p-idx: as int-ptr! s/offset
					idx: p-idx/value
					sz: (as-integer (as int-ptr! s/tail) - p-idx) >> 2
				][
					idx: keys/i
					sz: 1
				]
				k: blk + idx
				if all [
					_BUCKET_IS_NOT_DEL(flags ii sh)
					actions/compare k key COMP_EQUAL
				][
					loop sz [
						either last? [		;-- backward searching
							align: head - 1 - idx
						][
							align: idx - head
						]
						if all [
							actions/compare k key op
							align // skip = 0
						][
							either reverse? [
								if all [idx < head idx > last-idx][last-idx: idx find?: yes]
							][
								if idx >= head [
									either last? [
										if idx > last-idx [last-idx: idx find?: yes]
									][
										if idx < last-idx [last-idx: idx find?: yes]
									]
								]
							]
						]
						if chain? [
							p-idx: p-idx + 1
							idx: p-idx/value
							k: blk + idx
						]
					]
					if find? [return blk + last-idx]
				]
			]

			i: i + step and mask
			_HT_CAL_FLAG_INDEX(i ii sh)
			i: i + 1

			step: step + 1
			if i = last [
				if set-header? [key/header: saved-type]
				return either find? [blk + last-idx][null]
			]
		]

		if set-header? [key/header: saved-type]
		if find? [return blk + last-idx]
		either _BUCKET_IS_EITHER(flags ii sh) [null][blk + keys/i]
	]

	delete: func [
		node	[node!]
		key		[red-value!]
		/local s [series!] h [hashtable!] i ii idx c-idx [integer!]
			sh [integer!] flags keys chain [int-ptr!] indexes [int-ptr!]
	][
		s: as series! node/value
		h: as hashtable! s/offset
		assert h/n-buckets > 0

		either h/indexes = null [				;-- map!
			key: key + 1
			key/header: MAP_KEY_DELETED
		][										;-- hash!
			s: as series! h/keys/value
			keys: as int-ptr! s/offset
			s: as series! h/flags/value
			flags: as int-ptr! s/offset
			s: as series! h/blk/value
			i: (as-integer key - s/offset) >> 4 + 1
			s: as series! h/indexes/value
			indexes: as int-ptr! s/offset
			idx: indexes/i
			if keys/idx < 0 [
				c-idx: 0 - keys/idx
				chain: array/pick-ptr h/chains c-idx
				i: array/find-int chain i - 1
				assert i >= 0
				array/remove-at chain i size? integer!
				either zero? array/length? chain [
					array/poke-ptr h/chains c-idx null
					keys/idx: c-idx
				][exit]
			]
			i: idx - 1
			_HT_CAL_FLAG_INDEX(i ii sh)
			_BUCKET_SET_DEL_TRUE(flags ii sh)
		]
		h/size: h/size - 1
	]

	copy: func [				;-- only map! use it
		node	[node!]
		blk		[node!]
		return: [node!]
		/local s [series!] h [hashtable!] ss [series!] hh [hashtable!]
			new [node!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		new: copy-series s
		ss: as series! new/value
		hh: as hashtable! ss/offset

		hh/flags: copy-series as series! h/flags/value
		hh/keys: copy-series as series! h/keys/value
		hh/blk: blk
		new
	]

	clear-map: func [
		node	[node!]
		/local
			s	[series!]
			h	[hashtable!]
	][
		s: as series! node/value
		h: as hashtable! s/offset
		h/size: 0
		h/n-occupied: 0
		array/clear h/blk
		s: as series! h/flags/value
		fill as byte-ptr! s/offset as byte-ptr! s/tail #"^(AA)"
	]

	clear: func [				;-- only for clear hash! datatype
		node	[node!]
		head	[integer!]
		size	[integer!]
		/local s [series!] h [hashtable!] flags [int-ptr!] i [integer!] del? [logic!]
			ii idx c-idx [integer!] sh n [integer!] indexes keys chain [int-ptr!]
	][
		if zero? size [exit]

		s: as series! node/value
		h: as hashtable! s/offset

		s: as series! h/blk/value
		n: (as-integer s/tail - s/offset) >> 4
		if head + size > n [size: n - head]
		if n = size [	;-- clear all
			h/size: 0
			h/n-occupied: 0
			fill-series h/flags #"^(AA)"
			fill-series h/indexes #"^(FF)"
			array/clear h/chains
			exit
		]

		;h/n-occupied: h/n-occupied - size		;-- enable it when we have shrink
		h/size: h/size - size
		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		s: as series! h/indexes/value
		indexes: (as int-ptr! s/offset) + head
		until [
			del?: yes
			idx: indexes/value
			assert idx > 0
			if keys/idx < 0 [
				c-idx: 0 - keys/idx
				chain: array/pick-ptr h/chains c-idx
				i: array/find-int chain head
				assert i >= 0
				array/remove-at chain i size? integer!
				either zero? array/length? chain [
					array/poke-ptr h/chains c-idx null
					keys/idx: c-idx
				][del?: no]
			]
			if del? [
				i: idx - 1
				_HT_CAL_FLAG_INDEX(i ii sh)
				_BUCKET_SET_DEL_TRUE(flags ii sh)
			]
			head: head + 1
			indexes: indexes + 1
			size: size - 1
			zero? size
		]
	]

	destroy: func [
		node [node!]
	][
		;Let GC do the work?
	]

	refresh: func [
		node	[node!]
		offset	[integer!]
		head	[integer!]
		size	[integer!]
		change? [logic!]					;-- deleted or inserted items
		return: [integer!]
		/local s [series!] h [hashtable!] indexes chain p e keys index flags [int-ptr!]
			i c-idx idx part ii sh n [integer!] table [node!] saved [logic!]
	][
		if size > 30000 [return HASH_TABLE_ERR_REHASH]

		saved: collector/active?
		collector/active?: no

		if null? refresh-buffer [
			refresh-buffer: as red-hash! ALLOC_TAIL(root)
			refresh-buffer/header: TYPE_MAP
			refresh-buffer/node: alloc-bytes 4
			refresh-buffer/table: init 1024 null HASH_TABLE_INTEGER 0
		]
		table: refresh-buffer/table

		s: as series! node/value
		h: as hashtable! s/offset
		assert h/indexes <> null
		assert h/n-buckets > 0

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		ii: head							;-- save head

		s: as series! h/indexes/value
		indexes: as int-ptr! s/offset

		n: size
		while [n > 0][
			index: indexes + head
			i: index/value
			either keys/i < 0 [				;-- chain mode
				chain: array/pick-ptr h/chains 0 - keys/i
				if null? get-value table as-integer chain [
					put-key table as-integer chain
					s: as series! chain/value
					p: as int-ptr! s/offset
					e: as int-ptr! s/tail
					while [p < e][
						if p/value >= ii [
							p/value: p/value + offset
						]
						p: p + 1
					]
				]
			][
				keys/i: keys/i + offset
			]
			head: head + 1
			n: n - 1
		]
		clear-map table

		if change? [
			head: ii						;-- restore head
			either negative? offset [		;-- need to delete some entries
				part: offset
				s: as series! h/flags/value
				flags: as int-ptr! s/offset
				while [negative? part][
					index: indexes + head + part
					i: index/value
					if keys/i < 0 [
						c-idx: 0 - keys/i
						chain: array/pick-ptr h/chains c-idx
						idx: array/find-int chain head + part
						assert idx >= 0
						array/remove-at chain idx size? integer!
						either zero? array/length? chain [
							array/poke-ptr h/chains c-idx null
							keys/i: c-idx
						][part: part + 1 continue]
					]
					i: i - 1
					_HT_CAL_FLAG_INDEX(i ii sh)
					_BUCKET_SET_DEL_TRUE(flags ii sh)
					h/size: h/size - 1
					part: part + 1
				]
			][								;-- may need to expand indexes
				s: as series! h/indexes/value
				if size + head + offset << 2 > s/size [
					s: expand-series-filled s size + head + offset << 3 #"^(FF)"
					indexes: as int-ptr! s/offset
					s/tail: as cell! (as byte-ptr! s/offset) + s/size
				]
			]
			move-memory
				as byte-ptr! (indexes + head + offset)
				as byte-ptr! indexes + head
				size * 4
		]
		collector/active?: saved
		HASH_TABLE_ERR_OK
	]

	move: func [
		node	[node!]
		dst		[integer!]
		src		[integer!]
		items	[integer!]
		/local s [series!] h [hashtable!] indexes [int-ptr!]
			index [integer!] part [integer!] head [integer!] temp [byte-ptr!]
	][
		if all [src <= dst dst < (src + items)][exit]

		s: as series! node/value
		h: as hashtable! s/offset
		s: as series! h/indexes/value
		indexes: as int-ptr! s/offset

		part: dst - src
		if part > 0 [part: part - (items - 1)]
		refresh node part src items no

		either negative? part [
			part: 0 - part
			index: items
			head: dst
		][
			index: 0 - items
			head: src + items
		]
		refresh node index head part no

		if dst > src [dst: dst - items + 1]
		items: items * 4
		temp: allocate items
		copy-memory temp as byte-ptr! indexes + src items
		move-memory
			as byte-ptr! (indexes + head + index)
			as byte-ptr! indexes + head
			part * 4
		copy-memory as byte-ptr! indexes + dst temp items
		free temp
	]

	to-lower: func [				;-- Latin1 locale only, TBD: locale support
		str		[byte-ptr!]
		len		[integer!]
		return: [byte-ptr!]
		/local
			n	[integer!]
	][
		if len > str-buffer-sz [
			free str-buffer
			str-buffer: allocate len
		]
		n: 1
		loop len [
			either any [
				str/n > #"Z"
				str/n < #"A"
			][
				str-buffer/n: str/n
			][
				str-buffer/n: str/n or #"`"
			]
			n: n + 1
		]
		str-buffer
	]

	compare-cstr: func [
		cstr1	[byte-ptr!]
		cstr2	[byte-ptr!]
		len		[integer!]
		strict?	[logic!]
		return: [integer!]
	][
		either strict? [
			compare-memory cstr1 cstr2 len
		][
			platform/strnicmp cstr1 cstr2 len
		]
	]

	put-symbol: func [
		node	[node!]
		cstr	[byte-ptr!]
		len		[integer!]
		opt?	[logic!]			;-- don't put if found
		return: [integer!]			;-- return symbol id
		/local
			s [series!] h [hashtable!] x [integer!] i [integer!] site [integer!]
			last [integer!] mask [integer!] step [integer!] keys [int-ptr!]
			hash [integer!] n-buckets [integer!] flags [int-ptr!] ii [integer!]
			sh [integer!] blk [red-symbol!] idx [integer!] del? [logic!] k [red-symbol!]
			vsize [integer!] blk-node [series!] find? [logic!] xx [integer!] new? [logic!]
			len2 [integer!] strict? [logic!] p [byte-ptr!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		if h/n-occupied >= h/upper-bound [			;-- update the hash table
			vsize: either h/n-buckets > (h/size << 1) [-1][1]
			n-buckets: h/n-buckets + vsize
			resize node n-buckets << 4
		]

		blk-node: as series! h/blk/value
		blk: as red-symbol! blk-node/offset
		idx: (as-integer blk-node/tail - as cell! blk) >> 4

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		n-buckets: h/n-buckets + 1
		x:	  n-buckets
		site: n-buckets
		mask: n-buckets - 2
		hash: murmur3-x86-32 to-lower cstr len len
		strict?: not opt?
		loop 2 [	;-- first try: case-sensitive comparison, second try: case-insensitive comparison
			find?: yes
			i: hash and mask
			_HT_CAL_FLAG_INDEX(i ii sh)
			i: i + 1									;-- 1-based index
			either _BUCKET_IS_EMPTY(flags ii sh) [x: i break][
				step: 0
				last: i
				while [
					find?: _BUCKET_IS_NOT_EMPTY(flags ii sh)
					find?
				][
					k: as red-symbol! blk + keys/i
					s: as series! k/cache/value
					len2: as-integer (s/tail - s/offset)
					either any [
						len2 <> len
						0 <> compare-cstr as byte-ptr! s/offset cstr len strict?
					][
						i: i + step and mask
						_HT_CAL_FLAG_INDEX(i ii sh)
						i: i + 1
						step: step + 1
						if i = last [x: site find?: no break]
					][break]
				]
				x: i
			]
			either any [find? opt?][break][xx: x strict?: no]
		]

		_HT_CAL_FLAG_INDEX((x - 1) ii sh)
		either _BUCKET_IS_EMPTY(flags ii sh) [
			k: as red-symbol! alloc-tail blk-node
			keys/x: idx
			len2: -1
		][
			len2: keys/x + 1
			either any [strict? opt?][return len2][
				k: as red-symbol! alloc-tail blk-node
				_HT_CAL_FLAG_INDEX((xx - 1) ii sh)
				keys/xx: idx
			]
		]

		_BUCKET_SET_BOTH_FALSE(flags ii sh)
		h/size: h/size + 1
		h/n-occupied: h/n-occupied + 1

		blk-node: as series! h/blk/value
		blk: as red-symbol! blk-node/offset

		k/header: TYPE_UNSET
		node: alloc-bytes len + 1		;-- add NUL bytes to make it compatible with C string
		s: as series! node/value
		p: as byte-ptr! s/offset
		copy-memory p cstr len
		p: p + len
		p/1: null-byte
		s/tail: as red-value! p
		k/cache: node
		k/node: null
		k/alias: len2
		k/header: TYPE_SYMBOL

		(as-integer k - blk) >> 4 + 1
	]

	get-ctx-symbol: func [
		node		[node!]
		key			[integer!]				;-- symbol id
		case?		[logic!]				;-- YES: case insensitive
		ctx			[node!]					;-- if cxt <> null, create a new word in the context
		new-id		[int-ptr!]
		return:		[integer!]
		/local
			s		[series!]
			h		[hashtable!]
			i		[integer!]
			flags	[int-ptr!]
			last	[integer!]
			mask	[integer!]
			step	[integer!]
			keys	[int-ptr!]
			ii		[integer!]
			hash	[integer!]
			kk		[integer!]
			sh		[integer!]
			blk		[red-word!]
			k		[red-word!]
			sym		[integer!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		if all [ctx <> null h/n-occupied >= h/upper-bound][			;-- update the hash table
			i: either h/n-buckets > (h/size << 1) [-1][1]
			kk: h/n-buckets + i
			resize node kk << 4
		]

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		s: as series! h/blk/value
		blk: as red-word! s/offset

		hash: symbol/resolve key
		kk: either case? [hash][key]
		mask: h/n-buckets - 1
		i: hash and mask
		_HT_CAL_FLAG_INDEX(i ii sh)
		i: i + 1
		last: i
		step: 0
		while [_BUCKET_IS_NOT_EMPTY(flags ii sh)][ 
			k: blk + keys/i
			sym: either case? [symbol/resolve k/symbol][k/symbol]
			either kk <> sym [
				i: i + step and mask
				_HT_CAL_FLAG_INDEX(i ii sh)
				i: i + 1
				step: step + 1
				if i = last [assert 0 = 1 break]		;-- should not happen
			][break]
		]

		either ctx <> null [
			either _BUCKET_IS_EMPTY(flags ii sh) [
				_BUCKET_SET_BOTH_FALSE(flags ii sh)
				h/size: h/size + 1
				h/n-occupied: h/n-occupied + 1
				ii: (as-integer s/tail - s/offset) >> 4	;-- index is zero-base
				keys/i: ii

				k: as red-word! alloc-tail s
				k/header: TYPE_WORD						;-- force word! type
				k/index: ii
				k/ctx: ctx
				k/symbol: key
				new-id/value: ii
				-1
			][new-id/value: keys/i keys/i]
		][
			either _BUCKET_IS_EMPTY(flags ii sh) [-1][keys/i]
		]
	]

	get-ctx-word: func [
		ctx		[red-context!]
		idx		[integer!]				;-- word index
		return:	[red-word!]
		/local
			s	[series!]
			h	[hashtable!]
	][
		s: as series! ctx/symbols/value
		h: as hashtable! s/offset
		s: as series! h/blk/value 
		as red-word! s/offset + idx
	]

	get-ctx-words: func [
		ctx		[red-context!]
		return:	[series!]
		/local
			s	[series!]
			h	[hashtable!]
	][
		s: as series! ctx/symbols/value
		h: as hashtable! s/offset
		as series! h/blk/value 
	]

	get-ctx-symbols: func [
		ctx		[red-context!]
		return:	[node!]
		/local
			s	[series!]
			h	[hashtable!]
	][
		s: as series! ctx/symbols/value
		h: as hashtable! s/offset
		h/blk
	]
]
