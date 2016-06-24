Red/System [
	Title:	"Windows Draw dialect backend"
	Author: "Nenad Rakocevic"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

modes: declare struct! [
	pen				[handle!]
	brush			[handle!]
	pen-join		[integer!]
	pen-cap			[integer!]
	pen-width		[integer!]
	pen-style		[integer!]
	pen-color		[integer!]								;-- 00bbggrr format
	brush-color		[integer!]								;-- 00bbggrr format
	font-color		[integer!]
	bitmap			[handle!]
	graphics		[integer!]								;-- gdiplus graphics
	gp-pen			[integer!]								;-- gdiplus pen
	gp-pen-saved	[integer!]
	gp-brush		[integer!]								;-- gdiplus brush
	gp-font			[integer!]								;-- gdiplus font
	gp-font-brush	[integer!]
	pen?			[logic!]
	brush?			[logic!]
	on-image?		[logic!]								;-- drawing on image?
	alpha-pen?		[logic!]
	alpha-brush?	[logic!]
	font-color?		[logic!]
]

paint: declare tagPAINTSTRUCT


max-colors: 256												;-- max number of colors for gradient
max-edges:  1000											;-- max number of edges for a polygone
edges: as tagPOINT allocate max-edges * (size? tagPOINT)	;-- polygone edges buffer
colors: as int-ptr! allocate 2 * max-colors * (size? integer!)
colors-pos: as pointer! [float32!] colors + max-colors

anti-alias?: no
GDI+?: no

update-gdiplus-font-color: func [color [integer!] /local brush [integer!]][
	if modes/font-color <> color [
		unless zero? modes/gp-font-brush [
			GdipDeleteBrush modes/gp-font-brush
			modes/gp-font-brush: 0
		]
		modes/font-color: color
		;-- work around for drawing text on transparent background
		;-- http://stackoverflow.com/questions/5647322/gdi-font-rendering-especially-in-layered-windows
		if color >>> 24 = 0 [color: 1 << 24 or color]
		brush: 0
		GdipCreateSolidFill to-gdiplus-color color :brush
		modes/gp-font-brush: brush
	]
]

update-gdiplus-font: func [dc [handle!] /local font [integer!]][
	font: 0
	unless zero? modes/gp-font [GdipDeleteFont modes/gp-font]
	GdipCreateFontFromDC as-integer dc :font
	modes/gp-font: font
]

update-gdiplus-modes: func [
	dc [handle!]
	/local
		handle [integer!]
][
	either modes/pen? [
		either zero? modes/gp-pen-saved [
			handle: modes/gp-pen
			GdipSetPenColor handle to-gdiplus-color modes/pen-color
			GdipSetPenWidth handle as float32! integer/to-float modes/pen-width
			if modes/pen-join <> -1 [
				OS-draw-line-join dc modes/pen-join
			]

			if modes/pen-cap <> -1 [
				OS-draw-line-cap dc modes/pen-cap
			]
		][
			modes/gp-pen: modes/gp-pen-saved
			modes/gp-pen-saved: 0
		]
	][
		modes/gp-pen-saved: modes/gp-pen
		modes/gp-pen: 0
	]

	handle: 0
	unless zero? modes/gp-brush [
		GdipDeleteBrush modes/gp-brush
		modes/gp-brush: 0
	]
	if modes/brush? [
		GdipCreateSolidFill to-gdiplus-color modes/brush-color :handle
		modes/gp-brush: handle
	]
]

update-pen: func [
	dc		[handle!]
	/local
		mode  [integer!]
		cap   [integer!]
		join  [integer!]
		pen   [handle!]
		brush [tagLOGBRUSH]
][
	mode: 0
	unless null? modes/pen [DeleteObject modes/pen]
	either modes/pen? [
		cap: modes/pen-cap
		join: modes/pen-join
		modes/pen: either all [join = -1 cap = -1] [
			pen: CreatePen modes/pen-style modes/pen-width modes/pen-color
			pen
		][
			if join <> -1 [
				mode: case [
					join = miter		[PS_JOIN_MITER]
					join = miter-bevel [PS_JOIN_MITER]
					join = _round		[PS_JOIN_ROUND]
					join = bevel		[PS_JOIN_BEVEL]
					true				[PS_JOIN_MITER]
				]
			]
			if cap <> -1 [
				mode: mode or case [
					cap = flat		[PS_ENDCAP_FLAT]
					cap = square		[PS_ENDCAP_SQUARE]
					cap = _round		[PS_ENDCAP_ROUND]
					true				[PS_ENDCAP_FLAT]
				]
			]
			brush: declare tagLOGBRUSH
			brush/lbStyle: BS_SOLID
			brush/lbColor: modes/pen-color
			pen: ExtCreatePen
				PS_GEOMETRIC or modes/pen-style or mode
				modes/pen-width
				brush
				0
				null
			pen
		]
	][
		pen: GetStockObject NULL_PEN
		modes/pen: null
	]
	SelectObject dc pen
]

update-modes: func [
	dc [handle!]
	/local
		handle	[handle!]
][
	either GDI+? [
		update-gdiplus-modes dc
	][
		update-pen dc

		unless null? modes/brush [DeleteObject modes/brush]
		modes/brush: either modes/brush? [
			handle: CreateSolidBrush modes/brush-color
			handle
		][
			handle: GetStockObject NULL_BRUSH
			null
		]
		SelectObject dc handle
	]
]

draw-begin: func [
	hWnd		[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	paint?		[logic!]
	return: 	[handle!]
	/local
		dc		 [handle!]
		rect	 [RECT_STRUCT]
		width	 [integer!]
		height	 [integer!]
		hBitmap  [handle!]
		hBackDC  [handle!]
		graphics [integer!]
][
	modes/pen:			null
	modes/brush:		null
	modes/pen-width:	1
	modes/pen-style:	PS_SOLID
	modes/pen-color:	0						;-- default: black
	modes/pen-join:		-1
	modes/pen-cap:		-1
	modes/brush-color:	-1
	modes/font-color:	-1
	modes/gp-brush:		0
	modes/gp-pen:		0
	modes/gp-pen-saved: 0
	modes/gp-font:		0
	modes/gp-font-brush: 0
	modes/on-image?:	no
	modes/pen?:			yes
	modes/brush?:		no
	modes/alpha-pen?:	no
	modes/alpha-brush?:	no
	modes/font-color?:	no
	dc:					null

	rect: declare RECT_STRUCT
	either null? hWnd [
		modes/on-image?: yes
		either on-graphic? [
			graphics: as-integer img
		][
			graphics: 0
			OS-image/GdipGetImageGraphicsContext as-integer img/node :graphics
		]
		dc: CreateCompatibleDC hScreen
		SelectObject dc default-font
		SetTextColor dc modes/pen-color
		update-gdiplus-font-color modes/pen-color
	][
		dc: either paint? [BeginPaint hWnd paint][hScreen]
		GetClientRect hWnd rect
		width: rect/right - rect/left
		height: rect/bottom - rect/top
		hBitmap: CreateCompatibleBitmap dc width height
		hBackDC: CreateCompatibleDC dc
		SelectObject hBackDC hBitmap
		modes/bitmap: hBitmap

		dc: hBackDC

		SetArcDirection dc AD_CLOCKWISE
		SetBkMode dc BK_TRANSPARENT
		SelectObject dc GetStockObject NULL_BRUSH

		render-base hWnd dc

		graphics: 0
		GdipCreateFromHDC dc :graphics	
	]
	modes/graphics:	graphics
	GdipCreatePen1
		to-gdiplus-color modes/pen-color
		as float32! integer/to-float modes/pen-width
		GDIPLUS_UNIT_PIXEL
		:graphics
	modes/gp-pen: graphics
	OS-draw-anti-alias dc yes
	update-gdiplus-font dc
	dc
]

draw-end: func [
	dc			[handle!]
	hWnd		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	paint?		[logic!]
	/local
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		bitmap	[integer!]
		old-dc	[integer!]
][
	rect: declare RECT_STRUCT
	if paint? [
		GetClientRect hWnd rect
		width: rect/right - rect/left
		height: rect/bottom - rect/top
		BitBlt paint/hdc 0 0 width height dc 0 0 SRCCOPY
	]

	unless any [on-graphic? zero? modes/graphics][GdipDeleteGraphics modes/graphics]
	unless zero? modes/gp-pen	[GdipDeletePen modes/gp-pen]
	unless zero? modes/gp-pen-saved	[GdipDeletePen modes/gp-pen-saved]
	unless zero? modes/gp-brush	[GdipDeleteBrush modes/gp-brush]
	unless zero? modes/gp-font-brush [GdipDeleteBrush modes/gp-font-brush]
	unless zero? modes/gp-font	[GdipDeleteFont modes/gp-font]
	unless null? modes/pen		[DeleteObject modes/pen]
	unless null? modes/brush	[DeleteObject modes/brush]

	unless modes/on-image? [
		DeleteObject modes/bitmap
	]
	either cache? [
		old-dc: GetWindowLong hWnd wc-offset - 4
		unless zero? old-dc [DeleteDC as handle! old-dc]
		SetWindowLong hWnd wc-offset - 4 as-integer dc
	][
		DeleteDC dc
	]
	if all [hWnd <> null paint?][EndPaint hWnd paint]
]

to-gdiplus-color: func [
	color	[integer!]
	return: [integer!]
	/local
		red   [integer!]
		green [integer!]
		blue  [integer!]
		alpha [integer!]
][
	red: color and FFh << 16
	green: color and FF00h
	blue: color >> 16 and FFh
	alpha: (255 - (color >>> 24)) << 24
	red or green or blue or alpha
]

OS-draw-anti-alias: func [
	dc	 [handle!]
	on? [logic!]
][
	anti-alias?: on?
	either on? [
		GDI+?: yes
		GdipSetSmoothingMode modes/graphics GDIPLUS_ANTIALIAS
		GdipSetTextRenderingHint modes/graphics TextRenderingHintAntiAliasGridFit
	][
		GDI+?: no
		if modes/on-image? [anti-alias?: yes GDI+?: yes]			;-- always use GDI+ to draw on image
		GdipSetSmoothingMode modes/graphics GDIPLUS_HIGHSPPED
		GdipSetTextRenderingHint modes/graphics TextRenderingHintSystemDefault
	]
	update-modes dc
]

OS-draw-line: func [
	dc	   [handle!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt		[tagPOINT]
		nb		[integer!]
		pair	[red-pair!]
][
	pt: edges
	pair:  point
	nb:	   0
	
	while [all [pair <= end nb < max-edges]][
		pt/x: pair/x
		pt/y: pair/y
		nb: nb + 1
		pt: pt + 1
		pair: pair + 1	
	]
	either GDI+? [
		GdipDrawLinesI modes/graphics modes/gp-pen edges nb
	][
		Polyline dc edges nb
	]
]

OS-draw-pen: func [
	dc	   [handle!]
	color  [integer!]									;-- 00bbggrr format
	off?	[logic!]
	alpha? [logic!]
][
	modes/alpha-pen?: alpha?
	GDI+?: any [alpha? anti-alias? modes/alpha-brush?]

	modes/pen?: not off?
	either modes/pen-color <> color [
		modes/pen-color: color
		update-modes dc
	][
		unless GDI+? [update-modes dc]
	]
	unless modes/font-color? [
		if GDI+? [update-gdiplus-font-color color]
		unless modes/on-image? [SetTextColor dc color]
	]
]

OS-draw-fill-pen: func [
	dc	   [handle!]
	color  [integer!]									;-- 00bbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	modes/alpha-brush?: alpha?
	GDI+?: any [alpha? anti-alias? modes/alpha-pen?]

	modes/brush?: not off?
	either any [
		modes/brush-color <> color
		modes/gp-brush <> 0								;-- always update brush in gdi+ mode
	][
		modes/brush-color: color
		update-modes dc
	][
		unless GDI+? [update-modes dc]
	]
]

OS-draw-line-width: func [
	dc	  [handle!]
	width [red-integer!]
][
	if modes/pen-width <> width/value [
		modes/pen-width: width/value
		update-modes dc
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
	angle90: as float32! 90.0
	GdipResetPath path
	GdipAddPathArcI path x y diameter diameter as float32! 180.0 angle90
	x: x + (width - diameter)
	GdipAddPathArcI path x y diameter diameter as float32! 270.0 angle90
	y: y + (height - diameter)
	GdipAddPathArcI path x y diameter diameter as float32! 0.0 angle90
	x: x - (width - diameter)
	GdipAddPathArcI path x y diameter diameter angle90 angle90
	GdipClosePathFigure path
]

gdiplus-draw-roundbox: func [
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
	radius	[integer!]
	fill?	[logic!]
	/local
		path	[integer!]
][
	path: 0
	GdipCreatePath GDIPLUS_FILLMODE_ALTERNATE :path
	gdiplus-roundrect-path path x y width height radius
	if fill? [
		GdipFillPath modes/graphics modes/gp-brush path
	]
	GdipDrawPath modes/graphics modes/gp-pen path
	GdipDeletePath path
]

OS-draw-box: func [
	dc	  [handle!]
	upper [red-pair!]
	lower [red-pair!]
	/local
		t	   [integer!]
		radius [red-integer!]
		rad	   [integer!]
][
	either TYPE_OF(lower) = TYPE_INTEGER [
		radius: as red-integer! lower
		lower:  lower - 1
		rad: radius/value * 2
		either GDI+? [
			gdiplus-draw-roundbox
				upper/x
				upper/y
				lower/x - upper/x
				lower/y - upper/y
				rad
				modes/brush?
		][
			RoundRect dc upper/x upper/y lower/x + 1 lower/y + 1 rad rad
		]
	][
		either GDI+? [
			if upper/x > lower/x [t: upper/x upper/x: lower/x lower/x: t]
			if upper/y > lower/y [t: upper/y upper/y: lower/y lower/y: t]
			unless zero? modes/gp-brush [				;-- fill rect
				GdipFillRectangleI
					modes/graphics
					modes/gp-brush
					upper/x
					upper/y
					lower/x - upper/x
					lower/y - upper/y
			]
			GdipDrawRectangleI
				modes/graphics
				modes/gp-pen
				upper/x
				upper/y
				lower/x - upper/x
				lower/y - upper/y
		][
			Rectangle dc upper/x upper/y lower/x + 1 lower/y + 1
		]
	]
]

OS-draw-triangle: func [
	dc	  [handle!]
	start [red-pair!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
][
	point: edges
	
	point/x: start/x									;-- 1st point
	point/y: start/y
	point: point + 1
	
	pair: start + 1
	point/x: pair/x										;-- 2nd point
	point/y: pair/y
	point: point + 1
	
	pair: pair + 1
	point/x: pair/x										;-- 3rd point
	point/y: pair/y
	point: point + 1
	
	point/x: start/x									;-- close the triangle
	point/y: start/y

	either GDI+? [
		if modes/brush? [
			GdipFillPolygonI
				modes/graphics
				modes/gp-brush
				edges
				4
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI modes/graphics modes/gp-pen edges 4
	][
		either modes/brush? [
			Polygon dc edges 4
		][
			Polyline dc edges 4
		]
	]
]

OS-draw-polygon: func [
	dc	  [handle!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		nb	  [integer!]
][
	point: edges
	pair:  start
	nb:	   0
	
	while [all [pair <= end nb < max-edges]][
		point/x: pair/x
		point/y: pair/y
		nb: nb + 1
		point: point + 1
		pair: pair + 1	
	]
	;if nb = max-edges [fire error]
	
	point/x: start/x									;-- close the polygon
	point/y: start/y

	either GDI+? [
		if modes/brush? [
			GdipFillPolygonI
				modes/graphics
				modes/gp-brush
				edges
				nb + 1
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI modes/graphics modes/gp-pen edges nb + 1
	][
		either modes/brush? [
			Polygon dc edges nb + 1
		][
			Polyline dc edges nb + 1
		]
	]
]

OS-draw-spline: func [
	dc		[handle!]
	start	[red-pair!]
	end		[red-pair!]
	closed? [logic!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		nb	  [integer!]
][
	point: edges
	pair:  start
	nb:	   0
	
	while [all [pair <= end nb < max-edges]][
		point/x: pair/x
		point/y: pair/y
		nb: nb + 1
		point: point + 1
		pair: pair + 1	
	]
	;if nb = max-edges [fire error]

	unless GDI+? [update-gdiplus-modes dc]					;-- force to use GDI+

	if modes/brush? [
		GdipFillClosedCurveI
			modes/graphics
			modes/gp-brush
			edges
			nb
			GDIPLUS_FILLMODE_ALTERNATE
	]
	either closed? [
		GdipDrawClosedCurveI modes/graphics modes/gp-pen edges nb
	][
		GdipDrawCurveI modes/graphics modes/gp-pen edges nb
	]
]

do-draw-ellipse: func [
	dc		[handle!]
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
][
	either GDI+? [
		if modes/brush? [
			GdipFillEllipseI
				modes/graphics
				modes/gp-brush
				x
				y
				width
				height
		]
		GdipDrawEllipseI
			modes/graphics
			modes/gp-pen
			x
			y
			width
			height
	][	
		Ellipse dc x y x + width + 1 y + height + 1
	]
]

OS-draw-circle: func [
	dc	   [handle!]
	center [red-pair!]
	radius [red-integer!]
	/local
		rad-x [integer!]
		rad-y [integer!]
		w	  [integer!]
		h	  [integer!]
		f	  [red-float!]
][
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
			rad-x: float/to-integer f/value + 0.75
			rad-y: rad-x
			w: float/to-integer f/value * 2.0
			h: w
		][
			rad-y: float/to-integer f/value + 0.75
			h: float/to-integer f/value * 2.0
			f: f - 1
			rad-x: float/to-integer f/value + 0.75
			w: float/to-integer f/value * 2.0
		]
	]
	do-draw-ellipse dc center/x - rad-x center/y - rad-y w h
]

OS-draw-ellipse: func [
	dc	  	 [handle!]
	upper	 [red-pair!]
	diameter [red-pair!]
][
	do-draw-ellipse dc upper/x upper/y diameter/x diameter/y
]

OS-draw-font: func [
	dc		[handle!]
	font	[red-object!]
	/local
		vals  [red-value!]
		state [red-block!]
		int   [red-integer!]
		color [red-tuple!]
		hFont [handle!]
][
	vals: object/get-values font
	state: as red-block! vals + FONT_OBJ_STATE
	color: as red-tuple! vals + FONT_OBJ_COLOR
	
	hFont: as handle! either TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		int/value
	][
		make-font as red-object! none-value font
	]

	SelectObject dc hFont
	modes/font-color?: either TYPE_OF(color) = TYPE_TUPLE [
		SetTextColor dc color/array1
		if modes/on-image? [update-gdiplus-font-color color/array1]
		yes
	][
		no
	]
	if modes/on-image? [update-gdiplus-font dc]
]

OS-draw-text: func [
	dc		[handle!]
	pos		[red-pair!]
	text	[red-string!]
	/local
		str		[c-string!]
		len		[integer!]
		rect	[RECT_STRUCT_FLOAT32]
][
	str: unicode/to-utf16 text
	len: string/rs-length? text
	either modes/on-image? [
		rect: declare RECT_STRUCT_FLOAT32
		rect/x: as float32! integer/to-float pos/x
		rect/y: as float32! integer/to-float pos/y
		rect/width: as float32! 0.0
		rect/height: as float32! 0.0
		GdipDrawString modes/graphics str len modes/gp-font rect 0 modes/gp-font-brush
	][
		ExtTextOut dc pos/x pos/y ETO_CLIPPED null str len null
	]
]

OS-draw-arc: func [
	dc	   [handle!]
	center [red-pair!]
	end	   [red-value!]
	/local
		radius		[red-pair!]
		angle		[red-integer!]
		rad-x		[integer!]
		rad-y		[integer!]
		start-x		[integer!]
		start-y 	[integer!]
		end-x		[integer!]
		end-y		[integer!]
		angle-begin [float!]
		angle-len	[float!]
		rad-x-float	[float!]
		rad-y-float	[float!]
		rad-x-2		[float!]
		rad-y-2		[float!]
		rad-x-y		[float!]
		tan-2		[float!]
		closed?		[logic!]
][
	radius: center + 1
	rad-x: radius/x
	rad-y: radius/y
	angle: as red-integer! radius + 1
	angle-begin: integer/to-float angle/value
	angle: angle + 1
	angle-len: integer/to-float angle/value

	closed?: angle < end

	either GDI+? [
		either closed? [
			if modes/brush? [
				GdipFillPieI
					modes/graphics
					modes/gp-brush
					center/x - rad-x
					center/y - rad-y
					rad-x << 1
					rad-y << 1
					as float32! angle-begin
					as float32! angle-len
			]
			GdipDrawPieI
				modes/graphics
				modes/gp-pen
				center/x - rad-x
				center/y - rad-y
				rad-x << 1
				rad-y << 1
				as float32! angle-begin
				as float32! angle-len
		][
			GdipDrawArcI
				modes/graphics
				modes/gp-pen
				center/x - rad-x
				center/y - rad-y
				rad-x << 1
				rad-y << 1
				as float32! angle-begin
				as float32! angle-len
		]
	][
		rad-x-float: integer/to-float rad-x
		rad-y-float: integer/to-float rad-y

		either rad-x = rad-y [				;-- circle
			start-x: center/x + float/to-integer rad-x-float * (system/words/cos degree-to-radians angle-begin TYPE_COSINE)
			start-y: center/y + float/to-integer rad-y-float * (system/words/sin degree-to-radians angle-begin TYPE_SINE)
			end-x:	 center/x + float/to-integer rad-x-float * (system/words/cos degree-to-radians angle-begin + angle-len TYPE_COSINE)
			end-y:	 center/y + float/to-integer rad-y-float * (system/words/sin degree-to-radians angle-begin + angle-len TYPE_SINE)
		][
			rad-x-y: rad-x-float * rad-y-float
			rad-x-2: rad-x-float * rad-x-float
			rad-y-2: rad-y-float * rad-y-float
			tan-2: system/words/tan degree-to-radians angle-begin TYPE_TANGENT
			tan-2: tan-2 * tan-2
			start-x: float/to-integer rad-x-y / (sqrt rad-x-2 * tan-2 + rad-y-2)
			start-y: float/to-integer rad-x-y / (sqrt rad-y-2 / tan-2 + rad-x-2)
			if all [angle-begin > 90.0  angle-begin < 270.0][start-x: 0 - start-x]
			if all [angle-begin > 180.0 angle-begin < 360.0][start-y: 0 - start-y]
			start-x: center/x + start-x
			start-y: center/y + start-y
			angle-begin: angle-begin + angle-len
			tan-2: system/words/tan degree-to-radians angle-begin TYPE_TANGENT
			tan-2: tan-2 * tan-2
			end-x: float/to-integer rad-x-y / (sqrt rad-x-2 * tan-2 + rad-y-2)
			end-y: float/to-integer rad-x-y / (sqrt rad-y-2 / tan-2 + rad-x-2)
			if all [angle-begin > 90.0  angle-begin < 270.0][end-x: 0 - end-x]
			if all [angle-begin > 180.0 angle-begin < 360.0][end-y: 0 - end-y]
			end-x: center/x + end-x
			end-y: center/y + end-y
		]

		either closed? [
			Pie
				dc
				center/x - rad-x
				center/y - rad-y
				center/x + rad-x + 1
				center/y + rad-y + 1
				start-x
				start-y
				end-x
				end-y
		][
			Arc
				dc
				center/x - rad-x
				center/y - rad-y
				center/x + rad-x + 1
				center/y + rad-y + 1
				start-x
				start-y
				end-x
				end-y
		]
	]
]

OS-draw-curve: func [
	dc	  [handle!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		p2	  [red-pair!]
		p3	  [red-pair!]
		nb	  [integer!]
		count [integer!]
][
	point: edges
	pair:  start
	nb:	   0
	count: (as-integer end - pair) >> 4 + 1

	either count = 3 [			;-- p0, p1, p2 -> p0, (p0 + 2p1) / 3, (2p1 + p2) / 3, p2
		point/x: pair/x
		point/y: pair/y
		point: point + 1
		p2: pair + 1
		p3: pair + 2
		point/x: p2/x << 1 + pair/x / 3
		point/y: p2/y << 1 + pair/y / 3
		point: point + 1
		point/x: p2/x << 1 + p3/x / 3
		point/y: p2/y << 1 + p3/y / 3
		point: point + 1
		point/x: end/x
		point/y: end/y
	][
		until [
			point/x: pair/x
			point/y: pair/y
			nb: nb + 1
			point: point + 1
			pair: pair + 1
			nb = 4
		]
	]

	either GDI+? [
		GdipDrawBeziersI modes/graphics modes/gp-pen edges 4
	][
		PolyBezier dc edges 4
	]
]

OS-draw-line-join: func [
	dc	  [handle!]
	style [integer!]
	/local
		mode  [integer!]
][
	mode: 0
	modes/pen-join: style
	either GDI+? [
		case [
			style = miter		[mode: GDIPLUS_MITER]
			style = miter-bevel [mode: GDIPLUS_MITERCLIPPED]
			style = _round		[mode: GDIPLUS_ROUND]
			style = bevel		[mode: GDIPLUS_BEVEL]
			true				[mode: GDIPLUS_MITER]
		]
		GdipSetPenLineJoin modes/gp-pen mode
	][
		update-pen dc PEN_LINE_JOIN
	]
]
	
OS-draw-line-cap: func [
	dc	  [handle!]
	style [integer!]
	/local
		mode  [integer!]
][
	mode: 0
	modes/pen-cap: style
	either GDI+? [
		case [
			style = flat		[mode: GDIPLUS_LINECAPFLAT]
			style = square		[mode: GDIPLUS_LINECAPSQUARE]
			style = _round		[mode: GDIPLUS_LINECAPROUND]
			true				[mode: GDIPLUS_LINECAPFLAT]
		]
		GdipSetPenStartCap modes/gp-pen mode
		GdipSetPenEndCap modes/gp-pen mode
	][
		update-pen dc PEN_LINE_CAP
	]
]

OS-draw-image: func [
	dc			[handle!]
	image		[red-image!]
	start		[red-pair!]
	end			[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	pattern		[red-word!]
	/local
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
		pts		[tagPOINT]
][
	either null? start [x: 0 y: 0][x: start/x y: start/y]
	case [
		start = end [
			width:  IMAGE_WIDTH(image/size)
			height: IMAGE_HEIGHT(image/size)
		]
		start + 1 = end [					;-- two control points
			width: end/x - x
			height: end/y - y
		]
		start + 2 = end [					;-- three control points
			pts: edges
			loop 3 [
				pts/x: start/x
				pts/y: start/y
				pts: pts + 1
				start: start + 1
			]
			GdipDrawImagePointsI modes/graphics as-integer image/node edges 3
			exit
		]
		true [0]							;@@ TBD four control points
	]
	GdipDrawImageRectRectI
		modes/graphics
		as-integer image/node
		x y width height
		0 0 IMAGE_WIDTH(image/size) IMAGE_HEIGHT(image/size)
		GDIPLUS_UNIT_PIXEL
		0 0 0
]

OS-draw-grad-pen: func [
	dc			[handle!]
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
		pos		[pointer! [float32!]]
		last-p	[pointer! [float32!]]
		n		[integer!]
		delta	[float!]
		p		[float!]
		rotate? [logic!]
		scale?	[logic!]
][
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
			TYPE_INTEGER	[p: integer/to-float int/value]
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

	pt: edges
	color: colors + 1
	pos: colors-pos + 1
	delta: 1.0 / integer/to-float count - 1
	p: 0.0
	head: as red-value! int
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		color/value: to-gdiplus-color clr/array1
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
		colors-pos/value: as float32! 0.0
		colors/value: color/value
		color: colors
		pos: colors-pos
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
		GdipCreateLineBrushI edges pt color/1 color/count 0 :brush
		GdipSetLinePresetBlend brush color pos count
		if rotate? [GdipRotateLineTransform brush angle GDIPLUS_MATRIXORDERAPPEND]
		if scale? [GdipScaleLineTransform brush sx sy GDIPLUS_MATRIXORDERAPPEND]
	][
		GdipCreatePath GDIPLUS_FILLMODE_ALTERNATE :brush
		n: stop - start
		stop: n * 2
		case [
			type = radial  [GdipAddPathEllipseI brush x - n y - n stop stop]
			type = diamond [GdipAddPathRectangleI brush x - n y - n stop stop]
		]

		GdipCreateMatrix :n
		if rotate? [GdipRotateMatrix n angle GDIPLUS_MATRIXORDERPREPEND]
		if scale?  [GdipScaleMatrix n sx sy GDIPLUS_MATRIXORDERPREPEND]
		scale?: any [rotate? scale?]
		if scale? [							;@@ transform path will move it
			GdipTransformPath brush n
			GdipDeleteMatrix n
		]

		n: brush
		GdipCreatePathGradientFromPath n :brush
		GdipDeletePath n
		GdipSetPathGradientCenterColor brush color/value
		reverse-int-array color count
		GdipSetPathGradientPresetBlend brush color pos count

		if any [							;@@ move the shape back to the right position
			all [type = radial scale?]
			all [type = diamond rotate?]
		][
			GdipGetPathGradientCenterPointI brush pt
			sx: as float32! integer/to-float x - pt/x
			sy: as float32! integer/to-float y - pt/y
			GdipTranslatePathGradientTransform brush sx sy GDIPLUS_MATRIXORDERAPPEND
		]
	]

	GDI+?: yes
	either brush? [
		unless zero? modes/gp-brush	[GdipDeleteBrush modes/gp-brush]
		modes/brush?: yes
		modes/gp-brush: brush
	][
		GdipSetPenBrushFill modes/gp-pen brush
	]
]