Red/System [
	Title:   "Integer! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %integer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

integer: context [
	verbose: 0
	
	overflow?: func [
		fl		[red-float!]
		return: [logic!]
	][
		any [fl/value > 2147483647.0 fl/value < -2147483648.0]
	]

	abs: func [
		value	[integer!]
		return: [integer!]
	][
		if value = -2147483648 [
			fire [TO_ERROR(math overflow)]
		]
		if negative? value [value: 0 - value]
		value
	]

	get*: func [										;-- unboxing integer value from stack
		return: [integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments
		assert TYPE_OF(int) = TYPE_INTEGER
		int/value
	]
	
	get-any*: func [									;-- special get* variant for SWITCH
		return: [integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments
		either TYPE_OF(int) = TYPE_INTEGER [int/value][0] ;-- accept NONE values
	]
	
	get: func [											;-- unboxing integer value
		value	[red-value!]
		return: [integer!]
		/local
			int [red-integer!]
	][
		assert TYPE_OF(value) = TYPE_INTEGER
		int: as red-integer! value
		int/value
	]
	
	box: func [
		value	[integer!]
		return: [red-integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments
		int/header: TYPE_INTEGER
		int/value: value
		int
	]
	
	from-binary: func [
		bin		[red-binary!]
		return: [integer!]
		/local
			s	   [series!]
			p	   [byte-ptr!]
			len	   [integer!]
			i	   [integer!]
			factor [integer!]
	][
		s: GET_BUFFER(bin)
		len: (as-integer s/tail - s/offset) + bin/head
		if len > 4 [len: 4]								;-- take first 32 bits only

		i: 0
		factor: 0
		p: (as byte-ptr! s/offset) + bin/head + len - 1

		loop len [
			i: i + ((as-integer p/value) << factor)
			factor: factor + 8
			p: p - 1
		]
		i
	]

	from-issue: func [
		issue	[red-word!]
		return: [integer!]
		/local
			len  [integer!]
			str  [red-string!]
			bin  [red-binary!]
			s	 [series!]
			unit [integer!]
	][
		str: as red-string! stack/push as red-value! symbol/get issue/symbol
		str/head: 0								;-- /head = -1 (casted from symbol!)
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		len: string/rs-length? str
		if len > 8 [len: 8]

		str/node: binary/decode-16 
			(as byte-ptr! s/offset) + (str/head << (unit >> 1))
			len
			unit
		if null? str/node [fire [TO_ERROR(script invalid-data) issue]]
		len: from-binary as red-binary! str
		stack/pop 1
		len
	]

	form-signed: func [									;@@ replace with sprintf() call?
		i 		[integer!]
		return: [c-string!]
		/local 
			s	[c-string!]
			c 	[integer!]
			n 	[logic!]
	][
		s: "-0000000000"								;-- 11 bytes wide	
		if zero? i [									;-- zero special case
			s/11: #"0"
			return s + 10
		]
		if i = -2147483648 [							;-- min integer special case
			return "-2147483648"
		]
		n: negative? i
		if n [i: 0 - i]
		c: 11
		while [i <> 0][
			s/c: #"0" + (i // 10)
			i: i / 10
			c: c - 1
		]
		if n [s/c: #"-" c: c - 1]
		s + c
	]

	do-math-op: func [
		left	[integer!]
		right	[integer!]
		type	[math-op!]
		return:	[integer!]
		/local
			res [integer!]
	][
		switch type [
			OP_ADD [
				res: left + right
				if system/cpu/overflow? [fire [TO_ERROR(math overflow)]]
				res
			]
			OP_SUB [
				res: left - right
				if system/cpu/overflow? [fire [TO_ERROR(math overflow)]]
				res
			]
			OP_MUL [
				res: left * right
				if system/cpu/overflow? [fire [TO_ERROR(math overflow)]]
				res
			]
			OP_AND [left and right]
			OP_OR  [left or right]
			OP_XOR [left xor right]
			OP_REM [
				either zero? right [
					fire [TO_ERROR(math zero-divide)]
					0								;-- pass the compiler's type-checking
				][
					if all [left = -2147483648 right = -1][
						fire [TO_ERROR(math overflow)]
					]
					left % right
				]
			]
			OP_DIV [
				either zero? right [
					fire [TO_ERROR(math zero-divide)]
					0								;-- pass the compiler's type-checking
				][
					if all [left = -2147483648 right = -1][
						fire [TO_ERROR(math overflow)]
					]
					left / right
				]
			]
		]
	]

	do-math: func [
		op			[math-op!]
		return:		[red-value!]
		/local
			left	[red-integer!]
			right	[red-integer!]
			word	[red-word!]
			value	[integer!]
			size	[integer!]
			n		[integer!]
			v		[integer!]
			tp		[byte-ptr!]
	][
		left: as red-integer! stack/arguments
		right: left + 1

		assert any [									;@@ replace by typeset check when possible
			TYPE_OF(left) = TYPE_INTEGER
			TYPE_OF(left) = TYPE_CHAR
		]
		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_CHAR
			TYPE_OF(right) = TYPE_FLOAT
			TYPE_OF(right) = TYPE_PERCENT
			TYPE_OF(right) = TYPE_PAIR
			TYPE_OF(right) = TYPE_TUPLE
			TYPE_OF(right) = TYPE_TIME
			TYPE_OF(right) = TYPE_VECTOR
			TYPE_OF(right) = TYPE_DATE
		]

		switch TYPE_OF(right) [
			TYPE_INTEGER TYPE_CHAR [
				left/value: do-math-op left/value right/value op
			]
			TYPE_FLOAT TYPE_PERCENT TYPE_TIME [float/do-math op]
			TYPE_PAIR
			TYPE_TUPLE [
				value: left/value						;-- swap them!
				copy-cell as red-value! right as red-value! left
				right/header: TYPE_INTEGER
				right/value: value
				
				either TYPE_OF(left) = TYPE_PAIR [
					if op = OP_DIV [
						fire [TO_ERROR(script not-related) words/_divide datatype/push TYPE_INTEGER]
					]
					if op = OP_SUB [
						pair/negate						;-- negates the pair! now in stack/arguments
						op: OP_ADD
					]
					pair/do-math op
				][
					if any [op = OP_SUB op = OP_DIV][
						word: either op = OP_SUB [words/_subtract][words/_divide]
						fire [TO_ERROR(script not-related) word datatype/push TYPE_INTEGER]
					]
					tuple/do-math op
				]
			]
			TYPE_VECTOR [
				return stack/set-last vector/do-math-scalar op as red-vector! right as red-value! left
			]
			TYPE_DATE [
				either op = OP_ADD [
					value: left/value						;-- swap them!
					copy-cell as red-value! right as red-value! left
					right/header: TYPE_INTEGER
					right/value: value
					date/do-math op
				][
					fire [TO_ERROR(script not-related) words/_subtract datatype/push TYPE_INTEGER]
				]
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]
		as red-value! left
	]

	make-at: func [
		slot	[red-value!]
		value	[integer!]
		return:	[red-integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! slot
		int/header: TYPE_INTEGER
		int/value: value
		int
	]

	make-in: func [
		parent 	[red-block!]
		value 	[integer!]
		return: [red-integer!]
		/local
			int [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/make-in"]]
		
		int: as red-integer! ALLOC_TAIL(parent)
		int/header: TYPE_INTEGER
		int/value: value
		int
	]
	
	push: func [
		value	[integer!]
		return: [red-integer!]
		/local
			int [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/push"]]
		
		int: as red-integer! stack/push*
		int/header: TYPE_INTEGER
		int/value: value
		int
	]

	;-- Actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-integer!]
		/local
			bool [red-logic!]
			int	 [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/make"]]

		either TYPE_OF(spec) = TYPE_LOGIC [
			bool: as red-logic! spec
			int: as red-integer! proto
			int/header: TYPE_INTEGER
			int/value: as-integer bool/value
			int
		][
			as red-integer! to proto spec type
		]
	]

	random: func [
		int		[red-integer!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			n	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/random"]]

		either seed? [
			_random/srand int/value
			int/header: TYPE_UNSET
		][
			unless zero? int/value [
				n: _random/rand % int/value + 1
				int/value: either negative? int/value [0 - n][n]
			]
		]
		as red-value! int
	]

	to: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-value!]
		/local
			int  [red-integer!]
			fl	 [red-float!]
			str	 [red-string!]
			t	 [red-time!]
			p	 [byte-ptr!]
			err	 [integer!]
			i	 [integer!]
			unit [integer!]
			len	 [integer!]
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/to"]]
		
		if TYPE_OF(spec) = TYPE_INTEGER [return spec]
		
		int: as red-integer! proto
		int/header: TYPE_INTEGER
		
		switch TYPE_OF(spec) [
			TYPE_CHAR [
				int/value: spec/data2
			]
			TYPE_FLOAT
			TYPE_PERCENT [
				fl: as red-float! spec
				if overflow? fl [fire [TO_ERROR(script type-limit) datatype/push TYPE_INTEGER]]
				int/value: as-integer fl/value
			]
			TYPE_BINARY [
				int/value: from-binary as red-binary! spec
			]
			TYPE_ISSUE [
				int/value: from-issue as red-word! spec
			]
			TYPE_TIME [
				t: as red-time! spec
				int/value: as-integer t/time + 0.5
			]
			TYPE_DATE [
				int/value: date/to-epoch as red-date! spec
			]
			TYPE_ANY_STRING [
				err: 0
				str: as red-string! spec
				s: GET_BUFFER(str)
				unit: GET_UNIT(s)
				p: (as byte-ptr! s/offset) + (str/head << log-b unit)
				len: (as-integer s/tail - p) >> log-b unit
				i: tokenizer/scan-integer p len unit :err
				if err <> 0 [
					fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_INTEGER spec]
				]
				int/value: i
			]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_INTEGER spec]]
		]
		proto
	]

	form: func [
		int		   [red-integer!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/form"]]
		
		formed: form-signed int/value
		string/concatenate-literal buffer formed
		part - length? formed							;@@ optimize by removing length?
	]
	
	mold: func [
		int		[red-integer!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/mold"]]

		form int buffer arg part
	]
	
	compare: func [
		value1    [red-integer!]						;-- first operand
		value2    [red-integer!]						;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [integer!]
		/local
			char  [red-char!]
			f	  [red-float!]
			left  [integer!]
			right [integer!] 
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/compare"]]

		if all [
			any [op = COMP_FIND op = COMP_STRICT_EQUAL]
			TYPE_OF(value2) <> TYPE_INTEGER
		][return 1]
		
		left: value1/value
		
		switch TYPE_OF(value2) [
			TYPE_INTEGER [
				right: value2/value
			]
			TYPE_CHAR [
				char: as red-char! value2				;@@ could be optimized as integer! and char!
				right: char/value						;@@ structures are overlapping exactly
			]
			TYPE_FLOAT TYPE_PERCENT [
				f: as red-float! value1
				left: value1/value
				f/value: as-float left
				res: float/compare f as red-float! value2 op
				value1/value: left
				return res
			]
			default [RETURN_COMPARE_OTHER]
		]
		SIGN_COMPARE_RESULT(left right)
	]
	
	complement: func [
		int		[red-integer!]
		return:	[red-value!]
	][
		int/value: not int/value
		as red-value! int
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/remainder"]]
		as red-value! do-math OP_REM
	]

	absolute: func [
		return: [red-integer!]
		/local
			int	[red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "integer/absolute"]]
		
		int: as red-integer! stack/arguments
		int/value: abs int/value
		int
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/add"]]
		as red-value! do-math OP_ADD
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/divide"]]
		as red-value! do-math OP_DIV
	]
		
	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/multiply"]]
		as red-value! do-math OP_MUL
	]
	
	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/subtract"]]
		as red-value! do-math OP_SUB
	]

	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/and~"]]
		as red-value! do-math OP_AND
	]

	or~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/or~"]]
		as red-value! do-math OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "integer/xor~"]]
		as red-value! do-math OP_XOR
	]

	negate: func [
		return: [red-integer!]
		/local
			int	  [red-integer!]
			fl	  [red-float!]
			value [integer!]
	][
		int: as red-integer! stack/arguments
		int/value: 0 - int/value
		if system/cpu/overflow? [fire [TO_ERROR(math overflow)]]
		int 											;-- re-use argument slot for return value
	]

	int-power: func [
		base	[integer!]
		exp		[integer!]
		return: [integer!]
		/local
			res  [integer!]
	][
		res: 1
		while [exp <> 0][
			if as logic! exp and 1 [
				res: res * base
				if system/cpu/overflow? [throw RED_INT_OVERFLOW]
			]
			exp: exp >> 1
			base: base * base
			if all [system/cpu/overflow? exp > 0][
				throw RED_INT_OVERFLOW
			]
		]
		res
	]

	power: func [
		return:	 [red-value!]
		/local
			base [red-integer!]
			exp  [red-integer!]
			f	 [red-float!]
			type [integer!]
			up?	 [logic!]
	][
		base: as red-integer! stack/arguments
		exp: base + 1
		type: TYPE_OF(exp)
		
		if all [type <> TYPE_INTEGER type <> TYPE_FLOAT][
			ERR_EXPECT_ARGUMENT(type 1)
		]
		
		up?: any [
			TYPE_OF(exp) = TYPE_FLOAT
			negative? exp/value
		]
		unless up? [
			catch RED_INT_OVERFLOW [
				base/value: int-power base/value exp/value
			]
		]
		if any [up? system/thrown = RED_INT_OVERFLOW][
			system/thrown: 0
			f: as red-float! base
			f/value: as-float base/value
			f/header: TYPE_FLOAT
			float/power
		]
		as red-value! base
	]
	
	even?: func [
		int		[red-integer!]
		return: [logic!]
	][
		not as-logic int/value and 1
	]
	
	odd?: func [
		int		[red-integer!]
		return: [logic!]
	][
		as-logic int/value and 1
	]

	#define INT_TRUNC [val: either num > 0 [n - r][r - n]]

	#define INT_FLOOR [
		either m < 0 [
			fire [TO_ERROR(math overflow)]
		][
			val: either num > 0 [n - r][0 - m]
		]
	]

	#define INT_CEIL [
		either m < 0 [
			fire [TO_ERROR(math overflow)]
		][
			val: either num < 0 [r - n][m]
		]
	]

	#define INT_AWAY [
		either m < 0 [
			fire [TO_ERROR(math overflow)]
		][
			val: either num > 0 [m][0 - m]
		]
	]

	round: func [
		value		[red-value!]
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
			f		[red-float!]
			num		[integer!]
			sc		[integer!]
			s		[integer!]
			n		[integer!]
			m		[integer!]
			r		[integer!]
			val		[integer!]
	][
		int: as red-integer! value
		num: int/value
		if num = 80000000h [return value]
		sc: 1
		if OPTION?(scale) [
			if TYPE_OF(scale) = TYPE_FLOAT [
				f: as red-float! value
				f/value: as-float num
				f/header: TYPE_FLOAT
				return float/round value as red-float! scale _even? down? half-down? floor? ceil? half-ceil?
			]
			sc: abs scale/value
		]
		if zero? sc [fire [TO_ERROR(math overflow)]]

		n: abs num
		r: n % sc
		if zero? r [return value]

		s: sc - r
		m: n + s
		case [
			down?		[INT_TRUNC]
			floor?		[INT_FLOOR]
			ceil?		[INT_CEIL ]
			r < s		[INT_TRUNC]
			r > s		[INT_AWAY ]
			_even?		[either zero? (n / sc and 1) [INT_TRUNC][INT_AWAY]]
			half-down?	[INT_TRUNC]
			half-ceil?	[INT_CEIL ]
			true		[INT_AWAY ]
		]
		int/value: val
		value
	]

	init: does [
		datatype/register [
			TYPE_INTEGER
			TYPE_VALUE
			"integer!"
			;-- General actions --
			:make
			:random
			null			;reflect
			:to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			:power
			:remainder
			:round
			:subtract
			:even?
			:odd?
			;-- Bitwise actions --
			:and~
			:complement
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