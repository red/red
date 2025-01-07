Red/System [
	Title:	"GTK3 font"
	Author: "bitbegin"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

font-ext-type: -1
default-attrs: as handle! 0

init-default-handle: does [
	unless null? default-attrs [
		pango_attr_list_unref default-attrs
	]
	default-attrs: create-default-attrs
]

create-default-attrs: func [
	return:		[handle!]
	/local
		list	[handle!]
		attr	[PangoAttribute!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[integer!]
][
	list: pango_attr_list_new
	attr: pango_attr_family_new default-font-name
	pango_attr_list_insert list attr
	attr: pango_attr_size_new PANGO_SCALE * default-font-size
	pango_attr_list_insert list attr

	alpha?: 0
	rgb: default-font-color
	alpha?: 1
	r: 0 g: 0 b: 0 a: 0
	color-u8-to-u16 rgb :r :g :b :a
	attr: pango_attr_foreground_new r g b
	pango_attr_list_insert list attr
	attr: pango_attr_foreground_alpha_new a
	pango_attr_list_insert list attr
	list
]

;-- create css styles
;-- `anti-alias` need to be set by cairo
create-css: func [
	face		[red-object!]
	font		[red-object!]
	type		[integer!]
	css			[GString!]
	/local
		node	[c-string!]
		values	[red-value!]
		str		[red-string!]
		name	[c-string!]
		len		[integer!]
		int		[red-integer!]
		size	[integer!]
		color	[red-tuple!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[float!]
		style	[red-word!]
		blk		[red-block!]
		sym		[integer!]
][
	node: case [
		type = area [
			"*"
		]
		true [
			"*"
		]
	]
	g_string_set_size css 0
	g_string_append_printf [css "%s {" node]

	values: object/get-values font
	str: as red-string! values + FONT_OBJ_NAME
	if TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
		g_string_append_printf [css { font-family: "%s";} name]
	]

	int: as red-integer! values + FONT_OBJ_SIZE
	if TYPE_OF(int) = TYPE_INTEGER [
		size: int/value
		g_string_append_printf [css { font-size: %dpt;} size]
	]

	color: as red-tuple! values + FONT_OBJ_COLOR
	if TYPE_OF(color) = TYPE_TUPLE [
		alpha?: 0
		rgb: get-color-int color :alpha?
		b: rgb >> 16 and FFh
		g: rgb >> 8 and FFh
		r: rgb and FFh
		a: 1.0
		if alpha? = 1 [
			a: (as float! 255 - (rgb >>> 24)) / 255.0
		]
		g_string_append_printf [css { color: rgba(%d, %d, %d, %.3f);} r g b a]
	]

	;-- ? GTK3 warnings
	;int: as red-integer! values + FONT_OBJ_ANGLE
	;if TYPE_OF(int) = TYPE_INTEGER [
	;	g_string_append_printf [css { font-style: oblique %ddeg;} int/value]
	;]

	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]

	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold [
					g_string_append css " font-weight: bold;"
				]
				sym = _italic [
					g_string_append css " font-style: italic;"
				]
				sym = _underline [
					;-- TBD: only one text-decoration style can be used
					;g_string_append css " text-decoration: underline;"
					0
				]
				sym = _strike [
					g_string_append css " text-decoration: line-through;"
				]
				true			 [0]
			]
			style: style + 1
		]
	]

	g_string_append css "}"
]

;-- create pango attributes
;-- `angle` need to be set on label
;-- `anti-alias` need to be set by cairo
create-pango-attrs: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
	/local
		list	[handle!]
		attr	[PangoAttribute!]
		values	[red-value!]
		str		[red-string!]
		name	[c-string!]
		len		[integer!]
		int		[red-integer!]
		size	[integer!]
		color	[red-tuple!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[integer!]
		style	[red-word!]
		blk		[red-block!]
		sym		[integer!]
][
	list: pango_attr_list_new

	values: object/get-values font

	str: as red-string! values + FONT_OBJ_NAME
	if TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
		attr: pango_attr_family_new name
		pango_attr_list_insert list attr
	]

	int: as red-integer! values + FONT_OBJ_SIZE
	if TYPE_OF(int) = TYPE_INTEGER [
		size: int/value
		attr: pango_attr_size_new PANGO_SCALE * size
		pango_attr_list_insert list attr
	]

	color: as red-tuple! values + FONT_OBJ_COLOR
	if TYPE_OF(color) = TYPE_TUPLE [
		alpha?: 0
		rgb: get-color-int color :alpha?
		r: 0 g: 0 b: 0 a: 0
		color-u8-to-u16 rgb :r :g :b :a
		attr: pango_attr_foreground_new r g b
		pango_attr_list_insert list attr
		attr: pango_attr_foreground_alpha_new a
		pango_attr_list_insert list attr
	]

	unless null? face [
		color: as red-tuple! (object/get-values face) + FACE_OBJ_COLOR
		if all [
			TYPE_OF(color) = TYPE_TUPLE
			not all [
				TUPLE_SIZE?(color) = 4
				color/array1 and FF000000h = FF000000h
			]
		][
			alpha?: 0
			rgb: get-color-int color :alpha?
			r: 0 g: 0 b: 0 a: 0
			color-u8-to-u16 rgb :r :g :b :a
			attr: pango_attr_background_new r g b
			pango_attr_list_insert list attr
			attr: pango_attr_background_alpha_new a
			pango_attr_list_insert list attr
		]
	]

	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]

	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold [
					attr: pango_attr_weight_new PANGO_WEIGHT_BOLD
					pango_attr_list_insert list attr
				]
				sym = _italic [
					attr: pango_attr_style_new PANGO_STYLE_ITALIC
					pango_attr_list_insert list attr
				]
				sym = _underline [
					attr: pango_attr_underline_new PANGO_UNDERLINE_SINGLE
					pango_attr_list_insert list attr
				]
				sym = _strike [
					attr: pango_attr_strikethrough_new true
					pango_attr_list_insert list attr
				]
				true			 [0]
			]
			style: style + 1
		]
	]
	list
]

free-pango-attrs: func [
	attrs		[handle!]
][
	pango_attr_list_unref attrs
]


mark-font: func [hFont [handle!]][]

delete-font: func [h [handle!]][pango_attr_list_unref h]

make-font: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
	/local
		attrs	[handle!]
		values	[red-value!]
		blk		[red-block!]
		h		[red-handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [
		return null
	]
	attrs: create-pango-attrs face font
	values: object/get-values font
	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 2
		h: handle/make-in blk as-integer attrs handle/CLASS_FONT
		none/make-in blk
	][
		h: as red-handle! block/rs-head blk
		h: handle/make-at as red-value! h as-integer attrs handle/CLASS_FONT
	]
	if attrs <> null [h/extID: externals/store attrs font-ext-type]

	blk: as red-block! values + FONT_OBJ_PARENT
	if all [face <> null TYPE_OF(blk) <> TYPE_BLOCK][
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]
	attrs
]

get-font-handle-slot: func [
	font	[red-object!]
	idx		[integer!]							;-- 0-based index
	return: [red-handle!]
	/local
		state [red-block!]
		h	  [red-handle!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		h: (as red-handle! block/rs-head state) + idx
		if TYPE_OF(h) = TYPE_HANDLE [return h]
	]
	null
]

get-font-handle: func [
	font	[red-object!]
	idx		[integer!]							;-- 0-based index
	return: [handle!]
	/local
		h [red-handle!]
][
	h: get-font-handle-slot font idx
	either null? h [null][as handle! h/value]
]

get-font: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
	/local
		hFont	[handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return null]
	hFont: get-font-handle font 0
	if null? hFont [hFont: make-font face font]
	hFont
]

free-font: func [
	font		[red-object!]
	/local
		state	[red-block!]
		h		[red-handle!]
		hFont	[handle!]
][
	h: get-font-handle-slot font 0
	if h <> null [
		hFont: as handle! h/value
		pango_attr_list_unref hFont
		h/extID: externals/remove h/extID no
		state: as red-block! (object/get-values font) + FONT_OBJ_STATE
		state/header: TYPE_NONE
	]
]

update-font: func [
	font		[red-object!]
	flag		[integer!]
	/local
		hFont	[handle!]
][
	switch flag [
		FONT_OBJ_NAME
		FONT_OBJ_SIZE
		FONT_OBJ_STYLE
		FONT_OBJ_ANGLE
		FONT_OBJ_ANTI-ALIAS? [
			if TYPE_OF(font) = TYPE_OBJECT [
				free-font font
				make-font null font
			]
		]
		default [0]
	]
]

change-font: func [
	widget		[handle!]
	face		[red-object!]
	values		[red-value!]
	sym			[integer!]
	/local
		font	[red-object!]
		prov	[handle!]
		css		[GString!]
		style	[handle!]
		label	[handle!]
		hFont	[handle!]
][
	font: as red-object! values + FACE_OBJ_FONT
	if any [
		null? font
		TYPE_OF(font) <> TYPE_OBJECT
	][
		free-font-provider widget
		;-- clear attrs
		case [
			sym = text [
				gtk_label_set_attributes widget null
			]
			any [
				sym = button
				sym = check
				sym = radio
			][
				label: gtk_bin_get_child widget
				if g_type_check_instance_is_a label gtk_label_get_type [
					gtk_label_set_attributes label null
				]
			]
			sym = area [
				clear-textview-tag widget
			]
			sym = text-list [
				set-text-list-font widget null
			]
			true [0]
		]
		exit
	]
	prov: GET-RED-FONT(widget)
	if null? prov [
		prov: create-provider widget
		SET-RED-FONT(widget prov)
	]
	css: GET-FONT-STR(widget)
	if null? css [
		css: g_string_sized_new 128
		SET-FONT-STR(widget css)
	]

	create-css face font sym css
	gtk_css_provider_load_from_data prov css/str -1 null

	;-- special styles
	case [
		sym = text [
			set-label-attrs widget font
		]
		any [
			sym = button
			sym = check
			sym = radio
		][
			label: gtk_bin_get_child widget
			;-- some button maybe have empty label
			if g_type_check_instance_is_a label gtk_label_get_type [
				set-label-attrs label font
			]
		]
		sym = area [
			set-textview-tag widget font
		]
		sym = text-list [
			set-text-list-font widget font
		]
		true [0]
	]

	free-font font
	make-font face font
]

set-label-attrs: func [
	label		[handle!]
	font		[red-object!]
	/local
		values	[red-value!]
		int		[red-integer!]
		angle	[integer!]
		attrs	[handle!]
		style	[red-word!]
		len		[integer!]
		blk		[red-block!]
		sym		[integer!]
		attr	[PangoAttribute!]
][
	values: object/get-values font

	int: as red-integer! values + FONT_OBJ_ANGLE
	angle: either TYPE_OF(int) = TYPE_INTEGER [int/value][0]
	gtk_label_set_angle label as float! angle

	attrs: pango_attr_list_new
	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]

	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold [
					0
				]
				sym = _italic [
					0
				]
				sym = _underline [
					attr: pango_attr_underline_new PANGO_UNDERLINE_SINGLE
					pango_attr_list_insert attrs attr
				]
				sym = _strike [
					attr: pango_attr_strikethrough_new true
					pango_attr_list_insert attrs attr
				]
				true [0]
			]
			style: style + 1
		]
	]
	gtk_label_set_attributes label attrs
]

free-font-provider: func [
	widget		[handle!]
	/local
		prov	[handle!]
		css		[GString!]
][
	prov: GET-RED-FONT(widget)
	unless null? prov [
		remove-provider widget prov
		g_object_unref prov
		SET-RED-FONT(widget null)
	]
	css: GET-FONT-STR(widget)
	unless null? css [
		g_string_free css true
		SET-FONT-STR(widget 0)
	]
]

create-pango-font: func [
	font		[red-object!]
	return:		[handle!]
	/local
		hFont	[handle!]
		values	[red-value!]
		str		[red-string!]
		name	[c-string!]
		len		[integer!]
		int		[red-integer!]
		size	[integer!]
		style	[red-word!]
		blk		[red-block!]
		sym		[integer!]
][
	hFont: pango_font_description_new

	either TYPE_OF(font) <> TYPE_OBJECT [
		pango_font_description_set_family hFont default-font-name
		pango_font_description_set_size hFont PANGO_SCALE * default-font-size
	][
		values: object/get-values font

		str: as red-string! values + FONT_OBJ_NAME
		name: either TYPE_OF(str) = TYPE_STRING [
			len: -1
			unicode/to-utf8 str :len
		][default-font-name]
		pango_font_description_set_family hFont name

		int: as red-integer! values + FONT_OBJ_SIZE
		size: either any [
			TYPE_OF(int) <> TYPE_INTEGER
			int/value <= 0
		][
			default-font-size
		][
			int/value
		]
		pango_font_description_set_size hFont PANGO_SCALE * size

		style: as red-word! values + FONT_OBJ_STYLE
		len: switch TYPE_OF(style) [
			TYPE_BLOCK [
				blk: as red-block! style
				style: as red-word! block/rs-head blk
				len: block/rs-length? blk
			]
			TYPE_WORD  [1]
			default	   [0]
		]

		unless zero? len [
			loop len [
				sym: symbol/resolve style/symbol
				case [
					sym = _bold [
						pango_font_description_set_weight hFont PANGO_WEIGHT_BOLD
					]
					sym = _italic [
						pango_font_description_set_style hFont PANGO_STYLE_ITALIC
					]
					sym = _underline [
						0
					]
					sym = _strike [
						0
					]
					true [0]
				]
				style: style + 1
			]
		]
	]
	hFont
]

free-pango-font: func [
	hFont		[handle!]
][
	pango_font_description_free hFont
]

update-textview-tag: func [
	buffer		[handle!]
	start		[handle!]
	end			[handle!]
	/local
		table	[handle!]
		tag		[handle!]
][
	table: gtk_text_buffer_get_tag_table buffer
	tag: gtk_text_tag_table_lookup table "underline"
	unless null? tag [
		gtk_text_buffer_apply_tag buffer tag start end
	]
]

set-textview-tag: func [
	widget		[handle!]
	font		[red-object!]
	/local
		buffer	[handle!]
		start	[GtkTextIter! value]
		end		[GtkTextIter! value]
		tag		[handle!]
		values	[red-value!]
		style	[red-word!]
		len		[integer!]
		blk		[red-block!]
		sym		[integer!]
][
	buffer: gtk_text_view_get_buffer widget
	gtk_text_buffer_get_bounds buffer as handle! start as handle! end
	gtk_text_buffer_remove_all_tags buffer as handle! start as handle! end

	values: object/get-values font
	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]
	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold [
					0
				]
				sym = _italic [
					0
				]
				sym = _underline [
					tag: gtk_text_buffer_create_tag [buffer "underline" "underline" PANGO_UNDERLINE_SINGLE null]
					gtk_text_buffer_apply_tag buffer tag as handle! start as handle! end
				]
				sym = _strike [
					0
				]
				true			 [0]
			]
			style: style + 1
		]
	]
]

clear-textview-tag: func [
	widget		[handle!]
	/local
		buffer	[handle!]
		start	[GtkTextIter! value]
		end		[GtkTextIter! value]
][
	buffer: gtk_text_view_get_buffer widget
	gtk_text_buffer_get_bounds buffer as handle! start as handle! end
	gtk_text_buffer_remove_all_tags buffer as handle! start as handle! end
]

set-text-list-font: func [
	widget		[handle!]
	font		[red-object!]
	/local
		list	[GList!]
		child	[GList!]
		label	[handle!]
][
	list: gtk_container_get_children widget
	child: list
	while [not null? child][
		label: gtk_bin_get_child child/data
		either null? font [
			gtk_label_set_attributes label null
		][
			set-label-attrs label font
		]
		child: child/next
	]
	unless null? list [
		g_list_free list
	]
]
