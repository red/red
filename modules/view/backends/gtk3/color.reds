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

default-backdrop-color: 00FFFFFFh			;-- default white

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
		layout	[handle!]
		style	[handle!]
][
	prov: GET-RED-COLOR(widget)
	either null? prov [
		prov: create-provider widget
		SET-RED-COLOR(widget prov)
		css: g_string_sized_new 64
		SET-COLOR-STR(widget css)
		layout: get-face-layout widget get-face-values widget type
		if layout <> widget [
			style: gtk_widget_get_style_context layout
			gtk_style_context_add_provider style prov GTK_STYLE_PROVIDER_PRIORITY_USER
		]
	][
		css: GET-COLOR-STR(widget)
	]
	if TYPE_OF(color) <> TYPE_TUPLE [
		g_string_set_size css 0
		gtk_css_provider_load_from_data prov css/str -1 null
		exit
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
	g_string_set_size css 0
	g_string_append css "* {"
	g_string_append_printf [css { background-color: rgba(%d, %d, %d, %.3f);} r g b a]
	g_string_append css "}"
	g_string_append css " * selection {"
	g_string_append_printf [css { color: rgba(%d, %d, %d, %.3f);} r g b a]
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
	free-provider prov
	SET-RED-COLOR(widget null)
	css: GET-COLOR-STR(widget)
	g_string_free css true
	SET-COLOR-STR(widget 0)
]
