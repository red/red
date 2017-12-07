Red/System [
	Title:	 "Port! datatype runtime functions"
	Author:	 "Xie Qingtian"
	File: 	 %port.reds
	Tabs:	 4
	Rights:	 "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

port: context [
	verbose: 0

	serialize: func [
		p		[red-port!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent?	[logic!]
		tabs	[integer!]
		mold?	[logic!]
		return: [integer!]
		/local
			formed [c-string!]
	][
		formed: string/to-hex p/handle false
		string/concatenate-literal buffer formed
		string/append-char GET_BUFFER(buffer) as-integer #"h"
		part - 9
	]

	;-- Actions --

	form: func [
		p		[red-port!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return:	[integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/form"]]
		
		serialize p buffer no no no arg part no 0 no
	]
	
	mold: func [
		p		[red-port!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/mold"]]
		
		string/concatenate-literal buffer "make port! ["
		part: serialize p buffer only? all? flat? arg part - 12 yes indent + 1 yes
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]

	compare: func [
		value1	[red-port!]							;-- first operand
		value2	[red-port!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			left  [integer!]
			right [integer!] 
	][
		#if debug? = yes [if verbose > 0 [print-line "port/compare"]]

		if TYPE_OF(value2) <> TYPE_PORT [return 1]
		SIGN_COMPARE_RESULT(value1/handle value2/handle)
	]
	
	init: does [
		datatype/register [
			TYPE_PORT
			TYPE_VALUE
			"port!"
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