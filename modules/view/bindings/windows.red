Red [
	Title:	"Windows console backend"
	Author: "Nenad Rakocevic"
	File: 	%windows.red
	Tabs: 	4
	Rights: "Copyright (C) 2014 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

system/view/platform: context [

	#system [

		gui: context [
			#define HORZRES				8
			#define VERTRES				10
			
			#define COLOR_WINDOW		5
			#define CS_VREDRAW			1
			#define CS_HREDRAW			2

			#define IDC_ARROW			7F00h
			#define WS_OVERLAPPEDWINDOW	00CF0000h
			#define WS_CLIPCHILDREN		02000000h
			#define CW_USEDEFAULT		80000000h
			#define WS_EX_ACCEPTFILES	00000010h
			#define WS_CHILD			40000000h
			#define WS_VISIBLE			10000000h
			#define WS_EX_COMPOSITED	02000000h
			#define WS_VSCROLL			00200000h
			#define WS_EX_LAYERED 		00080000h
			#define WS_TABSTOP			00010000h
			#define WS_EX_TRANSPARENT	00000020h
			#define WS_EX_CLIENTEDGE	00000200h
			#define WS_BORDER			00400000h

			#define SIF_RANGE			0001h
			#define SIF_PAGE			0002h
			#define SIF_POS				0004h
			#define SIF_DISABLENOSCROLL	0008h
			#define SB_VERT				1
			#define SW_SHOW				5
			#define SW_SHOWDEFAULT		10

			#define BS_PUSHBUTTON		00000000h
			#define BS_DEFPUSHBUTTON	00000001h
			#define BS_CHECKBOX			00000002h
			#define BS_AUTOCHECKBOX		00000003h
			#define BS_RADIOBUTTON		00000004h
			#define BS_AUTORADIOBUTTON	00000009h

			#define ES_LEFT				00000000h
			#define SS_LEFT				00000010h
			#define SS_SIMPLE			00000000h

			#define WM_DESTROY			0002h
			#define WM_PAINT			000Fh
			#define WM_SETFONT			0030h
			#define WM_GETFONT			0031h
			#define WM_COMMAND 			0111h

			#define BM_GETCHECK			F0F0h
			#define BM_SETCHECK			F0F1h

			#define BN_CLICKED 			0

			#define DEFAULT_GUI_FONT 	17
			
			#define WM_LBUTTONDOWN		0201h
			#define WM_LBUTTONUP		0202h
			#define WM_RBUTTONDOWN		0204h
			#define WM_RBUTTONUP		0205h
			#define WM_MBUTTONDOWN		0207h
			#define WM_MBUTTONUP		0208h

			#define ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID	0004h
			#define ACTCTX_FLAG_RESOURCE_NAME_VALID			0008h
			#define ACTCTX_FLAG_SET_PROCESS_DEFAULT 		0010h

			#define handle!				[pointer! [integer!]]

			tagPOINT: alias struct! [
				x		[integer!]
				y		[integer!]	
			]

			tagMSG: alias struct! [
				hWnd	[handle!]
				msg		[integer!]
				wParam	[integer!]
				lParam	[integer!]
				time	[integer!]
				pt		[tagPOINT]			;@@ POINT struct
			]

			wndproc-cb!: alias function! [
				hWnd	[handle!]
				msg		[tagMSG]
				wParam	[integer!]
				lParam	[integer!]
				return: [integer!]
			]

			WNDCLASSEX: alias struct! [
				cbSize		  [integer!]
				style		  [integer!]
				lpfnWndProc	  [wndproc-cb!]
				cbClsExtra    [integer!]
				cbWndExtra    [integer!]
				hInstance	  [handle!]
				hIcon	  	  [handle!]
				hCursor		  [handle!]
				hbrBackground [integer!]
				lpszMenuName  [c-string!]
				lpszClassName [c-string!]
				hIconSm	  	  [integer!]
			]

			SCROLLINFO: alias struct! [
				cbSize		[integer!]
				fMask		[integer!]
				nMin		[integer!]
				nMax		[integer!]
				nPage		[integer!]
				nPos		[integer!]
				nTrackPos	[integer!]
			]

			ACTCTX: alias struct! [
				cbsize		[integer!]
				dwFlags		[integer!]
				lpSource	[c-string!]					;-- wide-string
				wProcLangID	[integer!]					;-- combined wProc and wLangID in one field
				lpAssDir	[c-string!]
				lpResource	[c-string!]
				lpAppName	[c-string!]
				hModule		[integer!]
			]
			
			DISPLAY_DEVICE: alias struct! [
				cbSize		[integer!]
				DevName		[byte!]
			]
			
			OSVERSIONINFO: alias struct! [
				dwOSVersionInfoSize [integer!]
				dwMajorVersion		[integer!]
				dwMinorVersion		[integer!]
				dwBuildNumber		[integer!]	
				dwPlatformId		[integer!]
				szCSDVersion		[byte-ptr!]			;-- array of 128 bytes
				szCSDVersion0		[integer!]
				szCSDVersion1		[float!]
				szCSDVersion2		[float!]
				szCSDVersion3		[float!]
				szCSDVersion4		[float!]
				szCSDVersion5		[float!]
				szCSDVersion6		[float!]
				szCSDVersion7		[float!]
				szCSDVersion8		[float!]
				szCSDVersion9		[float!]
				szCSDVersion10		[float!]
				szCSDVersion11		[float!]
				szCSDVersion12		[float!]
				szCSDVersion13		[float!]
				szCSDVersion14		[float!]
				szCSDVersion15		[float!]
			]

			#import [
				"kernel32.dll" stdcall [
					GetModuleHandle: "GetModuleHandleA" [
						lpModuleName [integer!]
						return:		 [handle!]
					]
					GetLastError: "GetLastError" [
						return: [integer!]
					]
					GetSystemDirectory: "GetSystemDirectoryA" [
						lpBuffer	[c-string!]
						uSize		[integer!]
						return:		[integer!]
					]
					CreateActCtx: "CreateActCtxA" [
						pActCtx		[ACTCTX]
						return:		[handle!]
					]
					ActivateActCtx: "ActivateActCtx" [
						hActCtx		[handle!]
						lpCookie	[struct! [ptr [byte-ptr!]]]
					]
					GetVersionEx: "GetVersionExA" [
						lpVersionInfo [OSVERSIONINFO]
						return:		[integer!]
					]
				]
				"User32.dll" stdcall [
					GetDC: "GetDC" [
						hWnd		[handle!]
						return:		[handle!]
					]
					EnumDisplayDevices: "EnumDisplayDevicesA" [
						lpDevice 	[c-string!]
						iDevNum		[integer!]
						lpDispDev	[DISPLAY_DEVICE]
						dwFlags		[integer!]
						return:		[integer!]
					]
					RegisterClassEx: "RegisterClassExA" [
						lpwcx		[WNDCLASSEX]
						return: 	[integer!]
					]
					LoadCursor: "LoadCursorA" [
						hInstance	 [handle!]
						lpCursorName [integer!]
						return: 	 [handle!]
					]
					CreateWindowEx: "CreateWindowExA" [
						dwExStyle	 [integer!]
						lpClassName	 [c-string!]
						lpWindowName [c-string!]
						dwStyle		 [integer!]
						x			 [integer!]
						y			 [integer!]
						nWidth		 [integer!]
						nHeight		 [integer!]
						hWndParent	 [handle!]
						hMenu	 	 [handle!]
						hInstance	 [handle!]
						lpParam		 [int-ptr!]
						return:		 [handle!]
					]
					SetScrollInfo:	"SetScrollInfo" [
						hWnd		 [handle!]
						fnBar		 [integer!]
						lpsi		 [SCROLLINFO]
						fRedraw		 [logic!]
						return: 	 [integer!]
					]
					ShowWindow: "ShowWindow" [
						hWnd		[handle!]
						nCmdShow	[integer!]
						return:		[logic!]
					]
					UpdateWindow: "UpdateWindow" [
						hWnd		[handle!]
						return:		[logic!]
					]
					DefWindowProc: "DefWindowProcA" [
						hWnd		[handle!]
						msg			[tagMSG]
						wParam		[integer!]
						lParam		[integer!]
						return: 	[integer!]
					]
					GetMessage: "GetMessageA" [
						msg			[tagMSG]
						hWnd		[handle!]
						wParam		[integer!]
						lParam		[integer!]
						return: 	[logic!]
					]
					TranslateMessage: "TranslateMessage" [
						msg			[tagMSG]
						return: 	[logic!]
					]
					DispatchMessage: "DispatchMessageA" [
						msg			[tagMSG]
						return: 	[integer!]
					]
					PostQuitMessage: "PostQuitMessage" [
						nExitCode	[integer!]
					]
					SendMessage: "SendMessageA" [
						hWnd		[handle!]
						msg			[integer!]
						wParam		[integer!]
						lParam		[integer!]
						return: 	[handle!]
					]
					SendDlgItemMessage: "SendDlgItemMessageA" [
						hDlg		[handle!]
						nIDDlgItem	[integer!]
						msg			[integer!]
						wParam		[integer!]
						lParam		[integer!]
						return: 	[handle!]
					]
				]
				"gdi32.dll" stdcall [
					GetDeviceCaps: "GetDeviceCaps" [
						hDC			[handle!]
						nIndex		[integer!]
						return:		[integer!]
					]
					SetTextColor: "SetTextColor" [
						hdc			[handle!]
						crColor		[integer!]					;-- 0x00bbggrr
						return:		[integer!]					;-- 0x00bbggrr
					]
					SetBkColor: "SetBkColor" [
						hdc			[handle!]
						crColor		[integer!]					;-- 0x00bbggrr
						return:		[integer!]					;-- 0x00bbggrr				
					]
					TextOut: "TextOutA" [
						hdc			[handle!]
						nXStart		[integer!]
						nYStart		[integer!]
						lpString	[c-string!]
						size		[integer!]
						return:		[logic!]
					]
					GetStockObject: "GetStockObject" [
						fnObject	[integer!]
						return:		[handle!]
					]
				]
				"UxTheme.dll" stdcall [
					SetWindowTheme: "SetWindowTheme" [
						hWnd		[handle!]
						appname		[c-string!]
						subIdList	[integer!]
					]
				]
			]

			hScreen: as handle! 0
			default-font: declare handle!
			version-info: declare OSVERSIONINFO

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
				EVT_MOVE
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

			get-event-type: func [
				evt		[byte-ptr!]
				;return: [red-value!]
				/local
					msg [tagMSG]
			][
				msg: as tagMSG evt
				
			]
			
			make-event: func [
				msg		[tagMSG]
				type	[integer!]
			][
				print-line ["Low-level event type: " type]
				gui-evt/type: type
				gui-evt/msg:  as byte-ptr! msg
				
				#call [system/view/awake gui-evt]
			]

			WndProc: func [
				hWnd	[handle!]
				msg		[tagMSG]
				wParam	[integer!]
				lParam	[integer!]
				return: [integer!]
			][				
				switch msg [
				
					WM_LBUTTONDOWN	[make-event msg EVT_LEFT_DOWN]
					WM_LBUTTONUP	[make-event msg EVT_LEFT_UP]
					WM_RBUTTONDOWN	[make-event msg EVT_RIGHT_DOWN]
					WM_RBUTTONUP	[make-event msg EVT_RIGHT_UP]
					WM_MBUTTONDOWN	[make-event msg EVT_MIDDLE_DOWN]
					WM_MBUTTONUP	[make-event msg EVT_MIDDLE_UP]
					
					WM_COMMAND [
						if WIN32_HIWORD(wParam) = BN_CLICKED [
							make-event msg EVT_CLICK
						]
					]
					;WM_NOTIFY [
					;
					;]
					WM_PAINT [
						DefWindowProc hWnd msg wParam lParam
					]
					WM_DESTROY [PostQuitMessage 0]
					default    [return DefWindowProc hWnd msg wParam lParam]
				]
				DefWindowProc hWnd msg wParam lParam
			]

			do-events: func [
				no-wait? [logic!]
				/local
					msg	[tagMSG]
			][
				msg: declare tagMSG

				while [GetMessage msg null 0 0][
					TranslateMessage msg
					DispatchMessage  msg
					if no-wait? [exit]
				]
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

				;if zero? parent [parent: as-integer hWnd]

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

	;dpi: 94
	;screen-size: 1920x1200
	window-size: 800x400
	
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
		type	[word!]
		text	[string!]
		offset	[pair!]
		size	[pair!]
		parent	[integer!]
		return: [integer!]
		/local
			handle [integer!]
	][
		handle: gui/OS-make-view type text offset size parent
		handle											;@@ workaround compiler limitation
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
				obj: make-view face/type face/text face/offset face/size p
				
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
	build:	none
]
