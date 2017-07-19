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


spec-of: func [fun [any-function!]][first :fun]
body-of: func [fun [any-function!]][second :fun]

function: func [
	"Defines a function with all set-words as locals."
	[catch]
	spec [block!] {Help string (opt) followed by arg words (and opt type and string)}
	body [block!] "The body block of the function"
	/with "Define or use a persistent object (self)"
	object [object! block!] "The object or spec"
	/extern words [block!] "These words are not local"
	/local r ws wb a
][
	spec: copy/deep spec
	body: copy/deep body
	ws: make block! length? spec
	parse spec [any [
			set-word! | set a any-word! (insert tail ws to-word a) | skip
		]]
	if with [
		unless object? object [object: make object! object]
		bind body object
		insert tail ws first object
	]
	insert tail ws words
	wb: make block! 12
	parse body r: [any [
			set a set-word! (insert tail wb to-word a) |
			hash! | into r | skip
		]]
	unless empty? wb: exclude wb ws [
		remove find wb 'local
		unless find spec /local [insert tail spec /local]
		insert tail spec wb
	]
	throw-on-error [make function! spec body]
]

has: func [
	{A shortcut to define a function that has local variables but no arguments.}
	locals [block!]
	body [block!]
][
	func head insert copy locals /local body
]