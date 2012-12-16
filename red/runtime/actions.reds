Red/System [
	Title:   "Red action functions"
	Author:  "Nenad Rakocevic"
	File: 	 %actions.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

actions: context [
	verbose: 0
	
	get-action-ptr-from: func [
		type	[integer!]								;-- datatype ID
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			index [integer!]
	][
		index: type << 8 + action
		index: action-table/index						;-- lookup action function pointer

		if zero? index [
			print-line [
				"^/*** Script error: action " action
				" not defined for type: " type
			]
			halt
		]
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
			bool [red-logic!]
	][
		arg: stack/arguments + 1
		switch TYPE_OF(arg) [
			TYPE_INTEGER [int: as red-integer! arg int/value]
			TYPE_LOGIC	 [bool: as red-logic! arg 2 - as-integer bool/value]
			default		 [--NOT_IMPLEMENTED-- 0]
		]
	]


	;--- Actions polymorphic calls ---

	make*: func [
		return:	 [red-value!]
	][
		stack/set-last make stack/arguments stack/arguments + 1
	]

	make: func [
		proto 	 [red-value!]
		spec	 [red-value!]
		return:	 [red-value!]
		/local
			dt	 [red-datatype!]
			int  [red-integer!]
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
			return:	 [red-value!]						;-- newly created value
		] get-action-ptr-from type ACT_MAKE
		
		action-make proto spec
	]

	random*: func [][]
	
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
	
	to*: func [][]

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
			string/truncate-tail GET_BUFFER(buffer) limit
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
		
		if all [part >= 0 negative? limit][
			string/truncate-tail GET_BUFFER(buffer) limit
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
			return:  [integer!]							;-- remaining part count
		] get-action-ptr value ACT_MOLD

		action-mold value buffer only? all? flat? arg part
	]
	
	
	get-path*: func [][]
	set-path*: func [][]
	
	compare: func [
		value1  [red-value!]
		value2  [red-value!]
		op	    [integer!]
		return: [logic!]
		/local
			action-compare
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/compare"]]

		action-compare: as function! [
			value1  [red-value!]						;-- first operand
			value2  [red-value!]						;-- second operand
			op	    [integer!]							;-- type of comparison
			return: [logic!]
		] get-action-ptr value1 ACT_COMPARE
		
		action-compare value1 value2 op
	]
	
	absolute*: func [][]
	
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
		/local
			action-negate
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/negate"]]

		action-negate: as function! [
			return:	[red-value!]						;-- negated value
		] get-action-ptr* ACT_NEGATE
		action-negate
	]
	
	
	power*: func [][]
	remainder*: func [][]
	round*: func [][]
	
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
	
	even?*: func [][]
	odd?*: func [][]
	and~*: func [][]
	complement*: func [][]
	or~*: func [][]
	xor~*: func [][]
	
	append*: func [
		part  [integer!]
		only  [integer!]
		dup   [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		append
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			stack/arguments + dup
	]
	
	append: func [
		series  [red-series!]
		value   [red-value!]
		part	[red-value!]
		only?	[logic!]
		dup		[red-value!]
		return:	[red-value!]
		/local
			action-append
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/append"]]

		action-append: as function! [
			series  [red-series!]
			value   [red-value!]
			part	[red-value!]
			only?	[logic!]
			dup		[red-value!]
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr as red-value! series ACT_APPEND
		
		action-append series value part only? dup
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
	
	change*: func [][]
	
	clear*: func [
		return:	[red-value!]
		/local
			action-clear
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/clear"]]

		action-clear: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_CLEAR
		action-clear
	]
	
	copy*: func [
		part	[integer!]
		deep	[integer!]
		types	[integer!]
		return:	[red-series!]
	][
		copy
			as red-series! stack/arguments
			stack/arguments + part
			as logic! deep + 1
			stack/arguments + types
	]
	
	copy: func [
		series  [red-series!]
		part	[red-value!]
		deep?	[logic!]
		types	[red-value!]
		return:	[red-series!]
		/local
			action-copy
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/copy"]]
			
		action-copy: as function! [
			series  [red-series!]
			part	[red-value!]
			deep?	[logic!]
			types	[red-value!]
			return: [red-series!]
		] get-action-ptr as red-value! series ACT_COPY
					
		action-copy series part deep? types
	]
	
	find*: func [
		part	 [integer!]
		only	 [integer!]
		case-arg [integer!]
		any-arg  [integer!]
		with-arg [integer!]
		skip	 [integer!]
		last	 [integer!]
		reverse	 [integer!]
		tail	 [integer!]
		match	 [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		find
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			as logic! case-arg + 1
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
			any?	 [logic!]
			with-arg [red-string!]
			skip	 [red-integer!]
			last?	 [logic!]
			reverse? [logic!]
			tail?	 [logic!]
			match?	 [logic!]
			return:  [red-value!]
		] get-action-ptr as red-value! series ACT_FIND
			
		action-find series value part only? case? any? with-arg skip last? reverse? tail? match?
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
	insert*: func [][]
	
	length?*: func [
		return:	[red-value!]
		/local
			action-length?
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/length?"]]

		action-length?: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_LENGTH?
		action-length?
	]
	
	next*: func [
		return:	[red-value!]
		/local
			action-next
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/next"]]

		action-next: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_NEXT
		action-next
	]
	
	pick*: func [
		return:	 [red-value!]
	][
		pick
			as red-series! stack/arguments
			get-index-argument
	]
	
	pick: func [
		series	[red-series!]
		index	[integer!]
		return:	[red-value!]
		/local
			action-pick
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/pick"]]

		action-pick: as function! [
			series	[red-series!]
			index	[integer!]
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr as red-value! series ACT_PICK
		
		stack/set-last action-pick series index
	]
	
	poke*: func [
		return:	[red-value!]
	][	
		poke
			as red-series! stack/arguments
			get-index-argument
			stack/arguments + 2
	]


	poke: func [
		series	[red-series!]
		index	[integer!]
		data    [red-value!]
		return:	[red-value!]
		/local
			action-poke
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/poke"]]

		action-poke: as function! [
			series	[red-series!]
			index	[integer!]
			data    [red-value!]
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_POKE
		
		action-poke series index data
	]
	
	remove*: func [][]
	reverse*: func [][]
	
	select*: func [
		part	 [integer!]
		only	 [integer!]
		case-arg [integer!]
		any-arg  [integer!]
		with-arg [integer!]
		skip	 [integer!]
		last	 [integer!]
		reverse	 [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		select
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			as logic! case-arg + 1
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
			any?	 [logic!]
			with-arg [red-string!]
			skip	 [red-integer!]
			last?	 [logic!]
			reverse? [logic!]
			return:  [red-value!]
		] get-action-ptr as red-value! series ACT_SELECT

		action-select series value part only? case? any? with-arg skip last? reverse?
	]
	
	sort*: func [][]
	
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
	
	swap*: func [][]
	
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

	
	take*: func [][]
	trim*: func [][]
	create*: func [][]
	close*: func [][]
	delete*: func [][]
	modify*: func [][]
	open*: func [][]
	open?*: func [][]
	query*: func [][]
	read*: func [][]
	rename*: func [][]
	update*: func [][]
	write*: func [][]
]