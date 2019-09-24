Red/System [
	Title:   "Pair! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %pair.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

pair: context [
	verbose: 0
	
	do-math: func [
		op		  [integer!]
		return:	  [red-pair!]
		/local
			left  [red-pair!]
			right [red-pair!]
			int	  [red-integer!]
			fl	  [red-float!]
			x	  [float!]
			y	  [float!]
			f	  [float32!]
	][
		left: as red-pair! stack/arguments
		right: left + 1
		
		assert TYPE_OF(left) = TYPE_PAIR
		
		switch TYPE_OF(right) [
			TYPE_PAIR 	 [
				x: as float! right/x
				y: as float! right/y
			]
			TYPE_INTEGER [
				int: as red-integer! right
				x: as-float int/value
				y: x
			]
			TYPE_FLOAT TYPE_PERCENT [
				fl: as red-float! right
				f: as-float32 fl/value
				switch op [
					OP_MUL [
						left/x: left/x * f
						left/y: left/y * f
						return left
					]
					OP_DIV [
						left/x: left/x / f
						left/y: left/y / f
						return left
					]
					default [
						x: fl/value
						y: x
					]
				]
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]
		left/x: as-float32 float/do-math-op as-float left/x x op
		left/y: as-float32 float/do-math-op as-float left/y y op
		left
	]
	
	make-at: func [
		slot 	[red-value!]
		x 		[float32!]
		y 		[float32!]
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
		x 		[float32!]
		y 		[float32!]
		return: [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make-in"]]
		make-at ALLOC_TAIL(parent) x y
	]
	
	push: func [
		x		[float32!]
		y		[float32!]
		return: [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/push"]]
		make-at stack/push* x y
	]

	push-int: func [
		x		[integer!]
		y		[integer!]
		return: [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/push-int"]]
		make-at stack/push* as float32! x as float32! y
	]

	get-float32: func [
		int		[red-integer!]
		return: [float32!]
		/local
			fl	[red-float!]
	][
		either TYPE_OF(int) = TYPE_FLOAT [
			fl: as red-float! int
			as-float32 fl/value
		][
			as-float32 int/value
		]
	]

	;-- Actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-pair!]
		/local
			int	 [red-integer!]
			int2 [red-integer!]
			fl	 [red-float!]
			x	 [float32!]
			y	 [float32!]
			cell [integer!]
			val	 [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				x: as-float32 int/value
				push x x
			]
			TYPE_FLOAT [
				fl: as red-float! spec
				x: as-float32 fl/value
				push x x
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
				push get-float32 int get-float32 int2
			]
			TYPE_STRING [
				cell: 0
				val: as red-value! :cell
				copy-cell spec val					;-- save spec, load-value will change it

				proto: load-value as red-string! spec
				if TYPE_OF(proto) <> TYPE_PAIR [
					fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_PAIR val]
				]
				proto
			]
			TYPE_PAIR [as red-pair! spec]
			default [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_PAIR spec]
				push-int 0 0
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
			n	[float32!]
			x	[integer!]
			y	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/random"]]

		x: as-integer pair/x
		y: as-integer pair/y
		either seed? [
			_random/srand x xor y
			pair/header: TYPE_UNSET
		][
			n: (as-float32 _random/rand) / as-float32 2147483648.0
			unless zero? x [pair/x: pair/x * n]
			unless zero? y [pair/y: pair/y * n]
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

		formed: float/form-float as-float pair/x float/FORM_TIME
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/append-char GET_BUFFER(buffer) as-integer #"x"
		
		formed: float/form-float as-float pair/y float/FORM_TIME
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
			int  [red-integer!]
			w	 [red-word!]
			axis [integer!]
			type [integer!]
			f32  [float32!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/eval-path"]]
		
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				axis: int/value
				if all [axis <> 1 axis <> 2][
					fire [TO_ERROR(script invalid-path) path element]
				]
			]
			TYPE_WORD [
				w: as red-word! element
				axis: symbol/resolve w/symbol
				if all [axis <> words/x axis <> words/y][
					fire [TO_ERROR(script invalid-path) path element]
				]
				axis: either axis = words/x [1][2]
			]
			default [
				fire [TO_ERROR(script invalid-path) path element]
			]
		]

		either value <> null [
			type: TYPE_OF(value)
			if all [type <> TYPE_INTEGER type <> TYPE_FLOAT] [
				fire [TO_ERROR(script invalid-type) datatype/push type]
			]

			f32: get-float32 as red-integer! value
			either axis = 1 [parent/x: f32][parent/y: f32]
			object/check-owner as red-value! parent
		][
			f32: either axis = 1 [parent/x][parent/y]
			value: as red-value! float/push as-float f32
			stack/pop 1			;-- avoid moving stack top
		]
		value
	]
	
	compare: func [
		left	[red-pair!]								;-- first operand
		right	[red-pair!]								;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			diff [float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/compare"]]

		if TYPE_OF(right) <> TYPE_PAIR [RETURN_COMPARE_OTHER]
		diff: as-float left/x - right/x
		if diff = 0.0 [diff: as float! left/y - right/y]
		SIGN_COMPARE_RESULT(diff 0.0)
	]

	round: func [
		value		[red-value!]
		scale		[red-float!]
		_even?		[logic!]
		down?		[logic!]
		half-down?	[logic!]
		floor?		[logic!]
		ceil?		[logic!]
		half-ceil?	[logic!]
		return:		[red-value!]
		/local
			pair	[red-pair!]
			val		[red-float! value]
	][
		pair: as red-pair! value
		val/header: TYPE_FLOAT
		val/value: as-float pair/x
		pair/x: as-float32 float/round as red-value! val scale _even? down? half-down? floor? ceil? half-ceil?
		val/value: as-float pair/y
		pair/y: as-float32 float/round as red-value! val scale _even? down? half-down? floor? ceil? half-ceil?
		value
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
		pair/x: as float32! float/abs as-float pair/x		;@@ TBD: optimize it
		pair/y: as float32! float/abs as-float pair/y
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
		pair/x: (as-float32 0.0) - pair/x
		pair/y: (as-float32 0.0) - pair/y
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
		as red-value! float/push as-float either index = 1 [pair/x][pair/y]
	]
	
	reverse: func [
		pair	[red-pair!]
		part	[red-value!]
		return:	[red-value!]
		/local
			tmp [float32!]
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
			:make			;to
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
			:round
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
