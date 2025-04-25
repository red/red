Red/System [
	Title:   "String! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %string.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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

	#enum modification-type! [
		MODE_APPEND
		MODE_INSERT
		MODE_OVERWRITE
	]

	#enum escape-type! [
		ESC_CHAR: FDh
		ESC_URI:  FEh			;-- RFC 3986
		ESC_URL:  FFh			;-- similar encodeURI
	]

	;-- Non-printable characters escaping table (dots are just placeholders for no-op)
	escape-chars: #{
		40 41 42 43 44 45 46 47 ;-- 07h		@ A B C D E F G
		48 2D 2F 4B 4C 4D 4E 4F ;-- 0Fh		H - / K L M N O
		50 51 52 53 54 55 56 57 ;-- 17h		P Q R S T U V W
		58 59 5A 5B 5C 5D 5E 5F ;-- 1Fh		X Y Z [ \ ] ^ _
		00 00 22 00 00 00 00 00 ;-- 27h		. . " . . . . .
		00 00 00 00 00 00 00 00 ;-- 2Fh		. . . . . . . .
		00 00 00 00 00 00 00 00 ;-- 37h		. . . . . . . .
		00 00 00 00 00 00 00 00 ;-- 3Fh		. . . . . . . .
		00 00 00 00 00 00 00 00 ;-- 47h		. . . . . . . .
		00 00 00 00 00 00 00 00 ;-- 4Fh		. . . . . . . .
		00 00 00 00 00 00 00 00 ;-- 57h		. . . . . . . .
		00 00 00 00 00 00 5E 00 ;-- 5Fh		. . . . . . ^ .
	}
	
	;-- Hex values encoding table for special characters in URLs (FF => no-op)
	escape-url-chars: #{								;-- ESC_URL: #"^(FF)"
		FF FF FF FF FF FF FF FF ;-- 07h
		FF FF FF FF FF FF FF FF ;-- 0Fh
		FF FF FF FF FF FF FF FF ;-- 17h
		FF FF FF FF FF FF FF FF ;-- 1Fh
		FF FF FF FF FF FF FF FF ;-- 27h
		FF FF FF FF FF FF FF FF ;-- 2Fh
		00 01 02 03 04 05 06 07 ;-- 37h		#"0"-#"9" => 0-9
		08 09 FF FF FF FF FF FF ;-- 3Fh
		FF 0A 0B 0C 0D 0E 0F FF ;-- 47h		#"A"-#"F" => 10-15
		FF FF FF FF FF FF FF FF ;-- 4Fh
		FF FF FF FF FF FF FF FF ;-- 57h
		FF FF FF FF FF FF FF FF ;-- 5Fh
		FF 0A 0B 0C 0D 0E 0F FF ;-- 67h		#"a"-#"f" => 10-15
		FF FF FF FF FF FF FF FF ;-- 6Fh
		FF FF FF FF FF FF FF FF ;-- 77h
		FF FF FF FF FF FF FF FF ;-- 7Fh
	}

	;-- URI special characters encoding table (RFC3986 rules)
	;-- FF: pass-thru, 00: escape character
	uri-encode-tbl: #{
		00 00 00 00 00 00 00 00 ;-- 07h
		00 00 00 00 00 00 00 00 ;-- 0Fh
		00 00 00 00 00 00 00 00 ;-- 17h
		00 00 00 00 00 00 00 00 ;-- 1Fh
		00 00 00 00 00 00 00 00 ;-- 27h
		00 00 00 00 00 FF FF 00 ;-- 2Fh
		FF FF FF FF FF FF FF FF ;-- 37h
		FF FF 00 00 00 00 00 00 ;-- 3Fh
		00 FF FF FF FF FF FF FF ;-- 47h
		FF FF FF FF FF FF FF FF ;-- 4Fh
		FF FF FF FF FF FF FF FF ;-- 57h
		FF FF FF 00 00 00 00 FF ;-- 5Fh
		00 FF FF FF FF FF FF FF ;-- 67h
		FF FF FF FF FF FF FF FF ;-- 6Fh
		FF FF FF FF FF FF FF FF ;-- 77h
		FF FF FF 00 00 00 FF 00 ;-- 7Fh
	}

	;-- URL special characters encoding table (encodeURI rules)
	;-- FF: pass-thru, 00: escape character
	url-encode-tbl: #{
		00 00 00 00 00 00 00 00 ;-- 07h
		00 00 00 00 00 00 00 00 ;-- 0Fh
		00 00 00 00 00 00 00 00 ;-- 17h
		00 00 00 00 00 00 00 00 ;-- 1Fh
		00 FF 00 FF FF 00 FF FF ;-- 27h
		FF FF FF FF FF FF FF FF ;-- 2Fh
		FF FF FF FF FF FF FF FF ;-- 37h
		FF FF FF 00 00 FF 00 FF ;-- 3Fh
		FF FF FF FF FF FF FF FF ;-- 47h
		FF FF FF FF FF FF FF FF ;-- 4Fh
		FF FF FF FF FF FF FF FF ;-- 57h
		FF FF FF 00 00 00 00 FF ;-- 5Fh
		00 FF FF FF FF FF FF FF ;-- 67h
		FF FF FF FF FF FF FF FF ;-- 6Fh
		FF FF FF FF FF FF FF FF ;-- 77h
		FF FF FF 00 00 00 FF 00 ;-- 7Fh
	}

	utf8-buffer: #{00000000}

	to-float: func [
		s		[byte-ptr!]
		len		[integer!]
		e		[int-ptr!]
		return: [float!]
	][
		dtoa/to-float s s + len e
	]

	byte-to-hex: func [
		byte	 [integer!]
		return:  [c-string!]
		/local
			ss	 [c-string!]
			h	 [c-string!]
			i	 [integer!]
	][
		ss: "00"
		h: "0123456789ABCDEF"

		i: byte and 15 + 1								;-- byte // 16 + 1
		ss/2: h/i
		i: byte >> 4 and 15 + 1							;-- byte // 16 + 1
		ss/1: h/i
		ss
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
			assert cp <= max-char-codepoint
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

	decode-url-char: func [
		p			[byte-ptr!]
		rp			[byte-ptr!]
		return:		[logic!]
		/local
			ch		[integer!]
			v1		[integer!]
			v2		[integer!]
	][
		ch: as integer! p/1
		if ch > MAX_URL_CHARS [return false]
		if p/1 <> #"%" [return false]
		v1: 1 + as-integer p/2
		v2: 1 + as-integer p/3
		v1: as-integer escape-url-chars/v1
		v2: as-integer escape-url-chars/v2
		if any [
			v1 = ESC_URL
			v2 = ESC_URL
		][return false]

		v1: v1 << 4 + v2
		rp/1: as byte! v1
		return true
	]

	decode-url: func [
		str			[red-string!]
		url			[red-string!]
		/local
			slen	[integer!]
			data	[byte-ptr!]
			end		[byte-ptr!]
			s		[series!]
			ch		[byte!]
			size	[integer!]
			p		[byte-ptr!]
			ch2		[byte!]
			enc?	[logic!]
			code	[integer!]
			pc		[byte-ptr!]
			u		[integer!]
	][
		slen: -1
		data: as byte-ptr! unicode/to-utf8 str :slen
		if slen = 0 [exit]
		end: data + slen
		s: GET_BUFFER(url)

		ch: #"^@" ch2: #"^@"
		while [data < end][
			enc?: false
			if decode-url-char data :ch [
				size: unicode/utf8-char-size? as-integer ch
				p: data + 3
				enc?: true
				if size <> 0 [
					loop size - 1 [
						unless decode-url-char p :ch2 [
							enc?: false
							break
						]
						p: p + 3
					]
				]
			]
			either enc? [
				either size = 0 [
					s: append-char s as integer! ch
					data: data + 3
				][
					code: 0
					p: as byte-ptr! :code
					p/1: ch
					p: p + 1
					data: data + 3
					loop size - 1 [
						decode-url-char data :ch
						p/1: ch
						p: p + 1
						data: data + 3
					]
					u: unicode/decode-utf8-char as c-string! :code :size
					s: append-char s u
				]
			][
				size: as integer! end - data
				u: unicode/decode-utf8-char as c-string! data :size
				s: append-char s u
				data: data + size
			]
		]
	]

	encode-url-char: func [
		type		[integer!]
		pch			[byte-ptr!]
		psize		[int-ptr!]
		return:		[byte-ptr!]
		/local
			ss		[c-string!]
			tbl		[byte-ptr!]
			ch		[integer!]
			index	[integer!]
			code	[integer!]
			pcode	[byte-ptr!]
			str		[c-string!]
	][
		ss: "%00"
		tbl: either type = ESC_URI [uri-encode-tbl][url-encode-tbl]
		ch: as integer! pch/1
		either ch > MAX_URL_CHARS [
			code: 0
		][
			index: ch + 1
			code: as integer! tbl/index
		]
		either code = FFh [
			pcode: pch
			psize/1: 1
		][
			str: byte-to-hex ch
			ss/2: str/1
			ss/3: str/2
			pcode: as byte-ptr! ss
			psize/1: 3
		]
		pcode
	]

	encode-url: func [
		str			[red-string!]
		url			[red-string!]
		type		[integer!]
		/local
			slen	[integer!]
			data	[byte-ptr!]
			end		[byte-ptr!]
			s		[series!]
			size	[integer!]
			node	[node!]
			dst		[byte-ptr!]
			p		[byte-ptr!]
	][
		slen: -1
		data: as byte-ptr! unicode/to-utf8 str :slen
		if slen = 0 [exit]
		end: data + slen
		s: GET_BUFFER(url)

		size: 0
		while [data < end][
			p: encode-url-char type data :size
			loop size [
				node: s/node
				dst: alloc-tail-unit s 1
				dst/1: p/1
				s: as series! node/value
				p: p + 1
			]
			data: data + 1
		]
	]

	rs-load: func [
		src		 [c-string!]							;-- source string buffer
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
		_series/get-length as red-series! str no
	]

	rs-abs-length?: func [
		str	    [red-string!]
		return: [integer!]
	][
		_series/get-length as red-series! str yes
	]

	rs-skip: func [
		str 	[red-string!]
		len		[integer!]
		return: [logic!]
	][
		_series/rs-skip as red-series! str len
	]
	
	rs-next: func [
		str 	[red-string!]
		return: [logic!]
	][
		_series/rs-skip as red-series! str 1
	]

	rs-head: func [
		str	    [red-string!]
		return: [byte-ptr!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(str)
		(as byte-ptr! s/offset) + (str/head << (log-b GET_UNIT(s)))
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
		(as byte-ptr! s/offset) + (str/head << (log-b GET_UNIT(s))) >= as byte-ptr! s/tail
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

		p: (as byte-ptr! s/offset) + (pos << (log-b unit))
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
	
	rs-find: func [
		str		[red-string!]
		cp		[integer!]
		return: [integer!]
		/local
			s	 [series!]
			unit [integer!]
			pos  [byte-ptr!]
			head [byte-ptr!]
			tail [byte-ptr!]
	][
		s:	  GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (str/head << (log-b unit))
		pos:  head
		tail: as byte-ptr! s/tail
		
		while [pos < tail][
			if cp = get-char pos unit [
				return (as-integer pos - head) >> (log-b unit)
			]
			pos: pos + unit
		]
		-1
	]

	rs-find-char: func [
		str		[red-string!]
		cp		[integer!]
		skip	[integer!]
		case?	[logic!]				;-- case sensitive?
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
		skip: unit * skip
		head: (as byte-ptr! s/offset) + (str/head << (log-b unit))
		tail: as byte-ptr! s/tail
		while [head < tail][
			c1: get-char head unit
			unless case? [
				c1: case-folding/change-char c1 yes	;-- uppercase c1
				cp: case-folding/change-char cp yes	;-- uppercase cp
			]
			if c1 = cp [return true]
			head: head + skip
		]
		false
	]
	
	rs-match: func [
		str1	[red-string!]
		cstr	[c-string!]
		return: [logic!]								;-- TRUE if str1 starts with str2
		/local
			s	  [series!]
			unit  [integer!]
			size  [integer!]
			size2 [integer!]
			p	  [byte-ptr!]
			tail  [byte-ptr!]
			c	  [integer!]
			byte  [byte!]
	][
		size: rs-length? str1
		size2: length? cstr
		if size < size2 [return no]
		
		p: rs-head str1
		tail: rs-tail str1
		s: GET_BUFFER(str1)
		unit: GET_UNIT(s)
		
		while [all [p < tail cstr/1 <> null-byte]][
			c: get-char p unit
			if c > 255 [return no]
			byte: as-byte c
			if byte <> cstr/1 [return no]
			cstr: cstr + 1
			p: p + unit
		]
		yes
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

	rs-make-at: func [
		slot	[cell!]
		size 	[integer!]								;-- number of cells to pre-allocate
		return:	[red-string!]
		/local 
			p	[node!]
			str	[red-string!]
	][
		if zero? size [size: 1]
		str: as red-string! slot
		str/header: TYPE_UNSET
		str/node:  alloc-series size 1 0
		str/head:  0
		str/cache: null
		str/header: TYPE_STRING
		str
	]
	
	truncate: func [
		s	    [series!]
		part	[integer!]
		return: [series!]
		/local
			p	[cell!]
	][
		assert part > 0
		part: part << log-b GET_UNIT(s)
		if part > s/size [return s]
		
		p: as cell! (as byte-ptr! s/offset) + part
		if p < s/tail [s/tail: p]
		
		assert s/offset <= s/tail
		assert (as byte-ptr! s/offset) + s/size >= as byte-ptr! s/tail
		s
	]

	remove-part: func [
		str		[red-string!]
		offset	[integer!]
		part	[integer!]
		return:	[red-string!]
		/local
			s		[series!]
			unit	[integer!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
	][
		assert offset >= 0
		assert part > 0

		s:    GET_BUFFER(str)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (offset << (unit >> 1))
		tail: as byte-ptr! s/tail

		if head >= tail [return str]					;-- early exit if nothing to remove

		part: part << (log-b unit)
		if head + part < tail [
			move-memory 
				head
				head + part
				as-integer tail - head - part
		]
		s/tail: as red-value! tail - part
		str
	]

	append-char: func [
		s		[series!]
		cp		[integer!]								;-- codepoint
		return: [series!]
		/local
			p	 [byte-ptr!]
			p4	 [int-ptr!]
			node [node!]
	][
		switch GET_UNIT(s) [
			Latin1 [
				case [
					cp <= 7Fh [
						node: s/node
						p: alloc-tail-unit s 1
						p/1: as-byte cp
						s: as series! node/value
					]
					cp <= FFFFh [
						p: as byte-ptr! s/offset
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
					node: s/node
					p: alloc-tail-unit s 2
					p/1: as-byte (cp and FFh)
					p/2: as-byte (cp >> 8)
					s: as series! node/value
				][
					s: unicode/UCS2-to-UCS4 s
					s: append-char s cp
				]
			]
			UCS-4 [
				node: s/node
				p4: as int-ptr! alloc-tail-unit s 4
				p4/1: cp
				s: as series! node/value
			]
		]
		s										;-- refresh s address
	]

	overwrite-char: func [
		s		[series!]
		offset	[integer!]
		cp		[integer!]
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

		loop 2 [
			p: (as byte-ptr! s/offset) + (offset << (log-b unit))
			either (p + unit) > ((as byte-ptr! s/offset) + s/size) [
				s: expand-series s 0
			][
				break
			]
		]

		poke-char s p cp
		if p >= as byte-ptr! s/tail [s/tail: as cell! p + unit]
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
		p: (as byte-ptr! s/offset) + (offset << (log-b unit))
	
		move-memory										;-- make space
			p + unit
			p
			as-integer (as byte-ptr! s/tail) - p

		s/tail: as cell! (as byte-ptr! s/tail) + unit
		
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
		head: (as byte-ptr! s/offset) + (offset << (log-b unit))
		tail: as byte-ptr! s/tail

		if head >= tail [return str]					;-- early exit if nothing to remove

		if head + unit < tail [
			move-memory 
				head
				head + unit
				as-integer tail - head - unit
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
	
	move-chars: func [
		str1 [red-string!]
		str2 [red-string!]
		part [integer!]
		/local
			s1		[series!]
			s2		[series!]
			p		[byte-ptr!]
			tail	[byte-ptr!]
			offset	[integer!]
			unit	[integer!]
	][
		s1:	  GET_BUFFER(str1)
		s2:	  GET_BUFFER(str2)
		unit: GET_UNIT(s1)
		
		p: (as byte-ptr! s1/offset) + (str1/head << (log-b unit))
		offset: str2/head
		tail: p + part
		
		while [p < tail][
			insert-char s2 offset get-char p unit
			offset: offset + 1
			p: p + unit
		]
		
		offset: offset - str2/head
		if positive? offset [remove-part str1 str1/head offset]
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
			same? [logic!]
			sc	  [red-slice!]
	][
		same?: all [
			str1/node = str2/node
			str1/head = str2/head
		]
		if op = COMP_SAME [return either same? [0][-1]]
		if all [
			same?
			any [op = COMP_EQUAL op = COMP_FIND op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL]
		][return 0]

		if TYPE_OF(str1) = TYPE_SYMBOL [symbol/make-red-string as red-symbol! str1]
		if TYPE_OF(str2) = TYPE_SYMBOL [symbol/make-red-string as red-symbol! str2]

		s1: GET_BUFFER(str1)
		s2: GET_BUFFER(str2)
		unit1: GET_UNIT(s1)
		unit2: GET_UNIT(s2)
		head1: either TYPE_OF(str1) = TYPE_SYMBOL [0][str1/head]
		head2: either TYPE_OF(str2) = TYPE_SYMBOL [0][str2/head]
		size1: (as-integer s1/tail - s1/offset) >> (log-b unit1) - head1
		sc: as red-slice! str2
		either all [TYPE_OF(sc) = TYPE_SLICE sc/length >= 0][
			size2: sc/length
			end: (as byte-ptr! s2/offset) + (head2 + size2 << (log-b unit2))
		][
			size2: (as-integer s2/tail - s2/offset) >> (log-b unit2) - head2
			end: as byte-ptr! s2/tail						;-- only one "end" is needed
		]

		either match? [
			if zero? size2 [
				return as-integer all [op <> COMP_EQUAL op = COMP_FIND op <> COMP_STRICT_EQUAL]
			]
			if size2 > size1 [return 1]
		][
			either size1 <> size2 [							;-- shortcut exit for different sizes
				if any [
					op = COMP_EQUAL op = COMP_FIND op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL
				][return 1]

				if zero? size2 [return 1]					;-- edge case 1

				if size2 > size1 [
					end: end - (size2 - size1 << (log-b unit2))
				]
			][
				if zero? size1 [return 0]					;-- shortcut exit for empty strings
			]
		]

		if zero? size1 [return -1]							;-- edge case 2

		p1:  (as byte-ptr! s1/offset) + (head1 << (log-b unit1))
		p2:  (as byte-ptr! s2/offset) + (head2 << (log-b unit2))
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
				c1: case-folding/change-char c1 yes	;-- uppercase c1
				c2: case-folding/change-char c2 yes	;-- uppercase c2
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
	
	match-tag?: func [
		str		[red-string!]
		value	[red-value!]						;-- tag!
		op		[integer!]
		return:	[logic!]
		/local
			s	 [series!]
			unit [integer!]
			c1	 [integer!]
			c2	 [integer!]
			len	 [integer!]
	][
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		c1: get-char 
			(as byte-ptr! s/offset) + (str/head << (log-b unit))
			unit
		
		len: str/head + 1 + rs-length? as red-string! value
		c2: get-char
			(as byte-ptr! s/offset) + (len << (log-b unit))
			unit
		
		all [c1 = as-integer #"<" c2 = as-integer #">"]
	]

	match?: func [
		str	    [red-string!]
		value   [red-value!]							;-- char! or string! value
		op		[integer!]
		return: [logic!]
		/local
			char [red-char!]
			s	 [series!]
			type [integer!]
			unit [integer!]
			c1	 [integer!]
			c2	 [integer!]
			res? [logic!]
	][
		type: TYPE_OF(value)
		switch type [
			TYPE_CHAR [
				char: as red-char! value
				c1: char/value

				s: GET_BUFFER(str)
				unit: GET_UNIT(s)
				c2: get-char 
					(as byte-ptr! s/offset) + (str/head << (log-b unit))
					unit

				if op <> COMP_STRICT_EQUAL [
					c1: case-folding/change-char c1 yes	;-- uppercase c1
					c2: case-folding/change-char c2 yes	;-- uppercase c2
				]
				c1 = c2
			]
			TYPE_TAG [
				either match-tag? str value op [
					str/head: str/head + 1
					res?: zero? equal? str as red-string! value op yes
					str/head: str/head - 1
					res?
				][no]
			]
			default  [
				either ANY_STRING?(type) [				;-- TYPE_TAG excluded
					zero? equal? str as red-string! value op yes
				][no]
			]
		]
	]

	alter: func [
		str1	[red-string!]							;-- string! to modify
		str2	[red-string!]							;-- string! to modify to str1
		part	[integer!]								;-- str2 characters to overwrite, -1 means all
		offset	[integer!]								;-- offset from head in codepoints
		keep?	[logic!]								;-- do not change str2 encoding
		mode	[integer!]								;-- type of modification: append, insert or overwrite
		/local
			s1	  [series!]
			s2	  [series!]
			tail  [byte-ptr!]
			p	  [byte-ptr!]
			p2	  [byte-ptr!]
			p4	  [int-ptr!]
			limit [byte-ptr!]
			unit1 [integer!]
			unit2 [integer!]
			type1 [integer!]
			type2 [integer!]
			size  [integer!]
			size1 [integer!]
			size2 [integer!]
			cp	  [integer!]
			h1	  [integer!]
			h2	  [integer!]
			diff? [logic!]
			same? [logic!]
	][
		type1: TYPE_OF(str1)
		type2: TYPE_OF(str2)
		if type1 = TYPE_SYMBOL [symbol/make-red-string as red-symbol! str1]
		if type2 = TYPE_SYMBOL [symbol/make-red-string as red-symbol! str2]

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
		
		h1: either type1 = TYPE_SYMBOL [0][str1/head << (log-b unit1)]	;-- make symbol! used as string! pass safely
		h2: either type2 = TYPE_SYMBOL [0][str2/head << (log-b unit2)]	;-- make symbol! used as string! pass safely
		
		size2: (as-integer s2/tail - s2/offset) - h2 >> (log-b unit2)
		if all [part >= 0 part < size2][size2: part]
		size: unit1 * size2
		if size <= 0 [exit]

		size1: (as-integer s1/tail - s1/offset) + size
		if (as byte-ptr! s1/size) < (as byte-ptr! size1) [	;-- force to use unsigned comparison
			same?: s1 = s2
			s1: expand-series s1 size1 * 2
			if same? [s2: s1]
		]

		if mode = MODE_INSERT [
			move-memory									;-- make space
				(as byte-ptr! s1/offset) + h1 + offset + size
				(as byte-ptr! s1/offset) + h1 + offset
				(as-integer s1/tail - s1/offset) - h1 - offset
		]

		tail: as byte-ptr! s1/tail
		p: either mode = MODE_APPEND [
			tail
		][
			(as byte-ptr! s1/offset) + (offset << (log-b unit1)) + h1
		]
		either all [keep? diff?][
			assert s1 <> s2
			p2: (as byte-ptr! s2/offset) + h2
			limit: p2 + (size2 << (log-b unit2))
			while [p2 < limit][
				switch unit2 [
					Latin1 [cp: as-integer p2/1]
					UCS-2  [cp: (as-integer p2/2) << 8 + p2/1]
					UCS-4  [p4: as int-ptr! p2 cp: p4/1]
				]
				s1: either mode = MODE_APPEND [
					append-char s1 cp
				][
					poke-char s1 p cp
				]
				p: p + unit1
				p2: p2 + unit2
			]
		][
			either s1 = s2 [
				move-memory p (as byte-ptr! s2/offset) + h2 size
			][
				copy-memory p (as byte-ptr! s2/offset) + h2 size
			]
			p: p + size
		]
		if mode = MODE_INSERT [p: tail + size] 
		if all [mode = MODE_OVERWRITE p < tail][p: tail]
		s1/tail: as cell! p
	]

	overwrite: func [									;-- overwrite str2 to str1
		str1	  [red-string!]							;-- string! to overwrite
		str2	  [red-string!]							;-- string! to overwrite to str1
		part	  [integer!]							;-- str2 characters to overwrite, -1 means all
		offset	  [integer!]							;-- offset from head in codepoints
		keep?	  [logic!]								;-- do not change str2 encoding
	][
		alter str1 str2 part offset keep? MODE_OVERWRITE
	]
	
	concatenate: func [									;-- append str2 to str1
		str1	  [red-string!]							;-- string! to extend
		str2	  [red-string!]							;-- string! to append to str1
		part	  [integer!]							;-- str2 characters to append, -1 means all
		offset	  [integer!]							;-- offset from head in codepoints
		keep?	  [logic!]								;-- do not change str2 encoding
		insert?	  [logic!]								;-- insert str2 at str1 index instead of appending
	][
		alter str1 str2 part offset keep? as-integer insert?
	]

	concatenate-literal: func [
		str		  [red-string!]
		p		  [c-string!]							;-- Red/System literal string
		return:   [series!]
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
		s
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
	
	load-at: func [
		src		 [c-string!]							;-- source string buffer
		size	 [integer!]
		slot	 [red-value!]
		encoding [integer!]
		return:  [red-string!]
		/local
			str  [red-string!]
	][
		str: as red-string! either slot = null [stack/push*][slot]
		str/header: TYPE_UNSET
		str/head:	0
		str/cache:	null
		switch encoding [
			UTF-8	 [str/node: unicode/load-utf8 src size]
			UTF-16LE [str/node: unicode/load-utf16 src size null no]
			default	 [
				print "*** Loading Error: input encoding unsupported"
				halt
			]
		]
		str/header:	TYPE_STRING							;-- implicit reset of all header flags
		str
	]

	load-in: func [
		src		 [c-string!]							;-- source string buffer
		size	 [integer!]
		blk		 [red-block!]
		encoding [integer!]
		return:  [red-string!]
	][
		load-at src size ALLOC_TAIL(blk) encoding
	]
	
	load: func [
		src		 [c-string!]							;-- source string buffer
		size	 [integer!]
		encoding [integer!]
		return:  [red-string!]
	][
		load-at src size null encoding
	]
	
	make-at: func [
		slot	[red-value!]
		size 	[integer!]								;-- number of codepoints to pre-allocate
		unit	[integer!]
		return:	[red-string!]
		/local 
			str	[red-string!]
	][
		str: as red-string! slot
		set-type slot TYPE_UNSET
		str/head:	0
		str/node:	alloc-codepoints size unit
		str/cache:	null
		set-type slot TYPE_STRING
		str
	]
	
	push: func [
		str		[red-string!]
		return: [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/push"]]

		as red-string! copy-cell as red-value! str stack/push*
	]

	compare-call: func [								;-- Wrap red function!
		value1   [byte-ptr!]
		value2   [byte-ptr!]
		fun		 [integer!]
		flags	 [integer!]
		return:  [integer!]
		/local
			res  [red-value!]
			bool [red-logic!]
			int  [red-integer!]
			d    [red-float!]
			f	 [red-function!]
			all? [logic!]
			num  [integer!]
			cnt  [integer!]
			str1 [red-string!]
			str2 [red-string!]
			v1	 [red-value!]
			v2	 [red-value!]
			s1   [series!]
			s2   [series!]
			unit [integer!]
			c1	 [integer!]
			c2	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/compare-call"]]

		f: as red-function! fun
		stack/mark-func words/_compare-cb f/ctx
		
		unit: flags >>> 2 and 7
		c1: get-char value1 unit
		c2: get-char value2 unit

		either flags and sort-reverse-mask = 0 [
			v2: as red-value! char/push c2
			v1: as red-value! char/push c1
		][
			v1: as red-value! char/push c1
			v2: as red-value! char/push c2
		]

		all?: flags and sort-all-mask = sort-all-mask
		num: flags >>> 5
		if all [all? num > 0][
			str1: make-at v1 1 unit
			str2: make-at v2 1 unit
			s1: GET_BUFFER(str1)
			s2: GET_BUFFER(str2)
			s1/offset: as red-value! value1
			s2/offset: as red-value! value2
			s1/tail: as red-value! (value1 + (num << (log-b unit)))
			s2/tail: as red-value! (value2 + (num << (log-b unit)))
		]

		cnt: _function/count-locals f/spec 0 no
		if positive? cnt [_function/init-locals cnt]
		interpreter/call f f/ctx as red-value! words/_compare-cb CB_SORT
		stack/unwind
		stack/pop 1

		res: stack/top
		switch TYPE_OF(res) [
			TYPE_LOGIC [
				bool: as red-logic! res
				either bool/value [1][-1]
			]
			TYPE_INTEGER [
				int: as red-integer! res
				0 - int/value
			]
			TYPE_FLOAT [
				d: as red-float! res
				case [
					d/value > 0.0 [-1]
					d/value < 0.0 [1]
					true [0]
				]
			]
			TYPE_NONE [-1]
			default [1]
		]
	]

	utf8-to-str: func [
		src		[c-string!]
		len		[integer!]
		return: [red-string!]
		/local
			remain	[integer!]
			str		[red-string!]
	][
		remain: 0
		str: rs-make-at stack/push* len
		unicode/load-utf8-stream src len str :remain
		if remain > 0 [
			fire [
				TO_ERROR(access invalid-utf8)
				binary/load as byte-ptr! src + (len - remain) remain
			]
		]
		str
	]

	;-- Actions -- 
	
	make: func [
		proto	[red-string!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-string!]
		/local
			size [integer!]
			int	 [red-integer!]
			fl	 [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/make"]]
		
		either any [
			TYPE_OF(spec) = TYPE_INTEGER
			TYPE_OF(spec) = TYPE_FLOAT
		][
			size: get-int-from spec
			if size < 0 [fire [TO_ERROR(script out-of-range) spec]]
			proto/header: TYPE_UNSET						;-- implicit reset of all header flags
			proto/head: 0
			proto/node: alloc-bytes size					;-- alloc enough space for at least a Latin1 string
			proto/cache: null
			proto/header: type								;-- implicit reset of all header flags
			proto
		][
			either type = TYPE_BINARY [
				if TYPE_OF(spec) = TYPE_MONEY [
					fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_BINARY spec]
				]
				as red-string! binary/to as red-binary! proto spec type
			][
				to as red-value! proto spec type
			]
		]
	]

	to: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-string!]
		/local
			buffer	[red-string!]
			node	[node!]
			remain	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/to"]]
		
		switch TYPE_OF(spec) [
			TYPE_ANY_STRING [
				buffer: as red-string! _series/copy
					as red-series! spec
					as red-series! proto
					null no null
			]
			TYPE_BINARY [
				buffer: utf8-to-str
					as-c-string binary/rs-head as red-binary! spec
					binary/rs-length? as red-binary! spec
			]
			TYPE_ANY_LIST [
				buffer: make-at proto 16 1
				insert buffer spec null no null yes
			]
			TYPE_REFINEMENT [
				buffer: rs-make-at proto 16
				either type = TYPE_STRING [
					actions/form spec buffer null 0
				][
					refinement/mold as red-word! spec buffer yes yes yes null 0 0
				]
			]
			TYPE_NONE [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_STRING spec]
			]
			default [
				buffer: rs-make-at proto 16
				actions/form spec buffer null 0
			]
		]
		set-type as cell! buffer type
		buffer
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
		
		part - rs-length? str
	]
	
	sniff-chars: func [
		p	  [byte-ptr!]
		tail  [byte-ptr!]
		unit  [integer!]
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
				#"^""   [quote/value: quote/value + 1]
				#"^/"   [nl/value: 	  nl/value + 1]
				default [0]
			]
			p: p + unit
		]
	]

	find-right-brace: func [
		p			[byte-ptr!]
		tail		[byte-ptr!]
		unit		[integer!]
		return:		[logic!]
		/local
			cp		[integer!]
			p4		[int-ptr!]
			cnt		[integer!]
	][
		cnt: 0
		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			switch cp [
				#"{"    [cnt: cnt + 1]
				#"}"    [cnt: cnt - 1 if cnt = 0 [return true]]
				default [0]
			]
			p: p + unit
		]
		false
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
			any [cp = 1Eh all [80h <= cp cp <= 9Fh] all [all? cp > 7Fh]][
				append-char GET_BUFFER(buffer) as-integer #"^^"
				append-char GET_BUFFER(buffer) as-integer #"("
				concatenate-literal buffer to-hex cp yes
				append-char GET_BUFFER(buffer) as-integer #")"
			]
			all [type = ESC_CHAR cp < MAX_ESC_CHARS escape-chars/idx <> null-byte][
				append-char GET_BUFFER(buffer) as-integer #"^^"
				append-char GET_BUFFER(buffer) as-integer escape-chars/idx
			]
			all [type = ESC_CHAR cp = 7Fh][
				concatenate-literal buffer "^^~"
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
			c-beg  [integer!]
			conti? [logic!]
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
		p: (as byte-ptr! s/offset) + (str/head << (log-b unit))
		head: p
		
		tail: either zero? limit [						;@@ rework that part
			as byte-ptr! s/tail
		][
			either negative? part [p][p + (part << (log-b unit))]
		]
		if tail > as byte-ptr! s/tail [tail: as byte-ptr! s/tail]

		c-beg: 0
		conti?: true
		quote: 0
		nl:    0
		sniff-chars p tail unit :quote :nl

		either any [
			nl >= 3
			positive? quote
			BRACES_THRESHOLD <= rs-length? str
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
					#"{" [
						if all [conti? not find-right-brace p tail unit][
							conti?: false
						]
						either conti? [c-beg: c-beg + 1][
							append-char GET_BUFFER(buffer) as-integer #"^^"
						]
						append-char GET_BUFFER(buffer) cp
					]
					#"}" [
						either c-beg > 0 [c-beg: c-beg - 1][
							append-char GET_BUFFER(buffer) as-integer #"^^"
						]
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
		part - ((as-integer tail - head) >> (log-b unit)) - 2
	]
	
	eval-path: func [
		parent	[red-string!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		gparent [red-value!]
		p-item	[red-value!]
		index	[integer!]
		case?	[logic!]
		get?	[logic!]
		tail?	[logic!]
		evt?	[logic!]
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
					_series/poke as red-series! parent int/value value null	;TBD: add char! checking!
					value
				][
					_series/pick as red-series! parent int/value null
				]
			]
			TYPE_WORD [
				fire [TO_ERROR(script invalid-path) path element]
				null
			]
			default [
				either set? [
					element: find parent element null no no no no null null no no no no
					if TYPE_OF(element) = TYPE_NONE [
						fire [TO_ERROR(script bad-path-set) path element]
					]
					actions/poke as red-series! element 2 value null
					value
				][
					select parent element null no no no no null null no no
				]
			]
		]
	]
	
	compare: func [
		str1	[red-string!]							;-- first operand  (any-string!)
		str2	[red-string!]							;-- second operand (any-string!)
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			type1 type2 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/compare"]]
		
		type1: TYPE_OF(str1)
		type2: TYPE_OF(str2)
		
		if all [
			type1 <> type2
			any [
				not ANY_STRING?(type2)
				all [
					op <> COMP_EQUAL
					op <> COMP_NOT_EQUAL
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
			c1		[integer!]
			c2		[integer!]
			count	[integer!]
			res		[integer!]
			rev		[integer!]
	][
		rev: either flags and sort-reverse-mask = sort-reverse-mask [-1][1]
		either flags and sort-all-mask = sort-all-mask [
			count: flags >> 2
		][
			count: flags >> 2
			p1: p1 + count
			p2: p2 + count
			count: 1
		]
		loop count [
			c1: as-integer p1/1
			c2: as-integer p2/1
			if op = COMP_EQUAL [
				if all [65 <= c1 c1 <= 90][c1: c1 + 32]
				if all [65 <= c2 c2 <= 90][c2: c2 + 32]
			]
			res: c1 - c2 * rev
			unless zero? res [break]
			p1: p1 + 1 p2: p2 + 1
		]
		res
	]

	compare-UCS2: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			c1		[integer!]
			c2		[integer!]
			count	[integer!]
			res		[integer!]
			rev		[integer!]
	][
		rev: either flags and sort-reverse-mask = sort-reverse-mask [-1][1]
		either flags and sort-all-mask = sort-all-mask [
			count: flags >> 2
		][
			count: flags >> 2 << 1
			p1: p1 + count
			p2: p2 + count
			count: 1
		]
		loop count [
			c1: (as-integer p1/2) << 8 + p1/1
			c2: (as-integer p2/2) << 8 + p2/1
			if op = COMP_EQUAL [
				c1: case-folding/change-char c1 yes	;-- uppercase c1
				c2: case-folding/change-char c2 yes	;-- uppercase c2
			]
			res: c1 - c2 * rev
			unless zero? res [break]
			p1: p1 + 2 p2: p2 + 2
		]
		res
	]

	compare-UCS4: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			c1		[integer!]
			c2		[integer!]
			count	[integer!]
			res		[integer!]
			rev		[integer!]
			p4  	[int-ptr!]
	][
		rev: either flags and sort-reverse-mask = sort-reverse-mask [-1][1]
		either flags and sort-all-mask = sort-all-mask [
			count: flags >> 2
		][
			count: flags and -4							;-- flags >> 2 * 4
			p1: p1 + count
			p2: p2 + count
			count: 1
		]
		loop count [
			p4: as int-ptr! p1
			c1: p4/1
			p4: as int-ptr! p2
			c2: p4/1
			if op = COMP_EQUAL [
				c1: case-folding/change-char c1 yes	;-- uppercase c1
				c2: case-folding/change-char c2 yes	;-- uppercase c2
			]
			res: c1 - c2 * rev
			unless zero? res [break]
			p1: p1 + 4 p2: p2 + 4
		]
		res
	]

	compare-float32: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			pf		[pointer! [float32!]]
			f1		[float32!]
			f2		[float32!]
			count	[integer!]
			res		[integer!]
			rev		[integer!]
	][
		rev: either flags and sort-reverse-mask = sort-reverse-mask [-1][1]
		either flags and sort-all-mask = sort-all-mask [
			count: flags >> 2
		][
			count: flags and -4							;-- flags >> 2 * 4
			p1: p1 + count
			p2: p2 + count
			count: 1
		]
		loop count [
			pf: as pointer! [float32!] p1
			f1: pf/1
			pf: as pointer! [float32!] p2
			f2: pf/1
			res: SIGN_COMPARE_RESULT(f1 f2)
			res: res * rev
			unless zero? res [break]
			p1: p1 + 4 p2: p2 + 4
		]
		res
	]

	compare-float: func [
		p1		[byte-ptr!]
		p2		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		return: [integer!]
		/local
			pf		[pointer! [float!]]
			f1		[float!]
			f2		[float!]
			count	[integer!]
			res		[integer!]
			rev		[integer!]
	][
		rev: either flags and sort-reverse-mask = sort-reverse-mask [-1][1]
		either flags and sort-all-mask = sort-all-mask [
			count: flags >> 2
		][
			count: flags and -4 << 1					;-- flags >> 2 * 8
			p1: p1 + count
			p2: p2 + count
			count: 1
		]
		loop count [
			pf: as pointer! [float!] p1
			f1: pf/1
			pf: as pointer! [float!] p2
			f2: pf/1
			res: SIGN_COMPARE_RESULT(f1 f2)
			res: res * rev
			unless zero? res [break]
			p1: p1 + 8 p2: p2 + 8
		]
		res
	]

	find: func [
		str			[red-string!]
		value		[red-value!]
		part		[red-value!]
		only?		[logic!]
		case?		[logic!]
		same?		[logic!]
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
			end1	[byte-ptr!]
			end2	[byte-ptr!]
			result	[red-value!]
			int		[red-integer!]
			char	[red-char!]
			fl		[red-float!]
			str2	[red-string!]
			bits	[red-bitset!]
			sbits	[series!]
			pbits	[byte-ptr!]
			pos		[byte-ptr!]								;-- required by BS_TEST_BIT
			p1 p2	[byte-ptr!]
			p4		[int-ptr!]
			pf		[float-ptr!]
			unit	[encoding!]
			unit2	[encoding!]
			head2	[integer!]
			c1 c2	[integer!]
			cf1 cf2	[float!]
			step	[integer!]
			sz		[integer!]
			sz2		[integer!]
			len     [integer!]
			limit	[integer!]
			part?	[logic!]
			bs?		[logic!]
			type	[integer!]
			found?	[logic!]
			float?	[logic!]
			get2	[subroutine!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/find"]]
		
		get2: [
			s2: GET_BUFFER(str2)
			unit2: GET_UNIT(s2)
			pattern: (as byte-ptr! s2/offset) + (head2 << (log-b unit2))
			end2:    (as byte-ptr! s2/tail)
			sz2: 	 (as-integer end2 - pattern) >> (log-b unit2)
		]

		result: stack/push as red-value! str
		
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		buffer: (as byte-ptr! s/offset) + (str/head << (log-b unit))
		end: as byte-ptr! s/tail
		len: rs-length? str

		if any [							;-- early exit if string is empty or at tail
			s/offset = s/tail
			all [not reverse? buffer >= end]
		][
			result/header: TYPE_NONE
			return result
		]

		step: 1
		part?: no
		type: TYPE_OF(str)

		;-- Options processing --
		
		if any [any? OPTION?(with-arg)][--NOT_IMPLEMENTED--]
		
		if OPTION?(skip) [
			assert TYPE_OF(skip) = TYPE_INTEGER
			step: skip/value
			if step < 1 [fire [TO_ERROR(script out-of-range) skip]]
		]
		if OPTION?(part) [
			sz: either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				int/value
			][
				str2: as red-string! part
				unless all [
					TYPE_OF(str2) = type				;-- handles ANY-STRING!
					str2/node = str/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part)
				]
				str2/head - str/head
			]
			if sz <= 0 [								;-- early exit if part <= 0
				result/header: TYPE_NONE
				return result
			]
			if sz > len [sz: len]
			part?: yes
			limit: sz << log-b unit
		]
		case [
			last? [
				step: 0 - step
				end: buffer
				buffer: either part? [buffer + limit][as byte-ptr! s/tail]
				buffer: buffer - unit
			]
			reverse? [
				step: 0 - step
				buffer: (as byte-ptr! s/offset) + (str/head - 1 << (log-b unit))
				end: either part? [buffer - limit + unit][as byte-ptr! s/offset]
				if any [buffer < end match?][			;-- early exit if str/head = 0
					result/header: TYPE_NONE
					return result
				]
			]
			true [
				end: either part? [buffer + limit][as byte-ptr! s/tail] ;-- + unit => compensate for the '>= test
			]
		]

		case?: either ANY_STRING?(type) [not case?][no]
		if same? [case?: no]
		reverse?: any [reverse? last?]					;-- reduce both flags to one
		step: step << (log-b unit)
		pattern: end2: null
		bs?: no
		float?: TYPE_OF(value) = TYPE_FLOAT
		sz2: unit2: 0
		
		;-- Value argument processing --
		
		switch TYPE_OF(value) [
			TYPE_CHAR [
				char: as red-char! value
				c2: char/value
				if case? [c2: case-folding/change-char c2 yes] ;-- uppercase c2
			]
			TYPE_BITSET [
				bits:  as red-bitset! value
				sbits: GET_BUFFER(bits)
				pbits: as byte-ptr! sbits/offset
				sz: (as-integer sbits/tail - sbits/offset) << 3
				bs?:   yes
				case?: no
			]
			TYPE_STRING
			TYPE_FILE
			TYPE_URL
			TYPE_EMAIL
			TYPE_REF
			TYPE_BINARY
			TYPE_WORD [
				either TYPE_OF(value) = TYPE_WORD [
					str2: as red-string! word/get-buffer as red-word! value
					head2: 0							;-- str2/head = -1 (casted from symbol!)
				][
					if all [TYPE_OF(str) <> TYPE_BINARY TYPE_OF(value) = TYPE_BINARY][
						fire [TO_ERROR(script invalid-arg) value]						
					]
					str2: as red-string! value
					head2: str2/head
				]
				get2
			]
			default [
				either all [
					any [
						TYPE_OF(str) = TYPE_VECTOR
						TYPE_OF(str) = TYPE_BINARY
					]
					any [TYPE_OF(value) = TYPE_INTEGER float?]
				][
					either float? [
						fl: as red-float! value
						cf2: fl/value
					][
						char: as red-char! value
						c2: char/value
					]
				][
					str2: string/rs-make-at stack/push* 16
					actions/form value str2 null 0
					head2: 0
					get2
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
					8	   [pf: as float-ptr! buffer cf1: pf/value]	;-- vector of float64! case
				]
				if all [case? not float?][
					c1: case-folding/change-char c1 yes ;-- uppercase c1
				]
				either bs? [
					either c1 < sz [
						BS_TEST_BIT(pbits c1 found?)
					][
						found?: as logic! sbits/flags and flag-bitset-not
					]
				][
					found?: either float? [cf1 = cf2][c1 = c2]
				]
				if all [found? tail? not reverse?][		;-- /tail option too, but only when found pattern
					buffer: buffer + step
				]
			][
				p1: buffer
				end1: end
				if reverse? [
					sz: (as-integer p1 - end) >> (log-b unit) + 1
					if sz < sz2 [found?: no break] 
					p1: p1 - (sz2 - 1 << (log-b unit))
					end1: buffer + unit
				]
				p2: pattern
				until [									;-- series comparison
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
					if case? [
						c1: case-folding/change-char c1 yes	;-- uppercase c1
						c2: case-folding/change-char c2 yes	;-- uppercase c2
					]
					found?: c1 = c2
					
					p1: p1 + unit
					p2: p2 + unit2
					any [
						not found?						;-- no match
						p2 >= end2						;-- searched string tail reached
						p1 >= end1						;-- search buffer exhausted at tail
					]
				]
				if all [
					found?
					p2 < end2							;-- search string tail not reached
					p1 >= end1							;-- search buffer exhausted
				][found?: no] 							;-- partial match case, make it fail

				if found? [
					if reverse? [buffer: end1 - (sz2 << (log-b unit))]
					if tail? [buffer: p1]
				]
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
			str/head: (as-integer buffer - s/offset) >> (log-b unit) ;-- just change the head position on stack
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
		same?	 [logic!]
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
			type   [integer!]
	][
		result: find str value part only? case? same? any? with-arg skip last? reverse? no no
		
		if TYPE_OF(result) <> TYPE_NONE [
			offset: switch TYPE_OF(value) [
				TYPE_ANY_STRING
				TYPE_WORD
				TYPE_BINARY [
					either TYPE_OF(value) = TYPE_WORD [
						str2: as red-string! word/get-buffer as red-word! value
						head2: 0							;-- str2/head = -1 (casted from symbol!)
					][
						str2: as red-string! value
						head2: str2/head
					]
					s: GET_BUFFER(str2)
					(as-integer s/tail - s/offset) >> (log-b GET_UNIT(s)) - head2
				]
				default [1]
			]
			str: as red-string! result
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			
			p: (as byte-ptr! s/offset) + ((str/head + offset) << (log-b unit))
			
			either p < as byte-ptr! s/tail [
				type: switch TYPE_OF(str) [
					TYPE_BINARY	[TYPE_INTEGER]
					TYPE_VECTOR [as-integer str/cache]
					default 	[TYPE_CHAR]
				]
				char: as red-char! result
				char/header: type
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
		comparator	[red-function!]
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
			offset	[integer!]
			chk?	[logic!]
	][
		step: 1
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		mult: log-b unit
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
					len2: 0 - len2
					str/head: str/head - len2
					len: either negative? str/head [str/head: 0 0][len2]
					buffer: buffer - (len << mult)
				]
			]
		]
		if zero? len [return str]						;-- early exit if nothing to sort

		either OPTION?(skip) [
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
		][
			if all? [fire [TO_ERROR(script bad-refines)]]
		]

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

		either OPTION?(comparator) [
			switch TYPE_OF(comparator) [
				TYPE_FUNCTION [
					flags: unit << 2 or flags
					if all [all? OPTION?(skip)] [
						flags: flags or sort-all-mask
						flags: step << 5 or flags
					]
					cmp: as-integer :compare-call
					op: as-integer comparator
				]
				TYPE_INTEGER [
					if any [all? not OPTION?(skip)] [
						fire [TO_ERROR(script bad-refines)]
					]
					int: as red-integer! comparator
					offset: int/value
					if any [offset < 1 offset > step][
						fire [
							TO_ERROR(script out-of-range)
							comparator
						]
					]
					flags: offset - 1 << 2 or flags
				]
				default [
					ERR_INVALID_REFINEMENT_ARG(refinements/compare comparator)
				]
			]
		][
			if all [all? OPTION?(skip)] [
				flags: flags or sort-all-mask
				flags: step << 2 or flags
			]
		]
		chk?: ownership/check as red-value! str words/_sort null str/head 0
		_sort/qsort buffer len unit * step op flags cmp
		if chk? [ownership/check as red-value! str words/_sorted null str/head 0]
		str
	]

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
			action	  [red-word!]
			s		  [series!]
			s2		  [series!]
			dup-n	  [integer!]
			cnt		  [integer!]
			part	  [integer!]
			len		  [integer!]
			rest	  [integer!]
			added	  [integer!]
			type	  [integer!]
			index	  [integer!]
			slots	  [integer!]
			size	  [integer!]
			tail?	  [logic!]
			chk?	  [logic!]
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
				form-buf: as red-string! value
				unless all [
					TYPE_OF(sp) = TYPE_OF(form-buf)
					sp/node = form-buf/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				sp/head - form-buf/head
			]
		]
		if OPTION?(dup-arg) [
			int: as red-integer! dup-arg
			cnt: int/value
			if negative? cnt [return as red-value! str]
			dup-n: cnt
		]
		
		form-slot: stack/push*							;-- reserve space for FORMing incompatible values
		form-slot/header: TYPE_UNSET
		
		s: GET_BUFFER(str)
		len: (as-integer s/tail - s/offset) >> (log-b GET_UNIT(s))
		tail?: any [len = str/head append?]
		index: either append? [
			action: words/_append
			len
		][
			action: words/_insert
			str/head
		]
		chk?: ownership/check as red-value! str action value index part

		slots: either part > 0 [cnt * part][cnt]
		slots: slots * GET_UNIT(s)
		size: slots + as-integer s/tail - s/offset
		if size > s/size [
			if cnt <= 4 [size: size * 2]				;-- double it if low number of inserted slots
			s: expand-series s size
		]
		
		while [not zero? cnt][							;-- /dup support
			type: TYPE_OF(value)
			either any [								;@@ replace it with: typeset/any-list?
				type = TYPE_BLOCK
				type = TYPE_PAREN
				type = TYPE_HASH
			][
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
					either all [
						ANY_STRING?(type)
						type <> TYPE_TAG				;-- preserve angle brackets
					][
						form-buf: as red-string! cell
					][
						;TBD: free previous form-buf node and series buffer
						form-buf: rs-make-at form-slot 16
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
		if part < 0 [part: 1]							;-- ownership/check needs part >= 0
		if chk? [
			action: either append? [words/_appended][words/_inserted]
			ownership/check as red-value! str action value index part
		]
		either append? [str/head: 0][
			added: added * dup-n
			str/head: str/head + added
			s: GET_BUFFER(str)
			part: log-b GET_UNIT(s)
			if (as byte-ptr! s/offset) + (str/head << part) > as byte-ptr! s/tail [ ;-- check for past-end caused by object event
				str/head: (as-integer s/tail - s/offset) >> part  ;-- adjust offset to series' tail
			]
		]
		stack/pop 1										;-- pop the FORM slot
		as red-value! str
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
			chk? chk2? [logic!]
	][
		switch TYPE_OF(str2) [
			TYPE_BINARY
			TYPE_ANY_STRING [0]
			default 		[fire [TO_ERROR(script invalid-arg) str2]]
		]
		s1:    GET_BUFFER(str1)
		unit1: GET_UNIT(s1)
		head1: (as byte-ptr! s1/offset) + (str1/head << (log-b unit1))
		if head1 = as byte-ptr! s1/tail [return str1]				;-- early exit if nothing to swap

		s2:    GET_BUFFER(str2)
		unit2: GET_UNIT(s2)
		head2: (as byte-ptr! s2/offset) + (str2/head << (log-b unit2))
		if head2 = as byte-ptr! s2/tail [return str1]				;-- early exit if nothing to swap

		chk?:  ownership/check as red-value! str1 words/_swap null str1/head 1
		chk2?: ownership/check as red-value! str2 words/_swap null str2/head 1
		char1: get-char head1 unit1
		char2: get-char head2 unit2
		poke-char s1 head1 char2
		poke-char s2 head2 char1
		if chk?  [ownership/check as red-value! str1 words/_swaped null str1/head 1]
		if chk2? [ownership/check as red-value! str2 words/_swaped null str2/head 1]
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
		with-chars/1: 9
		with-chars/2: 10
		with-chars/3: 13
		with-chars/4: 32
		wlen: 4
		if OPTION?(with-arg) [
			switch TYPE_OF(with-arg) [
				TYPE_CHAR
				TYPE_INTEGER [
					int: as red-integer! with-arg
					with-chars/1: int/value
					wlen: 1
				]
				TYPE_BINARY
				TYPE_STRING [
					str2: as red-string! with-arg
					s:    GET_BUFFER(str2)
					unit: GET_UNIT(s)
					head: (as byte-ptr! s/offset) + (str2/head << (log-b unit))
					tail: as byte-ptr! s/tail

					size: (as integer! tail - head) >> (log-b unit)
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
		head: (as byte-ptr! s/offset) + (str/head << (log-b unit))
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
		head: (as byte-ptr! s/offset) + (str/head << (log-b unit))
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
		head: (as byte-ptr! s/offset) + (str/head << (log-b unit))
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
			cur: cur + unit
		]
		s/tail: as red-value! cur
	]
	
	take: func [
		str	    	[red-string!]
		part-arg	[red-value!]
		deep?		[logic!]
		last?		[logic!]
		return:		[red-value!]
		/local
			char	[red-char!]
			vec		[red-vector!]
			s		[series!]
			unit	[integer!]
			type	[integer!]
	][
		str: as red-string! _series/take as red-series! str part-arg deep? last?
		s: GET_BUFFER(str)

		if all [
			not OPTION?(part-arg)
			1 = _series/get-length as red-series! str yes
		][
			unit: GET_UNIT(s)
			type: TYPE_OF(str)
			either type = TYPE_VECTOR [
				vec: as red-vector! str
				str: as red-string! vector/get-value as byte-ptr! s/offset unit vec/type
			][
				type: either type = TYPE_BINARY [TYPE_INTEGER][TYPE_CHAR]
				char: as red-char! str
				char/header: type
				char/value:  get-char as byte-ptr! s/offset unit
			]
		]
		as red-value! str
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
		/local
			chk?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "string/trim"]]

		chk?: ownership/check as red-value! str words/_trim null str/head 0
		case [
			any [all? OPTION?(with-arg)] [trim-with str with-arg]
			auto? [--NOT_IMPLEMENTED--]
			lines? [trim-lines str]
			true  [trim-head-tail str head? tail?]
		]
		if chk? [ownership/check as red-value! str words/_trimmed null str/head 0]
		as red-series! str
	]

	change-range: func [
		str		[red-string!]
		cell	[red-value!]
		limit	[red-value!]
		part?	[logic!]
		return: [integer!]
		/local
			s			[series!]
			added		[integer!]
			len			[integer!]
			type		[integer!]
			char		[red-char!]
			form-buf	[red-string!]
			form-slot	[red-value!]
	][
		form-slot: stack/push*				;-- reserve space for FORMing incompatible values
		form-slot/header: TYPE_UNSET
		added: 0

		while [cell < limit][
			type: TYPE_OF(cell)
			either type = TYPE_CHAR [
				char: as red-char! cell
				s: GET_BUFFER(str)
				either part? [				;-- /part will insert extra elements
					insert-char s str/head + added char/value
				][
					overwrite-char s str/head + added char/value
				]
				added: added + 1
			][
				either all [
					ANY_STRING?(type)
					type <> TYPE_TAG				;-- preserve angle brackets
				][
					form-buf: as red-string! cell
				][
					;TBD: free previous form-buf node and series buffer
					form-buf: rs-make-at form-slot 16
					actions/form cell form-buf null 0
				]
				len: rs-length? form-buf			;-- form-buf can be changed by overwrite/concatenate
				either part? [
					concatenate str form-buf -1 added yes yes
				][
					overwrite str form-buf -1 added yes
				]
				added: added + len
			]
			cell: cell + 1
		]
		stack/pop 1							;-- pop the FORM slot
		added
	]

	do-set-op: func [
		case?	 [logic!]
		skip-arg [red-integer!]
		op		 [integer!]
		return:  [red-series!]
		/local
			ser1	[red-series!]
			ser2	[red-series!]
			new		[red-series!]
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
			append?	[logic!]
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

		ser1: as red-series! stack/arguments
		ser2: ser1 + 1
		len: _series/get-length ser1 no
		if op = OP_UNION [len: len + _series/get-length ser2 no]
		new: as red-series! rs-make-at stack/push* len
		if zero? len [return new]			;-- early exit if nothing to do
		s2: GET_BUFFER(new)
		n: 2

		until [
			s: GET_BUFFER(ser1)
			unit: GET_UNIT(s)
			head: (as byte-ptr! s/offset) + (ser1/head << (log-b unit))
			tail: as byte-ptr! s/tail

			while [head < tail] [			;-- iterate over first series
				append?: no
				cp: get-char head unit
				if check? [
					find?: rs-find-char as red-string! ser2 cp step case?
					if invert? [find?: not find?]
				]
				if all [
					find?
					not rs-find-char as red-string! new cp step case?
				][
					append?: yes
					s2: append-char s2 cp
				]

				i: 1
				while [						;-- skip some chars
					head: head + unit
					all [head < tail i < step]
				][
					i: i + 1
					if append? [s2: append-char s2 get-char head unit]
				]
			]

			either both? [					;-- iterate over second series?
				ser1: ser2
				ser2: as red-series! stack/arguments
				n: n - 1
			][n: 0]
			zero? n
		]
		ser1/node: new/node
		ser1/head: 0
		stack/pop 1
		ser1
	]

	init: does [
		datatype/register [
			TYPE_STRING
			TYPE_SERIES
			"string!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			INHERIT_ACTION	;reflect
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
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			INHERIT_ACTION	;change
			INHERIT_ACTION	;clear
			INHERIT_ACTION	;copy
			:find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			:insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;move
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			null			;put
			INHERIT_ACTION	;remove
			INHERIT_ACTION	;reverse
			:select
			:sort
			INHERIT_ACTION	;skip
			:swap
			INHERIT_ACTION	;tail
			INHERIT_ACTION	;tail?
			:take
			:trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			INHERIT_ACTION	;modify
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