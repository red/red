Red/System [
	Title:	"GTK3 widget handlers"
	Author: "Qingtian Xie, RCqls"
	File: 	%handlers.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

set-selected: func [
	obj			[handle!]
	ctx			[node!]
	idx			[integer!]
	/local
		int		[red-integer!]
][
	int: as red-integer! get-node-facet ctx FACE_OBJ_SELECTED
	int/header: TYPE_INTEGER
	int/value: idx
]

set-text: func [
	obj			[handle!]
	ctx			[node!]
	text		[c-string!]
	/local
		size	[integer!]
		str		[red-string!]
		face	[red-object!]
		out		[c-string!]
][
	;; DEBUG: print ["set-text: " text lf]
	size: length? text
	;; DEBUG: print ["length?: " size lf]
	if size >= 0 [
		str: as red-string! get-node-facet ctx FACE_OBJ_TEXT
		if TYPE_OF(str) <> TYPE_STRING [
			string/make-at as red-value! str size UCS-2
		]
		if size = 0 [
			string/rs-reset str
			exit
		]
		;; TODO: bug with unicode characters just below
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
	evbox		[handle!]
	widget		[handle!]
][
	make-event widget 0 EVT_CLICK
]

button-toggled: func [
	[cdecl]
	evbox		[handle!]
	button		[handle!]
	/local
		bool	[red-logic!]
		type	[integer!]
		undetermined? [logic!]
][
	bool: (as red-logic! get-face-values button) + FACE_OBJ_DATA
	undetermined?: gtk_toggle_button_get_inconsistent button

	either undetermined? [
		type: TYPE_OF(bool)
		bool/header: TYPE_NONE						;-- NONE indicates undeterminate
	][
		bool/value: gtk_toggle_button_get_active button
	]
	make-event button 0 EVT_CHANGE
]

render-text: func [
	cr			[handle!]
	face		[red-object!]
	size		[red-pair!]
	values		[red-value!]
	/local
		text	[red-string!]
		color	[red-tuple!]
		font	[red-object!]
		attrs	[handle!]
		new?	[logic!]
		para	[red-object!]
		flags	[integer!]
		layout	[handle!]
		len		[integer!]
		str		[c-string!]
		pline	[handle!]
		lx		[integer!]
		ly		[integer!]
		x		[float!]
		y		[float!]
		rect	[tagRECT value]
		lrect	[tagRECT value]
][
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [exit]

	color: as red-tuple! values + FACE_OBJ_COLOR
	font: as red-object! values + FACE_OBJ_FONT
	attrs: get-attrs face font
	new?: false
	if null? attrs [
		new?: true
		attrs: create-simple-attrs default-font-name default-font-size color
	]

	;; DEBUG: print ["render-text: " cr lf]
	para: as red-object! values + FACE_OBJ_PARA
	flags: either TYPE_OF(para) = TYPE_OBJECT [		;@@ TBD set alignment attribute
		get-para-flags base para
	][
		0005h										;-- center or middle
	]

	layout: pango_cairo_create_layout cr
	cairo_save cr

	len: -1
	str: unicode/to-utf8 text :len
	pango_layout_set_text layout str -1
	pango_layout_set_attributes layout attrs

	pango_cairo_update_layout cr layout

	pline: pango_layout_get_line layout 0
	pango_layout_line_get_pixel_extents pline rect lrect
	ly: (pango_layout_get_line_count layout) * lrect/height
	lx: lrect/width

	case [
		flags and 0001h <> 0 [x: (as-float (size/x - lx)) / 2.0]	; center
		flags and 0002h <> 0 [x: as-float (size/x - lx)] 			; right
		true [x: 0.0]			 									; left
	]
	case [
		flags and 0004h <> 0 [y: (as-float (size/y - ly)) / 2.0]	; middle
		flags and 0008h <> 0 [y: as-float (size/y - ly)] 			; bottom
		true [y: 0.0] 												; top
	]

	;; DEBUG: print [lx "x" ly " and (" x "," y ")" lf]

	cairo_move_to cr x y
	pango_cairo_show_layout cr layout
	cairo_stroke cr
	cairo_restore cr

	if new? [
		free-pango-attrs attrs
	]
]

base-draw: func [
	[cdecl]
	evbox		[handle!]
	cr			[handle!]
	widget		[handle!]
	return:		[integer!]
	/local
		face	[red-object!]
		values	[red-value!]
		draw	[red-block!]
		img		[red-image!]
		size	[red-pair!]
		type	[red-word!]
		font	[red-object!]
		color	[red-tuple!]
		sym		[integer!]
		pos		[red-pair! value]
		DC		[draw-ctx! value]
		drawDC	[draw-ctx!]
][
	face: get-face-obj widget
	values: object/get-values face
	img:  as red-image! values + FACE_OBJ_IMAGE
	draw: as red-block! values + FACE_OBJ_DRAW
	size: as red-pair! values + FACE_OBJ_SIZE
	type: as red-word! values + FACE_OBJ_TYPE
	font: as red-object! values + FACE_OBJ_FONT
	color: as red-tuple! values + FACE_OBJ_COLOR
	sym: symbol/resolve type/symbol

	if TYPE_OF(color) = TYPE_TUPLE [
		free-font font
		make-font face font
		set-css widget face values
		gtk_render_background
				gtk_widget_get_style_context widget
				cr
				0.0 0.0
				as float! size/x as float! size/y
	]

	if TYPE_OF(img) = TYPE_IMAGE [
		;; DEBUG: print ["base-draw, GDK-draw-image: " 0 "x" 0 "x" size/x "x" size/y lf]
		;; ONLY WORK for Mandelbrot and raytracer:
		;; GDK-draw-image cr OS-image/to-argb-pixbuf img 0 0 size/x size/y
		GDK-draw-image cr OS-image/to-pixbuf img 0 0 size/x size/y
	]

	case [
		sym = base [render-text cr face size values]
		sym = rich-text [
			pos/x: 0 pos/y: 0
			draw-text-box cr :pos get-face-obj widget yes
		]
		true []
	]

	either TYPE_OF(draw) = TYPE_BLOCK [
		do-draw cr null draw no yes yes yes
	][
		system/thrown: 0
		drawDC: declare draw-ctx!								;@@ should declare it on stack
		draw-begin drawDC cr null no no
		integer/make-at as red-value! draw as-integer drawDC
		make-event widget 0 EVT_DRAWING
		draw/header: TYPE_NONE
		draw-end drawDC cr no no no
	]

	;if null? gtk_container_get_children widget [
	;	return EVT_NO_DISPATCH
	;]

	EVT_DISPATCH
]

window-delete-event: func [
	[cdecl]
	widget		[handle!]
	return:		[integer!]
][
	;; DEBUG: print ["window-delete-event" lf]
	make-event widget 0 EVT_CLOSE
	EVT_DISPATCH
]

window-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventAny!]
	widget		[handle!]
	return:		[integer!]
	/local
		h		[handle!]
][
	h: GET-STARTRESIZE(widget)
	unless null? h [
		if event/type = 13 [				;-- GDK_PROXIMITY_OUT
			h: as handle! 1
			SET-RESIZING(widget h)
		]
		if event/type = 12 [				;-- GDK_PROXIMITY_IN
			h: GET-RESIZING(widget)
			unless null? h [
				make-event widget 0 EVT_SIZING
				make-event widget 0 EVT_SIZE
			]
			h: as handle! 0
			SET-RESIZING(widget h)
			SET-STARTRESIZE(widget h)
		]
	]
	EVT_DISPATCH
]

window-size-allocate: func [
	[cdecl]
	evbox		[handle!]
	rect		[tagRECT]
	widget		[handle!]
	/local
		sz		[red-pair!]
		h		[handle!]
][
	;; DEBUG: print ["window-size-allocate rect: " rect/x "x" rect/y "x" rect/width "x" rect/height     lf]
	sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE
	h: GET-STARTRESIZE(widget)
	if null? h [
		h: as handle! 1
		SET-STARTRESIZE(widget h)
	]
	if any [
		sz/x <> rect/width
		sz/y <> rect/height
	][
		sz/x: rect/width
		sz/y: rect/height
		h: GET-RESIZING(widget)
		either null? h [
			make-event widget 0 EVT_SIZE
		][
			make-event widget 0 EVT_SIZING
		]
	]
]

range-value-changed: func [
	[cdecl]
	range		[handle!]
	widget		[handle!]
	/local
		values	[red-value!]
		pos		[red-float!]
		value	[float!]
][
	values: get-face-values widget
	pos: as red-float! values + FACE_OBJ_DATA

	value: gtk_range_get_value range
	pos/value: value / 100.0
	make-event range 0 EVT_CHANGE
]

combo-selection-changed: func [
	[cdecl]
	evbox		[handle!]
	widget		[handle!]
	/local
		idx		[integer!]
		res		[integer!]
		text	[c-string!]
		face	[red-object!]
][
	idx: gtk_combo_box_get_active widget
	if idx >= 0 [
		face: get-face-obj widget
		res: make-event widget idx + 1 EVT_SELECT
		set-selected widget face/ctx idx + 1
		text: gtk_combo_box_text_get_active_text widget
		set-text widget face/ctx text
		if res = EVT_DISPATCH [
			make-event widget idx + 1 EVT_CHANGE
		]
	]
]

text-list-selected-rows-changed: func [
	[cdecl]
	evbox		[handle!]
	widget		[handle!]
	/local
		idx		[integer!]
		sel		[handle!]
		res		[integer!]
		text	[c-string!]
		face	[red-object!]
][
	; From now, only single-selection mode
	sel: gtk_list_box_get_selected_row widget
	idx: either null? sel [-1][gtk_list_box_row_get_index sel]
	if idx >= 0 [
		face: get-face-obj widget
		res: make-event widget idx + 1 EVT_SELECT
		set-selected widget face/ctx idx + 1
		text: gtk_label_get_text gtk_bin_get_child sel
		set-text widget face/ctx text
		if res = EVT_DISPATCH [
			make-event widget idx + 1 EVT_CHANGE
		]
	]
]

tab-panel-switch-page: func [
	[cdecl]
	evbox		[handle!]
	page		[handle!]
	idx			[integer!]
	widget		[handle!]
	/local
		res		[integer!]
		text	[c-string!]
		face	[red-object!]
][
	if idx >= 0 [
		face: get-face-obj widget
		res: make-event widget idx + 1 EVT_SELECT
		set-selected widget face/ctx idx + 1
		text: gtk_notebook_get_tab_label_text widget page
		set-text widget face/ctx text
		if res = EVT_DISPATCH [
			make-event widget idx + 1 EVT_CHANGE
		]
	]
]

key-press-event: func [
	[cdecl]
	evbox		[handle!]
	event-key	[GdkEventKey!]
	widget		[handle!]
	return:		[integer!]
	/local
		win		[handle!]
		face	[red-object!]
		values	[red-value!]
		type	[red-word!]
		sym		[integer!]
		res		[integer!]
		key		[integer!]
		flags	[integer!]
		key2	[integer!]
][
	win: gtk_get_event_widget as handle! event-key
	if evbox <> gtk_window_get_focus win [return EVT_NO_DISPATCH]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	key: translate-key event-key/keyval
	key2: gdk_keyval_to_unicode event-key/keyval
	flags: check-extra-keys event-key/state
	either all [
		key2 > 0
		key2 <= FFFFh
	][
		special-key: 0
		res: make-event widget key2 or flags EVT_KEY_DOWN
		if res <> EVT_NO_DISPATCH [
			return make-event widget key2 or flags EVT_KEY
		]
	][
		special-key: either char-key? as-byte key [0][-1]		;-- special key or not
		res: make-event widget key or flags EVT_KEY_DOWN
		if res <> EVT_NO_DISPATCH [
			return make-event widget key or flags EVT_KEY
		]
	]
	res
]

key-release-event: func [
	[cdecl]
	evbox		[handle!]
	event-key	[GdkEventKey!]
	widget		[handle!]
	return:		[integer!]
	/local
		win		[handle!]
		face	[red-object!]
		values	[red-value!]
		type	[red-word!]
		sym		[integer!]
		key		[integer!]
		flags	[integer!]
		key2	[integer!]
][
	win: gtk_get_event_widget as handle! event-key
	if evbox <> gtk_window_get_focus win [return EVT_NO_DISPATCH]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	key: translate-key event-key/keyval
	key2: gdk_keyval_to_unicode event-key/keyval
	flags: check-extra-keys event-key/state
	either all [
		key2 > 0
		key2 <= FFFFh
	][
		special-key: 0
		make-event widget key2 or flags EVT_KEY_DOWN
	][
		special-key: either char-key? as-byte key [0][-1]		;-- special key or not
		make-event widget key or flags EVT_KEY_DOWN
	]
]

field-changed: func [
	[cdecl]
	buffer		[handle!]
	widget		[handle!]
	/local
		text	[c-string!]
		face	[red-object!]
][
	text: gtk_entry_get_text widget
	face: get-face-obj widget
	unless null? face [
		set-text widget face/ctx text
		make-event widget 0 EVT_CHANGE
	]
]

focus-in-event: func [
	[cdecl]
	evbox		[handle!]
	event		[handle!]
	widget		[handle!]
	return:		[integer!]
	/local
		face	[red-object!]
		values	[red-value!]
		type	[red-word!]
		int		[red-integer!]
		sym		[integer!]
][
	if evbox <> gtk_get_event_widget event [return EVT_NO_DISPATCH]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	int: as red-integer! values + FACE_OBJ_SELECTED
	sym: symbol/resolve type/symbol
	change-selection widget int sym
	make-event widget 0 EVT_FOCUS
]

focus-out-event: func [
	[cdecl]
	evbox		[handle!]
	event		[handle!]
	widget		[handle!]
	return:		[integer!]
	/local
		face	[red-object!]
		values	[red-value!]
		type	[red-word!]
		sym		[integer!]
][
	if evbox <> gtk_get_event_widget event [return EVT_NO_DISPATCH]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	make-event widget 0 EVT_UNFOCUS
]

area-changed: func [
	[cdecl]
	buffer		[handle!]
	widget		[handle!]
	/local
		text	[c-string!]
		face	[red-object!]
		start	[GtkTextIter! value]
		end		[GtkTextIter! value]
][
	; Weirdly, GtkTextIter introduced since I did not simplest solution to get the full content of a GtkTextBuffer!
	gtk_text_buffer_get_bounds buffer as handle! start as handle! end
	text: gtk_text_buffer_get_text buffer as handle! start as handle! end no
	face: get-face-obj widget
	unless null? face [
		set-text widget face/ctx text
		make-event widget 0 EVT_CHANGE
	]
]

area-populate-popup: func [
	[cdecl]
	evbox		[handle!]
	hMenu		[handle!]
	widget		[handle!]
	/local
		values	[red-value!]
		menu	[red-block!]
][
	values: get-face-values widget
	menu: as red-block! values + FACE_OBJ_MENU
	;; DEBUG: print ["populate menu for " widget " and menu " hMenu lf]
	append-context-menu menu hMenu widget
]

red-timer-action: func [
	[cdecl]
	self		[handle!]
	return:		[logic!]
	/local
		timer	[int-ptr!]
][
	make-event self 0 EVT_TIME
	true
]

widget-enter-notify-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventCrossing!]
	widget		[handle!]
	return:		[integer!]
	/local
		flags	[integer!]
][
	if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	flags: check-flags event/type event/state
	make-event widget flags EVT_OVER
]

widget-leave-notify-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventCrossing!]
	widget		[handle!]
	return:		[integer!]
	/local
		flags	[integer!]
][
	if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	flags: check-flags event/type event/state
	make-event widget flags or EVT_FLAG_AWAY EVT_OVER
]

mouse-button-release-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventButton!]
	widget		[handle!]
	return:		[integer!]
	/local
		sym		[integer!]
		x		[integer!]
		y		[integer!]
		sel		[red-pair!]
		buffer	[handle!]
		start	[GtkTextIter! value]
		end		[GtkTextIter! value]
		flags	[integer!]
		ev		[integer!]
][
	if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	sym: get-widget-symbol widget
	if sym = field [
		if event/button = GDK_BUTTON_PRIMARY [
			x: -1 y: -1
			if gtk_editable_get_selection_bounds widget :x :y [
				;; DEBUG: print ["from " x " to " y lf ]
				sel: as red-pair! (get-face-values widget) + FACE_OBJ_SELECTED
				either x = y [sel/header: TYPE_NONE][
					sel/header: TYPE_PAIR
					sel/x: x + 1
					sel/y: y
				]
				make-event widget 0 EVT_SELECT
			]
		]
	]
	if sym = area [
		if event/button = GDK_BUTTON_PRIMARY [
			buffer: gtk_text_view_get_buffer widget
			if gtk_text_buffer_get_selection_bounds buffer as handle! start as handle! end [
				x: -1 y: -1
				x: gtk_text_iter_get_offset as handle! start
				y: gtk_text_iter_get_offset as handle! end
				;; DEBUG: print ["from " x " to " y lf ]
				sel: as red-pair! (get-face-values widget) + FACE_OBJ_SELECTED
				either x = y [sel/header: TYPE_NONE][
					sel/header: TYPE_PAIR
					sel/x: x + 1
					sel/y: y
				]
				make-event widget 0 EVT_SELECT
			]
		]
	]
	evt-motion/state: yes
	evt-motion/cpt: 0
	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	evt-motion/x_new: as-integer event/x
	evt-motion/y_new: as-integer event/y
	flags: check-flags event/type event/state
	ev: case [
		event/button = GDK_BUTTON_SECONDARY [EVT_RIGHT_UP]
		event/button = GDK_BUTTON_MIDDLE [EVT_MIDDLE_UP]
		true [EVT_LEFT_UP]
	]
	make-event widget flags ev
]

mouse-button-press-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventButton!]
	widget		[handle!]
	return:		[integer!]
	/local
		sym		[integer!]
		flags	[integer!]
		hMenu	[handle!]
		ev		[integer!]
][
	if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	sym: get-widget-symbol widget

	if gtk_widget_get_focus_on_click widget [
		;; DEBUG: print ["grab focus on mouse " widget lf]
		gtk_widget_grab_focus widget
	]

	;; DEBUG: print ["with button " event/button lf]
	if  event/button = GDK_BUTTON_SECONDARY  [
		hMenu: context-menu? widget
		;; DEBUG: print ["widget " widget " with menu " hMenu lf]
		unless null? hMenu [
			menu-x: as-integer event/x
			menu-y: as-integer event/y
			;; DEBUG: print ["menu pointer : " menu-x "x" menu-y lf]
			gtk_menu_popup_at_pointer hMenu	 as handle! event
			return EVT_NO_DISPATCH
		]

	]

	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	evt-motion/x_new: as-integer event/x
	evt-motion/y_new: as-integer event/y
	flags: check-flags event/type event/state
	ev: case [
		event/button = GDK_BUTTON_SECONDARY [EVT_RIGHT_DOWN]
		event/button = GDK_BUTTON_MIDDLE [EVT_MIDDLE_DOWN]
		true [EVT_LEFT_DOWN]
	]
	make-event widget flags ev
]

mouse-motion-notify-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventMotion!]
	widget		[handle!]
	return:		[integer!]
	/local
		offset	[red-pair!]
		x		[float!]
		y		[float!]
		wflags	[integer!]
		flags	[integer!]
][
	if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	evt-motion/x_new: as-integer event/x
	evt-motion/y_new: as-integer event/y
	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	wflags: get-flags (as red-block! get-face-values widget) + FACE_OBJ_FLAGS
	if wflags and FACET_FLAGS_ALL_OVER <> 0 [
		flags: check-flags event/type event/state
		return make-event widget flags EVT_OVER
	]
	EVT_DISPATCH
]

widget-scroll-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventScroll!]
	widget		[handle!]
	return:		[integer!]
][
	if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	g_object_set_qdata widget red-event-id as handle! event
	if any [event/delta_y < -0.01 event/delta_y > 0.01][
		return make-event widget check-down-flags event/state EVT_WHEEL
	]
	EVT_DISPATCH
]

menu-item-activate: func [
	[cdecl]
	item		[handle!]
	widget		[handle!]
	/local
		key		[integer!]
][
	key: menu-item-key? item
	make-event widget key EVT_MENU
]
