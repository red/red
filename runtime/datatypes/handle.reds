Red/System [
	Title:	 "Handle! datatype runtime functions"
	Author:	 "Nenad Rakocevic, Oldes"
	File: 	 %handle.reds
	Tabs:	 4
	Rights:	 "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

handle: context [
	verbose: 0
	
	#enum handle-classes! [
		CLASS_NULL										;-- null class (to be removed)
		CLASS_FD										;-- file descriptor
		CLASS_MONITOR									;-- display monitor handle
		CLASS_WINDOW									;-- window handle
		CLASS_FONT										;-- font handle
		CLASS_RICHTEXT									;-- rich-text handle
		CLASS_DEVICE
	]
	
	names: ["null" "fd" "monitor" "window" "font" "rich-text"]
	
	box: func [
		value	[integer!]
		type	[integer!]
		return:	[red-handle!]
	][
		make-at stack/arguments value type
	]

	make-in: func [
		parent 	[red-block!]
		value 	[integer!]
		type	[integer!]
		return: [red-handle!]
	][
		#if debug? = yes [if verbose > 0 [print-line "handle/make-in"]]
		make-at ALLOC_TAIL(parent) value type
	]

	make-at: func [
		slot	[red-value!]
		value	[integer!]
		type	[integer!]
		return:	[red-handle!]
		/local
			h	[red-handle!]
	][
		h: as red-handle! slot
		h/header: TYPE_HANDLE
		h/type:	  type
		h/value:  value
		h/extID:  -1
		h
	]

	push: func [
		value	[handle!]
		type	[integer!]
		return: [red-handle!]
	][
		#if debug? = yes [if verbose > 0 [print-line "handle/push"]]
		make-at stack/push* as integer! value type
	]
	
	push-null: func [return: [red-handle!]][push as handle! 0 CLASS_NULL]

	;-- Actions --

	form: func [
		h		[red-handle!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return:	[integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "handle/form"]]
		
		formed: string/to-hex h/value false
		string/concatenate-literal buffer formed
		string/append-char GET_BUFFER(buffer) as-integer #"h"
		part - 9
	]
	
	mold: func [
		h		[red-handle!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			type [integer!]
	][
		#if debug? = yes [
			all?: yes			;-- show handle in debug mode
			if verbose > 0 [print-line "handle/mold"]
		]

		either all? [
			string/concatenate-literal buffer "#[handle! "
			part: form h buffer arg part
			type: h/type
			if type > 0 [
				string/append-char GET_BUFFER(buffer) as-integer space
				string/concatenate-literal buffer as-c-string names/type
				part: part + 1 + length? as-c-string names/type
			]
			string/append-char GET_BUFFER(buffer) as-integer #"]"
			part + 11
		][
			string/concatenate-literal buffer "handle!"
			part + 7
		]
	]

	compare: func [
		value1	[red-handle!]							;-- first operand
		value2	[red-handle!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			left  [integer!]
			right [integer!] 
	][
		#if debug? = yes [if verbose > 0 [print-line "handle/compare"]]

		if TYPE_OF(value2) <> TYPE_HANDLE [return 1]
		SIGN_COMPARE_RESULT(value1/value value2/value)
	]
	
	init: does [
		names: names + 1								;-- make this array 0-based
		
		datatype/register [
			TYPE_HANDLE
			TYPE_INTEGER
			"handle!"
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