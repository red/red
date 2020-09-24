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
