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
	gp-brush		[integer!]								;-- gdiplus brush
	gp-font			[integer!]								;-- gdiplus font
	gp-font-brush	[integer!]
	on-image?		[logic!]								;-- drawing on image?
]

paint: declare tagPAINTSTRUCT

max-edges: 1000												;-- max number of edges for a polygone
edges: as tagPOINT allocate max-edges * (size? tagPOINT)	;-- polygone edges buffer

anti-alias?: no

update-gdiplus-font-color: func [color [integer!] /local brush [integer!]][
	unless zero? modes/gp-font-brush [
		GdipDeleteBrush modes/gp-font-brush
		modes/gp-font-brush: 0
	]
	if modes/font-color <> color [
		modes/font-color: color
		brush: 0
		GdipCreateSolidFill to-gdiplus-color color :brush
		modes/gp-font-brush: brush
	]
]

update-gdiplus-font: func [dc [handle!] /local font [integer!] res [integer!]][
	font: 0
	unless zero? modes/gp-font [GdipDeleteFont modes/gp-font]
	res: GdipCreateFontFromDC as-integer dc :font
	modes/gp-font: font
]

update-gdiplus-modes: func [
	dc [handle!]
	/local
		handle [integer!]
][
	unless zero? modes/gp-pen [GdipDeletePen modes/gp-pen]
	handle: 0
	GdipCreatePen1
		to-gdiplus-color modes/pen-color
		as float32! integer/to-float modes/pen-width
		GDIPLUS_UNIT_WORLD
		:handle
	modes/gp-pen: handle

	if modes/pen-join <> -1 [
		OS-draw-line-join dc modes/pen-join
	]

	if modes/pen-cap <> -1 [
		OS-draw-line-cap dc modes/pen-cap
	]

	handle: 0
	unless zero? modes/gp-brush [
		GdipDeleteBrush modes/gp-brush
		modes/gp-brush: 0
	]
	if modes/brush-color <> -1 [
		GdipCreateSolidFill to-gdiplus-color modes/brush-color :handle
		modes/gp-brush: handle
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
	paint?	[logic!]
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
	modes/pen:			null
	modes/brush:		null
	modes/pen-width:	1
	modes/pen-style:	PS_SOLID
	modes/pen-color:	00FFFFFFh						;-- default: black
	modes/pen-join:		-1
	modes/pen-cap:		-1
	modes/brush-color:	-1
	modes/font-color:	-1
	modes/gp-brush:		0
	modes/gp-pen:		0
	modes/gp-font:		0
	modes/gp-font-brush: 0
	modes/on-image?:	no
	anti-alias?:		no
	dc:					null

	rect: declare RECT_STRUCT
	either null? hWnd [
		modes/on-image?: yes
		anti-alias?: yes
		graphics: 0
		image/GdipGetImageGraphicsContext as-integer img/node :graphics
		GdipSetSmoothingMode graphics GDIPLUS_HIGHSPPED
		dc: CreateCompatibleDC hScreen
		SelectObject dc default-font
		update-gdiplus-font-color 0
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

		unless null? hWnd [render-base hWnd dc]

		SetArcDirection dc AD_CLOCKWISE
		SetBkMode dc BK_TRANSPARENT

		graphics: 0
		GdipCreateFromHDC dc :graphics	
	]
	modes/graphics:	graphics
	update-modes dc
	update-gdiplus-font dc
	dc
]

draw-end: func [
	dc		[handle!]
	hWnd	[handle!]
	img		[red-image!]
	cache?	[logic!]
	paint?	[logic!]
	/local
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		bitmap	[integer!]
		old-dc	[integer!]
][
	rect: declare RECT_STRUCT
	GetClientRect hWnd rect
	width: rect/right - rect/left
	height: rect/bottom - rect/top
	if paint? [BitBlt as handle! paint/hdc 0 0 width height dc 0 0 SRCCOPY]

	unless zero? modes/graphics [GdipDeleteGraphics modes/graphics]
	unless zero? modes/gp-pen	[GdipDeletePen modes/gp-pen]
	unless zero? modes/gp-brush	[GdipDeleteBrush modes/gp-brush]
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
][
	red: color and FFh << 16
	green: color and 0000FF00h
	blue: color >> 16 and FFh
	red or green or blue or FF000000h
]

OS-draw-anti-alias: func [
	dc	 [handle!]
	off? [logic!]
	/local
		on-image? [logic!]
][
	on-image?: modes/on-image?
	if any [on-image? anti-alias? <> off?] [
		anti-alias?: off?
		either anti-alias? [
			unless on-image? [update-gdiplus-modes dc]
			GdipSetSmoothingMode modes/graphics GDIPLUS_ANTIALIAS
			GdipSetTextRenderingHint modes/graphics TextRenderingHintAntiAliasGridFit
		][
			if on-image? [anti-alias?: yes]			;-- always use GDI+ to draw on image
			GdipSetSmoothingMode modes/graphics GDIPLUS_HIGHSPPED
			GdipSetTextRenderingHint modes/graphics TextRenderingHintSystemDefault
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
		res: GdipDrawLinesI modes/graphics modes/gp-pen edges nb
	][
		if null? modes/pen [OS-draw-pen dc modes/pen-color]
		Polyline dc edges nb
	]
]

OS-draw-pen: func [
	dc	  [handle!]
	color [integer!]									;-- 00bbggrr format
][
	if modes/pen-color <> color [
		modes/pen-color: color
		update-modes dc
	]
]

OS-draw-fill-pen: func [
	dc	  [handle!]
	color [integer!]									;-- 00bbggrr format
	off?  [logic!]
][
	color: either off? [-1][color]
	if modes/brush-color <> color [
		modes/brush-color: color
		update-modes dc
	]
]

OS-draw-line-width: func [
	dc	  [handle!]
	width [integer!]
][
	if modes/pen-width <> width [
		modes/pen-width: width
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
		radius [red-integer!]
		rad	   [integer!]
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
			unless zero? modes/gp-brush [				;-- fill rect
				GdipFillRectangleI
					modes/graphics
					modes/gp-brush
					upper/x
					upper/y
					lower/x - upper/x - 1
					lower/y - upper/y - 1
			]
			GdipDrawRectangleI
				modes/graphics
				modes/gp-pen
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
				modes/gp-brush
				edges
				4
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI modes/graphics modes/gp-pen edges 4
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
				modes/gp-brush
				edges
				nb + 1
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI modes/graphics modes/gp-pen edges nb + 1
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
				modes/gp-brush
				x
				y
				width - 1
				height - 1
		]
		GdipDrawEllipseI
			modes/graphics
			modes/gp-pen
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
	if TYPE_OF(color) = TYPE_TUPLE [
		SetTextColor dc color/array1 and 00FFFFFFh
		if modes/on-image? [update-gdiplus-font-color color/array1]
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

	either anti-alias? [
		either closed? [
			if modes/brush-color <> -1 [
				GdipFillPieI
					modes/graphics
					modes/gp-brush
					center/x - rad-x - 1
					center/y - rad-y - 1
					rad-x << 1
					rad-y << 1
					as float32! angle-begin
					as float32! angle-len
			]
			GdipDrawPieI
				modes/graphics
				modes/gp-pen
				center/x - rad-x - 1
				center/y - rad-y - 1
				rad-x << 1
				rad-y << 1
				as float32! angle-begin
				as float32! angle-len
		][
			GdipDrawArcI
				modes/graphics
				modes/gp-pen
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
	either anti-alias? [
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
	either anti-alias? [
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