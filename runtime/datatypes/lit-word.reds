Red/System [
	Title:   "Lit-word! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %lit-word.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

lit-word: context [
	verbose: 0
	
	load-in: func [
		str 	 [c-string!]
		blk		 [red-block!]
		return:	 [red-word!]
		/local 
			cell [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-word/load"]]
		
		cell: word/load-in str blk
		cell/header: TYPE_LIT_WORD						;-- implicit reset of all header flags
		cell
	]
	
	load: func [
		str 	[c-string!]
		return:	[red-word!]
		/local 
			cell [red-word!]
	][
		cell: word/load str
		cell/header: TYPE_LIT_WORD						;-- implicit reset of all header flags
		cell
	]
	
	push: func [
		w		[red-word!]
		return:	[red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-word/push"]]
		
		w: word/push w
		set-type as red-value! w TYPE_LIT_WORD
		w
	]
	
	push-local: func [
		node	[node!]
		index	[integer!]
		return: [red-word!]
		/local
			ctx	[red-context!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-word/push-local"]]

		ctx: TO_CTX(node)
		s: as series! ctx/symbols/value
		push as red-word! s/offset + index
	]

	set: func [
		/local
			args [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-word/set"]]
		
		args: stack/arguments
		_context/set as red-word! args args + 1
		stack/set-last args + 1
	]
	
	get: does [
		#if debug? = yes [if verbose > 0 [print-line "lit-word/get"]]
		
		stack/set-last _context/get as red-word! stack/arguments
	]
	
	;-- Actions --

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
		#if debug? = yes [if verbose > 0 [print-line "lit-word/mold"]]
		
		string/append-char GET_BUFFER(buffer) as-integer #"'"
		word/form w buffer arg part - 1
	]
	
	init: does [
		datatype/register [
			TYPE_LIT_WORD
			TYPE_WORD
			"lit-word!"
			;-- General actions --
			INHERIT_ACTION	;make
			null			;random
			null			;reflect
			INHERIT_ACTION	;to
			INHERIT_ACTION	;form
			:mold
			null			;eval-path
			null			;set-path
			INHERIT_ACTION	;compare
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
