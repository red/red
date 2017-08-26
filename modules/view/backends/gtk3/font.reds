Red/System [
	Title:	"GTK3 fonts management"
	Author: "Qingtian Xie"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum pango-style! [
  PANGO_STYLE_NORMAL
  PANGO_STYLE_OBLIQUE
  PANGO_STYLE_ITALIC
]

#enum pango-variant! [
  PANGO_VARIANT_NORMAL
  PANGO_VARIANT_SMALL_CAPS
]

#enum pango-weight! [
  PANGO_WEIGHT_THIN: 100
  PANGO_WEIGHT_ULTRALIGHT: 200
  PANGO_WEIGHT_LIGHT: 300
  PANGO_WEIGHT_SEMILIGHT: 350
  PANGO_WEIGHT_BOOK: 380
  PANGO_WEIGHT_NORMAL: 400
  PANGO_WEIGHT_MEDIUM: 500
  PANGO_WEIGHT_SEMIBOLD: 600
  PANGO_WEIGHT_BOLD: 700
  PANGO_WEIGHT_ULTRABOLD: 800
  PANGO_WEIGHT_HEAVY: 900
  PANGO_WEIGHT_ULTRAHEAVY: 1000
]

#enum pango-stretch! [
  PANGO_STRETCH_ULTRA_CONDENSED
  PANGO_STRETCH_EXTRA_CONDENSED
  PANGO_STRETCH_CONDENSED
  PANGO_STRETCH_SEMI_CONDENSED
  PANGO_STRETCH_NORMAL
  PANGO_STRETCH_SEMI_EXPANDED
  PANGO_STRETCH_EXPANDED
  PANGO_STRETCH_EXTRA_EXPANDED
  PANGO_STRETCH_ULTRA_EXPANDED
]

#enum pango-font-mask! [
  PANGO_FONT_MASK_FAMILY: 1
  PANGO_FONT_MASK_STYLE: 2
  PANGO_FONT_MASK_VARIANT: 4
  PANGO_FONT_MASK_WEIGHT: 8
  PANGO_FONT_MASK_STRETCH: 16
  PANGO_FONT_MASK_SIZE: 32
  PANGO_FONT_MASK_GRAVITY: 64
]

#define PANGO_SCALE 1024
#define PANGO_SCALE_XX_SMALL 0.5787037037037
#define PANGO_SCALE_X_SMALL  0.6444444444444
#define PANGO_SCALE_SMALL    0.8333333333333
#define PANGO_SCALE_MEDIUM   1.0
#define PANGO_SCALE_LARGE    1.2
#define PANGO_SCALE_X_LARGE  1.4399999999999
#define PANGO_SCALE_XX_LARGE 1.728


;; The idea: font-handle (which is required in view.red) is the css string which is (the only object) not related to the widget

make-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [handle!]
	/local
		values   [red-value!]
		style    [red-word!]
		blk      [red-block!]
		len      [integer!]
		sym      [integer!]
		str      [red-string!]
		name     [c-string!]
		size     [red-integer!]
		css      [c-string!]
		color    [red-tuple!]
		bgcolor  [red-tuple!]
		rgba     [c-string!]
		hFont    [handle!]
		int      [red-integer!]
][
	values: object/get-values font

	;name:
	str: 	as red-string!	values + FONT_OBJ_NAME
	size:	as red-integer!	values + FONT_OBJ_SIZE
	style:	as red-word!	values + FONT_OBJ_STYLE
	;angle:
	color:	as red-tuple!	values + FONT_OBJ_COLOR
	;anti-alias?:

	; release first
	hFont: get-font-handle font
	unless null? hFont [g_free hFont]

	css:	g_strdup_printf ["* {"]

	unless null? face [
		bgcolor: as red-tuple!	(object/get-values face) + FACE_OBJ_COLOR
		if TYPE_OF(bgcolor) = TYPE_TUPLE [
			rgba: to-css-rgba bgcolor
			css: add-to-string css "%s background-color: %s;" as handle! rgba
			g_free as handle! rgba
		]
	]

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
			case [
				sym = _bold      ["bold" css: g_strdup_printf ["%s font-weight: bold;" css]]
				sym = _italic    ["italic" css: g_strdup_printf ["%s font-style: italic;" css]]
				sym = _underline ["underline" css: g_strdup_printf ["%s text-decoration-line: underline;" css]]
				sym = _strike    ["strike" css: g_strdup_printf ["%s text-decoration-line: line-through;" css]]
				true             [""]
			]
			style: style + 1
		]
	]

	if TYPE_OF(color) = TYPE_TUPLE [
		rgba: to-css-rgba color
		css: add-to-string css "%s color: %s;" as handle! rgba
		g_free as handle! rgba
	]

	css: add-to-string css "%s}" null

	hFont: as handle! css

	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 2
		handle/make-in blk as-integer hFont
	][
		int: as red-integer! block/rs-head blk
		int/header: TYPE_HANDLE
		int/value: as-integer hFont
	]

	if face <> null [
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]

	hFont
]

; Here, style provider is used as font provider
make-font-provider: func [
	widget	[handle!]
	/local
		style	 [handle!]
		provider [handle!]
][
	provider:	gtk_css_provider_new
	style:		gtk_widget_get_style_context widget

	gtk_style_context_add_provider style provider GTK_STYLE_PROVIDER_PRIORITY_APPLICATION

	g_object_set_qdata widget gtk-style-id provider
]

get-font-provider: func [
	widget  [handle!]
	return: [handle!]
][
	g_object_get_qdata widget gtk-style-id
] 



get-font-handle: func [
	font	[red-object!]
	return: [handle!]
	/local
		state  [red-block!]
		int	   [red-integer!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		if TYPE_OF(int) = TYPE_INTEGER [
			return as handle! int/value
		]
	]
	null
]

free-font: func [
	font [red-object!]
	/local
		state [red-block!]
		hFont [handle!]
][
	hFont: get-font-handle font
	if hFont <> null [
		state: as red-block! (object/get-values font) + FONT_OBJ_STATE
		state/header: TYPE_NONE
	]
]

update-font: func [
	font [red-object!]
	flag [integer!]
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

;convert font to pango_font_description (used for get-text-size)
font-description: func [
	font [red-object!]
	return: [handle!]
	/local
		values   [red-value!]
		style    [red-word!]
		blk      [red-block!]
		len      [integer!]
		sym      [integer!]
		str      [red-string!]
		name     [c-string!]
		size     [red-integer!]
		css      [c-string!]
		color    [red-tuple!]
		bgcolor  [red-tuple!]
		rgba     [c-string!]
		fsty     [integer!]
		fd	     [handle!]

][
	values: object/get-values font

	;name:
	str: 	as red-string!	values + FONT_OBJ_NAME
	size:	as red-integer!	values + FONT_OBJ_SIZE
	style:	as red-word!	values + FONT_OBJ_STYLE
	;angle:
	color:	as red-tuple!	values + FONT_OBJ_COLOR
	;anti-alias?:

	fd: pango_font_description_new

	if TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
		pango_font_description_set_family fd name
	]

	if TYPE_OF(size) = TYPE_INTEGER [
		pango_font_description_set_size fd size/value * PANGO_SCALE
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

	fsty: PANGO_STYLE_NORMAL
	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [ 
				sym = _bold      [pango_font_description_set_weight fd PANGO_WEIGHT_BOLD]
				sym = _italic    [fsty: PANGO_STYLE_ITALIC]
				sym = _underline []
				sym = _strike    []
				true             []
			]
			style: style + 1
		]
	]

	pango_font_description_set_style fd fsty
	pango_font_description_set_stretch fd PANGO_STRETCH_NORMAL
	pango_font_description_set_variant fd PANGO_VARIANT_NORMAL
	
	fd
]


OS-request-font: func [
	font		[red-object!]
	selected	[red-object!]
	mono?		[logic!]
	return:		[red-object!]
][
	font
]

; Stuff maybe to REMOVE related to cairo without any success
; #enum cairo_font_slant_t! [
; 	CAIRO_FONT_SLANT_NORMAL
; 	CAIRO_FONT_SLANT_ITALIC
; 	CAIRO_FONT_SLANT_OBLIQUE
; ]

; #enum cairo_font_weight_t! [
; 	CAIRO_FONT_WEIGHT_NORMAL
;  	CAIRO_FONT_WEIGHT_BOLD
; ]

; select-cairo-font: func [
; 	cr		[handle!]
; 	font 	[red-object!]
; 	/local
; 		values   [red-value!]
; 		style    [red-word!]
; 		blk      [red-block!]
; 		len      [integer!]
; 		sym      [integer!]
; 		str      [red-string!]
; 		name     [c-string!]
; 		size     [red-integer!]
; 		css      [c-string!]
; 		color    [red-tuple!]
; 		bgcolor  [red-tuple!]
; 		rgba     [c-string!]
; 		slant    [integer!]
; 		weight   [integer!]
; ][
; 	values: object/get-values font

; 	;name:
; 	str: 	as red-string!	values + FONT_OBJ_NAME
; 	size:	as red-integer!	values + FONT_OBJ_SIZE
; 	style:	as red-word!	values + FONT_OBJ_STYLE
; 	;angle:
; 	color:	as red-tuple!	values + FONT_OBJ_COLOR
; 	;anti-alias?:

; 	if TYPE_OF(str) = TYPE_STRING [
; 		len: -1
; 		name: unicode/to-utf8 str :len
;  	]

; 	len: switch TYPE_OF(style) [
; 		TYPE_BLOCK [
; 			blk: as red-block! style
; 			style: as red-word! block/rs-head blk
; 			block/rs-length? blk
; 		]
; 		TYPE_WORD	[1]
; 		default		[0]
; 	]

; 	slant: CAIRO_FONT_SLANT_NORMAL
; 	weight: CAIRO_FONT_WEIGHT_NORMAL
	
; 	unless zero? len [
; 		loop len [
; 			sym: symbol/resolve style/symbol
; 			case [ 
; 				sym = _bold      [weight: CAIRO_FONT_WEIGHT_BOLD]
; 				sym = _italic    [slant: CAIRO_FONT_SLANT_ITALIC]
; 				sym = _underline []
; 				sym = _strike    []
; 				true             []
; 			]
; 			style: style + 1
; 		]
; 	]

; 	;cairo_select_font_face cr name slant weight
; 	cairo_select_font_face cr "Arial" 0 0

; 	if TYPE_OF(size) = TYPE_INTEGER [
; 		print ["size: " size/value lf]
; 		cairo_set_font_size cr size/value
; 	]
; ]