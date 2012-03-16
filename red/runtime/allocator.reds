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

#define _128KB				131072			; @@ create a dedicated datatype?
#define _2MB				2097152
#define _16MB				16777216
#define nodes-per-frame		5000
#define node-frame-size		[((nodes-per-frame * 2 * size? pointer!) + size? node-frame!)]

#define series-in-use		80000000h		;-- mark a series as used (not collectable by the GC)
#define flag-series-big		40000000h		;-- 1 = big, 0 = series
#define flag-ins-head		10000000h		;-- optimize for head insertions
#define flag-ins-tail		20000000h		;-- optimize for tail insertions
#define flag-ins-both		30000000h		;-- optimize for both head & tail insertions
#define s-size-mask			00FFFFFFh		;-- mask for 24-bit size field
	
int-array!: alias struct! [ptr [int-ptr!]]

;-- cell header bits layout --
;   31:		lock							;-- lock series for active thread access only
;   30:		new-line						;-- new-line (LF) marker (before the slot)
;   29-8:	<reserved>
;   7-0:	datatype ID						;-- datatype number

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
;	20-3: 	<reserved>
;	4-0:	units							;-- size in bytes of atomic element stored in buffer
											;-- 0: UTF-8, 1: binary! byte, 2: UTF-16, 4: UTF-32, 16: block! cell
series-buffer!: alias struct! [
	flags	[integer!]						;-- series flags
	size	[integer!]						;-- size of allocated buffer
	node	[int-ptr!]						;-- point back to referring node
	head	[integer!]						;-- series buffer head index
	tail	[integer!]						;-- series buffer tail index 
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

big-frame!: alias struct! [					;-- big frame header (for >= 2MB series)
	flags	[integer!]						;-- bit 30: 1 (type = big)
	next	[big-frame!]					;-- next frame or null
	size	[integer!]						;-- size (up to 4GB - size? header)
	padding [integer!]						;-- make this header same size as series-buffer! header
]

memory: declare struct! [					; TBD: instanciate this structure per OS thread
	total	 [integer!]						;-- total memory size allocated (in bytes)
	n-head	 [node-frame!]					;-- head of node frames list
	n-active [node-frame!]					;-- actively used node frame
	n-tail	 [node-frame!]					;-- tail of node frames list
	s-head	 [series-frame!]				;-- head of series frames list
	s-active [series-frame!]				;-- actively used series frame
	s-tail	 [series-frame!]				;-- tail of series frames list
	s-start	 [integer!]						;-- start size for new series frame		(1)
	s-size	 [integer!]						;-- current size for new series frame	(1)
	s-max	 [integer!]						;-- max size for new series frames		(1)
	b-head	 [big-frame!]					;-- head of big frames list
]

memory/total: 	0
memory/s-start: _128KB
memory/s-max: 	_2MB
memory/s-size: 	memory/s-start
;; (1) Series frames size will grow from 128KB up to 2MB (arbitrary selected). This
;; range will need fine-tuning with real Red apps. This growing size, with low starting value
;; will allow small apps to not consume much memory while avoiding to penalize big apps.


;-------------------------------------------
;-- Allocate paged virtual memory region
;-------------------------------------------
allocate-virtual: func [
	size 	[integer!]						;-- allocated size in bytes (page size multiple)
	exec? 	[logic!]						;-- TRUE => executable region
	return: [int-ptr!]						;-- allocated memory region pointer
	/local ptr
][
	size: round-to size + 4	OS-page-size	;-- account for header (one word)
	memory/total: memory/total + size
	ptr: OS-allocate-virtual size exec?
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
	OS-free-virtual ptr
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
format-node-stack: func [
	frame [node-frame!]						;-- node frame to format
	/local node ptr
][
	ptr: frame/bottom						;-- point to bottom of stack
	node: ptr + frame/nodes					;-- first free node address
	until [
		ptr/value: as-integer node			;-- store free node address on stack
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
	frame: as node-frame! allocate-virtual sz no ;-- R/W only

	frame/prev:  null
	frame/next:  null
	frame/nodes: size

	frame/bottom: as int-ptr! (as byte-ptr! frame) + size? node-frame!
	frame/top: frame/bottom + size - 1		;-- point to the top element
	
	either null? memory/n-head [
		memory/n-head: frame				;-- first item in the list
		memory/n-tail: frame
		memory/n-active: frame
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
	if memory/n-active = frame [
		memory/n-active: memory/n-tail		;-- reset active frame to last one @@
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
	assert not null? node
	
	frame: memory/n-active
	offset: as-integer node - frame
	
	unless all [
		positive? offset					;-- check if node address is part of active frame
		offset < node-frame-size
	][										;@@ following code not be needed if freed only by the GC...								
		frame: memory/n-head				;-- search for right frame from head of the list
		while [								; @@ could be optimized by searching backward/forward from active frame
			offset: as-integer node - frame
			not all [						;-- test if node address is part of that frame
				positive? offset
				offset < node-frame-size	; @@ check upper bound case
			]
		][
			frame: frame/next
			assert frame <> null			;-- should found the right one before the list end
		]
	]
	
	frame/top: frame/top + 1				;-- free node by pushing its address on stack
	frame/top/value: as-integer node

	assert frame/top < (frame/bottom + frame/nodes)	;-- top should not overflow
]

;-------------------------------------------
;-- Allocate a series frame buffer
;-------------------------------------------
alloc-series-frame: func [
	return:	[series-frame!]					;-- newly initialized frame
	/local size frame
][
	size: memory/s-size
	if size < memory/s-max [memory/s-size: size * 2]
	
	size: size + size? series-frame! 		;-- total required size for a series frame
	frame: as series-frame! allocate-virtual size no ;-- R/W only
	
	either null? memory/s-head [
		memory/s-head: frame				;-- first item in the list
		memory/s-tail: frame
		memory/s-active: frame
		frame/prev:  null
	][
		memory/s-tail/next: frame			;-- append new item at tail of the list
		frame/prev: memory/s-tail			;-- link back to previous tail
		memory/s-tail: frame				;-- now tail is the new item
	]
	
	frame/next: null
	frame/heap: as series-buffer! (as byte-ptr! frame) + size? series-frame!
	frame/tail: (as byte-ptr! frame) + size	;-- point to last byte in frame
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
	if memory/s-active = frame [
		memory/s-active: memory/s-tail		;-- reset active frame to last one @@
	]

	assert not all [						;-- ensure that list is not empty
		null? memory/s-head
		null? memory/s-tail
	]
	
	free-virtual as int-ptr! frame			;-- release the memory to the OS
]

;-------------------------------------------
;-- Update node back-reference from moved series buffers
;-------------------------------------------
update-series-nodes: func [
	series	[series-buffer!]				;-- start of series region with nodes to re-sync
][
	until [
		;-- update the node pointer to the new series address
		series/node/value: as-integer (as byte-ptr! series) + size? series-buffer!
		
		;-- advance to the next series buffer
		series: as series-buffer! (as byte-ptr! series) + series/size
		
		;-- exit when a freed series is met (<=> end of region)
		zero? (series/flags and series-in-use)
	]
]

;-------------------------------------------
;-- Compact a series frame by moving down in-use series buffer regions
;-------------------------------------------
#define SM1_INIT		1					;-- enter the state machine
#define SM1_HOLE		2					;-- begin of contiguous region of freed buffers (hole)
#define SM1_HOLE_END	3					;-- end of freed buffers region 
#define SM1_USED		4					;-- begin of contiguous region of buffers in use
#define SM1_USED_END	5					;-- end of used buffers region 

compact-series-frame: func [
	frame [series-frame!]					;-- series frame to compact
	/local heap series state
		free? [logic!] src [byte-ptr!] dst [byte-ptr!]
][
	series: as series-buffer! (as byte-ptr! frame) + size? series-frame! ;-- point to first series buffer
	free?: zero? (series/flags and series-in-use)  ;-- true: series is not used
	heap: frame/heap
		
	src: null								;-- src will point to start of buffer region to move down
	dst: null								;-- dst will point to start of free region
	state: SM1_INIT

	until [
		if all [state = SM1_INIT free?][
			dst: as byte-ptr! series		 ;-- start of "hole" region
			state: SM1_HOLE
		]
		if all [state = SM1_HOLE not free?][ ;-- search for first used series (<=> end of hole)
			state: SM1_HOLE_END
		]
		if state = SM1_HOLE_END [
			src: as byte-ptr! series		 ;-- start of new "alive" region
			state: SM1_USED
		]
	 	;-- point to next series buffer
		series: as series-buffer! (as byte-ptr! series) + series/size
		free?: zero? (series/flags and series-in-use)  ;-- true: series is not used

		if all [state = SM1_USED any [free? series >= heap]][	;-- handle both normal and "exit" states
			state: SM1_USED_END
		]
		if state = SM1_USED_END [
			assert dst < src				 ;-- regions are moved down in memory
			assert src < as byte-ptr! series ;-- src should point at least at series - series/size
			copy-memory dst	src as-integer series - src
			update-series-nodes as series-buffer! dst
			dst: dst + (as-integer series - src) ;-- points after moved region (ready for next move)
			state: SM1_HOLE
		]
		series >= heap						;-- exit state machine
	]
	
	unless null? dst [						;-- no compaction occurred, all series were in use
		frame/heap: as series-buffer! dst	;-- set new heap after last moved region
	]
]

;-------------------------------------------
;-- Allocate a series from the active series frame, return the series
;-------------------------------------------
alloc-series-buffer: func [
	size	[integer!]						;-- size in bytes
	return: [series-buffer!]				;-- return the new series buffer
	/local series frame sz
][
	assert positive? size					;-- size is not zero or negative
	size: round-to-next size size? cell!	;-- size is a multiple of cell! size
	
	frame: memory/s-active
	sz: size + size? series-buffer!			;-- add series header size

	;-- size should not be greater than the frame capacity
	assert sz < as-integer (frame/tail - ((as byte-ptr! frame) + size? series-frame!))

	series: frame/heap
	if ((as byte-ptr! series) + sz) >= frame/tail [
		; TBD: trigger a GC pass from here and update memory/s-active
		frame: alloc-series-frame
		memory/s-active: frame				;@@ to be removed once GC implemented
		series: frame/heap
	]
	
	assert sz < _16MB						;-- max series size allowed in a series frame @@
	
	frame/heap: as series-buffer! (as byte-ptr! frame/heap) + sz

	series/size: sz
	series/flags: series-in-use 			;-- mark series as in-use
		or flag-ins-both					;-- optimize for both head & tail insertions (default)
		and not flag-series-big				;-- set type bit to 0 (= series)
		
	series/head: size / 2					;-- position empty series at middle of buffer
	series/tail: series/head
	series
]

;-------------------------------------------
;-- Allocate a node and a series from the active series frame, return the node
;-------------------------------------------
alloc-series: func [
	size	[integer!]						;-- size in multiple of cell! size
	return: [int-ptr!]						;-- return a new node pointer (pointing to the newly allocated series buffer)
	/local series node
][
	series: alloc-series-buffer size
	node: alloc-node						;-- get a new node
	series/node: node						;-- link back series to node
	;-- make node points to first usable byte of series buffer
	node/value: as-integer (as byte-ptr! series) + size? series-buffer!
	node									;-- return the node pointer
]

;-------------------------------------------
;-- Release a series
;-------------------------------------------
free-series: func [
	frame	[series-frame!]					;-- frame containing the series (should be provided by the GC)
	node	[int-ptr!]						;-- series' node pointer
	/local series
][
	assert not null? frame
	assert not null? node
	
	series: as series-buffer! ((as byte-ptr! node/value) - size? series-buffer!) ;-- point back to series header
	
	assert not zero? (series/flags and not series-in-use) ;-- ensure that 'used bit is set
	series/flags: series/flags xor series-in-use 		  ;-- clear 'used bit (enough to free the series)
	
	if frame/heap = as series-buffer! (		;-- test if series is on top of heap
		(as byte-ptr! node/value) +  series/size
	) [
		frame/heap = series					;-- cheap collecting of last allocated series
	]
	
	free-node node
]

;-------------------------------------------
;-- Expand a series to a new size
;-------------------------------------------
expand-series: func [
	series  [series-buffer!]				;-- series to expand
	new-sz	[integer!]						;-- new size
	return: [series-buffer!]				;-- return new series with new size
	/local new
][
	assert not null? series
	assert new-sz > series/size 			;-- ensure requested size is bigger than current one
	
	new: alloc-series-buffer new-sz
	series/node/value: as-integer new		;-- link node to new series buffer
	
	;TBD: honor flag-ins-head and flag-ins-tail when copying!
	
	copy-memory 							;-- copy old series in new buffer (including header)
		as byte-ptr! new
		as byte-ptr! series
		series/size + size? series-buffer!
	
	assert not zero? (series/flags and not series-in-use) ;-- ensure that 'used bit is set
	series/flags: series/flags xor series-in-use		  ;-- clear 'used bit (enough to free the series)
	new	
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
;-- Allocate a big series
;-------------------------------------------
alloc-big: func [
	size [integer!]							;-- buffer size to allocate (in bytes)
	return: [byte-ptr!]						;-- return allocated buffer pointer
	/local sz frame frm
][
	assert positive? size
	assert size >= _2MB						;-- should be bigger than a series frame
	
	sz: size + size? big-frame! 			;-- total required size for a big frame
	frame: as big-frame! allocate-virtual sz no ;-- R/W only

	frame/next: null
	frame/size: size
	
	either null? memory/b-head [
		memory/b-head: frame				;-- first item in the list
	][
		frm: memory/b-head					;-- search for tail of list (@@ might want to save it?)
		until [frm: frm/next null? frm/next]
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
		memory/b-head: null
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


;===========================================
;== Debugging functions
;===========================================

#if debug? = yes [

	;-------------------------------------------
	;-- Print usage stats about a given frame
	;-------------------------------------------
	frame-stats: func [
		free	[integer!]
		used	[integer!]
		total	[integer!]
		/local percent
	][
		assert free + used = total
		percent: 100 * used / total
		if all [not zero? used zero? percent][percent: 1]

		print [
			"used = " used "/" total " ("  percent "%), "
			"free = " free "/" total " (" 100 - percent "%)" lf
		]
	]
	
		
	;-------------------------------------------
	;-- List series buffer allocated in a given series frame
	;-------------------------------------------
	list-series-buffers: func [
		frame	[series-frame!]
		/local series alt? size block count
	][
		count: 1
		series: as series-buffer! (as byte-ptr! frame) + size? series-frame!
		until [
			print [
				" - series #" count 
				": size = "	series/size - size? series-buffer!
				", offset pos = " series/head ", tail pos = " series/tail
				"    "
			]
			if series/flags and flag-ins-head <> 0 [print "H"]
			if series/flags and flag-ins-tail <> 0 [print "T"]
			print lf
			count: count + 1

			series: as series-buffer! (as byte-ptr! series) + series/size
			series >= frame/heap
		]
		assert series = frame/heap
	]
	
	;-------------------------------------------
	;-- Displays total frames count
	;-------------------------------------------
	print-frames-count: func [count [integer!] /local s][
		s: either count > 1 ["s^/"][newline]
		print ["^/    " count " frame" s lf]
	]

	;-------------------------------------------
	;-- Dump memory statistics on screen
	;-------------------------------------------
	memory-stats: func [
		verbose [integer!]						;-- stat verbosity level (1, 2 or 3)
		/local count n-frame s-frame b-frame free-nodes base
	][
		assert all [1 <= verbose verbose <= 3]
		
		print [lf "====== Red Memory Stats ======" lf]

	;-- Node frames stats --
		count: 0
		n-frame: memory/n-head
		
		print [lf "-- Node frames --" lf]
		while [n-frame <> null][
			if verbose >= 2 [
				print ["#" count + 1 ": "]
				free-nodes: (as-integer (n-frame/top - n-frame/bottom) + 1) / 4
				frame-stats 
					free-nodes
					n-frame/nodes - free-nodes
					n-frame/nodes
			]
			count: count + 1
			n-frame: n-frame/next
		]
		print-frames-count count
		
	;-- Series frames stats --
		count: 0
		s-frame: memory/s-head

		print ["-- Series frames --" lf]
		while [s-frame <> null][
			if verbose >= 2 [
				print ["#" count + 1 ": "]
				base: (as byte-ptr! s-frame) + size? series-frame!
				frame-stats
					as-integer s-frame/tail - as byte-ptr! s-frame/heap
					as-integer (as byte-ptr! s-frame/heap) - base
					as-integer s-frame/tail - base
				if verbose >= 3 [
					list-series-buffers s-frame
				]
			]
			count: count + 1
			s-frame: s-frame/next
		]
		print-frames-count count
		
	;-- Big frames stats --
		count: 0
		b-frame: memory/b-head

		print ["-- Big frames --" lf]
		while [b-frame <> null][
			if verbose >= 2 [
				print ["#" count + 1 ": "]
				prin-int b-frame/size
			]
			count: count + 1
			b-frame: b-frame/next
		]
		print-frames-count count
		
		print [
			"Total memory used: " memory/total " bytes" lf
			"==============================" lf
		]
	]
	
	;-------------------------------------------
	;-- Dump memory layout of a given series frame
	;-------------------------------------------
	dump-series-frame: func [
		frame	[series-frame!]
		/local series alt? size block
	][
		series: as series-buffer! (as byte-ptr! frame) + size? series-frame!
		
		print [lf "=== Series layout for frame: <" frame "h>" lf]
		
		alt?: no
		until [
			block: either zero? (series/flags and series-in-use) [
				"."
			][
				alt?: not alt?
				either alt? ["x"]["o"]
			]
			
			size: (series/size - size? series-buffer!) / 16
			until [
				print block
				size: size - 1
				zero? size
			]
			
			series: as series-buffer! (as byte-ptr! series) + series/size
			series >= frame/heap
		]
		assert series = frame/heap
		print lf
	]
	
]
