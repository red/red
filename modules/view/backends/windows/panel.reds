Red/System [
	Title:	"Windows events handling"
	Author: "Nenad Rakocevic"
	File: 	%panel.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-panel: func [
	values [red-value!]
	phWnd  [handle!]									;-- parent window handle
	/local
		parent	  [red-object!]
		type	  [red-word!]
		pair	  [red-pair!]
		win-rect  [RECT_STRUCT]
		calc-rect [RECT_STRUCT]
][
	win-rect:  declare RECT_STRUCT
	calc-rect: declare RECT_STRUCT
	parent: as red-object! values + FACE_OBJ_PARENT

	if TYPE_OF(parent) = TYPE_OBJECT [
		type: as red-word! get-node-facet parent/ctx FACE_OBJ_TYPE

		if tab-panel = symbol/resolve type/symbol [
			GetClientRect phWnd win-rect
			copy-memory 
				as byte-ptr! calc-rect
				as byte-ptr! win-rect
				size? win-rect
			SendMessage phWnd TCM_ADJUSTRECT 0 as-integer calc-rect

			pair: as red-pair! values + FACE_OBJ_OFFSET
			pair/x: calc-rect/left - win-rect/left - 3
			pair/y: calc-rect/top  - win-rect/top - 1

			pair: as red-pair! values + FACE_OBJ_SIZE
			pair/x: calc-rect/right  - calc-rect/left + 4
			pair/y: calc-rect/bottom - calc-rect/top + 3
		]
	]
]

PanelWndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		nmhdr [tagNMHDR]
][
	switch msg [
		WM_COMMAND [
			process-command-event hWnd msg wParam lParam
		]
		WM_VSCROLL
		WM_HSCROLL [
			unless zero? lParam [						;-- message from trackbar
				unless null? current-msg [
					current-msg/hWnd: as handle! lParam	;-- trackbar handle
					get-slider-pos current-msg
					make-event current-msg 0 EVT_CHANGE
					return 0
				]
			]
		]
		WM_NOTIFY [
			nmhdr: as tagNMHDR lParam
			switch nmhdr/code [
				TCN_SELCHANGING [return process-tab-select nmhdr/hWndFrom]
				TCN_SELCHANGE	[process-tab-change nmhdr/hWndFrom]
				default [0]
			]
		]
		WM_MENUSELECT [
			if wParam <> FFFF0000h [
				menu-selected: WIN32_LOWORD(wParam)
				menu-handle: as handle! lParam
			]
			return 0
		]
		WM_ERASEBKGND [
			if paint-background hWnd as handle! wParam [return 1]
		]
		default [0]
	]
	if ext-parent-proc? [call-custom-proc hWnd msg wParam lParam]
	;DefWindowProc hWnd msg wParam lParam					;@@ need to refactor base face, temporary use it to refresh background
	CallWindowProc as wndproc-cb! :WndProc hWnd msg wParam lParam
]