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
		_11		[integer!]
		_12		[integer!]
		_21		[integer!]
		_22		[integer!]
		_31		[integer!]
		_32		[integer!]
		m		[D2D_MATRIX_3X2_F]
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
	ctx/pen-style:	0
	ctx/pen?:		yes
	ctx/hwnd:		hWnd
	ctx/font-color:	-1

	this: d2d-ctx
	target: get-hwnd-render-target hWnd
	ctx/dc: as ptr-ptr! this
	ctx/target: as int-ptr! target

	dc: as ID2D1DeviceContext this/vtbl
	;dc/SetTextAntialiasMode this 1				;-- ClearType
	dc/SetTarget this target/bitmap

	dc/BeginDraw this
	_11: 0 _12: 0 _21: 0 _22: 0 _31: 0 _32: 0
	m: as D2D_MATRIX_3X2_F :_32
	m/_11: as float32! 1.0
	m/_22: as float32! 1.0
	dc/SetTransform this m						;-- set to identity matrix

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
		fmt		[this!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	layout: either TYPE_OF(text) = TYPE_OBJECT [				;-- text-box!
		OS-text-box-layout as red-object! text as render-target! ctx/target 0 yes
	][
		fmt: as this! create-text-format as red-object! text null
		create-text-layout text fmt 0 0
	]
	txt-box-draw-background ctx/target pos layout
	dc/DrawTextLayout this as float32! pos/x as float32! pos/y layout ctx/pen 0
	true
]

OS-draw-shape-beginpath: func [
	ctx			[draw-ctx!]
][

]

OS-draw-shape-endpath: func [
	ctx			[draw-ctx!]
	close?		[logic!]
	return:		[logic!]
][

]

OS-draw-shape-close: func [
	ctx		[draw-ctx!]
][

]

OS-draw-shape-moveto: func [
	ctx		[draw-ctx!]
	coord	[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-line: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][

]

OS-draw-shape-axis: func [
	ctx			[draw-ctx!]
	start		[red-value!]
	end			[red-value!]
	rel?		[logic!]
	hline		[logic!]
][

]

OS-draw-shape-curve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-qcurve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-curv: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-qcurv: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-arc: func [
	ctx		[draw-ctx!]
	end		[red-pair!]
	sweep?	[logic!]
	large?	[logic!]
	rel?	[logic!]
][

]

OS-draw-anti-alias: func [
	ctx [draw-ctx!]
	on? [logic!]
][

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
	pt0:  point

	while [pt1: pt0 + 1 pt1 <= end][
		dc/DrawLine
			this
			as float32! pt0/x as float32! pt0/y
			as float32! pt1/x as float32! pt1/y
			ctx/pen
			ctx/pen-width
			0
		pt0: pt0 + 1
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
		rc		[RECT32! value]
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
	gsink/EndFigure sthis 1						;-- D2D1_FIGURE_END_CLOSED

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
][

]

OS-draw-arc: func [
	ctx	   [draw-ctx!]
	center [red-pair!]
	end	   [red-value!]
][

]

OS-draw-curve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
][

]

OS-draw-line-join: func [
	ctx		[draw-ctx!]
	style	[integer!]
][

]

OS-draw-line-cap: func [
	ctx		[draw-ctx!]
	style	[integer!]
][

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
][

]

OS-matrix-scale: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	sy			[red-integer!]
][

]

OS-matrix-translate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	x			[integer!]
	y			[integer!]
][

]

OS-matrix-skew: func [
	ctx		    [draw-ctx!]
	pen-fill    [integer!]
	sx			[red-integer!]
	sy			[red-integer!]
][

]

OS-matrix-transform: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
][
	
]

OS-matrix-push: func [ctx [draw-ctx!] state [draw-state!]][

]

OS-matrix-pop: func [ctx [draw-ctx!] state [draw-state!]][]

OS-matrix-reset: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
][
	
]

OS-matrix-invert: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]

][

]

OS-matrix-set: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	blk			[red-block!]
][
	
]

OS-set-matrix-order: func [
	ctx		[draw-ctx!]
	order	[integer!]
][

]
