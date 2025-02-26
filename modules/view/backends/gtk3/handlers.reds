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

vbar-value-changed: func [
	[cdecl]
	adj			[handle!]
	widget		[handle!]
	/local
		sc		[node!]
		pos		[integer!]
		values	[red-value!]
		min		[red-integer!]
		max		[red-integer!]
		page	[red-integer!]
		range	[integer!]
		lower	[float!]
		upper	[float!]
		v		[float!]
		pg		[float!]
		bar		[handle!]
		dir		[integer!]
][
	sc: GET-CONTAINER(adj)
	if sc <> null [
		values: get-node-values sc

		min:	as red-integer! values + SCROLLER_OBJ_MIN
		max:	as red-integer! values + SCROLLER_OBJ_MAX
		page:	as red-integer! values + SCROLLER_OBJ_PAGE
		range:	max/value - page/value - min/value + 1

		v: gtk_adjustment_get_value adj
		lower: gtk_adjustment_get_lower adj
		upper: gtk_adjustment_get_upper adj
		pg: gtk_adjustment_get_page_size adj
		pg: upper - lower - pg

		v: v / pg * (as float! range)
		v: v + as float! min/value
		pos: as-integer v		
		pos: pos << 4

		bar: gtk_scrollable_get_hadjustment widget
		dir: as-integer bar = adj
		SET-IN-LOOP(widget sc)
		make-event widget dir << 3 or 2 or pos EVT_SCROLL
		SET-IN-LOOP(widget null)
	]
]

scroller-value-changed: func [
	[cdecl]
	adj			[handle!]
	widget		[handle!]
	/local
		values	[red-value!]
		pos		[integer!]
][
	values: get-face-values widget
	pos: as-integer gtk_adjustment_get_value adj
	pos: pos << 4

	make-event widget 2 or pos EVT_SCROLL
]

button-toggled: func [
	[cdecl]
	evbox  [handle!]
	button [handle!]
	/local
		values	 [red-value!]
		bool	 [red-logic!]
		type	 [red-word!]
		flags	 [integer!]
		sym		 [integer!]
		tri?	 [logic!]
		toggled? [logic!]
		mixed?   [logic!]
][
	values: get-face-values button
	bool:   as red-logic! values + FACE_OBJ_DATA
	type:   as red-word! values + FACE_OBJ_TYPE
	flags:  get-flags as red-block! values + FACE_OBJ_FLAGS
	
	sym:  symbol/resolve type/symbol
	tri?: flags and FACET_FLAGS_TRISTATE <> 0
	toggled?: gtk_toggle_button_get_active button
		
	either all [sym = check tri?][
		mixed?: gtk_toggle_button_get_inconsistent button
		if toggled? [
			gtk_toggle_button_set_inconsistent button not mixed?			;-- flip on each toggle
			unless mixed? [													;--		 N		 Y
				g_signal_handlers_block_by_func(evbox :button-toggled button)
				gtk_toggle_button_set_active button no						;--  |--- emulate ---^
				g_signal_handlers_unblock_by_func(evbox :button-toggled button)
				bool/header: TYPE_NONE
			]
		]
	][
		bool/header: TYPE_LOGIC
		bool/value:  toggled?
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
		pt		[red-point2D!]
		sx sy	[integer!]
][
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [exit]

	color: as red-tuple! values + FACE_OBJ_COLOR
	font: as red-object! values + FACE_OBJ_FONT
	either all [
		font <> null
		TYPE_OF(font) = TYPE_OBJECT
	][
		attrs: create-pango-attrs face font
		new?: yes
	][
		new?: no
		attrs: default-attrs
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

	GET_PAIR_XY_INT(size sx sy)
	case [
		hsym = _para/center [x: (as-float (sx - lx)) / 2.0]
		hsym = _para/right [x: as-float (sx - lx)]
		true [x: 0.0]
	]
	case [
		vsym = _para/middle [y: (as-float (sy - ly)) / 2.0]
		vsym = _para/bottom [y: as-float (sy - ly)]
		true [y: 0.0]
	]

	cairo_move_to cr x y
	pango_cairo_show_layout cr layout
	cairo_stroke cr
	cairo_restore cr
	if new? [
		pango_attr_list_unref attrs
	]
	g_object_unref layout
]

base-draw: func [
	[cdecl]
	evbox		[handle!]
	draw-cr		[handle!]
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
		bool	[red-logic!]
		sym		[integer!]
		pos		[red-pair! value]
		drawDC	[draw-ctx!]
		css		[GString!]
		buf		[handle!]
		cr		[handle!]
		pt		[red-point2D!]
		sx sy	[integer!]
][
	face: get-face-obj widget
	values: object/get-values face
	img:  as red-image! values + FACE_OBJ_IMAGE
	draw: as red-block! values + FACE_OBJ_DRAW
	size: as red-pair! values + FACE_OBJ_SIZE
	type: as red-word! values + FACE_OBJ_TYPE
	font: as red-object! values + FACE_OBJ_FONT
	color: as red-tuple! values + FACE_OBJ_COLOR
	bool: as red-logic! values + FACE_OBJ_ENABLED?
	sym: symbol/resolve type/symbol
	if all [
		sym = base
		not bool/value
	][return EVT_DISPATCH]

	GET_PAIR_XY_INT(size sx sy)
	cr: draw-cr
	buf: null
	either all [
		TYPE_OF(color) = TYPE_TUPLE
		not all [
			TUPLE_SIZE?(color) = 4
			color/array1 and FF000000h = FF000000h
		]
	][
		gtk_render_background
				gtk_widget_get_style_context widget
				cr
				0.0 0.0
				as float! sx as float! sy
	][
		if sym = base [
			buf: GET-BASE-BUFFER(widget)
			assert buf <> null
			cr: cairo_create buf
			cairo_set_operator cr CAIRO_OPERATOR_CLEAR	;-- make it fully transparent
			cairo_paint cr
			cairo_set_operator cr CAIRO_OPERATOR_OVER
		]
	]

	if TYPE_OF(img) = TYPE_IMAGE [
		GDK-draw-image null cr OS-image/to-pixbuf img 0 0 sx sy
	]

	case [
		sym = base [render-text cr face size values]
		sym = rich-text [
			pos/header: TYPE_PAIR
			pos/x: 0 pos/y: 0
			draw-text-box cr :pos get-face-obj widget yes
		]
		true []
	]

	either TYPE_OF(draw) = TYPE_BLOCK [
		do-draw cr null draw no yes no yes
	][
		system/thrown: 0
		drawDC: declare draw-ctx!								;@@ should declare it on stack
		draw-begin drawDC cr null no no
		g_object_set_qdata widget draw-ctx-id as int-ptr! drawDC
		make-event widget 0 EVT_DRAWING
		draw-end drawDC cr no no no
	]

	if buf <> null [
		cairo_set_source_surface draw-cr buf 0.0 0.0
		cairo_paint draw-cr
		cairo_destroy cr
	]

	EVT_DISPATCH
]

camera-draw: func [
	[cdecl]
	evbox		[handle!]
	cr			[handle!]
	widget		[handle!]
	return:		[integer!]
	/local
		cfg		[integer!]
		data	[integer!]
		dlen	[integer!]
		pixbuf	[handle!]
		last	[handle!]
][
	cfg: as integer! GET-CAMERA-CFG(widget)
	last: GET-CAMERA-IMG(widget)
	pixbuf: null
	if all [
		cfg <> 0
		0 = camera-dev/trylock cfg
	][
		data: 0
		dlen: 0
		camera-dev/get-data cfg :data :dlen
		if dlen <> 0 [
			;-- now precess data
			pixbuf: camera-dev/get-pixbuf cfg
			gdk_cairo_set_source_pixbuf cr pixbuf 0.0 0.0
			cairo_paint cr
			camera-dev/signal cfg
		]
		camera-dev/unlock cfg
	]
	either null? pixbuf [
		unless null? last [
			gdk_cairo_set_source_pixbuf cr last 0.0 0.0
			cairo_paint cr
		]
	][
		unless null? last [
			g_object_unref last
		]
		SET-CAMERA-IMG(widget pixbuf)
	]
	EVT_DISPATCH
]

camera-cb: func [
	cfg			[integer!]
	/local
		widget	[handle!]
][
	widget: camera-dev/get-widget cfg
	gtk_widget_queue_draw widget
]

transparent-base?: func [
	color	[red-tuple!]
	return: [logic!]
][
	either all [
		TYPE_OF(color) = TYPE_TUPLE
		any [
			TUPLE_SIZE?(color) = 3 
			color/array1 and FF000000h <> FF000000h
		]
	][false][true]
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
		offset	[red-point2D!]
		size	[red-pair!]
		parent	[red-object!]
		sym		[integer!]
		hparent	[handle!]
		pane	[red-block!]
		head	[red-object!]
		tail	[red-object!]
		target	[handle!]
		offset2	[red-point2D!]
		size2	[red-pair!]
		x dx w	[float!]
		y dy h	[float!]
		scroll	[GdkEventScroll!]
		motion	[GdkEventMotion!]
		button	[GdkEventButton!]
		key		[GdkEventKey!]
		win		[handle!]
		pt		[red-point2D!]
		sx sy	[float32!]
		sx2 sy2 [float32!]
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
		etype = GDK_SCROLL
	][exit]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	color: as red-tuple! values + FACE_OBJ_COLOR
	offset: as red-point2D! values + FACE_OBJ_OFFSET
	size: as red-pair! values + FACE_OBJ_SIZE
	parent: as red-object! values + FACE_OBJ_PARENT
	sym: symbol/resolve type/symbol

	if all [
		sym = base
		transparent-base? color
	][
		GET_PAIR_XY(size sx sy)
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
					offset2: as red-point2D! (object/get-values tail) + FACE_OBJ_OFFSET
					size2: as red-pair! (object/get-values tail) + FACE_OBJ_SIZE
					GET_PAIR_XY(size2 sx2 sy2)
					unless all [
						offset/x + sx > offset2/x
						offset2/x + sx2 > offset/x
						offset/y + sy > offset2/y
						offset2/y + sy2 > offset/y
					][continue]
					case [
						etype = GDK_SCROLL [
							scroll: as GdkEventScroll! event
							dx: as float! offset/x - offset2/x
							dy: as float! offset/y - offset2/y
							w: as float! sx2
							h: as float! sy2
							x: scroll/x + dx
							y: scroll/y + dy
							if any [x < 0.0 y < 0.0 x > w y > h][continue]
							scroll/x: x
							scroll/y: y
							scroll/x_root: scroll/x_root + dx
							scroll/y_root: scroll/y_root + dy
							gtk_widget_event target as handle! event
							SET-RESEND-EVENT(target target)
						]
						etype = GDK_MOTION_NOTIFY [
							motion: as GdkEventMotion! event
							dx: as float! offset/x - offset2/x
							dy: as float! offset/y - offset2/y
							w: as float! sx2
							h: as float! sy2
							x: motion/x + dx
							y: motion/y + dy
							if any [x < 0.0 y < 0.0 x > w y > h][continue]
							motion/x: x
							motion/y: y
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
							w: as float! sx2
							h: as float! sy2
							x: button/x + dx
							y: button/y + dy
							if any [x < 0.0 y < 0.0 x > w y > h][continue]
							button/x: x
							button/y: y
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

im-commit: func [
	[cdecl]
	ctx			[handle!]
	str			[c-string!]
	widget		[handle!]
	/local
		cp		[integer!]
		cnt		[integer!]
][
	;probe ["commit " length? str]
	im-preedit?: no
	special-key: 0
	while [str/1 <> null-byte][
		cnt: unicode/utf8-char-size? as-integer str/1
		cp: unicode/decode-utf8-char str :cnt
		unicode-cp: cp
		make-event widget cp EVT_KEY
		str: str + cnt
	]
]

im-preedit-start: func [
	[cdecl]
	ctx			[handle!]
	widget		[handle!]
][
	;print-line "preedit start"
	im-preedit?: yes
]

im-preedit-changed: func [
	[cdecl]
	ctx			[handle!]
	widget		[handle!]
	/local
		pstr	[integer!]
][
	;print-line "preedit changed"
	if im-preedit? [
		pstr: 0
		gtk_im_context_get_preedit_string ctx :pstr null null
		make-event widget pstr EVT_IME
		g_free as handle! pstr
	]
]

im-retrieve-surrounding: func [
	[cdecl]
	ctx			[handle!]
	widget		[handle!]
][
	print-line "retrieve"
	true
]

im-delete-surrounding: func [
	[cdecl]
	ctx			[handle!]
	offset		[integer!]
	chars		[integer!]
	widget		[handle!]
][
	print-line ["delet: " offset "x" chars]
	true
]

window-delete-event: func [
	[cdecl]
	widget		[handle!]
	return:		[integer!]
][
	make-event widget 0 EVT_CLOSE
]

window-configure-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventConfigure!]
	widget		[handle!]
	return:		[integer!]
	/local
		x		[integer!]
		y		[integer!]
		offset	[red-pair!]
][
	x: 0 y: 0
	gtk_window_get_position widget :x :y
	offset: (as red-pair! get-face-values widget) + FACE_OBJ_OFFSET
	offset/x: x
	offset/y: y
	unless null? GET-STARTRESIZE(widget) [
		SET-RESIZING(widget widget)
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
		cont	[handle!]
		w		[integer!]
		h		[integer!]
][
	sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE
	if null? GET-STARTRESIZE(widget) [
		SET-STARTRESIZE(widget widget)
	]

	unless null? GET-HMENU(widget) [
		cont: GET-CONTAINER(widget)
		w: gtk_widget_get_allocated_width cont
		h: gtk_widget_get_allocated_height cont
		SET-CONTAINER-W(widget w)
		SET-CONTAINER-H(widget h)
	]

	if any [
		sz/x <> rect/width
		sz/y <> rect/height
	][
		sz/x: rect/width
		sz/y: rect/height
		if null? GET-PAIR-SIZE(widget) [
			as-point2D sz
		]
		either null? GET-RESIZING(widget) [
			make-event widget 0 EVT_SIZE
		][
			make-event widget 0 EVT_SIZING
		]
	]
	window-ready?: yes
]

widget-realize: func [
	[cdecl]
	evbox		[handle!]
	widget		[handle!]
	/local
		cursor	[handle!]
		win		[handle!]
		parent	[handle!]
		im		[handle!]
][
	cursor: GET-CURSOR(widget)
	unless null? cursor [
		win: gtk_widget_get_window widget
		if null? win [
			parent: gtk_widget_get_parent widget
			win: gtk_widget_get_window parent
		]
		gdk_window_set_cursor win cursor
	]
	im: GET-IM-CONTEXT(widget)
	unless null? im [
		win: gtk_widget_get_window widget
		gtk_im_context_set_client_window im win
	]
]

widget-unrealize: func [
	[cdecl]
	evbox		[handle!]
	widget		[handle!]
	/local
		im		[handle!]
][
	im: GET-IM-CONTEXT(widget)
	gtk_im_context_set_client_window im null
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
		set-selected widget face/ctx idx + 1
		res: make-event widget idx + 1 EVT_SELECT
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

reset-im-context: func [ctx [handle!]][
	if im-need-reset? [
		im-need-reset?: false
		gtk_im_context_reset ctx
	]
]

translate-key: func [
	keycode		[integer!]
	return:		[integer!]
	/local
		pos		[integer!]
][
	if all [
		keycode >= 20h
		keycode <= 7Fh
	][
		pos: keycode - 20h + 1
		return keycode-ascii/pos
	]
	if all [
		keycode >= FF00h
		keycode <= FFFFh
	][
		pos: keycode - FF00h + 1
		return keycode-special/pos
	]
	;-- simple fix #4267
	if keycode = FE20h [
		return RED_VK_TAB
	]
	RED_VK_UNKNOWN
]

convert-numpad-key: func [
	vkey	[integer!]
	return: [integer!]
][
	as-integer switch vkey [
		RED_VK_NUMPAD0	 [#"0"]
		RED_VK_NUMPAD1	 [#"1"]
		RED_VK_NUMPAD2	 [#"2"]
		RED_VK_NUMPAD3	 [#"3"]
		RED_VK_NUMPAD4	 [#"4"]
		RED_VK_NUMPAD5	 [#"5"]
		RED_VK_NUMPAD6	 [#"6"]
		RED_VK_NUMPAD7	 [#"7"]
		RED_VK_NUMPAD8	 [#"8"]
		RED_VK_NUMPAD9	 [#"9"]
		RED_VK_MULTIPLY	 [#"*"]
		RED_VK_ADD		 [#"+"]
		RED_VK_SEPARATOR [#","]
		RED_VK_SUBTRACT	 [#"-"]
		RED_VK_DECIMAL	 [#"."]
		RED_VK_DIVIDE	 [#"/"]
		default			 [vkey]
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
		im		[handle!]
		done?	[logic!]
][
	;probe ["key pressed " evbox " " widget]
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	either sym <> rich-text [
		either null? GET-RESEND-EVENT(evbox) [
			win: gtk_get_event_widget as handle! event-key
			unless g_type_check_instance_is_a win gtk_window_get_type [
				return EVT_DISPATCH
			]
			if evbox <> gtk_window_get_focus win [return EVT_NO_DISPATCH]
		][
			SET-RESEND-EVENT(evbox null)
		]
	][	;-- handles rich-text seperately
		im: GET-IM-CONTEXT(widget)
		if gtk_im_context_filter_keypress im event-key [
			im-need-reset?: yes
			return 1		;-- return TRUE
		]
		if im-preedit? [
			key: event-key/keyval
			if any [
				key = FF0Dh	;-- GDK_KEY_Return
				key = FF1Bh	;-- GDK_KEY_Escape
				key = FE34h	;-- GDK_KEY_ISO_Enter
				key = FF8Dh	;-- GDK_KEY_KP_Enter
			][reset-im-context im]
		]
	]

	key: translate-key event-key/keyval
	flags: check-extra-keys event-key/state
	special-key: either char-key? as-byte key [0][-1]		;-- special key or not
	if all [key >= 80h special-key = -1][
		flags: flags or special-key-to-flags key
	]
	key: convert-numpad-key key

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
		im		[handle!]
		done?	[logic!]
][
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	either sym <> rich-text [
		either null? GET-RESEND-EVENT(evbox) [
			win: gtk_get_event_widget as handle! event-key
			if evbox <> gtk_window_get_focus win [return EVT_NO_DISPATCH]
		][
			SET-RESEND-EVENT(evbox null)
		]
	][
		im: GET-IM-CONTEXT(widget)
		if gtk_im_context_filter_keypress im event-key [
			im-need-reset?: yes
			return 1		;-- return TRUE
		]
	]

	key: translate-key event-key/keyval
	flags: check-extra-keys event-key/state
	special-key: either char-key? as-byte key [0][-1]		;-- special key or not
	if all [key >= 80h special-key = -1][
		flags: flags or special-key-to-flags key
	]
	key: convert-numpad-key key
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
		size	[red-pair!]
		sym		[integer!]
		im		[handle!]
][
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	int: as red-integer! values + FACE_OBJ_SELECTED
	sym: symbol/resolve type/symbol
	if sym = window [
		if evbox <> gtk_get_event_widget event [return EVT_DISPATCH]
		unless null? GET-RESIZING(widget) [
			make-event widget 0 EVT_SIZING
			make-event widget 0 EVT_SIZE
		]
		SET-RESIZING(widget null)
		SET-STARTRESIZE(widget null)
		return EVT_DISPATCH
	]
	if sym = rich-text [
		im: GET-IM-CONTEXT(widget)
		;probe ["set-focus: " im]
		gtk_im_context_focus_in im
	]
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
		state	[red-value!]
		type	[red-word!]
		sym		[integer!]
		im		[handle!]
][
	face: get-face-obj widget
	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	if sym = window [
		return EVT_DISPATCH
	]
	if sym = rich-text [
		im: GET-IM-CONTEXT(widget)
		;probe ["unfocus: " im]
		gtk_im_context_focus_out im
	]
	state: values + FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_NONE [
		return EVT_DISPATCH
	]

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
	update-textview-tag buffer as handle! start as handle! end
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

has-buffer: func [
	widget		[handle!]
	return:		[logic!]
][
	null <> GET-BASE-BUFFER(widget)
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
	if any [
		evbox <> gtk_get_event_widget as handle! event
		evt-motion/pressed
	][
		return EVT_NO_DISPATCH
	]
	if has-buffer widget [return EVT_DISPATCH]
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
	if any [
		evbox <> gtk_get_event_widget as handle! event
		evt-motion/pressed
	][
		return EVT_NO_DISPATCH
	]
	if has-buffer widget [
		either null = GET-BASE-ENTER(widget) [
			return EVT_DISPATCH
		][
			SET-BASE-ENTER(widget null)
		]
	]
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
		buf		[handle!]
		start	[GtkTextIter! value]
		end		[GtkTextIter! value]
		flags	[integer!]
		pixels	[int-ptr!]
		ev w	[integer!]
][
	either null? GET-RESEND-EVENT(evbox) [
		if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	][
		SET-RESEND-EVENT(evbox null)
	]

	x: as-integer event/x
	y: as-integer event/y

	buf: GET-BASE-BUFFER(widget)
	if buf <> null [
		w: cairo_image_surface_get_width buf
		pixels: as int-ptr! cairo_image_surface_get_data buf
		pixels: pixels + (y * w) + x
		if pixels/1 and FF000000h = 0 [		;-- transparent pixel
			return EVT_DISPATCH
		]
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
		flags	[integer!]
		hMenu	[handle!]
		buf		[handle!]
		pixels	[int-ptr!]
		ev x y w [integer!]
][
	either null? GET-RESEND-EVENT(evbox) [
		if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	][
		SET-RESEND-EVENT(evbox null)
	]

	if event/button = GDK_BUTTON_PRIMARY [
		evt-motion/pressed: yes
	]

	x: as-integer event/x
	y: as-integer event/y

	buf: GET-BASE-BUFFER(widget)
	if buf <> null [
		w: cairo_image_surface_get_width buf
		pixels: as int-ptr! cairo_image_surface_get_data buf
		pixels: pixels + (y * w) + x
		if pixels/1 and FF000000h = 0 [		;-- transparent pixel
			return EVT_DISPATCH
		]
	]

	if event/button = GDK_BUTTON_SECONDARY [
		hMenu: GET-MENU-KEY(widget)
		unless null? hMenu [
			menu-x: x
			menu-y: y
			gtk_menu_popup_at_pointer hMenu as handle! event
			return EVT_NO_DISPATCH
		]
	]

	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	evt-motion/x_new: x
	evt-motion/y_new: y
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
		x		[integer!]
		y		[integer!]
		flags	[integer!]
		buf		[handle!]
		w		[integer!]
		pixels	[int-ptr!]
		enter	[handle!]
][
	either null? GET-RESEND-EVENT(evbox) [
		if evbox <> gtk_get_event_widget as handle! event [return EVT_NO_DISPATCH]
	][
		SET-RESEND-EVENT(evbox null)
	]

	x: as-integer event/x
	y: as-integer event/y
	evt-motion/x_new:  x
	evt-motion/y_new:  y
	evt-motion/x_root: event/x_root
	evt-motion/y_root: event/y_root
	flags: check-flags event/type event/state

	buf: GET-BASE-BUFFER(widget)
	if buf <> null [
		w: cairo_image_surface_get_width buf
		pixels: as int-ptr! cairo_image_surface_get_data buf
		pixels: pixels + (y * w) + x
		enter: GET-BASE-ENTER(widget)
		either pixels/1 and FF000000h = 0 [		;-- transparent pixel
			if enter <> null  [
				SET-BASE-ENTER(widget null)
				make-event widget flags or EVT_FLAG_AWAY EVT_OVER
			]
			return EVT_DISPATCH
		][
			if enter = null [
				SET-BASE-ENTER(widget widget)
				make-event widget flags EVT_OVER
				return EVT_DISPATCH
			]
		]
	]

	wflags: get-flags (as red-block! get-face-values widget) + FACE_OBJ_FLAGS
	if wflags and FACET_FLAGS_ALL_OVER = 0 [return EVT_DISPATCH]
	make-event widget flags EVT_OVER
]

widget-scroll-event: func [
	[cdecl]
	evbox		[handle!]
	event		[GdkEventScroll!]
	widget		[handle!]
	return:		[integer!]
][
	SET-RESEND-EVENT(evbox null)
	g_object_set_qdata widget red-event-id as handle! event
	if any [event/delta_y < -0.01 event/delta_y > 0.01 event/direction <> GDK_SCROLL_SMOOTH][
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
	if key <> 0 [
		make-event widget key EVT_MENU
	]
]

calendar-changed: func [
	[cdecl]
	evbox		[handle!]
	widget		[handle!]
	/local
		face	[red-object!]
		values	[red-value!]
		data	[red-value!]
		year	[integer!]
		month	[integer!]
		day		[integer!]
][
	face: get-face-obj widget
	values: object/get-values face
	data: as red-value! values + FACE_OBJ_DATA
	year: 0 month: 0 day: 0
	gtk_calendar_get_date widget :year :month :day
	date/make-at data year month + 1 day 0.0 0 0 no no
	make-event widget 0 EVT_CHANGE
]
