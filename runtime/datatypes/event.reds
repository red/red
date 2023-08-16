Red/System [
	Title:   "Event! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %event.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

event: context [
	verbose: 0
	
	get-named-index: func [
		w 		[red-word!]
		ref		[red-value!]
		return: [integer!]
		/local
			sym idx [integer!]
	][
		sym: symbol/resolve w/symbol
		idx: -1
		case [
			sym = words/type	   [idx: 1]
			sym = words/face	   [idx: 2]
			sym = words/window	   [idx: 3]
			sym = words/offset	   [idx: 4]
			sym = words/key		   [idx: 5]
			sym = words/picked	   [idx: 6]
			sym = words/flags	   [idx: 7]
			sym = words/away?	   [idx: 8]
			sym = words/down?	   [idx: 9]
			sym = words/mid-down?  [idx: 10]
			sym = words/alt-down?  [idx: 11]
			sym = words/aux-down?  [idx: 12]
			sym = words/ctrl?	   [idx: 13]
			sym = words/shift?	   [idx: 14]
			sym = words/orientation[idx: 15]
			true [if TYPE_OF(ref) = TYPE_EVENT [fire [TO_ERROR(script cannot-use) w ref]]]
		]
		idx
	]
	
	push-field: func [
		evt		[red-event!]
		field	[integer!]
		return: [red-value!]
	][
		switch field [
			1  [gui/get-event-type evt]
			2  [gui/get-event-face evt]
			3  [gui/get-event-window evt]
			4  [gui/get-event-offset evt]
			5  [gui/get-event-key evt]
			6  [gui/get-event-picked evt]
			7  [gui/get-event-flags evt]
			8  [gui/get-event-flag evt/flags gui/EVT_FLAG_AWAY]
			9  [gui/get-event-flag evt/flags gui/EVT_FLAG_DOWN]
			10 [gui/get-event-flag evt/flags gui/EVT_FLAG_MID_DOWN]
			11 [gui/get-event-flag evt/flags gui/EVT_FLAG_ALT_DOWN]
			12 [gui/get-event-flag evt/flags gui/EVT_FLAG_AUX_DOWN]
			13 [gui/get-event-flag evt/flags gui/EVT_FLAG_CTRL_DOWN]
			14 [gui/get-event-flag evt/flags gui/EVT_FLAG_SHIFT_DOWN]
			15 [gui/get-event-orientation evt]
			default [assert false null]
		]
	]
	
	push: func [
		evt [red-event!]
	][	
		stack/push as red-value! evt
	]

	;-- Actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-event!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/make"]]

		as red-event! 0
	]
	
	form: func [
		evt		[red-event!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/form"]]
		
		string/concatenate-literal buffer "event"
		part - 5
	]
	
	mold: func [
		evt		[red-event!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/mold"]]

		form evt buffer arg part
	]
	
	compare: func [
		evt		  [red-event!]							;-- first operand
		arg2	  [red-none!]							;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_EVENT [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_FIND
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL [res: as-integer type <> TYPE_EVENT]
			COMP_SORT
			COMP_CASE_SORT [res: 0]
			default [
				res: -2
			]
		]
		res
	]
	
	eval-path: func [
		evt		[red-event!]							;-- implicit type casting
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
			word  [red-word!]
			field [integer!]
			sym	  [integer!]
	][
		word: as red-word! element
		
		either value <> null [
			sym: symbol/resolve word/symbol
			if sym <> words/type [fire [TO_ERROR(script bad-path-set) path word]]
			if TYPE_OF(value) <> TYPE_WORD [fire [TO_ERROR(script bad-path-set) path value]]
			gui/set-event-type evt as red-word! value
			value
		][
			field: get-named-index word path
			if field = -1 [fire [TO_ERROR(script invalid-path) path element]]
			push-field evt field
		]
	]

	pick: func [
		evt		[red-event!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/pick"]]

		if TYPE_OF(boxed) = TYPE_WORD [index: get-named-index as red-word! boxed as red-value! evt]
		if any [index < 1 index > 15][fire [TO_ERROR(script out-of-range) boxed]]
		push-field evt index
	]
	
	init: does [
		datatype/register [
			TYPE_EVENT
			TYPE_VALUE
			"event!"
			;-- General actions --
			null			;make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
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