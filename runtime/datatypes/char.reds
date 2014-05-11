Red/System [
	Title:   "Char! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %char.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

char: context [
	verbose: 0
	
	do-math: func [
		op		[math-op!]
		return: [red-value!]
		/local
			char [red-char!]
	][
		char: as red-char! integer/do-math op
		char/header: TYPE_CHAR
		
		if char/value > 0010FFFFh [
			print-line "*** Math Error: char overflow"
		]
		as red-value! char
	]
	
	load-in: func [
		value [integer!]
		blk	  [red-block!]
		/local
			cell [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/load-in"]]

		cell: as red-char! ALLOC_TAIL(blk)
		cell/header: TYPE_CHAR
		cell/value: value
	]

	push: func [
		value	 [integer!]
		/local
			cell [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/push"]]
		cell: as red-char! stack/push*
		cell/header: TYPE_CHAR
		cell/value: value
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
		return:   	[logic!]
		/local
			integer [red-integer!]
			left  	[integer!]
			right 	[integer!]
			res	  	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/compare"]]

		left: value1/value

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
		switch op [
			COMP_EQUAL 			[res: left = right]
			COMP_NOT_EQUAL 		[res: left <> right]
			COMP_STRICT_EQUAL	[res: all [TYPE_OF(value2) = TYPE_CHAR left = right]]
			COMP_LESSER			[res: left <  right]
			COMP_LESSER_EQUAL	[res: left <= right]
			COMP_GREATER		[res: left >  right]
			COMP_GREATER_EQUAL	[res: left >= right]
		]
		res
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
			null			;to
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