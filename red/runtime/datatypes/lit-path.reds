Red/System [
	Title:   "Lit-path! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %lit-path.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

lit-path: context [
	verbose: 0
	
	push*: func [
		size	[integer!]
		return: [red-lit-path!]	
		/local
			p 	[red-lit-path!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-path/push*"]]
		
		p: as red-lit-path! ALLOC_TAIL(root)
		p/header: TYPE_LIT_PATH							;-- implicit reset of all header flags
		p/head:   0
		p/node:   alloc-cells size
		push p
		p
	]
	
	push: func [
		p [red-lit-path!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-path/push"]]

		p/header: TYPE_LIT_PATH							;@@ type casting (from block! to path!)
		copy-cell as red-value! p stack/push*
	]


	;--- Actions ---
	
	make: func [
		proto 	 [red-value!]
		spec	 [red-value!]
		return:	 [red-lit-path!]
		/local
			path [red-lit-path!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-path/make"]]

		path: as red-lit-path! block/make proto spec
		path/header: TYPE_LIT_PATH
		path
	]
	
	form: func [
		p		[red-lit-path!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-path/form"]]
		
		string/append-char GET_BUFFER(buffer) as-integer #"'"
		path/form p buffer arg part - 1
	]
	
	mold: func [
		p		[red-lit-path!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-path/mold"]]

		form p buffer arg part
	]
	
	compare: func [
		value1	   [red-block!]							;-- first operand
		value2	   [red-block!]							;-- second operand
		op		   [integer!]							;-- type of comparison
		return:	   [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "lit-path/compare"]]

		if TYPE_OF(value2) <> TYPE_LIT_PATH [RETURN_COMPARE_OTHER]
		block/compare-each value1 value2 op
	]

	datatype/register [
		TYPE_LIT_PATH
		TYPE_PATH
		"lit-path!"
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		:form
		:mold
		null			;get-path
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
		INHERIT_ACTION	;append
		INHERIT_ACTION	;at
		INHERIT_ACTION	;back
		null			;change
		INHERIT_ACTION	;clear
		INHERIT_ACTION	;copy
		INHERIT_ACTION	;find
		INHERIT_ACTION	;head
		INHERIT_ACTION	;head?
		INHERIT_ACTION	;index?
		null			;insert
		INHERIT_ACTION	;length?
		INHERIT_ACTION	;next
		INHERIT_ACTION	;pick
		INHERIT_ACTION	;poke
		null			;remove
		null			;reverse
		INHERIT_ACTION	;select
		null			;sort
		INHERIT_ACTION	;skip
		null			;swap
		INHERIT_ACTION	;tail
		INHERIT_ACTION	;tail?
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