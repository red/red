Red/System [
	Title:   "None! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %none.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

red-none!: alias struct! [
	header 	[integer!]							;-- cell header only, no payload
]

none-value: declare red-value!					;-- preallocate none! value
none-value/header: RED_TYPE_NONE

append-none: func [
	blk			[node!]							;-- storage place (at tail of block)
	return:		[red-value!]					;-- return unset cell pointer
	/local
		cell 	[red-none!]
][
	cell: as red-none! alloc-at-tail blk
	cell/header: RED_TYPE_NONE
	as red-value! cell
]
