Red/System [
	Title:	"DRAW Direct2D Backend"
	Author: "Xie Qingtian"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %text-box.reds

draw-state!: alias struct! [unused [integer!]]

draw-begin: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	paint?		[logic!]
	return: 	[draw-ctx!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		bg-clr	[integer!]
		brush	[integer!]
		target	[render-target!]
		brushes [int-ptr!]
		pbrush	[ID2D1SolidColorBrush]
		d3d-clr [D3DCOLORVALUE]
		values	[red-value!]
		clr		[red-tuple!]
		text	[red-string!]
		pos		[red-pair! value]
][
	zero-memory as byte-ptr! ctx size? draw-ctx!
	ctx/pen-width:	as float32! 1.0
	ctx/pen-join: D2D1_LINE_JOIN_MITER
	ctx/pen-cap: D2D1_CAP_STYLE_FLAT
	ctx/pen-style:	0
	ctx/pen?:		yes
	ctx/hwnd:		hWnd
	update-pen-style ctx

	this: d2d-ctx
	target: get-hwnd-render-target hWnd
	ctx/dc: as ptr-ptr! this
	ctx/target: as int-ptr! target

	dc: as ID2D1DeviceContext this/vtbl
	dc/SetTextAntialiasMode this 1				;-- ClearType
	dc/SetTarget this target/bitmap
	dc/SetAntialiasMode this 0					;-- D2D1_ANTIALIAS_MODE_PER_PRIMITIVE

	dc/BeginDraw this
	matrix2d/identity m
	dc/SetTransform this :m						;-- set to identity matrix

	values: get-face-values hWnd
	clr: as red-tuple! values + FACE_OBJ_COLOR
	bg-clr: either TYPE_OF(clr) = TYPE_TUPLE [clr/array1][-1]
	if bg-clr <> -1 [							;-- paint background
		dc/Clear this to-dx-color bg-clr null
	]

	d3d-clr: to-dx-color ctx/pen-color null
	brush: 0
	dc/CreateSolidColorBrush this d3d-clr null :brush
	ctx/pen: brush

	brush: 0
	dc/CreateSolidColorBrush this d3d-clr null :brush
	ctx/brush: brush

	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) = TYPE_STRING [
		pos/x: 0 pos/y: 0
		OS-draw-text ctx pos as red-string! get-face-obj hWnd yes
	]
	ctx
]

release-ctx: func [
	ctx			[draw-ctx!]
	/local
		IUnk [IUnknown]
		this [this!]
][
	COM_SAFE_RELEASE_OBJ(IUnk ctx/pen)
	COM_SAFE_RELEASE_OBJ(IUnk ctx/brush)
]

draw-end: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	paint?		[logic!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		sc		[IDXGISwapChain1]
		rt		[render-target!]
		hr		[integer!]
][
	release-pen-style ctx
	rt: as render-target! ctx/target
	this: rt/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/EndDraw this null null
	dc/SetTarget this null

	this: rt/swapchain
	sc: as IDXGISwapChain1 this/vtbl
	hr: sc/Present this 0 0

	switch hr [
		COM_S_OK [ValidateRect hWnd null]
		DXGI_ERROR_DEVICE_REMOVED
		DXGI_ERROR_DEVICE_RESET [
			release-ctx ctx
			d2d-release-target rt
			ctx/dc: null
			SetWindowLong hWnd wc-offset - 24 0
			DX-create-dev
			InvalidateRect hWnd null 0
		]
		default [
			0		;@@ TBD log error!!!
		]
	]
]

release-pen-style: func [
	ctx			[draw-ctx!]
	/local
		sthis	[this!]
		style	[ID2D1StrokeStyle]
][
	if ctx/pen-style <> 0 [
		sthis: as this! ctx/pen-style
		style: as ID2D1StrokeStyle sthis/vtbl
		style/Release sthis
		ctx/pen-style: 0
	]
]

update-pen-style: func [
	ctx			[draw-ctx!]
	/local
		prop	[D2D1_STROKE_STYLE_PROPERTIES value]
		d2d		[ID2D1Factory]
		hr		[integer!]
		style	[ptr-value!]
][
	release-pen-style ctx

	prop/startCap: ctx/pen-cap
	prop/endCap: ctx/pen-cap
	prop/dashCap: ctx/pen-cap
	prop/lineJoin: ctx/pen-join
	prop/miterLimit: as float32! 10.0
	prop/dashStyle: 0
	prop/dashOffset: as float32! 0.0

	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreateStrokeStyle d2d-factory prop null 0 :style
	ctx/pen-style: as integer! style/value
]

OS-draw-pen: func [
	ctx		[draw-ctx!]
	color	[integer!]
	off?	[logic!]
	/local
		this	[this!]
		brush	[ID2D1SolidColorBrush]
][
	if any [ctx/pen-color <> color ctx/pen? = off?][
		ctx/pen?: not off?
		ctx/pen-color: color
		unless ctx/font-color? [ctx/font-color: color]	;-- if no font, use pen color for text color
		if ctx/pen? [
			this: as this! ctx/pen
			brush: as ID2D1SolidColorBrush this/vtbl
			brush/SetColor this to-dx-color color null
		]
	]
]

OS-draw-text: func [
	ctx		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	return:	[logic!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		layout	[this!]
		brush	[ID2D1SolidColorBrush]
		color?	[logic!]
		pen		[this!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	layout: either TYPE_OF(text) = TYPE_OBJECT [				;-- text-box!
		OS-text-box-layout as red-object! text as render-target! ctx/target 0 yes
	][
		if null? ctx/text-format [
			ctx/text-format: as this! create-text-format as red-object! text null
		]
		create-text-layout text ctx/text-format 0 0
	]
	color?: no
	if ctx/font-color <> ctx/pen-color [
		pen: as this! ctx/pen
		brush: as ID2D1SolidColorBrush pen/vtbl
		brush/SetColor pen to-dx-color ctx/font-color null
		color?: yes
	]
	txt-box-draw-background ctx/target pos layout
	dc/DrawTextLayout this as float32! pos/x as float32! pos/y layout ctx/pen 0
	if color? [
		brush/SetColor pen to-dx-color ctx/pen-color null
	]
	true
]

OS-draw-shape-beginpath: func [
	ctx			[draw-ctx!]
	/local
		d2d		[ID2D1Factory]
		path	[ptr-value!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sink	[ptr-value!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[D2D_POINT_2F value]
][
	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	ctx/sub/path: as integer! pthis
	ctx/sub/sink: as integer! sthis
	ctx/sub/last-pt-x: as float32! 0.0
	ctx/sub/last-pt-y: as float32! 0.0
	ctx/sub/shape-curve?: no
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/BeginFigure sthis vpoint 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
]

OS-draw-shape-endpath: func [
	ctx			[draw-ctx!]
	close?		[logic!]
	return:		[logic!]
	/local
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		hr		[integer!]
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	pthis: as this! ctx/sub/path
	gpath: as ID2D1PathGeometry pthis/vtbl
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl

	gsink/EndFigure sthis either close? [1][0]

	hr: gsink/Close sthis
	gsink/Release sthis

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	if ctx/brush? [
		dc/FillGeometry this as int-ptr! pthis ctx/brush null
	]
	if ctx/pen? [
		dc/DrawGeometry this as int-ptr! pthis ctx/pen ctx/pen-width ctx/pen-style
	]
	gpath/Release pthis

	ctx/sub/path: 0
	ctx/sub/sink: 0
	true
]

OS-draw-shape-close: func [
	ctx			[draw-ctx!]
	/local
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[D2D_POINT_2F value]
][
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	gsink/EndFigure sthis 1
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/BeginFigure sthis vpoint 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
]

OS-draw-shape-moveto: func [
	ctx			[draw-ctx!]
	coord		[red-pair!]
	rel?		[logic!]
	/local
		dx		[float32!]
		dy		[float32!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[D2D_POINT_2F value]
][
	dx: as float32! coord/x
	dy: as float32! coord/y
	either rel? [
		ctx/sub/last-pt-x: ctx/sub/last-pt-x + dx
		ctx/sub/last-pt-y: ctx/sub/last-pt-y + dy
	][
		ctx/sub/last-pt-x: dx
		ctx/sub/last-pt-y: dy
	]
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	gsink/EndFigure sthis 0
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/BeginFigure sthis vpoint 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
	ctx/sub/shape-curve?: no
]

OS-draw-shape-line: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	/local
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[D2D_POINT_2F value]
		dx		[float32!]
		dy		[float32!]
		x		[float32!]
		y		[float32!]
		pair	[red-pair!]
][
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl

	dx: ctx/sub/last-pt-x
	dy: ctx/sub/last-pt-y
	pair: start
	while [pair <= end][
		x: as float32! pair/x
		y: as float32! pair/y
		if rel? [
			x: x + dx
			y: y + dy
			dx: x
			dy: y
		]
		vpoint/x: x
		vpoint/y: y
		gsink/AddLine sthis vpoint
		pair: pair + 1
	]

	ctx/sub/last-pt-x: x
	ctx/sub/last-pt-y: y
	ctx/sub/shape-curve?: no
]

OS-draw-shape-axis: func [
	ctx			[draw-ctx!]
	start		[red-value!]
	end			[red-value!]
	rel?		[logic!]
	hline?		[logic!]
	/local
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		len		[float32!]
		sx		[float32!]
		sy		[float32!]
		vpoint	[D2D_POINT_2F value]
][
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl

	len: get-float32 as red-integer! start
	sx: ctx/sub/last-pt-x
	sy: ctx/sub/last-pt-y
	either hline? [
		ctx/sub/last-pt-x: either rel? [sx + len][len]
	][
		ctx/sub/last-pt-y: either rel? [sy + len][len]
	]
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/AddLine sthis vpoint
]

draw-curve: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	short?		[logic!]
	num			[integer!]				;--	number of points
	/local
		dx		[float32!]
		dy		[float32!]
		p3y		[float32!]
		p3x		[float32!]
		p2y		[float32!]
		p2x		[float32!]
		p1y		[float32!]
		p1x		[float32!]
		pf		[float32-ptr!]
		pt		[red-pair!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		bezier	[D2D1_BEZIER_SEGMENT value]
		qbezier	[D2D1_QUADRATIC_BEZIER_SEGMENT value]
][
	pt: start + 1
	p1x: as float32! start/x
	p1y: as float32! start/y
	p2x: as float32! pt/x
	p2y: as float32! pt/y
	if num = 3 [					;-- cubic Bézier
		pt: start + 2
		p3x: as float32! pt/x
		p3y: as float32! pt/y
	]

	dx: ctx/sub/last-pt-x
	dy: ctx/sub/last-pt-y
	if rel? [
		pf: :p1x
		loop num [
			pf/1: pf/1 + dx			;-- x
			pf/2: pf/2 + dy			;-- y
			pf: pf + 2
		]
	]

	if short? [
		either ctx/sub/shape-curve? [
			;-- The control point is assumed to be the reflection of the control point
			;-- on the previous command relative to the current point
			p1x: dx * (as float32! 2.0) - ctx/sub/control-x
			p1y: dy * (as float32! 2.0) - ctx/sub/control-y
		][
			;-- if previous command is not curve/curv/qcurve/qcurv, use current point
			p1x: dx
			p1y: dy
		]
	]

	ctx/sub/shape-curve?: yes
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	either num = 3 [				;-- cubic Bézier
		bezier/point1/x: p1x
		bezier/point1/y: p1y
		bezier/point2/x: p2x
		bezier/point2/y: p2y
		bezier/point3/x: p3x
		bezier/point3/y: p3y
		gsink/AddBezier sthis bezier
		ctx/sub/control-x: p2x
		ctx/sub/control-y: p2y
		ctx/sub/last-pt-x: p3x
		ctx/sub/last-pt-y: p3y
	][								;-- quadratic Bézier
		qbezier/point1/x: p1x
		qbezier/point1/y: p1y
		qbezier/point2/x: p2x
		qbezier/point2/y: p2y
		gsink/AddQuadraticBezier sthis qbezier
		ctx/sub/control-x: p1x
		ctx/sub/control-y: p1y
		ctx/sub/last-pt-x: p2x
		ctx/sub/last-pt-y: p2y
	]
]

OS-draw-shape-curve: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve ctx start end rel? no 3
]

OS-draw-shape-qcurve: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve ctx start end rel? no 2
]

OS-draw-shape-curv: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve ctx start - 1 end rel? yes 3
]

OS-draw-shape-qcurv: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve ctx start - 1 end rel? yes 2
]

OS-draw-shape-arc: func [
	ctx			[draw-ctx!]
	end			[red-pair!]
	sweep?		[logic!]
	large?		[logic!]
	rel?		[logic!]
	/local
		item		[red-integer!]
		p1-x		[float32!]
		p1-y		[float32!]
		p2-x		[float32!]
		p2-y		[float32!]
		radius-x	[float32!]
		radius-y	[float32!]
		theta		[float32!]
		arc			[D2D1_ARC_SEGMENT value]
		sthis		[this!]
		gsink		[ID2D1GeometrySink]
][
	;-- parse arguments
	p1-x: ctx/sub/last-pt-x
	p1-y: ctx/sub/last-pt-y
	p2-x: either rel? [ p1-x + as float32! end/x ][ as float32! end/x ]
	p2-y: either rel? [ p1-y + as float32! end/y ][ as float32! end/y ]
	ctx/sub/last-pt-x: p2-x
	ctx/sub/last-pt-y: p2-y
	item: as red-integer! end + 1
	radius-x: get-float32 item
	item: item + 1
	radius-y: get-float32 item
	item: item + 1
	theta: get-float32 item

	arc/point/x: p2-x
	arc/point/y: p2-y
	arc/size/width: radius-x
	arc/size/height: radius-y
	arc/angle: theta
	arc/direction: either sweep? [1][0]
	arc/arcSize: either large? [1][0]

	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	gsink/AddArc sthis arc
]

OS-draw-anti-alias: func [
	ctx			[draw-ctx!]
	on?			[logic!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/SetAntialiasMode this either on? [0][1]
]

_OS-draw-polygon: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	close?		[logic!]
	/local
		d2d		[ID2D1Factory]
		path	[ptr-value!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sink	[ptr-value!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		point	[D2D_POINT_2F value]
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	point/x: as float32! start/x
	point/y: as float32! start/y
	gsink/BeginFigure sthis point 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
	start: start + 1
	while [start <= end] [
		point/x: as float32! start/x
		point/y: as float32! start/y
		gsink/AddLine sthis point
		start: start + 1
	]
	gsink/EndFigure sthis as-integer close?		;-- D2D1_FIGURE_END_CLOSED

	hr: gsink/Close sthis
	gsink/Release sthis

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	if ctx/brush? [
		dc/FillGeometry this as int-ptr! pthis ctx/brush null
	]
	if ctx/pen? [
		dc/DrawGeometry this as int-ptr! pthis ctx/pen ctx/pen-width ctx/pen-style
	]
	gpath/Release pthis
]

OS-draw-line: func [
	ctx	   [draw-ctx!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt0		[red-pair!]
		pt1		[red-pair!]
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	pt0: point
	pt1: pt0 + 1

	either pt1 = end [
		dc/DrawLine
			this
			as float32! pt0/x as float32! pt0/y
			as float32! pt1/x as float32! pt1/y
			ctx/pen
			ctx/pen-width
			ctx/pen-style
	][
		_OS-draw-polygon ctx point end no
	]
]

OS-draw-fill-pen: func [
	ctx		[draw-ctx!]
	color	[integer!]									;-- 00bbggrr format
	off?	[logic!]
	alpha?	[logic!]
	/local
		this	[this!]
		brush	[ID2D1SolidColorBrush]
][
	if any [ctx/brush-color <> color ctx/brush? = off?][
		ctx/brush?: not off?
		ctx/brush-color: color
		if ctx/brush? [
			this: as this! ctx/brush
			brush: as ID2D1SolidColorBrush this/vtbl
			brush/SetColor this to-dx-color color null
		]
	]
]

OS-draw-line-width: func [
	ctx			[draw-ctx!]
	width		[red-value!]
	/local
		width-v [float32!]
][
	width-v: (get-float32 as red-integer! width)
	if ctx/pen-width <> width-v [
		ctx/pen-width: width-v
	]
]

OS-draw-box: func [
	ctx			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		rc		[RECT_F! value]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	rc/right: as float32! lower/x
	rc/bottom: as float32! lower/y
	rc/left: as float32! upper/x
	rc/top: as float32! upper/y
	if ctx/brush? [
		dc/FillRectangle this rc ctx/brush 
	]
	if ctx/pen? [
		dc/DrawRectangle this rc ctx/pen ctx/pen-width ctx/pen-style
	]
]

OS-draw-triangle: func [		;@@ TBD merge this function with OS-draw-polygon
	ctx			[draw-ctx!]
	start		[red-pair!]
][
	OS-draw-polygon ctx start start + 2
]

OS-draw-polygon: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
][
	_OS-draw-polygon ctx start end yes
]

spline-delta: 1.0 / 25.0

do-spline-step: func [
	sthis		[this!]
	p0			[red-pair!]
	p1			[red-pair!]
	p2			[red-pair!]
	p3			[red-pair!]
	/local
		gsink	[ID2D1GeometrySink]
		t		[float!]
		t2		[float!]
		t3		[float!]
		x		[float!]
		y		[float!]
		point	[D2D_POINT_2F value]
][
		gsink: as ID2D1GeometrySink sthis/vtbl
		t: 0.0
		loop 25 [
			t: t + spline-delta
			t2: t * t
			t3: t2 * t

			x:
			   2.0 * (as-float p1/x) + ((as-float p2/x) - (as-float p0/x) * t) +
			   ((2.0 * (as-float p0/x) - (5.0 * (as-float p1/x)) + (4.0 * (as-float p2/x)) - (as-float p3/x)) * t2) +
			   (3.0 * ((as-float p1/x) - (as-float p2/x)) + (as-float p3/x) - (as-float p0/x) * t3) * 0.5
			y:
			   2.0 * (as-float p1/y) + ((as-float p2/y) - (as-float p0/y) * t) +
			   ((2.0 * (as-float p0/y) - (5.0 * (as-float p1/y)) + (4.0 * (as-float p2/y)) - (as-float p3/y)) * t2) +
			   (3.0 * ((as-float p1/y) - (as-float p2/y)) + (as-float p3/y) - (as-float p0/y) * t3) * 0.5
			point/x: as float32! x
			point/y: as float32! y
			gsink/AddLine sthis point
		]
]

OS-draw-spline: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	closed?		[logic!]
	/local
		d2d		[ID2D1Factory]
		path	[ptr-value!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sink	[ptr-value!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		point	[D2D_POINT_2F value]
		this	[this!]
		dc		[ID2D1DeviceContext]
		pt		[red-pair!]
		stop	[red-pair!]
][
	if (as-integer end - start) >> 4 = 1 [		;-- two points input
		OS-draw-line ctx start end				;-- draw a line
		exit
	]

	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	point/x: as float32! start/x
	point/y: as float32! start/y
	gsink/BeginFigure sthis point 1				;-- D2D1_FIGURE_BEGIN_HOLLOW

	either closed? [
		do-spline-step sthis
			end
			start
			start + 1
			start + 2
	][
		do-spline-step sthis
			start
			start
			start + 1
			start + 2
	]

	pt: start
	stop: end - 3

	while [pt <= stop] [
		do-spline-step sthis
			pt
			pt + 1
			pt + 2
			pt + 3
		pt: pt + 1
	]

	either closed? [
		do-spline-step sthis
			end - 2
			end - 1
			end
			start
		do-spline-step sthis
			end - 1
			end
			start
			start + 1
		gsink/EndFigure sthis 1						;-- D2D1_FIGURE_END_CLOSED
	][
		do-spline-step sthis
			end - 2
			end - 1
			end
			end
		gsink/EndFigure sthis 0						;-- D2D1_FIGURE_END_OPEN
	]

	hr: gsink/Close sthis
	gsink/Release sthis

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	if ctx/brush? [
		dc/FillGeometry this as int-ptr! pthis ctx/brush null
	]
	if ctx/pen? [
		dc/DrawGeometry this as int-ptr! pthis ctx/pen ctx/pen-width ctx/pen-style
	]
	gpath/Release pthis
]

do-draw-ellipse: func [
	ctx			[draw-ctx!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		cx		[float32!]
		cy		[float32!]
		rx		[float32!]
		ry		[float32!]
		ellipse	[D2D1_ELLIPSE value]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	cx: as float32! x
	cy: as float32! y
	rx: as float32! width
	ry: as float32! height
	rx: rx / as float32! 2.0
	ry: ry / as float32! 2.0
	ellipse/x: cx + rx
	ellipse/y: cy + ry
	ellipse/radiusX: rx
	ellipse/radiusY: ry
	if ctx/brush? [
		dc/FillEllipse this ellipse ctx/brush
	]
	if ctx/pen? [
		dc/DrawEllipse this ellipse ctx/pen ctx/pen-width ctx/pen-style
	]
]

OS-draw-circle: func [
	ctx			[draw-ctx!]
	center		[red-pair!]
	radius		[red-integer!]
	/local
		rad-x	[integer!]
		rad-y	[integer!]
		w		[integer!]
		h		[integer!]
		f		[red-float!]
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
	do-draw-ellipse ctx center/x - rad-x center/y - rad-y w h
]

OS-draw-ellipse: func [
	ctx			[draw-ctx!]
	upper		[red-pair!]
	diameter	[red-pair!]
][
	do-draw-ellipse ctx upper/x upper/y diameter/x diameter/y
]

OS-draw-font: func [
	ctx		[draw-ctx!]
	font	[red-object!]
	/local
		clr [red-tuple!]
][
	ctx/text-format: as this! create-text-format font null
	;-- set font color
	clr: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
	if TYPE_OF(clr) = TYPE_TUPLE [
		ctx/font-color: clr/array1
		ctx/font-color?: yes
	]
]

OS-draw-arc: func [
	ctx				[draw-ctx!]
	center			[red-pair!]
	end				[red-value!]
	/local
		cx			[float32!]
		cy			[float32!]
		rad			[float32!]
		radius		[red-pair!]
		rad-x		[float32!]
		rad-y		[float32!]
		begin		[red-integer!]
		angle-begin [float32!]
		angle		[red-integer!]
		sweep		[integer!]
		i			[integer!]
		angle-end	[float32!]
		start-x		[float32!]
		start-y		[float32!]
		end-x		[float32!]
		end-y		[float32!]
		closed?		[logic!]
		d2d			[ID2D1Factory]
		path		[ptr-value!]
		hr			[integer!]
		pthis		[this!]
		gpath		[ID2D1PathGeometry]
		sink		[ptr-value!]
		sthis		[this!]
		gsink		[ID2D1GeometrySink]
		point		[D2D_POINT_2F value]
		this		[this!]
		dc			[ID2D1DeviceContext]
		arc			[D2D1_ARC_SEGMENT value]
][
	cx: as float32! center/x
	cy: as float32! center/y
	rad: (as float32! PI) / as float32! 180.0

	radius: center + 1
	rad-x: as float32! radius/x
	rad-y: as float32! radius/y
	begin: as red-integer! radius + 1
	angle-begin: rad * as float32! begin/value
	angle: begin + 1
	sweep: angle/value
	i: begin/value + sweep
	angle-end: rad * as float32! i
	start-x: as float32! cos as float! angle-begin
	start-x: cx + (rad-x * start-x)
	start-y: as float32! sin as float! angle-begin
	start-y: cy + (rad-y * start-y)
	end-x: as float32! cos as float! angle-end
	end-x: cx + (rad-x * end-x)
	end-y: as float32! sin as float! angle-end
	end-y: cy + (rad-y * end-y)

	closed?: angle < end

	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	point/x: start-x
	point/y: start-y
	gsink/BeginFigure sthis point 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
	arc/point/x: end-x
	arc/point/y: end-y
	arc/size/width: rad-x
	arc/size/height: rad-y
	arc/angle: as float32! 0.0
	arc/direction: 1							;-- D2D1_SWEEP_DIRECTION_CLOCKWISE
	arc/arcSize: either sweep >= 180 [1][0]
	hr: gsink/AddArc sthis arc
	gsink/EndFigure sthis either closed? [1][0]

	hr: gsink/Close sthis
	gsink/Release sthis

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	if ctx/brush? [
		dc/FillGeometry this as int-ptr! pthis ctx/brush null
	]
	if ctx/pen? [
		dc/DrawGeometry this as int-ptr! pthis ctx/pen ctx/pen-width ctx/pen-style
	]
	gpath/Release pthis
]

OS-draw-curve: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	/local
		cp1x	[float32!]
		cp1y	[float32!]
		cp2x	[float32!]
		cp2y	[float32!]
		p2		[red-pair!]
		p3		[red-pair!]
		ps		[D2D1_BEZIER_SEGMENT value]
		d2d		[ID2D1Factory]
		path	[ptr-value!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sink	[ptr-value!]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		point	[D2D_POINT_2F value]
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	p2: start + 1
	p3: start + 2

	either 2 = ((as-integer end - start) >> 4) [		;-- p0, p1, p2  -->  p0, (p0 + 2p1) / 3, (2p1 + p2) / 3, p2
		cp1x: (as float32! p2/x << 1 + start/x) / as float32! 3.0
		cp1y: (as float32! p2/y << 1 + start/y) / as float32! 3.0
		cp2x: (as float32! p2/x << 1 + p3/x) / as float32! 3.0
		cp2y: (as float32! p2/y << 1 + p3/y) / as float32! 3.0
	][
		cp1x: as float32! p2/x
		cp1y: as float32! p2/y
		cp2x: as float32! p3/x
		cp2y: as float32! p3/y
	]
	ps/point1/x: cp1x
	ps/point1/y: cp1y
	ps/point2/x: cp2x
	ps/point2/y: cp2y
	ps/point3/x: as float32! end/x
	ps/point3/y: as float32! end/y

	d2d: as ID2D1Factory d2d-factory/vtbl
	hr: d2d/CreatePathGeometry d2d-factory :path
	pthis: as this! path/value
	gpath: as ID2D1PathGeometry pthis/vtbl
	hr: gpath/Open pthis :sink
	sthis: as this! sink/value
	gsink: as ID2D1GeometrySink sthis/vtbl

	point/x: as float32! start/x
	point/y: as float32! start/y
	gsink/BeginFigure sthis point 1				;-- D2D1_FIGURE_BEGIN_HOLLOW
	hr: gsink/AddBezier sthis ps
	gsink/EndFigure sthis 0
	hr: gsink/Close sthis
	gsink/Release sthis

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	if ctx/brush? [
		dc/FillGeometry this as int-ptr! pthis ctx/brush null
	]
	if ctx/pen? [
		dc/DrawGeometry this as int-ptr! pthis ctx/pen ctx/pen-width ctx/pen-style
	]
	gpath/Release pthis
]

OS-draw-line-join: func [
	ctx			[draw-ctx!]
	style		[integer!]
	/local
		mode	[integer!]
][
	case [
		style = miter		[mode: D2D1_LINE_JOIN_MITER]
		style = miter-bevel [mode: D2D1_LINE_JOIN_MITER_OR_BEVEL]
		style = _round		[mode: D2D1_LINE_JOIN_ROUND]
		style = bevel		[mode: D2D1_LINE_JOIN_BEVEL]
		true				[mode: D2D1_LINE_JOIN_MITER]
	]
	ctx/pen-join: mode
	update-pen-style ctx
]

OS-draw-line-cap: func [
	ctx			[draw-ctx!]
	style		[integer!]
	/local
		mode	[integer!]
][
	case [
		style = flat		[mode: D2D1_CAP_STYLE_FLAT]
		style = square		[mode: D2D1_CAP_STYLE_SQUARE]
		style = _round		[mode: D2D1_CAP_STYLE_ROUND]
		true				[mode: D2D1_CAP_STYLE_FLAT]
	]
	ctx/pen-cap: mode
	update-pen-style ctx
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
][

]


OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	img		[red-image!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
][

]

OS-draw-brush-pattern: func [
	ctx		[draw-ctx!]
	size	[red-pair!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	block	[red-block!]
	brush?	[logic!]
][

]


OS-draw-grad-pen-old: func [
	ctx			[draw-ctx!]
	type		[integer!]
	mode		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
][

]

OS-draw-grad-pen: func [
	ctx			[draw-ctx!]
	mode		[integer!]
	stops		[red-value!]
	count		[integer!]
	skip-pos	[logic!]
	positions	[red-value!]
	focal?		[logic!]
	spread		[integer!]
	brush?		[logic!]
][

]

OS-set-clip: func [
	ctx		[draw-ctx!]
	u		[red-pair!]
	l		[red-pair!]
	rect?	[logic!]
	mode	[integer!]
][

]

OS-matrix-rotate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	angle		[red-integer!]
	center		[red-pair!]
	/local
		rad		[float!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	rad: PI / 180.0 * get-float angle
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		either angle <> as red-integer! center [
			matrix2d/translate :m as float32! 0 - center/x as float32! 0 - center/y :t
			matrix2d/rotate :t as float32! rad :m
			matrix2d/translate :m as float32! center/x as float32! center/y :t
		][
			matrix2d/rotate :m as float32! rad :t
		]
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-scale: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	sy			[red-integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/scale :m get-float32 sx get-float32 sy :t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-translate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	x			[integer!]
	y			[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/translate :m as float32! x as float32! y :t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-skew: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	sy			[red-integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
		x		[float32!]
		y		[float32!]
][
	x: as float32! degree-to-radians get-float sx TYPE_TANGENT
	y: as float32! degree-to-radians get-float sy TYPE_TANGENT
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/skew :m x y :t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-transform: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		rotate	[red-integer!]
		center?	[logic!]
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center

	OS-matrix-rotate ctx pen-fill rotate center
	OS-matrix-scale ctx pen-fill scale scale + 1
	OS-matrix-translate ctx pen-fill translate/x translate/y
]

OS-matrix-push: func [ctx [draw-ctx!] state [draw-state!]][

]

OS-matrix-pop: func [ctx [draw-ctx!] state [draw-state!]][]

OS-matrix-reset: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		;dc/GetTransform this :m
		matrix2d/identity :m
		dc/SetTransform this :m
	][
		;-- TBD
		exit
	]
]

OS-matrix-invert: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/invert :m :t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-matrix-set: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	blk			[red-block!]
	/local
		val		[red-integer!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		m0		[D2D_MATRIX_3X2_F value]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
][
	val: as red-integer! block/rs-head blk
	m/_11: get-float32 val
	m/_12: get-float32 val + 1
	m/_21: get-float32 val + 2
	m/_22: get-float32 val + 3
	m/_31: get-float32 val + 4
	m/_32: get-float32 val + 5
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m0
		matrix2d/mul m0 m t
		dc/SetTransform this :t
	][
		;-- TBD
		exit
	]
]

OS-set-matrix-order: func [
	ctx		[draw-ctx!]
	order	[integer!]
][

]
