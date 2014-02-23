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

trans-pop: function [stack [block!]][
	value: last stack
	remove back tail stack
	append/only last stack value
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
		multiline-string string-rule cnt trans-string new base c
][
	cs:		[- - - - - - - - - - - - -]
	stack:	clear []
	count?:	yes											;-- if TRUE, lines counter is enabled

	
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
	]
	set [
		digit hexa hexa-char not-word-char not-word-1st
		not-file-char not-str-char not-mstr-char caret-char
		non-printable-char integer-end ws-ASCII ws-U+2k
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
		{#"} (type: char!) [
			s: escaped-char
			| copy value UTF8-printable (value: as-binary value)
			| #"^-" (value: s/1)
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
			| integer-rule	  (append last stack trans-integer s e)
			;| hexa-rule		  (stack/push decode-hexa	 copy/part s e)
			;| word-rule		  (stack/push to type value)
			;| lit-word-rule	  (stack/push to type value)
			;| get-word-rule	  (stack/push to type value)
			;| refinement-rule (stack/push to refinement! copy/part s e)
			;| slash-rule	  (stack/push to word! 	   	 copy/part s e)
			;| issue-rule	  (stack/push to issue!	   	 copy/part s e)
			;| file-rule		  (stack/push load-file		 copy/part s e)
			;| char-rule		  (stack/push decode-UTF8-char value)
			| block-rule
			| paren-rule
			| string-rule	  (append last stack do trans-string)
			;| binary-rule	  (stack/push load-binary s e)
		]
	]
	
	any-value: [pos: any [literal-value | ws]]
	
	parse/case src [any-value opt wrong-delimiters]
	stack/1
]