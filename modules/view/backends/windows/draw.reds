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
	pen		  	[handle!]
	brush	 	[handle!]
	font		[handle!]
	pen-join	[integer!]
	pen-cap		[integer!]
	pen-width	[integer!]
	pen-style	[integer!]
	pen-color	[integer!]								;-- 00bbggrr format
	brush-color [integer!]								;-- 00bbggrr format
	bitmap		[handle!]
	saved-dc	[handle!]
	saved-pen	[handle!]
	saved-brush [handle!]
	saved-font	[handle!]
	graphics	[integer!]								;-- gdiplus graphics
	g-pen		[integer!]								;-- gdiplus pen
	g-brush		[integer!]								;-- gdiplus brush
]

paint: declare tagPAINTSTRUCT

max-edges: 1000												;-- max number of edges for a polygone
edges: as tagPOINT allocate max-edges * (size? tagPOINT)	;-- polygone edges buffer

anti-alias?: no

update-gdiplus-modes: func [
	dc [handle!]
	/local
		handle [integer!]
][
	unless zero? modes/g-pen [GdipDeletePen modes/g-pen]
	handle: 0
	GdipCreatePen1
		to-gdiplus-color modes/pen-color
		as float32! integer/to-float modes/pen-width
		GDIPLUS_UNIT_WORLD
		:handle
	modes/g-pen: handle

	if modes/pen-join <> -1 [
		OS-draw-line-join dc modes/pen-join
	]

	if modes/pen-cap <> -1 [
		OS-draw-line-cap dc modes/pen-cap
	]

	handle: 0
	unless zero? modes/g-brush [
		GdipDeleteBrush modes/g-brush
		modes/g-brush: 0
	]
	if modes/brush-color <> -1 [
		GdipCreateSolidFill to-gdiplus-color modes/brush-color :handle
		modes/g-brush: handle
	]
]

update-pen: func [
	dc		[handle!]
	type	[integer!]
	/local
		style [integer!]
		mode  [integer!]
		brush [tagLOGBRUSH]
][
	mode: 0
	unless null? modes/pen [DeleteObject modes/pen]
	either type < PEN_LINE_CAP [
		modes/pen: CreatePen modes/pen-style modes/pen-width modes/pen-color
	][
		if modes/pen-join <> -1 [
			style: modes/pen-join
			mode: case [
				style = miter		[PS_JOIN_MITER]
				style = miter-bevel [PS_JOIN_MITER]
				style = _round		[PS_JOIN_ROUND]
				style = bevel		[PS_JOIN_BEVEL]
				true				[PS_JOIN_MITER]
			]
		]
		if modes/pen-cap <> -1 [
			style: modes/pen-cap
			mode: mode or case [
				style = flat		[PS_ENDCAP_FLAT]
				style = square		[PS_ENDCAP_SQUARE]
				style = _round		[PS_ENDCAP_ROUND]
				true				[PS_ENDCAP_FLAT]
			]
		]
		brush: declare tagLOGBRUSH
		brush/lbStyle: BS_SOLID
		brush/lbColor: modes/pen-color
		modes/pen: ExtCreatePen
			PS_GEOMETRIC or modes/pen-style or mode
			modes/pen-width
			brush
			0
			null
	]
	SelectObject dc modes/pen
]

update-modes: func [
	dc [handle!]
	/local
		handle	[integer!]
		type	[integer!]
][
	either anti-alias? [
		update-gdiplus-modes dc
	][
		type: either all [
			modes/pen-join = -1
			modes/pen-cap = -1
		][PEN_COLOR][PEN_LINE_CAP]
		update-pen dc type

		unless null? modes/brush [DeleteObject modes/brush]
		modes/brush: either modes/brush-color = -1 [
			GetStockObject NULL_BRUSH
		][
			CreateSolidBrush modes/brush-color
		]
		SelectObject dc modes/brush
	]
]

draw-begin: func [
	hWnd	[handle!]
	img		[red-image!]
	return: [handle!]
	/local
		dc		 [handle!]
		rect	 [RECT_STRUCT]
		width	 [integer!]
		height	 [integer!]
		hBitmap  [handle!]
		hBackDC  [handle!]
		graphics [integer!]
][
	rect: declare RECT_STRUCT
	either null? hWnd [
		dc: hScreen
		width: IMAGE_WIDTH(img/size)
		height: IMAGE_HEIGHT(img/size)
		graphics: 0
		GdipCreateHBITMAPFromBitmap as-integer img/node :graphics 0
		hBitmap: as handle! graphics
	][
		dc: BeginPaint hWnd paint
		GetClientRect hWnd rect
		width: rect/right - rect/left
		height: rect/bottom - rect/top
		hBitmap: CreateCompatibleBitmap dc width height
	]
	hBackDC: CreateCompatibleDC dc
	SelectObject hBackDC hBitmap
	modes/saved-dc: dc
	modes/bitmap: hBitmap

	dc: hBackDC

	unless null? hWnd [paint-background hWnd dc]

	SetArcDirection dc AD_CLOCKWISE
	SetBkMode dc BK_TRANSPARENT

	modes/saved-pen:	SelectObject dc GetStockObject DC_PEN
	modes/saved-brush:	SelectObject dc GetStockObject DC_BRUSH	
	;modes/saved-font:	SelectObject dc GetStockObject ANSI_FIXED_FONT

	modes/pen:			null
	modes/brush:		null
	modes/font:			null
	modes/pen-width:	1
	modes/pen-style:	PS_SOLID
	modes/pen-color:	00FFFFFFh						;-- default: black
	modes/pen-join:		-1
	modes/pen-cap:		-1
	modes/brush-color:	-1
	modes/g-brush:		0
	modes/g-pen:		0

	graphics: 0
	GdipCreateFromHDC dc :graphics
	modes/graphics:	graphics

	anti-alias?: no
	update-modes dc
	dc
]

draw-end: func [
	dc	 [handle!]
	hWnd [handle!]
	img  [red-image!]
	/local
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		bitmap	[integer!]
][
	rect: declare RECT_STRUCT
	GetClientRect hWnd rect
	width: rect/right - rect/left
	height: rect/bottom - rect/top
	BitBlt modes/saved-dc 0 0 width height dc 0 0 SRCCOPY

	if null? hWnd [
		GdipDisposeImage as-integer img/node
		bitmap: 0
		GdipCreateBitmapFromHBITMAP modes/bitmap 0 :bitmap
		img/node: as node! bitmap
	]

	unless zero? modes/graphics [GdipDeleteGraphics modes/graphics]
	unless zero? modes/g-pen	[GdipDeletePen modes/g-pen]
	unless zero? modes/g-brush	[GdipDeleteBrush modes/g-brush]
	unless null? modes/pen		[DeleteObject modes/pen]
	unless null? modes/brush	[DeleteObject modes/brush]

	DeleteDC dc
	DeleteObject modes/bitmap
	unless null? hWnd [EndPaint hWnd paint]
]

to-gdiplus-color: func [
	color	[integer!]
	return: [integer!]
	/local
		red   [integer!]
		green [integer!]
		blue  [integer!]
][
	red: color and FFh << 16
	green: color and 0000FF00h
	blue: color >> 16 and FFh
	red or green or blue or FF000000h
]

OS-draw-anti-alias: func [
	dc	 [handle!]
	off? [logic!]
][
	if anti-alias? <> off? [
		anti-alias?: off?
		either anti-alias? [
			update-gdiplus-modes dc
			GdipSetSmoothingMode modes/graphics GDIPLUS_ANTIALIAS
		][
			GdipSetSmoothingMode modes/graphics GDIPLUS_HIGHSPPED
		]
	]
]

OS-draw-line: func [
	dc	   [handle!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt		[tagPOINT]
		nb		[integer!]
		res		[integer!]
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
	either anti-alias? [
		res: GdipDrawLinesI modes/graphics modes/g-pen edges nb
	][
		if null? modes/pen [OS-draw-pen dc modes/pen-color]
		Polyline dc edges nb
	]
]

OS-draw-pen: func [
	dc	  [handle!]
	color [integer!]									;-- 00bbggrr format
][
	modes/pen-color: color
	update-modes dc
]

OS-draw-fill-pen: func [
	dc	  [handle!]
	color [integer!]									;-- 00bbggrr format
	off?  [logic!]
][
	modes/brush-color: either off? [-1][color]
	update-modes dc
]

OS-draw-line-width: func [
	dc	  [handle!]
	width [integer!]
][
	modes/pen-width: width
	update-modes dc
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
	x: x + (width - diameter - 1)
	GdipAddPathArcI path x y diameter diameter as float32! 270.0 angle90
	y: y + (height - diameter - 1)
	GdipAddPathArcI path x y diameter diameter as float32! 0.0 angle90
	x: x - (width - diameter - 1)
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
		res		[integer!]
][
	path: 0
	res: GdipCreatePath GDIPLUS_FILLMODE_ALTERNATE :path
	gdiplus-roundrect-path path x y width height radius
	if fill? [
		GdipFillPath modes/graphics modes/g-brush path
	]
	GdipDrawPath modes/graphics modes/g-pen path
	GdipDeletePath path
]

OS-draw-box: func [
	dc	  [handle!]
	upper [red-pair!]
	lower [red-pair!]
	/local
		radius [red-integer!]
		rad	   [integer!]
		width  [integer!]
][
	either TYPE_OF(lower) = TYPE_INTEGER [
		radius: as red-integer! lower
		lower:  lower - 1
		rad: radius/value
		either anti-alias? [
			gdiplus-draw-roundbox
				upper/x
				upper/y
				lower/x - upper/x
				lower/y - upper/y
				rad
				modes/brush-color <> -1
		][
			RoundRect dc upper/x upper/y lower/x lower/y rad rad
		]
	][
		either anti-alias? [
			unless null? modes/brush [				;-- fill rect
				width: modes/pen-width
				GdipFillRectangleI
					modes/graphics
					modes/g-brush
					upper/x
					upper/y
					lower/x - upper/x - 1
					lower/y - upper/y - 1
			]
			GdipDrawRectangleI
				modes/graphics
				modes/g-pen
				upper/x
				upper/y
				lower/x - upper/x - 1
				lower/y - upper/y - 1
		][
			Rectangle dc upper/x upper/y lower/x lower/y
		]
	]
]

OS-draw-triangle: func [
	dc	  [handle!]
	start [red-pair!]
	end	  [red-pair!]
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

	either anti-alias? [
		if modes/brush-color <> -1 [
			GdipFillPolygonI
				modes/graphics
				modes/g-brush
				edges
				4
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI modes/graphics modes/g-pen edges 4
	][
		either modes/brush-color = -1 [
			Polyline dc edges 4
		][
			Polygon dc edges 4
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

	either anti-alias? [
		if modes/brush-color <> -1 [
			GdipFillPolygonI
				modes/graphics
				modes/g-brush
				edges
				nb + 1
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI modes/graphics modes/g-pen edges nb + 1
	][
		either modes/brush-color = -1 [
			Polyline dc edges nb + 1
		][
			Polygon dc edges nb + 1
		]
	]
]

do-draw-ellipse: func [
	dc		[handle!]
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
][
	either anti-alias? [
		if modes/brush-color <> -1 [
			GdipFillEllipseI
				modes/graphics
				modes/g-brush
				x
				y
				width - 1
				height - 1
		]
		GdipDrawEllipseI
			modes/graphics
			modes/g-pen
			x
			y
			width - 1
			height - 1
	][	
		Ellipse dc x y x + width y + height
	]
]

OS-draw-circle: func [
	dc	   [handle!]
	center [red-pair!]
	radius [red-integer!]
	/local
		rad-x [integer!]
		rad-y [integer!]
][
	either center + 1 = radius [
		rad-x: radius/value
		rad-y: rad-x
	][
		rad-y: radius/value
		radius: radius - 1
		rad-x: radius/value
	]
	do-draw-ellipse dc center/x - rad-x center/y - rad-y rad-x << 1 rad-y << 1
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
	SetTextColor dc either TYPE_OF(color) = TYPE_TUPLE [color/array1 and 00FFFFFFh][0]
]

OS-draw-text: func [
	dc		[handle!]
	pos		[red-pair!]
	text	[red-string!]
	/local
		str		[c-string!]
		len		[integer!]
][
	str: unicode/to-utf16 text
	len: string/rs-length? text
	ExtTextOut dc pos/x pos/y ETO_CLIPPED null str len null
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

	either anti-alias? [
		either closed? [
			if modes/brush-color <> -1 [
				GdipFillPieI
					modes/graphics
					modes/g-brush
					center/x - rad-x - 1
					center/y - rad-y - 1
					rad-x << 1
					rad-y << 1
					as float32! angle-begin
					as float32! angle-len
			]
			GdipDrawPieI
				modes/graphics
				modes/g-pen
				center/x - rad-x - 1
				center/y - rad-y - 1
				rad-x << 1
				rad-y << 1
				as float32! angle-begin
				as float32! angle-len
		][
			GdipDrawArcI
				modes/graphics
				modes/g-pen
				center/x - rad-x - 1
				center/y - rad-y - 1
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
				center/x + rad-x
				center/y + rad-y
				start-x
				start-y
				end-x
				end-y
		][
			Arc
				dc
				center/x - rad-x
				center/y - rad-y
				center/x + rad-x
				center/y + rad-y
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

	either anti-alias? [
		GdipDrawBeziersI modes/graphics modes/g-pen edges 4
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
	either anti-alias? [
		case [
			style = miter		[mode: GDIPLUS_MITER]
			style = miter-bevel [mode: GDIPLUS_MITERCLIPPED]
			style = _round		[mode: GDIPLUS_ROUND]
			style = bevel		[mode: GDIPLUS_BEVEL]
			true				[mode: GDIPLUS_MITER]
		]
		GdipSetPenLineJoin modes/g-pen mode
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
	either anti-alias? [
		case [
			style = flat		[mode: GDIPLUS_LINECAPFLAT]
			style = square		[mode: GDIPLUS_LINECAPSQUARE]
			style = _round		[mode: GDIPLUS_LINECAPROUND]
			true				[mode: GDIPLUS_LINECAPFLAT]
		]
		GdipSetPenStartCap modes/g-pen mode
		GdipSetPenEndCap modes/g-pen mode
	][
		update-pen dc PEN_LINE_CAP
	]
]

OS-draw-image: func [
	dc			[handle!]
	image		[red-image!]
	rect		[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	pattern		[red-word!]
	/local
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
][
	x: rect/x
	y: rect/y
	rect: rect + 1
	either TYPE_OF(rect) <> TYPE_PAIR [
		width:  IMAGE_WIDTH(image/size)
		height: IMAGE_HEIGHT(image/size)
	][
		width: rect/x - x
		height: rect/y - y
	]
	GdipDrawImageRectRectI
		modes/graphics
		as-integer image/node
		x y width height
		0 0 IMAGE_WIDTH(image/size) IMAGE_HEIGHT(image/size)
		GDIPLUS_UNIT_PIXEL
		0 0 0
]