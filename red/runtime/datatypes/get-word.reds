Red/System [
	Title:   "Get-word! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %get-word.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

get-word: context [
	verbose: 0
	
	load: func [
		str 	 [c-string!]
		return:	 [red-word!]
		/local 
			p	 [node!]
			id   [integer!]								;-- symbol ID
			cell [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "get-word/load"]]
		
		cell: word/load str
		cell/header: TYPE_GET_WORD						;-- implicit reset of all header flags
		cell
	]
	
	push: func [
		w  [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "get-word/push"]]
		
		w: word/push w
		set-type as red-value! w TYPE_GET_WORD
	]

	set: func [
		/local
			args [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "get-word/set"]]
		
		args: stack/arguments
		_context/set as red-word! args args + 1
		stack/set-last args + 1
	]
	
	get: does [
		#if debug? = yes [if verbose > 0 [print-line "get-word/get"]]
		
		stack/set-last _context/get as red-word! stack/arguments
	]
	
	;-- Actions --
	
	form: func [
		w		[red-word!]
		buffer	[red-string!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "get-word/form"]]

		word/form w buffer part							;@@ implement full support for /part
	]
	
	mold: func [
		w		[red-word!]
		buffer	[red-string!]
		part 	[integer!]
		flags   [integer!]								;-- 0: /only, 1: /all, 2: /flat
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "get-word/mold"]]

		string/append-char GET_BUFFER(buffer) as-integer #":"
		word/form w buffer part							;@@ implement full support for /part
	]
	
	datatype/register [
		TYPE_GET_WORD
		TYPE_VALUE
		"get-word"
		;-- General actions --
		null			;make
		null			;random
		null			;reflect
		null			;to
		:form
		:mold
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
		null			;index?
		null			;insert
		null			;length?
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
