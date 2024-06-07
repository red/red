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
		p		[pixel!]
		values	[red-value!]
		str		[red-string!]
		config	[render-config! value]
][
	_widget/render x y widget 0		;-- draw background

	;-- draw frame
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
			case [
				all [x = up-x  y = up-y ][p/code-point: 256Dh]  ;-- #"╭"
				all [x = max-x y = up-y ][p/code-point: 256Eh]  ;-- #"╮"
				all [x = up-x  y = max-y][p/code-point: 2570h]  ;-- #"╰"
				all [x = max-x y = max-y][p/code-point: 256Fh]  ;-- #"╯"
				any [x = up-x  x = max-x][p/code-point: 2502h]  ;-- #"│"
				any [y = up-y  y = max-y][p/code-point: 2500h]  ;-- #"─"
				true [0]
			]
			p: p + 1
			x: x + 1
		]
		y: y + 1
	]

	;-- draw title
	values: get-face-values widget
	str:    as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(str) = TYPE_STRING [
		zero-memory as byte-ptr! :config size? render-config!
		_widget/render-text str up-x + 1 up-y :box :config
	]
]