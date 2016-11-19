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
	pen-width		[float32!]
	pen-style		[integer!]
	pen-color		[integer!]								;-- 00bbggrr format
	brush-color		[integer!]								;-- 00bbggrr format
	font-color		[integer!]
	bitmap			[handle!]
	graphics		[integer!]								;-- gdiplus graphics
	gp-state		[integer!]
	gp-pen			[integer!]								;-- gdiplus pen
	gp-pen-saved	[integer!]
	gp-brush		[integer!]								;-- gdiplus brush
	gp-font			[integer!]								;-- gdiplus font
	gp-font-brush	[integer!]
	gp-matrix		[integer!]
	gp-path			[integer!]
	image-attr		[integer!]								;-- gdiplus image attributes
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
types: allocate max-edges * (size? byte!)					;-- point type buffer
colors: as int-ptr! allocate 2 * max-colors * (size? integer!)
colors-pos: as pointer! [float32!] colors + max-colors

#define SHAPE_OTHER     0
#define SHAPE_CURVE     1
#define SHAPE_QCURVE    2

last-point?: no
path-last-point: declare tagPOINT
curve-info!: alias struct! [
    type    [integer!]
    control [tagPOINT]
]
prev-shape: declare curve-info!
prev-shape/control: declare tagPOINT

arcPOINTS!: alias struct! [
    start-x     [float!]
    start-y     [float!]
    end-x       [float!]
    end-y       [float!]
]
connect-subpath: 0
matrix-order: GDIPLUS_MATRIXORDERAPPEND

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

update-gdiplus-modes: func [][
	update-gdiplus-pen
	update-gdiplus-brush
]

update-gdiplus-brush: func [/local handle [integer!]][
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

update-gdiplus-pen: func [/local handle [integer!]][
	either modes/pen? [
		if modes/gp-pen-saved <> 0 [
			modes/gp-pen: modes/gp-pen-saved
			modes/gp-pen-saved: 0
		]
		handle: modes/gp-pen
		GdipSetPenColor handle to-gdiplus-color modes/pen-color
		GdipSetPenWidth handle modes/pen-width
		if modes/pen-join <> -1 [
			OS-draw-line-join null modes/pen-join
		]
		if modes/pen-cap <> -1 [
			OS-draw-line-cap null modes/pen-cap
		]
	][
		modes/gp-pen-saved: modes/gp-pen
		modes/gp-pen: 0
	]
]

update-brush: func [dc [handle!] /local handle [handle!]][
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
			pen: CreatePen modes/pen-style as integer! modes/pen-width modes/pen-color
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
				as integer! modes/pen-width
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
][
	either GDI+? [
		update-gdiplus-modes
	][
		update-pen dc
		update-brush dc
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
	modes/pen:				null
	modes/brush:			null
	modes/pen-width:		as float32! 1
	modes/pen-style:		PS_SOLID
	modes/pen-color:		0						;-- default: black
	modes/pen-join:			-1
	modes/pen-cap:			-1
	modes/brush-color:		-1
	modes/font-color:		-1
	modes/gp-brush:			0
	modes/gp-pen:			0
	modes/gp-pen-saved:		0
	modes/gp-font:			0
	modes/gp-font-brush:	0
	modes/gp-matrix:		0
	modes/image-attr:		0
	modes/on-image?:		no
	modes/pen?:				yes
	modes/brush?:			no
	modes/alpha-pen?:		no
	modes/alpha-brush?:		no
	modes/font-color?:		no
	dc:						null

    last-point?: no
    prev-shape/type: SHAPE_OTHER
    path-last-point/x: 0
    path-last-point/y: 0

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
		modes/pen-width
		GDIPLUS_UNIT_WORLD
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
	unless zero? modes/image-attr [GdipDisposeImageAttributes modes/image-attr]
	unless zero? modes/gp-matrix [GdipDeleteMatrix modes/gp-matrix]
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


radian-to-degrees: func [
    radians     [float!]
    return:     [float!]
][
    (radians * 180.0) / PI
]

adjust-angle: func [
    x       [float!]
    y       [float!]
    angle   [float!]
    return: [float!]
][
    case [
        all [ x >= 0.0 y <= 0.0 ] [ either angle = 0.0 [0.0 - angle][360.0 - angle] ]
        all [ x <= 0.0 y >= 0.0 ] [ 180.0 - angle ]
        all [ x <= 0.0 y <= 0.0 ] [ 180.0 + angle ]
        true [ angle ]
    ]
]

set-matrix: func [
    xform       [XFORM!]
    eM11        [float!]
    eM12        [float!]
    eM21        [float!]
    eM22        [float!]
    eDx         [float!]
    eDy         [float!]
][
    xform/eM11: as float32! eM11
    xform/eM12: as float32! eM12
    xform/eM21: as float32! eM21
    xform/eM22: as float32! eM22
    xform/eDx: as float32! eDx
    xform/eDy: as float32! eDy
]

gdi-calc-arc: func [
    center-x        [float!]
    center-y        [float!]
    rad-x           [float!]
    rad-y           [float!]
    angle-begin     [float!]
    angle-len       [float!]
    return:         [arcPOINTS!]
	/local
        radius      [red-pair!]
        angle       [red-integer!]
        start-x     [float!]
        start-y     [float!]
        end-x       [float!]
        end-y       [float!]
        rad-x-float [float32!]
        rad-y-float [float32!]
        rad-x-2     [float32!]
        rad-y-2     [float32!]
        rad-x-y     [float32!]
        tan-2       [float32!]
        rad-beg     [float!]
        rad-end     [float!]
        points      [arcPOINTS!]
][
    points: declare arcPOINTS!
    rad-x-float: as float32! rad-x
    rad-y-float: as float32! rad-y

    either rad-x = rad-y [				;-- circle
        rad-beg: degree-to-radians angle-begin TYPE_SINE
        rad-end: degree-to-radians angle-begin + angle-len TYPE_SINE
        start-y: center-y + (rad-y-float * system/words/sin rad-beg)
        end-y:	 center-y + (rad-y-float * system/words/sin rad-end)
        rad-beg: degree-to-radians angle-begin TYPE_COSINE
        rad-end: degree-to-radians angle-begin + angle-len TYPE_COSINE
        start-x: center-x + (rad-x-float * system/words/cos rad-beg)
        end-x:	 center-x + (rad-x-float * system/words/cos rad-end)
    ][
        rad-beg: degree-to-radians angle-begin TYPE_TANGENT
        rad-end: degree-to-radians angle-begin + angle-len TYPE_TANGENT
        rad-x-y: rad-x-float * rad-y-float
        rad-x-2: rad-x-float * rad-x-float
        rad-y-2: rad-y-float * rad-y-float
        tan-2: as float32! system/words/tan rad-beg
        tan-2: tan-2 * tan-2
        start-x: as float! rad-x-y / (sqrt as-float rad-x-2 * tan-2 + rad-y-2)
        start-y: as float! rad-x-y / (sqrt as-float rad-y-2 / tan-2 + rad-x-2)
        if all [angle-begin > 90.0  angle-begin < 270.0][start-x: 0.0 - start-x]
        if all [angle-begin > 180.0 angle-begin < 360.0][start-y: 0.0 - start-y]
        start-x: center-x + start-x
        start-y: center-y + start-y
        angle-begin: angle-begin + angle-len
        tan-2: as float32! system/words/tan rad-end
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
    dc          [handle!]
    start       [red-pair!]
    end         [red-pair!]
    rel?        [logic!]
    nr-points   [integer!]
    /local
        point   [tagPOINT]
        pair    [red-pair!]
        pt      [tagPOINT]
        nb      [integer!]
        count   [integer!]
][
    pt:     edges
    pair:   start
    nb:     0
    count: (as-integer end - pair) >> 4 + 1
    while [ all [ pair <= end nb < max-edges count >= nr-points ] ][
        pt/x: path-last-point/x
        pt/y: path-last-point/y
        while [ nb < 3 ][
            nb: nb + 1
            pt: pt + 1
            pt/x: either rel? [ pair/x + path-last-point/x ][ pair/x ]
            pt/y: either rel? [ pair/y + path-last-point/y ][ pair/y ]
            if nb < nr-points [ pair: pair + 1 ] 
        ]
        path-last-point/x: pt/x
        path-last-point/y: pt/y
        either GDI+? [
            GdipAddPathBeziersI modes/gp-path edges nb + 1
        ][
            PolyBezier dc edges nb + 1 
        ]

        count: (as-integer end - pair) >> 4
        nb: 0
        pt: edges
        pair: pair + 1
    ]
    last-point?: yes
    point: edges + nr-points - 1
    prev-shape/type: SHAPE_CURVE
    prev-shape/control/x: point/x
    prev-shape/control/y: point/y
	connect-subpath: 1
]

draw-short-curves: func [
    dc          [handle!]
    start       [red-pair!]
    end         [red-pair!]
    rel?        [logic!]
    nr-points   [integer!]
    /local
        point   [tagPOINT]
        pair    [red-pair!]
        pt      [tagPOINT]
        nb      [integer!]
        control [tagPOINT]
        count   [integer!]
][
    pt: edges
    nb: 0
    pair: start
    control: declare tagPOINT
    either prev-shape/type = SHAPE_CURVE [
        control/x: prev-shape/control/x
        control/y: prev-shape/control/y
    ][
        control/x: path-last-point/x
        control/y: path-last-point/y
    ]
    while [ pair <= end ][
        pt/x: path-last-point/x
        pt/y: path-last-point/y
        pt: pt + 1
        pt/x: ( 2 * path-last-point/x ) - control/x
        pt/y: ( 2 * path-last-point/y ) - control/y
        pt: pt + 1
        pt/x: either rel? [ path-last-point/x + pair/x ][ pair/x ]
        pt/y: either rel? [ path-last-point/y + pair/y ][ pair/y ]
        control/x: pt/x
        control/y: pt/y
        pt: pt + 1
        loop nr-points - 1 [ pair: pair + 1 ]
        if pair <= end [
            pt/x: either rel? [ path-last-point/x + pair/x ][ pair/x ]
            pt/y: either rel? [ path-last-point/y + pair/y ][ pair/y ]
            last-point?: yes
            path-last-point/x: pt/x
            path-last-point/y: pt/y
            pair: pair + 1
            nb: nb + 4
        ]
        either GDI+? [
            GdipAddPathBeziersI modes/gp-path edges nb
        ][
            PolyBezier dc edges nb
        ]
        prev-shape/type: SHAPE_CURVE
        prev-shape/control/x: control/x
        prev-shape/control/y: control/y 

        pt: edges
        nb: 0
    ]
	connect-subpath: 1
]

OS-draw-shape-beginpath: func [
    dc          [handle!]
    /local
        path    [integer!]
][
    connect-subpath: 0
    either GDI+? [
        path: 0
        GdipCreatePath 0 :path	; alternate fill
        modes/gp-path: path
		GdipStartPathFigure modes/gp-path
    ][
        update-modes dc
    	BeginPath dc
    ]
]

OS-draw-shape-endpath: func [
    dc          [handle!]
    close?      [logic!]
    return:     [logic!]
    /local
        alpha   [byte!]
        width   [integer!]
        height  [integer!]
        ftn     [integer!]
        bf      [tagBLENDFUNCTION]
        count   [integer!]
        result  [logic!]
        point   [tagPOINT]
][
    result: true

    either GDI+? [
        count: 0
        GdipGetPointCount modes/gp-path :count

        either all [ count > 0 count <= max-edges ][
            if close? [ GdipClosePathFigure modes/gp-path ]
            GdipDrawPath modes/graphics modes/gp-pen modes/gp-path
            GdipFillPath modes/graphics modes/gp-brush modes/gp-path
            GdipDeletePath modes/gp-path
        ][ if count > max-edges [ result: false ] ]
    ][
        if close? [ CloseFigure dc ]
        EndPath dc
        count: GetPath dc edges types 0
        either all [ count > 0 count <= max-edges ][
            count: GetPath dc edges types count
            FillPath dc
            PolyDraw dc edges types count
        ][ if count > max-edges [ result: false ] ]
    ]
    result
]

OS-draw-shape-moveto: func [
    dc      [handle!]
    coord   [red-pair!]
    rel?    [logic!]
    /local
        pt  [tagPOINT]
][
    either all [ rel? last-point? ][
        path-last-point/x: path-last-point/x + coord/x
        path-last-point/y: path-last-point/y + coord/y
    ][
        path-last-point/x: coord/x
        path-last-point/y: coord/y
    ]
	connect-subpath: 0
    last-point?: yes
    prev-shape/type: SHAPE_OTHER
    either GDI+? [
        GdipStartPathFigure modes/gp-path
	][
        pt: declare tagPOINT
        MoveToEx dc path-last-point/x path-last-point/y pt
    ]
]

OS-draw-shape-line: func [
    dc          [handle!]
    start       [red-pair!]
    end         [red-pair!]
    rel?        [logic!]
    /local
        pt      [tagPOINT]
        nb      [integer!]
        pair    [red-pair!]
][
    pt: edges
    pair:  start
    nb:	   0

    if last-point? [
        pt/x: path-last-point/x
        pt/y: path-last-point/y
        pt: pt + 1
        nb: nb + 1
    ]

    while [all [pair <= end nb < max-edges]][
        pt/x: pair/x
        pt/y: pair/y
        if rel? [
            pt/x: pt/x + path-last-point/x
            pt/y: pt/y + path-last-point/y
        ]
        path-last-point/x: pt/x
        path-last-point/y: pt/y
        nb: nb + 1
        pt: pt + 1
        pair: pair + 1	
    ]
    either GDI+? [
        GdipAddPathLine2I  modes/gp-path edges nb
    ][
        Polyline dc edges nb
    ]
	last-point?: yes
    prev-shape/type: SHAPE_OTHER
	connect-subpath: 1
]

OS-draw-shape-axis: func [
    dc          [handle!]
    start       [red-value!]
    end         [red-value!]
    rel?        [logic!]
    hline       [logic!]
    /local
        pt      [tagPOINT]
        nb      [integer!]
        coord	[red-value!]
        coord-v [integer!]
        coord-f [red-float!]
        coord-i [red-integer!]
][
    if last-point? [
        pt: edges
        nb: 0
        coord: start

        pt/x: path-last-point/x
        pt/y: path-last-point/y
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
                        pt/x: path-last-point/x + coord-v
                    ][ pt/x: coord-v ]
                    pt/y: path-last-point/y
                    path-last-point/x: pt/x
                ]
                true [
                    either rel? [ 
                        pt/y: path-last-point/y + coord-v
                    ][ pt/y: coord-v ]
                    pt/x: path-last-point/x
                    path-last-point/y: pt/y 
                ]
            ]
            coord: coord + 1
            nb: nb + 1
            pt: pt + 1
            any [ coord > end nb >= max-edges ]
        ]
        last-point?: yes
        either GDI+? [
            GdipAddPathLine2I modes/gp-path edges nb
        ][
            Polyline dc edges nb
        ]
        prev-shape/type: SHAPE_OTHER
		connect-subpath: 1
    ]
]

OS-draw-shape-curve: func [
    dc      [handle!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    draw-curves dc start end rel? 3
]

OS-draw-shape-qcurve: func [
    dc      [handle!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    draw-curves dc start end rel? 2
]

OS-draw-shape-curv: func [
    dc      [handle!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    draw-short-curves dc start end rel? 2
]

OS-draw-shape-qcurv: func [
    dc      [handle!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    draw-short-curves dc start end rel? 1
]

OS-draw-shape-arc: func [
    dc      [handle!]
    start   [red-pair!]
    end     [red-value!]
    sweep?  [logic!]
    large?  [logic!]
    rel?    [logic!]
    /local
        item        [red-integer!]
        center-x    [float!]
        center-y    [float!]
        cx          [float!]
        cy          [float!]
        cf          [float!]
        angle-1     [float!]
        angle-2     [float!]
        angle-len   [float!]
        radius-x    [float!]
        radius-y    [float!]
        theta       [float!]
        X1          [float!]
        Y1          [float!]
        p1-x        [float!]
        p1-y        [float!]
        p2-x        [float!]
        p2-y        [float!]
        cos-val     [float!]
        sin-val     [float!]
        rx2         [float!]
        ry2         [float!]
        dx          [float!]
        dy          [float!]
        sqrt-val    [float!]
        sign        [float!]
        rad-check   [float!]
        angle       [red-integer!]
        center      [red-pair!]
        m           [integer!]
        path        [integer!]
        xform       [XFORM!]
        arc-dir     [integer!]
        prev-dir    [integer!]
        pt          [tagPOINT]
        arc-points  [arcPOINTS!]
][
    if last-point? [
        ;-- parse arguments 
        p1-x: as float! path-last-point/x
        p1-y: as float! path-last-point/y
        p2-x: either rel? [ p1-x + as float! start/x ][ as float! start/x ]
        p2-y: either rel? [ p1-y + as float! start/y ][ as float! start/y ]
        item: as red-integer! start + 1
        radius-x: get-float item
        item: item + 1
        radius-y: get-float item
        item: item + 1
        theta: get-float item
        if radius-x < 0.0 [ radius-x: radius-x * -1]
        if radius-y < 0.0 [ radius-x: radius-x * -1]

        ;-- calculate center
        dx: (p1-x - p2-x) / 2.0
        dy: (p1-y - p2-y) / 2.0
        cos-val: system/words/cos degree-to-radians theta TYPE_COSINE
        sin-val: system/words/sin degree-to-radians theta TYPE_SINE
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
        cy: cf * (radius-y * X1 / radius-x) * (-1)
        center-x: (cos-val * cx) - (sin-val * cy) + ((p1-x + p2-x) / 2.0)
        center-y: (sin-val * cx) + (cos-val * cy) + ((p1-y + p2-y) / 2.0)

        ;-- calculate angles
        angle-1: radian-to-degrees system/words/atan (float/abs ((p1-y - center-y) / (p1-x - center-x)))
        angle-1: adjust-angle (p1-x - center-x) (p1-y - center-y) angle-1
        angle-2: radian-to-degrees system/words/atan (float/abs ((p2-y - center-y) / (p2-x - center-x)))
        angle-2: adjust-angle (p2-x - center-x) (p2-y - center-y) angle-2
        angle-len: angle-2 - angle-1
        sign: either angle-len >= 0.0 [ 1.0 ][ -1.0 ]
        if large? [
            either sign < 0.0 [
                angle-len: 360.0 + angle-len 
            ][
                angle-len: angle-len - 360.0
            ]
        ]
        angle-1: angle-1 - theta

        ;--draw arc
        either GDI+? [
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
            GdipTranslateMatrix m as float32! (center-x * -1) as float32! (center-y * -1) GDIPLUS_MATRIXORDERAPPEND 
            GdipRotateMatrix m as float32! theta GDIPLUS_MATRIXORDERAPPEND
            GdipTranslateMatrix m as float32! center-x as float32! center-y GDIPLUS_MATRIXORDERAPPEND
            GdipTransformPath path m  
            GdipDeleteMatrix m

            GdipAddPathPath modes/gp-path path connect-subpath
            GdipDeletePath path
        ][
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
            SetGraphicsMode dc GM_ADVANCED
            xform: declare XFORM!
            set-matrix xform 1.0 0.0 0.0 1.0 center-x * -1 center-y * -1
            SetWorldTransform dc xform
            set-matrix xform cos-val sin-val sin-val * -1 cos-val center-x center-y
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
            SetGraphicsMode dc GM_COMPATIBLE
        ]

        ;-- set last point
        last-point?: yes
        path-last-point/x: as integer! p2-x
        path-last-point/y: as integer! p2-y
        prev-shape/type: SHAPE_OTHER
		connect-subpath: 1
    ]
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
	if all [off? modes/pen? <> off?][exit]

	modes/alpha-pen?: alpha?
	GDI+?: any [alpha? anti-alias? modes/alpha-brush?]

	if any [modes/pen-color <> color modes/pen? = off?][
		modes/pen?: not off?
		modes/pen-color: color
		either GDI+? [update-gdiplus-pen][update-pen dc]
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
	if all [off? modes/brush? <> off?][exit]

	modes/alpha-brush?: alpha?
	GDI+?: any [alpha? anti-alias? modes/alpha-pen?]

	if any [modes/brush-color <> color modes/brush? = off?][
		modes/brush?: not off?
		modes/brush-color: color
		either GDI+? [update-gdiplus-brush][update-brush dc]
	]
]

OS-draw-line-width: func [
	dc	  [handle!]
	width [red-value!]
    /local 
        width-v     [float32!]
][
    width-v: get-float32 as red-integer! width
	if modes/pen-width <> width-v [
        modes/pen-width: width-v
		either GDI+? [
			GdipSetPenWidth modes/gp-pen modes/pen-width
		][
			update-pen dc
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
				lower/x - upper/x + 1
				lower/y - upper/y + 1
				rad
				modes/brush?
		][
			RoundRect dc upper/x upper/y lower/x lower/y rad rad
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
					lower/x - upper/x + 1
					lower/y - upper/y + 1
			]
			GdipDrawRectangleI
				modes/graphics
				modes/gp-pen
				upper/x
				upper/y
				lower/x - upper/x + 1
				lower/y - upper/y + 1
		][
			Rectangle dc upper/x upper/y lower/x lower/y
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

	unless GDI+? [update-gdiplus-modes]					;-- force to use GDI+

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
		h		[integer!]
		w		[integer!]
		sz		[tagSIZE]
		y		[integer!]
		x		[integer!]
		rect	[RECT_STRUCT_FLOAT32]
][
	str: unicode/to-utf16 text
	len: string/rs-length? text
	either modes/on-image? [
		x: 0
		rect: as RECT_STRUCT_FLOAT32 :x
		rect/x: as float32! pos/x
		rect/y: as float32! pos/y
		rect/width: as float32! 0
		rect/height: as float32! 0
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
		angle-begin [float32!]
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
        prev-dir    [integer!]
        arc-dir     [integer!]
        arc-points  [arcPOINTS!]
][
	radius: center + 1
	rad-x: radius/x
	rad-y: radius/y
	angle: as red-integer! radius + 1
	angle-begin: as float32! angle/value
	angle: angle + 1
	angle-len: as float32! angle/value

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
					angle-begin
					angle-len
			]
			GdipDrawPieI
				modes/graphics
				modes/gp-pen
				center/x - rad-x
				center/y - rad-y
				rad-x << 1
				rad-y << 1
				angle-begin
				angle-len
		][
			GdipDrawArcI
				modes/graphics
				modes/gp-pen
				center/x - rad-x
				center/y - rad-y
				rad-x << 1
				rad-y << 1
				angle-begin
				angle-len
		]
	][
		rad-x-float: as float32! rad-x
		rad-y-float: as float32! rad-y

        arc-points: gdi-calc-arc 
                        as float! center/x 
                        as float! center/y 
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
				center/x - rad-x
				center/y - rad-y
				center/x + rad-x + 1
				center/y + rad-y + 1
				as integer! arc-points/start-x
				as integer! arc-points/start-y
				as integer! arc-points/end-x
				as integer! arc-points/end-y
		][
			Arc
				dc
				center/x - rad-x
				center/y - rad-y
				center/x + rad-x + 1
				center/y + rad-y + 1
				as integer! arc-points/start-x
				as integer! arc-points/start-y
				as integer! arc-points/end-x
				as integer! arc-points/end-y
		]
        SetArcDirection dc prev-dir
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
		w		[integer!]
		h		[integer!]
		attr	[integer!]
		color	[integer!]
		pts		[tagPOINT]
][
	attr: 0
	if key-color <> null [
		attr: modes/image-attr
		if zero? attr [GdipCreateImageAttributes :attr]
		color: to-gdiplus-color key-color/array1
		GdipSetImageAttributesColorKeys attr 0 true color color
	]
	w: IMAGE_WIDTH(image/size)
	h: IMAGE_HEIGHT(image/size)
	either null? start [x: 0 y: 0][x: start/x y: start/y]
	case [
		start = end [
			width:  w
			height: h
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
			GdipDrawImagePointsRectI
				modes/graphics as-integer image/node edges 3
				0 0 w h GDIPLUS_UNIT_PIXEL attr 0 0
			exit
		]
		true [exit]							;@@ TBD four control points
	]
	GdipDrawImageRectRectI
		modes/graphics as-integer image/node
		x y width height 0 0 w h
		GDIPLUS_UNIT_PIXEL attr 0 0
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

	pt: edges
	color: colors + 1
	pos: colors-pos + 1
	delta: as-float count - 1
	delta: 1.0 / delta
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
			sx: as float32! x - pt/x
			sy: as float32! y - pt/y
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

OS-set-clip: func [
	upper	[red-value!]
	lower	[red-value!]
    rect?   [logic!]
    dc      [handle!]
    mode    [integer!]
    /local
        u   [red-pair!]
        l   [red-pair!]
][
    either GDI+? [
        either rect? [
            u: as red-pair! upper
            l: as red-pair! lower
            GdipSetClipRectI
                modes/graphics
                u/x
                u/y
                l/x - u/x
                l/y - u/y
                mode
        ][
            GdipSetClipPath
                modes/graphics
                modes/gp-path
                mode
            GdipDeletePath modes/gp-path
        ]
    ][
        if rect? [
            u: as red-pair! upper
            l: as red-pair! lower
            BeginPath dc
            Rectangle dc u/x u/y l/x l/y  
        ]
        EndPath dc  ;-- a path has already been started
        SelectClipPath dc mode
    ]
]

matrix-rotate: func [
	angle	[red-integer!]
	center	[red-pair!]
    m       [integer!]
][
	GDI+?: yes
	if angle <> as red-integer! center [
        GdipTranslateMatrix m as float32! 0 - center/x as float32! 0 - center/y GDIPLUS_MATRIXORDERAPPEND 
	]
    GdipRotateMatrix m get-float32 angle GDIPLUS_MATRIXORDERAPPEND
	if angle <> as red-integer! center [
        GdipTranslateMatrix m as float32! center/x as float32! center/y GDIPLUS_MATRIXORDERAPPEND 
	]
]

OS-matrix-rotate: func [
	angle	[red-integer!]
	center	[red-pair!]
	/local
        m   [integer!]
][
	GDI+?: yes
    m: 0
    GdipCreateMatrix :m
    matrix-rotate angle center m
    GdipMultiplyWorldTransform modes/graphics m matrix-order
    GdipDeleteMatrix m
]

OS-matrix-scale: func [
	sx		[red-integer!]
	sy		[red-integer!]
][
	GDI+?: yes
	GdipScaleWorldTransform modes/graphics get-float32 sx get-float32 sy matrix-order
]

OS-matrix-translate: func [
	x	[integer!]
	y	[integer!]
][
	GDI+?: yes
	GdipTranslateWorldTransform
		modes/graphics
		as float32! x
		as float32! y
		matrix-order
]

OS-matrix-skew: func [
	sx		[red-integer!]
	sy		[red-integer!]
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
	x: as float32! system/words/tan degree-to-radians get-float sx TYPE_TANGENT
	y: as float32! either sx = sy [0.0][system/words/tan degree-to-radians get-float sy TYPE_TANGENT]
	GdipCreateMatrix2 u y x u z z :m
	GdipMultiplyWorldTransform modes/graphics m matrix-order
	GdipDeleteMatrix m
]

OS-matrix-transform: func [
	rotate		[red-integer!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		center	[red-pair!]
        m       [integer!]
][
	center: as red-pair! either rotate + 1 = scale [rotate][rotate + 1]
    m: 0
    GdipCreateMatrix :m
    matrix-rotate rotate center m
    GdipScaleMatrix m get-float32 scale get-float32 scale + 1 GDIPLUS_MATRIXORDERAPPEND
    GdipTranslateMatrix m as float32! translate/x as float32! translate/y
    GdipMultiplyWorldTransform modes/graphics m matrix-order
    GdipDeleteMatrix m
]

OS-matrix-push: func [state [int-ptr!] /local s][
	s: 0
	GdipSaveGraphics modes/graphics :s
	state/value: s
]

OS-matrix-pop: func [state [integer!]][GdipRestoreGraphics modes/graphics state]

OS-matrix-reset: func [][GdipResetWorldTransform modes/graphics]

OS-matrix-invert: func [/local m [integer!]][
	m: modes/gp-matrix
	if zero? m [
		GdipCreateMatrix :m
		modes/gp-matrix: m
	]
	GdipGetWorldTransform modes/graphics m
	GdipInvertMatrix m
	GdipSetWorldTransform modes/graphics m
]

OS-matrix-set: func [
	blk		[red-block!]
	/local
		m	[integer!]
		val [red-integer!]
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
	GdipMultiplyWorldTransform modes/graphics m matrix-order
	GdipDeleteMatrix m
]

OS-set-matrix-order: func [
    order   [integer!]
][ matrix-order: order ]
