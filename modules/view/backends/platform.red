Red [
	Title:	"Platform-independent part of the GUI backend"
	Author: "Nenad Rakocevic, Xie Qingtian"
	File: 	%platform.red
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

system/view/platform: context [

	#system [
		gui: context [
			#enum facet! [
				FACE_OBJ_TYPE
				FACE_OBJ_OFFSET
				FACE_OBJ_SIZE
				FACE_OBJ_TEXT
				FACE_OBJ_IMAGE
				FACE_OBJ_COLOR
				FACE_OBJ_MENU
				FACE_OBJ_DATA
				FACE_OBJ_ENABLE?
				FACE_OBJ_VISIBLE?
				FACE_OBJ_SELECTED
				FACE_OBJ_FLAGS
				FACE_OBJ_OPTIONS
				FACE_OBJ_PARENT
				FACE_OBJ_PANE
				FACE_OBJ_STATE
				FACE_OBJ_RATE
				FACE_OBJ_EDGE
				FACE_OBJ_PARA
				FACE_OBJ_FONT
				FACE_OBJ_ACTORS
				FACE_OBJ_EXTRA
				FACE_OBJ_DRAW
			]
			
			#enum facet-flag! [
				FACET_FLAG_TYPE:		00000001h
				FACET_FLAG_OFFSET:		00000002h
				FACET_FLAG_SIZE:		00000004h
				FACET_FLAG_TEXT:		00000008h
				FACET_FLAG_IMAGE:		00000010h
				FACET_FLAG_COLOR:		00000020h
				FACET_FLAG_MENU:		00000040h
				FACET_FLAG_DATA:		00000080h
				FACET_FLAG_ENABLE?:		00000100h
				FACET_FLAG_VISIBLE?:	00000200h
				FACET_FLAG_SELECTED:	00000400h
				FACET_FLAG_FLAGS:		00000800h
				FACET_FLAG_OPTIONS:		00001000h
				FACET_FLAG_PARENT:		00002000h
				FACET_FLAG_PANE:		00004000h
				FACET_FLAG_STATE:		00008000h
				FACET_FLAG_RATE:		00010000h
				FACET_FLAG_EDGE:		00020000h
				FACET_FLAG_PARA:		00040000h
				FACET_FLAG_FONT:		00080000h	;-- keep in sync with value in update-font-faces function
				FACET_FLAG_ACTOR:		00100000h
				FACET_FLAG_EXTRA:		00200000h
				FACET_FLAG_DRAW:		00400000h
			]
			
			#enum flags-flag! [
				FACET_FLAGS_ALL_OVER:	00000001h

				FACET_FLAGS_EDITABLE:	00040000h
				FACET_FLAGS_SCROLLABLE:	00080000h

				FACET_FLAGS_D2D:		00100000h

				FACET_FLAGS_POPUP:		01000000h
				FACET_FLAGS_MODAL:		02000000h
				FACET_FLAGS_RESIZE:		04000000h
				FACET_FLAGS_NO_BTNS:	08000000h
				FACET_FLAGS_NO_MAX:		10000000h
				FACET_FLAGS_NO_MIN:		20000000h
				FACET_FLAGS_NO_TITLE:	40000000h
				FACET_FLAGS_NO_BORDER:	80000000h
			]
			
			#enum font-facet! [
				FONT_OBJ_NAME
				FONT_OBJ_SIZE
				FONT_OBJ_STYLE
				FONT_OBJ_ANGLE
				FONT_OBJ_COLOR
				FONT_OBJ_ANTI-ALIAS?
				FONT_OBJ_SHADOW
				FONT_OBJ_STATE
				FONT_OBJ_PARENT
			]
			
			#enum para-facet! [
				PARA_OBJ_ORIGIN
				PARA_OBJ_PADDING
				PARA_OBJ_SCROLL
				PARA_OBJ_ALIGN
				PARA_OBJ_V-ALIGN
				PARA_OBJ_WRAP?
				PARA_OBJ_PARENT
			]

			#enum text-box-facet! [
				TBOX_OBJ_TEXT
				TBOX_OBJ_SIZE
				TBOX_OBJ_FONT
				TBOX_OBJ_PARA
				TBOX_OBJ_SPACING
				TBOX_OBJ_TABS
				TBOX_OBJ_STYLES
				TBOX_OBJ_STATE
				TBOX_OBJ_TARGET
				TBOX_OBJ_FIXED?
				TBOX_OBJ_WIDTH
				TBOX_OBJ_HEIGHT
				TBOX_OBJ_LINE_COUNT
			]

			#enum scroller-facet! [
				SCROLLER_OBJ_POS
				SCROLLER_OBJ_PAGE
				SCROLLER_OBJ_MIN
				SCROLLER_OBJ_MAX
				SCROLLER_OBJ_VISIBLE?
				SCROLLER_OBJ_VERTICAL?
				SCROLLER_OBJ_PARENT
			]

			#enum event-type! [
				EVT_LEFT_DOWN:		1
				EVT_LEFT_UP
				EVT_MIDDLE_DOWN
				EVT_MIDDLE_UP
				EVT_RIGHT_DOWN
				EVT_RIGHT_UP
				EVT_AUX_DOWN
				EVT_AUX_UP
				EVT_CLICK
				EVT_DBL_CLICK
				EVT_WHEEL
				EVT_OVER								;-- last mouse event

				EVT_KEY
				EVT_KEY_DOWN
				EVT_KEY_UP
				EVT_IME
				EVT_FOCUS
				EVT_UNFOCUS
				EVT_ENTER
				
				EVT_ZOOM
				EVT_PAN
				EVT_ROTATE
				EVT_TWO_TAP
				EVT_PRESS_TAP
				
				EVT_SELECT
				EVT_CHANGE
				EVT_MENU
				
				EVT_CLOSE								;-- window events
				EVT_MOVE
				EVT_SIZE
				EVT_MOVING
				EVT_SIZING
				EVT_TIME
				EVT_DRAWING
				EVT_SCROLL
			]
			
			#enum event-flag! [
				EVT_FLAG_AX2_DOWN:		00200000h
				EVT_FLAG_AUX_DOWN:		00400000h
				EVT_FLAG_ALT_DOWN:		00800000h
				EVT_FLAG_MID_DOWN:		01000000h
				EVT_FLAG_DOWN:			02000000h
				EVT_FLAG_AWAY:			04000000h
				EVT_FLAG_DBL_CLICK:		08000000h
				EVT_FLAG_CTRL_DOWN:		10000000h
				EVT_FLAG_SHIFT_DOWN:	20000000h
				EVT_FLAG_MENU_DOWN:		40000000h		;-- ALT key
				EVT_FLAG_CMD_DOWN:		80000000h		;-- Command/WIN key
				;EVT_FLAG_KEY_SPECIAL:	80000000h		;@@ deprecated
			]

			#enum pen-type! [
				PEN_COLOR
				PEN_WIDTH
				PEN_LINE_CAP
				PEN_LINE_JOIN
			]
			
			facets: context [
				type:		symbol/make "type"
				offset:		symbol/make "offset"
				size:		symbol/make "size"
				text:		symbol/make "text"
				image:		symbol/make "image"
				color:		symbol/make "color"
				menu:		symbol/make "menu"
				data:		symbol/make "data"
				enable?:	symbol/make "enable?"
				visible?:	symbol/make "visible?"
				selected:	symbol/make "selected"
				flags:		symbol/make "flags"
				parent:		symbol/make "parent"
				pane:		symbol/make "pane"
				state:		symbol/make "state"
				rate:		symbol/make "rate"
				edge:		symbol/make "edge"
				actors:		symbol/make "actors"
				extra:		symbol/make "extra"
				draw:		symbol/make "draw"
			]
			
			_para: context [
				origin: 	symbol/make "origin"
				padding:	symbol/make "padding"
				scroll:		symbol/make "scroll"
				align:		symbol/make "align"
				v-align:	symbol/make "v-align"
				wrap?:		symbol/make "wrap?"
				left:		symbol/make "left"
				center:		symbol/make "center"
				right:		symbol/make "right"
				top:		symbol/make "top"
				middle:		symbol/make "middle"
				bottom:		symbol/make "bottom"
			]

			screen:			symbol/make "screen"
			window:			symbol/make "window"
			button:			symbol/make "button"
			check:			symbol/make "check"
			radio:			symbol/make "radio"
			field:			symbol/make "field"
			area:			symbol/make "area"
			text:			symbol/make "text"
			text-list:		symbol/make "text-list"
			progress:		symbol/make "progress"
			slider:			symbol/make "slider"
			drop-down:		symbol/make "drop-down"
			drop-list:		symbol/make "drop-list"
			_image:			symbol/make "image"
			base:			symbol/make "base"
			panel:			symbol/make "panel"
			tab-panel:		symbol/make "tab-panel"
			group-box:		symbol/make "group-box"
			camera:			symbol/make "camera"
			caret:			symbol/make "caret"
			scroller:		symbol/make "scroller"

			---:			symbol/make "---"
			done:			symbol/make "done"
			_continue:		symbol/make "continue"
			stop:			symbol/make "stop"
			
			ClearType:		symbol/make "ClearType"
			_bold:			symbol/make "bold"
			_italic:		symbol/make "italic"
			_underline:		symbol/make "underline"
			_strike:		symbol/make "strike"
			_border:		symbol/make "border"
			_backdrop:		symbol/make "backdrop"
			_font-name:		symbol/make "font-name"
			_font-size:		symbol/make "font-size"
			
			all-over:		symbol/make "all-over"
			over:			symbol/make "over"
			draggable:		symbol/make "draggable"
			resize:			symbol/make "resize"
			no-title:		symbol/make "no-title"
			no-border:		symbol/make "no-border"
			no-min:			symbol/make "no-min"
			no-max:			symbol/make "no-max"
			no-buttons:		symbol/make "no-buttons"
			modal:			symbol/make "modal"
			popup:			symbol/make "popup"
			scrollable:		symbol/make "scrollable"
			editable:		symbol/make "editable"

			Direct2D:		symbol/make "Direct2D"

			_cursor:		symbol/make "cursor"
			_arrow:			symbol/make "arrow"
			_hand:			symbol/make "hand"
			_I-beam:		symbol/make "I-beam"
			_cross:			symbol/make "cross"

			on-over:		symbol/make "on-over"
			_actors:		word/load "actors"
			_scroller:		word/load "scroller"

			_text:			word/load "text"
			_data:			word/load "data"
			_control:		word/load "control"
			_shift:			word/load "shift"
			_command:		word/load "command"
			_alt:			word/load "alt"
			_away:			word/load "away"
			_down:			word/load "down"
			_up:			word/load "up"
			_mid-down:		word/load "mid-down"
			_mid-up:		word/load "mid-up"
			_alt-down:		word/load "alt-down"
			_alt-up:		word/load "alt-up"
			_aux-down:		word/load "aux-down"
			_aux-up:		word/load "aux-up"
			_wheel:			word/load "wheel"
			_click:			word/load "click"
			_dbl-click:		word/load "dbl-click"
			_over:			word/load "over"
			_key:			word/load "key"
			_key-down:		word/load "key-down"
			_key-up:		word/load "key-up"
			_ime:			word/load "ime"
			_focus:			word/load "focus"
			_unfocus:		word/load "unfocus"
			_select:		word/load "select"
			_change:		word/load "change"
			_enter:			word/load "enter"
			_menu:			word/load "menu"
			_close:			word/load "close"
			_move:			word/load "move"
			_resize:		word/load "resize"
			_moving:		word/load "moving"
			_resizing:		word/load "resizing"
			_zoom:			word/load "zoom"
			_pan:			word/load "pan"
			_rotate:		word/load "rotate"
			_two-tap:		word/load "two-tap"
			_press-tap:		word/load "press-tap"
			_time:			word/load "time"
			_drawing:		word/load "drawing"
			_scroll:		word/load "scroll"

			_track:			word/load "track"
			_page-left:		word/load "page-left"
			_page-right:	word/load "page-right"
			_page-up:		word/load "page-up"
			_page-down:		word/load "page-down"
			_end:			word/load "end"
			_home:			word/load "home"
			_left:			word/load "left"
			_up:			word/load "up"
			_right:			word/load "right"
			_down:			word/load "down"
			_insert:		word/load "insert"
			_delete:		word/load "delete"
			_F1:			word/load "F1"
			_F2:			word/load "F2"
			_F3:			word/load "F3"
			_F4:			word/load "F4"
			_F5:			word/load "F5"
			_F6:			word/load "F6"
			_F7:			word/load "F7"
			_F8:			word/load "F8"
			_F9:			word/load "F9"
			_F10:			word/load "F10"
			_F11:			word/load "F11"
			_F12:			word/load "F12"
			_left-shift:	word/load "left-shift"
			_right-shift:	word/load "right-shift"
			_left-control:	word/load "left-control"
			_right-control:	word/load "right-control"
			_left-alt:		word/load "left-alt"
			_right-alt:		word/load "right-alt"
			_left-menu:		word/load "left-menu"
			_right-menu:	word/load "right-menu"
			_left-command:	word/load "left-command"
			_right-command:	word/load "right-command"
			_caps-lock:		word/load "caps-lock"
			_num-lock:		word/load "num-lock"

			get-event-type: func [
				evt		[red-event!]
				return: [red-value!]
			][
				as red-value! switch evt/type [
					EVT_TIME		 [_time]
					EVT_DRAWING		 [_drawing]
					EVT_SCROLL		 [_scroll]
					EVT_LEFT_DOWN	 [_down]
					EVT_LEFT_UP		 [_up]
					EVT_MIDDLE_DOWN	 [_mid-down]
					EVT_MIDDLE_UP	 [_mid-up]
					EVT_RIGHT_DOWN	 [_alt-down]
					EVT_RIGHT_UP	 [_alt-up]
					EVT_AUX_DOWN	 [_aux-down]
					EVT_AUX_UP		 [_aux-up]
					EVT_WHEEL		 [_wheel]
					EVT_CLICK		 [_click]
					EVT_DBL_CLICK	 [_dbl-click]
					EVT_OVER		 [_over]
					EVT_KEY			 [_key]
					EVT_KEY_DOWN	 [_key-down]
					EVT_KEY_UP		 [_key-up]
					EVT_IME			 [_ime]
					EVT_FOCUS		 [_focus]
					EVT_UNFOCUS		 [_unfocus]
					EVT_SELECT	 	 [_select]
					EVT_CHANGE		 [_change]
					EVT_ENTER		 [_enter]
					EVT_MENU		 [_menu]
					EVT_CLOSE		 [_close]
					EVT_MOVE		 [_move]
					EVT_SIZE		 [_resize]
					EVT_MOVING		 [_moving]
					EVT_SIZING		 [_resizing]
					EVT_ZOOM		 [_zoom]
					EVT_PAN			 [_pan]
					EVT_ROTATE		 [_rotate]
					EVT_TWO_TAP		 [_two-tap]
					EVT_PRESS_TAP	 [_press-tap]
				]
			]
			
			set-event-type: func [
				evt		[red-event!]
				word	[red-word!]
				/local
					sym [integer!]
			][
				sym: symbol/resolve word/symbol
				case [
					sym = _time/symbol			[sym: EVT_TIME]
					sym = _drawing/symbol		[sym: EVT_DRAWING]
					sym = _scroll/symbol		[sym: EVT_SCROLL]
					sym = _down/symbol			[sym: EVT_LEFT_DOWN]
					sym = _up/symbol			[sym: EVT_LEFT_UP]
					sym = _mid-down/symbol		[sym: EVT_MIDDLE_DOWN]
					sym = _mid-up/symbol		[sym: EVT_MIDDLE_UP]
					sym = _alt-down/symbol		[sym: EVT_RIGHT_DOWN]
					sym = _alt-up/symbol		[sym: EVT_RIGHT_UP]
					sym = _aux-down/symbol		[sym: EVT_AUX_DOWN]
					sym = _aux-up/symbol		[sym: EVT_AUX_UP]
					sym = _wheel/symbol			[sym: EVT_WHEEL]
					sym = _click/symbol			[sym: EVT_CLICK]
					sym = _dbl-click/symbol		[sym: EVT_DBL_CLICK]
					sym = _over/symbol			[sym: EVT_OVER]
					sym = _key/symbol			[sym: EVT_KEY]
					sym = _key-down/symbol		[sym: EVT_KEY_DOWN]
					sym = _key-up/symbol		[sym: EVT_KEY_UP]
					sym = _ime/symbol			[sym: EVT_IME]
					sym = _focus/symbol			[sym: EVT_FOCUS]
					sym = _unfocus/symbol		[sym: EVT_UNFOCUS]
					sym = _select/symbol		[sym: EVT_SELECT]
					sym = _change/symbol		[sym: EVT_CHANGE]
					sym = _enter/symbol			[sym: EVT_ENTER]
					sym = _menu/symbol			[sym: EVT_MENU]
					sym = _close/symbol			[sym: EVT_CLOSE]
					sym = _move/symbol			[sym: EVT_MOVE]
					sym = _resize/symbol		[sym: EVT_SIZE]
					sym = _moving/symbol		[sym: EVT_MOVING]
					sym = _resizing/symbol		[sym: EVT_SIZING]
					sym = _zoom/symbol			[sym: EVT_ZOOM]
					sym = _pan/symbol			[sym: EVT_PAN]
					sym = _rotate/symbol		[sym: EVT_ROTATE]
					sym = _two-tap/symbol		[sym: EVT_TWO_TAP]
					sym = _press-tap/symbol		[sym: EVT_PRESS_TAP]
					true [
						fire [TO_ERROR(script not-event-type) word]
					]
				]
				evt/type: sym
			]

			#import  [
			LIBM-file cdecl [
				fabsf: "fabsf" [
					x			[float32!]
					return:		[float32!]
				]
				sinf:		 "sinf" [
					radians		[float32!]
					return:		[float32!]
				]
				cosf:		 "cosf" [
					radians		[float32!]
					return:		[float32!]
				]
				tanf:		 "tanf" [
					radians		[float32!]
					return:		[float32!]
				]
				asinf:		 "asinf" [
					radians		[float32!]
					return:		[float32!]
				]
				acosf:		 "acosf" [
					radians		[float32!]
					return:		[float32!]
				]
				atanf:		 "atanf" [
					radians		[float32!]
					return:		[float32!]
				]
				atan2f:		 "atan2f" [
					y			[float32!]
					x			[float32!]
					return:		[float32!]
				]
				sqrtf:		"sqrtf" [
					x			[float32!]
					return:		[float32!]
				]
			]]

			;#include %android/gui.reds
			#switch OS [
				Windows  [#include %windows/gui.reds]
				MacOSX   [#include %osx/gui.reds]
				#default []					;-- Linux
			]
		]
	]
	
	make-null-handle: routine [][handle/box 0]

	get-screen-size: routine [
		id		[integer!]
		/local
			pair [red-pair!]
	][
		pair: gui/get-screen-size id
		SET_RETURN(pair)
	]
	
	size-text: routine [
		face  [object!]
		value
		/local
			values [red-value!]
			text   [red-string!]
			pair   [red-pair!]
			font   [red-object!]
			state  [red-block!]
			hFont  [int-ptr!]							;-- handle!
	][
		;@@ check if object is a face?
		values: object/get-values face
		switch TYPE_OF(value) [
			TYPE_STRING [text: as red-string! value]
			TYPE_NONE   [text: as red-string! values + gui/FACE_OBJ_TEXT]
			default     [fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(value)]]
		]
		if TYPE_OF(text) <> TYPE_STRING [
			SET_RETURN(none-value)
			exit
		]

		font: as red-object! values + gui/FACE_OBJ_FONT
		hFont: either TYPE_OF(font) = TYPE_OBJECT [
			state: as red-block! (object/get-values font) + gui/FONT_OBJ_STATE
			either TYPE_OF(state) <> TYPE_BLOCK [gui/make-font face font][gui/get-font-handle font 0]
		][
			null
		]
		pair: as red-pair! stack/arguments
		pair/header: TYPE_PAIR
		
		gui/get-text-size text hFont pair
	]
	
	on-change-facet: routine [
		owner  [object!]
		word   [word!]
		value  [any-type!]
		action [word!]
		new	   [any-type!]
		index  [integer!]
		part   [integer!]
	][
		if TYPE_OF(new) = TYPE_NONE [new: null]
		gui/OS-update-facet owner word value action new index part
	]
	
	update-font: routine [font [object!] flags [integer!]][
		gui/update-font font flags
		SET_RETURN(none-value)
	]
	
	update-para: routine [face [object!] flags [integer!]][
		gui/update-para face flags
		SET_RETURN(none-value)
	]
	
	destroy-view: routine [face [object!] empty? [logic!]][
		gui/OS-destroy-view face empty?
		SET_RETURN(none-value)
	]
	
	update-view: routine [face [object!]][
		gui/OS-update-view face
		SET_RETURN(none-value)
	]

	refresh-window: routine [h [handle!]][
		gui/OS-refresh-window h/value
	]

	redraw: routine [face [object!] /local h [integer!]][
		h: as-integer gui/face-handle? face
		if h <> 0 [gui/OS-redraw h]
	]

	show-window: routine [id [handle!]][
		gui/OS-show-window id/value
		SET_RETURN(none-value)
	]

	make-view: routine [face [object!] parent [handle!]][
		handle/box gui/OS-make-view face parent/value
	]

	draw-image: routine [image [image!] cmds [block!]][
		gui/OS-do-draw image cmds
	]

	draw-face: routine [face [object!] cmds [block!] /local int [red-integer!]][
		int: as red-integer! (object/get-values face) + gui/FACE_OBJ_DRAW
		gui/OS-draw-face as draw-ctx! int/value cmds
	]

	do-event-loop: routine [no-wait? [logic!] /local bool [red-logic!]][
		bool: as red-logic! stack/arguments
		bool/header: TYPE_LOGIC
		bool/value:  gui/do-events no-wait?
	]

	request-font: routine [font [object!] selected [object!] mono? [logic!]][
		gui/OS-request-font font selected mono?
	]

	request-file: routine [
		title	[string!]
		name	[file!]
		filter	[block!]
		save?	[logic!]
		multi?	[logic!]
	][
		stack/set-last gui/OS-request-file title name filter save? multi?
	]

	request-dir: routine [
		title	[string!]
		dir		[file!]
		filter	[block!]
		keep?	[logic!]
		multi?	[logic!]
	][
		stack/set-last gui/OS-request-dir title dir filter keep? multi?
	]

	text-box-layout: routine [
		box		[object!]
	][
		gui/OS-text-box-layout box null no
	]

	text-box-metrics: routine [
		state	[block!]
		arg0	[any-type!]
		type	[integer!]
	][
		stack/set-last gui/OS-text-box-metrics state arg0 type
	]

	update-scroller: routine [scroller [object!] flags [integer!]][
		gui/update-scroller scroller flags
		SET_RETURN(none-value)
	]

	init: func [/local svs fonts][
		system/view/screens: svs: make block! 6

		#system [gui/init]

		extend system/view/metrics/margins [#switch config/OS [
			Windows [
				button:		[1x1   1x1]					;-- LeftxRight TopxBottom
				tab-panel:	[0x2   0x1]
				text-list:	[0x0   0x15]
			]
			MacOSX [
				button:		[6x6   0x3]
			]
		]]
		extend system/view/metrics/paddings [#switch config/OS [
			Windows [
				check:		[16x0  0x0]					;-- 13 + 3 for text padding
				radio:		[16x0  0x0]					;-- 13 + 3 for text padding
				;slider: 	[7x7   3x0]
				group-box:	[3x3  15x3]
				tab-panel:	[0x2   0x1]
			]
			MacOSX [
				button:		[7x7   0x0]
				check:		[20x0  3x1]
				radio:		[20x0  1x1]
			]
		]]

		append svs make face! [							;-- default screen
			type:	'screen
			offset: 0x0
			size:	get-screen-size 0
			pane:	make block! 4
			state:	reduce [make-null-handle 0 none copy [1]]
		]
		
		set fonts:
			bind [fixed sans-serif serif] system/view/fonts
			switch system/platform [
				Windows [["Courier New" "Arial" "Times"]
			]
		]
		
		set [font-fixed font-sans-serif font-serif] reduce fonts
	]
	
	version: none
	build:	 none
	product: none
	
	init
]
