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
	pen		  [handle!]
	brush	  [handle!]
	pen-width [integer!]
	pen-style [integer!]
	color	  [integer!]								;-- 00bbggrr format
	bg-color  [integer!]								;-- 00bbggrr format
]

modes/pen:		 null
modes/pen-width: 1
modes/pen-style: PS_SOLID
modes/color:	 00112233h								;-- default: black

paint: declare tagPAINTSTRUCT

update-pen: func [
	dc [handle!]
][
	unless null? modes/pen [DeleteObject modes/pen]
	modes/pen: CreatePen modes/pen-style modes/pen-width modes/color
	SelectObject dc modes/pen
	
	unless null? modes/brush [DeleteObject modes/brush]
	modes/brush: GetStockObject NULL_BRUSH
	SelectObject dc modes/brush
]

draw-begin: func [
	hWnd	[handle!]
	return: [handle!]
][
	BeginPaint hWnd paint
]

draw-end: func [dc [handle!] hWnd [handle!]][
	unless null? modes/pen	 [DeleteObject modes/pen]
	unless null? modes/brush [DeleteObject modes/brush]
	EndPaint hWnd paint
]

OS-draw-line: func [
	dc	   [handle!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt [tagPOINT]
][
	if null? modes/pen [OS-draw-pen dc modes/color]
	
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
	modes/color: color
	update-pen dc
]

OS-draw-line-width: func [
	dc	  [handle!]
	width [integer!]
][
	modes/pen-width: width
	update-pen dc
]

OS-draw-box: func [
	dc	   [handle!]
	upper  [red-pair!]
	lower  [red-pair!]
][
	Rectangle dc upper/x upper/y lower/x lower/y
]
