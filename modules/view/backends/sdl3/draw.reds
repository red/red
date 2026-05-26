Red/System [
	Title:	"SDL3 Draw dialect backend"
	File: 	%draw.reds
	Tabs: 	4
]

#enum DRAW-BRUSH-TYPE! [
	DRAW_BRUSH_NONE
	DRAW_BRUSH_COLOR
]

draw-state!: alias struct! [
	pen-type	[integer!]
	pen-color	[integer!]
	brush-color	[integer!]
	brush-type	[integer!]
	line-width	[integer!]
]

sdl3-poly-xs: declare int-ptr!
sdl3-poly-xs: null
sdl3-clip-stack: declare int-ptr!
sdl3-clip-stack: null
sdl3-clip-depth: 0
sdl3-clip-active?: no
sdl3-clip-x: 0
sdl3-clip-y: 0
sdl3-clip-w: 0
sdl3-clip-h: 0

draw-set-color: func [
	renderer [handle!]
	color	 [integer!]
][
	SDL_SetRenderDrawColor
		renderer
		as byte! (color and FFh)
		as byte! ((color >>> 8) and FFh)
		as byte! ((color >>> 16) and FFh)
		as byte! either color and FF000000h = 0 [255][(color >>> 24) and FFh]
]

draw-line-xy: func [
	ctx	[draw-ctx!]
	x1	[integer!]
	y1	[integer!]
	x2	[integer!]
	y2	[integer!]
	/local
		dx dy half i [integer!]
][
	if ctx/pen-type = DRAW_BRUSH_NONE [exit]
	draw-set-color ctx/dc ctx/pen-color
	either ctx/line-width <= 1 [
		SDL_RenderLine ctx/dc as float32! ctx/x + x1 as float32! ctx/y + y1 as float32! ctx/x + x2 as float32! ctx/y + y2
	][
		dx: x2 - x1
		if dx < 0 [dx: 0 - dx]
		dy: y2 - y1
		if dy < 0 [dy: 0 - dy]
		half: ctx/line-width / 2
		i: 0 - half
		either dx >= dy [
			while [i <= half][
				SDL_RenderLine ctx/dc as float32! ctx/x + x1 as float32! ctx/y + y1 + i as float32! ctx/x + x2 as float32! ctx/y + y2 + i
				i: i + 1
			]
		][
			while [i <= half][
				SDL_RenderLine ctx/dc as float32! ctx/x + x1 + i as float32! ctx/y + y1 as float32! ctx/x + x2 + i as float32! ctx/y + y2
				i: i + 1
			]
		]
	]
]

draw-line-color: func [
	ctx		[draw-ctx!]
	x1		[integer!]
	y1		[integer!]
	x2		[integer!]
	y2		[integer!]
	color	[integer!]
][
	draw-set-color ctx/dc color
	SDL_RenderLine ctx/dc as float32! ctx/x + x1 as float32! ctx/y + y1 as float32! ctx/x + x2 as float32! ctx/y + y2
]

draw-rect-fill: func [
	ctx		[draw-ctx!]
	x		[integer!]
	y		[integer!]
	w		[integer!]
	h		[integer!]
	color	[integer!]
	/local
		r [SDL_FRect!]
][
	if any [w <= 0 h <= 0][exit]
	r: declare SDL_FRect!
	r/x: as float32! ctx/x + x
	r/y: as float32! ctx/y + y
	r/w: as float32! w
	r/h: as float32! h
	draw-set-color ctx/dc color
	SDL_RenderFillRect ctx/dc r
]

draw-rect-border: func [
	ctx	[draw-ctx!]
	x	[integer!]
	y	[integer!]
	w	[integer!]
	h	[integer!]
][
	draw-line-xy ctx x y x + w - 1 y
	draw-line-xy ctx x y x y + h - 1
	draw-line-xy ctx x + w - 1 y x + w - 1 y + h - 1
	draw-line-xy ctx x y + h - 1 x + w - 1 y + h - 1
]

draw-apply-clip: func [
	ctx [draw-ctx!]
	/local
		r [SDL_Rect!]
][
	either sdl3-clip-active? [
		r: declare SDL_Rect!
		r/x: ctx/x + sdl3-clip-x
		r/y: ctx/y + sdl3-clip-y
		r/w: sdl3-clip-w
		r/h: sdl3-clip-h
		SDL_SetRenderClipRect ctx/dc as int-ptr! r
	][
		SDL_SetRenderClipRect ctx/dc null
	]
]

draw-push-clip: func [
	/local
		slot [int-ptr!]
][
	if sdl3-clip-stack = null [sdl3-clip-stack: as int-ptr! allocate 2048]
	if any [sdl3-clip-stack = null sdl3-clip-depth >= 100][exit]
	slot: sdl3-clip-stack + (sdl3-clip-depth * 5)
	slot/1: either sdl3-clip-active? [1][0]
	slot/2: sdl3-clip-x
	slot/3: sdl3-clip-y
	slot/4: sdl3-clip-w
	slot/5: sdl3-clip-h
	sdl3-clip-depth: sdl3-clip-depth + 1
]

draw-pop-clip: func [
	ctx [draw-ctx!]
	/local
		slot [int-ptr!]
][
	if any [sdl3-clip-stack = null sdl3-clip-depth <= 0][
		sdl3-clip-active?: no
		draw-apply-clip ctx
		exit
	]
	sdl3-clip-depth: sdl3-clip-depth - 1
	slot: sdl3-clip-stack + (sdl3-clip-depth * 5)
	sdl3-clip-active?: slot/1 <> 0
	sdl3-clip-x: slot/2
	sdl3-clip-y: slot/3
	sdl3-clip-w: slot/4
	sdl3-clip-h: slot/5
	draw-apply-clip ctx
]

draw-set-clip-rect: func [
	ctx [draw-ctx!]
	x	[integer!]
	y	[integer!]
	w	[integer!]
	h	[integer!]
][
	if w < 0 [x: x + w w: 0 - w]
	if h < 0 [y: y + h h: 0 - h]
	if any [w <= 0 h <= 0][
		sdl3-clip-active?: no
		draw-apply-clip ctx
		exit
	]
	sdl3-clip-active?: yes
	sdl3-clip-x: x
	sdl3-clip-y: y
	sdl3-clip-w: w
	sdl3-clip-h: h
	draw-apply-clip ctx
]

draw-clear-clip: func [
	ctx [draw-ctx!]
][
	sdl3-clip-depth: 0
	sdl3-clip-active?: no
	draw-apply-clip ctx
]

draw-image-rect: func [
	ctx	[draw-ctx!]
	img	[red-image!]
	x	[integer!]
	y	[integer!]
	w	[integer!]
	h	[integer!]
	/local
		iw		[integer!]
		ih		[integer!]
		bitmap	[integer!]
		stride	[integer!]
		pixels	[int-ptr!]
		texture [handle!]
		dst		[SDL_FRect!]
][
	if any [img = null TYPE_OF(img) <> TYPE_IMAGE w <= 0 h <= 0][exit]
	iw: IMAGE_WIDTH(img/size)
	ih: IMAGE_HEIGHT(img/size)
	if any [iw <= 0 ih <= 0][exit]
	bitmap: OS-image/lock-bitmap img no
	if bitmap = 0 [exit]
	stride: 0
	pixels: OS-image/get-data bitmap :stride
	either pixels = null [
		OS-image/unlock-bitmap img bitmap
	][
		texture: SDL_CreateTexture ctx/dc SDL_PIXELFORMAT_ARGB8888 SDL_TEXTUREACCESS_STATIC iw ih
		either texture = null [
			OS-image/unlock-bitmap img bitmap
		][
			SDL_SetTextureBlendMode texture SDL_BLENDMODE_BLEND
			if SDL_UpdateTexture texture null pixels stride [
				dst: declare SDL_FRect!
				dst/x: as float32! ctx/x + x
				dst/y: as float32! ctx/y + y
				dst/w: as float32! w
				dst/h: as float32! h
				SDL_RenderTexture ctx/dc texture null as int-ptr! dst
			]
			SDL_DestroyTexture texture
			OS-image/unlock-bitmap img bitmap
		]
	]
]

draw-begin: func [
	ctx			[draw-ctx!]
	hWnd		[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	paint?		[logic!]
	return: 	[draw-ctx!]
][
	ctx/dc: hWnd
	ctx/x: 0
	ctx/y: 0
	ctx/left: 0
	ctx/top: 0
	ctx/right: 0
	ctx/bottom: 0
	ctx/pen-type: DRAW_BRUSH_COLOR
	ctx/pen-color: 0
	ctx/brush-type: DRAW_BRUSH_NONE
	ctx/brush-color: 00FFFFFFh
	ctx/line-width: 1
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
OS-draw-shape-beginpath: func [ctx [draw-ctx!] draw? [logic!]][]
OS-draw-shape-endpath: func [ctx [draw-ctx!] close? [logic!] return: [logic!]][true]
OS-draw-shape-close: func [ctx [draw-ctx!]][]
OS-draw-shape-moveto: func [ctx [draw-ctx!] coord [red-pair!] rel? [logic!]][]
OS-draw-shape-line: func [ctx [draw-ctx!] start [red-pair!] end [red-pair!] rel? [logic!]][]
OS-draw-shape-axis: func [ctx [draw-ctx!] start [red-value!] end [red-value!] rel? [logic!] hline [logic!]][]
OS-draw-shape-curve: func [ctx [draw-ctx!] start [red-pair!] end [red-pair!] rel? [logic!]][]
OS-draw-shape-qcurve: func [ctx [draw-ctx!] start [red-pair!] end [red-pair!] rel? [logic!]][]
OS-draw-shape-curv: func [ctx [draw-ctx!] start [red-pair!] end [red-pair!] rel? [logic!]][]
OS-draw-shape-qcurv: func [ctx [draw-ctx!] start [red-pair!] end [red-pair!] rel? [logic!]][]
OS-draw-shape-arc: func [ctx [draw-ctx!] end [red-pair!] sweep? [logic!] large? [logic!] rel? [logic!]][]
OS-draw-anti-alias: func [ctx [draw-ctx!] on? [logic!]][]
OS-draw-line: func [
	ctx	  [draw-ctx!]
	point [red-pair!]
	end	  [red-pair!]
	/local
		p [red-pair!]
		pt [red-point2D!]
		x1 y1 x2 y2 [integer!]
][
	until [
		p: point + 1
		GET_PAIR_XY_INT(point x1 y1)
		GET_PAIR_XY_INT(p x2 y2)
		draw-line-xy ctx x1 y1 x2 y2
		point: point + 1
		p = end
	]
]
OS-draw-pen: func [ctx [draw-ctx!] color [integer!] off? [logic!] alpha? [logic!]][
	if off? [ctx/pen-type: DRAW_BRUSH_NONE exit]
	ctx/pen-color: color
	ctx/pen-type: DRAW_BRUSH_COLOR
]
OS-draw-fill-pen: func [ctx [draw-ctx!] color [integer!] off? [logic!] alpha? [logic!]][
	if off? [ctx/brush-type: DRAW_BRUSH_NONE exit]
	ctx/brush-color: color
	ctx/brush-type: DRAW_BRUSH_COLOR
]
OS-draw-line-width: func [
	ctx	  [draw-ctx!]
	width [red-value!]
	/local
		int [red-integer!]
		flt [red-float!]
][
	ctx/line-width: 1
	switch TYPE_OF(width) [
		TYPE_INTEGER [
			int: as red-integer! width
			ctx/line-width: int/value
		]
		TYPE_FLOAT [
			flt: as red-float! width
			ctx/line-width: as-integer flt/value
		]
		default [0]
	]
	if ctx/line-width < 1 [ctx/line-width: 1]
]
OS-draw-box: func [
	ctx	  [draw-ctx!]
	upper [red-pair!]
	lower [red-pair!]
	/local
		pt [red-point2D!]
		x1 y1 x2 y2 w h [integer!]
][
	GET_PAIR_XY_INT(upper x1 y1)
	GET_PAIR_XY_INT(lower x2 y2)
	w: x2 - x1
	h: y2 - y1
	if ctx/brush-type = DRAW_BRUSH_COLOR [draw-rect-fill ctx x1 y1 w h ctx/brush-color]
	if ctx/pen-type <> DRAW_BRUSH_NONE [draw-rect-border ctx x1 y1 w h]
]
sort-poly-xs: func [
	count [integer!]
	/local
		i j t limit inner-limit [integer!]
		a b [int-ptr!]
][
	i: 0
	limit: count - 1
	while [i < limit][
		j: 0
		a: sdl3-poly-xs
		inner-limit: count - i - 1
		while [j < inner-limit][
			b: a + 1
			if a/1 > b/1 [
				t: a/1
				a/1: b/1
				b/1: t
			]
			a: a + 1
			j: j + 1
		]
		i: i + 1
	]
]

draw-polygon-fill: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	color	[integer!]
	/local
		p q [red-pair!]
		pt [red-point2D!]
		x1 y1 x2 y2 [integer!]
		min-y max-y y n x t i [integer!]
		xs [int-ptr!]
][
	if sdl3-poly-xs = null [sdl3-poly-xs: as int-ptr! allocate 4096]
	if sdl3-poly-xs = null [exit]

	GET_PAIR_XY_INT(start min-y max-y)
	min-y: max-y
	p: start
	while [p <= end][
		GET_PAIR_XY_INT(p x1 y1)
		if y1 < min-y [min-y: y1]
		if y1 > max-y [max-y: y1]
		p: p + 1
	]

	y: min-y
	while [y <= max-y][
		n: 0
		p: start
		while [p <= end][
			q: either p = end [start][p + 1]
			GET_PAIR_XY_INT(p x1 y1)
			GET_PAIR_XY_INT(q x2 y2)
			if any [all [y1 <= y y2 > y] all [y2 <= y y1 > y]][
				x: x1 + ((y - y1) * (x2 - x1) / (y2 - y1))
				if n < 1024 [
					xs: sdl3-poly-xs + n
					xs/1: x
					n: n + 1
				]
			]
			p: p + 1
		]
		if n > 1 [
			sort-poly-xs n
			i: 0
			xs: sdl3-poly-xs
			while [i + 1 < n][
				x1: xs/1
				xs: xs + 1
				x2: xs/1
				if x1 > x2 [
					t: x1
					x1: x2
					x2: t
				]
				draw-line-color ctx x1 y x2 y color
				xs: xs + 1
				i: i + 2
			]
		]
		y: y + 1
	]
]

OS-draw-triangle: func [ctx [draw-ctx!] start [red-pair!]][
	OS-draw-polygon ctx start start + 2
]
OS-draw-polygon: func [
	ctx	  [draw-ctx!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		p [red-pair!]
		q [red-pair!]
	first [red-pair!]
	pt [red-point2D!]
	x1 y1 x2 y2 [integer!]
][
	if ctx/brush-type = DRAW_BRUSH_COLOR [draw-polygon-fill ctx start end ctx/brush-color]

	if ctx/pen-type = DRAW_BRUSH_NONE [exit]
	first: start
	p: start
	while [p < end][
		q: p + 1
		GET_PAIR_XY_INT(p x1 y1)
		GET_PAIR_XY_INT(q x2 y2)
		draw-line-xy ctx x1 y1 x2 y2
		p: p + 1
	]
	GET_PAIR_XY_INT(end x1 y1)
	GET_PAIR_XY_INT(first x2 y2)
	draw-line-xy ctx x1 y1 x2 y2
]
draw-spline-step: func [
	ctx [draw-ctx!]
	p0	[red-pair!]
	p1	[red-pair!]
	p2	[red-pair!]
	p3	[red-pair!]
	/local
		pt [red-point2D!]
		p0x p0y p1x p1y p2x p2y p3x p3y [float32!]
		t t2 t3 delta xf yf [float32!]
		last-x last-y next-x next-y [integer!]
][
	if ctx/pen-type = DRAW_BRUSH_NONE [exit]
	GET_PAIR_XY(p0 p0x p0y)
	GET_PAIR_XY(p1 p1x p1y)
	GET_PAIR_XY(p2 p2x p2y)
	GET_PAIR_XY(p3 p3x p3y)
	last-x: as-integer p1x
	last-y: as-integer p1y
	t: as float32! 0.0
	delta: as float32! 0.04
	loop 25 [
		t: t + delta
		t2: t * t
		t3: t2 * t
		xf: (
			(as float32! 2.0 * p1x)
			+ ((p2x - p0x) * t)
			+ (((as float32! 2.0 * p0x) - (as float32! 5.0 * p1x) + (as float32! 4.0 * p2x) - p3x) * t2)
			+ (((as float32! 0.0 - p0x) + (as float32! 3.0 * p1x) - (as float32! 3.0 * p2x) + p3x) * t3)
		) * as float32! 0.5
		yf: (
			(as float32! 2.0 * p1y)
			+ ((p2y - p0y) * t)
			+ (((as float32! 2.0 * p0y) - (as float32! 5.0 * p1y) + (as float32! 4.0 * p2y) - p3y) * t2)
			+ (((as float32! 0.0 - p0y) + (as float32! 3.0 * p1y) - (as float32! 3.0 * p2y) + p3y) * t3)
		) * as float32! 0.5
		next-x: as-integer xf
		next-y: as-integer yf
		draw-line-xy ctx last-x last-y next-x next-y
		last-x: next-x
		last-y: next-y
	]
]

OS-draw-spline: func [
	ctx		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	closed? [logic!]
	/local
		p stop [red-pair!]
][
	if ((as-integer end - start) >> 4) = 1 [
		OS-draw-line ctx start end
		exit
	]

	either closed? [
		draw-spline-step ctx end start start + 1 start + 2
	][
		draw-spline-step ctx start start start + 1 start + 2
	]

	p: start
	stop: end - 3
	while [p <= stop][
		draw-spline-step ctx p p + 1 p + 2 p + 3
		p: p + 1
	]

	either closed? [
		draw-spline-step ctx end - 2 end - 1 end start
		draw-spline-step ctx end - 1 end start start + 1
	][
		draw-spline-step ctx end - 2 end - 1 end end
	]
]
draw-ellipse-spans: func [
	ctx		[draw-ctx!]
	cx		[integer!]
	cy		[integer!]
	x		[integer!]
	y		[integer!]
	color	[integer!]
][
	draw-line-color ctx cx - x cy + y cx + x cy + y color
	if y <> 0 [draw-line-color ctx cx - x cy - y cx + x cy - y color]
]

draw-ellipse-points: func [
	ctx		[draw-ctx!]
	cx		[integer!]
	cy		[integer!]
	x		[integer!]
	y		[integer!]
	color	[integer!]
][
	draw-line-color ctx cx + x cy + y cx + x cy + y color
	if x <> 0 [draw-line-color ctx cx - x cy + y cx - x cy + y color]
	if y <> 0 [
		draw-line-color ctx cx + x cy - y cx + x cy - y color
		if x <> 0 [draw-line-color ctx cx - x cy - y cx - x cy - y color]
	]
]

draw-ellipse-pass: func [
	ctx		[draw-ctx!]
	cx		[integer!]
	cy		[integer!]
	rx		[integer!]
	ry		[integer!]
	fill?	[logic!]
	color	[integer!]
	/local
		x y [integer!]
		rx2 ry2 [integer!]
		two-rx2 two-ry2 [integer!]
		px py [integer!]
		p [integer!]
][
	if any [rx < 0 ry < 0][exit]
	either rx = 0 [
		draw-line-color ctx cx cy - ry cx cy + ry color
	][
		either ry = 0 [
			draw-line-color ctx cx - rx cy cx + rx cy color
		][
			x: 0
			y: ry
			rx2: rx * rx
			ry2: ry * ry
			two-rx2: rx2 * 2
			two-ry2: ry2 * 2
			px: 0
			py: two-rx2 * y
			p: ry2 - (rx2 * ry) + (rx2 / 4)
			while [px < py][
				either fill? [
					draw-ellipse-spans ctx cx cy x y color
				][
					draw-ellipse-points ctx cx cy x y color
				]
				x: x + 1
				px: px + two-ry2
				either p < 0 [
					p: p + ry2 + px
				][
					y: y - 1
					py: py - two-rx2
					p: p + ry2 + px - py
				]
			]
			p: (ry2 * (x * x + x)) + (ry2 / 4) + (rx2 * ((y - 1) * (y - 1))) - (rx2 * ry2)
			while [y >= 0][
				either fill? [
					draw-ellipse-spans ctx cx cy x y color
				][
					draw-ellipse-points ctx cx cy x y color
				]
				y: y - 1
				py: py - two-rx2
				either p > 0 [
					p: p + rx2 - py
				][
					x: x + 1
					px: px + two-ry2
					p: p + rx2 - py + px
				]
			]
		]
	]
]

do-draw-ellipse: func [
	ctx		[draw-ctx!]
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
	/local
		rx ry cx cy [integer!]
][
	if width < 0 [x: x + width width: 0 - width]
	if height < 0 [y: y + height height: 0 - height]
	if any [width <= 0 height <= 0][exit]

	rx: width / 2
	ry: height / 2
	cx: x + rx
	cy: y + ry

	if ctx/brush-type = DRAW_BRUSH_COLOR [draw-ellipse-pass ctx cx cy rx ry yes ctx/brush-color]
	if ctx/pen-type <> DRAW_BRUSH_NONE [draw-ellipse-pass ctx cx cy rx ry no ctx/pen-color]
]
OS-draw-circle: func [
	ctx	   [draw-ctx!]
	center [red-pair!]
	radius [red-integer!]
	/local
		pt [red-point2D!]
		x y r [integer!]
][
	GET_PAIR_XY_INT(center x y)
	r: radius/value
	do-draw-ellipse ctx x - r y - r r * 2 r * 2
]
OS-draw-ellipse: func [
	ctx		 [draw-ctx!]
	upper	 [red-pair!]
	diameter [red-pair!]
	/local
		pt [red-point2D!]
		x1 y1 x2 y2 [integer!]
][
	GET_PAIR_XY_INT(upper x1 y1)
	GET_PAIR_XY_INT(diameter x2 y2)
	do-draw-ellipse ctx x1 y1 x2 - x1 y2 - y1
]
OS-draw-font: func [ctx [draw-ctx!] font [red-object!]][]
OS-draw-text: func [
	ctx		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	return: [logic!]
	/local
		pt [red-point2D!]
		x y color [integer!]
][
	GET_PAIR_XY_INT(pos x y)
	color: either ctx/pen-type <> DRAW_BRUSH_NONE [ctx/pen-color][0]
	either TYPE_OF(text) = TYPE_OBJECT [
		draw-text-box ctx/dc ctx/x + x ctx/y + y as red-object! text color catch?
	][
		draw-text ctx/dc ctx/x + x ctx/y + y text color null
	]
	true
]
draw-arc-raster: func [
	ctx		[draw-ctx!]
	cx		[integer!]
	cy		[integer!]
	rx		[integer!]
	ry		[integer!]
	begin	[integer!]
	sweep	[integer!]
	closed? [logic!]
	/local
		abs-sweep steps i [integer!]
		x y last-x last-y start-x start-y [integer!]
		angle step rad fx fy [float!]
][
	if any [rx <= 0 ry <= 0 sweep = 0][exit]

	abs-sweep: sweep
	if abs-sweep < 0 [abs-sweep: 0 - abs-sweep]
	if abs-sweep >= 360 [
		do-draw-ellipse ctx cx - rx cy - ry rx * 2 ry * 2
		exit
	]

	steps: abs-sweep / 4
	if steps < 8 [steps: 8]
	if steps > 180 [steps: 180]

	rad: 3.141592653589793 / 180.0
	step: (as float! sweep) / as float! steps
	angle: as float! begin

	last-x: 0
	last-y: 0
	start-x: 0
	start-y: 0
	i: 0
	while [i <= steps][
		fx: (as float! cx) + ((as float! rx) * cos (angle * rad))
		fy: (as float! cy) + ((as float! ry) * sin (angle * rad))
		x: as-integer floor fx
		y: as-integer floor fy

		if i = 0 [
			start-x: x
			start-y: y
		]
		if all [closed? ctx/brush-type = DRAW_BRUSH_COLOR][
			draw-line-color ctx cx cy x y ctx/brush-color
		]
		if all [i > 0 ctx/pen-type <> DRAW_BRUSH_NONE][
			draw-line-xy ctx last-x last-y x y
		]
		last-x: x
		last-y: y
		angle: angle + step
		i: i + 1
	]

	if all [closed? ctx/pen-type <> DRAW_BRUSH_NONE][
		draw-line-xy ctx cx cy start-x start-y
		draw-line-xy ctx cx cy last-x last-y
	]
]

OS-draw-arc: func [
	ctx	   [draw-ctx!]
	center [red-pair!]
	end	   [red-value!]
	/local
		radius [red-pair!]
		angle  [red-integer!]
		pt	   [red-point2D!]
		cx cy rx ry begin sweep [integer!]
		closed? [logic!]
][
	radius: center + 1
	GET_PAIR_XY_INT(center cx cy)
	GET_PAIR_XY_INT(radius rx ry)
	angle: as red-integer! radius + 1
	begin: angle/value
	angle: angle + 1
	sweep: angle/value
	closed?: angle < end
	draw-arc-raster ctx cx cy rx ry begin sweep closed?
]
OS-draw-curve: func [
	ctx	  [draw-ctx!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		p1 p2 p3 [red-pair!]
		pt [red-point2D!]
		x0 y0 x1 y1 x2 y2 x3 y3 [integer!]
		last-x last-y next-x next-y i count [integer!]
		t nt t2 nt2 t3 nt3 xf yf [float32!]
][
	if ctx/pen-type = DRAW_BRUSH_NONE [exit]

	p1: start + 1
	p2: start + 2
	p3: start + 3
	GET_PAIR_XY_INT(start x0 y0)
	GET_PAIR_XY_INT(p1 x1 y1)
	GET_PAIR_XY_INT(p2 x2 y2)
	count: (as-integer end - start) >> 4
	if count > 2 [GET_PAIR_XY_INT(p3 x3 y3)]

	last-x: x0
	last-y: y0
	i: 1
	while [i <= 24][
		t: (as float32! i) / as float32! 24.0
		nt: as float32! 1.0 - t
		t2: t * t
		nt2: nt * nt
		either count = 2 [
			xf: (nt2 * as float32! x0) + ((as float32! 2.0 * nt * t) * as float32! x1) + (t2 * as float32! x2)
			yf: (nt2 * as float32! y0) + ((as float32! 2.0 * nt * t) * as float32! y1) + (t2 * as float32! y2)
		][
			t3: t2 * t
			nt3: nt2 * nt
			xf: (nt3 * as float32! x0) + ((as float32! 3.0 * nt2 * t) * as float32! x1) + ((as float32! 3.0 * nt * t2) * as float32! x2) + (t3 * as float32! x3)
			yf: (nt3 * as float32! y0) + ((as float32! 3.0 * nt2 * t) * as float32! y1) + ((as float32! 3.0 * nt * t2) * as float32! y2) + (t3 * as float32! y3)
		]
		next-x: as-integer xf
		next-y: as-integer yf
		draw-line-xy ctx last-x last-y next-x next-y
		last-x: next-x
		last-y: next-y
		i: i + 1
	]
]
OS-draw-line-join: func [ctx [draw-ctx!] style [integer!]][]
OS-draw-line-cap: func [ctx [draw-ctx!] style [integer!]][]
OS-draw-line-pattern: func [ctx [draw-ctx!] start [red-integer!] end [red-integer!]][]
OS-draw-image: func [
	ctx		  [draw-ctx!]
	image	  [red-image!]
	start	  [red-pair!]
	end		  [red-pair!]
	key-color [red-tuple!]
	border?	  [logic!]
	crop1	  [red-pair!]
	pattern	  [red-word!]
	return:	  [integer!]
	/local
		pt [red-point2D!]
		x y w h [integer!]
][
	either start = null [
		x: 0 y: 0 w: IMAGE_WIDTH(image/size) h: IMAGE_HEIGHT(image/size)
	][
		GET_PAIR_XY_INT(start x y)
		either any [end = null start = end][
			w: IMAGE_WIDTH(image/size)
			h: IMAGE_HEIGHT(image/size)
		][
			GET_PAIR_XY_INT(end w h)
			w: w - x
			h: h - y
		]
	]
	draw-image-rect ctx image x y w h
	0
]
OS-draw-brush-bitmap: func [ctx [draw-ctx!] img [red-image!] crop-1 [red-pair!] crop-2 [red-pair!] mode [red-word!] brush? [logic!]][]
OS-draw-brush-pattern: func [ctx [draw-ctx!] size [red-pair!] crop-1 [red-pair!] crop-2 [red-pair!] mode [red-word!] block [red-block!] brush? [logic!]][]
OS-draw-grad-pen-old: func [ctx [draw-ctx!] type [integer!] mode [integer!] offset [red-pair!] count [integer!] brush? [logic!]][]
OS-draw-grad-pen: func [ctx [draw-ctx!] mode [integer!] stops [red-value!] count [integer!] skip-pos [logic!] positions [red-value!] focal? [logic!] spread [integer!] brush? [logic!]][]
OS-set-clip: func [
	ctx	  [draw-ctx!]
	u	  [red-pair!]
	l	  [red-pair!]
	rect? [logic!]
	mode  [integer!]
	/local
		pt [red-point2D!]
		x1 y1 x2 y2 w h right bottom cur-right cur-bottom [integer!]
][
	if rect? = no [exit]
	GET_PAIR_XY_INT(u x1 y1)
	GET_PAIR_XY_INT(l x2 y2)
	w: x2 - x1
	h: y2 - y1
	if w < 0 [x1: x1 + w w: 0 - w]
	if h < 0 [y1: y1 + h h: 0 - h]

	draw-push-clip
	if all [mode = intersect sdl3-clip-active?][
		right: x1 + w
		bottom: y1 + h
		cur-right: sdl3-clip-x + sdl3-clip-w
		cur-bottom: sdl3-clip-y + sdl3-clip-h
		if x1 < sdl3-clip-x [x1: sdl3-clip-x]
		if y1 < sdl3-clip-y [y1: sdl3-clip-y]
		if right > cur-right [right: cur-right]
		if bottom > cur-bottom [bottom: cur-bottom]
		w: right - x1
		h: bottom - y1
	]
	draw-set-clip-rect ctx x1 y1 w h
]

OS-clip-end: func [ctx [draw-ctx!]][
	draw-pop-clip ctx
]
OS-matrix-rotate: func [ctx [draw-ctx!] pen-fill [integer!] angle [red-integer!] center [red-pair!]][]
OS-matrix-scale: func [ctx [draw-ctx!] pen-fill [integer!] sx [red-integer!] sy [red-pair!]][]
OS-matrix-translate: func [ctx [draw-ctx!] pen-fill [integer!] pair [red-pair!]][]
OS-matrix-skew: func [ctx [draw-ctx!] pen-fill [integer!] sx [red-integer!] sy [red-pair!]][]
OS-matrix-transform: func [ctx [draw-ctx!] pen-fill [integer!] center [red-pair!] scale [red-integer!] translate [red-pair!]][]
OS-draw-state-push: func [
	ctx	  [draw-ctx!]
	state [draw-state!]
][
	state/pen-type: ctx/pen-type
	state/pen-color: ctx/pen-color
	state/brush-color: ctx/brush-color
	state/brush-type: ctx/brush-type
	state/line-width: ctx/line-width
]

OS-draw-state-pop: func [
	ctx	  [draw-ctx!]
	state [draw-state!]
][
	ctx/pen-type: state/pen-type
	ctx/pen-color: state/pen-color
	ctx/brush-color: state/brush-color
	ctx/brush-type: state/brush-type
	ctx/line-width: state/line-width
]
OS-matrix-reset: func [ctx [draw-ctx!] pen-fill [integer!]][]
OS-matrix-invert: func [ctx [draw-ctx!] pen-fill [integer!]][]
OS-matrix-set: func [ctx [draw-ctx!] pen-fill [integer!] blk [red-block!]][]
OS-set-matrix-order: func [ctx [draw-ctx!] order [integer!]][]
OS-draw-shadow: func [
	ctx		[draw-ctx!]
	offset	[red-pair!]
	blur	[integer!]
	spread	[integer!]
	color	[integer!]
	inset?	[logic!]
][0]
