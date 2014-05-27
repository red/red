Red/System [
	Title:   "Float! datatype runtime functions"
	Author:  "Nenad Rakocevic, Oldes"
	File: 	 %decimal.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define DBL_EPSILON	2.2204460492503131E-16

float: context [
	verbose: 4

	abs: func [
		value	[float!]
		return: [float!]
		/local
			n	[int-ptr!]
	][
		n: (as int-ptr! :value) + 1
		n/value: n/value and 7FFFFFFFh
		value
	]

	get*: func [										;-- unboxing float value from stack
		return: [float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		assert TYPE_OF(fl) = TYPE_FLOAT
		fl/value
	]

	get-any*: func [									;-- special get* variant for SWITCH
		return: [float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		either TYPE_OF(fl) = TYPE_FLOAT [fl/value][0.0] ;-- accept NONE values
	]

	get: func [											;-- unboxing float value
		value	[red-value!]
		return: [float!]
		/local
			fl [red-float!]
	][
		assert TYPE_OF(value) = TYPE_FLOAT
		fl: as red-float! value
		fl/value
	]

	box: func [
		value	[float!]
		return: [red-float!]
		/local
			int [red-float!]
	][
		fl: as red-float! stack/arguments
		fl/header: TYPE_FLOAT
		fl/value: value
		fl
	]

	to-integer: func [
		number 	[float!]
		return:	[integer!]
		/local
			f	[float!]
			d	[int-ptr!]
	][
		;-- Based on this method: http://stackoverflow.com/a/429812/494472
		;-- A bit more explanation: http://lolengine.net/blog/2011/3/20/understanding-fast-float-integer-conversions
		f: number + 6755399441055744.0
		d: as int-ptr! :f
		d/value
	]

	do-math: func [
		type	  [integer!]
		return:	  [red-float!]
		/local
			left  [red-float!]
			right [red-float!]
			int   [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/do-math"]]

		left:  as red-float! stack/arguments
		right: as red-float! left + 1

		assert any [									;@@ replace by typeset check when possible
			TYPE_OF(left) = TYPE_INTEGER
			TYPE_OF(left) = TYPE_FLOAT
		]
		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_CHAR
			TYPE_OF(right) = TYPE_FLOAT
		]

		if TYPE_OF(left) <> TYPE_FLOAT [
			int: as red-integer! left
			left/header: TYPE_FLOAT
			left/value: integer/to-float int/value
		]
		if TYPE_OF(right) <> TYPE_FLOAT [
			int: as red-integer! right
			right/value: integer/to-float int/value
		]

		left/value: switch type [
			OP_ADD [left/value + right/value]
			OP_SUB [left/value - right/value]
			OP_MUL [left/value * right/value]
			OP_DIV [left/value / right/value]
			OP_REM [left/value % right/value]
			default [print-line "*** Math Error: float don't support BITWISE OP!" left/value]
		]
		left
	]

	load-in: func [
		blk	  	[red-block!]
		value 	[float!]
		/local
			fl [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/load-in"]]

		fl: as red-float! ALLOC_TAIL(blk)
		fl/header: TYPE_FLOAT
		fl/value: value
	]

	push: func [
		value	[float!]
		return: [red-float!]
		/local
			fl [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/push"]]

		fl: as red-float! stack/push*
		fl/header: TYPE_FLOAT
		fl/value: value
		fl
	]

	;-- Actions --

	make: func [
		proto	 [red-value!]	
		spec	 [red-value!]
		return:	 [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/make"]]

		switch TYPE_OF(spec) [
			TYPE_FLOAT [
				as red-float! spec
			]
			default [
				--NOT_IMPLEMENTED--
				as red-float! spec					;@@ just for making it compilable
			]
		]
	]

	random: func [
		f		[red-float!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-float!]
		/local
			t	[float!]
			s	[float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/random"]]

		either seed? [
			_random/srand to-integer f/value
			f/header: TYPE_UNSET
		][
			s: (integer/to-float _random/rand) / 2147483647.0
			if s < 0.0 [s: 0.0 - s]
			f/value: s * f/value
		]
		f
	]

	form: func [
		fl		   [red-float!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/form"]]

		formed: "000000000000000000000000000000"						;-- 30 bytes wide, big enough.
		sprintf [formed "%.14g" fl/value]
		
		string/concatenate-literal buffer formed
		part - length? formed							;@@ optimize by removing length?
	]

	mold: func [
		fl		[red-float!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/mold"]]

		form fl buffer arg part
	]

	compare: func [
		value1    [red-float!]						;-- first operand
		value2    [red-float!]						;-- second operand
		op	      [integer!]						;-- type of comparison
		return:   [logic!]
		/local
			int   [red-integer!]
			left  [float!]
			right [float!] 
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/compare"]]

		left: value1/value

		switch TYPE_OF(value2) [
			TYPE_CHAR
			TYPE_INTEGER [
				int: as red-integer! value2
				right: integer/to-float int/value
			]
			TYPE_FLOAT [right: value2/value]
			default [RETURN_COMPARE_OTHER]
		]
		switch op [
			COMP_EQUAL 			[res: left = right]
			COMP_NOT_EQUAL 		[res: left <> right]
			COMP_STRICT_EQUAL	[res: all [TYPE_OF(value2) = TYPE_FLOAT left = right]]
			COMP_LESSER			[res: left <  right]
			COMP_LESSER_EQUAL	[res: left <= right]
			COMP_GREATER		[res: left >  right]
			COMP_GREATER_EQUAL	[res: left >= right]
		]
		res
	]

	complement: func [
		fl		[red-float!]
		return:	[red-value!]
	][
		--NOT_IMPLEMENTED--
		;fl/value: not fl/value
		as red-value! fl
	]

	absolute: func [
		return: [red-float!]
		/local
			f	  [red-float!]
			value [float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/absolute"]]

		f: as red-float! stack/arguments
		f/value: abs f/value
		f 											;-- re-use argument slot for return value
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/add"]]
		as red-value! do-math OP_ADD
	]

	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/divide"]]
		as red-value! do-math OP_DIV
	]

	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/multiply"]]
		as red-value! do-math OP_MUL
	]

	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/subtract"]]
		as red-value! do-math OP_SUB
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/remainder"]]
		as red-value! do-math OP_REM
	]

	negate: func [
		return: [red-float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		fl/value: 0.0 - fl/value
		fl 											;-- re-use argument slot for return value
	]

	power: func [
		return:	 [red-float!]
		/local
			base [red-float!]
			exp  [red-float!]
			int	 [red-integer!]
	][
		base: as red-float! stack/arguments
		exp: base + 1
		if TYPE_OF(exp) = TYPE_INTEGER [
			int: as red-integer! exp
			exp/value: integer/to-float int/value
		]
		base/value: float-power base/value exp/value
		base
	]

	even?: func [
		int		[red-float!]
		return: [logic!]
	][
		;requires conversion to integer
		;not as-logic float/value and 1
		--NOT_IMPLEMENTED--
		false
	]

	odd?: func [
		int		[red-integer!]
		return: [logic!]
	][
		;requires conversion to integer
		;as-logic int/value and 1
		--NOT_IMPLEMENTED--
		false
	]

	init: does [
		datatype/register [
			TYPE_FLOAT
			TYPE_VALUE
			"float!"
			;-- General actions --
			:make
			:random
			null			;reflect
			null			;to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			:power
			:remainder
			null			;round
			:subtract
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