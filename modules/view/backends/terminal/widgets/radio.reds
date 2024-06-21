Red/System [
	Title:	"Radio widget"
	Author: "Xie Qingtian"
	File: 	%radio.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

make-radio-ui: func [
	widget		[widget!]
	/local
		face	[red-object!]
		ui		[red-string!]
][
	face: get-face-obj widget
	#call [TUI-helpers/make-radio-ui face]
	ui: as red-string! stack/arguments
	widget/ui: ui/node
]

on-radio-event: func [
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

		if TYPE_OF(data) <> TYPE_LOGIC [
			data/header: TYPE_LOGIC
		]
		data/value: yes
		make-radio-ui widget
		screen/redraw widget
		make-red-event EVT_CHANGE widget 0
	]
	0
]

draw-radio: func [
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

init-radio: func [
	widget		[widget!]
][
	widget/render: as render-func! :draw-radio
	widget/update: as update-func! :make-radio-ui
	widget/on-event: as event-handler! :on-radio-event
	widget/data: null
	make-radio-ui widget
]