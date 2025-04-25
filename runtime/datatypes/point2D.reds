Red/System [
	Title:   "Point2D! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %point2D.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

point2D: context [
	verbose: 0
	
	get-named-index: func [
		w		[red-word!]
		ref		[red-value!]
		return: [integer!]
		/local
			axis [integer!]
	][
		axis: symbol/resolve w/symbol
		if all [axis <> words/x axis <> words/y][
			either TYPE_OF(ref) = TYPE_POINT2D [
				fire [TO_ERROR(script cannot-use) w ref]
			][
				fire [TO_ERROR(script invalid-path) ref w]
			]
		]
		either axis = words/x [1][2]
	]
	
	do-math: func [
		op		  [integer!]
		return:	  [red-point2D!]
		/local
			left  [red-point2D!]
			right [red-point2D!]
			int	  [red-integer!]
			fl	  [red-float!]
			p	  [red-pair!]
			x	  [float32!]
			y	  [float32!]
			f	  [float32!]
	][
		left: as red-point2D! stack/arguments
		right: left + 1
		
		assert TYPE_OF(left) = TYPE_POINT2D
		
		switch TYPE_OF(right) [
			TYPE_POINT2D [
				x: right/x
				y: right/y
			]
			TYPE_PAIR [
				p: as red-pair! right
				x: as-float32 p/x
				y: as-float32 p/y
			]
			TYPE_INTEGER [
				int: as red-integer! right
				x: as-float32 int/value
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
						x: f
						y: x
					]
				]
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]
		left/x: as-float32 float/do-math-op as-float left/x as-float x op null
		left/y: as-float32 float/do-math-op as-float left/y as-float y op null
		left
	]
	
	make-at: func [
		slot 	[red-value!]
		x 		[float32!]
		y 		[float32!]
		return: [red-point2D!]
		/local
			p [red-point2D!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/make-at"]]
		
		p: as red-point2D! slot
		set-type slot TYPE_POINT2D
		p/x: x
		p/y: y
		p
	]
	
	make-in: func [
		parent 	[red-block!]
		x 		[float32!]
		y 		[float32!]
		return: [red-point2D!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/make-in"]]
		make-at ALLOC_TAIL(parent) x y
	]
	
	push: func [
		x		[float32!]
		y		[float32!]
		return: [red-point2D!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/push"]]
		make-at stack/push* x y
	]

	get-value-int: func [
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
		return:	[red-point2D!]
		/local
			int	 [red-integer!]
			int2 [red-integer!]
			fl	 [red-float!]
			p	 [red-pair!]
			x	 [float32!]
			val	 [red-string! value]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/make"]]

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
				push get-value-int int get-value-int int2
			]
			TYPE_PAIR [
				p: as red-pair! spec
				push as-float32 p/x as-float32 p/y
			]
			TYPE_STRING [
				copy-cell spec as red-value! val		;-- save spec, load-value will change it
				proto: load-value as red-string! spec
				if TYPE_OF(proto) <> TYPE_POINT2D [
					fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_POINT2D val]
				]
				proto
			]
			TYPE_POINT2D [as red-point2D! spec]
			default [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_POINT2D spec]
				null
			]
		]
	]
	
	random: func [
		point2D	[red-point2D!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			n	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/random"]]

		either seed? [
			_random/srand murmur3-x86-32 (as byte-ptr! point2D) + 4 8
			point2D/header: TYPE_UNSET
		][
			if point2D/x <> as-float32 0.0 [
				point2D/x: as-float32 float/rs-random as-float point2D/x secure?
			]
			if point2D/y <> as-float32 0.0 [
				point2D/y: as-float32 float/rs-random as-float point2D/y secure?
			]
		]
		as red-value! point2D
	]
	
	form: func [
		point2D	[red-point2D!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/form"]]

		string/append-char GET_BUFFER(buffer) as-integer #"("
		formed: float/form-float as-float point2D/x float/FORM_POINT_32
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/concatenate-literal buffer ", "
		
		formed: float/form-float as-float point2D/y float/FORM_POINT_32
		string/concatenate-literal buffer formed
		string/append-char GET_BUFFER(buffer) as-integer #")"
		part - 4 - length? formed						;@@ optimize by removing length?
	]
	
	mold: func [
		point2D	[red-point2D!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/mold"]]

		form point2D buffer arg part
	]

	eval-path: func [
		parent	[red-point2D!]								;-- implicit type casting
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
			fp	 [red-float!]
			axis [integer!]
			type [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/eval-path"]]
		
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
			if all [type <> TYPE_INTEGER type <> TYPE_FLOAT][
				fire [TO_ERROR(script invalid-type) datatype/push type]
			]
			if evt? [old: stack/push as red-value! parent]
			
			int: as red-integer! stack/arguments
			either TYPE_OF(int) = TYPE_INTEGER [
				int/header: TYPE_INTEGER
				either axis = 1 [parent/x: as-float32 int/value][parent/y: as-float32 int/value]
			][
				fp: as red-float! int
				fp/header: TYPE_FLOAT
				either axis = 1 [parent/x: as-float32 fp/value][parent/y: as-float32 fp/value]
			]
			if evt? [
				either TYPE_OF(gparent) = TYPE_OBJECT [
					object/fire-on-set as red-object! gparent as red-word! p-item old as red-value! parent
				][
					ownership/check as red-value! gparent words/_set-path value axis 1
				]
				stack/pop 1								;-- avoid moving stack top
			]
			stack/arguments
		][
			fp: either axis = 1 [float/push as-float parent/x][float/push as-float parent/y]
			stack/pop 1									;-- avoid moving stack top
			as red-value! fp
		]
	]
		
	compare: func [
		left	[red-point2D!]							;-- first operand
		right	[red-point2D!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			delta	[float32!]
			pt		[red-point2D!]
			pair	[red-pair!]
			ip1 ip2 [int-ptr!]
			res		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/compare"]]

		if TYPE_OF(right) = TYPE_PAIR [					;-- convert it to point2d
			pair: as red-pair! right
			pt: as red-point2D! stack/push*
			pt/header: TYPE_POINT2D
			pt/x: as float32! pair/x
			pt/y: as float32! pair/y
			right: pt
		]
		if TYPE_OF(right) <> TYPE_POINT2D [RETURN_COMPARE_OTHER]

		switch op [
			COMP_EQUAL
			COMP_NOT_EQUAL 	[
				either float/almost-equal32 left/x right/x [
					res: as-integer not float/almost-equal32 left/y right/y
				][
					res: 1
				]
			]
			COMP_STRICT_EQUAL [
				either left/x = right/x [
					res: as-integer not left/y = right/y
				][
					res: 1
				]
			] 
			COMP_SAME [
				ip1: :left/x
				ip2: :right/x
				res: as-integer any [ip1/1 <> ip2/1  ip1/2 <> ip2/2]
			]
			default [
				delta: left/x - right/x
				if float/almost-equal32 0.0 delta [delta: left/y - right/y]
				res: either delta < as float32! 0.0 [-1][either delta > as float32! 0.0 [1][0]]
			]
		]
		res
	]

	round: func [
		point2D		[red-point2D!]
		fscale		[red-float!]
		_even?		[logic!]
		down?		[logic!]
		half-down?	[logic!]
		floor?		[logic!]
		ceil?		[logic!]
		half-ceil?	[logic!]
		return:		[red-value!]
		/local
			f		[red-float! value]
			scale	[red-integer!]
			pair	[red-pair!]
			p		[red-point2D!]
			scalexy?[logic!]
			y		[integer!]
			fy		[float!]
	][
		if TYPE_OF(fscale) = TYPE_MONEY [
			fire [TO_ERROR(script not-related) stack/get-call datatype/push TYPE_MONEY]
		]
		scalexy?: all [
			OPTION?(fscale)
			any [TYPE_OF(fscale) = TYPE_POINT2D TYPE_OF(fscale) = TYPE_PAIR TYPE_OF(fscale) = TYPE_POINT3D]
		]
		if scalexy? [
			either TYPE_OF(fscale) = TYPE_PAIR [
				pair: as red-pair! fscale
				y: pair/y
				scale: as red-integer! fscale
				scale/header: TYPE_INTEGER
				scale/value: pair/x
			][
				p: as red-point2D! fscale
				fy: as float! p/y
				fscale/header: TYPE_FLOAT
				fscale/value: as float! p/x
			]
		]
		
		f/value: as float! point2D/x
		float/round as red-value! f fscale _even? down? half-down? floor? ceil? half-ceil?
		point2D/x: as float32! f/value
		
		if scalexy? [
			either TYPE_OF(fscale) = TYPE_INTEGER [
				scale/value: y
			][
				fscale/value: fy
			]
		]
		f/value: as float! point2D/y
		float/round as red-value! f fscale _even? down? half-down? floor? ceil? half-ceil?
		point2D/y: as float32! f/value
		
		as red-value! point2D
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point2D/remainder"]]
		as red-value! do-math OP_REM
	]
	
	absolute: func [
		return: [red-point2D!]
		/local
			point2D [red-point2D!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/absolute"]]

		point2D: as red-point2D! stack/arguments
		point2D/x: as-float32 float/abs as-float point2D/x
		point2D/y: as-float32 float/abs as-float point2D/y
		point2D
	]
	
	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point2D/add"]]
		as red-value! do-math OP_ADD
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point2D/divide"]]
		as red-value! do-math OP_DIV
	]
		
	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point2D/multiply"]]
		as red-value! do-math OP_MUL
	]
	
	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point2D/subtract"]]
		as red-value! do-math OP_SUB
	]
	
	negate: func [
		return: [red-point2D!]
		/local
			point2D [red-point2D!]
	][
		point2D: as red-point2D! stack/arguments
		point2D/x: as-float32 0.0 - point2D/x
		point2D/y: as-float32 0.0 - point2D/y
		point2D
	]
	
	pick: func [
		point2D	[red-point2D!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			f   [float32!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/pick"]]

		if TYPE_OF(boxed) = TYPE_WORD [index: get-named-index as red-word! boxed as red-value! point2D]
		if all [index <> 1 index <> 2][fire [TO_ERROR(script out-of-range) boxed]]
		f: either index = 1 [point2D/x][point2D/y]
		as red-value! float/push as-float f
	]
	
	reverse: func [
		point2D	[red-point2D!]
		part	[red-value!]
		skip    [red-value!]
		return:	[red-value!]
		/local
			tmp [float32!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point2D/reverse"]]
	
		tmp: point2D/x
		point2D/x: point2D/y
		point2D/y: tmp
		as red-value! point2D
	]

	init: does [
		datatype/register [
			TYPE_POINT2D
			TYPE_VALUE
			"point2D!"
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
