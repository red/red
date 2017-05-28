Red/System [
	Title:	"Cocoa events handling"
	Author: "Qingtian Xie"
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

char-keys: [
	1000C400h C0FF0080h E0FFFF7Fh 0000F7FFh 00000000h 3F000000h 1F000080h 00FC7F38h
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

make-at: func [
	view	[integer!]
	face	[red-object!]
	return: [red-object!]
	/local
		ivar [integer!]
][
	ivar: class_getInstanceVariable object_getClass view IVAR_RED_FACE
	assert ivar <> 0
	as red-object! copy-cell as cell! view + ivar_getOffset ivar as cell! face
]

push-face: func [
	handle  [integer!]
	return: [red-object!]
][
	make-at handle as red-object! stack/push*
]

get-event-face: func [
	evt		[red-event!]
	return: [red-value!]
][
	as red-value! push-face as-integer evt/msg
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

char-key?: func [
	key	    [byte!]									;-- virtual key code
	return: [logic!]
	/local
		slot [byte-ptr!]
][
	slot: (as byte-ptr! char-keys) + as-integer (key >>> 3)
	slot/value and (as-byte (80h >> as-integer (key and as-byte 7))) <> null-byte
]

check-extra-keys: func [
	event	[integer!]
	return: [integer!]
	/local
		key		[integer!]
		flags	[integer!]
][
	key: 0
	flags: objc_msgSend [event sel_getUid "modifierFlags"]
	if NSControlKeyMask and flags <> 0 [key: EVT_FLAG_CTRL_DOWN]
	if NSShiftKeyMask and flags <> 0 [key: key or EVT_FLAG_SHIFT_DOWN]
	if NSAlternateKeyMask and flags <> 0 [key: key or EVT_FLAG_MENU_DOWN]
	if NSCommandKeyMask and flags <> 0 [key: key or EVT_FLAG_CMD_DOWN]
	key
]

translate-key: func [
	keycode [integer!]
	return: [integer!]
][
	keycode: keycode + 1
	keycode-table/keycode
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		type	[integer!]
		event	[integer!]
		offset	[red-pair!]
		rc		[NSRect!]
		y		[integer!]
		x		[integer!]
][
	type: evt/type
	offset: as red-pair! stack/push*
	offset/header: TYPE_PAIR
	case [
		type <= EVT_OVER [
			event: objc_getAssociatedObject as-integer evt/msg RedNSEventKey
			either zero? event [offset/x: 0 offset/y: 0][
				rc: as NSRect! (as int-ptr! event) + 2
				x: objc_msgSend [evt/msg sel_getUid "convertPoint:fromView:" rc/x rc/y 0]
				y: system/cpu/edx
				rc: as NSRect! :x
				offset/x: as-integer rc/x
				offset/y: as-integer rc/y
			]
			as red-value! offset
		]
		any [
			type = EVT_MOVING
			type = EVT_MOVE
		][
			rc: as NSRect! (as int-ptr! evt/msg) + 2
			offset/x: as-integer rc/x
			offset/y: screen-size-y - as-integer (rc/y + rc/h)
			as red-value! offset
		]
		any [
			type = EVT_SIZING
			type = EVT_SIZE
		][
			rc: as NSRect! (as int-ptr! evt/msg) + 2
			offset/x: as-integer rc/w
			offset/y: as-integer rc/h
			as red-value! offset
		]
		any [
			type = EVT_ZOOM
			type = EVT_PAN
			type = EVT_ROTATE
			type = EVT_TWO_TAP
			type = EVT_PRESS_TAP
		][
			as red-value! offset
		]
		true [stack/pop 1 as red-value! none-value]
	]
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		code		[integer!]
		char		[red-char!]
		res			[red-value!]
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
		EVT_SCROLL [integer/push evt/flags >>> 4]
		EVT_IME [to-red-string evt/flags null]
		default	 [integer/push evt/flags << 16 >> 16]
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
	if evt/flags and EVT_FLAG_MENU_DOWN <> 0 [block/rs-append blk as red-value! _alt]
	if evt/flags and EVT_FLAG_CMD_DOWN <> 0 [block/rs-append blk as red-value! _command]
	as red-value! blk
]

get-event-flag: func [
	flags	[integer!]
	flag	[integer!]
	return: [red-value!]
][
	as red-value! logic/push flags and flag <> 0
]

make-event: func [
	obj		[integer!]
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
	gui-evt/msg:   as byte-ptr! obj
	gui-evt/flags: flags

	state: EVT_DISPATCH

	#call [system/view/awake gui-evt]

	res: as red-word! stack/arguments
	if TYPE_OF(res) = TYPE_WORD [
		sym: symbol/resolve res/symbol
		if any [sym = done sym = stop][state: EVT_NO_DISPATCH]
	]
	state
]

process-mouse-tracking: func [
	window	[integer!]
	event	[integer!]
	return: [integer!]
	/local
		y	[integer!]
		x	[integer!]
		pt	[CGPoint!]
		n 	[integer!]
		v	[integer!]
		w	[integer!]
][
	w: window
	if zero? w [
		x: objc_msgSend [objc_getClass "NSEvent" sel_getUid "mouseLocation"]
		y: system/cpu/edx
		pt: as CGPoint! :x
		n: objc_msgSend [
			objc_getClass "NSWindow" sel_getUid "windowNumberAtPoint:belowWindowWithWindowNumber:"
			pt/x pt/y 0
		]
		w: objc_msgSend [NSApp sel_getUid "windowWithWindowNumber:" n]
	]
	if w <> 0 [
		v: objc_msgSend [w sel_getUid "contentView"]
		if v <> 0 [v: objc_msgSend [v sel_getUid "superview"]]
		if zero? v [return 0]

		either zero? window [
			x: objc_msgSend [w sel_getUid "convertScreenToBase:" pt/x pt/y]
		][
			x: objc_msgSend [event sel_getUid "locationInWindow"]
		]
		y: system/cpu/edx
		pt: as CGPoint! :x

		v: objc_msgSend [v sel_getUid "hitTest:" pt/x pt/y]

		while [all [v <> 0 not red-face? v]][
			v: objc_msgSend [v sel_getUid "superview"]
		]
		if v <> 0 [
			objc_msgSend [v sel_getUid "mouseMoved:" event]
		]
		if v <> current-widget [
			if current-widget <> 0 [
				objc_msgSend [current-widget sel_getUid "mouseExited:" event]
			]
			if v <> 0 [objc_msgSend [v sel_getUid "mouseEntered:" event]]
			current-widget: v
		]
	]
	w
]

process: func [
	event	[integer!]
	return: [integer!]
	/local
		p-int		[int-ptr!]
		type		[integer!]
		window		[integer!]
		n-win		[integer!]
		flags		[integer!]
		faces		[red-block!]
		face		[red-object!]
		start		[red-object!]
		check?		[logic!]
		active?		[logic!]
		down?		[logic!]
		y			[integer!]
		x			[integer!]
		point		[CGPoint!]
		view		[integer!]
][
	window: objc_msgSend [event sel_getUid "window"]
	p-int: as int-ptr! event
	type: p-int/2
	switch type [
		NSMouseMoved
		NSLeftMouseDragged
		NSRightMouseDragged
		NSOtherMouseDragged [
			check?: yes
			window: process-mouse-tracking window event
		]
		default [0]
	]

	if window <> 0 [
		down?: no active?: no check?: no

		if any [
			type = NSLeftMouseDown type = NSRightMouseDown type = NSOtherMouseDown
		][
			active?: yes down?: yes check?: yes
		]
		if any [
			type = NSLeftMouseUp type = NSRightMouseUp type = NSOtherMouseUp
		][
			active?: yes check?: yes
		]
		switch type [
			NSMouseEntered
			NSMouseExited
			NSKeyDown
			NSKeyUp
			NSScrollWheel [check?: yes]
			default [0]
		]

		if all [check? red-face? window][
			faces: as red-block! #get system/view/screens
			face: as red-object! block/rs-head faces		;-- screen 1 TBD multi-screen support
			faces: as red-block! get-node-facet face/ctx FACE_OBJ_PANE
			if 1 >= block/rs-length? faces [return EVT_DISPATCH]

			start: as red-object! block/rs-head faces
			face:  as red-object! block/rs-tail faces
			while [
				face: face - 1
				face >= start
			][
				flags: get-flags as red-block! get-node-facet face/ctx FACE_OBJ_FLAGS
				if all [
					window <> get-face-handle face
					flags and FACET_FLAGS_MODAL <> 0
				][
					if down? [NSBeep]
					return EVT_NO_DISPATCH
				]
			]
		]
	]
	EVT_DISPATCH
]

close-pending-windows: func [/local n [integer!] p [int-ptr!]][
	n: vector/rs-length? win-array
	if zero? n [exit]

	p: as int-ptr! vector/rs-head win-array
	while [n > 0][
		free-handles p/value yes
		p: p + 1
		n: n - 1
	]
	vector/rs-clear win-array
	close-window?: no
]

do-events: func [
	no-wait? [logic!]
	return:  [logic!]
	/local
		msg?	[logic!]
		state	[integer!]
		pool	[integer!]
		timeout [integer!]
		event	[integer!]
][
	msg?: no
	either loop-started? [no-wait?: yes][loop-started?: yes]		;-- just keep one event loop

	timeout: either no-wait? [0][
		objc_msgSend [NSApp sel_getUid "activateIgnoringOtherApps:" 1]
		objc_msgSend [objc_getClass "NSDate" sel_getUid "distantFuture"]	
	]

	until [
		pool: objc_msgSend [objc_getClass "NSAutoreleasePool" sel_getUid "alloc"]
		objc_msgSend [pool sel_getUid "init"]

		event: objc_msgSend [
			NSApp sel_getUid "nextEventMatchingMask:untilDate:inMode:dequeue:"
			NSAnyEventMask
			timeout
			NSDefaultRunLoopMode
			true
		]

		if event <> 0 [
			msg?: yes
			state: process event
			if state >= EVT_DISPATCH [
				objc_msgSend [NSApp sel_getUid "sendEvent:" event]
			]
		]

		if close-window? [close-pending-windows]

		objc_msgSend [pool sel_getUid "drain"]
		any [zero? win-cnt no-wait?]
	]

	if zero? win-cnt [
		loop-started?: no
		objc_msgSend [NSApp sel_getUid "stop:" 0]
	]
	msg?
]