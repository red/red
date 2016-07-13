Red/System [
	Title:   "Pair! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %pair.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
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
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]
		
		switch type [
			OP_ADD [left/x: left/x + x  left/y: left/y + y]
			OP_SUB [left/x: left/x - x  left/y: left/y - y]
			OP_MUL [left/x: left/x * x  left/y: left/y * y]
			OP_DIV [left/x: left/x / x  left/y: left/y / y]
			OP_REM [left/x: left/x % x  left/y: left/y % y]
			OP_AND [left/x: left/x and x  left/y: left/y and y]
			OP_OR  [left/x: left/x or  x  left/y: left/y or  y]
			OP_XOR [left/x: left/x xor x  left/y: left/y xor y]
		]
		left
	]
	
	make-at: func [
		slot 	[red-value!]
		x 		[integer!]
		y 		[integer!]
		return: [red-pair!]
		/local
			pair [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make-at"]]
		
		pair: as red-pair! slot
		pair/header: TYPE_PAIR
		pair/x: x
		pair/y: y
		pair
	]
	
	make-in: func [
		parent 	[red-block!]
		x 		[integer!]
		y 		[integer!]
		return: [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make-in"]]
		make-at ALLOC_TAIL(parent) x y
	]
	
	push: func [
		x		[integer!]
		y		[integer!]
		return: [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/push"]]
		make-at stack/push* x y
	]

	;-- Actions --
	
	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-pair!]
		/local
			int	 [red-integer!]
			int2 [red-integer!]
			fl	 [red-float!]
			x	 [integer!]
			y	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				push int/value int/value
			]
			TYPE_BLOCK [
				int: as red-integer! block/rs-head as red-block! spec
				int2: int + 1
				if any [
					2 > block/rs-length? as red-block! spec
					all [TYPE_OF(int)  <> TYPE_INTEGER TYPE_OF(int)  <> TYPE_FLOAT]
					all [TYPE_OF(int2) <> TYPE_INTEGER TYPE_OF(int2) <> TYPE_FLOAT]
				][
					fire [TO_ERROR(syntax malconstruct) spec]
				]
				x: either TYPE_OF(int) = TYPE_FLOAT [
					fl: as red-float! int
					float/to-integer fl/value
				][
					int/value
				]
				y: either TYPE_OF(int2) = TYPE_FLOAT [
					fl: as red-float! int2
					float/to-integer fl/value
				][
					int2/value
				]	
				push x y
			]
			default [
				fire [TO_ERROR(script invalid-type) spec]
				push 0 0
			]
		]
	]
	
	random: func [
		pair	[red-pair!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			n	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/random"]]

		either seed? [
			_random/srand pair/x xor pair/y
			pair/header: TYPE_UNSET
		][
			unless zero? pair/x [
				n: _random/rand % pair/x + 1
				pair/x: either negative? pair/x [0 - n][n]
			]
			unless zero? pair/y [
				n: _random/rand % pair/y + 1
				pair/y: either negative? pair/y [0 - n][n]
			]
		]
		as red-value! pair
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
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			int	 [red-integer!]
			w	 [red-word!]
			axis [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/eval-path"]]
		
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				axis: int/value
				if all [axis <> 1 axis <> 2][
					fire [TO_ERROR(script invalid-path) stack/arguments element]
				]
			]
			TYPE_WORD [
				w: as red-word! element
				axis: symbol/resolve w/symbol
				if all [axis <> words/x axis <> words/y][
					fire [TO_ERROR(script invalid-path) stack/arguments element]
				]
				axis: either axis = words/x [1][2]
			]
			default [
				fire [TO_ERROR(script invalid-path) stack/arguments element]
			]
		]
		either value <> null [
			int: as red-integer! stack/arguments
			int/header: TYPE_INTEGER
			either axis = 1 [parent/x: int/value][parent/y: int/value]
			object/check-owner as red-value! parent
			as red-value! int
		][
			int: integer/push either axis = 1 [parent/x][parent/y]
			stack/pop 1									;-- avoid moving stack top
			int
		]
	]
	
	compare: func [
		left	[red-pair!]								;-- first operand
		right	[red-pair!]								;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			diff [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/compare"]]

		diff: left/y - right/y
		if zero? diff [diff: left/x - right/x]
		SIGN_COMPARE_RESULT(diff 0)
	]
	
	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/remainder"]]
		as red-value! do-math OP_REM
	]
	
	absolute: func [
		return: [red-pair!]
		/local
			pair [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/absolute"]]

		pair: as red-pair! stack/arguments
		pair/x: integer/abs pair/x
		pair/y: integer/abs pair/y
		pair
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
	
	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/and~"]]
		as red-value! do-math OP_AND
	]

	or~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/or~"]]
		as red-value! do-math OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/xor~"]]
		as red-value! do-math OP_XOR
	]
	
	negate: func [
		return: [red-pair!]
		/local
			pair [red-pair!]
	][
		pair: as red-pair! stack/arguments
		pair/x: 0 - pair/x
		pair/y: 0 - pair/y
		pair
	]
	
	pick: func [
		pair	[red-pair!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/pick"]]

		if all [index <> 1 index <> 2][fire [TO_ERROR(script out-of-range) boxed]]
		as red-value! integer/push either index = 1 [pair/x][pair/y]
	]
	
	reverse: func [
		pair	[red-pair!]
		part	[red-value!]
		return:	[red-value!]
		/local
			tmp [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/reverse"]]
	
		tmp: pair/x
		pair/x: pair/y
		pair/y: tmp
		as red-value! pair
	]
	
	init: does [
		datatype/register [
			TYPE_PAIR
			TYPE_VALUE
			"pair!"
			;-- General actions --
			:make
			:random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			null			;power
			:remainder
			null			;round
			:subtract
			null			;even?
			null			;odd?
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
			:pick
			null			;poke
			null			;put
			null			;remove
			:reverse
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
