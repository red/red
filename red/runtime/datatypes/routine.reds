Red/System [
	Title:   "Routine! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %routine.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]


routine: context [
	verbose: 0
	
	get-arity: func [
		value	[red-routine!]
		return: [integer!]
	][
		value/header >> 25 and 1Fh
	]
	
	set-arity: func [
		value	[red-routine!]
		/local
			slot  [red-value!]
			tail  [red-value!]
			s	  [series!]
			count [integer!]
	][
		s: as series! value/spec/value
		
		slot:  s/offset
		tail:  s/tail
		count: 0
		
		while [slot < tail][
			if TYPE_OF(slot) = TYPE_WORD [
				count: count + 1
			]
			slot: slot + 1
		]
		
		value/header: (value/header and flag-arity-mask) or (count << 25)
	]
	
	push: func [
		spec	 [red-block!]
		body	 [red-block!]
		code	 [integer!]
		return:	 [red-routine!]							;-- return function's local context
		/local
			cell   [red-routine!]
			native [red-native!]
			value  [red-value!]
			more   [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "routine/push"]]

		cell: as red-routine! stack/push*
		cell/header: TYPE_ROUTINE						;-- implicit reset of all header flags
		cell/spec:	 spec/node
		cell/more:	 alloc-cells 3
		
		more: as series! cell/more/value
		value: either null? body [none-value][as red-value! body]
		copy-cell value alloc-tail more					;-- store body block or none
		alloc-tail more									;-- reserved place for "symbols"

		native: as red-native! alloc-tail more
		native/header: TYPE_NATIVE
		native/code: code
		
		set-arity cell
		cell
	]
		
	;-- Actions -- 
	
	form: func [
		value	[red-routine!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "routine/form"]]

		string/concatenate-literal buffer "?routine?"
		part - 10
	]

	mold: func [
		fun		[red-routine!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
		/local
			s	[series!]
			blk	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "routine/mold"]]

		string/concatenate-literal buffer "routine "
		
		blk: as red-block! stack/push*
		blk/header: TYPE_ROUTINE
		blk/head: 0
		blk/node: fun/spec
		part: block/mold blk buffer only? all? flat? arg part - 8			;-- spec
		
		s: as series! fun/more/value
		block/mold as red-block! s/offset buffer only? all? flat? arg part	;-- body
	]

	init: does [
		datatype/register [
			TYPE_ROUTINE
			TYPE_FUNCTION
			"routine!"
			;-- General actions --
			null			;make
			null			;random
			INHERIT_ACTION	;reflect
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
]