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
	
	#define BRACES_THRESHOLD	50						;-- max string length for using " delimiter
	#define MAX_ESC_CHARS		60h	
	
	escape-chars: declare byte-ptr!

	fill-table: func [
		/local
			c [byte!]
			i [integer!]
	][
		i: 1
		c:  #"@"
		while [c <= #"_"][
			escape-chars/i: c
			i: i + 1
			c: c + 1
		]
		
		while [i < MAX_ESC_CHARS][
			escape-chars/i: null-byte
			i: i + 1
		]
		
		escape-chars/10: #"-"							;-- 9  + 1 (adjust for 1-base)
		escape-chars/11: #"/"							;-- 10 + 1 (adjust for 1-base)
		escape-chars/35: #"^""							;-- 34 + 1 (adjust for 1-base)
	]
	
	to-hex: func [
		cp		[integer!]								;-- codepoint <= 10FFFFh
		return: [c-string!]
		/local
			s [c-string!]
			h [c-string!]
			c [integer!]
			i [integer!]
	][
		assert cp <= 0010FFFFh
		
		s: "000000"
		h: "0123456789ABCDEF"
		
		if zero? cp [
			s/5: #"0"
			s/6: #"0"
			return s + 5
		]
		
		c: 6
		while [cp <> 0][
			i: cp and 15 + 1								;-- cp // 16 + 1
			s/c: h/i
			cp: cp >> 4
			c: c - 1
		]
		s + c
	]
	
	rs-length?: func [
		str	    [red-string!]
		return: [integer!]
	][
		get-length str
	]

	rs-head: func [
		str	    [red-string!]
		return: [byte-ptr!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(str)
		(as byte-ptr! s/offset) + (str/head << (GET_UNIT(s) >> 1))
	]

	rs-tail: func [
		str	    [red-string!]
		return: [byte-ptr!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(str)
		as byte-ptr! s/tail
	]
	
	get-char: func [
		p	    [byte-ptr!]
		unit	[integer!]
		return: [integer!]
		/local
			p4	[int-ptr!]
	][
		switch unit [
			Latin1 [as-integer p/value]
			UCS-2  [(as-integer p/2) << 8 + p/1]
			UCS-4  [p4: as int-ptr! p p4/value]
		]
	]
	
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

		assert any [
			TYPE_OF(str) = TYPE_STRING					;@@ ANY_STRING?
			TYPE_OF(str) = TYPE_FILE
		]
		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(str)

		if all [base = 1 index/value <= 0][base: base - 1]
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
	
	get-length: func [
		str		   [red-string!]
		return:	   [integer!]
		/local
			s	   [series!]
			offset [integer!]
	][
		s: GET_BUFFER(str)
		offset: str/head
		if negative? offset [offset: 0]					;-- @@ beware of symbol/index leaking here...
		(as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1) - offset
	]
	
	add-terminal-NUL: func [
		p	   [byte-ptr!]
		unit   [integer!]
		/local
			p4 [int-ptr!]
	][
		switch unit [
			Latin1 [p/1: as-byte 0]
			UCS-2  [p/1: as-byte 0 p/2: as-byte 0]
			UCS-4  [p4: as int-ptr! p p4/1: 0]
		]
	]
	
	truncate-from-tail: func [
		s	    [series!]
		offset  [integer!]								;-- negative offset from tail
		return: [series!]
	][
		if zero? offset [return s]
		assert negative? offset
		
		s/tail: as cell! (as byte-ptr! s/tail) + (offset * GET_UNIT(s))
		add-terminal-NUL as byte-ptr! s/tail GET_UNIT(s)
		s
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
				s/tail: as cell! p4						;-- reset tail just before NUL
			]
		]
		s
	]
	
	insert-char: func [
		s		[series!]
		offset	[integer!]								;-- offset from head in codepoints
		cp		[integer!]								;-- codepoint
		return: [series!]
		/local
			p	 [byte-ptr!]
			unit [integer!]
	][
		switch GET_UNIT(s) [
			Latin1 [
				case [
					cp <= FFh 	[0]
					cp <= FFFFh [s: unicode/Latin1-to-UCS2 s]
					true 		[s: unicode/Latin1-to-UCS4 s]
				]
			]
			UCS-2 [if cp > FFFFh [s: unicode/UCS2-to-UCS4 s]]
			UCS-4 [0]
		]
		unit: GET_UNIT(s)
		if ((as byte-ptr! s/tail) + unit) > ((as byte-ptr! s + 1) + s/size) [
			s: expand-series s 0
		]
		p: (as byte-ptr! s/offset) + (offset << (unit >> 1))
	
		move-memory										;-- make space
			p + unit
			p
			as-integer (as byte-ptr! s/tail) - p

		s/tail: as cell! (as byte-ptr! s/tail) + unit
		add-terminal-NUL as byte-ptr! s/tail unit
		
		poke-char s p cp
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
		str1	  [red-string!]							;-- string! to extend
		str2	  [red-string!]							;-- string! to append to str1
		part	  [integer!]							;-- str2 characters to append, -1 means all
		keep?	  [logic!]								;-- do not change str2 encoding
		insert?	  [logic!]								;-- insert str2 at str1 index instead of appending
		/local
			s1	  [series!]
			s2	  [series!]
			unit1 [integer!]
			unit2 [integer!]
			size  [integer!]
			size2 [integer!]
			p	  [byte-ptr!]
			limit [byte-ptr!]
			cp	  [integer!]
			h1	  [integer!]
			h2	  [integer!]
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
		
		h1: either TYPE_OF(str1) = TYPE_SYMBOL [0][str1/head << (unit1 >> 1)]	;-- make symbol! used as string! pass safely
		h2: either TYPE_OF(str2) = TYPE_SYMBOL [0][str2/head << (unit2 >> 1)]	;-- make symbol! used as string! pass safely
		
		size2: (as-integer s2/tail - s2/offset) - h2
		size:  (as-integer s1/tail - s1/offset) - h1 + size2
		if s1/size < size [s1: expand-series s1 size + unit1]	;-- account for terminal NUL
		
		if part >= 0 [
			part: part << (unit2 >> 1)
			if part < size2 [size2: part]				;-- optionally limit str2 characters to copy
		]
		if insert? [
			move-memory									;-- make space
				(as byte-ptr! s1/offset) + h1 + size2
				(as byte-ptr! s1/offset) + h1
				(as-integer s1/tail - s1/offset) - h1
		]
		
		either all [keep? unit1 <> unit2][
			p: (as byte-ptr! s1/offset) + h1
			limit: p + size2
			while [p < limit][
				either unit2 = UCS-2 [
					cp: (as-integer p/2) << 8 + p/1
					p: p + 2
				][
					cp: as-integer p/1
					p: p + 1
				]
				s1: either insert? [
					poke-char s1 p cp
				][
					append-char s1 cp
				]
			]
		][
			p: either insert? [
				(as byte-ptr! s1/offset) + h1
			][
				as byte-ptr! s1/tail
			]
			copy-memory	p (as byte-ptr! s2/offset) + h2 size2
			p: p + size2
		]
		if insert? [p: (as byte-ptr! s1/tail) + size2] 
		
		add-terminal-NUL p unit1
		s1/tail: as cell! p							;-- reset tail just before NUL
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
	
	concatenate-literal-part: func [
		str	   [red-string!]
		p	   [c-string!]								;-- Red/System literal string
		part   [integer!]								;-- number of bytes to append
		/local
			s	  [series!]
	][
		s: GET_BUFFER(str)
		assert p/1 <> null-byte							;-- assume no empty string passed
		assert positive? part

		until [
			s: append-char s as-integer p/1
			p: p + 1
			part: part - 1
			zero? part
		]
	]

	load-in: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		blk		 [red-block!]
		return:  [red-string!]
		/local
			str  [red-string!]
	][
		str: as red-string! ALLOC_TAIL(blk)
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 0
		str/node: unicode/load-utf8 src size
		str/cache: either size < 64 [src][null]			;-- cache only small strings (experimental)
		str
	]
	
	load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		return:  [red-string!]
	][
		load-in src size root
	]
	
	push: func [
		str [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/push"]]

		copy-cell as red-value! str stack/push*
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
		str: as red-string! stack/push*
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 	0
		str/node: 	alloc-bytes size					;-- alloc enough space for at least a Latin1 string
		str
	]
	
	form: func [
		str		  [red-string!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part	  [integer!]
		return:	  [integer!]
		/local
			int	  [red-integer!]
			limit [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/form"]]

		limit: either OPTION?(arg) [
			int: as red-integer! arg
			int/value	
		][-1]
		concatenate buffer str limit no no
		part - get-length str
	]
	
	sniff-chars: func [
		p	  [byte-ptr!]
		tail  [byte-ptr!]
		unit  [integer!]
		curly [int-ptr!]
		quote [int-ptr!]
		nl	  [int-ptr!]
		/local
			cp [integer!]
			p4 [int-ptr!]
	][
		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			switch cp [
				#"{"    [if curly/value >= 0 [curly/value: curly/value + 1]]
				#"}"    [curly/value: curly/value - 1]
				#"^""   [quote/value: quote/value + 1]
				#"^/"   [nl/value: 	  nl/value + 1]
				default [0]
			]
			p: p + unit
		]
	]
	
	append-escaped-char: func [
		buffer	[red-string!]
		cp	    [integer!]
		/local
			idx [integer!]
	][
		idx: cp + 1
		case [
			cp = 5Eh [
				append-char GET_BUFFER(buffer) as-integer #"^^"
				append-char GET_BUFFER(buffer) as-integer #"^^"
			]
			cp > 7Fh [
				append-char GET_BUFFER(buffer) as-integer #"^^"
				append-char GET_BUFFER(buffer) as-integer #"("
				concatenate-literal buffer to-hex cp
				append-char GET_BUFFER(buffer) as-integer #")"
			]
			all [cp < MAX_ESC_CHARS escape-chars/idx <> null-byte][
				append-char GET_BUFFER(buffer) as-integer #"^^"
				append-char GET_BUFFER(buffer) as-integer escape-chars/idx
			]
			true [
				append-char GET_BUFFER(buffer) cp
			]
		]
	]
	
	mold: func [
		str		[red-string!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
		/local
			int	   [red-integer!]
			limit  [integer!]
			s	   [series!]
			unit   [integer!]
			cp	   [integer!]
			p	   [byte-ptr!]
			p4	   [int-ptr!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
			curly  [integer!]
			quote  [integer!]
			nl	   [integer!]
			open   [byte!]
			close  [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/mold"]]

		limit: either OPTION?(arg) [
			int: as red-integer! arg
			int/value
		][0]
		
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		head: p
		
		tail: either zero? limit [						;@@ rework that part
			as byte-ptr! s/tail
		][
			p + (part << (unit >> 1))
		]
		if tail > as byte-ptr! s/tail [tail: as byte-ptr! s/tail]
		
		curly: 0
		quote: 0
		nl:    0
		sniff-chars p tail unit :curly :quote :nl
		
		either any [
			nl >= 3
			negative? curly
			positive? quote
			BRACES_THRESHOLD <= get-length str
		][
			open:  #"{"
			close: #"}"
		][
			open:  #"^""
			close: #"^""
		]
		
		append-char GET_BUFFER(buffer) as-integer open
		
		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			either open =  #"{" [
				switch cp [
					#"{" #"}" [
						if curly <> 0 [append-char GET_BUFFER(buffer) as-integer #"^^"]
						append-char GET_BUFFER(buffer) cp
					]
					#"^/" #"^"" [
						append-char GET_BUFFER(buffer) cp
					]
					#"^^" [
						concatenate-literal buffer "^^^^"
					]
					default [
						append-escaped-char buffer cp
					]
				]
			][
				append-escaped-char buffer cp
			]
			p: p + unit
		]
		
		append-char GET_BUFFER(buffer) as-integer close
		part - ((as-integer tail - head) >> (unit >> 1)) - 2
	]
	
	eval-path: func [
		parent	[red-string!]							;-- implicit type casting
		element	[red-value!]
		set?	[logic!]
		return:	[red-value!]
		/local
			int [red-integer!]
	][
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				either set? [
					poke parent int/value as red-char! stack/arguments	;TBD: add char! checking!
					stack/arguments
				][
					pick parent int/value
				]
			]
			TYPE_WORD [
				either set? [
					element: find parent element null no no no null null no no no no
					actions/poke as red-series! element 2 stack/arguments
					stack/arguments
				][
					select parent element null no no no null null no no
				]
			]
			default [
				print-line "*** Error: invalid value in path!"
				halt
				null
			]
		]
	]
	
	compare: func [
		str1	  [red-string!]							;-- first operand
		str2	  [red-string!]							;-- second operand
		op		  [integer!]							;-- type of comparison
		return:	  [logic!]
		/local
			s1	  [series!]
			s2	  [series!]
			unit1 [integer!]
			unit2 [integer!]
			size1 [integer!]
			size2 [integer!]
			end	  [byte-ptr!]
			p1	  [byte-ptr!]
			p2	  [byte-ptr!]
			p4	  [int-ptr!]
			c1	  [integer!]
			c2	  [integer!]
			lax?  [logic!]
			res	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/compare"]]

		if any [
			all [
				op = COMP_STRICT_EQUAL
				TYPE_OF(str2) <> TYPE_STRING
			]
			all [
				op <> COMP_STRICT_EQUAL
				TYPE_OF(str2) <> TYPE_STRING
				TYPE_OF(str2) <> TYPE_FILE
			]
		][RETURN_COMPARE_OTHER]
		
		s1: GET_BUFFER(str1)
		s2: GET_BUFFER(str2)
		unit1: GET_UNIT(s1)
		unit2: GET_UNIT(s2)
		size1: (as-integer s1/tail - s1/offset) >> (unit1 >> 1)- str1/head
		size2: (as-integer s2/tail - s2/offset) >> (unit2 >> 1)- str2/head
		
		if size1 <> size2 [								;-- shortcut exit for different sizes
			if any [op = COMP_EQUAL op = COMP_STRICT_EQUAL][return false]
			if op = COMP_NOT_EQUAL [return true]
		]
		if zero? size1 [								;-- shortcut exit for empty strings
			return any [op = COMP_EQUAL op = COMP_STRICT_EQUAL]
		]
		
		end: as byte-ptr! s1/tail						;-- only one "end" is needed
		p1:  (as byte-ptr! s1/offset) + (str1/head << (unit1 >> 1))
		p2:  (as byte-ptr! s2/offset) + (str2/head << (unit2 >> 1))
		lax?: op <> COMP_STRICT_EQUAL
		
		until [	
			switch unit1 [
				Latin1 [c1: as-integer p1/1]
				UCS-2  [c1: (as-integer p1/2) << 8 + p1/1]
				UCS-4  [p4: as int-ptr! p1 c1: p4/1]
			]
			switch unit2 [
				Latin1 [c2: as-integer p2/1]
				UCS-2  [c2: (as-integer p2/2) << 8 + p2/1]
				UCS-4  [p4: as int-ptr! p2 c2: p4/1]
			]
			if lax? [
				if all [65 <= c1 c1 <= 90][c1: c1 + 32]	;-- lowercase c1
				if all [65 <= c2 c2 <= 90][c2: c2 + 32] ;-- lowercase c2
			]
			p1: p1 + unit1
			p2: p2 + unit2
			any [
				c1 <> c2
				p1 >= end
			]
		]
		switch op [
			COMP_EQUAL			[res: c1 = c2]
			COMP_NOT_EQUAL		[res: c1 <> c2]
			COMP_STRICT_EQUAL	[res: c1 = c2]
			COMP_LESSER			[res: c1 <  c2]
			COMP_LESSER_EQUAL	[res: c1 <= c2]
			COMP_GREATER		[res: c1 >  c2]
			COMP_GREATER_EQUAL	[res: c1 >= c2]
		]
		res
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
	
	find: func [
		str			[red-string!]
		value		[red-value!]
		part		[red-value!]
		only?		[logic!]
		case?		[logic!]
		any?		[logic!]							;@@ not implemented
		with-arg	[red-string!]						;@@ not implemented
		skip		[red-integer!]
		last?		[logic!]
		reverse?	[logic!]
		tail?		[logic!]
		match?		[logic!]
		return:		[red-value!]
		/local
			s		[series!]
			s2		[series!]
			buffer	[byte-ptr!]
			pattern	[byte-ptr!]
			end		[byte-ptr!]
			end2	[byte-ptr!]
			result	[red-value!]
			int		[red-integer!]
			char	[red-char!]
			str2	[red-string!]
			unit	[encoding!]
			unit2	[encoding!]
			head2	[integer!]
			p1		[byte-ptr!]
			p2		[byte-ptr!]
			p4		[int-ptr!]
			c1		[integer!]
			c2		[integer!]
			step	[integer!]
			limit	[byte-ptr!]
			part?	[logic!]
			op		[integer!]
			found?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/find"]]

		result: stack/push as red-value! str
		
		s: GET_BUFFER(str)
		if s/offset = s/tail [							;-- early exit if string is empty
			result/header: TYPE_NONE
			return result
		]
		unit: GET_UNIT(s)
		step: 1
		part?: no

		;-- Options processing --
		
		if any [any? OPTION?(with-arg)][--NOT_IMPLEMENTED--]
		
		if OPTION?(skip) [
			assert TYPE_OF(skip) = TYPE_INTEGER
			step: skip/value
		]
		if OPTION?(part) [
			limit: either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				if int/value <= 0 [						;-- early exit if part <= 0
					result/header: TYPE_NONE
					return result
				]
				(as byte-ptr! s/offset) + (int/value - 1 << (unit >> 1)) ;-- int argument is 1-based
			][
				str2: as red-string! part
				unless all [
					TYPE_OF(str2) = TYPE_OF(str)		;-- handles ANY-STRING!
					str2/node = str/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				(as byte-ptr! s/offset) + (str2/head << (unit >> 1))
			]
			part?: yes
		]
		case [
			last? [
				step: 0 - step
				buffer: either part? [limit][(as byte-ptr! s/tail) - unit]
				end: as byte-ptr! s/offset
			]
			reverse? [
				step: 0 - step
				buffer: either part? [limit][(as byte-ptr! s/offset) + (str/head - 1 << (unit >> 1))]
				end: as byte-ptr! s/offset
				if buffer < end [							;-- early exit if str/head = 0
					result/header: TYPE_NONE
					return result
				]
			]
			true [
				buffer: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
				end: either part? [limit + unit][as byte-ptr! s/tail] ;-- + unit => compensate for the '>= test
			]
		]
		case?: not case?								;-- inverted case? meaning
		reverse?: any [reverse? last?]					;-- reduce both flags to one
		step: step << (unit >> 1)
		pattern: null
		
		;-- Value argument processing --
		
		switch TYPE_OF(value) [
			TYPE_CHAR [
				char: as red-char! value
				c2: char/value
				if all [case? 65 <= c2 c2 <= 90][c2: c2 + 32] ;-- lowercase c2
			]
			TYPE_STRING TYPE_FILE TYPE_WORD [
				either TYPE_OF(value) = TYPE_WORD [
					str2: as red-string! word/get-buffer as red-word! value
					head2: 0							;-- str2/head = -1 (casted from symbol!)
				][
					str2: as red-string! value
					head2: str2/head
				]
				s2: GET_BUFFER(str2)
				unit2: GET_UNIT(s2)
				pattern: (as byte-ptr! s2/offset) + (head2 << (unit >> 1))
				end2:    (as byte-ptr! s2/tail)
			]
			default [
				result/header: TYPE_NONE
				return result
			]
		]
		
		;-- Search loop --
		until [
			either pattern = null [
				switch unit [
					Latin1 [c1: as-integer buffer/1]
					UCS-2  [c1: (as-integer buffer/2) << 8 + buffer/1]
					UCS-4  [p4: as int-ptr! buffer c1: p4/1]
				]
				if all [case? 65 <= c1 c1 <= 90][c1: c1 + 32] ;-- lowercase c1
				found?: c1 = c2
				
				if any [
					match?								;-- /match option returns tail of match (no loop)
					all [found? tail? not reverse?]		;-- /tail option too, but only when found pattern
				][
					buffer: buffer + step
				]
			][
				p1: buffer
				p2: pattern
				until [									;-- series comparison
					either unit = unit2 [
						switch unit [
							Latin1 [
								c1: as-integer p1/1
								c2: as-integer p2/1
							]
							UCS-2  [
								c1: (as-integer p1/2) << 8 + p1/1
								c2: (as-integer p2/2) << 8 + p2/1
							]
							UCS-4  [
								p4: as int-ptr! p1
								c1: p4/1
								p4: as int-ptr! p2
								c2: p4/1
							]
						]
					][
						switch unit [
							Latin1 [c1: as-integer p1/1]
							UCS-2  [c1: (as-integer p1/2) << 8 + p1/1]
							UCS-4  [p4: as int-ptr! p1 c1: p4/1]
						]
						switch unit2 [
							Latin1 [c2: as-integer p2/1]
							UCS-2  [c2: (as-integer p2/2) << 8 + p2/1]
							UCS-4  [p4: as int-ptr! p2 c2: p4/1]
						]
					]
					if all [case? 65 <= c1 c1 <= 90][c1: c1 + 32] ;-- lowercase c1
					if all [case? 65 <= c2 c2 <= 90][c2: c2 + 32] ;-- lowercase c2
					found?: c1 = c2
					
					p1: p1 + unit
					p2: p2 + unit2
					any [
						not found?						;-- no match
						p2 >= end2						;-- searched string tail reached
						all [reverse? p1 <= end]		;-- search buffer exhausted at head
						all [not reverse? p1 >= end]	;-- search buffer exhausted at tail
					]
				]
				if all [
					found?
					p2 < end2							;-- search string tail not reached
					any [								;-- search buffer exhausted
						all [reverse? p1 <= end]
						all [not reverse? p1 >= end]
					]
				][found?: no] 							;-- partial match case, make it fail

				if all [found? any [match? tail?]][buffer: p1]
			]
			buffer: buffer + step
			any [
				match?									;-- /match option limits to one comparison
				all [not match? found?]					;-- match found
				all [reverse? buffer < end]				;-- head of block series reached
				all [not reverse? buffer >= end]		;-- tail of block series reached
			]
		]
		buffer: buffer - step							;-- compensate for extra step
		if all [tail? reverse? null? pattern][			;-- additional step for tailed reversed search
			buffer: buffer - step
		]
		
		either found? [
			str: as red-string! result
			str/head: (as-integer buffer - s/offset) >> (unit >> 1)	;-- just change the head position on stack
		][
			result/header: TYPE_NONE					;-- change the stack 1st argument to none.
		]
		result
	]
	
	select: func [
		str		 [red-string!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:	 [red-value!]
		/local
			s	   [series!]
			p	   [byte-ptr!]
			p4	   [int-ptr!]
			char   [red-char!]
			result [red-value!]
			str2   [red-string!]
			head2  [integer!]
			offset [integer!]
	][
		result: find str value part only? case? any? with-arg skip last? reverse? no no
		
		if TYPE_OF(result) <> TYPE_NONE [
			offset: switch TYPE_OF(value) [
				TYPE_STRING TYPE_FILE TYPE_WORD [
					either TYPE_OF(value) = TYPE_WORD [
						str2: as red-string! word/get-buffer as red-word! value
						head2: 0							;-- str2/head = -1 (casted from symbol!)
					][
						str2: as red-string! value
						head2: str2/head
					]
					s: GET_BUFFER(str2)
					(as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1) - head2
				]
				default [1]
			]
			str: as red-string! result
			s: GET_BUFFER(str)
			p: (as byte-ptr! s/offset) + ((str/head + offset) << (GET_UNIT(s) >> 1))
			
			either p < as byte-ptr! s/tail [
				char: as red-char! result
				char/header: TYPE_CHAR
				char/value: switch GET_UNIT(s) [
					Latin1 [as-integer p/value]
					UCS-2  [(as-integer p/2) << 8 + p/1]
					UCS-4  [p4: as int-ptr! p p4/value]
				]
			][
				result/header: TYPE_NONE
			]
		]
		result
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
			char: as red-char! stack/push*
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
		
	insert: func [
		str		 [red-string!]
		value	 [red-value!]
		part-arg [red-value!]
		only?	 [logic!]
		dup-arg	 [red-value!]
		append?	 [logic!]
		return:	 [red-value!]
		/local
			src		  [red-block!]
			cell	  [red-value!]
			limit	  [red-value!]
			int		  [red-integer!]
			char	  [red-char!]
			sp		  [red-string!]
			form-slot [red-value!]
			form-buf  [red-string!]
			s		  [series!]
			s2		  [series!]
			cnt		  [integer!]
			part	  [integer!]
			unit	  [integer!]
			i		  [integer!]
			added	  [integer!]
			type	  [integer!]
			tail?	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/insert"]]

		cnt:  1
		part: -1
		
		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				sp: as red-string! part-arg
				assert all [
					TYPE_OF(sp) = TYPE_STRING			;@@ replace by ANY_STRING?
					TYPE_OF(sp) = TYPE_FILE
					sp/node = str/node
				]
				sp/head + 1								;-- /head is 0-based
			]
		]
		if OPTION?(dup-arg) [
			int: as red-integer! dup-arg
			cnt: int/value
		]
		
		form-slot: stack/push*							;-- reserve space for FORMing incompatible values
		
		s: GET_BUFFER(str)
		tail?: any [
			(as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1) = str/head
			append?
		]
		i: 0
		added: 0
		
		while [not zero? cnt][							;-- /dup support
			either TYPE_OF(value) = TYPE_BLOCK [		;@@ replace it with: typeset/any-block?
				src: as red-block! value
				if negative? part [part: block/rs-length? src] 	;-- if not /part, use whole value length
				s2: GET_BUFFER(src)
				cell:  s2/offset + src/head
				limit: cell + part						;-- /part support
			][
				cell:  value
				limit: value + 1
			]
			while [cell < limit][						;-- multiple values case
				type: TYPE_OF(cell)
				
				either type = TYPE_CHAR [
					char: as red-char! cell
					s: GET_BUFFER(str)
					either tail? [
						append-char s char/value
					][
						insert-char s str/head + i char/value
						i: i + 1
					]
					added: added + 1
				][
					either any [
						type = TYPE_STRING				;@@ replace with ANY_STRING?
						type = TYPE_FILE 
					][
						form-buf: as red-string! cell
					][
						;TBD: free previous form-buf node and series buffer
						form-buf: string/rs-make-at form-slot 16
						actions/form cell form-buf null 0
					]
					either tail? [
						concatenate str form-buf part no no
					][
						concatenate str form-buf part no yes
					]
					added: added + rs-length? form-buf
				]
				cell: cell + 1
			]
			cnt: cnt - 1
		]
		unless append? [
			str/head: str/head + added
			s: GET_BUFFER(str)
			assert (as byte-ptr! s/offset) + (str/head << (GET_UNIT(s) >> 1)) <= as byte-ptr! s/tail
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
		str		   [red-string!]
		index	   [integer!]
		char	   [red-char!]
		return:	   [red-value!]
		/local
			s	   [series!]
			offset [integer!]
			pos	   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/poke"]]

		s: GET_BUFFER(str)
		
		offset: str/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]
		
		pos: (as byte-ptr! s/offset) + (offset << (GET_UNIT(s) >> 1))
		
		either any [
			zero? index
			pos >= as byte-ptr! s/tail
			pos <  as byte-ptr! s/offset
		][
			--NOT_IMPLEMENTED--
			;TBD: waiting for error!
		][
			if TYPE_OF(char) <> TYPE_CHAR [
				print-line "Error: POKE expected char! value"	;@@ replace by error! when ready
				halt
			]
			poke-char s pos char/value
			stack/set-last as red-value! char
		]
		as red-value! char
	]
	
	remove: func [
		str	 	 [red-string!]
		part-arg [red-value!]
		return:	 [red-string!]
		/local
			s		[series!]
			part	[integer!]
			unit	[integer!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			int		[red-integer!]
			str2	[red-string!]
	][
		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail
		
		if head = tail [return str]						;-- early exit if nothing to remove

		part: unit

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				str2: as red-string! part-arg
				unless all [
					TYPE_OF(str2) = TYPE_OF(str)		;-- handles ANY-STRING!
					str2/node = str/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				str2/head - str/head
			]
			if part <= 0 [return str]					;-- early exit if negative /part index
			part: part << (unit >> 1)
		]

		if head + part < tail [
			move-memory 
				head
				head + part
				as-integer tail - (head + part)
		]
		s/tail: as red-value! tail - part
		str
	]
	
	;--- Misc actions ---

	copy: func [
		str	    	[red-string!]
		new			[red-string!]
		part-arg	[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-series!]
		/local
			int		[red-integer!]
			str2	[red-string!]
			offset	[integer!]
			s		[series!]
			buffer	[series!]
			node	[node!]
			unit	[integer!]
			part	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/copy"]]

		s: GET_BUFFER(str)
		unit: GET_UNIT(s)

		offset: str/head << (unit >> 1)
		part: (as-integer s/tail - s/offset) - offset

		if OPTION?(types) [--NOT_IMPLEMENTED--]

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				case [
					int/value > (part >> (unit >> 1)) [part >> (unit >> 1)]
					positive? int/value [int/value]
					true				[0]
				]
			][
				str2: as red-string! part-arg
				unless all [
					TYPE_OF(str2) = TYPE_OF(str)		;-- handles ANY-STRING!
					str2/node = str/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				str2/head
			]
			part: part << (unit >> 1)
		]
		
		node: 	alloc-bytes part + unit
		buffer: as series! node/value
		buffer/flags: s/flags							;@@ filter flags?
		
		unless zero? part [
			copy-memory 
				as byte-ptr! buffer/offset
				(as byte-ptr! s/offset) + offset
				part

			buffer/tail: as cell! (as byte-ptr! buffer/offset) + part
		]
		add-terminal-NUL as byte-ptr! buffer/tail unit
		
		new/node: node
		new/head: 0
		as red-series! new
	]
	
	init: does [
		escape-chars: allocate MAX_ESC_CHARS
		fill-table
	
		datatype/register [
			TYPE_STRING
			TYPE_VALUE
			"string!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
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
			:at
			:back
			null			;change
			:clear
			:copy
			:find
			:head
			:head?
			:index?
			:insert
			:length?
			:next
			:pick
			:poke
			:remove
			null			;reverse
			:select
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
]