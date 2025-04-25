Red [
	Title:	"Platform-independent part of the GUI backend"
	Author: "Nenad Rakocevic, Xie Qingtian"
	File: 	%platform.red
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#switch config/GUI-engine [
	native   [#if config/OS = 'Android [#include %android/gui.red]]
	terminal [#include %terminal/make-ui.red]
	test     [#include %test/gui.red]
]

system/view/platform: context [

	#system [

		view-log-level: 0

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
				FACE_OBJ_ENABLED?
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
				FACE_OBJ_ONCHANGE
				FACE_OBJ_ONDEEPCHANGE
				FACE_OBJ_EXT1
				FACE_OBJ_EXT2
				FACE_OBJ_EXT3
				FACE_OBJ_EXT4
				FACE_OBJ_EXT5
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
				FACET_FLAG_ENABLED?:	00000100h
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
				FACET_FLAGS_FOCUSABLE:	00000002h
				
				FACET_FLAGS_TRISTATE:	00020000h
				FACET_FLAGS_SCROLLABLE:	00040000h
				FACET_FLAGS_PASSWORD:	00080000h
				FACET_FLAGS_NO_SYNC:	00100000h
				FACET_FLAGS_FULLSCREEN:	00200000h

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
			red/boot?: yes								;-- forces words allocation in root block
			
			facets: context [
				type:		symbol/make "type"
				offset:		symbol/make "offset"
				size:		symbol/make "size"
				text:		symbol/make "text"
				image:		symbol/make "image"
				color:		symbol/make "color"
				menu:		symbol/make "menu"
				data:		symbol/make "data"
				enabled?:	symbol/make "enabled?"
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
				top:		symbol/make-opt "top"
				middle:		symbol/make "middle"
				bottom:		symbol/make "bottom"
			]

			screen:			symbol/make "screen"
			window:			symbol/make "window"
			button:			symbol/make "button"
			toggle:			symbol/make "toggle"
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
			rich-text:		symbol/make "rich-text"
			calendar:		symbol/make "calendar"

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
			_class:			symbol/make "class"
			_regular:		symbol/make "regular"
			_small:			symbol/make "small"
			_mini:			symbol/make "mini"
			
			all-over:		symbol/make "all-over"
			focusable:		symbol/make "focusable"
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
			tri-state:		symbol/make "tri-state"
			scrollable:		symbol/make "scrollable"
			password:		symbol/make "password"
			no-sync:		symbol/make "no-sync"
			fullscreen:		symbol/make "fullscreen"

			_accelerated:	symbol/make "accelerated"

			_cursor:		symbol/make "cursor"
			_arrow:			symbol/make "arrow"
			_hand:			symbol/make "hand"
			_I-beam:		symbol/make "I-beam"
			_cross:			symbol/make "cross"
			_resize-ns:		symbol/make "resize-ns"
			_resize-we:		symbol/make "resize-we"
			_resize-ew:		symbol/make "resize-ew"

			_drag-on:		symbol/make "drag-on"
			_actors:		word/load "actors"
			_scroller:		word/load "scroller"
			_window:		word/load "window"
			_panel:			word/load "panel"

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
			_ratio:			word/load "ratio"

			_vertical:		word/load "vertical"
			_horizontal:	word/load "horizontal"
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
			_scroll-lock:	word/load "scroll-lock"
			_pause:			word/load "pause"

			red/boot?: no
			red/collector/active?: yes

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

			get-tuple-color: func [
				tp		[red-tuple!]
				return: [integer!]
				/local
					color [integer!]
			][
				color: tp/array1
				if TUPLE_SIZE?(tp) = 3 [color: color and 00FFFFFFh]
				color
			]

			as-point2D: func [
				pair	[red-pair!]
				return: [red-point2D!]
				/local
					x y [float32!]
					pt  [red-point2D!]
			][
				pt: as red-point2D! pair
				x: as float32! pair/x
				y: as float32! pair/y
				pt/x: x
				pt/y: y
				pt/header: TYPE_POINT2D
				pt
			]

			as-pair: func [
				pt		[red-point2D!]
				return: [red-pair!]
				/local
					x y [integer!]
					pair [red-pair!]
			][
				pair: as red-pair! pt
				x: as-integer pt/x
				y: as-integer pt/y
				pair/x: x
				pair/y: y
				pair/header: TYPE_PAIR
				pair
			]

			get-flags: func [
				field	[red-block!]
				return: [integer!]									;-- return a bit-array of all flags
				/local
					word  [red-word!]
					len	  [integer!]
					sym	  [integer!]
					flags [integer!]
			][
				switch TYPE_OF(field) [
					TYPE_BLOCK [
						word: as red-word! block/rs-head field
						len: block/rs-length? field
						if zero? len [return 0]
					]
					TYPE_WORD [
						word: as red-word! field
						len: 1
					]
					default [return 0]
				]
				flags: 0
				
				loop len [
					sym: symbol/resolve word/symbol
					case [
						sym = all-over	 [flags: flags or FACET_FLAGS_ALL_OVER]
						sym = focusable	 [flags: flags or FACET_FLAGS_FOCUSABLE]
						sym = resize	 [flags: flags or FACET_FLAGS_RESIZE]
						sym = no-title	 [flags: flags or FACET_FLAGS_NO_TITLE]
						sym = no-border  [flags: flags or FACET_FLAGS_NO_BORDER]
						sym = no-min	 [flags: flags or FACET_FLAGS_NO_MIN]
						sym = no-max	 [flags: flags or FACET_FLAGS_NO_MAX]
						sym = no-buttons [flags: flags or FACET_FLAGS_NO_BTNS]
						sym = modal		 [flags: flags or FACET_FLAGS_MODAL]
						sym = popup		 [flags: flags or FACET_FLAGS_POPUP]
						sym = tri-state  [flags: flags or FACET_FLAGS_TRISTATE]
						sym = scrollable [flags: flags or FACET_FLAGS_SCROLLABLE]
						sym = password	 [flags: flags or FACET_FLAGS_PASSWORD]
						sym = no-sync	 [flags: flags or FACET_FLAGS_NO_SYNC]
						sym = fullscreen [flags: flags or FACET_FLAGS_FULLSCREEN]
						true			 [fire [TO_ERROR(script invalid-arg) word]]
					]
					word: word + 1
				]
				flags
			]
			
			reattach-window-face: func [
				hMonitor [handle!]
				window	 [red-object!]
				parent	 [red-object!]
				/local
					blk		 [red-block!]
					screen 	 [red-object!]
					face end [red-object!]
					h		 [red-handle!]
					s s2	 [series!]
					hidden?	 [logic!]
			][
				assert TYPE_OF(parent) = TYPE_OBJECT
				blk: as red-block! #get system/view/screens
				s: GET_BUFFER(blk)
				face: as red-object! s/offset
				end:  as red-object! s/tail

				while [face < end][
					blk: as red-block! (object/get-values face) + FACE_OBJ_STATE
					assert TYPE_OF(blk) = TYPE_BLOCK
					s2: GET_BUFFER(blk)
					h: as red-handle! s2/offset
					if all [
						h/value = as-integer hMonitor
						TYPE_OF(h) = TYPE_HANDLE
						h/type = handle/CLASS_MONITOR
					][
						if parent/ctx <> face/ctx [					;-- if window really moved to a different display
							blk: as red-block! (object/get-values parent) + FACE_OBJ_PANE
							assert TYPE_OF(blk) = TYPE_BLOCK
							hidden?: block/rs-take blk as red-value! window yes  ;-- remove window from old screen/pane

							blk: as red-block! (object/get-values face) + FACE_OBJ_PANE
							either hidden? [
								block/insert-value blk as red-value! window yes	yes ;-- insert window to new screen/pane at head
							][
								block/rs-append blk as red-value! window	;-- append window to new screen/pane
							]
							copy-cell as red-value! face (object/get-values window) + FACE_OBJ_PARENT	;-- window/parent: screen
						]
						exit
					]
					face: face + 1
				]
				assert false
			]

			#include %keycodes.reds
			#switch GUI-engine [
				native [
					;#include %android/gui.reds
					#switch OS [
						Windows  [#include %windows/gui.reds]
						macOS    [#include %macOS/gui.reds]
						; GTK backend (is it in conflict with %GTK/gui.reds)
						Linux	 [#include %gtk3/gui.reds]
						#default []
					]
				]
				test 	 [#include %test/gui.reds]
				GTK 	 [#include %gtk3/gui.reds]
				terminal [#include %terminal/gui.reds]
			]
		]
	]

	mouse-event?: #either config/GUI-engine = 'terminal [no][yes]

	make-null-handle: routine [][handle/box 0 handle/CLASS_NULL]

	fetch-all-screens: routine [][
		#either GUI-engine = 'terminal [
			SET_RETURN(none-value)
		][
			SET_RETURN(gui/OS-fetch-all-screens)
		]
	]

	#either config/GUI-engine = 'terminal [
		get-current-screen: func [][system/view/screens/1/state/1]
	][	
		get-current-screen: routine [][
			SET_RETURN(gui/OS-get-current-screen)
		]
	]
	
	refresh-screens: has [svs spec screen][
		svs: system/view/screens
		foreach spec fetch-all-screens [
			either svs/1 [
				screen: svs/1
				screen/offset: spec/1
				screen/size:   to-pair spec/2 / spec/3
				screen/data:   spec/3
				screen/state/1: spec/4
				
			][
				append svs make face! [
					type:	'screen
					offset: spec/1
					size:	to-pair spec/2 / spec/3
					data:	spec/3
					pane:	make block! 4
					state:	reduce [spec/4 0 none copy [1]]
				]
			]
			svs: next svs
		]
		unless empty? svs [								;-- clean up screens for removed displays
			foreach screen svs [clear screen/pane]
			clear svs
		]
	]
	
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
			pt	   [red-point2D!]
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

		pt: point2D/push F32_0 F32_0
		gui/get-text-size face text pt
		stack/set-last as red-value! pt
	]
	
	on-change-facet: routine [
		owner  [object!]
		word   [any-word!]
		value  [any-type!]
		action [word!]
		new	   [any-type!]
		index  [integer!]
		part   [integer!]
	][
		if TYPE_OF(new) = TYPE_NONE [new: null]
		gui/OS-update-facet owner word value action new index part
	]
	
	update-text: routine [face [object!]][
		#if OS = 'Windows [gui/get-text-alt face -1]
		SET_RETURN(none-value)
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
	
	detach-image: routine [img [image!]][
		ownership/unbind as red-value! img
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
		handle/box gui/OS-make-view face parent/value handle/CLASS_WINDOW
	]

	draw-image: routine [image [image!] cmds [block!]][
		if any [zero? IMAGE_WIDTH(image/size) zero? IMAGE_HEIGHT(image/size)][exit]
		gui/OS-do-draw image cmds
		ownership/check as red-value! image words/_poke as red-value! image -1 -1
	]

	draw-face: routine [face [object!] cmds [block!] /local h [handle!] flags [integer!]][
		flags: gui/get-flags as red-block! (object/get-values face) + gui/FACE_OBJ_FLAGS
		h: gui/face-handle? face
		if h <> null [gui/OS-draw-face h cmds flags]
	]

	do-event-loop: routine [no-wait? [logic!] /local bool [red-logic!]][
		bool: as red-logic! stack/arguments
		bool/value:  gui/do-events no-wait?
		bool/header: TYPE_LOGIC
	]

	exit-event-loop: routine [][
		#switch GUI-engine [
			native [
				#switch OS [
					Windows  [gui/PostQuitMessage 0]
					macOS    [gui/post-quit-msg]
					Linux    [gui/post-quit-msg]
					#default [0]
				]
			]
			test 	 []
			GTK 	 []
			terminal [gui/post-quit-msg]
		]
	]

	request-font: routine [font [object!] selected [any-type!] mono? [logic!]][
		gui/OS-request-font font as red-object! selected mono?
	]

	request-file: routine [
		title	[any-type!]
		name	[any-type!]
		filter	[any-type!]
		save?	[logic!]
		multi?	[logic!]
	][
		stack/set-last gui/OS-request-file
			as red-string! title
			as red-file! name
			as red-block! filter
			save?
			multi?
	]

	request-dir: routine [
		title	[any-type!]
		dir		[any-type!]
		filter	[any-type!]
		keep?	[logic!]
		multi?	[logic!]
	][
		stack/set-last gui/OS-request-dir
			as red-string! title
			as red-file! dir
			as red-block! filter
			keep?
			multi?
	]

	text-box-metrics: routine [
		box		[object!]
		arg0	[any-type!]
		type	[integer!]
		/local
			state	[red-block!]
			bool	[red-logic!]
			values	[red-value!]
			txt		[red-string!]
			word	[red-word!]
			sym		[integer!]
			layout? [logic!]
	][
		layout?: yes
		values: object/get-values box
		word: as red-word! values + gui/FACE_OBJ_TYPE
		sym: symbol/resolve word/symbol
		if sym <> gui/rich-text [
			fire [TO_ERROR(script face-type) word]
		]

		txt: as red-string! values + gui/FACE_OBJ_TEXT
		if TYPE_OF(txt) <> TYPE_STRING [
			stack/set-last none-value
			exit
		]
		#either GUI-engine = 'terminal [
			stack/set-last gui/OS-text-box-metrics box arg0 type
		][
			state: as red-block! values + gui/FACE_OBJ_EXT3
			if TYPE_OF(state) = TYPE_BLOCK [
				bool: as red-logic! (block/rs-tail state) - 1
				layout?: bool/value
			]
			if layout? [gui/OS-text-box-layout box null 0 no]
			stack/set-last gui/OS-text-box-metrics state arg0 type
		]
	]

	update-scroller: routine [scroller [object!] flags [integer!]][
		gui/update-scroller scroller flags
		SET_RETURN(none-value)
	]

	set-dark-mode: routine [face [object!] dark? [logic!] /local word [red-word!]][
		word: as red-word! (object/get-values face) + gui/FACE_OBJ_TYPE
		gui/set-dark-mode gui/get-face-handle face dark? gui/window = symbol/resolve word/symbol
	]

	support-dark-mode?: routine [return: [logic!]][
		gui/support-dark-mode?
	]

	init: func [/local svs colors fonts][
		system/view/screens: svs: make block! 6

		#system [gui/init]

		extend system/view/metrics/margins [
			#switch config/GUI-engine [
				native [#switch config/OS [
					Windows [
						button:			[1x1   1x1]				;-- LeftxRight TopxBottom
						toggle:			[1x1   1x1]
						tab-panel:		[0x2   0x1]
						group-box:		[0x0   0x1]
						calendar:		[1x0   0x0]
					]
					macOS [
						button:			[2x2   2x3 regular 6x6 4x7 small 5x5 4x6 mini 1x1 0x1]
						toggle:			[2x2   2x3 regular 6x6 4x7 small 5x5 4x6 mini 1x1 0x1]
						regular:		[6x6   4x7]
						small:			[5x5   4x6]
						mini:			[1x1   0x1]
						group-box:		[3x3   0x4]
						tab-panel:		[7x7  6x10]
						drop-down:		[0x3   2x3 regular 0x3 2x3 small 0x3 1x3 mini 0x2 1x3]
						drop-list:		[0x3   2x3 regular 0x3 2x3 small 0x3 1x3 mini 0x2 1x3]
					]
				]]
			]
		]
		extend system/view/metrics/paddings [
			#switch config/GUI-engine [
				native [#switch config/OS [
					Windows [
						check:			[16x0  0x0]				;-- 13 + 3 for text padding
						radio:			[16x0  0x0]				;-- 13 + 3 for text padding
						field:			[0x8   0x0]
						group-box:		[3x3  10x3]
						tab-panel:		[1x3  25x0]
						button:			[8x8   0x0]
						toggle:			[8x8   0x0]
						drop-down:		[0x7   0x0]
						drop-list:		[0x7   0x0]
						calendar:		[21x0 1x0]
					]
					macOS [
						button:			[11x11 0x0 regular 14x14 0x0 small 11x11 0x0 mini 11x11 0x0]
						toggle:			[11x11 0x0 regular 14x14 0x0 small 11x11 0x0 mini 11x11 0x0]
						check:			[20x0  3x1]
						radio:			[20x0  1x1]
						text:			[3x3   0x0]
						field:			[3x3   0x0]
						group-box:		[0x8  4x18]
						drop-list:		[14x26 0x0 regular 14x26 0x0 small 11x22 0x0 mini 11x22 0x0]
					]
					Linux [
						button:			[17x17 3x3]
						toggle:			[17x17 3x3]
						check:			[20x8  2x2]
						radio:			[20x8  2x2]
						text:			[3x3   0x0]
						field:			[9x9   1x1]
						group-box:		[0x8  4x18]
						tab-panel:		[0x0  39x0]
						drop-list:		[0x40 0x0]
						drop-down:		[0x54 0x0]
					]
				]]
				terminal [
					check:			[2x0  0x0]
					radio:			[2x0  0x0]
				]
			]
		]
		extend system/view/metrics/fixed-heights [
			#switch config/GUI-engine [
				native [#switch config/OS [
					macOS	[
						progress:	21
					]
					Linux [
						progress:	4
					]
				]]
			]
		]
		#switch config/GUI-engine [
			native [#switch config/OS [
				Windows [
					if version/1 <= 6 [						;-- for Win7 & XP
						extend system/view/metrics/def-heights [
							button:		23
							toggle:		23
							text:		24
							field:		24
							check:		24
							radio:		24
							slider:		24
							drop-down:	23
							drop-list:	23
						]
					]
				]
				macOS	[
					extend system/view/metrics/def-heights [
						check:		21
						radio:		21
						text:		18
						field:		21
						drop-down:	21
						drop-list:	21
						progress:	21
					]
				]
	 			Linux	[
					 extend system/view/metrics/def-heights [
						button:		29
						toggle:		29
						check:		20
						radio:		19
						text:		17
						field:		30
						drop-down:	34
						drop-list:	34
						progress:	4
						slider:		34
					]
				]
			]]
		]
		
		colors: system/view/metrics/colors
		#switch config/OS [
			Windows [
				colors/tab-panel: white
				;colors/window							;-- set in gui/init from OS metrics
				;colors/panel							;-- set in gui/init from OS metrics
			]
			macOS [
			
			]
			Linux [
			]
		]

		#either config/GUI-engine = 'terminal [
			append svs make face! [						;-- default screen
				type:	'screen
				offset: 0x0
				size:	get-screen-size 0
				pane:	make block! 4
				state:	reduce [make-null-handle 0 none copy [1]]
			]
		][
			refresh-screens
		]
		
		set fonts:
			bind [fixed sans-serif serif] system/view/fonts
			switch system/platform [
				;-- references:
				;-- https://fontsarena.com/blog/operating-systems-default-serif-fonts/
				;-- https://fontsarena.com/blog/operating-systems-default-sans-serif-fonts/
				;-- https://www.granneman.com/webdev/coding/css/fonts-and-formatting/default-fonts
				Windows [
					case [
						version >= 6.0.0 [["Consolas" "Segoe UI" "Times New Roman"]]
						'xp              [["Courier New" "Tahoma" "Times New Roman"]]
					]
				]
				macOS [
					case [
						version >= 10.11.0 [["SF Mono" "San Francisco" "Times"]]
						version >= 10.10.0 [["Menlo" "Helvetica Neue" "Times"]]
						'older             [["Menlo" "Lucida Grande" "Times"]]
					]
				]
				;-- use "Monospace" on Linux, we let the system use the default one
				Linux [["Monospace" "DejaVu Sans" "Times New Roman"]]
				Android [["Roboto Mono" "Roboto" "Noto Serif"]]
			]
		
		set [font-fixed font-sans-serif font-serif] reduce fonts
	]
	
	version: none
	build:	 none
	product: none
	
	init
]
