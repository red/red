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

tray-data!: alias struct! [
	data		[NOTIFYICONDATAW! value]
	free-ico?	[logic!]
]

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

#define SET_ICON [
	tdata/free-ico?: yes
	either TYPE_OF(img) = TYPE_IMAGE [
		data/hIcon: to-icon img
	][
		data/hIcon: LoadIcon hInstance as c-string! 1
	]
]

init-tray: func [
	parent	[handle!]
	values	[red-value!]
	return: [int-ptr!]
	/local
		tdata [tray-data!]
		data  [NOTIFYICONDATAW!]
		img   [red-image!]
][
	tdata: as tray-data! zero-alloc size? tray-data!
	data: as NOTIFYICONDATAW! tdata
	data/cbSize: size? NOTIFYICONDATAW!
	data/uID: 0
	data/uFlags: NIF_ICON or NIF_MESSAGE
	data/uCallbackMessage: WM_TRAY_CALLBACK
	data/hWnd: parent
	data/uVersion: 4
	img: as red-image! values + FACE_OBJ_IMAGE
	SET_ICON
	Shell_NotifyIconW NIM_ADD data
	Shell_NotifyIconW NIM_SETVERSION data
	SetWindowLong parent wc-offset - 20 as-integer data
	as int-ptr! data
]

update-tray-icon: func [
	hWnd	[handle!]
	img		[red-image!]
	/local
		tdata [tray-data!]
		data  [NOTIFYICONDATAW!]
		icon  [handle!]
][
	tdata: as tray-data! GetWindowLong hWnd wc-offset - 20
	data: as NOTIFYICONDATAW! tdata
	icon: data/hIcon
	SET_ICON
	Shell_NotifyIconW NIM_MODIFY data
	if tdata/free-ico? [DestroyIcon icon]
]

destroy-tray: func [
	hwnd	 [handle!]
	/local
		tdata [tray-data!]
		data  [NOTIFYICONDATAW!]
][
	tdata: as tray-data! GetWindowLong hWnd wc-offset - 20
	data: as NOTIFYICONDATAW! tdata
	Shell_NotifyIconW NIM_DELETE data
	if tdata/free-ico? [DestroyIcon data/hIcon]
	free as byte-ptr! tdata
]
