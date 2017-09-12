Red/System [
	Title:   "Percent! datatype runtime functions"
	Author:  "Qingtian Xie"
	File: 	 %percent.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

percent: context [
	verbose: 0

	get: func [											;-- unboxing float value
		value	[red-value!]
		return: [float!]
		/local
			fl [red-float!]
	][
		assert TYPE_OF(value) = TYPE_PERCENT
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
		fl/header: TYPE_PERCENT
		fl/value: value
		fl
	]

	rs-make-at: func [
		slot	[red-value!]
		value	[float!]
		return:	[red-float!]
		/local
			p	[red-float!]
	][
		p: as red-float! slot
		p/header: TYPE_PERCENT
		p/value: value
		p
	]

	make-at: func [
		cell 	[cell!]
		high	[integer!]
		low		[integer!]
		return: [red-float!]
	][
		cell/header: TYPE_PERCENT
		cell/data2: low
		cell/data3: high
		as red-float! cell
	]

	make-in: func [
		parent	[red-block!]
		high	[integer!]
		low		[integer!]
		return: [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "percent/make-in"]]

		make-at ALLOC_TAIL(parent) high low
	]
	
	push64: func [
		high	[integer!]
		low		[integer!]
		return: [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "percent/push64"]]

		make-at stack/push* high low
	]

	push: func [
		value	[float!]
		return: [red-float!]
		/local
			fl [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "percent/push"]]

		fl: as red-float! stack/push*
		fl/header: TYPE_PERCENT
		fl/value: value
		fl
	]

	;-- make: :to

	form: func [
		fl		   [red-float!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			formed [c-string!]
			value  [float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "percent/form"]]

		value: fl/value * 100.0
		formed: float/form-float value float/FORM_PERCENT
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
	][
		#if debug? = yes [if verbose > 0 [print-line "percent/mold"]]

		form fl buffer arg part
	]

	init: does [
		datatype/register [
			TYPE_PERCENT
			TYPE_FLOAT
			"percent!"
			;-- General actions --
			INHERIT_ACTION	;make
			INHERIT_ACTION	;random
			null			;reflect
			INHERIT_ACTION	;to
			:form
			:mold
			null			;eval-path
			null			;set-path
			INHERIT_ACTION	;compare
			;-- Scalar actions --
			INHERIT_ACTION	;absolute
			INHERIT_ACTION	;add
			INHERIT_ACTION	;divide
			INHERIT_ACTION	;multiply
			INHERIT_ACTION	;negate
			INHERIT_ACTION	;power
			INHERIT_ACTION	;remainder
			INHERIT_ACTION	;round
			INHERIT_ACTION	;subtract
			INHERIT_ACTION	;even?
			INHERIT_ACTION	;odd?
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