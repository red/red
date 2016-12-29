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

d2d-brushes: as int-ptr! 0							;-- brushes cache for Direct2D
d2d-brush-cnt: 0

#define D2D_MAX_BRUSHES 64

#include %text-box.reds

select-brush: func [
	color	[integer!]
	return: [integer!]
	/local
		brushes [int-ptr!]
][
	brushes: d2d-brushes
	loop d2d-brush-cnt [
		either brushes/value = color [
			return brushes/2
		][
			brushes: brushes + 2
		]
	]
	0
]

put-brush: func [
	color	[integer!]
	brush	[integer!]
	/local
		brushes [int-ptr!]
][
	brushes: d2d-brushes + (d2d-brush-cnt * 2)
	brushes/1: color
	brushes/2: brush
	d2d-brush-cnt: d2d-brush-cnt + 1
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
	rt/SetTextAntialiasMode this 1				;-- ClearType

	rt/BeginDraw this
	_11: 0 _12: 0 _21: 0 _22: 0 _31: 0 _32: 0
	m: as D2D_MATRIX_3X2_F :_32
	m/_11: as float32! 1.0
	m/_22: as float32! 1.0
	rt/SetTransform this m						;-- set to identity matrix

	bg-clr: to-bgr as node! GetWindowLong hWnd wc-offset + 4 FACE_OBJ_COLOR
	if bg-clr <> -1 [							;-- paint background
		rt/Clear this to-dx-color bg-clr null
	]

	brush: 0
	either null? d2d-brushes [
		d2d-brushes: as int-ptr! allocate D2D_MAX_BRUSHES * 2 * size? int-ptr!
		rt/CreateSolidColorBrush this to-dx-color ctx/pen-color null null :brush
		put-brush ctx/pen-color brush
	][
		brush: select-brush ctx/pen-color
	]
	ctx/pen: brush
]

clean-draw-d2d: func [
	ctx		[draw-ctx!]
	/local
		IUnk [IUnknown]
		this [this!]
][
	;;TBD release all brushes when D2DERR_RECREATE_TARGET or exit the process
]

draw-end-d2d: func [
	ctx		[draw-ctx!]
	hWnd	[handle!]
	/local
		this [this!]
		rt	 [ID2D1HwndRenderTarget]
		hr	 [integer!]
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

OS-draw-pen-d2d: func [
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

OS-draw-text-d2d: func [
	ctx		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	/local
		this	[this!]
		rt		[ID2D1HwndRenderTarget]
		IUnk	[IUnknown]
		values	[red-value!]
		str		[red-string!]
		size	[red-pair!]
		int		[red-integer!]
		state	[red-block!]
		styles	[red-block!]
		w		[integer!]
		h		[integer!]
		fmt		[this!]
		layout	[this!]
][
	this: as this! ctx/dc
	rt: as ID2D1HwndRenderTarget this/vtbl

	either TYPE_OF(text) = TYPE_OBJECT [				;-- text-box!
		values: object/get-values as red-object! text
		state: as red-block! values + TBOX_OBJ_STATE

		layout: either TYPE_OF(state) = TYPE_BLOCK [
			int: as red-integer! block/rs-head state
			as this! int/value
		][
			OS-text-box-layout as red-object! text this yes
		]
	][
		0
	]

	rt/DrawTextLayout this as float32! pos/x as float32! pos/y layout ctx/pen 0
]