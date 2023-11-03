Red/System [
	Title:	"GTK3 events handling"
	Author: "Qingtian Xie, RCqls"
	File: 	%events.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;; In the GTK world, gboolean is a gint and the dispatching is as follows:
#enum event-action! [
	EVT_DISPATCH: 0										;-- allow DispatchMessage call only
	EVT_NO_DISPATCH 									;-- no further msg processing allowed
]

#define GDK_BUTTON_PRIMARY 1
#define GDK_BUTTON_MIDDLE 2
#define GDK_BUTTON_SECONDARY 3

#define SET_PAIR_SIZE_FLAG(hwnd size) [
	either PAIR_TYPE?(size) [
		SET-PAIR-SIZE(hwnd hwnd)
	][
		SET-PAIR-SIZE(hwnd null)
	]
]

gui-evt: declare red-event!								;-- low-level event value slot
gui-evt/header: TYPE_EVENT

modal-loop-type:	0									;-- remanence of last EVT_MOVE or EVT_SIZE
zoom-distance:	 	0
special-key: 		-1									;-- <> -1 if a non-displayable key is pressed

flags-blk: declare red-block!							;-- static block value for event/flags
flags-blk/header:	TYPE_BLOCK
flags-blk/head:		0
flags-blk/node:		alloc-cells 4

; used to save old position of pointer in widget-motion-notify-event handler
evt-motion: context [
	pressed:	no
	x_root:		0.0
	y_root:		0.0
	x_new:	 	0
	y_new:		0
]

char-keys: [
	1000C400h C0FF0080h E0FFFF7Fh 0000F7FFh 00000000h 3F000000h 1F000080h 00FC7F38h
]

keycode-special: [
	;-- FF00h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_BACK			;-- FF08h
	RED_VK_TAB			;-- FF09h
	RED_VK_BACKTAB		;-- FF0Ah
	RED_VK_CLEAR		;-- FF0Bh
	RED_VK_UNKNOWN
	RED_VK_RETURN		;-- FF0Dh
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	;-- FF10h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_PAUSE		;-- FF13h
	RED_VK_SCROLL		;-- FF14h
	RED_VK_UNKNOWN		;-- GDK_KEY_Sys_Req
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_ESCAPE		;-- FF1Bh
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	;-- FF20h
	RED_VK_UNKNOWN		;-- GDK_KEY_Multi_key
	RED_VK_KANJI		;-- FF21h
	RED_VK_UNKNOWN		;-- GDK_KEY_Muhenkan
	RED_VK_UNKNOWN		;-- GDK_KEY_Henkan_Mode
	RED_VK_UNKNOWN		;-- GDK_KEY_Romaji
	RED_VK_UNKNOWN		;-- GDK_KEY_Hiragana
	RED_VK_UNKNOWN		;-- GDK_KEY_Katakana
	RED_VK_UNKNOWN		;-- GDK_KEY_Hiragana_Katakana
	RED_VK_UNKNOWN		;-- GDK_KEY_Zenkaku
	RED_VK_UNKNOWN		;-- GDK_KEY_Hankaku
	RED_VK_UNKNOWN		;-- GDK_KEY_Zenkaku_Hankaku
	RED_VK_UNKNOWN		;-- GDK_KEY_Touroku
	RED_VK_UNKNOWN		;-- GDK_KEY_Massyo
	RED_VK_UNKNOWN		;-- GDK_KEY_Kana_Lock
	RED_VK_UNKNOWN		;-- GDK_KEY_Kana_Shift
	RED_VK_UNKNOWN		;-- GDK_KEY_Eisu_Shift
	;-- FF30h
	RED_VK_UNKNOWN		;-- GDK_KEY_Eisu_toggle
	RED_VK_HANGUL		;-- GDK_KEY_Hangul
	RED_VK_UNKNOWN		;-- GDK_KEY_Hangul (FF31h ~ FF3Fh)
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	;-- FF40h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	;-- FF50h
	RED_VK_HOME			;-- FF50h
	RED_VK_LEFT			;-- FF51h
	RED_VK_UP			;-- FF52h
	RED_VK_RIGHT		;-- FF53h
	RED_VK_DOWN			;-- FF54h
	RED_VK_PRIOR		;-- FF55h
	RED_VK_NEXT			;-- FF56h
	RED_VK_END			;-- FF57h
	RED_VK_UNKNOWN		;-- GDK_KEY_Begin
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	;-- FF60h
	RED_VK_SELECT		;-- FF60h
	RED_VK_PRINT		;-- FF61h
	RED_VK_EXECUTE		;-- FF62h
	RED_VK_INSERT		;-- FF63h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN		;-- GDK_KEY_Undo
	RED_VK_UNKNOWN		;-- GDK_KEY_Redo
	RED_VK_MENU			;-- FF67h
	RED_VK_UNKNOWN		;-- GDK_KEY_Find
	RED_VK_UNKNOWN		;-- GDK_KEY_Cancel
	RED_VK_HELP			;-- FF6Ah
	RED_VK_UNKNOWN		;-- GDK_KEY_Break
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	;-- FF70h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_MODECHANGE	;-- FF7Eh (GDK_KEY_Mode_switch)
	RED_VK_NUMLOCK		;-- FF7Fh
	;-- FF80h
	RED_VK_SPACE		;-- FF80h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_TAB			;-- FF89h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_RETURN		;-- FF8Dh
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	;-- FF90h
	RED_VK_UNKNOWN
	RED_VK_F1			;-- FF91h
	RED_VK_F2			;-- FF92h
	RED_VK_F3			;-- FF93h
	RED_VK_F4			;-- FF94h
	RED_VK_HOME			;-- FF95h
	RED_VK_LEFT			;-- FF96h
	RED_VK_UP			;-- FF97h
	RED_VK_RIGHT		;-- FF98h
	RED_VK_DOWN			;-- FF99h
	RED_VK_PRIOR		;-- FF9Ah
	RED_VK_NEXT			;-- FF9Bh
	RED_VK_END			;-- FF9Ch
	RED_VK_CLEAR		;-- GDK_KEY_KP_Begin
	RED_VK_INSERT		;-- FF9Eh
	RED_VK_DELETE		;-- FF9Fh
	;-- FFA0h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_MULTIPLY		;-- FFAAh
	RED_VK_ADD			;-- FFABh
	RED_VK_SEPARATOR	;-- FFACh
	RED_VK_SUBTRACT		;-- FFADh
	RED_VK_DECIMAL		;-- FFAEh
	RED_VK_DIVIDE		;-- FFAFh
	;-- FFB0h
	RED_VK_NUMPAD0		;-- FFB0h
	RED_VK_NUMPAD1		;-- FFB1h
	RED_VK_NUMPAD2		;-- FFB2h
	RED_VK_NUMPAD3		;-- FFB3h
	RED_VK_NUMPAD4		;-- FFB4h
	RED_VK_NUMPAD5		;-- FFB5h
	RED_VK_NUMPAD6		;-- FFB6h
	RED_VK_NUMPAD7		;-- FFB7h
	RED_VK_NUMPAD8		;-- FFB8h
	RED_VK_NUMPAD9		;-- FFB9h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN		;-- GDK_KEY_KP_Equal
	RED_VK_F1			;-- FFBEh
	RED_VK_F2			;-- FFBFh
	;-- FFC0h
	RED_VK_F3			;-- FFC0h
	RED_VK_F4			;-- FFC1h
	RED_VK_F5			;-- FFC2h
	RED_VK_F6			;-- FFC3h
	RED_VK_F7			;-- FFC4h
	RED_VK_F8			;-- FFC5h
	RED_VK_F9			;-- FFC6h
	RED_VK_F10			;-- FFC7h
	RED_VK_F11			;-- FFC8h
	RED_VK_F12			;-- FFC9h
	RED_VK_F13			;-- FFCAh
	RED_VK_F14			;-- FFCBh
	RED_VK_F15			;-- FFCCh
	RED_VK_F16			;-- FFCDh
	RED_VK_F17			;-- FFCEh
	RED_VK_F18			;-- FFCFh
	;-- FFD0h
	RED_VK_F19			;-- FFD0h
	RED_VK_F20			;-- FFD1h
	RED_VK_F21			;-- FFD2h
	RED_VK_F22			;-- FFD3h
	RED_VK_F23			;-- FFD4h
	RED_VK_F24			;-- FFD5h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	;-- FFE0h
	RED_VK_UNKNOWN		;-- GDK_KEY_F35
	RED_VK_LSHIFT		;-- FFE1h
	RED_VK_RSHIFT		;-- FFE2h
	RED_VK_LCONTROL		;-- FFE3h
	RED_VK_RCONTROL		;-- FFE4h
	RED_VK_CAPITAL		;-- FFE5h
	RED_VK_SHIFT		;-- FFE6h
	RED_VK_LWIN			;-- FFE7h
	RED_VK_RWIN			;-- FFE8h
	RED_VK_LMENU		;-- FFE9h
	RED_VK_RMENU		;-- FFEAh
	RED_VK_UNKNOWN		;-- GDK_KEY_Super_L
	RED_VK_UNKNOWN		;-- GDK_KEY_Super_R
	RED_VK_UNKNOWN		;-- GDK_KEY_Hyper_L
	RED_VK_UNKNOWN		;-- GDK_KEY_Hyper_R
	RED_VK_UNKNOWN		;-- FFEFh
	;-- FFF0h
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_UNKNOWN
	RED_VK_DELETE		;-- FFFFh
]

keycode-ascii: [
	;-- 20h
	RED_VK_SPACE		;-- 20h
	RED_VK_UNKNOWN		;-- GDK_KEY_exclam
	RED_VK_OEM_7		;-- 22h (GDK_KEY_quotedbl)
	RED_VK_OEM_MINUS	;-- 23h (GDK_KEY_numbersign)
	RED_VK_UNKNOWN		;-- GDK_KEY_dollar
	RED_VK_UNKNOWN		;-- GDK_KEY_percent
	RED_VK_UNKNOWN		;-- GDK_KEY_ampersand
	RED_VK_UNKNOWN		;-- GDK_KEY_apostrophe
	;RED_VK_UNKNOWN		;-- GDK_KEY_quoteright
	RED_VK_UNKNOWN		;-- GDK_KEY_parenleft
	RED_VK_UNKNOWN		;-- GDK_KEY_parenright
	RED_VK_UNKNOWN		;-- GDK_KEY_asterisk
	RED_VK_OEM_PLUS		;-- 2Bh
	RED_VK_OEM_COMMA	;-- 2Ch
	RED_VK_OEM_MINUS	;-- 2Dh
	RED_VK_OEM_PERIOD	;-- 2Eh
	RED_VK_OEM_2		;-- 2Fh (GDK_KEY_slash)
	;-- 30h
	RED_VK_0			;-- 30h
	RED_VK_1			;-- 31h
	RED_VK_2			;-- 32h
	RED_VK_3			;-- 33h
	RED_VK_4			;-- 34h
	RED_VK_5			;-- 35h
	RED_VK_6			;-- 36h
	RED_VK_7			;-- 37h
	RED_VK_8			;-- 38h
	RED_VK_9			;-- 39h
	RED_VK_OEM_1		;-- 3Ah (GDK_KEY_colon)
	RED_VK_OEM_1		;-- 3Bh (GDK_KEY_semicolon)
	RED_VK_UNKNOWN		;-- GDK_KEY_less
	RED_VK_UNKNOWN		;-- GDK_KEY_equal
	RED_VK_UNKNOWN		;-- GDK_KEY_greater
	RED_VK_UNKNOWN		;-- GDK_KEY_question
	;-- 40h
	RED_VK_UNKNOWN		;-- GDK_KEY_at
	RED_VK_A			;-- 41h
	RED_VK_B			;-- 42h
	RED_VK_C			;-- 43h
	RED_VK_D			;-- 44h
	RED_VK_E			;-- 45h
	RED_VK_F			;-- 46h
	RED_VK_G			;-- 47h
	RED_VK_H			;-- 48h
	RED_VK_I			;-- 49h
	RED_VK_J			;-- 4Ah
	RED_VK_K			;-- 4Bh
	RED_VK_L			;-- 4Ch
	RED_VK_M			;-- 4Dh
	RED_VK_N			;-- 4Eh
	RED_VK_O			;-- 4Fh
	;-- 50h
	RED_VK_P			;-- 50h
	RED_VK_Q			;-- 51h
	RED_VK_R			;-- 52h
	RED_VK_S			;-- 53h
	RED_VK_T			;-- 54h
	RED_VK_U			;-- 55h
	RED_VK_V			;-- 56h
	RED_VK_W			;-- 57h
	RED_VK_X			;-- 58h
	RED_VK_Y			;-- 59h
	RED_VK_Z			;-- 5Ah
	RED_VK_UNKNOWN		;-- GDK_KEY_bracketleft
	RED_VK_UNKNOWN		;-- GDK_KEY_backslash
	RED_VK_UNKNOWN		;-- GDK_KEY_bracketright
	RED_VK_UNKNOWN		;-- GDK_KEY_asciicircum
	RED_VK_UNKNOWN		;-- GDK_KEY_underscore
	;-- 60h
	RED_VK_UNKNOWN		;-- GDK_KEY_quoteleft
	RED_VK_A			;-- 61h
	RED_VK_B			;-- 62h
	RED_VK_C			;-- 63h
	RED_VK_D			;-- 64h
	RED_VK_E			;-- 65h
	RED_VK_F			;-- 66h
	RED_VK_G			;-- 67h
	RED_VK_H			;-- 68h
	RED_VK_I			;-- 69h
	RED_VK_J			;-- 6Ah
	RED_VK_K			;-- 6Bh
	RED_VK_L			;-- 6Ch
	RED_VK_M			;-- 6Dh
	RED_VK_N			;-- 6Eh
	RED_VK_O			;-- 6Fh
	;-- 70h
	RED_VK_P			;-- 70h
	RED_VK_Q			;-- 71h
	RED_VK_R			;-- 72h
	RED_VK_S			;-- 73h
	RED_VK_T			;-- 74h
	RED_VK_U			;-- 75h
	RED_VK_V			;-- 76h
	RED_VK_W			;-- 77h
	RED_VK_X			;-- 78h
	RED_VK_Y			;-- 79h
	RED_VK_Z			;-- 7Ah
	RED_VK_UNKNOWN		;-- GDK_KEY_braceleft
	RED_VK_UNKNOWN		;-- GDK_KEY_bar
	RED_VK_UNKNOWN		;-- GDK_KEY_braceright
	RED_VK_UNKNOWN		;-- GDK_KEY_asciitilde
	RED_VK_UNKNOWN
	;-- 80h
]

special-key-to-flags: func [
	key		[integer!]
	return:	[integer!]
][
	case [
		key = RED_VK_LCONTROL [
			EVT_FLAG_CTRL_DOWN
		]
		key = RED_VK_RCONTROL [
			EVT_FLAG_CTRL_DOWN
		]
		key = RED_VK_LSHIFT [
			EVT_FLAG_SHIFT_DOWN
		]
		key = RED_VK_RSHIFT [
			EVT_FLAG_SHIFT_DOWN
		]
		key = RED_VK_LMENU [
			EVT_FLAG_MENU_DOWN
		]
		key = RED_VK_RMENU [
			EVT_FLAG_MENU_DOWN
		]
		true [0]
	]
]

make-at: func [
	widget	[handle!]
	face	[red-object!]
	return: [red-object!]
	/local
		f	[red-value!]
][
	f: as red-value! get-face-obj widget
	assert f <> null
	as red-object! copy-cell f as cell! face
]

push-face: func [
	handle  [handle!]
	return: [red-object!]
][
	make-at handle as red-object! stack/push*
]

get-event-face: func [
	evt		[red-event!]
	return: [red-value!]
][
	as red-value! push-face as handle! evt/msg
]

get-event-window: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		handle [handle!]
		face   [red-object!]
][
	;; DEBUG: print ["get-event-windows: " evt/type " " evt/msg lf]
	handle: gtk_widget_get_toplevel as handle! evt/msg
	as red-value! get-face-obj handle
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		widget	[handle!]
		sz 		[red-pair!]
		pt		[red-point2d!]
		offset	[red-pair!]
		value	[integer!]
		sx sy	[integer!]
][
	;; DEBUG: print ["get-event-offset: " evt/type lf]
	case [
		any [
			evt/type <= EVT_OVER
			evt/type = EVT_MOVING
			evt/type = EVT_MOVE
		][
			pt: as red-point2d! stack/push*
			pt/header: TYPE_POINT2D
			pt/x: as float32! evt-motion/x_new
			pt/y: as float32! evt-motion/y_new
			as red-value! pt
		]
		any [
			evt/type = EVT_SIZING
			evt/type = EVT_SIZE
		][
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR

			widget: as handle! evt/msg
			either null? GET-HMENU(widget) [
				sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE
				GET_PAIR_XY_INT(sz sx sy)
				offset/x: sx
				offset/y: sy
			][
				offset/x: GET-CONTAINER-W(widget)
				offset/y: GET-CONTAINER-H(widget)
			]
			if null? GET-PAIR-SIZE(widget) [
				as-point2D offset
			]
			as red-value! offset
		]
		any [
			evt/type = EVT_ZOOM
			evt/type = EVT_PAN
			evt/type = EVT_ROTATE
			evt/type = EVT_TWO_TAP
			evt/type = EVT_PRESS_TAP
		][

			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			as red-value! offset
		]
		evt/type = EVT_MENU [
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			offset/x: menu-x
			offset/y: menu-y
			as red-value! offset
		]
		true [as red-value! none-value]
	]
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		code		[integer!]
		char		[red-char!]
		res			[red-value!]
][
	as red-value! switch evt/type [
		EVT_KEY
		EVT_KEY_UP
		EVT_KEY_DOWN [
			res: null
			code: evt/flags
			code: code and FFFFh
			if all [evt/type = EVT_KEY unicode-cp >= 00010000h][code: unicode-cp]
			if special-key = -1 [
				res: as red-value! switch code [
					RED_VK_PRIOR	[_page-up]
					RED_VK_NEXT		[_page-down]
					RED_VK_END		[_end]
					RED_VK_HOME		[_home]
					RED_VK_LEFT		[_left]
					RED_VK_UP		[_up]
					RED_VK_RIGHT	[_right]
					RED_VK_DOWN		[_down]
					RED_VK_INSERT	[_insert]
					RED_VK_DELETE	[_delete]
					RED_VK_F1		[_F1]
					RED_VK_F2		[_F2]
					RED_VK_F3		[_F3]
					RED_VK_F4		[_F4]
					RED_VK_F5		[_F5]
					RED_VK_F6		[_F6]
					RED_VK_F7		[_F7]
					RED_VK_F8		[_F8]
					RED_VK_F9		[_F9]
					RED_VK_F10		[_F10]
					RED_VK_F11		[_F11]
					RED_VK_F12		[_F12]
					RED_VK_LSHIFT	[_left-shift]
					RED_VK_RSHIFT	[_right-shift]
					RED_VK_LCONTROL	[_left-control]
					RED_VK_RCONTROL	[_right-control]
					RED_VK_CAPITAL	[_caps-lock]
					RED_VK_NUMLOCK	[_num-lock]
					RED_VK_LMENU	[_left-alt]
					RED_VK_RMENU	[_right-alt]
					RED_VK_LWIN		[_left-command]
					RED_VK_APPS		[_right-command]
					RED_VK_SCROLL	[_scroll-lock]
					RED_VK_PAUSE	[_pause]
					default			[null]
				]
			]
			either null? res [
				either all [special-key = -1 evt/type = EVT_KEY][
					none-value
				][
					char: as red-char! stack/push*
					char/header: TYPE_CHAR
					char/value: code
					as red-value! char
				]
			][res]
		]
		EVT_SCROLL [
			code: evt/flags
			either code and 8 = 0 [
				switch code and 7 [
					2 [_track]
					1 [_page-up]
					3 [_page-down]
					4 [_up]
					5 [_down]
					default [_end]
				]
			][
				switch code and 7 [
					2 [_track]
					1 [_page-left]
					3 [_page-right]
					4 [_left]
					5 [_right]
					default [_end]
				]
			]
		]
		EVT_WHEEL [_wheel]
		default [as red-value! none-value]
	]
]

get-event-orientation: func [
	evt		[red-event!]
	return: [red-value!]
][
	if evt/type = EVT_SCROLL [
		either evt/flags and 8 = 0 [
			return as red-value! _vertical
		][
			return as red-value! _horizontal
		]
	]
	as red-value! none-value
]

get-event-picked: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		res		[red-value!]
		int		[red-integer!]
		event	[GdkEventScroll!]
		str		[c-string!]
		size	[integer!]
		delta	[float!]
][
	as red-value! switch evt/type [
		EVT_ZOOM
		EVT_PAN
		EVT_ROTATE
		EVT_TWO_TAP
		EVT_PRESS_TAP [
			either evt/type = EVT_ZOOM [
				res: as red-value! none/push
			][
				int: as red-integer! stack/push*
				int/header: TYPE_INTEGER
				int
			]
		]
		EVT_WHEEL [
			event: as GdkEventScroll! g_object_get_qdata as handle! evt/msg red-event-id
			delta: switch event/direction [
				GDK_SCROLL_UP [1.0]
				GDK_SCROLL_DOWN [-1.0]
				default [0.0 - event/delta_y]
			]
			float/push delta
		]
		EVT_IME [
			str: as c-string! evt/flags
			size: length? str
			string/load str size UTF-8
		]
		EVT_SCROLL [integer/push evt/flags >>> 4]
		EVT_MENU [word/push* evt/flags and FFFFh]
		default	 [integer/push evt/flags and FFFFh]
	]
]

get-event-flags: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		blk [red-block!]
][
	;; DEBUG: print ["get-event-flags " lf]
	blk: flags-blk
	block/rs-clear blk
	if evt/flags and EVT_FLAG_AWAY		 <> 0 [block/rs-append blk as red-value! _away]
	if evt/flags and EVT_FLAG_DOWN		 <> 0 [block/rs-append blk as red-value! _down]
	if evt/flags and EVT_FLAG_MID_DOWN	 <> 0 [block/rs-append blk as red-value! _mid-down]
	if evt/flags and EVT_FLAG_ALT_DOWN	 <> 0 [block/rs-append blk as red-value! _alt-down]
	if evt/flags and EVT_FLAG_AUX_DOWN	 <> 0 [block/rs-append blk as red-value! _aux-down]
	if evt/flags and EVT_FLAG_CTRL_DOWN	 <> 0 [block/rs-append blk as red-value! _control]
	if evt/flags and EVT_FLAG_SHIFT_DOWN <> 0 [block/rs-append blk as red-value! _shift]
	as red-value! blk
]

get-event-flag: func [
	flags	[integer!]
	flag	[integer!]
	return: [red-value!]
][
	;; DEBUG: print ["get-event-flag "  flags and flag <> 0 lf]
	as red-value! logic/push flags and flag <> 0
]

;; This function is only called in handlers.red
;; No
make-event: func [
	msg		[handle!]
	flags	[integer!]
	evt		[integer!]
	return: [integer!]
	/local
		res	   [red-word!]
		word   [red-word!]
		sym	   [integer!]
		state  [integer!]
		key	   [integer!]
		char   [integer!]
		type   [integer!]
][
	gui-evt/type:  evt
	gui-evt/msg:   as byte-ptr! msg
	gui-evt/flags: flags

	;; DEBUG: print ["make-event:  down? " flags and EVT_FLAG_DOWN <> 0 lf]

	state: EVT_DISPATCH

	switch evt [
		; EVT_OVER [0
		; ]
		; EVT_KEY_DOWN [0
		; ]
		; EVT_KEY_UP [0
		; ]
		EVT_KEY [
			key: flags and FFFFh
			if all [
				flags and EVT_FLAG_CTRL_DOWN <> 0
				97 <= key key <= 122
			][key: key - 96]
			gui-evt/flags: flags and FFFF0000h or key
		]
		; EVT_SELECT [0
		; ]
		; EVT_CHANGE [0
		; ]
		EVT_LEFT_DOWN [
			case [
				flags and EVT_FLAG_DBL_CLICK <> 0 [
					;; DEBUG: print ["Double click!!!!!" lf]
					gui-evt/type: EVT_DBL_CLICK
				]
				; flags and EVT_FLAG_CMD_DOWN <> 0 [
				; 	gui-evt/type: EVT_RIGHT_DOWN
				; ]
				; flags and EVT_FLAG_CTRL_DOWN <> 0 [
				; 	gui-evt/type: EVT_MIDDLE_DOWN
				; ]
				true [0]
			]
		]
		; EVT_LEFT_UP [
		; 	case [
		; 		flags and EVT_FLAG_CMD_DOWN <> 0 [
		; 			gui-evt/type: EVT_RIGHT_UP
		; 		]
		; 		flags and EVT_FLAG_CTRL_DOWN <> 0 [
		; 			gui-evt/type: EVT_MIDDLE_UP
		; 		]
		; 		true [0]
		; 	]
		; ]
		; EVT_CLICK [0
		; ]
		; EVT_MENU [0]		;-- symbol ID of the menu
		default	 [0]
	]

	stack/mark-try-all words/_anon
	res: as red-word! stack/arguments
	catch CATCH_ALL_EXCEPTIONS [
		#call [system/view/awake gui-evt]
		stack/unwind
	]
	stack/adjust-post-try
	if system/thrown <> 0 [system/thrown: 0]
	type: TYPE_OF(res)
	if ANY_WORD?(type) [
		sym: symbol/resolve res/symbol
		if any [sym = _continue sym = done][
			state: EVT_NO_DISPATCH
		]
	]
	state
]

do-events: func [
	no-wait?	[logic!]
	return:		[logic!]
	/local
		msg?	[logic!]
		list	[GList!]
		win		[handle!]
][
	win: find-last-window
	if null? win [return no]
	SET-IN-LOOP(win win)

	msg?: any [not no-wait? gtk_events_pending]
	until [
		gtk_main_iteration_do not no-wait?
		unless g_type_check_instance_is_a win gtk_window_get_type [
			break
		]
		if null? GET-IN-LOOP(win) [break]
		if force-redraw? [
			gdk_window_process_all_updates
			force-redraw?: no
		]
		no-wait?
	]
	msg?
]

post-quit-msg: func [
	/local
		win		[handle!]
][
	win: find-last-window
	SET-IN-LOOP(win null)
	gtk_widget_queue_draw win
]

char-key?: func [
	key			[byte!]									;-- virtual key code
	return:		[logic!]
	/local
		slot	[byte-ptr!]
][
	slot: (as byte-ptr! char-keys) + as-integer (key >>> 3)
	slot/value and (as-byte (80h >> as-integer (key and as-byte 7))) <> null-byte
]

check-extra-keys: func [
	state		[integer!]
	return:		[integer!]
	/local
		key		[integer!]
][
	key: 0
	if state and GDK_SHIFT_MASK <> 0 [key: EVT_FLAG_SHIFT_DOWN]
	if state and GDK_CONTROL_MASK <> 0 [key: key or EVT_FLAG_CTRL_DOWN]
	if any [state and GDK_MOD1_MASK <> 0  state and GDK_MOD5_MASK <> 0][key: key or EVT_FLAG_MENU_DOWN]
	key
]

check-extra-buttons: func [
	state		[integer!]
	return:		[integer!]
	/local
		buttons	[integer!]
][
	buttons: 0
	if state and GDK_BUTTON1_MASK  <> 0 [buttons: EVT_FLAG_DOWN]
	if state and GDK_BUTTON2_MASK  <> 0 [buttons: buttons or EVT_FLAG_DOWN]
	if state and GDK_BUTTON3_MASK  <> 0 [buttons: buttons or EVT_FLAG_DOWN]
	buttons
]

check-down-flags: func [
	state		[integer!]
	return:		[integer!]
	/local
		flags	[integer!]
][
	flags: 0
	if state and GDK_BUTTON1_MASK <> 0 [flags: flags or EVT_FLAG_DOWN]
	if state and GDK_META_MASK <> 0 [flags: flags or EVT_FLAG_ALT_DOWN]
	if state and GDK_SHIFT_MASK <> 0 [flags: flags or EVT_FLAG_SHIFT_DOWN]
	if state and GDK_CONTROL_MASK <> 0 [flags: flags or EVT_FLAG_CTRL_DOWN]
	if state and GDK_BUTTON2_MASK <> 0 [flags: flags or EVT_FLAG_MID_DOWN]
	if state and GDK_BUTTON3_MASK <> 0 [flags: flags or EVT_FLAG_AUX_DOWN]
	;;if state and 0040h <> 0 [flags: flags or EVT_FLAG_AUX_DOWN]	;-- needs an AUX2 flag
	flags
]

check-flags: func [
	type		[integer!]
	state		[integer!]
	return:		[integer!]
	/local
		flags	[integer!]
][
	flags: 0
	;;[flags: flags or EVT_FLAG_AX2_DOWN]
	if state and GDK_META_MASK <> 0 [flags: flags or EVT_FLAG_AUX_DOWN]
	if state and GDK_META_MASK <> 0 [flags: flags or EVT_FLAG_ALT_DOWN]
	if state and GDK_BUTTON2_MASK <> 0 [flags: flags or EVT_FLAG_MID_DOWN]
	if state and GDK_BUTTON1_MASK <> 0 [flags: flags or EVT_FLAG_DOWN]
	;;[flags: flags or EVT_FLAG_AWAY]
	if type = GDK_DOUBLE_BUTTON_PRESS [flags: flags or EVT_FLAG_DBL_CLICK]
	if state and GDK_CONTROL_MASK <> 0 [flags: flags or EVT_FLAG_CTRL_DOWN]
	if state and GDK_SHIFT_MASK <> 0 [flags: flags or EVT_FLAG_SHIFT_DOWN]
	if state and GDK_HYPER_MASK <> 0 [flags: flags or EVT_FLAG_MENU_DOWN]
	if state and GDK_SUPER_MASK <> 0 [flags: flags or EVT_FLAG_CMD_DOWN]
	flags
]

;; TODO: before finding better solution!!!!
;; container-type? is now only restricted to rich-text (cf gui.red)
;; since
;; 1) it is required in makedoc/easy-VID-rt.red
;; 2) it is too slow when used in ast.red for base widget (too much delegations).

connect-common-events: func [
	widget		[handle!]
	data		[int-ptr!]
][
	gtk_widget_add_events widget GDK_BUTTON_PRESS_MASK
	gobj_signal_connect(widget "button-press-event" :mouse-button-press-event data)
	
	gtk_widget_add_events widget GDK_BUTTON1_MOTION_MASK or GDK_POINTER_MOTION_MASK
	gobj_signal_connect(widget "motion-notify-event" :mouse-motion-notify-event data)


	gtk_widget_add_events widget GDK_BUTTON_RELEASE_MASK
	gobj_signal_connect(widget "button-release-event" :mouse-button-release-event data)

	gtk_widget_add_events widget GDK_KEY_PRESS_MASK
	gobj_signal_connect(widget "key-press-event" :key-press-event data)

	gtk_widget_add_events widget GDK_KEY_RELEASE_MASK
	gobj_signal_connect(widget "key-release-event" :key-release-event data)

	gtk_widget_add_events widget GDK_SCROLL_MASK
	gobj_signal_connect(widget "scroll-event" :widget-scroll-event data)
]

connect-focus-events: func [
	evbox		[handle!]
	widget		[handle!]
	sym			[integer!]
][
	if any [
		sym = rich-text
		sym = field
		sym = area
		sym = base	
	][
		gtk_widget_set_can_focus widget yes
		gtk_widget_set_focus_on_click widget yes
		gtk_widget_grab_focus widget
		gtk_widget_add_events widget GDK_FOCUS_CHANGE_MASK
		gobj_signal_connect(evbox "focus-in-event" :focus-in-event widget)
		gobj_signal_connect(evbox "focus-out-event" :focus-out-event widget)
	]
]

connect-notify-events: func [
	widget		[handle!]
	data		[int-ptr!]
][
	gtk_widget_add_events widget GDK_ENTER_NOTIFY_MASK or GDK_LEAVE_NOTIFY_MASK
	gobj_signal_connect(widget "enter-notify-event" :widget-enter-notify-event data)
	gobj_signal_connect(widget "leave-notify-event" :widget-leave-notify-event data)
]

connect-radio-toggled-events: func [
	face		[red-object!]
	last		[handle!]
	parent		[handle!]
	/local
		pface	[red-object!]
		pane	[red-block!]
		head	[red-object!]
		tail	[red-object!]
		handle	[handle!]
][
	gobj_signal_connect(last "toggled" :button-toggled last)
	pface: get-face-obj parent
	;if TYPE_OF(pface) <> TYPE_OBJECT [exit]
	pane: as red-block! (object/get-values pface) + FACE_OBJ_PANE
	head: as red-object! block/rs-head pane
	tail: as red-object! block/rs-tail pane
	while [head < tail][
		handle: face-handle? head
		unless null? handle [
			if radio = get-widget-symbol handle [
				gobj_signal_connect(handle "toggled" :button-toggled handle)
			]
		]
		head: head + 1
	]
]

connect-widget-events: func [
	widget		[handle!]
	values		[red-value!]
	sym			[integer!]
	/local
		evbox	[handle!]
		cont	[handle!]
		buffer	[handle!]
][
	evbox: get-face-evbox widget values sym
	cont: GET-CONTAINER(widget)
	;-- register red mouse, key event functions
	either sym = window [
		connect-notify-events cont widget
		connect-common-events cont widget
	][
		connect-notify-events evbox widget
		connect-common-events evbox widget
	]
	connect-focus-events evbox widget sym

	gobj_signal_connect(evbox "realize" :widget-realize widget)

	case [
		any [
			sym = check
			sym = toggle
		][
			gobj_signal_connect(widget "toggled" :button-toggled widget)
		]
		sym = radio [
			0
		]
		sym = button [
			gobj_signal_connect(widget "clicked" :button-clicked widget)
		]
		sym = base [
			gobj_signal_connect(widget "draw" :base-draw widget)
			;-- transparent widget need propagate events to sibling
			gobj_signal_connect(widget "event-after" :base-event-after widget)
		]
		sym = rich-text [
			gobj_signal_connect(widget "draw" :base-draw widget)
			gobj_signal_connect(widget "unrealize" :widget-unrealize widget)
		]
		sym = window [
			gobj_signal_connect(widget "delete-event" :window-delete-event widget)
			gobj_signal_connect(widget "size-allocate" :window-size-allocate widget)
			gtk_widget_add_events widget GDK_FOCUS_CHANGE_MASK
			gobj_signal_connect(widget "focus-in-event" :focus-in-event widget)
			gobj_signal_connect(widget "focus-out-event" :focus-out-event widget)
			gobj_signal_connect(widget "configure-event" :window-configure-event widget)
			evbox: GET-CONTAINER(widget)
			gobj_signal_connect(evbox "draw" :base-draw evbox)
		]
		sym = slider [
			gobj_signal_connect(widget "value-changed" :range-value-changed widget)
		]
		sym = text [
			connect-notify-events evbox widget
		]
		sym = field [
			gobj_signal_connect(widget "changed" :field-changed widget)
		]
		sym = progress [
			0
		]
		sym = camera [
			gobj_signal_connect(widget "draw" :camera-draw widget)
		]
		sym = calendar [
			gobj_signal_connect(widget "day-selected" :calendar-changed widget)
		]
		sym = area [
			buffer: gtk_text_view_get_buffer widget
			gobj_signal_connect(buffer "changed" :area-changed widget)
			g_object_set [widget "populate-all" yes null]
			gobj_signal_connect(widget "populate-popup" :area-populate-popup widget)
		]
		sym = group-box [
			0
		]
		sym = panel [
			gobj_signal_connect(widget "draw" :base-draw widget)
		]
		sym = tab-panel [
			gobj_signal_connect(widget "switch-page" :tab-panel-switch-page widget)
		]
		sym = text-list [
			;;; Mandatory and can respond to  (ON_SELECT or ON_CHANGE)
			gobj_signal_connect(widget "selected-rows-changed" :text-list-selected-rows-changed widget)
		]
		any [
			sym = drop-list
			sym = drop-down
		][
			;;; Mandatory! and can respond to (ON_SELECT or ON_CHANGE)
			gobj_signal_connect(widget "changed" :combo-selection-changed widget)
		]
		true [0]
	]
]