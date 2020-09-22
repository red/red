Red/System [
	Title:   "Symbol! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %symbol.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

symbol: context [
	verbose: 0
	table: as node! 0
	
	is-any-type?: func [
		word	[red-word!]
		return: [logic!]
	][
		assert TYPE_OF(word) = TYPE_WORD
		(resolve word/symbol) = resolve words/any-type!
	]

	make-red-string: func [
		sym		[red-symbol!]
		/local
			s	[series!]
	][
		if sym/node = null [
			s: as series! sym/cache/value
			sym/node: unicode/load-utf8 as c-string! s/offset as-integer s/tail - s/offset
		]
	]

	make-alt: func [
		str 	[red-string!]
		len		[integer!]		;-- -1: use the whole string
		return:	[integer!]
		/local
			s	[c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/make-alt"]]
		s: unicode/to-utf8 str :len
		make-alt-utf8 as byte-ptr! s len
	]

	make-alt-utf8: func [
		s 		[byte-ptr!]
		len		[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/make-alt-utf8"]]
		_hashtable/put-symbol table s len no
	]

	make: func [
		s 		[c-string!]								;-- input c-string!
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/make"]]
		_hashtable/put-symbol table as byte-ptr! s system/words/length? s no
	]

	make-opt: func [
		s		[c-string!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/make-opt"]]
		_hashtable/put-symbol table as byte-ptr! s system/words/length? s yes
	]
	
	get: func [
		id		[integer!]
		return:	[red-symbol!]
		/local
			s	[series!]
			sym [red-symbol!]
	][
		s: GET_BUFFER(symbols)
		sym: as red-symbol! s/offset + id - 1
		make-red-string sym
		sym
	]
	
	get-c-string: func [
		id		[integer!]
		return:	[c-string!]
		/local
			sym	[red-symbol!]
			s	[series!]
	][
		sym: get id
		s: as series! sym/node/value
		as c-string! s/offset
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
		assert sym < s/tail
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