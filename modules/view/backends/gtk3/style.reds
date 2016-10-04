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

	.underline {
		text-decoration-line: underline;
	}

	.strike {
		text-decoration-line: line-through;
	}
}

style-init: func [
	/local
		provider [handle!]
		screen   [handle!]
][
	screen: gdk_screen_get_default
	provider: gtk_css_provider_new

	gtk_css_provider_load_from_data provider css-style length? css-style as handle! 0

	gtk_style_context_add_provider_for_screen screen provider GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
]

set-widget-style: func [
	widget [handle!]
	face   [red-object!]
	/local
		font    [red-object!]
		values  [red-value!]
		context [handle!]
		style   [red-word!]
		blk     [red-block!]
		len     [integer!]
		sym     [integer!]
		class   [c-string!]
][
	values: object/get-values face

	font:	as red-object!	values + FACE_OBJ_FONT

	if TYPE_OF(font) = TYPE_OBJECT [
		values: object/get-values font

		style:	as red-word!	values + FONT_OBJ_STYLE

		len: switch TYPE_OF(style) [
			TYPE_BLOCK [
				blk: as red-block! style
				style: as red-word! block/rs-head blk
				block/rs-length? blk
			]
			TYPE_WORD	[1]
			default		[0]
		]

		context: gtk_widget_get_style_context widget

		unless zero? len [
			loop len [
				sym: symbol/resolve style/symbol
				class: case [
					sym = _bold      ["bold"]
					sym = _italic    ["italic"]
					sym = _underline ["underline"]
					sym = _strike    ["strike"]
					true             [""]
				]
				unless 0 = length? class [gtk_style_context_add_class context class]
			]
		]
	]
]
