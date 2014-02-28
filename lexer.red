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
		digit hexa hexa-char not-word-char not-word-1st
		not-file-char not-str-char not-mstr-char caret-char
		non-printable-char integer-end block-rule literal-value
		any-value escaped-char char-rule line-string nested-curly-braces
		multiline-string string-rule cnt trans-string new base c ws
][
	cs:		[- - - - - - - - - - - - - -]				;-- memoized bitsets
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
	
	if cs/1 = '- [
		cs/1:  charset "0123465798"						;-- digit
		cs/2:  union cs/1 charset "ABCDEF"				;-- hexa
		cs/3:  union cs/2 charset "abcdef"				;-- hexa-char	
		cs/4:  charset {/\^^,[](){}"#%$@:;}				;-- not-word-char
		cs/5:  union union cs/4 cs/1 charset {'}		;-- not-word-1st
		cs/6:  charset {[](){}"%@:;}					;-- not-file-char
		cs/7:  #"^""									;-- not-str-char
		cs/8:  #"}"										;-- not-mstr-char
		cs/9:  charset [#"^(40)" - #"^(5F)"]			;-- caret-char
		cs/10: charset [#"^(00)" - #"^(1F)"]			;-- non-printable-char
		cs/11: charset {^{"[]);}						;-- integer-end
		cs/12: charset " ^-^M"							;-- ws-ASCII, ASCII common whitespaces
		cs/13: charset [#"^(80)" - #"^(8A)"]			;-- ws-U+2k, Unicode spaces in the U+2000-U+200A range
		cs/14: charset [#"^(00)" - #"^(1F)"] 			;-- ASCII control characters

	]
	set [
		digit hexa hexa-char not-word-char not-word-1st
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
		#"}"
	]
	
	multiline-string: [#"{" s: nested-curly-braces]
	
	string-rule: [line-string | multiline-string]
	
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

	hexa-rule: [2 8 hexa e: #"h" (type: integer!)]
	
	integer-number-rule: [
		opt [#"-" | #"+"] digit any [digit | #"'" digit] e:
	]
	
	integer-rule: [
		integer-number-rule
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
	
	comment-rule: [#";" [to lf | to end]]
	
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
			;| multiline-comment-rule
			;| escaped-rule    (stack/push value)
			| integer-rule		(append last stack trans-integer s e)
			;| hexa-rule		  (stack/push decode-hexa	 copy/part s e)
			| word-rule
			| lit-word-rule
			| get-word-rule
			| slash-rule		(trans-word last stack copy/part s e word!)
			| refinement-rule
			;| file-rule		  (stack/push load-file		 copy/part s e)
			| char-rule			(append last stack value)
			| issue-rule
			| block-rule
			| paren-rule
			| string-rule		(append last stack do trans-string)
			;| binary-rule	  (stack/push load-binary s e)
		]
	]
	
	any-value: [pos: any [literal-value | ws]]
	
	parse/case src [any-value opt wrong-delimiters]
	stack/1
]