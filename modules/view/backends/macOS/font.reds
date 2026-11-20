Red/System [
	Title:	"Cocoa fonts management"
	Author: "Qingtian Xie"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

ns-font-weight: func [								;-- NSFontWeightTrait value of a weight from 100 to 900
	weight	[integer!]
	return: [float!]
][
	switch weight + 50 / 100 [
		0 1 [-0.8]
		2	[-0.6]
		3	[-0.4]
		4	[0.0]
		5	[0.23]
		6	[0.3]
		7	[0.4]
		8	[0.56]
		default [0.62]
	]
]

font-weight?: func [								;-- weight from 100 to 900 of an NSFont's face
	nsfont	[integer!]
	return: [integer!]
	/local
		traits	[int-ptr!]
		num		[int-ptr!]
		w		[float!]
		d		[float!]
		best	[float!]
		weight	[integer!]
		n		[integer!]
][
	traits: CTFontCopyTraits nsfont
	num: CFDictionaryGetValue traits NSFontWeightTrait
	w: 0.0
	unless null? num [CFNumberGetValue num 6 as int-ptr! :w]	;-- kCFNumberFloat64Type
	CFRelease as-integer traits
	best: 9.0
	weight: 400
	n: 100
	until [
		d: (ns-font-weight n) - w
		if d < 0.0 [d: 0.0 - d]
		if d < best [
			best: d
			weight: n
		]
		n: n + 100
		n > 900
	]
	weight
]

make-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [handle!]
	/local
		values	[red-value!]
		int		[red-integer!]
		value	[red-value!]
		bool	[red-logic!]
		style	[red-word!]
		str		[red-string!]
		blk		[red-block!]
		size	[float32!]
		angle	[integer!]
		quality [integer!]
		len		[integer!]
		sym		[integer!]
		name	[c-string!]
		traits	[integer!]
		weight	[integer!]
		w		[float!]
		w-num	[integer!]
		t-num	[integer!]
		dict	[integer!]
		attrs	[integer!]
		desc	[integer!]
		manager [integer!]
		method	[c-string!]
		hFont	[handle!]
		temp	[CGPoint!]
		sys?	[logic!]
][
	temp: declare CGPoint!
	values: object/get-values font

	int: as red-integer! values + FONT_OBJ_SIZE
	either TYPE_OF(int) <> TYPE_INTEGER [
		size: as float32! 0.0
	][
		size: as float32! int/value * 94 / 72						;@@ hard coded
	]

	int: as red-integer! values + FONT_OBJ_ANGLE
	angle: either TYPE_OF(int) = TYPE_INTEGER [int/value * 10][0]	;-- in tenth of degrees

	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]

	traits: 0
	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold	 	 [traits: traits or NSBoldFontMask]
				sym = _italic	 [traits: traits or NSItalicFontMask]
				sym = _underline [0]
				sym = _strike	 [0]
				true			 [0]
			]
			style: style + 1
		]
	]
	weight: get-font-weight font 0
	if weight > 0 [traits: traits and NSItalicFontMask]	;-- the weight replaces `bold`

	temp/x: size
	str: as red-string! values + FONT_OBJ_NAME
	hFont: null
	sys?: no
	either TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
		sym: CFString(name)
	][
		sys?: yes
		sym: objc_msgSend [default-font sel_getUid "familyName"]
	]
	manager: objc_msgSend [objc_getClass "NSFontManager" sel_getUid "sharedFontManager"]
	until [
		hFont: as handle! objc_msgSend [
			manager
			sel_getUid "fontWithFamily:traits:weight:size:"
			sym
			traits
			5									;-- ignored if use traits
			temp/x
		]
		unless sys? [CFRelease sym]
		if null? hFont [
			either sys? [sym: CFString("Helvetica") sys?: no][
				sym: objc_msgSend [default-font sel_getUid "familyName"]
				sys?: yes
			]
		]
		hFont <> null
	]
	if weight > 0 [										;-- the family's face closest to the weight
		w: ns-font-weight weight
		w-num: CFNumberCreate 0 6 as int-ptr! :w		;-- kCFNumberFloat64Type
		t-num: CFNumberCreate 0 3 :traits				;-- kCFNumberSInt32Type, NSItalicFontMask = NSFontItalicTrait
		dict: objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
		dict: objc_msgSend [dict sel_getUid "initWithObjectsAndKeys:" w-num NSFontWeightTrait t-num NSFontSymbolicTrait 0]
		sym: objc_msgSend [hFont sel_getUid "familyName"]
		attrs: objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
		attrs: objc_msgSend [attrs sel_getUid "initWithObjectsAndKeys:" sym NSFontFamilyAttribute dict NSFontTraitsAttribute 0]
		desc: objc_msgSend [objc_getClass "NSFontDescriptor" sel_getUid "alloc"]
		desc: objc_msgSend [desc sel_getUid "initWithFontAttributes:" attrs]
		sym: objc_msgSend [objc_getClass "NSFont" sel_getUid "fontWithDescriptor:size:" desc temp/x]
		if sym <> 0 [hFont: as handle! sym]
		objc_msgSend [desc sel_getUid "release"]
		objc_msgSend [attrs sel_getUid "release"]
		objc_msgSend [dict sel_getUid "release"]
		CFRelease w-num
		CFRelease t-num
	]

	blk: get-font-state font
	either null? blk [
		blk: make-font-state font 1
		handle/make-in blk as-integer hFont handle/CLASS_FONT
	][
		int: as red-integer! block/rs-head blk
		int/header: TYPE_HANDLE
		int/value: as-integer hFont
	]

	link-font-to-face face font
	hFont
]

get-font-handle: func [
	font	[red-object!]
	idx		[integer!]
	return: [handle!]
	/local
		state  [red-block!]
		int	   [red-integer!]
][
	state: get-font-state font
	if state <> null [
		int: as red-integer! block/rs-head state
		if TYPE_OF(int) = TYPE_HANDLE [
			return as handle! int/value
		]
	]
	null
]

get-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [handle!]
	/local
		hFont [handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return as handle! default-font]
	hFont: get-font-handle font 0
	if null? hFont [hFont: make-font face font]
	link-font-to-face face font
	hFont
]

free-font: func [
	font [red-object!]
	/local
		hFont [handle!]
][
	hFont: get-font-handle font 0
	if hFont <> null [drop-font-state font]
]

update-font: func [
	font [red-object!]
	flag [integer!]
][
	switch flag [
		FONT_OBJ_NAME
		FONT_OBJ_SIZE
		FONT_OBJ_STYLE
		FONT_OBJ_WEIGHT
		FONT_OBJ_ANGLE
		FONT_OBJ_ANTI-ALIAS? [
			free-font font
			make-font null font
		]
		default [0]
	]
]

make-font-attrs: func [
	font	[red-object!]
	face	[red-object!]
	type	[integer!]
	return: [integer!]
	/local
		values	[red-value!]
		blk		[red-block!]
		style	[red-word!]
		o-para	[red-object!]
		nsfont	[integer!]
		nscolor [integer!]
		len		[integer!]
		under	[integer!]
		strike	[integer!]
		para	[integer!]
		attrs	[integer!]
][
	nsfont: as-integer get-font face font
	values: object/get-values font
	nscolor: to-NSColor as red-tuple! values + FONT_OBJ_COLOR
	if zero? nscolor [
		nscolor: objc_msgSend [objc_getClass "NSColor" sel_getUid "blackColor"]
	]
	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]

	under: 0									;-- NSUnderlineStyleNone
	strike: 0
	unless zero? len [
		loop len [
			attrs: symbol/resolve style/symbol
			case [
				attrs = _underline [under: 1]	;-- NSUnderlineStyleSingle
				attrs = _strike	 [strike: 1]
				true			 [0]
			]
			style: style + 1
		]
	]
	under: CFNumberCreate 0 15 :under
	strike: CFNumberCreate 0 15 :strike

	len: -1
	if TYPE_OF(face) = TYPE_OBJECT [
		o-para: as red-object! (object/get-values face) + FACE_OBJ_PARA
		if TYPE_OF(o-para) = TYPE_OBJECT [len: 3 and get-para-flags type o-para]
	]
	if all [any [type = button type = toggle] len = -1][len: NSTextAlignmentCenter]

	para: 0
	if len <> -1 [
		para: objc_msgSend [objc_getClass "NSParagraphStyle" sel_getUid "defaultParagraphStyle"]
		para: objc_msgSend [para sel_getUid "mutableCopy"]
		objc_msgSend [para sel_getUid "setAlignment:" len]
	]

	attrs: objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
	attrs: objc_msgSend [
		attrs sel_getUid "initWithObjectsAndKeys:"
		nsfont NSFontAttributeName
		nscolor NSForegroundColorAttributeName
		under NSUnderlineStyleAttributeName
		strike NSStrikethroughStyleAttributeName
		para NSParagraphStyleAttributeName
		0
	]
	if para <> 0 [objc_msgSend [para sel_getUid "release"]]
	CFRelease under
	CFRelease strike
	attrs
]

;setup-fixed-collection: func [
;	/local
;		collection		[integer!]
;		collection-cls	[integer!]
;		descriptors		[integer!]
;		all-descs		[integer!]
;		desc			[integer!]
;		enumerator		[integer!]
;		traits			[integer!]
;		sel_traits		[integer!]
;][
;	collection-cls: objc_getClass "NSFontCollection"
;	collection: objc_msgSend [
;		collection-cls sel_getUid "fontCollectionWithName:" NSString("com.apple.AllFonts")
;	]

;	descriptors: objc_msgSend [
;		objc_msgSend [objc_getClass "NSMutableArray" sel_alloc] sel_init
;	]
;	all-descs: objc_msgSend [collection sel_getUid "matchingDescriptors"]
;	enumerator: objc_msgSend [all-descs sel_getUid "objectEnumerator"]
;	sel_traits: sel_getUid "symbolicTraits"
;	while [
;		desc: objc_msgSend [enumerator sel_getUid "nextObject"]
;		desc <> 0
;	][
;		traits: objc_msgSend [desc sel_traits]
;		if traits and NSFontMonoSpaceTrait <> 0 [objc_msgSend [descriptors sel_addObject desc]]
;	]

;	collection: objc_msgSend [
;		collection-cls sel_getUid "fontCollectionWithDescriptors:" descriptors
;	]

;	objc_msgSend [
;		collection-cls sel_getUid "showFontCollection:withName:visibility:error:"
;		collection NSString("Red Monospaced") 1 0			;-- NSFontCollectionVisibilityProcess: 1
;	]
;]
