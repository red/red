Red/System [
	Title:	"Windows Draw dialect backend"
	Author:	"Nenad Rakocevic"
	File:	%draw.reds
	Tabs:	4
	Rights:	"Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

get-hwnd-render-target-d2d: func [
	hWnd	[handle!]
	return:	[int-ptr!]
	/local
		target	[int-ptr!]
][
	target: as int-ptr! GetWindowLong hWnd wc-offset - 36
	if null? target [
		target: as int-ptr! zero-alloc size? render-target!
		target/1: as-integer create-hwnd-render-target hWnd
		target/2: as-integer allocate D2D_MAX_BRUSHES * 2 * size? int-ptr!
		target/3: 0
		target/4: 0			;-- for text-box! background color
		SetWindowLong hWnd wc-offset - 36 as-integer target
	]
	target
]

#include %text-box.reds

draw-begin-d2d: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		_11		[integer!]
		_12		[integer!]
		_21		[integer!]
		_22		[integer!]
		_31		[integer!]
		_32		[integer!]
		m		[D2D_MATRIX_3X2_F]
		bg-clr	[integer!]
		brush	[ptr-value!]
		target	[int-ptr!]
		brushes [int-ptr!]
		pbrush	[ID2D1SolidColorBrush]
		d3d-clr [D3DCOLORVALUE]
		values	[red-value!]
		clr		[red-tuple!]
		text	[red-string!]
		pos		[red-pair! value]
][
	target: get-hwnd-render-target-d2d hWnd

	this: as this! target/value
	ctx/dc: as handle! this
	ctx/brushes: target

	rt: as ID2D1HwndRenderTarget this/vtbl
	rt/SetTextAntialiasMode this 1				;-- ClearType

	rt/BeginDraw this
	_11: 0 _12: 0 _21: 0 _22: 0 _31: 0 _32: 0
	m: as D2D_MATRIX_3X2_F :_32
	m/_11: as float32! 1.0
	m/_22: as float32! 1.0
	rt/SetTransform this m						;-- set to identity matrix

	values: get-face-values hWnd
	clr: as red-tuple! values + FACE_OBJ_COLOR
	bg-clr: either TYPE_OF(clr) = TYPE_TUPLE [get-tuple-color clr][-1]
	if bg-clr <> -1 [							;-- paint background
		rt/Clear this to-dx-color bg-clr null
	]

	d3d-clr: to-dx-color ctx/pen-color null
	rt/CreateSolidColorBrush this d3d-clr null :brush
	ctx/pen: as-integer brush/value

	rt/CreateSolidColorBrush this d3d-clr null :brush
	ctx/brush: as-integer brush/value

	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) = TYPE_STRING [
		point2D/make-at as red-value! :pos F32_0 F32_0
		OS-draw-text-d2d ctx pos as red-string! get-face-obj hWnd yes
	]
]

clean-draw-d2d: func [
	ctx		[draw-ctx!]
	/local
		IUnk [IUnknown]
		this [this!]
][
	COM_SAFE_RELEASE_OBJ(IUnk ctx/pen)
	COM_SAFE_RELEASE_OBJ(IUnk ctx/brush)
]

draw-end-d2d: func [
	ctx		[draw-ctx!]
	hWnd	[handle!]
	/local
		this [this!]
		rt	 [ID2D1HwndRenderTarget]
		hr	 [integer!]
][
	this: as this! ctx/dc
	rt: as ID2D1HwndRenderTarget this/vtbl
	hr: rt/EndDraw this null null

	clean-draw-d2d ctx

	switch hr [
		COM_S_OK [ValidateRect hWnd null]
		D2DERR_RECREATE_TARGET [
			d2d-release-target as render-target! ctx/brushes
			ctx/dc: null
			SetWindowLong hWnd wc-offset - 36 0
			InvalidateRect hWnd null 0
		]
		default [
			0		;@@ TBD log error!!!
		]
	]
]

OS-draw-pen-d2d: func [
	ctx		[draw-ctx!]
	color	[integer!]
	off?	[logic!]
	/local
		this	[this!]
		brush	[ID2D1SolidColorBrush]
][
	if any [ctx/pen-color <> color ctx/pen? = off?][
		ctx/pen?: not off?
		ctx/pen-color: color
		if ctx/pen? [
			this: as this! ctx/pen
			brush: as ID2D1SolidColorBrush this/vtbl
			brush/SetColor this to-dx-color color null
		]
	]
]

OS-draw-line-width-d2d: func [
	ctx			[draw-ctx!]
	width		[red-value!]
	/local
		width-v [float32!]
][
	width-v: (get-float32 as red-integer! width)
	if ctx/pen-width <> width-v [
		ctx/pen-width: width-v
	]
]

OS-draw-line-d2d: func [
	ctx	   [draw-ctx!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt0		[red-pair!]
		pt1		[red-pair!]
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		pt		[red-point2D!]
		x1 y1	[float32!]
		x2 y2	[float32!]
][
	this: as this! ctx/dc
	rt: as ID2D1HwndRenderTarget this/vtbl
	pt0:  point

	while [pt1: pt0 + 1 pt1 <= end][
		GET_PAIR_XY(pt0 x1 y1)
		GET_PAIR_XY(pt1 x2 y2)
		rt/DrawLine
			this
			x1 y1
			x2 y2
			as this! ctx/pen
			ctx/pen-width
			null
		pt0: pt0 + 1
	]
]

OS-draw-fill-pen-d2d: func [
	ctx		[draw-ctx!]
	color	[integer!]
	off?	[logic!]
	/local
		this	[this!]
		brush	[ID2D1SolidColorBrush]
][
	if any [ctx/brush-color <> color ctx/brush? = off?][
		ctx/brush?: not off?
		ctx/brush-color: color
		if ctx/brush? [
			this: as this! ctx/brush
			brush: as ID2D1SolidColorBrush this/vtbl
			brush/SetColor this to-dx-color color null
		]
	]
]

OS-draw-circle-d2d: func [
	ctx	   [draw-ctx!]
	center [red-pair!]
	radius [red-integer!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		ellipse [D2D1_ELLIPSE value]
		pt		[red-point2D!]
][
	this: as this! ctx/dc
	rt: as ID2D1HwndRenderTarget this/vtbl

	GET_PAIR_XY(center ellipse/x ellipse/y)
	ellipse/radiusX: get-float32 radius
	ellipse/radiusY: ellipse/radiusX
	if ctx/brush? [
		rt/FillEllipse this ellipse as this! ctx/brush
	]
	if ctx/pen? [
		rt/DrawEllipse this ellipse as this! ctx/pen ctx/pen-width as this! ctx/pen-style
	]
]

OS-draw-box-d2d: func [
	ctx		[draw-ctx!]
	upper	[red-pair!]
	lower	[red-pair!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		rc		[RECT_F! value]
		pt		[red-point2D!]
][
	this: as this! ctx/dc
	rt: as ID2D1HwndRenderTarget this/vtbl

	GET_PAIR_XY(lower rc/right rc/bottom)
	GET_PAIR_XY(upper rc/left rc/top)
	if ctx/brush? [
		rt/FillRectangle this rc as this! ctx/brush 
	]
	if ctx/pen? [
		rt/DrawRectangle this rc as this! ctx/pen ctx/pen-width as this! ctx/pen-style
	]
]

OS-draw-text-d2d: func [
	ctx		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		layout	[this!]
		fmt		[this!]
		flags	[integer!]
		x y		[float32!]
		pt		[red-point2D!]
][
	this: as this! ctx/dc
	rt: as ID2D1HwndRenderTarget this/vtbl

	layout: either TYPE_OF(text) = TYPE_OBJECT [				;-- text-box!
		OS-text-box-layout as red-object! text as render-target! ctx/brushes 0 yes
	][
		fmt: as this! create-text-format as red-object! text null
		create-text-layout text fmt 0 0
	]
	txt-box-draw-background ctx/brushes pos layout
	flags: either win8+? [4][0]		;-- 4: D2D1_DRAW_TEXT_OPTIONS_ENABLE_COLOR_FONT
	GET_PAIR_XY(pos x y)
	rt/DrawTextLayout this x y layout as this! ctx/pen flags 
]

xform: declare XFORM!

#define	SHAPE_OTHER				0
#define	SHAPE_CURVE				1
#define	SHAPE_QCURVE			2

#define	GRADIENT_NONE			0
#define	GRADIENT_LINEAR			1
#define	GRADIENT_RADIAL			2
#define	GRADIENT_DIAMOND		3

#define	INVALID_RADIUS			-1
#define	INDEX_UPPER				0
#define	INDEX_LOWER				1
#define	INDEX_OTHER				2

#define INIT_GRADIENT_DATA(upper lower other) [
	upper: gradient/data + INDEX_UPPER
	lower: gradient/data + INDEX_LOWER
	other: gradient/data + INDEX_OTHER
]

#define MAX_GRADIENT_DATA		5
#define MAX_EDGES				1000	;-- max number of edges for a polygone
#define MAX_COLORS				256		;-- max number of colors for gradient

#define ALLOC_REENTRANT(type) [
	as type allocate size? type
]
#define ALLOC_REENTRANT_ELEMS(type1 type2 count) [
	as type1 allocate count * (size? type2)
]
#define ALLOC_REENTRANT_BYTES(count) [
	allocate count
]
#define FREE_REENTRANT(word) [
	free as byte-ptr! word
]
#define FREE_REENTRANT_BYTES(word) [
	free word
]

draw-state!: alias struct! [
	gstate		[integer!]
	pen-clr		[integer!]
	brush-clr	[integer!]
	pen-join	[integer!]
	pen-cap		[integer!]
	pen?		[logic!]
	brush?		[logic!]
	a-pen?		[logic!]
	a-brush?	[logic!]
]

alloc-context: func [
	ctx				[draw-ctx!]
	/local
		max-colors	[integer!]
][
	max-colors: 2 * MAX_COLORS
	ctx/other:							ALLOC_REENTRANT(other!)
	ctx/other/gradient-pen:				ALLOC_REENTRANT(gradient!)
	ctx/other/gradient-pen/path-data:	ALLOC_REENTRANT(PATHDATA)
	ctx/other/gradient-pen/data:		ALLOC_REENTRANT_ELEMS(tagPOINT tagPOINT MAX_GRADIENT_DATA)
	ctx/other/gradient-pen/colors:		ALLOC_REENTRANT_ELEMS(int-ptr! integer! max-colors)
	ctx/other/gradient-pen/colors-pos:	as float32-ptr! ctx/other/gradient-pen/colors + MAX_COLORS
	ctx/other/gradient-fill:			ALLOC_REENTRANT(gradient!)
	ctx/other/gradient-fill/path-data:	ALLOC_REENTRANT(PATHDATA)
	ctx/other/gradient-fill/data:		ALLOC_REENTRANT_ELEMS(tagPOINT tagPOINT MAX_GRADIENT_DATA)
	ctx/other/gradient-fill/colors:		ALLOC_REENTRANT_ELEMS(int-ptr! integer! max-colors)
	ctx/other/gradient-fill/colors-pos:	as float32-ptr! ctx/other/gradient-fill/colors + MAX_COLORS
	ctx/other/matrix-elems:				ALLOC_REENTRANT_ELEMS(float32-ptr! float32! 6)
	ctx/other/paint:					ALLOC_REENTRANT(tagPAINTSTRUCT)
	ctx/other/edges:					ALLOC_REENTRANT_ELEMS(tagPOINT tagPOINT MAX_EDGES)
	ctx/other/types:					ALLOC_REENTRANT_BYTES(MAX_EDGES)
	ctx/other/path-last-point:			ALLOC_REENTRANT(tagPOINT)
	ctx/other/prev-shape:				ALLOC_REENTRANT(curve-info!)
	ctx/other/prev-shape/control:		ALLOC_REENTRANT(tagPOINT)
	ctx/other/pattern-image-fill:		ALLOC_REENTRANT_ELEMS(integer! red-image! 1)
	ctx/other/pattern-image-pen:		ALLOC_REENTRANT_ELEMS(integer! red-image! 1)
]

free-context: func [
	ctx [draw-ctx!]
][
	FREE_REENTRANT(ctx/other/pattern-image-pen)
	FREE_REENTRANT(ctx/other/pattern-image-fill)
	FREE_REENTRANT(ctx/other/prev-shape/control)
	FREE_REENTRANT(ctx/other/prev-shape)
	FREE_REENTRANT(ctx/other/path-last-point)
	FREE_REENTRANT_BYTES(ctx/other/types)
	FREE_REENTRANT(ctx/other/edges)
	FREE_REENTRANT(ctx/other/paint)
	FREE_REENTRANT(ctx/other/matrix-elems)
	FREE_REENTRANT(ctx/other/gradient-fill/colors)
	FREE_REENTRANT(ctx/other/gradient-fill/data)
	FREE_REENTRANT(ctx/other/gradient-fill/path-data)
	FREE_REENTRANT(ctx/other/gradient-fill)
	FREE_REENTRANT(ctx/other/gradient-pen/colors)
	FREE_REENTRANT(ctx/other/gradient-pen/data)
	FREE_REENTRANT(ctx/other/gradient-pen/path-data)
	FREE_REENTRANT(ctx/other/gradient-pen)
	FREE_REENTRANT(ctx/other)
]

clip-replace: func [ ctx [draw-ctx!] return: [integer!] ][
	either ctx/other/GDI+? [GDIPLUS_COMBINEMODEREPLACE][RGN_COPY]
]
clip-intersect: func [ ctx [draw-ctx!] return: [integer!] ][
	either ctx/other/GDI+? [GDIPLUS_COMBINEMODEINTERSECT][RGN_AND]
]
clip-union: func [ ctx [draw-ctx!] return: [integer!] ][
	either ctx/other/GDI+? [GDIPLUS_COMBINEMODEUNION][RGN_OR]
]
clip-xor: func [ ctx [draw-ctx!] return: [integer!] ][
	either ctx/other/GDI+? [GDIPLUS_COMBINEMODEXOR][RGN_XOR]
]
clip-diff: func [ ctx [draw-ctx!] return: [integer!] ][
	either ctx/other/GDI+? [GDIPLUS_COMBINEMODEEXCLUDE][RGN_DIFF]
]

update-gdiplus-font-color: func [ctx [draw-ctx!] color [integer!] /local brush [integer!]][
	if ctx/font-color <> color [
		unless zero? ctx/gp-font-brush [
			GdipDeleteBrush ctx/gp-font-brush
			ctx/gp-font-brush: 0
		]
		ctx/font-color: color
		brush: 0
		GdipCreateSolidFill to-gdiplus-color-fixed color :brush
		ctx/gp-font-brush: brush
	]
]

update-gdiplus-font: func [ctx [draw-ctx!] /local font [integer!]][
	font: 0
	unless zero? ctx/gp-font [GdipDeleteFont ctx/gp-font]
	GdipCreateFontFromDC as-integer ctx/dc :font
	ctx/gp-font: font
]

update-gdiplus-modes: func [ctx [draw-ctx!] ][
	update-gdiplus-pen ctx
	update-gdiplus-brush ctx
]

update-gdiplus-brush: func [ctx [draw-ctx!] /local handle [integer!]][
	handle: 0
	ctx/gp-brush-type: BRUSH_TYPE_NORMAL
	ctx/other/gradient-fill?: false
	unless zero? ctx/gp-brush [
		GdipDeleteBrush ctx/gp-brush
		ctx/gp-brush: 0
	]
	if ctx/brush? [
		GdipCreateSolidFill to-gdiplus-color-fixed ctx/brush-color :handle
		ctx/gp-brush: handle
	]
]

update-gdiplus-pen: func [ctx [draw-ctx!] /local handle [integer!]][
	ctx/gp-pen-type: BRUSH_TYPE_NORMAL
	ctx/other/gradient-pen?: false
	either ctx/pen? [
		if ctx/gp-pen-saved <> 0 [
			ctx/gp-pen: ctx/gp-pen-saved
			ctx/gp-pen-saved: 0
		]
		handle: ctx/gp-pen
		GdipSetPenColor handle to-gdiplus-color ctx/pen-color
		GdipSetPenWidth handle ctx/pen-width
		if ctx/pen-join <> 0 [
			OS-draw-line-join ctx ctx/pen-join
		]
		if ctx/pen-cap <> 0 [
			OS-draw-line-cap ctx ctx/pen-cap
		]
	][
		ctx/gp-pen-saved: ctx/gp-pen
		ctx/gp-pen: 0
	]
]

update-brush: func [ctx [draw-ctx!] /local handle [handle!]][
	if 0 <> ctx/brush [DeleteObject as handle! ctx/brush]
	handle: either ctx/brush? [
		CreateSolidBrush ctx/brush-color
	][
		GetStockObject NULL_BRUSH
	]
	ctx/brush: as-integer handle
	SelectObject ctx/dc handle
]

update-pen: func [
	ctx		  [draw-ctx!]
	/local
		mode  [integer!]
		cap   [integer!]
		join  [integer!]
		pen   [handle!]
		brush [tagLOGBRUSH]
][
	mode: 0
	if 0 <> ctx/pen [DeleteObject as handle! ctx/pen]
	either ctx/pen? [
		cap: ctx/pen-cap
		join: ctx/pen-join
		pen: either all [join = -1 cap = -1] [
			CreatePen ctx/pen-style as integer! ctx/pen-width ctx/pen-color
		][
			if join <> -1 [
				mode: case [
					join = miter		[PS_JOIN_MITER]
					join = miter-bevel	[PS_JOIN_MITER]
					join = _round		[PS_JOIN_ROUND]
					join = bevel		[PS_JOIN_BEVEL]
					true				[PS_JOIN_MITER]
				]
			]
			if cap <> -1 [
				mode: mode or case [
					cap = flat			[PS_ENDCAP_FLAT]
					cap = square		[PS_ENDCAP_SQUARE]
					cap = _round		[PS_ENDCAP_ROUND]
					true				[PS_ENDCAP_FLAT]
				]
			]
			brush: declare tagLOGBRUSH
			brush/lbStyle: BS_SOLID
			brush/lbColor: ctx/pen-color
			ExtCreatePen
				PS_GEOMETRIC or ctx/pen-style or mode
				as integer! ctx/pen-width
				brush
				0
				null
		]
		ctx/pen: as-integer pen
	][
		pen: GetStockObject NULL_PEN
		ctx/pen: 0
	]
	SelectObject ctx/dc pen
]

update-modes: func [
	ctx [draw-ctx!]
][
	either ctx/other/GDI+? [
		update-gdiplus-modes ctx
	][
		update-pen ctx
		update-brush ctx
	]
]

draw-begin: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	paint?		[logic!]
	return: 	[draw-ctx!]
	/local
		dc		 [handle!]
		rect	 [RECT_STRUCT value]
		width	 [integer!]
		height	 [integer!]
		hBitmap  [handle!]
		hBackDC  [handle!]
		graphics [integer!]
		ptrn	 [red-image!]
		ratio	 [float32!]
][
	zero-memory as byte-ptr! ctx size? draw-ctx!
	alloc-context ctx

	ctx/pen-width:		as float32! 1.0
	ctx/pen?:			yes
	ctx/hwnd:			hWnd
	ctx/font-color:		-1
	ctx/gp-brush-type:	BRUSH_TYPE_NORMAL
	ctx/gp-pen-type:	BRUSH_TYPE_NORMAL
	dc:					null

	ctx/other/gradient-pen/extra:			0
	ctx/other/gradient-pen/matrix:			0
	ctx/other/gradient-pen/spread:			WRAP_MODE_TILE
	ctx/other/gradient-pen/type:			GRADIENT_NONE
	ctx/other/gradient-pen/count:			0
	ctx/other/gradient-pen/positions?:		false
	ctx/other/gradient-pen/created?:		false
	ctx/other/gradient-pen/transformed?:	false
	ctx/other/gradient-fill/extra:			0
	ctx/other/gradient-fill/matrix:			0
	ctx/other/gradient-fill/spread:			WRAP_MODE_TILE
	ctx/other/gradient-fill/type:			GRADIENT_NONE
	ctx/other/gradient-fill/count:			0
	ctx/other/gradient-fill/positions?:		false
	ctx/other/gradient-fill/created?:		false
	ctx/other/gradient-fill/transformed?:	false
	ctx/other/gradient-pen?:				false
	ctx/other/gradient-fill?:				false
	ctx/other/D2D?:							(GetWindowLong hWnd wc-offset - 12) and BASE_FACE_D2D <> 0
	ctx/other/GDI+?:						no
	ctx/other/last-point?:					no
	ctx/other/prev-shape/type:				SHAPE_OTHER
	ctx/other/path-last-point/x:			0
	ctx/other/path-last-point/y:			0
	ctx/other/matrix-order:					GDIPLUS_MATRIX_PREPEND
	ctx/other/connect-subpath:				0
	ctx/other/anti-alias?:					no
	ptrn:									as red-image! ctx/other/pattern-image-fill
	ptrn/node:								null
	ptrn:									as red-image! ctx/other/pattern-image-pen
	ptrn/node:								null

	either null? hWnd [
		ctx/on-image?: yes
		either on-graphic? [
			graphics: as-integer img
		][
			graphics: 0
			OS-image/GdipGetImageGraphicsContext as-integer img/node :graphics
		]
		dc: CreateCompatibleDC hScreen
		SelectObject dc default-font
		SetTextColor dc ctx/pen-color
		ctx/dc: dc
		update-gdiplus-font-color ctx ctx/pen-color
	][
		either ctx/other/D2D? [
			draw-begin-d2d ctx hWnd
			return ctx
		][
			either null? img [
				dc: either paint? [BeginPaint hWnd ctx/other/paint][hScreen]
				GetClientRect hWnd rect
				width: rect/right - rect/left
				height: rect/bottom - rect/top
				hBitmap: CreateCompatibleBitmap dc width height
				hBackDC: CreateCompatibleDC dc
				SelectObject hBackDC hBitmap
				ctx/bitmap: hBitmap
			][
				hBackDC: as handle! img
			]

			dc: hBackDC
			ctx/dc: dc

			SetGraphicsMode dc GM_ADVANCED
			SetArcDirection dc AD_CLOCKWISE
			SetBkMode dc BK_TRANSPARENT
			SelectObject dc GetStockObject NULL_BRUSH

			render-base hWnd dc

			graphics: 0
			GdipCreateFromHDC dc :graphics
			SelectObject dc GetStockObject NULL_BRUSH
			SelectObject dc default-font

			update-gdiplus-font-color ctx ctx/pen-color			
		]
	]

	if any [hWnd <> null on-graphic?][
		if current-dpi <> as float32! 96.0 [
			ratio: dpi-factor
			GdipScaleWorldTransform graphics ratio ratio GDIPLUS_MATRIX_PREPEND
			ctx/scale-ratio: ratio
		]
	]

	ctx/graphics: graphics
	GdipCreatePen1
		to-gdiplus-color ctx/pen-color
		ctx/pen-width
		GDIPLUS_UNIT_WORLD
		:graphics
	ctx/gp-pen: graphics
	OS-draw-anti-alias ctx yes
	update-gdiplus-font ctx
	ctx
]

draw-end: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	paint?		[logic!]
	/local
		hr		[integer!]
		IUnk	[IUnknown]
		this	[this!]
		pad4	[integer!]
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		bitmap	[integer!]
		old-dc	[integer!]
		dc		[handle!]
		ptrn	[red-image!]
][
	if ctx/other/D2D? [
		draw-end-d2d ctx hWnd
		free-context ctx
		exit
	]

	dc: ctx/dc
	pad4: 0
	rect: as RECT_STRUCT :pad4
	if paint? [
		GetClientRect hWnd rect
		width: rect/right - rect/left
		height: rect/bottom - rect/top
		BitBlt ctx/other/paint/hdc 0 0 width height dc 0 0 SRCCOPY
	]

	unless any [on-graphic? zero? ctx/graphics][GdipDeleteGraphics ctx/graphics]
	unless zero? ctx/gp-pen			[GdipDeletePen ctx/gp-pen]
	unless zero? ctx/gp-pen-saved	[GdipDeletePen ctx/gp-pen-saved]
	unless zero? ctx/gp-brush		[GdipDeleteBrush ctx/gp-brush]
	unless zero? ctx/gp-font-brush	[GdipDeleteBrush ctx/gp-font-brush]
	unless zero? ctx/gp-font		[GdipDeleteFont ctx/gp-font]
	unless zero? ctx/image-attr 	[GdipDisposeImageAttributes ctx/image-attr]
	unless zero? ctx/gp-matrix		[GdipDeleteMatrix ctx/gp-matrix]
	unless zero? ctx/pen			[DeleteObject as handle! ctx/pen]
	unless zero? ctx/brush			[DeleteObject as handle! ctx/brush]
	unless zero? ctx/other/gradient-pen/matrix		[ GdipDeleteMatrix ctx/other/gradient-pen/matrix ]
	unless zero? ctx/other/gradient-fill/matrix		[ GdipDeleteMatrix ctx/other/gradient-fill/matrix ]
	ptrn: as red-image! ctx/other/pattern-image-fill
	unless null? ptrn/node [
		OS-image/delete as red-image! ctx/other/pattern-image-fill
	]
	ptrn: as red-image! ctx/other/pattern-image-pen
	unless null? ptrn/node [
		OS-image/delete as red-image! ctx/other/pattern-image-pen
	]

	if ctx/bitmap <> null [DeleteObject ctx/bitmap]
	either cache? [
		old-dc: GetWindowLong hWnd wc-offset - 4
		unless zero? old-dc [DeleteDC as handle! old-dc]
		SetWindowLong hWnd wc-offset - 4 as-integer dc
	][
		DeleteDC dc
	]
	if all [hWnd <> null paint?][EndPaint hWnd ctx/other/paint]

	free-context ctx
]

radian-to-degrees: func [
	radians [float!]
	return: [float!]
][
	(radians * 180.0) / PI
]

adjust-angle: func [
	x		[float!]
	y		[float!]
	angle	[float!]
	return:	[float!]
][
	case [
		all [ x >= 0.0 y <= 0.0 ] [ either angle = 0.0 [0.0 - angle][360.0 - angle] ]
		all [ x <= 0.0 y >= 0.0 ] [ 180.0 - angle ]
		all [ x <= 0.0 y <= 0.0 ] [ 180.0 + angle ]
		true [ angle ]
	]
]

set-matrix: func [
	xform		[XFORM!]
	eM11		[float!]
	eM12		[float!]
	eM21		[float!]
	eM22		[float!]
	eDx			[float!]
	eDy			[float!]
][
	xform/eM11: as float32! eM11
	xform/eM12: as float32! eM12
	xform/eM21: as float32! eM21
	xform/eM22: as float32! eM22
	xform/eDx: as float32! eDx
	xform/eDy: as float32! eDy
]

gdi-calc-arc: func [
	center-x		[float!]
	center-y		[float!]
	rad-x			[float!]
	rad-y			[float!]
	angle-begin		[float!]
	angle-len		[float!]
	return:			[arcPOINTS!]
	/local
		start-x		[float!]
		start-y		[float!]
		end-x		[float!]
		end-y		[float!]
		rad-x-float	[float32!]
		rad-y-float	[float32!]
		rad-x-2		[float32!]
		rad-y-2		[float32!]
		rad-x-y		[float32!]
		tan-2		[float32!]
		rad-beg		[float!]
		rad-end		[float!]
		points		[arcPOINTS!]
][
	points: declare arcPOINTS!
	rad-x-float: as float32! rad-x
	rad-y-float: as float32! rad-y

	either rad-x = rad-y [				;-- circle
		rad-beg: degree-to-radians angle-begin TYPE_SINE
		rad-end: degree-to-radians angle-begin + angle-len TYPE_SINE
		start-y: center-y + (rad-y-float * sin rad-beg)
		end-y:	 center-y + (rad-y-float * sin rad-end)
		rad-beg: degree-to-radians angle-begin TYPE_COSINE
		rad-end: degree-to-radians angle-begin + angle-len TYPE_COSINE
		start-x: center-x + (rad-x-float * cos rad-beg)
		end-x:	 center-x + (rad-x-float * cos rad-end)
	][
		rad-beg: degree-to-radians angle-begin TYPE_TANGENT
		rad-end: degree-to-radians angle-begin + angle-len TYPE_TANGENT
		rad-x-y: rad-x-float * rad-y-float
		rad-x-2: rad-x-float * rad-x-float
		rad-y-2: rad-y-float * rad-y-float
		tan-2: as float32! tan rad-beg
		tan-2: tan-2 * tan-2
		start-x: as float! rad-x-y / (sqrt as-float rad-x-2 * tan-2 + rad-y-2)
		start-y: as float! rad-x-y / (sqrt as-float rad-y-2 / tan-2 + rad-x-2)
		if all [angle-begin > 90.0  angle-begin < 270.0][start-x: 0.0 - start-x]
		if all [angle-begin > 180.0 angle-begin < 360.0][start-y: 0.0 - start-y]
		start-x: center-x + start-x
		start-y: center-y + start-y
		angle-begin: angle-begin + angle-len
		tan-2: as float32! tan rad-end
		tan-2: tan-2 * tan-2
		end-x: as float! rad-x-y / (sqrt as-float rad-x-2 * tan-2 + rad-y-2)
		end-y: as float! rad-x-y / (sqrt as-float rad-y-2 / tan-2 + rad-x-2)
		if angle-begin < 0.0 [ angle-begin: 360.0 + angle-begin]
		if all [angle-begin > 90.0  angle-begin < 270.0][end-x: 0.0 - end-x]
		if all [angle-begin > 180.0 angle-begin < 360.0][end-y: 0.0 - end-y]
		end-x: center-x + end-x
		end-y: center-y + end-y
	]
	points/start-x: start-x
	points/start-y: start-y
	points/end-x: end-x
	points/end-y: end-y
	points
]

draw-curves: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	nr-points	[integer!]
	/local
		point	[tagPOINT]
		pair	[red-pair!]
		nb		[integer!]
		count	[integer!]
		x y		[integer!]
		pt		[red-point2D!]
][
	point:  ctx/other/edges
	pair:   start
	nb:     0
	count: (as-integer end - pair) >> 4 + 1
	while [ all [ pair <= end nb < MAX_EDGES count >= nr-points ] ][
		point/x: ctx/other/path-last-point/x
		point/y: ctx/other/path-last-point/y
		while [ nb < 3 ][
			nb: nb + 1
			point: point + 1
			GET_PAIR_XY_INT(pair x y)
			point/x: either rel? [ x + ctx/other/path-last-point/x ][ x ]
			point/y: either rel? [ y + ctx/other/path-last-point/y ][ y ]
			if nb < nr-points [ pair: pair + 1 ]
		]
		ctx/other/path-last-point/x: point/x
		ctx/other/path-last-point/y: point/y
		either ctx/other/GDI+? [
			GdipAddPathBeziersI ctx/gp-path ctx/other/edges nb + 1
		][
			PolyBezier ctx/dc ctx/other/edges nb + 1
		]

		count: (as-integer end - pair) >> 4
		nb: 0
		point: ctx/other/edges
		pair: pair + 1
	]
	ctx/other/last-point?: yes
	point: ctx/other/edges + nr-points - 1
	ctx/other/prev-shape/type: SHAPE_CURVE
	ctx/other/prev-shape/control/x: point/x
	ctx/other/prev-shape/control/y: point/y
	ctx/other/connect-subpath: 1
]

draw-short-curves: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	nr-points	[integer!]
	/local
		pair	[red-pair!]
		point	[tagPOINT]
		nb		[integer!]
		control	[tagPOINT value]
		count	[integer!]
		pt		[red-point2D!]
		x y		[integer!]
][
	point: ctx/other/edges
	nb: 0
	pair: start
	either ctx/other/prev-shape/type = SHAPE_CURVE [
		control/x: ctx/other/prev-shape/control/x
		control/y: ctx/other/prev-shape/control/y
	][
		control/x: ctx/other/path-last-point/x
		control/y: ctx/other/path-last-point/y
	]
	while [ pair <= end ][
		point/x: ctx/other/path-last-point/x
		point/y: ctx/other/path-last-point/y
		point: point + 1
		point/x: ( 2 * ctx/other/path-last-point/x ) - control/x
		point/y: ( 2 * ctx/other/path-last-point/y ) - control/y
		if nr-points = 1 [
			control/x: point/x
			control/y: point/y
		]
		point: point + 1
		GET_PAIR_XY_INT(pair x y)
		point/x: either rel? [ ctx/other/path-last-point/x + x ][ x ]
		point/y: either rel? [ ctx/other/path-last-point/y + y ][ y ]
		if nr-points = 2 [
			control/x: point/x
			control/y: point/y
		]
		point: point + 1
		loop nr-points - 1 [ pair: pair + 1 ]
		if pair <= end [
			GET_PAIR_XY_INT(pair x y)
			point/x: either rel? [ ctx/other/path-last-point/x + x ][ x ]
			point/y: either rel? [ ctx/other/path-last-point/y + y ][ y ]
			ctx/other/last-point?: yes
			ctx/other/path-last-point/x: point/x
			ctx/other/path-last-point/y: point/y
			pair: pair + 1
			nb: nb + 4
		]
		either ctx/other/GDI+? [
			GdipAddPathBeziersI ctx/gp-path ctx/other/edges nb
		][
			PolyBezier ctx/dc ctx/other/edges nb
		]
		ctx/other/prev-shape/type: SHAPE_CURVE
		ctx/other/prev-shape/control/x: control/x
		ctx/other/prev-shape/control/y: control/y

		point: ctx/other/edges
		nb: 0
	]
	ctx/other/connect-subpath: 1
]

OS-draw-shape-beginpath: func [
	ctx			[draw-ctx!]
	draw?		[logic!]
	/local
		path	[integer!]
][
	ctx/other/connect-subpath: 0
	either ctx/other/GDI+? [
		path: 0
		GdipCreatePath 0 :path	; alternate fill
		ctx/gp-path: path
		GdipStartPathFigure ctx/gp-path
	][
		update-modes ctx
		BeginPath ctx/dc
	]
]

OS-draw-shape-endpath: func [
	ctx			[draw-ctx!]
	close?		[logic!]
	return:		[logic!]
	/local
		alpha	[byte!]
		width	[integer!]
		height	[integer!]
		ftn		[integer!]
		bf		[tagBLENDFUNCTION]
		count	[integer!]
		result	[logic!]
		point	[tagPOINT]
		dc		[handle!]
][
	result: true

	either ctx/other/GDI+? [
		if ctx/gp-path <> 0 [
			check-gradient-shape ctx                          ;-- check for gradient
			check-texture-shape ctx
			if close? [ GdipClosePathFigure ctx/gp-path ]
			GdipDrawPath ctx/graphics ctx/gp-pen ctx/gp-path
			GdipFillPath ctx/graphics ctx/gp-brush ctx/gp-path
			GdipDeletePath ctx/gp-path
			ctx/gp-path: 0
		]
	][
		dc: ctx/dc
		if close? [ CloseFigure dc ]
		EndPath dc
		count: GetPath dc ctx/other/edges ctx/other/types 0
		if count > 0 [
			count: GetPath dc ctx/other/edges ctx/other/types count
			FillPath dc
			PolyDraw dc ctx/other/edges ctx/other/types count
		]
	]
	result
]

OS-draw-shape-close: func [
	ctx		[draw-ctx!]
][
	either ctx/other/GDI+? [
		GdipClosePathFigure ctx/gp-path
	][
		CloseFigure ctx/dc
	]
]

OS-draw-shape-moveto: func [
	ctx		[draw-ctx!]
	coord	[red-pair!]
	rel?	[logic!]
	/local
		point	[tagPOINT value]
		pt		[red-point2D!]
		x y		[integer!]
][
	GET_PAIR_XY_INT(coord x y)
	either all [ rel? ctx/other/last-point? ][
		ctx/other/path-last-point/x: ctx/other/path-last-point/x + x
		ctx/other/path-last-point/y: ctx/other/path-last-point/y + y
	][
		ctx/other/path-last-point/x: x
		ctx/other/path-last-point/y: y
	]
	ctx/other/connect-subpath: 0
	ctx/other/last-point?: yes
	ctx/other/prev-shape/type: SHAPE_OTHER
	either ctx/other/GDI+? [
		GdipStartPathFigure ctx/gp-path
	][
		MoveToEx ctx/dc ctx/other/path-last-point/x ctx/other/path-last-point/y :point
	]
]

OS-draw-shape-line: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	/local
		point	[tagPOINT]
		nb		[integer!]
		pair	[red-pair!]
		pt		[red-point2D!]
][
	point: ctx/other/edges
	pair:  start
	nb:	   0

	if ctx/other/last-point? [
		point/x: ctx/other/path-last-point/x
		point/y: ctx/other/path-last-point/y
		point: point + 1
		nb: nb + 1
	]

	while [pair <= end][
		GET_PAIR_XY_INT(pair point/x point/y)
		if rel? [
			point/x: point/x + ctx/other/path-last-point/x
			point/y: point/y + ctx/other/path-last-point/y
		]
		ctx/other/path-last-point/x: point/x
		ctx/other/path-last-point/y: point/y
		nb: nb + 1
		point: point + 1
		pair: pair + 1
		if any [pair > end nb = MAX_EDGES][
			either ctx/other/GDI+? [
				GdipAddPathLine2I ctx/gp-path ctx/other/edges nb
			][
				Polyline ctx/dc ctx/other/edges nb
			]
			if all [pair <= end nb = MAX_EDGES][
				nb: 0
				point: ctx/other/edges
				pair: pair - 1
			]
		]
	]
	ctx/other/last-point?: yes
	ctx/other/prev-shape/type: SHAPE_OTHER
	ctx/other/connect-subpath: 1
]

OS-draw-shape-axis: func [
	ctx			[draw-ctx!]
	start		[red-value!]
	end			[red-value!]
	rel?		[logic!]
	hline		[logic!]
	/local
		pt		[tagPOINT]
		nb		[integer!]
		coord	[red-value!]
		coord-v	[integer!]
		coord-f	[red-float!]
		coord-i	[red-integer!]
][
	if ctx/other/last-point? [
		pt: ctx/other/edges
		nb: 0
		coord: start

		pt/x: ctx/other/path-last-point/x
		pt/y: ctx/other/path-last-point/y
		pt: pt + 1
		nb: nb + 1
		coord-v: 0
		until [
			either TYPE_OF(coord) = TYPE_INTEGER [
				coord-i: as red-integer! coord
				coord-v: coord-i/value
			][
				coord-f: as red-float! coord
				coord-v: as integer! coord-f/value
			]
			case [
				hline [
					either rel? [
						pt/x: ctx/other/path-last-point/x + coord-v
					][ pt/x: coord-v ]
					pt/y: ctx/other/path-last-point/y
					ctx/other/path-last-point/x: pt/x
				]
				true [
					either rel? [
						pt/y: ctx/other/path-last-point/y + coord-v
					][ pt/y: coord-v ]
					pt/x: ctx/other/path-last-point/x
					ctx/other/path-last-point/y: pt/y
				]
			]
			coord: coord + 1
			nb: nb + 1
			pt: pt + 1
			any [ coord > end nb >= MAX_EDGES ]
		]
		ctx/other/last-point?: yes
		either ctx/other/GDI+? [
			GdipAddPathLine2I ctx/gp-path ctx/other/edges nb
		][
			Polyline ctx/dc ctx/other/edges nb
		]
		ctx/other/prev-shape/type: SHAPE_OTHER
		ctx/other/connect-subpath: 1
	]
]

OS-draw-shape-curve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][
	draw-curves ctx start end rel? 3
]

OS-draw-shape-qcurve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][
	draw-curves ctx start end rel? 2
]

OS-draw-shape-curv: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][
	draw-short-curves ctx start end rel? 2
]

OS-draw-shape-qcurv: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][
	draw-short-curves ctx start end rel? 1
]

OS-draw-shape-arc: func [
	ctx		[draw-ctx!]
	end		[red-pair!]
	sweep?	[logic!]
	large?	[logic!]
	rel?	[logic!]
	/local
		item		[red-integer!]
		center-x	[float!]
		center-y	[float!]
		cx			[float!]
		cy			[float!]
		cf			[float!]
		angle-1		[float!]
		angle-2		[float!]
		angle-len	[float!]
		radius-x	[float!]
		radius-y	[float!]
		theta		[float!]
		X1			[float!]
		Y1			[float!]
		p1-x		[float!]
		p1-y		[float!]
		p2-x		[float!]
		p2-y		[float!]
		cos-val		[float!]
		sin-val		[float!]
		rx2			[float!]
		ry2			[float!]
		dx			[float!]
		dy			[float!]
		sqrt-val	[float!]
		sign		[float!]
		rad-check	[float!]
		m			[integer!]
		path		[integer!]
		arc-dir		[integer!]
		prev-dir	[integer!]
		arc-points	[arcPOINTS!]
		dc			[handle!]
		pt			[red-point2D!]
		x y			[float!]
][
	if ctx/other/last-point? [
		;-- parse arguments
		p1-x: as float! ctx/other/path-last-point/x
		p1-y: as float! ctx/other/path-last-point/y
		GET_PAIR_XY_F(end x y)
		p2-x: either rel? [ p1-x + x ][ x ]
		p2-y: either rel? [ p1-y + y ][ y ]
		item: as red-integer! end + 1
		radius-x: get-float item
		item: item + 1
		radius-y: get-float item
		item: item + 1
		theta: get-float item
		if radius-x < 0.0 [ radius-x: radius-x * -1.0]
		if radius-y < 0.0 [ radius-x: radius-x * -1.0]

		;-- calculate center
		dx: (p1-x - p2-x) / 2.0
		dy: (p1-y - p2-y) / 2.0
		cos-val: cos degree-to-radians theta TYPE_COSINE
		sin-val: sin degree-to-radians theta TYPE_SINE
		X1: (cos-val * dx) + (sin-val * dy)
		Y1: (cos-val * dy) - (sin-val * dx)
		rx2: radius-x * radius-x
		ry2: radius-y * radius-y
		rad-check: ((X1 * X1) / rx2) + ((Y1 * Y1) / ry2)
		if rad-check > 1.0 [
			radius-x: radius-x * sqrt rad-check
			radius-y: radius-y * sqrt rad-check
			rx2: radius-x * radius-x
			ry2: radius-y * radius-y
		]
		sign: either large? = sweep? [ -1.0 ][ 1.0 ]
		sqrt-val: ((rx2 * ry2) - (rx2 * Y1 * Y1) - (ry2 * X1 * X1)) / ((rx2 * Y1 * Y1) + (ry2 * X1 * X1))
		cf: either sqrt-val < 0.0 [ 0.0 ][ sign * sqrt sqrt-val ]
		cx: cf * (radius-x * Y1 / radius-y)
		cy: cf * (radius-y * X1 / radius-x) * -1.0
		center-x: (cos-val * cx) - (sin-val * cy) + ((p1-x + p2-x) / 2.0)
		center-y: (sin-val * cx) + (cos-val * cy) + ((p1-y + p2-y) / 2.0)

		;-- calculate angles
		angle-1: radian-to-degrees atan (float/abs ((p1-y - center-y) / (p1-x - center-x)))
		angle-1: adjust-angle (p1-x - center-x) (p1-y - center-y) angle-1
		angle-2: radian-to-degrees atan (float/abs ((p2-y - center-y) / (p2-x - center-x)))
		angle-2: adjust-angle (p2-x - center-x) (p2-y - center-y) angle-2
		angle-len: angle-2 - angle-1
		either sweep? [
			if angle-len < 0.0 [angle-len: 360.0 + angle-len]
		][
			if angle-len > 0.0 [angle-len: angle-len - 360.0]
		]
		angle-1: angle-1 - theta

		;--draw arc
		either ctx/other/GDI+? [
			path: 0
			GdipCreatePath 0 :path	; alternate fill
			GdipAddPathArc
				path
				as float32! center-x - radius-x
				as float32! center-y - radius-y
				as float32! (radius-x * 2.0)
				as float32! (radius-y * 2.0)
				as float32! angle-1
				as float32! angle-len
			m: 0

			GdipCreateMatrix :m
			GdipTranslateMatrix m as float32! (center-x * -1.0) as float32! (center-y * -1.0) GDIPLUS_MATRIX_APPEND
			GdipRotateMatrix m as float32! theta GDIPLUS_MATRIX_APPEND
			GdipTranslateMatrix m as float32! center-x as float32! center-y GDIPLUS_MATRIX_APPEND
			GdipTransformPath path m
			GdipDeleteMatrix m

			GdipAddPathPath ctx/gp-path path ctx/other/connect-subpath
			GdipDeletePath path
		][
			dc: ctx/dc
			either theta <> 0.0 [
				arc-points: gdi-calc-arc
								center-x
								center-y
								radius-x
								radius-y
								angle-1
								angle-len
			][
				arc-points: declare arcPOINTS!
				arc-points/start-x: p1-x
				arc-points/start-y: p1-y
				arc-points/end-x: p2-x
				arc-points/end-y: p2-y
			]

			set-matrix xform 1.0 0.0 0.0 1.0 center-x * -1.0 center-y * -1.0
			SetWorldTransform dc xform
			set-matrix xform cos-val sin-val sin-val * -1.0 cos-val center-x center-y
			ModifyWorldTransform dc xform MWT_RIGHTMULTIPLY

			prev-dir: GetArcDirection dc
			arc-dir: either sweep? [ AD_CLOCKWISE ][ AD_COUNTERCLOCKWISE ]
			SetArcDirection dc arc-dir
			Arc
				dc
				as integer! center-x - radius-x
				as integer! center-y - radius-y
				as integer! center-x + radius-x
				as integer! center-y + radius-y
				as integer! arc-points/start-x
				as integer! arc-points/start-y
				as integer! arc-points/end-x
				as integer! arc-points/end-y
			SetArcDirection dc prev-dir

			set-matrix xform 1.0 0.0 0.0 1.0 0.0 0.0
			SetWorldTransform dc xform
		]

		;-- set last point
		ctx/other/last-point?: yes
		ctx/other/path-last-point/x: as integer! p2-x
		ctx/other/path-last-point/y: as integer! p2-y
		ctx/other/prev-shape/type: SHAPE_OTHER
		ctx/other/connect-subpath: 1
	]
]

OS-draw-anti-alias: func [
	ctx [draw-ctx!]
	on? [logic!]
][
	ctx/other/anti-alias?: on?
	either on? [
		ctx/other/GDI+?: yes
		GdipSetSmoothingMode ctx/graphics GDIPLUS_ANTIALIAS
		GdipSetTextRenderingHint ctx/graphics TextRenderingHintAntiAliasGridFit
	][
		ctx/other/GDI+?: no
		if any [ctx/on-image? current-dpi <> as float32! 96.0][	;-- always use GDI+ to draw on image
			ctx/other/anti-alias?: yes
			ctx/other/GDI+?: yes
		]
		GdipSetSmoothingMode ctx/graphics GDIPLUS_HIGHSPPED
		GdipSetTextRenderingHint ctx/graphics TextRenderingHintSystemDefault
	]
	update-modes ctx
]

OS-draw-line: func [
	ctx	   [draw-ctx!]
	points [red-pair!]
	end	   [red-pair!]
	/local
		start	[tagPOINT]
		point	[tagPOINT]
		nb		[integer!]
		pair	[red-pair!]
		pt		[red-point2D!]
		x y		[integer!]
][
	if ctx/other/D2D? [OS-draw-line-d2d ctx points end exit]

	point: ctx/other/edges
	start: point
	pair:  points
	nb:	   0

	while [pair <= end][
		GET_PAIR_XY_INT(pair point/x point/y)
		nb: nb + 1
		point: point + 1
		pair: pair + 1
		
		if any [pair > end nb = MAX_EDGES][
			either ctx/other/GDI+? [
				check-gradient-poly ctx start 2
				GdipDrawLinesI ctx/graphics ctx/gp-pen start nb
			][
				Polyline ctx/dc start nb
			]
			if all [pair <= end nb = MAX_EDGES][
				nb: 0
				point: start
				pair: pair - 1
			]
		]
	]
]

OS-draw-pen: func [
	ctx		[draw-ctx!]
	color	[integer!]									;-- 00bbggrr format
	off?	[logic!]
	alpha?	[logic!]
][
	if all [off? ctx/pen? <> off?][exit]

	if ctx/other/D2D? [OS-draw-pen-d2d ctx color off? exit]

	ctx/alpha-pen?: alpha?
	ctx/other/GDI+?: any [alpha? ctx/other/anti-alias? ctx/alpha-brush?]

	ctx/pen?: not off?
	ctx/pen-color: color
	either ctx/other/GDI+? [update-gdiplus-pen ctx][update-pen ctx]

	unless ctx/font-color? [
		if ctx/other/GDI+? [update-gdiplus-font-color ctx color]
		unless ctx/on-image? [SetTextColor ctx/dc color]
	]
]

OS-draw-fill-pen: func [
	ctx		[draw-ctx!]
	color	[integer!]									;-- 00bbggrr format
	off?	[logic!]
	alpha?	[logic!]
][
	if all [off? ctx/brush? <> off?][exit]

	if ctx/other/D2D? [OS-draw-fill-pen-d2d ctx color off? exit]

	ctx/alpha-brush?: alpha?
	ctx/other/GDI+?: any [alpha? ctx/other/anti-alias? ctx/alpha-pen?]

	ctx/brush?: not off?
	ctx/brush-color: color
	either ctx/other/GDI+? [update-gdiplus-brush ctx][update-brush ctx]
]

OS-draw-line-width: func [
	ctx			[draw-ctx!]
	width		[red-value!]
	/local
		width-v [float32!]
][
	if ctx/other/D2D? [OS-draw-line-width-d2d ctx width exit]

	width-v: get-float32 as red-integer! width
	if ctx/pen-width <> width-v [
		ctx/pen-width: width-v
		either ctx/other/GDI+? [
			GdipSetPenWidth ctx/gp-pen ctx/pen-width
		][
			update-pen ctx
		]
	]
]

gdiplus-roundrect-path: func [
	path		[integer!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	diameter	[integer!]
	/local
		angle90 [float32!]
][
	angle90: as float32! 90
	GdipAddPathArcI path x y diameter diameter as float32! 180 angle90
	x: x + (width - diameter)
	GdipAddPathArcI path x y diameter diameter as float32! 270 angle90
	y: y + (height - diameter)
	GdipAddPathArcI path x y diameter diameter as float32! 0 angle90
	x: x - (width - diameter)
	GdipAddPathArcI path x y diameter diameter angle90 angle90
	GdipClosePathFigure path
]

gdiplus-draw-roundbox: func [
	graphics	[integer!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	radius		[integer!]
	pen			[integer!]
	brush		[integer!]
	/local
		path	[integer!]
][
	path: 0
	GdipCreatePath GDIPLUS_FILLMODE_ALTERNATE :path
	gdiplus-roundrect-path path x y width height radius
	if brush <> 0 [
		GdipFillPath graphics brush path
	]
	GdipDrawPath graphics pen path
	GdipDeletePath path
]

gdiplus-draw-box: func [
	graphics	[integer!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	radius		[integer!]
	pen			[integer!]
	brush		[integer!]
][
	if radius > 0 [
		gdiplus-draw-roundbox
			graphics
			x
			y
			width
			height
			radius
			pen
			brush
		exit
	]
	if brush <> 0 [				;-- fill rect
		GdipFillRectangleI
			graphics
			brush
			x
			y
			width
			height
	]

	GdipDrawRectangleI
		graphics
		pen
		x
		y
		width
		height
]

OS-draw-box: func [
	ctx			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		t		[integer!]
		radius	[red-integer!]
		rad		[integer!]
		up-x	[integer!]
		up-y	[integer!]
		low-x	[integer!]
		low-y	[integer!]
		width	[integer!]
		height	[integer!]
		brush	[integer!]
		pt		[red-point2D!]
][
	if ctx/other/D2D? [
		OS-draw-box-d2d ctx upper lower
		exit
	]
	rad: either TYPE_OF(lower) = TYPE_INTEGER [
		radius: as red-integer! lower
		lower:  lower - 1
		radius/value
	][0]
	GET_PAIR_XY_INT(upper up-x up-y)
	GET_PAIR_XY_INT(lower low-x low-y)
	either positive? rad [
		rad: rad * 2
		width: low-x - up-x
		height: low-y - up-y
		t: either width > height [height][width]
		rad: either rad > t [t][rad]
		either ctx/other/GDI+? [
			check-gradient-box ctx upper lower
			check-texture-box ctx upper
			brush: either ctx/brush? [ctx/gp-brush][0]
			gdiplus-draw-box
				ctx/graphics
				up-x
				up-y
				width
				height
				rad
				ctx/gp-pen
				brush
		][
			RoundRect ctx/dc up-x up-y low-x low-y rad rad
		]
	][
		either ctx/other/GDI+? [
			if up-x > low-x [t: up-x up-x: low-x low-x: t]
			if up-y > low-y [t: up-y up-y: low-y low-y: t]
			check-gradient-box ctx upper lower
			check-texture-box ctx upper
			brush: either ctx/brush? [ctx/gp-brush][0]
			gdiplus-draw-box
				ctx/graphics
				up-x
				up-y
				low-x - up-x
				low-y - up-y
				rad
				ctx/gp-pen
				brush
		][
			Rectangle ctx/dc up-x up-y low-x low-y
		]
	]
]

OS-draw-triangle: func [		;@@ TBD merge this function with OS-draw-polygon
	ctx		[draw-ctx!]
	start	[red-pair!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		pt	  [red-point2D!]
][
	point: ctx/other/edges

	GET_PAIR_XY_INT(start point/x point/y)				;-- 1st point
	point: point + 1

	pair: start + 1
	GET_PAIR_XY_INT(pair point/x point/y)				;-- 2nd point
	point: point + 1

	pair: pair + 1
	GET_PAIR_XY_INT(pair point/x point/y)				;-- 3nd point
	point: point + 1

	GET_PAIR_XY_INT(start point/x point/y)				;-- close the triangle

	either ctx/other/GDI+? [
		check-gradient-poly ctx ctx/other/edges 3
		check-texture-poly ctx ctx/other/edges 3
		if ctx/brush? [
			GdipFillPolygonI
				ctx/graphics
				ctx/gp-brush
				ctx/other/edges
				4
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI ctx/graphics ctx/gp-pen ctx/other/edges 4
	][
		either ctx/brush? [
			Polygon ctx/dc ctx/other/edges 4
		][
			Polyline ctx/dc ctx/other/edges 4
		]
	]
]

OS-draw-polygon: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		nb	  [integer!]
		pt	  [red-point2D!]
][
	point: ctx/other/edges
	pair:  start
	nb:	   0

	while [all [pair <= end nb < MAX_EDGES]][
		GET_PAIR_XY_INT(pair point/x point/y)
		nb: nb + 1
		point: point + 1
		pair: pair + 1
	]
	;if nb = max-edges [fire error]

	GET_PAIR_XY_INT(start point/x point/y)				;-- close the polygon

	either ctx/other/GDI+? [
		check-gradient-poly ctx ctx/other/edges nb
		check-texture-poly ctx ctx/other/edges nb
		if ctx/brush? [
			GdipFillPolygonI
				ctx/graphics
				ctx/gp-brush
				ctx/other/edges
				nb + 1
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI ctx/graphics ctx/gp-pen ctx/other/edges nb + 1
	][
		either ctx/brush? [
			Polygon ctx/dc ctx/other/edges nb + 1
		][
			Polyline ctx/dc ctx/other/edges nb + 1
		]
	]
]

OS-draw-spline: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	closed? [logic!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		nb	  [integer!]
		pt	  [red-point2D!]
][
	point: ctx/other/edges
	pair:  start
	nb:	   0

	while [all [pair <= end nb < MAX_EDGES]][
		GET_PAIR_XY_INT(pair point/x point/y)
		nb: nb + 1
		point: point + 1
		pair: pair + 1
	]
	;if nb = max-edges [fire error]

	unless ctx/other/GDI+? [update-gdiplus-modes ctx]					;-- force to use GDI+

	if ctx/brush? [
		GdipFillClosedCurveI
			ctx/graphics
			ctx/gp-brush
			ctx/other/edges
			nb
			GDIPLUS_FILLMODE_ALTERNATE
	]
	either closed? [
		GdipDrawClosedCurveI ctx/graphics ctx/gp-pen ctx/other/edges nb
	][
		GdipDrawCurveI ctx/graphics ctx/gp-pen ctx/other/edges nb
	]
]

do-draw-ellipse: func [
	ctx		[draw-ctx!]
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
][
	either ctx/other/GDI+? [
		check-gradient-ellipse ctx x y width height
		if ctx/brush? [
			GdipFillEllipseI
				ctx/graphics
				ctx/gp-brush
				x
				y
				width
				height
		]
		GdipDrawEllipseI
			ctx/graphics
			ctx/gp-pen
			x
			y
			width
			height
	][
		Ellipse ctx/dc x y x + width y + height
	]
]

OS-draw-circle: func [
	ctx		[draw-ctx!]
	center	[red-pair!]
	radius	[red-integer!]
	/local
		rad-x [integer!]
		rad-y [integer!]
		w	  [integer!]
		h	  [integer!]
		f	  [red-float!]
		pt	  [red-point2D!]
		x y   [integer!]
][
	if ctx/other/D2D? [
		OS-draw-circle-d2d ctx center radius
		exit
	]
	either TYPE_OF(radius) = TYPE_INTEGER [
		either center + 1 = radius [					;-- center, radius
			rad-x: radius/value
			rad-y: rad-x
		][
			rad-y: radius/value							;-- center, radius-x, radius-y
			radius: radius - 1
			rad-x: radius/value
		]
		w: rad-x * 2
		h: rad-y * 2
	][
		f: as red-float! radius
		either center + 1 = radius [
			rad-x: as-integer f/value + 0.75
			rad-y: rad-x
			w: as-integer f/value * 2.0
			h: w
		][
			rad-y: as-integer f/value + 0.75
			h: as-integer f/value * 2.0
			f: f - 1
			rad-x: as-integer f/value + 0.75
			w: as-integer f/value * 2.0
		]
	]
	GET_PAIR_XY_INT(center x y)
	do-draw-ellipse ctx x - rad-x y - rad-y w h
]

OS-draw-ellipse: func [
	ctx		 [draw-ctx!]
	upper	 [red-pair!]
	diameter [red-pair!]
	/local
		u-x  [integer!]
		u-y  [integer!]
		d-x  [integer!]
		d-y  [integer!]
		pt	 [red-point2D!]
][
	GET_PAIR_XY_INT(upper u-x u-y)
	GET_PAIR_XY_INT(diameter d-x d-y)
	do-draw-ellipse ctx u-x u-y d-x d-y
]

OS-draw-font: func [
	ctx		[draw-ctx!]
	font	[red-object!]
	/local
		vals   [red-value!]
		state  [red-block!]
		handle [red-handle!]
		color  [red-tuple!]
		hFont  [handle!]
][
	vals: object/get-values font
	state: as red-block! vals + FONT_OBJ_STATE
	color: as red-tuple! vals + FONT_OBJ_COLOR

	hFont: null
	if TYPE_OF(state) = TYPE_BLOCK [
		handle: as red-handle! (block/rs-head state) + 2
		if TYPE_OF(handle) = TYPE_HANDLE [hFont: as handle! handle/value]
	]

	if null? hFont [
		hFont: OS-make-font get-face-obj ctx/hwnd font no
	]

	SelectObject ctx/dc hFont
	update-gdiplus-font ctx
	ctx/font-color?: either TYPE_OF(color) = TYPE_TUPLE [
		SetTextColor ctx/dc color/array1
		update-gdiplus-font-color ctx get-tuple-color color
		yes
	][
		no
	]
]

OS-draw-text: func [
	ctx		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	return: [logic!]
	/local
		str		[c-string!]
		p		[c-string!]
		len		[integer!]
		h		[integer!]
		w		[integer!]
		sz		[tagSIZE]
		y		[integer!]
		x		[integer!]
		rect	[RECT_STRUCT_FLOAT32]
		tm		[tagTEXTMETRIC]
		fx fy	[float32!]
		pt		[red-point2D!]
][
	if ctx/other/D2D? [
		OS-draw-text-d2d ctx pos text catch?
		return true
	]

	if TYPE_OF(text) = TYPE_OBJECT [return false]

	GET_PAIR_XY(pos fx fy)
	len: -1
	str: unicode/to-utf16-len text :len no
	either any [
		ctx/on-image?
		ctx/other/GDI+?
	][
		x: 0
		rect: as RECT_STRUCT_FLOAT32 :x
		rect/x: fx
		rect/y: fy
		rect/width: as float32! 0
		rect/height: as float32! 0
		GdipDrawString ctx/graphics str len ctx/gp-font rect 0 ctx/gp-font-brush
	][
		tm: as tagTEXTMETRIC ctx/other/gradient-pen/colors
		GetTextMetrics ctx/dc tm
		x: dpi-scale fx
		y: dpi-scale fy
		p: str
		while [len > 0][
			if all [p/1 = #"^/" p/2 = #"^@"][
				ExtTextOut ctx/dc x y ETO_CLIPPED null str (as-integer p - str) / 2 null
				y: y + tm/tmHeight
				str: p + 2
			]
			p: p + 2
			len: len - 1
		]
		if p > str [ExtTextOut ctx/dc x y ETO_CLIPPED null str (as-integer p - str) / 2 null]
	]
	true
]

OS-draw-arc: func [
	ctx	   [draw-ctx!]
	center [red-pair!]
	end	   [red-value!]
	/local
		radius		[red-pair!]
		angle		[red-integer!]
		arc-points	[arcPOINTS!]
		dc			[handle!]
		pt			[red-point2D!]
		rad-x		[integer!]
		rad-y		[integer!]
		start-x		[integer!]
		start-y		[integer!]
		end-x		[integer!]
		end-y		[integer!]
		angle-begin	[float32!]
		angle-len	[float32!]
		rad-x-float	[float32!]
		rad-y-float	[float32!]
		rad-x-2		[float32!]
		rad-y-2		[float32!]
		rad-x-y		[float32!]
		tan-2		[float32!]
		rad-beg		[float!]
		rad-end		[float!]
		closed?		[logic!]
		prev-dir	[integer!]
		arc-dir		[integer!]
		cx cy		[integer!]
][
	radius: center + 1
	GET_PAIR_XY_INT(radius rad-x rad-y)
	angle: as red-integer! radius + 1
	angle-begin: as float32! angle/value
	angle: angle + 1
	angle-len: as float32! angle/value

	closed?: angle < end

	GET_PAIR_XY_INT(center cx cy)
	either ctx/other/GDI+? [
		either closed? [
			if ctx/brush? [
				GdipFillPieI
					ctx/graphics
					ctx/gp-brush
					cx - rad-x
					cy - rad-y
					rad-x << 1
					rad-y << 1
					angle-begin
					angle-len
			]
			GdipDrawPieI
				ctx/graphics
				ctx/gp-pen
				cx - rad-x
				cy - rad-y
				rad-x << 1
				rad-y << 1
				angle-begin
				angle-len
		][
			GdipDrawArcI
				ctx/graphics
				ctx/gp-pen
				cx - rad-x
				cy - rad-y
				rad-x << 1
				rad-y << 1
				angle-begin
				angle-len
		]
	][
		dc: ctx/dc
		rad-x-float: as float32! rad-x
		rad-y-float: as float32! rad-y

		arc-points: gdi-calc-arc
						as float! cx
						as float! cy
						as float! rad-x
						as float! rad-y
						as float! angle-begin
						as float! angle-len
		prev-dir: GetArcDirection dc
		arc-dir: either angle-len > as float32! 0.0 [ AD_CLOCKWISE ][ AD_COUNTERCLOCKWISE ]
		SetArcDirection dc arc-dir
		either closed? [
			Pie
				dc
				cx - rad-x
				cy - rad-y
				cx + rad-x
				cy + rad-y
				as integer! arc-points/start-x
				as integer! arc-points/start-y
				as integer! arc-points/end-x
				as integer! arc-points/end-y
		][
			Arc
				dc
				cx - rad-x
				cy - rad-y
				cx + rad-x
				cy + rad-y
				as integer! arc-points/start-x
				as integer! arc-points/start-y
				as integer! arc-points/end-x
				as integer! arc-points/end-y
		]
		SetArcDirection dc prev-dir
	]
]

OS-draw-curve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		p2	  [red-pair!]
		p3	  [red-pair!]
		nb	  [integer!]
		count [integer!]
		pt	  [red-point2D!]
		x y	  [integer!]
		x2 y2 [integer!]
		x3 y3 [integer!]
][
	point: ctx/other/edges
	pair:  start
	nb:	   0
	count: (as-integer end - pair) >> 4 + 1

	either count = 3 [			;-- p0, p1, p2 -> p0, (p0 + 2p1) / 3, (2p1 + p2) / 3, p2
		GET_PAIR_XY_INT(pair x y)
		point/x: x
		point/y: y
		point: point + 1
		p2: pair + 1
		p3: pair + 2
		GET_PAIR_XY_INT(p2 x2 y2)
		GET_PAIR_XY_INT(p3 x3 y3)
		point/x: x2 << 1 + x / 3
		point/y: y2 << 1 + y / 3
		point: point + 1
		point/x: x2 << 1 + x3 / 3
		point/y: y2 << 1 + y3 / 3
		point: point + 1
		GET_PAIR_XY_INT(end point/x point/y)
	][
		until [
			GET_PAIR_XY_INT(pair point/x point/y)
			nb: nb + 1
			point: point + 1
			pair: pair + 1
			nb = 4
		]
	]

	either ctx/other/GDI+? [
		GdipDrawBeziersI ctx/graphics ctx/gp-pen ctx/other/edges 4
	][
		PolyBezier ctx/dc ctx/other/edges 4
	]
]

OS-draw-line-join: func [
	ctx		[draw-ctx!]
	style	[integer!]
	/local
		mode [integer!]
][
	mode: 0
	ctx/pen-join: style
	either ctx/other/GDI+? [
		case [
			style = miter		[mode: GDIPLUS_MITER]
			style = miter-bevel [mode: GDIPLUS_MITERCLIPPED]
			style = _round		[mode: GDIPLUS_ROUND]
			style = bevel		[mode: GDIPLUS_BEVEL]
			true				[mode: GDIPLUS_MITER]
		]
		GdipSetPenLineJoin ctx/gp-pen mode
	][
		update-pen ctx PEN_LINE_JOIN
	]
]

OS-draw-line-cap: func [
	ctx		[draw-ctx!]
	style	[integer!]
	/local
		mode [integer!]
][
	mode: 0
	ctx/pen-cap: style
	either ctx/other/GDI+? [
		case [
			style = flat		[mode: GDIPLUS_LINECAPFLAT]
			style = square		[mode: GDIPLUS_LINECAPSQUARE]
			style = _round		[mode: GDIPLUS_LINECAPROUND]
			true				[mode: GDIPLUS_LINECAPFLAT]
		]
		GdipSetPenStartCap ctx/gp-pen mode
		GdipSetPenEndCap ctx/gp-pen mode
	][
		update-pen ctx PEN_LINE_CAP
	]
]

OS-draw-line-pattern: func [
	ctx			[draw-ctx!]
	start		[red-integer!]
	end			[red-integer!]
][
]

OS-draw-image: func [
	ctx			[draw-ctx!]
	src			[red-image!]
	start		[red-pair!]
	end			[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	crop1		[red-pair!]
	pattern		[red-word!]
	return:		[integer!]
	/local
		src.w	[integer!]
		src.h	[integer!]
		x		[integer!]
		y		[integer!]
		w		[integer!]
		h		[integer!]
		crop2	[red-pair!]
		crop.x	[integer!]
		crop.y	[integer!]
		crop.w	[integer!]
		crop.h	[integer!]
		dst		[red-image! value]
		handle	[integer!]
		pt		[red-point2D!]
][
	either any [
		start + 2 = end
		start + 3 = end
	][
		x: 0 y: 0 w: 0 h: 0
		image/any-resize src dst crop1 start end :x :y :w :h
		if dst/header = TYPE_NONE [return 0]
		GdipDrawImageRectI ctx/graphics as-integer dst/node x y w h
		OS-image/delete dst
	][
		src.w: IMAGE_WIDTH(src/size)
		src.h: IMAGE_HEIGHT(src/size)
		either null? start [x: 0 y: 0][GET_PAIR_XY_INT(start x y)]
		unless null? crop1 [
			crop2: crop1 + 1
			crop.x: crop1/x
			crop.y: crop1/y
			crop.w: crop2/x
			crop.h: crop2/y
			if crop.x + crop.w > src.w [
				crop.w: src.w - crop.x
			]
			if crop.y + crop.h > src.h [
				crop.h: src.h - crop.y
			]
		]
		case [
			start = end [
				either null? crop1 [
					w: src.w h: src.h
				][
					w: crop.w h: crop.h
				]
			]
			start + 1 = end [
				GET_PAIR_XY_INT(end w h)
				w: w - x
				h: h - y
			]
			true [return 0]
		]
		either null? crop1 [
			GdipDrawImageRectI ctx/graphics as-integer src/node x y w h
		][
			GdipDrawImageRectRectI
				ctx/graphics as-integer src/node
				x y w h
				crop.x crop.y crop.w crop.h
				GDIPLUS_UNIT_PIXEL 0 0 0
		]
	]
	0
]

check-texture: func [
	ctx		[draw-ctx!]
	pen?	[logic!]
	return:	[integer!]
	/local
		brush [integer!]
][
	brush: 0
	either pen? [
		if ctx/gp-pen-type = BRUSH_TYPE_TEXTURE [
			GdipGetPenBrushFill ctx/gp-pen :brush
		]
	][
		if ctx/gp-brush-type = BRUSH_TYPE_TEXTURE [
			brush: ctx/gp-brush
		]
	]
	brush
]

check-texture-box: func [
	ctx		[draw-ctx!]
	upper	[red-pair!]
	/local
		brush [integer!]
		pt	  [red-point2D!]
		fx fy [float!]
][
	brush: 0
	GET_PAIR_XY_F(upper fx fy)
	if ctx/gp-pen-type = BRUSH_TYPE_TEXTURE [
		brush: check-texture ctx true
		texture-translate fx fy brush
	]
	if ctx/gp-brush-type = BRUSH_TYPE_TEXTURE [
		brush: check-texture ctx false
		texture-translate fx fy brush
	]
]

check-texture-ellipse: func [
	ctx		[draw-ctx!]
	x		[integer!]
	y		[integer!]
	/local
		brush [integer!]
][
	brush: 0
	if ctx/gp-pen-type = BRUSH_TYPE_TEXTURE [
		brush: check-texture ctx true
		texture-translate as-float x as-float y brush
	]
	if ctx/gp-brush-type = BRUSH_TYPE_TEXTURE [
		brush: check-texture ctx false
		texture-translate as-float x as-float y brush
	]
]

check-texture-poly: func [
	ctx		[draw-ctx!]
	start	[tagPOINT]
	count	[integer!]
	/local
		cx		[integer!]
		cy		[integer!]
		d		[integer!]
		brush	[integer!]
][
	brush: 0
	cx: 0 cy: 0 d: 0
	if ctx/gp-pen-type = BRUSH_TYPE_TEXTURE [
		brush: check-texture ctx true
		get-shape-center start count :cx :cy :d
		texture-translate as-float cx as-float cy brush
	]
	if ctx/gp-brush-type = BRUSH_TYPE_TEXTURE [
		brush: check-texture ctx false
		get-shape-center start count :cx :cy :d
		texture-translate as-float cx as-float cy brush
	]
]

check-texture-shape: func [
	ctx [draw-ctx!]
	/local
		new-path	[integer!]
		count		[integer!]
		result		[integer!]
		points		[tagPOINT]
		point		[tagPOINT]
		path-data	[PATHDATA]
		pt2F		[POINT_2F]
][
	if all [
		ctx/gp-pen-type = BRUSH_TYPE_NORMAL
		ctx/gp-brush-type = BRUSH_TYPE_NORMAL
	][exit]

	;-- flatten path to get a polygon aproximation
	new-path: 0
	GdipClonePath ctx/gp-path :new-path
	GdipFlattenPath new-path 0 as float32! 1.0
	count: 0
	GdipGetPointCount new-path :count
	path-data: ALLOC_REENTRANT(PATHDATA)
	path-data/count: count
	path-data/points: as POINT_2F allocate count * (size? POINT_2F)
	path-data/types: allocate count
	GdipGetPathData new-path path-data
	;-- translate call to check-texture-poly (it will start drawing texture in the center of aproximated polygon)
	points: as tagPOINT allocate count * (size? tagPOINT)
	point: points
	pt2F:  path-data/points
	loop count [
		point/x: as-integer pt2F/x
		point/y: as-integer pt2F/y
		point: point + 1
		pt2F: pt2F + 1
	]
	check-texture-poly ctx points count
	;-- free allocated resources
	GdipDeletePath new-path
	free as byte-ptr! points
	free as byte-ptr! path-data/points
	free path-data/types
	FREE_REENTRANT(path-data)
]

texture-rotate: func [
	angle	[float!]
	brush	[integer!]
][
	unless zero? brush [ GdipRotateTextureTransform brush as-float32 angle GDIPLUS_MATRIX_PREPEND ]
]

texture-scale: func [
	sx		[float!]
	sy		[float!]
	brush	[integer!]
][
	unless zero? brush [ GdipScaleTextureTransform brush as-float32 sx as-float32 sy GDIPLUS_MATRIX_PREPEND ]
]

texture-translate: func [
	x		[float!]
	y		[float!]
	brush	[integer!]
][
	unless zero? brush [ GdipTranslateTextureTransform brush as-float32 x as-float32 y GDIPLUS_MATRIX_PREPEND ]
]

texture-set-matrix: func [
	matrix	[integer!]
	brush	[integer!]
][
	unless zero? brush [ GdipSetTextureTransform brush matrix ]
]

texture-reset-matrix: func [
	brush	[integer!]
][
	unless zero? brush [ GdipResetTextureTransform brush ]
]

texture-invert-matrix: func [
	ctx		[draw-ctx!]
	brush	[integer!]
	/local
		m	[integer!]
][
	unless zero? brush [
		m: ctx/gp-matrix
		if zero? m [
			GdipCreateMatrix :m
			ctx/gp-matrix: m
		]
		GdipGetTextureTransform brush :m
		GdipInvertMatrix m
		GdipSetTextureTransform brush m
	]
]

OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	img		[red-image!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
	/local
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
		texture	[integer!]
		wrap	[integer!]
		result	[integer!]
][
	width:  OS-image/width? img/node
	height: OS-image/height? img/node
	either crop-1 = null [
		x: 0
		y: 0
	][
		x: crop-1/x
		y: crop-1/y
	]
	either crop-2 = null [
		width:  width - x
		height: height - y
	][
		width:  either ( x + crop-2/x ) > width [ width - x ][ crop-2/x ]
		height: either ( y + crop-2/y ) > height [ height - y ][ crop-2/y ]
	]
	wrap: WRAP_MODE_TILE
	unless mode = null [
		wrap: symbol/resolve mode/symbol
		case [
			wrap = flip-x [ wrap: WRAP_MODE_TILE_FLIP_X ]
			wrap = flip-y [ wrap: WRAP_MODE_TILE_FLIP_Y ]
			wrap = flip-xy [ wrap: WRAP_MODE_TILE_FLIP_XY ]
			wrap = clamp [ wrap: WRAP_MODE_CLAMP]
			true [ wrap: WRAP_MODE_TILE ]
		]
	]
	texture: 0
	result: GdipCreateTexture2I as-integer img/node wrap x y width height :texture
	either brush? [
		ctx/brush?:         yes
		ctx/gp-brush:       texture
		ctx/gp-brush-type:  BRUSH_TYPE_TEXTURE
	][
		GdipSetPenBrushFill ctx/gp-pen texture
		ctx/gp-pen-type:    BRUSH_TYPE_TEXTURE
	]
]

OS-draw-brush-pattern: func [
	ctx		[draw-ctx!]
	size	[red-pair!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	block	[red-block!]
	brush?	[logic!]
	/local
		pat-image	[red-image!]
		bkg-alpha	[byte!]
		p-alpha		[red-binary! value]
		bin			[red-binary!]
		s			[series!]
		p			[byte-ptr!]
		len			[integer!]
][
	pat-image: either brush?
		[ as red-image! ctx/other/pattern-image-fill ]
		[ as red-image! ctx/other/pattern-image-pen ]
	unless null? pat-image/node [
		OS-image/delete pat-image
	]
	pat-image/header: TYPE_IMAGE
	pat-image/head:   0
	pat-image/size:   size/y << 16 or size/x
	bkg-alpha:        as byte! 0
	len:              size/x * size/y
	p-alpha/node:	  null								;-- avoid garbage during GC stack pointers scanning
	bin: binary/make-at :p-alpha len
	s: GET_BUFFER(bin)
	p: as byte-ptr! s/offset
	s/tail: as cell! (p + len)
	set-memory p #"^(FF)" len
	pat-image/node: OS-image/make-image size/x size/y null bin null
	do-draw null pat-image block no no no no
	OS-draw-brush-bitmap ctx pat-image crop-1 crop-2 mode brush?
]

get-shape-center: func [
	start	[tagPOINT]
	count	[integer!]
	cx		[int-ptr!]
	cy		[int-ptr!]
	d		[int-ptr!]
	/local
		point	[tagPOINT]
		dx		[integer!]
		dy		[integer!]
		x0		[integer!]
		y0		[integer!]
		x1		[integer!]
		y1		[integer!]
		a		[integer!]
		r		[integer!]
		signedArea	[float!]
		centroid-x	[float!]
		centroid-y	[float!]
][
	;-- implementation taken from http://stackoverflow.com/questions/2792443/finding-the-centroid-of-a-polygon
	x0: 0 y0: 0 x1: 0 y1: 0
	a: 0 signedArea: 0.0
	centroid-x: 0.0 centroid-y: 0.0
	point: start
	loop count - 1 [
		x0: point/x
		y0: point/y
		point: point + 1
		x1: point/x
		y1: point/y
		a: x0 * y1 - (x1 * y0)
		signedArea: signedArea + as-float a
		centroid-x: centroid-x + as-float ((x0 + x1) * a)
		centroid-y: centroid-y + as-float ((y0 + y1) * a)
	]
	x0: point/x
	y0: point/y
	x1: start/x
	y1: start/y
	a: x0 * y1 - (x1 * y0)
	signedArea: signedArea + as-float a
	centroid-x: centroid-x + as-float ((x0 + x1) * a)
	centroid-y: centroid-y + as-float ((y0 + y1) * a)

	signedArea: signedArea * 0.5
	centroid-x: centroid-x / (signedArea * 6.0)
	centroid-y: centroid-y / (signedArea * 6.0)

	cx/value: as-integer centroid-x
	cy/value: as-integer centroid-y
	;-- take biggest distance
	d/value: 0
	point: start
	loop count [
		dx: cx/value - point/x
		dy: cy/value - point/y
		r: as-integer sqrt as-float ( dx * dx + ( dy * dy ) )
		if r > d/value [ d/value: r ]
		point: point + 1
	]
]

get-shape-bounding-box: func [
	start	[tagPOINT]
	count	[integer!]
	upper	[tagPOINT]
	lower	[tagPOINT]
	/local
		point	[tagPOINT]
][
	upper/x: 1000000
	upper/y: 1000000
	lower/x: 0
	lower/y: 0
	point: start
	loop count [
		if point/x > lower/x [ lower/x: point/x ]
		if point/y > lower/y [ lower/y: point/y ]
		if point/x < upper/x [ upper/x: point/x ]
		if point/y < upper/y [ upper/y: point/y ]
		point: point + 1
	]
]

gradient-deviation: func [
	p1			[tagPOINT]
	p2			[tagPOINT]
	return:		[float32!]
	/local
		d		[float!]
		d1		[float!]
		d2		[float!]
][
	d1: as-float p1/x - p2/x
	d2: as-float p1/y - p2/y
	d: sqrt ( ( d1 * d1 ) + ( d2 * d2 ) )
	as-float32 radian-to-degrees asin ( d2 / d )
]

gradient-transform: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	/local
		brush	[integer!]
][
	if gradient/transformed? [
		either gradient = ctx/other/gradient-pen [
			brush: 0
			GdipGetPenBrushFill ctx/gp-pen :brush
		][
			brush: ctx/gp-brush
		]
		either gradient/type = GRADIENT_LINEAR [
			GdipRotateMatrix
				gradient/matrix
				(as-float32 0.0) - gradient-deviation gradient/data gradient/data + 1
				GDIPLUS_MATRIX_PREPEND
			GdipSetLineTransform brush gradient/matrix      ;-- this function resets angle of position points
		][
			GdipSetPathGradientTransform brush gradient/matrix
		]
		gradient/transformed?: false
	]
]

gradient-rotate: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	angle		[float!]
][
	gradient/transformed?: true
	GdipRotateMatrix gradient/matrix as float32! angle GDIPLUS_MATRIX_PREPEND
	if gradient/created? [ gradient-transform ctx gradient ]
]

gradient-skew: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	sx			[float!]
	sy			[float!]
	/local
		m	[integer!]
		x	[float32!]
		y	[float32!]
		u	[float32!]
		z	[float32!]
][
	m: 0
	u: as float32! 1.0
	z: as float32! 0.0
	x: as float32! tan degree-to-radians sx TYPE_TANGENT
	y: as float32! either sx = sy [0.0][tan degree-to-radians sy TYPE_TANGENT]
	gradient/transformed?: true
	GdipCreateMatrix2 u y x u z z :m
	GdipMultiplyMatrix gradient/matrix m GDIPLUS_MATRIX_PREPEND
	GdipDeleteMatrix m
	if gradient/created? [ gradient-transform ctx gradient ]
]

gradient-scale: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	sx			[float!]
	sy			[float!]
][
	gradient/transformed?: true
	GdipScaleMatrix gradient/matrix as-float32 sx as-float32 sy GDIPLUS_MATRIX_PREPEND
	if gradient/created? [ gradient-transform ctx gradient ]
]

gradient-translate: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	x			[float!]
	y			[float!]
][
	gradient/transformed?: true
	GdipTranslateMatrix gradient/matrix as-float32 x as-float32 y GDIPLUS_MATRIX_PREPEND
	if gradient/created? [ gradient-transform ctx gradient ]
]

gradient-transf-reset: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	/local
		m		[integer!]
][
	m: gradient/matrix
	either zero? m [
		GdipCreateMatrix :m
		gradient/matrix: m
	][
		GdipSetMatrixElements
			m
			as-float32 1
			as-float32 0
			as-float32 0
			as-float32 1
			as-float32 0
			as-float32 0
	]
]

gradient-set-matrix: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	m			[integer!]
	/local
		m11	[float32-ptr!]
		m12	[float32-ptr!]
		m21	[float32-ptr!]
		m22	[float32-ptr!]
		dx	[float32-ptr!]
		dy	[float32-ptr!]
][
	gradient/transformed?: true
	GdipGetMatrixElements m ctx/other/matrix-elems
	m11: ctx/other/matrix-elems
	m12: ctx/other/matrix-elems + 1
	m21: ctx/other/matrix-elems + 2
	m22: ctx/other/matrix-elems + 3
	dx:  ctx/other/matrix-elems + 4
	dy:  ctx/other/matrix-elems + 5
	GdipSetMatrixElements
		gradient/matrix
		m11/value
		m12/value
		m21/value
		m22/value
		dx/value
		dy/value
	if gradient/created? [ gradient-transform ctx gradient ]
]

gradient-reset-matrix: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
][
	gradient/transformed?: true
	gradient-transf-reset ctx gradient
	if gradient/created? [ gradient-transform ctx gradient ]
]

gradient-invert-matrix: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
][
	gradient/transformed?: true
	GdipInvertMatrix gradient/matrix
	if gradient/created? [ gradient-transform ctx gradient ]
]

save-brush: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	brush		[integer!]
][
	ctx/other/GDI+?: yes
	gradient/created?: true
	either gradient = ctx/other/gradient-fill [
		unless zero? ctx/gp-brush	[GdipDeleteBrush ctx/gp-brush]
		ctx/gp-brush: brush
		ctx/gp-brush-type: BRUSH_TYPE_NORMAL
	][
		GdipSetPenBrushFill ctx/gp-pen brush
		ctx/gp-pen-type: BRUSH_TYPE_NORMAL
	]
]

gradient-linear: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	point-1		[tagPOINT]
	point-2		[tagPOINT]
	/local
		brush	[integer!]
		count	[integer!]
][
	brush: 0
	count: gradient/count
	unless gradient/extra = 0 [
		point-1/x: point-1/x - gradient/extra - 1
		point-2/x: point-2/x + gradient/extra + 1
		gradient/extra: 0
	]
	GdipCreateLineBrushI point-1 point-2 gradient/colors/1 gradient/colors/count 0 :brush
	if gradient/transformed? [
		GdipRotateMatrix
			gradient/matrix
			(as-float32 0.0) - gradient-deviation point-1 point-2
			GDIPLUS_MATRIX_PREPEND
		GdipSetLineTransform brush gradient/matrix      ;-- this function resets angle of position points
		gradient/transformed?: false
	]
	GdipSetLinePresetBlend brush gradient/colors gradient/colors-pos count
	GdipSetLineWrapMode brush gradient/spread

	save-brush ctx gradient brush
]

gradient-radial-diamond: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	center		[tagPOINT]
	focal		[tagPOINT]
	radius		[integer!]
	/local
		brush	[integer!]
		count	[integer!]
		color	[int-ptr!]
		size	[integer!]
		n		[integer!]
		width	[integer!]
		height	[integer!]
		x		[integer!]
		y		[integer!]
		other	[tagPOINT]
][
	brush: 0

	count: gradient/count
	GdipCreatePath GDIPLUS_FILLMODE_ALTERNATE :brush

	other: gradient/data + INDEX_OTHER
	either gradient/type = GRADIENT_RADIAL [
		size: radius * 2
		x: center/x - radius
		y: center/y - radius
		unless gradient/extra = 0 [
			x: x - gradient/extra - 1
			y: y - gradient/extra - 1
			size: 2 * gradient/extra + size
			gradient/extra: 0
		]
		GdipAddPathEllipseI brush x y size size
		other/x: focal/x
		other/y: focal/y
	][
		x: center/x
		y: center/y
		width: focal/x - center/x + 1
		height: focal/y - center/y + 1
		unless gradient/extra = 0 [
			x: x - gradient/extra - 1
			y: y - gradient/extra - 1
			width: 2 * gradient/extra + height
			height: 2 * gradient/extra + height
			gradient/extra: 0
		]
		GdipAddPathRectangleI brush x y width height
	]

	n: brush
	GdipCreatePathGradientFromPath n :brush
	GdipDeletePath n
	GdipSetPathGradientCenterColor brush gradient/colors/value
	either gradient/type = GRADIENT_RADIAL [
		GdipSetPathGradientCenterPointI brush focal
	][
		unless radius = INVALID_RADIUS [ GdipSetPathGradientCenterPointI brush other ]
	]
	reverse-int-array gradient/colors count
	reverse-float32-array gradient/colors-pos count
	GdipSetPathGradientPresetBlend brush gradient/colors gradient/colors-pos count
	reverse-int-array gradient/colors count
	reverse-float32-array gradient/colors-pos count

	if gradient/transformed? [
		GdipSetPathGradientTransform brush gradient/matrix
		gradient/transformed?: false
	]
	GdipSetPathGradientWrapMode brush gradient/spread

	save-brush ctx gradient brush
]

check-gradient: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	/local
		upper	[tagPOINT]
		lower	[tagPOINT]
		radius	[tagPOINT]
][
	INIT_GRADIENT_DATA(upper lower radius)
	if all [ gradient = ctx/other/gradient-pen ctx/pen-width > as float32! 1.0 ] [
		gradient/extra: as-integer ctx/pen-width / as float32! 2.0
	]
	case [
		gradient/type = GRADIENT_LINEAR [
			gradient-linear ctx gradient upper lower
		]
		any [
			gradient/type = GRADIENT_RADIAL
			gradient/type = GRADIENT_DIAMOND
		][
			gradient-radial-diamond ctx gradient upper lower radius/x
		]
		true []
	]
]

_check-gradient-box: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		dx		[integer!]
		dy		[integer!]
		_upper	[tagPOINT]
		_lower	[tagPOINT]
		_other	[tagPOINT]
][
	INIT_GRADIENT_DATA(_upper _lower _other)
	case [
		any [
			gradient/type = GRADIENT_LINEAR
			gradient/type = GRADIENT_DIAMOND
		][
			_upper/x: upper/x
			_lower/x: lower/x
			either gradient/type = GRADIENT_LINEAR [
				_upper/y: 0
				_lower/y: 0
			][
				_upper/y: upper/y
				_lower/y: lower/y
			]
			_other/x: INVALID_RADIUS
		]
		gradient/type = GRADIENT_RADIAL [
			dx: ( lower/x - upper/x + 1 ) / 2
			dy: ( lower/y - upper/y + 1 ) / 2
			_upper/x: upper/x + dx
			_upper/y: upper/y + dy
			_lower/x: _upper/x
			_lower/y: _upper/y
			_other/x: as-integer sqrt as-float (dx * dx + ( dy * dy ) )
		]
		true []
	]
	check-gradient ctx gradient _upper _lower _other
]
check-gradient-box: func [
	ctx		[draw-ctx!]
	upper	[red-pair!]
	lower	[red-pair!]
][
	if all [
		ctx/other/gradient-pen?
		not ctx/other/gradient-pen/positions?
	][
		_check-gradient-box
			ctx
			ctx/other/gradient-pen
			upper
			lower
	]
	if all [
		ctx/other/gradient-fill?
		not ctx/other/gradient-fill/positions?
	][
		ctx/brush?: true
		_check-gradient-box
			ctx
			ctx/other/gradient-fill
			upper
			lower
	]
]

_check-gradient-ellipse: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		dx		[integer!]
		dy		[integer!]
		upper	[tagPOINT]
		lower	[tagPOINT]
		other	[tagPOINT]
][
	INIT_GRADIENT_DATA(upper lower other)
	case [
		any [
			gradient/type = GRADIENT_LINEAR
			gradient/type = GRADIENT_DIAMOND
		][
			upper/x: x
			lower/x: x + width
			either gradient/type = GRADIENT_LINEAR [
				upper/y: 0
				lower/y: 0
			][
				upper/y: y
				lower/y: y + height
			]
			other/x: INVALID_RADIUS
		]
		gradient/type = GRADIENT_RADIAL [
			dx: width / 2
			dy: height / 2
			upper/x: x + dx
			upper/y: y + dy
			lower/x: upper/x
			lower/y: upper/y
			other/x: either dx > dy [dx][dy]
		]
		true []
	]
	check-gradient ctx gradient upper lower other
]
check-gradient-ellipse: func [
	ctx		[draw-ctx!]
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
][
	if all [
		ctx/other/gradient-pen?
		not ctx/other/gradient-pen/positions?
	][
		_check-gradient-ellipse
			ctx
			ctx/other/gradient-pen
			x
			y
			width
			height
	]
	if all [
		ctx/other/gradient-fill?
		not ctx/other/gradient-fill/positions?
	][
		ctx/brush?: true
		_check-gradient-ellipse
			ctx
			ctx/other/gradient-fill
			x
			y
			width
			height
	]
]

_check-gradient-poly: func [
	ctx			[draw-ctx!]
	gradient	[gradient!]
	start		[tagPOINT]
	count		[integer!]
	/local
		cx		[integer!]
		cy		[integer!]
		d		[integer!]
		upper	[tagPOINT]
		lower	[tagPOINT]
		other	[tagPOINT]
][
	INIT_GRADIENT_DATA(upper lower other)
	cx: 0 cy: 0 d: 0
	case [
		any [
			gradient/type = GRADIENT_LINEAR
			gradient/type = GRADIENT_DIAMOND
		][
			get-shape-bounding-box start count upper lower
			either gradient/type = GRADIENT_LINEAR [
				upper/y: 0
				lower/y: 0
				other/x: INVALID_RADIUS
			][
				get-shape-center start count :cx :cy :d
				other/x: cx
				other/y: cy
			]
		]
		gradient/type = GRADIENT_RADIAL [
			get-shape-center start count :cx :cy :d
			upper/x: cx
			upper/y: cy
			lower/x: cx
			lower/y: cy
			other/x: d
		]
	]
	check-gradient ctx gradient upper lower other
]
check-gradient-poly: func [
	ctx		[draw-ctx!]
	start	[tagPOINT]
	count	[integer!]
][
	if all [
		ctx/other/gradient-pen?
		not ctx/other/gradient-pen/positions?
	][
		_check-gradient-poly
			ctx
			ctx/other/gradient-pen
			start
			count
	]
	if all [
		ctx/other/gradient-fill?
		not ctx/other/gradient-fill/positions?
	][
		ctx/brush?: true
		_check-gradient-poly
			ctx
			ctx/other/gradient-fill
			start
			count
	]
]

_check-gradient-shape: func [
	ctx				[draw-ctx!]
	gradient		[gradient!]
	/local
		new-path	[integer!]
		count		[integer!]
		result		[integer!]
		points		[tagPOINT]
		point		[tagPOINT]
		pt2F		[POINT_2F]
][
	;-- flatten path to get a polygon aproximation
	new-path: 0
	GdipClonePath ctx/gp-path :new-path
	GdipFlattenPath new-path 0 as float32! 1.0
	count: 0
	GdipGetPointCount new-path :count
	gradient/path-data/count: count
	gradient/path-data/points: as POINT_2F allocate count * (size? POINT_2F)
	gradient/path-data/types: allocate count
	GdipGetPathData new-path gradient/path-data
	;-- translate call to check-gradient-poly (it will draw gradient in the center of aproximated polygon)
	points: as tagPOINT allocate count * (size? tagPOINT)
	point: points
	pt2F:  gradient/path-data/points
	loop count [
		point/x: as-integer pt2F/x
		point/y: as-integer pt2F/y
		point: point + 1
		pt2F: pt2F + 1
	]
	_check-gradient-poly ctx gradient points count
	;-- free allocated resources
	GdipDeletePath new-path
	free as byte-ptr! points
	free as byte-ptr! gradient/path-data/points
	free gradient/path-data/types
]
check-gradient-shape: func [
	ctx	[draw-ctx!]
][
	if all [
		ctx/other/gradient-pen?
		not ctx/other/gradient-pen/positions?
	][
		_check-gradient-shape
			ctx
			ctx/other/gradient-pen
	]
	if all [
		ctx/other/gradient-fill?
		not ctx/other/gradient-fill/positions?
	][
		ctx/brush?: true
		_check-gradient-shape
			ctx
			ctx/other/gradient-fill
	]
]

OS-draw-grad-pen-old: func [
	ctx			[draw-ctx!]
	type		[integer!]
	mode		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
	/local
		x		[integer!]
		y		[integer!]
		start	[integer!]
		stop	[integer!]
		brush	[integer!]
		angle	[float32!]
		sx		[float32!]
		sy		[float32!]
		int		[red-integer!]
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		pt		[tagPOINT]
		color	[int-ptr!]
		last-c	[int-ptr!]
		pos		[float32-ptr!]
		last-p	[float32-ptr!]
		n		[integer!]
		delta	[float!]
		p		[float!]
		rotate? [logic!]
		scale?	[logic!]
		_colors [int-ptr!]
		_colors-pos [float32-ptr!]
][
	_colors: ctx/other/gradient-pen/colors
	_colors-pos: ctx/other/gradient-pen/colors-pos
	x: offset/x
	y: offset/y

	int: as red-integer! offset + 1
	start: int/value
	int: int + 1
	stop: int/value

	n: 0
	rotate?: no
	scale?: no
	sy: as float32! 1.0
	while [
		int: int + 1
		n < 3
	][								;-- fetch angle, scale-x and scale-y (optional)
		switch TYPE_OF(int) [
			TYPE_INTEGER	[p: as-float int/value]
			TYPE_FLOAT		[f: as red-float! int p: f/value]
			default			[break]
		]
		switch n [
			0	[if p <> 0.0 [angle: as float32! p rotate?: yes]]
			1	[if p <> 1.0 [sx: as float32! p scale?: yes]]
			2	[if p <> 1.0 [sy: as float32! p scale?: yes]]
		]
		n: n + 1
	]

	pt: ctx/other/edges
	color: _colors + 1
	pos: _colors-pos + 1
	delta: as-float count - 1
	delta: 1.0 / delta
	p: 0.0
	head: as red-value! int
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		color/value: to-gdiplus-color get-tuple-color clr
		next: head + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		pos/value: as float32! p
		if next <> head [p: p + delta]
		head: head + 1
		color: color + 1
		pos: pos + 1
	]

	last-p: pos - 1
	last-c: color - 1
	pos: pos - count
	color: color - count
	if pos/value > as float32! 0.0 [			;-- first one should be always 0.0
		_colors-pos/value: as float32! 0.0
		_colors/value: color/value
		color: _colors
		pos: _colors-pos
		count: count + 1
	]
	if last-p/value < as float32! 1.0 [			;-- last one should be always 1.0
		last-c/2: last-c/value
		last-p/2: as float32! 1.0
		count: count + 1
	]

	brush: 0
	either type = linear [
		pt/x: x + start
		pt/y: y
		pt: pt + 1
		pt/x: x + stop
		pt/y: y
		GdipCreateLineBrushI ctx/other/edges pt color/1 color/count 0 :brush
		GdipSetLinePresetBlend brush color pos count
		if rotate? [GdipRotateLineTransform brush angle GDIPLUS_MATRIX_APPEND]
		if scale? [GdipScaleLineTransform brush sx sy GDIPLUS_MATRIX_APPEND]
	][
		GdipCreatePath GDIPLUS_FILLMODE_ALTERNATE :brush
		n: stop - start
		stop: n * 2
		case [
			type = radial  [GdipAddPathEllipseI brush x - n y - n stop stop]
			type = diamond [GdipAddPathRectangleI brush x - n y - n stop stop]
		]

		GdipCreateMatrix :n
		if rotate? [GdipRotateMatrix n angle GDIPLUS_MATRIX_APPEND]
		if scale?  [GdipScaleMatrix n sx sy GDIPLUS_MATRIX_APPEND]
		scale?: any [rotate? scale?]
		if scale? [							;@@ transform path will move it
			GdipTransformPath brush n
			GdipDeleteMatrix n
		]

		n: brush
		GdipCreatePathGradientFromPath n :brush
		GdipDeletePath n
		GdipSetPathGradientCenterColor brush color/value
		GdipSetPathGradientCenterPointI brush as tagPOINT :offset/x
		reverse-int-array color count
		n: count - 1
		start: 2
		while [start < n][					;-- reverse position
			sx: pos/start
			pos/start: (as float32! 1.0) - pos/n
			pos/n: (as float32! 1.0) - sx
			n: n - 1
			start: start + 1
		]
		GdipSetPathGradientPresetBlend brush color pos count

		if any [							;@@ move the shape back to the right position
			all [type = radial scale?]
			all [type = diamond rotate?]
		][
			GdipGetPathGradientCenterPointI brush pt
			sx: as float32! x - pt/x
			sy: as float32! y - pt/y
			GdipTranslatePathGradientTransform brush sx sy GDIPLUS_MATRIX_APPEND
		]
	]

	ctx/other/GDI+?: yes
	either brush? [
		unless zero? ctx/gp-brush	[GdipDeleteBrush ctx/gp-brush]
		ctx/brush?: yes
		ctx/gp-brush: brush
	][
		GdipSetPenBrushFill ctx/gp-pen brush
	]
]

OS-draw-grad-pen: func [
	ctx			[draw-ctx!]
	mode		[integer!]
	stops		[red-value!]
	count		[integer!]
	skip-pos	[logic!]
	positions	[red-value!]
	focal?		[logic!]
	spread		[integer!]
	brush?		[logic!]
	/local
		x		[integer!]
		y		[integer!]
		start	[integer!]
		stop	[integer!]
		brush	[integer!]
		angle	[float32!]
		sx		[float32!]
		sy		[float32!]
		int		[red-integer!]
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		pt		[tagPOINT]
		color	[int-ptr!]
		last-c	[int-ptr!]
		pos		[float32-ptr!]
		last-p	[float32-ptr!]
		n		[integer!]
		delta	[float!]
		p		[float!]
		radius		[integer!]
		first-point	[logic!]
		last-point	[logic!]
		point		[red-pair!]
		value		[red-value!]
		_colors		[int-ptr!]
		_colors-pos	[float32-ptr!]
		gradient	[gradient!]
		gm			[integer!]
][
	either brush? [
		ctx/other/gradient-fill?: true
		_colors: ctx/other/gradient-fill/colors
		_colors-pos: ctx/other/gradient-fill/colors-pos
	][
		ctx/other/gradient-pen?: true
		_colors: ctx/other/gradient-pen/colors
		_colors-pos: ctx/other/gradient-pen/colors-pos
	]
	;-- stops
	pt: ctx/other/edges
	color: _colors + 1
	pos: _colors-pos + 1
	delta: as-float count - 1
	delta: 1.0 / delta
	p: 0.0
	head: stops
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		color/value: to-gdiplus-color get-tuple-color clr
		next: head + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		pos/value: either mode = linear [ as float32! p ][ as float32! ( 1.0 - p ) ]
		if next <> head [p: p + delta]
		head: head + 1
		color: color + 1
		pos: pos + 1
	]
	;-- patch first and last point
	last-p: pos - 1
	last-c: color - 1
	pos: pos - count
	color: color - count
	first-point: false
	last-point:  false
	either mode = linear [
		_colors-pos/value: as float32! 0.0          ;-- first one should be always 0.0
		if last-p/value < as float32! 1.0 [			;-- last one should be always 1.0
			last-point: true
			last-p: last-p + 1
			last-p/value: as float32! 1.0
		]
	][
		_colors-pos/value: as float32! 1.0          ;-- first one should be always 1.0
		if last-p/value > as float32! 0.0 [			;-- last one should be always 0.0
			last-point: true
			last-p: last-p + 1
			last-p/value: as float32! 0.0
		]
	]
	_colors/value: color/value
	count: count + 1
	if last-point [
		color: last-c
		last-c: last-c + 1
		last-c/value: color/value
		count: count + 1
	]
	gradient: either brush? [ctx/brush?: yes ctx/other/gradient-fill ][ ctx/other/gradient-pen ]
	gradient/count:     count
	gradient/created?:  false
	gradient/positions?: false
	gradient-transf-reset ctx gradient

	;-- spread
	case [
		spread = _pad       [ gradient/spread: WRAP_MODE_TILE ]         ;-- currently pad not supported by GDI+, fallback to repeat
		spread = _repeat    [ gradient/spread: WRAP_MODE_TILE ]
		spread = _reflect   [ gradient/spread: WRAP_MODE_TILE_FLIP_X ]
		true [ gradient/spread: WRAP_MODE_TILE ]
	]

	;-- positions
	case [
		mode = linear [
			gradient/type: GRADIENT_LINEAR
			unless skip-pos [
				gradient/positions?: true
				pt: gradient/data
				point: as red-pair! positions
				pt/x: point/x pt/y: point/y
				pt: pt + 1
				point: as red-pair! (positions + 1)
				pt/x: point/x pt/y: point/y
				gradient-linear ctx gradient gradient/data gradient/data + 1
			]
		]
		any [ mode = radial mode = diamond ][
			gradient/type: either mode = radial [ GRADIENT_RADIAL ][ GRADIENT_DIAMOND ]
			unless skip-pos [
				gradient/positions?: true
				pt: gradient/data
				point: as red-pair! positions
				pt/x: point/x pt/y: point/y
				either mode = radial [
					value: positions + 1
					radius: as-integer get-float as red-integer! value
					pt: pt + 1
					if focal? [
						point: as red-pair! ( positions + 2 )
					]
					pt/x: point/x pt/y: point/y
					pt: pt + 1
					pt/x: radius
				][
					pt: pt + 1
					point: as red-pair! (positions + 1)
					pt/x: point/x pt/y: point/y
					pt: pt + 1
					either focal? [
						point: as red-pair! ( positions + 2 )
						pt/x: point/x
						pt/y: point/y
					][
						pt/x: INVALID_RADIUS
					]
				]
				gradient-radial-diamond ctx gradient gradient/data gradient/data + 1 pt/x
			]
		]
		true [ gradient/type: GRADIENT_NONE ]
	]
]

OS-set-clip: func [
	ctx		[draw-ctx!]
	u		[red-pair!]
	l		[red-pair!]
	rect?	[logic!]
	mode	[integer!]
	/local
		dc	[handle!]
		clip-mode [integer!]
][
	case [
		mode = replace	 [clip-mode: clip-replace ctx]
		mode = intersect [clip-mode: clip-intersect ctx]
		mode = union	 [clip-mode: clip-union ctx]
		mode = _xor		 [clip-mode: clip-xor ctx]
		mode = exclude	 [clip-mode: clip-diff ctx]
		true			 [clip-mode: clip-replace ctx]
	]
	either ctx/other/GDI+? [
		either rect? [
			GdipSetClipRectI
				ctx/graphics
				u/x
				u/y
				l/x - u/x
				l/y - u/y
				clip-mode
		][
			GdipSetClipPath
				ctx/graphics
				ctx/gp-path
				clip-mode
			GdipDeletePath ctx/gp-path
		]
	][
		dc: ctx/dc
		if rect? [
			BeginPath dc
			Rectangle dc u/x u/y l/x l/y
		]
		EndPath dc  ;-- a path has already been started
		SelectClipPath dc clip-mode
	]
]

OS-clip-end: func [
	ctx		[draw-ctx!]
][]

OS-matrix-rotate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	angle		[red-integer!]
	center		[red-pair!]
	/local
		brush		[integer!]
		gradient	[gradient!]
		pen?		[logic!]
		g			[integer!]
		cx			[float32!]
		cy			[float32!]
][
	ctx/other/GDI+?: yes
	either pen-fill <> -1 [
		;-- rotate pen or fill
		pen?: either pen-fill = pen [ true ][ false ]
		;-- gradient
		gradient: either pen? [ ctx/other/gradient-pen ][ ctx/other/gradient-fill ]
		gradient-rotate ctx gradient as-float angle/value
		;-- texture
		brush: check-texture ctx pen?
		texture-rotate as-float angle/value brush
	][
		;-- rotate figure
		g: ctx/graphics
		either angle <> as red-integer! center [
			either ctx/other/matrix-order = GDIPLUS_MATRIX_APPEND [
				cx: as float32! 0 - center/x
				cy: as float32! 0 - center/y
			][
				cx: as float32! center/x
				cy: as float32! center/y
			]
			GdipTranslateWorldTransform g cx cy ctx/other/matrix-order
			GdipRotateWorldTransform g get-float32 angle ctx/other/matrix-order
			GdipTranslateWorldTransform g (as float32! 0.0) - cx (as float32! 0.0) - cy ctx/other/matrix-order
		][
			GdipRotateWorldTransform g get-float32 angle ctx/other/matrix-order
		]
	]
]

OS-matrix-scale: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	center		[red-pair!]
	/local
		sy			[red-integer!]
		gradient	[gradient!]
		pen?		[logic!]
		brush		[integer!]
		g			[integer!]
		cx			[float32!]
		cy			[float32!]
][
	ctx/other/GDI+?: yes
	sy: sx + 1
	either pen-fill <> -1 [
		;-- scale pen or fill
		pen?: either pen-fill = pen [ true ][ false ]
		;-- gradient
		gradient: either pen? [ ctx/other/gradient-pen ][ ctx/other/gradient-fill ]
		gradient-scale ctx gradient as-float sx/value as-float sy/value
		;-- texture
		brush: check-texture ctx pen?
		texture-scale as-float sx/value as-float sy/value brush
	][
		;-- scale figure
		g: ctx/graphics
		either sy <> as red-integer! center [
			either ctx/other/matrix-order = GDIPLUS_MATRIX_APPEND [
				cx: as float32! 0 - center/x
				cy: as float32! 0 - center/y
			][
				cx: as float32! center/x
				cy: as float32! center/y
			]
			GdipTranslateWorldTransform g cx cy ctx/other/matrix-order
			GdipScaleWorldTransform g get-float32 sx get-float32 sy ctx/other/matrix-order
			GdipTranslateWorldTransform g (as float32! 0.0) - cx (as float32! 0.0) - cy ctx/other/matrix-order
		][
			GdipScaleWorldTransform g get-float32 sx get-float32 sy ctx/other/matrix-order
		]
	]
]

OS-matrix-translate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	xy			[red-pair!]
	/local
		gradient	[gradient!]
		pen?		[logic!]
		brush		[integer!]
		x y			[float32!]
		pt			[red-point2D!]
][
	ctx/other/GDI+?: yes
	GET_PAIR_XY(xy x y)
	either pen-fill <> -1 [
		;-- translate pen or fill
		pen?: either pen-fill = pen [ true ][ false ]
		;-- gradient
		gradient: either pen? [ ctx/other/gradient-pen ][ ctx/other/gradient-fill ]
		gradient-translate ctx gradient as-float x as-float y
		;-- texture
		brush: check-texture ctx pen?
		texture-translate as-float x as-float y brush
	][
		;-- translate figure
		GdipTranslateWorldTransform
			ctx/graphics
			x
			y
			ctx/other/matrix-order
	]
]

OS-matrix-skew: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	center		[red-pair!]
	/local
		sy			[red-integer!]
		xv			[float!]
		yv			[float!]
		m			[integer!]
		x			[float32!]
		y			[float32!]
		u			[float32!]
		z			[float32!]
		gradient	[gradient!]
		g			[integer!]
		cx			[float32!]
		cy			[float32!]
][
	sy: sx + 1
	xv: get-float sx
	yv: either all [
		sy <= center
		TYPE_OF(sy) = TYPE_PAIR
	][
		get-float sy
	][
		0.0
	]
	either pen-fill <> -1 [
		;-- skew pen or fill
		gradient: either pen-fill = pen [ ctx/other/gradient-pen ][ ctx/other/gradient-fill ]
		gradient-skew ctx gradient xv yv
	][
		;-- skew figure
		g: ctx/graphics
		if TYPE_OF(center) = TYPE_PAIR [
			either ctx/other/matrix-order = GDIPLUS_MATRIX_APPEND [
				cx: as float32! 0 - center/x
				cy: as float32! 0 - center/y
			][
				cx: as float32! center/x
				cy: as float32! center/y
			]
			GdipTranslateWorldTransform g cx cy ctx/other/matrix-order
		]
		m: 0
		u: as float32! 1.0
		z: as float32! 0.0
		x: as float32! tan degree-to-radians xv TYPE_TANGENT
		y: as float32! either yv = 0.0 [0.0][tan degree-to-radians yv TYPE_TANGENT]

		GdipCreateMatrix2 u y x u z z :m
		GdipMultiplyWorldTransform g m ctx/other/matrix-order
		GdipDeleteMatrix m
		if TYPE_OF(center) = TYPE_PAIR [
			GdipTranslateWorldTransform g (as float32! 0.0) - cx (as float32! 0.0) - cy ctx/other/matrix-order
		]
	]
]

OS-matrix-transform: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		rotate		[red-integer!]
		gradient	[gradient!]
		pen?		[logic!]
		brush		[integer!]
		center?		[logic!]
		g			[integer!]
		cx			[float32!]
		cy			[float32!]
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center

	either pen-fill <> -1 [
		;-- transform pen or fill
		pen?: either pen-fill = pen [ true ][ false ]
		;-- gradient
		gradient: either pen? [ ctx/other/gradient-pen ][ ctx/other/gradient-fill ]
		gradient-translate ctx gradient as-float translate/x as-float translate/y
		gradient-scale ctx gradient get-float scale get-float scale + 1
		gradient-rotate ctx gradient as-float rotate/value
		;-- texture
		brush: check-texture ctx pen?
		texture-translate as-float translate/x as-float translate/y brush
		texture-scale get-float scale get-float scale + 1 brush
		texture-rotate as-float rotate/value brush
	][
		;-- transform figure
		g: ctx/graphics
		if center? [
			either ctx/other/matrix-order = GDIPLUS_MATRIX_APPEND [
				cx: as float32! 0 - center/x
				cy: as float32! 0 - center/y
			][
				cx: as float32! center/x
				cy: as float32! center/y
			]
			GdipTranslateWorldTransform g cx cy ctx/other/matrix-order
		]
		either ctx/other/matrix-order = GDIPLUS_MATRIX_APPEND [
			GdipRotateWorldTransform g get-float32 rotate ctx/other/matrix-order
			GdipScaleWorldTransform g get-float32 scale get-float32 scale + 1 ctx/other/matrix-order
			GdipTranslateWorldTransform g as float32! translate/x as float32! translate/y ctx/other/matrix-order
		][
			GdipTranslateWorldTransform g as float32! translate/x as float32! translate/y ctx/other/matrix-order
			GdipScaleWorldTransform g get-float32 scale get-float32 scale + 1 ctx/other/matrix-order
			GdipRotateWorldTransform g get-float32 rotate ctx/other/matrix-order
		]
		if center? [
			GdipTranslateWorldTransform g (as float32! 0.0) - cx (as float32! 0.0) - cy ctx/other/matrix-order
		]
	]
]

OS-draw-state-push: func [ctx [draw-ctx!] state [draw-state!] /local s][
	s: 0
	GdipSaveGraphics ctx/graphics :s
	state/gstate: s
	state/pen-clr: ctx/pen-color
	state/brush-clr: ctx/brush-color
	state/pen-join: ctx/pen-join
	state/pen-cap: ctx/pen-cap
	state/pen?: ctx/pen?
	state/brush?: ctx/brush?
	state/a-pen?: ctx/alpha-pen?
	state/a-brush?: ctx/alpha-brush?
]

OS-draw-state-pop: func [ctx [draw-ctx!] state [draw-state!]][
	GdipRestoreGraphics ctx/graphics state/gstate
	ctx/pen-join: state/pen-join
	ctx/pen-cap: state/pen-cap
	OS-draw-pen ctx state/pen-clr not state/pen? state/a-pen?
	OS-draw-fill-pen ctx state/brush-clr not state/brush? state/a-brush?
]

OS-matrix-reset: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	/local
		gradient	[gradient!]
		pen?		[logic!]
		brush		[integer!]
][
	either pen-fill <> -1 [
		;-- reset matrix for pen or fill
		pen?: either pen-fill = pen [ true ][ false ]
		;-- gradient
		gradient: either pen? [ ctx/other/gradient-pen ][ ctx/other/gradient-fill ]
		gradient-transf-reset ctx gradient
		;-- texture
		brush: check-texture ctx pen?
		texture-reset-matrix brush
	][
		;-- reset matrix for figure
		GdipResetWorldTransform ctx/graphics
	]
	if ctx/scale-ratio <> as float32! 0.0 [
		GdipScaleWorldTransform ctx/graphics ctx/scale-ratio ctx/scale-ratio GDIPLUS_MATRIX_PREPEND
	]
]

OS-matrix-invert: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	/local
		m			[integer!]
		gradient	[gradient!]
		pen?		[logic!]
		brush		[integer!]
][
	m: ctx/gp-matrix
	if zero? m [
		GdipCreateMatrix :m
		ctx/gp-matrix: m
	]
	either pen-fill <> -1 [
		;-- invert matrix for pen or fill
		pen?: either pen-fill = pen [ true ][ false ]
		;-- gradient
		gradient: either pen? [ ctx/other/gradient-pen ][ ctx/other/gradient-fill ]
		gradient-invert-matrix ctx gradient
		;-- texture
		brush: check-texture ctx pen?
		texture-invert-matrix ctx brush
	][
		;-- invert matrix for figure
		GdipGetWorldTransform ctx/graphics m
		GdipInvertMatrix m
		GdipSetWorldTransform ctx/graphics m
	]
]

OS-matrix-set: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	blk			[red-block!]
	/local
		m			[integer!]
		val			[red-integer!]
		gradient	[gradient!]
		pen?		[logic!]
		brush		[integer!]
][
	m: 0
	val: as red-integer! block/rs-head blk
	GdipCreateMatrix2
		get-float32 val
		get-float32 val + 1
		get-float32 val + 2
		get-float32 val + 3
		get-float32 val + 4
		get-float32 val + 5
		:m
	either pen-fill <> -1 [
		;-- set matrix for pen or fill
		pen?: either pen-fill = pen [ true ][ false ]
		;-- gradient
		gradient: either pen? [ ctx/other/gradient-pen ][ ctx/other/gradient-fill ]
		gradient-set-matrix ctx gradient m
		;-- texture
		brush: check-texture ctx pen?
		texture-set-matrix m brush
	][
		;-- set matrix for figure
		GdipMultiplyWorldTransform ctx/graphics m ctx/other/matrix-order
	]
	GdipDeleteMatrix m
]

OS-set-matrix-order: func [
	ctx		[draw-ctx!]
	order	[integer!]
][
	case [
		order = _append [ ctx/other/matrix-order: GDIPLUS_MATRIX_APPEND ]
		order = prepend [ ctx/other/matrix-order: GDIPLUS_MATRIX_PREPEND ]
		true [ ctx/other/matrix-order: GDIPLUS_MATRIX_PREPEND ]
	]
]

OS-draw-shadow: func [
	ctx		[draw-ctx!]
	offset	[red-pair!]
	blur	[integer!]
	spread	[integer!]
	color	[integer!]
	inset?	[logic!]
][0]