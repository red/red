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
				;FACE_OBJ_RATE
				FACE_OBJ_EDGE
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
				;FACET_FLAG_RATE:		
				FACET_FLAG_EDGE:		00010000h
				FACET_FLAG_FONT:		00020000h	;-- keep in sync with value in update-font-faces function
				FACET_FLAG_ACTOR:		00040000h
				FACET_FLAG_EXTRA:		00080000h
				FACET_FLAG_DRAW:		00100000h
			]
			
			#enum flags-flag! [
				FACET_FLAGS_ALL_OVER:	00000001h
				FACET_FLAGS_DRAGGABLE:	00000002h
			]
			
			#enum font-facet! [
				FONT_OBJ_NAME
				FONT_OBJ_SIZE
				FONT_OBJ_STYLE
				FONT_OBJ_ANGLE
				FONT_OBJ_COLOR
				FONT_OBJ_ANTI-ALIAS?
				FONT_OBJ_SHADOW
				FONT_OBJ_PARA
				FONT_OBJ_STATE
				FONT_OBJ_PARENT
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
				EVT_OVER								;-- last mouse event
				
				EVT_KEY
				EVT_KEY_DOWN
				EVT_KEY_UP
				
				EVT_SELECT
				EVT_CHANGE
				EVT_MENU
				EVT_CLOSE
			]
			
			#enum event-flag! [
				EVT_FLAG_AX2_DOWN:		00400000h
				EVT_FLAG_AUX_DOWN:		00800000h
				EVT_FLAG_ALT_DOWN:		01000000h
				EVT_FLAG_MID_DOWN:		02000000h
				EVT_FLAG_DOWN:			04000000h
				EVT_FLAG_AWAY:			08000000h
				EVT_FLAG_DBL_CLICK:		10000000h
				EVT_FLAG_CTRL_DOWN:		20000000h
				EVT_FLAG_SHIFT_DOWN:	40000000h
				EVT_FLAG_KEY_SPECIAL:	80000000h
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
				;rate:		symbol/make "rate"
				edge:		symbol/make "edge"
				actors:		symbol/make "actors"
				extra:		symbol/make "extra"
				draw:		symbol/make "draw"
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
			
			
			---:			symbol/make "---"
			done:			symbol/make "done"
			_continue:		symbol/make "continue"
			stop:			symbol/make "stop"
			popup:			symbol/make "popup"
			
			ClearType:		symbol/make "ClearType"
			_bold:			symbol/make "bold"
			_italic:		symbol/make "italic"
			_underline:		symbol/make "underline"
			_strike:		symbol/make "strike"
			
			all-over:		symbol/make "all-over"
			draggable:		symbol/make "draggable"
			
			_control:		word/load "control"
			_shift:			word/load "shift"
			_away:			word/load "away"
			_down:			word/load "down"
			_up:			word/load "up"
			_mid-down:		word/load "mid-down"
			_mid-up:		word/load "mid-up"
			_alt-down:		word/load "alt-down"
			_alt-up:		word/load "alt-up"
			_aux-down:		word/load "aux-down"
			_aux-up:		word/load "aux-up"
			_click:			word/load "click"
			_double-click:	word/load "double-click"
			_over:			word/load "over"
			_key:			word/load "key"
			;_key-down:		word/load "key-down"
			_key-up:		word/load "key-up"
			_select:		word/load "select"
			_change:		word/load "change"
			_menu:			word/load "menu"
			_close:			word/load "close"
			
			_page-up:		word/load "page-up"
			_page_down:		word/load "page-down"
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

			get-event-type: func [
				evt		[red-event!]
				return: [red-value!]
			][
				as red-value! switch evt/type [
					EVT_LEFT_DOWN	 [_down]
					EVT_LEFT_UP		 [_up]
					EVT_MIDDLE_DOWN	 [_mid-down]
					EVT_MIDDLE_UP	 [_mid-up]
					EVT_RIGHT_DOWN	 [_alt-down]
					EVT_RIGHT_UP	 [_alt-up]
					EVT_AUX_DOWN	 [_aux-down]
					EVT_AUX_UP		 [_aux-up]
					EVT_CLICK		 [_click]
					EVT_DBL_CLICK	 [_double-click]
					EVT_OVER		 [_over]
					EVT_KEY			 [_key]
					;EVT_KEY_DOWN	 [_key-down]
					EVT_KEY_UP		 [_key-up]
					EVT_SELECT	 	 [_select]
					EVT_CHANGE		 [_change]
					EVT_MENU		 [_menu]
					EVT_CLOSE		 [_close]
				]
			]

			;#include %android/gui.reds
			#include %windows/gui.reds
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
	
	on-change-facet: routine [
		owner  [object!]
		word   [word!]
		value  [any-type!]
		action [word!]
		index  [integer!]
		part   [integer!]
	][
		gui/OS-update-facet owner word value action index part
	]
	
	update-font: routine [font [object!] flag [integer!]][
		gui/update-font font flag
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
	
	show-window: routine [id [integer!]][
		gui/OS-show-window id
		SET_RETURN(none-value)
	]

	make-view: routine [face [object!] parent [integer!] return: [integer!]][
		gui/OS-make-view face parent
	]

	to-image: routine [face [object!]][
		stack/set-last as red-value! gui/OS-to-image face
	]

	draw-image: routine [image [image!] cmds [block!]][
		gui/OS-do-draw image cmds
	]

	do-event-loop: routine [no-wait? [logic!]][
		probe "do-event-loop"
		gui/do-events no-wait?
		probe "exited from event-loop"
	]
	
	init: has [svs][
		#system [gui/init]
		
		system/view/metrics/dpi: 94						;@@ Needs to be calculated
		system/view/screens: svs: make block! 6
		
		append svs make face! [							;-- default screen
			name:	none
			type:	'screen
			offset: 0x0
			size:	get-screen-size 0
			pane:	make block! 4
			state:	reduce [0 0 none none]
		]
	]
	
	version: none
	build:	 none
	product: none
]
