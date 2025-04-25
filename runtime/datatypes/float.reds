Red/System [
	Title:   "Float! datatype runtime functions"
	Author:  "Nenad Rakocevic, Oldes, Qingtian Xie"
	File: 	 %float.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define DBL_EPSILON		2.2204460492503131E-16

float: context [
	verbose: 0

	#enum form-type! [
		FORM_FLOAT_32
		FORM_FLOAT_64
		FORM_PERCENT_32
		FORM_PERCENT
		FORM_TIME
		FORM_POINT_32
	]

	pretty-print?: true
	full-support?: false

	uint64!: alias struct! [int1 [byte-ptr!] int2 [byte-ptr!]]
	int64!:  alias struct! [int1 [integer!] int2 [integer!]]

	DOUBLE_MAX: 0.0
	+INF: 0.0											;-- rebol can't load INF, NaN
	-INF: 0.0											;-- rebol can't load INF, NaN
	QNaN: 0.0
	HALF: 0.0

	double-int-union: as int64! :DOUBLE_MAX				;-- set to largest number
	double-int-union/int2: 7FEFFFFFh
	double-int-union/int1: FFFFFFFFh

	double-int-union: as int64! :+INF
	double-int-union/int2: 7FF00000h
	
	double-int-union: as int64! :-INF
	double-int-union/int2: FFF00000h

	double-int-union: as int64! :QNaN					;-- smallest quiet NaN
	double-int-union/int2: 7FF80000h
	
	double-int-union: as int64! :HALF
	double-int-union/int2: 3FDFFFFFh
	double-int-union/int1: FFFFFFFFh
	
	round-to-int: func [f [float!] return: [integer!]][
		as-integer f + HALF
	]

	abs: func [
		value	[float!]
		return: [float!]
		/local
			n	[int-ptr!]
	][
		n: (as int-ptr! :value) + 1
		n/value: n/value and 7FFFFFFFh
		value
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
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		fl/header: TYPE_FLOAT
		fl/value: value
		fl
	]

	form-float: func [
		f			[float!]
		type		[integer!]
		return:		[c-string!]
		/local
			s		[c-string!]
			s0		[c-string!]
			p0		[c-string!]
			p		[c-string!]
			p1		[c-string!]
			dot?	[logic!]
			d		[int64!]
			w0		[integer!]
			temp	[float!]
			tried?	[logic!]
			pretty? [logic!]
			percent? [logic!]
	][
		d: as int64! :f
		w0: d/int2												;@@ Use little endian. Watch out big endian !

		if w0 and 7FF00000h = 7FF00000h [
			if all [
				zero? d/int1									;@@ Use little endian. Watch out big endian !
				zero? (w0 and 000FFFFFh)
			][
				return either 0 = (w0 and 80000000h) ["1.#INF"]["-1.#INF"]
			]
			return "1.#NaN"
		]

		percent?: any [type = FORM_PERCENT type = FORM_PERCENT_32]
		if pretty-print? [
			temp: abs f
			if temp < DBL_EPSILON [return either percent? ["0%"][either type = FORM_POINT_32 ["0"]["0.0"]]]
		]

		s: "0000000000000000000000000000000"					;-- 32 bytes wide, big enough.
		case [
			any [type = FORM_FLOAT_32 type = FORM_PERCENT_32 type = FORM_POINT_32][
				sprintf [s "%.7g" f]
			]
			type = FORM_TIME [									;-- microsecond precision
				s: dtoa/form-float f 6 no
			]
			type = FORM_PERCENT [
				sprintf [s "%.13g" f]
			]
			true [
				s/17: #"0"
				s/18: #"0"
				sprintf [s "%.16g" f]
			]
		]

		tried?: no
		s0: s
		until [
			p:    null
			p1:   null
			dot?: no

			until [
				if s/1 = #"." [dot?: yes]
				if s/1 = #"e" [
					p: s
					until [
						s: s + 1
						s/1 > #"0"
					]
					p1: s
				]
				s: s + 1
				s/1 = #"^@"
			]

			if pretty-print? [									;-- prettify output if needed
				pretty?: no
				either p = null [								;-- No "E" notation
					w0: as-integer s - s0
					if w0 > 16 [
						p0: either s0/1 = #"-" [s0 + 1][s0]
						if any [
							p0/1 <> #"0"
							all [p0/1 = #"0" w0 > 17]
						][
							p0: s - 2
							pretty?: yes
						]
					]
				][
					if (as-integer p - s0) > 16 [				;-- the number of digits = 16
						p0: p - 2
						pretty?: yes
					]
				]

				if all [pretty? not tried?][
					if any [									;-- correct '01' or '99' pattern
						all [p0/2 = #"1" p0/1 = #"0"]
						all [p0/2 = #"9" p0/1 = #"9"]
					][
						tried?: yes
						s: switch type [
							FORM_POINT_32
							FORM_FLOAT_32 ["%.5g"]
							FORM_TIME	  ["%.5g"]
							default		  ["%.14g"]
						]
						sprintf [s0 s f]
						s: s0
					]
				]
			]
			s0 <> s
		]

		if p1 <> null [											;-- remove #"+" and leading zero
			p0: p
			either p/2 = #"-" [p: p + 2][p: p + 1]
			move-memory as byte-ptr! p as byte-ptr! p1 as-integer s - p1
			s: p + as-integer s - p1
			s/1: #"^@"
			p: p0
		]
		either percent? [
			s/1: #"%"
			s/2: #"^@"
		][
			if all [not dot? type <> FORM_TIME type <> FORM_POINT_32][	;-- added tailing ".0"
				either p = null [
					p: s
				][
					move-memory as byte-ptr! p + 2 as byte-ptr! p as-integer s - p
				]
				p/1: #"."
				p/2: #"0"
				s/3: #"^@"
			]
		]
		s0
	]

	do-math-op: func [
		left	[float!]
		right	[float!]
		type	[integer!]
		return: [float!]
	][
		switch type [
			OP_ADD [left + right]
			OP_SUB [left - right]
			OP_MUL [left * right]
			OP_DIV [left / right]
			OP_REM [
				case [
					0.0 * right = 0.0 [fmod left right]	;-- finite right part - no special case
					NaN? right [QNaN]
					0.0 * left = 0.0 [left]				;-- finite % +-infinity - special case for #4900
					true [QNaN]							;-- (+-infinity or NaN) % +-infinity = NaN
				]
			]
			default [
				fire [TO_ERROR(script cannot-use) stack/get-call datatype/push TYPE_FLOAT]
				0.0										;-- pass the compiler's type-checking
			]
		]
	]

	do-math: func [
		type	  [integer!]
		return:	  [red-float!]
		/local
			left  [red-float!]
			right [red-float!]
			type1 [integer!]
			type2 [integer!]
			int   [red-integer!]
			word  [red-word!]
			op1	  [float!]
			op2	  [float!]
			t1?	  [logic!]
			t2?	  [logic!]
			pct?  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/do-math"]]

		left:  as red-float! stack/arguments
		right: as red-float! left + 1

		type1: TYPE_OF(left)
		type2: TYPE_OF(right)

		assert any [
			type1 = TYPE_INTEGER
			type1 = TYPE_FLOAT
			type1 = TYPE_PERCENT
			type1 = TYPE_TIME
		]

		switch type2 [
			TYPE_TUPLE [return as red-float! tuple/do-math type]
			TYPE_MONEY [return as red-float! money/do-math type]
			TYPE_PAIR  [
				if type1 <> TYPE_TIME [
					if any [type = OP_SUB type = OP_DIV][
						word: either type = OP_SUB [words/_subtract][words/_divide]
						fire [TO_ERROR(script not-related) word datatype/push TYPE_PAIR]
					]
					op1: left/value
					copy-cell as red-value! right as red-value! left
					right/header: type1
					right/value: op1
					return as red-float! pair/do-math type
				]
			]
			TYPE_POINT2D
			TYPE_POINT3D [
				if type1 <> TYPE_TIME [
					if any [type = OP_SUB type = OP_DIV][
						word: either type = OP_SUB [words/_subtract][words/_divide]
						fire [TO_ERROR(script not-related) word datatype/push type2]
					]
					op1: left/value
					copy-cell as red-value! right as red-value! left
					right/header: type1
					right/value: op1
					either type2 = TYPE_POINT2D [
						return as red-float! point2D/do-math type
					][
						return as red-float! point3D/do-math type
					]
				]
			]
			TYPE_VECTOR [
				return as red-float! stack/set-last vector/do-math-scalar type as red-vector! right as red-value! left
			]
			default [0]
		]

		if any [
			not any [						;@@ replace by typeset check when possible
				type2 = TYPE_INTEGER
				type2 = TYPE_CHAR
				type2 = TYPE_FLOAT
				type2 = TYPE_PERCENT
				type2 = TYPE_TIME
			]
			all [
				any [type1 = TYPE_TIME type1 = TYPE_PERCENT]
				type2 = TYPE_CHAR
			]
		][fire [TO_ERROR(script invalid-type) datatype/push type2]]

		if type1 = TYPE_INTEGER [
			int: as red-integer! left
			left/header: TYPE_FLOAT
			left/value: as-float int/value
		]
		if any [
			type2 = TYPE_INTEGER
			type2 = TYPE_CHAR
		][
			int: as red-integer! right
			right/value: as-float int/value
		]
		pct?:  all [
			type1 = TYPE_PERCENT
			type2 <> TYPE_PERCENT
		]
		if pct? [left/header: TYPE_FLOAT]			;-- convert percent! to float!
		
		op1: left/value
		op2: right/value
		
		t1?: all [type1 = TYPE_TIME type2 <> TYPE_TIME]
		t2?: all [type1 <> TYPE_TIME type2 = TYPE_TIME]

		left/value: do-math-op op1 op2 type
		
		if any [t1? t2?][left/header: TYPE_TIME]
		if all [pct? not t2?][left/header: TYPE_PERCENT]
		left
	]
	
	make-at: func [
		slot	[red-value!]
		value	[float!]
		return: [red-float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! slot
		fl/header: TYPE_FLOAT
		fl/value: value
		fl
	]

	make-in: func [
		parent	[red-block!]
		high	[integer!]
		low		[integer!]
		return: [red-float!]
		/local
			cell [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/make-in"]]

		cell: ALLOC_TAIL(parent)
		cell/header: TYPE_FLOAT
		cell/data2: low
		cell/data3: high
		as red-float! cell
	]
	
	push64: func [
		high	[integer!]
		low		[integer!]
		return: [red-float!]
		/local
			cell [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/push64"]]

		cell: stack/push*
		cell/header: TYPE_FLOAT
		cell/data2: low
		cell/data3: high
		as red-float! cell
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
	
	from-money: func [
		mn      [red-money!]
		return: [float!]
	][
		money/to-float mn
	]
	
	from-binary: func [
		bin		[red-binary!]
		return: [float!]
		/local
			s		[series!]
			p		[byte-ptr!]
			len		[integer!]
			part	[integer!]
			int2	[integer!]
			int1	[integer!]
			pf		[pointer! [float!]]
			factor	[integer!]
			f64?	[logic!]
	][
		s: GET_BUFFER(bin)
		len: (as-integer s/tail - s/offset) + bin/head
		if len > 8 [len: 8]							;-- take first 32 bits only
		f64?: either len > 4 [part: 4 yes][part: len no]

		int2: 0
		int1: 0
		factor: 0
		p: (as byte-ptr! s/offset) + bin/head + len - 1

		loop part [
			int1: int1 or ((as-integer p/value) << factor)
			factor: factor + 8
			p: p - 1
		]
		if f64? [
			factor: 0
			part: len - 4
			loop part [
				int2: int2 or ((as-integer p/value) << factor)
				factor: factor + 8
				p: p - 1
			]
		]
		pf: as pointer! [float!] :int1
		pf/value
	]

	get-rs-float: func [
		val		[red-float!]
		return: [float!]
		/local
			int [red-integer!]
	][
		switch TYPE_OF(val) [
			TYPE_INTEGER [
				int: as red-integer! val
				as float! int/value
			]
			TYPE_FLOAT [val/value]
			default [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_FLOAT val]
				0.0
			]
		]
	]

	from-block: func [
		blk		[red-block!]
		return: [float!]
		/local
			val [red-float!]
			f	[float!]
			int [integer!]
	][
		val: as red-float! block/rs-head blk
		int: as-integer get-rs-float val + 1
		f: pow 10.0 as float! int
		f * get-rs-float val
	]

	rs-random: func [
		value	[float!]
		secure? [logic!]
		return: [float!]
		/local
			s	[float!]
	][
		either secure? [
			((as-float _random/rand-secure) / 2147483647.0 + (as-float _random/rand-secure))
				/ (2147483648.0 / value)
		] [
			s: (as-float _random/rand) / 2147483647.0
			s * value
		]
	]

	;-- Actions --

	;-- make: :to

	random: func [
		f		[red-float!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-float!]
		/local
			s	[float!]
			sp	[int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/random"]]

		either seed? [
			s: f/value
			sp: as int-ptr! :s
			_random/srand sp/1 xor sp/2
			f/header: TYPE_UNSET
		][
			f/value: rs-random f/value secure?
		]
		f
	]

	to: func [
		proto	[red-float!]
		spec	[red-value!]
		type	[integer!]								;-- target type
		return:	[red-float!]
		/local
			int	 [red-integer!]
			tm	 [red-time!]
			str  [red-string!]
			res	 [red-float!]
			p	 [byte-ptr!]
			err	 [integer!]
			unit [integer!]
			len	 [integer!]
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/to"]]

		proto/header: type
		switch TYPE_OF(spec) [
			TYPE_INTEGER
			TYPE_CHAR [
				int: as red-integer! spec
				proto/value: as-float int/value
			]
			TYPE_MONEY [
				proto/value: from-money as red-money! spec
			]
			TYPE_TIME [
				tm: as red-time! spec
				proto/value: tm/time
			]
			TYPE_ANY_STRING [
				err: 0
				str: as red-string! spec
				either type = TYPE_PERCENT [
					res: as red-float! load-single-value str stack/push*
					switch TYPE_OF(res) [
						TYPE_PERCENT
						TYPE_FLOAT	 [proto/value: res/value]
						TYPE_INTEGER [
							int: as red-integer! res
							proto/value: as-float int/value
						]
						default 	 [err: -1]
					 ]
				][
					s: GET_BUFFER(str)
					unit: GET_UNIT(s)
					p: (as byte-ptr! s/offset) + (str/head << log-b unit)
					len: (as-integer s/tail - p) >> log-b unit

					either len > 0 [
						proto/value: tokenizer/scan-float p len unit :err
					][err: -1]
				]
				if err <> 0 [fire [TO_ERROR(script bad-to-arg) datatype/push type spec]]
			]
			TYPE_BINARY [
				proto/value: from-binary as red-binary! spec
			]
			TYPE_ANY_LIST [
				if 2 <> block/rs-length? as red-block! spec [
					fire [TO_ERROR(script bad-to-arg) datatype/push type spec]
				]
				proto/value: from-block as red-block! spec
			]
			TYPE_FLOAT
			TYPE_PERCENT [
				spec/header: type
				proto: as red-float! spec
			]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push type spec]]
		]
		proto
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

		formed: form-float fl/value FORM_FLOAT_64
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
		/local
			s	[c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/mold"]]

		s: dtoa/form-float fl/value 0 yes
		string/concatenate-literal buffer s
		part - length? s							;@@ optimize by removing length?
	]

	NaN?: func [
		value	[float!]
		return: [logic!]
		/local
			n	[int-ptr!]
			m	[int-ptr!]
	][
		m: as int-ptr! :value
		n: m + 1
		either n/value and 7FF00000h = 7FF00000h [		;-- the exponent bits are all ones
			any [										;-- the fraction bits are not entirely zeros
				m/value <> 0
				n/value and 000FFFFFh <> 0
			]
		][false]
	]

	NaN-f32?: func [
		value	[float32!]
		return: [logic!]
	][
		value <> value
	]

	special?: func [
		value	[float!]
		return: [logic!]
	][
		any [value = 1.#INF value = -1.#INF NaN? value]
	]
	
	;-- ported from equivalent C code at: https://gist.github.com/dockimbel/e479ad63adcacb690dd80c8ebec10de9
	almost-equal32: func [
		left	[float32!]
		right	[float32!]
		return: [logic!]
		/local
			l r al ar max-inf [integer!]
	][
		if any [NaN-f32? left NaN-f32? right][return no]
		if left = right [return yes]					;-- for NaN, also raise error in default mode
		
		;-- handle large numbers as almost equal to infinity using bit manipulation
		l: as-integer keep left
		r: as-integer keep right
		al: l and 7FFFFFFFh
		ar: r and 7FFFFFFFh
		max-inf: 7F7FFFFFh								;-- largest finite float
		
		if any [al >= max-inf ar >= max-inf][
			return any [
				all [
					any [l = 7F800000h l = FF800000h]
					any [r = 7F800000h r = FF800000h]
				]
				(integer/abs (al - ar)) < 100000h
			]
		]
		if all [al = 0 ar = 0][return yes]				;-- handle negative and positive zero as equal
		
		;-- make the integer representation ordered as a two's complement integer
		if al < 0 [al: 80000000 - al]
		if ar < 0 [ar: 80000000 - ar]
		(integer/abs al - ar) <= 10						;-- 10 ULP threshold
	]

	;@@ using 64bit integer will simplify it significantly.
	;-- returns false if either number is (or both are) NAN.
	;-- treats really large numbers as almost equal to infinity.
	;-- thinks +0.0 and -0.0 are 0 DLP's apart.
	;-- Max ULP: 10 (enough for ordinary use)
	;-- Ref: https://github.com/svn2github/googletest/blob/master/include/gtest/internal/gtest-internal.h
	;--      https://github.com/rebol/rebol/blob/master/src/core/t-decimal.c
	almost-equal: func [
		left	[float!]
		right	[float!]
		return: [logic!]
		/local
			a	 [uint64!]
			b	 [uint64!]
			lo1  [byte-ptr!]
			lo2  [byte-ptr!]
			hi1  [byte-ptr!]
			hi2  [byte-ptr!]
			diff [byte-ptr!]
	][
		if any [NaN? left NaN? right] [return false]
		if left = right [return true]					;-- for NaN, also raise error in default mode

		if DBL_EPSILON > abs left - right [return true] ;-- check if the numbers are really close, use an absolute epsilon

		a: as uint64! :left
		b: as uint64! :right
		lo1: a/int1
		lo2: b/int1
		hi1: a/int2
		hi2: b/int2

		either (as-integer hi1) < 0 [
			hi1: as byte-ptr! (not as-integer hi1)
			lo1: as byte-ptr! (not as-integer lo1)
			either (as-integer lo1) = -1 [hi1: hi1 + 1 lo1: null][lo1: lo1 + 1]
		][
			hi1: as byte-ptr! (as-integer hi1) or 80000000h
		]

		either (as-integer hi2) < 0 [
			hi2: as byte-ptr! (not as-integer hi2)
			lo2: as byte-ptr! (not as-integer lo2)
			either (as-integer lo2) = -1 [hi2: hi2 + 1 lo2: null][lo2: lo2 + 1]
		][
			hi2: as byte-ptr! (as-integer hi2) or 80000000h
		]

		diff: either hi1 > hi2 [hi1 - hi2][hi2 - hi1]
		if diff > (as byte-ptr! 1) [return false]

		case [
			hi1 = hi2 [
				diff: either lo1 < lo2 [lo2 - lo1][lo1 - lo2]
			]
			hi1 > hi2 [
				either lo1 >= lo2 [return false][
					diff: (as byte-ptr! -1) - lo2 + lo1 + 1
				]
			]
			hi2 > hi1 [
				either lo2 >= lo1 [return false][
					diff: (as byte-ptr! -1) - lo1 + lo2 + 1
				]
			]
		]

		diff <= (as byte-ptr! 10)					;-- 10 ULP threshold
	]

	compare: func [
		value1    [red-float!]						;-- first operand
		value2    [red-float!]						;-- second operand
		op	      [integer!]						;-- type of comparison
		return:   [integer!]
		/local
			int   [red-integer!]
			left  [float!]
			right [float!] 
			res	  [integer!]
			ip1   [int-ptr!]
			ip2   [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/compare"]]

		if all [
			any [op = COMP_FIND op = COMP_SAME op = COMP_STRICT_EQUAL]
			TYPE_OF(value1) <> TYPE_OF(value2)
		][return 1]

		left: value1/value

		switch TYPE_OF(value2) [
			TYPE_MONEY [
				if money/float-underflow? left [return -1]
				if money/float-overflow?  left [return 1]
				return money/compare money/from-float left as red-money! value2 op
			]
			TYPE_INTEGER [
				int: as red-integer! value2
				right: as-float int/value
			]
			TYPE_TIME
			TYPE_PERCENT
			TYPE_FLOAT [right: value2/value]
			default [RETURN_COMPARE_OTHER]
		]
		switch op [
			COMP_EQUAL
			COMP_NOT_EQUAL 	[res: as-integer not almost-equal left right]
			COMP_STRICT_EQUAL [res: as-integer not left = right]	;-- SIGN_COMPARE_RESULT cannot handle NaN 
			COMP_SAME [
				ip1: as int-ptr! :left
				ip2: as int-ptr! :right
				res: as-integer any [ip1/1 <> ip2/1  ip1/2 <> ip2/2]
			]
			default [
				res: either any [NaN? left NaN? right][
					switch op [
						COMP_LESSER
						COMP_LESSER_EQUAL	[1]
						COMP_GREATER
						COMP_GREATER_EQUAL	[-1]
						default 			[assert false 0 ]
					]
				][
					SIGN_COMPARE_RESULT(left right)
				]
			]
		]
		res
	]

	complement: func [
		fl		[red-float!]
		return:	[red-value!]
	][
		--NOT_IMPLEMENTED--
		;fl/value: not fl/value
		as red-value! fl
	]

	absolute: func [
		return: [red-float!]
		/local
			f	  [red-float!]
			value [float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "float/absolute"]]

		f: as red-float! stack/arguments
		f/value: abs f/value
		f 											;-- re-use argument slot for return value
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

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "float/remainder"]]
		as red-value! do-math OP_REM
	]

	negate: func [
		return: [red-float!]
		/local
			fl [red-float!]
	][
		fl: as red-float! stack/arguments
		fl/value: 0.0 - fl/value
		fl 											;-- re-use argument slot for return value
	]

	power: func [
		return:	 [red-float!]
		/local
			base [red-float!]
			exp  [red-float!]
			int	 [red-integer!]
			type [integer!]
	][
		base: as red-float! stack/arguments
		exp: base + 1
		type: TYPE_OF(exp)
		
		if all [type <> TYPE_INTEGER type <> TYPE_FLOAT][
			ERR_EXPECT_ARGUMENT(type 1)
		]
		if TYPE_OF(exp) = TYPE_INTEGER [
			int: as red-integer! exp
			exp/value: as-float int/value
		]
		base/value: pow base/value exp/value
		base
	]

	even?: func [
		fl		[red-float!]
		return: [logic!]
	][
		not as-logic (as integer! fl/value) and 1
	]

	odd?: func [
		fl		[red-float!]
		return: [logic!]
	][
		as-logic (as integer! fl/value) and 1
	]

	#define FLOAT_TRUNC(x) [d: floor float/abs x either x < 0.0 [0.0 - d][d]]
	#define FLOAT_AWAY(x)  [d: ceil float/abs x  either x < 0.0 [0.0 - d][d]]

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
			int		[red-integer!]
			f		[red-float!]
			dec		[float!]
			sc		[float!]
			r		[float!]
			d		[float!]
			e		[integer!]
			v		[logic!]
	][
		if TYPE_OF(scale) = TYPE_MONEY [
			fire [TO_ERROR(script not-related) stack/get-call datatype/push TYPE_MONEY]
		]
		
		e: 0
		f: as red-float! value
		dec: f/value
		sc: either TYPE_OF(f) = TYPE_PERCENT [0.01][1.0]
		if OPTION?(scale) [
			either TYPE_OF(scale) = TYPE_INTEGER [
				int: as red-integer! scale
				sc: abs as float! int/value
			][
				sc: abs scale/value
			]
			if TYPE_OF(f) = TYPE_PERCENT [sc: sc / 100.0]
		]
		if sc < ldexp abs dec -53 [return value]		;-- is scale negligible?

		v: sc >= 1.0
		dec: either v [dec / sc][
			r: frexp sc :e
			either e <= -1022 [
				sc: r
				dec: ldexp dec e
			][e: 0]
			sc: 1.0 / sc
			dec * sc
		]

		d: abs dec
		r: 0.5 + floor d
		dec: case [
			down?		[FLOAT_TRUNC(dec)]
			floor?		[floor dec		 ]
			ceil?		[ceil dec		 ]
			r < d		[FLOAT_AWAY(dec) ]
			r > d		[FLOAT_TRUNC(dec)]
			_even?		[either (fmod d 2.0) < 1.0 [FLOAT_TRUNC(dec)][FLOAT_AWAY(dec)]]
			half-down?	[FLOAT_TRUNC(dec)]
			half-ceil?	[ceil dec		 ]
			true		[FLOAT_AWAY(dec) ]
		]

		f/value: either v [
			dec: dec * sc
			if DOUBLE_MAX = abs dec [
				fire [TO_ERROR(math overflow)]
			]
			dec
		][
			ldexp dec / sc e
		]
		if OPTION?(scale) [
			either TYPE_OF(scale) = TYPE_INTEGER [
				dec: f/value
				int: as red-integer! value
				int/header: TYPE_INTEGER
				int/value: as integer! dec
			][
				value/header: TYPE_OF(scale)
			]
		]
		value
	]

	init: does [
		datatype/register [
			TYPE_FLOAT
			TYPE_VALUE
			"float!"
			;-- General actions --
			:to
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