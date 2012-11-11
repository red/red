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

	push: func [
		value	 [integer!]
		/local
			cell [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/push"]]
		cell: as red-char! stack/push
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
		char: as red-char! stack/push
		char/header: TYPE_CHAR
		char/value: value
		char
	]
	
	form: func [
		arg	    [red-char!]
		buffer  [red-string!]
		part    [integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/form"]]

		string/append-char GET_BUFFER(buffer) arg/value
		part - 1
	]
	
	mold: func [
		arg	   [red-char!]
		buffer [red-string!]
		part   [integer!]
		flags  [integer!]								;-- 0: /only, 1: /all, 2: /flat
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/mold"]]

		string/concatenate-literal buffer {#"}
		string/append-char GET_BUFFER(buffer) arg/value
		string/append-char GET_BUFFER(buffer) as-integer #"^""
		part											;@@ implement full support for /part
	]

	compare: func [
		value1    	[red-char!]							;-- first operand
		value2    	[red-char!]							;-- second operand
		op	      	[integer!]							;-- type of comparison
		return:   	[logic!]
		/local
			integer [red-integer!]
			type 	[integer!]
			left  	[integer!]
			right 	[integer!]
			res	  	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/compare"]]

		type: TYPE_OF(value2)
		left: value1/value

		switch type [
			TYPE_INTEGER [
				integer: as red-integer! value2			;@@ could be optimized as integer! and char!
				right: integer/value					;@@ structures are overlapping exactly
			]
			TYPE_CHAR [
				right: value2/value
			]
			default [									;@@ Throw error! when ready
				either op = COMP_EQUAL [
					return false
				][
					print-line ["Error: cannot compare char! with type #" type]
					halt
				]
			]
		]
		switch op [
			COMP_EQUAL 			[res: left = right]
			COMP_STRICT_EQUAL	[res: all [type = TYPE_CHAR left = right]]
			COMP_LESSER			[res: left <  right]
			COMP_LESSER_EQUAL	[res: left <= right]
			COMP_GREATER		[res: left >  right]
			COMP_GREATER_EQUAL	[res: left >= right]
		]
		res
	]

	add: func [
		return:  [red-value!]
		/local
			char [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/add"]]
		char: as red-char! integer/do-math OP_ADD
		char/header: TYPE_CHAR
		as red-value! char 
	]

	divide: func [
		return:  [red-value!]
		/local
			char [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/divide"]]
		char: as red-char! integer/do-math OP_DIV
		char/header: TYPE_CHAR
		as red-value! char 
	]

	multiply: func [
		return:  [red-value!]
		/local
			char [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/multiply"]]
		char: as red-char! integer/do-math OP_MUL
		char/header: TYPE_CHAR
		as red-value! char 
	]

	subtract: func [
		return:  [red-value!]
		/local
			char [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/subtract"]]
		char: as red-char! integer/do-math OP_SUB
		char/header: TYPE_CHAR
		as red-value! char 
	]

	datatype/register [
		TYPE_CHAR
		TYPE_VALUE
		"char"
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