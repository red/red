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

hidden-hwnd:  as handle! 0
line-metrics: as DWRITE_LINE_METRICS 0
max-line-cnt: 0

OS-text-box-color: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		dl		[IDWriteTextLayout]
		brush	[integer!]
][
	brush: select-brush dc + 1 color
	if zero? brush [
		this: as this! dc/value
		rt: as ID2D1HwndRenderTarget this/vtbl
		rt/CreateSolidColorBrush this to-dx-color color null null :brush
		put-brush dc + 1 color brush
	]

	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetDrawingEffect this as this! brush pos len
]

OS-text-box-background: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		cache	[red-vector!]
		brush	[integer!]
][
	cache: as red-vector! dc + 3
	if TYPE_OF(cache) <> TYPE_VECTOR [
		vector/make-at as red-value! cache 128 TYPE_INTEGER 4
	]
	brush: select-brush dc + 1 color
	if zero? brush [
		this: as this! dc/value
		rt: as ID2D1HwndRenderTarget this/vtbl
		rt/CreateSolidColorBrush this to-dx-color color null null :brush
		put-brush dc + 1 color brush
	]
	vector/rs-append-int cache pos
	vector/rs-append-int cache len
	vector/rs-append-int cache brush
]

OS-text-box-weight: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	weight	[integer!]
	/local
		this	[this!]
		dl		[IDWriteTextLayout]
][
	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetFontWeight this weight pos len
]

OS-text-box-italic: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	/local
		this	[this!]
		dl		[IDWriteTextLayout]
][
	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetFontStyle this 2 pos len
]

OS-text-box-underline: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
	/local
		this	[this!]
		dl		[IDWriteTextLayout]
][
	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetUnderline this yes pos len
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
	/local
		this	[this!]
		dl		[IDWriteTextLayout]
][
	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetStrikethrough this yes pos len
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
	font	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	name	[red-string!]
	/local
		this	[this!]
		dl		[IDWriteTextLayout]
		n		[integer!]
][
	n: -1
	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetFontFamilyName this unicode/to-utf16-len name :n yes pos len
]

OS-text-box-font-size: func [
	font	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
	/local
		this [this!]
		dl	 [IDWriteTextLayout]
][
	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetFontSize this ConvertPointSizeToDIP(size) pos len
]

OS-text-box-metrics: func [
	state	[red-block!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
	/local
		layout			[handle!]
		this			[this!]
		dl				[IDWriteTextLayout]
		lineCount		[integer!]
		maxBidiDepth	[integer!]
		layoutHeight	[float32!]
		layoutWidth		[float32!]
		height			[float32!]
		widthTrailing	[float32!]
		width			[float32!]
		top				[float32!]
		left			[integer!]
		lm				[DWRITE_LINE_METRICS]
		metrics			[DWRITE_TEXT_METRICS]
		hit				[DWRITE_HIT_TEST_METRICS]
		x				[float32!]
		y				[float32!]
		trailing?		[integer!]
		inside?			[integer!]
		blk				[red-block!]
		int				[red-integer!]
		pos				[red-pair!]
		values			[red-value!]
		hr				[integer!]
][
	int: as red-integer! block/rs-head state
	layout: as handle! int/value
	left: 0
	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl

	as red-value! switch type [
		TBOX_METRICS_OFFSET? [
			x: as float32! 0.0 y: as float32! 0.0
			;int: as red-integer! arg0
			hr: as-integer arg0
			hit: as DWRITE_HIT_TEST_METRICS :left
			dl/HitTestTextPosition this hr - 1 no :x :y hit
			if y < as float32! 0.0 [y: as float32! 0.0]
			pair/push as-integer x + as float32! 0.5 as-integer y
		]
		TBOX_METRICS_INDEX? [
			pos: as red-pair! arg0
			x: as float32! pos/x
			y: as float32! pos/y
			trailing?: 0
			inside?: 0
			hit: as DWRITE_HIT_TEST_METRICS :left
			dl/HitTestPoint this x y :trailing? :inside? hit
			if 0 <> trailing? [left: left + 1]
			integer/push left + 1
		]
		TBOX_METRICS_LINE_HEIGHT [
			lineCount: 0
			dl/GetLineMetrics this null 0 :lineCount
			if lineCount > max-line-cnt [
				max-line-cnt: lineCount + 1
				line-metrics: as DWRITE_LINE_METRICS realloc
					as byte-ptr! line-metrics
					lineCount + 1 * size? DWRITE_HIT_TEST_METRICS
			]
			lineCount: 0
			dl/GetLineMetrics this line-metrics max-line-cnt :lineCount
			lm: line-metrics
			hr: as-integer arg0
			while [
				hr: hr - lm/length
				lineCount: lineCount - 1
				all [hr > 0 lineCount > 0]
			][
				lm: lm + 1
			]
			integer/push as-integer lm/height
		]
		default [
			metrics: as DWRITE_TEXT_METRICS :left
			hr: dl/GetMetrics this metrics

			values: object/get-values as red-object! arg0
			integer/make-at values + TBOX_OBJ_WIDTH as-integer metrics/width
			integer/make-at values + TBOX_OBJ_HEIGHT as-integer metrics/height
			integer/make-at values + TBOX_OBJ_LINE_COUNT metrics/lineCount
		]
	]
]

OS-text-box-layout: func [
	box		[red-object!]
	target	[int-ptr!]
	catch?	[logic!]
	return: [this!]
	/local
		IUnk	[IUnknown]
		hWnd	[handle!]
		values	[red-value!]
		str		[red-string!]
		size	[red-pair!]
		int		[red-integer!]
		fixed?	[red-logic!]
		state	[red-block!]
		styles	[red-block!]
		vec		[red-vector!]
		obj		[red-object!]
		w		[integer!]
		h		[integer!]
		fmt		[this!]
		layout	[this!]
][
	values: object/get-values box
	if null? target [
		hWnd: null
		obj: as red-object! values + TBOX_OBJ_TARGET
		if TYPE_OF(obj) = TYPE_OBJECT [
			hWnd: face-handle? obj
		]
		if null? hWnd [
			if null? hidden-hwnd [
				hidden-hwnd: CreateWindowEx WS_EX_TOOLWINDOW #u16 "RedBaseInternal" null WS_POPUP 0 0 2 2 null null hInstance null
			]
			hWnd: hidden-hwnd
		]
		target: get-hwnd-render-target hWnd
	]

	vec: as red-vector! target + 3
	if TYPE_OF(vec) = TYPE_VECTOR [vector/rs-clear vec]

	state: as red-block! values + TBOX_OBJ_STATE
	either TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state	;-- release previous text layout
		layout: as this! int/value
		COM_SAFE_RELEASE(IUnk layout)
		int: int + 1
		fmt: as this! int/value
	][
		fixed?: as red-logic! values + TBOX_OBJ_FIXED?
		fmt: as this! create-text-format as red-object! values + TBOX_OBJ_FONT
		if fixed?/value [set-line-spacing fmt]
		block/make-at state 2
		none/make-in state							;-- 1: text layout
		integer/make-in state as-integer fmt		;-- 2: text format
	]

	set-text-format fmt as red-object! values + TBOX_OBJ_PARA

	str: as red-string! values + TBOX_OBJ_TEXT
	size: as red-pair! values + TBOX_OBJ_SIZE
	either TYPE_OF(size) = TYPE_PAIR [
		w: size/x h: size/y
	][
		w: 0 h: 0
	]
	layout: create-text-layout str fmt w h
	integer/make-at block/rs-head state as-integer layout

	styles: as red-block! values + TBOX_OBJ_STYLES
	if all [
		TYPE_OF(styles) = TYPE_BLOCK
		2 < block/rs-length? styles
	][
		parse-text-styles target as handle! layout styles catch?
	]
	layout
]

txt-box-draw-background: func [
	target	[int-ptr!]
	pos		[red-pair!]
	layout	[this!]
	/local
		this		[this!]
		rt			[ID2D1HwndRenderTarget]
		styles		[red-vector!]
		line-cnt	[integer!]
		dl			[IDWriteTextLayout]
		hits		[DWRITE_HIT_TEST_METRICS]
		hit			[DWRITE_HIT_TEST_METRICS]
		s			[series!]
		p			[int-ptr!]
		end			[int-ptr!]
		x			[float32!]
		y			[float32!]
		height		[integer!]
		width		[integer!]
		top			[integer!]
		left		[integer!]
		rc			[D2D_RECT_F]
][
	styles: as red-vector! target + 3
	if any [
		TYPE_OF(styles) <> TYPE_VECTOR
		zero? vector/rs-length? styles
	][exit]

	this: as this! target/value
	rt: as ID2D1HwndRenderTarget this/vtbl
	dl: as IDWriteTextLayout layout/vtbl

	line-cnt: 0
	dl/GetLineMetrics layout null 0 :line-cnt
	if line-cnt > max-line-cnt [
		max-line-cnt: line-cnt + 1
		line-metrics: as DWRITE_LINE_METRICS realloc
			as byte-ptr! line-metrics
			line-cnt + 1 * size? DWRITE_HIT_TEST_METRICS
	]
	hits: as DWRITE_HIT_TEST_METRICS line-metrics

	left: 0
	rc: as D2D_RECT_F :left
	x: as float32! pos/x
	y: as float32! pos/y
	s: GET_BUFFER(styles)
	p: (as int-ptr! s/offset) + styles/head
	end: as int-ptr! s/tail
	while [p < end][
		dl/HitTestTextRange layout p/1 p/2 x y hits max-line-cnt :line-cnt
		hit: hits
		loop line-cnt [
			left: as-integer hit/left + as float32! 0.5
			top: as-integer hit/top + as float32! 0.5
			width: as-integer hit/width + as float32! 0.5
			height: as-integer hit/height + as float32! 0.5
			rc/right: as float32! left + width
			rc/bottom: as float32! top + height
			rc/top: as float32! top
			rc/left: as float32! left
			rt/FillRectangle this rc p/3
			hit: hit + 1
		]
		p: p + 3
	]
	vector/rs-clear styles
]