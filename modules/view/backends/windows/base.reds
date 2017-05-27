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

#define BASE_FACE_CLIPPED 1
#define BASE_FACE_CARET   2

init-base-face: func [
	handle		[handle!]
	parent		[integer!]
	values		[red-value!]
	alpha?		[logic!]
	/local
		pt		[tagPOINT]
		offset	[red-pair!]
		size	[red-pair!]
		show?	[red-logic!]
		opts	[red-block!]
		word	[red-word!]
		len		[integer!]
		sym		[integer!]
		flags	[integer!]
		face [red-object!]
][
	offset: as red-pair! values + FACE_OBJ_OFFSET
	size:	as red-pair! values + FACE_OBJ_SIZE
	show?:	as red-logic! values + FACE_OBJ_VISIBLE?
	opts:	as red-block! values + FACE_OBJ_OPTIONS

	SetWindowLong handle wc-offset - 4 0
	SetWindowLong handle wc-offset - 16 parent
	SetWindowLong handle wc-offset - 20 0
	SetWindowLong handle wc-offset - 24 0
	either alpha? [
		pt: as tagPOINT (as int-ptr! offset) + 2
		unless win8+? [
			pt: position-base handle as handle! parent offset
		]
		update-base handle as handle! parent pt values
		if all [show?/value IsWindowVisible as handle! parent][
			ShowWindow handle SW_SHOWNA
		]
		unless win8+? [
			process-layered-region handle size offset null offset null yes
		]
	][
		SetWindowLong handle wc-offset - 12 offset/y << 16 or (offset/x and FFFFh)
	]

	if TYPE_OF(opts) = TYPE_BLOCK [
		word: as red-word! block/rs-head opts
		len: block/rs-length? opts
		if len % 2 <> 0 [exit]
		flags: GetWindowLong handle wc-offset - 12
		while [len > 0][
			sym: symbol/resolve word/symbol
			case [
				sym = caret [
					SetWindowLong handle wc-offset - 12 flags or BASE_FACE_CARET
					face: as red-object! word + 1
					SetWindowLong handle wc-offset - 24 as-integer get-face-handle as red-object! word + 1
					update-caret handle values
				]
				true [0]
			]
			word: word + 2
			len: len - 2
		]
	]
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
		rc		[RECT_STRUCT value]
		graphic	[integer!]
		type	[integer!]
		res		[logic!]
][
	graphic: 0
	res: paint-background hWnd hDC
	
	values: get-face-values hWnd
	w: as red-word! values + FACE_OBJ_TYPE
	img: as red-image! values + FACE_OBJ_IMAGE

	GetClientRect hWnd :rc
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
		render-text values hDC :rc
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
		handle	[red-handle!]
		hFont	[handle!]
		old		[integer!]
		flags	[integer!]
		res		[logic!]
		len		[integer!]
		str		[c-string!]
][
	;unless winxp? [return render-text-d2d values hDC rc]
	res: false
	text: as red-string! values + FACE_OBJ_TEXT
	para: as red-object! values + FACE_OBJ_PARA
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
				handle: as red-handle! block/rs-head state
				if TYPE_OF(handle) = TYPE_HANDLE [
					hFont: as handle! handle/value
				]
			]
		]
		SelectObject hDC hFont
		flags: either TYPE_OF(para) = TYPE_OBJECT [
			get-para-flags base para
		][
			DT_SINGLELINE or DT_CENTER or DT_VCENTER
		]
		flags: flags or 0800h		;-- DT_NOPREFIX
		old: SetBkMode hDC 1
		len: -1
		str: unicode/to-utf16-len text :len yes
		res: 0 <> DrawText hDC str len rc flags
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
		flags	[integer!]
][
	flags: GetWindowLong hWnd wc-offset - 12
	either any [
		not zero? x
		not zero? y
		size/x <> new-width
		size/y <> new-height
		BASE_FACE_CLIPPED and flags <> 0
	][
		SetWindowLong hWnd wc-offset - 12 flags or BASE_FACE_CLIPPED
		rgn: CreateRectRgn x y new-width new-height
		SetWindowRgn hWnd rgn false
		child: as handle! GetWindowLong hWnd wc-offset - 20
		if child <> null [
			rgn: CreateRectRgn x y new-width new-height
			SetWindowRgn child rgn false
		]
	][SetWindowLong hWnd wc-offset - 12 flags and FFFFFFFEh]
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
		target	[int-ptr!]
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		flags	[integer!]
		w		[integer!]
		len		[integer!]
		hfont	[handle!]
		draw	[red-block!]
		DC		[draw-ctx!]
		font	[red-object!]
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
			either (get-face-flags hWnd) and FACET_FLAGS_D2D = 0 [
				unless zero? GetWindowLong hWnd wc-offset + 4 [
					update-base hWnd null null get-face-values hWnd
				]
			][
				target: as int-ptr! GetWindowLong hWnd wc-offset - 24
				if target <> null [
					this: as this! target/value
					rt: as ID2D1HwndRenderTarget this/vtbl
					w: WIN32_LOWORD(lParam)
					flags: WIN32_HIWORD(lParam)
					rt/Resize this as tagSIZE :w
					InvalidateRect hWnd null 1
				]
			]
			return 0
		]
		WM_PAINT
		WM_DISPLAYCHANGE [
			draw: (as red-block! get-face-values hWnd) + FACE_OBJ_DRAW
			either TYPE_OF(draw) = TYPE_BLOCK [
				either zero? GetWindowLong hWnd wc-offset - 4 [
					do-draw hWnd null draw no yes yes yes
				][
					bitblt-memory-dc hWnd no
				]
			][
				system/thrown: 0
				DC: declare draw-ctx!				;@@ should declare it on stack
				draw-begin DC hWnd null no yes
				integer/make-at as red-value! draw as-integer DC
				current-msg/hWnd: hWnd
				make-event current-msg 0 EVT_DRAWING
				draw/header: TYPE_NONE
				draw-end DC hWnd no no yes
			]
			return 0
		]
		WM_VSCROLL
		WM_HSCROLL [
			if zero? lParam [						;-- message from standard scroll bar
				current-msg/hWnd: hWnd
				current-msg/msg: msg
				current-msg/wParam: wParam
				make-event current-msg 0 EVT_SCROLL
				return 0
			]
		]
		0317h	;-- WM_PRINT
		0318h [ ;-- WM_PRINTCLIENT
			draw: (as red-block! get-face-values hWnd) + FACE_OBJ_DRAW
			do-draw hWnd as red-image! wParam draw no no no yes
			return 0
		]
		default [0]
	]
	if (get-face-flags hWnd) and FACET_FLAGS_EDITABLE <> 0 [
		switch msg [
			WM_IME_SETCONTEXT [
				either zero? wParam [
					ImmReleaseContext hWnd hIMCtx
				][
					hIMCtx: ImmGetContext hWnd
				]
			]
			010Dh [							;-- WM_IME_STARTCOMPOSITION
				ime-open?: yes
				font: as red-object! (get-face-values hWnd) + FACE_OBJ_FONT
				if TYPE_OF(font) = TYPE_OBJECT [
					hfont: get-font-handle font 0
					if hfont <> null [
						GetObject hFont 92 as byte-ptr! ime-font
						ImmSetCompositionFontW hIMCtx ime-font
					]
				]
			]
			010Eh [							;-- WM_IME_ENDCOMPOSITION
				ime-open?: no
			]
			default [0]
		]
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
	hWnd	[handle!]
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
		handle	[red-handle!]
		values	[red-value!]
		color	[red-tuple!]
		state	[red-block!]
		rect	[RECT_STRUCT_FLOAT32 value]
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
			handle: as red-handle! block/rs-head state
			if TYPE_OF(handle) = TYPE_HANDLE [
				hFont: handle/value
			]
		][
			hFont: as-integer make-font get-face-obj hWnd font
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

	rect/x: as float32! 0.0
	rect/y: as float32! 0.0
	rect/width: as float32! width
	rect/height: as float32! height

	GdipDrawString graphic unicode/to-utf16 text -1 hFont :rect format hBrush

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
	if (get-face-flags hWnd) and FACET_FLAGS_D2D <> 0 [
		InvalidateRect hWnd null 0
		exit
	]

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
		unless null? parent [
			SetParent hWnd parent
			change-offset hWnd as red-pair! values + FACE_OBJ_OFFSET base
			SetActiveWindow parent
		]
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
	GdipSetSmoothingMode graphic GDIPLUS_ANTIALIAS
	GdipSetCompositingMode graphic 0				;-- over mode
	GdipSetCompositingQuality graphic 2				;-- high quality
	GdipSetPixelOffsetMode graphic 2				;-- high quality

	if TYPE_OF(color) = TYPE_TUPLE [				;-- update background
		alpha?: update-base-background graphic color width height
	]
	update-base-image graphic img width height
	update-base-text hWnd graphic hBackDC text font para width height
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