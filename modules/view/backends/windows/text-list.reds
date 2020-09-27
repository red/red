Red/System [
	Title:	"Windows text-list widget"
	Author: "Xie Qingtian, Nenad Rakocevic"
	File: 	%text-list.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-text-list: func [
	hWnd	 [handle!]
	data	 [red-block!]
	selected [red-integer!]
	/local
		str		  [red-string!]
		tail	  [red-string!]
		c-str	  [c-string!]
		str-saved [c-string!]
		type	  [integer!]
		len		  [integer!]
		value	  [integer!]
][
	SendMessage hWnd LB_RESETCONTENT 0 0
	
	len: 0
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		while [str < tail][
			type: TYPE_OF(str)
			if ANY_STRING?(type) [
				c-str: unicode/to-utf16 str
				value: string/rs-length? str
				if len < value [len: value str-saved: c-str]
				
				SendMessage 
					hWnd
					LB_ADDSTRING
					0
					as-integer c-str
			]
			str: str + 1
		]
		unless zero? len [
			update-list-hbar hWnd str-saved len
		]
	]
	SetWindowLong hWnd wc-offset - 4 len

	either TYPE_OF(selected) <> TYPE_INTEGER [
		selected/header: TYPE_INTEGER
		selected/value: -1
	][
		SendMessage hWnd LB_SETCURSEL selected/value - 1 0
	]
]

init-drop-list: func [
	hWnd		[handle!]
	data		[red-block!]
	caption		[c-string!]
	selected	[red-integer!]
	drop-list?	[logic!]
	/local
		str	 [red-string!]
		tail [red-string!]
		type [integer!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		
		SendMessage hWnd CB_RESETCONTENT 0 0
		
		while [str < tail][
			type: TYPE_OF(str)
			if ANY_STRING?(type) [
				SendMessage 
					hWnd
					CB_ADDSTRING
					0
					as-integer unicode/to-utf16 str
			]
			str: str + 1
		]
	]
	either any [null? caption drop-list?][
		if TYPE_OF(selected) = TYPE_INTEGER [
			SendMessage hWnd CB_SETCURSEL selected/value - 1 0
		]
	][
		SetWindowText hWnd caption
	]
]

update-list-hbar: func [
	hWnd  [handle!]
	str	  [c-string!]
	len	  [integer!]
	/local
		csize [tagSIZE]
		dc	  [handle!]
		hFont [handle!]
		saved [handle!]
][
	csize: declare tagSIZE
	dc: GetDC hWnd
	hFont: SendMessage hWnd WM_GETFONT 0 0
	if hFont <> null [saved: SelectObject dc hFont]
	GetTextExtentPoint32 dc str len csize
	if hFont <> null [SelectObject dc saved]
	ReleaseDC dc
	SendMessage hWnd LB_SETHORIZONTALEXTENT csize/width + 4 0
]

insert-list-item: func [
	hWnd  [handle!]
	item  [red-string!]
	pos	  [integer!]
	drop? [logic!]
	/local
		str [c-string!]
		msg	[integer!]
		len [integer!]
][
	unless TYPE_OF(item) = TYPE_STRING [exit]

	msg: either drop? [CB_GETCOUNT][LB_GETCOUNT]
	len: as-integer SendMessage hWnd msg 0 0
	if pos > len [pos: len]

	str: unicode/to-utf16 item
	msg: either drop? [CB_INSERTSTRING][LB_INSERTSTRING]
	SendMessage hWnd msg pos as-integer str
	unless drop? [
		len: string/rs-length? item
		if len > GetWindowLong hWnd wc-offset - 4 [
			SetWindowLong hWnd wc-offset - 4 len
			update-list-hbar hWnd str len
		]
	]
]

remove-list-item: func [
	hWnd  [handle!]
	pos	  [integer!]
	drop? [logic!]
	/local
		msg	[integer!]
][
	msg: either drop? [CB_DELETESTRING][LB_DELETESTRING]
	SendMessage hWnd msg pos 0
	;@@ update the horizontal extent value for scrollbar?
	;@@ update the selected facet
]

remove-list-items: func [
	hWnd  [handle!]
	pos	  [integer!]
	part  [integer!]
	str	  [red-string!]
	drop? [logic!]
][
	loop part [
		if TYPE_OF(str) = TYPE_STRING [
			remove-list-item hWnd pos drop?
		]
	]
]

update-list: func [
	face  [red-object!]
	value [red-value!]
	sym   [integer!]
	new	  [red-value!]
	index [integer!]
	part  [integer!]
	drop? [logic!]										;-- TRUE: drop-list or drop-down widgets
	/local
		hWnd [handle!]
		msg  [integer!]
		str  [red-string!]
		sel  [red-integer!]
		blk  [red-block!]
		data [red-block!]
		val  [red-value!]
		i n	 [integer!]
][
	hWnd: get-face-handle face
	switch TYPE_OF(value) [
		TYPE_BLOCK [
			;-- caculate the index in native widget, e.g.
			;-- we have data: ["abc" 32 "zyz" 8 "xxx"]   index: 4
			;-- the actual insertion index: 2
			val: block/rs-head as red-block! (object/get-values face) + FACE_OBJ_DATA
			i: 0 n: 0
			while [n < index][
				if TYPE_OF(val) = TYPE_STRING [i: i + 1]
				val: val + 1
				n: n + 1
			]

			blk: as red-block! value
			case [
				any [
					sym = words/_remove/symbol
					sym = words/_take/symbol
					sym = words/_clear/symbol
					sym = words/_reverse/symbol
					sym = words/_put/symbol
					sym = words/_poke/symbol
					sym = words/_move/symbol
				][
					data: as red-block! new
					if all [
						sym = words/_move/symbol
						data/node <> blk/node		;-- move to another block
					][
						;@@ TBD handle it properly
						;@@ need to trigger event for origin block in `move` action
						exit
					]

					ownership/unbind-each blk index part
					
					either all [
						sym = words/_clear/symbol
						zero? index
					][
						msg: either drop? [CB_RESETCONTENT][LB_RESETCONTENT]
						SendMessage hWnd msg 0 0
					][
						str: as red-string! block/rs-abs-at blk index
						remove-list-items hWnd i part str drop?
					]
				]
				any [
					sym = words/_inserted/symbol
					sym = words/_appended/symbol
					sym = words/_poked/symbol
					sym = words/_put-ed/symbol
					sym = words/_reversed/symbol
					sym = words/_moved/symbol
				][
					str: as red-string! either any [
						null? new
						TYPE_OF(new) = TYPE_BLOCK
					][
						block/rs-abs-at blk index
					][
						new
					]
					ownership/unbind-each as red-block! value index part
					loop part [
						if TYPE_OF(str) = TYPE_STRING [
							insert-list-item hWnd str i drop?
							i: i + 1
							ownership/bind as red-value! str face _data
						]
						str: str + 1
					]
				]
				true [0]
			]
		]
		TYPE_ANY_STRING [
			if any [sym = words/_lowercase/symbol sym = words/_uppercase/symbol][
				sel: as red-integer! (object/get-values face) + FACE_OBJ_SELECTED
				index: sel/value - 1
			]
			remove-list-item hWnd index drop?
			insert-list-item hWnd as red-string! value index drop?
		]
		default [assert false]			;@@ raise a runtime error
	]
]