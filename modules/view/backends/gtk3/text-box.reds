Red/System [
	Title:	"Text Box Windows DirectWrite Backend"
	Author: "Xie Qingtian, RCqls"
	File: 	%text-box.reds
	Tabs: 	4
	Dependency: %draw-d2d.reds
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define TBOX_METRICS_OFFSET?		0
#define TBOX_METRICS_INDEX?			1
#define TBOX_METRICS_LINE_HEIGHT	2
#define TBOX_METRICS_SIZE			3
#define TBOX_METRICS_LINE_COUNT		4
#define TBOX_METRICS_CHAR_INDEX?	5
#define TBOX_METRICS_OFFSET_LOWER	6

#define PANGO_TEXT_MARKUP_SIZED		500

max-line-cnt:  0


layout-ctx-init: func [
	lc 			[layout-ctx!]
	text 		[c-string!]
	text-len	[integer!]
][
	lc/text: text
	lc/text-len: text-len
	lc/text-pos: 0
	lc/attr-list: pango_attr_list_new
]

utf8-to-bytes: func [
	text		[c-string!]
	len			[integer!]
	return:		[integer!]
	/local
		end		[c-string!]
][
	end: text
	loop len [
		end: unicode/utf8-next-char end
	]
	as integer! end - text
]

OS-text-box-color: func [
	dc			[handle!]
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	color		[integer!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		a		[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len
	a: color >> 24 and FFh
	r: color >> 16 and FFh
	g: color >> 8 and FFh
	b: color and FFh
	attr: pango_attr_foreground_new r g b
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr

	attr: pango_attr_foreground_alpha_new a
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr
]

OS-text-box-background: func [
	dc			[handle!]
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	color		[integer!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		a		[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len
	a: color >> 24 and FFh
	r: color >> 16 and FFh
	g: color >> 8 and FFh
	b: color and FFh
	attr: pango_attr_background_new r g b
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr

	attr: pango_attr_background_alpha_new a
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr
]

OS-text-box-weight: func [
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	weight		[integer!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len
	attr: pango_attr_weight_new weight
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr
]

OS-text-box-italic: func [
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len
	attr: pango_attr_style_new PANGO_STYLE_ITALIC
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr
]

OS-text-box-underline: func [
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	opts		[red-value!]					;-- options
	tail		[red-value!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len
	attr: pango_attr_underline_new PANGO_UNDERLINE_SINGLE
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr
]

OS-text-box-strikeout: func [
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	opts		[red-value!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len
	attr: pango_attr_strikethrough_new true
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr
]

OS-text-box-border: func [
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	opts		[red-value!]					;-- options
	tail		[red-value!]
][
	0
]

OS-text-box-font-name: func [
	dc			[handle!]
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	name		[red-string!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		len2	[integer!]
		str		[c-string!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len

	len2: -1
	str: unicode/to-utf8 name :len2
	attr: pango_attr_family_new str
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr
]

OS-text-box-font-size: func [
	nsfont	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len
	attr: pango_attr_size_new as integer! size
	attr/start: s
	attr/end: e
	pango_attr_list_insert lc/attr-list attr
]

OS-text-box-metrics: func [
	state		[red-block!]
	arg0		[red-value!]
	type		[integer!]
	return:		[red-value!]
	/local
		int		[red-integer!]
		rstate	[red-integer!]
		layout	[handle!]
		x		[float!]
		y		[float!]
		width	[integer!]
		height	[integer!]
		pos		[red-pair!]
		rect	[tagRECT value]
		lrect	[tagRECT value]
		pline	[handle!]
		idx		[integer!]
		trail	[integer!]
		ok?		[logic!]
		;; DEBUG: fd		[handle!]
][
	;; DEBUG: print ["OS-text-box-metrics: " get-symbol-name type lf]
	rstate: as red-integer! block/rs-head state
	layout: as handle! rstate/value
	;; DEBUG: print ["layout: " layout lf]
	;; DEBUG: fd: pango_layout_get_font_description layout print ["OS-text-box-metrics layout: " layout " " pango_font_description_get_family fd " " pango_font_description_get_size fd lf]
	if null? layout [return as red-value! none-value]
	as red-value! switch type [
		TBOX_METRICS_OFFSET?
		TBOX_METRICS_OFFSET_LOWER [ ; caret-to-offset
			int: as red-integer! arg0
			pango_layout_index_to_pos layout int/value - 1 :rect
			;; DEBUG: print ["TBOX_METRICS_OFFSET? " rect/x / PANGO_SCALE "x" rect/y / PANGO_SCALE "x" rect/width / PANGO_SCALE "x" rect/height / PANGO_SCALE lf]
			pair/push rect/x / PANGO_SCALE  rect/y / PANGO_SCALE
		]
		TBOX_METRICS_INDEX?
		TBOX_METRICS_CHAR_INDEX? [ ; offset-to-caret
			pos: as red-pair! arg0
			idx: -1 trail: -1
			;; DEBUG: print ["TBOX_METRICS_INDEX? pos: " pos/x "x" pos/y lf]
			ok?: pango_layout_xy_to_index layout (pos/x * PANGO_SCALE) (pos/y * PANGO_SCALE) :idx :trail
			;; DEBUG: print ["TBOX_METRICS_INDEX? " pos/x "x" pos/y  " " ok? " index: " idx + 1   lf]
			if all[type = TBOX_METRICS_INDEX? 0 <> trail] [idx: idx + 1]
			integer/push idx + 1
		]
		TBOX_METRICS_SIZE [
			pline: pango_layout_get_line layout 0
			pango_layout_line_get_pixel_extents pline rect lrect
			width: -1 height: -1
			;pango_layout_get_pixel_size layout :width :height
			; width: (pango_layout_get_width layout) / PANGO_SCALE
			height: (pango_layout_get_line_count layout) * lrect/height
			width: lrect/width
			;; DEBUG: print ["TBOX_METRICS_SIZE: " width "x" height " " pango_layout_get_line_count layout lf]
			;print ["text: " layout/text lf]
			pair/push width height
		]
		TBOX_METRICS_LINE_COUNT [
			idx: pango_layout_get_line_count layout
			;; DEBUG: print ["TBOX_METRICS_LINE_COUNT: " idx lf]
			integer/push idx
		]
		TBOX_METRICS_LINE_HEIGHT [
			int: as red-integer! arg0
			pango_layout_index_to_pos layout int/value :rect
			height: rect/height / PANGO_SCALE
			;; DEBUG: print ["TBOX_METRICS_LINE_HEIGHT " height  " (" rect/x "x" rect/y "x" rect/width "x" rect/height ")" lf]
			integer/push height
		]
		default [
			none-value
		]
	]
]

OS-text-box-layout: func [
	box			[red-object!]
	target		[int-ptr!]
	ft-clr		[integer!]
	catch?		[logic!]
	return:		[handle!]
	/local
		hWnd	[handle!]
		values	[red-value!]
		size	[red-pair!]
		rstate	[red-integer!]
		bool	[red-logic!]
		state	[red-block!]
		styles	[red-block!]
		pval	[red-value!]
		vec		[red-vector!]
		obj		[red-object!]
		w		[integer!]
		h		[integer!]
		dc		[draw-ctx!]
		lc		[layout-ctx!]
		cached?	[logic!]
		force?	[logic!]
		font	[red-object!]
		hFont	[handle!]
		clr		[integer!]
		text	[red-string!]
		len		[integer!]
		str		[c-string!]
		pc		[handle!]
		ft-ok?	[logic!]
][
	;; DEBUG: print ["OS-text-box-layout: " box " " face-handle? box " target: " target lf]
	values: object/get-values box
	state: as red-block! values + FACE_OBJ_EXT3
	cached?: TYPE_OF(state) = TYPE_BLOCK
	;; DEBUG: print ["cached?: " cached? " state: " state lf]
	force?: either cached? [
		rstate: as red-integer! block/rs-head state
		bool: as red-logic! rstate + 1
		;; DEBUG: print ["rstate: " rstate " -> " rstate/value " bool: " bool " -> " bool/value  lf]
		bool/value
	][true]
	;; DEBUG: print ["force?: " force? lf]

	lc: declare layout-ctx! ; this is not dynamic but lc/layout would change dynamically for each rich-text
	text: as red-string! values + FACE_OBJ_TEXT
	font: as red-object! values + FACE_OBJ_FONT
	ft-ok?: TYPE_OF(font) = TYPE_OBJECT ;all[not null? target TYPE_OF(font) = TYPE_OBJECT]
	either ft-ok? [
		hFont: get-font-handle font 0
		if null? hFont [hFont: CREATE-DEFAULT-FONT]
	][
		hFont: CREATE-DEFAULT-FONT
	]

	len: -1
	str: unicode/to-utf8 text :len

	layout-ctx-init lc str len

	;; DEBUG: print ["OS-text-box-layout lc/text: " lc/text " " lc/text-len lf]

	size: as red-pair! values + FACE_OBJ_SIZE

	either force? [
		;; create lc/layout
		;; DEBUG: print ["create layout: " target  lf]
		either null? target [
			either cached? [lc/layout: as handle! rstate/value]
			[
				; this is when OS-text-box-metrics is used before drawing
				if null? pango-context [pango-context: gdk_pango_context_get]
				lc/layout: pango_layout_new pango-context
				;; DEBUG: print ["rich-text layout: " lc/layout " " pango_font_description_get_family hFont " " pango_font_description_get_size hFont lf]
			]
		][
			dc: as draw-ctx! target
			dc/font-desc: hFont
			lc/layout: make-pango-cairo-layout dc/raw dc/font-desc
			;; DEBUG: print ["rich-text layout with target: " lc/layout lf]
		]
		;; DEBUG: print ["with  target: " target " lc/layout: " lc/layout lf]
		either cached? [
			rstate/value: as integer! lc/layout
			bool/value: false
			;; DEBUG: print ["lc/layout force to be updated: " lc/layout " bool: " bool/value lf]
		][
			block/make-at state 3 									;maybe more later
			;; DEBUG: print ["lc/layout newly created: " lc/layout lf]
			integer/make-in state as integer! lc/layout				; handle for lc/layout
			logic/make-in state either null? target [true][false] 	; force build lc/layout
			logic/make-in state true								; possible use for redraw used in gui.red/update-richtext
		]
	][
		lc/layout: as handle! rstate/value
		;; DEBUG: print ["lc/layout cached: " lc/layout lf]
	]
	pango_layout_set_font_description lc/layout hFont

	styles: as red-block! values + FACE_OBJ_DATA
	if all [
		TYPE_OF(styles) = TYPE_BLOCK
		1 < block/rs-length? styles
	][
		parse-text-styles target as handle! lc styles 7FFFFFFFh catch?
	]
	pango-layout-set-text lc size
	as handle! lc
]

pango-layout-apply-attr: func [
	lc		[layout-ctx!]
][
	pango_layout_set_text lc/layout lc/text -1
	unless null? lc/attr-list [
		pango_layout_set_attributes lc/layout lc/attr-list
		pango_attr_list_unref lc/attr-list
		lc/attr-list: null
	]
]

pango-layout-set-text: func [
	lc		[layout-ctx!]
	size	[red-pair!]
][
	unless null? lc [
		pango-layout-apply-attr lc
		pango_layout_set_width lc/layout PANGO_SCALE * size/x
		pango_layout_set_height lc/layout PANGO_SCALE * size/y
		pango_layout_set_wrap lc/layout PANGO_WRAP_WORD_CHAR
	]
]
