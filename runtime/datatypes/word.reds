Red/System [
	Title:   "Word! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %word.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define CHECK_UNSET(value word) [
	if TYPE_OF(value) = TYPE_UNSET [
		fire [TO_ERROR(script need-value) word]
	]
]

word: context [
	verbose: 0
	
	duplicate: func [w [red-word!] return: [red-word!]][
		assert red/boot?
		as red-word! copy-cell as red-value! w ALLOC_TAIL(root)
	]
	
	load-in: func [
		str 	[c-string!]
		blk		[red-block!]
		return:	[red-word!]
	][
		push-in symbol/make str blk
	]
	
	load: func [
		str 	[c-string!]
		return:	[red-word!]
		/local
			w	[red-word!]
	][
		w: _context/add-global-word symbol/make str yes yes
		either red/boot? [
			as red-word! copy-cell as red-value! w ALLOC_TAIL(root)
		][
			w
		]
	]
	
	make-at: func [
		id		[integer!]								;-- symbol ID
		pos		[red-value!]
		return:	[red-word!]
		/local 
			cell [red-word!]
	][
		cell: as red-word! pos
		set-type pos TYPE_WORD
		cell/ctx: 	 global-ctx
		cell/symbol: id
		cell/index:  _context/add TO_CTX(global-ctx) cell
		cell
	]
	
	box: func [
		id		[integer!]								;-- symbol ID
		return:	[red-word!]
	][
		make-at id stack/arguments
	]
	
	push-in: func [
		id		[integer!]								;-- symbol ID
		blk		[red-block!]
		return:	[red-word!]
	][
		make-at id ALLOC_TAIL(blk)
	]
	
	push*: func [
		id		[integer!]								;-- symbol ID
		return:	[red-word!]
	][
		make-at id stack/push*
	]
	
	push: func [
		word	 [red-word!]
		return:  [red-word!]
		/local
			cell [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/push"]]
		
		cell: as red-word! stack/push*
		copy-cell as cell! word as cell! cell
		cell
	]
	
	push-local: func [
		node	[node!]
		index	[integer!]
		return: [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/push-local"]]

		push from node index
	]
	
	from: func [
		node	[node!]
		index	[integer!]
		return: [red-word!]
		/local
			ctx	[red-context!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/from"]]

		_hashtable/get-ctx-word TO_CTX(node) index
	]
	
	at: func [
		node	[node!]
		sym		[integer!]
		return: [red-word!]
		/local
			ctx	[red-context!]
			idx [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/at"]]

		ctx: TO_CTX(node)
		idx: _context/find-word ctx sym no
		either idx < 0 [
			_context/add-global sym
		][
			_hashtable/get-ctx-word ctx idx
		]
	]
	
	get-in: func [
		node	[node!]
		index	[integer!]
		return: [red-value!]
		/local
			ctx	[red-context!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/get-in"]]

		ctx: TO_CTX(node)
		s: as series! ctx/values/value
		s/offset + index
	]
	
	get-local: func [
		node	[node!]
		index	[integer!]
		return: [red-value!]
		/local
			ctx	  [red-context!]
			value [red-value!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/get-local"]]

		ctx: TO_CTX(node)
		if null? ctx/values [
			s: _hashtable/get-ctx-words ctx
			fire [TO_ERROR(script not-defined) s/offset + index]
		]
		
		value: either ON_STACK?(ctx) [
			(as red-value! ctx/values) + index
		][
			s: as series! ctx/values/value
			s/offset + index
		]
		stack/push value
	]
	
	get-buffer: func [
		w		[red-word!]
		return: [red-symbol!]
	][
		symbol/get w/symbol
	]

	set: func [
		/local
			value [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/set"]]
		
		value: stack/arguments + 1
		CHECK_UNSET(value stack/arguments)
		_context/set as red-word! stack/arguments value
		stack/set-last value
	]

	replace: func [
		node	[node!]
		index	[integer!]
		/local
			ctx	   [red-context!]
			value  [red-value!]
			w	   [red-word!]
			values [series!]
	][
		value: stack/get-top
		ctx: TO_CTX(node)
		if GET_CTX_TYPE(ctx) = CONTEXT_OBJECT [
			w: _hashtable/get-ctx-word ctx index
			w/header: w/header or flag-word-dirty
		]
		values: as series! ctx/values/value
		stack/push values/offset + index
		copy-cell value values/offset + index
	]
	
	set-in-ctx: func [
		node	[node!]
		index	[integer!]
		/local
			ctx	   [red-context!]
			value  [red-value!]
			w	   [red-word!]
			values [series!]
	][
		value: stack/get-top
		ctx: TO_CTX(node)
		if GET_CTX_TYPE(ctx) = CONTEXT_OBJECT [
			w: _hashtable/get-ctx-word ctx index
			w/header: w/header or flag-word-dirty
		]
		values: as series! ctx/values/value
		copy-cell value values/offset + index
	]
	
	set-in: func [
		node	[node!]
		index	[integer!]
		return: [red-value!]
		/local
			ctx	   [red-context!]
			value  [red-value!]
			w	   [red-word!]
			values [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/set-in"]]
		
		value: stack/arguments
		ctx: TO_CTX(node)
		if GET_CTX_TYPE(ctx) = CONTEXT_OBJECT [
			w: _hashtable/get-ctx-word ctx index
			w/header: w/header or flag-word-dirty
		]		
		values: as series! ctx/values/value
		copy-cell value values/offset + index
		value
	]
	
	set-local: func [
		slot	 [red-value!]
		return:  [red-value!]
		/local
			value [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/set-local"]]
		
		value: stack/arguments
		CHECK_UNSET(value slot)
		copy-cell value slot
	]
	
	get-any: func [
		word	 [red-word!]
		return:  [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/get-any"]]

		copy-cell _context/get word stack/push*
	]
	
	get: func [
		word	 [red-word!]
		return:  [red-value!]
		/local
			value [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/get"]]
		
		value: copy-cell _context/get word stack/push*
		if TYPE_OF(value) = TYPE_UNSET [
			fire [TO_ERROR(script no-value) word]
		]
		value
	]

	as-string: func [
		w		[red-word!]
		return: [red-string!]
		/local
			s	[series!]
			str [red-string!]
			sym [red-value!]
	][
		s: GET_BUFFER(symbols)
		sym: s/offset + w/symbol - 1
		symbol/make-red-string as red-symbol! sym
		str: as red-string! stack/push sym
		str/header: TYPE_STRING
		str/head: 0
		str/cache: null
		str
	]
	
	check-1st-char: func [
		w [red-word!]
		/local
			sym [red-symbol!]
			buf	[series!]
			s   [c-string!]
			cp  [integer!]
			n	[integer!]
			c   [byte!]
	][
		n: 0
		sym: symbol/get w/symbol
		buf: as series! sym/cache/value
		cp: unicode/decode-utf8-char as c-string! buf/offset :n
		if cp > 127 [exit]
		c: as-byte cp
		
		s: {/\^^,[](){}"#%$@:;'0123465798}
		until [
			if c = s/1 [fire [TO_ERROR(syntax bad-char) w]]
			s: s + 1
			s/1 = null-byte
		]
	]

	;-- Actions --
	
	form: func [
		w		[red-word!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
		/local
			s		[series!]
			str		[red-string!]
			saved	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/form"]]
		
		s: GET_BUFFER(symbols)
		str: as red-string! s/offset + w/symbol - 1		;-- symbol! and string! structs are partial overlapping
		saved: str/head
		str/head: 0
		part: string/form str buffer arg part
		str/head: saved
		part
	]
	
	mold: func [
		w		[red-word!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/mold"]]

		form w buffer arg part
	]

	to: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return: [red-value!]
		/local
			char	[red-char!]
			dt		[red-datatype!]
			bool	[red-logic!]
			str		[red-string!]
			word	[red-word!]
			name	[names!]
			cstr	[c-string!]
			index	[integer!]
			val		[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/to"]]

		switch TYPE_OF(spec) [
			TYPE_ANY_WORD [proto: spec]
			TYPE_REFINEMENT
			TYPE_ISSUE [
				word: as red-word! spec
				if TYPE_OF(spec) = TYPE_ISSUE [check-1st-char word]
				index: _context/bind-word TO_CTX(global-ctx) word	;-- issue #4537
				assert index >= 0
				proto: spec
			]
			TYPE_STRING [
				proto: load-value as red-string! spec
				unless any-word? TYPE_OF(proto) [fire [TO_ERROR(script invalid-chars)]]
			]
			TYPE_CHAR [
				char: as red-char! spec
				str: string/make-at stack/push* 1 Latin1
				string/append-char GET_BUFFER(str) char/value
				proto: load-value str
				unless any-word? TYPE_OF(proto) [fire [TO_ERROR(script invalid-chars)]]
			]
			TYPE_DATATYPE [
				dt: as red-datatype! spec
				name: name-table + dt/value
				copy-cell as cell! name/word proto
			]
			TYPE_LOGIC [
				bool: as red-logic! spec
				cstr: either bool/value ["true"]["false"]
				make-at symbol/make cstr proto
			]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push type spec]]
		]

		proto/header: type
		proto
	]

	any-word?: func [									;@@ discard it when ANY_WORD? available
		type	[integer!]
		return: [logic!]
	][
		any [
			type = TYPE_WORD
			type = TYPE_GET_WORD
			type = TYPE_SET_WORD
			type = TYPE_LIT_WORD
			type = TYPE_REFINEMENT
			type = TYPE_ISSUE							;-- do not equal it to other word types
		]
	]
	
	compare: func [
		arg1	 [red-word!]							;-- first operand
		arg2	 [red-word!]							;-- second operand
		op		 [integer!]								;-- type of comparison
		return:	 [integer!]
		/local
			s	 [series!]
			type [integer!]
			res	 [integer!]
			str1 [red-string!]
			str2 [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/compare"]]
		
		type: TYPE_OF(arg2)
		if any [
			all [type = TYPE_ISSUE TYPE_OF(arg1) <> TYPE_ISSUE]
			not any-word? type
		][
			RETURN_COMPARE_OTHER						;@@ replace by ANY_WORD? when available
		]
		switch op [
			COMP_EQUAL
			COMP_NOT_EQUAL
			COMP_FIND [
				res: as-integer not EQUAL_WORDS?(arg1 arg2)
			]
			COMP_STRICT_EQUAL [
				res: as-integer any [
					type <> TYPE_OF(arg1)
					arg1/symbol <> arg2/symbol
				]
			]
			COMP_SAME [
				res: as-integer any [
					arg1/symbol <> arg2/symbol
					arg1/ctx    <> arg2/ctx
					type <> TYPE_OF(arg1)
				]
			]
			COMP_STRICT_EQUAL_WORD [
				either any [
					all [TYPE_OF(arg1) = TYPE_WORD type = TYPE_LIT_WORD]
					all [TYPE_OF(arg1) = TYPE_LIT_WORD type = TYPE_WORD]
				][
					res: as-integer arg1/symbol <> arg2/symbol
				][
					res: as-integer any [type <> TYPE_OF(arg1) arg1/symbol <> arg2/symbol]
				]
			]
			default [
				s: GET_BUFFER(symbols)
				str1: as red-string! s/offset + arg1/symbol - 1
				str2: as red-string! s/offset + arg2/symbol - 1
				res: string/equal? str1 str2 op no
			]
		]
		res
	]
	
	index?: func [
		return: [red-value!]
		/local
			w	  [red-word!]
			int	  [red-integer!]
			index [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/index?"]]

		w: as red-word! stack/arguments
		int: as red-integer! w
		index: w/index
	
		either index = -1 [int/header: TYPE_NONE][
			int/header: TYPE_INTEGER
			int/value:  index + 1						;-- return a 1-based value
		]
		as red-value! int
	]

	init: does [
		datatype/register [
			TYPE_WORD
			TYPE_SYMBOL
			"word!"
			;-- General actions --
			:to				;make
			null			;random
			null			;reflect
			:to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
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
			:index?
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
