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

gui-evt: declare red-event!								;-- low-level event value slot
gui-evt/header: TYPE_EVENT

modal-loop-type: 	0										;-- remanence of last EVT_MOVE or EVT_SIZE
zoom-distance:	 	0
special-key: 		-1										;-- <> -1 if a non-displayable key is pressed

flags-blk: declare red-block!							;-- static block value for event/flags
flags-blk/header:	TYPE_BLOCK
flags-blk/head:		0
flags-blk/node:		alloc-cells 4

; used to save old position of pointer in widget-motion-notify-event handler
evt-motion: context [
	state:		no
	x_root:		0.0
	y_root:		0.0
	x_new:	 	0
	y_new:		0
	cpt:		0
	sensitiv:	3
]

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
	;; DEBUG: print ["get-event-windows: " evt/type " " evt/msg lf]
	handle: gtk_widget_get_toplevel as handle! evt/msg
	as red-value! g_object_get_qdata handle red-face-id
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
	;; DEBUG: print ["get-event-offset: " evt/type lf]
	case [
		any [
			evt/type <= EVT_OVER
			evt/type = EVT_MOVING
			evt/type = EVT_MOVE
		][
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			offset/x: evt-motion/x_new
			offset/y: evt-motion/y_new
			;; DEBUG: print ["event-offset: " offset/x "x" offset/y lf]
			as red-value! offset
		]
		any [
			evt/type = EVT_SIZING
			evt/type = EVT_SIZE
		][
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR

			widget: as handle! evt/msg
			sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE
			as red-value! sz
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
			;; DEBUG: print ["key-code=" code " flags=" evt/flags " special?=" special? " shift=" (evt/flags and EVT_FLAG_SHIFT_DOWN <> 0) lf]
			either special? [
				special-key: code
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
			][special-key: -1]
			if null? res [
				res: either all [special?  evt/type = EVT_KEY][
					as red-value! none-value
				][
					;; DEBUG: print ["key-code2=" code " flags=" evt/flags " special-key=" special-key " special?=" special? " shift=" (evt/flags and EVT_FLAG_SHIFT_DOWN <> 0) lf]
					char: as red-char! stack/push*
					char/header: TYPE_CHAR
					char/value: code
					as red-value! char
				]
			]
			res
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

get-event-picked: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		res		[red-value!]
		int		[red-integer!]
		event	[GdkEventScroll!]
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
			float/push 0.0 - event/delta_y
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
		; EVT_KEY [0
		; ]
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
	;; DEBUG: print ["make-event result:" res lf]
	type: TYPE_OF(res)
	if  ANY_WORD?(type) [
		sym: symbol/resolve res/symbol
		;; DEBUG: print ["make-event symbol:" get-symbol-name sym lf]
		case [
			sym = done [state: EVT_NO_DISPATCH]			;-- prevent other high-level events
			sym = stop [state: EVT_NO_DISPATCH]			;-- prevent all other events
			true 	   [0]								;-- ignore others
		]
	]

	; #call [system/view/awake gui-evt]
	; res: as red-word! stack/arguments

	; if TYPE_OF(res) = TYPE_WORD [
	; 	sym: symbol/resolve res/symbol
	; 	;; DEBUG:
	; 	print ["make-events result:" sym lf]

	; 	case [
	; 		sym = done [state: EVT_DISPATCH]			;-- prevent other high-level events
	; 		sym = stop [state: EVT_NO_DISPATCH]			;-- prevent all other events
	; 		true 	   [0]								;-- ignore others
	; 	]
	; ]

	state
]

do-events: func [
	no-wait? [logic!]
	return:  [logic!]
	/local
		msg? 	[logic!]
		event	[GdkEventAny!]
		widget	[handle!]
		; state	[GdkModifierType!]
		; source	[handle!]
][
	msg?: no

	set-view-no-wait gtk_application_get_active_window GTKApp no-wait?

	;@@ Improve it!!!
	;@@ as we cannot access gapplication->priv->use_count
	;@@ we use a global value to simulate it

	;; DEBUG: print ["do-events no-wait? " no-wait? lf]

	;; Initially normally uncommented: the exit-loop is also decremented in destroy for supposed no-wait view!
	unless no-wait? [
		exit-loop: exit-loop + 1
	]

	while [exit-loop > 0][
		if g_main_context_iteration GTKApp-Ctx not no-wait? [msg?: yes]
		if no-wait? [break]
	]

	while [g_main_context_iteration GTKApp-Ctx false][	;-- consume leftover event
		msg?: yes
		if no-wait? [break]
	]

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

check-extra-buttons: func [
	state	[integer!]
	return:	[integer!]
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
	state  [integer!]
	return: [integer!]
	/local
		flags [integer!]
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
	type   	[integer!]
	state  	[integer!]
	return: [integer!]
	/local
		flags [integer!]
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

translate-key: func [
	keycode [integer!]
	return: [integer!]
	/local
		key 		[integer!]
		special?	[logic!]
][
	;; DEBUG: print ["keycode: " keycode lf]
	keycode: either gdk_keyval_is_upper keycode [gdk_keyval_to_upper keycode][gdk_keyval_to_lower keycode]
	;; DEBUG: print [" translate-key: keycode: " keycode lf]
	special?: no
	key: case [
		all[keycode >= 20h keycode <= 5Ah][keycode]; RED_VK_SPACE to RED_VK_Z
		all[keycode >= 5Bh keycode <= 60h][keycode]
		all[keycode >= 61h keycode <= 7Ah][keycode]; RED_VK_a to RED_VK_z
		all[keycode >= 7Bh keycode <= 7Dh][keycode];
		all[keycode >= A0h keycode <= FFh][keycode];
		all[keycode >= FFBEh keycode <= FFD5h][special?: yes keycode + RED_VK_F1 - FFBEh]		;RED_VK_F1 to RED_VK_F24
		all[keycode >= FF51h keycode <= FF54h][special?: yes keycode + RED_VK_LEFT - FF51h]		;RED_VK_LEFT to RED_VK_DOWN
		all[keycode >= FF55h keycode <= FF57h][special?: yes keycode + RED_VK_PRIOR - FF51h]	;RED_VK_PRIOR to RED_VK_END
		keycode = FF0Dh	[special?: no RED_VK_RETURN]
		keycode = FF1Bh [special?: yes RED_VK_ESCAPE]
		keycode = FF50h [special?: yes RED_VK_HOME]
		keycode = FFE5h [special?: yes RED_VK_NUMLOCK]
		keycode = FF08h [special?: no RED_VK_BACK]
		keycode = FF09h [special?: no RED_VK_TAB]
		keycode = FFE1h [special?: yes RED_VK_LSHIFT]
		keycode = FFE2h [special?: yes RED_VK_RSHIFT]
		keycode = FFE3h [special?: yes RED_VK_LCONTROL]
		keycode = FFE4h [special?: yes RED_VK_RCONTROL]
		keycode = FFFFh [special?: yes RED_VK_DELETE]
		;@@ To complete!
		true [RED_VK_UNKNOWN]
	]
	if special? [key: key or 80000000h]
	special-key: either special? [key][-1]
	;; DEBUG: 	print [" key: " key " special?=" special?  lf]
	key
]

post-quit-msg: func [
	/local
		e	[integer!]
		tm	[float!]
][
	exit-loop: exit-loop - 1
]

;;------------- centralize here connection handlers
;; The goal is to only connect gtk handlers only when actor is provided
;; Rmk: Specific development for rich-text with panel parent with on-over actor for rich-text
;; 		The panel needs to receive the event otherwise the rich-text can't receive the event with the associated actor.
;;		A delegation connection is provided to do so.

#enum DebugConnect! [
	DEBUG_CONNECT_NONE: 			0
	DEBUG_CONNECT_WIDGET: 			1
	DEBUG_CONNECT_COMMON: 			2
	DEBUG_CONNECT_NOTIFY: 			4
	DEBUG_CONNECT_RESPOND_KEY: 		8
	DEBUG_CONNECT_RESPOND_MOUSE: 	16
	DEBUG_CONNECT_RESPOND_WINDOW: 	32
	DEBUG_CONNECT_ALL_ADD:      63
	DEBUG_CONNECT_RESPOND_EVENT: 	65536
	DEBUG_CONNECT_ALL:				131071
]

;; DEBUG mode: NONE vs ALL vs ALL_ADD
debug-connect-level: DEBUG_CONNECT_NONE
;debug-connect-level: DEBUG_CONNECT_ALL_ADD

debug-connect?: func [level [integer!] return: [logic!]][debug-connect-level and level <> 0]

;; TODO: before finding better solution!!!!
;; container-type? is now only restricted to rich-text (cf gui.red)
;; since
;; 1) it is required in makedoc/easy-VID-rt.red
;; 2) it is too slow when used in ast.red for base widget (too much delegations).

connect-common-events: function [
	widget		[handle!]
	data		[int-ptr!]
][
	assert widget <> null
	gtk_widget_add_events widget GDK_BUTTON_PRESS_MASK
	gobj_signal_connect(widget "button-press-event" :mouse-button-press-event data)
	
	gtk_widget_add_events widget GDK_BUTTON1_MOTION_MASK or GDK_POINTER_MOTION_MASK
	gobj_signal_connect(widget "motion-notify-event" :mouse-motion-notify-event data)


	gtk_widget_add_events widget GDK_BUTTON_RELEASE_MASK
	gobj_signal_connect(widget "button-release-event" :mouse-button-release-event data)

	gtk_widget_add_events widget GDK_KEY_PRESS_MASK or GDK_FOCUS_CHANGE_MASK
	gobj_signal_connect(widget "key-press-event" :key-press-event data)

	gtk_widget_add_events widget GDK_KEY_RELEASE_MASK
	gobj_signal_connect(widget "key-release-event" :key-release-event data)

	gtk_widget_add_events widget GDK_SCROLL_MASK
	gobj_signal_connect(widget "scroll-event" :widget-scroll-event data)
]

connect-focus-events: function [
	widget		[handle!]
	data		[int-ptr!]
][
	assert widget <> null
	gobj_signal_connect(widget "focus-in-event" :focus-in-event data)
	gobj_signal_connect(widget "focus-out-event" :focus-out-event data)
]

connect-notify-events: function [
	widget		[handle!]
	data		[int-ptr!]
][
	assert widget <> null
	gtk_widget_add_events widget GDK_ENTER_NOTIFY_MASK or GDK_LEAVE_NOTIFY_MASK
	gobj_signal_connect(widget "enter-notify-event" :widget-enter-notify-event data)
	gobj_signal_connect(widget "leave-notify-event" :widget-leave-notify-event data)
]

connect-widget-events: function [
	widget		[handle!]
	sym			[integer!]
	evbox		[handle!]
	/local
		buffer	[handle!]
][
	;; register red mouse, key event functions
	connect-common-events evbox widget

	case [
		sym = check [
			;@@ No click event for check
			;gobj_signal_connect(widget "clicked" :button-clicked null)
			gobj_signal_connect(evbox "toggled" :button-toggled widget)
		]
		sym = radio [
			;@@ Line below removed because it generates an error and there is no click event for radio
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add radio toggled " lf]]
			gobj_signal_connect(evbox "toggled" :button-toggled widget)
		]
		sym = button [
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add button clicked " lf]]
			gobj_signal_connect(evbox "clicked" :button-clicked widget)
		]
		sym = base [
			gobj_signal_connect(evbox "draw" :base-draw widget)
			gtk_widget_add_events evbox GDK_BUTTON_PRESS_MASK or GDK_BUTTON1_MOTION_MASK or GDK_BUTTON_RELEASE_MASK or GDK_KEY_PRESS_MASK or GDK_KEY_RELEASE_MASK
			gtk_widget_set_can_focus evbox yes
			gtk_widget_set_focus_on_click evbox yes
		]
		sym = rich-text [
			gobj_signal_connect(widget "draw" :base-draw widget)
			gtk_widget_add_events widget GDK_BUTTON_PRESS_MASK or GDK_BUTTON1_MOTION_MASK or GDK_BUTTON_RELEASE_MASK or GDK_KEY_PRESS_MASK or GDK_KEY_RELEASE_MASK
			gtk_widget_set_can_focus widget yes
			gtk_widget_set_focus_on_click widget yes
			gtk_widget_is_focus widget
			gtk_widget_grab_focus widget
			connect-focus-events widget widget
		]
		sym = window [
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add window delete-event " lf]]
			gobj_signal_connect(evbox "delete-event" :window-delete-event widget)
			;BUG (make `vid.red` failing): gtk_widget_add_events widget GDK_STRUCTURE_MASK
			gobj_signal_connect(evbox "configure-event" :window-configure-event widget)
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add window size-allocate " lf]]
			gobj_signal_connect(evbox "size-allocate" :window-size-allocate widget)
			connect-focus-events evbox widget
		]
		sym = slider [
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add slider value-changed " lf]]
			gobj_signal_connect(evbox "value-changed" :range-value-changed widget)
		]
		sym = text [0]
		sym = field [
			buffer: gtk_entry_get_buffer widget
			gobj_signal_connect(buffer "changed" :field-changed widget)
			gtk_widget_set_can_focus evbox yes
			gtk_widget_set_focus_on_click evbox yes
			gtk_widget_is_focus evbox
			gtk_widget_grab_focus evbox
			connect-focus-events evbox widget
		]
		sym = progress [
			0
		]
		sym = area [
			; _widget is here buffer
			buffer: gtk_text_view_get_buffer widget
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add area changed " lf]]
			gobj_signal_connect(buffer "changed" :area-changed widget)
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add area populate-all " lf]]
			g_object_set [evbox "populate-all" yes widget]
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add area populate-popup" lf]]
			gobj_signal_connect(evbox "populate-popup" :area-populate-popup widget)
			gtk_widget_set_can_focus evbox yes
			gtk_widget_set_focus_on_click evbox yes
			gtk_widget_is_focus evbox
			gtk_widget_grab_focus evbox
			connect-focus-events evbox widget
		]
		sym = group-box [
			0
		]
		sym = panel [
			gobj_signal_connect(evbox "draw" :base-draw widget)
			gtk_widget_add_events evbox GDK_BUTTON_PRESS_MASK or GDK_BUTTON1_MOTION_MASK or GDK_BUTTON_RELEASE_MASK or GDK_KEY_PRESS_MASK or GDK_KEY_RELEASE_MASK or GDK_FOCUS_CHANGE_MASK
			gtk_widget_set_can_focus evbox yes
			gtk_widget_set_focus_on_click evbox yes
		]
		sym = tab-panel [
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add tab-panel switch-page " lf]]
			gobj_signal_connect(evbox "switch-page" :tab-panel-switch-page widget)
		]
		sym = text-list [
			;;; Mandatory and can respond to  (ON_SELECT or ON_CHANGE)
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add text-list selected-rows-changed " lf]]
			gobj_signal_connect(evbox "selected-rows-changed" :text-list-selected-rows-changed widget)
		]
		any [
			sym = drop-list
			sym = drop-down
		][
			;;; Mandatory! and can respond to (ON_SELECT or ON_CHANGE)
			;; DEBUG: if debug-connect? DEBUG_CONNECT_WIDGET [print ["Add drop-(list|down) changed " lf]]
			gobj_signal_connect(evbox "changed" :combo-selection-changed widget)
		]
		true [0]
	]
	connect-notify-events evbox widget
]