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
	
	get-position: func [
		base	   [integer!]
		return:	   [integer!]
		/local
			str	   [red-string!]
			index  [red-integer!]
			s	   [series!]
			offset [integer!]
			max	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/get-position"]]

		str: as red-string! stack/arguments
		index: as red-integer! str + 1

		assert TYPE_OF(str)   = TYPE_STRING
		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(str)

		offset: str/head + index/value - base			;-- index is one-based
		if negative? offset [offset: 0]
		max: (as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1)
		if offset > max [offset: max]

		offset
	]
	
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
		p: alloc-series size 1 0						;-- align string data to head of buffer 
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
		slot	[cell!]
		size 	[integer!]								;-- number of cells to pre-allocate
		return:	[node!]
		/local 
			p	[node!]
			str	[red-string!]
	][
		p: alloc-series size 1 0
		set-type slot TYPE_STRING						;@@ decide to use or not 'set-type...
		str: as red-string! slot
		str/head: 0
		str/node: p
		p
	]
	
	append-char: func [
		s		[series!]
		cp		[integer!]								;-- codepoint
		/local
			p1	[byte-ptr!]
			p4	[int-ptr!]
	][
		switch GET_UNIT(s) [
			Latin1 [
				case [
					cp <= FFh [
						p1: as byte-ptr! s/tail
						p1/value: as-byte cp			;-- overwrite termination NUL character
						s/tail: as cell! (as byte-ptr! s/tail) + 1	;-- safe to increment here
						
						p1: alloc-tail-unit s 1
						p1/value: as-byte 0				;-- add it back
					]
					cp <= FFFFh [
						s: unicode/latin1-to-UCS2 s
						append-char s cp
					]
					true [
						s: unicode/UCS2-to-UCS4 s
						append-char s cp
					]
				]
			]
			UCS-2 [
				either cp <= FFFFh [
					p1: as byte-ptr! s/tail
					p1/1: as-byte (cp and FFh)			;-- overwrite termination NUL character
					p1/2: as-byte (cp >> 8)
					s/tail: as cell! (as byte-ptr! s/tail) + 2	;-- safe to increment here
					
					p1: alloc-tail-unit s 2
					p1/1: as-byte 0						;-- add it back
					p1/2: as-byte 0
				][
					s: unicode/UCS2-to-UCS4 s
					append-char s cp
				]
			]
			UCS-4 [
				p4: as int-ptr! s/tail
				p4/value: cp							;-- overwrite termination NUL character
				s/tail: as cell! (as int-ptr! s/tail) + 1	;-- safe to increment here
				
				p4: as int-ptr! alloc-tail-unit s 4
				p4/value: 0								;-- add it back
			]
		]
	]
	
	push: func [
		src		[c-string!]								;-- UTF-8 source string buffer
		return: [red-value!]
		/local
			str  [red-string!]
			size [integer!]
	][
		size: 1 + length? src
		str: as red-string! stack/push
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 0
		str/node: unicode/load-utf8 src size			;@@ try to avoid length? call
		str/cache: either size < 64 [src][null]			;-- cache only small strings (experimental)
		as red-value! str
	]
	
	;-- Actions -- 
	
	make: func [
	
	][
	
	]
	
	form: func [
		part 		[integer!]
		return: 	[integer!]
		/local
			arg		[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/form"]]

		arg: stack/arguments
		copy-cell 
			arg
			arg + 1										;@@ free allocated series in actions/form!!
		part											;@@ implement full support for /part
	]
	
	;--- Property reading actions ---

	head?: func [
		return:	  [red-value!]
		/local
			str	  [red-string!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/head?"]]

		str:   as red-string! stack/arguments
		state: as red-logic! str

		state/header: TYPE_LOGIC
		state/value:  zero? str/head
		as red-value! state
	]

	tail?: func [
		return:	  [red-value!]
		/local
			str	  [red-string!]
			state [red-logic!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/tail?"]]

		str:   as red-string! stack/arguments
		state: as red-logic! str

		s: GET_BUFFER(str)

		state/header: TYPE_LOGIC
		state/value:  (as byte-ptr! s/offset) + (str/head << (GET_UNIT(s) >> 1)) = as byte-ptr! s/tail
		as red-value! state
	]

	index-of: func [
		return:	  [red-value!]
		/local
			str	  [red-string!]
			index [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/index-of"]]

		str:   as red-string! stack/arguments
		index: as red-integer! str

		index/header: TYPE_INTEGER
		index/value:  str/head + 1
		as red-value! index
	]

	length-of: func [
		return: [red-value!]
		/local
			str	[red-string!]
			int [red-integer!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/length-of"]]

		str: as red-string! stack/arguments

		s: GET_BUFFER(str)

		int: as red-integer! str
		int/header: TYPE_INTEGER
		int/value:  (as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1) - str/head
		as red-value! int
	]
	
	;--- Navigation actions ---

	at: func [
		return:	[red-value!]
		/local
			str	[red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/at"]]

		str: as red-string! stack/arguments
		str/head: get-position 1
		as red-value! str
	]

	back: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/back"]]

		block/back										;-- identical behaviour as block!
	]

	next: func [
		return:	  [red-value!]
		/local
			str	  [red-string!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/next"]]

		str: as red-string! stack/arguments

		s: GET_BUFFER(str)

		if (as byte-ptr! s/offset) + (str/head + 1 << (GET_UNIT(s) >> 1)) <= as byte-ptr! s/tail [
			str/head: str/head + 1
		]
		as red-value! str
	]

	skip: func [
		return:	[red-value!]
		/local
			str	[red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/skip"]]

		str: as red-string! stack/arguments
		str/head: get-position 0
		as red-value! str
	]

	head: func [
		return:	[red-value!]
		/local
			str	[red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/head"]]

		str: as red-string! stack/arguments
		str/head: 0
		as red-value! str
	]

	tail: func [
		return:	[red-value!]
		/local
			str	[red-string!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/tail"]]

		str: as red-string! stack/arguments
		s: GET_BUFFER(str)

		str/head: (as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1)
		as red-value! str
	]
	
	;--- Reading actions ---

	pick: func [
		return:	   [red-value!]
		/local
			str	   [red-string!]
			index  [red-integer!]
			char   [red-char!]
			s	   [series!]
			offset [integer!]
			p1	   [byte-ptr!]
			p4	   [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/pick"]]

		str: as red-string! stack/arguments
		index: as red-integer! str + 1
		s: GET_BUFFER(str)

		offset: str/head + index/value - 1				;-- index is one-based
		p1: (as byte-ptr! s/offset) + (offset << (GET_UNIT(s) >> 1))
		
		either any [
			negative? offset
			p1 >= as byte-ptr! s/tail
		][
			stack/push-last none-value
		][
			char: as red-char! str
			char/header: TYPE_CHAR		
			char/value: switch GET_UNIT(s) [
				Latin1 [as-integer p1/value]
				UCS-2  [(as-integer p1/1) << 8 + p1/2]
				UCS-4  [p4: as int-ptr! p1 p4/value]
			]			
			as red-value! char
		]
	]

	
	datatype/register [
		TYPE_STRING
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		:form
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
		:at
		:back
		null			;change
		null			;clear
		null			;copy
		null			;find
		:head
		:head?
		:index-of
		null			;insert
		:length-of
		:next
		:pick
		null			;poke
		null			;remove
		null			;reverse
		null			;select
		null			;sort
		:skip
		null			;swap
		:tail
		:tail?
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