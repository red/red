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
	
	validate: func [									;-- temporary mimalist spec checking
		spec [red-block!]
		/local
			value  [red-value!]
			end	   [red-value!]
			next   [red-value!]
			block? [logic!]
	][
		value: block/rs-head spec
		end:   block/rs-tail spec
		
		while [value < end][
			switch TYPE_OF(value) [
				TYPE_WORD
				TYPE_GET_WORD [
					next: value + 1
					block?: all [
						next < end
						TYPE_OF(next) = TYPE_BLOCK
					]
					value: value + either block? [2][1]
				]
				TYPE_SET_WORD [
					next: value + 1
					unless all [
						next < end
						TYPE_OF(next) = TYPE_BLOCK
					][
						print-line "*** Error: return: not followed by type in function spec"
						halt
					]
					value: next
				]
				TYPE_LIT_WORD
				TYPE_REFINEMENT
				TYPE_STRING [
					value: value + 1
				]
				default [
					print-line "*** Error: invalid value in function spec"
					halt
				]
			]
		]
	]
	
	bind: func [
		body [red-block!]
		ctx	 [red-context!]
		/local
			value [red-value!]
			end	  [red-value!]
			w	  [red-word!]
			idx	  [integer!]
			type  [integer!]
	][
		value: block/rs-head body
		end:   block/rs-tail body

		while [value < end][
			switch TYPE_OF(value) [	
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_SET_WORD
				TYPE_REFINEMENT [
					w: as red-word! value
					idx: _context/find-word ctx w/symbol
					if idx >= 0 [
						w/ctx:   ctx
						w/index: idx
					]
				]
				TYPE_BLOCK 					;@@ replace with TYPE_ANY_BLOCK
				TYPE_PAREN 
				TYPE_PATH
				TYPE_LIT_PATH
				TYPE_SET_PATH
				TYPE_GET_PATH	[
					bind as red-block! value ctx
				]
				default [0]
			]
			value: value + 1
		]
	]
	
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
		code	 [integer!]
		return:	 [red-context!]							;-- return function's local context
		/local
			cell   [red-function!]
			native [red-native!]
			more   [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_function/push"]]

		cell: as red-function! stack/push*
		cell/header: TYPE_FUNCTION						;-- implicit reset of all header flags
		cell/spec:	 spec/node
		cell/ctx:	 _context/make spec yes
		cell/more:	 alloc-cells 3
		
		more: as series! cell/more/value
		copy-cell
			as cell! body
			alloc-tail more
		
		alloc-tail more									;-- reserved place for "symbols"
		
		native: as red-native! alloc-tail more
		native/header: TYPE_NATIVE
		native/code: code
		
		bind body cell/ctx
		cell/ctx
	]
		
	;-- Actions -- 
	
	reflect: func [
		fun		[red-function!]
		field	[integer!]
		return:	[red-block!]
		/local
			blk [red-block!]
			s	[series!]
	][
		case [
			field = words/spec [
				blk: as red-block! stack/arguments		;-- overwrite the function slot on stack
				blk/header: TYPE_BLOCK
				blk/node: fun/spec						;-- order of assignments matters
				blk/head: 0
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
		blk												;@@ TBD: remove it when all cases implemented
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
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "function/mold"]]

		string/concatenate-literal buffer "func "
		
		blk: as red-block! stack/push*
		blk/header: TYPE_BLOCK
		blk/head: 0
		blk/node: fun/spec
		part: block/mold blk buffer only? all? flat? arg part - 5			;-- spec
		
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