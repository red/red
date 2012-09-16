Red/System [
	Title:   "Char! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %char.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

char: context [

	push: func [
		value	 [integer!]
		/local
			cell [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/push"]]
		cell: as red-char! stack/push
		cell/header: TYPE_CHAR
		cell/value: value
	]
	
	;-- Actions -- 
	
	form: func [
		part 	[integer!]
		/local
			arg [red-char!]
	][
		arg: as red-char! stack/arguments
		;...
	]
	

	datatype/register [
		TYPE_CHAR
		;-- General actions --
		null			;make
		null			;random
		null			;reflect
		null			;to
		null			;form
		null			;mold
		null			;get-path
		null			;set-path
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