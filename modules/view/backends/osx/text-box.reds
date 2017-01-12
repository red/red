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
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
][
]

OS-text-box-metrics: func [
	layout	[handle!]
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
][
	values: object/get-values box

	state: as red-block! values + TBOX_OBJ_STATE
	either TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		layout: int/value
	][
		str: to-NSString as red-string! values + TBOX_OBJ_TEXT
		size: as red-pair! values + TBOX_OBJ_SIZE
		h: 0
		sz: as NSSize! :h
		sz/w: as float32! 1e37 sz/h: as float32! 1e37
		if TYPE_OF(size) = TYPE_PAIR [
			unless zero? size/x [sz/w: as float32! size/x]
			unless zero? size/y [sz/h: as float32! size/y]
		]
		ts: objc_msgSend [
			objc_msgSend [objc_getClass "NSTextStorage" sel_alloc]
			sel_getUid "initWithString:" str
		]

		tc: objc_msgSend [
			objc_msgSend [objc_getClass "NSTextContainer" sel_alloc]
			sel_getUid "initWithSize:" sz/w sz/h
		]
		layout: objc_msgSend [objc_msgSend [objc_getClass "NSLayoutManager" sel_alloc] sel_init]

		objc_msgSend [layout sel_getUid "addTextContainer:" tc]
		objc_msgSend [tc sel_release]
		objc_msgSend [ts sel_getUid "addLayoutManager:" layout]
		objc_msgSend [layout sel_release]

		block/make-at state 3
		integer/make-in state layout
		integer/make-in state tc
		integer/make-in state ts
	]

	;@@ set para: as red-object! values + TBOX_OBJ_PARA

	styles: as red-block! values + TBOX_OBJ_STYLES
	if all [
		TYPE_OF(styles) = TYPE_BLOCK
		2 < block/rs-length? styles
	][
		parse-text-styles target as handle! layout styles catch?
	]
	layout
]