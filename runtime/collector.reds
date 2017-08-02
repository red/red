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
		probe "context"
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
							probe "self"
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
						probe ["any-block, type: " TYPE_OF(value)]
						mark-block as red-block! value

						if TYPE_OF(value) = TYPE_PATH [
							path: as red-path! value
							if path/args <> null [
								probe "path/args"
								mark-block-node path/args
							]
						]
					]
				]
				TYPE_SYMBOL
				TYPE_STRING
				TYPE_URL 
				TYPE_FILE
				TYPE_VECTOR
				TYPE_BITSET [
					probe ["bitset, type: " TYPE_OF(value)]
					series: as red-series! value
					keep series/node
				]
				TYPE_OBJECT [
					probe "object"
					obj: as red-object! value
					mark-context obj/ctx
					if obj/on-set <> null [keep obj/on-set]
				]
				TYPE_HASH
				TYPE_MAP [
					probe "hash"
					hash: as red-hash! value
					keep hash/node
					_hashtable/mark hash/table			;@@ check if previously marked
				]
				TYPE_FUNCTION [
					fun: as red-function! value
					mark-context fun/ctx
					probe "function"
					mark-block-node fun/spec
					mark-block-node fun/more
				]
				TYPE_ROUTINE [
					routine: as red-routine! value
					;mark-block-node routine/symbols	;-- unused for now
					probe "routine"
					mark-block-node routine/spec
					mark-block-node routine/more
				]
				TYPE_ACTION
				TYPE_NATIVE
				TYPE_OP [
					native: as red-native! value
					if native/args <> null [
						probe "native"
						mark-block-node native/args
					]
					if native/spec <> null [			;@@ should not happen!
						probe "native"
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
	
	do-cycle: func [/local s [series!]][
		probe "marking..."
		check-frames
		
		mark-block root
		;mark-block symbols
		_hashtable/mark symbol/table		;-- will mark symbols
		_hashtable/mark ownership/table

		probe "marking stack"
		keep arg-stk/node
		keep call-stk/node
		mark-values stack/bottom stack/top - 1
		
		keep case-folding/upper-to-lower/node
		keep case-folding/lower-to-upper/node
		
		probe "sweeping..."
		collect-frames
		probe "done!"
	]
	
]