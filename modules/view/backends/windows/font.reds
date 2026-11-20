Red/System [
	Title:	"Windows fonts management"
	Author: "Nenad Rakocevic"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

font-ext-type: -1

make-font: func [
	face		[red-object!]
	font		[red-object!]
	return:		[handle!]
][
	OS-make-font face font yes
]

get-gdi-face: func [									;-- GDI face of the font DirectWrite matches in a family for a weight
	name	[c-string!]									;-- family name
	weight	[int-ptr!]									;-- weight asked, set to the face's weight
	italic? [logic!]
	lf		[tagLOGFONT]								;-- filled with the face found
	return: [c-string!]									;-- face name, `name` if DirectWrite does not know the family
	/local
		factory [IDWriteFactory]
		coll	[IDWriteFontCollection]
		family	[IDWriteFontFamily]
		interop [IDWriteGdiInterop]
		unk		[IUnknown]
		ptr		[com-ptr! value]
		list	[this!]
		this	[this!]
		dwfont	[this!]
		obj		[this!]
		idx		[integer!]
		found	[integer!]
		style	[integer!]
][
	factory: as IDWriteFactory dwrite-factory/vtbl
	if 0 <> factory/GetSystemFontCollection dwrite-factory :ptr no [return name]
	list: ptr/value
	coll: as IDWriteFontCollection list/vtbl
	idx: 0
	found: 0
	style: either italic? [2][0]						;-- DWRITE_FONT_STYLE_ITALIC: 2
	if all [
		zero? coll/FindFamilyName list name :idx :found
		found <> 0
		zero? coll/GetFontFamily list idx :ptr
	][
		this: ptr/value
		family: as IDWriteFontFamily this/vtbl
		if zero? family/GetFirstMatchingFont this weight/value 5 style :ptr [	;-- DWRITE_FONT_STRETCH_NORMAL: 5
			dwfont: ptr/value
			if zero? factory/GetGdiInterop dwrite-factory :ptr [
				obj: ptr/value
				interop: as IDWriteGdiInterop obj/vtbl
				if zero? interop/ConvertFontToLOGFONT obj dwfont lf :found [
					name: as c-string! :lf/lfFaceName
					weight/value: lf/lfWeight
				]
				COM_SAFE_RELEASE(unk obj)
			]
			COM_SAFE_RELEASE(unk dwfont)
		]
		COM_SAFE_RELEASE(unk this)
	]
	COM_SAFE_RELEASE(unk list)
	name
]

OS-make-font: func [
	face		[red-object!]
	font		[red-object!]
	scaling?	[logic!]
	return:		[handle!]
	/local
		values	[red-value!]
		int		[red-integer!]
		value	[red-value!]
		bool	[red-logic!]
		style	[red-word!]
		str		[red-string!]
		blk		[red-block!]
		h		[red-handle!]
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
		lf		[tagLOGFONT value]
][
	values: object/get-values font
	
	int: as red-integer! values + FONT_OBJ_SIZE
	if any [TYPE_OF(int) <> TYPE_INTEGER  int/value <= 0][
		int: as red-integer! #get system/view/fonts/size
	]
	len: either scaling? [log-pixels-y][96]
	height: 0 - (int/value * len / 72)

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
	len: get-font-weight font 0
	if len > 0 [
		weight: len
		unless winxp? [name: get-gdi-face name :weight italic? lf]
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

	blk: get-font-state font
	either null? blk [
		blk: make-font-state font 3
		either scaling? [
			h: handle/make-in blk as-integer hFont handle/CLASS_FONT
			if hFont <> null [h/extID: externals/store hFont font-ext-type]
		][
			none/make-in blk
		]
		none/make-in blk								;-- DWrite font
		either scaling? [
			none/make-in blk
		][
			h: handle/make-in blk as-integer hFont handle/CLASS_FONT
			if hFont <> null [h/extID: externals/store hFont font-ext-type]
		]
	][
		h: as red-handle! block/rs-head blk
		value: as red-value! h + 2						;-- the unscaled font
		either scaling? [
			if TYPE_OF(value) <> TYPE_HANDLE [OS-make-font face font no]	;-- kept when already made (GDI+ Draw)
		][h: h + 2]
		h: handle/make-at as red-value! h as-integer hFont handle/CLASS_FONT
		if hFont <> null [h/extID: externals/store hFont font-ext-type]
	]

	link-font-to-face face font
	hFont
]

set-font: func [
	hWnd   [handle!]
	face   [red-object!]
	values [red-value!]
	/local
		font   [red-object!]
		hFont  [handle!]
][
	font: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(font) <> TYPE_OBJECT [
		SendMessage hWnd WM_SETFONT as-integer default-font 0
		exit
	]
	
	hFont: get-font-handle font 0
	if null? hFont [hFont: make-font face font]		;-- none yet, or only the unscaled one (GDI+ Draw's)
	link-font-to-face face font
	SendMessage hWnd WM_SETFONT as-integer hFont 0
]

get-font-handle-slot: func [
	font	[red-object!]
	idx		[integer!]							;-- 0-based index
	return: [red-handle!]
	/local
		state [red-block!]
		h	  [red-handle!]
][
	state: get-font-state font
	if state <> null [
		h: (as red-handle! block/rs-head state) + idx
		if TYPE_OF(h) = TYPE_HANDLE [return h]
	]
	null
]

get-font-handle: func [
	font	[red-object!]
	idx		[integer!]							;-- 0-based index
	return: [handle!]
	/local
		h [red-handle!]
][
	h: get-font-handle-slot font idx
	either null? h [null][as handle! h/value]
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
	link-font-to-face face font
	hFont
]

mark-font: func [hFont [handle!]][]

delete-font: func [h [handle!]][DeleteObject h]

free-font: func [
	font [red-object!]
	/local
		h	  [red-handle!]
		hFont [handle!]
		h2	  [handle!]
		this  [this!]
		obj   [IUnknown]
		n	  [integer!]
		free? [logic!]
][
	free?: no
	unless winxp? [
		h: get-font-handle-slot font 1
		if h <> null [
			this: as this! h/value
			either h/extID >= 0 [
				externals/replace h/extID null			;-- released; the GC frees the record (a copied font may hold its ID)
			][
				COM_SAFE_RELEASE(obj this)
			]
			free?: yes
		]
	]
	n: 0
	h2: null
	loop 2 [
		hFont: get-font-handle font n
		if hFont <> null [
			assert hFont <> h2
			h: get-font-handle-slot font n
			externals/replace h/extID null				;-- DeleteObject (delete-font); the GC frees the record
			h2: hFont
			free?: yes
		]
		n: 2
	]
	if free? [drop-font-state font]
]

update-font: func [
	font [red-object!]
	flag [integer!]
][
	switch flag [
		FONT_OBJ_NAME
		FONT_OBJ_SIZE
		FONT_OBJ_STYLE
		FONT_OBJ_WEIGHT
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
		str/header: TYPE_UNSET
		str/head:	0
		str/cache:	null
		str/node:	unicode/load-utf16 name size null no
		str/header:	TYPE_STRING							;-- implicit reset of all header flags
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
		set-font-weight font logfont/lfWeight
	][
		font/header: TYPE_NONE
	]

	free as byte-ptr! cf
	free as byte-ptr! logfont
	font
]
