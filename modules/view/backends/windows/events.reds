Red/System [
	Title:	"Windows events handling"
	Author: "Nenad Rakocevic"
	File: 	%events.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum event-action! [
	EVT_NO_DISPATCH										;-- no further msg processing allowed
	EVT_DISPATCH										;-- allow DispatchMessage call only
]

paint: declare tagPAINTSTRUCT							;-- moved here from 'draw.reds'

gui-evt: declare red-event!								;-- low-level event value slot
gui-evt/header: TYPE_EVENT

oldBaseWndProc:	 0
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

make-at: func [
	handle  [handle!]
	face	[red-object!]
	return: [red-object!]
][
	face/header:		  GetWindowLong handle wc-offset
	face/ctx:	 as node! GetWindowLong handle wc-offset + 4
	face/class:			  GetWindowLong handle wc-offset + 8
	face/on-set: as node! GetWindowLong handle wc-offset + 12
	face
]

push-face: func [
	handle  [handle!]
	return: [red-object!]
][
	make-at handle as red-object! stack/push*
]

get-event-window: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		handle [handle!]
		msg    [tagMSG]
][
	msg: as tagMSG evt/msg
	handle: get-widget-handle msg
	as red-value! either handle = as handle! -1 [		;-- filter out unwanted events
		none-value
	][
		push-face GetAncestor handle 2					;-- GA_ROOT
	]
]

get-event-face: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		handle [handle!]
		msg    [tagMSG]
][
	msg: as tagMSG evt/msg
	handle: get-widget-handle msg
	as red-value! either handle = as handle! -1 [		;-- filter out unwanted events
		none-value
	][
		push-face handle
	]
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		offset [red-pair!]
		value  [integer!]
		msg    [tagMSG]
		pt	   [tagPOINT]
		gi	   [GESTUREINFO]
		x	   [integer!]
		y	   [integer!]
][
	msg: as tagMSG evt/msg
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
			value: msg/lParam
			
			either evt/flags and EVT_FLAG_AWAY <> 0 [
				msg: as tagMSG evt/msg
				pt: declare tagPOINT
				pt/x: WIN32_LOWORD(value)
				pt/y: WIN32_HIWORD(value)
				ClientToScreen get-child-from-xy msg/hWnd pt/x pt/y pt
				x: pt/x
				y: pt/y
				pt: get-window-pos msg/hWnd
				ClientToScreen msg/hWnd pt
				offset/x: x - pt/x
				offset/y: y - pt/y
			][
				offset/x: WIN32_LOWORD(value)
				offset/y: WIN32_HIWORD(value)
			]
			as red-value! offset
		]
		any [
			evt/type = EVT_KEY
			evt/type = EVT_KEY_UP
			evt/type = EVT_KEY_DOWN
		][
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR

			value: GetMessagePos
			pt: screen-to-client msg/hWnd WIN32_LOWORD(value) WIN32_HIWORD(value)
			offset/x: pt/x
			offset/y: pt/y
			as red-value! offset
		]
		any [
			evt/type = EVT_ZOOM
			evt/type = EVT_PAN
			evt/type = EVT_ROTATE
			evt/type = EVT_TWO_TAP
			evt/type = EVT_PRESS_TAP
		][
			gi: get-gesture-info msg/lParam
			
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			value: gi/ptsLocation						;-- coordinates of center point		

			offset/x: WIN32_LOWORD(value)
			offset/y: WIN32_HIWORD(value)
			as red-value! offset
		]
		true [as red-value! none-value]
	]
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		char [red-char!]
		msg  [tagMSG]
][
	as red-value! switch evt/type [
		EVT_KEY
		EVT_KEY_UP
		EVT_KEY_DOWN [
			either special-key <> -1 [
				switch special-key [
					VK_PRIOR	[_page-up]
					VK_NEXT		[_page-down]
					VK_END		[_end]
					VK_HOME		[_home]
					VK_LEFT		[_left]
					VK_UP		[_up]
					VK_RIGHT	[_right]
					VK_DOWN		[_down]
					VK_INSERT	[_insert]
					VK_DELETE	[_delete]
					VK_F1		[_F1]
					VK_F2		[_F2]
					VK_F3		[_F3]
					VK_F4		[_F4]
					VK_F5		[_F5]
					VK_F6		[_F6]
					VK_F7		[_F7]
					VK_F8		[_F8]
					VK_F9		[_F9]
					VK_F10		[_F10]
					VK_F11		[_F11]
					VK_F12		[_F12]
					VK_LSHIFT	[_left-shift]
					VK_RSHIFT	[_right-shift]
					VK_LCONTROL	[_left-control]
					VK_RCONTROL	[_right-control]
					VK_CAPITAL	[_caps-lock]
					VK_NUMLOCK	[_num-lock]
					VK_LMENU	[_left-alt]
					VK_RMENU	[_right-alt]
					VK_LWIN		[_left-command]
					VK_RWIN		[_right-command]
					default		[
						either evt/type = EVT_KEY [none-value][
							char: as red-char! stack/push*
							char/header: TYPE_CHAR
							char/value: evt/flags and FFFFh
							as red-value! char
						]
					]
				]
			][
				char: as red-char! stack/push*
				char/header: TYPE_CHAR
				char/value: evt/flags and FFFFh
				as red-value! char
			]
		]
		EVT_SCROLL [
			msg: as tagMSG evt/msg
			either msg/msg = WM_VSCROLL [
				switch msg/wParam and FFFFh [
					SB_LINEUP	[_up]
					SB_LINEDOWN [_down]
					SB_PAGEUP	[_page-up]
					SB_PAGEDOWN	[_page-down]
					SB_THUMBTRACK [_track]
					default		[_end]
				]
			][
				switch msg/wParam and FFFFh [
					SB_LINEUP	[_left]
					SB_LINEDOWN [_right]
					SB_PAGEUP	[_page-left]
					SB_PAGEDOWN	[_page-right]
					SB_THUMBTRACK [_track]
					default		[_end]
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
		msg	[tagMSG]
		gi	[GESTUREINFO]
		zd	[float!]
][
	as red-value! switch evt/type [
		EVT_ZOOM
		EVT_PAN
		EVT_ROTATE
		EVT_TWO_TAP
		EVT_PRESS_TAP [
			msg: as tagMSG evt/msg
			gi: get-gesture-info msg/lParam
			either evt/type = EVT_ZOOM [
				res: as red-value! either zoom-distance = -1 [none/push][
					pct: as red-float! stack/push*
					pct/header: TYPE_PERCENT
					zd: as-float zoom-distance
					pct/value: 1.0 + ((as-float gi/ullArgumentH) - zd / zd)				
					pct
				]
				zoom-distance: gi/ullArgumentH
				res
			][
				int: as red-integer! stack/push*
				int/header: TYPE_INTEGER
				int/value: gi/ullArgumentH
				int
			]
		]
		EVT_MENU [word/push* evt/flags and FFFFh]
		EVT_SCROLL [
			msg: as tagMSG evt/msg
			integer/push get-track-pos msg/hWnd msg/msg = WM_VSCROLL
		]
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
	if evt/flags and EVT_FLAG_MENU_DOWN  <> 0 [block/rs-append blk as red-value! _alt]
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

map-left-right: func [
	wParam  [integer!]
	lParam  [integer!]
	return: [integer!]
	/local
		scancode [integer!]
		key		 [integer!]
		extend?	 [logic!]
][
	key: wParam and FFFFh
	scancode: lParam and 00FF0000h >>> 16
	extend?: lParam and 01000000h <> 0
	
	switch key [
		VK_SHIFT   [key: MapVirtualKey scancode 3]		;-- MAPVK_VSC_TO_VK_EX
		VK_CONTROL [key: either extend? [VK_RCONTROL][VK_LCONTROL]]
		VK_MENU	   [key: either extend? [VK_RMENU][VK_LMENU]]
		default    [0]
	]	
	key
]

check-extra-keys: func [
	only?	[logic!]
	return: [integer!]
	/local
		key [integer!]
][
	key: 0
	if (GetAsyncKeyState VK_CONTROL)  and 8000h <> 0 [key: EVT_FLAG_CTRL_DOWN]
	if (GetAsyncKeyState VK_SHIFT)    and 8000h <> 0 [key: key or EVT_FLAG_SHIFT_DOWN]
	if (GetAsyncKeyState VK_MENU)     and 8000h <> 0 [key: key or EVT_FLAG_MENU_DOWN]	;-- ALT key
	
	unless only? [
		if (GetAsyncKeyState 01h) and 8000h <> 0 [key: key or EVT_FLAG_DOWN] 	   ;-- VK_LBUTTON
		if (GetAsyncKeyState 02h) and 8000h <> 0 [key: key or EVT_FLAG_ALT_DOWN]   ;-- VK_RBUTTON
		if (GetAsyncKeyState 04h) and 8000h <> 0 [key: key or EVT_FLAG_MID_DOWN]   ;-- VK_MBUTTON
		if (GetAsyncKeyState 05h) and 8000h <> 0 [key: key or EVT_FLAG_AUX_DOWN]   ;-- VK_XBUTTON1
	]
	key
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

get-track-pos: func [
	hWnd			[handle!]
	vertical?		[logic!]
	return:			[integer!]
	/local
		nTrackPos	[integer!]
		nPos		[integer!]
		nPage		[integer!]
		nMax		[integer!]
		nMin		[integer!]
		fMask		[integer!]
		cbSize		[integer!]
][
	cbSize: size? tagSCROLLINFO
	fMask: 4 or 10h
	nPos: 0
	nTrackPos: 0
	GetScrollInfo hWnd as-integer vertical? as tagSCROLLINFO :cbSize
	nTrackPos
]

make-event: func [
	msg		[tagMSG]
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
	gui-evt/flags: 0

	state: EVT_DISPATCH

	switch evt [
		EVT_OVER [
			gui-evt/flags: gui-evt/flags or flags or decode-down-flags msg/wParam
		]
		EVT_KEY_DOWN [
			key: msg/wParam and FFFFh
			if key = VK_PROCESSKEY [			;-- IME-friendly exit
				if ime-open? [special-key: -1]
				return EVT_DISPATCH
			]
			special-key: either any [
				ime-open?
				char-key? as-byte key
			][-1][map-left-right key msg/lParam]
			gui-evt/flags: key or check-extra-keys no
		]
		EVT_KEY_UP [
			key: msg/wParam and FFFFh
			special-key: either char-key? as-byte key [-1][map-left-right key msg/lParam]
			gui-evt/flags: key or check-extra-keys no
		]
		EVT_KEY [
			char: msg/wParam
			key: check-extra-keys no
			if all [
				key and EVT_FLAG_CTRL_DOWN <> 0
				96 < char char < 123					;-- #"a" <= char <= #"z"
			][char: char + 64 special-key: -1]
			if any [
				key and EVT_FLAG_SHIFT_DOWN <> 0
				special-key = VK_LMENU
				special-key = VK_RMENU
			][special-key: -1]
			gui-evt/flags: char or key
		]
		EVT_SELECT [
			word: as red-word! get-facet msg FACE_OBJ_TYPE
			assert TYPE_OF(word) = TYPE_WORD
			if word/symbol = drop-down [get-text msg flags]
			gui-evt/flags: flags + 1 and FFFFh			;-- index is one-based for string!
		]
		EVT_CHANGE [
			word: as red-word! get-facet msg FACE_OBJ_TYPE
			assert TYPE_OF(word) = TYPE_WORD
			either tab-panel = symbol/resolve word/symbol [
				gui-evt/flags: flags and FFFFh			;-- already one-based
			][
				unless zero? flags [get-text msg -1] 	;-- get text if not done already
			]
		]
		EVT_LEFT_DOWN
		EVT_LEFT_UP
		EVT_RIGHT_DOWN
		EVT_RIGHT_UP
		EVT_MIDDLE_DOWN
		EVT_MIDDLE_UP
		EVT_DBL_CLICK
		EVT_WHEEL [
			key: flags
			flags: msg/wParam
			if flags and 08h <> 0 [key: key or EVT_FLAG_CTRL_DOWN]	;-- MK_CONTROL
			if flags and 04h <> 0 [key: key or EVT_FLAG_SHIFT_DOWN]	;-- MK_SHIFT
			gui-evt/flags: key
		]
		EVT_CLICK [
			gui-evt/flags: check-extra-keys yes
		]
		EVT_MENU [gui-evt/flags: flags and FFFFh]		;-- symbol ID of the menu
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

call-custom-proc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	/local
		p	 [ext-class!]
		proc [wndproc-cb!]
][
	p: ext-classes
	while [p < ext-cls-tail][
		proc: as wndproc-cb! p/parent-proc
		unless null? :proc [proc hWnd msg wParam lParam]
		p: p + 1
	]
]

to-char: func [
	vkey	[integer!]
	return:	[integer!]									;-- Unicode char
	/local
		buf  [c-string!]
		skey [integer!]
		res	 [integer!]
][
	buf: "0123456789"									;-- makes a 10 bytes buffer
	GetKeyboardState kb-state
	skey: MapVirtualKey vkey 0							;-- MAPVK_VK_TO_VSC
	res: ToUnicode vkey skey kb-state buf 10 0
	either res > 0 [as-integer buf/1][-1]				;-- -1: conversion failed
]

init-current-msg: func [
	/local
		pos [integer!]
][
	current-msg: declare tagMSG
	pos: GetMessagePos
	current-msg/x: WIN32_LOWORD(pos)
	current-msg/y: WIN32_HIWORD(pos)
]

process-command-event: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	/local
		type   [red-word!]
		values [red-value!]
		idx	   [integer!]
		res	   [integer!]
		saved  [handle!]
		child  [handle!]
][
	if all [zero? lParam wParam < 1000][				;-- heuristic to detect a menu selection (--)'
		unless null? menu-handle [
			do-menu hWnd
			exit
		]
	]

	child: as handle! lParam
	unless null? current-msg [saved: current-msg/hWnd]
	switch WIN32_HIWORD(wParam) [
		BN_CLICKED [
			type: as red-word! get-facet current-msg FACE_OBJ_TYPE
			make-event current-msg 0 EVT_CLICK			;-- should be *after* get-facet call (Windows closing on click case)
			if any [
				type/symbol = check
				type/symbol = radio
			][
				current-msg/hWnd: child					;-- force child handle
				if get-logic-state current-msg [
					make-event current-msg 0 EVT_CHANGE
				]
			]
		]
		EN_CHANGE [											;-- sent also by CreateWindow
			unless any [null? current-msg no-face? hWnd][	;-- ignore CreateWindow-time events
				unless no-face? child [		  				;-- ignore CreateWindow-time events (fixes #1596)
					current-msg/hWnd: child	  				;-- force Edit handle
					make-event current-msg -1 EVT_CHANGE
					type: as red-word! get-facet current-msg FACE_OBJ_TYPE
					if type/symbol = area [
						extend-area-limit child 16
						update-scrollbars child
					]
				]
			]
			0
		]
		EN_SETFOCUS
		CBN_SETFOCUS [
			values: get-face-values hWnd
			if values <> null [
				make-at 
					child
					as red-object! values + FACE_OBJ_SELECTED
			]
			current-msg/hWnd: child
			make-event current-msg 0 EVT_FOCUS
		]
		EN_KILLFOCUS
		CBN_KILLFOCUS [
			current-msg/hWnd: child
			make-event current-msg 0 EVT_UNFOCUS
		]
		CBN_SELCHANGE [
			current-msg/hWnd: child			;-- force ListBox or Combobox handle
			type: as red-word! get-facet current-msg FACE_OBJ_TYPE
			res: either type/symbol = text-list [LB_GETCURSEL][CB_GETCURSEL]
			idx: as-integer SendMessage child res 0 0
			res: make-event current-msg idx EVT_SELECT
			get-selected current-msg idx + 1
			if res = EVT_DISPATCH [
				make-event current-msg 0 EVT_CHANGE
			]
		]
		CBN_EDITCHANGE [
			current-msg/hWnd: child			;-- force Combobox handle
			type: as red-word! get-facet current-msg FACE_OBJ_TYPE
			unless type/symbol = text-list [
				make-event current-msg -1 EVT_CHANGE
			]
		]
		STN_CLICKED [
			init-current-msg
			current-msg/hWnd: child
			make-event current-msg 0 EVT_LEFT_DOWN
		]
		default [0]
	]
	unless null? current-msg [current-msg/hWnd: saved]
]

paint-background: func [
	hWnd	[handle!]
	hDC		[handle!]
	return: [logic!]
	/local
		rect   [RECT_STRUCT value]
		hBrush [handle!]
		color  [integer!]
][
	color: to-bgr as node! GetWindowLong hWnd wc-offset + 4 FACE_OBJ_COLOR
	if color = -1 [return false]

	hBrush: CreateSolidBrush color
	GetClientRect hWnd rect
	FillRect hDC rect hBrush
	DeleteObject hBrush
	true
]

process-custom-draw: func [
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		item	[tagNMCUSTOMDRAWINFO]
		values	[red-value!]
		type	[red-word!]
		txt		[red-string!]
		font	[red-object!]
		color	[red-tuple!]
		sym		[integer!]
		old		[integer!]
		flags	[integer!]
		DC		[handle!]
		rc		[RECT_STRUCT]
][
	item:	as tagNMCUSTOMDRAWINFO lParam
	values: get-face-values item/hWndFrom
	type:	as red-word! values + FACE_OBJ_TYPE
	DC:		item/hdc
	sym: symbol/resolve type/symbol
	if any [
		sym = check
		sym = radio
		sym = button
	][
		if all [
			item/dwDrawStage = CDDS_PREPAINT
			item/uItemState <> CDIS_DISABLED
		][
			;@@ TBD draw image
			font: as red-object! values + FACE_OBJ_FONT
			if TYPE_OF(font) = TYPE_OBJECT [
				txt: as red-string! values + FACE_OBJ_TEXT
				values: object/get-values font
				color: as red-tuple! values + FONT_OBJ_COLOR
				old: SetBkMode DC 1
				if all [
					TYPE_OF(color) = TYPE_TUPLE
					color/array1 <> 0
				][
					SetTextColor DC color/array1 and 00FFFFFFh
				]
				rc: as RECT_STRUCT (as int-ptr! item) + 5
				flags: DT_VCENTER or DT_SINGLELINE
				either sym = button [
					flags: flags or DT_CENTER
				][
					rc/left: rc/left + 16
				]
				DrawText DC unicode/to-utf16 txt -1 rc flags
				SetBkMode DC old
				return CDRF_SKIPDEFAULT
			]
		]
	]
	CDRF_DODEFAULT
]

bitblt-memory-dc: func [
	hWnd	[handle!]
	alpha?	[logic!]
	/local
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		hBackDC [handle!]
		ftn		[integer!]
		bf		[tagBLENDFUNCTION]
		dc		[handle!]
][
	dc: BeginPaint hWnd paint
	hBackDC: as handle! GetWindowLong hWnd wc-offset - 4
	rect: declare RECT_STRUCT
	GetClientRect hWnd rect
	width: rect/right - rect/left
	height: rect/bottom - rect/top
	either alpha? [
		ftn: 0
		bf: as tagBLENDFUNCTION :ftn
		bf/BlendOp: as-byte 0
		bf/BlendFlags: as-byte 0
		bf/SourceConstantAlpha: as-byte 255
		bf/AlphaFormat: as-byte 1
		AlphaBlend dc 0 0 width height hBackDC 0 0 width height ftn
	][
		BitBlt dc 0 0 width height hBackDC 0 0 SRCCOPY
	]
	EndPaint hWnd paint
]

screen-to-client: func [
	hWnd	[handle!]
	x		[integer!]
	y		[integer!]
	return: [tagPOINT]
	/local
		pt	[tagPOINT]
][
	pt: declare tagPOINT
	pt/x: x
	pt/y: y
	ScreenToClient hWnd pt
	pt
]

delta-size: func [
	hWnd	[handle!]
	return: [tagPOINT]
	/local
		win		[RECT_STRUCT]
		client	[RECT_STRUCT]
		pt		[tagPOINT]
][
	client: declare RECT_STRUCT
	win:	declare RECT_STRUCT	

	GetClientRect hWnd client
	GetWindowRect hWnd win
	
	pt: screen-to-client hWnd win/left win/top
	pt/x: (win/right - win/left) - client/right
	pt/y: (win/bottom - win/top) - client/bottom
	pt
]

update-pair-facet: func [
	hWnd   [handle!]
	type   [integer!]
	lParam [integer!]
	/local
		pair [red-pair!]
][
	current-msg/hWnd: hWnd
	pair: as red-pair! get-facet current-msg type
	pair/header: TYPE_PAIR								;-- forces pair! in case user changed it
	pair/x: WIN32_LOWORD(lParam)
	pair/y: WIN32_HIWORD(lParam)
]

set-window-info: func [
	hWnd	[handle!]
	lParam	[integer!]
	return: [logic!]
	/local
		x	   [integer!]
		y	   [integer!]
		cx	   [integer!]
		cy	   [integer!]
		values	[red-value!]
		pair	[red-pair!]
		info	[tagMINMAXINFO]
		ret?	[logic!]
][
	ret?: no
	unless no-face? hWnd [
		x: 0
		y: 0
		cx: 0
		cy: 0
		window-border-info? hWnd :x :y :cx :cy
		values: get-face-values hWnd
		pair: as red-pair! values + FACE_OBJ_SIZE
		info: as tagMINMAXINFO lParam
		cx: pair/x + cx
		cy: pair/y + cy

		if pair/x > info/ptMaxSize.x [info/ptMaxSize.x: cx ret?: yes]
		if pair/y > info/ptMaxSize.y [info/ptMaxSize.y: cy ret?: yes]
		if pair/x > info/ptMaxTrackSize.x [info/ptMaxTrackSize.x: cx ret?: yes]
		if pair/y > info/ptMaxTrackSize.y [info/ptMaxTrackSize.y: cy ret?: yes]
		if pair/x < info/ptMinTrackSize.x [info/ptMinTrackSize.x: cx ret?: yes]
		if pair/y < info/ptMinTrackSize.y [info/ptMinTrackSize.y: cy ret?: yes]

		pair: as red-pair! values + FACE_OBJ_OFFSET
		if pair/x < info/ptMaxPosition.x [info/ptMaxPosition.x: pair/x + x ret?: yes]
		if pair/y < info/ptMaxPosition.y [info/ptMaxPosition.y: pair/y + y ret?: yes]
	]
	ret?
]

TimerProc: func [
	hWnd   [handle!]
	msg	   [integer!]
	id	   [int-ptr!]
	dwTime [integer!]
][
	current-msg/hWnd: hWnd
	make-event current-msg 0 EVT_TIME
]

WndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		target [int-ptr!]
		this   [this!]
		rt	   [ID2D1HwndRenderTarget]
		res	   [integer!]
		color  [integer!]
		type   [integer!]
		pos	   [integer!]
		handle [handle!]
		rc	   [RECT_STRUCT value]
		values [red-value!]
		font   [red-object!]
		parent [red-object!]
		draw   [red-block!]
		brush  [handle!]
		nmhdr  [tagNMHDR]
		gi	   [GESTUREINFO]
		pt	   [tagPOINT]
		offset [red-pair!]
		p-int  [int-ptr!]
		winpos [tagWINDOWPOS]
		w-type [red-word!]
		miniz? [logic!]
][
	type: either no-face? hWnd [panel][			;@@ remove this test, create a WndProc for panel?
		values: get-face-values hWnd
		w-type: (as red-word! values) + FACE_OBJ_TYPE
		symbol/resolve w-type/symbol
	]
	switch msg [
		WM_NCCREATE [
			p-int: as int-ptr! lParam
			store-face-to-hWnd hWnd as red-object! p-int/value
		]
		WM_WINDOWPOSCHANGED [
			if all [not win8+? type = window][
				winpos: as tagWINDOWPOS lParam
				pt: screen-to-client hWnd winpos/x winpos/y
				offset: (as red-pair! values) + FACE_OBJ_OFFSET
				pt/x: winpos/x - offset/x - pt/x
				pt/y: winpos/y - offset/y - pt/y
				update-layered-window hWnd null pt winpos -1
			]
		]
		WM_MOVE
		WM_SIZE [
			if (get-face-flags hWnd) and FACET_FLAGS_D2D <> 0 [
				target: as int-ptr! GetWindowLong hWnd wc-offset - 24
				if target <> null [
					this: as this! target/value
					rt: as ID2D1HwndRenderTarget this/vtbl
					color: WIN32_LOWORD(lParam)
					res: WIN32_HIWORD(lParam)
					rt/Resize this as tagSIZE :color
					InvalidateRect hWnd null 1
				]
			]
			if type = window [
				if null? current-msg [init-current-msg]
				if wParam <> SIZE_MINIMIZED [
					miniz?: no
					type: either msg = WM_MOVE [
						if all [						;@@ MINIMIZED window, @@ find a better way to detect it
							WIN32_HIWORD(lParam) < -9999
							WIN32_LOWORD(lParam) < -9999
						][miniz?: yes]
						FACE_OBJ_OFFSET
					][FACE_OBJ_SIZE]
					update-pair-facet hWnd type lParam
					if miniz? [return 0]
					modal-loop-type: either msg = WM_MOVE [EVT_MOVING][EVT_SIZING]
					current-msg/lParam: lParam
					make-event current-msg 0 modal-loop-type

					values: values + FACE_OBJ_STATE
					if all [
						msg = WM_SIZE
						TYPE_OF(values) = TYPE_BLOCK
						any [zero? win-state wParam = SIZE_MAXIMIZED]
					][
						make-event current-msg 0 EVT_SIZE
					]
					return 0
				]
			]
		]
		;WM_MOVING
		;WM_SIZING [
			;pair: as red-pair! stack/arguments
			;if TYPE_OF(pair) = TYPE_PAIR [
			;	either msg = WM_MOVING [
			;		pt: screen-to-client hWnd rc/left rc/top
			;		rc/left:   pair/x	 + pt/x
			;		rc/top:	   pair/y	 + pt/y
			;		rc/right:  rc/right	 + pt/x
			;		rc/bottom: rc/bottom + pt/y
			;	][
			;		pt: delta-size hWnd
			;		rc/right:  rc/left + pair/x + pt/x
			;		rc/bottom: rc/top + pair/y + pt/y
			;	]
			;]
			;return 1									;-- TRUE
		;]
		WM_ENTERSIZEMOVE [
			if type = window [win-state: 1]
		]
		WM_EXITSIZEMOVE [
			if type = window [
				win-state: 0
				type: either modal-loop-type = EVT_MOVING [EVT_MOVE][EVT_SIZE]
				make-event current-msg 0 type
				return 0
			]
		]
		WM_ACTIVATE [
			if all [type = window WIN32_LOWORD(wParam) <> 0][set-selected-focus hWnd return 0]
		]
		WM_GESTURE [
			handle: hWnd
			type: switch wParam [
				1		[zoom-distance: -1 0]
				2		[zoom-distance: -1 0]
				3		[EVT_ZOOM]
				4		[EVT_PAN]
				5		[EVT_ROTATE]
				6		[EVT_TWO_TAP]
				7		[EVT_PRESS_TAP]
				default [0]
			]
			if type <> 0 [
				gi: get-gesture-info lParam
				pos: gi/ptsLocation
				pt: screen-to-client hWnd WIN32_LOWORD(pos) WIN32_HIWORD(pos)
				handle: get-child-from-xy hWnd pt/x pt/y
				
				current-msg/hWnd: handle
				current-msg/lParam: lParam
				make-event current-msg 0 type
				;return 0
			]
		]
		WM_COMMAND [
			process-command-event hWnd msg wParam lParam
		]
		WM_NOTIFY [
			nmhdr: as tagNMHDR lParam
			switch nmhdr/code [
				TCN_SELCHANGING [return process-tab-select nmhdr/hWndFrom]
				TCN_SELCHANGE	[process-tab-change nmhdr/hWndFrom]
				NM_CUSTOMDRAW	[
					res: process-custom-draw wParam lParam
					if res <> 0 [return res]
				]
				default [0]
			]
		]
		WM_VSCROLL
		WM_HSCROLL [
			either zero? lParam [						;-- message from standard scroll bar
				current-msg/wParam: wParam
				make-event current-msg 0 EVT_SCROLL
			][											;-- message from trackbar
				if null? current-msg [init-current-msg]
				current-msg/hWnd: as handle! lParam		;-- trackbar handle
				get-slider-pos current-msg
				make-event current-msg 0 EVT_CHANGE
			]
			return 0
		]
		WM_ERASEBKGND [
			draw: (as red-block! values) + FACE_OBJ_DRAW
			if any [
				TYPE_OF(draw) = TYPE_BLOCK				;-- draw background in draw to avoid flickering
				render-base hWnd as handle! wParam
			][
				return 1
			]
			parent: as red-object! values + FACE_OBJ_PARENT
			if TYPE_OF(parent) = TYPE_OBJECT [
				w-type: as red-word! get-node-facet parent/ctx FACE_OBJ_TYPE
				if tab-panel = symbol/resolve w-type/symbol [
					GetClientRect hWnd rc
					FillRect as handle! wParam rc GetSysColorBrush COLOR_WINDOW
					return 1
				]
			]
		]
		WM_PAINT [
			draw: (as red-block! values) + FACE_OBJ_DRAW
			if TYPE_OF(draw) = TYPE_BLOCK [
				either zero? GetWindowLong hWnd wc-offset - 4 [
					do-draw hWnd null draw no yes yes yes
				][
					bitblt-memory-dc hWnd no
				]
				return 0
			]
		]
		WM_CTLCOLOREDIT
		WM_CTLCOLORSTATIC 
		WM_CTLCOLORLISTBOX [
			if null? current-msg [init-current-msg]
			current-msg/hWnd: as handle! lParam			;-- force child handle
			handle: get-widget-handle current-msg
			brush: null
			if handle <> as handle! -1 [
				font: (as red-object! get-face-values handle) + FACE_OBJ_FONT
				if TYPE_OF(font) = TYPE_OBJECT [
					color: to-bgr font/ctx FONT_OBJ_COLOR
					if color <> -1 [
						SetTextColor as handle! wParam color
						brush: either msg = WM_CTLCOLORSTATIC [
							SetBkMode as handle! wParam BK_TRANSPARENT
							GetSysColorBrush COLOR_3DFACE
						][
							GetStockObject DC_BRUSH
						]
					]
				]
				color: to-bgr as node! GetWindowLong handle wc-offset + 4 FACE_OBJ_COLOR
				if color <> -1 [
					SetBkColor as handle! wParam color
					SetDCBrushColor as handle! wParam color
					brush: GetStockObject DC_BRUSH
				]
				unless null? brush [
					return as-integer brush
				]
			]
		]
		WM_SETCURSOR [
			res: GetWindowLong as handle! wParam wc-offset - 28
			unless zero? res [
				SetCursor as handle! res
				return 1
			]
		]
		WM_ENTERMENULOOP [
			if zero? wParam [							;-- reset if entering menu bar
				menu-origin: null
				menu-ctx: null
			]
		]
		WM_MENUSELECT [
			if wParam <> FFFF0000h [
				menu-selected: WIN32_LOWORD(wParam)
				menu-handle: as handle! lParam
			]
			return 0
		]
		WM_GETMINMAXINFO [								;@@ send before WM_NCCREATE
			if all [type = window set-window-info hWnd lParam][return 0]
		]
		WM_CLOSE [
			if type = window [
				either -1 = GetWindowLong hWnd wc-offset - 4 [clean-up][
					SetFocus hWnd									;-- force focus on the closing window,
					current-msg/hWnd: hWnd							;-- prevents late unfocus event generation.
					res: make-event current-msg 0 EVT_CLOSE
					if res  = EVT_DISPATCH [return 0]				;-- continue
					;if res <= EVT_DISPATCH   [free-handles hWnd]	;-- done
					if res  = EVT_NO_DISPATCH [clean-up PostQuitMessage 0]	;-- stop
					return 0
				]
			]
		]
		default [0]
	]
	if ext-parent-proc? [call-custom-proc hWnd msg wParam lParam]

	DefWindowProc hWnd msg wParam lParam
]

process: func [
	msg		[tagMSG]
	return: [integer!]
	/local
		lParam [integer!]
		pt	   [tagPOINT]
		hWnd   [handle!]
		new	   [handle!]
		res	   [integer!]
		x	   [integer!]
		y	   [integer!]
		evt?   [logic!]
][
	switch msg/msg [
		WM_MOUSEMOVE [
			lParam: msg/lParam
			x: WIN32_LOWORD(lParam)
			y: WIN32_HIWORD(lParam)
			if any [
				x < (0 - screen-size-x) 				;@@ needs `negate` support
				y < (0 - screen-size-y)
				x > screen-size-x
				y > screen-size-y
			][
				return EVT_DISPATCH						;-- filter out buggy mouse positions (thanks MS!)
			]
			new: get-child-from-xy msg/hWnd x y
			
			evt?: all [hover-saved <> null hover-saved <> new]
			
			if evt? [
				msg/hWnd: hover-saved
				make-event msg EVT_FLAG_AWAY EVT_OVER
			]
			if any [
				evt?
				(get-face-flags new) and FACET_FLAGS_ALL_OVER <> 0
			][
				msg/hWnd: new
				make-event msg 0 EVT_OVER
			]
			hover-saved: new
			EVT_DISPATCH
		]
		WM_MOUSEWHELL [
			x: WIN32_HIWORD(msg/wParam)
			y: either x < 0 [0 - x][x]
			if y > 120 [y: 120]							;-- WHEEL_DELTA: 120
			make-event msg x / y and FFFFh EVT_WHEEL
			EVT_DISPATCH
		]
		WM_LBUTTONDOWN	[
			if GetCapture <> null [return EVT_DISPATCH]
			menu-origin: null							;-- reset if user clicks on menu bar
			menu-ctx: null
			make-event msg 0 EVT_LEFT_DOWN
		]
		WM_LBUTTONUP	[make-event msg 0 EVT_LEFT_UP]
		WM_RBUTTONDOWN	[
			if GetCapture <> null [return EVT_DISPATCH]
			lParam: msg/lParam
			pt: declare tagPOINT
			pt/x: WIN32_LOWORD(lParam)
			pt/y: WIN32_HIWORD(lParam)
			ClientToScreen msg/hWnd pt
			menu-origin: null
			menu-ctx: null
			either show-context-menu msg pt/x pt/y [
				EVT_NO_DISPATCH
			][
				make-event msg 0 EVT_RIGHT_DOWN
			]
		]
		WM_RBUTTONUP	[make-event msg 0 EVT_RIGHT_UP]
		WM_MBUTTONDOWN	[make-event msg 0 EVT_MIDDLE_DOWN]
		WM_MBUTTONUP	[make-event msg 0 EVT_MIDDLE_UP]
		WM_KEYDOWN		[
			res: make-event msg 0 EVT_KEY_DOWN
			if res <> EVT_NO_DISPATCH [
				if special-key <> -1 [
					switch special-key [
						VK_SHIFT	VK_CONTROL
						VK_LSHIFT	VK_RSHIFT
						VK_LCONTROL	VK_RCONTROL
						VK_LMENU	VK_RMENU [0]				 ;-- no KEY event
						default  [res: make-event msg 0 EVT_KEY] ;-- force a KEY event
					]
				]
			]
			res
		]
		WM_SYSKEYUP
		WM_KEYUP		[make-event msg 0 EVT_KEY_UP]
		WM_SYSKEYDOWN	[make-event msg 0 EVT_KEY_DOWN]
		WM_CHAR
		WM_DEADCHAR		[make-event msg 0 EVT_KEY]
		WM_LBUTTONDBLCLK [
			menu-origin: null							;-- reset if user clicks on menu bar
			menu-ctx: null
			make-event msg 0 EVT_LEFT_DOWN
			make-event msg 0 EVT_DBL_CLICK
			EVT_DISPATCH
		]
		;WM_DESTROY []
		default			[EVT_DISPATCH]
	]
]

do-events: func [
	no-wait? [logic!]
	return:  [logic!]
	/local
		msg	  [tagMSG]
		state [integer!]
		msg?  [logic!]
][
	msg: declare tagMSG
	msg?: no
	exit-loop: 0
	
	while [
		either no-wait? [
			0 < PeekMessage msg null 0 0 1
		][
			0 < GetMessage msg null 0 0
		]
	][
		unless msg? [msg?: yes]
		state: process msg
		if state >= EVT_DISPATCH [
			current-msg: msg
			TranslateMessage msg
			DispatchMessage msg
		]
		if no-wait? [return msg?]
	]
	exit-loop: exit-loop - 1
	if exit-loop > 0 [PostQuitMessage 0]
	msg?
]