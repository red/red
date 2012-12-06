Red/System [
	Title:   "Function! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %function.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]


_function: context [
	verbose: 0
	
	init-locals: func [
		nb 	   [integer!]
		/local
			p  [red-value!]
	][
		until [
			p: stack/push*
			p/header: TYPE_NONE
			nb: nb - 1
			zero? nb
		]
	]

	push: func [
		spec	 [red-block!]
		body	 [red-block!]
		return:	 [red-context!]							;-- return function's local context
		/local
			cell [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_function/push"]]

		cell: as red-function! stack/push*
		cell/header: TYPE_FUNCTION						;-- implicit reset of all header flags
		cell/spec:	 spec
		cell/ctx:	 _context/make spec yes
		cell/more:	 alloc-cells 2
		
		copy-cell
			as cell! body
			alloc-tail as series! cell/more/value
		
		cell/ctx
	]
		
	;-- Actions -- 
	
	reflect: func [
		fun		[red-function!]
		field	[integer!]
		return:	[red-value!]
		/local
			blk [red-block!]
			s	[series!]
	][
		case [
			field = words/spec [
				stack/set-last as red-value! fun/spec
			]
			field = words/body [
				s: as series! fun/more/value
				blk: as red-block! s/offset
				stack/set-last as red-value! blk
			]
			field = words/words [
				--NOT_IMPLEMENTED--						;@@ build the words block from spec
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		as red-value! blk								;@@ TBD: remove it when all cases implemented
	]
	
	form: func [
		value	[red-function!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "function/form"]]

		string/concatenate-literal buffer "?function?"
		part - 10
	]

	mold: func [
		fun		[red-function!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
		/local
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "function/mold"]]

		string/concatenate-literal buffer "func "
		part: block/mold fun/spec buffer only? all? flat? arg part - 5		;-- spec
		s: as series! fun/more/value
		block/mold as red-block! s/offset buffer only? all? flat? arg part	;-- body
	]

	datatype/register [
		TYPE_FUNCTION
		TYPE_CONTEXT
		"function!"
		;-- General actions --
		null			;make
		null			;random
		:reflect
		null			;to
		:form
		:mold
		null			;get-path
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