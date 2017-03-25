Red/System [
	Title:   "Email! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %email.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

email: context [
	verbose: 0

	push: func [
		email [red-email!]
	][
		#if debug? = yes [if verbose > 0 [print-line "email/push"]]

		copy-cell as red-value! email stack/push*
	]

	;-- Actions --

	mold: func [
		email   [red-email!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "email/mold"]]
		
		url/mold as red-url! email buffer only? all? flat? arg part indent
	]
	
	eval-path: func [
		parent	[red-string!]								;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			part  [red-value!]
			w	  [red-word!]
			sym	  [integer!]
			pos	  [integer!]
			slots [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "email/eval-path"]]

		either TYPE_OF(element) = TYPE_WORD [
			w: as red-word! element
			sym: symbol/resolve w/symbol
			if all [sym <> words/user sym <> words/host][
				fire [TO_ERROR(script invalid-path) stack/arguments element]
			]
		][
			fire [TO_ERROR(script invalid-path) stack/arguments element]
		]
		
		pos: string/rs-find parent as-integer #"@"
		if pos = -1 [pos: string/rs-length? parent]
		parent: string/push parent
		
		part: either sym = words/user [
			as red-value! integer/push pos
		][
			parent/head: pos + 1
			either value = null [null][
				as red-value! integer/push string/rs-length? parent
			]
		]
		either value <> null [
			_series/change as red-series! parent value part no null
			object/check-owner as red-value! parent
		][
			value: stack/push*
			_series/copy as red-series! parent as red-series! value part no	null 
		]
		
		slots: either part = null [2][3]
		stack/pop slots									;-- avoid moving stack top
		value
	]

	init: does [
		datatype/register [
			TYPE_EMAIL
			TYPE_STRING
			"email!"
			;-- General actions --
			INHERIT_ACTION	;make
			null			;random
			INHERIT_ACTION	;reflect
			INHERIT_ACTION	;to
			INHERIT_ACTION	;form
			:mold
			:eval-path
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
