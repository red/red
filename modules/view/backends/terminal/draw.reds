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
	ctx/pen-type: DRAW_BRUSH_NONE
	ctx/font-color?: no
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

OS-draw-line: func [
	ctx	   [draw-ctx!]
	point  [red-pair!]
	end	   [red-pair!]
][

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

	color: MAKE_TRUE_COLOR(color)
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
][

]

OS-draw-triangle: func [		;@@ TBD merge this function with OS-draw-polygon
	ctx		[draw-ctx!]
	start	[red-pair!]
][

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

do-draw-ellipse: func [
	ctx		[draw-ctx!]
	x		[integer!]
	y		[integer!]
	width	[integer!]
	height	[integer!]
][

]

OS-draw-circle: func [
	ctx		[draw-ctx!]
	center	[red-pair!]
	radius	[red-integer!]
][

]

OS-draw-ellipse: func [
	ctx		 [draw-ctx!]
	upper	 [red-pair!]
	diameter [red-pair!]
][

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
		ctx/font-color: MAKE_TRUE_COLOR(clr)
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
		x y		[integer!]
		pt		[red-point2D!]
		config	[render-config! value]
][
	GET_PAIR_XY_INT(pos x y)
	zero-memory as byte-ptr! :config size? render-config!
	config/align: TEXT_WRAP_FLAG
	config/flags: PIXEL_ANSI_SEQ
	case [
		ctx/font-color? [config/fg-color: ctx/font-color]
		ctx/pen-type = DRAW_BRUSH_COLOR [config/fg-color: ctx/pen-color]
		true [0]
	]
	_widget/render-text text ctx/x + x ctx/y + y as rect! :ctx/left :config
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