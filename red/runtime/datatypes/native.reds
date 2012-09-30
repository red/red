Red/System [
	Title:   "Native! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %native.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

native: context [
	verbose: 0
	
	push: func [
		/local
			cell  [red-native!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/push"]]
		
		cell: as red-native! stack/push
		cell/header: TYPE_NATIVE
		;...TBD
	]
	
	;-- Actions -- 
	
	make: func [
		return:    [red-value!]						;-- return native cell pointer
		/local
			arg	   [red-value!]
			native [red-native!]
			spec   [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/make"]]

		arg:    stack/arguments
		native: as red-native! arg
		spec:   as red-block!  arg + 1
		
		assert TYPE_OF(spec) = TYPE_BLOCK
		
		native/header:  TYPE_NATIVE					;-- implicit reset of all header flags
		native/spec:    spec/node					; @@ copy spec block if not at head
		;native/symbols: clean-spec spec 			; @@ TBD
		
		as red-value! native
	]

	datatype/register [
		TYPE_NATIVE
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		null			;form
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