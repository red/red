Red/System [
	Title:	"Windows fonts management"
	Author: "Nenad Rakocevic"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

make-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [handle!]
	/local
		values	[red-value!]
		int		[red-integer!]
		value	[red-value!]
		bool	[red-logic!]
		style	[red-word!]
		str		[red-string!]
		blk		[red-block!]
		weight	[integer!]
		height	[integer!]
		angle	[integer!]
		quality [integer!]
		len		[integer!]
		sym		[integer!]
		name	[c-string!]
		italic? [logic!]
		under?	[logic!]
		strike? [logic!]
		hFont	[handle!]
][
	values: object/get-values font
	
	int: as red-integer! values + FONT_OBJ_SIZE
	height: either TYPE_OF(int) <> TYPE_INTEGER [0][
		0 - (int/value * log-pixels-y / 72)
	]
	
	int: as red-integer! values + FONT_OBJ_ANGLE
	angle: either TYPE_OF(int) = TYPE_INTEGER [int/value * 10][0]	;-- in tenth of degrees
	
	value: values + FONT_OBJ_ANTI-ALIAS?
	switch TYPE_OF(value) [
		TYPE_LOGIC [
			bool: as red-logic! value
			quality: either bool/value [4][0]			;-- ANTIALIASED_QUALITY
		]
		TYPE_WORD [
			style: as red-word! value
			either ClearType = symbol/resolve style/symbol [
				quality: 5								;-- CLEARTYPE_QUALITY
			][
				quality: 0
				;fire error ?
			]
		]
		default [quality: 0]							;-- DEFAULT_QUALITY
	]
	
	str: as red-string! values + FONT_OBJ_NAME
	name: either TYPE_OF(str) = TYPE_STRING [
		len: string/rs-length? str
		if len > 31 [len: 31]
		unicode/to-utf16-len str :len yes
	][default-font-name]

	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			len: block/rs-length? blk
		]
		TYPE_WORD  [1]
		default	   [0]
	]
	
	italic?: no
	under?:  no
	strike?: no
	weight:	 0

	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [
				sym = _bold	 	 [weight:  700]
				sym = _italic	 [italic?: yes]
				sym = _underline [under?:  yes]
				sym = _strike	 [strike?: yes]
				true			 [0]
			]
			style: style + 1
		]
	]
	
	hFont: CreateFont
		height
		0												;-- nWidth
		0												;-- nEscapement
		angle											;-- nOrientation
		weight
		as-integer italic?
		as-integer under?
		as-integer strike?
		1												;-- DEFAULT_CHARSET
		0												;-- OUT_DEFAULT_PRECIS
		0												;-- CLIP_DEFAULT_PRECIS
		quality
		0												;-- DEFAULT_PITCH
		name

	blk: as red-block! values + FONT_OBJ_STATE
	either TYPE_OF(blk) <> TYPE_BLOCK [
		block/make-at blk 2
		handle/make-in blk as-integer hFont
		none/make-in blk								;-- DWrite font
	][
		int: as red-integer! block/rs-head blk
		int/header: TYPE_HANDLE
		int/value: as-integer hFont
	]

	if face <> null [
		blk: block/make-at as red-block! values + FONT_OBJ_PARENT 4
		block/rs-append blk as red-value! face
	]
	hFont
]

set-font: func [
	hWnd   [handle!]
	face   [red-object!]
	values [red-value!]
	/local
		font   [red-object!]
		state  [red-block!]
		handle [red-handle!]
		hFont  [handle!]
][
	font: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(font) <> TYPE_OBJECT [
		SendMessage hWnd WM_SETFONT as-integer default-font 0
		exit
	]
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	
	hFont: as handle! either TYPE_OF(state) = TYPE_BLOCK [
		handle: as red-handle! block/rs-head state
		handle/value
	][
		make-font face font
	]
	SendMessage hWnd WM_SETFONT as-integer hFont 0
]

get-font-handle: func [
	font	[red-object!]
	idx		[integer!]							;-- 0-based index
	return: [handle!]
	/local
		state  [red-block!]
		handle [red-handle!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		handle: (as red-handle! block/rs-head state) + idx
		if TYPE_OF(handle) = TYPE_HANDLE [
			return as handle! handle/value
		]
	]
	null
]

get-hfont: func [				;-- get or create a HFONT handle from font! object
	face	[red-object!]
	font	[red-object!]
	return: [handle!]
	/local
		hFont [handle!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return null]
	hFont: get-font-handle font 0
	if null? hFont [hFont: make-font face font]
	hFont
]

free-font: func [
	font [red-object!]
	/local
		state [red-block!]
		hFont [handle!]
		this  [this!]
		obj   [IUnknown]
][
	hFont: get-font-handle font 0
	if hFont <> null [
		DeleteObject hFont
		state: as red-block! (object/get-values font) + FONT_OBJ_STATE
		state/header: TYPE_NONE
	]
	unless winxp? [
		this: as this! get-font-handle font 1
		COM_SAFE_RELEASE(obj this)
	]
]

update-font: func [
	font [red-object!]
	flag [integer!]
][
	switch flag [
		FONT_OBJ_NAME
		FONT_OBJ_SIZE
		FONT_OBJ_STYLE
		FONT_OBJ_ANGLE
		FONT_OBJ_ANTI-ALIAS? [
			free-font font
			make-font null font
		]
		default [0]
	]
]

OS-request-font: func [
	font	 [red-object!]
	selected [red-object!]
	mono?	 [logic!]
	return:  [red-object!]
	/local
		values	[red-value!]
		str		[red-string!]
		style	[red-block!]
		cf		[tagCHOOSEFONT]
		logfont [tagLOGFONT]
		size	[integer!]
		hfont	[handle!]
		name	[c-string!]
		bold?	[logic!]
][
	size: size? tagCHOOSEFONT
	cf: as tagCHOOSEFONT allocate size
	logfont: as tagLOGFONT allocate 92
	zero-memory as byte-ptr! cf size
	zero-memory as byte-ptr! logfont 92

	name: as c-string! (as byte-ptr! logfont) + 28

	hfont: get-hfont null selected
	either null? hfont [
		copy-memory as byte-ptr! name as byte-ptr! #u16 "Courier New" 22
		logfont/lfHeight: -11 * log-pixels-y / 72
		logfont/lfCharSet: #"^(01)"						;-- default
	][
		GetObject hfont 92 as byte-ptr! logfont
	]

	cf/lStructSize: size
	cf/hwndOwner: GetForegroundWindow
	cf/lpLogFont: logfont
	cf/Flags: 01000043h									;-- CF_INITTOLOGFONTSTRUCT or CF_BOTH or CF_NOVERTFONTS
	if mono? [cf/Flags: 4000h or cf/Flags]				;-- CF_FIXEDPITCHONLY

	either ChooseFont cf [
		size: lstrlen as byte-ptr! name
		values: object/get-values font
		str: as red-string! values + FONT_OBJ_NAME
		str/header:	TYPE_STRING							;-- implicit reset of all header flags
		str/head:	0
		str/cache:	null
		str/node:	unicode/load-utf16 name size null no
		integer/make-at values + FONT_OBJ_SIZE cf/iPointSize / 10

		style: as red-block! values + FONT_OBJ_STYLE
		bold?: no
		if logfont/lfWeight = 700 [
			word/make-at _bold as red-value! style
			bold?: yes
		]
		if logfont/lfItalic <> #"^@" [
			either bold? [
				block/make-at style 4
				word/push-in _bold style
				word/push-in _italic style
			][
				word/make-at _italic as red-value! style
			]
		]
	][
		font/header: TYPE_NONE
	]

	free as byte-ptr! cf
	free as byte-ptr! logfont
	font
]