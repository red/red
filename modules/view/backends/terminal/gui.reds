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

#include %widgets/field.reds
#include %widgets/button.reds
#include %widgets/progress.reds
#include %widgets/text-list.reds

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
	collector/keep flags-blk/node
	ansi-parser/on-gc-mark
	screen/on-gc-mark
	timer/on-gc-mark
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

get-flags: func [
	field	[red-block!]
	return: [integer!]									;-- return a bit-array of all flags
	/local
		word  [red-word!]
		len	  [integer!]
		sym	  [integer!]
		flags [integer!]
][
	switch TYPE_OF(field) [
		TYPE_BLOCK [
			word: as red-word! block/rs-head field
			len: block/rs-length? field
			if zero? len [return 0]
		]
		TYPE_WORD [
			word: as red-word! field
			len: 1
		]
		default [return 0]
	]
	flags: 0
	
	loop len [
		sym: symbol/resolve word/symbol
		case [
			sym = all-over	 [flags: flags or FACET_FLAGS_ALL_OVER]
			sym = resize	 [flags: flags or FACET_FLAGS_RESIZE]
			sym = no-title	 [flags: flags or FACET_FLAGS_NO_TITLE]
			sym = no-border  [flags: flags or FACET_FLAGS_NO_BORDER]
			sym = no-min	 [flags: flags or FACET_FLAGS_NO_MIN]
			sym = no-max	 [flags: flags or FACET_FLAGS_NO_MAX]
			sym = no-buttons [flags: flags or FACET_FLAGS_NO_BTNS]
			sym = modal		 [flags: flags or FACET_FLAGS_MODAL]
			sym = popup		 [flags: flags or FACET_FLAGS_POPUP]
			sym = scrollable [flags: flags or FACET_FLAGS_SCROLLABLE]
			sym = password	 [flags: flags or FACET_FLAGS_PASSWORD]
			true			 [fire [TO_ERROR(script invalid-arg) word]]
		]
		word: word + 1
	]
	flags
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
	as red-value! none-value
]

OS-request-dir: func [
	title	[red-string!]
	dir		[red-file!]
	filter	[red-block!]
	keep?	[logic!]
	multi?	[logic!]
	return: [red-value!]
][
	as red-value! none-value
]

update-scroller: func [
	scroller [red-object!]
	flags [integer!]
][

]

OS-redraw: func [hWnd [integer!]][
	screen/redraw
]

OS-refresh-window: func [hWnd [integer!]][
	screen/redraw
]

OS-show-window: func [
	hWnd	[integer!]
	/local
		g	[widget!]
][
	g: as widget! hWnd
	screen/init-window as window-manager! g/data
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
	rate:						values + FACE_OBJ_RATE

	flags: 0
	bits:  get-flags as red-block! values + FACE_OBJ_FLAGS
	if bits and FACET_FLAGS_ALL_OVER <> 0 [flags: flags or WIDGET_FLAG_ALL_OVER]

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

	widget: _widget/make as widget! parent
	widget/flags: flags
	widget/box/left: offset/x
	widget/box/top: offset/y
	widget/box/right: offset/x + sx
	widget/box/bottom: offset/y + sy

	copy-cell as cell! face as cell! :widget/face

	sym: symbol/resolve type/symbol
	widget/type: sym

	case [
		sym = window 	[screen/add-window widget]
		sym = field  	[init-field widget]
		sym = button 	[init-button widget]
		sym = progress	[init-progress widget]
		sym = text-list [init-text-list widget]
		true			[0]
	]

	screen/update-bounding-box widget
	screen/update-editable-widget widget

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

	if sym = window [screen/remove-window widget]

	_widget/delete widget
	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
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
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	values: s/offset

	state: as red-block! values + FACE_OBJ_STATE
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

	b: as red-logic! #get system/view/auto-sync?
	sync?: b/value
	b/value: no
	w/update w
	screen/redraw
	b/value: sync?

	int/value: 0										;-- reset flags
]

OS-destroy-view: func [
	face   [red-object!]
	empty? [logic!]
][
	free-faces face
	if zero? screen/windows-cnt [
		post-quit-msg
		tty/show-cursor
		screen/set-cursor-bottom
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
][
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
	ctx		[draw-ctx!]
	cmds	[red-block!]
][
	if TYPE_OF(cmds) = TYPE_BLOCK [
		catch RED_THROWN_ERROR [parse-draw ctx cmds yes]
	]
	if system/thrown = RED_THROWN_ERROR [system/thrown: 0]
]