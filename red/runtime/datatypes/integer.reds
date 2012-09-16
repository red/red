Red/System [
	Title:   "Integer! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %integer.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

integer: context [
	verbose: 0

	get: func [										;-- unboxing integer value
		value		[red-value!]
		return: 	[integer!]
		/local
			cell	[red-integer!]
	][
		assert TYPE_OF(value) = TYPE_INTEGER
		cell: as red-integer! value
		cell/value
	]
	
	form-signed: func [
		s [c-string!]
		i [integer!]
		return: [c-string!]
		/local 
			c [integer!]
			n [logic!]
	][
		if zero? i [
			s/1: #"0"
			s/2: null-byte
			return s
		]
		n:  negative? i
		if n [i: negate i]
		c: 11
		while [i <> 0][
			s/c: #"0" + (i // 10)
			i: i / 10
			c: c - 1
		]
		if n [s/c: #"-" c: c - 1]
		i: 11 - c
		s/i: null-byte
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
		
		assert TYPE_OF(left)  = TYPE_INTEGER
		assert TYPE_OF(right) = TYPE_INTEGER
		
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
	
	form: func [
		part 		[integer!]
		return: 	[integer!]
		/local
			arg		[red-integer!]
			value	[integer!]
			str		[red-string!]
			series	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/form"]]
		
		arg: as red-integer! stack/arguments
		assert TYPE_OF(arg) = TYPE_INTEGER
		value: arg/value
		
		str: as red-string! arg + 1
		assert TYPE_OF(str) = TYPE_STRING
		
		series: GET_BUFFER(str)
		series/offset: as cell! form-signed as c-string! series/offset value
		part											;@@ implement full support for /part
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
		;-- General actions --
		null			;make
		null			;random
		null			;reflect
		null			;to
		:form
		null			;mold
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
		null			;index-of
		null			;insert
		null			;length-of
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