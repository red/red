Red/System [
	Title:   "Symbol! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %symbol.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

symbol: context [
	verbose: 0
	table: declare node!
	
	is-any-type?: func [
		word	[red-word!]
		return: [logic!]
	][
		assert TYPE_OF(word) = TYPE_WORD
		(symbol/resolve word/symbol) = symbol/resolve words/any-type!
	]
	
	search: func [
		str 	  [red-string!]
		return:	  [integer!]
		/local
			s		 [series!]
			id		 [integer!]
			aliased? [logic!]
			key		 [red-value!]
	][
		aliased?: no

		key: _hashtable/get table as red-value! str 0 1 yes no no
		if key = null [
			key: _hashtable/get table as red-value! str 0 1 no no no	
			aliased?: yes
		]

		id: either key = null [0][
			s: GET_BUFFER(symbols)
			(as-integer key - s/offset) >> 4 + 1
		]
		if aliased? [id: 0 - id]
		id
	]
	
	duplicate: func [
		src		 [c-string!]
		return:  [c-string!]
		/local
			node [node!]
			dst  [c-string!]
			s	 [series!]
			len	 [integer!]
	][
		len: length? src
		node: alloc-bytes len							;@@ TBD: mark this buffer as protected!
		s: as series! node/value
		dst: as c-string! s/offset
		
		copy-memory as byte-ptr! dst as byte-ptr! src len
		dst
	]
	
	make-alt: func [
		str 	[red-string!]
		return:	[integer!]
		/local
			sym	[red-symbol!]
			id	[integer!]
			len [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/make-alt"]]

		len: -1											;-- convert all chars
		str/header: TYPE_SYMBOL							;-- make hashtable happy
		id: search str
		if positive? id [return id]

		sym: as red-symbol! ALLOC_TAIL(symbols)
		sym/header: TYPE_SYMBOL							;-- implicit reset of all header flags
		sym/node:   str/node
		sym/cache:  unicode/to-utf8 str :len
		sym/alias:  either zero? id [-1][0 - id]		;-- -1: no alias, abs(id)>0: alias id
		_hashtable/put table as red-value! sym
		block/rs-length? symbols
	]
	
	make: func [
		s 		[c-string!]								;-- input c-string!
		return:	[integer!]
		/local
			str  [red-string!]
			sym  [red-symbol!]
			id   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/make"]]
		
		str: declare red-string!
		str/node:	unicode/load-utf8 s system/words/length? s
		str/header: TYPE_SYMBOL							;-- make hashtable happy
		str/head:	0
		id: search str

		if positive? id [return id]
		
		sym: as red-symbol! ALLOC_TAIL(symbols)	
		sym/header: TYPE_SYMBOL							;-- implicit reset of all header flags
		sym/node:   str/node
		sym/cache:  duplicate s
		sym/alias:  either zero? id [-1][0 - id]		;-- -1: no alias, abs(id)>0: alias id
		_hashtable/put table as red-value! sym
		block/rs-length? symbols
	]
	
	get: func [
		id		[integer!]
		return:	[red-symbol!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(symbols)
		as red-symbol! s/offset + id - 1
	]
	
	resolve: func [
		id		[integer!]
		return:	[integer!]
		/local
			sym	[red-symbol!]
			s	[series!]
	][
		s: GET_BUFFER(symbols)
		sym: as red-symbol! s/offset + id - 1
		either positive? sym/alias [sym/alias][id]
	]

	get-alias-id: func [
		id		[integer!]
		return:	[integer!]
		/local
			sym	[red-symbol!]
			s	[series!]
	][
		s: GET_BUFFER(symbols)
		sym: as red-symbol! s/offset + id - 1
		sym/alias
	]

	push: func [

	][

	]
	
	;-- Actions -- 

	compare: func [
		sym1	[red-symbol!]
		sym2	[red-symbol!]
		op		[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/compare"]]

		string/equal? as red-string! sym1 as red-string! sym2 op no							;-- match?: no
	]
	
	init: does [
		datatype/register [
			TYPE_SYMBOL
			TYPE_VALUE
			"symbol!"
			;-- General actions --
			null			;make
			null			;random
			null			;reflect
			null			;to
			null			;form
			null			;mold
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