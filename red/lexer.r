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
	line: 	none									;-- source code lines counter
	lines:	[]										;-- offsets of newlines marker in current block
	count?: yes										;-- if TRUE, lines counter is enabled
	pos:	none									;-- source input position (error reporting)
	start:	none
	_end:	none
	value:	none
	blk: 	none
	s: e:	none
	fail?:	none
	type:	none
	
	;====== Parsing rules ======
	
	digit: charset "0123465798"
	hexa:  union digit charset "ABCDEF" 
	
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
	
	not-word-char:  charset {/\^^,'[](){}"#%$@:;}
	not-word-1st:	union not-word-char digit
	not-file-char:  charset {[](){}"%@:;}
	not-str-char:   charset {"}
	not-mstr-char:  charset "}"
	caret-char:	    charset [#"@" - #"_"]
	printable-char: charset [#"^(20)" - #"^(7E)"]
	char-char:		exclude printable-char charset {"^^}
	integer-end:	charset {^{"])}
	stop: 		    none
	
	UTF8-ws-filtered-char: [
		[
			pos: [stop | ws-no-count] :pos (fail?: [end skip])
			| UTF8-char _end: (fail?: none)
		]
		fail?
	]
	
	UTF8-nl-filtered-char: [
		[
			pos: [stop | newline-char] :pos (fail?: [end skip])
			| UTF8-char _end: (fail?: none)
		]
		fail?
	]
	
	UTF8-filtered-char: [
		[pos: stop :pos (fail?: [end skip]) | UTF8-char _end: (fail?: none)]
		fail?
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
	
	newline-char: [
		#"^/"
		| #{C285}									;-- U+0085 (Newline)
		| #{E280} [
			#{A8}									;-- U+2028 (Line separator)
			| #{A9}									;-- U+2029 (Paragraph separator)
		]
	]
	
	ws-no-count: [(count?: no) ws (count?: yes)]
	
	any-ws: [pos: any ws]
	
	symbol-rule: [
		(stop: not-word-char) some UTF8-ws-filtered-char 
		_end:
	]
	
	begin-symbol-rule: [
		(stop: not-word-1st) UTF8-ws-filtered-char	;-- 1st char is restricted
		opt symbol-rule
	]
	
	path-rule: [some [slash [begin-symbol-rule | paren-rule]] _end:]
	
	word-rule: [
		(type: word!) start: begin-symbol-rule 
		opt [path-rule (type: path!)] 
		opt [#":" (type: either type = word! [set-word!][set-path!])]
	]
	
	get-word-rule: 	 [#":" (type: get-word!) start: begin-symbol-rule]
	
	lit-word-rule: 	 [
		#"'" (type: lit-word!) start: begin-symbol-rule
		opt [path-rule (type: probe lit-path!)]
	]
	
	issue-rule: 	 [#"#" start: symbol-rule]
	
	refinement-rule: [slash start: symbol-rule]
	
	slash-rule: 	 [start: [slash opt slash] _end:]
		
	integer-rule: [
		opt #"-" digit any [digit | #"'" digit] _end:
		pos: [										;-- protection rule from typo with sticky words
			[integer-end | ws-no-count] (fail?: none)
			| skip (fail?: [end skip]) 
		] :pos 
		fail?
	]
		
	block-rule: [
		#"[" (append/only stack make block! 1)
		any-red-value
		#"]" (		
			value: last stack
			remove back tail stack
		)
	]
	
	paren-rule: [
		#"(" (append/only stack make paren! 1)
		any-red-value
		#")" (		
			value: last stack
			remove back tail stack
		)
	]
	
	escaped-char: [
		"^^(" [
			s: [6 hexa | 4 hexa | 2 hexa] e: (		;-- Unicode values allowed up to 10FFFFh
				value: encode-UTF8 s e
			)
			| [
				"null" 	 (value: #"^(00)")
				| "back" (value: #"^(08)")
				| "tab"  (value: #"^(09)")
				| "line" (value: #"^(0A)")
				| "page" (value: #"^(0C)")
				| "esc"  (value: #"^(1B)")
				| "del"	 (value: #"^(7F)")
			] 
		] #")"
		| #"^^" [
			s: caret-char (value: to char! s/1 - #"@") 
			| [
				#"/" 	(value: #"^/")
				| #"-"	(value: #"^-")
				| #"?" 	(value: #"^(del)")
			]
		]
	]
	
	char-rule: [
		{#"} (fail?: none) [
			start: char-char (value: to char! start/1)	;-- allowed UTF-1 chars
			| newline-char (fail?: [end skip])			;-- fail rule
			| copy value [UTF8-2 | UTF8-3 | UTF8-4]		;-- allowed Unicode chars
			| escaped-char
		] fail? {"}
	]
	
	line-string: [
		{"} start: (stop: not-str-char) any UTF8-nl-filtered-char _end: {"}
	]
	
	multiline-string: [
		#"{" start: (stop: not-mstr-char) any [
			pos: #"^/" (line: line + 1) | "^^}" | UTF8-filtered-char 
		] _end: #"}"
	]
	
	string-rule: [line-string | multiline-string]
	
	binary-rule: [
		"#{" start: any [
			pos: #"^/" (line: line + 1) | 2 hexa | ws | comment-rule
		] _end: #"}"
	]
	
	file-rule: [
		#"%" (stop: not-file-char)
		start: some UTF8-ws-filtered-char _end:
	]
	
	lit-value-rule: []
	
	comment-rule: [#";" to #"^/"]
	
	multiline-comment-rule: [
		"comment" any-ws #"{" (stop: not-mstr-char) any [
			#"^/" (line: line + 1) | "^^}" | UTF8-filtered-char
		] #"}"
	]

	Red-value: [
		pos: (_end: none) start: [
			integer-rule	  (push load-integer   copy/part start _end)
			| comment-rule
			| multiline-comment-rule
			| word-rule		  (push to type		   copy/part start _end)
			| lit-word-rule	  (push to type		   copy/part start _end)
			| get-word-rule	  (push to get-word!   copy/part start _end)
			| refinement-rule (push to refinement! copy/part start _end)
			| slash-rule	  (push to word! 	   copy/part start _end)
			| char-rule		  (push value)
			| issue-rule	  (push to issue!	   copy/part start _end)
			| block-rule	  (push value)
			| paren-rule	  (push value)
			| string-rule	  (push load-string start _end)
			| binary-rule	  (push load-binary start _end)
			| file-rule		  (push to file!	   copy/part start _end)
			;| lit-value-rule
		]
	]
	
	any-Red-value: [pos: any [Red-value | ws]]

	header: [any-ws pos: "Red" any-ws block-rule]

	program: [pos: opt UTF-8-BOM header any-Red-value]
	
	
	;====== Helper functions ======
	
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
	
	encode-UTF8: func [s [string!] e [string!]][
		copy/part s e								;@@ placeholder
	]

	load-integer: func [s [string!]][
		unless attempt [s: to integer! s][
			throw-error "invalid 32-bit integer"
		]
		s
	]

	load-string: func [s [string!] e [string!] /local new value][
		new: make string! offset? s e				;-- allocated size close to final size

		parse/all/case s [
			some [
				escaped-char (insert tail new value)
				| s: UTF8-filtered-char e: (		;-- already set to right filter	
					insert/part tail new s e
				)
			]										;-- exit on matching " or }
		]
		new
	]
	
	load-binary: func [s [string!] e [string!] /local new byte][
		new: make binary! (offset? s e) / 2			;-- allocated size above final size

		parse/all/case s [
			some [
				copy byte 2 hexa (insert tail new debase/base byte 16)
				| ws | comment-rule
				| #"}" end skip
			]
		]
		new
	]
	
	run: func [src [string! binary!]][
		line: 1
		count?: yes
		
		append/only stack make block! 1

		unless parse/all/case src program [
			throw-error "invalid Red data"
		]
		
		add-line-markers stack/1
		also stack/1 clear stack
	]
]