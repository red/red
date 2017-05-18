Red/System [
	Title:   "Word! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %word.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
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
	][
		_context/add-global-word symbol/make str yes yes
	]
	
	make-at: func [
		id		[integer!]								;-- symbol ID
		pos		[red-value!]
		return:	[red-word!]
		/local 
			cell [red-word!]
	][
		cell: as red-word! pos
		cell/header: TYPE_WORD							;-- implicit reset of all header flags
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
		
		ctx: TO_CTX(node)
		s: as series! ctx/symbols/value
		as red-word! s/offset + index
	]
	
	at: func [
		node	[node!]
		sym		[integer!]
		return: [red-word!]
		/local
			ctx	[red-context!]
			idx [integer!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/at"]]

		ctx: TO_CTX(node)
		idx: _context/find-word ctx sym no
		either idx < 0 [
			_context/add-global sym
		][
			s: as series! ctx/symbols/value
			as red-word! s/offset + idx
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
			s: as series! ctx/symbols/value
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
			values [series!]
	][
		value: stack/top - 1
		ctx: TO_CTX(node)
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
			values [series!]
	][
		value: stack/top - 1
		ctx: TO_CTX(node)
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
			values [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/set-in"]]
		
		value: stack/arguments
		ctx: TO_CTX(node)
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
	][
		s: GET_BUFFER(symbols)
		str: as red-string! stack/push s/offset + w/symbol - 1
		str/header: TYPE_STRING
		str/head: 0
		str/cache: null
		str
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
			name	[names!]
			idx		[integer!]
			buf1	[integer!]
			data	[byte-ptr!]
			cstr	[c-string!]
			len		[integer!]
			val		[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/to"]]

		switch TYPE_OF(spec) [
			TYPE_WORD
			TYPE_SET_WORD
			TYPE_GET_WORD
			TYPE_LIT_WORD
			TYPE_REFINEMENT
			TYPE_ISSUE [proto: spec]
			TYPE_STRING [
				len: 0
				val: as red-value! :len
				copy-cell spec val					;-- save spec, load-value will change it
				proto: load-value as red-string! spec
				unless any-word? TYPE_OF(proto) [fire [TO_ERROR(syntax bad-char) val]]
			]
			TYPE_CHAR [
				char: as red-char! spec
				buf1: 0
				data: as byte-ptr! :buf1
				len: unicode/cp-to-utf8 char/value data
				idx: len + 1
				data/idx: null-byte
				make-at symbol/make as c-string! data proto
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
			COMP_NOT_EQUAL [
				res: as-integer not EQUAL_WORDS?(arg1 arg2)
			]
			COMP_SAME
			COMP_STRICT_EQUAL [
				res: as-integer any [
					type <> TYPE_OF(arg1)
					arg1/symbol <> arg2/symbol
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
