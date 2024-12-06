Red/System [
	Title:   "Native! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %native.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

native: context [
	verbose: 0
	
	;-- Actions -- 
	
	make: func [
		proto	[red-value!]
		spec	[red-block!]
		type	[integer!]
		return:	[red-native!]						;-- return native cell pointer
		/local
			list   [red-block!]
			native [red-native!]
			value  [red-value!]
			more s [series!]
			node   [node!]
			index  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/make"]]
		
		if TYPE_OF(spec) <> TYPE_BLOCK [throw-make proto spec]
		s: GET_BUFFER(spec)
		list: as red-block! s/offset
		if list + list/head + 2 <> s/tail [throw-make proto spec]

		native: as red-native! stack/push*
		native/header:  TYPE_UNSET
		native/spec:	list/node						; @@ copy spec block if not at head
		native/more:	alloc-unset-cells 2
		native/header:  TYPE_NATIVE						;-- implicit reset of all header flags
		
		more: as series! native/more/value
		node: _context/make spec yes no CONTEXT_FUNCTION
		copy-cell as red-value! (as series! node/value) + 1 alloc-tail more	;-- ctx slot
		value: alloc-tail more							;-- args cache slot
		value/header: TYPE_NONE
		
		list: list + 1
		if TYPE_OF(list) <> TYPE_INTEGER [throw-make proto spec]
		index: integer/get as red-value! list
		if any [index < 1 index > NATIVES_NB][throw-make proto spec]
		native/code: natives/table/index
		native
	]
	
	reflect: func [
		native	[red-native!]
		field	[integer!]
		return:	[red-block!]
		/local
			blk   [red-block!]
			table [int-ptr!]
			index [integer!]
			node  [node!]
			s	  [series!]
			type  [integer!]
	][
		case [
			field = words/spec [
				blk: as red-block! stack/arguments
				blk/header: TYPE_BLOCK					;-- implicit reset of all header flags
				blk/node:	native/spec
				blk/head:	0
			]
			field = words/body [
				type: GET_OP_SUBTYPE(native)
				either all [TYPE_OF(native) = TYPE_OP any [type = TYPE_FUNCTION type = TYPE_ROUTINE]][
					s: as series! native/more/value
					stack/set-last s/offset
				][
					table: either TYPE_OF(native) = TYPE_NATIVE [natives/table][actions/table]
					index: 0
					until [index: index + 1 native/code = table/index]
					return as red-block! integer/box index
				]
			]
			field = words/words [
				--NOT_IMPLEMENTED--						;@@ build the words block from spec
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		blk												;@@ TBD: remove it when all cases implemented
	]
	
	form: func [
		value	[red-native!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/form"]]

		string/concatenate-literal buffer "?native?"
		part - 8
	]
	
	mold: func [
		native	[red-native!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/mold"]]

		string/concatenate-literal buffer "make native! ["
		
		part: block/mold
			reflect native words/spec					;-- mold spec
			buffer
			only?
			all?
			flat?
			arg
			part - 14
			indent
		
		string/concatenate-literal buffer "]"
		part - 1
	]

	compare: func [
		arg1	[red-native!]							;-- first operand
		arg2	[red-native!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_NATIVE [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_FIND
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				res: SIGN_COMPARE_RESULT(arg1/code arg2/code)
			]
			default [
				res: -2
			]
		]
		res
	]

	init: does [
		datatype/register [
			TYPE_NATIVE
			TYPE_VALUE
			"native!"
			;-- General actions --
			:make
			null			;random
			:reflect
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