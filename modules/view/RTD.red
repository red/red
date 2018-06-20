Red [
	Title:   "Rich Text Dialect"
	Author:  "Nenad Rakocevic"
	File: 	 %RTD.red
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

context [
	stack: make block! 10
	color-stk: make block! 5
	out: text: s-idx: mark: s: pos: v: none

	;--- Parsing rules ---

	nested: [ahead block! into rtd]
	color:  [
		  s: tuple!	(v: s/1)							;-- color as R.G.B tuple
		| issue!	(v: hex-to-rgb s/1)					;-- color as #rgb or #rrggbb hex value
		| word! 	if (tuple? attempt [v: get s/1])
	]
	f-args: [
		ahead block! into [integer! string! | string! integer!]
		| integer!
		| string!
	]
	style: [
		  ['b | 'bold      | <b>] (push 'b)	[nested | rtd [/b | /bold 	   | </b>]] (pop 'b)
		| ['i | 'italic    | <i>] (push 'i)	[nested | rtd [/i | /italic	   | </i>]] (pop 'i)
		| ['u | 'underline | <u>] (push 'u)	[nested | rtd [/u | /underline | </u>]] (pop 'u)
		| ['s | 'strike    | <s>] (push 's)	[nested | rtd [/s | /strike	   | </s>]] (pop 's)
		| ['f | 'font      | <font>]
			s: f-args (push either block? s/1 [head insert copy s/1 'f][reduce ['f s/1]]) 
			[nested | rtd [/f | /font | </font>]]
			(pop 'f)
		| ['bg | <bg>] color (push reduce ['bg v]) [nested | rtd [/bg | </bg>]] (pop 'bg)
		| color (push-color v) opt [nested (pop-color)]
		| ahead path!
		  into [
			(mark: tail stack) some [					;@@ implement any-single
				(v: none)
				s: ['b | 'i | 'u | 's | word! if (tuple? attempt [v: get s/1])]
				(either v [push-color v][push s/1])
			]
		  ]
		  nested (pop-all mark)
	]
	rtd: [some [pos: style | s: string! (append text s/1 s-idx: tail-idx?)]]

	;--- Functions ---

	tail-idx?: does [index? tail text]

	push-color: func [c [tuple!]][reduce/into [s-idx '_ c] tail color-stk]

	pop-color: has [entry pos][
		close-colors
		entry: back back tail color-stk	
		append out as-pair entry/1 tail-idx? - entry/1 entry/3
		clear skip tail color-stk -3
	]

	close-colors: has [pos][
		pos: color-stk
		while [pos: find/tail pos '_][
			pos/-1: tail-idx?
			append out as-pair pos/-2 tail-idx? - pos/-2
			append out pos/1
			new-line skip tail out -2 on
			pos: remove/part skip pos -2 3
		]
	]

	push: func [style [word! block!]][reduce/into [s-idx style] tail stack]

	pop: function [style [word!]][
		entry: back back tail stack
		type: any [all [block? entry/2 entry/2/1] entry/2]

		either style = type [
			if entry/1 < tail-idx? [					;-- ignore zero-range styles
				append out as-pair entry/1 tail-idx? - entry/1
				new-line back tail out on
				append out switch style [
					b	['bold]
					i	['italic]
					u	['underline]
					s	['strike]
					f	[next entry/2]
					bg	[reduce ['backdrop entry/2/2]]
				]
				clear skip tail stack -2
			]
		][cause-error 'script 'rtd-no-match reduce [style]]
	]

	pop-all: function [mark [block!]][
		first?: yes
		while [mark <> tail stack][
			pop last stack
			either first? [first?: no][remove skip tail out -2]
		]
	]

	optimize: function [][								;-- combine same ranges together
		parse out [
			any [
				pos: pair! (range: pos/1) to pair! pos:
				any [
					to range s: skip [to pair! | to end] e: (
						s: remove s
						e: next move/part s pos offset? s back e
					) :e
				]
			]
		]
	]

	set 'rtd-layout func [
		"Returns a rich-text face from a RTD source code"
		spec [block!]	"RTD source code"
		/only			"Returns only [text data] facets"
		/with			"Populate an existing face object"
			face [object!] "Face object to populate"
		return: [object! block!]
	][
		clear stack
		clear color-stk
		out: make block! 50
		text: make string! 100
		s-idx: 1

		unless parse spec rtd [cause-error 'script 'rtd-invalid-syntax reduce [pos]]

		close-colors
		optimize
		case [
			only  [reduce [text out]]
			with  [face/text: text face/data: out face]
			'else [face: make-face/spec 'rich-text reduce [text] face/data: out face]
		]
	]
]