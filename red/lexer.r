REBOL [
	Title:   "Red Lexical Scanner"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

lexer: context [
	verbose: 0
	
	line: 	none									;-- source code lines counter
	lines:	[]										;-- offsets of newlines marker in current block
	count?: yes										;-- if TRUE, lines counter is enabled
	pos:	none									;-- source input position (error reporting)
	s:		none									;-- mark start position of new value
	e:		none									;-- mark end position of new value
	value:	none									;-- new value
	fail?:	none									;-- used for failing some parsing rules
	type:	none									;-- define the type of the new value
	
	;====== Parsing rules ======
	
	digit: charset "0123465798"
	hexa:  union digit charset "ABCDEF" 
	
	;-- UTF-8 encoding rules from: http://tools.ietf.org/html/rfc3629#section-4
	UTF-8-BOM: #{EFBBBF}
	ws-ASCII:  charset " ^-^M"						;-- ASCII common whitespaces
	ws-U+2k:   charset [#"^(80)" - #"^(8A)"]		;-- Unicode spaces in the U+2000-U+200A range
	UTF8-tail: charset [#"^(80)" - #"^(BF)"]
	UTF8-1:    charset [#"^(00)" - #"^(7F)"]
	
	UTF8-2: reduce [
		charset [#"^(C2)" - #"^(DF)"]
		UTF8-tail
	]
	
	UTF8-3: reduce [
		#{E0} 	 charset [#"^(A0)" - #"^(BF)"] UTF8-tail
		'| 		 charset [#"^(E1)" - #"^(EC)"] 2 UTF8-tail
		'| #{ED} charset [#"^(80)" - #"^(9F)"] UTF8-tail
		'| 		 charset [#"^(EE)" - #"^(EF)"] 2 UTF8-tail
	]
	
	UTF8-4: reduce [
		#{F0} 	 charset [#"^(90)" - #"^(BF)"] 2 UTF8-tail
		'| 		 charset [#"^(F1)" - #"^(F3)"] 3 UTF8-tail
		'| #{F4} charset [#"^(80)" - #"^(8F)"] 2 UTF8-tail
	]
	
	UTF8-char: [pos: UTF8-1 | UTF8-2 | UTF8-3 | UTF8-4]
	
	not-word-char:  charset {/\^^,'[](){}"#%$@:;}
	not-word-1st:	union not-word-char digit
	not-file-char:  charset {[](){}"%@:;}
	not-str-char:   #"^""
	not-mstr-char:  #"}"
	caret-char:	    charset [#"^(40)" - #"^(5F)"]
	non-printable-char: charset [#"^(00)" - #"^(1F)"]
	integer-end:	charset {^{"])}
	stop: 		    none
	
	control-char: reduce [
		charset [#"^(00)" - #"^(1F)"] 				;-- ASCII control characters
		'| #"^(C2)" charset [#"^(80)" - #"^(9F)"] 	;-- C2 control characters
	]
	
	UTF8-filtered-char: [
		[pos: stop :pos (fail?: [end skip]) | UTF8-char e: (fail?: none)]
		fail?
	]
	
	UTF8-printable: [
		[non-printable-char | not-str-char (fail?: [end skip]) | UTF8-char (fail?: none)]
		fail?
	]
	
	;-- Whitespaces list from: http://en.wikipedia.org/wiki/Whitespace_character
	ws: [
		pos: #"^/" (
			if count? [
				line: line + 1 
				append/only lines to block! stack/tail?
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
	
	counted-newline: [pos: #"^/" (line: line + 1)]
	
	ws-no-count: [(count?: no) ws (count?: yes)]
	
	any-ws: [pos: any ws]
	
	symbol-rule: [
		(stop: [not-word-char | ws-no-count | control-char])
		some UTF8-filtered-char e:
	]
	
	begin-symbol-rule: [							;-- 1st char in symbols is restricted
		(stop: [not-word-1st | ws-no-count | control-char])
		UTF8-filtered-char
		opt symbol-rule
	]
	
	path-rule: [
		pos: slash :pos (							;-- path detection barrier
			stack/push path!
			;-- push 1st path element
						
			;-- Cannot do TO WORD! directly from a BINARY!
			stack/push to type to string! copy/part (bin-pos s) (bin-pos e)
		)
		some [
			slash
			s: [
				integer-number-rule
				| begin-symbol-rule			(type: word!)
				| paren-rule 				(type: paren!)
				| #":" s: begin-symbol-rule	(type: get-word!)
				;@@ add more datatypes here
			] (
				stack/push either type = paren! [	;-- append path element
					value
				][
					;-- Cannot do TO WORD! directly from a BINARY!
					to type to string! copy/part (bin-pos s) (bin-pos e)
				]
				type: path!
			)
			opt [#":" (type: set-path!)]
		]
		(value: stack/pop type)
	]
	
	word-rule: 	[
		(type: word!) s: begin-symbol-rule [
			path-rule 								;-- path matched
			| (										;-- word matched
				value: to string! copy/part (bin-pos s) (bin-pos e)
			)
			opt [#":" (type: set-word!)]
		] 
	]
	
	get-word-rule: [
		#":" (type: get-word!) s: begin-symbol-rule [
			path-rule (
				value/1: to get-word! value/1		;-- workaround missing get-path! in R2
			)
			| (
				type: get-word!
				value: to string! copy/part (bin-pos s) (bin-pos e)
			)
		]
	]
	
	lit-word-rule: [
		#"'" (type: word!) s: begin-symbol-rule [
			path-rule (type: lit-path!)				;-- path matched
			| (
				type: lit-word!
				value: to string! copy/part (bin-pos s) (bin-pos e)
			)
		]
	]
	
	issue-rule: [#"#" (type: issue!) s: symbol-rule]
	
	refinement-rule: [slash (type: refinement!) s: symbol-rule]
	
	slash-rule: [s: [slash opt slash] e:]
	
	hexa-rule: [2 8 hexa e: #"h" (type: integer!)]
		
	integer-number-rule: [
		(type: integer!)
		opt [#"-" | #"+"] digit any [digit | #"'" digit] e:
	]
	
	integer-rule: [
		integer-number-rule
		pos: [										;-- protection rule from typo with sticky words
			[integer-end | ws-no-count | end] (fail?: none)
			| skip (fail?: [end skip]) 
		] :pos 
		fail?
	]
		
	block-rule: [#"[" (stack/push block!) any-value #"]" (value: stack/pop block!)]
	
	paren-rule: [#"(" (stack/push paren!) any-value	#")" (value: stack/pop paren!)]
	
	escaped-char: [
		"^^(" [
			s: [2 6 hexa] e: (						;-- Unicode values allowed up to 10FFFFh
				value: encode-UTF8-char (bin-pos s) (bin-pos e)
			)
			| [
				"null" 	 (value: #{00})
				| "back" (value: #{08})
				| "tab"  (value: #{09})
				| "line" (value: #{0A})
				| "page" (value: #{0C})
				| "esc"  (value: #{1B})
				| "del"	 (value: #{7F})
			] 
		] #")"
		| #"^^" [
			[
				#"/" 	(value: #{0A})
				| #"-"	(value: #{09})
				| #"?" 	(value: #{7F})
				| #"^^" (value: #{5E})				;-- caret escaping case
			]
			| s: caret-char (
				value: integer-to-bytes/width ((first (bin-pos s)) - 64) 1
			)
		]
	]
	
	char-rule: [
		{#"} (type: char!) [
			s: escaped-char
			| copy value UTF8-printable (value: bin-capture value)
		] {"}
	]
	
	line-string: [
		{"} s: (type: string! stop: [not-str-char | newline-char])
		any UTF8-filtered-char
		e: {"}
	]
	
	multiline-string: [
		#"{" s: (type: string! stop: not-mstr-char)
		any [counted-newline | "^^}" | UTF8-filtered-char]
		e: #"}"
	]
	
	string-rule: [line-string | multiline-string]
	
	binary-rule: [
		"#{" (type: binary!) 
		s: any [counted-newline | 2 hexa | ws-no-count | comment-rule]
		e: #"}"
	]
	
	file-rule: [
		#"%" (type: file! stop: [not-file-char | ws-no-count])
		s: some UTF8-filtered-char e:
	]
	
	escaped-rule: [
		"#[" any-ws [
			"none" 	  (value: none)
			| "true"  (value: true)
			| "false" (value: false)
			| s: [
				"none!" | "logic!" | "block!" | "integer!" | "word!" 
				| "set-word!" | "get-word!" | "lit-word!" | "refinement!"
				| "binary!" | "string!"	| "char!" | "bitset!" | "path!"
				| "set-path!" | "lit-path!" | "native!"	| "action!"
				| "issue!" | "paren!" | "function!"
			] e: (
				value: get to word! copy/part (bin-pos s) (bin-pos e)
			)
		]  any-ws #"]"
	]
	
	comment-rule: [#";" [to #"^/" | to end]]
	
	multiline-comment-rule: [
		"comment" any-ws #"{" (stop: not-mstr-char) any [
			counted-newline | "^^}" | UTF8-filtered-char
		] #"}"
	]
	
	wrong-delimiters: [
		pos: [
			  #"]" (value: #"[") | #")" (value: #"(")
			| #"[" (value: #"]") | #"(" (value: #")")
		] :pos
		(throw-error/with ["missing matching" value])
	]

	literal-value: [
		pos: (e: none) s: [
			comment-rule
			| multiline-comment-rule
			| escaped-rule	  (stack/push value)
			| integer-rule (
				stack/push load-integer copy/part (bin-pos s) (bin-pos e)
			)
			| hexa-rule (
				stack/push decode-hexa copy/part (bin-pos s) (bin-pos e)
			)
			| word-rule		  (stack/push to type value)
			| lit-word-rule	  (stack/push to type value)
			| get-word-rule	  (stack/push to type value)
			| refinement-rule (
				;-- This is convoluted due to an R3 bug in TO that won't allow
				;-- issue characters (like starting with a number) in refinement
				;-- unless you go through an issue intermidiary.  Also there's
				;-- what may be a general Rebol problem about not being able
				;-- to convert directly from binary to word with an implied
				;-- string decoding...you have to convert to string
				
				stack/push to refinement! either r3? [
					to issue! to string! copy/part (bin-pos s) (bin-pos e)
				] [
					to string! copy/part (bin-pos s) (bin-pos e)
				]
			)
			| slash-rule (
				stack/push to word! to string! copy/part (bin-pos s) (bin-pos e)
			)
			| issue-rule (
				stack/push to issue! to string! copy/part (bin-pos s) (bin-pos e)
			)
			| file-rule (
				stack/push to file! to string! copy/part (bin-pos s) (bin-pos e)
			)
			| char-rule (
				stack/push encode-char decode-UTF8-char value
			)
			| block-rule	  (stack/push value)
			| paren-rule	  (stack/push value)
			| string-rule	  (
				stack/push load-string (bin-pos s) (bin-pos e)
			)
			| binary-rule (
				stack/push load-binary (bin-pos s) (bin-pos e)
			)
		]
	]
	
	any-value: [pos: any [literal-value | ws]]

	header: [
		pos: thru "Red" any-ws block-rule (stack/push value)
		| (throw-error/with "Invalid Red program") end skip
	]

	program: [
		pos: opt UTF-8-BOM
		header
		any-value
		opt wrong-delimiters
	]
	
	;====== Helper functions ======
	
	stack: context [
		stk: []
		
		push: func [value][
			either any [value = block! value = paren! value = path!][
				if value = path! [value: block!]
				insert/only tail stk value: make value 1			
				value
			][
				insert/only tail last stk :value
			]
		]
		
		pop: func [type [datatype!]][
			if any [type = path! type = set-path!][type: block!]
			
			if type <> type? last stk [
				throw-error/with ["invalid" mold type "closing delimiter"]
			]
			also last stk remove back tail stk
		]
		
		tail?: does [tail last stk]
		reset: does [clear stk]
	]
	
	throw-error: func [/with msg [string! block!] /binary][
		print rejoin [
			"*** Syntax Error: " either with [
				uppercase/part reform msg 1
			][
				reform ["Invalid" mold type "value"]
			]
			"^/*** line: " line
			"^/*** at: " either binary [
				mold copy/part pos 40
			] [
				;-- Note this conversion might give you gibberish in R2,
				;-- since it doesn't understand UTF8.
				mold to string! copy/part pos 40
			]
		]
		halt
	]

	add-line-markers: func [blk [block!]][	
		foreach pos lines [new-line pos yes]
		clear lines
	]
	
	pad-head: func [s [binary!]][
		head insert/dup s #"0" 8 - length? s
	]
	
	encode-UTF8-char: func [s [binary!] e [binary!] /local c code new][
		c: debase/base pad-head copy/part s e 16
		while [c/1 = 0][c: next c]					;-- trim heading zeros
		code: to integer! c
		
		case [
			code <= 127  [
				new: code							;-- c <= 7Fh
			]
			code <= 2047 [							;-- c <= 07FFh
				new: (shift-left (shift-right code 6) or #"^(C0)" 8)
						or (code and #"^(3F)") or #"^(80)"
			]
			code <= 65535 [							;-- c <= FFFFh
				new: (shift-left (shift-right code 12) or #"^(E0)" 16)
						or (shift-left (shift-right code 6) and #"^(3F)" or #"^(80)" 8)
						or (code and #"^(3F)") or #"^(80)"
			]
			code <= 1114111 [						;-- c <= 10FFFFh
				new: (shift-left (shift-right code 18) or #"^(F0)" 24)
						or (shift-left (shift-right code 12) and #"^(3F)" or #"^(80)" 16)
						or (shift-left (shift-right code 6)  and #"^(3F)" or #"^(80)" 8)
						or (code and #"^(3F)") or #"^(80)"
			]
			'else [
				throw-error/with "Codepoints above U+10FFFF are not supported"
			]
		]
		assert [integer? new]
		either new < 0 [
			;-- Special case for R2 with 32-bit integers... with this
			;-- method of encoding by shift and bits, we can wind up with
			;-- a negative number.  integer-to-bytes by default currently
			;-- requires you to specify a width for negative numbers,
			;-- but otherwise gives you just enough bytes to represent
			;-- the positive number.
			assert [not r3?]
			new: integer-to-bytes/width new 4
		] [
			new: integer-to-bytes new
		]
	]
	
	decode-UTF8-char: func [value [binary! char!]][
		if char? value [return to integer! value]
		
		value: switch/default length? value [
			1 [value]
			2 [
				value: value and #{1F3F}
				value: add shift-left value/1 6 value/2
			]
			3 [
				value: value and #{0F3F3F}
				value: add add
					shift-left value/1 12
					shift-left value/2 6
					value/3
			]
			4 [
				value: value and #{073F3F3F}
				value: add add add
					shift-left value/1 18
					shift-left value/2 12
					shift-left value/3 6
					value/4
			]
		][
			throw-error/with/binary "Unsupported or invalid UTF-8 encoding"
		]	
		
		to integer! value				;-- special encoding for Unicode char!
	]
	
	encode-char: func [value [integer!] /local hexstring][
		assert [
			parse (mold integer-to-bytes/width value 4) [
				"#{" copy hexstring to "}" skip
			]
		] 
		insert hexstring {'}
		to issue! hexstring
	]

	decode-hexa: func [s [binary!]][
		binary-to-int32 s
	]

	load-integer: func [s [binary!]][
		unless attempt [s: to integer! to-string s][throw-error]
		s
	]

	load-string: func [s [binary!] e [binary!] /local new encoded checked][		
		new: make binary! offset? s e				;-- allocated size close to final size

		;-- R3 will not (at present) successfully string convert
		;-- the buffer at the end if any codepoints are above #"^(FFFF)"
		
		checked: func [encoded [binary!]] [
			if r3? [assert [65535 >= decode-UTF8-char encoded]]
			encoded
		]

		parse/all/case s [
			some [
				escaped-char (insert tail new checked value)
				| s: UTF8-filtered-char e: (		;-- already set to right filter	
					insert tail new checked copy/part (bin-pos s) (bin-pos e) 
				)
			]										;-- exit on matching " or }
		]
		
		;-- Fake in R2 (just passes thru all UTF8 data), real in R3
		to string! new
	]
	
	load-binary: func [s [binary!] e [binary!] /local new byte][
		new: make binary! (offset? s e) / 2			;-- allocated size above final size

		parse/all/case s [
			some [
				copy byte 2 hexa (insert tail new debase/base (bin-capture byte) 16)
				| ws | comment-rule
				| #"}" end skip
			]
		]
		new
	]
	
	process: func [src [string! binary!] /local blk][
		if string? src [
		  	;-- This limitiation is to keep R2-Red working the same and on
		  	;-- the same compatible subset of input as Unicode-based R3-Red.
		  	;-- Although this check will not be necessary when R2 compatibility
		  	;-- is not interesting any more, it should be pointed out that
		  	;-- if R3 is not updated it will only allow codepoints up to
  			;-- ^(FFFF).  Red's current codepoint limit is ^(10FFFF), so it
  			;-- allows 16 times as many characters...thus programs must be
  			;-- provided in binary! and not as a string! to take advantage
  			;-- of these additional characters.

			src: to binary! r2-utf8-checked src
		]
		
		line: 1
		count?: yes
		
		blk: stack/push block!						;-- root block

		unless parse/all/case src program [throw-error]
		
		add-line-markers blk
		stack/reset
		blk
	]
]