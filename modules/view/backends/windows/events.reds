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

gui-evt: declare red-event!								;-- low-level event value slot
gui-evt/header: TYPE_EVENT

oldBaseWndProc:	 0
modal-loop-type: 0										;-- remanence of last EVT_MOVE or EVT_SIZE
zoom-distance:	 0

flags-blk: declare red-block!							;-- static block value for event/flags
flags-blk/header:	TYPE_BLOCK
flags-blk/head:		0
flags-blk/node:		alloc-cells 4

push-face: func [
	handle  [handle!]
	return: [red-object!]
	/local
		face [red-object!]
][
	face: as red-object! stack/push*
	face/header:		  GetWindowLong handle wc-offset
	face/ctx:	 as node! GetWindowLong handle wc-offset + 4
	face/class:			  GetWindowLong handle wc-offset + 8
	face/on-set: as node! GetWindowLong handle wc-offset + 12
	face
]

get-event-face: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		handle [handle!]
		face   [red-object!]
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
		gi	   [GESTUREINFO]
][
	case [
		any [
			evt/type <= EVT_OVER
			evt/type = EVT_MOVING
			evt/type = EVT_SIZING
			evt/type = EVT_MOVE
			evt/type = EVT_SIZE
		][
			msg: as tagMSG evt/msg

			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			value: msg/lParam

			offset/x: WIN32_LOWORD(value)
			offset/y: WIN32_HIWORD(value)
			as red-value! offset
		]
		any [
			evt/type = EVT_ZOOM
			evt/type = EVT_PAN
			evt/type = EVT_ROTATE
			evt/type = EVT_TWO_TAP
			evt/type = EVT_PRESS_TAP
		][
			msg: as tagMSG evt/msg
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
][
	as red-value! switch evt/type [
		EVT_KEY 
		EVT_KEY_UP [
			either evt/flags and EVT_FLAG_KEY_SPECIAL <> 0 [
				switch evt/flags and FFFFh [
					VK_PRIOR	[_page-up]
					VK_NEXT		[_page_down]
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
					default		[none-value]
				]
			][
				char: as red-char! stack/push*
				char/header: TYPE_CHAR
				char/value: evt/flags and FFFFh
				as red-value! char
			]
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
					zd: integer/to-float zoom-distance
					pct/value: 1.0 + ((integer/to-float gi/ullArgumentH) - zd / zd)				
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
			if key = VK_PROCESSKEY [return EVT_DISPATCH] ;-- IME-friendly exit
			char: to-char key
			key: either char = -1 [key or EVT_FLAG_KEY_SPECIAL][char]
			gui-evt/flags: process-special-keys key
			gui-evt/type: EVT_KEY
		]
		EVT_KEY_UP [
			key: msg/wParam and FFFFh
			char: to-char msg/wParam and FFFFh
			key: either char = -1 [key or EVT_FLAG_KEY_SPECIAL][char]
			gui-evt/flags: process-special-keys key
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
		EVT_DBL_CLICK [
			key: 0
			flags: msg/wParam
			if flags and 08h <> 0 [key: EVT_FLAG_CTRL_DOWN]			;-- MK_CONTROL
			if flags and 04h <> 0 [key: key or EVT_FLAG_SHIFT_DOWN]	;-- MK_SHIFT
			gui-evt/flags: key
		]
		EVT_CLICK [
			key: 0
			if (GetAsyncKeyState 11h) and 8000h <> 0 [key: EVT_FLAG_CTRL_DOWN]		   ;-- VK_CONTROL
			if (GetAsyncKeyState 10h) and 8000h <> 0 [key: key or EVT_FLAG_SHIFT_DOWN] ;-- VK_SHIFT
			gui-evt/flags: key
		]
		EVT_MENU [gui-evt/flags: flags and FFFFh]		;-- symbol ID of the menu
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

process-special-keys: func [
	key		[integer!]
	return: [integer!]
	/local
		state [integer!]
][
	state: 0
	if (GetAsyncKeyState 01h) and 8000h <> 0 [state: state or EVT_FLAG_DOWN]  	   ;-- VK_LBUTTON
	if (GetAsyncKeyState 02h) and 8000h <> 0 [state: state or EVT_FLAG_ALT_DOWN]   ;-- VK_RBUTTON
	if (GetAsyncKeyState 04h) and 8000h <> 0 [state: state or EVT_FLAG_MID_DOWN]   ;-- VK_MBUTTON
	if (GetAsyncKeyState 05h) and 8000h <> 0 [state: state or EVT_FLAG_AUX_DOWN]   ;-- VK_XBUTTON1
	if (GetAsyncKeyState 10h) and 8000h <> 0 [state: state or EVT_FLAG_SHIFT_DOWN] ;-- VK_SHIFT
	if (GetAsyncKeyState 11h) and 8000h <> 0 [state: state or EVT_FLAG_CTRL_DOWN]  ;-- VK_CONTROL
	
	if state <> 0 [
		if state and EVT_FLAG_CTRL_DOWN <> 0 [key: key + 64] 
		key: key or state
	]
	key
]

init-current-msg: func [
	/local
		pos [integer!]
][
	current-msg: declare TAGmsg
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
		idx	   [integer!]
		res	   [integer!]
][
	if all [zero? lParam wParam < 1000][				;-- heuristic to detect a menu selection (--)'
		unless null? menu-handle [
			do-menu hWnd
			exit
		]
	]
	switch WIN32_HIWORD(wParam) [
		BN_CLICKED [
			type: as red-word! get-facet current-msg FACE_OBJ_TYPE
			make-event current-msg 0 EVT_CLICK			;-- should be *after* get-facet call (Windows closing on click case)
			if any [
				type/symbol = check
				type/symbol = radio
			][
				current-msg/hWnd: as handle! lParam		;-- force child handle
				if get-logic-state current-msg [
					make-event current-msg 0 EVT_CHANGE
				]
			]
		]
		EN_CHANGE [										;-- sent also by CreateWindow
			unless any [
				null? current-msg 
				(GetWindowLong hWnd wc-offset) and get-type-mask <> TYPE_OBJECT ;-- ignore CreateWindow-time events
			][
				current-msg/hWnd: as handle! lParam		;-- force Edit handle
				make-event current-msg -1 EVT_CHANGE
			]
			0
		]
		EN_SETFOCUS
		CBN_SETFOCUS [
			current-msg/hWnd: as handle! lParam
			make-event current-msg 0 EVT_FOCUS
		]
		EN_KILLFOCUS
		CBN_KILLFOCUS [
			current-msg/hWnd: as handle! lParam
			make-event current-msg 0 EVT_UNFOCUS
		]
		CBN_SELCHANGE [
			current-msg/hWnd: as handle! lParam			;-- force ListBox or Combobox handle
			type: as red-word! get-facet current-msg FACE_OBJ_TYPE
			res: either type/symbol = text-list [LB_GETCURSEL][CB_GETCURSEL]
			idx: as-integer SendMessage as handle! lParam res 0 0
			res: make-event current-msg idx EVT_SELECT
			get-selected current-msg idx + 1
			if res = EVT_DISPATCH [
				make-event current-msg 0 EVT_CHANGE
			]
		]
		CBN_EDITCHANGE [
			current-msg/hWnd: as handle! lParam			;-- force Combobox handle
			type: as red-word! get-facet current-msg FACE_OBJ_TYPE
			unless type/symbol = text-list [
				make-event current-msg -1 EVT_CHANGE
			]
		]
		default [0]
	]
]

paint-background: func [
	hWnd	[handle!]
	hDC		[handle!]
	return: [logic!]
	/local
		rect   [RECT_STRUCT]
		hBrush [handle!]
		color  [integer!]
][
	color: to-bgr as node! GetWindowLong hWnd wc-offset + 4 FACE_OBJ_COLOR
	if color = -1 [return false]

	hBrush: CreateSolidBrush color
	rect: declare RECT_STRUCT
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
		DC		[handle!]
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
				if all [
					TYPE_OF(color) = TYPE_TUPLE
					color/array1 <> 0
				][
					old: SetBkMode DC 1
					SetTextColor DC color/array1 and 00FFFFFFh
					DrawText
						DC
						unicode/to-utf16 txt
						-1
						as RECT_STRUCT (as int-ptr! item) + 5
						DT_CENTER or DT_VCENTER or DT_SINGLELINE
					SetBkMode DC old
					return CDRF_SKIPDEFAULT
				]
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

WndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		res	   [integer!]
		color  [integer!]
		type   [integer!]
		pos	   [integer!]
		handle [handle!]
		font   [red-object!]
		face   [red-object!]
		draw   [red-block!]
		brush  [handle!]
		nmhdr  [tagNMHDR]
		rc	   [RECT_STRUCT]
		gi	   [GESTUREINFO]
		pt	   [tagPOINT]
		offset [red-pair!]
		pair   [red-pair!]
		p-int  [int-ptr!]
		winpos [tagWINDOWPOS]
][
	switch msg [
		WM_NCCREATE [
			p-int: as int-ptr! lParam
			store-face-to-hWnd hWnd as red-object! p-int/value
		]
		WM_WINDOWPOSCHANGED [
			unless win8+? [
				winpos: as tagWINDOWPOS lParam
				pt: screen-to-client hWnd winpos/x winpos/y
				offset: (as red-pair! get-face-values hWnd) + FACE_OBJ_OFFSET
				pt/x: winpos/x - offset/x - pt/x
				pt/y: winpos/y - offset/y - pt/y
				update-layered-window hWnd null pt winpos -1
			]
		]
		WM_MOVE
		WM_SIZE [
			if current-msg <> null [
				type: either msg = WM_MOVE [FACE_OBJ_OFFSET][FACE_OBJ_SIZE]
				current-msg/hWnd: hWnd
				pair: as red-pair! get-facet current-msg type
				pair/header: TYPE_PAIR						;-- forces pair! in case user changed it
				pair/x: WIN32_LOWORD(lParam)
				pair/y: WIN32_HIWORD(lParam)

				modal-loop-type: either msg = WM_MOVE [EVT_MOVING][EVT_SIZING]
				current-msg/lParam: lParam
				make-event current-msg 0 modal-loop-type
			]
		]
		WM_MOVING
		WM_SIZING [
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
			return 1									;-- TRUE
		]
		WM_EXITSIZEMOVE [
			type: either modal-loop-type = EVT_MOVING [EVT_MOVE][EVT_SIZE]
			make-event current-msg 0 type
			return 0
		]
		WM_ACTIVATE [
			if WIN32_LOWORD(wParam) <> 0 [set-selected-focus hWnd return 0]
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
				NM_CUSTOMDRAW	[return process-custom-draw wParam lParam]
				default [0]
			]
		]
		WM_VSCROLL
		WM_HSCROLL [
			unless zero? lParam [						;-- message from trackbar
				if null? current-msg [init-current-msg]
				current-msg/hWnd: as handle! lParam		;-- trackbar handle
				get-slider-pos current-msg
				make-event current-msg 0 EVT_CHANGE
				return 0
			]
		]
		WM_ERASEBKGND [
			draw: (as red-block! get-face-values hWnd) + FACE_OBJ_DRAW
			unless TYPE_OF(draw) = TYPE_BLOCK [			;-- draw background in draw to avoid flickering
				if paint-background hWnd as handle! wParam [return 1]
			]
		]
		WM_PAINT [
			draw: (as red-block! get-face-values hWnd) + FACE_OBJ_DRAW
			if TYPE_OF(draw) = TYPE_BLOCK [
				either zero? GetWindowLong hWnd wc-offset - 4 [
					do-draw hWnd null draw no yes yes
				][
					bitblt-memory-dc hWnd no
				]
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
		WM_CLOSE [
			handle: current-msg/hWnd
			SetFocus current-msg/hWnd					;-- force focus on the closing window,
			current-msg/hWnd: handle					;-- prevents late unfocus event generation.
			
			res: make-event current-msg 0 EVT_CLOSE
			if res  = EVT_DISPATCH [return 0]				;-- continue
			;if res <= EVT_DISPATCH   [free-handles hWnd]	;-- done
			if res  = EVT_NO_DISPATCH [clean-up PostQuitMessage 0]	;-- stop
			return 0
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
		WM_HSCROLL [
			get-slider-pos msg
			make-event current-msg 0 EVT_CHANGE
		]
		WM_KEYDOWN		[make-event msg 0 EVT_KEY_DOWN]
		WM_SYSKEYUP
		WM_KEYUP		[make-event msg 0 EVT_KEY_UP]
		WM_SYSKEYDOWN	[
			make-event msg 0 EVT_KEY_DOWN
			EVT_NO_DISPATCH
		]
		WM_LBUTTONDBLCLK [
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
		res	  [integer!]
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