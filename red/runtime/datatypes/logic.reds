Red/System [
	Title:   "Logic! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %logic.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

red-logic!: alias struct! [
	header 	[integer!]							;-- cell header
	value	[logic!]
]

true-value: declare red-logic!					;-- preallocate TRUE value
true-value/value: true

false-value: declare red-logic!					;-- preallocate FALSE value
false-value/value: false


append-logic: func [
	blk			[node!]							;-- storage place (at tail of block)
	value		[logic!]						;-- logic value
	return:		[red-value!]					;-- return logic cell pointer
	/local
		cell 	[red-logic!]
][
	cell: as red-logic! alloc-at-tail blk
	cell/header: RED_TYPE_LOGIC					;-- implicit reset of all header flags
	cell/value: value
	as red-value! cell
]
