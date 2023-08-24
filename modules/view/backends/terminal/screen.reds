Red/System [
	Author: "Xie Qingtian"
	File: 	%screen.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

screen: context [

	active-win:			as window-manager! 0
	hover-widget:		as widget! 0		;-- the widget under the mouse
	focus-widget:		as widget! 0
	captured-widget:	as widget! 0
	captured:			as node! 0
	win-list:			as node! 0
	esc-sequences:		as node! 0			;-- escape sequences
	buffer:				as pixel! 0			;--a width x height 2-D plane
	back-buffer:		as pixel! 0
	width:				0
	height:				0
	relative-y:			0
	present?:			no
	cursor-x:			0
	cursor-y:			0

	init: func [][
		win-list: array/make 4 size? int-ptr!
		captured: array/make 16 size? int-ptr!
		esc-sequences: array/make 4000 1
	]

	windows-cnt: func [
		return: [integer!]
	][
		array/length? win-list
	]

	resize-buffer: func [
		wm [window-manager!]
		/local
			w h [integer!]
	][
		unless tty/raw-mode? [exit]

		w: as-integer wm/box/right - wm/box/left
		h: as-integer wm/box/bottom - wm/box/top

		if w > tty/columns [w: tty/columns]
		if h > tty/rows [h: tty/rows]

		if any [w <> width h <> height][
			if buffer <> null [free as byte-ptr! buffer]
			if back-buffer <> null [free as byte-ptr! back-buffer]
			width: w
			height: h
			buffer: as pixel! zero-alloc width * height * size? pixel!
			back-buffer: as pixel! zero-alloc width * height * size? pixel!
		]
	]

	free-buffer: does [
		free as byte-ptr! buffer
		free as byte-ptr! back-buffer
		buffer: as pixel! 0
		back-buffer: as pixel! 0
	]

	on-gc-mark: func [
		/local
			w	[window-manager!]
			s	[series!]
			p	[ptr-ptr!]
			e	[ptr-ptr!]
	][
		collector/keep win-list
		collector/keep captured
		collector/keep esc-sequences
	]

	update-bounding-box: func [
		widget	[widget!]
		/local
			win	[widget!]
			wm  [window-manager!]
			rc1	[RECT_F!]
			rc2 [RECT_F!]
	][
		win: widget/parent
		if all [win <> null win/type = window][
			wm: as window-manager! win/data
			rc1: wm/box
			rc2: widget/box
			if rc1/left > rc2/left [rc1/left: rc2/left]
			if rc1/top > rc2/top [rc1/top: rc2/top]
			if rc1/right < rc2/right [rc1/right: rc2/right]
			if rc1/bottom < rc2/bottom [rc1/bottom: rc2/bottom]
		]
	]

	update-editable-widget: func [
		widget	[widget!]
		/local
			win	[widget!]
			wm  [window-manager!]
	][
		if widget/type <> field [exit]

		win: widget/parent
		while [all [win <> null win/type <> window]][
			win: win/parent
		]
		if win <> null [
			wm: as window-manager! win/data
			wm/editable: wm/editable + 1
		]
	]

	add-window: func [
		widget	[widget!]
		return: [window-manager!]
		/local
			p	[window-manager!]
	][
		p: as window-manager! zero-alloc size? window-manager!
		p/window: widget
		p/focused: widget
		array/append-ptr win-list as int-ptr! p
		widget/data: as int-ptr! p
		p
	]

	remove-window: func [
		widget	[widget!]
		/local
			wm	[window-manager!]
	][
		wm: as window-manager! widget/data
		array/remove-ptr win-list as int-ptr! wm
		free as byte-ptr! wm
		active-win: as window-manager! array/pick-ptr win-list array/length? win-list
		focus-widget: active-win/focused
		hover-widget: null
		captured-widget: null
		array/clear captured
	]

	redraw: func [][present?: yes]

	set-cursor-bottom: func [/local dx [integer!]][
		if cursor-y > 0 [
			dx: height - relative-y
			prin "^M"
			tty/cursor-down dx
		]
	]

	render-widget: func [
		widget	[widget!]
		/local
			sym [integer!]
			p	[red-block!]
			obj [red-object!]
			end [red-object!]
	][
		if widget/flags and WIDGET_FLAG_HIDDEN <> 0 [exit]

		sym: WIDGET_TYPE(widget)
		widget/render widget

		p: CHILD_WIDGET(widget)
		if TYPE_OF(p) = TYPE_BLOCK [
			obj: as red-object! block/rs-head p
			end: as red-object! block/rs-tail p
			while [obj < end][
				render-widget as widget! get-face-handle obj
				obj: obj + 1
			]
		]
	]

	#define ADD_BYTE(byte) [array/append-byte esc-sequences byte]
	#define ADD_BYTES(data len) [array/append-bytes esc-sequences data len]
	#define ADD_STR(s) [array/append-bytes esc-sequences as byte-ptr! s length? s]

	emit-color: func [
		clr			[integer!]
		fg-color?	[logic!]
		/local
			type [integer!]
			s	 [c-string!]
			fmt  [c-string!]
			_buf [tiny-str! value]
	][
		ADD_STR("^[[")
		s: as c-string! :_buf
		type: clr >>> 24
		switch type [
		    default-color	[
			    s: either fg-color? ["39"]["49"]
			    ADD_STR(s)
		    ]
		    palette-16		[]
		    palette-256		[]
		    true-color		[
				clr: make-color clr
				fmt: either fg-color? ["38;5;%d"]["48;5;%d"]
				sprintf [s fmt clr]
				ADD_STR(s)
		    ]
		    default			[]
		]
		ADD_BYTE(#"m")
	]

	update-pixel-style: func [
		pre		[pixel!]
		p		[pixel!]
		return: [pixel!]
	][
		if all [
			p/flags and PIXEL_FAINT <> 0
			pre/flags and PIXEL_FAINT = 0
		][	;-- Faint
			ADD_STR("^[[2m")
		]

		if all [
			p/flags and PIXEL_FAINT = 0
			pre/flags and PIXEL_FAINT <> 0
		][	;-- Faint reset
			ADD_STR("^[[22m")
		]

		if all [
			p/flags and PIXEL_INVERTED <> 0
			pre/flags and PIXEL_INVERTED = 0
		][	;-- inverted
			ADD_STR("^[[7m")
		]

		if all [
			p/flags and PIXEL_INVERTED = 0
			pre/flags and PIXEL_INVERTED <> 0
		][	;-- inverted reset
			ADD_STR("^[[27m")
		]

		if pre/fg-color <> p/fg-color [
			emit-color p/fg-color yes
		]
		if pre/bg-color <> p/bg-color [
			emit-color p/bg-color no
		]
		p
	]

	present: func [
		/local
			x y  [integer!]
			p	 [pixel!]
			prev [pixel!]
			end  [pixel!]
			px	 [pixel! value]
			_buf [tiny-str! value]
			str  [byte-ptr!]
			n	 [integer!]
			cp	 [integer!]
			dy	 [integer!]
			s	 [c-string!]
	][
		LOG_MSG(["present: " width " " height " " relative-y])
		if any [width < 1 height < 1][exit]

		str: as byte-ptr! :_buf

		if relative-y > 0 [
			s: as c-string! str
			ADD_BYTE(#"^M")		;-- move left
			sprintf [s "^[[%dA" relative-y]	;-- move up
			ADD_STR(s)
			ADD_STR("^[[0J")	;-- erase down to the bottom of the screen
		]

		px/fg-color: 0
		px/bg-color: 0
		px/flags: 0
		prev: px
		end: px

		p: buffer
		y: 0
		until [
			x: 0
			until [
				if DRAW_PIXEL?(p) [
					prev: update-pixel-style prev p

					cp: p/code-point
					if zero? cp [cp: as-integer #" "]
					n: unicode/cp-to-utf8 cp str
					if n > 0 [ADD_BYTES(str n)]
				]

				p: p + 1
				x: x + 1
				x = width
			]
			y: y + 1
			if y < height [ADD_STR("^(0D)^(0A)")]	;-- cursor move to next line
			y = height
		]
		update-pixel-style prev end

		;-- set cursor position
		
		either all [
			WIDGET_EDITABLE?(focus-widget)
			any [cursor-x > 0 cursor-y > 0]
		][
			s: as c-string! str
			ADD_BYTE(#"^M")		;-- move left
			dy: height - cursor-y - 1
			if dy > 0 [
				sprintf [s "^[[%dA" dy]			;-- move up
				ADD_STR(s)
			]
			if cursor-x > 0 [
				sprintf [s "^[[%dC" cursor-x]	;-- move right
				ADD_STR(s)
			]
			relative-y: cursor-y
		][
			relative-y: height - 1
		]

		str: array/get-buffer esc-sequences
		tty/write str array/length? esc-sequences
		array/clear esc-sequences
		present?: no
	]

	render: func [
		/local
			wm [window-manager!]
	][
		unless present? [exit]

		wm: active-win
		resize-buffer wm
		render-widget wm/window
		present?: yes
		present
		either WIDGET_EDITABLE?(focus-widget) [
			tty/show-cursor
		][
			tty/hide-cursor
		]
		fflush 0
	]
]
