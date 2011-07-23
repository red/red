Red/System [
	Title:   "Red memory manager"
	Author:  "Nenad Rakocevic"
	File: 	 %allocator.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

;-- New built-in natives worth adding to Red/System??
; get-bit n value
; set-bit n value
; clear-bit n value
; bit-set? n value

;-- cell header bits layout --
;   31: mark								;-- mark as referenced for the GC (mark phase)
;   30: lock								;-- lock slot for current thread access only
;   29: immutable							;-- mark as read-only (series only)
;   28: new-line?							;-- new-line marker (before the slot)
;   8-28: <reserved>
;   0-7: datatype ID						;-- datatype number
	
int-array!: alias struct! [ptr [byte-ptr!]]

cell!: alias struct! [
	header	[integer!]						;-- cell's header flags
	data1	[integer!]						;-- placeholders to make a 128-bit cell
	data2	[integer!]
	data3	[integer!]
]

series-frame!: alias struct! [				;-- series frame header
	next	[series-frame!]					;-- next frame or null
	prev	[series-frame!]					;-- previous frame or null
	buffer	[byte-ptr!]
]

node-frame!: alias struct! [				;-- node frame header
	next	[node-frame!]					;-- next frame or null
	prev	[node-frame!]					;-- previous frame or null
	nodes	[integer!]						;-- number of nodes
	bottom	[int-array!]					;-- bottom of stack (last entry)
	top		[int-ptr!]						;-- top of stack (first entry)
]

memory: declare struct! [
	n-head	  [node-frame!]					;-- head of node frames list
	n-current [node-frame!]					;-- currently used node frame
	n-tail	  [node-frame!]					;-- tail of node frames list
	s-head	  [series-frame!]				;-- head of series frames list
	s-current [series-frame!]				;-- currently used series frame
	s-tail	  [series-frame!]				;-- tail of series frames list
]

;-------------------------------------------
;-- Format the node frame stack by filling it with pointers to all nodes
;-------------------------------------------
format-node-stack: func [
	frame [node-frame!]						;-- node frame to format
	/local node ptr
][
	ptr: as int-ptr! frame/bottom			;-- point to bottom of stack
	node: ptr + frame/nodes					;-- first free node address
	until [
		ptr/value: node						;-- store free node address on stack
		node: node + 1
		ptr: ptr + 1
		ptr > frame/top						;-- until the stack is filled up
	]
]

;-------------------------------------------
;-- Allocate a node frame buffer and initialize it
;-------------------------------------------
alloc-node-frame: func [
	size 	[integer!]						;-- nb of nodes
	return:	[node-frame!]					;-- newly initialized frame
	/local sz frame
][
	assert size > 0
	sz: size * 2 + size? node-frame! 		;-- total required size of node frame
	frame: as node-frame! allocate-virtual page-round sz no ;-- RW only
	
	frame/prev:  null
	frame/next:  null
	frame/nodes: size
	frame/bottom: frame + 5					;-- 5 = size of frame header in words
	frame/top: frame/bottom + size - 1		;-- point to the top element
	
	either null? memory/n-head [
		memory/n-head: frame				;-- first item in the list
		memory/n-tail: frame
	][
		memory/n-tail/next: frame			;-- append new item at end of the lost
		frame/prev: memory/n-tail			;-- link back to previous tail
		memory/n-tail: frame				;-- now tail is the new item
	]
	
	format-node-stack frame					;-- prepare the node frame for use
	frame
]

;-------------------------------------------
;-- Release a node frame buffer
;-------------------------------------------
free-node-frame: func [
	frame [node-frame!]
][
	either null? frame/prev [
		memory/n-head: frame/next
	][
		frame/prev/next: frame/next
	]
	
	either null? frame/next [
		memory/n-tail: frame/prev
	][
		frame/next/prev: frame/prev
	]
	
	assert not all [
		null? memory/n-head
		null? memory/n-tail
	]
	
	free-virtual as int-ptr! frame
]

;-------------------------------------------
;-- Allocate a series frame buffer
;-------------------------------------------
alloc-series-frame: func [

][

]

;-------------------------------------------
;-- Release a series frame buffer
;-------------------------------------------
free-series-frame: func [

][

]

;-------------------------------------------
;-- Allocate a series
;-------------------------------------------
alloc-series: func [

][

]

;-------------------------------------------
;-- Free a series
;-------------------------------------------
free-series: func [

][

]

;-------------------------------------------
;-- Expand a series to a new size
;-------------------------------------------
expand-series: func [

][

]