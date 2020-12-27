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

hidden-hwnd:  as handle! 0
line-metrics: as DWRITE_LINE_METRICS 0
max-line-cnt: 0

OS-text-box-color: func [
	target	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		this	[this!]
		rt		[render-target!]
		dc		[ID2D1DeviceContext]
		dl		[IDWriteTextLayout]
		brush	[integer!]
][
	brush: select-brush target + 1 color
	if zero? brush [
		rt: as render-target! target
		this: rt/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/CreateSolidColorBrush this to-dx-color color null null as ptr-ptr! :brush
		put-brush target + 1 color brush
	]

	this: as this! layout
	dl: as IDWriteTextLayout this/vtbl
	dl/SetDrawingEffect this as this! brush pos len
]

OS-text-box-background: func [
	target	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		this	[this!]
		rt		[render-target!]
		dc		[ID2D1DeviceContext]
		cache	[red-vector!]
		brush	[integer!]
][
	rt: as render-target! target
	cache: rt/styles
	if null? cache [
		cache: vector/make-at ALLOC_TAIL(root) 128 TYPE_INTEGER 4
		rt/styles: cache
	]
	brush: select-brush target + 1 color
	if zero? brush [
		this: rt/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/CreateSolidColorBrush this to-dx-color color null null as ptr-ptr! :brush
		put-brush target + 1 color brush
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
	dl/SetFontSize this as float32! 94.0 * size / 72.0 pos len
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
		text			[red-string!]
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
		TBOX_METRICS_OFFSET?
		TBOX_METRICS_OFFSET_LOWER [
			text: as red-string! int + 2
			x: as float32! 0.0 y: as float32! 0.0
			int: as red-integer! arg0
			hr: either TYPE_OF(text) <> TYPE_STRING [0][adjust-index text 0 int/value - 1 1]
			hit: as DWRITE_HIT_TEST_METRICS :left
			dl/HitTestTextPosition this hr no :x :y hit
			if y < as float32! 0.0 [y: as float32! 0.0]
			if type = TBOX_METRICS_OFFSET_LOWER [
				x: x + hit/width
				y: y + hit/height
			]
			pair/push as-integer x + as float32! 0.5 as-integer y + as float32! 0.99
		]
		TBOX_METRICS_INDEX?
		TBOX_METRICS_CHAR_INDEX? [
			pos: as red-pair! arg0
			x: as float32! pos/x
			y: as float32! pos/y
			trailing?: 0
			inside?: 0
			hit: as DWRITE_HIT_TEST_METRICS :left
			dl/HitTestPoint this x y :trailing? :inside? hit
			text: as red-string! int + 2
			if TYPE_OF(text) = TYPE_STRING [left: adjust-index text 0 left -1]
			if all [type = TBOX_METRICS_INDEX? 0 <> trailing?][left: left + 1]
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
			int: as red-integer! arg0
			hr: int/value
			while [
				hr: hr - lm/length
				lineCount: lineCount - 1
				all [hr > 0 lineCount > 0]
			][
				lm: lm + 1
			]
			y: lm/height
			integer/push as-integer y + as float32! 0.99
		]
		default [
			metrics: as DWRITE_TEXT_METRICS :left
			hr: dl/GetMetrics this metrics
			either type = TBOX_METRICS_SIZE [
				pair/push 
					as-integer (metrics/width + as float32! 0.5)
					as-integer (metrics/height + as float32! 0.5)
			][
				integer/push metrics/lineCount
			]
		]
	]
]

OS-text-box-layout: func [
	box		[red-object!]
	target	[render-target!]
	ft-clr	[integer!]
	catch?	[logic!]
	return: [this!]
	/local
		IUnk	[IUnknown]
		hWnd	[handle!]
		values	[red-value!]
		str		[red-string!]
		size	[red-pair!]
		int		[red-integer!]
		bool	[red-logic!]
		state	[red-block!]
		styles	[red-block!]
		pval	[red-value!]
		vec		[red-vector!]
		obj		[red-object!]
		w		[integer!]
		h		[integer!]
		sym		[integer!]
		type	[red-word!]
		para	[integer!]
		fmt		[this!]
		layout	[this!]
][
	values: object/get-values box
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	fmt: as this! create-text-format as red-object! values + FACE_OBJ_FONT box

	if null? target [
		hWnd: face-handle? box
		if null? hWnd [
			if null? hidden-hwnd [
				hidden-hwnd: CreateWindowEx WS_EX_TOOLWINDOW #u16 "RedBaseInternal" null WS_POPUP 0 0 2 2 null null hInstance null
				store-face-to-hWnd hidden-hwnd box
			]
			hWnd: hidden-hwnd
		]
		target: get-hwnd-render-target hWnd no
	]

	pval: null
	para: either sym = rich-text [
		state: as red-block! values + FACE_OBJ_EXT3
		either TYPE_OF(state) = TYPE_BLOCK [
			pval: block/rs-head state
			int: as red-integer! pval
			layout: as this! int/value
			COM_SAFE_RELEASE(IUnk layout)		;-- release previous text layout
			bool: as red-logic! int + 3
			bool/value: false
		][
			block/make-at state 4
			none/make-in state					;-- 1: text layout
			handle/make-in state 0				;-- 2: target
			none/make-in state					;-- 3: text
			logic/make-in state false			;-- 4: layout?
			pval: block/rs-head state
		]
		handle/make-at pval + 1 as-integer target
		0
	][5]	;-- base face
	vec: target/styles
	if vec <> null [vector/rs-clear vec]

	set-text-format fmt as red-object! values + FACE_OBJ_PARA para sym
	if sym = rich-text [
		set-tab-size fmt as red-integer! values + FACE_OBJ_EXT1
		set-line-spacing fmt as red-integer! values + FACE_OBJ_EXT2
	]

	str: as red-string! values + FACE_OBJ_TEXT
	size: as red-pair! values + FACE_OBJ_SIZE
	either TYPE_OF(size) = TYPE_PAIR [
		w: size/x h: size/y
	][
		w: 0 h: 0
	]

	if pval <> null [copy-cell as red-value! str pval + 2]		;-- save text
	layout: create-text-layout str fmt w h
	if pval <> null [handle/make-at pval as-integer layout]

	styles: as red-block! values + FACE_OBJ_DATA
	if all [
		TYPE_OF(styles) = TYPE_BLOCK
		1 < block/rs-length? styles
	][
		parse-text-styles as int-ptr! target as handle! layout styles str catch?
	]
	layout
]

txt-box-draw-background: func [
	target	[int-ptr!]
	pos		[red-pair!]
	layout	[this!]
	/local
		this		[this!]
		dc			[ID2D1DeviceContext]
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
		rc			[RECT_F!]
][
	styles: as red-vector! target/4
	if any [
		null? styles
		zero? vector/rs-length? styles
	][exit]

	this: d2d-ctx
	dc: as ID2D1DeviceContext this/vtbl
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
	rc: as RECT_F! :left
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
			height: as-integer hit/height + as float32! 0.99
			rc/right: as float32! left + width
			rc/bottom: as float32! top + height
			rc/top: as float32! top
			rc/left: as float32! left
			dc/FillRectangle this rc as this! p/3
			hit: hit + 1
		]
		p: p + 3
	]
	vector/rs-clear styles
]

adjust-index: func [
	str		[red-string!]
	offset	[integer!]
	idx		[integer!]
	adjust	[integer!]
	return: [integer!]
	/local
		s		[series!]
		unit	[integer!]
		head	[byte-ptr!]
		tail	[byte-ptr!]
		i		[integer!]
		c		[integer!]
][
	assert TYPE_OF(str) = TYPE_STRING
	s: GET_BUFFER(str)
	unit: GET_UNIT(s)
	if unit = UCS-4 [
		head: (as byte-ptr! s/offset) + (str/head + offset << 2)
		tail: head + (idx * 4)
		i: 0
		while [head < tail][
			c: string/get-char head unit
			if c >= 00010000h [
				idx: idx + adjust
				if adjust < 0 [tail: tail - unit]
			]
			head: head + unit
		]
	]
	idx
]