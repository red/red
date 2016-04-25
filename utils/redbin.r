REBOL [
	Title:   "Redbin format encoder for Red compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %redbin.r
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

context [
	header:		make binary! 10'000
	buffer:		make binary! 200'000
	sym-table:	make binary! 10'000
	sym-string:	make binary! 10'000
	symbols:	make hash! 	 1'000						;-- [word1 word2 ...]
	contexts:	make hash!	 1'000						;-- [name [symbols] index ...]
	index:		0
	
	stats:		make block! 100
	profile?:	no
	debug?:		no
	
	UTF8-char:	lexer/UTF8-char
	chars: 		make block!  10'000
	decoded: 	make string! 10'000
	lf-flag:	shift/left 1 31		;-- header's new-line flag
	
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
			insert/dup tail buf null n - bytes
		]
	]
	
	preprocess-directives: func [blk][
		forall blk [
			if blk/1 = #get-definition [				;-- temporary directive
				value: select extracts/definitions blk/2
				change/only/part blk value 2
			]
		]
	]
	
	decode-UTF8: func [str [string! file! url!] /local upper s e cp unit new][
		upper: 0

		parse/all/case str [
			any [s: UTF8-char e: (
				cp: either e = next s [s/1][			;-- shortcut for ASCII codepoints
					lexer/decode-UTF8-char/redbin as-binary copy/part s e
				]
				append chars cp: to integer! cp
				upper: max upper cp
			)]
		]
		if upper < 128 [								;-- shortcut for ASCII strings
			clear chars
			return reduce [str 1]
		]
		new: clear decoded
		
		unit: either upper < 65536 [
			foreach cp chars [insert tail new to-bin16 cp]
			2
		][
			foreach cp chars [insert tail new to-bin32 cp]
			4
		]
		clear chars
		reduce [new unit]
	]
	
	emit: func [n [integer!]][insert tail buffer to-bin32 n]
	
	emit-type: func [type [word!] lf? /unit n [integer!]][
		emit extracts/definitions/:type or either lf? [lf-flag][0]
	]
	
	emit-ctx-info: func [word [any-word!] ctx [word! none!] /local entry pos][
		unless ctx [emit -1 return -1]				;-- -1 for global context
		entry: find contexts ctx
		either pos: find entry/2 to word! word [
			emit entry/3
			(index? pos) - 1
		][
			emit -1
			-1
		]
	]
	
	emit-unset: does [emit-type 'TYPE_UNSET off]

	emit-none: func [lf?][emit-type 'TYPE_NONE lf?]
	
	emit-datatype: func [type [datatype! word!] lf?][
		unless word? type [type: to word! mold type]
		emit-type 'TYPE_DATATYPE lf?
		emit extracts/definitions/:type
	]
	
	emit-logic: func [value [logic!] lf?][
		emit-type 'TYPE_LOGIC lf?
		emit to integer! value
	]
	
	emit-float: func [value [decimal!] lf? /local bin][
		pad buffer 8
		emit-type 'TYPE_FLOAT lf?
		bin: IEEE-754/to-binary64 value
		emit to integer! copy/part bin 4
		emit to integer! skip bin 4
	]
	
	emit-fp-special: func [value [issue!] lf?][
		pad buffer 8
		emit-type 'TYPE_FLOAT lf?
		switch next value [
			#INF  [emit to integer! #{7FF00000} emit 0]
			#INF- [emit to integer! #{FFF00000} emit 0]
			#NaN  [emit to integer! #{7FF80000} emit 0]			;-- smallest quiet NaN
			#0-	  [emit to integer! #{80000000} emit 0]
		]
	]

	emit-percent: func [value [issue!] lf? /local bin][
		pad buffer 8
		emit-type 'TYPE_PERCENT lf?
		value: to decimal! to string! copy/part value back tail value
		bin: IEEE-754/to-binary64 value / 100.0
		emit to integer! copy/part bin 4
		emit to integer! skip bin 4
	]

	emit-char: func [value [integer!] lf?][
		emit-type 'TYPE_CHAR lf?
		emit value
	]
	
	emit-integer: func [value [integer!] lf?][
		emit-type 'TYPE_INTEGER lf?
		emit value
	]

	emit-pair: func [value [pair!] lf?][
		emit-type 'TYPE_PAIR lf?
		emit value/x
		emit value/y
	]

	emit-tuple: func [value [tuple!] lf? /local bin size n header][
		bin: make binary! 12
		bin: insert/dup bin null 3
		size: length? value
		header: extracts/definitions/TYPE_TUPLE or shift/left size 8
		if lf? [header: header or lf-flag]
		
		emit header
		n: 0
		until [
			n: n + 1
			insert bin to-bin8 value/:n
			n = size
		]
		bin: tail bin
		emit to integer! skip bin -4
		emit to integer! copy/part skip bin -8 4
		emit to integer! copy/part head bin 4
	]

	emit-op: func [spec [any-word!]][
		emit-type 'TYPE_OP off
		emit-symbol spec
	]
	
	emit-native: func [id [word!] spec [block!] /action][
		emit-type pick [TYPE_ACTION TYPE_NATIVE] to logic! action off
		emit extracts/definitions/:id
		emit-block/sub spec off
	]
	
	emit-typeset: func [v1 [integer!] v2 [integer!] v3 [integer!] lf? /root][
		emit-type 'TYPE_TYPESET lf?
		emit v1
		emit v2
		emit v3
		
		if root [
			if debug? [print [index ": typeset"]]
			index: index + 1
		]
		index - 1
	]

	emit-string: func [str [any-string!] lf? /root /local type unit header][
		type: select [
			string! TYPE_STRING
			file!	TYPE_FILE
			url!	TYPE_URL
			binary! TYPE_BINARY
		] type?/word str

		either type = 'TYPE_BINARY [unit: 1][set [str unit] decode-UTF8 str]
		header: extracts/definitions/:type or shift/left unit 8
		if lf? [header: header or lf-flag]

		emit header
		emit (index? str) - 1								 ;-- head
		emit (length? str) / unit
		append buffer str
		pad buffer 4

		if root [
			if debug? [print [index ": string :" copy/part str 40]]
			index: index + 1
		]
		index - 1
	]
	
	emit-issue: func [value [issue!] lf?][
		emit-type 'TYPE_ISSUE lf?
		emit-symbol to word! form value
	]
	
	emit-symbol: func [word /local pos s][
		word: to word! word
		
		unless pos: find/case symbols word [
			s: tail sym-string
			repend sym-string [word null]
			append sym-table to-bin32 (index? s) - 1
			append symbols word
			pos: back tail symbols
		]
		emit (index? pos) - 1							;-- emit index of symbol
	]
	
	emit-word: func [
		word ctx [word! none!] ctx-idx [integer! none!] lf? /root /set?
		/local type idx header
	][
		type: select [
			word!		TYPE_WORD
			set-word!	TYPE_SET_WORD
			get-word!	TYPE_GET_WORD
			refinement! TYPE_REFINEMENT
			lit-word!	TYPE_LIT_WORD
		] type?/word :word
		
		header: extracts/definitions/:type
		if set? [header: header or shift/left 1 27]
		if lf? [header: header or lf-flag]
		emit header
		emit-symbol word
		idx: emit-ctx-info word ctx
		emit any [ctx-idx idx]
		if root [
			if debug? [print [index ": word :" mold word]]
			index: index + 1
		]
	]
	
	emit-block: func [
		blk [any-block!] lf? /with main-ctx [word!] /sub
		/local type item binding ctx idx emit?
	][
		if profile? [profile blk]
		
		type: case [
			all [path? :blk get-word? blk/1][
				blk/1: to word! blk/1 					;-- workround for missing get-path! in R2
				'get-path
			]
			blk/1 = #!map! [
				remove blk
				'map
			]
			'else [type?/word :blk]
		]
		emit-type select [
			block!		TYPE_BLOCK
			paren!		TYPE_PAREN
			path!		TYPE_PATH
			lit-path!	TYPE_LIT_PATH
			set-path!	TYPE_SET_PATH
			get-path	TYPE_GET_PATH
			map			TYPE_MAP
		] type lf?
		
		preprocess-directives blk
		unless type = 'map [emit (index? blk) - 1]		;-- head field
		emit length? blk
		if all [not sub debug?][
			print [index ": block" length? blk #":" copy/part mold/flat blk 60]
		]
		
		forall blk [
			lf?: if block? blk [new-line? blk]
			;if lf? [?? blk halt]
			item: blk/1
			either any-block? :item [
				either with [
					emit-block/sub/with :item lf? main-ctx 
				][
					emit-block/sub :item lf?
				]
			][
				emit?: case [
					unicode-char? :item [
						emit-char to integer! next item lf?
						no
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
						yes
					]
					percent-value? :item [
						emit-percent item lf?
						no
					]
					float-special? :item [
						emit-fp-special item lf?
						no
					]
					'else [yes]
				]
				
				if emit? [
					switch type?/word get/any 'item [
						word!
						set-word!
						lit-word!
						refinement!
						get-word! [emit-word :item ctx idx lf?]
						file!
						url!
						string!
						binary!   [emit-string item lf?]
						issue!	  [emit-issue item lf?]
						integer!  [emit-integer item lf?]
						decimal!  [emit-float item lf?]
						char!	  [emit-char to integer! item lf?]
						pair!	  [emit-pair item lf?]
						tuple!	  [emit-tuple item lf?]
						datatype! [emit-datatype item lf?]
						logic!	  [emit-logic item lf?]
						none! 	  [emit-none lf?]
						unset! 	  [emit-unset]
					]
				]
			]
		]
		if type = 'map [insert blk #!map!]
		unless sub [index: index + 1]
		index - 1										;-- return the block index
	]
	
	emit-context: func [
		name [word!] spec [block!] stack? [logic!] self? [logic!] /root
		/local header
	][
		repend contexts [name copy spec index]			;-- COPY to avoid late word decorations
		header: extracts/definitions/TYPE_CONTEXT or shift/left 1 8 ;-- header
		if stack? [header: header or shift/left 1 29]
		if self?  [header: header or shift/left 1 28]
		
		emit header
		emit length? spec
		foreach word spec [emit-symbol word]
		if root [
			if debug? [print [index ": context :" copy/part mold/flat spec 50 "," stack? "," self?]]
			index: index + 1
		]
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
	
	finish: func [spec [block!] /local flags compress? data out len][
		pad sym-string 8
		flags: #{04}
		
		repend header [
			to-bin32 index - 1							;-- number of root records
			to-bin32 length? buffer						;-- size of records in bytes
			to-bin32 length? symbols
			to-bin32 length? sym-string
			sym-table
			sym-string
		]
		insert buffer header
		
		if compress?: find spec 'compress [
			flags: flags or #{02}
			out: make binary! len: length? buffer
			insert/dup out null len
			len: redc/crush-compress buffer len out
			clear buffer
			insert/part buffer out len
		]
		
		clear header
		repend header [
			"REDBIN"
			#{01}										;-- version: 1
			flags										;-- flags: symbols [+ options]
		]
		insert buffer header
	]
]
