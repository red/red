Red/System [
	Title:	"Text Box Windows DirectWrite Backend"
	Author: "Xie Qingtian"
	File: 	%text-box.reds
	Tabs: 	4
	Dependency: %draw-d2d.reds
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define TBOX_METRICS_OFFSET?		0
#define TBOX_METRICS_INDEX?			1
#define TBOX_METRICS_LINE_HEIGHT	2
#define TBOX_METRICS_METRICS		3

max-line-cnt:  0

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
		under [integer!]
][
	under: 1
	under: CFNumberCreate 0 15 :under
	objc_msgSend [layout sel_addAttribute NSUnderlineStyleAttributeName under pos len]
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	/local
		strike [integer!]
][
	strike: 1
	strike: CFNumberCreate 0 15 :strike
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
		desc	[integer!]
		font	[integer!]
		str		[integer!]
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
		desc	[integer!]
		font	[integer!]
		x		[integer!]
		y		[integer!]
		temp	[CGPoint!]
][
	y: 0
	temp: as CGPoint! :y
	temp/x: as float32! size
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
		layout	[integer!]
		ts		[integer!]
		tc		[integer!]
		pos		[red-pair!]
		int		[red-integer!]
		values	[red-value!]
		y		[float32!]
		x		[float32!]
		cnt		[integer!]
		yy		[integer!]
		xx		[integer!]
		_w		[integer!]
		_h		[integer!]
		_y		[integer!]
		_x		[integer!]
		frame	[NSRect!]
		pt		[CGPoint!]
		idx		[integer!]
		len		[integer!]
		method	[integer!]
		saved	[int-ptr!]
		last?	[logic!]
][
	int: as red-integer! block/rs-head state
	layout: int/value
	int: int + 1
	tc: int/value
	int: int + 1
	ts: int/value
	as red-value! switch type [
		TBOX_METRICS_OFFSET?
		TBOX_METRICS_LINE_HEIGHT [
			xx: 0 _x: 0
			;int: as red-integer! arg0
			idx: (as-integer arg0) - 1
			len: objc_msgSend [ts sel_getUid "length"]
			if idx < 0 [idx: 0]
			last?: idx >= len
			if last? [idx: len - 1]

			frame: as NSRect! :_x
			method: sel_getUid "lineFragmentUsedRectForGlyphAtIndex:effectiveRange:"
			saved: system/stack/align
			push 0 push 0 push 0
			push 0 push idx
			push method push layout push frame
			objc_msgSend_stret 5
			system/stack/top: saved
			either type = TBOX_METRICS_LINE_HEIGHT [
				integer/push as-integer frame/h
			][
				pt: as CGPoint! :_x
				either last? [
					pt/x: frame/x + frame/w
				][
					_x: objc_msgSend [layout sel_getUid "locationForGlyphAtIndex:" idx]
				]
				x: pt/x + as float32! 0.5
				pair/push as-integer x as-integer pt/y
			]
		]
		TBOX_METRICS_INDEX? [
			y: as float32! 0.0
			pos: as red-pair! arg0
			xx: 0
			pt: as CGPoint! :xx
			pt/x: as float32! pos/x
			pt/y: as float32! pos/y
			idx: objc_msgSend [
				layout
				sel_getUid "characterIndexForPoint:inTextContainer:fractionOfDistanceBetweenInsertionPoints:"
				pt/x pt/y tc :y
			]
			if y > as float32! 0.5 [idx: idx + 1]
			integer/push idx + 1
		]
		default [
			idx: objc_msgSend [layout sel_getUid "glyphRangeForTextContainer:" tc]
			len: system/cpu/edx
			xx: 0 _x: 0
			frame: as NSRect! :_x
			method: sel_getUid "boundingRectForGlyphRange:inTextContainer:"
			saved: system/stack/align
			push 0 push 0
			push tc push len push idx
			push method push layout push frame
			objc_msgSend_stret 6
			system/stack/top: saved
			values: object/get-values as red-object! arg0
			integer/make-at values + TBOX_OBJ_WIDTH as-integer frame/w
			integer/make-at values + TBOX_OBJ_HEIGHT as-integer frame/h

			method: sel_getUid "lineFragmentRectForGlyphAtIndex:effectiveRange:"
			cnt: 0
			idx: 0
			yy: 0
			while [idx < len][
				cnt: cnt + 1
				saved: system/stack/align
				push 0 push 0 push 0
				push :xx push idx
				push method push layout push frame
				objc_msgSend_stret 5
				system/stack/top: saved
				idx: xx + yy
			]
			if zero? cnt [cnt: 1]
			integer/make-at values + TBOX_OBJ_LINE_COUNT cnt
		]
	]
]

OS-text-box-layout: func [
	box		[red-object!]
	target	[int-ptr!]
	catch?	[logic!]
	return: [integer!]
	/local
		values	[red-value!]
		state	[red-block!]
		int		[red-integer!]
		styles	[red-block!]
		size	[red-pair!]
		layout	[integer!]
		ts		[integer!]
		tc		[integer!]
		str		[integer!]
		w		[integer!]
		h		[integer!]
		sz		[NSSize!]
		attrs	[integer!]
		nsfont	[integer!]
		clr		[integer!]
		para	[integer!]
		cached?	[logic!]
][
	values: object/get-values box

	str: to-NSString as red-string! values + TBOX_OBJ_TEXT
	state: as red-block! values + TBOX_OBJ_STATE
	size: as red-pair! values + TBOX_OBJ_SIZE
	nsfont: as-integer get-font null as red-object! values + TBOX_OBJ_FONT
	cached?: TYPE_OF(state) = TYPE_BLOCK

	h: 7CF0BDC2h w: 7CF0BDC2h
	sz: as NSSize! :h

	either cached? [
		int: as red-integer! block/rs-head state
		layout: int/value
		int: int + 1 tc: int/value
		int: int + 1 ts: int/value
		int: int + 1 para: int/value
	][
		tc: objc_msgSend [
			objc_msgSend [objc_getClass "NSTextContainer" sel_alloc]
			sel_getUid "initWithSize:" 7CF0BDC2h 7CF0BDC2h
		]
		objc_msgSend [tc sel_getUid "setLineFragmentPadding:" 0]

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
		h: objc_msgSend [nsfont sel_getUid "advancementForGlyph:" 32]			;-- #" "
		objc_msgSend [para sel_getUid "setDefaultTabInterval:" sz/w * (as float32! 4.0)]
		objc_msgSend [para sel_getUid "setTabStops:" objc_msgSend [objc_getClass "NSArray" sel_getUid "array"]]

		h: 7CF0BDC2h
		block/make-at state 4
		integer/make-in state layout
		integer/make-in state tc
		integer/make-in state ts
		integer/make-in state para
	]

	;@@ set para: as red-object! values + TBOX_OBJ_PARA

	if TYPE_OF(size) = TYPE_PAIR [
		unless zero? size/x [sz/w: as float32! size/x]
		unless zero? size/y [sz/h: as float32! size/y]
	]
	objc_msgSend [tc sel_getUid "setSize:" sz/w sz/h]

	objc_msgSend [ts sel_getUid "beginEditing"]

	if cached? [
		w: objc_msgSend [ts sel_getUid "length"]
		objc_msgSend [ts sel_getUid "deleteCharactersInRange:" 0 w]
		objc_msgSend [ts sel_getUid "replaceCharactersInRange:withString:" 0 0 str]
	]

	attrs: objc_msgSend [
		objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
		sel_getUid "initWithObjectsAndKeys:"
		nsfont NSFontAttributeName
		para NSParagraphStyleAttributeName
		0
	]
	w: objc_msgSend [str sel_getUid "length"]
	objc_msgSend [ts sel_getUid "setAttributes:range:" attrs 0 w]
	objc_msgSend [attrs sel_release]

	styles: as red-block! values + TBOX_OBJ_STYLES
	if all [
		TYPE_OF(styles) = TYPE_BLOCK
		2 < block/rs-length? styles
	][
		parse-text-styles as handle! nsfont as handle! ts styles catch?
	]

	objc_msgSend [ts sel_getUid "endEditing"]
	layout
]