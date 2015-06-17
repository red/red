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

#system [

	gui: context [
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

		#define BS_DEFPUSHBUTTON	00000001h
		#define BS_CHECKBOX			00000002h
		#define BS_RADIOBUTTON		00000004h
		
		#define ES_LEFT				00000000h
		#define SS_LEFT				00000010h
		#define SS_SIMPLE			00000000h

		#define WM_DESTROY			0002h
		#define WM_PAINT			000Fh
		#define WM_SETFONT			0030h
		#define WM_GETFONT			0031h
		

		#define handle!				[pointer! [integer!]]

		GUIConClass:  "RedGUIConsole"
		ConEditClass: "RedConEdit"

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

		#import [
			"kernel32.dll" stdcall [
				GetModuleHandle: "GetModuleHandleA" [
					lpModuleName [integer!]
					return:		 [handle!]
				]
				GetLastError: "GetLastError" [
					return: [integer!]
				]
			]
			"User32.dll" stdcall [
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
			]
			"gdi32.dll" stdcall [
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
			]
			"UxTheme.dll" stdcall [
				SetWindowTheme: "SetWindowTheme" [
					hWnd		[handle!]
					appname		[c-string!]
					subIdList	[integer!]
				]
			]
		]

		WndProc: func [
			hWnd	[handle!]
			msg		[tagMSG]
			wParam	[integer!]
			lParam	[integer!]
			return: [integer!]
		][
			switch msg [
				WM_PAINT [
					DefWindowProc hWnd msg wParam lParam
				]
				WM_DESTROY [PostQuitMessage 0]
				default    [return DefWindowProc hWnd msg wParam lParam]
			]
			0
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
			wcex/lpszClassName: GUIConClass
			wcex/hIconSm:		0

			RegisterClassEx wcex
		]

		create-window: func [
			hInstance [handle!]
		][
			hWnd: CreateWindowEx
				WS_EX_COMPOSITED
				GUIConClass
				"Red View"
				WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN
				CW_USEDEFAULT
				0
				600
				400
				null
				null
				hInstance
				null
		]

		init: does [
			hInstance: GetModuleHandle 0
			register-classes hInstance
			create-window hInstance

			ShowWindow hWnd  SW_SHOWDEFAULT
			UpdateWindow hWnd
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
		][
			flags: 	  0
			ws-flags: 0
			sym: 	  symbol/resolve type/symbol
			
			case [
				sym = button [
					class: "BUTTON"
					flags: WS_TABSTOP or BS_DEFPUSHBUTTON
				]
				sym = check [
					class: "BUTTON"
					flags: WS_TABSTOP or BS_CHECKBOX
				]
				sym = radio [
					class: "BUTTON"
					flags: WS_TABSTOP or BS_RADIOBUTTON
				]
				sym = field [
					class: "EDIT"
					flags: ES_LEFT
					ws-flags: WS_TABSTOP or WS_EX_CLIENTEDGE
				]
				sym = text [
					class: "STATIC"
					flags: SS_SIMPLE
				]
			]
			
			if zero? parent [parent: as-integer hWnd]
			
			caption: either TYPE_OF(str) = TYPE_STRING [
				as-c-string string/rs-head str
			][
				null
			]
			
			handle: CreateWindowEx
				WS_EX_COMPOSITED or ws-flags
				class
				caption
				WS_VISIBLE or WS_CHILD or flags
				offset/x
				offset/y
				size/x
				size/y
				as int-ptr! parent
				null
				hInstance
				null
					
			if null? handle [print-line "*** Error: CreateWindowEx failed!"]
			as-integer handle
		]

		hInstance:	declare handle!
		hdc: 		declare handle!
		hWnd:		declare handle!
		msg:		declare tagMSG

		init
		do-events yes
		;SetWindowTheme hWnd "Explorer" 0

		button:		symbol/make "button"
		check:		symbol/make "check"
		radio:		symbol/make "radio"
		field:		symbol/make "field"
		text:		symbol/make "text"
	]
]

dpi: 94
screen-size: 1920x1200
window-size: 600x400

make-view: routine [
	type	[word!]
	text	[string!]
	offset	[pair!]
	size	[pair!]
	parent	[integer!]
	return: [integer!]
][
	gui/OS-make-view type text offset size parent
]


do-event-loop: routine [no-wait? [logic!]][
	print-line "do-event-loop"
	gui/do-events no-wait?
]

;set-font-size: routine [
;	handle [integer!]
;	size   [integer!]
;	/local
;		font [handle!]
;][
;	font: gui/SendMessage as int-ptr! handle WM_GETFONT 0 0
;?? font
;	unless null? font [
;		0
;	]
;]


show: func [face [block!] /with parent [block!] /local obj f params][
	either face/state/1 [
	
	][
		switch face/type [
			screen [
				;lay: java-new [android.widget.AbsoluteLayout activity-obj]
			]
			button [
				;#system [gui/create-view]
				obj: make-view 'button face/text face/offset face/size 0
			]
			text [
				obj: make-view 'text face/text face/offset face/size 0
			]
			field [
				obj: make-view 'field face/text face/offset face/size 0
			]
			check [
				obj: make-view 'check face/text face/offset face/size 0
			]
			radio [
				obj: make-view 'radio face/text face/offset face/size 0
			]
			toggle [
				;obj: java-new [android.widget.ToggleButton activity-obj]
			]
			clock [
				;obj: java-new [android.widget.AnalogClock activity-obj]
			]
			;calendar [
			;	obj: java-new [android.widget.CalendarView activity-obj]
			;]
		]
;		if obj [set-font-size obj 8]
comment {
		if face/type <> 'screen [
			java-do [obj/setText any [face/text ""]]
			
			params: java-new [
				"android/widget/AbsoluteLayout$LayoutParams"
				face/size/x
				face/size/y
				face/offset/x
				face/offset/y
			]
			java-do [lay/addView obj params]
		]
		face/state: obj
}
	]
	if face/pane [foreach f face/pane [show/with f face]]
]

do-events: func [/no-wait][
	do-event-loop no
]

;obj: make-view 'button "Hello" 10x10 80x40 0
;if obj [set-font-size obj 8]
