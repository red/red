Red/System [
	Title:	"Windows GUI backend"
	Author: "Nenad Rakocevic, Xie Qingtian"
	File: 	%gui.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %win32.reds
#include %classes.reds
#include %events.reds

#include %font.reds
#include %camera.reds
#include %image.reds
#include %menu.reds
#include %panel.reds
#include %tab-panel.reds
#include %text-list.reds
#include %draw.reds

hScreen:		as handle! 0
hInstance:		as handle! 0
default-font:	as handle! 0
version-info: 	declare OSVERSIONINFO
current-msg: 	as tagMSG 0
wc-extra:		80										;-- reserve 64 bytes for win32 internal usage (arbitrary)
wc-offset:		64										;-- offset to our 16 bytes

log-pixels-x:	0
log-pixels-y:	0

clean-up: does [
	current-msg: null
]

get-face-values: func [
	hWnd	[handle!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		node [node!]
		s	 [series!]
][
	node: as node! GetWindowLong hWnd wc-offset + 4
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
][
	get-node-facet 
		as node! GetWindowLong get-widget-handle msg wc-offset + 4
		facet
]

get-widget-handle: func [
	msg		[tagMSG]
	return: [handle!]
	/local
		hWnd   [handle!]
		header [integer!]
		p	   [int-ptr!]
][
	hWnd: msg/hWnd
	header: GetWindowLong hWnd wc-offset

	if header and get-type-mask <> TYPE_OBJECT [
		hWnd: GetParent hWnd							;-- for composed widgets (try 1)
		header: GetWindowLong hWnd wc-offset

		if header and get-type-mask <> TYPE_OBJECT [
			hWnd: WindowFromPoint msg/x msg/y			;-- try 2
			header: GetWindowLong hWnd wc-offset

			if header and get-type-mask <> TYPE_OBJECT [
				p: as int-ptr! GetWindowLong hWnd 0		;-- try 3
				hWnd: as handle! p/2
				header: GetWindowLong hWnd wc-offset

				if header and get-type-mask <> TYPE_OBJECT [
					hWnd: as handle! -1					;-- not found
				]
			]
		]
	]
	hWnd
]

get-face-handle: func [
	face	[red-object!]
	return: [handle!]
	/local
		state [red-block!]
		int	  [red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	assert TYPE_OF(state) = TYPE_BLOCK
	int: as red-integer! block/rs-head state
	assert TYPE_OF(int) = TYPE_INTEGER
	as handle! int/value
]

enable-visual-styles: func [
	/local
		ctx	   [ACTCTX]
		dir	   [c-string!]
		ret	   [integer!]
		actctx [handle!]
		dll    [handle!]
		InitCC [InitCommonControlsEx!]
		ctrls  [INITCOMMONCONTROLSEX]
		cookie [struct! [ptr [byte-ptr!]]]
][
	ctx: declare ACTCTX
	cookie: declare struct! [ptr [byte-ptr!]]
	dir: as-c-string allocate 258						;-- 128 UTF-16 codepoints + 2 NUL

	ctx/cbSize:		 size? ACTCTX
	ctx/dwFlags: 	 ACTCTX_FLAG_RESOURCE_NAME_VALID
		or ACTCTX_FLAG_SET_PROCESS_DEFAULT
		or ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID

	ctx/lpSource: 	 #u16 "shell32.dll"
	ctx/wProcLangID: 0
	ctx/lpAssDir: 	 dir
	ctx/lpResource:	 as-c-string 124					;-- Manifest ID in the DLL

	sz: GetSystemDirectory dir 128
	if sz > 128 [probe "*** GetSystemDirectory: buffer overflow"]

	actctx: CreateActCtx ctx
	ActivateActCtx actctx cookie

	dll: LoadLibraryEx #u16 "comctl32.dll" 0 0
	if dll = null [probe "*** Error loading comctl32.dll"]

	InitCC: as InitCommonControlsEx! GetProcAddress dll "InitCommonControlsEx"
	ctrls: declare INITCOMMONCONTROLSEX
	ctrls/dwSize: size? INITCOMMONCONTROLSEX
	ctrls/dwICC: ICC_STANDARD_CLASSES
			  or ICC_TAB_CLASSES
			  or ICC_LISTVIEW_CLASSES
			  or ICC_BAR_CLASSES
	InitCC ctrls

	DeactivateActCtx 0 cookie/ptr
	ReleaseActCtx actctx
	free as byte-ptr! dir
]

to-bgr: func [
	node	[node!]
	return: [integer!]									;-- 00bbggrr format or -1 if not found
][
	color: as red-tuple! get-node-facet node FACE_OBJ_COLOR
	either TYPE_OF(color) = TYPE_TUPLE [
		color/array1 and 00FFFFFFh
	][
		-1
	]
]

free-handles: func [
	hWnd [handle!]
	/local
		values [red-value!]
		type   [red-word!]
		face   [red-object!]
		tail   [red-object!]
		pane   [red-block!]
		state  [red-value!]
		sym	   [integer!]
		cam	   [camera!]
][
	values: get-face-values hWnd
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	
	case [
		sym = window [
			pane: as red-block! values + FACE_OBJ_PANE
			if TYPE_OF(pane) = TYPE_BLOCK [
				face: as red-object! block/rs-head pane
				tail: as red-object! block/rs-tail pane
				while [face < tail][
					free-handles get-face-handle face
					face: face + 1
				]
			]
		]
		sym = group-box [
			;-- destroy the extra frame window
			DestroyWindow as handle! GetWindowLong hWnd wc-offset - 4 as-integer hWnd
		]
		sym = _image [
			DeleteDC as handle! GetWindowLong hWnd wc-offset - 4
		]
		sym = camera [
			cam: as camera! GetWindowLong hWnd wc-offset - 4
			unless null? cam [
				teardown-graph cam
				free-graph cam
			]
		]
		true [
			0
			;; handle user-provided classes too
		]
	]
	DestroyWindow hWnd
	
	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

init: func [
	/local
		ver [red-tuple!]
		int [red-integer!]
][
	hScreen: GetDC null
	hInstance: GetModuleHandle 0
	default-font: GetStockObject DEFAULT_GUI_FONT

	version-info/dwOSVersionInfoSize: size? OSVERSIONINFO
	GetVersionEx version-info
	ver: as red-tuple! #get system/view/platform/version

	ver/header: TYPE_TUPLE or (3 << 19)
	ver/array1: version-info/dwMajorVersion
		or (version-info/dwMinorVersion << 8)
		and 0000FFFFh

	unless all [
		version-info/dwMajorVersion = 5
		version-info/dwMinorVersion < 1
	][
		enable-visual-styles							;-- not called for Win2000
	]

	register-classes hInstance

	int: as red-integer! #get system/view/platform/build
	int/header: TYPE_INTEGER
	int/value:  version-info/dwBuildNumber

	int: as red-integer! #get system/view/platform/product
	int/header: TYPE_INTEGER
	int/value:  as-integer version-info/wProductType
	
	log-pixels-x: GetDeviceCaps hScreen 88				;-- LOGPIXELSX
	log-pixels-y: GetDeviceCaps hScreen 90				;-- LOGPIXELSY
]

set-logic-state: func [
	hWnd   [handle!]
	state  [red-logic!]
	check? [logic!]
	/local
		value [integer!]
][
	value: either TYPE_OF(state) <> TYPE_LOGIC [
		either check? [BST_INDETERMINATE][false]
	][
		as-integer state/value							;-- returns 0/1, matches the messages
	]
	SendMessage hWnd BM_SETCHECK value 0
]

get-logic-state: func [
	msg		[tagMSG]
	return: [logic!]									;-- TRUE if state has changed
	/local
		bool  [red-logic!]
		state [integer!]
		otype [integer!]
		obool [logic!]
][
	bool: as red-logic! get-facet msg FACE_OBJ_DATA
	state: as-integer SendMessage msg/hWnd BM_GETCHECK 0 0

	either state = BST_INDETERMINATE [
		otype: TYPE_OF(bool)
		bool/header: TYPE_NONE							;-- NONE indicates undeterminate
		bool/header <> otype
	][
		obool: bool/value
		bool/value: state = BST_CHECKED
		bool/value <> obool
	]
]

get-selected: func [
	msg [tagMSG]
	idx [integer!]
	/local
		int [red-integer!]
][
	int: as red-integer! get-facet msg FACE_OBJ_SELECTED
	int/value: idx
]

get-text: func [
	msg	[tagMSG]
	idx	[integer!]
	/local
		size	[integer!]
		str		[red-string!]
		out		[c-string!]
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
		unicode/load-utf16 null size str
	]
]

get-position-value: func [
	pos		[red-float!]
	maximun [integer!]
	return: [integer!]
	/local
		f	[float!]
][
	f: 0.0
	if any [
		TYPE_OF(pos) = TYPE_FLOAT
		TYPE_OF(pos) = TYPE_PERCENT
	][
		f: pos/value * (integer/to-float maximun)
	]
	float/to-integer f
]

get-slider-pos: func [
	msg	[tagMSG]
	/local
		values	[red-value!]
		size	[red-pair!]
		pos		[red-float!]
		int		[integer!]
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
	int: as-integer SendMessage msg/hWnd TBM_GETPOS 0 0
	divisor: size/x
	if size/y > size/x [divisor: size/y int: divisor - int]
	pos/value: (integer/to-float int) / (integer/to-float divisor)
]

get-screen-size: func [
	id		[integer!]									;@@ Not used yet
	return: [red-pair!]
][
	pair/push 
		GetDeviceCaps hScreen HORZRES
		GetDeviceCaps hScreen VERTRES
]

DWM-enabled?: func [
	return:		[logic!]
	/local
		enabled [integer!]
		dll		[handle!]
		fun		[DwmIsCompositionEnabled!]
][
	enabled: 0
	dll: LoadLibraryEx #u16 "dwmapi.dll" 0 0
	if dll = null [return false]
	fun: as DwmIsCompositionEnabled! GetProcAddress dll "DwmIsCompositionEnabled"
	fun :enabled
	either zero? enabled [false][true]
]

OS-show-window: func [
	hWnd [integer!]
][
	ShowWindow as handle! hWnd SW_SHOWDEFAULT
	UpdateWindow as handle! hWnd
]

OS-make-view: func [
	face	[red-object!]
	parent	[integer!]
	return: [integer!]
	/local
		values	  [red-value!]
		type	  [red-word!]
		str		  [red-string!]
		tail	  [red-string!]
		offset	  [red-pair!]
		size	  [red-pair!]
		data	  [red-block!]
		int		  [red-integer!]
		img		  [red-image!]
		menu	  [red-block!]
		show?	  [red-logic!]
		open?	  [red-logic!]
		selected  [red-integer!]
		flags	  [integer!]
		ws-flags  [integer!]
		sym		  [integer!]
		class	  [c-string!]
		caption   [c-string!]
		offx	  [integer!]
		offy	  [integer!]
		value	  [integer!]
		handle	  [handle!]
		hWnd	  [handle!]
		p		  [ext-class!]
		id		  [integer!]
		vertical? [logic!]
		panel?	  [logic!]
][
	values: object/get-values face

	type:	  as red-word!		values + FACE_OBJ_TYPE
	str:	  as red-string!	values + FACE_OBJ_TEXT
	offset:   as red-pair!		values + FACE_OBJ_OFFSET
	size:	  as red-pair!		values + FACE_OBJ_SIZE
	show?:	  as red-logic!		values + FACE_OBJ_VISIBLE?
	open?:	  as red-logic!		values + FACE_OBJ_ENABLE?
	data:	  as red-block!		values + FACE_OBJ_DATA
	img:	  as red-image!		values + FACE_OBJ_IMAGE
	menu:	  as red-block!		values + FACE_OBJ_MENU
	selected: as red-integer!	values + FACE_OBJ_SELECTED

	flags: 	  WS_CHILD or WS_CLIPSIBLINGS
	ws-flags: 0
	id:		  0
	sym: 	  symbol/resolve type/symbol
	offx:	  offset/x
	offy:	  offset/y
	panel?:	  no

	if show?/value [flags: flags or WS_VISIBLE]

	case [
		sym = button [
			class: #u16 "RedButton"
			;flags: flags or BS_PUSHBUTTON
		]
		sym = check [
			class: #u16 "RedButton"
			flags: flags or WS_TABSTOP or BS_AUTOCHECKBOX
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
			init-panel values as handle! parent
			offx: offset/x								;-- refresh locals
			offy: offset/y
			panel?: yes
		]
		sym = tab-panel [
			class: #u16 "RedTabPanel"
		]
		sym = field [
			class: #u16 "RedField"
			flags: flags or ES_LEFT or ES_AUTOHSCROLL
			ws-flags: WS_TABSTOP or WS_EX_CLIENTEDGE
		]
		sym = area [
			class: #u16 "RedField"
			flags: flags or ES_LEFT or ES_AUTOVSCROLL or ES_AUTOHSCROLL or ES_MULTILINE
			ws-flags: WS_TABSTOP or WS_EX_CLIENTEDGE
		]
		sym = text [
			class: #u16 "RedFace"
			flags: flags or SS_SIMPLE
		]
		sym = text-list [
			class: #u16 "RedListBox"
			flags: flags or LBS_NOTIFY or WS_HSCROLL or WS_VSCROLL
		]
		sym = drop-down [
			class: #u16 "RedCombo"
			flags: flags or CBS_DROPDOWN or CBS_HASSTRINGS ;or WS_OVERLAPPED
		]
		sym = drop-list [
			class: #u16 "RedCombo"
			flags: flags or CBS_DROPDOWNLIST or CBS_HASSTRINGS ;or WS_OVERLAPPED
		]
		sym = progress [
			class: #u16 "RedProgress"
			if size/y > size/x [flags: flags or PBS_VERTICAL]
		]
		sym = slider [
			class: #u16 "RedSlider"
			if size/y > size/x [
				flags: flags or TBS_VERT or TBS_DOWNISLEFT
			]
		]
		sym = _image [
			class: #u16 "RedImage"
		]
		sym = camera [
			class: #u16 "RedCamera"
		]
		sym = base [
			class: #u16 "Base"
		]
		sym = window [
			class: #u16 "RedWindow"
			flags: WS_OVERLAPPEDWINDOW ;or WS_CLIPCHILDREN
			offx:  CW_USEDEFAULT
			offy:  CW_USEDEFAULT
			if menu-bar? menu window [
				id: as-integer build-menu menu CreateMenu
			]
		]
		true [											;-- search in user-defined classes
			p: find-class type
			class: p/class
			ws-flags: ws-flags or p/ex-styles
			flags: flags or p/styles
			id: p/base-id
		]
	]

	caption: either TYPE_OF(str) = TYPE_STRING [
		unicode/to-utf16 str
	][
		null
	]

	unless DWM-enabled? [
		ws-flags: ws-flags or WS_EX_COMPOSITED			;-- this flag conflicts with DWM
	]

	handle: CreateWindowEx
		ws-flags
		class
		caption
		flags
		offx
		offy
		size/x
		size/y
		as int-ptr! parent
		as handle! id
		hInstance
		null

	if null? handle [print-line "*** Error: CreateWindowEx failed!"]

	BringWindowToTop handle
	;SendMessage handle WM_SETFONT as-integer default-font 1
	set-font handle face values

	;-- extra initialization
	case [
		sym = camera	[init-camera handle data open?/value]
		sym = text-list [init-text-list handle data selected]
		sym = _image	[init-image handle data img]
		sym = tab-panel [set-tabs handle values]
		sym = group-box [
			flags: flags or WS_GROUP or BS_GROUPBOX
			hWnd: CreateWindowEx
				ws-flags
				#u16 "BUTTON"
				caption
				flags
				0
				0
				size/x
				size/y
				handle
				null
				hInstance
				null

			SendMessage hWnd WM_SETFONT as-integer default-font 1
			SetWindowLong handle wc-offset - 4 as-integer hWnd
		]
		panel? [
			adjust-parent handle as handle! parent offx offy
		]
		sym = slider [
			vertical?: size/y > size/x
			value: either vertical? [size/y][size/x]
			SendMessage handle TBM_SETRANGE 1 value << 16
			value: get-position-value as red-float! data value
			if vertical? [value: size/y - value]
			SendMessage handle TBM_SETPOS 1 value
		]
		sym = progress [
			value: get-position-value as red-float! data 100
			SendMessage handle PBM_SETPOS value 0
		]
		sym = check [set-logic-state handle as red-logic! data yes]
		sym = radio [set-logic-state handle as red-logic! data no]
		any [
			sym = drop-down
			sym = drop-list
		][
			if any [
				TYPE_OF(data) = TYPE_BLOCK
				TYPE_OF(data) = TYPE_HASH
				TYPE_OF(data) = TYPE_MAP
			][
				str:  as red-string! block/rs-head data
				tail: as red-string! block/rs-tail data
				while [str < tail][
					if TYPE_OF(str) = TYPE_STRING [
						SendMessage 
							handle
							CB_ADDSTRING
							0
							as-integer unicode/to-utf16 str
					]
					str: str + 1
				]
			]
			either any [null? caption sym = drop-list][
				int: as red-integer! get-node-facet face/ctx FACE_OBJ_SELECTED
				if TYPE_OF(int) = TYPE_INTEGER [
					SendMessage handle CB_SETCURSEL int/value - 1 0
				]
			][
				SetWindowText handle caption
			]
		]
		true [0]
	]
	
	;-- store the face value in the extra space of the window struct
	SetWindowLong handle wc-offset		  		   face/header
	SetWindowLong handle wc-offset + 4  as-integer face/ctx
	SetWindowLong handle wc-offset + 8  		   face/class
	SetWindowLong handle wc-offset + 12 as-integer face/on-set

	as-integer handle
]

change-size: func [
	hWnd [integer!]
	size [red-pair!]
][
	SetWindowPos 
		as handle! hWnd
		as handle! 0
		0 0
		size/x size/y 
		SWP_NOMOVE or SWP_NOZORDER
]

change-offset: func [
	hWnd [integer!]
	pos  [red-pair!]
][
	SetWindowPos 
		as handle! hWnd
		as handle! 0
		pos/x pos/y
		0 0
		SWP_NOSIZE or SWP_NOZORDER
]

change-text: func [
	hWnd [integer!]
	str  [red-string!]
	type [red-word!]
	/local
		text [c-string!]
][
	text: null
	switch TYPE_OF(str) [
		TYPE_STRING [text: unicode/to-utf16 str]
		TYPE_NONE	[text: #u16 "^@"]
		default		[0]									;@@ Auto-convert?
	]
	unless null? text [
		if type/symbol = group-box [
			hWnd: GetWindowLong as handle! hWnd wc-offset - 4
		]
		SetWindowText as handle! hWnd text
	]
]

change-visible: func [
	hWnd  [integer!]
	show? [logic!]
	/local
		value [integer!]
][
	value: either show? [SW_SHOW][SW_HIDE]
	ShowWindow as handle! hWnd value
]

change-enable: func [
	hWnd	[integer!]
	enable? [logic!]
][
	toggle-preview as handle! hWnd enable?
]

change-selection: func [
	hWnd [integer!]
	idx  [integer!]
	type [red-word!]
][
	either type/symbol = camera [
		select-camera as handle! hWnd idx - 1
	][
		SendMessage as handle! hWnd CB_SETCURSEL idx - 1 0
	]
]

change-data: func [
	hWnd [integer!]
	data [red-value!]
	type [red-word!]
	/local
		h		[handle!]
		f		[red-float!]
		values	[red-value!]
][
	h: as handle! hWnd
	case [
		all [
			type/symbol = progress
			TYPE_OF(data) = TYPE_PERCENT
		][
			f: as red-float! data
			SendMessage h PBM_SETPOS float/to-integer f/value * 100.0 0
		]
		type/symbol = check [
			set-logic-state h as red-logic! data yes
		]
		type/symbol = radio [
			set-logic-state h as red-logic! data no
		]
		type/symbol = base [		;@@ temporary used to update draw window, remove later.
			InvalidateRect h null 1
		]
		type/symbol = _image [
			values: get-face-values h
			init-image h as red-block! data as red-image! values + FACE_OBJ_IMAGE
			InvalidateRect h null 1
		]
		true [0]										;-- default, do nothing
	]
]

change-faces-parent: func [
	pane   [red-block!]
	parent [red-object!]
	index  [integer!]
	part   [integer!]
][
	assert TYPE_OF(pane) = TYPE_BLOCK
	face: as red-object! block/rs-abs-at pane index
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
		bool		[red-logic!]
		type		[red-word!]
		values		[red-value!]
		offset		[red-pair!]
		tab-panel?	[logic!]
][
	hWnd: get-face-handle face
	values: get-node-facet face/ctx 0
	bool: as red-logic! values + FACE_OBJ_VISIBLE?
	tab-panel?: no
	
	if parent <> null [
		assert TYPE_OF(parent) = TYPE_OBJECT
		type: as red-word! get-node-facet parent/ctx FACE_OBJ_TYPE
		tab-panel?: tab-panel = symbol/resolve type/symbol
	]
	unless tab-panel? [bool/value: parent <> null]
	
	either null? parent [
		change-visible as-integer hWnd no
		SetParent hWnd null
	][
		if tab-panel? [exit]
		SetParent hWnd get-face-handle parent
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
		s	 [series!]
		nb	 [integer!]
		sub? [logic!]
][
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
			hdwp: DeferWindowPos
				hdwp
				get-face-handle face
				as handle! 0							;-- HWND_TOP
				0 0
				0 0
				SWP_NOSIZE or SWP_NOMOVE
			
			type: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
			
			if tab-panel = symbol/resolve type/symbol [
				;-- ensures that panels are above the tab-panel
				blk: as red-block! get-node-facet face/ctx FACE_OBJ_PANE
				if TYPE_OF(blk) = TYPE_BLOCK [update-z-order blk hdwp]
			]
		]
		face: face + 1
	]
	unless sub? [EndDeferWindowPos hdwp]
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
		s		[series!]
		hWnd	[integer!]
		flags	[integer!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	values: s/offset

	state: as red-block! values + gui/FACE_OBJ_STATE
	s: GET_BUFFER(state)
	int: as red-integer! s/offset
	hWnd: int/value
	int: int + 1
	flags: int/value

	if flags and FACET_FLAG_OFFSET <> 0 [
		change-offset hWnd as red-pair! values + gui/FACE_OBJ_OFFSET
	]
	if flags and FACET_FLAG_SIZE <> 0 [
		change-size hWnd as red-pair! values + gui/FACE_OBJ_SIZE
	]
	if flags and FACET_FLAG_TEXT <> 0 [
		change-text
			hWnd
			as red-string! values + gui/FACE_OBJ_TEXT
			as red-word! values + gui/FACE_OBJ_TYPE
	]
	if flags and FACET_FLAG_DATA <> 0 [
		change-data
			hWnd 
			values + gui/FACE_OBJ_DATA
			as red-word! values + gui/FACE_OBJ_TYPE
	]
	if flags and FACET_FLAG_ENABLE? <> 0 [
		bool: as red-logic! values + gui/FACE_OBJ_ENABLE?
		change-enable hWnd bool/value
	]
	if flags and FACET_FLAG_VISIBLE? <> 0 [
		bool: as red-logic! values + gui/FACE_OBJ_VISIBLE?
		change-visible hWnd bool/value
	]
	if flags and FACET_FLAG_SELECTED <> 0 [
		int2: as red-integer! values + gui/FACE_OBJ_SELECTED
		change-selection hWnd int2/value as red-word! values + gui/FACE_OBJ_TYPE
	]
	if any [
		flags and FACET_FLAG_DRAW  <> 0
		flags and FACET_FLAG_COLOR <> 0
	][
		InvalidateRect as handle! hWnd null 1
	]
	if flags and FACET_FLAG_PANE <> 0 [
		word: as red-word! values + FACE_OBJ_TYPE
		if tab-panel <> symbol/resolve word/symbol [	;-- tab-panel/pane has custom z-order handling
			update-z-order 
				as red-block! values + gui/FACE_OBJ_PANE
				null
		]
	]
	if flags and FACET_FLAG_MENU <> 0 [
		menu: as red-block! values + gui/FACE_OBJ_MENU
		if menu-bar? menu window [
			DestroyMenu GetMenu as handle! hWnd
			SetMenu as handle! hWnd build-menu menu CreateMenu
		]
	]
	
	int/value: 0										;-- reset flags
]

OS-destroy-view: func [
	face   [red-object!]
	empty? [logic!]
	/local
		screen [red-object!]
		pane   [red-block!]
][
	free-handles get-face-handle face
	if empty? [clean-up PostQuitMessage 0]
]

OS-update-facet: func [
	face   [red-object!]
	facet  [red-word!]
	value  [red-value!]
	action [red-word!]
	index  [integer!]
	part   [integer!]
	/local
		word [red-word!]
		sym	 [integer!]
		type [integer!]
		hWnd [handle!]
][
	sym: symbol/resolve facet/symbol
	
	case [
		sym = facets/pane [
			sym: action/symbol 
			case [
				any [
					sym = words/_remove/symbol
					sym = words/_take/symbol
					sym = words/_clear/symbol
				][
					change-faces-parent as red-block! value null index part
				]
				any [
					sym = words/_insert/symbol
					sym = words/_poke/symbol			;@@ unbind old value
					sym = words/_put/symbol				;@@ unbind old value
				][
					change-faces-parent as red-block! value face index part
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
					update-list face value sym index part no
				]
				any [
					type = drop-list
					type = drop-down
				][
					if any [
						index and 1 = 1
						part  and 1 = 1
					][
						fire [TO_ERROR(script invalid-data-facet) value]
					]
					index: index / 2
					part:   part / 2
					if zero? part [exit]
					
					update-list face value sym index part yes
				]
				type = tab-panel [
					update-tabs	face value sym index part
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
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		bmp		[handle!]
		bitmap	[integer!]
		img		[red-image!]
		word	[red-word!]
		type	[integer!]
		size	[red-pair!]
		screen? [logic!]
][
	rect: declare RECT_STRUCT
	word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
	screen?: screen = symbol/resolve word/symbol
	either screen? [
		size: as red-pair! get-node-facet face/ctx FACE_OBJ_SIZE
		width: size/x
		height: size/y
		rect/left: 0
		rect/top: 0
		dc: hScreen
	][
		hWnd: get-face-handle face
		GetWindowRect hWnd rect
		width: rect/right - rect/left
		height: rect/bottom - rect/top
		dc: GetDC hWnd
	]

	mdc: CreateCompatibleDC dc
	bmp: CreateCompatibleBitmap dc width height
	SelectObject mdc bmp
	BitBlt mdc 0 0 width height hScreen rect/left rect/top SRCCOPY

	bitmap: 0
	GdipCreateBitmapFromHBITMAP bmp 0 :bitmap

	either zero? bitmap [img: as red-image! none-value][
		img: image/init-image as red-image! stack/push* bitmap
	]

    DeleteDC mdc
    DeleteObject bmp
    unless screen? [ReleaseDC hWnd dc]
	img
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
][
	do-draw null img cmds
]