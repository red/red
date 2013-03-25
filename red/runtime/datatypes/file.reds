Red/System [
	Title:   "File! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %file.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

file: context [
	verbose: 0
	
	load-in: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		blk		 [red-block!]
		return:  [red-string!]
		/local
			cell [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/load"]]
		
		cell: string/load-in src size blk
		cell/header: TYPE_FILE							;-- implicit reset of all header flags
		cell
	]
	
	load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		return:  [red-string!]
	][
		load-in src size root
	]

	
	push: func [
		file [red-file!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/push"]]
		
		copy-cell as red-value! file stack/push*
	]
	
	;-- Actions --
	
	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		type	 [integer!]
		return:	 [red-file!]
		/local
			file [red-file!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/make"]]

		file: as red-file! string/make proto spec type
		set-type as red-value! file TYPE_FILE
		file
	]
	
	mold: func [
		file    [red-file!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/mold"]]

		string/append-char GET_BUFFER(buffer) as-integer #"%"
		string/form file buffer arg part - 1
	]
	
	datatype/register [
		TYPE_FILE
		TYPE_STRING
		"file!"
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		INHERIT_ACTION	;form
		:mold
		null			;get-path
		null			;set-path
		INHERIT_ACTION	;:compare
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
		INHERIT_ACTION	;append
		INHERIT_ACTION	;at
		INHERIT_ACTION	;back
		null			;change
		INHERIT_ACTION	;clear
		INHERIT_ACTION	;copy
		INHERIT_ACTION	;find
		INHERIT_ACTION	;head
		INHERIT_ACTION	;head?
		INHERIT_ACTION	;index?
		null			;insert
		INHERIT_ACTION	;length?
		INHERIT_ACTION	;next
		INHERIT_ACTION	;pick
		INHERIT_ACTION	;poke
		INHERIT_ACTION	;remove
		null			;reverse
		INHERIT_ACTION	;select
		null			;sort
		INHERIT_ACTION	;skip
		null			;swap
		INHERIT_ACTION	;tail
		INHERIT_ACTION	;tail?
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
