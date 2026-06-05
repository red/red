Red/System [
	Title:	"Cairo Draw dialect backend"
	Author: "Qingtian Xie, Honix, RCqls"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %text-box.reds

#define MAX_COLORS				256		;-- max number of colors for gradient

#enum cairo_operator_t! [
	CAIRO_OPERATOR_CLEAR
	CAIRO_OPERATOR_SOURCE
	CAIRO_OPERATOR_OVER
	CAIRO_OPERATOR_IN
	CAIRO_OPERATOR_OUT
	CAIRO_OPERATOR_ATOP
	CAIRO_OPERATOR_DEST
	CAIRO_OPERATOR_DEST_OVER
	CAIRO_OPERATOR_DEST_IN
	CAIRO_OPERATOR_DEST_OUT
	CAIRO_OPERATOR_DEST_ATOP
	CAIRO_OPERATOR_XOR
	CAIRO_OPERATOR_ADD
	CAIRO_OPERATOR_SATURATE
	CAIRO_OPERATOR_MULTIPLY
	CAIRO_OPERATOR_SCREEN
	CAIRO_OPERATOR_OVERLAY
	CAIRO_OPERATOR_DARKEN
	CAIRO_OPERATOR_LIGHTEN
	CAIRO_OPERATOR_COLOR_DODGE
	CAIRO_OPERATOR_COLOR_BURN
	CAIRO_OPERATOR_HARD_LIGHT
	CAIRO_OPERATOR_SOFT_LIGHT
	CAIRO_OPERATOR_DIFFERENCE
	CAIRO_OPERATOR_EXCLUSION
	CAIRO_OPERATOR_HSL_HUE
	CAIRO_OPERATOR_HSL_SATURATION
	CAIRO_OPERATOR_HSL_COLOR
	CAIRO_OPERATOR_HSL_LUMINOSITY
]

#enum cairo_fill_rule_t! [
	CAIRO_FILL_RULE_WINDING
	CAIRO_FILL_RULE_EVEN_ODD
]

#enum MATRIX-ORDER! [
	MATRIX-APPEND
	MATRIX-PREPEND
]

cairo_rectangle_t!: alias struct! [
	x		[float!]
	y		[float!]
	width	[float!]
	height	[float!]
]

cairo_rectangle_list_t!: alias struct! [
	status			[integer!]
	rectangles		[int-ptr!]
	num_rectangles	[integer!]
]

free-pango-cairo-font: func [
	dc		[draw-ctx!]
][
	unless null? dc/font-attrs [
		pango_attr_list_unref dc/font-attrs
		dc/font-attrs: null
	]
	unless null? dc/font-opts [
		cairo_font_options_destroy dc/font-opts
		dc/font-opts: null
	]
]

set-source-color-alpha: func [
	cr			[handle!]
	color		[integer!]
	alpha-scale	[float!]
	/local
		r		[float!]
		b		[float!]
		g		[float!]
		a		[float!]
][
	r: as-float color and FFh
	r: r / 255.0
	g: as-float color >> 8 and FFh
	g: g / 255.0
	b: as-float color >> 16 and FFh
	b: b / 255.0
	a: as-float color >> 24 and FFh
	a: 1.0 - (a / 255.0)
	a: a * alpha-scale
	if a < 0.0 [a: 0.0]
	if a > 1.0 [a: 1.0]
	cairo_set_source_rgba cr r g b a
]

set-source-color: func [
	cr			[handle!]
	color		[integer!]
][
	set-source-color-alpha cr color 1.0
]

draw-begin: func [
	ctx			[draw-ctx!]
	cr			[handle!]
	img			[red-image!]
	on-graphic?	[logic!]
	pattern?	[logic!]
	return:		[draw-ctx!]
	/local
		grad	[gradient!]
		fe		[cairo_font_extents_t! value]
][
	ctx/cr:				cr
	ctx/pen-pattern:	null
	ctx/pen-width:		1.0
	ctx/pen-color:		0						;-- default: black
	ctx/brush-color:	0
	ctx/font-color:		0
	ctx/font-color?:	no
	ctx/pen?:			yes
	ctx/brush?:			no
	ctx/shadow?:		no
	ctx/shadow-offset-x: 0.0
	ctx/shadow-offset-y: 0.0
	ctx/shadow-blur:	0.0
	ctx/shadow-spread:	0.0
	ctx/shadow-color:	0
	ctx/shadow-inset?:	no
	ctx/shadows/next:	null
	ctx/clip-path:		null
	ctx/clip-rule:		CAIRO_FILL_RULE_WINDING
	ctx/clip-x1:		0.0
	ctx/clip-y1:		0.0
	ctx/clip-x2:		0.0
	ctx/clip-y2:		0.0
	ctx/matrix-order:	MATRIX-PREPEND
	ctx/pattern?:		pattern?
	ctx/font-antialias: CAIRO_ANTIALIAS_DEFAULT
	ctx/line-width?:	yes

	cairo_get_matrix cr as cairo_matrix_t! ctx/device-matrix
	cairo_identity_matrix cr

	grad: ctx/grad-pen
	grad/on?: off
	grad/matrix-on?: off
	grad/count: 0
	grad/offset-on?: off
	grad/focal-on?: off
	grad/pattern-on?: off

	grad: ctx/grad-brush
	grad/on?: off
	grad/matrix-on?: off
	grad/count: 0
	grad/offset-on?: off
	grad/focal-on?: off
	grad/pattern-on?: off

	ctx/font-attrs:		null
	ctx/font-opts:		null
	ctx/utf8-buffer:	null
	ctx/utf8-buffer-size: 0
	cairo_font_extents cr fe							;-- init fe with default font metrics
	ctx/font-ascent:	fe/ascent

	cairo_set_line_width cr 1.0
	cairo_set_operator cr CAIRO_OPERATOR_OVER
	set-source-color cr 0
	ctx
]

draw-end: func [
	dc			[draw-ctx!]
	hWnd		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	pattern?	[logic!]
][
	cairo_identity_matrix dc/cr
	free-pango-cairo-font dc
	unless null? dc/utf8-buffer [
		free dc/utf8-buffer
		dc/utf8-buffer: null
		dc/utf8-buffer-size: 0
	]
	if dc/grad-pen/on? [
		free-gradient dc/grad-pen
		dc/grad-pen/on?: off
	]
	if dc/grad-brush/on? [
		free-gradient dc/grad-brush
		dc/grad-brush/on?: off
	]
	free-shadow dc
	if dc/clip-path <> null [
		cairo_path_destroy dc/clip-path
		dc/clip-path: null
	]
]

cairo-matrix-translate: func [
	cr		[handle!]
	x		[float!]
	y		[float!]
	order	[MATRIX-ORDER!]
	/local
		m	[cairo_matrix_t! value]
		c	[cairo_matrix_t! value]
][
	if order = MATRIX-PREPEND [
		cairo_translate cr x y
		exit
	]
	cairo_matrix_init_translate m x y
	cairo_get_matrix cr c
	cairo_matrix_multiply c c m
	cairo_set_matrix cr c
]

cairo-matrix-scale: func [
	cr		[handle!]
	x		[float!]
	y		[float!]
	order	[MATRIX-ORDER!]
	/local
		m	[cairo_matrix_t! value]
		c	[cairo_matrix_t! value]
][
	if order = MATRIX-PREPEND [
		cairo_scale cr x y
		exit
	]
	cairo_matrix_init_scale m x y
	cairo_get_matrix cr c
	cairo_matrix_multiply c c m
	cairo_set_matrix cr c
]

cairo-matrix-rotate: func [
	cr		[handle!]
	r		[float!]
	order	[MATRIX-ORDER!]
	/local
		m	[cairo_matrix_t! value]
		c	[cairo_matrix_t! value]
][
	if order = MATRIX-PREPEND [
		cairo_rotate cr r
		exit
	]
	cairo_matrix_init_rotate m r
	cairo_get_matrix cr c
	cairo_matrix_multiply c c m
	cairo_set_matrix cr c
]

cairo-matrix-concat: func [
	cr		[handle!]
	m		[cairo_matrix_t!]
	order	[MATRIX-ORDER!]
	/local
		c	[cairo_matrix_t! value]
][
	if order = MATRIX-PREPEND [
		cairo_transform cr m
		exit
	]
	cairo_get_matrix cr c
	cairo_matrix_multiply c c m
	cairo_set_matrix cr c
]

ctx-matrix-adapt: func [
	dc		[draw-ctx!]
	saved	[cairo_matrix_t!]
	/local
		m	[cairo_matrix_t! value]
		c	[cairo_matrix_t! value]
][
	if dc/pattern? [exit]
	cairo_get_matrix dc/cr saved
	cairo_get_matrix dc/cr c
	cairo_matrix_multiply c c dc/device-matrix
	cairo_set_matrix dc/cr c
]

ctx-matrix-unadapt: func [
	dc		[draw-ctx!]
	saved	[cairo_matrix_t!]
][
	if dc/pattern? [exit]
	cairo_set_matrix dc/cr saved
]

append-clip-rectangles: func [
	cr			[handle!]
	rects		[cairo_rectangle_t!]
	count		[integer!]
	return:		[logic!]
	/local
		i		[integer!]
		any?	[logic!]
][
	i: 0
	any?: no
	while [i < count][
		if all [
			rects/width > 0.0
			rects/height > 0.0
		][
			cairo_rectangle cr rects/x rects/y rects/width rects/height
			any?: yes
		]
		rects: rects + 1
		i: i + 1
	]
	any?
]

clone-cairo-path: func [
	cr			[handle!]
	path		[handle!]
	return:		[handle!]
	/local
		saved	[handle!]
		copy	[handle!]
][
	if path = null [return null]
	saved: cairo_copy_path cr
	cairo_new_path cr
	cairo_append_path cr path
	copy: cairo_copy_path cr
	cairo_new_path cr
	if saved <> null [
		cairo_append_path cr saved
		cairo_path_destroy saved
	]
	copy
]

track-clip-path: func [
	dc			[draw-ctx!]
	path		[handle!]
	rule		[integer!]
	/local
		saved	[handle!]
		x1		[float!]
		y1		[float!]
		x2		[float!]
		y2		[float!]
][
	if path = null [
		free-clip-path dc
		exit
	]
	x1: 0.0
	y1: 0.0
	x2: 0.0
	y2: 0.0
	if dc/clip-path <> null [cairo_path_destroy dc/clip-path]
	dc/clip-path: clone-cairo-path dc/cr path
	dc/clip-rule: rule
	saved: cairo_copy_path dc/cr
	cairo_new_path dc/cr
	cairo_append_path dc/cr path
	cairo_path_extents dc/cr :x1 :y1 :x2 :y2
	cairo_new_path dc/cr
	if saved <> null [
		cairo_append_path dc/cr saved
		cairo_path_destroy saved
	]
	dc/clip-x1: x1
	dc/clip-y1: y1
	dc/clip-x2: x2
	dc/clip-y2: y2
]

free-gradient: func [
	grad		[gradient!]
][
	grad/matrix-on?: off
	if grad/pattern-on? [
		cairo_pattern_destroy grad/pattern
		grad/pattern-on?: off
	]
	if grad/type <> bitmap [
		free as byte-ptr! grad/colors
	]
]

free-shadow: func [
	dc			[draw-ctx!]
	/local
		s		[shadow!]
		nxt		[shadow!]
][
	s: dc/shadows/next
	while [s <> null][
		nxt: s/next
		free as byte-ptr! s
		s: nxt
	]
	dc/shadows/next: null
]

free-clip-path: func [
	dc			[draw-ctx!]
][
	if dc/clip-path <> null [
		cairo_path_destroy dc/clip-path
		dc/clip-path: null
	]
	dc/clip-rule: CAIRO_FILL_RULE_WINDING
]

abs-float: func [
	value		[float!]
	return:		[float!]
][
	either value < 0.0 [0.0 - value][value]
]

floor-int: func [
	value		[float!]
	return:		[integer!]
	/local
		i		[integer!]
][
	i: as integer! value
	if (as float! i) > value [i: i - 1]
	i
]

ceil-int: func [
	value		[float!]
	return:		[integer!]
	/local
		i		[integer!]
][
	i: as integer! value
	if (as float! i) < value [i: i + 1]
	i
]

box-blur-horizontal-a8: func [
	src			[byte-ptr!]
	dst			[byte-ptr!]
	width		[integer!]
	height		[integer!]
	stride		[integer!]
	radius		[integer!]
	/local
		y		[integer!]
		x		[integer!]
		i		[integer!]
		idx		[integer!]
		add		[integer!]
		sub		[integer!]
		size	[integer!]
		sum		[integer!]
		val		[integer!]
		row		[byte-ptr!]
		out		[byte-ptr!]
		p		[byte-ptr!]
][
	if any [width <= 0 height <= 0 radius <= 0][exit]
	size: (radius * 2) + 1
	y: 0
	while [y < height][
		row: src + (y * stride)
		out: dst + (y * stride)
		sum: ((as integer! row/1) and FFh) * (radius + 1)
		i: 1
		while [i <= radius][
			idx: either i < width [i][width - 1]
			p: row + idx
			sum: sum + ((as integer! p/1) and FFh)
			i: i + 1
		]
		x: 0
		while [x < width][
			val: sum / size
			p: out + x
			p/1: as-byte val
			add: x + radius + 1
			if add >= width [add: width - 1]
			sub: x - radius
			if sub < 0 [sub: 0]
			p: row + add
			sum: sum + ((as integer! p/1) and FFh)
			p: row + sub
			sum: sum - ((as integer! p/1) and FFh)
			x: x + 1
		]
		y: y + 1
	]
]

box-blur-vertical-a8: func [
	src			[byte-ptr!]
	dst			[byte-ptr!]
	width		[integer!]
	height		[integer!]
	stride		[integer!]
	radius		[integer!]
	/local
		y		[integer!]
		x		[integer!]
		i		[integer!]
		idx		[integer!]
		add		[integer!]
		sub		[integer!]
		size	[integer!]
		sum		[integer!]
		val		[integer!]
		p		[byte-ptr!]
][
	if any [width <= 0 height <= 0 radius <= 0][exit]
	size: (radius * 2) + 1
	x: 0
	while [x < width][
		p: src + x
		sum: ((as integer! p/1) and FFh) * (radius + 1)
		i: 1
		while [i <= radius][
			idx: either i < height [i][height - 1]
			p: src + (idx * stride) + x
			sum: sum + ((as integer! p/1) and FFh)
			i: i + 1
		]
		y: 0
		while [y < height][
			val: sum / size
			p: dst + (y * stride) + x
			p/1: as-byte val
			add: y + radius + 1
			if add >= height [add: height - 1]
			sub: y - radius
			if sub < 0 [sub: 0]
			p: src + (add * stride) + x
			sum: sum + ((as integer! p/1) and FFh)
			p: src + (sub * stride) + x
			sum: sum - ((as integer! p/1) and FFh)
			y: y + 1
		]
		x: x + 1
	]
]

blur-a8-mask: func [
	data		[byte-ptr!]
	width		[integer!]
	height		[integer!]
	stride		[integer!]
	radius		[integer!]
	/local
		tmp		[byte-ptr!]
		size	[integer!]
		pass	[integer!]
][
	if any [radius <= 0 width <= 0 height <= 0][exit]
	size: stride * height
	tmp: allocate size
	if tmp = null [exit]
	pass: 0
	while [pass < 3][
		box-blur-horizontal-a8 data tmp width height stride radius
		box-blur-vertical-a8 tmp data width height stride radius
		pass: pass + 1
	]
	free tmp
]

clone-shadow-chain: func [
	src			[shadow!]
	return:		[shadow!]
	/local
		head	[shadow!]
		tail	[shadow!]
		node	[shadow!]
][
	head: null
	tail: null
	while [src <> null][
		node: as shadow! allocate size? shadow!
		node/offset-x: src/offset-x
		node/offset-y: src/offset-y
		node/blur: src/blur
		node/spread: src/spread
		node/color: src/color
		node/inset?: src/inset?
		node/next: null
		either head = null [
			head: node
		][
			tail/next: node
		]
		tail: node
		src: src/next
	]
	head
]

draw-shadow-path-layer: func [
	dc			[draw-ctx!]
	path		[handle!]
	stroke?		[logic!]
	offset-x	[float!]
	offset-y	[float!]
	spread		[float!]
	color		[integer!]
	alpha		[float!]
	/local
		cr		[handle!]
		x1		[float!]
		y1		[float!]
		x2		[float!]
		y2		[float!]
		w		[float!]
		h		[float!]
		cx		[float!]
		cy		[float!]
		sx		[float!]
		sy		[float!]
		iw		[float!]
		ih		[float!]
		inner?	[logic!]
][
	cr: dc/cr

	cairo_save cr
	cairo_new_path cr
	either spread <> 0.0 [
		cairo_append_path cr path
		x1: 0.0 y1: 0.0 x2: 0.0 y2: 0.0
		either stroke? [
			cairo_stroke_extents cr :x1 :y1 :x2 :y2
		][
			cairo_path_extents cr :x1 :y1 :x2 :y2
		]
		cairo_new_path cr
		w: x2 - x1
		h: y2 - y1
		either all [w > 0.0 h > 0.0][
			cx: x1 + (w / 2.0)
			cy: y1 + (h / 2.0)
			sx: (w + (spread * 2.0)) / w
			sy: (h + (spread * 2.0)) / h
			cairo_translate cr offset-x + cx offset-y + cy
			cairo_scale cr sx sy
			cairo_translate cr 0.0 - cx 0.0 - cy
		][
			cairo_translate cr offset-x offset-y
		]
	][
		cairo_translate cr offset-x offset-y
	]
	cairo_append_path cr path
	set-source-color-alpha cr color alpha
	either stroke? [
		cairo_stroke cr
	][
		cairo_fill cr
	]
	cairo_restore cr
]

draw-inset-shadow-path-layer: func [
	dc			[draw-ctx!]
	path		[handle!]
	offset-x	[float!]
	offset-y	[float!]
	spread		[float!]
	color		[integer!]
	alpha		[float!]
	/local
		cr		[handle!]
		x1		[float!]
		y1		[float!]
		x2		[float!]
		y2		[float!]
		w		[float!]
		h		[float!]
		cx		[float!]
		cy		[float!]
		sx		[float!]
		sy		[float!]
		iw		[float!]
		ih		[float!]
		inner	[logic!]
][
	cr: dc/cr

	cairo_save cr
	cairo_new_path cr
	cairo_append_path cr path
	cairo_clip cr

	cairo_new_path cr
	cairo_append_path cr path

	inner: yes
	either spread <> 0.0 [
		x1: 0.0 y1: 0.0 x2: 0.0 y2: 0.0
		cairo_path_extents cr :x1 :y1 :x2 :y2
		w: x2 - x1
		h: y2 - y1
		either all [w > 0.0 h > 0.0][
			cx: x1 + (w / 2.0)
			cy: y1 + (h / 2.0)
			iw: w - (spread * 2.0)
			ih: h - (spread * 2.0)
			either all [iw > 0.0 ih > 0.0][
				sx: iw / w
				sy: ih / h
				cairo_translate cr offset-x + cx offset-y + cy
				cairo_scale cr sx sy
				cairo_translate cr 0.0 - cx 0.0 - cy
			][
				inner: no
			]
		][
			cairo_translate cr offset-x offset-y
		]
	][
		cairo_translate cr offset-x offset-y
	]
	if inner [cairo_append_path cr path]
	cairo_set_fill_rule cr CAIRO_FILL_RULE_EVEN_ODD
	set-source-color-alpha cr color alpha
	cairo_fill cr
	cairo_set_fill_rule cr CAIRO_FILL_RULE_WINDING
	cairo_restore cr
]

draw-blurred-shadow-mask: func [
	dc			[draw-ctx!]
	path		[handle!]
	stroke?		[logic!]
	offset-x	[float!]
	offset-y	[float!]
	blur		[float!]
	spread		[float!]
	color		[integer!]
	/local
		cr		[handle!]
		mcr		[handle!]
		surf	[handle!]
		data	[byte-ptr!]
		x1		[float!]
		y1		[float!]
		x2		[float!]
		y2		[float!]
		w		[float!]
		h		[float!]
		cx		[float!]
		cy		[float!]
		sx		[float!]
		sy		[float!]
		pad		[float!]
		origin-x [integer!]
		origin-y [integer!]
		max-x	[integer!]
		max-y	[integer!]
		width	[integer!]
		height	[integer!]
		stride	[integer!]
		radius	[integer!]
		origin-xf [float!]
		origin-yf [float!]
][
	cr: dc/cr
	x1: 0.0 y1: 0.0 x2: 0.0 y2: 0.0

	cairo_save cr
	cairo_new_path cr
	cairo_append_path cr path
	either stroke? [
		cairo_stroke_extents cr :x1 :y1 :x2 :y2
	][
		cairo_path_extents cr :x1 :y1 :x2 :y2
	]
	cairo_new_path cr
	cairo_restore cr

	w: x2 - x1
	h: y2 - y1
	if any [w <= 0.0 h <= 0.0][exit]

	pad: blur + abs-float spread + 3.0
	origin-x: floor-int x1 - pad
	origin-y: floor-int y1 - pad
	max-x: ceil-int x2 + pad
	max-y: ceil-int y2 + pad
	width: max-x - origin-x
	height: max-y - origin-y
	if any [width <= 0 height <= 0][exit]

	surf: cairo_image_surface_create CAIRO_FORMAT_A8 width height
	if surf = null [exit]
	mcr: cairo_create surf
	if mcr = null [
		cairo_surface_destroy surf
		exit
	]

	origin-xf: as float! origin-x
	origin-yf: as float! origin-y
	cairo_translate mcr 0.0 - origin-xf 0.0 - origin-yf
	cairo_new_path mcr
	either spread <> 0.0 [
		cairo_append_path mcr path
		x1: 0.0 y1: 0.0 x2: 0.0 y2: 0.0
		either stroke? [
			cairo_stroke_extents mcr :x1 :y1 :x2 :y2
		][
			cairo_path_extents mcr :x1 :y1 :x2 :y2
		]
		cairo_new_path mcr
		w: x2 - x1
		h: y2 - y1
		if all [w > 0.0 h > 0.0][
			cx: x1 + (w / 2.0)
			cy: y1 + (h / 2.0)
			sx: (w + (spread * 2.0)) / w
			sy: (h + (spread * 2.0)) / h
			if all [sx > 0.0 sy > 0.0][
				cairo_translate mcr cx cy
				cairo_scale mcr sx sy
				cairo_translate mcr 0.0 - cx 0.0 - cy
			]
		]
	][
		0
	]
	cairo_append_path mcr path
	cairo_set_source_rgba mcr 1.0 1.0 1.0 1.0
	either stroke? [
		cairo_stroke mcr
	][
		cairo_fill mcr
	]
	cairo_destroy mcr

	cairo_surface_flush surf
	data: cairo_image_surface_get_data surf
	stride: cairo_format_stride_for_width CAIRO_FORMAT_A8 width
	radius: as integer! blur
	if radius < 1 [radius: 1]
	blur-a8-mask data width height stride radius
	cairo_surface_mark_dirty surf

	cairo_save cr
	set-source-color cr color
	cairo_mask_surface cr surf origin-xf + offset-x origin-yf + offset-y
	cairo_restore cr
	cairo_surface_destroy surf
]

draw-blurred-inset-shadow-mask: func [
	dc			[draw-ctx!]
	path		[handle!]
	offset-x	[float!]
	offset-y	[float!]
	blur		[float!]
	spread		[float!]
	color		[integer!]
	/local
		cr		[handle!]
		mcr		[handle!]
		surf	[handle!]
		data	[byte-ptr!]
		x1		[float!]
		y1		[float!]
		x2		[float!]
		y2		[float!]
		w		[float!]
		h		[float!]
		cx		[float!]
		cy		[float!]
		sx		[float!]
		sy		[float!]
		iw		[float!]
		ih		[float!]
		pad		[float!]
		origin-x [integer!]
		origin-y [integer!]
		max-x	[integer!]
		max-y	[integer!]
		width	[integer!]
		height	[integer!]
		stride	[integer!]
		radius	[integer!]
		origin-xf [float!]
		origin-yf [float!]
		inner	[logic!]
][
	cr: dc/cr
	x1: 0.0 y1: 0.0 x2: 0.0 y2: 0.0

	cairo_save cr
	cairo_new_path cr
	cairo_append_path cr path
	cairo_path_extents cr :x1 :y1 :x2 :y2
	cairo_new_path cr
	cairo_restore cr

	w: x2 - x1
	h: y2 - y1
	if any [w <= 0.0 h <= 0.0][exit]

	pad: blur + abs-float spread + abs-float offset-x + abs-float offset-y + 3.0
	origin-x: floor-int x1 - pad
	origin-y: floor-int y1 - pad
	max-x: ceil-int x2 + pad
	max-y: ceil-int y2 + pad
	width: max-x - origin-x
	height: max-y - origin-y
	if any [width <= 0 height <= 0][exit]

	surf: cairo_image_surface_create CAIRO_FORMAT_A8 width height
	if surf = null [exit]
	mcr: cairo_create surf
	if mcr = null [
		cairo_surface_destroy surf
		exit
	]

	origin-xf: as float! origin-x
	origin-yf: as float! origin-y
	cairo_translate mcr 0.0 - origin-xf 0.0 - origin-yf
	cairo_new_path mcr
	cairo_append_path mcr path

	inner: yes
	either spread <> 0.0 [
		x1: 0.0 y1: 0.0 x2: 0.0 y2: 0.0
		cairo_path_extents mcr :x1 :y1 :x2 :y2
		w: x2 - x1
		h: y2 - y1
		either all [w > 0.0 h > 0.0][
			cx: x1 + (w / 2.0)
			cy: y1 + (h / 2.0)
			iw: w - (spread * 2.0)
			ih: h - (spread * 2.0)
			either all [iw > 0.0 ih > 0.0][
				sx: iw / w
				sy: ih / h
				cairo_translate mcr offset-x + cx offset-y + cy
				cairo_scale mcr sx sy
				cairo_translate mcr 0.0 - cx 0.0 - cy
			][
				inner: no
			]
		][
			cairo_translate mcr offset-x offset-y
		]
	][
		cairo_translate mcr offset-x offset-y
	]
	if inner [cairo_append_path mcr path]
	cairo_set_fill_rule mcr CAIRO_FILL_RULE_EVEN_ODD
	cairo_set_source_rgba mcr 1.0 1.0 1.0 1.0
	cairo_fill mcr
	cairo_set_fill_rule mcr CAIRO_FILL_RULE_WINDING
	cairo_destroy mcr

	cairo_surface_flush surf
	data: cairo_image_surface_get_data surf
	stride: cairo_format_stride_for_width CAIRO_FORMAT_A8 width
	radius: as integer! blur
	if radius < 1 [radius: 1]
	blur-a8-mask data width height stride radius
	cairo_surface_mark_dirty surf

	cairo_save cr
	cairo_new_path cr
	cairo_append_path cr path
	cairo_clip cr
	set-source-color cr color
	cairo_mask_surface cr surf origin-xf origin-yf
	cairo_restore cr
	cairo_surface_destroy surf
]

draw-one-shadow-path: func [
	dc			[draw-ctx!]
	path		[handle!]
	stroke?		[logic!]
	offset-x	[float!]
	offset-y	[float!]
	blur		[float!]
	spread		[float!]
	color		[integer!]
	inset?		[logic!]
][
	either blur <= 0.0 [
		either inset? [
			draw-inset-shadow-path-layer dc path offset-x offset-y spread color 1.0
		][
			draw-shadow-path-layer dc path stroke? offset-x offset-y spread color 1.0
		]
	][
		either inset? [
			draw-blurred-inset-shadow-mask dc path offset-x offset-y blur spread color
		][
			draw-blurred-shadow-mask dc path stroke? offset-x offset-y blur spread color
		]
	]
]

draw-shadow-path: func [
	dc			[draw-ctx!]
	stroke?		[logic!]
	inset?		[logic!]
	/local
		path	[handle!]
		s		[shadow!]
][
	if not dc/shadow? [exit]

	path: cairo_copy_path dc/cr
	if dc/shadow-inset? = inset? [
		draw-one-shadow-path dc path stroke? dc/shadow-offset-x dc/shadow-offset-y dc/shadow-blur dc/shadow-spread dc/shadow-color inset?
	]
	s: dc/shadows/next
	while [s <> null][
		if s/inset? = inset? [
			draw-one-shadow-path dc path stroke? s/offset-x s/offset-y s/blur s/spread s/color inset?
		]
		s: s/next
	]
	cairo_new_path dc/cr
	cairo_append_path dc/cr path
	cairo_path_destroy path
]

do-draw-pen*: func [
	dc			[draw-ctx!]
	shadow?		[logic!]
	/local
		cr		[handle!]
		pattern	[handle!]
		saved	[cairo_matrix_t! value]
		restore? [logic!]
		x1		[float!]
		y1		[float!]
		x2		[float!]
		y2		[float!]
][
	cr: dc/cr
	either all [dc/pen? dc/line-width?][
		if shadow? [draw-shadow-path dc yes no]
		restore?: no
		either all [
			dc/grad-pen/on?
			dc/grad-pen/pattern-on?
		][
			pattern: dc/grad-pen/pattern
			if dc/grad-pen/type = bitmap [
				x1: 0.0 y1: 0.0 x2: 0.0 y2: 0.0
				cairo_stroke_extents cr :x1 :y1 :x2 :y2
				restore?: set-surface-brush-origin pattern x1 y1 saved
			]
			cairo_set_source cr pattern
		][
			set-source-color cr dc/pen-color
		]
		cairo_stroke cr
		if restore? [cairo_pattern_set_matrix pattern saved]
	][
		cairo_new_path cr
	]
]

do-draw-pen: func [
	dc			[draw-ctx!]
][
	do-draw-pen* dc yes
]

do-draw-path: func [
	dc			[draw-ctx!]
	/local
		cr		[handle!]
		pattern	[handle!]
		saved	[cairo_matrix_t! value]
		restore? [logic!]
		x1		[float!]
		y1		[float!]
		x2		[float!]
		y2		[float!]
][
	cr: dc/cr
	if any [dc/brush? all [dc/pen? dc/line-width?]][
		draw-shadow-path dc not dc/brush? no
	]
	if dc/brush? [
		restore?: no
		either all [
			dc/grad-brush/on?
			dc/grad-brush/pattern-on?
		][
			pattern: dc/grad-brush/pattern
			if dc/grad-brush/type = bitmap [
				x1: 0.0 y1: 0.0 x2: 0.0 y2: 0.0
				cairo_path_extents cr :x1 :y1 :x2 :y2
				restore?: set-surface-brush-origin pattern x1 y1 saved
			]
			cairo_set_source cr pattern
		][
			set-source-color cr dc/brush-color
		]
		cairo_fill_preserve cr
		if restore? [cairo_pattern_set_matrix pattern saved]
		draw-shadow-path dc no yes
	]
	do-draw-pen* dc no
]

line-distance: func [
	x1			[float!]
	y1			[float!]
	x2			[float!]
	y2			[float!]
	return:		[float!]
	/local
		x		[float!]
		y		[float!]
		px		[float!]
		py		[float!]
		delta	[float!]
][
	x: x1
	y: y1
	px: x2 - x
	py: y2 - y
	delta: (px * px) + (py * py)
	sqrt delta
]

mesh-set-color: func [
	pattern		[handle!]
	corner		[integer!]
	color		[integer!]
	/local
		r		[float!]
		g		[float!]
		b		[float!]
		a		[float!]
][
	r: as-float color and FFh
	r: r / 255.0
	g: as-float color >> 8 and FFh
	g: g / 255.0
	b: as-float color >> 16 and FFh
	b: b / 255.0
	a: as-float 255 - (color >>> 24)
	a: a / 255.0
	cairo_mesh_pattern_set_corner_color_rgba pattern corner r g b a
]

mesh-add-patch: func [
	pattern		[handle!]
	ix1			[float!]
	iy1			[float!]
	ox1			[float!]
	oy1			[float!]
	ox2			[float!]
	oy2			[float!]
	ix2			[float!]
	iy2			[float!]
	inner-color	[integer!]
	outer-color	[integer!]
][
	cairo_mesh_pattern_begin_patch pattern
	cairo_mesh_pattern_move_to pattern ix1 iy1
	cairo_mesh_pattern_line_to pattern ox1 oy1
	cairo_mesh_pattern_line_to pattern ox2 oy2
	cairo_mesh_pattern_line_to pattern ix2 iy2
	mesh-set-color pattern 0 inner-color
	mesh-set-color pattern 1 outer-color
	mesh-set-color pattern 2 outer-color
	mesh-set-color pattern 3 inner-color
	cairo_mesh_pattern_end_patch pattern
]

mesh-add-rect-ring: func [
	pattern		[handle!]
	x1			[float!]
	y1			[float!]
	x2			[float!]
	y2			[float!]
	cx			[float!]
	cy			[float!]
	p1			[float!]
	p2			[float!]
	color1		[integer!]
	color2		[integer!]
	/local
		i1x		[float!]
		i1y		[float!]
		i2x		[float!]
		i2y		[float!]
		i3x		[float!]
		i3y		[float!]
		i4x		[float!]
		i4y		[float!]
		o1x		[float!]
		o1y		[float!]
		o2x		[float!]
		o2y		[float!]
		o3x		[float!]
		o3y		[float!]
		o4x		[float!]
		o4y		[float!]
][
	i1x: cx + ((x1 - cx) * p1) i1y: cy + ((y1 - cy) * p1)
	i2x: cx + ((x2 - cx) * p1) i2y: cy + ((y1 - cy) * p1)
	i3x: cx + ((x2 - cx) * p1) i3y: cy + ((y2 - cy) * p1)
	i4x: cx + ((x1 - cx) * p1) i4y: cy + ((y2 - cy) * p1)

	o1x: cx + ((x1 - cx) * p2) o1y: cy + ((y1 - cy) * p2)
	o2x: cx + ((x2 - cx) * p2) o2y: cy + ((y1 - cy) * p2)
	o3x: cx + ((x2 - cx) * p2) o3y: cy + ((y2 - cy) * p2)
	o4x: cx + ((x1 - cx) * p2) o4y: cy + ((y2 - cy) * p2)

	mesh-add-patch pattern i1x i1y o1x o1y o2x o2y i2x i2y color1 color2
	mesh-add-patch pattern i2x i2y o2x o2y o3x o3y i3x i3y color1 color2
	mesh-add-patch pattern i3x i3y o3x o3y o4x o4y i4x i4y color1 color2
	mesh-add-patch pattern i4x i4y o4x o4y o1x o1y i1x i1y color1 color2
]

finish-pattern: func [
	grad		[gradient!]
	pattern		[handle!]
	/local
		matrix	[cairo_matrix_t!]
		m		[cairo_matrix_t! value]
		res		[cairo_matrix_t! value]
][
	cairo_matrix_init_identity m
	either grad/matrix-on? [
		matrix: as cairo_matrix_t! grad/matrix
		cairo_matrix_multiply res matrix m
		copy-memory as byte-ptr! matrix as byte-ptr! res size? cairo_matrix_t!
		cairo_pattern_set_matrix pattern matrix
	][
		cairo_pattern_set_matrix pattern m
	]
	cairo_pattern_set_extend pattern
		case [
			grad/spread = _pad       [CAIRO_EXTEND_PAD]
			grad/spread = _repeat    [CAIRO_EXTEND_REPEAT]
			grad/spread = _reflect   [CAIRO_EXTEND_REFLECT]
			true [CAIRO_EXTEND_REPEAT]
		]
	either grad/pattern-on? [
		cairo_pattern_destroy grad/pattern
	][
		grad/pattern-on?: on
	]
	grad/pattern: pattern
]

sync-active-pattern-matrix: func [
	grad	[gradient!]
][
	if grad/pattern-on? [
		cairo_pattern_set_matrix grad/pattern as cairo_matrix_t! grad/matrix
	]
]

create-diamond-pattern: func [
	grad		[gradient!]
	upper-x		[float!]
	upper-y		[float!]
	lower-x		[float!]
	lower-y		[float!]
	/local
		pattern	[handle!]
		color	[int-ptr!]
		pos		[float32-ptr!]
		p1		[float!]
		p2		[float!]
		c1		[integer!]
		c2		[integer!]
		i		[integer!]
		t		[float!]
		cx		[float!]
		cy		[float!]
		bound-x1 [float!]
		bound-y1 [float!]
		bound-x2 [float!]
		bound-y2 [float!]
		half-x	[float!]
		half-y	[float!]
		pmax	[float!]
		px		[float!]
		tile	[float!]
		tile-idx [integer!]
		reverse? [logic!]
][
	if upper-x > lower-x [t: lower-x lower-x: upper-x upper-x: t]
	if upper-y > lower-y [t: lower-y lower-y: upper-y upper-y: t]
	bound-x1: upper-x
	bound-y1: upper-y
	bound-x2: lower-x
	bound-y2: lower-y

	either grad/offset-on? [
		upper-x: grad/offset/x
		upper-y: grad/offset/y
		lower-x: grad/offset2/x
		lower-y: grad/offset2/y
		either grad/focal-on? [
			cx: grad/focal/x
			cy: grad/focal/y
		][
			cx: upper-x + lower-x
			cy: upper-y + lower-y
			cx: cx / 2.0
			cy: cy / 2.0
		]
	][
		cx: upper-x + lower-x
		cy: upper-y + lower-y
		cx: cx / 2.0
		cy: cy / 2.0
	]

	color: grad/colors
	pos: grad/colors-pos
	unless grad/zero-base? [
		color: color + 1
		pos: pos + 1
	]

	pattern: cairo_pattern_create_mesh
	c1: color/1
	p1: as float! pos/1
	color: color + 1
	pos: pos + 1
	i: grad/count - 1
	while [i > 0][
		c2: color/1
		p2: as float! pos/1
		mesh-add-rect-ring pattern upper-x upper-y lower-x lower-y cx cy p1 p2 c1 c2
		c1: c2
		p1: p2
		color: color + 1
		pos: pos + 1
		i: i - 1
	]
	half-x: abs-float (upper-x - cx)
	t: abs-float (lower-x - cx)
	if t > half-x [half-x: t]
	half-y: abs-float (upper-y - cy)
	t: abs-float (lower-y - cy)
	if t > half-y [half-y: t]
	pmax: 1.0
	if half-x > 0.0 [
		px: abs-float (bound-x1 - cx)
		t: abs-float (bound-x2 - cx)
		if t > px [px: t]
		px: px / half-x
		if px > pmax [pmax: px]
	]
	if half-y > 0.0 [
		px: abs-float (bound-y1 - cy)
		t: abs-float (bound-y2 - cy)
		if t > px [px: t]
		px: px / half-y
		if px > pmax [pmax: px]
	]
	case [
		grad/spread = _pad [
			if pmax > p1 [
				mesh-add-rect-ring pattern upper-x upper-y lower-x lower-y cx cy p1 pmax c1 c1
			]
		]
		any [
			grad/spread = _repeat
			grad/spread = _reflect
		][
			tile: 1.0
			tile-idx: 1
			while [tile < pmax][
				color: grad/colors
				pos: grad/colors-pos
				unless grad/zero-base? [
					color: color + 1
					pos: pos + 1
				]
				c1: color/1
				p1: as float! pos/1
				color: color + 1
				pos: pos + 1
				i: grad/count - 1
				reverse?: all [
					grad/spread = _reflect
					tile-idx and 1 <> 0
				]
				while [i > 0][
					c2: color/1
					p2: as float! pos/1
					either reverse? [
						mesh-add-rect-ring pattern upper-x upper-y lower-x lower-y cx cy tile + (1.0 - p2) tile + (1.0 - p1) c2 c1
					][
						mesh-add-rect-ring pattern upper-x upper-y lower-x lower-y cx cy tile + p1 tile + p2 c1 c2
					]
					c1: c2
					p1: p2
					color: color + 1
					pos: pos + 1
					i: i - 1
				]
				tile: tile + 1.0
				tile-idx: tile-idx + 1
			]
		]
		true [0]
	]
	finish-pattern grad pattern
]

update-pattern: func [
	grad		[gradient!]
	pattern		[handle!]
	cx			[float!]
	cy			[float!]
	/local
		matrix	[cairo_matrix_t!]
		m		[cairo_matrix_t! value]
		res		[cairo_matrix_t! value]
		color	[int-ptr!]
		pos		[float32-ptr!]
		r		[float!]
		g		[float!]
		b		[float!]
		a		[float!]
	p		[float!]
][
	color: grad/colors
	pos: grad/colors-pos
	unless grad/zero-base? [
		color: color + 1
		pos: pos + 1
	]
	loop grad/count [
		r: as-float color/1 and FFh
		r: r / 255.0
		g: as-float color/1 >> 8 and FFh
		g: g / 255.0
		b: as-float color/1 >> 16 and FFh
		b: b / 255.0
		a: as-float 255 - (color/1 >>> 24)
		a: a / 255.0
		p: as float! pos/1
		cairo_pattern_add_color_stop_rgba pattern p r g b a
		color: color + 1
		pos: pos + 1
	]
	finish-pattern grad pattern
]

get-shape-center: func [
	start			[red-pair!]
	end				[red-pair!]
	cx				[float32-ptr!]
	cy				[float32-ptr!]
	d				[float32-ptr!]
	/local
		point		[red-pair!]
		dx			[float32!]
		dy			[float32!]
		x0			[float32!]
		y0			[float32!]
		x1			[float32!]
		y1			[float32!]
		a			[float32!]
		r			[float32!]
		signedArea	[float32!]
		centroid-x	[float32!]
		centroid-y	[float32!]
		pt			[red-point2D!]
][
	;-- implementation taken from http://stackoverflow.com/questions/2792443/finding-the-centroid-of-a-polygon
	signedArea: as float32! 0.0
	centroid-x: as float32! 0.0 centroid-y: as float32! 0.0
	point: start
	while [point <= end][
		GET_PAIR_XY(point x0 y0)
		point: point + 1
		GET_PAIR_XY(point x1 y1)
		a: x0 * y1 - (x1 * y0)
		signedArea: signedArea + a
		centroid-x: centroid-x + ((x0 + x1) * a)
		centroid-y: centroid-y + ((y0 + y1) * a)
	]

	signedArea: signedArea * as float32! 0.5
	centroid-x: centroid-x / (signedArea * as float32! 6.0)
	centroid-y: centroid-y / (signedArea * as float32! 6.0)

	cx/value: centroid-x
	cy/value: centroid-y

	if d <> null [
		;-- take biggest distance
		d/value: as float32! 0.0
		point: start
		while [point <= end][
			GET_PAIR_XY(point x0 y0)
			dx: centroid-x - x0
			dy: centroid-y - y0
			r: sqrtf dx * dx + ( dy * dy )
			if r > d/value [ d/value: r ]
			point: point + 1
		]
	]
]

check-grad-points: func [
	grad		[gradient!]
	upper-x		[float!]
	upper-y		[float!]
	lower-x		[float!]
	lower-y		[float!]
	/local
		pattern	[handle!]
		t		[float!]
		x1		[float!]
		y1		[float!]
		r1		[float!]
		x2		[float!]
		y2		[float!]
		r2		[float!]
		delta	[float!]
		px		[float!]
		py		[float!]
][
	unless grad/on? [exit]
	pattern: null
	case [
		grad/type = linear [
			either grad/offset-on? [
				x1: grad/offset/x
				y1: grad/offset/y
				x2: grad/offset2/x
				y2: grad/offset2/y
			][
				x1: upper-x y1: upper-y
				x2: lower-x y2: lower-y
			]
			pattern: cairo_pattern_create_linear x1 y1 x2 y2
		]
		grad/type = radial [
			either grad/offset-on? [
				either grad/focal-on? [
					x1: grad/focal/x
					y1: grad/focal/y
					x2: grad/offset/x
					y2: grad/offset/y
					r1: 0.0 ;grad/offset2/x
					r2: grad/offset2/y
				][
					x1: grad/offset/x
					y1: grad/offset/y
					x2: x1
					y2: y1
					r1: 0.0 ;grad/offset2/x
					r2: grad/offset2/y
				]
			][
				if upper-x > lower-x [
					t: lower-x
					lower-x: upper-x
					upper-x: t
				]
				if upper-y > lower-y [
					t: lower-y
					lower-y: upper-y
					upper-y: t
				]
				delta: line-distance upper-x upper-y lower-x lower-y
				px: lower-x + upper-x
				py: lower-y + upper-y
				x1: px
				x1: x1 / 2.0
				y1: py
				y1: y1 / 2.0
				x2: x1 y2: y1
				r1: 0.0
				r2: delta
			]
			pattern: cairo_pattern_create_radial x1 y1 r1 x2 y2 r2
		]
		grad/type = diamond [
			create-diamond-pattern grad upper-x upper-y lower-x lower-y
			exit
		]
		true [exit]
	]
	unless null? pattern [
		update-pattern grad pattern x1 y1
	]
]

check-grad-line: func [
	grad		[gradient!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		pt		[red-point2D!]
		ux uy lx ly [float!]
][
	GET_PAIR_XY_F(upper ux uy)
	GET_PAIR_XY_F(lower lx ly)
	check-grad-points grad ux uy lx ly
]

check-grad-brush-lines: func [
	grad		[gradient!]
	point		[red-pair!]
	end			[red-pair!]
	/local
		pattern	[handle!]
		next	[red-pair!]
		x1		[float!]
		y1		[float!]
		r1		[float!]
		x2		[float!]
		y2		[float!]
		r2		[float!]
		cx		[float32!]
		cy		[float32!]
		d		[float32!]
		pt		[red-point2D!]
][
	unless grad/on? [exit]
	pattern: null
	case [
		grad/type = linear [
			either grad/offset-on? [
				x1: grad/offset/x
				y1: grad/offset/y
				x2: grad/offset2/x
				y2: grad/offset2/y
			][
				GET_PAIR_XY_F(point x1 y1)
				next: point + 1
				GET_PAIR_XY_F(next x2 y2)
			]
			pattern: cairo_pattern_create_linear x1 y1 x2 y2
		]
		grad/type = radial [
			either grad/offset-on? [
				either grad/focal-on? [
					x1: grad/focal/x
					y1: grad/focal/y
					x2: grad/offset/x
					y2: grad/offset/y
					r1: 0.0 ;grad/offset2/x
					r2: grad/offset2/y
				][
					x1: grad/offset/x
					y1: grad/offset/y
					x2: x1
					y2: y1
					r1: 0.0 ;grad/offset2/x
					r2: grad/offset2/y
				]
			][
				cx: as float32! 0.0
				cy: cx
				d: cx
				get-shape-center point end :cx :cy :d
				x1: as-float cx
				y1: as-float cy
				r1: 0.0
				x2: x1
				y2: y1
				r2: as-float d
			]
			pattern: cairo_pattern_create_radial x1 y1 r1 x2 y2 r2
		]
		grad/type = diamond [
			GET_PAIR_XY_F(point x1 y1)
			x2: x1
			y2: y1
			next: point + 1
			while [next <= end][
				GET_PAIR_XY_F(next r1 r2)
				if r1 < x1 [x1: r1]
				if r1 > x2 [x2: r1]
				if r2 < y1 [y1: r2]
				if r2 > y2 [y2: r2]
				next: next + 1
			]
			create-diamond-pattern grad x1 y1 x2 y2
			exit
		]
		true [exit]
	]
	unless null? pattern [
		update-pattern grad pattern x1 y1
	]
]

check-grad-arc-radial: func [
	grad		[gradient!]
	ax			[float!]
	ay			[float!]
	ar			[float!]
	/local
		pattern	[handle!]
		x1		[float!]
		y1		[float!]
		r1		[float!]
		x2		[float!]
		y2		[float!]
		r2		[float!]
][
	unless grad/on? [exit]
	unless grad/type = radial [exit]
	pattern: null

	either grad/offset-on? [
		either grad/focal-on? [
			x1: grad/focal/x
			y1: grad/focal/y
			x2: grad/offset/x
			y2: grad/offset/y
			r1: 0.0 ;grad/offset2/x
			r2: grad/offset2/y
		][
			x1: grad/offset/x
			y1: grad/offset/y
			x2: x1
			y2: y1
			r1: 0.0 ;grad/offset2/x
			r2: grad/offset2/y
		]
	][
		x1: ax - ar
		y1: ay - ar
		r1: 0.0
		x2: x1
		y2: y1
		r2: ar
	]
	pattern: cairo_pattern_create_radial x1 y1 r1 x2 y2 r2

	unless null? pattern [
		update-pattern grad pattern x1 y1
	]
]

check-grad-box-radial: func [
	grad		[gradient!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		pattern	[handle!]
		x1		[float!]
		y1		[float!]
		r1		[float!]
		x2		[float!]
		y2		[float!]
		r2		[float!]
		w		[float!]
		h		[float!]
		pt		[red-point2D!]
		ux uy lx ly [float!]
][
	unless grad/on? [exit]
	unless grad/type = radial [exit]
	pattern: null

	either grad/offset-on? [
		either grad/focal-on? [
			x1: grad/focal/x
			y1: grad/focal/y
			x2: grad/offset/x
			y2: grad/offset/y
			r1: 0.0 ;grad/offset2/x
			r2: grad/offset2/y
		][
			x1: grad/offset/x
			y1: grad/offset/y
			x2: x1
			y2: y1
			r1: 0.0 ;grad/offset2/x
			r2: grad/offset2/y
		]
	][
		GET_PAIR_XY_F(upper ux uy)
		GET_PAIR_XY_F(lower lx ly)
		x1: ux + lx
		y1: uy + ly
		x1: x1 / 2.0
		y1: y1 / 2.0
		r1: 0.0
		x2: x1
		y2: y1
		w: either ux < lx [
			lx - ux
		][
			ux - lx
		]
		h: either uy < ly [
			ly - uy
		][
			uy - ly
		]
		r2: either w > h [w][h]
		r2: r2 / 2.0
	]
	pattern: cairo_pattern_create_radial x1 y1 r1 x2 y2 r2

	unless null? pattern [
		update-pattern grad pattern x1 y1
	]
]

check-grad-box: func [
	grad		[gradient!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		pt		[red-point2D!]
		ux uy lx ly [float!]
][
	case [
		grad/type = linear [
			GET_PAIR_XY_F(upper ux uy)
			GET_PAIR_XY_F(lower lx ly)
			;-- the windows backend use horizontal linear gradient default,
			;-- maybe should use diagonal line
			check-grad-points grad ux uy lx ly
		]
		grad/type = radial [
			check-grad-box-radial grad upper lower
		]
		grad/type = diamond [
			GET_PAIR_XY_F(upper ux uy)
			GET_PAIR_XY_F(lower lx ly)
			create-diamond-pattern grad ux uy lx ly
		]
		true [0]
	]
]

check-grad-circle: func [
	grad		[gradient!]
	cx			[float!]
	cy			[float!]
	rx			[float!]
	ry			[float!]
	/local
		r		[float!]
][
	case [
		grad/type = linear [
			check-grad-points grad cx - rx cy - ry cx + rx cy + ry
		]
		grad/type = radial [
			r: rx
			if rx > ry [r: ry]
			check-grad-arc-radial grad cx cy r
		]
		grad/type = diamond [
			check-grad-points grad cx - rx cy - ry cx + rx cy + ry
		]
		true [0]
	]
]

OS-draw-anti-alias: func [
	dc			[draw-ctx!]
	on?			[logic!]
][
	cairo_set_antialias dc/cr either on? [CAIRO_ANTIALIAS_GOOD][CAIRO_ANTIALIAS_NONE]
]

OS-draw-line: func [
	dc			[draw-ctx!]
	point		[red-pair!]
	end			[red-pair!]
	/local
		iter	[red-pair!]
		cr		[handle!]
		saved	[cairo_matrix_t! value]
		pt		[red-point2D!]
		x y		[float!]
][
	cr: dc/cr
	ctx-matrix-adapt dc saved
	cairo_new_sub_path cr
	iter: point
	while [iter <= end][
		GET_PAIR_XY_F(iter x y)
		cairo_line_to cr x y
		iter: iter + 1
	]
	check-grad-line dc/grad-pen point end
	do-draw-pen dc
	ctx-matrix-unadapt dc saved
]

OS-draw-pen: func [
	dc			[draw-ctx!]
	color		[integer!]									;-- 00bbggrr format
	off?		[logic!]
	alpha?		[logic!]
][
	dc/pen?: not off?
	if dc/grad-pen/on? [
		if dc/grad-pen/pattern-on? [
			cairo_pattern_destroy dc/grad-pen/pattern
		]
		dc/grad-pen/pattern-on?: off
		dc/grad-pen/on?: off
	]
	unless off? [
		dc/pen-color: color
		unless dc/font-color? [dc/font-color: color]
	]
]

OS-draw-fill-pen: func [
	dc			[draw-ctx!]
	color		[integer!]									;-- 00bbggrr format
	off?		[logic!]
	alpha?		[logic!]
][
	dc/brush?: not off?
	if dc/grad-brush/on? [
		if dc/grad-brush/pattern-on? [
			cairo_pattern_destroy dc/grad-brush/pattern
		]
		dc/grad-brush/pattern-on?: off
		dc/grad-brush/on?: off
	]
	unless off? [
		dc/brush-color: color
	]
]

_set-line-dash: func [
	dc		[draw-ctx!]
	/local
		cnt		[integer!]
		pint	[int-ptr!]
		pf		[float-ptr!]
		dashes	[float-ptr!]
][
	if dc/pen-pattern <> null [
		pint: as int-ptr! dc/pen-pattern
		cnt: pint/value
		dashes: dc/pen-pattern + 1
		pf: as float-ptr! system/stack/allocate cnt * 2
		while [cnt > 0][
			pf/cnt: dashes/cnt * dc/pen-width
			cnt: cnt - 1
		]
		cairo_set_dash dc/cr pf pint/value 0.0
	]
]

OS-draw-line-width: func [
	dc			[draw-ctx!]
	width		[red-value!]
	/local
		w		[float!]
][
	w: get-float as red-integer! width
	dc/line-width?: w > 0.0
	if w <= 0.0 [w: 1.0]
	dc/pen-width: w
	cairo_set_line_width dc/cr w

	_set-line-dash dc
]

OS-draw-box: func [
	dc			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		cr		[handle!]
		radius	[red-integer!]
		t 		[float!]
		rad		[float!]
		x		[float!]
		y		[float!]
		w		[float!]
		h		[float!]
		tf		[float!]
		degrees [float!]
		saved	[cairo_matrix_t! value]
		pt		[red-point2D!]
		ux uy lx ly [float!]
][
	cr: dc/cr
	radius: null
	if upper + 2 = lower [	;-- lower is pointing to the optional radius parameter
		radius: as red-integer! lower
		lower:  lower - 1
	]

	GET_PAIR_XY_F(upper ux uy)
	GET_PAIR_XY_F(lower lx ly)
	if ux > lx [t: ux ux: lx lx: t]
	if uy > ly [t: uy uy: ly ly: t]

	x: ux
	y: uy
	w: lx - ux
	h: ly - uy

	ctx-matrix-adapt dc saved
	either radius <> null [
		tf: either w > h [h][w]
		tf: tf / 2.0
		rad: get-float radius
		if rad > tf [rad: tf]

		degrees: pi / 180.0
		cairo_new_sub_path cr
		cairo_arc cr x + w - rad  y + rad rad -90.0 * degrees 0.0 * degrees
		cairo_arc cr x + w - rad y + h - rad rad 0.0 * degrees 90.0 * degrees
		cairo_arc cr x + rad y + h - rad rad 90.0 * degrees 180.0 * degrees
		cairo_arc cr x + rad y + rad rad 180.0 * degrees 270.0 * degrees
		cairo_close_path cr
	][
		cairo_rectangle cr x y w h
	]
	check-grad-box dc/grad-pen upper lower
	check-grad-box dc/grad-brush upper lower
	do-draw-path dc
	ctx-matrix-unadapt dc saved
]

OS-draw-triangle: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	/local
		saved	[cairo_matrix_t! value]
		pt		[red-point2D!]
		sx sy	[float!]
][
	ctx-matrix-adapt dc saved
	cairo_new_sub_path dc/cr
	loop 3 [
		GET_PAIR_XY_F(start sx sy)
		cairo_line_to dc/cr sx sy
		start: start + 1
	]
	cairo_close_path dc/cr								;-- close the triangle
	check-grad-line dc/grad-pen start start + 1
	check-grad-brush-lines dc/grad-brush start start + 2
	do-draw-path dc
	ctx-matrix-unadapt dc saved
]

OS-draw-polygon: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	/local
		saved	[cairo_matrix_t! value]
		pt		[red-point2D!]
		sx sy	[float!]
][
	ctx-matrix-adapt dc saved
	cairo_new_sub_path dc/cr
	until [
		GET_PAIR_XY_F(start sx sy)
		cairo_line_to dc/cr sx sy
		start: start + 1
		start > end
	]
	cairo_close_path dc/cr
	check-grad-line dc/grad-pen start start + 1
	check-grad-brush-lines dc/grad-brush start end
	do-draw-path dc
	ctx-matrix-unadapt dc saved
]

do-spline-step: func [
	ctx			[handle!]
	p0			[red-pair!]
	p1			[red-pair!]
	p2			[red-pair!]
	p3			[red-pair!]
	/local
		t		[float!]
		t2		[float!]
		t3		[float!]
		x		[float!]
		y		[float!]
		p0x p0y [float!]
		p1x p1y [float!]
		p2x p2y [float!]
		p3x p3y [float!]
		delta	[float!]
		pt		[red-point2D!]
][
	delta: 0.04
	t: 0.0
	GET_PAIR_XY_F(p0 p0x p0y)
	GET_PAIR_XY_F(p1 p1x p1y)
	GET_PAIR_XY_F(p2 p2x p2y)
	GET_PAIR_XY_F(p3 p3x p3y)
	loop 25 [
		t: t + delta
		t2: t * t
		t3: t2 * t

		x:
		   (p1x * 2.0) + (p2x - p0x * t) +
		   ((p0x * 2.0) - (p1x * 5.0) + (p2x * 4.0) - p3x * t2) +
		   ((p1x - p2x * 3.0) + p3x - p0x * t3) * 0.5
		y:
		   (p1y * 2.0) + (p2y - p0y * t) + 
		   ((p0y * 2.0) - (p1y * 5.0) + (p2y * 4.0) - p3y * t2) + 
		   ((p1y - p2y * 3.0) + p3y - p0y * t3) * 0.5 

		cairo_line_to ctx x y
	]
]

OS-draw-spline: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	closed?		[logic!]
	/local
		cr		[handle!]
		point	[red-pair!]
		stop	[red-pair!]
		saved	[cairo_matrix_t! value]
][
	if (as-integer end - start) >> 4 = 1 [		;-- two points input
		OS-draw-line dc start end				;-- draw a line
		exit
	]

	cr: dc/cr
	ctx-matrix-adapt dc saved
	either closed? [
		do-spline-step cr
			end
			start
			start + 1
			start + 2
	][
		do-spline-step cr
			start
			start
			start + 1
			start + 2
	]

	point: start
	stop: end - 3

	while [point <= stop] [
		do-spline-step cr
			point
			point + 1
			point + 2
			point + 3
		point: point + 1
	]

	either closed? [
		do-spline-step cr
			end - 2
			end - 1
			end
			start
		do-spline-step cr
			end - 1
			end
			start
			start + 1
		cairo_close_path cr
	][
		do-spline-step cr
			end - 2
			end - 1
			end
			end
	]

	check-grad-line dc/grad-pen start start + 1
	check-grad-brush-lines dc/grad-brush start end
	do-draw-path dc
	ctx-matrix-unadapt dc saved
]

OS-draw-circle: func [
	dc			[draw-ctx!]
	center		[red-pair!]
	radius		[red-integer!]
	/local
		cr		[handle!]
		rad-x	[float!]
		rad-y	[float!]
		cx cy	[float!]
		f		[red-float!]
		saved	[cairo_matrix_t! value]
		pt		[red-point2D!]
][
	cr: dc/cr
	rad-x: get-float radius
	rad-y: rad-x
	if center + 2 = radius [	;-- center, radius-x, radius-y
		radius: radius - 1
		rad-x: get-float radius
	]

	if any [
		rad-x = 0.0
		rad-y = 0.0
	][exit]

	ctx-matrix-adapt dc saved
	cairo_new_sub_path cr
	cairo_save cr
	GET_PAIR_XY_F(center cx cy)
	cairo_translate cr cx cy
	cairo_scale cr rad-x rad-y
	cairo_arc cr 0.0 0.0 1.0 0.0 2.0 * pi
	cairo_restore cr
	check-grad-circle dc/grad-pen cx cy rad-x rad-y
	check-grad-circle dc/grad-brush cx cy rad-x rad-y
	do-draw-path dc
	ctx-matrix-unadapt dc saved
]

OS-draw-ellipse: func [
	dc			[draw-ctx!]
	upper		[red-pair!]
	diameter	[red-pair!]
	/local
		cr		[handle!]
		rad-x	[float!]
		rad-y	[float!]
		cx		[float!]
		cy		[float!]
		saved	[cairo_matrix_t! value]
		pt		[red-point2D!]
][
	cr: dc/cr
	GET_PAIR_XY_F(diameter rad-x rad-y)
	rad-x: rad-x / 2.0
	rad-y: rad-y / 2.0
	GET_PAIR_XY_F(upper cx cy)
	cx: cx + rad-x
	cy: cy + rad-y
	if any [
		rad-x = 0.0
		rad-y = 0.0
	][exit]

	ctx-matrix-adapt dc saved
	cairo_new_sub_path cr
	cairo_save cr
	cairo_translate cr cx cy
	cairo_scale cr rad-x rad-y
	cairo_arc cr 0.0 0.0 1.0 0.0 2.0 * pi
	cairo_restore cr
	check-grad-circle dc/grad-pen cx cy rad-x rad-y
	check-grad-circle dc/grad-brush cx cy rad-x rad-y
	do-draw-path dc
	ctx-matrix-unadapt dc saved
]


set-font-attrs: func [
	dc			[draw-ctx!]
	font		[red-object!]
	/local
		cr		[handle!]
		slant	[integer!]
		weight	[integer!]
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
	cr: dc/cr
	values: object/get-values font

	str: as red-string! values + FONT_OBJ_NAME
	either TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
	][
		name: "Serif"
	]

	slant: 0
	weight: 0
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
					weight: 1
				]
				sym = _italic [
					slant: 1
				]
				sym = _underline [0]
				sym = _strike	 [0]
				true			 [0]
			]
			style: style + 1
		]
	]
	cairo_select_font_face cr name slant weight

	int: as red-integer! values + FONT_OBJ_SIZE
	if TYPE_OF(int) = TYPE_INTEGER [
		size: int/value
		cairo_set_font_size cr as float! size
	]

	color: as red-tuple! values + FONT_OBJ_COLOR
	either TYPE_OF(color) = TYPE_TUPLE [
		alpha?: 0
		rgb: get-color-int color :alpha?
		dc/font-color: rgb
		dc/font-color?: yes
		set-source-color cr rgb
	][
		dc/font-color: dc/pen-color
		dc/font-color?: no
	]

	if dc/font-attrs <> null [pango_attr_list_unref dc/font-attrs]
	dc/font-attrs: create-pango-attrs null font
]

OS-draw-font: func [
	dc			[draw-ctx!]
	font		[red-object!]
	/local
		values	[red-value!]
		value	[red-value!]
		quality	[integer!]
		bool	[red-logic!]
		word	[red-word!]
		fe		[cairo_font_extents_t! value]
][
	if null? dc/font-opts [
		dc/font-opts: cairo_font_options_create
	]
	set-font-attrs dc font

	values: object/get-values font
	value: values + FONT_OBJ_ANTI-ALIAS?
	quality: switch TYPE_OF(value) [
		TYPE_LOGIC [
			bool: as red-logic! value
			either bool/value [
				CAIRO_ANTIALIAS_SUBPIXEL
			][
				CAIRO_ANTIALIAS_NONE
			]
		]
		TYPE_WORD [
			word: as red-word! value
			either ClearType = symbol/resolve word/symbol [
				CAIRO_ANTIALIAS_BEST
			][
				CAIRO_ANTIALIAS_NONE
			]
		]
		default [CAIRO_ANTIALIAS_DEFAULT]
	]
	dc/font-antialias: quality
	cairo_font_extents dc/cr fe							;-- get new font metrics
	dc/font-ascent: fe/ascent
	cairo_font_options_set_antialias dc/font-opts quality
]

draw-text-at: func [
	dc			[draw-ctx!]
	text		[red-string!]
	x			[float!]
	y			[float!]
	/local
		cr		[handle!]
		len		[integer!]
		str		[c-string!]
		layout	[handle!]
		attrs	[handle!]
		lc		[layout-ctx!]
][
	cr: dc/cr
	cairo_save cr
	cairo_move_to cr x y
	len: (string/rs-length? text) * 4 + 1
	if dc/utf8-buffer-size < len [
		dc/utf8-buffer: either null? dc/utf8-buffer [
			allocate len
		][
			realloc dc/utf8-buffer len
		]
		dc/utf8-buffer-size: len
	]
	unicode/to-utf8-buffer text dc/utf8-buffer -1 yes
	str: as c-string! dc/utf8-buffer
	if null? pango-context [pango-context: gdk_pango_context_get]
	layout: pango_layout_new pango-context
	pango_layout_set_text layout str -1
	either dc/font-attrs <> null [
		pango_layout_set_attributes layout dc/font-attrs
	][
		attrs: create-pango-attrs-no-color null
		lc: declare layout-ctx!
		lc/layout: layout
		lc/text: str
		lc/attrs: attrs
		OS-text-box-color null as handle! lc 0 string/rs-length? text dc/pen-color
		pango_layout_set_attributes layout attrs
		pango_attr_list_unref attrs
	]
	pango_cairo_show_layout cr layout
	g_object_unref layout
	cairo_restore cr
]

draw-text-box: func [
	cr			[handle!]
	pos			[red-pair!]
	tbox		[red-object!]
	clr			[integer!]
	force?		[logic!]
	catch?		[logic!]
	/local
		values	[red-value!]
		text	[red-string!]
		state	[red-block!]
		layout?	[logic!]
		bool	[red-logic!]
		int		[red-integer!]
		layout	[handle!]
		size	[red-pair!]
		color	[red-tuple!]
		para	[red-object!]
		pvalues	[red-value!]
		pt		[red-point2D!]
		x y		[float!]
		w h		[float!]
		text-x	[float!]
		text-y	[float!]
		tw		[integer!]
		th		[integer!]
		hsym	[integer!]
		vsym	[integer!]
][
	values: object/get-values tbox
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [exit]

	state: as red-block! values + FACE_OBJ_EXT3
	layout?: yes
	if TYPE_OF(state) = TYPE_BLOCK [
		bool: as red-logic! (block/rs-tail state) - 1
		layout?: bool/value
	]
	if any [force? layout?] [
		OS-text-box-layout tbox null clr catch?
	]

	int: as red-integer! block/rs-head state
	layout: as handle! int/value
	GET_PAIR_XY_F(pos x y)
	text-x: x
	text-y: y
	size: as red-pair! values + FACE_OBJ_SIZE
	color: as red-tuple! values + FACE_OBJ_COLOR
	if all [
		TYPE_OF(color) = TYPE_TUPLE
		ANY_COORD?(size)
	][
		GET_PAIR_XY_F(size w h)
		set-source-color cr get-tuple-color color
		cairo_rectangle cr x y w h
		cairo_fill cr
	]
	para: as red-object! values + FACE_OBJ_PARA
	if all [
		TYPE_OF(para) = TYPE_OBJECT
		ANY_COORD?(size)
	][
		pvalues: object/get-values para
		hsym: get-para-hsym pvalues
		vsym: get-para-vsym pvalues
		if any [
			hsym = _para/center
			hsym = _para/middle
			hsym = _para/right
			vsym = _para/middle
			vsym = _para/bottom
		][
			GET_PAIR_XY_F(size w h)
			tw: 0 th: 0
			pango_layout_get_pixel_size layout :tw :th
			case [
				all [
					any [hsym = _para/center hsym = _para/middle]
					w > as float! tw
				][
					text-x: x + ((w - as float! tw) / 2.0)
				]
				all [hsym = _para/right w > as float! tw][
					text-x: x + w - as float! tw
				]
				true [0]
			]
			case [
				all [vsym = _para/middle h > as float! th][
					text-y: y + ((h - as float! th) / 2.0)
				]
				all [vsym = _para/bottom h > as float! th][
					text-y: y + h - as float! th
				]
				true [0]
			]
		]
	]
	cairo_move_to cr text-x text-y
	if force? [set-source-color cr clr]
	pango_cairo_show_layout cr layout
]

OS-draw-text: func [
	dc			[draw-ctx!]
	pos			[red-pair!]
	text		[red-string!]
	catch?		[logic!]
	return:		[logic!]
	/local
		saved	[cairo_matrix_t! value]
		pt		[red-point2D!]
		clr		[integer!]
		x y		[float!]
][
	ctx-matrix-adapt dc saved
	clr: either dc/font-color? [dc/font-color][dc/pen-color]
	either TYPE_OF(text) = TYPE_STRING [
		GET_PAIR_XY_F(pos x y)
		set-source-color dc/cr clr
		draw-text-at dc text x y
	][
		draw-text-box dc/cr pos as red-object! text clr yes catch?
	]
	ctx-matrix-unadapt dc saved
	true
]

OS-draw-arc: func [
	dc				[draw-ctx!]
	center			[red-pair!]
	end				[red-value!]
	/local
		cr			[handle!]
		radius		[red-pair!]
		angle		[red-integer!]
		begin		[red-integer!]
		cx			[float!]
		cy			[float!]
		rad-x		[float!]
		rad-y		[float!]
		angle-begin [float!]
		angle-end	[float!]
		rad			[float!]
		sweep		[integer!]
		i			[integer!]
		closed?		[logic!]
		saved		[cairo_matrix_t! value]
		pt			[red-point2D!]
][
	cr: dc/cr
	GET_PAIR_XY_F(center cx cy)
	rad: PI / 180.0

	radius: center + 1
	GET_PAIR_XY_F(radius rad-x rad-y)
	begin: as red-integer! radius + 1
	angle-begin: rad * as float! begin/value
	angle: begin + 1
	sweep: angle/value
	i: begin/value + sweep
	angle-end: rad * as float! i

	;-- adjust angles for ellipses
	if rad-x <> rad-y [
		angle-begin: atan2 (sin angle-begin) * rad-x (cos angle-begin) * rad-y
		angle-end:   atan2 (sin angle-end)  * rad-x (cos angle-end) * rad-y

		rad: angle-end - angle-begin
		if rad < 0.0 [rad: 0.0 - rad]
		if PI < rad [
			either angle-end > angle-begin [
				angle-end: angle-end - (PI * 2.0)
			][
				angle-begin: angle-begin - (PI * 2.0)
			]
		]
	]

	closed?: angle < end

	ctx-matrix-adapt dc saved
	cairo_save cr
	either closed? [
		cairo_move_to cr cx cy
	][
		cairo_new_sub_path cr
	]
	cairo_translate cr cx    cy
	cairo_scale     cr rad-x rad-y
	either sweep < 0 [
		cairo_arc_negative cr 0.0 0.0 1.0 angle-begin angle-end
	][
		cairo_arc cr 0.0 0.0 1.0 angle-begin angle-end
	]
	if closed? [
		cairo_close_path cr
	]
	check-grad-circle dc/grad-pen cx cy rad-x rad-y
	check-grad-circle dc/grad-brush cx cy rad-x rad-y
	cairo_restore cr
	either closed? [
		do-draw-path dc
	][
		do-draw-pen dc
	]
	ctx-matrix-unadapt dc saved
]

OS-draw-curve: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	/local
		cr		[handle!]
		p2		[red-pair!]
		p3		[red-pair!]
		saved	[cairo_matrix_t! value]
		pt		[red-point2D!]
		sx sy p2x p2y p3x p3y [float!]
		cp1x	[float!]
		cp1y	[float!]
		cp2x	[float!]
		cp2y	[float!]
][
	cr: dc/cr
	p2: start + 1
	p3: start + 2
	GET_PAIR_XY_F(start sx sy)
	GET_PAIR_XY_F(p2 p2x p2y)
	GET_PAIR_XY_F(p3 p3x p3y)

	ctx-matrix-adapt dc saved
	either (as-integer end - start) >> 4 = 2 [	;-- three points
		;-- p0, p1, p2  -->  p0, (p0 + 2p1) / 3, (2p1 + p2) / 3, p2
		cp1x: (p2x * 2.0) + sx / 3.0
		cp1y: (p2y * 2.0) + sy / 3.0
		cp2x: (p2x * 2.0) + p3x / 3.0
		cp2y: (p2y * 2.0) + p3y / 3.0

	][	; four input points
		cp1x: p2x
		cp1y: p2y
		cp2x: p3x
		cp2y: p3y
	]
	
	cairo_move_to cr sx sy
	GET_PAIR_XY_F(end sx sy)
	cairo_curve_to cr cp1x cp1y cp2x cp2y sx sy
	check-grad-line dc/grad-pen start end
	do-draw-pen dc
	ctx-matrix-unadapt dc saved
]

OS-draw-line-join: func [
	dc			[draw-ctx!]
	style		[integer!]
][
	cairo_set_line_join dc/cr
		case [
			style = miter		[0]
			style = _round		[1]
			style = bevel		[2]
			style = miter-bevel	[0]
			true				[0]
		]
]

OS-draw-line-cap: func [
	dc			[draw-ctx!]
	style		[integer!]
][
	cairo_set_line_cap dc/cr
		case [
			style = flat		[0]
			style = _round		[1]
			style = square		[2]
			true				[0]
		]
]

OS-draw-line-pattern: func [
	dc			[draw-ctx!]
	start		[red-integer!]
	end			[red-integer!]
	/local
		p		[red-integer!]
		cnt		[integer!]
		dashes	[float-ptr!]
		pf		[float-ptr!]
		pint	[int-ptr!]
][
	if dc/pen-pattern <> null [
		free as byte-ptr! dc/pen-pattern
		dc/pen-pattern: null
	]
	cnt: (as-integer end - start) / 16 + 1
	dashes: null
	if cnt > 0 [
		dashes: as float-ptr! allocate (cnt + 1) * size? float!
		dc/pen-pattern: dashes
		;-- save count in the first slot
		pint: as int-ptr! dashes
		pint/1: cnt
		dashes: dashes + 1
		pf: dashes
		while [start <= end][
			either zero? start/value [pf/1: 0.0001][pf/1: as float! start/value]
			pf: pf + 1
			start: start + 1
		]
	]
	_set-line-dash dc
]

GDK-draw-image: func [
	dc			[draw-ctx!]
	cr			[handle!]
	image		[handle!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		img		[handle!]
		absw	[integer!]
		absh	[integer!]
		saved	[cairo_matrix_t! value]
][
	if any [
		width = 0
		height = 0
	][exit]

	absw: width
	if width < 0 [absw: 0 - width]
	absh: height
	if height < 0 [absh: 0 - height]
	img: gdk_pixbuf_scale_simple image absw absh 2

	cairo_save cr
	cairo_translate cr as-float x as-float y
	if width < 0 [
		cairo_scale cr -1.0 1.0
	]
	if height < 0 [
		cairo_scale cr 1.0 -1.0
	]
	unless null? dc [
		ctx-matrix-adapt dc saved
	]
	gdk_cairo_set_source_pixbuf cr img 0.0 0.0
	cairo_paint cr
	unless null? dc [
		ctx-matrix-unadapt dc saved
	]
	cairo_restore cr
	g_object_unref img
]

OS-draw-image: func [
	dc			[draw-ctx!]
	src			[red-image!]
	start		[red-pair!]
	end			[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	crop1		[red-pair!]
	pattern		[red-word!]
	return:		[integer!]
	/local
		src.w	[integer!]
		src.h	[integer!]
		x		[integer!]
		y		[integer!]
		w		[integer!]
		h		[integer!]
		crop2	[red-pair!]
		crop.x	[integer!]
		crop.y	[integer!]
		crop.w	[integer!]
		crop.h	[integer!]
		right	[integer!]
		bottom	[integer!]
		dst		[red-image! value]
		pixbuf	[handle!]
		pt		[red-point2D!]
][
	either any [
		start + 2 = end
		start + 3 = end
	][
		x: 0 y: 0 w: 0 h: 0
		image/any-resize src dst crop1 start end :x :y :w :h
		if dst/header = TYPE_NONE [return 0]
		pixbuf: OS-image/to-pixbuf dst
		GDK-draw-image dc dc/cr pixbuf x y w h
		OS-image/delete dst/node
	][
		src.w: IMAGE_WIDTH(src/size)
		src.h: IMAGE_HEIGHT(src/size)
		either null? start [x: 0 y: 0][GET_PAIR_XY_INT(start x y)]
		unless null? crop1 [
			crop2: crop1 + 1
			crop.x: crop1/x
			crop.y: crop1/y
			crop.w: crop2/x
			crop.h: crop2/y

			right: crop.x + crop.w
			bottom: crop.y + crop.h
			if any [		;-- clip outside the image
				right <= 0 bottom <= 0
				crop.x >= src.w crop.y >= src.h
			][return 0]

			if right > src.w [right: src.w]
			if bottom > src.h [bottom: src.h]
			if crop.x < 0 [crop.x: 0]
			if crop.y < 0 [crop.y: 0]

			crop.w: right - crop.x
			crop.h: bottom - crop.y
		]
		case [
			start = end [
				either null? crop1 [
					w: src.w h: src.h
				][
					w: crop.w h: crop.h
				]
			]
			start + 1 = end [
				GET_PAIR_XY_INT(end w h)
				w: w - x
				h: h - y
			]
			true [return 0]
		]
		pixbuf: OS-image/to-pixbuf src
		unless null? crop1 [
			pixbuf: gdk_pixbuf_new_subpixbuf pixbuf crop.x crop.y crop.w crop.h
		]
		GDK-draw-image dc dc/cr pixbuf x y w h
		unless null? crop1 [
			g_object_unref pixbuf
		]
	]
	0
]

OS-draw-grad-pen-old: func [
	dc			[draw-ctx!]
	type		[integer!]
	mode		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
	/local
		w		[float!]
		h		[float!]
		int		[red-integer!]
		grad	[gradient!]
		nums	[integer!]
		pc		[int-ptr!]
		x		[float!]
		y		[float!]
		n		[integer!]
		f		[red-float!]
		rotate?	[logic!]
		scale?	[logic!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		delta	[float!]
		p		[float!]
		angle	[float!]
		matrix	[cairo_matrix_t!]
		color	[int-ptr!]
		last-c	[int-ptr!]
		pos		[float32-ptr!]
		last-p	[float32-ptr!]
		pt		[red-point2D!]
		off-x off-y [float!]
][
	int: as red-integer! offset + 1
	w: as float! int/value
	int: int + 1
	h: as float! int/value

	grad: either brush? [
		dc/brush?: yes
		dc/grad-brush
	][
		dc/pen?: yes
		dc/grad-pen
	]
	unless grad/on? [
		nums: 2 * MAX_COLORS
		pc: as int-ptr! allocate nums * size? integer!
		grad/colors: pc
		grad/colors-pos: as float32-ptr! pc + MAX_COLORS
		grad/on?: on
	]
	grad/spread: _pad
	grad/type: type
	grad/count: 0

	grad/focal-on?: off
	GET_PAIR_XY_F(offset off-x off-y)
	case [
		type = linear [
			grad/offset-on?: on
			grad/offset/x: off-x + w
			grad/offset/y: off-y + w
			grad/offset2/x: off-x + h
			grad/offset2/y: off-y + w
		]
		type = radial [
			grad/offset-on?: on
			grad/offset/x: off-x
			grad/offset/y: off-y
			grad/offset2/x: w					;-- smaller radius
			grad/offset2/y: h					;-- bigger radius
			grad/focal-on?: on
			grad/focal/x: off-x + w
			grad/focal/y: off-y + w
		]
		true [
			grad/offset-on?: off
		]
	]

	n: 0
	rotate?: no
	scale?: no
	y: 1.0
	while [
		int: int + 1
		n < 3
	][								;-- fetch angle, scale-x and scale-y (optional)
		switch TYPE_OF(int) [
			TYPE_INTEGER	[p: as-float int/value]
			TYPE_FLOAT		[f: as red-float! int p: f/value]
			default			[break]
		]
		switch n [
			0	[angle: p rotate?: yes]
			1	[x:	p scale?: yes]
			2	[y:	p]
		]
		n: n + 1
	]
	matrix: as cairo_matrix_t! grad/matrix
	cairo_matrix_init_identity matrix
	if any [rotate? scale?][
		grad/matrix-on?: on
		if rotate? [
			p: PI / 180.0
			p: p * angle
			cairo_matrix_rotate matrix 0.0 - p
		]
		if scale? [
			x: 1.0 / x
			y: 1.0 / y
			cairo_matrix_scale matrix x y
		]
	]

	color: grad/colors + 1
	pos: grad/colors-pos + 1
	delta: as-float count - 1
	delta: 1.0 / delta
	p: 0.0
	head: as red-value! int
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		color/value: get-tuple-color clr
		next: head + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		pos/value: as float32! p
		if next <> head [p: p + delta]
		head: head + 1
		color: color + 1
		pos: pos + 1
	]

	grad/zero-base?: no
	last-p: pos - 1
	last-c: color - 1
	pos: pos - count
	color: color - count
	if pos/value > as float32! 0.0 [			;-- first one should be always 0.0
		grad/colors-pos/value: as float32! 0.0
		grad/colors/value: color/value
		count: count + 1
		grad/zero-base?: yes
	]
	if last-p/value < as float32! 1.0 [			;-- last one should be always 1.0
		last-c/2: last-c/value
		last-p/2: as float32! 1.0
		count: count + 1
	]
	grad/count: count
]

OS-draw-grad-pen: func [
	dc			[draw-ctx!]
	type		[integer!]
	stops		[red-value!]
	count		[integer!]
	skip-pos?	[logic!]
	positions	[red-value!]
	focal?		[logic!]
	spread		[integer!]
	brush?		[logic!]
	/local
		grad	[gradient!]
		nums	[integer!]
		pc		[int-ptr!]
		point	[red-pair!]
		p		[float!]
		delta	[float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		f		[red-float!]
		matrix	[cairo_matrix_t!]
		color	[int-ptr!]
		last-c	[int-ptr!]
		pos		[float32-ptr!]
		last-p	[float32-ptr!]
		pt		[red-point2D!]
][

	grad: either brush? [
		dc/brush?: yes
		dc/grad-brush
	][
		dc/pen?: yes
		dc/grad-pen
	]
	unless grad/on? [
		nums: 2 * MAX_COLORS
		pc: as int-ptr! allocate nums * size? integer!
		grad/colors: pc
		grad/colors-pos: as float32-ptr! pc + MAX_COLORS
		grad/on?: on
	]
	grad/spread: spread
	grad/type: type
	grad/count: 0

	grad/focal-on?: off
	case [
		type = linear [
			either skip-pos? [
				grad/offset-on?: off
			][
				grad/offset-on?: on
				point: as red-pair! positions
				GET_PAIR_XY_F(point grad/offset/x grad/offset/y)
				point: point + 1
				GET_PAIR_XY_F(point grad/offset2/x grad/offset2/y)
			]
		]
		type = radial [
			either skip-pos? [
				grad/offset-on?: off
			][
				grad/offset-on?: on
				point: as red-pair! positions
				GET_PAIR_XY_F(point grad/offset/x grad/offset/y)
				p: get-float as red-integer! point + 1
				grad/offset2/x: 0.0
				grad/offset2/y: p
				if focal? [
					grad/focal-on?: on
					point: point + 2
					GET_PAIR_XY_F(point grad/focal/x grad/focal/y)
				]
			]
		]
		type = diamond [
			either skip-pos? [
				grad/offset-on?: off
			][
				grad/offset-on?: on
				point: as red-pair! positions
				GET_PAIR_XY_F(point grad/offset/x grad/offset/y)
				point: point + 1
				GET_PAIR_XY_F(point grad/offset2/x grad/offset2/y)
				if focal? [
					grad/focal-on?: on
					point: point + 1
					GET_PAIR_XY_F(point grad/focal/x grad/focal/y)
				]
			]
		]
		true [
			grad/offset-on?: off
		]
	]

	matrix: as cairo_matrix_t! grad/matrix
	cairo_matrix_init_identity matrix

	color: grad/colors + 1
	pos: grad/colors-pos + 1
	delta: as-float count - 1
	delta: 1.0 / delta
	p: 0.0
	head: stops
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		color/value: get-tuple-color clr
		next: head + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		pos/value: as float32! p
		if next <> head [p: p + delta]
		head: head + 1
		color: color + 1
		pos: pos + 1
	]

	grad/zero-base?: no
	last-p: pos - 1
	last-c: color - 1
	pos: pos - count
	color: color - count
	if pos/value > as float32! 0.0 [			;-- first one should be always 0.0
		grad/colors-pos/value: as float32! 0.0
		grad/colors/value: color/value
		count: count + 1
		grad/zero-base?: yes
	]
	if last-p/value < as float32! 1.0 [			;-- last one should be always 1.0
		last-c/2: last-c/value
		last-p/2: as float32! 1.0
		count: count + 1
	]
	grad/count: count
]

OS-matrix-rotate: func [
	dc			[draw-ctx!]
	pen-fill	[integer!]
	angle		[red-integer!]
	center		[red-pair!]
	/local
		cr		[handle!]
		rad		[float!]
		grad	[gradient!]
		matrix	[cairo_matrix_t!]
		cx		[float!]
		cy		[float!]
		pt		[red-point2D!]
][
	cr: dc/cr
	rad: PI / 180.0 * get-float angle
	either pen-fill = -1 [
		either ANY_COORD?(center) [
			GET_PAIR_XY_F(center cx cy)
			if dc/matrix-order = MATRIX-APPEND [
				cx: 0.0 - cx
				cy: 0.0 - cy
			]
			cairo-matrix-translate cr cx cy dc/matrix-order
			cairo-matrix-rotate cr rad dc/matrix-order
			cairo-matrix-translate cr 0.0 - cx 0.0 - cy dc/matrix-order
		][
			cairo-matrix-rotate cr rad dc/matrix-order
		]
	][
		grad: either pen-fill = pen [dc/grad-pen][dc/grad-brush]
		if grad/on? [
			matrix: as cairo_matrix_t! grad/matrix
			grad/matrix-on?: on
			cairo_matrix_rotate matrix 0.0 - rad
			sync-active-pattern-matrix grad
		]
	]
]

OS-matrix-scale: func [
	dc			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	center		[red-pair!]
	/local
		sy		[red-integer!]
		grad	[gradient!]
		matrix	[cairo_matrix_t!]
		x		[float!]
		y		[float!]
		cx		[float!]
		cy		[float!]
		pt		[red-point2D!]
][
	sy: sx + 1
	either pen-fill <> -1 [
		grad: either pen-fill = pen [dc/grad-pen][dc/grad-brush]
		if grad/on? [
			matrix: as cairo_matrix_t! grad/matrix
			grad/matrix-on?: on
			x: get-float sx
			y: get-float sy
			x: 1.0 / x
			y: 1.0 / y
			cairo_matrix_scale matrix x y
			sync-active-pattern-matrix grad
		]
	][
		either ANY_COORD?(center) [
			GET_PAIR_XY_F(center cx cy)
			if dc/matrix-order = MATRIX-APPEND [
				cx: 0.0 - cx
				cy: 0.0 - cy
			]
			cairo-matrix-translate dc/cr cx cy dc/matrix-order
			cairo-matrix-scale dc/cr get-float sx get-float sy dc/matrix-order
			cairo-matrix-translate dc/cr 0.0 - cx 0.0 - cy dc/matrix-order
		][
			cairo-matrix-scale dc/cr get-float sx get-float sy dc/matrix-order
		]
	]
]

OS-matrix-translate: func [
	dc			[draw-ctx!]
	pen-fill	[integer!]
	pos			[red-pair!]
	/local
		grad	[gradient!]
		matrix	[cairo_matrix_t!]
		pt		[red-point2D!]
		x y		[float!]
][
	GET_PAIR_XY_F(pos x y)
	either pen-fill <> -1 [
		grad: either pen-fill = pen [dc/grad-pen][dc/grad-brush]
		if grad/on? [
			matrix: as cairo_matrix_t! grad/matrix
			grad/matrix-on?: on
			cairo_matrix_translate matrix 0.0 - x 0.0 - y
			sync-active-pattern-matrix grad
		]
	][
		cairo-matrix-translate dc/cr x y dc/matrix-order
	]
]

OS-matrix-skew: func [
	dc			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	center		[red-pair!]
	/local
		sy		[red-integer!]
		xv		[float!]
		yv		[float!]
		cx		[float!]
		cy		[float!]
		grad	[gradient!]
		m		[cairo_matrix_t! value]
		matrix	[cairo_matrix_t!]
		res		[cairo_matrix_t! value]
		pt		[red-point2D!]
][
	sy: sx + 1
	xv: get-float sx
	yv: either all [
		sy <= center
		TYPE_OF(sy) <> TYPE_PAIR
	][
		get-float sy
	][
		0.0
	]
	m/xx: 1.0
	m/yx: either yv = 0.0 [0.0][tan degree-to-radians yv TYPE_TANGENT]
	m/xy: tan degree-to-radians get-float sx TYPE_TANGENT
	m/yy: 1.0
	m/x0: 0.0
	m/y0: 0.0
	either pen-fill <> -1 [
		grad: either pen-fill = pen [dc/grad-pen][dc/grad-brush]
		if grad/on? [
			matrix: as cairo_matrix_t! grad/matrix
			grad/matrix-on?: on
			m/yx: 0.0 - m/yx
			m/xy: 0.0 - m/xy
			cairo_matrix_multiply res matrix m
			copy-memory as byte-ptr! matrix as byte-ptr! res size? cairo_matrix_t!
			sync-active-pattern-matrix grad
		]
	][
		either ANY_COORD?(center) [
			GET_PAIR_XY_F(center cx cy)
			if dc/matrix-order = MATRIX-APPEND [
				cx: 0.0 - cx
				cy: 0.0 - cy
			]
			cairo-matrix-translate dc/cr cx cy dc/matrix-order
			cairo-matrix-concat dc/cr m dc/matrix-order
			cairo-matrix-translate dc/cr 0.0 - cx 0.0 - cy dc/matrix-order
		][
			cairo-matrix-concat dc/cr m dc/matrix-order
		]
	]
]

OS-matrix-transform: func [
	dc			[draw-ctx!]
	pen-fill	[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		cr		[handle!]
		rotate	[red-integer!]
		center?	[logic!]
		rad		[float!]
		cx		[float!]
		cy		[float!]
		x y		[float!]
		pt		[red-point2D!]
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center
	rad: PI / 180.0 * get-float rotate
	cr: dc/cr
	if center? [
		GET_PAIR_XY_F(center cx cy)
		if dc/matrix-order = MATRIX-APPEND [
			cx: 0.0 - cx
			cy: 0.0 - cy
		]
		cairo-matrix-translate dc/cr cx cy dc/matrix-order
	]
	GET_PAIR_XY_F(translate x y)
	either dc/matrix-order = MATRIX-APPEND [
		cairo-matrix-rotate cr rad dc/matrix-order
		cairo-matrix-scale cr get-float scale get-float scale + 1 dc/matrix-order
		cairo-matrix-translate cr x y dc/matrix-order
	][
		cairo-matrix-translate cr x y dc/matrix-order
		cairo-matrix-scale cr get-float scale get-float scale + 1 dc/matrix-order
		cairo-matrix-rotate cr rad dc/matrix-order
	]
	if center? [
		cairo-matrix-translate cr 0.0 - cx 0.0 - cy dc/matrix-order
	]
]

OS-draw-state-push: func [
	dc			[draw-ctx!]
	state		[draw-state!]
][
	cairo_save dc/cr
	if dc/font-attrs <> null [pango_attr_list_ref dc/font-attrs]
	;-- The byte-copy below aliases the gradient pattern handles between dc
	;-- and the saved state. Bump the user-ref so inner-block destroys (e.g.
	;-- via OS-draw-fill-pen) don't leave the saved snapshot dangling.
	if dc/grad-pen/pattern-on?   [cairo_pattern_reference dc/grad-pen/pattern]
	if dc/grad-brush/pattern-on? [cairo_pattern_reference dc/grad-brush/pattern]
	copy-memory as byte-ptr! state (as byte-ptr! dc) + 4 size? draw-state!
	if dc/clip-path <> null [state/clip-path: clone-cairo-path dc/cr dc/clip-path]
	state/shadows/next: clone-shadow-chain dc/shadows/next
]

OS-draw-state-pop: func [
	dc			[draw-ctx!]
	state		[draw-state!]
][
	cairo_restore dc/cr
	if dc/pen-pattern <> null [free as byte-ptr! dc/pen-pattern]
	if dc/font-attrs <> null [pango_attr_list_unref dc/font-attrs]
	;-- Release any pattern the inner block left in dc before the memcpy
	;-- overwrites the pointer with the saved one (whose extra ref was taken
	;-- in OS-draw-state-push).
	if dc/grad-pen/pattern-on?   [cairo_pattern_destroy dc/grad-pen/pattern]
	if dc/grad-brush/pattern-on? [cairo_pattern_destroy dc/grad-brush/pattern]
	free-shadow dc
	free-clip-path dc
	copy-memory (as byte-ptr! dc) + 4 as byte-ptr! state size? draw-state!
	if dc/font-opts <> null [cairo_font_options_set_antialias dc/font-opts state/font-antialias]
]

OS-matrix-reset: func [
	dc			[draw-ctx!]
	pen-fill	[integer!]
	/local
		grad	[gradient!]
		matrix	[cairo_matrix_t!]
][
	either pen-fill <> -1 [
		grad: either pen-fill = pen [dc/grad-pen][dc/grad-brush]
		if grad/on? [
			matrix: as cairo_matrix_t! grad/matrix
			grad/matrix-on?: on
			cairo_matrix_init_identity matrix
			sync-active-pattern-matrix grad
		]
	][
		cairo_identity_matrix dc/cr
	]
]

OS-matrix-invert: func [
	dc			[draw-ctx!]
	pen-fill	[integer!]
	/local
		grad	[gradient!]
		matrix	[cairo_matrix_t!]
][
	either pen-fill <> -1 [
		grad: either pen-fill = pen [dc/grad-pen][dc/grad-brush]
		if grad/on? [
			matrix: as cairo_matrix_t! grad/matrix
			grad/matrix-on?: on
			cairo_matrix_invert matrix
			sync-active-pattern-matrix grad
		]
	][
		cairo_get_matrix dc/cr matrix
		cairo_matrix_invert matrix
		cairo_set_matrix dc/cr matrix
	]
]

OS-matrix-set: func [
	dc			[draw-ctx!]
	pen-fill	[integer!]
	blk			[red-block!]
	/local
		grad	[gradient!]
		m		[cairo_matrix_t! value]
		val		[red-integer!]
		matrix	[cairo_matrix_t!]
		res		[cairo_matrix_t! value]
][
	val: as red-integer! block/rs-head blk
	m/xx: get-float val
	m/yx: get-float val + 1
	m/xy: get-float val + 2
	m/yy: get-float val + 3
	m/x0: get-float val + 4
	m/y0: get-float val + 5
	either pen-fill <> -1 [
		grad: either pen-fill = pen [dc/grad-pen][dc/grad-brush]
		if grad/on? [
			matrix: as cairo_matrix_t! grad/matrix
			grad/matrix-on?: on
			cairo_matrix_invert m
			cairo_matrix_multiply res matrix m
			copy-memory as byte-ptr! matrix as byte-ptr! res size? cairo_matrix_t!
			sync-active-pattern-matrix grad
		]
	][
		cairo-matrix-concat dc/cr m dc/matrix-order
	]
]

OS-set-matrix-order: func [
	ctx			[draw-ctx!]
	order		[integer!]
][
	case [
		order = _append [ ctx/matrix-order: MATRIX-APPEND ]
		order = prepend [ ctx/matrix-order: MATRIX-PREPEND ]
		true [ ctx/matrix-order: MATRIX-PREPEND ]
	]
]

OS-set-clip: func [
	dc			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
	rect?		[logic!]
	mode		[integer!]
	/local
		cr		[handle!]
		t		[float!]
		x1		[float!]
		x2		[float!]
		y1		[float!]
		y2		[float!]
		cx1		[float!]
		cy1		[float!]
		cx2		[float!]
		cy2		[float!]
		saved	[cairo_matrix_t! value]
		path	[handle!]
		track-path [handle!]
		old-path [handle!]
		pt		[red-point2D!]
		clip-list [cairo_rectangle_list_t!]
		rects	[cairo_rectangle_t!]
		advanced? [logic!]
		handled? [logic!]
		old?	[logic!]
		i		[integer!]
		right	[float!]
		bottom	[float!]
][
	cr: dc/cr
	path: null
	track-path: null
	old-path: null
	either rect? [
		GET_PAIR_XY_F(upper x1 y1)
		GET_PAIR_XY_F(lower x2 y2)
		if x1 > x2 [t: x1 x1: x2 x2: t]
		if y1 > y2 [t: y1 y1: y2 y2: t]
	][
		path: cairo_copy_path dc/cr
	]

	advanced?: any [
		mode = union
		mode = _xor
		mode = exclude
	]
	if advanced? [
		handled?: no
		clip-list: as cairo_rectangle_list_t! cairo_copy_clip_rectangle_list cr
		if all [
			clip-list <> null
			clip-list/status = 0
			clip-list/num_rectangles > 0
		][
			rects: as cairo_rectangle_t! clip-list/rectangles
			i: 0
			old?: no
			cx1: 0.0 cy1: 0.0 cx2: 0.0 cy2: 0.0
			while [i < clip-list/num_rectangles][
				if all [
					rects/width > 0.0
					rects/height > 0.0
				][
					right: rects/x + rects/width
					bottom: rects/y + rects/height
					either old? [
						if rects/x < cx1 [cx1: rects/x]
						if rects/y < cy1 [cy1: rects/y]
						if right > cx2 [cx2: right]
						if bottom > cy2 [cy2: bottom]
					][
						cx1: rects/x
						cy1: rects/y
						cx2: right
						cy2: bottom
						old?: yes
					]
				]
				rects: rects + 1
				i: i + 1
			]
			if old? [
				rects: as cairo_rectangle_t! clip-list/rectangles
				ctx-matrix-adapt dc saved
				case [
					mode = union [
						cairo_reset_clip cr
						cairo_new_path cr
						append-clip-rectangles cr rects clip-list/num_rectangles
						either rect? [
							cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
						][
							cairo_append_path cr path
						]
						cairo_set_fill_rule cr CAIRO_FILL_RULE_WINDING
						cairo_clip cr
						handled?: yes
					]
					mode = _xor [
						cairo_reset_clip cr
						cairo_new_path cr
						append-clip-rectangles cr rects clip-list/num_rectangles
						either rect? [
							cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
						][
							cairo_append_path cr path
						]
						cairo_set_fill_rule cr CAIRO_FILL_RULE_EVEN_ODD
						cairo_clip cr
						cairo_set_fill_rule cr CAIRO_FILL_RULE_WINDING
						handled?: yes
					]
					mode = exclude [
						cairo_reset_clip cr
						cairo_new_path cr
						append-clip-rectangles cr rects clip-list/num_rectangles
						cairo_set_fill_rule cr CAIRO_FILL_RULE_WINDING
						cairo_clip cr
						cairo_new_path cr
						cairo_rectangle cr cx1 cy1 cx2 - cx1 cy2 - cy1
						either rect? [
							cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
						][
							cairo_append_path cr path
						]
						cairo_set_fill_rule cr CAIRO_FILL_RULE_EVEN_ODD
						cairo_clip cr
						cairo_set_fill_rule cr CAIRO_FILL_RULE_WINDING
						handled?: yes
					]
				]
				ctx-matrix-unadapt dc saved
			]
		]
		if clip-list <> null [cairo_rectangle_list_destroy as handle! clip-list]
			if all [
				not handled?
				dc/clip-path <> null
				any [
					dc/clip-rule = CAIRO_FILL_RULE_WINDING
					mode = exclude
					all [
						any [
							mode = union
							mode = _xor
						]
						dc/clip-rule = CAIRO_FILL_RULE_EVEN_ODD
						rect?
						any [
							x2 <= dc/clip-x1
							x1 >= dc/clip-x2
							y2 <= dc/clip-y1
							y1 >= dc/clip-y2
						]
					]
			]
		][
			if any [
				mode = union
				mode = _xor
			][
				old-path: clone-cairo-path cr dc/clip-path
				cairo_new_path cr
				cairo_append_path cr old-path
				either rect? [
					cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
				][
					cairo_append_path cr path
				]
				track-path: cairo_copy_path cr
				track-clip-path dc track-path either mode = union [
					dc/clip-rule
				][
					CAIRO_FILL_RULE_EVEN_ODD
				]
				cairo_path_destroy track-path
			]
			ctx-matrix-adapt dc saved
			case [
				mode = union [
					cairo_reset_clip cr
					cairo_new_path cr
					cairo_append_path cr old-path
					either rect? [
						cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
					][
						cairo_append_path cr path
					]
					cairo_set_fill_rule cr dc/clip-rule
					cairo_clip cr
					cairo_set_fill_rule cr CAIRO_FILL_RULE_WINDING
					handled?: yes
				]
				mode = _xor [
					cairo_reset_clip cr
					cairo_new_path cr
					cairo_append_path cr old-path
					either rect? [
						cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
					][
						cairo_append_path cr path
					]
					cairo_set_fill_rule cr CAIRO_FILL_RULE_EVEN_ODD
					cairo_clip cr
					cairo_set_fill_rule cr CAIRO_FILL_RULE_WINDING
					handled?: yes
				]
				mode = exclude [
					cairo_reset_clip cr
					cairo_new_path cr
					cairo_append_path cr dc/clip-path
					cairo_set_fill_rule cr dc/clip-rule
					cairo_clip cr
					cairo_new_path cr
					cairo_rectangle cr dc/clip-x1 dc/clip-y1 dc/clip-x2 - dc/clip-x1 dc/clip-y2 - dc/clip-y1
					either rect? [
						cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
					][
						cairo_append_path cr path
					]
					cairo_set_fill_rule cr CAIRO_FILL_RULE_EVEN_ODD
					cairo_clip cr
					cairo_set_fill_rule cr CAIRO_FILL_RULE_WINDING
					free-clip-path dc
					handled?: yes
				]
			]
			ctx-matrix-unadapt dc saved
		]
		if handled? [
			if old-path <> null [cairo_path_destroy old-path]
			if path <> null [cairo_path_destroy path]
			exit
		]
	]

	if mode = replace [cairo_reset_clip cr]
	either mode = replace [
		cairo_new_path cr
		either rect? [
			cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
		][
			cairo_append_path cr path
		]
		track-path: cairo_copy_path cr
		track-clip-path dc track-path CAIRO_FILL_RULE_WINDING
		cairo_path_destroy track-path
	][
		free-clip-path dc
	]
	cairo_new_path dc/cr
	ctx-matrix-adapt dc saved
	either rect? [
		cairo_rectangle cr x1 y1 x2 - x1 y2 - y1
	][
		cairo_append_path dc/cr path
		cairo_path_destroy path
	]
	cairo_clip cr
	ctx-matrix-unadapt dc saved
]

OS-clip-end: func [
	ctx		[draw-ctx!]
][]

;-- shape sub command --

OS-draw-shape-beginpath: func [
	dc			[draw-ctx!]
	draw?		[logic!]
][
	cairo_move_to dc/cr 0.0 0.0
]

OS-draw-shape-endpath: func [
	dc			[draw-ctx!]
	close?		[logic!]
	return:		[logic!]
	/local
		saved	[cairo_matrix_t! value]
		path	[handle!]
][
	if close? [cairo_close_path dc/cr]
	path: cairo_copy_path dc/cr
	cairo_new_path dc/cr
	ctx-matrix-adapt dc saved
	cairo_append_path dc/cr path
	cairo_path_destroy path
	do-draw-path dc
	ctx-matrix-unadapt dc saved
	true
]

OS-draw-shape-moveto: func [
	dc			[draw-ctx!]
	coord		[red-pair!]
	rel?		[logic!]
	/local
		x		[float!]
		y		[float!]
		pt		[red-point2D!]
][
	GET_PAIR_XY_F(coord x y)
	either rel? [
		cairo_rel_move_to dc/cr x y
	][
		cairo_move_to dc/cr x y
	]
	dc/shape-curve?: no
]

OS-draw-shape-line: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	/local
		x		[float!]
		y		[float!]
		pt		[red-point2D!]
][
	until [
		GET_PAIR_XY_F(start x y)
		either rel? [
			cairo_rel_line_to dc/cr x y
		][
			cairo_line_to dc/cr x y
		]
		start: start + 1
		start > end
	]
	dc/shape-curve?: no
]

OS-draw-shape-axis: func [
	dc			[draw-ctx!]
	start		[red-value!]
	end			[red-value!]
	rel?		[logic!]
	hline?		[logic!]
	/local
		len		[float!]
		last-x	[float!]
		last-y	[float!]
][
	last-x: 0.0 last-y: 0.0
	if 1 = cairo_has_current_point dc/cr [
		cairo_get_current_point dc/cr :last-x :last-y
	]
	len: get-float as red-integer! start
	either hline? [
		cairo_line_to dc/cr either rel? [last-x + len][len] last-y
	][
		cairo_line_to dc/cr last-x either rel? [last-y + len][len]
	]
	dc/shape-curve?: no
]

draw-curve: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	short?		[logic!]
	num			[integer!]				;--	number of points
	/local
		dx		[float!]
		dy		[float!]
		p3y		[float!]
		p3x		[float!]
		p2y		[float!]
		p2x		[float!]
		p1y		[float!]
		p1x		[float!]
		pf		[float-ptr!]
		pair	[red-pair!]
		last-x	[float!]
		last-y	[float!]
		pt		[red-point2D!]
][
	while [ start < end ][
		pair: start + 1
		GET_PAIR_XY_F(start p1x p1y)
		GET_PAIR_XY_F(pair p2x p2y)
		if num = 3 [					;-- cubic Bézier
			pair: start + 2
			GET_PAIR_XY_F(pair p3x p3y)
		]

		last-x: 0.0 last-y: 0.0
		if 1 = cairo_has_current_point dc/cr [
			cairo_get_current_point dc/cr :last-x :last-y
		]
		dx: last-x
		dy: last-y
		if rel? [
			pf: :p1x
			loop num [
				pf/1: pf/1 + dx			;-- x
				pf/2: pf/2 + dy			;-- y
				pf: pf + 2
			]
		]

		if short? [
			either dc/shape-curve? [
				;-- The control point is assumed to be the reflection of the control point
				;-- on the previous command relative to the current point
				p1x: dx * 2.0 - (as float! dc/control-x)
				p1y: dy * 2.0 - (as float! dc/control-y)
			][
				;-- if previous command is not curve/curv/qcurve/qcurv, use current point
				p1x: dx
				p1y: dy
			]
			start: start - 1
		]

		dc/shape-curve?: yes
		either num = 3 [				;-- cubic Bézier
			cairo_curve_to dc/cr p1x p1y p2x p2y p3x p3y
			dc/control-x: as float32! p2x
			dc/control-y: as float32! p2y
		][								;-- quadratic Bézier
			cairo_curve_to dc/cr
				(0.6666666666666666 * p1x) + (0.3333333333333333 * dx)
				(0.6666666666666666 * p1y) + (0.3333333333333333 * dy)
				(0.6666666666666666 * p1x) + (0.3333333333333333 * p2x)
				(0.6666666666666666 * p1y) + (0.3333333333333333 * p2y)
				p2x p2y
			dc/control-x: as float32! p1x
			dc/control-y: as float32! p1y
		]
		start: start + num
	]
]


OS-draw-shape-curve: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve dc start end rel? no 3
]

OS-draw-shape-qcurve: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve dc start end rel? no 2
]

OS-draw-shape-curv: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve dc start - 1 end rel? yes 3
]

OS-draw-shape-qcurv: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][
	draw-curve dc start - 1 end rel? yes 2
]

OS-draw-shape-arc: func [
	dc			[draw-ctx!]
	end			[red-pair!]
	sweep?		[logic!]
	large?		[logic!]
	rel?		[logic!]
	/local
		cr			[handle!]
		item		[red-integer!]
		last-x		[float!]
		last-y		[float!]
		center-x	[float32!]
		center-y	[float32!]
		cx			[float32!]
		cy			[float32!]
		cf			[float32!]
		radius-x	[float32!]
		radius-y	[float32!]
		theta		[float32!]
		X1			[float32!]
		Y1			[float32!]
		p1-x		[float32!]
		p1-y		[float32!]
		p2-x		[float32!]
		p2-y		[float32!]
		cos-val		[float32!]
		sin-val		[float32!]
		rx2			[float32!]
		ry2			[float32!]
		dx			[float32!]
		dy			[float32!]
		sqrt-val	[float32!]
		sign		[float32!]
		rad-check	[float32!]
		pi2			[float32!]
		matrix		[cairo_matrix_t! value]
		pt			[red-point2D!]
][
	cr: dc/cr
	last-x: 0.0 last-y: 0.0
	if 1 = cairo_has_current_point cr [
		cairo_get_current_point cr :last-x :last-y
	]
	p1-x: as float32! last-x p1-y: as float32! last-y
	GET_PAIR_XY(end p2-x p2-y)
	if rel? [ p2-x: p1-x + p2-x ]
	if rel? [ p2-y: p1-y + p2-y ]

	item: as red-integer! end + 1
	radius-x: fabsf get-float32 item
	item: item + 1
	radius-y: fabsf get-float32 item
	item: item + 1
	pi2: as float32! 2.0 * PI
	theta: get-float32 item
	theta: theta * as float32! (PI / 180.0)
	theta: as-float32 fmod as-float theta as-float pi2 ; OLD: theta % pi2

	;-- calculate center
	dx: (p1-x - p2-x) / as float32! 2.0
	dy: (p1-y - p2-y) / as float32! 2.0
	cos-val: cosf theta
	sin-val: sinf theta
	X1: (cos-val * dx) + (sin-val * dy)
	Y1: (cos-val * dy) - (sin-val * dx)
	rx2: radius-x * radius-x
	ry2: radius-y * radius-y
	rad-check: ((X1 * X1) / rx2) + ((Y1 * Y1) / ry2)
	if rad-check > as float32! 1.0 [
		radius-x: radius-x * sqrtf rad-check
		radius-y: radius-y * sqrtf rad-check
		rx2: radius-x * radius-x
		ry2: radius-y * radius-y
	]
	either large? = sweep? [sign: as float32! -1.0 ][sign: as float32! 1.0 ]
	sqrt-val: ((rx2 * ry2) - (rx2 * Y1 * Y1) - (ry2 * X1 * X1)) / ((rx2 * Y1 * Y1) + (ry2 * X1 * X1))
	either sqrt-val < as float32! 0.0 [cf: as float32! 0.0 ][ cf: sign * sqrtf sqrt-val ]
	cx: cf * (radius-x * Y1 / radius-y)
	cy: cf * (radius-y * X1 / radius-x) * (as float32! -1.0)
	center-x: (cos-val * cx) - (sin-val * cy) + ((p1-x + p2-x) / as float32! 2.0)
	center-y: (sin-val * cx) + (cos-val * cy) + ((p1-y + p2-y) / as float32! 2.0)

	cairo_matrix_init_scale matrix 1.0 / as float! radius-x 1.0 / as float! radius-y
	cairo_matrix_rotate matrix 0.0 - as float! theta
	cairo_matrix_translate matrix 0.0 - as float! center-x 0.0 - as float! center-y
	last-x: as float! p1-x
	last-y: as float! p1-y
	cairo_matrix_transform_point matrix :last-x :last-y
	p1-x: as float32! last-x
	p1-y: as float32! last-y
	last-x: as float! p2-x
	last-y: as float! p2-y
	cairo_matrix_transform_point matrix :last-x :last-y
	p2-x: as float32! last-x
	p2-y: as float32! last-y

	;-- calculate angles
	cx: atan2f p1-y p1-x
	cy: atan2f p2-y p2-x

	cairo_save cr
	;cairo_new_sub_path cr
	cairo_translate cr as float! center-x as float! center-y
	cairo_rotate    cr as float! theta
	cairo_scale     cr as float! radius-x as float! radius-y
	either sweep? [
		cairo_arc cr 0.0 0.0 1.0 as float! cx as float! cy
	][
		cairo_arc_negative cr 0.0 0.0 1.0 as float! cx as float! cy
	]
	cairo_restore cr
]

OS-draw-shape-close: func [
	dc			[draw-ctx!]
][
	cairo_close_path dc/cr
]

get-brush-mode: func [
	mode	[red-word!]
	return: [integer!]
][
	either mode = null [tile][symbol/resolve mode/symbol]
]

crop-brush-surface: func [
	src		[handle!]
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
	return: [handle!]
	/local
		surf	[handle!]
		cr		[handle!]
][
	surf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 width height
	cr: cairo_create surf
	cairo_set_source_surface cr src as-float 0 - x as-float 0 - y
	cairo_paint cr
	cairo_destroy cr
	surf
]

prepare-brush-surface: func [
	src		[handle!]
	width	[integer!]
	height	[integer!]
	mode	[integer!]
	return: [handle!]
	/local
		surf	[handle!]
		cr		[handle!]
		w2		[integer!]
		h2		[integer!]
][
	surf: src
	case [
		mode = flip-x [
			w2: width * 2
			surf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 w2 height
			cr: cairo_create surf
			cairo_set_source_surface cr src 0.0 0.0
			cairo_paint cr
			cairo_save cr
			cairo_translate cr as-float w2 0.0
			cairo_scale cr -1.0 1.0
			cairo_set_source_surface cr src 0.0 0.0
			cairo_paint cr
			cairo_restore cr
			cairo_destroy cr
		]
		mode = flip-y [
			h2: height * 2
			surf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 width h2
			cr: cairo_create surf
			cairo_set_source_surface cr src 0.0 0.0
			cairo_paint cr
			cairo_save cr
			cairo_translate cr 0.0 as-float h2
			cairo_scale cr 1.0 -1.0
			cairo_set_source_surface cr src 0.0 0.0
			cairo_paint cr
			cairo_restore cr
			cairo_destroy cr
		]
		mode = flip-xy [
			w2: width * 2
			h2: height * 2
			surf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 w2 h2
			cr: cairo_create surf
			cairo_set_source_surface cr src 0.0 0.0
			cairo_paint cr
			cairo_save cr
			cairo_translate cr as-float w2 0.0
			cairo_scale cr -1.0 1.0
			cairo_set_source_surface cr src 0.0 0.0
			cairo_paint cr
			cairo_restore cr
			cairo_save cr
			cairo_translate cr 0.0 as-float h2
			cairo_scale cr 1.0 -1.0
			cairo_set_source_surface cr src 0.0 0.0
			cairo_paint cr
			cairo_restore cr
			cairo_save cr
			cairo_translate cr as-float w2 as-float h2
			cairo_scale cr -1.0 -1.0
			cairo_set_source_surface cr src 0.0 0.0
			cairo_paint cr
			cairo_restore cr
			cairo_destroy cr
		]
		true [0]
	]
	surf
]

make-brush-pattern: func [
	src		[handle!]
	width	[integer!]
	height	[integer!]
	mode	[integer!]
	return: [handle!]
	/local
		pattern		[handle!]
		prepared	[handle!]
		extend		[integer!]
][
	prepared: prepare-brush-surface src width height mode
	extend: either mode = clamp [CAIRO_EXTEND_PAD][CAIRO_EXTEND_REPEAT]
	pattern: cairo_pattern_create_for_surface prepared
	cairo_pattern_set_extend pattern extend
	if prepared <> src [cairo_surface_destroy prepared]
	pattern
]

set-surface-brush-origin: func [
	pattern	[handle!]
	x		[float!]
	y		[float!]
	saved	[cairo_matrix_t!]
	return: [logic!]
	/local
		shift	[cairo_matrix_t! value]
		matrix	[cairo_matrix_t! value]
][
	cairo_pattern_get_matrix pattern saved
	cairo_matrix_init_translate shift 0.0 - x 0.0 - y
	cairo_matrix_multiply matrix saved shift
	cairo_pattern_set_matrix pattern matrix
	yes
]

set-brush-pattern: func [
	dc		[draw-ctx!]
	pattern	[handle!]
	brush?	[logic!]
	/local
		grad	[gradient!]
		matrix	[cairo_matrix_t!]
][
	grad: either brush? [
		dc/brush?: yes
		dc/grad-brush
	][
		dc/pen?: yes
		dc/grad-pen
	]
	if all [grad/on? grad/pattern-on?][
		cairo_pattern_destroy grad/pattern
	]
	grad/on?: on
	grad/type: bitmap
	grad/matrix-on?: off
	matrix: as cairo_matrix_t! grad/matrix
	cairo_matrix_init_identity matrix
	cairo_pattern_set_matrix pattern matrix
	grad/pattern: pattern
	grad/pattern-on?: on
]

OS-draw-brush-bitmap: func [
	dc			[draw-ctx!]
	img			[red-image!]
	crop-1		[red-pair!]
	crop-2		[red-pair!]
	mode		[red-word!]
	brush?		[logic!]
	/local
		width	[integer!]
		height	[integer!]
		pixbuf	[handle!]
		x xx	[integer!]
		y yy	[integer!]
		surf	[handle!]
		cr		[handle!]
		pattern	[handle!]
		mode-id [integer!]
		pt		[red-point2D!]
][
	width:  OS-image/width? img/node
	height: OS-image/height? img/node
	pixbuf: OS-image/to-pixbuf img
	either crop-1 = null [
		x: 0
		y: 0
	][
		GET_PAIR_XY_INT(crop-1 x y)
	]
	either crop-2 = null [
		width:  width - x
		height: height - y
	][
		GET_PAIR_XY_INT(crop-2 xx yy)
		width:  either ( x + xx ) > width [ width - x ][ xx ]
		height: either ( y + yy ) > height [ height - y ][ yy ]
	]
	mode-id: get-brush-mode mode
	surf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 width height
	cr: cairo_create surf
	cairo_translate cr as-float 0 - x as-float 0 - y
	gdk_cairo_set_source_pixbuf cr pixbuf 0.0 0.0
	cairo_paint cr
	cairo_destroy cr
	pattern: make-brush-pattern surf width height mode-id
	cairo_surface_destroy surf
	set-brush-pattern dc pattern brush?
]

OS-draw-brush-pattern: func [
	dc			[draw-ctx!]
	size		[red-pair!]
	crop-1		[red-pair!]
	crop-2		[red-pair!]
	mode		[red-word!]
	block		[red-block!]
	brush?		[logic!]
	/local
		surf	[handle!]
		crop	[handle!]
		cr		[handle!]
		x		[integer!]
		y		[integer!]
		xx		[integer!]
		yy		[integer!]
		width	[integer!]
		height	[integer!]
		pattern	[handle!]
		mode-id [integer!]
		pt		[red-point2D!]
][
	GET_PAIR_XY_INT(size x y)
	width: x
	height: y
	surf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 x y
	cr: cairo_create surf
	do-draw cr null block no no yes yes
	cairo_destroy cr

	either crop-1 = null [
		x: 0
		y: 0
	][
		GET_PAIR_XY_INT(crop-1 x y)
	]
	either crop-2 = null [
		width:  width - x
		height: height - y
	][
		GET_PAIR_XY_INT(crop-2 xx yy)
		width:  either (x + xx) > width [width - x][xx]
		height: either (y + yy) > height [height - y][yy]
	]
	crop: surf
	if any [x <> 0 y <> 0 width <> size/x height <> size/y][
		crop: crop-brush-surface surf x y width height
	]
	mode-id: get-brush-mode mode
	pattern: make-brush-pattern crop width height mode-id
	if crop <> surf [cairo_surface_destroy crop]
	cairo_surface_destroy surf
	set-brush-pattern dc pattern brush?
]

OS-draw-shadow: func [
	ctx		[draw-ctx!]
	offset	[red-pair!]
	blur	[integer!]
	spread	[integer!]
	color	[integer!]
	inset?	[logic!]
	/local
		pt	[red-point2D!]
		s	[shadow!]
		tail [shadow!]
		chain? [logic!]
][
	chain?: ctx/shadow?
	ctx/shadow?: ANY_COORD?(offset)
	either ctx/shadow? [
		either chain? [
			s: as shadow! allocate size? shadow!
			s/next: null
			GET_PAIR_XY_F(offset s/offset-x s/offset-y)
			s/blur: as float! blur
			s/spread: as float! spread
			s/color: color
			s/inset?: inset?
			tail: ctx/shadows
			while [tail/next <> null][tail: tail/next]
			tail/next: s
		][
			free-shadow ctx
			GET_PAIR_XY_F(offset ctx/shadow-offset-x ctx/shadow-offset-y)
			ctx/shadow-blur: as float! blur
			ctx/shadow-spread: as float! spread
			ctx/shadow-color: color
			ctx/shadow-inset?: inset?
		]
	][
		free-shadow ctx
	]
]
