Red/System [
	Title:	"Group Box Widget"
	Author: "Xie Qingtian"
	File: 	%group-box.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-group-box: func [
	widget		[widget!]
][
	widget/render: as render-func! :draw-group-box
]

draw-group-box: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
	/local
		box		[rect! value]
		w h		[integer!]
		up-x	[integer!]
		up-y	[integer!]
		xx yy	[integer!]
		min-x	[integer!]
		min-y	[integer!]
		max-x	[integer!]
		max-y	[integer!]
		sym		[integer!]
		clr	fg	[integer!]
		p		[pixel!]
		values	[red-value!]
		str		[red-string!]
		font	[red-object!]
		opts	[red-block!]
		color	[red-tuple!]
		corners	[red-word!]
		round?	[logic!]
		color?	[logic!]
		config	[render-config! value]
][
	_widget/render x y widget PIXEL_IGNORE_TEXT		;-- draw background

	;-- draw frame
	color?: no
	round?: no
	values: get-face-values widget
	opts: as red-block! values + FACE_OBJ_OPTIONS

	if TYPE_OF(opts) = TYPE_BLOCK [
		corners: as red-word! block/select-word opts word/load "border-corners" no
		if TYPE_OF(corners) = TYPE_WORD [
			sym: symbol/resolve corners/symbol
			round?: sym = _round
		]
		color: as red-tuple! block/select-word opts word/load "border-color" no
		switch TYPE_OF(color) [
			TYPE_TUPLE [
				color?: yes
				clr: get-tuple-color color
				clr: make-color-256 clr
			]
			TYPE_WORD [
				color?: no
			]
			default [0]
		]
	]

	w: 0
	h: 0
	_widget/get-size widget :w :h
	max-x: x + w - 1
	max-y: y + h - 1

	_widget/get-clip-box x y widget :box
	min-x: either box/left > x [box/left][x]
	min-y: either box/top > y [box/top][y]
	up-x: x
	up-y: y
	xx: box/right
	yy: box/bottom

	y: min-y
	while [all [y <= max-y y < yy]][
		x: min-x
		p: screen/buffer + (screen/width * y + x)
		while [all [x <= max-x x < xx]][
			fg: clr
			case [
				all [x = up-x  y = up-y ][p/code-point: either round? [256Dh][250Ch]]  ;-- #"╭" or #"┌"
				all [x = max-x y = up-y ][p/code-point: either round? [256Eh][2510h]]  ;-- #"╮" or #"┐"
				all [x = up-x  y = max-y][p/code-point: either round? [2570h][2514h]]  ;-- #"╰" or #"└"
				all [x = max-x y = max-y][p/code-point: either round? [256Fh][2518h]]  ;-- #"╯" or #"┘"
				any [x = up-x  x = max-x][p/code-point: 2502h]  ;-- #"│"
				any [y = up-y  y = max-y][p/code-point: 2500h]  ;-- #"─"
				true [fg: p/fg-color]
			]
			if color? [p/fg-color: fg]
			p: p + 1
			x: x + 1
		]
		y: y + 1
	]

	;-- draw title
	str:  as red-string! values + FACE_OBJ_TEXT
	font: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(str) = TYPE_STRING [
		zero-memory as byte-ptr! :config size? render-config!
		if TYPE_OF(font) = TYPE_OBJECT [	;-- set color for both title and border
			clr: get-font-color font
			config/fg-color: make-color-256 clr
		]
		config/flags: PIXEL_ANSI_SEQ
		_widget/render-text str up-x + 1 up-y :box :config
	]
]