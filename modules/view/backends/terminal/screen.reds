Red/System [
	Author: "Xie Qingtian"
	File: 	%screen.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

screen: context [

	active-win:			as window-manager! 0
	current-win:		as widget! 0
	hover-widget:		as widget! 0		;-- the widget under the mouse
	focus-widget:		as widget! 0
	captured-widget:	as widget! 0
	captured:			as node! 0
	win-list:			as node! 0
	esc-sequences:		as node! 0			;-- escape sequences
	buffer:				as pixel! 0			;--a width x height 2-D plane
	width:				0
	height:				0
	relative-y:			0
	present?:			no
	cursor-x:			0
	cursor-y:			0
	offset-x:			0
	offset-y:			0
	alternate-screen?:	no
	in-alter-mode?:		no
	enter-tui?:			no

	init: func [][
		win-list: array/make 4 size? int-ptr!
		captured: array/make 16 size? int-ptr!
		esc-sequences: array/make 2000 1
	]

	enter-alter-screen: does [
		if all [alternate-screen? not in-alter-mode?][
			tty/enter-alter-screen
			in-alter-mode?: yes
		]
	]

	exit-alter-screen: does [
		if in-alter-mode? [
			tty/exit-alter-screen
			in-alter-mode?: no
		]
	]

	on-resize: func [
		w	[integer!]
		h	[integer!]
		/local
			g-evt	[widget-event! value]
			cnt i	[integer!]
			wm		[window-manager!]
			win		[widget!]
	][
		g-evt/pt/x: as float32! w
		g-evt/pt/y: as float32! h
		cnt: windows-cnt
		i: 1
		while [i <= cnt][
			wm: as window-manager! array/pick-ptr win-list i
			win: wm/window
			g-evt/widget: win
			win/on-event EVT_SIZE :g-evt
			if 0 <> win/face [
				make-event EVT_SIZE :g-evt 0
			]
			i: i + 1
		]
		if in-alter-mode? [
			render
		]
	]

	clear: does [
		if in-alter-mode? [
			tty/write as byte-ptr! "^[[2J" 4
			fflush 0
		]
	]

	reset: does [
		free-windows
		width:				0
		height:				0
		relative-y:			0
		present?:			no
		cursor-x:			0
		cursor-y:			0
		offset-x:			0
		offset-y:			0
		active-win:			null
		hover-widget:		null
		focus-widget:		null
		captured-widget:	null
		array/clear captured
		array/clear esc-sequences
		array/clear win-list
		free-buffer

		last-mouse-evt:		0
		mouse-click-delta:	0
		mouse-event?:		no
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
			if any [w > width h > height][		;-- require a bigger buffer
				if buffer <> null [free as byte-ptr! buffer]
				buffer: as pixel! allocate w * h * size? pixel!
			]
			width: w
			height: h
		]
	]

	set-buffer-size: func [
		win		[widget!]
		/local
			wm	[window-manager!]
			rc1	[RECT_F!]
			rc2 [RECT_F!]
	][
		wm: as window-manager! win/data
		rc1: wm/box
		rc2: win/box
		rc1/left: rc2/left
		rc1/top: rc2/top
		rc1/right: rc2/right
		rc1/bottom: rc2/bottom
		resize-buffer wm
	]

	clear-buffer: does [
		if buffer <> null [
			zero-memory as byte-ptr! buffer width * height * size? pixel!
		]
	]

	free-buffer: does [
		if buffer <> null [
			free as byte-ptr! buffer
			buffer: null
		]
	]

	_mark-widget: func [
		w		[widget!]
		/local
			p	[red-block!]
			obj [red-object!]
			end [red-object!]
			h	[handle!]
	][
		if w/ui <> null [collector/keep w/ui]
		p: CHILD_WIDGET(w)
		if TYPE_OF(p) = TYPE_BLOCK [
			obj: as red-object! block/rs-head p
			end: as red-object! block/rs-tail p
			while [obj < end][
				h: face-handle? obj
				if h <> null [
					_mark-widget as widget! h
				]
				obj: obj + 1
			]
		]
	]

	mark-widgets: func [
		/local
			cnt	[integer!]
			i	[integer!]
			wm	[window-manager!]
	][
		cnt: windows-cnt
		i: 1
		while [i <= cnt][
			wm: as window-manager! array/pick-ptr win-list i
			_mark-widget wm/window
			i: i + 1
		]
	]

	on-gc-mark: func [][
		collector/keep win-list
		collector/keep captured
		collector/keep esc-sequences
		mark-widgets
	]

	update-bounding-box: func [
		widget	[widget!]
		/local
			win	[widget!]
			wm  [window-manager!]
			rc1	[RECT_F!]
			rc2 [RECT_F!]
	][
		win: either widget/type = window [widget][widget/parent]
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
		unless WIDGET_EDITABLE?(widget) [exit]

		win: widget/parent
		while [all [win <> null win/type <> window]][
			win: win/parent
		]
		if win <> null [
			wm: as window-manager! win/data
			wm/editable: wm/editable + 1
		]
	]

	update-focus-widget: func [
		widget	[widget!]
		/local
			win	[widget!]
			wm  [window-manager!]
	][
		wm: as window-manager! current-win/data
		if any [
			wm/focused <> null
			widget/flags and WIDGET_FLAG_FOCUSABLE = 0
		][exit]

		win: widget/parent
		while [all [win <> null win/type <> window]][
			win: win/parent
		]
		if win <> null [
			wm: as window-manager! win/data
			set-focus-widget widget wm
		]
	]

	set-focus-widget: func [
		w			[widget!]
		wm			[window-manager!]
	][
		if null? wm [wm: active-win]
		WIDGET_UNSET_FLAG(focus-widget WIDGET_FLAG_FOCUS)
		send-event EVT_UNFOCUS focus-widget 0

		wm/focused: w
		focus-widget: w

		WIDGET_SET_FLAG(focus-widget WIDGET_FLAG_FOCUS)
		send-event EVT_FOCUS focus-widget 0
	]

	win-render-func: func [
		x			[integer!]
		y			[integer!]
		widget		[widget!]
	][0]

	add-window: func [
		widget	[widget!]
		return: [window-manager!]
		/local
			p	[window-manager!]
	][
		if widget/flags and WIDGET_FLAG_FULLSCREEN <> 0 [
			alternate-screen?: yes
		]
		current-win: widget
		if null? focus-widget [focus-widget: widget]
		p: as window-manager! zero-alloc size? window-manager!
		p/window: widget
		array/append-ptr win-list as int-ptr! p
		widget/data: as int-ptr! p
		widget/render: as render-func! :win-render-func
		p
	]

	init-window: func [
		wm		[window-manager!]
		/local
			w	[widget!]
	][
		w: either null? wm/focused [
			wm/window
		][
			wm/focused
		]
		active-win: wm
		set-focus-widget w wm

		if all [
			wm/editable = 0
			tty/raw-mode?
		][tty/hide-cursor]

		hover-widget: null
		captured-widget: null
		array/clear captured
	]

	remove-window: func [
		widget	[widget!]
		/local
			wm	[window-manager!]
	][
		wm: as window-manager! widget/data
		array/remove-ptr win-list as int-ptr! wm
		free as byte-ptr! wm
		if windows-cnt > 0 [
			active-win: as window-manager! array/pick-ptr win-list windows-cnt
			init-window active-win
		]
	]

	redraw: func [w [widget!]][
		if null? w [w: focus-widget]
		while [all [w <> null WIDGET_TYPE(w) <> window]][
			w: w/parent
		]
		if all [w <> null w/data = as int-ptr! active-win][
			present?: yes
		]
	]

	set-cursor-bottom: func [/local dx [integer!]][
		if cursor-y > 0 [
			dx: height - relative-y
			tty/cursor-down dx
		]
		tty/write as byte-ptr! "^M^/" 2
	]

	update-mouse-offset: func [][
		either alternate-screen? [
			offset-x: 0
			offset-y: 0
		][
			if offset-y + height > tty/rows [
				offset-y: tty/rows - height
			]
		]
	]

	render-widget: func [
		widget	[widget!]
		/local
			p	[red-block!]
			obj [red-object!]
			end [red-object!]
			x y [integer!]
	][
		if widget/flags and WIDGET_FLAG_HIDDEN <> 0 [exit]

		x: 0 y: 0
		_widget/to-screen-pt widget :x :y
		widget/render x y widget

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

	free-windows: func [
		/local
			cnt	[integer!]
			i	[integer!]
			w	[widget!]
			wm	[window-manager!]
			wins [node!]
	][
		wins: array/copy win-list
		cnt: windows-cnt
		i: 1
		while [i <= cnt][
			wm: as window-manager! array/pick-ptr wins i
			free-faces get-face-obj wm/window
			i: i + 1
		]
		array/clear wins
	]

	#define ADD_BYTE(byte) [array/append-byte esc-sequences byte]
	#define ADD_BYTES(data len) [array/append-bytes esc-sequences data len]
	#define ADD_STR(s) [array/append-bytes esc-sequences as byte-ptr! s length? s]

	reset-cursor: func [/local s [c-string!] _buf [tiny-str! value]][
		if enter-tui? [
			tty/write as byte-ptr! "^M" 1	;-- move to start of the line
			if relative-y > 0 [
				s: as c-string! :_buf
				sprintf [s "^[[%dA^[[0J" relative-y]	;-- move up and erase line
				tty/write as byte-ptr! s length? s
				relative-y: 0
			]
		]
	]

	emit-color: func [
		clr			[integer!]
		fg-color?	[logic!]
		/local
			type [integer!]
			idx  [integer!]
			s	 [c-string!]
			fmt  [c-string!]
			_buf [tiny-str! value]
			r g b [integer!]
	][
		ADD_STR("^[[")
		s: as c-string! :_buf
		type: clr >>> 24
		switch type [
		    default-color	[
			    s: either fg-color? ["39"]["49"]
		    ]
		    palette-16		[
			    clr: clr and 0Fh
			    idx: clr * 2 + as-integer fg-color?
			    idx: idx + 1	;-- 1-based
			    s: as c-string! color-16-table/idx
		    ]
		    palette-256		[
			    clr: clr and FFh
				fmt: either fg-color? ["38;5;%d"]["48;5;%d"]
				sprintf [s fmt clr]
		    ]
		    true-color		[
				r: clr and 00FF0000h >> 16 
				g: clr and FF00h >> 8
				b: clr and FFh
				fmt: either fg-color? ["38;2;%d;%d;%d"]["48;2;%d;%d;%d"]
				sprintf [s fmt r g b]
		    ]
		    default	[s: "0"]
		]
		ADD_STR(s)
		ADD_BYTE(#"m")
	]

	reset-color: func [
		fg-color?	[logic!]
		/local
			s	 [c-string!]
			_buf [tiny-str! value]
	][
		ADD_STR("^[[")
		s: as c-string! :_buf
		s: either fg-color? ["39"]["49"]
		ADD_STR(s)
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

		if all [
			p/flags and PIXEL_BOLD <> 0
			pre/flags and PIXEL_BOLD = 0
		][	;-- bold
			ADD_STR("^[[1m")
		]

		if all [
			p/flags and PIXEL_BOLD = 0
			pre/flags and PIXEL_BOLD <> 0
		][	;-- bold reset
			ADD_STR("^[[22m")
		]

		if all [
			p/flags and PIXEL_ITALIC <> 0
			pre/flags and PIXEL_ITALIC = 0
		][	;-- italic
			ADD_STR("^[[3m")
		]

		if all [
			p/flags and PIXEL_ITALIC = 0
			pre/flags and PIXEL_ITALIC <> 0
		][	;-- italic reset
			ADD_STR("^[[23m")
		]

		if all [
			p/flags and PIXEL_STRIKE <> 0
			pre/flags and PIXEL_STRIKE = 0
		][	;-- strike through
			ADD_STR("^[[9m")
		]

		if all [
			p/flags and PIXEL_STRIKE = 0
			pre/flags and PIXEL_STRIKE <> 0
		][	;-- strike through reset
			ADD_STR("^[[29m")
		]

		if all [
			p/flags and PIXEL_UNDERLINE <> 0
			pre/flags and PIXEL_UNDERLINE = 0
		][	;-- underline
			ADD_STR("^[[4m")
		]

		if all [
			p/flags and PIXEL_UNDERLINE = 0
			pre/flags and PIXEL_UNDERLINE <> 0
		][	;-- underline reset
			ADD_STR("^[[24m")
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
		if any [width < 1 height < 1][exit]

		present?: yes

		str: as byte-ptr! :_buf
		s: as c-string! str

		either alternate-screen? [
			ADD_STR("^[[H")		;-- move to top left
		][
			ADD_BYTE(#"^M")		;-- move left
			if relative-y > 0 [
				sprintf [s "^[[%dA" relative-y]	;-- move up
				ADD_STR(s)
			]
			ADD_STR("^[[0J")	;-- erase down to the bottom of the screen
		]

		px/fg-color: 0
		px/bg-color: 0
		px/flags: 0
		prev: px
		end: px

		y: 0
		until [
			p: buffer + (width * y)
			x: 0
			until [
				if DRAW_PIXEL?(p) [
					prev: update-pixel-style prev p

					either p/flags and PIXEL_PASSWORD = 0 [
						cp: p/code-point
						if zero? cp [cp: as-integer #" "]
					][
						cp: as-integer #"*"
					]
					n: unicode/cp-to-utf8 cp str
					if n > 0 [ADD_BYTES(str n)]
				]

				p: p + 1
				x: x + 1
				x = width
			]
			y: y + 1
			if y < height [
				prev/bg-color: 0
				ADD_STR("^[[49m^(0D)^(0A)")	;-- reset bg colors and cursor move to next line
			]
			y = height
		]
		update-pixel-style prev end

		;-- set cursor position
		
		either all [
			WIDGET_EDITABLE?(focus-widget)
			any [cursor-x >= 0 cursor-y >= 0]
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

		str: array/get-ptr esc-sequences
		tty/write str array/length? esc-sequences
		array/clear esc-sequences

		enter-tui?: yes
		present?: no
	]

	render: func [
		/local
			wm [window-manager!]
	][
		update-mouse-offset
		unless present? [exit]

		wm: active-win
		resize-buffer wm
		clear-buffer
		render-widget wm/window
		unless WIDGET_EDITABLE?(focus-widget) [
			tty/hide-cursor
		]
		fflush 0
		present
		if WIDGET_EDITABLE?(focus-widget) [
			tty/show-cursor
		]
		fflush 0
	]
]
