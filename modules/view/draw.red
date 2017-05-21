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
		_matrix-order:  symbol/make "matrix-order"
		_append:        symbol/make "append"
		prepend:        symbol/make "prepend"
		invert-matrix:	symbol/make "invert-matrix"
		reset-matrix:	symbol/make "reset-matrix"
		_push:			symbol/make "push"
		clip:			symbol/make "clip"
		crop:			symbol/make "crop"
		replace:        symbol/make "replace"
		intersect:      symbol/make "intersect"
		union:          symbol/make "union"
		xor:            symbol/make "xor"
		exclude:        symbol/make "exclude"
		complement:     symbol/make "complement"
		rotate:			symbol/make "rotate"
		scale:			symbol/make "scale"
		translate:		symbol/make "translate"
		skew:			symbol/make "skew"
		transform:		symbol/make "transform"
		shape:			symbol/make "shape"
		curv:			symbol/make "curv"
		hline:			symbol/make "hline"
		vline:			symbol/make "vline"
		move:			symbol/make "move"
		qcurv:			symbol/make "qcurv"
		qcurve:			symbol/make "qcurve"
		sweep:			symbol/make "sweep"
		large:			symbol/make "large"
		close-shape:	symbol/make "close"

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
		_pattern:       symbol/make "pattern"
		bitmap:         symbol/make "bitmap"
		_pad:           symbol/make "pad"
		_repeat:        symbol/make "repeat"
		_reflect:       symbol/make "reflect"
		tile:           symbol/make "tile"
		flip-x:         symbol/make "flip-x"
		flip-y:         symbol/make "flip-y"
		flip-xy:        symbol/make "flip-xy"
		clamp:          symbol/make "clamp"

		throw-draw-error: func [
			cmds   [red-block!]
			cmd	   [red-value!]
			catch? [logic!]
			/local
				silent [red-logic!]
				base   [red-value!]
		][
			silent: as red-logic! #get system/view/silent?
			if all [TYPE_OF(silent) = TYPE_LOGIC silent/value][throw 1]
			
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

		transparent-color?: func [
			color	[red-tuple!]
			return: [logic!]
		][
			all [
				TYPE_OF(color) = TYPE_TUPLE
				color/array1 >>> 24 = 255
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
				v: as-float int/value
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
				v: as float32! int/value
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
		
		reverse-float32-array: func [
			array	[pointer! [float32!]]
			count	[integer!]
			/local
				tail [pointer! [float32!]]
				val  [float32!]
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
		
		#define DRAW_FETCH_SOME(type) [
			until [cmd: cmd + 1 any [TYPE_OF(cmd) <> type cmd = tail]]
			cmd: cmd - 1
		]
		
		#define DRAW_FETCH_SOME_2(type1 type2) [
			until [cmd: cmd + 1 any [ all [TYPE_OF(cmd) <> type1 TYPE_OF(cmd) <> type2] cmd = tail]]
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

		#define DRAW_FETCH_OPT_TRANSFORM [
			value: start
			DRAW_FETCH_OPT_VALUE(TYPE_LIT_WORD)
			either cmd = pos [
				word: as red-word! value
				sym: symbol/resolve word/symbol
				either any [ sym = pen sym = fill-pen][
					start: start + 1
				][
					cmd: cmd - 1
					sym: -1
				]
			][ sym: -1 ]
		]

		old-gradient-pen: func [
			DC		[draw-ctx!]
			cmds	[red-block!]
			start	[red-value!]
			tail	[red-value!]
			cmd		[red-value!]
			sym		[integer!]
			catch?	[logic!]
			return: [red-value!]
			/local
				word	[red-word!]
				pattern [red-word!]
				point	[red-pair!]
				pos		[red-value!]
				value	[red-value!]
				type	[integer!]
				count	[integer!]
				off?	[logic!]
		][
			word: as red-word! start
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
			OS-draw-grad-pen-old
				DC
				symbol/resolve word/symbol
				-1
				point
				count
				sym = fill-pen
			cmd - 1
		]

		check-pen: func [
			DC	    [draw-ctx!]
			cmds    [red-block!]
			start	[red-value!]
			tail	[red-value!]
			cmd     [red-value!]
			sym     [integer!]
			catch?  [logic!]								;-- YES: report errors, NO: fire errors
			return: [red-value!]
			/local
				word	[red-word!]
				point	[red-pair!]
				pos		[red-value!]
				value	[red-value!]
				img     [red-image!]
				crop-1	[red-pair!]
				crop-2	[red-pair!]
				size    [red-pair!]
				type	[integer!]
				count	[integer!]
				mode	[integer!]
				rgb		[integer!]
				alpha?	[integer!]
				off?    [logic!]
				grad?	[logic!]
				stops   [red-value!]
				_start  [red-value!]
				spread  [integer!]
				positions   [red-value!]
				skip-pos    [logic!]
				focal?      [logic!]
		][
			off?: no
			grad?: no
			mode: -1
			if TYPE_OF(start) = TYPE_WORD [
				word: as red-word! start
				mode: symbol/resolve word/symbol
				off?: _off = mode
				grad?: any [mode = linear mode = radial mode = diamond]
			]
			cmd: cmd + 1
			either grad? [								;-- gradient pen
				count: 0
				stops: cmd + 1
				if TYPE_OF(stops) = TYPE_PAIR [
					return old-gradient-pen DC cmds start tail cmd sym catch?
				]
				loop 2 [                                ;-- at least two stops required
					DRAW_FETCH_VALUE_2(TYPE_TUPLE TYPE_WORD)
					DRAW_FETCH_OPT_VALUE(TYPE_FLOAT)
					count: count + 1
				]
				_start: cmd
				while [ cmd < tail ][                   ;--optional more stops
					DRAW_FETCH_OPT_VALUE_2(TYPE_TUPLE TYPE_WORD)
					if cmd = _start [ break ]
					value: cmd
					if TYPE_OF(value) = TYPE_WORD [
						value: as red-value! _context/get as red-word! cmd
					]
					if TYPE_OF(value) <> TYPE_TUPLE [ cmd: cmd - 1 break ]
					DRAW_FETCH_OPT_VALUE(TYPE_FLOAT)
					_start: cmd
					count: count + 1
				]
				positions: cmd
				skip-pos: true
				focal?: false
				case [                                                  ;-- positions
					mode = linear [
						DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
						if cmd <> positions [
							skip-pos: false
							DRAW_FETCH_VALUE(TYPE_PAIR)
						] 
					]
					mode = radial [
						DRAW_FETCH_OPT_VALUE(TYPE_PAIR)                 ;-- center
						if cmd <> positions [
							skip-pos: false 
							DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT) ;-- radius
							_start: cmd
							DRAW_FETCH_OPT_VALUE(TYPE_PAIR)             ;-- focal point
							if _start <> cmd [ focal?: true ]
						]
					]
					mode = diamond [
						DRAW_FETCH_OPT_VALUE(TYPE_PAIR)                 ;-- upper
						if cmd <> positions [
							skip-pos: false 
							DRAW_FETCH_VALUE(TYPE_PAIR)                 ;-- lower
							_start: cmd
							DRAW_FETCH_OPT_VALUE(TYPE_PAIR)             ;-- focal point
							if _start <> cmd [ focal?: true ]
						]
					]
				]
				positions: positions + 1
				_start: cmd
				DRAW_FETCH_OPT_VALUE(TYPE_WORD)         ;-- spread value
				either cmd <> _start [
					word:   as red-word! cmd
					spread: symbol/resolve word/symbol
					unless any [
						spread = _pad
						spread = _repeat
						spread = _reflect
					][
						spread: _pad 
						cmd: cmd - 1
					]
				][
					spread: _pad
				]
				OS-draw-grad-pen
					DC
					mode
					stops
					count
					skip-pos
					positions
					focal?
					spread
					sym = fill-pen
			][
				case [
					mode = _pattern [
						DRAW_FETCH_VALUE(TYPE_PAIR)
						size: as red-pair! cmd
						word:   null
						crop-1: null
						crop-2: null 
						DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
						if cmd = pos [ crop-1: as red-pair! cmd ]
						DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
						if cmd = pos [ crop-2: as red-pair! cmd ]
						DRAW_FETCH_OPT_VALUE(TYPE_WORD)
						if pos = cmd [ 
							word: as red-word! cmd
							type: symbol/resolve word/symbol
							unless any [ 
								type = tile 
								type = flip-x 
								type = flip-y
								type = flip-xy
								type = clamp
							][ cmd: cmd - 1 word: null ] 
						]
						DRAW_FETCH_VALUE(TYPE_BLOCK)
						OS-draw-brush-pattern DC size crop-1 crop-2 word as red-block! cmd sym = fill-pen
					]
					mode = bitmap [
						img: null
						DRAW_FETCH_VALUE(TYPE_WORD)
						either TYPE_OF(cmd) = TYPE_WORD [
							value: as red-value! _context/get as red-word! cmd
							if TYPE_OF(value) <> TYPE_IMAGE [ 
								throw-draw-error cmds cmd catch? 
							]
							img: as red-image! value
						][ throw-draw-error cmds cmd catch? ]
						word:   null
						crop-1: null
						crop-2: null 
						DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
						if cmd = pos [ crop-1: as red-pair! cmd ]
						DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
						if cmd = pos [ crop-2: as red-pair! cmd ]
						DRAW_FETCH_OPT_VALUE(TYPE_WORD)
						if pos = cmd [ 
							word: as red-word! cmd
							type: symbol/resolve word/symbol
							unless any [ 
								type = tile 
								type = flip-x 
								type = flip-y
								type = flip-xy
								type = clamp
							][ cmd: cmd - 1 word: null ] 
						]
						OS-draw-brush-bitmap DC img crop-1 crop-2 word sym = fill-pen
					]
					true [
						cmd: cmd - 1
						either off? [ cmd: cmd + 1 rgb: -1 ][ DRAW_FETCH_TUPLE ]
						either sym = pen [
							OS-draw-pen DC rgb off? as logic! alpha?
						][
							OS-draw-fill-pen DC rgb off? as logic! alpha?
						]
					]
				]
			]
			cmd
		]

		check-line: func [
			DC      [draw-ctx!]
			cmds    [red-block!]
			start	[red-value!]
			tail	[red-value!]
			cmd     [red-value!]
			sym     [integer!]
			catch?  [logic!]								;-- YES: report errors, NO: fire errors
			return: [red-value!]
			/local
				word	[red-word!]
		][
			case [
				sym = line-width [
					DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
					OS-draw-line-width DC cmd
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
			]
			cmd
		]
		
		parse-shape: func [
			DC      [draw-ctx!]
			cmds    [red-block!]
			draw?   [logic!]
			catch?  [logic!]								;-- YES: report errors, NO: fire errors
			/local
				cmd     [red-value!]
				tail    [red-value!]
				start   [red-value!]
				opts    [red-value!]
				end     [red-value!]
				pos     [red-value!]
				word    [red-word!]
				point   [red-pair!]
				sym     [integer!]
				rel?    [logic!]
				close?  [logic!]
				sweep?  [logic!]
				large?  [logic!]
		][
			cmd:  block/rs-head cmds
			tail: block/rs-tail cmds

			close?: no
			OS-draw-shape-beginpath DC
			while [cmd < tail][
				case [
					any [ TYPE_OF(cmd) = TYPE_WORD TYPE_OF(cmd) = TYPE_LIT_WORD ][
						rel?: TYPE_OF(cmd) = TYPE_LIT_WORD
						start: cmd + 1
						word: as red-word! cmd
						sym: symbol/resolve word/symbol

						case [
							any [sym = pen sym = fill-pen] [
								cmd: check-pen DC cmds start tail cmd sym catch?
							]
							sym = move [
								DRAW_FETCH_VALUE(TYPE_PAIR)
								OS-draw-shape-moveto DC as red-pair! cmd rel?
								close?: no
							]
							sym = line [
								DRAW_FETCH_VALUE(TYPE_PAIR)
								DRAW_FETCH_SOME_PAIR
								OS-draw-shape-line DC as red-pair! start as red-pair! cmd rel?
								close?: yes
							]
							any [sym = line-width sym = line-join sym = line-cap][
								cmd: check-line DC cmds start tail cmd sym catch?
							]
							any [ sym = hline sym = vline ][
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								OS-draw-shape-axis DC start cmd rel? (sym = hline)
								close?: yes
							]
							sym = _arc [
								sweep?: false
								large?: false
								DRAW_FETCH_VALUE(TYPE_PAIR)
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								end: cmd
								opts: cmd
								loop 2 [
									DRAW_FETCH_OPT_VALUE(TYPE_WORD)
									if opts <> cmd [
										word: as red-word! cmd
										case [
											( symbol/resolve word/symbol ) = sweep [ sweep?: true ]
											( symbol/resolve word/symbol ) = large [ large?: true ]
											true [ cmd: cmd - 1 break]
										]
										opts: cmd
									]
								]
								OS-draw-shape-arc DC as red-pair! start sweep? large? rel?
								close?: yes
							]
							sym = curve [
								DRAW_FETCH_SOME_PAIR
								if (as-integer cmd - start) < 32 [throw-draw-error cmds cmd - 2 catch?]
								OS-draw-shape-curve DC as red-pair! start as red-pair! cmd rel?
								close?: yes
							]
							sym = curv [
								DRAW_FETCH_SOME_PAIR
								if (as-integer cmd - start) < 16 [throw-draw-error cmds cmd - 1 catch?]
								OS-draw-shape-curv DC as red-pair! start as red-pair! cmd rel?
								close?: yes
							]
							sym = qcurve [
								DRAW_FETCH_SOME_PAIR
								if (as-integer cmd - start) < 16 [throw-draw-error cmds cmd - 1 catch?]
								OS-draw-shape-qcurve DC as red-pair! start as red-pair! cmd rel?
								close?: yes
							]
							sym = qcurv [
								DRAW_FETCH_SOME_PAIR
								OS-draw-shape-qcurv DC as red-pair! start as red-pair! cmd rel?
								close?: yes
							]
							sym = close-shape [OS-draw-shape-close DC]
							true [ throw-draw-error cmds cmd catch? ]
						]
					]
					true [ throw-draw-error cmds cmd catch? ]
				]
				cmd: cmd + 1
			]
			if draw? [
				unless OS-draw-shape-endpath DC close? [ throw-draw-error cmds cmd catch? ]
			]
		]

		parse-draw: func [
			DC	   [draw-ctx!]
			cmds   [red-block!]
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
				crop-s	[red-pair!]
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
				rect?   [logic!]
				state	[integer!]
				clip-mode    [integer!]
				m-order [integer!]
		][
			cmd:  block/rs-head cmds
			tail: block/rs-tail cmds

			state: 0
			clip-mode: replace
			while [cmd < tail][
				switch TYPE_OF(cmd) [
					TYPE_WORD [
						word: as red-word! cmd
						sym: symbol/resolve word/symbol
						start: cmd + 1

						case [
							any [sym = pen sym = fill-pen] [
								cmd: check-pen DC cmds start tail cmd sym catch?
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
							any [sym = line-width sym = line-join sym = line-cap][
								cmd: check-line DC cmds start tail cmd sym catch?
							]
							sym = triangle [
								loop 3 [DRAW_FETCH_VALUE(TYPE_PAIR)]
								OS-draw-triangle DC as red-pair! start
							]
							sym = _polygon [
								DRAW_FETCH_SOME_PAIR
								if start + 2 > cmd [throw-draw-error cmds cmd catch?]
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
								DRAW_FETCH_VALUE(TYPE_PAIR)					;-- position
								DRAW_FETCH_VALUE_2(TYPE_STRING TYPE_OBJECT) ;-- string! or text-box!
								OS-draw-text DC as red-pair! start as red-string! cmd catch?
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
								crop-s: null
								pattern: null

								pos: cmd + 1
								if pos < tail [
									if any [TYPE_OF(pos) = TYPE_TUPLE TYPE_OF(pos) = TYPE_WORD][
										value: either TYPE_OF(pos) = TYPE_WORD [_context/get as red-word! pos][pos]
										if TYPE_OF(value) = TYPE_TUPLE [color: as red-tuple! value cmd: pos]
									]

									pos: cmd + 1
									if all [pos < tail TYPE_OF(pos) = TYPE_WORD][
										word: as red-word! pos
										sym: symbol/resolve word/symbol
										case [
											sym = border [border?: yes cmd: pos]
											sym = crop [
												crop-s: as red-pair! pos + 1
												cmd: pos
												loop 2 [DRAW_FETCH_VALUE(TYPE_PAIR)]
											]
											;any [sym = repeat sym = reflect][
											;	;@@ TBD check if followed by four integers
											;]
											true [0]
										]
									]
								]
								OS-draw-image DC as red-image! start point end color border? crop-s pattern
							]
							sym = clip [
								rect?: false
								DRAW_FETCH_VALUE_2(TYPE_PAIR TYPE_BLOCK)
								either TYPE_OF(cmd) = TYPE_PAIR [
									DRAW_FETCH_VALUE(TYPE_PAIR)
									rect?: true
								][
									parse-shape DC as red-block! cmd false catch?
								]
								value: cmd
								DRAW_FETCH_OPT_VALUE(TYPE_WORD)
								if pos = cmd [
									word: as red-word! cmd
									type: symbol/resolve word/symbol  
									either any [
										type = replace
										type = intersect
										type = union
										type = xor
										type = exclude
									][ 
										clip-mode: type
									][
										cmd: cmd - 1 
									]
								]
								DRAW_FETCH_OPT_VALUE(TYPE_BLOCK)
								either pos = cmd [
									OS-matrix-push DC :state
									OS-set-clip DC as red-pair! start as red-pair! value rect? clip-mode
									parse-draw DC as red-block! cmd catch?
									OS-matrix-pop DC state
								][
									OS-set-clip DC as red-pair! start as red-pair! value rect? clip-mode
								]
							]
							sym = shape [
								DRAW_FETCH_VALUE(TYPE_BLOCK)
								parse-shape DC as red-block! cmd true catch?
							]
							sym = _matrix-order [
								DRAW_FETCH_VALUE(TYPE_WORD)
								word: as red-word! start
								m-order: symbol/resolve word/symbol
								unless any [
									m-order = _append
									m-order = prepend
								][ throw-draw-error cmds cmd catch? ]
								OS-set-matrix-order DC m-order
							]
							sym = rotate [
								DRAW_FETCH_OPT_TRANSFORM
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
								DRAW_FETCH_OPT_VALUE(TYPE_BLOCK)
								either pos = cmd [
									OS-matrix-push DC :state
									OS-matrix-rotate DC sym as red-integer! start as red-pair! cmd - 1
									parse-draw DC as red-block! cmd catch?
									OS-matrix-pop DC state
								][
									OS-matrix-rotate DC sym as red-integer! start as red-pair! cmd
								]
							]
							sym = scale [
								DRAW_FETCH_OPT_TRANSFORM
								loop 2 [DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)]
								DRAW_FETCH_OPT_VALUE(TYPE_BLOCK)
								either pos = cmd [
									OS-matrix-push DC :state
									OS-matrix-scale DC sym as red-integer! start as red-integer! cmd - 1
									parse-draw DC as red-block! cmd catch?
									OS-matrix-pop DC state
								][
									OS-matrix-scale DC sym as red-integer! start as red-integer! cmd
								]
							]
							sym = translate [
								DRAW_FETCH_OPT_TRANSFORM
								DRAW_FETCH_VALUE(TYPE_PAIR)
								point: as red-pair! start
								DRAW_FETCH_OPT_VALUE(TYPE_BLOCK)
								either pos = cmd [
									OS-matrix-push DC :state
									OS-matrix-translate DC sym point/x point/y
									parse-draw DC as red-block! cmd catch?
									OS-matrix-pop DC state
								][
									OS-matrix-translate DC sym point/x point/y
								]
							]
							sym = skew [
								DRAW_FETCH_OPT_TRANSFORM
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								DRAW_FETCH_OPT_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								DRAW_FETCH_OPT_VALUE(TYPE_BLOCK)
								either pos = cmd [
									OS-matrix-push DC :state
									OS-matrix-skew DC sym as red-integer! start as red-integer! cmd - 1
									parse-draw DC as red-block! cmd catch?
									OS-matrix-pop DC state
								][
									OS-matrix-skew DC sym as red-integer! start as red-integer! cmd
								]
							]
							sym = transform [
								DRAW_FETCH_OPT_TRANSFORM
								DRAW_FETCH_OPT_VALUE(TYPE_PAIR)
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								value: cmd + 1
								loop 2 [DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)]
								DRAW_FETCH_VALUE(TYPE_PAIR)
								DRAW_FETCH_OPT_VALUE(TYPE_BLOCK)
								either pos = cmd [
									OS-matrix-push DC :state
									OS-matrix-transform
										DC
										sym
										as red-pair! start
										as red-integer! value
										as red-pair! cmd - 1
									parse-draw DC as red-block! cmd catch?
									OS-matrix-pop DC state
								][
									OS-matrix-transform
										DC
										sym
										as red-pair! start
										as red-integer! value
										as red-pair! cmd
								]
							]
							sym = _push [							;@@ push is a keyword in R/S
								DRAW_FETCH_VALUE(TYPE_BLOCK)
								OS-matrix-push DC :state
								parse-draw DC as red-block! start catch?
								OS-matrix-pop DC state
							]
							sym = matrix [
								DRAW_FETCH_OPT_TRANSFORM
								DRAW_FETCH_VALUE(TYPE_BLOCK)
								OS-matrix-set DC sym as red-block! start
							]
							sym = reset-matrix  [
								DRAW_FETCH_OPT_TRANSFORM
								OS-matrix-reset DC sym
							]
							sym = invert-matrix [
								DRAW_FETCH_OPT_TRANSFORM
								OS-matrix-invert DC sym
							]
							true [throw-draw-error cmds cmd catch?]
						]
					]
					TYPE_SET_WORD [
						blk: as red-block! _context/set as red-word! cmd as red-value! cmds
						blk/head: ((as-integer cmd - block/rs-head cmds) / size? cell!) + 1
					]
					TYPE_BLOCK [
						parse-draw DC as red-block! cmd catch?
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
				DC		[draw-ctx! value]				;-- drawing context (opaque handle)
		][
			if all [
				null? handle
				any [TYPE_OF(cmds) <> TYPE_BLOCK zero? block/rs-length? cmds]
			][exit]
			
			system/thrown: 0
			draw-begin :DC handle img on-graphic? paint?
			if TYPE_OF(cmds) = TYPE_BLOCK [
				catch RED_THROWN_ERROR [parse-draw DC cmds catch?]
			]
			draw-end :DC handle on-graphic? cache? paint?
			if system/thrown = RED_THROWN_ERROR [
				either catch? [system/thrown: 0][re-throw]
			]
		]

		parse-text-styles: func [
			dc			[handle!]
			layout		[handle!]			;-- text layout (opaque handle)
			cmds		[red-block!]
			catch?		[logic!]
			/local
				cmd		[red-value!]
				tail	[red-value!]
				pos		[red-value!]
				value	[red-value!]
				start	[red-value!]
				int1	[red-integer!]
				int2	[red-integer!]
				word	[red-word!]
				sym		[integer!]
				rgb		[integer!]
				alpha?	[integer!]
				idx		[integer!]
				len		[integer!]
		][
			alpha?: 0 idx: 0 len: 0
			cmd:  block/rs-head cmds
			tail: block/rs-tail cmds

			while [cmd < tail][
				switch TYPE_OF(cmd) [
					TYPE_WORD [
						word: as red-word! cmd
						sym: symbol/resolve word/symbol
						start: cmd + 1

						case [
							sym = _backdrop [							;-- background color
								DRAW_FETCH_TUPLE
								OS-text-box-background dc layout idx len rgb
							]
							sym = _bold [
								OS-text-box-weight layout idx len 700
							]
							sym = _italic [
								OS-text-box-italic layout idx len
							]
							sym = _underline [
								DRAW_FETCH_OPT_VALUE(TYPE_TUPLE)		;-- color
								DRAW_FETCH_OPT_VALUE(TYPE_LIT_WORD)		;-- style: 'dash, 'double, 'triple
								OS-text-box-underline layout idx len start cmd
							]
							sym = _strike [
								DRAW_FETCH_OPT_VALUE(TYPE_TUPLE)		;-- color
								DRAW_FETCH_OPT_VALUE(TYPE_LIT_WORD)		;-- style: 'wave, 'double
								OS-text-box-strikeout layout idx len start cmd
							]
							sym = border [
								DRAW_FETCH_OPT_VALUE(TYPE_TUPLE)		;-- color
								DRAW_FETCH_OPT_VALUE(TYPE_LIT_WORD)		;-- style: 'dash, 'wave
								OS-text-box-border layout idx len start cmd
							]
							sym = _font-name [
								DRAW_FETCH_VALUE(TYPE_STRING)
								OS-text-box-font-name dc layout idx len as red-string! start
							]
							sym = _font-size [
								DRAW_FETCH_VALUE_2(TYPE_INTEGER TYPE_FLOAT)
								OS-text-box-font-size dc layout idx len get-float as red-integer! start
							]
							true [throw-draw-error cmds cmd catch?]
						]
					]
					TYPE_TUPLE [										;-- text color
						rgb: get-color-int as red-tuple! cmd :alpha?
						OS-text-box-color dc layout idx len rgb
					]
					TYPE_INTEGER [										;-- range
						int1: as red-integer! cmd
						int2: int1 + 1
						cmd: cmd + 2
						if any [TYPE_OF(int2) <> TYPE_INTEGER TYPE_OF(cmd) = TYPE_INTEGER][
							throw-draw-error cmds cmd catch?
						]
						idx: int1/value - 1
						len: int2/value
						cmd: as red-value! int2
					]
					default [throw-draw-error cmds cmd catch?]
				]
				cmd: cmd + 1
			]
		]
	]
]

draw: function [
	"Draws scalable vector graphics to an image"
	image	[image! pair!]	"Image or size for an image"
	cmd		[block!]		"Draw commands"
	/transparent
	return: [image!]
][
	if pair? image [
		image: either transparent [ make image! image 255.255.255.0 ][ make image! image ]
	]
	system/view/platform/draw-image image cmd
	image
]
