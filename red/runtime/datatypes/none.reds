Red/System [
	Title:   "None! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %none.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

none-value: declare red-value!							;-- preallocate none! value
none-value/header: TYPE_NONE

none: context [
	verbose: 0
	
	push: func [
		return:		[red-value!]						;-- return cell pointer
		/local
			cell 	[red-none!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/push"]]

		cell: as red-none! stack/arguments
		cell/header: TYPE_NONE							;-- implicit reset of all header flags
		as red-value! cell
	]
		
	;-- Actions -- 

	make: func [
		return:		[red-value!]						;-- return cell pointer
	][
		#if debug? = yes [if verbose > 0 [print-line "none/make"]]

		push
	]
	
	form: func [
		part		[integer!]
		return: 	[integer!]
		/local
			buffer	[red-string!]
			series	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "none/form"]]

		buffer: as red-string! stack/arguments + 1
		assert TYPE_OF(buffer) = TYPE_STRING
		series: as series! buffer/node/value
		
		copy-memory
			as byte-ptr! series/offset
			as byte-ptr! "none"
			5											;-- includes null terminal character
		part											;@@ implement full support for /part
	]
	
	datatype/register [
		TYPE_NONE
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