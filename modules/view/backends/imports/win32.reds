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
#define WM_KEYDOWN			0100h
#define WM_KEYUP			0101h
#define WM_CHAR				0102h
#define WM_COMMAND 			0111h
#define WM_LBUTTONDOWN		0201h
#define WM_LBUTTONUP		0202h
#define WM_RBUTTONDOWN		0204h
#define WM_RBUTTONUP		0205h
#define WM_MBUTTONDOWN		0207h
#define WM_MBUTTONUP		0208h


#define BM_GETCHECK			F0F0h
#define BM_SETCHECK			F0F1h

#define BN_CLICKED 			0

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

#define DEFAULT_GUI_FONT 	17

#define ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID	0004h
#define ACTCTX_FLAG_RESOURCE_NAME_VALID			0008h
#define ACTCTX_FLAG_SET_PROCESS_DEFAULT 		0010h

#define VER_NT_WORKSTATION			1
#define VER_NT_DOMAIN_CONTROLLER	2
#define VER_NT_SERVER				3

#define GWL_USERDATA        -21

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
	pt		[tagPOINT]			;@@ POINT struct
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
	wServicePack		[integer!]			;-- Major: 16, Minor: 16
	wSuiteMask0			[byte!]
	wSuiteMask1			[byte!]
	wProductType		[byte!]
	wReserved			[byte!]
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
			msg			[integer!]
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
		SetWindowLong: "SetWindowLongA" [
			hWnd		[handle!]
			nIndex		[integer!]
			dwNewLong	[integer!]
			return: 	[handle!]
		]
		GetWindowLong: "GetWindowLongA" [
			hWnd		[handle!]
			nIndex		[integer!]
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