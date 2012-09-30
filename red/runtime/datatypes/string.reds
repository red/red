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
		return: [series!]
		/local
			p	[byte-ptr!]
			p4	[int-ptr!]
	][
		switch GET_UNIT(s) [
			Latin1 [
				case [
					cp <= FFh [
						s/tail: as cell! (as byte-ptr! s/tail) + 1	;-- safe to increment here
						p: alloc-tail-unit s 1
						p/0: as-byte cp					;-- overwrite termination NUL character
						p/1: as-byte 0					;-- add it back at next position
						s: GET_BUFFER(s)				;-- refresh s pointer if relocated by alloc-tail-unit
						s/tail: as cell! p				;-- reset tail just before NUL					
					]
					cp <= FFFFh [
						s: unicode/Latin1-to-UCS2 s
						s: append-char s cp
					]
					true [
						s: unicode/Latin1-to-UCS4 s
						s: append-char s cp
					]
				]
			]
			UCS-2 [
				either cp <= FFFFh [
					s/tail: as cell! (as byte-ptr! s/tail) + 2	;-- safe to increment here
					p: alloc-tail-unit s 2
					
					p/-1: as-byte (cp and FFh)			;-- overwrite termination NUL character
					p/0: as-byte (cp >> 8)
					p/1: as-byte 0						;-- add it back
					p/2: as-byte 0
					
					s: GET_BUFFER(s)					;-- refresh s pointer if relocated by alloc-tail-unit
					s/tail: as cell! p 					;-- reset tail just before NUL
				][
					s: unicode/UCS2-to-UCS4 s
					s: append-char s cp
				]
			]
			UCS-4 [
				s/tail: as cell! (as int-ptr! s/tail) + 1	;-- safe to increment here
				p4: as int-ptr! alloc-tail-unit s 4
				p4/0: cp								;-- overwrite termination NUL character
				p4/1: 0									;-- add it back
				s: GET_BUFFER(s)						;-- refresh s pointer if relocated by alloc-tail-unit
				s/tail: as cell! p						;-- reset tail just before NUL
			]
		]
		s
	]
	
	poke-char: func [
		s		[series!]
		p		[byte-ptr!]								;-- target passed as pointer to favor the general code path
		cp		[integer!]								;-- codepoint
		return: [series!]
		/local
			p4	[int-ptr!]
	][
		switch GET_UNIT(s) [
			Latin1 [
				case [
					cp <= FFh [
						p/1: as-byte cp
					]
					cp <= FFFFh [
						p: (as byte-ptr! s - 1) - p		;-- calc index value
						s: unicode/Latin1-to-UCS2 s
						p: (as byte-ptr! s + 1) + ((as-integer p) << 1) ;-- calc the new position
						s: poke-char s p cp
					]
					true [
						p: (as byte-ptr! s - 1) - p		;-- calc index value
						s: unicode/Latin1-to-UCS4 s
						p: (as byte-ptr! s + 1) + ((as-integer p) << 2) ;-- calc the new position
						s: poke-char s p cp
					]
				]
			]
			UCS-2 [
				either cp <= FFFFh [
					p/1: as-byte (cp and FFh)
					p/2: as-byte (cp >> 8)
				][
					p: (as byte-ptr! s - 1) - p			;-- calc index value
					s: unicode/UCS2-to-UCS4 s
					p: (as byte-ptr! s + 1) + ((as-integer p) << 2) ;-- calc the new position
					s: poke-char s p cp
				]
			]
			UCS-4 [
				p4: as int-ptr! p
				p4/1: cp
			]
		]
		s
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
			idx	   [integer!]
			offset [integer!]
			p1	   [byte-ptr!]
			p4	   [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/pick"]]

		str: as red-string! stack/arguments
		s: GET_BUFFER(str)
		
		index: as red-integer! str + 1
		idx: index/value
		
		offset: str/head + idx - 1						;-- index is one-based
		if negative? idx [offset: offset + 1]

		p1: (as byte-ptr! s/offset) + (offset << (GET_UNIT(s) >> 1))
		
		either any [
			zero? idx
			p1 >= as byte-ptr! s/tail
			p1 <  as byte-ptr! s/offset
		][
			stack/set-last none-value
		][
			if negative? offset [offset: offset + 1]
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
	
	;--- Modifying actions ---
		
	append: func [
		return:	  [red-value!]
		/local
			str	  [red-string!]
			value [red-value!]
			char  [red-char!]
			src	  [red-block!]
			s	  [series!]
			dst	  [series!]
			cell  [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/append"]]

		;@@ implement /part and /only support
		str: as red-string! stack/arguments
		value: as red-value! str + 1
		dst: GET_BUFFER(str)

		either TYPE_OF(value) = TYPE_BLOCK [			;@@ replace it with: typeset/any-block?
			src: as red-block! value
			s: GET_BUFFER(src)
			cell: s/offset + src/head

			while [cell < s/tail][						;-- multiple values case
				either TYPE_OF(cell) = TYPE_CHAR [
					char: as red-char! cell				
					dst: append-char dst char/value
				][
					--NOT_IMPLEMENTED--						;@@ actions/form needs to take an argument!
					;TBD once INSERT is implemented
				]
				cell: cell + 1
			]
		][												;-- single value case
			either TYPE_OF(value) = TYPE_CHAR [
				char: as red-char! value
				dst: append-char dst char/value
			][
				actions/form no							;-- FORM value before appending
				--NOT_IMPLEMENTED--
				;TBD once INSERT is implemented
			]
		]		
		as red-value! str
	]

	clear: func [
		return:	[red-value!]
		/local
			str	[red-string!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/clear"]]

		str: as red-string! stack/arguments
		s: GET_BUFFER(str)
		s/tail: as cell! (as byte-ptr! s/offset) + (str/head << (GET_UNIT(s) >> 1))	
		as red-value! str
	]

	poke: func [
		return:	   [red-value!]
		/local
			str	   [red-string!]
			index  [red-integer!]
			char   [red-char!]
			s	   [series!]
			idx	   [integer!]
			offset [integer!]
			pos	   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/poke"]]

		str: as red-string! stack/arguments
		s: GET_BUFFER(str)
		
		index: as red-integer! str + 1
		idx: index/value
		
		offset: str/head + idx - 1						;-- index is one-based
		if negative? idx [offset: offset + 1]
		
		pos: (as byte-ptr! s/offset) + (offset << (GET_UNIT(s) >> 1))
		
		either any [
			zero? idx
			pos >= as byte-ptr! s/tail
			pos <  as byte-ptr! s/offset
		][
			--NOT_IMPLEMENTED--
			;TBD: waiting for error!
		][
			char: as red-char! str + 2
			if TYPE_OF(char) <> TYPE_CHAR [
				print-line "Error: POKE expected char! value"	;@@ replace by error! when ready
				halt
			]
			poke-char s pos char/value
		]
		as red-value! str
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
		:append
		:at
		:back
		null			;change
		:clear
		null			;copy
		null			;find
		:head
		:head?
		:index-of
		null			;insert
		:length-of
		:next
		:pick
		:poke
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