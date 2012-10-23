Red/System [
	Title:   "Red runtime debugging functions"
	Author:  "Nenad Rakocevic"
	File: 	 %debug.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
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
		/local series alt? size block count head tail
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
