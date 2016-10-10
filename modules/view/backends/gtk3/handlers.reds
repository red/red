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