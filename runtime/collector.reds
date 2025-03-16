Red/System [
	Title:   "Red memory garbage collector"
	Author:  "Nenad Rakocevic"
	File: 	 %collector.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: "Implements the naive Mark&Sweep method."
]

collector: context [
	#define GC_DONE		0
	#define GC_RUNNING	1

	verbose: 0
	active?: no
	state: GC_DONE
	
	#enum frame-type! [
		FRAME_NODES
		FRAME_SERIES
	]

	prefs: declare struct! [
		nodes-gc-trigger 		[integer!]				;-- 0-31: node GC trigger age (in stats/cycles)
		;nodes-core-nb			[integer!]				;-- threshold below which no nodes compacting is done
	]
	
	stats: declare struct! [
		cycles [integer!]
	]
	
	ext-size: 100
	ext-markers: as int-ptr! allocate ext-size * size? int-ptr!
	ext-top: ext-markers
	
	refs: as int-ptr! 0
	refs-size: 20000

	
	indent: 0
	
	init: func [
		/local mask [integer!]
	][
		stats/cycles: 			0
		prefs/nodes-gc-trigger: 5						;-- trigger if node frame is unchanged after 5 cycles
	]

	compare-cb: func [[cdecl] a [int-ptr!] b [int-ptr!] return: [integer!]][
		SIGN_COMPARE_RESULT((as int-ptr! a/value) (as int-ptr! b/value))
	]
	
	frames-list: context [
		min-size:  1000
		fit-cache: 16									;-- nb of pointers fitting into a typical 64 bytes L1 cache

		list!: alias struct! [
			list  [int-ptr!] 							;-- array of frame pointers
			size  [integer!]							;-- size of list (in pointers)
			count [integer!]							;-- current number of stored frames
		]
		nodes:  declare list!
		series: declare list!
		nodes/size:  min-size
		series/size: min-size
		
		rebuild: func [									;-- build an array of node frames pointers
			/local
				frm	[node-frame!]
				pos [int-ptr!]
				s	[list!]
				cnt [integer!]
				process [subroutine!]
		][
			;-- allocation alignement not guaranteed, so L1 cache optmization is only eventual.
			if null? nodes/list  [nodes/list:  as node! allocate min-size * size? int-ptr!]
			if null? series/list [series/list: as node! allocate min-size * size? int-ptr!]
			
			process: [
				until [
					pos/value: as-integer frm
					pos: pos + 1
					cnt: cnt + 1
					if cnt >= s/size [
						s/size: s/size * 2
						s/list: as int-ptr! realloc as byte-ptr! s/list s/size * size? int-ptr!
						pos: s/list + cnt
					]
					frm: frm/next
					frm = null
				]
				if all [cnt > min-size cnt * 3 < s/size][	;-- shrink buffer if 2/3 or more are not used
					s/size: cnt
					s/list: as int-ptr! realloc as byte-ptr! s/list s/size * size? int-ptr!
				]
				qsort as byte-ptr! s/list cnt 4 :compare-cb	;-- sort the array
				s/count: cnt
			]
			
			s: nodes									;-- node frames
			frm: memory/n-head
			cnt: 0
			pos: s/list
			process
			
			s: series									;-- regular series frames
			frm: as node-frame! memory/s-head			
			cnt: 0
			pos: s/list
			process
			
			if memory/b-head <> null [					;-- big series
				frm: as node-frame! memory/b-head
				pos: s/list + cnt
				process
			]
		]
		
		find: func [
			ptr		[int-ptr!]
			type	[frame-type!]
			return: [logic!]
			/local
				sfrm		 [series-frame!]
				frm p b e	 [int-ptr!]
				tail		 [byte-ptr!]
				s			 [list!]
				w h			 [integer!]
				end? series? [logic!]
		][
			series?: type = FRAME_SERIES
			s: either series? [h: size? series-frame!  series][h: size? node-frame!  nodes]
			w: nodes-per-frame * size? node!			;-- fixed node frame width
			
			either s/count <= fit-cache [				;== linear search
				p: s/list
				either series? [
					loop s/count [
						sfrm: as series-frame! p/value
						tail: (as byte-ptr! sfrm) + sfrm/size
						if all [(as int-ptr! (as byte-ptr! sfrm) + h) <= ptr ptr < as int-ptr! tail][return yes]
						p: p + 1
					]
				][
					loop s/count [
						frm: as int-ptr! p/value + h
						if all [frm <= ptr ptr < as int-ptr! ((as byte-ptr! frm) + w)][return yes]
						p: p + 1
					]
				]
			][											;== binary search for arrays bigger than 16 nodes
				b: s/list								;-- low pointer
				e: s/list + (s/count - 1)				;-- high pointer
				either series? [
					until [
						p: b + ((as-integer e - b) >> 2 + 1 / 2) ;-- points to the middle of [b,e] segment
						sfrm: as series-frame! p/value
						tail: (as byte-ptr! sfrm) + sfrm/size
						if all [(as int-ptr! (as byte-ptr! sfrm) + h) <= ptr ptr < as int-ptr! tail][return yes]
						end?: b = e						;-- gives a chance to probe the b = e segment
						either (as int-ptr! p/value) < ptr [b: p][e: p - 1] ;-- chooses lower or upper segment
						end?
					]
				][
					until [
						p: b + ((as-integer e - b) >> 2 + 1 / 2) ;-- points to the middle of [b,e] segment
						frm: as int-ptr! p/value + h
						if all [frm <= ptr ptr < as int-ptr! ((as byte-ptr! frm) + w)][return yes]
						end?: b = e						;-- gives a chance to probe the b = e segment
						either (as node! p/value) < ptr [b: p][e: p - 1] ;-- chooses lower or upper segment
						end?
					]
				]
			]
			no
		]
	]
	
	nodes-list: context [								;-- nodes freeing batch handling
		list:	  as int-ptr! 0
		min-size: 20000
		buf-size: min-size								;-- initial number of supported nodes
		count:	  0										;-- current number of stored nodes
		
		init: does [list: as int-ptr! allocate buf-size * size? node!]
		
		store: func [node [node!]][
			if null? node [exit]						;-- expanded series sets null node in old series
			if count = buf-size [flush]					;-- buffer full, flush it first
			count: count + 1
			list/count: as-integer node
		]
		
		flush: func [									;-- assumes frames-list buffer is built and sorted
			/local
				frm p e n node new [int-ptr!]
				frm-nb w [integer!]
		][
			if zero? count [exit]
			qsort as byte-ptr! list count 4 :compare-cb
			p: frames-list/nodes/list
			e: p + frames-list/nodes/count
			w: nodes-per-frame * size? node!			;-- node frame width
			n: list
			
			loop count [
				node: as node! n/value
				while [
					frm: as int-ptr! ((as node-frame! p/value) + 1)
					not all [frm <= node  node < as node! ((as byte-ptr! frm) + w)]
				][
					p: p + 1
					assert p <= e						;-- parent frame should always be found
				]
				free-node as node-frame! p/value node
				n/value: 0								;-- not strictly needed, but cleaner that way.
				n: n + 1
			]
			count: 0									;-- resets the list to its head (clears the list content)
		]
	]
	
	calc-free-slots: func [
		return: [integer!]
		/local
			frame [node-frame!]
			cnt	  [integer!]
	][
		frame: memory/n-head
		cnt: 0
		until [
			if all [frame/head <> null not frame/locked?][cnt: cnt + nodes-per-frame - frame/used]
			frame: frame/next
			frame = null
		]
		cnt
	]

	compact-node: func [
		src		[node-frame!]
		refs	[int-ptr!]
		/local
			slot head tail new [node!]
			ptr [int-ptr!]
			frame dst  [node-frame!]
			s [series!]
			select-dst [subroutine!]
	][
		select-dst: [									;-- subroutine for finding a destination frame
			frame: memory/n-active
			if null? frame/head [
				while [any [frame = src frame/head = null frame/locked?]][frame: frame/next]
				memory/n-active: frame
			]
			assert frame <> null
			frame
		]
		
		dst: select-dst
		head: as node! src + 1							;-- skip frame header
		slot: head										;-- 1st node slot
		tail: slot + src/nodes

		loop src/nodes [								;-- loop over each node's value in frame
			ptr: as int-ptr! slot/value
			if all [ptr <> null any [ptr < head  tail < ptr]][	;-- move node's value to dst frame if node is not part of the internal free list
				if null? dst/head [dst: select-dst]		;-- if dst frame is full, find a new one
				new: dst/head							;-- alloc node slot in dst frame
				dst/head: as node! new/value			;-- set free list head to next free slot
				new/value: as-integer ptr				;-- transfer the node's value
				_hashtable/rs-put refs as-integer slot as-integer new	;-- store old (key), new (value) pair
				;print-line ["relocating node: " slot " from frame " src " to " dst " (new: " new ")"]
				s: as series! ptr
				s/node: new								;-- update back-reference
				src/used: src/used - 1					;-- not strictly needed, just for sake of internal consistency
				dst/used: dst/used + 1
			]
			slot: slot + 1
		]
		assert src/used = 0
		src/locked?: yes								;-- prevents new allocations, schedules for freeing at end of GC pass
	]
	
	do-node-cycle: func [
		/local
			frame [node-frame!]
			mask !mask avail [integer!]
	][
		assert nodes-list/count = 0
		!mask: 1 << (prefs/nodes-gc-trigger + 1) - 1	;-- create mask for checking frame usage across last 32 GC passes

		frame: memory/n-head
		while [all [frame <> null null? frame/head]][frame: frame/next]
		if null? frame [exit]							;-- all the frames are full
		memory/n-active: frame							;-- initialize dst

		avail: calc-free-slots							;-- nb of potential free destination slots (including the ones from frames to be compacted)
		frame: memory/n-tail
		until [
			;probe [frame ", used: " frame/used ", free: " frame/nodes - frame/used ", birth: " frame/birth ", a-used: " as int-ptr! frame/a-used]
			if all [
				frame/a-used and !mask = !mask			;-- node frame been unused for several GC passes (5 by default)
				frame/used < 5000						;-- only compact frames with < 50% usage
				avail > nodes-per-frame					;-- and only if enough destination slots left, simplified from: frame/used < (avail - (nodes-per-frame - frame/used))
				frame <> memory/n-active				;-- src <> dst
			][
				if refs = null [refs: _hashtable/rs-init refs-size]
				avail: avail - nodes-per-frame
				compact-node frame refs
			]
			frame: frame/prev
			frame = null
		]
	]
	
	keep: func [
		ptr		[int-ptr!]
		return: [logic!]								;-- TRUE if newly marked, FALSE if already done
		/local
			node new [node!]
			s	  [series!]
			new?  [logic!]
			flags [integer!]
	][
		if refs <> null [
			new: _hashtable/rs-get refs ptr/value
			if new <> null [
				;probe ["(keep) ptr: " ptr ", node: " as node! ptr/value ", new: " as node! new/value]
				ptr/value: new/value
			]
		]	
		node: as node! ptr/value
		s: as series! node/value
		flags: s/flags
		new?: flags and flag-gc-mark = 0
		if new? [s/flags: flags or flag-gc-mark]
		new?
	]

	unmark: func [
		node	 [node!]
		/local s [series!]
	][
		s: as series! node/value
		s/flags: s/flags and not flag-gc-mark
	]
	
	mark-context: func [
		ptr		[int-ptr!]
		/local
			node [node!]
			ctx  [red-context!]
			slot [red-value!]
	][
		if keep ptr [
			node: as node! ptr/value
			ctx: TO_CTX(node)							;-- [context! function!|object!]
			slot: as red-value! ctx
			_hashtable/mark :ctx/symbols
			unless ON_STACK?(ctx) [mark-block-node :ctx/values]
			mark-values slot + 1 slot + 2				;-- mark the back-reference value (2nd value)
		]
	]

	mark-values: func [
		value [red-value!]
		tail  [red-value!]
		/local
			series	[red-series!]
			obj		[red-object!]
			hash	[red-hash!]
			word	[red-word!]
			path	[red-path!]
			fun		[red-function!]
			routine [red-routine!]
			native	[red-native!]
			ctx		[red-context!]
			img		[red-image!]
			h		[red-handle!]
			len		[integer!]
			type	[integer!]
	][
		#if debug? = yes [if verbose > 1 [len: -1 indent: indent + 1]]
		
		while [value < tail][
			#if debug? = yes [if verbose > 1 [
				print "^/"
				loop indent * 4 [print "  "]
				print [TYPE_OF(value) ": "]
			]]
			
			switch TYPE_OF(value) [
				TYPE_WORD 
				TYPE_GET_WORD
				TYPE_SET_WORD 
				TYPE_LIT_WORD
				TYPE_REFINEMENT [
					word: as red-word! value
					if word/ctx <> null [
						#if debug? = yes [if verbose > 1 [print-symbol word]]
						either word/symbol = words/self [
							mark-block-node :word/ctx
						][
							mark-context :word/ctx
						]
					]
				]
				TYPE_BLOCK
				TYPE_PAREN
				TYPE_ANY_PATH [
					series: as red-series! value
					if series/node <> null [			;-- can happen in routine
						#if debug? = yes [if verbose > 1 [print ["len: " block/rs-length? as red-block! series]]]
						mark-block as red-block! value
					]
				]
				TYPE_SYMBOL [
					series: as red-series! value
					keep :series/extra
					if series/node <> null [keep :series/node]
				]
				TYPE_ANY_STRING [
					#if debug? = yes [if verbose > 1 [print as-c-string string/rs-head as red-string! value]]
					series: as red-series! value
					keep :series/node
					if series/extra <> 0 [keep :series/extra]
				]
				TYPE_BINARY
				TYPE_VECTOR
				TYPE_BITSET [
					series: as red-series! value
					keep :series/node
				]
				TYPE_ERROR
				TYPE_PORT
				TYPE_OBJECT [
					#if debug? = yes [if verbose > 1 [print "object"]]
					obj: as red-object! value
					mark-context :obj/ctx
					if obj/on-set <> null [keep :obj/on-set]
				]
				TYPE_CONTEXT [
					#if debug? = yes [if verbose > 1 [print "context"]]
					ctx: as red-context! value
					;keep :ctx/self
					_hashtable/mark :ctx/symbols
					unless ON_STACK?(ctx) [mark-block-node :ctx/values]
				]
				TYPE_HASH
				TYPE_MAP [
					#if debug? = yes [if verbose > 1 [print "hash/map"]]
					hash: as red-hash! value
					mark-block-node :hash/node
					_hashtable/mark :hash/table			;@@ check if previously marked
				]
				TYPE_FUNCTION
				TYPE_ROUTINE [
					#if debug? = yes [if verbose > 1 [print "function"]]
					fun: as red-function! value
					mark-context :fun/ctx
					mark-block-node :fun/spec
					mark-block-node :fun/more
				]
				TYPE_ACTION
				TYPE_NATIVE
				TYPE_OP [
					native: as red-native! value
					mark-block-node :native/spec
					mark-block-node :native/more
					if TYPE_OF(native) = TYPE_OP [
						type: GET_OP_SUBTYPE(native)
						if any [type = TYPE_FUNCTION type = TYPE_ROUTINE][
							mark-context :native/code
						]
					]
				]
				#if any [OS = 'macOS OS = 'Linux OS = 'Windows][
				TYPE_IMAGE [
					#if debug? = yes [if verbose > 1 [print "image"]]
					img: as red-image! value
					#if draw-engine <> 'GDI+ [
						if img/node <> null [
							keep :img/node
							image/mark img/node
						]
					]
				]]
				TYPE_HANDLE [
					#if debug? = yes [if verbose > 1 [print "handler"]]
					h: as red-handle! value
					if h/extID >= 0 [externals/mark h/extID]
				]
				default [0]
			]
			value: value + 1
		]
		#if debug? = yes [if verbose > 1 [indent: indent - 1]]
	]
	
	mark-block-node: func [
		ptr	[int-ptr!]
		/local
			node [node!]
			s	 [series!]
	][
		if keep ptr [
			node: as node! ptr/value
			s: as series! node/value
			mark-values s/offset s/tail
		]
	]
	
	mark-block: func [
		blk [red-block!]
		/local
			s [series!]
	][
		if keep :blk/node [
			s: GET_BUFFER(blk)
			mark-values s/offset s/tail
		]
	]
	
	update-series: func [								;-- Update moved series internal pointers
		s		[series!]								;-- start of series region with nodes to re-sync
		offset	[integer!]
		size	[integer!]
		/local
			tail [byte-ptr!]
	][
		tail: (as byte-ptr! s) + size
		until [
			s/node/value: as-integer s					;-- update the node pointer to the new series address
			s/offset: as cell! (as byte-ptr! s/offset) - offset	;-- update offset and tail pointers
			s/tail:   as cell! (as byte-ptr! s/tail) - offset
			s: as series! (as byte-ptr! s + 1) + s/size + SERIES_BUFFER_PADDING
			tail <= as byte-ptr! s
		]
	]

	compact-series-frame: func [						;-- Compact a series frame by moving down in-use series buffer regions
		frame	[series-frame!]							;-- series frame to compact
		refs	[int-ptr!]
		return: [int-ptr!]								;-- returns the next stack pointer to process
		/local
			tail  [int-ptr!]
			ptr	  [int-ptr!]
			s	  [series!]
			heap  [series!]
			src	  [byte-ptr!]
			dst	  [byte-ptr!]
			delta [integer!]
			size  [integer!]
			tail? [logic!]
	][
		tail: memory/stk-tail
		s: as series! frame + 1							;-- point to first series buffer
		heap: frame/heap
		src: null										;-- src will point to start of buffer region to move down
		dst: null										;-- dst will point to start of free region

		;assert heap > s
		if heap = s [return refs]

		until [
			tail?: no
			if s/flags and flag-gc-mark = 0 [			;-- check if it starts with a gap
				if dst = null [dst: as byte-ptr! s]
				;probe ["search live from: " s]
				collector/nodes-list/store s/node
				while [									;-- search for a live series
					s: as series! (as byte-ptr! s + 1) + s/size + SERIES_BUFFER_PADDING
					tail?: s >= heap
					not tail?
				][
					either s/flags and flag-gc-mark <> 0 [break][collector/nodes-list/store s/node]
				]
				;probe ["live found at: " s]
			]
			unless tail? [
				src: as byte-ptr! s
				;probe ["search gap from: " s]
				until [									;-- search for a gap
					s/flags: s/flags and not flag-gc-mark	;-- clear mark flag
					s: as series! (as byte-ptr! s + 1) + s/size + SERIES_BUFFER_PADDING
					tail?: s >= heap
					;@@ test tail? first, otherwise s/flags may crash if s = heap
					any [tail? s/flags and flag-gc-mark = 0]
				]
				;probe ["gap found at: " s]
				if dst <> null [
					assert dst < src					;-- regions are moved down in memory
					assert src < as byte-ptr! s 		;-- src should point at least at series - series/size

					size: as-integer (as byte-ptr! s) - src
					delta: as-integer src - dst
					;probe ["move src=" src ", dst=" dst ", size=" size]
					move-memory dst	src size
					update-series as series! dst delta size

					if refs < tail [					;-- update pointers on native stack
						while [all [refs < tail (as byte-ptr! refs/1) < src]][refs: refs + 2]
						while [all [refs < tail (as byte-ptr! refs/1) < (src + size)]][
							ptr: as int-ptr! refs/2
							ptr/value: ptr/value - delta
							refs: refs + 2
						]
					]
					dst: dst + size
				]
			]
			tail?
		]
		if dst <> null [								;-- no compaction occurred, all series were in use
			frame/heap: as series! dst					;-- set new heap after last moved region
			#if debug? = yes [markfill as int-ptr! frame/heap as int-ptr! frame/tail]
		]
		refs
	]

	cross-compact-frame: func [
		frame	[series-frame!]
		refs	[int-ptr!]
		return: [int-ptr!]
		/local
			prev	[series-frame!]
			free-sz [integer!]
			tail	[int-ptr!]
			ptr		[int-ptr!]
			s		[series!]
			ss		[series!]
			heap	[series!]
			src		[byte-ptr!]
			dst		[byte-ptr!]
			prev-dst [byte-ptr!]
			dst2	[byte-ptr!]
			set-cross [subroutine!]
			delta	[integer!]
			size	[integer!]
			size2	[integer!]
			tail?	[logic!]
			cross?	[logic!]
			update? [logic!]
	][
		set-cross: [
			either free-sz > 52428 [cross?: yes][		;- 1MB * 5%
				free-sz: 0
				cross?: no
			]
		]
		prev: frame/prev
		if null? prev [									;-- first frame
			return compact-series-frame frame refs
		]

		prev-dst: as byte-ptr! prev/heap
		free-sz: as-integer prev/tail - prev/heap
		set-cross

		tail: memory/stk-tail
		s: as series! frame + 1							;-- point to first series buffer
		heap: frame/heap
		if heap = s [return refs]

		src: null										;-- src will point to start of buffer region to move down
		dst: null										;-- dst will point to start of free region
		tail?: no

		until [
			if s/flags and flag-gc-mark = 0 [			;-- check if it starts with a gap
				if dst = null [dst: as byte-ptr! s]
				collector/nodes-list/store s/node
				while [									;-- search for a live series
					s: as series! (as byte-ptr! s + 1) + s/size + SERIES_BUFFER_PADDING
					tail?: s >= heap
					not tail?
				][
					either s/flags and flag-gc-mark <> 0 [break][collector/nodes-list/store s/node]
				]
			]
			unless tail? [
				size: 0
				src: as byte-ptr! s
				until [									;-- search for a gap
					s/flags: s/flags and not flag-gc-mark	;-- clear mark flag
					size2: size
					size: SERIES_BUFFER_PADDING + size + s/size + size? series-buffer!
					ss: s								;-- save previous series pointer
					s: as series! (as byte-ptr! s + 1) + s/size + SERIES_BUFFER_PADDING
					tail?: s >= heap
					any [	;@@ test tail? first, otherwise s/flags may crash if s = heap
						tail?	
						all [cross? size >= free-sz]
						s/flags and flag-gc-mark = 0
					]
				]

				update?: yes
				case [
					any [
						size <= free-sz
						all [size2 > 0 size2 <= free-sz]
					][
						if dst = null [dst: src]
						if size > free-sz [
							size: size2
							s: ss
							s/flags: s/flags or flag-gc-mark
							tail?: no
						]
						free-sz: free-sz - size
						set-cross
						delta: as-integer src - prev-dst
						dst2: prev-dst
						prev-dst: prev-dst + size
					]
					dst <> null [
						assert dst < src				;-- regions are moved down in memory
						assert src < as byte-ptr! s 	;-- src should point at least at series - series/size

						size: as-integer (as byte-ptr! s) - src
						delta: as-integer src - dst
						dst2: dst
						dst: dst + size
					]
					true [
						update?: no
						cross?: no
					]
				]

				if update? [
					;probe ["(x-compact) move src=" src ", dst=" dst2 ", size=" size]
					move-memory dst2 src size
					update-series as series! dst2 delta size
					if refs < tail [			;-- update pointers on native stack
						while [all [refs < tail (as byte-ptr! refs/1) < src]][refs: refs + 2]
						while [all [refs < tail (as byte-ptr! refs/1) < (src + size)]][
							ptr: as int-ptr! refs/2
							ptr/value: ptr/value - delta
							;probe ["(x-compact) update pointer " as int-ptr! refs/1 " on stack at: " ptr]
							refs: refs + 2
						]
					]
				]
			]
			tail?
		]

		prev/heap: as series! prev-dst
		if dst <> null [								;-- no compaction occurred, all series were in use
			frame/heap: as series! dst					;-- set new heap after last moved region
			#if debug? = yes [markfill as int-ptr! frame/heap as int-ptr! frame/tail]
		]
		if all [dst = as byte-ptr! (frame + 1) frame/next <> null][		;-- cache last one
			free-series-frame frame
		]
		refs
	]

	encode-dyn-ptr: func [
		stk	    [int-ptr!]								;-- stack frame pointer
		typed?  [logic!]								;-- typed or generic variadic function
		return: [integer!]								;-- return a bitmap of pointer slots
		/local
			count i bits [integer!]
			ptr? [logic!]
	][
		stk: stk + 2
		count: stk/value								;-- args count
		stk: stk + 1
		stk: as int-ptr! stk/value						;-- args pointer
		i: 3											;-- skip variadic slots header
		bits: 0
		either typed? [									;-- typed call (RTTI available)
			assert count <= 9							;-- 32 - 3, divided by 3 slots per argument
			loop count [
				switch stk/value [						;-- argument type ID
					type-c-string!
					type-byte-ptr!
					type-int-ptr!
					type-struct! [ptr?: yes]
					default		 [ptr?: stk/value >= 1000]
				]
				i: i + 1
				if ptr? [bits: bits or (1 << i)]		;-- mark pointer
				i: i + 2								;-- skip 64-bit slot
			]
			bits
		][												;-- variadic call (no RTTI)
			assert count <= 14							;-- 32 - 3 divided by 2 slots per argument
			bits: (1 << (count * 2)) - 1				;-- set bits for all required positions
			bits and 55555555h << i						;-- mask to keep only even positions, offset by i bits
		]
	]

	scan-stack-refs: func [
		table  [int-ptr!]								;-- optional table for nodes relocation
		store? [logic!]									;-- store series pointers in a list for later eventual update
		/local
			frm	map	slot p sp b base base' head prev [int-ptr!]
			refs tail new [int-ptr!]
			node [node!]
			c-low c-high lib-low lib-high caller [byte-ptr!]
			s [series!]
			bits idx disp nb [integer!]
			ext? [logic!]
	][
		c-low: system/image/base + system/image/code
		c-high: c-low + system/image/code-size
		#if libRedRT? = yes [
			lib-low: system/lib-image/base + system/lib-image/code
			lib-high: lib-low + system/lib-image/code-size
		]
		frm: system/stack/frame
		refs: memory/stk-refs
		tail: refs + (memory/stk-sz * 2)
		base: bitarrays-base
		base': lib-bitarrays-base						;-- points to libRedRT's bitmap array
		prev: frm
		frm: as int-ptr! frm/value						;-- skip extract-stack-refs own frame

		until [
			caller: either any [null? prev  prev = as int-ptr! -1  prev >= stk-bottom][null][
				as byte-ptr! prev/2
			]
		#either libRedRT? = yes [
			if any [									;-- only process Red frames (skip externals)
				all [c-low < caller caller < c-high]
				all [lib-low < caller caller < lib-high]
			]
		][
			if all [c-low < caller caller < c-high]		;-- only process Red frames (skip externals)
		]
			[
				slot: frm - 3							;-- position on bitmap slot
				assert slot/value >= 0					;-- should never hit STACK_BITMAP_BARRIER
				b: either slot/value and 40000000h <> 0 [base'][base] ;-- select exe or dll's bitmap array
				map: b + (slot/value and 0FFFFFFFh)		;-- first corresponding bitmap slot (removing bit flags)
				head: map								;-- saved head reference for later args bitmap detection
				idx: 2									;-- arguments index (1-based)
				disp: 1									;-- scanning direction
				loop 2 [								;-- 1st loop: args, 2nd loop: locals
					until [
						bits: map/value					;-- read 31 slots bitmap
						ext?: bits and 80000000h <> 0	;-- read extension bit
						bits: bits and 7FFFFFFFh		;-- clear extension bit
						if all [
							map = head					;-- only for args bitmaps
							any [bits = 40000000h bits = 20000000h] ;-- variadic/typed function call
						][
							bits: encode-dyn-ptr frm bits = 20000000h ;-- replace bitmap by a dynamic one (32 stack slots only)
						]
						while [bits <> 0][
							idx: idx + disp
							if bits and 1 <> 0 [		;-- check if the slot is a pointer
								p: as int-ptr! frm/idx
								if all [
									p > as int-ptr! FFFFh	  ;-- filter out too low values
									p < as int-ptr! FFFFF000h ;-- filter out too high values
								][
									sp: frm + idx - 1
									case [
										all [			;=== Mark node! references ===
											(as-integer p) and 3 = 0	;-- check if it's a valid int-ptr!
											frames-list/find p FRAME_NODES
											p/value <> 0
											not frames-list/find as int-ptr! p/value FRAME_NODES ;-- freed nodes can still be on the stack!
											keep sp
										][
											;probe ["(scan) node pointer on stack: " p " : " as byte-ptr! p/value]
											p: as int-ptr! sp/value		;-- refresh it after `keep sp` call
											s: as series! p/value
											if GET_UNIT(s) = 16 [mark-values s/offset s/tail]
										]
										all [
											not all [(as byte-ptr! stack/bottom) <= p p <= (as byte-ptr! stack/top)] ;-- stack region is fixed
											frames-list/find p FRAME_SERIES
										][
											;probe ["stack pointer: " p " : " as byte-ptr! p/value " (" frm + idx - 1 ")"]
											if store? [	;=== Extract series references ===
												if refs = tail [
													;@@ for cases like issue #3628, should find a better way to handle it
													refs: memory/stk-refs
													memory/stk-sz: memory/stk-sz + 1000
													refs: as int-ptr! realloc as byte-ptr! refs memory/stk-sz * 2 * size? int-ptr!
													memory/stk-refs: refs
													tail: refs + (memory/stk-sz * 2)
													refs: tail - 2000
												]
												refs/1: as-integer p	;-- pointer inside a frame
												refs/2: as-integer sp	;-- pointer address on stack
												refs: refs + 2
											]
										]
										true [0]
									]
								]
							]
							bits: bits >>> 1			;-- next slot flag
						]
						map: map + 1					;-- next 31 slots bitmap
						not ext?						;-- loop until no more extended slots
					]
					idx:  -3							;-- locals index (1-based)
					disp: -1							;-- scanning direction
				]
			]
			prev: frm
			frm: as int-ptr! frm/value					;-- jump to next stack frame
			if frm < prev [								;-- if broken frames chain
				slot: prev - 4
				frm: as int-ptr! slot/value				;-- use last known parent frame pointer
				if frm < prev [break]
			]
			any [null? frm  frm = as int-ptr! -1  frm >= stk-bottom]
		]
		memory/stk-tail: refs
		nb: (as-integer refs - memory/stk-refs) >> 2 / 2

		if all [store? nb > 0][
			qsort as byte-ptr! memory/stk-refs nb 8 :compare-cb

			;tail: refs
			;refs: memory/stk-refs
			;until [
			;	probe [refs ": [" as int-ptr! refs/1 #":" as int-ptr! refs/2 #"]"]
			;	refs: refs + 2
			;	refs = tail
			;]
		]
	]

	collect-series-frames: func [
		type	  [integer!]
		/local
			frame [series-frame!]
			refs  [int-ptr!]
			next  [series-frame!]
	][
		next: null
		refs: null
		frame: memory/s-head
		refs: memory/stk-refs

		until [
			;@@ current frame may be released
			;@@ rare case: the starting address of next frame may be identical to 
			;@@ the tail of the last frame, add 1 to avoid moving
			next: frame/next + 1

			either type = COLLECTOR_RELEASE [
				refs: cross-compact-frame frame refs
			][
				refs: compact-series-frame frame refs
			]
			frame: next - 1
			frame = null
		]
		;#if debug? = yes [					;; enable it once we get a visual exception reporting for panic exits!
		;	frame: memory/s-head
		;	until [
		;		check-series frame
		;		frame: frame/next
		;		frame = null
		;	]
		;]
	]
	
	do-mark-sweep: func [
		/local
			p		[int-ptr!]
		#if debug? = yes [
			file	[c-string!]
			saved	[integer!]
			buf		[c-string!]
			tm tm1	[float!]
		]
			cb		[function! []]
	][
		system/atomic/store :state GC_RUNNING

		#if debug? = yes [if verbose > 1 [
			#if OS = 'Windows [platform/dos-console?: no]
			file: "                      "
			sprintf [file "live-values-%d.log" stats/cycles]
			saved: stdout
			stdout: simple-io/open-file file simple-io/RIO_APPEND no
		]]

		#if debug? = yes [
			if verbose > 3 [stack-trace]
			buf: "                                                               "
			tm: platform/get-time yes yes
			print [
				"root: " block/rs-length? root "/" ***-root-size
				", runs: " stats/cycles
				", mem: " 	memory-info null 1
			]
			if verbose > 1 [probe "^/marking..."]
		]

		do-node-cycle
		mark-block root
		#if debug? = yes [if verbose > 1 [probe "marking symbol table"]]
		_hashtable/mark as int-ptr! :symbol/table		;-- will mark symbols
		#if debug? = yes [if verbose > 1 [probe "marking ownership table"]]
		_hashtable/mark as int-ptr! :ownership/table

		#if debug? = yes [if verbose > 1 [probe "marking stack"]]
		keep :arg-stk/node
		keep :call-stk/node
		mark-values stack/bottom stack/top
		
		#if debug? = yes [if verbose > 1 [probe "marking globals"]]
		if interpreter/near/node <> null [keep :interpreter/near/node]
		lexer/mark-buffers
		mark-block-node :references/list/node
		
		#if debug? = yes [if verbose > 1 [probe "marking globals from optional modules"]]
		p: ext-markers
		while [p < ext-top][
			if p/value <> 0 [							;-- check if not unregistered
				cb: as function! [] p/value
				cb
			]
			p: p + 1
		]
		
		#if debug? = yes [if verbose > 1 [probe "scanning native stack"]]
		frames-list/rebuild								;-- refresh nodes and series frames list
		scan-stack-refs refs yes

		#if debug? = yes [tm1: (platform/get-time yes yes) - tm]	;-- marking time

		#if debug? = yes [if verbose > 1 [probe "sweeping..."]]
		externals/sweep
		_hashtable/sweep ownership/table
		collect-series-frames COLLECTOR_RELEASE
		collect-big-frames
		nodes-list/flush
		collect-node-frames

		if refs <> null [
			_hashtable/rs-destroy refs					;-- clear all the node entries
			refs: null
		]
	
		;-- unmark fixed series
		unmark root/node
		unmark arg-stk/node
		unmark call-stk/node
		
		stats/cycles: stats/cycles + 1

		#if debug? = yes [
			tm: (platform/get-time yes yes) - tm - tm1
			sprintf [buf ", mark: %.1fms, sweep: %.1fms" tm1 * 1000.0 tm * 1000.0]
			probe [" => " memory-info null 1 buf]
			if verbose > 1 [
				simple-io/close-file stdout
				stdout: saved
				#if OS = 'Windows [platform/dos-console?: yes]
			]
			if verbose > 0 [validate]
		]
		system/atomic/store :state GC_DONE
	]

	running?: func [return: [logic!]][
		GC_RUNNING = system/atomic/load :state
	]

	do-cycle: does [
		unless active? [exit]
		do-mark-sweep
	]
	
	register: func [cb [int-ptr!]][
		assert (as-integer ext-top - ext-markers) >> 2 < ext-size
		ext-top/value: as-integer cb
		ext-top: ext-top + 1
	]
	
	unregister: func [cb [int-ptr!] /local p [int-ptr!]][
		p: ext-markers
		while [p < ext-top][
			if p/value = as-integer cb [p/value: 0 exit]
			p: p + 1
		]
	]
;comment {	
	#if debug? = yes [
		;== Memory integrity checkings ==
		
		#enum errors! [
			NODE_FRM_HEAD: 1
			NODE_FRM_NO_LOCK
			NODE_FRM_SIZE
			NODE_FRM_USED
			NODE_FRM_FREE
			NODE_FRM_USED_CTRL
		]
		
		messages: [
			"node frame's /prev is not Null at linked-list head"
			"locked node frame not freed"
			"node frame slots size invalid"
			"node frame used slots value out of range"
			"node frame free slots inconsistent"
			"node frame counted used slots does not match frame's /used value"
		]
		
		--assert: func [id [integer!] b [logic!]][
			unless b [
				print-line [
					"^/** Error: "
					as-c-string messages/id 
					"! (" id ")^/stopping..."
				]
				quit -1
			]
		]

		check-node-frames: func [
			verbose [integer!]
			/local
				frame	[node-frame!]
				p v [int-ptr!]
				head tail slot [node!]
				free used w [integer!]
		][
			if verbose > 0 [print lf]
			
			frame: memory/n-head
			--assert NODE_FRM_HEAD frame/prev = null
						
			until [
				;-- header checkings
				--assert NODE_FRM_NO_LOCK	not frame/locked?
				--assert NODE_FRM_SIZE		frame/nodes = nodes-per-frame
				--assert NODE_FRM_USED		all [0 <= frame/used  frame/used <= nodes-per-frame]
				
				;-- free slots list consistency checking
				free: 0
				p: frame/head
				
				while [p <> null][
					free: free + 1
					p: as int-ptr! p/value				;-- next free slot
				]
				if verbose > 0 [probe ["Frame: " frame ", /used: " frame/used ", free: " free]]
				--assert NODE_FRM_FREE nodes-per-frame - frame/used = free
				
				;-- full slots checking
				head: as node! frame + 1				;-- skip frame header
				slot: head
				tail: slot + frame/nodes
				w: nodes-per-frame * size? node!		;-- fixed node frame width
				used: 0
				
				loop frame/nodes [
					v: as int-ptr! slot/value
					unless any [null? v all [head <= v v < tail]][
						used: used + 1
						;also check if part of series frame
					]
					slot: slot + 1
				]
				if verbose > 0 [probe ["Frame: " frame ", /used: " frame/used ", counted: " used]]
				--assert NODE_FRM_USED_CTRL frame/used = used
				
				frame: frame/next
				frame = null
			]
		]
		
		validate: func [
			/local verbosity [integer!]
		][
			verbosity: 0
			print-line "^/== Memory Checks=="
			print "=> nodes frames checking..."
			check-node-frames verbosity
			print-line "OK"
		]
		
		; series frames checkings (normal + big)
		;	- frame header sanity checks
		;   - series header checks
		;	- values series header checks
		
		; node frames checkings
		;	- frame header sanity checks
		;	- nodes free list checks
		;	- node's value validity check (series pointers)
	
		; check live values validity
		; check all stack slot pointers validity
	
	]
;}
]