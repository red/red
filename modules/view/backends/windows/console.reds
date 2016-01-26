Red/System [
	Title:	"GUI console"
	Author: "Qingtian Xie"
	File: 	%console.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define VT_MSG_SELALL	0401h

ps:  as tagPAINTSTRUCT 0
hdc: as handle! 0

update-scrollbar: func [
	vt		[terminal!]
	/local
		si	[tagSCROLLINFO]
][
	si: as tagSCROLLINFO vt/scrollbar
	si/cbSize: size? tagSCROLLINFO
	si/fMask: SIF_PAGE or SIF_POS or SIF_RANGE or SIF_DISABLENOSCROLL
	si/nMin: 1
	si/nMax: vt/nlines
	si/nPage: vt/rows
	si/nPos: vt/pos
	SetScrollInfo vt/hwnd SB_VERT si true
]

set-select-color: func [
	vt		[terminal!]
][
	SetTextColor hdc 00FFFFFFh
	SetBkColor hdc 0
]

set-normal-color: func [
	vt		[terminal!]
][
	SetTextColor hdc 0
	SetBkColor hdc 00FFFFFFh
]

copy-to-clipboard: func [
	vt		[terminal!]
	/local
		out		[ring-buffer!]
		data	[red-string!]
		format	[integer!]
		head	[integer!]
		node	[line-node!]
		start	[byte-ptr!]
		end		[byte-ptr!]
		size	[integer!]
		s		[series!]
		hMem	[handle!]
		p		[byte-ptr!]
][
	out: vt/out
	data: out/data
	head: out/s-head
	if head = -1 [exit]
	if any [
		head = -1
		not OpenClipboard vt/hwnd
	][exit]

	node: out/lines + head - 1
	data/head: node/offset + out/s-h-idx
	start: string/rs-head data
	node: out/lines + out/s-tail - 1
	data/head: node/offset + out/s-t-idx
	end: string/rs-head data
	data/head: 0

	s: GET_BUFFER(data)
	either start <= end [
		size: as-integer end - start
	][
		size: as-integer end - as byte-ptr! s/offset
		size: size + as-integer (as byte-ptr! s/tail) - start
	]
	EmptyClipboard
	hMem: GlobalAlloc 42h size + 2			;-- added null terminator
	if null? hMem [CloseClipboard exit]
	p: GlobalLock hMem
	either start <= end [
		copy-memory p start size
	][
		size: as-integer (as byte-ptr! s/tail) - start
		copy-memory p start size
		p: p + size
		copy-memory p as byte-ptr! s/offset as-integer end - as byte-ptr! s/offset
	]
	GlobalUnlock hMem

	format: either GET_UNIT(s) = UCS-2 [CF_UNICODETEXT][CF_TEXT]
	SetClipboardData format hMem
	CloseClipboard
]

paste-from-clipboard: func [
	vt		[terminal!]
	/local
		hMem	[handle!]
		p		[byte-ptr!]
		cp		[integer!]
][
	unless OpenClipboard GetParent vt/hwnd [exit]
	hMem: GetClipboardData CF_UNICODETEXT
	if hMem <> null [
		p: GlobalLock hMem
		if p <> null [
			while [
				cp: (as-integer p/2) << 8 + p/1
				not zero? cp
			][
				either cp = as-integer #"^-" [
					loop 4 [edit vt 32]
				][
					if cp = 10 [cp: 13]
					edit vt cp
				]
				p: p + 2
			]
			GlobalUnlock hMem
		]
	]
	CloseClipboard
]

popup-menu: func [
	vt		[terminal!]
	x		[integer!]
	y		[integer!]
	/local
		menu	[handle!]
		cmd		[integer!]
		select?	[logic!]
		paste?	[logic!]
		flag	[integer!]
][
	menu: CreatePopupMenu
	select?: any [vt/select-all? vt/out/s-head <> -1]
	paste?: any [
		IsClipboardFormatAvailable CF_TEXT
		IsClipboardFormatAvailable CF_UNICODETEXT
	]
	flag: either select? [0][3]
	AppendMenu menu flag WM_COPY #u16 "Copy^-Ctrl+C"
	flag: either paste? [0][3]
	AppendMenu menu flag WM_PASTE #u16 "Paste^-Ctrl+V"
	AppendMenu menu 0800h 0 null
	AppendMenu menu flag VT_MSG_SELALL #u16 "Select All^-Ctrl+A"

	cmd: TrackPopupMenuEx menu TPM_RETURNCMD x y vt/hwnd null
	unless zero? cmd [PostMessage vt/hwnd cmd 0 0]
]

set-font: func [
	vt		[terminal!]
	/local
		dc [handle!]
		tm [tagTEXTMETRIC]
		w  [integer!]
][
	w: 0
	dc: GetDC vt/hwnd
	tm: as tagTEXTMETRIC allocate size? tagTEXTMETRIC
	SelectObject dc vt/font
	GetTextMetrics dc tm
	ReleaseDC vt/hwnd dc
	update-font vt tm/tmAveCharWidth tm/tmHeight
	GetCharWidth32 dc 8220 8220 :w
	extra-table: either w = vt/char-w [stub-table][ambiguous-table]
	free as byte-ptr! tm
]

OS-draw-text: func [
	str		[c-string!]
	len		[integer!]
	x		[integer!]
	y		[integer!]
	w		[integer!]
	h		[integer!]
	/local
		rc		[RECT_STRUCT]
][
	rc: declare RECT_STRUCT
	rc/top: y
	rc/bottom: y + h
	rc/left: x
	rc/right: x + w
	ExtTextOut hdc x y ETO_OPAQUE or ETO_CLIPPED rc str len null
]

OS-init: func [vt [terminal!]][
	vt/scrollbar: as int-ptr! allocate size? tagSCROLLINFO
	vt/font: GetStockObject SYSTEM_FIXED_FONT
	update-scrollbar vt
	ps: as tagPAINTSTRUCT allocate size? tagPAINTSTRUCT
]

OS-close: func [vt [terminal!]][
	free as byte-ptr! vt/scrollbar
	free as byte-ptr! ps
]

OS-hide-caret: func [vt [terminal!]][
	HideCaret vt/hwnd
]

OS-update-caret: func [vt [terminal!] /local w][
	w: vt/char-w
	SetCaretPos vt/caret-x * w vt/caret-y * vt/char-h
	unless vt/caret? [ShowCaret vt/hwnd vt/caret?: yes]
]

OS-refresh: func [
	vt		[terminal!]
	rect	[RECT_STRUCT]
][
	InvalidateRect vt/hwnd rect 0
]

on-key-down: func [
	key		[integer!]
	return: [integer!]
	/local
		ctrl	[integer!]
		shift	[integer!]
][
	ctrl: GetKeyState VK_CONTROL		;@@ GetKeyState return short
	ctrl: WIN32_LOWORD(ctrl)
	shift: GetKeyState VK_SHIFT			;@@ GetKeyState return short
	shift: WIN32_LOWORD(shift)
	switch key [
		VK_HOME		[RS_KEY_HOME]
		VK_END		[RS_KEY_END]
		VK_PRIOR	[RS_KEY_PAGE_UP]
		VK_NEXT		[RS_KEY_PAGE_DOWN]
		VK_LEFT		[RS_KEY_LEFT]
		VK_RIGHT	[RS_KEY_RIGHT]
		VK_UP		[RS_KEY_UP]
		VK_DOWN		[RS_KEY_DOWN]
		VK_DELETE	[RS_KEY_DELETE]
		default		[RS_KEY_NONE]
	]
]

ConsoleWndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		vt		[terminal!]
		tm		[tagTEXTMETRIC]
		dc		[handle!]
		delta	[integer!]
		state	[integer!]
		out		[ring-buffer!]
		p-int	[int-ptr!]
][
	vt: as terminal! GetWindowLong hWnd wc-offset - 4
	switch msg [
		WM_NCCREATE [
			p-int: as int-ptr! lParam
			vt: as terminal! allocate size? terminal!
			v-terminal: as integer! vt
			tm: as tagTEXTMETRIC allocate size? tagTEXTMETRIC
			dc: GetDC hWnd
			SelectObject dc GetStockObject SYSTEM_FIXED_FONT
			GetTextMetrics dc tm
			ReleaseDC hWnd dc
			vt/hwnd: hWnd
			init vt p-int/6 p-int/5 tm/tmAveCharWidth tm/tmHeight
			SetWindowLong hWnd wc-offset - 4 as-integer vt
			free as byte-ptr! tm
			return 1
		]
		WM_ERASEBKGND	 [return 1]					;-- drawing in WM_PAINT to avoid flicker
		WM_PAINT [
			hdc: BeginPaint hWnd ps
			SelectObject hdc vt/font
			paint vt
			EndPaint hWnd ps
			if vt/caret? [update-caret vt]
			update-scrollbar vt
			return 0
		]
		WM_SETFONT [
			vt/font: as handle! wParam
			set-font vt
			refresh vt
			return 0
		]
		WM_SIZE [
			vt/win-w: WIN32_LOWORD(lParam)
			vt/win-h: WIN32_HIWORD(lParam)
			vt/cols: vt/win-w / vt/char-w
			vt/rows: vt/win-h / vt/char-h
			OS-refresh vt null
			return 0
		]
		WM_VSCROLL [
			lParam: WIN32_LOWORD(wParam)
			delta: switch lParam [
				SB_LINEUP	[-1]
				SB_LINEDOWN [1]
				SB_PAGEUP	[0 - vt/rows]
				SB_PAGEDOWN [vt/rows]
				SB_THUMBTRACK [
					wParam: WIN32_HIWORD(wParam)
					either wParam = 1 [SCROLL_TOP][wParam - vt/pos]
				]
				SB_TOP		[SCROLL_TOP]
				SB_BOTTOM	[SCROLL_BOTTOM]
				default [0]
			]
			unless zero? delta [scroll vt delta]
			return 0
		]
		WM_MOUSEWHELL [
			delta: either WIN32_HIWORD(wParam) > 0 [-3][3]
			scroll vt delta
			return 0
		]
		WM_MOUSEACTIVATE [
			SetFocus hWnd
			return 1								;-- MA_ACTIVATE
		]
		WM_SETFOCUS [
			CreateCaret hWnd null 1 vt/char-h
			update-caret vt
			return 0
		]
		WM_KILLFOCUS [
			DestroyCaret
			vt/caret?: no
			return 0
		]
		WM_LBUTTONDOWN [
			cancel-select vt
			either select vt WIN32_LOWORD(lParam) WIN32_HIWORD(lParam) yes [
				SetCapture hWnd
			][
				out: vt/out
				out/s-head: -1
				out/s-tail: -1
				refresh vt
			]
			return 0
		]
		WM_LBUTTONUP [
			vt/select?: no
			out: vt/out
			if all [
				out/s-head = out/s-tail
				out/s-h-idx = out/s-t-idx
			][
				cancel-select vt
				out/s-head: -1
				out/s-tail: -1
				refresh vt
			]
			ReleaseCapture
			return 0
		]
		WM_MOUSEMOVE [
			if vt/select? [
				cancel-select vt
				select vt WIN32_LOWORD(lParam) WIN32_HIWORD(lParam) no
				out: vt/out
				unless all [
					out/s-head = out/s-tail
					out/s-h-idx = out/s-t-idx
				][
					mark-select vt
					refresh vt
				]
			]
			return 0
		]
		WM_KEYDOWN [
			;SendMessage GetParent vt/hwnd WM_COMMAND VTN_KEYDOWN << 16 or (wParam and FFFFh) as-integer vt/hwnd
			edit vt on-key-down wParam
			return 0
		]
		WM_CHAR [
			state: GetKeyState VK_LCONTROL		;@@ GetKeyState return short
			state: WIN32_LOWORD(state)
			unless all [wParam = 3 zero? state][edit vt wParam]
			return 0
		]
		WM_NCDESTROY [
			close vt
		]
		WM_CONTEXTMENU [
			popup-menu vt WIN32_LOWORD(lParam) WIN32_HIWORD(lParam)
		]
		WM_COPY [copy-to-clipboard vt]
		WM_PASTE [paste-from-clipboard vt]
		WM_CLEAR [0]
		VT_MSG_SELALL [
			select-all vt
			OS-refresh vt null
		]
		default [0]
	]
	DefWindowProc hWnd msg wParam lParam
]