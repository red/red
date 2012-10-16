Red/System [
	Title:   "Red action functions"
	Author:  "Nenad Rakocevic"
	File: 	 %actions.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

actions: context [
	verbose: 0
	
	;@@ temporary stack-oriented version kept until internal API fully changed
	get-action-ptr*: func [
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			arg  [red-value!]
			type  [integer!]
			index [integer!]
	][
		arg: stack/arguments
		index: TYPE_OF(arg) << 8 + action
		index: action-table/index						;-- lookup action function pointer

		if zero? index [
			print-line [
				"^/*** Script error: action " action
				" not defined for type: " TYPE_OF(arg)
			]
			halt
		]
		index
	]	

	get-action-ptr: func [
		value	[red-value!]
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			index [integer!]
	][
		index: TYPE_OF(value) << 8 + action
		index: action-table/index						;-- lookup action function pointer

		if zero? index [
			print-line [
				"^/*** Script error: action " action
				" not defined for type: " TYPE_OF(value)
			]
			halt
		]
		index
	]	

	;--- Actions polymorphic calls ---

	make*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/make"]]

		action-make: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- newly created value
		] get-action-ptr* ACT_MAKE
		action-make 
	]

	random*: func [][]
	reflect*: func [][]
	to*: func [][]

	form*: func [
		/local
			buffer  [red-string!]
			part 	[logic!]
	][
		part: off										;@@ TBD
		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push either part [16][16] ;@@ /part argument
		form stack/arguments buffer -1
		stack/set-last as red-value! buffer
	]
	
	form: func [
		value   [red-value!]							;-- FORM argument
		buffer  [red-string!]							;-- FORM buffer
		part    [integer!]								;-- max bytes count
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/form"]]

		action-form: as function! [						;-- needs to be globally bound
			value	[red-value!]						;-- FORM argument
			buffer	[red-string!]						;-- FORM buffer
			part	[integer!]							;-- max bytes count
			return: [integer!]							;-- remaining part count
		] get-action-ptr value ACT_FORM

		action-form value buffer -1
	]
	
	mold*: func [
		/local
			buffer  [red-string!]
			flags 	[integer!]
	][
		flags: 0										;@@ fill flags testing refinements presence
		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push 16			;@@ /part argument
		mold stack/arguments buffer -1 flags
		stack/set-last as red-value! buffer
	]
	
	mold: func [
		value   [red-value!]							;-- MOLD argument
		buffer  [red-string!]							;-- MOLD buffer
		part    [integer!]								;-- max bytes count
		flags   [integer!]								;-- 0: /only, 1: /all, 2: /flat
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/mold"]]

		action-mold: as function! [						;-- needs to be globally bound
			value	[red-value!]						;-- FORM argument
			buffer	[red-string!]						;-- FORM buffer
			part	[integer!]							;-- max bytes count
			flags	[integer!]							;-- 0: /only, 1: /all, 2: /flat
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
		] get-action-ptr* ACT_COMPARE
		
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
	
	index-of*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/index-of"]]

		action-index-of: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_INDEX_OF
		action-index-of
	]
	insert*: func [][]
	
	length-of*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/length-of"]]

		action-length-of: as function! [				;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_LENGTH_OF
		action-length-of
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