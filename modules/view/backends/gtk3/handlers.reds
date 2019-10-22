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
	size		[red-pair!]
	values		[red-value!]
	/local
		text	[red-string!]
		font	[red-object!]
		attrs	[handle!]
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


	font: as red-object! values + FACE_OBJ_FONT
	attrs: get-attrs null font

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
]

base-draw: func [
	[cdecl]
	evbox		[handle!]
	cr			[handle!]
	widget		[handle!]
	return:		[logic!]
	/local
		vals	[red-value!]
		draw	[red-block!]
		clr		[red-tuple!]
		img		[red-image!]
		size	[red-pair!]
		type	[red-word!]
		sym		[integer!]
		pos		[red-pair! value]
		DC		[draw-ctx! value]
		drawDC	[draw-ctx!]
][
	;; DEBUG: print ["base-draw " widget " " gtk_widget_get_allocated_width widget "x" gtk_widget_get_allocated_height widget lf]

	vals: get-face-values widget
	img:  as red-image! vals + FACE_OBJ_IMAGE
	draw: as red-block! vals + FACE_OBJ_DRAW
	clr:  as red-tuple! vals + FACE_OBJ_COLOR
	size: as red-pair! vals + FACE_OBJ_SIZE
	type: as red-word! vals + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	if TYPE_OF(clr) = TYPE_TUPLE [
		;; DEBUG: print ["base-draw color" (clr/array1 >>> 24 and FFh)  "x" (clr/array1 >> 16 and FFh ) "x" (clr/array1 >> 8 and FFh ) "x" (clr/array1 and FFh ) lf]

		;;;  OLD and DOES NOT WORK
		; cairo_save cr
		; set-source-color cr clr/array1
		; cairo_paint cr								;-- paint background
		; cairo_restore cr
		;cairo_save cr
		gtk_render_background gtk_widget_get_style_context widget cr 0.0 0.0  as float! size/x as float! size/y
		;cairo_restore cr
	]

	if TYPE_OF(img) = TYPE_IMAGE [
		;; DEBUG: print ["base-draw, GDK-draw-image: " 0 "x" 0 "x" size/x "x" size/y lf]
		;; ONLY WORK for Mandelbrot and raytracer:
		;; GDK-draw-image cr OS-image/to-argb-pixbuf img 0 0 size/x size/y
		GDK-draw-image cr OS-image/to-pixbuf img 0 0 size/x size/y
	]

	case [
		sym = base [render-text cr size vals]
		sym = rich-text [
			;; DEBUG: print ["base-draw (rich-text)" widget " face " get-face-obj widget lf]
			pos/x: 0 pos/y: 0
			init-draw-ctx :DC cr
			draw-text-box :DC :pos get-face-obj widget yes
		]
		true []
	]

	either TYPE_OF(draw) = TYPE_BLOCK [
		;; DEBUG: print ["do-draw in base-draw" lf]
		do-draw cr null draw no yes yes yes
	][
		;; DEBUG: print ["base-draw: draw not a block" lf]
		system/thrown: 0
		drawDC: declare draw-ctx!								;@@ should declare it on stack
		draw-begin drawDC cr null no no
		integer/make-at as red-value! draw as-integer drawDC
		make-event widget 0 EVT_DRAWING
		draw/header: TYPE_NONE
		draw-end drawDC cr no no no
	]
	;; DEBUG: print ["base-draw " widget lf]

	false
]

window-delete-event: func [
	[cdecl]
	widget		[handle!]
	return:		[logic!]
][
	;; DEBUG: print ["window-delete-event" lf]
	make-event widget 0 EVT_CLOSE
	no
]

; window-destroy: func [
; 	[cdecl]
; 	widget	[handle!]
; ][
; 	;; DEBUG: print ["window-destroy" lf]
; 	;;remove-all-timers widget
; 	make-event widget 0 EVT_CLOSE
; ]

window-removed-event: func [
	[cdecl]
	app			[handle!]
	widget		[handle!]
	count		[int-ptr!]
][
	;; DEBUG[view/no-wait]: print ["App " app " removed window " widget "exit-loop: " exit-loop " win-cnt: " win-cnt " main-window? " main-window = widget]
	unless view-no-wait? widget [count/value: count/value - 1]
	;; DEBUG[view/no-wait]: print ["=> exit-loop: " count/value lf]
]

window-event:  func [
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
		vals	[red-value!]
		val		[float!]
		size	[red-pair!]
		;	type  [red-word!]
		pos		[red-float!]
		;	sym   [integer!]
		max		[float!]
][
	; This event happens on GtkRange widgets including GtkScale.
	; Will any other widget need this?
	vals: get-face-values widget
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

; Do not use key-press-event since character would not be printed!
key-press-event: func [
	[cdecl]
	evbox		[handle!]
	event-key	[GdkEventKey!]
	widget		[handle!]
	return:		[integer!]
	/local
		res		[integer!]
		key		[integer!]
		flags	[integer!]
		text	[c-string!]
		face	[red-object!]
		qdata	[handle!]
][
	;; DEBUG: print ["key-press-event: " event-key/keyval lf]
	if event-key/keyval > FFFFh [return EVT_DISPATCH]
	key: translate-key event-key/keyval
	flags: 0 ;either char-key? as-byte key [0][80000000h]	;-- special key or not
	flags: flags or check-extra-keys event-key/state

	;; DEBUG: print ["key: " key " flags: " flags " key or flags: " key or flags lf]

	res: make-event widget key or flags EVT_KEY_DOWN
	;; DEBUG: print ["field press res " res lf]
	if res <> EVT_NO_DISPATCH [
		;; DEBUG: print ["special-key=" special-key " key=" key lf]
		either special-key <> -1 [
			switch key and FFFFh [
				RED_VK_SHIFT	RED_VK_CONTROL
				RED_VK_LSHIFT	RED_VK_RSHIFT
				RED_VK_LCONTROL	RED_VK_RCONTROL
				RED_VK_LMENU	RED_VK_RMENU
				RED_VK_UNKNOWN [0]				 ;-- no KEY event
				default  [res: make-event widget key or flags EVT_KEY] ;-- force a KEY event
			]
		][res: make-event widget key or flags EVT_KEY]
	]
	;; DEBUG: print ["key-press end" lf]
	res
]

key-release-event: func [
	[cdecl]
	evbox		[handle!]
	event-key	[GdkEventKey!]
	widget		[handle!]
	return:		[integer!]
	/local
		key		[integer!]
		flags	[integer!]
][
	if event-key/keyval > FFFFh [return EVT_DISPATCH]
	key: translate-key event-key/keyval
	flags: 0 ;either char-key? as-byte key [0][80000000h]	;-- special key or not
	flags: flags or check-extra-keys event-key/state
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
][
	make-event widget 0 EVT_FOCUS
]

focus-out-event: func [
	[cdecl]
	evbox		[handle!]
	event		[handle!]
	widget		[handle!]
][
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
	self	[handle!]
	return: [integer!]
	/local
		timer	[int-ptr!]
][
	; timer: get-widget-timer self
	; either null? timer [
	;either null? main-window [no]
	;[
	 	make-event self 0 EVT_TIME
	 	1
	;];[
	; 	print ["timer for widget " self " will stop!" lf]
	; 	remove-widget-timer self
	; 	no ; this removes the timer
	; ]
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
	;; DEBUG: print [ "ENTER: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]

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
	;; DEBUG: print [ "LEAVE: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
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
	;; DEBUG: print [ "mouse -> BUTTON-PRESS: " widget " ("  ") x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root " drag? " draggable? widget lf]
	; evt-motion/state: yes
	; evt-motion/cpt: 0
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
		res		[integer!]
		offset	[red-pair!]
		x		[float!]
		y		[float!]
		wflags	[integer!]
		flags	[integer!]
][
	;; DEBUG: print [ "mouse -> MOTION: " widget " x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root " drag? " draggable? widget lf]
	res: EVT_DISPATCH
	evt-motion/x_new: as-integer event/x
	evt-motion/y_new: as-integer event/y
	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	wflags: get-flags (as red-block! get-face-values widget) + FACE_OBJ_FLAGS
	if wflags and FACET_FLAGS_ALL_OVER <> 0 [
		flags: check-flags event/type event/state
		res: make-event widget flags EVT_OVER
	]
	;; DEBUG: print ["mouse-motion-notify-event:  down? " (event/state and GDK_BUTTON1_MASK <> 0) " " (flags and EVT_FLAG_DOWN <> 0) lf]
	res
]

menu-item-activate: func [
	[cdecl]
	item		[handle!]
	widget		[handle!]
	/local
		key		[integer!]
][
	key: menu-item-key? item
	;; DEBUG: print ["menu-item activated: " item " with key: " key " on widget " widget  lf]
	make-event widget key EVT_MENU
]

widget-scroll-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventScroll!]
	widget		[handle!]
	return:		[integer!]
	/local
		res	[integer!]
][
	;; DEBUG: print ["scroll-event: " event/direction " " event/delta_x " " event/delta_y lf]
	res: EVT_DISPATCH
	g_object_set_qdata widget red-event-id as handle! event
	if any[event/delta_y < -0.01 event/delta_y > 0.01][
		res: make-event widget check-down-flags event/state EVT_WHEEL
	]
	res
]
