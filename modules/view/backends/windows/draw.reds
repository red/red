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

gradient!: alias struct! [
    extra           [integer!]                              ;-- used when pen width > 1
    pair-1          [red-pair!]                             ;-- preallocated for performance reasons
    pair-2          [red-pair!]                             ;-- preallocated for performance reasons
    path-data       [PATHDATA]                              ;-- preallocated for performance reasons
    points-data     [tagPOINT]                              ;-- preallocated for performance reasons
    type            [integer!]                              ;-- gradient on fly (just before drawing figure)
    count           [integer!]                              ;-- gradient stops count
    data            [tagPOINT]                              ;-- figure coordinates
    positions?      [logic!]                                ;-- true if positions are defined, false otherwise
    created?        [logic!]                                ;-- true if gradient brush created, false otherwise                                 
]
max-data: 5
gradient-pen: declare gradient!                             ;-- one for pen
gradient-pen/data: as tagPOINT allocate max-data * (size? tagPOINT)
gradient-fill: declare gradient!                            ;-- one for fill
gradient-fill/data: as tagPOINT allocate max-data * (size? tagPOINT)
gradient-pen?: false
gradient-fill?: false

gradient-matrix-pen: 0  ;-- transformation matrix for pen gradient GDI+
gradient-matrix-fill: 0  ;-- transformation matrix for fill gradient GDI+


paint: declare tagPAINTSTRUCT
max-colors: 256												;-- max number of colors for gradient
max-edges:  1000											;-- max number of edges for a polygone
edges: as tagPOINT allocate max-edges * (size? tagPOINT)	;-- polygone edges buffer
types: allocate max-edges * (size? byte!)					;-- point type buffer
colors: as int-ptr! allocate 2 * max-colors * (size? integer!)
colors-pos: as pointer! [float32!] colors + max-colors
pen-colors: as int-ptr! allocate 2 * max-colors * (size? integer!)  ;-- for delayed pen gradients (no positions specified)
pen-colors-pos: as pointer! [float32!] pen-colors + max-colors      ;-- for delayed pen gradients (no positions specified)

#define SHAPE_OTHER     0
#define SHAPE_CURVE     1
#define SHAPE_QCURVE    2

#define GRADIENT_NONE       0
#define GRADIENT_LINEAR     1
#define GRADIENT_RADIAL     2
#define GRADIENT_DIAMOND    3

#define INVALID_RADIUS      -1
#define INDEX_UPPER         0
#define INDEX_LOWER         1
#define INDEX_OTHER         2

#define INIT_GRADIENT_DATA(upper lower other)  [
    upper: gradient/data + INDEX_UPPER
    lower: gradient/data + INDEX_LOWER
    other: gradient/data + INDEX_OTHER
]

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
D2D?: no

clip-replace: func [ return: [integer!] ][
    either GDI+? [GDIPLUS_COMBINEMODEREPLACE][RGN_COPY]
]
clip-intersect: func [ return: [integer!] ][
    either GDI+? [GDIPLUS_COMBINEMODEINTERSECT][RGN_AND]
]
clip-union: func [ return: [integer!] ][
    either GDI+? [GDIPLUS_COMBINEMODEUNION][RGN_OR]
]
clip-xor: func [ return: [integer!] ][
    either GDI+? [GDIPLUS_COMBINEMODEXOR][RGN_XOR]
]
clip-diff: func [ return: [integer!] ][
    either GDI+? [GDIPLUS_COMBINEMODEEXCLUDE][RGN_DIFF]
]

matrix-order-append: func [ return: [integer!] ][ GDIPLUS_MATRIXORDERAPPEND ]
matrix-order-prepend: func [ return: [integer!] ][ GDIPLUS_MATRIXORDERAPPEND ]

update-gdiplus-font-color: func [ctx [draw-ctx!] color [integer!] /local brush [integer!]][
    if ctx/font-color <> color [
        unless zero? ctx/gp-font-brush [
            GdipDeleteBrush ctx/gp-font-brush
            ctx/gp-font-brush: 0
        ]
        ctx/font-color: color
        ;-- work around for drawing text on transparent background
        ;-- http://stackoverflow.com/questions/5647322/gdi-font-rendering-especially-in-layered-windows
        if color >>> 24 = 0 [color: 1 << 24 or color]
        brush: 0
        GdipCreateSolidFill to-gdiplus-color color :brush
        ctx/gp-font-brush: brush
    ]
]

update-gdiplus-font: func [ctx [draw-ctx!] /local font [integer!]][
    font: 0
    unless zero? ctx/gp-font [GdipDeleteFont ctx/gp-font]
    GdipCreateFontFromDC as-integer ctx/dc :font
    ctx/gp-font: font
]

update-gdiplus-modes: func [ctx [draw-ctx!] ][
    update-gdiplus-pen ctx
    update-gdiplus-brush ctx
]

update-gdiplus-brush: func [ctx [draw-ctx!] /local handle [integer!]][
    handle: 0
    unless zero? ctx/gp-brush [
        GdipDeleteBrush ctx/gp-brush
        ctx/gp-brush: 0
    ]
    if ctx/brush? [
        GdipCreateSolidFill to-gdiplus-color ctx/brush-color :handle
        ctx/gp-brush: handle
    ]
]

update-gdiplus-pen: func [ctx [draw-ctx!] /local handle [integer!]][
    either ctx/pen? [
        if ctx/gp-pen-saved <> 0 [
            ctx/gp-pen: ctx/gp-pen-saved
            ctx/gp-pen-saved: 0
        ]
        handle: ctx/gp-pen
        GdipSetPenColor handle to-gdiplus-color ctx/pen-color
        GdipSetPenWidth handle ctx/pen-width
        if ctx/pen-join <> 0 [
            OS-draw-line-join ctx ctx/pen-join
        ]
        if ctx/pen-cap <> 0 [
            OS-draw-line-cap ctx ctx/pen-cap
        ]
    ][
        ctx/gp-pen-saved: ctx/gp-pen
        ctx/gp-pen: 0
    ]
]

update-brush: func [ctx [draw-ctx!] /local handle [handle!]][
    if 0 <> ctx/brush [DeleteObject as handle! ctx/brush]
    handle: either ctx/brush? [
        CreateSolidBrush ctx/brush-color
    ][
        GetStockObject NULL_BRUSH
    ]
    ctx/brush: as-integer handle
    SelectObject ctx/dc handle
]

update-pen: func [
    ctx		  [draw-ctx!]
    /local
        mode  [integer!]
        cap   [integer!]
        join  [integer!]
        pen   [handle!]
        brush [tagLOGBRUSH]
][
    mode: 0
    if 0 <> ctx/pen [DeleteObject as handle! ctx/pen]
    either ctx/pen? [
        cap: ctx/pen-cap
        join: ctx/pen-join
        pen: either all [join = -1 cap = -1] [
            CreatePen ctx/pen-style as integer! ctx/pen-width ctx/pen-color
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
            brush/lbColor: ctx/pen-color
            ExtCreatePen
                PS_GEOMETRIC or ctx/pen-style or mode
                as integer! ctx/pen-width
                brush
                0
                null
        ]
        ctx/pen: as-integer pen
    ][
        pen: GetStockObject NULL_PEN
        ctx/pen: 0
    ]
    SelectObject ctx/dc pen
]

update-modes: func [
    ctx [draw-ctx!]
][
    either GDI+? [
        update-gdiplus-modes ctx
    ][
        update-pen ctx
        update-brush ctx
    ]
]

draw-begin: func [
    ctx			[draw-ctx!]
    hWnd		[handle!]
    img			[red-image!]
    on-graphic? [logic!]
    paint?		[logic!]
    return: 	[draw-ctx!]
    /local
        dc		 [handle!]
        rect	 [RECT_STRUCT]
        width	 [integer!]
        height	 [integer!]
        hBitmap  [handle!]
        hBackDC  [handle!]
        graphics [integer!]
][
    zero-memory as byte-ptr! ctx size? draw-ctx!
    ctx/pen-width:		as float32! 1.0
    ctx/pen?:			yes
    ctx/hwnd:			hWnd
    dc:					null

    gradient-pen/extra:         0
    gradient-pen/pair-1:        declare red-pair!
    gradient-pen/pair-2:        declare red-pair!
    gradient-pen/path-data:     declare PATHDATA
    gradient-pen/type:        GRADIENT_NONE
    gradient-pen/count:         0
    gradient-pen/positions?:    false
    gradient-pen/created?:      false 

    gradient-fill/extra:         0
    gradient-fill/pair-1:        declare red-pair!
    gradient-fill/pair-2:        declare red-pair!
    gradient-fill/path-data:     declare PATHDATA
    gradient-fill/type:        GRADIENT_NONE
    gradient-fill/count:         0 
    gradient-fill/positions?:    false
    gradient-fill/created?:      false

    gradient-matrix-pen: 0 
    gradient-matrix-fill: 0 

    D2D?: (get-face-flags hWnd) and FACET_FLAGS_D2D <> 0
    last-point?: no
    prev-shape/type: SHAPE_OTHER
    path-last-point/x: 0
    path-last-point/y: 0

    matrix-order: GDIPLUS_MATRIXORDERAPPEND

    rect: declare RECT_STRUCT
    either null? hWnd [
        ctx/on-image?: yes
        either on-graphic? [
            graphics: as-integer img
        ][
            graphics: 0
            OS-image/GdipGetImageGraphicsContext as-integer img/node :graphics
        ]
        dc: CreateCompatibleDC hScreen
        SelectObject dc default-font
        SetTextColor dc ctx/pen-color
        ctx/dc: dc
        update-gdiplus-font-color ctx ctx/pen-color
    ][
        either D2D? [
            draw-begin-d2d ctx hWnd
            return ctx
        ][
            dc: either paint? [BeginPaint hWnd paint][hScreen]
            GetClientRect hWnd rect
            width: rect/right - rect/left
            height: rect/bottom - rect/top
            hBitmap: CreateCompatibleBitmap dc width height
            hBackDC: CreateCompatibleDC dc
            SelectObject hBackDC hBitmap
            ctx/bitmap: hBitmap

            dc: hBackDC
            ctx/dc: dc

            SetGraphicsMode dc GM_ADVANCED
            SetArcDirection dc AD_CLOCKWISE
            SetBkMode dc BK_TRANSPARENT
            SelectObject dc GetStockObject NULL_BRUSH

            render-base hWnd dc

            graphics: 0
            GdipCreateFromHDC dc :graphics
        ]
    ]

    ctx/graphics: graphics
    GdipCreatePen1
        to-gdiplus-color ctx/pen-color
        ctx/pen-width
        GDIPLUS_UNIT_WORLD
        :graphics
    ctx/gp-pen: graphics
    OS-draw-anti-alias ctx yes
    update-gdiplus-font ctx
    ctx
]

draw-end: func [
    ctx			[draw-ctx!]
    hWnd		[handle!]
    on-graphic? [logic!]
    cache?		[logic!]
    paint?		[logic!]
    /local
        hr		[integer!]
        IUnk	[IUnknown]
        this	[this!]
        pad4	[integer!]
        rect	[RECT_STRUCT]
        width	[integer!]
        height	[integer!]
        bitmap	[integer!]
        old-dc	[integer!]
        dc		[handle!]
][
    if D2D? [
        draw-end-d2d ctx hWnd
        exit
    ]

    dc: ctx/dc
    pad4: 0
    rect: as RECT_STRUCT :pad4
    if paint? [
        GetClientRect hWnd rect
        width: rect/right - rect/left
        height: rect/bottom - rect/top
        BitBlt paint/hdc 0 0 width height dc 0 0 SRCCOPY
    ]

    unless any [on-graphic? zero? ctx/graphics][GdipDeleteGraphics ctx/graphics]
    unless zero? ctx/gp-pen			[GdipDeletePen ctx/gp-pen]
    unless zero? ctx/gp-pen-saved	[GdipDeletePen ctx/gp-pen-saved]
    unless zero? ctx/gp-brush		[GdipDeleteBrush ctx/gp-brush]
    unless zero? ctx/gp-font-brush	[GdipDeleteBrush ctx/gp-font-brush]
    unless zero? ctx/gp-font		[GdipDeleteFont ctx/gp-font]
    unless zero? ctx/image-attr 	[GdipDisposeImageAttributes ctx/image-attr]
    unless zero? ctx/gp-matrix		[GdipDeleteMatrix ctx/gp-matrix]
    unless zero? ctx/pen			[DeleteObject as handle! ctx/pen]
    unless zero? ctx/brush			[DeleteObject as handle! ctx/brush]
    unless zero? gradient-matrix-pen [ GdipDeleteMatrix gradient-matrix-pen ]
    unless zero? gradient-matrix-fill [ GdipDeleteMatrix gradient-matrix-fill ]

    unless ctx/on-image? [
        DeleteObject ctx/bitmap
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
        start-y: center-y + (rad-y-float * sin rad-beg)
        end-y:	 center-y + (rad-y-float * sin rad-end)
        rad-beg: degree-to-radians angle-begin TYPE_COSINE
        rad-end: degree-to-radians angle-begin + angle-len TYPE_COSINE
        start-x: center-x + (rad-x-float * cos rad-beg)
        end-x:	 center-x + (rad-x-float * cos rad-end)
    ][
        rad-beg: degree-to-radians angle-begin TYPE_TANGENT
        rad-end: degree-to-radians angle-begin + angle-len TYPE_TANGENT
        rad-x-y: rad-x-float * rad-y-float
        rad-x-2: rad-x-float * rad-x-float
        rad-y-2: rad-y-float * rad-y-float
        tan-2: as float32! tan rad-beg
        tan-2: tan-2 * tan-2
        start-x: as float! rad-x-y / (sqrt as-float rad-x-2 * tan-2 + rad-y-2)
        start-y: as float! rad-x-y / (sqrt as-float rad-y-2 / tan-2 + rad-x-2)
        if all [angle-begin > 90.0  angle-begin < 270.0][start-x: 0.0 - start-x]
        if all [angle-begin > 180.0 angle-begin < 360.0][start-y: 0.0 - start-y]
        start-x: center-x + start-x
        start-y: center-y + start-y
        angle-begin: angle-begin + angle-len
        tan-2: as float32! tan rad-end
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
    dc			[handle!]
    gp-path		[integer!]
    start		[red-pair!]
    end			[red-pair!]
    rel?		[logic!]
    nr-points	[integer!]
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
            GdipAddPathBeziersI gp-path edges nb + 1
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
    dc			[handle!]
    gp-path		[integer!]
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
            GdipAddPathBeziersI gp-path edges nb
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
    ctx			[draw-ctx!]
    /local
        path	[integer!]
][
    connect-subpath: 0
    either GDI+? [
        path: 0
        GdipCreatePath 0 :path	; alternate fill
        ctx/gp-path: path
        GdipStartPathFigure ctx/gp-path
    ][
        update-modes ctx
        BeginPath ctx/dc
    ]
]

OS-draw-shape-endpath: func [
    ctx			[draw-ctx!]
    close?		[logic!]
    return:		[logic!]
    /local
        alpha   [byte!]
        width   [integer!]
        height  [integer!]
        ftn     [integer!]
        bf      [tagBLENDFUNCTION]
        count   [integer!]
        result  [logic!]
        point   [tagPOINT]
        dc		[handle!]
][
    result: true

    either GDI+? [
        count: 0
        GdipGetPointCount ctx/gp-path :count
        if count > 0 [
            check-gradient-shape ctx                          ;-- check for gradient
            if close? [ GdipClosePathFigure ctx/gp-path ]
            GdipDrawPath ctx/graphics ctx/gp-pen ctx/gp-path
            GdipFillPath ctx/graphics ctx/gp-brush ctx/gp-path
            GdipDeletePath ctx/gp-path
        ]
    ][
        dc: ctx/dc
        if close? [ CloseFigure dc ]
        EndPath dc
        count: GetPath dc edges types 0
        if count > 0 [
            count: GetPath dc edges types count
            FillPath dc
            PolyDraw dc edges types count
        ]
    ]
    result
]

OS-draw-shape-moveto: func [
    ctx		[draw-ctx!]
    coord	[red-pair!]
    rel?	[logic!]
    /local
        pt	[tagPOINT]
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
        GdipStartPathFigure ctx/gp-path
    ][
        pt: declare tagPOINT
        MoveToEx ctx/dc path-last-point/x path-last-point/y pt
    ]
]

OS-draw-shape-line: func [
    ctx			[draw-ctx!]
    start		[red-pair!]
    end			[red-pair!]
    rel?		[logic!]
    /local
        pt		[tagPOINT]
        nb		[integer!]
        pair	[red-pair!]
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
        GdipAddPathLine2I ctx/gp-path edges nb
    ][
        Polyline ctx/dc edges nb
    ]
    last-point?: yes
    prev-shape/type: SHAPE_OTHER
    connect-subpath: 1
]

OS-draw-shape-axis: func [
    ctx         [draw-ctx!]
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
            GdipAddPathLine2I ctx/gp-path edges nb
        ][
            Polyline ctx/dc edges nb
        ]
        prev-shape/type: SHAPE_OTHER
        connect-subpath: 1
    ]
]

OS-draw-shape-curve: func [
    ctx		[draw-ctx!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    draw-curves ctx/dc ctx/gp-path start end rel? 3
]

OS-draw-shape-qcurve: func [
    ctx		[draw-ctx!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    draw-curves ctx/dc ctx/gp-path start end rel? 2
]

OS-draw-shape-curv: func [
    ctx		[draw-ctx!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    draw-short-curves ctx/dc ctx/gp-path start end rel? 2
]

OS-draw-shape-qcurv: func [
    ctx		[draw-ctx!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    draw-short-curves ctx/dc ctx/gp-path start end rel? 1
]

OS-draw-shape-arc: func [
    ctx		[draw-ctx!]
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
        dc			[handle!]
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
        cos-val: cos degree-to-radians theta TYPE_COSINE
        sin-val: sin degree-to-radians theta TYPE_SINE
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
        angle-1: radian-to-degrees atan (float/abs ((p1-y - center-y) / (p1-x - center-x)))
        angle-1: adjust-angle (p1-x - center-x) (p1-y - center-y) angle-1
        angle-2: radian-to-degrees atan (float/abs ((p2-y - center-y) / (p2-x - center-x)))
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

            GdipAddPathPath ctx/gp-path path connect-subpath
            GdipDeletePath path
        ][
            dc: ctx/dc
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
    ctx [draw-ctx!]
    on? [logic!]
][
    anti-alias?: on?
    either on? [
        GDI+?: yes
        GdipSetSmoothingMode ctx/graphics GDIPLUS_ANTIALIAS
        GdipSetTextRenderingHint ctx/graphics TextRenderingHintAntiAliasGridFit
    ][
        GDI+?: no
        if ctx/on-image? [anti-alias?: yes GDI+?: yes]			;-- always use GDI+ to draw on image
        GdipSetSmoothingMode ctx/graphics GDIPLUS_HIGHSPPED
        GdipSetTextRenderingHint ctx/graphics TextRenderingHintSystemDefault
    ]
    update-modes ctx
]

OS-draw-line: func [
    ctx	   [draw-ctx!]
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
        GdipDrawLinesI ctx/graphics ctx/gp-pen edges nb
    ][
        Polyline ctx/dc edges nb
    ]
]

OS-draw-pen: func [
    ctx		[draw-ctx!]
    color	[integer!]									;-- 00bbggrr format
    off?	[logic!]
    alpha?	[logic!]
][
    if all [off? ctx/pen? <> off?][exit]

    ctx/alpha-pen?: alpha?
    GDI+?: any [alpha? anti-alias? ctx/alpha-brush?]

    if any [ctx/pen-color <> color ctx/pen? = off?][
        ctx/pen?: not off?
        ctx/pen-color: color
        either GDI+? [update-gdiplus-pen ctx][update-pen ctx]
    ]

    unless ctx/font-color? [
        if GDI+? [update-gdiplus-font-color ctx color]
        unless ctx/on-image? [SetTextColor ctx/dc color]
    ]
]

OS-draw-fill-pen: func [
    ctx		[draw-ctx!]
    color	[integer!]									;-- 00bbggrr format
    off?	[logic!]
    alpha?	[logic!]
][
    if all [off? ctx/brush? <> off?][exit]

    ctx/alpha-brush?: alpha?
    GDI+?: any [alpha? anti-alias? ctx/alpha-pen?]

    if any [ctx/brush-color <> color ctx/brush? = off?][
        ctx/brush?: not off?
        ctx/brush-color: color
        either GDI+? [update-gdiplus-brush ctx][update-brush ctx]
    ]
]

OS-draw-line-width: func [
    ctx			[draw-ctx!]
    width		[red-value!]
    /local 
        width-v [float32!]
][
    width-v: get-float32 as red-integer! width
    if ctx/pen-width <> width-v [
        ctx/pen-width: width-v
        either GDI+? [
            GdipSetPenWidth ctx/gp-pen ctx/pen-width
        ][
            update-pen ctx
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
    ctx			[draw-ctx!]
    x			[integer!]
    y			[integer!]
    width		[integer!]
    height		[integer!]
    radius		[integer!]
    fill?		[logic!]
    /local
        path	[integer!]
][
    path: 0
    GdipCreatePath GDIPLUS_FILLMODE_ALTERNATE :path
    gdiplus-roundrect-path path x y width height radius
    if fill? [
        GdipFillPath ctx/graphics ctx/gp-brush path
    ]
    GdipDrawPath ctx/graphics ctx/gp-pen path
    GdipDeletePath path
]

OS-draw-box: func [
    ctx			[draw-ctx!]
    upper		[red-pair!]
    lower		[red-pair!]
    /local
        t		[integer!]
        radius	[red-integer!]
        rad		[integer!]
][
    either TYPE_OF(lower) = TYPE_INTEGER [
        radius: as red-integer! lower
        lower:  lower - 1
        rad: radius/value * 2
        either GDI+? [
            check-gradient-box ctx upper lower
            gdiplus-draw-roundbox
                ctx
                upper/x
                upper/y
                lower/x - upper/x
                lower/y - upper/y
                rad
                ctx/brush?
        ][
            RoundRect ctx/dc upper/x upper/y lower/x lower/y rad rad
        ]
    ][
        either GDI+? [
            if upper/x > lower/x [t: upper/x upper/x: lower/x lower/x: t]
            if upper/y > lower/y [t: upper/y upper/y: lower/y lower/y: t]
            check-gradient-box ctx upper lower
            unless zero? ctx/gp-brush [				;-- fill rect
                GdipFillRectangleI
                    ctx/graphics
                    ctx/gp-brush
                    upper/x
                    upper/y
                    lower/x - upper/x
                    lower/y - upper/y
            ]
            GdipDrawRectangleI
                ctx/graphics
                ctx/gp-pen
                upper/x
                upper/y
                lower/x - upper/x
                lower/y - upper/y
        ][
            Rectangle ctx/dc upper/x upper/y lower/x lower/y
        ]
    ]
]

OS-draw-triangle: func [		;@@ TBD merge this function with OS-draw-polygon
    ctx		[draw-ctx!]
    start	[red-pair!]
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
        check-gradient-poly ctx edges 3
        if ctx/brush? [
            GdipFillPolygonI
                ctx/graphics
                ctx/gp-brush
                edges
                4
                GDIPLUS_FILLMODE_ALTERNATE
        ]
        GdipDrawPolygonI ctx/graphics ctx/gp-pen edges 4
    ][
        either ctx/brush? [
            Polygon ctx/dc edges 4
        ][
            Polyline ctx/dc edges 4
        ]
    ]
]

OS-draw-polygon: func [
    ctx		[draw-ctx!]
    start	[red-pair!]
    end		[red-pair!]
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
        check-gradient-poly ctx edges nb
        if ctx/brush? [
            GdipFillPolygonI
                ctx/graphics
                ctx/gp-brush
                edges
                nb + 1
                GDIPLUS_FILLMODE_ALTERNATE
        ]
        GdipDrawPolygonI ctx/graphics ctx/gp-pen edges nb + 1
    ][
        either ctx/brush? [
            Polygon ctx/dc edges nb + 1
        ][
            Polyline ctx/dc edges nb + 1
        ]
    ]
]

OS-draw-spline: func [
    ctx		[draw-ctx!]
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

    unless GDI+? [update-gdiplus-modes ctx]					;-- force to use GDI+

    if ctx/brush? [
        GdipFillClosedCurveI
            ctx/graphics
            ctx/gp-brush
            edges
            nb
            GDIPLUS_FILLMODE_ALTERNATE
    ]
    either closed? [
        GdipDrawClosedCurveI ctx/graphics ctx/gp-pen edges nb
    ][
        GdipDrawCurveI ctx/graphics ctx/gp-pen edges nb
    ]
]

do-draw-ellipse: func [
    ctx		[draw-ctx!]
    x		[integer!]
    y		[integer!]
    width	[integer!]
    height	[integer!]
][
    either GDI+? [
        check-gradient-ellipse ctx x y width height
        if ctx/brush? [
            GdipFillEllipseI
                ctx/graphics
                ctx/gp-brush
                x
                y
                width
                height
        ]
        GdipDrawEllipseI
            ctx/graphics
            ctx/gp-pen
            x
            y
            width
            height
    ][	
        Ellipse ctx/dc x y x + width y + height
    ]
]

OS-draw-circle: func [
    ctx		[draw-ctx!]
    center	[red-pair!]
    radius	[red-integer!]
    /local
        rad-x [integer!]
        rad-y [integer!]
        w	  [integer!]
        h	  [integer!]
        f	  [red-float!]
][
    if D2D? [
        OS-draw-circle-d2d ctx center radius
        exit
    ]
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
    do-draw-ellipse ctx center/x - rad-x center/y - rad-y w h
]

OS-draw-ellipse: func [
    ctx		 [draw-ctx!]
    upper	 [red-pair!]
    diameter [red-pair!]
][
    do-draw-ellipse ctx upper/x upper/y diameter/x diameter/y
]

OS-draw-font: func [
    ctx		[draw-ctx!]
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
        make-font get-face-obj ctx/hwnd font
    ]

    SelectObject ctx/dc hFont
    ctx/font-color?: either TYPE_OF(color) = TYPE_TUPLE [
        SetTextColor ctx/dc color/array1
        if ctx/on-image? [update-gdiplus-font-color ctx color/array1]
        yes
    ][
        no
    ]
    if ctx/on-image? [update-gdiplus-font ctx]
]

OS-draw-text: func [
    ctx		[draw-ctx!]
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
    either ctx/on-image? [
        x: 0
        rect: as RECT_STRUCT_FLOAT32 :x
        rect/x: as float32! pos/x
        rect/y: as float32! pos/y
        rect/width: as float32! 0
        rect/height: as float32! 0
        GdipDrawString ctx/graphics str len ctx/gp-font rect 0 ctx/gp-font-brush
    ][
        ExtTextOut ctx/dc pos/x pos/y ETO_CLIPPED null str len null
    ]
]

OS-draw-arc: func [
    ctx	   [draw-ctx!]
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
        dc			[handle!]
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
            if ctx/brush? [
                GdipFillPieI
                    ctx/graphics
                    ctx/gp-brush
                    center/x - rad-x
                    center/y - rad-y
                    rad-x << 1
                    rad-y << 1
                    angle-begin
                    angle-len
            ]
            GdipDrawPieI
                ctx/graphics
                ctx/gp-pen
                center/x - rad-x
                center/y - rad-y
                rad-x << 1
                rad-y << 1
                angle-begin
                angle-len
        ][
            GdipDrawArcI
                ctx/graphics
                ctx/gp-pen
                center/x - rad-x
                center/y - rad-y
                rad-x << 1
                rad-y << 1
                angle-begin
                angle-len
        ]
    ][
        dc: ctx/dc
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
                center/x + rad-x
                center/y + rad-y
                as integer! arc-points/start-x
                as integer! arc-points/start-y
                as integer! arc-points/end-x
                as integer! arc-points/end-y
        ][
            Arc
                dc
                center/x - rad-x
                center/y - rad-y
                center/x + rad-x
                center/y + rad-y
                as integer! arc-points/start-x
                as integer! arc-points/start-y
                as integer! arc-points/end-x
                as integer! arc-points/end-y
        ]
        SetArcDirection dc prev-dir
    ]
]

OS-draw-curve: func [
    ctx		[draw-ctx!]
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
        GdipDrawBeziersI ctx/graphics ctx/gp-pen edges 4
    ][
        PolyBezier ctx/dc edges 4
    ]
]

OS-draw-line-join: func [
    ctx		[draw-ctx!]
    style	[integer!]
    /local
        mode  [integer!]
][
    mode: 0
    ctx/pen-join: style
    either GDI+? [
        case [
            style = miter		[mode: GDIPLUS_MITER]
            style = miter-bevel [mode: GDIPLUS_MITERCLIPPED]
            style = _round		[mode: GDIPLUS_ROUND]
            style = bevel		[mode: GDIPLUS_BEVEL]
            true				[mode: GDIPLUS_MITER]
        ]
        GdipSetPenLineJoin ctx/gp-pen mode
    ][
        update-pen ctx PEN_LINE_JOIN
    ]
]
    
OS-draw-line-cap: func [
    ctx		[draw-ctx!]
    style	[integer!]
    /local
        mode  [integer!]
][
    mode: 0
    ctx/pen-cap: style
    either GDI+? [
        case [
            style = flat		[mode: GDIPLUS_LINECAPFLAT]
            style = square		[mode: GDIPLUS_LINECAPSQUARE]
            style = _round		[mode: GDIPLUS_LINECAPROUND]
            true				[mode: GDIPLUS_LINECAPFLAT]
        ]
        GdipSetPenStartCap ctx/gp-pen mode
        GdipSetPenEndCap ctx/gp-pen mode
    ][
        update-pen ctx PEN_LINE_CAP
    ]
]

OS-draw-image: func [
    ctx			[draw-ctx!]
    image		[red-image!]
    start		[red-pair!]
    end			[red-pair!]
    key-color	[red-tuple!]
    border?		[logic!]
    crop1		[red-pair!]
    pattern		[red-word!]
    /local
        x		[integer!]
        y		[integer!]
        width	[integer!]
        height	[integer!]
        src-x	[integer!]
        src-y	[integer!]
        w		[integer!]
        h		[integer!]
        attr	[integer!]
        color	[integer!]
        crop2	[red-pair!]
        pts		[tagPOINT]
][
    attr: 0
    if key-color <> null [
        attr: ctx/image-attr
        if zero? attr [GdipCreateImageAttributes :attr]
        color: to-gdiplus-color key-color/array1
        GdipSetImageAttributesColorKeys attr 0 true color color
    ]
    either crop1 = null [
        src-x: 0 src-y: 0
        w: IMAGE_WIDTH(image/size)
        h: IMAGE_HEIGHT(image/size)
    ][
        crop2: crop1 + 1
        src-x: crop1/x
        src-y: crop1/y
        w: crop2/x
        h: crop2/y
    ]
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
                ctx/graphics as-integer image/node edges 3
                0 0 w h GDIPLUS_UNIT_PIXEL attr 0 0
            exit
        ]
        true [exit]							;@@ TBD four control points
    ]
    GdipDrawImageRectRectI
        ctx/graphics as-integer image/node
        x y width height src-x src-y w h
        GDIPLUS_UNIT_PIXEL attr 0 0
]

get-shape-center: func [
    start   [tagPOINT]
    count   [integer!]
    cx      [int-ptr!]
    cy      [int-ptr!]
    d       [int-ptr!]
    /local
        point   [tagPOINT]
        dx      [integer!]
        dy      [integer!]
        x0      [integer!]
        y0      [integer!]
        x1      [integer!]
        y1      [integer!]
        a       [integer!]
        r       [integer!]
        signedArea  [float!]
        centroid-x  [float!]
        centroid-y  [float!]
][
    ;-- implementation taken from http://stackoverflow.com/questions/2792443/finding-the-centroid-of-a-polygon
    x0: 0 y0: 0 x1: 0 y1: 0
    a: 0 signedArea: 0.0
    centroid-x: 0.0 centroid-y: 0.0
    point: start
    loop count - 1 [
        x0: point/x
        y0: point/y
        point: point + 1
        x1: point/x
        y1: point/y
        a: x0 * y1 - (x1 * y0)
        signedArea: signedArea + as-float a
        centroid-x: centroid-x + as-float ((x0 + x1) * a)
        centroid-y: centroid-y + as-float ((y0 + y1) * a)
    ]
    x0: point/x
    y0: point/y
    x1: start/x
    y1: start/y
    a: x0 * y1 - (x1 * y0)
    signedArea: signedArea + as-float a
    centroid-x: centroid-x + as-float ((x0 + x1) * a)
    centroid-y: centroid-y + as-float ((y0 + y1) * a)

    signedArea: signedArea * 0.5
    centroid-x: centroid-x / (signedArea * 6.0) 
    centroid-y: centroid-y / (signedArea * 6.0) 

    cx/value: as-integer centroid-x
    cy/value: as-integer centroid-y
    ;-- take biggest distance
    d/value: 0
    point: start
    loop count [
        dx: cx/value - point/x
        dy: cy/value - point/y
        r: as-integer sqrt as-float ( dx * dx + ( dy * dy ) )
        if r > d/value [ d/value: r ]
        point: point + 1
    ] 
]

get-shape-bounding-box: func [
    start   [tagPOINT]
    count   [integer!]
    upper   [tagPOINT]
    lower   [tagPOINT]
    /local
        point   [tagPOINT]
][
    upper/x: 1000000 
    upper/y: 1000000
    lower/x: 0
    lower/y: 0
    point: start
    loop count [
        if point/x > lower/x [ lower/x: point/x ]
        if point/y > lower/y [ lower/y: point/y ]
        if point/x < upper/x [ upper/x: point/x ]
        if point/y < upper/y [ upper/y: point/y ]
        point: point + 1
    ]
]

gradient-transform: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    gm          [integer!]
    /local
        brush   [integer!]
][
    either gradient/type = GRADIENT_LINEAR [
        brush: 0
        GdipGetPenBrushFill ctx/gp-pen :brush
        GdipSetLineTransform brush gm
    ][
        GdipSetPathGradientTransform ctx/gp-brush gm
    ]
]

gradient-transf-reset: func [
    gradient    [gradient!]
    /local 
        mm      [int-ptr!]
][
    mm: either gradient = gradient-pen [ :gradient-matrix-pen ][ :gradient-matrix-fill ]
    either zero? mm/value [
        GdipCreateMatrix mm
    ][
        GdipSetMatrixElements 
            mm/value
            as-float32 1 
            as-float32 0 
            as-float32 0 
            as-float32 1 
            as-float32 0 
            as-float32 0
    ]
]

save-brush: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    brush       [integer!]
][
    GDI+?: yes
    gradient/created?: true
    either gradient = gradient-fill [
        unless zero? ctx/gp-brush	[GdipDeleteBrush ctx/gp-brush]
        ctx/gp-brush: brush
    ][
        GdipSetPenBrushFill ctx/gp-pen brush
    ]
]

gradient-linear: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    _colors     [int-ptr!]
    _colors-pos [pointer! [float32!]]
    point-1     [tagPOINT]
    point-2     [tagPOINT]
    /local
        brush	[integer!]
        count   [integer!]
        gm      [integer!]
][
    brush: 0
    count: gradient/count
    unless gradient/extra = 0 [
        point-1/x: point-1/x - gradient/extra - 1
        point-2/x: point-2/x + gradient/extra + 1
        gradient/extra: 0
    ] 
    GdipCreateLineBrushI point-1 point-2 _colors/1 _colors/count 0 :brush
    GdipSetLinePresetBlend brush _colors _colors-pos count

    gm: either gradient = gradient-pen [ gradient-matrix-pen ][ gradient-matrix-fill ]
    GdipSetLineTransform brush gm

    save-brush ctx gradient brush
]

gradient-radial-diamond: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    _colors     [int-ptr!]
    _colors-pos [pointer! [float32!]]
    center      [tagPOINT]
    focal       [tagPOINT]
    radius      [integer!]
    /local
        brush	[integer!]
        count   [integer!]
        color   [int-ptr!]
        size    [integer!]
        n		[integer!]
        width   [integer!]
        height  [integer!]
        x       [integer!]
        y       [integer!]
        other   [tagPOINT]
        gm      [integer!]
][
    brush: 0

    count: gradient/count
    GdipCreatePath GDIPLUS_FILLMODE_ALTERNATE :brush

    other: gradient/data + INDEX_OTHER
    either gradient/type = GRADIENT_RADIAL [
        size: radius * 2
        x: center/x - radius
        y: center/y - radius
        unless gradient/extra = 0 [
            x: x - gradient/extra - 1
            y: y - gradient/extra - 1
            size: 2 * gradient/extra + size
            gradient/extra: 0
        ] 
        GdipAddPathEllipseI brush x y size size
        other/x: focal/x
        other/y: focal/y
    ][
        x: center/x
        y: center/y
        width: focal/x - center/x + 1
        height: focal/y - center/y + 1
        unless gradient/extra = 0 [
            x: x - gradient/extra - 1
            y: y - gradient/extra - 1
            width: 2 * gradient/extra + height
            height: 2 * gradient/extra + height
            gradient/extra: 0
        ] 
        GdipAddPathRectangleI brush x y width height
    ]

    n: brush
    GdipCreatePathGradientFromPath n :brush
    GdipDeletePath n
    GdipSetPathGradientCenterColor brush _colors/value
    either gradient/type = GRADIENT_RADIAL [
        GdipSetPathGradientCenterPointI brush focal
    ][
        unless radius = INVALID_RADIUS [ GdipSetPathGradientCenterPointI brush other ]
    ]
    reverse-int-array _colors count
    reverse-float32-array _colors-pos count
    GdipSetPathGradientPresetBlend brush _colors _colors-pos count
    reverse-int-array _colors count
    reverse-float32-array _colors-pos count

    gm: either gradient = gradient-pen [ gradient-matrix-pen ][ gradient-matrix-fill ]
    GdipSetPathGradientTransform brush gm

    save-brush ctx gradient brush
]

check-gradient: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    _colors     [int-ptr!]
    _colors-pos [pointer! [float32!]]
    /local
        upper       [tagPOINT]
        lower       [tagPOINT]
        radius      [tagPOINT]
][
    INIT_GRADIENT_DATA(upper lower radius)
    if all [ gradient = gradient-pen ctx/pen-width > as float32! 1.0 ] [
        gradient/extra: as-integer ctx/pen-width / 2
    ]
    case [
        gradient/type = GRADIENT_LINEAR [
            gradient-linear ctx gradient _colors _colors-pos upper lower
        ]
        any [
            gradient/type = GRADIENT_RADIAL 
            gradient/type = GRADIENT_DIAMOND
        ][
            gradient-radial-diamond ctx gradient _colors _colors-pos upper lower radius/x
        ]
        true []
    ]
]

_check-gradient-box: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    _colors     [int-ptr!]
    _colors-pos [pointer! [float32!]]
    upper       [red-pair!]
    lower       [red-pair!]
    /local
        dx      [integer!]
        dy      [integer!]
        _upper  [tagPOINT]
        _lower  [tagPOINT]
        _other  [tagPOINT]
][
    INIT_GRADIENT_DATA(_upper _lower _other)
    case [
        any [
            gradient/type = GRADIENT_LINEAR
            gradient/type = GRADIENT_DIAMOND 
        ][
            _upper/x: upper/x 
            _lower/x: lower/x 
            either gradient/type = GRADIENT_LINEAR [
                _upper/y: 0
                _lower/y: 0
            ][
                _upper/y: upper/y
                _lower/y: lower/y
            ]
            _other/x: INVALID_RADIUS
        ]
        gradient/type = GRADIENT_RADIAL [
            dx: ( lower/x - upper/x + 1 ) / 2
            dy: ( lower/y - upper/y + 1 ) / 2
            _upper/x: upper/x + dx 
            _upper/y: upper/y + dy
            _lower/x: _upper/x
            _lower/y: _upper/y
            _other/x: as-integer sqrt as-float (dx * dx + ( dy * dy ) )
        ]
        true []
    ]
    check-gradient ctx gradient _colors _colors-pos _upper _lower _other
]
check-gradient-box: func [
    ctx		[draw-ctx!]
    upper   [red-pair!]
    lower   [red-pair!]
][
    if all [ gradient-pen? not gradient-pen/positions? ][
        _check-gradient-box ctx gradient-pen pen-colors pen-colors-pos upper lower
    ]
    if all [ gradient-fill? not gradient-fill/positions? ][
        ctx/brush?: true
        _check-gradient-box ctx gradient-fill colors colors-pos upper lower
    ]
]

_check-gradient-ellipse: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    _colors     [int-ptr!]
    _colors-pos [pointer! [float32!]]
    x       [integer!]
    y       [integer!]
    width   [integer!]
    height  [integer!]
    /local
        dx      [integer!]
        dy      [integer!]
        upper   [tagPOINT]
        lower   [tagPOINT]
        other   [tagPOINT]
][
    INIT_GRADIENT_DATA(upper lower other)
    case [
        any [
            gradient/type = GRADIENT_LINEAR
            gradient/type = GRADIENT_DIAMOND 
        ][
            upper/x: x 
            lower/x: x + width 
            either gradient/type = GRADIENT_LINEAR [
                upper/y: 0
                lower/y: 0
            ][
                upper/y: y 
                lower/y: y + height
            ]
            other/x: INVALID_RADIUS
        ]
        gradient/type = GRADIENT_RADIAL [
            dx: width / 2
            dy: height / 2
            upper/x: x + dx
            upper/y: y + dy
            lower/x: upper/x
            lower/y: upper/y
            other/x: either dx > dy [dx][dy]
        ]
        true []
    ]
    check-gradient ctx gradient _colors _colors-pos upper lower other
]
check-gradient-ellipse: func [
    ctx		[draw-ctx!]
    x       [integer!]
    y       [integer!]
    width   [integer!]
    height  [integer!]
][
    if all [ gradient-pen? not gradient-pen/positions? ][
        _check-gradient-ellipse ctx gradient-pen pen-colors pen-colors-pos x y width height
    ]
    if all [ gradient-fill? not gradient-fill/positions? ][
        ctx/brush?: true
        _check-gradient-ellipse ctx gradient-fill colors colors-pos x y width height
    ]
]

_check-gradient-poly: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    _colors     [int-ptr!]
    _colors-pos [pointer! [float32!]]
    start   [tagPOINT]
    count   [integer!]
    /local
        cx      [integer!]
        cy      [integer!]
        d       [integer!]
        upper   [tagPOINT]
        lower   [tagPOINT]
        other   [tagPOINT]
][
    INIT_GRADIENT_DATA(upper lower other)
    cx: 0 cy: 0 d: 0
    case [
        any [
            gradient/type = GRADIENT_LINEAR
            gradient/type = GRADIENT_DIAMOND 
        ][
            get-shape-bounding-box start count upper lower
            either gradient/type = GRADIENT_LINEAR [
                upper/y: 0
                lower/y: 0
                other/x: INVALID_RADIUS
            ][
                get-shape-center start count :cx :cy :d
                other/x: cx
                other/y: cy
            ]
        ]
        gradient/type = GRADIENT_RADIAL [
            get-shape-center start count :cx :cy :d
            upper/x: cx 
            upper/y: cy
            lower/x: cx 
            lower/y: cy
            other/x: d
        ]
    ]
    check-gradient ctx gradient _colors _colors-pos upper lower other
]
check-gradient-poly: func [
    ctx		[draw-ctx!]
    start   [tagPOINT]
    count   [integer!]
][
    if all [ gradient-pen? not gradient-pen/positions? ][
        _check-gradient-poly ctx gradient-pen pen-colors pen-colors-pos start count
    ]
    if all [ gradient-fill? not gradient-fill/positions? ][
        ctx/brush?: true
        _check-gradient-poly ctx gradient-fill colors colors-pos start count
    ]
]

_check-gradient-shape: func [
    ctx		    [draw-ctx!]
    gradient    [gradient!]
    _colors     [int-ptr!]
    _colors-pos [pointer! [float32!]]
    /local 
        new-path    [integer!]
        count       [integer!]
        result      [integer!]
        points      [tagPOINT]
        point       [tagPOINT]
        pt2F        [POINT_2F]
][
    ;-- flatten path to get a polygon aproximation
    new-path: 0
    GdipClonePath ctx/gp-path :new-path
    GdipFlattenPath new-path 0 as float32! 1.0
    count: 0
    GdipGetPointCount new-path :count
    gradient/path-data/count: count
    gradient/path-data/points: as POINT_2F allocate count * (size? POINT_2F)
    gradient/path-data/types: allocate count 
    GdipGetPathData new-path gradient/path-data
    ;-- translate call to check-gradient-poly (it will draw gradient in the center of aproximated polygon)
    points: as tagPOINT allocate count * (size? tagPOINT)
    point: points
    pt2F:  gradient/path-data/points
    loop count [
        point/x: as-integer pt2F/x 
        point/y: as-integer pt2F/y
        point: point + 1
        pt2F: pt2F + 1
    ]
    _check-gradient-poly ctx gradient _colors _colors-pos points count 
    ;-- free allocated resources
    free as byte-ptr! points
    free as byte-ptr! gradient/path-data/points
    free gradient/path-data/types
]
check-gradient-shape: func [
    ctx		[draw-ctx!]
][
    if all [ gradient-pen? not gradient-pen/positions? ][
        _check-gradient-shape ctx gradient-pen pen-colors pen-colors-pos
    ]
    if all [ gradient-fill? not gradient-fill/positions? ][
        ctx/brush?: true
        _check-gradient-shape ctx gradient-fill colors colors-pos
    ]
]

OS-draw-grad-pen: func [
    ctx			[draw-ctx!]
    mode		[integer!]
    stops		[red-value!]
    count       [integer!]
    skip-pos    [logic!]
    positions   [red-value!]
    focal?      [logic!]
    spread      [integer!]
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
        radius      [integer!]
        first-point [logic!]
        last-point  [logic!]
        point       [red-pair!]
        value       [red-value!]
        _colors     [int-ptr!]
        _colors-pos [pointer! [float32!]]
        gradient    [gradient!]
        gm          [integer!]
][
    either brush? [
        gradient-fill?: true
        _colors: colors
        _colors-pos: colors-pos 
    ][
        gradient-pen?: true
        _colors: pen-colors
        _colors-pos: pen-colors-pos
    ]
    ;-- stops
    pt: edges
    color: _colors + 1
    pos: _colors-pos + 1
    delta: as-float count - 1
    delta: 1.0 / delta
    p: 0.0
    head: stops
    loop count [
        clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
        color/value: to-gdiplus-color clr/array1
        next: head + 1 
        if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
        pos/value: either mode = linear [ as float32! p ][ as float32! ( 1.0 - p ) ]
        if next <> head [p: p + delta]
        head: head + 1
        color: color + 1
        pos: pos + 1
    ]
    ;-- patch first and last point
    last-p: pos - 1 
    last-c: color - 1
    pos: pos - count
    color: color - count
    first-point: false
    last-point:  false
    either mode = linear [
        _colors-pos/value: as float32! 0.0           ;-- first one should be always 0.0
        if last-p/value < as float32! 1.0 [			;-- last one should be always 1.0
            last-point: true
            last-p: last-p + 1
            last-p/value: as float32! 1.0
        ]
    ][
        _colors-pos/value: as float32! 1.0           ;-- first one should be always 1.0
        if last-p/value > as float32! 0.0 [			;-- last one should be always 0.0
            last-point: true
            last-p: last-p + 1
            last-p/value: as float32! 0.0
        ]
    ]
    _colors/value: color/value
    count: count + 1
    if last-point [
        color: last-c
        last-c: last-c + 1
        last-c/value: color/value
        count: count + 1
    ]
    ctx/brush?:       brush?
    gradient: either ctx/brush? [ gradient-fill ][ gradient-pen ]
    gradient/count:     count
    gradient/created?:  false
    gradient/positions?: false
    gradient-transf-reset gradient
    
    ;-- positions
    case [
        mode = linear [ 
            gradient/type: GRADIENT_LINEAR 
            unless skip-pos [
                gradient/positions?: true
                pt: gradient/data
                point: as red-pair! positions
                pt/x: point/x pt/y: point/y
                pt: pt + 1
                point: as red-pair! (positions + 1)
                pt/x: point/x pt/y: point/y
                gradient-linear ctx gradient _colors _colors-pos gradient/data gradient/data + 1
            ]
        ]
        any [ mode = radial mode = diamond ][
            gradient/type: either mode = radial [ GRADIENT_RADIAL ][ GRADIENT_DIAMOND ] 
            unless skip-pos [
                gradient/positions?: true
                pt: gradient/data
                point: as red-pair! positions
                pt/x: point/x pt/y: point/y
                either mode = radial [
                    value: positions + 1
                    radius: as-integer get-float as red-integer! value
                    pt: pt + 1
                    if focal? [
                        point: as red-pair! ( positions + 2 )
                    ]
                    pt/x: point/x pt/y: point/y
                    pt: pt + 1
                    pt/x: radius
                ][
                    pt: pt + 1
                    point: as red-pair! (positions + 1)
                    pt/x: point/x pt/y: point/y
                    pt: pt + 1
                    either focal? [
                        point: as red-pair! ( positions + 2 )
                        pt/x: point/x 
                        pt/y: point/y
                    ][
                        pt/x: INVALID_RADIUS
                    ]
                ] 
                gradient-radial-diamond ctx gradient _colors _colors-pos gradient/data gradient/data + 1 pt/x
            ] 
        ]
        true [ gradient/type: GRADIENT_NONE ]
    ]
]

OS-set-clip: func [
    ctx		[draw-ctx!]
    upper	[red-value!]
    lower	[red-value!]
    rect?	[logic!]
    mode	[integer!]
    /local
        u	[red-pair!]
        l	[red-pair!]
        dc	[handle!]
        clip-mode 	[integer!]
][
    case [
        mode = replace [ clip-mode: clip-replace ]
        mode = intersect [ clip-mode: clip-intersect ]
        mode = union [ clip-mode: clip-union ]
        mode = xor [ clip-mode: clip-xor ]
        mode = exclude [ clip-mode: clip-diff ]
        true [ clip-mode: clip-replace ]
    ]
    either GDI+? [
        either rect? [
            u: as red-pair! upper
            l: as red-pair! lower
            GdipSetClipRectI
                ctx/graphics
                u/x
                u/y
                l/x - u/x
                l/y - u/y
                clip-mode
        ][
            GdipSetClipPath
                ctx/graphics
                ctx/gp-path
                clip-mode
            GdipDeletePath ctx/gp-path
        ]
    ][
        dc: ctx/dc
        if rect? [
            u: as red-pair! upper
            l: as red-pair! lower
            BeginPath dc
            Rectangle dc u/x u/y l/x l/y  
        ]
        EndPath dc  ;-- a path has already been started
        SelectClipPath dc clip-mode
    ]
]

matrix-rotate: func [
    ctx		[draw-ctx!]
    angle	[red-integer!]
    center	[red-pair!]
    m       [integer!]
    /local
        mm  [integer!]
        pts [tagPOINT]
][
    GDI+?: yes
    pts: edges
    if angle <> as red-integer! center [
        pts/x: center/x
        pts/y: center/y
        mm: ctx/gp-matrix
        if zero? mm [
            GdipCreateMatrix :mm
            ctx/gp-matrix: mm
        ]
        GdipGetWorldTransform ctx/graphics ctx/gp-matrix
        GdipTransformMatrixPointsI ctx/gp-matrix pts 1

        GdipTranslateMatrix m as float32! 0 - pts/x as float32! 0 - pts/y GDIPLUS_MATRIXORDERAPPEND 
    ]
    GdipRotateMatrix m get-float32 angle GDIPLUS_MATRIXORDERAPPEND
    if angle <> as red-integer! center [
        GdipTranslateMatrix m as float32! pts/x as float32! pts/y GDIPLUS_MATRIXORDERAPPEND 
    ]
]

OS-matrix-rotate: func [
    ctx		[draw-ctx!]
    angle	[red-integer!]
    center	[red-pair!]
    /local
        m   [integer!]
][
    GDI+?: yes
    m: 0
    GdipCreateMatrix :m
    matrix-rotate ctx angle center m
    GdipMultiplyWorldTransform ctx/graphics m matrix-order
    GdipDeleteMatrix m
]

OS-matrix-scale: func [
    ctx		[draw-ctx!]
    sx		[red-integer!]
    sy		[red-integer!]
][
    GDI+?: yes
    GdipScaleWorldTransform ctx/graphics get-float32 sx get-float32 sy matrix-order
]

OS-matrix-translate: func [
    ctx	[draw-ctx!]
    x	[integer!]
    y	[integer!]
][
    GDI+?: yes
    GdipTranslateWorldTransform
        ctx/graphics
        as float32! x
        as float32! y
        matrix-order
]

OS-matrix-skew: func [
    ctx		[draw-ctx!]
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
    x: as float32! tan degree-to-radians get-float sx TYPE_TANGENT
    y: as float32! either sx = sy [0.0][tan degree-to-radians get-float sy TYPE_TANGENT]
    GdipCreateMatrix2 u y x u z z :m
    GdipMultiplyWorldTransform ctx/graphics m matrix-order
    GdipDeleteMatrix m
]

OS-matrix-transform: func [
    ctx			[draw-ctx!]
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
    matrix-rotate ctx rotate center m
    GdipScaleMatrix m get-float32 scale get-float32 scale + 1 GDIPLUS_MATRIXORDERAPPEND
    GdipTranslateMatrix m as float32! translate/x as float32! translate/y
    GdipMultiplyWorldTransform ctx/graphics m matrix-order
    GdipDeleteMatrix m
]

OS-matrix-push: func [ctx [draw-ctx!] state [int-ptr!] /local s][
    s: 0
    GdipSaveGraphics ctx/graphics :s
    state/value: s
]

OS-matrix-pop: func [ctx [draw-ctx!] state [integer!]][GdipRestoreGraphics ctx/graphics state]

OS-matrix-reset: func [ctx [draw-ctx!]][GdipResetWorldTransform ctx/graphics]

OS-matrix-invert: func [ctx [draw-ctx!] /local m [integer!]][
    m: ctx/gp-matrix
    if zero? m [
        GdipCreateMatrix :m
        ctx/gp-matrix: m
    ]
    GdipGetWorldTransform ctx/graphics m
    GdipInvertMatrix m
    GdipSetWorldTransform ctx/graphics m
]

OS-matrix-set: func [
    ctx		[draw-ctx!] 
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
    GdipMultiplyWorldTransform ctx/graphics m matrix-order
    GdipDeleteMatrix m
]

OS-set-matrix-order: func [
    order   [integer!]
][ 
    case [
        order = _append [ matrix-order: GDIPLUS_MATRIXORDERAPPEND ]
        order = prepend [ matrix-order: GDIPLUS_MATRIXORDERPREPEND ]
        true [ matrix-order: GDIPLUS_MATRIXORDERAPPEND ]
    ]
]
