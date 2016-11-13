Red/System [
	Title:   "Logic! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %logic.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

true-value:  declare red-logic!							;-- preallocate TRUE value
false-value: declare red-logic!							;-- preallocate FALSE value

logic: context [
	verbose: 0
	
	get: func [											;-- unboxing integer value
		value	 [red-value!]
		return:  [logic!]
		/local
			cell [red-logic!]
	][
		assert TYPE_OF(value) = TYPE_LOGIC
		cell: as red-logic! value
		cell/value
	]
	
	box: func [
		value	[logic!]
		return: [red-logic!]
		/local
			cell [red-logic!]
	][
		cell: as red-logic! stack/arguments
		cell/header: TYPE_LOGIC
		cell/value: value
		cell
	]
	
	top-true?: func [
		return:  [logic!]
	][
		not top-false?									;-- true if not none or false
	]

	top-false?: func [
		return:  [logic!]
		/local
			arg	 [red-logic!]
			type [integer!]
	][
		arg: as red-logic! stack/top - 1
		type: TYPE_OF(arg)

		any [
			type = TYPE_NONE
			all [type = TYPE_LOGIC not arg/value]
		]
	]
		
	true?: func [
		return:  [logic!]
		/local
			arg	 [red-logic!]
			type [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/true?"]]
		
		arg: as red-logic! stack/arguments
		type: TYPE_OF(arg)
		if type = TYPE_UNSET [fire [TO_ERROR(script no-return)]]
		
		not any [										;-- true if not none or false
			type = TYPE_NONE
			all [type = TYPE_LOGIC not arg/value]
		]
	]
	
	false?: func [
		return:  [logic!]
		/local
			arg	 [red-logic!]
			type [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/false?"]]
		
		arg: as red-logic! stack/arguments
		type: TYPE_OF(arg)
		
		any [
			type = TYPE_NONE
			all [type = TYPE_LOGIC not arg/value]
		]
	]
	
	make-in: func [
		parent	 [red-block!]
		value 	 [logic!]
		return:	 [red-logic!]
		/local
			cell [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/make-in"]]

		cell: as red-logic! ALLOC_TAIL(parent)
		cell/header: TYPE_LOGIC							;-- implicit reset of all header flags
		cell/value: value
		cell
	]
	
	push: func [
		value 	 [logic!]
		return:	 [red-logic!]
		/local
			cell [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/push"]]

		cell: as red-logic! stack/push*
		cell/header: TYPE_LOGIC							;-- implicit reset of all header flags
		cell/value: value
		cell
	]
	
	;-- Actions -- 

	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-logic!]							;-- return cell pointer
		/local
			bool [red-logic!]
			int	 [red-integer!]
			fl	 [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				bool: as red-logic! proto
				bool/header: TYPE_LOGIC					;-- implicit reset of all header flags
				bool/value: as-logic int/value
				bool
			]
			TYPE_FLOAT
			TYPE_PERCENT [
				fl: as red-float! spec
				bool: as red-logic! proto
				bool/header: TYPE_LOGIC					;-- implicit reset of all header flags
				bool/value: fl/value <> 0.0
				bool
			]
			default [to proto spec type]
		]
	]

	random: func [
		logic	[red-logic!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/random"]]

		either seed? [
			_random/srand as-integer logic/value
			logic/header: TYPE_UNSET
		][
			logic/value: _random/rand % 2 <> 0
		]
		logic
	]
	
	to: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/to"]]

		switch TYPE_OF(spec) [
			TYPE_LOGIC [as red-logic! spec]
			TYPE_NONE  [false-value]
			default	   [true-value]
		]
	]

	form: func [
		boolean	[red-logic!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/form"]]

		string/concatenate-literal buffer either boolean/value ["true"]["false"]
		part - either boolean/value [4][5]
	]
	
	mold: func [
		boolean	[red-logic!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/mold"]]

		form boolean buffer arg part
	]
	
	compare: func [
		arg1      [red-logic!]							;-- first operand
		arg2	  [red-logic!]							;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "logic/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_LOGIC [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL 
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [res: (as-integer arg1/value) - (as-integer arg2/value)]
			default [
				res: -2
			]
		]
		res
	]
	
	complement: func [
		bool	[red-logic!]
		return:	[red-value!]
	][
		bool/value: not bool/value
		as red-value! bool
	]

	do-bitwise: func [
		type	  [integer!]
		return:	  [red-logic!]
		/local
			left  [red-logic!]
			right [red-logic!]
	][
		left: as red-logic! stack/arguments
		right: left + 1
		if TYPE_OF(right) <> TYPE_LOGIC [
			ERR_EXPECT_ARGUMENT((TYPE_OF(right)) 1)
		]
		left/value: switch type [
			OP_AND [left/value and right/value]
			OP_OR  [left/value or  right/value]
			OP_XOR [left/value xor right/value]
		]
		left
	]

	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "logic/and~"]]
		as red-value! do-bitwise OP_AND
	]

	or~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "logic/or~"]]
		as red-value! do-bitwise OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "logic/xor~"]]
		as red-value! do-bitwise OP_XOR
	]

	init: does [
		true-value/header:  TYPE_LOGIC
		true-value/value: 	yes
		
		false-value/header: TYPE_LOGIC
		false-value/value: 	no
	
		datatype/register [
			TYPE_LOGIC
			TYPE_VALUE
			"logic!"
			;-- General actions --
			:make
			:random
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
			:and~
			:complement
			:or~
			:xor~
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