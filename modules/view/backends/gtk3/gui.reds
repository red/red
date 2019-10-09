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

#define SET-CURSOR(s d)			[g_object_set_qdata s cursor-id d]
#define GET-CURSOR(s)			[g_object_get_qdata s cursor-id]
#define SET-EVENT-BOX(s d)		[g_object_set_qdata s event-box-id d]
#define GET-EVENT-BOX(s)		[g_object_get_qdata s event-box-id]
#define SET-CONTAINER(s d)		[g_object_set_qdata s gtk-container-id d]
#define GET-CONTAINER(s)		[g_object_get_qdata s gtk-container-id]
#define SET-RESIZING(s d)		[g_object_set_qdata s resizing-id d]
#define GET-RESIZING(s)			[g_object_get_qdata s resizing-id]
#define SET-STARTRESIZE(s d)	[g_object_set_qdata s start-resize-id d]
#define GET-STARTRESIZE(s)		[g_object_get_qdata s start-resize-id]

#define CREATE-DEFAULT-FONT		[
	font-description-create default-font-name default-font-size PANGO_WEIGHT_NORMAL PANGO_STYLE_NORMAL
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

GTKApp:			as handle! 0
GTKApp-Ctx: 	0
exit-loop:		0

;;;close-window?:	no
;;;win-array:		declare red-vector!
win-cnt:		0
AppMainMenu:	as handle! 0

;; Identifiers for qdata
red-face-id1:		g_quark_from_string "red-face-id1"
red-face-id2:		g_quark_from_string "red-face-id2"
red-face-id3:		g_quark_from_string "red-face-id3"
red-face-id4:		g_quark_from_string "red-face-id4"
gtk-style-id: 		g_quark_from_string "gtk-style-id"
event-box-id:		g_quark_from_string "event-box-id"					;-- widget's layout-widget
gtk-container-id:	g_quark_from_string "gtk-container-id"				;-- widget's parent-widget
red-timer-id:		g_quark_from_string "red-timer-id"
css-id:				g_quark_from_string "css-id"
size-id:			g_quark_from_string "size-id"
menu-id:			g_quark_from_string "menu-id"
no-wait-id:			g_quark_from_string "no-wait-id"
red-event-id:		g_quark_from_string "red-event-id"
cursor-id:			g_quark_from_string "cursor-id"
resizing-id:		g_quark_from_string "resizing-id"
start-resize-id:	g_quark_from_string "start-resize-id"

group-radio:	as handle! 0

settings:		as handle! 0
pango-context:	as handle! 0
default-font:	as handle! 0
default-font-name: as c-string! 0
default-font-size: 0
gtk-font-name:	"Sans"
gtk-font-size:	10

; Do not KNOW about this one
;;;
main-window:	as handle! 0
last-window:	as handle! 0

log-pixels-x:	0
log-pixels-y:	0
screen-size-x:	0
screen-size-y:	0


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
	face	[red-object!]
	return: [integer!]
	/local
		state [red-block!]
		int	  [red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	assert TYPE_OF(state) = TYPE_BLOCK
	int: as red-integer! block/rs-head state
	assert TYPE_OF(int) = TYPE_HANDLE
	int/value
]

get-widget-symbol: func [
	widget		[handle!]
	return:		[integer!]
	/local
		type	[red-word!]
		values	[red-value!]
][
	values: get-face-values widget
	either null? values [symbol/resolve popup][
		type: as red-word! values + FACE_OBJ_TYPE
		symbol/resolve type/symbol
	]
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

;; GTK basic widget is often embedded in some super widget in order to be contained in some layout widget
event-box?: func [
	widget		[handle!]
	return:		[handle!]
	/local
		evbox	[handle!]
][
	evbox: g_object_get_qdata widget event-box-id
	if null? evbox [evbox: widget]
	return evbox
]

gtk-layout?: func [
	type		[integer!]
	return:		[logic!]
][
	any[type = rich-text type = panel type = base]
]

container-type?: func [
	type		[integer!]
	return:		[logic!]
][
	;;; See events.reds to see the comment above
	; Option I:  any[type = rich-text type = panel type = base]
	; Option II:
	type = rich-text
]

set-view-no-wait: func [
	window		[handle!]
	key			[logic!]
][
	; usually a view/no-wait call at most twice do-events and at least one do-events with no-wait? = true
	;; DEBUG[view/no-wait]: print ["view-no-wait? window " window " => "  key lf]
	g_object_set_qdata window no-wait-id as int-ptr! either key [1][0]
]

view-no-wait?: func [
	window		[handle!]
	return:		[logic!]
][
	all[1 = as integer! g_object_get_qdata window no-wait-id window <> main-window]
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

	text: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][
		null
	]

	width: 0 height: 0

	;;; get pango_context
	;  from widget first
	; widget: face-handle? face
	; pc: as handle! 0 pl: as handle! 0
	; unless null? widget [
	; 	pc: gtk_widget_get_pango_context widget
	; 	unless null? pc [pl: pango_layout_new pc ];seems more natural than pango-context
	; ]
	; globally otherwise
	;if null? pl [
		pl: pango_layout_new pango-context
	;]


	pango_layout_set_text pl text -1
	pango_layout_set_font_description pl hFont
	pango_layout_get_pixel_size pl :width :height
	g_object_unref pl
;	unless null? pc [g_object_unref pc]

	size/width: width
	size/height: height

	if pair <> null [
		pair/x: size/width
		pair/y: size/height
	]
	size
]

to-bgr: func [
	node		[node!]
	pos			[integer!]
	return:		[integer!]									;-- 00bbggrr format or -1 if not found
	/local
		color	[red-tuple!]
][
	color: as red-tuple! get-node-facet node pos
	either TYPE_OF(color) = TYPE_TUPLE [
		color/array1 and 00FFFFFFh
	][
		-1
	]
]

free-handles: func [
	widget		[integer!]
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
][
	values: get-face-values as handle! widget
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	;;;if all [sym = window not force?][
	;;;	close-window?: yes
	;;;	vector/rs-append-int win-array widget
	;;;]

	rate: values + FACE_OBJ_RATE
	if TYPE_OF(rate) <> TYPE_NONE [change-rate as handle! widget none-value]

	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [face < tail][
			handle: face-handle? face
			unless null? handle [free-handles as-integer handle force?]
			face: face + 1
		]
	]

	if sym = window [
		win-cnt: win-cnt - 1
		post-quit-msg
	]

	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

; Debug function to show children tree
debug-show-children: func [
	widget			[handle!]
	parent?			[logic!]
	/local
		widget_		[handle!]
		child		[handle!]
		container	[handle!]
		rect		[tagRECT value]
		sx			[integer!]
		sy			[integer!]
		offset		[red-pair!]
		size		[red-pair!]
		pane		[red-block!]
		type		[red-word!]
		sym			[integer!]
		face		[red-object!]
		tail		[red-object!]
		values		[red-value!]
		overlap?	[logic!]
		; these ones would be removed
		debug		[logic!]
		cpt			[integer!]
][
	; to remove when satisfactory enough development
	debug: yes

	values: get-face-values widget
	type: 	as red-word! values + FACE_OBJ_TYPE
	pane: 	as red-block! values + FACE_OBJ_PANE

	either parent? [
		face: 	as red-object! values + FACE_OBJ_PARENT
		either TYPE_OF(face) = TYPE_NONE [
			print-line "parent face: none"
			print ["parent handle: " widget lf]
		][
			values: object/get-values face
			type: 	as red-word! values + FACE_OBJ_TYPE
			pane: 	as red-block! values + FACE_OBJ_PANE
			widget_: face-handle? face
			print ["from parent handle: " widget_ lf]
		]
	][print ["parent handle: " widget lf]]

	sym: 	symbol/resolve type/symbol

	if all [TYPE_OF(pane) = TYPE_BLOCK 0 <> block/rs-length? pane] [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		if debug [print ["Pane type: " get-symbol-name sym lf]]
		if TYPE_OF(face) <> TYPE_OBJECT [print-line "not face object"]
		widget_: face-handle? face

		either null? widget_ [print-line "null container" container: null][container: GET-CONTAINER(widget_)]
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
				widget_: event-box? child

				gtk_widget_get_allocation widget_ as handle! rect
				; rmk: rect/x and rect/y are absolute coordinates when offset/x and offset/y are relative coordinates
				if debug [ print ["widget->rect:" rect/x "x" rect/y  "x" rect/width "x" rect/height lf]]
			]
			if debug [print ["red->rect:" offset/x "x" offset/y  "x" size/x "x" size/y lf]]
			either null? child [print-line "null child"][debug-show-children child no]
			face: face + 1
		]
		if debug [print-line "Pane end"]
	]
]

; on-gc-mark: does [
; 	collector/keep flags-blk/node
; 	collector/keep win-array/node
; ]

show-gtk-version: func [][
	print [ "GTK VERSION: " gtk_get_major_version "." gtk_get_minor_version "." gtk_get_micro_version lf]
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
	default-font: CREATE-DEFAULT-FONT
]

init: func [][
	show-gtk-version
	gtk_disable_setlocale
	GTKApp: gtk_application_new RED_GTK_APP_ID G_APPLICATION_NON_UNIQUE
	gobj_signal_connect(GTKApp "window-removed" :window-removed-event :exit-loop)
	GTKApp-Ctx: g_main_context_default
	unless g_main_context_acquire GTKApp-Ctx [
		probe "ERROR: GTK: Cannot acquire main context" halt
	]
	g_application_register GTKApp null null
	;;;vector/make-at as red-value! win-array 8 TYPE_INTEGER 4

	screen-size-x: gdk_screen_width
	screen-size-y: gdk_screen_height

	set-defaults

	#if type = 'exe [red-gtk-styles]
	;;;collector/register as int-ptr! :on-gc-mark
]

get-symbol-name: function [
	sym			[integer!]
	return:		[c-string!]
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
		sym = rich-text ["rich-text"]
		sym = done ["done"]
		sym = stop ["stop"]
		sym = _image ["image"]

		sym = facets/pane ["facets/pane"]

		sym = words/_remove/symbol	["words/remove"]
		sym = words/_take/symbol	["words/take"]
		sym = words/_clear/symbol	["words/clear"]
		sym = words/_insert/symbol	["words/insert"]
		sym = words/_poke/symbol	["words/poke"]
		sym = words/_moved/symbol	["words/moved"]
		sym = words/_changed/symbol	["words/changed"]

		true ["undefined"]
	]
]
; this adjustment is supposed to fix only horizontally consecutive widgets in the same pane
adjust-sizes: func [
	widget			[handle!]
	/local
		widget_		[handle!]
		child		[handle!]
		container	[handle!]
		rect		[tagRECT value]
		dx			[integer!]
		dy			[integer!]
		ox			[integer!]
		oy			[integer!]
		sx			[integer!]
		sy			[integer!]
		offset		[red-pair!]
		size		[red-pair!]
		pane		[red-block!]
		type		[red-word!]
		sym			[integer!]
		face		[red-object!]
		tail		[red-object!]
		values		[red-value!]
		overlap?	[logic!]
		; these ones would be removed
		debug		[logic!]
		cpt			[integer!]
][
	; to remove when satisfactory enough development
	debug: no

	values: get-face-values widget
	type: 	as red-word! values + FACE_OBJ_TYPE
	pane: 	as red-block! values + FACE_OBJ_PANE

	sym: 	symbol/resolve type/symbol

	if all [TYPE_OF(pane) = TYPE_BLOCK 0 <> block/rs-length? pane] [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		if debug [print ["Parent type: " get-symbol-name sym lf]]
		child: face-handle? face
		container: either null? child [null][GET-CONTAINER(child)]
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
					widget_: event-box? child
					if debug [ print ["move child: " offset/x "+" dx "("  offset/x + dx ")" " " offset/y lf]]
					gtk_layout_move container widget_ offset/x + dx  offset/y
					gtk_widget_get_allocation widget_ as handle! rect
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
		clr		[integer!]
		t		[integer!]
		face	[red-object!]
		font	[red-object!]
][
	;; DEBUG: print ["change-color "  widget " " get-symbol-name type lf]
	t: TYPE_OF(color)
	if all [t <> TYPE_NONE t <> TYPE_TUPLE][exit]
	; if transparent-color? color [
	; 	objc_msgSend [widget sel_getUid "setDrawsBackground:" no]
	; 	exit
	; ]
	case [
		type = area [
			face: get-face-obj widget
			font: face-font? face
			apply-css-styles widget face font type
			; widget: objc_msgSend [widget sel_getUid "documentView"]
			; clr: either t = TYPE_NONE [00FFFFFFh][color/array1]
			; set-caret-color widget clr
			; if t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "textBackgroundColor"]]
		]
		true [
			;; DEBUG: print ["change-color " widget lf]
			face: get-face-obj widget
			font: face-font? face
			apply-css-styles widget face font type
		]
	]
]

change-pane: func [
	parent		[handle!]
	pane		[red-block!]
	type		[integer!]
	/local
		face	[red-object!]
		tail	[red-object!]
		widget	[handle!]
		evbox	[handle!]
		nb		[integer!]
		s		[series!]
		values	[red-value!]
		offset	[red-pair!]
		list	[GList!]
		child	[GList!]

][
	;; DEBUG: print ["change-pane " get-symbol-name type lf]

	if gtk-layout? type [ ;; this is for gtk_layout widget
		list: as GList! gtk_container_get_children parent

		child: list nb: 0
		while [not null? child][
		nb: nb + 1
		g_object_ref child/data ; to avoid destruction before removing from container
		gtk_container_remove parent child/data
		;; DEBUG: print ["removed widget" nb ": " child/data " to " parent lf]
		child: child/next
		]
		g_list_free as int-ptr! list

		s: GET_BUFFER(pane)
		face: as red-object! s/offset + pane/head
		tail: as red-object! s/tail
		nb: (as-integer tail - face) >> 4

		nb: 0
		while [face < tail][
			if TYPE_OF(face) = TYPE_OBJECT [
				widget: face-handle? face
				if widget <> null [
					evbox: event-box? widget
					nb: nb + 1
					;; DEBUG: print ["add widget" nb ": " widget "(" evbox ") to " parent lf]
					gtk_container_add parent evbox
					values: object/get-values face
					offset: as red-pair! values + FACE_OBJ_OFFSET
					gtk_layout_move parent evbox offset/x  offset/y
				]
			]
			face: face + 1
		]
		;; OS-refresh-window as-integer main-window

		;; DEBUG:
		; list: as GList! gtk_container_get_children parent
		; child: list nb: 0
		; while [not null? child][
		;    nb: nb + 1
		;    print [" widget" nb ": " child/data lf]
		;    child: child/next
		; ]
		; g_list_free as int-ptr! list
	]
]

change-font: func [
	widget		[handle!]
	face		[red-object!]
	font		[red-object!]
	type		[integer!]
	return:		[logic!]
	/local
		; css		 [c-string!]
		; provider [handle!]
		hFont	[handle!]
][
	;; DEBUG: print ["change-font " widget " " get-symbol-name type lf]
	if TYPE_OF(font) <> TYPE_OBJECT [return no]

	; provider: get-styles-provider widget

	; ;; update the style (including font color) gtk_css_provider is much more easier to apply than older interface to manage all the styles
	; css: ""
	; css: css-styles face font type

	; unless null? provider [gtk_css_provider_load_from_data provider css -1 null]

	apply-css-styles widget face font type

	;; Update the pango_font_description hFont (directly used by get-text-size)
	make-font face font

	yes
]

change-offset: func [
	widget		[handle!]
	pos			[red-pair!]
	type		[integer!]
	/local
		container	[handle!]
		evbox		[handle!]
][
	;; DEBUG: print ["change-offset type: " get-symbol-name get-widget-symbol widget " " widget " " pos/x "x" pos/y lf]
	either type = window [
		gtk_window_move widget pos/x pos/y
	][
		unless null? widget [
			;OS-refresh-window as integer! main-window
			container: either null? widget [null][GET-CONTAINER(widget)]
			;; DEBUG: print ["change-offset by" pos lf]
			; _widget: either type = text [
			; 	g_object_get_qdata widget _widget-id
			; ][widget]

			evbox: event-box? widget
			unless null? container [
				gtk_layout_move container evbox pos/x pos/y
				gtk_widget_queue_draw evbox
			]
		]
	]
]

change-size: func [
	widget		[handle!]
	size		[red-pair!]
	type		[integer!]
	/local
		evbox	[handle!]
][
	;; DEBUG: print ["change-size " get-symbol-name get-widget-symbol widget " " widget " " size/x "x" size/y lf]

	either type = window [
		;; DEBUG: print ["change-size window: "  size/x "x" size/y lf]
		gtk_window_set_default_size widget size/x size/y
		gtk_window_resize widget size/x size/y
		gtk_widget_queue_draw widget
	][
		 unless null? widget [
			evbox: event-box? widget
			gtk_widget_set_size_request evbox size/x size/y
			gtk_widget_queue_resize evbox
		]
	]

]

init-all-children: func [
	widget		[handle!]
	/local
		values	[red-value!]
		pane	[red-block!]
		show?	[red-logic!]
		cursor	[handle!]
		win		[handle!]
		face	[red-object!]
		tail	[red-object!]
		child	[handle!]
][
	values: get-face-values widget
	pane: 	as red-block! values + FACE_OBJ_PANE

	show?:	as red-logic! values + FACE_OBJ_VISIBLE?
	gtk_widget_set_visible widget show?/value

	cursor: GET-CURSOR(widget)
	unless null? cursor [
		win: gtk_widget_get_window widget
		unless null? win [
			gdk_window_set_cursor win cursor
		]
	]

	if all [TYPE_OF(pane) = TYPE_BLOCK 0 <> block/rs-length? pane] [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane

		while [face < tail][
			child: face-handle? face
			unless null? child [
				init-all-children child
			]
			face: face + 1
		]
	]
]

change-visible: func [
	widget		[handle!]
	show?		[logic!]
	type		[integer!]
][
	case [
		type = window [
			; either show? [
			; 	objc_msgSend [widget sel_getUid "makeKeyAndOrderFront:" widget]
			; ][
			; 	objc_msgSend [widget sel_getUid "orderOut:" widget]
			; ]
			0
		]
		true [
			;; DEBUG: print ["change-visible " widget " (type " get-symbol-name type "): " show? lf]
			gtk_widget_set_visible widget show?
			gtk_widget_queue_draw widget
		]
	]
;	gtk_widget_queue_draw widget
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
	widget		[handle!]
	values		[red-value!]
	/local
		data	[red-value!]
		word	[red-word!]
		size	[red-pair!]
		f		[red-float!]
		str		[red-string!]
		caption	[c-string!]
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
			gtk_progress_bar_set_fraction widget  f/value
		]
		all [
			type = slider
			TYPE_OF(data) = TYPE_PERCENT
		][
			f: as red-float! data
			size: as red-pair! values + FACE_OBJ_SIZE
			len: either size/x > size/y [size/x][size/y]
			gtk_range_set_value widget f/value * (as-float len)
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
			init-text-list widget as red-block! data
			gtk_widget_show_all widget
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
			item: gtk_list_box_get_row_at_index widget idx
			gtk_list_box_select_row widget item
		]
		any [type = drop-list type = drop-down][
			gtk_combo_box_set_active widget idx
		]
	 	type = tab-panel [
			gtk_notebook_set_current_page widget idx
		]
		type = window [
			switch TYPE_OF(int) [
				TYPE_OBJECT [set-selected-focus widget]
				TYPE_NONE	[; as in windows but not sure!
					;; DEVEL: print ["DEVEL WARNING: 'change-selection windows' since not sure this is valid"]
					gtk_widget_grab_focus widget
				]
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
		as-integer state/value							;-- returns 0/1, matches the messages
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
	drop-list?	[logic!] ;to remove if unused
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
		;; DEBUG: print ["combo-size: " size lf]

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
	widget		[handle!]
	data		[red-block!]
	/local
		str		[red-string!]
		tail	[red-string!]
		val		[c-string!]
		len		[integer!]
		label	[handle!]
		type	[integer!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		;; DEBUG: print ["init-text-list" lf]
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data

		if str = tail [exit]

		while [str < tail][
			type: TYPE_OF(str)
			;; DEBUG: print ["type " type lf]
			if ANY_STRING?(type) [
				len: -1
				val: unicode/to-utf8 str :len
				label: gtk_label_new val
				;; DEBUG: print ["Add elt: " val lf]
				gtk_widget_set_halign label 1		;-- GTK_ALIGN_START
				gtk_container_add widget label
			]
			str: str + 1
		]
	]
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
					;; DEBUG: print ["set cursor: " widget lf]
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
	;; DEBUG: print ["OS-redraw" lf]
	unless null? as handle! widget [gtk_widget_queue_draw as handle! widget]
]

OS-refresh-window: func [widget [integer!]][
	;; DEBUG: print-line "OS-refresh-window"
	;debug-show-children main-window no
	;gtk_widget_queue_draw main-window
	OS-show-window widget
]

OS-show-window: func [
	widget		[integer!]
	/local
		face	[red-object!]
	 	event	[GdkEventConfigure!]
		type	[integer!]
		size	[red-pair!]
		hWnd	[handle!]
][
	hWnd: as handle! widget
	unless null? hWnd [
		type: get-widget-symbol hWnd
		gtk_widget_show_all hWnd
		;; DEBUG: print ["OS-show-window " hWnd "(" get-symbol-name type ") win: " gtk_widget_get_window hWnd lf]
		;; Deal with visible? facets
		init-all-children hWnd
		gtk_widget_grab_focus hWnd
		face: (as red-object! get-face-values hWnd) + FACE_OBJ_SELECTED
		if TYPE_OF(face) = TYPE_OBJECT [gtk_widget_grab_focus face-handle? face]
	]
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
		sym			[integer!]
		p-sym		[integer!]
		caption		[c-string!]
		len			[integer!]
		widget		[handle!]
		evbox		[handle!]
		winbox		[handle!]
		buffer		[handle!]
		container	[handle!]
		hMenu		[handle!]
		value		[integer!]
		fvalue		[float!]
		vertical?	[logic!]
		rfvalue		[red-float!]
][
	stack/mark-native words/_body

	values: object/get-values face

	evbox: as handle! 0 ; widget version with possible scrollview

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

	bits: 	  get-flags as red-block! values + FACE_OBJ_FLAGS
	sym: 	  symbol/resolve type/symbol

	; if bits and FACET_FLAGS_SCROLLABLE <> 0 [
	; 	flags: flags or WS_HSCROLL or WS_VSCROLL
	; ]

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
		]
		sym = button [
			widget: gtk_button_new_with_label caption
			if TYPE_OF(img) = TYPE_IMAGE [
				change-image widget img sym
			]
		]
		sym = base [
			widget: gtk_layout_new null null;
			gtk_layout_set_size widget size/x size/y
			;; widget: gtk_drawing_area_new
		]
		sym = rich-text [
			widget: gtk_layout_new null null;gtk_drawing_area_new
			gtk_layout_set_size widget size/x size/y
			evbox: gtk_scrolled_window_new null null
			;; DEBUG: print ["rich-text evbox: " evbox lf]
			gtk_container_add evbox widget
		]
		sym = window [
			;; DEBUG: print ["win App " GTKApp lf]
			win-cnt: win-cnt + 1
			widget: gtk_window_new 0
			last-window: widget
			;; DEBUG: print ["win number " win-cnt " at " widget lf]
			if win-cnt = 1 [
				;; DEBUG: print ["Creation of Main window" lf]
				main-window: widget
			]
			gtk_application_add_window GTKApp widget

			if bits and FACET_FLAGS_MODAL <> 0 [
				;; DEBUG: print ["Creation of Modal window" lf]
				gtk_window_set_modal widget yes
			]
			unless null? caption [gtk_window_set_title widget caption]

			winbox: gtk_box_new GTK_ORIENTATION_VERTICAL  0
			gtk_container_add widget winbox
			if all [						;@@ application menu ?
				null? AppMainMenu
				menu-bar? menu window
			][
				AppMainMenu: gtk_menu_bar_new
				;; DEBUG: print ["AppMainMenu " AppMainMenu " creation for window " widget lf]
				build-menu menu AppMainMenu widget
				gtk_box_pack_start winbox  AppMainMenu no yes 0
			]
			gtk_widget_show winbox
			evbox: gtk_layout_new null null
			gtk_layout_set_size evbox size/x size/y
			gtk_box_pack_start winbox evbox yes yes 0
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
		sym = slider [
			vertical?: size/y > size/x
			value: either vertical? [size/y][size/x]
			widget: gtk_scale_new_with_range vertical? 0.0 as float! value 1.0
			value: get-position-value as red-float! data value
			if vertical? [value: size/y - value]
			gtk_range_set_value widget as float! value
			gtk_scale_set_has_origin widget no
			gtk_scale_set_draw_value widget no
		]
		sym = text [
			widget: gtk_label_new caption
			;; gtk_label_set_width_chars widget ???
			evbox: gtk_event_box_new null null
			gtk_container_add evbox widget
		]
		sym = field [
			widget: gtk_entry_new
			buffer: gtk_entry_get_buffer widget
			unless null? caption [gtk_entry_buffer_set_text buffer caption -1]
			gtk_entry_set_width_chars widget size/x / 10
			set-hint-text widget as red-block! values + FACE_OBJ_OPTIONS
			if bits and FACET_FLAGS_PASSWORD <> 0 [gtk_entry_set_visibility widget no]
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
			evbox: gtk_scrolled_window_new null null
			gtk_container_add evbox widget
		]
		sym = group-box [
			widget: gtk_frame_new caption
			gtk_frame_set_shadow_type widget 3
			gtk_frame_set_label_align widget 0.5 0.5; Todo: does not seem to work
			container: gtk_layout_new null null
			gtk_container_add widget container
		]
		sym = panel [
			widget: gtk_layout_new null null
			unless null? caption [
				buffer: gtk_label_new caption
				gtk_container_add widget buffer
			]
			gtk_layout_set_size widget size/x size/y
		]
		sym = tab-panel [
			widget: gtk_notebook_new
			set-tabs widget values
		]
		sym = text-list [
			widget: gtk_list_box_new
			init-text-list widget data
			;gtk_list_box_select_row widget gtk_list_box_get_row_at_index widget 0
			evbox: gtk_scrolled_window_new null null
			if bits and FACET_FLAGS_NO_BORDER = 0 [
				gtk_scrolled_window_set_shadow_type evbox 3
			]
			gtk_container_add evbox widget
		]
		any [
			sym = drop-list
			sym = drop-down
		][
			widget: either sym = drop-list [gtk_combo_box_text_new][gtk_combo_box_text_new_with_entry]
			init-combo-box widget data caption sym = drop-list
			;; TODO: improve it but better than nothing from now otherwise it is uggly!
			if sym = drop-down[gtk_entry_set_width_chars gtk_bin_get_child widget (size/x - 20) / 10 ] ; 10 here the size of the font... TODO: to improve later!
			gtk_combo_box_set_active widget 0
		]
		true [
			;-- search in user-defined classes
			fire [TO_ERROR(script face-type) type]
		]
	]

	; save the previous group-radio state as a global variable
	group-radio: either sym = radio [widget][as handle! 0]

	parse-common-opts widget face as red-block! values + FACE_OBJ_OPTIONS sym

	;;DEBUG: print [ "New widget " get-symbol-name sym "->" widget lf]

	either null? evbox [evbox: widget][SET-EVENT-BOX(widget evbox)]
	if all [
		sym <> window
		parent <> 0
	][
		p-sym: get-widget-symbol as handle! parent
		; TODO: case to replace with either if no more choice
		;; DEBUG: print ["Parent: " get-symbol-name p-sym " evbox" evbox lf]

		container: as handle! case [
			p-sym = window [
				g_object_get_qdata as handle! parent event-box-id
			]
			any [p-sym = panel p-sym = rich-text p-sym = base] [parent]
			p-sym = group-box [
				buffer: gtk_container_get_children as handle! parent
				;; DEBUG: print ["Parent when not container : " buffer/value lf]
				buffer/value
			]
			true [
				; CAREFULL: NOT SURE THIS WAS USED PROPERLY -> for compilation of gui-console this clearly leads to a bug
				; buffer: gtk_container_get_children as handle! parent
				; ;; DEBUG:
				; print ["Parent when not container : " buffer/value lf]
				; buffer/value

				;; redirect to the layout of the parent
				;; WARNING: (since completedly changed code)
				print ["DEVEL WARNING: <<NORMALLY NOTHING SHOULD GO HERE>>  (ONLY FOR DEVELOPMENT SINCE CODE HAS FULLY CHANGED BUT IMPOSSIBLE TO TEST) " lf]
				g_object_get_qdata as handle! parent gtk-container-id
			]
		]
		;; DEBUG: print ["widget (" get-symbol-name sym "):" widget "[evbox: " evbox "] with parent (" get-symbol-name p-sym ") " as handle! parent " with container (" (get-symbol-name get-widget-symbol container)  ") " container lf]

		;save gtk_layout container for adjustment since size/x and size/y are not the real sizes in gtk and need to be updated in a second pass
		SET-CONTAINER(widget container)
		if sym = text [SET-CONTAINER(evbox container)]
		gtk_widget_set_size_request evbox size/x size/y
		gtk_layout_put container evbox offset/x offset/y
		;; DEBUG: print ["make-view: evbox: " offset/x "x" offset/y "x" size/x "x" size/y lf]
	]

	; Deal with actors
	connect-widget-events widget sym evbox

	unless any[sym = window sym = area][build-context-menu widget menu]

	;-- store the face value in the extra space of the window struct
	assert TYPE_OF(face) = TYPE_OBJECT					;-- detect corruptions caused by CreateWindow unwanted events
	store-face-to-obj widget face
	if sym = text [store-face-to-obj evbox face]

	change-selection widget as red-integer! values + FACE_OBJ_SELECTED sym
	change-para widget face as red-object! values + FACE_OBJ_PARA font sym
	change-enabled widget enabled?/value sym

	make-styles-provider widget

	;; TODO: NOT SURE the if is necessary!
	if sym <> base [
		change-font widget face font sym
	]

	if TYPE_OF(rate) <> TYPE_NONE [change-rate widget rate]

	change-color widget as red-tuple! values + FACE_OBJ_COLOR sym

	;; USELESS: if sym <> window [gtk_widget_show widget]
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
		change-offset widget as red-pair! values + FACE_OBJ_OFFSET type
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
		flags: get-flags as red-block! values + FACE_OBJ_FLAGS
		if all[
			type = field
			flags and FACET_FLAGS_PASSWORD <> 0
		][
			;; DEBUG: print ["password flag activated for field" lf]
			gtk_entry_set_visibility widget no
		]
	]
	if flags and FACET_FLAG_DRAW  <> 0 [
		gtk_widget_queue_draw widget
		; 0
	]
	if flags and FACET_FLAG_COLOR <> 0 [
		;; DEBUG: print ["FACET_FLAG_COLOR " get-symbol-name type lf]
		;;;if type = base [
			;; DEBUG: print ["FACET_FLAG_COLOR " widget  lf]
			change-color widget as red-tuple! values + FACE_OBJ_COLOR type
		;;;]
	]
	if all [flags and FACET_FLAG_PANE <> 0 type <> tab-panel][
		change-pane widget as red-block! values + FACE_OBJ_PANE type
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
	;; DEBUG: print ["OS-destroy-view" lf]
	handle: face-handle? face
	values: object/get-values face
	flags: get-flags as red-block! values + FACE_OBJ_FLAGS
	either handle <> main-window [
		;; DEBUG: if flags and FACET_FLAGS_MODAL <> 0 [print ["modal "]] print ["window: " handle " (main-window: " main-window ") closing... win-cnt: " win-cnt " exit-loop: " exit-loop lf ]

		;gtk_window_close handle ;; NOT ENOUGH SINCE THIS IS EQUIVALENT TO CLICKING CLOSE BUTTON
		gtk_widget_destroy handle
		win-cnt: win-cnt - 1
	][

	;; DEBUG: print ["closing main window win-cnt: " win-cnt " exit-loop: " exit-loop lf]

	obj: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj FONT_OBJ_PARENT]

	obj: as red-object! values + FACE_OBJ_PARA
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj PARA_OBJ_PARENT]

	;;g_main_context_release GTKApp-Ctx
	;; DEBUG:

	;; TODO: This can be useless now!
	remove-all-timers handle

	;; DEBUG: print ["BYE! win: " win-cnt " (" handle ")" lf]

	free-handles as-integer handle no
	]
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