REBOL [
	Title:   "Information extractor from Red runtime source code"
	Author:  "Nenad Rakocevic"
	File: 	 %extractor.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
	Notes: {
		These utility functions extract types ID and function definitions from Red
		runtime source code and make it available to the compiler, before the Red runtime
		is actually compiled.
		
		This procedure is required during bootstrapping, as the REBOL compiler can't
		examine loaded Red data in memory at runtime.
	}
]

context [
	definitions: make block! 100
	data: load %runtime/macros.reds
	
	extract-defs: func [type [word!] /local list index][
		list: select data type
		
		index: 0
		foreach word list [
			switch type?/word word [
				set-word! [
					red/throw-error "extractor error: unsupported set-words!"
				]
				word! [
					repend definitions [word index]
					index: index + 1
				]
			]
		]
	]
	
	extract-defs 'datatypes!
	extract-defs 'actions!
	
	data: none
]