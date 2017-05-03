REBOL [
	Title:   "Red Lexical Scanner"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;-- Patch NEW-LINE and NEW-LINE? natives to accept paren! --
append first find third :new-line  block! paren!
append first find third :new-line? block! paren!


lexer: context [
	verbose: 0
	
	old-line: none
	line: 	none									;-- source code lines counter
	lines:	[]										;-- offsets of newlines marker in current block
	count?: yes										;-- if TRUE, lines counter is enabled
	cnt:	none									;-- counts nested {} in multi-line strings
	pos:	none									;-- source input position (error reporting)
	mark:	none									;-- use for keeping input cursor at same position
	path:	none									;-- path input position (error reporting)
	s:		none									;-- mark start position of new value
	e:		none									;-- mark end position of new value
	series: none									;-- temporary hold last stack series
	value:	none									;-- new value
	value2:	none									;-- secondary new value
	fail?:	none									;-- used for failing some parsing rules
	type:	none									;-- define the type of the new value
	rs?:	no 										;-- if TRUE, do lexing for Red/System
	neg?:	no										;-- if TRUE, denotes a negative number value
	base:	16										;-- binary base
	otag: 	none
	ot:		none
	ct:		none
	
	;====== Parsing rules ======

	four:	  charset "01234"
	half:	  charset "012345"
	non-zero: charset "123456789"
	digit:	  union non-zero charset "0"
	dot:	  #"."
	comma:	  #","

	byte: [
		"25" half
		| #"2" four digit
		| #"1" digit digit
		| opt #"0" non-zero digit
		| 0 2 #"0" digit
		| #"0"
	]

	hexa:  union digit charset "ABCDEF"
	hexa-char: union hexa charset "abcdef"
	base64-char: union digit charset [#"A" - #"Z" #"a" - #"z" #"+" #"/" #"="]
	
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
		#{E0} 	 charset [#"^(A0)" - #"^(BF)"]   UTF8-tail
		'| 		 charset [#"^(E1)" - #"^(EC)"] 2 UTF8-tail
		'| #{ED} charset [#"^(80)" - #"^(9F)"]   UTF8-tail
		'| 		 charset [#"^(EE)" - #"^(EF)"] 2 UTF8-tail
	]
	
	UTF8-4: reduce [
		#{F0} 	 charset [#"^(90)" - #"^(BF)"] 2 UTF8-tail 
		'| 		 charset [#"^(F1)" - #"^(F3)"] 3 UTF8-tail
		'| #{F4} charset [#"^(80)" - #"^(8F)"] 2 UTF8-tail
	]
	
	UTF8-char: [pos: UTF8-1 | UTF8-2 | UTF8-3 | UTF8-4]
	
	not-word-char:	charset {/\^^,[](){}"#%$@:;}
	not-word-1st:	union union not-word-char digit charset {'}
	not-file-char:	charset {[](){}"@:;}
	not-url-char:	charset {[](){}";}
	not-email-char:	union not-file-char union ws-ASCII charset "<^/"
	not-str-char:	#"^""
	not-mstr-char:	#"}"
	not-tag-1st:	complement union ws-ASCII charset "=><"
	not-tag-char:	complement charset ">"
	tag-char:		charset "<>"
	caret-char:		charset [#"^(40)" - #"^(5F)"]
	non-printable-char: charset [#"^(00)" - #"^(1F)"]
	pair-end:		charset {^{"[]();:}
	integer-end:	charset {^{"[]();:xX}
	path-end:		charset {^{"[]();}
	file-end:		charset {^{[]();}
	stop:			none

	control-char: reduce [ 							;-- Control characters
		charset [#"^(00)" - #"^(1F)"] 				;-- C0 control codes
		'| #"^(C2)" charset [#"^(80)" - #"^(9F)"] 	;-- C1 control codes (UTF-8 encoded)
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
		#"^/" (
			if count? [
				line: line + 1
				stack/nl?: yes
			]
		)
		| ws-ASCII									;-- only the common whitespaces are matched
		| #{C2} [
			#{85}									;-- U+0085 (Newline)
			| #{A0}									;-- U+00A0 (No-break space)
		]
		;| #{E1} [
		;	#{9A80}									;-- U+1680 (Ogham space mark)
		;	| #{A08E}								;-- U+180E (Mongolian vowel separator)
		;]
		;| #{E2} [
		;	#{80} [
		;		ws-U+2k								;-- U+2000-U+200A range
		;		| #{A8}								;-- U+2028 (Line separator)
		;		| #{A9}								;-- U+2029 (Paragraph separator)
		;		| #{AF}								;-- U+202F (Narrow no-break space)
		;	]
		;	| #{819F}								;-- U+205F (Medium mathematical space)
		;]
		;| #{E38080}									;-- U+3000 (Ideographic space)
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
		(stop: [not-word-char | ws-no-count | control-char | tag-char] otag: #"<" ot: none)
		some [
			otag ot: [#"/" (otag: [end skip] ot: back ot) :ot | none] ;-- a</b>
			| #">" ct: (if ot [otag: [end skip] ct: back ot]) :ct	  ;-- a<b>
			| UTF8-filtered-char
		] e:
	]
	
	begin-symbol-rule: [							;-- 1st char in symbols is restricted
		(stop: [not-word-1st | ws-no-count | control-char])
		UTF8-filtered-char
		opt symbol-rule
	]
	
	path-rule: [
		pos: slash :pos (							;-- path detection barrier
			stack/allocate block! 4
			stack/push to type copy/part s e		;-- push 1st path element
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
					to type copy/part s e
				]
				type: path!
			)
		]
		opt [#":" (type: set-path!)]
		e: [path-end | ws-no-count | end | (pos: path throw-error)] :e ;-- detect invalid tail characters				
		(value: stack/pop type)
	]
	
	word-rule: 	[
		(type: word!)
		#"%" [ws-no-count | pos: file-end :pos | end] (value: "%")	;-- special case for remainder op!
		| path: s: begin-symbol-rule [
			url-rule
			| path-rule 							;-- path matched
			| (value: copy/part s e)				;-- word matched
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
				value: copy/part s e				;-- word matched
			)
		]
	]
	
	lit-word-rule: [
		#"'" (type: word!) [
			#"/" (type: lit-word! value: "/")
			| s: begin-symbol-rule [
				path-rule (type: lit-path!)				;-- path matched
				| (
					type: lit-word!
					value: copy/part s e				;-- word matched
				)
			]
		][s: #":" :s (throw-error) | none]
	]
	
	map-rule: [
		"#(" (stack/allocate block! 10) any-value #")" (
			stack/prefix #!map!
			value: stack/pop block!
		)
	]
	
	issue-rule: [#"#" (type: issue!) s: symbol-rule]
	
	refinement-rule: [slash (type: refinement!) s: symbol-rule]
	
	slash-rule: [s: [slash opt slash] e:]
	
	hexa-rule: [2 8 hexa e: #"h" pos: [integer-end | ws-no-count | end ] :pos (type: integer!)]

	sticky-word-rule: [								;-- protect from sticky words typos
		mark: [integer-end | ws-no-count | end | (pos: s throw-error)] :mark
	]

	tuple-value-rule: [
		(type: tuple!)
		byte dot byte 1 12 [dot byte] e:
	]

	tuple-rule: [tuple-value-rule sticky-word-rule]
	
	time-rule: [
		s: positive-integer-rule [
			decimal-number-rule (value: as-time 0 value load-number copy/part s e neg?) ;-- mm:ss.dd
			| (value2: load-number copy/part s e) [
				#":" s: positive-integer-rule opt decimal-number-rule
				  (value: as-time value value2 load-number copy/part s e neg?)	;-- hh:mm:ss[.dd]
				| (value: as-time value value2 0 neg?)							;-- hh:mm
			]
		] (type: time!)
	]
	
	positive-integer-rule: [digit any digit e: (type: integer!)]
	
	integer-number-rule: [
		opt [#"-" (neg?: yes) | #"+" (neg?: no)] digit any [digit | #"'" digit] e:
		(type: integer!)
	]
	
	integer-rule: [
		pos: decimal-special e:								;-- escape path for NaN, INFs
		(type: issue! value: load-number copy/part s e)
		|	(neg?: no) integer-number-rule
			opt [decimal-number-rule | decimal-exp-rule e: (type: decimal!)]
			opt [#"%" e: (type: issue!)]
			sticky-word-rule
			(value: load-number copy/part s e)
			opt [
				[#"x" | #"X"] (
					type: pair!
					value2: to pair! reduce [value 0]
				)
				[s: integer-number-rule | (type: pair! throw-error)]
				mark: [pair-end | ws-no-count | end | (type: pair! throw-error)] :mark
				(value2/2: load-number copy/part s e value: value2)
			]
			opt [#":" [time-rule | (throw-error)]]
	]

	decimal-special: [
		s: "-0.0" | (neg?: no) opt [#"-" (neg?: yes)] "1.#" s: [
			[[#"N" | #"n"] [#"a" | #"A"] [#"N" | #"n"]]
			| [[#"I" | #"i"] [#"N" | #"n"] [#"F" | #"f"]]
		]
	]
	
	decimal-exp-rule: [
		[[#"e" | #"E"] opt [#"-" | #"+"] 1 3 digit]
	]
	
	decimal-number-rule: [
		[dot | comma] digit any [digit | #"'" digit]
		opt decimal-exp-rule e: (type: decimal!)
	]

	decimal-rule: [
		decimal-number-rule opt [#"%" e: (type: issue!)]
		sticky-word-rule
	]
		
	block-rule: [#"[" (stack/allocate block! 10) any-value #"]" (value: stack/pop block!)]
	
	paren-rule: [#"(" (stack/allocate paren! 10) any-value	#")" (value: stack/pop paren!)]
	
	escaped-char: [
		"^^(" [
			[										;-- special case first
				"null" 	 (value: #"^(00)")
				| "back" (value: #"^(08)")
				| "tab"  (value: #"^(09)")
				| "line" (value: #"^(0A)")
				| "page" (value: #"^(0C)")
				| "esc"  (value: #"^(1B)")
				| "del"	 (value: #"^~")
			]
			| pos: [2 6 hexa-char] e: (				;-- Unicode values allowed up to 10FFFFh
					either rs? [
						value: to-char to-integer debase/base copy/part pos e 16
					][value: encode-UTF8-char pos e]
			)
		] #")"
		| #"^^" [
			[
				#"/" 	(value: #"^/")
				| #"-"	(value: #"^-")
				| #"~" 	(value: #"^(del)")
				| #"^^" (value: #"^^")				;-- caret escaping case
				| #"{"	(value: #"{")
				| #"}"	(value: #"}")
				| #"^""	(value: #"^"")
			]
			| pos: caret-char (value: pos/1 - 64)
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
		{"} s: (type: string! stop: [not-str-char | newline-char])
		any [{^^"} | escaped-char | UTF8-filtered-char]
		e: {"}
	]
	
	nested-curly-braces: [
		(cnt: 1 fail?: none)
		any [[
				counted-newline 
				| "^^^^"
				| "^^{"
				| "^^}"
				| #"{" (cnt: cnt + 1)
				| e: #"}" (if zero? cnt: cnt - 1 [fail?: [end skip]])
				| UTF8-char
			] fail?
		]
		#"}" (old-line: line)
	]
	
	multiline-string: [#"{" s: (type: string!) nested-curly-braces]
	
	string-rule: [line-string | multiline-string]
	
	tag-rule: [
		#"<" s: not-tag-1st (type: tag!)
		 any [#"^"" thru #"^"" | #"'" thru #"'" | not-tag-char] e: #">"
	]
	
	email-rule: [
		(stop: [not-email-char])
		s: some UTF8-filtered-char #"@" (type: email!)
		any UTF8-filtered-char e: (value: dehex copy/part s e)
	]

	base-2-rule: [
		"2#{" (type: binary!) [
			s: any [counted-newline | 8 [#"0" | #"1" ] | ws-no-count | comment-rule]
			e: #"}" (base: 2)
			| (pos: skip s -3 throw-error)
		]
	]
	
	base-16-rule: [
		opt "16" "#{" (type: binary!) [
			s: any [counted-newline | 2 hexa-char | ws-no-count | comment-rule]
			e: #"}" (base: 16)
			| (pos: skip s -2 throw-error)
		]
	]

	base-64-rule: [
		"64#{" (type: binary!) [
			s: any [counted-newline | base64-char | ws-no-count | comment-rule]
			e: #"}" (
				cnt: offset? s e
				if all [0 < cnt cnt < 4][pos: skip s -4 throw-error]
				base: 64
			)
			| (pos: skip s -4 throw-error)
		]
	]

	binary-rule: [[base-16-rule | base-64-rule | base-2-rule] (old-line: line)]

	file-rule: [
		pos: #"%" (type: file! stop: [not-file-char | ws-no-count]) [
			#"{" (throw-error)
			| line-string
			| s: any UTF8-filtered-char e:
		]
	]

	url-rule: [
		#":" (type: url! stop: [not-url-char | ws-no-count])
		some UTF8-filtered-char e: (value: dehex copy/part s e)
	]

	escaped-rule: [
		"#[" any-ws [
			  "true"  (value: true)
			| "false" (value: false)
			| s: [
				"none!" | "logic!" | "block!" | "integer!" | "word!" 
				| "set-word!" | "get-word!" | "lit-word!" | "refinement!"
				| "binary!" | "string!"	| "char!" | "bitset!" | "path!"
				| "set-path!" | "lit-path!" | "native!"	| "action!"
				| "issue!" | "paren!" | "function!"
			] e: (value: get to word! copy/part s e)
			| "none" (value: none)
		]  any-ws #"]"
	]
	
	comment-rule: [#";" [to #"^/" | to end]]
	
	wrong-end: [(
			ending: either 1 < length? stack/stk [
				value: switch type?/word stack/top [
					block! [#"]"]
					paren! [#")"]
				]
				first [(throw-error/with ["missing" mold value "character"])]
			][none]
		)
		ending
	]

	literal-value: [
		pos: (e: none) s: [
			comment-rule
			| escaped-rule    (stack/push value)
			| tuple-rule	  (stack/push load-tuple	 copy/part s e)
			| hexa-rule		  (stack/push decode-hexa	 copy/part s e)
			| binary-rule	  (stack/push load-binary s e base)
			| email-rule	  (stack/push to email! value)
			| integer-rule	  (stack/push value)
			| decimal-rule	  (stack/push load-decimal	 copy/part s e)
			| tag-rule		  (stack/push to tag!		 copy/part s e)
			| word-rule		  (stack/push to type value)
			| lit-word-rule	  (stack/push to type value)
			| get-word-rule	  (stack/push to type value)
			| refinement-rule (stack/push to refinement! copy/part s e)
			| slash-rule	  (stack/push to word!		 copy/part s e)
			| file-rule		  (stack/push load-file		 copy/part s e)
			| char-rule		  (stack/push decode-UTF8-char value)
			| block-rule	  (stack/push value)
			| paren-rule	  (stack/push value)
			| string-rule	  (stack/push load-string s e)
			| map-rule		  (stack/push value)
			| issue-rule	  (stack/push to issue!		 copy/part s e)
		]
	]
	
	any-value: [pos: any [literal-value | ws]]

	header: [
		pos: thru "Red" (rs?: no) opt ["/System" (rs?: yes stack/push 'Red/System)]
		any-ws block-rule (stack/push value)
		| (throw-error/with "Invalid Red program") end skip
	]

	program: [
		pos: opt UTF-8-BOM
		header
		any-value
		opt wrong-end
	]
	
	;====== Helper functions ======
	
	stack: context [
		stk: []
		nl?: no
		
		allocate: func [type [datatype!] size [integer!] /local new pos][
			pos: insert/only tail stk new: make type size
			if nl? [new-line back pos yes nl?: no]
			new
		]
		
		prefix: func [value][insert/only last stk :value]
		
		push: func [value][
			value: insert/only tail last stk :value
			if nl? [new-line back value yes nl?: no]
			value
		]
		
		pop: func [type [datatype!] /local pos][
			pos: back tail stk
			nl?: new-line? pos
			
			either any [type = path! type = set-path!][
				change/only pos to type pos/1
			][
				if type <> type? pos/1 [
					throw-error/with ["invalid" mold type "closing delimiter"]
				]
			]
			also pos/1 remove pos
		]
		
		top: does [last stk]
		
		reset: does [clear stk]
	]
	
	throw-error: func [/with msg [string! block!]][
		print rejoin [
			"*** Syntax Error: " either with [
				uppercase/part reform msg 1
			][
				reform ["Invalid" mold type "value"]
			]
			"^/*** line: " line
			"^/*** at: " mold copy/part pos 40
		]
		either encap? [quit][halt]
	]

	
	pad-head: func [s [string!]][
		head insert/dup s #"0" 8 - length? s
	]
	
	encode-UTF8-char: func [s [string!] e [string!] /local c code new][
		c: debase/base pad-head copy/part s e 16
		while [c/1 = 0][c: next c]					;-- trim heading zeros
		code: to integer! c
		
		case [
			code <= 127  [
				new: to char! code					;-- c <= 7Fh
			]
			code <= 2047 [							;-- c <= 07FFh
				new: (shift/left (shift code 6) or #"^(C0)" 8)
						or (code and #"^(3F)") or #"^(80)"
			]
			code <= 65535 [							;-- c <= FFFFh
				new: (shift/left (shift code 12) or #"^(E0)" 16)
						or (shift/left (shift code 6) and #"^(3F)" or #"^(80)" 8)
						or (code and #"^(3F)") or #"^(80)"
			]
			code <= 1114111 [						;-- c <= 10FFFFh
				new: (shift/left (shift code 18) or #"^(F0)" 24)
						or (shift/left (shift code 12) and #"^(3F)" or #"^(80)" 16)
						or (shift/left (shift code 6)  and #"^(3F)" or #"^(80)" 8)
						or (code and #"^(3F)") or #"^(80)"
			]
			'else [
				throw-error/with "Codepoints above U+10FFFF are not supported"
			]
		]
		if integer? new [
			new: debase/base to-hex new 16
			remove-each byte new [byte = #"^(null)"]
		]	
		new
	]
	
	decode-UTF8-char: func [value /redbin][
		if all [not redbin char? value][return encode-char to integer! value]
		
		value: switch/default length? value [
			1 [value]
			2 [
				value: value and #{1F3F}
				value: add shift/left value/1 6 value/2
			]
			3 [
				value: value and #{0F3F3F}
				value: add add
					shift/left value/1 12
					shift/left value/2 6
					value/3
			]
			4 [
				value: value and #{073F3F3F}
				value: add add add
					shift/left value/1 18
					shift/left value/2 12
					shift/left value/3 6
					value/4
			]
		][
			throw-error/with "Unsupported or invalid UTF-8 encoding"
		]
		
		either redbin [value][
			encode-char to integer! value				;-- special encoding for Unicode char!
		]
	]
	
	decode-UTF8-string: func [str [string!] /local new s e][
		new: make string! length? str
		parse/all str [
			some [
				s: UTF8-char e: (
					append new debase/base skip decode-UTF8-char as-binary copy/part s e 7 16
				)
			]
		]
		head change/part str new tail str
	]
	
	encode-char: func [value [integer!]][
		head insert to-hex value #"'"
	]
	
	decode-hexa: func [s [string!]][
		to integer! debase/base s 16
	]
	
	as-time: func [h [integer!] m [integer!] s [integer! decimal!] neg? [logic!] /local t][
		if any [all [h <> 0 m < 0] all [s s < 0]][type: time! throw-error]
		t: to time! reduce [abs h abs m abs s]
		either neg? [negate t][t]
	]
	
	load-tuple: func [s [string!] /local new byte p e][
		new: join make issue! 1 + length? s #"~"
		byte: [p: 1 3 digit e: (append new skip to-hex load copy/part p e 6)]
		unless parse s [byte 2 11 [dot byte]][throw-error]
		new
	]

	load-number: func [s [string!]][
		switch/default type [
			#[datatype! decimal!][s: load-decimal s]
			#[datatype! issue!  ][
				if s = "-0.0" [s: "0-"]					;-- re-encoded for consistency
				s: to issue! either #"%" = last s [s][join "." s]
				if neg? [append s #"-"]
			]
		][
			unless find [integer! decimal!] type?/word s: to integer! s [throw-error]
		]
		s
	]

	load-decimal: func [s [string!]][
		unless attempt [s: to decimal! s][throw-error]
		s
	]

	load-string: func [s [string!] e [string!] /local new filter][
		new: make string! offset? s e				;-- allocated size close to final size
		filter: get pick [UTF8-char UTF8-filtered-char] s/-1 = #"{"

		parse/all/case copy/part s e [
			any [
				escaped-char   (insert tail new value)
				| s: filter e: (insert/part tail new s e)
			]										;-- exit on matching " or }
		]
		new
	]
	
	load-binary: func [s [string!] e [string!] base [integer!] /local new str][
		new: make string! offset? s e				;-- allocated size above final size

		parse/all/case s [
			some [
				copy str some base64-char (insert tail new str)
				| ws | comment-rule
				| #"}" end skip
			]
		]
		new: debase/base new base
		if none? new [throw-error]
		new
	]

	load-file: func [s [string!]][
		parse s [any [#"%" [2 hexa | (pos: skip pos negate 1 + length? s throw-error)] | skip]]
		to file! replace/all dehex s #"\" #"/"
	]
	
	process: func [src [string! binary!] /local blk][
		old-line: line: 1
		count?: yes
		blk: stack/allocate block! 100				;-- root block
		
		unless parse/all/case src program [throw-error]
		stack/reset
		blk
	]
]