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

#enum _function-key! [
	KEY_CTRL_A:		  1
	KEY_CTRL_B:		  2
	KEY_CTRL_C:		  3
	KEY_CTRL_D:		  4
	KEY_CTRL_E:		  5
	KEY_CTRL_F:		  6
	KEY_CTRL_H:		  8
	KEY_TAB:		  9
	KEY_CTRL_K:		 11
	KEY_CTRL_L:		 12
	KEY_ENTER:		 13
	KEY_CTRL_N:		 14
	KEY_CTRL_P:		 16
	KEY_CTRL_T:		 20
	KEY_CTRL_U:		 21
	KEY_CTRL_W:		 23
	KEY_ESCAPE:		 27
	KEY_BACKSPACE:	127
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
		series	[series!]
		unit	[integer!]
		offset	[byte-ptr!]
		tail	[byte-ptr!]
		w h	cp	[integer!]
		len n	[integer!]
		idx		[integer!]
		f		[field-data!]
][
	WIDGET_SET_FLAG(widget WIDGET_FLAG_FOCUSABLE)
	if widget/data <> null [free as byte-ptr! widget/data]
	widget/data: as int-ptr! zero-alloc size? field-data!
	widget/render: as render-func! :draw-field
	widget/on-event: as event-handler! :on-field-edit
	widget/flags: widget/flags or WIDGET_FLAG_EDITABLE

	str: as red-string! (get-face-values widget) + FACE_OBJ_TEXT
	if TYPE_OF(str) = TYPE_STRING [
		w: 0 h: 0
		_widget/get-size widget :w :h

		len:	0
		idx:	0
		series: GET_BUFFER(str)
		unit: 	GET_UNIT(series)
		offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
		tail:   as byte-ptr! series/tail

		while [
			all [offset < tail len < w]
		][
			cp: string/get-char offset unit
			n: either all [0001F300h <= cp cp <= 0001F5FFh][2][wcwidth? cp]
			len: len + n
			idx: idx + 1
			offset: offset + unit
		]
		if len > w [
			len: len - n
			idx: idx - 1
		]

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
][
	widget: evt/widget
	field: as field-data! widget/data
	line: as red-string! (get-face-values widget) + FACE_OBJ_TEXT
	if TYPE_OF(line) <> TYPE_STRING [
		string/rs-make-at as red-value! line 10
	]

	w: 0 h: 0
	_widget/get-size widget :w :h

	cp: 0
	if type = EVT_KEY [
		cp: evt/data
		if SPECIAL_KEY?(cp) [cp: cp and 7FFFFFFFh]
	]
	LOG_MSG(["on-edit: " cp])
	if any [zero? cp cp = as-integer #"^-"][return 0]

	idx: field/idx
	switch cp [
		KEY_CTRL_H
		KEY_BACKSPACE [
			unless zero? idx [
				field/idx: idx - 1
				field/cursor: field/cursor - 1
				string/remove-char line line/head + field/idx
			]
		]
		KEY_CTRL_B
		RED_VK_LEFT [
			unless zero? idx [
				field/idx: idx - 1
				field/cursor: field/cursor - 1
			]
		]
		KEY_CTRL_F
		RED_VK_RIGHT [
			if idx < string/rs-length? line [
				field/idx: idx + 1
				field/cursor: field/cursor + 1
			]
		]
		default [
			if w > string/rs-length? line [
				either string/rs-tail? line [
					string/append-char GET_BUFFER(line) cp
				][
					string/insert-char GET_BUFFER(line) line/head + idx cp
				]
				field/idx: idx + 1
				field/cursor: field/cursor + 1
			]
		]
	]
	screen/redraw
	0
]

draw-field: func [
	widget		[widget!]
	/local
		x y		[integer!]
		field	[field-data!]
][
	_widget/render-text widget 0
	if WIDGET_FOCUSED?(widget) [
		x: 0 y: 0
		_widget/get-offset widget :x :y
		field: as field-data! widget/data
		screen/cursor-x: x + field/cursor
		screen/cursor-y: y
	]
]