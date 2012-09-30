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
	
	mold: func [
		part 		[integer!]
		/local
			arg		[red-char!]
			str		[red-string!]
			series	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/mold"]]

		arg: as red-char! stack/arguments
		str: as red-string! arg + 1
		assert TYPE_OF(str) = TYPE_STRING

		series: GET_BUFFER(str)
		string/append-char series as-integer #"#"
		string/append-char series as-integer #"^""
		string/append-char series arg/value
		string/append-char series as-integer #"^""
		part											;@@ implement full support for /part
	]
	
	form: func [
		part 		[integer!]
		/local
			arg		[red-char!]
			str		[red-string!]
			series	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/form"]]

		arg: as red-char! stack/arguments
		str: as red-string! arg + 1
		assert TYPE_OF(str) = TYPE_STRING

		series: GET_BUFFER(str)
		string/append-char series arg/value
		part											;@@ implement full support for /part
	]
	
	add: func [
		return:  [red-value!]
		/local
			char [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/add"]]
		char: as red-char! integer/do-math OP_ADD
		char/header: TYPE_CHAR
		as red-value! char 
	]

	divide: func [
		return:  [red-value!]
		/local
			char [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/divide"]]
		char: as red-char! integer/do-math OP_DIV
		char/header: TYPE_CHAR
		as red-value! char 
	]

	multiply: func [
		return:  [red-value!]
		/local
			char [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/multiply"]]
		char: as red-char! integer/do-math OP_MUL
		char/header: TYPE_CHAR
		as red-value! char 
	]

	subtract: func [
		return:  [red-value!]
		/local
			char [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "char/subtract"]]
		char: as red-char! integer/do-math OP_SUB
		char/header: TYPE_CHAR
		as red-value! char 
	]

	datatype/register [
		TYPE_CHAR
		;-- General actions --
		null			;make
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
		:add
		:divide
		:multiply
		null			;negate
		null			;power
		null			;remainder
		null			;round
		:subtract
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