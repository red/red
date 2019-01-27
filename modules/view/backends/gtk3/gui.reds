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

;#include %gdkkeysyms.reds
#include %handlers.reds
#include %comdlgs.reds

GTKApp:			as handle! 0
GTKApp-Ctx: 	0
exit-loop:		0

red-face-id:	0
_widget-id:		1
gtk-fixed-id:	2
red-timer-id:	3
css-id:			4
size-id:		5

gtk-style-id:	0

group-radio:	as handle! 0
tabs: context [
	nb: 	0
	cur: 	0
]
; used to save old position of pointer in widget-motion-notify-event handler
motion: context [
	state:		no
	x_root:		0.0
	y_root:		0.0
	x_new:	 	0
	y_new:		0
	cpt:		0
	sensitiv:	3
]
; to put in other place (usually platform.red) if useful
_drag-on:		symbol/make "drag-on"
_on-over:		word/load "on-over"

pango-context:	as handle! 0
gtk-font:		"Sans 10"
default-font:	0

; Do not KNOW about this one 
;;;main-window:	as handle! 0

; Temporary, will be removed...
last-widget:	as handle! 0

log-pixels-x:	0
log-pixels-y:	0
screen-size-x:	0
screen-size-y:	0

get-face-object: func [
	handle	[handle!]
	return: [red-object!]
	/local
		face	[red-object!]
		qdata	[handle!]
][
	face: as red-object! 0
	unless null? handle [
		qdata: g_object_get_qdata handle red-face-id
		unless null? qdata [
			face: as red-object! qdata
		]
	]
	face
]

get-face-values: func [
	handle	[handle!]
	return: [red-value!]
	/local
		face	[red-object!]
		qdata	[handle!]
		values	[red-value!]
][
	values: as red-value! 0
	unless null? handle [
		qdata: g_object_get_qdata handle red-face-id
		unless null? qdata [
			face: as red-object! qdata
			values: object/get-values face
		]
	]
	values
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

face-handle?: func [
	face	[red-object!]
	return: [handle!]									;-- returns NULL is no handle
	/local
		state [red-block!]
		int	  [red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		if TYPE_OF(int) = TYPE_HANDLE [return as handle! int/value]
	]
	null
]

get-widget-symbol: func [
    widget    [handle!]
    return:    [integer!]
    /local
        type    [red-word!]
		values	[red-value!]
][
	values: get-face-values widget
    type: as red-word! values + FACE_OBJ_TYPE
    symbol/resolve type/symbol
]

get-widget-data: func [
    widget    [handle!]
    return:    [red-block!]
	/local
		values	[red-value!]
][
	values: get-face-values widget
    as red-block! values + FACE_OBJ_DATA
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
	face    [red-object!]
	str		[red-string!]
	hFont	[handle!]
	pair	[red-pair!]
	return: [tagSIZE]
	/local
		text	[c-string!]
		len		[integer!]
		width	[integer!]
		height	[integer!]
		pl		[handle!]
		size	[tagSIZE]
		df		[c-string!]
		pc 		[handle!]
		widget	[handle!]
][
	if null? pango-context [pango-context: gdk_pango_context_get]
	size: declare tagSIZE

	text: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][
		null
	]

	width: 0 height: 0

	;;; get pango_context
	;  from widget first
	widget: face-handle? face
	pc: gtk_widget_get_pango_context widget
	pl: pango_layout_new pc ;seems more natural than pango-context
	; globally otherwise
	if null? pl [pl: pango_layout_new pango-context]
	 

	pango_layout_set_text pl text -1
	pango_layout_set_font_description pl hFont
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
	hWnd [handle!]
	values [red-value!]
	/local
		type   [red-word!]
		rate   [red-value!]
		state  [red-value!]
		sym	   [integer!]
][
	;type: as red-word! values + FACE_OBJ_TYPE
	;sym: symbol/resolve type/symbol

	rate: values + FACE_OBJ_RATE
	if TYPE_OF(rate) <> TYPE_NONE [change-rate hWnd none-value]
	gtk_widget_destroy hWnd
	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

; Debug function to show children tree
debug-show-children: func [
	hWnd 	[handle!]
	parent? [logic!]
	/local
		widget		[handle!]
		child		[handle!]
		container	[handle!]
		rect 		[tagRECT]
		sx			[integer!]
		sy			[integer!]
		offset		[red-pair!]
		size		[red-pair!]
		pane 		[red-block!]
		type		[red-word!]
		sym			[integer!]
		face 		[red-object!]
		tail 		[red-object!]
		values		[red-value!]
		overlap?	[logic!]
		; these ones would be removed
		debug		[logic!]
		cpt 		[integer!]
][
	; to remove when saitsfactory enough development
	debug: yes

	values: get-face-values hWnd
	type: 	as red-word! values + FACE_OBJ_TYPE
	pane: 	as red-block! values + FACE_OBJ_PANE

	either parent? [
		face: 	as red-object! values + FACE_OBJ_PARENT
		either TYPE_OF(face) = TYPE_NONE [
			print-line "parent face: none"
			print ["parent handle: " hWnd lf]
		][
			values: object/get-values face
			type: 	as red-word! values + FACE_OBJ_TYPE
			pane: 	as red-block! values + FACE_OBJ_PANE
			widget: face-handle? face
			print ["from parent handle: " widget lf]
		]
	][print ["parent handle: " hWnd lf]]

	sym: 	symbol/resolve type/symbol

	rect: 	as tagRECT allocate (size? tagRECT)
	
	if all [TYPE_OF(pane) = TYPE_BLOCK 0 <> block/rs-length? pane] [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		if debug [print ["Pane type: " get-symbol-name sym lf]]
		if TYPE_OF(face) <> TYPE_OBJECT [print-line "not face object"]
		widget: face-handle? face
		
		either null? widget [print-line "null container" container: null][container: g_object_get_qdata widget gtk-fixed-id]
		print ["container handle: " container lf]
		
		 sx: 0 sy: 0
		cpt: 0
		while [face < tail][
			cpt: cpt + 1
			print-line cpt
			child: face-handle? face
			print ["child handle: " child lf]
			values: object/get-values face
			offset: as red-pair! values + FACE_OBJ_OFFSET
			size: as red-pair! values + FACE_OBJ_SIZE
			type: 	as red-word! values + FACE_OBJ_TYPE
			sym: 	symbol/resolve type/symbol
			 
			if debug [print ["Child" cpt " type: " get-symbol-name sym lf]]
			; if next widget is on the right of the previous one or there is no overlapping dx becomes 0 
		
			unless null? container [	
				widget: g_object_get_qdata child _widget-id
				if null? widget [widget: child]

				gtk_widget_get_allocation widget as handle! rect
				; rmk: rect/x and rect/y are absolute coordinates when offset/x and offset/y are relative coordinates
				if debug [ print ["widget->rect:" rect/x "x" rect/y  "x" rect/width "x" rect/height lf]]
			] 
			if debug [print ["red->rect:" offset/x "x" offset/y  "x" size/x "x" size/y lf]]
			either null? child [print-line "null child"][debug-show-children child no]
			face: face + 1
		]
		if debug [print-line "Pane end"]
	]
	free as byte-ptr! rect
]

init: func [][
	GTKApp: gtk_application_new RED_GTK_APP_ID G_APPLICATION_NON_UNIQUE
	gobj_signal_connect(GTKApp "window-removed" :window-removed-event :exit-loop)

	GTKApp-Ctx: g_main_context_default
	unless g_main_context_acquire GTKApp-Ctx [
		probe "ERROR: GTK: Cannot acquire main context" halt
	]
	g_application_register GTKApp null null

	red-face-id: g_quark_from_string "red-face-id"
	gtk-style-id: g_quark_from_string "gtk-style-id"

	screen-size-x: gdk_screen_width
	screen-size-y: gdk_screen_height

]

get-symbol-name: function [
	sym 	[integer!]
	return: [c-string!]
][
	case [
		sym = check ["check"]
		sym = radio ["radio"] 
		sym = button ["button"]
		sym = base  ["base"]
		sym = window ["window"]
		sym = slider ["slider"]
		sym = text ["text"]
		sym = field ["field"]
		sym = progress ["progress"]
		sym = area ["area"]
		sym = group-box ["group-box"]
		sym = panel ["panel"]
		sym = tab-panel ["tab-panel"]
		sym = text-list ["text-list"]
		sym = drop-list ["drop-list"]
		sym = drop-down ["drop-down"]
		true ["other widget"]
	]
]
; this adjustment is supposed to fix only horizontally consecutive widgets in the same pane  
adjust-sizes: func [
	hWnd 	[handle!]
	/local
		widget		[handle!]
		child		[handle!]
		container	[handle!]
		rect 		[tagRECT]
		dx			[integer!]
		dy			[integer!]
		ox			[integer!]
		oy			[integer!]
		sx			[integer!]
		sy			[integer!]
		offset		[red-pair!]
		size		[red-pair!]
		pane 		[red-block!]
		type		[red-word!]
		sym			[integer!]
		face 		[red-object!]
		tail 		[red-object!]
		values		[red-value!]
		overlap?	[logic!]
		; these ones would be removed
		debug		[logic!]
		cpt 		[integer!]
][
	; to remove when satisfactory enough development
	debug: no

	values: get-face-values hWnd
	type: 	as red-word! values + FACE_OBJ_TYPE
	pane: 	as red-block! values + FACE_OBJ_PANE

	sym: 	symbol/resolve type/symbol

	rect: 	as tagRECT allocate (size? tagRECT)
	
	if all [TYPE_OF(pane) = TYPE_BLOCK 0 <> block/rs-length? pane] [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		if debug [print ["Parent type: " get-symbol-name sym lf]]
		child: face-handle? face
		container: either null? child [null][g_object_get_qdata child gtk-fixed-id]
		dx: 0 dy: 0
		ox: 0 oy: 0 sx: 0 sy: 0
		cpt: 0
		while [face < tail][
			cpt: cpt + 1
			child: face-handle? face
			unless null? child [
				values: object/get-values face
				offset: as red-pair! values + FACE_OBJ_OFFSET
				size: as red-pair! values + FACE_OBJ_SIZE
				type: 	as red-word! values + FACE_OBJ_TYPE
				sym: 	symbol/resolve type/symbol
				overlap?: all [ox + dx + sx > offset/x oy + sy > offset/y] 
				if debug [print ["Child" cpt " type: " get-symbol-name sym lf]]
				; if next widget is on the right of the previous one or there is no overlapping dx becomes 0 
				if any [ox > offset/x not overlap?] [dx: 0]
				unless null? container [	
					widget: g_object_get_qdata child _widget-id
					if null? widget [widget: child]
					if debug [ print ["move child: " offset/x "+" dx "("  offset/x + dx ")" " " offset/y lf]]
					gtk_fixed_move container widget offset/x + dx  offset/y
					gtk_widget_get_allocation widget as handle! rect
					; rmk: rect/x and rect/y are absolute coordinates when offset/x and offset/y are relative coordinates
					if debug [ print ["widget->rect:" rect/x "x" rect/y  "x" rect/width "x" rect/height lf]]
				]
				; save previous offset and size coordinates
				ox: offset/x oy: offset/y sx: size/x sy: size/y 
				if debug [print ["red->rect:" offset/x "x" offset/y  "x" size/x "x" size/y lf]]
				dx: dx + rect/width - sx
				dy: dy + rect/height - sy
				if debug [ print ["next dx: " dx lf]]
				adjust-sizes child
			]
			face: face + 1
		]
		if debug [print-line "Pane end"]
	]
	free as byte-ptr! rect
]

change-rate: func [
	hWnd [handle!]
	rate [red-value!]
	/local
		int		[red-integer!]
		tm		[red-time!]
		ts		[integer!]
		timer	[integer!]
		data	[handle!]
][
	unless null? hWnd [
		data: g_object_get_qdata hWnd red-timer-id
		timer: either null? data [0][as integer! data]

		if timer <> 0 [								;-- cancel a preexisting timeout
			g_source_remove timer
			g_object_set_qdata hWnd red-timer-id null
		]

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
			]
			TYPE_NONE [exit]
			default	  [fire [TO_ERROR(script invalid-facet-type) rate]]
		]

		timer: g_timeout_add ts as integer! :red-timer-action hWnd
		g_object_set_qdata hWnd red-timer-id as int-ptr! timer
	]
]

change-image: func [
	hWnd	[handle!]
	image	[red-image!]
	type	[integer!]
	/local
		img	 [handle!]
][
	case [
		; type = camera [
		; 	snap-camera hWnd
		; 	until [TYPE_OF(image) = TYPE_IMAGE]			;-- wait
		; ]
		any [type = button type = check type = radio][
			if TYPE_OF(image) = TYPE_IMAGE [
				img: gtk_image_new_from_pixbuf as handle! OS-image/to-pixbuf image
				gtk_button_set_image hWnd img
			]
		]
	]
]

change-color: func [
	hWnd	[handle!]
	color	[red-tuple!]
	type	[integer!]
	/local
		clr  [integer!]
		set? [logic!]
		t	 [integer!]
][
	t: TYPE_OF(color)
	if all [t <> TYPE_NONE t <> TYPE_TUPLE][exit]
	; if transparent-color? color [
	; 	objc_msgSend [hWnd sel_getUid "setDrawsBackground:" no]
	; 	exit
	; ]
	; set?: yes
	case [
	; 	type = area [
	; 		hWnd: objc_msgSend [hWnd sel_getUid "documentView"]
	; 		clr: either t = TYPE_NONE [00FFFFFFh][color/array1]
	; 		set-caret-color hWnd clr
	; 		if t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "textBackgroundColor"]]
	; 	]
		type = text [
	; 		if t = TYPE_NONE [
	; 			clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "controlColor"]
	; 			set?: no
	; 		]
	; 		objc_msgSend [hWnd sel_getUid "setDrawsBackground:" set?]
		]
	; 	any [type = check type = radio][
	; 		hWnd: objc_msgSend [hWnd sel_getUid "cell"]
	; 		if t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "controlColor"]]
	; 	]
	; 	type = field [
	; 		if t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "textBackgroundColor"]]
	; 	]
	; 	type = window [
	; 		if t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "windowBackgroundColor"]]
	; 	]
	; 	true [
	; 		set?: no
	; 		objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
	; 	]
	]
	; if set? [
	; 	if t = TYPE_TUPLE [clr: to-NSColor color]
	; 	objc_msgSend [hWnd sel_getUid "setBackgroundColor:" clr]
	; ]
	0
]

update-z-order: func [
	parent	[handle!]
	pane	[red-block!]
	type	[integer!]
	/local
		face [red-object!]
		tail [red-object!]
		hWnd [handle!]
		parr [int-ptr!]
		arr  [integer!]
		nb   [integer!]
		s	 [series!]
][
	s: GET_BUFFER(pane)
	face: as red-object! s/offset + pane/head
	tail: as red-object! s/tail
	nb: (as-integer tail - face) >> 4

	parr: as int-ptr! allocate nb * 4
	nb: 0
	while [face < tail][
		if TYPE_OF(face) = TYPE_OBJECT [
			hWnd: face-handle? face
			if hWnd <> null [
				nb: nb + 1
				parr/nb: as-integer hWnd
			]
		]
		face: face + 1
	]
	; arr: objc_msgSend [
	; 	objc_getClass "NSArray"
	; 	sel_getUid "arrayWithObjects:count:"
	; 	parr nb
	; ]
	; free as byte-ptr! parr
	; if type = window [parent: objc_msgSend [parent sel_getUid "contentView"]]
	; objc_msgSend [parent sel_getUid "setSubviews:" arr]
0
]

change-font: func [
	hWnd	[handle!]
	face	[red-object!]
	font	[red-object!]
	type	[integer!]
	return: [logic!]
	/local
		css		 [c-string!]
		provider [handle!]
		hFont	[handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return no]

	provider: get-styles-provider hWnd

	;; update the style (including font color) gtk_css_provider is much more easier to apply than older interface to manage all the styles
	css: ""
	css: css-styles face font

	;; DEBUG: print ["change-font ccs: " css lf]

	gtk_css_provider_load_from_data provider css -1 null

	;; Update the pango_font_description hFont (directly used by get-text-size)
	make-font face font
	
	yes
]

change-offset: func [
	hWnd [handle!]
	pos  [red-pair!]
	type [integer!]
	/local
		container 	[handle!]
		_widget		[handle!]
][
	;; DEBUG: print ["change-offset type: " get-symbol-name get-widget-symbol hWnd lf]
	either type = window [
		0
	][
		;OS-refresh-window as integer! main-window
		container: either null? hWnd [null][g_object_get_qdata hWnd gtk-fixed-id]
		;; DEBUG: print ["change-offset by" pos lf]
		; _widget: either type = text [
		; 	g_object_get_qdata hWnd _widget-id
		; ][hWnd]
		_widget: g_object_get_qdata hWnd _widget-id
		_widget: either null? _widget [hWnd][_widget]
		unless null? container [
			gtk_fixed_move container _widget pos/x pos/y
			gtk_widget_queue_draw _widget
		]
	]
]

change-size: func [
	hWnd [handle!]
	size [red-pair!]
	type [integer!]
	/local
		_widget	[handle!]
][
	;; DEBUG: print ["change-size" get-symbol-name get-widget-symbol hWnd size lf]
	either type = window [
		gtk_window_set_default_size hWnd size/x size/y
	 ][
		_widget: g_object_get_qdata hWnd _widget-id
		_widget: either null? _widget [hWnd][_widget]
		gtk_widget_set_size_request _widget size/x size/y
		gtk_widget_queue_draw _widget
	]
]

change-visible: func [
	hWnd  [handle!]
	show? [logic!]
	type  [integer!]
][
	case [
		type = window [
			; either show? [
			; 	objc_msgSend [hWnd sel_getUid "makeKeyAndOrderFront:" hWnd]
			; ][
			; 	objc_msgSend [hWnd sel_getUid "orderOut:" hWnd]
			; ]
			0
		]
		true [gtk_widget_set_visible hWnd show?]
	]
]

change-enabled: func [
	hWnd	 [handle!]
	enabled? [logic!]
	type	 [integer!]
	/local
		obj  [integer!]
][
	gtk_widget_set_sensitive hWnd enabled?
]

change-text: func [
	hWnd	[handle!]
	values	[red-value!]
	face	[red-object!]
	type	[integer!]
	/local
		len    [integer!]
		cstr   [c-string!]
		str    [red-string!]
		buffer [handle!]
][
	if type = base [
		gtk_widget_queue_draw hWnd
		exit
	]

	str: as red-string! values + FACE_OBJ_TEXT
	cstr: switch TYPE_OF(str) [
		TYPE_STRING [len: -1 unicode/to-utf8 str :len]
		TYPE_NONE	[""]
		default		[null]									;@@ Auto-convert?
	]
	if null? cstr [exit]
	
	;unless change-font hWnd face as red-object! values + FACE_OBJ_FONT type [
		case [
			type = area [
				buffer: gtk_text_view_get_buffer hWnd
			 	gtk_text_buffer_set_text buffer cstr -1
			]
			type = text [
				gtk_label_set_text hWnd cstr
			]
			type = field [
				buffer: gtk_entry_get_buffer hWnd
				gtk_entry_buffer_set_text buffer cstr -1
			]
			any [type = button type = radio type = check] [
				gtk_button_set_label hWnd cstr
			]
			type = window [
				gtk_window_set_title hWnd cstr
			] 
			type = group-box [
				gtk_frame_set_label hWnd cstr
			]
			true [0]
		]
		gtk_widget_queue_draw hWnd
	;]
]

change-data: func [
	hWnd   [handle!]
	values [red-value!]
	/local
		data 	[red-value!]
		word 	[red-word!]
		size	[red-pair!]
		f		[red-float!]
		str		[red-string!]
		caption [c-string!]
		type	[integer!]
		len		[integer!]
][
	data: as red-value! values + FACE_OBJ_DATA
	word: as red-word! values + FACE_OBJ_TYPE
	type: word/symbol

	;;DEBUG: print ["change-data: " get-symbol-name type lf]

	case [
		all [
			type = progress
			TYPE_OF(data) = TYPE_PERCENT
		][
			f: as red-float! data
			gtk_progress_bar_set_fraction hWnd  f/value
		]
		all [
			type = slider
			TYPE_OF(data) = TYPE_PERCENT
		][
			f: as red-float! data
			size: as red-pair! values + FACE_OBJ_SIZE
			len: either size/x > size/y [size/x][size/y]
			gtk_range_set_value hWnd f/value * (as-float len)
		]
		type = check [
			set-logic-state hWnd as red-logic! data yes
		]
		type = radio [
			set-logic-state hWnd as red-logic! data no
		]
	; 	type = tab-panel [
	; 		set-tabs hWnd get-face-values hWnd
	; 	]
		all [
			type = text-list
			TYPE_OF(data) = TYPE_BLOCK
		][
			;;DEBUG: print ["text-list updated" lf]
			gtk_container_foreach hWnd as-integer :remove-entry hWnd
			init-text-list hWnd as red-block! data
			gtk_widget_show_all hWnd
		]
		any [type = drop-list type = drop-down][
			init-combo-box hWnd as red-block! data null type = drop-list
		]
		true [0]										;-- default, do nothing
	]
	0
]

change-selection: func [
	hWnd   [handle!]
	int	   [red-integer!]								;-- can be also none! | object!
	type   [integer!]
	/local
		idx [integer!]
		sz	[integer!]
		wnd [integer!]
		item [handle!]
][
	if type <> window [
		idx: either TYPE_OF(int) = TYPE_INTEGER [int/value - 1][-1]
	]
	case [
	; 	type = camera [
	; 		either TYPE_OF(int) = TYPE_NONE [
	; 			toggle-preview hWnd false
	; 		][
	; 			select-camera hWnd idx
	; 			toggle-preview hWnd true
	; 		]
	; 	]
		type = text-list [
			item: gtk_list_box_get_row_at_index hWnd idx
			gtk_list_box_select_row hWnd item
		]
		any [type = drop-list type = drop-down][
			gtk_combo_box_set_active hWnd idx
		]
	 	type = tab-panel [
			gtk_notebook_set_current_page hWnd idx
		]
	; 	type = window [
	; 		wnd: either TYPE_OF(int) = TYPE_OBJECT [
	; 			as-integer face-handle? as red-object! int
	; 		][0]
	; 		objc_msgSend [hWnd sel_getUid "makeFirstResponder:" wnd]
	; 	]
	 	true [0]										;-- default, do nothing
	]
]

set-selected-focus: func [
	hWnd [handle!]
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

get-fraction-value: func [
	pos		[red-float!]
	return: [float!]
	/local
		f	[float!]
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

init-combo-box: func [
	combo		[handle!]
	data		[red-block!]
	caption		[c-string!]
	drop-list?	[logic!] ;to remove if unused
	/local
		str	 [red-string!]
		tail [red-string!]
		len  [integer!]
		val  [c-string!]
		size [integer!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data

		size: block/rs-length? data
		print ["combo-size: " size lf]

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

	;len: objc_msgSend [combo sel_getUid "numberOfItems"]
	;if zero? len [objc_msgSend [combo sel_getUid "setStringValue:" NSString("")]]

	;either drop-list? [
	;	objc_msgSend [combo sel_getUid "setEditable:" false]
	;][
	;	if caption <> 0 [
	;		objc_msgSend [combo sel_getUid "setStringValue:" caption]
	;	]
	;]
]

remove-entry: func [
	[cdecl]
	widget		[handle!]
	container	[int-ptr!]
][
	gtk_container_remove container widget
]

init-text-list: func [
	widget	 [handle!]
	data	 [red-block!]
	/local
		str		[red-string!]
		tail	[red-string!]
		val		[c-string!]
		len		[integer!]
		label	[handle!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data

		if str = tail [exit]

		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [
				len: -1
				val: unicode/to-utf8 str :len
				label: gtk_label_new val
				gtk_widget_set_halign label 1		;-- GTK_ALIGN_START
				gtk_container_add widget label
			]
			str: str + 1
		]
	]
]

update-scroller: func [
	scroller [red-object!]
	flag	 [integer!]
	/local
		parent		[red-object!]
		vertical?	[red-logic!]
		int			[red-integer!]
		values		[red-value!]
		hWnd		[handle!]
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
	;hWnd: as handle! int/value

	;int: as red-integer! values + flag

	;if flag = SCROLLER_OBJ_VISIBLE? [
	;	ShowScrollBar hWnd as-integer vertical?/value as logic! int/value
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
	;	SetScrollInfo hWnd as-integer vertical?/value as tagSCROLLINFO :cbSize yes
	;]
]

connect-mouse-events: function [
	hWnd 	[handle!]
	face 	[red-object!]
	actors	[red-object!]
	type	[integer!]
	/local
		_widget [handle!]
][
	if all [
		not null? actors/ctx
		(object/rs-find actors  as red-value!  _on-over) <> -1
	][
		_widget: either type = text [
			g_object_get_qdata hWnd _widget-id
		][hWnd]
		; OR (NOT YET TESTED but if needed for widget with _widget)
		; _widget: g_object_get_qdata hWnd _widget-id
		; _widget: either null? _widget [hWnd][_widget]

		;; DEBUG: print [ "Mouse events " get-symbol-name type "->" widget lf]
		gtk_widget_add_events _widget GDK_ENTER_NOTIFY_MASK or GDK_LEAVE_NOTIFY_MASK
		gobj_signal_connect(_widget "enter-notify-event" :widget-enter-notify-event face/ctx)
		gobj_signal_connect(_widget "leave-notify-event" :widget-leave-notify-event face/ctx)		
	] 
]



parse-common-opts: func [
	hWnd	[handle!]
	face 	[red-object!]
	options [red-block!]
	type	[integer!]
	/local
		word	[red-word!]
		w		[red-word!]
		img		[red-image!]
		bool	[red-logic!]
		len		[integer!]
		sym		[integer!]
		cur		[c-string!]
		hcur	[integer!]
		nsimg	[integer!]
		btn?	[logic!]
][
	btn?: yes
	if TYPE_OF(options) = TYPE_BLOCK [
		word: as red-word! block/rs-head options
		len: block/rs-length? options
		if len % 2 <> 0 [exit]
		while [len > 0][
			sym: symbol/resolve word/symbol
			case [
				sym = _drag-on [
					gtk_widget_add_events hWnd GDK_BUTTON_PRESS_MASK or GDK_BUTTON1_MOTION_MASK or GDK_BUTTON_RELEASE_MASK ;or GDK_ENTER_NOTIFY_MASK 
					gobj_signal_connect(hWnd "motion-notify-event" :widget-motion-notify-event face/ctx)
					gobj_signal_connect(hWnd "button-press-event" :widget-button-press-event face/ctx)
					gobj_signal_connect(hWnd "button-release-event" :widget-button-release-event face/ctx)
				]
				; sym = _cursor [
				; 	w: word + 1
				; 	either TYPE_OF(w) = TYPE_IMAGE [
				; 		img: as red-image! w
				; 		nsimg: objc_msgSend [
				; 			OBJC_ALLOC("NSImage")
				; 			sel_getUid "initWithCGImage:size:" OS-image/to-cgimage img 0 0
				; 		]
				; 		pt/x: as float32! IMAGE_WIDTH(img/size) / 2
				; 		pt/y: as float32! IMAGE_HEIGHT(img/size) / 2
				; 		hcur: objc_msgSend [
				; 			OBJC_ALLOC("NSCursor")
				; 			sel_getUid "initWithImage:hotSpot:" nsimg pt/x pt/y
				; 		]
				; 		objc_msgSend [nsimg sel_release]
				; 	][
				; 		sym: symbol/resolve w/symbol
				; 		cur: case [
				; 			sym = _I-beam	["IBeamCursor"]
				; 			sym = _hand		["pointingHandCursor"]
				; 			sym = _cross	["crosshairCursor"]
				; 			true			["arrowCursor"]
				; 		]
				; 		hcur: objc_msgSend [objc_getClass "NSCursor" sel_getUid cur]
				; 	]
				; 	if hcur <> 0 [objc_setAssociatedObject hWnd RedCursorKey hcur OBJC_ASSOCIATION_ASSIGN]
				; ]
				; sym = _class [
				; 	w: word + 1
				; 	sym: symbol/resolve w/symbol
				; 	sym: case [
				; 		sym = _regular	[0]			;-- 32
				; 		sym = _small	[1]			;-- 28
				; 		sym = _mini		[2]			;-- 16
				; 		true			[0]
				; 	]
				; 	objc_msgSend [
				; 		objc_msgSend [hWnd sel_getUid "cell"]
				; 		sel_getUid "setControlSize:" sym
				; 	]
				; 	btn?: no
				; ]
				; sym = _accelerated [
				; 	bool: as red-logic! word + 1
				; 	if bool/value [objc_msgSend [hWnd sel_getUid "setWantsLayer:" yes]]
				; ]
				true [0]
			]
			word: word + 2
			len: len - 2
		]
	]

	; if type = button [
	; 	len: either btn? [NSRegularSquareBezelStyle][NSRoundedBezelStyle]
	; 	objc_msgSend [hWnd sel_getUid "setBezelStyle:" len]
	; ]
]

OS-redraw: func [hWnd [integer!]][gtk_widget_queue_draw as handle! hWnd]

OS-refresh-window: func [hWnd [integer!]][
	;print-line "REFFRREEEESSSSHHHHH" 
	;debug-show-children main-window no
	;gtk_widget_queue_draw main-window
	OS-show-window hWnd
]

OS-show-window: func [
	hWnd	[integer!]
	; /local
	; 	auto-adjust?	[red-logic!]
][
	gtk_widget_show_all as handle! hWnd
	gtk_widget_grab_focus as handle! hWnd

	; @@ TEMPORARY: TO BE REMOVED BUT USEFUL NOW FOR COMPARING THE EFFECT OF ADJUST-SIZES IN RED TEST WITHOUT RECOMPILING CONSOLE
	;auto-adjust?: as red-logic! #get system/view/gtk-auto-adjust?
	;if all [TYPE_OF(auto-adjust?) = TYPE_LOGIC auto-adjust?/value] [
	;	adjust-sizes as handle! hWnd
	;	gtk_widget_queue_draw as handle! hWnd
	;]
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
		font	  [red-object!]
		para	  [red-object!]
		flags	  [integer!]
		bits	  [integer!]
		rate	  [red-value!]
		sym		  [integer!]
		p-sym	  [integer!]
		caption   [c-string!]
		len		  [integer!]
		widget	  [handle!]
		_widget	  [handle!]
		buffer	  [handle!]
		container [handle!]
		value	  [integer!]
		fvalue	  [float!]
		vertical? [logic!]
		rfvalue	  [red-float!]
][
	stack/mark-native words/_body

	values: object/get-values face

	_widget: as handle! 0 ; widget version with possible scrollview

	type:	  as red-word!		values + FACE_OBJ_TYPE
	str:	  as red-string!	values + FACE_OBJ_TEXT
	offset:   as red-pair!		values + FACE_OBJ_OFFSET
	size:	  as red-pair!		values + FACE_OBJ_SIZE
	show?:	  as red-logic!		values + FACE_OBJ_VISIBLE?
	open?:	  as red-logic!		values + FACE_OBJ_ENABLED?
	data:	  as red-block!		values + FACE_OBJ_DATA
	img:	  as red-image!		values + FACE_OBJ_IMAGE
	font:	  as red-object!	values + FACE_OBJ_FONT
	menu:	  as red-block!		values + FACE_OBJ_MENU
	selected: as red-integer!	values + FACE_OBJ_SELECTED
	para:	  as red-object!	values + FACE_OBJ_PARA
	rate: 	  as red-value!		values + FACE_OBJ_RATE

	bits: 	  get-flags as red-block! values + FACE_OBJ_FLAGS
	sym: 	  symbol/resolve type/symbol

	caption: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][
		null
	]

	;;DEBUG: print ["OS-make-view " get-symbol-name sym lf]

	case [
		sym = check [
			widget: gtk_check_button_new_with_label caption
			set-logic-state widget as red-logic! data no
			;@@ No click event for check
			;gobj_signal_connect(widget "clicked" :button-clicked null)
			gobj_signal_connect(widget "toggled" :button-toggled face/ctx)
		]
		sym = radio [
			widget: either null? group-radio [
				;; DEBUG: print ["radio created: " caption lf]
				gtk_radio_button_new_with_label null caption
			][
				;; DEBUG: print ["radio group-radio created: " caption lf]
				gtk_radio_button_new_with_label_from_widget group-radio caption
			]
			set-logic-state widget as red-logic! data no
			;@@ Line below removed because it generates an error and there is no click event for radio 
			gobj_signal_connect(widget "toggled" :button-toggled face/ctx)
		]
		sym = button [
			widget: gtk_button_new_with_label caption
			gobj_signal_connect(widget "clicked" :button-clicked null)
			if TYPE_OF(img) = TYPE_IMAGE [
				change-image widget img sym
			]
		]
		sym = base [
			widget: gtk_drawing_area_new
			gobj_signal_connect(widget "draw" :base-draw face/ctx)
		]
		sym = window [
			;; DEBUG: print ["win " GTKApp lf]
			;widget: gtk_application_window_new GTKApp
			widget: gtk_window_new 0
			;; DEBUG: print ["win1 " widget lf]
			gtk_application_add_window GTKApp widget
			;; DEBUG: print ["win2 " lf]
			;; DEBUG (temporary code): main-window: widget
			unless null? caption [gtk_window_set_title widget caption]
			gtk_window_set_default_size widget size/x size/y
			gtk_container_add widget gtk_fixed_new
			gtk_window_move widget offset/x offset/y
			gobj_signal_connect(widget "delete-event" :window-delete-event null)
			gobj_signal_connect(widget "size-allocate" :window-size-allocate null)
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
			gobj_signal_connect(widget "value-changed" :range-value-changed face/ctx)
		]
		sym = text [
			widget: gtk_label_new caption
			_widget: gtk_event_box_new null null
			gtk_container_add _widget widget
			gobj_signal_connect(_widget "button-press-event" :text-button-press-event widget)
		]
		sym = field [
			widget: gtk_entry_new
			buffer: gtk_entry_get_buffer widget
			unless null? caption [gtk_entry_buffer_set_text buffer caption -1]
			gobj_signal_connect(widget "key-release-event" :field-key-release-event face/ctx)
			;Do not work: gobj_signal_connect(widget "key-press-event" :field-key-press-event face/ctx)
			gtk_widget_set_can_focus widget yes
			;This depends on version >= 3.2
			;gtk_widget_set_focus_on_click widget yes
			gobj_signal_connect(widget "move-focus" :field-move-focus face/ctx)
			gtk_entry_set_width_chars widget 0
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
			unless null? caption [gtk_text_buffer_set_text buffer caption -1]
			_widget: gtk_scrolled_window_new null null
			gtk_container_add _widget widget
			gobj_signal_connect(buffer "changed" :area-changed widget)
		]
		sym = group-box [
			widget: gtk_frame_new caption
			gtk_frame_set_shadow_type widget 3
			gtk_frame_set_label_align widget 0.5 0.5; Todo: does not seem to work
			container: gtk_fixed_new
			gtk_container_add widget container
		]
		sym = panel [
			widget: gtk_fixed_new
			unless null? caption [
				buffer: gtk_label_new caption
				gtk_container_add widget buffer
			]
		]
		sym = tab-panel [
			widget: gtk_notebook_new
			tabs/cur: 0
			tabs/nb: block/rs-length? data
			gobj_signal_connect(widget "switch-page" :tab-panel-switch-page face/ctx)
		]
		sym = text-list [
			widget: gtk_list_box_new
			init-text-list widget data
			;gtk_list_box_select_row widget gtk_list_box_get_row_at_index widget 0
			_widget: gtk_scrolled_window_new null null
			if bits and FACET_FLAGS_NO_BORDER = 0 [
				gtk_scrolled_window_set_shadow_type _widget 3
			]
			gtk_container_add _widget widget
			gobj_signal_connect(widget "selected-rows-changed" :text-list-selected-rows-changed face/ctx)
		]
		any [
			sym = drop-list
			sym = drop-down
		][
			widget: either sym = drop-list [gtk_combo_box_text_new][gtk_combo_box_text_new_with_entry]
			init-combo-box widget data caption sym = drop-list
			gtk_combo_box_set_active widget 0
			gobj_signal_connect(widget "changed" :combo-selection-changed face/ctx)
		]
		true [
			;-- search in user-defined classes
			fire [TO_ERROR(script face-type) type]
		]
	]

	parse-common-opts widget face as red-block! values + FACE_OBJ_OPTIONS sym

	; save the previous group-radio state as a global variable
	group-radio: either sym = radio [widget][as handle! 0] 

	;;DEBUG: print [ "New widget " get-symbol-name sym "->" widget lf]
	
	if all [
		sym <> window
		parent <> 0
	][
		p-sym: get-widget-symbol as handle! parent
		either null? _widget [_widget: widget][g_object_set_qdata widget _widget-id _widget ]
		; TODO: case to replace with either if no more choice
		case [
			p-sym = tab-panel [
				container: as handle! parent
				; widget is necessarily a panel and then same as _widget
				data: get-widget-data container
				str:  (as red-string! block/rs-head data) + tabs/cur
				caption: either TYPE_OF(str) = TYPE_STRING [
					len: -1
					unicode/to-utf8 str :len
				][
					"Tab"
				]
				buffer: gtk_label_new caption
				gtk_notebook_append_page container widget buffer
				tabs/cur: tabs/cur + 1
				if tabs/cur = tabs/nb [tabs/cur: 0 tabs/nb: 0]
			]
			true [
				container:  as handle! either p-sym = panel [parent][buffer: gtk_container_get_children as handle! parent buffer/value]
				;save gtk_fixed container for adjustment since size/x and size/y are not the real sizes in gtk and need to be updated in a second pass
				g_object_set_qdata widget gtk-fixed-id container
				if sym = text [g_object_set_qdata _widget gtk-fixed-id container]
				gtk_widget_set_size_request _widget size/x size/y
				gtk_fixed_put container _widget offset/x offset/y
			]
		]
	]

	connect-mouse-events widget face as red-object! values + FACE_OBJ_ACTORS sym

	;-- store the face value in the extra space of the window struct
	assert TYPE_OF(face) = TYPE_OBJECT					;-- detect corruptions caused by CreateWindow unwanted events
	store-face-to-obj widget face
	if sym = text [store-face-to-obj _widget face]

	; change-selection widget as red-integer! values + FACE_OBJ_SELECTED sym
	change-para widget face as red-object! values + FACE_OBJ_PARA font sym

	unless show?/value [change-visible widget no sym]
	unless open?/value [change-enabled widget no sym]
	
	make-styles-provider widget
		if sym <> base [
			change-font widget face font sym
		]

	if TYPE_OF(rate) <> TYPE_NONE [change-rate widget rate]
	; if sym <> base [change-color widget as red-tuple! values + FACE_OBJ_COLOR sym]

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
		widget	[handle!]
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
	widget: as handle! int/value
	int: int + 1
	flags: int/value

	if flags and FACET_FLAG_OFFSET <> 0 [
		change-offset widget as red-pair! values + FACE_OBJ_OFFSET type
	]
	if flags and FACET_FLAG_SIZE <> 0 [
		change-size widget as red-pair! values + FACE_OBJ_SIZE type
	]
	if flags and FACET_FLAG_TEXT <> 0 [
		change-text widget values face type
		gtk_widget_queue_draw widget
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
	;if flags and FACET_FLAG_FLAGS <> 0 [
	;	SetWindowLong
	;		widget
	;		wc-offset + 16
	;		get-flags as red-block! values + FACE_OBJ_FLAGS
	;]
	if flags and FACET_FLAG_DRAW  <> 0 [
		gtk_widget_queue_draw widget
	]
	if flags and FACET_FLAG_COLOR <> 0 [
		if type = base [
	;		update-base widget null null values
			gtk_widget_queue_draw widget
	;	][
	;		InvalidateRect widget null 1
		]
	]
	if all [flags and FACET_FLAG_PANE <> 0 type <> tab-panel][
		;update-z-order hWnd as red-block! values + FACE_OBJ_PANE type
		0
	]
	if flags and FACET_FLAG_RATE <> 0 [
		change-rate widget values + FACE_OBJ_RATE
	]
	if flags and FACET_FLAG_FONT <> 0 [
		change-font widget face as red-object! values + FACE_OBJ_FONT type
	]
	if flags and FACET_FLAG_PARA <> 0 [
	change-para
			widget
			face
			as red-object! values + FACE_OBJ_PARA
			as red-object! values + FACE_OBJ_FONT
			type
	]
	;if flags and FACET_FLAG_MENU <> 0 [
	;	menu: as red-block! values + FACE_OBJ_MENU
	;	if menu-bar? menu window [
	;		DestroyMenu GetMenu widget
	;		SetMenu widget build-menu menu CreateMenu
	;	]
	;]
	;if flags and FACET_FLAG_IMAGE <> 0 [
	;	change-image widget values type
	;]

	int/value: 0										;-- reset flags
]

OS-destroy-view: func [
	face   [red-object!]
	empty? [logic!]
	/local
		handle [handle!]
		values [red-value!]
		obj	   [red-object!]
		flags  [integer!]
][
	handle: face-handle? face
	values: object/get-values face
	flags: get-flags as red-block! values + FACE_OBJ_FLAGS
	if flags and FACET_FLAGS_MODAL <> 0 [
		0
	]

	free-handles handle values

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
		;sym = facets/pane [0]
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
	face	[red-object!]
	return: [red-image!]
	/local
		hWnd 	[handle!]
		dc		[handle!]
		mdc		[handle!]
		width	[integer!]
		height	[integer!]
		bmp		[handle!]
		bitmap	[integer!]
		img		[red-image!]
		word	[red-word!]
		type	[integer!]
		size	[red-pair!]
		screen? [logic!]
		ret		[red-image!]
][
	word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
	screen?: screen = symbol/resolve word/symbol
	either screen? [
		; get pixbuf from screen_root_window
		bmp: as handle! 0;gdk_pixbuf_get_from_window gdk_screen_get_root_window gdk_screen_get_default 0 0 screen-size-x screen-size-y; CGWindowListCreateImage 0 0 7F800000h 7F800000h 1 0 0		;-- INF
		ret: image/init-image as red-image! stack/push* OS-image/load-pixbuf bmp
	][
		;view: as-integer face-handle? face
		;either zero? view [ret: as red-image! none-value][
		;	sz: as red-pair! (object/get-values face) + FACE_OBJ_SIZE
		;	rc: make-rect 0 0 sz/x sz/y
			; data: objc_msgSend [view sel_getUid "dataWithPDFInsideRect:" rc/x rc/y rc/w rc/h]
			; img: objc_msgSend [
			; 	objc_msgSend [objc_getClass "NSImage" sel_alloc]
			; 	sel_getUid "initWithData:" data
			; ]
			bmp: as handle! 0; objc_msgSend [img sel_getUid "CGImageForProposedRect:context:hints:" 0 0 0]
			ret: image/init-image as red-image! stack/push* OS-image/load-pixbuf bmp
			; objc_msgSend [bmp sel_getUid "retain"]
			; objc_msgSend [img sel_release]
		;]
	]
	ret
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
][
	do-draw null img cmds no no no no
]

OS-draw-face: func [
	ctx		[draw-ctx!]
	cmds	[red-block!]
][
	if TYPE_OF(cmds) = TYPE_BLOCK [
		catch RED_THROWN_ERROR [parse-draw ctx cmds yes]
	]
	if system/thrown = RED_THROWN_ERROR [system/thrown: 0]
]