Red/System [
	Title:   "Common datatypes base functions"
	Author:  "Nenad Rakocevic"
	File: 	 %value.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#define red-value!	cell!

last-value: declare red-value!
last-value/header: RED_TYPE_UNSET

set-type: func [
	cell 		[cell!]
	type		[integer!]
][
	cell/header: cell/header and type-mask or type
]

alloc-at-tail: func [
	blk		[node!]
	return: [cell!]
	/local 
		s		[series!]
		cell	[red-value!]
][
	s: as series! blk/value
	if (as byte-ptr! s/tail + 1) >= ((as byte-ptr! s + 1) + s/size) [
		s: expand-series s 0
	]
	
	cell: as cell! (as byte-ptr! s + 1) + s/tail
	;-- ensure that cell is within series boundary
	assert (as byte-ptr! cell) < ((as byte-ptr! s + 1) + s/size)
	
	s/tail: s/tail + 1								;-- move tail to next cell
	cell
]
