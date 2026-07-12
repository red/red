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
		cycles		 [integer!]							;-- nb or GC runs
		nodes-cycles [integer!]							;-- nb of node frames compaction runs
	]
	
	ext-size: 100
	ext-markers: as ptr-ptr! allocate ext-size * size? int-ptr!
	ext-top: ext-markers
	
	refs: as int-ptr! 0
	refs-size: 20000

	
	indent: 0
	
	init: func [
		/local mask [integer!]
	][
		stats/cycles: 			0
		stats/nodes-cycles:		0
		prefs/nodes-gc-trigger: 5						;-- trigger if node frame is unchanged after 5 cycles
	]

	compare-cb: func [
		[cdecl]
		a [int-ptr!]
		b [int-ptr!]
		return: [integer!]
		/local pa pb [ptr-ptr!]
	][
		pa: as ptr-ptr! a
		pb: as ptr-ptr! b
		SIGN_COMPARE_RESULT(pa/value pb/value)
	]

	node-record!: alias struct! [
		node	[node!]
		handle	[node-handle!]
	]

	compare-node-record-cb: func [
		[cdecl]
		a [int-ptr!]
		b [int-ptr!]
		return: [integer!]
		/local
			ra [node-record!]
			rb [node-record!]
	][
		ra: as node-record! a
		rb: as node-record! b
		SIGN_COMPARE_RESULT(ra/node rb/node)
	]
	
	frames-list: context [
		min-size:  1000
		fit-cache: 16									;-- nb of pointers fitting into a typical 64 bytes L1 cache

		list!: alias struct! [
			list  [ptr-ptr!] 							;-- array of native-width frame pointers
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
				pos [ptr-ptr!]
				s	[list!]
				cnt [integer!]
				process [subroutine!]
		][
			;-- allocation alignement not guaranteed, so L1 cache optmization is only eventual.
			if null? nodes/list  [nodes/list:  as ptr-ptr! allocate min-size * size? int-ptr!]
			if null? series/list [series/list: as ptr-ptr! allocate min-size * size? int-ptr!]
			
			process: [
				until [
					pos/value: as int-ptr! frm
					pos: pos + 1
					cnt: cnt + 1
					if cnt >= s/size [
						s/size: s/size * 2
						s/list: as ptr-ptr! realloc as byte-ptr! s/list s/size * size? int-ptr!
						pos: s/list + cnt
					]
					frm: frm/next
					frm = null
				]
				if all [cnt > min-size cnt * 3 < s/size][	;-- shrink buffer if 2/3 or more are not used
					s/size: cnt
					s/list: as ptr-ptr! realloc as byte-ptr! s/list s/size * size? int-ptr!
				]
				qsort as byte-ptr! s/list cnt size? int-ptr! :compare-cb	;-- sort the array
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
				frm			 [int-ptr!]
				p b e		 [ptr-ptr!]
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
						if all [
							frm <= ptr
							ptr < as int-ptr! ((as byte-ptr! frm) + w)
							zero? (((as-integer ptr) - (as-integer frm)) and ((size? node!) - 1))
						][return yes]
						p: p + 1
					]
				]
			][											;== binary search for arrays bigger than 16 nodes
				b: s/list								;-- low pointer
				e: s/list + (s/count - 1)				;-- high pointer
				either series? [
					until [
						p: b + ((((as-integer e - b) / size? int-ptr!) + 1) / 2) ;-- points to the middle of [b,e] segment
						sfrm: as series-frame! p/value
						tail: (as byte-ptr! sfrm) + sfrm/size
						if all [(as int-ptr! (as byte-ptr! sfrm) + h) <= ptr ptr < as int-ptr! tail][return yes]
						end?: b = e						;-- gives a chance to probe the b = e segment
						either (as int-ptr! p/value) < ptr [b: p][e: p - 1] ;-- chooses lower or upper segment
						end?
					]
				][
					until [
						p: b + ((((as-integer e - b) / size? int-ptr!) + 1) / 2) ;-- points to the middle of [b,e] segment
						frm: as int-ptr! p/value + h
						if all [
							frm <= ptr
							ptr < as int-ptr! ((as byte-ptr! frm) + w)
							zero? (((as-integer ptr) - (as-integer frm)) and ((size? node!) - 1))
						][return yes]
						end?: b = e						;-- gives a chance to probe the b = e segment
						either (as int-ptr! p/value) < ptr [b: p][e: p - 1] ;-- chooses lower or upper segment
						end?
					]
				]
			]
			no
		]
	]
	
	nodes-list: context [								;-- nodes freeing batch handling
		list:	  as node-record! 0
		min-size: 20000
		buf-size: min-size								;-- initial number of supported nodes
		count:	  0										;-- current number of stored nodes
		
		init: does [list: as node-record! allocate buf-size * size? node-record!]
		
		store: func [
			handle [node-handle!]
			/local
				node [node!]
				slot [node-record!]
		][
			if zero? handle [exit]					;-- expanded series clears the old back-reference
			node: resolve-node handle
			if count = buf-size [flush]					;-- buffer full, flush it first
			slot: list + count
			slot/node: node
			slot/handle: handle
			count: count + 1
		]
		
		flush: func [									;-- assumes frames-list buffer is built and sorted
			/local
				frm new [int-ptr!]
				p e [ptr-ptr!]
				node [node!]
				n [node-record!]
				frm-nb w handle [integer!]
		][
			if zero? count [exit]
			qsort as byte-ptr! list count size? node-record! :compare-node-record-cb
			p: frames-list/nodes/list
			e: p + frames-list/nodes/count
			w: nodes-per-frame * size? node!			;-- node frame width
			n: list
			
			loop count [
				node: n/node
				handle: n/handle
				while [
					frm: as int-ptr! ((as node-frame! p/value) + 1)
					not all [frm <= as int-ptr! node  (as int-ptr! node) < as int-ptr! ((as byte-ptr! frm) + w)]
				][
					p: p + 1
					assert p <= e						;-- parent frame should always be found
				]
				free-node-handle handle
				free-node as node-frame! p/value node
				n/node: null							;-- not strictly needed, but cleaner that way.
				n/handle: 0
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
			if all [
				ptr <> null
				any [ptr < as int-ptr! head  (as int-ptr! tail) < ptr]
			][										;-- move node's value if it is not an internal free-list link
				if null? dst/head [dst: select-dst]		;-- if dst frame is full, find a new one
				new: dst/head							;-- alloc node slot in dst frame
				dst/head: as node! new/value			;-- set free list head to next free slot
				new/value: ptr							;-- transfer the node's full-width value
				_hashtable/rs-put refs as-integer slot as-integer new	;-- store old (key), new (value) pair
				;print-line ["relocating node: " slot " from frame " src " to " dst " (new: " new ")"]
				s: as series! ptr
				set-node-handle s/node new				;-- retarget the stable handle
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
			done? [logic!]
	][
		assert nodes-list/count = 0
		!mask: 1 << (prefs/nodes-gc-trigger + 1) - 1	;-- create mask for checking frame usage across last 32 GC passes

		frame: memory/n-head
		while [all [frame <> null null? frame/head]][frame: frame/next]
		if null? frame [exit]							;-- all the frames are full
		memory/n-active: frame							;-- initialize dst

		done?: no
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
				done?: yes
			]
			frame: frame/prev
			frame = null
		]
		if done? [stats/nodes-cycles: stats/nodes-cycles + 1] ;-- increment count if at least one frame was compacted.
	]
	
	refresh-array: func [p [node!] end [node!] /local new [int-ptr!]][
		while [p < end][
			;probe ["p: " p ", node: " as int-ptr! p/value]
			new: _hashtable/rs-get refs as-integer p/value
			if new <> null [prin "." p/value: as int-ptr! new/value]
			p: p + 1
		]
	]
	
	keep-raw: func [
		ptr		[ptr-ptr!]
		return: [logic!]								;-- TRUE if newly marked, FALSE if already done
		/local
			node [node!]
			new  [int-ptr!]
			s	  [series!]
			new?  [logic!]
			flags [integer!]
	][
		if refs <> null [
			new: _hashtable/rs-get refs as-integer ptr/value
			if new <> null [
				;probe ["(keep) ptr: " ptr ", node: " as node! ptr/value ", new: " as node! new/value]
				ptr/value: as int-ptr! new/value
			]
		]	
		node: as node! ptr/value
		s: as series! node/value
		flags: s/flags
		new?: flags and flag-gc-mark = 0
		if new? [s/flags: flags or flag-gc-mark]
		new?
	]

	keep: func [
		ptr		[int-ptr!]
		return: [logic!]								;-- TRUE if newly marked, FALSE if already done
		/local
			node  [node!]
			s     [series!]
			new?  [logic!]
			flags [integer!]
	][
		if zero? ptr/value [return no]
		node: resolve-node ptr/value
		s: as series! node/value
		flags: s/flags
		new?: flags and flag-gc-mark = 0
		if new? [s/flags: flags or flag-gc-mark]
		new?
	]

	unmark: func [
		handle	[node-handle!]
		/local s [series!]
	][
		s: resolve-series handle
		s/flags: s/flags and not flag-gc-mark
	]
	
	mark-context: func [
		ptr		[int-ptr!]
		/local
			node [int-ptr!]
			ctx  [red-context!]
			slot [red-value!]
	][
		if keep ptr [
			ctx: TO_CTX(ptr/value)							;-- [context! function!|object!]
			slot: as red-value! ctx
			node: as int-ptr! resolve-node ctx/symbols
			_hashtable/mark as ptr-ptr! :node
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
			node	[int-ptr!]
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
					if HANDLE?(word/ctx) [
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
					if HANDLE?(series/node) [			;-- can happen in routine
						#if debug? = yes [if verbose > 1 [print ["len: " block/rs-length? as red-block! series]]]
						mark-block as red-block! value
					]
				]
				TYPE_SYMBOL [
					series: as red-series! value
					keep :series/extra
					if HANDLE?(series/node) [keep :series/node]
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
					if HANDLE?(obj/on-set) [keep :obj/on-set]
				]
				TYPE_CONTEXT [
					#if debug? = yes [if verbose > 1 [print "context"]]
					ctx: as red-context! value
					;keep :ctx/self
					node: as int-ptr! resolve-node ctx/symbols
					_hashtable/mark as ptr-ptr! :node
					unless ON_STACK?(ctx) [mark-block-node :ctx/values]
				]
				TYPE_HASH
				TYPE_MAP [
					#if debug? = yes [if verbose > 1 [print "hash/map"]]
					hash: as red-hash! value
					mark-block-node :hash/node
					node: as int-ptr! resolve-node hash/table
					_hashtable/mark as ptr-ptr! :node		;@@ check if previously marked
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
					if HANDLE?(img/node) [
						keep :img/node
						image/mark resolve-node img/node
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
			s: resolve-series ptr/value
			mark-values s/offset s/tail
		]
	]

	mark-block-raw: func [
		ptr	[ptr-ptr!]
		/local
			node [node!]
			s	 [series!]
	][
		if keep-raw ptr [
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
	
	prepare-series-move: func [						;-- Rewrite headers for a pending series move
		src dst	[byte-ptr!]							;-- source and destination regions
		size	[integer!]
		/local
			s destination [series!]
			tail [byte-ptr!]
			offset [integer!]
	][
		s: as series! src
		destination: as series! dst
		tail: src + size
		until [
			set-node-value s/node as int-ptr! destination	;-- update the node pointer before moving the bytes
			offset: as-integer (as byte-ptr! s/offset) - (as byte-ptr! s)
			s/offset: as cell! (as byte-ptr! destination) + offset
			offset: as-integer (as byte-ptr! s/tail) - (as byte-ptr! s)
			s/tail: as cell! (as byte-ptr! destination) + offset
			destination: as series! (as byte-ptr! destination + 1) + s/size + SERIES_BUFFER_PADDING
			s: as series! (as byte-ptr! s + 1) + s/size + SERIES_BUFFER_PADDING
			tail <= as byte-ptr! s
		]
	]

	compact-series-frame: func [						;-- Compact a series frame by moving down in-use series buffer regions
		frame	[series-frame!]							;-- series frame to compact
		refs	[ptr-ptr!]
		return: [ptr-ptr!]								;-- returns the next stack pointer to process
		/local
			tail  [ptr-ptr!]
			ptr	  [ptr-ptr!]
			s	  [series!]
			heap  [series!]
			src	  [byte-ptr!]
			dst	  [byte-ptr!]
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
					;probe ["move src=" src ", dst=" dst ", size=" size]
					prepare-series-move src dst size
					move-memory dst src size

					if refs < tail [					;-- update pointers on native stack
						while [all [refs < tail (as byte-ptr! refs/value) < src]][refs: refs + 2]
						while [all [refs < tail (as byte-ptr! refs/value) < (src + size)]][
							ptr: refs + 1
							ptr: as ptr-ptr! ptr/value
							ptr/value: as int-ptr! (dst + (as-integer (as byte-ptr! ptr/value) - src))
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
		refs	[ptr-ptr!]
		return: [ptr-ptr!]
		/local
			prev	[series-frame!]
			free-sz [integer!]
			tail	[ptr-ptr!]
			ptr		[ptr-ptr!]
			s		[series!]
			ss		[series!]
			heap	[series!]
			src		[byte-ptr!]
			dst		[byte-ptr!]
			prev-dst [byte-ptr!]
			dst2	[byte-ptr!]
			set-cross [subroutine!]
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
						dst2: prev-dst
						prev-dst: prev-dst + size
					]
					dst <> null [
						assert dst < src				;-- regions are moved down in memory
						assert src < as byte-ptr! s 	;-- src should point at least at series - series/size

						size: as-integer (as byte-ptr! s) - src
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
					prepare-series-move src dst2 size
					move-memory dst2 src size
					if refs < tail [			;-- update pointers on native stack
						while [all [refs < tail (as byte-ptr! refs/value) < src]][refs: refs + 2]
						while [all [refs < tail (as byte-ptr! refs/value) < (src + size)]][
							ptr: refs + 1
							ptr: as ptr-ptr! ptr/value
							ptr/value: as int-ptr! (dst2 + (as-integer (as byte-ptr! ptr/value) - src))
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
		stk	    [ptr-ptr!]								;-- native-width stack frame pointer
		typed?  [logic!]								;-- typed or generic variadic function
		return: [integer!]								;-- return a bitmap of pointer slots
		/local
			count i bits [integer!]
			ptr? [logic!]
	][
		#either target = 'X86-64 [
			stk: stk - 5
			count: as-integer stk/value				;-- args count
			stk: stk - 1
			stk: as ptr-ptr! stk/value					;-- args pointer
			i: either typed? [2][3]
		][
			stk: stk + 2
			count: as-integer stk/value				;-- args count
			stk: stk + 1
			stk: as ptr-ptr! stk/value					;-- args pointer
			i: 3										;-- skip variadic slots header
		]
		bits: 0
		#if target = 'X86-64 [bits: 2]					;-- list is the second formal argument
		either typed? [									;-- typed call (RTTI available)
			assert count <= 9							;-- 32 - 3, divided by 3 slots per argument
			loop count [
				switch as-integer stk/value [			;-- argument type ID
					type-c-string!
					type-byte-ptr!
					type-int-ptr!
					type-struct! [ptr?: yes]
					default		 [ptr?: (as-integer stk/value) >= 1000]
				]
				i: i + 1
				if ptr? [bits: bits or (1 << i)]		;-- mark pointer
				i: i + 2								;-- skip 64-bit slot
			]
			bits
		][												;-- variadic call (no RTTI)
			assert count <= 14							;-- 32 - 3 divided by 2 slots per argument
			#either target = 'X86-64 [
				bits or (((1 << count) - 1) << i)
			][
				bits: (1 << (count * 2)) - 1			;-- set bits for all required positions
				bits and 55555555h << i					;-- mask to keep only even positions, offset by i bits
			]
		]
	]

	scan-stack-refs: func [
		store? [logic!]									;-- store series pointers in a list for later eventual update
		/local
			frm slot sp prev [ptr-ptr!]
			sp-address [byte-ptr!]
			map p b base base' head [int-ptr!]
			refs tail new entry [ptr-ptr!]
			node [node!]
			c-low c-high lib-low lib-high caller [byte-ptr!]
			s [series!]
			bits slot-bits idx disp nb arg-slots local-slots slots handle [integer!]
			ext? dyn? [logic!]
	][
		c-low: system/image/base + system/image/code
		c-high: c-low + system/image/code-size
		#if libRedRT? = yes [
			lib-low: system/lib-image/base + system/lib-image/code
			lib-high: lib-low + system/lib-image/code-size
		]
		frm: as ptr-ptr! system/stack/frame
		refs: memory/stk-refs
		nb: 0
		tail: refs + (memory/stk-sz * 2)
		base: bitarrays-base
		base': lib-bitarrays-base						;-- points to libRedRT's bitmap array
		prev: frm
		frm: as ptr-ptr! frm/value						;-- skip extract-stack-refs own frame

		until [
			caller: either any [null? prev  prev = as ptr-ptr! -1  prev >= as ptr-ptr! stk-bottom][null][
				slot: prev + 1
				as byte-ptr! slot/value
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
				slot-bits: as-integer slot/value
				assert slot-bits >= 0					;-- should never hit STACK_BITMAP_BARRIER
				b: either slot-bits and 40000000h <> 0 [base'][base] ;-- select exe or dll's bitmap array
				map: b + (slot-bits and 0FFFFFFFh)		;-- first corresponding bitmap slot (removing bit flags)
				#either target = 'X86-64 [
					arg-slots: map/value
					map: map + 1
					local-slots: map/value
					map: map + 1
				][
					arg-slots: 0
					local-slots: 0
				]
				head: map								;-- saved head reference for later args bitmap detection
				#either target = 'X86-64 [idx: -1][idx: 2] ;-- arguments index
				disp: 1									;-- scanning direction
				loop 2 [								;-- 1st loop: args, 2nd loop: locals
					#either target = 'X86-64 [
						slots: either disp = 1 [arg-slots][local-slots]
					][slots: 0]
					until [
						bits: map/value					;-- read 31 slots bitmap
						ext?: bits and 80000000h <> 0	;-- read extension bit
						bits: bits and 7FFFFFFFh		;-- clear extension bit
						dyn?: no
						if all [
							map = head					;-- only for args bitmaps
							any [bits = 40000000h bits = 20000000h] ;-- variadic/typed function call
						][
							dyn?: yes
							bits: encode-dyn-ptr frm bits = 20000000h ;-- replace bitmap by a dynamic one (32 stack slots only)
							#if target = 'X86-64 [slots: 31]
						]
						while [#either target = 'X86-64 [
							any [bits <> 0 (idx + 1) < slots]
						][
							bits <> 0
						]][
							#either target = 'X86-64 [idx: idx + 1][idx: idx + disp]
							#if target = 'X86-64 [
								sp-address: either disp = -1 [
									(as byte-ptr! frm) - ((5 + arg-slots + idx) * size? pointer!)
								][either all [dyn? idx >= arg-slots] [
									(as byte-ptr! frm) + ((2 + idx - arg-slots) * size? pointer!)
								][
									(as byte-ptr! frm) - ((5 + idx) * size? pointer!)
								]]
								sp: as ptr-ptr! sp-address
								if all [idx < slots][
									handle: as integer! sp/value
									if all [handle > 0 handle < node-registry/next][
										entry: node-registry/entries + (handle - 1)
										if entry/value <> null [keep as int-ptr! sp]
									]
								]
							]
							if bits and 1 <> 0 [		;-- check if the slot is a pointer
								#either target = 'X86-64 [
								][sp: frm + idx - 1]
								p: sp/value
								if #either target = 'X86-64 [
									p > as int-ptr! FFFFh
								][all [
									p > as int-ptr! FFFFh	  ;-- filter out too low values
									p < as int-ptr! FFFFF000h ;-- filter out too high values
								]][
									node: as node! p
									case [
										all [			;=== Mark node! references ===
											frames-list/find p FRAME_NODES
											node/value <> null
											not frames-list/find node/value FRAME_NODES ;-- freed nodes can still be on the stack!
											frames-list/find node/value FRAME_SERIES
											keep-raw as ptr-ptr! sp
										][
											;probe ["(scan) node pointer on stack: " p " : " as byte-ptr! node/value]
											p: sp/value				;-- refresh it after `keep sp` call
											node: as node! p
											s: as series! node/value
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
													refs: as ptr-ptr! realloc as byte-ptr! refs memory/stk-sz * 2 * size? int-ptr!
													memory/stk-refs: refs
													tail: refs + (memory/stk-sz * 2)
													refs: tail - 2000
												]
												refs/value: p			;-- pointer inside a frame
												new: refs + 1
												#either target = 'X86-64 [
													new/value: as int-ptr! sp-address
												][new/value: as int-ptr! sp]
												refs: refs + 2
												nb: nb + 1
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
					#either target = 'X86-64 [idx: -1][idx: -3] ;-- locals index
					disp: -1							;-- scanning direction
				]
			]
			prev: frm
			frm: as ptr-ptr! frm/value					;-- jump to next stack frame
			if frm < prev [								;-- if broken frames chain
				slot: prev - 4
				frm: as ptr-ptr! slot/value				;-- use last known parent frame pointer
				if frm < prev [break]
			]
			any [null? frm  frm = as ptr-ptr! -1  frm >= as ptr-ptr! stk-bottom]
		]
		memory/stk-tail: refs

		if all [store? nb > 0][
			qsort as byte-ptr! memory/stk-refs nb (2 * size? int-ptr!) :compare-cb

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
			refs  [ptr-ptr!]
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
			marker	[ptr-ptr!]
		#if debug? = yes [
			file	[c-string!]
			saved	[integer!]
			buf		[c-string!]
			tm tm1	[float!]
		]
			cb		[function! []]
	][
		if GC_RUNNING = system/atomic/load :state [exit]
		system/atomic/store :state GC_RUNNING			;-- camera widget relies on threads and reads this value.

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
				", nodes-runs: " stats/nodes-cycles
;; run-all-comp2 has strange nodes-runs pattern: check!
				", mem: " 	memory-info null 1
			]
			if verbose > 1 [probe "^/marking..."]
		]

		#either target = 'X86-64 [
			0										;-- rs-* relocation map still uses 32-bit pointer keys
		][
			do-node-cycle
		]
		mark-block root
		#if debug? = yes [if verbose > 1 [probe "marking symbol table"]]
		p: as int-ptr! symbol/table
		_hashtable/mark as ptr-ptr! :p			;-- will mark symbols
		symbol/table: as node! p
		#if debug? = yes [if verbose > 1 [probe "marking ownership table"]]
		p: as int-ptr! ownership/table
		_hashtable/mark as ptr-ptr! :p
		ownership/table: as node! p

		#if debug? = yes [if verbose > 1 [probe "marking stack"]]
		keep :arg-stk/node
		keep :call-stk/node
		mark-values stack/bottom stack/top
		
		#if debug? = yes [if verbose > 1 [probe "marking globals"]]
		mark-context as int-ptr! :global-ctx
		if HANDLE?(interpreter/near/node) [mark-block interpreter/near]
		lexer/mark-buffers
		mark-block-node :references/list/node
		
		#if debug? = yes [if verbose > 1 [probe "marking globals from optional modules"]]
		marker: ext-markers
		while [marker < ext-top][
			if marker/value <> null [					;-- check if not unregistered
				cb: as function! [] marker/value
				cb
			]
			marker: marker + 1
		]
		
		#if debug? = yes [if verbose > 1 [probe "scanning native stack"]]
		frames-list/rebuild								;-- refresh nodes and series frames list
		scan-stack-refs yes
		if refs <> null [cycles/refresh]
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
		if any [not active? running?][exit]
		do-mark-sweep
	]
	
	register: func [
		cb [int-ptr!]
		/local p [ptr-ptr!]
	][
		p: ext-markers
		while [p < ext-top][
			if p/value = null [
				p/value: cb
				exit
			]
			p: p + 1
		]
		if ext-top >= (ext-markers + ext-size) [
			fire [TO_ERROR(internal no-memory)]
		]
		ext-top/value: cb
		ext-top: ext-top + 1
	]
	
	unregister: func [cb [int-ptr!] /local p [ptr-ptr!]][
		p: ext-markers
		while [p < ext-top][
			if p/value = cb [p/value: null exit]
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
		
		messages: protect [
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
				v [int-ptr!]
				p head tail slot [node!]
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
					p: as node! p/value					;-- next free slot
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
					unless any [
						null? v
						all [(as int-ptr! head) <= v v < as int-ptr! tail]
					][
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
