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
		type-code		16777216		;-- this entry holds the attribute's type code
		min				16777217		;-- this is the minimum value it can hold
		max				16777218		;-- this is the maximum value it can hold
		L10N			16777219		;-- localization of this resource is can be encouraged
		other			16777220		;-- for plural support, see android.content.res.PluralRules#attrForQuantity(int)
		zero			16777221
		one				16777222
		two				16777223
		few				16777224
		many			16777225
	]

	attribute-type: [
		any				65535			;-- no type has been defined for this attribute
		reference		1
		string			2
		integer			4
		boolean			8
		color			16
		float			32
		dimension		64
		fraction		128
		enum			65536			;-- the enumeration values are supplied as additional entries in the map
		flags			131072			;-- the flag bit values are supplied as additional entries in the map
	]

	L10N-flags: [
		required		0
		suggested		1
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

	complex-unit-flags: [
		shift			0
		mask			15
		pixel			0
		DIP				1
		SP				2
		point			3
		inche			4
		millimeter		5
		fraction		0
		fraction-parent 1
	]

	string-pool-flags: [					;-- flags of the 'string-pool-header/flags'
		sorted			1					;-- if set, the string index is sorted by the string values
		UTF-8			256					;-- string pool is encoded in UTF-8
	]

	config-flags: [
		mmc						1
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
	] [8]

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
	] none

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
		language			[short]
		country				[short]
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
	] [48]

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
	] none

	res-table-map: make-struct [
		name-idx		[integer!]
		size			[short]				;-- a res-value
		res0			[char]
		datatype		[char]
		data			[integer!]
	] [-1 8]

	pad4: func [s [string! binary!] /local rem][
		unless zero? rem: (length? s) // 4 [
			insert/dup tail s #"^@" 4 - rem
		]
		s
	]

	hex-to-integer: func [str [string!] /local int value][
		int: 0
		foreach c skip str 2 [
			value: case [
				all [c >= #"0" c <= #"9"] [c - #"0"]
				all [c >= #"a" c <= #"f"] [c - #"a" + 10]
				all [c >= #"A" c <= #"F"] [c - #"A" + 10]
			]
			int: int * 16 + value
		]
		int
	]

	utf8-to-utf16: func [str [string!] /local buf][
		;TODO add completed support for converting utf-8 to utf-16
		buf: make binary! 2 * length? str
		foreach char str [
			either char < 128 [
				append buf char
				append buf null
			][
				print ["Only support ASCII string." str]
			]
		]
		buf
	]

	clean-block: func [blk [block!] /local new][
		new: make block! length? blk
		foreach value blk [
			unless empty? trim value [
				append new value
			]
		]
		new
	]

	get-res-id: func [
		type [string!] key [string!] all-res [block!]
		/local
			parts info local-info types id
	][
		info: select android-res type
		local-info: select all-res/3/4 type
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
			local-info: select all-res/3/4 type
			types: all-res/3/2
			type-id: index? find types type
			key-id: (index? find local-info/1 key) - 1
			id: key-id
					or (shift/left type-id 16)
					or (shift/left 127 24)
		]
		id
	]

	string-to-value: func [
		str				[string!]
		attr-type		[string!]
		value-strings	[block!]
		local-res		[block!]
		/local value v
	][
		value: make-struct res-value none
		case [
			integer? v: attempt [load str] [
				value/datatype: to-integer value-type/int-dec
				value/data: v
			]
			any [
				attr-type = "string"
				all [find attr-type "string" #"@" <> first str]
			][
				value/datatype: to-integer value-type/string
				value/data: (index? find value-strings str) - 1
			]
			attr-type = "boolean" [
				value/datatype: to-integer value-type/int-bool
				value/data: either str = "true" [-1][0]
			]
			attr-type = "dimen" [
				value/datatype: to-integer value-type/dimension
				value/data: 16
			]
			#"@" = first str [
				value/datatype: to-integer value-type/reference
				value/data: get-res-id "attr" next str local-res
			]
		]
		value
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

	compile-string-pool: func [
		strings [block!]
		/utf-16
		/local header offsets buf
	][
		;TODO handle styled strings
		;TODO handle string length > 32767
		offsets: make binary! 32
		buf: make binary! 512
		foreach str strings [
			append offsets to-bin32 length? buf
			append buf to-bin16 length? str
			if utf-16 [str: utf8-to-utf16 str]
			append buf to-binary str
			append buf either utf-16 [#{0000}][#{00}]	;-- null char
		]
		buf: pad4 buf

		header:               make-struct string-pool-header none
		header/type:          to-integer resource-type/string-pool
		header/header-size:   length? form-struct header
		header/string-count:  length? strings
		header/style-count:   0
		header/strings-start: header/header-size + (4 * length? strings)
		header/styles-start:  0
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
			print ["Not a manifest file:" manifest]
			halt
		]
		name
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

		unless value: select name part [
			if parse part [s: some digit e: "dpi"] [
				value: to-integer copy/part s e
			]
		]
		config/density: value
	]

	get-orientation: func [part [string!] config [object!] /local name value][
		name: [
			"any" 		0
			"port"		1
			"land"		2
			"square"	3
		]

		value: select name part
		config/orientation: value
	]

	ge-smallest-width-dp:  func [part [string!] config [object!] /local value][
		if parse part ["sw" s: some digit e: "dp"] [
			value: to-integer copy/part s e
		]
		config/smallest-width-dp: value
	]

	parse-config: func [
		config-str [any-string!] config [object!]
		/local parts flag
	][
		flag: 0
		parts: parse config-str "-"

		if ge-smallest-width-dp parts/1 config [
			flag: flag or config-flags/smallest-screen-width
			if tail? parts: next parts [return flag]
		]

		if get-orientation parts/1 config [
			flag: flag or config-flags/orientation
			if tail? parts: next parts [return flag]
		]

		if get-density parts/1 config [
			flag: flag or config-flags/density
			if tail? parts: next parts [return flag]
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
		][
			config-part: 'default
		]

		config-map: all-res/2
		unless find config-map config-part [
			config: form-struct config
			repend config-map [config-part reduce [config-flag config]]
		]
		config-part
	]

	collect-resource: func [
		node [block!] config [string! word!] all-res [block!]
		/local
			tag attr body name value res-info type-info key values
			type-strings key-strings value-strings
	][
		tag: node/1
		attr: node/2
		body: clean-block node/3

		value-strings: all-res/1
		type-strings: all-res/3/2
		key-strings: all-res/3/3
		res-info: all-res/3/4

		unless find type-strings tag [append type-strings tag]
		name: attempt [select attr "name"]
		switch tag [
			"attr"  []
			"style" [
				value: body
				if (length? attr) > 2 [					;-- extra attributes, e.g "parent"
					config: join attr config
				]
			]
			"drawable"
			"string" [
				value: add-to-string-pool value-strings body/1
			]
			"string-array"		[]
			"dimen" [
				value: body/1
			]
			"color"				[]
			"bool"				[]
			"fraction"			[]
			"plurals"			[]
			"array"				[]
			"integer"			[]
			"integer-array"		[]
			"declare-styleable" []
			"public"			[]
			"public-padding"	[]
			"add-resource"		[]
		]

		if name [
			unless type-info: select res-info tag [
				type-info: make block! 256
				append/only type-info make block! 128
				repend res-info [tag type-info]
			]

			add-to-string-pool type-info/1 name
			either key: find key-strings name [
				values: select type-info (index? key) - 1
			][
				values: make block! 4
				repend type-info [length? key-strings values]
				append key-strings name
			]
			repend values [value config]
		]
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
				print ["Warning: not a resource." xml/1]
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
		files: read res-dir
		foreach file files [
			either idx: find/last file #"." [
				name: to-string copy/part file idx
			][
				name: to-string file
			]
			file-path: to-string join %res/ [dir file]
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

	compile-entry-value: func [
		type [string!]
		value [string! block! integer!]
		attr [none! block!]
		all-res [block!]
		/local
			res info parent res-map-entry res-map-blk parent-id
	][
		res-map-blk: make block! 4
		res: make-struct res-value none
		info: switch type [
			"string"
			"drawable" [
				res/datatype: to-integer value-type/string
				res/data: value
			]
			"style" [
				res-map-entry: make-struct res-table-map-entry none
				if attr [
					if parent: select attr "parent" [
						parent-id: get-res-id type parent all-res
						res-map-entry/parent: parent-id
						res-map-entry/count: 0
					]
				]
			]
			"dimen" [
				res/datatype: to-integer value-type/dimension
				res/data: 16									;@@ fake data
			]
			default [print ["Unknown resource type:" type]]
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
			type-spec type-info info-blk cnt config-flag spec
			info-chunk res-info entry-chunk flag attrs
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
		res-info: all-res/3/4
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
					flag: first select all-res/2 config
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
					entry-chunk: compile-entry-value type value attrs all-res
					append info-blk join form-struct entry entry-chunk
				]
				append type-spec config-flag
				foreach [config info-blk] type-info [
					insert/dup tail info-blk none cnt - length? info-blk
				]
			]
			append info-chunk compile-type-spec type-id type-spec
			append info-chunk compile-type-info type-id type-info all-res/2
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
		res-package: all-res/3

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
		key [block!] value [string!] strings [block!] local-res [block!]
		/local res attrs info key-id
	][
		res: make-struct res-value none
		attrs: select android-res "attr"
		either key/2 [									;-- key with a namespace
			either key/1 = "android" [
				info: select attrs key/2
				key-id: hex-to-integer info/1
				res: string-to-value value info/2 strings local-res
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
		local-res	[block!]
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
						res: get-res-value key value strings local-res
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
						append buf flatten-xml item line strings ns local-res
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

	collect-strings: func [
		xml [block!] string-id [block!] string-no-id [block!] ids [binary!]
		/local key-blk ns name attrs info
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
							if ns = "android" [
								either info: select attrs name [
									if all [
										#"@" <> first value
										not find info/2 "integer"		;@@
										find info/2 "string"
									][
										append string-no-id value
									]
									unless find string-id name [
										append string-id name
										append ids to-bin32 hex-to-integer info/1
									]
								][
									print ["Can't find attribute:" name]
								]
							]
						][
							;TODO find key in local-res
							repend string-no-id [key value]
						]
					]
				]
			]
			if body [
				foreach item body [
					if block? item [
						collect-strings item string-id string-no-id ids
					]
				]
			]
		]
	]

	compile-xml-file: func [
		file [file!] local-res [block!]
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

		collect-strings xml/3/1 string-id string-no-id ids

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

		xml-bin: flatten-xml xml/3/1 1 all-strings ns local-res
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
			[]										;-- config map
			[										;-- res-package
				(package-name)
				[]									;-- type-strings
				[]									;-- key-strings
				[]									;-- res-info
			]
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
