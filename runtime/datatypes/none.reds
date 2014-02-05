Red/System [
	Title:   "None! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %none.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

none-value: declare red-value!							;-- preallocate none! value

none: context [
	verbose: 0
	
	rs-push: func [
		blk		[red-block!]
		return:	[red-value!]							;-- return cell pointer
		/local
			cell 	[red-none!]
	][
		cell: as red-none! ALLOC_TAIL(blk)
		cell/header: TYPE_NONE							;-- implicit reset of all header flags
		as red-value! cell
	]
	
	push-last: func [
		return:		[red-value!]						;-- return cell pointer
		/local
			cell 	[red-none!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/push-last"]]

		cell: as red-none! stack/arguments
		cell/header: TYPE_NONE							;-- implicit reset of all header flags
		as red-value! cell
	]
	
	push: func [
		return:		[red-value!]						;-- return cell pointer
		/local
			cell 	[red-none!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/push"]]

		cell: as red-none! stack/push*
		cell/header: TYPE_NONE							;-- implicit reset of all header flags
		as red-value! cell
	]
		
	;-- Actions -- 

	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-none!]
		/local
			cell [red-none!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/make"]]

		cell: as red-none! stack/push*
		cell/header: TYPE_NONE							;-- implicit reset of all header flags
		cell
	]
	
	form: func [
		value	[red-none!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/form"]]
		
		string/concatenate-literal buffer "none"
		part - 4
	]
	
	mold: func [
		value	[red-none!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/mold"]]

		form value buffer arg part
	]
	
	compare: func [
		arg1      [red-none!]							;-- first operand
		arg2	  [red-none!]							;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [logic!]
		/local
			type  [integer!]
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/compare"]]

		type: TYPE_OF(arg2)
		switch op [
			COMP_EQUAL 
			COMP_STRICT_EQUAL [res: type =  TYPE_NONE]
			COMP_NOT_EQUAL	  [res: type <> TYPE_NONE]
			default [
				print-line ["Error: cannot use: " op " comparison on none! value"]
			]
		]
		res
	]
	
	clear:	 does []									;-- arguments can be safely omitted
	find:    does []
	
	length?: func [
		value	[red-none!]
		return: [integer!]
	][
		-1
	]
	
	remove:  func [
		series	[red-series!]
		part	[red-value!]
		return:	[integer!]
	][
		push-last
		0
	]
	
	select:  does []
	take:	 does []

	init: does [
		none-value/header: TYPE_NONE
		
		datatype/register [
			TYPE_NONE
			TYPE_VALUE
			"none!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			null			;get-path
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
			:clear
			null			;copy
			:find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			:length?
			null			;next
			null			;pick
			null			;poke
			:remove
			null			;reverse
			:select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			:take
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