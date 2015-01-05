Red/System [
	Title:   "Typeset datatype runtime functions"
	Author:  "Xie Qingtian"
	File: 	 %typeset.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

typeset: context [
	verbose: 0

	#enum typeset-op! [
		OP_MAX											;-- calculate highest value
		OP_SET											;-- set value bits
		OP_TEST											;-- test if value bits are set
		OP_CLEAR										;-- clear value bits
		OP_UNION
		OP_AND
		OP_OR
		OP_XOR
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
		set2: set1 + 1
		res: as red-typeset! stack/push*
		res/header: TYPE_TYPESET
		clear res
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
			OP_AND	[
				res/array1: set1/array1 and set2/array1
				res/array2: set1/array2 and set2/array2
				res/array3: set1/array3 and set2/array3
			]
			OP_XOR	[
				res/array1: set1/array1 xor set2/array1
				res/array2: set1/array2 xor set2/array2
				res/array3: set1/array3 xor set2/array3
			]
		]
		stack/set-last as red-value! res
		res
	]

	union: func [
		case?	[logic!]
		skip	[red-value!]
		return: [red-typeset!]
	][
		do-bitwise OP_UNION
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
			type [red-datatype!]
			id   [integer!]
	][
		type: as red-datatype! value
		if TYPE_OF(type) = TYPE_WORD [
			type: as red-datatype! word/get as red-word! type
		]
		if TYPE_OF(type) <> TYPE_DATATYPE [
			print-line "** Error: invalid argument" ;TBD throw an error
		]
		id: type/value
		assert id < 96
		case [
			id < 32 [sets/array1: sets/array1 or (1 << id)]
			id < 64 [sets/array2: sets/array2 or (1 << (id - 32))]
			true	[sets/array3: sets/array3 or (1 << (id - 64))]
		]		
	]

	;-- Actions --

	make: func [
		proto	[red-value!]
		spec	[red-value!]
		return: [red-typeset!]
		/local
			sets [red-typeset!]
			type [red-value!]
			blk	 [red-block!]
			i	 [integer!]
			end  [red-value!]
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/make"]]

		sets: as red-typeset! stack/push*
		sets/header: TYPE_TYPESET						;-- implicit reset of all header flags
		clear sets

		either TYPE_OF(spec) = TYPE_BLOCK [
			blk: as red-block! spec
			s: GET_BUFFER(blk)
			i: blk/head
			end: s/tail
			type: s/offset + i

			while [type < end][
				set-type sets type
				i: i + 1
				type: s/offset + i
			]
		][
			print-line "** Error: invalid argument" ;TBD throw an error
		]
		sets
	]

	form: func [
		sets	[red-typeset!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
		/local
			array	[int-ptr!]
			end		[int-ptr!]
			value	[integer!]
			id		[integer!]
			base	[integer!]
			cnt		[integer!]
			s		[series!]
			part?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/form"]]

		part?: OPTION?(arg)
		array: (as int-ptr! sets) + 1
		end: array + 3
		base: 0
		cnt: 0
		string/concatenate-literal buffer "make typeset! ["
		part: part - 15
		until [
			id: 0
			value: array/value
			until [
				if value and (1 << id) <> 0 [
					if all [part? negative? part][return part]
					name: name-table + base + id
					string/concatenate-literal-part buffer name/buffer name/size + 1
					string/append-char GET_BUFFER(buffer) as-integer space
					part: part - name/size - 2
					cnt: cnt + 1
				]
				id: id + 1
				id = 32
			]
			base: base + 32
			array: array + 1
			array = end
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
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				res: SIGN_COMPARE_RESULT((length? set1) (length? set2))
			]
			default [
				print-line ["Error: cannot use: " op " comparison on typeset! value"]
				res: -2
			]
		]
		res
	]

	negate: func [
		sets	[red-typeset!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/negate"]]

		as red-value! complement sets
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

	clear: func [
		sets	[red-typeset!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/clear"]]

		sets/array1: 0
		sets/array2: 0
		sets/array3: 0
		as red-value! sets
	]

	find: func [
		sets	 [red-typeset!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
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
			res  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/find"]]

		if TYPE_OF(value) <> TYPE_DATATYPE [
			print-line "Find Error: invalid argument"
			return as red-value! false-value
		]
		type: as red-datatype! value
		id: type/value
		res: case [
			id < 32 [sets/array1 and (1 << id)]
			id < 64 [sets/array2 and (1 << (id - 32))]
			true	[sets/array3 and (1 << (id - 64))]
		]
		as red-value! either zero? res [false-value][true-value]
	]

	insert: func [
		sets	 [red-typeset!]
		value	 [red-value!]
		part-arg [red-value!]
		only?	 [logic!]
		dup-arg	 [red-value!]
		append?	 [logic!]
		return:	 [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/insert"]]

		set-type sets value
		as red-value! sets
	]

	length?: func [
		sets	[red-typeset!]
		return: [integer!]
		/local
			v	[integer!]
			c	[integer!]
			arr [int-ptr!]
			end [int-ptr!]
			len [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "typeset/length?"]]

		len: 0
		arr: as int-ptr! sets
		end: arr + 3
		until [
			arr: arr + 1
			v: arr/value
			c: 0
			while [v <> 0][
				c: c + 1
				v: v and (v - 1)
			]
			len: len + c
			arr = end
		]
		len
	]

	init: does [
		datatype/register [
			TYPE_TYPESET
			TYPE_VALUE
			"typeset!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
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
			:negate
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
			:clear
			null			;copy
			:find
			null			;head
			null			;head?
			null			;index?
			:insert
			:length?
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