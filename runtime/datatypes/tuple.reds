Red/System [
	Title:   "Tuple! datatype runtime functions"
	Author:  "Qingtian Xie"
	File: 	 %tuple.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

tuple: context [
	verbose: 0

	rs-make: func [
		[variadic]
		count	[integer!]
		list	[int-ptr!]
		return: [red-tuple!]
		/local
			tuple	[red-tuple!]
			tp		[byte-ptr!]
			i		[integer!]
	][
		tuple: as red-tuple! stack/push*
		tuple/header: TYPE_TUPLE or either count > 2 [count << 19][3 << 19]

		tp: (as byte-ptr! tuple) + 4
		i: 0
		while [i < count][
			i: i + 1
			tp/i: as-byte list/value
			list: list + 1
		]
		while [i < 3][i: i + 1 tp/i: null-byte]
		tuple
	]
	
	from-binary: func [
		bin		[red-binary!]
		tp		[red-tuple!]
		return: [red-tuple!]
		/local
			s	   [series!]
			p	   [byte-ptr!]
			dst	   [byte-ptr!]
			len	   [integer!]
	][
		s: GET_BUFFER(bin)
		len: (as-integer s/tail - s/offset) + bin/head
		if len > 12 [len: 12]							;-- take first 12 bytes only
		
		p: (as byte-ptr! s/offset) + bin/head
		dst: (as byte-ptr! tp) + 4

		loop len [
			dst/value: p/value
			p: p + 1
			dst: dst + 1
		]

		while [len < 3][dst/value: null-byte len: 3 dst: dst + 1]

		tp/header: TYPE_TUPLE or (len << 19)
		tp
	]

	from-issue: func [
		issue	[red-word!]
		tp		[red-tuple!]
		return: [red-tuple!]
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
		if len > 24 [len: 24]

		str/node: binary/decode-16 
			(as byte-ptr! s/offset) + (str/head << (unit >> 1))
			len
			unit
		if null? str/node [fire [TO_ERROR(script invalid-data) issue]]
		tp: from-binary as red-binary! str tp
		stack/pop 1
		tp
	]
	
	make-rgba: func [
		slot	[red-value!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[integer!]								;-- a = -1 => RGB else RGBA
		return: [red-tuple!]
		/local
			tp	 [red-tuple!]
			size [integer!]
	][
		size: either a = -1 [a: 0 3][4]
		tp: as red-tuple! slot
		tp/header: TYPE_TUPLE or (size << 19)
		tp/array1: (r << 24) or (g << 16 and 00FF0000h) or (b << 8 and FF00h) or (a and FFh)
		tp/array2: 0
		tp/array3: 0
		tp
	]

	push: func [
		size	[integer!]
		arr1	[integer!]
		arr2	[integer!]
		arr3	[integer!]
		return: [red-tuple!]
		/local
			tp	 [red-tuple!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/push"]]
		
		tp: as red-tuple! stack/push*
		tp/header: TYPE_TUPLE or (size << 19)
		tp/array1: arr1
		tp/array2: arr2
		tp/array3: arr3
		tp
	]

	do-math: func [
		type	  [integer!]
		return:	  [red-tuple!]
		/local
			left  [red-tuple!]
			right [red-tuple!]
			int   [red-integer!]
			fl    [red-float!]
			tp1   [byte-ptr!]
			tp2   [byte-ptr!]
			size  [integer!]
			size1 [integer!]
			size2 [integer!]
			v	  [integer!]
			v1	  [integer!]
			n	  [integer!]
			f1	  [float!]
			f2	  [float!]
			swap? [logic!]
			float? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/do-math"]]

		left:  as red-tuple! stack/arguments
		right: as red-tuple! left + 1

		swap?: no
		if TYPE_OF(left) <> TYPE_TUPLE [
			int: as red-integer! left
			left: right
			right: as red-tuple! int
			swap?: yes
		]

		float?: no
		size2: 0
		switch TYPE_OF(right) [
			TYPE_TUPLE [
				tp2: (as byte-ptr! right) + 4
				size2: TUPLE_SIZE?(right)
			]
			TYPE_INTEGER [
				int: as red-integer! right
				v: int/value
			]
			TYPE_FLOAT
			TYPE_PERCENT [
				float?: yes
				fl: as red-float! right
				f2: fl/value
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]

		tp1: (as byte-ptr! left) + 4
		size1: TUPLE_SIZE?(left)
		n: 0
		either float? [
			until [
				n: n + 1
				v1: as-integer tp1/n
				f1: as-float v1
				f1: float/do-math-op f1 f2 type
				v1: as-integer f1
				either v1 > 255 [v1: 255][if negative? v1 [v1: 0]]
				tp1/n: as byte! v1
				n = size1
			]
		][
			size: either size1 < size2 [
				SET_TUPLE_SIZE(left size2)
				size2
			][size1]
			until [
				n: n + 1
				if positive? size2 [
					v: either n <= size2 [as-integer tp2/n][0]
				]
				v1: either n <= size1 [as-integer tp1/n][0]
				v1: integer/do-math-op v1 v type
				either v1 > 255 [v1: 255][if negative? v1 [v1: 0]]
				tp1/n: as byte! v1
				n = size
			]
		]
		if swap? [copy-cell as cell! left stack/arguments]
		left
	]

	;-- Actions --

	make: func [
		proto 	[red-tuple!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-tuple!]
	][
		to proto spec -1
	]

	random: func [
		tp		[red-tuple!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			value [red-value!]
			array [byte-ptr!]
			n	  [integer!]
			size  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/random"]]

		either seed? [
			value: as red-value! tp
			_random/srand value/data1 xor value/data2 xor value/data3
			tp/header: TYPE_UNSET
		][
			array: (as byte-ptr! tp) + 4
			size: TUPLE_SIZE?(tp)
			n: 0
			until [
				n: n + 1
				array/n: as-byte _random/rand % ((as-integer array/n) + 1)
				n = size
			]
		]
		as red-value! tp
	]
	
	to: func [
		proto 	[red-tuple!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-tuple!]
		/local
			int  [red-integer!]
			blk  [red-block!]
			char [red-char!]
			fl	 [red-float!]
			tp   [byte-ptr!]
			i	 [integer!]
			n	 [integer!]
			byte [integer!]
			s	 [series!]
			val	 [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/to"]]

		switch TYPE_OF(spec) [
			TYPE_ANY_LIST [
				blk: as red-block! spec
				n: block/rs-length? blk
				if n > 12 [
					fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_TUPLE spec]
				]
				tp: (as byte-ptr! proto) + 4
				s: GET_BUFFER(blk)
				int: as red-integer! s/offset + blk/head
				i: 0
				while [i < n][
					i: i + 1
					switch TYPE_OF(int) [
						TYPE_INTEGER [byte: int/value]
						TYPE_CHAR	 [
							char: as red-char! int
							byte: char/value
						]
						TYPE_FLOAT 	 [
							fl: as red-float! int
							byte: as-integer fl/value
						]
						default [
							fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_TUPLE spec]
						]
					]
					if any [byte > 255 byte < 0][
						fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_TUPLE spec]
					]
					tp/i: as byte! byte
					int: int + 1
				]
				while [i < 3][i: i + 1 tp/i: null-byte]
				proto/header: TYPE_TUPLE or (i << 19)
			]
			TYPE_BINARY	  [
				proto: from-binary as red-binary! spec proto
			]
			TYPE_ISSUE [
				from-issue as red-word! spec proto
			]
			TYPE_ANY_STRING [
				i: 0
				val: as red-value! :i
				copy-cell spec val					;-- save spec, load-value will change it

				proto: as red-tuple! load-value as red-string! spec
				
				if TYPE_OF(proto) <> TYPE_TUPLE [ 
					fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_TUPLE val]
				]
			]
			TYPE_TUPLE [return as red-tuple! spec]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_TUPLE spec]]
		]
		proto
	]

	form: func [
		tp		   [red-tuple!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			formed [c-string!]
			value  [byte-ptr!]
			n	   [integer!]
			size   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/form"]]

		value: (as byte-ptr! tp) + 4
		size: TUPLE_SIZE?(tp)
		
		n: 0
		until [
			n: n + 1
			formed: integer/form-signed as-integer value/n
			string/concatenate-literal buffer formed
			unless n = size [
				part: part - 1
				string/append-char GET_BUFFER(buffer) as-integer #"."
			]
			part: part - system/words/length? formed	;@@ optimize by removing length?
			n = size
		]
		part
	]

	mold: func [
		tp		[red-tuple!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/mold"]]

		form tp buffer arg part
	]

	eval-path: func [
		parent	[red-tuple!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			int  [red-integer!]
			type [integer!]
	][
		type: TYPE_OF(element)
		either type = TYPE_INTEGER [
			int: as red-integer! element
			either value <> null [
				poke parent int/value value null
				value
			][
				pick parent int/value null
			]
		][
			fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(element)]
			null
		]
	]

	compare: func [
		tp1		[red-tuple!]							;-- first operand
		tp2		[red-tuple!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return: [integer!]
		/local
			p1	 [byte-ptr!]
			p2	 [byte-ptr!]
			i	 [integer!]
			sz   [integer!]
			sz1  [integer!]
			sz2  [integer!]
			v1	 [integer!]
			v2	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/compare"]]

		if TYPE_OF(tp2) <> TYPE_TUPLE [RETURN_COMPARE_OTHER]
		p1: (as byte-ptr! tp1) + 4
		p2: (as byte-ptr! tp2) + 4
		sz1: TUPLE_SIZE?(tp1)
		sz2: TUPLE_SIZE?(tp2)
		sz: either sz1 > sz2 [sz1][sz2]

		i: 0
		until [
			i: i + 1
			v1: either i > sz1 [0][as-integer p1/i] 
			v2: either i > sz2 [0][as-integer p2/i]
			if v1 <> v2 [return SIGN_COMPARE_RESULT(v1 v2)]
			i = sz
		]
		0
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "tuple/add"]]
		as red-value! do-math OP_ADD
	]

	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "tuple/divide"]]
		as red-value! do-math OP_DIV
	]

	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "tuple/multiply"]]
		as red-value! do-math OP_MUL
	]

	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "tuple/subtract"]]
		as red-value! do-math OP_SUB
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "tuple/remainder"]]
		as red-value! do-math OP_REM
	]

	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "tuple/and~"]]
		as red-value! do-math OP_AND
	]

	or~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "tuple/or~"]]
		as red-value! do-math OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "tuple/xor~"]]
		as red-value! do-math OP_XOR
	]

	length?: func [
		tp		[red-tuple!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/length?"]]

		TUPLE_SIZE?(tp)
	]

	all-zero?: func [ ;ugly name, but needed because of the `zero?` macro
		tp		[red-tuple!]
		return: [logic!]
		/local
			value	[byte-ptr!]
			size	[integer!]
			n		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/zero?"]]
		value: (as byte-ptr! tp) + 4
		size: TUPLE_SIZE?(tp)
		n: 1
		while [n <= size] [
			if value/n <> as byte! 0 [return false]
			n: n + 1
		]
		true
	]

	pick: func [
		tp		[red-tuple!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			value	[byte-ptr!]
			size	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/pick"]]

		value: (as byte-ptr! tp) + 4
		size: TUPLE_SIZE?(tp)

		either any [
			index <= 0
			index > size
		][
			fire [TO_ERROR(script out-of-range) boxed]
			null
		][
			as red-value! integer/push as-integer value/index
		]
	]

	poke: func [
		tp		[red-tuple!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			value [byte-ptr!]
			size  [integer!]
			int   [red-integer!]
			v	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/poke"]]

		value: (as byte-ptr! tp) + 4
		size: TUPLE_SIZE?(tp)

		either any [
			index <= 0
			index > size
		][
			fire [TO_ERROR(script out-of-range) boxed]
		][
			int: as red-integer! data
			either TYPE_OF(int) = TYPE_NONE [
				v: size - index + 1
				size: either index > 3 [index - 1][3]
				loop v [
					value/index: as byte! 0
					index: index + 1
				]
				SET_TUPLE_SIZE(tp size)
			][
				v: int/value
				either v > 255 [v: 255][if negative? v [v: 0]]
				value/index: as byte! v
			]
		]
		object/check-owner as red-value! tp
		as red-value! data
	]

	reverse: func [
		tuple	 [red-tuple!]
		part-arg [red-value!]
		return:	 [red-value!]
		/local
			int  [red-integer!]
			part [integer!]
			tmp  [byte!]
			size [integer!]
			n	 [integer!]
			tp   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tuple/reverse"]]

		tp: (as byte-ptr! tuple) + 4
		size: TUPLE_SIZE?(tuple)
		part: size
		if OPTION?(part-arg) [
			either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				part: int/value
				if negative? part [
					fire [TO_ERROR(script out-of-range) int]
				]
			][
				ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
			]
		]

		if part < size [size: part]
		n: 1
		while [n < size] [
			tmp: tp/n
			tp/n: tp/size
			tp/size: tmp
			n: n + 1
			size: size - 1
		]
		object/check-owner as red-value! tuple
		as red-value! tuple
	]

	init: does [
		datatype/register [
			TYPE_TUPLE
			TYPE_VALUE
			"tuple!"
			;-- General actions --
			:make
			:random
			null			;reflect
			:to
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
			null			;negate
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
			:length?
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