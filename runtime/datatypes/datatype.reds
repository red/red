Red/System [
	Title:   "Datatype! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %datatype.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

datatype: context [
	verbose: 0
	top-id:  0											;-- last type ID registered
	
	make-words: func [
		/local
			name [names!]
			i	 [integer!]
	][
		i: 1
		until [
			name: name-table + i
			name/word: word/load name/buffer
			i: i + 1
			i > top-id
		]
	]

	;-------------------------------------
	;-- Load actions table with a new datatype set of function pointers
	;--
	;-- Input: block of values with type ID in first place followed by
	;-- actions pointers.
	;--
	;-- Returns: -
	;-------------------------------------
	register: func [
		[variadic]
		count		[integer!]
		list		[int-ptr!]
		/local
			type	[integer!]
			index	[integer!]
			parent	[integer!]
			idx		[integer!]
			name	[names!]
	][
		type: list/value
		assert type < 50								;-- hard limit of action table
		if type > top-id [top-id: type]					;@@ unreliable, needs automatic type IDs
		list: list + 1
		
		parent: list/value
		list: list + 1
		
		name: name-table + type
		name/buffer: as c-string! list/value			;-- store datatype string name
		name/size: (length? name/buffer) - 1			;-- store string size (not counting terminal `!`)
		if root <> null [								;-- checks if all datatypes have been loaded
			name/word: word/load name/buffer
		]
		list: list + 1
		count: count - 3								;-- skip the "header" data
		
		if count <> ACTIONS_NB [
			print [
				"*** Datatype Error: invalid actions count for type: " type lf
				"*** Found: " count lf
				"*** Expected: " ACTIONS_NB lf
			]
			halt
		]
		
		index: type << 8 + 1							;-- consume first argument (type ID), one-based index
		until [
			action-table/index: either all [
				parent <> TYPE_VALUE
				list/value = INHERIT_ACTION
			][
				idx: parent << 8 + 1 + (ACTIONS_NB - count)
				action-table/idx						;-- inherit action from parent
			][
				list/value
			]
			index: index + 1
			list: list + 1
			count: count - 1
			zero? count
		]
	]
	
	make-in: func [
		parent	[red-block!]
		type	[integer!]
		return: [red-datatype!]
		/local
			dt  [red-datatype!]
	][
		#if debug? = yes [if verbose > 0 [print-line "datatype/make-in"]]

		dt: as red-datatype! ALLOC_TAIL(parent)
		dt/header: TYPE_DATATYPE						;-- implicit reset of all header flags	
		dt/value: type
		dt
	]
	
	push: func [
		type	[integer!]
		return: [red-datatype!]
		/local
			dt  [red-datatype!]
	][
		#if debug? = yes [if verbose > 0 [print-line "datatype/push"]]

		dt: as red-datatype! stack/push*
		dt/header: TYPE_DATATYPE						;-- implicit reset of all header flags	
		dt/value: type
		dt
	]
	
	;-- Actions --

	form: func [
		dt		 [red-datatype!]
		buffer	 [red-string!]
		arg		 [red-value!]
		part	 [integer!]
		return:  [integer!]
		/local
			name [names!]
	][
		#if debug? = yes [if verbose > 0 [print-line "datatype/form"]]
		
		name: name-table + dt/value
		string/concatenate-literal-part buffer name/buffer name/size
		part - name/size
	]
	
	mold: func [
		dt		[red-datatype!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			name [names!]
	][
		#if debug? = yes [if verbose > 0 [print-line "datatype/mold"]]

		name: name-table + dt/value	
		string/concatenate-literal-part buffer name/buffer name/size + 1
		part - name/size - 1
	]
	
	compare: func [
		arg1      [red-datatype!]						;-- first operand
		arg2	  [red-datatype!]						;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [integer!]
		/local
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "datatype/compare"]]

		switch op [
			COMP_EQUAL
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL	  [
				res: as-integer any [TYPE_OF(arg2) <> TYPE_DATATYPE arg1/value <> arg2/value]
			]
			default [
				res: -2
			]
		]
		res
	]
	
	init: does [
		register [
			TYPE_DATATYPE
			TYPE_VALUE
			"datatype!"
			;-- General actions --
			null			;make
			null			;random
			null			;reflect
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

