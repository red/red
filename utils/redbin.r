REBOL [
	Title:   "Redbin format encoder for Red compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %redbin.r
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

context [
	header:		make binary! 10'000
	buffer:		make binary! 200'000
	sym-string:	make binary! 10'000
	sym-offsets: make block!  1'000						;-- byte offset of each symbol in sym-string
	symbols:	make hash! 	 1'000						;-- [word1 word2 ...]
	contexts:	make hash!	 1'000						;-- [name [symbols] index ...]
	index:		0
	
	stats:		make block! 100
	profile?:	no
	debug?:		no
	
	UTF8-char:	lexer/UTF8-char
	chars: 		make block!  10'000
	decoded: 	make binary! 10'000
	nl?:		no

	CP_MODIFIER: 64										;-- compact tag space (see runtime/redbin.reds)
	CP_INT0:	 128									;-- 80h-BFh integer! immediates 0-63
	CP_NL:		 192									;-- C0h new-line marker
	CP_TRUE:	 194									;-- C2h
	CP_FALSE:	 195									;-- C3h
	CP_GSET:	 196									;-- C4h global-set word marker

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
	
	preprocess-directives: func [blk][
		forall blk [
			if blk/1 = #get-definition [				;-- temporary directive
				value: select extracts/definitions blk/2
				change/only/part blk value 2
			]
		]
	]
	
	decode-UTF8: func [str [string! file! url! tag! email!] /local upper s e cp unit new][
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
	
	to-varint: func [n [number!] /local out g done?][	;-- LEB128, 32-bit unsigned in decimal domain
		if n < 0 [n: 4294967296.0 + n]
		out: make binary! 5
		until [
			g: to integer! n // 128
			n: (n - (n // 128)) / 128
			done?: zero? n
			append out to char! g + pick [0 128] done?
			done?
		]
		out
	]

	emit-byte: func [b [integer!]][append buffer to char! b]
	
	emit-varint: func [n [number!]][append buffer to-varint n]

	emit-svarint: func [n [number!]][					;-- zigzag-mapped signed varint
		emit-varint either n < 0 [-2.0 * n - 1][2.0 * n]
	]
	
	emit-tag: func [type [word!] /mod /local b][
		if nl? [emit-byte CP_NL nl?: no]
		b: extracts/definitions/:type
		if mod [b: b or CP_MODIFIER]
		emit-byte b
	]
	
	emit-u32-le: func [n [integer!]][append buffer to-bin32 n]	;-- to-bin32 is little-endian

	emit-float64-le: func [f [decimal! issue!]][
		append buffer head reverse IEEE-754/to-binary64 f
	]
	
	same-float?: func [a [decimal!] b [decimal!]][		;-- bit-exact: R2's `=` is fuzzy for decimals
		(IEEE-754/to-binary64 a) = (IEEE-754/to-binary64 b)
	]
	
	emit-float32-le: func [f [decimal! issue!]][
		append buffer IEEE-754/to-binary32/rev f
	]

	emit-unset: does [emit-tag 'TYPE_UNSET]

	emit-none: does [emit-tag 'TYPE_NONE]
	
	emit-datatype: func [type [datatype! word!]][
		unless word? type [type: to word! mold type]
		emit-tag 'TYPE_DATATYPE
		emit-varint extracts/definitions/:type
	]
	
	emit-logic: func [value [logic!]][
		if nl? [emit-byte CP_NL nl?: no]
		emit-byte either value [CP_TRUE][CP_FALSE]
	]
	
	emit-float: func [value [decimal!] /with type /local i][
		either all [
			value >= -2147483000.0
			value <= 2147483000.0
			same-float? value to decimal! i: to integer! value	;-- exact whole number (also rejects -0.0)
		][
			emit-tag/mod any [type 'TYPE_FLOAT]			;-- whole-number short form
			emit-svarint i
		][
			emit-tag any [type 'TYPE_FLOAT]
			emit-float64-le value
		]
	]
	
	emit-fp-special: func [value [issue!]][
		emit-tag 'TYPE_FLOAT
		emit-float64-le value
	]

	emit-percent: func [value [issue!] /local d k][
		d: to decimal! append to string! copy/part value back tail value "e-2"	;-- (#5753)
		k: 0
		either all [
			d >= -21474836.0
			d <= 21474836.0
			same-float? d ((to decimal! k: to integer! d * 100.0) / 100.0)	;-- exact round-trip only
		][
			emit-tag/mod 'TYPE_PERCENT					;-- hundredths short form
			emit-svarint k
		][
			emit-tag 'TYPE_PERCENT
			emit-float64-le d
		]
	]
	
	emit-time: func [value [time!] /local f i][
		f: to decimal! value
		either all [
			f >= -2147483000.0
			f <= 2147483000.0
			same-float? f to decimal! i: to integer! f	;-- exact whole seconds only
		][
			emit-tag/mod 'TYPE_TIME
			emit-svarint i
		][
			emit-tag 'TYPE_TIME
			emit-float64-le f
		]
	]
	
	emit-date: func [value [date!] /with zone][
		either value/time [
			emit-tag/mod 'TYPE_DATE
			emit-u32-le red/encode-date/with value zone
			emit-float64-le encode-UTC-time value/time any [zone value/zone]
		][
			emit-tag 'TYPE_DATE
			emit-u32-le red/encode-date/with value zone
		]
	]

	emit-char: func [value [integer!]][
		emit-tag 'TYPE_CHAR
		emit-varint value
	]
	
	emit-integer: func [value [integer!]][
		either all [value >= 0 value <= 63][
			if nl? [emit-byte CP_NL nl?: no]
			emit-byte CP_INT0 + value					;-- integer! immediate
		][
			emit-tag 'TYPE_INTEGER
			emit-svarint value
		]
	]

	emit-pair: func [value [pair!]][
		emit-tag 'TYPE_PAIR
		emit-svarint value/x
		emit-svarint value/y
	]
	
	emit-point: func [list [block!]][
		emit-tag select [2 TYPE_POINT2D 3 TYPE_POINT3D] length? list
		forall list [emit-float32-le either integer? list/1 [to decimal! list/1][list/1]]
	]

	emit-tuple: func [value [issue!] /local bin size][
		bin: debase/base next value 16
		size: length? bin
		either size = 3 [
			emit-tag 'TYPE_TUPLE
		][
			emit-tag/mod 'TYPE_TUPLE
			emit-byte size
		]
		append buffer bin
	]
	
	emit-money: func [value [issue!]][
		value: to string! next value
		either value/4 = #"-" [
			emit-tag/mod 'TYPE_MONEY					;-- negative amount
		][
			emit-tag 'TYPE_MONEY
		]
		append buffer either value/1 = #"." [null][to-char to-currency-code copy/part value 3]
		append buffer to binary! to-nibbles copy/part skip value 4 22		;-- nibbles array
	]
	
	emit-native: func [id [word!] spec [block!] /action][
		emit-tag pick [TYPE_ACTION TYPE_NATIVE] to logic! action
		emit-varint extracts/definitions/:id
		emit-block/sub spec
	]
	
	emit-typeset: func [v1 [integer!] v2 [integer!] v3 [integer!] /root /local bin][
		bin: rejoin [to-bin32 v1 to-bin32 v2 to-bin32 v3]
		while [all [not empty? bin zero? last bin]][clear back tail bin]		;-- trim trailing zero bytes
		emit-tag 'TYPE_TYPESET
		emit-byte length? bin
		append buffer bin
		
		if root [
			if debug? [print [index ": typeset"]]
			index: index + 1
		]
		index - 1
	]
	
	emit-string: func [str [any-string!] /root /local type unit][
		type: either issue? str ['TYPE_REF][				;-- internal encoding of ref! datatype
			select [
				string! TYPE_STRING
				file!	TYPE_FILE
				tag!	TYPE_TAG
				url!	TYPE_URL
				email!	TYPE_EMAIL
				binary! TYPE_BINARY
			] type?/word str
		]
		
		str: to string! str									;-- head is always zero (v1 boot payload)
		emit-tag type
		either type = 'TYPE_BINARY [						;-- binary! is an any-string! in R2, but decodes
			emit-varint length? str							;-- via decode-binary-cp: plain byte length
		][													;-- any-string!: raw UCS-1/2/4, unit packed into length
			set [str unit] decode-UTF8 str
			emit-varint (length? str) / unit * 4 + select [1 0 2 1 4 2] unit
		]
		append buffer str

		if root [
			if debug? [print [index ": string :" copy/part str 40]]
			index: index + 1
		]
		index - 1
	]
	
	emit-issue: func [value [issue!]][
		emit-tag 'TYPE_ISSUE
		emit-symbol to word! form value
	]
	
	emit-symbol: func [word /local pos s][
		word: to word! word
		
		unless pos: find/case symbols word [
			s: tail sym-string
			append sym-offsets -1 + index? s			;-- byte offset of this symbol in sym-string
			repend sym-string [word null]
			append symbols word
			pos: back tail symbols
		]
		emit-varint (index? pos) - 1					;-- emit index of symbol
	]
	
	emit-word: func [
		word ctx [word! none!] ctx-idx [integer! none!] /root /set?
		/local type entry pos ctx-field idx
	][
		type: select [
			word!		TYPE_WORD
			set-word!	TYPE_SET_WORD
			get-word!	TYPE_GET_WORD
			refinement! TYPE_REFINEMENT
			lit-word!	TYPE_LIT_WORD
		] type?/word :word
		
		ctx-field: -1
		idx: -1
		if all [ctx entry: find contexts ctx][
			if pos: find entry/2 to word! word [
				ctx-field: entry/3
				idx: (index? pos) - 1
			]
		]
		idx: any [ctx-idx idx]

		if set? [emit-byte CP_GSET]						;-- global-set: value record follows
		either ctx-field = -1 [
			emit-tag type								;-- canonical form: global binding
			emit-symbol word
		][
			emit-tag/mod type
			emit-symbol word
			emit-varint ctx-field						;-- context record index among roots
			emit-svarint idx
		]
		if root [
			if debug? [print [index ": word :" mold word]]
			unless set? [index: index + 1]
		]
		index - 1
	]
	
	emit-block: func [
		blk [any-block! path! lit-path! set-path!] /with main-ctx [word!] /sub
		/local type item binding ctx idx emit? multi-line? ofs
	][
		if profile? [profile blk]
		
		type: case [
			all [path? :blk get-word? blk/1][
				blk: copy blk							;-- avoid modifying path in-place (see #4517)
				blk/1: to word! blk/1 					;-- workround for missing get-path! in R2
				'get-path
			]
			blk/1 = #!map! [
				remove blk
				'map
			]
			blk/1 = #!point! [
				emit-point next blk
				exit
			]
			blk/1 = #!date! [
				emit-date/with blk/2 blk/3
				exit
			]
			'else [type?/word :blk]
		]
		type: select [
			block!		TYPE_BLOCK
			paren!		TYPE_PAREN
			path!		TYPE_PATH
			lit-path!	TYPE_LIT_PATH
			set-path!	TYPE_SET_PATH
			get-path	TYPE_GET_PATH
			map			TYPE_MAP
		] type
		
		preprocess-directives blk
		ofs: (index? blk) - 1
		either any [type = 'TYPE_MAP zero? ofs][emit-tag type][
			emit-tag/mod type							;-- non-zero head
			emit-varint ofs
		]
		emit-varint length? blk
		if all [not sub debug?][
			print [index ": block" length? blk #":" trim/lines copy/part mold/flat blk 60]
		]
		nl?: no
		multi-line?: any [block? blk paren? blk]

		forall blk [
			if multi-line? [nl?: new-line? blk]
			item: blk/1
			either any-block? :item [
				either with [
					emit-block/sub/with :item main-ctx
				][
					emit-block/sub :item
				]
			][
				emit?: case [
					issue? :item [
						case [
							unicode-char? :item [
								emit-char to integer! next item
								no
							]
							tuple-value? :item [
								emit-tuple item
								no
							]
							percent-value? :item [
								emit-percent item
								no
							]
							float-special? :item [
								emit-fp-special item
								no
							]
							money-value? :item [
								emit-money item
								no
							]
							ref-value? :item [
								emit-string next item
								no
							]
							type-value? :item [
								emit-datatype get-RS-type-ID/word to-word form skip item 2
								no
							]
							'else [
								emit-issue item
								no
							]
						]
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
					'else [yes]
				]
				
				if emit? [
					switch type?/word get/any 'item [
						word!
						set-word!
						lit-word!
						refinement!
						get-word! [emit-word :item ctx idx]
						file!
						url!
						tag!
						email!
						string!
						binary!   [emit-string item]
						integer!  [emit-integer item]
						decimal!  [emit-float item]
						char!	  [emit-char to integer! item]
						pair!	  [emit-pair item]
						datatype! [emit-datatype get-RS-type-ID/word item]
						logic!	  [emit-logic item]
						time!	  [emit-time item]
						date!	  [emit-date item]
						none! 	  [emit-none]
						unset! 	  [emit-unset]
					]
				]
			]
		]
		nl?: no
		if type = 'TYPE_MAP [insert blk #!map!]
		unless sub [index: index + 1]
		index - 1										;-- return the block index
	]
	
	emit-context: func [
		name [word!] spec [block!] stack? [logic!] self? [logic!] type [word!] /root
		/local flags
	][
		repend contexts [name copy spec index]			;-- COPY to avoid late word decorations
		flags: select [function 1 object 2] type
		if stack? [flags: flags or 4]
		if self?  [flags: flags or 8]
		
		emit-tag 'TYPE_CONTEXT
		emit-byte flags
		emit-varint length? spec
		foreach word spec [emit-symbol word]
		if root [
			if debug? [print [index ": context :" trim/lines copy/part mold/flat spec 50 "," stack? "," self?]]
			index: index + 1
		]
		index - 1
	]
	
	init: does [
		clear header
		clear buffer
		clear sym-string
		clear sym-offsets
		clear symbols
		clear contexts
	]
	
	finish: func [spec [block!] /local flags compress? out len][
		flags: #{05}									;-- compact + symbol table
		
		repend header [
			to-varint index - 1							;-- number of root records
			to-varint length? buffer					;-- size of records in bytes
			to-varint length? symbols
			to-varint length? sym-string
		]
		foreach ofs sym-offsets [append header to-bin32 ofs]	;-- per-symbol offsets (4-byte LE), read in place
		append header sym-string
		insert buffer header
		
		if all [
			compress?: find spec 'compress
			128 < len: length? buffer
		][
			out: make binary! len
			insert/dup out null len
			len: redc/crush-compress buffer len out
			if len > 0 [
				flags: flags or #{02}
				clear buffer
				insert/part buffer out len
			]
		]
		
		clear header
		repend header [
			"REDBIN"
			#{01}										;-- version: 1
			flags										;-- flags: compact + symbols [+ options]
		]
		insert buffer header
	]
]