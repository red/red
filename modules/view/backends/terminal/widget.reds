Red/System [
	Title:	"Widget related functions"
	Author: "Xie Qingtian"
	File: 	%widget.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019 Red Foundation. All rights reserved."
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
					g/box/left <= x x <= g/box/right
					g/box/top <= y y <= g/box/bottom
				]
			][
				return g
			]
		]
		null
	]

	delete: func [
		w [widget!]
	][
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

	render-text: func [
		x		[integer!]
		y		[integer!]
		widget	[widget!]
		flags	[integer!]
		/local
			values	[red-value!]
			str		[red-string!]
			color	[red-tuple!]
			font	[red-object!]
			options	[red-block!]
			i len	[integer!]
			p		[pixel!]
			n cnt	[integer!]
			w h		[integer!]
			dx dy	[integer!]
			fg bg	[integer!]
	][
		values: get-face-values widget
		str:    as red-string! values + FACE_OBJ_TEXT
		color:  as red-tuple!  values + FACE_OBJ_COLOR
		font:   as red-object! values + FACE_OBJ_FONT
		options: as red-block! values + FACE_OBJ_OPTIONS

		bg: 0 fg: 0
		if TYPE_OF(color) = TYPE_TUPLE [
			bg: true-color << 24 or get-tuple-color color
		]

		if TYPE_OF(font) = TYPE_OBJECT [
			fg: true-color << 24 or get-font-color font
		]

		dx: screen/width - x
		dy: screen/height - y
		w: 0 h: 0
		_widget/get-size widget :w :h
		if w < dx [dx: w]
		if h < dy [dy: h]

		if any [dx <= 0 dy <= 0][exit]

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

		p: screen/buffer + (screen/width * y + x)
		cnt: 0
		if TYPE_OF(str) = TYPE_STRING [
			i: str/head
			len: string/rs-length? str
			while [all [i < len cnt < dx]][
				p/code-point: string/rs-abs-at str i
				p/bg-color: bg
				p/fg-color: fg
				p/flags: flags
				n: char-width? p/code-point
				loop n - 1 [
					p: p + 1
					p/flags: flags or PIXEL_SKIP
				]
				cnt: cnt + n
				p: p + 1
				i: i + 1
			]
		]
		while [cnt < dx][
			p/code-point: 0
			p/bg-color: bg
			p/fg-color: fg
			p: p + 1
			cnt: cnt + 1
		]

		dy: y + dy
		y: y + 1
		while [y < dy][
			i: 0
			p: screen/buffer + (screen/width * y + x)
			while [i < dx][
				p/code-point: 0
				p/bg-color: bg
				p/fg-color: fg
				p: p + 1
				i: i + 1
			]
			y: y + 1
		]
	]
]