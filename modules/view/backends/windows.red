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
				
				EVT_KEY
				EVT_KEY_DOWN
				EVT_KEY_UP
			]
			
			#enum event-flag! [
				EVT_FLAG_DBL_CLICK:		10000000h
				EVT_FLAG_CTRL_DOWN:		20000000h
				EVT_FLAG_SHIFT_DOWN:	40000000h
				EVT_FLAG_KEY_DOWN:		80000000h
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
			_key-down:		word/load "key-down"
			_key-up:		word/load "key-up"
			
			_page-up:		word/load "page-up"
			_page_down:		word/load "page-down"
			_end:			word/load "end"
			_home:			word/load "home"
			_left:			word/load "left"
			_up:			word/load "up"
			_right:			word/load "right"
			_down:			word/load "down"
			_insert:		word/load "insert"
			_delete:		word/load "delete"
			_F1:			word/load "F1"
			_F2:			word/load "F2"
			_F3:			word/load "F3"
			_F4:			word/load "F4"
			_F5:			word/load "F5"
			_F6:			word/load "F6"
			_F7:			word/load "F7"
			_F8:			word/load "F8"
			_F9:			word/load "F9"
			_F10:			word/load "F10"
			_F11:			word/load "F11"
			_F12:			word/load "F12"
			
			hScreen: as handle! 0
			default-font: declare handle!
			version-info: declare OSVERSIONINFO

			get-event-type: func [
				evt		[red-event!]
				return: [red-value!]
			][
				as red-value! switch evt/type [
					EVT_LEFT_DOWN	 [_down]
					EVT_LEFT_UP		 [_up]
					EVT_MIDDLE_DOWN	 [_middle-down]
					EVT_MIDDLE_UP	 [_middle-up]
					EVT_RIGHT_DOWN	 [_alt-down]
					EVT_RIGHT_UP	 [_alt-up]
					EVT_AUX_DOWN	 [_aux-down]
					EVT_AUX_UP		 [_aux-up]
					EVT_CLICK		 [_click]
					EVT_DBL_CLICK	 [_double-click]
					EVT_MOVE		 [_move]
					EVT_KEY			 [_key]
					EVT_KEY_DOWN	 [_key-down]
					EVT_KEY_UP		 [_key-up]
				]
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
				either evt/type <= EVT_MOVE [
					msg: as tagMSG evt/msg

					offset: as red-pair! stack/push*
					offset/header: TYPE_PAIR
					value: msg/lParam

					offset/x: WIN32_LOWORD(value)
					offset/y: WIN32_HIWORD(value)
					as red-value! offset
				][
					as red-value! none-value
				]
			]
			
			get-event-key: func [
				evt		[red-event!]
				return: [red-value!]
				/local
					char [red-char!]
			][
				as red-value! switch evt/type [
					EVT_KEY [
						either evt/flags and EVT_FLAG_KEY_DOWN <> 0 [
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
				
			make-event: func [
				msg		[tagMSG]
				type	[integer!]
				return: [logic!]
				/local
					done? [logic!]
			][
				gui-evt/type: type
				gui-evt/msg:  as byte-ptr! msg
				gui-evt/flags: 0						;-- reset flags
				done?: no
				
				switch type [
					EVT_KEY_DOWN [
						gui-evt/flags: msg/wParam and FFFFh or EVT_FLAG_KEY_DOWN
						gui-evt/type: EVT_KEY
						done?: yes
					]
					EVT_KEY [gui-evt/flags: msg/wParam and FFFFh]
					default [0]
				]
				;@@ set other flags here
				
				#call [system/view/awake gui-evt]
				done?
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
			
			process-early: func [
				msg		[tagMSG]
				return: [logic!]
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
					WM_KEYDOWN		[make-event msg EVT_KEY_DOWN]
					WM_KEYUP		[make-event msg EVT_KEY_UP]
					;WM_DESTROY []
					default			[no]
				]
				;done?
			]
			
			process-late: func [
				msg	[tagMSG]
				/local
					wParam [integer!]
			][
				switch msg/msg [
					WM_COMMAND [
						wParam: msg/wParam
						if WIN32_HIWORD(wParam) = BN_CLICKED [
							make-event msg EVT_CLICK
						]
					]
					WM_CHAR [make-event msg EVT_KEY]
					default [0]
				]
			]

			do-events: func [
				no-wait? [logic!]
				/local
					msg	  [tagMSG]
					done? [logic!]
			][
				msg: declare tagMSG

				while [GetMessage msg null 0 0][
					TranslateMessage msg
					done?: process-early msg
					DispatchMessage msg
					unless done? [process-late msg]
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
				wcex/style:			CS_HREDRAW or CS_VREDRAW ;or CS_DBLCLKS
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
				
				wcex/style:			CS_HREDRAW or CS_VREDRAW ;or CS_DBLCLKS
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
