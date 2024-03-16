Red/System [
	Title:	"Windows events handling"
	Author: "Nenad Rakocevic"
	File: 	%panel.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-panel: func [
	values [red-value!]
	phWnd  [handle!]									;-- parent window handle
	/local
		parent	  [red-object!]
		type	  [red-word!]
		pt		  [red-point2D!]
		pair	  [red-pair!]
		win-rect  [RECT_STRUCT value]
		calc-rect [RECT_STRUCT value]
		fx		  [float32!]
		fy		  [float32!]
		x y		  [integer!]
][
	parent: as red-object! values + FACE_OBJ_PARENT

	if TYPE_OF(parent) = TYPE_OBJECT [
		type: as red-word! get-node-facet parent/ctx FACE_OBJ_TYPE

		if tab-panel = symbol/resolve type/symbol [
			GetClientRect phWnd win-rect
			copy-memory 
				as byte-ptr! calc-rect
				as byte-ptr! win-rect
				size? win-rect
			SendMessage phWnd TCM_ADJUSTRECT 0 as-integer calc-rect

			pt: as red-point2D! values + FACE_OBJ_OFFSET
			fx: as float32! calc-rect/left - win-rect/left
			fy: as float32! calc-rect/top  - win-rect/top
			either dpi-factor <> as float32! 1.0 [
				pt/x: dpi-unscale fx
				pt/y: dpi-unscale fy
			][
				pt/x: fx - as float32! 3.0
				pt/y: fy - as float32! 1.0
			]

			pair: as red-pair! values + FACE_OBJ_SIZE
			pt: as red-point2D! pair
			x: calc-rect/right  - calc-rect/left
			y: calc-rect/bottom - calc-rect/top
			
			either dpi-factor <> as float32! 1.0 [
				fx: dpi-unscale as float32! x
				fy: dpi-unscale as float32! y
				either TYPE_OF(pair) = TYPE_POINT2D [
					pt/x: fx
					pt/y: fy
				][
					pair/x: as-integer fx
					pair/y: as-integer fy
				]
			][
				x: x + 4
				y: y + 3
				either TYPE_OF(pair) = TYPE_POINT2D [
					pt/x: as float32! x
					pt/y: as float32! y
				][
					pair/x: x
					pair/y: y
				]
			]
		]
	]
]