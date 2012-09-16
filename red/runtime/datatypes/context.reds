Red/System [
	Title:   "Context! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %context.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

_context: context [
	verbose: 0
	
	find-word: func [
		ctx		[red-context!]
		symbol	[integer!]
		return:	[integer!]								;-- value > 0: success, value = -1: failure
		/local
			series	[series!]
			list	[red-integer!]
			end		[red-integer!]
	][
		series: as series! ctx/symbols/value
		list: as red-integer! series/offset
		end: as red-integer! series/tail
		
		while [list < end][
			if list/value = symbol [
				return (1 + as-integer list - as red-integer! series/offset) >> 4	;@@ log2(size? cell!) hardcoded
			]
			list: list + 1
		]
		-1												;-- search failed
	]

	add: func [
		ctx			[red-context!]
		word 		[red-word!]
		return:		[integer!]
		/local
			sym		[cell!]	
			value	[cell!]
			series  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/add"]]
		
		sym: alloc-tail as series! ctx/symbols/value
		copy-cell as cell! word sym
		
		value: alloc-tail as series! ctx/values/value
		value/header: TYPE_NONE
		
		series: as series! ctx/values/value
		(as-integer series/tail - series/offset) >> 4
	]

	set: func [
		word 		[red-word!]
		value		[red-value!]
		/local
			values	[series!]
			cell	[cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/set"]]
		
		if word/index = -1 [
			word/index: find-word word/ctx word/symbol
		]
		values: as series! word/ctx/values/value
		cell: values/offset + word/index
		copy-cell value cell
	]

	get: func [
		word		[red-word!]
		return:		[cell!]
		/local
			values	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/get"]]
		
		assert all [								;-- ensure word is properly bound to a context
			not null? word/ctx
			word/index > -1
		]
		values: as series! word/ctx/values/value
		values/offset + word/index
	]

	make: func [
		blk			[red-block!]					;-- storage place (at tail of block)
		slots		[integer!]						;-- max number of words in the context
		stack?		[logic!]						;-- TRUE: alloc values on stack, FALSE: alloc them from heap
		return:		[red-context!]
		/local
			cell 	[red-context!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/make"]]
		
		cell: as red-context! ALLOC_TAIL(blk)
		cell/header: TYPE_CONTEXT					;-- implicit reset of all header flags	
		cell/symbols: alloc-series slots 2 0		;-- force offset at head of buffer

		either stack? [
			cell/values: null						;TBD: complete this code branch
		][
			cell/values: alloc-cells slots
		]
		cell
	]
	
	;-- Actions -- 
	
	datatype/register [
		TYPE_CONTEXT
		;-- General actions --
		null			;make
		null			;random
		null			;reflect
		null			;to
		null			;form
		null			;mold
		null			;get-path
		null			;set-path
		;-- Scalar actions --
		null			;absolute
		null			;add
		null			;divide
		null			;multiply
		null			;negate
		null			;power
		null			;remainder
		null			;round
		null			;subtract
		null			;even?
		null			;odd?
		;-- Bitwise actions --
		null			;and~
		null			;complement
		null			;or~
		null			;xor~
		;-- Series actions --
		null			;append
		null			;at
		null			;back
		null			;change
		null			;clear
		null			;copy
		null			;find
		null			;head
		null			;head?
		null			;index-of
		null			;insert
		null			;length-of
		null			;next
		null			;pick
		null			;poke
		null			;remove
		null			;reverse
		null			;select
		null			;sort
		null			;skip
		null			;swap
		null			;tail
		null			;tail?
		null			;take
		null			;trim
		;-- I/O actions --
		null			;create
		null			;close
		null			;delete
		null			;modify
		null			;open
		null			;open?
		null			;query
		null			;read
		null			;rename
		null			;update	
		null			;write
	]
]