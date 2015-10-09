Red/System [
	Title:	"Windows text-list widget"
	Author: "Xie Qingtian, Nenad Rakocevic"
	File: 	%text-list.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-text-list: func [
	hWnd		  [handle!]
	data		  [red-block!]
	selected	  [red-integer!]
	/local
		str		  [red-string!]
		tail	  [red-string!]
		c-str	  [c-string!]
		str-saved [c-string!]
		len		  [integer!]
		value	  [integer!]
][
	len: 0
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		while [str < tail][
			c-str: unicode/to-utf16 str
			value: string/rs-length? str
			if len < value [len: value str-saved: c-str]
			if TYPE_OF(str) = TYPE_STRING [
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

	if TYPE_OF(selected) <> TYPE_INTEGER [
		selected/header: TYPE_INTEGER
		selected/value: -1
	]
]

update-list-hbar: func [
	hWnd  [handle!]
	str	  [c-string!]
	len	  [integer!]
	/local
		csize [tagSIZE]
][
	csize: declare tagSIZE
	GetTextExtentPoint32 GetDC hWnd str len csize
	SendMessage hWnd LB_SETHORIZONTALEXTENT csize/width 0
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

update-list: func [
	face  [red-object!]
	value [red-value!]
	sym   [integer!]
	index [integer!]
	part  [integer!]
	drop? [logic!]										;-- TRUE: drop-list or drop-down widgets
	/local
		msg [integer!]
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
					
					either all [
						sym = words/_clear/symbol
						zero? index
					][
						msg: either drop? [CB_RESETCONTENT][LB_RESETCONTENT]
						SendMessage hWnd msg 0 0
					][
						loop part [remove-list-item hWnd index drop?]
					]
				]
				any [
					sym = words/_insert/symbol
					sym = words/_poke/symbol
					sym = words/_put/symbol
				][
					;ownership/unbind-each as red-block! value index part
					
					loop part [
						if sym <> words/_insert/symbol [
							remove-list-item hWnd index drop?
						]
						insert-list-item
							hWnd
							as red-string! block/rs-abs-at as red-block! value index
							index
							drop?
					]
				]
				true [0]
			]
		]
		TYPE_STRING [
			remove-list-item hWnd index drop?
			insert-list-item hWnd as red-string! value index drop?
		]
		default [assert false]			;@@ raise a runtime error
	]
]