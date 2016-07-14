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
		matrix:			symbol/make "matrix"
		invert-matrix:	symbol/make "invert-matrix"
		reset-matrix:	symbol/make "reset-matrix"
		push:			symbol/make "push"
		rotate:			symbol/make "rotate"
		scale:			symbol/make "scale"
		translate:		symbol/make "translate"
		skew:			symbol/make "skew"
		transform:		symbol/make "transform"

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
		linear:			symbol/make "linear"
		radial:			symbol/make "radial"
		diamond:		symbol/make "diamond"

		throw-draw-error: func [
			cmds   [red-block!]
			cmd	   [red-value!]
			catch? [logic!]
			/local
				base [red-value!]
		][
			base: block/rs-head cmds
			cmds: as red-block! stack/push as red-value! cmds
			cmds/head: (as-integer cmd - base) >> 4
			either catch? [
				report TO_ERROR(script invalid-draw) as red-value! cmds null null
				throw RED_THROWN_ERROR
			][
				fire [TO_ERROR(script invalid-draw) cmds]
			]
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

		get-float: func [
			int		[red-integer!]
			return: [float!]
			/local
				f	[red-float!]
				v	[float!]
		][
			either TYPE_OF(int) = TYPE_INTEGER [
				v: integer/to-float int/value
			][
				f: as red-float! int
				v: f/value
			]
			v
		]

		get-float32: func [
			int		[red-integer!]
			return: [float32!]
			/local
				f	[red-float!]
				v	[float32!]
		][
			either TYPE_OF(int) = TYPE_INTEGER [
				v: as float32! integer/to-float int/value
			][
				f: as red-float! int
				v: as float32! f/value
			]
			v
		]

		reverse-int-array: func [
			array	[int-ptr!]
			count	[integer!]
			/local
				tail [int-ptr!]
				val  [integer!]
		][
			tail: array + count - 1
			while [array < tail][
				val: array/value
				array/value: tail/value
				tail/value: val
				array: array + 1
				tail: tail - 1
			]
		]

		#define DRAW_FETCH_VALUE(type) [
			cmd: cmd + 1
			if any [cmd >= tail TYPE_OF(cmd) <> type][
				throw-draw-error cmds cmd catch?
			]
		]

		#define DRAW_FETCH_VALUE_2(type1 type2) [
			cmd: cmd + 1
			if any [cmd >= tail all [TYPE_OF(cmd) <> type1 TYPE_OF(cmd) <> type2]][
				throw-draw-error cmds cmd catch?
			]
		]
		
		#define DRAW_FETCH_OPT_VALUE(type) [
			pos: cmd + 1
			if all [pos < tail TYPE_OF(pos) = type][cmd: pos]
		]

		#define DRAW_FETCH_OPT_VALUE_2(type1 type2) [
			pos: cmd + 1
			if all [
				pos < tail
				any [TYPE_OF(pos) = type1 TYPE_OF(pos) = type2]
			][cmd: pos]
		]

		#define DRAW_FETCH_SOME_PAIR [
			until [cmd: cmd + 1 any [TYPE_OF(cmd) <> TYPE_PAIR cmd = tail]]
			cmd: cmd - 1
		]
		
		#define DRAW_FETCH_NAMED_VALUE(type) [
			cmd: cmd + 1
			if cmd >= tail [throw-draw-error cmds cmd catch?]
			value: either TYPE_OF(cmd) = TYPE_WORD [_context/get as red-word! cmd][cmd]
			if TYPE_OF(value) <> type [throw-draw-error cmds cmd catch?]
		]
		
		#define DRAW_FETCH_TUPLE [
			DRAW_FETCH_NAMED_VALUE(TYPE_TUPLE)
			alpha?: 0
			rgb: get-color-int as red-tuple! value :alpha?
		]
		
		parse-draw: func [
			cmds   [red-block!]
			DC	   [handle!]
			catch? [logic!]								;-- YES: report errors, NO: fire errors
			/local
				cmd		[red-value!]
				tail	[red-value!]
				start	[red-value!]
				pos		[red-value!]
				value	[red-value!]
				word	[red-word!]
				pattern [red-word!]
				point	[red-pair!]
				end		[red-pair!]
				blk		[red-block!]
				color	[red-tuple!]
				sym		[integer!]
				mode	[integer!]
				rgb		[integer!]
				alpha?	[integer!]
				count	[integer!]
				type	[integer!]
				off?	[logic!]
				pair?	[logic!]
				border?	[logic!]
				closed? [logic!]
				grad?	[logic!]
		][
			cmd:  block/rs-head cmds
			tail: block/rs-tail cmds

			while [cmd < tail][
				switch TYPE_OF(cmd) [
					TYPE_WORD [
						word: as red-word! cmd
						sym: symbol/resolve word/symbol
						start: cmd + 1

						case [
							any [sym = pen sym = fill-pen][
								off?: no
								grad?: no
								if TYPE_OF(start) = TYPE_WORD [
									word: as red-word! start
									mode: symbol/resolve word/symbol
									off?: _off = mode
									grad?: any [mode = linear mode = radial mode = diamond]
								]
								either grad? [								;-- gradient pen
									cmd: cmd + 1
									DRAW_FETCH_OPT_VALUE(TYPE_WORD)			;-- grad mode (optional)
									pattern: either pos = cmd [as red-word! cmd][null]

									DRAW_FETCH_VALUE(TYPE_PAIR)				;-- grad offset
									point: as red-pair! cmd
									loop 2 [								;-- start and stop
										DRAW_FETCH_VALUE(TYPE_INTEGER)
									]
									loop 3 [								;-- angle, scale-x and scale-y (optional)
										pos: cmd + 1
										if pos < tail [
											type: TYPE_OF(pos)
											either any [
												type = TYPE_INTEGER
												type = TYPE_FLOAT
											][cmd: pos][break]
										]
									]
									count: 0
									off?: no
									start: cmd
									while [
										cmd: cmd + 1
										cmd < tail
									][
										value: either TYPE_OF(cmd) = TYPE_WORD [_context/get as red-word! cmd][cmd]
										type: TYPE_OF(value)
										if type = TYPE_TUPLE [count: count + 1]
										unless any [type = TYPE_TUPLE type = TYPE_FLOAT][break]
									]
									if count < 2 [throw-draw-error cmds start catch?]
									mode: either null? pattern [-1][symbol/resolve pattern/symbol]
									OS-draw-grad-pen
										DC
										symbol/resolve word/symbol
										mode
										point
										count
										sym = fill-pen
									cmd: cmd - 1
								][
									either off? [cmd: cmd + 1 rgb: -1][DRAW_FETCH_TUPLE]
									either sym = pen [
										OS-draw-pen DC rgb off? as logic! alpha?
									][
										OS-draw-fill-pen DC rgb off? as logic! alpha?
									]
								]
							]
							sym = box [
								loop 2 [DRAW_FETCH_VALUE(TYPE_PAIR)]
								DRAW_FETCH_OPT_VALUE(TYPE_INTEGER)
								OS-draw-box DC as red-pair! start as red-pair! cmd
							]
							sym = line [
								DRAW_FETCH_SOME_PAIR
								if start = cmd [throw-draw-error cmds cmd catch?]
								OS-draw-line DC as red-pair! start as red-pair! cmd
							]
							sym = line-width [
								DRAW_FETCH_VALUE(TYPE_INTEGER)
								OS-draw-line-width DC as red-integer! start
							]
							sym = triangle [
								loop 3 [DRAW_FETCH_VALUE(TYPE_PAIR)]
								OS-draw-triangle DC as red-pair! start
							]
							sym = _polygon [
								DRAW_FETCH_SOME_PAIR
								if start + 3 > cmd [throw-draw-error cmds cmd catch?]
								OS-draw-polygon DC as red-pair! start as red-pair! cmd
							]
							sym = circle [
								DRAW_FETCH_VALUE(TYPE_PAIR)						;-- center
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)		;-- radius
								DRAW_FETCH_OPT_VALUE_2(TYPE_INTEGER TYPE_FLOAT) ;-- radius-y (optional)
								OS-draw-circle DC as red-pair! start as red-integer! cmd
							]
							sym = _ellipse [
								loop 2 [DRAW_FETCH_VALUE(TYPE_PAIR)] ;-- bound box
								OS-draw-ellipse DC as red-pair! start as red-pair! cmd
							]	
							sym = anti-alias [
								either TYPE_OF(start) = TYPE_WORD [
									word: as red-word! start
									OS-draw-anti-alias DC _off <> symbol/resolve word/symbol
								][
									throw-draw-error cmds cmd catch?
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
								if all [
									cmd < tail
									TYPE_OF(word) = TYPE_WORD
									closed <> symbol/resolve word/symbol
								][
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
								DRAW_FETCH_SOME_PAIR
								DRAW_FETCH_OPT_VALUE(TYPE_WORD)
								closed?: no
								if all [cmd < tail TYPE_OF(cmd) = TYPE_WORD][
									word: as red-word! cmd
									closed?: closed = symbol/resolve word/symbol
									cmd: cmd - 1
								]
								if start + 1 > cmd [throw-draw-error cmds cmd + 1 catch?]
								OS-draw-spline DC as red-pair! start as red-pair! cmd closed?
								if closed? [cmd: cmd + 1]		;-- skip CLOSED word
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
								end: null
								if pair? [
									cmd: pos						;-- upper-left point
									until [
										DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
										cmd <> pos
									]
									end: as red-pair! cmd
								]
								color: null
								border?: no
								pattern: null

								pos: cmd + 1
								if pos < tail [
									if any [TYPE_OF(pos) = TYPE_TUPLE TYPE_OF(pos) = TYPE_WORD][
										if pos >= tail [throw-draw-error cmds cmd catch?]
										value: either TYPE_OF(pos) = TYPE_WORD [_context/get as red-word! pos][pos]
										if TYPE_OF(value) = TYPE_TUPLE [color: as red-tuple! value]
									]

									pos: cmd + 1
									if all [pos < tail TYPE_OF(pos) = TYPE_WORD][
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
								]
								OS-draw-image DC as red-image! start point end color border? pattern
							]
							sym = rotate [
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
								OS-matrix-rotate as red-integer! start as red-pair! cmd
							]
							sym = scale [
								loop 2 [DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)]
								OS-matrix-scale as red-integer! start as red-integer! cmd
							]
							sym = translate [
								DRAW_FETCH_VALUE(TYPE_PAIR)
								point: as red-pair! start
								OS-matrix-translate point/x point/y
							]
							sym = skew [
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								DRAW_FETCH_OPT_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								OS-matrix-skew as red-integer! start as red-integer! cmd
							]
							sym = transform [
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
								value: cmd + 1
								loop 2 [DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)]
								DRAW_FETCH_VALUE(TYPE_PAIR)
								OS-matrix-transform
									as red-integer! start
									as red-integer! value
									as red-pair! cmd
							]
							sym = push [
								DRAW_FETCH_VALUE(TYPE_BLOCK)
								OS-matrix-push
								parse-draw as red-block! start DC catch?
								OS-matrix-pop
							]
							sym = matrix [
								DRAW_FETCH_VALUE(TYPE_BLOCK)
								OS-matrix-set as red-block! start
							]
							sym = reset-matrix  [OS-matrix-reset]
							sym = invert-matrix [OS-matrix-invert]
							true [throw-draw-error cmds cmd catch?]
						]
					]
					TYPE_SET_WORD [
						blk: as red-block! _context/set as red-word! cmd as red-value! cmds
						blk/head: ((as-integer cmd - block/rs-head cmds) / size? cell!) + 1
					]
					TYPE_BLOCK [
						parse-draw as red-block! cmd DC catch?
					]
					default [throw-draw-error cmds cmd catch?]
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
			catch?		[logic!]
			/local
				DC	   [handle!]						;-- drawing context (opaque handle)
		][
			if all [
				null? handle
				any [TYPE_OF(cmds) <> TYPE_BLOCK zero? block/rs-length? cmds]
			][exit]

			system/thrown: 0

			DC: draw-begin handle img on-graphic? paint?
			if TYPE_OF(cmds) = TYPE_BLOCK [
				catch RED_THROWN_ERROR [parse-draw cmds DC catch?]
			]
			draw-end DC handle on-graphic? cache? paint?
			
			if system/thrown = RED_THROWN_ERROR [
				either catch? [system/thrown: 0][re-throw]
			]
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
