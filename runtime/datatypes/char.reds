Red/System [
	Title:   "Char! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %char.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

char: context [
	verbose: 0
	
	do-math: func [
		op		[math-op!]
		return: [red-value!]
		/local
			right [red-float!]
			char  [red-char!]
	][
		right: as red-float! stack/arguments + 1
		if TYPE_OF(right) = TYPE_FLOAT [
			char: as red-char! right
			char/header: TYPE_CHAR
			char/value: as-integer right/value
		]
		char: as red-char! integer/do-math op
		char/header: TYPE_CHAR
		
		if any [
			char/value > 0010FFFFh
			negative? char/value
		][
			fire [TO_ERROR(math overflow)]
		]
		as red-value! char
	]
	
	make-in: func [
		parent	[red-block!]
		value	[integer!]
		return: [red-char!]
		/local
			cell [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/make-in"]]

		cell: as red-char! ALLOC_TAIL(parent)
		cell/header: TYPE_CHAR
		cell/value: value
		cell
	]

	push: func [
		value	 [integer!]
		return:	 [red-char!]
		/local
			cell [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/push"]]
		cell: as red-char! stack/push*
		cell/header: TYPE_CHAR
		cell/value: value
		cell
	]
	
	;-- Actions --
	
	make: func [
		proto 	  [red-value!]
		spec	  [red-value!]	
		return:	  [red-char!]
		/local
			char  [red-char!]
			int	  [red-integer!]
			value [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				value: int/value
			]
			default [--NOT_IMPLEMENTED--]
		]
		char: as red-char! stack/push*
		char/header: TYPE_CHAR
		char/value: value
		char
	]
	
	form: func [
		c	    [red-char!]
		buffer  [red-string!]
		arg		[red-value!]
		part    [integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/form"]]

		string/append-char GET_BUFFER(buffer) c/value
		part - 1
	]
	
	mold: func [
		c	    [red-char!]
		buffer  [red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part    [integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/mold"]]

		string/concatenate-literal buffer {#"}
		string/append-escaped-char buffer c/value string/ESC_CHAR all?
		string/append-char GET_BUFFER(buffer) as-integer #"^""
		part - 4
	]

	compare: func [
		value1    	[red-char!]							;-- first operand
		value2    	[red-char!]							;-- second operand
		op	      	[integer!]							;-- type of comparison
		return:		[integer!]
		/local
			integer [red-integer!]
			left  	[integer!]
			right 	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/compare"]]

		if all [
			op = COMP_STRICT_EQUAL
			TYPE_OF(value2) <> TYPE_CHAR
		][return 1]

		switch TYPE_OF(value2) [
			TYPE_INTEGER [
				integer: as red-integer! value2			;@@ could be optimized as integer! and char!
				right: integer/value					;@@ structures are overlapping exactly
			]
			TYPE_CHAR [
				right: value2/value
			]
			default [RETURN_COMPARE_OTHER]
		]
		left: value1/value
		SIGN_COMPARE_RESULT(left right)
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "char/add"]]
		do-math OP_ADD 
	]

	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "char/divide"]]
		do-math OP_DIV
	]

	multiply: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "char/multiply"]]
		do-math OP_MUL
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "char/remainder"]]
		do-math OP_REM
	]

	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "char/subtract"]]
		do-math OP_SUB
	]

	and~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "char/and~"]]
		do-math OP_AND
	]

	or~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "char/or~"]]
		do-math OP_OR
	]

	xor~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "char/xor~"]]
		do-math OP_XOR
	]

	init: does [
		datatype/register [
			TYPE_CHAR
			TYPE_INTEGER
			"char!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			null			;reflect
			INHERIT_ACTION	;to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			null			;absolute
			:add
			:divide
			:multiply
			null			;negate
			null			;power
			:remainder
			null			;round
			:subtract
			INHERIT_ACTION
			INHERIT_ACTION
			;-- Bitwise actions --
			:and~
			null			;complement
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