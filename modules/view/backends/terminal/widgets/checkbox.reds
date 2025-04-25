Red/System [
	Title:	"Check Box widget"
	Author: "Xie Qingtian"
	File: 	%checkbox.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

make-checkbox-ui: func [
	widget		[widget!]
	/local
		face	[red-object!]
		ui		[red-string!]
][
	face: get-face-obj widget
	#call [TUI-helpers/make-checkbox-ui face]
	ui: as red-string! stack/arguments
	widget/ui: ui/node
]

on-checkbox-event: func [
	type		[event-type!]
	evt			[widget-event!]
	return:		[integer!]
	/local
		widget	[widget!]
		cp		[integer!]
		data	[red-logic!]
		values	[red-value!]
		change? [logic!]
][
	widget: evt/widget
	change?: no
	case [
		type = EVT_KEY [
			cp: evt/data
			if cp = 32 [change?: yes]	;-- space key
		]
		type = EVT_FOCUS [
			screen/redraw widget
		]
		type = EVT_CLICK [change?: yes]
		true [0]
	]

	if change? [
		values: get-face-values widget
		data: as red-logic! values + FACE_OBJ_DATA

		switch TYPE_OF(data) [
			TYPE_NONE  [data/header: TYPE_LOGIC data/value: true]
			TYPE_LOGIC [data/value: not data/value]
			default	   [data/header: TYPE_LOGIC data/value: false]
		]
		make-checkbox-ui widget
		screen/redraw widget
		make-red-event EVT_CHANGE widget 0
	]
	0
]

draw-checkbox: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
	/local
		flags	[integer!]
][
	flags: PIXEL_ANSI_SEQ or PIXEL_IGNORE_TEXT
	if WIDGET_FOCUSED?(widget) [
		flags: flags or PIXEL_INVERTED
	]
	_widget/render x y widget flags
]

init-checkbox: func [
	widget		[widget!]
][
	widget/render: as render-func! :draw-checkbox
	widget/update: as update-func! :make-checkbox-ui
	widget/on-event: as event-handler! :on-checkbox-event
	widget/data: null
	make-checkbox-ui widget
]