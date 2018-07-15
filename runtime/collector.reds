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
	
	mark-context: func [
		node [node!]
		/local
			ctx  [red-context!]
	][
		;probe "context"
		if keep node [
			ctx: TO_CTX(node)
			keep ctx/symbols
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
			s		[series!]
	][
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_WORD 
				TYPE_GET_WORD
				TYPE_SET_WORD 
				TYPE_LIT_WORD
				TYPE_REFINEMENT [
					word: as red-word! value
					if word/ctx <> null [
						;print-symbol word
						;print "^/"
						either word/symbol = words/self [
							;probe "self"
							mark-block-node word/ctx
						][
							mark-context word/ctx
						]
					]
				]
				TYPE_BLOCK
				TYPE_PAREN
				TYPE_PATH
				TYPE_LIT_PATH
				TYPE_GET_PATH
				TYPE_SET_PATH [
					series: as red-series! value
					if series/node <> null [			;-- can happen in routine
						;probe ["any-block, type: " TYPE_OF(value)]
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
				TYPE_SYMBOL
				TYPE_STRING
				TYPE_URL 
				TYPE_FILE
				TYPE_TAG 
				TYPE_EMAIL [
					;probe ["string, type: " TYPE_OF(value)]
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
				TYPE_OBJECT [
					;probe "object"
					obj: as red-object! value
					mark-context obj/ctx
					if obj/on-set <> null [keep obj/on-set]
				]
				TYPE_CONTEXT [
					;probe "context
					ctx: as red-context! value
					;keep ctx/self
					mark-block-node ctx/symbols
					unless ON_STACK?(ctx) [mark-block-node ctx/values]
				]
				TYPE_HASH
				TYPE_MAP [
					;probe "hash"
					hash: as red-hash! value
					mark-block-node hash/node
					_hashtable/mark hash/table			;@@ check if previously marked
				]
				TYPE_FUNCTION [
					fun: as red-function! value
					mark-context fun/ctx
					;probe "function"
					mark-block-node fun/spec
					mark-block-node fun/more
				]
				TYPE_ROUTINE [
					routine: as red-routine! value
					;mark-block-node routine/symbols	;-- unused for now
					;probe "routine"
					mark-block-node routine/spec
					mark-block-node routine/more
				]
				TYPE_ACTION
				TYPE_NATIVE
				TYPE_OP [
					native: as red-native! value
					if native/args <> null [
						;probe "native"
						mark-block-node native/args
					]
					if native/spec <> null [			;@@ should not happen!
						;probe "native"
						mark-block-node native/spec
					]
				]
				default [0]
			]
			value: value + 1
		]
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
	
	do-mark-sweep: func [/local s [series!] p [int-ptr!] obj [red-object!] w [red-word!] cb][
		;probe "marking..."
probe ["root size: " block/rs-length? root ", cycles: " stats/cycles]
		mark-block root
		_hashtable/mark symbol/table					;-- will mark symbols
		_hashtable/mark ownership/table

		;probe "marking stack"
		keep arg-stk/node
		keep call-stk/node
		mark-values stack/bottom stack/top
		
		;probe "marking globals"
		keep case-folding/upper-to-lower/node
		keep case-folding/lower-to-upper/node
		
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
		
		;probe "marking globals from optional modules"
		p: ext-markers
		while [p < ext-top][
			cb: as function! [] p/value
			cb
			p: p + 1
		]
		
		;probe marking nodes on native stack
		mark-stack-nodes
		
		;probe "sweeping..."
		collect-frames
		
		stats/cycles: stats/cycles + 1
		;probe "done!"
	]
	
	do-cycle: does [
		unless active? [exit]
		do-mark-sweep
	]
	
	register: func [cb [int-ptr!]][
		assert (as-integer ext-top - ext-markers) >> 2 < ext-size
		ext-top/value: as integer! cb
		ext-top: ext-top + 1
	]
	
]