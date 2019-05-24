Red [
    File:    %common.red
    Title:   "JSON codec common code"
    Date:    9-Aug-2018
    Version: 0.0.2
	Author: [
		"Gregg Irwin" {
			Ported from %json.r by Romano Paolo Tenca, Douglas Crockford, 
			and Gregg Irwin.
			Further research: json libs by Chris Ross-Gill, Kaj de Vos, and
			@WiseGenius.
		}
        "Gabriele Santilli" {
            Refactoring and minor improvements.
        }
	]
	History: [
		0.0.1 10-Sep-2016 "First release. Based on %json.r"    Gregg
        0.0.2  9-Aug-2018 "Refactoring and minor improvements" Gabriele
	]
	License: [
		http://www.apache.org/licenses/LICENSE-2.0 
		and "The Software shall be used for Good, not Evil."
	]
]

export: func [
    "Export a value to the global context"
    'word [set-word!]
    value
    /to ctx [any-word! any-object! function!]
] [
    set word :value
    unless :ctx [ctx: system/words]
    set bind word ctx :value
]

json-common: context [
	;-----------------------------------------------------------
	;-- Generic support funcs

	BOM: [
		UTF-8		#{EFBBBF}
		UTF-16-BE	#{FEFF}
		UTF-16-LE	#{FFFE}
		UTF-32-BE	#{0000FEFF}
		UTF-32-LE	#{FFFE0000}
	]

	BOM-UTF-16?: func [data [string! binary!]][
		any [find/match data BOM/UTF-16-BE  find/match data BOM/UTF-16-LE]
	]

	BOM-UTF-32?: func [data [string! binary!]][
		any [find/match data BOM/UTF-32-BE  find/match data BOM/UTF-32-LE]
	]


	; MOLD adds quotes string!, but not all any-string! values.
	enquote: func [str [string!] "(modified)"][append insert str {"} {"}]

	high-surrogate?: func [codepoint [integer!]][
        all [codepoint >= D800h  codepoint <= DBFFh]
    ]
    
	low-surrogate?: func [codepoint [integer!]][
        all [codepoint >= DC00h  codepoint <= DFFFh]
    ]
    
	translit: func [
		"Tansliterate sub-strings in a string"
		string [string!] "Input (modified)"
		rule   [block! bitset!] "What to change"
		xlat   [block! function!] "Translation table or function. MUST map a string! to a string!."
		/local val
	][
		parse string [
			some [
				change copy val rule (val either block? :xlat [xlat/:val][xlat val])
				| skip
			]
		]
		string
	]

	;-----------------------------------------------------------
	;-- JSON backslash escaping

	;TBD: I think this can be improved. --Gregg
		
	json-to-red-escape-table: [
	;   JSON Red
		{\"} "^""
		{\\} "\"
		{\/} "/"
		{\b} "^H"   ; #"^(back)"
		{\f} "^L"   ; #"^(page)"
		{\n} "^/"
		{\r} "^M"
		{\t} "^-"
	]
	red-to-json-escape-table: reverse copy json-to-red-escape-table
	
	json-esc-ch: charset {"t\/nrbf}             ; Backslash escaped JSON chars
	json-escaped: [#"\" json-esc-ch]			; Backslash escape rule
	red-esc-ch: charset {^"^-\/^/^M^H^L}        ; Red chars requiring JSON backslash escapes

	decode-backslash-escapes: func [string [string!] "(modified)"][
		translit string json-escaped json-to-red-escape-table
	]

	encode-backslash-escapes: func [string [string!] "(modified)"][
		translit string red-esc-ch red-to-json-escape-table
	]

	ctrl-char: charset [#"^@" - #"^_"]			; Control chars 0-31
]
