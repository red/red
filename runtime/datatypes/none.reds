Red/System [
	Title:   "None! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %none.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

none-value: declare red-value!							;-- preallocate none! value

none: context [
	verbose: 0
	
	make-in: func [
		parent	[red-block!]
		return:	[red-value!]							;-- return cell pointer
		/local
			cell 	[red-none!]
	][
		cell: as red-none! ALLOC_TAIL(parent)
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

	to: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-none!]
		/local
			cell [red-none!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/to"]]

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
		return:   [integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_NONE [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_SAME 
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [res: 0]
			default [
				res: -2
			]
		]
		res
	]
	
	clear: func [
		none	[red-none!]
		return:	[red-value!]
 	][
		push-last
	]
	
	find: func [
		none		[red-none!]
		value		[red-value!]
		part		[red-value!]
		only?		[logic!]
		case?		[logic!]
		same?		[logic!]
		any?		[logic!]
		with-arg	[red-string!]
		skip		[red-integer!]
		last?		[logic!]
		reverse?	[logic!]
		tail?		[logic!]
		match?		[logic!]
		return:		[red-value!]
	][
		push-last
	]
	
	length?: func [
		none	[red-none!]
		return: [integer!]
	][
		-1
	]
	
	remove: func [
		none	[red-none!]
		part	[red-value!]
		return:	[red-value!]
	][
		push-last
	]
	
	select: func [
		blk		 [red-block!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:	 [red-value!]
	][
		push-last
	]

	take: func [
		value	 [red-value!]
		part-arg [red-value!]
		deep?	 [logic!]
		last?	 [logic!]
		return:  [red-value!]
	][
		push-last
	]

	init: does [
		none-value/header: TYPE_NONE
		
		datatype/register [
			TYPE_NONE
			TYPE_VALUE
			"none!"
			;-- General actions --
			:to				;make
			null			;random
			null			;reflect
			:to
			:form
			:mold
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
			:clear
			null			;copy
			:find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			:length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
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