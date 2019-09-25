Red/System [
	Title:   "Red values low-level tokenizer"
	Author:  "Nenad Rakocevic"
	File: 	 %tokenizer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2017-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

tokenizer: context [

	;; For UTF-8 decoding, uses DFA algorithm: http://bjoern.hoehrmann.de/utf-8/decoder/dfa/#variations
	
	utf8d: [ ;[byte! 8]
		; The first part of the table maps bytes to character classes that
		; to reduce the size of the transition table and create bitmasks.
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
		1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1   9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 
		7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7   7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 
		8 8 2 2 2 2 2 2 2 2 2 2 2 2 2 2   2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 
		10 3 3 3 3 3 3 3 3 3 3 3 3 4 3 3  11 6 6 6 5 8 8 8 8 8 8 8 8 8 8 8 
	
		; The second part is a transition table that maps a combination
		; of a state of the automaton and a character class to a state.
		0  12 24 36 60 96 84 12 12 12 48 72  12 12 12 12 12 12 12 12 12 12 12 12 
		12  0 12 12 12 12 12  0 12  0 12 12  12 24 12 12 12 12 12 24 12 24 12 12 
		12 12 12 12 12 12 12 24 12 12 12 12  12 24 12 12 12 12 12 12 12 24 12 12 
		12 12 12 12 12 12 12 36 12 36 12 12  12 36 12 12 12 12 12 36 12 36 12 12 
		12 36 12 12 12 12 12 12 12 12 12 12  
	]
	
	decode-utf8-char: func [
		p		[byte-ptr!]
		cp		[int-ptr!]
		return: [byte-ptr!]
		/local
			state [integer!]
			byte  [integer!]
			idx	  [integer!]
			type  [integer!]
	][
		state: 0
		forever [
			byte: as-integer p/value
			idx: byte + 1
			type: utf8d/idx
			
			idx: 256 + state + type + 1
			state: utf8d/idx
			
			switch state [
				0 [										;-- ACCEPT
					cp/value: FFh >> type and byte
					return p + 1
				]
				12 [									;-- REJECT
					cp/value: -1
					return p
				]
				default [
					cp/value: byte and 3Fh or (cp/value << 6)
					p: p + 1
				]
			]
		]
		as byte-ptr! 0									;-- never reached, just make compiler happy
	]
	
	scanner!: alias function! [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]]


	scan-string: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]

	scan-alt-string: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]

	scan-block: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]

	scan-paren: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]

	scan-comment: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]

	scan-file: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]
	
	scan-refinement: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]

	scan-money: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]

	scan-lesser: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]

	scan-lit: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]
	
	scan-get: func [s [byte-ptr!] end [byte-ptr!] return: [byte-ptr!]
	;	/local
	][
		s
	]
	
	value-1st: [
		#"^""			:scan-string
		#"{"			:scan-alt-string
		#"["			:scan-block
		#"("			:scan-paren
		#";"			:scan-comment
		#"%"			:scan-file
		#"/"			:scan-refinement
		#"$"			:scan-money
		#"<"			:scan-lesser
		#"'"			:scan-lit
		#":"			:scan-get
		;[#"0" - #"9"] 	:scan-digit
		;else			:scan-word
	]

	scan-token: func [
		src [byte-ptr!]
		len [integer!]
		/local
			p	   [byte-ptr!]
			end	   [byte-ptr!]
			cp	   [integer!]
			res	   [int-ptr!]
			action [scanner!]
	][
		p: src
		end: p + len

		while [p < end][
			cp: as-integer p/value
			res: as int-ptr! value-1st/cp
			either null? res [
				p: p + 1
			][
				action: as scanner! res
				p: action p + 1 end
			]
		]
	]

	scan-integer: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		error	[int-ptr!]
		return: [integer!]
		/local
			c	 [integer!]
			n	 [integer!]
			m	 [integer!]
			neg? [logic!]
	][
		neg?: no
		
		c: string/get-char p unit
		if any [
			c = as-integer #"+" 
			c = as-integer #"-"
		][
			neg?: c = as-integer #"-"
			p: p + unit
			len: len - 1
		]
		n: 0
		until [
			c: (string/get-char p unit) - #"0"
			either all [c <= 9 c >= 0][					;-- skip #"'"
				m: n * 10
				if system/cpu/overflow? [error/value: -2 return 0]
				n: m
				if all [neg? n = 2147483640 c = 8][return 80000000h] ;-- special exit trap for -2147483648
				m: n + c
				if system/cpu/overflow? [error/value: -2 return 0]
				n: m
			][
				c: c + #"0"
				case [
					c = as-integer #"." [break]
					c = as-integer #"'" [0]				;-- pass-thru
					true				[
						error/value: -1
						len: 1 							;-- force exit
					]
				]
			]
			p: p + unit
			len: len - 1
			zero? len
		]
		either neg? [0 - n][n]
	]

	scan-float: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		error	[int-ptr!]
		return: [float!]
		/local
			cp	 [integer!]
			tail [byte-ptr!]
			cur	 [byte-ptr!]
			s0	 [byte-ptr!]
	][
		cur: as byte-ptr! "0000000000000000000000000000000"		;-- 32 bytes including NUL
		tail: p + (len << (unit >> 1))

		if len > 31 [cur: as byte-ptr! system/stack/allocate (len + 1) >> 2 + 1]
		s0: cur

		until [											;-- convert to ascii string
			cp: string/get-char p unit
			if cp <> as-integer #"'" [					;-- skip #"'"
				if cp = as-integer #"," [cp: as-integer #"."]
				cur/1: as-byte cp
				cur: cur + 1
			]
			p: p + unit
			p = tail
		]
		cur/1: #"^@"									;-- replace the byte with null so to-float can use it as end of input
		string/to-float s0 len error
	]

	scan-tuple: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		error	[int-ptr!]
		slot	[red-value!]
		/local
			c	 [integer!]
			n	 [integer!]
			m	 [integer!]
			size [integer!]
			tp	 [byte-ptr!]
	][
		tp: (as byte-ptr! slot) + 4
		n: 0
		size: 0
		
		loop len [
			c: string/get-char p unit
			either c = as-integer #"." [
				size: size + 1
				if any [n < 0 n > 255 size > 12][error/value: -1 exit]
				tp/size: as byte! n
				n: 0
			][
				m: n * 10
				if system/cpu/overflow? [error/value: -1 exit]
				n: m
				m: n + c - #"0"
				if system/cpu/overflow? [error/value: -1 exit]
				n: m
			]
			p: p + unit
		]
		size: size + 1									;-- last number
		tp/size: as byte! n
		slot/header: TYPE_TUPLE or (size << 19)
	]

]