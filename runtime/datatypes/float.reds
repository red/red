Red/System [
	Title:   "Float! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %float.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

float: context [
	verbose: 0

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
		fl: as red-integer! stack/arguments
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
	
;	form-signed: func [									;@@ replace with sprintf() call?
;		i 		[integer!]
;		return: [c-string!]
;		/local 
;			s	[c-string!]
;			c 	[integer!]
;			n 	[logic!]
;	][
;		s: "-0000000000"								;-- 11 bytes wide	
;		if zero? i [									;-- zero special case
;			s/11: #"0"
;			return s + 10
;		]
;		if i = -2147483648 [							;-- min integer special case
;			return "-2147483648"
;		]
;		n: negative? i
;		if n [i: negate i]
;		c: 11
;		while [i <> 0][
;			s/c: #"0" + (i // 10)
;			i: i / 10
;			c: c - 1
;		]
;		if n [s/c: #"-" c: c - 1]
;		s + c
;	]
	
	do-math: func [
		type	  [integer!]
		return:	  [red-float!]
		/local
			args  [red-value!]
			left  [red-float!]
			right [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/do-math"]]
		
		args: stack/arguments
		left:  as red-float! args
		right: as red-float! args + 1
		
		assert TYPE_OF(left) = TYPE_FLOAT
		assert TYPE_OF(right) = TYPE_FLOAT
		
		left/value: switch type [
			OP_ADD [left/value + right/value]
			OP_SUB [left/value - right/value]
			OP_MUL [left/value * right/value]
			OP_DIV [left/value / right/value]
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
		
		formed: "" ;form-signed fl/value
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
			char  [red-char!]
			left  [float!]
			right [float!] 
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/compare"]]
		
		left: value1/value
		
		switch TYPE_OF(value2) [
			TYPE_FLOAT [
				right: value2/value
			]
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
		fl/value: not fl/value
		as red-value! int
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
	
	negate: func [
		return: [red-float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		fl/value: 0 - fl/value
		fl 											;-- re-use argument slot for return value
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
			:negate
			null			;power
			null			;remainder
			null			;round
			:subtract
			:even?
			:odd?
			;-- Bitwise actions --
			null			;and~
			:complement
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