Red[
	Title:   "XML codec"
	Author:  "Boleslav Březovský"
	File:    %XML.red
	Rights:  "Copyright (C) 2022 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Links: [
		xml-specs: https://www.w3.org/TR/2006/REC-xml11-20060816
	]
]

; -- main context ----------------------------------------------------------

xml: context [

; -- settings

	meta?: false			; export metada also
	red-keys?: true			; convert keys to Red values
	text-sigil: 'text!		; text sigil for the COMPACT format
	trace?: false
	format: 'triples
	formats: [triples compact key-val]

; -- support functions

	strip: func [
		"Remove first and last character"
		value [string!]
	] [
		copy/part next value -2 + length? value
	]

	meta-action: func [
		data [block!]
	] [
		to paren! compose/deep [
			if meta? [
				repend target [(data)]
			]
			value?: false
		]
	]

	load-key: none

	value: att-name: att-value: att-length: att-ns: char-data:
	verinfo: encinfo: namespace: nl?:
		none
	cont-val: ""
	value?: false
	attributes: none

	target: []
	target-stack: []

	decode: func [
		"Convert XML data to Red format"
		data [string! file! url!] "XML to convert"
		/as
			fmt [word!] "Select output format [triples compact key-val]"
		/meta "Preserve meta data"
		/strict "Require XML prolog"
		; debugging
		/trace "Use `parse-trace` instead of `parse`"
	] [
		fmt: any [fmt format]
			unless find formats fmt [
				do make error! "Unkown format"
			]
		init-decoder fmt
		unless string? data [data: read data]
		meta?: meta
		document: either strict [strict-document] [loose-document]
		clear target
		clear target-stack
		clear attributes

		value: att-name: att-value:
		verinfo: encinfo:
			none

		either trace [
			parse-trace data document
		] [
			parse data document
		]
		target
	]

	set 'load-xml :decode

	sq: #"'"
	dq: #"^""
	caret: #"^^"
	lower-letter: charset [#"a" - #"z"]
	upper-letter: charset [#"A" - #"Z"]
	digit: charset [#"0" - #"9"]
	letter: union lower-letter upper-letter
	alphanum: union letter digit

	; -- Document
	document: none
	strict-document: [
		prolog
		element
	]
	loose-document: [
		opt prolog
		element
	]

	; -- Character Range
	Char: {[#x1-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]}
	RestrictedChar: {[#x1-#x8] | [#xB-#xC] | [#xE-#x1F] | [#x7F-#x84] | [#x86-#x9F]}

	Char: charset [
		#"^(01)" -#"^(D7FF)" #"^(E000)" - #"^(FFFD)" #"^(10000)" - #"^(10FFFF)"
	]
	RestrictedChar: charset [
		#"^(01)" -#"^(08)" #"^(0B)" - #"^(0C)" #"^(0E)" - #"^(1F)"
		#"^(7F)" - #"^(84)" #"^(86)" - #"^(9F)"
	]

	;TODO: compatibility characters

	; -- White Space
	S: charset reduce [space tab cr lf]
	S?: [opt S]
	S*: [any S]
	S+: [some S]

	; -- Names and Tokens
	NameStartChar:
	name-start-char: charset [
		":_" #"a" - #"z" #"A" - #"Z" #"0" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" 
		#"^(F8)" - #"^(02FF)" #"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)"
		#"^(200C)" - #"^(200D)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)"
		#"^(3001)" - #"^(D7FF)" #"^(F900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
		#"^(010000)" - #"^(0EFFFF)"
	]
	NameChar:
	name-char: union name-start-char charset [
		"-." #"0" - #"9" #"^(B7)" #"^(0300)" - #"^(036F)" #"^(203F)" - #"^(2040)"
	]
	Name:
	name: [name-start-char any name-char]
	Names: [Name any [space Name]]
	Nmtoken: [some NameChar]
	Nmtokens: [Nmtoken any [space Nmtoken]]

	;-- Literals
	ent-dchars: complement charset {%&"}
	ent-schars: complement charset {%&'}
	EntityValue: [
		dq any [ent-schars | PEReference | Reference] dq
	|	sq any [ent-schars | PEReference | Reference] sq
	]
	att-dchars: complement charset {<&"}
	att-schars: complement charset {<&'}
	AttValue: [
		dq any [att-dchars | reference] dq
	|	sq any [att-schars | reference] sq
	]
	SystemLiteral: [
		dq any [#"^^" | dq] dq
	|	sq any [#"^^" | sq] sq
	]
	SystemLiteral: [
		dq thru dq
	|	sq thru sq
	]
	PubidLiteral: [
		dq any PubidChar dq
	|	sq any [not sq PubidChar] sq
	]
	PubidChar: charset reduce [
		space cr lf #"a" '- #"z" #"A" '- #"Z" {-'()+,./:=?;!*#@$_%}
	]

	; -- Character Data
	cd-chars: charset "^^<&"
	cd-chars: complement charset "<&"
;	CharData: [not ["]]>" any cd-chars] any not cd-chars]
	CharData: [
		copy char-data any [
			not #"<" [
				["&amp;" | "&gt;" | "&lt;"] ; TODO: &apos; &quot
				; what about other escapes?
			|	not "&" skip
			]
		]
	]

	; -- Comment
	Comment: [
		"<!--"
		copy value some [
			[not #"-" Char] 
		|	[#"-" not #"-" Char]
		]
		"-->"
		store-comment
	]

	; -- Processing Instructions
	PI: [
		"<?"
		PITarget
		opt [
			S+ not [any Char "?>" any Char] any Char
		]
		"?>"
	]
	PI: [
		"<?" copy att-name PITarget S+ copy value to "?>"
		2 skip
		store-pi
	]
	PITarget-chars: charset "xXmMlL"
	PITarget: [not [some PITarget-chars S+] Name]

	; -- CDATA Sections
	CDSect: [
		CDStart
		copy value CData
		CDend
		store-cdata
	]
	CDStart: "<![CDATA["
	CData: [any [not "]]>" Char]]
	CDend: "]]>"

	; -- Prolog
	prolog: [
		XMLDecl
		opt [doctypedecl any Misc]
		any Misc
	]
	XMLDecl: [
		{<?xml} VersionInfo opt EncodingDecl opt SDDecl S* {?>}
		store-xml-decl
	]
	VersionInfo: [
		S+ "version" Eq [sq VersionNum sq | dq VersionNum dq]
	]
	Eq: [S* #"=" S*]
	VersionNum: [copy verinfo ["1.0" | "1.1"]]
	Misc: [Comment | PI | S+]

	; -- Document Type Definition
	doctypedecl: [
		S+
		"<!DOCTYPE" S+ Name
		opt [S+ ExternalID]
		S*
		opt [#"[" intSubset #"]" S*]
		#">"
	]
	DeclSep: [PEReference | S+]
	intSubset: [any [markupdecl | DeclSep]]
	markupdecl: [
		elementdecl | AttlistDecl | EntityDecl | NotationDecl | PI | Comment
	]

	; -- External Subset
	extSubset: [opt TextDecl extSubsetDecl]
	extSubsetDecl: [any [markupdecl | conditionalSect | DeclSep]]

	; -- Standalone Document Declaration
	SDDecl: [
		some space
		"standalone"
		Eq
		[sq ["yes" | "no"] sq | dq ["yes" | "no"] dq]
	]

	; -- Elements
	_element: [ ; NOTE: use this for testing
		mark:
		(print ["***^/" mold mark "^/***^/"])
		element
	]
	element: [
		EmptyElemTag
	|	S* STag S* content S* ETag pop-stack S*
	]
	STag: [
		#"<"
		copy value Name
		any [
			S+
			Attribute
			store-attributes
		]
		S*
		#">"
		push-stack
	]
	Attribute: [
		copy att-name Name
		Eq
		copy att-value AttValue
	]
	ETag: ["</" Name S* #">"]
	content: [
		(value?: true)
		copy value [
			opt CharData
			any [[element | Reference | CDSect | PI | Comment] opt CharData]
		]
		(cont-val: value)
	]
	EmptyElemTag: [
		#"<" copy value Name any [S+ Attribute] S* "/>"
		(value?: cont-val: copy "")
		store-attributes
		push-stack pop-stack
    ]
	elementdecl: ["<!ELEMENT" S+ Name S+ contentspec S* #">"]
	contentspec: ["EMPTY" | "ANY" | Mixed | children]
	child-chars: charset "?*+"
	children: [[choice | seq] opt child-chars]
	cp: [[Name | choice | seq] opt child-chars]
	choice: [#"(" S* cp some [S* #"|" S* cp] S* #")"]
	seq: [#"(" S* cp some [S* #"," S* cp] S* #")"]
	Mixed: [
		#"(" S* "#PCDATA" any [S* #"|" S* Name] opt space ")*"
	|	#"(" S* "#PCDATA" S* #")"
	]

	; -- Attributes
	AttlistDecl: ["<!ATTLIST" S+ Name any AttDef S* #">"]
	AttDef: [S+ Name S+ AttType S+ DefaultDecl]
	AttType: [StringType | TokenizedType | EnumeratedType]
	StringType: "CDATA"
	TokenizedType: [
		"IDREF" | "ID" | "IDREFS" | "ENTITY" | "ENTITIES" | "NMTOKENS"
		| "NMTOKEN"
	] ; NOTE: sorted differently than in spec to actually work

	EnumeratedType: [NotationType | Enumeration]
	NotationType: ["NOTATION" S+ #"(" S* Name any [S* #"|" S*] S* #")"]
	Enumeration: [#"(" S* Nmtoken any [S* #"|" S* Nmtoken] S* #")"]
	DefaultDecl: ["#REQUIRED" | "#IMPLIED" | opt ["#FIXED" S+] AttValue]

	; -- Conditional Sections
	conditionalSect: [includeSect | ignoreSect]
	includeSect: ["<![" S* "INCLUDE" S* #"[" extSubsetDecl "]]>"]
	ignoreSect: ["<![" S* "IGNOREE" S* #"[" any ignoreSectContents "]]>"]
	ignoreSectContents: [Ignore any ["<![" ignoreSectContents "]]>" Ignore]]
	Ignore: [any [not ["<![" | "]]>"] Char]]

	; -- Physical Structures

	number: charset "0123456789"
	hexnum: union number charset "abcdefABCDEF"
	CharRef: [ "&#" some number #";" | "&#x" some hexnum #";"]
	Reference: [EntityRef | CharRef]
	EntityRef: [#"&" Name #";"]
	PERreference: [#"%" Name #";"]

	; -- Entity Declaration

	EntityDecl: [GEDecl | PEDecl]
	GEDecl: ["<!ENTITY" S+ Name S+ EntityDef S* #">"]
	PEDecl: ["<!ENTITY" S+ #"%" S+ Name S+ PEDef S* #">"]
	EntityDef: [EntityValue | ExternalID opt NDataDecl]
	PEDef: [EntityValue | ExternalID]
	ExternalID: [
		"SYSTEM" S+ SystemLiteral
	|	"PUBLIC" S+ PubidLiteral S+ SystemLiteral
	]
	NDataDecl: [S+ "NDATA" S+ Name]
	TextDecl: ["<?xml" opt VersionInfo EncodingDecl S* "?>"]
	extParsedEnt: [opt TextDecl not any Char content RestrictedChar any Char]
	EncodingDecl: [S+ "encoding" Eq [dq EncName dq | sq EncName sq]]
	enc-chars: union alphanum charset "._"
	EncName: [copy encinfo [letter any [enc-chars | #"-"]]]
	
	; -- Notation Declarations
	NotationDecl: ["<!NOTATION" S+ Name S+ [ExternalID | PublicID] S* #">"]
	PublicID: ["PUBLIC" S+ PubidLiteral]

	; -- Actions
	push-stack:
	pop-stack:
	store-attributes:
	store-xml-decl:
	store-pi:
	store-comment:
	store-cdata:
	store-char-data:
		none

	init-decoder: func [decoder /local name value] [
		decoder: select decoders decoder
		foreach [name value] decoder [
			set name :value
		]
	]

	decoders: context [
		triples: reduce [
			'attributes []
			'load-key func [value] [
				unless red-keys? [return value]
				either find value #":" [
					to path! replace/all value #":" #"/"
				] [to word! value]
			]
			'store-char-data func [] [
				if all [
					string? char-data
					not empty? trim char-data
				] [
					repend target [
						none
						copy char-data
						none
					]
				]
			]
			'push-stack quote (
				; store non-eclosed text if exists
				store-char-data
				; store latest tag
				append target load-key value
				append/only target-stack target
				new-line back tail target true
				append/only target copy []
				append/only target either empty? attributes [
					none
				] [
					copy attributes
				]
				; do cleanup
				clear attributes
				target: first skip tail target -2
			)
			'pop-stack quote (
				store-char-data
				target: take/last target-stack
				if value? [
					change skip tail target -2 either empty? cont-val [
						none
					] [
						cont-val
					]
				]
				value?: false
				clear char-data
			)
			'store-attributes quote (
				if att-name [
					repend attributes [load-key att-name strip att-value]
					att-name: att-value: none
				]
			)
			'store-xml-decl meta-action [
				#xml
				none
				compose [
					version: (verinfo)
					encoding: (encinfo)
				]
			]
			'store-pi meta-action [#PI att-name value]
			'store-comment meta-action [#comment trim value none]
			'store-cdata meta-action [#cdata value none]
		]
		compact: reduce [
			'attributes []
			'load-key func [value /att] [
				if find value #":" [
					value: split value #":"
					either att [
						att-ns: value/1
					] [
						namespace: value/1
					]
					value: value/2
				]
				to either att [issue!] [word!] value
			]
			'store-attributes quote (
				if att-name [
					att-name: load-key/att form att-name
					if att-ns [
						append attributes to refinement! att-ns
						att-ns: none
					]
					repend attributes [
						att-name
						strip att-value
					]
					att-name: att-value: none
				]
			)
			'store-char-data func [] [
				if all [
					string? char-data
					not empty? trim char-data
				] [
					append target reduce [to word! text-sigil copy char-data]
					clear char-data
					clear cont-val
				]
			]
			'push-stack quote (
				; store non-eclosed text if exists
				store-char-data
				; store latest tag
				nl?: false
				value: load-key value
				if namespace [
					append target to refinement! namespace
					namespace: none
					new-line back tail target true
					nl?: true
				]
				append target value
				unless nl? [
					new-line back tail target true
				]
				append target reduce [copy attributes]
				append/only target-stack target
				; do cleanup
				clear attributes
				target: last target
			)
			'pop-stack quote (
				store-char-data
				target: take/last target-stack
				if all [
					value?
					not empty? cont-val
				] [
					append last target reduce ['! cont-val]
				]
				value?: false
				clear char-data
			)
			; TODO: Do not emit empty attributes here
			'store-xml-decl quote (
				if meta? [
					append target @xml
					if verinfo [repend target [#version  verinfo]]
					if encinfo [repend target [#encoding encinfo]]
				]
			)
			'store-pi meta-action [@PI att-name trim value]
			'store-comment meta-action [@comment trim value]
			'store-cdata meta-action [@cdata value]
		]
		key-val: reduce [
			'attributes []
			'load-key func [value] [
				unless red-keys? [return value]
				either find value #":" [
					to path! replace/all value #":" #"/"
				] [to word! value]
			]
			'store-char-data func [] [
				if all [
					string? char-data
					not empty? trim char-data
				] [
					repend target [
						#text
						copy char-data
					]
					new-line skip tail target -2 true
				]
			]
			'push-stack quote (
				; store non-eclosed text if exists
				store-char-data
				; store latest tag
				append target load-key value
				append/only target-stack target
				new-line back tail target true
				repend target [
					copy []
					#attr either empty? attributes [
						none
					] [
						copy attributes
					]
				]

				; do cleanup
				clear attributes
				target: first skip tail target -3
			)
			'pop-stack quote (
				store-char-data
				target: take/last target-stack
				if value? [
					change skip tail target -3 either empty? cont-val [
						none
					] [
						cont-val
					]
					insert skip tail target -3 #text
				]
				value?: false
				clear char-data
			)
			'store-attributes quote (
				if att-name [
					repend attributes [load-key att-name strip att-value]
					att-name: att-value: none
				]
			)
			'store-xml-decl meta-action [
				'.xml
				compose [
					version: (verinfo)
					encoding: (encinfo)
				]
			]
			'store-pi meta-action [#PI att-name value]
			'store-comment meta-action [#comment trim value]
			'store-cdata meta-action [#cdata value]
		]
	]

; === encoder part ===========================================================

	output: make string! 10000

	pretty?: false
	default-indentation: "    "
	indentation: "    "
	current-indentation: ""

	indent: func [] [
		either pretty? [
			append copy "^/" skip current-indentation length? indentation
		] [
			""
		]
	]

	i+: func [] [append current-indentation indentation]
	i-: func [] [remove/part current-indentation length? indentation]

	enquote: function [value] [rejoin [dq value dq]]

	make-atts: function [
		data
	] [
		data: either none? data [""] [
			collect/into [
				foreach [key value] data [
					keep rejoin [key #"=" enquote value space]
				]
			] clear ""
		]
		unless empty? data [insert data space]
		trim data
	]

	make-tag: function [
		name
		/with
			atts
		/close
		/empty
	] [
		atts: either all [
			with not empty? atts
		] [
			rejoin [space make-atts atts]
		] [""]
		rejoin trim reduce [
			#"<" if close [#"/"] form name atts if empty [" /"] #">"
		]
	]

	process-tag: function [
		data
	] [
		output: make string! 1000
		i+
		either block? data/2 [
			; tag
			either empty? data/2 [
				; empty tag
				repend output [indent #"<" form data/1 make-atts data/3 "/>"]
			] [
				; tag pair
				repend output [indent #"<" form data/1 make-atts data/3 #">"]
				until [
					repend output process-tag take/part data/2 3
					empty? data/2
				]
				repend output [indent "</" form data/1 #">"]
			]
		] [
			; content
			repend output either data/1 [[
				indent
				#"<" form data/1 make-atts data/3 #">"
				either data/2 [data/2] [""]
				"</" form data/1 #">"
			]] [
				[data/2]
			]
		]
		i-
		output
	]


	ns-name: tag-name: ns-att-name:
		none
	tag-stack: []

	encoders: context [
		triples: context [
			encode: func [
				data
			] [
				data: copy/deep data
				clear output
				; TODO add proper header: xml/doctype
				until [
					repend output process-tag take/part data 3
					empty? data
				]
				output
			]
		]

		compact: context [
			ns-rule: [
				(ns-name: none)
				opt [set ns-name refinement!]
			]
			tag-rule: [
				ns-rule
				set tag-name word!
				(if ns-name [tag-name: rejoin [ns-name #":" tag-name]])
				(attributes: clear #())
				into [
					any att-rule
					(
						append output make-tag/with tag-name attributes
						insert tag-stack tag-name
					)
					any content-rule
				]
				(
					tag-name: take tag-stack
					append output make-tag/close tag-name
				)
			]
			att-rule: [
				(ns-att-name: none)
				opt [set ns-att-name refinement!]
				set att-name issue!
				set att-value string!
				(
					if ns-att-name [att-name: rejoin [ns-att-name #":" att-name]]
					put attributes att-name att-value
				)
			]
			text-rule: [
				text-sigil copy value string!
				(append output value)
			]
			pi-rule: [
				ns-rule
				set tag-name issue!
				set value string!
			]
			content-rule: [
				text-rule
			|	tag-rule
			|	pi-rule
			]
			encode: func [
				data
				/trace
				/local parse*
			] [
				clear output
				clear tag-stack
				text-sigil: to lit-word! text-sigil
				parse*: either trace [:parse-trace] [:parse]
				parse* data [some content-rule]
				output
			]
		]

		key-val: context [
			tag-pos: none
			init-tag: quote (
				if ns-name [tag-name: rejoin [ns-name #":" tag-name]]
				attributes: clear #()
				append output make-tag tag-name
				insert tag-stack reduce [tag-name back tail output]
			)
			store-tag: quote (
				tag-name: take tag-stack
				tag-pos: take tag-stack
				append output make-tag/close tag-name
				unless empty? attributes [
					insert tag-pos collect [
						foreach [key value] attributes [
							keep rejoin [
								space key {="} value #"^""
							]
						]
					]
				]
			)
			ns-rule: [
				(ns-name: none)
				opt [set ns-name refinement!]
			]
			tag-rule: [
				ns-rule
				set tag-name word! (tag-name)
				init-tag
				[
					ahead block! into [any content-rule]
				|	text-rule
				]
				#attr [none! | into [any attr-rule]]
				store-tag
			]
			attr-rule: [
				(ns-att-name: none)
				opt [set ns-att-name refinement!]
				set att-name word!
				set att-value string!
				(
					if ns-att-name [att-name: rejoin [ns-att-name #":" att-name]]
					put attributes att-name att-value
				)
			]
			text-rule: [
				#text [
					set value string! (append output value)
				|	none!
				]
			]
			content-rule: [text-rule | tag-rule]
			encode: func [
				data
				/local parse*
			] [
				clear output
				clear tag-stack
				parse*: either trace? [:parse-trace] [:parse]
				parse* data [some content-rule]
				output
			]
		]
	]

	set 'to-xml func [
		data [block!]	"Red data for conversion"
		/as
			fmt [word!]	"Format of the source data [triples compact key-val]"
		/pretty
			indent [string!] "Pretty format the output, using given indentation."
		/trace
	] [
		fmt: any [fmt format]
		unless find formats fmt [
			do make error! "Unkown format"
		]
		if indent [indentation: indent]
		pretty?: pretty
		trace?: trace
		data: encoders/:fmt/encode data
		indentation: default-indentation
		data
	]

]

