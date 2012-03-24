Red/System [
	Title:   "Datatype! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %datatype.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

red-datatype!: alias struct! [
	header 	[integer!]							;-- cell header only, no payload
]

append-datatype: func [
	blk			[node!]							;-- storage place (at tail of block)
	type		[integer!]						;-- type ID
	return:		[red-value!]					;-- return unset cell pointer
	/local
		cell 	[red-datatype!]
][
	cell: as red-datatype! alloc-at-tail blk
	cell/header: RED_TYPE_DATATYPE				;-- implicit reset of all header flags
	as red-value! cell
]
