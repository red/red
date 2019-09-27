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
	
	#enum errors! [
		LEX_ERR_STRING: 1
		
		LEX_ERROR										;-- keep it last
	]
	
	state!: alias struct! [
		parent   [red-block!]							;-- any-block! accepted
		buffer	 [red-value!]							;-- special buffer for hatching any-blocks
		buf-head [red-value!]
		buf-tail [red-value!]
		head     [byte-ptr!]
		tail     [byte-ptr!]
		pos      [byte-ptr!]
		err	     [integer!]
	]
	
	scanner!: alias function! [state [state!] return: [byte-ptr!]]


	scan-string: func [state [state!] return: [byte-ptr!]
		/local
			p [byte-ptr!]
			e [byte-ptr!]
			c [byte!]
	][
		p: state/pos
		e: state/tail
		while [c: p/value all [p < e c <> #"^""]][
			either c = #"^^" [p: p + 2][
				if c = #"^/" [state/pos: p throw LEX_ERR_STRING]
				p: p + 1
			]
		]
		
		e: p
		p: state/pos
		;decode/converte the string
		
		p
	]

	scan-alt-string: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-block: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-paren: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	scan-paren-close: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-comment: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-file: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	scan-refinement: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-money: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-lesser: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]

	scan-lit: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	scan-get: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	scan-sharp: func [state [state!] return: [byte-ptr!]
	;	/local
	][
		null
	]
	
	#enum lexer-categories! [
		LEX_EOF
		LEX_BLANK
		LEX_COMMA
		LEX_COLON
		LEX_NUMBER
		LEX_WORD
	]
	
	lex-table-template: [
	;--- Code ------- 1st char ------------ Nth char ---
		#"^(00)"							LEX_EOF
		#"^(01)"							LEX_NO_OP
		#"^(02)"							LEX_NO_OP
		#"^(03)"							LEX_NO_OP
		#"^(04)"							LEX_NO_OP
		#"^(05)"							LEX_NO_OP
		#"^(06)"							LEX_NO_OP
		#"^(07)"							LEX_NO_OP
		#"^(08)"							LEX_NO_OP
		#"^(09)"							LEX_BLANK	;-- TAB
		#"^(0A)"							LEX_BLANK	;-- LF
		#"^(0B)"							LEX_NO_OP   
		#"^(0C)"							LEX_NO_OP
		#"^(0D)"							LEX_BLANK	;-- CR
		#"^(0E)"							LEX_NO_OP
		#"^(0F)"							LEX_NO_OP		
		#"^(10)"							LEX_NO_OP
		#"^(11)"							LEX_NO_OP		
		#"^(12)"							LEX_NO_OP
		#"^(13)"							LEX_NO_OP		
		#"^(14)"							LEX_NO_OP		
		#"^(15)"							LEX_NO_OP
		#"^(16)"							LEX_NO_OP		
		#"^(17)"							LEX_NO_OP		
		#"^(18)"							LEX_NO_OP
		#"^(19)"							LEX_NO_OP
		#"^(1A)"							LEX_NO_OP
		#"^(1B)"							LEX_NO_OP
		#"^(1C)"							LEX_NO_OP		
		#"^(1D)"							LEX_NO_OP
		#"^(1E)"							LEX_NO_OP
		#"^(1F)"							LEX_NO_OP
		#"^(10)"							LEX_NO_OP		
		
		#" "								LEX_BLANK	;-- space
		#"!"								LEX_WORD
		#"^""			:scan-string
		#"#"			:scan-sharp
		#"$"			:scan-money
		#"%"			:scan-file
		#"&"								LEX_WORD
		#"'"			:scan-lit
		#"("			:scan-paren
		#")"			:scan-paren-close
		#"*"								LEX_WORD
		#"+"								LEX_WORD
		#","								LEX_COMMA
		#"-"								LEX_WORD
		#"."								LEX_WORD
		#"/"			:scan-refinement
		
		#"0"								LEX_NUMBER
		#"1"								LEX_NUMBER
		#"2"								LEX_NUMBER
		#"3"								LEX_NUMBER
		#"4"								LEX_NUMBER
		#"5"								LEX_NUMBER
		#"6"								LEX_NUMBER
		#"7"								LEX_NUMBER
		#"8"								LEX_NUMBER
		#"9"								LEX_NUMBER
		
		#":"			:scan-get
		#";"			:scan-comment
		#"<"			:scan-lesser
		#"="								LEX_WORD
		#">"								LEX_WORD
		#"?"								LEX_WORD
		
		
		
		#"{"			:scan-alt-string
		#"["			:scan-block
		
		
		
		;[#"0" - #"9"] 	:scan-digit
		;else			:scan-word
	]
	
	lex-table: as int-ptr! 0							;-- table created at run-time

	scan-tokens: func [
		state [state!]
		/local
			parent	[red-block!]
			p		[byte-ptr!]
			e		[byte-ptr!]
			cp		[integer!]
			res		[integer!]
			s		[series!]
			do-scan [scanner!]
	][
		parent: state/parent
		s:  GET_BUFFER(parent)
		p:  state/pos
		e:  state/tail
		cp: 0

		while [p < e][
			while [										;-- skip all head blanks
				cp: as-integer p/value
				lex-table/cp = LEX_BLANK
			][p: p + 1]
			
			res: lex-table/cp
			either res < 1000 [
				p: p + 1
			][
				do-scan: as scanner! res
				state/pos: p + 1
				p: do-scan state
			]
		]
		state/pos: p
	]
	
	scan: func [
		dst [red-block!]								;-- destination block
		src [byte-ptr!]									;-- UTF-8 buffer
		len [integer!]									;-- buffer size in bytes
		/local
			stack [red-block!]
			state [state! value]
	][
		state/parent: block/make-in dst 100
		state/buffer: as cell! alloc-big 1000 * size? cell!
		state/buf-head: state/buffer
		state/buf-tail: state/buffer + 1000
		state/head: src
		state/tail: src + len
		state/pos:  src
		state/err:  0
		
		catch LEX_ERROR [scan-tokens state]
		if system/thrown > 0 [
			0 ; error handling
		]
	]
	
	init: func [][
	
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