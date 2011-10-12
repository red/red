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
	end:	none
	value:	none
	blk: 	none
	s: e:	none
	fail:	none
	
	
	push: func [value][append/only last stack :value]

	add-line-markers: func [blk [block!]][
		foreach pos lines [new-line pos yes]
		clear lines
	]
	
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
	
	not-word-char: charset {/,'[](){}"#%$@:}
	
	UTF8-word-char: [
		[
			pos: [not-word-char | (count?: no) ws (count?: yes) ] :pos (fail: [end skip])
			| UTF8-char end: (fail: none)
		]
		fail
	]
	
	;-- Whitespaces list from: http://en.wikipedia.org/wiki/Whitespace_character
	ws: [
		#"^/" (
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
		| #{E280} [
			ws-U+2k									;-- U+2000-U+200A range
			| #{A8}									;-- U+2028 (Line separator)
			| #{A9}									;-- U+2029 (Paragraph separator)
			| #{AF}									;-- U+202F (Narrow no-break space)
		]
		| #{E2819F}									;-- U+205F (Medium mathematical space)
		| #{E38080}									;-- U+3000 (Ideographic space)
	]
	
	any-ws: [pos: any ws]
	
	
	word-rule: [start: some UTF8-word-char end:]
	
	get-word-rule: [#":" word-rule]
		
	lit-word-rule: [#"'" word-rule]
	
	refinement-rule: [#"/" word-rule]
	
	integer-rule: []
	
	char-rule: []
	
	block-rule: []
	
	paren-rule: []
	
	string-rule: []
	
	binary-rule: []
	
	file-rule: []
	
	lit-value-rule: []
	
	block-rule: [
		#"[" (append/only stack make block! 1)
		any expression 
		#"]" (		
			blk: last stack
			remove back tail stack
			push blk
		)
	]

	expression: [
		any-ws 
		pos: (end: none) start: [
			word-rule [
				#":" 		  (push to set-word!   copy/part start end)
				| none 		  (push to word! 	   copy/part start end)
			]
			| get-word-rule	  (push to get-word!   copy/part start end)
			| lit-word-rule	  (push to lit-word!   copy/part start end)
			| refinement-rule (push to refinement! copy/part start end)
			;| integer-rule
			;| char-rule
			| block-rule
			;| paren-rule
			;| string-rule
			;| binary-rule
			;| file-rule
			;| lit-value-rule
		]
		any-ws
	]

	header: [any-ws pos: "Red" any-ws block-rule]

	program: [pos: opt UTF-8-BOM header any expression]
	
	run: func [src [string! binary!]][
		append/only stack make block! 1
		
		unless parse/all src program [		
			print rejoin [
				"*** Loading Error: (line " line ") at: " copy/part pos 40
			]
		]
		
		add-line-markers blk
		also stack/1 clear stack
	]
]