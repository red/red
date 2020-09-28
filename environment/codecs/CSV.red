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

	; -- main functions
	set 'load-csv function [
		"Converts CSV text to a block of rows, where each row is a block of fields."
		data [string!] "Text CSV data to load"
		/with
			delimiter [char! string!] "Delimiter to use (default is comma)"
		/header		"Treat first line as header; implies /as-columns if /as-records is not used"
		/as-columns	"Returns named columns; default names if /header is not used"
		/as-records	"Returns records instead of rows; implies /header"
		/flat		"Returns a flat block; you need to know the number of fields"
		/trim		"Ignore spaces between quotes and delimiter"
		/quote
			qt-char [char!] "Use different character for quotes than double quote (^")"
		/extern
			quote-char
	] [
		; -- check for disallowed combination of refinements
		disallowed: [
			[as-columns as-records][flat as-columns][flat as-records][flat header]
		]
		foreach refs disallowed [
			if all refs [
				return make error! rejoin [
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
		line: make block! 20
		value: make string! 200

		; -- parse rules
		newline: [crlf | lf | cr]
		quotchars: charset reduce ['not quote-char]
		valchars: charset reduce ['not append copy "^/^M" delimiter]
		quoted-value: [
			(clear value) [
				quote-char
				any [
					[
						set char quotchars
					|	quote-char quote-char (char: quote-char)
					]
					(append value char)
				]
				quote-char
			]
		]
		normal-value: [s: any valchars e: (value: copy/part s e)]
		single-value: [quoted-value | normal-value]
		values: [any [single-value delimiter add-value] single-value add-value]
		add-value: [(
			if trim [
				value: system/words/trim value
				all [
					quote-char = first value
					quote-char = last value
					take value
					take/last value
				]
			]
			append line copy value
		)]
		add-line: [
			(
				; remove last empty element, when required
				all [
					ignore-empty?
					empty? last line
					take/last line
				]
				; check for longest line
				length: length? line
				if zero? longest [longest: length]		; first line
				if all [strict? longest <> length][
					return make error! non-aligned
				]
				if longest < length [longest: length]
				either as-records [
					; extend header when needed
					if longest > length? header [
						loop longest - (length? header) [
							append header next-column-name last header
						]
					]
					; append line to output
					value: make map! length
					repeat index length [
						value/(header/:index): line/:index
					]
					append output copy value
				][
					either flat [
						append output copy line
					][
						append/only output copy line
					]
				]
			)
			init
		]
		line-rule: [values [newline | end] add-line]
		init: [(clear line)]

		; -- main code
		parsed?: parse data [
			opt [
				if (header) 
				values newline
				(header: copy line)
				init
			]
			mark: (
				if all [
					header 
					any [
						equal? mark head mark
						empty? mark
					]
				][do make error! "CSV data are too small to use /HEADER refinement"]
			)
			; -- Prepare default header (will be expanded when necessary)
			(unless header [header: make-header 1])
			[
				init some line-rule
			|	init values add-line
			]
			any newline
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
