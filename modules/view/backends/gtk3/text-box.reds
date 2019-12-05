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
	r: 0 g: 0 b: 0 a: 0
	color-u8-to-u16 color :r :g :b :a
	attr: pango_attr_foreground_new r g b
	attr/start: s
	attr/end: s + e
	pango_attr_list_change lc/attrs attr

	attr: pango_attr_foreground_alpha_new a
	attr/start: s
	attr/end: s + e
	pango_attr_list_change lc/attrs attr
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
	r: 0 g: 0 b: 0 a: 0
	color-u8-to-u16 color :r :g :b :a
	attr: pango_attr_background_new r g b
	attr/start: s
	attr/end: s + e
	pango_attr_list_change lc/attrs attr

	attr: pango_attr_background_alpha_new a
	attr/start: s
	attr/end: s + e
	pango_attr_list_change lc/attrs attr
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
	attr/end: s + e
	pango_attr_list_change lc/attrs attr
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
	attr/end: s + e
	pango_attr_list_change lc/attrs attr
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
	attr/end: s + e
	pango_attr_list_change lc/attrs attr
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
	attr/end: s + e
	pango_attr_list_change lc/attrs attr
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
	attr/end: s + e
	pango_attr_list_change lc/attrs attr
]

OS-text-box-font-size: func [
	dc			[handle!]
	layout		[handle!]
	pos			[integer!]
	len			[integer!]
	size		[float!]
	/local
		lc		[layout-ctx!]
		s		[integer!]
		e		[integer!]
		attr	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	s: utf8-to-bytes lc/text pos
	e: utf8-to-bytes lc/text + s len
	attr: pango_attr_size_new PANGO_SCALE * as integer! size
	attr/start: s
	attr/end: s + e
	pango_attr_list_change lc/attrs attr
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
	ft-clr		[integer!]				;-- TBD: to replace font color
	catch?		[logic!]
	return:		[handle!]
	/local
		values	[red-value!]
		text	[red-string!]
		state	[red-block!]
		size	[red-pair!]
		font	[red-object!]
		parent	[red-object!]
		cached?	[logic!]
		attrs	[handle!]
		int		[red-integer!]
		layout	[handle!]
		para	[handle!]
		bool	[red-logic!]
		lc		[layout-ctx!]
		str		[c-string!]
		len		[integer!]
		styles	[red-block!]
][
	values: object/get-values box

	text: as red-string! values + FACE_OBJ_TEXT
	state: as red-block! values + FACE_OBJ_EXT3
	size: as red-pair! values + FACE_OBJ_SIZE
	font: as red-object! values + FACE_OBJ_FONT
	parent: as red-object! values + FACE_OBJ_PARENT
	styles: as red-block! values + FACE_OBJ_DATA
	cached?: TYPE_OF(state) = TYPE_BLOCK

	either cached? [
		int: as red-integer! block/rs-head state
		layout: as handle! int/value
		int: int + 1 para: as handle! int/value
		bool: as red-logic! int + 2
		bool/value: false
	][
		para: null
		if null? pango-context [
			pango-context: gdk_pango_context_get
		]
		layout: pango_layout_new pango-context

		block/make-at state 4
		integer/make-in state as integer! layout
		integer/make-in state as integer! para
		none/make-in state
		logic/make-in state false
	]
	if all [
		TYPE_OF(font) <> TYPE_OBJECT
		TYPE_OF(parent) = TYPE_OBJECT
	][
		font: as red-object! (object/get-values parent) + FACE_OBJ_FONT
	]
	attrs: either TYPE_OF(font) = TYPE_OBJECT [
		create-pango-attrs null font
	][
		create-simple-attrs default-font-name default-font-size null
	]
	len: -1
	str: unicode/to-utf8 text :len
	pango_layout_set_width layout PANGO_SCALE * size/x
	pango_layout_set_height layout PANGO_SCALE * size/y
	pango_layout_set_wrap layout PANGO_WRAP_WORD_CHAR			;-- TBD: apply para
	pango_layout_set_text layout str -1

	if all [
		TYPE_OF(styles) = TYPE_BLOCK
		1 < block/rs-length? styles
	][
		;-- this is not dynamic but lc/layout would change dynamically for each rich-text
		lc: declare layout-ctx!
		lc/layout: layout
		lc/text: str
		lc/attrs: attrs
		parse-text-styles target as handle! lc styles 7FFFFFFFh catch?
	]
	pango_layout_set_attributes layout attrs
	free-pango-attrs attrs
	layout
]
