Red/System [
	Title:	"Widget related functions"
	Author: "Xie Qingtian"
	File: 	%widget.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

_widget: context [
	has-flag?: func [
		widget	[widget!]
		flag	[integer!]
		return: [logic!]
	][
		widget/flags and flag <> 0
	]

	default-event-handler: func [
		type	[event-type!]
		event	[widget-event!]
		return: [integer!]
	][
		0
	]

	default-render-func: func [
		x			[integer!]
		y			[integer!]
		widget		[widget!]
	][
		render x y widget PIXEL_ANSI_SEQ
	]

	default-update-func: func [
		widget		[widget!]
	][
		0
	]

	make: func [
		parent		[widget!]
		return:		[widget!]
		/local
			widget	[widget!]
	][
		widget: as widget! zero-alloc size? widget!
		widget/parent: parent
		widget/update: as update-func! :default-update-func
		widget/render: as render-func! :default-render-func
		widget/on-event: as event-handler! :default-event-handler
		widget
	]

	set-size: func [
		g			[widget!]
		w			[float32!]
		h			[float32!]
	][
		g/box/right: g/box/left + w
		g/box/bottom: g/box/top + h
	]

	get-size: func [
		g	[widget!]
		w	[int-ptr!]
		h	[int-ptr!]
	][
		w/value: as-integer g/box/right - g/box/left
		h/value: as-integer g/box/bottom - g/box/top
	]

	get-offset: func [
		g	[widget!]
		x	[int-ptr!]
		y	[int-ptr!]
	][
		x/value: as-integer g/box/left
		y/value: as-integer g/box/top
	]

	to-screen-pt: func [
		widget		[widget!]
		p-x			[int-ptr!]
		p-y			[int-ptr!]
		/local
			x		[float32!]
			y		[float32!]
	][
		x: F32_0
		y: F32_0
		while [all [widget <> null widget/type <> window]][ ;-- window is always full screen
			x: x + widget/box/left
			y: y + widget/box/top
			widget: widget/parent
		]
		p-x/value: as-integer x
		p-y/value: as-integer y
	]

	find-child: func [
		widget	[widget!]
		x		[float32!]
		y		[float32!]
		return: [widget!]
		/local
			g	[widget!]
			obj	[red-object!]
			n	[integer!]
	][
		n: length? widget
		obj: tail widget
		loop n [
			obj: obj - 1
			g: as widget! get-face-handle obj
			if all [
				g <> null
				g/flags and WIDGET_FLAG_HIDDEN = 0		;-- visible
				all [
					g/box/left <= x x < g/box/right
					g/box/top <= y y < g/box/bottom
				]
			][
				return g
			]
		]
		null
	]

	delete: func [
		w [widget!]
		/local
			sym [integer!]
	][
		sym: WIDGET_TYPE(w)
		case [
			sym = window [screen/remove-window w]
			any [sym = rich-text sym = field][free as byte-ptr! w/data]
			true [0]
		]
		if w/image <> null [free as byte-ptr! w/image]
		free as byte-ptr! w
	]

	copy: func [
		widget	[widget!]
		return: [widget!]
		/local
			g	[widget!]
	][
		g: as widget! allocate size? widget!
		copy-memory as byte-ptr! g as byte-ptr! widget size? widget!
		g
	]

	length?: func [
		widget	[widget!]
		return:	[integer!]
		/local
			p	[red-block!]
	][
		p: CHILD_WIDGET(widget)
		if TYPE_OF(p) <> TYPE_BLOCK [return 0]
		block/rs-length? p
	]

	head: func [
		widget	[widget!]
		return: [red-object!]
		/local
			p	[red-block!]
	][
		p: CHILD_WIDGET(widget)
		if TYPE_OF(p) <> TYPE_BLOCK [return null]
		as red-object! block/rs-head p
	]

	tail: func [
		widget	[widget!]
		return: [red-object!]
		/local
			p	[red-block!]
	][
		p: CHILD_WIDGET(widget)
		if TYPE_OF(p) <> TYPE_BLOCK [return null]
		as red-object! block/rs-tail p
	]

	#enum ansi-erase-mode! [
		ERASE_DOWN
		ERASE_UP
		ERASE_SCREEN
		ERASE_LINE
		ERASE_LINE_END
		ERASE_LINE_START
	]

	saved-cursor: 0
	default-attributes: 0

	console-store-position: does [][
		0
	]

	set-console-cursor: func [
		cursor		[integer!]
	][
		0
	]

	clear-screen: func [
		"Clears the screen and moves the cursor to the home position (line 0, column 0)"
		mode       [ansi-erase-mode!]
	][
		0
	]

	update-graphic-mode: func [	;-- styles and colors
		p		[pixel!]
		value	[integer!]
		/local
			flags [integer!]
			idx	  [integer!]
	][	
		flags: p/flags
		case [
			value = 0 [	;-- reset all styles and colors
				p/fg-color: 0
				p/bg-color: 0
				p/flags: 0
			]
			value = 6 [0]
			all [value >= 1 value <= 9][
				idx: value
				p/flags: flags or style-table/idx
			]
			all [value >= 21 value <= 29][
				idx: value - 20
				p/flags: flags and (not style-table/idx)
			]
			value = 38 [0]
			all [value >= 30 value <= 39][
				idx: value - 30
				p/fg-color: MAKE_COLOR_16(idx)
			]
			value = 48 [0]
			all [value >= 40 value <= 49][
				idx: value - 40
				p/bg-color: MAKE_COLOR_16(idx)
			]
			all [value >= 90 value <= 97][
				idx: value - 80
				p/fg-color: MAKE_COLOR_16(idx)
			]
			all [value >= 100 value <= 107][
				idx: value - 90
				p/bg-color: MAKE_COLOR_16(idx)
			]
			true [0]
		]
	]

	parse-ansi-sequence: func[
		str 	[byte-ptr!]
		unit    [integer!]
		pix		[pixel!]
		return: [integer!]
		/local
			cp      [integer!]
			cnt		[integer!]
			state   [integer!]
			value1  [integer!]
			value2  [integer!]
			value3  [integer!]
			command [integer!]
			col     [integer!]
			row     [integer!]
	][
		str: str + unit		;-- skip ESC
		cp: string/get-char str unit
		if cp <> as-integer #"[" [return 0]
		
		cnt:	 1
		state:   1
		value1:  0
		value2:  0
		value3:  0
		str: str + unit
		cnt: cnt + 1
		until [
			cp: string/get-char str unit
			str: str + unit
			cnt: cnt + 1
			switch state [
				1 [ ;value1 start
					case [
						all [cp >= as-integer #"0" cp <= as-integer #"9"][
							value1: ((value1 * 10) + (cp - as-integer #"0")) // FFFFh
							state: 2
						]
						cp = as-integer #";" [] ;do nothing
						cp = as-integer #"s" [	;-- Saves the current cursor position.
							console-store-position
							state: -1
						]
						cp = as-integer #"u" [ ;-- Returns the cursor to the position stored by the Save Cursor Position sequence.
							set-console-cursor saved-cursor
							state: -1
						]
						cp = as-integer #"K" [ ;-- Erase Line.
							clear-screen ERASE_LINE_END
							state: -1
						]
						cp = as-integer #"J" [ ;-- Clear screen from cursor down.
							clear-screen ERASE_DOWN
							state: -1
						]
						any [cp = as-integer #"H" cp = as-integer #"f"] [
							set-console-cursor 0
							state: -1
						]
						true [ state: -1 ]
					]
				]
				2 [ ;value1 continue
					case [
						all [cp >= as-integer #"0" cp <= as-integer #"9"][
							value1: ((value1 * 10) + (cp - as-integer #"0")) // FFFFh
						]
						cp = as-integer #";" [
							state: 3
						]
						cp = as-integer #"m" [
							update-graphic-mode pix value1
							state: -1
						]
						cp = as-integer #"A" [ ;-- Cursor Up.
							state: -1
						]
						cp = as-integer #"B" [ ;-- Cursor Down.
							state: -1
						]
						cp = as-integer #"C" [ ;-- Cursor Forward.
							state: -1
						]
						cp = as-integer #"D" [ ;-- Cursor Backward.
							state: -1
						]
						cp = as-integer #"J" [
							case [
								value1 = 1 [clear-screen ERASE_UP]
								value1 = 2 [clear-screen ERASE_SCREEN]
								true [] ;ignore other values
							]
							state: -1
						]
						cp = as-integer #"K" [
							case [
								value1 = 1 [clear-screen ERASE_LINE_START]
								value1 = 2 [clear-screen ERASE_LINE]
								true [] ;ignore other values
							]
							state: -1
						]
						true [ state: -1 ]
					]
				]
				3 [ ;value2 start
					case [
						all [cp >= as-integer #"0" cp <= as-integer #"9"][
							value2: ((value2 * 10) + (cp - as-integer #"0")) // FFFFh
							state: 4
						]
						cp = as-integer #";" [] ;do nothing
						true [ state: -1 ]
					]
				] ;value2 continue
				4 [
					case [
						all [cp >= as-integer #"0" cp <= as-integer #"9"][
							value2: ((value2 * 10) + (cp - as-integer #"0")) // FFFFh
						]
						cp = as-integer #"m" [
							update-graphic-mode pix value1
							update-graphic-mode pix value2
							state: -1 
						]
						cp = as-integer #";" [
							state: 5
						]
						any [cp = as-integer #"H" cp = as-integer #"f"] [ ;-- Cursor Position.
							set-console-cursor (value1 and 0000FFFFh) or (value2 << 16)
							state: -1
						]
						true [ state: -1 ]
					]
				]
				5 [ ;value3 start
					case [
						all [cp >= as-integer #"0" cp <= as-integer #"9"][
							value3: ((value3 * 10) + (cp - as-integer #"0")) // FFFFh
							state: 6
						]
						cp = as-integer #";" [] ;do nothing
						true [ state: -1 ]
					]
				]
				6 [ ;value3 continue
					case [
						all [cp >= as-integer #"0" cp <= as-integer #"9"][
							value3: ((value3 * 10) + (cp - as-integer #"0")) // FFFFh
						]
						cp = as-integer #"m" [
							case [
								all [value1 = 38 value2 = 5][
									pix/fg-color: MAKE_COLOR_256(value3)
								]
								all [value1 = 48 value2 = 5][
									pix/bg-color: MAKE_COLOR_256(value3)
								]
								true [
									update-graphic-mode pix value1
									update-graphic-mode pix value2
									update-graphic-mode pix value3
								]
							]
							state: -1 
						]
						cp = as-integer #";" [
							value1: 0 value2: 0 value3: 0
							state: 1
						]
						true [ state: -1 ]
					]
				]
			]
			state < 0
		]
		cnt
	]

	paint-background: func [
		x		[integer!]
		y		[integer!]
		w		[integer!]
		h		[integer!]
		bg		[integer!]
		/local
			p	[pixel!]
			i	[integer!]
			yy	[integer!]
	][
		yy: y + h
		while [y < yy][
			i: 0
			p: screen/buffer + (screen/width * y + x)
			while [i < w][
				p/code-point: 32	;-- whitespace char
				p/bg-color: bg
				p: p + 1
				i: i + 1
			]
			y: y + 1
		]
	]

	text-layout: func [
		str		[red-string!]
		box		[rect!]				;-- in
		bbox	[rect!]				;-- out
		align	[integer!]
		/local
			x y w h	[integer!]
			txt-w	[integer!]
			txt-h	[integer!]
	][
		x: 0
		y: 0
		w: box/right - box/left
		h: box/bottom - box/top

		txt-w: w txt-h: h
		if align <> 0 [
			size-text str w 0 :txt-w :txt-h
		]

		if txt-w < w [
			case [
				align and TEXT_ALIGN_CENTER <> 0 [
					x: w - txt-w / 2
				]
				align and TEXT_ALIGN_RIGHT <> 0 [
					x: w - txt-w
				]
				true [0]
			]
		]
		if txt-h < h [
			case [
				align and TEXT_ALIGN_VCENTER <> 0 [
					y: h - txt-h / 2
				]
				align and TEXT_ALIGN_BOTTOM <> 0 [
					y: h - txt-h
				]
				true [0]
			]
		]
		bbox/left: x
		bbox/top: y
		bbox/right: x + txt-w
		bbox/bottom: y + txt-h
	]

	render-text: func [
		str		[red-string!]
		pos-x	[integer!]		;-- screen coordinate
		pos-y	[integer!]		;-- screen coordinate
		box		[rect!]
		config	[render-config!]
		/local
			attr-str	[pixel!]
			end p		[pixel!]
			pix			[pixel! value]
			x y	n fg	[integer!]
			align flags	[integer!]
			cp unit		[integer!]
			dx dy		[integer!]
			w skip		[integer!]
			p-int		[int-ptr!]
			wrap?		[logic!]
			ansi?		[logic!]
			s			[series!]
			data		[byte-ptr!]
			tail		[byte-ptr!]
	][
		x: box/left
		y: box/top
		dx: box/right
		dy: box/bottom
		align: config/align
		flags: config/flags
		fg: config/fg-color
		w: pos-x
		wrap?: align and TEXT_WRAP_FLAG <> 0

		either null? config/rich-text [
			if TYPE_OF(str) <> TYPE_STRING [exit]
			ansi?: flags and PIXEL_ANSI_SEQ <> 0
			s:	  GET_BUFFER(str)
			unit: GET_UNIT(s)
			data: string/rs-head str
			tail: string/rs-tail str

			;-- skip abs(pos-y) lines if pos-y < y
			w: pos-x
			while [all [data < tail pos-y < y]][
				cp: string/get-char data unit
				if cp = as-integer lf [
					pos-y: pos-y + 1
					w: pos-x
					data: data + unit
					continue
				]
				n: char-width? cp
				w: w + n
				data: data + unit
				if all [wrap? w >= dx][		;-- wrap text
					pos-y: pos-y + 1
					w: pos-x
				]
			]

			;-- do drawing
			w: pos-x
			if pos-x > x [x: pos-x]
			if pos-y > y [y: pos-y]
			p: screen/buffer + (screen/width * y + x)
			while [all [data < tail y < dy]][
				cp: string/get-char data unit
				if all [cp = as-integer #"^[" ansi?][
					pix/fg-color: fg
					pix/flags: flags
					skip: parse-ansi-sequence data unit :pix
					if skip > 0 [
						fg: pix/fg-color
						flags: pix/flags
						data: data + (unit * skip)
						continue
					]
				]
				if cp = as-integer lf [
					y: y + 1
					p: screen/buffer + (screen/width * y + x)
					w: pos-x
					data: data + unit
					continue
				]

				n: char-width? cp
				;-- skip abs(pos-x) pixels if pos-x < x
				if w < x [
					data: data + unit
					w: w + n
					if w >= x [
						p: p + (w - x)
					]
					continue
				]

				w: w + n
				if w <= dx [
					p/code-point: cp
					p/fg-color: fg
					p/flags: flags
					loop n - 1 [
						p: p + 1
						p/flags: PIXEL_SKIP
					]
					p: p + 1
					data: data + unit
				]
				if w >= dx [
					either wrap? [		;-- wrap text
						y: y + 1
						p: screen/buffer + (screen/width * y + x)
						w: pos-x
					][					;-- skip to next line
						while [data < tail][
							cp: string/get-char data unit
							if cp = as-integer lf [break]
							data: data + unit
						]
					]
				]
			]
		][
			attr-str: as pixel! config/rich-text
			p-int: as int-ptr! attr-str
			attr-str: attr-str + 1
			end: attr-str + p-int/value

			;-- skip abs(pos-y) lines if pos-y < y
			while [all [attr-str < end pos-y < y]][
				cp: attr-str/code-point
				if cp = as-integer lf [
					pos-y: pos-y + 1
					w: pos-x
					attr-str: attr-str + 1
					continue
				]
				n: char-width? cp
				w: w + n
				attr-str: attr-str + 1
				if all [wrap? w >= dx][		;-- wrap text
					pos-y: pos-y + 1
					w: pos-x
				]
			]

			;-- do drawing
			w: pos-x
			if pos-x > x [x: pos-x]
			if pos-y > y [y: pos-y]
			p: screen/buffer + (screen/width * y + x)
			while [all [attr-str < end y < dy]][
				cp: attr-str/code-point
				if cp = as-integer lf [
					y: y + 1
					p: screen/buffer + (screen/width * y + x)
					w: pos-x
					attr-str: attr-str + 1
					continue
				]

				n: char-width? cp
				;-- skip abs(pos-x) pixels if pos-x < x
				if w < x [
					attr-str: attr-str + 1
					w: w + n
					if w >= x [
						p: p + (w - x)
					]
					continue
				]
				
				w: w + n
				if w <= dx [
					p/code-point: cp
					p/fg-color: attr-str/fg-color
					p/bg-color: attr-str/bg-color
					p/flags: attr-str/flags or flags
					loop n - 1 [
						p: p + 1
						p/flags: PIXEL_SKIP
					]
					p: p + 1
					attr-str: attr-str + 1
				]
				if w >= dx [
					either wrap? [		;-- wrap text
						y: y + 1
						p: screen/buffer + (screen/width * y + x)
						w: pos-x
					][					;-- skip to next line
						while [attr-str < end][
							cp: attr-str/code-point
							if cp = as-integer lf [break]
							attr-str: attr-str + 1
						]
					]
				]
			]
		]
	]

	get-clip-box: func [
		x		[integer!]	;-- screen coordinate
		y		[integer!]	;-- screen coordinate
		widget	[widget!]
		box		[rect!]
		/local
			w h		[integer!]
			px py	[integer!]
			xx yy	[integer!]
			off-x	[integer!]
			off-y	[integer!]
			parent	[widget!]
	][
		w: 0 h: 0
		get-size widget :w :h
		xx: x + w
		yy: y + h

		parent: widget/parent
		if WIDGET_TYPE(parent) <> window [
			;-- check if it clips with its parent
			w: 0 h: 0
			get-size parent :w :h
			off-x: as-integer widget/box/left
			off-y: as-integer widget/box/top
			px: x - off-x			;-- parent screen x pos
			py: y - off-y			;-- parent screen y pos
			if px + w < xx [xx: px + w]
			if py + h < yy [yy: py + h]
			if px > x [x: px]
			if py > y [y: py]
		]

		if xx > screen/width [xx: screen/width]
		if yy > screen/height [yy: screen/height]
		box/left: either x > 0 [x][0]
		box/top: either y > 0 [y][0]
		box/right: xx
		box/bottom: yy
	]

	render: func [
		x		[integer!]	;-- screen coordinate
		y		[integer!]	;-- screen coordinate
		widget	[widget!]
		flags	[integer!]
		/local
			values	[red-value!]
			str		[red-string!]
			color	[red-tuple!]
			font	[red-object!]
			options	[red-block!]
			draw	[red-block!]
			para	[red-object!]
			w h clr	[integer!]
			xx yy	[integer!]
			pos-x	[integer!]
			pos-y	[integer!]
			align	[integer!]
			box		[rect! value]
			bbox	[rect! value]
			rc		[rect!]
			config	[render-config! value]
			ctx		[draw-ctx! value]
			ui		[red-string! value]
	][
		values: get-face-values widget
		str:    as red-string! values + FACE_OBJ_TEXT
		color:  as red-tuple!  values + FACE_OBJ_COLOR
		font:   as red-object! values + FACE_OBJ_FONT
		para:	as red-object! values + FACE_OBJ_PARA
		options: as red-block! values + FACE_OBJ_OPTIONS

		zero-memory as byte-ptr! :config size? render-config!

		if TYPE_OF(color) = TYPE_TUPLE [
			clr: get-tuple-color color
			config/bg-color: make-color-256 clr
		]
		if TYPE_OF(font) = TYPE_OBJECT [
			clr: get-font-color font
			config/fg-color: make-color-256 clr
		]
		if TYPE_OF(para) = TYPE_OBJECT [
			config/align: get-para-flags para
		]

		xx: x yy: y
		get-clip-box x y widget :box
		x: box/left
		y: box/top
		w: box/right - x
		h: box/bottom - y
		if any [w <= 0 h <= 0][exit]

		;-- paint background
		paint-background x y w h config/bg-color

		;-- draw image
		if widget/image <> null [
			config/rich-text: as int-ptr! widget/image
			align: config/align
			config/align: TEXT_WRAP_FLAG
			render-text null xx yy :box :config
			config/align: align
		]

		;-- draw ui
		if widget/ui <> null [
			ui/header: TYPE_STRING
			ui/head: 0
			ui/node: widget/ui
			ui/cache: null
			config/flags: flags
			render-text ui xx yy :box :config			
		]

		;-- draw text
		if flags and PIXEL_IGNORE_TEXT = 0 [
			config/rich-text: null
			either all [TYPE_OF(str) = TYPE_STRING WIDGET_TYPE(widget) = rich-text][
				config/rich-text: widget/data
			][
				if all [
					any [
						TYPE_OF(str) <> TYPE_STRING
						zero? string/rs-length? str
					]
					TYPE_OF(options) = TYPE_BLOCK
				][
					str: as red-string! block/select-word options word/load "hint" no
					if TYPE_OF(str) = TYPE_STRING [
						flags: flags or PIXEL_FAINT
					]
				]
			]

			pos-x: xx
			pos-y: yy
			if TYPE_OF(str) = TYPE_STRING [
				get-size widget :w :h
				rc: as rect! :ctx/left
				rc/left: 0
				rc/top: 0
				rc/right: w
				rc/bottom: h
				text-layout str rc :bbox config/align
				pos-x: pos-x + bbox/left
				pos-y: pos-y + bbox/top
			]
			config/flags: flags
			render-text str pos-x pos-y :box :config
		]

		;-- do draw block
		draw: as red-block! values + FACE_OBJ_DRAW
		if any [TYPE_OF(draw) <> TYPE_BLOCK zero? block/rs-length? draw][exit]

		ctx/flags: flags
		ctx/dc: as handle! widget
		ctx/x: xx
		ctx/y: yy
		ctx/left: box/left
		ctx/top: box/top
		ctx/right: box/right
		ctx/bottom: box/bottom
		draw-begin :ctx as handle! widget null no yes
		parse-draw :ctx draw yes
		draw-end :ctx as handle! widget no no yes
	]
]