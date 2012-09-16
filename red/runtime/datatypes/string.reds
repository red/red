Red/System [
	Title:   "String! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %string.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

string: context [
	verbose: 0
	
	make-from: func [
		parent	[red-block!]
		s 		[c-string!]								;-- input string buffer
		return:	[node!]
		/local 
			size [integer!]
			series [series!]
			p	 [node!]
			str	 [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/make-from"]]
		
		size: system/words/length? s
		p: alloc-series size 0 flag-ins-tail			;-- align string data to head of buffer 
		series: as series! p/value 
		copy-memory 
			as byte-ptr! series/offset
			as byte-ptr! s
			size
		series/tail: as cell! (as byte-ptr! series/tail) + size
		
		assert (as byte-ptr! series/tail) < ((as byte-ptr! series) + series/size)

		str: as red-string! ALLOC_TAIL(parent)
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 0
		str/node: p
		
		p
	]
	
	rs-make-at: func [
		slot	[red-string!]
		size 	[integer!]								;-- number of cells to pre-allocate
		return:	[node!]
		/local 
			p	[node!]
			str	[red-string!]
	][
		p: alloc-series size 0 default-offset
		set-type as cell! slot TYPE_STRING
		slot/head: 0
		slot/node: p
		p
	]
	
	push: func [

	][
	
	]
	
	;-- Actions -- 
	
	make: func [
	
	][
	
	]

	
	datatype/register [
		TYPE_STRING
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		null			;form
		null			;mold
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