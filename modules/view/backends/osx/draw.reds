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

#include %text-box.reds

#define DRAW_FLOAT_MAX		[as float32! 3.4e38]
#define F32_0				[as float32! 0.0]
#define F32_1				[as float32! 1.0]	

max-colors: 256												;-- max number of colors for gradient
max-edges: 1000												;-- max number of edges for a polygon
edges: as CGPoint! allocate max-edges * (size? CGPoint!)	;-- polygone edges buffer
colors: as pointer! [float32!] allocate 5 * max-colors * (size? float32!)
colors-pos: colors + (4 * max-colors)

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

		if on-graphic? [							;-- draw on image!, flip the CTM
			rc: as NSRect! img
			CGContextTranslateCTM CGCtx as float32! 0.0 rc/y
			CGContextScaleCTM CGCtx as float32! 1.0 as float32! -1.0
		]
		CGContextTranslateCTM CGCtx as float32! 0.5 as float32! 0.5
	]

	ctx/raw:			CGCtx
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
	ctx/brush-color:	0
	ctx/grad-pen:		-1
	ctx/pen?:			yes
	ctx/brush?:			no
	ctx/colorspace:		CGColorSpaceCreateDeviceRGB
	ctx/last-pt-x:		as float32! 0.0
	ctx/last-pt-y:		as float32! 0.0

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
	if dc/font-attrs <> 0 [objc_msgSend [dc/font-attrs sel_getUid "release"]]
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
	if dc/pen-width <> width-v [
		dc/pen-width: width-v
		CGContextSetLineWidth dc/raw width-v
	]
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
	if dc/grad-pos? [check-gradient-poly dc edges 3]
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
	if dc/grad-pos? [check-gradient-poly dc edges nb]
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

draw-text-box: func [
	ctx		[handle!]
	pos		[red-pair!]
	tbox	[red-object!]
	catch?	[logic!]
	/local
		int		[red-integer!]
		state	[red-block!]
		layout	[integer!]
		tc		[integer!]
		idx		[integer!]
		len		[integer!]
		y		[integer!]
		x		[integer!]
		pt		[CGPoint!]
][
	state: (as red-block! object/get-values tbox) + TBOX_OBJ_STATE

	if TYPE_OF(state) <> TYPE_BLOCK [
		OS-text-box-layout tbox null catch?
	]

	int: as red-integer! block/rs-head state
	layout: int/value
	int: int + 1
	tc: int/value

	idx: objc_msgSend [layout sel_getUid "glyphRangeForTextContainer:" tc]
	len: system/cpu/edx
	x: 0
	pt: as CGPoint! :x
	pt/x: as float32! pos/x
	pt/y: as float32! pos/y
	objc_msgSend [layout sel_getUid "drawBackgroundForGlyphRange:atPoint:" idx len pt/x pt/y]
	objc_msgSend [layout sel_getUid "drawGlyphsForGlyphRange:atPoint:" idx len pt/x pt/y]
]

OS-draw-text: func [
	dc		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	/local
		ctx [handle!]
][
	ctx: dc/raw
	either TYPE_OF(text) = TYPE_STRING [
		draw-text-at ctx text dc/font-attrs pos/x pos/y
	][
		draw-text-box ctx pos as red-object! text catch?
	]
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
	image		[integer!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		rc		[NSRect!]
		ty		[float32!]
][
	rc: make-rect x y width height
	ty: rc/y + rc/h
	;-- flip coords
	;; drawing an image or PDF by calling Core Graphics functions directly,
	;; we must flip the CTM.
	;; http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
	CGContextTranslateCTM dc as float32! 0.0 ty
	CGContextScaleCTM dc as float32! 1.0 as float32! -1.0

	CGContextDrawImage dc rc/x as float32! 0.0 rc/w rc/h image

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
	crop1		[red-pair!]
	pattern		[red-word!]
	/local
		img		[integer!]
		sub-img [integer!]
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
		w		[float32!]
		h		[float32!]
		ww		[float32!]
		crop2	[red-pair!]
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

	img: CGBitmapContextCreateImage as-integer image/node
	if crop1 <> null [
		crop2: crop1 + 1
		w: as float32! crop2/x
		h: as float32! crop2/y
		ww: w / h * (as float32! height)
		width: as-integer ww
		sub-img: CGImageCreateWithImageInRect
			img
			as float32! crop1/x
			as float32! crop1/y
			w
			h
		CGImageRelease img
		img: sub-img
	]

	CG-draw-image dc/raw img x y width height
	if crop1 <> null [CGImageRelease img]
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

	;pt1/x: dc/grad-x1
	;pt1/y: dc/grad-y1
	;pt1: CGPointApplyAffineTransform pt1 dc/matrix
	;pt2/x: dc/grad-x2
	;pt2/y: dc/grad-y2
	;pt2: CGPointApplyAffineTransform pt2 dc/matrix
	CGContextConcatCTM dc/raw dc/matrix

	either dc/grad-type = linear [
		CGContextDrawLinearGradient
			ctx
			dc/grad-pen
			;pt1/x pt1/y pt2/x pt2/y
			dc/grad-x1 dc/grad-y1 dc/grad-x2 dc/grad-y2
			3
	][
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
][
	dc/grad-type: type
	dc/grad-spread: spread
	dc/grad-x1: as float32! offset/x			;-- save gradient offset for later use
	dc/grad-y1: as float32! offset/y

	int: as red-integer! offset + 1
	dc/grad-x2: as float32! int/value
	int: int + 1
	dc/grad-y2: as float32! int/value

	if type = radial [
		dc/grad-radius: dc/grad-y2 - dc/grad-x2
		dc/grad-x2: dc/grad-x1
		dc/grad-y2: dc/grad-y1
	]

	n: 0
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
			0	[if p <> as float32! 0.0 [dc/grad-angle: p dc/grad-rotate?: yes]]
			1	[if p <> as float32! 1.0 [dc/grad-sx: p dc/grad-scale?: yes]]
			2	[if p <> as float32! 1.0 [dc/grad-sy: p dc/grad-scale?: yes]]
		]
		n: n + 1
	]

	color: colors + 4
	pos: colors-pos + 1
	delta: as float32! count - 1
	delta: (as float32! 1.0) / delta
	p: as float32! 0.0
	head: as red-value! int

	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		val: clr/array1
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
		pt		[red-pair!]
		val		[integer!]
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
		val: clr/array1
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
		pt: as red-pair! positions
		ctx/grad-x1: as float32! pt/x ctx/grad-y1: as float32! pt/y
		either type = linear [
			pt: pt + 1
			ctx/grad-x2: as float32! pt/x ctx/grad-y2: as float32! pt/y
		][
			either type = radial [
				ctx/grad-radius: get-float32 as red-integer! positions + 1
				if focal? [
					pt: as red-pair! ( positions + 2 )
				]
				ctx/grad-x2: as float32! pt/x ctx/grad-y2: as float32! pt/y
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
		pt	[CGPoint!]
		rad [float32!]
][
	ctx: dc/raw
	rad: (as float32! PI) / (as float32! 180.0) * get-float32 angle
	either pen = -1 [
		if angle <> as red-integer! center [
			_OS-matrix-translate ctx center/x center/y
		]
		CGContextRotateCTM ctx rad
		if angle <> as red-integer! center [
			_OS-matrix-translate ctx 0 - center/x 0 - center/y
		]
	][
		dc/matrix: CGAffineTransformRotate dc/matrix rad
	]
]

OS-matrix-scale: func [
	dc		[draw-ctx!]
	pen		[integer!]
	sx		[red-integer!]
	sy		[red-integer!]
][
	either pen = -1 [
		CGContextScaleCTM dc/raw get-float32 sx get-float32 sy
	][
		dc/matrix: CGAffineTransformScale dc/matrix get-float32 sx get-float32 sy
	]
]

_OS-matrix-translate: func [
	ctx [handle!]
	x	[integer!]
	y	[integer!]
][
	CGContextTranslateCTM ctx as float32! x as float32! y
]

OS-matrix-translate: func [
	dc	[draw-ctx!]
	pen [integer!]
	x	[integer!]
	y	[integer!]
][
	either pen = -1 [
		CGContextTranslateCTM dc/raw as float32! x as float32! y
	][
		dc/matrix: CGAffineTransformTranslate dc/matrix as float32! x as float32! y
	]
]

OS-matrix-skew: func [
	dc		[draw-ctx!]
	pen		[integer!]
	sx		[red-integer!]
	sy		[red-integer!]
	/local
		m	[CGAffineTransform! value]
][
	m/a: as float32! 1.0
	m/b: as float32! either sx = sy [0.0][tan degree-to-radians get-float sy TYPE_TANGENT]
	m/c: as float32! tan degree-to-radians get-float sx TYPE_TANGENT
	m/d: as float32! 1.0
	m/tx: as float32! 0.0
	m/ty: as float32! 0.0
	either pen = -1 [
		CGContextConcatCTM dc/raw m
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
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center

	OS-matrix-rotate dc pen rotate center
	OS-matrix-scale dc pen scale scale + 1
	_OS-matrix-translate dc/raw translate/x translate/y
]

OS-matrix-push: func [dc [draw-ctx!] state [int-ptr!]][
	CGContextSaveGState dc/raw
]

OS-matrix-pop: func [dc [draw-ctx!] state [integer!]][
	CGContextRestoreGState dc/raw
	dc/pen-color:		0
	dc/brush-color:		0
]

OS-matrix-reset: func [
	dc [draw-ctx!]
	pen [integer!]
	/local
		m [CGAffineTransform! value]
][
	m: CGAffineTransformMake F32_1 F32_0 F32_0 F32_1 as float32! 0.5 as float32! 0.5
	CGContextSetCTM dc/raw m
]

OS-matrix-invert: func [
	dc	[draw-ctx!]
	pen	[integer!]
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
	CGContextConcatCTM dc/raw m
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
		t	[integer!]
		x1	[integer!]
		x2	[integer!]
		y1	[integer!]
		y2	[integer!]
		p4	[integer!]
		p3	[integer!]
		p2	[integer!]
		p1	[integer!]
		rc	[NSRect!]
][
	ctx: dc/raw
	if upper/x > lower/x [t: upper/x upper/x: lower/x lower/x: t]
	if upper/y > lower/y [t: upper/y upper/y: lower/y lower/y: t]

	p1: 0
	rc: as NSRect! :p1
	x1: upper/x
	y1: upper/y
	x2: lower/x
	y2: lower/y
	rc/x: as float32! x1
	rc/y: as float32! y1
	rc/w: as float32! x2 - x1
	rc/h: as float32! y2 - y1
	;CGContextBeginPath ctx
	CGContextAddRect ctx rc/x rc/y rc/w rc/h
	CGContextClip ctx
]

;-- shape sub command --

OS-draw-shape-beginpath: func [
	dc          [draw-ctx!]
	/local
		path    [integer!]
][
	CGContextBeginPath dc/raw
]

OS-draw-shape-endpath: func [
	dc          [draw-ctx!]
	close?      [logic!]
	return:     [logic!]
	/local
		alpha   [byte!]
][
	if close? [CGContextClosePath dc/raw]
	do-draw-path dc
	true
]

OS-draw-shape-moveto: func [
	dc      [draw-ctx!]
	coord   [red-pair!]
	rel?    [logic!]
	/local
		ctx [handle!]
		x	[float32!]
		y	[float32!]
][
	ctx: dc/raw
	x: as float32! coord/x
	y: as float32! coord/y
	if rel? [
		x: dc/last-pt-x + x
		y: dc/last-pt-y + y
	]
	dc/last-pt-x: x
	dc/last-pt-y: y
	dc/shape-curve?: no
	CGContextMoveToPoint ctx x y
]

OS-draw-shape-line: func [
	dc          [draw-ctx!]
	start       [red-pair!]
	end         [red-pair!]
	rel?        [logic!]
	/local
		ctx		[handle!]
		dx		[float32!]
		dy		[float32!]
		x		[float32!]
		y		[float32!]
][
	ctx: dc/raw
	dx: dc/last-pt-x
	dy: dc/last-pt-y

	until [
		x: as float32! start/x
		y: as float32! start/y
		if rel? [
			x: x + dx
			y: y + dy
			dx: x
			dy: y
		]
		CGContextAddLineToPoint ctx x y
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
	CGContextAddLineToPoint dc/raw dc/last-pt-x dc/last-pt-y
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
		pt		[red-pair!]
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
		CGContextAddCurveToPoint dc/raw p1x p1y p2x p2y p3x p3y
		dc/control-x: p2x
		dc/control-y: p2y
		dc/last-pt-x: p3x
		dc/last-pt-y: p3y
	][								;-- quadratic Bézier
		CGContextAddQuadCurveToPoint dc/raw p1x p1y p2x p2y
		dc/control-x: p1x
		dc/control-y: p1y
		dc/last-pt-x: p2x
		dc/last-pt-y: p2y
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
][
	;-- parse arguments
	p1-x: ctx/last-pt-x
	p1-y: ctx/last-pt-y
	p2-x: either rel? [ p1-x + as float32! end/x ][ as float32! end/x ]
	p2-y: either rel? [ p1-y + as float32! end/y ][ as float32! end/y ]
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
	theta: theta % pi2

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

	path: CGPathCreateMutable
	CGPathMoveToPoint path null center-x center-y
	CGPathAddRelativeArc path :m as float32! 0.0 as float32! 0.0 as float32! 1.0 cx angle-len
	CGContextAddPath ctx/raw path
	CGPathRelease path
]

OS-draw-shape-close: func [
	ctx		[draw-ctx!]
][
	CGContextClosePath ctx/raw
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
		x			[integer!]
		y			[integer!]
		w			[integer!]
		h			[integer!]
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
][
	dc/pattern-blk: as int-ptr! block
	ctx: dc/raw
	alpha: as float32! 1.0
	w: size/x
	h: size/y
	either crop-1 = null [
		x: 0
		y: 0
	][
		x: crop-1/x
		y: crop-1/y
	]
	either crop-2 = null [
		w: w - x
		h: h - y
	][
		w: either ( x + crop-2/x ) > w [ w - x ][ crop-2/x ]
		h: either ( y + crop-2/y ) > h [ h - y ][ crop-2/y ]
	]

	wrap: tile
	unless mode = null [wrap: symbol/resolve mode/symbol]
	dc/pattern-mode: wrap
	case [
		any [wrap = flip-x wrap = flip-y] [w: w * 2]
		wrap = flip-xy [w: w * 2 h: h * 2]
		true []
	]

	space: CGColorSpaceCreatePattern 0
	CGContextSetFillColorSpace ctx space
	CGColorSpaceRelease space

	callbacks: as CGPatternCallbacks! :dc/pattern-ver
	callbacks/version: 0
	callbacks/drawPattern: as-integer :draw-pattern-callback
	callbacks/releaseInfo: 0

	width: as float32! w
	height: as float32! h
	dc/pattern-w: width
	dc/pattern-h: height
	rc/x: as float32! x
	rc/y: as float32! y
	rc/w: width
	rc/h: height
	m: CGAffineTransformMake F32_1 F32_0 F32_0 as float32! -1.0 as float32! 0 height
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

