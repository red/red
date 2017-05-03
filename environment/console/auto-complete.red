Red [
	Title:	"Auto completion functions for words and functions"
	Author: "Qingtian Xie"
	File: 	%auto-complete.red
	Tabs: 	4
	Rights: "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

has-common-part?: no

common-substr: func [
	blk		[block!]
	/local a b
][
	has-common-part?: either 1 < length? blk [
		sort blk
		a: first blk
		b: last blk
		while [
			all [
				not tail? a
				not tail? b
				(first a) = first b		;@@ cannot use a/1 as 'a may be a file!
			]
		][
			a: next a
			b: next b
		]
		insert blk copy/part head a a
		yes
	][no]
]

red-complete-path: func [
	str		 [string!]
	console? [logic!]
	/local s result word w1 ptr words first? sys-word w
][
	result: make block! 4
	first?: yes
	s: ptr: str
	while [ptr: find str #"/"][
		word: attempt [to word! copy/part str ptr]
		if none? word [return result]
		either first? [
			if value? word [
				w1: get word
				first?: no
			]
		][
			w1: get in w1 word
		]
		str: either object? w1 [next ptr][""]
	]
	if any [function? w1 action? w1 native? w1 routine? w1] [
		word: find/last/tail s #"/"
		words: make block! 4
		foreach w spec-of w1 [
			if refinement? w [append words w]
		]
	]
	if object? w1 [
		word: str
		words: words-of w1
	]
	if words [
		foreach w words [
			sys-word: form w
			if any [empty? word find/match sys-word word] [
				append result sys-word
			]
		]
	]

	if console? [common-substr result]
	if any [1 = length? result has-common-part?] [
		poke result 1 append copy/part s word result/1
	]
	result
]

red-complete-file: func [
	str		 [string!]
	console? [logic!]
	/local file result path word f files replace? change?
][
	result: make block! 4
	file: to file! next str
	replace?: no

	either word: find/last/tail str #"/" [
		path: to file! copy/part next str word
		unless exists? path [return result]
		replace?: yes
	][
		path: %./
		word: file
	]

	files: read path
	foreach f files [
		if any [empty? word find/match f word] [
			append result f
		]
	]
	if console? [common-substr result]
	if any [1 = length? result has-common-part?] [
		poke result 1 append copy/part str either replace? [word][1] result/1
	]
	result
]

red-complete-input: func [
	str		 [string!]
	console? [logic!]
	/local
		word ptr result sys-word delim? len insert?
		start end delimiters d w change?
][
	has-common-part?: no
	result: make block! 4
	delimiters: [#"^-" #" " #"[" #"(" #":" #"'" #"{"]
	delim?: no
	insert?: not tail? str
	len: (index? str) - 1
	end: str
	ptr: str: head str
	foreach d delimiters [
		word: find/last/tail/part str d len
		if all [word (index? ptr) < (index? word)] [ptr: word]
	]
	either head? ptr [start: str][start: ptr delim?: yes]
	word: copy/part start end
	unless empty? word [
		case [
			all [
				#"%" = word/1
				1 < length? word
			][
				append result 'file
				append result red-complete-file word console?
			]
			all [
				#"/" <> word/1
				ptr: find word #"/"
				#" " <> pick ptr -1
			][
				append result 'path
				append result red-complete-path word console?
			]
			true [
				append result 'word
				foreach w words-of system/words [
					if value? w [
						sys-word: mold w
						if find/match sys-word word [
							append result sys-word
						]
					]
				]
				if ptr: find result word [swap next result ptr]
				if console? [common-substr next result]
			]
		]
	]
	if console? [result: next result]

	if all [console? any [has-common-part? 1 = length? result]][
		if word = result/1 [
			unless has-common-part? [clear result]
		]
		unless empty? result [
			either any [insert? delim?] [
				str: append copy/part str start result/1
				poke result 1 tail str
				if insert? [append str end]
			][
				poke result 1 tail result/1
			]
		]
	]
	result
]