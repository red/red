Red/System [
	Title:   "Unicode codecs"
	Author:  "Nenad Rakocevic, Rudolf W. Meijer"
	File: 	 %unicode.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

unicode: context [
	verbose: 0

	#define U_REPLACEMENT 	FFFDh
	#define NOT_A_CHARACTER FFFEh
	;	choose one of the following options
	;	FFFDh			; U+FFFD = replacement character
	;	1Ah				; U+001A = control SUB (substitute)
	;	241Ah			; U+241A = symbol for substitute
	;	2426h			; U+2426 = symbol for substitute form two
	;	3Fh				; U+003F = question mark
	;	BFh				; U+00BF = inverted question mark
	;	DC00h + b1		; U+DCxx where xx = b1 (never a Unicode codepoint)

	utf8-char-size?: func [
		byte-1st	[integer!]
		return:		[integer!]
	][
		;@@ In function unicode/decode-utf8-char
		;@@ just support up to four bytes in a UTF-8 sequence
		;if byte-1st and FCh = FCh [return 6]
		;if byte-1st and F8h = F8h [return 5]
		if byte-1st and F0h = F0h [return 4]
		if byte-1st and E0h = E0h [return 3]
		if byte-1st and C0h = C0h [return 2]
		0
	]

	cp-to-utf8: func [
		cp		[integer!]
		buf		[byte-ptr!]
		return: [integer!]
	][
		case [
			cp <= 7Fh [
				buf/1: as-byte cp
				1
			]
			cp <= 07FFh [
				buf/1: as-byte cp >> 6 or C0h
				buf/2: as-byte cp and 3Fh or 80h
				2
			]
			cp < 0000FFFFh [
				buf/1: as-byte cp >> 12 or E0h
				buf/2: as-byte cp >> 6 and 3Fh or 80h
				buf/3: as-byte cp	   and 3Fh or 80h
				3
			]
			cp < 0010FFFFh [
				buf/1: as-byte cp >> 18 or F0h
				buf/2: as-byte cp >> 12 and 3Fh or 80h
				buf/3: as-byte cp >> 6  and 3Fh or 80h
				buf/4: as-byte cp 		and 3Fh or 80h
				4
			]
			true [
				fire [TO_ERROR(script invalid-char) char/push cp]
				0
			]
		]
	]

	to-utf8: func [
		str		 [red-string!]
		len		 [int-ptr!]			;-- len/value = -1 convert all chars
		return:  [c-string!]
	][
		io-to-utf8 str len no
	]

	io-to-utf8: func [
		str		 [red-string!]
		len		 [int-ptr!]			;-- len/value = -1 convert all chars
		convert? [logic!]			;-- convert line terminators to OS specific
		return:  [c-string!]
		/local
			s	 [series!]
			beg  [byte-ptr!]
			buf	 [byte-ptr!]
			p	 [byte-ptr!]
			p4	 [int-ptr!]
			tail [byte-ptr!]
			unit [integer!]
			cp	 [integer!]
			part [integer!]
	][
		s:	  GET_BUFFER(str)
		unit: GET_UNIT(s)

		part: string/rs-length? str
		unless len/value = -1 [
			if len/value < part [part: len/value]
		]
		buf: allocate unit << 1 * (1 + part)	;@@ TBD: mark this buffer as protected!
		beg: buf

		p:	  string/rs-head str
		tail: p + (part << (unit >> 1))
		
		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			#if OS = 'Windows [
				if all [convert? cp = as-integer lf][
					buf/1: cr
					buf: buf + 1
				]
			]
			buf: buf + cp-to-utf8 cp buf
			p: p + unit
		]
		buf/1: null-byte

		len/value: as-integer buf - beg
		as-c-string beg
	]
	
	Latin1-to-UCS2: func [
		s		 [series!]
		return:	 [series!]
		/local
			used [integer!]
			base [byte-ptr!]
			src  [byte-ptr!]
			dst  [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unicode/Latin1-to-UCS2"]]

		used: as-integer s/tail - s/offset
		used: used << 1 
		if used + 2 > s/size [							;-- ensure we have enough space
			s: expand-series s used + 2					;-- reserve one more for edge cases
		]
		base: as byte-ptr! s/offset
		src:  as byte-ptr! s/tail						;-- start from end
		dst:  (as byte-ptr! s/offset) + used
		s/tail: as cell! dst							;-- adjust to new tail
		
		while [src > base][								;-- in-place conversion
			src: src - 1
			dst: dst - 2
			dst/1: src/1
			dst/2: null-byte
		]
		s/flags: s/flags and flag-unit-mask or UCS-2	;-- s/unit: UCS-2
		s
	]
	
	Latin1-to-UCS4: func [
		s		 [series!]
		return:	 [series!]
		/local
			used [integer!]
			base [byte-ptr!]
			src  [byte-ptr!]
			dst  [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unicode/Latin1-to-UCS4"]]

		used: as-integer s/tail - s/offset
		used: used << 2
		if used > s/size [								;-- ensure we have enough space
			s: expand-series s used + 4					;-- reserve one more for edge cases
		]
		base: as byte-ptr! s/offset
		src:  as byte-ptr! s/tail						;-- start from end
		dst:  as int-ptr! (as byte-ptr! s/offset) + used
		s/tail: as cell! dst							;-- adjust to new tail

		while [src > base][								;-- in-place conversion
			src: src - 1
			dst: dst - 1
			dst/value: as-integer src/1
		]
		s/flags: s/flags and flag-unit-mask or UCS-4	;-- s/unit: UCS-4
		s
	]
	
	UCS2-to-UCS4: func [
		s		 [series!]
		return:	 [series!]
		/local
			used [integer!]
			base [byte-ptr!]
			src  [byte-ptr!]
			dst  [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unicode/UCS2-to-UCS4"]]

		used: as-integer s/tail - s/offset	
		used: used << 1
		if used > s/size [								;-- ensure we have enough space
			s: expand-series s used + 4
		]
		base: as byte-ptr! s/offset
		src:  as byte-ptr! s/tail						;-- start from end
		dst:  as int-ptr! (as byte-ptr! s/offset) + used
		s/tail: as cell! dst							;-- adjust to new tail

		while [src > base][								;-- in-place conversion
			src: src - 2
			dst: dst - 1
			dst/value: (as-integer src/2) << 8 + src/1
		]
		s/flags: s/flags and flag-unit-mask or UCS-4	;-- s/unit: UCS-4
		s
	]
	
	decode-utf8-char: func [
		src		[c-string!]
		cnt		[int-ptr!]								;-- pointer to size of next char in bytes
		return: [integer!]								;-- return -1 to indicate the string is incomplete, which is not an error
		/local
			b1  [integer!]								;-- up to four bytes in a UTF-8 sequence		
			b2  [integer!]								;-- for computing purposes they are of integer! type
			b3  [integer!]
			b4  [integer!]
			cp  [integer!]								; computed codepoint
	][
		b1: as-integer src/1
		
		either b1 < 80h	[								; single byte (ASCII)
			cp: b1										; and we are done
			cnt/value: 1
		][
			cp: NOT_A_CHARACTER
			; assume error by default - this simplifies code greatly
			; cp is now only set if a correct sequence has been decoded

			if b1 > BFh [								; 80h - BFh may not start a sequence
				case  [
					b1 < E0h [							; start of two-byte sequence
						if cnt/value < 2 [return -1]
						b2: as-integer src/2
						if all [
							b2 >= 80h b2 < C0h
						][
							cp:	(b1 - C0h << 6) or
								(b2 - 80h)
;							if any [
;								cp > 7Fh				; optional test for overlong
;								cp = 0					; even so, must allow U+0000
;							][
								cnt/value: 2
;							]
						]
					]
					b1 < F0h [							; start of three-byte sequence
						if cnt/value < 3 [return -1]
						b2: as-integer src/2
						b3: as-integer src/3
						if all [
							b2 >= 80h b2 < C0h
							b3 >= 80h b3 < C0h
						][
							cp:	(b1 - E0h << 12) or
								(b2 - 80h <<  6) or
								(b3 - 80h)
							;either all [
							;	any [cp < DC00h cp > DCFFh]
							;	cp > 7FFh				; optional test for overlong
							;][
							either any [cp < DC00h cp > DCFFh][
								cnt/value: 3
							][
								cp: NOT_A_CHARACTER
							]
						]
					]
					b1 < F8h [							; start of four-byte sequence
						if cnt/value < 4 [return -1]
						b2: as-integer src/2
						b3: as-integer src/3
						b4: as-integer src/4
						if all [
							b2 >= 80h b2 < C0h
							b3 >= 80h b3 < C0h
							b4 >= 80h b4 < C0h
						][
							cp:	(b1 - F0h << 18) or
								(b2 - 80h << 12) or
								(b3 - 80h <<  6) or
								(b4 - 80h)
							;either all [
							;	cp <= 0010FFFFh
							;	cp > FFFFh				; optional test for overlong
							;][
							either cp <= 0010FFFFh [
								cnt/value: 4
							][
								cp: NOT_A_CHARACTER
							]
						]
					]
					true [0]
				]
			]
		]
		if cp = NOT_A_CHARACTER [
			fire [
				TO_ERROR(access invalid-utf8)
				binary/load as byte-ptr! src 4
			]
		]
		cp
	]

	load-utf8-buffer: func [
		src		   [c-string!]							;-- UTF-8 input buffer (zero-terminated)
		size	   [integer!]							;-- size of src in bytes (excluding terminal NUL)
		dst		   [series!]							;-- optional output string! series
		remain	   [int-ptr!]							;-- number of undecoded bytes at end of buffer
		convert?   [logic!]								;-- convert all line terminators to standard
		return:	   [node!]
		/local
			node   [node!]
			s 	   [series!]
			buf1   [byte-ptr!]
			buf4   [int-ptr!]
			end    [byte-ptr!]
			unit   [integer!]
			cp	   [integer!]							;-- computed codepoint
			count  [integer!]
			used   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unicode/load-utf8-buffer"]]

		assert not negative? size 

		used: either zero? size [1][size]
		either null? dst [								;-- test if output buffer is provided
			node: alloc-series used 1 0
			s: as series! node/value
			unit:  Latin1								;-- start with 1 byte/codepoint
		][
			node: dst/node
			s: dst
			unit: GET_UNIT(s)
			if s/size / unit < used [
				s: expand-series s used * unit
			]
		]
		
		buf1:  as byte-ptr! s/offset
		buf4:  null
		end:   buf1 + s/size
		count: size

		if zero? size [return node]
		;assert not zero? as-integer src/1				;@@ ensure input string not empty
		
		if all [src/1 = #"^(EF)" src/2 = #"^(BB)" src/3 = #"^(BF)"][ ;-- skip BOM if present
			src: src + 3
			count: count - 3
		]

		;-- the first part of loop is Rudolf's code with very minor modifications
		;-- (res/value replaced by cp, 'u renamed to 'src)
		;-- original source code: https://gist.github.com/1325840
		
		until [
			; cycling through res is done at the end; likewise for src
			; to account for this, as soon as a multiple byte sequence is consumed
			; the pointer in src is moved one less than the number of bytes consumed

			used: count									;-- pass number of remaining bytes in input stream
			cp: decode-utf8-char src :used
			if cp = -1 [								;-- premature exit if buffer incomplete
				s/tail: as cell! either unit = UCS-4 [buf4][buf1]	;-- position s/tail at end of loaded characters (no NUL terminator)
				if remain <> null [remain/value: count]				;-- return the number of unprocessed bytes
				return node
			]

			if all [convert? cp = as-integer cr] [		;-- convert CRLF/CR to LF
				if all [count - used > 0 src/2 = lf] [
					count: count - used
					src: src + used
					continue
				]
				cp: as-integer lf
			]
			switch unit [
				Latin1 [
					case [
						cp <= FFh [
							buf1/value: as-byte cp
							buf1: buf1 + 1
							assert buf1 <= end			;-- should not happen if we're good
						]
						cp <= FFFFh [
							s/tail: as cell! buf1
							unit: UCS-2
							s:    Latin1-to-UCS2 s		;-- upgrade to UCS-2
							buf1: as byte-ptr! s/tail
							end:  (as byte-ptr! s/offset) + s/size

							buf1/1: as-byte cp and FFh
							buf1/2: as-byte cp >> 8
							buf1: buf1 + 2
						]
						true [
							s/tail: as cell! buf1
							unit: UCS-4
							s:    Latin1-to-UCS4 s		;-- upgrade to UCS-4
							buf4: as int-ptr! s/tail
							end:  (as byte-ptr! s/offset) + s/size

							buf4/value: cp
							buf4: buf4 + 1
						]
					]
				]
				UCS-2 [
					either cp > FFFFh [
						s/tail: as cell! buf1
						unit: UCS-4
						s:    UCS2-to-UCS4 s			;-- upgrade to UCS-4
						buf4: as int-ptr! s/tail
						end:  (as byte-ptr! s/offset) + s/size
						
						buf4/value: cp
						buf4: buf4 + 1
					][
						if buf1 >= end [
							s/tail: as cell! buf1
							s: expand-series s s/size + (size >> 2)	;-- increase size by 50% 
							buf1: as byte-ptr! s/tail
							end: (as byte-ptr! s/offset) + s/size
						]
						buf1/1: as-byte cp and FFh
						buf1/2: as-byte cp >> 8
						buf1: buf1 + 2
					]
				]
				UCS-4 [
					if buf4 >= (as int-ptr! end) [
						s/tail: as cell! buf4
						s: expand-series s s/size + size ;-- increase size by 100% 
						buf4: as int-ptr! s/tail
						end: (as byte-ptr! s/offset) + s/size
					]
					buf4/value: cp
					buf4: buf4 + 1
				]
			]
			count: count - used
			src: src + used
			zero? count
		] 												;-- end until
		
		s/tail: as cell! either unit = UCS-4 [buf4][buf1]
		assert s/size >= as-integer (s/tail - s/offset)
		
		node
	]
	
	load-utf8-stream: func [
		src		   [c-string!]							;-- UTF-8 input buffer (not NUL-terminated)
		size	   [integer!]							;-- size of src buffer in bytes (excluding NUL if any)
		output	   [red-string!]						;-- output buffer to append new chars to
		remain	   [int-ptr!]							;-- number of undecoded bytes at end of input buffer
		return:	   [node!]
	][
		load-utf8-buffer src size GET_BUFFER(output) remain no
	]

	load-utf8: func [
		src		   [c-string!]							;-- UTF-8 input buffer (zero-terminated)
		size	   [integer!]							;-- size of src in bytes (excluding terminal NUL)
		return:	   [node!]
	][
		load-utf8-buffer src size null null no
	]
	
	scan-utf16: func [									;-- detect codepoint max storage size
		src		[c-string!]
		size	[integer!]
		return: [integer!]								;-- 1, 2 or 4 (bytes per codepoint)
		/local
			unit [integer!]
			c	 [byte!]
	][
		unit: 1
		src: src + 1
		while [size > 0][
			c: src/1									;-- UTF-16LE, high byte in 2nd position
			if all [#"^(D8)" <= c c <= #"^(DF)"][return 4]	;-- max
			if c <> null-byte [unit: 2]
			src: src + 2
			size: size - 1
		]
		unit
	]

	count-extras: func [								;-- count LF and extra bytes for cp > 00010000h
		p 		[byte-ptr!]
		tail 	[byte-ptr!]
		unit	[integer!]
		return: [integer!]
		/local
			p4	  [int-ptr!]
			extra [integer!]
			cp	  [integer!]
	][
		extra: 0
		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			if any [
				cp = as-integer LF						;-- account for extra CR
				cp > 00010000h							;-- account for surrrogate pair
			][
				extra: extra + 2
			]
			p: p + unit
		]
		extra
	]
	
	load-utf16: func [ 
		src		[c-string!]								;-- UTF-16LE input buffer (zero-terminated)
		size	[integer!]								;-- size of src in codepoints (excluding terminal NUL)
		str		[red-string!]							;-- optional destination string
		cr?		[logic!]								;-- yes => remove CR in CRLF sequences
		return:	[node!]
		/local
			unit [encoding!]
			node [node!]
			s	 [series!]
			p	 [byte-ptr!]
			p4	 [int-ptr!]
			cnt  [integer!]
			c	 [integer!]
			cp	 [integer!]
			len	 [integer!]
	][
		if null? src [
			assert not null? str
			src: str/cache								;-- import UTF-16 string from cache
		]
		unit: scan-utf16 src size
		
		either null? str [
			node: either size = 0 [
				alloc-series 1 2 0						;-- create an empty string
			][
				alloc-series size unit 0
			]
			s: as series! node/value
		][
			node: str/node
			s: GET_BUFFER(str)
			len: size << (unit >> 1)
			if len > s/size [s: expand-series s len]
			s/flags: s/flags and flag-unit-mask or unit
		]
		s/flags: s/flags or flag-UTF16-cache
		p: as byte-ptr! s/offset
		cnt: size

		switch unit [
			Latin1 [
				while [cnt > 0][
					either all [cr? src/1 = #"^M" src/2 = null-byte][
						size: size - 1
					][
						p/value: src/1
						p: p + 1
					]
					src: src + 2
					cnt: cnt - 1
				]
			]
			UCS-2 [
				either cr? [
					while [cnt > 0][
						either all [src/1 = #"^M" src/2 = null-byte][
							size: size - 1
						][
							p/1: src/1
							p/2: src/2
							p: p + 2
						]
						src: src + 2
						cnt: cnt - 1
					]
				][
					copy-memory p as byte-ptr! src size * 2
				]
			]
			UCS-4 [
				p4: as int-ptr! p
				while [cnt > 0][
					c: as-integer src/2
					either all [D8h <= c c <= DBh][
						cp: c << 8 + src/1 and 03FFh << 10	;-- lead surrogate decoding
						
						src: src + 2
						cnt: cnt - 1
						c: as-integer src/2
						if any [
							cnt < 0
							not any [DCh <= c c <= DFh]
						][
							print "*** Input Error: invalid UTF-16LE codepoint"
							halt 
						]
						p4/value: c << 8 + src/1 and 03FFh or cp + 00010000h  ;-- trail surrogate decoding
						p4: p4 + 1
					][
						either all [cr? src/1 = #"^M" c = 0][
							size: size - 1
						][
							p4/value: c << 8 + src/1
							p4: p4 + 1
						]
					]
					src: src + 2
					cnt: cnt - 1
				]
			]
		]
		s/tail: as cell! (as byte-ptr! s/offset) + (size * unit)
		node
	]

	cp-to-utf16: func [
		cp		[integer!]
		buf		[byte-ptr!]
		return: [integer!]				;-- return number of utf16 codepoint
		/local
			unit [integer!]
	][
		case [
			cp < 00010000h [
				buf/1: as-byte cp
				buf/2: as-byte cp >> 8
				1
			]
			cp < 00110000h [
				cp: cp - 00010000h
				unit: cp >> 10 or D800h
				buf/1: as-byte unit
				buf/2: as-byte unit >> 8
				unit: cp and 03FFh or DC00h
				buf/3: as-byte unit
				buf/4: as-byte unit >> 8
				2
			]
			true [print "Error: to-utf16 codepoint overflow" 0]
		]
	]

	to-utf16: func [									;-- LF to CRLF conversion implied
		str		[red-string!]
		return:	[c-string!]
		/local
			len [integer!]
	][
		len: -1
		to-utf16-len str :len yes
	]

	to-utf16-len: func [
		str		[red-string!]
		len		[int-ptr!]								;-- len/value = -1 convert all chars
		cr?		[logic!]								;-- yes => convert LF to CRLF
		return: [c-string!]
		/local
			s	 [series!]
			src  [byte-ptr!]
			dst  [byte-ptr!]
			tail [byte-ptr!]
			part [integer!]
			size [integer!]
			unit [integer!]
			cp	 [integer!]
			p4	 [int-ptr!]
	][
		s:	  GET_BUFFER(str)
		unit: GET_UNIT(s)
		size: string/rs-length? str
		if all [len/value <> -1 len/value < size][size: len/value]
		part: size
		size: size << 1 + 2								;-- including terminal-NUL
		
		src: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: src + (part << (unit >> 1))

		get-cache str size + count-extras src tail unit
		dst:  as byte-ptr! str/cache

		switch unit [
			Latin1 [
				while [src < tail][						;-- in-place conversion
					if all [cr? src/1 = #"^/"][
						dst/1: #"^M"
						dst/2: null-byte
						dst: dst + 2
						part: part + 1
					]
					dst/1: src/1
					dst/2: null-byte
					src: src + 1
					dst: dst + 2
				]
			]
			UCS-2 [
				either cr? [
					while [src < tail][					;-- in-place conversion
						if all [src/1 = #"^/" src/2 = null-byte][
							dst/1: #"^M"
							dst/2: null-byte
							dst: dst + 2
							part: part + 1
						]
						dst/1: src/1
						dst/2: src/2
						src: src + 2
						dst: dst + 2
					]
				][
					unit: as-integer tail - src
					copy-memory dst src unit
					dst: dst + unit
				]
			]
			UCS-4 [
				while [src < tail][
					p4: as int-ptr! src
					cp: p4/value
					case [
						cp < 00010000h [
							if all [cr? cp = 10][		;-- check for LF
								dst/1: #"^M"
								dst/2: null-byte
								dst: dst + 2
								part: part + 1
							]
							dst/1: as-byte cp
							dst/2: as-byte cp >> 8
							dst: dst + 2
						]
						cp < 00110000h [
							cp: cp - 00010000h
							unit: cp >> 10 or D800h
							dst/1: as-byte unit
							dst/2: as-byte unit >> 8
							unit: cp and 03FFh or DC00h
							dst/3: as-byte unit
							dst/4: as-byte unit >> 8
							p4: as int-ptr! dst
							dst: dst + 4
							part: part + 1
						]
						true [print "Error: to-utf16 codepoint overflow" return null]
					]
					src: src + 4
				]
			]
		]
		dst/1: null-byte
		dst/2: null-byte
		len/value: part
		
		#if debug? = yes [
			s: (as series! str/cache) - 1
			assert (as byte-ptr! str/cache) + s/size > dst	;-- detect buffer overflow
		]
		str/cache
	]
	
	get-cache: func [
		str		[red-string!]
		size	[integer!]								;-- desired cache size in bytes
		return: [c-string!]
		/local
			node [node!]
			s	 [series!]
	][
		either null? str/cache [
			node: alloc-bytes size
			s: as series! node/value
			str/cache: as-c-string s/offset
		][
			s: (as series! str/cache) - 1
			if s/size < size [s: expand-series s size]
			str/cache: as-c-string s + 1
		]
		str/cache
	]
	
]
