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

#define DRAW_FLOAT_MAX		[as Cocoa-float! 3.4e38]

#either ABI = 'apple-aarch64 [
	#define sqrtf sqrt
	#define sinf sin
	#define cosf cos
	#define atan2f atan2
	#define fabsf fabs
	#define GET_COCOA_XY(_pair fx fy) [
		either PAIR_TYPE?(_pair) [
			fx: as float! _pair/x
			fy: as float! _pair/y
		][
			pt: as red-point2D! _pair
			fx: as float! pt/x
			fy: as float! pt/y
		]
	]
][
	#define GET_COCOA_XY(_pair fx fy) [GET_PAIR_XY(_pair fx fy)]
]

max-colors: 256												;-- max number of colors for gradient
max-edges: 1000												;-- max number of edges for a polygon
edges: as CGPoint! allocate max-edges * (size? CGPoint!)	;-- polygone edges buffer
colors: as Cocoa-float-ptr! allocate 5 * max-colors * (size? Cocoa-float!)
colors-pos: colors + (4 * max-colors)

draw-state!: alias struct! [
	pen-clr		[integer!]
	brush-clr	[integer!]
	font-attrs	[Cocoa-handle!]
	pen-join	[integer!]
	pen-cap		[integer!]
	pen?		[logic!]
	brush?		[logic!]
	a-pen?		[logic!]
	a-brush?	[logic!]
	font-clr?	[logic!]
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
		nscolor [Cocoa-handle!]
		objects	[Cocoa-handle-array!]
		keys	[Cocoa-handle-array!]
		saved	[int-ptr!]
		m		[CGAffineTransform!]
][
	unless pattern? [
		CGContextSaveGState CGCtx

		either on-graphic? [							;-- draw on image!, flip the CTM
			rc: as NSRect! img
			ctx/rect-y: rc/y
			CGContextTranslateCTM CGCtx as Cocoa-float! 0.0 rc/y
			CGContextScaleCTM CGCtx as Cocoa-float! 1.0 as Cocoa-float! -1.0
		][
			CGContextTranslateCTM CGCtx as Cocoa-float! 0.5 as Cocoa-float! 0.5
		]
	]

	ctx/raw:			CGCtx
	ctx/ctx-matrix:		CGContextGetCTM CGCtx
	ctx/matrix/a:		as Cocoa-float! 1.0
	ctx/matrix/b:		as Cocoa-float! 0.0
	ctx/matrix/c:		as Cocoa-float! 0.0
	ctx/matrix/d:		as Cocoa-float! 1.0
	ctx/matrix/tx:		as Cocoa-float! 0.0
	ctx/matrix/ty:		as Cocoa-float! 0.0
	ctx/pen-width:		as Cocoa-float! 1.0
	ctx/pen-style:		0
	ctx/pen-color:		0						;-- default: black
	ctx/pen-join:		miter
	ctx/pen-cap:		flat
	ctx/brush-color:	-1
	ctx/grad-pen:		0
	ctx/pen?:			yes
	ctx/brush?:			no
	ctx/font-color?:	no
	ctx/grad-pos?:		no
	ctx/colorspace:		CGColorSpaceCreateDeviceRGB
	ctx/last-pt-x:		as Cocoa-float! 0.0
	ctx/last-pt-y:		as Cocoa-float! 0.0
	ctx/on-image?:		on-graphic?

	objects: declare Cocoa-handle-array!
	keys: declare Cocoa-handle-array!
	objects/v1: default-font
	keys/v1: NSFontAttributeName
	ctx/font-attrs: make-NSDictionary objects keys as NSUInteger! 1

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
	if dc/grad-pen <> 0 [CGGradientRelease dc/grad-pen]
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
		GET_COCOA_XY(pair p/x p/y)
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
		r  [Cocoa-float!]
		g  [Cocoa-float!]
		b  [Cocoa-float!]
		a  [Cocoa-float!]
][
	r: (as Cocoa-float! color and FFh) / 255.0
	g: (as Cocoa-float! color >> 8 and FFh) / 255.0
	b: (as Cocoa-float! color >> 16 and FFh) / 255.0
	a: (as Cocoa-float! 255 - (color >>> 24)) / 255.0
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
		clr		[Cocoa-handle!]
		attrs	[Cocoa-handle!]
][
	clr: rs-to-NSColor color
	attrs: objc_msgSend [dc/font-attrs sel_getUid "mutableCopy"]
	if zero? objc_msgSend [attrs sel_getUid "objectForKey:" NSFontAttributeName][
		objc_msgSend [attrs sel_getUid "setObject:forKey:" default-font NSFontAttributeName]
	]
	objc_msgSend [attrs sel_getUid "setObject:forKey:" clr NSForegroundColorAttributeName]
	objc_msgSend [dc/font-attrs sel_release]
	dc/font-attrs: attrs
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
		unless dc/font-color? [_set-font-color dc color]
	]
]

OS-draw-fill-pen: func [
	dc	   [draw-ctx!]
	color  [integer!]									;-- aabbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	if dc/grad-pen <> 0 [
		CGGradientRelease dc/grad-pen
		dc/grad-pos?: no
		dc/grad-pen: 0
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
		width-v	[Cocoa-float!]
][
	width-v: F32_TO_COCOA get-float32 as red-integer! width
	if width-v <= (as Cocoa-float! 0.0) [width-v: as Cocoa-float! 1.0]
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
		dashes	[Cocoa-float-ptr!]
		pf		[Cocoa-float-ptr!]
][
	cnt: (as-integer end - start) / 16 + 1
	dashes: null
	if cnt > 0 [
		dashes: as Cocoa-float-ptr! system/stack/allocate cnt
		pf: dashes
		while [start <= end][
			pf/1: as Cocoa-float! start/value
			pf: pf + 1
			start: start + 1
		]
	]
	CGContextSetLineDash dc/raw as Cocoa-float! 0.0 dashes cnt
]

get-shape-center: func [
	start			[CGPoint!]
	count			[integer!]
	cx				[Cocoa-float-ptr!]
	cy				[Cocoa-float-ptr!]
	d				[Cocoa-float-ptr!]
	/local
		point		[CGPoint!]
		dx			[Cocoa-float!]
		dy			[Cocoa-float!]
		x0			[Cocoa-float!]
		y0			[Cocoa-float!]
		x1			[Cocoa-float!]
		y1			[Cocoa-float!]
		a			[Cocoa-float!]
		r			[Cocoa-float!]
		signedArea	[Cocoa-float!]
		centroid-x	[Cocoa-float!]
		centroid-y	[Cocoa-float!]
][
	;-- implementation taken from http://stackoverflow.com/questions/2792443/finding-the-centroid-of-a-polygon
	signedArea: as Cocoa-float! 0.0
	centroid-x: as Cocoa-float! 0.0 centroid-y: as Cocoa-float! 0.0
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

	signedArea: signedArea * as Cocoa-float! 0.5
	centroid-x: centroid-x / (signedArea * as Cocoa-float! 6.0)
	centroid-y: centroid-y / (signedArea * as Cocoa-float! 6.0)

	cx/value: centroid-x
	cy/value: centroid-y

	if d <> null [
		;-- take biggest distance
		d/value: as Cocoa-float! 0.0
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
		cx		[Cocoa-float!]
		cy		[Cocoa-float!]
		d		[Cocoa-float!]
		rc		[NSRect! value]
][
	cx: as Cocoa-float! 0.0 cy: as Cocoa-float! 0.0 d: as Cocoa-float! 0.0
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
	upper-x		[Cocoa-float!]
	upper-y		[Cocoa-float!]
	lower-x		[Cocoa-float!]
	lower-y		[Cocoa-float!]
	/local
		type	[integer!]
		dx		[Cocoa-float!]
		dy		[Cocoa-float!]
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
			dx: lower-x - upper-x + as Cocoa-float! 1.0
			dy: lower-y - upper-y + as Cocoa-float! 1.0
			dx: dx / as Cocoa-float! 2.0
			dy: dy / as Cocoa-float! 2.0
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
		t		[Cocoa-float!]
		radius	[red-integer!]
		rad		[Cocoa-float!]
		x1		[Cocoa-float!]
		x2		[Cocoa-float!]
		xm		[Cocoa-float!]
		ym		[Cocoa-float!]
		y1		[Cocoa-float!]
		y2		[Cocoa-float!]
		width	[Cocoa-float!]
		height	[Cocoa-float!]
		pt		[red-point2D!]
		ux uy lx ly [Cocoa-float!]
][
	ctx: dc/raw
	radius: null
	if upper + 2 = lower [
		radius: as red-integer! lower
		lower:  lower - 1
	]
	GET_COCOA_XY(upper ux uy)
	GET_COCOA_XY(lower lx ly)
	if ux > lx [t: ux ux: lx lx: t]
	if uy > ly [t: uy uy: ly ly: t]

	x1: ux
	y1: uy
	x2: lx
	y2: ly
	xm: x1 + (x2 - x1 / as Cocoa-float! 2.0)
	ym: y1 + (y2 - y1 / as Cocoa-float! 2.0)

	either radius <> null [
		width: lx - ux
		height: ly - uy
		t: either width > height [height][width]
		rad: F32_TO_COCOA get-float32 radius
		if (rad * as Cocoa-float! 2.0) > t [rad: t / as Cocoa-float! 2.0]
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
		path [Cocoa-handle!]
][
	ctx: dc/raw
	either dc/grad-pen = 0 [
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
		GET_COCOA_XY(start point/x point/y)
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
		GET_COCOA_XY(pair point/x point/y)
		nb: nb + 1
		point: point + 1
		pair: pair + 1
	]
	;if nb = max-edges [fire error]
	GET_COCOA_XY(start point/x point/y)			;-- close the polygon

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
		x		[Cocoa-float!]
		y		[Cocoa-float!]
		delta	[Cocoa-float!]
		t		[Cocoa-float!]
		t2		[Cocoa-float!]
		t3		[Cocoa-float!]
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
		GET_COCOA_XY(start p/x p/y)			;-- duplicate first point
		p: p + 1
	]
	while [start <= end][
		GET_COCOA_XY(start p/x p/y)
		p: p + 1
		start: start + 1
	]
	unless closed? [
		GET_COCOA_XY(end p/x p/y)			;-- duplicate end point
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
	delta: (as Cocoa-float! 1.0) / (as Cocoa-float! 25.0)

	while [i < count][						;-- CatmullRom Spline, tension = 0.5
		p0: p + (i % num)
		p1: p + (i + 1 % num)
		p2: p + (i + 2 % num)
		p3: p + (i + 3 % num)

		t: as Cocoa-float! 0.0
		n: 0
		until [
			t: t + delta
			t2: t * t
			t3: t2 * t
			x: (as Cocoa-float! 2.0) * p1/x + (p2/x - p0/x * t) +
			   (((as Cocoa-float! 2.0) * p0/x - ((as Cocoa-float! 5.0) * p1/x) + ((as Cocoa-float! 4.0) * p2/x) - p3/x) * t2) +
			   ((as Cocoa-float! 3.0) * (p1/x - p2/x) + p3/x - p0/x * t3) * 0.5
			y: (as Cocoa-float! 2.0) * p1/y + (p2/y - p0/y * t) +
			   (((as Cocoa-float! 2.0) * p0/y - ((as Cocoa-float! 5.0) * p1/y) + ((as Cocoa-float! 4.0) * p2/y) - p3/y) * t2) +
			   ((as Cocoa-float! 3.0) * (p1/y - p2/y) + p3/y - p0/y * t3) * 0.5
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
	x		[Cocoa-float!]
	y		[Cocoa-float!]
	w		[Cocoa-float!]
	h		[Cocoa-float!]
	/local
		dx	[Cocoa-float!]
		dy	[Cocoa-float!]
][
	CGContextAddEllipseInRect dc/raw x y w h
	if dc/grad-pos? [
		either dc/grad-type = linear [
			dc/grad-x1: x
			dc/grad-x2: x + w
			dc/grad-y1: y
			dc/grad-y2: y
		][
			dx: w / as Cocoa-float! 2.0
			dy: h / as Cocoa-float! 2.0
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
		rad-x [Cocoa-float!]
		rad-y [Cocoa-float!]
		w	  [Cocoa-float!]
		h	  [Cocoa-float!]
		cx cy [Cocoa-float!]
		f	  [red-float!]
		pt	  [red-point2D!]
][
	rad-x: F32_TO_COCOA get-float32 radius
	rad-y: rad-x
	if center + 2 = radius [	;-- center, radius-x, radius-y
		radius: radius - 1
		rad-x: F32_TO_COCOA get-float32 radius
	]
	w: rad-x * as Cocoa-float! 2.0
	h: rad-y * as Cocoa-float! 2.0

	GET_COCOA_XY(center cx cy)
	do-draw-ellipse dc cx - rad-x cy - rad-y w h
]

OS-draw-ellipse: func [
	dc	  	 [draw-ctx!]
	upper	 [red-pair!]
	diameter [red-pair!]
	/local
		pt	 [red-point2D!]
		ux uy dx dy [Cocoa-float!]
][
	GET_COCOA_XY(upper ux uy)
	GET_COCOA_XY(diameter dx dy)
	do-draw-ellipse dc ux uy dx dy
]

OS-draw-font: func [
	dc		[draw-ctx!]
	font	[red-object!]
	/local
		clr [red-tuple!]
][
	objc_msgSend [dc/font-attrs sel_release]
	dc/font-attrs: make-font-attrs font as red-object! none-value -1
	clr: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
	either TYPE_OF(clr) = TYPE_TUPLE [
		dc/font-color?: yes
		_set-font-color dc get-tuple-color clr
	][
		dc/font-color?: no
		_set-font-color dc dc/pen-color
	]
]

draw-text-at: func [
	ctx		[handle!]
	text	[red-string!]
	attrs	[Cocoa-handle!]
	x		[Cocoa-float!]
	y		[Cocoa-float!]
	/local
		str		[Cocoa-handle!]
		attr	[Cocoa-handle!]
		line	[Cocoa-handle!]
		delta	[Cocoa-float!]
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
		layout	[Cocoa-handle!]
		tc		[Cocoa-handle!]
		idx		[integer!]
		len		[integer!]
		cg-pt	[CGPoint! value]
		clr		[Cocoa-handle!]
		range	[NSRange! value]
		size	[red-pair!]
		color	[red-tuple!]
		pt		[red-point2D!]
		w h		[Cocoa-float!]
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
		clr: either null? dc [as Cocoa-handle! 0][
			objc_msgSend [dc/font-attrs sel_getUid "objectForKey:" NSForegroundColorAttributeName]
		]
		OS-text-box-layout tbox null clr catch?
	]

	layout: get-text-box-state-handle state 0
	tc: get-text-box-state-handle state 1

	range: objc_msgSend_range [layout sel_getUid "glyphRangeForTextContainer:" tc]
	idx: as integer! range/idx
	len: as integer! range/len
	GET_COCOA_XY(pos cg-pt/x cg-pt/y)
	size: as red-pair! values + FACE_OBJ_SIZE
	color: as red-tuple! values + FACE_OBJ_COLOR
	if all [
		TYPE_OF(color) = TYPE_TUPLE
		ANY_COORD?(size)
	][
		GET_COCOA_XY(size w h)
		CG-set-color dc/raw get-tuple-color color yes
		CGContextFillRect dc/raw cg-pt/x cg-pt/y w h
	]
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
		x y [Cocoa-float!]
][
	ctx: dc/raw
	either TYPE_OF(text) = TYPE_STRING [
		GET_COCOA_XY(pos x y)
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
	cx		[Cocoa-float!]
	cy		[Cocoa-float!]
	rx		[Cocoa-float!]
	ry		[Cocoa-float!]
	alpha	[Cocoa-float!]
	beta	[Cocoa-float!]
	start?	[logic!]
	closed? [logic!]
	/local
		delta	[Cocoa-float!]
		bcp		[Cocoa-float!]
		pi32	[Cocoa-float!]
		sin-a	[Cocoa-float!]
		sin-b	[Cocoa-float!]
		cos-a	[Cocoa-float!]
		cos-b	[Cocoa-float!]
		sx		[Cocoa-float!]
		sy		[Cocoa-float!]
][
	pi32: as Cocoa-float! PI

	;-- adjust angles for ellipses
	alpha: atan2f (sinf alpha) * rx (cosf alpha) * ry
	beta:  atan2f (sinf beta)  * rx (cosf beta) * ry

	if pi32 < fabsf beta - alpha [
		either beta > alpha [
			beta: beta - (pi32 * as Cocoa-float! 2.0)
		][
			alpha: alpha - (pi32 * as Cocoa-float! 2.0)
		]
	]
	delta: beta - alpha / as Cocoa-float! 2.0
	bcp: as Cocoa-float! (4.0 / 3.0 * (1.0 - cos as float! delta) / sin as float! delta)

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
		cx			[Cocoa-float!]
		cy			[Cocoa-float!]
		rad-x		[Cocoa-float!]
		rad-y		[Cocoa-float!]
		angle-begin [Cocoa-float!]
		angle-end	[Cocoa-float!]
		delta		[Cocoa-float!]
		rad			[Cocoa-float!]
		current		[Cocoa-float!]
		drawn		[Cocoa-float!]
		sweep		[integer!]
		i			[integer!]
		closed?		[logic!]
		pt			[red-point2D!]
][
	ctx: dc/raw
	GET_COCOA_XY(center cx cy)
	rad: (as Cocoa-float! PI) / as Cocoa-float! 180.0

	radius: center + 1
	GET_COCOA_XY(radius rad-x rad-y)
	begin: as red-integer! radius + 1
	angle-begin: rad * as Cocoa-float! begin/value
	angle: begin + 1
	sweep: angle/value
	i: begin/value + sweep
	angle-end: rad * as Cocoa-float! i

	closed?: angle < end

	CGContextBeginPath ctx
	if closed? [CGContextMoveToPoint ctx cx cy]
	either any [sweep >= 360 sweep <= -360][
		CGContextAddEllipseInRect ctx cx - rad-x cy - rad-y rad-x * as Cocoa-float! 2.0 rad-y * as Cocoa-float! 2.0
	][
		either rad-x <> rad-y [								;-- elliptical arc
			delta: as Cocoa-float! (PI / 2.0)
			drawn: as Cocoa-float! 0.0
			i: 0
			until [
				current: angle-begin + drawn
				rad: angle-end - current
				either rad > delta [rad: delta][
					if rad <= as Cocoa-float! 0.000001 [break]
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
		cp1x  [Cocoa-float!]
		cp1y  [Cocoa-float!]
		cp2x  [Cocoa-float!]
		cp2y  [Cocoa-float!]
		p2	  [red-pair!]
		p3	  [red-pair!]
		pt	  [red-point2D!]
		sx sy [Cocoa-float!]
		p2x p2y p3x p3y [Cocoa-float!]
][
	ctx: dc/raw
	p2: start + 1
	p3: start + 2
	GET_COCOA_XY(p2 p2x p2y)
	GET_COCOA_XY(p3 p3x p3y)
	GET_COCOA_XY(start sx sy)

	either 2 = ((as-integer end - start) >> 4) [		;-- p0, p1, p2  -->  p0, (p0 + 2p1) / 3, (2p1 + p2) / 3, p2
		cp1x: (p2x * as Cocoa-float! 2.0) + sx / as Cocoa-float! 3.0
		cp1y: (p2y * as Cocoa-float! 2.0) + sy / as Cocoa-float! 3.0
		cp2x: (p2x * as Cocoa-float! 2.0) + p3x / as Cocoa-float! 3.0
		cp2y: (p2y * as Cocoa-float! 2.0) + p3y / as Cocoa-float! 3.0
	][
		cp1x: p2x
		cp1y: p2y
		cp2x: p3x
		cp2y: p3y
	]

	CGContextBeginPath ctx
	CGContextMoveToPoint ctx sx sy
	GET_COCOA_XY(end sx sy)
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
	image		[Cocoa-handle!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		tx		[Cocoa-float!]
		ty		[Cocoa-float!]
		w		[Cocoa-float!]
		h		[Cocoa-float!]
		flip-x	[Cocoa-float!]
		flip-y	[Cocoa-float!]
][
	either width < 0 [
		w: as Cocoa-float! 0 - width
		flip-x: as Cocoa-float! -1.0
	][
		w: as Cocoa-float! width
		flip-x: as Cocoa-float! 1.0
	]
	tx: as Cocoa-float! x
	either height < 0 [
		h: as Cocoa-float! 0 - height
		flip-y: as Cocoa-float! 1.0
	][
		h: as Cocoa-float! height
		flip-y: as Cocoa-float! -1.0
	]
	ty: as Cocoa-float! y + height
	;-- flip coords
	;; drawing an image or PDF by calling Core Graphics functions directly,
	;; we must flip the CTM.
	;; http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
	CGContextTranslateCTM dc tx ty
	CGContextScaleCTM dc flip-x flip-y

	CGContextDrawImage dc as Cocoa-float! 0.0 as Cocoa-float! 0.0 w h image

	;-- flip back
	CGContextScaleCTM dc flip-x flip-y
	CGContextTranslateCTM dc (as Cocoa-float! 0.0) - tx (as Cocoa-float! 0.0) - ty
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
		handle	[Cocoa-handle!]
		pt		[red-point2D!]
][
	either any [
		start + 2 = end
		start + 3 = end
	][
		x: 0 y: 0 w: 0 h: 0
		image/any-resize src dst crop1 start end :x :y :w :h
		if dst/header = TYPE_NONE [return 0]
		handle: as Cocoa-handle! OS-image/to-cgimage dst
		CG-draw-image dc/raw handle x y w h
		OS-image/delete resolve-node dst/node
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
		handle: as Cocoa-handle! OS-image/to-cgimage src
		unless null? crop1 [
			handle: CGImageCreateWithImageInRect handle
						as Cocoa-float! crop.x as Cocoa-float! crop.y
						as Cocoa-float! crop.w as Cocoa-float! crop.h
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
			as Cocoa-float! 0.0
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
		color	[Cocoa-float-ptr!]
		pos		[Cocoa-float-ptr!]
		last-c	[Cocoa-float-ptr!]
		last-p	[Cocoa-float-ptr!]
		int		[red-integer!]
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		n		[integer!]
		delta	[Cocoa-float!]
		p		[Cocoa-float!]
		angle	[Cocoa-float!]
		sx		[Cocoa-float!]
		sy		[Cocoa-float!]
		rotate? [logic!]
		scale?	[logic!]
		pt		[red-point2D!]
][
	dc/matrix: CGAffineTransformMake 1.0 0.0 0.0 1.0 0.0 0.0
	dc/grad-type: type
	dc/grad-spread: spread
	GET_COCOA_XY(offset dc/grad-x1 dc/grad-y1)

	int: as red-integer! offset + 1
	sx: as Cocoa-float! int/value
	int: int + 1
	sy: as Cocoa-float! int/value

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
	sy: as Cocoa-float! 1.0
	while [
		int: int + 1
		n < 3
	][										;-- fetch angle, scale-x and scale-y (optional)
		switch TYPE_OF(int) [
			TYPE_INTEGER	[p: as Cocoa-float! int/value]
			TYPE_FLOAT		[f: as red-float! int p: as Cocoa-float! f/value]
			default			[break]
		]
		switch n [
			0	[if p <> (as Cocoa-float! 0.0) [angle: p rotate?: yes]]
			1	[if p <> (as Cocoa-float! 1.0) [sx: p scale?: yes]]
			2	[if p <> (as Cocoa-float! 1.0) [sy: p scale?: yes]]
		]
		n: n + 1
	]
	if rotate? [
		p: (as Cocoa-float! PI) / (as Cocoa-float! 180.0)
		dc/matrix: CGAffineTransformRotate dc/matrix p * angle
	]
	if scale? [
		dc/matrix: CGAffineTransformScale dc/matrix sx sy
	]

	color: colors + 4
	pos: colors-pos + 1
	delta: as Cocoa-float! count - 1
	delta: (as Cocoa-float! 1.0) / delta
	p: as Cocoa-float! 0.0
	head: as red-value! int

	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		val: get-tuple-color clr
		color/1: (as Cocoa-float! val and FFh) / 255.0
		color/2: (as Cocoa-float! val >> 8 and FFh) / 255.0
		color/3: (as Cocoa-float! val >> 16 and FFh) / 255.0
		color/4: (as Cocoa-float! 255 - (val >>> 24)) / 255.0
		next: head + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: as Cocoa-float! f/value]
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

	if pos/value > as Cocoa-float! 0.0 [			;-- first one should be always 0.0
		colors-pos/value: as Cocoa-float! 0.0
		colors/1: color/1
		colors/2: color/2
		colors/3: color/3
		colors/4: color/4
		color: colors
		pos: colors-pos
		count: count + 1
	]

	if dc/grad-pen <> 0 [CGGradientRelease dc/grad-pen]
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
		color	[Cocoa-float-ptr!]
		last-c	[Cocoa-float-ptr!]
		pos		[Cocoa-float-ptr!]
		last-p	[Cocoa-float-ptr!]
		delta	[Cocoa-float!]
		p		[Cocoa-float!]
		pair	[red-pair!]
		pt		[red-point2D!]
		val		[integer!]
		x y		[Cocoa-float!]
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
	delta: as Cocoa-float! count - 1
	delta: (as Cocoa-float! 1.0) / delta
	p: as Cocoa-float! 0.0
	head: stops
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		val: get-tuple-color clr
		color/1: (as Cocoa-float! val and FFh) / 255.0
		color/2: (as Cocoa-float! val >> 8 and FFh) / 255.0
		color/3: (as Cocoa-float! val >> 16 and FFh) / 255.0
		color/4: (as Cocoa-float! 255 - (val >>> 24)) / 255.0
		next: head + 1
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: as Cocoa-float! f/value]
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

	if pos/value > as Cocoa-float! 0.0 [			;-- first one should be always 0.0
		colors-pos/value: as Cocoa-float! 0.0
		colors/1: color/1
		colors/2: color/2
		colors/3: color/3
		colors/4: color/4
		color: colors
		pos: colors-pos
		count: count + 1
	]

	if ctx/grad-pen <> 0 [CGGradientRelease ctx/grad-pen]
	ctx/grad-pen: CGGradientCreateWithColorComponents ctx/colorspace color pos count

	;-- positions
	unless skip-pos? [
		pair: as red-pair! positions
		GET_COCOA_XY(pair x y)
		ctx/grad-x1: x ctx/grad-y1: y
		either type = linear [
			pair: pair + 1
			GET_COCOA_XY(pair x y)
			ctx/grad-x2: x ctx/grad-y2: y
		][
			either type = radial [
				ctx/grad-radius: F32_TO_COCOA get-float32 as red-integer! positions + 1
				if focal? [
					pair: as red-pair! ( positions + 2 )
					GET_COCOA_XY(pair x y)
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
		rad [Cocoa-float!]
		x y [Cocoa-float!]
][
	ctx: dc/raw
	rad: (as Cocoa-float! PI) / (as Cocoa-float! 180.0) * (F32_TO_COCOA get-float32 angle)
	GET_COCOA_XY(center x y)
	either pen = -1 [
		if angle <> as red-integer! center [
			_OS-matrix-translate ctx x y
		]
		CGContextRotateCTM ctx rad
		if angle <> as red-integer! center [
			_OS-matrix-translate ctx (as Cocoa-float! 0.0) - x (as Cocoa-float! 0.0) - y
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
		x y [Cocoa-float!]
][
	GET_COCOA_XY(center x y)
	sy: sx + 1
	either pen = -1 [
		if TYPE_OF(center) = TYPE_PAIR [
			_OS-matrix-translate dc/raw x y
		]
		CGContextScaleCTM dc/raw F32_TO_COCOA get-float32 sx F32_TO_COCOA get-float32 sy
		if TYPE_OF(center) = TYPE_PAIR [
			_OS-matrix-translate dc/raw (as Cocoa-float! 0.0) - x (as Cocoa-float! 0.0) - y
		]
	][
		dc/matrix: CGAffineTransformScale dc/matrix F32_TO_COCOA get-float32 sx F32_TO_COCOA get-float32 sy
	]
]

_OS-matrix-translate: func [
	ctx [handle!]
	x	[Cocoa-float!]
	y	[Cocoa-float!]
][
	CGContextTranslateCTM ctx x y
]

OS-matrix-translate: func [
	dc	[draw-ctx!]
	pen [integer!]
	pos [red-pair!]
	/local
		pt [red-point2D!]
		x y [Cocoa-float!]
][
	GET_COCOA_XY(pos x y)
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
		x y [Cocoa-float!]
][
	sy: sx + 1
	xv: get-float sx
	yv: either any [
		sx = center
		TYPE_OF(sy) = TYPE_PAIR
	][0.0][get-float sy]

	m/a: as Cocoa-float! 1.0
	m/b: as Cocoa-float! either yv = 0.0 [0.0][tan degree-to-radians yv TYPE_TANGENT]
	m/c: as Cocoa-float! tan degree-to-radians xv TYPE_TANGENT
	m/d: as Cocoa-float! 1.0
	m/tx: as Cocoa-float! 0.0
	m/ty: as Cocoa-float! 0.0
	GET_COCOA_XY(center x y)
	either pen = -1 [
		if TYPE_OF(center) = TYPE_PAIR [
			_OS-matrix-translate dc/raw x y
		]
		CGContextConcatCTM dc/raw m
		if TYPE_OF(center) = TYPE_PAIR [
			_OS-matrix-translate dc/raw (as Cocoa-float! 0.0) - x (as Cocoa-float! 0.0) - y
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
		x y		[Cocoa-float!]
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center

	GET_COCOA_XY(translate x y)
	_OS-matrix-translate dc/raw x y
	OS-matrix-scale dc pen scale center
	OS-matrix-rotate dc pen rotate center
]

OS-draw-state-push: func [dc [draw-ctx!] state [draw-state!]][
	CGContextSaveGState dc/raw
	state/pen-clr: dc/pen-color
	state/brush-clr: dc/brush-color
	state/font-attrs: dc/font-attrs
	state/pen-join: dc/pen-join
	state/pen-cap: dc/pen-cap
	state/pen?: dc/pen?
	state/brush?: dc/brush?
	state/a-pen?: dc/grad-pen?
	state/a-brush?: dc/grad-brush?
	state/font-clr?: dc/font-color?
	objc_msgSend [state/font-attrs sel_getUid "retain"]
]

OS-draw-state-pop: func [dc [draw-ctx!] state [draw-state!]][
	CGContextRestoreGState dc/raw
	dc/pen-color: state/pen-clr
	dc/brush-color: state/brush-clr
	objc_msgSend [dc/font-attrs sel_release]
	dc/font-attrs: state/font-attrs
	dc/pen-join: state/pen-join
	dc/pen-cap: state/pen-cap
	dc/pen?: state/pen?
	dc/brush?: state/brush?
	dc/grad-pen?: state/a-pen?
	dc/grad-brush?: state/a-brush?
	dc/font-color?: state/font-clr?
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
	m/a: F32_TO_COCOA get-float32 val
	m/b: F32_TO_COCOA get-float32 val + 1
	m/c: F32_TO_COCOA get-float32 val + 2
	m/d: F32_TO_COCOA get-float32 val + 3
	m/tx: F32_TO_COCOA get-float32 val + 4
	m/ty: F32_TO_COCOA get-float32 val + 5
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
		p   [Cocoa-handle!]
		t	[Cocoa-float!]
		x1	[Cocoa-float!]
		x2	[Cocoa-float!]
		y1	[Cocoa-float!]
		y2	[Cocoa-float!]
		rc	[NSRect! value]
		pt	[red-point2D!]
		up-x up-y [Cocoa-float!]
		lo-x lo-y [Cocoa-float!]
][
	ctx: dc/raw
	either rect? [
		GET_COCOA_XY(upper up-x up-y)
		GET_COCOA_XY(lower lo-x lo-y)
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
	CGPathMoveToPoint dc/path null 0.0 0.0
]

OS-draw-shape-endpath: func [
	dc          [draw-ctx!]
	close?      [logic!]
	return:     [logic!]
	/local
		path	[Cocoa-handle!]
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
		x		[Cocoa-float!]
		y		[Cocoa-float!]
		pt		[red-point2D!]
][
	GET_COCOA_XY(coord x y)
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
		path	[Cocoa-handle!]
		dx		[Cocoa-float!]
		dy		[Cocoa-float!]
		x		[Cocoa-float!]
		y		[Cocoa-float!]
		pt		[red-point2D!]
][
	path: dc/path
	dx: dc/last-pt-x
	dy: dc/last-pt-y

	until [
		GET_COCOA_XY(start x y)
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
		len		[Cocoa-float!]
][
	len: F32_TO_COCOA get-float32 as red-integer! start
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
		dx		[Cocoa-float!]
		dy		[Cocoa-float!]
		p3y		[Cocoa-float!]
		p3x		[Cocoa-float!]
		p2y		[Cocoa-float!]
		p2x		[Cocoa-float!]
		p1y		[Cocoa-float!]
		p1x		[Cocoa-float!]
		pf		[Cocoa-float-ptr!]
		pair	[red-pair!]
		pt		[red-point2D!]
][
	while [ start < end ][
		pair: start + 1
		GET_COCOA_XY(start p1x p1y)
		GET_COCOA_XY(pair p2x p2y)
		if num = 3 [					;-- cubic Bézier
			pair: start + 2
			GET_COCOA_XY(pair p3x p3y)
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
				p1x: dx * (as Cocoa-float! 2.0) - dc/control-x
				p1y: dy * (as Cocoa-float! 2.0) - dc/control-y
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
		center-x	[Cocoa-float!]
		center-y	[Cocoa-float!]
		cx			[Cocoa-float!]
		cy			[Cocoa-float!]
		cf			[Cocoa-float!]
		angle-len	[Cocoa-float!]
		radius-x	[Cocoa-float!]
		radius-y	[Cocoa-float!]
		theta		[Cocoa-float!]
		X1			[Cocoa-float!]
		Y1			[Cocoa-float!]
		p1-x		[Cocoa-float!]
		p1-y		[Cocoa-float!]
		p2-x		[Cocoa-float!]
		p2-y		[Cocoa-float!]
		cos-val		[Cocoa-float!]
		sin-val		[Cocoa-float!]
		rx2			[Cocoa-float!]
		ry2			[Cocoa-float!]
		dx			[Cocoa-float!]
		dy			[Cocoa-float!]
		sqrt-val	[Cocoa-float!]
		sign		[Cocoa-float!]
		rad-check	[Cocoa-float!]
		pi2			[Cocoa-float!]
		pt1			[CGPoint! value]
		pt2			[CGPoint! value]
		m			[CGAffineTransform! value]
		path		[Cocoa-handle!]
		pt			[red-point2D!]
		end-x end-y [Cocoa-float!]
][
	;-- parse arguments
	GET_COCOA_XY(end end-x end-y)
	p1-x: ctx/last-pt-x
	p1-y: ctx/last-pt-y
	p2-x: either rel? [ p1-x + end-x ][ end-x ]
	p2-y: either rel? [ p1-y + end-y ][ end-y ]
	ctx/last-pt-x: p2-x
	ctx/last-pt-y: p2-y
	item: as red-integer! end + 1
	radius-x: fabsf F32_TO_COCOA get-float32 item
	item: item + 1
	radius-y: fabsf F32_TO_COCOA get-float32 item
	item: item + 1
	pi2: as Cocoa-float! 2.0 * PI
	theta: F32_TO_COCOA get-float32 item
	theta: theta * as Cocoa-float! (PI / 180.0)
	#either ABI = 'apple-aarch64 [
		theta: fmod theta pi2
	][
		theta: as-float32 fmod as-float theta as-float pi2
	]

	;-- calculate center
	dx: (p1-x - p2-x) / as Cocoa-float! 2.0
	dy: (p1-y - p2-y) / as Cocoa-float! 2.0
	cos-val: cosf theta
	sin-val: sinf theta
	X1: (cos-val * dx) + (sin-val * dy)
	Y1: (cos-val * dy) - (sin-val * dx)
	rx2: radius-x * radius-x
	ry2: radius-y * radius-y
	rad-check: ((X1 * X1) / rx2) + ((Y1 * Y1) / ry2)
	if rad-check > as Cocoa-float! 1.0 [
		radius-x: radius-x * sqrtf rad-check
		radius-y: radius-y * sqrtf rad-check
		rx2: radius-x * radius-x
		ry2: radius-y * radius-y
	]
	either large? = sweep? [sign: as Cocoa-float! -1.0 ][sign: as Cocoa-float! 1.0 ]
	sqrt-val: ((rx2 * ry2) - (rx2 * Y1 * Y1) - (ry2 * X1 * X1)) / ((rx2 * Y1 * Y1) + (ry2 * X1 * X1))
	either sqrt-val < as Cocoa-float! 0.0 [cf: as Cocoa-float! 0.0 ][ cf: sign * sqrtf sqrt-val ]
	cx: cf * (radius-x * Y1 / radius-y)
	cy: cf * (radius-y * X1 / radius-x) * (as Cocoa-float! -1.0)
	center-x: (cos-val * cx) - (sin-val * cy) + ((p1-x + p2-x) / as Cocoa-float! 2.0)
	center-y: (sin-val * cx) + (cos-val * cy) + ((p1-y + p2-y) / as Cocoa-float! 2.0)

	;-- transform our ellipse into the unit circle
	m: CGAffineTransformMakeScale (as Cocoa-float! 1.0) / radius-x (as Cocoa-float! 1.0) / radius-y
	m: CGAffineTransformRotate m (as Cocoa-float! 0.0) - theta
	m: CGAffineTransformTranslate m (as Cocoa-float! 0.0) - center-x (as Cocoa-float! 0.0) - center-y

	pt1/x: p1-x pt1/y: p1-y
	pt2/x: p2-x pt2/y: p2-y
	pt1: CGPointApplyAffineTransform pt1 m
	pt2: CGPointApplyAffineTransform pt2 m

	;-- calculate angles
	cx: atan2f pt1/y pt1/x
	cy: atan2f pt2/y pt2/x
	angle-len: cy - cx
	either sweep? [
		if angle-len < as Cocoa-float! 0.0 [
			angle-len: angle-len + pi2
		]
	][
		if angle-len > as Cocoa-float! 0.0 [
			angle-len: angle-len - pi2
		]
	]

	;-- construct the inverse transform
	m: CGAffineTransformMakeTranslation center-x center-y
	m: CGAffineTransformRotate m theta
	m: CGAffineTransformScale m radius-x radius-y
	CGPathAddRelativeArc ctx/path :m as Cocoa-float! 0.0 as Cocoa-float! 0.0 as Cocoa-float! 1.0 cx angle-len
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
		w	[Cocoa-float!]
		h	[Cocoa-float!]
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
		CGContextScaleCTM ctx as Cocoa-float! -1.0 1.0
		do-draw ctx null blk no no yes yes
	]
	if wrap = flip-y [
		m: CGAffineTransformMake 1.0 0.0 0.0 as Cocoa-float! -1.0 w h
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
		x xx		[Cocoa-float!]
		y yy		[Cocoa-float!]
		w			[Cocoa-float!]
		h			[Cocoa-float!]
		wrap		[integer!]
		ctx			[handle!]
		pattern		[Cocoa-handle!]
		space		[Cocoa-handle!]
		rc			[NSRect! value]
		m			[CGAffineTransform! value]
		alpha		[Cocoa-float!]
		width		[Cocoa-float!]
		height		[Cocoa-float!]
		callbacks	[CGPatternCallbacks!]
		pt			[red-point2D!]
][
	dc/pattern-blk: as int-ptr! block
	ctx: dc/raw
	alpha: as Cocoa-float! 1.0
	GET_COCOA_XY(size w h)
	either crop-1 = null [
		x: as Cocoa-float! 0.0
		y: as Cocoa-float! 0.0
	][
		GET_COCOA_XY(crop-1 x y)
	]
	either crop-2 = null [
		w: w - x
		h: h - y
	][
		GET_COCOA_XY(crop-2 xx yy)
		w: either ( x + xx ) > w [ w - x ][ xx ]
		h: either ( y + yy ) > h [ h - y ][ yy ]
	]

	wrap: tile
	unless mode = null [wrap: symbol/resolve mode/symbol]
	dc/pattern-mode: wrap
	case [
		any [wrap = flip-x wrap = flip-y] [w: w * (as Cocoa-float! 2.0)]
		wrap = flip-xy [w: w * (as Cocoa-float! 2.0) h: h * (as Cocoa-float! 2.0)]
		true []
	]

	space: CGColorSpaceCreatePattern 0
	CGContextSetFillColorSpace ctx space
	CGColorSpaceRelease space

	callbacks: as CGPatternCallbacks! :dc/pattern-ver
	callbacks/version: 0
	callbacks/drawPattern: as int-ptr! :draw-pattern-callback
	callbacks/releaseInfo: null

	width: w
	height: h
	dc/pattern-w: width
	dc/pattern-h: height
	rc/x: x
	rc/y: y
	rc/w: width
	rc/h: height
	m: CGAffineTransformMake 1.0 0.0 0.0 as Cocoa-float! -1.0 0.0 height
	pattern: CGPatternCreate as int-ptr! dc rc m width height 0 yes callbacks
	either brush? [
		dc/brush?: yes
		CGContextSetFillPattern ctx pattern :alpha
	][
		dc/pen?: yes
		CGContextSetStrokePattern ctx pattern :alpha
	]
	CGPatternRelease pattern

	if dc/grad-pen <> 0 [
		CGGradientRelease dc/grad-pen
		dc/grad-pos?: no
		dc/grad-pen: 0
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
