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

make-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [Cocoa-handle!]
	/local
		values	[red-value!]
		int		[red-integer!]
		value	[red-value!]
		bool	[red-logic!]
		style	[red-word!]
		str		[red-string!]
		blk		[red-block!]
		size	[Cocoa-float!]
		angle	[integer!]
		quality [integer!]
		len		[integer!]
		sym		[integer!]
		name	[c-string!]
		traits	[integer!]
		manager [Cocoa-handle!]
		family	[Cocoa-handle!]
		method	[c-string!]
		hFont	[Cocoa-handle!]
		handle-value [red-handle!]
		temp	[CGPoint!]
		sys?	[logic!]
][
	temp: declare CGPoint!
	values: object/get-values font

	int: as red-integer! values + FONT_OBJ_SIZE
	either TYPE_OF(int) <> TYPE_INTEGER [
		size: as Cocoa-float! 0.0
	][
		size: as Cocoa-float! (int/value * 94 / 72)					;@@ hard coded
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
	hFont: 0
	sys?: no
	either TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
		family: CFString(name)
	][
		sys?: yes
		family: objc_msgSend [default-font sel_getUid "familyName"]
	]
	manager: objc_msgSend [objc_getClass "NSFontManager" sel_getUid "sharedFontManager"]
	until [
		hFont: objc_msgSend [
			manager
			sel_getUid "fontWithFamily:traits:weight:size:"
			family
			traits
			5									;-- ignored if use traits
			temp/x
		]
		unless sys? [CFRelease family]
		if hFont = 0 [
			either sys? [family: CFString("Helvetica") sys?: no][
				family: objc_msgSend [default-font sel_getUid "familyName"]
				sys?: yes
			]
		]
		hFont <> 0
	]

	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 2
		handle-value: handle/make-in blk as integer! hFont handle/CLASS_FONT
		set-cocoa-handle handle-value hFont
	][
		handle-value: as red-handle! block/rs-head blk
		handle-value/header: TYPE_HANDLE
		handle-value/type: handle/CLASS_FONT
		set-cocoa-handle handle-value hFont
	]

	if face <> null [
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]
	hFont
]

get-font-handle: func [
	font	[red-object!]
	idx		[integer!]
	return: [Cocoa-handle!]
	/local
		state  [red-block!]
		h		   [red-handle!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		h: as red-handle! block/rs-head state
		if TYPE_OF(h) = TYPE_HANDLE [
			return get-cocoa-handle h
		]
	]
	0
]

get-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [Cocoa-handle!]
	/local
		hFont [Cocoa-handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return default-font]
	hFont: get-font-handle font 0
	if hFont = 0 [hFont: make-font face font]
	hFont
]

free-font: func [
	font [red-object!]
	/local
		state [red-block!]
		hFont [Cocoa-handle!]
][
	hFont: get-font-handle font 0
	if hFont <> 0 [
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
	return: [Cocoa-handle!]
	/local
		values	[red-value!]
		blk		[red-block!]
		style	[red-word!]
		o-para	[red-object!]
		nsfont	[Cocoa-handle!]
		nscolor [Cocoa-handle!]
		len		[integer!]
		under	[Cocoa-handle!]
		strike	[Cocoa-handle!]
		under-value [integer!]
		strike-value [integer!]
		para	[Cocoa-handle!]
		attrs	[Cocoa-handle!]
		objects	[Cocoa-handle-array!]
		keys	[Cocoa-handle-array!]
		attr-count [NSUInteger!]
		style-sym [integer!]
][
	nsfont: get-font face font
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

	under-value: 0							;-- NSUnderlineStyleNone
	strike-value: 0
	unless zero? len [
		loop len [
			style-sym: symbol/resolve style/symbol
			case [
				style-sym = _underline [under-value: 1]	;-- NSUnderlineStyleSingle
				style-sym = _strike	 [strike-value: 1]
				true			 [0]
			]
			style: style + 1
		]
	]
	under: CFNumberCreate 0 15 :under-value
	strike: CFNumberCreate 0 15 :strike-value

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

	objects: declare Cocoa-handle-array!
	keys: declare Cocoa-handle-array!
	objects/v1: nsfont
	keys/v1: NSFontAttributeName
	objects/v2: nscolor
	keys/v2: NSForegroundColorAttributeName
	objects/v3: under
	keys/v3: NSUnderlineStyleAttributeName
	objects/v4: strike
	keys/v4: NSStrikethroughStyleAttributeName
	attr-count: as NSUInteger! 4
	if para <> 0 [
		objects/v5: para
		keys/v5: NSParagraphStyleAttributeName
		attr-count: as NSUInteger! 5
	]
	attrs: make-NSDictionary objects keys attr-count
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
