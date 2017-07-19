Red/System [
	Title:   "Action! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %action.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

action: context [
	verbose: 0
	
	push: func [
		/local
			cell  [red-action!]
	][
		#if debug? = yes [if verbose > 0 [print-line "action/push"]]
		
		cell: as red-action! stack/push*
		cell/header: TYPE_ACTION
		;...TBD
	]
	
	;-- Actions -- 
	
	make: func [
		proto	[red-value!]
		spec	[red-block!]
		type	[integer!]
		return:	[red-action!]							;-- return action cell pointer
		/local
			list   [red-block!]
			action [red-action!]
			s	   [series!]
			index  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "action/make"]]
		
		if TYPE_OF(spec) <> TYPE_BLOCK [throw-make proto spec]
		s: GET_BUFFER(spec)
		list: as red-block! s/offset
		if list + list/head + 2 <> s/tail [throw-make proto spec]
		
		action: as red-action! stack/push*
		action/header:	TYPE_ACTION						;-- implicit reset of all header flags
		action/spec:    list/node						; @@ copy spec block if not at head
		action/args: 	null
		
		list: list + 1
		if TYPE_OF(list) <> TYPE_INTEGER [throw-make proto spec]
		index: integer/get as red-value! list			;-- action IDs are one-based
		if any [index < 1 index > ACTIONS_NB][throw-make proto spec]
		action/code: actions/table/index
		
		action
	]
	
	form: func [
		value	[red-action!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "action/form"]]

		string/concatenate-literal buffer "?action?"
		part - 8
	]
	
	mold: func [
		action	[red-action!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "action/mold"]]

		string/concatenate-literal buffer "make action! ["
		
		part: block/mold								;-- mold spec
			native/reflect action words/spec
			buffer
			only?
			all?
			flat?
			arg
			part - 14
			indent
		
		string/concatenate-literal buffer "]"
		part - 1
	]

	compare: func [
		arg1	[red-action!]							;-- first operand
		arg2	[red-action!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "action/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_ACTION [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				res: SIGN_COMPARE_RESULT(arg1/code arg2/code)
			]
			default [
				res: -2
			]
		]
		res
	]

	init: does [
		datatype/register [
			TYPE_ACTION
			TYPE_NATIVE
			"action!"
			;-- General actions --
			:make
			null			;random
			INHERIT_ACTION	;reflect
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