Red/System [
	Title:	"GTK3 fonts management"
	Author: "Qingtian Xie, Thiago Dourado de Andrade, RCqls"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;; First style development provided by Thiago Dourado de Andrade
#define GTK_STYLE_PROVIDER_PRIORITY_APPLICATION 600

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


;; The idea: font-handle (which is required in view.red) is the css string which is (the only object) not related to the widget

make-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [handle!]
	/local
		values	[red-value!]
		blk		[red-block!]
		css		[c-string!]
		hFont	[handle!]
][
	; no more deal with different styles but only font via pango_font_description (excluding color, underline, strike)
	hFont: font-description font

	set-font-handle font hFont

	values: object/get-values font

	if face <> null [
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]

	;; DEBUG: print ["font-description: " hFont lf]

	hFont
]

get-font-handle: func [
	font	[red-object!]
	idx		[integer!]
	return: [handle!]
	/local
		state  [red-block!]
		int	   [red-integer!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		if TYPE_OF(int) = TYPE_HANDLE [
			return as handle! int/value
		]
	]
	null
]

;; CAREFUL! This solution does not work...  
get-font-handle-from-face-handle: func [
	hWnd	[handle!]
	return:	[handle!]
	/local
		hFont	[handle!]
		style	[handle!]
][
	;; DOES NOT WORK! TOO BAD!
	style:	gtk_widget_get_style_context hWnd

	;; Two ways: the second one's would be deprecated
	;; Solution 1
	;;hFont: as handle! 0
	;;gtk_style_context_get [style "font" hFont null]
	;; Solution 2 (supposed to be deprecated)
	;hFont: gtk_style_context_get_font style 0
	;hFont
	as handle! 0
]

free-font-handle: func [
	hFont [handle!]
][
	pango_font_description_free hFont
]

free-font: func [
	font [red-object!]
	/local
		state [red-block!]
		hFont [handle!]
][
	hFont: get-font-handle font 0
	if hFont <> null [
		state: as red-block! (object/get-values font) + FONT_OBJ_STATE
		state/header: TYPE_NONE
	]
	free-font-handle hFont
]

set-font-handle: func [
	font [red-object!]
	hFont 	[handle!]
	/local
		values	[red-value!]
		blk		[red-block!]
		state 	[red-block!]
		int		[red-integer!]
		hFontP	[handle!]
][
	; release previous hFont first
	hFontP: get-font-handle font 0
	unless null? hFontP [
		free-font-handle hFontP
	]

	values: object/get-values font
			
	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 2
		handle/make-in blk as-integer hFont
	][
		int: as red-integer! block/rs-head blk
		int/header: TYPE_HANDLE
		int/value: as-integer hFont
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
		fsize	 [integer!]
		css      [c-string!]
		color    [red-tuple!]
		bgcolor  [red-tuple!]
		rgba     [c-string!]
		fweight  [integer!]
		fstyle   [integer!]
		fd	     [handle!]

][
	; default font if font is none. TODO: better than gtk-font would be to get the default font system or from red side
	if TYPE_OF(font) = TYPE_NONE [
		return pango_font_description_from_string gtk-font
	]
	values: object/get-values font
	;name:
	str: 	as red-string!	values + FONT_OBJ_NAME
	size:	as red-integer!	values + FONT_OBJ_SIZE
	style:	as red-word!	values + FONT_OBJ_STYLE
	;angle:
	color:	as red-tuple!	values + FONT_OBJ_COLOR
	;anti-alias?:

	fd: pango_font_description_new

	name: "Arial" ; @@ to change to default font name  
	if TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
	]
	pango_font_description_set_family fd name

	fsize: either TYPE_OF(size) = TYPE_INTEGER [size/value][16]
	;; DEBUG: print ["font-description: fsize -> " fsize lf]
	pango_font_description_set_size fd fsize * PANGO_SCALE

	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			block/rs-length? blk
		]
		TYPE_WORD	[1]
		default		[0]
	]

	fstyle: PANGO_STYLE_NORMAL
	fweight: PANGO_WEIGHT_NORMAL
	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [ 
				sym = _bold      [fweight: PANGO_WEIGHT_BOLD]
				sym = _italic    [fstyle: PANGO_STYLE_ITALIC]
				sym = _underline []
				sym = _strike    []
				true             []
			]
			style: style + 1
		]
	]

	pango_font_description_set_weight fd fweight
	pango_font_description_set_style fd fstyle
	pango_font_description_set_stretch fd PANGO_STRETCH_NORMAL
	pango_font_description_set_variant fd PANGO_VARIANT_NORMAL
	
	fd
]

;; Styles initiated by Thiago Dourado de Andrade (used in change-font)
; Here, style provider is used as font provider
make-styles-provider: func [
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

get-styles-provider: func [
	widget  [handle!]
	return: [handle!]
][
	g_object_get_qdata widget gtk-style-id
]

css-styles: func [
	face	[red-object!]
	font	[red-object!]
	return: [c-string!]
	/local
		values   [red-value!]
		blk      [red-block!]
		style    [red-word!]
		len      [integer!]
		sym      [integer!]
		str      [red-string!]
		name     [c-string!]
		size     [red-integer!]
		css      [c-string!]
		color    [red-tuple!]
		bgcolor  [red-tuple!]
		rgba     [c-string!]
][
	values: object/get-values font

	;name:
	str: 	as red-string!	values + FONT_OBJ_NAME
	size:	as red-integer!	values + FONT_OBJ_SIZE
	style:	as red-word!	values + FONT_OBJ_STYLE
	;angle:
	color:	as red-tuple!	values + FONT_OBJ_COLOR
	;anti-alias?:

	css:	g_strdup_printf ["* {"]

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
				sym = _bold      ["bold" css: g_strdup_printf ["%s font-weight: bold; " css]]
				sym = _italic    ["italic" css: g_strdup_printf ["%s font-style: italic;" css]]
				sym = _underline ["underline" css: g_strdup_printf ["%s text-decoration: underline;" css]]
				sym = _strike    ["strike" css: g_strdup_printf ["%s text-decoration: line-through;" css]]
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

	;; Further styles from face
	unless null? face [
		bgcolor: as red-tuple!	(object/get-values face) + FACE_OBJ_COLOR
		if TYPE_OF(bgcolor) = TYPE_TUPLE [
			rgba: to-css-rgba bgcolor
			css: add-to-string css "%s background-color: %s;" as handle! rgba
			g_free as handle! rgba
		]
	]

	css: add-to-string css "%s}" null

	;; DEBUG: print ["css-styles -> css: " css lf]
	
	css
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