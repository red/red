Red/System [
	Title:   "Context! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %context.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

_context: context [
	verbose: 0
	
	find-word: func [
		ctx		[red-context!]
		sym		[integer!]
		return:	[integer!]								;-- value > 0: success, value = -1: failure
		/local
			series	[series!]
			list	[red-word!]
			end		[red-word!]
	][
		series: as series! ctx/symbols/value
		list:   as red-word! series/offset
		end:    as red-word! series/tail
		sym:	symbol/resolve sym
		
		while [list < end][
			if list/symbol = sym [
				return (as-integer list - as red-word! series/offset) >> 4	;@@ log2(size? cell!) hardcoded
			]
			list: list + 1
		]
		-1												;-- search failed
	]

	add: func [
		ctx		[red-context!]
		word 	[red-word!]
		return:	[integer!]
		/local
			sym	  [cell!]
			value [cell!]
			s  	  [series!]
			id	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/add"]]
		
		id: find-word ctx word/symbol
		if id <> -1 [return id]
		
		s: as series! ctx/symbols/value
		sym: alloc-tail s
		copy-cell as cell! word sym
		
		unless ON_STACK?(ctx) [
			value: alloc-tail as series! ctx/values/value
			value/header: TYPE_UNSET
		]
		
		(as-integer s/tail - s/offset) >> 4 - 1
	]
	
	set-integer: func [
		word 		[red-word!]
		value		[integer!]
		/local
			int 	[red-integer!]
			values	[series!]
			ctx		[red-context!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/set-integer"]]

		ctx: word/ctx
		
		if word/index = -1 [
			word/index: find-word ctx word/symbol
		]
		int: as red-integer! either ON_STACK?(ctx) [
			(as red-value! ctx/values) + word/index
		][
			values: as series! word/ctx/values/value
			values/offset + word/index
		]
		int/header: TYPE_INTEGER
		int/value: value
	]

	set: func [
		word 		[red-word!]
		value		[red-value!]
		return:		[red-value!]
		/local
			values	[series!]
			ctx		[red-context!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/set"]]
		
		ctx: word/ctx
		
		if word/index = -1 [
			word/index: find-word ctx word/symbol
		]
		either ON_STACK?(ctx) [
			copy-cell value (as red-value! ctx/values) + word/index
		][
			values: as series! ctx/values/value
			copy-cell value values/offset + word/index
		]
	]

	get: func [
		word	   [red-word!]
		return:	   [red-value!]
		/local
			values [series!]
			sym	   [red-symbol!]
			ctx	   [red-context!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/get"]]
		
		ctx: word/ctx
		
		if any [										;-- ensure word is properly bound to a context
			null? ctx
			word/index = -1
		][
			sym: symbol/get word/symbol
			print-line ["*** Error: word '" sym/cache " has no value"]
			halt
		]
		if null? ctx/values [
			sym: symbol/get word/symbol
			print-line ["*** Error: undefined context for word '" sym/cache]
			halt
		]
		either ON_STACK?(ctx) [
			(as red-value! ctx/values) + word/index
		][
			values: as series! ctx/values/value
			values/offset + word/index
		]
	]

	create: func [
		blk			[red-block!]						;-- storage place (at tail of block)
		slots		[integer!]							;-- max number of words in the context
		stack?		[logic!]							;-- TRUE: alloc values on stack, FALSE: alloc them from heap
		return:		[red-context!]
		/local
			cell 	[red-context!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/create"]]
		
		if zero? slots [slots: 1]
		cell: as red-context! ALLOC_TAIL(blk)
		cell/header: TYPE_CONTEXT						;-- implicit reset of all header flags	
		cell/symbols: alloc-series slots 16 0			;-- force offset at head of buffer

		either stack? [
			cell/header: TYPE_CONTEXT or flag-series-stk
			cell/values: null							;-- will be set to stack frame dynamically
		][
			cell/values: alloc-cells slots
		]
		cell
	]
	
	make: func [
		spec	[red-block!]
		stack?	[logic!]
		return:	[red-context!]
		/local
			ctx	 [red-context!]
			cell [red-value!]
			slot [red-word!]
			s	 [series!]
			type [integer!]
			i	 [integer!]
	][
		ctx: create root block/rs-length? spec stack?
		s: GET_BUFFER(spec)
		cell: s/offset
		i: 0
		
		while [cell < s/tail][
			type: TYPE_OF(cell)
			if any [									;TBD: use typeset/any-word?
				type = TYPE_WORD
				type = TYPE_GET_WORD
				type = TYPE_LIT_WORD
				type = TYPE_REFINEMENT
			][											;-- add new word to context
				slot: as red-word! alloc-tail as series! ctx/symbols/value
				copy-cell cell as red-value! slot
				slot/header: TYPE_WORD
				slot/ctx: ctx
				slot/index: i
				i: i + 1
			]
			cell: cell + 1
		]
		ctx
	]
	
	;-- Actions -- 
	
	datatype/register [
		TYPE_CONTEXT
		TYPE_VALUE
		"context!"
		;-- General actions --
		null			;make
		null			;random
		null			;reflect
		null			;to
		null			;form
		null			;mold
		null			;get-path
		null			;set-path
		null			;compare
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
		null			;index?
		null			;insert
		null			;length?
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