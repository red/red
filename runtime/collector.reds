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
	verbose: 0
	active?: no
	
	stats: declare struct! [
		cycles [integer!]
	]
	
	ext-size: 100
	ext-markers: as int-ptr! allocate ext-size * size? int-ptr!
	ext-top: ext-markers
	
	stats/cycles: 0
	
	indent: 0
	
	in-range?: func [
		p		[int-ptr!]
		return: [logic!]
		/local
			frm  [node-frame!]
			tail [byte-ptr!]
	][
		frm: memory/n-head
		until [
			tail: (as byte-ptr! frm) + (frm/nodes * 2 * (size? pointer!) + (size? node-frame!))
			if all [(as int-ptr! frm + 1) + frm/nodes <= p p < as int-ptr! tail][
				return yes
			]
			frm: frm/next
			frm = null
		]
		no
	]

	mark-stack-nodes: func [
		/local
			top	 [int-ptr!]
			stk	 [int-ptr!]
			p	 [int-ptr!]
			s	 [series!]
	][
		top:  system/stack/top
		stk:  stk-bottom
		
		until [
			stk: stk - 1
			p: as int-ptr! stk/value
			if all [
				(as-integer p) and 3 = 0		;-- check if it's a valid int-ptr!
				p > as int-ptr! FFFFh			;-- filter out too low values
				p < as int-ptr! FFFFF000h		;-- filter out too high values
				not all [(as byte-ptr! stack/bottom) <= p p <= (as byte-ptr! stack/top)] ;-- stack region is fixed
				in-range? p
				p/value <> 0
				keep p
			][
				;probe ["node pointer on stack: " p " : " as byte-ptr! p/value]
				s: as series! p/value
				if GET_UNIT(s) = 16 [mark-values s/offset s/tail]
			]
			stk = top
		]
	]
	
	keep: func [
		node	[node!]
		return: [logic!]								;-- TRUE if newly marked, FALSE if already done
		/local
			s	  [series!]
			new?  [logic!]
			flags [integer!]
	][
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
		node [node!]
		/local
			ctx  [red-context!]
	][
		;probe "context"
		if keep node [
			ctx: TO_CTX(node)
			_hashtable/mark ctx/symbols
			unless ON_STACK?(ctx) [mark-block-node ctx/values]
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
			image	[red-image!]
			len		[integer!]
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
							mark-block-node word/ctx
						][
							mark-context word/ctx
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

						if TYPE_OF(value) = TYPE_PATH [
							path: as red-path! value
							if path/args <> null [
								;probe "path/args"
								mark-block-node path/args
							]
						]
					]
				]
				TYPE_SYMBOL [
					series: as red-series! value
					keep as node! series/extra
					if series/node <> null [keep series/node]
				]
				TYPE_ANY_STRING [
					#if debug? = yes [if verbose > 1 [print as-c-string string/rs-head as red-string! value]]
					series: as red-series! value
					keep series/node
					if series/extra <> 0 [keep as node! series/extra]
				]
				TYPE_BINARY
				TYPE_VECTOR
				TYPE_BITSET [
					;probe ["bitset, type: " TYPE_OF(value)]
					series: as red-series! value
					keep series/node
				]
				TYPE_ERROR
				TYPE_PORT
				TYPE_OBJECT [
					#if debug? = yes [if verbose > 1 [print "object"]]
					obj: as red-object! value
					mark-context obj/ctx
					if obj/on-set <> null [keep obj/on-set]
				]
				TYPE_CONTEXT [
					#if debug? = yes [if verbose > 1 [print "context"]]
					ctx: as red-context! value
					;keep ctx/self
					_hashtable/mark ctx/symbols
					unless ON_STACK?(ctx) [mark-block-node ctx/values]
				]
				TYPE_HASH
				TYPE_MAP [
					#if debug? = yes [if verbose > 1 [print "hash/map"]]
					hash: as red-hash! value
					mark-block-node hash/node
					_hashtable/mark hash/table			;@@ check if previously marked
				]
				TYPE_FUNCTION [
					fun: as red-function! value
					mark-context fun/ctx
					#if debug? = yes [if verbose > 1 [print "function"]]
					mark-block-node fun/spec
					mark-block-node fun/more
				]
				TYPE_ROUTINE [
					routine: as red-routine! value
					;mark-block-node routine/symbols	;-- unused for now
					#if debug? = yes [if verbose > 1 [print "routine"]]
					mark-block-node routine/spec
					mark-block-node routine/more
				]
				TYPE_ACTION
				TYPE_NATIVE
				TYPE_OP [
					native: as red-native! value
					if native/args <> null [
						#if debug? = yes [if verbose > 1 [print "native"]]
						mark-block-node native/args
					]
					if native/spec <> null [			;@@ should not happen!
						#if debug? = yes [if verbose > 1 [print "native"]]
						mark-block-node native/spec
					]
					if native/header and body-flag <> 0 [
						#if debug? = yes [if verbose > 1 [print "op/code"]]
						mark-block-node as node! native/code
					]
				]
				#if any [OS = 'macOS OS = 'Linux OS = 'Windows][
				TYPE_IMAGE [
					image: as red-image! value
					#if draw-engine <> 'GDI+ [if image/node <> null [keep image/node]]
				]]
				default [0]
			]
			value: value + 1
		]
		#if debug? = yes [if verbose > 1 [indent: indent - 1]]
	]
	
	mark-block-node: func [
		node [node!]
		/local
			s [series!]
	][
		if keep node [
			s: as series! node/value
			mark-values s/offset s/tail
		]
	]
	
	mark-block: func [
		blk [red-block!]
		/local
			s [series!]
	][
		if keep blk/node [
			s: GET_BUFFER(blk)
			mark-values s/offset s/tail
		]
	]
	
	do-mark-sweep: func [
		/local
			s		[series!]
			p		[int-ptr!]
			obj		[red-object!]
			w		[red-word!]
		#if debug? = yes [
			file	[c-string!]
			saved	[integer!]
			buf		[c-string!]
			tm tm1	[float!]
		]
			cb
	][
		#if debug? = yes [if verbose > 1 [
			#if OS = 'Windows [platform/dos-console?: no]
			file: "                      "
			sprintf [file "live-values-%d.log" stats/cycles]
			saved: stdout
			stdout: simple-io/open-file file simple-io/RIO_APPEND no
		]]

		#if debug? = yes [
			if verbose > 2 [stack-trace]
			buf: "                                                               "
			tm: platform/get-time yes yes
			print [
				"root: " block/rs-length? root "/" ***-root-size
				", runs: " stats/cycles
				", mem: " 	memory-info null 1
			]
			if verbose > 1 [probe "^/marking..."]
		]

		mark-block root
		#if debug? = yes [if verbose > 1 [probe "marking symbol table"]]
		_hashtable/mark symbol/table					;-- will mark symbols
		#if debug? = yes [if verbose > 1 [probe "marking ownership table"]]
		_hashtable/mark ownership/table

		#if debug? = yes [if verbose > 1 [probe "marking stack"]]
		keep arg-stk/node
		keep call-stk/node
		mark-values stack/bottom stack/top
		
		#if debug? = yes [if verbose > 1 [probe "marking globals"]]
		keep case-folding/upper-to-lower/node
		keep case-folding/lower-to-upper/node
		lexer/mark-buffers

		#if debug? = yes [if verbose > 1 [probe "marking path parent"]]
		obj: object/path-parent
		if TYPE_OF(obj) = TYPE_OBJECT [
			mark-context obj/ctx
			if obj/on-set <> null [keep obj/on-set]
		]
		w: object/field-parent
		if TYPE_OF(w) = TYPE_WORD [
			if w/ctx <> null [
				;print-symbol w
				;print "^/"
				either w/symbol = words/self [
					;probe "self"
					mark-block-node w/ctx
				][
					mark-context w/ctx
				]
			]
		]
		
		#if debug? = yes [if verbose > 1 [probe "marking globals from optional modules"]]
		p: ext-markers
		while [p < ext-top][
			if p/value <> 0 [							;-- check if not unregistered
				cb: as function! [] p/value
				cb
			]
			p: p + 1
		]
		
		#if debug? = yes [if verbose > 1 [probe "marking nodes on native stack"]]
		mark-stack-nodes

		#if debug? = yes [tm1: (platform/get-time yes yes) - tm]	;-- marking time

		#if debug? = yes [if verbose > 1 [probe "sweeping..."]]
		_hashtable/sweep ownership/table
		collect-frames COLLECTOR_RELEASE

		;-- unmark fixed series
		unmark root/node
		unmark arg-stk/node
		unmark call-stk/node
		
		stats/cycles: stats/cycles + 1
		;probe "done!"

		#if debug? = yes [
			tm: (platform/get-time yes yes) - tm - tm1
			sprintf [buf ", mark: %.1fms, sweep: %.1fms" tm1 * 1000.0 tm * 1000.0]
			probe [" => " memory-info null 1 buf]
			if verbose > 1 [
				simple-io/close-file stdout
				stdout: saved
				#if OS = 'Windows [platform/dos-console?: yes]
			]
		]
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
	
]