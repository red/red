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
	;brush: select-brush dc + 1 color
	;if zero? brush [
	;	this: as this! dc/value
	;	rt: as ID2D1HwndRenderTarget this/vtbl
	;	rt/CreateSolidColorBrush this to-dx-color color null null :brush
	;	put-brush dc + 1 color brush
	;]

	;this: as this! layout
	;dl: as IDWriteTextLayout this/vtbl
	;dl/SetDrawingEffect this as this! brush pos len
]

OS-text-box-background: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		cache	[red-vector!]
		brush	[integer!]
][
	;cache: as red-vector! dc + 3
	;if TYPE_OF(cache) <> TYPE_VECTOR [
	;	vector/make-at as red-value! cache 128 TYPE_INTEGER 4
	;]
	;brush: select-brush dc + 1 color
	;if zero? brush [
	;	this: as this! dc/value
	;	rt: as ID2D1HwndRenderTarget this/vtbl
	;	rt/CreateSolidColorBrush this to-dx-color color null null :brush
	;	put-brush dc + 1 color brush
	;]
	;vector/rs-append-int cache pos
	;vector/rs-append-int cache len
	;vector/rs-append-int cache brush
]

OS-text-box-weight: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	weight	[integer!]
][
]

OS-text-box-italic: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
][
]

OS-text-box-underline: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
][
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
][
	;n: -1
	;this: as this! layout
	;dl: as IDWriteTextLayout this/vtbl
	;dl/SetFontFamilyName this unicode/to-utf16-len name :n yes pos len
]

OS-text-box-font-size: func [
	nsfont	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
][
]

OS-text-box-metrics: func [
	state	[red-block!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
][
	as red-value! none-value
	;as red-value! switch type [
	;	TBOX_METRICS_OFFSET? [
	;		x: as float32! 0.0 y: as float32! 0.0
	;		;int: as red-integer! arg0
	;	]
	;	TBOX_METRICS_INDEX? [
	;		pos: as red-pair! arg0
	;		x: as float32! pos/x
	;		y: as float32! pos/y
	;	]
	;	TBOX_METRICS_LINE_HEIGHT [
	;		lineCount: 0
	;		dl/GetLineMetrics this null 0 :lineCount
	;		if lineCount > max-line-cnt [
	;			max-line-cnt: lineCount + 1
	;			line-metrics: as DWRITE_LINE_METRICS realloc
	;				as byte-ptr! line-metrics
	;				lineCount + 1 * size? DWRITE_HIT_TEST_METRICS
	;		]
	;		lineCount: 0
	;		dl/GetLineMetrics this line-metrics max-line-cnt :lineCount
	;		lm: line-metrics
	;		hr: as-integer arg0
	;		while [
	;			hr: hr - lm/length
	;			lineCount: lineCount - 1
	;			all [hr > 0 lineCount > 0]
	;		][
	;			lm: lm + 1
	;		]
	;		integer/push as-integer lm/height
	;	]
	;	default [
	;		metrics: as DWRITE_TEXT_METRICS :left
	;		hr: dl/GetMetrics this metrics
	;		#if debug? = yes [if hr <> 0 [log-error hr]]

	;		values: object/get-values as red-object! arg0
	;		integer/make-at values + TBOX_OBJ_WIDTH as-integer metrics/width
	;		integer/make-at values + TBOX_OBJ_HEIGHT as-integer metrics/height
	;		integer/make-at values + TBOX_OBJ_LINE_COUNT metrics/lineCount
	;	]
	;]
]

OS-text-box-layout: func [
	box		[red-object!]
	target	[int-ptr!]
	ft-clr	[integer!]
	catch?	[logic!]
	return: [integer!]
	/local
		values	[red-value!]
		state	[red-block!]
		int		[red-integer!]
		styles	[red-block!]
		size	[red-pair!]
		bool	[red-logic!]
		layout	[integer!]
		ts		[integer!]
		tc		[integer!]
		w		[integer!]
		h		[integer!]
		para	[integer!]
		cached?	[logic!]

		font	[handle!]
		clr		[integer!]
		text	[red-string!]
		len     [integer!]
		str		[c-string!]
][
	values: object/get-values box
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;if null? target [
	;	hWnd: get-face-handle as red-object! values + TBOX_OBJ_TARGET
	;	target: get-hwnd-render-target hWnd
	;]

	;state: as red-block! values + TBOX_OBJ_STATE
	;either TYPE_OF(state) = TYPE_BLOCK [
	;	int: as red-integer! block/rs-head state	;-- release previous text layout
	;	layout: as this! int/value
	;	COM_SAFE_RELEASE(IUnk layout)
	;	int: int + 1
	;	fmt: as this! int/value
	;][
	;	fixed?: as red-logic! values + TBOX_OBJ_FIXED?
	;	fmt: as this! create-text-format as red-object! values + TBOX_OBJ_FONT
	;	if fixed?/value [set-line-spacing fmt]
	;	block/make-at state 2
	;	none/make-in state							;-- 1: text layout
	;	integer/make-in state as-integer fmt		;-- 2: text format
	;]

	;set-text-format fmt as red-object! values + TBOX_OBJ_PARA

	;str: as red-string! values + TBOX_OBJ_TEXT
	;size: as red-pair! values + TBOX_OBJ_SIZE
	;either TYPE_OF(size) = TYPE_PAIR [
	;	w: size/x h: size/y
	;][
	;	w: 0 h: 0
	;]
	;layout: create-text-layout str fmt w h
	;integer/make-at block/rs-head state as-integer layout

	;styles: as red-block! values + TBOX_OBJ_STYLES
	;if all [
	;	TYPE_OF(styles) = TYPE_BLOCK
	;	2 < block/rs-length? styles
	;][
	;	parse-text-styles target as handle! layout styles catch?
	;]
	;layout
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	text: as red-string! values + FACE_OBJ_TEXT
	len: -1
	str: unicode/to-utf8 text :len
	state: as red-block! values + FACE_OBJ_EXT3
	size: as red-pair! values + FACE_OBJ_SIZE
	font: get-font null as red-object! values + FACE_OBJ_FONT
	cached?: TYPE_OF(state) = TYPE_BLOCK

	; h: 7CF0BDC2h w: 7CF0BDC2h
	; sz: as NSSize! :h

	; either cached? [
	; 	int: as red-integer! block/rs-head state
	; 	layout: int/value
	; 	int: int + 1 tc: int/value
	; 	int: int + 1 ts: int/value
	; 	int: int + 1 para: int/value
	; 	bool: as red-logic! int + 2
	; 	bool/value: false
	; ][
	; 	tc: objc_msgSend [
	; 		objc_msgSend [objc_getClass "NSTextContainer" sel_alloc]
	; 		sel_getUid "initWithSize:" 7CF0BDC2h 7CF0BDC2h
	; 	]
	; 	objc_msgSend [tc sel_getUid "setLineFragmentPadding:" 0]

	; 	ts: objc_msgSend [
	; 		objc_msgSend [objc_getClass "NSTextStorage" sel_alloc]
	; 		sel_getUid "initWithString:" str
	; 	]

	; 	layout: objc_msgSend [objc_msgSend [objc_getClass "RedLayoutManager" sel_alloc] sel_init]
	; 	objc_msgSend [layout sel_getUid "addTextContainer:" tc]
	; 	objc_msgSend [tc sel_release]
	; 	objc_msgSend [ts sel_getUid "addLayoutManager:" layout]
	; 	objc_msgSend [layout sel_release]
	; 	objc_msgSend [layout sel_getUid "setDelegate:" layout]
	; 	objc_setAssociatedObject layout RedAttachedWidgetKey nsfont OBJC_ASSOCIATION_ASSIGN

	; 	para: objc_msgSend [objc_getClass "NSParagraphStyle" sel_getUid "defaultParagraphStyle"]
	; 	para: objc_msgSend [para sel_getUid "mutableCopy"]
	; 	h: objc_msgSend [nsfont sel_getUid "advancementForGlyph:" 32]			;-- #" "
	; 	objc_msgSend [para sel_getUid "setDefaultTabInterval:" sz/w * (as float32! 4.0)]
	; 	objc_msgSend [para sel_getUid "setTabStops:" objc_msgSend [objc_getClass "NSArray" sel_getUid "array"]]

	; 	h: 7CF0BDC2h
	; 	block/make-at state 6
	; 	integer/make-in state layout
	; 	integer/make-in state tc
	; 	integer/make-in state ts
	; 	integer/make-in state para
	; 	none/make-in state
	; 	logic/make-in state false
	; ]

	; copy-cell values + FACE_OBJ_TEXT (block/rs-head state) + 4

	; ;@@ set para: as red-object! values + FACE_OBJ_PARA

	; if TYPE_OF(size) = TYPE_PAIR [
	; 	unless zero? size/x [sz/w: as float32! size/x]
	; 	unless zero? size/y [sz/h: as float32! size/y]
	; ]
	; objc_msgSend [tc sel_getUid "setSize:" sz/w sz/h]

	; objc_msgSend [ts sel_getUid "beginEditing"]

	; if cached? [
	; 	w: objc_msgSend [ts sel_length]
	; 	objc_msgSend [ts sel_getUid "deleteCharactersInRange:" 0 w]
	; 	objc_msgSend [ts sel_getUid "replaceCharactersInRange:withString:" 0 0 str]
	; ]

	; attrs: objc_msgSend [
	; 	objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
	; 	sel_getUid "initWithObjectsAndKeys:"
	; 	nsfont NSFontAttributeName
	; 	para NSParagraphStyleAttributeName
	; 	nscolor NSForegroundColorAttributeName
	; 	0
	; ]
	; w: objc_msgSend [str sel_length]
	; objc_msgSend [ts sel_getUid "setAttributes:range:" attrs 0 w]
	; objc_msgSend [attrs sel_release]

	; styles: as red-block! values + FACE_OBJ_DATA
	; if all [
	; 	TYPE_OF(styles) = TYPE_BLOCK
	; 	1 < block/rs-length? styles
	; ][
	; 	parse-text-styles as handle! nsfont as handle! ts styles w catch?
	; ]

	; objc_msgSend [ts sel_getUid "endEditing"]
	; layout
	0
]