Red/System [
	Title:	"DRAW Direct2D Backend"
	Author: "Xie Qingtian"
	File: 	%draw-d2d.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

draw-begin-d2d: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		_11		[integer!]
		_12		[integer!]
		_21		[integer!]
		_22		[integer!]
		_31		[integer!]
		_32		[integer!]
		color	[D3DCOLORVALUE]
		m		[D2D_MATRIX_3X2_F]
		bg-clr	[integer!]
		brush	[integer!]
][
	this: as this! GetWindowLong hWnd wc-offset - 24
	if null? this [
		this: create-hwnd-render-target hWnd
		SetWindowLong hWnd wc-offset - 24 as-integer this
	]
	ctx/dc: as handle! this

	rt: as ID2D1HwndRenderTarget this/vtbl
	rt/BeginDraw this
	_11: 0 _12: 0 _21: 0 _22: 0 _31: 0 _32: 0
	m: as D2D_MATRIX_3X2_F :_32
	m/_11: as float32! 1.0
	m/_22: as float32! 1.0
	rt/SetTransform this m				;-- set to identity matrix

	bg-clr: to-bgr as node! GetWindowLong hWnd wc-offset + 4 FACE_OBJ_COLOR
	if bg-clr <> -1 [					;-- paint background
		rt/Clear this to-dx-color bg-clr null
	]

	brush: 0
	rt/CreateSolidColorBrush this to-dx-color ctx/pen-color null null :brush
	ctx/pen: brush
]

clean-draw-d2d: func [
	ctx		[draw-ctx!]
	/local
		IUnk [IUnknown]
		this [this!]
][
	COM_SAFE_RELEASE_OBJ(IUnk ctx/pen)
]

draw-end-d2d: func [
	ctx		[draw-ctx!]
	hWnd	[handle!]
	/local
		this [this!]
		rt	 [ID2D1HwndRenderTarget]
		hr [integer!]
][
	this: as this! ctx/dc
	rt: as ID2D1HwndRenderTarget this/vtbl
	hr: rt/EndDraw this null null

	clean-draw-d2d ctx

	switch hr [
		COM_S_OK [ValidateRect hWnd null]
		D2DERR_RECREATE_TARGET [
			rt/Release this
			ctx/dc: null
			SetWindowLong hWnd wc-offset - 24 0
		]
		default [
			0		;@@ TBD log error!!!
		]
	]
]

OS-draw-circle-d2d: func [
	ctx	   [draw-ctx!]
	center [red-pair!]
	radius [red-integer!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		ellipse [D2D1_ELLIPSE]
][
	this: as this! ctx/dc
	rt: as ID2D1HwndRenderTarget this/vtbl

	ellipse: declare D2D1_ELLIPSE
	ellipse/x: as float32! center/x
	ellipse/y: as float32! center/y
	ellipse/radiusX: get-float32 radius
	ellipse/radiusY: ellipse/radiusX
	if ctx/brush? [
		rt/FillEllipse this ellipse ctx/brush
	]
	if ctx/pen? [
		rt/DrawEllipse this ellipse ctx/pen ctx/pen-width ctx/pen-style
	]
]