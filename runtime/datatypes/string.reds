Red/System [
	Title:   "String! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %string.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

string: context [
	verbose: 0
	
	#define BRACES_THRESHOLD	50						;-- max string length for using " delimiter
	#define MAX_ESC_CHARS		5Fh	
	#define MAX_URL_CHARS 		7Fh
	
	#enum escape-type! [
		ESC_CHAR: FDh
		ESC_URL:  FEh
		ESC_NONE: FFh
	]
		
	escape-chars: [
		#"^(40)" #"^(41)" #"^(42)" #"^(43)" #"^(44)" #"^(45)" #"^(46)" #"^(47)" ;-- 07h
		#"^(48)" #"-"     #"/"     #"^(4B)" #"^(4C)" #"^(4D)" #"^(4E)" #"^(4F)" ;-- 0Fh
		#"^(50)" #"^(51)" #"^(52)" #"^(53)" #"^(54)" #"^(55)" #"^(56)" #"^(57)" ;-- 17h
		#"^(58)" #"^(59)" #"^(5A)" #"^(5B)" #"^(5C)" #"^(5D)" #"^(5E)" #"^(5F)" ;-- 1Fh
		#"^(00)" #"^(00)" #"^""    #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" ;-- 27h
		#"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" ;-- 2Fh
		#"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" ;-- 37h
		#"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" ;-- 3Fh
		#"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" ;-- 47h
		#"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" ;-- 4Fh
		#"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" ;-- 57h
		#"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^(00)" #"^^"	   #"^(00)" ;-- 5Fh
	]

	escape-url-chars: [							;-- ESC_NONE: #"^(FF)" ESC_URL: #"^(FE)"
		#"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" ;-- 07h
		#"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" ;-- 0Fh
		#"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" ;-- 17h
		#"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" #"^(FE)" ;-- 1Fh
		#"^(FE)" #"^(FF)" #"^(FE)" #"^(FF)" #"^(FF)" #"^(FE)" #"^(FF)" #"^(FF)" ;-- 27h
		#"^(FE)" #"^(FE)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" ;-- 2Fh
		#"^(00)" #"^(01)" #"^(02)" #"^(03)" #"^(04)" #"^(05)" #"^(06)" #"^(07)" ;-- 37h
		#"^(08)" #"^(09)" #"^(FF)" #"^(FE)" #"^(FE)" #"^(FF)" #"^(FE)" #"^(FF)" ;-- 3Fh
		#"^(FF)" #"^(0A)" #"^(0B)" #"^(0C)" #"^(0D)" #"^(0E)" #"^(0F)" #"^(FF)" ;-- 47h
		#"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" ;-- 4Fh
		#"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" ;-- 57h
		#"^(FF)" #"^(FF)" #"^(FF)" #"^(FE)" #"^(FF)" #"^(FE)" #"^(FF)" #"^(FF)" ;-- 5Fh
		#"^(FF)" #"^(0A)" #"^(0B)" #"^(0C)" #"^(0D)" #"^(0E)" #"^(0F)" #"^(FF)" ;-- 67h
		#"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" ;-- 6Fh
		#"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" #"^(FF)" ;-- 77h
		#"^(FF)" #"^(FF)" #"^(FF)" #"^(FE)" #"^(FF)" #"^(FE)" #"^(FF)" #"^(FF)" ;-- 7Fh
	]

	utf8-buffer: [#"^(00)" #"^(00)" #"^(00)" #"^(00)"]

	to-float: func [
		s		[byte-ptr!]
		return: [float!]
		/local
			s0	[byte-ptr!]
	][
		s0: s
		if any [s/1 = #"-" s/1 = #"+"] [s: s + 1]
		if s/3 = #"#" [										;-- 1.#NaN, -1.#INF" or "1.#INF
			if any [s/4 = #"I" s/4 = #"i"] [
				return either s0/1 = #"-" [
					0.0 - float/+INF
				][float/+INF]
			]
			if any [s/4 = #"N" s/4 = #"n"] [
				return float/QNaN
			]
		]
		strtod s0 null
	]

	to-hex: func [
		value	 [integer!]
		char?	 [logic!]
		return:  [c-string!]
		/local
			s	 [c-string!]
			h	 [c-string!]
			c	 [integer!]
			i	 [integer!]
			sign [integer!]
			cp	 [integer!]
	][
		
		s: "00000000"
		h: "0123456789ABCDEF"

		c: 8
		sign: either negative? value [-1][0]
		cp: value
		while [cp <> sign][
			i: cp and 15 + 1								;-- cp // 16 + 1
			s/c: h/i
			cp: cp >> 4
			c: c - 1
		]

		either char? [
			assert cp <= 0010FFFFh							;-- codepoint <= 10FFFFh
			if zero? value [
				s/7: #"0"
				s/8: #"0"
				return s + 6
			]
			s + c
		][
			i: 1
			while [i <= c][									;-- fill leading with #"0" or #"F"
				s/i: either negative? sign [#"F"][#"0"]
				i: i + 1
			]
			s
		]
	]

	decode-utf8-hex: func [
		p			[byte-ptr!]
		unit		[integer!]
		cp			[int-ptr!]
		trailing?	[logic!]
		return: 	[byte-ptr!]
		/local
			i		[integer!]
			v1		[integer!]
			v2		[integer!]
			size	[integer!]
			src		[byte-ptr!]
			buffer	[byte-ptr!]
	][
		v1: (get-char p unit) + 1						;-- adjust for 1-base
		v2: (get-char p + unit unit) + 1				;-- adjust for 1-base
		if any [
			v1 > MAX_URL_CHARS
			v2 > MAX_URL_CHARS
		][return p]

		v1: as-integer escape-url-chars/v1
		v2: as-integer escape-url-chars/v2
		if any [
			v1 = ESC_NONE
			v2 = ESC_NONE
			v1 = ESC_URL
			v2 = ESC_URL
		][return p]

		v1: v1 << 4 + v2
		src: p + (unit << 1)

		if trailing? [cp/value: v1 return src]

		either v1 <= 7Fh [
			cp/value: v1
			p: src
		][
			i: 1
			buffer: utf8-buffer
			size: unicode/utf8-char-size? v1
			v2: size
			while [buffer/i: as byte! v1 v2 > 1][
				if (as-integer #"%") <> get-char src unit [return p]
				src: decode-utf8-hex src + unit unit :v1 true
				i: i + 1
				v2: v2 - 1
			]
			if positive? size [
				v1: unicode/decode-utf8-char as c-string! buffer :size
			]
			if positive? size [cp/value: v1 p: src]
		]
		p
	]

	rs-load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		encoding [integer!]
		return:  [red-string!]
	][
		load-in src size root encoding
	]

	rs-length?: func [
		str	    [red-string!]
		return: [integer!]
	][
		get-length str no
	]
	
	rs-skip: func [
		str 	[red-string!]
		len		[integer!]
		return: [logic!]
		/local
			s	   [series!]
			offset [integer!]
	][
		assert len >= 0
		s: GET_BUFFER(str)
		offset: str/head + len << (GET_UNIT(s) >> 1)

		if (as byte-ptr! s/offset) + offset <= as byte-ptr! s/tail [
			str/head: str/head + len
		]
		(as byte-ptr! s/offset) + offset >= as byte-ptr! s/tail
	]
	
	rs-next: func [
		str 	[red-string!]
		return: [logic!]
	][
		rs-skip str 1
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

	rs-tail?: func [
		str 	[red-string!]
		return: [logic!]
		/local
			s [series!]
	][
		s: GET_BUFFER(str)
		(as byte-ptr! s/offset) + (str/head << (GET_UNIT(s) >> 1)) >= as byte-ptr! s/tail
	]
	
	rs-abs-at: func [
		str	    [red-string!]
		pos  	[integer!]
		return:	[integer!]
		/local
			s	   [series!]
			p	   [byte-ptr!]
			unit   [integer!]
	][
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)

		p: (as byte-ptr! s/offset) + (pos << (unit >> 1))
		assert p < as byte-ptr! s/tail
		get-char p unit
	]
	
	rs-reset: func [
		str	[red-string!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(str)
		s/flags: s/flags and flag-unit-mask or Latin1
		s/tail: s/offset
		str/head: 0
	]

	rs-find-char: func [
		str		[red-string!]
		cp		[integer!]
		case?	[logic!]
		return: [logic!]
		/local
			s	 [series!]
			unit [integer!]
			head [byte-ptr!]
			tail [byte-ptr!]
			c1	 [integer!]
	][
		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail
		while [head < tail][
			c1: get-char head unit
			if case? [
				c1: case-folding/folding-case c1 yes	;-- uppercase c1
				cp: case-folding/folding-case cp yes	;-- uppercase cp
			]
			if c1 = cp [return true]
			head: head + unit
		]
		false
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
			TYPE_OF(str) = TYPE_URL
			TYPE_OF(str) = TYPE_VECTOR
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
		absolute?  [logic!]
		return:	   [integer!]
		/local
			s	   [series!]
			offset [integer!]
	][
		s: GET_BUFFER(str)
		offset: either absolute? [0][str/head]
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
			Latin1  [p/1: as-byte 0]
			UCS-2   [p/1: as-byte 0 p/2: as-byte 0]
			UCS-4   [p4: as int-ptr! p p4/1: 0]
			default [0]
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
	
	remove-char: func [
		str	 	 [red-string!]
		offset	 [integer!]
		return:	 [red-string!]
		/local
			s		[series!]
			unit	[integer!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
	][
		assert offset >= 0
		
		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (offset << (unit >> 1))
		tail: as byte-ptr! s/tail

		if head >= tail [return str]					;-- early exit if nothing to remove

		if head + unit < tail [
			move-memory 
				head
				head + unit
				as-integer tail - head					;-- account for trailing NUL
		]
		s/tail: as red-value! tail - unit
		str
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
						p: p - (as byte-ptr! s/offset)		;-- calc index value
						s: unicode/Latin1-to-UCS2 s
						p: (as byte-ptr! s/offset) + ((as-integer p) << 1) ;-- calc the new position
						s: poke-char s p cp
					]
					true [
						p: p - (as byte-ptr! s/offset)		;-- calc index value
						s: unicode/Latin1-to-UCS4 s
						p: (as byte-ptr! s/offset) + ((as-integer p) << 2) ;-- calc the new position
						s: poke-char s p cp
					]
				]
			]
			UCS-2 [
				either cp <= FFFFh [
					p/1: as-byte (cp and FFh)
					p/2: as-byte (cp >> 8)
				][
					p: p - (as byte-ptr! s/offset)			;-- calc index value
					s: unicode/UCS2-to-UCS4 s
					p: (as byte-ptr! s/offset) + ((as-integer p) << 1) ;-- calc the new position
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
	
	equal?: func [
		str1	  [red-string!]							;-- first operand
		str2	  [red-string!]							;-- second operand
		op		  [integer!]							;-- type of comparison
		match?	  [logic!]								;-- match str2 within str1 (sizes matter less)
		return:	  [integer!]
		/local
			s1	  [series!]
			s2	  [series!]
			unit1 [integer!]
			unit2 [integer!]
			size1 [integer!]
			size2 [integer!]
			head1 [integer!]
			head2 [integer!]
			end	  [byte-ptr!]
			p1	  [byte-ptr!]
			p2	  [byte-ptr!]
			p4	  [int-ptr!]
			c1	  [integer!]
			c2	  [integer!]
			lax?  [logic!]
	][
		s1: GET_BUFFER(str1)
		s2: GET_BUFFER(str2)
		unit1: GET_UNIT(s1)
		unit2: GET_UNIT(s2)
		head1: either TYPE_OF(str1) = TYPE_SYMBOL [0][str1/head]
		head2: either TYPE_OF(str2) = TYPE_SYMBOL [0][str2/head]
		size2: (as-integer s2/tail - s2/offset) >> (unit2 >> 1) - head2
		end: as byte-ptr! s2/tail							;-- only one "end" is needed

		either match? [
			if zero? size2 [
				return as-integer all [op <> COMP_EQUAL op <> COMP_STRICT_EQUAL]
			]
		][
			size1: (as-integer s1/tail - s1/offset) >> (unit1 >> 1) - head1

			either size1 <> size2 [							;-- shortcut exit for different sizes
				if any [
					op = COMP_EQUAL op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL
				][return 1]

				if size2 > size1 [
					end: end - (size2 - size1 << (unit2 >> 1))
				]
			][
				if zero? size1 [return 0]					;-- shortcut exit for empty strings
			]
		]
		p1:  (as byte-ptr! s1/offset) + (head1 << (unit1 >> 1))
		p2:  (as byte-ptr! s2/offset) + (head2 << (unit2 >> 1))
		lax?: all [op <> COMP_STRICT_EQUAL op <> COMP_CASE_SORT]

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
				c1: case-folding/folding-case c1 yes	;-- uppercase c1
				c2: case-folding/folding-case c2 yes	;-- uppercase c2
			]
			p1: p1 + unit1
			p2: p2 + unit2
			any [
				c1 <> c2
				p2 >= end
			]
		]
		if all [not match? c1 = c2][c1: size1 c2: size2]
		SIGN_COMPARE_RESULT(c1 c2)
	]
	
	match-bitset?: func [
		str	    [red-string!]
		bits    [red-bitset!]
		return: [logic!]
		/local
			s	   [series!]
			unit   [integer!]
			p	   [byte-ptr!]
			pos	   [byte-ptr!]
			p4	   [int-ptr!]
			cp	   [integer!]
			size   [integer!]
			set?   [logic!]								;-- required by BS_TEST_BIT
			not?   [logic!]
			match? [logic!]
	][
		s:	  GET_BUFFER(str)
		unit: GET_UNIT(s)
		p: 	  rs-head str
		
		s:	   GET_BUFFER(bits)
		not?:  FLAG_NOT?(s)
		size:  s/size << 3
		
		cp: switch unit [
			Latin1 [as-integer p/value]
			UCS-2  [(as-integer p/2) << 8 + p/1]
			UCS-4  [p4: as int-ptr! p p4/value]
		]
		either size < cp [not?][						;-- virtual bit
			p: bitset/rs-head bits
			BS_TEST_BIT(p cp match?)
			match?
		]
	]

	match?: func [
		str	    [red-string!]
		value   [red-value!]							;-- char! or string! value
		op		[integer!]
		return: [logic!]
		/local
			char [red-char!]
			s	 [series!]
			unit [integer!]
			c1	 [integer!]
			c2	 [integer!]
	][
		either TYPE_OF(value) = TYPE_CHAR [
			char: as red-char! value
			c1: char/value
			
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			c2: get-char 
				(as byte-ptr! s/offset) + (str/head << (unit >> 1))
				unit
			
			if op <> COMP_STRICT_EQUAL [
				if all [65 <= c1 c1 <= 90][c1: c1 + 32]	;-- lowercase c1
				if all [65 <= c2 c2 <= 90][c2: c2 + 32] ;-- lowercase c2
				c1: case-folding/folding-case c1 yes	;-- uppercase c1
				c2: case-folding/folding-case c2 yes	;-- uppercase c2
			]
			c1 = c2
		][
			either TYPE_OF(value) <> TYPE_STRING [no][	;-- @@ extend it to accept string! derivatives?
				zero? equal? str as red-string! value op yes
			]
		]
	]
	
	concatenate: func [									;-- append str2 to str1
		str1	  [red-string!]							;-- string! to extend
		str2	  [red-string!]							;-- string! to append to str1
		part	  [integer!]							;-- str2 characters to append, -1 means all
		offset	  [integer!]							;-- offset from head in codepoints
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
			p2	  [byte-ptr!]
			p4	  [int-ptr!]
			limit [byte-ptr!]
			cp	  [integer!]
			h1	  [integer!]
			h2	  [integer!]
			diff? [logic!]
	][
		s1: GET_BUFFER(str1)
		s2: GET_BUFFER(str2)
		unit1: GET_UNIT(s1)
		unit2: GET_UNIT(s2)
		diff?: unit1 <> unit2

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
				unit2: unit1
			]
			true [true]									;@@ catch-all case to make compiler happy
		]
		
		h1: either TYPE_OF(str1) = TYPE_SYMBOL [0][str1/head << (unit1 >> 1)]	;-- make symbol! used as string! pass safely
		h2: either TYPE_OF(str2) = TYPE_SYMBOL [0][str2/head << (unit2 >> 1)]	;-- make symbol! used as string! pass safely
		
		size2: (as-integer s2/tail - s2/offset) - h2
		size:  (as-integer s1/tail - s1/offset) + (unit1 / unit2 * size2) + (unit1 << 1)		;-- account for keep? and terminal NUL
		if s1/size < size [s1: expand-series s1 size]
		
		if part >= 0 [
			part: part << (unit2 >> 1)
			if part < size2 [size2: part]				;-- optionally limit str2 characters to copy
		]
		if insert? [
			move-memory									;-- make space
				(as byte-ptr! s1/offset) + h1 + offset + size2
				(as byte-ptr! s1/offset) + h1 + offset
				(as-integer s1/tail - s1/offset) - h1
		]

		p: either insert? [
			(as byte-ptr! s1/offset) + (offset << (unit1 >> 1)) + h1
		][
			as byte-ptr! s1/tail
		]
		either all [keep? diff?][
			p2: (as byte-ptr! s2/offset) + h2
			limit: p2 + size2
			while [p2 < limit][
				switch unit2 [
					Latin1 [cp: as-integer p2/1]
					UCS-2  [cp: (as-integer p2/2) << 8 + p2/1]
					UCS-4  [p4: as int-ptr! p2 cp: p4/1]
				]
				s1: either insert? [
					poke-char s1 p cp
				][
					append-char s1 cp
				]
				p: p + unit1
				p2: p2 + unit2
			]
		][
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
		encoding [integer!]
		return:  [red-string!]
		/local
			str  [red-string!]
	][
		str: as red-string! either null = blk [stack/push*][ALLOC_TAIL(blk)]
		str/header: TYPE_STRING							;-- implicit reset of all header flags
		str/head: 0
		switch encoding [
			UTF-8	 [
				str/node: unicode/load-utf8 src size
				str/cache: either size < 64 [src][null]	;-- cache only small strings
			]
			UTF-16LE [
				str/node: unicode/load-utf16 src size
				str/cache: null
			]
			default	 [
				print "*** Loading Error: input encoding unsupported"
				halt
			]
		]
		str
	]
	
	load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		encoding [integer!]
		return:  [red-string!]
	][
		load-in src size null encoding
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

	random: func [
		str		[red-string!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			char [red-char!]
			s	 [series!]
			size [integer!]
			unit [integer!]
			temp [integer!]
			idx	 [byte-ptr!]
			head [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/random"]]

		either seed? [
			str/header: TYPE_UNSET				;-- TODO: calc string to seed.
		][
			temp: 0
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			head: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
			size: (as-integer s/tail - s/offset) >> (unit >> 1) - str/head

			if only? [
				either positive? size [
					idx: head + (_random/rand % size << (unit >> 1))
					char: as red-char! str
					char/header: TYPE_CHAR
					char/value: get-char idx unit
				][
					str/header: TYPE_NONE
				]
			]

			while [size > 0][
				idx: head + (_random/rand % size << (unit >> 1))
				copy-memory as byte-ptr! :temp head unit
				copy-memory head idx unit
				copy-memory idx as byte-ptr! :temp unit
				head: head + unit
				size: size - 1
			]
		]
		as red-value! str
	]

	to: func [
		type	[red-datatype!]
		spec	[red-string!]
		return: [red-value!]
		/local
			t	[integer!]
			f	[red-float!]
			int [red-integer!]
			blk [red-block!]
			ret [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/to"]]

		t: type/value
		blk: as red-block! type
		#call [system/lexer/transcode spec none]

		either zero? block/rs-length? blk [
			ret: as red-value! blk
			ret/header: TYPE_UNSET
		][
			ret: block/rs-head blk
		]

		either t = TYPE_FLOAT [
			if TYPE_OF(ret) = TYPE_INTEGER [
				int: as red-integer! ret
				f: as red-float! ret
				f/header: TYPE_FLOAT
				f/value: integer/to-float int/value
			]
		][
			if TYPE_OF(ret) <> t [
				fire [TO_ERROR(script bad-make-arg) datatype/push t ret]
			]
		]
		stack/set-last ret
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
		concatenate buffer str limit 0 yes no
		
		part - get-length str no
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
		type	[integer!]
		all?	[logic!]
		/local
			idx [integer!]
	][
		idx: cp + 1
		case [
			all [all? cp > 7Fh][
				append-char GET_BUFFER(buffer) as-integer #"^^"
				append-char GET_BUFFER(buffer) as-integer #"("
				concatenate-literal buffer to-hex cp yes
				append-char GET_BUFFER(buffer) as-integer #")"
			]
			all [type = ESC_CHAR cp < MAX_ESC_CHARS escape-chars/idx <> null-byte][
				append-char GET_BUFFER(buffer) as-integer #"^^"
				append-char GET_BUFFER(buffer) as-integer escape-chars/idx
			]
			all [
				type = ESC_URL
				cp < MAX_URL_CHARS
				escape-url-chars/idx = (as byte! ESC_URL)
			][
				append-char GET_BUFFER(buffer) as-integer #"%"
				concatenate-literal buffer to-hex cp yes
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
			either negative? part [p][p + (part << (unit >> 1))]
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
			BRACES_THRESHOLD <= get-length str no
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
					#"^""	[append-char GET_BUFFER(buffer) cp]
					#"^^"	[concatenate-literal buffer "^^^^"]
					default [append-escaped-char buffer cp ESC_CHAR all?]
				]
			][
				append-escaped-char buffer cp ESC_CHAR all?
			]
			p: p + unit
		]

		append-char GET_BUFFER(buffer) as-integer close
		part - ((as-integer tail - head) >> (unit >> 1)) - 2
	]
	
	eval-path: func [
		parent	[red-string!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		return:	[red-value!]
		/local
			int  [red-integer!]
			set? [logic!]
	][
		set?: value <> null
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				either set? [
					poke parent int/value as red-char! value null	;TBD: add char! checking!
					value
				][
					pick parent int/value null
				]
			]
			TYPE_WORD [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(element)]
				null
			]
			default [
				either set? [
					element: find parent element null no no no null null no no no no
					actions/poke as red-series! element 2 value null
					value
				][
					select parent element null no no no null null no no
				]
			]
		]
	]
	
	compare: func [
		str1	[red-string!]							;-- first operand  (any-string!)
		str2	[red-string!]							;-- second operand (any-string!)
		op		[integer!]								;-- type of comparison
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/compare"]]
		
		if all [
			TYPE_OF(str2) <> TYPE_OF(str1)
			any [
				all [
					op <> COMP_EQUAL
					op <> COMP_NOT_EQUAL
				]
				all [
					TYPE_OF(str2) <> TYPE_STRING		;@@ use ANY_STRING?
					TYPE_OF(str2) <> TYPE_FILE
					TYPE_OF(str2) <> TYPE_URL
				]
			]
		][RETURN_COMPARE_OTHER]
		
		equal? str1 str2 op no							;-- match?: no
	]

	compare-Latin1: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			c1	[integer!]
			c2	[integer!]
	][
		c1: as-integer p1/1
		c2: as-integer p2/1
		if op = COMP_EQUAL [
			if all [65 <= c1 c1 <= 90][c1: c1 + 32]
			if all [65 <= c2 c2 <= 90][c2: c2 + 32]
		]
		either zero? flags [c1 - c2][c2 - c1]
	]

	compare-UCS2: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			c1	[integer!]
			c2	[integer!]
	][
		c1: (as-integer p1/2) << 8 + p1/1
		c2: (as-integer p2/2) << 8 + p2/1
		if op = COMP_EQUAL [
			c1: case-folding/folding-case c1 yes	;-- uppercase c1
			c2: case-folding/folding-case c2 yes	;-- uppercase c2
		]
		either zero? flags [c1 - c2][c2 - c1]
	]

	compare-UCS4: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			c1	[integer!]
			c2	[integer!]
			p4  [int-ptr!]
	][
		p4: as int-ptr! p1
		c1: p4/1
		p4: as int-ptr! p2
		c2: p4/1
		if op = COMP_EQUAL [
			c1: case-folding/folding-case c1 yes	;-- uppercase c1
			c2: case-folding/folding-case c2 yes	;-- uppercase c2
		]
		either zero? flags [c1 - c2][c2 - c1]
	]

	compare-float32: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			pf	[pointer! [float32!]]
			f1	[float32!]
			f2	[float32!]
	][
		pf: as pointer! [float32!] p1
		f1: pf/1
		pf: as pointer! [float32!] p2
		f2: pf/1
		either zero? flags [
			SIGN_COMPARE_RESULT(f1 f2)
		][
			SIGN_COMPARE_RESULT(f2 f1)
		]
	]

	compare-float: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			pf	[pointer! [float!]]
			f1	[float!]
			f2	[float!]
	][
		pf: as pointer! [float!] p1
		f1: pf/1
		pf: as pointer! [float!] p2
		f2: pf/1
		either zero? flags [
			SIGN_COMPARE_RESULT(f1 f2)
		][
			SIGN_COMPARE_RESULT(f2 f1)
		]
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
		str		[red-string!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/length?"]]

		rs-length? str
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
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/next"]]

		rs-next as red-string! stack/arguments
		stack/arguments
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
		unit: GET_UNIT(s)
		buffer: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		end: as byte-ptr! s/tail

		if any [							;-- early exit if string is empty or at tail
			s/offset = s/tail
			all [not reverse? buffer >= end]
		][
			result/header: TYPE_NONE
			return result
		]

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
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part)
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

		case?: either TYPE_OF(str) = TYPE_VECTOR [no][not case?]			;-- inverted case? meaning
		reverse?: any [reverse? last?]					;-- reduce both flags to one
		step: step << (unit >> 1)
		pattern: null
		
		;-- Value argument processing --
		
		switch TYPE_OF(value) [
			TYPE_CHAR [
				char: as red-char! value
				c2: char/value
				if case? [
					c2: case-folding/folding-case c2 yes	;-- uppercase c2
				]
			]
			TYPE_STRING
			TYPE_FILE
			TYPE_URL
			TYPE_WORD [
				either TYPE_OF(value) = TYPE_WORD [
					str2: as red-string! word/get-buffer as red-word! value
					head2: 0							;-- str2/head = -1 (casted from symbol!)
				][
					str2: as red-string! value
					head2: str2/head
				]
				s2: GET_BUFFER(str2)
				unit2: GET_UNIT(s2)
				pattern: (as byte-ptr! s2/offset) + (head2 << (unit2 >> 1))
				end2:    (as byte-ptr! s2/tail)
			]
			default [
				either all [
					TYPE_OF(str) = TYPE_VECTOR
					TYPE_OF(value) = TYPE_INTEGER
				][
					char: as red-char! value
					c2: char/value
				][
					result/header: TYPE_NONE
					return result
				]
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
				if case? [
					c1: case-folding/folding-case c1 yes	;-- uppercase c1
				]
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
					if case? [
						c1: case-folding/folding-case c1 yes	;-- uppercase c1
						c2: case-folding/folding-case c2 yes	;-- uppercase c2
					]
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
			char   [red-char!]
			result [red-value!]
			str2   [red-string!]
			head2  [integer!]
			offset [integer!]
			unit   [integer!]
	][
		result: find str value part only? case? any? with-arg skip last? reverse? no no
		
		if TYPE_OF(result) <> TYPE_NONE [
			offset: switch TYPE_OF(value) [
				TYPE_STRING TYPE_FILE TYPE_URL TYPE_WORD [
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
			unit: GET_UNIT(s)
			
			p: (as byte-ptr! s/offset) + ((str/head + offset) << (unit >> 1))
			
			either p < as byte-ptr! s/tail [
				char: as red-char! result
				char/header: either TYPE_OF(str) = TYPE_VECTOR [as-integer str/cache][TYPE_CHAR]
				char/value:  get-char p unit
			][
				result/header: TYPE_NONE
			]
		]
		result
	]

	sort: func [
		str			[red-string!]
		case?		[logic!]
		skip		[red-integer!]
		compare		[red-function!]
		part		[red-value!]
		all?		[logic!]
		reverse?	[logic!]
		stable?		[logic!]
		return:		[red-string!]
		/local
			s		[series!]
			end		[byte-ptr!]
			buffer	[byte-ptr!]
			unit	[integer!]
			cmp		[integer!]
			len		[integer!]
			len2	[integer!]
			step	[integer!]
			int		[red-integer!]
			str2	[red-string!]
			op		[integer!]
			flags	[integer!]
			mult	[integer!]
	][
		step: 1
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		mult: unit >> 1
		buffer: (as byte-ptr! s/offset) + (str/head << mult)
		end: as byte-ptr! s/tail
		len: (as-integer end - buffer) >> mult

		if OPTION?(part) [
			len2: either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				int/value
			][
				str2: as red-string! part
				unless all [
					TYPE_OF(str2) = TYPE_OF(str)		;-- handles ANY-STRING!
					str2/node = str/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part)
				]
				str2/head - str/head
			]
			if len2 < len [
				len: len2
				if negative? len2 [
					len2: negate len2
					str/head: str/head - len2
					len: either negative? str/head [str/head: 0 0][len2]
					buffer: buffer - (len << mult)
				]
			]
		]

		if OPTION?(skip) [
			assert TYPE_OF(skip) = TYPE_INTEGER
			step: skip/value
			if any [
				step <= 0
				len % step <> 0
				step > len
			][
				ERR_INVALID_REFINEMENT_ARG(refinements/_skip skip)
			]
			if step > 1 [len: len / step]
		]

		if unit = 6 [unit: 8]
		cmp: either all [
			TYPE_OF(str) = TYPE_VECTOR
			(as-integer str/cache) = TYPE_FLOAT					;-- vec/type
		][
			switch unit [
				4 [as-integer :compare-float32]
				8 [as-integer :compare-float]
			]
		][
			switch unit [
				Latin1  [as-integer :compare-Latin1]
				UCS-2   [as-integer :compare-UCS2]
				UCS-4   [as-integer :compare-UCS4]
			]
		]
		op: either TYPE_OF(str) = TYPE_VECTOR [
			COMP_STRICT_EQUAL
		][
			either case? [COMP_STRICT_EQUAL][COMP_EQUAL]
		]
		flags: either reverse? [SORT_REVERSE][SORT_NORMAL]
		_sort/qsort buffer len unit * step op flags cmp
		str
	]

	;--- Reading actions ---

	pick: func [
		str		[red-string!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			char   [red-char!]
			vec    [red-vector!]
			s	   [series!]
			offset [integer!]
			unit   [integer!]
			p1	   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/pick"]]

		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		
		offset: str/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]

		p1: (as byte-ptr! s/offset) + (offset << (unit >> 1))
		
		either any [
			zero? index
			p1 >= as byte-ptr! s/tail
			p1 <  as byte-ptr! s/offset
		][
			none-value
		][
			either TYPE_OF(str) = TYPE_VECTOR [
				vec: as red-vector! str
				vector/get-value p1 unit vec/type
			][
				char: as red-char! stack/push*
				char/header: TYPE_CHAR		
				char/value:  get-char p1 unit
				as red-value! char
			]
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
			dup-n	  [integer!]
			cnt		  [integer!]
			part	  [integer!]
			len		  [integer!]
			rest	  [integer!]
			added	  [integer!]
			type	  [integer!]
			tail?	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/insert"]]

		dup-n: 1
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
					TYPE_OF(sp) = TYPE_URL
					sp/node = str/node
				]
				sp/head + 1								;-- /head is 0-based
			]
		]
		if OPTION?(dup-arg) [
			int: as red-integer! dup-arg
			cnt: int/value
			if negative? cnt [return as red-value! str]
			dup-n: cnt
		]
		
		form-slot: stack/push*							;-- reserve space for FORMing incompatible values
		
		s: GET_BUFFER(str)
		tail?: any [
			(as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1) = str/head
			append?
		]
		
		while [not zero? cnt][							;-- /dup support
			either TYPE_OF(value) = TYPE_BLOCK [		;@@ replace it with: typeset/any-block?
				src: as red-block! value
				s2: GET_BUFFER(src)
				cell:  s2/offset + src/head
				limit: cell + block/rs-length? src
			][
				cell:  value
				limit: value + 1
			]
			rest: 0
			added: 0
			while [
				all [cell < limit added <> part]		;-- multiple values case
			][
				type: TYPE_OF(cell)
				
				either type = TYPE_CHAR [
					char: as red-char! cell
					s: GET_BUFFER(str)
					either tail? [
						append-char s char/value
					][
						insert-char s str/head + added char/value
					]
					added: added + 1
				][
					either any [
						type = TYPE_STRING				;@@ replace with ANY_STRING?
						type = TYPE_FILE 
						type = TYPE_URL
					][
						form-buf: as red-string! cell
					][
						;TBD: free previous form-buf node and series buffer
						form-buf: string/rs-make-at form-slot 16
						actions/form cell form-buf null 0
					]
					len: rs-length? form-buf
					rest: len		 					;-- if not /part, use whole value length
					if positive? part [					;-- /part support
						rest: part - added
						if rest > len [rest: len]
					]
					either tail? [
						concatenate str form-buf rest 0 no no
					][
						concatenate str form-buf rest added no yes
					]
					added: added + rest
				]
				cell: cell + 1
			]
			cnt: cnt - 1
		]
		unless append? [
			added: added * dup-n
			str/head: str/head + added
			s: GET_BUFFER(str)
			assert (as byte-ptr! s/offset) + (str/head << (GET_UNIT(s) >> 1)) <= as byte-ptr! s/tail
		]
		stack/pop 1										;-- pop the FORM slot
		as red-value! str
	]

	clear: func [
		str		[red-string!]
		return:	[red-value!]
		/local
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/clear"]]

		s: GET_BUFFER(str)
		s/tail: as cell! (as byte-ptr! s/offset) + (str/head << (GET_UNIT(s) >> 1))	
		add-terminal-NUL as byte-ptr! s/tail GET_UNIT(s)
		as red-value! str
	]

	poke: func [
		str		[red-string!]
		index	[integer!]
		char	[red-char!]
		boxed	[red-value!]
		return:	[red-value!]
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
			fire [
				TO_ERROR(script out-of-range)
				integer/push index
			]
		][
			either TYPE_OF(str) = TYPE_VECTOR [
				if TYPE_OF(char) <> as-integer str/cache [
					fire [TO_ERROR(script invalid-arg) char]
				]
				vector/set-value pos as red-value! char GET_UNIT(s)
			][
				if TYPE_OF(char) <> TYPE_CHAR [
					fire [TO_ERROR(script invalid-arg) char]
				]
				poke-char s pos char/value
			]
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

		part: either unit = 6 [8][unit]

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
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				str2/head - str/head
			]
			if part <= 0 [return str]					;-- early exit if negative /part index
			part: part << (unit >> 1)
		]

		either head + part < tail [
			move-memory 
				head
				head + part
				as-integer tail - (head + part) + unit ;-- size including trailing NUL
			s/tail: as red-value! tail - part
		][
			s/tail: as red-value! head
		]
		str
	]

	reverse: func [
		str	 	 [red-string!]
		part-arg [red-value!]
		return:	 [red-string!]
		/local
			s		[series!]
			part	[integer!]
			unit	[integer!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			temp	[byte-ptr!]
			int		[red-integer!]
			str2	[red-string!]
	][
		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail

		if head = tail [return str]						;-- early exit if nothing to reverse

		part: 0

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
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				str2/head - str/head
			]
			if part <= 0 [return str]					;-- early exit if negative /part index
			part: part << (unit >> 1)
		]

		if unit = 6 [unit: 8]
		if all [positive? part head + part < tail] [tail: head + part]
		tail: tail - unit								;-- point to last value
		temp: as byte-ptr! :part
		while [head < tail][							;-- TODO: optimise it according to unit
			copy-memory temp head unit
			copy-memory head tail unit
			copy-memory tail temp unit
			head: head + unit
			tail: tail - unit
		]
		str
	]

	take: func [
		str	    	[red-string!]
		part-arg	[red-value!]
		deep?		[logic!]
		last?		[logic!]
		return:		[red-value!]
		/local
			int		[red-integer!]
			str2	[red-string!]
			char	[red-char!]
			float	[red-float!]
			vec		[red-vector!]
			offset	[byte-ptr!]
			tail	[byte-ptr!]
			s		[series!]
			buffer	[series!]
			node	[node!]
			unit	[integer!]
			part	[integer!]
			bytes	[integer!]
			size	[integer!]
			vec?	[logic!]
			pf		[pointer! [float!]]
			pf32	[pointer! [float32!]]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/take"]]

		size: rs-length? str
		if size <= 0 [									;-- early exit if nothing to take
			set-type as cell! str TYPE_NONE
			return as red-value! str
		]
		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		part: 1

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
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				either str2/head < str/head [0][
					either last? [size - (str2/head - str/head)][str2/head - str/head]
				]
			]
			if part > size [part: size]
		]

		bytes:	part << (unit >> 1)
		node: 	alloc-bytes bytes + unit
		buffer: as series! node/value
		buffer/flags: s/flags							;@@ filter flags?

		vec?: TYPE_OF(str) = TYPE_VECTOR
		str2: as red-string! stack/push*
		either vec? [
			vec: as red-vector! str
			str2/header: TYPE_VECTOR
			str2/cache: str/cache
		][
			str2/header: TYPE_STRING
		]
		str2/node: 	node
		str2/head: 	0

		either positive? part [
			tail: as byte-ptr! s/tail
			offset: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
			if last? [
				offset: tail - bytes
				s/tail: as cell! offset
			]
			copy-memory
				as byte-ptr! buffer/offset
				offset
				bytes
			buffer/tail: as cell! (as byte-ptr! buffer/offset) + bytes

			unless last? [
				move-memory
					offset
					offset + bytes
					as-integer tail - offset - bytes
				s/tail: as cell! tail - bytes
			]
			add-terminal-NUL as byte-ptr! buffer/tail unit
			add-terminal-NUL as byte-ptr! s/tail unit
		][return as red-value! str2]

		if part = 1 [
			either vec? [
				stack/pop 1
				str2: as red-string! vector/get-value as byte-ptr! buffer/offset unit vec/type
			][										;-- return char!
				char: as red-char! str2
				char/header: TYPE_CHAR
				char/value:  get-char as byte-ptr! buffer/offset unit
			]
		]
		as red-value! str2
	]

	swap: func [
		str1	 [red-string!]
		str2	 [red-string!]
		return:	 [red-string!]
		/local
			s1		[series!]
			s2		[series!]
			char1	[integer!]
			char2	[integer!]
			unit1	[integer!]
			unit2	[integer!]
			head1	[byte-ptr!]
			head2	[byte-ptr!]
	][
		s1:    GET_BUFFER(str1)
		unit1: GET_UNIT(s1)
		head1: (as byte-ptr! s1/offset) + (str1/head << (unit1 >> 1))
		if head1 = as byte-ptr! s1/tail [return str1]				;-- early exit if nothing to swap

		s2:    GET_BUFFER(str2)
		unit2: GET_UNIT(s2)
		head2: (as byte-ptr! s2/offset) + (str2/head << (unit2 >> 1))
		if head2 = as byte-ptr! s2/tail [return str1]				;-- early exit if nothing to swap

		char1: get-char head1 unit1
		char2: get-char head2 unit2
		poke-char s1 head1 char2
		poke-char s2 head2 char1
		str1
	]

	trim-with: func [
		str			[red-string!]
		with-arg	[red-value!]
		/local
			s		[series!]
			unit	[integer!]
			cur		[byte-ptr!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			int		[red-integer!]
			n		[integer!]
			wlen	[integer!]
			size	[integer!]
			char	[integer!]
			find?	[logic!]
			str2	[red-string!]
			with-chars	[int-ptr!]
	][
		with-chars: [9 10 13 32]						;-- default chars for /ALL [TAB LF CR SPACE]
		wlen: 4
		if OPTION?(with-arg) [
			switch TYPE_OF(with-arg) [
				TYPE_CHAR
				TYPE_INTEGER [
					int: as red-integer! with-arg
					with-chars/1: int/value
					wlen: 1
				]
				TYPE_STRING [
					str2: as red-string! with-arg
					s:    GET_BUFFER(str2)
					unit: GET_UNIT(s)
					head: (as byte-ptr! s/offset) + (str2/head << (unit >> 1))
					tail: as byte-ptr! s/tail

					size: (as integer! tail - head) >> (unit >> 1)
					if zero? size [exit]				;-- early exit

					if size > wlen [
						with-chars: as int-ptr! allocate size * 4
					]
					n: 1
					while [head < tail][
						with-chars/n: get-char head unit
						n: n + 1
						head: head + unit
					]
					wlen: n - 1
				]
			]
		]

		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail
		cur: head
		while [head < tail][
			n: 0
			char: get-char head unit
			find?: false
			until [
				n: n + 1
				find?: char = with-chars/n
				any [find? n = wlen]
			]
			unless find? [
				poke-char s cur char
				cur: cur + unit
			]
			head: head + unit
		]
		add-terminal-NUL cur unit

		s/tail: as red-value! cur
		if wlen > 4 [free as byte-ptr! with-chars]
	]

	trim-lines: func [
		str			[red-string!]
		/local
			s		[series!]
			unit	[integer!]
			cur		[byte-ptr!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			pad		[integer!]
			char	[integer!]
	][
		pad: 0
		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail
		cur: head
		while [head < tail][
			char: get-char head unit
			either WHITE_CHAR?(char) [
				if pad = 1 [
					poke-char s cur as-integer #" "
					cur: cur + unit
					pad: 2
				]
			][
				poke-char s cur char
				cur: cur + unit
				pad: 1
			]
			head: head + unit
		]
		if pad = 2 [cur: cur - unit]
		add-terminal-NUL cur unit

		s/tail: as red-value! cur
	]

	trim-head-tail: func [
		str				[red-string!]
		head?			[logic!]
		tail?			[logic!]
		/local
			s			[series!]
			unit		[integer!]
			cur			[byte-ptr!]
			left		[byte-ptr!]
			head		[byte-ptr!]
			tail		[byte-ptr!]
			char		[integer!]
			append-lf?	[logic!]
			outside? 	[logic!]
			skip?		[logic!]
	][
		append-lf?: no
		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail
		cur: head

		if any [head? not tail?] [
			while [
				char: get-char head unit
				all [head < tail WHITE_CHAR?(char)]
			][
				head: head + unit
			]
		]

		if any [tail? not head?] [
			while [
				char: get-char tail - unit unit
				all [head < tail WHITE_CHAR?(char)]
			][
				if char = 10 [append-lf?: yes]
				tail: tail - unit
			]
		]

		either all [not head? not tail?] [
			outside?: no
			left: null

			while [head < tail] [
				skip?: no
				char: get-char head unit

				case [
					SPACE_CHAR?(char) [
						either outside? [skip?: yes][
							if left = null [left: cur]
						]
					]
					char = 10 [
						outside?: yes
						if left <> null [cur: left left: null]
					]
					true [
						outside?: no
						left: null
					]
				]

				unless skip? [
					poke-char s cur char
					cur: cur + unit
				]
				head: head + unit
			]
		][
			move-memory cur head (as-integer tail - head)
			cur: cur + (as-integer tail - head)
		]

		if all [append-lf? not tail?] [
			poke-char s cur 10
			cur: cur + 1
		]
		add-terminal-NUL cur unit
		s/tail: as red-value! cur
	]

	trim: func [
		str			[red-string!]
		head?		[logic!]
		tail?		[logic!]
		auto?		[logic!]
		lines?		[logic!]
		all?		[logic!]
		with-arg	[red-value!]
		return:		[red-series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/trim"]]

		case [
			any [all? OPTION?(with-arg)] [trim-with str with-arg]
			auto? [--NOT_IMPLEMENTED--]
			lines? [trim-lines str]
			true  [trim-head-tail str head? tail?]
		]
		as red-series! str
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
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				str2/head - str/head
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

		either TYPE_OF(str) = TYPE_VECTOR [
			new/header: TYPE_VECTOR
			new/cache: str/cache
		][
			add-terminal-NUL as byte-ptr! buffer/tail unit
			new/header: TYPE_STRING
		]
		new/node: 	node
		new/head: 	0
		
		as red-series! new
	]

	do-set-op: func [
		case?	 [logic!]
		skip-arg [red-integer!]
		op		 [integer!]
		return:  [red-string!]
		/local
			str1	[red-string!]
			str2	[red-string!]
			new		[red-string!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			unit	[integer!]
			i		[integer!]
			n		[integer!]
			s		[series!]
			s2		[series!]
			cp		[integer!]
			len		[integer!]
			step	[integer!]
			check?	[logic!]
			invert? [logic!]
			both?	[logic!]
			find?	[logic!]
	][
		step: 1
		if OPTION?(skip-arg) [
			assert TYPE_OF(skip-arg) = TYPE_INTEGER
			step: skip-arg/value
			if step <= 0 [
				ERR_INVALID_REFINEMENT_ARG(refinements/_skip skip-arg)
			]
		]

		find?: yes both?: no check?: no invert?: no
		if op = OP_UNION	  [both?: yes]
		if op = OP_INTERSECT  [check?: yes]
		if op = OP_EXCLUDE	  [check?: yes invert?: yes]
		if op = OP_DIFFERENCE [both?: yes check?: yes invert?: yes]

		str1: as red-string! stack/arguments
		str2: str1 + 1
		len: rs-length? str1
		len: len + either op = OP_UNION [rs-length? str2][0]
		new: rs-make-at stack/push* len
		s2: GET_BUFFER(new)
		n: 2

		until [
			s: GET_BUFFER(str1)
			unit: GET_UNIT(s)
			head: (as byte-ptr! s/offset) + (str1/head << (unit >> 1))
			tail: as byte-ptr! s/tail

			while [head < tail] [			;-- iterate over first series
				cp: get-char head unit 
				if check? [
					find?: rs-find-char str2 cp case?
					if invert? [find?: not find?]
				]
				if all [
					find?
					not rs-find-char new cp case?
				][
					s2: append-char s2 cp
				]

				i: 1
				while [						;-- skip some chars
					head: head + unit
					all [head < tail i < step]
				][
					i: i + 1
					s2: append-char s2 get-char head unit
				]
			]

			either both? [					;-- iterate over second series?
				str1: str2
				str2: as red-string! stack/arguments
				n: n - 1
			][n: 0]
			zero? n
		]
		str1/node: new/node
		str1/head: 0
		stack/pop 1
		str1
	]

	init: does [
		datatype/register [
			TYPE_STRING
			TYPE_VALUE
			"string!"
			;-- General actions --
			:make
			:random
			null			;reflect
			:to
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
			:reverse
			:select
			:sort
			:skip
			:swap
			:tail
			:tail?
			:take
			:trim
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