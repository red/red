Red/System [
	Title:   "Block datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %block.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]


#define series! series-buffer!

;series-buffer!: alias struct! [
;	flags	[integer!]						;-- series flags
;	size	[integer!]						;-- size of allocated buffer
;	node	[int-ptr!]						;-- point back to referring node
;	head	[integer!]						;-- series buffer head index
;	tail	[integer!]						;-- series buffer tail index 
;]

make-series: func [
	size 	[integer!]						;-- number of cells to pre-allocate
	parent	[block!]
	return:	[node!]
	/local 
		p	[node!]
		blk	[block!]
][
	p: alloc-series size size? cell!
	
	
	if parent <> null [
		blk: as block! parent
		blk/header: RED_TYPE_BLOCK
		blk/head: 	0
		blk/series: p
	]
	p
]

append-block: func [

][

]

mold-block: func [
	blk 	[block!]
	buffer	[node!]
	part	[integer!]
][

]