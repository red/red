Red/System [
	Title:	"Windows GUI backend"
	Author: "Nenad Rakocevic, Xie Qingtian"
	File: 	%gui.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;; ===== Extra slots usage in Window structs =====
;;
;;		-60  :							<- TOP
;;		-40  : base: draw-ctx! pointer
;;		-36  : Direct2D render target
;;		-32	 : base: mouse capture count
;;			 : window: default font
;;		-28  : Cursor handle
;;		-24  : base-layered: caret's owner handle, Window: modal loop type for moving and resizing
;;		-20  : evolved-base-layered: child handle
;;		-16  : base-layered: owner handle, window: border width and height
;;		-12  : clipped? flag, caret? flag, d2d? flag, ime? flag
;;		 -8  : base: pos X/Y in pixel
;;			   window: pos X/Y in pixel
;;		 -4  : camera: camera!
;;			   group-box: frame hWnd
;;			   window destroy flag
;;		  0  : |
;;		  4  : |__ face!
;;		  8  : |
;;		  12 : |
;;		  16 : FACE_OBJ_FLAGS        <- BOTTOM

#define OFFSET_DRAW_CTX	[wc-offset - 40]

#define IS_D2D_FACE(sym) [
	any [sym = base sym = rich-text sym = window sym = panel]
]

#define AREA_BUFFER_LIMIT 32768

#include %win32.reds
#include %direct2d.reds
#include %matrix2d.reds
#include %classes.reds
#include %events.reds

#include %font.reds
#include %para.reds
#include %camera.reds
#include %base.reds
#include %menu.reds
#include %panel.reds
#include %tab-panel.reds
#include %text-list.reds
#include %button.reds
#include %calendar.reds
#either draw-engine = 'GDI+ [
	#include %draw-gdi.reds
][
	#include %draw.reds
]
#include %comdlgs.reds

exit-loop:		0
process-id:		0
border-width:	0
hScreen:		as handle! 0
hInstance:		as handle! 0
default-font:	as handle! 0
hover-saved:	as handle! 0							;-- last window under mouse cursor
prev-captured:	as handle! 0
version-info: 	declare OSVERSIONINFO
current-msg: 	as tagMSG 0
wc-extra:		80										;-- reserve 64 bytes for win32 internal usage (arbitrary)
wc-offset:		60										;-- offset to our 16+4 bytes
win11?:			no
win10+?:		no
win8+?:			no
winxp?:			no
DWM-enabled?:	no										;-- listen for composition state changes by handling the WM_DWMCOMPOSITIONCHANGED notification
win-state:		0
hIMCtx:			as handle! 0
ime-open?:		no
ime-font:		as tagLOGFONT allocate 92
base-down-hwnd: as handle! 0

dpi-factor:		as float32! 1.0
current-dpi:	as float32! 96.0
log-pixels-x:	0
log-pixels-y:	0
screen-size-x:	0
screen-size-y:	0
default-font-name: as c-string! 0

rc-cache:		declare RECT_STRUCT
kb-state: 		allocate 256							;-- holds keyboard state for keys conversion

dark-mode?:		no
pShouldAppsUseDarkMode: as int-ptr! 0

monitor!: alias struct! [
	handle	 [handle!]
	DPI		 [float32!]
	pixels-x [integer!]
]

monitors-nb: 10
monitors: as monitor! 0
monitor-tail: as monitor! 0


dpi-scale: func [
	num		[float32!]
	return: [integer!]
][
	as-integer num * dpi-factor
]

dpi-unscale: func [
	num		[float32!]
	return: [float32!]
][
	num / dpi-factor
]

clean-up: does [
	current-msg: null
]

face-set?: func [
	hWnd	[handle!]
	return: [logic!]
][
	0 <> GetWindowLong hWnd wc-offset
]

get-face-obj: func [
	hWnd	[handle!]
	return: [red-object!]
][
	if null? hWnd [return null]
	as red-object! references/get GetWindowLong hWnd wc-offset
]

get-face-values: func [
	hWnd	[handle!]
	return: [red-value!]
	/local
		face [red-object!]
		ctx	 [red-context!]
		node [node!]
		s	 [series!]
][
	face: as red-object! references/get GetWindowLong hWnd wc-offset
	node: face/ctx
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset
]

get-node-facet: func [
	node	[node!]
	facet	[integer!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		s	 [series!]
][
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset + facet
]

get-facets: func [
	msg		[tagMSG]
	return: [red-value!]
][
	get-face-values get-widget-handle msg
]

get-facet: func [
	msg		[tagMSG]
	facet	[integer!]
	return: [red-value!]
	/local
		face [red-object!]
][
	face: as red-object! references/get GetWindowLong get-widget-handle msg wc-offset
	get-node-facet face/ctx facet
]

get-widget-handle: func [
	msg		[tagMSG]
	return: [handle!]
	/local
		hWnd   [handle!]
		p	   [int-ptr!]
		id	   [integer!]
][
	hWnd: msg/hWnd

	unless face-set? hWnd [
		hWnd: GetParent hWnd							;-- for composed widgets (try 1)
		unless face-set? hWnd [
			hWnd: WindowFromPoint msg/x msg/y			;-- try 2
			id: 0
			GetWindowThreadProcessId hWnd :id
			if any [
				id <> process-id
				hWnd = GetConsoleWindow					;-- see #1290
			] [ return as handle! -1 ]
			unless face-set? hWnd [
				p: as int-ptr! GetWindowLong hWnd 0		;-- try 3
				either null? p [
					hWnd: as handle! -1					;-- not found
				][
					hWnd: as handle! p/2
					unless face-set? hWnd [hWnd: as handle! -1]	;-- not found
				]
			]
		]
	]
	hWnd
]

get-face-flags: func [
	hWnd	[handle!]
	return: [integer!]
][
	GetWindowLong hWnd wc-offset + 16
]

face-handle?: func [
	face	[red-object!]
	return: [handle!]									;-- returns NULL if no handle
	/local
		state  [red-block!]
		handle [red-handle!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		handle: as red-handle! block/rs-head state
		if TYPE_OF(handle) = TYPE_HANDLE [return as handle! handle/value]
	]
	null
]

get-face-handle: func [
	face	[red-object!]
	return: [handle!]
	/local
		state  [red-block!]
		handle [red-handle!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	assert TYPE_OF(state) = TYPE_BLOCK
	handle: as red-handle! block/rs-head state
	assert TYPE_OF(handle) = TYPE_HANDLE
	as handle! handle/value
]

get-window-pos: func [
	hWnd	[handle!]
	return:	[tagPOINT]
	/local
		pt [tagPOINT]
][
	pt: declare tagPOINT
	pt/x: 0
	pt/y: 0
	MapWindowPoints hWnd GetParent hWnd pt 1
	pt
]

get-child-from-xy: func [
	parent	[handle!]
	x		[integer!]
	y		[integer!]
	return: [handle!]
	/local
		hWnd [handle!]
][
	hWnd: ChildWindowFromPointEx parent x y CWP_SKIPINVISIBLE or CWP_SKIPTRANSPARENT
	either null? hWnd [parent][hWnd]
]

get-gesture-info: func [
	handle  [integer!]
	return: [GESTUREINFO]
	/local
		gi [GESTUREINFO]
][
	gi: declare GESTUREINFO
	gi/cbSize: size? GESTUREINFO
	#case [
		any [not legacy not find legacy 'no-touch] [
			GetGestureInfo as GESTUREINFO handle gi
		]
	]
	gi
]

get-text-size: func [
	face 	[red-object!]
	str		[red-string!]
	pt		[red-point2D!]
	/local
		values 	[red-value!]
		font	[red-object!]
		state	[red-block!]
		type	[red-word!]
		sym		[integer!]
		hFont	[handle!]
		hwnd 	[handle!]
		dc 		[handle!]
		c-str	[c-string!]
		size 	[tagSIZE value]
		rc 		[RECT_STRUCT value]
		bbox 	[RECT_STRUCT_FLOAT32 value]
][
	;-- possibly null if hwnd wasn't stored in `state` yet (upon face creation)
	;  in this case hwnd=0 is of the screen, while `para` can still be applied from the face/ctx
	hwnd: face-handle? face
	if null? hwnd [
		hwnd: GetDesktopWindow
	]

	values: object/get-values face
	dc: GetWindowDC hwnd

	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	either IS_D2D_FACE(sym) [
		GetClientRect hWnd :rc
		render-text values hwnd dc :rc str :bbox
		if pt <> null [
			pt/x: bbox/width * as float32! 0.98 / dpi-factor
			pt/y: bbox/height / dpi-factor
		]
	][	;-- native controls use GDI to draw the text, so we use GDI function to measure the text size
		font: as red-object! values + FACE_OBJ_FONT
		hFont: null
		if TYPE_OF(font) = TYPE_OBJECT [
			state: as red-block! values + FONT_OBJ_STATE
			if TYPE_OF(state) = TYPE_BLOCK [hFont: get-font-handle font 0]
			if null? hFont [hFont: make-font face font]
		]
		if null? hFont [hFont: default-font]

		SelectObject dc hFont
		c-str: unicode/to-utf16 str
		GetTextExtentPoint32 dc c-str wcslen c-str :size

		if pt <> null [
			pt/x: (as float32! size/width) / dpi-factor
			pt/y: (as float32! size/height) / dpi-factor
		]
	]

	ReleaseDC hwnd dc
]

update-scrollbars: func [
	hWnd [handle!]
	text [c-string!] ;utf16 encoded string or null
	/local
		values	[red-value!]
		str		[red-string!]
		para	[red-object!]
		dc		[handle!]
		rect	[RECT_STRUCT value]
		horz?	[logic!]
		vert?	[logic!]
		size    [integer!]
		max-n	[integer!]
		start	[c-string!]
		txt-start [c-string!]
		txt-pos   [c-string!]
		bool      [red-logic!]
		wrap?     [logic!]
		chars     [integer!]
		c1 c2 	[byte!]
		w h height width right bottom [integer!]
][
	values: get-face-values hWnd
	str:  as red-string! values + FACE_OBJ_TEXT
	para: as red-object! values + FACE_OBJ_PARA
	horz?: no
	vert?: no
	wrap?: no

	either TYPE_OF(str) = TYPE_STRING [
		GetClientRect hWnd rect
		bottom: rect/bottom
		right:  rect/right

		if text = null [ text: unicode/to-utf16 str ]

		if TYPE_OF(para) = TYPE_OBJECT [
			bool: as red-logic! (object/get-values para) + PARA_OBJ_WRAP?
			wrap?: all [TYPE_OF(bool) = TYPE_LOGIC  bool/value] ;@@ no word wrap by default?
		]

		dc: GetDC hWnd
		size: GetTabbedTextExtent dc "M^(00)" 1 0 null ;-- measure one big character
		height: WIN32_HIWORD(size)
		width: size and FFFFh

		txt-pos:   text
		txt-start: text
		h: 0
		max-n: 0

		forever [
			c1: txt-pos/1
			c2: txt-pos/2
			if c2 = null-byte [
				if any [c1 = #"^/" c1 = null-byte] [
					chars: (as integer! (txt-pos - txt-start)) / 2
					chars: either c1 = #"^/" [chars - 2][chars - 1] 	;-- -2 exclude crlf, -1 exclude null-byte
					w: width * chars
					h: h + height
					if w > right [
						either wrap? [
							rect/bottom: bottom
							rect/right: right
							DrawText dc txt-start chars rect DT_CALCRECT or DT_EXPANDTABS or DT_WORDBREAK 
							h: h - height + rect/bottom
						][
							if chars > max-n [
								max-n: chars
								start: txt-start
							]
							horz?: yes
						]
					]
					if h >= bottom [
						vert?: yes
						if wrap? [break]
					]
					if c1 = null-byte [break]			;-- no need to continue
					txt-start: txt-pos + 2
				]
			]
			txt-pos: txt-pos + 2
		]

		if all [not wrap? horz?][	;-- check again in case it's not fixed-width font
			size: GetTabbedTextExtent dc start max-n 0 null
			w: size and FFFFh
			horz?: w > right
		]

		ReleaseDC hWnd dc
		ShowScrollBar hWnd 1 vert?						;-- SB_VERT
		ShowScrollBar hWnd 0 horz?						;-- SB_HORZ
	][
		ShowScrollBar hWnd 3 no							;-- SB_BOTH
	]
]

set-hint-text: func [
	hWnd		[handle!]
	options		[red-block!]
	/local
		text	[red-string!]
][
	if TYPE_OF(options) <> TYPE_BLOCK [exit]
	text: as red-string! block/select-word options word/load "hint" no
	if TYPE_OF(text) = TYPE_STRING [
		SendMessage hWnd 1501h 0 as-integer unicode/to-utf16 text		;-- EM_SETCUEBANNER
	]
]

set-layered-option: func [
	options		[red-block!]
	win8+?		[logic!]
	return:		[integer!]
	/local
		layer?	[red-logic!]
][
	if TYPE_OF(options) <> TYPE_BLOCK [return 0]
	layer?: as red-logic! block/select-word options word/load "accelerated" no
	either all [TYPE_OF(layer?) = TYPE_LOGIC layer?/value][
		either win8+? [WS_EX_LAYERED][WS_EX_LAYERED or WS_EX_TOOLWINDOW]
	][0]
]

set-area-options: func [
	hWnd		[handle!]
	options		[red-block!]
	/local
		tabsize	[red-integer!]
		size	[integer!]
][
	size: 16	;-- according to MSDN, 16 dialog units equals to 4 character average width, and this value is device independent.
	SendMessage hWnd CBh 1 as-integer :size

	if TYPE_OF(options) <> TYPE_BLOCK [exit]
	tabsize: as red-integer! block/select-word options word/load "tabs" no
	if TYPE_OF(tabsize) = TYPE_INTEGER [
		size: tabsize/value * 4
		SendMessage hWnd CBh 1 as-integer :size
	]
]

get-scrollbar-ratio: func [
	int		 [red-integer!]
	return:  [float!]
	/local
		fl	  [red-float!]
		ratio [float!]
][
	switch TYPE_OF(int) [
		TYPE_INTEGER [
			ratio: as-float int/value
		]
		TYPE_FLOAT
		TYPE_PERCENT [
			fl: as red-float! int
			ratio: fl/value
		]
		default [return -1.0]
	]
	if ratio < 0.0 [ratio: 0.0]
	if ratio > 1.0 [ratio: 1.0]
	ratio
]

update-scroller: func [
	scroller [red-object!]
	flag	 [integer!]
	/local
		parent		[red-object!]
		vertical?	[red-logic!]
		int			[red-integer!]
		bool		[red-logic!]
		values		[red-value!]
		hWnd		[handle!]
		nTrackPos	[integer!]
		nPos		[integer!]
		nPage		[integer!]
		nMax		[integer!]
		nMin		[integer!]
		fMask		[integer!]
		cbSize		[integer!]
][
	values: object/get-values scroller
	parent: as red-object! values + SCROLLER_OBJ_PARENT
	vertical?: as red-logic! values + SCROLLER_OBJ_VERTICAL?
	int: as red-integer! block/rs-head as red-block! (object/get-values parent) + FACE_OBJ_STATE
	hWnd: as handle! int/value

	if flag = SCROLLER_OBJ_VISIBLE? [
		bool: as red-logic! values + SCROLLER_OBJ_VISIBLE?
		ShowScrollBar hWnd as-integer vertical?/value bool/value
		exit
	]

	fMask: switch flag [
		SCROLLER_OBJ_POS [
			int: as red-integer! values + SCROLLER_OBJ_POS
			nPos: int/value SIF_POS
		]
		SCROLLER_OBJ_PAGE
		SCROLLER_OBJ_MAX [
			int: as red-integer! values + SCROLLER_OBJ_PAGE
			nPage: int/value
			int: as red-integer! values + SCROLLER_OBJ_MAX
			nMin: 1
			nMax: int/value
		 	SIF_RANGE or SIF_PAGE
		]
		default [0]
	]

	if fMask <> 0 [
		fMask: fMask or SIF_DISABLENOSCROLL
		cbSize: size? tagSCROLLINFO
		SetScrollInfo hWnd as-integer vertical?/value as tagSCROLLINFO :cbSize yes
	]
]

update-caret: func [
	hWnd	[handle!]
	values	[red-value!]
	/local
		size  [red-pair!]
		owner [handle!]
		pt	  [red-point2D!]
		x y	  [integer!]
][
	size: as red-pair! values + FACE_OBJ_SIZE
	GET_PAIR_XY_INT(size x y)
	owner: as handle! GetWindowLong hWnd wc-offset - 24
	CreateCaret owner null x y
	change-offset hWnd as red-point2D! values + FACE_OBJ_OFFSET caret
]

update-selection: func [
	hWnd	[handle!]
	values	[red-value!]
	/local
		sel	  [red-pair!]
		begin [integer!]
		end   [integer!]
][
	begin: 0
	end:   0
	SendMessage hWnd EM_GETSEL as-integer :begin as-integer :end
	sel: as red-pair! values + FACE_OBJ_SELECTED
	either begin = end [
		sel/header: TYPE_NONE
	][
		sel/header: TYPE_PAIR
		assert begin <= end
		adjust-selection values :begin :end -1
		sel/x: begin + 1								;-- one-based positionq
		sel/y: end										;-- points past the last selected, so no need + 1
	]
]

update-rich-text: func [
	state	[red-block!]
	handles [red-block!]
	return: [logic!]
	/local
		redraw [red-logic!]
][
	if TYPE_OF(handles) = TYPE_BLOCK [
		redraw: as red-logic! (block/rs-tail handles) - 1
		redraw/value: true
	]
	TYPE_OF(state) <> TYPE_BLOCK
]

to-bgr: func [
	node	[node!]
	pos		[integer!]
	return: [integer!]									;-- 00bbggrr format or -1 if not found
	/local
		color [red-tuple!]
][
	color: as red-tuple! get-node-facet node pos
	either TYPE_OF(color) = TYPE_TUPLE [
		color/array1 and 00FFFFFFh
	][
		-1
	]
]

free-dc: func [
	handle	[int-ptr!]
	/local
		dc	[integer!]
][
	#either draw-engine = 'GDI+ [
	if zero? (WS_EX_LAYERED and GetWindowLong handle GWL_EXSTYLE) [
		dc: GetWindowLong handle wc-offset - 4
		if dc <> 0 [DeleteDC as handle! dc]			;-- delete cached dc
	]
	dc: GetWindowLong handle wc-offset - 36
	if dc <> 0 [
		either (GetWindowLong handle wc-offset - 12) and BASE_FACE_IME <> 0 [
			d2d-release-target as render-target! dc
		][											;-- caret
			DestroyCaret
		]
	]][
	;-- Direct2D backend
	dc: GetWindowLong handle wc-offset - 36
	if dc <> 0 [d2d-release-target as render-target! dc]
	if (GetWindowLong handle wc-offset - 12) and BASE_FACE_IME <> 0 [
		DestroyCaret
	]]
]

free-faces: func [
	face		[red-object!]
	top-level?	[logic!]
	/local
		values	[red-value!]
		type	[red-word!]
		obj		[red-object!]
		tail	[red-object!]
		pane	[red-block!]
		state	[red-value!]
		rate	[red-value!]
		sym		[integer!]
		dc		[integer!]
		flags	[integer!]
		cam		[camera!]
		handle	[handle!]
		hFont	[handle!]
][
	handle: face-handle? face
	#if debug? = yes [if null? handle [probe "VIEW: WARNING: free null window handle!"]]

	if null? handle [exit]

	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	if sym = window [	;-- hide it first for better User experience
		SetWindowPos handle null 0 0 0 0 SWP_HIDEWINDOW or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER
	]

	rate: values + FACE_OBJ_RATE
	if TYPE_OF(rate) <> TYPE_NONE [change-rate handle none-value]

	obj: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj FONT_OBJ_PARENT]
	
	obj: as red-object! values + FACE_OBJ_PARA
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj PARA_OBJ_PARENT]

	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		obj: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [obj < tail][
			free-faces obj no
			obj: obj + 1
		]
	]

	case [
		sym = group-box [
			;-- destroy the extra frame window
			DestroyWindow as handle! GetWindowLong handle wc-offset - 4 as-integer handle
		]
		sym = panel [DestroyWindow handle]
		sym = camera [stop-camera handle]
		true [
			0
			;; handle user-provided classes too
		]
	]
	if sym = window [
		hFont: as handle! GetWindowLong handle wc-offset - 32	;-- default font
		if hFont <> null [DeleteObject hFont]

		state: values + FACE_OBJ_SELECTED
		state/header: TYPE_NONE
		SetWindowLong handle wc-offset - 4 -1
	]

	references/remove GetWindowLong handle wc-offset
	SetWindowLong handle wc-offset 0
	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE

	if top-level? [PostMessage handle WM_CLOSE 0 0]
]

set-defaults: func [
	hWnd		[handle!]
	/local
		hFont	[handle!]
		font	[tagLOGFONT]
		ft		[tagLOGFONT value]
		name	[c-string!]
		res		[integer!]
		len		[integer!]
		metrics [tagNONCLIENTMETRICS value]
][
	if default-font-name <> null [free as byte-ptr! default-font-name default-font-name: null]
	if hWnd <> null [
		hFont: as handle! GetWindowLong hWnd wc-offset - 32
		if hFont <> null [DeleteObject hFont]
	]
	res: -1
	metrics/cbSize: size? tagNONCLIENTMETRICS
	#case [
		any [not legacy not find legacy 'no-multi-monitor][	;-- DPI-aware (Win10+)
			res: as-integer SystemParametersInfoForDPI 29h size? tagNONCLIENTMETRICS as int-ptr! :metrics 0 log-pixels-y
		]
		true [												;-- fixed DPI across all monitors (Win8-)
			res: as-integer SystemParametersInfo 29h size? tagNONCLIENTMETRICS as int-ptr! :metrics 0
		]
	]
	font: as tagLOGFONT :metrics/lfMessageFont
	
	if res >= 0 [
		name: as-c-string :font/lfFaceName
		len: utf16-length? name
		res: len + 1 * 2
		default-font-name: as c-string! allocate res
		copy-memory as byte-ptr! default-font-name as byte-ptr! name res
		string/load-at
			name
			len
			#get system/view/fonts/system
			UTF-16LE
		integer/make-at 
			#get system/view/fonts/size
			0 - (font/lfHeight * 72 / log-pixels-y)

		default-font: CreateFontIndirect font
	]

	if null? default-font [default-font: GetStockObject DEFAULT_GUI_FONT]
	if hWnd <> null [SetWindowLong hWnd wc-offset - 32 as-integer default-font]
]

enable-visual-styles: func [
	return:   [logic!]
	/local
		icc   [integer!]
		size  [integer!]
		ctrls [tagINITCOMMONCONTROLSEX]
][
	size: size? tagINITCOMMONCONTROLSEX
	icc: ICC_STANDARD_CLASSES			;-- user32.dll controls
	  or ICC_PROGRESS_CLASS				;-- progress
	  or ICC_TAB_CLASSES				;-- tabs
	  or ICC_LISTVIEW_CLASSES			;-- table headers
	  or ICC_UPDOWN_CLASS				;-- spinboxes
	  or ICC_BAR_CLASSES				;-- trackbar
	  or ICC_DATE_CLASSES				;-- date/time picker
	ctrls: as tagINITCOMMONCONTROLSEX :size
	InitCommonControlsEx ctrls
]

update-dpi-factor: func [
	hWnd	[handle!]
	/local
		win	screen [red-object!]
		fl [red-float!]
][
	win: as red-object! get-face-obj hWnd
	assert TYPE_OF(win) = TYPE_OBJECT
	screen: as red-object! (object/get-values win) + FACE_OBJ_PARENT		;-- screen: win/parent
	if TYPE_OF(screen) = TYPE_OBJECT [
		fl: as red-float! (object/get-values screen) + FACE_OBJ_DATA		;-- fl: screen/data
		if TYPE_OF(fl) = TYPE_FLOAT [
			dpi-factor: as float32! fl/value
			current-dpi: dpi-factor * as float32! 96.0
		]
	]
]

get-dpi: func [
	/local
		monitor [handle!]
		pt		[tagPOINT value]
][
	#case [
		any [not legacy not find legacy 'no-multi-monitor][
			GetCursorPos pt
			monitor: MonitorFromPoint pt 2
			GetDpiForMonitor monitor 0 :log-pixels-x :log-pixels-y
		]
		true [
			log-pixels-x: GetDeviceCaps hScreen 88		;-- LOGPIXELSX
			log-pixels-y: GetDeviceCaps hScreen 90		;-- LOGPIXELSY
		]
	]
	current-dpi: as float32! log-pixels-x
	dpi-factor: current-dpi / as float32! 96.0
]

get-metrics: func [
	/local
		svm	[red-hash!]
		blk [red-block!]
][
	copy-cell 
		as red-value! integer/push log-pixels-x
		#get system/view/metrics/dpi
	
	svm: as red-hash! #get system/view/metrics/misc
	
	map/put svm as red-value! _scroller as red-value! pair/push
		GetSystemMetrics 2								;-- SM_CXVSCROLL
		GetSystemMetrics 20								;-- SM_CYVSCROLL
		no
		
	map/put 
		as red-hash! #get system/view/metrics/colors
		as red-value! _text as red-value! tuple/push
			3 (GetSysColor COLOR_WINDOWTEXT) 0 0
		no
		
	map/put 
		as red-hash! #get system/view/metrics/colors
		as red-value! _window as red-value! tuple/push
			3 (GetSysColor COLOR_WINDOW) 0 0
		no
		
	map/put 
		as red-hash! #get system/view/metrics/colors
		as red-value! _panel as red-value! tuple/push
			3 (GetSysColor COLOR_3DFACE) 0 0
		no
]

on-gc-mark: does [
	collector/keep :flags-blk/node
]

init: func [
	/local
		ver   [red-tuple!]
		int   [red-integer!]
		dll	  [handle!]
		;SetPreferredAppMode [SetPreferredAppMode!]
][
	process-id:		GetCurrentProcessId
	hScreen:		GetDC null
	hInstance:		GetModuleHandle 0

	version-info/dwOSVersionInfoSize: size? OSVERSIONINFO
	GetVersionEx version-info

	unless all [
		version-info/dwMajorVersion = 5
		version-info/dwMinorVersion < 1
	][
		enable-visual-styles							;-- not called for Win2000
	]

	DWM-enabled?: dwm-composition-enabled?

	win10+?: version-info/dwMajorVersion >= 10
	win8+?: any [
		version-info/dwMajorVersion >= 10				;-- Win 10+
		all [											;-- Win 8, Win 8.1
			version-info/dwMajorVersion >= 6
			version-info/dwMinorVersion >= 2
		]
	]
	winxp?: version-info/dwMajorVersion < 6

	ver: as red-tuple! #get system/view/platform/version

	ver/header: TYPE_TUPLE or (3 << 19)
	ver/array1: version-info/dwMajorVersion
		or (version-info/dwMinorVersion << 8)
		and 0000FFFFh

	get-dpi
	unless winxp? [DX-init]
	set-defaults null

	register-classes hInstance

	int: as red-integer! #get system/view/platform/build
	int/header: TYPE_INTEGER
	int/value:  version-info/dwBuildNumber
	win11?: version-info/dwBuildNumber >= 22000

	int: as red-integer! #get system/view/platform/product
	int/header: TYPE_INTEGER
	int/value:  as-integer version-info/wProductType

	monitors: as monitor! allocate monitors-nb * size? monitor!
	monitor-tail: monitors
	
	get-metrics

	if win10+? [
		dll: LoadLibraryA "uxtheme.dll"
		if dll <> null [
			pShouldAppsUseDarkMode: GetProcAddress dll as c-string! 132
			dark-mode?: use-dark-mode?
		]
	]

	collector/register as int-ptr! :on-gc-mark
	time-meter/start _time_meter	
	font-ext-type: externals/register "font" as-integer :delete-font
]

use-dark-mode?: func [
	return: [logic!]
	/local
		hc	[tagHIGHCONTRASTW value]
		ShouldAppsUseDarkMode [ShouldAppsUseDarkMode!]
][
	either all [win10+? pShouldAppsUseDarkMode <> null][
		ShouldAppsUseDarkMode: as ShouldAppsUseDarkMode! pShouldAppsUseDarkMode
		hc/cbSize: size? tagHIGHCONTRASTW
		SystemParametersInfo 42h size? tagHIGHCONTRASTW as int-ptr! :hc 0
		all [
			hc/dwFlags and 1 = 0	; Not High Contrast scheme
			ShouldAppsUseDarkMode
		]
	][false]
]

support-dark-mode?: func [
	return: [logic!]
	/local
		hc	[tagHIGHCONTRASTW value]
][
	either win10+? [
		hc/cbSize: size? tagHIGHCONTRASTW
		SystemParametersInfo 42h size? tagHIGHCONTRASTW as int-ptr! :hc 0
		hc/dwFlags and 1 = 0	; Not High Contrast scheme
	][false]
]

set-dark-mode: func [
	hWnd		[handle!]
	dark?		[logic!]
	top-level?	[logic!]
	/local
		flag	[integer!]
][
	if top-level? [
		flag: either dark? [1][0]
		;-- set DWMWA_USE_IMMERSIVE_DARK_MODE. needed for titlebar
		DwmSetWindowAttribute hWnd 20 :flag size? flag
	]
	either dark? [
		SetWindowTheme hWnd #u16 "DarkMode_Explorer" null
	][
		SetWindowTheme hWnd #u16 "Explorer" null
	]
]

cleanup: does [
	unregister-classes hInstance
	DX-release-dev
	DX-cleanup
]


window-border-info?: func [
	handle	[handle!]
	x		[int-ptr!]
	y		[int-ptr!]
	width	[int-ptr!]
	height	[int-ptr!]
	/local
		win		[RECT_STRUCT value]
		client	[RECT_STRUCT value]
		pt		[tagPOINT]
][
	GetClientRect handle client
	if zero? client/right [exit]

	GetWindowRect handle win
	if x <> null [
		pt: screen-to-client handle win/left win/top
		x/value: pt/x
		y/value: pt/y
	]
	if width <> null [
		width/value: (win/right - win/left) - client/right
		height/value: (win/bottom - win/top) - client/bottom
	]
]

transparent-win?: func [
	color	[red-tuple!]
	return: [logic!]
][
	either any [
		TYPE_OF(color) <> TYPE_TUPLE
		any [
			TUPLE_SIZE?(color) = 3 
			color/array1 and FF000000h = 0
		]
	][false][true]
]

init-window: func [										;-- post-creation settings
	handle  [handle!]
][
	SetWindowLong handle wc-offset - 4 0
	SetWindowLong handle wc-offset - 16 0
	SetWindowLong handle wc-offset - 24 0
	SetWindowLong handle wc-offset - 32 0
	SetWindowLong handle wc-offset - 36 0
]

get-selected-handle: func [
	hWnd	[handle!]
	return: [handle!]
	/local
		face   [red-object!]
		values [red-value!]
		handle [handle!]
][
	values: get-face-values hWnd
	handle: null
	if values <> null [
		face: as red-object! values + FACE_OBJ_SELECTED
		if TYPE_OF(face) = TYPE_OBJECT [
			handle: face-handle? face
		]
	]
	handle
]

set-selected-focus: func [
	hWnd [handle!]
][
	hWnd: get-selected-handle hWnd
	unless null? hWnd [SetFocus hWnd]
]

set-logic-state: func [
	hWnd   [handle!]
	state  [red-logic!]
	check? [logic!]
	/local
		values [red-block!]
		flags  [integer!]
		type   [integer!]
		value  [integer!]
		tri?   [logic!]
][	
	if check? [
		values: as red-block! object/get-values get-face-obj hWnd
		flags: get-flags as red-block! values + FACE_OBJ_FLAGS
		tri?: flags and FACET_FLAGS_TRISTATE <> 0
	]
	
	type: TYPE_OF(state)
	value: either all [check? tri? type = TYPE_NONE][BST_INDETERMINATE][
		as integer! switch type [
			TYPE_NONE  [false]
			TYPE_LOGIC [state/value]					;-- returns 0/1, matches the state flag
			default	   [true]
		]
	]

	SendMessage hWnd BM_SETCHECK value 0
]

get-logic-state: func [
	msg [tagMSG]
	/local
		bool  [red-logic!]
		state [integer!]
][
	bool: as red-logic! get-facet msg FACE_OBJ_DATA
	state: as-integer SendMessage msg/hWnd BM_GETCHECK 0 0

	either state = BST_INDETERMINATE [
		bool/header: TYPE_NONE
	][
		bool/header: TYPE_LOGIC
		bool/value: state = BST_CHECKED
	]
]

get-selected: func [
	msg [tagMSG]
	idx [integer!]
	/local
		int [red-integer!]
][
	int: as red-integer! get-facet msg FACE_OBJ_SELECTED
	int/header: TYPE_INTEGER
	int/value: idx
]

get-text-alt: func [
	face [red-object!]
	idx	 [integer!]
	/local
		str	 [red-string!]
		out	 [c-string!]
		hWnd [handle!]
		size [integer!]
][
	hWnd: face-handle? face
	if null? hWnd [exit]
	
	size: as-integer either idx = -1 [
		SendMessage hWnd WM_GETTEXTLENGTH idx 0
	][
		SendMessage hWnd CB_GETLBTEXTLEN idx 0
	]
	if size >= 0 [
		str: as red-string! (object/get-values face) + FACE_OBJ_TEXT
		if TYPE_OF(str) <> TYPE_STRING [
			string/make-at as red-value! str size UCS-2
		]
		if size = 0 [
			string/rs-reset str
			exit
		]
		out: unicode/get-cache str size + 1 * 4			;-- account for surrogate pairs and terminal NUL

		either idx = -1 [
			SendMessage hWnd WM_GETTEXT size + 1 as-integer out  ;-- account for NUL
		][
			SendMessage hWnd CB_GETLBTEXT idx as-integer out
		]
		unicode/load-utf16 null size str yes
		ownership/bind as red-value! str face _text
	]
]

get-text: func [
	msg	[tagMSG]
	idx	[integer!]
	/local
		size [integer!]
		str	 [red-string!]
		face [red-object!]
		out	 [c-string!]
][
	size: as-integer either idx = -1 [
		SendMessage msg/hWnd WM_GETTEXTLENGTH idx 0
	][
		SendMessage msg/hWnd CB_GETLBTEXTLEN idx 0
	]
	if size >= 0 [
		str: as red-string! get-facet msg FACE_OBJ_TEXT
		if TYPE_OF(str) <> TYPE_STRING [
			string/make-at as red-value! str size UCS-2
		]
		if size = 0 [
			string/rs-reset str
			exit
		]
		out: unicode/get-cache str size + 1 * 4			;-- account for surrogate pairs and terminal NUL

		either idx = -1 [
			SendMessage msg/hWnd WM_GETTEXT size + 1 as-integer out  ;-- account for NUL
		][
			SendMessage msg/hWnd CB_GETLBTEXT idx as-integer out
		]
		unicode/load-utf16 null size str yes
		
		face: push-face msg/hWnd
		if TYPE_OF(face) = TYPE_OBJECT [
			ownership/bind as red-value! str face _text
		]
		stack/pop 1
	]
]

get-position-value: func [
	pos		[red-float!]
	maximum [float32!]
	return: [integer!]
	/local
		f	[float32!]
][
	f: as float32! 0.0
	if any [
		TYPE_OF(pos) = TYPE_FLOAT
		TYPE_OF(pos) = TYPE_PERCENT
	][
		f: maximum * as float32! pos/value
	]
	as-integer f
]

get-ratio: func [face [red-object!] return: [red-float!]][
	as red-float! object/rs-select face as red-value! _ratio
]

set-scroller-metrics: func [
	msg	[tagMSG]
	si	[tagSCROLLINFO]
	/local
		values	 [red-value!]
		pos		 [red-float!]
		sel		 [red-float!]
		range	 [float!]
		dividend [integer!]
][
	values: get-facets msg
	pos: as red-float! values + FACE_OBJ_DATA
	sel: as red-float! values + FACE_OBJ_SELECTED

	if TYPE_OF(pos) <> TYPE_FLOAT [pos/header: TYPE_FLOAT]
	range: as-float si/nMax - si/nMin
	dividend: si/nPos - si/nMin
	pos/value: (as-float dividend) / range
	
	if TYPE_OF(sel) <> TYPE_PERCENT [sel/header: TYPE_PERCENT]
	sel/value: (as-float si/nPage) / range
]

get-slider-pos: func [
	msg	[tagMSG]
	/local
		values	[red-value!]
		size	[red-pair!]
		pos		[red-float!]
		amount	[integer!]
		divisor [integer!]
][
	values: get-facets msg
	size:	as red-pair!	values + FACE_OBJ_SIZE
	pos:	as red-float!	values + FACE_OBJ_DATA

	if all [
		TYPE_OF(pos) <> TYPE_FLOAT
		TYPE_OF(pos) <> TYPE_PERCENT
	][
		percent/rs-make-at as red-value! pos 0.0
	]
	amount: as-integer SendMessage msg/hWnd TBM_GETPOS 0 0
	divisor: size/x
	if size/y > size/x [divisor: size/y amount: divisor - amount]
	pos/value: (as-float amount) / as-float divisor
]

get-screen-size: func [
	id		[integer!]									;@@ Not used yet
	return: [red-pair!]
][
	screen-size-x: GetDeviceCaps hScreen HORZRES
	screen-size-y: GetDeviceCaps hScreen VERTRES
	pair/push screen-size-x * 96 / log-pixels-x screen-size-y * 96 / log-pixels-x
]

dwm-composition-enabled?: func [
	return:		[logic!]
	/local
		enabled [integer!]
		dll		[handle!]
		fun		[DwmIsCompositionEnabled!]
][
	enabled: 0
	dll: LoadLibraryA "dwmapi.dll"
	if dll = null [return false]
	fun: as DwmIsCompositionEnabled! GetProcAddress dll "DwmIsCompositionEnabled"
	fun :enabled
	FreeLibrary dll
	either zero? enabled [false][true]
]

store-face-to-hWnd: func [
	hWnd	[handle!]
	face	[red-object!]
][
	if face-set? hWnd [exit]
	SetWindowLong hWnd wc-offset references/store as red-value! face
]

evolve-base-face: func [
	hWnd	[handle!]
	return: [handle!]
	/local
		values	[red-value!]
		type	[red-word!]
		handle	[handle!]
		size	[red-pair!]
		visible [red-logic!]
		pos		[integer!]
][
	values: get-face-values hWnd
	type: as red-word! values + FACE_OBJ_TYPE
	if all [
		base = symbol/resolve type/symbol
		(WS_EX_LAYERED and GetWindowLong hWnd GWL_EXSTYLE) <> 0
	][
		handle: as handle! GetWindowLong hWnd wc-offset - 20
		if null? handle [
			size: as red-pair! values + FACE_OBJ_SIZE
			visible: as red-logic! values + FACE_OBJ_VISIBLE?
			pos: GetWindowLong hWnd wc-offset - 8
			handle: CreateWindowEx
				WS_EX_LAYERED
				#u16 "RedBaseInternal"
				null
				WS_POPUP
				WIN32_LOWORD(pos)
				WIN32_HIWORD(pos)
				size/x
				size/y
				hWnd
				null
				hInstance
				null

			SetLayeredWindowAttributes handle 1 0 2
			SetWindowLong handle wc-offset - 20 0
			if visible/value [ShowWindow handle SW_SHOWNA]
			SetWindowLong hWnd wc-offset - 20 as-integer handle
		]
		hWnd: handle
	]
	hWnd
]

parse-common-opts: func [
	hWnd	[handle!]
	options [red-block!]
	/local
		word	[red-word!]
		w		[red-word!]
		img		[red-image!]
		len		[integer!]
		sym		[integer!]
		bitmap	[integer!]
		lock	[com-ptr! value]
][
	SetWindowLong hWnd wc-offset - 28 0
	if TYPE_OF(options) = TYPE_BLOCK [
		word: as red-word! block/rs-head options
		len: block/rs-length? options
		if len % 2 <> 0 [exit]
		
		while [len > 0][
			if TYPE_OF(word) = TYPE_SET_WORD [
				sym: symbol/resolve word/symbol
				case [
					sym = _cursor [
						w: word + 1
						either TYPE_OF(w) = TYPE_IMAGE [
							img: as red-image! w
							bitmap: OS-image/to-gpbitmap img :lock
							GdipCreateHICONFromBitmap bitmap :sym
							OS-image/release-gpbitmap bitmap :lock
							SetWindowLong hWnd wc-offset - 28 sym
						][
							if TYPE_OF(w) = TYPE_WORD [
								sym: symbol/resolve w/symbol
								sym: case [
									sym = _I-beam		[IDC_IBEAM]
									sym = _hand			[32649]			;-- IDC_HAND
									sym = _cross		[32515]
									sym = _resize-ns	[32645]
									any [
										sym = _resize-ew
										sym = _resize-we
									]					[32644]
									true				[IDC_ARROW]
								]
								sym: as-integer LoadCursor null sym
								SetWindowLong hWnd wc-offset - 28 sym
							]
						]
					]
					true [0]
				]
			]
			word: word + 2
			len: len - 2
		]
	]
]

OS-get-current-screen: func [
	return: [red-handle!]
	/local
		hMonitor [handle!]
		pt		 [tagPOINT value]
][
	GetCursorPos pt
	hMonitor: MonitorFromPoint pt 2
	handle/make-at stack/arguments as-integer hMonitor handle/CLASS_MONITOR
]

monitor-enum-proc: func [
	[stdcall]
	hMonitor[integer!]
	hDC		[handle!]
	lpRECT	[int-ptr!]									;-- RECT_STRUCT
	spec	[red-block!]
	return: [logic!]
	/local
		blk	  [red-block!]
		s	  [series!]
		DPI	  [float32!]
		rec	  [RECT_STRUCT]
		pt	  [tagPOINT value]
		log-x [integer!]
		log-y [integer!]
][
	log-x: log-y: 0
	#case [
		any [not legacy not find legacy 'no-multi-monitor][
			GetDpiForMonitor as handle! hMonitor 0 :log-x :log-y
		]
		true [
			log-x: GetDeviceCaps hScreen 88				;-- LOGPIXELSX
			log-y: GetDeviceCaps hScreen 90				;-- LOGPIXELSY
		]
	]
	DPI: (as float32! log-x) / as float32! 96.0
	
	blk: block/make-at as red-block! ALLOC_TAIL(spec) 4
	s: GET_BUFFER(blk)
	rec: as RECT_STRUCT lpRECT
	
	pair/make-at   alloc-tail s rec/left rec/top
	pair/make-at   alloc-tail s rec/right - rec/left rec/bottom - rec/top
	float/make-at  alloc-tail s as-float DPI
	handle/make-at alloc-tail s hMonitor handle/CLASS_MONITOR
	
	monitor-tail/handle:   as handle! hMonitor
	monitor-tail/DPI:	   DPI
	monitor-tail/pixels-x: log-x
	monitor-tail: monitor-tail + 1
	assert (as-integer monitor-tail - monitors) >> 2 < monitors-nb
	
	true												;-- continue enumeration
]

OS-fetch-all-screens: func [
	return: [red-block!]
	/local blk [red-block!]
][
	blk: block/push-only* 2
	EnumDisplayMonitors null null :monitor-enum-proc blk
	blk
]

OS-redraw: func [hWnd [integer!]][
	InvalidateRect as handle! hWnd null 0
	UpdateWindow as handle! hWnd
]

OS-refresh-window: func [hWnd [integer!]][UpdateWindow as handle! hWnd]

OS-show-window: func [
	hWnd [integer!]
	/local
		face	[red-object!]
][
	if prev-captured <> null [ReleaseCapture]
	check-base-capture
	ShowWindow as handle! hWnd SW_SHOWDEFAULT
	UpdateWindow as handle! hWnd
	unless win8+? [
		update-layered-window as handle! hWnd null null null -1
	]

	SetForegroundWindow as handle! hWnd
	set-selected-focus as handle! hWnd
]

OS-make-view: func [
	face	[red-object!]
	parent	[integer!]
	return: [integer!]
	/local
		values	  [red-value!]
		type	  [red-word!]
		str		  [red-string!]
		offset	  [red-point2D!]
		size	  [red-pair!]
		data	  [red-block!]
		menu	  [red-block!]
		show?	  [red-logic!]
		enabled?  [red-logic!]
		selected  [red-integer!]
		para	  [red-object!]
		rate	  [red-value!]
		options	  [red-block!]
		fl		  [red-float!]
		rc		  [RECT_STRUCT value]
		si		  [tagSCROLLINFO]
		pt		  [red-point2D!]
		handle	  [handle!]
		hWnd	  [handle!]
		p		  [ext-class!]
		flags n	  [integer!]
		ws-flags  [integer!]
		bits	  [integer!]
		sym		  [integer!]
		state	  [integer!]
		class	  [c-string!]
		caption   [c-string!]
		value	  [integer!]
		id		  [integer!]
		vertical? [logic!]
		panel?	  [logic!]
		alpha?	  [logic!]
		para?	  [logic!]
		off-x	  [integer!]
		off-y	  [integer!]
		ratio	  [float!]
		sx sy f32 [float32!]
		ex-flags  [integer!]
][
	stack/mark-native words/_body

	values: object/get-values face

	type:	  as red-word!		values + FACE_OBJ_TYPE
	str:	  as red-string!	values + FACE_OBJ_TEXT
	offset:   as red-point2D!	values + FACE_OBJ_OFFSET
	size:	  as red-pair!		values + FACE_OBJ_SIZE
	show?:	  as red-logic!		values + FACE_OBJ_VISIBLE?
	enabled?: as red-logic!		values + FACE_OBJ_ENABLED?
	data:	  as red-block!		values + FACE_OBJ_DATA
	menu:	  as red-block!		values + FACE_OBJ_MENU
	selected: as red-integer!	values + FACE_OBJ_SELECTED
	para:	  as red-object!	values + FACE_OBJ_PARA
	rate:	  					values + FACE_OBJ_RATE
	options:  as red-block!		values + FACE_OBJ_OPTIONS
	
	bits: 	  get-flags as red-block! values + FACE_OBJ_FLAGS

	if TYPE_OF(offset) = TYPE_PAIR [as-point2D as red-pair! offset]
	either TYPE_OF(size) = TYPE_PAIR [
		sx: as float32! size/x
		sy: as float32! size/y
		ex-flags: PAIR_SIZE_FACET
	][
		ex-flags: 0
		pt: as red-point2D! size
		sx: pt/x
		sy: pt/y
	]

	flags: 	  WS_CHILD or WS_CLIPSIBLINGS
	ws-flags: 0
	id:		  0
	sym: 	  symbol/resolve type/symbol
	panel?:	  no
	alpha?:   no
	para?:	  TYPE_OF(para) = TYPE_OBJECT

	if all [show?/value sym <> window][flags: flags or WS_VISIBLE]
	if para? [flags: flags or get-para-flags sym para]
	
	if all [TYPE_OF(enabled?) = TYPE_LOGIC not enabled?/value][
		flags: flags or WS_DISABLED
	]

	if bits and FACET_FLAGS_SCROLLABLE <> 0 [
		flags: flags or WS_HSCROLL or WS_VSCROLL
	]

	case [
		sym = button [
			class: #u16 "RedButton"
			flags: flags or 00002000h		;-- BS_MULTILINE
			;flags: flags or BS_PUSHBUTTON
		]
		sym = toggle [
			class: #u16 "RedButton"
			flags: flags or BS_AUTOCHECKBOX or BS_PUSHLIKE
		]
		sym = check [
			class: #u16 "RedButton"
			state: either bits and FACET_FLAGS_TRISTATE <> 0 [BS_AUTO3STATE][BS_AUTOCHECKBOX]
			flags: flags or WS_TABSTOP or state
		]
		sym = radio [
			class: #u16 "RedButton"
			flags: flags or WS_TABSTOP or BS_RADIOBUTTON
		]
		any [
			sym = panel 
			sym = group-box
		][
			class: #u16 "RedPanel"
			either all [
				parent <> 0
				(WS_EX_LAYERED and GetWindowLong as handle! parent GWL_EXSTYLE) <> 0
			][
				alpha?: yes
				ws-flags: WS_EX_LAYERED
			][
				init-panel values as handle! parent
				panel?: yes
				GET_PAIR_XY(size sx sy)		;-- size adjusted
			]
		]
		sym = tab-panel [
			class: #u16 "RedTabPanel"
		]
		sym = field [
			class: #u16 "RedField"
			flags: flags or WS_TABSTOP or ES_AUTOHSCROLL
			if bits and FACET_FLAGS_PASSWORD <> 0 [flags: flags or ES_PASSWORD]
			unless para? [flags: flags or ES_LEFT or ES_NOHIDESEL]
			if bits and FACET_FLAGS_NO_BORDER = 0 [ws-flags: ws-flags or WS_EX_CLIENTEDGE]
		]
		sym = area [
			class: #u16 "RedArea"
			unless para? [flags: flags or ES_LEFT or ES_AUTOHSCROLL or WS_HSCROLL or ES_NOHIDESEL]
			flags: flags or ES_MULTILINE or ES_AUTOVSCROLL or WS_VSCROLL or WS_TABSTOP
			if bits and FACET_FLAGS_NO_BORDER = 0 [ws-flags: ws-flags or WS_EX_CLIENTEDGE]
		]
		sym = text [
			class: #u16 "RedFace"
			flags: flags or SS_SIMPLE
		]
		sym = text-list [
			class: #u16 "RedListBox"
			flags: flags or LBS_NOTIFY or WS_HSCROLL or WS_VSCROLL or LBS_NOINTEGRALHEIGHT
			if bits and FACET_FLAGS_NO_BORDER = 0 [ws-flags: ws-flags or WS_EX_CLIENTEDGE]
		]
		sym = drop-down [
			class: #u16 "RedCombo"
			flags: flags or CBS_DROPDOWN or CBS_HASSTRINGS or CBS_AUTOHSCROLL ;or WS_OVERLAPPED
		]
		sym = drop-list [
			class: #u16 "RedCombo"
			flags: flags or CBS_DROPDOWNLIST or CBS_HASSTRINGS ;or WS_OVERLAPPED
		]
		sym = progress [
			class: #u16 "RedProgress"
			if sy > sx [flags: flags or PBS_VERTICAL]
		]
		sym = slider [
			class: #u16 "RedSlider"
			if sy > sx [
				flags: flags or TBS_VERT or TBS_DOWNISLEFT
			]
		]
		sym = scroller [
			class: #u16 "RedScroller"
			if sy > sx [flags: flags or SBS_VERT]
		]
		any [sym = base sym = rich-text][
			class: #u16 "RedBase"
			either all [
				parent <> 0
				(WS_EX_LAYERED and GetWindowLong as handle! parent GWL_EXSTYLE) <> 0
			][
				alpha?: yes
				ws-flags: WS_EX_LAYERED
			][
				alpha?: transparent-base?
					as red-tuple! values + FACE_OBJ_COLOR
					as red-image! values + FACE_OBJ_IMAGE
				
				either alpha? [
					either win8+? [ws-flags: WS_EX_LAYERED][
						ws-flags: WS_EX_LAYERED or WS_EX_TOOLWINDOW
						flags: WS_POPUP
					]
				][
					ws-flags: set-layered-option options win8+?
				]
			]
		]
		sym = camera [
			class: #u16 "RedCamera"
		]
		sym = calendar [
			class: #u16 "RedCalendar"
			flags: flags or MCS_NOSELCHANGEONNAV or MCS_NOTODAY or MCS_SHORTDAYSOFWEEK
		]
		sym = window [
			class: #u16 "RedWindow"
			flags: WS_CAPTION or WS_CLIPCHILDREN
			;ws-flags: WS_EX_COMPOSITED
			if bits and FACET_FLAGS_NO_MIN  = 0 [flags: flags or WS_MINIMIZEBOX]
			if bits and FACET_FLAGS_NO_MAX  = 0 [flags: flags or WS_MAXIMIZEBOX]
			if bits and FACET_FLAGS_NO_BTNS = 0 [flags: flags or WS_SYSMENU]
			if bits and FACET_FLAGS_POPUP  <> 0 [ws-flags: ws-flags or WS_EX_TOOLWINDOW]
			either bits and FACET_FLAGS_RESIZE = 0 [
				flags: flags and (not WS_MAXIMIZEBOX)
			][
				flags: flags or WS_THICKFRAME
			]

			if menu-bar? menu window [
				flags: flags or WS_SYSMENU
				id: as-integer build-menu menu CreateMenu
			]

			if bits and FACET_FLAGS_NO_TITLE  <> 0 [flags: WS_POPUP or WS_BORDER]
			if bits and FACET_FLAGS_NO_BORDER <> 0 [
				flags: WS_POPUP
				;; NB: use layered window only with no-border flag
				;; layered window doesn't work with border somehow
				alpha?: transparent-win? as red-tuple! values + FACE_OBJ_COLOR
				n: either alpha? [WS_EX_LAYERED][set-layered-option options win8+?]
				ws-flags: ws-flags or n
			]
			get-dpi

			if sx < as float32! 0.0 [sx: as float32! 200.0]
			if sy < as float32! 0.0 [sy: as float32! 200.0]
			rc/left: 0
			rc/top: 0
			rc/right:  dpi-scale sx
			rc/bottom: dpi-scale sy
			AdjustWindowRectEx rc flags menu-bar? menu window ws-flags
			rc/right: rc/right - rc/left
			rc/bottom: rc/bottom - rc/top
			if bits and FACET_FLAGS_MODAL <> 0 [
				parent: as-integer GetActiveWindow
			]
		]
		true [											;-- search in user-defined classes
			p: find-class type
			either null? p [
				fire [TO_ERROR(script face-type) type]
			][
				class: p/class
				ws-flags: ws-flags or p/ex-styles
				flags: flags or p/styles
				id: p/base-id
			]
		]
	]

	caption: either all [TYPE_OF(str) = TYPE_STRING sym <> area][
		unicode/to-utf16 str
	][
		null
	]

	unless any [alpha? not winxp?][
		ws-flags: ws-flags or WS_EX_COMPOSITED		;-- this flag conflicts with DWM
	]

	if all [
		parent <> 0
		not alpha?
	][
		parent: as-integer evolve-base-face as handle! parent
	]

	off-x:	dpi-scale offset/x
	off-y:	dpi-scale offset/y
	if sym <> window [
		rc/right:	dpi-scale sx
		rc/bottom:	dpi-scale sy
	]

	handle: CreateWindowEx
		ws-flags
		class
		caption
		flags
		off-x
		off-y
		rc/right
		rc/bottom
		as int-ptr! parent
		as handle! id
		hInstance
		as int-ptr! face

	if null? handle [print-line "*** View Error: CreateWindowEx failed!"]

	SetWindowLong handle wc-offset - 12 ex-flags
	if any [win8+? not alpha?][BringWindowToTop handle]
	set-font handle face values

	;-- store the face value in the extra space of the window struct
	assert TYPE_OF(face) = TYPE_OBJECT					;-- detect corruptions caused by CreateWindow unwanted events
	store-face-to-hWnd handle face
	parse-common-opts handle options

	;-- extra initialization
	case [
		sym = camera	[init-camera handle data selected get-ratio face]
		sym = text-list [init-text-list handle data selected]
		sym = base		[init-base-face handle parent values alpha? ex-flags]
		sym = panel		[if alpha? [init-base-face handle parent values alpha? ex-flags]]
		sym = tab-panel [set-tabs handle values]
		any [
			sym = button
			sym = toggle
		][
			init-button handle values
			if sym = toggle [set-logic-state handle as red-logic! data no]
		]
		sym = group-box [
			flags: flags or WS_GROUP or BS_GROUPBOX
			hWnd: CreateWindowEx
				ws-flags
				#u16 "BUTTON"
				caption
				flags
				0
				0
				rc/right
				rc/bottom
				handle
				null
				hInstance
				null

			SendMessage hWnd WM_SETFONT as-integer default-font 1
			SetWindowLong handle wc-offset - 4 as-integer hWnd
		]
		panel? [
			adjust-parent handle as handle! parent offset/x offset/y
			SetWindowLong handle wc-offset - 4 0
			SetWindowLong handle wc-offset - 36 0
		]
		any [
			sym = slider
			sym = progress
		][
			vertical?: sy > sx
			f32: either vertical? [sy][sx]
			off-x: get-position-value as red-float! data f32
			value: as-integer f32
			either sym = slider [
				if vertical? [off-x: (as-integer sy) - off-x]
				SendMessage handle TBM_SETRANGE 1 value << 16
				SendMessage handle TBM_SETPOS 1 off-x
			][
				SendMessage handle PBM_SETRANGE 0 value << 16
				SendMessage handle PBM_SETPOS off-x 0
			]
		]
		sym = scroller [
			ratio: get-scrollbar-ratio selected
			if ratio < 0.0 [
				ratio: 0.1						;-- default to 10%
				fl: as red-float! selected
				fl/header: TYPE_PERCENT
				fl/value: ratio
			]
			si: declare tagSCROLLINFO
			si/cbSize: size? tagSCROLLINFO
			si/fMask: SIF_PAGE or SIF_POS or SIF_RANGE
			si/nMin: 0
			si/nMax: 100
			si/nPage: float/round-to-int ratio * 100.0
			si/nPos: 0
			SetScrollInfo handle SB_CTL si true
			fl: as red-float! data
			fl/header: TYPE_FLOAT
			fl/value:  0.0
		]
		any [
			sym = toggle
			sym = check
			sym = radio
		][
			set-logic-state handle as red-logic! data sym = check
		]
		any [
			sym = drop-down
			sym = drop-list
		][
			init-drop-list handle data caption selected sym = drop-list
		]
		sym = field [
			set-hint-text handle options
			if TYPE_OF(selected) <> TYPE_NONE [change-selection handle selected values]
		]
		sym = area [
			set-area-options handle options
			change-text handle values sym
			if TYPE_OF(selected) <> TYPE_NONE [change-selection handle selected values]
		]
		sym = rich-text [
			ex-flags: ex-flags or (BASE_FACE_D2D or BASE_FACE_IME)
			init-base-face handle parent values alpha? ex-flags
		]
		sym = calendar [
			init-calendar handle as red-value! data
			update-calendar-color handle as red-value! values + FACE_OBJ_COLOR
		]
		sym = window [
			init-window handle
			if alpha? [init-base-face handle parent values alpha? ex-flags]
			#if sub-system = 'gui [
				with clipboard [
					if null? main-hWnd [main-hWnd: handle]
				]
			]
			SetWindowLong
				handle
				wc-offset - 8
				WIN32_MAKE_LPARAM((off-x - rc/left) (off-y - rc/top))
		]
		true [0]
	]
	if TYPE_OF(rate) <> TYPE_NONE [change-rate handle rate]

	SetWindowLong handle wc-offset + 16 get-flags as red-block! values + FACE_OBJ_FLAGS
	stack/unwind
	as-integer handle
]

change-size: func [
	hWnd [handle!]
	vals [red-value!]
	type [integer!]
	/local
		size	[red-pair!]
		cx		[integer!]
		cy		[integer!]
		max		[integer!]
		msg		[integer!]
		layer?	[logic!]
		pos		[red-point2D!]
		sz-x	[integer!]
		sz-y	[integer!]
		sx sy	[float32!]
		pt		[red-point2D!]
		flags	[integer!]
][
	size: as red-pair! vals + FACE_OBJ_SIZE
	flags: GetWindowLong hWnd wc-offset - 12 
	either TYPE_OF(size) = TYPE_PAIR [
		sx: as float32! size/x
		sy: as float32! size/y
		flags: flags or PAIR_SIZE_FACET
	][
		pt: as red-point2D! size
		sx: pt/x
		sy: pt/y
		flags: flags and (not PAIR_SIZE_FACET)
	]
	SetWindowLong hWnd wc-offset - 12 flags

	cx: 0
	cy: 0
	if type = window [window-border-info? hWnd null null :cx :cy]

	layer?: all [
		not win8+?
		type = base
		0 <> (WS_EX_LAYERED and GetWindowLong hWnd GWL_EXSTYLE)
	]

	if layer? [
		pos: as red-point2D! vals + FACE_OBJ_OFFSET
		process-layered-region hWnd size pos as red-block! vals + FACE_OBJ_PANE pos null layer?
	]

	sz-x: dpi-scale sx
	sz-y: dpi-scale sy
	SetWindowPos 
		hWnd
		as handle! 0
		0 0
		sz-x + cx sz-y + cy
		SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE

	if layer? [
		hWnd: as handle! GetWindowLong hWnd wc-offset - 20
		if hWnd <> null [change-size hWnd vals -1]
	]
	case [
		any [type = slider type = progress][
			max: as-integer either sx > sy [sx][sy]
			msg: either type = slider [TBM_SETRANGEMAX][max: max << 16 PBM_SETRANGE]
			SendMessage hWnd msg 0 max					;-- do not force a redraw
			change-data hWnd vals
		]
		type = scroller  [
			;; TBD
			0
		]
		type = group-box [
			hWnd: as handle! GetWindowLong hWnd wc-offset - 4	;-- change frame's size too
			SetWindowPos 
					hWnd
					as handle! 0
					0 0
					sz-x + cx sz-y + cy
					SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE
		]
		type = area		 [update-scrollbars hWnd null]
		type = tab-panel [update-tab-contents hWnd FACE_OBJ_SIZE]
		type = text		 [InvalidateRect hWnd null 1]	;-- issue #4388
		type = camera	 [update-camera hWnd sz-x + cx sz-y + cy]
		true	  		 [0]
	]
]

set-ime-pos: func [
	hWnd	[handle!]
	pos-x	[integer!]
	pos-y	[integer!]
	/local
		left	[integer!]
		top		[integer!]
		right	[integer!]
		bottom	[integer!]
		y		[integer!]
		x		[integer!]
		dwStyle	[integer!]
][
	dwStyle: 2			;-- CFS_POINT
	x: pos-x
	y: pos-y
	ImmSetCompositionWindow hIMCtx as tagCOMPOSITIONFORM :dwStyle
]

change-offset: func [
	hWnd [handle!]
	pos  [red-point2D!]
	type [integer!]
	/local
		owner	[handle!]
		child	[handle!]
		size	[red-pair!]
		flags	[integer!]
		param	[integer!]
		_y		[integer!]
		_x		[integer!]
		pad		[integer!]
		header	[integer!]
		pt		[red-pair!]
		offset	[tagPOINT]
		values	[red-value!]
		layer?	[logic!]
		pos-x	[integer!]
		pos-y	[integer!]
][
	flags: SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
	header: 0
	pt: as red-pair! :header
	layer?: (GetWindowLong hWnd GWL_EXSTYLE) and WS_EX_LAYERED > 0

	if TYPE_OF(pos) = TYPE_PAIR [as-point2D as red-pair! pos]

	pos-x: dpi-scale pos/x
	pos-y: dpi-scale pos/y
	if all [					;-- caret widget
		layer?
		type = base
		(BASE_FACE_CARET and GetWindowLong hWnd wc-offset - 12) <> 0
	][
		SetCaretPos pos-x pos-y
		set-ime-pos hWnd pos-x pos-y
	]

	if all [not win8+? type = base][
		values: get-face-values hWnd
		size: as red-pair! values + FACE_OBJ_SIZE
		process-layered-region hWnd size pos as red-block! values + FACE_OBJ_PANE pos null layer?
		param: GetWindowLong hWnd wc-offset - 8
		either layer? [
			owner: as handle! GetWindowLong hWnd wc-offset - 16
			child: as handle! GetWindowLong hWnd wc-offset - 20

			pt/x: pos-x
			pt/y: pos-y
			ClientToScreen owner (as tagPOINT pt) + 1
			offset: as tagPOINT pt
			offset/x: pt/x - WIN32_LOWORD(param)
			offset/y: pt/y - WIN32_HIWORD(param)
			pos-x: pt/x
			pos-y: pt/y
			update-layered-window hWnd null offset null -1

			if child <> null [
				SetWindowPos
					child
					as handle! 0
					pos-x pos-y
					0 0
					flags
			]
		][
			offset: as tagPOINT pt
			offset/x: pos-x - WIN32_LOWORD(param)
			offset/y: pos-y - WIN32_HIWORD(param)
			update-layered-window hWnd null offset null -1
		]
		SetWindowLong hWnd wc-offset - 8 WIN32_MAKE_LPARAM(pos-x pos-y)
	]
	SetWindowPos 
		hWnd
		as handle! 0
		pos-x pos-y
		0 0
		flags
	if type = tab-panel [update-tab-contents hWnd FACE_OBJ_OFFSET]
]

extend-area-limit: func [
	hWnd  [handle!]
	extra [integer!]
	/local
		limit [integer!]
		old	  [integer!]
][
	limit: as-integer SendMessage hWnd EM_GETLIMITTEXT 0 0
	old:   as-integer SendMessage hWnd WM_GETTEXTLENGTH 0 0
	
	if extra + old > limit [
		SendMessage hWnd EM_SETLIMITTEXT old + extra + AREA_BUFFER_LIMIT 0
	]
]

adjust-selection: func [
	values	[red-value!]
	bgn		[int-ptr!]
	end		[int-ptr!]
	inc		[integer!]									;-- +1 to increase, -1 to decrease
	/local
		quote	[integer!]
		nl		[integer!]
		unit	[integer!]
		unit-b	[integer!]
		cp		[integer!]
		size	[integer!]
		str		[red-string!]
		s		[series!]
		head	[byte-ptr!]
		tail	[byte-ptr!]
		p		[byte-ptr!]
		p-bgn	[byte-ptr!]
		p-end	[byte-ptr!]
][
	assert bgn/value <= end/value

	str: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(str) <> TYPE_STRING [exit]
	s: GET_BUFFER(str)
	unit: GET_UNIT(s)
	unit-b: log-b unit
	head: (as byte-ptr! s/offset) + (str/head << unit-b)
	tail: as byte-ptr! s/tail

	either inc > 0 [
		p-bgn: head + (bgn/1 << unit-b)
		p-end: head + (end/1 << unit-b)
		quote: 0  nl: 0
		if p-bgn < head [p-bgn: head]
		if p-end > tail [p-end: tail]
		string/sniff-chars head  p-bgn unit :quote :nl
		bgn/1: bgn/1 + nl
		string/sniff-chars p-bgn p-end unit :quote :nl
		end/1: end/1 + nl
	][
		p: head
		while [p < tail] [
			cp: string/get-char p unit
			if cp = as-integer #"^/" [
				size: (as-integer p - head) >> unit-b
				case [
					size >= end/1	[break]
					size >= bgn/1	[end/1: end/1 - 1]
					true	[bgn/1: bgn/1 - 1  end/1: end/1 - 1]
				]
			]
			p: p + unit
		]
	]
]

select-text: func [
	hWnd   [handle!]
	values [red-value!]
	/local
		sel		[red-pair!]
		begin	[integer!]
		end		[integer!]
][
	sel: as red-pair! values + FACE_OBJ_SELECTED
	either TYPE_OF(sel) = TYPE_PAIR [
		either sel/x <= sel/y [
			begin: sel/x - 1
			end: sel/y									;-- should point past the last selected char
		][
			begin: sel/y - 1
			end: sel/x
		]
		adjust-selection values :begin :end 1
	][
		begin: 0
		end:   0
	]
	SendMessage hWnd EM_SETSEL begin end
]

change-text: func [
	hWnd	[handle!]
	values	[red-value!]
	type	[integer!]
	/local
		text [c-string!]
		str  [red-string!]
		len  [integer!]
		n	 [integer!]
][
	if any [
		type = base
		all [
			type = window
			(WS_EX_LAYERED and GetWindowLong hWnd GWL_EXSTYLE) <> 0
		]
	][
		update-base hWnd null null values
		exit
	]
	if type = rich-text [
		InvalidateRect hWnd null 0
		exit
	]

	str: as red-string! values + FACE_OBJ_TEXT
	text: null
	switch TYPE_OF(str) [
		TYPE_STRING [
			text: unicode/to-utf16 str
			len: string/rs-length? str
		]
		TYPE_NONE	[
			text: #u16 "^@"
			len: 1
		]
		default		[0]									;@@ Auto-convert?
	]
	unless null? text [
		if type = group-box [
			hWnd: as handle! GetWindowLong hWnd wc-offset - 4
		]
		if type = area [
			extend-area-limit hWnd len
			update-scrollbars hWnd text
		]
		SetWindowText hWnd text
		if type = area [
			;-- too many `lf` convert to `crlf` in the edit control
			len: as-integer SendMessage hWnd EM_GETLIMITTEXT 0 0
			n: as-integer SendMessage hWnd WM_GETTEXTLENGTH 0 0
			if n >= len [
				extend-area-limit hWnd 16
				SetWindowText hWnd text
			]
		]
	]
]

change-enabled: func [
	hWnd	[handle!]
	values	[red-value!]
	type	[integer!]
	/local
		bool [red-logic!]
][
	bool: as red-logic! values + FACE_OBJ_ENABLED?
	if all [
		type = base
		(BASE_FACE_CARET and GetWindowLong hWnd wc-offset - 12) <> 0
	][
		change-visible hWnd values bool/value base
	]
	EnableWindow hWnd bool/value
]

change-visible: func [
	hWnd	[handle!]
	values	[red-value!]
	show?	[logic!]
	type	[integer!]
	/local
		value [integer!]
][
	if all [
		type = base
		(BASE_FACE_CARET and GetWindowLong hWnd wc-offset - 12) <> 0
	][
		either show? [update-caret hWnd values][DestroyCaret]
	]
	value: either show? [either type = base [SW_SHOWNA][SW_SHOW]][SW_HIDE]
	ShowWindow hWnd value
	unless win8+? [update-layered-window hWnd null null null -1]

	if type = group-box [
		hWnd: as handle! GetWindowLong hWnd wc-offset - 4
		ShowWindow hWnd value
	]
	if type = tab-panel [update-tab-contents hWnd FACE_OBJ_VISIBLE?]
]

change-image: func [
	hWnd	[handle!]
	values	[red-value!]
	type	[integer!]
	/local
		img [red-image!]
][
	case [
		type = base [update-base hWnd null null values]
		any [type = button type = toggle][init-button hWnd values]
		type = camera [
			img: as red-image! values + FACE_OBJ_IMAGE
			if TYPE_OF(img) = TYPE_NONE [
				camera-wait-image img
			]
		]
		true [0]
	]
]

change-selection: func [
	hWnd   [handle!]
	int	   [red-integer!]								;-- can be also none! | object! | percent!
	values [red-value!]
	/local
		type [red-word!]
		flt	 [float!]
		si	 [tagSCROLLINFO value]
		sym	 [integer!]
][
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	case [
		sym = scroller [
			flt: get-scrollbar-ratio int
			if flt < 0.0 [exit]
			si/cbSize: size? tagSCROLLINFO
			si/fMask: SIF_PAGE or SIF_RANGE
			GetScrollInfo hWnd SB_CTL :si
			si/nPage: float/round-to-int flt * as-float si/nMax - si/nMin
			SetScrollInfo hWnd SB_CTL :si true
		]
		sym = camera [
			either TYPE_OF(int) = TYPE_NONE [
				stop-camera hWnd 
			][
				if select-camera hWnd int/value - 1 [
					toggle-preview hWnd true
				]
			]
		]
		sym = text-list [
			SendMessage hWnd LB_SETCURSEL int/value - 1 0
		]
		any [sym = drop-list sym = drop-down][
			SendMessage hWnd CB_SETCURSEL int/value - 1 0
		]
		any [sym = field sym = area][
			select-text hWnd values
		]
		sym = tab-panel [
			select-tab hWnd int/value - 1				;@@ requires range checking
		]
		sym = window [
			switch TYPE_OF(int) [
				TYPE_OBJECT [set-selected-focus hWnd]
				TYPE_NONE	[SetFocus hWnd]
				default [0]
			]
		]
		true [0]										;-- default, do nothing
	]
]

change-data: func [
	hWnd   [handle!]
	values [red-value!]
	/local
		data 	[red-value!]
		word 	[red-word!]
		f		[red-float!]
		str		[red-string!]
		size	[red-pair!]
		bool	[red-logic!]
		range	[integer!]
		flt		[float!]
		caption [c-string!]
		type	[integer!]
		si	    [tagSCROLLINFO value]
][
	data: as red-value! values + FACE_OBJ_DATA
	word: as red-word! values + FACE_OBJ_TYPE
	type: word/symbol
	
	case [
		all [
			any [type = slider type = progress]
			any [TYPE_OF(data) = TYPE_PERCENT TYPE_OF(data) = TYPE_FLOAT]
		][
			f: as red-float! data
			size: as red-pair! values + FACE_OBJ_SIZE
			flt: f/value
			range: either size/y > size/x [size/y][size/x]
			flt: flt * as-float range
			either type = slider [
				if size/y > size/x [flt: 1.0 - flt]
				SendMessage hWnd TBM_SETPOS 1 as-integer flt
			][
				SendMessage hWnd PBM_SETPOS as-integer flt 0
			]
		]
		all [type = scroller TYPE_OF(data) = TYPE_FLOAT][
			f: as red-float! data
			flt: f/value
			if flt < 0.0 [flt: 0.0]
			if flt > 1.0 [flt: 1.0]
			si/cbSize: size? tagSCROLLINFO
			si/fMask: SIF_POS or SIF_RANGE
			GetScrollInfo hWnd SB_CTL :si
			range: si/nMax - si/nMin
			si/nPos: si/nMin + as-integer (flt * as-float range)
			SetScrollInfo hWnd SB_CTL :si true
		]
		any [
			type = check
			type = toggle
		][
			set-logic-state hWnd as red-logic! data type = check
		]
		type = radio [
			set-logic-state hWnd as red-logic! data no
			bool: as red-logic! data
			unless bool/value [
				SendMessage GetParent hWnd WM_COMMAND BN_UNPUSHED << 16 as-integer hWnd
			]
		]
		type = tab-panel [
			set-tabs hWnd get-face-values hWnd
		]
		all [type = calendar TYPE_OF(data) = TYPE_DATE][
			change-calendar hWnd as red-date! data
		]
		type = text-list [
			if TYPE_OF(data) = TYPE_BLOCK [
				init-text-list 
					hWnd
					as red-block! data
					as red-integer! values + FACE_OBJ_SELECTED
			]
		]
		any [type = drop-list type = drop-down][
			str: as red-string! values + FACE_OBJ_TEXT
			caption: either TYPE_OF(str) = TYPE_STRING [
				unicode/to-utf16 str
			][
				null
			]
			init-drop-list 
				hWnd
				as red-block! data
				caption
				as red-integer! values + FACE_OBJ_SELECTED
				type = drop-list
		]
		type = rich-text [
			InvalidateRect hWnd null 0
		]
		true [0]										;-- default, do nothing
	]
]

change-rate: func [
	hWnd [handle!]
	rate [red-value!]
	/local
		int [red-integer!]
		tm  [red-time!]
][
	switch TYPE_OF(rate) [
		TYPE_INTEGER [
			int: as red-integer! rate
			if int/value <= 0 [fire [TO_ERROR(script invalid-facet-type) rate]]
			SetTimer hWnd 1 1000 / int/value :TimerProc
		]
		TYPE_TIME [
			tm: as red-time! rate
			if tm/time <= 0.0 [fire [TO_ERROR(script invalid-facet-type) rate]]
			SetTimer hWnd 1 as-integer tm/time * 1000.0 :TimerProc
		]
		TYPE_NONE [KillTimer hWnd 1]
		default	  [fire [TO_ERROR(script invalid-facet-type) rate]]
	]
]

change-faces-parent: func [
	pane   [red-block!]
	parent [red-object!]
	new	   [red-value!]
	index  [integer!]
	part   [integer!]
	/local
		face [red-object!]
		tail [red-object!]
][
	assert TYPE_OF(pane) = TYPE_BLOCK
	face: as red-object! either null? new [block/rs-abs-at pane index][new]
	tail: face + part
	assert tail <= as red-object! block/rs-tail pane
	
	while [face < tail][
		if TYPE_OF(face) = TYPE_OBJECT [change-parent face parent]
		face: face + 1
	]
]

change-parent: func [
	face   [red-object!]
	parent [red-object!]
	/local
		hWnd		[handle!]
		handle		[handle!]
		bool		[red-logic!]
		type		[red-word!]
		values		[red-value!]
		offset		[red-point2D!]
		pt			[tagPOINT value]
		x			[integer!]
		y			[integer!]
		sym			[integer!]
		pos			[integer!]
		tab-panel?	[logic!]
][
	hWnd: get-face-handle face
	values: get-node-facet face/ctx 0
	bool: as red-logic! values + FACE_OBJ_VISIBLE?
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	tab-panel?: no
	if parent <> null [
		assert TYPE_OF(parent) = TYPE_OBJECT
		type: as red-word! get-node-facet parent/ctx FACE_OBJ_TYPE
		tab-panel?: tab-panel = symbol/resolve type/symbol
	]
	unless tab-panel? [bool/value: parent <> null]

	either null? parent [
		change-visible hWnd values no sym
		SetParent hWnd null
	][
		if tab-panel? [exit]
		handle: get-face-handle parent
		either all [
			not win8+?
			base = sym
			layered-win? hWnd
		][
			SetWindowLong hWnd wc-offset - 16 as-integer handle
			pos: GetWindowLong hWnd wc-offset - 8
			x: WIN32_LOWORD(pos)
			y: WIN32_HIWORD(pos)
			offset: as red-point2D! values + FACE_OBJ_OFFSET
			pt/x: dpi-scale offset/x
			pt/y: dpi-scale offset/y
			position-base hWnd handle :pt
			SetWindowPos hWnd null pt/x pt/y 0 0 SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
			pt/x: pt/x - x
			pt/y: pt/y - y
			update-layered-window hWnd null :pt null -1
			exit
		][
			SetParent hWnd handle
		]
	]
	OS-show-window as-integer hWnd
]

update-z-order: func [
	pane [red-block!]
	hdwp [handle!]
	/local
		face [red-object!]
		tail [red-object!]
		type [red-word!]
		blk	 [red-block!]
		hWnd [handle!]
		s	 [series!]
		nb	 [integer!]
		sub? [logic!]
][
	if TYPE_OF(pane) <> TYPE_BLOCK [exit]
	s: GET_BUFFER(pane)
	
	face: as red-object! s/offset + pane/head
	tail: as red-object! s/tail
	nb: (as-integer tail - face) >> 4
	
	sub?: either null? hdwp [
		hdwp: BeginDeferWindowPos nb
		no
	][
		yes
	]

	while [face < tail][
		if TYPE_OF(face) = TYPE_OBJECT [
			hWnd: face-handle? face
			unless null? hWnd [
				hdwp: DeferWindowPos
					hdwp
					hWnd
					as handle! 0							;-- HWND_TOP
					0 0
					0 0
					SWP_NOSIZE or SWP_NOMOVE or SWP_NOACTIVATE
				
				type: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
				
				if tab-panel = symbol/resolve type/symbol [
					;-- ensures that panels are above the tab-panel
					blk: as red-block! get-node-facet face/ctx FACE_OBJ_PANE
					if TYPE_OF(blk) = TYPE_BLOCK [update-z-order blk hdwp]
				]
			]
		]
		face: face + 1
	]
	unless sub? [EndDeferWindowPos hdwp]
]

unlink-sub-obj: func [
	face  [red-object!]
	obj   [red-object!]
	field [integer!]
	/local
		values [red-value!]
		parent [red-block!]
		res	   [red-value!]
][
	values: object/get-values obj
	parent: as red-block! values + field
	
	if TYPE_OF(parent) = TYPE_BLOCK [
		res: block/find parent as red-value! face null no no yes no null null no no no no
		if TYPE_OF(res) <> TYPE_NONE [_series/remove as red-series! res null null]
		if all [
			field = FONT_OBJ_PARENT
			block/rs-tail? parent
		][
			free-font obj
		]
	]
]

OS-update-view: func [
	face [red-object!]
	/local
		ctx		[red-context!]
		values	[red-value!]
		state	[red-block!]
		menu	[red-block!]
		word	[red-word!]
		int		[red-integer!]
		int2	[red-integer!]
		bool	[red-logic!]
		color	[red-tuple!]
		s		[series!]
		hWnd	[handle!]
		flags	[integer!]
		type	[integer!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	values: s/offset

	state: as red-block! values + FACE_OBJ_STATE
	word: as red-word! values + FACE_OBJ_TYPE
	type: symbol/resolve word/symbol

	if all [
		type = rich-text
		update-rich-text state as red-block! values + FACE_OBJ_EXT3
	][exit]

	s: GET_BUFFER(state)
	int: as red-integer! s/offset
	hWnd: as handle! int/value
	int: int + 1
	flags: int/value

	if flags and FACET_FLAG_OFFSET <> 0 [
		change-offset hWnd as red-point2D! values + FACE_OBJ_OFFSET type
	]
	if flags and FACET_FLAG_SIZE <> 0 [
		change-size hWnd values type
	]
	if flags and FACET_FLAG_TEXT <> 0 [
		change-text hWnd values type
	]
	if flags and FACET_FLAG_DATA <> 0 [
		change-data	hWnd values
	]
	if flags and FACET_FLAG_ENABLED? <> 0 [
		change-enabled hWnd values type
	]
	if flags and FACET_FLAG_VISIBLE? <> 0 [
		bool: as red-logic! values + FACE_OBJ_VISIBLE?
		change-visible hWnd values bool/value type
	]
	if flags and FACET_FLAG_SELECTED <> 0 [
		int2: as red-integer! values + FACE_OBJ_SELECTED
		change-selection hWnd int2 values
	]
	if flags and FACET_FLAG_FLAGS <> 0 [
		flags: get-flags as red-block! values + FACE_OBJ_FLAGS
		SetWindowLong
			hWnd
			wc-offset + 16
			flags
		if type = field [
			type: either flags and FACET_FLAGS_PASSWORD = 0 [0][25CFh]
			SendMessage hWnd 204 type 0
			SetFocus hWnd
		]
	]
	if flags and FACET_FLAG_DRAW  <> 0 [
		if IS_D2D_FACE(type) [
			update-base hWnd null null values
		]
	]
	if flags and FACET_FLAG_COLOR <> 0 [
		case [
			IS_D2D_FACE(type) [
				update-base hWnd null null values
			]
			type = calendar [
				update-calendar-color hWnd as red-value! values + FACE_OBJ_COLOR
			]
			true [InvalidateRect hWnd null 1]
		]
	]
	if flags and FACET_FLAG_PANE <> 0 [
		if tab-panel <> type [				;-- tab-panel/pane has custom z-order handling
			update-z-order 
				as red-block! values + gui/FACE_OBJ_PANE
				null
		]
	]
	if flags and FACET_FLAG_RATE <> 0 [
		change-rate hWnd values + FACE_OBJ_RATE
	]
	if flags and FACET_FLAG_FONT <> 0 [
		set-font hWnd face values
		either IS_D2D_FACE(type) [
			update-base hWnd null null values
		][
			InvalidateRect hWnd null 1
		]
	]
	if flags and FACET_FLAG_PARA <> 0 [
		either IS_D2D_FACE(type) [
			update-base hWnd null null values
		][
			InvalidateRect hWnd null 1
		]
	]
	if flags and FACET_FLAG_MENU <> 0 [
		menu: as red-block! values + FACE_OBJ_MENU
		DestroyMenu GetMenu hWnd
		either menu-bar? menu window [
			SetMenu hWnd build-menu menu CreateMenu
		][
			SetMenu hWnd null
		]
	]
	if flags and FACET_FLAG_IMAGE <> 0 [
		change-image hWnd values type
	]
	
	int/value: 0										;-- reset flags
]

OS-destroy-view: func [
	face   [red-object!]
	empty? [logic!]
][
	free-faces face yes
	if empty? [
		exit-loop: exit-loop + 1
		PostQuitMessage 0
	]
]

OS-update-facet: func [
	face   [red-object!]
	facet  [red-word!]
	value  [red-value!]
	action [red-word!]
	new	   [red-value!]
	index  [integer!]
	part   [integer!]
	/local
		word [red-word!]
		pane [red-block!]
		sym	 [integer!]
		type [integer!]
][
	sym: symbol/resolve facet/symbol
	
	case [
		sym = facets/pane [
			sym: action/symbol 
			pane: as red-block! value
			case [
				any [
					sym = words/_remove/symbol
					sym = words/_take/symbol
					sym = words/_clear/symbol
				][
					change-faces-parent pane null new index part
				]
				any [
					sym = words/_inserted/symbol
					sym = words/_poke/symbol			;@@ unbind old value
					sym = words/_put/symbol				;@@ unbind old value
					sym = words/_moved/symbol
					sym = words/_changed/symbol
				][
					change-faces-parent pane face new index part
					update-z-order pane null
				]
				true [0]
			]
		]
		sym = facets/data [
			word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
			type: symbol/resolve word/symbol
			sym: action/symbol
			case [
				type = text-list [
					either sym = words/_sort/symbol [
						OS-update-view face
					][
						update-list face value sym new index part no
					]
				]
				any [
					type = drop-list
					type = drop-down
				][
					if zero? part [exit]
					update-list face value sym new index part yes
				]
				type = tab-panel [
					update-tabs	face value sym new index part
				]
				true [OS-update-view face]
			]
		]
		true [OS-update-view face]
	]
]


OS-to-image: func [
	face	[red-object!]
	return: [red-image!]
	/local
		hWnd 	[handle!]
		dc		[handle!]
		mdc		[handle!]
		rc		[RECT_STRUCT value]
		width	[integer!]
		height	[integer!]
		bmp		[handle!]
		img		[red-image!]
		word	[red-word!]
		size	[red-pair!]
		draw	[red-block!]
		screen? [logic!]
		bo		[tagPOINT value] 		;-- base offset
		sym 	[integer!]
		ret		[red-image!]
		dctx	[draw-ctx! value]
][
	hWnd: null
	word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
	sym: symbol/resolve word/symbol
	if sym = camera [
		hWnd: face-handle? face
		either null? hWnd [ret: as red-image! none-value][
			ret: as red-image! (object/get-values face) + FACE_OBJ_IMAGE
			camera-wait-image ret
		]
		return ret
	]
	screen?: screen = sym
	either screen? [
		size: as red-pair! get-node-facet face/ctx FACE_OBJ_SIZE
		width: dpi-scale as float32! size/x
		height: dpi-scale as float32! size/y
		rc/left: 0
		rc/top: 0
		dc: hScreen
	][
		hWnd: face-handle? face
		if null? hWnd [return as red-image! none-value]
		GetWindowRect hWnd rc
		width: rc/right - rc/left
		height: rc/bottom - rc/top
		dc: GetDC hWnd
	]

	if sym = base [
		ReleaseDC hWnd dc
		bmp: OS-image/make-image width height null null null
		ret: image/init-image as red-image! stack/push* bmp

		draw: as red-block! (object/get-values face) + FACE_OBJ_DRAW
		either TYPE_OF(draw) = TYPE_BLOCK [
			do-draw hwnd ret draw no no yes yes
		][
			catch RED_THROWN_ERROR [
				draw-begin :dctx hWnd ret no yes
				draw-end :dctx hWnd no no yes
			]
			system/thrown: 0
		]
		return ret
	]

	mdc: CreateCompatibleDC dc
	bmp: CreateCompatibleBitmap dc width height
	SelectObject mdc bmp

	either screen? [
		BitBlt mdc 0 0 width height hScreen rc/left rc/top SRCCOPY or CAPTUREBLT
	][
		either win8+? [
			PrintWindow hWnd mdc 2
		][
			bo/x: 0  bo/y: 0
			;-- when printing whole windows, account for nonclient area size:
			if window = sym [
				ClientToScreen hWnd bo
				bo/x: bo/x - rc/left
				bo/y: bo/y - rc/top
			]

			; see https://stackoverflow.com/a/44062144 and #3465 as to why PrintWindow shouldn't be used alone
			PrintWindow hWnd mdc 0 		;-- print everything that's printable
			imprint-layers-deep mdc hWnd bo/x bo/y null
		]
	]

	img: OS-image/from-HBITMAP as integer! bmp 0

    DeleteDC mdc
    DeleteObject bmp
    unless screen? [ReleaseDC hWnd dc]
	img
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
][
	do-draw null img cmds no no no no
]

OS-draw-face: func [
	hWnd	[handle!]
	cmds	[red-block!]
	flags	[integer!]
	/local
		ctx [draw-ctx!]
][
	if TYPE_OF(cmds) = TYPE_BLOCK [
		assert system/thrown = 0
		ctx: as draw-ctx! GetWindowLong hWnd OFFSET_DRAW_CTX
		catch RED_THROWN_ERROR [parse-draw ctx cmds yes]
	]
	if system/thrown = RED_THROWN_ERROR [system/thrown: 0]
]