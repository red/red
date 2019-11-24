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

draw-state!: alias struct! [mat [handle!]]

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

;; TODO: only used for rich-text that I think need much less than that
;; certainly create
init-draw-ctx: func [
	ctx		[draw-ctx!]
	cr		[handle!]
][
	ctx/cr:				cr
	ctx/pen-width:		1.0
	ctx/pen-style:		0
	ctx/pen-color:		0						;-- default: black
	ctx/pen-join:		miter
	ctx/pen-cap:		flat
	ctx/brush-color:	0
	ctx/font-color:		0
	ctx/pen?:			yes
	ctx/brush?:			no
	ctx/grad-pen:		null

	ctx/font-attrs:		null
	ctx/font-opts:		null
]

draw-begin: func [
	ctx			[draw-ctx!]
	cr			[handle!]
	img			[red-image!]
	on-graphic?	[logic!]
	pattern?	[logic!]
	return:		[draw-ctx!]
][
	;; DEBUG: print ["draw-begin : " on-graphic? " " pattern?  lf]
	init-draw-ctx ctx cr

	cairo_set_line_width cr 1.0
	;; DEBUG: print ["draw-begin: set-source-color black" lf]
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
]

do-draw-path: func [
	dc			[draw-ctx!]
	/local
		cr		[handle!]
][
	cr: dc/cr
	if dc/brush? [
		cairo_save cr
		either null? dc/grad-pen [
			set-source-color cr dc/brush-color
		][
			cairo_set_source cr dc/grad-pen
		]
		cairo_fill_preserve cr
		cairo_restore cr
	]
	either dc/pen? [
		cairo_stroke cr
	][
		cairo_new_path cr
	]
]

do-draw-pen: func [
	dc			[draw-ctx!]
	/local
		cr		[handle!]
][
	cr: dc/cr
	either dc/pen? [
		cairo_save cr
		unless null? dc/grad-pen [
			cairo_set_source cr dc/grad-pen
		]
		cairo_stroke cr
		cairo_restore cr
	][
		cairo_new_path cr
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
		cr		[handle!]
][
	cr: dc/cr
	cairo_move_to cr as-float point/x as-float point/y
	point: point + 1

	while [point <= end][
		cairo_line_to cr as-float point/x as-float point/y
		point: point + 1
	]
	do-draw-pen dc
]

OS-draw-pen: func [
	dc			[draw-ctx!]
	color		[integer!]									;-- 00bbggrr format
	off?		[logic!]
	alpha?		[logic!]
][
	dc/pen?: not off?
	if all [not off? dc/pen-color <> color][
		dc/pen-color: color
		dc/font-color: color
		set-source-color dc/cr color
	]
]

OS-draw-fill-pen: func [
	dc			[draw-ctx!]
	color		[integer!]									;-- 00bbggrr format
	off?		[logic!]
	alpha?		[logic!]
][
	dc/brush?: not off?
	unless null? dc/grad-pen [
		cairo_pattern_destroy dc/grad-pen
		dc/grad-pen: null
	]
	if dc/brush-color <> color [
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
	dc/pen-width: w
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
	do-draw-path dc
]

OS-draw-triangle: func [
	dc			[draw-ctx!]
	start		[red-pair!]
][
	loop 3 [
		cairo_line_to dc/cr as-float start/x as-float start/y
		start: start + 1
	]
	cairo_close_path dc/cr								;-- close the triangle
	do-draw-path dc
]

OS-draw-polygon: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
][
	until [
		cairo_line_to dc/cr as-float start/x as-float start/y
		start: start + 1
		start > end
	]
	cairo_close_path dc/cr
	do-draw-path dc
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
][
	if (as-integer end - start) >> 4 = 1 [		;-- two points input
		OS-draw-line dc start end				;-- draw a line
		exit
	]

	cr: dc/cr

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

	do-draw-path dc
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

	cairo_save cr
	cairo_translate cr as-float center/x
						as-float center/y
	cairo_scale cr as-float rad-x
					as-float rad-y
	cairo_arc cr 0.0 0.0 1.0 0.0 2.0 * pi
	cairo_restore cr
	do-draw-path dc
]

OS-draw-ellipse: func [
	dc			[draw-ctx!]
	upper		[red-pair!]
	diameter	[red-pair!]
	/local
		cr		[handle!]
		rad-x	[integer!]
		rad-y	[integer!]
][
	cr: dc/cr
	rad-x: diameter/x / 2
	rad-y: diameter/y / 2

	cairo_save cr
	cairo_translate cr as-float upper/x + rad-x
						as-float upper/y + rad-y
	cairo_scale cr as-float rad-x
					as-float rad-y
	cairo_arc cr 0.0 0.0 1.0 0.0 2.0 * pi
	cairo_restore cr
	do-draw-path dc
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
][
	either TYPE_OF(text) = TYPE_STRING [
		draw-text-at dc/cr text dc/font-attrs dc/font-opts pos/x pos/y
	][
		draw-text-box dc/cr pos as red-object! text catch?
	]
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

	closed?: angle < end

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
	cairo_restore cr
	either closed? [
		do-draw-path dc
	][
		do-draw-pen dc
	]
]

OS-draw-curve: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	/local
		cr		[handle!]
		p2		[red-pair!]
		p3		[red-pair!]
][
	cr: dc/cr

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
	do-draw-pen dc
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
	cr			[handle!]
	image		[handle!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		img		[handle!]
][
	;; DEBUG: print ["GDK-draw-image " width " handle " image lf]
	img: either width = 0 [image][gdk_pixbuf_scale_simple image width height 2]
	;; DEBUG: print ["GDK-draw-image: " x "x" y "x" width "x" height lf]
	cairo_translate cr as-float x as-float y
	gdk_cairo_set_source_pixbuf cr img 0.0 0.0
	cairo_paint cr
	cairo_translate cr as-float (0 - x) as-float (0 - y)
	if width > 0 [g_object_unref img]
]

OS-draw-image: func [
	dc			[draw-ctx!]
	image		[red-image!]
	start		[red-pair!]
	end			[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	crop1		[red-pair!]
	pattern		[red-word!]
	/local
		cr			[handle!]
		img			[int-ptr!]
		bitmap 		[integer!]
		stride 		[integer!]
		x			[integer!]
		y			[integer!]
		width		[integer!]
		height		[integer!]
		w			[float!]
		h			[float!]
		crop_x		[float!]
		crop_y		[float!]
		crop2		[red-pair!]
		crop_cr		[handle!]
		crop_surf	[handle!]
		crop_xscale	[float!]
		crop_yscale	[float!]
		format		[cairo_format_t!]
		img_w		[float!]
		img_h		[float!]
		crop_img_sx	[integer!]
		crop_img_sy	[integer!]
][
	;; DEBUG: print ["OS-draw-image" lf]
	img_w:	as float! IMAGE_WIDTH(image/size)
	img_h:	as float! IMAGE_HEIGHT(image/size)
	either null? start [x: 0 y: 0][x: start/x y: start/y]
	case [
		start = end [
			width:  as integer! img_w
			height: as integer! img_h
		]
		start + 1 = end [					;-- two control points
			width: end/x - x
			height: end/y - y
		]
		start + 2 = end [0]					;@@ TBD three control points
		true [0]							;@@ TBD four control points
	]
	cr: dc/cr
	;; DEBUG: print ["OS-draw-image: " x "x" y " " width "x" height lf "image: " image lf "original: " IMAGE_WIDTH(image/size) "x" IMAGE_HEIGHT(image/size)  lf]

	img: OS-image/to-pixbuf image

	either crop1 <> null [
		;; DEBUG: print ["crop1: " crop1/x "x" crop1/y lf]
		crop_x: as float! crop1/x
		crop_y: as float! crop1/y
		crop2: crop1 + 1
		w: as float! crop2/x
		h: as float! crop2/y
		crop_xscale: w / (as float! width)
		crop_yscale: h / (as float! height)
		crop_img_sx: as integer! (img_w / crop_xscale)
		crop_img_sy: as integer! (img_h / crop_yscale)
		;width: as-integer (w / h * (as float! height))
		;; DEBUG: print ["cropping dest: " crop_x "x" crop_y "x" w "x" h " img size: " crop_img_sx "x" crop_img_sy lf]
		img: gdk_pixbuf_scale_simple img crop_img_sx crop_img_sy 2
		format: CAIRO_FORMAT_RGB24 ;either 3 = gdk_pixbuf_get_n_channels img [CAIRO_FORMAT_RGB24][CAIRO_FORMAT_ARGB32]
		;; DEBÙG: print ["pixbuf format: " format lf]
		crop_surf: cairo_image_surface_create format crop_img_sx crop_img_sy
		crop_cr: cairo_create crop_surf
    	gdk_cairo_set_source_pixbuf crop_cr img 0.0 0.0
		cairo_paint crop_cr
		cairo_destroy crop_cr

		cairo_save cr
		cairo_translate cr as-float x as-float y
		cairo_set_source_surface cr crop_surf (0.0 - (crop_x / crop_xscale)) (0.0 - (crop_y / crop_yscale))
		cairo_rectangle cr 0.0 0.0 as float! width as float! height
		cairo_fill cr
		cairo_translate cr as-float (0 - x) as-float (0 - y)
		cairo_restore cr

		cairo_surface_destroy crop_surf
		g_object_unref img
	][
		GDK-draw-image cr img x y width height
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
		x		[float!]
		y		[float!]
		start	[float!]
		stop	[float!]
		pattern	[handle!]
		int		[red-integer!]
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		n		[integer!]
		delta	[float!]
		p		[float!]
		angle	[float!]
		rotate?	[logic!]
		scale?	[logic!]
		matrix	[cairo_matrix_t! value]
][
	x: as-float offset/x
	y: as-float offset/y

	int: as red-integer! offset + 1
	start: as-float int/value
	int: int + 1
	stop: as-float int/value

	pattern: either type = linear [
		cairo_pattern_create_linear x + start y x + stop y
	][
		cairo_pattern_create_radial x y start x y stop
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
	cairo_matrix_init matrix 1.0 0.0 0.0 1.0 0.0 0.0
	if rotate? [
		p:  PI / 180.0
		cairo_matrix_rotate matrix p * angle
	]
	if scale? [
		cairo_matrix_scale matrix x y
	]
	cairo_matrix_invert matrix
	cairo_pattern_set_matrix pattern matrix

	delta: as-float count - 1
	delta: 1.0 / delta
	p: 0.0
	head: as red-value! int
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		next: head + 1
		n: clr/array1
		x: as-float n and FFh
		x: x / 255.0
		y: as-float n >> 8 and FFh
		y: y / 255.0
		start: as-float n >> 16 and FFh
		start: start / 255.0
		stop: as-float 255 - (n >>> 24)
		stop: stop / 255.0
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		cairo_pattern_add_color_stop_rgba pattern p x y start stop
		p: p + delta
		head: head + 1
	]

	if brush? [dc/brush?: yes]				;-- set brush, or set pen
	unless null? dc/grad-pen [cairo_pattern_destroy dc/grad-pen]
	dc/grad-pen: pattern
]

OS-draw-grad-pen: func [
	ctx			[draw-ctx!]
	type		[integer!]
	stops		[red-value!]
	count		[integer!]
	skip-pos?	[logic!]
	positions	[red-value!]
	focal?		[logic!]
	spread		[integer!]
	brush?		[logic!]
][

]

OS-matrix-rotate: func [
	dc			[draw-ctx!]
	pen			[integer!]
	angle		[red-integer!]
	center		[red-pair!]
	/local
		cr		[handle!]
		rad		[float!]
][
	cr: dc/cr
	rad: PI / 180.0 * get-float angle
	if angle <> as red-integer! center [
		cairo_translate cr as float! center/x
					   as float! center/y
	]
	cairo_rotate cr rad
	if angle <> as red-integer! center [
		cairo_translate cr as float! (0 - center/x)
					as float! (0 - center/y)
	]
]

OS-matrix-scale: func [
	dc			[draw-ctx!]
	pen			[integer!]
	sx			[red-integer!]
	sy			[red-integer!]
][
	cairo_scale dc/cr as float! get-float32 sx
					  as float! get-float32 sy
]

OS-matrix-translate: func [
	dc			[draw-ctx!]
	pen			[integer!]
	x			[integer!]
	y			[integer!]
][
	cairo_translate dc/cr as-float x
						  as-float y
]

OS-matrix-skew: func [
	dc			[draw-ctx!]
	pen			[integer!]
	sx			[red-integer!]
	sy			[red-integer!]
	/local
		m		[integer!]
		x		[float32!]
		y		[float32!]
		u		[float32!]
		z		[float32!]
][
	m: 0
	u: as float32! 1.0
	z: as float32! 0.0
	x: as float32! tan degree-to-radians get-float sx TYPE_TANGENT
	y: as float32! either sx = sy [0.0][tan degree-to-radians get-float sy TYPE_TANGENT]
]

OS-matrix-transform: func [
	dc			[draw-ctx!]
	pen			[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		rotate	[red-integer!]
		center?	[logic!]
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center

	OS-matrix-rotate dc pen rotate center
	OS-matrix-scale dc pen scale scale + 1
	OS-matrix-translate dc pen translate/x translate/y
]

OS-matrix-push: func [
	dc			[draw-ctx!]
	state		[draw-state!]
][
	cairo_save dc/cr
]

OS-matrix-pop: func [
	dc			[draw-ctx!]
	state		[draw-state!]
][
	cairo_restore dc/cr
]

OS-matrix-reset: func [
	dc			[draw-ctx!]
	pen			[integer!]
][
	cairo_identity_matrix dc/cr
]

OS-matrix-invert: func [
	dc			[draw-ctx!]
	pen			[integer!]
][]

OS-matrix-set: func [
	dc			[draw-ctx!]
	pen			[integer!]
	blk			[red-block!]
	/local
		m		[cairo_matrix_t! value]
		val		[red-integer!]
][
	m: null
	val: as red-integer! block/rs-head blk
    m/xx: get-float val
    m/yx: get-float val + 1
    m/xy: get-float val + 2
    m/yy: get-float val + 3
    m/x0: get-float val + 4
    m/y0: get-float val + 5
	cairo_transform dc/cr :m ; Weirdly it is not cairo_set_matrix because it is a global change!
]

OS-set-matrix-order: func [
	ctx			[draw-ctx!]
	order		[integer!]
][
	0
]

OS-set-clip: func [
	dc			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
][
	print ["set-clip!" lf]
	0
]

;-- shape sub command --

OS-draw-shape-beginpath: func [
	dc			[draw-ctx!]
][
]

OS-draw-shape-endpath: func [
	dc			[draw-ctx!]
	close?		[logic!]
	return:		[logic!]
][
	if close? [cairo_close_path dc/cr]
	do-draw-path dc
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
		dx		[float!]
		dy		[float!]
		p3y		[float!]
		p3x		[float!]
		p2y		[float!]
		p2x		[float!]
		p1y		[float!]
		p1x		[float!]
		pf		[float-ptr!]
		pt		[red-pair!]
][
	pt: start + 1
	p1x: as-float start/x
	p1y: as-float start/y
	p2x: as-float pt/x
	p2y: as-float pt/y
	if num = 3 [					;-- cubic Bézier
		pt: start + 2
		p3x: as-float pt/x
		p3y: as-float pt/y
	]

	; dx: dc/last-pt-x
	; dy: dc/last-pt-y
	; if rel? [
	; 	pf: :p1x
	; 	loop num [
	; 		pf/1: pf/1 + dx			;-- x
	; 		pf/2: pf/2 + dy			;-- y
	; 		pf: pf + 2
	; 	]
	; ]

	; if short? [
	; 	either dc/shape-curve? [
	; 		;-- The control point is assumed to be the reflection of the control point
	; 		;-- on the previous command relative to the current point
	; 		p1x: dx * 2.0 - dc/control-x
	; 		p1y: dy * 2.0 - dc/control-y
	; 	][
	; 		;-- if previous command is not curve/curv/qcurve/qcurv, use current point
	; 		p1x: dx
	; 		p1y: dy
	; 	]
	; ]

	dc/shape-curve?: yes
	either num = 3 [				;-- cubic Bézier
		either rel? [cairo_rel_curve_to dc/cr p1x p1y p2x p2y p3x p3y]
		[cairo_curve_to dc/cr p1x p1y p2x p2y p3x p3y]
		; dc/control-x: p2x
		; dc/control-y: p2y
		; dc/last-pt-x: p3x
		; dc/last-pt-y: p3y
	][								;-- quadratic Bézier
		;CGPathAddQuadCurveToPoint dc/path null p1x p1y p2x p2y
		; dc/control-x: p1x
		; dc/control-y: p1y
		; dc/last-pt-x: p2x
		; dc/last-pt-y: p2y
		0
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
		angle-len	[float32!]
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
][
	cr: dc/cr
	last-x: 0.0 last-y: 0.0
	if 1 = cairo_has_current_point cr[
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


	;-- transform our ellipse into the unit circle
	; m: CGAffineTransformMakeScale (as float! 1.0) / radius-x (as float! 1.0) / radius-y
	; m: CGAffineTransformRotate m (as float! 0.0) - theta
	; m: CGAffineTransformTranslate m (as float! 0.0) - center-x (as float! 0.0) - center-y

	; pt1/x: p1-x pt1/y: p1-y
	; pt2/x: p2-x pt2/y: p2-y
	; pt1: CGPointApplyAffineTransform pt1 m
	; pt2: CGPointApplyAffineTransform pt2 m

	;-- calculate angles
	cx: atan2f p1-y p1-x
	cy: atan2f p2-y p2-x
	angle-len: cy - cx
	either sweep? [
		if angle-len < as float32! 0.0 [
			angle-len: angle-len + pi2
		]
	][
		if angle-len > as float32! 0.0 [
			angle-len: angle-len - pi2
		]
	]

	;-- construct the inverse transform
	; m: CGAffineTransformMakeTranslation center-x center-y
	; m: CGAffineTransformRotate m theta
	; m: CGAffineTransformScale m radius-x radius-y
	; CGPathAddRelativeArc ctx/path :m as float32! 0.0 as float32! 0.0 as float32! 1.0 cx angle-len
	cairo_save cr
	cairo_new_sub_path cr
	cairo_translate cr as float! center-x as float! center-y
	cairo_scale     cr as float! radius-x as float! radius-y
	cairo_arc cr 0.0 0.0 1.0 as float! cx as float! cy
	cairo_restore cr
]

OS-draw-shape-close: func [
	dc			[draw-ctx!]
][
	cairo_close_path dc/cr
]

OS-draw-brush-bitmap: func [
	ctx			[draw-ctx!]
	img			[red-image!]
	crop-1		[red-pair!]
	crop-2		[red-pair!]
	mode		[red-word!]
	brush?		[logic!]
][]

OS-draw-brush-pattern: func [
	dc			[draw-ctx!]
	size		[red-pair!]
	crop-1		[red-pair!]
	crop-2		[red-pair!]
	mode		[red-word!]
	block		[red-block!]
	brush?		[logic!]
][]
