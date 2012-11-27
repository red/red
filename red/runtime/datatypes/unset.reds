Red/System [
	Title:   "Unset! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %unset.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

unset-value: declare red-value!							;-- preallocate unset! value
unset-value/header: TYPE_UNSET

unset: context [
	verbose: 0
	
	;-- Actions -- 

	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-unset!]
		/local
			cell [red-unset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/make"]]
		
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
		
		string/concatenate-literal buffer "unset"
		part - 5
	]
	
	mold: func [
		value	[red-unset!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/mold"]]
		
		form value buffer arg part
	]
	
	compare: func [
		arg1      [red-unset!]							;-- first operand
		arg2	  [red-unset!]							;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [logic!]
		/local
			type  [integer!]
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/compare"]]

		type: TYPE_OF(arg2)
		switch op [
			COMP_EQUAL 
			COMP_STRICT_EQUAL [res: type =  TYPE_UNSET]
			COMP_NOT_EQUAL	  [res: type <> TYPE_UNSET]
			default [
				print-line ["Error: cannot use: " op " comparison on unset! value"]
			]
		]
		res
	]

	datatype/register [
		TYPE_UNSET
		TYPE_VALUE
		"unset!"
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