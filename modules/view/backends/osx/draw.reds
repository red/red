Red/System [
	Title:	"OSX Draw dialect backend"
	Author: "Qingtian Xie"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define DRAW_FLOAT_MAX		[as float32! 3.4e38]

max-edges: 1000												;-- max number of edges for a polygon
edges: as CGPoint! allocate max-edges * (size? CGPoint!)	;-- polygone edges buffer

draw-ctx!: alias struct! [
	raw				[handle!]					;-- OS drawing object: CGContext
	a				[float32!]					;-- CTM
	b				[float32!]
	c				[float32!]
	d				[float32!]
	tx				[float32!]
	ty				[float32!]
	pen-join		[integer!]
	pen-cap			[integer!]
	pen-width		[integer!]
	pen-style		[integer!]
	pen-color		[integer!]					;-- 00bbggrr format
	brush-color		[integer!]					;-- 00bbggrr format
	font-attrs		[integer!]
	height			[float32!]
	pen?			[logic!]
	brush?			[logic!]
	on-image?		[logic!]					;-- drawing on image?
]

draw-begin: func [
	ctx			[draw-ctx!]
	CGCtx		[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	paint?		[logic!]
	return: 	[draw-ctx!]
	/local
		rc		[NSRect!]
		nscolor [integer!]
		saved	[int-ptr!]
		m		[CGAffineTransform!]
][
	CGContextSaveGState CGCtx
	CGContextTranslateCTM CGCtx as float32! 0.5 as float32! 0.5

	ctx/raw:			CGCtx
	ctx/pen-width:		1
	ctx/pen-style:		0
	ctx/pen-color:		0						;-- default: black
	ctx/pen-join:		miter
	ctx/pen-cap:		flat
	ctx/brush-color:	0
	ctx/pen?:			yes
	ctx/brush?:			no

	ctx/font-attrs: objc_msgSend [				;-- default font attributes
		objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
		sel_getUid "initWithObjectsAndKeys:"
		default-font NSFontAttributeName
		0
	]
	rc: as NSRect! img
	ctx/height:	rc/y	

	CGContextSetMiterLimit CGCtx DRAW_FLOAT_MAX
	OS-draw-anti-alias ctx yes

	m: as CGAffineTransform! (as int-ptr! ctx) + 1
	saved: system/stack/align
	push 0
	push 0
	push CGCtx
	push m
	CGContextGetCTM 2							;-- save CTM
	system/stack/top: saved

	ctx
]

draw-end: func [
	dc			[draw-ctx!]
	CGCtx		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	paint?		[logic!]
][
	if dc/font-attrs <> 0	[objc_msgSend [dc/font-attrs sel_getUid "release"]]
	CGContextRestoreGState CGCtx
	OS-draw-anti-alias dc yes
]

OS-draw-anti-alias: func [
	dc	[draw-ctx!]
	on? [logic!]
][
	CGContextSetAllowsAntialiasing dc/raw on?
	CGContextSetAllowsFontSmoothing dc/raw on?
]

OS-draw-line: func [
	dc	   [draw-ctx!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		pt		[CGPoint!]
		nb		[integer!]
		pair	[red-pair!]
		ctx		[handle!]
][
	ctx:	dc/raw
	pt:		edges
	pair:	point
	nb:		0

	while [all [pair <= end nb < max-edges]][
		pt/x: as float32! pair/x
		pt/y: as float32! pair/y
		nb: nb + 1
		pt: pt + 1
		pair: pair + 1
	]
	CGContextBeginPath ctx
	CGContextAddLines ctx edges nb
	CGContextStrokePath ctx
]

CG-set-color: func [
	ctx		[handle!]
	color	[integer!]
	fill?	[logic!]
	/local
		r  [float32!]
		g  [float32!]
		b  [float32!]
		a  [float32!]
][
	r: (as float32! color and FFh) / 255.0
	g: (as float32! color >> 8 and FFh) / 255.0
	b: (as float32! color >> 16 and FFh) / 255.0
	a: (as float32! 255 - (color >>> 24)) / 255.0
	either fill? [
		CGContextSetRGBFillColor ctx r g b a
	][
		CGContextSetRGBStrokeColor ctx r g b a
	]
]

OS-draw-pen: func [
	dc	   [draw-ctx!]
	color  [integer!]									;-- aabbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	dc/pen?: not off?
	if all [not off? dc/pen-color <> color][
		dc/pen-color: color
		CG-set-color dc/raw color no
	]
]

OS-draw-fill-pen: func [
	dc	   [draw-ctx!]
	color  [integer!]									;-- aabbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	either off? [dc/brush?: no][
		if dc/brush-color <> color [
			dc/brush?: yes
			dc/brush-color: color
			CG-set-color dc/raw color yes
		]
	]
]

OS-draw-line-width: func [
	dc	  [draw-ctx!]
	width [red-integer!]
][
	if dc/pen-width <> width/value [
		dc/pen-width: width/value
		CGContextSetLineWidth dc/raw as float32! width/value
	]
]

OS-draw-box: func [
	dc	  [draw-ctx!]
	upper [red-pair!]
	lower [red-pair!]
	/local
		ctx		[handle!]
		t		[integer!]
		radius	[red-integer!]
		rad		[float32!]
		x1		[float32!]
		x2		[float32!]
		xm		[float32!]
		ym		[float32!]
		y1		[float32!]
		y2		[float32!]
][
	ctx: dc/raw
	radius: null
	if TYPE_OF(lower) = TYPE_INTEGER [
		radius: as red-integer! lower
		lower:  lower - 1
	]
	if upper/x > lower/x [t: upper/x upper/x: lower/x lower/x: t]
	if upper/y > lower/y [t: upper/y upper/y: lower/y lower/y: t]

	x1: as float32! upper/x
	y1: as float32! upper/y
	x2: as float32! lower/x
	y2: as float32! lower/y
	xm: x1 + (x2 - x1 / as float32! 2.0)
	ym: y1 + (y2 - y1 / as float32! 2.0)

	either radius <> null [
		rad: as float32! radius/value
		CGContextMoveToPoint ctx x1 ym
		CGContextAddArcToPoint ctx x1 y1 xm y1 rad
		CGContextAddArcToPoint ctx x2 y1 x2 ym rad
		CGContextAddArcToPoint ctx x2 y2 xm y2 rad
		CGContextAddArcToPoint ctx x1 y2 x1 ym rad
		CGContextClosePath ctx
		do-draw-path dc
	][
		if dc/brush? [CGContextFillRect ctx x1 y1 x2 - x1 y2 - y1]
		if dc/pen? [CGContextStrokeRect ctx x1 y1 x2 - x1 y2 - y1]
	]
]

do-draw-path: func [
	dc	  [draw-ctx!]
	/local
		mode [integer!]
][
	mode: case [
		all [dc/pen? dc/brush?] [kCGPathFillStroke]
		dc/brush?				[kCGPathFill]
		dc/pen?					[kCGPathStroke]
		true					[-1]
	]
	if mode <> -1 [CGContextDrawPath dc/raw mode]
]

OS-draw-triangle: func [
	dc	  [draw-ctx!]
	start [red-pair!]
	/local
		ctx   [handle!]
		point [CGPoint!]
][
	ctx: dc/raw
	point: edges

	loop 3 [
		point/x: as float32! start/x
		point/y: as float32! start/y
		point: point + 1
		start: start + 1
	]
	point/x: edges/x									;-- close the triangle
	point/y: edges/y
	CGContextBeginPath ctx
	CGContextAddLines ctx edges 4
	do-draw-path dc
]

OS-draw-polygon: func [
	dc	  [draw-ctx!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		ctx   [handle!]
		pair  [red-pair!]
		point [CGPoint!]
		nb	  [integer!]
		mode  [integer!]
][
	ctx:   dc/raw
	point: edges
	pair:  start
	nb:	   0
	
	while [all [pair <= end nb < max-edges]][
		point/x: as float32! pair/x
		point/y: as float32! pair/y
		nb: nb + 1
		point: point + 1
		pair: pair + 1	
	]
	;if nb = max-edges [fire error]	
	point/x: as float32! start/x						;-- close the polygon
	point/y: as float32! start/y

	CGContextBeginPath ctx
	CGContextAddLines ctx edges nb + 1
	do-draw-path dc
]

OS-draw-spline: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	closed? [logic!]
	/local
		ctx		[handle!]
		p		[CGPoint!]
		p0		[CGPoint!]
		p1		[CGPoint!]
		p2		[CGPoint!]
		p3		[CGPoint!]
		x		[float32!]
		y		[float32!]
		delta	[float32!]
		t		[float32!]
		t2		[float32!]
		t3		[float32!]
		i		[integer!]
		n		[integer!]
		count	[integer!]
		num		[integer!]
][
	ctx: dc/raw

	count: (as-integer end - start) >> 4
	num: count + 1

	p: edges
	unless closed? [
		p/x: as float32! start/x			;-- duplicate first point
		p/y: as float32! start/y
		p: p + 1
	]
	while [start <= end][
		p/x: as float32! start/x
		p/y: as float32! start/y
		p: p + 1
		start: start + 1
	]
	unless closed? [
		p/x: as float32! end/x				;-- duplicate end point
		p/y: as float32! end/y
	]

	p: either closed? [
		count: count + 1
		edges + 1
	][
		num: num + 2
		edges
	]
	CGContextBeginPath ctx
	CGContextMoveToPoint ctx p/x p/y

	p: edges
	i: 0
	delta: (as float32! 1.0) / (as float32! 25.0)

	while [i < count][						;-- CatmullRom Spline, tension = 0.5
		p0: p + (i % num)
		p1: p + (i + 1 % num)
		p2: p + (i + 2 % num)
		p3: p + (i + 3 % num)

		t: as float32! 0.0
		n: 0
		until [
			t: t + delta
			t2: t * t
			t3: t2 * t
			x: (as float32! 2.0) * p1/x + (p2/x - p0/x * t) +
			   (((as float32! 2.0) * p0/x - ((as float32! 5.0) * p1/x) + ((as float32! 4.0) * p2/x) - p3/x) * t2) +
			   ((as float32! 3.0) * (p1/x - p2/x) + p3/x - p0/x * t3) * 0.5
			y: (as float32! 2.0) * p1/y + (p2/y - p0/y * t) +
			   (((as float32! 2.0) * p0/y - ((as float32! 5.0) * p1/y) + ((as float32! 4.0) * p2/y) - p3/y) * t2) +
			   ((as float32! 3.0) * (p1/y - p2/y) + p3/y - p0/y * t3) * 0.5
			CGContextAddLineToPoint ctx x y
			n: n + 1
			n = 25
		]
		i: i + 1
	]
	do-draw-path dc
]

do-draw-ellipse: func [
	dc		[draw-ctx!]
	x		[float32!]
	y		[float32!]
	w		[float32!]
	h		[float32!]
][
	if dc/brush? [CGContextFillEllipseInRect dc/raw x y w h]
	if dc/pen? [CGContextStrokeEllipseInRect dc/raw x y w h]
]

OS-draw-circle: func [
	dc	   [draw-ctx!]
	center [red-pair!]
	radius [red-integer!]
	/local
		rad-x [integer!]
		rad-y [integer!]
		w	  [float32!]
		h	  [float32!]
		f	  [red-float!]
][
	either TYPE_OF(radius) = TYPE_INTEGER [
		either center + 1 = radius [					;-- center, radius
			rad-x: radius/value
			rad-y: rad-x
		][
			rad-y: radius/value							;-- center, radius-x, radius-y
			radius: radius - 1
			rad-x: radius/value
		]
		w: as float32! rad-x * 2
		h: as float32! rad-y * 2
	][
		f: as red-float! radius
		either center + 1 = radius [
			rad-x: as-integer f/value + 0.75
			rad-y: rad-x
			w: as float32! f/value * 2.0
			h: w
		][
			rad-y: as-integer f/value + 0.75
			h: as float32! f/value * 2.0
			f: f - 1
			rad-x: as-integer f/value + 0.75
			w: as float32! f/value * 2.0
		]
	]
	do-draw-ellipse dc as float32! center/x - rad-x as float32! center/y - rad-y w h
]

OS-draw-ellipse: func [
	dc	  	 [draw-ctx!]
	upper	 [red-pair!]
	diameter [red-pair!]
][
	do-draw-ellipse dc as float32! upper/x as float32! upper/y as float32! diameter/x as float32! diameter/y
]

OS-draw-font: func [
	dc		[draw-ctx!]
	font	[red-object!]
][
	objc_msgSend [dc/font-attrs sel_getUid "release"]
	dc/font-attrs: make-font-attrs font as red-object! none-value -1
]

draw-text-at: func [
	ctx		[handle!]
	text	[red-string!]
	attrs	[integer!]
	x		[integer!]
	y		[integer!]
	/local
		str		[integer!]
		attr	[integer!]
		line	[integer!]
		delta	[float32!]
		m		[CGAffineTransform!]
][
	m: make-CGMatrix 1 0 0 -1 x y
	str: to-CFString text
	attr: CFAttributedStringCreate 0 str attrs
	line: CTLineCreateWithAttributedString attr

	delta: objc_msgSend_f32 [
		objc_msgSend [attrs sel_getUid "objectForKey:" NSFontAttributeName]
		sel_getUid "ascender"
	]
	m/ty: m/ty + delta
	CGContextSetTextMatrix ctx m/a m/b m/c m/d m/tx m/ty
	CTLineDraw line ctx

	CFRelease str
	CFRelease attr
	CFRelease line
]

OS-draw-text: func [
	dc		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
][
	draw-text-at dc/raw text dc/font-attrs pos/x pos/y
	if dc/brush? [CG-set-color dc/raw dc/brush-color yes]
]

_draw-arc: func [
	; make an elliptical arc
	; Based on the algorithm described in
	; http://www.stillhq.com/ctpfaq/2002/03/c1088.html#AEN1212
	ctx		[handle!]
	cx		[float32!]
	cy		[float32!]
	rx		[float32!]
	ry		[float32!]
	alpha	[float32!]
	beta	[float32!]
	start?	[logic!]
	closed? [logic!]
	/local
		delta	[float32!]
		bcp		[float32!]
		pi32	[float32!]
		sin-a	[float32!]
		sin-b	[float32!]
		cos-a	[float32!]
		cos-b	[float32!]
		sx		[float32!]
		sy		[float32!]
][
	pi32: as float32! PI

	;-- adjust angles for ellipses
	alpha: atan2f (sinf alpha) * rx (cosf alpha) * ry
	beta:  atan2f (sinf beta)  * rx (cosf beta) * ry

	if pi32 < fabsf beta - alpha [
		either beta > alpha [
			beta: beta - (pi32 * as float32! 2.0)
		][
			alpha: alpha - (pi32 * as float32! 2.0)
		]
	]
	delta: beta - alpha / 2.0
	bcp: as float32! (4.0 / 3.0 * (1.0 - cosf delta) / sinf delta)

	sin-a: sinf alpha
	sin-b: sinf beta
	cos-a: cosf alpha
	cos-b: cosf beta

	if start? [
		sx: rx * cos-a + cx
		sy: ry * sin-a + cy
		either closed? [
			CGContextAddLineToPoint ctx sx sy
		][
			CGContextMoveToPoint ctx sx sy
		]
	]

	CGContextAddCurveToPoint ctx
		cos-a - (bcp * sin-a) * rx + cx
		sin-a + (bcp * cos-a) * ry + cy
		cos-b + (bcp * sin-b) * rx + cx
		sin-b - (bcp * cos-b) * ry + cy
		cos-b * rx + cx
		sin-b * ry + cy
]

OS-draw-arc: func [
	dc	   [draw-ctx!]
	center [red-pair!]
	end	   [red-value!]
	/local
		ctx			[handle!]
		radius		[red-pair!]
		angle		[red-integer!]
		begin		[red-integer!]
		cx			[float32!]
		cy			[float32!]
		rad-x		[float32!]
		rad-y		[float32!]
		angle-begin [float32!]
		angle-end	[float32!]
		delta		[float32!]
		rad			[float32!]
		current		[float32!]
		drawn		[float32!]
		sweep		[integer!]
		i			[integer!]
		closed?		[logic!]
][
	ctx: dc/raw
	cx: as float32! center/x
	cy: as float32! center/y
	rad: (as float32! PI) / as float32! 180.0

	radius: center + 1
	rad-x: as float32! radius/x
	rad-y: as float32! radius/y
	begin: as red-integer! radius + 1
	angle-begin: rad * as float32! begin/value
	angle: begin + 1
	sweep: angle/value
	angle-end: rad * as float32! (begin/value + sweep)

	closed?: angle < end

	CGContextBeginPath ctx
	if closed? [CGContextMoveToPoint ctx cx cy]
	either any [sweep >= 360 sweep <= -360][
		CGContextAddEllipseInRect ctx cx - rad-x cy - rad-y rad-x * as float32! 2.0 rad-y * as float32! 2.0
	][
		either rad-x <> rad-y [								;-- elliptical arc
			delta: as float32! (PI / 2.0)
			drawn: as float32! 0.0
			i: 0
			until [
				current: angle-begin + drawn
				rad: angle-end - current
				either rad > delta [rad: delta][
					if rad <= as float32! 0.000001 [break]
				]
				_draw-arc ctx cx cy rad-x rad-y current current + rad zero? i closed?
				drawn: drawn + rad
				i: i + 1
				i = 4
			]
		][
			CGContextAddArc ctx cx cy rad-x angle-begin angle-end 0
		]
	]
	if closed? [CGContextClosePath ctx]
	do-draw-path dc
]

OS-draw-curve: func [
	dc	  [draw-ctx!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		ctx   [handle!]
		cp1x  [float32!]
		cp1y  [float32!]
		cp2x  [float32!]
		cp2y  [float32!]
		p2	  [red-pair!]
		p3	  [red-pair!]
][
	ctx: dc/raw
	p2: start + 1
	p3: start + 2

	either 2 = ((as-integer end - start) >> 4) [		;-- p0, p1, p2  -->  p0, (p0 + 2p1) / 3, (2p1 + p2) / 3, p2
		cp1x: (as float32! p2/x << 1 + start/x) / as float32! 3.0
		cp1y: (as float32! p2/y << 1 + start/y) / as float32! 3.0
		cp2x: (as float32! p2/x << 1 + p3/x) / as float32! 3.0
		cp2y: (as float32! p2/y << 1 + p3/y) / as float32! 3.0
	][
		cp1x: as float32! p2/x
		cp1y: as float32! p2/y
		cp2x: as float32! p3/x
		cp2y: as float32! p3/y
	]

	CGContextBeginPath ctx
	CGContextMoveToPoint ctx as float32! start/x as float32! start/y
	CGContextAddCurveToPoint ctx cp1x cp1y cp2x cp2y as float32! end/x as float32! end/y
	CGContextStrokePath ctx
]

OS-draw-line-join: func [
	dc	  [draw-ctx!]
	style [integer!]
	/local
		mode [integer!]
][
	mode: kCGLineJoinMiter
	if dc/pen-join <> style [
		dc/pen-join: style
		case [
			style = miter		[mode: kCGLineJoinMiter]
			style = miter-bevel [mode: kCGLineJoinMiter]
			style = _round		[mode: kCGLineJoinRound]
			style = bevel		[mode: kCGLineJoinBevel]
			true				[mode: kCGLineJoinMiter]
		]
		CGContextSetLineJoin dc/raw mode
	]
]
	
OS-draw-line-cap: func [
	dc	  [draw-ctx!]
	style [integer!]
	/local
		mode [integer!]
][
	mode: kCGLineCapButt
	if dc/pen-cap <> style [
		dc/pen-cap: style
		case [
			style = flat		[mode: kCGLineCapButt]
			style = square		[mode: kCGLineCapSquare]
			style = _round		[mode: kCGLineCapRound]
			true				[mode: kCGLineCapButt]
		]
		CGContextSetLineCap dc/raw mode
	]
]

CG-draw-image: func [						;@@ use CALayer to get very good performance?
	dc			[handle!]
	bitmap		[integer!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		rc		[NSRect!]
		image	[integer!]
		ty		[float32!]
][
	image: CGBitmapContextCreateImage bitmap
	rc: make-rect x y width height
	ty: rc/y + rc/h
	;-- flip coords
	;; drawing an image or PDF by calling Core Graphics functions directly,
	;; we must flip the CTM.
	;; http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
	CGContextTranslateCTM dc as float32! 0.0 ty
	CGContextScaleCTM dc as float32! 1.0 as float32! -1.0

	CGContextDrawImage dc rc/x as float32! 0.0 rc/w rc/h image
	CGImageRelease image

	;-- flip back
	CGContextScaleCTM dc as float32! 1.0 as float32! -1.0
	CGContextTranslateCTM dc as float32! 0.0 (as float32! 0.0) - ty
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
	either null? start [x: 0 y: 0][x: start/x y: start/y]
	case [
		start = end [
			width:  IMAGE_WIDTH(image/size)
			height: IMAGE_HEIGHT(image/size)
		]
		start + 1 = end [					;-- two control points
			width: end/x - x
			height: end/y - y
		]
		start + 2 = end [0]					;@@ TBD three control points
		true [0]							;@@ TBD four control points
	]

	CG-draw-image dc/raw as-integer image/node x y width height
]

OS-draw-grad-pen: func [
	dc			[draw-ctx!]
	type		[integer!]
	mode		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
][0]

;transform-point: func [
;	ctx			[handle!]
;	point		[red-pair!]
;	return:		[CGPoint!]
;	/local
;		saved	[int-ptr!]
;		ty		[integer!]
;		tx		[integer!]
;		d		[integer!]
;		c		[integer!]
;		b		[integer!]
;		a		[integer!]
;		m		[CGAffineTransform!]
;		py		[integer!]
;		px		[integer!]
;		pt		[CGPoint!]
;][
;	a: 0
;	m: as CGAffineTransform! :a
;	pt: edges
;	pt/x: as float32! point/x
;	pt/y: as float32! point/y

;	saved: system/stack/align
;	push 0
;	push 0
;	push ctx
;	push m
;	CGContextGetCTM 2
;	system/stack/top: saved

;	px: CGPointApplyAffineTransform pt/x pt/y m/a m/b m/c m/d m/tx m/ty
;	py: system/cpu/edx
;	pt: as CGPoint! :px
;	pt
;]

OS-matrix-rotate: func [
	dc		[draw-ctx!]
	angle	[red-integer!]
	center	[red-pair!]
	/local
		ctx [handle!]
		pt	[CGPoint!]
][
	ctx: dc/raw
	if angle <> as red-integer! center [
		OS-matrix-translate ctx center/x center/y
	]
	CGContextRotateCTM ctx (as float32! PI) / (as float32! 180.0) * get-float32 angle
	if angle <> as red-integer! center [
		OS-matrix-translate ctx 0 - center/x 0 - center/y
	]
]

OS-matrix-scale: func [
	dc		[draw-ctx!]
	sx		[red-integer!]
	sy		[red-integer!]
][
	CGContextScaleCTM dc/raw get-float32 sx get-float32 sy
]

OS-matrix-translate: func [
	ctx [handle!]
	x	[integer!]
	y	[integer!]
][
	CGContextTranslateCTM ctx as float32! x as float32! y
]

OS-matrix-skew: func [
	dc		[draw-ctx!]
	sx		[red-integer!]
	sy		[red-integer!]
	/local
		ty	[integer!]
		tx	[integer!]
		d	[integer!]
		c	[integer!]
		b	[integer!]
		a	[integer!]
		m	[CGAffineTransform!]
][
	a: 0
	m: as CGAffineTransform! :a
	m/a: as float32! 1.0
	m/b: as float32! either sx = sy [0.0][_tan degree-to-radians get-float sy TYPE_TANGENT]
	m/c: as float32! _tan degree-to-radians get-float sx TYPE_TANGENT
	m/d: as float32! 1.0
	m/tx: as float32! 0.0
	m/ty: as float32! 0.0
	CGContextConcatCTM dc/raw m/a m/b m/c m/d m/tx m/ty
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

OS-matrix-push: func [dc [draw-ctx!]][
	CGContextSaveGState dc/raw
]

OS-matrix-pop: func [dc [draw-ctx!]][
	CGContextRestoreGState dc/raw
	dc/pen-color:		0
	dc/brush-color:		0
]

OS-matrix-reset: func [dc [draw-ctx!] /local m [CGAffineTransform!]][
	m: as CGAffineTransform! (as int-ptr! dc) + 1
	CGContextSetCTM dc/raw m/a m/b m/c m/d m/tx m/ty
]

OS-matrix-invert: func [
	dc [draw-ctx!]
	/local
		saved	[int-ptr!]
		ty		[integer!]
		tx		[integer!]
		d		[integer!]
		c		[integer!]
		b		[integer!]
		a		[integer!]
		invert	[CGAffineTransform!]
		m		[CGAffineTransform!]
][
	a: 0
	invert: as CGAffineTransform! :a
	m: as CGAffineTransform! (as int-ptr! dc) + 1
	saved: system/stack/align
	push 0										;-- padding
	push m/ty push m/tx push m/d push m/c push m/b push m/a
	push invert
	CGAffineTransformInvert 6
	system/stack/top: saved
	m: invert
	CGContextSetCTM dc/raw m/a m/b m/c m/d m/tx m/ty
]

OS-matrix-set: func [
	dc		[draw-ctx!]
	blk		[red-block!]
	/local
		ty	[integer!]
		tx	[integer!]
		d	[integer!]
		c	[integer!]
		b	[integer!]
		a	[integer!]
		m	[CGAffineTransform!]
		val	[red-integer!]
][
	val: as red-integer! block/rs-head blk
	a: 0
	m: as CGAffineTransform! :a
	m/a: get-float32 val
	m/b: get-float32 val + 1
	m/c: get-float32 val + 2
	m/d: get-float32 val + 3
	m/tx: get-float32 val + 4
	m/ty: get-float32 val + 5
	CGContextConcatCTM dc/raw m/a m/b m/c m/d m/tx m/ty
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