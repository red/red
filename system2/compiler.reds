Red/System [
	Title:   "Red/System compiler"
	File: 	 %compiler.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

compiler: context [
	#include %utils/vector.reds
	#include %utils/mempool.reds
	#include %utils/hashmap.reds
	#include %parser.reds

	_mempool: as mempool! 0

	;@@ the memory returned should be zeroed
	malloc: func [size [integer!] return: [byte-ptr!]][
		mempool/alloc _mempool size
	]


	comp-dialect: func [
		src		[red-block!]
		job		[red-object!]
	][
		parser/parse-context src null no
	]

	init: does [
		_mempool: mempool/make
	]

	clean: does [
		mempool/destroy _mempool
	]
]