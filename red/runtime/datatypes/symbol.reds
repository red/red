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
	
	same?: func [										;-- case-insensitive string comparison
		str1	     [c-string!]
		str2	     [c-string!]
		return:      [integer!]
		/local
			aliased? [logic!]
			c1	     [byte!]
			c2	     [byte!]
	][		
		aliased?: no
		c1:   str1/1
		c2:   str2/1

		while [c1 <> null-byte][
			if c1 <> c2 [
				if all [#"A" <= c1 c1 <= #"Z"][c1: c1 + 32]	;-- lowercase c1
				if all [#"A" <= c2 c2 <= #"Z"][c2: c2 + 32] ;-- lowercase c2
				if c1 <> c2 [return 0]				;-- not same case-insensitive character
				aliased?: yes
			]
			str1: str1 + 1
			str2: str2 + 1
			c1: str1/1
			c2: str2/1
		]
		case [
			c2 <> null-byte [0]							;-- not matching
			aliased? [-1]								;-- similar (case-insensitive matching)
			true [1]									;-- same (case-sensitive matching)
		]
	]
	
	search: func [										;@@ use a faster lookup method later
		str 	  [c-string!]							;-- UTF-8 string
		return:	  [integer!]
		/local
			s	  [series!]
			entry [red-symbol!]
			end   [red-symbol!]
			id	  [integer!]
	][
		s: GET_BUFFER(symbols)
		entry: as red-symbol! s/offset
		end:   as red-symbol! s/tail
		i: 1
		
		while [entry < end][
			id: same? entry/cache str
			if id <> 0 [return id]						;-- matching symbol found
			i: i + 1
			entry: entry + 1
		]
		0												;-- no matching symbol
	]
	
	make: func [
		s 		[c-string!]								;-- input c-string!
		return:	[integer!]
		/local 
			sym	[red-symbol!]
			id	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "symbol/make"]]
		
		id: search s
		if positive? id [return id]
		
		sym: as red-symbol! ALLOC_TAIL(symbols)	
		sym/header: TYPE_SYMBOL							;-- implicit reset of all header flags
		sym/alias:  either zero? id [-1][0 - id]		;-- -1: no alias, abs(id)>0: alias id
		sym/node:   unicode/load-utf8 s 1 + length? s
		sym/cache:  s
		either zero? id [block/rs-length? symbols][0 - id]
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