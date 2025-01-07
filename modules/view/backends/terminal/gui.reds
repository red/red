Red/System [
	Title:	"CLI backend"
	Author: "Xie Qingtian"
	File: 	%gui.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %definitions.reds
#include %utils.reds
#include %timer.reds
#include %events.reds
#include %ansi-parser.reds
#include %tty.reds
#include %para.reds
#include %font.reds
#include %text-box.reds
#include %draw.reds
#include %widget.reds
#include %screen.reds

#include %widgets/base.reds
#include %widgets/field.reds
#include %widgets/button.reds
#include %widgets/progress.reds
#include %widgets/text-list.reds
#include %widgets/rich-text.reds
#include %widgets/group-box.reds
#include %widgets/checkbox.reds
#include %widgets/radio.reds

color-profile: 0

get-face-obj: func [
	g		[widget!]
	return: [red-object!]
][
	as red-object! :g/face
]

get-face-values: func [
	g		 [widget!]
	return:  [red-value!]
	/local
		ctx	 [red-context!]
		node [node!]
		s	 [series!]
][
	node: g/obj-ctx
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset
]

get-face-handle: func [
	face		[red-object!]
	return:		[handle!]
	/local
		state	[red-block!]
		int		[red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	assert TYPE_OF(state) = TYPE_BLOCK
	int: as red-integer! block/rs-head state
	assert TYPE_OF(int) = TYPE_HANDLE
	as handle! int/value
]

has-focus?: func [
	h		[int-ptr!]
	return: [logic!]
	/local
		w	[widget!]
][
	w: as widget! h
	WIDGET_FOCUSED?(w)
]

widget-data: func [
	h		[int-ptr!]
	return: [int-ptr!]
	/local
		w	[widget!]
][
	w: as widget! h
	either null? w [null][w/data]
]

set-widget-ui: func [
	h		[int-ptr!]
	ui		[node!]
	/local
		w	[widget!]
][
	w: as widget! h
	if w <> null [w/ui: ui]
]

support-dark-mode?: func [
	return: [logic!]
][
	false
]

set-dark-mode: func [
	hWnd		[handle!]
	dark?		[logic!]
	top-level?	[logic!]
][
]

on-gc-mark: does [
	collector/keep :flags-blk/node
	ansi-parser/on-gc-mark
	screen/on-gc-mark
	timer/on-gc-mark
]

check-color-support: func [/local int [red-integer!]][
	#call [TUI-helpers/check-color-support]
	int: as red-integer! stack/arguments
	color-profile: int/value
]

init: func [
	/local
		ver   [red-tuple!]
		int   [red-integer!]
][
	ver: as red-tuple! #get system/view/platform/version
	ver/header: TYPE_TUPLE or (3 << 19)
	ver/array1: 10 << 16 or (10 << 8) or 10

	int: as red-integer! #get system/view/platform/build
	int/header: TYPE_INTEGER
	int/value:  1000 and FFFFh

	int: as red-integer! #get system/view/platform/product
	int/header: TYPE_INTEGER
	int/value:  0

	check-color-support
	screen/init
	timer/init
	ansi-parser/init
	collector/register as int-ptr! :on-gc-mark
]

clean-up: does [
	tty/restore
]

get-screen-size: func [
	id		[integer!]
	return: [red-pair!]
][
	tty/OS-window-size
	pair/push tty/columns tty/rows
]

size-text: func [
	str		[red-string!]
	box-w	[integer!]
	box-h	[integer!]
	w		[int-ptr!]
	h		[int-ptr!]
	/local
		series	[series!]
		unit	[integer!]
		offset	[byte-ptr!]
		tail	[byte-ptr!]
		cp idx	[integer!]
		len n	[integer!]
		max-len [integer!]
		cnt		[integer!]
][
	if zero? box-w [box-w: 7FFFFFFFh]
	cnt: 	 1
	len:	 0
	max-len: 0
	series: GET_BUFFER(str)
	unit: 	GET_UNIT(series)
	offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
	tail:   as byte-ptr! series/tail

	while [offset < tail][
		cp: string/get-char offset unit
		either cp = as-integer lf [
			cnt: cnt + 1
			if len > max-len [max-len: len]
			len: 0
		][
			n: char-width? cp
			len: len + n
		]
		either len > box-w [	;-- wrap text
			cnt: cnt + 1
			len: len - n
			if len > max-len [max-len: len]
			if len <= 0 [break]	;-- width is too small that cannot even contain 1 char
			len: 0
		][
			offset: offset + unit
		]
	]
	if len > max-len [max-len: len]
	w/value: max-len
	h/value: cnt
]

get-text-size: func [
	face 	[red-object!]
	text	[red-string!]
	pt		[red-point2D!]
	/local
		n	[integer!]
][
	n: 1
	pt/x: as float32! string-width? text 7FFFFFFFh null :n
	pt/y: as float32! n
]

get-node-facet: func [
	node	[node!]
	facet	[integer!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		s	 [series!]
][
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset + facet
]

face-handle?: func [
	face	[red-object!]
	return: [handle!]							;-- returns NULL if no handle
	/local
		state [red-block!]
		int	  [red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		if TYPE_OF(int) = TYPE_HANDLE [return as handle! int/value]
	]
	null
]

make-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [handle!]
	/local
		blk	[red-block!]
][
	blk: as red-block! (object/get-values font) + FONT_OBJ_PARENT
	if face <> null [
		if TYPE_OF(blk) <> TYPE_BLOCK [blk: block/make-at blk 4]
		block/rs-append blk as red-value! face
	]
	OS-make-font font
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

OS-request-file: func [
	title	[red-string!]
	name	[red-file!]
	filter	[red-block!]
	save?	[logic!]
	multi?	[logic!]
	return: [red-value!]
][
	#call [TUI-helpers/request-file title name filter save? multi?]
]

OS-request-dir: func [
	title	[red-string!]
	dir		[red-file!]
	filter	[red-block!]
	keep?	[logic!]
	multi?	[logic!]
	return: [red-value!]
][
	#call [TUI-helpers/request-dir title dir filter keep? multi?]
]

update-scroller: func [
	scroller [red-object!]
	flags [integer!]
][

]

OS-redraw: func [hWnd [integer!]][
	screen/redraw as widget! hWnd
]

OS-refresh-window: func [hWnd [integer!]][
	screen/redraw as widget! hWnd
]

OS-show-window: func [
	hWnd	[integer!]
	/local
		g	[widget!]
][
	g: as widget! hWnd
	screen/init-window as window-manager! g/data
	screen/redraw g
]

OS-make-view: func [
	face	[red-object!]
	parent	[integer!]
	return: [integer!]
	/local
		widget	[widget!]
		values	[red-value!]
		type	[red-word!]
		offset	[red-point2D!]
		size	[red-pair!]
		show?	[red-logic!]
		enable?	[red-logic!]
		rate	[red-value!]
		image	[red-image!]
		flags	[integer!]
		bits	[integer!]
		sym		[integer!]
		pt		[red-point2D!]
		sx sy	[float32!]
][
	stack/mark-native words/_body

	values: object/get-values face

	type:	  as red-word!		values + FACE_OBJ_TYPE
	offset:   as red-point2D!	values + FACE_OBJ_OFFSET
	size:	  as red-pair!		values + FACE_OBJ_SIZE
	show?:	  as red-logic!		values + FACE_OBJ_VISIBLE?
	enable?:  as red-logic!		values + FACE_OBJ_ENABLED?
	image:	  as red-image!		values + FACE_OBJ_IMAGE
	rate:						values + FACE_OBJ_RATE

	flags: 0
	bits:  get-flags as red-block! values + FACE_OBJ_FLAGS
	if bits and FACET_FLAGS_ALL_OVER <> 0 [flags: flags or WIDGET_FLAG_ALL_OVER]
	if bits and FACET_FLAGS_PASSWORD <> 0 [flags: flags or WIDGET_FLAG_PASSWORD]
	if bits and FACET_FLAGS_FOCUSABLE <> 0 [flags: flags or WIDGET_FLAG_FOCUSABLE]
	if bits and FACET_FLAGS_FULLSCREEN <> 0 [flags: flags or WIDGET_FLAG_FULLSCREEN]

	if TYPE_OF(offset) = TYPE_PAIR [as-point2D as red-pair! offset]
	either TYPE_OF(size) = TYPE_PAIR [
		flags: flags or WIDGET_FLAG_PAIR_SIZE
		sx: as float32! size/x
		sy: as float32! size/y
	][
		pt: as red-point2D! size
		sx: pt/x
		sy: pt/y
	]

	unless show?/value [flags: flags or WIDGET_FLAG_HIDDEN]
	unless enable?/value [flags: flags or WIDGET_FLAG_DISABLE]

	sym: symbol/resolve type/symbol
	if sym = window [
		offset/x: as float32! 0.0
		offset/y: as float32! 0.0
	]

	widget: _widget/make as widget! parent
	widget/flags: flags
	widget/box/left: offset/x
	widget/box/top: offset/y
	widget/box/right: offset/x + sx
	widget/box/bottom: offset/y + sy

	copy-cell as cell! face as cell! :widget/face

	widget/type: sym

	case [
		sym = window 	[screen/add-window widget]
		sym = field  	[init-field widget]
		sym = button 	[init-button widget]
		sym = base		[init-base widget]
		sym = progress	[init-progress widget]
		sym = group-box [init-group-box widget]
		sym = check		[init-checkbox widget]
		sym = radio		[init-radio widget]
		sym = text-list [init-text-list widget]
		sym = rich-text [init-rich-text widget]
		true			[0]
	]

	if parent <> 0 [
		screen/update-bounding-box widget
		screen/update-editable-widget widget
		screen/update-focus-widget widget
		if TYPE_OF(image) = TYPE_IMAGE [change-image widget image]
	]
	if TYPE_OF(rate) <> TYPE_NONE [change-rate widget rate]

	stack/unwind
	as-integer widget
]

unlink-sub-obj: func [
	face  [red-object!]
	obj   [red-object!]
	field [integer!]
	/local
		values [red-value!]
		parent [red-block!]
		res	   [red-value!]
][
	values: object/get-values obj
	parent: as red-block! values + field

	if TYPE_OF(parent) = TYPE_BLOCK [
		res: block/find parent as red-value! face null no no yes no null null no no no no
		if TYPE_OF(res) <> TYPE_NONE [_series/remove as red-series! res null null]
		if all [
			field = FONT_OBJ_PARENT
			block/rs-tail? parent
		][
			free-font obj
		]
	]
]

free-faces: func [
	face	[red-object!]
	/local
		values	[red-value!]
		type	[red-word!]
		obj		[red-object!]
		tail	[red-object!]
		pane	[red-block!]
		state	[red-value!]
		rate	[red-value!]
		sym		[integer!]
		dc		[integer!]
		flags	[integer!]
		widget	[widget!]
][
	widget: as widget! face-handle? face
	if null? widget [exit]

	values: object/get-values face
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	rate: values + FACE_OBJ_RATE
	if TYPE_OF(rate) <> TYPE_NONE [change-rate widget none-value]

	obj: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj FONT_OBJ_PARENT]
	
	obj: as red-object! values + FACE_OBJ_PARA
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj PARA_OBJ_PARENT]

	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		obj: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [obj < tail][
			free-faces obj
			obj: obj + 1
		]
	]

	_widget/delete widget
	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

change-image: func [
	widget		[widget!]
	img			[red-image!]
	/local
		w h	hh	[integer!]
		new-img	[red-image!]
		bmp		[integer!]
		stride	[integer!]
		data	[int-ptr!]
		i ii sz	[integer!]
		x y b	[integer!]
		fg bg	[integer!]
		pixel	[pixel!]
][
	if widget/image <> null [
		free as byte-ptr! widget/image
		widget/image: null
	]

	w: 0 h: 0
	_widget/get-size widget :w :h
	sz: w * h
	if any [null? img/node sz <= 0][exit]

	data: as int-ptr! allocate sz + 1 * size? pixel!
	data/value: sz
	pixel: as pixel! data
	widget/image: pixel
	new-img: image/resize img w h * 2
	stride: 0
	bmp: OS-image/lock-bitmap new-img no
	data: OS-image/get-data bmp :stride
	y: 0
	hh: h * 2
	while [y < hh][
		x: 1
		i: w * y + x
		ii: w * (y + 1) + x
		while [x <= w][
			bg: data/i
			fg: data/ii
			pixel: pixel + 1
			either bg >>> 24 <> 0 [
				pixel/code-point: 2584h	;-- Unicode Character 'LOWER HALF BLOCK'
				either color-profile = true-color [
					pixel/bg-color: true-color << 24 or (bg and 00FFFFFFh)
					pixel/fg-color: true-color << 24 or (fg and 00FFFFFFh)
				][
					b: bg and FFh << 16
					bg: b or (bg and FF00h) or (bg and 00FF0000h >> 16)
					pixel/bg-color: make-color-256 bg
					b: fg and FFh << 16
					fg: b or (fg and FF00h) or (fg and 00FF0000h >> 16)
					pixel/fg-color: make-color-256 fg
				]
			][							;-- transparent
				pixel/code-point: 20h	;-- space char
				pixel/bg-color: 0
				pixel/fg-color: 0
			]
			pixel/flags: 0
			x: x + 1
			i: i + 1
			ii: ii + 1
		]
		y: y + 2
	]
	OS-image/unlock-bitmap new-img bmp
	image/delete new-img
]

change-rate: func [
	widget		[widget!]
	rate		[red-value!]
	/local
		int [red-integer!]
		tm  [red-time!]
][
	switch TYPE_OF(rate) [
		TYPE_INTEGER [
			int: as red-integer! rate
			if int/value <= 0 [fire [TO_ERROR(script invalid-facet-type) rate]]
			timer/add widget 1000 / int/value
		]
		TYPE_TIME [
			tm: as red-time! rate
			if tm/time <= 0.0 [fire [TO_ERROR(script invalid-facet-type) rate]]
			timer/add widget as-integer tm/time * 1000.0
		]
		TYPE_NONE [timer/kill widget]
		default	  [fire [TO_ERROR(script invalid-facet-type) rate]]
	]
]

change-offset: func [
	widget		[widget!]
	offset		[red-pair!]
	/local
		box		[RECT_F!]
		pt		[red-point2D!]
		sx sy	[float32!]
		x y		[float32!]
][
	box: as RECT_F! :widget/box
	sx: box/right - box/left
	sy: box/bottom - box/top
	GET_PAIR_XY(offset x y)
	box/left: x
	box/top: y
	box/right: x + sx
	box/bottom: y + sy
]

change-size: func [
	widget		[widget!]
	size		[red-pair!]
	/local
		box		[RECT_F!]
		sx sy	[float32!]
		pt		[red-point2D!]
][
	box: as RECT_F! :widget/box
	GET_PAIR_XY(size sx sy)
	box/right: box/left + sx
	box/bottom: box/top + sy
	if widget/type = window [screen/set-buffer-size widget]
]

change-enabled: func [
	w		[widget!]
	values	[red-value!]
	/local
		bool [red-logic!]
][
	bool: as red-logic! values + FACE_OBJ_ENABLED?
	either bool/value [WIDGET_UNSET_FLAG(w WIDGET_FLAG_DISABLE)][
		WIDGET_SET_FLAG(w WIDGET_FLAG_DISABLE)
	]
]

change-visible: func [
	w		[widget!]
	values	[red-value!]
	/local
		bool [red-logic!]
][
	bool: as red-logic! values + FACE_OBJ_VISIBLE?
	either bool/value [WIDGET_UNSET_FLAG(w WIDGET_FLAG_HIDDEN)][
		WIDGET_SET_FLAG(w WIDGET_FLAG_HIDDEN)
	]
]

change-data: func [
	w		[widget!]
	values	[red-value!]
][
	0
]

select-text: func [
	w		[widget!]
	values	[red-value!]
][
	0
]

change-selection: func [
	w		[widget!]
	values	[red-value!]
	/local
		face [red-object!]
		type [red-word!]
		sym	 [integer!]
][
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol
	case [
		any [sym = field sym = area][
			select-text w values
		]
		sym = window [
			face: as red-object! values + FACE_OBJ_SELECTED
			switch TYPE_OF(face) [
				TYPE_OBJECT [
					w: as widget! face-handle? face
					screen/set-focus-widget w null
				]
				TYPE_NONE	[screen/set-focus-widget w null]
				default [0]
			]
		]
		true [0]										;-- default, do nothing
	]
]

get-text-alt: func [
	face [red-object!]
	idx	 [integer!]
][
	exit
]

OS-update-view: func [
	face [red-object!]
	/local
		ctx		[red-context!]
		values	[red-value!]
		state	[red-block!]
		int		[red-integer!]
		val		[red-value!]
		s		[series!]
		w		[widget!]
		b		[red-logic!]
		sync?	[logic!]
		flags	[integer!]
		bits	[integer!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	values: s/offset

	state: as red-block! values + FACE_OBJ_STATE
	if TYPE_OF(state) <> TYPE_BLOCK [exit]

	s: GET_BUFFER(state)
	int: as red-integer! s/offset
	w: as widget! int/value
	int: int + 1
	flags: int/value
	
	if flags and FACET_FLAG_RATE <> 0 [
		timer/kill w
		val: values + FACE_OBJ_RATE
		if TYPE_OF(val) <> TYPE_NONE [change-rate w val]
	]
	if flags and FACET_FLAG_OFFSET <> 0 [
		change-offset w as red-pair! values + FACE_OBJ_OFFSET
	]
	if flags and FACET_FLAG_SIZE <> 0 [
		change-size w as red-pair! values + FACE_OBJ_SIZE
	]
	if flags and FACET_FLAG_SELECTED <> 0 [
		change-selection w values
	]
	if flags and FACET_FLAG_ENABLED? <> 0 [
		change-enabled w values
	]
	if flags and FACET_FLAG_VISIBLE? <> 0 [
		change-visible w values
	]
	if flags and FACET_FLAG_FLAGS <> 0 [
		bits:  get-flags as red-block! values + FACE_OBJ_FLAGS
		either bits and FACET_FLAGS_ALL_OVER <> 0 [
			WIDGET_SET_FLAG(w WIDGET_FLAG_ALL_OVER)
		][
			WIDGET_UNSET_FLAG(w WIDGET_FLAG_ALL_OVER)
		]
		either bits and FACET_FLAGS_PASSWORD <> 0 [
			WIDGET_SET_FLAG(w WIDGET_FLAG_PASSWORD)
		][
			WIDGET_UNSET_FLAG(w WIDGET_FLAG_PASSWORD)
		]
	]
	if flags and FACET_FLAG_IMAGE <> 0 [
		change-image w as red-image! values + FACE_OBJ_IMAGE
	]
	if flags and FACET_FLAG_DATA <> 0 [
		change-data w values
	]
	b: as red-logic! #get system/view/auto-sync?
	sync?: b/value
	b/value: no
	w/update w
	screen/redraw w
	b/value: sync?

	int/value: 0										;-- reset flags
]

OS-destroy-view: func [
	face   [red-object!]
	empty? [logic!]
][
	free-faces face
	post-quit-msg
	if 0 < screen/windows-cnt [
		screen/redraw null
	]
]

OS-update-facet: func [
	face   [red-object!]
	facet  [red-word!]
	value  [red-value!]
	action [red-word!]
	new	   [red-value!]
	index  [integer!]
	part   [integer!]
	/local
		sym		[integer!]
		widget	[widget!]
		type	[integer!]
		len		[integer!]
		blk		[red-block!]
		sel		[red-integer!]
][
	sym: symbol/resolve facet/symbol
	
	case [
		sym = facets/pane [
			sym: action/symbol
		]
		sym = facets/data [
			widget: as widget! face-handle? face
			if null? widget [exit]

			type: WIDGET_TYPE(widget)
			sym: action/symbol
			case [
				type = text-list [
					blk: as red-block! value
					sel: as red-integer! (object/get-values face) + FACE_OBJ_SELECTED
					if TYPE_OF(blk) <> TYPE_BLOCK [exit]
					if any [
						sym = words/_remove/symbol
						sym = words/_take/symbol
						sym = words/_clear/symbol
						sym = words/_move/symbol
					][
						len: block/rs-length? blk
						if (as-integer widget/data) > index [widget/data: as int-ptr! index]
						if all [			;-- cleared
							zero? index
							part >= len
						][
							widget/data: null
						]
						if TYPE_OF(sel) = TYPE_INTEGER [
							part: len - part
							if part < 0 [part: 0]
							if sel/value > part [sel/value: part]
						]
					]
				]
				any [
					type = drop-list
					type = drop-down
				][
					if zero? part [exit]
				]
				type = tab-panel [0]
				true [0]
			]
		]
		true [0]
	]
	OS-update-view face
]

OS-to-image: func [
	face	[red-object!]
	return: [red-image!]
][
	null
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
][
	do-draw null img cmds no no no no
]

OS-draw-face: func [
	hWnd	[handle!]
	cmds	[red-block!]
	flags	[integer!]
][
]