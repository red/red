Red/System [
	Title:   "Error! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %error.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

error: context [
	verbose: 0
	
	push: func [
		return:	 [red-value!]							;-- return cell pointer
		/local
			cell [red-object!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/push"]]

		cell: as red-object! stack/push*
		cell/header: TYPE_ERROR							;-- implicit reset of all header flags
		;TBD
		as red-value! cell
	]
		
	;-- Actions -- 

	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-object!]
		/local
			cell [red-object!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/make"]]

		cell: as red-object! stack/push*
		cell/header: TYPE_ERROR							;-- implicit reset of all header flags
		;TBD
		cell
	]
	
	form: func [
		value	[red-object!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/form"]]
		
		;TBD
		part
	]
	
	mold: func [
		obj		[red-object!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/mold"]]

		string/concatenate-literal buffer "make error! ["
		part: object/serialize obj buffer only? all? flat? arg part - 13 yes indent + 1
		if indent > 0 [part: object/do-indent buffer indent part]
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]

	init: does [
		datatype/register [
			TYPE_ERROR
			TYPE_OBJECT
			"error!"
			;-- General actions --
			:make
			null			;random
			INHERIT_ACTION	;reflect
			null			;to
			:form
			:mold
			INHERIT_ACTION	;eval-path
			null			;set-path
			INHERIT_ACTION	;compare
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
			INHERIT_ACTION	;copy
			INHERIT_ACTION	;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;next
			null			;pick
			null			;poke
			null			;remove
			null			;reverse
			INHERIT_ACTION	;select
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