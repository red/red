Red/System [
	Title:   "Unicode codecs"
	Author:  "Nenad Rakocevic, Rudolf W. Meijer"
	File: 	 %unicode.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#enum encoding! [
	Latin1: 1
	UCS-2:  2
	UCS-4:  4
]

unicode: context [
	verbose: 0

	#define U_REPLACEMENT 	FFFDh
	;	choose one of the following options
	;	FFFDh			; U+FFFD = replacement character
	;	1Ah				; U+001A = control SUB (substitute)
	;	241Ah			; U+241A = symbol for substitute
	;	2426h			; U+2426 = symbol for substitute form two
	;	3Fh				; U+003F = question mark
	;	BFh				; U+00BF = inverted question mark
	;	DC00h + b1		; U+DCxx where xx = b1 (never a Unicode codepoint)
	
	latin1-to-UCS2: func [
		s		 [series!]
		return:	 [series!]
		/local
			used [integer!]
			base [byte-ptr!]
			src  [byte-ptr!]
			dst  [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "unicode/latin1-to-UCS2"]]

		used: as-integer s/tail - s/offset	
		if used * 2 >= s/size [							;-- ensure we have enough space
			s: expand-series s used * 2 + 1
		]
		base: as byte-ptr! s/offset
		src:  as byte-ptr! s/tail						;-- start from end
		dst:  (as byte-ptr! s/offset) + (used * 2)
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
	
	UCS2-to-UCS4: func [
		s		 [series!]
		return:	 [series!]
	][
		assert false
		
		#if debug? = yes [if verbose > 0 [print-line "unicode/UCS2-to-UCS4"]]

		;TBD
		s/flags: s/flags and flag-unit-mask or UCS-4	;-- s/unit: UCS-4
		s
	]

	load-utf8: func [
		src		   [c-string!]							;-- UTF-8 input buffer (zero-terminated)
		size	   [integer!]							;-- size of src in bytes
		return:	   [node!]
		/local
			node   [node!]
			s 	   [series!]
			buf1   [byte-ptr!]
			buf4   [int-ptr!]
			end    [byte-ptr!]
			unit   [integer!]
			b1 	   [integer!]							;-- up to four bytes in a UTF-8 sequence
			b2	   [integer!]							;-- for computing purposes they are of integer! type
			b3     [integer!]
			b4     [integer!]
			cp	   [integer!]							; computed codepoint
	][
		#if debug? = yes [if verbose > 0 [print-line "unicode/load-utf8"]]

		assert positive? size 
		node: alloc-series size 1 0
		
		s:    as series! node/value
		buf1: as byte-ptr! s/offset
		end:  buf1 + s/size
		unit: Latin1									;-- start with 1 byte/codepoint

		assert not zero? as-integer src/1				;@@ ensure input string not empty

		;-- the first part of loop is Rudolf's code with very minor modifications
		;-- (res/value replaced by cp, 'u renamed to 'src)
		;-- original source code: https://gist.github.com/1325840
		
		until [
			b1: as-integer src/1

			; cycling through res is done at the end; likewise for src
			; to account for this, as soon as a multiple byte sequence is consumed
			; the pointer in src is moved one less than the number of bytes consumed

			either b1 < 80h	[							; single byte (ASCII)
				cp: b1									; and we are done
			][
				cp: U_REPLACEMENT
				; assume error by default - this simplifies code greatly
				; cp is now only set if a correct sequence has been decoded

				unless b1 < C0h [						; 80h - BFh may not start a sequence
					case  [
						b1 < E0h [						; start of two-byte sequence
							b2: as-integer src/2
							if all [
								b2 >= 80h b2 < C0h
							][
								cp:	(b1 - C0h << 6) or
									(b2 - 80h)
	;							if any [
	;								cp > 7Fh			; optional test for overlong
	;								cp = 0				; even so, must allow U+0000
	;							][
									src: src + 1
	;							]
							]
						]
						b1 < F0h [						; start of three-byte sequence
							b2: as-integer src/2
							b3: as-integer src/3
							if all [
								b2 >= 80h b2 < C0h
								b3 >= 80h b3 < C0h
							][
								cp:	(b1 - E0h << 12) or
									(b2 - 80h <<  6) or
									(b3 - 80h)
								if all [
									any [cp < DC00h cp > DCFFh]
	;								cp > 7FFh			; optional test for overlong
								][
									src: src + 2
								]
							]
						]
						b1 < F8h [						; start of four-byte sequence
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
								if all [
									cp <= 0010FFFFh
	;								cp > FFFFh			; optional test for overlong
								][
									src: src + 3
								]
							]
						]
	;					true [
	;						error case					;@@ throw an error! value
	;					]
					]
				]
			]
			
			switch unit [
				Latin1 [
					either cp > 255 [
						s/tail: as cell! buf1
						unit: UCS-2
						s:    latin1-to-UCS2 s			;-- upgrade to UCS-2
						buf1: as byte-ptr! s/tail
						end:  (as byte-ptr! s/offset) + s/size
						
						buf1/1: as-byte cp and FFh
						buf1/2: as-byte cp >> 8
						buf1: buf1 + 2
					][
						buf1/value: as-byte cp
						buf1: buf1 + 1
						assert buf1 <= end				;@@ should not happen if we're good
					]
				]
				UCS-2 [
					either cp > 65535 [
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
						s: expand-series s s/size + size ;-- increase size by 100% 
						buf4: as int-ptr! s/tail
						end: (as byte-ptr! s/offset) + s/size	
					]
					buf4/value: cp
					buf4: buf4 + 1
				]
			]
			src: src + 1
			zero? b1
		] 												;-- end until
		
		s/tail: as cell! switch unit [					;-- position s/tail just before the NUL character
			Latin1 [buf1 - 1]
			UCS-2  [buf1 - 2]
			UCS-4  [buf4 - 1]
		]
		assert s/size + GET_UNIT(s) >= as-integer (s/tail - s/offset)
		
		node
	]

]