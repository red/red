Red [
	Title:   "Red language syntax highlight lexer"
	Author:  "Nenad Rakocevic & Xie Qingtian"
	File: 	 %highlight.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

highlight: context [
	throw-error: function [spec [block!] /missing][
		type: spec/1									;-- preserve lit-words from double reduction
	]
	
	add-styles: function [
		src		[string!]
		dst		[block! none!]
		theme	[map!]
		/part	
			length [integer! string!]
		return: [block!]
		/local
			new s e len style c pos value cnt type process path
			digit hexa-upper hexa-lower hexa hexa-char not-word-char not-word-1st
			not-file-char not-str-char not-mstr-char caret-char
			non-printable-char integer-end ws-ASCII ws-U+2k control-char
			four half non-zero path-end base base64-char slash-end not-url-char
			email-end
	][
		cs:		[- - - - - - - - - - - - - - - - - - - - - - - -]	;-- memoized bitsets
		count?:	yes										;-- if TRUE, lines counter is enabled

		stack: 0
		line: 1
		dst: any [dst make block! 200]

		if cs/1 = '- [
			cs/1:  charset "0123465798"					;-- digit
			cs/2:  charset "ABCDEF"						;-- hexa-upper
			cs/3:  charset "abcdef"						;-- hexa-lower
			cs/4:  union cs/1 cs/2						;-- hexa
			cs/5:  union cs/4 cs/3						;-- hexa-char	
			cs/6:  charset {/\^^,[](){}"#%$@:;}			;-- not-word-char
			cs/7:  union union cs/6 cs/1 charset {'}	;-- not-word-1st
			cs/8:  charset {[](){}"@:;}					;-- not-file-char
			cs/9:  #"^""								;-- not-str-char
			cs/10: #"}"									;-- not-mstr-char
			cs/11: charset [#"^(40)" - #"^(5F)"]		;-- caret-char
			cs/12: charset [							;-- non-printable-char
				#"^(00)" - #"^(08)"						;-- (exclude TAB)
				#"^(0A)" - #"^(1F)"
			]
			cs/13: charset {^{"[]();:xX}				;-- integer-end
			cs/14: charset " ^-^M"						;-- ws-ASCII, ASCII common whitespaces
			cs/15: charset [#"^(2000)" - #"^(200A)"]	;-- ws-U+2k, Unicode spaces in the U+2000-U+200A range
			cs/16: charset [ 							;-- Control characters
				#"^(00)" - #"^(1F)"						;-- C0 control codes
				#"^(80)" - #"^(9F)"						;-- C1 control codes
			]
			cs/17: charset "01234"						;-- four
			cs/18: charset "012345"						;-- half
			cs/19: charset "123456789"					;-- non-zero
			cs/20: charset {^{"[]();}					;-- path-end
			cs/21: union cs/1 charset [					;-- base64-char
				#"A" - #"Z" #"a" - #"z" #"+" #"/" #"="
			]
			cs/22: charset {[](){}":;}					;-- slash-end
			cs/23: charset {[](){}";}					;-- not-url-char
			cs/24: union cs/8 union cs/14 charset "<^/" ;-- email-end
		]
		set [
			digit hexa-upper hexa-lower hexa hexa-char not-word-char not-word-1st
			not-file-char not-str-char not-mstr-char caret-char
			non-printable-char integer-end ws-ASCII ws-U+2k control-char
			four half non-zero path-end base64-char slash-end not-url-char email-end
		] cs

		byte: [
			"25" half
			| "2" four digit
			| "1" digit digit
			| non-zero digit
			| digit
		]

		;-- Whitespaces list from: http://en.wikipedia.org/wiki/Whitespace_character
		ws: [
			pos: #"^/" (
				if count? [
					line: line + 1 
				]
			)
			| ws-ASCII									;-- only the common whitespaces are matched
			;| #"^(0085)"								;-- U+0085 (Newline)
			| #"^(00A0)"								;-- U+00A0 (No-break space)
			;| #"^(1680)"								;-- U+1680 (Ogham space mark)
			;| #"^(180E)"								;-- U+180E (Mongolian vowel separator)
			;| ws-U+2k									;-- U+2000-U+200A range
			;| #"^(2028)"								;-- U+2028 (Line separator)
			;| #"^(2029)"								;-- U+2029 (Paragraph separator)
			;| #"^(202F)"								;-- U+202F (Narrow no-break space)
			;| #"^(205F)"								;-- U+205F (Medium mathematical space)
			;| #"^(3000)"								;-- U+3000 (Ideographic space)
		]

		newline-char: [
			#"^/"
			| #"^(0085)"								;-- U+0085 (Newline)
			| #"^(2028)"								;-- U+2028 (Line separator)
			| #"^(2029)"								;-- U+2029 (Paragraph separator)
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
				| pos: [2 6 hexa-char] (				;-- Unicode values allowed up to 10FFFFh
					type: 'char!
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
				| pos: caret-char (value: pos/1 - 64)
			]
		]

		char-rule: [
			{#"} [
				 escaped-char
				| ahead [non-printable-char | not-str-char]
				  (throw-error [char! skip s -2])
				  reject
				| skip (value: s/1)
			][
				{"} (type: 'char!)
				| (throw-error [char! skip s -2])
			]
		]

		line-string: [
			#"^"" any [
				{^^"}
				| ahead [#"^"" | newline-char] break
				| escaped-char
				| skip
			]
			#"^""
		]

		nested-curly-braces: [
			(cnt: 1)
			any [
				counted-newline 
				| "^^{"
				| "^^}"
				| #"{" (cnt: cnt + 1)
				| #"}" if (zero? cnt: cnt - 1) break
				| escaped-char
				| skip
			]
		]

		multiline-string: [
			#"{" nested-curly-braces (unless zero? cnt [throw-error [string! s]])
		]

		string-rule: [(type: 'string!) line-string | multiline-string]
		
		tag-rule: [
			#"<" not [#"=" | #">" | #"<" | ws] (type: 'tag!)
			 some [#"^"" thru #"^"" | #"'" thru #"'" | e: #">" break | skip]
			(if e/1 <> #">" [throw-error [tag! back s]])
		]
		
		email-rule: [
			some [ahead email-end break | skip] #"@"
			any [ahead email-end break | skip]
			(type: 'email!)
		]

		base-2-rule: [
			"2#{" [
				any [counted-newline | 8 [#"0" | #"1" ] | ws-no-count | comment-rule] #"}"
				| break
			] (base: 2)
		]

		base-16-rule: [
			opt "16" "#{" [
				any [counted-newline | 2 hexa-char | ws-no-count | comment-rule] #"}"
				| break
			] (base: 16)
		]

		base-64-rule: [
			"64#{" (cnt: 0) [
				any [counted-newline | base64-char | ws-no-count (cnt: cnt + 1) | comment-rule] #"}"
				| break
			] (base: 64)
		]

		binary-rule: [base-16-rule | base-64-rule | base-2-rule]

		file-rule: [
			#"%" [
				#"{" (throw-error [file! s])
				| line-string (type: 'file!)
				| any [ahead [not-file-char | ws-no-count] break | skip]
				  (type: 'file!)
			]
		]

		url-rule: [
			#":" not [not-url-char | ws-no-count | end]
			any [#"@" | #":" | ahead [not-file-char | ws-no-count] break | skip]
			(type: 'url!)
		]

		symbol-rule: [
			(ot: none) some [
				ahead [not-word-char | ws-no-count | control-char] break
				| #"<" ot: [ahead #"/" (ot: back ot) :ot break | none]	;-- a</b>
				| #">" if (ot) [(ot: back ot) :ot break]				;-- a<b>
				| skip
			] e:
		]

		begin-symbol-rule: [							;-- 1st char in symbols is restricted
			[not ahead [not-word-1st | ws-no-count | control-char]]
			symbol-rule
		]

		path-rule: [
			ahead slash (								;-- path detection barrier
				stack: stack + 1
				type: 'path!
			)
			some [
				slash
				[
					integer-number-rule
					| begin-symbol-rule			(type: 'word!)
					| paren-rule
					| #":" begin-symbol-rule	(type: 'get-word!)
					;@@ add more datatypes here
					| (throw-error [path! path])
					  reject
				]
			]
			opt [#":" (type: 'set-path!)][
				ahead [path-end | ws | end] | (throw-error [type path])
			]
			(stack: stack + 1)
		]
		
		special-words: [
			#"%" [ws-no-count | end] (value: "%")	;-- special case for remainder op!
			| #"/" ahead [slash-end | slash | ws-no-count | control-char | end][
				#"/" 
				ahead [slash-end | ws-no-count | control-char | end] (value: "//")
				| (value: "/")
			]
			| "<>" (value: "<>")
		]

		word-rule: 	[
			(type: 'word!) special-words	opt [#":" (type: 'set-word!)]
			| path: begin-symbol-rule (type: 'word!) [
				url-rule
				| path-rule							;-- path matched
				| opt [#":" (type: 'set-word!)]
			]
		]

		get-word-rule: [
			#":" (type: 'get-word!) [
				special-words
				| begin-symbol-rule [
					path-rule (type: 'get-path!)
					| (type: 'get-word!)	;-- get-word matched
				]
			]
		]

		lit-word-rule: [
			#"'" (type: 'lit-word!) [
				special-words (to-word stack value type)
				| [
					begin-symbol-rule [
						path-rule (type: 'lit-path!)			 ;-- path matched
						| (type: 'lit-word!) ;-- lit-word matched
					]
				]
			]
			opt [#":" (throw-error [type back s])]
		]

		issue-rule: [
			#"#" (type: 'issue!) symbol-rule (
				if (index? s) = index? e [throw-error [type skip s -4]]
			)
		]
		

		refinement-rule: [
			slash [
				some slash (type: 'word!)				;--  ///... case
				| ahead [not-word-char | ws-no-count | control-char] (type: 'word!) ;-- / case
				| symbol-rule (type: 'refinement! next s)
			]
		]
		
		sticky-word-rule: [								;-- protect from sticky words typos
			ahead [integer-end | ws-no-count | end | (throw-error [type s])]
		]
		hexa-rule: [2 8 hexa #"h"]

		tuple-value-rule: [byte 2 11 [dot byte] (type: 'tuple!)]

		tuple-rule: [tuple-value-rule sticky-word-rule]
		
		time-rule: [
			positive-integer-rule [
				float-number-rule ;-- mm:ss.dd
				| [
					#":" positive-integer-rule opt float-number-rule	;-- hh:mm:ss[.dd]
					| (type: 'time!)						;-- hh:mm
				]
			] (type: 'time!)
		]
		
		positive-integer-rule: [(type: 'integer!) digit any digit]

		integer-number-rule: [
			opt [#"-" (neg?: yes) | #"+" (neg?: no)] digit any [digit | #"'" digit] (type: 'integer!)
		]

		integer-rule: [
			float-special	;-- escape path for NaN, INFs
			| (neg?: no) integer-number-rule
			  opt [float-number-rule | float-exp-rule (type: 'float!)]
			  opt [#"%" (type: 'percent!)]
			  sticky-word-rule
			  opt [
				[#"x" | #"X"] integer-number-rule
				(type: 'pair!)
			  ]
			  opt [#":" [time-rule | (throw-error [type pos])]]
		]

		float-special: [
			opt #"-" "1.#" [
				[[#"N" | #"n"] [#"a" | #"A"] [#"N" | #"n"]]
				| [[#"I" | #"i"] [#"N" | #"n"] [#"F" | #"f"]]
			] (type: 'float!)
		]

		float-exp-rule: [[#"e" | #"E"] opt [#"-" | #"+"] 1 3 digit]

		float-number-rule: [
			[dot | comma] digit any [digit | #"'" digit]
			opt float-exp-rule (type: 'float!)
		]

		float-rule: [
			opt [#"-" | #"+"] float-number-rule
			opt [#"%" (type: 'percent!)]
			sticky-word-rule
		]
		
		map-rule: [
			"#(" (stack: stack + 1)
			any-value (type: none)
			#")" (stack: stack - 1)
		]

		block-rule: [
			#"[" (stack: stack + 1)
			any-value (type: none)
			#"]" (stack: stack - 1)
		]

		paren-rule: [
			#"(" (stack: stack + 1)
			any-value (type: none)
			#")" (stack: stack - 1)
		]

		escaped-rule: [
			"#[" pos: any ws [
				  "true"  			(value: true)
				| "false" 			(value: false)
				| [
					"none!"			
					| "logic!"
					| "block!"
					| "integer!"
					| "word!"
					| "set-word!"
					| "get-word!"
					| "lit-word!"
					| "refinement!"
					| "binary!"
					| "string!"
					| "char!"
					| "bitset!"
					| "path!"
					| "set-path!"
					| "lit-path!"
					| "get-path!"
					| "native!"
					| "action!"
					| "op!"
					| "issue!"
					| "paren!"
					| "function!"
					| "routine!"
				]
				| "none" 			(value: none)
			] pos: any ws #"]"
		]

		comment-rule: [(type: 'comment!) #";" [to lf | to end]]

		wrong-delimiters: [
			pos: [
				  #"]" (value: #"[") | #")" (value: #"(")
				| #"[" (value: #"]") | #"(" (value: #")")
			] :pos
		]

		literal-value: [
			pos: (type: none) s: [
				 string-rule
				| block-rule
				| comment-rule
				| tuple-rule
				| hexa-rule
				| binary-rule (type: 'binary!)
				| email-rule
				| integer-rule
				| float-rule
				| tag-rule
				| word-rule
				| lit-word-rule
				| get-word-rule
				| refinement-rule
				| file-rule
				| char-rule
				| map-rule
				| paren-rule
				| escaped-rule
				| issue-rule
			] e:
		]

		any-value: [
			pos: any [some ws | literal-value (
				if all [type style: select theme type][
					len: offset? s e
					append dst as-pair (index? s) len
					append dst style
				]
			)]
		]
		red-rules: [any-value opt wrong-delimiters]

		unless either part [
			parse/case/part src red-rules length
		][
			parse/case src red-rules
		][
			throw-error ['value pos]
		]
		dst
	]
]

;styles: make block! 100
;highlight/add-styles {--== Red 0.6.1 ==-- ^/} styles

;?? styles