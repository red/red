Red/System [
	Title:   "Triple! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %triple.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

triple: context [
	verbose: 0

	;-- Actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-triple!]
	][
		#if debug? = yes [if verbose > 0 [print-line "triple/make"]]

		as red-triple! 0
	]
	
	form: func [
		triple	[red-triple!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "triple/form"]]
		
		string/concatenate-literal buffer "make triple! ["
		part: part - 13
		
		formed: integer/form-signed triple/x
		string/concatenate-literal buffer formed
		string/append-char GET_BUFFER(buffer) as-integer #" "
		part: part - 1 - length? formed
		
		formed: integer/form-signed triple/y
		string/concatenate-literal buffer formed
		string/append-char GET_BUFFER(buffer) as-integer #" "
		part: part - 1 - length? formed
		
		formed: integer/form-signed triple/z
		string/concatenate-literal buffer formed
		part: part - length? formed
		
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]
	
	mold: func [
		triple	[red-triple!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "triple/mold"]]

		form triple buffer arg part
	]
	
	init: does [
		datatype/register [
			TYPE_TRIPLE
			TYPE_VALUE
			"triple!"
			;-- General actions --
			null			;make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			null			;eval-path
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