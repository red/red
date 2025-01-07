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
	
	#enum operand! [LEFT_OP RIGHT_OP]
	
	get-named-index: func [
		w		[red-word!]
		ref		[red-value!]
		return: [integer!]
		/local
			axis [integer!]
	][
		axis: symbol/resolve w/symbol
		if all [axis <> words/x axis <> words/y][
			either TYPE_OF(ref) = TYPE_PAIR [
				fire [TO_ERROR(script cannot-use) w ref]
			][
				fire [TO_ERROR(script invalid-path) ref w]
			]
		]
		either axis = words/x [1][2]
	]
	
	do-math: func [
		op		  [integer!]
		return:	  [red-pair!]
		/local
			left  [red-pair!]
			right [red-pair!]
			int	  [red-integer!]
			fl	  [red-float!]
			slot  [red-integer! value]
			x y	  [integer!]
			x' y' [integer!]
			f n   [float!]
			promo [subroutine!]
	][
		promo: [
			right/x: x
			right/y: y
			promote LEFT_OP
			promote RIGHT_OP
			return as red-pair! point2D/do-math op
		]
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
			TYPE_POINT2D [
				promote LEFT_OP
				return as red-pair! point2D/do-math op
			]
			TYPE_FLOAT TYPE_PERCENT [
				fl: as red-float! right
				f: fl/value
				switch op [
					OP_MUL [
						if float/special? f [fire [TO_ERROR(script invalid-arg) right]]
						left/x: as-integer (as-float left/x) * f
						left/y: as-integer (as-float left/y) * f
						return left
					]
					OP_DIV [
						if float/NaN? f [fire [TO_ERROR(script invalid-arg) right]]
						left/x: as-integer (as-float left/x) / f
						left/y: as-integer (as-float left/y) / f
						return left
					]
					default [
						if float/special? f [fire [TO_ERROR(script invalid-arg) right]]
						x: as-integer f
						y: x
					]
				]
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]
		slot/header: TYPE_UNSET
		x': integer/do-math-op left/x x op slot
		if TYPE_OF(slot) <> TYPE_UNSET [promo]
		left/x: x'
		
		y': integer/do-math-op left/y y op slot
		if TYPE_OF(slot) <> TYPE_UNSET [promo]
		left/y: y'
		left
	]
	
	promote: func [
		arg [operand!]
		/local
			p  [red-pair!]
			pt [red-point2D!]
	][
		p: as red-pair! stack/arguments + arg
		pt: as red-point2D! p
		pt/header: TYPE_POINT2D
		pt/x: as-float32 p/x
		pt/y: as-float32 p/y
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
		set-type slot TYPE_PAIR
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

	get-value-int: func [
		int		[red-integer!]
		return: [integer!]
		/local
			fl	[red-float!]
	][
		either TYPE_OF(int) = TYPE_FLOAT [
			fl: as red-float! int
			as-integer fl/value
		][
			int/value
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
			p	 [red-point2D!]
			x	 [integer!]
			y	 [integer!]
			val	 [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				push int/value int/value
			]
			TYPE_FLOAT [
				fl: as red-float! spec
				x: as-integer fl/value
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
				x: get-value-int int
				y: get-value-int int2
				push x y
			]
			TYPE_POINT2D [
				p: as red-point2D! spec
				if any [
					float/special? as-float p/x
					float/special? as-float p/y
				][
					fire [TO_ERROR(script invalid-arg) spec]
				]
				push as-integer p/x as-integer p/y
			]
			TYPE_STRING [
				y: 0
				val: as red-value! :y
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
				null
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
				pair/x: _random/int-uniform-distr secure? pair/x
			]
			unless zero? pair/y [
				pair/y: _random/int-uniform-distr secure? pair/y
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
		gparent [red-value!]
		p-item	[red-value!]
		index	[integer!]
		case?	[logic!]
		get?	[logic!]
		tail?	[logic!]
		evt?	[logic!]
		return:	[red-value!]
		/local
			old	 [red-value!]
			int	 [red-integer!]
			axis [integer!]
			type [integer!]
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
			TYPE_WORD [axis: get-named-index as red-word! element path]
			default	  [fire [TO_ERROR(script invalid-path) path element]]
		]
		either value <> null [
			type: TYPE_OF(value)
			if type <> TYPE_INTEGER [
				fire [TO_ERROR(script invalid-type) datatype/push type]
			]
			if evt? [old: stack/push as red-value! parent]
			
			int: as red-integer! stack/arguments
			int/header: TYPE_INTEGER
			either axis = 1 [parent/x: int/value][parent/y: int/value]
			if evt? [
				either TYPE_OF(gparent) = TYPE_OBJECT [
					object/fire-on-set as red-object! gparent as red-word! p-item old as red-value! parent
				][
					ownership/check as red-value! gparent words/_set-path value axis 1
				]
				stack/pop 1								;-- avoid moving stack top
			]
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
			tmp  [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/compare"]]

		if TYPE_OF(right) = TYPE_POINT2D [				;-- promote left to point2D in such case
			promote LEFT_OP
			return point2D/compare as red-point2D! left as red-point2D! right op
		]
		if TYPE_OF(right) <> TYPE_PAIR [RETURN_COMPARE_OTHER]
		diff: left/x - right/x
		if zero? diff [diff: left/y - right/y]
		SIGN_COMPARE_RESULT(diff 0)
	]

	round: func [
		pair		[red-pair!]
		scale		[red-integer!]
		_even?		[logic!]
		down?		[logic!]
		half-down?	[logic!]
		floor?		[logic!]
		ceil?		[logic!]
		half-ceil?	[logic!]
		return:		[red-value!]
		/local
			int		[red-integer!]
			value	[red-value!]
			p		[red-pair!]
			scalexy?[logic!]
			y		[integer!]
	][
		if TYPE_OF(scale) = TYPE_MONEY [
			fire [TO_ERROR(script not-related) stack/get-call datatype/push TYPE_MONEY]
		]
		scalexy?: all [OPTION?(scale) TYPE_OF(scale) = TYPE_PAIR]
		if scalexy? [
			p: as red-pair! scale
			y: p/y
			scale/header: TYPE_INTEGER
			scale/value: p/x
		]
		
		int: integer/push pair/x
		value: integer/round as red-value! int scale _even? down? half-down? floor? ceil? half-ceil?
		pair/x: get-value-int as red-integer! value
		
		if scalexy? [scale/value: y]
		int/value: pair/y
		value: integer/round as red-value! int scale _even? down? half-down? floor? ceil? half-ceil?
		pair/y: get-value-int as red-integer! value
		
		as red-value! pair
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

		if TYPE_OF(boxed) = TYPE_WORD [index: get-named-index as red-word! boxed as red-value! pair]
		if all [index <> 1 index <> 2][fire [TO_ERROR(script out-of-range) boxed]]
		as red-value! integer/push either index = 1 [pair/x][pair/y]
	]
	
	reverse: func [
		pair	[red-pair!]
		part	[red-value!]
		skip    [red-value!]
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
