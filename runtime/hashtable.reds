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

	make: func [
		sz		[integer!]
		unit	[integer!]
		return:	[node!]
		/local
			node [node!]
			s	 [series!]
	][
		node: alloc-bytes sz * unit
		s: as series! node/value
		s/flags: s/flags and flag-unit-mask or unit
		node
	]

	length?: func [
		node	[node!]
		return: [integer!]
		/local
			s	[series!]
	][
		s: as series! node/value
		(as-integer s/tail - s/offset) >> (log-b GET_UNIT(s))
	]

	clear: func [
		node	[node!]
		/local
			s	[series!]
	][
		s: as series! node/value
		s/tail: s/offset
	]

	clear-at: func [
		node	[node!]
		offset	[integer!]			;-- 1-based index
		/local
			s	[series!]
	][
		s: as series! node/value
		s/tail: as cell! (as byte-ptr! s/offset) + (offset - 1 << (log-b GET_UNIT(s)))
	]

	copy: func [
		node	[node!]
		return: [node!]
	][
		copy-series as series! node/value
	]

	get-ptr: func [
		node	[node!]
		return: [byte-ptr!]
		/local
			s	[series!]
	][
		s: as series! node/value
		as byte-ptr! s/offset
	]

	append-byte: func [
		node	[node!]
		val		[byte!]
		/local
			s	[series!]
			p	[byte-ptr!]
	][
		s: as series! node/value
		p: alloc-tail-unit s size? byte!
		p/value: val
	]

	pick-byte: func [
		node		[node!]
		idx			[integer!]		;-- 1-based index
		return:		[byte!]
		/local
			s		[series!]
			p		[byte-ptr!]
	][
		s: as series! node/value
		p: as byte-ptr! s/offset
		assert p + idx - 1 < as byte-ptr! s/tail
		p/idx
	]

	append-bytes: func [
		node	[node!]
		data	[byte-ptr!]
		len		[integer!]
		return: [byte-ptr!]
		/local
			s	[series!]
			p	[byte-ptr!]
	][
		s: as series! node/value
		p: alloc-tail-unit s len
		copy-memory p data len
		p
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

	insert-ptr: func [
		node		[node!]
		ptr			[int-ptr!]
		offset		[integer!]
		/local
			s		[series!]
			p		[byte-ptr!]
			pp		[ptr-ptr!]
			unit	[integer!]
	][
		s: as series! node/value
		unit: size? int-ptr!

		if ((as byte-ptr! s/tail) + unit) > ((as byte-ptr! s + 1) + s/size) [
			s: expand-series s 0
		]
		p: (as byte-ptr! s/offset) + (offset << (log-b unit))

		move-memory		;-- make space
			p + unit
			p
			as-integer (as byte-ptr! s/tail) - p

		pp: as ptr-ptr! p
		pp/value: ptr
		s/tail: as cell! (as byte-ptr! s/tail) + unit
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

	remove-ptr: func [
		node	[node!]
		val		[int-ptr!]
		/local
			n	[integer!]
	][
		n: find-ptr node val
		if n <> -1 [remove-at node n size? int-ptr!]
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

#define HASH_TABLE_HASH			0
#define HASH_TABLE_MAP			1
#define HASH_TABLE_SYMBOL		2
#define HASH_TABLE_NODE_KEY		3		;-- key must be a node, GC will mark it
#define HASH_TABLE_OWNERSHIP	4

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

	rs-hashtable!: alias struct! [
		size		[integer!]
		flags		[int-ptr!]
		key-vals	[int-ptr!]
		n-occupied	[integer!]
		n-buckets	[integer!]
		upper-bound	[integer!]
	]

	dump: func [
		table	[node!]
		/local
			s	[series!]
			h	[hashtable!]
			blk [red-value!]
			k	[red-value!]
			val [red-value!]
			int? [logic!]
			n-buckets key vsize j ii sh idx [integer!]
			keys flags int-key [int-ptr!]
	][
		s: as series! table/value
		h: as hashtable! s/offset
		int?: h/type >= HASH_TABLE_NODE_KEY
		s: as series! h/blk/value
		blk: s/offset
		s: as series! h/flags/value
		flags: as int-ptr! s/offset
		n-buckets: h/n-buckets

		s: as series! h/keys/value
		keys: as int-ptr! s/offset
		probe "^/== Deleted keys =="
		j: 0
		until [
			_HT_CAL_FLAG_INDEX(j ii sh)
			j: j + 1
			if _BUCKET_IS_DEL(flags ii sh) [
				idx: keys/j
				either int? [
					int-key: as int-ptr! ((as byte-ptr! blk) + idx)
					key: int-key/2
					print [as int-ptr! key " "]
					vsize: (as-integer h/indexes) >> 4
					val: (as red-value! int-key) + 1
					loop vsize - 1 [	;-- print values
						print [TYPE_OF(val) " "]
						val: val + 1
					]
				][
					k: blk + (idx and 7FFFFFFFh)
					print TYPE_OF(k)
					print " "
					if h/type <> HASH_TABLE_HASH [
						val: k + 1
						print TYPE_OF(val)
					]
				]
				print lf
			]
			j = n-buckets
		]
		probe "== Alive keys =="
		j: 0
		until [
			_HT_CAL_FLAG_INDEX(j ii sh)
			j: j + 1
			if _BUCKET_IS_HAS_KEY(flags ii sh) [
				idx: keys/j
				either int? [
					int-key: as int-ptr! ((as byte-ptr! blk) + idx)
					key: int-key/2
					print [as int-ptr! key " "]
					vsize: (as-integer h/indexes) >> 4
					val: (as red-value! int-key) + 1
					loop vsize - 1 [	;-- print values
						print [TYPE_OF(val) " "]
						val: val + 1
					]
				][
					k: blk + (idx and 7FFFFFFFh)
					print TYPE_OF(k)
					print " "
					if h/type <> HASH_TABLE_HASH [
						val: k + 1
						print TYPE_OF(val)
					]
				]
				print lf
			]
			j = n-buckets
		]
	]

	mark: func [
		ptr [int-ptr!]
		/local
			table [node!]
			node [node!]
			s	 [series!]
			h	 [hashtable!]
			val	 [red-value!]
			end	 [red-value!]
			p	 [ptr-ptr!]
			e	 [ptr-ptr!]
			type [integer!]
			vsize [integer!]
	][
		collector/keep ptr
		table: as node! ptr/value
		s: as series! table/value
		h: as hashtable! s/offset
		type: h/type
		if type = HASH_TABLE_HASH [
			collector/keep :h/indexes
			collector/keep :h/chains
			s: as series! h/chains/value
			p: as ptr-ptr! s/offset
			e: as ptr-ptr! s/tail
			while [p < e][
				if p/value <> null [collector/keep as int-ptr! p]
				p: p + 1
			]
		]
		collector/keep :h/flags
		collector/keep :h/keys

		if type >= HASH_TABLE_NODE_KEY [ 
			vsize: as integer! h/indexes
			vsize: vsize >> 4
			s: as series! h/blk/value
			val: s/offset
			end: s/tail
			while [val < end][
				collector/keep :val/data1	;-- mark node key
				node: as node! val/data1
				s: as series! node/value
				if GET_UNIT(s) = 16 [collector/mark-values s/offset s/tail]		
				val: val + vsize
			]
		]
		if type > 0 [collector/mark-block-node :h/blk]
	]

	sweep: func [
		table [node!]
		/local
			s	 [series!]
			h	 [hashtable!]
			val	 [red-value!]
			end	 [red-value!]
			obj  [red-object!]
			type [integer!]
			vsize [integer!]
			node [node!]
	][
		s: as series! table/value
		h: as hashtable! s/offset

		type: h/type
		assert type >= HASH_TABLE_NODE_KEY

		vsize: as integer! h/indexes
		vsize: vsize >> 4
		s: as series! h/blk/value
		val: s/offset
		end: s/tail
		while [val < end][
			if val/header = TYPE_UNSET [			;-- only sweep alive key. key was deleted if val/header = TYPE_VALUE
				node: as node! val/data1
				assert node <> null
				s: as series! node/value
				either s/flags and flag-gc-mark = 0 [
					delete-key table as-integer node
					val/data1: 0
				][
					if type = HASH_TABLE_OWNERSHIP [
						obj: as red-object! val + 2	;-- check owner
						s: as series! obj/ctx/value
						if s/flags and flag-gc-mark = 0 [
							delete-key table as-integer node
							val/data1: 0
						]
					]
				]
			]
			val: val + vsize
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
			TYPE_ALL_WORD [murmur3-x86-int symbol/resolve key/data2]
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
			TYPE_LOGIC [murmur3-x86-int key/data1]
			TYPE_ACTION
			TYPE_NATIVE [murmur3-x86-int key/data3]
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

	_alloc: func [
		size	[integer!]
		filler	[byte!]
		return: [byte-ptr!]
	][
		set-memory allocate size filler size
	]

	rs-init: func [
		size	[integer!]
		return: [int-ptr!]
		/local
			h			[rs-hashtable!]
			f-buckets	[float!]
			fsize		[float!]
	][
		h: as rs-hashtable! _alloc size? rs-hashtable! null-byte
		if size < 4 [size: 4]
		fsize: as-float size
		f-buckets: fsize / _HT_HASH_UPPER
		h/n-buckets: round-up as-integer f-buckets
		f-buckets: as-float h/n-buckets
		h/upper-bound: as-integer f-buckets * _HT_HASH_UPPER
		h/flags: as int-ptr! _alloc h/n-buckets >> 2 #"^(AA)"
		h/key-vals: as int-ptr! allocate h/n-buckets * 2 * size? int-ptr!
		as int-ptr! h
	]

	rs-size?: func [
		table	[int-ptr!]
		return: [integer!]
		/local
			h	[rs-hashtable!]
	][
		h: as rs-hashtable! table
		h/size
	]

	rs-next: func [
		table	[int-ptr!]
		pos		[int-ptr!]	;-- current position
		return: [int-ptr!]
		/local
			h	[rs-hashtable!]
			keys flags end [int-ptr!]
			n-buckets ii sh i [integer!]
	][
		h: as rs-hashtable! table
		keys: h/key-vals
		flags: h/flags
		n-buckets: h/n-buckets
		end: keys + (n-buckets * 2)
		i: either null? pos [
			pos: keys
			0
		][
			pos: pos + 2
			(as-integer pos - keys) >> 3
		]

		while [pos < end][
			_HT_CAL_FLAG_INDEX(i ii sh)
			if _BUCKET_IS_HAS_KEY(flags ii sh) [
				return pos
			]
			pos: pos + 2
			i: i + 1
		]
		null
	]

	rs-put: func [
		table	[int-ptr!]
		key		[integer!]
		value	[integer!]
		return: [logic!]		;-- return true if key already exist
		/local
			h [rs-hashtable!]
			x i site last mask step hash n-buckets ii sh new-size [integer!]
			keys flags k [int-ptr!]
			del? find? [logic!]
	][
		h: as rs-hashtable! table
		find?: false

		if h/n-occupied >= h/upper-bound [			;-- update the hash table
			new-size: either h/n-buckets > (h/size << 1) [-1][1]
			n-buckets: h/n-buckets + new-size
			rs-resize table n-buckets
		]

		keys: h/key-vals
		flags: h/flags
		n-buckets: h/n-buckets
		x:	  n-buckets
		site: n-buckets
		mask: n-buckets - 1
		hash: murmur3-x86-int key
		i: hash and mask
		_HT_CAL_FLAG_INDEX(i ii sh)
		either _BUCKET_IS_EMPTY(flags ii sh) [x: i][
			step: 0
			last: i
			while [
				del?: _BUCKET_IS_DEL(flags ii sh)
				k: keys + (i * 2)
				all [
					_BUCKET_IS_NOT_EMPTY(flags ii sh)
					any [
						del?
						k/1 <> key
					]
				]
			][
				if del? [site: i]
				step: step + 1
				i: i + step and mask
				_HT_CAL_FLAG_INDEX(i ii sh)
				if i = last [x: site break]
			]
			if x = n-buckets [
				x: either all [
					_BUCKET_IS_EMPTY(flags ii sh)
					site <> n-buckets
				][site][i]
			]
		]
		_HT_CAL_FLAG_INDEX(x ii sh)
		case [
			_BUCKET_IS_EMPTY(flags ii sh) [
				h/n-occupied: h/n-occupied + 1
			]
			_BUCKET_IS_DEL(flags ii sh) [0]
			true [find?: true]	;-- key already exist
		]
		k: keys + (x * 2)
		k/2: value
		unless find? [
			k/1: key
			_BUCKET_SET_BOTH_FALSE(flags ii sh)
			h/size: h/size + 1
		]
		find?
	]

	rs-get: func [
		table		[int-ptr!]
		key			[integer!]
		return:		[int-ptr!]		;-- return a pointer to the value, or NULL if not found
		/local
			h	[rs-hashtable!]
			idx [integer!]
	][
		idx: rs-get-idx table key
		either idx > -1 [
			h: as rs-hashtable! table
			h/key-vals + (idx * 2) + 1
		][null]
	]

	rs-delete: func [
		table		[int-ptr!]
		key			[integer!]
		/local
			h		[rs-hashtable!]
			idx		[integer!]
			ii sh	[integer!]
			flags	[int-ptr!]
	][
		idx: rs-get-idx table key
		if idx > -1 [
			_HT_CAL_FLAG_INDEX(idx ii sh)
			h: as rs-hashtable! table
			flags: h/flags
			if _BUCKET_IS_HAS_KEY(flags ii sh) [
				_BUCKET_SET_DEL_TRUE(flags ii sh)
				h/size: h/size - 1
			]
		]
	]

	rs-get-idx: func [
		table		[int-ptr!]
		key			[integer!]
		return:		[integer!]
		/local
			h [rs-hashtable!]
			i last mask step hash n-buckets ii sh [integer!]
			keys flags k [int-ptr!]
	][
		h: as rs-hashtable! table
		keys: h/key-vals
		flags: h/flags
		n-buckets: h/n-buckets
		mask: n-buckets - 1
		hash: murmur3-x86-int key
		i: hash and mask
		_HT_CAL_FLAG_INDEX(i ii sh)

		step: 0
		last: i
		while [
			k: keys + (i * 2)
			all [
				_BUCKET_IS_NOT_EMPTY(flags ii sh)
				any [
					_BUCKET_IS_DEL(flags ii sh)
					k/1 <> key
				]
			]
		][
			step: step + 1
			i: i + step and mask
			_HT_CAL_FLAG_INDEX(i ii sh)
			if i = last [return -1]
		]
		either _BUCKET_IS_EITHER(flags ii sh) [-1][i]
	]

	rs-resize: func [
		table			[int-ptr!]
		new-buckets		[integer!]
		return:			[integer!]
		/local
			h			[rs-hashtable!]
			i j mask	[integer!]
			step tmp	[integer!]
			keys k		[int-ptr!]
			n-buckets	[integer!]
			new-size	[integer!]
			break?		[logic!]
			flags		[int-ptr!]
			new-flags	[int-ptr!]
			new-keys	[int-ptr!]
			ii sh idx	[integer!]
			key val		[integer!]
			f			[float!]
	][
		h: as rs-hashtable! table

		flags: h/flags
		n-buckets: h/n-buckets
		new-buckets: round-up new-buckets
		if new-buckets < 4 [new-buckets: 4]
		f: as-float new-buckets
		new-size: as-integer f * _HT_HASH_UPPER + 0.5

		either h/size >= new-size [return 0][
			new-flags: as int-ptr! _alloc new-buckets >> 2 #"^(AA)"
			if n-buckets < new-buckets [
				new-keys: as int-ptr! realloc as byte-ptr! h/key-vals new-buckets * 2 * size? int-ptr!
				if null? new-keys [
					free as byte-ptr! new-flags
					return -1
				]
			]
		]

		j: 0
		mask: new-buckets - 1
		keys: new-keys
		until [
			_HT_CAL_FLAG_INDEX(j ii sh)
			if _BUCKET_IS_HAS_KEY(flags ii sh) [
				_BUCKET_SET_DEL_TRUE(flags ii sh)
				k: keys + (j * 2)
				key: k/1
				val: k/2
				break?: no
				until [									;-- kick-out process
					step: 0
					i: (murmur3-x86-int key) and mask
					_HT_CAL_FLAG_INDEX(i ii sh)
					while [_BUCKET_IS_NOT_EMPTY(new-flags ii sh)][
						step: step + 1
						i: i + step and mask
						_HT_CAL_FLAG_INDEX(i ii sh)
					]
					_BUCKET_SET_EMPTY_FALSE(new-flags ii sh)
					k: keys + (i * 2)
					either all [
						i < n-buckets
						_BUCKET_IS_HAS_KEY(flags ii sh)
					][
						tmp: k/1 k/1: key key: tmp		;-- swap key
						tmp: k/2 k/2: val val: tmp		;-- swap val
						_BUCKET_SET_DEL_TRUE(flags ii sh)
					][
						k/1: key
						k/2: val
						break?: yes
					]
					break?
				]
			]
			j: j + 1
			j = n-buckets
		]
		if n-buckets > new-buckets [			;-- shrink the hash table
			new-keys: as int-ptr! realloc as byte-ptr! h/key-vals new-buckets * 2 * size? integer!
		]
		free as byte-ptr! flags
		h/flags: new-flags
		h/key-vals: new-keys
		h/n-buckets: new-buckets
		h/n-occupied: h/size
		h/upper-bound: new-size
		0
	]

	rs-destroy: func [
		table	[int-ptr!]
		/local
			h	[rs-hashtable!]
	][
		if table <> null [
			h: as rs-hashtable! table
			free as byte-ptr! h/key-vals
			free as byte-ptr! h/flags
			free as byte-ptr! table
		]
	]

	rs-clear: func [
		table	[int-ptr!]
		/local
			h	[rs-hashtable!]
	][
		if table <> null [
			h: as rs-hashtable! table
			set-memory as byte-ptr! h/flags #"^(AA)" h/n-buckets >> 2
			h/size: 0
			h/n-occupied: 0
		]
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
			hash		[red-hash!]
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
		if type >= HASH_TABLE_NODE_KEY [h/indexes: as node! vsize + 1 << 4]

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
		either any [type >= HASH_TABLE_NODE_KEY blk = null][
			h/blk: alloc-cells size
		][
			h/blk: blk/node
			if type = HASH_TABLE_HASH [
				hash: as red-hash! stack/push* ;@@ push on stack to mark it properly, especially `h/chains`
				hash/header: TYPE_HASH
				hash/head: 0
				hash/node: h/blk
				hash/table: node
			]
			put-all node blk/head skip
			if type = HASH_TABLE_HASH [stack/pop 1]
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
			blk			[node!]
			new-blk		[node!]
			i sz		[integer!]
			start		[red-value!]
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

		blk: h/blk		;-- @@ put it on stack, so GC can mark it
		s: as series! blk/value
		start: s/offset
		end: s/tail
		i: 0
		h/blk: alloc-cells sz * len
		while [
			value: start + i
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

		int?: h/type >= HASH_TABLE_NODE_KEY
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
							hash: murmur3-x86-int int-key/2
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
		hash: murmur3-x86-int key
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
		hash: murmur3-x86-int key
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
		hash: murmur3-x86-int key
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
			sh [integer!] continue? [logic!] blk [red-value!] idx [integer!]
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

	copy: func [
		node	[node!]
		blk		[node!]
		return: [node!]
		/local s [series!] h [hashtable!] ss [series!] hh [hashtable!]
			new flags keys indexes chains [node!]
	][
		s: as series! node/value
		h: as hashtable! s/offset

		new: copy-series s
		ss: as series! new/value
		hh: as hashtable! ss/offset

		flags: copy-series as series! h/flags/value
		hh/flags: flags
		keys: copy-series as series! h/keys/value
		hh/keys: keys
		hh/blk: blk
		if h/type = HASH_TABLE_HASH [
			indexes: copy-series as series! h/indexes/value
			hh/indexes: indexes
			chains: copy-series as series! h/chains/value
			hh/chains: chains
		]
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
			i c-idx idx part ii sh n [integer!] table buf [node!]
	][
		if size > 30000 [return HASH_TABLE_ERR_REHASH]

		if null? refresh-buffer [
			buf: alloc-bytes 4
			table: init 1024 null HASH_TABLE_NODE_KEY 0
			refresh-buffer: as red-hash! ALLOC_TAIL(root)
			refresh-buffer/header: TYPE_MAP
			refresh-buffer/node: buf
			refresh-buffer/table: table
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
			strnicmp cstr1 cstr2 len
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
		i: (murmur3-x86-int hash) and mask
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
