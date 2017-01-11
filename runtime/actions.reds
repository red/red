Red/System [
	Title:   "Red action functions"
	Author:  "Nenad Rakocevic"
	File: 	 %actions.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

actions: context [
	verbose: 0
	
	table: as int-ptr! 0
	
	register: func [
		[variadic]
		count	[integer!]
		list	[int-ptr!]
		/local
			index  [integer!]
	][
		index:  1
		
		until [
			table/index: list/value
			index: index + 1
			list: list + 1
			count: count - 1
			zero? count
		]
		assert index = (ACTIONS_NB + 1)
	]
	
	get-action-ptr-path: func [
		value	[red-value!]							;-- any-type! value
		action	[integer!]								;-- action ID
		path	[red-value!]
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			type  [integer!]							;-- datatype ID
			index [integer!]
	][
		type:  TYPE_OF(value)
		index: type << 8 + action
		index: action-table/index						;-- lookup action function pointer

		if zero? index [
			if null? path [path: none-value]
			fire [
				TO_ERROR(script bad-path-type)
				path
				datatype/push type
			]
		]
		index
	]
	
	get-action-ptr-from: func [
		type	[integer!]								;-- datatype ID
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			index [integer!]
	][
		index: type << 8 + action
		index: action-table/index						;-- lookup action function pointer

		if zero? index [ERR_EXPECT_ARGUMENT(type 0)]
		index
	]
	
	;@@ temporary stack-oriented version kept until internal API fully changed
	get-action-ptr*: func [
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			arg  [red-value!]
	][
		arg: stack/arguments
		get-action-ptr-from TYPE_OF(arg) action
	]	

	get-action-ptr: func [
		value	[red-value!]							;-- any-type! value
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
	][
		get-action-ptr-from TYPE_OF(value) action
	]
	
	get-index-argument: func [
		return:	 [integer!]
		/local
			arg  [red-value!]
			int  [red-integer!]
			char [red-char!]
			bool [red-logic!]
	][
		arg: stack/arguments + 1
		switch TYPE_OF(arg) [
			TYPE_INTEGER [int:  as red-integer! arg int/value]
			TYPE_CHAR 	 [char: as red-char! 	arg char/value]
			TYPE_LOGIC	 [bool: as red-logic! 	arg 2 - as-integer bool/value]
			default		 [0]
		]
	]


	;--- Actions polymorphic calls ---

	make*: func [
		return:	[red-value!]
	][
		stack/set-last make stack/arguments stack/arguments + 1
	]

	make: func [
		proto 	 [red-value!]
		spec	 [red-value!]
		return:	 [red-value!]
		/local
			dt	 [red-datatype!]
			type [integer!]
			action-make
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/make"]]
		
		type: TYPE_OF(proto)
		if type = TYPE_DATATYPE [
			dt: as red-datatype! proto
			type: dt/value
		]

		action-make: as function! [
			proto 	 [red-value!]
			spec	 [red-value!]
			type	 [integer!]
			return:	 [red-value!]						;-- newly created value
		] get-action-ptr-from type ACT_MAKE
		
		action-make proto spec type
	]

	random*: func [
		seed	[integer!]
		secure	[integer!]
		only	[integer!]
		return:	[red-value!]
	][
		random
			as red-value! stack/arguments
			as logic! seed + 1
			as logic! secure + 1
			as logic! only + 1
	]

	random: func [
		value   [red-value!]
		seed?	[logic!]
		secure? [logic!]
		only?	[logic!]
		return: [red-value!]
		/local
			action-random
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/random"]]

		action-random: as function! [
			value	[red-value!]
			seed?	[logic!]
			secure? [logic!]
			only?	[logic!]
			return: [red-value!]
		] get-action-ptr value ACT_RANDOM

		action-random value seed? secure? only?
	]

	reflect*: func [
		return: [red-block!]
	][
		reflect stack/arguments as red-word! stack/arguments + 1
	]
	
	reflect: func [
		value	[red-value!]
		field	[red-word!]
		return: [red-block!]
		/local
			action-reflect
	][
		action-reflect: as function! [
			value	[red-value!]
			field	[integer!]
			return:	[red-block!]
		] get-action-ptr-from TYPE_OF(value) ACT_REFLECT
			
		action-reflect value field/symbol
	]

	to*: func [
		return: [red-value!]
	][
		stack/set-last to stack/arguments stack/arguments + 1
	]

	to: func [
		proto 	 [red-value!]
		spec	 [red-value!]
		return:	 [red-value!]
		/local
			dt	 [red-datatype!]
			type [integer!]
			action-to
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/to"]]

		type: TYPE_OF(proto)
		if type = TYPE_DATATYPE [
			dt: as red-datatype! proto
			type: dt/value
		]

		action-to: as function! [
			proto 	 [red-value!]
			spec	 [red-value!]
			type	 [integer!]
			return:	 [red-value!]						;-- newly created value
		] get-action-ptr-from type ACT_TO

		action-to proto spec type
	]


	form*: func [
		part	   [integer!]
		/local
			arg	   [red-value!]
			buffer [red-string!]
			int    [red-integer!]
			limit  [integer!]
	][
		arg: stack/arguments + part
		
		limit: either part >= 0 [
			int: as red-integer! arg
			int/value
		][0]
		
		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push* 16		;@@ /part argument
		limit: form stack/arguments buffer arg limit
		
		if all [part >= 0 negative? limit][
			string/truncate-from-tail GET_BUFFER(buffer) limit
		]
		stack/set-last as red-value! buffer
	]
	
	form: func [
		value   [red-value!]							;-- FORM argument
		buffer  [red-string!]							;-- FORM buffer
		arg		[red-value!]							;-- max bytes count
		part	[integer!]
		return: [integer!]
		/local
			action-form
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/form"]]

		action-form: as function! [
			value	[red-value!]						;-- FORM argument
			buffer	[red-string!]						;-- FORM buffer
			arg		[red-value!]						;-- max bytes count
			part	[integer!]
			return: [integer!]							;-- remaining part count
		] get-action-ptr value ACT_FORM

		action-form value buffer arg part
	]
	
	mold*: func [
		only	[integer!]
		_all	[integer!]
		flat	[integer!]
		part	[integer!]
		/local
			arg	   [red-value!]
			buffer [red-string!]
			int    [red-integer!]
			limit  [integer!]
	][
		arg: stack/arguments + part
		
		limit: either part >= 0 [
			int: as red-integer! arg
			int/value
		][0]

		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push* 16		;@@ /part argument
		limit: mold 
			stack/arguments
			buffer
			as logic! only + 1
			as logic! _all + 1
			as logic! flat + 1
			arg
			limit
			0
		
		if all [part >= 0 negative? limit][
			string/truncate-from-tail GET_BUFFER(buffer) limit
		]
		stack/set-last as red-value! buffer
	]
	
	mold: func [
		value    [red-value!]							;-- MOLD argument
		buffer   [red-string!]							;-- MOLD buffer
		only?	 [logic!]
		all?	 [logic!]
		flat?	 [logic!]
		arg		 [red-value!]
		part     [integer!]								;-- max bytes count
		indent	 [integer!]
		return:  [integer!]
		/local
			action-mold
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/mold"]]

		action-mold: as function! [
			value	 [red-value!]						;-- FORM argument
			buffer	 [red-string!]						;-- FORM buffer
			only?	 [logic!]
			all?	 [logic!]
			flat?	 [logic!]
			part-arg [red-value!]		
			part	 [integer!]							;-- max bytes count
			indent	 [integer!]
			return:  [integer!]							;-- remaining part count
		] get-action-ptr value ACT_MOLD

		action-mold value buffer only? all? flat? arg part indent
	]
	
	eval-path*: func [
		set?	[logic!]
		return:	[red-value!]
		/local
			value [red-value!]
	][
		value: either set? [stack/arguments + 2][null]
		value: stack/set-last eval-path 
			stack/arguments
			stack/arguments + 1
			value
			null
			no
		
		if set? [object/path-parent/header: TYPE_NONE]	;-- disables owner checking
		value
	]
	
	eval-path: func [
		parent	[red-value!]
		element	[red-value!]
		value	[red-value!]
		path	[red-path!]
		case?	[logic!]
		return:	[red-value!]
		/local
			action-path
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/eval-path"]]
				
		action-path: as function! [
			parent	[red-value!]
			element	[red-value!]
			value	[red-value!]
			path	[red-value!]
			case?	[logic!]
			return:	[red-value!]
		] get-action-ptr-path parent ACT_EVALPATH as red-value! path
		
		action-path parent element value as red-value! path case?
	]
	
	set-path*: func [][]
	
	compare*: func [
		op		[comparison-op!]
		return: [red-logic!]
		/local
			result [red-logic!]
	][
		result: as red-logic! stack/arguments
		result/value: compare stack/arguments stack/arguments + 1 op
		result/header: TYPE_LOGIC
		result
	]	
	
	compare: func [
		value1  [red-value!]
		value2  [red-value!]
		op	    [comparison-op!]
		return: [logic!]
		/local
			action-compare value res
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/compare"]]

		action-compare: as function! [
			value1  [red-value!]						;-- first operand
			value2  [red-value!]						;-- second operand
			op	    [integer!]							;-- type of comparison
			return: [integer!]
		] get-action-ptr value1 ACT_COMPARE
		
		value: action-compare value1 value2 op
		if all [
			value = -2
			op <> COMP_EQUAL
			op <> COMP_SAME
			op <> COMP_STRICT_EQUAL
			op <> COMP_NOT_EQUAL
		][
			fire [TO_ERROR(script invalid-compare) value1 value2]
		]
		switch op [
			COMP_EQUAL
			COMP_SAME
			COMP_STRICT_EQUAL 	[res: value =  0]
			COMP_NOT_EQUAL 		[res: value <> 0]
			COMP_LESSER			[res: value <  0]
			COMP_LESSER_EQUAL	[res: value <= 0]
			COMP_GREATER		[res: value >  0]
			COMP_GREATER_EQUAL	[res: value >= 0]
		]
		res
	]

	compare-value: func [								;-- Compare function return integer!
		value1  [red-value!]
		value2  [red-value!]
		op		[comparison-op!]
		return: [integer!]
		/local
			action-compare res
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/compare-value"]]

		action-compare: as function! [
			value1  [red-value!]						;-- first operand
			value2  [red-value!]						;-- second operand
			op	    [integer!]							;-- type of comparison
			return: [integer!]
		] get-action-ptr value1 ACT_COMPARE

		switch TYPE_OF(value1) [
			TYPE_LOGIC	 [res: value1/data1 - value2/data1]
			TYPE_NATIVE
			TYPE_ACTION
			TYPE_FUNCTION
			TYPE_OP
			TYPE_ROUTINE [res: SIGN_COMPARE_RESULT(value1/data3 value2/data3)]
			TYPE_NONE
			TYPE_UNSET	 [res: 0]
			default		 [res: action-compare value1 value2 op]
		]
		res
	]
	
	modify*: func [
		case?	[integer!]
		return:	[red-value!]
	][	
		modify
			stack/arguments
			stack/arguments + 1
			stack/arguments + 2
			case? <> -1

		stack/set-last stack/arguments
	]


	modify: func [
		target	[red-value!]
		field	[red-value!]
		value	[red-value!]
		case?	[logic!]
		/local
			action-modify
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/modify"]]

		action-modify: as function! [
			target	[red-value!]
			field	[red-value!]
			value	[red-value!]
			case?	[logic!]
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr target ACT_MODIFY

		action-modify target field value case?
	]
	
	absolute*: func [
		return:	[red-value!]
		/local
			action-absolute
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/absolute"]]

		action-absolute: as function! [
			return:	[red-value!]						;-- absoluted value
		] get-action-ptr* ACT_ABSOLUTE
		action-absolute
	]
	
	add*: func [
		return:	[red-value!]
		/local
			action-add
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/add"]]

		action-add: as function! [
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr* ACT_ADD
		action-add
	]
	
	divide*: func [
		return:	[red-value!]
		/local
			action-divide
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/divide"]]

		action-divide: as function! [
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_DIVIDE
		action-divide
	]
	
	multiply*: func [
		return:	[red-value!]
		/local
			action-multiply
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/multiply"]]

		action-multiply: as function! [
			return:	[red-value!]						;-- multiplication resulting value
		] get-action-ptr* ACT_MULTIPLY
		action-multiply
	]
	
	negate*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/negate"]]

		negate-action stack/arguments
	]

	negate-action: func [								;-- negate is a Red/System keyword
		value	[red-value!]
		return:	[red-value!]
		/local
			action-negate
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/negate"]]

		action-negate: as function! [
			value	[red-value!]
			return:	[red-value!]						;-- negated value
		] get-action-ptr value ACT_NEGATE
		
		action-negate value
	]

	power*: func [
		return:	[red-value!]
		/local
			action-power
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/power"]]

		action-power: as function! [
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr* ACT_POWER
		action-power
	]

	remainder*: func [
		return:	  [red-value!]
		/local
			action-remainder
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/remainder"]]

		action-remainder: as function! [
			return:	  [red-value!]
		] get-action-ptr* ACT_REMAINDER
		action-remainder
	]

	round*: func [
		_to		  [integer!]
		even	  [integer!]
		down	  [integer!]
		half-down [integer!]
		floor	  [integer!]
		ceil	  [integer!]
		half-ceil [integer!]
		/local
			scale [red-value!]
	][
		scale: stack/arguments + _to
		round
			stack/arguments
			scale
			as logic! even	+ 1
			as logic! down	+ 1
			as logic! half-down + 1
			as logic! floor + 1
			as logic! ceil  + 1
			as logic! half-ceil + 1
	]

	round: func [
		value		[red-value!]
		scale		[red-value!]
		_even?		[logic!]
		down?		[logic!]
		half-down?	[logic!]
		floor?		[logic!]
		ceil?		[logic!]
		half-ceil?	[logic!]
		return:		[red-value!]
		/local
			action-round
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/round"]]

		action-round: as function! [
			value		[red-value!]
			scale		[red-value!]
			_even?		[logic!]
			down?		[logic!]
			half-down?	[logic!]
			floor?		[logic!]
			ceil?		[logic!]
			half-ceil?	[logic!]
			return:		[red-value!]
		] get-action-ptr value ACT_ROUND

		action-round value scale _even? down? half-down? floor? ceil? half-ceil?
	]

	subtract*: func [
		return:	[red-value!]
		/local
			action-subtract
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/subtract"]]

		action-subtract: as function! [
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr* ACT_SUBTRACT
		action-subtract
	]
	
	even?*: func [
		return:	[red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/even?"]]
		
		logic/box even? stack/arguments
	]
	
	even?: func [
		value	[red-value!]
		return: [logic!]
		/local
			action-even?
	][
		action-even?: as function! [
			value	[red-value!]
			return: [logic!]							;-- TRUE if value is even.
		] get-action-ptr value ACT_EVEN?
		
		action-even? value
	]
	
	odd?*: func [
		return:	[red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/odd?"]]
		
		logic/box odd? stack/arguments
	]
	
	odd?: func [
		value	[red-value!]
		return: [logic!]
		/local
			action-odd?
	][
		action-odd?: as function! [
			value	[red-value!]
			return: [logic!]							;-- TRUE if value is odd.
		] get-action-ptr value ACT_ODD?
		
		action-odd? value
	]
	
	and~*: func [
		return:	[red-value!]
		/local
			action-and~
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/and~"]]

		action-and~: as function! [
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_AND~
		action-and~
	]
	
	complement*: does [
		stack/set-last complement stack/arguments
	]
	
	complement: func [
		value	[red-value!]
		return:	[red-value!]
		/local
			action-complement
	][
		action-complement: as function! [
			value	[red-value!]
			return:	[red-value!]						;-- complemented value
		] get-action-ptr value ACT_COMPLEMENT
		
		action-complement value
	]

	or~*: func [
		return:	[red-value!]
		/local
			action-or~
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/or~"]]

		action-or~: as function! [
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_OR~
		action-or~
	]

	xor~*: func [
		return:	[red-value!]
		/local
			action-xor~
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/xor~"]]

		action-xor~: as function! [
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_XOR~
		action-xor~
	]

	append*: func [
		part  [integer!]
		only  [integer!]
		dup   [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		insert
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			stack/arguments + dup
			yes
	]
	
	at*: func [
		return:	[red-value!]
		/local
			action-at
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/at"]]

		action-at: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_AT
		action-at
	]
	
	back*: func [
		return:	[red-value!]
		/local
			action-back
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/back"]]

		action-back: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_BACK
		action-back
	]

	change*: func [
		part	[integer!]
		only	[integer!]
		dup		[integer!]
		return: [red-series!]
	][
		change
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			stack/arguments + dup
	]

	change: func [
		series	[red-series!]
		value	[red-value!]
		part	[red-value!]
		only?	[logic!]
		dup		[red-value!]
		return: [red-series!]
		/local
			action-change
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/change"]]

		action-change: as function! [
			series	[red-series!]
			value	[red-value!]
			part	[red-value!]
			only?	[logic!]
			dup		[red-value!]
			return: [red-series!]
		] get-action-ptr as red-value! series ACT_CHANGE

		action-change series value part only? dup
	]

	clear*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/clear"]]
		clear stack/arguments
	]
	
	clear: func [
		value	[red-value!]
		return:	[red-value!]
		/local
			action-clear
	][
		action-clear: as function! [
			value	[red-value!]
			return:	[red-value!]						;-- argument series
		] get-action-ptr value ACT_CLEAR
		
		action-clear value
	]
	
	copy*: func [
		part	[integer!]
		deep	[integer!]
		types	[integer!]
		return:	[red-value!]
	][
		stack/set-last copy
			as red-series! stack/arguments
			stack/push*
			stack/arguments + part
			as logic! deep + 1
			stack/arguments + types
	]
	
	copy: func [
		series  [red-series!]
		new		[red-value!]
		part	[red-value!]
		deep?	[logic!]
		types	[red-value!]
		return:	[red-value!]
		/local
			action-copy
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/copy"]]
		
		new/header: series/header
			
		action-copy: as function! [
			series  [red-series!]
			new		[red-value!]
			part	[red-value!]
			deep?	[logic!]
			types	[red-value!]
			return: [red-series!]
		] get-action-ptr as red-value! series ACT_COPY
					
		as red-value! action-copy series new part deep? types
	]
	
	find*: func [
		part	 [integer!]
		only	 [integer!]
		case-arg [integer!]
		same-arg [integer!]
		any-arg  [integer!]
		with-arg [integer!]
		skip	 [integer!]
		last	 [integer!]
		reverse	 [integer!]
		tail	 [integer!]
		match	 [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		stack/set-last find
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			as logic! case-arg + 1
			as logic! same-arg + 1
			as logic! any-arg + 1
			as red-string!  stack/arguments + with-arg
			as red-integer! stack/arguments + skip
			as logic! last + 1
			as logic! reverse + 1
			as logic! tail + 1
			as logic! match + 1
	]
		
	find: func [
		series   [red-series!]
		value    [red-value!]
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
		return:  [red-value!]
		/local
			action-find
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/find"]]
	
		action-find: as function! [
			series   [red-series!]
			value    [red-value!]
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
			return:  [red-value!]
		] get-action-ptr as red-value! series ACT_FIND
			
		action-find series value part only? case? same? any? with-arg skip last? reverse? tail? match?
	]
	
	head*: func [
		return:	[red-value!]
		/local
			action-head
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/head"]]

		action-head: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_HEAD
		action-head
	]
	
	head?*: func [
		return:	[red-value!]
		/local
			action-head?
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/head?"]]

		action-head?: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_HEAD?
		action-head?
	]
	
	index?*: func [
		return:	[red-value!]
		/local
			action-index?
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/index?"]]

		action-index?: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_INDEX?
		action-index?
	]

	insert*: func [
		part  [integer!]
		only  [integer!]
		dup   [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		insert
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			stack/arguments + dup
			no
	]
	
	insert: func [
		series  [red-series!]
		value   [red-value!]
		part	[red-value!]
		only?	[logic!]
		dup		[red-value!]
		append? [logic!]
		return:	[red-value!]
		/local
			action-insert
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/insert"]]

		action-insert: as function! [
			series  [red-series!]
			value   [red-value!]
			part	[red-value!]
			only?	[logic!]
			dup		[red-value!]
			append? [logic!]
			return:	[red-value!]						;-- series after insertion position
		] get-action-ptr as red-value! series ACT_INSERT
		
		action-insert series value part only? dup append?
	]
	
	length?*: func [
		return:	[red-integer!]
		/local
			int	  [red-integer!]
			value [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/length?"]]

		int: as red-integer! stack/arguments
		value: length? stack/arguments					;-- must be set before slot is modified
		either value = -1 [
			none/push-last
		][
			int/value:  value
			int/header: TYPE_INTEGER
		]
		int
	]
	
	length?: func [
		value	[red-value!]
		return: [integer!]
		/local
			action-length?
	][
		action-length?: as function! [
			value	[red-value!]
			return:	[integer!]							;-- length of series
		] get-action-ptr value ACT_LENGTH?
		
		action-length? value
	]
	
	move*: func [
		part	[integer!]
		return:	[red-value!]
	][
		stack/set-last move
			as red-series!  stack/arguments
			as red-series!  stack/arguments + 1
			as red-integer! stack/arguments + part
	]
	
	move: func [
		origin  [red-series!]
		target  [red-series!]
		part	[red-integer!]
		return:	[red-value!]
		/local
			action-move
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/move"]]

		action-move: as function! [
			origin  [red-series!]
			target  [red-series!]
			part	[red-integer!]
			return:	[red-value!]						;-- next value from series
		] get-action-ptr as red-value! origin ACT_MOVE
		
		action-move origin target part
	]
	
	next*: func [
		return:	[red-value!]
		/local
			action-next
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/next"]]

		action-next: as function! [
			return:	[red-value!]						;-- next value from series
		] get-action-ptr* ACT_NEXT
		action-next
	]
	
	pick*: func [
		return:	 [red-value!]
	][
		stack/set-last pick
			as red-series! stack/arguments
			get-index-argument
			stack/arguments + 1
	]
	
	pick: func [
		series	[red-series!]
		index	[integer!]
		boxed	[red-value!]							;-- boxed index value
		return:	[red-value!]
		/local
			action-pick
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/pick"]]

		action-pick: as function! [
			series	[red-series!]
			index	[integer!]
			boxed	[red-value!]						;-- boxed index value
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr as red-value! series ACT_PICK
		
		action-pick series index boxed
	]
	
	poke*: func [
		return:	[red-value!]
	][	
		poke
			as red-series! stack/arguments
			get-index-argument
			stack/arguments + 2
			stack/arguments + 1
		
		stack/set-last stack/arguments + 2				;@@ inline that above
	]


	poke: func [
		series	[red-series!]
		index	[integer!]								;-- unboxed value
		data	[red-value!]
		boxed	[red-value!]							;-- boxed index value
		/local
			action-poke
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/poke"]]

		action-poke: as function! [
			series	[red-series!]
			index	[integer!]
			data	[red-value!]
			boxed	[red-value!]
			return:	[red-value!]						;-- data argument passed as result
		] get-action-ptr as red-value! series ACT_POKE
		
		action-poke series index data boxed
	]
	
	put*: func [
		case? [integer!]
	][	
		stack/set-last put
			stack/arguments
			stack/arguments + 1
			stack/arguments + 2
			case? <> -1
	]

	put: func [
		series	[red-value!]
		key		[red-value!]
		value	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			action-put
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/put"]]

		action-put: as function! [
			series	[red-value!]
			key		[red-value!]
			value	[red-value!]
			case?	[logic!]
			return:	[red-value!]						;-- value argument passed as result
		] get-action-ptr as red-value! series ACT_PUT

		action-put series key value case?
	]
	
	remove*: func [
		part [integer!]
		/local
			part-arg [red-value!]
	][
		part-arg: either part < 0 [null][stack/arguments + part]
		remove as red-series! stack/arguments part-arg
	]
	
	remove: func [
		series  [red-series!]
		part	[red-value!]
		return:	[red-value!]
		/local
			action-remove
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/remove"]]
		
		action-remove: as function! [
			series	[red-series!]
			part	[red-value!]
			return:	[red-value!]
		] get-action-ptr as red-value! series ACT_REMOVE
		
		action-remove series part
	]

	reverse*: func [
		part [integer!]
	][
		reverse
			as red-series! stack/arguments
			stack/arguments + part
	]

	reverse: func [
		series  [red-series!]
		part	[red-value!]
		return:	[red-value!]
		/local
			action-reverse
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/reverse"]]

		action-reverse: as function! [
			series	[red-series!]
			part	[red-value!]
			return:	[red-value!]
		] get-action-ptr as red-value! series ACT_REVERSE

		action-reverse series part
	]
	
	select*: func [
		part	 [integer!]
		only	 [integer!]
		case-arg [integer!]
		same-arg [integer!]
		any-arg  [integer!]
		with-arg [integer!]
		skip	 [integer!]
		last	 [integer!]
		reverse	 [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		stack/set-last select
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			as logic! case-arg + 1
			as logic! same-arg + 1
			as logic! any-arg + 1
			as red-string!  stack/arguments + with-arg
			as red-integer! stack/arguments + skip
			as logic! last + 1
			as logic! reverse + 1
	]

	select: func [
		series   [red-series!]
		value    [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		same?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:  [red-value!]
		/local
			action-select
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/select"]]

		action-select: as function! [
			series   [red-series!]
			value    [red-value!]
			part	 [red-value!]
			only?	 [logic!]
			case?	 [logic!]
			same?	 [logic!]
			any?	 [logic!]
			with-arg [red-string!]
			skip	 [red-integer!]
			last?	 [logic!]
			reverse? [logic!]
			return:  [red-value!]
		] get-action-ptr as red-value! series ACT_SELECT

		action-select series value part only? case? same? any? with-arg skip last? reverse?
	]
	
	sort*: func [
		case-arg [integer!]
		skip-arg [integer!]
		compare  [integer!]
		part	 [integer!]
		all-arg  [integer!]
		reverse	 [integer!]
		stable	 [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		stack/set-last sort
			as red-series!   stack/arguments
			as logic!		 case-arg + 1
			as red-integer!  stack/arguments + skip-arg
			as red-function! stack/arguments + compare
			stack/arguments + part
			as logic! all-arg + 1
			as logic! reverse + 1
			as logic! stable + 1
	]

	sort: func [
		series   [red-series!]
		case?    [logic!]
		skip	 [red-integer!]
		compare	 [red-function!]
		part	 [red-value!]
		all?	 [logic!]
		reverse? [logic!]
		stable?  [logic!]
		return:  [red-value!]
		/local
			action-sort
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/sort"]]

		action-sort: as function! [
			series   [red-series!]
			case?    [logic!]
			skip	 [red-integer!]
			compare	 [red-function!]
			part	 [red-value!]
			all?	 [logic!]
			reverse? [logic!]
			stable?  [logic!]
			return:  [red-value!]
		] get-action-ptr as red-value! series ACT_SORT

		action-sort series case? skip compare part all? reverse? stable?
	]

	skip*: func [
		return:	[red-value!]
		/local
			action-skip
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/skip"]]

		action-skip: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_SKIP
		action-skip
	]
	
	swap*: func [
		return: [red-series!]
	][
		swap
			as red-series! stack/arguments
			as red-series! stack/arguments + 1
	]

	swap: func [
		series1 [red-series!]
		series2	[red-series!]
		return:	[red-series!]
		/local
			action-swap
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/swap"]]

		action-swap: as function! [
			series1	[red-series!]
			series2	[red-series!]
			return:	[red-series!]
		] get-action-ptr as red-value! series1 ACT_SWAP

		action-swap series1 series2
	]
	
	tail*: func [
		return:	[red-value!]
		/local
			action-tail
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/tail"]]

		action-tail: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_TAIL
		action-tail
	]
	
	tail?*: func [
		return:	[red-value!]
		/local
			action-tail?
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/tail?"]]

		action-tail?: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_TAIL?
		action-tail?
	]

	take*: func [
		part	[integer!]
		deep	[integer!]
		last	[integer!]
		return:	[red-value!]
	][
		stack/set-last take
			as red-series! stack/arguments
			stack/arguments + part
			as logic! deep + 1
			as logic! last + 1
	]

	take: func [
		series  [red-series!]
		part	[red-value!]
		deep?	[logic!]
		last?	[logic!]
		return:	[red-value!]
		/local
			action-take
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/take"]]

		action-take: as function! [
			series  [red-series!]
			part	[red-value!]
			deep?	[logic!]
			last?	[logic!]
			return: [red-value!]
		] get-action-ptr as red-value! series ACT_TAKE

		action-take series part deep? last?
	]

	trim*: func [
		head	[integer!]
		tail	[integer!]
		auto	[integer!]
		lines	[integer!]
		_all	[integer!]
		with-arg [integer!]
		return:	[red-series!]
	][
		trim
			as red-series! stack/arguments
			as logic! head  + 1
			as logic! tail  + 1
			as logic! auto  + 1
			as logic! lines + 1
			as logic! _all  + 1
			stack/arguments + with-arg
	]

	trim: func [
		series  [red-series!]
		head?	[logic!]
		tail?	[logic!]
		auto?	[logic!]
		lines?	[logic!]
		all?	[logic!]
		with-arg [red-value!]
		return:	[red-series!]
		/local
			action-trim
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/trim"]]

		action-trim: as function! [
			series  [red-series!]
			head?	[logic!]
			tail?	[logic!]
			auto?	[logic!]
			lines?	[logic!]
			all?	[logic!]
			with-arg [red-value!]
			return:	[red-series!]
		] get-action-ptr as red-value! series ACT_TRIM

		action-trim series head? tail? auto? lines? all? with-arg
	]

	create*: func [][]
	close*: func [][]
	delete*: func [][]
	open*: func [][]
	open?*: func [][]
	query*: func [][]

	read*: func [
		part	[integer!]
		seek	[integer!]
		binary? [integer!]
		lines?	[integer!]
		info?	[integer!]
		as-arg	[integer!]
		return:	[red-value!]
	][
		stack/set-last read
			stack/arguments
			stack/arguments + part
			stack/arguments + seek
			binary? <> -1
			lines? <> -1
			info? <> -1
			stack/arguments + as-arg
	]

	read: func [
		src		[red-value!]
		part	[red-value!]
		seek	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		info?	[logic!]
		as-arg	[red-value!]
		return: [red-value!]
		/local
			action-read
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/read"]]

		action-read: as function! [
			src		[red-value!]
			part	[red-value!]
			seek	[red-value!]
			binary? [logic!]
			lines?	[logic!]
			info?	[logic!]
			as-arg	[red-value!]
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr src ACT_READ

		action-read src part seek binary? lines? info? as-arg
	]

	rename*: func [][]
	update*: func [][]

	write*: func [
		binary? [integer!]
		lines?	[integer!]
		info?	[integer!]
		append? [integer!]
		part	[integer!]
		seek	[integer!]
		allow	[integer!]
		as-arg	[integer!]
		return:	[red-value!]
	][
		stack/set-last write
			stack/arguments
			stack/arguments + 1
			binary? <> -1
			lines? <> -1
			info? <> -1
			append? <> -1
			stack/arguments + part
			stack/arguments + seek
			stack/arguments + allow
			stack/arguments + as-arg
	]

	write: func [
		src		[red-value!]
		data	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		info?	[logic!]
		append? [logic!]
		part	[red-value!]
		seek	[red-value!]
		allow	[red-value!]
		as-arg	[red-value!]
		return: [red-value!]
		/local
			action-write
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/write"]]

		action-write: as function! [
			src		[red-value!]
			data	[red-value!]
			binary? [logic!]
			lines?	[logic!]
			info?	[logic!]
			append? [logic!]
			part	[red-value!]
			seek	[red-value!]
			allow	[red-value!]
			as-arg	[red-value!]
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr src ACT_WRITE

		action-write src data binary? lines? info? append? part seek allow as-arg
	]
	
	
	init: does [
		table: as int-ptr! allocate ACTIONS_NB * size? integer!
		
		register [
			;-- General actions --
			:make*
			:random*
			:reflect*
			:to*
			:form*
			:mold*
			:eval-path*
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute*
			:add*
			:divide*
			:multiply*
			:negate*
			:power*
			:remainder*
			:round*
			:subtract*
			:even?*
			:odd?*
			;-- Bitwise actions --
			:and~*
			:complement*
			:or~*
			:xor~*
			;-- Series actions --
			:append*
			:at*
			:back*
			:change*
			:clear*
			:copy*
			:find*
			:head*
			:head?*
			:index?*
			:insert*
			:length?*
			:move*
			:next*
			:pick*
			:poke*
			:put*
			:remove*
			:reverse*
			:select*
			:sort*
			:skip*
			:swap*
			:tail*
			:tail?*
			:take*
			:trim*
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			:modify*
			null			;open
			null			;open?
			null			;query
			:read*
			null			;rename
			null			;update
			:write*
		]
	]
]