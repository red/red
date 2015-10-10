Red/System [
	Title:	"Windows Image widget"
	Author: "Xie Qingtian"
	File: 	%image.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

ImageWndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		hBackDC [handle!]
		ftn		[integer!]
		bf		[tagBLENDFUNCTION]
][
	switch msg [
		WM_ERASEBKGND [
			hBackDC: as handle! GetWindowLong hWnd wc-offset - 4
			rect: declare RECT_STRUCT
			GetClientRect hWnd rect
			width: rect/right - rect/left
			height: rect/bottom - rect/top
			ftn: 0
			bf: as tagBLENDFUNCTION :ftn
			bf/BlendOp: as-byte 0
			bf/BlendFlags: as-byte 0
			bf/SourceConstantAlpha: as-byte 255
			bf/AlphaFormat: as-byte 1
			AlphaBlend as handle! wParam 0 0 width height hBackDC 0 0 width height ftn
			return 1
		]
		default [0]
	]
	DefWindowProc hWnd msg wParam lParam
]

make-image-dc: func [
	hWnd		[handle!]
	img			[red-image!]
	return:		[integer!]
	/local
		graphic [integer!]
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		hDC		[handle!]
		hBitmap [handle!]
		hBackDC [handle!]
][
	graphic: 0
	rect: declare RECT_STRUCT

	GetClientRect hWnd rect
	width: rect/right - rect/left
	height: rect/bottom - rect/top

	hDC: GetDC hWnd
	hBackDC: CreateCompatibleDC hDC
	hBitmap: CreateCompatibleBitmap hDC width height
	SelectObject hBackDC hBitmap
	GdipCreateFromHDC hBackDC :graphic
	GdipDrawImageRectI graphic as-integer img/node 0 0 width height
	ReleaseDC hWnd hDC

	as-integer hBackDC
]

init-image: func [
	hWnd	[handle!]
	data	[red-block!]
	img		[red-image!]
	/local
		str  [red-string!]
		tail [red-string!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		while [str < tail][
			switch TYPE_OF(str) [
				TYPE_URL   [
					copy-cell
						as cell! image/load-binary as red-binary!
							simple-io/request-http HTTP_GET as red-url! str null null yes no no
						as cell! img
				]
				TYPE_FILE  [image/make-at as red-value! img str]
				TYPE_IMAGE [copy-cell as cell! str as cell! img]
				default [0]
			]
			str: str + 1
		]
	]
	SetWindowLong hWnd wc-offset - 4 make-image-dc hWnd img
]