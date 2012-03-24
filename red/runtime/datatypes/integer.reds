Red/System [
	Title:   "Integer! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %integer.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

red-integer!: alias struct! [
	header 	[integer!]							;-- cell header
	padding	[integer!]							;-- align value on 64-bit boundary
	value	[integer!]							;-- 32-bit signed integer value
]

append-integer: func [
	blk			[node!]							;-- storage place (at tail of block)
	i 			[integer!]						;-- integer value 
	return:		[red-value!]					;-- return integer cell pointer
	/local
		cell 	[red-integer!]
][
	cell: as red-integer! alloc-at-tail blk
	cell/header: RED_TYPE_INTEGER				;-- implicit reset of all header flags
	cell/value: i
	as red-value! cell
]

get-integer: func [
	value		[red-value!]
	return: 	[integer!]
	/local
		cell	[red-integer!]
][
	cell: as red-integer! value
	cell/value
]
