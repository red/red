Red/System [
	Title:   "Native! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %native.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

native: context [
	verbose: 0
	
	push: func [
		/local
			cell  [red-native!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/push"]]
		
		cell: as red-native! stack/push*
		cell/header: TYPE_NATIVE
		;...TBD
	]
	
	;-- Actions -- 
	
	make: func [
		proto	   [red-value!]
		spec	   [red-block!]
		return:    [red-native!]						;-- return native cell pointer
		/local
			native [red-native!]
			s	   [series!]
			index  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/make"]]
		
		assert TYPE_OF(spec) = TYPE_BLOCK
		s: GET_BUFFER(spec)
		spec: as red-block! s/offset

		native: as red-native! stack/push*
		native/header:  TYPE_NATIVE						;-- implicit reset of all header flags
		native/spec:    spec/node						; @@ copy spec block if not at head
		;native/symbols: clean-spec spec 				; @@ TBD
		
		index: integer/get s/offset + 1
		native/code: natives/table/index
		native
	]
	
	reflect: func [
		native	[red-native!]
		field	[integer!]
		return:	[red-block!]
		/local
			blk [red-block!]
	][
		case [
			field = words/spec [
				blk: as red-block! stack/arguments
				blk/header: TYPE_BLOCK					;-- implicit reset of all header flags
				blk/node:	native/spec
				blk/head:	0
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
		
		string/concatenate-literal buffer "]"
		part - 1
	]

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