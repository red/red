Red/System [
	Title:	"GTK3 widget handlers"
	Author: "Qingtian Xie"
	File: 	%handlers.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

gtk-app-activate: func [
	[cdecl]
	app		[handle!]
	data	[int-ptr!]
	/local
		win [handle!]
][
	probe "active"
]

set-selected: func [
	obj [handle!]
	ctx [node!]
	idx [integer!]
	/local
		int [red-integer!]
][
	int: as red-integer! get-node-facet ctx FACE_OBJ_SELECTED
	int/header: TYPE_INTEGER
	int/value: idx
]

set-text: func [
	obj		[handle!]
	ctx		[node!]
	text	[c-string!]
	/local
		size [integer!]
		str	 [red-string!]
		face [red-object!]
		out	 [c-string!]
][
	size: length? text
	if size >= 0 [
		str: as red-string! get-node-facet ctx FACE_OBJ_TEXT
		if TYPE_OF(str) <> TYPE_STRING [
			string/make-at as red-value! str size UCS-2
		]
		if size = 0 [
			string/rs-reset str
			exit
		]
		unicode/load-utf8-buffer text size GET_BUFFER(str) null no
		
		face: push-face obj
		if TYPE_OF(face) = TYPE_OBJECT [
			ownership/bind as red-value! str face _text
		]
		stack/pop 1
	]
]

button-clicked: func [
	[cdecl]
	widget	[handle!]
	ctx		[node!]
][
	make-event widget 0 EVT_CLICK
]

button-toggled: func [
	[cdecl]
	button	[handle!]
	ctx		[node!]
	/local
		bool		  [red-logic!]
		type		  [integer!]
		undetermined? [logic!]
][
	bool: as red-logic! get-node-facet ctx FACE_OBJ_DATA
	undetermined?: gtk_toggle_button_get_inconsistent button

	either undetermined? [
		type: TYPE_OF(bool)
		bool/header: TYPE_NONE						;-- NONE indicates undeterminate
	][
		bool/value: gtk_toggle_button_get_active button
	]
	make-event button 0 EVT_CHANGE
]

base-draw: func [
	[cdecl]
	widget	[handle!]
	cr		[handle!]
	ctx		[node!]
	return: [logic!]
	/local
		vals [red-value!]
		draw [red-block!]
		clr  [red-tuple!]
][
	vals: get-node-values ctx
	draw: as red-block! vals + FACE_OBJ_DRAW
	clr:  as red-tuple! vals + FACE_OBJ_COLOR
	if TYPE_OF(clr) = TYPE_TUPLE [
		set-source-color cr clr/array1
		cairo_paint cr								;-- paint background
	]
	do-draw cr null draw no yes yes yes
	false
]

window-delete-event: func [
	[cdecl]
	widget	[handle!]
	event	[handle!]
	exit-lp	[int-ptr!]
	return: [logic!]
][
	false
]

window-removed-event: func [
	[cdecl]
	app		[handle!]
	widget	[handle!]
	count	[int-ptr!]
][
	count/value: count/value - 1
]

range-value-changed: func [
	[cdecl]
	range	[handle!]
	ctx		[node!]
	/local
		vals  [red-value!]
		val   [float!]
		size  [red-pair!]
	;	type  [red-word!]
		pos   [red-float!]
	;	sym   [integer!]
		max   [float!]
][
	; This event happens on GtkRange widgets including GtkScale.
	; Will any other widget need this?
	vals: get-node-values ctx
	;type:	as red-word!	vals + FACE_OBJ_TYPE
	size:	as red-pair!	vals + FACE_OBJ_SIZE
	pos:	as red-float!	vals + FACE_OBJ_DATA

	;sym:	symbol/resolve type/symbol

	;if type = slider [
	val: gtk_range_get_value range
	either size/y > size/x [
		max: as-float size/y
		val: max - val
	][
		max: as-float size/x
	]
	pos/value: val / max
	make-event range 0 EVT_CHANGE
	;]
]

combo-selection-changed: func [
	[cdecl]
	combo	[handle!]
	ctx		[node!]
	/local
		idx [integer!]
		res [integer!]
		text [c-string!]
][
	idx: gtk_combo_box_get_active combo
	if idx >= 0 [
		res: make-event combo idx + 1 EVT_SELECT
		set-selected combo ctx idx + 1
		text: gtk_combo_box_text_get_active_text combo
		set-text combo ctx text
		if res = EVT_DISPATCH [
			make-event combo idx + 1 EVT_CHANGE
		]
	]
]
