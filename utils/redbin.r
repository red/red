REBOL [
	Title:   "Redbin format encoder for Red compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %redbin.r
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

context [
	header:		make binary! 10'000
	buffer:		make binary! 100'000
	sym-table:	make binary! 10'000
	sym-string:	make binary! 10'000
	symbols:	make hash! 	 1'000						;-- [word1 word2 ...]
	contexts:	make hash!	 1'000						;-- [name [symbols] index ...]
	index:		0
	
	stats:		make block! 100
	profile?:	yes
	
	profile: func [blk /local pos][
		foreach item blk [
			unless pos: find/skip stats type? :item 2 [
				repend stats [type? :item 0]
				pos: skip tail stats -2
			]
			pos/2: pos/2 + 1

		]
	]
	
	get-index: does [index - 1]
	
	pad: func [buf [any-string!] n [integer!] /local bytes][
		unless zero? bytes: (length? buf) // n [
			insert/dup tail buf null bytes
		]
	]
	
	emit: func [n [integer!]][insert tail buffer to-bin32 n]
	
	emit-type: func [type [word!]][
		emit select extracts/definitions type
	]
	
	emit-ctx-info: func [word [any-word!] ctx [word!] /local entry pos][	
		entry: find contexts ctx
		emit entry/3
		either pos: find entry/2 to word! word [(index? pos) - 1][none]
	]
	
	emit-decimal: func [value [integer!]][
			
	]
	
	emit-char: func [value [integer!]][
		emit-type 'TYPE_CHAR
		emit value
	]
	
	emit-integer: func [value [integer!]][
		emit-type 'TYPE_INTEGER
		emit value
	]
	
	emit-typeset: func [v1 [integer!] v2 [integer!] v3 [integer!] /root][
		emit-type 'TYPE_TYPESET
		emit v1
		emit v2
		emit v3
		
		if root [index: index + 1]
		index - 1
	]
	
	emit-string: func [str [any-string!] /root /local type][
		type: select [
			string! TYPE_STRING
			file!	TYPE_FILE
			url!	TYPE_URL
		] type?/word str
		
		emit (shift/left extracts/definitions/:type 8) or 1 		;-- UCS/Head fields
		emit (index? str) - 1
		emit length? str
		append buffer str
		pad buffer 4
		
		if root [index: index + 1]
		index - 1
	]
	
	emit-issue: func [value [issue!]][
		emit-type 'TYPE_ISSUE
		emit-symbol to word! form value
	]
	
	emit-symbol: func [word /local pos s][
		word: to word! word
		
		unless pos: find symbols word [
			s: tail sym-string
			repend sym-string [word null]
			append sym-table to-bin32 (index? s) - 1
			append symbols word
			pos: back tail symbols
		]
		emit (index? pos) - 1							;-- emit index of symbol
	]
	
	emit-word: func [word ctx [word! none!] index [integer! none!]][
		emit-type select [
			word!		TYPE_WORD
			set-word!	TYPE_SET_WORD
			get-word!	TYPE_GET_WORD
			refinement! TYPE_REFINEMENT
			lit-word!	TYPE_LIT_WORD
		] type?/word word
		
		emit-symbol word
		idx: either ctx [emit-ctx-info word ctx][-1]	;-- -1 for global context
		emit any [index idx -1]
	]
	
	emit-block: func [blk [any-block!] /with main-ctx [word!] /sub /local type item binding ctx idx][
		if profile? [profile blk]
		
		type: either all [path? blk get-word? blk/1][
			blk/1: to word! blk/1 						;-- workround for missing get-path! in R2
			'get-path
		][
			type?/word blk
		]
	
		emit-type select [
			block!		TYPE_BLOCK
			paren!		TYPE_PAREN
			path!		TYPE_PATH
			lit-path!	TYPE_LIT_PATH
			set-path!	TYPE_SET_PATH
		] type
		
		emit (index? blk) - 1							;-- head field
		emit length? blk
	
		forall blk [
			item: blk/1
			either any-block? :item [
				either with [
					emit-block/sub/with item main-ctx 
				][
					emit-block/sub item
				]
			][
				if :item = #get-definition [			;-- temporary directive
					value: select extracts/definitions blk/2
					change/only/part blk value 2
					item: blk/1
				]
				case [
					unicode-char? :item [
						value: item
						item: #"_"						;-- placeholder just to pass the char! type to item
						emit-char to integer! next value
					]
					any-word? :item [
						ctx: main-ctx
						value: :item
						either all [with local-word? to word! :item][				
							idx: get-word-index/with to word! :item main-ctx			
						][
							if binding: find-binding :item [
								set [ctx idx] binding
							]
						]
					]
					float-special? :item [
						;emit-fp-special item
						value: :item
					]
				]
				switch type?/word :item [
					word!
					set-word!
					refinement!
					get-word! [emit-word item ctx idx]
					string!	  [emit-string item]
					issue!	  [emit-issue item]
					integer!  [emit-integer item]
					decimal!  [emit-float item]
				]
			]
		]
		unless sub [index: index + 1]
		index - 1										;-- return the block index
	]
	
	emit-context: func [name [word!] spec [block!] /root][
		repend contexts [name spec index]
		emit (shift/left extracts/definitions/TYPE_CONTEXT 8)
			or 1										;-- flags: 1 (no values)
		
		emit length? spec
		foreach word spec [emit-symbol word]
		if root [index: index + 1]
		index - 1
	]
	
	init: does [
		clear header
		clear buffer
		clear sym-table
		clear sym-string
		clear symbols
		clear contexts
		index: 0
	]
	
	finish: func [flags [block! none!]][
		pad sym-string 8
		
		repend header [
			"REDBIN"
			#{0104}										;-- version: 1, flags: symbols
			to-bin32 length? symbols
			to-bin32 length? sym-string
			sym-table
			sym-string
		]
		insert buffer header
	]
]