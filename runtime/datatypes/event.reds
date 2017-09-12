Red/System [
	Title:   "Event! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %event.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

event: context [
	verbose: 0
	
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
		return:	[red-point!]
	][
		#if debug? = yes [if verbose > 0 [print-line "event/make"]]

		as red-point! 0
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
		case?	[logic!]
		return:	[red-value!]
		/local
			word [red-word!]
			sym	 [integer!]
	][
		word: as red-word! element
		sym: symbol/resolve word/symbol
		
		either value <> null [
			if sym <> words/type [fire [TO_ERROR(script invalid-path-set) path]]
			if TYPE_OF(value) <> TYPE_WORD [fire [TO_ERROR(script bad-path-set) path value]]
			gui/set-event-type evt as red-word! value
			value
		][
			case [
				sym = words/type	  [gui/get-event-type evt]
				sym = words/face	  [gui/get-event-face evt]
				sym = words/window	  [gui/get-event-window evt]
				sym = words/offset	  [gui/get-event-offset evt]
				sym = words/key		  [gui/get-event-key evt]
				sym = words/picked	  [gui/get-event-picked evt]
				sym = words/flags	  [gui/get-event-flags evt]
				sym = words/away?	  [gui/get-event-flag evt/flags gui/EVT_FLAG_AWAY]
				sym = words/down?	  [gui/get-event-flag evt/flags gui/EVT_FLAG_DOWN]
				sym = words/mid-down? [gui/get-event-flag evt/flags gui/EVT_FLAG_MID_DOWN]
				sym = words/alt-down? [gui/get-event-flag evt/flags gui/EVT_FLAG_ALT_DOWN]
				sym = words/aux-down? [gui/get-event-flag evt/flags gui/EVT_FLAG_AUX_DOWN]
				sym = words/ctrl?	  [gui/get-event-flag evt/flags gui/EVT_FLAG_CTRL_DOWN]
				sym = words/shift?	  [gui/get-event-flag evt/flags gui/EVT_FLAG_SHIFT_DOWN]
				;sym = words/code	  [gui/get-event-code	  evt/msg]
				true 				  [fire [TO_ERROR(script invalid-path) path element] null]
			]
		]
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