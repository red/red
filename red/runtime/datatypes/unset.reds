Red/System [
	Title:   "Unset! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %unset.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

red-unset!: alias struct! [
	header 	[integer!]							;-- cell header only, no payload
]

unset-value: declare red-value!					;-- preallocate unset! value
unset-value/header: RED_TYPE_UNSET

append-unset: func [
	blk			[node!]							;-- storage place (at tail of block)
	return:		[red-value!]					;-- return unset cell pointer
	/local
		cell 	[red-unset!]
][
	cell: as red-unset! alloc-at-tail blk
	cell/header: RED_TYPE_UNSET					;-- implicit reset of all header flags
	as red-value! cell
]
