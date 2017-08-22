Red/System [
	Title:	"GTK3 events handling"
	Author: "Qingtian Xie"
	File: 	%events.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

keycode-table: [
	RED_VK_A				;-- 0
	RED_VK_S				;-- 1
	RED_VK_D				;-- 2
	RED_VK_F				;-- 3
	RED_VK_H				;-- 4
	RED_VK_G				;-- 5
	RED_VK_Z				;-- 6
	RED_VK_X				;-- 7
	RED_VK_C				;-- 8
	RED_VK_V				;-- 9
	RED_VK_OEM_3			;-- 0x0A	Section key.
	RED_VK_B				;-- 0x0B
	RED_VK_Q				;-- 0x0C
	RED_VK_W				;-- 0x0D
	RED_VK_E				;-- 0x0E
	RED_VK_R				;-- 0x0F
	RED_VK_Y				;-- 0x10
	RED_VK_T				;-- 0x11
	RED_VK_1				;-- 0x12
	RED_VK_2				;-- 0x13
	RED_VK_3				;-- 0x14
	RED_VK_4				;-- 0x15
	RED_VK_6				;-- 0x16
	RED_VK_5				;-- 0x17
	RED_VK_OEM_PLUS			;-- 0x18	=+
	RED_VK_9				;-- 0x19
	RED_VK_7				;-- 0x1A
	RED_VK_OEM_MINUS		;-- 0x1B	-_
	RED_VK_8				;-- 0x1C
	RED_VK_0				;-- 0x1D
	RED_VK_OEM_6			;-- 0x1E	]}
	RED_VK_O				;-- 0x1F
	RED_VK_U				;-- 0x20
	RED_VK_OEM_4			;-- 0x21	{[
	RED_VK_I				;-- 0x22
	RED_VK_P				;-- 0x23
	RED_VK_RETURN			;-- 0x24	Return
	RED_VK_L				;-- 0x25
	RED_VK_J				;-- 0x26
	RED_VK_OEM_7			;-- 0x27	'"
	RED_VK_K				;-- 0x28
	RED_VK_OEM_1			;-- 0x29	;:
	RED_VK_OEM_5			;-- 0x2A	\|
	RED_VK_OEM_COMMA		;-- 0x2B	<
	RED_VK_OEM_2			;-- 0x2C	/?
	RED_VK_N				;-- 0x2D
	RED_VK_M				;-- 0x2E
	RED_VK_OEM_PERIOD		;-- 0x2F	.>
	RED_VK_TAB				;-- 0x30
	RED_VK_SPACE			;-- 0x31
	RED_VK_OEM_3			;-- 0x32	 `~
	RED_VK_BACK				;-- 0x33	Backspace
	RED_VK_UNKNOWN			;-- 0x34	n/a
	RED_VK_ESCAPE			;-- 0x35
	RED_VK_APPS				;-- 0x36	Right Command
	RED_VK_LWIN				;-- 0x37	Left Command
	RED_VK_SHIFT			;-- 0x38	Left Shift
	RED_VK_CAPITAL			;-- 0x39	Caps Lock
	RED_VK_MENU				;-- 0x3A	Left Option
	RED_VK_CONTROL			;-- 0x3B	Left Ctrl
	RED_VK_SHIFT			;-- 0x3C	Right Shift
	RED_VK_MENU				;-- 0x3D	Right Option
	RED_VK_CONTROL			;-- 0x3E	Right Ctrl
	RED_VK_UNKNOWN			;-- 0x3F	fn
	RED_VK_F17				;-- 0x40
	RED_VK_DECIMAL			;-- 0x41	Num Pad .
	RED_VK_UNKNOWN			;-- 0x42	n/a
	RED_VK_MULTIPLY			;-- 0x43	Num Pad *
	RED_VK_UNKNOWN			;-- 0x44	n/a
	RED_VK_ADD				;-- 0x45	Num Pad +
	RED_VK_UNKNOWN			;-- 0x46	n/a
	RED_VK_CLEAR			;-- 0x47	Num Pad Clear
	RED_VK_VOLUME_UP		;-- 0x48
	RED_VK_VOLUME_DOWN		;-- 0x49
	RED_VK_VOLUME_MUTE		;-- 0x4A
	RED_VK_DIVIDE			;-- 0x4B	Num Pad /
	RED_VK_RETURN			;-- 0x4C	Num Pad Enter
	RED_VK_UNKNOWN			;-- 0x4D	n/a
	RED_VK_SUBTRACT			;-- 0x4E	Num Pad -
	RED_VK_F18				;-- 0x4F
	RED_VK_F19				;-- 0x50
	RED_VK_OEM_PLUS			;-- 0x51	Num Pad =.
	RED_VK_NUMPAD0			;-- 0x52
	RED_VK_NUMPAD1			;-- 0x53
	RED_VK_NUMPAD2			;-- 0x54
	RED_VK_NUMPAD3			;-- 0x55
	RED_VK_NUMPAD4			;-- 0x56
	RED_VK_NUMPAD5			;-- 0x57
	RED_VK_NUMPAD6			;-- 0x58
	RED_VK_NUMPAD7			;-- 0x59
	RED_VK_F20				;-- 0x5A
	RED_VK_NUMPAD8			;-- 0x5B
	RED_VK_NUMPAD9			;-- 0x5C
	RED_VK_UNKNOWN			;-- 0x5D	Yen (JIS Keyboard Only)
	RED_VK_UNKNOWN			;-- 0x5E	Underscore (JIS Keyboard Only)
	RED_VK_UNKNOWN			;-- 0x5F	KeypadComma (JIS Keyboard Only)
	RED_VK_F5				;-- 0x60
	RED_VK_F6				;-- 0x61
	RED_VK_F7				;-- 0x62
	RED_VK_F3				;-- 0x63
	RED_VK_F8				;-- 0x64
	RED_VK_F9				;-- 0x65
	RED_VK_UNKNOWN			;-- 0x66	Eisu (JIS Keyboard Only)
	RED_VK_F11				;-- 0x67
	RED_VK_UNKNOWN			;-- 0x68	Kana (JIS Keyboard Only)
	RED_VK_F13				;-- 0x69
	RED_VK_F16				;-- 0x6A
	RED_VK_F14				;-- 0x6B
	RED_VK_UNKNOWN			;-- 0x6C	n/a
	RED_VK_F10				;-- 0x6D
	RED_VK_UNKNOWN			;-- 0x6E	n/a (Windows95 key?)
	RED_VK_F12				;-- 0x6F
	RED_VK_UNKNOWN			;-- 0x70	n/a
	RED_VK_F15				;-- 0x71
	RED_VK_INSERT			;-- 0x72	Help
	RED_VK_HOME				;-- 0x73	Home
	RED_VK_PRIOR			;-- 0x74	Page Up
	RED_VK_DELETE			;-- 0x75	Forward Delete
	RED_VK_F4				;-- 0x76
	RED_VK_END				;-- 0x77	End
	RED_VK_F2				;-- 0x78
	RED_VK_NEXT				;-- 0x79	Page Down
	RED_VK_F1				;-- 0x7A
	RED_VK_LEFT				;-- 0x7B	Left Arrow
	RED_VK_RIGHT			;-- 0x7C	Right Arrow
	RED_VK_DOWN				;-- 0x7D	Down Arrow
	RED_VK_UP				;-- 0x7E	Up Arrow
	RED_VK_UNKNOWN			;-- 0x7F	n/a
]

; RED_VK_UNKNOWN 1->0x1
; RED_VK_UNKNOWN 2->0x2
; RED_VK_UNKNOWN 3->0x3
; RED_VK_UNKNOWN 4->0x4
; RED_VK_UNKNOWN 5->0x5
; RED_VK_UNKNOWN 6->0x6
; RED_VK_UNKNOWN 7->0x7
; RED_VK_UNKNOWN 8->0x8
; 9->0x9
; 10->0xa
; 11->0xb
; 12->0xc
; 13->0xd
; 14->0xe
; 15->0xf
; 16->0x10
; 17->0x11
; 18->0x12
; 19->0x13
; 20->0x14
; 21->0x15
; 22->0x16
; 23->0x17
; 24->0x18
; 25->0x19
; 26->0x1a
; 27->0x1b
; 28->0x1c
; 29->0x1d
; 30->0x1e
; 31->0x1f
; 32->space
; 33->exclam
; 34->quotedbl
; 35->numbersign
; 36->dollar
; 37->percent
; 38->ampersand
; 39->apostrophe
; 40->parenleft
; 41->parenright
; 42->asterisk
; 43->plus
; 44->comma
; 45->minus
; 46->period
; 47->slash
; 48->0
; 49->1
; 50->2
; 51->3
; 52->4
; 53->5
; 54->6
; 55->7
; 56->8
; 57->9
; 58->colon
; 59->semicolon
; 60->less
; 61->equal
; 62->greater
; 63->question
; 64->at
; 65->A
; 66->B
; 67->C
; 68->D
; 69->E
; 70->F
; 71->G
; 72->H
; 73->I
; 74->J
; 75->K
; 76->L
; 77->M
; 78->N
; 79->O
; 80->P
; 81->Q
; 82->R
; 83->S
; 84->T
; 85->U
; 86->V
; 87->W
; 88->X
; 89->Y
; 90->Z
; 91->bracketleft
; 92->backslash
; 93->bracketright
; 94->asciicircum
; 95->underscore
; 96->grave
; 97->a
; 98->b
; 99->c
; 100->d
; 101->e
; 102->f
; 103->g
; 104->h
; 105->i
; 106->j
; 107->k
; 108->l
; 109->m
; 110->n
; 111->o
; 112->p
; 113->q
; 114->r
; 115->s
; 116->t
; 117->u
; 118->v
; 119->w
; 120->x
; 121->y
; 122->z
; 123->braceleft
; 124->bar
; 125->braceright
; 126->asciitilde
; 127->0x7f
; 128->0x80


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
		offset [red-pair!]
		value  [integer!]
][
	case [
		any [
			evt/type <= EVT_OVER
			evt/type = EVT_MOVING
			evt/type = EVT_SIZING
			evt/type = EVT_MOVE
			evt/type = EVT_SIZE
		][
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
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
			print ["code " code lf]
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
	print ["keycode: " keycode]
	keycode: gdk_keyval_to_upper keycode
	print [" keycode2: " keycode]
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
	print [" key: " key " F1" RED_VK_F1 lf]
	key
]