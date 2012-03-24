Red/System [
	Title:   "Block! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %block.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

red-block!: alias struct! [
	header 	[integer!]							;-- cell header
	head	[integer!]							;-- block's head index
	node	[node!]								;-- series node pointer
]

make-block: func [
	size 	[integer!]							;-- number of cells to pre-allocate
	parent	[red-block!]
	return:	[node!]
	/local 
		p	[node!]
		blk	[red-block!]
][
	p: alloc-series size size? cell! default-offset
	
	if parent <> null [
		blk: as red-block! parent
		blk/header: RED_TYPE_BLOCK				;-- implicit reset of all header flags
		blk/head: 	0
		blk/node:   p
	]
	p
]

mold-block: func [
	blk 	[red-block!]
	buffer	[node!]
	part	[integer!]
][

]

pick-block: func [
	blk 	[node!]
	idx		[integer!]
	return: [red-value!]
	/local
		s		[series!]
		cell	[red-value!]
][
	assert idx > 0								;-- only positive indexes for internal use
	s: as series! blk/value
	cell: as cell! (as byte-ptr! s + 1) + s/offset
	cell: cell + idx
	
	either cell > s/tail [none-value][cell]
]