REBOL [
	Title:   "Red Lexical Scanner"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

lexer: context [
	verbose: 0
	
	stack: 	[[]]									;-- nested blocks stack
	pos:	none									;-- source input position (error reporting)
	value:	none
	blk: 	none
	
	UTF-8-BOM: #{EFBBBF}
	ws-ASCII: charset " ^-^/^M"						;-- ASCII common whitespaces
	ws-U+2k: charset [#"^(80)" - #"^(8A)"]			;-- Unicode spaces in the U+2000-U+200A range
	
	;-- Whitespaces list from: http://en.wikipedia.org/wiki/Whitespace_character
	ws: [
		ws-ASCII									;-- only the 4 common whitespaces are matched
		| #{C2} [
			#{85}									;-- U+0085 (Newline)
			| #{A0}									;-- U+00A0 (No-break space)
		]
		| #{E1} [
			#{9A80}									;-- U+1680 (Ogham space mark)
			| #{A08E}								;-- U+180E (Mongolian vowel separator)
		]
		| #{E280} [
			ws-U+2k									;-- U+2000-U+200A range
			| #{A8}									;-- U+2028 (Line separator)
			| #{A9}									;-- U+2029 (Paragraph separator)
			| #{AF}									;-- U+202F (Narrow no-break space)
		]
		| #{E2819F}									;-- U+205F (Medium mathematical space)
		| #{E38080}									;-- U+3000 (Ideographic space)
	]

	push: func [value][append/only last stack value]
	
	word-rule: []
	
	get-word-rule: []
	
	set-word-rule: []
	
	lit-word-rule: []
	
	refinement-rule: []
	
	integer-rule: []
	
	char-rule: []
	
	block-rule: []
	
	paren-rule: []
	
	string-rule: []
	
	binary-rule: []
	
	file-rule: []
	
	lit-value-rule: []
	
	block-rule: [
		pos: #"[" (push make block! 1)
		pos: expression 
		#"]" (	
			blk: last stack
			remove back tail stack
			push blk
		)
	]

	expression: [
		any pos: ws
		pos: copy value [
			word-rule
			| get-word-rule
			| set-word-rule
			| lit-word-rule
			| refinement-rule
			| integer-rule
			| char-rule
			| block-rule
			| paren-rule
			| string-rule
			| binary-rule
			| file-rule
			| lit-value-rule
		]
	]

	header: [any pos: ws pos: "Red" pos: any ws block-rule]

	program: [pos: opt UTF-8-BOM header any expression]
	
	run: func [src [string! binary!]][
		unless parse src program [
		
		]
		stack/1
	]
]