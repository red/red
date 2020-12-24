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

draw-state!: alias struct! [
	pen-join		[integer!]
	pen-cap			[integer!]
	pen-style		[integer!]
	pen-color		[integer!]					;-- 00bbggrr format
	brush-color		[integer!]					;-- 00bbggrr format
	font-color		[integer!]
	grad-pen		[gradient! value]
	grad-brush		[gradient! value]
	pen?			[logic!]
	brush?			[logic!]
	on-image?		[logic!]
]

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

#enum MATRIX-ORDER! [
	MATRIX-APPEND
	MATRIX-PREPEND
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

set-source-color: func [
	cr			[handle!]
	color		[integer!]
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
	cairo_set_source_rgba cr r g b a
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
][
	ctx/cr:				cr
	ctx/pen-style:		0
	ctx/pen-color:		0						;-- default: black
	ctx/pen-join:		miter
	ctx/pen-cap:		flat
	ctx/brush-color:	0
	ctx/font-color:		0
	ctx/pen?:			yes
	ctx/brush?:			no
	ctx/matrix-order:	MATRIX-PREPEND
	ctx/pattern?:		pattern?

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
	if dc/grad-pen/on? [
		free-gradient dc/grad-pen
		dc/grad-pen/on?: off
	]
	if dc/grad-brush/on? [
		free-gradient dc/grad-brush
		dc/grad-brush/on?: off
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

do-draw-path: func [
	dc			[draw-ctx!]
	/local
		cr		[handle!]
][
	cr: dc/cr
	if dc/brush? [
		either all [
			dc/grad-brush/on?
			dc/grad-brush/pattern-on?
		][
			cairo_set_source cr dc/grad-brush/pattern
		][
			set-source-color cr dc/brush-color
		]
		cairo_fill_preserve cr
	]
	do-draw-pen dc
]

do-draw-pen: func [
	dc			[draw-ctx!]
	/local
		cr		[handle!]
][
	cr: dc/cr
	either dc/pen? [
		either all [
			dc/grad-pen/on?
			dc/grad-pen/pattern-on?
		][
			cairo_set_source cr dc/grad-pen/pattern
		][
			set-source-color cr dc/pen-color
		]
		cairo_stroke cr
	][
		cairo_new_path cr
	]
]

line-distance: func [
	x1			[integer!]
	y1			[integer!]
	x2			[integer!]
	y2			[integer!]
	return:		[float32!]
	/local
		x		[float32!]
		y		[float32!]
		px		[float32!]
		py		[float32!]
		delta	[float32!]
][
	x: as float32! x1
	y: as float32! y1
	px: (as float32! x2) - x
	py: (as float32! y2) - y
	delta: (px * px) + (py * py)
	sqrtf delta
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
			true [CAIRO_EXTEND_REPEAT]								;-- default spread
		]

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
	either grad/pattern-on? [
		cairo_pattern_destroy grad/pattern
	][
		grad/pattern-on?: on
	]
	grad/pattern: pattern
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
][
	;-- implementation taken from http://stackoverflow.com/questions/2792443/finding-the-centroid-of-a-polygon
	signedArea: as float32! 0.0
	centroid-x: as float32! 0.0 centroid-y: as float32! 0.0
	point: start
	while [point <= end][
		x0: as float32! point/x
		y0: as float32! point/y
		point: point + 1
		x1: as float32! point/x
		y1: as float32! point/y
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
			dx: centroid-x - as float32! point/x
			dy: centroid-y - as float32! point/y
			r: sqrtf dx * dx + ( dy * dy )
			if r > d/value [ d/value: r ]
			point: point + 1
		]
	]
]

check-grad-points: func [
	grad		[gradient!]
	upper-x		[integer!]
	upper-y		[integer!]
	lower-x		[integer!]
	lower-y		[integer!]
	/local
		pattern	[handle!]
		t		[integer!]
		x1		[float!]
		y1		[float!]
		r1		[float!]
		x2		[float!]
		y2		[float!]
		r2		[float!]
		delta	[float32!]
		px		[float32!]
		py		[float32!]
][
	unless grad/on? [exit]
	pattern: null
	case [
		grad/type = linear [
			either grad/offset-on? [
				x1: as float! grad/offset/x
				y1: as float! grad/offset/y
				x2: as float! grad/offset2/x
				y2: as float! grad/offset2/y
			][
				x1: as float! upper-x y1: as float! upper-y
				x2: as float! lower-x y2: as float! lower-y
			]
			pattern: cairo_pattern_create_linear x1 y1 x2 y2
		]
		grad/type = radial [
			either grad/offset-on? [
				either grad/focal-on? [
					x1: as float! grad/focal/x
					y1: as float! grad/focal/y
					x2: as float! grad/offset/x
					y2: as float! grad/offset/y
					r1: 0.0 ;as float! grad/offset2/x
					r2: as float! grad/offset2/y
				][
					x1: as float! grad/offset/x
					y1: as float! grad/offset/y
					x2: x1
					y2: y1
					r1: 0.0 ;as float! grad/offset2/x
					r2: as float! grad/offset2/y
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
				px: as float32! lower-x + upper-x
				py: as float32! lower-y + upper-y
				x1: as float! px
				x1: x1 / 2.0
				y1: as float! py
				y1: y1 / 2.0
				x2: x1 y2: y1
				r1: 0.0
				r2: as float! delta
			]
			pattern: cairo_pattern_create_radial x1 y1 r1 x2 y2 r2
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
][
	check-grad-points grad upper/x upper/y lower/x lower/y
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
][
	unless grad/on? [exit]
	pattern: null
	case [
		grad/type = linear [
			either grad/offset-on? [
				x1: as float! grad/offset/x
				y1: as float! grad/offset/y
				x2: as float! grad/offset2/x
				y2: as float! grad/offset2/y
			][
				x1: as float! point/x y1: as float! point/y
				next: point + 1
				x2: as float! next/x  y2: as float! next/y
			]
			pattern: cairo_pattern_create_linear x1 y1 x2 y2
		]
		grad/type = radial [
			either grad/offset-on? [
				either grad/focal-on? [
					x1: as float! grad/focal/x
					y1: as float! grad/focal/y
					x2: as float! grad/offset/x
					y2: as float! grad/offset/y
					r1: 0.0 ;as float! grad/offset2/x
					r2: as float! grad/offset2/y
				][
					x1: as float! grad/offset/x
					y1: as float! grad/offset/y
					x2: x1
					y2: y1
					r1: 0.0 ;as float! grad/offset2/x
					r2: as float! grad/offset2/y
				]
			][
				cx: as float32! 0.0
				cy: cx
				d: cx
				get-shape-center point end :cx :cy :d
				x1: as float! cx
				y1: as float! cy
				r1: 0.0
				x2: x1
				y2: y1
				r2: as float! d
			]
			pattern: cairo_pattern_create_radial x1 y1 r1 x2 y2 r2
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
		delta	[float32!]
][
	unless grad/on? [exit]
	unless grad/type = radial [exit]
	pattern: null

	either grad/offset-on? [
		either grad/focal-on? [
			x1: as float! grad/focal/x
			y1: as float! grad/focal/y
			x2: as float! grad/offset/x
			y2: as float! grad/offset/y
			r1: 0.0 ;as float! grad/offset2/x
			r2: as float! grad/offset2/y
		][
			x1: as float! grad/offset/x
			y1: as float! grad/offset/y
			x2: x1
			y2: y1
			r1: 0.0 ;as float! grad/offset2/x
			r2: as float! grad/offset2/y
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
		delta	[float32!]
		w		[integer!]
		h		[integer!]
][
	unless grad/on? [exit]
	unless grad/type = radial [exit]
	pattern: null

	either grad/offset-on? [
		either grad/focal-on? [
			x1: as float! grad/focal/x
			y1: as float! grad/focal/y
			x2: as float! grad/offset/x
			y2: as float! grad/offset/y
			r1: 0.0 ;as float! grad/offset2/x
			r2: as float! grad/offset2/y
		][
			x1: as float! grad/offset/x
			y1: as float! grad/offset/y
			x2: x1
			y2: y1
			r1: 0.0 ;as float! grad/offset2/x
			r2: as float! grad/offset2/y
		]
	][
		x1: as float! upper/x + lower/x
		y1: as float! upper/y + lower/y
		x1: x1 / 2.0
		y1: y1 / 2.0
		r1: 0.0
		x2: x1
		y2: y1
		w: either upper/x < lower/x [
			lower/x - upper/x
		][
			upper/x - lower/x
		]
		h: either upper/y < lower/y [
			lower/y - upper/y
		][
			upper/y - lower/y
		]
		r2: either w > h [as float! w][as float! h]
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
][
	case [
		grad/type = linear [
			;-- the windows backend use horizontal linear gradient default,
			;-- maybe should use diagonal line
			check-grad-points grad upper/x upper/y lower/x upper/y
		]
		grad/type = radial [
			check-grad-box-radial grad upper lower
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
			check-grad-points grad
				as integer! cx - rx as integer! cy - ry
				as integer! cx + rx as integer! cy + ry
		]
		grad/type = radial [
			r: rx
			if rx > ry [r: ry]
			check-grad-arc-radial grad cx cy r
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
][
	cr: dc/cr
	ctx-matrix-adapt dc saved
	cairo_new_sub_path cr
	iter: point
	while [iter <= end][
		cairo_line_to cr as-float iter/x as-float iter/y
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
		dc/font-color: color
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

OS-draw-line-width: func [
	dc			[draw-ctx!]
	width		[red-value!]
	/local
		w		[float!]
][
	w: get-float as red-integer! width
	if w <= 0.0 [w: 1.0]
	cairo_set_line_width dc/cr w
]

OS-draw-box: func [
	dc			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		cr		[handle!]
		radius	[red-integer!]
		t 		[integer!]
		rad		[float!]
		x		[float!]
		y		[float!]
		w		[float!]
		h		[float!]
		tf		[float!]
		degrees [float!]
		saved	[cairo_matrix_t! value]
][
	cr: dc/cr
	radius: null
	if TYPE_OF(lower) = TYPE_INTEGER [
		radius: as red-integer! lower
		lower:  lower - 1
	]

	if upper/x > lower/x [t: upper/x upper/x: lower/x lower/x: t]
	if upper/y > lower/y [t: upper/y upper/y: lower/y lower/y: t]

	x: as-float upper/x
	y: as-float upper/y
	w: as-float lower/x - upper/x
	h: as-float lower/y - upper/y

	ctx-matrix-adapt dc saved
	either radius <> null [
		tf: either w > h [h][w]
		tf: tf / 2.0
		rad: as-float radius/value
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
][
	ctx-matrix-adapt dc saved
	cairo_new_sub_path dc/cr
	loop 3 [
		cairo_line_to dc/cr as-float start/x as-float start/y
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
][
	ctx-matrix-adapt dc saved
	cairo_new_sub_path dc/cr
	until [
		cairo_line_to dc/cr as-float start/x as-float start/y
		start: start + 1
		start > end
	]
	cairo_close_path dc/cr
	check-grad-line dc/grad-pen start start + 1
	check-grad-brush-lines dc/grad-brush start end
	do-draw-path dc
	ctx-matrix-unadapt dc saved
]

spline-delta: 1.0 / 25.0

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
][
	t: 0.0
	loop 25 [
		t: t + spline-delta
		t2: t * t
		t3: t2 * t

		x:
			2.0 * (as-float p1/x) + ((as-float p2/x) - (as-float p0/x) * t) +
			((2.0 * (as-float p0/x) - (5.0 * (as-float p1/x)) + (4.0 * (as-float p2/x)) - (as-float p3/x)) * t2) +
			(3.0 * ((as-float p1/x) - (as-float p2/x)) + (as-float p3/x) - (as-float p0/x) * t3) * 0.5
		y:
			2.0 * (as-float p1/y) + ((as-float p2/y) - (as-float p0/y) * t) +
			((2.0 * (as-float p0/y) - (5.0 * (as-float p1/y)) + (4.0 * (as-float p2/y)) - (as-float p3/y)) * t2) +
			(3.0 * ((as-float p1/y) - (as-float p2/y)) + (as-float p3/y) - (as-float p0/y) * t3) * 0.5

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
		rad-x	[integer!]
		rad-y	[integer!]
		w		[float!]
		h		[float!]
		f		[red-float!]
		saved	[cairo_matrix_t! value]
][
	cr: dc/cr
	either TYPE_OF(radius) = TYPE_INTEGER [
		either center + 1 = radius [					;-- center, radius
			rad-x: radius/value
			rad-y: rad-x
		][
			rad-y: radius/value							;-- center, radius-x, radius-y
			radius: radius - 1
			rad-x: radius/value
		]
		w: as float! rad-x * 2
		h: as float! rad-y * 2
	][
		f: as red-float! radius
		either center + 1 = radius [
			rad-x: as-integer f/value + 0.75
			rad-y: rad-x
			w: as float! f/value * 2.0
			h: w
		][
			rad-y: as-integer f/value + 0.75
			h: as float! f/value * 2.0
			f: f - 1
			rad-x: as-integer f/value + 0.75
			w: as float! f/value * 2.0
		]
	]
	if any [
		rad-x = 0
		rad-y = 0
	][exit]

	ctx-matrix-adapt dc saved
	cairo_new_sub_path cr
	cairo_save cr
	cairo_translate cr as-float center/x
						as-float center/y
	cairo_scale cr as-float rad-x
					as-float rad-y
	cairo_arc cr 0.0 0.0 1.0 0.0 2.0 * pi
	cairo_restore cr
	check-grad-circle dc/grad-pen as float! center/x as float! center/y as float! rad-x as float! rad-y
	check-grad-circle dc/grad-brush as float! center/x as float! center/y as float! rad-x as float! rad-y
	do-draw-path dc
	ctx-matrix-unadapt dc saved
]

OS-draw-ellipse: func [
	dc			[draw-ctx!]
	upper		[red-pair!]
	diameter	[red-pair!]
	/local
		cr		[handle!]
		rad-x	[integer!]
		rad-y	[integer!]
		cx		[integer!]
		cy		[integer!]
		saved	[cairo_matrix_t! value]
][
	cr: dc/cr
	rad-x: diameter/x / 2
	rad-y: diameter/y / 2
	cx: upper/x + rad-x
	cy: upper/y + rad-y
	if any [
		rad-x = 0
		rad-y = 0
	][exit]

	ctx-matrix-adapt dc saved
	cairo_new_sub_path cr
	cairo_save cr
	cairo_translate cr as-float cx
					   as-float cy
	cairo_scale cr as-float rad-x
					as-float rad-y
	cairo_arc cr 0.0 0.0 1.0 0.0 2.0 * pi
	cairo_restore cr
	check-grad-circle dc/grad-pen as float! cx as float! cy as float! rad-x as float! rad-y
	check-grad-circle dc/grad-brush as float! cx as float! cy as float! rad-x as float! rad-y
	do-draw-path dc
	ctx-matrix-unadapt dc saved
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
][
	free-pango-cairo-font dc
	dc/font-attrs: create-pango-attrs null font
	dc/font-opts: cairo_font_options_create

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
	cairo_font_options_set_antialias dc/font-opts quality
]

draw-text-at: func [
	cr			[handle!]
	text		[red-string!]
	attrs		[handle!]
	opts		[handle!]
	x			[integer!]
	y			[integer!]
	/local
		len		[integer!]
		str		[c-string!]
		layout	[handle!]
][
	cairo_save cr
	cairo_move_to cr as-float x as-float y
	len: -1
	str: unicode/to-utf8 text :len
	layout: pango_cairo_create_layout cr
	pango_layout_set_text layout str -1
	pango_layout_set_attributes layout attrs
	pango_cairo_context_set_font_options pango_layout_get_context layout opts
	pango_cairo_update_layout cr layout
	pango_cairo_show_layout cr layout
	g_object_unref layout
	cairo_restore cr
]

draw-text-box: func [
	cr			[handle!]
	pos			[red-pair!]
	tbox		[red-object!]
	catch?		[logic!]
	/local
		values	[red-value!]
		text	[red-string!]
		state	[red-block!]
		layout?	[logic!]
		bool	[red-logic!]
		clr		[integer!]
		int		[red-integer!]
		layout	[handle!]
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
	if layout? [
		clr: 0										;-- TBD
		OS-text-box-layout tbox null clr catch?
	]

	int: as red-integer! block/rs-head state
	layout: as handle! int/value
	cairo_move_to cr as-float pos/x as-float pos/y
	pango_cairo_update_layout cr layout
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
][
	ctx-matrix-adapt dc saved
	either TYPE_OF(text) = TYPE_STRING [
		draw-text-at dc/cr text dc/font-attrs dc/font-opts pos/x pos/y
	][
		draw-text-box dc/cr pos as red-object! text catch?
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
][
	cr: dc/cr
	cx: as float! center/x
	cy: as float! center/y
	rad: PI / 180.0

	radius: center + 1
	rad-x: as float! radius/x
	rad-y: as float! radius/y
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
][
	cr: dc/cr

	ctx-matrix-adapt dc saved
	if (as-integer end - start) >> 4 = 3    ; four input points
	[
		cairo_move_to cr as-float start/x
						  as-float start/y
		start: start + 1
	]

	p2: start + 1
	p3: start + 2
	cairo_curve_to cr as-float start/x
					   as-float start/y
					   as-float p2/x
					   as-float p2/y
					   as-float p3/x
					   as-float p3/y
	check-grad-line dc/grad-pen start start + 2
	do-draw-pen dc
	ctx-matrix-unadapt dc saved
]

OS-draw-line-join: func [
	dc			[draw-ctx!]
	style		[integer!]
][
	dc/pen-join: style
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
	dc/pen-cap: style
	cairo_set_line_cap dc/cr
		case [
			style = flat		[0]
			style = _round		[1]
			style = square		[2]
			true				[0]
		]
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
		dst		[red-image! value]
		pixbuf	[handle!]
][
	either any [
		start + 2 = end
		start + 3 = end
	][
		x: 0 y: 0 w: 0 h: 0
		image/any-resize src dst crop1 start end :x :y :w :h
		if dst/header = TYPE_NONE [exit]
		pixbuf: OS-image/to-pixbuf dst
		GDK-draw-image dc dc/cr pixbuf x y w h
		OS-image/delete dst
	][
		src.w: IMAGE_WIDTH(src/size)
		src.h: IMAGE_HEIGHT(src/size)
		either null? start [x: 0 y: 0][x: start/x y: start/y]
		unless null? crop1 [
			crop2: crop1 + 1
			crop.x: crop1/x
			crop.y: crop1/y
			crop.w: crop2/x
			crop.h: crop2/y
			if crop.x + crop.w > src.w [
				crop.w: src.w - crop.x
			]
			if crop.y + crop.h > src.h [
				crop.h: src.h - crop.y
			]
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
				w: end/x - x
				h: end/y - y
			]
			true [exit]
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
]

OS-draw-grad-pen-old: func [
	dc			[draw-ctx!]
	type		[integer!]
	mode		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
	/local
		w		[integer!]
		h		[integer!]
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
][
	int: as red-integer! offset + 1
	w: int/value
	int: int + 1
	h: int/value

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
	case [
		type = linear [
			grad/offset-on?: on
			grad/offset/x: offset/x + w
			grad/offset/y: offset/y + w
			grad/offset2/x: offset/x + h
			grad/offset2/y: offset/y + w
		]
		type = radial [
			grad/offset-on?: on
			grad/offset/x: offset/x
			grad/offset/y: offset/y
			grad/offset2/x: w					;-- smaller radius
			grad/offset2/y: h					;-- bigger radius
			grad/focal-on?: on
			grad/focal/x: offset/x + w
			grad/focal/y: offset/y + w
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
		color/value: clr/array1
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
				grad/offset/x: point/x
				grad/offset/y: point/y
				point: point + 1
				grad/offset2/x: point/x
				grad/offset2/y: point/y
			]
		]
		type = radial [
			either skip-pos? [
				grad/offset-on?: off
			][
				grad/offset-on?: on
				point: as red-pair! positions
				grad/offset/x: point/x
				grad/offset/y: point/y
				p: get-float as red-integer! point + 1
				grad/offset2/x: 0
				grad/offset2/y: as integer! p
				if focal? [
					grad/focal-on?: on
					point: point + 2
					grad/focal/x: point/x
					grad/focal/y: point/y
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
		color/value: clr/array1
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
][
	cr: dc/cr
	rad: PI / 180.0 * get-float angle
	either pen-fill = -1 [
		either TYPE_OF(center) = TYPE_PAIR [
			either dc/matrix-order = MATRIX-APPEND [
				cx: as float! 0 - center/x
				cy: as float! 0 - center/y
			][
				cx: as float! center/x
				cy: as float! center/y
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
		]
	][
		either TYPE_OF(center) = TYPE_PAIR [
			either dc/matrix-order = MATRIX-APPEND [
				cx: as float! 0 - center/x
				cy: as float! 0 - center/y
			][
				cx: as float! center/x
				cy: as float! center/y
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
	x			[integer!]
	y			[integer!]
	/local
		grad	[gradient!]
		matrix	[cairo_matrix_t!]
][
	either pen-fill <> -1 [
		grad: either pen-fill = pen [dc/grad-pen][dc/grad-brush]
		if grad/on? [
			matrix: as cairo_matrix_t! grad/matrix
			grad/matrix-on?: on
			cairo_matrix_translate matrix 0.0 - as-float x 0.0 - as-float y
		]
	][
		cairo-matrix-translate dc/cr as-float x as-float y dc/matrix-order
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
][
	sy: sx + 1
	xv: get-float sx
	yv: either all [
		sy <= center
		TYPE_OF(sy) = TYPE_PAIR
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
		]
	][
		either TYPE_OF(center) = TYPE_PAIR [
			either dc/matrix-order = MATRIX-APPEND [
				cx: as float! 0 - center/x
				cy: as float! 0 - center/y
			][
				cx: as float! center/x
				cy: as float! center/y
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
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center
	rad: PI / 180.0 * get-float rotate
	cr: dc/cr
	if center? [
		either dc/matrix-order = MATRIX-APPEND [
			cx: as float! 0 - center/x
			cy: as float! 0 - center/y
		][
			cx: as float! center/x
			cy: as float! center/y
		]
		cairo-matrix-translate dc/cr cx cy dc/matrix-order
	]
	either dc/matrix-order = MATRIX-APPEND [
		cairo-matrix-rotate cr rad dc/matrix-order
		cairo-matrix-scale cr get-float scale get-float scale + 1 dc/matrix-order
		cairo-matrix-translate cr as float! translate/x as float! translate/y dc/matrix-order
	][
		cairo-matrix-translate cr as float! translate/x as float! translate/y dc/matrix-order
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
	copy-memory as byte-ptr! state (as byte-ptr! dc) + 4 size? draw-state!
]

OS-draw-state-pop: func [
	dc			[draw-ctx!]
	state		[draw-state!]
][
	cairo_restore dc/cr
	copy-memory (as byte-ptr! dc) + 4 as byte-ptr! state size? draw-state!
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
	m: null
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
		t		[integer!]
		x1		[integer!]
		x2		[integer!]
		y1		[integer!]
		y2		[integer!]
		saved	[cairo_matrix_t! value]
		path	[handle!]
][
	cr: dc/cr
	either rect? [
		if upper/x > lower/x [t: upper/x upper/x: lower/x lower/x: t]
		if upper/y > lower/y [t: upper/y upper/y: lower/y lower/y: t]

		x1: upper/x
		y1: upper/y
		x2: lower/x
		y2: lower/y
		ctx-matrix-adapt dc saved
		cairo_rectangle cr
			as float! x1 as float! y1
			as float! x2 - x1 as float! y2 - y1
	][
		path: cairo_copy_path dc/cr
		cairo_new_path dc/cr
		ctx-matrix-adapt dc saved
		cairo_append_path dc/cr path
	]
	cairo_set_operator cr case [
		mode = replace	 [CAIRO_OPERATOR_SOURCE]
		mode = intersect [CAIRO_OPERATOR_OVER]
		mode = union	 [CAIRO_OPERATOR_ADD]
		mode = _xor		 [CAIRO_OPERATOR_XOR]
		mode = exclude	 [CAIRO_OPERATOR_EXCLUSION]
		true			 [CAIRO_OPERATOR_OVER]
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
][
	x: as-float coord/x
	y: as-float coord/y
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
][
	until [
		x: as-float start/x
		y: as-float start/y
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
		dx		[float32!]
		dy		[float32!]
		p3y		[float32!]
		p3x		[float32!]
		p2y		[float32!]
		p2x		[float32!]
		p1y		[float32!]
		p1x		[float32!]
		pf		[float32-ptr!]
		pt		[red-pair!]
		last-x	[float!]
		last-y	[float!]
][
	pt: start + 1
	p1x: as float32! start/x
	p1y: as float32! start/y
	p2x: as float32! pt/x
	p2y: as float32! pt/y
	if num = 3 [					;-- cubic Bézier
		pt: start + 2
		p3x: as float32! pt/x
		p3y: as float32! pt/y
	]

	last-x: 0.0 last-y: 0.0
	if 1 = cairo_has_current_point dc/cr [
		cairo_get_current_point dc/cr :last-x :last-y
	]
	dx: as float32! last-x
	dy: as float32! last-y
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
			p1x: dx * 2.0 - dc/control-x
			p1y: dy * 2.0 - dc/control-y
		][
			;-- if previous command is not curve/curv/qcurve/qcurv, use current point
			p1x: dx
			p1y: dy
		]
	]

	dc/shape-curve?: yes
	either num = 3 [				;-- cubic Bézier
		cairo_curve_to dc/cr
			as float! p1x as float! p1y
			as float! p2x as float! p2y
			as float! p3x as float! p3y
		dc/control-x: p2x
		dc/control-y: p2y
	][								;-- quadratic Bézier
		cairo_curve_to dc/cr
			(2.0 / 3.0 * as float! p1x) + (1.0 / 3.0 * as float! dx)
			(2.0 / 3.0 * as float! p1y) + (1.0 / 3.0 * as float! dy)
			(2.0 / 3.0 * as float! p2x) + (1.0 / 3.0 * as float! p1x)
			(2.0 / 3.0 * as float! p2y) + (1.0 / 3.0 * as float! p1y)
			as float! p2x as float! p2y
		dc/control-x: p1x
		dc/control-y: p1y
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
][
	cr: dc/cr
	last-x: 0.0 last-y: 0.0
	if 1 = cairo_has_current_point cr [
		cairo_get_current_point cr :last-x :last-y
	]
	p1-x: as float32! last-x p1-y: as float32! last-y
	p2-x: either rel? [ p1-x + as float32! end/x ][ as float32! end/x ]
	p2-y: either rel? [ p1-y + as float32! end/y ][ as float32! end/y ]
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
	cairo_new_sub_path cr
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
		x		[integer!]
		y		[integer!]
		wrap	[integer!]
		surf	[handle!]
		cr		[handle!]
		pattern	[handle!]
		grad	[gradient!]
][
	width:  OS-image/width? img/node
	height: OS-image/height? img/node
	pixbuf: OS-image/to-pixbuf img
	either crop-1 = null [
		x: 0
		y: 0
	][
		x: crop-1/x
		y: crop-1/y
	]
	either crop-2 = null [
		width:  width - x
		height: height - y
	][
		width:  either ( x + crop-2/x ) > width [ width - x ][ crop-2/x ]
		height: either ( y + crop-2/y ) > height [ height - y ][ crop-2/y ]
	]
	wrap: CAIRO_EXTEND_REPEAT
	unless mode = null [
		wrap: symbol/resolve mode/symbol
		case [
			wrap = flip-x [ wrap: CAIRO_EXTEND_REFLECT ]
			wrap = flip-y [ wrap: CAIRO_EXTEND_REFLECT ]
			wrap = flip-xy [ wrap: CAIRO_EXTEND_REFLECT ]
			wrap = clamp [ wrap: CAIRO_EXTEND_PAD ]
			true [ wrap: CAIRO_EXTEND_NONE ]
		]
	]
	surf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 width height
	cr: cairo_create surf
	cairo_translate cr as-float 0 - x as-float 0 - y
	gdk_cairo_set_source_pixbuf cr pixbuf 0.0 0.0
	cairo_paint cr
	cairo_destroy cr
	pattern: cairo_pattern_create_for_surface surf
	cairo_surface_destroy surf

	grad: either brush? [
		dc/brush?: yes
		dc/grad-brush
	][
		dc/pen?: yes
		dc/grad-pen
	]
	cairo_pattern_set_extend pattern wrap
	grad/on?: on
	grad/type: bitmap
	grad/pattern: pattern
	grad/pattern-on?: on
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
		cr		[handle!]
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
		wrap	[integer!]
		pattern	[handle!]
		grad	[gradient!]
][
	surf: cairo_image_surface_create CAIRO_FORMAT_ARGB32 size/x size/y
	cr: cairo_create surf
	do-draw cr null block no no yes yes
	cairo_destroy cr

	either crop-1 = null [
		x: 0
		y: 0
	][
		x: crop-1/x
		y: crop-1/y
	]
	width: size/x
	height: size/y
	either crop-2 = null [
		width:  width - x
		height: height - y
	][
		width:  either ( x + crop-2/x ) > width [ width - x ][ crop-2/x ]
		height: either ( y + crop-2/y ) > height [ height - y ][ crop-2/y ]
	]
	wrap: CAIRO_EXTEND_REPEAT
	unless mode = null [
		wrap: symbol/resolve mode/symbol
		case [
			wrap = flip-x [ wrap: CAIRO_EXTEND_REFLECT ]
			wrap = flip-y [ wrap: CAIRO_EXTEND_REFLECT ]
			wrap = flip-xy [ wrap: CAIRO_EXTEND_REFLECT ]
			wrap = clamp [ wrap: CAIRO_EXTEND_PAD ]
			true [ wrap: CAIRO_EXTEND_NONE ]
		]
	]
	pattern: cairo_pattern_create_for_surface surf

	grad: either brush? [
		dc/brush?: yes
		dc/grad-brush
	][
		dc/pen?: yes
		dc/grad-pen
	]
	cairo_pattern_set_extend pattern wrap
	grad/on?: on
	grad/type: bitmap
	grad/pattern: pattern
	grad/pattern-on?: on

	cairo_surface_destroy surf
]

OS-draw-shadow: func [
	ctx		[draw-ctx!]
	offset	[red-pair!]
	blur	[integer!]
	spread	[integer!]
	color	[integer!]
	inset?	[logic!]
][0]
