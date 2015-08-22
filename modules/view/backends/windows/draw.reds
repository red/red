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
	pen-width	[integer!]
	pen-style	[integer!]
	pen-color	[integer!]								;-- 00bbggrr format
	brush-color [integer!]								;-- 00bbggrr format
	saved-pen	[handle!]
	saved-brush [handle!]
	saved-font	[handle!]
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
	
	SelectObject dc modes/saved-pen
	SelectObject dc modes/saved-brush
	;SelectObject dc modes/saved-font
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
					lower/x - upper/x - 1
					lower/y - upper/y - 1
			]
			GdipDrawRectangleI
				modes/graphics
				as-integer modes/pen
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
				as-integer modes/brush
				x
				y
				width - 1
				height - 1
		]
		GdipDrawEllipseI
			modes/graphics
			as-integer modes/pen
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
					as-integer modes/brush
					center/x - rad-x
					center/y - rad-y
					rad-x << 1
					rad-y << 1
					as float32! angle-begin
					as float32! angle-len
			]
			GdipDrawPieI
				modes/graphics
				as-integer modes/pen
				center/x - rad-x
				center/y - rad-y
				rad-x << 1
				rad-y << 1
				as float32! angle-begin
				as float32! angle-len
		][
			GdipDrawArcI
				modes/graphics
				as-integer modes/pen
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