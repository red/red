Red/System [
	Title:   "Point3D! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %point3D.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

point3D: context [
	verbose: 0
	
	zero: as-float32 0.0
	
	get-named-index: func [
		w		[red-word!]
		ref		[red-value!]
		return: [integer!]
		/local
			axis [integer!]
	][
		axis: symbol/resolve w/symbol
		if all [axis <> words/x axis <> words/y axis <> words/z][
			either TYPE_OF(ref) = TYPE_POINT3D [
				fire [TO_ERROR(script cannot-use) w ref]
			][
				fire [TO_ERROR(script invalid-path) ref w]
			]
		]
		case [
			axis = words/x [1]
			axis = words/y [2]
			true		   [3]
		]
	]
	
	do-math: func [
		op		  [integer!]
		return:	  [red-point3D!]
		/local
			left  [red-point3D!]
			right [red-point3D!]
			int	  [red-integer!]
			fl	  [red-float!]
			p	  [red-pair!]
			x y z [float32!]
			f	  [float32!]
	][
		left: as red-point3D! stack/arguments
		right: left + 1
		z: as-float32 0.0
		
		assert TYPE_OF(left) = TYPE_POINT3D
		
		switch TYPE_OF(right) [
			TYPE_POINT3D [
				x: right/x
				y: right/y
				z: right/z
			]
			TYPE_INTEGER [
				int: as red-integer! right
				x: as-float32 int/value
				y: x
				z: x
			]
			TYPE_FLOAT TYPE_PERCENT [
				fl: as red-float! right
				f: as-float32 fl/value
				switch op [
					OP_MUL [
						left/x: left/x * f
						left/y: left/y * f
						left/z: left/z * f
						return left
					]
					OP_DIV [
						left/x: left/x / f
						left/y: left/y / f
						left/z: left/z / f
						return left
					]
					default [
						x: f
						y: x
						z: x
					]
				]
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]
		left/x: as-float32 float/do-math-op as-float left/x as-float x op null
		left/y: as-float32 float/do-math-op as-float left/y as-float y op null
		left/z: as-float32 float/do-math-op as-float left/z as-float z op null
		left
	]
	
	make-at: func [
		slot 	[red-value!]
		x 		[float32!]
		y 		[float32!]
		z 		[float32!]
		return: [red-point3D!]
		/local
			p [red-point3D!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/make-at"]]
		
		p: as red-point3D! slot
		set-type slot TYPE_POINT3D
		p/x: x
		p/y: y
		p/z: z
		p
	]
	
	make-in: func [
		parent 	[red-block!]
		x 		[float32!]
		y 		[float32!]
		z 		[float32!]
		return: [red-point3D!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/make-in"]]
		make-at ALLOC_TAIL(parent) x y z
	]
	
	push: func [
		x		[float32!]
		y		[float32!]
		z 		[float32!]
		return: [red-point3D!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/push"]]
		make-at stack/push* x y z
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
		return:	[red-point3D!]
		/local
			int	 [red-integer!]
			int2 [red-integer!]
			int3 [red-integer!]
			fl	 [red-float!]
			p	 [red-pair!]
			pt	 [red-point2D!]
			x	 [float32!]
			val	 [red-value! value]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				x: as-float32 int/value
				push x x x
			]
			TYPE_FLOAT [
				fl: as red-float! spec
				x: as-float32 fl/value
				push x x x
			]
			TYPE_BLOCK [
				int: as red-integer! block/rs-head as red-block! spec
				int2: int  + 1
				int3: int2 + 1
				if any [
					2 > block/rs-length? as red-block! spec
					all [TYPE_OF(int)  <> TYPE_INTEGER TYPE_OF(int)  <> TYPE_FLOAT]
					all [TYPE_OF(int2) <> TYPE_INTEGER TYPE_OF(int2) <> TYPE_FLOAT]
					all [TYPE_OF(int3) <> TYPE_INTEGER TYPE_OF(int3) <> TYPE_FLOAT]
				][
					fire [TO_ERROR(syntax malconstruct) spec]
				]
				push get-value-int int get-value-int int2 get-value-int int3
			]
			TYPE_PAIR [
				p: as red-pair! spec
				push as-float32 p/x as-float32 p/y as-float32 0.0
			]
			TYPE_POINT2D [
				pt: as red-point2D! spec
				push as-float32 p/x as-float32 p/y as-float32 0.0
			]			
			TYPE_STRING [
				copy-cell spec val					;-- save spec, load-value will change it
				proto: load-value as red-string! spec
				if TYPE_OF(proto) <> TYPE_POINT3D [
					fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_POINT3D val]
				]
				proto
			]
			TYPE_POINT3D [as red-point3D! spec]
			default [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_POINT3D spec]
				null
			]
		]
	]
	
	random: func [
		pt		[red-point3D!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			n	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/random"]]

		either seed? [
			_random/srand murmur3-x86-32 (as byte-ptr! pt) + 4 12
			pt/header: TYPE_UNSET
		][
			if pt/x <> as-float32 0.0 [
				pt/x: as-float32 float/rs-random as-float pt/x secure?
			]
			if pt/y <> as-float32 0.0 [
				pt/y: as-float32 float/rs-random as-float pt/y secure?
			]
			if pt/z <> as-float32 0.0 [
				pt/z: as-float32 float/rs-random as-float pt/z secure?
			]
		]
		as red-value! pt
	]
	
	form: func [
		pt		[red-point3D!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/form"]]

		string/append-char GET_BUFFER(buffer) as-integer #"("
		formed: float/form-float as-float pt/x float/FORM_POINT_32
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/concatenate-literal buffer ", "
		formed: float/form-float as-float pt/y float/FORM_POINT_32
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?

		string/concatenate-literal buffer ", "
		formed: float/form-float as-float pt/z float/FORM_POINT_32
		string/concatenate-literal buffer formed		
		
		string/append-char GET_BUFFER(buffer) as-integer #")"
		part - 6 - length? formed						;@@ optimize by removing length?
	]
	
	mold: func [
		pt		[red-point3D!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/mold"]]

		form pt buffer arg part
	]

	eval-path: func [
		parent	[red-point3D!]							;-- implicit type casting
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
			f32	 [float32!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/eval-path"]]
		
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				axis: int/value
				if any [axis < 1 axis > 3][
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
			f32: either TYPE_OF(int) = TYPE_INTEGER [
				int/header: TYPE_INTEGER
				as-float32 int/value
			][
				fp: as red-float! int
				fp/header: TYPE_FLOAT
				as-float32 fp/value
			]
			switch axis [
				1 [parent/x: f32]
				2 [parent/y: f32]
				3 [parent/z: f32]
				default [assert false]
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
			switch axis [
				1 [fp: float/push as-float parent/x]
				2 [fp: float/push as-float parent/y]
				3 [fp: float/push as-float parent/z]
				default [assert false]
			]
			stack/pop 1									;-- avoid moving stack top
			as red-value! fp
		]
	]
		
	compare: func [
		left	[red-point3D!]							;-- first operand
		right	[red-point3D!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			delta	[float32!]
			pt		[red-point3D! value]
			pair	[red-pair!]
			ip1 ip2 [int-ptr!]
			res		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/compare"]]

		if TYPE_OF(right) <> TYPE_POINT3D [RETURN_COMPARE_OTHER]

		;if TYPE_OF(right) = TYPE_PAIR [					;-- convert it to point3D
		;	pair: as red-pair! right
		;	pt/x: as float32! pair/x
		;	pt/y: as float32! pair/y
		;	right: :pt
		;]
		switch op [
			COMP_EQUAL
			COMP_NOT_EQUAL 	[
				either float/almost-equal as-float left/x as-float right/x [
					either float/almost-equal as-float left/y as-float right/y [
						res: as-integer not float/almost-equal as-float left/z as-float right/z
					][
						res: 1
					]
				][
					res: 1
				]
			]
			COMP_STRICT_EQUAL [
				either left/x = right/x [
					either left/y = right/y [
						res: as-integer not left/z = right/z
					][
						res: 1
					]
				][
					res: 1
				]
			] 
			COMP_SAME [
				ip1: :left/x
				ip2: :right/x
				res: as-integer any [ip1/1 <> ip2/1  ip1/2 <> ip2/2  ip1/3 <> ip2/3]
			]
			default [
				delta: left/x - right/x
				if float/almost-equal 0.0 as-float delta [delta: left/y - right/y]
				if float/almost-equal 0.0 as-float delta [delta: left/z - right/z]
				res: either delta < as float32! 0.0 [-1][either delta > as float32! 0.0 [1][0]]
			]
		]
		res
	]

	round: func [
		pt			[red-point3D!]
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
			p		[red-point3D!]
			scalexy?[logic!]
			y		[integer!]
			fy fz	[float!]
	][
		if TYPE_OF(fscale) = TYPE_MONEY [
			fire [TO_ERROR(script not-related) stack/get-call datatype/push TYPE_MONEY]
		]
		scalexy?: all [
			OPTION?(fscale)
			TYPE_OF(fscale) = TYPE_POINT3D
		]
		if scalexy? [
			p: as red-point3D! fscale
			fy: as float! p/y
			fz: as float! p/z
			fscale/header: TYPE_FLOAT
			fscale/value: as float! p/x
		]
		
		f/value: as float! pt/x
		float/round as red-value! f fscale _even? down? half-down? floor? ceil? half-ceil?
		pt/x: as float32! f/value
		
		if scalexy? [fscale/value: fy]
		f/value: as float! pt/y
		float/round as red-value! f fscale _even? down? half-down? floor? ceil? half-ceil?
		pt/y: as float32! f/value
		
		if scalexy? [fscale/value: fz]
		f/value: as float! pt/z
		float/round as red-value! f fscale _even? down? half-down? floor? ceil? half-ceil?
		pt/z: as float32! f/value
		
		as red-value! pt
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point3D/remainder"]]
		as red-value! do-math OP_REM
	]
	
	absolute: func [
		return: [red-point3D!]
		/local
			pt  [red-point3D!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/absolute"]]

		pt: as red-point3D! stack/arguments
		pt/x: as-float32 float/abs as-float pt/x
		pt/y: as-float32 float/abs as-float pt/y
		pt
	]
	
	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point3D/add"]]
		as red-value! do-math OP_ADD
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point3D/divide"]]
		as red-value! do-math OP_DIV
	]
		
	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point3D/multiply"]]
		as red-value! do-math OP_MUL
	]
	
	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "point3D/subtract"]]
		as red-value! do-math OP_SUB
	]
	
	negate: func [
		return: [red-point3D!]
		/local
			pt  [red-point3D!]
	][
		pt: as red-point3D! stack/arguments
		pt/x: as-float32 0.0 - pt/x
		pt/y: as-float32 0.0 - pt/y
		pt/z: as-float32 0.0 - pt/z
		pt
	]
	
	pick: func [
		pt		[red-point3D!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			f   [float32!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/pick"]]

		if TYPE_OF(boxed) = TYPE_WORD [index: get-named-index as red-word! boxed as red-value! pt]
		if all [index < 1 index > 3][fire [TO_ERROR(script out-of-range) boxed]]
		switch index [1 [f: pt/x] 2 [f: pt/y] 3 [f: pt/z] default [assert false]]
		as red-value! float/push as-float f
	]
	
	reverse: func [
		pt		[red-point3D!]
		part	[red-value!]
		skip    [red-value!]
		return:	[red-value!]
		/local
			tmp [float32!]
	][
		#if debug? = yes [if verbose > 0 [print-line "point3D/reverse"]]
	
		tmp: pt/x
		pt/x: pt/z
		pt/z: tmp
		as red-value! pt
	]

	init: does [
		datatype/register [
			TYPE_POINT3D
			TYPE_VALUE
			"point3D!"
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
