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

refresh-tab-panel: func [
	hWnd [handle!]
	/local
		rect [RECT_STRUCT]
][
	unless DWM-enabled? [
		rect: declare RECT_STRUCT
		GetClientRect hWnd rect
		InvalidateRect hWnd rect 0
	]
]

select-tab: func [
	hWnd [handle!]
	idx  [integer!]
	/local
		nmhdr  [tagNMHDR]
		parent [handle!]
][
	nmhdr: declare tagNMHDR
	nmhdr/hwndFrom: hWnd
	nmhdr/idFrom:	0
	nmhdr/code:		TCN_SELCHANGING
	
	parent: GetParent hWnd
	SendMessage parent WM_NOTIFY 0 as-integer nmhdr

	;SendMessage hWnd TCM_SETCURSEL   idx 0
	SendMessage hWnd TCM_SETCURFOCUS idx 0
	
	nmhdr/hwndFrom: hWnd
	nmhdr/idFrom:	0
	nmhdr/code: TCN_SELCHANGE
	SendMessage parent WM_NOTIFY 0 as-integer nmhdr
]

process-tab-select: func [
	hWnd	[handle!]
	return: [integer!]
][
	as-integer EVT_NO_DISPATCH = make-event 
		current-msg
		1 + as-integer SendMessage hWnd TCM_GETCURSEL 0 0
		EVT_SELECT
]

process-tab-change: func [
	hWnd [handle!]
	/local
		idx [integer!]
][
	idx: as-integer SendMessage hWnd TCM_GETCURSEL 0 0
	current-msg/hWnd: hWnd
	set-tab get-facets current-msg idx
	make-event current-msg idx + 1 EVT_CHANGE
	current-msg/hWnd: hWnd								;-- could have been changed
	get-selected current-msg idx + 1
]

adjust-parent: func [									;-- prevent tabcontrol from having children
	hWnd   [handle!]
	parent [handle!]
	x	   [integer!]
	y	   [integer!]
	/local
		values [red-value!]
		type   [red-word!]
		pos	   [red-pair!]
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

	refresh-tab-panel hWnd
]

set-tabs: func [
	hWnd   [handle!]
	facets [red-value!]
	/local
		data [red-block!]
		str	 [red-string!]
		tail [red-string!]
		int	 [red-integer!]
		nb	 [integer!]
][
	data: as red-block! facets + FACE_OBJ_DATA
	nb: 0
	
	SendMessage hWnd TCM_DELETEALLITEMS 0 0

	if TYPE_OF(data) = TYPE_BLOCK [
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		nb: 0
		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [
				insert-tab hWnd str nb
				nb: nb + 1
			]
			str: str + 1
		]
	]
	int: as red-integer! facets + FACE_OBJ_SELECTED

	either TYPE_OF(int) <> TYPE_INTEGER [
		int/header: TYPE_INTEGER						;-- force selection on first tab
		int/value:  1
	][
		case [
			int/value < 1  [int/value: 1]
			int/value > nb [int/value: nb]
			true 		   [0]
		]
		select-tab hWnd int/value - 1
	]
]

show-tab: func [
	hWnd [handle!]
	flag [integer!]
][
	ShowWindow hWnd flag
	unless win8+? [
		if flag = SW_SHOW [flag: SW_SHOWNA]
		update-layered-window hWnd null null null flag
	]
]

get-panel-handle: func [
	hWnd	[handle!]			;-- Tab-panel handle!
	return: [handle!]
	/local
		values	[red-value!]
		pane	[red-block!]
		idx		[red-integer!]
		obj		[red-object!]
][
	values: get-face-values hWnd
	pane: as red-block! values + FACE_OBJ_PANE
	idx: as red-integer! values + FACE_OBJ_SELECTED
	obj: as red-object! (block/rs-head pane) + idx/value - 1
	either TYPE_OF(obj) = TYPE_OBJECT [
		get-face-handle obj
	][
		null
	]
]

update-tab-contents: func [
	hWnd	[handle!]
	type	[integer!]
	/local
		nshow  [integer!]
		parent [handle!]
		values [red-value!]
		show?  [red-logic!]
		pane   [red-block!]
		pos    [red-pair!]
		obj    [red-object!]
		tail   [red-object!]
][
	parent: hWnd
	values: get-face-values parent
	switch type [
		FACE_OBJ_SIZE
		FACE_OBJ_OFFSET [
			pane: as red-block! values + FACE_OBJ_PANE
			if TYPE_OF(pane) = TYPE_BLOCK [
				obj:  as red-object! block/rs-head pane
				tail: as red-object! block/rs-tail pane
				while [obj < tail][
					if TYPE_OF(obj) = TYPE_OBJECT [
						hWnd: get-face-handle obj
						values: get-node-facet obj/ctx 0
						init-panel values parent
						either type = FACE_OBJ_SIZE [
							change-size
								hWnd
								as red-pair! values + FACE_OBJ_SIZE panel
						][
							pos: as red-pair! values + FACE_OBJ_OFFSET
							adjust-parent hWnd parent pos/x pos/y
						]
					]
					obj: obj + 1
				]
			]
		]
		FACE_OBJ_VISIBLE? [
			show?: as red-logic! values + FACE_OBJ_VISIBLE?
			nshow: either show?/value [SW_SHOW][SW_HIDE]
			show-tab get-panel-handle parent nshow
		]
		default [0]
	]
]

set-tab: func [
	facets [red-value!]
	idx	   [integer!]
	/local
		pane   [red-block!]
		old	   [red-integer!]
		panels [red-value!]
		obj	   [red-object!]
		hWnd   [handle!]
		len	   [integer!]
		bool   [red-logic!]
][
	pane: as red-block! facets + FACE_OBJ_PANE

	if TYPE_OF(pane) = TYPE_BLOCK [
		old: as red-integer! facets + FACE_OBJ_SELECTED
		panels: block/rs-head pane
		len:	block/rs-length? pane

		if idx <= len [
			obj: as red-object! panels + idx
			if TYPE_OF(obj) = TYPE_OBJECT [
				bool: as red-logic! get-node-facet obj/ctx FACE_OBJ_VISIBLE?
				bool/value: true
				hWnd: get-face-handle obj
				show-tab hWnd SW_SHOW
				BringWindowToTop hWnd
			]
		]
		if all [
			TYPE_OF(old) = TYPE_INTEGER
			old/value > 0
			old/value <= len
			old/value - 1 <> idx
		][
			obj: as red-object! panels + old/value - 1
			if TYPE_OF(obj) = TYPE_OBJECT [
				bool: as red-logic! get-node-facet obj/ctx FACE_OBJ_VISIBLE?
				bool/value: false
				show-tab get-face-handle obj SW_HIDE
			]
		]
	]
]

update-tabs: func [
	face  [red-object!]
	value [red-value!]
	sym   [integer!]
	new	  [red-value!]
	index [integer!]
	part  [integer!]
	/local
		hWnd [handle!]
		str  [red-string!]
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
					ownership/unbind-each as red-block! value index part
					loop part [
						SendMessage hWnd TCM_DELETEITEM index 0
						refresh-tab-panel hWnd
					]
				]
				any [
					sym = words/_insert/symbol
					sym = words/_poke/symbol
					sym = words/_put/symbol
				][
					str: as red-string! either null? new [
						block/rs-abs-at as red-block! value index
					][
						new
					]
					loop part [
						if sym <> words/_insert/symbol [
							;ownership/unbind-each as red-block! value index part
							SendMessage hWnd TCM_DELETEITEM index 0
						]
						insert-tab hWnd str index
						str: str + 1
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