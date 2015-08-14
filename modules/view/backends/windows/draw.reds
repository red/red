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

current-pen: as handle! 0
paint: declare tagPAINTSTRUCT

draw-begin: func [
	hWnd	[handle!]
	return: [handle!]
	/local
		dc	[handle!]
][
	dc: BeginPaint hWnd paint
	current-pen: CreatePen PS_SOLID 2 00112233h
	SelectObject dc current-pen
	dc
]

draw-end: func [DC [handle!] hWnd [handle!]][
	EndPaint hWnd paint
]

draw-line: func [
	DC	   [handle!]
	handle [handle!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt [tagPOINT]
][
	pt: declare tagPOINT

	MoveToEx DC point/x point/y pt
	until [
		point: point + 1
		LineTo DC point/x point/y
		point = end
	]
]
