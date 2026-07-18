Red/System [
	Title:	"Text Box Windows DirectWrite Backend"
	Author: "Xie Qingtian"
	File: 	%text-box.reds
	Tabs: 	4
	Dependency: %draw.reds
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define TBOX_METRICS_OFFSET?		0
#define TBOX_METRICS_INDEX?			1
#define TBOX_METRICS_LINE_HEIGHT	2
#define TBOX_METRICS_SIZE			3
#define TBOX_METRICS_LINE_COUNT		4
#define TBOX_METRICS_CHAR_INDEX?	5

max-line-cnt:  0

get-text-box-state-handle: func [
	state	[red-block!]
	index	[integer!]
	return: [Cocoa-handle!]
	/local
		cell [red-value!]
		int  [red-integer!]
][
	cell: block/rs-head state + index
	#either ABI = 'apple-aarch64 [
		get-cocoa-handle as red-handle! cell
	][
		int: as red-integer! cell
		as Cocoa-handle! int/value
	]
]

append-text-box-state-handle: func [
	state	[red-block!]
	value	[Cocoa-handle!]
	/local
		result [red-handle!]
][
	#either ABI = 'apple-aarch64 [
		result: handle/make-in state as integer! value handle/CLASS_RICHTEXT
		set-cocoa-handle result value
	][
		integer/make-in state as integer! value
	]
]

OS-text-box-color: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
][
	objc_msgSend [layout sel_addAttribute NSForegroundColorAttributeName rs-to-NSColor color pos len]
]

OS-text-box-background: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
][
	objc_msgSend [layout sel_addAttribute NSBackgroundColorAttributeName rs-to-NSColor color pos len]
]

OS-text-box-weight: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	weight	[integer!]
][
	objc_msgSend [layout sel_getUid "applyFontTraits:range:" NSBoldFontMask pos len]
]

OS-text-box-italic: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
][
	objc_msgSend [layout sel_getUid "applyFontTraits:range:" NSItalicFontMask pos len]
]

OS-text-box-underline: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
	/local
		value [integer!]
		under [Cocoa-handle!]
][
	value: 1
	under: CFNumberCreate 0 15 :value
	objc_msgSend [layout sel_addAttribute NSUnderlineStyleAttributeName under pos len]
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	/local
		value [integer!]
		strike [Cocoa-handle!]
][
	value: 1
	strike: CFNumberCreate 0 15 :value
	objc_msgSend [layout sel_addAttribute NSStrikethroughStyleAttributeName strike pos len]
]

OS-text-box-border: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
	0
]

OS-text-box-font-name: func [
	nsfont	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	name	[red-string!]
	/local
		desc	[Cocoa-handle!]
		font	[Cocoa-handle!]
		str		[Cocoa-handle!]
][
	desc: objc_msgSend [nsfont sel_getUid "fontDescriptor"]
	str: to-CFString name
	font: objc_msgSend [
		objc_getClass "NSFont" sel_getUid "fontWithDescriptor:size:"
		objc_msgSend [desc sel_getUid "fontDescriptorWithFamily:" str]
		0
	]
	objc_msgSend [layout sel_addAttribute NSFontAttributeName font pos len]
	CFRelease str
]

OS-text-box-font-size: func [
	nsfont	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
	/local
		desc	[Cocoa-handle!]
		font	[Cocoa-handle!]
		temp	[CGPoint!]
][
	temp: declare CGPoint!
	temp/x: as Cocoa-float! size
	temp/y: as Cocoa-float! 0.0
	desc: objc_msgSend [nsfont sel_getUid "fontDescriptor"]
	font: objc_msgSend [
		objc_getClass "NSFont" sel_getUid "fontWithDescriptor:size:"
		objc_msgSend [desc sel_getUid "fontDescriptorWithSize:" temp/x]
		0
	]
	objc_msgSend [layout sel_addAttribute NSFontAttributeName font pos len]
]

OS-text-box-metrics: func [
	state	[red-block!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
	/local
		layout	[Cocoa-handle!]
		ts		[Cocoa-handle!]
		tc		[Cocoa-handle!]
		pos		[red-pair!]
		int		[red-integer!]
		str		[red-string!]
		values	[red-value!]
		y		[Cocoa-float!]
		cnt		[integer!]
		yy		[integer!]
		xx		[integer!]
		_w		[integer!]
		_h		[integer!]
		_y		[integer!]
		_x		[integer!]
		frame	[NSRect! value]
		cg-pt	[CGPoint! value]
		idx		[integer!]
		len		[integer!]
		range	[NSRange! value]
		last?	[logic!]
		pt		[red-point2D!]
][
	int: as red-integer! block/rs-head state + 2
	layout: get-text-box-state-handle state 0
	tc: get-text-box-state-handle state 1
	ts: get-text-box-state-handle state 2
	as red-value! switch type [
		TBOX_METRICS_OFFSET?
		TBOX_METRICS_LINE_HEIGHT [
			str: as red-string! int + 2
			xx: 0 _x: 0
			int: as red-integer! arg0
			idx: int/value - 1
			len: string/rs-length? str
			if idx < 0 [idx: 0]
			last?: idx >= len
			if last? [idx: len - 1]

			frame: objc_msgSend_rect [
				layout sel_getUid "lineFragmentUsedRectForGlyphAtIndex:effectiveRange:"
				as NSUInteger! idx 0
			]
			either type = TBOX_METRICS_LINE_HEIGHT [
				float/push as float! frame/h
			][
				cg-pt/y: as Cocoa-float! 0.0
				either last? [
					cg-pt/x: frame/x + frame/w
				][
					cg-pt: objc_msgSend_pt [layout sel_getUid "locationForGlyphAtIndex:" as NSUInteger! idx]
				]
				point2D/push COCOA_TO_F32(cg-pt/x) COCOA_TO_F32(cg-pt/y)
			]
		]
		TBOX_METRICS_INDEX?
		TBOX_METRICS_CHAR_INDEX? [
			y: as Cocoa-float! 0.0
			pos: as red-pair! arg0
			xx: 0
			cg-pt/x: as Cocoa-float! pos/x
			cg-pt/y: as Cocoa-float! pos/y
			idx: as integer! objc_msgSend [
				layout
				sel_getUid "characterIndexForPoint:inTextContainer:fractionOfDistanceBetweenInsertionPoints:"
				cg-pt/x cg-pt/y tc :y
			]
			if all [type = TBOX_METRICS_INDEX? y > as Cocoa-float! 0.5][idx: idx + 1]
			integer/push idx + 1
		]
		TBOX_METRICS_SIZE [
			range: objc_msgSend_range [layout sel_getUid "glyphRangeForTextContainer:" tc]
			idx: as integer! range/idx
			len: as integer! range/len
			frame: objc_msgSend_rect [
				layout sel_getUid "boundingRectForGlyphRange:inTextContainer:"
				range/idx range/len tc
			]
			point2D/push COCOA_TO_F32(frame/w) COCOA_TO_F32(frame/h)
		]
		TBOX_METRICS_LINE_COUNT [
			range: objc_msgSend_range [layout sel_getUid "glyphRangeForTextContainer:" tc]
			len: as integer! range/len
			cnt: 0
			idx: 0
			while [idx < len][
				cnt: cnt + 1
				frame: objc_msgSend_rect [
					layout sel_getUid "lineFragmentRectForGlyphAtIndex:effectiveRange:"
					as NSUInteger! idx :range
				]
				idx: as integer! (range/idx + range/len)
			]
			if zero? cnt [cnt: 1]
			integer/push cnt
		]
		default [0]
	]
]

OS-text-box-layout: func [
	box			[red-object!]
	target		[int-ptr!]
	nscolor		[Cocoa-handle!]
	catch?		[logic!]
	return:		[Cocoa-handle!]
	/local
		values	[red-value!]
		state	[red-block!]
		int		[red-integer!]
		styles	[red-block!]
		size	[red-pair!]
		font	[red-object!]
		fcolor	[red-tuple!]
		bool	[red-logic!]
		layout	[Cocoa-handle!]
		ts		[Cocoa-handle!]
		tc		[Cocoa-handle!]
		str		[Cocoa-handle!]
		w		[integer!]
		h		[integer!]
		sz		[NSSize!]
		attrs	[Cocoa-handle!]
		objects	[Cocoa-handle-array!]
		keys	[Cocoa-handle-array!]
		attr-count [NSUInteger!]
		nsfont	[Cocoa-handle!]
		clr		[Cocoa-handle!]
		para	[Cocoa-handle!]
		cached?	[logic!]
		pt		[red-point2D!]
		sx sy	[float32!]
][
	values: object/get-values box

	str: to-NSString as red-string! values + FACE_OBJ_TEXT
	state: as red-block! values + FACE_OBJ_EXT3
	size: as red-pair! values + FACE_OBJ_SIZE
	font: as red-object! values + FACE_OBJ_FONT
	nsfont: get-font null font
	cached?: TYPE_OF(state) = TYPE_BLOCK

	sz: declare NSSize!
	sz/w: as Cocoa-float! 1.0e37
	sz/h: as Cocoa-float! 1.0e37

	either cached? [
		layout: get-text-box-state-handle state 0
		tc: get-text-box-state-handle state 1
		ts: get-text-box-state-handle state 2
		para: get-text-box-state-handle state 3
		int: as red-integer! block/rs-head state + 3
		bool: as red-logic! int + 2
		bool/value: false
	][
		tc: objc_msgSend [
			objc_msgSend [objc_getClass "NSTextContainer" sel_alloc]
			sel_getUid "initWithSize:" sz/w sz/h
		]
		objc_msgSend [tc sel_getUid "setLineFragmentPadding:" (as Cocoa-float! 0.0)]

		ts: objc_msgSend [
			objc_msgSend [objc_getClass "NSTextStorage" sel_alloc]
			sel_getUid "initWithString:" str
		]

		layout: objc_msgSend [objc_msgSend [objc_getClass "RedLayoutManager" sel_alloc] sel_init]
		objc_msgSend [layout sel_getUid "addTextContainer:" tc]
		objc_msgSend [tc sel_release]
		objc_msgSend [ts sel_getUid "addLayoutManager:" layout]
		objc_msgSend [layout sel_release]
		objc_msgSend [layout sel_getUid "setDelegate:" layout]
		objc_setAssociatedObject layout RedAttachedWidgetKey nsfont OBJC_ASSOCIATION_ASSIGN

		para: objc_msgSend [objc_getClass "NSParagraphStyle" sel_getUid "defaultParagraphStyle"]
		para: objc_msgSend [para sel_getUid "mutableCopy"]
		sz: objc_msgSend_sz [nsfont sel_getUid "advancementForGlyph:" 32]		;-- #" "
		objc_msgSend [para sel_getUid "setDefaultTabInterval:" sz/w * (as Cocoa-float! 4.0)]
		objc_msgSend [para sel_getUid "setTabStops:" objc_msgSend [objc_getClass "NSArray" sel_getUid "array"]]

		block/make-at state 6
		append-text-box-state-handle state layout
		append-text-box-state-handle state tc
		append-text-box-state-handle state ts
		append-text-box-state-handle state para
		none/make-in state
		logic/make-in state false
	]

	copy-cell values + FACE_OBJ_TEXT (block/rs-head state) + 4

	;@@ set para: as red-object! values + FACE_OBJ_PARA

	if ANY_COORD?(size) [
		GET_PAIR_XY(size sx sy)
		if sx <> F32_0 [sz/w: F32_TO_COCOA sx]
		if sy <> F32_0 [sz/h: F32_TO_COCOA sy]
	]
	objc_msgSend [tc sel_getUid "setSize:" sz/w sz/h]

	objc_msgSend [ts sel_getUid "beginEditing"]

	if cached? [
		w: as integer! objc_msgSend [ts sel_length]
		objc_msgSend [ts sel_getUid "deleteCharactersInRange:" 0 w]
		objc_msgSend [ts sel_getUid "replaceCharactersInRange:withString:" 0 0 str]
	]

	objects: declare Cocoa-handle-array!
	keys: declare Cocoa-handle-array!
	objects/v1: nsfont
	keys/v1: NSFontAttributeName
	objects/v2: para
	keys/v2: NSParagraphStyleAttributeName
	attr-count: as NSUInteger! 2
	if nscolor <> 0 [
		objects/v3: nscolor
		keys/v3: NSForegroundColorAttributeName
		attr-count: as NSUInteger! 3
	]
	attrs: make-NSDictionary objects keys attr-count
	w: as integer! objc_msgSend [str sel_length]
	objc_msgSend [ts sel_getUid "setAttributes:range:" attrs 0 w]
	objc_msgSend [attrs sel_release]
	;-- base font foreground; data ranges layer above
	if TYPE_OF(font) = TYPE_OBJECT [
		fcolor: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
		if TYPE_OF(fcolor) = TYPE_TUPLE [
			OS-text-box-color null as handle! ts 0 w get-tuple-color fcolor
		]
	]

	styles: as red-block! values + FACE_OBJ_DATA
	if all [
		TYPE_OF(styles) = TYPE_BLOCK
		1 < block/rs-length? styles
	][
		parse-text-styles as handle! nsfont as handle! ts styles as red-string! values + FACE_OBJ_TEXT catch?
	]

	objc_msgSend [ts sel_getUid "endEditing"]
	layout
]
