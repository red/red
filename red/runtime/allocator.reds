Red/System [
	Title:   "Red memory allocator"
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
;   30: lock								;-- lock slot for active thread access only
;   29: immutable							;-- mark as read-only (series only)
;   28: new-line?							;-- new-line marker (before the slot)
;   8-28: <reserved>
;   0-7: datatype ID						;-- datatype number

#define size-of-2MB			2097152
#define size-of-16MB		16777216
#define nodes-per-frame		5000
#define node-frame-size		[((nodes-per-frame * 2 * size? pointer!) + size? node-frame!)]

#define series-in-use		10000000h
	
int-array!: alias struct! [ptr [int-ptr!]]

cell!: alias struct! [
	header	[integer!]						;-- cell's header flags
	data1	[integer!]						;-- placeholders to make a 128-bit cell
	data2	[integer!]
	data3	[integer!]
]

series-buffer!: alias struct! [
	size	[integer!]						;-- bitfield: 31: used/free, 30-24: reserved, 23-0: size
	referer	[int-ptr!]						;-- point back to refering node
]

series-frame!: alias struct! [				;-- series frame header
	next	[series-frame!]					;-- next frame or null
	prev	[series-frame!]					;-- previous frame or null
	heap	[series-buffer!]				;-- point to allocatable region
	tail	[byte-ptr!]						;-- point to last byte in allocatable region
]

node-frame!: alias struct! [				;-- node frame header
	next	[node-frame!]					;-- next frame or null
	prev	[node-frame!]					;-- previous frame or null
	nodes	[integer!]						;-- number of nodes
	bottom	[int-ptr!]						;-- bottom of stack (last entry, fixed)
	top		[int-ptr!]						;-- top of stack (first entry, moving)
]

memory: declare struct! [
	n-head	 [node-frame!]					;-- head of node frames list
	n-active [node-frame!]					;-- actively used node frame
	n-tail	 [node-frame!]					;-- tail of node frames list
	s-head	 [series-frame!]				;-- head of series frames list
	s-active [series-frame!]				;-- actively used series frame
	s-tail	 [series-frame!]				;-- tail of series frames list
	s-limit	 [integer!]						;-- size in bytes for the new series frames (1)
]
memory/s-limit: 131072						;-- 128KB
;; (1) Series frames size will grow from 128KB up to 2MB (arbitrary selected). This
;; range will need fine-tuning with real Red apps. This growing size, with low starting value
;; will allow small apps to not consume much memory while avoiding to penalize big apps.

;-------------------------------------------
;-- Format the node frame stack by filling it with pointers to all nodes
;-------------------------------------------
format-node-stack: func [
	frame [node-frame!]						;-- node frame to format
	/local node ptr
][
	ptr: frame/bottom						;-- point to bottom of stack
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
	assert positive? size
	sz: size * 2 * (size? pointer!) + (size? node-frame!) ;-- total required size for a node frame
	frame: as node-frame! allocate-virtual sz no ;-- RW only
	
	frame/prev:  null
	frame/next:  null
	frame/nodes: size
	frame/bottom: frame + 5					;-- 5 = size of frame header in words
	frame/top: frame/bottom + size - 1		;-- point to the top element
	
	either null? memory/n-head [
		memory/n-head: frame				;-- first item in the list
		memory/n-tail: frame
	][
		memory/n-tail/next: frame			;-- append new item at tail of the list
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
	frame [node-frame!]						;-- frame to release
][
	either null? frame/prev [				;-- if frame = head
		memory/n-head: frame/next			;-- head now points to next one
	][
		either null? frame/next [			;-- if frame = tail
			memory/n-tail: frame/prev		;-- tail is now at one position back
		][
			frame/prev/next: frame/next		;-- link preceding frame to next frame
			frame/next/prev: frame/prev		;-- link back next frame to preceding frame
		]
	]

	assert not all [						;-- ensure that list is not empty
		null? memory/n-head
		null? memory/n-tail
	]
	
	free-virtual as int-ptr! frame			;-- release the memory to the OS
]

;-------------------------------------------
;-- Obtain a free node from a node frame
;-------------------------------------------
alloc-node: func [
	return: [int-ptr!]						;-- return a free node pointer
	/local frame node
][
	frame: memory/n-active					;-- take node from active node frame
	node: as int-ptr! frame/top/value		;-- pop free node address from stack
	frame/top: frame/top - 1
	
	if frame/top = frame/bottom [
		; TBD: trigger a "light" GC pass from here and update memory/n-active
		frame: alloc-node-frame nodes-per-frame	;-- allocate a new frame
		memory/n-active: frame				;@@ to be removed once GC implemented
		node: as int-ptr! frame/top/value	;-- pop free node address from stack
		frame/top: frame/top - 1
	]
	node
]

;-------------------------------------------
;-- Release a used node
;-------------------------------------------
free-node: func [
	node [int-ptr!]							;-- node to release
	/local frame offset
][
	frame: memory/n-active
	offset: as-integer node - frame
	
	if all [
		positive? offset					;-- check if node address is part of active frame
		offset < node-frame-size
	][										;-- node is owned by active frame
		frame/top: frame/top + 1			;-- free node by pushing its address on stack
		frame/top/value: node
		
		assert frame/top < (frame/bottom + frame/nodes)	;-- top should not overflow
		exit
	]
											;@@ following code not be needed if freed only by the GC...
	frame: memory/n-head					;-- search for right frame from head of the list
	while [									; @@ could be optimized by searching backward/forward from active frame
		offset: as-integer node - frame
		not all [							;-- test if node address is part of that frame
			positive? offset
			offset < node-frame-size		; @@ check upper bound case
		]
	][
		frame: frame/next
		assert frame <> null				;-- should found the right one before the list end
	]
	frame/top: frame/top + 1				;-- free node by pushing its address on stack
	frame/top/value: node

	assert frame/top < (frame/bottom + frame/nodes)	;-- top should not overflow
]

;-------------------------------------------
;-- Allocate a series frame buffer
;-------------------------------------------
alloc-series-frame: func [
	return:	[series-frame!]					;-- newly initialized frame
	/local size frame
][
	size: memory/s-limit
	if size < size-of-2MB [
		memory/s-limit: size * 2
	]
	size: size + size? series-frame! 		;-- total required size for a series frame
	frame: as series-frame! allocate-virtual size no ;-- RW only
	
	either null? memory/s-head [
		memory/s-head: frame				;-- first item in the list
		memory/s-tail: frame
		frame/prev:  null
	][
		memory/s-tail/next: frame			;-- append new item at tail of the list
		frame/prev: memory/s-tail			;-- link back to previous tail
		memory/s-tail: frame				;-- now tail is the new item
	]
	
	frame/next: null
	frame/heap: frame + size? series-frame!
	frame/tail: frame + size - 1			;-- point to last byte in frame
	frame
]

;-------------------------------------------
;-- Release a series frame buffer
;-------------------------------------------
free-series-frame: func [
	frame [series-frame!]					;-- frame to release
][
	either null? frame/prev [				;-- if frame = head
		memory/s-head: frame/next			;-- head now points to next one
	][
		either null? frame/next [			;-- if frame = tail
			memory/s-tail: frame/prev		;-- tail is now at one position back
		][
			frame/prev/next: frame/next		;-- link preceding frame to next frame
			frame/next/prev: frame/prev		;-- link back next frame to preceding frame
		]
	]

	assert not all [						;-- ensure that list is not empty
		null? memory/s-head
		null? memory/s-tail
	]
	
	free-virtual as int-ptr! frame			;-- release the memory to the OS
]

;-------------------------------------------
;-- Compact a series frame by overwriting unused series
;-------------------------------------------
compact-series-frame: func [

][

]


;-------------------------------------------
;-- Allocate a series from the active series frame
;-------------------------------------------
alloc-series: func [
	size	[integer!]						;-- size in multiple of 16 bytes (cell! size)
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
	/local series node
][
	assert positive? size					;-- size is not zero or negative
	assert zero? (size and 0Fh)				;-- size is a multiple of 16
	
	frame: memory/s-active
	size: size + size? series-buffer!		;-- add series header size

	;-- size should not be greater than the frame capacity
	assert size < as-integer (frame/tail - ((as byte-ptr! frame) + size? series-frame!))

	series: frame/heap
	if (as byte-ptr! series + size) >= frame/tail [
		; TBD: trigger a GC pass from here and update memory/s-active
		frame: alloc-series-frame
		memory/s-active: frame				;@@ to be removed once GC implemented
		series: frame/heap
	]
	
	assert size < size-of-16MB				;-- max series size allowed in a series frame
	series/size: size or series-in-use		;-- mark series as used
	
	node: alloc-node						;-- get a new node
	series/referer: node					;-- link back series to node
	node/value: (as byte-ptr! series) + size? series-buffer! ;-- node points to first usable byte of series buffer
	node									;-- return the node pointer
]

;-------------------------------------------
;-- Release a series
;-------------------------------------------
free-series: func [
	frame	[series-frame!]
	node	[int-ptr!]
][

]

;-------------------------------------------
;-- Expand a series to a new size
;-------------------------------------------
expand-series: func [

][

]