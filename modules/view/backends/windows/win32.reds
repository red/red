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

#if dev-mode? = yes [
	#include %../../../../runtime/platform/COM.reds
	#include %../../../../runtime/platform/image-gdiplus.reds
]

#define NM_CUSTOMDRAW			-12

#define GWL_HWNDPARENT			-8
#define GWL_STYLE				-16
#define GWL_EXSTYLE				-20

#define CDRF_DODEFAULT			0
#define CDRF_NEWFONT			2
#define CDRF_SKIPDEFAULT		4
#define CDRF_DOERASE			8			;-- draw the background
#define CDRF_SKIPPOSTPAINT		0100h		;-- don't draw the focus rect

#define CDRF_NOTIFYPOSTPAINT	10h
#define CDRF_NOTIFYITEMDRAW		20h

#define CDDS_PREPAINT			1
#define CDDS_POSTPAINT			2
#define CDDS_PREERASE			3
#define CDDS_POSTERASE			4

#define CDIS_DISABLED			4

#define GW_OWNER				4

#define CWP_SKIPINVISIBLE		1
#define CWP_SKIPTRANSPARENT		4

;-- DrawText() Format Flags

#define DT_CENTER				0001h
#define DT_VCENTER				0004h
#define DT_SINGLELINE			0020h
#define DT_EXPANDTABS			0040h
#define DT_CALCRECT				0400h

#define TBM_GETPOS			0400h
#define TBM_SETPOS			0405h
#define TBM_SETRANGE		0406h
#define TBM_SETRANGEMAX		0408h

#define PBM_SETRANGE		0401h
#define PBM_SETPOS			0402h

#define TPM_RETURNCMD		0100h

#define LB_ADDSTRING		0180h
#define LB_INSERTSTRING		0181h
#define LB_DELETESTRING		0182h
#define LB_RESETCONTENT		0184h
#define LB_SETCURSEL		0186h
#define LB_GETCURSEL		0188h
#define LB_GETCOUNT			018Bh
#define LB_SETHORIZONTALEXTENT	0194h

#define HORZRES				8
#define VERTRES				10

#define SW_HIDE				0
#define SW_SHOW				5
#define SW_SHOWNA			8
#define SW_SHOWDEFAULT		10

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
#define CBN_SETFOCUS		3
#define CBN_KILLFOCUS		4
#define CBN_EDITCHANGE		5
#define CBN_SELENDOK		9
#define CBN_SELENDCANCEL	10


#define LBN_SELCHANGE       1
#define LBN_DBLCLK          2

#define EN_CHANGE			0300h
#define EN_SETFOCUS			0100h
#define EN_KILLFOCUS		0200h

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
#define TCM_DELETEALLITEMS	1309h
#define TCM_GETCURSEL		130Bh
#define TCM_SETCURSEL		130Ch
#define TCM_ADJUSTRECT		1328h
#define TCM_SETCURFOCUS		1330h
#define TCM_INSERTITEMW		133Eh

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
#define IDC_IBEAM			7F01h

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
#define WS_MAXIMIZEBOX		00010000h
#define WS_MINIMIZEBOX		00020000h
#define WS_GROUP			00020000h
#define WS_THICKFRAME		00040000h
#define WS_SYSMENU			00080000h
#define WS_BORDER			00800000h
#define WS_DLGFRAME			00400000h
#define WS_CAPTION			00C00000h
#define WS_MAXIMIZE			01000000h
#define WS_CLIPSIBLINGS 	04000000h
#define WS_MINIMIZE			20000000h
#define WS_POPUP		 	80000000h
#define WS_EX_TOOLWINDOW	00000080h
#define WS_DISABLED         08000000h

#define SIF_RANGE			0001h
#define SIF_PAGE			0002h
#define SIF_POS				0004h
#define SIF_DISABLENOSCROLL	0008h
#define SB_VERT				1

#define SB_LINEUP			0
#define SB_LINEDOWN			1
#define SB_PAGEUP			2
#define SB_PAGEDOWN			3
#define SB_THUMBTRACK		5
#define SB_TOP				6
#define SB_BOTTOM			7

#define BS_PUSHBUTTON		00000000h
#define BS_DEFPUSHBUTTON	00000001h
#define BS_CHECKBOX			00000002h
#define BS_AUTOCHECKBOX		00000003h
#define BS_RADIOBUTTON		00000004h
#define BS_GROUPBOX			00000007h
#define BS_AUTORADIOBUTTON	00000009h

#define EM_SETLIMITTEXT		000000C5h
#define EM_GETLIMITTEXT		000000D5h
#define ES_LEFT				00000000h
#define ES_CENTER			00000001h
#define ES_RIGHT			00000003h
#define ES_MULTILINE		00000004h
#define ES_AUTOVSCROLL		00000040h
#define ES_AUTOHSCROLL		00000080h
#define SS_LEFT				00000010h
#define SS_SIMPLE			00000000h
#define SS_NOTIFY			00000100h

#define STN_CLICKED			0

#define SIZE_MINIMIZED		1
#define SIZE_MAXIMIZED		2

#define WM_CREATE			0001h
#define WM_NCCREATE			0081h
#define WM_NCDESTROY		0082h
#define WM_NCHITTEST		0084h
#define WM_DESTROY			0002h
#define WM_MOVE				0003h
#define WM_SIZE				0005h
#define WM_ACTIVATE			0006h
#define WM_SETFOCUS			0007h
#define WM_KILLFOCUS		0008h
#define WM_CLOSE			0010h
#define WM_SETTEXT			000Ch
#define WM_GETTEXT			000Dh
#define WM_GETTEXTLENGTH	000Eh
#define WM_PAINT			000Fh
#define WM_ERASEBKGND		0014h
#define WM_CTLCOLOR			0019h
#define WM_SETCURSOR		0020h
#define WM_MOUSEACTIVATE	0021h
#define WM_GETMINMAXINFO	0024h
#define WM_SETFONT			0030h
#define WM_GETFONT			0031h
#define WM_WINDOWPOSCHANGED 0047h
#define WM_NOTIFY			004Eh
#define WM_CONTEXTMENU		007Bh
#define WM_DISPLAYCHANGE	007Eh
#define WM_KEYDOWN			0100h
#define WM_KEYUP			0101h
#define WM_CHAR				0102h
#define WM_DEADCHAR 		0103h
#define WM_SYSKEYDOWN		0104h
#define WM_SYSKEYUP			0105h
#define WM_COMMAND 			0111h
#define WM_SYSCOMMAND		0112h
#define WM_TIMER			0113h
#define WM_HSCROLL			0114h
#define WM_VSCROLL			0115h
#define WM_INITMENU			0116h
#define WM_GESTURE			0119h
#define WM_MENUSELECT		011Fh
#define WM_MENUCOMMAND		0126h
#define WM_CTLCOLOREDIT		0133h
#define WM_CTLCOLORLISTBOX	0134h
#define WM_CTLCOLORBTN		0135h
#define WM_CTLCOLORDLG		0136h
#define WM_CTLCOLORSCROLLBAR 0137h
#define WM_CTLCOLORSTATIC	0138h
#define	WM_MOUSEMOVE		0200h
#define WM_LBUTTONDOWN		0201h
#define WM_LBUTTONUP		0202h
#define WM_LBUTTONDBLCLK	0203h
#define WM_RBUTTONDOWN		0204h
#define WM_RBUTTONUP		0205h
#define WM_MBUTTONDOWN		0207h
#define WM_MBUTTONUP		0208h
#define	WM_MOUSEWHELL		020Ah
#define WM_ENTERMENULOOP	0211h
#define WM_SIZING			0214h
#define WM_MOVING			0216h
#define WM_ENTERSIZEMOVE	0231h
#define WM_EXITSIZEMOVE		0232h
#define WM_IME_SETCONTEXT	0281h
#define WM_IME_NOTIFY		0282h
#define WM_COPY				0301h
#define WM_PASTE			0302h
#define WM_CLEAR			0303h

#define WM_CAP_DRIVER_CONNECT		040Ah
#define WM_CAP_DRIVER_DISCONNECT	040Bh
#define WM_CAP_EDIT_COPY			041Eh
#define WM_CAP_GRAB_FRAME			043Ch
#define WM_CAP_SET_SCALE			0435h
#define WM_CAP_SET_PREVIEWRATE		0434h
#define WM_CAP_SET_PREVIEW			0432h
#define WM_CAP_DLG_VIDEOSOURCE		042Ah
#define WM_CAP_STOP					0444h

#define BM_GETCHECK			F0h
#define BM_SETCHECK			F1h
#define BM_SETSTYLE			F4h
#define BM_SETIMAGE			F7h

#define BN_CLICKED 			0

#define BST_UNCHECKED		0
#define BST_CHECKED			1
#define BST_INDETERMINATE	2

#define VK_SHIFT			10h
#define VK_CONTROL			11h
#define VK_MENU				12h
#define VK_PAUSE			13h
#define VK_CAPITAL			14h

#define VK_ESCAPE			1Bh

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

#define VK_NUMLOCK			90h
#define VK_SCROLL			91h

#define VK_LSHIFT			A0h
#define VK_RSHIFT			A1h
#define VK_LCONTROL			A2h
#define VK_RCONTROL			A3h
#define VK_LMENU			A4h
#define VK_RMENU			A5h
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
#define NULL_PEN			8
#define DC_BRUSH			18
#define DC_PEN              19

#define BS_SOLID			0
#define BS_BITMAP			80h

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

#define GDIPLUS_MATRIX_PREPEND	0
#define GDIPLUS_MATRIX_APPEND	1

#define GDIPLUS_COMBINEMODEREPLACE	    0
#define GDIPLUS_COMBINEMODEINTERSECT	1
#define GDIPLUS_COMBINEMODEUNION	    2
#define GDIPLUS_COMBINEMODEXOR  	    3
#define GDIPLUS_COMBINEMODEEXCLUDE	    4
;#define GDIPLUS_COMBINEMODECOMPLEMENT   5



#define AC_SRC_OVER                 0
#define AC_SRC_ALPHA                0			;-- there are some troubles on Win64 with value 1

#define TextRenderingHintSystemDefault		0
#define TextRenderingHintAntiAliasGridFit	3

#define SRCCOPY					00CC0020h

#define ILC_COLOR24				18h
#define ILC_COLOR32				20h

#define BCM_SETIMAGELIST		1602h
#define BCM_SETTEXTMARGIN		1604h

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

#define WIN32_LOWORD(param) (param and FFFFh << 16 >> 16)	;-- trick to force sign extension
#define WIN32_HIWORD(param) (param >> 16)

#define IS_EXTENDED_KEY		01000000h

#define ANSI_FIXED_FONT		11
#define SYSTEM_FONT			13
#define SYSTEM_FIXED_FONT	16
#define ETO_OPAQUE			2
#define ETO_CLIPPED			4

#define GA_ROOT				2

#define GM_COMPATIBLE       1
#define GM_ADVANCED         2

#define MWT_IDENTITY        1
#define MWT_LEFTMULTIPLY    2
#define MWT_RIGHTMULTIPLY   3

#define AD_COUNTERCLOCKWISE 1
#define AD_CLOCKWISE        2

#define RGN_AND             1
#define RGN_OR              2
#define RGN_XOR             3
#define RGN_DIFF            4
#define RGN_COPY            5

#define WRAP_MODE_TILE          0
#define WRAP_MODE_TILE_FLIP_X   1
#define WRAP_MODE_TILE_FLIP_Y   2
#define WRAP_MODE_TILE_FLIP_XY  3
#define WRAP_MODE_CLAMP         4

BUTTON_IMAGELIST: alias struct! [
	handle		[integer!]
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
	align		[integer!]
]

tagWINDOWPOS: alias struct! [
	hWnd			[handle!]
	hwndInsertAfter	[handle!]
	x				[integer!]
	y				[integer!]
	cx				[integer!]
	cy				[integer!]
	flags			[integer!]
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

tagTEXTMETRIC: alias struct! [
	tmHeight			[integer!]
	tmAscent			[integer!]
	tmDescent			[integer!]
	tmInternalLeading	[integer!]
	tmExternalLeading	[integer!]
	tmAveCharWidth		[integer!]
	tmMaxCharWidth		[integer!]
	tmWeight			[integer!]
	tmOverhang			[integer!]
	tmDigitizedAspectX	[integer!]
	tmDigitizedAspectY	[integer!]
	tmFirstLastChar		[integer!]
	tmDefaultBreakChar	[integer!]
	tmItalic			[byte!]
	tmUnderlined		[byte!]
	tmStruckOut			[byte!]
	tmPitchAndFamily	[byte!]
	tmCharSet			[byte!]
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

tagNMCUSTOMDRAWINFO: alias struct! [
	hWndFrom	[handle!]
	idFrom		[integer!]
	code		[integer!]
	dwDrawStage [integer!]
	hdc			[handle!]
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
	dwItemSpec	[int-ptr!];this is control specific, but it's how to specify an item.  valid only with CDDS_ITEM bit set
	uItemState	[integer!]
	lItemlParam [integer!]
]

tagSCROLLINFO: alias struct! [
	cbSize		[integer!]
	fMask		[integer!]
	nMin		[integer!]
	nMax		[integer!]
	nPage		[integer!]
	nPos		[integer!]
	nTrackPos	[integer!]
]

tagCREATESTRUCT: alias struct! [
	lpParams 	[int-ptr!]
	hInstance	[handle!]
	hMenu		[handle!]
	hwndParent	[integer!]
	cy			[integer!]
	cx			[integer!]
	y			[integer!]
	x			[integer!]
	style		[integer!]
	lpszName	[byte-ptr!]
	lpszClass	[byte-ptr!]
	dwExStyle	[integer!]
]

tagMINMAXINFO: alias struct! [
	ptReserved.x	 [integer!]
	ptReserved.y	 [integer!]
	ptMaxSize.x		 [integer!]
	ptMaxSize.y		 [integer!]
	ptMaxPosition.x	 [integer!]
	ptMaxPosition.y	 [integer!]
	ptMinTrackSize.x [integer!]
	ptMinTrackSize.y [integer!]
	ptMaxTrackSize.x [integer!]
	ptMaxTrackSize.y [integer!]
]

wndproc-cb!: alias function! [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
]

timer-cb!: alias function! [
	hWnd	[handle!]
	msg		[integer!]
	idEvent	[int-ptr!]
	dwTime	[integer!]
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

GESTUREINFO: alias struct! [
	cbSize		 [integer!]
	dwFlags		 [integer!]
	dwID		 [integer!]
	hwndTarget	 [handle!]
	ptsLocation	 [integer!]
	dwInstanceID [integer!]
	dwSequenceID [integer!]
	pad1		 [integer!]
	ullArgumentH [integer!]
	ullArgumentL [integer!]
	cbExtraArgs	 [integer!]
	pad2		 [integer!]
]

GESTURECONFIG: alias struct! [
	dwID		[integer!]
	dwWant		[integer!]
	dwBlock		[integer!]
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

tagINITCOMMONCONTROLSEX: alias struct! [
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

tagCOMPOSITIONFORM: alias struct! [
	dwStyle		[integer!]
	x			[integer!]
	y			[integer!]
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
]

tagLOGFONT: alias struct! [								;-- 92 bytes
	lfHeight		[integer!]
	lfWidth			[integer!]
	lfEscapement	[integer!]
	lfOrientation	[integer!]
	lfWeight		[integer!]
	lfItalic		[byte!]
	lfUnderline		[byte!]
	lfStrikeOut		[byte!]
	lfCharSet		[byte!]
	lfOutPrecision	[byte!]
	lfClipPrecision	[byte!]
	lfQuality		[byte!]
	lfPitchAndFamily[byte!]
	lfFaceName		[float!]							;@@ 64 bytes offset: 28
	lfFaceName2		[float!]
	lfFaceName3		[float!]
	lfFaceName4		[float!]
	lfFaceName5		[float!]
	lfFaceName6		[float!]
	lfFaceName7		[float!]
	lfFaceName8		[float!]
]

tagCHOOSEFONT: alias struct! [
	lStructSize		[integer!]
	hwndOwner		[int-ptr!]
	hDC				[integer!]
	lpLogFont		[tagLOGFONT]
	iPointSize		[integer!]
	Flags			[integer!]
	rgbColors		[integer!]
	lCustData		[integer!]
	lpfnHook		[integer!]
	lpTemplateName	[c-string!]
	hInstance		[integer!]
	lpszStyle		[c-string!]
	nFontType		[integer!]							;-- WORD
	nSizeMin		[integer!]
	nSizeMax		[integer!]
]

tagOFNW: alias struct! [
	lStructSize			[integer!]
	hwndOwner			[handle!]
	hInstance			[integer!]
	lpstrFilter			[c-string!]
	lpstrCustomFilter	[c-string!]
	nMaxCustFilter		[integer!]
	nFilterIndex		[integer!]
	lpstrFile			[byte-ptr!]
	nMaxFile			[integer!]
	lpstrFileTitle		[c-string!]
	nMaxFileTitle		[integer!]
	lpstrInitialDir		[c-string!]
	lpstrTitle			[c-string!]
	Flags				[integer!]
	nFileOffset			[integer!]
	;nFileExtension		[integer!]
	lpstrDefExt			[c-string!]
	lCustData			[integer!]
	lpfnHook			[integer!]
	lpTemplateName		[integer!]
	;-- if (_WIN32_WINNT >= 0x0500)
	pvReserved			[integer!]
	dwReserved			[integer!]
	FlagsEx				[integer!]
]

tagBROWSEINFO: alias struct! [
	hwndOwner		[handle!]
	pidlRoot		[int-ptr!]
	pszDisplayName	[c-string!]
	lpszTitle		[c-string!]
	ulFlags			[integer!]
	lpfn			[integer!]
	lParam			[integer!]
	iImage			[integer!]
]

DwmIsCompositionEnabled!: alias function! [
	pfEnabled	[int-ptr!]
	return:		[integer!]
]

XFORM!: alias struct! [
    eM11        [float32!]
    eM12        [float32!]
    eM21        [float32!]
    eM22        [float32!]
    eDx         [float32!]
    eDy         [float32!]
]

#import [
	"kernel32.dll" stdcall [
		GlobalAlloc: "GlobalAlloc" [
			flags		[integer!]
			size		[integer!]
			return:		[handle!]
		]
		GlobalFree: "GlobalFree" [
			hMem		[handle!]
			return:		[integer!]
		]
		GlobalLock: "GlobalLock" [
			hMem		[handle!]
			return:		[byte-ptr!]
		]
		GlobalUnlock: "GlobalUnlock" [
			hMem		[handle!]
			return:		[integer!]
		]
		GetCurrentProcessId: "GetCurrentProcessId" [
			return:		[integer!]
		]
		GetModuleHandle: "GetModuleHandleW" [
			lpModuleName [integer!]
			return:		 [handle!]
		]
		GetSystemDirectory: "GetSystemDirectoryW" [
			lpBuffer	[c-string!]
			uSize		[integer!]
			return:		[integer!]
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
		LoadLibraryA: "LoadLibraryA" [
			lpFileName	[c-string!]
			return:		[handle!]
		]
		FreeLibrary: "FreeLibrary" [
			hModule		[handle!]
			return:		[logic!]
		]
		GetProcAddress: "GetProcAddress" [
			hModule		[handle!]
			lpProcName	[c-string!]
			return:		[integer!]
		]
		lstrlen: "lstrlenW" [
			str			[byte-ptr!]
			return:		[integer!]
		]
	]
	"User32.dll" stdcall [
		GetKeyboardLayout: "GetKeyboardLayout" [
			idThread	[integer!]
			return:		[integer!]
		]
		GetSystemMetrics: "GetSystemMetrics" [
			index		[integer!]
			return:		[integer!]
		]
		SystemParametersInfo: "SystemParametersInfoW" [
			action		[integer!]
			iParam		[integer!]
			vParam		[int-ptr!]
			winini		[integer!]
			return:		[logic!]
		]
		GetForegroundWindow: "GetForegroundWindow" [
			return:		[handle!]
		]
		IsWindowVisible: "IsWindowVisible" [
			hWnd		[handle!]
			return:		[logic!]
		]
		SetTimer: "SetTimer" [
			hWnd		[handle!]
			nIDEvent	[integer!]
			uElapse		[integer!]
			lpTimerFunc [timer-cb!]
			return:		[int-ptr!]
		]
		KillTimer: "KillTimer" [
			hWnd		[handle!]
			uIDEvent	[int-ptr!]
			return:		[logic!]
		]
		OpenClipboard: "OpenClipboard" [
			hWnd		[handle!]
			return:		[logic!]
		]
		SetClipboardData: "SetClipboardData" [
			uFormat		[integer!]
			hMem		[handle!]
			return:		[handle!]
		]
		GetClipboardData: "GetClipboardData" [
			uFormat		[integer!]
			return:		[handle!]
		]
		EmptyClipboard: "EmptyClipboard" [
			return:		[integer!]
		]
		CloseClipboard: "CloseClipboard" [
			return:		[integer!]
		]
		IsClipboardFormatAvailable: "IsClipboardFormatAvailable" [
			format		[integer!]
			return:		[logic!]
		]
		GetKeyState: "GetKeyState" [
			nVirtKey	[integer!]
			return:		[integer!]
		]
		SetActiveWindow: "SetActiveWindow" [
			hWnd		[handle!]
			return:		[handle!]
		]
		SetForegroundWindow: "SetForegroundWindow" [
			hWnd		[handle!]
			return:		[logic!]
		]
		SetWindowRgn: "SetWindowRgn" [
			hWnd		[handle!]
			hRgn		[handle!]
			redraw		[logic!]
			return:		[integer!]
		]
		SetFocus: "SetFocus" [
			hWnd		[handle!]
			return:		[handle!]
		]
		SetCapture: "SetCapture" [
			hWnd		[handle!]
			return:		[handle!]
		]
		ReleaseCapture: "ReleaseCapture" [
			return:		[logic!]
		]
		SetLayeredWindowAttributes: "SetLayeredWindowAttributes" [
			hWnd		[handle!]
			crKey		[integer!]
			bAlpha		[integer!]
			dwFlags		[integer!]
			return:		[integer!]
		]
		UpdateLayeredWindow: "UpdateLayeredWindow" [
			hwnd		[handle!]
			hdcDst		[handle!]
			pptDst		[tagPOINT]
			psize		[tagSIZE]
			hdcSrc		[handle!]
			pptSrc		[tagPOINT]
			crKey		[integer!]
			pblend		[integer!]
			dwFlags		[integer!]
			return:		[logic!]
		]
		GetWindowThreadProcessId: "GetWindowThreadProcessId" [
			hWnd		[handle!]
			process-id	[int-ptr!]
			return:		[integer!]
		]
		DrawText: "DrawTextW" [
			hDC			[handle!]
			lpchText	[c-string!]
			nCount		[integer!]
			lpRect		[RECT_STRUCT]
			uFormat		[integer!]
			return:		[integer!]
		]
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
		MapVirtualKey: "MapVirtualKeyW" [
			uCode		[integer!]
			uMapType	[integer!]
			return:		[integer!]
		]
		ToUnicode: "ToUnicode" [
			wVirtKey	[integer!]
			wScanCode	[integer!]
			lpKeyState	[byte-ptr!]
			pwszBuff	[c-string!]
			cchBuff		[integer!]
			wFlags		[integer!]
			return:		[integer!]
		]
		GetKeyboardState: "GetKeyboardState" [
			lpKeyState	[byte-ptr!]
			return:		[logic!]
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
		UnregisterClass: "UnregisterClassW" [
			lpClassName	[c-string!]
			hInstance	[handle!]
			return:		[integer!]
		]
		LoadCursor: "LoadCursorW" [
			hInstance	 [handle!]
			lpCursorName [integer!]
			return: 	 [handle!]
		]
		SetCursor: "SetCursor" [
			hCursor		[handle!]
			return:		[handle!]			;-- return previous cursor, if there was one
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
			lpsi		 [tagSCROLLINFO]
			fRedraw		 [logic!]
			return: 	 [integer!]
		]
		GetScrollInfo: "GetScrollInfo" [
			hWnd		[handle!]
			nBar		[integer!]
			lpsi		[tagSCROLLINFO]
			return:		[integer!]
		]
		ShowScrollBar: "ShowScrollBar" [
			hWnd		[handle!]
			wBar		[integer!]
			bShow		[logic!]
			return:		[logic!]
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
		EnableWindow: "EnableWindow" [
			hWnd		[handle!]
			bEnable		[logic!]
			return:		[logic!]
		]
		InvalidateRect: "InvalidateRect" [
			hWnd		[handle!]
			lpRect		[RECT_STRUCT]
			bErase		[integer!]
			return:		[integer!]
		]
		ValidateRect: "ValidateRect" [
			hWnd		[handle!]
			lpRect		[RECT_STRUCT]
			return:		[logic!]
		]
		GetParent: "GetParent" [
			hWnd 		[handle!]
			return:		[handle!]
		]
		GetAncestor: "GetAncestor" [
			hWnd 		[handle!]
			gaFlags		[integer!]
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
		RealChildWindowFromPoint: "RealChildWindowFromPoint" [
			hwndParent	[handle!]
			x			[integer!]
			y			[integer!]
			return:		[handle!]
		]
		ChildWindowFromPointEx: "ChildWindowFromPointEx" [
			hwndParent	[handle!]
			x			[integer!]
			y			[integer!]
			flags		[integer!]
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
		PeekMessage: "PeekMessageW" [
			msg			[tagMSG]
			hWnd		[handle!]
			msgMin		[integer!]
			msgMax		[integer!]
			removeMsg	[integer!]
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
		PostMessage: "PostMessageW" [
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
		AdjustWindowRectEx: "AdjustWindowRectEx" [
			lpRect		[RECT_STRUCT]
			dwStyle		[integer!]
			bMenu		[logic!]
			dwExStyle	[integer!]
			return:		[logic!]
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
		AppendMenu: "AppendMenuW" [
			hMenu		[handle!]
			uFlags		[integer!]
			uIDNewItem	[integer!]
			lpNewItem	[c-string!]
			return:		[logic!]
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
		ScreenToClient: "ScreenToClient" [
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
		GetAsyncKeyState: "GetAsyncKeyState" [
			nVirtKey	[integer!]
			return:		[integer!]						;-- returns a 16-bit value
		]
		GetCapture: "GetCapture" [
			return:		[handle!]
		]
		GetTabbedTextExtent: "GetTabbedTextExtentW" [
			hdc			[handle!]
			lpString	[c-string!]
			len			[integer!]
			nTabPos		[integer!]
			lpnTabStop	[int-ptr!]
			return:		[integer!]
		]
		CreateCaret: "CreateCaret" [
			hWnd		[handle!]
			bitmap		[handle!]
			width		[integer!]
			height		[integer!]
			return:		[integer!]
		]
		DestroyCaret: "DestroyCaret" [
			return:		[integer!]
		]
		HideCaret: "HideCaret" [
			hWnd		[handle!]
			return:		[integer!]
		]
		ShowCaret: "ShowCaret" [
			hWnd		[handle!]
			return:		[integer!]
		]
		SetCaretPos: "SetCaretPos" [
			x			[integer!]
			y			[integer!]
			return:		[integer!]
		]
		PrintWindow: "PrintWindow" [
			hWnd		[handle!]
			dc			[handle!]
			flag		[integer!]
			return:		[integer!]
		]
	]
	"gdi32.dll" stdcall [
		GetObject: "GetObjectW" [
			hObj		[handle!]
			cbBuffer	[integer!]
			lpObject	[byte-ptr!]
			return:		[integer!]
		]
		GetTextFace: 	"GetTextFaceW" [
			hdc			[handle!]
			nCount		[integer!]
			lpFaceName	[byte-ptr!]
			return:		[integer!]
		]
		GetCharWidth32: "GetCharWidth32W" [
			hdc			[handle!]
			iFirst		[integer!]
			iLast		[integer!]
			lpBuffer	[int-ptr!]
			return:		[integer!]
		]
		GetTextMetrics: "GetTextMetricsW" [
			hdc			[handle!]
			lptm		[tagTEXTMETRIC]
			return:		[integer!]
		]
		CreateRectRgn: "CreateRectRgn" [
			left		[integer!]
			top			[integer!]
			right		[integer!]
			bottom		[integer!]
			return:		[handle!]
		]
		ExtTextOut: "ExtTextOutW" [
			hdc			[handle!]
			X			[integer!]
			Y			[integer!]
			fuOptions	[integer!]
			lprc		[RECT_STRUCT]
			lpString	[c-string!]
			cbCount		[integer!]						;-- count of characters
			lpDx		[int-ptr!]
			return:		[integer!]
		]	
		GetTextExtentPoint32: "GetTextExtentPoint32W" [
			hdc			[handle!]
			lpString	[c-string!]
			len			[integer!]
			lpSize		[tagSIZE]
			return:		[integer!]
		]
		GetTextExtentExPoint: "GetTextExtentExPointW" [
			hdc			[handle!]
			lpString	[c-string!]
			len			[integer!]
			extent		[integer!]
			lpnFit		[int-ptr!]
			alpDx		[int-ptr!]
			lpSize		[tagSIZE]
			return:		[logic!]
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
        SelectClipPath: "SelectClipPath" [
            hdc         [handle!]
            iMode       [integer!]
            return:     [logic!]
        ]
        BeginPath: "BeginPath" [
            hdc         [handle!]
            return:     [logic!]
        ]
        EndPath: "EndPath" [
            hdc         [handle!]
            return:     [logic!]
        ]
        GetPath: "GetPath" [
            hdc         [handle!]
            points      [tagPOINT]
            types       [byte-ptr!]
            nSize       [integer!]
            return:     [integer!]
        ]
        FillPath: "FillPath" [
            hdc         [handle!]
            return:     [logic!]
        ]
        CloseFigure: "CloseFigure" [
            hdc         [handle!]
            return:     [logic!]
        ]
		Polyline: "Polyline" [
			hdc			[handle!]
			lppt		[tagPOINT]
			cPoints		[integer!]
			return:		[logic!]
		]
        PolylineTo: "PolylineTo" [
            hdc         [handle!]
            lppt        [tagPOINT]
            cPoints     [integer!]
            return:     [logic!]
        ]
        PolyDraw: "PolyDraw" [
            hdc         [handle!]
            points      [tagPOINT]
            types       [byte-ptr!]
            nSize       [integer!]
            return:     [logic!]
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
        ArcTo: "ArcTo" [
            hdc         [handle!]
            nLeftRect   [integer!]
            nTopRect    [integer!]
            nRightRect  [integer!]
            nBottomRect [integer!]
            nXStartArc  [integer!]
            nYStartArc  [integer!]
            nXEndArc    [integer!]
            nYEndArc    [integer!]
            return:     [logic!]
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
        GetArcDirection: "GetArcDirection" [
            hdc         [handle!]
            return:     [integer!]
        ]
		PolyBezier: "PolyBezier" [
			hdc			[handle!]
			lppt		[tagPOINT]
			cPoints		[integer!]
			return:		[integer!]
		]
		CreateFontIndirect: "CreateFontIndirectW" [
			lplf		[tagLOGFONT]
			return:		[handle!]
		]
		CreateFont: "CreateFontW" [
			nHeight				[integer!]
			nWidth				[integer!]
			nEscapement			[integer!]
			nOrientation		[integer!]
			fnWeight			[integer!]
			fdwItalic			[integer!]
			fdwUnderline		[integer!]
			fdwStrikeOut		[integer!]
			fdwCharSet			[integer!]
			fdwOutputPrecision	[integer!]
			fdwClipPrecision	[integer!]
			fdwQuality			[integer!]
			fdwPitchAndFamily	[integer!]
			lpszFace			[c-string!]
			return: 			[handle!]
		]
        SetGraphicsMode: "SetGraphicsMode" [
            hdc         [handle!]
            mode        [integer!]
            return:     [integer!]
        ]
        SetWorldTransform: "SetWorldTransform" [
            hdc         [handle!]
            lpXform     [XFORM!]
            return:     [logic!]
        ]
        ModifyWorldTransform: "ModifyWorldTransform" [
            hdc         [handle!]
            lpXform     [XFORM!]
            iMode       [integer!]
            return:     [logic!]
        ]
	]
	"comdlg32.dll" stdcall [
			GetOpenFileName: "GetOpenFileNameW" [
				lpofn		[tagOFNW]
				return:		[integer!]
			]
			GetSaveFileName: "GetSaveFileNameW" [
				lpofn		[tagOFNW]
				return:		[integer!]
			]
		ChooseFont: "ChooseFontW" [
			lpcf		[tagCHOOSEFONT]
			return:		[logic!]
		]
	]
	"gdiplus.dll" stdcall [
		GdipCreateHICONFromBitmap: "GdipCreateHICONFromBitmap" [
			bitmap		[integer!]
			hIcon		[int-ptr!]
			return:		[integer!]
		]
		GdipSetPixelOffsetMode: "GdipSetPixelOffsetMode" [
			graphics	[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		GdipSetCompositingMode: "GdipSetCompositingMode" [
			graphics	[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		GdipSetCompositingQuality: "GdipSetCompositingQuality" [
			graphics	[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		GdipCreateImageAttributes: "GdipCreateImageAttributes" [
			attr		[int-ptr!]
			return:		[integer!]
		]
		GdipDisposeImageAttributes: "GdipDisposeImageAttributes" [
			attr		[integer!]
			return:		[integer!]
		]
		GdipSetImageAttributesColorKeys: "GdipSetImageAttributesColorKeys" [
			attr		[integer!]
			type		[integer!]
			enable?		[logic!]
			colorLow	[integer!]
			colorHigh	[integer!]
			return:		[integer!]
		]
		GdipCreateMatrix: "GdipCreateMatrix" [
			matrix		[int-ptr!]
			return:		[integer!]
		]
		GdipDeleteMatrix: "GdipDeleteMatrix" [
			matrix		[integer!]
			return:		[integer!]
		]
		GdipMultiplyMatrix: "GdipMultiplyMatrix" [
			matrix-1	[integer!]
			matrix-2	[integer!]
			order		[integer!]
			return:		[integer!]
		]
		GdipRotateMatrix: "GdipRotateMatrix" [
			matrix		[integer!]
			angle		[float32!]
			matrixorder [integer!]
			return:		[integer!]
		]
		GdipTranslateMatrix: "GdipTranslateMatrix" [
			matrix		[integer!]
			dx			[float32!]
			dy			[float32!]
			matrixorder	[integer!]
			return:		[integer!]
		]
		GdipScaleMatrix: "GdipScaleMatrix" [
			matrix		[integer!]
			sx			[float32!]
			sy			[float32!]
			matrixorder	[integer!]
			return:		[integer!]
		]
		GdipInvertMatrix: "GdipInvertMatrix" [
			matrix		[integer!]
		]
		GdipCreateMatrix2: "GdipCreateMatrix2" [
			m11			[float32!]
			m12			[float32!]
			m21			[float32!]
			m22			[float32!]
			dx			[float32!]
			dy			[float32!]
			matrix		[int-ptr!]
			return:		[int-ptr!]
		]
		GdipGetMatrixElements: "GdipGetMatrixElements" [
			m 			[integer!]
			out			[pointer! [float32!]]
			return:		[integer!]
		]
		GdipSetMatrixElements: "GdipSetMatrixElements" [
			m			[integer!]
			m11			[float32!]
			m12			[float32!]
			m21			[float32!]
			m22			[float32!]
			dx			[float32!]
			dy			[float32!]
			return:		[integer!]
		]
		GdipTransformMatrixPointsI: "GdipTransformMatrixPointsI" [
			matrix		[integer!]
			pts			[tagPOINT]
			count		[integer!]
			return:		[integer!]
		]
		GdipSaveGraphics: "GdipSaveGraphics" [
			graphics	[integer!]
			state		[int-ptr!]
			return:		[integer!]
		]
		GdipRestoreGraphics: "GdipRestoreGraphics" [
			graphics	[integer!]
			state		[integer!]
			return:		[integer!]
		]
		GdipSetClipRectI: "GdipSetClipRectI" [
			graphics	[integer!]
			x			[integer!]
			y			[integer!]
			width 		[integer!]
			height 		[integer!]
			combine 	[integer!]
			return:		[integer!]
		]
        GdipSetClipPath: "GdipSetClipPath" [
			graphics	[integer!]
			path		[integer!]
            combineMode [integer!]
            return:     [integer!]
        ]
		GdipRotateWorldTransform: "GdipRotateWorldTransform" [
			graphics	[integer!]
			angle		[float32!]
			matrixorder [integer!]
			return:		[integer!]
		]
		GdipTranslateWorldTransform: "GdipTranslateWorldTransform" [
			graphics	[integer!]
			dx			[float32!]
			dy			[float32!]
			matrixorder	[integer!]
			return:		[integer!]
		]
		GdipScaleWorldTransform: "GdipScaleWorldTransform" [
			graphics	[integer!]
			sx			[float32!]
			sy			[float32!]
			matrixorder	[integer!]
			return:		[integer!]
		]
		GdipMultiplyWorldTransform: "GdipMultiplyWorldTransform" [
			graphics	[integer!]
			matrix		[integer!]
			matrixorder	[integer!]
			return:		[integer!]
		]
		GdipSetWorldTransform: "GdipSetWorldTransform" [
			graphics	[integer!]
			matrix		[integer!]
			return:		[integer!]
		]
		GdipGetWorldTransform: "GdipGetWorldTransform" [
			graphics	[integer!]
			matrix		[integer!]
			return:		[integer!]
		]
		GdipResetWorldTransform: "GdipResetWorldTransform" [
			graphics	[integer!]
			return:		[integer!]
		]
		GdipTransformPath: "GdipTransformPath" [
			path		[integer!]
			matrix		[integer!]
			return:		[integer!]
		]
		GdipTranslatePathGradientTransform: "GdipTranslatePathGradientTransform" [
			matrix		[integer!]
			dx			[float32!]
			dy			[float32!]
			matrixorder	[integer!]
			return:		[integer!]
		]
		GdipSetPathGradientWrapMode: "GdipSetPathGradientWrapMode" [
			brush		[integer!]
			wrapmode	[integer!]
			return:		[integer!]
		]
		GdipCreatePathGradientFromPath: "GdipCreatePathGradientFromPath" [
			path		[integer!]
			brush		[int-ptr!]
			return:		[integer!]
		]
		GdipCreatePathGradientI: "GdipCreatePathGradientI" [
			points		[tagPOINT]
			count		[integer!]
			wrapmode	[integer!]
			brush		[int-ptr!]
			return:		[integer!]
		]
		GdipSetPathGradientCenterColor: "GdipSetPathGradientCenterColor" [
			brush		[integer!]
			color		[integer!]
			return:		[integer!]
		]
		GdipSetPathGradientSurroundColorsWithCount: "GdipSetPathGradientSurroundColorsWithCount" [
			brush		[integer!]
			colors		[int-ptr!]
			count		[int-ptr!]
			return:		[integer!]
		]
		GdipSetPathGradientPath: "GdipSetPathGradientPath" [
			brush		[integer!]
			path		[integer!]
			return:		[integer!]
		]
		GdipSetPathGradientCenterPointI: "GdipSetPathGradientCenterPointI" [
			brush		[integer!]
			point		[tagPOINT]
			return:		[integer!]
		]
		GdipGetPathGradientCenterPointI: "GdipGetPathGradientCenterPointI" [
			brush		[integer!]
			point		[tagPOINT]
			return:		[integer!]
		]
		GdipSetPathGradientPresetBlend: "GdipSetPathGradientPresetBlend" [
			brush		[integer!]
			colors		[int-ptr!]
			positions	[pointer! [float32!]]
			count		[integer!]
			return:		[integer!]
		]
		GdipSetPathGradientTransform: "GdipSetPathGradientTransform" [
            brush       [integer!]
            matrix      [integer!]
            return:     [integer!]
		]
		GdipScaleLineTransform: "GdipScaleLineTransform" [
			brush		[integer!]
			sx			[float32!]
			sy			[float32!]
			matrixorder	[integer!]
			return:		[integer!]
		]
		GdipRotateLineTransform: "GdipRotateLineTransform" [
			brush		[integer!]
			angle		[float32!]
			matrixorder	[integer!]
			return:		[integer!]
		]
		GdipSetLineTransform: "GdipSetLineTransform" [
			brush		[integer!]
			matrix		[integer!]
			return:		[integer!]
		]
		GdipSetLineWrapMode: "GdipSetLineWrapMode" [
			brush		[integer!]
			wrapmode	[integer!]
			return:		[integer!]
		]
		GdipCreateTexture: "GdipCreateTexture" [
			image		[integer!]
			wrapmode	[integer!]
			texture		[int-ptr!]
			return:		[integer!]
		]
		GdipRotateTextureTransform: "GdipRotateTextureTransform" [
			brush		[integer!]
			angle		[float32!]
			order 		[integer!]
			return:		[integer!]
		]
		GdipScaleTextureTransform: "GdipScaleTextureTransform" [
			brush		[integer!]
			sx			[float32!]
			sy			[float32!]
			order 		[integer!]
			return:		[integer!]
		]
		GdipTranslateTextureTransform: "GdipTranslateTextureTransform" [
			brush		[integer!]
			dx			[float32!]
			dy			[float32!]
			order 		[integer!]
			return:		[integer!]
		]
		GdipResetTextureTransform: "GdipResetTextureTransform" [
			brush		[integer!]
			return:		[integer!]
		]
		GdipSetTextureTransform: "GdipSetTextureTransform" [
			brush		[integer!]
			matrix		[integer!]
			return:		[integer!]
		]
		GdipGetTextureTransform: "GdipGetTextureTransform" [
			brush		[integer!]
			matrix		[int-ptr!]
			return:		[integer!]
		]
		GdipDrawImagePointsRectI: "GdipDrawImagePointsRectI" [
			graphics	[integer!]
			image		[integer!]
			points		[tagPOINT]
			count		[integer!]
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
		GdipSetLinePresetBlend: "GdipSetLinePresetBlend" [
			brush		[integer!]
			colors		[int-ptr!]
			positions	[pointer! [float32!]]
			count		[integer!]
			return:		[integer!]
		]
		GdipCreateLineBrushI: "GdipCreateLineBrushI" [
			pt1			[tagPOINT]
			pt2			[tagPOINT]
			color1		[integer!]
			color2		[integer!]
			wrap		[integer!]
			brush		[int-ptr!]
			return:		[integer!]
		]
		GdipDeleteStringFormat: "GdipDeleteStringFormat" [
			format		[integer!]
			return:		[integer!]
		]
		GdipCreateStringFormat: "GdipCreateStringFormat" [
			attributes	[integer!]
			language	[integer!]
			format		[int-ptr!]
			return:		[integer!]
		]
		GdipSetStringFormatAlign: "GdipSetStringFormatAlign" [
			format		[integer!]
			align		[integer!]
			return:		[integer!]
		]
		GdipSetStringFormatLineAlign: "GdipSetStringFormatLineAlign" [
			format		[integer!]
			align		[integer!]
			return:		[integer!]
		]
		GdipCreateFontFromDC: "GdipCreateFontFromDC" [
			hdc			[integer!]
			font		[int-ptr!]
			return:		[integer!]
		]
		GdipDeleteFont: "GdipDeleteFont" [
			font		[integer!]
			return:		[integer!]
		]
		GdipSetTextRenderingHint: "GdipSetTextRenderingHint" [
			graphics	[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		GdipDrawImageRectI: "GdipDrawImageRectI" [
			graphics	[integer!]
			image		[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			return:		[integer!]
		]
		GdipCreateBitmapFromHBITMAP: "GdipCreateBitmapFromHBITMAP" [
			hbmp		[handle!]
			palette		[integer!]
			bitmap		[int-ptr!]
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
        GdipCreateTexture2I: "GdipCreateTexture2I" [
            image       [integer!]
            wrapmode    [integer!]
            x           [integer!]
            y           [integer!]
            width       [integer!]
            height      [integer!]
            texture     [int-ptr!]
            return:     [integer!]
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
        GdipClonePath: "GdipClonePath" [
            path        [integer!]
            new-path    [int-ptr!]
            return:     [integer!]
        ]
        GdipFlattenPath: "GdipFlattenPath" [
            path        [integer!]
            matrix      [integer!]
            flatness    [float32!]
            return:     [integer!]
        ]
		GdipStartPathFigure: "GdipStartPathFigure" [
			path		[integer!]
			return:		[integer!]
		]
		GdipClosePathFigure: "GdipClosePathFigure" [
			path		[integer!]
			return:		[integer!]
		]
        GdipAddPathLine2I: "GdipAddPathLine2I" [
            path        [integer!]
            points      [tagPOINT]
            count       [integer!]
            return:     [integer!]
        ]
		GdipAddPathRectangleI: "GdipAddPathRectangleI" [
			path		[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
			return:		[integer!]
		]
		GdipAddPathEllipseI: "GdipAddPathEllipseI" [
			path		[integer!]
			x			[integer!]
			y			[integer!]
			width		[integer!]
			height		[integer!]
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
		GdipAddPathArc: "GdipAddPathArc" [
			path		[integer!]
			x			[float32!]
			y			[float32!]
			width		[float32!]
			height		[float32!]
			startAngle	[float32!]
			sweepAngle	[float32!]
			return:		[integer!]
		]
        GdipAddPathBeziersI: "GdipAddPathBeziersI" [
            path        [integer!]
            points      [tagPOINT]
            count       [integer!]
            return:     [integer!]
        ]
        GdipAddPathPath: "GdipAddPathPath" [
            path-dst    [integer!]
            path-src    [integer!]
            connect     [integer!]
            return:     [integer!]
        ]
        GdipGetPointCount: "GdipGetPointCount" [
            path        [integer!]
            count       [int-ptr!]
            return:     [integer!]
        ]
        GdipGetPathData: "GdipGetPathData" [
            path        [integer!]
            pathData    [PATHDATA]
            return:     [integer!]
        ]
        GdipGetPathLastPoint: "GdipGetPathLastPoint" [
            path        [integer!]
            point       [POINT_2F]
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
		GdipDrawCurveI: "GdipDrawCurveI" [
			graphics	[integer!]
			pen			[integer!]
			points		[tagPOINT]
			count		[integer!]
			return:		[integer!]
		]
		GdipDrawClosedCurveI: "GdipDrawClosedCurveI" [
			graphics	[integer!]
			pen			[integer!]
			points		[tagPOINT]
			count		[integer!]
			return:		[integer!]
		]
		GdipFillClosedCurveI: "GdipFillClosedCurveI" [
			graphics	[integer!]
			brush		[integer!]
			points		[tagPOINT]
			count		[integer!]
			fillMode	[integer!]
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
		GdipSetPenColor: "GdipSetPenColor" [
			pen			[integer!]
			color		[integer!]
			return:		[integer!]
		]
		GdipSetPenWidth: "GdipSetPenWidth" [
			pen			[integer!]
			width		[float32!]
			return:		[integer!]
		]
		GdipSetPenBrushFill: "GdipSetPenBrushFill" [
			pen			[integer!]
			brush		[integer!]
			return:		[integer!]
		]
        GdipGetPenBrushFill: "GdipGetPenBrushFill" [
			pen			[integer!]
			brush		[int-ptr!]
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
		GdipCreateHBITMAPFromBitmap: "GdipCreateHBITMAPFromBitmap" [
			image		[integer!]
			hbmp		[int-ptr!]
			background	[integer!]
			return:		[integer!]
		]
		GdipDisposeImage: "GdipDisposeImage" [
			image		[integer!]
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
	"comctl32.dll" stdcall [
		InitCommonControlsEx: "InitCommonControlsEx" [
			lpInitCtrls [tagINITCOMMONCONTROLSEX]
			return:		[logic!]
		]
		ImageList_Create: "ImageList_Create" [
			cx			[integer!]
			cy			[integer!]
			flags		[integer!]
			cInitial	[integer!]
			cGrow		[integer!]
			return:		[integer!]
		]
		ImageList_Destroy: "ImageList_Destroy" [
			himl		[integer!]
			return:		[integer!]
		]
		ImageList_Add: "ImageList_Add" [
			himl		[integer!]
			hbmImage	[integer!]
			hbmMask		[integer!]
			return:		[integer!]
		]
	]
	"shell32.dll" stdcall [
		SHBrowseForFolder: "SHBrowseForFolderW" [
			lpbi		[tagBROWSEINFO]
			return: 	[integer!]
		]
		SHGetPathFromIDList: "SHGetPathFromIDListW" [
			pidl		[integer!]
			pszPath		[byte-ptr!]
			return:		[logic!]
		]
	]
	"ole32.dll" stdcall [
		CoTaskMemFree: "CoTaskMemFree" [
			pv		[integer!]
		]
	]
	"imm32.dll" stdcall [
		ImmGetContext: "ImmGetContext" [
			hWnd	[handle!]
			return:	[handle!]
		]
		ImmReleaseContext: "ImmReleaseContext" [
			hWnd	[handle!]
			hIMC	[handle!]
			return:	[logic!]
		]
		ImmGetOpenStatus: "ImmGetOpenStatus" [
			hIMC	[handle!]
			return:	[logic!]
		]
		ImmSetCompositionWindow: "ImmSetCompositionWindow" [
			hIMC	[handle!]
			lpComp	[tagCOMPOSITIONFORM]
			return: [logic!]
		]
		ImmSetCompositionFontW: "ImmSetCompositionFontW" [
			hIMC	[handle!]
			lfont	[tagLOGFONT]
			return: [logic!]
		]
	]
	"UxTheme.dll" stdcall [
		OpenThemeData: "OpenThemeData" [
			hWnd		 [handle!]
			pszClassList [c-string!]
			return:		 [handle!]
		]
		CloseThemeData: "CloseThemeData" [
			hTheme		[handle!]
			return:		[integer!]
		]
		IsThemeActive:	"IsThemeActive" [				;WARN: do not call from DllMain!!
			return:		[logic!]
		]
		GetThemeSysFont: "GetThemeSysFont" [
			hTheme		[handle!]
			iFontID		[integer!]
			plf			[tagLOGFONT]
			return:		[integer!]
		]
	]
	LIBC-file cdecl [
		realloc: "realloc" [						"Resize and return allocated memory."
			memory			[byte-ptr!]
			size			[integer!]
			return:			[byte-ptr!]
		]
	]
]


#case [
	any [not legacy not find legacy 'no-touch] [
		#import [
			"User32.dll" stdcall [
				SetGestureConfig: "SetGestureConfig" [
					hWnd		[handle!]
					dwReserved	[integer!]						;-- set it to 0
					cIDs		[integer!]
					pConfig		[GESTURECONFIG]
					cbSize		[integer!]
					return:		[logic!]
				]
				GetGestureInfo: "GetGestureInfo" [
					hIn			[GESTUREINFO]
					hOut		[GESTUREINFO]
					return:		[logic!]
				]
			]
		]
	]
]

zero-memory: func [
	dest	[byte-ptr!]
	size	[integer!]
][
	loop size [dest/value: #"^@" dest: dest + 1]
]

utf16-length?: func [
	s 		[c-string!]
	return: [integer!]
	/local base
][
	base: s
	while [any [s/1 <> null-byte s/2 <> null-byte]][s: s + 2]
	(as-integer s - base) >>> 1							;-- do not count the terminal zero
]