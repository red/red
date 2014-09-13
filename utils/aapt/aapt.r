REBOL [
	Title:   "Android Asset Packaging Tool (aapt)"
	Author:  "Qingtian Xie"
	File: 	 %aapt.r
	Type:	 'library
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

do %rebzip.r

aapt: context [

	android-res: reduce load %android-res.r
	res-tools-ns: "http://schemas.android.com/tools"
	res-prv-ns: "http://schemas.android.com/apk/prv/res/"
	res-root-ns: "http://schemas.android.com/apk/res/"
	res-android-ns: "http://schemas.android.com/apk/res/"
	res-auto-package-ns: "http://schemas.android.com/apk/res-auto"

	digit: charset [#"0" - #"9"]
	lower-alpha: charset [#"a" - #"z"]
	upper-alpha: charset [#"A" - #"Z"]
	units: ["px" | "dip" | "dp" | "sp" | "pt" | "in" | "mm" | "%p" | "%"]

	sdk: [
		cupcake					3
		donut					4
		eclair					5
		eclair_0_1				6
		mr1						7
		froyo					8
		honeycomb_mr2			13
		ice_cream_sandwich		14
		ice_cream_sandwich_mr1	15
	]

	value-type: [						;-- type of the data value in 'res-value/data'
		null			#{00}			;-- no data
		reference		#{01}			;-- a reference to another resource table entry
		attribute		#{02}			;-- an attribute resource identifier
		string			#{03}			;-- an index into the containing resource table's global value string pool
		float			#{04}			;-- a single-precision floating point number
		dimension		#{05}			;-- a complex number encoding a dimension value,such as "100in"
		fraction		#{06}			;-- a complex number encoding a fraction of a container,such as "20%"
		first-int		#{10}			;-- beginning of integer flavors...
		int-dec			#{10}			;-- a raw integer value of the form n..n
		int-hex			#{11}			;-- a raw integer value of the form 0xn..n
		int-bool		#{12}			;-- either 0 or 1, for input "false" or "true" respectively
		first-color		#{1C}			;-- beginning of color integer flavors...
		color-ARGB8		#{1C}			;-- a raw integer value of the form #aarrggbb
		color-RGB8		#{1D}			;-- a raw integer value of the form #rrggbb
		color-ARGB4		#{1E}			;-- a raw integer value of the form #argb
		color-RGB4		#{1F}			;-- a raw integer value of the form #rgb
		last-color		#{1F}			;-- ...end of color integer flavors
		last-int		#{1F}			;-- ...end of integer flavors
	]

	attribute-flags: [
		type			16777216		;-- this entry holds the attribute's type code
		min				16777217		;-- this is the minimum value it can hold
		max				16777218		;-- this is the maximum value it can hold
		L10N			16777219		;-- localization of this resource is can be encouraged
	]

	plurals-flags: [
		"other"			16777220		;-- for plural support, see android.content.res.PluralRules#attrForQuantity(int)
		"zero"			16777221
		"one"			16777222
		"two"			16777223
		"few"			16777224
		"many"			16777225
	]

	attribute-type: [
		"any"			65535			;-- no type has been defined for this attribute
		"reference"		1
		"string"		2
		"integer"		4
		"boolean"		8
		"color"			16
		"float"			32
		"dimension"		64
		"fraction"		128
		"enum"			65536			;-- the enumeration values are supplied as additional entries in the map
		"flags"			131072			;-- the flag bit values are supplied as additional entries in the map
	]

	L10N-flags: [
		"required"		0
		"suggested"		1
	]

	resource-type: [
		null			#{0000}
		string-pool		#{0001}
		table			#{0002}
		xml				#{0003}
	]

	xml-type: [
		first-chunk		#{0100}
		start-namespace #{0100}
		end-namespace	#{0101}
		start-element	#{0102}
		end-element		#{0103}
		CDATA			#{0104}
		last-chunk		#{017F}
		resource-map	#{0180}
	]

	table-type: [
		package			#{0200}
		type-info		#{0201}
		type-spec		#{0202}
	]

	string-pool-flags: [					;-- flags of the 'string-pool-header/flags'
		sorted			1					;-- if set, the string index is sorted by the string values
		UTF-8			256					;-- string pool is encoded in UTF-8
	]

	config-flags: [
		mcc						1
		mnc						2
		locale					4
		touchscreen				8
		keyboard				16
		keyboard-hidden 		32
		navigation				64
		orientation				128
		density					256
		screen-size				512
		smallest-screen-width	8192		;-- #{2000}
		version					1024
		screen-layout			2048
		ui-mode					4096
		layout-direction		16384		;-- #{4000}
	]

	chunk-header: make-struct [				;-- Header that appears at the front of every data chunk in a resource.
		type			[short]				;-- Type identifier for this chunk
		header-size		[short]				;-- size? chunk-header
		size			[integer!]			;-- size? chunk-header + size? data
	] [0 8]

	res-value: make-struct [
		size			[short]
		res0			[char]				;-- always set to 0
		datatype		[char]
		data			[integer!]
	] [8 0 16 0]

	string-pool-header: make-struct [
		type			[short]				;-- a chunk-header
		header-size		[short]
		size			[integer!]
		string-count	[integer!]
		style-count		[integer!]
		flags			[integer!]
		strings-start	[integer!]
		styles-start	[integer!]
	] none

	string-pool-span: make-struct [
		name-idx		[integer!]			;-- 0xFFFFFFFF, indicates the end of an array of spans
		first-char		[integer!]
		last-char		[integer!]
	] [-1]

	;-------------------------------------------------------
	;-- Binary XML Tree Structs
	;-------------------------------------------------------
	xmltree-header: make-struct [
		type			[short]				;-- a chunk-header
		header-size		[short]
		size			[integer!]
	] [0 8]

	xmltree-node: make-struct [
		type			[short]				;-- a chunk-header
		header-size		[short]
		size			[integer!]
		line-number		[integer!]
		comment-idx		[integer!]			;-- optional; -1 if none.
	] [0 16 0 0 -1]

	xmltree-namespace-ext: make-struct [
		prefix-idx		[integer!]
		uri-idx			[integer!]
	] none

	xmltree-cdata-ext: make-struct [
		data-idx		[integer!]
		size			[short]				;-- a res-value
		res0			[char]
		datatype		[char]
		data			[integer!]
	] none

	xmltree-attr-ext: make-struct [
		ns-idx			[integer!]
		name-idx		[integer!]
		attr-start		[short]
		attr-size		[short]
		attr-count		[short]
		id-idx			[short]
		class-idx		[short]
		style-idx		[short]
	] [-1 -1 20 20]

	xmltree-attribute: make-struct [
		ns-idx			[integer!]
		name-idx		[integer!]
		raw-value-idx	[integer!]
		size			[short]				;-- a res-value
		res0			[char]
		datatype		[char]
		data			[integer!]
	] [-1 -1 -1 8]

	xmltree-end-element-ext: make-struct [
		ns-idx			[integer!]
		name-idx		[integer!]
	] [-1]

	;-------------------------------------------------------
	;-- Resource Table Structs
	;-------------------------------------------------------
	res-table-header: make-struct [
		type			[short]				;-- a chunk-header
		header-size		[short]
		size			[integer!]
		package-count	[integer!]
	] none

	res-table-package: make-struct [
		type			[short]				;-- a chunk-header
		header-size		[short]
		size			[integer!]
		id				[integer!]
		name			[binary!]			;-- char16_t name[128]
		type-strings	[integer!]
		last-type		[integer!]
		key-strings		[integer!]
		last-key		[integer!]
	] [512 284]

	res-table-config: make-struct [
		size				[integer!]
		mcc					[short]
		mnc					[short]
		language1			[char]
		language2			[char]
		country1			[char]
		country2			[char]
		orientation			[char]
		touchscreen			[char]
		density				[short]
		keyboard			[char]
		navigation			[char]
		input-flags			[char]
		inputPad0			[char]
		screen-width		[short]
		screen-height		[short]
		sdk-version			[short]
		minor-version		[short]				;-- for now minor version must always be 0!!!
		screen-layout		[char]
		ui-mode				[char]
		smallest-width-dp	[short]
		screen-width-dp		[short]
		screen-height-dp	[short]
		locale-script		[integer!]
		locale-variant		[decimal!]
	] [48 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]

	res-table-type-spec: make-struct [
		type				[short]				;-- a chunk-header
		header-size			[short]
		size				[integer!]
		id					[char]
		res0				[char]
		res1				[short]
		entry-count			[integer!]
	] none

	res-table-type: make-struct [
		type				[short]				;-- a chunk-header
		header-size			[short]
		size				[integer!]
		id					[char]
		res0				[char]
		res1				[short]
		entry-count			[integer!]
		entries-start		[integer!]
		;config				[res-table-config]
	] [513 68]

	res-table-entry: make-struct [
		size			[short]
		flags			[short]
		key-string-idx	[integer!]
	] [8]

	res-table-map-entry: make-struct [
		;entry			[res-table-entry]
		parent			[integer!]
		count			[integer!]
	] [0 0]

	res-table-map: make-struct [
		name-id			[integer!]
		;value			[res-value]
	] [-1]

	pad4: func [s [string! binary!] /local rem][
		unless zero? rem: (length? s) // 4 [
			insert/dup tail s #"^@" 4 - rem
		]
		s
	]

	get-hex: func [c [char!]][
		case [
			all [c >= #"0" c <= #"9"] [c - #"0"]
			all [c >= #"a" c <= #"f"] [c - #"a" + 10]
			all [c >= #"A" c <= #"F"] [c - #"A" + 10]
		]
	]

	hex-to-integer: func [str [string!] /local int value][
		int: 0
		foreach c skip str 2 [
			value: get-hex c
			int: int * 16 + value
		]
		int
	]

	udata: [0 192 224 240 248 252]

	unicode-to-utf8: func [cp [integer!] /local result][
		result: make string! 4
		either cp < 128 [
			insert tail result to-char cp
		][
			either cp < 256 [
				cp: to-char cp
				insert insert tail result cp / 64 or 192 cp and 63 or 128
			][
				result: tail result
				until [
					insert result to char! cp and 63 or 128
					128 > cp: cp and -64 / 64
				]
				insert result to char! cp or pick udata 1 + length? result
			]
		]
		head result
	]

	utf8-to-utf16: func [s [string!] /length /local m cp result cnt][
		result: make string! (length? s) * 2
		cnt: 0
		while [not tail? s][
			cp: first s
			cnt: cnt + 1
			either cp < 128 [
				unless length [repend result [cp #"^@"]]
			][
				m: 8 - length? find	enbase/base	to binary! cp 2 #"0"
				cp: cp xor pick udata m
				loop m - 1 [cp: 64 * cp + (63 and first s: next s)]		;--	code point
				either cp < 65536 [
					unless length [append result to-bin16 cp]
				][
					;--	multiple UTF16 characters with surrogates
					either length [cnt: cnt + 1][
						cp: cp - 65536
						append result to-bin16 55296 + shift/logical cp 10
						append result to-bin16 cp and 1023 + 56320
					]
				]
			]
			s: next s
		]
		either length [cnt][result]
	]

	clean-block: func [blk [block! none!] /local new][
		if none? blk [return make block! 1]
		new: make block! length? blk
		foreach value blk [
			either block? value [
				append/only new clean-block value
			][
				if any [
					none? value
					not empty? trim copy value
				][append new value]
			]
		]
		new
	]

	get-res-id: func [
		type [string!] key [string!] all-res [block!]
		/local
			parts info local-info types id type-id key-id
	][
		if key = "null" [return 0]
		info: select android-res type
		local-info: select all-res/4/4 type
		parts: parse key ":"
		either parts/2 [
			either parts/1 = "android" [
				key: parts/2
				parts: parse key "/"
				if parts/2 [type: parts/1 key: parts/2]
				info: select android-res type
				id: select info key
				id: hex-to-integer either type = "attr" [id/1][id]
			][
				;TODO find in other namespaces
			]
		][
			parts: parse key "/"
			if parts/2 [type: parts/1 key: parts/2]
			types: all-res/4/2
			if type = "+id" [
				type: "id"
				res: compose/deep [
					"id"
					["name" (key)]
					"false"
				]
				collect-resource res 'default all-res
			]

			local-info: select all-res/4/4 type
			type-id: index? find types type
			key-id: (index? find local-info/1 key) - 1
			id: key-id
				or (shift/left type-id 16)
				or (shift/left 127 24)
		]
		id
	]

	get-color-value: func [str [string!] value [object!] /local len color][
		len: length? str
		color: 0
		case [
			len = 4 [
				value/datatype: to-integer value-type/color-RGB4
				color: color or to-integer #{FF000000}
				color: color or shift/left get-hex str/2 20
				color: color or shift/left get-hex str/2 16
				color: color or shift/left get-hex str/3 12
				color: color or shift/left get-hex str/3 8
				color: color or shift/left get-hex str/4 4
				color: color or get-hex str/4
			]
			len = 5 [
				value/datatype: to-integer value-type/color-ARGB4
				color: color or shift/left get-hex str/2 28
				color: color or shift/left get-hex str/2 24
				color: color or shift/left get-hex str/3 20
				color: color or shift/left get-hex str/3 16
				color: color or shift/left get-hex str/4 12
				color: color or shift/left get-hex str/4 8
				color: color or shift/left get-hex str/5 4
				color: color or get-hex str/5
			]
			len = 7 [
				value/datatype: to-integer value-type/color-RGB8
				color: color or to-integer #{FF000000}
				color: color or shift/left get-hex str/2 20
				color: color or shift/left get-hex str/3 16
				color: color or shift/left get-hex str/4 12
				color: color or shift/left get-hex str/5 8
				color: color or shift/left get-hex str/6 4
				color: color or get-hex str/7
			]
			len = 9 [
				value/datatype: to-integer value-type/color-ARGB8
				color: color or shift/left get-hex str/2 28
				color: color or shift/left get-hex str/3 24
				color: color or shift/left get-hex str/4 20
				color: color or shift/left get-hex str/5 16
				color: color or shift/left get-hex str/6 12
				color: color or shift/left get-hex str/7 8
				color: color or shift/left get-hex str/8 4
				color: color or get-hex str/9
			]
			'else [print ["AAPT: Color Format error" str] halt]
		]
		value/data: color
	]

	get-unit-value: func [
		str [string!] value [object!]
		/local unit-names f unit s e data bits neg? radix sft m
	][
		unit-names: [
			"px"	5	0	1.0
			"dip"	5	1	1.0
			"dp"	5	1	1.0
			"sp"	5	2	1.0
			"pt"	5	3	1.0
			"in"	5	4	1.0
			"mm"	5	5	1.0
			"%" 	6	0	0.01
			"%p"	6	1	0.01
		]
		parse str [
			s: opt [#"-" | #"+"] some digit e: (f: to decimal! copy/part s e)
			units s: (unit: copy/part e s)
		]
		unit: find/tail unit-names unit
		value/datatype: unit/1
		data: unit/2

		f: f * unit/3
		if neg?: negative? f [f: abs f]
		bits: attempt [to-integer f * 8388608 + 0.5]			;@@ should use int64!
		either bits [
			case [
				zero? bits and 8388607 [radix: 0 sft: 23]
				zero? bits and -8388608 [radix: 3 sft: 0]
				zero? bits and -2147483648 [radix: 2 sft: 8]
				'else [radix: 1 sft: 16]
			]
			m: (shift/logical bits sft) and 16777215
			if neg? [m: (negate m) and 16777215]
			value/data: data or (shift/left radix 4) or (shift/left m 8)
		][
			print ["AAPT: Integer Overflow" str]
		]
	]

	parse-value: func [
		str				[string! integer! block! none!]
		type			[string!]
		value-strings	[block!]
		all-res			[block!]
		/local res v idx
	][
		res: make-struct res-value none
		v: attempt [load str]
		case [
			integer? str [
				res/datatype: to-integer value-type/string
				res/data: str + length? all-res/2
			]
			type = "id" [
				res/datatype: to-integer value-type/int-bool
				res/data: 0
			]
			type = "boolean" [
				res/datatype: to-integer value-type/int-bool
				res/data: either str = "true" [-1][0]
			]
			#"#" = first str [
				get-color-value str res
			]
			#"@" = first str [
				res/datatype: to-integer value-type/reference
				res/data: get-res-id type next str all-res
			]
			#"?" = first str [
				res/datatype: to-integer value-type/attribute
				res/data: get-res-id type next str all-res
			]
			parse str ["0x" some digit end] [
				res/datatype: to-integer value-type/int-hex
				res/data: hex-to-integer str
			]
			all [type <> "string" integer? v] [
				res/datatype: to-integer either type = "flag" [
					value-type/int-hex
				][value-type/int-dec]
				res/data: v
			]
			all [type <> "string" decimal? v] [
				res/datatype: to-integer value-type/float
				res/data: v
			]
			parse str [opt [#"-" | #"+"] some digit units] [
				get-unit-value str res
			]
			'else [
				res/datatype: to-integer value-type/string
				either idx: find value-strings str [
					res/data: (index? idx) - 1
				][
					print ["AAPT: Can't resolve value" type str]
				]
			]
		]
		res
	]

	add-to-string-pool: func [pool [block!] str [string!] /local value idx][
		either value: find pool str [
			(index? value) - 1
		][
			idx: length? pool
			append pool str
			idx
		]
	]

	normalize-string: func [s [string!] /local quoted? new unicode][
		trim/head/tail s
		if all [
			#"^"" = first s
			#"^"" = last  s
		][
			quoted?: yes
			remove s
			remove back tail s
		]

		new: make string! length? s
		until [
			either s/1 = #"\" [
				if none? s/2 [return new]
				append new switch/default s/2 [
					#"t" [#"^-"]
					#"n" [#"^/"]
					#"u" [
						unicode: copy/part s 6
						s: skip s 5
						unicode-to-utf8 hex-to-integer unicode
					]
				][s/1]
				s: next s
			][
				append new either s/1 = #"^/" [
					either quoted? [s/1][
						while [s/2 <= #" "][s: next s]
						#" "
					]
				][s/1]
			]
			s: next s
			tail? s
		]
		new
	]

	compile-style-string: func [strings [block!]
		/local new styles str span style start style?
	][
		styles: make block! 4
		unless block? strings/1 [return styles]

		start: strings
		new: make block! length? strings
		until [
			style?: false
			str: copy ""
			style: make binary! 64
			foreach s strings/1 [
				append str either string? s [s][
					if any [s/1 = "b" s/1 = "i" s/1 = "u"][
						style?: true
						span: make-struct string-pool-span none
						span/name-idx: add-to-string-pool start s/1
						span/first-char: length? str
						span/last-char: span/first-char + (length? s/3/1) - 1
						append style form-struct span
					]
					s/3/1
				]
			]
			if style? [
				append style #{FFFFFFFF}
				append styles style
			]
			append new normalize-string str
			strings: next strings
			string? strings/1
		]
		append new strings
		append clear start new
		styles
	]

	compile-string-pool: func [
		strings [block!]
		/utf-16
		/local styles header offsets buf base u8len u16len
	][
		styles: compile-style-string strings
		offsets: make binary! 32
		buf: make binary! 512
		foreach str strings [
			append offsets to-bin32 length? buf
			either utf-16 [									;-- UTF-16: maximum length: 0x7FFFFFF (2147483647 bytes)
				str: utf8-to-utf16 str
				if 32767 < u16len: (length? str) / 2 [
					append buf to-bin16 (32767 and shift u16len 16) or 32768
				]
				append buf to-bin16 u16len
			][												;-- UTF-8: maximum length: 0x7FFF (32767 bytes)
				u8len: length? str
				u16len: utf8-to-utf16/length str
				if 127 < u16len [
					append buf to-bin8 (127 and shift u16len 8) or 128
				]
				append buf to-bin8 u16len
				if 127 < u8len [
					append buf to-bin8 (127 and shift u8len 8) or 128
				]
				append buf to-bin8 u8len
			]
			append buf str
			append buf either utf-16 [#{0000}][#{00}]		;-- null char
		]
		buf: pad4 buf

		base: length? buf
		foreach style styles [
			append offsets to-bin32 (length? buf) - base
			append buf style
		]

		header:               make-struct string-pool-header none
		header/type:          to-integer resource-type/string-pool
		header/header-size:   length? form-struct header
		header/string-count:  length? strings
		header/style-count:   length? styles
		header/strings-start: header/header-size
							+ (4 * length? strings)
							+ (4 * length? styles)
		header/styles-start: either empty? styles [0][
								append buf #{FFFFFFFFFFFFFFFF}
								header/strings-start + base
							]
		unless utf-16 [header/flags: string-pool-flags/UTF-8]
		header/size: header/header-size
					+ (length? offsets)
					+ (length? buf)
		repend form-struct header [offsets buf]
	]

	get-package-name: func [manifest [file!] /local xml name][
		xml: parse-xml read manifest
		xml: xml/3/1
		either xml/1 = "manifest" [
			name: select xml/2 "package"
		][
			print ["AAPT: Not a manifest file:" manifest]
			halt
		]
		name
	]

	get-mcc: func [part [string!] config [object!] /local value][
		if parse part [
			"any" (value: 0)
			| "mcc" s: some digit e: end (value: to-integer copy/part s e)
		][
			config/mcc: value
		]
	]

	get-mnc: func [part [string!] config [object!] /local value][
		if part = "any" [config/mnc: 0 return true]
		if parse part ["mnc" s: some digit e: end] [
			value: to-integer copy/part s e
			config/mnc: either zero? value [-1][value]
		]
	]

	get-language: func [part [string!] config [object!]][
		parse/case part [
			"any" | "default"
			| 2 lower-alpha end
			(config/language1: part/1 config/language2: part/2)
		]
	]

	get-country: func [part [string!] config [object!]][
		parse/case part [
			#"r" 2 upper-alpha end
			(config/country1: part/2 config/country2: part/3)
		]
	]

	get-layout-direction: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"ldltr"		64
			"ldrtl"		128
		]

		if value: select name part [
			config/screen-layout: config/screen-layout and 63 or value
		]
	]

	get-smallest-width-dp:  func [part [string!] config [object!] /local value][
		if parse part [
			"any" (value: 0)
			| "sw" s: some digit e: "dp" end (value: to-integer copy/part s e)
		][
			config/smallest-width-dp: value
		]
	]

	get-screen-width-dp: func [part [string!] config [object!] /local name value][
		if parse part [
			"any" (value: 0)
			| "w" s: some digit e: "dp" end (value: to-integer copy/part s e)
		][
			config/screen-width-dp: value
		]
	]

	get-screen-height-dp: func [part [string!] config [object!] /local name value][
		if parse part [
			"any" (value: 0)
			| "h" s: some digit e: "dp" end (value: to-integer copy/part s e)
		][
			config/screen-height-dp: value
		]
	]

	get-screen-layout-size: func [part [string!] config [object!] /local name value][
		name: [
			"any"		0
			"small"		1
			"normal"	2
			"large"		3
			"xlarge"	4
		]

		if value: select name part [
			config/screen-layout: config/screen-layout and 240 or value
		]
	]

	get-screen-layout-aspect: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"long"		32
			"notlong"	16
		]

		if value: select name part [
			config/screen-layout: config/screen-layout and 207 or value
		]
	]

	get-orientation: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"port"		1
			"land"		2
			"square"	3
		]

		if value: select name part [
			config/orientation: value
		]
	]

	get-UI-mode-type: func [part [string!] config [object!] /local name value][
		name: [
			"any" 			0
			"desk"			2
			"car"			3
			"television"	4
			"appliance"		5
			"watch"			6
		]

		if value: select name part [
			config/ui-mode: config/ui-mode and 240 or value
		]
	]

	get-UI-mode-night: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"night"		32
			"notnight"	16
		]

		if value: select name part [
			config/ui-mode: config/ui-mode and 207 or value
		]
	]

	get-density: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"nodpi"		65535
			"ldpi"		120
			"mdpi"		160
			"tvdpi"		213
			"hdpi"		240
			"xhdpi"		320
			"xxhdpi"	480
			"xxxhdpi"	640
		]

		either value: select name part [
			config/density: value
		][
			if parse part [s: some digit e: "dpi" end] [
				config/density: to-integer copy/part s e
			]
		]
	]

	get-touch-screen: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"notouch"	1
			"stylus"	2
			"finger"	3
		]

		if value: select name part [
			config/touchscreen: value
		]
	]

	get-keys-hidden: func [part [string!] config [object!] /local name value][
		name: [
			"any" 			0
			"keysexposed"	1
			"keyshidden"	2
			"keyssoft"		3
		]

		if value: select name part [
			config/input-flags: config/input-flags and 252 or value
		]
	]

	get-keyboard: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"nokeys"	1
			"qwerty"	2
			"12key"		3
		]

		if value: select name part [
			config/keyboard: value
		]
	]

	get-nav-hidden: func [part [string!] config [object!] /local name value][
		name: [
			"any" 			0
			"navexposed"	4
			"navhidden"		8
		]

		if value: select name part [
			config/input-flags: config/input-flags and 243 or value
		]
	]

	get-navigation: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"nonav"		1
			"dpad"		2
			"trackball" 3
			"whell"		4
		]

		if value: select name part [
			config/navigation: value
		]
	]

	get-screen-size: func [part [string!] config [object!] /local value][
		either part = "any" [
			config/screen-width: 0
			config/screen-height: 0
		][
			value: attempt [load part]
			if pair? value [
				config/screen-width: value/1
				config/screen-height: value/2
			]
		]
	]

	get-version: func [part [string!] config [object!] /local name value][
		if parse part [
			"any" (value: 0)
			| "v" s: some digit e: end (value: to-integer copy/part s e)
		][
			config/sdk-version: value
		]
	]

	parse-config: func [
		config-str [any-string!] config [object!]
		/local parts flag
	][
		flag: 0
		parts: parse config-str "-"
		if get-mcc parts/1 config [
			flag: flag or config-flags/mcc
			if tail? parts: next parts [return flag]
		]
		if get-mnc parts/1 config [
			flag: flag or config-flags/mnc
			if tail? parts: next parts [return flag]
		]
		if get-language parts/1 config [
			flag: flag or config-flags/locale
			if tail? parts: next parts [return flag]
		]
		if get-country parts/1 config [
			flag: flag or config-flags/locale
			if tail? parts: next parts [return flag]
		]
		if get-layout-direction parts/1 config [
			flag: flag or config-flags/layout-direction
			if tail? parts: next parts [return flag]
		]
		if get-smallest-width-dp parts/1 config [
			flag: flag or config-flags/smallest-screen-width
			if tail? parts: next parts [return flag]
		]
		if get-screen-width-dp parts/1 config [
			flag: flag or config-flags/screen-size
			if tail? parts: next parts [return flag]
		]
		if get-screen-height-dp parts/1 config [
			flag: flag or config-flags/screen-size
			if tail? parts: next parts [return flag]
		]
		if get-screen-layout-size parts/1 config [
			flag: flag or config-flags/screen-layout
			if tail? parts: next parts [return flag]
		]
		if get-screen-layout-aspect parts/1 config [
			flag: flag or config-flags/screen-layout
			if tail? parts: next parts [return flag]
		]
		if get-orientation parts/1 config [
			flag: flag or config-flags/orientation
			if tail? parts: next parts [return flag]
		]
		if get-UI-mode-type parts/1 config [
			flag: flag or config-flags/ui-mode
			if tail? parts: next parts [return flag]
		]
		if get-UI-mode-night parts/1 config [
			flag: flag or config-flags/ui-mode
			if tail? parts: next parts [return flag]
		]
		if get-density parts/1 config [
			flag: flag or config-flags/density
			if tail? parts: next parts [return flag]
		]
		if get-touch-screen parts/1 config [
			flag: flag or config-flags/touchscreen
			if tail? parts: next parts [return flag]
		]
		if get-keys-hidden parts/1 config [
			flag: flag or config-flags/keyboard-hidden
			if tail? parts: next parts [return flag]
		]
		if get-keyboard parts/1 config [
			flag: flag or config-flags/keyboard
			if tail? parts: next parts [return flag]
		]
		if get-nav-hidden parts/1 config [
			flag: flag or config-flags/keyboard-hidden
			if tail? parts: next parts [return flag]
		]
		if get-navigation parts/1 config [
			flag: flag or config-flags/navigation
			if tail? parts: next parts [return flag]
		]
		if get-screen-size parts/1 config [
			flag: flag or config-flags/screen-size
			if tail? parts: next parts [return flag]
		]
		if get-version parts/1 config [
			flag: flag or config-flags/version
			if tail? parts: next parts [return flag]
		]
		print ["AAPT: Ignore some configs" parts]
		flag
	]

	fix-up-version: func [config [object!] flag [integer!] /local min-sdk][
		min-sdk: 0
		case [
			any [
				config/smallest-width-dp <> 0
				config/screen-width-dp <> 0
				config/screen-height-dp <> 0
			][
				min-sdk: sdk/honeycomb_mr2
			]
			config/ui-mode <> 0 [min-sdk: sdk/froyo]
			any [
				config/screen-layout <> 0
				config/density <> 0
			][
				min-sdk: sdk/donut
			]
		]
		if min-sdk > config/sdk-version [
			config/sdk-version: min-sdk
			flag: flag or config-flags/version
		]
		flag
	]

	make-config-map: func [
		res-dir [file!] all-res [block!]
		/local config config-flag config-map config-part
	][
		config: make-struct res-table-config none
		config-flag: 0
		either config-part: find/tail to-string res-dir #"-" [
			remove back tail config-part
			config-flag: parse-config config-part config
			config-flag: fix-up-version config config-flag
		][
			config-part: 'default
		]

		config-map: all-res/3
		unless find config-map config-part [
			config: form-struct config
			repend config-map [config-part reduce [config-flag config]]
		]
		config-part
	]

	collect-string: func [body [block!] all-res [block!]][
		either 1 < length? body [
			insert/only all-res/2 body
			negate length? all-res/2
		][
			either #"@" = first body/1 [body/1][
				add-to-string-pool all-res/1 normalize-string body/1
			]
		]
	]

	collect-resource: func [
		node [block!] config [string! word!] all-res [block!]
		/local
			tag attr body name value res-info type-info key values
			type-strings key-strings value-strings type res info
	][
		tag: type: node/1
		attr: node/2
		body: either string? node/3 [node/3][clean-block node/3]

		if tag = "item" [
			if tag: select attr "type" [type: tag]
		]

		value-strings: all-res/1
		type-strings: all-res/4/2
		key-strings: all-res/4/3
		res-info: all-res/4/4

		if type = "integer-array" [type: "array"]
		if type = "string-array" [
			type: "array"
			foreach info body [
				poke info 3 reduce [collect-string info/3 all-res]
			]
		]
		unless find type-strings type [append type-strings type]
		name: attempt [select attr "name"]
		value: switch/default type [
			"drawable"
			"layout"
			"anim"
			"animator"
			"interpolator"
			"transition"
			"xml"
			"raw"
			"menu"
			"mipmap"
			"color"
			"bool"
			"integer"
			"fraction"
			"dimen" [
				either file? body/1 [
					add-to-string-pool value-strings to-string body/1
				][body/1]
			]
			"id"
			"attr"
			"array"
			"style"
			"plurals"
			"string-array"
			"integer-array" [
				if any [type = "id" type = "attr"][
					config: 'default
				]
				if type = "attr" [
					foreach info body [
						set [tag attrs b] info
						either any [tag = "enum" tag = "flag"][
							res: reduce ["id" attrs b]
							collect-resource res 'default all-res
						][
							print ["AAPT: Can't resolve attribute" name tag]
						]
					]
				]
				if type = "plurals" [
					foreach info body [
						poke info 3 reduce [collect-string info/3 all-res]
					]
				]
				if (length? attr) > 2 [					;-- extra attributes, e.g "parent"
					config: join attr config
				]
				body
			]
			"string" [collect-string body all-res]
		][
			print ["AAPT: not support resource type" type] none
		]

		if all [name value] [
			unless type-info: select res-info type [
				type-info: make block! 256
				append/only type-info make block! 128
				repend res-info [type type-info]
			]

			add-to-string-pool type-info/1 name
			either key: find key-strings name [
				values: select type-info (index? key) - 1
				unless values [
					values: make block! 4
					repend type-info [(index? key) - 1 values]
				]
			][
				values: make block! 4
				repend type-info [length? key-strings values]
				append key-strings name
			]
			repend values [value config]
		]
		name
	]

	collect-value-resources: func [
		res-dir [file!] config [string! word!] all-res [block!]
		/local files xml
	][
		files: read res-dir
		foreach file files [
			xml: parse-xml read join res-dir file
			xml: xml/3/1
			either "resources" = xml/1 [
				foreach node xml/3 [
					if block? node [
						collect-resource node config all-res
					]
				]
			][
				print ["AAPT: not a resource" xml/1]
			]
		]
		all-res
	]

	collect-file-resources: func [
		res-dir [file!] config [string! word!] all-res [block!]
		/local files dir res type name idx file-path
	][
		dir: second split-path res-dir
		type: first parse to-string dir "-"
		if #"/" = last type [type: copy/part type back tail type]
		files: read res-dir
		foreach file files [
			either idx: find/last file #"." [
				name: to-string copy/part file idx
			][
				name: to-string file
			]
			file-path: join %res/ [dir file]
			res: compose/deep [
				(type)
				["name" (name)]
				[(file-path)]
			]
			collect-resource res config all-res
		]
		all-res
	]

	compile-type-spec: func [
		type-id [integer!] type-spec [block!]
		/local spec buf
	][
		spec:             make-struct res-table-type-spec none
		spec/type:        to-integer table-type/type-spec
		spec/header-size: length? form-struct spec
		spec/size:        spec/header-size + (4 * length? type-spec)
		spec/id:          type-id
		spec/entry-count: length? type-spec

		buf: form-struct spec
		foreach flag type-spec [
			append buf to-bin32 flag
		]
		buf
	]

	compile-type-info: func [
		type-id [integer!] type-info [block!] config-map [block!]
		/local res buf offsets info-chunk config-chunk
	][
		info-chunk: make binary! 512
		foreach [config info] type-info [
			res:               make-struct res-table-type none
			res/type:          to-integer table-type/type-info
			res/id:            type-id
			res/entry-count:   length? info
			config-chunk:      second select config-map config
			res/entries-start: res/header-size + (4 * res/entry-count)
			offsets:           make binary! 64
			buf:               make binary! 256
			foreach chunk info [
				either chunk [
					append offsets to-bin32 length? buf
					append buf chunk
				][
					append offsets to-bin32 -1
				]
			]
			res/size: res/entries-start + length? buf
			repend info-chunk [form-struct res config-chunk offsets buf]
		]
		info-chunk
	]

	parse-flags: func [flags [string!] flags-map [block!] /local parts flag][
		flag: 0
		parts: parse flags "|"
		foreach part parts [
			flag: flag or select flags-map part
		]
		flag
	]

	compile-attribute: func [
		key [string!] value [block!] attr [block!] all-res [block!]
		/local
			format attr-map name-id k v res-map-blk special
			values-blk info res
	][
		res-map-blk: make block! 4
		values-blk: make block! 4
		attr-map: last all-res
		if attr [
			format: select attr "format"
			if special: select attr "min" [
				res: parse-value special "integer" all-res/1 all-res
				append res-map-blk join to-bin32 attribute-flags/min form-struct res
			]
			if special: select attr "max" [
				res: parse-value special "integer" all-res/1 all-res
				append res-map-blk join to-bin32 attribute-flags/max form-struct res
			]
			if special: select attr "localization" [
				res: make-struct res-value none
				res/data: parse-flags special L10N-flags
				append res-map-blk join to-bin32 attribute-flags/L10N form-struct res
			]
		]

		foreach info value [
			set [tag attrs body] info
			unless format [format: tag]
			k: select attrs "name"
			v: select attrs "value"
			repend values-blk [k v]
			name-id: get-res-id "id" k all-res
			res: parse-value v "integer" all-res/1 all-res
			append res-map-blk join to-bin32 name-id form-struct res
		]

		unless format [format: "any"]
		repend attr-map [key reduce [format values-blk]]
		name-id: attribute-flags/type
		res: make-struct res-value none
		res/data: parse-flags format attribute-type
		insert res-map-blk join to-bin32 name-id form-struct res
		res-map-blk
	]

	compile-entry-value: func [
		type	[string!]
		key		[string!]
		value	[string! block! integer!]
		attr	[none! block!]
		all-res	[block!]
		/local
			res parent res-map-entry res-map-blk parent-id info k name-id nb
	][
		res: make-struct res-value none
		either block? value [
			res-map-entry: make-struct res-table-map-entry none
			switch type [
				"style" [
					res-map-blk: make block! 4
					if attr [
						if parent: select attr "parent" [
							parent-id: get-res-id type parent all-res
							res-map-entry/parent: parent-id
						]
						foreach info value [
							set [tag attrs body] info
							k: select attrs "name"
							name-id: to-bin32 get-res-id "attr" k all-res
							res: parse-value body/1 "integer" all-res/1 all-res
							append res-map-blk join name-id form-struct res
						]
						res-map-entry/count: length? res-map-blk
					]
				]
				"attr" [
					res-map-blk: compile-attribute key value attr all-res
					res-map-entry: make-struct res-table-map-entry none
					res-map-entry/count: length? res-map-blk
				]
				"array" [
					res-map-blk: make block! 4
					if attr [
						nb: 0
						foreach info value [
							name-id: to-bin32 33554432 or nb
							res: parse-value info/3/1 "any" all-res/1 all-res
							append res-map-blk join name-id form-struct res
							nb: nb + 1
						]
						res-map-entry/count: length? res-map-blk
					]
				]
				"plurals" [
					res-map-blk: make block! 4
					if attr [
						foreach info value [
							set [tag attrs body] info
							k: select attrs "quantity"
							name-id:  to-bin32 select plurals-flags k
							res: parse-value body/1 "string" all-res/1 all-res
							append res-map-blk join name-id form-struct res
						]
						res-map-entry/count: length? res-map-blk
					]
				]
			]
		][
			res: parse-value value type all-res/1 all-res
		]

		either res-map-entry [
			join form-struct res-map-entry res-map-blk
		][
			form-struct res
		]
	]

	compile-res-info: func [
		all-res [block!]
		/local
			type-spec type-info info-blk cnt config-flag spec k type-id
			info-chunk res-info entry-chunk flag attrs key-strings
	][
		;; layout of the 'res-info
		;; [
		;;	 type [
		;;			[key1 key2 key3 ...]
		;;			key1-idx [value1 config1 value2 config2 ...]
		;;			key2-idx [value1 config1 value2 config2 ...]
		;;			...
		;;		  ]
		;;	 ...
		;; ]
		;; for example
		;; [
		;;	"string" [
		;;		["app_name" "action_settings"]
		;;		2 [0 default 7 "zh-rCN"]
		;;		3 [2 default 5 "ja-rJP"]
		;;	]
		;;	"style"  []
		;;	"dimens" []
		;; ]
		key-strings: all-res/4/3
		res-info: all-res/4/4
		type-id: 0
		info-chunk: make binary! 2048
		foreach [type info] res-info [
			type-id: type-id + 1
			cnt: 0
			type-spec: make block! length? info/1
			type-info: make block! 4
			info: next info
			foreach [key values] info [
				config-flag: 0
				cnt: cnt + 1
				foreach [value config] values [
					if block? config [
						attrs: config
						config: last config
					]
					flag: first select all-res/3 config
					config-flag: config-flag or flag

					unless info-blk: select type-info config [
						info-blk: make block! length? first head info
						repend type-info [config info-blk]
					]

					entry: make-struct res-table-entry none
					if block? value [
						entry/flags: 1
						entry/size: 16						;@@ hard code! size of res-table-map-entry
					]
					entry/key-string-idx: key
					k: pick key-strings key + 1
					entry-chunk: compile-entry-value type k value attrs all-res
					append info-blk join form-struct entry entry-chunk
				]
				append type-spec config-flag
				foreach [config info-blk] type-info [
					insert/dup tail info-blk none cnt - length? info-blk
				]
			]
			append info-chunk compile-type-spec type-id type-spec
			append info-chunk compile-type-info type-id type-info all-res/3
		]
		info-chunk
	]

	compile-res-package: func [
		all-res [block!]
		/local
			res-package package-name type-strings key-strings
			header res-chunk
	][
		;; res-package: [package-name type-strings key-strings res-info]
		res-package: all-res/4

		package-name: utf8-to-utf16 res-package/1
		insert/dup tail package-name null 256 - length? package-name

		type-strings: compile-string-pool res-package/2
		key-strings:  compile-string-pool res-package/3
		res-chunk:    compile-res-info all-res

		header: make-struct res-table-package none
		header/id:           127									;@@ add overlay support?
		header/name:         package-name
		header/type-strings: header/header-size
		header/key-strings:  header/header-size + length? type-strings
		header/last-type:    length? res-package/2
		header/last-key:     length? res-package/3
		header/size:		 header/header-size
							+ (length? type-strings)
							+ (length? key-strings)
							+ (length? res-chunk)
		repend form-struct header [type-strings key-strings res-chunk]
	]

	compile-resources: func [
		all-res [block!]
		/local value-strings package-chunk header
	][
		insert all-res/1 all-res/2
		value-strings: compile-string-pool all-res/1
		package-chunk: compile-res-package all-res

		header: make-struct res-table-header none
		header/type:          to-integer resource-type/table
		header/header-size:   length? form-struct header
		header/package-count: 1
		header/size: header/header-size
					+ (length? value-strings)
					+ (length? package-chunk)
		repend form-struct header [value-strings package-chunk]
	]

	get-res-value: func [
		key [block!] value [string!] strings [block!] all-res [block!]
		/local res attrs info key-id v
	][
		res: make-struct res-value none
		attrs: select android-res "attr"
		either key/2 [									;-- key with a namespace
			either key/1 = "android" [
				info: select attrs key/2
				key-id: hex-to-integer info/1
				if info/3 [value: select info/3 value]
				res: parse-value value info/2 strings all-res
			][
				;TODO process other resource namespaces
			]
		][
			res/datatype: to-integer value-type/string
			res/data: (index? find strings value) - 1
		]
		reduce [key-id res]
	]

	flatten-xml-namespace: func [
		attr [block!] strings [block!] ns [block!] line [integer!]
		/local ns-blk ns-node ns-ext ns-start ns-end ns?
	][
		ns-start: make binary! 32
		ns-end: make binary! 32
		ns?: no
		foreach [key value] attr [
			if any [
				key = "xmlns"
				find key "xmlns:"
			][
				ns-blk: parse key ":"
				either value = res-tools-ns [
					repend ns [ns-blk/2 res-tools-ns]
				][
					ns?: yes
					ns-node: make-struct xmltree-node none
					ns-node/type: to-integer xml-type/start-namespace
					ns-node/line-number: line
					ns-node/size: ns-node/header-size
								+ (length? form-struct xmltree-namespace-ext)

					ns-ext: make-struct xmltree-namespace-ext none
					ns-ext/uri-idx: (index? find strings value) - 1
					either ns-blk/2 [
						ns-ext/prefix-idx: (index? find strings ns-blk/2) - 1
						repend ns [ns-blk/2 ns-ext/uri-idx]
					][
						ns-ext/prefix-idx: -1
						repend ns [value ns-ext/uri-idx]
					]

					repend ns-start [form-struct ns-node form-struct ns-ext]

					ns-node/type: to-integer xml-type/end-namespace
					repend ns-end [form-struct ns-node form-struct ns-ext]
				]
			]
		]
		if ns? [reduce [ns-start ns-end]]
	]

	flatten-xml: func [
		xml			[block!]
		line		[integer!]
		strings		[block!]
		ns			[block!]
		all-res		[block!]
		/local
			element attr-ext attr-node buf res name v
			attrs-chunk attr-buf end-ext ns-chunk
	][
		buf: make binary! 1024
		foreach [tag attr body] xml [
			;TODO handle element's namespace
			element: make-struct xmltree-node none
			element/type: to-integer xml-type/start-element
			element/line-number: line

			attr-ext: make-struct xmltree-attr-ext none
			if attr [
				ns-chunk: flatten-xml-namespace attr strings ns line
				if ns-chunk [append buf ns-chunk/1]
				attrs-chunk: make block! length? attr
				foreach [key value] attr [
					key: parse key ":"
					unless any [
						key/1 = "xmlns"
						all [key/2 res-tools-ns = select ns key/1]
					][
						attr-node: make-struct xmltree-attribute none
						either key/2 [
							attr-node/ns-idx: select ns key/1
							name: key/2
						][
							attr-node/ns-idx: -1
							name: key/1
						]
						attr-node/name-idx: (index? find strings name) - 1
						if v: find strings value [
							attr-node/raw-value-idx: (index? v) - 1
						]
						res: get-res-value key value strings all-res
						attr-node/datatype: res/2/datatype
						attr-node/data: res/2/data
						repend attrs-chunk [res/1 form-struct attr-node]
					]
				]
				sort/skip attrs-chunk 2
				forall attrs-chunk [attrs-chunk: remove attrs-chunk]
				attr-ext/attr-count: length? attrs-chunk
			]
			attr-ext/name-idx: (index? find strings tag) - 1
			attr-buf: append form-struct attr-ext attrs-chunk
			element/size: element/header-size + length? attr-buf
			repend buf [form-struct element attr-buf]

			if body [
				foreach item body [
					line: line + 1
					if block? item [
						append buf flatten-xml item line strings ns all-res
					]
				]
			]

			end-ext: make-struct xmltree-end-element-ext none
			end-ext/name-idx: attr-ext/name-idx
			element/type: to-integer xml-type/end-element
			element/size: element/header-size + length? form-struct end-ext
			repend buf [form-struct element form-struct end-ext]
			if ns-chunk [append buf ns-chunk/2]
		]
		buf
	]

	accept-string?: func [value [string!] type [string!]][
		all [
			#"@" <> first value
			#"?" <> first value
			find type "string"
			not all [find type "integer" integer? load value]
			not all [find type "float" number? load value]
			not all [find type "boolean" any [value = "true" value = "false"]]
		]
	]

	collect-xml-strings: func [
		xml [block!]
		string-id [block!]
		string-no-id [block!]
		ids [binary!]
		all-res [block!]
		/local key-blk ns name id info attrs
	][
		attrs: select android-res "attr"
		foreach [tag attr body] xml [
			append string-no-id tag
			if attr [
				foreach [key value] attr [
					key-blk: parse key ":"
					either key-blk/1 = "xmlns" [
						if key-blk/2 [append string-no-id key-blk/2]
						append string-no-id value
					][
						either 2 = length? key-blk [
							ns: key-blk/1
							name: key-blk/2
							if id: get-res-id "attr" key all-res [
								unless find string-id name [
									append string-id name
									append ids to-bin32 id
								]
							]
							info: select attrs name
							if accept-string? value info/2 [
								append string-no-id value
							]
						][
							repend string-no-id [key value]
						]
					]
				]
			]
			if body [
				foreach item body [
					if block? item [
						collect-xml-strings item string-id string-no-id ids all-res
					]
				]
			]
		]
	]

	compile-xml-file: func [
		file [file!] all-res [block!]
		/utf-16
		/local
			xml string-id string-no-id all-strings ns header
			xml-bin strings-chunk ids ids-header
	][
		ns: make block! 16
		string-id: make block! 32
		string-no-id: make block! 16
		ids: make binary! 128

		xml: parse-xml read file

		collect-xml-strings xml/3/1 string-id string-no-id ids all-res

		ids-header: make-struct chunk-header none
		ids-header/type: to-integer xml-type/resource-map
		ids-header/size: ids-header/header-size + length? ids
		ids: append form-struct ids-header ids

		all-strings: append string-id unique string-no-id
		strings-chunk: either utf-16 [
			compile-string-pool/utf-16 all-strings
		][
			compile-string-pool all-strings
		]

		xml-bin: flatten-xml xml/3/1 1 all-strings ns all-res
		header: make-struct xmltree-header none
		header/type: to-integer resource-type/xml
		header/size: header/header-size
					+ (length? strings-chunk)
					+ (length? ids)
					+ (length? xml-bin)
		repend form-struct header [strings-chunk ids xml-bin]
	]

	zip-raw-files: func [raw-dir [file!] /local date data saved files entries][
		saved: what-dir
		files: read raw-dir
		change-dir raw-dir
		entries: make block! 32
		foreach file files [
			zip/deep/to-entry entries file
		]
		change-dir saved
		entries
	]

	package: func [
		manifest [file!] res-dir [file!] raw-dir [file!] output [file!]
		/local
			dirs zip-entries all-res xml-bin res-bin
			package-name config files
	][
		package-name: get-package-name manifest
		zip-entries: make block! 32

		all-res: compose/deep [
			[]										;-- value-strings
			[]										;-- style-strings
			[]										;-- config map
			[										;-- res-package
				(package-name)
				[]									;-- type-strings
				[]									;-- key-strings
				[]									;-- res-info
			]
			[]										;-- attributes map
		]

		dirs: read res-dir
		foreach dir dirs [							;-- collecting resources info
			config: make-config-map dir all-res
			either find dir "values" [
				collect-value-resources join res-dir dir config all-res
			][
				collect-file-resources join res-dir dir config all-res
			]
		]

		foreach dir dirs [							;-- compiling xml resources
			unless find dir "values" [
				files: read join res-dir dir
				foreach file files [
					xml-bin: either %.xml = suffix? file [
						compile-xml-file join res-dir [dir file] all-res
					][
						read/binary join res-dir [dir file]
					]
					append/only zip-entries zip-entry join %res/ [dir file] now xml-bin
				]
			]
		]

		xml-bin: compile-xml-file/utf-16 manifest all-res
		append/only zip-entries zip-entry %AndroidManifest.xml now xml-bin

		res-bin: compile-resources all-res
		append/only zip-entries zip-entry/store %resources.arsc now res-bin

		append zip-entries zip-raw-files raw-dir
		package-all-entries output zip-entries
	]
]
