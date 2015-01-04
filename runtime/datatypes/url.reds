Red/System [
	Title:   "Url! datatype runtime functions"
	Author:  "Xie Qingtian"
	File: 	 %url.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

url: context [
	verbose: 0

	load-in: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		blk		 [red-block!]
		return:  [red-string!]
		/local
			cell [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/load"]]

		cell: string/load-in src size blk UTF-8
		cell/header: TYPE_URL							;-- implicit reset of all header flags
		cell
	]

	load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		return:  [red-string!]
	][
		load-in src size root
	]

	push: func [
		url [red-url!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/push"]]

		copy-cell as red-value! url stack/push*
	]

	;-- Actions --

	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		type	 [integer!]
		return:	 [red-url!]
		/local
			url [red-url!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/make"]]

		url: as red-url! string/make proto spec type
		set-type as red-value! url TYPE_URL
		url
	]

	mold: func [
		url    [red-url!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			int	   [red-integer!]
			limit  [integer!]
			s	   [series!]
			unit   [integer!]
			cp	   [integer!]
			p	   [byte-ptr!]
			p4	   [int-ptr!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/mold"]]

		limit: either OPTION?(arg) [
			int: as red-integer! arg
			int/value
		][0]

		s: GET_BUFFER(url)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (url/head << (unit >> 1))
		head: p

		tail: either zero? limit [						;@@ rework that part
			as byte-ptr! s/tail
		][
			either negative? part [p][p + (part << (unit >> 1))]
		]
		if tail > as byte-ptr! s/tail [tail: as byte-ptr! s/tail]

		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			string/append-escaped-char buffer cp string/ESC_URL all?
			p: p + unit
		]

		return part - ((as-integer tail - head) >> (unit >> 1)) - 1
	]

	compare: func [
		arg1	[red-string!]							;-- first operand
		arg2	[red-string!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/compare"]]

		either op = COMP_STRICT_EQUAL [
			as-integer TYPE_OF(arg2) = TYPE_URL
		][
			string/equal? arg1 arg2 op no
		]
	]

	copy: func [
		url    [red-url!]
		new		[red-string!]
		arg		[red-value!]
		deep?	[logic!]
		types	[red-value!]
		return:	[red-series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/copy"]]

		url: as red-url! string/copy as red-string! url new arg deep? types
		url/header: TYPE_URL
		as red-series! url
	]

	init: does [
		datatype/register [
			TYPE_URL
			TYPE_STRING
			"url!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			null			;reflect
			null			;to
			INHERIT_ACTION	;form
			:mold
			INHERIT_ACTION	;eval-path
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
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			null			;change
			INHERIT_ACTION	;clear
			:copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			INHERIT_ACTION	;insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			INHERIT_ACTION	;remove
			INHERIT_ACTION	;reverse
			INHERIT_ACTION	;select
			null			;sort
			INHERIT_ACTION	;skip
			INHERIT_ACTION	;swap
			INHERIT_ACTION	;tail
			INHERIT_ACTION	;tail?
			INHERIT_ACTION	;take
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
