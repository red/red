Red/System [
	Title:	"Field widget"
	Author: "Xie Qingtian"
	File: 	%field.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

field-data!: alias struct! [
	idx		[integer!]	;-- cursor index of the text
	cursor	[integer!]	;-- cursor position, take into account char width
	len		[integer!]	;-- length of the text, take into account char width
]

init-field: func [
	widget		[widget!]
	/local
		str		[red-string!]
		w h		[integer!]
		len		[integer!]
		idx		[integer!]
		f		[field-data!]
][
	WIDGET_SET_FLAG(widget WIDGET_FLAG_EDITABLE)
	if widget/data <> null [free as byte-ptr! widget/data]
	widget/data: as int-ptr! zero-alloc size? field-data!
	widget/render: as render-func! :draw-field
	widget/on-event: as event-handler! :on-field-edit

	str: as red-string! (get-face-values widget) + FACE_OBJ_TEXT
	if TYPE_OF(str) = TYPE_STRING [
		w: 0 h: 0
		_widget/get-size widget :w :h

		idx: 0
		len: string-width? str w :idx null

		f: as field-data! widget/data
		f/idx: idx
		f/cursor: len
		f/len: len
	]
]

on-field-edit: func [
	type		[event-type!]
	evt			[widget-event!]
	return:		[integer!]
	/local
		widget	[widget!]
		line	[red-string!]
		field	[field-data!]
		cp		[integer!]
		n		[integer!]
		idx		[integer!]
		w h		[integer!]
		off-x	[integer!]
][
	widget: evt/widget
	field: as field-data! widget/data
	line: as red-string! (get-face-values widget) + FACE_OBJ_TEXT
	if TYPE_OF(line) <> TYPE_STRING [
		string/rs-make-at as red-value! line 10
	]

	w: 0 h: 0
	_widget/get-size widget :w :h

	if type = EVT_CLICK [
		off-x: as-integer evt/pt/x
		idx: 0
		n: string-width? line off-x :idx null
		field/cursor: n
		field/idx: idx
		screen/redraw widget
		return 0
	]

	cp: 0
	if type = EVT_KEY [
		cp: evt/data
	]

	if any [zero? cp cp = as-integer #"^-" cp = as-integer cr][return 0]

	n: 0
	idx: field/idx
	switch cp [
		KEY_CTRL_H
		KEY_BACKSPACE [
			unless zero? idx [
				field/idx: idx - 1
				n: char-width? string/rs-abs-at line line/head + field/idx
				field/cursor: field/cursor - n
				field/len: field/len - n
				string/remove-char line line/head + field/idx
			]
		]
		KEY_CTRL_B
		KEY_LEFT [
			unless zero? idx [
				field/idx: idx - 1
				n: char-width? string/rs-abs-at line line/head + field/idx
				field/cursor: field/cursor - n
			]
		]
		KEY_CTRL_F
		KEY_RIGHT [
			if idx < string/rs-length? line [
				n: char-width? string/rs-abs-at line line/head + field/idx
				field/idx: idx + 1
				field/cursor: field/cursor + n
			]
		]
		KEY_BACKTAB [0]
		default [
			if cp >= 32 [
				n: char-width? cp
				if w - n >= field/len [
					either string/rs-tail? line [
						string/append-char GET_BUFFER(line) cp
					][
						string/insert-char GET_BUFFER(line) line/head + idx cp
					]
					field/idx: idx + 1
					field/cursor: field/cursor + n
					field/len: field/len + n
				]
			]
		]
	]
	screen/redraw widget
	0
]

draw-field: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
	/local
		field	[field-data!]
		flags	[integer!]
][
	widget/box/bottom: widget/box/top + F32_1		;-- force height to 1 line
	flags: either WIDGET_PASSWORD?(widget) [PIXEL_PASSWORD][0]
	_widget/render x y widget flags or PIXEL_ANSI_SEQ
	if WIDGET_FOCUSED?(widget) [
		field: as field-data! widget/data
		screen/cursor-x: x + field/cursor
		screen/cursor-y: y
	]
]