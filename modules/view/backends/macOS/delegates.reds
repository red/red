Red/System [
	Title:	"Delegates are used in controls"
	Author: "Qingtian Xie"
	File: 	%delegates.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
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

reset-cursor-rects: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	/local
		cur [integer!]
		sz	[CGPoint! value]
		rc	[NSRect! value]
][
	cur: objc_getAssociatedObject self RedCursorKey
	if cur <> 0 [
		either zero? objc_msgSend [
			self sel_getUid "respondsToSelector:" sel_getUid "contentSize"
		][
			rc: objc_msgSend_rect [self sel_getUid "bounds"]
			sz/x: rc/w
			sz/y: rc/h
		][
			sz: objc_msgSend_pt [self sel_getUid "contentSize"]
		]
		objc_msgSend [
			self sel_getUid "addCursorRect:cursor:" 0 0 sz/x sz/y cur
		]
	]
]

mouse-entered: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
][
	if zero? objc_getAssociatedObject self RedEnableKey [
		objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
		make-event self 0 EVT_OVER
	]
]

mouse-exited: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
][
	if zero? objc_getAssociatedObject self RedEnableKey [
		objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
		make-event self EVT_FLAG_AWAY EVT_OVER
	]
]

mouse-moved: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		flags [integer!]
][
	if zero? objc_getAssociatedObject self RedEnableKey [
		objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
		flags: get-flags (as red-block! get-face-values self) + FACE_OBJ_FLAGS
		if flags and FACET_FLAGS_ALL_OVER <> 0 [
			make-event self 0 EVT_OVER
		]
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
	if 0 <> objc_getAssociatedObject self RedEnableKey [exit]	;-- button is disabled

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
					button-click self
				]
			]
			default [0]
		]
		objc_msgSend [self sel_getUid "highlight:" inside?]
		type = NSLeftMouseUp
	]
]

mouse-events-base: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		p		[int-ptr!]
		flags	[integer!]
		super	[objc_super! value]
		cls		[integer!]
][
	p: as int-ptr! event
	flags: check-extra-keys event
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	switch p/2 [
		NSRightMouseDown [make-event self flags EVT_RIGHT_DOWN]
		NSRightMouseUp	 [make-event self flags EVT_RIGHT_UP]
		default			 [0]
	]
	cls: objc_msgSend [self sel_getUid "superclass"]
	super/receiver: self
	super/superclass: cls
	objc_msgSendSuper [super cmd event]
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
		drag?	[logic!]
][
	p: as int-ptr! event
	flags: check-extra-keys event
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	drag?: no
	switch p/2 [
		NSLeftMouseDown		[
			evt: objc_msgSend [event sel_getUid "clickCount"]
			evt: switch evt [
				1 [EVT_LEFT_DOWN]
				2 [EVT_DBL_CLICK]
				default [-1]
			]
			state: either evt = -1 [EVT_DISPATCH][make-event self flags evt]
		]
		NSLeftMouseUp		[
			state: either 2 > objc_msgSend [event sel_getUid "clickCount"][
				make-event self flags EVT_LEFT_UP
			][
				EVT_DISPATCH
			]
		]
		NSRightMouseDown	[state: make-event self flags EVT_RIGHT_DOWN]
		NSRightMouseUp		[state: make-event self flags EVT_RIGHT_UP]
		NSOtherMouseDown	[
			evt: either 2 < objc_msgSend [event sel_getUid "buttonNumber"][EVT_AUX_DOWN][EVT_MIDDLE_DOWN]
			state: make-event self flags evt
		]
		NSOtherMouseUp		[
			evt: either 2 < objc_msgSend [event sel_getUid "buttonNumber"][EVT_AUX_UP][EVT_MIDDLE_UP]
			state: make-event self flags evt
		]
		NSLeftMouseDragged	[drag?: yes flags: flags or EVT_FLAG_DOWN]
		NSRightMouseDragged [drag?: yes flags: flags or EVT_FLAG_ALT_DOWN]
		NSOtherMouseDragged	[drag?: yes flags: flags or EVT_FLAG_MID_DOWN]
		default [state: EVT_DISPATCH]
	]
	if drag? [
		opt: (get-face-values self) + FACE_OBJ_OPTIONS
		state: either all [
			zero? objc_getAssociatedObject self RedEnableKey
			any [
				TYPE_OF(opt) = TYPE_BLOCK
				0 <> objc_getAssociatedObject self RedAllOverFlagKey
			]
		][
			make-event self flags EVT_OVER
		][
			EVT_DISPATCH
		]
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

popup-button-action: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
	/local
		idx [integer!]
		res [integer!]
		str [integer!]
][
	idx: objc_msgSend [self sel_getUid "indexOfSelectedItem"]		;-- 1-based index
	str: objc_msgSend [self sel_getUid "titleOfSelectedItem"]
	if idx > 0 [
		res: make-event self idx EVT_SELECT
		set-selected self idx
		set-text self str
		if res = EVT_DISPATCH [
			make-event self idx EVT_CHANGE
		]
	]
	objc_msgSend [self sel_getUid "setTitle:" str]
]

handle-speical-key: func [
	self	[integer!]
	event	[integer!]
	return: [logic!]
	/local
		key		[integer!]
		flags	[integer!]
][
	key: objc_msgSend [event sel_getUid "keyCode"]
	either key = 72h [		;-- insert key
		flags: check-extra-keys event
		key: translate-key key
		special-key: -1
		make-event self key or flags EVT_KEY
		no
	][yes]
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
	special-key: either char-key? as-byte key [0][-1]	;-- special key or not
	flags: check-extra-keys event

	res: make-event self key or flags EVT_KEY_DOWN
	if res <> EVT_NO_DISPATCH [
		either special-key = -1 [						;-- special key
			make-event self key or flags EVT_KEY
		][
			if any [
				key = 8 key = 9							;-- backspace
				key = 13								;-- number enter
			][
				make-event self key or flags EVT_KEY
				exit
			]
			key: objc_msgSend [event sel_getUid "characters"]
			if all [
				key <> 0
				0 < objc_msgSend [key sel_length]
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
][
	either zero? objc_getAssociatedObject self RedRichTextKey [
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
	special-key: either char-key? as-byte key [0][-1]	;-- special key or not
	flags: check-extra-keys event
	if all [
		EVT_DISPATCH = make-event self key or flags EVT_KEY_UP
		cmd <> 0
	][
		msg-send-super self cmd event
	]
]

on-flags-changed: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	event	[integer!]
	/local
		key		[integer!]
		flags	[integer!]
		evt		[integer!]
][
	special-key: -1
	key: translate-key objc_msgSend [event sel_getUid "keyCode"]
	flags: check-extra-keys event
	evt: either zero? flags [EVT_KEY_UP][EVT_KEY_DOWN]
	if EVT_DISPATCH = make-event self key or flags evt [
		msg-send-super self cmd event
	]
]

button-click: func [
	[cdecl]
	self [integer!]
	/local
		w		[red-word!]
		values	[red-value!]
		type 	[integer!]
		event	[integer!]
][	
	values: get-face-values self
	w: as red-word! values + FACE_OBJ_TYPE
	type: symbol/resolve w/symbol
	
	if type <> radio [objc_msgSend [self sel_getUid "setNextState"]]
	
	event: case [
		type = button [EVT_CLICK]
		any [
			type = toggle
			type = check
		][
			get-logic-state self EVT_CHANGE
		]
		all [
			type = radio
			NSOffState = objc_msgSend [self sel_getUid "state"] ;-- ignore double-click (fixes #4246)
		][
			objc_msgSend [self sel_getUid "setNextState"]		;-- gets converted to CHANGE by high-level event handler
			get-logic-state self
			EVT_CLICK
		]
		true [0]
	]
	
	unless zero? event [make-event self 0 event]
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
		min			[red-integer!]
		max			[red-integer!]
		page		[red-integer!]
		range		[integer!]
		n			[integer!]
		frac		[float!]
		values		[red-value!]
][
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
][
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	make-event self event EVT_WHEEL
]

slider-change: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
	/local
		values	[red-value!]
		pos		[red-float!]
		opt		[red-value!]
		val		[float!]
		divisor [float!]
][
	values: get-face-values self
	pos: (as red-float! values) + FACE_OBJ_DATA

	if all [
		TYPE_OF(pos) <> TYPE_FLOAT
		TYPE_OF(pos) <> TYPE_PERCENT
	][
		percent/rs-make-at as red-value! pos 0.0
	]
	val: objc_msgSend_fpret [self sel_getUid "floatValue"]
	divisor: objc_msgSend_fpret [self sel_getUid "maxValue"]
	pos/value: val / divisor

	opt: values + FACE_OBJ_OPTIONS
	if all [
		zero? objc_getAssociatedObject self RedEnableKey
		any [
			TYPE_OF(opt) = TYPE_BLOCK
			0 <> objc_getAssociatedObject self RedAllOverFlagKey
		]
	][make-event self EVT_FLAG_DOWN EVT_OVER]
	make-event self 0 EVT_CHANGE
]

calendar-change: func [
	[cdecl]
	self   [integer!]
][	
	sync-calendar self
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
	size: objc_msgSend [text sel_length]
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
	if loop-started? [make-event self 0 EVT_CHANGE]
	msg-send-super self cmd notif
]

;text-change-selection: func [
;	[cdecl]
;	self	[integer!]
;	cmd		[integer!]
;	notif	[integer!]
;	/local
;		win		[integer!]
;		text	[integer!]
;		range	[NSRange! value]
;		sel		[red-pair!]
;][
	;win: objc_msgSend [NSApp sel_getUid "mainWindow"]
	;text: objc_msgSend [win sel_getUid "fieldEditor:forObject:" yes self]
	;text: objc_msgSend [self sel_getUid "currentEditor"]
;	range: objc_msgSend_range [self sel_getUid "selectedRange"]

;	sel: as red-pair! (get-face-values self) + FACE_OBJ_SELECTED
;	either zero? range/len [sel/header: TYPE_NONE][
;		sel/header: TYPE_PAIR
;		sel/x: range/idx + 1
;		sel/y: range/idx + range/len
;	]

;	make-event self 0 EVT_SELECT
;]

text-will-selection: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	view	[integer!]
	idx1	[integer!]
	len1	[integer!]
	idx2	[integer!]
	len2	[integer!]
	/local
		sel [red-pair!]
][
	sel: as red-pair! (get-face-values self) + FACE_OBJ_SELECTED
	either zero? len2 [sel/header: TYPE_NONE][
		sel/header: TYPE_PAIR
		sel/x: idx2 + 1
		sel/y: idx2 + len2
	]

	make-event self 0 EVT_SELECT
	system/cpu/edx: len2
	system/cpu/eax: idx2
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
	if loop-started? [make-event self 0 EVT_CHANGE]
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
	if all [loop-started? idx >= 0][
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
		font [red-object!]
		face [red-object!]
		attr [integer!]
		id	 [integer!]
		idx  [integer!]
		type [integer!]
		str  [integer!]
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

	if any [idx = -1 row >= 0][return 0]

	font: (as red-object! get-face-values obj) + FACE_OBJ_FONT
	str: to-NSString as red-string! block/rs-abs-at data idx
	if TYPE_OF(font) = TYPE_OBJECT [
		id: 0
		object_getInstanceVariable self IVAR_RED_FACE :id
		face: as red-object! references/get id
		attr: make-font-attrs font face text-list
		str: objc_msgSend [
			objc_msgSend [objc_getClass "NSAttributedString" sel_getUid "alloc"]
			sel_getUid "initWithString:attributes:" str attr
		]
	]
	str
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

win-send-event: func [
	self	[integer!]
	type	[integer!]
	event	[integer!]
	return: [logic!]
	/local
		responder	[integer!]
		find?		[logic!]
		send?		[logic!]
][
	send?: yes
	case [
		type = NSKeyUp [
			responder: objc_msgSend [self sel_getUid "firstResponder"]
			object_getInstanceVariable responder IVAR_RED_DATA :type
			if type = base [
				on-key-up responder 0 event
				send?: no
			]
		]
		type = NSKeyDown [
			find?: yes
			responder: objc_msgSend [self sel_getUid "firstResponder"]
			object_getInstanceVariable responder IVAR_RED_DATA :type
			either type <> base [
				unless red-face? responder [
					responder: objc_getAssociatedObject self RedFieldEditorKey
					unless red-face? responder [find?: no]
				]
				if find? [on-key-down responder event]
			][
				if find? [	;-- handle some special keys on rich-text base face
					send?: handle-speical-key responder event
				]
			]
		]
		true [0]
	]
	send?
]

app-send-event: func [
	[cdecl]
	self		[integer!]
	cmd			[integer!]
	event		[integer!]
	/local
		p-int p [int-ptr!]
		type	[integer!]
		window	[integer!]
		n-win	[integer!]
		flags	[integer!]
		faces	[red-block!]
		face	[red-object!]
		start	[red-object!]
		check?	[logic!]
		active?	[logic!]
		down?	[logic!]
		y		[integer!]
		x		[integer!]
		point	[CGPoint!]
		view	[integer!]
		state	[integer!]
		modal-win [integer!]
][
	window: objc_msgSend [event sel_getUid "window"]
	p-int: as int-ptr! event

	type: p-int/2
	switch type [
		NSMouseMoved
		NSLeftMouseDragged
		NSRightMouseDragged
		NSOtherMouseDragged [
			check?: yes
			window: process-mouse-tracking window event
		]
		default [0]
	]

	state: EVT_DISPATCH
	if window <> 0 [
		down?: no active?: no check?: no

		if any [
			type = NSLeftMouseDown type = NSRightMouseDown type = NSOtherMouseDown
		][
			active?: yes down?: yes check?: yes
		]
		if any [
			type = NSLeftMouseUp type = NSRightMouseUp type = NSOtherMouseUp
		][
			active?: yes check?: yes
		]
		switch type [
			NSMouseEntered
			NSMouseExited
			NSKeyDown
			NSKeyUp
			NSScrollWheel [check?: yes]
			default [0]
		]

		if all [check? red-face? window 0 < vector/rs-length? active-wins][
			p: as int-ptr! vector/rs-tail active-wins
			p: p - 1
			modal-win: p/value
			if window <> modal-win [
				if down? [NSBeep]
				state: EVT_NO_DISPATCH
			]
		]
	]
	if all [
		state >= EVT_DISPATCH
		any [zero? window win-send-event window type event]
	][
		msg-send-super self cmd event
	]
	if close-window? [
		close-pending-windows
		if zero? win-cnt [
			loop-started?: no
			post-quit-msg
		]
	]
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

should-terminate: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	app		[integer!]
	return: [integer!]
][
	#either sub-system = 'gui [1][0]	;-- 0: NSTerminateCancel, so we don't exit the console
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
	/local
		i	[integer!]
		n	[integer!]
		p	[int-ptr!]
		pp	[int-ptr!]
][
	p: as int-ptr! vector/rs-head active-wins
	n: vector/rs-length? active-wins
	i: 0
	while [i < n][
		pp: p + 1
		if pp/value = self [		;-- active its parent window
			objc_msgSend [p/value sel_getUid "makeKeyAndOrderFront:" p/value]
			string/remove-part as red-string! active-wins i 2
			break
		]
		p: p + 2
		i: i + 2
	]
	0
]

;win-will-resize: func [								;-- use it to block resizing window
;	[cdecl]
;	self	[integer!]
;	cmd		[integer!]
;	sender	[integer!]
;	w		[integer!]
;	h		[integer!]
;	return: [NSSize! value]
;	/local
;		sz	[NSSize! value]
;][
	
;]

win-did-resize: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	notif	[integer!]
	/local
		sz	[red-pair!]
		pt	[red-point2D!]
		v	[integer!]
		rc	[NSRect! value]
][
	make-event self 0 EVT_SIZING
	v: objc_msgSend [self sel_getUid "contentView"]
	rc: objc_msgSend_rect [v sel_getUid "frame"]
	sz: (as red-pair! get-face-values self) + FACE_OBJ_SIZE		;-- update face/size
	either zero? objc_getAssociatedObject self RedPairSizeKey [
		pt: as red-point2D! sz
		pt/header: TYPE_POINT2D
		pt/x: rc/w
		pt/y: rc/h
	][
		sz/header: TYPE_PAIR
		sz/x: as-integer rc/w
		sz/y: as-integer rc/h
	]
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
		2 or 4										;-- center
	]

	m: make-CGMatrix 1 0 0 -1 0 0
	case [
		flags and 1 <> 0 [m/tx: sz/w - rc/x]
		flags and 2 <> 0 [temp: sz/w - rc/x m/tx: temp / as float32! 2.0]
		true [0]
	]

	case [
		flags and 4 <> 0 [temp: sz/h - rc/y m/ty: temp / as float32! 2.0]
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

	attr: objc_msgSend [attrs sel_getUid "objectForKey:" NSStrikethroughStyleAttributeName]
	if as logic! objc_msgSend [attr sel_getUid "boolValue"][
		m/ty: m/ty - temp + (rc/y / as float32! 2.0)
		CGContextTranslateCTM ctx m/tx m/ty
		CGContextMoveToPoint ctx as float32! 0.0 as float32! 0.0
		CGContextAddLineToPoint ctx rc/x as float32! 0.0
		CGContextStrokePath ctx
	]
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
	_marked-range-len: objc_msgSend [text sel_length]
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
	special-key: 0
	objc_msgSend [self sel_getUid "unmarkText"]
	attr-str?: as logic! objc_msgSend [
		str sel_getUid "isKindOfClass:" objc_getClass "NSAttributedString"
	]
	text: either attr-str? [objc_msgSend [str sel_getUid "string"]][str]
	len: objc_msgSend [text sel_length]
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

hit-test: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	x		[integer!]
	y		[integer!]
	return: [integer!]
	/local
		img		[red-image!]
		sz		[red-pair!]
		pt		[CGPoint! value]
		super	[objc_super! value]
		v		[integer!]
		pixel	[integer!]
		w		[integer!]
		h		[integer!]
		ratio	[float32!]
		vals	[red-value!]
		clr		[red-tuple!]
		rc		[NSRect! value]
		rep		[integer!]
		alpha	[float!]
][
	super/receiver: self
	super/superclass: objc_msgSend [self sel_getUid "superclass"]
	v: objc_msgSendSuper [super cmd x y]
	if v = self [
		vals: get-face-values self
		img: (as red-image! vals) + FACE_OBJ_IMAGE
		sz: (as red-pair! vals) + FACE_OBJ_SIZE
		if TYPE_OF(img) = TYPE_IMAGE [
			pt: objc_msgSend_pt [
				self sel_getUid "convertPoint:fromView:" x y
				objc_msgSend [self sel_getUid "superview"]
			]
			w: IMAGE_WIDTH(img/size)
			h: IMAGE_HEIGHT(img/size)
			ratio: (as float32! w) / (as float32! sz/x)
			x: as-integer pt/x * ratio
			ratio: (as float32! h) / (as float32! sz/y)
			y: as-integer pt/y * ratio
			pixel: OS-image/get-pixel img/node y * w + x
			if pixel >>> 24 = 0 [return 0]
		]

		clr: (as red-tuple! vals) + FACE_OBJ_COLOR
		if any [	;-- full transparent color
			TYPE_OF(clr) = TYPE_NONE
			all [
				TYPE_OF(clr) = TYPE_TUPLE
				TUPLE_SIZE?(clr) > 3
				clr/array1 >>> 24 = 255
			]
		][
			rc: objc_msgSend_rect [self sel_getUid "bounds"]
			rep: objc_msgSend [self sel_getUid "bitmapImageRepForCachingDisplayInRect:" rc/x rc/y rc/w rc/h]
			objc_msgSend [self sel_getUid "cacheDisplayInRect:toBitmapImageRep:" rc/x rc/y rc/w rc/h rep]
			pt: objc_msgSend_pt [
				self sel_getUid "convertPoint:fromView:" x y
				objc_msgSend [self sel_getUid "superview"]
			]
			pixel: objc_msgSend [rep sel_getUid "colorAtX:y:" as-integer pt/x as-integer pt/y]
			alpha: objc_msgSend_fpret [pixel sel_getUid "alphaComponent"]
			if alpha = 0.0 [return 0]
		]
	]
	v
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
		type	[red-word!]
		sym		[integer!]
		pos		[red-point2D! value]
		v1010?	[logic!]
		DC		[draw-ctx!]
		pt		[red-point2D!]
		sx sy	[integer!]
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
	type: as red-word! vals + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	if TYPE_OF(clr) = TYPE_TUPLE [
		paint-background ctx get-tuple-color clr x y width height
	]
	if TYPE_OF(img) = TYPE_IMAGE [
		GET_PAIR_XY_INT(size sx sy)
		CG-draw-image ctx OS-image/to-cgimage img 0 0 sx sy
	]
	case [
		sym = base [render-text ctx vals as NSSize! (as int-ptr! self) + 8]
		sym = rich-text [
			pos/header: TYPE_POINT2D
			pos/x: F32_0 pos/y: F32_0
			draw-text-box null as red-pair! :pos get-face-obj self yes
		]
		true []
	]

	img: as red-image! (as int-ptr! self) + 8				;-- view's size
	either TYPE_OF(draw) = TYPE_BLOCK [
		do-draw ctx img draw no yes no yes
	][
		system/thrown: 0
		DC: declare draw-ctx!								;@@ should declare it on stack
		draw-begin DC ctx img no no
		object_setInstanceVariable self IVAR_RED_DRAW_CTX as-integer DC
		make-event self 0 EVT_DRAWING
		draw-end DC ctx no no no
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