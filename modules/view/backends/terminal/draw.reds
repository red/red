Red/System [
	Title:	"DRAW Direct2D Backend"
	Author: "Xie Qingtian"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum DRAW-BRUSH-TYPE! [
	DRAW_BRUSH_NONE
	DRAW_BRUSH_COLOR
]

draw-begin: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	paint?		[logic!]
	return: 	[draw-ctx!]
][
	ctx/pen-type: DRAW_BRUSH_COLOR
	ctx/font-color?: no
	ctx/pen-color: 0
	ctx/brush-type: DRAW_BRUSH_NONE
	ctx
]

draw-end: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	paint?		[logic!]
][

]

OS-draw-shape-beginpath: func [
	ctx			[draw-ctx!]
	draw?		[logic!]
][

]

OS-draw-shape-endpath: func [
	ctx			[draw-ctx!]
	close?		[logic!]
	return:		[logic!]
][
	yes
]

OS-draw-shape-close: func [
	ctx		[draw-ctx!]
][

]

OS-draw-shape-moveto: func [
	ctx		[draw-ctx!]
	coord	[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-line: func [
	ctx			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
][

]

OS-draw-shape-axis: func [
	ctx			[draw-ctx!]
	start		[red-value!]
	end			[red-value!]
	rel?		[logic!]
	hline		[logic!]
][

]

OS-draw-shape-curve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-qcurve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-curv: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-qcurv: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][

]

OS-draw-shape-arc: func [
	ctx		[draw-ctx!]
	end		[red-pair!]
	sweep?	[logic!]
	large?	[logic!]
	rel?	[logic!]
][

]

OS-draw-anti-alias: func [
	ctx [draw-ctx!]
	on? [logic!]
][

]

draw-line: func [										;-- using Brensenham's algorithm
	ctx			[draw-ctx!]
	x0 y0 x1 y1 [integer!]
	/local
		p  [pixel!]
		pt [red-point2D!]
		dx dy sx sy err e2 [integer!]
][
	dx: x1 - x0
	if negative? dx [dx: 0 - dx]
	sx: either x0 < x1 [1][-1]
	dy: y1 - y0
	if positive? dy [dy: 0 - dy]
	sy: either y0 < y1 [1][-1]
	err: dx + dy

	forever [
		if any [x0 >= screen/width y0 >= screen/height][break]
		p: screen/buffer + (screen/width * y0 + x0)
		p/fg-color: ctx/pen-color
		p/code-point: 2588h 							;-- solid block character

		if all [x0 = x1 y0 = y1][break]
		e2: err * 2
		if e2 >= dy [
			if x0 = x1 [break]
			err: err + dy
			x0: x0 + sx
		]
		if e2 <= dx [
			if y0 = y1 [break]
			err: err + dx
			y0: y0 + sy
		]
	]
]

OS-draw-line: func [
	ctx	   [draw-ctx!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		p  [red-pair!]
		pt [red-point2D!]
		x0 y0 x1 y1 [integer!]
][
	until [
		p: point + 1
		GET_PAIR_XY_INT(point x0 y0)
		GET_PAIR_XY_INT(p   x1 y1)
		draw-line ctx x0 y0 x1 y1
		point: point + 1
		p = end
	]
]

OS-draw-line-pattern: func [
	dc			[draw-ctx!]
	start		[red-integer!]
	end			[red-integer!]
][
]

OS-draw-pen: func [
	ctx		[draw-ctx!]
	color	[integer!]
	off?	[logic!]
	alpha?	[logic!]
][
	if off? [ctx/pen-type: DRAW_BRUSH_NONE exit]

	color: make-color-256 color
	unless ctx/font-color? [ctx/font-color: color]	;-- if no font, use pen color for text color
	ctx/pen-color: color
	ctx/pen-type: DRAW_BRUSH_COLOR
]

OS-draw-fill-pen: func [
	ctx		[draw-ctx!]
	color	[integer!]
	off?	[logic!]
	alpha?	[logic!]
][
	if off? [ctx/brush-type: DRAW_BRUSH_NONE exit]

	color: make-color-256 color
	ctx/brush-color: color
	ctx/brush-type: DRAW_BRUSH_COLOR
]

OS-draw-line-width: func [
	ctx			[draw-ctx!]
	width		[red-value!]
][

]

OS-draw-box: func [
	ctx			[draw-ctx!]
	upper		[red-pair!]
	lower		[red-pair!]
	/local
		t		[integer!]
		radiusX [float32!]
		radiusY [float32!]
		radius	[red-integer!]
		w		[integer!]
		h		[integer!]
		up-x	[integer!]
		up-y	[integer!]
		low-x	[integer!]
		low-y	[integer!]
		x y		[integer!]
		min-x	[integer!]
		min-y	[integer!]
		max-x	[integer!]
		max-y	[integer!]
		pt		[red-point2D!]
		p		[pixel!]
		fg bg	[integer!]
		fill?	[logic!]
		pen?	[logic!]
][
	radius: null
	if upper + 2 = lower [
		radius: as red-integer! lower
		radiusX: get-float32 radius
		radiusY: radiusX
		lower: lower - 1
	]

	GET_PAIR_XY_INT(upper up-x up-y)
	GET_PAIR_XY_INT(lower low-x low-y)

	if up-x > low-x [t: up-x up-x: low-x low-x: t]
	if up-y > low-y [t: up-y up-y: low-y low-y: t]

	h: ctx/bottom - ctx/top
	w: ctx/right - ctx/left
	if any [
		up-x > w low-x <= 0
		up-y > h low-y <= 0
	][exit]

	up-x: up-x + ctx/x
	low-x: low-x + ctx/x
	up-y: up-y + ctx/y
	low-y: low-y + ctx/y

	min-x: up-x
	if up-x < ctx/x [min-x: ctx/x]
	if low-x >= screen/width [low-x: screen/width - 1]

	min-y: up-y
	if up-y < ctx/y [min-y: ctx/y]
	if low-y >= screen/height [low-y: screen/height - 1]

	max-x: ctx/right
	max-y: ctx/bottom

	bg: 0
	either ctx/brush-type = DRAW_BRUSH_COLOR [
		fill?: yes
		bg: ctx/brush-color
	][fill?: no]
	pen?: ctx/pen-type <> DRAW_BRUSH_NONE
	y: min-y
	while [all [y <= low-y y < max-y]][
		x: min-x
		p: screen/buffer + (screen/width * y + x)
		while [all [x <= low-x x < max-x]][
			if fill? [
				p/bg-color: bg
				p/code-point: 32		;-- space char
			]
			if pen? [
				fg: ctx/pen-color
				case [
					all [x = up-x  y = up-y ][p/code-point: 250Ch]  ;-- #"┌"
					all [x = low-x y = up-y ][p/code-point: 2510h]  ;-- #"┐"
					all [x = up-x  y = low-y][p/code-point: 2514h]  ;-- #"└"
					all [x = low-x y = low-y][p/code-point: 2518h]  ;-- #"┘"
					any [x = up-x  x = low-x][p/code-point: 2502h]  ;-- #"│"
					any [y = up-y  y = low-y][p/code-point: 2500h]  ;-- #"─"
					true [fg: p/fg-color]
				]
				p/fg-color: fg
			]
			p: p + 1
			x: x + 1
		]
		y: y + 1
	]
]

compare-refs: func [[cdecl] a [int-ptr!] b [int-ptr!] return: [integer!]][
	SIGN_COMPARE_RESULT(a/2 b/2)
]

OS-draw-triangle: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	/local
		edges p [int-ptr!]
		buf  	[pixel!]
		pt 		[red-point2D!]
		sx sy w h height i j seg f ax bx t x y [integer!]
		a b		[float!]
		half?	[logic!]
][
	edges: [0 0 0 0 0 0]
	p: edges
	loop 3 [
		GET_PAIR_XY_INT(start sx sy)
		p/1: sx
		p/2: sy
		p: p + 2
		start: start + 1
	]
	qsort as byte-ptr! edges 3 8 :compare-refs			;-- sort edges by y coordinate
	p: edges
	
	if ctx/brush-type = DRAW_BRUSH_COLOR [				;-- fill pen set
		w: screen/width
		h: screen/height
		height: p/6 - p/2
		i: 0
		while [i < height][
			half?: any [p/4 - p/2 < i  p/4 = p/2]
			seg: either half? [p/6 - p/4][p/4 - p/2]
			a: (as-float i) / as-float height
			f: either half? [p/4 - p/2][0]
			b: (as-float i - f) / as-float seg
			
			ax: p/1 + (as-integer (as-float p/5 - p/1) * a)
			bx: either half? [
				p/3 + (as-integer (as-float p/5 - p/3) * b)
			][
				p/1 + (as-integer (as-float p/3 - p/1) * b)
			]
			if ax > bx [t: ax  ax: bx  bx: t]
			j: ax
			while [j <= bx][
				x: j
				y: p/2 + i
				buf: screen/buffer + (w * y + x)
				if all [x < w  y < h x >= 0 y >= 0][
					buf/bg-color: ctx/brush-color
					buf/code-point: 32					;-- space character
				]
				j: j + 1
			]
			i: i + 1
		]
	]
	if ctx/pen-type <> DRAW_BRUSH_NONE [
		draw-line ctx p/1 p/2 p/3 p/4					;-- draw edges last
		draw-line ctx p/3 p/4 p/5 p/6
		draw-line ctx p/5 p/6 p/1 p/2
	]
]

OS-draw-polygon: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
][

]

OS-draw-spline: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	closed? [logic!]
][

]

draw-ellipse: func [									;-- using Brensenham's algorithm for ellipses (center, rx, ry)
	ctx		[draw-ctx!]
	x0		[integer!]									;-- x center
	y0		[integer!]									;-- y center
	a		[integer!]									;-- x radius
	b		[integer!]									;-- y radius
	/local
		p  [pixel!]
		pt [red-point2D!]
		w h x y -x -y r x' y' dx dy e2 a2 b2 err xc step [integer!]
		plot [subroutine!]
		pen? fill? [logic!]
][
	plot: [
		if all [pen? x' < w  y' < h x' >= 0 y' >= 0][
			p: screen/buffer + (w * y' + x')
			p/fg-color: ctx/pen-color
			p/code-point: 2588h 						;-- solid block character
		]
		if all [fill? x0 <> x'][						;-- scanline filling between x0 and the edge
			xc: x0
			step: either xc < x' [-1][1]
			x': x' + step
			p: screen/buffer + (w * y' + x')
			while [x' <> (xc + step)][
				if all [x' < w  y' < h x' >= 0 y' >= 0][
					p/bg-color: ctx/brush-color
					p/code-point: 32					;-- space character
				]
				x': x' + step
				p: p + step
			]
		]
	]
	pen?:  ctx/pen-type <> DRAW_BRUSH_NONE
	fill?: ctx/brush-type = DRAW_BRUSH_COLOR
	w: screen/width
	h: screen/height
	x: 0 - a
	y: 0
	e2: b
	dx: (x * 2 + 1) * e2 * e2
	dy: x * x
	err: dx + dy
	a2: a * a
	b2: b * b
	
	while [x <= 0][										;-- per quadrant drawing
		-x: 0 - x
		-y: 0 - y
		x': x0 - x  y': y0 + y  plot
		x': x0 + x  y': y0 + y  plot
		x': x0 + x  y': y0 - y  plot
		x': x0 - x  y': y0 - y  plot
		
		e2: err * 2
		if e2 >= dx [
			x: x + 1
			dx: dx + (b2 * 2)
			err: err + dx
		]
		if e2 <= dy [
			y: y + 1
			dy: dy + (a2 * 2)
			err: err + dy
		]
	]
	while [y: y + 1  y < b][
		x': 0  y': y  plot
		x': 0  y': 0 - y  plot
	]
]

OS-draw-circle: func [									;-- using Brensenham's algorithm for ellipses (center, rx, ry)
	ctx		[draw-ctx!]
	center	[red-pair!]
	radius	[red-integer!]
	/local
		pt [red-point2D!]
		x0 y0 r [integer!]
][
	GET_PAIR_XY_INT(center x0 y0)
	r: radius/value
	if r <= 0 [exit]
	draw-ellipse ctx x0 y0 r * 2 r						;-- double the x radius size to compensate for non-squarred pixels
]

OS-draw-ellipse: func [									;-- using Bresenham algorithm on a bounding box (top-left, bottom-right)
	ctx		 [draw-ctx!]								;-- (https://zingl.github.io/Bresenham.pdf)
	upper	 [red-pair!]
	diameter [red-pair!]
	/local
		pt [red-point2D!]
		x0 y0 a b [integer!]
][
	GET_PAIR_XY_INT(upper x0 y0)
	GET_PAIR_XY_INT(diameter a b)
	if any [a <= 0 b <= 0][exit]
	
	a: as-integer (as-float a) + 0.5 / 2.0
	b: as-integer (as-float b) + 0.5 / 2.0
	draw-ellipse ctx x0 + a y0 + b a b
]

OS-draw-font: func [
	ctx		[draw-ctx!]
	font	[red-object!]
	/local
		color	[red-tuple!]
		clr		[integer!]
][
	;-- set font color
	color: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
	either TYPE_OF(color) = TYPE_TUPLE [
		clr: get-tuple-color color
		ctx/font-color: make-color-256 clr
		ctx/font-color?: yes
	][
		ctx/font-color?: no
	]
]

OS-draw-text: func [
	ctx		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	return: [logic!]
	/local
		w		[widget!]
		x y		[integer!]
		pt		[red-point2D!]
		config	[render-config! value]
		box		[red-object!]
		para	[red-object!]
		free?	[logic!]
][
	GET_PAIR_XY_INT(pos x y)
	zero-memory as byte-ptr! :config size? render-config!
	config/align: TEXT_WRAP_FLAG
	config/flags: ctx/flags or PIXEL_ANSI_SEQ
	case [
		ctx/font-color? [config/fg-color: ctx/font-color]
		ctx/pen-type = DRAW_BRUSH_COLOR [config/fg-color: ctx/pen-color]
		true [0]
	]
	free?: no
	if TYPE_OF(text) = TYPE_OBJECT [				;-- text-box!
		box: as red-object! text
		w: as widget! face-handle? box
		if null? w [
			w: as widget! OS-make-view box null
			free?: yes
		]
		para: as red-object! (object/get-values box) + FACE_OBJ_PARA
		if TYPE_OF(para) = TYPE_OBJECT [
			config/align: get-para-flags para
		]
		config/rich-text: w/data
	]
	_widget/render-text text ctx/x + x ctx/y + y as rect! :ctx/left :config
	if free? [_widget/delete w]
	true
]

OS-draw-arc: func [
	ctx	   [draw-ctx!]
	center [red-pair!]
	end	   [red-value!]
][

]

OS-draw-curve: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
][

]

OS-draw-line-join: func [
	ctx		[draw-ctx!]
	style	[integer!]
][

]

OS-draw-line-cap: func [
	ctx		[draw-ctx!]
	style	[integer!]
][

]

OS-draw-image: func [
	ctx			[draw-ctx!]
	image		[red-image!]
	start		[red-pair!]
	end			[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	crop1		[red-pair!]
	pattern		[red-word!]
	return:		[integer!]
][
	0
]


OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	img		[red-image!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
][

]

OS-draw-brush-pattern: func [
	ctx		[draw-ctx!]
	size	[red-pair!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	block	[red-block!]
	brush?	[logic!]
][

]


OS-draw-grad-pen-old: func [
	ctx			[draw-ctx!]
	type		[integer!]
	mode		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
][

]

OS-draw-grad-pen: func [
	ctx			[draw-ctx!]
	mode		[integer!]
	stops		[red-value!]
	count		[integer!]
	skip-pos	[logic!]
	positions	[red-value!]
	focal?		[logic!]
	spread		[integer!]
	brush?		[logic!]
][

]

OS-set-clip: func [
	ctx		[draw-ctx!]
	u		[red-pair!]
	l		[red-pair!]
	rect?	[logic!]
	mode	[integer!]
][

]

OS-clip-end: func [
	ctx		[draw-ctx!]
][]

OS-matrix-rotate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	angle		[red-integer!]
	center		[red-pair!]
][

]

OS-matrix-scale: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	sx			[red-integer!]
	sy			[red-pair!]
][

]

OS-matrix-translate: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	pair		[red-pair!]
][

]

OS-matrix-skew: func [
	ctx		    [draw-ctx!]
	pen-fill    [integer!]
	sx			[red-integer!]
	sy			[red-pair!]
][

]

OS-matrix-transform: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
][
	
]

OS-draw-state-push: func [ctx [draw-ctx!] state [draw-state!]][

]

OS-draw-state-pop: func [ctx [draw-ctx!] state [draw-state!]][]

OS-matrix-reset: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
][
	
]

OS-matrix-invert: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]

][

]

OS-matrix-set: func [
	ctx			[draw-ctx!]
	pen-fill	[integer!]
	blk			[red-block!]
][
	
]

OS-set-matrix-order: func [
	ctx		[draw-ctx!]
	order	[integer!]
][

]

OS-draw-shadow: func [
	ctx		[draw-ctx!]
	offset	[red-pair!]
	blur	[integer!]
	spread	[integer!]
	color	[integer!]
	inset?	[logic!]
][0]