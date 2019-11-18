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
		pvalues	[red-value!]
		hsym	[integer!]
		vsym	[integer!]
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

	para: as red-object! values + FACE_OBJ_PARA
	either TYPE_OF(para) = TYPE_OBJECT [
		pvalues: object/get-values para
		hsym: get-para-hsym pvalues
		vsym: get-para-vsym pvalues
	][
		hsym: _para/center
		vsym: _para/middle
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
		hsym = _para/center [x: (as-float (size/x - lx)) / 2.0]
		hsym = _para/right [x: as-float (size/x - lx)]
		true [x: 0.0]
	]
	case [
		vsym = _para/middle [y: (as-float (size/y - ly)) / 2.0]
		vsym = _para/bottom [y: as-float (size/y - ly)]
		true [y: 0.0]
	]

	cairo_move_to cr x y
	pango_cairo_show_layout cr layout
	cairo_stroke cr
	cairo_restore cr
	g_object_unref layout

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

base-event-after: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventAny!]
	widget		[handle!]
	/local
		etype	[integer!]
		face	[red-object!]
		values	[red-value!]
		type	[red-word!]
		color	[red-tuple!]
		offset	[red-pair!]
		parent	[red-object!]
		sym		[integer!]
		hparent	[handle!]
		pane	[red-block!]
		head	[red-object!]
		tail	[red-object!]
		target	[handle!]
		offset2	[red-pair!]
		dx		[float!]
		dy		[float!]
		motion	[GdkEventMotion!]
		button	[GdkEventButton!]
		key		[GdkEventKey!]
		win		[handle!]
][
	etype: event/type
	unless any [
		etype = GDK_MOTION_NOTIFY
		etype = GDK_BUTTON_PRESS
		etype = GDK_2BUTTON_PRESS
		etype = GDK_3BUTTON_PRESS
		etype = GDK_BUTTON_RELEASE
		etype = GDK_KEY_PRESS
		etype = GDK_KEY_RELEASE
	][exit]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	color: as red-tuple! values + FACE_OBJ_COLOR
	offset: as red-pair! values + FACE_OBJ_OFFSET
	parent: as red-object! values + FACE_OBJ_PARENT
	sym: symbol/resolve type/symbol

	if all [
		sym = base
		TYPE_OF(color) = TYPE_NONE
	][
		hparent: get-face-handle parent
		pane: as red-block! (object/get-values parent) + FACE_OBJ_PANE
		head: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [tail > head][
			tail: tail - 1
			if tail/ctx = face/ctx [
				while [tail > head][
					tail: tail - 1
					target: face-handle? tail
					if null? target [
						continue
					]
					offset2: as red-pair! (object/get-values tail) + FACE_OBJ_OFFSET
					case [
						etype = GDK_MOTION_NOTIFY [
							motion: as GdkEventMotion! event
							dx: as float! offset/x - offset2/x
							dy: as float! offset/y - offset2/y
							motion/x: motion/x + dx
							motion/y: motion/y + dy
							motion/x_root: motion/x_root + dx
							motion/y_root: motion/y_root + dy
							gtk_widget_event target as handle! event
							SET-RESEND-EVENT(target target)
						]
						any [
							etype = GDK_BUTTON_PRESS
							etype = GDK_2BUTTON_PRESS
							etype = GDK_3BUTTON_PRESS
							etype = GDK_BUTTON_RELEASE
						][
							button: as GdkEventButton! event
							dx: as float! offset/x - offset2/x
							dy: as float! offset/y - offset2/y
							button/x: button/x + dx
							button/y: button/y + dy
							button/x_root: button/x_root + dx
							button/y_root: button/y_root + dy
							gtk_widget_event target as handle! event
							SET-RESEND-EVENT(target target)
						]
						any [
							etype = GDK_KEY_PRESS
							etype = GDK_KEY_RELEASE
						][
							win: gtk_get_event_widget as handle! event
							if all [
								evbox = gtk_window_get_focus win
								gtk_widget_get_can_focus target
							][
								gtk_widget_grab_focus target
								gtk_widget_event target as handle! event
								SET-RESEND-EVENT(target target)
							]
						]
					]
					exit
				]
				exit
			]
		]
	]
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

widget-realize: func [
	[cdecl]
	evbox		[handle!]
	widget		[handle!]
	/local
		cursor	[handle!]
		win		[handle!]
][
	cursor: GET-CURSOR(widget)
	unless null? cursor [
		win: gtk_widget_get_window widget
		gdk_window_set_cursor win cursor
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
	either null? GET-RESEND-EVENT(evbox) [
		win: gtk_get_event_widget as handle! event-key
		if evbox <> gtk_window_get_focus win [return EVT_NO_DISPATCH]
	][
		SET-RESEND-EVENT(evbox null)
	]

	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	key: translate-key event-key/keyval
	flags: check-extra-keys event-key/state
	special-key: either char-key? as-byte key [0][-1]		;-- special key or not
	res: make-event widget key or flags EVT_KEY_DOWN
	if res <> EVT_NO_DISPATCH [
		key2: gdk_keyval_to_unicode event-key/keyval
		if all [
			key2 > 0
			key2 <= FFFFh
		][
			special-key: 0
			return make-event widget key2 or flags EVT_KEY
		]
		if key <> 0 [
			res: make-event widget key or flags EVT_KEY
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
][
	either null? GET-RESEND-EVENT(evbox) [
		win: gtk_get_event_widget as handle! event-key
		if evbox <> gtk_window_get_focus win [return EVT_NO_DISPATCH]
	][
		SET-RESEND-EVENT(evbox null)
	]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	key: translate-key event-key/keyval
	flags: check-extra-keys event-key/state
	special-key: either char-key? as-byte key [0][-1]		;-- special key or not
	make-event widget key or flags EVT_KEY_UP
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
	if evbox <> gtk_get_event_widget event [return EVT_DISPATCH]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	int: as red-integer! values + FACE_OBJ_SELECTED
	sym: symbol/resolve type/symbol
	change-selection widget int sym
	make-event widget 0 EVT_FOCUS
	EVT_DISPATCH
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
	if evbox <> gtk_get_event_widget event [return EVT_DISPATCH]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	make-event widget 0 EVT_UNFOCUS
	EVT_DISPATCH
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
	if evt-motion/pressed [return EVT_NO_DISPATCH]
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
	if evt-motion/pressed [return EVT_NO_DISPATCH]
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
	either null? GET-RESEND-EVENT(evbox) [
		if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	][
		SET-RESEND-EVENT(evbox null)
	]
	sym: get-widget-symbol widget

	if event/button = GDK_BUTTON_PRIMARY [
		case [
			sym = field [
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
			sym = area [
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
			true [0]
		]
		evt-motion/pressed: no
	]

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
	either null? GET-RESEND-EVENT(evbox) [
		if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	][
		SET-RESEND-EVENT(evbox null)
	]
	sym: get-widget-symbol widget

	if event/button = GDK_BUTTON_PRIMARY [
		evt-motion/pressed: yes
	]

	if event/button = GDK_BUTTON_SECONDARY [
		hMenu: GET-MENU-KEY(widget)
		unless null? hMenu [
			menu-x: as-integer event/x
			menu-y: as-integer event/y
			gtk_menu_popup_at_pointer hMenu as handle! event
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
		wflags	[integer!]
		x		[float!]
		y		[float!]
		flags	[integer!]
][
	either null? GET-RESEND-EVENT(evbox) [
		if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	][
		SET-RESEND-EVENT(evbox null)
	]
	wflags: get-flags (as red-block! get-face-values widget) + FACE_OBJ_FLAGS
	if wflags and FACET_FLAGS_ALL_OVER = 0 [return EVT_DISPATCH]
	evt-motion/x_new: as-integer event/x
	evt-motion/y_new: as-integer event/y
	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	flags: check-flags event/type event/state
	make-event widget flags EVT_OVER
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
	key: as integer! GET-MENU-KEY(item)
	make-event widget key EVT_MENU
]
