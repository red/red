Red/System [
	File: 	 %mempool.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define MEM_CHUNK_SIZE _2MB

mempool!: alias struct! [
	used		[integer!]
	chunk		[byte-ptr!]
	pool		[vector!]
]

mempool: context [

	add-chunk: func [
		m		[mempool!]
	][
		m/used: 0
		m/chunk: zero-alloc MEM_CHUNK_SIZE
		vector/append-ptr m/pool m/chunk
	]

	make: func [
		return: [mempool!]
		/local
			m	[mempool!]
	][
		m: as mempool! allocate size? mempool!
		m/pool: vector/make size? byte-ptr! 128
		add-chunk m
		m
	]

	alloc: func [
		m		[mempool!]
		size	[integer!]
		return: [byte-ptr!]
		/local
			p	[byte-ptr!]
	][
		assert size <= MEM_CHUNK_SIZE
		if m/used + size > MEM_CHUNK_SIZE [add-chunk m]
		p: m/chunk + m/used
		m/used: m/used + size
		p
	]

	destroy: func [
		m		[mempool!]
	][
		0
	]
]