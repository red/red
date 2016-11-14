Red/System [
	Title:   "Tag! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %tag.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

tag: context [
	verbose: 0

	push: func [
		tag [red-tag!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tag/push"]]

		copy-cell as red-value! tag stack/push*
	]

	;-- Actions --

	form: func [
		tag		  [red-tag!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part	  [integer!]
		return:	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tag/form"]]

		string/append-char GET_BUFFER(buffer) as-integer #"<"
		part: string/form as red-string! tag buffer arg part - 1
		string/append-char GET_BUFFER(buffer) as-integer #">"
		part - 1
	]

	mold: func [
		tag     [red-tag!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tag/mold"]]
		
		form tag buffer arg part - 1
	]

	init: does [
		datatype/register [
			TYPE_TAG
			TYPE_STRING
			"tag!"
			;-- General actions --
			INHERIT_ACTION	;make
			null			;random
			INHERIT_ACTION	;reflect
			INHERIT_ACTION	;to
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
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			INHERIT_ACTION	;change
			INHERIT_ACTION	;clear
			INHERIT_ACTION	;copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			INHERIT_ACTION	;insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;move
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			INHERIT_ACTION	;put
			INHERIT_ACTION	;remove
			INHERIT_ACTION	;reverse
			INHERIT_ACTION	;select
			null			;sort
			INHERIT_ACTION	;skip
			INHERIT_ACTION	;swap
			INHERIT_ACTION	;tail
			INHERIT_ACTION	;tail?
			INHERIT_ACTION	;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			INHERIT_ACTION	;modify
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
