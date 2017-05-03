Red/System [
	Title:	"Appkit Tab-panel widget"
	Author: "Qingtian Xie"
	File: 	%tab-panel.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

select-tab: func [
	hWnd [integer!]
	int  [red-integer!]
	/local
		nb	[integer!]
		idx [integer!]
][
	nb: objc_msgSend [hWnd sel_getUid "numberOfTabViewItems"]
	idx: int/value
	case [
		idx < 1  [idx: 1]
		idx > nb [idx: nb]
		true	 [0]
	]
	int/value: idx
	objc_msgSend [hWnd sel_getUid "selectTabViewItemAtIndex:" idx - 1]
]

insert-tab: func [
	hWnd  [integer!]
	str	  [red-string!]
	index [integer!]
][
	0
]

set-tabs: func [
	obj		[integer!]
	facets	[red-value!]
	/local
		data	[red-block!]
		pane	[red-block!]
		str		[red-string!]
		tail	[red-string!]
		int		[red-integer!]
		nb		[integer!]
		idx		[integer!]
		item	[integer!]
		title	[integer!]
		panel	[integer!]
		face	[red-object!]
		end		[red-object!]
][
	nb: objc_msgSend [obj sel_getUid "numberOfTabViewItems"]
	idx: nb - 1
	while [idx >= 0][							;-- remove all tabs
		objc_msgSend [
			obj sel_getUid "removeTabViewItem:"
			objc_msgSend [obj sel_getUid "tabViewItemAtIndex:" idx]
		]
		idx: idx - 1
	]

	data: as red-block! facets + FACE_OBJ_DATA
	pane: as red-block! facets + FACE_OBJ_PANE
	nb: 0

	if TYPE_OF(data) = TYPE_BLOCK [
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		face: as red-object! block/rs-head pane
		end:  as red-object! block/rs-tail pane
		nb: 0
		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [
				title: to-NSString str
				item: objc_msgSend [objc_getClass "NSTabViewItem" sel_getUid "alloc"]
				item: objc_msgSend [item sel_getUid "initWithIdentifier:" 0]
				objc_msgSend [item sel_getUid "setLabel:" title]
				objc_msgSend [obj sel_getUid "addTabViewItem:" item]

				if face < end [
					panel: get-face-handle face
					objc_msgSend [item sel_getUid "setView:" panel]
					face: face + 1
				]
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
		select-tab obj int
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
		hWnd [integer!]
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
						0;-- remove tab
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
							0;-- remove tab
						]
						insert-tab hWnd str index
						str: str + 1
					]
				]
				true [0]
			]
		]
		TYPE_STRING [
			insert-tab hWnd as red-string! value index
		]
		default [assert false]			;@@ raise a runtime error
	]
]