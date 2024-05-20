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
#define PANGO_MAX_SIZE				16777216

max-line-cnt:  0

utf8-to-bytes: func [
	text		[c-string!]
	len			[integer!]
	return:		[integer!]
	/local
		end		[c-string!]
][
	end: g_utf8_offset_to_pointer text len
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
		width	[integer!]
		height	[integer!]
		pos		[red-pair!]
		rect	[tagRECT value]
		lrect	[tagRECT value]
		pline	[handle!]
		idx		[integer!]
		trail	[integer!]
		ok?		[logic!]
		text	[c-string!]
		text2	[c-string!]
		pt		[red-point2D!]
		x y		[integer!]
][
	rstate: as red-integer! block/rs-head state
	layout: as handle! rstate/value
	if null? layout [return as red-value! none-value]
	as red-value! switch type [
		TBOX_METRICS_OFFSET?
		TBOX_METRICS_OFFSET_LOWER [					;-- caret-to-offset
			int: as red-integer! arg0
			text: pango_layout_get_text layout
			text2: g_utf8_offset_to_pointer text int/value - 1
			idx: as integer! text2 - text
			pango_layout_index_to_pos layout idx :rect
			if type = TBOX_METRICS_OFFSET_LOWER [
				rect/x: rect/x + rect/width
				rect/y: rect/y + rect/height
			]
			point2D/push
				(as float32! rect/x) / (as float32! PANGO_SCALE)
				(as float32! rect/y) / (as float32! PANGO_SCALE)
		]
		TBOX_METRICS_INDEX?
		TBOX_METRICS_CHAR_INDEX? [					;-- offset-to-caret
			pos: as red-pair! arg0
			GET_PAIR_XY_INT(pos x y)
			idx: -1 trail: -1
			ok?: pango_layout_xy_to_index layout (x * PANGO_SCALE) (y * PANGO_SCALE) :idx :trail
			text: pango_layout_get_text layout
			idx: g_utf8_pointer_to_offset text text + idx
			if all [type = TBOX_METRICS_INDEX? 0 <> trail][idx: idx + 1]
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
			point2D/push as float32! width as float32! height
		]
		TBOX_METRICS_LINE_COUNT [
			idx: pango_layout_get_line_count layout
			integer/push idx
		]
		TBOX_METRICS_LINE_HEIGHT [
			int: as red-integer! arg0
			pango_layout_index_to_pos layout int/value :rect
			float/push (as float! rect/height) / (as float! PANGO_SCALE)
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
		pt		[red-point2D!]
		sx sy	[integer!]
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
	either all [
		font <> null
		TYPE_OF(font) = TYPE_OBJECT
	][
		attrs: create-pango-attrs box font
	][
		attrs: pango_attr_list_new		;-- or pango_attr_list_copy default-attrs
	]
	len: -1
	str: unicode/to-utf8 text :len
	either ANY_COORD?(size) [
		GET_PAIR_XY_INT(size sx sy)
		sx: PANGO_SCALE * sx
		sy: PANGO_SCALE * sy
		if any [sx <= 0 sx >= PANGO_MAX_SIZE][sx: -1]
		if any [sy <= 0 sy >= PANGO_MAX_SIZE][sy: -1]
	][
		sx: -1
		sy: -1
	]
	pango_layout_set_width layout sx
	pango_layout_set_height layout sy
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
		parse-text-styles target as handle! lc styles text catch?
	]
	pango_layout_set_attributes layout attrs
	pango_attr_list_unref attrs
	layout
]
