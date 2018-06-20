Red [
	Title:   "Red runtime lexer"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

system/lexer: context [

	pre-load: none

	throw-error: function [spec [block!] /missing][
		type: spec/1									;-- preserve lit-words from double reduction
		spec: reduce spec
		src: back tail spec
		src/1: trim/tail either string? src/1 [
			form trim/with copy/part src/1 40 #"^/"
		][
			mold/flat/part src/1 40
		]
		if "^^/" = copy/part pos: skip tail src/1 -3 2 [remove/part pos 2]
		spec/1: type
		cause-error 'syntax any [all [missing 'missing] 'invalid] spec
	]
	
	make-hm: routine [h [integer!] m [integer!]][
		time/box (as-float h) * 3600.0 + ((as-float m) * 60.0)
	]
	
	make-msf: routine [m [integer!] s [float!]][
		time/box ((as-float m) * 60.0) + s
	]
	
	make-hms: routine [h [integer!] m [integer!] s [integer!]][
		time/box (as-float h) * 3600.0 + ((as-float m) * 60.0) + (as-float s)
	]
	
	make-hmsf: routine [h [integer!] m [integer!] s [float!]][
		time/box (as-float h) * 3600.0 + ((as-float m) * 60.0) + s
	]
	
	make-time: function [
		pos		[string!]
		hours	[integer! none!]
		mins	[integer!]
		secs	[integer! float! none!]
		neg?	[logic!]
		return: [time!]
	][
		if any [all [hours hours <> 0 mins < 0] all [secs secs < 0]][throw-error [time! pos]]
		if hours [hours: absolute hours]
		mins: absolute mins

		time: case [
			all [hours secs][
				either float? secs [
					make-hmsf hours mins secs
				][
					make-hms hours mins secs
				]
			]
			hours [make-hm hours mins]
			'else [
				unless float? secs []					;@@ TBD: error
				make-msf mins secs
			]
		]
		either neg? [negate time][time]
	]

	make-binary: routine [
		start  [string!]
		end    [string!]
		base   [integer!]
		/local
			s	 [series!]
			p	 [byte-ptr!]
			len  [integer!]
			unit [integer!]
			ret  [red-binary!]
	][
		s:  GET_BUFFER(start)
		unit: GET_UNIT(s)
		p:	  string/rs-head start
		len:  end/head - start/head
		
		ret: as red-binary! stack/arguments
		ret/head: 0
		ret/header: TYPE_BINARY
		ret/node: switch base [
			16 [binary/decode-16 p len unit]
			2  [binary/decode-2  p len unit]
			64 [binary/decode-64 p len unit]
		]
		if ret/node = null [ret/header: TYPE_NONE]		;-- return NONE!
	]

	make-tuple: routine [
		start  [string!]
		end	   [string!]
		/local
			s    [series!]
			err	 [integer!]
			len  [integer!]
			unit [integer!]
			p	 [byte-ptr!]
			tp	 [byte-ptr!]
			ret  [red-value!]
	][
		s:	  GET_BUFFER(start)
		unit: GET_UNIT(s)
		p:	  string/rs-head start
		len:  end/head - start/head
		ret:  stack/arguments
		err:  0
		
		tokenizer/scan-tuple p len unit	:err ret
		assert err = 0									;-- pre-checked validity
		ret
	]

	make-number: routine [
		start  [string!]
		end	   [string!]
		type   [datatype!]
		/local
			s	 [series!]
			len  [integer!]
			unit [integer!]
			p	 [byte-ptr!]
			err	 [integer!]
			i	 [integer!]
	][
		if type/value <> TYPE_INTEGER [
			make-float start end type					;-- float! escape path
			exit
		]
		s:	  GET_BUFFER(start)
		unit: GET_UNIT(s)
		p:	  string/rs-head start
		len:  end/head - start/head
		err:  0

		i: tokenizer/scan-integer p len unit :err
		
		if err <> 0 [
			type/value: TYPE_FLOAT
			make-float start end type			;-- fallback to float! loading
			exit
		]			
		integer/box i
	]

	make-float: routine [
		start [string!]
		end	  [string!]
		type  [datatype!]
		/local
			s	 [series!]
			unit [integer!]
			len  [integer!]
			p	 [byte-ptr!]
			err	 [integer!]
			f	 [float!]
	][
		s:	  GET_BUFFER(start)
		unit: GET_UNIT(s)
		p:	  string/rs-head start
		len:  end/head - start/head
		err:  0
		
		f: tokenizer/scan-float p len unit :err
		
		either type/value = TYPE_FLOAT [float/box f][percent/box f / 100.0]
	]

	make-hexa: routine [
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

	make-char: routine [
		start	[string!]
		end		[string!]
		/local
			n	  [integer!]
			value [red-value!]
	][
		n: make-hexa start end
		value: as red-value! integer/box n
		set-type value TYPE_CHAR
	]

	push-path: routine [
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
		path/args: null
	]

	set-path: routine [
		stack [block!]
		/local
			path [red-path!]
	][
		path: as red-path! _series/pick as red-series! stack 1 null
		path/args: null
		set-type as red-value! path TYPE_SET_PATH
	]

	make-word: routine [
		src   [string!]
		type  [datatype!]
	][
		set-type
			as red-value! word/box (symbol/make-alt src) ;-- word/box puts it in stack/arguments
			type/value
	]

	to-word: func [
		stack [block!]
		src   [string!]
		type  [datatype!]
	][
		store stack make-word src type
	]

	pop: function [stack [block!]][
		value: last stack
		remove back tail stack

		either any [1 < length? stack head? stack/1][
			append/only last stack :value
		][
			pos: back tail stack						;-- root storage and offset-ed series (/into option)
			pos/1: insert/only last stack :value
		]
	]

	store: function [stack [block!] value][
		either any [1 < length? stack head? stack/1][
			append last stack value
		][
			pos: back tail stack						;-- root storage and offset-ed series (/into option)
			pos/1: insert last stack value
		]
	]

	new-line: routine [
		series [any-type!]
		/local
			blk  [red-block!]
			s	 [series!]
			cell [red-value!]
	][
		assert any [
			TYPE_OF(series) = TYPE_BLOCK
			TYPE_OF(series) = TYPE_PAREN
		]
		blk: as red-block! series
		s: GET_BUFFER(blk)
		cell: s/offset + blk/head
		
		while [cell < s/tail][
			cell/header: cell/header or flag-new-line
			cell: cell + 1
		]
	]
	
	transcode: function [
		src	 [string!]
		dst	 [block! none!]
		trap [logic!]
		/one
		/only											;-- force returning the loaded value (with /one)
		/part	
			length [integer! string!]
		return: [block!]
		/local
			new s e c pos value cnt type process path
			digit hexa-upper hexa-lower hexa hexa-char not-word-char not-word-1st
			not-file-char not-str-char not-mstr-char caret-char
			non-printable-char integer-end ws-ASCII ws-U+2k control-char
			four half non-zero path-end base base64-char slash-end not-url-char
			email-end pair-end file-end err
	][
		cs:		[- - - - - - - - - - - - - - - - - - - - - - - - - - - - -] ;-- memoized bitsets
		stack:	clear []
		count?:	yes										;-- if TRUE, lines counter is enabled
		old-line: line: 1

		append/only stack any [dst make block! 200]

		make-string: [
			new: make type len: (index? e) - index? s
			parse/case/part s [
				any [
					escaped-char (append new value)
					| #"^^"								;-- trash single caret chars
					| set c skip (append new c)
				]
			] len
			new
		]

		make-file: [
			new: make type (index? e) - index? s
			buffer: copy/part s e
			parse buffer [any [#"%" [2 hexa | (throw-error [type s])] | skip]]
			append new dehex buffer
			if type = file! [parse new [any [s: #"\" change s #"/" | skip]]]
			new
		]
		
		month-rule: [(m: none)]							;-- dynamically filled
		mon-rule:   [(m: none)]							;-- dynamically filled

		if cs/1 = '- [
			do [
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
				cs/25: charset {^{"[]();:}					;-- pair-end
				cs/26: charset {^{[]();:}					;-- file-end
				cs/27: charset "/-"							;-- date-sep
				cs/28: charset "/T"							;-- time-sep
				cs/29: charset "=><[](){};^""				;-- not-tag-1st

				list: system/locale/months
				while [not tail? list][
					append month-rule list/1
					append/only month-rule p: copy quote (m: ?)
					unless tail? next list [append month-rule '|]
					p/2: index? list
					append mon-rule copy/part list/1 3
					append/only mon-rule p
					unless tail? next list [append mon-rule '|]
					list: next list
				]
			]
		]
		set [
			digit hexa-upper hexa-lower hexa hexa-char not-word-char not-word-1st
			not-file-char not-str-char not-mstr-char caret-char
			non-printable-char integer-end ws-ASCII ws-U+2k control-char
			four half non-zero path-end base64-char slash-end not-url-char email-end
			pair-end file-end date-sep time-sep not-tag-1st
		] cs

		byte: [
			"25" half
			| "2" four digit
			| "1" digit digit
			| opt #"0" non-zero digit
			| 0 2 #"0" digit
			| 1 2 #"0"
		]

		;-- Whitespaces list from: http://en.wikipedia.org/wiki/Whitespace_character
		ws: [
			#"^/" (
				if count? [
					line: line + 1 
					;append/only lines to block! stack/tail?
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
					| "del"	 (value: #"^~")
				]
				| pos: [2 6 hexa-char] e: (				;-- Unicode values allowed up to 10FFFFh
					value: make-char pos e
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
			{#"} s: [
				 escaped-char
				| ahead [non-printable-char | not-str-char]
				  (throw-error [char! skip s -2])
				  reject
				| skip (value: s/1)
			][
				{"}
				| (throw-error [char! skip s -2])
			]
		]

		line-string: [
			#"^"" s: any [
				{^^"}
				| ahead [#"^"" | newline-char] break
				| escaped-char
				| skip
			]
			e: #"^""
		]

		nested-curly-braces: [
			(cnt: 1)
			any [
				counted-newline 
				| "^^{"
				| "^^}"
				| #"{" (cnt: cnt + 1)
				| e: #"}" if (zero? cnt: cnt - 1) break
				| escaped-char
				| skip
			]
		]

		multiline-string: [
			#"{" s: nested-curly-braces (unless zero? cnt [throw-error [string! s]])
		]

		string-rule: [(type: string!) line-string | multiline-string]
		
		tag-rule: [
			#"<" not [not-tag-1st | ws] (type: tag!)
			 s: some [#"^"" thru #"^"" | #"'" thru #"'" | e: #">" break | skip]
			(if e/1 <> #">" [throw-error [tag! back s]])
		]
		
		email-rule: [
			s: some [ahead email-end break | skip] #"@"
			any [ahead email-end break | skip] e:
			(type: email!)
		]

		base-2-rule: [
			"2#{" (type: binary!) [
				s: any [counted-newline | 8 [#"0" | #"1" ] | ws-no-count | comment-rule] e: #"}"
				| (throw-error [binary! skip s -3])
			] (base: 2)
		]

		base-16-rule: [
			opt "16" "#{" (type: binary!) [
				s: any [counted-newline | 2 hexa-char | ws-no-count | comment-rule] e: #"}"
				| (throw-error [binary! skip s -2])
			] (base: 16)
		]

		base-64-rule: [
			"64#{" (type: binary! cnt: 0) [
				s: any [counted-newline | base64-char | ws-no-count (cnt: cnt + 1) | comment-rule] e: #"}"
				| (throw-error [binary! skip s -4])
			](
				cnt: (offset? s e) - cnt
				if all [0 < cnt cnt < 4][throw-error [binary! skip s -4]]
				base: 64
			)
		]

		binary-rule: [base-16-rule | base-64-rule | base-2-rule]

		file-rule: [
			s: #"%" [
				#"{" (throw-error [file! s])
				| line-string (process: make-string type: file!)
				| s: any [ahead [not-file-char | ws-no-count] break | skip] e:
				  (process: make-file type: file!)
			]
		]

		url-rule: [
			#":" not [not-url-char | ws-no-count | end]
			any [#"@" | #":" | ahead [not-file-char | ws-no-count] break | skip] e:
			(type: url! store stack do make-file)
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
			ahead #"/" (								;-- path detection barrier
				push-path stack type					;-- create empty path
				to-word stack copy/part s e word!		;-- push 1st path element
				type: path!
			)
			some [
				#"/"
				s: [
					integer-number-rule			(store stack make-number s e type)
					| begin-symbol-rule			(to-word stack copy/part s e word!)
					| paren-rule
					| #":" s: begin-symbol-rule	(to-word stack copy/part s e get-word!)
					;@@ add more datatypes here
					| (throw-error [path! path])
					  reject
				]
			]
			opt [#":" (type: set-path! set-path back tail stack)][
				ahead [path-end | ws-no-count | end] | (throw-error [type path])
			]
			(pop stack)
		]
		
		special-words: [
			#"%" [ws-no-count | ahead file-end | end] (value: "%")	;-- special case for remainder op!
			| #"/" ahead [slash-end | #"/" | ws-no-count | control-char | end][
				#"/" 
				ahead [slash-end | ws-no-count | control-char | end] (value: "//")
				| (value: "/")
			]
			| "<>" (value: "<>")
		]

		word-rule: 	[
			(type: word!) special-words	opt [#":" (type: set-word!)]
			(to-word stack value type)				;-- special case for / and // as words
			| path: s: begin-symbol-rule (type: word!) [
				url-rule
				| path-rule							;-- path matched
				| opt [#":" (type: set-word!)]
				  (if type [to-word stack copy/part s e type])	;-- word or set-word matched
			]
		]

		get-word-rule: [
			#":" (type: get-word!) [
				special-words (to-word stack value type)
				| s: begin-symbol-rule [
					path-rule (type: get-path!)
					| (to-word stack copy/part s e type)	;-- get-word matched
				]
			]
		]

		lit-word-rule: [
			#"'" (type: lit-word!) [
				special-words (to-word stack value type)
				| [
					s: begin-symbol-rule [
						path-rule (type: lit-path!)			 ;-- path matched
						| (to-word stack copy/part s e type) ;-- lit-word matched
					]
				]
			]
			opt [#":" (throw-error [type back s])]
		]

		issue-rule: [
			#"#" (type: issue!) s: symbol-rule (
				if (index? s) = index? e [throw-error [type skip s -4]]
				to-word stack copy/part s e type
			)
		]
		

		refinement-rule: [
			#"/" [
				some #"/" (type: word!) e:				;--  ///... case
				| ahead [not-word-char | ws-no-count | control-char] (type: word!) e: ;-- / case
				| symbol-rule (type: refinement! s: next s)
			]
			(to-word stack copy/part s e type)
		]
		
		sticky-word-rule: [								;-- protect from sticky words typos
			ahead [integer-end | ws-no-count | end | (throw-error [type s])]
		]
		hexa-rule: [2 8 hexa e: #"h" ahead [integer-end | ws-no-count | end]]

		tuple-value-rule: [byte 2 11 [#"." byte] e: (type: tuple!)]

		tuple-rule: [tuple-value-rule sticky-word-rule]
		
		time-rule: [
			s: positive-integer-rule [
				float-number-rule (value: make-time pos none value make-number s e type neg?) ;-- mm:ss.dd
				| (value2: make-number s e type) [
					#":" s: positive-integer-rule opt float-number-rule
					  (value: make-time pos value value2 make-number s e type neg?)		;-- hh:mm:ss[.dd]
					| (value: make-time pos value value2 none neg?)						;-- hh:mm
				]
			] (type: time!)
		]
		
		day-year-rule: [
			s: opt #"-" 3 4 digit e: (year: make-number s e integer!)
			| 1 2 digit e: (
				value: make-number s e integer!
				either day [year: value + pick [2000 1900] 50 > value][day: value]
			)
		]
		
		date-rule: [
			ahead [opt #"-" 1 4 digit date-sep | 8 digit #"T"][ ;-- quick lookhead
				s: 8 digit ee: #"T" (							;-- yyyymmddT
					year:  make-number s e: skip s 4 integer!
					month: make-number e e: skip e 2 integer!
					day:   make-number e e: skip e 2 integer!
					date:  make date! [day month year]
				) :ee
				| day-year-rule sep: date-sep (sep: sep/1) [
					s: 1 2 digit e: (month: make-number s e integer!)
					| case off month-rule (month: m)
					| case off mon-rule   (month: m)
				]
				sep day-year-rule [if (not all [day month year]) fail | none] (
					date: make date! [day month year]
				)
				| s: 4 digit #"-" (
					year: make-number s skip s 4 integer!
					date: make date! [1 1 year]
				)[
					"W" s: 2 digit (ee: none) opt [#"-" ee: non-zero] (	;-- yyyy-Www
						date/isoweek: make-number s skip s 2 integer!
						if ee [date/weekday: to integer! ee/1 - #"0"]	;-- yyyy-Www-d
					)
					| s: 3 digit (date/yearday: make-number s skip s 3 integer!) ;-- yyyy-ddd
				] (month: -1)
			](
				type: date!
				if all [
					month <> -1 any [date/year <> year date/month <> month date/day <> day]
				][throw-error [type pos]]
				day: month: year: none
			) opt [
				time-sep (ee: no) [
					s: 6 digit opt [#"." 1 9 digit ee:] (		;-- Thhmmss[.sss]
						hour: make-number s e: skip s 2 integer!
						mn:	  make-number e e: skip e 2 integer!
						date/time: either ee [
							sec: make-number e ee float!
							make-hmsf hour mn sec
						][
							sec: make-number e e: skip e 2 integer!
							make-hms hour mn sec
						]
					)
					| 4 digit (									;-- Thhmm
						hour: make-number s e: skip s 2 integer!
						mn:	  make-number e e: skip e 2 integer!
						date/time: make-hms hour mn 0
					)
					| s: positive-integer-rule (value: make-number s e integer!)
					#":" [(neg?: no) time-rule (date/time: value) | (throw-error [type pos])]
				]
				opt [
					#"Z" | [#"-" (neg?: yes) | #"+" (neg?: no)][
						s: 4 digit (							;-- +/-hhmm
							hour: make-number s e: skip s 2 integer!
							mn:   make-number e e: skip e 2 integer!
						)
						| 1 2 digit e: (hour: make-number s e integer! mn: none) ;-- +/-h, +/-hh
						opt [#":" s: 2 digit e: (mn: make-number s e integer!)]
					]
					(zone: make-hm hour any [mn 0] date/zone: either neg? [negate zone][zone])
				]
			] sticky-word-rule (value: date)
		]
		
		positive-integer-rule: [digit any digit e: (type: integer!)]

		integer-number-rule: [
			opt [#"-" (neg?: yes) | #"+" (neg?: no)] digit any [digit | #"'" digit] e:
			(type: integer!)
		]

		integer-rule: [
			float-special (value: make-number s e type)	;-- escape path for NaN, INFs
			| (neg?: no) integer-number-rule
			  opt [float-number-rule | float-exp-rule e: (type: float!)]
			  opt [#"%" (type: percent!)]
			  sticky-word-rule
			  (value: make-number s e type)
			  opt [
				[#"x" | #"X"] [s: integer-number-rule | (throw-error [pair! pos])]
				ahead [pair-end | ws-no-count | end | (throw-error [pair! pos])]
				(value: as-pair value make-number s e type)
			  ]
			  opt [#":" [time-rule | (throw-error [type pos])]]
		]

		float-special: [
			s: opt #"-" "1.#" [
				[[#"N" | #"n"] [#"a" | #"A"] [#"N" | #"n"]]
				| [[#"I" | #"i"] [#"N" | #"n"] [#"F" | #"f"]]
			] e: (type: float!)
		]

		float-exp-rule: [[#"e" | #"E"] opt [#"-" | #"+"] 1 3 digit]

		float-number-rule: [
			[#"." | #","] digit any [digit | #"'" digit]
			opt float-exp-rule e: (type: float!)
		]

		float-rule: [
			opt [#"-" | #"+"] float-number-rule
			opt [#"%" (type: percent!)]
			sticky-word-rule
		]
		
		map-rule: [
			"#(" (append/only stack make block! 100)
			any-value
			#")" (
				value: back tail stack
				value/1: make map! value/1
				pop stack
				old-line: line
			)
		]

		block-rule: [
			#"[" (
				append/only stack make block! 100
				if line > old-line [old-line: line new-line back tail stack]
			)
			any-value
			#"]" (
				pop stack
				old-line: line
			)
		]

		paren-rule: [
			#"(" (
				append/only stack make paren! 4
				if line > old-line [old-line: line new-line back tail stack]
			)
			any-value 
			#")" (
				pop stack
				old-line: line
			)
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

		comment-rule: [#";" [to #"^/" | to end] (old-line: line)]

		wrong-end: [(
				ending: either 1 < length? stack [
					value: switch type?/word last stack [
						block! [#"]"]
						paren! [#")"]
					]
					quote (throw-error/missing [value pos])
				][none]
			)
			ending
		]

		literal-value: [
			pos: (e: none) s: [
				 string-rule		(store stack do make-string)
				| block-rule
				| comment-rule
				| tuple-rule		(store stack make-tuple s e)
				| hexa-rule			(store stack make-hexa s e)
				| binary-rule		if (value: make-binary s e base) (store stack value)
				| email-rule		(store stack do make-file)
				| date-rule			if (value) (store stack value)
				| integer-rule		if (value) (store stack value)
				| float-rule		if (value: make-float s e type) (store stack value)
				| tag-rule			(store stack do make-string)
				| word-rule
				| lit-word-rule
				| get-word-rule
				| refinement-rule
				| file-rule			(store stack value: do process)
				| char-rule			(store stack value)
				| map-rule
				| paren-rule
				| escaped-rule		(store stack value)
				| issue-rule
			](
				if line > old-line [
					old-line: line 
					new-line back tail last stack
				]
			)
		]

		one-value: [any ws pos: opt literal-value pos: to end opt wrong-end]
		any-value: [pos: any [some ws | literal-value]]
		red-rules: [any-value any ws opt wrong-end]

		if pre-load [do [pre-load src length]]
		
		set/any 'err try [
			unless either part [
				parse/case/part src red-rules length
			][
				parse/case src either one [one-value][red-rules]
			][
				throw-error ['value pos]
			]
		]	
		either trap [
			reduce [stack/1 pos :err]
		][
			if error? :err [do :err]
			either all [one not only][pos][stack/1]
		]
	]
]
