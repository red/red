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

render-text: func [
	cr		[handle!]
	values	[red-value!]
	;sz		[NSSize!]
	/local
		text	[red-string!]
		font	[red-object!]
		para	[red-object!]
		flags	[integer!]
		len      [integer!]
		str		[c-string!]
		line	[integer!]
		x		[float!]
		y		[float!]
		temp	[float!]
		;te		[cairo_text_extents_t!]
		;fe		[cairo_font_extents_t!]
		pc	 	[handle!]
		lpc		[handle!]
		fd 		[handle!]
][
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [exit]

	para: as red-object! values + FACE_OBJ_PARA
	flags: either TYPE_OF(para) = TYPE_OBJECT [		;@@ TBD set alignment attribute
		get-para-flags base para
	][
		2 or 4										;-- center
	]

	; The pango_cairo way
	pc: pango_cairo_create_context cr
	lpc: pango_cairo_create_layout cr

	font: as red-object! values + FACE_OBJ_FONT
	fd: font-description font
	pango_layout_set_font_description lpc fd
	if TYPE_OF(text) = TYPE_STRING [
		len: -1
		str: unicode/to-utf8 text :len
	]
	pango_layout_set_text lpc str -1
	cairo_set_source_rgba cr 0.0 0.0 0.0 0.5
	pango_cairo_update_layout cr lpc
	pango_cairo_show_layout cr lpc

; @@ The cairo way (alternative) does not work for me after too many attempt
; 	if TYPE_OF(text) = TYPE_STRING [
; 		len: -1
; 		str: unicode/to-utf8 text :len
; 		te: as cairo_text_extents_t! allocate (size? cairo_text_extents_t!)
; 		cairo_text_extents cr str as handle! te
; 		fe: as cairo_font_extents_t! allocate (size? cairo_font_extents_t!)
; 		cairo_font_extents cr as handle! fe
; 		x: 0.5 - te/x_bearing - (te/width / 2.0)
; 		y: 0.5 - fe/descent + (fe/height / 2.0)
; 		free as byte-ptr! te
; 		free as byte-ptr! fe
; 	]

; 	cairo_scale cr 170.0 40.0
; 	;set-source-color cr 0
; 	cairo_set_source_rgba cr 0.0 0.0 0.0 0.5

; 	font: as red-object! values + FACE_OBJ_FONT
; 	either TYPE_OF(font) = TYPE_OBJECT [
; 		  select-cairo-font cr font
; 	][
; 		0
; 	]

; 	;cairo_move_to(cr, w/2 - extents.width/2, h/2);
; 	cairo_move_to cr x y  
; print [ "hi-str: <" str ">" lf]
; 	cairo_show_text cr str 

]

base-draw: func [
	[cdecl]
	widget	[handle!]
	cr		[handle!]
	ctx		[node!]
	return: [logic!]
	/local
		vals 	[red-value!]
		draw 	[red-block!]
		clr  	[red-tuple!]
		img  	[red-image!]
		size	[red-pair!]
		type	[red-word!]
		sym		[integer!]
		pos		[red-pair! value]
][
	;; DEBUG: print ["base-draw " widget lf]

	vals: get-node-values ctx
	img:  as red-image! vals + FACE_OBJ_IMAGE
	draw: as red-block! vals + FACE_OBJ_DRAW
	clr:  as red-tuple! vals + FACE_OBJ_COLOR
	size: as red-pair! vals + FACE_OBJ_SIZE
	type: as red-word! vals + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	
	if TYPE_OF(clr) = TYPE_TUPLE [
		;print ["color" (clr/array1 and 00FFFFFFh) lf]
		set-source-color cr clr/array1
		cairo_paint cr								;-- paint background
	]

	if TYPE_OF(img) = TYPE_IMAGE [
		GDK-draw-image cr as handle! OS-image/to-pixbuf img 0 0 size/x size/y
	]

	case [
		sym = base [render-text cr vals]
		sym = rich-text [
			pos/x: 0 pos/y: 0
			;; TODO: draw-text-box null :pos get-face-obj self yes
		]
		true []
	]
	
	either TYPE_OF(draw) = TYPE_BLOCK [
		do-draw cr null draw no yes yes yes
	][
		; system/thrown: 0
		; DC: declare draw-ctx!								;@@ should declare it on stack
		; draw-begin DC ctx img no no
		; integer/make-at as red-value! draw as-integer DC
		make-event widget 0 EVT_DRAWING
		; draw/header: TYPE_NONE
		; draw-end DC ctx no no no
	]
	;; DEBUG: print ["base-draw " widget lf]

	false
]

window-delete-event: func [
	[cdecl]
	widget	[handle!]
	return: [logic!]
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
	app		[handle!]
	widget	[handle!]
	count	[int-ptr!]
][
	count/value: count/value - 1
]

window-configure-event: func [
	[cdecl]
	widget	[handle!]
	event	[GdkEventConfigure!]
	/local
		sz	 [red-pair!]
][
	;;DEBUG: print [ "window-resizing " event/x "x" event/y " " event/width "x" event/height lf]
	sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE		;-- update face/size
	if 5 < (((event/width - sz/x) * (event/width - sz/x)) + ((event/height - sz/y) * (event/height - sz/y))) [
		sz/x: event/width
		sz/y: event/height
		make-event widget 0 EVT_SIZING
		yes
	][no]
]


window-size-allocate: func [
	[cdecl]
	widget	[handle!]
	rect	[tagRECT]
	/local
		sz	 [red-pair!]
][
	;;DEBUG: 
	print [ "window-size-allocate " rect/width "x" rect/height lf]
	make-event widget 0 EVT_SIZING
	sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE		;-- update face/size
	sz/x: rect/width
	sz/y: rect/height
	;; DEBUG: print [ "window-size-allocate end " sz lf]
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

text-button-press-event: func [
	[cdecl]
	_widget	[handle!]
	evt 	[handle!]
	widget	[handle!]
][
	make-event widget 0 EVT_LEFT_DOWN
]

combo-selection-changed: func [
	[cdecl]
	widget	[handle!]
	ctx		[node!]
	/local
		idx [integer!]
		res [integer!]
		text [c-string!]
][
	idx: gtk_combo_box_get_active widget
	if idx >= 0 [
		res: make-event widget idx + 1 EVT_SELECT
		set-selected widget ctx idx + 1
		text: gtk_combo_box_text_get_active_text widget
		set-text widget ctx text
		if res = EVT_DISPATCH [
			make-event widget idx + 1 EVT_CHANGE
		]
	]
]

text-list-selected-rows-changed: func [
	[cdecl]
	widget	[handle!]
	ctx		[node!]
	/local
		idx [integer!]
		sel [handle!]
		res [integer!]
		text [c-string!]
][
	; From now, only single-selection mode
	sel: gtk_list_box_get_selected_row widget
	idx: either null? sel [-1][gtk_list_box_row_get_index sel]
	if idx >= 0 [
		res: make-event widget idx + 1 EVT_SELECT
		set-selected widget ctx idx + 1
		text: gtk_label_get_text gtk_bin_get_child sel
		set-text widget ctx text
		if res = EVT_DISPATCH [
			make-event widget idx + 1 EVT_CHANGE
		]
	]
]

tab-panel-switch-page: func [
	[cdecl]
	widget	[handle!]
	page	[handle!]
	idx		[integer!]
	ctx		[node!]
	/local
		res  [integer!]
		text [c-string!]
][
	if idx >= 0 [
		res: make-event widget idx + 1 EVT_SELECT
		set-selected widget ctx idx + 1
		text: gtk_notebook_get_tab_label_text widget page
		set-text widget ctx text
		if res = EVT_DISPATCH [
			make-event widget idx + 1 EVT_CHANGE
		]
	]
]

; Do not use key-press-event since character would not be printed!
field-key-release-event: func [
	[cdecl]
	widget		[handle!]
	event-key	[GdkEventKey!]
	ctx			[node!]
	/local
		res		[integer!]
		key		[integer!]
		flags	[integer!]
		text	[c-string!]
		face	[red-object!]
		qdata	[handle!]
][
	;print "key-release: "
	;print [ "keyval: " event-key/keyval  " -> " gdk_keyval_name event-key/keyval  "(" event-key/keyval  " -> " gdk_keyval_to_lower event-key/keyval ") et state: " event-key/state lf]
	;print [ "keycode: " as integer! event-key/keycode1 " " as integer! event-key/keycode2 lf]

	if event-key/keyval > FFFFh [exit]
	key: translate-key event-key/keyval
	flags: 0 ;either char-key? as-byte key [0][80000000h]	;-- special key or not
	flags: flags or check-extra-keys event-key/state

	;print ["key: " key " flags: " flags " key or flags: " key or flags lf]

	res: make-event widget key or flags EVT_KEY_DOWN
	if res <> EVT_NO_DISPATCH [
	 	make-event widget key or flags EVT_KEY
	]

	text: gtk_entry_get_text widget
	qdata: g_object_get_qdata widget red-face-id
    unless null? qdata [
        face: as red-object! qdata
		set-text widget face/ctx text
		make-event widget 0 EVT_CHANGE
	]
]

field-move-focus: func [
	[cdecl]
	widget	[handle!]
	event	[handle!]
	ctx		[node!] 
][
	print-line "move-focus"
]

area-changed: func [
	[cdecl]
	buffer	[handle!]
	widget	[handle!]
	/local
		text	[c-string!]
		face	[red-object!]
		qdata	[handle!]
		start	[GtkTextIter!]
		end		[GtkTextIter!]
][
	; Weirdly, GtkTextIter introduced since I did not simplest solution to get the full content of a GtkTextBuffer!
	start: as GtkTextIter! allocate (size? GtkTextIter!) 
	end: as GtkTextIter! allocate (size? GtkTextIter!) 
	gtk_text_buffer_get_bounds buffer as handle! start as handle! end
	text: gtk_text_buffer_get_text buffer as handle! start as handle! end no
	free as byte-ptr! start free as byte-ptr! end 
	qdata: g_object_get_qdata widget red-face-id
    unless null? qdata [
        face: as red-object! qdata
		set-text widget face/ctx text
		make-event widget 0 EVT_CHANGE
	]
]

red-timer-action: func [
	[cdecl]
	self	[handle!]
	return: [logic!]
	/local
		timer	[int-ptr!]
][
	; timer: get-widget-timer self
	; either null? timer [
	;either null? main-window [no]
	;[
	 	make-event self 0 EVT_TIME
	 	yes
	;];[
	; 	print ["timer for widget " self " will stop!" lf]
	; 	remove-widget-timer self
	; 	no ; this removes the timer
	; ]
]	

widget-enter-notify-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventCrossing!]
	ctx 	[node!]
	return: [logic!]
][
	;; DEBUG: print [ "ENTER: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	make-event widget 0 EVT_OVER
	no
]

widget-leave-notify-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventCrossing!]
	ctx 	[node!]
	return: [logic!]
][
	;; DEBUG: print [ "LEAVE: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	make-event widget EVT_FLAG_AWAY EVT_OVER
	no
]

drag-widget-motion-notify-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventMotion!]
	ctx 	[node!]
	return: [logic!]
	/local
		offset 	[red-pair!]
		x 		[float!]
		y 		[float!]
		; state 	[red-block!]
		; int 	[red-integer!]
		; s 		[series!]

][
	;; Drag -> DEBUG: print [ "MOTION: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	either motion/state [
		if 0 = (motion/cpt % motion/sensitiv) [
			x:  event/x_root - motion/x_root
			y:  event/y_root - motion/y_root
			motion/x_new: as-integer x + either x > 0.0 [0.5][-0.5] 
			motion/y_new: as-integer y + either y > 0.0 [0.5][-0.5]
			motion/x_root: event/x_root
			motion/y_root: event/y_root
			make-event widget 0 EVT_OVER
		]
		motion/cpt: motion/cpt + 1
		yes
	][no]
]

drag-widget-button-press-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [logic!]
	/local
		offset 	[red-pair!]
][
	;; Drag -> DEBUG: print [ "BUTTON-PRESS: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	motion/state: yes
	motion/cpt: 0
	motion/x_root: event/x_root
	motion/y_root: event/y_root
	motion/x_new: 0
	motion/y_new: 0
	make-event widget 0 EVT_LEFT_DOWN
	yes
]

drag-widget-button-release-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [logic!]
	/local
		type	[red-word!]
		sym		[integer!]
		state	[logic!]
][
	; print [ "Drag -> BUTTON-RELEASE: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	
	; Special treatment for check and radio buttons (TODO: button)
	type: as red-word! get-node-facet ctx FACE_OBJ_TYPE
	sym:	symbol/resolve type/symbol
	
	if all [
		any [sym = check sym = radio]
		motion/cpt = 0					; IMPORTANT: change state only if no dragging! 
	][
		state: gtk_toggle_button_get_active widget
		gtk_toggle_button_set_active widget either sym = check [not state][yes]
	]

	motion/state: no
	make-event widget 0 EVT_LEFT_UP
	yes
]

mouse-button-press-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [logic!]
][
	;; DEBUG: print [ "mouse -> BUTTON-PRESS: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	; motion/state: yes
	; motion/cpt: 0
	motion/x_root: event/x_root
	motion/y_root: event/y_root
	motion/x_new: as-integer event/x
	motion/y_new: as-integer event/y
	make-event widget 0 EVT_LEFT_DOWN
	yes
]

mouse-button-release-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [logic!]
][
	;; DEBUG: print [ "mouse -> BUTTON-RELEASE: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	motion/state: yes
	motion/cpt: 0
	motion/x_root: event/x_root
	motion/y_root: event/y_root
	motion/x_new: as-integer event/x
	motion/y_new: as-integer event/y
	make-event widget 0 EVT_LEFT_UP
	yes
]

mouse-motion-notify-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventMotion!]
	ctx 	[node!]
	return: [logic!]
	/local
		offset 	[red-pair!]
		x 		[float!]
		y 		[float!]
		; state 	[red-block!]
		; int 	[red-integer!]
		; s 		[series!]

][
	;; DEBUG: print [ "mouse -> MOTION: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	motion/x_new: as-integer event/x
	motion/y_new: as-integer event/y
	motion/x_root: event/x_root
	motion/y_root: event/y_root
	make-event widget 0 EVT_OVER	 
	yes
]

key-press-event: func [
	[cdecl]
	widget		[handle!]
	event-key	[GdkEventKey!]
	ctx			[node!]
	;return:		[logic!]
	/local
		res		[integer!]
		key		[integer!]
		flags	[integer!]
		text	[c-string!]
][

	;; DEBUG: print ["key-press-event: " event-key/keyval lf]

	if event-key/keyval > FFFFh [exit];return yes]
	key: translate-key event-key/keyval
	flags: 0 ;either char-key? as-byte key [0][80000000h]	;-- special key or not
	flags: flags or check-extra-keys event-key/state


	res: make-event widget key or flags EVT_KEY_DOWN
	either res = EVT_NO_DISPATCH [yes][
	 	make-event widget key or flags EVT_KEY
		no
	]
]

key-release-event: func [
	[cdecl]
	widget		[handle!]
	event-key	[GdkEventKey!]
	ctx			[node!]
	;return:		[logic!]
	/local
		res		[integer!]
		key		[integer!]
		flags	[integer!]
		text	[c-string!]
][
	;; DEBUG: print ["key-release-event: " event-key/keyval lf]

	if event-key/keyval > FFFFh [exit];return yes]
	key: translate-key event-key/keyval
	flags: 0 ;either char-key? as-byte key [0][80000000h]	;-- special key or not
	flags: flags or check-extra-keys event-key/state


	res: make-event widget key or flags EVT_KEY_UP
	either res = EVT_NO_DISPATCH [yes][
	 	make-event widget key or flags EVT_KEY
		no
	]
	
]
