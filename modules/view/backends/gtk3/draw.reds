Red/System [
	Title:	"Cairo Draw dialect backend"
	Author: "Qingtian Xie"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

draw-ctx!: alias struct! [
	raw				[handle!]
	pen-join		[integer!]
	pen-cap			[integer!]
	pen-width		[integer!]
	pen-style		[integer!]
	pen-color		[integer!]					;-- 00bbggrr format
	brush-color		[integer!]					;-- 00bbggrr format
	font-color		[integer!]
	pen?			[logic!]
	brush?			[logic!]
	pattern			[handle!]
	on-image?		[logic!]					;-- drawing on image?
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
	a: as-float 255 - (color >>> 24)
	a: a / 255.0
	cairo_set_source_rgba cr r g b a
]

draw-begin: func [
	ctx			[draw-ctx!]
	cr			[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	paint?		[logic!]
	return: 	[draw-ctx!]
][
	ctx/raw:			cr
	ctx/pen-width:		1
	ctx/pen-style:		0
	ctx/pen-color:		0						;-- default: black
	ctx/pen-join:		miter
	ctx/pen-cap:		flat
	ctx/brush-color:	0
	ctx/font-color:		0
	ctx/pen?:			yes
	ctx/brush?:			no
	ctx/pattern:		null

	cairo_set_line_width cr 1.0
	set-source-color cr 0
	ctx
]

draw-end: func [
	dc			[draw-ctx!]
	hWnd		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	paint?		[logic!]
][
	0
]

do-paint: func [dc [draw-ctx!] /local cr [handle!]][
	cr: dc/raw
	if dc/brush? [
		cairo_save cr
		either null? dc/pattern [
			set-source-color cr dc/brush-color
		][
			cairo_set_source cr dc/pattern
		]
		cairo_fill_preserve cr
		cairo_restore cr
	]
	if dc/pen? [cairo_stroke cr]
]

OS-draw-anti-alias: func [
	dc	[draw-ctx!]
	on? [logic!]
][
0
]

OS-draw-line: func [
	dc	   [draw-ctx!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		cr [handle!]
][
	cr: dc/raw
	while [point <= end][
		cairo_line_to cr as-float point/x as-float point/y
		point: point + 1
	]
	cairo_stroke cr
]

OS-draw-pen: func [
	dc	   [draw-ctx!]
	color  [integer!]									;-- 00bbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	dc/pen?: not off?
	if dc/pen-color <> color [
		dc/pen-color: color
		set-source-color dc/raw color
	]
]

OS-draw-fill-pen: func [
	dc	   [draw-ctx!]
	color  [integer!]									;-- 00bbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	dc/brush?: not off?
	unless null? dc/pattern [
		cairo_pattern_destroy dc/pattern
		dc/pattern: null
	]
	if dc/brush-color <> color [
		dc/brush-color: color
	]
]

OS-draw-line-width: func [
	dc	  [draw-ctx!]
	width [red-integer!]
	/local
		w [integer!]
][
	w: width/value
	if dc/pen-width <> w [
		dc/pen-width: w
		cairo_set_line_width dc/raw as-float w
	]
]

OS-draw-box: func [
	dc	  [draw-ctx!]
	upper [red-pair!]
	lower [red-pair!]
	/local
		radius	[red-integer!]
		rad		[integer!]
		x		[float!]
		y		[float!]
		w		[float!]
		h		[float!]
][
	either TYPE_OF(lower) = TYPE_INTEGER [
		radius: as red-integer! lower
		lower:  lower - 1
		rad: radius/value * 2
		;;@@ TBD round box
	][
		x: as-float upper/x
		y: as-float upper/y
		w: as-float lower/x - upper/x
		h: as-float lower/y - upper/y
		cairo_rectangle dc/raw x y w h
		do-paint dc
	]
]

OS-draw-triangle: func [
	dc	  [draw-ctx!]
	start [red-pair!]
][
	loop 3 [
		cairo_line_to dc/raw as-float start/x as-float start/y
		start: start + 1
	]
	cairo_close_path dc/raw								;-- close the triangle
	do-paint dc
]

OS-draw-polygon: func [
	dc	  [draw-ctx!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		nb	  [integer!]
][
0
]

OS-draw-spline: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	closed? [logic!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		nb	  [integer!]
][
0
]

do-draw-ellipse: func [
	dc		[draw-ctx!]
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
][
0
]

OS-draw-circle: func [
	dc	   [draw-ctx!]
	center [red-pair!]
	radius [red-integer!]
	/local
		x [float!]
		y [float!]
][
	x: as-float center/x
	y: as-float center/y
	cairo_arc dc/raw x y as-float radius/value 0.0 2.0 * pi
	do-paint dc
]

OS-draw-ellipse: func [
	dc	  	 [draw-ctx!]
	upper	 [red-pair!]
	diameter [red-pair!]
][
0
]

OS-draw-font: func [
	dc		[draw-ctx!]
	font	[red-object!]
	/local
		vals  [red-value!]
		state [red-block!]
		int   [red-integer!]
		color [red-tuple!]
		hFont [draw-ctx!]
][
0
]

OS-draw-text: func [
	dc		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	/local
		str		[c-string!]
		len		[integer!]
][
0
]

OS-draw-arc: func [
	dc	   [draw-ctx!]
	center [red-pair!]
	end	   [red-value!]
	/local
		radius		[red-pair!]
		angle		[red-integer!]
		rad-x		[integer!]
		rad-y		[integer!]
		start-x		[integer!]
		start-y 	[integer!]
		end-x		[integer!]
		end-y		[integer!]
		angle-begin [float!]
		angle-len	[float!]
		rad-x-float	[float!]
		rad-y-float	[float!]
		rad-x-2		[float!]
		rad-y-2		[float!]
		rad-x-y		[float!]
		tan-2		[float!]
		closed?		[logic!]
][
0
]

OS-draw-curve: func [
	dc	  [draw-ctx!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		pair  [red-pair!]
		point [tagPOINT]
		p2	  [red-pair!]
		p3	  [red-pair!]
		nb	  [integer!]
		count [integer!]
][
0
]

OS-draw-line-join: func [
	dc	  [draw-ctx!]
	style [integer!]
	/local
		mode [integer!]
][
	if dc/pen-join <> style [
		dc/pen-join: style
	]
]
	
OS-draw-line-cap: func [
	dc	  [draw-ctx!]
	style [integer!]
	/local
		mode [integer!]
][
	if dc/pen-cap <> style [
		dc/pen-cap: style
	]
]

OS-draw-image: func [
	dc			[draw-ctx!]
	image		[red-image!]
	start		[red-pair!]
	end			[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	pattern		[red-word!]
	/local
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
][
0
]

OS-draw-grad-pen: func [
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
		scale?	[logic!]
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
			0	[0]					;-- rotation
			1	[x:	p scale?: yes]
			2	[y:	p]
		]
		n: n + 1
	]

	if scale? [0]

	delta: 1.0 / as-float count - 1
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
	unless null? dc/pattern [cairo_pattern_destroy dc/pattern]
	dc/pattern: pattern
]

OS-matrix-rotate: func [
	dc		[draw-ctx!]
	angle	[red-integer!]
	center	[red-pair!]
	/local
		m	[integer!]
		pts [tagPOINT]
][
	if angle <> as red-integer! center [
0
	]
	;GdipRotateWorldTransform dc/graphics get-float32 angle GDIPLUS_MATRIXORDERAPPEND
	if angle <> as red-integer! center [
0
	]
]

OS-matrix-scale: func [
	dc		[draw-ctx!]
	sx		[red-integer!]
	sy		[red-integer!]
][
0
]

OS-matrix-translate: func [
	ctx [handle!]
	x	[integer!]
	y	[integer!]
][
0
]

OS-matrix-skew: func [
	dc		[draw-ctx!]
	sx		[red-integer!]
	sy		[red-integer!]
	/local
		m	[integer!]
		x	[float32!]
		y	[float32!]
		u	[float32!]
		z	[float32!]
][
	m: 0
	u: as float32! 1.0
	z: as float32! 0.0
	x: as float32! _tan degree-to-radians get-float sx TYPE_TANGENT
	y: as float32! either sx = sy [0.0][_tan degree-to-radians get-float sy TYPE_TANGENT]
]

OS-matrix-transform: func [
	dc			[draw-ctx!]
	rotate		[red-integer!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		center	[red-pair!]
][
	center: as red-pair! either rotate + 1 = scale [rotate][rotate + 1]
	OS-matrix-rotate dc rotate center
	OS-matrix-scale dc scale scale + 1
	OS-matrix-translate dc/raw translate/x translate/y
]

OS-matrix-push: func [dc [draw-ctx!] /local state [integer!]][
	state: 0
]

OS-matrix-pop: func [dc [draw-ctx!]][0]

OS-matrix-reset: func [dc [draw-ctx!]][0]

OS-matrix-invert: func [dc [draw-ctx!] /local m [integer!]][
0
]

OS-matrix-set: func [
	dc		[draw-ctx!]
	blk		[red-block!]
	/local
		m	[integer!]
		val [red-integer!]
][
	m: 0
	val: as red-integer! block/rs-head blk
]

OS-set-clip: func [
	upper	[red-pair!]
	lower	[red-pair!]
][
]

;-- shape sub command --

OS-draw-shape-beginpath: func [
    dc          [draw-ctx!]
    /local
        path    [integer!]
][

]

OS-draw-shape-endpath: func [
    dc          [draw-ctx!]
    close?      [logic!]
    return:     [logic!]
    /local
        alpha   [byte!]
][
	true
]

OS-draw-shape-moveto: func [
    dc      [draw-ctx!]
    coord   [red-pair!]
    rel?    [logic!]
][
	
]

OS-draw-shape-line: func [
    dc          [draw-ctx!]
    start       [red-pair!]
    end         [red-pair!]
    rel?        [logic!]
][

]

OS-draw-shape-axis: func [
    dc          [draw-ctx!]
    start       [red-integer!]
    end         [red-integer!]
    rel?        [logic!]
    hline       [logic!]
][
	
]

OS-draw-shape-curve: func [
    dc      [draw-ctx!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
]

OS-draw-shape-qcurve: func [
    dc      [draw-ctx!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    ;draw-curves dc start end rel? 2
]

OS-draw-shape-curv: func [
    dc      [draw-ctx!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    ;draw-short-curves dc start end rel? 2
]

OS-draw-shape-qcurv: func [
    dc      [draw-ctx!]
    start   [red-pair!]
    end     [red-pair!]
    rel?    [logic!]
][
    ;draw-short-curves dc start end rel? 1
]

OS-draw-shape-arc: func [
    dc      [draw-ctx!]
    start   [red-pair!]
    end     [red-integer!]
    sweep?  [logic!]
    large?  [logic!]
    rel?    [logic!]
][
	
]