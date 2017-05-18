Red/System [
	Title:   "Typeset datatype runtime functions"
	Author:  "Xie Qingtian"
	File: 	 %typeset.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

typeset: context [
	verbose: 0

	rs-clear: func [
		sets 	[red-typeset!]
		return: [red-typeset!]
	][
		sets/array1: 0
		sets/array2: 0
		sets/array3: 0
		sets
	]
	
	rs-length?: func [
		sets	[red-typeset!]
		return: [integer!]
		/local
			arr [byte-ptr!]
			pos [byte-ptr!]								;-- required by BS_TEST_BIT
			cnt [integer!]
			id  [integer!]
			set? [logic!]								;-- required by BS_TEST_BIT
	][
		id:  1
		cnt: 0
		arr: (as byte-ptr! sets) + 4
		until [
			BS_TEST_BIT(arr id set?)
			if set? [cnt: cnt + 1]
			id: id + 1
			id > datatype/top-id
		]
		cnt
	]
	
	make-in: func [
		parent	[red-block!]
		bs1		[integer!]								;-- pre-encoded in little-endian
		bs2		[integer!]								;-- pre-encoded in little-endian
		bs3		[integer!]								;-- pre-encoded in little-endian
		return: [red-typeset!]
		/local
			ts	 [red-typeset!]
			bits [int-ptr!]
	][
		ts: as red-typeset! ALLOC_TAIL(parent)
		ts/header: TYPE_TYPESET							;-- implicit reset of all header flags
		
		bits: as int-ptr! ts
		bits/2: bs1
		bits/3: bs2
		bits/4: bs3
		ts
	]
	
	create: func [
		bs1		[integer!]								;-- pre-encoded in little-endian
		bs2		[integer!]								;-- pre-encoded in little-endian
		bs3		[integer!]								;-- pre-encoded in little-endian
		return: [red-typeset!]
	][
		make-in root bs1 bs2 bs3
	]
	
	make-default: func [
		blk [red-block!]
		/local
			ts	  [red-typeset!]
			bits  [int-ptr!]
			bbits [byte-ptr!]
			pos	  [byte-ptr!]
	][
		ts: as red-typeset! ALLOC_TAIL(blk)
		ts/header: TYPE_TYPESET							;-- implicit reset of all header flags
		
		bits: as int-ptr! ts
		bits/2: FFFFFFFFh
		bits/3: FFFFFFFFh
		bits/4: FFFFFFFFh
		
		bbits: as byte-ptr! bits + 1
		BS_CLEAR_BIT(bbits TYPE_UNSET)
	]
	
	make-with: func [
		blk	  [red-block!]
		spec  [red-block!]
		/local
			ts	  [red-typeset!]
			ts2	  [red-typeset!]
			pos	  [red-value!]
			value [red-value!]
			end	  [red-value!]
	][
		assert TYPE_OF(spec) = TYPE_BLOCK
		ts: as red-typeset! ALLOC_TAIL(blk)
		ts/header: TYPE_TYPESET							;-- implicit reset of all header flags
		rs-clear ts
		
		pos: block/rs-head spec
		end: block/rs-tail spec
		
		while [pos < end][
			value: either TYPE_OF(pos) = TYPE_WORD [
				word/get as red-word! pos
			][
				pos
			]
			switch TYPE_OF(value) [
				TYPE_DATATYPE [
					set-type ts value
				]
				TYPE_TYPESET  [
					ts2: as red-typeset! value
					ts/array1: ts/array1 or ts2/array1
					ts/array2: ts/array2 or ts2/array2
					ts/array3: ts/array3 or ts2/array3
				]
				TYPE_WORD [
					set-type ts as red-value! object!-type	;@@ user-defined types are object! for now
				]
				TYPE_BLOCK [0]								;-- <type!> [<extra>], just skip it
				default [
					fire [TO_ERROR(script invalid-type-spec) value]
				]
			]
			pos: pos + 1
		]
	]

	do-bitwise: func [
		type	[integer!]
		return: [red-typeset!]
		/local
			res   [red-typeset!]
			set1  [red-typeset!]
			set2  [red-typeset!]
	][
		set1: as red-typeset! stack/arguments
		if type = OP_UNIQUE [return set1]

		set2: set1 + 1
		res: as red-typeset! stack/push*
		res/header: TYPE_TYPESET
		rs-clear res
		if TYPE_OF(set2) = TYPE_DATATYPE [
			set-type res as red-value! set2
			set2: res
		]
		switch type [
			OP_UNION
			OP_OR	[
				res/array1: set1/array1 or set2/array1
				res/array2: set1/array2 or set2/array2
				res/array3: set1/array3 or set2/array3
			]
			OP_INTERSECT
			OP_AND	[
				res/array1: set1/array1 and set2/array1
				res/array2: set1/array2 and set2/array2
				res/array3: set1/array3 and set2/array3
			]
			OP_DIFFERENCE
			OP_XOR	[
				res/array1: set1/array1 xor set2/array1
				res/array2: set1/array2 xor set2/array2
				res/array3: set1/array3 xor set2/array3
			]
			OP_EXCLUDE [
				res/array1: set1/array1 and (not set2/array1)
				res/array2: set1/array2 and (not set2/array2)
				res/array3: set1/array3 and (not set2/array3)
			]
		]
		stack/set-last as red-value! res
		res
	]

	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "typeset/and~"]]
		as red-value! do-bitwise OP_AND
	]

	or~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "typeset/or~"]]
		as red-value! do-bitwise OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "typeset/xor~"]]
		as red-value! do-bitwise OP_XOR
	]

	push: func [
		sets [red-typeset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/push"]]

		copy-cell as red-value! sets stack/push*
	]

	set-type: func [
		sets	[red-typeset!]
		value	[red-value!]
		/local
			dt	 [red-datatype!]
			id   [integer!]
			bits [byte-ptr!]
			pos	 [byte-ptr!]
			src	 [int-ptr!]
			dst	 [int-ptr!]
	][
		dt: as red-datatype! value
		if TYPE_OF(dt) = TYPE_WORD [
			dt: as red-datatype! word/get as red-word! dt
		]
		if TYPE_OF(dt) = TYPE_TYPESET [
			dst: (as int-ptr! sets) + 1					;-- skip header
			src: (as int-ptr! dt) + 1					;-- skip header
			dst/1: dst/1 or src/1
			dst/2: dst/2 or src/2
			dst/3: dst/3 or src/3
			exit
		]
		if TYPE_OF(dt) <> TYPE_DATATYPE [
			fire [TO_ERROR(script invalid-arg) value]
		]
		id: dt/value
		assert id < 96
		bits: (as byte-ptr! sets) + 4					;-- skip header
		BS_SET_BIT(bits id)
	]

	to-block: func [
		sets	[red-typeset!]
		blk		[red-block!]
		return: [red-block!]
		/local
			array	[byte-ptr!]
			id		[integer!]
			name	[names!]
			pos		[byte-ptr!]								;-- required by BS_TEST_BIT
			set?	[logic!]							;-- required by BS_TEST_BIT
	][
		array: (as byte-ptr! sets) + 4
		block/make-at blk 4
		id: 1
		until [
			BS_TEST_BIT(array id set?)
			if set? [
				name: name-table + id
				block/rs-append blk as red-value! name/word
			]
			id: id + 1
			id > datatype/top-id
		]
		blk
	]

	;-- Actions --

	;make: :to
	
	to: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-value!]
		/local
			sets [red-typeset!]
			dt 	 [red-value!]
			blk	 [red-block!]
			i	 [integer!]
			end  [red-value!]
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/to"]]

		if TYPE_OF(spec) = TYPE_TYPESET [return spec]

		sets: as red-typeset! stack/push*
		sets/header: TYPE_TYPESET						;-- implicit reset of all header flags
		rs-clear sets

		either TYPE_OF(spec) = TYPE_BLOCK [
			blk: as red-block! spec
			s: GET_BUFFER(blk)
			i: blk/head
			end: s/tail
			dt: s/offset + i

			while [dt < end][
				set-type sets dt
				i: i + 1
				dt: s/offset + i
			]
		][
			fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_TYPESET spec]
		]		
		as red-value! sets
	]


	form: func [
		sets	[red-typeset!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
		/local
			array	[byte-ptr!]
			pos		[byte-ptr!]							;-- required by BS_TEST_BIT
			name	[names!]
			id		[integer!]
			cnt		[integer!]
			s		[series!]
			part?	[logic!]
			set?	[logic!]							;-- required by BS_TEST_BIT
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/form"]]

		part?: OPTION?(arg)
		array: (as byte-ptr! sets) + 4
		id: 1
		cnt: 0
		string/concatenate-literal buffer "make typeset! ["
		part: part - 15
		until [
			BS_TEST_BIT(array id set?)
			if set? [
				if all [part? negative? part][return part]
				name: name-table + id
				string/concatenate-literal-part buffer name/buffer name/size + 1
				string/append-char GET_BUFFER(buffer) as-integer space
				part: part - name/size - 2
				cnt: cnt + 1
			]
			id: id + 1
			id > datatype/top-id
		]
		s: GET_BUFFER(buffer)
		either zero? cnt [
			string/append-char s as-integer #"]"
		][
			string/poke-char s (as byte-ptr! s/tail) - 1 as-integer #"]"
		]
		part
	]

	mold: func [
		sets	[red-typeset!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/mold"]]

		form sets buffer arg part
	]

	compare: func [
		set1	[red-typeset!]							;-- first operand
		set2   	[red-typeset!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return: [integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/compare"]]

		type: TYPE_OF(set2)
		if type <> TYPE_TYPESET [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				res: SIGN_COMPARE_RESULT((rs-length? set1) (rs-length? set2))
			]
			default [
				res: -2
			]
		]
		res
	]

	complement: func [
		sets	[red-typeset!]
		return:	[red-value!]
		/local
			res [red-typeset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/complement"]]

		res: as red-typeset! copy-cell as red-value! sets stack/push*
		res/array1: not res/array1
		res/array2: not res/array2
		res/array3: not res/array3
		as red-value! res
	]

	find: func [
		sets	 [red-typeset!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		same?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		tail?	 [logic!]
		match?	 [logic!]
		return:	 [red-value!]
		/local
			id	 [integer!]
			type [red-datatype!]
			set? [logic!]								;-- required by BS_TEST_BIT
			array [byte-ptr!]
			pos	  [byte-ptr!]							;-- required by BS_TEST_BIT
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/find"]]

		if TYPE_OF(value) <> TYPE_DATATYPE [
			fire [TO_ERROR(script invalid-arg) value]
		]
		array: (as byte-ptr! sets) + 4
		type: as red-datatype! value
		id: type/value
		assert id < 96
		BS_TEST_BIT(array id set?)
		as red-value! either set? [true-value][false-value]
	]

	init: does [
		datatype/register [
			TYPE_TYPESET
			TYPE_VALUE
			"typeset!"
			;-- General actions --
			:to				;make
			null			;random
			null			;reflect
			:to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			null			;absolute
			null			;add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
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
			:find
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