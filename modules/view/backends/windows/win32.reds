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

#define TPM_RETURNCMD		0100h

#define LB_ADDSTRING		0180h
#define LB_INSERTSTRING		0181h
#define LB_DELETESTRING		0182h
#define LB_RESETCONTENT		0184h
#define LB_GETCURSEL		0188h
#define LB_SETHORIZONTALEXTENT	0194h

#define HORZRES				8
#define VERTRES				10

#define SW_HIDE				0
#define SW_SHOW				5

#define COLOR_BACKGROUND	1
#define COLOR_MENU			4
#define COLOR_WINDOW		5
#define COLOR_3DFACE		15

#define CS_VREDRAW			1
#define CS_HREDRAW			2
#define CS_DBLCLKS			8

#define CB_ADDSTRING		0143h
#define CB_DELETESTRING		0144h
#define CB_GETCOUNT			0146h
#define CB_GETCURSEL		0147h
#define CB_GETLBTEXT		0148h
#define CB_GETLBTEXTLEN		0149h
#define CB_INSERTSTRING		014Ah
#define CB_RESETCONTENT		014Bh
#define CB_SETCURSEL		014Eh
#define CB_SETHORIZONTALEXTENT 015Eh

#define CBN_SELCHANGE       1
#define CBN_EDITCHANGE		5
#define CBN_SELENDOK		9
#define CBN_SELENDCANCEL	10

#define LBN_SELCHANGE       1
#define LBN_DBLCLK          2

#define EN_CHANGE			0300h

#define TCN_SELCHANGE       -551
#define TCN_SELCHANGING		-552

#define CBS_DROPDOWN		0002h
#define CBS_DROPDOWNLIST	0003h
#define CBS_HASSTRINGS		0200h

#define TBS_HORZ			0000h
#define TBS_VERT			0002h
#define TBS_LEFT			0004h
#define TBS_DOWNISLEFT		0400h						;-- Down=Left and Up=Right (default is Down=Right and Up=Left)

#define LBS_NOTIFY			1
#define LBS_MULTIPLESEL		8
#define LBS_SORT			2

#define PBS_VERTICAL		04h

#define TCM_DELETEITEM		1308h
#define TCM_GETCURSEL		130Bh
#define TCM_SETCURSEL		130Ch
#define TCM_INSERTITEMW		133Eh
#define TCM_ADJUSTRECT		1328h

#define TCIF_TEXT			0001h

#define MIIM_STATE			0001h
#define MIIM_ID				0002h
#define MIIM_SUBMENU		0004h
#define MIIM_CHECKMARKS		0008h
#define MIIM_TYPE			0010h
#define MIIM_DATA			0020h
#define MIIM_STRING			0040h
#define MIIM_BITMAP			0080h
#define MIIM_FTYPE			0100h

#define MFT_STRING			00000000h
#define MFT_BITMAP			00000004h
#define MFT_MENUBARBREAK	00000020h
#define MFT_MENUBREAK		00000040h
;#define MFT_OWNERDRAW		MF_OWNERDRAW
#define MFT_RADIOCHECK		00000200h
#define MFT_SEPARATOR		00000800h
#define MFT_RIGHTORDER		00002000h
#define MFT_RIGHTJUSTIFY	00004000h

#define MNS_NOCHECK			80000000h
#define MNS_MODELESS		40000000h
#define MNS_DRAGDROP		20000000h
#define MNS_AUTODISMISS		10000000h
#define MNS_NOTIFYBYPOS		08000000h
#define MNS_CHECKORBMP		04000000h

#define IDC_ARROW			7F00h

#define CW_USEDEFAULT		80000000h

#define WS_OVERLAPPEDWINDOW	00CF0000h
#define WS_CLIPCHILDREN		02000000h
#define WS_EX_ACCEPTFILES	00000010h
#define WS_CHILD			40000000h
#define WS_VISIBLE			10000000h
#define WS_EX_COMPOSITED	02000000h
#define WS_HSCROLL			00100000h
#define WS_VSCROLL			00200000h
#define WS_EX_LAYERED 		00080000h
#define WS_TABSTOP			00010000h
#define WS_EX_TRANSPARENT	00000020h
#define WS_EX_CLIENTEDGE	00000200h
#define WS_GROUP			00020000h
#define WS_BORDER			00400000h
#define WS_CLIPSIBLINGS 	04000000h

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

#define ES_LEFT             00000000h
#define ES_CENTER           00000001h
#define ES_RIGHT            00000003h
#define ES_MULTILINE        00000004h
#define ES_AUTOVSCROLL      00000040h
#define ES_AUTOHSCROLL      00000080h
#define SS_LEFT				00000010h
#define SS_SIMPLE			00000000h

#define WM_DESTROY			0002h
#define WM_CLOSE			0010h
#define WM_SETTEXT			000Ch
#define WM_GETTEXT			000Dh
#define WM_GETTEXTLENGTH	000Eh
#define WM_PAINT			000Fh
#define WM_ERASEBKGND		0014h
#define WM_CTLCOLOR			0019h
#define WM_SETFONT			0030h
#define WM_GETFONT			0031h
#define WM_NOTIFY			004Eh
#define WM_CONTEXTMENU		007Bh
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
#define WM_INITMENU			0116h
#define WM_MENUSELECT		011Fh
#define WM_MENUCOMMAND		0126h
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
#define WM_ENTERMENULOOP	0211h

#define WM_CAP_DRIVER_CONNECT		040Ah
#define WM_CAP_DRIVER_DISCONNECT	040Bh
#define WM_CAP_EDIT_COPY			041Eh
#define WM_CAP_GRAB_FRAME			043Ch
#define WM_CAP_SET_SCALE			0435h
#define WM_CAP_SET_PREVIEWRATE		0434h
#define WM_CAP_SET_PREVIEW			0432h
#define WM_CAP_DLG_VIDEOSOURCE		042Ah
#define WM_CAP_STOP					0444h

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
#define SWP_NOACTIVATE		0010h
#define SWP_SHOWWINDOW		0040h
#define SWP_HIDEWINDOW		0080h

#define BK_TRANSPARENT		1
#define BK_OPAQUE			2

#define NULL_BRUSH          5
#define DC_BRUSH			18
#define DC_PEN              19

#define BS_SOLID			0

#define PS_SOLID			0
#define PS_DASH				1							; -------
#define PS_DOT				2							; .......
#define PS_DASHDOT			3							; _._._._
#define PS_DASHDOTDOT		4							; _.._.._

#define PS_ALTERNATE		8
#define PS_STYLE_MASK		0000000Fh

#define PS_ENDCAP_ROUND		00000000h
#define PS_ENDCAP_SQUARE	00000100h
#define PS_ENDCAP_FLAT		00000200h
#define PS_ENDCAP_MASK		00000F00h

#define PS_JOIN_ROUND		00000000h
#define PS_JOIN_BEVEL		00001000h
#define PS_JOIN_MITER		00002000h
#define PS_JOIN_MASK		0000F000h

#define PS_COSMETIC			00000000h
#define PS_GEOMETRIC		00010000h
#define PS_TYPE_MASK		000F0000h

#define GDIPLUS_LINECAPFLAT			0
#define GDIPLUS_LINECAPSQUARE		1
#define GDIPLUS_LINECAPROUND		2

#define GDIPLUS_MITER				0
#define GDIPLUS_BEVEL				1
#define GDIPLUS_ROUND				2
#define GDIPLUS_MITERCLIPPED		3

#define	GDIPLUS_HIGHSPPED			1
#define	GDIPLUS_ANTIALIAS			4
#define GDIPLUS_UNIT_WORLD			0
#define GDIPLUS_UNIT_DISPLAY		1
#define GDIPLUS_UNIT_PIXEL			2
#define GDIPLUS_UNIT_POINT			3
#define GDIPLUS_UNIT_INCH			4
#define GDIPLUS_FILLMODE_ALTERNATE	0
#define GDIPLUS_FILLMODE_WINDING	1

#define SRCCOPY             00CC0020h

#define ICC_LISTVIEW_CLASSES	00000001h				;-- listview, header
#define ICC_TREEVIEW_CLASSES	00000002h				;-- treeview, tooltips
#define ICC_BAR_CLASSES			00000004h				;-- toolbar, statusbar, trackbar, tooltips
#define ICC_TAB_CLASSES			00000008h				;-- tab, tooltips
#define ICC_UPDOWN_CLASS		00000010h				;-- updown
#define ICC_PROGRESS_CLASS		00000020h				;-- progress
#define ICC_HOTKEY_CLASS		00000040h				;-- hotkey
#define ICC_ANIMATE_CLASS		00000080h				;-- animate
#define ICC_WIN95_CLASSES		000000FFh
#define ICC_DATE_CLASSES		00000100h				;-- month picker, date picker, time picker, updown
#define ICC_USEREX_CLASSES		00000200h				;-- comboex
#define ICC_COOL_CLASSES		00000400h				;-- rebar (coolbar) control
#define ICC_INTERNET_CLASSES	00000800h
#define ICC_PAGESCROLLER_CLASS	00001000h				;-- page scroller
#define ICC_NATIVEFNTCTL_CLASS	00002000h				;-- native font control
;#if (_WIN32_WINNT >= 0x0501)
#define ICC_STANDARD_CLASSES	00004000h
#define ICC_LINK_CLASS			00008000h

#define handle!				[pointer! [integer!]]

#define WIN32_LOWORD(param) (param and FFFFh)
#define WIN32_HIWORD(param) (param >>> 16)

#define IS_EXTENDED_KEY		01000000h

#define AD_CLOCKWISE		2
#define ANSI_FIXED_FONT		11
#define SYSTEM_FONT			13
#define ETO_CLIPPED			4

tagPOINT: alias struct! [
	x		[integer!]
	y		[integer!]	
]

tagSIZE: alias struct! [
	width	[integer!]
	height	[integer!]
]

tagMSG: alias struct! [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	time	[integer!]
	x		[integer!]									;@@ POINT struct
	y		[integer!]	
]

tagLOGBRUSH: alias struct! [
	lbStyle [integer!]
	lbColor [integer!]
	lbHatch [integer!]
]

tagPAINTSTRUCT: alias struct! [
	hdc			 [integer!]
	fErase		 [integer!]
	left		 [integer!]
	top			 [integer!]
	right		 [integer!]
	bottom		 [integer!]
	fRestore	 [integer!]
	fIncUpdate	 [integer!]
	rgbReserved1 [integer!]
	rgbReserved2 [integer!]
	rgbReserved3 [integer!]
	rgbReserved4 [integer!]
	rgbReserved5 [integer!]
	rgbReserved6 [integer!]
	rgbReserved7 [integer!]
	rgbReserved8 [integer!]
]

tagNMHDR: alias struct! [
	hWndFrom	 [handle!]
	idFrom		 [integer!]
	code		 [integer!]
]

tagBLENDFUNCTION: alias struct! [
	BlendOp				[byte!]
	BlendFlags			[byte!]
	SourceConstantAlpha	[byte!]
	AlphaFormat			[byte!]
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
	lpSource	[c-string!]								;-- wide-string
	wProcLangID	[integer!]								;-- combined wProc and wLangID in one field
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
	szCSDVersion		[byte-ptr!]						;-- array of 128 bytes
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
	wServicePack		[integer!]						;-- Major: 16, Minor: 16
	wSuiteMask0			[byte!]
	wSuiteMask1			[byte!]
	wProductType		[byte!]
	wReserved			[byte!]
]

INITCOMMONCONTROLSEX: alias struct! [
	dwSize		[integer!]
	dwICC		[integer!]
]

TCITEM: alias struct! [
	mask		[integer!]
	dwState		[integer!]
	dwStateMask	[integer!]
	pszText		[c-string!]
	cchTextMax	[integer!]
	iImage		[integer!]
	lParam		[integer!]
]

MENUITEMINFO: alias struct! [
	cbSize		[integer!]
	fMask		[integer!]
	fType		[integer!]
	fState		[integer!]
	wID			[integer!]
	hSubMenu	[handle!]
	hbmpChecked	[handle!]
	hbmpUnchecked [handle!]
	dwItemData	[integer!]
	dwTypeData	[c-string!]
	cch			[integer!]
	hbmpItem	[handle!]
]

RECT_STRUCT: alias struct! [
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
]

RECT_STRUCT_FLOAT32: alias struct! [
	x			[float32!]
	y			[float32!]
	width		[float32!]
	height		[float32!]
]

InitCommonControlsEx!: alias function! [
	lpInitCtrls [INITCOMMONCONTROLSEX]
	return:		[integer!]
]

DwmIsCompositionEnabled!: alias function! [
	pfEnabled	[int-ptr!]
	return:		[integer!]
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
			return:		[integer!]
		]
		DeactivateActCtx: "DeactivateActCtx" [
			dwFlags		[integer!]
			Cookie		[byte-ptr!]
			return:		[integer!]
		]
		ReleaseActCtx: "ReleaseActCtx" [
			hActCtx		[handle!]
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
		LoadLibraryEx: "LoadLibraryExW" [
			lpFileName	[c-string!]
			hFile		[integer!]
			dwFlags		[integer!]
			return:		[handle!]
		]
		GetProcAddress: "GetProcAddress" [
			hModule		[handle!]
			lpProcName	[c-string!]
			return:		[integer!]
		]
	]
	"User32.dll" stdcall [
		GetDC: "GetDC" [
			hWnd		[handle!]
			return:		[handle!]
		]
		ReleaseDC: "ReleaseDC" [
			hWnd		[handle!]
			hDC			[handle!]
			return:		[integer!]
		]
		BeginPaint: "BeginPaint" [
			hWnd		[handle!]
			ps			[tagPAINTSTRUCT]
			return:		[handle!]
		]
		EndPaint: "EndPaint" [
			hWnd		[handle!]
			ps			[tagPAINTSTRUCT]
			return:		[integer!]
		]
		MapWindowPoints: "MapWindowPoints" [
			hWndFrom	[handle!]
			hWndTo		[handle!]
			lpPoints	[tagPOINT]
			cPoint		[integer!]
			return:		[integer!]
		]
		GetSysColorBrush: "GetSysColorBrush" [
			index		[integer!]
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
		InvalidateRect: "InvalidateRect" [
			hWnd		[handle!]
			lpRect		[RECT_STRUCT]
			bErase		[integer!]
			return:		[integer!]
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
			hInst		[handle!]
			lpszClass	[c-string!]
			lpwcx		[WNDCLASSEX]					;-- pass a WNDCLASSEX pointer's pointer
			return: 	[integer!]
		]
		GetWindowRect: "GetWindowRect" [
			hWnd		[handle!]
			lpRect		[RECT_STRUCT]
			return:		[integer!]
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
		BringWindowToTop: "BringWindowToTop" [
			hWnd		[handle!]
			return:		[logic!]
		]
		BeginDeferWindowPos: "BeginDeferWindowPos" [
			nNumWindows [integer!]
			return:		[handle!]
		]
		EndDeferWindowPos: "EndDeferWindowPos" [
			hWinPosInfo [handle!]
			return:		[logic!]
		]
		DeferWindowPos: "DeferWindowPos" [
			hWinPosInfo [handle!]
			hWnd		[handle!]
			hWndAfter	[handle!]
			x			[integer!]
			y			[integer!]
			cx			[integer!]
			cy			[integer!]
			uFlags		[integer!]
			return:		[handle!]
		]
		SetWindowPos: "SetWindowPos" [
			hWnd		[handle!]
			hWndAfter	[handle!]
			x			[integer!]
			y			[integer!]
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
		CreateMenu: "CreateMenu" [
			return:		[handle!]
		]
		CreatePopupMenu: "CreatePopupMenu" [
			return:		[handle!]
		]
		InsertMenuItem: "InsertMenuItemW" [
			hMenu		[handle!]
			uItem		[integer!]
			byPosition	[logic!]
			lpmii		[MENUITEMINFO]
			return:		[logic!]
		]
		GetMenuItemInfo: "GetMenuItemInfoW" [
			hMenu		[handle!]
			uItem		[integer!]
			byPosition	[logic!]
			lpmii		[MENUITEMINFO]
			return:		[logic!]
		]
		TrackPopupMenuEx: "TrackPopupMenuEx" [
			hMenu		[handle!]
			fuFlags		[integer!]
			x			[integer!]
			y			[integer!]
			hWnd		[handle!]
			lptpm		[byte-ptr!]						;-- null (LPTPMPARAMS)
			return:		[integer!]
		]
		ClientToScreen: "ClientToScreen" [
			hWnd		[handle!]
			lpPoint		[tagPOINT]
			return:		[logic!]
		]
		SetParent: "SetParent" [
			hChild		[handle!]
			hNewParent	[handle!]
			return:		[handle!]						;-- old parent
		]
		DestroyMenu: "DestroyMenu" [
			hMenu		[handle!]
			return:		[logic!]
		]
		SetMenu: "SetMenu" [
			hWnd		[handle!]
			hMenu		[handle!]
			return:		[logic!]
		]
		GetMenu: "GetMenu" [
			hWnd		[handle!]
			return:		[handle!]
		]
		DestroyWindow: "DestroyWindow" [
			hWnd		[handle!]
			return:		[logic!]
		]
		LoadIcon: "LoadIconW" [
			hInstance	[handle!]
			lpIconName	[c-string!]
			return:		[handle!]
		]
	]
	"gdi32.dll" stdcall [
		ExtTextOut: "ExtTextOutW" [
			hdc			[handle!]
			X			[integer!]
			Y			[integer!]
			fuOptions	[integer!]
			lprc		[RECT_STRUCT]
			lpString	[c-string!]
			cbCount		[integer!]						;-- count of characters
			lpDx		[int-ptr!]
		]	
		GetTextExtentPoint32: "GetTextExtentPoint32W" [
			hdc			[handle!]
			lpString	[c-string!]
			len			[integer!]
			lpSize		[tagSIZE]
			return:		[integer!]
		]
		CreateCompatibleDC: "CreateCompatibleDC" [
			hDC			[handle!]
			return:		[handle!]
		]
		CreateCompatibleBitmap: "CreateCompatibleBitmap" [
			hDC			[handle!]
			width		[integer!]
			height		[integer!]
			return:		[handle!]
		]
		DeleteDC: "DeleteDC" [
			hdc			[handle!]
			return:		[integer!]
		]
		BitBlt: "BitBlt" [
			hdcDest		[handle!]
			nXDest		[integer!]
			nYDest		[integer!]
			nWidth		[integer!]
			nHeight		[integer!]
			hdcSrc		[handle!]
			nXSrc		[integer!]
			nYSrc		[integer!]
			dwRop		[integer!]
			return:		[integer!]
		]
		SelectObject: "SelectObject" [
			hDC			[handle!]
			hgdiobj		[handle!]
			return:		[handle!]
		]
		GetDeviceCaps: "GetDeviceCaps" [
			hDC			[handle!]
			nIndex		[integer!]
			return:		[integer!]
		]
		SetTextColor: "SetTextColor" [
			hdc			[handle!]
			crColor		[integer!]						;-- 0x00bbggrr
			return:		[integer!]						;-- 0x00bbggrr
		]
		SetBkColor: "SetBkColor" [
			hdc			[handle!]
			crColor		[integer!]						;-- 0x00bbggrr
			return:		[integer!]						;-- 0x00bbggrr
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
		SetBrushOrgEx: "SetBrushOrgEx" [
			hdc			[handle!]
			nXOrg		[integer!]
			nYOrg		[integer!]
			lppt		[tagPOINT]
			return:		[integer!]
		]
		MoveToEx: "MoveToEx" [
			hdc			[handle!]
			X			[integer!]
			Y			[integer!]
			lpPoint		[tagPOINT]
			return:		[logic!]
		]
		LineTo: "LineTo" [
			hdc			[handle!]
			nXEnd		[integer!]
			nYEnd		[integer!]
			return:		[logic!]
		]
		ExtCreatePen: "ExtCreatePen" [
			dwPenStyle		[integer!]
			dwWidth			[integer!]
			lplb			[tagLOGBRUSH]
			dwStyleCount	[integer!]
			lpStyle			[int-ptr!]
			return:			[handle!]
		]
		CreatePen: "CreatePen" [
			fnPenStyle	[integer!]
			nWidth		[integer!]
			crColor		[integer!]
			return:		[handle!]
		]
		SetDCPenColor: "SetDCPenColor" [
			hdc			[handle!]
			crColor		[integer!]					;-- 0x00bbggrr
			return:		[integer!]					;-- 0x00bbggrr
		]
		Rectangle: "Rectangle" [
			hdc			[handle!]
			nLeftRect	[integer!]
			nTopRect	[integer!]
			nRightRect	[integer!]
			nBottomRect	[integer!]
			return:		[logic!]
		]
		RoundRect: "RoundRect" [
			hdc			[handle!]
			nLeftRect	[integer!]
			nTopRect	[integer!]
			nRightRect	[integer!]
			nBottomRect	[integer!]
			nWidth		[integer!]
			nHeight		[integer!]
			return:		[logic!]
		]
		Polyline: "Polyline" [
			hdc			[handle!]
			lppt		[tagPOINT]
			cPoints		[integer!]
			return:		[logic!]
		]
		Polygon: "Polygon" [
			hdc			[handle!]
			lppt		[tagPOINT]
			cPoints		[integer!]
			return:		[logic!]
		]
		Ellipse: "Ellipse" [
			hdc			[handle!]
			nLeftRect	[integer!]
			nTopRect	[integer!]
			nRightRect	[integer!]
			nBottomRect	[integer!]
			return:		[logic!]
		]
		Arc: "Arc" [
			hdc			[handle!]
			nLeftRect	[integer!]
			nTopRect	[integer!]
			nRightRect	[integer!]
			nBottomRect	[integer!]
			nXStartArc	[integer!]
			nYStartArc	[integer!]
			nXEndArc	[integer!]
			nYEndArc	[integer!]
			return:		[logic!]
		]
		Chord: "Chord" [
			hdc			[handle!]
			nLeftRect	[integer!]
			nTopRect	[integer!]
			nRightRect	[integer!]
			nBottomRect	[integer!]
			nXStartArc	[integer!]
			nYStartArc	[integer!]
			nXEndArc	[integer!]
			nYEndArc	[integer!]
			return:		[logic!]
		]
		Pie: "Pie" [
			hdc			[handle!]
			nLeftRect	[integer!]
			nTopRect	[integer!]
			nRightRect	[integer!]
			nBottomRect	[integer!]
			nXStartArc	[integer!]
			nYStartArc	[integer!]
			nXEndArc	[integer!]
			nYEndArc	[integer!]
			return:		[logic!]
		]
		SetArcDirection: "SetArcDirection" [
			hdc			[handle!]
			direction	[integer!]
			return:		[integer!]
		]
		PolyBezier: "PolyBezier" [
			hdc			[handle!]
			lppt		[tagPOINT]
			cPoints		[integer!]
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
		GdipCreateFromHDC: "GdipCreateFromHDC" [
			hDC			[handle!]
			graphics	[GpGraphics!]
			return:		[integer!]
		]
		GdipDeleteGraphics: "GdipDeleteGraphics" [
			graphics	[integer!]
			return:		[integer!]
		]
		GdipSetSmoothingMode: "GdipSetSmoothingMode" [
			graphics	[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		GdipCreatePen1: "GdipCreatePen1" [
			color		[integer!]
			width		[float32!]
			unit		[integer!]
			pen-ptr		[int-ptr!]
			return:		[integer!]
		]
		GdipDeletePen: "GdipDeletePen" [
			pen			[integer!]
			return:		[integer!]
		]
		GdipDrawLinesI: "GdipDrawLinesI" [
			graphics	[integer!]
			pen			[integer!]
			points		[tagPOINT]
			count		[integer!]
			return:		[integer!]
		]
		GdipDrawRectangleI: "GdipDrawRectangleI" [
			graphics	[integer!]
			pen			[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			return:		[integer!]
		]
		GdipFillRectangleI: "GdipFillRectangleI" [
			graphics	[integer!]
			pen			[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			return:		[integer!]
		]
		GdipCreateSolidFill: "GdipCreateSolidFill" [
			color		[integer!]
			brush-ptr	[int-ptr!]
			return:		[integer!]
		]
		GdipDeleteBrush: "GdipDeleteBrush" [
			brush		[integer!]
			return:		[integer!]
		]
		GdipDrawPolygonI: "GdipDrawPolygonI" [
			graphics	[integer!]
			pen			[integer!]
			points		[tagPOINT]
			count		[integer!]
			return:		[integer!]
		]
		GdipFillPolygonI: "GdipFillPolygonI" [
			graphics	[integer!]
			brush		[integer!]
			points		[tagPOINT]
			count		[integer!]
			fillMode	[integer!]
			return:		[integer!]
		]
		GdipDrawEllipseI: "GdipDrawEllipseI" [
			graphics	[integer!]
			pen			[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			return:		[integer!]
		]
		GdipFillEllipseI: "GdipFillEllipseI" [
			graphics	[integer!]
			brush		[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			return:		[integer!]
		]
		GdipDrawPath: "GdipDrawPath" [
			graphics	[integer!]
			pen			[integer!]
			path		[integer!]
			return:		[integer!]
		]
		GdipFillPath: "GdipFillPath" [
			graphics	[integer!]
			brush		[integer!]
			path		[integer!]
			return:		[integer!]
		]
		GdipCreatePath: "GdipCreatePath" [
			fillMode	[integer!]
			path-ptr	[int-ptr!]
			return:		[integer!]
		]
		GdipDeletePath: "GdipDeletePath" [
			path		[integer!]
			return:		[integer!]
		]
		GdipResetPath: "GdipResetPath" [
			path		[integer!]
			return:		[integer!]
		]
		GdipStartPathFigure: "GdipStartPathFigure" [
			path		[integer!]
			return:		[integer!]
		]
		GdipClosePathFigure: "GdipClosePathFigure" [
			path		[integer!]
			return:		[integer!]
		]
		GdipAddPathArcI: "GdipAddPathArcI" [
			path		[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			startAngle	[float32!]
			sweepAngle	[float32!]
			return:		[integer!]
		]
		GdipDrawArcI: "GdipDrawArcI" [
			graphics	[integer!]
			pen			[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			startAngle	[float32!]
			sweepAngle	[float32!]
			return:		[integer!]
		]
		GdipDrawPieI: "GdipDrawPieI" [
			graphics	[integer!]
			pen			[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			startAngle	[float32!]
			sweepAngle	[float32!]
			return:		[integer!]
		]
		GdipFillPieI: "GdipFillPieI" [
			graphics	[integer!]
			brush		[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			startAngle	[float32!]
			sweepAngle	[float32!]
			return:		[integer!]
		]
		GdipDrawString: "GdipDrawString" [
			graphics	[integer!]
			text		[c-string!]
			lenght		[integer!]
			font		[integer!]
			layoutRect	[RECT_STRUCT_FLOAT32]
			format		[integer!]
			brush		[integer!]
			return:		[integer!]
		]
		GdipDrawBeziersI: "GdipDrawBeziersI" [
			graphics	[integer!]
			pen			[integer!]
			points		[tagPOINT]
			count		[integer!]
			return:		[integer!]
		]
		GdipSetPenLineJoin: "GdipSetPenLineJoin" [
			pen			[integer!]
			linejoin	[integer!]
			return:		[integer!]
		]
		GdipSetPenStartCap: "GdipSetPenStartCap" [
			pen			[integer!]
			style		[integer!]
			return:		[integer!]
		]
		GdipSetPenEndCap: "GdipSetPenEndCap" [
			pen			[integer!]
			style		[integer!]
			return:		[integer!]
		]
		GdipDrawImageRectRectI: "GdipDrawImageRectRectI" [
			graphics	[integer!]
			image		[integer!]
			dstx		[integer!]
			dsty		[integer!]
			dstwidth	[integer!]
			dstheight	[integer!]
			srcx		[integer!]
			srcy		[integer!]
			srcwidth	[integer!]
			srcheight	[integer!]
			srcUnit		[integer!]
			attribute	[integer!]
			callback	[integer!]
			data		[integer!]
			return:		[integer!]
		]
	]
	"msimg32.dll" stdcall [
		AlphaBlend: "AlphaBlend" [
			hdcDest		[handle!]
			nXDest		[integer!]
			nYDest		[integer!]
			nWidth		[integer!]
			nHeight		[integer!]
			hdcSrc		[handle!]
			nXSrc		[integer!]
			nYSrc		[integer!]
			nsWidth		[integer!]
			nsHeight	[integer!]
			ftn			[integer!]
			return:		[integer!]
		]
	]
	"avicap32.dll" stdcall [
		capCreateCaptureWindow: "capCreateCaptureWindowW" [
			lpszName	[c-string!]
			dwStyle		[integer!]
			x			[integer!]		
			y			[integer!]
			nWidth		[integer!]
			nHeight		[integer!]
			hWnd		[handle!]
			nID			[integer!]
			return:		[integer!]
		]
	]
]