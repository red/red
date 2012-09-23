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

	get-action-ptr: func [
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			arg  [red-value!]
			type  [integer!]
			dt	  [red-datatype!]
			index [integer!]
	][
		arg: stack/arguments
		type: arg/header and get-type-mask
		
		if type = TYPE_DATATYPE [
			dt: as red-datatype! arg
			type: dt/value
		]
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

	;--- Actions polymorphic calls ---

	make: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/make"]]

		action-make: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- newly created value
		] get-action-ptr ACT_MAKE
		action-make 
	]

	random: func [][]
	reflect: func [][]
	to: func [][]

	form: func [
		part [logic!]
		/local
			str  [node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/form"]]

		action-form: as function! [						;-- needs to be globally bound
			part	[integer!]							;-- max bytes count
			return: [integer!]							;-- remaining part count
		] get-action-ptr ACT_FORM

		str: string/rs-make-at stack/push either part [16][16] ;@@ /part argument
		action-form 0
	]

	mold: func [][]
	get-path: func [][]
	set-path: func [][]
	
	absolute: func [][]
	
	add: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/add"]]

		action-add: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr ACT_ADD
		action-add
	]
	
	divide: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/divide"]]

		action-divide: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr ACT_DIVIDE
		action-divide
	]
	
	multiply: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/multiply"]]

		action-multiply: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- multiplication resulting value
		] get-action-ptr ACT_MULTIPLY
		action-multiply
	]
	
	negate: func [][]
	power: func [][]
	remainder: func [][]
	round: func [][]
	
	subtract: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/subtract"]]

		action-subtract: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr ACT_SUBTRACT
		action-subtract
	]
	
	even?: func [][]
	odd?: func [][]
	and~: func [][]
	complement: func [][]
	or~: func [][]
	xor~: func [][]
	
	append: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/append"]]

		action-append: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_APPEND
		action-append
	]
	
	at: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/at"]]

		action-at: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_AT
		action-at
	]
	
	back: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/back"]]

		action-back: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_BACK
		action-back
	]
	
	change: func [][]
	
	clear: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/clear"]]

		action-clear: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_CLEAR
		action-clear
	]
	
	copy: func [][]
	find: func [][]
	
	head: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/head"]]

		action-head: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_HEAD
		action-head
	]
	
	head?: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/head?"]]

		action-head?: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_HEAD?
		action-head?
	]
	
	index-of: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/index-of"]]

		action-index-of: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_INDEX_OF
		action-index-of
	]
	insert: func [][]
	
	length-of: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/length-of"]]

		action-length-of: as function! [				;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_LENGTH_OF
		action-length-of
	]
	
	next: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/next"]]

		action-next: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_NEXT
		action-next
	]
	
	pick: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/pick"]]

		action-pick: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_PICK
		action-pick
	]
	
	poke: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/poke"]]

		action-poke: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_POKE
		action-poke
	]
	
	remove: func [][]
	reverse: func [][]
	select: func [][]
	sort: func [][]
	
	skip: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/skip"]]

		action-skip: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_SKIP
		action-skip
	]
	
	swap: func [][]
	
	tail: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/tail"]]

		action-tail: as function! [						;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_TAIL
		action-tail
	]
	
	tail?: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/tail?"]]

		action-tail?: as function! [					;-- needs to be globally bound
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr ACT_TAIL?
		action-tail?
	]

	
	take: func [][]
	trim: func [][]
	create: func [][]
	close: func [][]
	delete: func [][]
	modify: func [][]
	open: func [][]
	open?: func [][]
	query: func [][]
	read: func [][]
	rename: func [][]
	update: func [][]
	write: func [][]
]