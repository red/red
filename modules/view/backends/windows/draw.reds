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
	pen-width	[integer!]
	pen-style	[integer!]
	pen-color	[integer!]								;-- 00bbggrr format
	brush-color [integer!]								;-- 00bbggrr format
	saved-pen	[handle!]
	saved-brush [handle!]
	graphics	[integer!]								;-- gdiplus graphics
]

paint: declare tagPAINTSTRUCT

max-edges: 1000												;-- max number of edges for a polygone
edges: as tagPOINT allocate max-edges * (size? tagPOINT)	;-- polygone edges buffer

anti-alias?: no

update-modes: func [
	dc [handle!]
	/local
		handle	[integer!]
		res		[integer!]
][
	either anti-alias? [
		unless null? modes/pen [GdipDeletePen as-integer modes/pen]
		handle: 0
		GdipCreatePen1
			to-gdiplus-color modes/pen-color
			as float32! integer/to-float modes/pen-width
			GDIPLUS_UNIT_WORLD
			:handle
		modes/pen: as handle! handle

		unless null? modes/brush [
			GdipDeleteBrush as-integer modes/brush
			modes/brush: null
		]
		if modes/brush-color <> -1 [
			GdipCreateSolidFill to-gdiplus-color modes/brush-color :handle
			modes/brush: as handle! handle
		]
	][
		unless null? modes/pen [DeleteObject modes/pen]
		modes/pen: CreatePen modes/pen-style modes/pen-width modes/pen-color
		SelectObject dc modes/pen
		
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
	return: [handle!]
	/local
		dc	[handle!]
][
	dc: BeginPaint hWnd paint
	saved-pen:   SelectObject dc GetStockObject DC_PEN
	saved-brush: SelectObject dc GetStockObject DC_BRUSH
	
	modes/pen:			null
	modes/brush:		null
	modes/pen-width:	1
	modes/pen-style:	PS_SOLID
	modes/pen-color:	00FFFFFFh						;-- default: black
	modes/brush-color:	-1
	modes/graphics:		0

	anti-alias?: no
	update-modes dc
	dc
]

draw-end: func [dc [handle!] hWnd [handle!]][
	either anti-alias? [
		unless zero? modes/graphics [GdipDeleteGraphics modes/graphics]
		unless null? modes/pen		[GdipDeletePen as-integer modes/pen]
		unless null? modes/brush	[GdipDeleteBrush as-integer modes/brush]
	][
		unless null? modes/pen		[DeleteObject modes/pen]
		unless null? modes/brush	[DeleteObject modes/brush]
	]
	
	SelectObject dc saved-pen
	SelectObject dc saved-brush
	EndPaint hWnd paint
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
		graphics [integer!]
		res		 [integer!]
][
	if anti-alias? <> off? [
		anti-alias?: off?
		either anti-alias? [
			graphics: 0
			unless null? modes/pen	 [DeleteObject modes/pen]
			unless null? modes/brush [DeleteObject modes/brush]
			GdipCreateFromHDC dc :graphics
			GdipSetSmoothingMode graphics GDIPLUS_ANTIALIAS
			modes/graphics: graphics
		][
			GdipDeletePen as-integer modes/pen
			unless null? modes/brush [GdipDeleteBrush as-integer modes/brush]
		]
		modes/pen: null
		modes/brush: null
		update-modes dc
	]
]

OS-draw-line: func [
	dc	   [handle!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt		[tagPOINT]
		pts		[int-ptr!]
		p		[int-ptr!]
		count	[integer!]
		res		[integer!]
][
	either anti-alias? [
		end: end + 1
		count: as-integer end - point
		count: count >> 4
		pts: as int-ptr! allocate count << 3
		p: pts
		until [
			p/1: point/x
			p/2: point/y
			p: p + 2
			point: point + 1
			point = end
		]
		res: GdipDrawLinesI modes/graphics as-integer modes/pen pts count
		free as byte-ptr! pts
	][
		if null? modes/pen [OS-draw-pen dc modes/pen-color]

		pt: declare tagPOINT
		MoveToEx dc point/x point/y pt
		
		until [
			point: point + 1
			LineTo dc point/x point/y
			point = end
		]
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
		GdipFillPath modes/graphics as-integer modes/brush path
	]
	GdipDrawPath modes/graphics as-integer modes/pen path
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
					as-integer modes/brush
					upper/x
					upper/y
					lower/x - upper/x
					lower/y - upper/y
			]
			GdipDrawRectangleI
				modes/graphics
				as-integer modes/pen
				upper/x
				upper/y
				lower/x - upper/x
				lower/y - upper/y
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
				as-integer modes/brush
				edges
				4
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI modes/graphics as-integer modes/pen edges 4
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
				as-integer modes/brush
				edges
				nb + 1
				GDIPLUS_FILLMODE_ALTERNATE
		]
		GdipDrawPolygonI modes/graphics as-integer modes/pen edges nb + 1
	][
		either modes/brush-color = -1 [
			Polyline dc edges nb + 1
		][
			Polygon dc edges nb + 1
		]
	]
]

OS-draw-circle: func [
	dc	   [handle!]
	center [red-pair!]
	radius [red-integer!]
	/local
		rad-x [integer!]
		rad-y [integer!]
		x	  [integer!]
		y	  [integer!]
][
	either center + 1 = radius [
		rad-x: radius/value
		rad-y: rad-x
	][
		rad-y: radius/value
		radius: radius - 1
		rad-x: radius/value
	]
	x: center/x
	y: center/y
	either anti-alias? [
		if modes/brush-color <> -1 [
			GdipFillEllipseI
				modes/graphics
				as-integer modes/brush
				x - rad-x
				y - rad-y
				rad-x << 1 - 1
				rad-y << 1 - 1
		]
		GdipDrawEllipseI
			modes/graphics
			as-integer modes/pen
			x - rad-x
			y - rad-y
			rad-x << 1 - 1
			rad-y << 1 - 1
	][	
		Ellipse dc 
			x - rad-x
			y - rad-y
			x + rad-x
			y + rad-y
	]
]
