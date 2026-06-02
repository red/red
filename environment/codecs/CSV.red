Red [
	Title: "CSV codec"
	Author: "Boleslav Březovský"
	Rights:  "Copyright (C) 2015-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Resources: [
		https://tools.ietf.org/html/rfc4180
		https://www.python.org/dev/peps/pep-0305/
	]
	Documentation: https://github.com/red/red/wiki/CSV-codec 
]

put system/codecs 'csv context [
	Title:     "CSV codec"
	Name:      'CSV
	Mime-Type: [text/csv]
	Suffixes:  [%.csv]
	encode: func [data [any-type!] where [file! url! none!]] [
		to-csv data
	]
	decode: func [text [string! binary! file!]] [
		if file? text [text: read text]
		if binary? text [text: to string! text]
		load-csv text
	]
]

context [
	; -- state variables
	ignore-empty?: false ; If line ends with delimiter, do not add empty string
	strict?: true		; Throw error on non-aligned records
	quote-char: #"^""
	double-quote: {""}
	quotable-chars: charset { ",^/}

	; -- internal values
	parsed?: none		; Keep state of parse result (for debugging purposes)
	non-aligned: "Data are not aligned"

	; -- support functions
	to-csv-line: function [
		"Join values as a string and put delimiter between them"
		data		[block!]		"Series to join"
		delimiter	[char! string!]	"Delimiter to put between values"
	][
		collect/into [
			while [not tail? next data][
				keep escape-value first data delimiter
				keep delimiter
				data: next data
			]
			keep escape-value first data delimiter
			keep newline
		] clear ""
	]


	escape-value: function [
		"Escape quotes and when required, enclose value in quotes"
		value		[any-type!]		"Value to escape (is formed)"
		delimiter	[char! string!]	"Delimiter character to be escaped"
		/extern quote-char double-quote quotable-chars
	][
		quot?: false
		value: form value
		len: length? value
		replace/all value quote-char double-quote
		unless equal? len length? value [quot?: true]
		if find value quotable-chars [quot?: true]
		if quot? [
			insert value quote-char
			append value quote-char
		]
		value
	]

	next-column-name: function [
		"Return name of next column (A->B, Z->AA, ...)"
		name	[char! string!]	"Name of current column"
	][
		name: copy name
		length: length? name
		repeat index length [
			position: length - index + 1
			previous: position - 1
			either equal? #"Z" name/:position [
				name/:position: #"A"
				if position = 1 [
					insert name #"A"
				]
			][
				name/:position: name/:position + 1
				break
			]
		]
		name
	]

	make-header: function [
		"Return default header (A-Z, AA-ZZ, ...)"
		length [integer!] "Required length of header"
	][
		key: copy "A"
		collect [
			keep copy key
			loop length - 1 [
				keep key: next-column-name key
			]
		]
	]

	get-columns: func [
		"Return all keywords from maps or objects"
		data [block!] "Data must block of maps or objects"
		/local columns
	][
		columns: words-of data/1
		foreach value data [
			append columns difference columns words-of value 
		]
		columns
	]

	encode-map: function [
		"Make CSV string from map! of columns"
		data		[map!] "Map of columns"
		delimiter	[char! string!]	"Delimiter to use in CSV string"
	][
		output: make string! 1000
		keys: keys-of data
		append output to-csv-line keys delimiter
		length: length? select data first keys
		if strict? [
			foreach key keys [
				if length <> length? select data key [
					return make error! non-aligned
				]
			]
		]
		repeat index length? select data first keys [
			line: make string! 100
			append output to-csv-line collect [
				foreach key keys [keep data/:key/:index]
			] delimiter
		]
		output
	]

	encode-maps: function [
		"Make CSV string from block of maps/objects"
		data		[block!] "Block of maps/objects"
		delimiter	[char! string!]	"Delimiter to use in CSV string"
	][
		columns: get-columns data
		collect/into [
			keep to-csv-line columns delimiter
			foreach value data [
				; construct block
				line: collect [
					foreach column columns [
						keep either value/:column [value/:column][""]
					]
				]
				keep to-csv-line line delimiter
			]		
		] make string! 1000
	]

	encode-flat: function [
		"Convert block of fixed size records to CSV string"
		data		[block!]		"Block treated as fixed size records"
		delimiter	[char! string!]	"Delimiter to use in CSV string"
		size		[integer!]		"Size of record"
	][
		unless zero? (length? data) // size [
			return make error! non-aligned
		]
		collect/into [
			until [
				keep to-csv-line copy/part data size delimiter
				tail? data: skip data size
			]
		] make string! 1000
	]

	encode-blocks: function [
		"Convert block of records to CSV string"
		data		[block!] "Block of blocks, each block is one record"
		delimiter	[char! string!] "Delimiter to use in CSV string"
	][
		length: length? first data
		collect/into [
			foreach line data [
				if length <> length? line [return make error! non-aligned]
				csv-line: to-csv-line line delimiter
				keep csv-line
			]
		] make string! 1000
	]

	csv-add-issue: func [
		errors	[block!]
		type	[word!]
		line	[integer!]
		column	[integer!]
		action	[word!]
		source	[string!]
		/local issue
	][
		issue: make object! [
			type:	none
			line:	none
			column: none
			action: none
			source: none
		]
		issue/type: type
		issue/line: line
		issue/column: column
		issue/action: action
		issue/source: copy source
		append/only errors issue
	]

	csv-newline-size?: func [pos [string!]][
		case [
			zero? length? pos [0]
			pos/1 = #"^/" [1]
			pos/1 = #"^M" [
				either all [1 < length? pos pos/2 = #"^/"][2][1]
			]
			true [0]
		]
	]

	csv-advance-char: func [
		pos		[string!]
		state	[block!]
		/local n
	][
		n: csv-newline-size? pos
		either zero? n [
			state/2: state/2 + 1
			next pos
		][
			state/1: state/1 + 1
			state/2: 1
			skip pos n
		]
	]

	csv-consume-newline: func [
		pos		[string!]
		state	[block!]
		/local n
	][
		n: csv-newline-size? pos
		state/1: state/1 + 1
		state/2: 1
		skip pos n
	]

	csv-at-delimiter?: func [
		pos		 [string!]
		delimiter [char! string!]
	][
		not not find/match pos delimiter
	]

	csv-consume-delimiter: func [
		pos			 [string!]
		delimiter-size [integer!]
		state		 [block!]
	][
		state/2: state/2 + delimiter-size
		skip pos delimiter-size
	]

	csv-space?: func [ch [char!]][
		any [ch = space ch = tab]
	]

	csv-line-end: func [pos [string!] /local lf-pos cr-pos][
		lf-pos: find pos #"^/"
		cr-pos: find pos #"^M"
		case [
			all [lf-pos cr-pos][either lf-pos < cr-pos [lf-pos][cr-pos]]
			lf-pos [lf-pos]
			cr-pos [cr-pos]
			true [skip pos length? pos]
		]
	]

	csv-finish-value: func [
		row		 [block!]
		value	 [string!]
		do-trim? [logic!]
		quote	 [char!]
	][
		if do-trim? [
			value: system/words/trim value
			all [
				not empty? value
				quote = first value
				quote = last value
				take value
				take/last value
			]
		]
		append row copy value
		clear value
	]

	csv-parse-row: func [
		pos			 [string!]
		delimiter	 [char! string!]
		delimiter-size [integer!]
		quote		 [char!]
		do-trim?	 [logic!]
		recover?	 [logic!]
		scan-state	 [block!]
		return:		 [block!]
		/local result row val start src-end state n probe line column ch next-pos
	][
		result: reduce [no none none none none none none make block! 2]
		row: make block! 20
		val: make string! 200
		start: pos
		line: scan-state/1
		column: scan-state/2
		state: 'start-field

		forever [
			if zero? length? pos [
				if state = 'quoted-field [
					result/5: 'unterminated-quote
					result/6: line
					result/7: column
					result/4: copy/part start pos
					break
				]
				csv-finish-value row val do-trim? quote
				result/1: yes
				result/2: row
				result/3: pos
				result/4: copy/part start pos
				break
			]

			n: csv-newline-size? pos
			ch: pos/1

			if state = 'start-field [
				either csv-at-delimiter? pos delimiter [
					csv-finish-value row val do-trim? quote
					pos: csv-consume-delimiter pos delimiter-size scan-state
				][either n <> 0 [
					csv-finish-value row val do-trim? quote
					src-end: pos
					pos: csv-consume-newline pos scan-state
					result/1: yes
					result/2: row
					result/3: pos
					result/4: copy/part start src-end
					break
				][either ch = quote [
					state: 'quoted-field
					pos: csv-advance-char pos scan-state
				][
					append val ch
					state: 'unquoted-field
					pos: csv-advance-char pos scan-state
				]]]
				continue
			]

			if state = 'unquoted-field [
				either csv-at-delimiter? pos delimiter [
					csv-finish-value row val do-trim? quote
					state: 'start-field
					pos: csv-consume-delimiter pos delimiter-size scan-state
				][either n <> 0 [
					csv-finish-value row val do-trim? quote
					src-end: pos
					pos: csv-consume-newline pos scan-state
					result/1: yes
					result/2: row
					result/3: pos
					result/4: copy/part start src-end
					break
				][
					append val ch
					pos: csv-advance-char pos scan-state
				]]
				continue
			]

			if state = 'quoted-field [
				either ch = quote [
					either all [1 < length? pos pos/2 = quote][
						append val quote
						next-pos: csv-advance-char pos scan-state
						pos: csv-advance-char next-pos scan-state
					][
						state: 'quote-closed
						pos: csv-advance-char pos scan-state
					]
				][
					append val ch
					pos: csv-advance-char pos scan-state
				]
				continue
			]

			if state = 'quote-closed [
				either csv-at-delimiter? pos delimiter [
					csv-finish-value row val do-trim? quote
					state: 'start-field
					pos: csv-consume-delimiter pos delimiter-size scan-state
				][either n <> 0 [
					csv-finish-value row val do-trim? quote
					src-end: pos
					pos: csv-consume-newline pos scan-state
					result/1: yes
					result/2: row
					result/3: pos
					result/4: copy/part start src-end
					break
				][either csv-space? ch [
					probe: pos
					while [all [not zero? length? probe csv-space? probe/1]][probe: next probe]
					either any [
						zero? length? probe
						csv-at-delimiter? probe delimiter
						(csv-newline-size? probe) <> 0
					][
						either recover? [
							append/only result/8 reduce [
								'whitespace-after-quote scan-state/1 scan-state/2 'repaired
							]
							while [pos <> probe][pos: csv-advance-char pos scan-state]
						][
							result/5: 'unexpected-after-quote
							result/6: scan-state/1
							result/7: scan-state/2
							result/4: copy/part start (csv-line-end pos)
							break
						]
					][
						result/5: 'unexpected-after-quote
						result/6: scan-state/1
						result/7: scan-state/2
						result/4: copy/part start (csv-line-end pos)
						break
					]
				][
					result/5: 'unexpected-after-quote
					result/6: scan-state/1
					result/7: scan-state/2
					result/4: copy/part start (csv-line-end pos)
					break
				]]]
				continue
			]
		]
		result
	]

	; -- main functions
	set 'load-csv function [
		"Converts CSV text to a block of rows, where each row is a block of fields."
		data [string!] "Text CSV data to load"
		/with
			delimiter [char! string!] "Delimiter to use (default is comma)"
		/header		"Treat first line as header; implies /as-columns if /as-records is not used"
		/as-columns	"Returns named columns; default names if /header is not used"
		/as-records	"Returns records instead of rows; default names if /header is not used"
		/flat		"Returns a flat block; you need to know the number of fields"
		/trim		"Ignore spaces between quotes and delimiter"
		/quote
			qt-char [char!] "Use different character for quotes than double quote (^")"
		/recover
			errors [block!] "Collect recoverable CSV issues and continue loading"
			/local
				disallowed refs output out-map longest record delimiter-size
				cursor parsed-row row-line scan-state row source length
				missing issue? repair key-index key
		/extern
			quote-char
	] [
		; -- check for disallowed combination of refinements
		disallowed: [
			[as-columns as-records][flat as-columns][flat as-records][flat header]
		]
		foreach refs disallowed [
			if all refs [
				do make error! rejoin [
					"Cannot use /" refs/1 " and /" refs/2 " refinements together"
				]
			]
		]
		if all [header not as-records][as-columns: true]

		; -- init local values
		delimiter: any [delimiter comma]
		quote-char: any [qt-char #"^""]
		output: make block! (length? data) / 80
		out-map: make map! []
		longest: 0
		record: none
		scan-state: reduce [1 1]
		delimiter-size: either char? delimiter [1][length? delimiter]

		; -- main code
		cursor: data
		if header [
			if zero? length? cursor [
				do make error! "CSV data are too small to use /HEADER refinement"
			]
			parsed-row: csv-parse-row cursor delimiter delimiter-size quote-char trim recover scan-state
			either parsed-row/1 [
				header: parsed-row/2
				longest: length? header
				foreach repair parsed-row/8 [
					csv-add-issue errors repair/1 repair/2 repair/3 repair/4 parsed-row/4
				]
				cursor: parsed-row/3
				if zero? length? cursor [
					do make error! "CSV data are too small to use /HEADER refinement"
				]
			][
				either recover [
					csv-add-issue errors parsed-row/5 parsed-row/6 parsed-row/7 'skipped parsed-row/4
					cursor: csv-consume-newline csv-line-end cursor scan-state
				][
					do make error! rejoin ["Invalid CSV data near line " parsed-row/6]
				]
			]
		]
		unless header [header: make-header 1]
		while [not zero? length? cursor][
			row-line: scan-state/1
			parsed-row: csv-parse-row cursor delimiter delimiter-size quote-char trim recover scan-state
			either parsed-row/1 [
				row: parsed-row/2
				source: parsed-row/4
				issue?: no
				foreach repair parsed-row/8 [
					csv-add-issue errors repair/1 repair/2 repair/3 repair/4 source
				]
				length: length? row
				if zero? longest [longest: length]
				if longest <> length [
					either recover [
						either length < longest [
							missing: longest - length
							loop missing [append row ""]
							csv-add-issue errors 'short-row row-line 1 'padded source
							length: longest
						][
							csv-add-issue errors 'long-row row-line 1 'skipped source
							issue?: yes
						]
					][
						do make error! non-aligned
					]
				]
				unless issue? [
					if longest < length [longest: length]
					either as-records [
						if longest > length? header [
							loop longest - (length? header) [
								append header next-column-name last header
							]
						]
						record: make map! length
						repeat index length [
							record/(header/:index): row/:index
						]
						append output record
					][
						either flat [
							append output copy row
						][
							append/only output copy row
						]
					]
				]
				cursor: parsed-row/3
			][
				either recover [
					csv-add-issue errors parsed-row/5 parsed-row/6 parsed-row/7 'skipped parsed-row/4
					cursor: csv-consume-newline csv-line-end cursor scan-state
				][
					do make error! rejoin ["Invalid CSV data near line " parsed-row/6]
				]
			]
		]

		; -- adjust output when needed
		if as-columns [
			; TODO: do not use first, but longest line
			key-index: 0
			if longest > length? header [
				header: make-header longest
			]
			foreach key header [
				key-index: key-index + 1
				out-map/:key: make block! length? output
				foreach line output [append out-map/:key line/:key-index]
			]
			output: out-map
		]
		output
	]

	set 'to-csv function [
		"Make CSV data from input value"
		data [block! map! object!] "May be block of fixed size records, block of block records, or map columns"
		/with "Delimiter to use (default is comma)"
			delimiter [char! string!]
		/skip	"Treat block as table of records with fixed length"
			size [integer!]
		/quote
			qt-char [char!] "Use different character for quotes than double quote (^")"
		/extern
			quote-char double-quote quotable-chars
	][
		; Initialization
		longest: 0
		delimiter: any [delimiter comma]
		quote-char: any [qt-char #"^""]
		double-quote: rejoin [quote-char quote-char]
		quotable-chars: charset rejoin [space newline quote-char delimiter]
		if any [map? data object? data][return encode-map data delimiter]
		if skip [return encode-flat data delimiter size]
		keyval?: any [map? first data object? first data]
		unless any [
			block? first data
			keyval?
		][data: reduce [data]] ; Only one line

		; -- check if it's block of maps/objects
		types: unique collect [foreach value data [keep type? value]]
		either all [
			1 = length? types
			keyval?
		][
			; -- this is block of maps
			encode-maps data delimiter
		][
			; this is block of blocks
			encode-blocks data delimiter
		]
	]
]
