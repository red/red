Red/System [
	Title:	"System Tray Widget"
	Author: "Xie Qingtian"
	File: 	%try.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019-2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

with [platform][
	TrayWndProc: func [
		[stdcall]
		hWnd	[handle!]
		msg		[integer!]
		wParam	[integer!]
		lParam	[integer!]
		return: [integer!]
		/local
			flags [integer!]
	][
		switch msg [
			WM_TRAY_CALLBACK [
				flags: 0
				init-current-msg
				current-msg/hWnd: hWnd
				current-msg/msg: msg
				switch WIN32_LOWORD(lParam) [
					WM_MOUSEMOVE [
						make-event current-msg flags EVT_OVER
					]
					WM_LBUTTONDOWN	[
						menu-origin: null							;-- reset if user clicks on menu bar
						menu-ctx: null
						make-event current-msg flags EVT_LEFT_DOWN
					]
					WM_LBUTTONUP	[
						make-event current-msg flags EVT_LEFT_UP
					]
					WM_RBUTTONDOWN	[
						menu-x: current-msg/x
						menu-y: current-msg/y
						menu-origin: null
						menu-ctx: null
						make-event current-msg flags EVT_RIGHT_DOWN
						SetForegroundWindow hWnd
						show-context-menu current-msg menu-x menu-y
					]
					WM_RBUTTONUP	[make-event current-msg flags EVT_RIGHT_UP]
					WM_MBUTTONDOWN	[make-event current-msg flags EVT_MIDDLE_DOWN]
					WM_MBUTTONUP	[make-event current-msg flags EVT_MIDDLE_UP]
					WM_LBUTTONDBLCLK [
						menu-origin: null							;-- reset if user clicks on menu bar
						menu-ctx: null
						make-event current-msg flags EVT_DBL_CLICK
					]
					default [0]
				]
				return 0
			]
			WM_MENUSELECT [
				if wParam <> FFFF0000h [
					menu-selected: WIN32_LOWORD(wParam)
					menu-handle: as handle! lParam
				]
				return 0
			]
			WM_COMMAND [
				if all [zero? lParam wParam < 1000][		;-- heuristic to detect a menu selection (--)'
					unless null? menu-handle [
						do-menu hWnd
						return 0
					]
				]
			]
			default [0]
		]
		DefWindowProc hWnd msg wParam lParam
	]

	init-tray: func [
		parent	[handle!]
		values	[red-value!]
		return: [int-ptr!]
		/local
			data [NOTIFYICONDATAW!]
	][
		data: as NOTIFYICONDATAW! zero-alloc size? NOTIFYICONDATAW!
		data/cbSize: size? NOTIFYICONDATAW!
		data/uID: 0
		data/uFlags: NIF_ICON or NIF_MESSAGE
		data/uCallbackMessage: WM_TRAY_CALLBACK
		data/hWnd: parent
		data/uVersion: 4
		data/hIcon: LoadIcon hInstance as c-string! 1
		Shell_NotifyIconW NIM_ADD data
		Shell_NotifyIconW NIM_SETVERSION data
		SetWindowLong parent wc-offset - 20 as-integer data
		as int-ptr! data
	]

	destroy-tray: func [
		hwnd	 [handle!]
		/local
			data [byte-ptr!]
	][
		data: as byte-ptr! GetWindowLong hWnd wc-offset - 20
		Shell_NotifyIconW NIM_DELETE as NOTIFYICONDATAW! data
		free data
	]
]
