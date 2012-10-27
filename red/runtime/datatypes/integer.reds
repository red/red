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
	
	form-signed: func [									;@@ replace with sprintf() call?
		i 		[integer!]
		return: [c-string!]
		/local 
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
		type	  [integer!]
		return:	  [red-integer!]
		/local
			left  [red-integer!]
			right [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/add"]]

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
		]
		left
	]

	push: func [
		value [integer!]
		/local
			cell  [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/push"]]
		
		cell: as red-integer! stack/push
		cell/header: TYPE_INTEGER
		cell/value: value
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
	
	form: func [
		int		[red-integer!]
		buffer	[red-string!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/form"]]
		
		string/concatenate-literal buffer form-signed int/value
		part											;@@ implement full support for /part
	]
	
	mold: func [
		int		[red-integer!]
		buffer	[red-string!]
		part 	[integer!]
		flags   [integer!]								;-- 0: /only, 1: /all, 2: /flat
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/mold"]]

		string/concatenate-literal buffer form-signed int/value
		part											;@@ implement full support for /part
	]
	
	compare: func [
		value1    [red-integer!]						;-- first operand
		value2    [red-integer!]						;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [logic!]
		/local
			char  [red-char!]
			type  [integer!]
			left  [integer!]
			right [integer!] 
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/compare"]]
		
		type: TYPE_OF(value2)
		left: value1/value
		
		switch type [
			TYPE_INTEGER [
				right: value2/value
			]
			TYPE_CHAR [
				char: as red-char! value2				;@@ could be optimized as integer! and char!
				right: char/value						;@@ structures are overlapping exactly
			]
			default [									;@@ Throw error! when ready
				either op = COMP_EQUAL [
					return false
				][
					print-line ["Error: cannot compare integer! with type #" type]
					halt
				]
			]
		]
		switch op [
			COMP_EQUAL 			[res: left = right]
			COMP_STRICT_EQUAL	[res: all [type = TYPE_INTEGER left = right]]
			COMP_LESSER			[res: left <  right]
			COMP_LESSER_EQUAL	[res: left <= right]
			COMP_GREATER		[res: left >  right]
			COMP_GREATER_EQUAL	[res: left >= right]
		]
		res
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
	
	datatype/register [
		TYPE_INTEGER
		"integer"
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
		:add
		:divide
		:multiply
		null			;negate
		null			;power
		null			;remainder
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