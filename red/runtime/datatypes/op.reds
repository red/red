Red/System [
	Title:   "Op! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %op.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

op: context [
	verbose: 0
	
	push: func [
		/local
			cell [red-op!]
	][
		#if debug? = yes [if verbose > 0 [print-line "op/push"]]
		
		cell: as red-op! stack/push
		cell/header: TYPE_OP
		;...TBD
	]
	
	;-- Actions -- 
	
	make: func [
		proto	[red-value!]
		spec	[red-block!]
		return: [red-op!]
		/local
			op	[red-op!]
	][
		#if debug? = yes [if verbose > 0 [print-line "op/make"]]

		;assert TYPE_OF(spec) = TYPE_BLOCK
		
		op: as red-op! stack/push
		op/header: TYPE_OP						;-- implicit reset of all header flags
		;op/spec:    spec/node					; @@ copy spec block if not at head
		;op/symbols: clean-spec spec 			; @@ TBD
		op
	]
	
	form: func [
		value	[red-native!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "op/form"]]

		string/concatenate-literal buffer "?op?"
		part - 4
	]
	
	mold: func [
		value	[red-native!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "op/mold"]]

		string/concatenate-literal buffer "op"
		part - 2
	]

	datatype/register [
		TYPE_OP
		TYPE_VALUE
		"op"
		;-- General actions --
		:make
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