REBOL [
	Title:   "Red Lexical Scanner"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

lexer: context [
	verbose: 0
	
	stack: 	[]										;-- nested blocks stack
	line: 	1										;-- source code lines counter
	lines:	[]										;-- offsets of newlines marker in current block
	count?: yes										;-- if TRUE, lines counter is enabled
	pos:	none									;-- source input position (error reporting)
	start:	none
	_end:	none
	value:	none
	blk: 	none
	s: e:	none
	fail:	none
	
	throw-error: func [msg [block! string!]][
		print rejoin [
			"*** Syntax Error: " uppercase/part reform msg 1
			"^/*** line: " line
			"^/*** at: " mold copy/part pos 40
		]
		halt
	]
	
	push: func [value][insert/only tail last stack :value]

	add-line-markers: func [blk [block!]][
		foreach pos lines [new-line pos yes]
		clear lines
	]
	
	load-integer: func [s [string!]][
		unless attempt [s: to integer! s][
			throw-error "invalid 32-bit integer"
		]
		s
	]
	
	;--- Parsing rules ---
	
	digit: charset "0123465798"
	
	;-- UTF-8 encoding rules from: http://tools.ietf.org/html/rfc3629#section-4
	UTF-8-BOM: #{EFBBBF}
	ws-ASCII: charset " ^-^M"						;-- ASCII common whitespaces
	ws-U+2k: charset [#"^(80)" - #"^(8A)"]			;-- Unicode spaces in the U+2000-U+200A range
	
	UTF8-tail: charset [#"^(80)" - #"^(BF)"]
		
	UTF8-1: charset [#"^(00)" - #"^(7F)"]
	
	UTF8-2: reduce [
		charset [#"^(C2)" - #"^(DF)"]
		UTF8-tail
	]
	
	UTF8-3: reduce [
		#{E0} charset [#"^(A0)" - #"^(BF)"] UTF8-tail
		'| charset [#"^(E1)" - #"^(EC)"] 2 UTF8-tail
		'| #{ED} charset [#"^(80)" - #"^(9F)"] UTF8-tail
		'| charset [#"^(EE)" - #"^(EF)"] 2 UTF8-tail
	]
	
	UTF8-4: reduce [
		#{F0} charset [#"^(90)" - #"^(BF)"] 2 UTF8-tail
		'| charset [#"^(F1)" - #"^(F3)"] 3 UTF8-tail
		'| #{F4} charset [#"^(80)" - #"^(8F)"] 2 UTF8-tail
	]
	
	UTF8-char: [pos: UTF8-1 | UTF8-2 | UTF8-3 | UTF8-4]
	
	not-word-char: charset {/\^,'[](){}"#%$@:;}
	not-file-char: charset {[](){}"%@:;}
	not-str-char:  charset {"}
	not-mstr-char: charset "}"
	stop: none
	
	UTF8-ws-filtered-char: [
		[
			pos: [stop | (count?: no) ws (count?: yes)] :pos (fail: [end skip])
			| UTF8-char _end: (fail: none)
		]
		fail
	]
	
	UTF8-filtered-char: [
		[pos: stop :pos (fail: [end skip]) | UTF8-char _end: (fail: none)]
		fail
	]
	
	;-- Whitespaces list from: http://en.wikipedia.org/wiki/Whitespace_character
	ws: [
		pos: #"^/" (
			if count? [
				line: line + 1 
				append/only lines tail last stack
			]
		)
		| ws-ASCII									;-- only the common whitespaces are matched
		| #{C2} [
			#{85}									;-- U+0085 (Newline)
			| #{A0}									;-- U+00A0 (No-break space)
		]
		| #{E1} [
			#{9A80}									;-- U+1680 (Ogham space mark)
			| #{A08E}								;-- U+180E (Mongolian vowel separator)
		]
		| #{E2} [
			#{80} [
				ws-U+2k								;-- U+2000-U+200A range
				| #{A8}								;-- U+2028 (Line separator)
				| #{A9}								;-- U+2029 (Paragraph separator)
				| #{AF}								;-- U+202F (Narrow no-break space)
			]
			| #{819F}								;-- U+205F (Medium mathematical space)
		]
		| #{E38080}									;-- U+3000 (Ideographic space)
	]
	
	any-ws: [pos: any ws]
	
	
	word-rule: [
		(stop: not-word-char)
		start: some UTF8-ws-filtered-char _end:
	]
	
	get-word-rule: [#":" word-rule]
		
	lit-word-rule: [#"'" word-rule]
	
	refinement-rule: [#"/" word-rule]
	
	integer-rule: [digit any [digit | #"'" digit] _end:]
		
	block-rule: [
		#"[" (append/only stack make block! 1)
		any-expression
		#"]" (		
			value: last stack
			remove back tail stack
			push value
		)
	]
	
	paren-rule: [
		#"(" (append/only stack make paren! 1)
		any-expression
		#")" (		
			value: last stack
			remove back tail stack
			push value
		)]
		
	char-rule: []
	
	encoded-char: [
	
	]
	
	string-rule: [
		  {"} start: (stop: not-str-char)
		  	;any [UTF8-filtered-char | encoded-char]
		  	any UTF8-filtered-char
		  _end: {"}
		| "{" start: (stop: not-mstr-char)		;@@ need to count LFs
			;any [UTF8-filtered-char | encoded-char]
			any UTF8-filtered-char
		_end: "}"
	]
	
	binary-rule: []
	
	file-rule: [
		#"%" (stop: not-file-char)
		start: some UTF8-ws-filtered-char _end:
	]
	
	lit-value-rule: []
	
	line-comment-rule: [
	
	]
	
	multiline-comment-rule: [
		
	]

	expression: [
		pos: (_end: none) start: [
			integer-rule	  (push load-integer   copy/part start _end)
			| word-rule [
				#":" 		  (push to set-word!   copy/part start _end)
				| none 		  (push to word! 	   copy/part start _end)
			]
			| get-word-rule	  (push to get-word!   copy/part start _end)
			| lit-word-rule	  (push to lit-word!   copy/part start _end)
			| refinement-rule (push to refinement! copy/part start _end)
			;| char-rule
			| block-rule
			| paren-rule
			| string-rule	  (push as-string      copy/part start _end)
			;| binary-rule
			| file-rule		  (push to file!	   copy/part start _end)
			;| lit-value-rule
		]
	]
	
	any-expression: [pos: any [expression | ws]]

	header: [any-ws pos: "Red" any-ws block-rule]

	program: [pos: opt UTF-8-BOM header any-expression]
	
	run: func [src [string! binary!]][
		append/only stack make block! 1

		unless parse/all/case src program [
			throw-error "invalid Red data"
		]
		
		add-line-markers stack/1
		also stack/1 clear stack
	]
]