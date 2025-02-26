Red/System [
	Title:   "Red memory allocator"
	Author:  "Nenad Rakocevic"
	File: 	 %allocator.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum collector-type! [
	COLLECTOR_DEFAULT
	COLLECTOR_RELEASE						;-- will release empty frames to OS
]

#define SERIES_BUFFER_PADDING	4

int-array!: alias struct! [ptr [int-ptr!]]

;-- cell header bits layout --
;	31:		lock							;-- lock series for active thread access only
;	30:		new-line						;-- new-line (LF) marker (before the slot)
;	29-25:	arity							;-- arity for routine! functions.
;	24:		self?							;-- self-aware context flag
;	23-16:	op! sub-type					;-- op's underlying function type (op! only)
;	22-19:	tuple-size						;-- size of tuple (tuple! only)
;	21-20:	fetch mode						;-- fetching mode for an argument (typeset! only)
;	18:		series-owned					;-- mark a series owned by an object
;	17:		owner							;-- indicate that an object is an owner
;	16:		<reserved>
;	15:		extern flag						;-- routine code is external to Red (from FFI)
;	14:		sign bit						;-- sign of money
;	13:		dirty?							;-- word flag indicating if value has been modified
;	12-11:	context type					;-- context-type! value (context! cells only)
;	10:		trace							;-- force tracing mode attribut flag (function! cells only)
;	9:		no-trace						;-- disable tracing mode attribut flag (function! cells only)
;	8:		<reserved>
;	7-0:	datatype ID						;-- datatype number

cell!: alias struct! [
	header	[integer!]						;-- cell's header flags
	data1	[integer!]						;-- placeholders to make a 128-bit cell
	data2	[integer!]
	data3	[integer!]
]

;-- series flags --
;	31: 	used 							;-- 1 = used, 0 = free
;	30: 	type 							;-- always 0 for series-buffer!
;	29-28: 	insert-opt						;-- optimized insertions: 2 = head, 1 = tail, 0 = both
;   27:		mark							;-- mark as referenced for the GC (mark phase)
;   26:		lock							;-- lock series for active thread access only
;   25:		immutable						;-- mark as read-only
;   24:		big								;-- indicates a big series (big-frame!)
;	23:		small							;-- reserved
;	22:		stack							;-- series buffer is allocated on stack
;   21:		permanent						;-- protected from GC (system-critical series)
;   20:     fixed							;-- series cannot be relocated (system-critical series)
;	19:		complement						;-- complement flag for bitsets
;	18:		UTF-16 cache					;-- signifies that the string cache is UTF-16 encoded (UTF-8 by default)
;	17:		owned							;-- series is owned by an object
;	16-5: 	<reserved>
;	4-0:	unit							;-- size in bytes of atomic element stored in buffer
											;-- 0: UTF-8, 1: Latin1/binary, 2: UCS-2, 4: UCS-4, 16: block! cell
series-buffer!: alias struct! [
	flags	[integer!]						;-- series flags
	node	[int-ptr!]						;-- point back to referring node
	size	[integer!]						;-- usable buffer size (series-buffer! struct excluded)
	offset	[cell!]							;-- series buffer offset pointer (insert at head optimization)
	tail	[cell!]							;-- series buffer tail pointer 
]

series-frame!: alias struct! [				;-- series frame header
	next	[series-frame!]					;-- next frame or null
	prev	[series-frame!]					;-- previous frame or null
	size	[integer!]						;-- frame size (in bytes)
	heap	[series-buffer!]				;-- point to allocatable region
	tail	[byte-ptr!]						;-- point to last byte in allocatable region
]

node-frame!: alias struct! [				;-- node frame header
	next	[node-frame!]					;-- next frame or null
	prev	[node-frame!]					;-- previous frame or null
	nodes	[integer!]						;-- number of nodes
	head	[node!]							;-- entry node for the free list (can be null if full)
	used	[integer!]						;-- number of used nodes in the list
	birth	[integer!]						;-- GC cycle runs when that node frame has been allocated
	p-used	[integer!]						;-- used nodes at last GC cycle
	a-used	[integer!]						;-- bit array of previously used states (1: unchanged/cycle, 0: changed)
	locked? [logic!]						;-- frame is locked from new node allocations (scheduled to be freed)
]

big-frame!: alias struct! [					;-- big frame header (for >= 2MB series)
	next	[big-frame!]					;-- next frame or null
	prev	[big-frame!]					;-- always null (single linked-list)
	size	[integer!]						;-- size (up to 4GB - size? header)
]

memory: declare struct! [					; TBD: instanciate this structure per OS thread
	total	 [integer!]						;-- total memory size allocated (in bytes)
	n-head	 [node-frame!]					;-- head of node frames list
	n-tail	 [node-frame!]					;-- tail of node frames list
	n-active [node-frame!]					;-- currently used node frame
	s-head	 [series-frame!]				;-- head of series frames list
	s-active [series-frame!]				;-- actively used series frame
	s-tail	 [series-frame!]				;-- tail of series frames list
	s-start	 [integer!]						;-- start size for new series frame		(1)
	s-size	 [integer!]						;-- current size for new series frame	(1)
	s-max	 [integer!]						;-- max size for new series frames		(1)
	b-head	 [big-frame!]					;-- head of big frames list
	stk-refs [int-ptr!]						;-- buffer to stack references to update during GC
	stk-tail [int-ptr!]						;-- tail pointer on stack references buffer
	stk-sz	 [integer!]						;-- size of stack references buffer in 64-bits slots
]

bitarrays-base: declare int-ptr!			;-- points to bit-arrays table
lib-bitarrays-base: declare int-ptr! 		;-- points to bit-arrays table (libRedRT image)


init-mem: func [/local p [int-ptr!]][
	memory/total:	 0
	memory/s-start:	 _1MB
	memory/s-max:	 _2MB
	memory/s-size:	 memory/s-start
	memory/stk-sz:	 1000
	memory/b-head:	 null
	memory/stk-refs: as int-ptr! allocate memory/stk-sz * 2 * size? int-ptr!
	
	collector/nodes-list/init
	
	p: as int-ptr! system/image/base + system/image/bitarray
	if p/0 = 1 [p: as int-ptr! crush/decompress as byte-ptr! p null]
	bitarrays-base: p

	#if libRedRT? = yes [
		p: as int-ptr! system/lib-image/base + system/lib-image/bitarray
		if p/0 = 1 [p: as int-ptr! crush/decompress as byte-ptr! p null]
		lib-bitarrays-base: p
	]
]

;; (1) Series frames size will grow from 1MB up to 2MB (arbitrary selected). This
;; range will need fine-tuning with real Red apps. This growing size, with low starting value
;; will allow small apps to not consume much memory while avoiding to penalize big apps.


;-------------------------------------------
;-- Fill a memory region with a given byte
;-------------------------------------------
fill: func [
	p	  [byte-ptr!]
	end   [byte-ptr!]
	byte  [byte!]
][
	set-memory p byte as-integer end - p
]

;-------------------------------------------
;-- Clear a memory region which size is a multiple of cell size
;-------------------------------------------
zerofill: func [
	p		[int-ptr!]
	end		[int-ptr!]
][
	assert p < end
	until [
		p/value: 0
		p: p + 1
		p = end
	]
]

;-------------------------------------------
;-- Allocate paged virtual memory region
;-------------------------------------------
allocate-virtual: func [
	size 	[integer!]						;-- allocated size in bytes (page size multiple)
	exec? 	[logic!]						;-- TRUE => executable region
	return: [int-ptr!]						;-- allocated memory region pointer
	/local 
		ptr [int-ptr!]
][
	size: round-to size + 4	platform/page-size	;-- account for header (one word)
	memory/total: memory/total + size
	catch OS_ERROR_VMEM_ALL [
		ptr: platform/allocate-virtual size exec?
	]
	if system/thrown > OS_ERROR_VMEM [
		system/thrown: 0
		fire [TO_ERROR(internal no-memory)]
	]
	ptr/value: size							;-- store size in header
	ptr + 1									;-- return pointer after header
]

;-------------------------------------------
;-- Free paged virtual memory region from OS
;-------------------------------------------
free-virtual: func [
	ptr [int-ptr!]							;-- address of memory region to release
][
	ptr: ptr - 1							;-- return back to header
	memory/total: memory/total - ptr/value
	catch OS_ERROR_VMEM_ALL [
		platform/free-virtual ptr
	]
	if system/thrown > OS_ERROR_VMEM [
		system/thrown: 0
		fire [TO_ERROR(internal wrong-mem)]
	]
]

;-------------------------------------------
;-- Free all frames (part of Red's global exit handler)
;-------------------------------------------
free-all: func [
	/local n-frame s-frame b-frame n-next s-next b-next
][
	n-frame: memory/n-head
	while [n-frame <> null][
		n-next: n-frame/next
		free-virtual as int-ptr! n-frame
		n-frame: n-next
	]
	
	s-frame: memory/s-head
	while [s-frame <> null][
		s-next: s-frame/next
		free-virtual as int-ptr! s-frame
		s-frame: s-next
	]

	b-frame: memory/b-head
	while [b-frame <> null][
		b-next: b-frame/next
		free-virtual as int-ptr! b-frame
		b-frame: b-next
	]
]

;-------------------------------------------
;-- Format the node frame stack by filling it with pointers to all nodes
;-------------------------------------------
format-nodes: func [
	frame [node-frame!]						;-- node frame to format
	/local
		head tail node [node!]
][
	head: as node! frame + 1
	tail: (head + frame/nodes) - 1			;-- exclude last slot from the loop
	frame/head: head
	node: head
	while [node < tail][
		node/value: as-integer node + 1
		node: node + 1
	]
	node/value: 0 							;-- set last node to null to mark the list end
]

;-------------------------------------------
;-- Allocate a node frame buffer and initialize it
;-------------------------------------------
alloc-node-frame: func [
	size 	[integer!]						;-- nb of nodes
	return:	[node-frame!]					;-- newly initialized frame
	/local
		frame [node-frame!]
		 sz	  [integer!]
][
	assert positive? size
	sz: size * (size? node!) + (size? node-frame!) ;-- total required size for a node frame
	frame: as node-frame! allocate-virtual sz no ;-- R/W only

	frame/prev:   null
	frame/next:   null
	frame/nodes:  size
	frame/used:   0
	frame/birth:  collector/stats/cycles
	frame/p-used: 0
	frame/a-used: 0
	frame/locked?: no

	either null? memory/n-head [
		memory/n-head: frame				;-- first item in the list
		memory/n-tail: frame
		memory/n-active: frame
	][
		memory/n-tail/next: frame			;-- append new item at tail of the list
		frame/prev: memory/n-tail			;-- link back to previous tail
		memory/n-tail: frame				;-- now tail is the new item
	]
	
	format-nodes frame						;-- prepare the node frame for use
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
			frame/prev/next: null
		][
			frame/prev/next: frame/next		;-- link preceding frame to next frame
			frame/next/prev: frame/prev		;-- link back next frame to preceding frame
		]
	]
	if memory/n-active = frame [
		memory/n-active: memory/n-tail		;-- reset active frame to last one @@
		assert not memory/n-tail/locked?
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
	return: [node!]							;-- return a free node pointer
	/local
		frame [node-frame!]
		node  [node!]
][
	frame: memory/n-active					;-- take node from active node frame
	if null? frame/head [
		frame: memory/n-head
		while [all [frame <> null any [frame/head = null frame/locked?]]][frame: frame/next]
		if null? frame [frame: alloc-node-frame nodes-per-frame]
		memory/n-active: frame
	]
	assert not frame/locked?
	node: frame/head
	frame/head: as node! node/value
	node/value: 0
	frame/used: frame/used + 1
	node
]

;-------------------------------------------
;-- Release a used node
;-------------------------------------------
free-node: func [
	frame [node-frame!]
	node  [int-ptr!]						;-- node to release
][
	assert node <> null
	node/value: as-integer frame/head
	frame/head: node
	frame/used: frame/used - 1
]

;-------------------------------------------
;-- Free empty node frames
;-------------------------------------------
collect-node-frames: func [
	/local
		frame next [node-frame!]
		unset? [logic!]
][
	unset?: yes
	frame: memory/n-head
	while [frame <> null][
		next: frame/next
		either any [zero? frame/used frame/locked?][
			free-node-frame frame
		][
			if all [unset? frame/used < frame/nodes][
				memory/n-active: frame
				unset?: no
			]
			frame/a-used: frame/a-used << 1 
			frame/a-used: frame/a-used or as-integer frame/p-used = frame/used
			frame/p-used: frame/used		;-- save used nodes (stats purposes)
		]
		frame: next
	]
]

;-------------------------------------------
;-- Allocate a series frame buffer
;-------------------------------------------
alloc-series-frame: func [
	return:	[series-frame!]					;-- newly initialized frame
	/local 
		frame frm [series-frame!]
		size [integer!]
][
	size: memory/s-size
	if size < memory/s-max [memory/s-size: size * 2]
	
	size: size + size? series-frame! 		;-- total required size for a series frame
	frame: as series-frame! allocate-virtual size no ;-- RW only
	frame/heap: as series-buffer! (as byte-ptr! frame) + size? series-frame!
	frame/tail: (as byte-ptr! frame) + size	;-- point to last byte in frame
	frame/size: size
	frame/next: null
	frame/prev: null
	
	frm: memory/s-head
	case [
		null? memory/s-head [
			memory/s-head: frame			;-- first item in the list
			memory/s-tail: frame
			memory/s-active: frame
			frame/prev:  null
		]
		frame < frm [
			frame/next: frm
			frm/prev: frame
			memory/s-head: frame
		]
		true [
			while [all [frm/next <> null frm < frame]][frm: frm/next]
			either all [frm/next = null frm < frame][
				frm/next: frame				;-- append new item at tail of the list
				frame/prev: frm				;-- link back to previous tail
				memory/s-tail: frame		;-- now tail is the new item
			][
				frame/prev: frm/prev		;-- insert frame in the linked list
				frame/next: frm
				frm/prev/next: frame
				frm/prev: frame
			]
		]
	]
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
			frame/prev/next: null
		][
			frame/prev/next: frame/next		;-- link preceding frame to next frame
			frame/next/prev: frame/prev		;-- link back next frame to preceding frame
		]
	]
	if memory/s-active = frame [
		memory/s-active: memory/s-tail		;-- reset active frame to last one @@
	]

	assert not all [						;-- ensure that list is not empty
		null? memory/s-head
		null? memory/s-tail
	]
	
	free-virtual as int-ptr! frame			;-- release the memory to the OS
]

#if debug? = yes [

	markfill: func [
		p		[int-ptr!]
		end		[int-ptr!]
	][
		assert p < end
		until [
			p/value: BADCAFE0h
			p: p + 1
			p = end
		]
	]

	dump-frame: func [
		frame [series-frame!]				;-- series frame to compact
		/local
			s	  [series!]
			heap  [series!]
	][
		s: as series! frame + 1				;-- point to first series buffer
		heap: frame/heap

		until [
			either s/flags and flag-gc-mark = 0 [prin "x "][prin "o "]
			probe [s ": unit=" GET_UNIT(s) " size=" s/size]
			s: as series! (as byte-ptr! s + 1) + s/size + SERIES_BUFFER_PADDING
			s >= heap
		]

	]
	
	check-frames: func [
		/local
			frame [series-frame!]
	][
		frame: memory/s-head
		until [
			check-series frame
			frame: frame/next
			frame = null
		]
	]

	check-series: func [
		frame [series-frame!]				;-- series frame to compact
		/local
			s	  [series!]
			heap  [series!]
	][
		s: as series! frame + 1				;-- point to first series buffer
		heap: frame/heap

		while [heap > s][
			if any [
				(as byte-ptr! s/offset) <> as byte-ptr! s + 1
				(as byte-ptr! s/tail) < as byte-ptr! s
				(as byte-ptr! s/tail) > ((as byte-ptr! s/offset) + s/size)
			][
				probe "Corrupted series detected:"
				dump4 s
				halt
			]
			s: as series! (as byte-ptr! s + 1) + s/size + SERIES_BUFFER_PADDING
		]

	]
]

find-space: func [
	size	[integer!]
	return: [series-frame!]
	/local
		frame [series-frame!]
][
	frame: memory/s-head
	while [all [frame <> null ((as byte-ptr! frame/heap) + size) >= frame/tail]][
		frame: frame/next
	]
	frame
]

;-------------------------------------------
;-- Allocate a series from the active series frame, return the series
;-------------------------------------------
alloc-series-buffer: func [
	usize	[integer!]						;-- size in units
	unit	[integer!]						;-- size of atomic elements stored
	offset	[integer!]						;-- force a given offset for series buffer (in bytes)
	return: [series-buffer!]				;-- return the new series buffer
	/local 
		series	 [series-buffer!]
		frame	 [series-frame!]
		size	 [integer!]
		sz		 [integer!]
		flag-big [integer!]
][
	assert positive? usize
	size: round-to usize * unit size? cell!	;-- size aligned to cell! size

	frame: memory/s-active
	;-- add series header size + (extra padding 4 bytes)
	;-- extra space between two adjacent series-buffer!s (ensure s1/tail <> s2)
	sz: SERIES_BUFFER_PADDING + size + size? series-buffer!
	flag-big: 0
	series: null
	either (as byte-ptr! sz) >= (as byte-ptr! memory/s-max) [ ;-- alloc a big frame if too big for series frames
		collector/do-cycle					;-- launch a GC pass
		series: as series-buffer! alloc-big sz
		flag-big: flag-series-big
	][
		if ((as byte-ptr! frame/heap) + sz) >= frame/tail [ ;-- search for a suitable frame
			frame: find-space sz
			if null? frame [
				collector/do-cycle			;-- launch a GC pass
				frame: find-space sz
				if any [
					null? frame
					(as-integer frame/tail - frame/heap) < 52428	;- 1MB * 5%
				][
					if sz >= memory/s-size [ ;@@ temporary checks
						memory/s-size: memory/s-max
					]
					frame: alloc-series-frame
				]
			]
			memory/s-active: frame
		]
		assert sz < memory/s-max			;-- max series size allowed in a series frame
		series: frame/heap
		frame/heap: as series-buffer! (as byte-ptr! frame/heap) + sz
	]
		
	series/size: size
	series/flags: unit or series-in-use or flag-big

	either offset = default-offset [
		offset: size >> 1					;-- target middle of buffer
		series/flags: series/flags or flag-ins-both	;-- optimize for both head & tail insertions (default)
	][
		series/flags: series/flags or flag-ins-tail ;-- optimize for tail insertions only
	]
	
	series/offset: as cell! (as byte-ptr! series + 1) + offset
	series/tail: series/offset
	series
]

;-------------------------------------------
;-- Allocate a node and a series from the active series frame, return the node
;-------------------------------------------
alloc-series: func [
	size	[integer!]						;-- number of elements to store
	unit	[integer!]						;-- size of atomic elements stored
	offset	[integer!]						;-- force a given offset for series buffer
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
	/local series [series!] node [int-ptr!]
][
;	#if debug? = yes [print-wide ["allocating series:" size unit offset lf]]
	series: null
	node: null
	series: alloc-series-buffer size unit offset
	node: alloc-node						;-- get a new node
	series/node: node						;-- link back series to node
	node/value: as-integer series ;(as byte-ptr! series) + size? series-buffer!
	node									;-- return the node pointer
]

;-------------------------------------------
;-- Allocate a series using malloc, return the node
;-------------------------------------------
alloc-fixed-series: func [
	usize	[integer!]						;-- number of elements to store
	unit	[integer!]						;-- size of atomic elements stored
	offset	[integer!]						;-- force a given offset for series buffer
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
	/local
		series	 [series-buffer!]
		size	 [integer!]
		sz		 [integer!]
		node	 [int-ptr!]
][
;	#if debug? = yes [print-wide ["allocating series:" size unit offset lf]]
	assert positive? usize
	size: round-to usize * unit size? cell!	;-- size aligned to cell! size
	sz: size + size? series-buffer!			;-- add series header size

	series: as series-buffer! allocate sz
	series/size: size
	series/flags: unit or series-in-use or flag-series-fixed or flag-ins-tail
	series/offset: as cell! (as byte-ptr! series + 1) + offset
	series/tail: series/offset

	node: alloc-node						;-- get a new node
	series/node: node						;-- link back series to node
	node/value: as-integer series
	node									;-- return the node pointer
]

;-------------------------------------------
;-- Wrapper on alloc-series for easy cells allocation
;-------------------------------------------
alloc-cells: func [
	size	[integer!]						;-- number of 16 bytes cells to preallocate
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)	
][
	alloc-series size 16 0					;-- optimize by default for tail insertion
]

;-------------------------------------------
;-- Wrapper on alloc-cells for easy unset cells allocation
;-------------------------------------------
alloc-unset-cells: func [
	size	[integer!]						;-- number of 16 bytes cells to preallocate
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
	/local
		node [node!]
		s	 [series!]
		p	 [int-ptr!]
		end	 [int-ptr!]
][
	node: alloc-series size 16 0
	s: as series! node/value
	p: as int-ptr! s/offset
	end: as int-ptr! ((as byte-ptr! s/offset) + s/size)
	
	assert p < end
	assert (as-integer end) and 3 = 0		;-- end should be a multiple of 4
	until [
		p/value: TYPE_UNSET
		p/2: 0
		p/3: 0
		p/4: 0
		p: p + 4
		p = end
	]
	node
]

;-------------------------------------------
;-- Wrapper on alloc-series for byte buffer allocation
;-------------------------------------------
alloc-bytes: func [
	size	[integer!]						;-- number of 16 bytes cells to preallocate
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
][
	if zero? size [size: 16]
	alloc-series size 1 0					;-- optimize by default for tail insertion
]

;-------------------------------------------
;-- Wrapper on alloc-series for codepoints buffer allocation
;-------------------------------------------
alloc-codepoints: func [
	size	[integer!]						;-- number of codepoints slots to preallocate
	unit	[integer!]
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
][
	assert unit <= 4
	if zero? size [size: 16 >> (unit >> 1)]
	alloc-series size unit 0				;-- optimize by default for tail insertion
]

;-------------------------------------------
;-- Wrapper on alloc-series for byte-filled buffer allocation
;-------------------------------------------
alloc-bytes-filled: func [
	size	[integer!]						;-- number of 16 bytes cells to preallocate
	byte	[byte!]
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
	/local
		node [node!]
		s	 [series!]
][
	node: alloc-bytes size
	s: as series! node/value
	fill 
		as byte-ptr! s/offset
		(as byte-ptr! s/offset) + s/size
		byte
	node
]

;-------------------------------------------
;-- Set series header flags
;-------------------------------------------
set-flag: func [
	node	[node!]
	flags	[integer!]
	/local series
][
	series: as series-buffer! node/value
	series/flags: series/flags or flags	;-- apply flags
]

;-------------------------------------------
;-- Expand a series to a new size
;-------------------------------------------
expand-series: func [
	series  [series-buffer!]				;-- series to expand
	new-sz	[integer!]						;-- new size in bytes
	return: [series-buffer!]				;-- return new series with new size
	/local
		new	  [series-buffer!]
		node  [node!]
		units [integer!]
		delta [integer!]
		big?  [logic!]
][
	;#if debug? = yes [print-wide ["series expansion triggered for:" series new-sz lf]]
	
	assert not null? series
	assert any [
		zero? new-sz
		new-sz > series/size				;-- ensure requested size is bigger than current one
	]
	units: GET_UNIT(series)
	
	if zero? new-sz [new-sz: series/size * 2] ;-- by default, alloc twice the old size

	if new-sz <= 0 [fire [TO_ERROR(internal no-memory)]]

	node: series/node
	new: null								;-- avoids GC processing this slot on stack (optimization)
	new: alloc-series-buffer new-sz / units units 0
	series: as series-buffer! node/value	;-- refresh series after eventual GC pass
	big?: new/flags and flag-series-big <> 0
	
	node/value: as-integer new				;-- link node to new series buffer
	delta: as-integer series/tail - series/offset
	
	new/flags:	series/flags
	new/node:	node
	new/tail:	as cell! (as byte-ptr! new/offset) + delta
	series/node: null						;-- needs to be set after potential GC pass from new allocation
	
	if big? [new/flags: new/flags or flag-series-big]	;@@ to be improved
	
	;TBD: honor flag-ins-head and flag-ins-tail when copying!	
	copy-memory 							;-- copy old series in new buffer
		as byte-ptr! new/offset
		as byte-ptr! series/offset
		series/size
	
	assert not zero? (series/flags and not series-in-use) ;-- ensure that 'used bit is set
	series/flags: series/flags xor series-in-use		  ;-- clear 'used bit (enough to free the series)	
	new	
]

;-------------------------------------------
;-- Expand a series to a new size and zero-fill extra space
;-------------------------------------------
expand-series-filled: func [
	s		[series-buffer!]				;-- series to expand
	new-sz	[integer!]						;-- new size in bytes
	byte	[byte!]							;-- byte to fill the extended region with
	return: [series-buffer!]
	/local
		old [integer!]
][
	old: s/size
	s: expand-series s new-sz
	fill (as byte-ptr! s/offset) + old (as byte-ptr! s/offset) + s/size byte
	s
]
;-------------------------------------------
;-- Shrink a series to a smaller size (not needed for now)
;-------------------------------------------
;shrink-series: func [
;	series  [series-buffer!]
;	return: [series-buffer!]
;][
;
;]

;-------------------------------------------
;-- Copy a series buffer
;-------------------------------------------
copy-series: func [
	s 		[series!]
	return: [node!]
	/local
		node   [node!]
		new	   [series!]
][
	node: alloc-bytes s/size
	
	new: as series! node/value
	new/flags: s/flags
	new/tail: as cell! (as byte-ptr! new/offset) + (as-integer s/tail - s/offset)
	
	unless zero? s/size [
		copy-memory 
			as byte-ptr! new/offset
			as byte-ptr! s/offset
			s/size
	]
	node
]

collect-big-frames: func [
	/local frame s
][
	frame: memory/b-head
	while [frame <> null][
		s: as series! (as byte-ptr! frame) + size? big-frame!
		frame: frame/next			;-- get next frame before free current frame
		either s/flags and flag-gc-mark = 0 [
			collector/nodes-list/store s/node
			free-big as byte-ptr! s
		][
			s/flags: s/flags and not flag-gc-mark	;-- clear mark flag
		]
	]
]

;-------------------------------------------
;-- Allocate a big series
;-------------------------------------------
alloc-big: func [
	size	[integer!]						;-- buffer size to allocate (in bytes)
	return: [byte-ptr!]						;-- return allocated buffer pointer
	/local 
		sz	  [integer!]
		frame [big-frame!]
		frm	  [big-frame!]
][
	assert positive? size
	assert size >= _2MB						;-- should be bigger than a series frame
	
	sz: size + size? big-frame! 			;-- total required size for a big frame
	frame: as big-frame! allocate-virtual sz no ;-- R/W only

	frame/next: null
	frame/prev: null
	frame/size: size
	
	either null? memory/b-head [
		memory/b-head: frame				;-- first item in the list
	][
		frm: memory/b-head					;-- search for tail of list (@@ might want to save it?)
		while [frm/next <> null][frm: frm/next]
		assert not null? frm		
		
		frm/next: frame						;-- append new item at tail of the list
	]
	
	(as byte-ptr! frame) + size? big-frame!	;-- return a pointer to the requested buffer
]

;-------------------------------------------
;-- Release a big series 
;-------------------------------------------
free-big: func [
	buffer	[byte-ptr!]						;-- big buffer to release
	/local frame frm
][
	assert not null? buffer
	
	frame: as big-frame! (buffer - size? big-frame!)  ;-- point to frame header
	
	either frame = memory/b-head [
		memory/b-head: frame/next
	][
		frm: memory/b-head					;-- search for frame position in list
		while [frm/next <> frame][			;-- frm should point to one item behind frame on exit
			frm: frm/next
			assert not null? frm			;-- ensure tail of list is not passed
		]
		frm/next: frame/next				;-- remove frame from list
	]
	
	free-virtual as int-ptr! frame			;-- release the memory to the OS
]

#if libRed? = yes [

	;-- Intermediary buffer used for holding Red values passed as arguments to an external
	;-- routine.
	
	ext-ring: context [
		head: as cell! 0
		tail: as cell! 0
		pos:  as cell! 0
		size: 50
		
		store: func [
			value	[cell!]
			return: [cell!]
		][
			copy-cell value alloc
		]
		
		alloc: func [return: [cell!]][
			pos: pos + 1
			if pos = tail [pos: head]
			pos
		]
		
		init: does [
			head: as cell! allocate size * size? cell!
			tail: head + size
			pos:  head
		]
		
		destroy: does [free as byte-ptr! head]
	]
	
]
