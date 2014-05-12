Red/System [
	Title:   "Integer! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %integer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

integer: context [
	verbose: 0

	get*: func [										;-- unboxing integer value from stack
		return: [integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments
		assert TYPE_OF(int) = TYPE_INTEGER
		int/value
	]
	
	get-any*: func [									;-- special get* variant for SWITCH
		return: [integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments
		either TYPE_OF(int) = TYPE_INTEGER [int/value][0] ;-- accept NONE values
	]
	
	get: func [											;-- unboxing integer value
		value	[red-value!]
		return: [integer!]
		/local
			int [red-integer!]
	][
		assert TYPE_OF(value) = TYPE_INTEGER
		int: as red-integer! value
		int/value
	]
	
	box: func [
		value	[integer!]
		return: [red-integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments
		int/header: TYPE_INTEGER
		int/value: value
		int
	]
	
	form-signed: func [									;@@ replace with sprintf() call?
		i 		[integer!]
		return: [c-string!]
		/local 
			s	[c-string!]
			c 	[integer!]
			n 	[logic!]
	][
		s: "-0000000000"								;-- 11 bytes wide	
		if zero? i [									;-- zero special case
			s/11: #"0"
			return s + 10
		]
		if i = -2147483648 [							;-- min integer special case
			return "-2147483648"
		]
		n: negative? i
		if n [i: negate i]
		c: 11
		while [i <> 0][
			s/c: #"0" + (i // 10)
			i: i / 10
			c: c - 1
		]
		if n [s/c: #"-" c: c - 1]
		s + c
	]

	do-math: func [
		type	  [math-op!]
		return:	  [red-integer!]
		/local
			left  [red-integer!]
			right [red-integer!]
	][
		left: as red-integer! stack/arguments
		right: left + 1
		
		assert any [									;@@ replace by typeset check when possible
			TYPE_OF(left) = TYPE_INTEGER
			TYPE_OF(left) = TYPE_CHAR
		]
		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_CHAR
		]
		
		left/value: switch type [
			OP_ADD [left/value + right/value]
			OP_SUB [left/value - right/value]
			OP_MUL [left/value * right/value]
			OP_DIV [left/value / right/value]
			OP_REM [left/value % right/value]
			OP_AND [left/value and right/value]
			OP_OR  [left/value or right/value]
			OP_XOR [left/value xor right/value]
		]
		left
	]

	load-in: func [
		blk	  	[red-block!]
		value 	[integer!]
		/local
			int [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/load-in"]]
		
		int: as red-integer! ALLOC_TAIL(blk)
		int/header: TYPE_INTEGER
		int/value: value
	]
	
	push: func [
		value	[integer!]
		return: [red-integer!]
		/local
			int [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/push"]]
		
		int: as red-integer! stack/push*
		int/header: TYPE_INTEGER
		int/value: value
		int
	]

	;-- Actions --
	
	make: func [
		proto	 [red-value!]	
		spec	 [red-value!]
		return:	 [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				as red-integer! spec
			]
			default [
				--NOT_IMPLEMENTED--
				as red-integer! spec					;@@ just for making it compilable
			]
		]
	]

	random: func [
		int		[red-integer!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			n	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/random"]]

		either seed? [
			_random/srand int/value
			int/header: TYPE_UNSET
		][
			n: _random/rand % int/value + 1
			int/value: either negative? int/value [0 - n][n]
		]
		as red-value! int
	]

	form: func [
		int		   [red-integer!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/form"]]
		
		formed: form-signed int/value
		string/concatenate-literal buffer formed
		part - length? formed							;@@ optimize by removing length?
	]
	
	mold: func [
		int		[red-integer!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/mold"]]

		form int buffer arg part
	]
	
	compare: func [
		value1    [red-integer!]						;-- first operand
		value2    [red-integer!]						;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [logic!]
		/local
			char  [red-char!]
			left  [integer!]
			right [integer!] 
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/compare"]]
		
		left: value1/value
		
		switch TYPE_OF(value2) [
			TYPE_INTEGER [
				right: value2/value
			]
			TYPE_CHAR [
				char: as red-char! value2				;@@ could be optimized as integer! and char!
				right: char/value						;@@ structures are overlapping exactly
			]
			default [RETURN_COMPARE_OTHER]
		]
		switch op [
			COMP_EQUAL 			[res: left = right]
			COMP_NOT_EQUAL 		[res: left <> right]
			COMP_STRICT_EQUAL	[res: all [TYPE_OF(value2) = TYPE_INTEGER left = right]]
			COMP_LESSER			[res: left <  right]
			COMP_LESSER_EQUAL	[res: left <= right]
			COMP_GREATER		[res: left >  right]
			COMP_GREATER_EQUAL	[res: left >= right]
		]
		res
	]
	
	complement: func [
		int		[red-integer!]
		return:	[red-value!]
	][
		int/value: not int/value
		as red-value! int
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/remainder"]]
		as red-value! do-math OP_REM
	]

	absolute: func [
		return: [red-integer!]
		/local
			int	  [red-integer!]
			value [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/absolute"]]
		
		int: as red-integer! stack/arguments
		value: int/value
		
		if value = -2147483648 [
			print-line "*** Math Error: integer overflow on ABSOLUTE"
		]
		if negative? value [int/value: 0 - value]
		int 											;-- re-use argument slot for return value
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/add"]]
		as red-value! do-math OP_ADD
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/divide"]]
		as red-value! do-math OP_DIV
	]
		
	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/multiply"]]
		as red-value! do-math OP_MUL
	]
	
	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/subtract"]]
		as red-value! do-math OP_SUB
	]

	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/and~"]]
		as red-value! do-math OP_AND
	]

	or~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/or~"]]
		as red-value! do-math OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/xor~"]]
		as red-value! do-math OP_XOR
	]

	negate: func [
		return: [red-integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments
		int/value: 0 - int/value
		int 											;-- re-use argument slot for return value
	]

	int-power: func [
		base	[integer!]
		exp		[integer!]
		return: [integer!]
		/local
			res  [integer!]
			neg? [logic!]
	][
		res: 1
		neg?: false

		if exp < 0 [neg?: true exp: 0 - exp]
		while [exp <> 0][
			if as logic! exp and 1 [res: res * base]
			exp: exp >> 1
			base: base * base
		]
		either neg? [1 / res][res]
	]

	power: func [
		return:	 [red-integer!]
		/local
			base [red-integer!]
			exp  [red-integer!]
	][
		base: as red-integer! stack/arguments
		exp: base + 1
		base/value: int-power base/value exp/value
		base
	]
	
	even?: func [
		int		[red-integer!]
		return: [logic!]
	][
		not as-logic int/value and 1
	]
	
	odd?: func [
		int		[red-integer!]
		return: [logic!]
	][
		as-logic int/value and 1
	]
	
	init: does [
		datatype/register [
			TYPE_INTEGER
			TYPE_VALUE
			"integer!"
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
			:even?
			:odd?
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