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

#enum event-action! [
	EVT_NO_DISPATCH										;-- no further msg processing allowed
	EVT_DISPATCH										;-- allow DispatchMessage call only
]

gui-evt: declare red-event!								;-- low-level event value slot
gui-evt/header: TYPE_EVENT

modal-loop-type: 0										;-- remanence of last EVT_MOVE or EVT_SIZE
zoom-distance:	 0
special-key: 	-1										;-- <> -1 if a non-displayable key is pressed

flags-blk: declare red-block!							;-- static block value for event/flags
flags-blk/header:	TYPE_BLOCK
flags-blk/head:		0
flags-blk/node:		alloc-cells 4

make-at: func [
	widget	[handle!]
	face	[red-object!]
	return: [red-object!]
	/local
		f	[red-value!]
][
	f: as red-value! g_object_get_qdata widget red-face-id
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
	none-value
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		widget	[handle!]
		sz 		[red-pair!]
		offset	[red-pair!]
		value	[integer!]
][
	case [
		any [
			evt/type <= EVT_OVER
			evt/type = EVT_MOVING
			evt/type = EVT_MOVE
		][
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			offset/x: motion/x_new
			offset/y: motion/y_new
			;;print ["event-offset: " offset/x "x" offset/y lf]
			as red-value! offset
		]
		any [
			evt/type = EVT_SIZING
			evt/type = EVT_SIZE
		][
			widget: as handle! evt/msg
			;;print ["event-offset type: " get-symbol-name get-widget-symbol widget lf]
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			; sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE
			; offset/x: sz/x
			; offset/y: sz/y
			
			offset/x: gtk_widget_get_allocated_width widget
			offset/y: gtk_widget_get_allocated_height widget

			;;print ["event-offset: " offset/x "x" offset/y lf]
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
		true [as red-value! none-value]
	]
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		char 		[red-char!]
		code 		[integer!]
		res	 		[red-value!]
		special?	[logic!]
][
	as red-value! switch evt/type [
		EVT_KEY
		EVT_KEY_UP
		EVT_KEY_DOWN [
			res: null
			code: evt/flags
			special?: code and 80000000h <> 0
			code: code and FFFFh
			;debug: print ["code " code lf]
			if special? [
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
					RED_VK_LMENU	[_left-alt]
					RED_VK_RMENU	[_right-alt]
					RED_VK_LWIN		[_left-command]
					RED_VK_APPS		[_right-command]
					default			[null]
				]
			]
			either null? res [
				either all [special? evt/type = EVT_KEY][
					none-value
				][
					char: as red-char! stack/push*
					char/header: TYPE_CHAR
					char/value: code
					as red-value! char
				]
			][res]
		]
		default [as red-value! none-value]
	]
]

get-event-picked: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		res [red-value!]
		int	[red-integer!]
		pct [red-float!]
		zd	[float!]
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
	as red-value! logic/push flags and flag <> 0
]

decode-down-flags: func [
	wParam  [integer!]
	return: [integer!]
	/local
		flags [integer!]
][
	flags: 0
	if wParam and 0001h <> 0 [flags: flags or EVT_FLAG_DOWN]
	if wParam and 0002h <> 0 [flags: flags or EVT_FLAG_ALT_DOWN]
	if wParam and 0004h <> 0 [flags: flags or EVT_FLAG_SHIFT_DOWN]
	if wParam and 0008h <> 0 [flags: flags or EVT_FLAG_CTRL_DOWN]
	if wParam and 0010h <> 0 [flags: flags or EVT_FLAG_MID_DOWN]
	if wParam and 0020h <> 0 [flags: flags or EVT_FLAG_AUX_DOWN]
	if wParam and 0040h <> 0 [flags: flags or EVT_FLAG_AUX_DOWN]	;-- needs an AUX2 flag
	flags
]

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
][
	gui-evt/type:  evt
	gui-evt/msg:   as byte-ptr! msg
	gui-evt/flags: flags

	state: EVT_DISPATCH

	switch evt [
		EVT_OVER [0
		]
		EVT_KEY_DOWN [0
		]
		EVT_KEY_UP [0
		]
		EVT_KEY [0
		]
		EVT_SELECT [0
		]
		EVT_CHANGE [0
		]
		EVT_LEFT_DOWN
		EVT_LEFT_UP
		EVT_RIGHT_DOWN
		EVT_RIGHT_UP
		EVT_MIDDLE_DOWN
		EVT_MIDDLE_UP
		EVT_DBL_CLICK [0
		]
		EVT_CLICK [0
		]
		EVT_MENU [0]		;-- symbol ID of the menu
		default	 [0]
	]

	#call [system/view/awake gui-evt]

	res: as red-word! stack/arguments
	if TYPE_OF(res) = TYPE_WORD [
		sym: symbol/resolve res/symbol
		case [
			sym = done [state: EVT_DISPATCH]			;-- prevent other high-level events
			sym = stop [state: EVT_NO_DISPATCH]			;-- prevent all other events
			true 	   [0]								;-- ignore others
		]
	]
	state
]

do-events: func [
	no-wait? [logic!]
	return:  [logic!]
	/local
		msg? [logic!]
][
	msg?: no
	;@@ Improve it!!!
	;@@ as we cannot access gapplication->priv->use_count
	;@@ we use a global value to simulate it
	unless no-wait? [exit-loop: exit-loop + 1]

	while [exit-loop > 0][
		if g_main_context_iteration GTKApp-Ctx not no-wait? [msg?: yes]
		if no-wait? [break]
	]
	
	while [g_main_context_iteration GTKApp-Ctx false][	;-- consume leftover event
		msg?: yes
		if no-wait? [break]
	]
	
	;g_settings_sync
	;g_main_context_release GTKApp-Ctx			;@@ release it?
	;g_object_unref GTKApp
	msg?
]

check-extra-keys: func [
	state	[integer!]
	return: [integer!]
	/local
		key		[integer!]
][
	key: 0
	if state and GDK_SHIFT_MASK <> 0 [key: EVT_FLAG_SHIFT_DOWN]
	if state and GDK_CONTROL_MASK <> 0 [key: key or EVT_FLAG_CTRL_DOWN]
	if any [state and GDK_MOD1_MASK <> 0  state and GDK_MOD5_MASK <> 0][key: key or EVT_FLAG_MENU_DOWN]
	key
]

translate-key: func [
	keycode [integer!]
	return: [integer!]
	/local
		key 		[integer!]
		special?	[logic!]
][
	;debug: print ["keycode: " keycode]
	keycode: gdk_keyval_to_upper keycode
	;debug: print [" keycode2: " keycode]
	special?: no
	key: case [
		all[keycode >= 30h keycode <= 5Ah][keycode]; RED_VK_0 to RED_VK_Z
		all[keycode >= FFBEh keycode <= FFC8h][special?: yes keycode + RED_VK_F1 - FFBEh];RED_VK_F1 to RED_VK_F11
		keycode = FFBFh [special?: yes RED_VK_F12]
		keycode = FF0Dh	[special?: yes RED_VK_RETURN]
		;@@ To complete!
		true [RED_VK_UNKNOWN]
	]
	if special? [key: key or 80000000h]
	;debug: print [" key: " key " F1" RED_VK_F1 lf]
	key
]