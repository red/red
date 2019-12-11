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

#include %../keycodes.reds
#include %gtk.reds
#include %events.reds

#include %font.reds
#include %para.reds
#include %draw.reds

#include %menu.reds
#include %handlers.reds
#include %comdlgs.reds
#include %tab-panel.reds
#include %text-list.reds

settings:			as handle! 0
pango-context:		as handle! 0
default-font-name:	as c-string! 0
default-font-size:	0
gtk-font-name:		"Sans"
gtk-font-size:		10

log-pixels-x:		0
log-pixels-y:		0
screen-size-x:		0
screen-size-y:		0

get-face-obj: func [
	handle		[handle!]
	return:		[red-object!]
	/local
		face	[red-object!]
][
	face: declare red-object!
	face/header: as integer! g_object_get_qdata handle red-face-id1
	face/ctx:	 			 g_object_get_qdata handle red-face-id2
	face/class:  as integer! g_object_get_qdata handle red-face-id3
	face/on-set: 			 g_object_get_qdata handle red-face-id4
	face
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
	values		[red-value!]
	sym			[integer!]
	return:		[handle!]
][
	case [
		any [
			sym = rich-text
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
][
	sym: get-widget-symbol parent
	either TYPE_OF(offset) = TYPE_PAIR [
		x: offset/x
		y: offset/y
	][
		x: 0
		y: 0
	]
	cvalues: get-face-values widget
	ctype: as red-word! cvalues + FACE_OBJ_TYPE
	csym: symbol/resolve ctype/symbol
	clayout: get-face-layout widget cvalues csym
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
		layout	[handle!]
		values	[red-value!]
		ntype	[red-word!]
		sym		[integer!]
		cparent	[handle!]
][
	either type = window [
		gtk_window_move widget pos/x pos/y
	][
		values: get-face-values widget
		ntype: as red-word! values + FACE_OBJ_TYPE
		sym: symbol/resolve ntype/symbol
		layout: get-face-layout widget values sym
		if layout <> widget [
			set-widget-offset layout widget 0 0
		]
		unless null? parent [
			values: get-face-values parent
			ntype: as red-word! values + FACE_OBJ_TYPE
			sym: symbol/resolve ntype/symbol
			cparent: get-face-child-layout parent sym
			set-widget-offset cparent layout pos/x pos/y
		]
	]
]

show-widget: func [
	widget		[handle!]
	/local
		values	[red-value!]
		type	[red-word!]
		sym		[integer!]
		layout	[handle!]
][
	values: get-face-values widget
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	layout: get-face-layout widget values sym
	if layout <> widget [
		gtk_widget_show layout
	]
	gtk_widget_show widget
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
	hFont		[handle!]
	pair		[red-pair!]
	return:		[tagSIZE]
	/local
		text	[c-string!]
		len		[integer!]
		width	[integer!]
		height	[integer!]
		pl		[handle!]
		size	[tagSIZE]
		df		[c-string!]
		pc		[handle!]
		widget	[handle!]
][
	if null? pango-context [pango-context: gdk_pango_context_get]
	size: declare tagSIZE
	if null? hFont [hFont: default-attrs]

	len: -1
	text: unicode/to-utf8 str :len

	pl: pango_layout_new pango-context
	pango_layout_set_text pl text -1
	pango_layout_set_attributes pl hFont
	width: 0 height: 0
	pango_layout_get_pixel_size pl :width :height
	g_object_unref pl

	size/width: width
	size/height: height

	if pair <> null [
		pair/x: size/width
		pair/y: size/height
	]
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
][
	values: get-face-values widget
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	rate: values + FACE_OBJ_RATE
	if TYPE_OF(rate) <> TYPE_NONE [change-rate widget none-value]

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

	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

on-gc-mark: does [
	collector/keep flags-blk/node
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
	set-default-font default-font-name default-font-size
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

init: func [][
	get-os-version
	gtk_disable_setlocale
	gtk_init null null

	screen-size-x: gdk_screen_width
	screen-size-y: gdk_screen_height

	set-defaults

	#if type = 'exe [red-gtk-styles]
	collector/register as int-ptr! :on-gc-mark
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
		type	[red-word!]
		sym		[integer!]
		face	[red-object!]
		tail	[red-object!]
		values	[red-value!]
		rate	[red-value!]
][
	remove-widget-timer widget
	values: get-face-values widget
	type: 	as red-word! values + FACE_OBJ_TYPE
	pane: 	as red-block! values + FACE_OBJ_PANE
	rate:	 values + FACE_OBJ_RATE

	change-rate widget none-value

	sym: 	symbol/resolve type/symbol

	if all [TYPE_OF(pane) = TYPE_BLOCK 0 <> block/rs-length? pane] [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane

		while [face < tail][
			widget_: face-handle? face
			unless null? widget [remove-all-timers widget_]
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
		; type = camera [
		; 	snap-camera widget
		; 	until [TYPE_OF(image) = TYPE_IMAGE]			;-- wait
		; ]
		any [type = button type = check type = radio][
			if TYPE_OF(image) = TYPE_IMAGE [
				img: gtk_image_new_from_pixbuf OS-image/to-pixbuf image
				gtk_button_set_image widget img
			]
		]
		true [0]

	]
]

change-color: func [
	widget		[handle!]
	color		[red-tuple!]
	type		[integer!]
	/local
		t		[integer!]
		face	[red-object!]
		values	[red-value!]
		font	[red-object!]
][
	t: TYPE_OF(color)
	if all [t <> TYPE_NONE t <> TYPE_TUPLE][exit]
	face: get-face-obj widget
	values: object/get-values face
	font: as red-object! values + FACE_OBJ_FONT
	free-font font
	make-font face font
	set-font widget face values
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
		gtk_widget_grab_focus focus
	]
]

change-font: func [
	widget		[handle!]
	face		[red-object!]
	values		[red-value!]
	/local
		font	[red-object!]
][
	font: as red-object! values + FACE_OBJ_FONT
	free-font font
	make-font face font
	set-font widget face values
]

change-offset: func [
	widget		[handle!]
	values		[red-value!]
	pos			[red-pair!]
	type		[integer!]
	/local
		parent	[handle!]
][
	parent: get-face-parent widget values type
	set-widget-child-offset parent widget pos type
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
][
	either type = window [
		gtk_window_set_default_size widget size/x size/y
		gtk_window_resize widget size/x size/y
		gtk_widget_queue_draw widget
	][
		values: get-face-values widget
		ntype: as red-word! values + FACE_OBJ_TYPE
		sym: symbol/resolve ntype/symbol
		layout: get-face-layout widget values sym
		if layout <> widget [
			gtk_widget_set_size_request layout size/x size/y
			gtk_widget_queue_resize layout
		]
		gtk_widget_set_size_request widget size/x size/y
		gtk_widget_queue_resize widget

		if type = panel [
			label: GET-CAPTION(widget)
			unless null? label [
				pl: gtk_label_get_layout label
				x: 0 y: 0
				pango_layout_get_pixel_size pl :x :y
				x: either size/x > x [size/x - x / 2][0]
				y: either size/y > y [size/y - y / 2][0]
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
		values	[red-value!]
		ntype	[red-word!]
		sym		[integer!]
		layout	[handle!]
][
	values: get-face-values widget
	ntype: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve ntype/symbol
	layout: get-face-layout widget values sym
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
			 	gtk_text_buffer_set_text buffer cstr -1
			]
			type = text [
				gtk_label_set_text widget cstr
			]
			type = field [
				buffer: gtk_entry_get_buffer widget
				gtk_entry_buffer_set_text buffer cstr -1
			]
			any [type = button type = radio type = check] [
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
		size		[red-pair!]
		f			[red-float!]
		str			[red-string!]
		caption		[c-string!]
		type		[integer!]
		len			[integer!]
][
	data: as red-value! values + FACE_OBJ_DATA
	word: as red-word! values + FACE_OBJ_TYPE
	selected: as red-integer! values + FACE_OBJ_SELECTED
	type: word/symbol

	;;DEBUG: print ["change-data: " get-symbol-name type lf]

	case [
		all [
			type = progress
			TYPE_OF(data) = TYPE_PERCENT
		][
			f: as red-float! data
			gtk_progress_bar_set_fraction widget f/value
		]
		all [
			type = slider
			TYPE_OF(data) = TYPE_PERCENT
		][
			f: as red-float! data
			gtk_range_set_value widget f/value * 100.0
		]
		type = check [
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
			;;DEBUG: print ["text-list updated" lf]
			gtk_container_foreach widget as-integer :remove-entry widget
			init-text-list widget as red-block! data selected
			gtk_widget_show widget
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
][
	;; DEBUG: print ["change-selection: " widget " (" get-symbol-name type ")" lf]

	if type <> window [
		idx: either TYPE_OF(int) = TYPE_INTEGER [int/value - 1][-1]
	]
	case [
		any [type = field type = area][
			sel: as red-pair! int
			either TYPE_OF(sel) = TYPE_NONE [
				idx: 0
				sz:  0
			][
				idx: sel/x - 1
				sz: sel/y - idx						;-- should point past the last selected char
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
	; 	type = camera [
	; 		either TYPE_OF(int) = TYPE_NONE [
	; 			toggle-preview widget false
	; 		][
	; 			select-camera widget idx
	; 			toggle-preview widget true
	; 		]
	; 	]
		type = text-list [
			select-text-list widget idx
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
	widget		[handle!]
	state		[red-logic!]
	check?		[logic!]
	/local
		value	[integer!]
][
	value: either TYPE_OF(state) <> TYPE_LOGIC [
		state/header: TYPE_LOGIC
		state/value: check?
		either check? [-1][0]
	][
		as-integer state/value								;-- returns 0/1, matches the messages
	]
	gtk_toggle_button_set_active widget as logic! value
	if value = -1 [gtk_toggle_button_set_inconsistent widget true]
]

get-flags: func [
	field		[red-block!]
	return:		[integer!]									;-- return a bit-array of all flags
	/local
		word	[red-word!]
		len		[integer!]
		sym		[integer!]
		flags	[integer!]
][
	switch TYPE_OF(field) [
		TYPE_BLOCK [
			word: as red-word! block/rs-head field
			len: block/rs-length? field
			if zero? len [return 0]
		]
		TYPE_WORD [
			word: as red-word! field
			len: 1
		]
		default [return 0]
	]
	flags: 0

	until [
		sym: symbol/resolve word/symbol
		case [
			sym = all-over	 [flags: flags or FACET_FLAGS_ALL_OVER]
			sym = resize	 [flags: flags or FACET_FLAGS_RESIZE]
			sym = no-title	 [flags: flags or FACET_FLAGS_NO_TITLE]
			sym = no-border  [flags: flags or FACET_FLAGS_NO_BORDER]
			sym = no-min	 [flags: flags or FACET_FLAGS_NO_MIN]
			sym = no-max	 [flags: flags or FACET_FLAGS_NO_MAX]
			sym = no-buttons [flags: flags or FACET_FLAGS_NO_BTNS]
			sym = modal		 [flags: flags or FACET_FLAGS_MODAL]
			sym = popup		 [flags: flags or FACET_FLAGS_POPUP]
			sym = scrollable [flags: flags or FACET_FLAGS_SCROLLABLE]
			sym = password	 [flags: flags or FACET_FLAGS_PASSWORD]
			true			 [fire [TO_ERROR(script invalid-arg) word]]
		]
		word: word + 1
		len: len - 1
		zero? len
	]
	flags
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
	g_object_set_qdata obj red-face-id1 as int-ptr! face/header
	g_object_set_qdata obj red-face-id2				face/ctx
	g_object_set_qdata obj red-face-id3 as int-ptr! face/class
	g_object_set_qdata obj red-face-id4				face/on-set
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
		size	[integer!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data

		size: block/rs-length? data

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

font-size?: func [
	font		[red-object!]
	return:		[integer!]
	/local
		values	[red-value!]
		size	[red-integer!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return default-font-size]
	values: object/get-values font
	size:	as red-integer!	values + FONT_OBJ_SIZE
	if TYPE_OF(size) <> TYPE_INTEGER [return default-font-size]
	size/value
]

update-scroller: func [
	scroller	[red-object!]
	flag		[integer!]
	/local
		parent		[red-object!]
		vertical?	[red-logic!]
		int			[red-integer!]
		values		[red-value!]
		widget		[handle!]
		nTrackPos	[integer!]
		nPos		[integer!]
		nPage		[integer!]
		nMax		[integer!]
		nMin		[integer!]
		fMask		[integer!]
		cbSize		[integer!]
][
	;values: object/get-values scroller
	;parent: as red-object! values + SCROLLER_OBJ_PARENT
	;vertical?: as red-logic! values + SCROLLER_OBJ_VERTICAL?
	;int: as red-integer! block/rs-head as red-block! (object/get-values parent) + FACE_OBJ_STATE
	;widget: as handle! int/value

	;int: as red-integer! values + flag

	;if flag = SCROLLER_OBJ_VISIBLE? [
	;	ShowScrollBar widget as-integer vertical?/value as logic! int/value
	;	exit
	;]

	;fMask: switch flag [
	;	SCROLLER_OBJ_POS [nPos: int/value SIF_POS]
	;	SCROLLER_OBJ_PAGE
	;	SCROLLER_OBJ_MAX [
	;		int: as red-integer! values + SCROLLER_OBJ_PAGE
	;		nPage: int/value
	;		int: as red-integer! values + SCROLLER_OBJ_MAX
	;		nMin: 1
	;		nMax: int/value
	;	 	SIF_RANGE or SIF_PAGE
	;	]
	;	default [0]
	;]

	;if fMask <> 0 [
	;	fMask: fMask or SIF_DISABLENOSCROLL
	;	cbSize: size? tagSCROLLINFO
	;	SetScrollInfo widget as-integer vertical?/value as tagSCROLLINFO :cbSize yes
	;]
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
		len		[integer!]
		sym		[integer!]
		cur		[c-string!]
		hcur	[handle!]
		pixbuf	[handle!]
		display	[handle!]
		x		[integer!]
		y		[integer!]
][
	if TYPE_OF(options) = TYPE_BLOCK [
		word: as red-word! block/rs-head options
		len: block/rs-length? options
		if len % 2 <> 0 [exit]
		while [len > 0][
			sym: symbol/resolve word/symbol
			case [
				sym = _cursor [
					w: word + 1
					display: gtk_widget_get_display widget
					either TYPE_OF(w) = TYPE_IMAGE [
						img: as red-image! w
						pixbuf: OS-image/to-pixbuf img 0 0
						x: IMAGE_WIDTH(img/size) / 2
						y: IMAGE_HEIGHT(img/size) / 2
						hcur: gdk_cursor_new_from_pixbuf display pixbuf x y
						;g_object_unref pixbuf
					][
						sym: symbol/resolve w/symbol
						cur: case [
							sym = _I-beam	["text"]
							sym = _hand		["grab"]
							sym = _cross	["crosshair"]
							true			["default"]
						]
						hcur: gdk_cursor_new_from_name display cur
					]
					SET-CURSOR(widget hcur)
				]
				true [0]
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
	]
]

OS-show-window: func [
	widget		[integer!]
][
	show-widget as handle! widget
	set-selected-focus as handle! widget
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
		value		[integer!]
		fvalue		[float!]
		vertical?	[logic!]
		rfvalue		[red-float!]
		attrs		[handle!]
		newF?		[logic!]
		handle		[handle!]
		fradio		[handle!]
		x			[integer!]
		y			[integer!]
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
			set-logic-state widget as red-logic! data no
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
		sym = button [
			widget: gtk_button_new_with_label caption
			if TYPE_OF(img) = TYPE_IMAGE [
				change-image widget img sym
			]
		]
		sym = base [
			widget: gtk_layout_new null null
			gtk_layout_set_size widget size/x size/y
		]
		sym = rich-text [
			widget: gtk_layout_new null null
			gtk_layout_set_size widget size/x size/y
			container: gtk_scrolled_window_new null null
			gtk_container_add container widget
		]
		sym = window [
			widget: gtk_window_new 0

			if bits and FACET_FLAGS_MODAL <> 0 [
				gtk_window_set_modal widget yes
			]
			unless null? caption [gtk_window_set_title widget caption]

			winbox: gtk_box_new GTK_ORIENTATION_VERTICAL  0
			gtk_container_add widget winbox
			if menu-bar? menu window [
				hMenu: gtk_menu_bar_new
				gtk_widget_show hMenu
				build-menu menu hMenu widget
				gtk_box_pack_start winbox hMenu no yes 0
			]
			gtk_widget_show winbox
			container: gtk_layout_new null null
			gtk_layout_set_size container size/x size/y
			gtk_widget_show container
			gtk_box_pack_start winbox container yes yes 0
			gtk_window_move widget offset/x offset/y

			;; The following line really matters to fix the initial size of the window
			gtk_widget_set_size_request widget size/x size/y
			gtk_window_set_resizable widget (bits and FACET_FLAGS_RESIZE <> 0)
			either any [
				bits and FACET_FLAGS_NO_TITLE <> 0
				bits and FACET_FLAGS_NO_BORDER <> 0
			][
				gtk_window_set_decorated widget no
			][
				gtk_window_set_decorated widget yes
			]
		]
		sym = camera [
			widget: gtk_layout_new null null
			gtk_layout_set_size widget size/x size/y
		]
		sym = slider [
			vertical?: size/y > size/x
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
			;; gtk_label_set_width_chars widget ???
			container: gtk_event_box_new null null
			gtk_container_add container widget
		]
		sym = field [
			widget: gtk_entry_new
			buffer: gtk_entry_get_buffer widget
			unless null? caption [
				gtk_entry_buffer_set_text buffer caption -1
			]
			gtk_entry_set_width_chars widget size/x / font-size? font
			set-hint-text widget as red-block! values + FACE_OBJ_OPTIONS
			if bits and FACET_FLAGS_PASSWORD <> 0 [gtk_entry_set_visibility widget no]
			gtk_entry_set_has_frame widget (bits and FACET_FLAGS_NO_BORDER = 0)
		]
		sym = progress [
			widget: gtk_progress_bar_new
			if size/y > size/x [
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
			gtk_frame_set_shadow_type widget 3
			gtk_frame_set_label_align widget 0.5 0.5		; Todo: does not seem to work
			buffer: gtk_layout_new null null
			gtk_widget_show buffer
			gtk_container_add widget buffer
		]
		sym = panel [
			widget: gtk_layout_new null null
			gtk_layout_set_size widget size/x size/y
		]
		sym = tab-panel [
			widget: gtk_notebook_new
		]
		sym = text-list [
			widget: gtk_list_box_new
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
			;; TODO: improve it but better than nothing from now otherwise it is uggly!
			if sym = drop-down [
				value: size/x / (font-size? font)
				if value > 2 [value - 2]
				gtk_entry_set_width_chars gtk_bin_get_child widget value
			]
			gtk_combo_box_set_active widget 0
		]
		true [
			;-- search in user-defined classes
			fire [TO_ERROR(script face-type) type]
		]
	]

	unless null? container [SET-CONTAINER(widget container)]
	;-- store the face value in the extra space of the window struct
	assert TYPE_OF(face) = TYPE_OBJECT
	store-face-to-obj widget face
	make-styles-provider widget

	if all [
		sym = panel
		not null? caption
	][
		attrs: get-attrs face font
		newF?: false
		if null? attrs [
			newF?: true
			attrs: create-simple-attrs default-font-name default-font-size color
		]
		buffer: gtk_label_new caption
		gtk_widget_show buffer
		set-label-attrs buffer font attrs
		handle: gtk_label_get_layout buffer
		x: 0 y: 0
		pango_layout_get_pixel_size handle :x :y
		x: either size/x > x [size/x - x / 2][0]
		y: either size/y > y [size/y - y / 2][0]
		gtk_layout_put widget buffer x y
		if newF? [
			free-pango-attrs attrs
		]
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

	change-selection widget selected sym
	if sym <> base [change-font widget face values]
	change-enabled widget enabled?/value sym

	parse-common-opts widget face as red-block! values + FACE_OBJ_OPTIONS sym

	if TYPE_OF(rate) <> TYPE_NONE [change-rate widget rate]

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
][
	;; DEBUG: print ["OS-update-view" lf]
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
		;; DEBUG: print ["update-view rich-text" lf]
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
				;; DEBUG: print ["password flag activated for field" lf]
				gtk_entry_set_visibility widget no
			]
			gtk_entry_set_has_frame widget (flags-flags and FACET_FLAGS_NO_BORDER = 0)
		]
	]
	if flags and FACET_FLAG_DRAW  <> 0 [
		gtk_widget_queue_draw widget
		; 0
	]
	if flags and FACET_FLAG_COLOR <> 0 [
		if type <> base [
			change-color widget as red-tuple! values + FACE_OBJ_COLOR type
		]
	]
	if all [flags and FACET_FLAG_PANE <> 0 type <> tab-panel][
		change-pane widget as red-block! values + FACE_OBJ_PANE type
	]
	if flags and FACET_FLAG_RATE <> 0 [
		change-rate widget values + FACE_OBJ_RATE
	]
	if flags and FACET_FLAG_FONT <> 0 [
		if type <> base [
			change-font widget face values
		]
	]
	if flags and FACET_FLAG_PARA <> 0 [
		change-para widget face values
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
	values: object/get-values face
	flags: get-flags as red-block! values + FACE_OBJ_FLAGS

	obj: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj FONT_OBJ_PARENT]

	obj: as red-object! values + FACE_OBJ_PARA
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj PARA_OBJ_PARENT]

	;; TODO: This can be useless now!
	remove-all-timers handle

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
		offset	[red-pair!]
		ret		[red-image!]
][
	word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
	type: symbol/resolve word/symbol

	;; DEBUG: print ["OS-to-image:" get-symbol-name type lf]
	case [
		type = screen [
			win: gdk_get_default_root_window
			width: gdk_window_get_width win
			height: gdk_window_get_height win
			xwin: gdk_x11_window_get_xid win
			win: gdk_x11_window_foreign_new_for_display gdk_window_get_display win xwin
			either  null? win [ret: as red-image! none-value]
			[
				pixbuf: gdk_pixbuf_get_from_window win 0 0 width height ;screen-size-x screen-size-y; CGWindowListCreateImage 0 0 7F800000h 7F800000h 1 0 0		;-- INF
				ret: image/init-image as red-image! stack/push* OS-image/load-pixbuf pixbuf
			]
		]
		true [
			widget: face-handle? face
			;; DEBUG: print ["widget: " widget lf]
			either null? widget [ret: as red-image! none-value][
				size: as red-pair! (object/get-values face) + FACE_OBJ_SIZE
				offset: as red-pair! (object/get-values face) + FACE_OBJ_OFFSET
				win: gtk_widget_get_window widget
				either not null? win [
					;; DEBUG: print ["win: " win " size: " size/x "x" size/y " offset: " offset/x "x" offset/y lf]
					pixbuf: either type = window [
						gdk_pixbuf_get_from_window win 0 0 size/x size/y
					][
						gdk_pixbuf_get_from_window win offset/x offset/y size/x size/y
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

OS-do-draw-OLD: func [
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
		pixbuf	[int-ptr!]
		buf		[byte-ptr!]
][
	;; DEBUG: print ["OS-do-draw " image lf]
	w: IMAGE_WIDTH(image/size)
	h: IMAGE_HEIGHT(image/size)
	stride: 0
	bitmap: OS-image/lock-bitmap image yes
	data: OS-image/get-data bitmap :stride
	;stride: cairo_format_stride_for_width CAIRO_FORMAT_ARGB32 w
	surf: cairo_image_surface_create_for_data as byte-ptr! data CAIRO_FORMAT_ARGB32 w h stride
	cr: cairo_create surf
	do-draw cr null cmds no yes yes yes
	cairo_destroy cr
	cairo_surface_destroy surf
	OS-image/buffer-argb-to-abgr data w h
	OS-image/unlock-bitmap image bitmap
]

OS-draw-face: func [
	ctx			[draw-ctx!]
	cmds		[red-block!]
][
	if TYPE_OF(cmds) = TYPE_BLOCK [
		catch RED_THROWN_ERROR [parse-draw ctx cmds yes]
	]
	if system/thrown = RED_THROWN_ERROR [system/thrown: 0]
]