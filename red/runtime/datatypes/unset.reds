Red/System [
	Title:   "Unset! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %unset.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

unset-value: declare red-value!							;-- preallocate unset! value
unset-value/header: TYPE_UNSET

unset: context [
	verbose: 0
	
	;-- Actions -- 

	make: func [
		return:		[red-value!]						;-- return unset cell pointer
		/local
			cell 	[red-unset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/make"]]
		
		cell: as red-unset! stack/arguments
		cell/header: TYPE_UNSET							;-- implicit reset of all header flags
		as red-value! cell
	]

	form: func [
		value	[red-unset!]
		buffer	[red-string!]
		part	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unset/form"]]
		
		string/concatenate-literal buffer "unset"
		part											;@@ implement full support for /part
	]

	datatype/register [
		TYPE_UNSET
		"unset"
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