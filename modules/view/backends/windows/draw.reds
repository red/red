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
]

paint: declare tagPAINTSTRUCT

max-edges: 1000											;-- max number of edges for a polygone
edges: as tagPOINT allocate max-edges					;-- polygone edges buffer

update-modes: func [
	dc [handle!]
][
	unless null? modes/pen [DeleteObject modes/pen]
	modes/pen: CreatePen modes/pen-style modes/pen-width modes/pen-color
	SelectObject dc modes/pen
	
	if null? modes/brush [DeleteObject modes/brush]
	modes/brush: either modes/brush-color = -1 [
		GetStockObject NULL_BRUSH
	][
		CreateSolidBrush modes/brush-color
	]
	SelectObject dc modes/brush
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
	modes/pen-width:	1
	modes/pen-style:	PS_SOLID
	modes/pen-color:	00112233h						;-- default: black
	modes/brush-color:	-1
	
	update-modes dc
	dc
]

draw-end: func [dc [handle!] hWnd [handle!]][
	unless null? modes/pen	 [DeleteObject modes/pen]
	unless null? modes/brush [DeleteObject modes/brush]
	
	SelectObject dc saved-pen
	SelectObject dc saved-brush
	EndPaint hWnd paint
]

OS-draw-line: func [
	dc	   [handle!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt [tagPOINT]
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
		RoundRect dc upper/x upper/y lower/x lower/y rad rad
	][
		Rectangle dc upper/x upper/y lower/x lower/y
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
	
	either modes/brush-color = -1 [
		Polyline dc edges 4
	][
		Polygon dc edges 4
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
	
	either modes/brush-color = -1 [
		Polyline dc edges nb + 1
	][
		Polygon dc edges nb + 1
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
	
	Ellipse dc 
		x - rad-x
		y - rad-y
		x + rad-x
		y + rad-y
]
