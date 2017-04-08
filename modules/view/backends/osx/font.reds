Red/System [
	Title:	"Cocoa fonts management"
	Author: "Qingtian Xie"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
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
		manager [integer!]
		method	[c-string!]
		hFont	[handle!]
		temp	[CGPoint!]
][
	temp: declare CGPoint!
	values: object/get-values font

	int: as red-integer! values + FONT_OBJ_SIZE
	either TYPE_OF(int) <> TYPE_INTEGER [
		size: as float32! 0.0
	][
		size: as float32! int/value * 96 / 72						;@@ hard coded
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

	temp/x: size
	str: as red-string! values + FONT_OBJ_NAME
	hFont: null
	if TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
		sym: CFString(name)
		manager: objc_msgSend [objc_getClass "NSFontManager" sel_getUid "sharedFontManager"]
		hFont: as handle! objc_msgSend [
			manager
			sel_getUid "fontWithFamily:traits:weight:size:"
			sym
			traits
			5									;-- ignored if use traits
			temp/x
		]
		CFRelease sym
	]
	if null? hFont [							;-- use system font
		method: either traits and NSBoldFontMask <> 0 [
			"boldSystemFontOfSize:"
		][
			"systemFontOfSize:"
		]
		hFont: as handle! objc_msgSend [objc_getClass "NSFont" sel_getUid method temp/x]
	]

	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 2
		handle/make-in blk as-integer hFont
	][
		int: as red-integer! block/rs-head blk
		int/header: TYPE_HANDLE
		int/value: as-integer hFont
	]

	if face <> null [
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]
	hFont
]

get-font-handle: func [
	font	[red-object!]
	return: [handle!]
	/local
		state  [red-block!]
		int	   [red-integer!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
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
	if TYPE_OF(font) <> TYPE_OBJECT [return null]
	hFont: get-font-handle font
	if null? hFont [hFont: make-font face font]
	hFont
]

free-font: func [
	font [red-object!]
	/local
		state [red-block!]
		hFont [handle!]
][
	hFont: get-font-handle font
	if hFont <> null [
		state: as red-block! (object/get-values font) + FONT_OBJ_STATE
		state/header: TYPE_NONE
	]
]

update-font: func [
	font [red-object!]
	flag [integer!]
][
	switch flag [
		FONT_OBJ_NAME
		FONT_OBJ_SIZE
		FONT_OBJ_STYLE
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

	para: 0
	if type = button [
		para: objc_msgSend [objc_getClass "NSParagraphStyle" sel_getUid "defaultParagraphStyle"]
		para: objc_msgSend [para sel_getUid "mutableCopy"]
		objc_msgSend [para sel_getUid "setAlignment:" NSTextAlignmentCenter]
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