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
	
	store: func [
		blk 	[red-block!]
		return: [red-block!]
	][
		copy-cell
			as cell! blk
			ALLOC_TAIL(root)
		blk
	]
	
	append*: func [
		return: [red-block!]
		/local
			blk	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/append*"]]
	
		blk: as red-block! stack/arguments
		assert TYPE_OF(blk) = TYPE_BLOCK
		
		copy-cell
			stack/arguments + 1
			ALLOC_TAIL(blk)
		blk
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
		return: [red-block!]
		/local
			blk	[red-block!]
	][
		;@@ implement /part and /only support
		blk: as red-block! stack/arguments
		assert TYPE_OF(blk) = TYPE_BLOCK
		
		copy-cell
			stack/arguments + 1
			ALLOC_TAIL(blk)
		blk
	]

	mold: func [
		part	[integer!]
	][

	]
	
	length?: func [
		return: [integer!]
	][
		0
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