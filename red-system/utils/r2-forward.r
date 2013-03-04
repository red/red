;; NOTE: This file is based on r2-forward.r 2.100.80.4 but stripped of the
;; changelog and most functions.
;;
;; Red/System's compiler requires REBOL 2.7.6 as baseline. This file hold
;; functions not part of REBOL 2.7.6 which are used in the implementation of
;; Red/System.

REBOL [
	Title: "REBOL 3 Forward Compatibility Functions"
	Name: 'r2-forward
	Type: 'module
	Version: 2.100.80.4.1
	Date: 23-Feb-2011
	File: %r2-forward.r
	Author: "Brian Hawley" ; BrianH
	Purpose: "Make REBOL 2 more compatible with REBOL 3."
	Exports: [
		map-each
		collect
		
		; tentative additions from HostileFork
		r3?
		hash!
		to-hash
		disarm
		read-binary
		write-binary
		read-string
		clear-map
		remove-map
		bin-pos
		bin-capture
		readable-error-block
		clean-path
		shift-left
		shift-right
		make-owner-executable
		unique-extended
		some-parsefix
		any-parsefix
		binary-to-int32
		integer-to-bytes
		r2-utf8-checked
		r2-string-to-binary
		r2-escape-string
		to-hex-string
	] ; No Globals to limit any potential damage.
	License: {
		Copyright (c) 2008-2009 Brian Hawley

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in
		all copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
		THE SOFTWARE.
	} ; MIT
]

r3?: does [system/version > 2.99.0]

;-- Interim solution for preliminary r3 build...define hash! simply as block!
;-- Performance suffers vs. re-coding to use map!-safe functions on R2 hash!
;-- But at least this won't degrade the R2 version, and gets the ball rolling
if r3? [
	hash!: block! 
	to-hash: func [b [block!]] [b]
]

if not r3? [

; MAP-EACH with set-words, best datatype! support and /into (ideal full version)
map-each: func [
	"Evaluates a block for each value(s) in a series and returns them as a block."
	[throw catch]
	'word [word! block!] "Word or block of words to set each time (local)"
	data [block!] "The series to traverse"
	body [block!] "Block to evaluate each time"
	/into "Collect into a given series, rather than a new block"
	output [any-block! any-string!] "The series to output to" ; Not image!
	/local init len x
][
	; Shortcut return for empty data
	either empty? data [any [output make block! 0]] [
		; BIND/copy word and body
		word: either block? word [
			if empty? word [throw make error! [script invalid-arg []]]
			copy/deep word  ; /deep because word is rebound before errors checked
		] [reduce [word]]
		word: use word reduce [word]
		body: bind/copy body first word
		; Build init code
		init: none
		parse word [any [word! | x: set-word! (
			unless init [init: make block! 4]
			; Add [x: at data index] to init, and remove from word
			insert insert insert tail init first x [at data] index? x
			remove x
		) :x | x: skip (
			throw make error! reduce ['script 'expect-set [word! set-word!] type? first x]
		)]]
		len: length? word ; Can be zero now (for advanced code tricks)
		; Create the output series if not specified
		unless into [output: make block! divide length? data max 1 len]
		; Process the data (which is not empty at this point)
		until [ ; Note: output: insert/only output needed for list! output
			set word data  do init
			unless unset? set/any 'x do body [output: insert/only output :x]
			tail? data: skip data len
		]
		; Return the output and clean up memory references
		also either into [output] [head output] (
			set [word data body output init x] none
		)
	]
]
; Note: This is pretty fast by R2 mezzanine loop standards, native in R3.

collect: func [
	"Evaluates a block, storing values via KEEP function, and returns block of collected values."
	body [block!] "Block to evaluate"
	/into "Insert into a buffer instead (returns position after insert)"
	output [series!] "The buffer series (modified)"
][ ; Note: Needs new FUNC (defined above)
	unless output [output: make block! 16]
	do func [keep] body func [value /only] [
		output: either only [insert/only output :value] [insert output :value]
		:value
	]
	either into [output] [head output]
]
; R3 version based on a discussion with Gregg and Gabriele in AltME.

]

;;
;; Tentative additions by HostileFork to support features that differ in R3
;; which are used by the Red codebase
;;

if r3? [disarm: func [e [error!]] [e]]
; Note: Errors are disarmed by default in R3

remove-map: func [m [map!] key /local pos /exists] [
	either r3? [
		; we're in Rebol 3, in which unfulfilled refinements are none?
		if (true? exists) and (none = m/key) [
				print "key was not in map for remove-map/exists"
				halt
		]

		m/key: none
	] [
		; we're in Rebol 2, this is the only way I know of to remove a key/val
		either pos: find m key [
			remove/part pos 2
		] [
			if exists [
				print "key was not in map for remove-map/exists"
				halt
			]
		]

	]
]
; Note: R3 does not support FIND on MAP!

read-binary: func [source [file! url! block!]] [
	either r3? [
		read source									;-- R3 defaults binary!
	] [
		read/binary source							;-- R2 defaults string!
	]
]

write-binary: func [destination [file! url! block!] data /direct] [
	either r3? [
		;-- no direct refinement in R3, ignore it
		write destination data						;-- R3 defaults binary!
	] [
		;-- R2 defaults string!
		
		either direct [
			write/binary/direct destination data
		] [
			write/binary destination data
		]
	]
]

read-string: func [source /local result] [
	either r3? [
		read/string source							;-- R3 defaults binary!
	] [
		read source									;-- R2 defaults string!
	]
]

clear-map: func [m [map!]] [
	either r3? [
		m: make map! [] 							;-- loses size hint
	] [
		clear m
	]
]
; Note: This shouldn't be needed, it's a temporary workaround for a bug in R3
; http://curecode.org/rebol3/ticket.rsp?id=1930&cursor=4

bin-pos: bin-capture: func [pos [binary! string!]] [
    either string? pos [
 	    as-binary pos
    ] [
        pos											;-- no-op in R3
    ]
]
; Note: these are for bridging incompatibility between R2/R3 on binary PARSE
; http://stackoverflow.com/questions/14203426/

readable-error-block: func [err [error! object!]] [
	either object? err [							;-- disarmed errors in R2
		system/error/(err/type)/type #":"
		reduce system/error/(err/type)/(err/id) newline
		"*** Where:" mold/flat err/where newline
		"*** Near: " mold/flat err/near newline
	] [
		mold err 									;-- need to write this
	]
]

if not r3? [clean-path: func [f [file!]] [get-modes f 'full-path]]
; http://stackoverflow.com/questions/14352039/

shift-left: func [data [integer! binary!] bits [integer!]] [
	either r3? [
		;-- R3 changes the default direction of shift to left :-/
		shift data bits
	] [
		shift/left data bits
	]
]

shift-right: func [data [integer! binary!] bits [integer!]] [
	either r3? [
		;-- R3 changes the default direction of shift to left :-/
		shift data negate bits
	] [
		shift data bits
	]
]

make-owner-executable: func [target [file!]] [
	either r3? [
		;-- just unix for now...
		call/wait rejoin [{chmod +x "} to-string target {"}]
	] [
		if find get-modes target 'file-modes 'owner-execute [
			set-modes target [owner-execute: true]
		]
	]
]

unique-extended: func [series [series!] /local s e] [
	either r3? [
		s: series
		while [s <> e: tail series] [
			while [e <> s] [
				if s/1 = e/1 [
					take e
				]
				e: back e
			]
			s: next s
		]
		series
	] [
		unique series
	]
]

some-parsefix: func [rule [block!] /local r] [
	if r3? [parse rule r: [any [ 
		change 'some 'while | and block! into r | skip 
	]]]
	rule
]
any-parsefix: func [rule [block!] /local r] [
	if r3? [parse rule r: [any [ 
		change 'any 'while | and block! into r | skip 
	]]]
	rule
]
;-- R3 has different behavior w.r.t. SOME and CHANGE
;-- Replacing with WHILE works, but that is not available in R2 PARSE
;--     http://stackoverflow.com/questions/14352264/ 

binary-to-int32: func [bin [binary!] /local padded] [
	assert [find [1 2 4] length? bin]
	padded: head insert/dup bin #{00} (4 - length? bin)
	if r3? [
		insert/dup padded (either 127 < first padded [#{FF}] [#{00}]) 4
	]
	to integer! padded
]

integer-to-bytes: func [v [integer!] /width bytes [integer!] /local bin high-byte s][
	unless width [
		if zero? v [return #{00}] ;-- special case or could fix parse rule
		bytes: 4
	]
	assert [find [1 2 4] bytes] ;-- code is generalized, just sanity check
	
	;-- This reformulation of [debase/base to-hex v 16] seems to
	;-- be able to work in both R2 and R3, but we need to recognize
	;-- that to-hex produces 8 byte long issues, not 4 byte ones		
	bin: debase/base next mold to-hex v 16

	high-byte: either v < 0 [
		;-- For now, if you don't specify a width we trim all leading
		;-- zeroes...if we did this with the FFs you might not know your
		;-- number was negative.  Revisit this design.
		assert [width]
		#{FF}
	] [
		#{00}
	]
	
	assert [
		parse/all bin compose [
			((length? bin) - bytes) high-byte 
			(unless width [[any #{00}]]) s: to end  
		]
	]
	copy bin-pos s
]

safe-r2-char: charset [#"^(00)" - #"^(7F)"]
unsafe-r2-char: charset [#"^(80)" - #"^(FF)"]

hex-digit: charset [#"0" - #"9" #"A" - #"F" #"a" - #"f"]

r2-utf8-checked: func [codepoints [char! string!]] [
	either char! = type? codepoints [
		if find safe-r2-char codepoints [return codepoints]
	] [
		if parse/all codepoints [any safe-r2-char] [return codepoints]
	]
	print "Unsafe codepoints for R2 found in string! by r2-utf8-checked"
	print "See http://stackoverflow.com/questions/15077974/"
	print mold codepoints
	throw "Bad codepoint found by r2-utf8-checked"
]

r2-string-to-binary: func [str [string!] /string /unescape /unsafe /local result s e escape-rule unsafe-rule safe-rule rule] [
	;-- Utility function originally from here:
	;--     http://stackoverflow.com/questions/15077974/
	
	result: copy either string [{}] [#{}]
	escape-rule: [
		"^^(" s: 2 hex-digit e: ")" (
			append result debase/base copy/part s e 16
		)
	]
	unsafe-rule: [
		s: unsafe-r2-char (
			append result to integer! first s
		)
	]
	safe-rule: [
		s: safe-r2-char (append result first s)
	]
	rule: compose/deep [
		any [
			(either unescape [[escape-rule |]] [])
			safe-rule
			(either unsafe [[| unsafe-rule]] [])
		]
	]
	unless parse/all str rule [
		print "Unsafe codepoints for R2 found in string! by r2-string-to-binary"
		print "See http://stackoverflow.com/questions/15077974/"
		print mold str
		throw "Bad codepoint found by r2-string-to-binary"
	]
	result
]

r2-escape-string: func [str [string!] /count var /local result num temp] [
	result: copy {}
	num: 0
	foreach codepoint str [
		either 127 >= to integer! codepoint [
			append result codepoint
			++ num
		] [
			codepoint: to binary! codepoint
			;-- only R3 will have > 1 byte cases
			assert [4 >= length? codepoint] 
			foreach byte codepoint [
				append result rejoin ["^^(" to-hex-string/size byte 2 ")"]
				++ num
			]
		]	
	]
	if count [
		set var num
	]
	result
]

to-hex-string: func [value [integer!] /size len /local result] [
	either size [
		either r3? [
			remove to string! to-hex/size value len
		] [
			;-- No size refinement in R2, string conversion drops # sign
			result: to string! to-hex value
			while ["00" = copy/part result 2] [
				remove/part result 2
			]
			result
		] 
	] [
		remove to string! to-hex value
	] 
]
