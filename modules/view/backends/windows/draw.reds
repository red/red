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

#define GAUSSIAN_SCALE_FACTOR 1.87997120597325

#include %text-box.reds

#enum DRAW-BRUSH-TYPE! [
	DRAW_BRUSH_NONE
	DRAW_BRUSH_COLOR
	DRAW_BRUSH_GRADIENT
	DRAW_BRUSH_GRADIENT_SMART
	DRAW_BRUSH_IMAGE_SMART
]

grad-stops: as D2D1_GRADIENT_STOP allocate 256 * size? D2D1_GRADIENT_STOP

calc-brush-position: func [
	brush		[this!]
	grad-type	[integer!]
	offset		[POINT_2F]
	upper-x		[float32!]
	upper-y		[float32!]
	lower-x		[float32!]
	lower-y		[float32!]
	/local
		t		[float32!]
		b		[ID2D1Brush]
		lin		[ID2D1LinearGradientBrush]
		rad		[ID2D1RadialGradientBrush]
		pt		[POINT_2F value]
		t1		[float32!]
		t2		[float32!]
		m		[D2D_MATRIX_3X2_F value]
		result	[D2D_MATRIX_3X2_F value]
][
	if upper-x > lower-x [
		t: upper-x
		upper-x: lower-x
		lower-x: t
	]
	if upper-y > lower-y [
		t: upper-y
		upper-y: lower-y
		lower-y: t
	]
	case [
		grad-type = linear [
			lin: as ID2D1LinearGradientBrush brush/vtbl
			pt/x: F32_0
			pt/y: F32_0
			lin/SetStartPoint brush pt
			pt/x: lower-x - upper-x
			pt/y: F32_0
			lin/SetEndPoint brush pt
		]
		grad-type = radial [
			rad: as ID2D1RadialGradientBrush brush/vtbl
			pt/x: as float32! 0.0
			pt/y: as float32! 0.0
			rad/SetGradientOriginOffset brush pt
			t1: lower-x - upper-x
			t1: t1 / as float32! 2.0
			t2: lower-y - upper-y
			t2: t2 / as float32! 2.0
			pt/x: t1
			pt/y: t2
			rad/SetCenter brush pt
			if t1 > t2 [t1: t2]
			rad/SetRadiusX brush t1
			rad/SetRadiusY brush t1
		]
		true [0]
	]
	;-- apply matrix transformation
	b: as ID2D1Brush brush/vtbl
	b/GetTransform brush :m
	offset/x: upper-x
	offset/y: upper-y
	matrix2d/translate :m upper-x upper-y :result no
	b/SetTransform brush :result
]

post-process-brush: func [
	brush		[this!]
	offset		[POINT_2F]
	/local
		b		[ID2D1Brush]
		m		[D2D_MATRIX_3X2_F value]
		result	[D2D_MATRIX_3X2_F value]
][
	b: as ID2D1Brush brush/vtbl
	b/GetTransform brush :m
	matrix2d/translate :m (F32_0) - offset/x (F32_0) - offset/y :result no
	b/SetTransform brush :result
]

draw-geometry: func [
	ctx			[draw-ctx!]
	path		[this!]
	/local
		dc		[ID2D1DeviceContext]
		this	[this!]
		gpath	[ID2D1PathGeometry]
		bounds	[RECT_F! value]
		bounds?	[logic!]
][
	bounds?: no
	gpath: as ID2D1PathGeometry path/vtbl
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	either ctx/brush-type > DRAW_BRUSH_GRADIENT [		;-- fill-pen
		bounds?: yes
		gpath/GetWidenedBounds path ctx/pen-width ctx/pen-style null as float32! 0.25 :bounds
		calc-brush-position
			ctx/brush
			ctx/brush-grad-type
			ctx/brush-offset
			bounds/left bounds/top bounds/right bounds/bottom
		dc/FillGeometry this path ctx/brush null
		post-process-brush ctx/brush ctx/brush-offset
	][
		if ctx/brush-type <> DRAW_BRUSH_NONE [
			dc/FillGeometry this path ctx/brush null
		]
	]
	either ctx/pen-type > DRAW_BRUSH_GRADIENT [			;-- pen
		unless bounds? [
			bounds?: yes
			gpath/GetWidenedBounds path ctx/pen-width ctx/pen-style null as float32! 0.25 :bounds
		]
		calc-brush-position
			ctx/pen
			ctx/pen-grad-type
			ctx/pen-offset
			bounds/left bounds/top bounds/right bounds/bottom
		dc/DrawGeometry this path ctx/pen ctx/pen-width ctx/pen-style
		post-process-brush ctx/pen ctx/pen-offset
	][
		if ctx/pen-type <> DRAW_BRUSH_NONE [
			dc/DrawGeometry this path ctx/pen ctx/pen-width ctx/pen-style
		]
	]
	gpath/Release path
]

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
		brush	[ptr-value!]
		target	[render-target!]
		brushes [int-ptr!]
		pbrush	[ID2D1SolidColorBrush]
		d3d-clr [D3DCOLORVALUE]
		values	[red-value!]
		clr		[red-tuple!]
		text	[red-string!]
		red-img [red-image!]
		font	[red-object!]
		pos		[red-pair! value]
		pos2	[red-pair!]
		rt		[com-ptr! value]
		wic-bmp	[this!]
		IUnk	[IUnknown]
		t-mode	[integer!]
		props	[D2D1_RENDER_TARGET_PROPERTIES value]
		factory [ID2D1Factory]
		rc		[RECT_F! value]
		font-clr? [logic!]
][
	zero-memory as byte-ptr! ctx size? draw-ctx!
	ctx/pen-width:	as float32! 1.0
	ctx/pen-join: D2D1_LINE_JOIN_MITER
	ctx/pen-cap: D2D1_CAP_STYLE_FLAT
	ctx/pen-style:	null
	ctx/hwnd:		hWnd
	update-pen-style ctx

	t-mode: 1	;-- ClearType
	this: d2d-ctx
	dc: as ID2D1DeviceContext this/vtbl

	either hWnd <> null [
		target: get-hwnd-render-target hWnd on-graphic?
		dc/SetTarget this target/bitmap
		dc/setDpi this dpi-x dpi-y
		if on-graphic? [t-mode: 2]	;-- gray scale for transparent target
	][
		wic-bmp: OS-image/get-wicbitmap img
		OS-image/mark-updated img
		;-- create a bitmap target
		target: as render-target! alloc0 size? render-target!
		target/brushes: as int-ptr! allocate D2D_MAX_BRUSHES * 2 * size? int-ptr!

		zero-memory as byte-ptr! :props size? D2D1_RENDER_TARGET_PROPERTIES
		factory: as ID2D1Factory d2d-factory/vtbl
		if 0 <> factory/CreateWicBitmapRenderTarget d2d-factory wic-bmp :props :rt [
			;TBD error!!!
			probe "CreateWicBitmapRenderTarget failed in draw-begin"
			return ctx
		]
		ctx/image: img/node
		this: rt/value
		dc: as ID2D1DeviceContext this/vtbl
		dc/QueryInterface this IID_ID2D1DeviceContext :rt	;-- Query ID2D1DeviceContext interface
		dc/Release this			;-- QueryInterface will increase the refcnt
		this: rt/value
		dc: as ID2D1DeviceContext this/vtbl
	]
	ctx/dc: as ptr-ptr! this
	ctx/target: as int-ptr! target

	dc/BeginDraw this
	dc/SetTextAntialiasMode this t-mode
	dc/SetAntialiasMode this 0					;-- D2D1_ANTIALIAS_MODE_PER_PRIMITIVE

	if ctx/image <> null [						;-- draw on image!
		rc/left: F32_0
		rc/top: F32_0
		rc/right: as float32! IMAGE_WIDTH(img/size)
		rc/bottom: as float32! IMAGE_HEIGHT(img/size)
		dc/PushAxisAlignedClip this :rc 0		;-- draw text properly on transparent bitmap
	]

	matrix2d/identity m
	dc/SetTransform this :m						;-- set to identity matrix

	d3d-clr: to-dx-color ctx/pen-color null
	dc/CreateSolidColorBrush this d3d-clr null :brush
	ctx/pen: as this! brush/value
	ctx/pen-type:	DRAW_BRUSH_COLOR

	dc/CreateSolidColorBrush this d3d-clr null :brush
	ctx/brush: as this! brush/value
	ctx/brush-type:	DRAW_BRUSH_NONE

	ctx/pre-order?: yes

	if hWnd <> null [
		values: get-face-values hWnd
		clr: as red-tuple! values + FACE_OBJ_COLOR
		bg-clr: either TYPE_OF(clr) = TYPE_TUPLE [clr/array1][-1]
		if any [on-graphic? bg-clr <> -1][		;-- paint background
			dc/Clear this to-dx-color bg-clr null
		]

		red-img: as red-image! values + FACE_OBJ_IMAGE
		if TYPE_OF(red-img) = TYPE_IMAGE [
			pos2: as red-pair! values + FACE_OBJ_SIZE
			OS-draw-image ctx red-img null pos2 null no null null
		]

		text: as red-string! values + FACE_OBJ_TEXT
		if TYPE_OF(text) = TYPE_STRING [
			pos/x: 0 pos/y: 0
			font: as red-object! values + FACE_OBJ_FONT
			font-clr?: no
			if TYPE_OF(font) = TYPE_OBJECT [
				clr: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
				if TYPE_OF(clr) = TYPE_TUPLE [
					ctx/font-color: clr/array1
					font-clr?: yes
				]
			]
			unless font-clr? [		;-- use system's setting
				ctx/font-color: GetSysColor COLOR_WINDOWTEXT
			]
			OS-draw-text ctx :pos as red-string! get-face-obj hWnd yes
			ctx/font-color: 0
		]
	]
	ctx
]

release-ctx: func [
	ctx			[draw-ctx!]
	/local
		IUnk	[IUnknown]
][
	COM_SAFE_RELEASE(IUnk ctx/pen)
	COM_SAFE_RELEASE(IUnk ctx/brush)
	release-pen-style ctx
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
	loop ctx/clip-cnt [OS-clip-end ctx]
	ctx/clip-cnt: 0

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	if ctx/image <> null [dc/PopAxisAlignedClip this]
	dc/EndDraw this null null
	if hWnd <> null [dc/SetTarget this null]

	release-ctx ctx		;@@ Possible improvement: cache resources for window target

	if on-graphic? [exit]

	rt: as render-target! ctx/target
	either hWnd <> null [		;-- window target
		this: rt/swapchain
		sc: as IDXGISwapChain1 this/vtbl
		hr: sc/Present this 0 0

		switch hr [
			COM_S_OK [0]
			DXGI_ERROR_DEVICE_REMOVED
			DXGI_ERROR_DEVICE_RESET [
				d2d-release-target rt
				ctx/dc: null
				SetWindowLong hWnd wc-offset - 36 0
				DX-create-dev
				InvalidateRect hWnd null 0
			]
			default [
				probe ["draw-end error: " hr]
				0			;@@ TBD log error!!!
			]
		]
	][						;-- image! target
		d2d-release-target rt
		dc/Release this
	]
]

release-pen-style: func [
	ctx			[draw-ctx!]
	/local
		IUnk	[IUnknown]
][
	unless null? ctx/pen-style [
		COM_SAFE_RELEASE(IUnk ctx/pen-style)
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
	ctx/pen-style: as this! style/value
]

OS-draw-pen: func [
	ctx		[draw-ctx!]
	color	[integer!]
	off?	[logic!]
	/local
		this	[this!]
		brush	[ID2D1SolidColorBrush]
		unk		[IUnknown]
		d3d-clr [D3DCOLORVALUE]
		pen		[ptr-value!]
		dc		[ID2D1DeviceContext]
][
	if off? [ctx/pen-type: DRAW_BRUSH_NONE exit]

	unless ctx/font-color? [ctx/font-color: color]	;-- if no font, use pen color for text color
	either ctx/pen-type = DRAW_BRUSH_COLOR [
		ctx/pen-color: color
		this: as this! ctx/pen
		brush: as ID2D1SolidColorBrush this/vtbl
		brush/SetColor this to-dx-color color null
	][
		COM_SAFE_RELEASE(unk ctx/pen)
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		d3d-clr: to-dx-color color null
		dc/CreateSolidColorBrush this d3d-clr null :pen
		ctx/pen: as this! pen/value
		ctx/pen-color: color
		ctx/pen-type: DRAW_BRUSH_COLOR
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
		set-line-spacing ctx/text-format null
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
		vpoint	[POINT_2F value]
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
	gsink/BeginFigure sthis vpoint as-integer ctx/brush-type = DRAW_BRUSH_NONE
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
		m		[D2D_MATRIX_3X2_F value]
		bounds	[RECT_F! value]
		this	[this!]
		dc		[ID2D1DeviceContext]
][
	pthis: as this! ctx/sub/path
	gpath: as ID2D1PathGeometry pthis/vtbl
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl

	gsink/EndFigure sthis as-integer close?

	hr: gsink/Close sthis
	gsink/Release sthis

	draw-geometry ctx pthis

	ctx/sub/path: 0
	ctx/sub/sink: 0
	true
]

OS-draw-shape-close: func [
	ctx			[draw-ctx!]
	/local
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		vpoint	[POINT_2F value]
][
	sthis: as this! ctx/sub/sink
	gsink: as ID2D1GeometrySink sthis/vtbl
	gsink/EndFigure sthis 1
	vpoint/x: ctx/sub/last-pt-x
	vpoint/y: ctx/sub/last-pt-y
	gsink/BeginFigure sthis vpoint as-integer ctx/brush-type = DRAW_BRUSH_NONE
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
		vpoint	[POINT_2F value]
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
	gsink/BeginFigure sthis vpoint as-integer ctx/brush-type = DRAW_BRUSH_NONE
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
		vpoint	[POINT_2F value]
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
		vpoint	[POINT_2F value]
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
	while [ start < end ][
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
		if rel? [
			pf: :p1x
			loop num [
				pf/1: pf/1 + dx			;-- x
				pf/2: pf/2 + dy			;-- y
				pf: pf + 2
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
		start: start + num - 1
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
		point	[POINT_2F value]
		m		[D2D_MATRIX_3X2_F value]
		bounds	[RECT_F! value]
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
	gsink/BeginFigure sthis point as-integer ctx/brush-type = DRAW_BRUSH_NONE
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

	draw-geometry ctx pthis
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
		if ctx/pen-type > DRAW_BRUSH_GRADIENT [
			calc-brush-position
				ctx/pen
				ctx/pen-grad-type
				ctx/pen-offset
				as float32! pt0/x as float32! pt0/y as float32! pt1/x as float32! pt1/y
		]
		if ctx/pen-type <> DRAW_BRUSH_NONE [
			dc/DrawLine 
				this
				as float32! pt0/x as float32! pt0/y
				as float32! pt1/x as float32! pt1/y
				ctx/pen
				ctx/pen-width
				ctx/pen-style
		]
		if ctx/pen-type > DRAW_BRUSH_GRADIENT [
			post-process-brush ctx/pen ctx/pen-offset
		]
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
		unk		[IUnknown]
		d3d-clr [D3DCOLORVALUE]
		pen		[ptr-value!]
		dc		[ID2D1DeviceContext]
][
	if off? [ctx/brush-type: DRAW_BRUSH_NONE exit]
	
	either ctx/brush-type = DRAW_BRUSH_COLOR [
		ctx/brush-color: color
		this: ctx/brush
		brush: as ID2D1SolidColorBrush this/vtbl
		brush/SetColor this to-dx-color color null
	][
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		COM_SAFE_RELEASE(unk ctx/brush)
		d3d-clr: to-dx-color color null
		dc/CreateSolidColorBrush this d3d-clr null :pen
		ctx/brush: as this! pen/value
		ctx/brush-color: color
		ctx/brush-type: DRAW_BRUSH_COLOR
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

draw-shadow: func [
	ctx			[draw-ctx!]
	bmp			[this!]			;-- input bitmap
	x			[integer!]
	y			[integer!]
	w			[integer!]
	h			[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		sbmp	[this!]
		eff-v	[com-ptr! value]
		eff-s	[com-ptr! value]
		eff		[this!]
		eff2	[this!]
		effect	[ID2D1Effect]
		pt		[POINT_2F value]
		target	[render-target!]
		output	[com-ptr! value]
		sigma	[float32!]
		s		[shadow!]
		spread	[integer!]
		unk		[IUnknown]
		err1	[integer!]
		err2	[integer!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	err1: 0 err2: 0
	dc/Flush this :err1 :err2

	target: as render-target! ctx/target
	dc/SetTarget this target/bitmap

	s: ctx/shadows
	until [
		sbmp: bmp
		spread: s/spread
		if spread <> 0 [			;-- scale intput bitmap
			dc/CreateEffect this CLSID_D2D1Scale :eff-s
			eff2: eff-s/value
			effect: as ID2D1Effect eff2/vtbl
			effect/SetInput eff2 0 bmp true
			pt/x: (as float32! spread * 2 + w) / (as float32! w)
			pt/y: (as float32! spread * 2 + h) / (as float32! h)
			effect/base/setValue eff2 0 0 as byte-ptr! :pt size? POINT_2F
			effect/GetOutput eff2 :output
			sbmp: output/value
		]

		dc/CreateEffect this CLSID_D2D1Shadow :eff-v
		eff: eff-v/value
		effect: as ID2D1Effect eff/vtbl
		effect/SetInput eff 0 sbmp true
		if spread <> 0 [
			COM_SAFE_RELEASE(unk sbmp)
			COM_SAFE_RELEASE(unk eff2)
		]

		sigma: as float32! (as float! s/blur) / GAUSSIAN_SCALE_FACTOR
		effect/base/setValue eff 0 0 as byte-ptr! :sigma size? float32!
		effect/base/setValue eff 1 0 as byte-ptr! to-dx-color s/color null size? D3DCOLORVALUE

		effect/GetOutput eff :output
		sbmp: output/value

		pt/x: as float32! x + s/offset-x - spread
		pt/y: as float32! y + s/offset-y - spread
		dc/DrawImage this sbmp pt null 1 0
		COM_SAFE_RELEASE(unk sbmp)
		COM_SAFE_RELEASE(unk eff)
		s: s/next
		null? s
	]
	pt/x: as float32! x
	pt/y: as float32! y
	dc/DrawImage this bmp pt null 1 0
	COM_SAFE_RELEASE(unk bmp)
]

OS-draw-box: func [
	ctx			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		t		[integer!]
		rc		[ROUNDED_RECT_F! value]
		radius	[red-integer!]
		type	[integer!]
		bmp		[this!]
		w		[integer!]
		h		[integer!]
		scale	[float32!]
		up-x	[integer!]
		up-y	[integer!]
		low-x	[integer!]
		low-y	[integer!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	radius: null
	if TYPE_OF(lower) = TYPE_INTEGER [
		radius: as red-integer! lower
		rc/radiusX: as float32! radius/value
		rc/radiusY: rc/radiusX
		lower:  lower - 1
	]

	up-x: upper/x up-y: upper/y low-x: lower/x low-y: lower/y
	if up-x > low-x [t: up-x up-x: low-x low-x: t]
	if up-y > low-y [t: up-y up-y: low-y low-y: t]

	w: low-x - up-x
	h: low-y - up-y
	either ctx/shadow? [
		scale: dpi-value / as float32! 96.0
		rc/left: as float32! 0.5
		rc/top:  as float32! 0.5
		rc/right:  (as float32! w) + (as float32! 0.5)
		rc/bottom: (as float32! h) + (as float32! 0.5)

		bmp: create-d2d-bitmap		;-- create an intermediate bitmap
				this
				as-integer (as float32! w + 1) * scale
				as-integer (as float32! h + 1) * scale
				1
		dc/SetTarget this bmp
	][
		rc/left: as float32! up-x
		rc/top: as float32! up-y
		rc/right: as float32! low-x
		rc/bottom: as float32! low-y
	]

	type: ctx/brush-type
	if type > DRAW_BRUSH_GRADIENT [		;-- fill-pen
		calc-brush-position
			ctx/brush
			ctx/brush-grad-type
			ctx/brush-offset
			rc/left rc/top rc/right rc/bottom
	]
	if type <> DRAW_BRUSH_NONE [
		either null? radius [
			dc/FillRectangle this as RECT_F! :rc ctx/brush
		][
			dc/FillRoundedRectangle this :rc ctx/brush
		]
	]
	if type > DRAW_BRUSH_GRADIENT [post-process-brush ctx/brush ctx/brush-offset]

	type: ctx/pen-type
	if type > DRAW_BRUSH_GRADIENT [
		calc-brush-position
			ctx/pen
			ctx/pen-grad-type
			ctx/pen-offset
			rc/left rc/top rc/right rc/bottom
	]
	if type <> DRAW_BRUSH_NONE [
		either null? radius [
			dc/DrawRectangle this as RECT_F! :rc ctx/pen ctx/pen-width ctx/pen-style
		][
			dc/DrawRoundedRectangle this :rc ctx/pen ctx/pen-width ctx/pen-style
		]
	]
	if type > DRAW_BRUSH_GRADIENT [post-process-brush ctx/pen ctx/pen-offset]

	if ctx/shadow? [draw-shadow ctx bmp upper/x upper/y w h]
]

OS-draw-triangle: func [
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
		point	[POINT_2F value]
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
		point	[POINT_2F value]
		m		[D2D_MATRIX_3X2_F value]
		bounds	[RECT_F! value]
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
	gsink/BeginFigure sthis point as-integer ctx/brush-type = DRAW_BRUSH_NONE

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

	draw-geometry ctx pthis
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
		dx		[float32!]
		dy		[float32!]
		rx		[float32!]
		ry		[float32!]
		ellipse	[D2D1_ELLIPSE value]
		scale	[float32!]
		bmp		[this!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	cx: as float32! x
	cy: as float32! y
	dx: as float32! width
	dy: as float32! height
	rx: dx / as float32! 2.0
	ry: dy / as float32! 2.0
	either ctx/shadow? [
		scale: dpi-value / as float32! 96.0
		ellipse/x: rx + as float32! 0.5
		ellipse/y: ry + as float32! 0.5
		bmp: create-d2d-bitmap		;-- create an intermediate bitmap
				this
				as-integer (as float32! width + 1) * scale
				as-integer (as float32! height + 1) * scale
				1
		dc/SetTarget this bmp
	][
		ellipse/x: cx + rx
		ellipse/y: cy + ry
	]
	ellipse/radiusX: rx
	ellipse/radiusy: ry
	either ctx/brush-type > DRAW_BRUSH_GRADIENT [		;-- fill-pen
		calc-brush-position
			ctx/brush
			ctx/brush-grad-type
			ctx/brush-offset
			cx cy cx + dx cy + dy
		dc/FillEllipse this ellipse ctx/brush
		post-process-brush ctx/brush ctx/brush-offset
	][
		if ctx/brush-type <> DRAW_BRUSH_NONE [
			dc/FillEllipse this ellipse ctx/brush
		]
	]
	either ctx/pen-type > DRAW_BRUSH_GRADIENT [
		calc-brush-position
			ctx/pen
			ctx/pen-grad-type
			ctx/pen-offset
			cx cy cx + dx cy + dy
		dc/DrawEllipse this ellipse ctx/pen ctx/pen-width ctx/pen-style
		post-process-brush ctx/pen ctx/pen-offset
	][
		if ctx/pen-type <> DRAW_BRUSH_NONE [
			dc/DrawEllipse this ellipse ctx/pen ctx/pen-width ctx/pen-style
		]
	]
	if ctx/shadow? [draw-shadow ctx bmp x y width height]
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
		pt-start	[POINT_2F value]
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
		point		[POINT_2F value]
		this		[this!]
		dc			[ID2D1DeviceContext]
		arc			[D2D1_ARC_SEGMENT value]
		alpha		[float!]
		beta		[float!]
		rx			[float!]
		ry			[float!]
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

	;-- adjust angles for ellipses
	if rad-x <> rad-y [
		alpha: as float! angle-begin
		beta: as float! angle-end
		rx: as float! rad-x
		ry: as float! rad-y
		alpha: atan2 (sin alpha) * rx (cos alpha) * ry
		beta:  atan2 (sin beta)  * rx (cos beta) * ry

		if PI < fabs beta - alpha [
			either beta > alpha [
				beta: beta - (PI * 2.0)
			][
				alpha: alpha - (PI * 2.0)
			]
		]
		angle-begin: as float32! alpha
		angle-end: as float32! beta
	]

	pt-start/x: as float32! cos as float! angle-begin
	pt-start/x: cx + (rad-x * pt-start/x)
	pt-start/y: as float32! sin as float! angle-begin
	pt-start/y: cy + (rad-y * pt-start/y)
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

	either closed? [
		point/x: cx point/y: cy
	][
		point/x: pt-start/x point/y: pt-start/y
	]
	gsink/BeginFigure sthis :point as-integer not closed?
	if closed? [gsink/AddLine sthis :pt-start]

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
	if ctx/brush-type <> DRAW_BRUSH_NONE [
		dc/FillGeometry this pthis ctx/brush null
	]
	if ctx/pen-type <> DRAW_BRUSH_NONE [
		dc/DrawGeometry this pthis ctx/pen ctx/pen-width ctx/pen-style
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
		point	[POINT_2F value]
		m		[D2D_MATRIX_3X2_F value]
		bounds	[RECT_F! value]
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
	gsink/BeginFigure sthis point 1
	hr: gsink/AddBezier sthis ps
	gsink/EndFigure sthis 0
	hr: gsink/Close sthis
	gsink/Release sthis

	draw-geometry ctx pthis
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

create-4p-matrix: func [
	size		[SIZE_F!]
	ul			[POINT_2F]
	ur			[POINT_2F]
	ll			[POINT_2F]
	lr			[POINT_2F]
	m			[MATRIX_4x4_F!]
	/local
		s		[MATRIX_4x4_F! value]
		a		[MATRIX_4x4_F! value]
		b		[MATRIX_4x4_F! value]
		c		[MATRIX_4x4_F! value]
		den		[float32!]
		t1		[float32!]
		t2		[float32!]
][
	matrix4x4/identity s
	s/_11: (as float32! 1.0) / size/width
	s/_22: (as float32! 1.0) / size/height

	matrix4x4/identity a
	a/_41: ul/x
	a/_42: ul/y
	a/_11: ur/x - ul/x
	a/_12: ur/y - ul/y
	a/_21: ll/x - ul/x
	a/_22: ll/y - ul/y

	matrix4x4/identity b
	den: a/_11 * a/_22 - (a/_12 * a/_21)
	t1: a/_22 * lr/x - (a/_21 * lr/y) + (a/_21 * a/_42) - (a/_22 * a/_41)
	t1: t1 / den
	t2: a/_11 * lr/y - (a/_12 * lr/x) + (a/_12 * a/_41) - (a/_11 * a/_42)
	t2: t2 / den
	b/_11: t1 / (t1 + t2 - as float32! 1.0)
	b/_22: t2 / (t1 + t2 - as float32! 1.0)
	b/_14: b/_11 - as float32! 1.0
	b/_24: b/_22 - as float32! 1.0

	matrix4x4/identity c
	matrix4x4/mul s b c
	matrix4x4/mul c a m
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
		this	[this!]
		dc		[ID2D1DeviceContext]
		ithis	[this!]
		bmp		[ptr-value!]
		bthis	[this!]
		d2db	[IUnknown]
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
		pt		[red-pair!]
		size	[SIZE_F! value]
		ul		[POINT_2F value]
		ur		[POINT_2F value]
		ll		[POINT_2F value]
		lr		[POINT_2F value]
		m		[MATRIX_4x4_F! value]
		trans	[int-ptr!]
		dst*	[RECT_F! value]
		dst		[RECT_F!]
		src*	[RECT_F! value]
		src		[RECT_F!]
		fval	[float32!]
		crop2	[red-pair!]
		same-img? [logic!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	same-img?: ctx/image = image/node
	if same-img? [dc/EndDraw this null null] ;-- same image as the drawing target, unlock the image
	ithis: OS-image/get-handle image yes
	dc/CreateBitmapFromWicBitmap2 this ithis null :bmp
	if same-img? [dc/BeginDraw this]
	bthis: as this! bmp/value
	d2db: as IUnknown bthis/vtbl
	either null? start [x: 0 y: 0][x: start/x y: start/y]
	width:  IMAGE_WIDTH(image/size)
	height: IMAGE_HEIGHT(image/size)

	either crop1 <> null [
		crop2: crop1 + 1
		src*/left: as float32! crop1/x
		src*/top: as float32! crop1/y
		src*/right: as float32! crop1/x + crop2/x
		src*/bottom: as float32! crop1/y + crop2/y
		src: :src*
		;-- sanitizing
		if src/left > src/right [
			fval: src/left
			src/left: src/right
			src/right: fval
		]
		if src/top > src/bottom [
			fval: src/top
			src/top: src/bottom
			src/bottom: fval
		]
		if any [src/right <= F32_0 src/bottom <= F32_0][exit]
		if src/left <= F32_0 [
			x: x - (as-integer src/left)
			src/left: F32_0
		]
		if src/top <= F32_0 [
			y: y - (as-integer src/top)
			src/top: F32_0
		]
		size/width: as float32! width
		size/height: as float32! height
		if src/right > size/width [src/right: size/width]
		if src/bottom > size/height [src/bottom: size/height]
		size/width: src/right - src/left
		size/height: src/bottom - src/top
		width: as-integer size/width
		height: as-integer size/height
	][
		src: null
		size/width: as float32! width
		size/height: as float32! height
	]

	trans: null
	dst: null
	case [
		start = end [
			dst*/left: as float32! x
			dst*/top: as float32! y
			dst*/right: as float32! x + width
			dst*/bottom: as float32! y + height
			dst: :dst*
		]
		any [					;-- two control points
			start + 1 = end
			all [null? start end <> null]
		][
			dst*/left: as float32! x
			dst*/top: as float32! y
			dst*/right: as float32! end/x
			dst*/bottom: as float32! end/y
			dst: :dst*
		]
		start + 2 = end [
			pt: start
			ul/x: as float32! pt/x
			ul/y: as float32! pt/y
			pt: start + 1
			ur/x: as float32! pt/x
			ur/y: as float32! pt/y
			pt: start + 2
			lr/x: as float32! pt/x
			lr/y: as float32! pt/y
			ll/x: ul/x
			ll/y: lr/y
			create-4p-matrix size ul ur ll lr m
			trans: as int-ptr! :m
		]
		start + 3 = end [
			pt: start
			ul/x: as float32! pt/x
			ul/y: as float32! pt/y
			pt: start + 1
			ur/x: as float32! pt/x
			ur/y: as float32! pt/y
			pt: start + 2
			lr/x: as float32! pt/x
			lr/y: as float32! pt/y
			pt: start + 3
			ll/x: as float32! pt/x
			ll/y: as float32! pt/y
			create-4p-matrix size ul ur ll lr m
			trans: as int-ptr! :m
		]
		true [0]
	]

	;-- D2D1_INTERPOLATION_MODE_DEFINITION_HIGH_QUALITY_CUBIC: 5
	dc/DrawBitmap2 this as int-ptr! bthis dst as float32! 1.0 5 src trans

	d2db/Release bthis
]

_OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	bmp		[this!]
	width	[integer!]
	height	[integer!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
	/local
		x		[integer!]
		y		[integer!]
		xx		[integer!]
		yy		[integer!]
		wrap	[integer!]
		wrap-x	[integer!]
		wrap-y	[integer!]
		props	[D2D1_IMAGE_BRUSH_PROPERTIES value]
		this	[this!]
		dc		[ID2D1DeviceContext]
		brush	[ptr-value!]
		unk		[IUnknown]
][
	either crop-1 = null [
		x: 0
		y: 0
	][
		x: crop-1/x
		y: crop-1/y
	]
	either crop-2 = null [
		xx: width
		yy: height
	][
		xx: crop-2/x
		yy: crop-2/y
		if xx > width [xx: width]
		if yy > height [yy: height]
	]

	wrap-x: D2D1_EXTEND_MODE_WRAP
	wrap-y: D2D1_EXTEND_MODE_WRAP
	unless mode = null [
		wrap: symbol/resolve mode/symbol
		case [
			wrap = flip-x [ wrap-x: D2D1_EXTEND_MODE_MIRROR ]
			wrap = flip-y [ wrap-y: D2D1_EXTEND_MODE_MIRROR ]
			wrap = flip-xy [
				wrap-x: D2D1_EXTEND_MODE_MIRROR
				wrap-y: D2D1_EXTEND_MODE_MIRROR
			]
			wrap = clamp [
				wrap-x: D2D1_EXTEND_MODE_CLAMP
				wrap-y: D2D1_EXTEND_MODE_CLAMP
			]
			true [0]
		]
	]

	props/left: as float32! x
	props/top: as float32! y
	props/right: as float32! xx
	props/bottom: as float32! yy
	props/extendModeX: wrap-x
	props/extendModeY: wrap-y
	props/interpolationMode: 1		;-- MODE_LINEAR

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/CreateImageBrush this bmp :props null :brush
	either brush? [
		COM_SAFE_RELEASE(unk ctx/brush)
		ctx/brush: as this! brush/value
		ctx/brush-type: DRAW_BRUSH_IMAGE_SMART
		ctx/brush-grad-type: 0
	][
		COM_SAFE_RELEASE(unk ctx/pen)
		ctx/pen: as this! brush/value
		ctx/pen-type: DRAW_BRUSH_IMAGE_SMART
		ctx/pen-grad-type: 0
	]
]

OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	img		[red-image!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
	/local
		width	[integer!]
		height	[integer!]
		dc		[ID2D1DeviceContext]
		this	[this!]
		ithis	[this!]
		bmp		[ptr-value!]
		unk		[IUnknown]
][
	width:  OS-image/width? img/node
	height: OS-image/height? img/node
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	ithis: OS-image/get-handle img yes
	dc/CreateBitmapFromWicBitmap2 this ithis null :bmp
	_OS-draw-brush-bitmap ctx as this! bmp/value width height crop-1 crop-2 mode brush?
	ithis: as this! bmp/value
	COM_SAFE_RELEASE(unk ithis)
]

OS-draw-brush-pattern: func [
	ctx		[draw-ctx!]
	size	[red-pair!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	block	[red-block!]
	brush?	[logic!]
	/local
		dc		[ID2D1DeviceContext]
		this	[this!]
		list	[com-ptr! value]
		cthis	[this!]
		cmd		[ID2D1CommandList]
		old-bmp	[com-ptr! value]
		clip-n	[integer!]
		n		[integer!]
		state	[draw-state! value]
		unk		[IUnknown]
		m		[D2D_MATRIX_3X2_F value]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	;dc/EndDraw this null null
	dc/CreateCommandList this :list
	cthis: list/value

	dc/GetTarget this :old-bmp		;-- refcnt increament
	clip-n: ctx/clip-cnt

	dc/SetTarget this cthis
	;dc/BeginDraw this
	OS-draw-state-push ctx :state
	matrix2d/identity m
	dc/SetTransform this :m			;-- set to identity matrix
	parse-draw ctx block no
	n: ctx/clip-cnt - clip-n
	loop n [OS-clip-end ctx]
	OS-draw-state-pop ctx :state
	;dc/EndDraw this null null

	cmd: as ID2D1CommandList cthis/vtbl
	cmd/Close cthis

	ctx/clip-cnt: clip-n
	dc/SetTarget this old-bmp/value	
	;dc/BeginDraw this

	_OS-draw-brush-bitmap ctx cthis size/x size/y crop-1 crop-2 mode brush?
	cmd/Release cthis
	this: old-bmp/value
	unk: as IUnknown this/vtbl
	unk/Release this			;-- refcnt decrement
]

OS-draw-grad-pen-old: func [
	ctx			[draw-ctx!]
	type		[integer!]
	spread		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
	/local
		x		[integer!]
		y		[integer!]
		int		[red-integer!]
		start	[integer!]
		stop	[integer!]
		n		[integer!]
		rotate? [logic!]
		scale?	[logic!]
		sx		[float32!]
		sy		[float32!]
		p		[float!]
		f		[red-float!]
		angle	[float32!]
		delta	[float!]
		gstops	[D2D1_GRADIENT_STOP]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		wrap	[integer!]
		dc		[ID2D1DeviceContext]
		this	[this!]
		sc		[com-ptr! value]
		brush	[com-ptr! value]
		bthis	[this!]
		ibrush	[ID2D1Brush]
		gprops	[D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES value]
		lprops	[D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES value]
		unk		[IUnknown]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
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

	gstops: grad-stops
	n: count - 1
	delta: as float! n
	delta: 1.0 / delta
	p: 0.0
	head: as red-value! int
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		next: head + 1
		to-dx-color clr/array1 as D3DCOLORVALUE (as int-ptr! gstops) + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		gstops/position: as float32! p
		if next <> head [p: p + delta]
		head: head + 1
		gstops: gstops + 1
	]

	case [
		spread = _pad		[wrap: 0]
		spread = _repeat	[wrap: 1]
		spread = _reflect	[wrap: 2]
		true [wrap: 0]
	]

	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/CreateGradientStopCollection this grad-stops count 0 wrap :sc
	either type = linear [
		lprops/startPoint.x: as float32! x + start
		lprops/startPoint.y: as float32! y
		lprops/endPoint.x: as float32! x + stop
		lprops/endPoint.y: as float32! y
		dc/CreateLinearGradientBrush this :lprops null sc/value :brush
	][
		gprops/center.x: as float32! x
		gprops/center.y: as float32! y
		gprops/radius.x: as float32! stop - start
		gprops/radius.y: gprops/radius.x
		gprops/offset.x: as float32! 0.0
		gprops/offset.y: as float32! 0.0
		dc/CreateRadialGradientBrush this :gprops null sc/value :brush
	]

	bthis: brush/value
	ibrush: as ID2D1Brush bthis/vtbl
	ibrush/GetTransform bthis :m
	matrix2d/identity :m
	if rotate? [
		matrix2d/rotate :m angle F32_0 F32_0 :t ctx/pre-order?
		copy-memory as byte-ptr! :m as byte-ptr! :t size? D2D_MATRIX_3X2_F
	]
	if scale? [
		matrix2d/scale :m sx sy F32_0 F32_0 :t ctx/pre-order?
		copy-memory as byte-ptr! :m as byte-ptr! :t size? D2D_MATRIX_3X2_F
	]
	ibrush/SetTransform bthis :m

	COM_SAFE_RELEASE(unk sc/value)

	either brush? [
		COM_SAFE_RELEASE(unk ctx/brush)
		ctx/brush: bthis
		ctx/brush-type: DRAW_BRUSH_GRADIENT
		ctx/brush-grad-type: type
	][
		COM_SAFE_RELEASE(unk ctx/pen)
		ctx/pen: bthis
		ctx/pen-type: DRAW_BRUSH_GRADIENT
		ctx/pen-grad-type: type
	]
]

OS-draw-grad-pen: func [
	ctx			[draw-ctx!]
	type		[integer!]
	stops		[red-value!]
	count		[integer!]
	skip-pos?	[logic!]
	positions	[red-value!]
	focal?		[logic!]
	spread		[integer!]
	brush?		[logic!]
	/local
		dc		[ID2D1DeviceContext]
		this	[this!]
		unk		[IUnknown]
		gprops	[D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES value]
		lprops	[D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES value]
		gstops	[D2D1_GRADIENT_STOP]
		x		[float!]
		y		[float!]
		start	[float!]
		stop	[float!]
		brush	[com-ptr! value]
		int		[red-integer!]
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		n		[integer!]
		delta	[float!]
		p		[float!]
		wrap	[integer!]
		sc		[com-ptr! value]
		pt		[red-pair!]
		gtype	[integer!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	gstops: grad-stops
	n: count - 1
	delta: as float! n
	delta: 1.0 / delta
	p: 0.0
	head: stops
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		next: head + 1
		to-dx-color clr/array1 as D3DCOLORVALUE (as int-ptr! gstops) + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		gstops/position: as float32! p
		if next <> head [p: p + delta]
		head: head + 1
		gstops: gstops + 1
	]

	case [
		spread = _pad		[wrap: 0]
		spread = _repeat	[wrap: 1]
		spread = _reflect	[wrap: 2]
		true [wrap: 0]
	]

	dc/CreateGradientStopCollection this grad-stops count 0 wrap :sc
	either type = linear [
		either skip-pos? [
			gtype: DRAW_BRUSH_GRADIENT_SMART
			lprops/startPoint.x: F32_0
			lprops/startPoint.y: F32_0
			lprops/endPoint.x: as float32! 1.0
			lprops/endPoint.y: F32_0
		][
			gtype: DRAW_BRUSH_GRADIENT
			pt: as red-pair! positions
			lprops/startPoint.x: as float32! pt/x
			lprops/startPoint.y: as float32! pt/y
			pt: pt + 1
			lprops/endPoint.x: as float32! pt/x
			lprops/endPoint.y: as float32! pt/y
		]
		dc/CreateLinearGradientBrush this lprops null sc/value :brush
	][
		either skip-pos? [
			gtype: DRAW_BRUSH_GRADIENT_SMART
			gprops/center.x: as float32! 1.0
			gprops/center.y: as float32! 1.0
			gprops/radius.x: as float32! 1.0
			gprops/radius.y: as float32! 1.0
			gprops/offset.x: as float32! 0.0
			gprops/offset.y: as float32! 0.0
		][
			gtype: DRAW_BRUSH_GRADIENT
			pt: as red-pair! positions
			gprops/center.x: as float32! pt/x
			gprops/center.y: as float32! pt/y
			gprops/radius.x: get-float32 as red-integer! pt + 1
			gprops/radius.y: gprops/radius.x
			either focal? [
				pt: pt + 2
				gprops/offset.x: as float32! pt/x
				gprops/offset.y: as float32! pt/y
			][
				gprops/offset.x: as float32! 0.0
				gprops/offset.y: as float32! 0.0
			]
		]
		dc/CreateRadialGradientBrush this gprops null sc/value :brush
	]

	COM_SAFE_RELEASE(unk sc/value)

	either brush? [
		COM_SAFE_RELEASE(unk ctx/brush)
		ctx/brush: brush/value
		ctx/brush-type: gtype
		ctx/brush-grad-type: type
	][
		COM_SAFE_RELEASE(unk ctx/pen)
		ctx/pen: brush/value
		ctx/pen-type: gtype
		ctx/pen-grad-type: type
	]
]

OS-set-clip: func [
	ctx		[draw-ctx!]
	u		[red-pair!]
	l		[red-pair!]
	rect?	[logic!]
	mode	[integer!]
	/local
		dc		[ID2D1DeviceContext]
		this	[this!]
		layer	[ptr-value!]
		lthis	[this!]
		hr		[integer!]
		pthis	[this!]
		gpath	[ID2D1PathGeometry]
		sthis	[this!]
		gsink	[ID2D1GeometrySink]
		para	[D2D1_LAYER_PARAMETERS1 value]
		inf4	[integer!]
		inf3	[integer!]
		inf2	[integer!]
		inf1	[integer!]
][
	ctx/clip-cnt: ctx/clip-cnt + 1
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl

	para/mode: 0
	matrix2d/identity para/trans
	para/opacity: as float32! 1.0
	para/brush: null
	para/opts: 1	;-- D2D1_LAYER_OPTIONS_INITIALIZE_FOR_CLEARTYPE
	para/mask: null
	either rect? [
		para/bounds/left: as float32! u/x
		para/bounds/top: as float32! u/y
		para/bounds/right: as float32! l/x
		para/bounds/bottom: as float32! l/y
	][
		inf1: FF800000h
		inf2: FF800000h
		inf3: 7F800000h
		inf4: 7F800000h
		copy-memory as byte-ptr! para/bounds as byte-ptr! :inf1 16

		;-- TDB: as the shape path are auto closed, so need a way to reserve path
		if ctx/sub/path <> 0 [
			pthis: as this! ctx/sub/path
			gpath: as ID2D1PathGeometry pthis/vtbl
			sthis: as this! ctx/sub/sink
			gsink: as ID2D1GeometrySink sthis/vtbl
			gsink/EndFigure sthis 1
			hr: gsink/Close sthis
			gsink/Release sthis

			para/mask: as int-ptr! pthis
		]
	]

	dc/PushLayer2 this :para null
]

OS-clip-end: func [
	ctx			[draw-ctx!]
	/local
		dc		[ID2D1DeviceContext]
		this	[this!]
][
	ctx/clip-cnt: ctx/clip-cnt - 1
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/PopLayer this
]

#define BEGIN_MATRIX_BRUSH [
	either pen-fill = pen [
		if ctx/pen-type <= DRAW_BRUSH_COLOR [exit]
		bthis: ctx/pen
	][
		if ctx/brush-type <= DRAW_BRUSH_COLOR [exit]
		bthis: ctx/brush
	]
	brush: as ID2D1Brush bthis/vtbl
]

OS-matrix-rotate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	angle		[red-integer!]
	center		[red-pair!]
	/local
		rad		[float32!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
		bthis	[this!]
		brush	[ID2D1Brush]
		cx		[float32!]
		cy		[float32!]
][
	rad: get-float32 angle
	either TYPE_OF(center) = TYPE_PAIR [
		cx: as float32! center/x
		cy: as float32! center/y
	][
		cx: as float32! 0.0 cy: as float32! 0.0
	]
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/rotate :m rad cx cy :t ctx/pre-order?
		dc/SetTransform this :t
	][
		BEGIN_MATRIX_BRUSH
		brush/GetTransform bthis :m
		matrix2d/rotate :m rad cx cy :t ctx/pre-order?
		brush/SetTransform bthis :t
	]
]

OS-matrix-scale: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	center		[red-pair!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
		bthis	[this!]
		brush	[ID2D1Brush]
		sy		[red-integer!]
		cx		[float32!]
		cy		[float32!]
][
	sy: sx + 1
	either TYPE_OF(center) = TYPE_PAIR [
		cx: as float32! center/x
		cy: as float32! center/y
	][
		cx: F32_0 cy: F32_0
	]
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/scale :m get-float32 sx get-float32 sy cx cy :t ctx/pre-order?
		dc/SetTransform this :t
	][
		BEGIN_MATRIX_BRUSH
		brush/GetTransform bthis :m
		matrix2d/scale :m get-float32 sx get-float32 sy cx cy :t ctx/pre-order?
		brush/SetTransform bthis :t
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
		bthis	[this!]
		brush	[ID2D1Brush]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/translate :m as float32! x as float32! y :t ctx/pre-order?
		dc/SetTransform this :t
	][
		BEGIN_MATRIX_BRUSH
		brush/GetTransform bthis :m
		matrix2d/translate :m as float32! x as float32! y :t ctx/pre-order?
		brush/SetTransform bthis :t
	]
]

OS-matrix-skew: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	center		[red-pair!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		t		[D2D_MATRIX_3X2_F value]
		x		[float32!]
		y		[float32!]
		cx		[float32!]
		cy		[float32!]
		bthis	[this!]
		brush	[ID2D1Brush]
		sy		[red-integer!]
][
	sy: sx + 1
	x: get-float32 sx
	y: get-float32 sy
	either TYPE_OF(center) = TYPE_PAIR [
		cx: as float32! center/x
		cy: as float32! center/y
	][
		cx: F32_0 cy: F32_0
	]
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/skew :m x y cx cy :t ctx/pre-order?
		dc/SetTransform this :t
	][
		BEGIN_MATRIX_BRUSH
		brush/GetTransform bthis :m
		matrix2d/skew :m x y cx cy :t ctx/pre-order?
		brush/SetTransform bthis :t
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
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	OS-matrix-rotate ctx pen-fill rotate center
	OS-matrix-scale ctx pen-fill scale center
	OS-matrix-translate ctx pen-fill translate/x translate/y
]

OS-draw-state-push: func [
	ctx			[draw-ctx!]
	draw-state	[draw-state!]
	/local
		factory	[ID2D1Factory]
		blk		[ptr-value!]
		this	[this!]
		dc		[ID2D1DeviceContext]
		unk		[IUnknown]
][
	factory: as ID2D1Factory d2d-factory/vtbl
	if 0 <> factory/CreateDrawingStateBlock d2d-factory null null :blk [
		;TBD error!!!
		probe "OS-draw-state-push failed"
		exit
	]
	copy-memory as byte-ptr! draw-state as byte-ptr! :ctx/state size? draw-state!
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	dc/SaveDrawingState this as this! blk/value
	draw-state/state: as this! blk/value
	COM_ADD_REF(unk draw-state/pen)
	COM_ADD_REF(unk draw-state/brush)
]

OS-draw-state-pop: func [
	ctx			[draw-ctx!]
	draw-state	[draw-state!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		IUnk	[IUnknown]
		n		[integer!]
][
	this: as this! ctx/dc
	dc: as ID2D1DeviceContext this/vtbl
	n: ctx/clip-cnt - draw-state/clip-cnt
	loop n [OS-clip-end ctx]
	dc/RestoreDrawingState this draw-state/state
	COM_SAFE_RELEASE(IUnk draw-state/state)
	COM_SAFE_RELEASE(IUnk ctx/pen)
	COM_SAFE_RELEASE(IUnk ctx/brush)
	copy-memory as byte-ptr! :ctx/state as byte-ptr! draw-state size? draw-state!
	ctx/state: null
	if ctx/pen-type = DRAW_BRUSH_COLOR [OS-draw-pen ctx ctx/pen-color no]
	if ctx/brush-type = DRAW_BRUSH_COLOR [OS-draw-fill-pen ctx ctx/brush-color no yes]
	update-pen-style ctx
]

OS-matrix-reset: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	/local
		this	[this!]
		dc		[ID2D1DeviceContext]
		m		[D2D_MATRIX_3X2_F value]
		bthis	[this!]
		brush	[ID2D1Brush]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		;dc/GetTransform this :m
		matrix2d/identity :m
		dc/SetTransform this :m
	][
		BEGIN_MATRIX_BRUSH
		matrix2d/identity :m
		brush/SetTransform bthis :m
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
		bthis	[this!]
		brush	[ID2D1Brush]
][
	either pen-fill = -1 [
		this: as this! ctx/dc
		dc: as ID2D1DeviceContext this/vtbl
		dc/GetTransform this :m
		matrix2d/invert :m :t
		dc/SetTransform this :t
	][
		BEGIN_MATRIX_BRUSH
		brush/GetTransform bthis :m
		matrix2d/invert :m :t
		brush/SetTransform bthis :t
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
		bthis	[this!]
		brush	[ID2D1Brush]
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
		matrix2d/mul m0 m t ctx/pre-order?
		dc/SetTransform this :t
	][
		BEGIN_MATRIX_BRUSH
		brush/GetTransform bthis :m0
		matrix2d/mul m0 m t ctx/pre-order?
		brush/SetTransform bthis :t
	]
]

OS-set-matrix-order: func [
	ctx		[draw-ctx!]
	order	[integer!]
][
	case [
		order = _append [ ctx/pre-order?: no ]
		order = prepend [ ctx/pre-order?: yes ]
		true [ ctx/pre-order?: yes ]
	]
]

OS-draw-shadow: func [
	ctx		[draw-ctx!]
	offset	[red-pair!]
	blur	[integer!]
	spread	[integer!]
	color	[integer!]
	inset?	[logic!]
	/local
		s		[shadow!]
		ss		[shadow!]
		chain?	[logic!]
][
	chain?: ctx/shadow?
	ctx/shadow?: TYPE_OF(offset) = TYPE_PAIR
	either ctx/shadow? [
		either chain? [
			s: as shadow! allocate size? shadow!
			s/next: null
			ss: ctx/shadows/next
			either null? ss [ctx/shadows/next: s][
				ss/next: s
			]
		][
			s: ctx/shadows
			s/next: null
		]
		s/offset-x: offset/x
		s/offset-y: offset/y
		s/blur: blur
		s/spread: spread
		s/color: color
		s/inset?: inset?
	][
		ss: ctx/shadows/next
		while [ss <> null][
			s: ss
			ss: ss/next
			free as byte-ptr! s
		]
		ctx/shadows/next: null
	]
]