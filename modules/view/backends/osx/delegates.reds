Red/System [
	Title:	"Delegates are used in controls"
	Author: "Qingtian Xie"
	File: 	%delegates.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

is-flipped: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	return: [logic!]
][
	true
]

accepts-first-responder: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	return: [logic!]
	/local
		type [integer!]
][
	type: 0
	object_getInstanceVariable self IVAR_RED_DATA :type
	type = base
]

become-first-responder: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	return: [logic!]
][
	make-event self 0 EVT_FOCUS
	msg-send-super-logic self cmd
]

mouse-entered: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
][
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	make-event self 0 EVT_OVER
]

mouse-exited: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
][
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	make-event self EVT_FLAG_AWAY EVT_OVER
]

mouse-moved: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		flags [integer!]
][
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	flags: get-flags (as red-block! get-face-values self) + FACE_OBJ_FLAGS
	if flags and FACET_FLAGS_ALL_OVER <> 0 [
		make-event self 0 EVT_OVER
	]
]

button-mouse-down: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		inside?	[logic!]
		p-int	[int-ptr!]
		window	[integer!]
		type	[integer!]
		y		[integer!]
		x		[integer!]
		bound	[NSRect!]
		rc		[NSRect!]
][
	inside?: yes
	objc_msgSend [self sel_getUid "highlight:" inside?]
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	make-event self 0 EVT_LEFT_DOWN
	until [
		window: objc_msgSend [self sel_getUid "window"]
		assert window <> 0
		event: objc_msgSend [
			window sel_getUid "nextEventMatchingMask:"
			NSLeftMouseDownMask or NSLeftMouseUpMask or NSLeftMouseDraggedMask
		]
		bound: as NSRect! (as int-ptr! self) + 6
		p-int: (as int-ptr! event) + 1
		type: p-int/value
		rc: as NSRect! (p-int + 1)
		x: objc_msgSend [self sel_getUid "convertPoint:fromView:" rc/x rc/y 0]
		y: system/cpu/edx
		rc: as NSRect! :x

		inside?: CGRectContainsPoint bound/x bound/y bound/w bound/h rc/x rc/y
		objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
		switch type [
			NSLeftMouseDragged [
				make-event self 0 EVT_OVER
			]
			NSLeftMouseUp [
				make-event self 0 EVT_LEFT_UP
				if inside? [
					inside?: false
					objc_msgSend [self sel_getUid "setNextState"]
					button-click self
				]
			]
			default [0]
		]
		objc_msgSend [self sel_getUid "highlight:" inside?]
		type = NSLeftMouseUp
	]
]

mouse-events: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		p		[int-ptr!]
		opt		[red-value!]
		evt		[integer!]
		flags	[integer!]
		state	[integer!]
][
	p: as int-ptr! event
	flags: check-extra-keys event
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	state: switch p/2 [
		NSLeftMouseDown		[
			evt: objc_msgSend [event sel_getUid "clickCount"]
			evt: switch evt [
				1 [EVT_LEFT_DOWN]
				2 [EVT_DBL_CLICK]
				default [-1]
			]
			either evt = -1 [EVT_DISPATCH][make-event self flags evt]
		]
		NSLeftMouseUp		[
			either 2 > objc_msgSend [event sel_getUid "clickCount"][
				make-event self flags EVT_LEFT_UP
			][
				EVT_DISPATCH
			]
		]
		NSRightMouseDown	[make-event self flags EVT_RIGHT_DOWN]
		NSRightMouseUp		[make-event self flags EVT_RIGHT_UP]
		NSOtherMouseDown	[
			evt: either 2 < objc_msgSend [event sel_getUid "buttonNumber"][EVT_AUX_DOWN][EVT_MIDDLE_DOWN]
			make-event self flags evt
		]
		NSOtherMouseUp		[
			evt: either 2 < objc_msgSend [event sel_getUid "buttonNumber"][EVT_AUX_UP][EVT_MIDDLE_UP]
			make-event self flags evt
		]
		NSLeftMouseDragged	
		NSRightMouseDragged	
		NSOtherMouseDragged	[
			opt: (get-face-values self) + FACE_OBJ_OPTIONS
			either any [
				TYPE_OF(opt) = TYPE_BLOCK
				0 <> objc_getAssociatedObject self RedAllOverFlagKey
			][
				make-event self flags EVT_OVER
			][
				EVT_DISPATCH
			]
		]
		default [EVT_DISPATCH]
	]
	if state = EVT_DISPATCH [msg-send-super self cmd event]
]

print-classname: func [
	obj		[integer!]
	/local
		cls		 [integer!]
		name	 [integer!]
		cls-name [c-string!]
][
	cls: objc_msgSend [obj sel_getUid "class"]
	name: NSStringFromClass cls
	cls-name: as c-string! objc_msgSend [name sel_getUid "UTF8String"]
	?? cls-name
]

red-timer-action: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	timer	[integer!]
][
	make-event self 0 EVT_TIME
]

on-key-down: func [
	[cdecl]
	self	[integer!]
	event	[integer!]
	/local
		res		[integer!]
		key		[integer!]
		flags	[integer!]
][
	key: objc_msgSend [event sel_getUid "keyCode"]
	key: either key >= 80h [0][translate-key key]
	flags: either char-key? as-byte key [0][80000000h]	;-- special key or not
	flags: flags or check-extra-keys event

	res: make-event self key or flags EVT_KEY_DOWN
	if res <> EVT_NO_DISPATCH [
		either flags and 80000000h <> 0 [				;-- special key
			make-event self key or flags EVT_KEY
		][
			if key = 8 [								;-- backspace
				make-event self key or flags EVT_KEY
				exit
			]
			key: objc_msgSend [event sel_getUid "characters"]
			if all [
				key <> 0
				0 < objc_msgSend [key sel_getUid "length"]
			][
				key: objc_msgSend [key sel_getUid "characterAtIndex:" 0]
				make-event self key or flags EVT_KEY
			]
		]
	]
]

key-down-base: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		flags		[integer!]
][
	flags: get-flags (as red-block! get-face-values self) + FACE_OBJ_FLAGS
	either flags and FACET_FLAGS_EDITABLE = 0 [
		on-key-down self event
	][
		objc_msgSend [
			objc_msgSend [self sel_getUid "inputContext"] sel_getUid "handleEvent:" event
		]
	]
]

win-level: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	return: [integer!]
][
	objc_msgSend [
		objc_msgSend [self sel_getUid "window"]
		sel_getUid "level"
	]
]

insert-text: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	str		[integer!]
][
]

on-key-up: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		key		[integer!]
		flags	[integer!]
][
	key: objc_msgSend [event sel_getUid "keyCode"]
	key: either key >= 80h [0][translate-key key]
	flags: either char-key? as-byte key [0][80000000h]	;-- special key or not
	flags: flags or check-extra-keys event
	make-event self key or flags EVT_KEY_UP
	;msg-send-super self cmd event
]

button-click: func [
	self	[integer!]
	/local
		w		[red-word!]
		values	[red-value!]
		bool	[red-logic!]
		type 	[integer!]
		state	[integer!]
		change? [logic!]
][
	make-event self 0 EVT_CLICK
	values: get-face-values self
	w: as red-word! values + FACE_OBJ_TYPE
	type: symbol/resolve w/symbol
	if any [
		type = check
		type = radio
	][
		bool: as red-logic! values + FACE_OBJ_DATA
		state: objc_msgSend [self sel_getUid "state"]
		change?: either state = -1 [
			type: TYPE_OF(bool)
			bool/header: TYPE_NONE							;-- NONE indicates undeterminate
			bool/header <> type
		][
			change?: bool/value								;-- save the old value
			bool/value: as logic! state
			bool/value <> change?
		]
		if change? [make-event self 0 EVT_CHANGE]
	]
]

empty-func: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
][0]

scroller-change: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
	/local
		code		[integer!]
		bar			[integer!]
		direction	[integer!]
		pos			[integer!]
		view		[integer!]
		min			[red-integer!]
		max			[red-integer!]
		page		[red-integer!]
		range		[integer!]
		n			[integer!]
		frac		[float!]
		values		[red-value!]
][
	view: objc_msgSend [self sel_getUid "documentView"]
	bar: objc_msgSend [self sel_getUid "verticalScroller"]
	direction: either bar = sender [0][1]
	code: objc_msgSend [sender sel_getUid "hitPart"]
	pos: 0
	if code = 2 [			;-- track
		frac: objc_msgSend_fpret [sender sel_getUid "doubleValue"]
		n: objc_getAssociatedObject sender RedAttachedWidgetKey
		if n <> 0 [
			values: as red-value! objc_msgSend [n sel_getUid "unsignedIntValue"]
			min:	as red-integer! values + SCROLLER_OBJ_MIN
			max:	as red-integer! values + SCROLLER_OBJ_MAX
			page:	as red-integer! values + SCROLLER_OBJ_PAGE
			range:	max/value - page/value - min/value + 2
			frac: frac * as float! range
			frac: 0.5 + frac + as float! min/value
			pos: as-integer frac
			pos: pos << 4
		]
	]
	make-event self direction << 3 or code or pos EVT_SCROLL
]

refresh-scrollview: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	draw?	[integer!]
	/local
		view [integer!]
][
	if draw? <> 0 [
		view: objc_msgSend [self sel_getUid "documentView"]
		objc_msgSend [view sel_getUid "setNeedsDisplay:" yes]
	]
	msg-send-super self cmd draw?
]

scroll-wheel: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		d	  [float32!]
		flags [integer!]
		delta [integer!]
][
	d: objc_msgSend_f32 [event sel_getUid "scrollingDeltaY"]
	case [
		all [d > as float32! -1.0 d < as float32! 0.0][delta: -1]
		all [d > as float32! 0.0 d < as float32! 1.0][delta: 1]
		true [delta: as-integer d]
	]
	flags: check-extra-keys event
	make-event self delta or flags EVT_WHEEL
]

slider-change: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
	/local
		pos		[red-float!]
		val		[float!]
		divisor [float!]
][
	pos: (as red-float! get-face-values self) + FACE_OBJ_DATA

	if all [
		TYPE_OF(pos) <> TYPE_FLOAT
		TYPE_OF(pos) <> TYPE_PERCENT
	][
		percent/rs-make-at as red-value! pos 0.0
	]
	val: objc_msgSend_fpret [self sel_getUid "floatValue"]
	divisor: objc_msgSend_fpret [self sel_getUid "maxValue"]
	pos/value: val / divisor
	make-event self 0 EVT_CHANGE
]

set-selected: func [
	obj [integer!]
	idx [integer!]
	/local
		int [red-integer!]
][
	int: as red-integer! (get-face-values obj) + FACE_OBJ_SELECTED
	int/header: TYPE_INTEGER
	int/value: idx
]

set-text: func [
	obj  [integer!]
	text [integer!]
	/local
		size [integer!]
		str	 [red-string!]
		face [red-object!]
		out	 [c-string!]
][
	size: objc_msgSend [text sel_getUid "length"]
	if size >= 0 [
		str: as red-string! (get-face-values obj) + FACE_OBJ_TEXT
		if TYPE_OF(str) <> TYPE_STRING [
			string/make-at as red-value! str size UCS-2
		]
		if size = 0 [
			string/rs-reset str
			exit
		]
		out: unicode/get-cache str size + 1 * 4			;-- account for surrogate pairs and terminal NUL
		objc_msgSend [text sel_getUid "getCString:maxLength:encoding:" out size + 1 * 2 NSUTF16LittleEndianStringEncoding]
		unicode/load-utf16 null size str no

		face: push-face obj
		if TYPE_OF(face) = TYPE_OBJECT [
			ownership/bind as red-value! str face _text
		]
		stack/pop 1
	]
]

text-did-end-editing: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
][
	make-event self 0 EVT_UNFOCUS
	msg-send-super self cmd notif
]

text-did-change: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
][
	set-text self objc_msgSend [self sel_getUid "stringValue"]
	make-event self 0 EVT_CHANGE
	msg-send-super self cmd notif
]

area-did-end-editing: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
][
	make-event self 0 EVT_UNFOCUS
]

area-text-change: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
][
	set-text self objc_msgSend [self sel_getUid "string"]
	make-event self 0 EVT_CHANGE
]

selection-change: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
	/local
		idx [integer!]
		res [integer!]
][
	idx: objc_msgSend [self sel_getUid "indexOfSelectedItem"]
	if idx >= 0 [
		res: make-event self idx + 1 EVT_SELECT
		set-selected self idx + 1
		set-text self objc_msgSend [self sel_getUid "itemObjectValueAtIndex:" idx]
		if res = EVT_DISPATCH [
			make-event self idx + 1 EVT_CHANGE
		]
	]
]

number-of-rows: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	obj		[integer!]
	return: [integer!]
	/local
		blk [red-block!]
		head [red-value!]
		tail [red-value!]
		cnt  [integer!]
		type [integer!]
][
	blk: as red-block! (get-face-values obj) + FACE_OBJ_DATA
	type: TYPE_OF(blk)
	either any [
		type = TYPE_BLOCK
		type = TYPE_HASH
		type = TYPE_MAP
	][
		head: block/rs-head blk
		tail: block/rs-tail blk
		cnt: 0
		while [head < tail][
			type: TYPE_OF(head)
			if ANY_STRING?(type) [cnt: cnt + 1]
			head: head + 1
		]
		cnt
	][0]
]

object-for-table: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	obj		[integer!]
	column	[integer!]
	row		[integer!]
	return: [integer!]
	/local
		data [red-block!]
		head [red-value!]
		tail [red-value!]
		idx  [integer!]
		type [integer!]
][
	data: (as red-block! get-face-values obj) + FACE_OBJ_DATA
	head: block/rs-head data
	tail: block/rs-tail data
	idx: -1
	while [all [row >= 0 head < tail]][
		type: TYPE_OF(head)
		if ANY_STRING?(type) [row: row - 1]
		head: head + 1
		idx: idx + 1
	]
	to-NSString as red-string! block/rs-abs-at data idx
]

table-cell-edit: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	obj		[integer!]
	column	[integer!]
	row		[integer!]
	return: [logic!]
][
	no
]

table-select-did-change: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
	/local
		res [integer!]
][
	res: make-event self 0 EVT_SELECT
	set-selected self 1 + objc_msgSend [self sel_getUid "selectedRow"]
	if res = EVT_DISPATCH [
		make-event self 0 EVT_CHANGE
	]
]

will-finish: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
][
	0
]

destroy-app: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	app		[integer!]
	return: [logic!]
][
	no
]

win-should-close: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
	return: [logic!]
][
	make-event sender 0 EVT_CLOSE
	no
]

win-will-close: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
][
	0
]

;win-will-resize: func [								;-- use it to block resizing window
;	[cdecl]
;	self	[integer!]
;	cmd		[integer!]
;	sender	[integer!]
;	w		[integer!]
;	h		[integer!]
;	/local
;		sz	[NSSize!]
;][
;	sz: as NSSize! :w
;	system/cpu/edx: h									;-- return NSSize!
;	system/cpu/eax: w
;]

win-did-resize: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
	/local
		ws		[NSRect!]
		sz		[red-pair!]
		h		[integer!]
		w		[integer!]
		y		[integer!]
		x		[integer!]
		rc		[NSRect!]
		saved	[int-ptr!]
		method	[integer!]
][
	x: 0
	rc: as NSRect! :x
	make-event self 0 EVT_SIZING

	ws: as NSRect! (as int-ptr! self) + 2
	method: sel_getUid "contentRectForFrameRect:"
	saved: system/stack/align
	push 0
	push ws/h push ws/w push ws/y push ws/x
	push method push self push rc
	objc_msgSend_stret 7
	system/stack/top: saved
	sz: (as red-pair! get-face-values self) + FACE_OBJ_SIZE		;-- update face/size
	sz/x: as-integer rc/w
	sz/y: as-integer rc/h
]

win-live-resize: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
][
	make-event self 0 EVT_SIZE
]

win-did-move: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
	/local
		rc	[NSRect!]
		sz	[red-pair!]
][
	rc: as NSRect! (as int-ptr! self) + 2
	sz: (as red-pair! get-face-values self) + FACE_OBJ_OFFSET	;-- update face/offset
	sz/x: as-integer rc/x
	sz/y: screen-size-y - as-integer (rc/y + rc/h)
	make-event self 0 EVT_MOVE
]

tabview-should-select: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	tabview	[integer!]
	item	[integer!]
	return: [logic!]
	/local
		idx		[integer!]
][
	idx: objc_msgSend [tabview sel_getUid "indexOfTabViewItem:" item]
	either EVT_DISPATCH = make-event self idx + 1 EVT_CHANGE [
		set-selected self idx + 1
		yes
	][
		no
	]
]

set-line-spacing: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	layout	[integer!]
	idx		[integer!]
	x		[float32!]
	y		[float32!]
	width	[float32!]
	height	[float32!]
	return: [float32!]
	/local
		d	[float32!]
][
	d: objc_msgSend_f32 [
		objc_getAssociatedObject layout RedAttachedWidgetKey
		sel_getUid "descender"
	]
	(as float32! 1.5) - d
]

render-text: func [
	ctx		[handle!]
	values	[red-value!]
	sz		[NSSize!]
	/local
		text	[red-string!]
		font	[red-object!]
		para	[red-object!]
		flags	[integer!]
		str		[integer!]
		attr	[integer!]
		nscolor [integer!]
		attrs	[integer!]
		line	[integer!]
		sy		[integer!]
		sx		[integer!]
		temp	[float32!]
		rc		[NSRect!]
		m		[CGAffineTransform!]
][
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [exit]

	CGContextSaveGState ctx
	font: as red-object! values + FACE_OBJ_FONT
	either TYPE_OF(font) = TYPE_OBJECT [
		attrs: make-font-attrs font as red-object! none-value -1
	][
		attrs: objc_msgSend [
			objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
			sel_getUid "initWithObjectsAndKeys:"
			default-font NSFontAttributeName
			0
		]
	]

	str: to-CFString text
	attr: CFAttributedStringCreate 0 str attrs
	sx: objc_msgSend [attr sel_getUid "size"]		;-- string width on screen
	sy: system/cpu/edx								;-- string height on screen
	rc: as NSRect! :sx

	para: as red-object! values + FACE_OBJ_PARA
	flags: either TYPE_OF(para) = TYPE_OBJECT [		;@@ TBD set alignment attribute
		get-para-flags base para
	][
		1 or 4										;-- center
	]

	m: make-CGMatrix 1 0 0 -1 0 0
	case [
		flags and 1 <> 0 [temp: sz/w - rc/x m/tx: temp / 2]
		flags and 2 <> 0 [m/tx: sz/w - rc/x]
		true [0]
	]

	case [
		flags and 4 <> 0 [temp: sz/h - rc/y m/ty: temp / 2]
		flags and 8 <> 0 [m/ty: sz/h - rc/y]
		true [0]
	]
	temp: objc_msgSend_f32 [
		objc_msgSend [attrs sel_getUid "objectForKey:" NSFontAttributeName]
		sel_getUid "ascender"
	]
	m/ty: m/ty + temp
	line: CTLineCreateWithAttributedString attr
	CGContextSetTextMatrix ctx m/a m/b m/c m/d m/tx m/ty
	CTLineDraw line ctx

	CFRelease str
	CFRelease attr
	CFRelease line
	objc_msgSend [attrs sel_getUid "release"]
	CGContextRestoreGState ctx
]

paint-background: func [
	ctx		[handle!]
	color	[integer!]
	x		[float32!]
	y		[float32!]
	width	[float32!]
	height	[float32!]
	/local
		r	[float32!]
		g	[float32!]
		b	[float32!]
		a	[float32!]
][
	r: (as float32! color and FFh) / 255.0
	g: (as float32! color >> 8 and FFh) / 255.0
	b: (as float32! color >> 16 and FFh) / 255.0
	a: (as float32! 255 - (color >>> 24)) / 255.0
	CGContextSetRGBFillColor ctx r g b a
	CGContextFillRect ctx x y width height
]

has-marked-text: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	return: [logic!]
][
	in-composition?
]

_marked-range-idx: 0
_marked-range-len: 0

marked-range: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
][
	system/cpu/edx: _marked-range-len
	system/cpu/eax: _marked-range-idx
]

selected-range: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
][
	system/cpu/edx: 0
	system/cpu/eax: 0
]

get-text-styles: func [
	str		[integer!]
	styles	[red-block!]
][
	
]

set-marked-text: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	str		[integer!]
	idx1	[integer!]
	len1	[integer!]
	idx2	[integer!]
	len2	[integer!]
	/local
		attr-str?	[logic!]
		text		[integer!]
		cstr		[c-string!]
		key			[integer!]
][
	in-composition?: yes
	attr-str?: as logic! objc_msgSend [
		str sel_getUid "isKindOfClass:" objc_getClass "NSAttributedString"
	]
	text: either attr-str? [objc_msgSend [str sel_getUid "string"]][str]
	make-event self text EVT_IME
	_marked-range-idx: idx1
	_marked-range-len: objc_msgSend [text sel_getUid "length"]
	if zero? _marked-range-len [
		objc_msgSend [self sel_getUid "unmarkText"]
	]
]

unmark-text: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
][
	in-composition?: no
	objc_msgSend [
		objc_msgSend [self sel_getUid "inputContext"]
		sel_getUid "discardMarkedText"
	]
]

valid-attrs-marked-text: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	return: [integer!]
][
	objc_msgSend [
		objc_getClass "NSArray" sel_getUid "arrayWithObjects:"
		NSMarkedClauseSegmentAttributeName
		NSGlyphInfoAttributeName
		0
	]
]

attr-str-range: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	idx		[integer!]
	len		[integer!]
	p-range	[int-ptr!]
	return: [integer!]
][
	;probe "attr-str-range"
	0
]

insert-text-range: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	str		[integer!]
	idx		[integer!]
	len		[integer!]
	/local
		attr-str?	[logic!]
		text		[integer!]
		cstr		[c-string!]
		key			[integer!]
][
	objc_msgSend [self sel_getUid "unmarkText"]
	attr-str?: as logic! objc_msgSend [
		str sel_getUid "isKindOfClass:" objc_getClass "NSAttributedString"
	]
	text: either attr-str? [objc_msgSend [str sel_getUid "string"]][str]
	len: objc_msgSend [text sel_getUid "length"]
	idx: 0
	while [idx < len][
		key: objc_msgSend [text sel_getUid "characterAtIndex:" idx]
		make-event self key EVT_KEY
		idx: idx + 1
	]
]

char-idx-point: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	x		[float32!]
	y		[float32!]
	return: [integer!]
][
	;probe "char-idx-point"
	0
]

first-rect-range: func [
	[stdcall]
	base		[integer!]
	/local
		pc		[int-ptr!]
		rc		[NSRect!]
		self	[integer!]
		cmd		[integer!]
		idx		[integer!]
		len		[integer!]
		p-range [int-ptr!]
		y		[integer!]
		x		[integer!]
		pt		[CGPoint!]
		sy		[float32!]
][
	pc: :base
	rc: as NSRect! base
	pc: pc + 1
	self: pc/value

	rc/x: caret-x
	rc/y: caret-y + caret-h
	rc/w: caret-w
	rc/h: caret-h

	x: objc_msgSend [self sel_getUid "convertPoint:toView:" rc/x rc/y 0]
	y: system/cpu/edx
	pt: as CGPoint! :x

	x: objc_msgSend [
		objc_msgSend [self sel_getUid "window"]
		sel_getUid "convertBaseToScreen:" pt/x pt/y
	]
	y: system/cpu/edx
	pt: as CGPoint! :x
	rc/x: pt/x
	rc/y: pt/y
]

do-cmd-selector: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sel		[integer!]
	/local
		event [integer!]
][
	event: objc_msgSend [NSApp sel_getUid "currentEvent"]
	if all [
		event <> 0
		NSKeyDown = objc_msgSend [event sel_getUid "type"]
	][
		on-key-down self event
	]
]

draw-rect: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	x		[float32!]
	y		[float32!]
	width	[float32!]
	height	[float32!]
	/local
		nsctx	[integer!]
		ctx		[handle!]
		vals	[red-value!]
		img		[red-image!]
		draw	[red-block!]
		clr		[red-tuple!]
		size	[red-pair!]
		bmp		[integer!]
		v1010?	[logic!]
		DC		[draw-ctx!]
][
	nsctx: objc_msgSend [objc_getClass "NSGraphicsContext" sel_getUid "currentContext"]
	v1010?: as logic! objc_msgSend [nsctx sel_getUid "respondsToSelector:" sel_getUid "CGContext"]
	ctx: as handle! either v1010? [
		objc_msgSend [nsctx sel_getUid "CGContext"]
	][
		objc_msgSend [nsctx sel_getUid "graphicsPort"]		;-- deprecated in 10.10
	]

	vals: get-face-values self
	img: as red-image! vals + FACE_OBJ_IMAGE
	draw: as red-block! vals + FACE_OBJ_DRAW
	clr:  as red-tuple! vals + FACE_OBJ_COLOR
	size: as red-pair! vals + FACE_OBJ_SIZE
	if TYPE_OF(clr) = TYPE_TUPLE [
		paint-background ctx clr/array1 x y width height
	]
	if TYPE_OF(img) = TYPE_IMAGE [
		bmp: CGBitmapContextCreateImage as-integer img/node 
		CG-draw-image ctx bmp 0 0 size/x size/y
		CGImageRelease bmp
	]
	render-text ctx vals as NSSize! (as int-ptr! self) + 8

	img: as red-image! (as int-ptr! self) + 8				;-- view's size
	either TYPE_OF(draw) = TYPE_BLOCK [
		do-draw ctx img draw no yes yes yes
	][
		system/thrown: 0
		DC: declare draw-ctx!								;@@ should declare it on stack
		draw-begin DC ctx img no yes
		integer/make-at as red-value! draw as-integer DC
		make-event self 0 EVT_DRAWING
		draw/header: TYPE_NONE
		draw-end DC ctx no no yes
	]
]

return-field-editor: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
	obj		[integer!]
	return: [integer!]
][
	objc_setAssociatedObject sender RedFieldEditorKey obj OBJC_ASSOCIATION_ASSIGN
	0
]

perform-key-equivalent: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	return: [logic!]
	/local
		type  [integer!]
		flags [integer!]
		mask  [integer!]
		obj   [integer!]
		sel   [integer!]
][
	type: objc_msgSend [event sel_getUid "type"]
	if type = NSKeyDown [
		flags: objc_msgSend [event sel_getUid "modifierFlags"]
		mask: 0
		if flags and NSAlternateKeyMask <> 0 [mask: mask or NSAlternateKeyMask]
		if flags and NSShiftKeyMask <> 0 [mask: mask or NSShiftKeyMask]
		if flags and NSControlKeyMask <> 0 [mask: mask or NSControlKeyMask]
		if flags and NSCommandKeyMask <> 0 [mask: mask or NSCommandKeyMask]
		sel: 0
		if mask = NSCommandKeyMask [
			flags: objc_msgSend [event sel_getUid "keyCode"]
			sel: switch flags [
				6 [sel_getUid "undo:"]				;-- Z
				7 [sel_getUid "cut:"]				;-- X
				8 [sel_getUid "copy:"]				;-- C
				9 [sel_getUid "paste:"]				;-- V
				0 [sel_getUid "selectAll:"]			;-- A
				default [0]
			]
		]
		if NSCommandKeyMask or NSShiftKeyMask = mask [
			if 6 = objc_msgSend [event sel_getUid "keyCode"][sel: sel_getUid "redo:"]
		]
		if sel <> 0 [
			;obj: objc_msgSend [objc_msgSend [sel sel_getUid "window"] sel_getUid "firstResponder"]
			return as logic! objc_msgSend [NSApp sel_getUid "sendAction:to:from:" sel 0 self]
		]
	]
	as logic! msg-send-super self cmd event
]

win-send-event: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		p-int		[int-ptr!]
		type		[integer!]
		view		[integer!]
		responder	[integer!]
		find?		[logic!]
][
	p-int: as int-ptr! event
	type: p-int/2
	;view: objc_msgSend [self sel_getUid "contentView"]
	;p-int: as int-ptr! self
	;view: p-int/7

	if type = NSKeyDown	[
		find?: yes
		responder: objc_msgSend [self sel_getUid "firstResponder"]
		object_getInstanceVariable responder IVAR_RED_DATA :type
		if type <> base [
			unless red-face? responder [
				responder: objc_getAssociatedObject self RedFieldEditorKey
				unless red-face? responder [find?: no]
			]
			if find? [on-key-down responder event]
		]
	]
	msg-send-super self cmd event
]