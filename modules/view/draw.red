Red/System [
	Title:	"Draw dialect"
	Author: "Nenad Rakocevic"
	File: 	%draw.red
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system [
	with gui [
		line:			symbol/make "line"
		line-width:		symbol/make "line-width"
		box:			symbol/make "box"
		triangle:		symbol/make "triangle"
		pen:			symbol/make "pen"
		fill-pen:		symbol/make "fill-pen"
		_polygon:		symbol/make "polygon"
		circle:			symbol/make "circle"
		anti-alias: 	symbol/make "anti-alias"
		font:			symbol/make "font"
		text:			symbol/make "text"
		_ellipse:		symbol/make "ellipse"
		_arc:			symbol/make "arc"
		curve:			symbol/make "curve"
		spline:			symbol/make "spline"
		line-join:		symbol/make "line-join"
		line-cap:		symbol/make "line-cap"
		
		_off:			symbol/make "off"
		closed:			symbol/make "closed"
		miter:			symbol/make "miter"
		miter-bevel:	symbol/make "miter-bevel"
		_round:			symbol/make "round"
		bevel:			symbol/make "bevel"
		square:			symbol/make "square"
		flat:			symbol/make "flat"
		border:			symbol/make "border"
		repeat:			symbol/make "repeat"
		reflect:		symbol/make "reflect"

		throw-draw-error: func [
			cmds [red-block!]
			cmd  [red-value!]
			/local
				base [red-value!]
		][
			base: block/rs-head cmds
			cmds: as red-block! stack/push as red-value! cmds
			cmds/head: (as-integer cmd - base) >> 4
			fire [TO_ERROR(script invalid-draw) cmds]
		]

		get-color-int: func [
			tp		[red-tuple!]
			alpha?	[int-ptr!]
			return: [integer!]
			/local
				color [integer!]
		][
			color: tp/array1
			alpha?/value: either TUPLE_SIZE?(tp) = 3 [
				color: color and 00FFFFFFh
				0
			][1]
			color
		]
		
		#define DRAW_FETCH_VALUE(type) [
			cmd: cmd + 1
			if any [cmd >= tail TYPE_OF(cmd) <> type][
				throw-draw-error cmds cmd
			]
		]
		
		#define DRAW_FETCH_OPT_VALUE(type) [
			pos: cmd + 1
			if all [pos < tail TYPE_OF(pos) = type][cmd: pos]
		]
		
		#define DRAW_FETCH_SOME_PAIR [
			until [cmd: cmd + 1 any [TYPE_OF(cmd) <> TYPE_PAIR cmd = tail]]
			cmd: cmd - 1
		]
		
		#define DRAW_FETCH_NAMED_VALUE(type) [
			cmd: cmd + 1
			if cmd >= tail [throw-draw-error cmds cmd]
			value: either TYPE_OF(cmd) = TYPE_WORD [_context/get as red-word! cmd][cmd]
			if TYPE_OF(value) <> type [throw-draw-error cmds cmd]
		]
		
		#define DRAW_FETCH_TUPLE [
			DRAW_FETCH_NAMED_VALUE(TYPE_TUPLE)
			alpha?: 0
			rgb: get-color-int as red-tuple! value :alpha?
		]
		
		parse-draw: func [
			cmds [red-block!]
			DC	 [handle!]
			/local
				cmd		[red-value!]
				tail	[red-value!]
				start	[red-value!]
				pos		[red-value!]
				value	[red-value!]
				word	[red-word!]
				pattern [red-word!]
				point	[red-pair!]
				color	[red-tuple!]
				sym		[integer!]
				rgb		[integer!]
				alpha?	[integer!]
				off?	[logic!]
				pair?	[logic!]
				border?	[logic!]
				closed? [logic!]
		][
			cmd:  block/rs-head cmds
			tail: block/rs-tail cmds

			while [cmd < tail][
				word: as red-word! cmd
				if TYPE_OF(word) <> TYPE_WORD [throw-draw-error cmds cmd]
				sym: symbol/resolve word/symbol
				start: cmd + 1
				
				case [
					sym = pen [
						DRAW_FETCH_TUPLE
						OS-draw-pen DC rgb as logic! alpha?
					]
					sym = box [
						loop 2 [DRAW_FETCH_VALUE(TYPE_PAIR)]
						DRAW_FETCH_OPT_VALUE(TYPE_INTEGER)
						OS-draw-box DC as red-pair! start as red-pair! cmd
					]
					sym = line [
						DRAW_FETCH_SOME_PAIR
						if start + 2 > cmd [throw-draw-error cmds cmd]
						OS-draw-line DC as red-pair! start as red-pair! cmd
					]
					sym = line-width [
						DRAW_FETCH_VALUE(TYPE_INTEGER)
						OS-draw-line-width DC as red-integer! start
					]
					sym = fill-pen [
						off?: no
						if TYPE_OF(start) = TYPE_WORD [
							word: as red-word! start
							off?: _off = symbol/resolve word/symbol
						]
						either off? [cmd: cmd + 1 rgb: -1][DRAW_FETCH_TUPLE]
						OS-draw-fill-pen DC rgb off? as logic! alpha?
					]
					sym = triangle [
						loop 3 [DRAW_FETCH_VALUE(TYPE_PAIR)]
						OS-draw-triangle DC as red-pair! start
					]
					sym = _polygon [
						DRAW_FETCH_SOME_PAIR
						OS-draw-polygon DC as red-pair! start as red-pair! cmd
					]
					sym = circle [
						DRAW_FETCH_VALUE(TYPE_PAIR)			;-- center
						DRAW_FETCH_VALUE(TYPE_INTEGER)		;-- radius
						DRAW_FETCH_OPT_VALUE(TYPE_INTEGER)	;-- radius-y (optional)
						OS-draw-circle DC as red-pair! start as red-integer! cmd
					]
					sym = _ellipse [
						loop 2 [DRAW_FETCH_VALUE(TYPE_PAIR)] ;-- center, radius
						OS-draw-ellipse DC as red-pair! start as red-pair! cmd
					]	
					sym = anti-alias [
						either TYPE_OF(start) = TYPE_WORD [
							word: as red-word! start
							OS-draw-anti-alias DC _off <> symbol/resolve word/symbol
						][
							throw-draw-error cmds cmd
						]
						cmd: start
					]
					sym = font [
						DRAW_FETCH_NAMED_VALUE(TYPE_OBJECT)
						OS-draw-font DC as red-object! value
					]
					sym = text [
						DRAW_FETCH_VALUE(TYPE_PAIR)		;-- position
						DRAW_FETCH_VALUE(TYPE_STRING)	;-- text string
						OS-draw-text DC as red-pair! start as red-string! cmd
					]
					sym = _arc [
						loop 2 [DRAW_FETCH_VALUE(TYPE_PAIR)]	;-- center/radius (of the circle/ellipse)
						loop 2 [DRAW_FETCH_VALUE(TYPE_INTEGER)]	;-- angle begin/length (degrees)
						DRAW_FETCH_OPT_VALUE(TYPE_WORD)
						word: as red-word! cmd
						if all [TYPE_OF(word) = TYPE_WORD closed <> symbol/resolve word/symbol][
							cmd: cmd - 1
						]
						OS-draw-arc DC as red-pair! start as red-value! cmd
					]
					sym = curve	[
						loop 3 [DRAW_FETCH_VALUE(TYPE_PAIR)]
						DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
						OS-draw-curve DC as red-pair! start as red-pair! cmd
					]
					sym = spline [
						DRAW_FETCH_OPT_VALUE(TYPE_WORD)
						closed?: no
						if TYPE_OF(cmd) = TYPE_WORD [
							word: as red-word! cmd
							closed?: closed = symbol/resolve word/symbol
						]
						DRAW_FETCH_SOME_PAIR
						OS-draw-spline DC as red-pair! start as red-pair! cmd closed?
					]
					sym = line-join	[
						DRAW_FETCH_VALUE(TYPE_WORD)
						word: as red-word! start
						OS-draw-line-join DC symbol/resolve word/symbol
					]
					sym = line-cap [
						DRAW_FETCH_VALUE(TYPE_WORD)
						word: as red-word! start
						OS-draw-line-cap DC symbol/resolve word/symbol
					]
					sym = _image [
						DRAW_FETCH_NAMED_VALUE(TYPE_IMAGE)
						start: value
						pos: cmd + 1
						pair?: TYPE_OF(pos) = TYPE_PAIR
						point: either pair? [as red-pair! pos][null]
						if pair? [
							DRAW_FETCH_VALUE(TYPE_PAIR)		;-- upper-left point
							DRAW_FETCH_OPT_VALUE(TYPE_PAIR)	;-- upper-right point (lower-right if only 2 pairs)
							if all [point < cmd TYPE_OF(cmd) = TYPE_PAIR][
								loop 2 [DRAW_FETCH_VALUE(TYPE_PAIR)] ;-- lower-left/right points
							]
						]
						color: null
						pos: cmd + 1
						if any [TYPE_OF(pos) = TYPE_TUPLE TYPE_OF(pos) = TYPE_WORD][
							if pos >= tail [throw-draw-error cmds cmd]
							value: either TYPE_OF(pos) = TYPE_WORD [_context/get as red-word! pos][pos]
							if TYPE_OF(value) = TYPE_TUPLE [color: as red-tuple! value]
						]
						border?: no
						pattern: null
						pos: cmd + 1
						if TYPE_OF(pos) = TYPE_WORD [
							word: as red-word! pos
							sym: symbol/resolve word/symbol
							case [
								sym = border [border?: yes cmd: cmd + 1]
								;any [sym = repeat sym = reflect][
								;	;@@ TBD check if followed by four integers
								;]
								true [0]
							]
						]
						OS-draw-image DC as red-image! start point color border? pattern
					]
					true [throw-draw-error cmds cmd]
				]
				cmd: cmd + 1
			]
		]

		do-draw: func [
			handle		[handle!]
			img			[red-image!]
			cmds		[red-block!]
			on-graphic? [logic!]
			cache?		[logic!]
			paint?		[logic!]
			/local
				DC	   [handle!]						;-- drawing context (opaque handle)
		][
			if all [
				null? handle
				any [TYPE_OF(cmds) <> TYPE_BLOCK zero? block/rs-length? cmds]
			][exit]

			DC: draw-begin handle img on-graphic? paint?
			if TYPE_OF(cmds) = TYPE_BLOCK [
				parse-draw cmds DC
			]
			draw-end DC handle on-graphic? cache? paint?
		]
	]
]

draw: function [
	"Draws scalable vector graphics to an image"
	image	[image! pair!]	"Image or size for an image"
	cmd		[block!]		"Draw commands"
	return: [image!]
][
	if pair? image [image: make image! image]
	system/view/platform/draw-image image cmd
	image
]