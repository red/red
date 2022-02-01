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

; -- options

	default-opts: #(
		include-meta?: #[false]	; export metada also
		str-keys?: #[false]		; leave keys as strings
		text-mark: text!		; text sigil for the COMPACT format
		trace?: #[false]		; use PARSE-TRACE instead of PARSE (debug)
		format: triples			; format to use
		indentation: "    "		; indentation spet to use
		pretty?: #[false]		; multiline output
	)

	include-meta?: false
	str-keys?: false
	text-mark: 'text!
	trace?: false
	format: 'triples
	indentation: "    "
	current-indentation: ""

	error-invalid-data: "Invalid input data"
	error-unknown-format: "Unknown format"

	formats: [triples compact key-val]

	set-options: func [opts] [
		unless map? opts [opts: to map! opts]
		foreach [key value] opts [
			if find keys-of opts key [
				set bind key 'set-options value
			]
		]
	]

	set-format: func [fmt] [
		fmt: any [fmt to word! default-opts/format]
		unless find formats fmt [
			do make error! error-unknown-format
		]
		fmt
	]

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
			if include-meta? [
				repend target [(data)]
				break-at target negate length? reduce [(data)]
			]
			value?: false
		]
	]

	break-at: func [
		"Insert newline at position"
		series [block!]
		index [integer!] "Index to insert newline at. Negative indexes are counted from tail."
	] [
		if negative? index [series: tail series]
		new-line skip series index true
		head series
	]
	load-key: none

	value: att-name: att-value: att-length: att-ns: char-data:
	doctype: verinfo: encinfo: stdinfo: namespace: nl?: attributes:
		none
	cont-val: ""
	value?: false

	target: []
	target-stack: []

	set 'load-xml func [
		"Convert XML data to Red format"
		data [string! file! url!] "XML to convert"
		/as
			fmt [word!] "Select output format [triples compact key-val]"
		/meta     "Preserve meta data"
		/str-keys "Leave keys as strings"
		/local result
	] [
		unless NameChar [init-charsets]
		; process options
		set-options default-opts
		fmt: set-format fmt
		init-decoder fmt
		include-meta?: meta
		str-keys?: str-keys
		; cleanup state
		unless string? data [data: read data]
		clear target
		clear target-stack
		clear attributes
		value: att-name: att-value: verinfo: encinfo: none
		; run parser
		result: either trace? [
			parse-trace data document
		] [
			parse data document
		]
		; make sure there are no lefovers
		clear cont-val
		clear target-stack
		clear attributes
		; return what the user expects
		either result [
			target
		] [
			do make error! error-invalid-data
		]
	]

	init-charsets: has [word spec] [
		Char: charset [
			#"^(01)" -#"^(D7FF)" #"^(E000)" - #"^(FFFD)" #"^(10000)" - #"^(10FFFF)"
		]
		RestrictedChar: charset [
			#"^(01)" -#"^(08)" #"^(0B)" - #"^(0C)" #"^(0E)" - #"^(1F)"
			#"^(7F)" - #"^(84)" #"^(86)" - #"^(9F)"
		]
		NameStartChar: charset [
			":_" #"a" - #"z" #"A" - #"Z" #"0" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)"
			#"^(F8)" - #"^(02FF)" #"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)"
			#"^(200C)" - #"^(200D)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)"
			#"^(3001)" - #"^(D7FF)" #"^(F900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)"
			#"^(010000)" - #"^(0EFFFF)"
		]
		NameChar: union NameStartChar charset [
			"-." #"0" - #"9" #"^(B7)" #"^(0300)" - #"^(036F)" #"^(203F)" - #"^(2040)"
		]
	]

	sq: #"'"
	dq: #"^""
	caret: #"^^"
	lower-letter: charset [#"a" - #"z"]
	upper-letter: charset [#"A" - #"Z"]
	digit:        charset [#"0" - #"9"]
	letter:       union lower-letter upper-letter
	alphanum:     union letter digit
	hexnum:       union digit charset "abcdefABCDEF"

	; -- Document
	document: [
		opt prolog
		element
	]

	; -- Character Range
	Char: none
	RestrictedChar: none
	;TODO: compatibility characters

	; -- White Space
	S: charset reduce [space tab cr lf]
	S?: [opt S]
	S*: [any S]
	S+: [some S]

	; -- Names and Tokens
	NameStartChar: none
	NameChar: none
	Name:     [NameStartChar any NameChar]
	Names:    [Name any [space Name]]
	Nmtoken:  [some NameChar]
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
		"<!DOCTYPE"
		(doctype: none)
		S+
		copy doctype [
			Name
			opt [S+ ExternalID]
			S*
			opt [#"[" intSubset #"]" S*]
		]
		store-doctype
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
	SDDecl-logic: [
		"yes" (stdinfo: true)
	|	"no"  (stdinfo: false)
	]
	SDDecl: [
		(stdinfo: none)
		S+
		"standalone"
		Eq
		[sq SDDecl-logic sq | dq SDDecl-logic dq]
	]

	; -- Elements
	element: [
		EmptyElemTag
	|	S* STag S* content S* ETag pop-stack S*
	]
	STag: [
		(clear attributes)
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
		(clear attributes)
		#"<"
		copy value Name
		any [
			S+
			Attribute
			store-attributes
		]
		S*
		"/>"
		(value?: cont-val: copy "")
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
	CharRef: [ "&#" some digit #";" | "&#x" some hexnum #";"]
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
				if str-keys? [return value]
				either find value #":" [
					load replace/all value #":" #"/"
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
				break-at target -1
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
				'xml!
				none
				compose [
					version: (verinfo)
					encoding: (encinfo)
					(either not none? stdinfo [compose [
						standalone: (stdinfo)]][]
					)
				]
			]
			'store-doctype meta-action ['doctype! doctype none]
			'store-pi meta-action ['PI! load-key att-name value]
			'store-comment meta-action ['comment! trim value none]
			'store-cdata meta-action ['cdata! value none]
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
					append target reduce [to word! text-mark copy char-data]
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
					break-at target -1
					nl?: true
				]
				append target value
				unless nl? [
					break-at target -1
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
				if include-meta? [
					append target 'xml!
					if verinfo [repend target [#version  verinfo]]
					if encinfo [repend target [#encoding encinfo]]
					unless none? stdinfo [repend target [#standalone stdinfo]]
				]
			)
			'store-doctype meta-action ['doctype! doctype]
			'store-pi meta-action ['PI! reduce [att-name trim value]]

			'store-pi quote (
				att-ns: none
				att-name: load-key/att form att-name
				append target compose/deep [
					PI! [
						(either att-ns [to refinement! att-ns][])
						(att-name)
						(trim value)
					]
				]
				att-ns: none
			)
		
			'store-comment meta-action ['comment! trim value]
			'store-cdata meta-action ['cdata! value]
		]
		key-val: reduce [
			'attributes []
			'load-key func [value] [
				if str-keys? [return value]
				either find value #":" [
					load replace/all value #":" #"/"
				] [to word! value]
			]
			'store-char-data func [] [
				if all [
					string? char-data
					not empty? trim char-data
				] [
					repend target [
						'text!
						copy char-data
					]
					break-at target -2
				]
				clear char-data
			]
			'push-stack quote (
				; store non-eclosed text if exists
				store-char-data
				; store latest tag
				repend target [load-key value copy []]
				break-at target -2
				append/only target-stack target
				unless empty? attributes [
					repend last target [
					'attr! copy attributes
					]
				]
				break-at last target -2
				; do cleanup
				clear attributes
				target: last target
			)
			'pop-stack quote (
				store-char-data
;				unless find target 'text! [repend target ['text! none]]
;				break-at target -2
				target: take/last target-stack
				value?: false
			)
			'store-attributes quote (
				if att-name [
					repend attributes [load-key att-name strip att-value]
					att-name: att-value: none
				]
			)
			'store-xml-decl meta-action [
				'xml!
				compose [
					version: (verinfo)
					encoding: (encinfo)
					(either not none? stdinfo [compose [
						standalone: (stdinfo)]][]
					)
				]
			]
			'store-doctype meta-action ['doctype! doctype]
			'store-pi meta-action ['PI! reduce [att-name value]]
			'store-comment meta-action ['comment! trim value]
			'store-cdata meta-action ['cdata! value]
		]
	]

; === encoder part ===========================================================

	output: make string! 10000

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
		data [block! map! none!]
	] [
		if any [
			not data
			data = 'none ; be sure that all NONEs are processed
			empty? data
		] [return ""]
		data: collect/into [
			foreach [key value] data [
				keep rejoin [key #"=" enquote value space]
			]
		] clear ""
		rejoin [space trim data]
	]

	make-tag: func [
		name
		/with
			atts [block! map! none!]
		/close
		/empty
	] [
		rejoin trim reduce [
			#"<" if close [#"/"] form name make-atts atts if empty [#"/"] #">"
		]
	]


	ns-name: tag-name: ns-att-name:
		none
	tag-stack: []

	meta-tags: [xml! doctype! PI! comment! cdata!]

	make-xmldecl: func [
		version
		encoding
		standalone
	] [
		rejoin [
			{<?xml version="} version dq
			either encoding [
				rejoin [ { encoding="} encoding dq]
			] [""]
			either not none? standalone [
			; STANDALONE can be missing (none), true or false
				rejoin [ { standalone="} pick ["yes" "no"] standalone dq]
			] [""]
			{ ?>}
		]
	]

	encoders: context [
		triples: context [
			process-tag: func [
				data
			] [
				if find meta-tags data/1 [return process-meta data]
				i+
				also collect [
					case [
						all [
							not none? data/3
							not block? data/3
						] [do make error! error-invalid-data]
						; empty tag
						any [
							all [block? data/2 empty? data/2]
							all [data/1 not data/2]
						] [
							keep reduce [indent make-tag/with/empty data/1 data/3]
						]
						; tag pair
						any [
							all [block? data/2 not empty? data/2]
							all [data/1 string? data/2]
						] [
							keep reduce [indent make-tag/with data/1 data/3]
							either string? data/2 [keep data/2] [
								until [
									keep process-tag data/2
									data/2: skip data/2 3
									empty? data/2
								]
							]
							keep reduce [indent make-tag/close data/1]
						]
						not data/1 [keep data/2]
					]
				]
				i-
			]
			process-meta: func [data] [
				rejoin switch data/1 [
					xml! [[
						make-xmldecl
							data/3/version
							data/3/encoding
							data/3/standalone
					]]
					doctype! [[ {<!DOCTYPE } data/2 #">"]]
					PI! [[ {<?} data/2 space data/3 {?>}]]
					comment! [[ {<!-- } data/2 { -->}]]
					cdata! [[ {<![CDATA[} data/2 {]]>}]]
				]
			]
			encode: func [
				data [block!]
			] [
				if any [
					empty? data
					not zero? (length? data) // 3
				] [
					do make error! error-invalid-data
				]
				clear output
				; TODO add proper header: xml/doctype
				until [
					either find meta-tags data/1 [
						append output process-meta data
					] [
						repend output process-tag data
					]
					data: skip data 3
					tail? data
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
				text-mark copy value string!
				(append output value)
			]
			pi-rule: [
				'PI!
				set value block!
				(repend output [{<?} value/1 space value/2 {?>}])
			]
			doctype-rule: [
				'doctype!
				set value string!
				(repend output [ {<!DOCTYPE } value #">" ])
			]
			comment-rule: [
				'comment!
				set value string!
				(repend output [ {<!-- } value { -->}])
			]
			cdata-rule: [
				'cdata!
				set value string!
				(repend output [ {<![CDATA[} value {]]>}])
			]
			xml-ver: xml-enc: xml-sal: none
			xmldecl-rule: [
				'xml!
				(xml-ver: xml-enc: xml-sal: none)
				some [
					#version    set xml-ver skip
				|	#encoding   set xml-enc skip
				|	#standalone set xml-sal skip
				]
				(append output make-xmldecl xml-ver xml-enc xml-sal)
			]
			content-rule: [
				text-rule
			|	pi-rule
			|	doctype-rule
			|	comment-rule
			|	cdata-rule
			|	xmldecl-rule
			|	tag-rule
			]
			encode: func [
				data
				/local parse*
			] [
				clear output
				clear tag-stack
				text-mark: to lit-word! text-mark
				parse*: either trace? [:parse-trace] [:parse]
				either parse* data [some content-rule] [
					output
				] [
					do make error! error-invalid-data
				]
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
				into [
					some [
						'attr! [none! | into [any attr-rule]]
					|	text-rule
					|	pi-rule
					|	doctype-rule
					|	comment-rule
					|	cdata-rule
					|	xmldecl-rule
					|	tag-rule
					]
				]
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
				'text! [
					set value string! (append output value)
				|	none!
				]
			]
			pi-rule: [
				'PI!
				set value block!
				(repend output [{<?} value/1 space value/2 {?>}])
			]
			doctype-rule: [
				'doctype!
				set value string!
				(repend output [ {<!DOCTYPE } value #">" ])
			]
			comment-rule: [
				'comment!
				set value string!
				(repend output [ {<!-- } value { -->}])
			]
			cdata-rule: [
				'cdata!
				set value string!
				(repend output [ {<![CDATA[} value {]]>}])
			]
			xmldecl-rule: [
				'xml!
				set value block!
				(
					append output make-xmldecl
						value/version
						value/encoding
						value/standalone
				)
			]
			content-rule: [
				text-rule
			|	pi-rule
			|	doctype-rule
			|	comment-rule
			|	cdata-rule
			|	xmldecl-rule
			|	tag-rule
			]
			encode: func [
				data
				/local parse*
			] [
				clear output
				clear tag-stack
				parse*: either trace? [:parse-trace] [:parse]
				either parse* data [some content-rule] [
					output
				] [
					do make error! error-invalid-data
				]
			]
		]
	]

	set 'to-xml func [
		data [block!]	"Red data for conversion"
		/as
			fmt [word!]	"Format of the source data [triples compact key-val]"
		/pretty
			indent [string!] "Pretty format the output, using given indentation."
	] [
		; process options
		set-options default-opts
		fmt: set-format fmt
		if indent [indentation: indent]
		pretty?: pretty
		; do parsing
		encoders/:fmt/encode data
	]

]

put system/codecs 'xml context [
	Title:     "XML codec"
	Name:      'XML
	Mime-Type: [application/xml]
	Suffixes:  [%.xml]
	encode: func [data [any-type!] where [file! url! none!]] [
		to-xml data
	]
	decode: func [text [string! binary! file!]] [
		if file? text [text: read text]
		if binary? text [text: to string! text]
		load-xml text
	]
]
