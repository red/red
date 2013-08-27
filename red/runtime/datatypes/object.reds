Red/System [
	Title:   "Object! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %object.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

object: context [
	verbose: 0
	
	serialize: func [
		obj		[red-object!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent? [logic!]
		return: [integer!]
		/local
			syms	[series!]
			values	[series!]
			sym		[red-value!]
			s-tail	[red-value!]
			value	[red-value!]
	][
		syms:   as series! obj/symbols/value
		values: as series! obj/values/value
		
		sym:	syms/offset
		s-tail: syms/tail
		value: 	values/offset
		
		while [sym < s-tail][
			if indent? [
				string/concatenate-literal buffer "    "
				part: part - 4
			]
			
			part: word/mold as red-word! sym buffer no no flat? arg part
			string/concatenate-literal buffer ": "
			part: part - 2
			
			part: actions/mold value buffer only? all? flat? arg part
			
			if any [indent? sym + 1 < s-tail][			;-- no final LF when FORMed
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			sym: sym + 1
			value: value + 1
		]
		part
	] 
	
	;-- Actions -- 
	
	make: func [
		proto	[red-object!]
		spec	[red-block!]
		return:	[red-object!]
		/local
			obj	 [red-object!]
			cell [red-value!]
			slot [red-word!]
			s	 [series!]
			type [integer!]
			i	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/make"]]
		
		obj: as red-object! _context/create root block/rs-length? spec no
		obj/header: TYPE_OBJECT
		
		s: GET_BUFFER(spec)
		cell: s/offset
		i: 0
		
		while [cell < s/tail][							;-- collecting context's set-words
			type: TYPE_OF(cell)
			if type = TYPE_SET_WORD [					;-- add new word to context
				slot: as red-word! alloc-tail as series! obj/symbols/value
				copy-cell cell as red-value! slot
				slot/header: TYPE_WORD
				slot/ctx: as red-context! obj
				slot/index: i
				i: i + 1
			]
			cell: cell + 1
		]
		
		_context/bind spec as red-context! obj
		interpreter/eval spec
		obj
	]
	
	form: func [
		obj		[red-object!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/form"]]

		serialize obj buffer no no no arg part no
	]
	
	mold: func [
		obj		[red-object!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/mold"]]
		
		string/concatenate-literal buffer "make object! [^/"
		part: serialize obj buffer only? all? flat? arg part - 15 yes
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]
	
	eval-path: func [
		parent	[red-object!]							;-- implicit type casting
		element	[red-value!]
		set?	[logic!]
		return:	[red-value!]
		/local
			word [red-word!]
			ctx  [red-context!]
	][
		word: as red-word! element
		ctx:  as red-context! parent 

		if word/ctx <> ctx [							;-- bind the word to object's context
			word/index: _context/find-word ctx word/symbol
			word/ctx: ctx
		]
		either set? [
			_context/set-in word stack/arguments ctx 
			stack/arguments
		][
			_context/get-in word ctx
		]
	]
	
	init: does [
		datatype/register [
			TYPE_OBJECT
			TYPE_VALUE
			"object!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
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
]