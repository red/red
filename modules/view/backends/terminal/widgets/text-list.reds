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
	#call [TUI-helpers/make-text-list-ui face]
]

on-text-list-event: func [
	type		[event-type!]
	evt			[widget-event!]
	return:		[integer!]
	/local
		widget	[widget!]
		cp		[integer!]
		cur-idx	[integer!]
		idx		[integer!]
		len		[integer!]
		head	[integer!]
		w h		[integer!]
		off-y	[integer!]
		ret		[integer!]
		data	[red-block!]
		values	[red-value!]
		fstate	[red-value!]
		selected [red-integer!]
][
	widget: evt/widget
	values: get-face-values widget
	data: as red-block! values + FACE_OBJ_DATA
	selected: as red-integer! values + FACE_OBJ_SELECTED

	w: 0 h: 0
	_widget/get-size widget :w :h
	head: as-integer widget/data
	cur-idx: selected/value
	idx: cur-idx

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
					]
					if all [idx - 1 < head head > 0][
						head: head - 1
					]
				]
				KEY_DOWN [
					if idx < len [
						idx: idx + 1
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
			make-text-list-ui widget
			screen/redraw widget
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

	if cur-idx <> idx [		;-- select a different item
		ret: make-red-event EVT_SELECT widget idx

		fstate: values + FACE_OBJ_STATE
		if TYPE_OF(fstate) <> TYPE_BLOCK [return 0]	;-- widget destroyed

		values: get-face-values widget
		selected: as red-integer! values + FACE_OBJ_SELECTED
		if cur-idx <> selected/value [			;-- change item inside select handler
			return 0
		]
		selected/value: idx
		make-text-list-ui widget
		screen/redraw widget
		if ret = EVT_DISPATCH [
			make-red-event EVT_CHANGE widget idx
		]
	]
	0
]

init-text-list: func [
	widget		[widget!]
][
	widget/update: as update-func! :make-text-list-ui
	widget/on-event: as event-handler! :on-text-list-event
	widget/data: null
	make-text-list-ui widget
]