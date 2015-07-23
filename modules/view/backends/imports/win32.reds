Red/System [
	Title:	"Windows platform GUI imports"
	Author: "Nenad Rakocevic"
	File: 	%win32.red
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define TBM_GETPOS			0400h
#define TBM_SETPOS			0405h
#define TBM_SETRANGE		0406h

#define PBM_SETPOS			0402h

#define HORZRES				8
#define VERTRES				10

#define SW_HIDE				0
#define SW_SHOW				5

#define COLOR_WINDOW		5
#define CS_VREDRAW			1
#define CS_HREDRAW			2
#define CS_DBLCLKS			8

#define CB_ADDSTRING		0143h
#define CB_GETCURSEL		0147h
#define CB_GETLBTEXT		0148h
#define CB_GETLBTEXTLEN		0149h
#define CB_SETCURSEL		014Eh

#define CBN_SELCHANGE       1
#define CBN_EDITCHANGE		5
#define CBN_SELENDOK		9
#define CBN_SELENDCANCEL	10

#define EN_CHANGE			0300h

#define CBS_DROPDOWN		0002h
#define CBS_DROPDOWNLIST	0003h
#define CBS_HASSTRINGS		0200h

#define TBS_HORZ			0000h
#define TBS_VERT			0002h
#define TBS_LEFT			0004h
#define TBS_DOWNISLEFT		0400h  	;-- Down=Left and Up=Right (default is Down=Right and Up=Left)

#define PBS_VERTICAL		04h

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
#define WS_GROUP			00020000h
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
#define BS_GROUPBOX			00000007h
#define BS_AUTORADIOBUTTON	00000009h

#define ES_LEFT				00000000h
#define SS_LEFT				00000010h
#define SS_SIMPLE			00000000h

#define WM_DESTROY			0002h
#define WM_SETTEXT			000Ch
#define WM_GETTEXT			000Dh
#define WM_GETTEXTLENGTH	000Eh
#define WM_PAINT			000Fh
#define WM_ERASEBKGND		0014h
#define WM_SETFONT			0030h
#define WM_GETFONT			0031h
#define WM_KEYDOWN			0100h
#define WM_KEYUP			0101h
#define WM_CHAR				0102h
#define WM_SYSKEYDOWN		0104h
#define WM_SYSKEYUP			0105h
#define WM_COMMAND 			0111h
#define WM_SYSCOMMAND		0112h
#define WM_TIMER			0113h
#define WM_HSCROLL			0114h
#define WM_VSCROLL			0115h
#define WM_CTLCOLOR			0019h
#define WM_CTLCOLOREDIT		0133h
#define WM_CTLCOLORLISTBOX	0134h
#define WM_CTLCOLORBTN		0135h
#define WM_CTLCOLORDLG		0136h
#define WM_CTLCOLORSCROLLBAR 0137h
#define WM_CTLCOLORSTATIC	0138h
#define WM_LBUTTONDOWN		0201h
#define WM_LBUTTONUP		0202h
#define WM_LBUTTONDBLCLK	0203h
#define WM_RBUTTONDOWN		0204h
#define WM_RBUTTONUP		0205h
#define WM_MBUTTONDOWN		0207h
#define WM_MBUTTONUP		0208h


#define BM_GETCHECK			00F0h
#define BM_SETCHECK			00F1h

#define BN_CLICKED 			0

#define BST_UNCHECKED		0
#define BST_CHECKED			1
#define BST_INDETERMINATE	2

#define VK_SPACE			20h
#define VK_PRIOR			21h
#define VK_NEXT				22h
#define VK_END				23h
#define VK_HOME				24h
#define VK_LEFT				25h
#define VK_UP				26h
#define VK_RIGHT			27h
#define VK_DOWN				28h
#define VK_SELECT			29h
#define VK_PRINT			2Ah
#define VK_EXECUTE			2Bh
#define VK_SNAPSHOT			2Ch
#define VK_INSERT			2Dh
#define VK_DELETE			2Eh
#define VK_HELP				2Fh
#define VK_LWIN				5Bh
#define VK_RWIN				5Ch
#define VK_APPS				5Dh
#define VK_F1				70h
#define VK_F2				71h
#define VK_F3				72h
#define VK_F4				73h
#define VK_F5				74h
#define VK_F6				75h
#define VK_F7				76h
#define VK_F8				77h
#define VK_F9				78h
#define VK_F10				79h
#define VK_F11				7Ah
#define VK_F12				7Bh
#define VK_F13				7Ch
#define VK_F14				7Dh
#define VK_F15				7Eh
#define VK_F16				7Fh
#define VK_F17				80h
#define VK_F18				81h
#define VK_F19				82h
#define VK_F20				83h
#define VK_F21				84h
#define VK_F22				85h
#define VK_F23				86h
#define VK_F24				87h
#define VK_PROCESSKEY		E5h

#define DEFAULT_GUI_FONT 	17

#define ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID	0004h
#define ACTCTX_FLAG_RESOURCE_NAME_VALID			0008h
#define ACTCTX_FLAG_SET_PROCESS_DEFAULT 		0010h

#define VER_NT_WORKSTATION			1
#define VER_NT_DOMAIN_CONTROLLER	2
#define VER_NT_SERVER				3

#define SWP_NOSIZE			0001h
#define SWP_NOMOVE			0002h
#define SWP_NOZORDER		0004h
#define SWP_SHOWWINDOW		0040h
#define SWP_HIDEWINDOW		0080h

#define BK_TRANSPARENT		1
#define BK_OPAQUE			2

#define DC_BRUSH			18

#define ICC_LISTVIEW_CLASSES	00000001h	;-- listview, header
#define ICC_TREEVIEW_CLASSES	00000002h	;-- treeview, tooltips
#define ICC_BAR_CLASSES			00000004h	;-- toolbar, statusbar, trackbar, tooltips
#define ICC_TAB_CLASSES			00000008h	;-- tab, tooltips
#define ICC_UPDOWN_CLASS		00000010h	;-- updown
#define ICC_PROGRESS_CLASS		00000020h	;-- progress
#define ICC_HOTKEY_CLASS		00000040h	;-- hotkey
#define ICC_ANIMATE_CLASS		00000080h	;-- animate
#define ICC_WIN95_CLASSES		000000FFh
#define ICC_DATE_CLASSES		00000100h	;--  month picker, date picker, time picker, updown
#define ICC_USEREX_CLASSES		00000200h	;-- comboex
#define ICC_COOL_CLASSES		00000400h	;-- rebar (coolbar) control
#define ICC_INTERNET_CLASSES	00000800h
#define ICC_PAGESCROLLER_CLASS	00001000h	;-- page scroller
#define ICC_NATIVEFNTCTL_CLASS	00002000h	;-- native font control
;#if (_WIN32_WINNT >= 0x0501)
#define ICC_STANDARD_CLASSES	00004000h
#define ICC_LINK_CLASS			00008000h

#define handle!				[pointer! [integer!]]

#define WIN32_LOWORD(param) (param and FFFFh)
#define WIN32_HIWORD(param) (param >>> 16)

#define IS_EXTENDED_KEY		01000000h


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
	x		[integer!]			;@@ POINT struct
	y		[integer!]	
]

wndproc-cb!: alias function! [
	hWnd	[handle!]
	msg		[integer!]
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
	szCSDVersion16		[float!]
	szCSDVersion17		[float!]
	szCSDVersion18		[float!]
	szCSDVersion19		[float!]
	szCSDVersion20		[float!]
	szCSDVersion21		[float!]
	szCSDVersion22		[float!]
	szCSDVersion23		[float!]
	szCSDVersion24		[float!]
	szCSDVersion25		[float!]
	szCSDVersion26		[float!]
	szCSDVersion27		[float!]
	szCSDVersion28		[float!]
	szCSDVersion29		[float!]
	szCSDVersion30		[float!]
	szCSDVersion31		[float!]
	wServicePack		[integer!]			;-- Major: 16, Minor: 16
	wSuiteMask0			[byte!]
	wSuiteMask1			[byte!]
	wProductType		[byte!]
	wReserved			[byte!]
]

INITCOMMONCONTROLSEX: alias struct! [
	dwSize		[integer!]
	dwICC		[integer!]
]

RECT_STRUCT: alias struct! [
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
]

#import [
	"kernel32.dll" stdcall [
		GetModuleHandle: "GetModuleHandleW" [
			lpModuleName [integer!]
			return:		 [handle!]
		]
		GetLastError: "GetLastError" [
			return: [integer!]
		]
		GetSystemDirectory: "GetSystemDirectoryW" [
			lpBuffer	[c-string!]
			uSize		[integer!]
			return:		[integer!]
		]
		CreateActCtx: "CreateActCtxW" [
			pActCtx		[ACTCTX]
			return:		[handle!]
		]
		ActivateActCtx: "ActivateActCtx" [
			hActCtx		[handle!]
			lpCookie	[struct! [ptr [byte-ptr!]]]
		]
		GetVersionEx: "GetVersionExW" [
			lpVersionInfo [OSVERSIONINFO]
			return:		[integer!]
		]
		LocalLock: "LocalLock" [
			hMem		[handle!]
			return:		[byte-ptr!]
		]
		LocalUnlock: "LocalUnlock" [
			hMem		[handle!]
			return:		[byte-ptr!]
		]
	]
	"User32.dll" stdcall [
		GetDC: "GetDC" [
			hWnd		[handle!]
			return:		[handle!]
		]
		EnumDisplayDevices: "EnumDisplayDevicesW" [
			lpDevice 	[c-string!]
			iDevNum		[integer!]
			lpDispDev	[DISPLAY_DEVICE]
			dwFlags		[integer!]
			return:		[integer!]
		]
		RegisterClassEx: "RegisterClassExW" [
			lpwcx		[WNDCLASSEX]
			return: 	[integer!]
		]
		LoadCursor: "LoadCursorW" [
			hInstance	 [handle!]
			lpCursorName [integer!]
			return: 	 [handle!]
		]
		CreateWindowEx: "CreateWindowExW" [
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
		GetParent: "GetParent" [
			hWnd 		[handle!]
			return:		[handle!]
		]
		GetWindow: "GetWindow" [
			hWnd 		[handle!]
			uCmd		[integer!]
			return:		[handle!]
		]
		WindowFromPoint: "WindowFromPoint" [
			x			[integer!]
			y			[integer!]
			return:		[handle!]
		]
		DefWindowProc: "DefWindowProcW" [
			hWnd		[handle!]
			msg			[integer!]
			wParam		[integer!]
			lParam		[integer!]
			return: 	[integer!]
		]
		CallWindowProc: "CallWindowProcW" [
			lpfnWndProc	[wndproc-cb!]
			hWnd		[handle!]
			msg			[integer!]
			wParam		[integer!]
			lParam		[integer!]
			return: 	[integer!]
		]
		GetMessage: "GetMessageW" [
			msg			[tagMSG]
			hWnd		[handle!]
			wParam		[integer!]
			lParam		[integer!]
			return: 	[integer!]
		]
		TranslateMessage: "TranslateMessage" [
			msg			[tagMSG]
			return: 	[logic!]
		]
		DispatchMessage: "DispatchMessageW" [
			msg			[tagMSG]
			return: 	[integer!]
		]
		PostQuitMessage: "PostQuitMessage" [
			nExitCode	[integer!]
		]
		SendMessage: "SendMessageW" [
			hWnd		[handle!]
			msg			[integer!]
			wParam		[integer!]
			lParam		[integer!]
			return: 	[handle!]
		]
		GetMessagePos: "GetMessagePos" [
			return:		[integer!]
		]
		SetWindowLong: "SetWindowLongW" [
			hWnd		[handle!]
			nIndex		[integer!]
			dwNewLong	[integer!]
			return: 	[integer!]
		]
		GetWindowLong: "GetWindowLongW" [
			hWnd		[handle!]
			nIndex		[integer!]
			return: 	[integer!]
		]
		GetClassInfoEx: "GetClassInfoExW" [
			hInst		[integer!]
			lpszClass	[c-string!]
			lpwcx		[WNDCLASSEX]					;-- pass a WNDCLASSEX pointer's pointer
			return: 	[integer!]
		]
		GetClientRect: "GetClientRect" [
			hWnd		[handle!]
			lpRect		[RECT_STRUCT]
			return:		[integer!]
		]
		FillRect: "FillRect" [
			hDC			[handle!]
			lprc		[RECT_STRUCT]
			hbr			[handle!]
			return:		[integer!]
		]
		SetWindowPos: "SetWindowPos" [
			hWnd		[handle!]
			hWndAfter	[handle!]
			X			[integer!]
			Y			[integer!]
			cx			[integer!]
			cy			[integer!]
			uFlags		[integer!]
			return:		[integer!]
		]
		SetWindowText: "SetWindowTextW" [
			hWnd		[handle!]
			lpString	[c-string!]
		]
		GetWindowText: "GetWindowTextW" [
			hWnd		[handle!]
			lpString	[c-string!]
			nMaxCount	[integer!]
			return:		[integer!]
		]
		GetWindowTextLength: "GetWindowTextLengthW" [
			hWnd		[handle!]
			return:		[integer!]
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
		SetBkMode: "SetBkMode" [
			hdc			[handle!]
			iBkMode		[integer!]
			return:		[integer!]
		]
		TextOut: "TextOutW" [
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
		CreateSolidBrush: "CreateSolidBrush" [
			crColor		[integer!]
			return:		[handle!]
		]
		SetDCBrushColor: "SetDCBrushColor" [
			hdc			[handle!]
			crColor		[integer!]					;-- 0x00bbggrr
			return:		[integer!]					;-- 0x00bbggrr
		]
		DeleteObject: "DeleteObject" [
			hObject		[handle!]
			return:		[integer!]
		]
	]
	"gdiplus.dll" stdcall [
		GdipDrawImageRectI: "GdipDrawImageRectI" [
			graphics	[integer!]
			image		[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			return:		[integer!]
		]
		GdipCreateFromHWND: "GdipCreateFromHWND" [
			hwnd		[handle!]
			graphics	[GpGraphics!]
			return:		[integer!]
		]
	]
	"Comctl32.dll" stdcall [
		InitCommonControlsEx: "InitCommonControlsEx" [
			lpInitCtrls [INITCOMMONCONTROLSEX]
			return:		[integer!]
		]
		InitCommonControls: "InitCommonControls" []
	]
	"UxTheme.dll" stdcall [
		SetWindowTheme: "SetWindowTheme" [
			hWnd		[handle!]
			appname		[c-string!]
			subIdList	[integer!]
		]
	]
]