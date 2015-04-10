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
		case?	[logic!]
		return:	[integer!]								;-- value > 0: success, value = -1: failure
		/local
			series	[series!]
			list	[red-word!]
			end		[red-word!]
	][
		series: as series! ctx/symbols/value
		list:   as red-word! series/offset
		end:    as red-word! series/tail
		
		either case? [
			sym: symbol/resolve sym
			while [list < end][
				if sym = symbol/resolve list/symbol [
					return (as-integer list - as red-word! series/offset) >> 4	;@@ log2(size? cell!) hardcoded
				]
				list: list + 1
			]
		][
			while [list < end][
				if sym = list/symbol [
					return (as-integer list - as red-word! series/offset) >> 4	;@@ log2(size? cell!) hardcoded
				]
				list: list + 1
			]
		]
		-1												;-- search failed
	]
	
	add-global: func [
		symbol	[integer!]
		return: [red-word!]
		/local
			ctx	  [red-context!]
			word  [red-word!]
			value [cell!]
			s  	  [series!]
			id	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/add-global"]]

		ctx: TO_CTX(global-ctx)
		id: find-word ctx symbol no
		s: as series! ctx/symbols/value
		
		if id <> -1 [return as red-word! s/offset + id]	;-- word already defined in global context
		
		s: as series! ctx/symbols/value
		id: (as-integer s/tail - s/offset) >> 4			;-- index is zero-base
		word: as red-word! alloc-tail s

		word/header: TYPE_WORD							;-- implicit reset of all header flags
		word/ctx: 	 global-ctx
		word/symbol: symbol
		word/index:  id

		value: alloc-tail as series! ctx/values/value
		value/header: TYPE_UNSET
		word
	]
	
	add-with: func [
		ctx		[red-context!]
		word	[red-word!]
		value	[red-value!]
		return: [red-value!]
		/local
			w	[red-word!]
			s  	[series!]
			id	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/add-with"]]

		id: find-word ctx word/symbol yes
		if id <> -1 [return null]

		s: as series! ctx/symbols/value
		id: (as-integer s/tail - s/offset) >> 4			;-- index is zero-base
		w: as red-word! alloc-tail s
		copy-cell as cell! word as cell! w
		w/ctx: ctx/self
		w/index: id
		
		s: as series! ctx/symbols/value					;-- refreshing pointer after alloc-tail
		copy-cell value alloc-tail as series! ctx/values/value
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
		
		id: find-word ctx word/symbol yes
		if id <> -1 [return id]
		
		s: as series! ctx/symbols/value
		id: (as-integer s/tail - s/offset) >> 4			;-- index is zero-base

		sym: alloc-tail s
		copy-cell as cell! word sym
		sym/header: TYPE_WORD							;-- force word! type
		word: as red-word! sym
		word/index: id
		
		unless ON_STACK?(ctx) [
			value: alloc-tail as series! ctx/values/value
			value/header: TYPE_UNSET
		]
		id
	]
	
	set-integer: func [
		word 	[red-word!]
		value	[integer!]
		return:	[integer!]
		/local
			node	[node!]
			int 	[red-integer!]
			values	[series!]
			ctx		[red-context!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/set-integer"]]

		node: word/ctx
		ctx: TO_CTX(node)
		
		if word/index = -1 [
			word/index: find-word ctx word/symbol no
		]
		int: as red-integer! either ON_STACK?(ctx) [
			(as red-value! ctx/values) + word/index
		][
			values: as series! ctx/values/value
			values/offset + word/index
		]
		int/header: TYPE_INTEGER
		int/value: value
		value
	]

	set-in: func [
		word 		[red-word!]
		value		[red-value!]
		ctx			[red-context!]
		return:		[red-value!]
		/local
			values	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/set-in"]]
		
		if word/index = -1 [
			word/index: find-word ctx word/symbol no
			if word/index = -1 [add ctx word]
		]
		either ON_STACK?(ctx) [
			copy-cell value (as red-value! ctx/values) + word/index
		][
			values: as series! ctx/values/value
			copy-cell value values/offset + word/index
		]
	]
	
	set: func [
		word	[red-word!]
		value	[red-value!]
		return:	[red-value!]
		/local
			node [node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/set"]]

		node: word/ctx
		set-in word value TO_CTX(node)
	]
	
	get-in: func [
		word	   [red-word!]
		ctx	   	   [red-context!]
		return:	   [red-value!]
		/local
			values [series!]
			sym	   [red-symbol!]
			s	   [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/get-with"]]

		if all [
			ctx/header and flag-self-mask <> 0			;-- test if context handles SELF
			word/index = -1
			word/symbol = words/self
		][
			s: as series! word/ctx/value
			return s/offset								;-- return original object value
		]
		if any [										;-- ensure word is properly bound to a context
			null? ctx
			word/index = -1
		][
			fire [TO_ERROR(script no-value) word]
		]
		if null? ctx/values [
			fire [TO_ERROR(script not-in-context) word]
		]
		either ON_STACK?(ctx) [
			(as red-value! ctx/values) + word/index
		][
			values: as series! ctx/values/value
			values/offset + word/index
		]
	]

	get: func [
		word	[red-word!]
		return:	[red-value!]
		/local
			node [node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/get"]]
		
		node: word/ctx
		get-in word TO_CTX(node)
	]

	create: func [
		slots		[integer!]							;-- max number of words in the context
		stack?		[logic!]							;-- TRUE: alloc values on stack, FALSE: alloc them from heap
		self?		[logic!]
		return:		[node!]
		/local
			cell 	[red-context!]
			node	[node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/create"]]
		
		if zero? slots [slots: 1]
		node: alloc-cells 1
		cell: as red-context! alloc-tail as series! node/value
		cell/header: TYPE_CONTEXT						;-- implicit reset of all header flags	
		cell/symbols: alloc-series slots 16 0			;-- force offset at head of buffer
		cell/self: node
		
		if self? [cell/header: cell/header or set-self-mask]

		either stack? [
			cell/header: TYPE_CONTEXT or flag-series-stk
			cell/values: null							;-- will be set to stack frame dynamically
		][
			cell/values: alloc-cleared-cells slots
		]
		node
	]
	
	make: func [
		spec	[red-block!]
		stack?	[logic!]
		self?	[logic!]
		return:	[node!]
		/local
			new		[node!]
			symbols	[node!]
			ctx		[red-context!]
			cell	[red-value!]
			slot	[red-word!]
			s		[series!]
			type	[integer!]
			i		[integer!]
	][
		new: create block/rs-length? spec stack? self?
		ctx: TO_CTX(new)
		symbols: ctx/symbols
		
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
				slot: as red-word! alloc-tail as series! symbols/value
				copy-cell cell as red-value! slot
				slot/header: TYPE_WORD
				slot/ctx: new
				slot/index: i
				i: i + 1
			]
			cell: cell + 1
		]
		new
	]
	
	get-words: func [
		/local
			blk	[red-block!]
			ctx [red-context!]
	][
		ctx: TO_CTX(global-ctx)
		blk: as red-block! stack/push*
		blk/header: TYPE_BLOCK
		blk/head: 	0
		blk/node: 	ctx/symbols 
		
		copy-cell 										;-- reposition cloned block at right place
			as red-value! block/clone blk no
			as red-value! blk
	]
	
	bind-word: func [
		ctx		[red-context!]
		word	[red-word!]
		return:	[integer!]
		/local
			idx [integer!]
	][
		idx: find-word ctx word/symbol yes
		if idx >= 0 [
			word/ctx: ctx/self
			word/index: idx
		]
		idx
	]
	
	bind: func [
		body	[red-block!]
		ctx		[red-context!]
		obj		[node!]									;-- required by SELF
		self?	[logic!]
		return: [red-block!]
		/local
			value [red-value!]
			end	  [red-value!]
			w	  [red-word!]
			type  [integer!]
	][
		value: block/rs-head body
		end:   block/rs-tail body

		while [value < end][
			switch TYPE_OF(value) [	
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_SET_WORD
				TYPE_LIT_WORD
				TYPE_REFINEMENT [
					w: as red-word! value
					either all [						;-- special processing of SELF word	
						self?
						TYPE_OF(value) = TYPE_WORD
						w/symbol = words/self
					][			
						w/ctx: obj						;-- make SELF refer to the original object
						w/index: -1						;-- make it fail if resolved out of context
					][
						bind-word ctx w
					]
				]
				TYPE_BLOCK 								;@@ replace with TYPE_ANY_BLOCK
				TYPE_PAREN
				TYPE_PATH
				TYPE_LIT_PATH
				TYPE_SET_PATH
				TYPE_GET_PATH	[
					bind as red-block! value ctx obj self?
				]
				default [0]
			]
			value: value + 1
		]
		body
	]
	
	set-context-each: func [
		s	 [series!]
		node [node!]
		/local
			p	 [red-word!]
			tail [red-word!]
	][
		p:	  as red-word! s/offset 
		tail: as red-word! s/tail

		while [p < tail][
			p/ctx: node
			p: p + 1
		]
	]
	
	collect-set-words: func [
		ctx	 	[red-context!]
		spec 	[red-block!]
		return: [logic!]
		/local
			cell [red-value!]
			tail [red-value!]
			base [red-value!]
			word [red-word!]
			s	 [series!]	
	][
		s: GET_BUFFER(spec)
		cell: s/offset
		tail: s/tail
		
		s: as series! ctx/symbols/value
		base: s/tail - s/offset

		while [cell < tail][
			if TYPE_OF(cell) = TYPE_SET_WORD [
				add ctx as red-word! cell
			]
			cell: cell + 1
		]
		s/tail - s/offset > base						;-- TRUE: new words added
	]
	
	;-- Actions -- 
	
	init: does [
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
			null			;eval-path
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
]