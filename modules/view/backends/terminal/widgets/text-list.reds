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
		data	[red-block!]
		values	[red-value!]
		selected [red-integer!]
][
	widget: evt/widget
	values: get-face-values widget
	data: as red-block! values + FACE_OBJ_DATA
	selected: as red-integer! values + FACE_OBJ_SELECTED

	idx: selected/value

	if type = EVT_KEY [
		len: switch TYPE_OF(data) [
			TYPE_MAP [map/rs-length? as red-hash! data]
			TYPE_BLOCK
			TYPE_HASH [block/rs-length? data]
			default [0]
		]
		cp: evt/data
		switch cp [
			KEY_UP [
				if idx > 1 [idx: idx - 1]
			]
			KEY_DOWN [
				if idx < len [idx: idx + 1]
			]
			default [return 0]
		]
	]

	selected/value: idx
	make-text-list-ui widget
	screen/redraw
	0
]

init-text-list: func [
	widget		[widget!]
][
	WIDGET_SET_FLAG(widget WIDGET_FLAG_FOCUSABLE)
	widget/update: as update-func! :make-text-list-ui
	widget/on-event: as event-handler! :on-text-list-event
	make-text-list-ui widget
]