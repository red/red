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
		GdipDrawImageRectI
			graphic
			as-integer img/node
			0 0
			rc/right - rc/left rc/bottom - rc/top
		GdipDeleteGraphics graphic
	]

	type: symbol/resolve w/symbol
	if all [group-box <> type window <> type] [
		render-text values hDC rc
	]
	res
]

render-text: func [
	values [red-value!]
	hDC	   [handle!]
	rc	   [RECT_STRUCT]
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
][
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) = TYPE_STRING [
		font: as red-object! values + FACE_OBJ_FONT
		hFont: GetStockObject DEFAULT_GUI_FONT				;-- select default GUI font
		
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
		DrawText hDC unicode/to-utf16 text -1 rc flags
		SetBkMode hDC old
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
		pos		[red-pair!]
		size	[red-pair!]
		rect	[RECT_STRUCT]
		sym		[integer!]
		style	[integer!]
		border	[integer!]
		width	[integer!]
		height	[integer!]
		sub?	[logic!]
		rgn		[handle!]
][
	values: get-face-values hWnd
	type: as red-word! values + FACE_OBJ_TYPE

	sub?: either all [null? hdwp offset <> null] [
		hdwp: BeginDeferWindowPos 1
		no
	][
		yes
	]

	sym: symbol/resolve type/symbol
	case [
		any [sym = window sym = panel sym = group-box sym = tab-panel] [
			pane: as red-block! values + FACE_OBJ_PANE
			if TYPE_OF(pane) = TYPE_BLOCK [
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
		]
		sym = base [
			either offset <> null [
				style: GetWindowLong hWnd GWL_EXSTYLE
				if style and WS_EX_LAYERED > 0 [
					pos: as red-pair! values + FACE_OBJ_OFFSET
					unless all [zero? offset/x zero? offset/y][
						pos/x: pos/x + offset/x
						pos/y: pos/y + offset/y
						hdwp: DeferWindowPos
							hdwp
							hWnd
							null
							pos/x pos/y
							0 0
							SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
					]
					if all [										;-- clip window
						winpos/flags and SWP_NOSIZE = 0				;-- sized
						winpos/flags and 8000h = 0					;-- not maximize and minimize
					][
						rect: declare RECT_STRUCT
						GetClientRect winpos/hWnd rect
						border: winpos/cx - rect/right >> 1
						size: as red-pair! values + FACE_OBJ_SIZE
						width: size/x
						height: size/y
						if pos/x + size/x > (winpos/x + winpos/cx) [
							width: size/x - (pos/x + size/x - (winpos/x + winpos/cx)) - border
						]
						if pos/y + size/y > (winpos/y + winpos/cy) [
							height: size/y - (pos/y + size/y - (winpos/y + winpos/cy)) - border
						]

						either any [
							width <> size/x
							height <> size/y
							1 = GetWindowLong hWnd wc-offset - 4
						][
							SetWindowLong hWnd wc-offset - 4 1
							rgn: CreateRectRgn 0 0 width height
							SetWindowRgn hWnd rgn false
							DeleteObject rgn
						][SetWindowLong hWnd wc-offset - 4 0]
					]
				]
			][
				bool: as red-logic! values + FACE_OBJ_VISIBLE?
				either bool/value [
					if showflag = -1 [showflag: SW_SHOWNA]
				][showflag: SW_HIDE]
				ShowWindow hWnd showflag
			]
		]
		true [0]
	]
	unless sub? [EndDeferWindowPos hdwp]
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
				SetActiveWindow GetParent hWnd
				return 3							;-- do not make it activated when click it
			]
		]
		WM_LBUTTONDOWN	 [SetCapture hWnd]
		WM_LBUTTONUP	 [ReleaseCapture]
		WM_ERASEBKGND	 [return 1]					;-- drawing in WM_PAINT to avoid flicker
		WM_PAINT [
			draw: (as red-block! get-face-values hWnd) + FACE_OBJ_DRAW
			either zero? GetWindowLong hWnd wc-offset - 4 [
				do-draw hWnd null draw no yes yes
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
	/local
		str  [red-string!]
		tail [red-string!]
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
		clr		[integer!]
		int		[red-integer!]
		values	[red-value!]
		color	[red-tuple!]
		state	[red-block!]
		rect	[RECT_STRUCT_FLOAT32]
][
	if TYPE_OF(text) <> TYPE_STRING [exit]

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
		DT_CENTER or DT_VCENTER
	]

	GdipCreateFontFromDC as-integer dc :hFont
	GdipCreateSolidFill to-gdiplus-color clr :hBrush
	
	GdipCreateStringFormat 80000000h 0 :format
	;GdipCreateStringFormat 0 0 :format
	GdipSetStringFormatAlign format 1
	GdipSetStringFormatLineAlign format 1

	rect: declare RECT_STRUCT_FLOAT32
	rect/x: as float32! 0.0
	rect/y: as float32! 0.0
	rect/width: as float32! integer/to-float width
	rect/height: as float32! integer/to-float height

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
		any [TUPLE_SIZE?(color) = 3 color/array1 >>> 24 = 255]
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
		SetWindowLong hWnd wc-offset - 4 0
		InvalidateRect hWnd null 1
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
		SetWindowLong hWnd GWL_STYLE WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS 
		SetWindowLong hWnd GWL_EXSTYLE 0
		SetParent hWnd parent
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
	do-draw null as red-image! graphic cmds yes no no

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