Red/System [
	Title:	"GTK3 fonts management"
	Author: "Qingtian Xie, Thiago Dourado de Andrade, RCqls, bitbegin"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

default-attrs: as handle! 0
default-css: as GString! 0

set-default-font: func [
	name		[c-string!]
	size		[integer!]
	/local
		attr	[PangoAttribute!]
][
	unless null? default-attrs [
		pango_attr_list_unref default-attrs
	]
	default-attrs: create-simple-attrs name size null

	unless null? default-css [
		g_string_free default-css true
	]
	default-css: create-simple-css name size null
]

create-simple-attrs: func [
	name		[c-string!]
	size		[integer!]
	color		[red-tuple!]
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
	attr: pango_attr_family_new name
	pango_attr_list_insert list attr
	attr: pango_attr_size_new PANGO_SCALE * size
	pango_attr_list_insert list attr

	if all [
		not null? color
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
	list
]

create-simple-css: func [
	name		[c-string!]
	size		[integer!]
	color		[red-tuple!]
	return:		[GString!]
	/local
		css		[GString!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[float!]
][
	css: g_string_sized_new 64
	g_string_append css "* {"
	g_string_append_printf [css { font-family: "%s";} name]
	g_string_append_printf [css { font-size: %dpt;} size]

	if all [
		not null? color
		TYPE_OF(color) = TYPE_TUPLE
		not all [
			TUPLE_SIZE?(color) = 4
			color/array1 and FF000000h = FF000000h
		]
	][
		alpha?: 0
		rgb: get-color-int color :alpha?
		b: rgb >> 16 and FFh
		g: rgb >> 8 and FFh
		r: rgb and FFh
		a: 1.0
		if alpha? = 1 [
			a: (as float! 255 - (rgb >>> 24)) / 255.0
		]
		g_string_append_printf [css { background-color: rgba(%d, %d, %d, %.3f);} r g b a]
	]
	g_string_append css "}"
	css
]

create-trans-css: func [
	return:		[GString!]
	/local
		css		[GString!]
][
	css: g_string_sized_new 64
	g_string_append css "* {"
	g_string_append css { background-color: transparent;}
	g_string_append css "}"
	css
]

create-background-css: func [
	color		[red-tuple!]
	return:		[GString!]
	/local
		css		[GString!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[float!]
][
	css: g_string_sized_new 64
	g_string_append css "* {"
	alpha?: 0
	rgb: get-color-int color :alpha?
	b: rgb >> 16 and FFh
	g: rgb >> 8 and FFh
	r: rgb and FFh
	a: 1.0
	if alpha? = 1 [
		a: (as float! 255 - (rgb >>> 24)) / 255.0
	]
	g_string_append_printf [css { background-color: rgba(%d, %d, %d, %.3f);} r g b a]
	g_string_append css "}"
	css
]

set-label-attrs: func [
	label		[handle!]
	font		[red-object!]
	hfont		[handle!]
	/local
		values	[red-value!]
		int		[red-integer!]
		angle	[integer!]
][
	if all [
		not null? font
		TYPE_OF(font) = TYPE_OBJECT
	][
		values: object/get-values font

		int: as red-integer! values + FONT_OBJ_ANGLE
		angle: either TYPE_OF(int) = TYPE_INTEGER [int/value][0]
		gtk_label_set_angle label as float! angle
	]

	gtk_label_set_attributes label hfont
]


set-label-para: func [
	label		[handle!]
	hsym		[integer!]
	vsym		[integer!]
	wrap?		[logic!]
	/local
		f		[float32!]
][
	case [
		hsym = _para/left [
			f: as float32! 0.0
		]
		hsym = _para/right [
			f: as float32! 1.0
		]
		true [
			f: as float32! 0.5
		]
	]
	gtk_label_set_xalign label f
	case [
		vsym = _para/top [
			f: as float32! 0.0
		]
		vsym = _para/bottom [
			f: as float32! 1.0
		]
		true [
			f: as float32! 0.5
		]
	]
	gtk_label_set_yalign label f
	gtk_label_set_line_wrap label wrap?
]

set-entry-para: func [
	entry		[handle!]
	hsym		[integer!]
	vsym		[integer!]
	wrap?		[logic!]
	/local
		layout	[handle!]
][
	layout: gtk_entry_get_layout entry
	case [
		hsym = _para/left [
			pango_layout_set_alignment layout PANGO_ALIGN_LEFT
		]
		hsym = _para/right [
			pango_layout_set_alignment layout PANGO_ALIGN_RIGHT
		]
		true [
			pango_layout_set_alignment layout PANGO_ALIGN_CENTER
		]
	]
	case [
		vsym = _para/top [
			gtk_widget_set_halign entry GTK_ALIGN_START
		]
		vsym = _para/bottom [
			gtk_widget_set_halign entry GTK_ALIGN_END
		]
		true [
			gtk_widget_set_halign entry GTK_ALIGN_CENTER
		]
	]
	if wrap? [
		pango_layout_set_wrap layout PANGO_WRAP_WORD
	]
]

set-textview-para: func [
	widget		[handle!]
	hsym		[integer!]
	vsym		[integer!]
	wrap?		[logic!]
][
	case [
		hsym = _para/left [
			gtk_text_view_set_justification widget GTK_JUSTIFY_LEFT
		]
		hsym = _para/right [
			gtk_text_view_set_justification widget GTK_JUSTIFY_RIGHT
		]
		true [
			gtk_text_view_set_justification widget GTK_JUSTIFY_CENTER
		]
	]
	case [
		vsym = _para/top [
			gtk_widget_set_halign widget GTK_ALIGN_START
		]
		vsym = _para/bottom [
			gtk_widget_set_halign widget GTK_ALIGN_END
		]
		true [
			gtk_widget_set_halign widget GTK_ALIGN_CENTER
		]
	]

	gtk_text_view_set_wrap_mode widget
		either wrap? [GTK_WRAP_WORD][GTK_WRAP_NONE]
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
	name: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][default-font-name]
	attr: pango_attr_family_new name
	pango_attr_list_insert list attr

	int: as red-integer! values + FONT_OBJ_SIZE
	size: either TYPE_OF(int) <> TYPE_INTEGER [default-font-size][
		int/value
	]
	attr: pango_attr_size_new PANGO_SCALE * size
	pango_attr_list_insert list attr

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

make-attrs: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
	/local
		list	[handle!]
		values	[red-value!]
		blk		[red-block!]
		int		[red-integer!]
][
	list: create-pango-attrs face font
	values: object/get-values font
	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 3
		handle/make-in blk as-integer list
		none/make-in blk
		none/make-in blk
	][
		int: as red-integer! block/rs-head blk
		int/header: TYPE_HANDLE
		int/value: as-integer list
	]

	blk: as red-block! values + FONT_OBJ_PARENT
	if all [face <> null TYPE_OF(blk) <> TYPE_BLOCK][
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]
	list
]

;-- create css styles
;-- TBD: support `angle`
;-- `anti-alias` need to be set by cairo
create-css: func [
	face		[red-object!]
	font		[red-object!]
	return:		[GString!]
	/local
		css		[GString!]
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
	css: g_string_sized_new 64
	g_string_append css "* {"

	values: object/get-values font

	str: as red-string! values + FONT_OBJ_NAME
	name: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		unicode/to-utf8 str :len
	][default-font-name]
	g_string_append_printf [css { font-family: "%s";} name]

	int: as red-integer! values + FONT_OBJ_SIZE
	size: either TYPE_OF(int) <> TYPE_INTEGER [default-font-size][
		int/value
	]
	g_string_append_printf [css { font-size: %dpt;} size]

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
					g_string_append css " text-decoration: underline;"
				]
				sym = _strike [
					g_string_append css " text-decoration: line-through;"
				]
				true			 [0]
			]
			style: style + 1
		]
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
			b: rgb >> 16 and FFh
			g: rgb >> 8 and FFh
			r: rgb and FFh
			a: 1.0
			if alpha? = 1 [
				a: (as float! 255 - (rgb >>> 24)) / 255.0
			]
			g_string_append_printf [css { background-color: rgba(%d, %d, %d, %.3f);} r g b a]
		]
	]

	g_string_append css "}"
	css
]

free-css: func [
	css			[GString!]
][
	g_string_free css true
]

make-css: func [
	face		[red-object!]
	font		[red-object!]
	return:		[GString!]
	/local
		css		[GString!]
		values	[red-value!]
		blk		[red-block!]
		int		[red-integer!]
][
	css: create-css face font
	values: object/get-values font

	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 3
		none/make-in blk
		handle/make-in blk as-integer css
		none/make-in blk
	][
		int: (as red-integer! block/rs-head blk) + 1
		int/header: TYPE_HANDLE
		int/value: as-integer css
	]

	blk: as red-block! values + FONT_OBJ_PARENT
	if all [face <> null TYPE_OF(blk) <> TYPE_BLOCK][
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]
	css
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
		size: either TYPE_OF(int) <> TYPE_INTEGER [default-font-size][
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

make-font: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [
		return null
	]
	make-css face font
	make-attrs face font
]

get-font-handle: func [
	font		[red-object!]
	idx			[integer!]
	return:		[handle!]
	/local
		state	[red-block!]
		handle	[red-handle!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		handle: (as red-handle! block/rs-head state) + idx
		if TYPE_OF(handle) = TYPE_HANDLE [
			return as handle! handle/value
		]
	]
	null
]

get-attrs: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
	/local
		hFont	[handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return null]
	hFont: get-font-handle font 0
	if null? hFont [hFont: make-attrs face font]
	hFont
]

get-css: func [
	face		[red-object!]
	font		[red-object!]
	return:		[GString!]
	/local
		css		[GString!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return null]
	css: as GString! get-font-handle font 1
	if null? css [css: make-css face font]
	css
]

free-font: func [
	font		[red-object!]
	/local
		state	[red-block!]
		hFont	[handle!]
		css		[GString!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [exit]
	hFont: get-font-handle font 0
	unless null? hFont [
		pango_attr_list_unref hFont
	]
	css: as GString! get-font-handle font 1
	unless null? css [
		g_string_free css true
	]
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	state/header: TYPE_NONE
]

set-font: func [
	widget		[handle!]
	face		[red-object!]
	values		[red-value!]
	/local
		font	[red-object!]
		color	[red-tuple!]
		para	[red-object!]
		hFont	[handle!]
		newF?	[logic!]
		css		[GString!]
		newC?	[logic!]
		type	[red-word!]
		sym		[integer!]
		layout	[handle!]
		pvalues	[red-value!]
		wrap?	[logic!]
		hsym	[integer!]
		vsym	[integer!]
		label	[handle!]
][
	font: as red-object! values + FACE_OBJ_FONT
	color: as red-tuple! values + FACE_OBJ_COLOR
	para: as red-object! values + FACE_OBJ_PARA


	hFont: get-attrs face font
	newF?: false
	if null? hFont [
		newF?: true
		hFont: create-simple-attrs default-font-name default-font-size color
	]
	css: get-css face font
	newC?: false
	if null? css [
		newC?: true
		css: create-simple-css default-font-name default-font-size color
	]
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	layout: get-face-layout widget values sym
	if all [
		sym = text
		layout <> widget
		TYPE_OF(color) = TYPE_TUPLE
	][
		apply-css-styles layout create-background-css color
	]
	either TYPE_OF(para) = TYPE_OBJECT [
		pvalues: object/get-values para
		wrap?: get-para-wrap pvalues
		hsym: get-para-hsym pvalues
		vsym: get-para-vsym pvalues
	][
		wrap?: no
		hsym: _para/left
		vsym: _para/middle
	]
	case [
		sym = text [
			set-label-para widget hsym vsym wrap?
			set-label-attrs widget font hFont
		]
		any [
			sym = button
			sym = check
			sym = radio
		][
			label: gtk_bin_get_child widget
			;-- some button maybe have empty label
			either g_type_check_instance_is_a label gtk_label_get_type [
				set-label-para label hsym vsym wrap?
				set-label-attrs label font hFont
			][
				apply-css-styles widget css
			]
		]
		sym = field [
			set-entry-para widget hsym vsym wrap?
			gtk_entry_set_attributes widget hFont
		]
		sym = group-box [
			label: gtk_frame_get_label_widget widget
			either null? label [
				apply-css-styles widget css
			][
				set-label-para label hsym vsym wrap?
				set-label-attrs label font hFont
			]
		]
		sym = area [
			set-textview-para widget hsym vsym wrap?
			apply-css-styles widget css
		]
		true [
			apply-css-styles widget css
		]
	]
	if newF? [
		free-pango-attrs hFont
	]
	if newC? [
		free-css css
	]
]

set-css: func [
	widget		[handle!]
	face		[red-object!]
	values		[red-value!]
	/local
		font	[red-object!]
		color	[red-tuple!]
		css		[GString!]
		newC?	[logic!]
		handle	[red-handle!]
		type	[red-word!]
		sym		[integer!]
		label	[handle!]
][
	font: as red-object! values + FACE_OBJ_FONT
	color: as red-tuple! values + FACE_OBJ_COLOR
	css: get-css face font
	newC?: false
	if null? css [
		newC?: true
		css: create-simple-css default-font-name default-font-size color
	]
	apply-css-styles widget css
	if newC? [
		free-css css
	]
]

update-font: func [
	font		[red-object!]
	flag		[integer!]
][
	switch flag [
		FONT_OBJ_NAME
		FONT_OBJ_SIZE
		FONT_OBJ_STYLE
		FONT_OBJ_ANGLE
		FONT_OBJ_ANTI-ALIAS? [
			free-font font
			make-font null font
		]
		default [0]
	]
]

make-styles-provider: func [
	widget		[handle!]
	/local
		style	[handle!]
		prov	[handle!]
][
	prov:	gtk_css_provider_new
	style:	gtk_widget_get_style_context widget

	gtk_style_context_add_provider style prov GTK_STYLE_PROVIDER_PRIORITY_USER
	g_object_set_qdata widget gtk-style-id prov
]

apply-css-styles: func [
	widget		[handle!]
	css			[GString!]
	/local
		prov	[handle!]
][
	prov: g_object_get_qdata widget gtk-style-id
	gtk_css_provider_load_from_data prov css/str -1 null
]

css-provider: func [
	path		[c-string!]
	priority	[integer!]
	/local
		prov	[handle!]
		disp	[handle!]
		screen	[handle!]
][
	prov: gtk_css_provider_new
	gtk_css_provider_load_from_path prov path null
	disp: gdk_display_get_default
	screen: gdk_display_get_default_screen disp
	gtk_style_context_add_provider_for_screen screen prov priority
	g_object_unref prov
]

red-gtk-styles: func [
	/local
		env		[str-array!]
		strarr	[handle!]
		str		[c-string!]
		found	[logic!]
][
	env: system/env-vars
	found: no
	until [
		strarr: g_strsplit env/item "=" 2
		str: as c-string! strarr/1
		if 0 = g_strcmp0 str "RED_GTK_STYLES" [
			str: as c-string! strarr/2
			css-provider str GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
			found: yes
		]
		env: env + 1
		g_strfreev strarr
		any [found env/item = null]
	]
]
