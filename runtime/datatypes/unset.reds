Red/System [
	Title:   "Unset! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %unset.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

unset-value: declare red-value!							;-- preallocate unset! value

unset: context [
	verbose: 0
	
	push-last: func [
		return:	 [red-unset!]
		/local
			cell [red-unset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/push-last"]]

		cell: as red-unset! stack/arguments
		cell/header: TYPE_UNSET							;-- implicit reset of all header flags
		cell
	]
	
	make-in: func [
		parent	 [red-block!]
		return:	 [red-unset!]
		/local
			cell [red-unset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/make-in"]]

		cell: as red-unset! ALLOC_TAIL(parent)
		cell/header: TYPE_UNSET							;-- implicit reset of all header flags
		cell
	]
	
	push: func [
		return:	 [red-unset!]
		/local
			cell [red-unset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/push"]]

		cell: as red-unset! stack/push*
		cell/header: TYPE_UNSET							;-- implicit reset of all header flags
		cell
	]

	;-- Actions -- 

	to: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-unset!]
		/local
			cell [red-unset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/to"]]
		cell: as red-unset! stack/push*
		cell/header: TYPE_UNSET							;-- implicit reset of all header flags
		cell
	]

	form: func [
		value	[red-unset!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/form"]]
		
		part
	]
	
	mold: func [
		value	[red-unset!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/mold"]]
		
		string/concatenate-literal buffer "unset"
		part - 5
	]
	
	compare: func [
		arg1      [red-unset!]							;-- first operand
		arg2	  [red-unset!]							;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_UNSET [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL 
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL [res: as-integer type <> TYPE_UNSET]
			COMP_SORT
			COMP_CASE_SORT [res: 0]
			default [
				res: -2
			]
		]
		res
	]

	init: does [
		unset-value/header: TYPE_UNSET

		datatype/register [
			TYPE_UNSET
			TYPE_VALUE
			"unset!"
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