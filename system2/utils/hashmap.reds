Red/System [
	Title:   "Hash Map"
	File: 	 %hashmap.red
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"	
]

hashmap: context [
	make: func [
		size	[integer!]
		return: [int-ptr!]
	][
		red/_hashtable/rs-init size
	]

	put: func [
		m	[int-ptr!]
		key [integer!]
		val [int-ptr!]
	][
		red/_hashtable/rs-put m key as-integer val
	]

	get: func [
		m	[int-ptr!]
		key [integer!]
		return: [ptr-ptr!]
	][
		as ptr-ptr! red/_hashtable/rs-get m key
	]

	size?: func [
		m	[int-ptr!]
		return: [integer!]
	][
		red/_hashtable/rs-size? m
	]

	next: func [
		m	[int-ptr!]
		pos [int-ptr!]
		return: [int-ptr!]
	][
		red/_hashtable/rs-next m pos
	]
]

#define HASH_TABLE_MAP		1

token-map: context [
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

	make: func [
		size	[integer!]
		return: [int-ptr!]
		/local
			blk [red-block! value]
	][
		block/make-at :blk size
		red/_hashtable/init size blk HASH_TABLE_MAP 1
	]

	put: func [
		m	[int-ptr!]
		key [cell!]
		val [int-ptr!]
		/local
			s	[series!]
			t	[hashtable!]
			v	[red-handle!]
	][
		t: as hashtable! m
		s: as series! t/blk/value
		key: red/copy-cell key as cell! red/alloc-tail-unit s (size? cell!) << 1
		v: as red-handle! key + 1
		v/header: TYPE_UNSET
		v/value: as-integer val
		red/_hashtable/put m key
	]

	get: func [
		m	[int-ptr!]
		key [cell!]
		return: [red-handle!]
	][
		key: red/_hashtable/get m key 0 0 COMP_STRICT_EQUAL no no
		either key <> null [as red-handle! key + 1][null]
	]
]