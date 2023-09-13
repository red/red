Red/System [
	Title:	"Text list widget"
	Author: "Xie Qingtian"
	File: 	%text-list.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

make-text-list-ui: func [
	widget		[widget!]
	/local
		face	[red-object!]
][
	face: get-face-obj widget
	#call [system/view/platform/make-text-list-ui face]
]

on-text-list-event: func [
	type		[event-type!]
	evt			[widget-event!]
	return:		[integer!]
	/local
		widget	[widget!]
		cp		[integer!]
		idx		[integer!]
		len		[integer!]
		head	[integer!]
		w h		[integer!]
		off-y	[integer!]
		data	[red-block!]
		values	[red-value!]
		change? [logic!]
		selected [red-integer!]
][
	widget: evt/widget
	values: get-face-values widget
	data: as red-block! values + FACE_OBJ_DATA
	selected: as red-integer! values + FACE_OBJ_SELECTED

	w: 0 h: 0
	_widget/get-size widget :w :h
	head: as-integer widget/data
	idx: selected/value
	change?: no

	case [
		type = EVT_KEY [
			len: switch TYPE_OF(data) [
				TYPE_MAP [map/rs-length? as red-hash! data]
				TYPE_BLOCK
				TYPE_HASH [block/rs-length? data]
				default [0]
			]
			cp: evt/data
			switch cp [
				KEY_UP [
					if idx > 1 [
						idx: idx - 1
						change?: yes
					]
					if all [idx - 1 < head head > 0][
						head: head - 1
					]
				]
				KEY_DOWN [
					if idx < len [
						idx: idx + 1
						change?: yes
					]
					if idx - h > head [
						head: head + 1
					]
				]
				default [return 0]
			]
			widget/data: as int-ptr! head
		]
		type = EVT_FOCUS [
			change?: yes
		]
		type = EVT_CLICK [
			off-y: as-integer evt/pt/y
			idx: head + off-y + 1
			if TYPE_OF(selected) <> TYPE_INTEGER [
				selected/header: TYPE_INTEGER
			]
		]
		true [0]
	]

	selected/value: idx
	make-text-list-ui widget
	screen/redraw widget
	if change? [make-red-event EVT_CHANGE widget 0]
	0
]

init-text-list: func [
	widget		[widget!]
][
	WIDGET_SET_FLAG(widget WIDGET_FLAG_FOCUSABLE)
	widget/update: as update-func! :make-text-list-ui
	widget/on-event: as event-handler! :on-text-list-event
	widget/data: null
	make-text-list-ui widget
]