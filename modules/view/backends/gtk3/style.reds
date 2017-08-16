Red/System [
	Title:	"GTK3 widget style management"
	Author:	"Thiago Dourado de Andrade"
	File:	%style.reds
	Tabs:	4
	Rights:	"Copyright (C) 2016 Thiago Dourado de Andrade. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define GTK_STYLE_PROVIDER_PRIORITY_APPLICATION 600

css-style: {
	.bold {
		font-weight: bold;
	}

	.italic {
		font-style: italic;
	}
}

style-init: func [
	/local
		provider [handle!]
		screen   [handle!]
][
	screen: gdk_screen_get_default
	provider: gtk_css_provider_new

	gtk_css_provider_load_from_data provider css-style -1 null

	gtk_style_context_add_provider_for_screen screen provider GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
]

add-to-string: func [
	string  [c-string!]
	format  [c-string!]
	value   [handle!]
	return: [c-string!]
	/local
		temp [c-string!]
][
	temp: g_strdup_printf [format string value]
	g_free as handle! string
	temp
]

to-css-rgba: func [
	color   [red-tuple!]								;-- needs to be a valid color tuple
	return: [c-string!]									;-- rgba(r, g, b, a) format - Should be cleaned with g_free
	/local
		size  [integer!]
		r     [integer!]
		g     [integer!]
		b     [integer!]
		a     [float!]
		rgba  [c-string!]
		alpha [c-string!]
][
	size: TUPLE_SIZE?(color)

	r: color/array1 and FFh
	g: (color/array1 >> 8) and FFh
	b: (color/array1 >> 16) and FFh
	a: 1.0

	if size = 4 [
		a: (as-float 255 - color/array1 >>> 24) / 255.0
	]

	alpha: as c-string! allocate G_ASCII_DTOSTR_BUF_SIZE
	g_ascii_dtostr alpha G_ASCII_DTOSTR_BUF_SIZE a

	rgba: g_strdup_printf ["rgba(%d, %d, %d, %s)" r g b alpha]

	free as byte-ptr! alpha

	rgba
]

get-style-provider: func [
	widget  [handle!]
	return: [handle!]
][
	g_object_get_qdata widget gtk-style-id
]

create-widget-style: func [
	widget [handle!]
	face   [red-object!]
	/local
		context  [handle!]
		provider [handle!]
][
	provider:	gtk_css_provider_new
	context:	gtk_widget_get_style_context widget

	gtk_style_context_add_provider context provider GTK_STYLE_PROVIDER_PRIORITY_APPLICATION

	g_object_set_qdata widget gtk-style-id provider

	set-widget-style widget face
]

set-widget-style: func [
	widget [handle!]
	face   [red-object!]
	/local
		font     [red-object!]
		values   [red-value!]
		context  [handle!]
		provider [handle!]
		style    [red-word!]
		blk      [red-block!]
		len      [integer!]
		sym      [integer!]
		str      [red-string!]
		name     [c-string!]
		size     [red-integer!]
		css      [c-string!]
		color    [red-tuple!]
		rgba     [c-string!]
][
	values: object/get-values face

	font:	as red-object!	values + FACE_OBJ_FONT

	if TYPE_OF(font) = TYPE_OBJECT [
		values: object/get-values font

		;name:
		str: 	as red-string!	values + FONT_OBJ_NAME
		size:	as red-integer!	values + FONT_OBJ_SIZE
		style:	as red-word!	values + FONT_OBJ_STYLE
		;angle:
		color:	as red-tuple!	values + FONT_OBJ_COLOR
		;anti-alias?:

		css:		g_strdup_printf ["* {"]
		context:	gtk_widget_get_style_context widget
		provider:	get-style-provider widget

		if TYPE_OF(str) = TYPE_STRING [
			len: -1
			name: unicode/to-utf8 str :len
			css: g_strdup_printf [{%s font-family: "%s";} css name]
		]

		if TYPE_OF(size) = TYPE_INTEGER [
			css: add-to-string css "%s font-size: %dpt;" as handle! size/value
		]

		len: switch TYPE_OF(style) [
			TYPE_BLOCK [
				blk: as red-block! style
				style: as red-word! block/rs-head blk
				block/rs-length? blk
			]
			TYPE_WORD	[1]
			default		[0]
		]

		unless zero? len [
			loop len [
				sym: symbol/resolve style/symbol
				case [ ;OLD -> class: case [
					sym = _bold      ["bold" css: g_strdup_printf ["%s font-weight: bold;" css]]
					sym = _italic    ["italic" css: g_strdup_printf ["%s font-style: italic;" css]]
					sym = _underline ["underline" css: g_strdup_printf ["%s text-decoration-line: underline;" css]]
					sym = _strike    ["strike" css: g_strdup_printf ["%s text-decoration-line: line-through;" css]]
					true             [""]
				]
				style: style + 1
				;unless 0 = length? class [gtk_style_context_add_class context class]
			]
		]

		if TYPE_OF(color) = TYPE_TUPLE [
			rgba: to-css-rgba color
			css: add-to-string css "%s color: %s;" as handle! rgba
			g_free as handle! rgba
		]

		css: add-to-string css "%s}" null

		print ["css: " css lf]

		gtk_css_provider_load_from_data provider css -1 null

		g_free as handle! css
	]
]
