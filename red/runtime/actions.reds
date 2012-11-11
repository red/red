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
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/make"]]
		
		type: TYPE_OF(proto)
		if type = TYPE_DATATYPE [
			dt: as red-datatype! proto
			type: dt/value
		]

		action-make: as function! [						;-- needs to be globally bound
			proto 	 [red-value!]
			spec	 [red-value!]
			return:	 [red-value!]						;-- newly created value
		] get-action-ptr-from type ACT_MAKE
		
		action-make proto spec
	]

	random*: func [][]
	reflect*: func [][]
	to*: func [][]

	form*: func [
		options	   [integer!]
		/local
			buffer [red-string!]
			part   [red-integer!]
			part?  [logic!]
			limit  [integer!]
	][
		part?: OPTION?(REF_FORM_PART)
		limit: either part? [
			part: as red-integer! stack/arguments + 1
			part/value
		][0]
		
		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push 16			;@@ /part argument
		limit: form stack/arguments buffer limit options
		if all [part? negative? limit][
			string/truncate-tail GET_BUFFER(buffer) limit
		]
		stack/set-last as red-value! buffer
	]
	
	form: func [
		value   [red-value!]							;-- FORM argument
		buffer  [red-string!]							;-- FORM buffer
		part    [integer!]								;-- max bytes count
		flags   [integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/form"]]

		action-form: as function! [						;-- needs to be globally bound
			value	[red-value!]						;-- FORM argument
			buffer	[red-string!]						;-- FORM buffer
			part	[integer!]							;-- max bytes count
			flags   [integer!]
			return: [integer!]							;-- remaining part count
		] get-action-ptr value ACT_FORM

		action-form value buffer part flags
	]
	
	mold*: func [
		options		[integer!]
		/local
			buffer  [red-string!]
	][
		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push 16			;@@ /part argument
		mold stack/arguments buffer -1 options
		stack/set-last as red-value! buffer
	]
	
	mold: func [
		value   [red-value!]							;-- MOLD argument
		buffer  [red-string!]							;-- MOLD buffer
		part    [integer!]								;-- max bytes count
		flags   [integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/mold"]]

		action-mold: as function! [						;-- needs to be globally bound
			value	[red-value!]						;-- FORM argument
			buffer	[red-string!]						;-- FORM buffer
			part	[integer!]							;-- max bytes count
			flags	[integer!]
			return: [integer!]							;-- remaining part count
		] get-action-ptr value ACT_MOLD

		action-mold value buffer -1 flags
	]
	
	
	get-path*: func [][]
	set-path*: func [][]
	
	compare: func [
		value1  [red-value!]
		value2  [red-value!]
		op	    [integer!]
		return: [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/compare"]]

		action-compare: as function! [					;-- needs to be globally bound
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
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/add"]]

		action-add: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr* ACT_ADD
		action-add
	]
	
	divide*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/divide"]]

		action-divide: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_DIVIDE
		action-divide
	]
	
	multiply*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/multiply"]]

		action-multiply: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- multiplication resulting value
		] get-action-ptr* ACT_MULTIPLY
		action-multiply
	]
	
	negate*: func [][]
	power*: func [][]
	remainder*: func [][]
	round*: func [][]
	
	subtract*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/subtract"]]

		action-subtract: as function! [					;-- needs to be globally bound
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
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/append"]]

		action-append: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_APPEND
		action-append
	]
	
	at*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/at"]]

		action-at: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_AT
		action-at
	]
	
	back*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/back"]]

		action-back: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_BACK
		action-back
	]
	
	change*: func [][]
	
	clear*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/clear"]]

		action-clear: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_CLEAR
		action-clear
	]
	
	copy*: func [][]
	find*: func [][]
	
	head*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/head"]]

		action-head: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_HEAD
		action-head
	]
	
	head?*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/head?"]]

		action-head?: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_HEAD?
		action-head?
	]
	
	index?*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/index?"]]

		action-index?: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_INDEX?
		action-index?
	]
	insert*: func [][]
	
	length?*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/length?"]]

		action-length?: as function! [				;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_LENGTH?
		action-length?
	]
	
	next*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/next"]]

		action-next: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_NEXT
		action-next
	]
	
	pick*: func [
		return:	[red-value!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments + 1
		
		pick
			as red-series! stack/arguments
			int/value	
	]
	
	pick: func [
		series	[red-series!]
		index	[integer!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/pick"]]

		action-pick: as function! [						;-- needs to be globally bound
			series	[red-series!]
			index	[integer!]
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr as red-value! series ACT_PICK
		stack/set-last action-pick series index
	]

	poke*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/poke"]]

		action-poke: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_POKE
		action-poke
	]
	
	remove*: func [][]
	reverse*: func [][]
	select*: func [][]
	sort*: func [][]
	
	skip*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/skip"]]

		action-skip: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_SKIP
		action-skip
	]
	
	swap*: func [][]
	
	tail*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/tail"]]

		action-tail: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_TAIL
		action-tail
	]
	
	tail?*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/tail?"]]

		action-tail?: as function! [					;-- needs to be globally bound
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