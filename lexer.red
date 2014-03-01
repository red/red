Red [
	Title:   "Red runtime lexer"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

trans-integer: routine [
	start [string!]
	end	  [string!]
	/local
		c	 [integer!]
		n	 [integer!]
		m	 [integer!]
		len  [integer!]
		p	 [byte-ptr!]
		neg? [logic!]
][
	str:  GET_BUFFER(start)
	unit: GET_UNIT(str)
	p:	  string/rs-head start
	len:  end/head - start/head
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
		c: string/get-char p unit
		
		m: n * 10
		if m < n [SET_RETURN(none-value) exit]			;-- return NONE on overflow
		n: m
		
		m: n + c - #"0"
		if m < n [SET_RETURN(none-value) exit]			;-- return NONE on overflow
		n: m

		p: p + unit
		len: len - 1
		zero? len
	]
	integer/box either neg? [0 - n][n]
]

trans-hexa: routine [
	start	[string!]
	end		[string!]
	return: [integer!]
	/local
		s	  [series!]
		unit  [integer!]
		p	  [byte-ptr!]
		head  [byte-ptr!]
		p4	  [int-ptr!]
		n	  [integer!]
		power [integer!]
		cp	  [byte!]
][
	s: GET_BUFFER(start)
	unit: GET_UNIT(s)
	
	p: (string/rs-head end) - unit
	head: string/rs-head start
	
	n: 0
	power: 0
	while [p >= head][
		cp: switch unit [
			Latin1 [p/value]
			UCS-2  [as-byte ((as-integer p/2) << 8 + p/1)]
			UCS-4  [p4: as int-ptr! p as-byte p4/value]
		]
		if cp <> #"0" [
			case [
				all [#"0" <= cp cp <= #"9"][cp: cp - #"0"]
				all [#"A" <= cp cp <= #"F"][cp: cp - #"A" + 10]
				all [#"a" <= cp cp <= #"f"][cp: cp - #"a" + 10]
			]
			n: n + ((as-integer cp) << power)
		]
		power: power + 4
		p: p - unit
	]
	n
]

trans-decimal: routine [
	start [string!]
	end	  [string!]
	/local
		c	  [integer!]
		value [integer!]
		m	  [integer!]
		len   [integer!]
		p	  [byte-ptr!]
		neg?  [logic!]
		expon [integer!] ;should be decimal!
		frac  [logic!]
		scale [integer!] ;should be decimal!
		;pow10 [deecimal!]
][
	str:  GET_BUFFER(start)
	unit: GET_UNIT(str)
	p:	  string/rs-head start
	len:  end/head - start/head
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
	value: 0
	while [
		c: string/get-char p unit
		all [
			c >= as-integer #"0"
			c <= as-integer #"9"
		]
	][
		m: value * 10
		if m < value [SET_RETURN(none-value) exit]			;-- return NONE on overflow
		value: m
		
		m: value + c - #"0"
		if m < value [SET_RETURN(none-value) exit]			;-- return NONE on overflow
		value: m

		p: p + unit	
		len: len - 1
	]
	
	;Handle numbers after decimal point if there are any
	if c = as-integer #"." [
		p: p + unit	
		len: len - 1
		while [
			c: string/get-char p unit
			all [
				c >= as-integer #"0"
				c <= as-integer #"9"
			]
		][
			;DO NOTHING SO FAR AS I CANNOT DIVIDE PROPERLY YET
			;pow10: 10.0
			;value: value + (c - #"0") / pow10
			;pow10: pow10 * 10.0
			p: p + unit	
			len: len - 1
		]
	]
	
	frac: no
	scale: 1 ;should be 1.0!
	
	if all [
		len > 0
		any [
			c = as-integer #"e"
			c = as-integer #"E"
		]
	][
		expon: 0
		p: p + unit	
		len: len - 1
		
		c: string/get-char p unit
		if any [
			c = as-integer #"+" 
			c = as-integer #"-"
		][
			frac: c = as-integer #"-"
			p: p + unit
			len: len - 1
		]
		until [
			c: string/get-char p unit
			
			m: expon * 10 ;should be 10.0
			if m < expon [SET_RETURN(none-value) exit]			;-- return NONE on overflow
			expon: m
			
			m: expon + c - #"0"
			if m < expon [SET_RETURN(none-value) exit]			;-- return NONE on overflow
			expon: m

			p: p + unit		
			len: len - 1
			zero? len
		]
		;while [expon >= 50] [
		;	scale: scale * 1E50
		;	expon: expon - 50
		;]
		while [expon >= 8] [
			scale: scale * 100000000 ;1E8
			expon: expon - 8
		]
		while [expon > 0] [
			scale: scale * 10 ;10.0
			expon: expon - 1
		]
		value: either frac [
			value / scale
		][	value * scale ]
	]
	
	integer/box either neg? [0 - value][value]
]

trans-push-path: routine [
	stack [block!]
	type  [datatype!]
	/local
		path [red-path!]
][
	path: as red-path! block/make-at as red-block! ALLOC_TAIL(stack) 4
	path/header: switch type/value [
		TYPE_GET_WORD [TYPE_GET_PATH]
		TYPE_LIT_WORD [TYPE_LIT_PATH]
		default [TYPE_PATH]
	]
]

trans-set-path: routine [
	stack [block!]
	/local
		path [red-path!]
][
	path: as red-path! block/pick stack 1 null
	set-type as red-value! path TYPE_SET_PATH
]

trans-word: routine [
	stack [block!]
	src   [string!]
	type  [datatype!]
	/local
		value [red-value!]
][
	value: as red-value! word/push-in (symbol/make-alt src) stack
	set-type value type/value
]

trans-pop: function [stack [block!]][
	value: last stack
	remove back tail stack
	append/only last stack :value
]

transcode: func [
	src		[string!]
	dst		[block! none!]
	return: [block!]
	/local
		cs stack pos s e value line count? wrong-delimiters comment-rule
		digit hexa-upper hexa-lower hexa hexa-char not-word-char not-word-1st
		not-file-char not-str-char not-mstr-char caret-char
		non-printable-char integer-end block-rule literal-value
		any-value escaped-char char-rule line-string nested-curly-braces
		multiline-string string-rule cnt trans-string new base c ws
		trans-file decode-hex decode-2hex hex
][
	cs:		[- - - - - - - - - - - - - - - -]			;-- memoized bitsets
	stack:	clear []
	count?:	yes											;-- if TRUE, lines counter is enabled
	line: 	1
	
	append/only stack any [dst make block! 4]
	
	trans-string: [
		new: make string! (index? e) - index? s
		parse/case copy/part s e [						;@@ add /part option to parse!
			any [
				escaped-char (append new value)
				| set c skip (append new c)
			]
		]
		new
	]
	
	decode-hex: [
		set c [
			digit 			(value: c - #"0")
			| hexa-upper	(value: c - #"A" + 10)
			| hexa-lower	(value: c - #"a" + 10)
			| (print "*** Syntax Error: invalid file hexa encoding") ;@@ temporary hardcoded
		]
	]
	
	decode-2hex: [
		decode-hex (hex: value << 4)
		decode-hex (hex: hex + value)
	]
	
	trans-file: [
		new: make file! (index? e) - index? s
		parse/case copy/part s e [						;@@ add /part option to parse!
			any [
				#"%" decode-2hex (append new hex)
				| set c skip (append new c)
			]
		]
		new
	]
	
	if cs/1 = '- [
		cs/1:  charset "0123465798"						;-- digit
		cs/2:  charset "ABCDEF"							;-- hexa-upper
		cs/3:  charset "abcdef"							;-- hexa-lower
		cs/4:  union cs/1 cs/2							;-- hexa
		cs/5:  union cs/4 cs/3							;-- hexa-char	
		cs/6:  charset {/\^^,[](){}"#%$@:;}				;-- not-word-char
		cs/7:  union union cs/6 cs/1 charset {'}		;-- not-word-1st
		cs/8:  charset {[](){}"%@:;}					;-- not-file-char
		cs/9:  #"^""									;-- not-str-char
		cs/10: #"}"										;-- not-mstr-char
		cs/11: charset [#"^(40)" - #"^(5F)"]			;-- caret-char
		cs/12: charset [#"^(00)" - #"^(1F)"]			;-- non-printable-char
		cs/13: charset {^{"[]);}						;-- integer-end
		cs/14: charset " ^-^M"							;-- ws-ASCII, ASCII common whitespaces
		cs/15: charset [#"^(80)" - #"^(8A)"]			;-- ws-U+2k, Unicode spaces in the U+2000-U+200A range
		cs/16: charset [#"^(00)" - #"^(1F)"] 			;-- ASCII control characters

	]
	set [
		digit hexa-upper hexa-lower hexa hexa-char not-word-char not-word-1st
		not-file-char not-str-char not-mstr-char caret-char
		non-printable-char integer-end ws-ASCII ws-U+2k control-char
	] cs
	
	;-- Whitespaces list from: http://en.wikipedia.org/wiki/Whitespace_character
	ws: [
		pos: #"^/" (
			if count? [
				line: line + 1 
				;append/only lines to block! stack/tail?
			]
		)
		| ws-ASCII										;-- only the common whitespaces are matched
		| #"^(0085)"									;-- U+0085 (Newline)
		| #"^(00A0)"									;-- U+00A0 (No-break space)
		| #"^(1680)"									;-- U+1680 (Ogham space mark)
		| #"^(180E)"									;-- U+180E (Mongolian vowel separator)
		| ws-U+2k										;-- U+2000-U+200A range
		| #"^(2028)"									;-- U+2028 (Line separator)
		| #"^(2029)"									;-- U+2029 (Paragraph separator)
		| #"^(202F)"									;-- U+202F (Narrow no-break space)
		| #"^(205F)"									;-- U+205F (Medium mathematical space)
		| #"^(3000)"									;-- U+3000 (Ideographic space)
	]

	newline-char: [
		#"^/"
		| #"^(0085)"									;-- U+0085 (Newline)
		| #"^(2028)"									;-- U+2028 (Line separator)
		| #"^(2029)"									;-- U+2029 (Paragraph separator)
	]

	counted-newline: [pos: #"^/" (line: line + 1)]

	ws-no-count: [(count?: no) ws (count?: yes)]

	escaped-char: [
		"^^(" [
			[										;-- special case first
				"null" 	 (value: #"^(00)")
				| "back" (value: #"^(08)")
				| "tab"  (value: #"^(09)")
				| "line" (value: #"^(0A)")
				| "page" (value: #"^(0C)")
				| "esc"  (value: #"^(1B)")
				| "del"	 (value: #"^(7F)")
			]
			| s: [2 6 hexa-char] e: (				;-- Unicode values allowed up to 10FFFFh
				value: encode-UTF8-char s e
			)
		] #")"
		| #"^^" [
			[
				#"/" 	(value: #"^/")
				| #"-"	(value: #"^-")
				| #"?" 	(value: #"^(del)")			;@@FIXME
				| #"^^" (value: #"^^")				;-- caret escaping case
				| #"{"	(value: #"{")
				| #"}"	(value: #"}")
				| #"^""	(value: #"^"")
			]
			| s: caret-char (value: s/1 - 64)
		]
	]

	char-rule: [
		{#"} s: [
			 escaped-char
			| ahead [non-printable-char | not-str-char] break
			| skip (value: s/1)
		] {"}
	]
	
	line-string: [
		{"} s: any [
			{^^"} e:
			| ahead [#"^"" | newline-char] break
			| skip e:
		]
		e: {"}
	]
	
	nested-curly-braces: [
		(cnt: 1)
		any [
			counted-newline 
			| "^^{" | "^^}"
			| #"{" (cnt: cnt + 1)
			| e: #"}" if (zero? cnt: cnt - 1) fail
			| skip
		]
	]
	
	multiline-string: [#"{" s: nested-curly-braces]
	
	string-rule: [line-string | multiline-string]
	
	file-rule: [
		#"%" s: any [ahead [not-file-char | ws-no-count] break | skip] e:
	]
	
	symbol-rule: [
		some [ahead [not-word-char | ws-no-count | control-char] break | skip] e:
	]

	begin-symbol-rule: [								;-- 1st char in symbols is restricted
		[not ahead [not-word-1st | ws-no-count | control-char]]
		symbol-rule
	]

	path-rule: [
		ahead slash (									;-- path detection barrier
			trans-push-path stack type					;-- create empty path
			trans-word last stack copy/part s e type	;-- push 1st path element
		)
		some [
			slash
			s: [
				integer-number-rule			(append last stack trans-integer s e)
				| begin-symbol-rule			(trans-word last stack copy/part s e word!)
				| paren-rule
				| #":" s: begin-symbol-rule	(trans-word last stack copy/part s e get-word!)
				;@@ add more datatypes here
			]
			opt [#":" (trans-set-path back tail stack)]
		] (trans-pop stack)
	]

	word-rule: 	[
		s: begin-symbol-rule (type: word!) [
			path-rule 									;-- path matched
			| opt [#":" (type: set-word!)]
			  (trans-word last stack copy/part s e type) ;-- word or set-word matched
		] 
	]

	get-word-rule: [
		#":" (type: get-word!) s: begin-symbol-rule [
			path-rule (type: get-path!)
			| (trans-word last stack copy/part s e type) ;-- get-word matched
		]
	]

	lit-word-rule: [
		#"'" (type: lit-word!) s: begin-symbol-rule [
			path-rule (type: lit-path!)					;-- path matched
			| (trans-word last stack copy/part s e type) ;-- lit-word matched
		]
	]

	issue-rule: [
		#"#" (type: issue!) s: symbol-rule
		(trans-word last stack copy/part s e type)
	]

	refinement-rule: [
		slash (type: refinement!) s: symbol-rule
		(trans-word last stack copy/part s e type)
	]

	slash-rule: [s: [slash opt slash] e:]

	hexa-rule: [2 8 hexa e: #"h"]
	
	integer-number-rule: [
		opt [#"-" | #"+"] digit any [digit | #"'" digit] e:
	]
	
	integer-rule: [
		integer-number-rule
		ahead [integer-end | ws-no-count | end]
	]
	
	decimal-number-rule: [
		opt [#"-" | #"+"] [
			;for numbers like: 1.0 -1.e2 1.0e-2
			[
				  any  digit #"." some digit
				| some digit #"." any  digit
			]
			opt [[#"e" | #"E"] opt [#"-" | #"+"] some digit]
			|
			;for numbers like: 1e2
			some digit
			[#"e" | #"E"] opt [#"-" | #"+"] some digit
		]
		e:
	]
	
	decimal-rule: [
		decimal-number-rule
		ahead [integer-end | ws-no-count | end]
	]
	
	block-rule: [
		#"[" (append/only stack make block! 4)
		any-value 
		#"]" (trans-pop stack)
	]
	
	paren-rule: [
		#"(" (append/only stack make paren! 4)
		any-value 
		#")" (trans-pop stack)
	]
	
	escaped-rule: [
		"#[" pos: any ws [
			  "true"  			(value: true)
			| "false" 			(value: false)
			| [
				"none!"			(value: none!)
				| "logic!"		(value: logic!)
				| "block!"		(value: block!)
				| "integer!"	(value: integer!)
				| "word!"		(value: word!)
				| "set-word!"	(value: set-word!)
				| "get-word!"	(value: get-word!)
				| "lit-word!"	(value: lit-word!)
				| "refinement!"	(value: refinement!)
				;| "binary!"	(value: binary!)
				| "string!"		(value: string!)
				| "char!"		(value: char!)
				| "bitset!"		(value: bitset!)
				| "path!"		(value: path!)
				| "set-path!"	(value: set-path!)
				| "lit-path!"	(value: lit-path!)
				| "get-path!"	(value: get-path!)
				| "native!"		(value: native!)
				| "action!"		(value: action!)
				| "op!"			(value: op!)
				| "issue!"		(value: issue!)
				| "paren!"		(value: paren!)
				| "function!"	(value: function!)
				| "routine!"	(value: routine!)
			]
			| "none" 			(value: none)
		] pos: any ws #"]"
	]
	
	comment-rule: [#";" [to lf | to end]]
	
	multiline-comment-rule: [
		"comment" any ws [
			#"{" nested-curly-braces
			| (print "*** Syntax Error: multiline string expected after COMMENT") ;@@ temporary
		]
	]
	
	wrong-delimiters: [
		pos: [
			  #"]" (value: #"[") | #")" (value: #"(")
			| #"[" (value: #"]") | #"(" (value: #")")
		] :pos
		(print ["missing matching" value])
	]
	
	literal-value: [
		pos: (e: none) s: [
			comment-rule
			| multiline-comment-rule
			| escaped-rule		(append last stack value)
			| integer-rule		(append last stack trans-integer s e)
			| decimal-rule		(append last stack trans-decimal s e)
			| hexa-rule			(append last stack trans-hexa s e)
			| word-rule
			| lit-word-rule
			| get-word-rule
			| slash-rule		(trans-word last stack copy/part s e word!)
			| refinement-rule
			| file-rule			(append last stack do trans-file)
			| char-rule			(append last stack value)
			| issue-rule
			| block-rule
			| paren-rule
			| string-rule		(append last stack do trans-string)
			;| binary-rule	  	(stack/push load-binary s e)
		]
	]
	
	any-value: [pos: any [literal-value | ws]]
	
	unless parse/case src [any-value opt wrong-delimiters][
		print ["*** Syntax Error: invalid Red value at:" copy/part pos 20]
	]
	stack/1
]