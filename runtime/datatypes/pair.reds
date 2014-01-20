Red/System [
	Title:   "Pair! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %pair.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

pair: context [
	verbose: 0
	
	do-math: func [
		type	  [integer!]
		return:	  [red-pair!]
		/local
			left  [red-pair!]
			right [red-pair!]
			int	  [red-integer!]
			x	  [integer!]
			y	  [integer!]
	][
		left: as red-pair! stack/arguments
		right: left + 1
		
		assert TYPE_OF(left) = TYPE_PAIR
		assert any [
			TYPE_OF(right) = TYPE_PAIR
			TYPE_OF(right) = TYPE_INTEGER
		]
		
		switch TYPE_OF(right) [
			TYPE_PAIR 	 [
				x: right/x
				y: right/y
			]
			TYPE_INTEGER [
				int: as red-integer! right
				x: int/value
				y: x
			]
			default [
				print-line "*** Math Error: unsupported right operand for pair operation"
			]
		]
		
		switch type [
			OP_ADD [left/x: left/x + x  left/y: left/y + y]
			OP_SUB [left/x: left/x - x  left/y: left/y - y]
			OP_MUL [left/x: left/x * x  left/y: left/y * y]
			OP_DIV [left/x: left/x / x  left/y: left/y / y]
		]
		left
	]

	load-in: func [
		blk	  	[red-block!]
		x 		[integer!]
		y 		[integer!]
		/local
			pair [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/load-in"]]
		
		pair: as red-pair! ALLOC_TAIL(blk)
		pair/header: TYPE_PAIR
		pair/x: x
		pair/y: y
	]
	
	push: func [
		value	[integer!]
		value2  [integer!]
		return: [red-pair!]
		/local
			pair [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/push"]]
		
		pair: as red-pair! stack/push*
		pair/header: TYPE_PAIR
		pair/x: value
		pair/y: value2
		pair
	]

	;-- Actions --
	
	make: func [
		proto	 [red-value!]	
		spec	 [red-value!]
		return:	 [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make"]]

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
		pair	[red-pair!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/form"]]

		formed: integer/form-signed pair/x
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/append-char GET_BUFFER(buffer) as-integer #"x"
		
		formed: integer/form-signed pair/y
		string/concatenate-literal buffer formed
		part - 1 - length? formed						;@@ optimize by removing length?
	]
	
	mold: func [
		pair	[red-pair!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/mold"]]

		form pair buffer arg part
	]
	
	eval-path: func [
		parent	[red-pair!]								;-- implicit type casting
		element	[red-value!]
		set?	[logic!]
		return:	[red-value!]
		/local
			int	  [red-integer!]
			w	  [red-word!]
			value [integer!]
	][
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				value: int/value
				if all [value <> 1 value <> 2][
					print-line ["*** Path Error: pair! does not support accessor:" value]
				]
			]
			TYPE_WORD [
				w: as red-word! element
				value: symbol/resolve w/symbol
				if all [value <> words/x value <> words/y][
					print-line "*** Path Error: pair! does not support accessor:"
				]
				value: either value = words/x [1][2]
			]
			default [
				print-line "*** Path Error: unsupported pair! access path"
			]
		]
		either set? [
			int: as red-integer! stack/push*
			either value = 1 [parent/x: int/value][parent/y: int/value]
			as red-value! int
		][
			integer/push either value = 1 [parent/x][parent/y]
		]
	]
	
	compare: func [
		left	[red-pair!]								;-- first operand
		right	[red-pair!]								;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[logic!]
		/local
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/compare"]]
		
		switch op [
			COMP_EQUAL 			[res: all [left/x =  right/x left/y =  right/y]]
			COMP_NOT_EQUAL 		[res: any [left/x <> right/x left/y <> right/y]]
			COMP_STRICT_EQUAL	[res: all [left/x =  right/x left/y =  right/y]]
			COMP_LESSER			[res: all [left/x <  right/x left/y <  right/y]]
			COMP_LESSER_EQUAL	[res: all [left/x <= right/x left/y <= right/y]]
			COMP_GREATER		[res: all [left/x >  right/x left/y >  right/y]]
			COMP_GREATER_EQUAL	[res: all [left/x >= right/x left/y >= right/y]]
		]
		res
	]
	
	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/add"]]
		as red-value! do-math OP_ADD
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/divide"]]
		as red-value! do-math OP_DIV
	]
		
	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/multiply"]]
		as red-value! do-math OP_MUL
	]
	
	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/subtract"]]
		as red-value! do-math OP_SUB
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
	
	init: does [
		datatype/register [
			TYPE_PAIR
			TYPE_VALUE
			"pair!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
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