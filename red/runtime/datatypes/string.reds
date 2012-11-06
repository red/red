Red/System [
	Title:   "String! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %string.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
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
	
	rs-make-at: func [
		slot	[cell!]
		size 	[integer!]								;-- number of cells to pre-allocate
		return:	[red-string!]
		/local 
			p	[node!]
			str	[red-string!]
	][
		p: alloc-series size 1 0
		set-type slot TYPE_STRING						;@@ decide to use or not 'set-type...
		str: as red-string! slot
		str/head: 0
		str/node: p
		str
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
	
	concatenate: func [									;-- append str2 to str1
		str1	  [red-string!]
		str2	  [red-string!]
		keep?	  [logic!]								;-- do not change str2 encoding
		/local
			s1	  [series!]
			s2	  [series!]
			unit1 [integer!]
			unit2 [integer!]
			size  [integer!]
			size2 [integer!]
			p	  [byte-ptr!]
			cp	  [integer!]
	][
		s1: GET_BUFFER(str1)
		s2: GET_BUFFER(str2)
		unit1: GET_UNIT(s1)
		unit2: GET_UNIT(s2)
		
		case [											;-- harmonize both encodings
			unit1 < unit2 [
				switch unit2 [
					UCS-2 [s1: unicode/Latin1-to-UCS2 s1]
					UCS-4 [
						s1: either unit1 = Latin1 [
							unicode/Latin1-to-UCS4 s1
						][
							unicode/UCS2-to-UCS4 s1
						]
					]
				]
				unit1: unit2
			]
			all [unit1 > unit2 not keep?][
				switch unit1 [
					UCS-2 [s2: unicode/Latin1-to-UCS2 s2]
					UCS-4 [
						s2: either unit2 = Latin1 [
							unicode/Latin1-to-UCS4 s2
						][
							unicode/UCS2-to-UCS4 s2
						]
					]
				]		
			]
			true [true]									;@@ catch-all case to make compiler happy
		]
		
		size2: as-integer (as byte-ptr! s2/tail - s2/offset) - str2/head
		size: (as-integer (as byte-ptr! s1/tail - s1/offset )- str1/head) + size2
		if s1/size < size [s1: expand-series s1 size + unit1]	;-- account for terminal NUL
		if negative? str2/head [size2: size2 - 1]		;-- mismatch correction when symbol! is used as string!
		
		either all [keep? unit1 <> unit2][
			p: as byte-ptr! s1/offset
			while [not p/1 <> null-byte][
				either unit2 = UCS-2 [
					cp: (as-integer p/2) << 8 + p/1
					p: p + 2
				][
					cp: as-integer p/1
					p: p + 1
				]
				s1: append-char s1 cp
			]
		][
			p: as byte-ptr! s1/tail
			copy-memory	p as byte-ptr! s2/offset size2 + unit1	;-- copy NUL too
			s1/tail: as cell! p + size2				;-- reset tail just before NUL
		]
	]
	
	concatenate-literal: func [
		str		  [red-string!]
		p		  [c-string!]							;-- Red/System literal string
		/local
			s	  [series!]
	][
		s: GET_BUFFER(str)
		assert p/1 <> null-byte							;-- assume no empty string passed
		
		until [
			s: append-char s as-integer p/1
			p: p + 1
			p/1 = null-byte
		]
	]

	load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		return:  [red-string!]
		/local
			str  [red-string!]
			size [integer!]
	][
		size: 1 + system/words/length? src
		str: as red-string! ALLOC_TAIL(root)
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 0
		str/node: unicode/load-utf8 src size			;@@ try to avoid length? call
		str/cache: either size < 64 [src][null]			;-- cache only small strings (experimental)
		str
	]
	
	push: func [
		str [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/push"]]

		copy-cell as red-value! str stack/push
	]
	
	;-- Actions -- 
	
	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		type	 [integer!]
		return:	 [red-string!]
		/local
			str	 [red-string!]
			size [integer!]
			int	 [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/make"]]
		
		size: 1
		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				size: int/value
			]
			default [--NOT_IMPLEMENTED--]
		]
		str: as red-string! stack/push
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 	0
		str/node: 	alloc-bytes size					;-- alloc enough space for at least a Latin1 string
		str
	]
	
	form: func [
		str		[red-string!]
		buffer	[red-string!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/form"]]

		concatenate buffer str no
		part											;@@ implement full support for /part
	]
	
	mold: func [
		str		[red-string!]
		buffer	[red-string!]
		part 	[integer!]
		flags   [integer!]								;-- 0: /only, 1: /all, 2: /flat
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/mold"]]

		append-char GET_BUFFER(buffer) as-integer #"^""
		concatenate buffer str no
		append-char GET_BUFFER(buffer) as-integer #"^""
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

	index?: func [
		return:	  [red-value!]
		/local
			str	  [red-string!]
			index [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/index?"]]

		str:   as red-string! stack/arguments
		index: as red-integer! str

		index/header: TYPE_INTEGER
		index/value:  str/head + 1
		as red-value! index
	]

	length?: func [
		return: [red-value!]
		/local
			str	[red-string!]
			int [red-integer!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/length?"]]

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
		str	       [red-string!]
		index  	   [integer!]
		return:	   [red-value!]
		/local
			char   [red-char!]
			s	   [series!]
			offset [integer!]
			p1	   [byte-ptr!]
			p4	   [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/pick"]]

		s: GET_BUFFER(str)
		
		offset: str/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]

		p1: (as byte-ptr! s/offset) + (offset << (GET_UNIT(s) >> 1))
		
		either any [
			zero? index
			p1 >= as byte-ptr! s/tail
			p1 <  as byte-ptr! s/offset
		][
			none-value
		][
			char: as red-char! stack/push
			char/header: TYPE_CHAR		
			char/value: switch GET_UNIT(s) [
				Latin1 [as-integer p1/value]
				UCS-2  [(as-integer p1/2) << 8 + p1/1]
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
				switch TYPE_OF(cell) [
					TYPE_CHAR [
						char: as red-char! cell				
						dst: append-char dst char/value
					]
					TYPE_STRING [
						concatenate str as red-string! cell no
					]
					default [
						--NOT_IMPLEMENTED--				;@@ actions/form needs to take an argument!
						;TBD once INSERT is implemented
					]
				]
				cell: cell + 1
			]
		][												;-- single value case
			switch TYPE_OF(value) [
				TYPE_CHAR [
					char: as red-char! value
					dst: append-char dst char/value
				]
				TYPE_STRING [
					concatenate str as red-string! value no
				]
				default [
					;actions/form* no					;-- FORM value before appending
					--NOT_IMPLEMENTED--
					;TBD once INSERT is implemented
				]
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
		TYPE_VALUE
		"string"
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
		:append
		:at
		:back
		null			;change
		:clear
		null			;copy
		null			;find
		:head
		:head?
		:index?
		null			;insert
		:length?
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