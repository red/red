Red/System [
	Title:   "Block! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %block.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

block: context [
	verbose: 0

	rs-length?: func [
		blk 	[red-block!]
		return: [integer!]
	][
		series: GET_BUFFER(blk)
		(as-integer (series/tail - series/offset)) >> 4 - blk/head
	]
	
	get-position: func [
		base	   [integer!]
		return:	   [integer!]
		/local
			blk	   [red-block!]
			index  [red-integer!]
			s	   [series!]
			offset [integer!]
			max	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/get-position"]]

		blk: as red-block! stack/arguments
		index: as red-integer! blk + 1

		assert TYPE_OF(blk)   = TYPE_BLOCK
		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(blk)

		offset: blk/head + index/value - base			;-- index is one-based
		if negative? offset [offset: 0]
		max: (as-integer s/tail - s/offset) >> 4
		if offset > max [offset: max]

		offset
	]
	
	append*: func [
		return: [red-block!]
		/local
			arg	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/append*"]]

		arg: as red-block! stack/arguments
		assert TYPE_OF(arg) = TYPE_BLOCK

		copy-cell
			as cell! arg + 1
			ALLOC_TAIL(arg)
			
		arg
	]

	make-in: func [
		parent	[red-block!]
		size 	[integer!]								;-- number of cells to pre-allocate
		return:	[red-block!]
		/local
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/make-in"]]
		
		blk: either null? parent [
			_root
		][
			assert TYPE_OF(parent) = TYPE_BLOCK
			as red-block! ALLOC_TAIL(parent)
		]		
		blk/header: TYPE_BLOCK							;-- implicit reset of all header flags
		blk/head: 	0
		blk/node: 	alloc-cells size	
		blk
	]
	
	push: func [
		size	[integer!]
		return: [red-block!]	
		/local
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/push"]]
		
		blk: as red-block! stack/push
		blk/header: TYPE_BLOCK							;-- implicit reset of all header flags
		blk/head: 	0
		blk/node: 	alloc-cells size	
		blk
	]

	;--- Actions ---
	
	make: func [
	
	][
	
	]
	
	append: func [
		return:	  [red-value!]
		/local
			blk	  [red-block!]
			value [red-value!]
			src	  [red-block!]
			s	  [series!]
			cell  [red-value!]
			i	  [integer!]
	][
		;@@ implement /part and /only support
		blk: as red-block! stack/arguments
		value: as red-value! blk + 1
		
		either TYPE_OF(value) = TYPE_BLOCK [			;@@ replace it with: typeset/any-block?
			src: as red-block! value
			s: GET_BUFFER(src)
			cell: s/offset + src/head
			
			while [cell < s/tail][						;-- multiple values case		
				copy-cell cell ALLOC_TAIL(blk)
				cell: cell + 1
			]
		][												;-- single value case
			copy-cell value	ALLOC_TAIL(blk)
		]		
		as red-value! blk
	]

	mold: func [
		part	[integer!]
	][

	]
	
	head: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/head"]]

		blk: as red-block! stack/arguments
		blk/head: 0
		as red-value! blk
	]
	
	head?: func [
		return:	  [red-value!]
		/local
			blk	  [red-block!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/head?"]]

		blk:   as red-block! stack/arguments
		state: as red-logic! blk
		
		state/header: TYPE_LOGIC
		state/value:  zero? blk/head
		as red-value! state
	]
	
	index-of: func [
		return:	  [red-value!]
		/local
			blk	  [red-block!]
			index [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/index-of"]]

		blk:   as red-block! stack/arguments
		index: as red-integer! blk
		
		index/header: TYPE_INTEGER
		index/value:  blk/head + 1
		as red-value! index
	]
	
	length-of: func [
		return: [red-value!]
		/local
			blk	[red-block!]
			int [red-integer!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/length-of"]]
		
		blk: as red-block! stack/arguments
		
		s: GET_BUFFER(blk)
		
		int: as red-integer! blk
		int/header: TYPE_INTEGER
		int/value:  (as-integer s/tail - s/offset - blk/head) >> 4
		as red-value! int
	]
	
	at: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/at"]]
		
		blk: as red-block! stack/arguments
		blk/head: get-position 1
		as red-value! blk
	]
	
	back: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/back"]]

		blk: as red-block! stack/arguments

		s: GET_BUFFER(blk)

		if (s/offset + blk/head - 1) >= s/offset [
			blk/head: blk/head - 1
		]
		as red-value! blk
	]
	
	next: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/next"]]
	
		blk: as red-block! stack/arguments
		
		s: GET_BUFFER(blk)
		
		if (s/offset + blk/head + 1) <= s/tail [
			blk/head: blk/head + 1
		]
		as red-value! blk
	]
	
	pick: func [
		return:	   [red-value!]
		/local
			blk	   [red-block!]
			index  [red-integer!]
			s	   [series!]
			offset [integer!]
			max	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/pick"]]
		
		blk: as red-block! stack/arguments
		index: as red-integer! blk + 1
		s: GET_BUFFER(blk)
		
		offset: blk/head + index/value - 1				;-- index is one-based
		stack/push-last either any [
			negative? offset
			s/offset + offset > s/tail	
		][
			 none-value
		][
			s/offset + offset
		]
	]
	
	skip: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/skip"]]

		blk: as red-block! stack/arguments
		blk/head: get-position 0
		as red-value! blk
	]
	
	tail: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/tail"]]

		blk: as red-block! stack/arguments
		s: GET_BUFFER(blk)
		
		blk/head: (as-integer s/tail - s/offset) >> 4
		as red-value! blk
	]
	
	tail?: func [
		return:	  [red-value!]
		/local
			blk	  [red-block!]
			state [red-logic!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/tail?"]]

		blk:   as red-block! stack/arguments
		state: as red-logic! blk
		
		s: GET_BUFFER(blk)

		state/header: TYPE_LOGIC
		state/value:  (s/offset + blk/head) = s/tail
		as red-value! state
	]

	
	datatype/register [
		TYPE_BLOCK
		;-- General actions --
		:make
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
		:append
		:at
		:back
		null			;change
		null			;clear
		null			;copy
		null			;find
		:head
		:head?
		:index-of
		null			;insert
		:length-of
		:next
		:pick
		null			;poke
		null			;remove
		null			;reverse
		null			;select
		null			;sort
		:skip
		null			;swap
		:tail
		:tail?
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