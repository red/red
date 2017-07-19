Red/System [
	Title:	"Windows Menu widget"
	Author: "Nenad Rakocevic"
	File: 	%menu.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

menu-selected:	-1										;-- last selected menu item ID
menu-handle: 	as handle! 0							;-- last selected menu handle
menu-origin:	as handle! 0							;-- window where context menu was opened from
menu-ctx:		as handle! 0							;-- context menu handle


build-menu: func [
	menu	[red-block!]
	hMenu	[handle!]
	return: [handle!]
	/local
		value [red-value!]
		tail  [red-value!]
		next  [red-value!]
		str	  [red-string!]
		w	  [red-word!]
		item  [MENUITEMINFO]
		pos	  [integer!]
][
	if TYPE_OF(menu) <> TYPE_BLOCK [return null] 

	item: declare MENUITEMINFO
	item/cbSize:  size? MENUITEMINFO
	item/fMask:	  MIIM_STRING or MIIM_FTYPE
	item/fType:	  MFT_STRING

	value: block/rs-head menu
	tail:  block/rs-tail menu

	pos: 0
	while [value < tail][
		switch TYPE_OF(value) [
			TYPE_STRING [
				str: as red-string! value
				item/fType:	MFT_STRING
				item/fMask:	MIIM_STRING or MIIM_ID or MIIM_DATA
				next: value + 1

				if next < tail [
					switch TYPE_OF(next) [
						TYPE_BLOCK [
							item/hSubMenu: build-menu as red-block! next CreatePopupMenu
							item/fMask:	item/fMask or MIIM_SUBMENU
							value: value + 1
						]
						TYPE_WORD [
							w: as red-word! next
							item/dwItemData: w/symbol
							item/fMask:	item/fMask or MIIM_DATA
							value: value + 1
						]
						default [0]
					]
				]
				item/cch: string/rs-length? str
				item/dwTypeData: unicode/to-utf16 str
				item/wID: pos
				InsertMenuItem hMenu pos true item
				pos: pos + 1
			]
			TYPE_WORD [
				w: as red-word! value
				if w/symbol = --- [
					item/fMask: MIIM_FTYPE or MIIM_ID or MIIM_DATA
					item/fType:	MFT_SEPARATOR
					item/wID: pos
					InsertMenuItem hMenu pos true item
					pos: pos + 1
				]
			]
			default [0]
		]
		value: value + 1
	]
	hMenu
]

menu-bar?: func [
	spec	[red-block!]
	type	[integer!]
	return: [logic!]
	/local
		w	[red-word!]
][
	if all [
		TYPE_OF(spec) = TYPE_BLOCK
		not block/rs-tail? spec
		type = window
	][
		w: as red-word! block/rs-head spec
		return not all [
			TYPE_OF(w) = TYPE_WORD
			popup = symbol/resolve w/symbol
		]
	]
	no
]

show-context-menu: func [
	msg		[tagMSG]
	x		[integer!]
	y		[integer!]
	return: [logic!]									;-- TRUE: menu displayed
	/local
		values [red-value!]
		spec   [red-block!]
		w	   [red-word!]
		hWnd   [handle!]
		hMenu  [handle!]
][
	values: get-facets msg
	spec: as red-block! values + FACE_OBJ_MENU
	menu-selected: -1
	menu-handle: null

	if TYPE_OF(spec) = TYPE_BLOCK [
		w: as red-word! values + FACE_OBJ_TYPE
		if menu-bar? spec symbol/resolve w/symbol [
			return no
		]
		hWnd: GetParent msg/hWnd			;@@ why use parent?
		if null? hWnd [hWnd: msg/hWnd]
		menu-origin: msg/hWnd

		hMenu: build-menu spec CreatePopupMenu
		menu-ctx: hMenu
		TrackPopupMenuEx hMenu 0 x y hWnd null
		return yes
	]
	no
]

get-menu-id: func [
	hMenu	[handle!]
	pos		[integer!]
	return: [integer!]
	/local
		item [MENUITEMINFO]
][
	item: declare MENUITEMINFO 
	item/cbSize:  size? MENUITEMINFO
	item/fMask:	  MIIM_DATA
	GetMenuItemInfo hMenu pos true item
	return item/dwItemData
]

do-menu: func [
	hWnd [handle!]
	/local
		res	[integer!]
][
	res: get-menu-id menu-handle menu-selected
	if null? menu-origin [menu-origin: hWnd]
	current-msg/hWnd: menu-origin
	make-event current-msg res EVT_MENU
	unless null? menu-ctx [DestroyMenu menu-ctx]		;-- recursive destruction
	menu-origin: null
]