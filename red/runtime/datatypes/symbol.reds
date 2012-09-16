Red/System [
	Title:   "Symbol! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %symbol.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

symbol: context [
	verbose: 0
	
	make: func [
		s 		[c-string!]								;-- input c-string!
		return:	[red-symbol!]
		/local 
			sym	[red-symbol!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/make"]]
		
		sym: as red-symbol! ALLOC_TAIL(symbols)	
		sym/header: TYPE_SYMBOL							;-- implicit reset of all header flags
		sym/buffer: s									;-- permanent string buffer in data segment
		sym
	]
	
	push: func [

	][

	]
	
	;-- Actions -- 
	
	datatype/register [
		TYPE_SYMBOL
		;-- General actions --
		null			;make
		null			;random
		null			;reflect
		null			;to
		null			;form
		null			;mold
		null			;get-path
		null			;set-path		
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