Red [
	Title:	"Windows platoform GUI backend"
	Author: "Nenad Rakocevic"
	File: 	%windows.red
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
			#include %imports/win32.reds

			#define WIN32_LOWORD(param) (param and FFFFh)
			#define WIN32_HIWORD(param) (param >>> 16)
			
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
				EVT_MOVE								;-- last mouse event
				
				EVT_KEY_DOWN
				EVT_KEY_UP
			]
			
			#enum event-flag! [
				EVT_FLAG_DBL_CLICK:		1
				EVT_FLAG_CTRL_DOWN
				EVT_FLAG_SHIFT_DOWN
			]
			
			gui-evt: declare red-event!					;-- low-level event value slot
			gui-evt/header: TYPE_EVENT
				
			_down:			word/load "down"
			_up:			word/load "up"
			_middle-down:	word/load "middle-down"
			_middle-up:		word/load "middle-up"
			_alt-down:		word/load "alt-down"
			_alt-up:		word/load "alt-up"
			_aux-down:		word/load "aux-down"
			_aux-up:		word/load "aux-up"
			_click:			word/load "click"
			_double-click:	word/load "double-click"
			_move:			word/load "move"
			_key:			word/load "key"
			_key-up:		word/load "key-up"
			
			hScreen: as handle! 0
			default-font: declare handle!
			version-info: declare OSVERSIONINFO

			get-event-type: func [
				evt		[red-event!]
				return: [red-value!]
				/local
					word [red-word!]
			][
				switch evt/type [
					EVT_LEFT_DOWN	 [word: _down]
					EVT_LEFT_UP		 [word: _up]
					EVT_MIDDLE_DOWN	 [word: _middle-down]
					EVT_MIDDLE_UP	 [word: _middle-up]
					EVT_RIGHT_DOWN	 [word: _alt-down]
					EVT_RIGHT_UP	 [word: _alt-up]
					EVT_AUX_DOWN	 [word: _aux-down]
					EVT_AUX_UP		 [word: _aux-up]
					EVT_CLICK		 [word: _click]
					EVT_DBL_CLICK	 [word: _double-click]
					EVT_MOVE		 [word: _move]
					EVT_KEY_DOWN	 [word: _key]
					EVT_KEY_UP		 [word: _key-up]
				]
				as red-value! word
			]
			
			get-event-face: func [
				evt		[red-event!]
				return: [red-value!]
			][
				as red-value! none-value
			]
			
			get-event-offset: func [
				evt		[red-event!]
				return: [red-value!]
				/local
					offset [red-pair!]
					value  [integer!]
					msg    [tagMSG]
			][
				;either evt/type <= EVT_MOVE
				msg: as tagMSG evt/msg

				offset: as red-pair! stack/push*
				offset/header: TYPE_PAIR
				value: msg/lParam
				
				offset/x: WIN32_LOWORD(value)
				offset/y: WIN32_HIWORD(value)				
				as red-value! offset
			]
				
			make-event: func [
				msg		[tagMSG]
				type	[integer!]
			][
				;print-line ["Low-level event type: " type]
				gui-evt/type: type
				gui-evt/msg:  as byte-ptr! msg
				
				#call [system/view/awake gui-evt]
			]

			WndProc: func [
				hWnd	[handle!]
				msg		[integer!]
				wParam	[integer!]
				lParam	[integer!]
				return: [integer!]
			][
				if msg = WM_DESTROY [PostQuitMessage 0]
				DefWindowProc hWnd msg wParam lParam
			]
			
			process: func [
				msg	[tagMSG]
				/local
					wParam [integer!]
			][
				switch msg/msg [				
					WM_LBUTTONDOWN	[make-event msg EVT_LEFT_DOWN]
					WM_LBUTTONUP	[make-event msg EVT_LEFT_UP]
					WM_RBUTTONDOWN	[make-event msg EVT_RIGHT_DOWN]
					WM_RBUTTONUP	[make-event msg EVT_RIGHT_UP]
					WM_MBUTTONDOWN	[make-event msg EVT_MIDDLE_DOWN]
					WM_MBUTTONUP	[make-event msg EVT_MIDDLE_UP]

					WM_COMMAND [
						wParam: msg/wParam
						if WIN32_HIWORD(wParam) = BN_CLICKED [
							make-event msg EVT_CLICK
						]
					]
					;WM_NOTIFY [
					;
					;]
					;WM_PAINT [
					;	DefWindowProc hWnd msg wParam lParam
					;]
					;WM_DESTROY [PostQuitMessage 0]
					default    [0]
				]
			]

			do-events: func [
				no-wait? [logic!]
				/local
					msg	[tagMSG]
			][
				msg: declare tagMSG

				while [GetMessage msg null 0 0][
					TranslateMessage msg
					process msg
					DispatchMessage  msg
					if no-wait? [exit]
				]
			]
			
			enable-visual-styles: func [
				return: [byte-ptr!]
				/local
					ctx	   [ACTCTX]
					dir	   [c-string!]
					ret	   [integer!]
					cookie [struct! [ptr [byte-ptr!]]]
			][
				ctx: declare ACTCTX
				cookie: declare struct! [ptr [byte-ptr!]]
				dir: as-c-string allocate 129				;-- 128 bytes + NUL

				ctx/cbSize:		 size? ACTCTX
				ctx/dwFlags: 	 ACTCTX_FLAG_RESOURCE_NAME_VALID
					or ACTCTX_FLAG_SET_PROCESS_DEFAULT
					or ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID

				ctx/lpSource: 	 "shell32.dll"
				ctx/wProcLangID: 0
				ctx/lpAssDir: 	 dir
				ctx/lpResource:	 as-c-string 124			;-- Manifest ID in the DLL

				sz: GetSystemDirectory dir 128
				if sz > 128 [probe "*** GetSystemDirectory: buffer overflow"]
				sz: sz + 1
				dir/sz: null-byte

				ActivateActCtx CreateActCtx ctx cookie
				cookie/ptr
			]

			register-classes: func [
				hInstance [handle!]
				/local
					wcex  [WNDCLASSEX]
					conex [WNDCLASSEX]
			][
				wcex: declare WNDCLASSEX

				wcex/cbSize: 		size? WNDCLASSEX
				wcex/style:			CS_HREDRAW or CS_VREDRAW
				wcex/lpfnWndProc:	:WndProc
				wcex/cbClsExtra:	0
				wcex/cbWndExtra:	0
				wcex/hInstance:		hInstance
				wcex/hIcon:			null
				wcex/hCursor:		LoadCursor null IDC_ARROW
				wcex/hbrBackground:	COLOR_WINDOW
				wcex/lpszMenuName:	null
				wcex/lpszClassName: "RedWindow"
				wcex/hIconSm:		0

				RegisterClassEx wcex
				
				wcex/style:			CS_HREDRAW or CS_VREDRAW
				wcex/lpfnWndProc:	:WndProc
				wcex/cbClsExtra:	0
				wcex/cbWndExtra:	0
				wcex/hInstance:		hInstance
				wcex/hIcon:			null
				wcex/hCursor:		LoadCursor null IDC_ARROW
				wcex/hbrBackground:	13
				wcex/lpszMenuName:	null
				wcex/lpszClassName: "Base"
				wcex/hIconSm:		0

				RegisterClassEx wcex
			]
			
			init: func [
				/local
					ver [red-tuple!]
					int [red-integer!]
			][
				hScreen: GetDC null
				hInstance: GetModuleHandle 0
				register-classes hInstance
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
					version-info/dwMinorVersion <= 1
				][
					enable-visual-styles				;-- not called for WinXP and Win2000
				]
					
				int: as red-integer! #get system/view/platform/build
				int/header: TYPE_INTEGER
				int/value:  version-info/dwBuildNumber
				
				int: as red-integer! #get system/view/platform/product
				int/header: TYPE_INTEGER
				int/value:  as-integer version-info/wProductType 
			]
			
			get-screen-size: func [
				id		[integer!]						;@@ Not used yet
				return: [red-pair!]
			][
				pair/push 
					GetDeviceCaps hScreen HORZRES
					GetDeviceCaps hScreen VERTRES
			]
			
			OS-show-window: func [
				hWnd [integer!]
			][
				ShowWindow as handle! hWnd SW_SHOWDEFAULT
				UpdateWindow as handle! hWnd
			]

			OS-make-view: func [
				face	[red-object!]
				type	[red-word!]
				str		[red-string!]
				offset	[red-pair!]
				size	[red-pair!]
				parent	[integer!]
				return: [integer!]
				/local
					flags	 [integer!]
					ws-flags [integer!]
					sym		 [integer!]
					class	 [c-string!]
					caption  [c-string!]
					offx	 [integer!]
					offy	 [integer!]
			][
				flags: 	  WS_VISIBLE or WS_CHILD
				ws-flags: 0
				sym: 	  symbol/resolve type/symbol
				offx:	  offset/x
				offy:	  offset/y

				case [
					sym = button [
						class: "BUTTON"
						flags: flags or BS_PUSHBUTTON
					]
					sym = check [
						class: "BUTTON"
						flags: flags or WS_TABSTOP or BS_AUTOCHECKBOX
					]
					sym = radio [
						class: "BUTTON"
						flags: flags or WS_TABSTOP or BS_AUTORADIOBUTTON
					]
					sym = field [
						class: "EDIT"
						flags: flags or ES_LEFT
						ws-flags: WS_TABSTOP or WS_EX_CLIENTEDGE
					]
					sym = text [
						class: "STATIC"
						flags: flags or SS_SIMPLE
					]
					sym = base [
						class: "Base"
					]
					sym = window [
						class: "RedWindow"
						flags: WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN
						offx:  CW_USEDEFAULT
						offy:  CW_USEDEFAULT
					]
				]

				caption: either TYPE_OF(str) = TYPE_STRING [
					as-c-string string/rs-head str
				][
					null
				]
				
				handle: CreateWindowEx
					WS_EX_COMPOSITED or ws-flags
					class
					caption
					flags
					offx
					offy
					size/x
					size/y
					as int-ptr! parent
					null
					hInstance
					null
					
				if null? handle [print-line "*** Error: CreateWindowEx failed!"]
				SendMessage handle WM_SETFONT as-integer default-font 1
				
				SetWindowLong handle GWL_USERDATA as-integer face/ctx

				as-integer handle
			]

			hInstance:	declare handle!
			hdc: 		declare handle!
			hWnd:		declare handle!
			msg:		declare tagMSG

			window:		symbol/make "window"
			button:		symbol/make "button"
			check:		symbol/make "check"
			radio:		symbol/make "radio"
			field:		symbol/make "field"
			text:		symbol/make "text"
			base:		symbol/make "base"
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
	
	show-window: routine [id [integer!]][gui/OS-show-window id]

	make-view: routine [
		face	[object!]
		type	[word!]
		text	[string!]
		offset	[pair!]
		size	[pair!]
		parent	[integer!]
		return: [integer!]
	][
		gui/OS-make-view face type text offset size parent
	]

	do-event-loop: routine [no-wait? [logic!]][
		print-line "do-event-loop"
		gui/do-events no-wait?
	]

	show: func [face [object!] /with parent [object!] /local obj f params new? p][
		either all [face/state face/state/1][

		][
			new?: yes
			if face/type <> 'screen [
				p: either with [parent/state/1][0]
				obj: make-view face face/type face/text face/offset face/size p
				
				if face/type = 'window [
					append system/view/screens/1/pane face
				]
			]
			face/state: reduce [obj 0 0]
		]
		
		if face/pane [foreach f face/pane [self/show/with f face]]

		if all [new? face/type = 'window][show-window obj]
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
		]		
	]
	
	version: none
	build:	 none
	product: none
]
