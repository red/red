Red [
    File:    %load-json.red
    Title:   "JSON parser"
    Purpose: "Convert JSON to Red."
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
	References: [
		http://www.json.org/
		https://www.ietf.org/rfc/rfc4627.txt
		http://www.rfc-editor.org/rfc/rfc7159.txt
		http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf
		https://github.com/rebolek/red-tools/blob/master/json.red
	]
	Notes: {
		- Ported from %json.r, by Romano Paolo Tenca, Douglas Crockford, and Gregg Irwin.
		- Further research: JSON libs by Chris Ross-Gill, Kaj de Vos, and @WiseGenius.
		
		? Do we want to have a single context or separate encode/decode contexts?
            - Split into two files (Gab)
		? Do we want to use a stack with parse, or recursive load-json/decode calls?

		- Unicode support is in the works.
		- Pretty formatting from %json.r removed. Determine what formatting options we want.

		- Would like to add more detailed decode error info.
			- JSON document is empty.
			- Invalid value.
			- Missing name for object member.
			- Missing colon after name of object member.
			- Missing comma or right curly brace after object member.
			- Missing comma or ] after array element.
			- Invalid \uXXXX escape.
			- Invalid surrogate pair.
			- Invalid backslash escape.
			- Missing closing quotation mark in string.
			- Numeric overflow.
			- Missing fraction in number.
			- Missing exponent in number.
	}
	Rights:  "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %environment/codecs/json/common.red

context [
    decode-backslash-escapes: :json-common/decode-backslash-escapes
    json-esc-ch:              :json-common/json-esc-ch
    json-escaped:             :json-common/json-escaped
	ctrl-char:                :json-common/ctrl-char

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
		#"^"" copy _str [
			any [some chars | #"\" [#"u" 4 hex-char | json-esc-ch]]
		] #"^"" (
			if not empty? _str: any [_str copy ""] [
				;!! If we reverse the decode-backslash-escapes and replace-unicode-escapes
				;!! calls, the string gets munged (extra U+ chars). Need to investigate.
				decode-backslash-escapes _str			; _str is modified
				replace-unicode-escapes _str			; _str is modified
				;replace-unicode-escapes decode-backslash-escapes _str
			]
		)
	]

	decode-unicode-char: func [
		"Convert \uxxxx format (NOT simple JSON backslash escapes) to a Unicode char"
		ch [string!] "4 hex digits"
	][
		buf: {#"^^(0000)"}								; Don't COPY buffer, reuse it
		if not parse ch [4 hex-char] [return none]		; Validate input data
		attempt [load head change at buf 5 ch]			; Replace 0000 section in buf
	]

	replace-unicode-escapes: func [
		s [string!] "(modified)"
		/local c
	][
		parse s [
			any [
				some chars								; Pass over unescaped chars
				| json-escaped							; Pass over simple backslash escapes
				| change ["\u" copy c 4 hex-char] (decode-unicode-char c) ()
				;| "\u" followed by anything else is an invalid \uXXXX escape
			]
		]
		s
	]
	;str: {\/\\\"\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t`1~!@#$%&*()_+-=[]{}|;:',./<>?}
	;mod-str: decode-backslash-escapes json-ctx/replace-unicode-escapes copy str
	;mod-str: json-ctx/replace-unicode-escapes decode-backslash-escapes copy str

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
