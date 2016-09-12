Red/System [
	Title:	"Windows layered window widget"
	Author: "Xie Qingtian"
	File: 	%base.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

position-base: func [
	base	[handle!]
	parent	[handle!]
	offset	[red-pair!]
	return: [tagPOINT]
	/local
		pt	[tagPOINT]
][
	pt: declare tagPOINT
	pt/x: offset/x
	pt/y: offset/y
	ClientToScreen parent pt		;-- convert client offset to screen offset
	SetWindowLong base wc-offset - 4 pt/x
	SetWindowLong base wc-offset - 8 pt/y
	pt
]

layered-win?: func [
	hWnd	[handle!]
	return: [logic!]
][
	(WS_EX_LAYERED and GetWindowLong hWnd GWL_EXSTYLE) <> 0
]

detached?: func [
	hWnd	[handle!]
	return: [logic!]
][
	(GetWindowLong hWnd GWL_STYLE) and WS_CHILD = 0
]

render-base: func [
	hWnd	[handle!]
	hDC		[handle!]
	return: [logic!]
	/local
		values	[red-value!]
		img		[red-image!]
		w		[red-word!]
		rc		[RECT_STRUCT]
		graphic	[integer!]
		type	[integer!]
		res		[logic!]
][
	graphic: 0
	res: paint-background hWnd hDC
	
	values: get-face-values hWnd
	w: as red-word! values + FACE_OBJ_TYPE
	img: as red-image! values + FACE_OBJ_IMAGE

	rc: declare RECT_STRUCT
	GetClientRect hWnd rc
	if TYPE_OF(img) = TYPE_IMAGE [
		GdipCreateFromHDC hDC :graphic
		if zero? GdipDrawImageRectI
			graphic
			as-integer img/node
			0 0
			rc/right - rc/left rc/bottom - rc/top [res: true]
		GdipDeleteGraphics graphic
	]

	type: symbol/resolve w/symbol
	if all [
		group-box <> type
		window <> type
		render-text values hDC rc
	][
		res: true
	]
	res
]

render-text: func [
	values	[red-value!]
	hDC		[handle!]
	rc		[RECT_STRUCT]
	return: [logic!]
	/local
		text	[red-string!]
		font	[red-object!]
		para	[red-object!]
		color	[red-tuple!]
		state	[red-block!]
		int		[red-integer!]
		hFont	[handle!]
		old		[integer!]
		flags	[integer!]
		res		[logic!]
][
	unless winxp? [return render-text-d2d values hDC rc]
	res: false
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) = TYPE_STRING [
		font: as red-object! values + FACE_OBJ_FONT
		hFont: default-font
		
		if TYPE_OF(font) = TYPE_OBJECT [
			values: object/get-values font
			color: as red-tuple! values + FONT_OBJ_COLOR
			if all [
				TYPE_OF(color) = TYPE_TUPLE
				color/array1 <> 0
			][
				SetTextColor hDC color/array1 and 00FFFFFFh
			]
			state: as red-block! values + FONT_OBJ_STATE
			if TYPE_OF(state) = TYPE_BLOCK [
				int: as red-integer! block/rs-head state
				if TYPE_OF(int) = TYPE_INTEGER [
					hFont: as handle! int/value
				]
			]
		]
		SelectObject hDC hFont
		
		flags: DT_SINGLELINE
		para: as red-object! values + FACE_OBJ_PARA
		flags: either TYPE_OF(para) = TYPE_OBJECT [
			get-para-flags base para
		][
			flags or DT_CENTER or DT_VCENTER
		]
		old: SetBkMode hDC 1
		res: 0 <> DrawText hDC unicode/to-utf16 text -1 rc flags
		SetBkMode hDC old
	]
	res
]

clip-layered-window: func [
	hWnd		[handle!]
	size		[red-pair!]
	x			[integer!]
	y			[integer!]
	new-width	[integer!]
	new-height	[integer!]
	/local
		rgn		[handle!]
		child	[handle!]
][
	either any [
		not zero? x
		not zero? y
		size/x <> new-width
		size/y <> new-height
		1 = GetWindowLong hWnd wc-offset - 12
	][
		SetWindowLong hWnd wc-offset - 12 1
		rgn: CreateRectRgn x y new-width new-height
		SetWindowRgn hWnd rgn false
		child: as handle! GetWindowLong hWnd wc-offset - 20
		if child <> null [
			rgn: CreateRectRgn x y new-width new-height
			SetWindowRgn child rgn false
		]
	][SetWindowLong hWnd wc-offset - 12 0]
]

process-layered-region: func [
	hWnd	[handle!]
	size	[red-pair!]
	pos		[red-pair!]
	pane	[red-block!]
	origin	[red-pair!]
	rect	[RECT_STRUCT]
	layer?	[logic!]
	/local
		x	  [integer!]
		y	  [integer!]
		w	  [integer!]
		h	  [integer!]
		owner [handle!]
		type  [red-word!]
		value [red-value!]
		face  [red-object!]
		tail  [red-object!]
][
	x: origin/x
	y: origin/y
	either null? rect [
		rect: declare RECT_STRUCT
		owner: as handle! GetWindowLong hWnd wc-offset - 16
		assert owner <> null
		GetClientRect owner rect
	][
		x: x + pos/x
		y: y + pos/y
	]

	if layer? [
		either negative? x [
			x: either x + size/x < 0 [size/x][0 - x]
			w: size/x
		][
			w: x + size/x - rect/right
			w: either positive? w [size/x - w][size/x]
			x: 0
		]
		either negative? y [
			y: either y + size/y < 0 [size/y][0 - y]
			h: size/y
		][
			h: y + size/y - rect/bottom
			h: either positive? h [size/y - h][size/y]
			y: 0
		]
		clip-layered-window hWnd size x y w h
	]

	if all [
		pane <> null
		TYPE_OF(pane) = TYPE_BLOCK
	][
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [face < tail][
			hWnd: get-face-handle face
			value: get-face-values hWnd
			size: as red-pair! value + FACE_OBJ_SIZE
			pos: as red-pair! value + FACE_OBJ_OFFSET
			pane: as red-block! value + FACE_OBJ_PANE
			type: as red-word! value + FACE_OBJ_TYPE
			layer?: all [
				base = symbol/resolve type/symbol
				(WS_EX_LAYERED and GetWindowLong hWnd GWL_EXSTYLE) > 0
			]
			process-layered-region hWnd size pos pane origin rect layer?
			face: face + 1
		]
	]
]

update-layered-window: func [
	hWnd		[handle!]
	hdwp		[handle!]
	offset		[tagPOINT]
	winpos		[tagWINDOWPOS]
	showflag	[integer!]
	/local
		values	[red-value!]
		pane	[red-block!]
		state	[red-block!]
		type	[red-word!]
		bool	[red-logic!]
		face	[red-object!]
		tail	[red-object!]
		size	[red-pair!]
		pt		[tagPOINT]
		rect	[RECT_STRUCT]
		border	[integer!]
		width	[integer!]
		height	[integer!]
		sub?	[logic!]
][
	values: get-face-values hWnd
	type: as red-word! values + FACE_OBJ_TYPE

	sub?: either all [null? hdwp offset <> null] [
		hdwp: BeginDeferWindowPos 1
		no
	][
		yes
	]

	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		bool: as red-logic! values + FACE_OBJ_VISIBLE?
		unless bool/value [showflag: -2]
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [face < tail][
			state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
			if TYPE_OF(state) = TYPE_BLOCK [
				update-layered-window get-face-handle face hdwp offset winpos showflag
			]
			face: face + 1
		]
	]
	if all [
		sub?
		base = symbol/resolve type/symbol
		(WS_EX_LAYERED and GetWindowLong hWnd GWL_EXSTYLE) > 0
	][
		either offset <> null [
			pt: declare tagPOINT
			pt/x: offset/x + GetWindowLong hWnd wc-offset - 4
			pt/y: offset/y + GetWindowLong hWnd wc-offset - 8
			unless all [zero? offset/x zero? offset/y][
				hdwp: DeferWindowPos
					hdwp
					hWnd
					null
					pt/x pt/y
					0 0
					SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
				SetWindowLong hWnd wc-offset - 4 pt/x
				SetWindowLong hWnd wc-offset - 8 pt/y
				hWnd: as handle! GetWindowLong hWnd wc-offset - 20
				if hWnd <> null [
					hdwp: DeferWindowPos
						hdwp
						hWnd
						null
						pt/x pt/y
						0 0
						SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
				]
			]
			if all [										;-- clip window
				winpos <> null
				winpos/flags and SWP_NOSIZE = 0				;-- sized
				winpos/flags and 8000h = 0					;-- not maximize and minimize
			][
				rect: declare RECT_STRUCT
				GetClientRect winpos/hWnd rect
				border: winpos/cx - rect/right >> 1
				size: as red-pair! values + FACE_OBJ_SIZE
				width: size/x
				height: size/y
				if pt/x + size/x + border > (winpos/x + winpos/cx) [
					width: size/x - (pt/x + size/x - (winpos/x + winpos/cx)) - border
				]
				if pt/y + size/y + border > (winpos/y + winpos/cy) [
					height: size/y - (pt/y + size/y - (winpos/y + winpos/cy)) - border
				]

				clip-layered-window hWnd size 0 0 width height
			]
		][
			bool: as red-logic! values + FACE_OBJ_VISIBLE?
			either bool/value [
				case [
					showflag = -1 [showflag: SW_SHOWNA]
					showflag = -2 [showflag: SW_HIDE]		;-- parent is invisible
					true [0]
				]
			][showflag: SW_HIDE]
			ShowWindow hWnd showflag
			hWnd: as handle! GetWindowLong hWnd wc-offset - 20
			if hWnd <> null [ShowWindow hWnd showflag]
		]
	]
	unless sub? [EndDeferWindowPos hdwp]
]

BaseInternalWndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		rect	[RECT_STRUCT]
		hBrush	[handle!]
][
	switch msg [
		WM_MOUSEACTIVATE [return 3]							;-- do not make it activated when click it
		WM_NCHITTEST	 [return -1]
		WM_ERASEBKGND	 [
			hBrush: CreateSolidBrush 1
			rect: declare RECT_STRUCT
			GetClientRect hWnd rect
			FillRect as handle! wParam rect hBrush
			DeleteObject hBrush
			return 1
		]
		default [0]
	]
	DefWindowProc hWnd msg wParam lParam
]

BaseWndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		flags	[integer!]
		draw	[red-block!]
][
	switch msg [
		WM_MOUSEACTIVATE [
			flags: GetWindowLong hWnd GWL_EXSTYLE
			if flags and WS_EX_LAYERED > 0 [
				return 3							;-- do not make it activated when click it
			]
		]
		WM_LBUTTONDOWN	 [SetCapture hWnd return 0]
		WM_LBUTTONUP	 [ReleaseCapture return 0]
		WM_ERASEBKGND	 [return 1]					;-- drawing in WM_PAINT to avoid flicker
		WM_SIZE  [
			unless zero? GetWindowLong hWnd wc-offset + 4 [
				update-base hWnd null null get-face-values hWnd
			]
		]
		WM_PAINT [
			draw: (as red-block! get-face-values hWnd) + FACE_OBJ_DRAW
			either zero? GetWindowLong hWnd wc-offset - 4 [
				do-draw hWnd null draw no yes yes yes
			][
				bitblt-memory-dc hWnd no
			]
			return 0
		]
		default [0]
	]
	DefWindowProc hWnd msg wParam lParam
]

update-base-image: func [
	graphic		[integer!]
	img			[red-image!]
	width		[integer!]
	height		[integer!]
][
	if TYPE_OF(img) = TYPE_IMAGE [
		GdipDrawImageRectI graphic as-integer img/node 0 0 width height
	]
]

update-base-background: func [
	graphic [integer!]
	color	[red-tuple!]
	width	[integer!]
	height	[integer!]
	return: [logic!]				;-- true: has alpha channel
	/local
		clr		[integer!]
		brush	[integer!]
][
	clr: color/array1
	clr: to-gdiplus-color clr
	brush: 0
	GdipCreateSolidFill clr :brush
	GdipFillRectangleI graphic brush 0 0 width height
	GdipDeleteBrush brush
	either clr >>> 24 = 255 [false][true]
]

update-base-text: func [
	graphic	[integer!]
	dc		[handle!]
	text	[red-string!]
	font	[red-object!]
	para	[red-object!]
	width	[integer!]
	height	[integer!]
	/local
		format	[integer!]
		hFont	[integer!]
		hBrush	[integer!]
		flags	[integer!]
		v-align [integer!]
		h-align [integer!]
		clr		[integer!]
		int		[red-integer!]
		values	[red-value!]
		color	[red-tuple!]
		state	[red-block!]
		rect	[RECT_STRUCT_FLOAT32]
][
	if TYPE_OF(text) <> TYPE_STRING [exit]

	GdipSetTextRenderingHint graphic TextRenderingHintAntiAliasGridFit

	format: 0
	hBrush: 0
	clr: 0
	hFont: as-integer default-font

	if TYPE_OF(font) = TYPE_OBJECT [
		values: object/get-values font
		color: as red-tuple! values + FONT_OBJ_COLOR

		state: as red-block! values + FONT_OBJ_STATE
		either TYPE_OF(state) = TYPE_BLOCK [
			int: as red-integer! block/rs-head state
			if TYPE_OF(int) = TYPE_INTEGER [
				hFont: int/value
			]
		][
			hFont: as-integer make-font as red-object! none-value font
		]
		if TYPE_OF(color) = TYPE_TUPLE [clr: color/array1]
	]
	SelectObject dc as handle! hFont

	flags: either TYPE_OF(para) = TYPE_OBJECT [
		get-para-flags base para
	][
		1 or 4
	]
	case [
		flags and 1 <> 0 [h-align: 1]
		flags and 2 <> 0 [h-align: 2]
		true			 [h-align: 0]
	]
	case [
		flags and 4 <> 0 [v-align: 1]
		flags and 8 <> 0 [v-align: 2]
		true			 [v-align: 0]
	]

	GdipCreateFontFromDC as-integer dc :hFont
	GdipCreateSolidFill to-gdiplus-color clr :hBrush
	
	GdipCreateStringFormat 80000000h 0 :format
	GdipSetStringFormatAlign format h-align
	GdipSetStringFormatLineAlign format v-align

	rect: declare RECT_STRUCT_FLOAT32
	rect/x: as float32! 0.0
	rect/y: as float32! 0.0
	rect/width: as float32! width
	rect/height: as float32! height

	GdipDrawString graphic unicode/to-utf16 text -1 hFont rect format hBrush

	GdipDeleteStringFormat format
	GdipDeleteBrush hBrush
	GdipDeleteFont hFont
]

transparent-base?: func [
	color	[red-tuple!]
	img		[red-image!]
	return: [logic!]
][
	either all [
		TYPE_OF(color) = TYPE_TUPLE
		TUPLE_SIZE?(color) = 3
	][false][true]
]

update-base: func [
	hWnd	[handle!]
	parent	[handle!]
	ptDst	[tagPOINT]
	values	[red-value!]
	/local
		img		[red-image!]
		color	[red-tuple!]
		cmds	[red-block!]
		text	[red-string!]
		font	[red-object!]
		para	[red-object!]
		sz		[red-pair!]
		width	[integer!]
		height	[integer!]
		hBitmap [handle!]
		hBackDC [handle!]
		size	[tagSIZE]
		ptSrc	[tagPOINT]
		ftn		[integer!]
		bf		[tagBLENDFUNCTION]
		graphic [integer!]
		alpha?	[logic!]
		flags	[integer!]
][
	flags: GetWindowLong hWnd GWL_EXSTYLE
	if zero? (flags and WS_EX_LAYERED) [
		graphic: GetWindowLong hWnd wc-offset - 4
		DeleteDC as handle! graphic
		SetWindowLong hWnd wc-offset - 4 0
		InvalidateRect hWnd null 0
		exit
	]

	img:	as red-image!  values + FACE_OBJ_IMAGE
	color:	as red-tuple!  values + FACE_OBJ_COLOR
	cmds:	as red-block!  values + FACE_OBJ_DRAW
	text:	as red-string! values + FACE_OBJ_TEXT
	font:	as red-object! values + FACE_OBJ_FONT
	para:	as red-object! values + FACE_OBJ_PARA
	sz:		as red-pair!   values + FACE_OBJ_SIZE
	ptSrc:  declare tagPOINT
	alpha?: yes     
	graphic: 0

	unless transparent-base? color img [
		SetWindowLong hWnd GWL_STYLE WS_CHILD or WS_CLIPSIBLINGS
		SetWindowLong hWnd GWL_EXSTYLE 0
		unless null? parent [SetParent hWnd parent]
		update-base hWnd parent ptDst values
		ShowWindow hWnd SW_SHOW
		exit
	]

	width: sz/x
	height: sz/y
	hBackDC: CreateCompatibleDC hScreen
	hBitmap: CreateCompatibleBitmap hScreen width height
	SelectObject hBackDC hBitmap
	GdipCreateFromHDC hBackDC :graphic

	if TYPE_OF(color) = TYPE_TUPLE [					;-- update background
		alpha?: update-base-background graphic color width height
	]
	update-base-image graphic img width height
	update-base-text graphic hBackDC text font para width height
	do-draw null as red-image! graphic cmds yes no no yes

	ptSrc/x: 0
	ptSrc/y: 0
	size: as tagSIZE (as int-ptr! sz) + 2
	ftn: 0
	bf: as tagBLENDFUNCTION :ftn
	bf/BlendOp: as-byte 0
	bf/BlendFlags: as-byte 0
	bf/SourceConstantAlpha: as-byte 255
	bf/AlphaFormat: as-byte 1
	flags: either alpha? [2][4]
	UpdateLayeredWindow hWnd hScreen ptDst size hBackDC ptSrc 0 as-integer :ftn flags
	GdipDeleteGraphics graphic
	DeleteObject hBitmap
	DeleteDC hBackDC
]