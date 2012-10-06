Red/System [
	Title:   "Datatype! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %datatype.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

datatype: context [
	verbose: 0

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
		count	[integer!]
		list	[int-ptr!]
		/local
			type  [integer!]
			index [integer!]
	][
		type: list/value
		assert type < 50								;-- hard limit of action table
		list: list + 1
		
		index: type + 1									;-- one-based
		name-table/index: list/value
		list: list + 1
		count: count - 2
		
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
			action-table/index: list/value
			index: index + 1
			list: list + 1
			count: count - 1
			zero? count
		]
	]
	
	push: func [
		type	[integer!]
		/local
			dt  [red-datatype!]
	][
		#if debug? = yes [if verbose > 0 [print-line "datatype/push"]]

		dt: as red-datatype! stack/push
		dt/header: TYPE_DATATYPE						;-- implicit reset of all header flags	
		dt/value: type
	]
	
	;-- Actions --

	make: func [
		return:	 [red-value!]							;-- return datatype cell pointer
		/local
			arg  [red-value!]
			dt   [red-datatype!]
			type [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "datatype/make"]]
		
		arg: stack/arguments
		dt:  as red-datatype! arg
		assert TYPE_OF(dt) = TYPE_DATATYPE
		
		dt/header: TYPE_DATATYPE						;-- implicit reset of all header flags	
		type: as red-integer! arg + 1
		dt/value: type/value		
		as red-value! dt
	]
	
	form: func [
		part	 [integer!]
		return:  [integer!]
		/local
			dt   [red-datatype!]
			str  [red-string!]
			name [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "datatype/form"]]

		dt: as red-datatype! stack/arguments
		str: as red-string! stack/arguments + 1
		assert TYPE_OF(str) = TYPE_STRING

		name: name-table + dt/value
		string/concatenate-literal str as c-string! name/value
		part											;@@ implement full support for /part
	]
	
	register [
		TYPE_DATATYPE
		"datatype"
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		:form
		null			;mold
		null			;get-path
		null			;set-path
		null			;compare
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
		null			;index-of
		null			;insert
		null			;length-of
		null			;next
		null			;pick
		null			;poke
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

