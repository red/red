Red/System [
	Title:   "Context! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %context.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

_context: context [
	verbose: 0
	
	find-word: func [
		ctx		[red-context!]
		sym		[integer!]
		case?	[logic!]
		return:	[integer!]		;-- value > 0: success, value = -1: failure
	][
		_hashtable/get-ctx-symbol ctx/symbols sym case? null null
	]

	find-or-store: func [		;-- find a symbol, if not found, store it.
		ctx		[red-context!]
		sym		[integer!]
		case?	[logic!]
		w-ctx	[node!]			;-- word/ctx
		new-id	[int-ptr!]
		return:	[integer!]		;-- word index in the context
	][
		_hashtable/get-ctx-symbol ctx/symbols sym case? w-ctx new-id
	]
	
	get-any: func [
		symbol  [integer!]
		node	[node!]
		return:	[red-value!]
		/local
			ctx	   [red-context!]
			values [series!]
			index  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/get-any"]]

		ctx: TO_CTX(node)
		if ON_STACK?(ctx) [ctx: TO_CTX(global-ctx)]
		values: as series! ctx/values/value
		index: find-word ctx symbol yes
		assert index <> -1
		values/offset + index
	]

	set-global: func [
		symbol	[integer!]
		value	[red-value!]
		return:	[red-value!]
		/local
			ctx	   [red-context!]
			word   [red-word!]
			values [series!]
			idx	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/set-global"]]

		ctx: TO_CTX(global-ctx)
		idx: find-word ctx symbol no
		if idx = -1 [
			word: add-global symbol
			idx: word/index
		]
		values: as series! ctx/values/value
		copy-cell value values/offset + idx
	]
	
	get-global: func [
		symbol  [integer!]
		return:	[red-value!]
		/local
			ctx	   [red-context!]
			values [series!]
			index  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/get-global"]]

		ctx: TO_CTX(global-ctx)
		values: as series! ctx/values/value
		index: find-word ctx symbol yes
		assert index <> -1
		values/offset + index
	]
	
	add-global: func [
		sym		[integer!]
		return: [red-word!]
		/local
			w	[red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/add-global"]]
		
		w: add-global-word sym no yes
		either red/boot? [
			as red-word! copy-cell as red-value! w ALLOC_TAIL(root)
		][
			w
		]
	]
	
	add-global-word: func [
		sym		[integer!]
		case?	[logic!]
		store?	[logic!]
		return: [red-word!]
		/local
			ctx	  [red-context!]
			word  [red-word!]
			value [cell!]
			s  	  [series!]
			id	  [integer!]
			new-id [integer!]
	][
		new-id: 0
		ctx: TO_CTX(global-ctx)
		id: find-or-store ctx sym case? global-ctx :new-id

		if id <> -1 [
			word: _hashtable/get-ctx-word ctx id
			if all [case? store? word/symbol <> sym][
				word: as red-word! copy-cell as red-value! word ALLOC_TAIL(root)
				word/symbol: sym
			]
			return word
		]

		word: _hashtable/get-ctx-word ctx new-id
		if positive? symbol/get-alias-id sym [	;-- alias, fetch original id
			word/index: find-word ctx sym yes
		]

		value: alloc-tail as series! ctx/values/value
		value/header: TYPE_UNSET
		word
	]

	add-and-set: func [
		ctx		[red-context!]
		word	[red-word!]
		value	[red-value!]
		return: [red-value!]
		/local
			id		[integer!]
			new-id	[integer!]
			s		[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/add-and-set"]]

		new-id: 0
		id: find-or-store ctx word/symbol yes ctx/self :new-id
		either id = -1 [
			copy-cell value alloc-tail as series! ctx/values/value
		][
			s: as series! ctx/values/value
			copy-cell value s/offset + id
		]
	]
	
	add-with: func [
		ctx		[red-context!]
		word	[red-word!]
		value	[red-value!]
		return: [red-value!]
		/local
			id		[integer!]
			new-id	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/add-with"]]

		new-id: 0
		id: find-or-store ctx word/symbol yes ctx/self :new-id
		if id <> -1 [return null]
		copy-cell value alloc-tail as series! ctx/values/value
	]

	add: func [
		ctx		[red-context!]
		word 	[red-word!]
		return:	[integer!]
		/local
			id		[integer!]
			new-id	[integer!]
			value	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/add"]]

		new-id: 0
		id: find-or-store ctx word/symbol yes word/ctx :new-id
		if id <> -1 [return id]

		unless ON_STACK?(ctx) [
			value: alloc-tail as series! ctx/values/value
			value/header: TYPE_UNSET
		]
		new-id
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
		word 	[red-word!]
		value	[red-value!]
		ctx		[red-context!]
		event?	[logic!]								;-- TRUE: trigger object events
		return:	[red-value!]
		/local
			values	[series!]
			obj		[red-object!]
			slot	[red-value!]
			old		[red-value!]
			saved	[red-value!]
			w		[red-word!]
			s		[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/set-in"]]
		
		if word/index = -1 [
			word/index: find-word ctx word/symbol no
			if word/index = -1 [add ctx word]
		]
		if null? ctx/values [
			fire [TO_ERROR(script not-defined) word]
		]
		either ON_STACK?(ctx) [
			copy-cell value (as red-value! ctx/values) + word/index
		][
			values: as series! ctx/values/value
			slot: values/offset + word/index
			
			if GET_CTX_TYPE(ctx) = CONTEXT_OBJECT [
				w: _hashtable/get-ctx-word ctx word/index
				w/header: w/header or flag-word-dirty
				
				if event? [
					s: as series! ctx/self/value
					obj: as red-object! s/offset + 1
					assert TYPE_OF(obj) = TYPE_OBJECT
					
					if obj/on-set <> null [
						saved: stack/top
						old: stack/push slot
						word: as red-word! word
						copy-cell value slot
						object/fire-on-set obj word old value
						stack/top: saved
						return slot
					]
				]
			]
			copy-cell value slot
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
		set-in word value TO_CTX(node) yes
	]
	
	get-in: func [
		word	   [red-word!]
		ctx	   	   [red-context!]
		return:	   [red-value!]
		/local
			values [series!]
			s	   [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/get-in"]]

		if all [
			TYPE_OF(ctx) = TYPE_OBJECT					;-- test special ctx pointer for SELF
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
	
	clone-words: func [		;-- clone a context. only copy words, without values
		slot	[red-block!]
		type	[context-type!]
		return: [node!]
		/local
			obj		[red-object!]
			node	[node!]
			sym		[red-word!]
			ctx		[red-context!]
			new		[node!]
			src		[series!]
			dst		[series!]
			slots	[integer!]
	][
		assert TYPE_OF(slot) = TYPE_OBJECT
		obj: as red-object! slot
		node: obj/ctx
		ctx: TO_CTX(node)
		src: _hashtable/get-ctx-words ctx
		slots: (as-integer (src/tail - src/offset)) >> 4
		
		new: create 
			slots
			ctx/header and flag-series-stk <> 0
			ctx/header and flag-self-mask  <> 0
			ctx
			type

		sym: as red-word! _hashtable/get-ctx-word TO_CTX(new) 0
		loop slots [
			sym/ctx: new
			sym: sym + 1
		]

		obj/ctx: new
		new
	]

	create: func [
		slots	[integer!]							;-- max number of words in the context
		stack?	[logic!]							;-- TRUE: alloc values on stack, FALSE: alloc them from heap
		self?	[logic!]
		proto	[red-context!]						;-- if proto <> null, copy all the words in the proto context
		type	[context-type!]
		return:	[node!]
		/local
			cell [red-context!]
			slot [red-value!]
			node [node!]
			vals [node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_context/create"]]
		
		if zero? slots [slots: 1]
		node: alloc-cells 2
		cell: as red-context! alloc-tail as series! node/value
		slot: alloc-tail as series! node/value			;-- allocate a slot for obj/func back-reference
		slot/header: TYPE_UNSET
		cell/header: TYPE_UNSET							;-- implicit reset of all header flags	
		cell/self: node

		either stack? [
			cell/values: null							;-- will be set to stack frame dynamically
			cell/symbols: _hashtable/init slots as red-block! proto HASH_TABLE_SYMBOL HASH_SYMBOL_CONTEXT
			cell/header: TYPE_CONTEXT or flag-series-stk
		][
			vals: alloc-unset-cells slots	;@@ keep it on native stack, so it can be marked by the GC
			cell/symbols: _hashtable/init slots as red-block! proto HASH_TABLE_SYMBOL HASH_SYMBOL_CONTEXT
			cell/values: vals
			cell/header: TYPE_CONTEXT
		]
		SET_CTX_TYPE(cell type)
		if self? [cell/header: cell/header or flag-self-mask]
		node
	]
	
	make: func [
		spec	[red-block!]
		stack?	[logic!]
		self?	[logic!]
		kind	[context-type!]
		return:	[node!]
		/local
			new		[node!]
			ctx		[red-context!]
			cell	[red-value!]
			end		[red-value!]
			w		[red-word!]
			s		[series!]
			type	[integer!]
			i		[integer!]
	][
		new: create block/rs-length? spec stack? self? null kind
		ctx: TO_CTX(new)
		s: GET_BUFFER(spec)
		cell: s/offset
		end: s/tail

		i: 0
		while [cell < end][
			type: TYPE_OF(cell)
			if any [									;TBD: use typeset/any-word?
				type = TYPE_WORD
				type = TYPE_GET_WORD
				type = TYPE_LIT_WORD
				type = TYPE_REFINEMENT
			][											;-- add new word to context
				w: as red-word! cell
				find-or-store ctx w/symbol yes new :type
				i: i + 1
			]
			cell: cell + 1
		]

		unless stack? [
			s: as series! ctx/values/value
			s/tail: s/offset + i
		]

		new
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
	][
		if cycles/find? body/node [return body]
		cycles/push body/node
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
				TYPE_ANY_BLOCK	[
					bind as red-block! value ctx obj self?
				]
				default [0]
			]
			value: value + 1
		]
		cycles/pop
		body
	]
	
	collect-set-words: func [
		ctx	 	[red-context!]
		spec 	[red-block!]
		return: [logic!]
		/local
			cell [red-value!]
			tail [red-value!]
			base [red-value!]
			s	 [series!]
	][
		s: GET_BUFFER(spec)
		cell: s/offset + spec/head
		tail: s/tail
		assert cell <= tail
		
		s: _hashtable/get-ctx-words ctx
		base: s/tail - s/offset

		while [cell < tail][
			if TYPE_OF(cell) = TYPE_SET_WORD [
				add ctx as red-word! cell
			]
			cell: cell + 1
		]
		s: _hashtable/get-ctx-words ctx					;-- refresh s after possible expansion
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
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
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