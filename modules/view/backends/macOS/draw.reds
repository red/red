Red/System [
	Title:	"macOS Draw dialect backend"
	Author: "Qingtian Xie"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %text-box.reds

#define DRAW_FLOAT_MAX		[as float32! 3.4e38]

max-colors: 256												;-- max number of colors for gradient
max-edges: 1000												;-- max number of edges for a polygon
edges: as CGPoint! allocate max-edges * (size? CGPoint!)	;-- polygone edges buffer
colors: as pointer! [float32!] allocate 5 * max-colors * (size? float32!)
colors-pos: colors + (4 * max-colors)

draw-state!: alias struct! [
	pen-clr		[integer!]
	brush-clr	[integer!]
	pen-join	[integer!]
	pen-cap		[integer!]
	pen?		[logic!]
	brush?		[logic!]
	a-pen?		[logic!]
	a-brush?	[logic!]
]

draw-begin: func [
	ctx			[draw-ctx!]
	CGCtx		[handle!]
	img			[red-image!]
	on-graphic? [logic!]
	pattern?	[logic!]
	return: 	[draw-ctx!]
	/local
		rc		[NSRect!]
		nscolor [integer!]
		saved	[int-ptr!]
		m		[CGAffineTransform!]
][
	unless pattern? [
		CGContextSaveGState CGCtx

		either on-graphic? [							;-- draw on image!, flip the CTM
			rc: as NSRect! img
			ctx/rect-y: rc/y
			CGContextTranslateCTM CGCtx as float32! 0.0 rc/y
			CGContextScaleCTM CGCtx as float32! 1.0 as float32! -1.0
		][
			CGContextTranslateCTM CGCtx as float32! 0.5 as float32! 0.5
		]
	]

	ctx/raw:			CGCtx
	ctx/ctx-matrix:		CGContextGetCTM CGCtx
	ctx/matrix/a:		F32_1
	ctx/matrix/b:		F32_0
	ctx/matrix/c:		F32_0
	ctx/matrix/d:		F32_1
	ctx/matrix/tx:		F32_0
	ctx/matrix/ty:		F32_0
	ctx/pen-width:		as float32! 1.0
	ctx/pen-style:		0
	ctx/pen-color:		0						;-- default: black
	ctx/pen-join:		miter
	ctx/pen-cap:		flat
	ctx/brush-color:	-1
	ctx/grad-pen:		-1
	ctx/pen?:			yes
	ctx/brush?:			no
	ctx/grad-pos?:		no
	ctx/colorspace:		CGColorSpaceCreateDeviceRGB
	ctx/last-pt-x:		as float32! 0.0
	ctx/last-pt-y:		as float32! 0.0
	ctx/on-image?:		on-graphic?

	ctx/font-attrs: objc_msgSend [				;-- default font attributes
		objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
		sel_getUid "initWithObjectsAndKeys:"
		default-font NSFontAttributeName
		0
	]

	CGContextSetMiterLimit CGCtx DRAW_FLOAT_MAX
	OS-draw-anti-alias ctx yes
	ctx
]

draw-end: func [
	dc			[draw-ctx!]
	CGCtx		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	pattern?	[logic!]
][
	if dc/font-attrs <> 0 [objc_msgSend [dc/font-attrs sel_release]]
	CGColorSpaceRelease dc/colorspace
	unless pattern? [
		CGContextRestoreGState CGCtx
		OS-draw-anti-alias dc yes
	]
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
		p		[CGPoint!]
		nb		[integer!]
		pair	[red-pair!]
		ctx		[handle!]
		pt		[red-point2D!]
][
	ctx:	dc/raw
	p:		edges
	pair:	point
	nb:		0

	while [all [pair <= end nb < max-edges]][
		GET_PAIR_XY(pair p/x p/y)
		nb: nb + 1
		p: p + 1
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

_set-font-color: func [
	dc		[draw-ctx!]
	color	[integer!]
	/local
		clr [integer!]
][
	if 2 >= objc_msgSend [dc/font-attrs sel_getUid "count"][
		clr: rs-to-NSColor color
		objc_msgSend [dc/font-attrs sel_release]
		dc/font-attrs: objc_msgSend [				;-- default font attributes
			objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
			sel_getUid "initWithObjectsAndKeys:"
			default-font NSFontAttributeName
			clr NSForegroundColorAttributeName
			0
		]
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
		_set-font-color dc color
	]
]

OS-draw-fill-pen: func [
	dc	   [draw-ctx!]
	color  [integer!]									;-- aabbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	if dc/grad-pen <> -1 [
		CGGradientRelease dc/grad-pen
		dc/grad-pos?: no
		dc/grad-pen: -1
	]
	either off? [dc/brush?: no][
		dc/brush?: yes
		if dc/brush-color <> color [
			dc/brush-color: color
			CG-set-color dc/raw color yes
		]
	]
]

OS-draw-line-width: func [
	dc	  [draw-ctx!]
	width [red-value!]
	/local
		width-v	[float32!]
][
	width-v: get-float32 as red-integer! width
	if width-v <= F32_0 [width-v: F32_1]
	dc/pen-width: width-v
	CGContextSetLineWidth dc/raw width-v
]

OS-draw-line-pattern: func [
	dc			[draw-ctx!]
	start		[red-integer!]
	end			[red-integer!]
	/local
		p		[red-integer!]
		cnt		[integer!]
		dashes	[float32-ptr!]
		pf		[float32-ptr!]
][
	cnt: (as-integer end - start) / 16 + 1
	dashes: null
	if cnt > 0 [
		dashes: as float32-ptr! system/stack/allocate cnt
		pf: dashes
		while [start <= end][
			pf/1: as float32! start/value
			pf: pf + 1
			start: start + 1
		]
	]
	CGContextSetLineDash dc/raw as float32! 0.0 dashes cnt
]

get-shape-center: func [
	start			[CGPoint!]
	count			[integer!]
	cx				[float32-ptr!]
	cy				[float32-ptr!]
	d				[float32-ptr!]
	/local
		point		[CGPoint!]
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
	loop count [
		x0: point/x
		y0: point/y
		point: point + 1
		x1: point/x
		y1: point/y
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
		loop count [
			dx: centroid-x - point/x
			dy: centroid-y - point/y
			r: sqrtf dx * dx + ( dy * dy )
			if r > d/value [ d/value: r ]
			point: point + 1
		]
	]
]

check-gradient-poly: func [
	ctx			[draw-ctx!]
	start		[CGPoint!]
	count		[integer!]
	/local
		type	[integer!]
		cx		[float32!]
		cy		[float32!]
		d		[float32!]
		rc		[NSRect! value]
][
	cx: as float32! 0.0 cy: as float32! 0.0 d: as float32! 0.0
	type: ctx/grad-type
	either type = radial [
		get-shape-center start count :cx :cy :d
		ctx/grad-radius: d
		ctx/grad-x1: cx
		ctx/grad-y1: cy
		ctx/grad-x2: ctx/grad-x1
		ctx/grad-y2: ctx/grad-y1
	][
		rc: CGContextGetPathBoundingBox ctx/raw
		ctx/grad-x1: rc/x
		ctx/grad-x2: rc/x + rc/w
		ctx/grad-y1: rc/y
		ctx/grad-y2: rc/y
	]
]

check-gradient-box: func [
	ctx			[draw-ctx!]
	upper-x		[float32!]
	upper-y		[float32!]
	lower-x		[float32!]
	lower-y		[float32!]
	/local
		type	[integer!]
		dx		[float32!]
		dy		[float32!]
][
	type: ctx/grad-type
	case [
		any [
			type = linear
			type = diamond
		][
			ctx/grad-x1: upper-x
			ctx/grad-x2: lower-x
			ctx/grad-y1: upper-y
			ctx/grad-y2: ctx/grad-y1
		]
		type = radial [
			dx: lower-x - upper-x + as float32! 1.0
			dy: lower-y - upper-y + as float32! 1.0
			dx: dx / as float32! 2.0
			dy: dy / as float32! 2.0
			ctx/grad-x1: dx + upper-x
			ctx/grad-y1: dy + upper-y
			ctx/grad-x2: ctx/grad-x1
			ctx/grad-y2: ctx/grad-y1
			ctx/grad-radius: sqrtf dx * dx + ( dy * dy )
		]
		true []
	]
]

OS-draw-box: func [
	dc	  [draw-ctx!]
	upper [red-pair!]
	lower [red-pair!]
	/local
		ctx		[handle!]
		t		[float32!]
		radius	[red-integer!]
		rad		[float32!]
		x1		[float32!]
		x2		[float32!]
		xm		[float32!]
		ym		[float32!]
		y1		[float32!]
		y2		[float32!]
		width	[float32!]
		height	[float32!]
		pt		[red-point2D!]
		ux uy lx ly [float32!]
][
	ctx: dc/raw
	radius: null
	if upper + 2 = lower [
		radius: as red-integer! lower
		lower:  lower - 1
	]
	GET_PAIR_XY(upper ux uy)
	GET_PAIR_XY(lower lx ly)
	if ux > lx [t: ux ux: lx lx: t]
	if uy > ly [t: uy uy: ly ly: t]

	x1: ux
	y1: uy
	x2: lx
	y2: ly
	xm: x1 + (x2 - x1 / as float32! 2.0)
	ym: y1 + (y2 - y1 / as float32! 2.0)

	either radius <> null [
		width: lx - ux
		height: ly - uy
		t: either width > height [height][width]
		rad: get-float32 radius
		if (rad * as float32! 2.0) > t [rad: t / as float32! 2.0]
		CGContextMoveToPoint ctx x1 ym
		CGContextAddArcToPoint ctx x1 y1 xm y1 rad
		CGContextAddArcToPoint ctx x2 y1 x2 ym rad
		CGContextAddArcToPoint ctx x2 y2 xm y2 rad
		CGContextAddArcToPoint ctx x1 y2 x1 ym rad
		CGContextClosePath ctx
	][
		CGContextAddRect ctx x1 y1 x2 - x1 y2 - y1
	]
	if dc/grad-pos? [check-gradient-box dc x1 y1 x2 y2]
	do-draw-path dc
]

do-draw-path: func [
	dc	  [draw-ctx!]
	/local
		ctx  [handle!]
		mode [integer!]
		path [integer!]
][
	ctx: dc/raw
	either dc/grad-pen = -1 [
		mode: case [
			all [dc/pen? dc/brush?] [kCGPathEOFillStroke]
			dc/brush?				[kCGPathEOFill]
			dc/pen?					[kCGPathStroke]
			true					[-1]
		]
		if mode <> -1 [CGContextDrawPath ctx mode]
	][
		if dc/pen? [path: CGContextCopyPath ctx]
		fill-gradient-region dc
		if dc/pen? [
			CGContextAddPath ctx path
			CGContextStrokePath ctx
		]
	]
]

OS-draw-triangle: func [
	dc	  [draw-ctx!]
	start [red-pair!]
	/local
		ctx   [handle!]
		point [CGPoint!]
		pt	  [red-point2D!]
][
	ctx: dc/raw
	point: edges

	loop 3 [
		GET_PAIR_XY(start point/x point/y)
		point: point + 1
		start: start + 1
	]
	point/x: edges/x									;-- close the triangle
	point/y: edges/y
	CGContextBeginPath ctx
	CGContextAddLines ctx edges 4
	if dc/grad-pos? [check-gradient-poly dc edges 3]
	CGContextClosePath ctx
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
		pt	  [red-point2D!]
][
	ctx:   dc/raw
	point: edges
	pair:  start
	nb:	   0

	while [all [pair <= end nb < max-edges]][
		GET_PAIR_XY(pair point/x point/y)
		nb: nb + 1
		point: point + 1
		pair: pair + 1
	]
	;if nb = max-edges [fire error]
	GET_PAIR_XY(start point/x point/y)			;-- close the polygon

	CGContextBeginPath ctx
	CGContextAddLines ctx edges nb + 1
	if dc/grad-pos? [check-gradient-poly dc edges nb]
	CGContextClosePath ctx
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
		pt		[red-point2D!]
][
	ctx: dc/raw

	count: (as-integer end - start) >> 4
	num: count + 1

	p: edges
	unless closed? [
		GET_PAIR_XY(start p/x p/y)			;-- duplicate first point
		p: p + 1
	]
	while [start <= end][
		GET_PAIR_XY(start p/x p/y)
		p: p + 1
		start: start + 1
	]
	unless closed? [
		GET_PAIR_XY(end p/x p/y)			;-- duplicate end point
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
	/local
		dx	[float32!]
		dy	[float32!]
][
	CGContextAddEllipseInRect dc/raw x y w h
	if dc/grad-pos? [
		either dc/grad-type = linear [
			dc/grad-x1: x
			dc/grad-x2: x + w
			dc/grad-y1: y
			dc/grad-y2: y
		][
			dx: w / as float32! 2.0
			dy: h / as float32! 2.0
			dc/grad-x1: x + dx			;-- center point
			dc/grad-y1: y + dy
			dc/grad-x2: dc/grad-x1
			dc/grad-y2: dc/grad-y1
			dc/grad-radius: either dx > dy [dx][dy]
		]
	]
	do-draw-path dc
]

OS-draw-circle: func [
	dc	   [draw-ctx!]
	center [red-pair!]
	radius [red-integer!]
	/local
		rad-x [float32!]
		rad-y [float32!]
		w	  [float32!]
		h	  [float32!]
		cx cy [float32!]
		f	  [red-float!]
		pt	  [red-point2D!]
][
	rad-x: get-float32 radius
	rad-y: rad-x
	if center + 2 = radius [	;-- center, radius-x, radius-y
		radius: radius - 1
		rad-x: get-float32 radius
	]
	w: rad-x * as float32! 2.0
	h: rad-y * as float32! 2.0

	GET_PAIR_XY(center cx cy)
	do-draw-ellipse dc cx - rad-x cy - rad-y w h
]

OS-draw-ellipse: func [
	dc	  	 [draw-ctx!]
	upper	 [red-pair!]
	diameter [red-pair!]
	/local
		pt	 [red-point2D!]
		ux uy dx dy [float32!]
][
	GET_PAIR_XY(upper ux uy)
	GET_PAIR_XY(diameter dx dy)
	do-draw-ellipse dc ux uy dx dy
]

OS-draw-font: func [
	dc		[draw-ctx!]
	font	[red-object!]
][
	objc_msgSend [dc/font-attrs sel_release]
	dc/font-attrs: make-font-attrs font as red-object! none-value -1
]

draw-text-at: func [
	ctx		[handle!]
	text	[red-string!]
	attrs	[integer!]
	x		[float32!]
	y		[float32!]
	/local
		str		[integer!]
		attr	[integer!]
		line	[integer!]
		delta	[float32!]
		m		[CGAffineTransform!]
][
	m: make-CGMatrix 1 0 0 -1 1 1
	m/tx: x
	m/ty: y
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

draw-text-box: func [
	dc		[draw-ctx!]
	pos		[red-pair!]
	tbox	[red-object!]
	catch?	[logic!]
	/local
		int		[red-integer!]
		values	[red-value!]
		state	[red-block!]
		str		[red-string!]
		bool	[red-logic!]
		layout? [logic!]
		layout	[integer!]
		tc		[integer!]
		idx		[integer!]
		len		[integer!]
		y		[integer!]
		x		[integer!]
		cg-pt	[CGPoint!]
		clr		[integer!]
		pt		[red-point2D!]
][
	values: object/get-values tbox
	str: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(str) <> TYPE_STRING [exit]

	state: as red-block! values + FACE_OBJ_EXT3
	layout?: yes
	if TYPE_OF(state) = TYPE_BLOCK [
		bool: as red-logic! (block/rs-tail state) - 1
		layout?: bool/value
	]
	if layout? [
		clr: either null? dc [0][
			objc_msgSend [dc/font-attrs sel_getUid "objectForKey:" NSForegroundColorAttributeName]
		]
		OS-text-box-layout tbox null clr catch?
	]

	int: as red-integer! block/rs-head state
	layout: int/value
	int: int + 1
	tc: int/value

	idx: objc_msgSend [layout sel_getUid "glyphRangeForTextContainer:" tc]
	len: system/cpu/edx
	x: 0
	cg-pt: as CGPoint! :x
	GET_PAIR_XY(pos cg-pt/x cg-pt/y)
	objc_msgSend [layout sel_getUid "drawBackgroundForGlyphRange:atPoint:" idx len cg-pt/x cg-pt/y]
	objc_msgSend [layout sel_getUid "drawGlyphsForGlyphRange:atPoint:" idx len cg-pt/x cg-pt/y]
]

OS-draw-text: func [
	dc		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	return: [logic!]
	/local
		ctx [handle!]
		pt	[red-point2D!]
		x y [float32!]
][
	ctx: dc/raw
	either TYPE_OF(text) = TYPE_STRING [
		GET_PAIR_XY(pos x y)
		draw-text-at ctx text dc/font-attrs x y
	][
		draw-text-box dc pos as red-object! text catch?
	]
	CG-set-color ctx dc/pen-color no				;-- drawing text will change pen color, so reset it
	CG-set-color ctx dc/brush-color yes				;-- drawing text will change brush color, so reset it
	true
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
	delta: beta - alpha / as float32! 2.0
	bcp: as float32! (4.0 / 3.0 * (1.0 - cos as float! delta) / sin as float! delta)

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
		pt			[red-point2D!]
][
	ctx: dc/raw
	GET_PAIR_XY(center cx cy)
	rad: (as float32! PI) / as float32! 180.0

	radius: center + 1
	GET_PAIR_XY(radius rad-x rad-y)
	begin: as red-integer! radius + 1
	angle-begin: rad * as float32! begin/value
	angle: begin + 1
	sweep: angle/value
	i: begin/value + sweep
	angle-end: rad * as float32! i

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
			CGContextAddArc ctx cx cy rad-x angle-begin angle-end as-integer sweep < 0
		]
	]
	either closed? [
		CGContextClosePath ctx
		do-draw-path dc
	][
		CGContextStrokePath ctx
	]
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
		pt	  [red-point2D!]
		sx sy [float32!]
		p2x p2y p3x p3y [float32!]
][
	ctx: dc/raw
	p2: start + 1
	p3: start + 2
	GET_PAIR_XY(p2 p2x p2y)
	GET_PAIR_XY(p3 p3x p3y)
	GET_PAIR_XY(start sx sy)

	either 2 = ((as-integer end - start) >> 4) [		;-- p0, p1, p2  -->  p0, (p0 + 2p1) / 3, (2p1 + p2) / 3, p2
		cp1x: (p2x * as float32! 2.0) + sx / as float32! 3.0
		cp1y: (p2y * as float32! 2.0) + sy / as float32! 3.0
		cp2x: (p2x * as float32! 2.0) + p3x / as float32! 3.0
		cp2y: (p2y * as float32! 2.0) + p3y / as float32! 3.0
	][
		cp1x: p2x
		cp1y: p2y
		cp2x: p3x
		cp2y: p3y
	]

	CGContextBeginPath ctx
	CGContextMoveToPoint ctx sx sy
	GET_PAIR_XY(end sx sy)
	CGContextAddCurveToPoint ctx cp1x cp1y cp2x cp2y sx sy
	CGContextStrokePath ctx
]

OS-draw-line-join: func [
	dc	  [draw-ctx!]
	style [integer!]
	/local
		mode [integer!]
][
	mode: kCGLineJoinMiter
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

OS-draw-line-cap: func [
	dc	  [draw-ctx!]
	style [integer!]
	/local
		mode [integer!]
][
	mode: kCGLineCapButt
	dc/pen-cap: style
	case [
		style = flat		[mode: kCGLineCapButt]
		style = square		[mode: kCGLineCapSquare]
		style = _round		[mode: kCGLineCapRound]
		true				[mode: kCGLineCapButt]
	]
	CGContextSetLineCap dc/raw mode
]

CG-draw-image: func [						;@@ use CALayer to get very good performance?
	dc			[handle!]
	image		[integer!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		tx		[float32!]
		ty		[float32!]
		w		[float32!]
		h		[float32!]
		flip-x	[float32!]
		flip-y	[float32!]
][
	either width < 0 [
		w: as float32! 0 - width
		flip-x: as float32! -1.0
	][
		w: as float32! width
		flip-x: as float32! 1.0
	]
	tx: as float32! x
	either height < 0 [
		h: as float32! 0 - height
		flip-y: as float32! 1.0
	][
		h: as float32! height
		flip-y: as float32! -1.0
	]
	ty: as float32! y + height
	;-- flip coords
	;; drawing an image or PDF by calling Core Graphics functions directly,
	;; we must flip the CTM.
	;; http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
	CGContextTranslateCTM dc tx ty
	CGContextScaleCTM dc flip-x flip-y

	CGContextDrawImage dc as float32! 0.0 as float32! 0.0 w h image

	;-- flip back
	CGContextScaleCTM dc flip-x flip-y
	CGContextTranslateCTM dc (as float32! 0.0) - tx (as float32! 0.0) - ty
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
		dst		[red-image! value]
		handle	[integer!]
		pt		[red-point2D!]
][
	either any [
		start + 2 = end
		start + 3 = end
	][
		x: 0 y: 0 w: 0 h: 0
		image/any-resize src dst crop1 start end :x :y :w :h
		if dst/header = TYPE_NONE [return 0]
		handle: OS-image/to-cgimage dst
		CG-draw-image dc/raw handle x y w h
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
				GET_PAIR_XY_INT(end w h)
				w: w - x
				h: h - y
			]
			true [return 0]
		]
		handle: OS-image/to-cgimage src
		unless null? crop1 [
			handle: CGImageCreateWithImageInRect handle
						as float32! crop.x as float32! crop.y
						as float32! crop.w as float32! crop.h
		]
		CG-draw-image dc/raw handle x y w h
		unless null? crop1 [
			CGImageRelease handle
		]
	]
	0
]

fill-gradient-region: func [
	dc		[draw-ctx!]
	/local
		ctx [handle!]
		pt1	[CGPoint! value]
		pt2	[CGPoint! value]
][
	ctx: dc/raw
	CGContextSaveGState ctx
	CGContextClip ctx

	either dc/grad-type = linear [
		pt1/x: dc/grad-x1
		pt1/y: dc/grad-y1
		pt1: CGPointApplyAffineTransform pt1 dc/matrix
		pt2/x: dc/grad-x2
		pt2/y: dc/grad-y2
		pt2: CGPointApplyAffineTransform pt2 dc/matrix
		CGContextDrawLinearGradient
			ctx
			dc/grad-pen
			pt1/x pt1/y pt2/x pt2/y
			3
	][
		CGContextConcatCTM dc/raw dc/matrix
		CGContextDrawRadialGradient
			ctx
			dc/grad-pen
			dc/grad-x2
			dc/grad-y2
			as float32! 0.0
			dc/grad-x1
			dc/grad-y1
			dc/grad-radius
			3
	]
	CGContextRestoreGState ctx
]

OS-draw-grad-pen-old: func [
	dc			[draw-ctx!]
	type		[integer!]
	spread		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
	/local
		val		[integer!]
		color	[pointer! [float32!]]
		pos		[pointer! [float32!]]
		last-c	[pointer! [float32!]]
		last-p	[pointer! [float32!]]
		int		[red-integer!]
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		n		[integer!]
		delta	[float32!]
		p		[float32!]
		angle	[float32!]
		sx		[float32!]
		sy		[float32!]
		rotate? [logic!]
		scale?	[logic!]
		pt		[red-point2D!]
][
	dc/matrix: CGAffineTransformMake F32_1 F32_0 F32_0 F32_1 F32_0 F32_0
	dc/grad-type: type
	dc/grad-spread: spread
	GET_PAIR_XY(offset dc/grad-x1 dc/grad-y1)

	int: as red-integer! offset + 1
	sx: as float32! int/value
	int: int + 1
	sy: as float32! int/value

	dc/grad-y2: dc/grad-y1
	either type = linear [
		dc/grad-x2: dc/grad-x1 + sy
		dc/grad-x1: dc/grad-x1 + sx
	][
		dc/grad-radius: sy - sx
		dc/grad-x2: dc/grad-x1
	]

	n: 0
	rotate?: no
	scale?: no
	sy: as float32! 1.0
	while [
		int: int + 1
		n < 3
	][										;-- fetch angle, scale-x and scale-y (optional)
		switch TYPE_OF(int) [
			TYPE_INTEGER	[p: as float32! int/value]
			TYPE_FLOAT		[f: as red-float! int p: as float32! f/value]
			default			[break]
		]
		switch n [
			0	[if p <> F32_0 [angle: p rotate?: yes]]
			1	[if p <> F32_1 [sx: p scale?: yes]]
			2	[if p <> F32_1 [sy: p scale?: yes]]
		]
		n: n + 1
	]
	if rotate? [
		p: (as float32! PI) / (as float32! 180.0)
		dc/matrix: CGAffineTransformRotate dc/matrix p * angle
	]
	if scale? [
		dc/matrix: CGAffineTransformScale dc/matrix sx sy
	]

	color: colors + 4
	pos: colors-pos + 1
	delta: as float32! count - 1
	delta: (as float32! 1.0) / delta
	p: as float32! 0.0
	head: as red-value! int

	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		val: get-tuple-color clr
		color/1: (as float32! val and FFh) / 255.0
		color/2: (as float32! val >> 8 and FFh) / 255.0
		color/3: (as float32! val >> 16 and FFh) / 255.0
		color/4: (as float32! 255 - (val >>> 24)) / 255.0
		next: head + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: as float32! f/value]
		pos/value: p
		if next <> head [p: p + delta]
		head: head + 1
		color: color + 4
		pos: pos + 1
	]

	last-p: pos - 1
	last-c: color - 4
	pos: pos - count
	color: color - (count * 4)

	if pos/value > as float32! 0.0 [			;-- first one should be always 0.0
		colors-pos/value: as float32! 0.0
		colors/1: color/1
		colors/2: color/2
		colors/3: color/3
		colors/4: color/4
		color: colors
		pos: colors-pos
		count: count + 1
	]

	if dc/grad-pen <> -1 [CGGradientRelease dc/grad-pen]
	dc/grad-pen: CGGradientCreateWithColorComponents dc/colorspace color pos count
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
	/local
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		color	[float32-ptr!]
		last-c	[float32-ptr!]
		pos		[float32-ptr!]
		last-p	[float32-ptr!]
		delta	[float32!]
		p		[float32!]
		pair	[red-pair!]
		pt		[red-point2D!]
		val		[integer!]
		x y		[float32!]
][
	ctx/grad-type: type
	ctx/grad-spread: spread
	ctx/grad-pos?: skip-pos?

	either brush? [
		ctx/grad-brush?: true
	][
		ctx/grad-pen?: true
	]
	;-- stops
	color: colors + 4
	pos: colors-pos + 1
	delta: as float32! count - 1
	delta: (as float32! 1.0) / delta
	p: as float32! 0.0
	head: stops
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		val: get-tuple-color clr
		color/1: (as float32! val and FFh) / 255.0
		color/2: (as float32! val >> 8 and FFh) / 255.0
		color/3: (as float32! val >> 16 and FFh) / 255.0
		color/4: (as float32! 255 - (val >>> 24)) / 255.0
		next: head + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: as float32! f/value]
		pos/value: p
		if next <> head [p: p + delta]
		head: head + 1
		color: color + 4
		pos: pos + 1
	]

	last-p: pos - 1
	last-c: color - 4
	pos: pos - count
	color: color - (count * 4)

	if pos/value > as float32! 0.0 [			;-- first one should be always 0.0
		colors-pos/value: as float32! 0.0
		colors/1: color/1
		colors/2: color/2
		colors/3: color/3
		colors/4: color/4
		color: colors
		pos: colors-pos
		count: count + 1
	]

	if ctx/grad-pen <> -1 [CGGradientRelease ctx/grad-pen]
	ctx/grad-pen: CGGradientCreateWithColorComponents ctx/colorspace color pos count

	;-- positions
	unless skip-pos? [
		pair: as red-pair! positions
		GET_PAIR_XY(pair x y)
		ctx/grad-x1: x ctx/grad-y1: y
		either type = linear [
			pair: pair + 1
			GET_PAIR_XY(pair x y)
			ctx/grad-x2: x ctx/grad-y2: y
		][
			either type = radial [
				ctx/grad-radius: get-float32 as red-integer! positions + 1
				if focal? [
					pair: as red-pair! ( positions + 2 )
					GET_PAIR_XY(pair x y)
				]
				ctx/grad-x2: x ctx/grad-y2: y
			][
				0	;@@ TBD diamond gradient
			]
		]
	]
]

OS-matrix-rotate: func [
	dc		[draw-ctx!]
	pen		[integer!]
	angle	[red-integer!]
	center	[red-pair!]
	/local
		ctx [handle!]
		pt	[red-point2D!]
		rad [float32!]
		x y [float32!]
][
	ctx: dc/raw
	rad: (as float32! PI) / (as float32! 180.0) * get-float32 angle
	GET_PAIR_XY(center x y)
	either pen = -1 [
		if angle <> as red-integer! center [
			_OS-matrix-translate ctx x y
		]
		CGContextRotateCTM ctx rad
		if angle <> as red-integer! center [
			_OS-matrix-translate ctx (as float32! 0.0) - x (as float32! 0.0) - y
		]
	][
		dc/matrix: CGAffineTransformRotate dc/matrix rad
	]
]

OS-matrix-scale: func [
	dc		[draw-ctx!]
	pen		[integer!]
	sx		[red-integer!]
	center	[red-pair!]
	/local
		sy	[red-integer!]
		pt	[red-point2D!]
		x y [float32!]
][
	GET_PAIR_XY(center x y)
	sy: sx + 1
	either pen = -1 [
		if TYPE_OF(center) = TYPE_PAIR [
			_OS-matrix-translate dc/raw x y
		]
		CGContextScaleCTM dc/raw get-float32 sx get-float32 sy
		if TYPE_OF(center) = TYPE_PAIR [
			_OS-matrix-translate dc/raw (as float32! 0.0) - x (as float32! 0.0) - y
		]
	][
		dc/matrix: CGAffineTransformScale dc/matrix get-float32 sx get-float32 sy
	]
]

_OS-matrix-translate: func [
	ctx [handle!]
	x	[float32!]
	y	[float32!]
][
	CGContextTranslateCTM ctx x y
]

OS-matrix-translate: func [
	dc	[draw-ctx!]
	pen [integer!]
	pos [red-pair!]
	/local
		pt [red-point2D!]
		x y [float32!]
][
	GET_PAIR_XY(pos x y)
	either pen = -1 [
		CGContextTranslateCTM dc/raw x y
	][
		dc/matrix: CGAffineTransformTranslate dc/matrix x y
	]
]

OS-matrix-skew: func [
	dc		[draw-ctx!]
	pen		[integer!]
	sx		[red-integer!]
	center	[red-pair!]
	/local
		sy	[red-integer!]
		xv	[float!]
		yv	[float!]
		m	[CGAffineTransform! value]
		pt	[red-point2D!]
		x y [float32!]
][
	sy: sx + 1
	xv: get-float sx
	yv: either any [
		sx = center
		TYPE_OF(sy) = TYPE_PAIR
	][0.0][get-float sy]

	m/a: as float32! 1.0
	m/b: as float32! either yv = 0.0 [0.0][tan degree-to-radians yv TYPE_TANGENT]
	m/c: as float32! tan degree-to-radians xv TYPE_TANGENT
	m/d: as float32! 1.0
	m/tx: as float32! 0.0
	m/ty: as float32! 0.0
	GET_PAIR_XY(center x y)
	either pen = -1 [
		if TYPE_OF(center) = TYPE_PAIR [
			_OS-matrix-translate dc/raw x y
		]
		CGContextConcatCTM dc/raw m
		if TYPE_OF(center) = TYPE_PAIR [
			_OS-matrix-translate dc/raw (as float32! 0.0) - x (as float32! 0.0) - y
		]
	][
		dc/matrix: CGAffineTransformConcat dc/matrix m
	]
]

OS-matrix-transform: func [
	dc			[draw-ctx!]
	pen			[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		rotate	[red-integer!]
		center? [logic!]
		pt		[red-point2D!]
		x y		[float32!]
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center

	GET_PAIR_XY(translate x y)
	_OS-matrix-translate dc/raw x y
	OS-matrix-scale dc pen scale center
	OS-matrix-rotate dc pen rotate center
]

OS-draw-state-push: func [dc [draw-ctx!] state [draw-state!]][
	CGContextSaveGState dc/raw
	state/pen-clr: dc/pen-color
	state/brush-clr: dc/brush-color
	state/pen-join: dc/pen-join
	state/pen-cap: dc/pen-cap
	state/pen?: dc/pen?
	state/brush?: dc/brush?
	state/a-pen?: dc/grad-pen?
	state/a-brush?: dc/grad-brush?
]

OS-draw-state-pop: func [dc [draw-ctx!] state [draw-state!]][
	CGContextRestoreGState dc/raw
	dc/pen-color: state/pen-clr
	dc/brush-color: state/brush-clr
	dc/pen-join: state/pen-join
	dc/pen-cap: state/pen-cap
	dc/pen?: state/pen?
	dc/brush?: state/brush?
	dc/grad-pen?: state/a-pen?
	dc/grad-brush?: state/a-brush?
]

OS-matrix-reset: func [
	dc		[draw-ctx!]
	pen		[integer!]
	/local
		ctx	[handle!]
		m	[CGAffineTransform! value]
][
	ctx: dc/raw
	CGContextSetCTM ctx dc/ctx-matrix
]

OS-matrix-invert: func [
	dc		[draw-ctx!]
	pen		[integer!]
	/local
		ctx	[handle!]
		m	[CGAffineTransform! value]
][
	ctx: dc/raw
	m: CGContextGetCTM ctx
	m: CGAffineTransformInvert m
	CGContextSetCTM ctx m
]

OS-matrix-set: func [
	dc		[draw-ctx!]
	pen		[integer!]
	blk		[red-block!]
	/local
		m	[CGAffineTransform! value]
		val	[red-integer!]
][
	val: as red-integer! block/rs-head blk
	m/a: get-float32 val
	m/b: get-float32 val + 1
	m/c: get-float32 val + 2
	m/d: get-float32 val + 3
	m/tx: get-float32 val + 4
	m/ty: get-float32 val + 5
	m: CGAffineTransformConcat m dc/ctx-matrix
	CGContextSetCTM dc/raw m
]

OS-set-matrix-order: func [
	ctx		[draw-ctx!]
	order	[integer!]
][
	0
]

OS-set-clip: func [
	dc		[draw-ctx!]
	upper	[red-pair!]
	lower	[red-pair!]
	rect?	[logic!]
	mode	[integer!]
	/local
		ctx [handle!]
		p   [integer!]
		t	[float32!]
		x1	[float32!]
		x2	[float32!]
		y1	[float32!]
		y2	[float32!]
		rc	[NSRect! value]
		pt	[red-point2D!]
		up-x up-y [float32!]
		lo-x lo-y [float32!]
][
	ctx: dc/raw
	either rect? [
		GET_PAIR_XY(upper up-x up-y)
		GET_PAIR_XY(lower lo-x lo-y)
		if up-x > lo-x [t: up-x up-x: lo-x lo-x: t]
		if up-y > lo-y [t: up-y up-y: lo-y lo-y: t]

		x1: up-x
		y1: up-y
		x2: lo-x
		y2: lo-y
		rc/x: x1
		rc/y: y1
		rc/w: x2 - x1
		rc/h: y2 - y1
		;CGContextBeginPath ctx
		CGContextAddRect ctx rc/x rc/y rc/w rc/h
	][
		p: dc/path
		CGPathCloseSubpath p
		CGContextAddPath ctx p
		CGPathRelease p
	]
	CGContextClip ctx
]

OS-clip-end: func [
	ctx		[draw-ctx!]
][]

;-- shape sub command --

OS-draw-shape-beginpath: func [
	dc          [draw-ctx!]
	draw?		[logic!]
][
	dc/path: CGPathCreateMutable
	CGPathMoveToPoint dc/path null F32_0 F32_0
]

OS-draw-shape-endpath: func [
	dc          [draw-ctx!]
	close?      [logic!]
	return:     [logic!]
	/local
		path	[integer!]
][
	path: dc/path
	if close? [CGPathCloseSubpath path]
	CGContextAddPath dc/raw path
	do-draw-path dc
	CGPathRelease path
	true
]

OS-draw-shape-moveto: func [
	dc      [draw-ctx!]
	coord   [red-pair!]
	rel?    [logic!]
	/local
		x		[float32!]
		y		[float32!]
		pt		[red-point2D!]
][
	GET_PAIR_XY(coord x y)
	if rel? [
		x: dc/last-pt-x + x
		y: dc/last-pt-y + y
	]
	dc/last-pt-x: x
	dc/last-pt-y: y
	dc/shape-curve?: no
	CGPathMoveToPoint dc/path null x y
]

OS-draw-shape-line: func [
	dc          [draw-ctx!]
	start       [red-pair!]
	end         [red-pair!]
	rel?        [logic!]
	/local
		path	[integer!]
		dx		[float32!]
		dy		[float32!]
		x		[float32!]
		y		[float32!]
		pt		[red-point2D!]
][
	path: dc/path
	dx: dc/last-pt-x
	dy: dc/last-pt-y

	until [
		GET_PAIR_XY(start x y)
		if rel? [
			x: x + dx
			y: y + dy
			dx: x
			dy: y
		]
		CGPathAddLineToPoint path null x y
		start: start + 1
		start > end
	]
	dc/last-pt-x: x
	dc/last-pt-y: y
	dc/shape-curve?: no
]

OS-draw-shape-axis: func [
	dc          [draw-ctx!]
	start       [red-value!]
	end         [red-value!]
	rel?        [logic!]
	hline?      [logic!]
	/local
		len		[float32!]
][
	len: get-float32 as red-integer! start
	either hline? [
		dc/last-pt-x: either rel? [dc/last-pt-x + len][len]
	][
		dc/last-pt-y: either rel? [dc/last-pt-y + len][len]
	]
	dc/shape-curve?: no
	CGPathAddLineToPoint dc/path null dc/last-pt-x dc/last-pt-y
]

draw-curve: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
	short?	[logic!]
	num		[integer!]				;--	number of points
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
		pair	[red-pair!]
		pt		[red-point2D!]
][
	while [ start < end ][
		pair: start + 1
		GET_PAIR_XY(start p1x p1y)
		GET_PAIR_XY(pair p2x p2y)
		if num = 3 [					;-- cubic Bézier
			pair: start + 2
			GET_PAIR_XY(pair p3x p3y)
		]

		dx: dc/last-pt-x
		dy: dc/last-pt-y
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
				p1x: dx * (as float32! 2.0) - dc/control-x
				p1y: dy * (as float32! 2.0) - dc/control-y
			][
				;-- if previous command is not curve/curv/qcurve/qcurv, use current point
				p1x: dx
				p1y: dy
			]
			start: start - 1
		]

		dc/shape-curve?: yes
		either num = 3 [				;-- cubic Bézier
			CGPathAddCurveToPoint dc/path null p1x p1y p2x p2y p3x p3y
			dc/control-x: p2x
			dc/control-y: p2y
			dc/last-pt-x: p3x
			dc/last-pt-y: p3y
		][								;-- quadratic Bézier
			CGPathAddQuadCurveToPoint dc/path null p1x p1y p2x p2y
			dc/control-x: p1x
			dc/control-y: p1y
			dc/last-pt-x: p2x
			dc/last-pt-y: p2y
		]
		start: start + num
	]
]

OS-draw-shape-curve: func [
	dc      [draw-ctx!]
	start   [red-pair!]
	end     [red-pair!]
	rel?    [logic!]
][
	draw-curve dc start end rel? no 3
]

OS-draw-shape-qcurve: func [
	dc      [draw-ctx!]
	start   [red-pair!]
	end     [red-pair!]
	rel?    [logic!]
][
	draw-curve dc start end rel? no 2
]

OS-draw-shape-curv: func [
	dc      [draw-ctx!]
	start   [red-pair!]
	end     [red-pair!]
	rel?    [logic!]
][
	draw-curve dc start - 1 end rel? yes 3
]

OS-draw-shape-qcurv: func [
	dc      [draw-ctx!]
	start   [red-pair!]
	end     [red-pair!]
	rel?    [logic!]
][
	draw-curve dc start - 1 end rel? yes 2
]

OS-draw-shape-arc: func [
	ctx		[draw-ctx!]
	end		[red-pair!]
	sweep?	[logic!]
	large?	[logic!]
	rel?	[logic!]
	/local
		item		[red-integer!]
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
		pt1			[CGPoint! value]
		pt2			[CGPoint! value]
		m			[CGAffineTransform! value]
		path		[integer!]
		pt			[red-point2D!]
		end-x end-y [float32!]
][
	;-- parse arguments
	GET_PAIR_XY(end end-x end-y)
	p1-x: ctx/last-pt-x
	p1-y: ctx/last-pt-y
	p2-x: either rel? [ p1-x + end-x ][ end-x ]
	p2-y: either rel? [ p1-y + end-y ][ end-y ]
	ctx/last-pt-x: p2-x
	ctx/last-pt-y: p2-y
	item: as red-integer! end + 1
	radius-x: fabsf get-float32 item
	item: item + 1
	radius-y: fabsf get-float32 item
	item: item + 1
	pi2: as float32! 2.0 * PI
	theta: get-float32 item
	theta: theta * as float32! (PI / 180.0)
	theta: as-float32 fmod as-float theta as-float pi2

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
	m: CGAffineTransformMakeScale (as float32! 1.0) / radius-x (as float32! 1.0) / radius-y
	m: CGAffineTransformRotate m (as float32! 0.0) - theta
	m: CGAffineTransformTranslate m (as float32! 0.0) - center-x (as float32! 0.0) - center-y

	pt1/x: p1-x pt1/y: p1-y
	pt2/x: p2-x pt2/y: p2-y
	pt1: CGPointApplyAffineTransform pt1 m
	pt2: CGPointApplyAffineTransform pt2 m

	;-- calculate angles
	cx: atan2f pt1/y pt1/x
	cy: atan2f pt2/y pt2/x
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
	m: CGAffineTransformMakeTranslation center-x center-y
	m: CGAffineTransformRotate m theta
	m: CGAffineTransformScale m radius-x radius-y
	CGPathAddRelativeArc ctx/path :m as float32! 0.0 as float32! 0.0 as float32! 1.0 cx angle-len
]

OS-draw-shape-close: func [
	ctx		[draw-ctx!]
][
	CGPathCloseSubpath ctx/path
]

OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	img		[red-image!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
	/local
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
		texture	[integer!]
		wrap	[integer!]
		result	[integer!]
][
]

draw-pattern-callback: func [
	[cdecl]
	info	[int-ptr!]
	ctx		[handle!]
	/local
		dc	[draw-ctx!]
		w	[float32!]
		h	[float32!]
		blk [red-block!]
		m	[CGAffineTransform! value]
		wrap [integer!]
][
	dc: as draw-ctx! info
	wrap: dc/pattern-mode
	blk: as red-block! dc/pattern-blk
	w: dc/pattern-w
	h: dc/pattern-h
	do-draw ctx null blk no no yes yes
	if wrap = flip-x [
		CGContextScaleCTM ctx as float32! -1.0 F32_1
		do-draw ctx null blk no no yes yes
	]
	if wrap = flip-y [
		m: CGAffineTransformMake F32_1 F32_0 F32_0 as float32! -1.0 w h
		CGContextConcatCTM ctx m
		do-draw ctx null blk no no yes yes
	]
	if wrap = flip-xy [0]
]

OS-draw-brush-pattern: func [
	dc		[draw-ctx!]
	size	[red-pair!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	block	[red-block!]
	brush?	[logic!]
	/local
		x xx		[float32!]
		y yy		[float32!]
		w			[float32!]
		h			[float32!]
		wrap		[integer!]
		ctx			[handle!]
		pattern		[integer!]
		space		[integer!]
		rc			[NSRect! value]
		m			[CGAffineTransform! value]
		alpha		[float32!]
		width		[float32!]
		height		[float32!]
		callbacks	[CGPatternCallbacks!]
		pt			[red-point2D!]
][
	dc/pattern-blk: as int-ptr! block
	ctx: dc/raw
	alpha: as float32! 1.0
	GET_PAIR_XY(size w h)
	either crop-1 = null [
		x: F32_0
		y: F32_0
	][
		GET_PAIR_XY(crop-1 x y)
	]
	either crop-2 = null [
		w: w - x
		h: h - y
	][
		GET_PAIR_XY(crop-2 xx yy)
		w: either ( x + xx ) > w [ w - x ][ xx ]
		h: either ( y + yy ) > h [ h - y ][ yy ]
	]

	wrap: tile
	unless mode = null [wrap: symbol/resolve mode/symbol]
	dc/pattern-mode: wrap
	case [
		any [wrap = flip-x wrap = flip-y] [w: w * (as float32! 2.0)]
		wrap = flip-xy [w: w * (as float32! 2.0) h: h * (as float32! 2.0)]
		true []
	]

	space: CGColorSpaceCreatePattern 0
	CGContextSetFillColorSpace ctx space
	CGColorSpaceRelease space

	callbacks: as CGPatternCallbacks! :dc/pattern-ver
	callbacks/version: 0
	callbacks/drawPattern: as-integer :draw-pattern-callback
	callbacks/releaseInfo: 0

	width: w
	height: h
	dc/pattern-w: width
	dc/pattern-h: height
	rc/x: x
	rc/y: y
	rc/w: width
	rc/h: height
	m: CGAffineTransformMake F32_1 F32_0 F32_0 as float32! -1.0 F32_0 height
	pattern: CGPatternCreate as int-ptr! dc rc m width height 0 yes callbacks
	either brush? [
		dc/brush?: yes
		CGContextSetFillPattern ctx pattern :alpha
	][
		dc/pen?: yes
		CGContextSetStrokePattern ctx pattern :alpha
	]
	CGPatternRelease pattern

	if dc/grad-pen <> -1 [
		CGGradientRelease dc/grad-pen
		dc/grad-pos?: no
		dc/grad-pen: -1
	]
]

OS-draw-shadow: func [
	ctx		[draw-ctx!]
	offset	[red-pair!]
	blur	[integer!]
	spread	[integer!]
	color	[integer!]
	inset?	[logic!]
][0]