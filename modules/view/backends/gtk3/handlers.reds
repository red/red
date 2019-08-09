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
	size 	[red-pair!]
	values	[red-value!]
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
		lx 		[integer!]
		ly 		[integer!]
		rect	[tagRECT value]
		lrect	[tagRECT value]
		pline	[handle!]
		pc	 	[handle!]
		lpc		[handle!]
		fd 		[handle!]
][
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [exit]

	;; DEBUG: print ["render-text: " cr lf]
	para: as red-object! values + FACE_OBJ_PARA
	flags: either TYPE_OF(para) = TYPE_OBJECT [		;@@ TBD set alignment attribute
		get-para-flags base para
	][
		0005h										;-- center or middle
	]

	cairo_save cr

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
	;; DEBUG: print ["render-text " str " size: " size/x "x" size/y " flags: " flags lf]

	pango_layout_set_text lpc str -1
	cairo_set_source_rgba cr 0.0 0.0 0.0 0.5
	pango_cairo_update_layout cr lpc

	pline: pango_layout_get_line lpc 0
	pango_layout_line_get_pixel_extents pline rect lrect
	ly: (pango_layout_get_line_count lpc) * lrect/height 
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
		
	pango_cairo_show_layout cr lpc

	cairo_stroke cr
	cairo_restore cr

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
		DC		[draw-ctx! value]
		drawDC  [draw-ctx!]
][
	;; DEBUG: print ["base-draw " widget " " gtk_widget_get_allocated_width widget "x" gtk_widget_get_allocated_height widget lf]

	vals: get-node-values ctx
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
	;; DEBUG[view/no-wait]: print ["App " app " removed window " widget "exit-loop: " exit-loop " win-cnt: " win-cnt " main-window? " main-window = widget] 
	unless view-no-wait? widget [count/value: count/value - 1]
	;; DEBUG[view/no-wait]: print ["=> exit-loop: " count/value lf]
]

;; BUG: `vid.red` fails... back with window-size-allocate handler for resizing
window-configure-event: func [
	[cdecl]
	widget	[handle!]
	event	[GdkEventConfigure!]
	/local
		sz	 	[red-pair!]
		offset	[red-pair!]
		x 		[integer!]
		y 		[integer!]
][
	;;DEBUG: print [ "window-resizing " event/x "x" event/y " " event/width "x" event/height lf]
	
	; Set the offset when window is moved
	offset: (as red-pair! get-face-values widget) + FACE_OBJ_OFFSET
	x: 0 y: 0 gtk_window_get_position widget :x :y
	;; DEBUG: print ["offset: " x "x" y lf]
	offset/x: x offset/y: y

	sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE		;-- update face/size
	; either any [event/width <> sz/x event/height <> sz/y] [
	; 	;if 0 = (evt-motion/cpt % evt-motion/sensitiv) [
	; 		evt-motion/x_new: event/width 
	; 		evt-motion/y_new: event/height
	; 		evt-motion/x_root: as float! event/x
	; 		evt-motion/y_root: as float! event/y 
	; 		make-event widget 0 EVT_SIZE
	; 	;]
	; 	;evt-motion/cpt: evt-motion/cpt + 1
	; 	yes
	; ][no]
	if any [event/width <> sz/x event/height <> sz/y] [
		; evt-sizing/x_new: event/width 
		; evt-sizing/y_new: event/height
		; sz/x: evt-sizing/x_new
		; sz/y: evt-sizing/y_new
		; ;; DEBUG: print ["window-size-allocate: "  evt-sizing/x_root "x" evt-sizing/y_root  lf]
		; evt-sizing/x_root: as float! event/x
		; evt-sizing/y_root: as float! event/y
		make-event widget 0 EVT_SIZE
	]
]


window-size-allocate: func [
	[cdecl]
	widget	[handle!]
	rect	[tagRECT]
	/local
		sz	 [red-pair!]
][
	;; DEBUG: print ["window-size-allocate rect: " rect/x "x" rect/y "x" rect/width "x" rect/height     lf]
	sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE		;-- update face/size
	if any [rect/width <> sz/x rect/height <> sz/y] [
			evt-sizing/x_new: rect/width 
			evt-sizing/y_new: rect/height
			;; DEBUG: print ["sz: " sz/x "x" sz/y  " -> " evt-sizing/x_new "x" evt-sizing/y_new lf]
			sz/x: evt-sizing/x_new
			sz/y: evt-sizing/y_new
			;; DEBUG: print ["window-size-allocate: "  evt-sizing/x_root "x" evt-sizing/y_root  lf]
			evt-sizing/x_root: as float! rect/x
			evt-sizing/y_root: as float! rect/y
			make-event widget 0 EVT_SIZING
	] 
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

simple-button-press-event: func [
	[cdecl]
	_widget	[handle!]
	evt 	[handle!]
	widget	[handle!]
][
	make-event widget 0 EVT_LEFT_DOWN
]
simple-button-release-event: func [
	[cdecl]
	_widget	[handle!]
	evt 	[handle!]
	widget	[handle!]
][
	make-event widget 0 EVT_LEFT_UP
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
field-key-press-event: func [
	[cdecl]
	widget		[handle!]
	event-key	[GdkEventKey!]
	ctx			[node!]
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
	EVT_DISPATCH
]

field-key-release-event: func [
	[cdecl]
	widget		[handle!]
	event-key	[GdkEventKey!]
	ctx			[node!]
	return:		[integer!]
	/local
		res		[integer!]
		key		[integer!]
		flags	[integer!]
		text	[c-string!]
		face	[red-object!]
		qdata	[handle!]
][
	;; DEBUG: print "key-release: "
	;; DEBUG: print [ "keyval: " event-key/keyval  " -> " gdk_keyval_name event-key/keyval  "(" event-key/keyval  " -> " gdk_keyval_to_lower event-key/keyval ") et state: " event-key/state lf]
	;; DEBUG: print [ "keycode: " as integer! event-key/keycode1 " " as integer! event-key/keycode2 lf]

	text: gtk_entry_get_text widget
	qdata: g_object_get_qdata widget red-face-id
	;; DEBUG: print ["qdata: " qdata "text: " text lf]
    unless null? qdata [
        face: as red-object! qdata
		set-text widget face/ctx text
		make-event widget 0 EVT_CHANGE
	]
	make-event widget 0 EVT_KEY_UP
]

field-move-focus: func [
	[cdecl]
	widget	[handle!]
	event	[handle!]
	ctx		[node!] 
][
	print-line "move-focus"
]

field-button-release-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [integer!]
	/local	
		x			[integer!]
		y			[integer!]
		sel			[red-pair!]
][
	;; DEBUG: print [ "field  mouse -> BUTTON-RELEASE: " widget " x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
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
	make-event widget 0 EVT_LEFT_UP
	EVT_NO_DISPATCH
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

area-button-press-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [integer!]
	/local
		flags 		[integer!]
][
	;; DEBUG: print [ "area -> BUTTON-PRESS: " widget " x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	
	menu-x: as-integer event/x
	menu-y: as-integer event/y
	;; DEBUG: print ["menu cursor pos: " menu-x "x" menu-y lf]
	flags: check-flags event/type event/state
	make-event widget flags EVT_LEFT_DOWN
	0;;no
]

area-button-release-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [integer!]
	/local
		flags 		[integer!]
		buffer		[handle!]
		start		[GtkTextIter!]; value does not work
		end			[GtkTextIter!]		
		x			[integer!]
		y			[integer!]
		sel			[red-pair!]
][
	;; DEBUG: print [ "area  mouse -> BUTTON-RELEASE: " widget " x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	if event/button = GDK_BUTTON_PRIMARY [
		start: as GtkTextIter! allocate (size? GtkTextIter!) 
		end: as GtkTextIter! allocate (size? GtkTextIter!) 
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
		free as byte-ptr! start free as byte-ptr! end 
	]
	0
]

area-populate-popup: func [
	[cdecl]
	widget	[handle!]
	hMenu	[handle!]
	ctx 	[node!]
	/local
		menu	[red-block!]
][
	;; DEBUG: print ["populate menu for " widget " and menu " hMenu lf] 
	menu: as red-block! get-node-facet ctx FACE_OBJ_MENU
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
	widget 	[handle!] 
	event	[GdkEventCrossing!]
	ctx 	[node!]
	return: [integer!]
	/local
		flags 		[integer!]
][
	;; DEBUG: print [ "ENTER: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]

	flags: check-flags event/type event/state
	make-event widget flags EVT_OVER
	0;;no
]

widget-leave-notify-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventCrossing!]
	ctx 	[node!]
	return: [integer!]
	/local
		flags 		[integer!]
][
	;; DEBUG: print [ "LEAVE: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	flags: check-flags event/type event/state
	make-event widget flags or EVT_FLAG_AWAY EVT_OVER
	0;;no
]

drag-widget-motion-notify-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventMotion!]
	ctx 	[node!]
	return: [integer!]
	/local
		offset 	[red-pair!]
		x 		[float!]
		y 		[float!]
		flags 	[integer!]
		state	[integer!]

][
	state: 0
	;; DEBUG: print [ "DRAG MOTION: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	if evt-motion/state [
		if 0 = (evt-motion/cpt % evt-motion/sensitiv) [
			x:  event/x_root - evt-motion/x_root
			y:  event/y_root - evt-motion/y_root
			evt-motion/x_new: as-integer x + either x > 0.0 [0.5][-0.5] 
			evt-motion/y_new: as-integer y + either y > 0.0 [0.5][-0.5]
			;; DEBUG: print ["new " evt-motion/x_new "x" evt-motion/y_new lf]
			evt-motion/x_root: event/x_root
			evt-motion/y_root: event/y_root
			flags: check-flags event/type event/state
			state: make-event widget flags EVT_OVER
		]
		evt-motion/cpt: evt-motion/cpt + 1
		state: 1;;yes
	]
	state
]

drag-widget-button-press-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [integer!]
	/local
		offset 	[red-pair!]
		flags 	[integer!]
][
	;; DEBUG: print [ "DRAG BUTTON-PRESS: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	if any[
		event/button = GDK_BUTTON_PRIMARY
		event/button = GDK_BUTTON_SECONDARY
	][
		evt-motion/state: yes
		evt-motion/cpt: 0
		evt-motion/x_root: event/x_root
		evt-motion/y_root: event/y_root
		evt-motion/x_new: 0
		evt-motion/y_new: 0
	]
	flags: check-flags event/type event/state
	make-event widget flags case [event/button = GDK_BUTTON_SECONDARY [EVT_RIGHT_DOWN] event/button = GDK_BUTTON_MIDDLE [EVT_MIDDLE_DOWN] true [EVT_LEFT_DOWN]]
	1;;yes
]

drag-widget-button-release-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [integer!]
	/local
		type	[red-word!]
		sym		[integer!]
		state	[logic!]
		flags 	[integer!]
][
	;; DEBUG: print [ "Drag -> BUTTON-RELEASE: x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root lf]
	unless any[event/button = GDK_BUTTON_PRIMARY event/button = GDK_BUTTON_SECONDARY event/button = GDK_BUTTON_MIDDLE] [return 0]
	; Special treatment for check and radio buttons (TODO: button)
	type: as red-word! get-node-facet ctx FACE_OBJ_TYPE
	sym:	symbol/resolve type/symbol
	
	if all [
		any [sym = check sym = radio]
		evt-motion/cpt = 0					; IMPORTANT: change state only if no dragging! 
	][
		state: gtk_toggle_button_get_active widget
		gtk_toggle_button_set_active widget either sym = check [not state][yes]
	]

	evt-motion/state: no
	flags: check-flags event/type event/state
	make-event widget flags  case [event/button = GDK_BUTTON_SECONDARY [EVT_RIGHT_UP] event/button = GDK_BUTTON_MIDDLE [EVT_MIDDLE_UP] true [EVT_LEFT_UP]]
	EVT_NO_DISPATCH
]

container-emit-event: func [
	[cdecl]
	widget	[handle!]
	event	[int-ptr!]
	/local
		rect 		[tagRECT]
		evt			[GdkEventButton!]
		x 			[integer!]
		y 			[integer!]
][
	evt: as GdkEventButton! event
	x: as-integer evt/x y: as-integer evt/y
	rect: 	as tagRECT allocate (size? tagRECT)
	gtk_widget_get_allocation widget as handle! rect
	
	;; DEBUG: if evt/type = GDK_BUTTON_PRESS [print ["emit event " widget lf]]
	if all[x >= rect/x x <= (rect/x + rect/width) y >= rect/y y <= (rect/y + rect/height)][
		;; DEBUG: if evt/type = GDK_BUTTON_PRESS [print ["emit2 event " widget " event " evt/x "x" evt/y lf "widget size " rect/x "x" rect/y "x" rect/width "x" rect/height lf]]
		gtk_widget_event real-widget? widget event
	]
	free as byte-ptr! rect
]

container-delegate-to-children: func [
	[cdecl]
	widget 	[handle!] 
	event	[int-ptr!]
	ctx 	[node!]
	return: [integer!]
][
	;; DEBUG: print [ "parent -> CONTAINER DELEGATE: " widget lf]
	gtk_container_foreach widget as-integer :container-emit-event event
	EVT_DISPATCH
]

mouse-button-press-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [integer!]
	/local
		flags 		[integer!]
		hMenu		[handle!]
][
	;; DEBUG: print [ "mouse -> BUTTON-PRESS: " widget " ("  ") x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root " drag? " draggable? widget lf]
	; evt-motion/state: yes
	; evt-motion/cpt: 0
	
	if gtk_widget_get_focus_on_click widget [
		;; DEBUG: print ["grab focus on mouse " widget lf] 
		gtk_widget_grab_focus widget
	]
	if draggable? widget [return 0] ; delegate to drag

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
	make-event widget flags case [event/button = GDK_BUTTON_SECONDARY [EVT_RIGHT_DOWN] event/button = GDK_BUTTON_MIDDLE [EVT_MIDDLE_DOWN] true [EVT_LEFT_DOWN]]
	;; DEBUG: print ["NO DISPATCH" lf]
	EVT_NO_DISPATCH
]

mouse-button-release-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventButton!]
	ctx 	[node!]
	return: [integer!]
	/local
		flags 		[integer!]
][
	;; DEBUG: print [ "mouse -> BUTTON-RELEASE: " widget " x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root " drag? " draggable? widget lf]
	if draggable? widget [return 0] ; delegate to drag
	evt-motion/state: yes
	evt-motion/cpt: 0
	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	evt-motion/x_new: as-integer event/x
	evt-motion/y_new: as-integer event/y
	flags: check-flags event/type event/state 
	make-event widget flags case [event/button = GDK_BUTTON_SECONDARY [EVT_RIGHT_UP] event/button = GDK_BUTTON_MIDDLE [EVT_MIDDLE_UP] true [EVT_LEFT_UP]]
	;;0 ;;no
]

mouse-motion-notify-event: func [
	[cdecl]
	widget 	[handle!] 
	event	[GdkEventMotion!]
	ctx 	[node!]
	return: [integer!]
	/local
		offset 	[red-pair!]
		x 		[float!]
		y 		[float!]
		wflags	[integer!]
		flags	[integer!]
][
	;; DEBUG: print [ "mouse -> MOTION: " widget " x: " event/x " y: " event/y " x_root: " event/x_root " y_root: " event/y_root " drag? " draggable? widget lf]

	if draggable? widget [return EVT_DISPATCH] ; delegate to drag
	evt-motion/x_new: as-integer event/x
	evt-motion/y_new: as-integer event/y
	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	wflags: get-flags (as red-block! get-face-values widget) + FACE_OBJ_FLAGS
	if wflags and FACET_FLAGS_ALL_OVER <> 0 [
		flags: check-flags event/type event/state
		make-event widget flags EVT_OVER	 
	]
	;; DEBUG: print ["mouse-motion-notify-event:  down? " (event/state and GDK_BUTTON1_MASK <> 0) " " (flags and EVT_FLAG_DOWN <> 0) lf] 
	EVT_DISPATCH ;;no
]

key-press-event: func [
	[cdecl]
	widget		[handle!]
	event-key	[GdkEventKey!]
	ctx			[node!]
	return:		[integer!]
	/local
		state	[integer!]
		key		[integer!]
		flags	[integer!]
		text	[c-string!]
][

	;; DEBUG: print ["key-press-event: " event-key/keyval " " widget lf]
	state: 0
	either event-key/keyval > FFFFh [state: 1][
		key: translate-key event-key/keyval
		flags: 0 ;either char-key? as-byte key [0][80000000h]	;-- special key or not
		flags: flags or check-extra-keys event-key/state


		state: make-event widget key or flags EVT_KEY_DOWN
		unless state = EVT_NO_DISPATCH [
			state: make-event widget key or flags EVT_KEY
		]
	]
	state
]

key-release-event: func [
	[cdecl]
	widget		[handle!]
	event-key	[GdkEventKey!]
	ctx			[node!]
	return:		[integer!]
	/local
		state	[integer!]
		key		[integer!]
		flags	[integer!]
		text	[c-string!]
][
	;; DEBUG: print ["key-release-event: " event-key/keyval " " widget lf]
	state: 0
	either event-key/keyval > FFFFh [state: 1][
		key: translate-key event-key/keyval
		flags: 0 ;either char-key? as-byte key [0][80000000h]	;-- special key or not
		flags: flags or check-extra-keys event-key/state


		state: make-event widget key or flags EVT_KEY_UP
		unless state = EVT_NO_DISPATCH [
			state: make-event widget key or flags EVT_KEY
		]
	]
	state
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
	widget		[handle!]
	event		[GdkEventScroll!]
	ctx			[node!]
	return:		[integer!]
	/local
		state 	[integer!]
][
	;; DEBUG: print ["scroll-event: " event/direction " " event/delta_x " " event/delta_y lf]
	state: 0
	g_object_set_qdata widget red-event-id as handle! event
	if any[event/delta_y < -0.01 event/delta_y > 0.01][	
		state: make-event widget check-down-flags event/state EVT_WHEEL
	]
	state
]
