Red/System [
	Title:	"GTK3 GUI backend"
	Author: "Qingtian Xie"
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

#include %font.reds
#include %para.reds
#include %draw.reds

#include %handlers.reds

GTKApp:			as handle! 0
GTKApp-Ctx: 	0
exit-loop:		0
red-face-id:	0

log-pixels-x:	0
log-pixels-y:	0
screen-size-x:	0
screen-size-y:	0

get-face-values: func [
	handle	[integer!]
	return: [red-value!]
][
	null
]

get-node-values: func [
	node	[node!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		s	 [series!]
][
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset
]

get-node-facet: func [
	node	[node!]
	facet	[integer!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		s	 [series!]
][
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset + facet
]

get-face-flags: func [
	face	[handle!]
	return: [integer!]
][
	0
]

get-face-handle: func [
	face	[red-object!]
	return: [handle!]
	/local
		state [red-block!]
		int	  [red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	assert TYPE_OF(state) = TYPE_BLOCK
	int: as red-integer! block/rs-head state
	assert TYPE_OF(int) = TYPE_INTEGER
	as handle! int/value
]

get-child-from-xy: func [
	parent	[handle!]
	x		[integer!]
	y		[integer!]
	return: [integer!]
	/local
		hWnd [handle!]
][
0
]

get-text-size: func [
	str		[red-string!]
	hFont	[handle!]
	pair	[red-pair!]
	return: [tagSIZE]
	/local
		saved [handle!]
		size  [tagSIZE]
][
	size: declare tagSIZE
	if pair <> null [
		pair/x: size/width
		pair/y: size/height
	]
	size
]

to-bgr: func [
	node	[node!]
	pos		[integer!]
	return: [integer!]									;-- 00bbggrr format or -1 if not found
	/local
		color [red-tuple!]
][
	color: as red-tuple! get-node-facet node pos
	either TYPE_OF(color) = TYPE_TUPLE [
		color/array1 and 00FFFFFFh
	][
		-1
	]
]

free-handles: func [
	hWnd [integer!]
	/local
		values [red-value!]
		type   [red-word!]
		face   [red-object!]
		tail   [red-object!]
		pane   [red-block!]
		state  [red-value!]
		sym	   [integer!]
		dc	   [integer!]
][
	values: get-face-values hWnd
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [face < tail][
			;@@ TBD
			face: face + 1
		]
	]

	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

init: func [][
	GTKApp: gtk_application_new RED_GTK_APP_ID 0
	gobj_signal_connect(GTKApp "window-removed" :window-removed-event :exit-loop)

	GTKApp-Ctx: g_main_context_default
	unless g_main_context_acquire GTKApp-Ctx [
		probe "ERROR: GTK: Cannot acquire main context" halt
	]
	g_application_register GTKApp null null

	red-face-id: g_quark_from_string "red-face-id"

	screen-size-x: gdk_screen_width
	screen-size-y: gdk_screen_height
]

set-selected-focus: func [
	hWnd [integer!]
	/local
		face   [red-object!]
		values [red-value!]
		handle [handle!]
][
	values: get-face-values hWnd
	if values <> null [
		face: as red-object! values + FACE_OBJ_SELECTED
		if TYPE_OF(face) = TYPE_OBJECT [
			0;@@ TBD
		]
	]
]

set-logic-state: func [
	hWnd   [handle!]
	state  [red-logic!]
	check? [logic!]
	/local
		value [integer!]
][
	value: either TYPE_OF(state) <> TYPE_LOGIC [
		state/header: TYPE_LOGIC
		state/value: check?
		either check? [-1][0]
	][
		as-integer state/value							;-- returns 0/1, matches the messages
	]
	gtk_toggle_button_set_active hWnd as logic! value
	if value = -1 [gtk_toggle_button_set_inconsistent hWnd true]
]

get-flags: func [
	field	[red-block!]
	return: [integer!]									;-- return a bit-array of all flags
	/local
		word  [red-word!]
		len	  [integer!]
		sym	  [integer!]
		flags [integer!]
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
			true			 [fire [TO_ERROR(script invalid-arg) word]]
		]
		word: word + 1
		len: len - 1
		zero? len
	]
	flags
]

get-position-value: func [
	pos		[red-float!]
	maximun [integer!]
	return: [integer!]
	/local
		f	[float!]
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

get-screen-size: func [
	id		[integer!]									;@@ Not used yet
	return: [red-pair!]
][
	pair/push screen-size-x screen-size-y
]

store-face-to-obj: func [
	obj		[handle!]
	face	[red-object!]
	/local
		storage [red-value!]
][
	storage: as red-value! allocate 16					;@@ should delete it when destory widget
	copy-cell as cell! face storage
	g_object_set_qdata obj red-face-id as int-ptr! storage
]

OS-refresh-window: func [hWnd [integer!]][0]

OS-show-window: func [
	hWnd	[integer!]
][
	gtk_widget_show_all as handle! hWnd
	gtk_widget_grab_focus as handle! hWnd
]

OS-make-view: func [
	face	[red-object!]
	parent	[integer!]
	return: [integer!]
	/local
		values	  [red-value!]
		type	  [red-word!]
		str		  [red-string!]
		tail	  [red-string!]
		offset	  [red-pair!]
		size	  [red-pair!]
		data	  [red-block!]
		int		  [red-integer!]
		img		  [red-image!]
		menu	  [red-block!]
		show?	  [red-logic!]
		open?	  [red-logic!]
		selected  [red-integer!]
		para	  [red-object!]
		flags	  [integer!]
		bits	  [integer!]
		sym		  [integer!]
		caption   [c-string!]
		len		  [integer!]
		widget	  [handle!]
		container [handle!]
		value	  [integer!]
		vertical? [logic!]
][
	stack/mark-func words/_body

	values: object/get-values face

	type:	  as red-word!		values + FACE_OBJ_TYPE
	str:	  as red-string!	values + FACE_OBJ_TEXT
	offset:   as red-pair!		values + FACE_OBJ_OFFSET
	size:	  as red-pair!		values + FACE_OBJ_SIZE
	show?:	  as red-logic!		values + FACE_OBJ_VISIBLE?
	open?:	  as red-logic!		values + FACE_OBJ_ENABLE?
	data:	  as red-block!		values + FACE_OBJ_DATA
	img:	  as red-image!		values + FACE_OBJ_IMAGE
	menu:	  as red-block!		values + FACE_OBJ_MENU
	selected: as red-integer!	values + FACE_OBJ_SELECTED
	para:	  as red-object!	values + FACE_OBJ_PARA

	sym: 	  symbol/resolve type/symbol

	caption: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][
		null
	]

	case [
		sym = check [
			widget: gtk_check_button_new_with_label caption
			set-logic-state widget as red-logic! data no
			gobj_signal_connect(widget "clicked" :button-clicked null)
			gobj_signal_connect(widget "toggled" :button-toggled face/ctx)
		]
		sym = button [
			widget: gtk_button_new_with_label caption
			gobj_signal_connect(widget "clicked" :button-clicked null)
		]
		sym = base [
			widget: gtk_drawing_area_new
			gobj_signal_connect(widget "draw" :base-draw face/ctx)
		]
		sym = window [
			widget: gtk_application_window_new GTKApp
			unless null? caption [gtk_window_set_title widget caption]
			gtk_window_set_default_size widget size/x size/y
			gtk_container_add widget gtk_fixed_new
			gtk_window_move widget offset/x offset/y
			gobj_signal_connect(widget "delete-event" :window-delete-event null)
		]
		sym = slider [
			vertical?: size/y > size/x
			value: either vertical? [size/y][size/x]
			widget: gtk_scale_new_with_range vertical? 0.0 as float! value 1.0
			value: get-position-value as red-float! data value
			if vertical? [value: size/y - value]
			gtk_range_set_value widget as float! value
			gtk_scale_set_has_origin widget no
			gtk_scale_set_draw_value widget no
			; insert value-changed handler
			gobj_signal_connect(widget "value-changed" :value-changed face/ctx)
		]
		true [
			;-- search in user-defined classes
			fire [TO_ERROR(script face-type) type]
		]
	]

	if all [
		sym <> window
		parent <> 0
	][
		gtk_widget_set_size_request widget size/x size/y
		container: gtk_container_get_children as handle! parent
		gtk_fixed_put as handle! container/value widget offset/x offset/y
	]

	;-- store the face value in the extra space of the window struct
	assert TYPE_OF(face) = TYPE_OBJECT					;-- detect corruptions caused by CreateWindow unwanted events
	store-face-to-obj widget face

	stack/unwind
	as-integer widget
]

OS-update-view: func [
	face [red-object!]
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
		hWnd	[integer!]
		flags	[integer!]
		type	[integer!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	values: s/offset

	state: as red-block! values + FACE_OBJ_STATE
	word: as red-word! values + FACE_OBJ_TYPE
	type: symbol/resolve word/symbol
	s: GET_BUFFER(state)
	int: as red-integer! s/offset
	hWnd: int/value
	int: int + 1
	flags: int/value

	;if flags and FACET_FLAG_OFFSET <> 0 [
	;	change-offset hWnd as red-pair! values + FACE_OBJ_OFFSET type
	;]
	;if flags and FACET_FLAG_SIZE <> 0 [
	;	change-size hWnd as red-pair! values + FACE_OBJ_SIZE type
	;]
	;if flags and FACET_FLAG_TEXT <> 0 [
	;	change-text hWnd values type
	;]
	;if flags and FACET_FLAG_DATA <> 0 [
	;	change-data	as handle! hWnd values
	;]
	;if flags and FACET_FLAG_ENABLE? <> 0 [
	;	change-enabled as handle! hWnd values
	;]
	;if flags and FACET_FLAG_VISIBLE? <> 0 [
	;	bool: as red-logic! values + FACE_OBJ_VISIBLE?
	;	change-visible hWnd bool/value type
	;]
	;if flags and FACET_FLAG_SELECTED <> 0 [
	;	int2: as red-integer! values + FACE_OBJ_SELECTED
	;	change-selection hWnd int2 values
	;]
	;if flags and FACET_FLAG_FLAGS <> 0 [
	;	SetWindowLong
	;		as handle! hWnd
	;		wc-offset + 16
	;		get-flags as red-block! values + FACE_OBJ_FLAGS
	;]
	if flags and FACET_FLAG_DRAW  <> 0 [
		gtk_widget_queue_draw as handle! hWnd
	]
	;if flags and FACET_FLAG_COLOR <> 0 [
	;	either type = base [
	;		update-base as handle! hWnd null null values
	;	][
	;		InvalidateRect as handle! hWnd null 1
	;	]
	;]
	;if flags and FACET_FLAG_PANE <> 0 [
	;	if tab-panel <> type [				;-- tab-panel/pane has custom z-order handling
	;		update-z-order 
	;			as red-block! values + gui/FACE_OBJ_PANE
	;			null
	;	]
	;]
	;if flags and FACET_FLAG_FONT <> 0 [
	;	set-font as handle! hWnd face values
	;	InvalidateRect as handle! hWnd null 1
	;]
	;if flags and FACET_FLAG_PARA <> 0 [
	;	update-para face 0
	;	InvalidateRect as handle! hWnd null 1
	;]
	;if flags and FACET_FLAG_MENU <> 0 [
	;	menu: as red-block! values + FACE_OBJ_MENU
	;	if menu-bar? menu window [
	;		DestroyMenu GetMenu as handle! hWnd
	;		SetMenu as handle! hWnd build-menu menu CreateMenu
	;	]
	;]
	;if flags and FACET_FLAG_IMAGE <> 0 [
	;	change-image hWnd values type
	;]

	int/value: 0										;-- reset flags
]

OS-destroy-view: func [
	face   [red-object!]
	empty? [logic!]
	/local
		handle [integer!]
		values [red-value!]
		obj	   [red-object!]
		flags  [integer!]
][
	handle: as-integer get-face-handle face
	values: object/get-values face
	flags: get-flags as red-block! values + FACE_OBJ_FLAGS
	if flags and FACET_FLAGS_MODAL <> 0 [
		0
		;;TBD
		;SetActiveWindow GetWindow handle GW_OWNER
	]

	free-handles handle

	obj: as red-object! values + FACE_OBJ_FONT
	;if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj FONT_OBJ_PARENT]
	
	obj: as red-object! values + FACE_OBJ_PARA
	;if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj PARA_OBJ_PARENT]
	
]

OS-update-facet: func [
	face   [red-object!]
	facet  [red-word!]
	value  [red-value!]
	action [red-word!]
	new	   [red-value!]
	index  [integer!]
	part   [integer!]
	/local
		word [red-word!]
		sym	 [integer!]
		type [integer!]
		hWnd [handle!]
][
	sym: symbol/resolve facet/symbol
	
	case [
		sym = facets/pane [0]
		sym = facets/data [0]
		true [OS-update-view face]
	]
]

OS-to-image: func [
	face	[red-object!]
	return: [red-image!]
	/local
		hWnd 	[handle!]
		dc		[handle!]
		mdc		[handle!]
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		bmp		[handle!]
		bitmap	[integer!]
		img		[red-image!]
		word	[red-word!]
		type	[integer!]
		size	[red-pair!]
		screen? [logic!]
][
	as red-image! none-value
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
][
	do-draw null img cmds no no no no
]
