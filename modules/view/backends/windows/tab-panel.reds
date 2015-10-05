Red/System [
	Title:	"Windows Tab-panel widget"
	Author: "Nenad Rakocevic"
	File: 	%tab-panel.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]


process-tab-select: func [
	hWnd	[handle!]
	return: [integer!]
][
	as-integer EVT_NO_PROCESS = make-event 
		current-msg
		as-integer SendMessage hWnd TCM_GETCURSEL 0 0
		EVT_SELECT
]

process-tab-change: func [
	hWnd [handle!]
	/local
		idx [integer!]
][
	idx: as-integer SendMessage hWnd TCM_GETCURSEL 0 0
	current-msg/hWnd: hWnd
	set-tab current-msg idx
	make-event current-msg idx + 1 EVT_CHANGE
	get-selected current-msg idx + 1
]

adjust-parent: func [									;-- prevent tabcontrol from having children
	hWnd   [handle!]
	parent [handle!]
	x	   [integer!]
	y	   [integer!]
	/local
		type [red-word!]
		pos	 [red-pair!]
][
	values: get-face-values parent
	type: as red-word! values + FACE_OBJ_TYPE

	if tab-panel = symbol/resolve type/symbol [
		SetParent hWnd GetParent parent
		pos: as red-pair! values + FACE_OBJ_OFFSET
		SetWindowPos hWnd null pos/x + x pos/y + y 0 0 SWP_NOSIZE or SWP_NOZORDER
	]
]

insert-tab: func [
	hWnd  [handle!]
	str	  [red-string!]
	index [integer!]
	/local
		item [TCITEM]
][
	item: declare TCITEM
	item/mask: TCIF_TEXT
	item/pszText: unicode/to-utf16 str
	item/cchTextMax: string/rs-length? str
	item/iImage: -1
	item/lParam: 0

	SendMessage
		hWnd
		TCM_INSERTITEMW
		index
		as-integer item
]

set-tabs: func [
	hWnd   [handle!]
	facets [red-value!]
	/local
		data [red-block!]
		str	 [red-string!]
		tail [red-string!]
		item [TCITEM]
		i	 [integer!]
][
	item: declare TCITEM
	data: as red-block! facets + FACE_OBJ_DATA

	if TYPE_OF(data) = TYPE_BLOCK [
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		i: 0
		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [insert-tab hWnd str i]
			i: i + 1
			str: str + 1
		]
	]
	int: as red-integer! facets + FACE_OBJ_SELECTED

	if TYPE_OF(int) <> TYPE_INTEGER [
		int/header: TYPE_INTEGER						;-- force selection on first tab
		int/value:  1
	]
]

set-tab: func [
	msg	 [tagMSG]
	idx	 [integer!]
	/local
		facets [red-value!]
		pane   [red-block!]
		old	   [red-integer!]
		panels [red-value!]
		obj	   [red-object!]
		len	   [integer!]
][
	facets: get-facets msg
	pane: as red-block! facets + FACE_OBJ_PANE

	if TYPE_OF(pane) = TYPE_BLOCK [
		old: as red-integer! facets + FACE_OBJ_SELECTED
		panels: block/rs-head pane
		len:	block/rs-length? pane

		if idx <= len [
			obj: as red-object! panels + idx SW_SHOW
			if TYPE_OF(obj) = TYPE_OBJECT [
				ShowWindow get-face-handle obj SW_SHOW
			]
		]
		if old/value <= len [
			obj: as red-object! panels + old/value - 1
			if TYPE_OF(obj) = TYPE_OBJECT [
				ShowWindow get-face-handle obj SW_HIDE
			]
		]
	]
]

update-tabs: func [
	face  [red-object!]
	value [red-value!]
	sym   [integer!]
	index [integer!]
	part  [integer!]
][
	hWnd: get-face-handle face
	switch TYPE_OF(value) [
		TYPE_BLOCK [
			case [
				any [
					sym = words/_remove/symbol
					sym = words/_take/symbol
					sym = words/_clear/symbol
				][
					;@@ unbind removed items
					loop part [SendMessage hWnd TCM_DELETEITEM index 0]
				]
				any [
					sym = words/_insert/symbol
					sym = words/_poke/symbol
					sym = words/_put/symbol
				][
					loop part [
						if sym <> words/_insert/symbol [
							SendMessage hWnd TCM_DELETEITEM index 0
							;@@ unbind old value
						]
						insert-tab
							hWnd
							as red-string! block/rs-abs-at as red-block! value index
							index
					]
				]
				true [0]
			]
		]
		TYPE_STRING [
			SendMessage hWnd TCM_DELETEITEM index 0
			insert-tab hWnd as red-string! value index
		]
		default [assert false]			;@@ raise a runtime error
	]
]