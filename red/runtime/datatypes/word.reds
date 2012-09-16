Red/System [
	Title:   "Word! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %word.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

word: context [
	verbose: 0
	
	load: func [
		str 	[c-string!]
		return:	[red-word!]
		/local 
			p	  [node!]
			id    [integer!]							;-- symbol ID
			cell  [red-word!]
	][
		symbol/make str
		id: block/rs-length? symbols
		
		cell: as red-word! ALLOC_TAIL(root)
		cell/header: TYPE_WORD							;-- implicit reset of all header flags
		cell/ctx: 	 global-ctx
		cell/symbol: id
		cell/index:  _context/add global-ctx cell
		cell
	]
	
	push: func [
		word	 [red-word!]
		return:  [red-word!]
		/local
			cell [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/push"]]
		
		cell: as red-word! stack/push
		copy-cell as cell! word as cell! cell
		cell
	]

	set: func [
		/local
			args [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/set"]]
		
		args: stack/arguments
		_context/set as red-word! args args + 1
		stack/push-last args + 1
	]
	
	get: func [
		word	 [red-word!]
		return:  [red-value!]
		/local
			cell [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "word/get"]]
		
		cell: stack/push
		copy-cell
			as cell! _context/get word
			cell
		
		cell
	]
	
	;-- Actions --

	datatype/register [
		TYPE_WORD
		;-- General actions --
		null			;make
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
