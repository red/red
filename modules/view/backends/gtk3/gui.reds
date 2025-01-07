Red/System [
	Title:	"GTK3 GUI backend"
	Author: "Qingtian Xie, RCqls, Thiago Dourado de Andrade"
	File: 	%gui.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %gtk.reds
#include %events.reds

#include %css.reds
#include %color.reds
#include %font.reds
#include %para.reds
#include %draw.reds

#include %menu.reds
#include %handlers.reds
#include %comdlgs.reds
#include %tab-panel.reds
#include %text-list.reds
#include %camera.reds

unicode-cp:			0
im-preedit?:		no
im-need-reset?:		no
window-ready?:		no
force-redraw?:		no
settings:			as handle! 0
pango-context:		as handle! 0
default-font-name:	as c-string! 0
default-font-size:	0
default-font-color: 0
default-font-width: as float32! 7.5		;-- pixel width
gtk-font-name:		"Sans"
gtk-font-size:		10

log-pixels-x:		0
log-pixels-y:		0
screen-size-x:		0
screen-size-y:		0

#define CHECK_FACE_SIZE(size x y) [
	if any [x > 65535 y > 65535][
		fire [TO_ERROR(script invalid-arg) size]
	]
]

get-face-obj: func [
	handle		[handle!]
	return:		[red-object!]
][
	as red-object! references/get as integer! g_object_get_qdata handle red-face-id
]

get-face-values: func [
	handle		[handle!]
	return:		[red-value!]
	/local
		values	[red-value!]
		face	[red-object!]
][
	values: as red-value! 0
	unless null? handle [
		face: get-face-obj handle
		unless null? face [
			values: object/get-values face
		]
	]
	values
]

get-node-values: func [
	node		[node!]
	return:		[red-value!]
	/local
		ctx		[red-context!]
		s		[series!]
][
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset
]

get-node-facet: func [
	node		[node!]
	facet		[integer!]
	return:		[red-value!]
	/local
		ctx		[red-context!]
		s		[series!]
][
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset + facet
]

get-face-flags: func [
	face		[handle!]
	return:		[integer!]
][
	0
]

face-handle?: func [
	face		[red-object!]
	return:		[handle!]									;-- returns NULL is no handle
	/local
		state	[red-block!]
		int		[red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		if TYPE_OF(int) = TYPE_HANDLE [return as handle! int/value]
	]
	null
]

get-face-handle: func [
	face		[red-object!]
	return:		[handle!]
	/local
		state	[red-block!]
		int		[red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	assert TYPE_OF(state) = TYPE_BLOCK
	int: as red-integer! block/rs-head state
	assert TYPE_OF(int) = TYPE_HANDLE
	as handle! int/value
]

get-widget-symbol: func [
	widget		[handle!]
	return:		[integer!]
	/local
		type	[red-word!]
		values	[red-value!]
][
	values: get-face-values widget
	type: as red-word! values + FACE_OBJ_TYPE
	symbol/resolve type/symbol
]

get-widget-data: func [
	widget		[handle!]
	return:		[red-block!]
	/local
		values	[red-value!]
][
	values: get-face-values widget
	as red-block! values + FACE_OBJ_DATA
]

get-face-parent: func [
	widget		[handle!]
	values		[red-value!]
	sym			[integer!]
	return:		[handle!]
	/local
		parent	[red-object!]
][
	if sym = window [return null]
	parent: as red-object! values + FACE_OBJ_PARENT
	get-face-handle parent
]

get-face-evbox: func [
	widget		[handle!]
	values		[red-value!]
	sym			[integer!]
	return:		[handle!]
][
	case [
		sym = text [
			gtk_widget_get_parent widget
		]
		true [
			widget
		]
	]
]

get-face-layout: func [
	widget		[handle!]
	sym			[integer!]
	return:		[handle!]
	/local
		h		[handle!]
][
	case [
		sym = rich-text [
			h: GET-CONTAINER(widget)
			if null? h [h: widget]
			h
		]
		any [
			sym = text
			sym = area
			sym = text-list
		][
			GET-CONTAINER(widget)
		]
		true [
			widget
		]
	]
]

get-face-child-layout: func [
	widget		[handle!]
	sym			[integer!]
	return:		[handle!]
][
	case [
		sym = window [
			GET-CONTAINER(widget)
		]
		sym = group-box [
			gtk_bin_get_child widget
		]
		true [
			widget
		]
	]
]

set-widget-child: func [
	parent		[handle!]
	widget		[handle!]
	offset		[red-pair!]
	return:		[logic!]
	/local
		sym		[integer!]
		x		[integer!]
		y		[integer!]
		cvalues	[red-value!]
		ctype	[red-word!]
		csym	[integer!]
		clayout	[handle!]
		playout	[handle!]
		pt		[red-point2D!]
][
	sym: get-widget-symbol parent
	GET_PAIR_XY_INT(offset x y)
	cvalues: get-face-values widget
	ctype: as red-word! cvalues + FACE_OBJ_TYPE
	csym: symbol/resolve ctype/symbol
	clayout: get-face-layout widget csym
	case [
		sym = window [
			playout: GET-CONTAINER(parent)
			gtk_layout_put playout clayout x y
			true
		]
		sym = group-box [
			playout: gtk_bin_get_child parent
			gtk_layout_put playout clayout x y
			true
		]
		any [
			sym = base
			sym = rich-text
			sym = panel
		][
			gtk_layout_put parent clayout x y
			true
		]
		sym = tab-panel [
			append-tab parent clayout
		]
		true [
			false
		]
	]
]

update-caret: func [
	ctx		[handle!]
	area	[GdkRectangle!]
][
	gtk_im_context_set_cursor_location ctx area
]

set-widget-offset: func [
	parent		[handle!]
	widget		[handle!]
	x			[integer!]
	y			[integer!]
][
	if g_type_check_instance_is_a parent gtk_layout_get_type [
		gtk_layout_move parent widget x y
		gtk_widget_queue_draw widget
	]
]

set-widget-child-offset: func [
	parent		[handle!]
	widget		[handle!]
	pos			[red-pair!]
	type		[integer!]
	/local
		im-ctx	[handle!]
		layout	[handle!]
		values	[red-value!]
		ntype	[red-word!]
		sym		[integer!]
		cparent	[handle!]
		alloc	[GtkAllocation! value]
		pt		[red-point2D!]
		x y		[integer!]
][
	GET_PAIR_XY_INT(pos x y)
	either type = window [
		gtk_window_move widget x y
	][
		values: get-face-values widget
		ntype: as red-word! values + FACE_OBJ_TYPE
		sym: symbol/resolve ntype/symbol
		layout: get-face-layout widget sym
		if layout <> widget [
			set-widget-offset layout widget 0 0
		]
		unless null? parent [
			values: get-face-values parent
			ntype: as red-word! values + FACE_OBJ_TYPE
			sym: symbol/resolve ntype/symbol
			cparent: get-face-child-layout parent sym
			set-widget-offset cparent layout x y
		]
		if type = base [
			layout: GET-CARET-OWNER(widget)
			if layout <> null [
				im-ctx: GET-IM-CONTEXT(layout)
				if im-ctx <> null [
					gtk_widget_get_allocation widget :alloc
					alloc/w: 0
					update-caret im-ctx as GdkRectangle! :alloc
				]
			]
		]
	]
]

set-scroller-pos: func [
	widget		[handle!]
	values		[red-value!]
	/local
		pos		[red-float!]
		sel		[red-float!]
		adj		[handle!]
		dividend [integer!]
][
	pos: as red-float! values + FACE_OBJ_DATA
	sel: as red-float! values + FACE_OBJ_SELECTED

	if TYPE_OF(pos) <> TYPE_FLOAT [pos/header: TYPE_FLOAT]
	adj: gtk_range_get_adjustment widget
	pos/value: gtk_adjustment_get_value adj
	
	if TYPE_OF(sel) <> TYPE_PERCENT [sel/header: TYPE_PERCENT]
	sel/value: (gtk_adjustment_get_page_size adj) / 100.0
]

get-child-from-xy: func [
	parent		[handle!]
	x			[integer!]
	y			[integer!]
	return:		[integer!]
	/local
		widget	[handle!]
][
0
]

get-text-size: func [
	face		[red-object!]
	str			[red-string!]
	pt			[red-point2D!]
	return:		[tagSIZE]
	/local
		values	[red-value!]
		font	[red-object!]
		state	[red-block!]
		hFont	[handle!]
		text	[c-string!]
		len		[integer!]
		size	[tagSIZE]
][
	values: object/get-values face
	font: as red-object! values + FACE_OBJ_FONT
	hFont: null
	if TYPE_OF(font) = TYPE_OBJECT [
		state: as red-block! values + FONT_OBJ_STATE
		if TYPE_OF(state) <> TYPE_BLOCK [hFont: get-font-handle font 0]
		if null? hFont [hFont: make-font face font]
	]
	if null? hFont [hFont: default-attrs]

	len: -1
	text: unicode/to-utf8 str :len

	size: pango-size? text hFont

	if pt <> null [
		pt/x: as float32! size/width
		pt/y: as float32! size/height
	]
	size
]

pango-size?: func [
	text		[c-string!]
	attrs		[handle!]
	return:		[tagSIZE]
	/local
		pl		[handle!]
		width	[integer!]
		height	[integer!]
		size	[tagSIZE]
][
	if null? pango-context [pango-context: gdk_pango_context_get]
	pl: pango_layout_new pango-context
	pango_layout_set_text pl text -1
	pango_layout_set_attributes pl attrs
	width: 0 height: 0
	pango_layout_get_pixel_size pl :width :height
	g_object_unref pl
	size: declare tagSIZE
	size/width: width
	size/height: height
	size
]

free-handles: func [
	widget		[handle!]
	force?		[logic!]
	/local
		values	[red-value!]
		type	[red-word!]
		face	[red-object!]
		tail	[red-object!]
		pane	[red-block!]
		state	[red-value!]
		rate	[red-value!]
		sym		[integer!]
		handle	[handle!]
		timer	[handle!]
		sec		[float!]
		cfg		[integer!]
		last	[handle!]
][
	if null? widget [exit]

	values: get-face-values widget
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	free-color-provider widget
	free-font-provider widget
	rate: values + FACE_OBJ_RATE
	if TYPE_OF(rate) <> TYPE_NONE [remove-widget-timer widget]

	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [face < tail][
			handle: face-handle? face
			unless null? handle [free-handles handle force?]
			face: face + 1
		]
	]

	if sym = window [
		gtk_widget_destroy widget
		;-- TBD: don't know why widget has been destroyed, but still need do event loop
		;-- otherwise the window can't be closed
		timer: g_timer_new
		g_timer_start timer
		forever [
			gtk_main_iteration_do no
			sec: g_timer_elapsed timer null
			if sec > 0.001 [break]
		]
		g_timer_stop timer
		g_timer_destroy timer
	]
	if sym = camera [
		cfg: as integer! GET-CAMERA-CFG(widget)
		if cfg <> 0 [
			camera-dev/close cfg
		]
		last: GET-CAMERA-IMG(widget)
		unless null? last [
			g_object_unref last
		]
	]

	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

on-gc-mark: does [
	collector/keep :flags-blk/node
]

parse-font-name: func [
	str			[c-string!]
	psize		[int-ptr!]
	plen		[int-ptr!]
	return:		[c-string!]
	/local
		len		[integer!]
		len2	[integer!]
		len3	[integer!]
][
	either null? str [
		len: 0
	][
		len: length? str
	]
	if any [
		len < 3
		str/len < #"0"
		str/len > #"9"
	][
		psize/value: gtk-font-size
		plen/value: length? gtk-font-name
		return gtk-font-name
	]
	len2: len - 1
	if str/len2 = #" " [
		psize/value: as integer! str/len - #"0"
		plen/value: len - 2
		return str
	]
	len3: len - 2
	if all [
		str/len2 >= #"0"
		str/len2 <= #"9"
		str/len3 = #" "
	][
		psize/value: as integer! str/len - #"0"
		psize/value: psize/value + (10 * as integer! str/len2 - #"0")
		plen/value: len - 3
		return str
	]
	psize/value: gtk-font-size
	plen/value: length? gtk-font-name
	gtk-font-name
]

set-defaults: func [
	/local
		font	[integer!]
		str		[c-string!]
		size	[integer!]
		len		[integer!]
][
	settings: gtk_settings_get_default
	font: 0
	g_object_get [settings "gtk-font-name" :font null]

	str: as c-string! font
	size: 0
	len: 0
	str: parse-font-name str :size :len

	string/load-at
		str
		len
		#get system/view/fonts/system
		UTF-8

	integer/make-at
		#get system/view/fonts/size
		size

	unless null? default-font-name [
		free as byte-ptr! default-font-name
	]
	default-font-name: as c-string! allocate len + 1
	copy-memory as byte-ptr! default-font-name as byte-ptr! str len
	len: len + 1
	default-font-name/len: null-byte
	default-font-size: size
	default-font-color: 0					;-- default black
	init-default-handle
	default-font-width: font-width? null null
]

find-active-window: func [
	return:		[handle!]
	/local
		pane	[red-block!]
		face	[red-object!]
		num		[integer!]
		count	[integer!]
		win		[handle!]
		ret		[handle!]
][
	pane: as red-block! #get system/view/screens					;-- screens list
	if null? pane [return null]
	
	face: as red-object! block/rs-head pane							;-- 1st screen
	if null? face [return null]	
	
	pane: as red-block! (object/get-values face) + FACE_OBJ_PANE	;-- windows list
	
	num: pane/head + block/rs-length? pane
	either all [
		TYPE_OF(pane) = TYPE_BLOCK
		0 < num
	][
		ret: face-handle? as red-object! (block/rs-tail pane) - 1
		count: num - 1
		loop num [
			win: face-handle? as red-object! block/rs-abs-at pane count
			unless null? win [
				if gtk_window_is_active win [
					return win
				]
			] 
			count: count - 1
		]
		ret
	][
		null
	]
]

find-last-window: func [
	return:		[handle!]
	/local
		pane	[red-block!]
		face	[red-object!]
][
	pane: as red-block! #get system/view/screens					;-- screens list
	if null? pane [return null]
	
	face: as red-object! block/rs-head pane							;-- 1st screen
	if null? face [return null]	
	
	pane: as red-block! (object/get-values face) + FACE_OBJ_PANE	;-- windows list
	
	either all [
		TYPE_OF(pane) = TYPE_BLOCK
		0 < (pane/head + block/rs-length? pane)
	][
		face-handle? as red-object! (block/rs-tail pane) - 1
	][
		null
	]
]

last-face-type?: func [
	face		[red-object!]
	parent		[handle!]
	sym			[integer!]
	return:		[logic!]
	/local
		pface	[red-object!]
		pane	[red-block!]
		head	[red-object!]
		tail	[red-object!]
		type	[red-word!]
][
	pface: get-face-obj parent
	;if TYPE_OF(pface) <> TYPE_OBJECT [return true]
	pane: as red-block! (object/get-values pface) + FACE_OBJ_PANE
	head: as red-object! block/rs-head pane
	tail: as red-object! block/rs-tail pane
	while [tail > head][
		tail: tail - 1
		if tail/ctx = face/ctx [return true]
		type: as red-word! get-node-facet tail/ctx FACE_OBJ_TYPE
		if sym = symbol/resolve type/symbol [
			return false
		]
	]
	true
]

get-os-version: func [
	/local
		major	[integer!]
		minor	[integer!]
		micro	[integer!]
		ver		[red-tuple!]
][
	major: gtk_get_major_version
	minor: gtk_get_minor_version
	micro: gtk_get_micro_version
	ver: as red-tuple! #get system/view/platform/version
	ver/header: TYPE_TUPLE or (3 << 19)
	ver/array1: micro << 16 or (minor << 8) or major
]

support-dark-mode?: func [
	return: [logic!]
][
	false
]

set-dark-mode: func [
	hWnd		[handle!]
	dark?		[logic!]
	top-level?	[logic!]
][
]

init: func [][
	get-os-version
	gtk_disable_setlocale
	gtk_init null null

	screen-size-x: gdk_screen_width
	screen-size-y: gdk_screen_height

	set-defaults

	#if type = 'exe [set-env-theme]
	set-app-theme "box, button.text-button {min-width: 1px; min-height: 1px;}" yes
	collector/register as int-ptr! :on-gc-mark
	font-ext-type: externals/register "font" as-integer :delete-font
]

get-symbol-name: function [
	sym			[integer!]
	return:		[c-string!]
][
	symbol/get-c-string sym
]

remove-widget-timer: func [
	widget		[handle!]
	/local
		timer	[integer!]
		data	[handle!]
][
	unless null? widget [
		data: g_object_get_qdata widget red-timer-id
		timer: either null? data [0][as integer! data]

		if timer <> 0 [								;-- cancel a preexisting timeout
			g_source_remove timer
			timer: 0
			g_object_set_qdata widget red-timer-id as int-ptr! timer
		]
	]
]

add-widget-timer: func [
	widget		[handle!]
	ts			[integer!]
	/local
		timer	[integer!]
		data	[handle!]
][
	;;g_object_ref_sink main-window
	timer: g_timeout_add ts as integer! :red-timer-action widget
	g_object_set_qdata widget red-timer-id as int-ptr! timer
]

get-widget-timer: func [
	widget		[handle!]
	return:		[int-ptr!]
][
	either null? widget [as int-ptr! 0][g_object_get_qdata widget red-timer-id]
]

remove-all-timers: func [
	widget		[handle!]
	/local
		widget_	[handle!]
		pane	[red-block!]
		face	[red-object!]
		tail	[red-object!]
		values	[red-value!]
		rate	[red-value!]
][
	values: get-face-values widget
	pane: 	as red-block! values + FACE_OBJ_PANE
	rate:	 values + FACE_OBJ_RATE

	if TYPE_OF(rate) <> TYPE_NONE [remove-widget-timer widget]

	if all [TYPE_OF(pane) = TYPE_BLOCK 0 <> block/rs-length? pane] [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane

		while [face < tail][
			widget_: face-handle? face
			unless null? widget_ [remove-all-timers widget_]
			face: face + 1
		]
	]
]

change-rate: func [
	widget		[handle!]
	rate		[red-value!]
	/local
		int		[red-integer!]
		tm		[red-time!]
		ts		[integer!]
		timer	[integer!]
		data	[handle!]
][
	unless null? widget [
		remove-widget-timer widget

		switch TYPE_OF(rate) [
			TYPE_INTEGER [
				int: as red-integer! rate
				if int/value <= 0 [fire [TO_ERROR(script invalid-facet-type) rate]]
				ts: 1000 / int/value
			]
			TYPE_TIME [
				tm: as red-time! rate
				if tm/time <= 0.0 [fire [TO_ERROR(script invalid-facet-type) rate]]
				ts: as-integer tm/time * 1000.0
				if ts = 0 [ts: 1]
			]
			TYPE_NONE [
				;; DEBUG: print ["change-rate: removed timer for widget " widget lf]
				exit
			]
			default	  [fire [TO_ERROR(script invalid-facet-type) rate]]
		]

		add-widget-timer widget ts
	]
]

change-image: func [
	widget		[handle!]
	image		[red-image!]
	type		[integer!]
	/local
		img		[handle!]
][
	;; DEBUG: print ["change-image " widget " type: " get-symbol-name type lf]
	case [
		all [type = camera TYPE_OF(image) = TYPE_NONE][
			camera-get-image widget image
		]
		any [type = button type = toggle type = check type = radio][
			if TYPE_OF(image) = TYPE_IMAGE [
				img: gtk_image_new_from_pixbuf OS-image/to-pixbuf image
				gtk_button_set_image widget img
			]
		]
		true [0]
	]
]

change-pane: func [
	parent		[handle!]
	pane		[red-block!]
	type		[integer!]
	/local
		layout	[handle!]
		win		[handle!]
		focus	[handle!]
		list	[GList!]
		child	[GList!]
		s		[series!]
		face	[red-object!]
		tail	[red-object!]
		widget	[handle!]
		values	[red-value!]
		offset	[red-pair!]

][
	layout: case [
		type = window [
			GET-CONTAINER(parent)
		]
		type = group-box [
			gtk_bin_get_child parent
		]
		any [
			type = base
			type = rich-text
			type = panel
		][
			parent
		]
		true [
			null
		]
	]

	unless null? layout [
		win: gtk_widget_get_toplevel parent
		focus: gtk_window_get_focus win
		list: gtk_container_get_children layout
		child: list
		while [not null? child][
			g_object_ref child/data								;-- to avoid destruction before removing from container
			gtk_container_remove layout child/data
			child: child/next
		]

		s: GET_BUFFER(pane)
		face: as red-object! s/offset + pane/head
		tail: as red-object! s/tail

		while [face < tail][
			if TYPE_OF(face) = TYPE_OBJECT [
				widget: face-handle? face
				if widget <> null [
					values: object/get-values face
					offset: as red-pair! values + FACE_OBJ_OFFSET
					set-widget-child parent widget offset
				]
			]
			face: face + 1
		]

		child: list
		while [not null? child][
			g_object_unref child/data
			child: child/next
		]
		unless null? list [
			g_list_free list
		]
		if focus <> null [gtk_widget_grab_focus focus]
	]
]

change-offset: func [
	widget		[handle!]
	values		[red-value!]
	pos			[red-pair!]
	type		[integer!]
	/local
		parent	[handle!]
][
	if TYPE_OF(pos) = TYPE_POINT2D [as-pair as red-point2D! pos]
	parent: get-face-parent widget values type
	set-widget-child-offset parent widget pos type
	as-point2D pos
]

change-size: func [
	widget		[handle!]
	size		[red-pair!]
	type		[integer!]
	/local
		values	[red-value!]
		ntype	[red-word!]
		sym		[integer!]
		layout	[handle!]
		label	[handle!]
		pl		[handle!]
		x		[integer!]
		y		[integer!]
		fy		[float!]
		min		[float!]
		max		[float!]
		page	[float!]
		adj		[handle!]
		pt		[red-point2D!]
		sx sy	[integer!]
][
	GET_PAIR_XY_INT(size sx sy)
	SET_PAIR_SIZE_FLAG(widget size)
	CHECK_FACE_SIZE(size sx sy)
	either type = window [
		gtk_window_resize widget sx sy
		gtk_widget_queue_draw widget
	][
		values: get-face-values widget
		ntype: as red-word! values + FACE_OBJ_TYPE
		sym: symbol/resolve ntype/symbol
		layout: get-face-layout widget sym
		y: sy
		if layout <> widget [
			if type = rich-text [	;-- is scrollable
				adj: gtk_scrollable_get_vadjustment widget
				min: gtk_adjustment_get_lower adj
				max: gtk_adjustment_get_upper adj
				page: gtk_adjustment_get_page_size adj
				fy: as float! y
				fy: max - min / page * fy
				y: as-integer fy
			]
			gtk_widget_set_size_request layout sx sy
			gtk_widget_queue_resize layout
		]
		if type = rich-text [
			gtk_layout_set_size widget sx y
		]
		gtk_widget_set_size_request widget sx sy
		gtk_widget_queue_resize widget

		if type = panel [
			label: GET-CAPTION(widget)
			unless null? label [
				pl: gtk_label_get_layout label
				x: 0 y: 0
				pango_layout_get_pixel_size pl :x :y
				x: either sx > x [sx - x / 2][0]
				y: either sy > y [sy - y / 2][0]
				gtk_layout_move widget label x y
			]
		]
	]
]

change-visible: func [
	widget		[handle!]
	show?		[logic!]
	type		[integer!]
	/local
		layout	[handle!]
][
	if all [show? type = window][OS-show-window as-integer widget exit]

	layout: get-face-layout widget type
	if layout <> widget [
		gtk_widget_set_visible layout show?
	]
	gtk_widget_set_visible widget show?
]

change-enabled: func [
	widget		[handle!]
	enabled?	[logic!]
	type		[integer!]
	/local
		obj		[integer!]
][
	gtk_widget_set_sensitive widget enabled?
]

change-text: func [
	widget		[handle!]
	values		[red-value!]
	face		[red-object!]
	type		[integer!]
	/local
		len		[integer!]
		cstr	[c-string!]
		str		[red-string!]
		buffer	[handle!]
		start	[GtkTextIter! value]
		end		[GtkTextIter! value]
][
	;; DEBUG: print ["change-text: " get-symbol-name type lf]

	if null? widget [exit]
	if  type = base [
		gtk_widget_queue_draw widget
		exit
	]

	str: as red-string! values + FACE_OBJ_TEXT
	cstr: switch TYPE_OF(str) [
		TYPE_STRING [len: -1 unicode/to-utf8 str :len]
		TYPE_NONE	[""]
		default		[null]									;@@ Auto-convert?
	]
	if null? cstr [exit]

	;unless change-font widget face as red-object! values + FACE_OBJ_FONT type [
		case [
			type = area [
				buffer: gtk_text_view_get_buffer widget
				g_signal_handlers_block_by_func(buffer :area-changed widget)
				gtk_text_buffer_set_text buffer cstr -1
				g_signal_handlers_unblock_by_func(buffer :area-changed widget)
				gtk_text_buffer_get_bounds buffer as handle! start as handle! end
				update-textview-tag buffer as handle! start as handle! end
			]
			type = text [
				gtk_label_set_text widget cstr
			]
			type = field [
				buffer: gtk_entry_get_buffer widget
				gtk_entry_buffer_set_text buffer cstr -1
			]
			any [type = button type = toggle type = radio type = check][
				gtk_button_set_label widget cstr
			]
			type = window [
				gtk_window_set_title widget cstr
			]
			type = group-box [
				gtk_frame_set_label widget cstr
			]
			true [0]
		]
		gtk_widget_queue_draw widget
	;]
]

change-data: func [
	widget			[handle!]
	values			[red-value!]
	/local
		data		[red-value!]
		word		[red-word!]
		selected	[red-integer!]
		f			[red-float!]
		str			[red-string!]
		caption		[c-string!]
		type		[integer!]
		len			[integer!]
		flt			[float!]
		adj			[handle!]
][
	data: as red-value! values + FACE_OBJ_DATA
	word: as red-word! values + FACE_OBJ_TYPE
	selected: as red-integer! values + FACE_OBJ_SELECTED
	type: word/symbol

	case [
		all [
			type = progress
			any [TYPE_OF(data) = TYPE_PERCENT TYPE_OF(data) = TYPE_FLOAT]
		][
			f: as red-float! data
			gtk_progress_bar_set_fraction widget f/value
		]
		all [
			type = slider
			any [TYPE_OF(data) = TYPE_PERCENT TYPE_OF(data) = TYPE_FLOAT]
		][
			f: as red-float! data
			gtk_range_set_value widget f/value * 100.0
		]
		all [type = scroller TYPE_OF(data) = TYPE_FLOAT][
			f: as red-float! data
			flt: f/value
			if flt < 0.0 [flt: 0.0]
			if flt > 1.0 [flt: 1.0]
			flt: flt * 100.0
			adj: gtk_range_get_adjustment widget
			gtk_adjustment_set_value adj flt
		]
		any [
			type = check
			type = toggle
		][
			set-logic-state widget as red-logic! data yes
		]
		type = radio [
			set-logic-state widget as red-logic! data no
		]
	; 	type = tab-panel [
	; 		set-tabs widget get-face-values widget
	; 	]
		all [
			type = text-list
			TYPE_OF(data) = TYPE_BLOCK
		][
			g_signal_handlers_block_by_func(widget :text-list-selected-rows-changed widget)
			gtk_list_box_unselect_all widget
			gtk_container_foreach widget as-integer :remove-entry widget
			init-text-list widget as red-block! data selected
			g_signal_handlers_unblock_by_func(widget :text-list-selected-rows-changed widget)
		]
		any [type = drop-list type = drop-down][
			init-combo-box widget as red-block! data null type = drop-list
		]
		true [0]										;-- default, do nothing
	]
	0
]

change-selection: func [
	widget		[handle!]
	int			[red-integer!]								;-- can be also none! | object!
	type		[integer!]
	/local
		idx 	[integer!]
		sz		[integer!]
		wnd		[integer!]
		item	[handle!]
		sel		[red-pair!]
		ins		[GtkTextIter! value]
		bound	[GtkTextIter! value]
		buffer	[handle!]
		adj		[handle!]
		f		[red-float!]
		flt		[float!]
][
	if type <> window [
		idx: either TYPE_OF(int) = TYPE_INTEGER [either int/value >= 0 [int/value - 1][-1]][-1]
	]
	case [
		any [type = field type = area][
			sel: as red-pair! int
			switch TYPE_OF(sel) [
				TYPE_PAIR [
					idx: sel/x - 1
					sz: sel/y - idx						;-- should point past the last selected char
				]
				TYPE_NONE [
					idx: 0
					sz:  0
				]
				default [0]
			]
			either type = field [
				gtk_editable_select_region widget idx idx + sz
			][
				buffer: gtk_text_view_get_buffer widget
				;; Careful! GtkTextIter! needs to be initialized first (so this weird call first!)
				gtk_text_buffer_get_selection_bounds buffer as handle! ins as handle! bound
				;; DEBUG: print [" pos : " idx "x" idx + sz lf]
				gtk_text_iter_set_offset as handle! ins idx
				gtk_text_iter_set_offset as handle! bound idx + sz
				gtk_text_buffer_select_range buffer as handle! ins as handle! bound
			]
		]
		type = scroller [
			adj: gtk_range_get_adjustment widget
			f: as red-float! int
			flt: f/value
			if flt < 0.0 [flt: 0.0]
			if flt > 1.0 [flt: 1.0]
			flt: flt * 100.0
			gtk_adjustment_set_page_size adj flt
		]
		type = camera [
			either idx < 0 [
				stop-camera widget
			][
				select-camera widget idx
			]
		]
		type = text-list [
			g_signal_handlers_block_by_func(widget :text-list-selected-rows-changed widget)
			select-text-list widget idx
			g_signal_handlers_unblock_by_func(widget :text-list-selected-rows-changed widget)
		]
		any [type = drop-list type = drop-down][
			gtk_combo_box_set_active widget idx
		]
	 	type = tab-panel [
			select-tab widget int
		]
		type = window [
			switch TYPE_OF(int) [
				TYPE_OBJECT [set-selected-focus widget]
				default [0]
			]
		]
	 	true [0]										;-- default, do nothing
	]
]


set-hint-text: func [
	widget		[handle!]
	options		[red-block!]
	/local
		text	[red-string!]
		cell	[integer!]
		len		[integer!]
		str		[c-string!]
][
	if TYPE_OF(options) <> TYPE_BLOCK [exit]
	text: as red-string! block/select-word options word/load "hint" no
	if TYPE_OF(text) = TYPE_STRING [
		len: -1
		str: unicode/to-utf8 text :len
		gtk_entry_set_placeholder_text widget str
	]
]

set-selected-focus: func [
	widget		[handle!]
	/local
		face	[red-object!]
		values	[red-value!]
		handle	[handle!]
][
	values: get-face-values widget
	if values <> null [
		face: as red-object! values + FACE_OBJ_SELECTED
		if TYPE_OF(face) = TYPE_OBJECT [
			handle: face-handle? face
			unless null? handle [gtk_widget_grab_focus handle]
		]
	]
]

set-logic-state: func [
	widget [handle!]
	state  [red-logic!]
	check? [logic!]
	/local
		flags [integer!]
		type  [integer!]
		tri?  [logic!]
		value [logic!]
][
	if check? [
		flags: get-flags as red-block! (get-face-values widget) + FACE_OBJ_FLAGS
		tri?:  flags and FACET_FLAGS_TRISTATE <> 0
		g_signal_handlers_block_by_func(widget :button-toggled widget)
	]
		
	type: TYPE_OF(state)
	either all [check? tri? type = TYPE_NONE][		
		gtk_toggle_button_set_inconsistent widget yes
		gtk_toggle_button_set_active widget no
	][
		value: switch type [
			TYPE_NONE  [false]
			TYPE_LOGIC [state/value]						;-- returns 0/1, matches the messages
			default    [true]
		]
		
		gtk_toggle_button_set_inconsistent widget no
		gtk_toggle_button_set_active widget value
	]
	
	if check? [
		g_signal_handlers_unblock_by_func(widget :button-toggled widget)
	]
]

get-position-value: func [
	pos			[red-float!]
	maximun		[integer!]
	return:		[integer!]
	/local
		f		[float!]
][
	f: 0.0
	if any [
		TYPE_OF(pos) = TYPE_FLOAT
		TYPE_OF(pos) = TYPE_PERCENT
	][
		f: pos/value * (as-float maximun)
	]
	as-integer f
]

get-fraction-value: func [
	pos			[red-float!]
	return:		[float!]
	/local
		f		[float!]
][
	f: 0.0
	if any [
		TYPE_OF(pos) = TYPE_FLOAT
		TYPE_OF(pos) = TYPE_PERCENT
	][
		f: pos/value
	]
	f
]

get-screen-size: func [
	id			[integer!]									;@@ Not used yet
	return:		[red-pair!]
][
	pair/push screen-size-x screen-size-y
]

store-face-to-obj: func [
	obj			[handle!]
	face		[red-object!]
][
	g_object_set_qdata obj red-face-id as int-ptr! references/store as red-value! face
]

init-combo-box: func [
	combo		[handle!]
	data		[red-block!]
	caption		[c-string!]
	drop-list?	[logic!]
	/local
		str		[red-string!]
		tail	[red-string!]
		len		[integer!]
		val		[c-string!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data

		;remove all items
		gtk_combo_box_text_remove_all combo

		if str = tail [exit]
		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [
				len: -1
				val: unicode/to-utf8 str :len
				gtk_combo_box_text_append_text combo val
			]
			str: str + 1
		]
	]
]

remove-entry: func [
	[cdecl]
	widget		[handle!]
	container	[int-ptr!]
][
	gtk_container_remove container widget
]

font-width?: func [
	face		[red-object!]
	font		[red-object!]
	return:		[float32!]
	/local
		txt		[c-string!]
		attrs	[handle!]
		free?	[logic!]
		sz		[tagSIZE]
][
	txt: "abcde12xxx"
	free?: no
	either all [
		font <> null
		TYPE_OF(font) = TYPE_OBJECT
	][
		attrs: create-pango-attrs face font
		free?: yes
	][
		attrs: default-attrs
	]
	sz: pango-size? txt attrs
	if free? [pango_attr_list_unref attrs]
	(as float32! sz/width) / as float32! 10.0
]

update-scroller: func [
	scroller	[red-object!]
	flag		[integer!]
	/local
		parent		[red-object!]
		vertical?	[red-logic!]
		bar			[handle!]
		int			[red-integer!]
		values		[red-value!]
		widget		[handle!]
		container	[handle!]
		pos			[float!]
		page		[float!]
		max			[float!]
		min			[float!]
		n			[float!]
		range		[float!]
		new-pos		[float!]
		vs			[integer!]
		hs			[integer!]
		w			[integer!]
		h			[integer!]
		flags		[integer!]
][
	values: object/get-values scroller
	parent: as red-object! values + SCROLLER_OBJ_PARENT
	vertical?: as red-logic! values + SCROLLER_OBJ_VERTICAL?
	int: as red-integer! block/rs-head as red-block! (object/get-values parent) + FACE_OBJ_STATE
	widget: as handle! int/value
	container: get-face-layout widget rich-text

	int: as red-integer! values + flag
	if flag = SCROLLER_OBJ_VISIBLE? [
		hs: 0 vs: 0
		gtk_scrolled_window_get_policy container :hs :vs
		either int/value = 0 [flags: 2][flags: 1]
		either vertical?/value [vs: flags][hs: flags]
		gtk_scrolled_window_set_policy container hs vs
		exit
	]

	either vertical?/value [
		bar: gtk_scrollable_get_vadjustment widget
	][
		bar: gtk_scrollable_get_hadjustment widget
	]

	SET-CONTAINER(bar scroller/ctx)

	w: 0 h: 0
	gtk_widget_get_size_request container :w :h

	int: as red-integer! values + SCROLLER_OBJ_POS
	pos: as float! int/value
	int: as red-integer! values + SCROLLER_OBJ_PAGE
	page: as float! int/value
	int: as red-integer! values + SCROLLER_OBJ_MIN
	min: as float! int/value
	int: as red-integer! values + SCROLLER_OBJ_MAX
	max: as float! int/value

	if max - min <= page [exit]

	switch flag [
		SCROLLER_OBJ_POS [
			if null <> GET-IN-LOOP(widget) [exit]
			pos: pos - min
			range: max - min - page + 1.0
			if pos > range [pos: range]
			if pos < 0.0 [pos: 0.0]
			either range <= 0.0 [new-pos: 1.0][
				new-pos: pos / range
			]
			min: gtk_adjustment_get_lower bar
			max: gtk_adjustment_get_upper bar
			page: gtk_adjustment_get_page_size bar
			range: max - min - page
			new-pos: new-pos * range + min
			gtk_adjustment_set_value bar new-pos
		]
		SCROLLER_OBJ_PAGE
		SCROLLER_OBJ_MAX [
			n: as float! h
			if all [page > 0.0 max - min > page][
				n: max - min + 1.0 / page * n
				h: as-integer n + 0.5
				gtk_layout_set_size widget w h
			]
		]
		default [0]
	]
]


update-rich-text: func [
	state		[red-block!]
	handles		[red-block!]
	return:		[logic!]
	/local
		redraw	[red-logic!]
][
	if TYPE_OF(handles) = TYPE_BLOCK [
		redraw: as red-logic! (block/rs-tail handles) - 1
		redraw/value: true
	]
	TYPE_OF(state) <> TYPE_BLOCK
]

parse-common-opts: func [
	widget		[handle!]
	face		[red-object!]
	options		[red-block!]
	type		[integer!]
	/local
		word	[red-word!]
		w		[red-word!]
		img		[red-image!]
		bool	[red-logic!]
		obj		[red-object!]
		len		[integer!]
		sym		[integer!]
		cur		[c-string!]
		hcur	[handle!]
		pixbuf	[handle!]
		display	[handle!]
		owner	[handle!]
		x		[integer!]
		y		[integer!]
][
	if TYPE_OF(options) = TYPE_BLOCK [
		word: as red-word! block/rs-head options
		len: block/rs-length? options
		if len % 2 <> 0 [exit]
		while [len > 0][
			if TYPE_OF(word) = TYPE_SET_WORD [
				sym: symbol/resolve word/symbol
				case [
					sym = _cursor [
						w: word + 1
						display: gtk_widget_get_display widget
						hcur: null
						either TYPE_OF(w) = TYPE_IMAGE [
							img: as red-image! w
							pixbuf: OS-image/to-pixbuf img 0 0
							x: IMAGE_WIDTH(img/size) / 2
							y: IMAGE_HEIGHT(img/size) / 2
							hcur: gdk_cursor_new_from_pixbuf display pixbuf x y
							;g_object_unref pixbuf
						][
							if TYPE_OF(word) = TYPE_WORD [
								sym: symbol/resolve w/symbol
								cur: case [
									sym = _I-beam	["text"]
									sym = _hand		["grab"]
									sym = _cross	["crosshair"]
									true			["default"]
								]
								hcur: gdk_cursor_new_from_name display cur
							]
						]
						if hcur <> null [SET-CURSOR(widget hcur)]
					]
					sym = caret [
						obj: as red-object! word + 1
						if TYPE_OF(word) = TYPE_OBJECT [
							owner: get-face-handle obj
							SET-CARET-OWNER(widget owner)
						]
					]
					true [0]
				]
			]
			word: word + 2
			len: len - 2
		]
	]
]

OS-redraw: func [
	widget		[integer!]
][
	if widget <> 0 [								;-- view engine should make sure a valid handle, but it not
		gtk_widget_queue_draw as handle! widget
	]
]

OS-refresh-window: func [
	widget		[integer!]
][
	if widget <> 0 [								;-- view engine should make sure a valid handle, but it not
		gtk_widget_queue_draw as handle! widget
		set-selected-focus as handle! widget
	]
]

OS-show-window: func [
	widget		[integer!]
	/local
		n		[integer!]
		win		[handle!]
][
	win: as handle! widget
	if gtk_window_get_modal win [gtk_window_set_transient_for win find-active-window]

	gtk_widget_show win
	n: 0
	window-ready?: no
	until [		;-- process some events to make the window ready
		do-events yes
		n: n + 1
		any [window-ready? n = 10000]
	]
	window-ready?: no
	;set-selected-focus win
]

set-buffer: func [
	widget	[handle!]
	x		[integer!]
	y		[integer!]
	color	[red-tuple!]
	/local
		buf [handle!]
][
	unless transparent-base? color [exit]

	buf: GET-BASE-BUFFER(widget)
	if buf <> null [cairo_surface_destroy buf]

	buf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 x y
	SET-BASE-BUFFER(widget buf)
]

OS-make-view: func [
	face		[red-object!]
	parent		[integer!]
	return:		[integer!]
	/local
		values		[red-value!]
		type		[red-word!]
		str			[red-string!]
		tail		[red-string!]
		offset		[red-pair!]
		size		[red-pair!]
		data		[red-block!]
		int			[red-integer!]
		img			[red-image!]
		menu		[red-block!]
		show?		[red-logic!]
		enabled?	[red-logic!]
		selected	[red-integer!]
		font		[red-object!]
		para		[red-object!]
		flags		[integer!]
		bits		[integer!]
		rate		[red-value!]
		color		[red-tuple!]
		sym			[integer!]
		p-sym		[integer!]
		caption		[c-string!]
		len			[integer!]
		widget		[handle!]
		winbox		[handle!]
		buffer		[handle!]
		container	[handle!]
		hMenu		[handle!]
		vadjust		[handle!]
		value		[integer!]
		fvalue		[float!]
		f32			[float32!]
		vertical?	[logic!]
		rfvalue		[red-float!]
		attrs		[handle!]
		handle		[handle!]
		fradio		[handle!]
		x			[integer!]
		y			[integer!]
		gm			[GdkGeometry! value]
		sx sy		[integer!]
		pt			[red-point2D!]
][
	stack/mark-native words/_body

	values: object/get-values face

	type:	  as red-word!		values + FACE_OBJ_TYPE
	str:	  as red-string!	values + FACE_OBJ_TEXT
	offset:   as red-pair!		values + FACE_OBJ_OFFSET
	size:	  as red-pair!		values + FACE_OBJ_SIZE
	show?:	  as red-logic!		values + FACE_OBJ_VISIBLE?
	enabled?: as red-logic!		values + FACE_OBJ_ENABLED?
	data:	  as red-block!		values + FACE_OBJ_DATA
	img:	  as red-image!		values + FACE_OBJ_IMAGE
	font:	  as red-object!	values + FACE_OBJ_FONT
	menu:	  as red-block!		values + FACE_OBJ_MENU
	selected: as red-integer!	values + FACE_OBJ_SELECTED
	para:	  as red-object!	values + FACE_OBJ_PARA
	rate: 	  as red-value!		values + FACE_OBJ_RATE
	color:	  as red-tuple!		values + FACE_OBJ_COLOR

	bits: 	  get-flags as red-block! values + FACE_OBJ_FLAGS
	sym: 	  symbol/resolve type/symbol

	if TYPE_OF(offset) = TYPE_POINT2D [as-pair as red-point2D! offset]
	GET_PAIR_XY_INT(size sx sy)
	CHECK_FACE_SIZE(size sx sy)

	caption: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][
		null
	]

	container: null

	case [
		sym = check [
			widget: gtk_check_button_new_with_label caption
		]
		sym = radio [
			handle: as handle! parent
			fradio: GET-FIRST-RADIO(handle)
			either null? fradio [
				widget: gtk_radio_button_new_with_label null caption
				SET-FIRST-RADIO(handle widget)
			][
				widget: gtk_radio_button_new_with_label_from_widget fradio caption
			]
			set-logic-state widget as red-logic! data no
		]
		sym = toggle [
			widget: gtk_toggle_button_new_with_label caption
			if TYPE_OF(img) = TYPE_IMAGE [
				change-image widget img sym
			]
		]
		sym = button [
			widget: gtk_button_new_with_label caption
			if TYPE_OF(img) = TYPE_IMAGE [
				change-image widget img sym
			]
		]
		sym = base [
			widget: gtk_layout_new null null
			gtk_layout_set_size widget sx sy
			set-buffer widget sx sy color
		]
		sym = rich-text [
			widget: gtk_layout_new null null
			gtk_layout_set_size widget sx sy
			handle: gtk_im_multicontext_new
			SET-IM-CONTEXT(widget handle)
			gobj_signal_connect(handle "commit" :im-commit widget)
			gobj_signal_connect(handle "preedit-start" :im-preedit-start widget)
			;gobj_signal_connect(handle "preedit-end" :im-preedit-end widget)
			gobj_signal_connect(handle "preedit-changed" :im-preedit-changed widget)
			;--@@ only a few languages may use it, such as Thai. I'll implement it later.
			;gobj_signal_connect(handle "retrieve-surrounding" :im-retrieve-surrounding widget)
			;gobj_signal_connect(handle "delete-surrounding" :im-delete-surrounding widget)
			if bits and FACET_FLAGS_SCROLLABLE <> 0 [
				container: gtk_scrolled_window_new null null
				gtk_container_add container widget
				gtk_scrolled_window_set_policy container 1 1
				len: 0
				loop 2 [
					either zero? len [vadjust: gtk_scrollable_get_vadjustment widget][
						vadjust: gtk_scrollable_get_hadjustment widget
					]
					len: len + 1
					g_signal_handlers_disconnect_by_data(vadjust widget)	;-- remove default event handler
					gtk_adjustment_configure vadjust 0.0 0.0 1.0 0.0 0.0 1.0
					gobj_signal_connect(vadjust "value_changed" :vbar-value-changed widget)
				]
			]
		]
		sym = scroller [
			vadjust: gtk_adjustment_new 0.0 0.0 100.0 1.0 10.0 10.0
			len: either sy > sx [1][0]
			widget: gtk_scrollbar_new len vadjust
			gobj_signal_connect(vadjust "value_changed" :scroller-value-changed widget)
			set-scroller-pos widget values
		]
		sym = window [
			;; FIXME TBD parent should not always be zero, view engine should set it.
			;either all [parent <> 0 bits and FACET_FLAGS_MODAL <> 0] [
			either bits and FACET_FLAGS_MODAL <> 0 [
				widget: gtk_dialog_new
				gtk_window_set_modal widget yes
				winbox: gtk_dialog_get_content_area widget
			][
				widget: gtk_window_new 0
				winbox: gtk_box_new GTK_ORIENTATION_VERTICAL 0
				gtk_container_add widget winbox
				gtk_widget_show winbox
			]
			if any [
				bits and FACET_FLAGS_NO_TITLE <> 0
				bits and FACET_FLAGS_NO_BORDER <> 0
			][
				gtk_window_set_decorated widget no
			]
			if any [
				bits and FACET_FLAGS_NO_MIN <> 0
				bits and FACET_FLAGS_NO_BTNS <> 0
			][
				gtk_window_set_type_hint widget 5					;-- WINDOW_TYPE_HINT_UTILITY
			]
			if bits and FACET_FLAGS_NO_BTNS <> 0 [
				gtk_window_set_deletable widget no					;-- hide Close button
			]
			
			unless null? caption [gtk_window_set_title widget caption]

			hMenu: null
			if menu-bar? menu window [
				hMenu: gtk_menu_bar_new
				gtk_widget_show hMenu
				build-menu menu hMenu widget
				gtk_box_pack_start winbox hMenu no yes 0
				SET-CONTAINER-W(widget sx)
				SET-CONTAINER-H(widget sy)
			]
			SET-HMENU(widget hMenu)

			container: gtk_layout_new null null
			gtk_layout_set_size container sx sy
			gtk_widget_show container
			gtk_box_pack_start winbox container yes yes 0
			gtk_window_move widget offset/x offset/y

			gtk_window_set_default_size widget sx sy
			gtk_window_set_resizable widget (bits and FACET_FLAGS_RESIZE <> 0)
			gm/min_width: 1
			gm/min_height: 1
			gtk_window_set_geometry_hints widget null :gm 2		;-- 2: MIN_SIZE

			store-face-to-obj container face
		]
		sym = camera [
			widget: gtk_layout_new null null
			gtk_layout_set_size widget sx sy
			init-camera widget data selected size
		]
		sym = calendar [
			widget: gtk_calendar_new
		]
		sym = slider [
			vertical?: sy > sx
			widget: gtk_scale_new_with_range vertical? 0.0 100.0 1.0
			if vertical? [
				gtk_range_set_inverted widget yes
			]
			fvalue: get-fraction-value as red-float! data
			gtk_range_set_value widget fvalue * 100.0
			gtk_scale_set_has_origin widget no
			gtk_scale_set_draw_value widget no
		]
		sym = text [
			widget: gtk_label_new caption
			gtk_label_set_line_wrap widget yes
			container: gtk_event_box_new
			gtk_container_add container widget
		]
		sym = field [
			widget: gtk_entry_new
			buffer: gtk_entry_get_buffer widget
			unless null? caption [
				gtk_entry_buffer_set_text buffer caption -1
			]
			f32: (as float32! sx - 18) / font-width? face font
			gtk_entry_set_width_chars widget as-integer f32
			set-hint-text widget as red-block! values + FACE_OBJ_OPTIONS
			if bits and FACET_FLAGS_PASSWORD <> 0 [gtk_entry_set_visibility widget no]
			gtk_entry_set_has_frame widget (bits and FACET_FLAGS_NO_BORDER = 0)
		]
		sym = progress [
			widget: gtk_progress_bar_new
			if sy > sx [
				gtk_orientable_set_orientation widget 1
				gtk_progress_bar_set_inverted widget yes
			]
			fvalue: get-fraction-value as red-float! data
			gtk_progress_bar_set_fraction widget fvalue
		]
		sym = area [
			widget: gtk_text_view_new
			buffer: gtk_text_view_get_buffer widget
			unless null? caption [
				gtk_text_buffer_set_text buffer caption -1
			]
			container: gtk_scrolled_window_new null null
			gtk_container_add container widget
		]
		sym = group-box [
			widget: gtk_frame_new caption
			buffer: gtk_layout_new null null
			gtk_widget_show buffer
			gtk_container_add widget buffer
		]
		sym = panel [
			widget: gtk_layout_new null null
			gtk_layout_set_size widget sx sy
		]
		sym = tab-panel [
			widget: gtk_notebook_new
		]
		sym = text-list [
			widget: gtk_list_box_new
			gtk_list_box_set_selection_mode widget 1
			init-text-list widget data selected
			container: gtk_scrolled_window_new null null
			if bits and FACET_FLAGS_NO_BORDER = 0 [
				gtk_scrolled_window_set_shadow_type container 3
			]
			gtk_container_add container widget
		]
		any [
			sym = drop-list
			sym = drop-down
		][
			widget: either sym = drop-list [gtk_combo_box_text_new][gtk_combo_box_text_new_with_entry]
			init-combo-box widget data caption sym = drop-list
			if sym = drop-down [
				if sx > 64 [value: sx - 64]
				if value < 24 [value: 24]
				f32: (as float32! value) / (font-width? face font)	;-- width / char width
				gtk_entry_set_width_chars gtk_bin_get_child widget as-integer f32
			]
			gtk_combo_box_set_active widget 0
		]
		true [
			;-- search in user-defined classes
			fire [TO_ERROR(script face-type) type]
		]
	]

	unless null? container [
		SET-CONTAINER(widget container)
	]
	;-- store the face value in the extra space of the window struct
	assert TYPE_OF(face) = TYPE_OBJECT
	store-face-to-obj widget face

	SET_PAIR_SIZE_FLAG(widget size)

	if all [
		sym = panel
		not null? caption
	][
		;attrs: get-font face font
		buffer: gtk_label_new caption
		gtk_widget_show buffer
		;set-label-attrs buffer font attrs
		handle: gtk_label_get_layout buffer
		x: 0 y: 0
		pango_layout_get_pixel_size handle :x :y
		x: either sx > x [sx - x / 2][0]
		y: either sy > y [sy - y / 2][0]
		gtk_layout_put widget buffer x y
		SET-CAPTION(widget buffer)
	]

	if sym <> window [
		if parent <> 0 [
			unless set-widget-child as handle! parent widget offset [
				fire [TO_ERROR(script face-type) type]
			]
		]
		set-widget-child-offset as handle! parent widget offset sym
		change-visible widget show?/value sym
		change-size widget size sym
	]

	unless any [sym = window sym = area][build-context-menu widget menu]
	
	; Deal with actors
	connect-widget-events widget values sym
	
	if sym = radio [
		if last-face-type? face as handle! parent sym [
			connect-radio-toggled-events face widget as handle! parent
		]
	]
	
	if any [sym = check sym = toggle][
		set-logic-state widget as red-logic! data yes
	]

	change-selection widget selected sym
	change-color widget color sym
	change-font widget face values sym
	change-para widget face values sym
	change-enabled widget enabled?/value sym

	parse-common-opts widget face as red-block! values + FACE_OBJ_OPTIONS sym

	if TYPE_OF(rate) <> TYPE_NONE [change-rate widget rate]

	as-point2D offset
	stack/unwind
	as-integer widget
]

OS-update-view: func [
	face		[red-object!]
	/local
		ctx		[red-context!]
		values	[red-value!]
		state	[red-block!]
		menu	[red-block!]
		draw	[red-block!]
		word	[red-word!]
		int		[red-integer!]
		int2	[red-integer!]
		bool	[red-logic!]
		s		[series!]
		widget	[handle!]
		flags	[integer!]
		flags-flags	[integer!]
		type	[integer!]
		par		[red-object!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	values: s/offset

	state: as red-block! values + FACE_OBJ_STATE
	word: as red-word! values + FACE_OBJ_TYPE
	type: symbol/resolve word/symbol

	if all [
		type = rich-text
		update-rich-text state as red-block! values + FACE_OBJ_EXT3
	][
		exit
	]

	s: GET_BUFFER(state)
	int: as red-integer! s/offset
	widget: as handle! int/value
	if null? widget [exit]

	int: int + 1
	flags: int/value

	if flags and FACET_FLAG_OFFSET <> 0 [
		change-offset widget values as red-pair! values + FACE_OBJ_OFFSET type
	]
	if flags and FACET_FLAG_SIZE <> 0 [
		change-size widget as red-pair! values + FACE_OBJ_SIZE type
	]
	if flags and FACET_FLAG_TEXT <> 0 [
		change-text widget values face type
		;gtk_widget_queue_draw widget
	]
	if flags and FACET_FLAG_DATA <> 0 [
		change-data	widget values
	]
	if flags and FACET_FLAG_ENABLED? <> 0 [
		bool: as red-logic! values + FACE_OBJ_ENABLED?
		change-enabled widget bool/value type
	]
	if flags and FACET_FLAG_VISIBLE? <> 0 [
		bool: as red-logic! values + FACE_OBJ_VISIBLE?
		change-visible widget bool/value type
	]
	if flags and FACET_FLAG_SELECTED <> 0 [
		int2: as red-integer! values + FACE_OBJ_SELECTED
		change-selection widget int2 type
	]
	if flags and FACET_FLAG_FLAGS <> 0 [
		flags-flags: get-flags as red-block! values + FACE_OBJ_FLAGS
		if type = field [
			if flags-flags and FACET_FLAGS_PASSWORD <> 0 [
				gtk_entry_set_visibility widget no
			]
			gtk_entry_set_has_frame widget (flags-flags and FACET_FLAGS_NO_BORDER = 0)
		]
	]
	if flags and FACET_FLAG_DRAW  <> 0 [
		either any [type = base type = panel type = rich-text][
			par: as red-object! values + FACE_OBJ_PARENT
			gtk_widget_queue_draw get-face-handle par
		][
			gtk_widget_queue_draw widget
		]
		force-redraw?: yes
		; 0
	]
	if flags and FACET_FLAG_COLOR <> 0 [
		change-color widget as red-tuple! values + FACE_OBJ_COLOR type
	]
	if all [flags and FACET_FLAG_PANE <> 0 type <> tab-panel][
		change-pane widget as red-block! values + FACE_OBJ_PANE type
	]
	if flags and FACET_FLAG_RATE <> 0 [
		change-rate widget values + FACE_OBJ_RATE
	]
	if flags and FACET_FLAG_FONT <> 0 [
		change-font widget face values type
	]
	if flags and FACET_FLAG_PARA <> 0 [
		change-para widget face values type
	]
	;if flags and FACET_FLAG_MENU <> 0 [
	;	menu: as red-block! values + FACE_OBJ_MENU
	;	if menu-bar? menu window [
	;		DestroyMenu GetMenu widget
	;		SetMenu widget build-menu menu CreateMenu
	;	]
	;]
	if flags and FACET_FLAG_IMAGE <> 0 [
		change-image widget as red-image! values + FACE_OBJ_IMAGE type
	]

	;; update-view at least ask for this
	;if main-window = widget [

	gtk_widget_queue_draw widget
	;]

	int/value: 0										;-- reset flags
]

unlink-sub-obj: func [
	face		[red-object!]
	obj			[red-object!]
	field		[integer!]
	/local
		values	[red-value!]
		parent	[red-block!]
		res		[red-value!]
][
	values: object/get-values obj
	parent: as red-block! values + field

	if TYPE_OF(parent) = TYPE_BLOCK [
		res: block/find parent as red-value! face null no no yes no null null no no no no
		if TYPE_OF(res) <> TYPE_NONE [_series/remove as red-series! res null null]
		if all [
			field = FONT_OBJ_PARENT
			block/rs-tail? parent
		][
			free-font obj
		]
	]
]

OS-destroy-view: func [
	face		[red-object!]
	empty?		[logic!]
	/local
		handle	[handle!]
		values	[red-value!]
		obj		[red-object!]
		flags	[integer!]
][
	handle: face-handle? face
	if null? handle [exit]

	values: object/get-values face
	flags: get-flags as red-block! values + FACE_OBJ_FLAGS

	obj: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj FONT_OBJ_PARENT]

	obj: as red-object! values + FACE_OBJ_PARA
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj PARA_OBJ_PARENT]

	free-handles handle no
]

OS-update-facet: func [
	face		[red-object!]
	facet		[red-word!]
	value		[red-value!]
	action		[red-word!]
	new			[red-value!]
	index		[integer!]
	part		[integer!]
	/local
		word	[red-word!]
		sym		[integer!]
		type	[integer!]
		pane	[red-block!]
		widget	[handle!]
][
	sym: symbol/resolve facet/symbol
	;; DEBUG: print ["update-facet " get-symbol-name sym lf]

	case [
		; sym = facets/pane [
		; 	sym: action/symbol
		; 	;; DEBUG: print ["update pane action " get-symbol-name sym lf]
		; 	pane: as red-block! value
		; ]
		sym = facets/data [
			word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
			type: symbol/resolve word/symbol
			sym: action/symbol
			case [
				; any [
				; 	type = drop-list
				; 	type = drop-down
				; ][
				; 	if zero? part [exit]
				; 	update-combo-box face value sym new index part yes
				; ]
				; type = tab-panel [
				; 	update-tabs face value sym new index part
				; ]
				true [OS-update-view face]
			]
		]
		true [OS-update-view face]
	]
]

OS-to-image: func [
	face		[red-object!]
	return:		[red-image!]
	/local
		widget	[handle!]
		win		[handle!]
		xwin	[integer!]
		width	[integer!]
		height	[integer!]
		pixbuf	[handle!]
		word	[red-word!]
		type	[integer!]
		size	[red-pair!]
		offset	[red-point2D!]
		ret		[red-image!]
		pt		[red-point2D!]
		sx sy	[integer!]
][
	word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
	type: symbol/resolve word/symbol

	case [
		type = screen [
			win: gdk_get_default_root_window
			width: gdk_window_get_width win
			height: gdk_window_get_height win
			xwin: gdk_x11_window_get_xid win
			win: gdk_x11_window_foreign_new_for_display gdk_window_get_display win xwin
			either null? win [ret: as red-image! none-value][
				pixbuf: gdk_pixbuf_get_from_window win 0 0 width height ;screen-size-x screen-size-y; CGWindowListCreateImage 0 0 7F800000h 7F800000h 1 0 0		;-- INF
				ret: image/init-image as red-image! stack/push* OS-image/load-pixbuf pixbuf
			]
		]
		type = camera [
			widget: face-handle? face
			either null? widget [ret: as red-image! none-value][
				ret: as red-image! (object/get-values face) + FACE_OBJ_IMAGE
				camera-get-image widget ret
			]
		]
		true [
			widget: face-handle? face
			either null? widget [ret: as red-image! none-value][
				size: as red-pair! (object/get-values face) + FACE_OBJ_SIZE
				offset: as red-point2D! (object/get-values face) + FACE_OBJ_OFFSET
				win: gtk_widget_get_window widget
				either not null? win [
					GET_PAIR_XY_INT(size sx sy)
					pixbuf: either type = window [
						gdk_pixbuf_get_from_window win 0 0 sx sy
					][
						gdk_pixbuf_get_from_window win as-integer offset/x as-integer offset/y sx sy
					]
					ret: image/init-image as red-image! stack/push* OS-image/load-pixbuf pixbuf
					;g_object_unref pixbuf
				][ret: as red-image! none-value]
			]
		]
	]
	ret
]

OS-do-draw: func [
	image		[red-image!]
	cmds		[red-block!]
	/local
		cr		[handle!]
		surf	[handle!]
		w		[integer!]
		h		[integer!]
		bitmap	[integer!]
		data	[int-ptr!]
		stride	[integer!]
][
	;; DEBUG: print ["OS-do-draw " image lf]
	w: IMAGE_WIDTH(image/size)
	h: IMAGE_HEIGHT(image/size)
	stride: 0
	bitmap: OS-image/lock-bitmap image yes
	data: OS-image/get-data bitmap :stride
	;; DEBUG: print ["OS-do-draw data " data " size: " w "x" h " stride: " stride lf]
	;stride: cairo_format_stride_for_width CAIRO_FORMAT_ARGB32 w
	surf: cairo_image_surface_create_for_data as byte-ptr! data CAIRO_FORMAT_ARGB32 w h stride
	cr: cairo_create surf
	;; OLD: do-draw cr null cmds no yes yes yes
	do-draw cr null cmds yes no no no
	cairo_destroy cr
	cairo_surface_destroy surf
	;; USELESS NOW???: OS-image/post-transf OS-image/POST-ARGB-TO-ABGR
	OS-image/unlock-bitmap image bitmap
]

OS-draw-face: func [
	hWnd	[handle!]
	cmds	[red-block!]
	flags	[integer!]
	/local
		ctx [draw-ctx!]
][
	if TYPE_OF(cmds) = TYPE_BLOCK [
		assert system/thrown = 0
		ctx: as draw-ctx! g_object_get_qdata hWnd draw-ctx-id
		catch RED_THROWN_ERROR [parse-draw ctx cmds yes]
	]
	if system/thrown = RED_THROWN_ERROR [system/thrown: 0]
]
