Red/System [
	Title:	"Windows Tab-panel widget"
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
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		len: 0
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
	if TYPE_OF(selected) <> TYPE_INTEGER [
		selected/header: TYPE_INTEGER
		selected/value: -1
	]
]

update-list-hbar: func [
	hWnd [handle!]
	str	 [c-string!]
	len	 [integer!]
	/local
		csize [tagSIZE]
][
	csize: declare tagSIZE
	GetTextExtentPoint32 GetDC hWnd str len csize
	SendMessage hWnd LB_SETHORIZONTALEXTENT csize/width 0
]

insert-list-item: func [
	hWnd [handle!]
	item [red-string!]
	pos	 [integer!]
	/local
		str [c-string!]
][
	str: unicode/to-utf16 item
	SendMessage hWnd LB_INSERTSTRING pos as-integer str
	update-list-hbar hWnd str string/rs-length? item
]

remove-list-item: func [
	hWnd [handle!]
	pos	 [integer!]
][
	SendMessage hWnd LB_DELETESTRING pos 0
	;@@ update the horizontal extent value for scrollbar?
	;@@ update the selected facet
]