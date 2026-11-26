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
#define TBOX_METRICS_OFFSET_LOWER	6

max-line-cnt:  0
tb-ext-type:  -1

release-text-obj: func [							;-- GC destructor for cached rich-text objects
	obj [int-ptr!]
][
	objc_msgSend [as-integer obj sel_release]
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
		str		[red-string!]
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
		rc		[NSRect! value]
		lp		[CGPoint! value]
		cg-pt	[CGPoint!]
		idx		[integer!]
		len		[integer!]
		c16		[integer!]
		n		[integer!]
		m		[integer!]
		k		[integer!]
		j		[integer!]
		e		[integer!]
		ck		[integer!]
		cj		[integer!]
		buf		[int-ptr!]
		ip		[int-ptr!]
		fp		[float32-ptr!]
		method	[integer!]
		saved	[int-ptr!]
		last?	[logic!]
		blank?	[logic!]
		pt		[red-point2D!]
][
	int: as red-integer! block/rs-head state
	layout: int/value
	int: int + 1
	tc: int/value
	int: int + 1
	ts: int/value
	as red-value! switch type [
		TBOX_METRICS_OFFSET?
		TBOX_METRICS_OFFSET_LOWER
		TBOX_METRICS_LINE_HEIGHT [
			str: as red-string! int + 2
			xx: 0 _x: 0
			int: as red-integer! arg0
			idx: int/value - 1
			len: string/rs-length? str
			if idx < 0 [idx: 0]
			last?: idx >= len
			if last? [idx: len - 1]

			frame: as NSRect! :_x
			blank?: no
			either zero? len [								;-- empty text: one line of the face's font
				frame/y: F32_0
				frame/h: set-line-spacing 0 0 layout 0 F32_0 F32_0 F32_0 F32_0
				cnt: objc_getAssociatedObject layout RedAttachedWidgetKey
				frame/h: frame/h + objc_msgSend_f32 [layout sel_getUid "defaultLineHeightForFont:" cnt]
			][
				c16: adjust-index str 0 idx 1					;-- UTF-16 position
				idx: objc_msgSend [layout sel_getUid "glyphIndexForCharacterAtIndex:" c16]
				method: sel_getUid "lineFragmentUsedRectForGlyphAtIndex:effectiveRange:"
				saved: system/stack/align
				push 0 push 0 push 0
				push 0 push idx
				push method push layout push frame
				objc_msgSend_stret 5
				system/stack/top: saved
				if last? [										;-- past the end: on the line AppKit adds after a final line break
					objc_msgSend [layout sel_getUid "ensureLayoutForTextContainer:" tc]
					cnt: objc_msgSend [layout sel_getUid "extraLineFragmentTextContainer"]
					blank?: cnt <> 0
					if blank? [
						rc: objc_msgSend_rect [layout sel_getUid "extraLineFragmentUsedRect"]
						frame/x: rc/x
						frame/y: rc/y
						frame/h: set-line-spacing 0 0 layout 0 F32_0 F32_0 F32_0 F32_0
						frame/h: frame/h + rc/h
					]
				]
			]
			either type = TBOX_METRICS_LINE_HEIGHT [
				float/push as float! frame/h
			][
				cg-pt: as CGPoint! :_x
				x: frame/x										;-- trailing edge
				y: x											;-- leading edge
				n: 0
				if all [len > 0 not blank?][
					method: sel_getUid "getLineFragmentInsertionPointsForCharacterAtIndex:alternatePositions:inDisplayOrder:positions:characterIndexes:"
					n: objc_msgSend [layout method c16 0 0 0 0]	;-- AppKit's carets on the line, in text order (none if not laid out)
				]
				if n > 0 [
					either n <= 4096 [buf: system/stack/allocate n * 2][buf: allocate-virtual n * 8 no]
					objc_msgSend [layout method c16 0 0 buf buf + n]
					fp: as float32-ptr! buf
					ip: buf + n
					k: 1
					j: 2
					while [all [j <= n ip/j <= c16]][			;-- k: the caret before the character, j: the one after it
						k: j
						j: j + 1
					]
					y: fp/k
					ck: ip/k
					x: y
					cj: -1
					if j <= n [
						x: fp/j
						cj: ip/j
					]
					if n > 4096 [free-virtual buf]
					m: objc_msgSend [layout method c16 1 0 0 0]	;-- where the direction changes, AppKit has a second caret
					if m > 0 [
						lp: objc_msgSend_pt [layout sel_getUid "locationForGlyphAtIndex:" idx]	;-- the character's left edge
						cnt: 0
						objc_msgSend [layout sel_getUid "getGlyphsInRange:glyphs:properties:characterIndexes:bidiLevels:" idx 1 0 0 0 :cnt]
						either m <= 4096 [buf: system/stack/allocate m * 2][buf: allocate-virtual m * 8 no]
						objc_msgSend [layout method c16 1 0 buf buf + m]
						fp: as float32-ptr! buf
						ip: buf + m
						e: 1
						while [e <= m][							;-- the character's edges: its left one, and the nearest caret on its right
							if ip/e = ck [
								either cnt and 1 = 0 [y: lp/x][
									if all [fp/e > lp/x any [y <= lp/x fp/e < y]][y: fp/e]
								]
							]
							if ip/e = cj [
								either cnt and 1 = 1 [x: lp/x][
									if all [fp/e > lp/x any [x <= lp/x fp/e < x]][x: fp/e]
								]
							]
							e: e + 1
						]
						if m > 4096 [free-virtual buf]
					]
					if last? [y: x]								;-- past the end: after the last character
				]
				if type = TBOX_METRICS_OFFSET_LOWER [			;-- lower end: the trailing edge, at the line's bottom
					y: x
					cg-pt/y: cg-pt/y + frame/h
				]
				cg-pt/x: y
				point2D/push cg-pt/x cg-pt/y
			]
		]
		TBOX_METRICS_INDEX?
		TBOX_METRICS_CHAR_INDEX? [
			y: as float32! 0.0
			pos: as red-pair! arg0
			xx: 0
			cg-pt: as CGPoint! :xx
			GET_PAIR_XY(pos cg-pt/x cg-pt/y)
			idx: objc_msgSend [
				layout
				sel_getUid "characterIndexForPoint:inTextContainer:fractionOfDistanceBetweenInsertionPoints:"
				cg-pt/x cg-pt/y tc :y
			]
			str: as red-string! int + 2
			idx: adjust-index str 0 idx -1						;-- UTF-16 position to Red position
			if all [type = TBOX_METRICS_INDEX? y > as float32! 0.5][idx: idx + 1]
			integer/push idx + 1
		]
		TBOX_METRICS_SIZE [
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
			point2D/push frame/w frame/h
		]
		TBOX_METRICS_LINE_COUNT [
			idx: objc_msgSend [layout sel_getUid "glyphRangeForTextContainer:" tc]
			len: system/cpu/edx
			xx: 0 _x: 0
			frame: as NSRect! :_x
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
			integer/push cnt
		]
		default [0]
	]
]

OS-text-box-layout: func [
	box			[red-object!]
	target		[int-ptr!]
	nscolor		[integer!]	
	catch?		[logic!]
	return:		[integer!]
	/local
		values	[red-value!]
		state	[red-block!]
		int		[red-integer!]
		styles	[red-block!]
		size	[red-pair!]
		font	[red-object!]
		fcolor	[red-tuple!]
		bool	[red-logic!]
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
		pt		[red-point2D!]
		sx sy	[float32!]
		hndl	[red-handle!]
][
	values: object/get-values box

	str: to-NSString as red-string! values + FACE_OBJ_TEXT
	state: get-text-box-state box						;-- null: not kept, the caller frees the storage
	size: as red-pair! values + FACE_OBJ_SIZE
	font: as red-object! values + FACE_OBJ_FONT
	nsfont: as-integer get-font null font
	cached?: all [state <> null TYPE_OF(state) = TYPE_BLOCK]

	h: 7CF0BDC2h w: 7CF0BDC2h
	sz: as NSSize! :h

	either cached? [
		int: as red-integer! block/rs-head state
		layout: int/value
		int: int + 1 tc: int/value
		int: int + 1 ts: int/value
		int: int + 1 para: int/value
		bool: as red-logic! int + 2
		bool/value: false
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

		para: objc_msgSend [objc_getClass "NSParagraphStyle" sel_getUid "defaultParagraphStyle"]
		para: objc_msgSend [para sel_getUid "mutableCopy"]
		h: objc_msgSend [nsfont sel_getUid "advancementForGlyph:" 32]			;-- #" "
		objc_msgSend [para sel_getUid "setDefaultTabInterval:" sz/w * (as float32! 4.0)]
		objc_msgSend [para sel_getUid "setTabStops:" objc_msgSend [objc_getClass "NSArray" sel_getUid "array"]]

		h: 7CF0BDC2h
		if state <> null [
			block/make-at state 6
			integer/make-in state layout
			integer/make-in state tc
			hndl: handle/make-in state ts handle/CLASS_RICHTEXT
			hndl/extID: externals/store as int-ptr! ts tb-ext-type		;-- GC releases both with the face
			hndl: handle/make-in state para handle/CLASS_RICHTEXT
			hndl/extID: externals/store as int-ptr! para tb-ext-type
			none/make-in state
			logic/make-in state false
		]
	]
	objc_setAssociatedObject layout RedAttachedWidgetKey nsfont OBJC_ASSOCIATION_ASSIGN	;-- the current font, for the line spacing

	if state <> null [copy-cell values + FACE_OBJ_TEXT (block/rs-head state) + 4]

	;@@ set para: as red-object! values + FACE_OBJ_PARA

	if ANY_COORD?(size) [
		GET_PAIR_XY(size sx sy)
		if sx <> F32_0 [sz/w: sx]
		if sy <> F32_0 [sz/h: sy]
	]
	objc_msgSend [tc sel_getUid "setSize:" sz/w sz/h]

	objc_msgSend [ts sel_getUid "beginEditing"]

	if cached? [
		w: objc_msgSend [ts sel_length]
		objc_msgSend [ts sel_getUid "deleteCharactersInRange:" 0 w]
		objc_msgSend [ts sel_getUid "replaceCharactersInRange:withString:" 0 0 str]
	]

	attrs: objc_msgSend [
		objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
		sel_getUid "initWithObjectsAndKeys:"
		nsfont NSFontAttributeName
		para NSParagraphStyleAttributeName
		nscolor NSForegroundColorAttributeName
		0
	]
	w: objc_msgSend [str sel_length]
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
		catch RED_THROWN_ERROR [
			parse-text-styles as handle! nsfont as handle! ts styles as red-string! values + FACE_OBJ_TEXT catch?
		]
	]

	objc_msgSend [ts sel_getUid "endEditing"]
	if null? state [objc_msgSend [para sel_release]]	;-- not kept: the storage's attributes hold it
	if system/thrown <> 0 [							;-- a Draw error in the data, the storage closed:
		either null? state [objc_msgSend [ts sel_release]][	;-- the layout is redone at its next use
			bool: as red-logic! (block/rs-tail state) - 1
			bool/value: true
		]
		re-throw
	]
	layout
]
