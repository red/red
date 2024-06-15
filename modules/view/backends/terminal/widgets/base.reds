Red/System [
	Title:	"Base widget"
	Author: "Xie Qingtian"
	File: 	%base.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

update-caret: func [
	widget		[widget!]
	x			[integer!]
	y			[integer!]
	/local
		values	[red-value!]
		opts	[red-block!]
		word	[red-word!]
		face	[red-object!]
		w		[widget!]
		len		[integer!]
		sym		[integer!]
][
	values: get-face-values widget
	opts: as red-block! values + FACE_OBJ_OPTIONS
	if TYPE_OF(opts) = TYPE_BLOCK [
		word: as red-word! block/rs-head opts
		len: block/rs-length? opts
		if len % 2 <> 0 [exit]
		while [len > 0][
			sym: symbol/resolve word/symbol
			case [
				sym = caret [
					WIDGET_SET_FLAG(widget WIDGET_FLAG_CARET)
					face: as red-object! word + 1
					w: as widget! face-handle? face
					if w <> null [
						WIDGET_SET_FLAG(w WIDGET_FLAG_EDITABLE)
						if WIDGET_FOCUSED?(w) [
							screen/cursor-x: x
							screen/cursor-y: y
						]
					]
				]
				true [0]
			]
			word: word + 2
			len: len - 2
		]
	]
]

init-base: func [
	widget		[widget!]
][
	update-caret widget 0 0
	screen/update-editable-widget widget
	widget/render: as render-func! :draw-base
]

draw-base: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
][
	if WIDGET_CARET?(widget) [
		update-caret widget x y
		exit
	]
	_widget/render x y widget PIXEL_ANSI_SEQ
]