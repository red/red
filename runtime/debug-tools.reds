Red/System [
	Title:   "Red runtime debugging functions"
	Author:  "Nenad Rakocevic"
	File: 	 %debug-tools.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

print-symbol: func [
	word [red-word!]
	/local
		sym [red-symbol!]
][
	sym: symbol/get word/symbol
	print sym/cache
]

;-------------------------------------------
;-- Memory stats
;-------------------------------------------
memory-info: func [
	blk		[red-block!]
	verbose [integer!]						;-- stat verbosity level (1, 2 or 3)
	/local
		n-frame s-frame b-frame free-nodes base list nodes series bigs
][
	assert all [1 <= verbose verbose <= 3]

;-- Node frames stats --
	nodes: block/make-in blk 8
	n-frame: memory/n-head

	while [n-frame <> null][
		if verbose >= 2 [
			free-nodes: (as-integer (n-frame/top - n-frame/bottom) + 1) / 4
			list: block/make-in nodes 8
			integer/make-in list n-frame/nodes - free-nodes
			integer/make-in list free-nodes
			integer/make-in list n-frame/nodes
		]
		n-frame: n-frame/next
	]

;-- Series frames stats --
	series: block/make-in blk 8
	s-frame: memory/s-head

	while [s-frame <> null][
		if verbose >= 2 [
			base: (as byte-ptr! s-frame) + size? series-frame!
			list: block/make-in series 8
			integer/make-in list as-integer s-frame/tail - as byte-ptr! s-frame/heap
			integer/make-in list as-integer (as byte-ptr! s-frame/heap) - base
			integer/make-in list  as-integer s-frame/tail - base
		]
		s-frame: s-frame/next
	]

;-- Big frames stats --
	bigs: block/make-in blk 8
	b-frame: memory/b-head

	while [b-frame <> null][
		if verbose >= 2 [
			integer/make-in bigs b-frame/size
		]
		b-frame: b-frame/next
	]
]

;===========================================
;== Debugging functions
;===========================================

#if debug? = yes [

	dump-globals: func [
		/local ctx sym-table val-table len s symbol value w sym val syms i
	][
		ctx: TO_CTX(global-ctx)
		sym-table: ctx/symbols
		val-table: ctx/values
		
		s: as series! sym-table/value
		len: (as-integer s/tail - s/offset) >> 4 + 1
		symbol: s/offset
		
		s: as series! val-table/value
		value: s/offset
		
		s: GET_BUFFER(symbols)
		syms: as red-symbol! s/offset
		
		print-line "Global Context"
		print-line "--------------"
		i: 0
		until [
			w: as red-word! symbol + i
			sym: syms + w/symbol - 1
			val: value + i	
			print-line [i ", " w/symbol "/" sym/alias ": " sym/cache "^- : " TYPE_OF(val)]
			i: i + 1
			i + 1 = len
		]
	]
	
	dump-symbols: func [
		/local tail s i sym
	][
		s: GET_BUFFER(symbols)
		sym: as red-symbol! s/offset
		tail: as red-symbol! s/tail

		print-line "Symbol Table"
		print-line "--------------"
		i: 0
		until [
			print-line [i "/" sym/alias ": " sym/cache]
			sym: sym + 1
			i: i + 1
			sym = tail
		]
	]


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
		/local series size count head tail
	][
		count: 1
		series: as series-buffer! (as byte-ptr! frame) + size? series-frame!
		until [
			head: as-integer ((as byte-ptr! series/offset) - (as byte-ptr! series) - size? series-buffer!)
			tail: as-integer ((as byte-ptr! series/tail) - (as byte-ptr! series) - size? series-buffer!)
			print [
				" - " series
				": size = "	series/size
				", offset pos = " head ", tail pos = " tail
				"    "
			]
			if series/flags and flag-ins-head <> 0 [print "H"]
			if series/flags and flag-ins-tail <> 0 [print "T"]
			print lf
			count: count + 1

			series: as series-buffer! (as byte-ptr! series) + series/size + size? series-buffer!
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
			
			size: series/size / 16
			until [
				print block
				size: size - 1
				zero? size
			]
			
			series: as series-buffer! (as byte-ptr! series) + series/size + size? series-buffer!
			series >= frame/heap
		]
		assert series = frame/heap
		print lf
	]
	
]
