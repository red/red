Red [
    Title:   "JSON codec"
    Author:  "Gabriele Santilli"
    File:    %JSON.red
    Purpose: "Adds JSON as a valid data type to use with LOAD/AS and SAVE/AS"
	Rights:  "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

; -- load-json

context [
	;-----------------------------------------------------------
	;-- JSON decoder
	;-----------------------------------------------------------

	;# Basic rules
	ws:  charset " ^-^/^M"						; Whitespace
	ws*: [any ws]
	ws+: [some ws]
	sep: [ws* #"," ws*]							; JSON value separator
	digit: charset "0123456789"
	non-zero-digit: charset "123456789"
	hex-char:  charset "0123456789ABCDEFabcdef"
	chars: charset [not {\"} #"^@" - #"^_"]		; Unescaped chars (NOT creates a virtual bitset)

    ; chars allowed in Red word! values - note that we don't allow < and > at all even though they are somewhat valid in word!
    not-word-char: charset {/\^^,[](){}"#%$@:;^/^(00A0) ^-^M<>}
    word-1st: complement append union not-word-char digit #"'"
    word-char: complement not-word-char

	;-----------------------------------------------------------
	;-- JSON value rules
	;-----------------------------------------------------------
	
	;-----------------------------------------------------------
	;-- Number
	sign: [#"-"]
	; Integers can't have leading zeros, but zero by itself is valid.
	int:  [[non-zero-digit any digit] | digit]
	frac: [#"." some digit]
	exp:  [[#"e" | #"E"] opt [#"+" | #"-"] some digit]
	number: [opt sign  int  opt frac  opt exp]
	numeric-literal: :number
	
	;-----------------------------------------------------------
	;-- String
	string-literal: [
		#"^"" _s:
			any [some chars | #"\" [#"u" 4 hex-char | json-esc-ch]]
		_e: #"^""
		(_str: either _s =? _e [copy ""][unescape copy/part _s _e])
	]

	decode-unicode-char: func [
		"Convert \uxxxx format (NOT simple JSON backslash escapes) to a Unicode char"
		ch [string!] "4 hex digits"
	][
		buf: {#"^^(0000)"}								; Don't COPY buffer, reuse it
		append append/part clear at buf 5 ch 4 {)"}		; Replace 0000 section in buf
		attempt [transcode/one buf]
	]

	json-esc-ch: charset {"t\/nrbf}             ; Backslash escaped JSON chars
	json-escaped: [#"\" json-esc-ch]			; Backslash escape rule

	json-to-red-escape-table: [
		#"\" [
			keep #"^""
		|	keep #"\"
		|	keep #"/"
		|	#"b"  keep (#"^H")   ; #"^(back)"
		|	#"f"  keep (#"^L")   ; #"^(page)"
		|	#"n"  keep (#"^/")
		|	#"r"  keep (#"^M")
		|	#"t"  keep (#"^-")
		|	#"u"  _s: 4 hex-char keep (decode-unicode-char _s)
		]
	]

	unescape: routine [
		str [string!] "(modified)"
		return: [string!]
		/local
			s s2 [series!]
			src tail [byte-ptr!]
			unit index c1 c2 dst [integer!]
	][
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		src: (as byte-ptr! s/offset) + (str/head << (log-b unit))
		dst: str/head
		tail: as byte-ptr! s/tail
		while [src < tail] [
			c1: string/get-char src unit
			as-byte c1
			src: src + unit
			either c1 <> as-integer #"\" [
				string/overwrite-char s dst c1
				dst: dst + 1
			][
				c2: string/get-char src unit
				as-byte c2
				src: src + unit
				c2: switch c2 [
					#"^"" #"\" #"/" [c2]
					#"b" [as-integer #"^H"]   ; #"^(back)"
					#"f" [as-integer #"^L"]   ; #"^(page)"
					#"n" [as-integer #"^/"]
					#"r" [as-integer #"^M"]
					#"t" [as-integer #"^-"]
					#"u" [
						c2: 0
						loop 4 [
							c1: string/get-char src unit
							src: src + unit
							case [
								all [(as-integer #"0") <= c1 c1 <= (as-integer #"9")] [c1: c1 - as-integer #"0"]
								all [(as-integer #"A") <= c1 c1 <= (as-integer #"F")] [c1: c1 - as-integer #"7"]	;-- #"7" = #"A" - 10
								all [(as-integer #"a") <= c1 c1 <= (as-integer #"f")] [c1: c1 - as-integer #"W"]	;-- #"W" = #"a" - 10
								true [fire [TO_ERROR(script invalid-char) char/push c1]]
							]
							c2: c2 << 4 + c1
						]
						c2
					]
					default [							;-- pass both chars
						string/overwrite-char s dst c1
						dst: dst + 1
					]
				]
				s2: string/overwrite-char s dst c2
				dst: dst + 1
				if s <> s2 [							;-- 's' could have been expanded
					index: (as-integer src - (as byte-ptr! s/offset)) >> (log-b unit)
					unit: GET_UNIT(s2)
					src: (as byte-ptr! s2/offset) + (index << (log-b unit))
					tail: as byte-ptr! s2/tail
					s: s2
				]
			]
		]
		s/tail: as red-value! (as byte-ptr! s/offset) + (dst << (log-b unit))
		str
	]

	;-----------------------------------------------------------
	;-- Object		
	json-object: [
		; Emit a new block to our output target, and push it on our
		; working stack, to handle nested structures. Emit returns
		; the insertion point for another value to go out into '_res,
		; but we want the target to be the block we just added, so
		; we reset '_res to that after 'emit is done.
		#"{" (push emit _tmp: copy []  _res: _tmp)
		ws* opt property-list
		; This is a little confusing. We're at the tail of our current
		; output target, which is on our stack. We pop that, then need
		; to back up one, which puts us AT the block of values we 
		; collected for this object in our output target. i.e., the 
		; values are in a sub-block at the first position now. We use
		; that (FIRST) to make a map! and replace the block of values
		; with the map! we just made. Note that a map is treated as a
		; single value, like an object. Using a block as the new value
		; requires using `change/only`.
		#"}" (
			_res: back pop
			_res: change _res make map! first _res
		)
	]
	
	property-list: [property any [sep property]]
	property: [json-name (emit either parse _str [word-1st any word-char] [to word! _str] [_str]) json-value]
	json-name: [ws* string-literal ws* #":"]
	
	;-----------------------------------------------------------
	;-- List
	array-list: [json-value any [sep json-value]]
	json-array: [
		; Emit a new block to our output target, and push it on our
		; working stack, to handle nested structures. Emit returns
		; the insertion point for another value to go out into '_res,
		; but we want the target to be the block we just added, so
		; we reset '_res to that after 'emit is done.
		#"[" (push emit _tmp: copy []  _res: _tmp)
		ws* opt array-list
		#"]" (_res: pop)
	]

	;-----------------------------------------------------------
	;-- Any JSON Value (top level JSON parse rule)
	json-value: [
		ws*
		[
			"true"    (emit true)							; Literals must be lowercase
			| "false" (emit false)
			| "null"  (emit none)
			| json-object
			| json-array
			| string-literal (emit _str)
			| copy _str numeric-literal (emit load _str)	; Number
			mark:   										; Set mark for failure location
		]
		ws*
	]

	;-----------------------------------------------------------
	;-- Decoder data structures

	; The stack is used to handle nested structures (objects and lists)
	stack: copy []
	push:  func [val][append/only stack val]
	pop:   does [take/last stack]

	_out: none	; Our overall output target/result                          
	_res: none	; The current output position where new values are inserted
	_tmp: none  ; Temporary
	_str: none	; Where string value parse results go               
	_s: _e: none	; String end markers
	mark: none	; Current parse position
	
	; Add a new value to our output target, and set the position for
	; the next emit to the tail of the insertion.
	;!! I really don't like how this updates _res as a side effect. --Gregg
	emit: func [value][_res: insert/only _res value]

	;-----------------------------------------------------------
	;-- Main decoder func

    set 'load-json func [
        "Convert a JSON string to Red data"
        input [string!] "The JSON string"
    ] [
		_out: _res: copy []		; These point to the same position to start with
		mark: input
		either parse/case input json-value [pick _out 1] [
			make error! form reduce [
				"Invalid json string. Near:"
				either tail? mark ["<end of input>"] [mold copy/part mark 40]
			]
		]
	]
]
; -- to-json

context [
    indent: none
    indent-level: 0
    normal-chars: none
    escapes: #(
        #"^"" {\"}
        #"\"  "\\"
        #"^H" "\b"
        #"^L" "\f"
        #"^/" "\n"
        #"^M" "\r"
        #"^-" "\t"
    )

    init-state: func [ind ascii?] [
        indent: ind
        indent-level: 0
        ; 34 is double quote "
        ; 92 is backslash \
        normal-chars: either ascii? [
            charset [32 33 35 - 91 93 - 127]
        ] [
            complement charset [0 - 31 34 92]
        ]
    ]

    emit-indent: func [output level] [
        indent-level: indent-level + level
        append/dup output indent indent-level
    ]

    emit-key-value: function [output sep map key] [
        value: select/case map :key
        if any-word? :key [key: form key]
        unless string? :key [key: mold :key]
        red-to-json-value output key
        append output sep
        red-to-json-value output :value
    ]

    red-to-json-value: function [output value] [
        special-char: none
        switch/default type?/word :value [
            none!           [append output "null"]
            logic!          [append output pick ["true" "false"] value]
            integer! float! [append output value]
            percent!        [append output to float! value]
            string! [
                append output #"^""
                parse value [
                    any [
                        mark1: some normal-chars mark2: (append/part output mark1 mark2)
                        |
                        set special-char skip (
                            either escape: select escapes special-char [
                                append output escape
                            ] [
                                insert insert tail output "\u" to-hex/size to integer! special-char 4
                            ]
                        )
                    ]
                ]
                append output #"^""
            ]
            block! [
                either empty? value [
                    append output "[]"
                ] [
                    either indent [
                        append output "[^/"
                        emit-indent output +1
                        red-to-json-value output first value
                        foreach v next value [
                            append output ",^/"
                            append/dup output indent indent-level
                            red-to-json-value output :v
                        ]
                        append output #"^/"
                        emit-indent output -1
                    ] [
                        append output #"["
                        red-to-json-value output first value
                        foreach v next value [
                            append output #","
                            red-to-json-value output :v
                        ]
                    ]
                    append output #"]"
                ]
            ]
            map! object! [
                keys: words-of value
                either empty? keys [
                    append output "{}"
                ] [
                    either indent [
                        append output "{^/" ; }
                        emit-indent output +1
                        emit-key-value output ": " value first keys
                        foreach k next keys [
                            append output ",^/"
                            append/dup output indent indent-level
                            emit-key-value output ": " value :k
                        ]
                        append output #"^/"
                        emit-indent output -1
                    ] [
                        append output #"{" ; }
                        emit-key-value output #":" value first keys
                        foreach k next keys [
                            append output #","
                            emit-key-value output #":" value :k
                        ]
                    ]
                    append output #"}"
                ]
            ]
        ] [
            red-to-json-value output either any-block? :value [
                to block! :value
            ] [
                either any-string? :value [form value] [mold :value]
            ]
        ]
        output
    ]

    set 'to-json function [
        "Convert Red data to a JSON string"
        data
        /pretty indent [string!] "Pretty format the output, using given indentation"
        /ascii "Force ASCII output (instead of UTF-8)"
    ] [
        result: make string! 4000
        init-state indent ascii
        red-to-json-value result data
    ]
]

put system/codecs 'json context [
    Title:     "JSON codec"
    Name:      'JSON
    Mime-Type: [application/json]
    Suffixes:  [%.json]
    encode: func [data [any-type!] where [file! url! none!]] [
        to-json data
    ]
    decode: func [text [string! binary! file!]] [
        if file? text [text: read text]
        if binary? text [text: to string! text]
        load-json text
    ]
]
