REBOL [
	Title:   "Information extractor from Red runtime source code"
	Author:  "Nenad Rakocevic"
	File: 	 %extractor.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Notes: {
		These utility functions extract types ID and function definitions from Red
		runtime source code and make it available to the compiler, before the Red runtime
		is actually compiled.
		
		This procedure is required during bootstrapping, as the REBOL compiler can't
		examine loaded Red data in memory at runtime.
	}
]

context [
	scalars: pos: none
	definitions: make block! 100
	hexa: charset "0123456789ABCDEF"

	data: copy read-cache %runtime/macros.reds
	parse/case data [any [pos: 2 8 hexa e: #"h" (pos: remove/part pos e) :pos | skip]] ;-- remove unloadable literals
	data: load data

	currencies: load-cache %environment/system.red
	extras: make block! 1
	
	extract-codes: has [codes][
		codes: third find (third find currencies/5 quote locale:) quote currencies:
		currencies: copy codes/2
	]
	
	extract-defs: func [type [word!] /local list index][
		list: select data type
		
		index: 0
		forall list [
			if set-word? list/1 [
				list/1: to word! list/1
				index: list/2
			]
			if word? list/1 [
				repend definitions [list/1 index]
				index: index + 1
			]
		]
	]
	
	extract-defs 'datatypes!
	extract-defs 'actions!
	extract-defs 'natives!
	
	extract-codes
	
	data: none
	
	set 'typeset! block!								;-- fake a convenient definition

	init: func [job [object!] /local src] [
		src: preprocessor/expand load-cache %environment/scalars.red job
		scalars: make object! copy skip src 2
		
		clear extras
	]
]