Red/System [
	Title:	"GTK3 color"
	Author: "bitbegin"
	File: 	%color.reds
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

to-gdk-color: func [
	color		[integer!]
	gcolor		[GdkRGBA!]
	/local
		t		[integer!]
		a		[float!]
][
	t: color >>> 24 and FFh
	t: FFh - t
	a: as float! t
	gcolor/alpha: a / 255.0
	t: color >> 16 and FFh
	a: as float! t
	gcolor/blue: a / 255.0
	t: color >> 8 and FFh
	a: as float! t
	gcolor/green: a / 255.0
	t: color and FFh
	a: as float! t
	gcolor/red: a / 255.0
]

color-u8-to-u16: func [
	color		[integer!]
	r			[int-ptr!]
	g			[int-ptr!]
	b			[int-ptr!]
	a			[int-ptr!]
	/local
		t		[integer!]
][
	t: color >>> 24 and FFh
	t: FFh - t
	a/value: t << 8 + t
	t: color >> 16 and FFh
	b/value: t << 8 + t
	t: color >> 8 and FFh
	g/value: t << 8 + t
	t: color and FFh
	r/value: t << 8 + t
]

change-color: func [
	widget		[handle!]
	color		[red-tuple!]
	type		[integer!]
	/local
		prov	[handle!]
		css		[GString!]
		rgb		[integer!]
		alpha?	[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[float!]
		style	[handle!]
		node	[c-string!]
		font	[red-object!]
		fcolor	[red-tuple!]
][
	if TYPE_OF(color) <> TYPE_TUPLE [
		free-color-provider widget
		exit
	]
	prov: GET-RED-COLOR(widget)
	if null? prov [
		prov: create-provider widget
		SET-RED-COLOR(widget prov)
	]
	css: GET-COLOR-STR(widget)
	if null? css [
		css: g_string_sized_new 64
		SET-COLOR-STR(widget css)
	]
	alpha?: 0
	rgb: get-color-int color :alpha?
	b: rgb >> 16 and FFh
	g: rgb >> 8 and FFh
	r: rgb and FFh
	a: 1.0
	if alpha? = 1 [
		a: (as float! 255 - (rgb >>> 24)) / 255.0
	]
	node: case [
		type = area [
			"text"
		]
		true [
			"*"
		]
	]
	g_string_set_size css 0
	g_string_set_size css 0
	g_string_append_printf [css "%s {" node]
	g_string_append_printf [css { background-color: rgba(%d, %d, %d, %.3f);} r g b a]
	if type = area [
		font: as red-object! (get-face-values widget) + FACE_OBJ_FONT
		if TYPE_OF(font) = TYPE_OBJECT [
			fcolor: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
			if TYPE_OF(fcolor) = TYPE_TUPLE [
				alpha?: 0
				rgb: get-color-int fcolor :alpha?
				b: rgb >> 16 and FFh
				g: rgb >> 8 and FFh
				r: rgb and FFh
				a: 1.0
				if alpha? = 1 [
					a: (as float! 255 - (rgb >>> 24)) / 255.0
				]
				g_string_append_printf [css { caret-color: rgba(%d, %d, %d, %.3f);} r g b a]
			]
		]
	]
	g_string_append css "}"
	gtk_css_provider_load_from_data prov css/str -1 null
]

free-color-provider: func [
	widget		[handle!]
	/local
		prov	[handle!]
		css		[GString!]
][
	prov: GET-RED-COLOR(widget)
	unless null? prov [
		remove-provider widget prov
		g_object_unref prov
		SET-RED-COLOR(widget null)
	]
	css: GET-COLOR-STR(widget)
	unless null? css [
		g_string_free css true
		SET-COLOR-STR(widget 0)
	]
]
