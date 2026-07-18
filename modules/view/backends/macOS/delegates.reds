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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	return: [logic!]
][
	true
]

accepts-first-responder: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	return: [logic!]
	/local
		type [Cocoa-handle!]
][
	type: 0
	object_getInstanceVariable self IVAR_RED_DATA :type
	type = base
]

become-first-responder: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	return: [logic!]
][
	make-event self 0 EVT_FOCUS
	msg-send-super-logic self cmd
]

reset-cursor-rects: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	/local
		cur [Cocoa-handle!]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
][
	if zero? objc_getAssociatedObject self RedEnableKey [
		objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
		make-event self 0 EVT_OVER
	]
]

mouse-exited: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
][
	if zero? objc_getAssociatedObject self RedEnableKey [
		objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
		make-event self EVT_FLAG_AWAY EVT_OVER
	]
]

mouse-moved: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
	/local
		inside?	[logic!]
		window	[Cocoa-handle!]
		type	[integer!]
		bound	[NSRect! value]
		pt		[CGPoint! value]
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
		bound: objc_msgSend_rect [self sel_getUid "bounds"]
		type: as integer! objc_msgSend [event sel_getUid "type"]
		pt: objc_msgSend_pt [event sel_getUid "locationInWindow"]
		pt: objc_msgSend_pt [self sel_getUid "convertPoint:fromView:" pt/x pt/y 0]

		inside?: CGRectContainsPoint bound/x bound/y bound/w bound/h pt/x pt/y
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
	/local
		type	[integer!]
		flags	[integer!]
		super	[objc_super! value]
		cls		[Cocoa-handle!]
][
	type: as integer! objc_msgSend [event sel_getUid "type"]
	flags: check-extra-keys event
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	switch type [
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
	/local
		type	[integer!]
		opt		[red-value!]
		evt		[integer!]
		flags	[integer!]
		state	[integer!]
		drag?	[logic!]
][
	type: as integer! objc_msgSend [event sel_getUid "type"]
	flags: check-extra-keys event
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	drag?: no
	switch type [
		NSLeftMouseDown		[
			evt: as integer! objc_msgSend [event sel_getUid "clickCount"]
			evt: switch evt [
				1 [EVT_LEFT_DOWN]
				2 [EVT_DBL_CLICK]
				default [-1]
			]
			state: either evt = -1 [EVT_DISPATCH][make-event self flags evt]
		]
		NSLeftMouseUp		[
			state: either 2 > as integer! objc_msgSend [event sel_getUid "clickCount"][
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
	obj		[Cocoa-handle!]
	/local
		cls		 [Cocoa-handle!]
		name	 [Cocoa-handle!]
		cls-name [c-string!]
][
	cls: objc_msgSend [obj sel_getUid "class"]
	name: NSStringFromClass cls
	cls-name: as c-string! objc_msgSend [name sel_getUid "UTF8String"]
	?? cls-name
]

red-timer-action: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	timer	[Cocoa-handle!]
][
	make-event self 0 EVT_TIME
]

popup-button-action: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	sender	[Cocoa-handle!]
	/local
		idx [integer!]
		res [integer!]
		str [Cocoa-handle!]
][
	idx: as integer! objc_msgSend [self sel_getUid "indexOfSelectedItem"]	;-- 1-based index
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
	self	[Cocoa-handle!]
	event	[Cocoa-handle!]
	return: [logic!]
	/local
		key		[integer!]
		flags	[integer!]
][
	key: as integer! objc_msgSend [event sel_getUid "keyCode"]
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
	self	[Cocoa-handle!]
	event	[Cocoa-handle!]
	/local
		res		[integer!]
		key		[integer!]
		chars	[Cocoa-handle!]
		flags	[integer!]
][
	key: as integer! objc_msgSend [event sel_getUid "keyCode"]
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
			chars: objc_msgSend [event sel_getUid "characters"]
			if all [
				chars <> 0
				0 < as integer! objc_msgSend [chars sel_length]
			][
				key: as integer! objc_msgSend [chars sel_getUid "characterAtIndex:" 0]
				make-event self key or flags EVT_KEY
			]
		]
	]
]

key-down-base: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	return: [NSInteger!]
][
	as NSInteger! objc_msgSend [
		objc_msgSend [self sel_getUid "window"]
		sel_getUid "level"
	]
]

insert-text: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	str		[Cocoa-handle!]
][
]

on-key-up: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
	/local
		key		[integer!]
		flags	[integer!]
][
	key: as integer! objc_msgSend [event sel_getUid "keyCode"]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
	/local
		key		[integer!]
		flags	[integer!]
		evt		[integer!]
][
	special-key: -1
	key: translate-key as integer! objc_msgSend [event sel_getUid "keyCode"]
	flags: check-extra-keys event
	evt: either zero? flags [EVT_KEY_UP][EVT_KEY_DOWN]
	if EVT_DISPATCH = make-event self key or flags evt [
		msg-send-super self cmd event
	]
]

button-click: func [
	[cdecl]
	self [Cocoa-handle!]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	sender	[Cocoa-handle!]
][0]

scroller-change: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	sender	[Cocoa-handle!]
	/local
		code		[integer!]
		bar			[Cocoa-handle!]
		direction	[integer!]
		pos			[integer!]
		min			[red-integer!]
		max			[red-integer!]
		page		[red-integer!]
		range		[integer!]
		n			[Cocoa-handle!]
		frac		[float!]
		values		[red-value!]
][
	bar: objc_msgSend [self sel_getUid "verticalScroller"]
	direction: either bar = sender [0][1]
	code: as integer! objc_msgSend [sender sel_getUid "hitPart"]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	draw?	[integer!]
	/local
		view [Cocoa-handle!]
][
	if draw? <> 0 [
		view: objc_msgSend [self sel_getUid "documentView"]
		objc_msgSend [view sel_getUid "setNeedsDisplay:" yes]
	]
	msg-send-super self cmd as Cocoa-handle! draw?
]

scroll-wheel: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
][
	objc_setAssociatedObject self RedNSEventKey event OBJC_ASSOCIATION_ASSIGN
	make-event self event EVT_WHEEL
]

slider-change: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	sender	[Cocoa-handle!]
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
	self   [Cocoa-handle!]
][	
	sync-calendar self
	make-event self 0 EVT_CHANGE
]

set-selected: func [
	obj [Cocoa-handle!]
	idx [integer!]
	/local
		int [red-integer!]
][
	int: as red-integer! (get-face-values obj) + FACE_OBJ_SELECTED
	int/header: TYPE_INTEGER
	int/value: idx
]

set-text: func [
	obj  [Cocoa-handle!]
	text [Cocoa-handle!]
	/local
		size [integer!]
		str	 [red-string!]
		face [red-object!]
		out	 [c-string!]
][
	size: as integer! objc_msgSend [text sel_length]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
][
	make-event self 0 EVT_UNFOCUS
	msg-send-super self cmd notif
]

text-did-change: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
][
	set-text self objc_msgSend [self sel_getUid "stringValue"]
	if loop-started? [make-event self 0 EVT_CHANGE]
	msg-send-super self cmd notif
]

;text-change-selection: func [
;	[cdecl]
;	self	[Cocoa-handle!]
;	cmd		[Cocoa-handle!]
;	notif	[Cocoa-handle!]
;	/local
;		win		[integer!]
;		text	[Cocoa-handle!]
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

update-text-selection: func [
	self	[Cocoa-handle!]
	idx		[integer!]
	len		[integer!]
	/local
		sel [red-pair!]
][
	sel: as red-pair! (get-face-values self) + FACE_OBJ_SELECTED
	either zero? len [sel/header: TYPE_NONE][
		sel/header: TYPE_PAIR
		sel/x: idx + 1
		sel/y: idx + len
	]
	make-event self 0 EVT_SELECT
]

#either ABI = 'apple-aarch64 [
	text-will-selection: func [
		[cdecl]
		self		[Cocoa-handle!]
		cmd			[Cocoa-handle!]
		view		[Cocoa-handle!]
		old-range	[NSRange! value]
		new-range	[NSRange! value]
		return:		[NSRange! value]
	][
		update-text-selection self as integer! new-range/idx as integer! new-range/len
		new-range
	]
][
	text-will-selection: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		view	[Cocoa-handle!]
		idx1	[integer!]
		len1	[integer!]
		idx2	[integer!]
		len2	[integer!]
	][
		update-text-selection self idx2 len2
		system/cpu/edx: len2
		system/cpu/eax: idx2
	]
]

area-did-end-editing: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
][
	make-event self 0 EVT_UNFOCUS
]

area-text-change: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
][
	set-text self objc_msgSend [self sel_getUid "string"]
	if loop-started? [make-event self 0 EVT_CHANGE]
]

selection-change: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
	/local
		idx [integer!]
		res [integer!]
][
	idx: as integer! objc_msgSend [self sel_getUid "indexOfSelectedItem"]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	obj		[Cocoa-handle!]
	return: [NSInteger!]
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
		as NSInteger! cnt
	][as NSInteger! 0]
]

object-for-table: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	obj		[Cocoa-handle!]
	column	[Cocoa-handle!]
	row		[NSInteger!]
	return: [Cocoa-handle!]
	/local
		data [red-block!]
		head [red-value!]
		tail [red-value!]
		font [red-object!]
		face [red-object!]
		attr [Cocoa-handle!]
		id	 [Cocoa-handle!]
		idx  [integer!]
		type [integer!]
		str  [Cocoa-handle!]
][
	data: (as red-block! get-face-values obj) + FACE_OBJ_DATA
	head: block/rs-head data
	tail: block/rs-tail data

	idx: -1
	while [all [row >= 0 head < tail]][
		type: TYPE_OF(head)
		if ANY_STRING?(type) [row: row - as NSInteger! 1]
		head: head + 1
		idx: idx + 1
	]

	if any [idx = -1 row >= 0][return 0]

	font: (as red-object! get-face-values obj) + FACE_OBJ_FONT
	str: to-NSString as red-string! block/rs-abs-at data idx
	if TYPE_OF(font) = TYPE_OBJECT [
		id: 0
		object_getInstanceVariable self IVAR_RED_FACE :id
		face: as red-object! references/get as integer! id
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	obj		[Cocoa-handle!]
	column	[Cocoa-handle!]
	row		[NSInteger!]
	return: [logic!]
][
	no
]

table-select-did-change: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
][
	0
]

win-send-event: func [
	self	[Cocoa-handle!]
	type	[integer!]
	event	[Cocoa-handle!]
	return: [logic!]
	/local
		responder	[Cocoa-handle!]
		view-type	[Cocoa-handle!]
		find?		[logic!]
		send?		[logic!]
][
	send?: yes
	view-type: as Cocoa-handle! 0
	case [
		type = NSKeyUp [
			responder: objc_msgSend [self sel_getUid "firstResponder"]
			object_getInstanceVariable responder IVAR_RED_DATA :view-type
			if view-type = base [
				on-key-up responder 0 event
				send?: no
			]
		]
		type = NSKeyDown [
			find?: yes
			responder: objc_msgSend [self sel_getUid "firstResponder"]
			object_getInstanceVariable responder IVAR_RED_DATA :view-type
			either view-type <> base [
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
	self		[Cocoa-handle!]
	cmd			[Cocoa-handle!]
	event		[Cocoa-handle!]
	/local
		p		[Cocoa-handle-ptr!]
		type	[integer!]
		window	[Cocoa-handle!]
		n-win	[integer!]
		flags	[integer!]
		faces	[red-block!]
		face	[red-object!]
		start	[red-object!]
		check?	[logic!]
		active?	[logic!]
		down?	[logic!]
		view	[Cocoa-handle!]
		state	[integer!]
		modal-win [Cocoa-handle!]
][
	window: objc_msgSend [event sel_getUid "window"]
	type: as integer! objc_msgSend [event sel_getUid "type"]
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
			p: as Cocoa-handle-ptr! vector/rs-tail active-wins
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
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	app		[Cocoa-handle!]
	return: [logic!]
][
	no
]

should-terminate: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	app		[Cocoa-handle!]
	return: [NSInteger!]
][
	#either sub-system = 'gui [as NSInteger! 1][as NSInteger! 0]	;-- 0: NSTerminateCancel
]

win-should-close: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	sender	[Cocoa-handle!]
	return: [logic!]
][
	make-event sender 0 EVT_CLOSE
	no
]

win-will-close: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
	/local
		i	[integer!]
		n	[integer!]
		p	[Cocoa-handle-ptr!]
		pp	[Cocoa-handle-ptr!]
][
	p: as Cocoa-handle-ptr! vector/rs-head active-wins
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
;	self	[Cocoa-handle!]
;	cmd		[Cocoa-handle!]
;	sender	[Cocoa-handle!]
;	w		[integer!]
;	h		[integer!]
;	return: [NSSize! value]
;	/local
;		sz	[NSSize! value]
;][
	
;]

win-did-resize: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
	/local
		sz	[red-pair!]
		pt	[red-point2D!]
		v	[Cocoa-handle!]
		rc	[NSRect! value]
][
	make-event self 0 EVT_SIZING
	v: objc_msgSend [self sel_getUid "contentView"]
	rc: objc_msgSend_rect [v sel_getUid "frame"]
	sz: (as red-pair! get-face-values self) + FACE_OBJ_SIZE		;-- update face/size
	either zero? objc_getAssociatedObject self RedPairSizeKey [
		pt: as red-point2D! sz
		pt/header: TYPE_POINT2D
		pt/x: COCOA_TO_F32(rc/w)
		pt/y: COCOA_TO_F32(rc/h)
	][
		sz/header: TYPE_PAIR
		sz/x: as-integer rc/w
		sz/y: as-integer rc/h
	]
]

win-live-resize: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
][
	make-event self 0 EVT_SIZE
]

win-did-move: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	notif	[Cocoa-handle!]
	/local
		rc	[NSRect! value]
		sz	[red-pair!]
][
	rc: objc_msgSend_rect [self sel_getUid "frame"]
	sz: (as red-pair! get-face-values self) + FACE_OBJ_OFFSET	;-- update face/offset
	sz/x: as-integer rc/x
	sz/y: screen-size-y - as-integer (rc/y + rc/h)
	make-event self 0 EVT_MOVE
]

tabview-should-select: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	tabview	[Cocoa-handle!]
	item	[Cocoa-handle!]
	return: [logic!]
	/local
		idx		[integer!]
][
	idx: as integer! objc_msgSend [tabview sel_getUid "indexOfTabViewItem:" item]
	either EVT_DISPATCH = make-event self idx + 1 EVT_CHANGE [
		set-selected self idx + 1
		yes
	][
		no
	]
]

#either ABI = 'apple-aarch64 [
	set-line-spacing: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		layout	[Cocoa-handle!]
		idx		[NSUInteger!]
		rc		[NSRect! value]
		return: [Cocoa-float!]
		/local
			d	[Cocoa-float!]
	][
		d: objc_msgSend_f32 [
			objc_getAssociatedObject layout RedAttachedWidgetKey
			sel_getUid "descender"
		]
		(as Cocoa-float! 1.5) - d
	]
][
	set-line-spacing: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		layout	[Cocoa-handle!]
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
		str		[Cocoa-handle!]
		attr	[Cocoa-handle!]
		nscolor [Cocoa-handle!]
		attrs	[Cocoa-handle!]
		objects	[Cocoa-handle-array!]
		keys	[Cocoa-handle-array!]
		line	[Cocoa-handle!]
		text-size [NSSize! value]
		temp	[Cocoa-float!]
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
		objects: declare Cocoa-handle-array!
		keys: declare Cocoa-handle-array!
		objects/v1: default-font
		keys/v1: NSFontAttributeName
		attrs: make-NSDictionary objects keys as NSUInteger! 1
	]

	str: to-CFString text
	attr: CFAttributedStringCreate 0 str attrs
	text-size: objc_msgSend_sz [attr sel_getUid "size"]
	rc: declare NSRect!
	rc/x: text-size/w
	rc/y: text-size/h
	rc/w: as Cocoa-float! 0.0
	rc/h: as Cocoa-float! 0.0

	para: as red-object! values + FACE_OBJ_PARA
	flags: either TYPE_OF(para) = TYPE_OBJECT [		;@@ TBD set alignment attribute
		get-para-flags base para
	][
		2 or 4										;-- center
	]

	m: make-CGMatrix 1 0 0 -1 0 0
	case [
		flags and 1 <> 0 [m/tx: sz/w - rc/x]
		flags and 2 <> 0 [temp: sz/w - rc/x m/tx: temp / as Cocoa-float! 2.0]
		true [0]
	]

	case [
		flags and 4 <> 0 [temp: sz/h - rc/y m/ty: temp / as Cocoa-float! 2.0]
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
		m/ty: m/ty - temp + (rc/y / as Cocoa-float! 2.0)
		CGContextTranslateCTM ctx m/tx m/ty
		CGContextMoveToPoint ctx as Cocoa-float! 0.0 as Cocoa-float! 0.0
		CGContextAddLineToPoint ctx rc/x as Cocoa-float! 0.0
		CGContextStrokePath ctx
	]
	objc_msgSend [attrs sel_getUid "release"]
	CGContextRestoreGState ctx
]

paint-background: func [
	ctx		[handle!]
	color	[integer!]
	x		[Cocoa-float!]
	y		[Cocoa-float!]
	width	[Cocoa-float!]
	height	[Cocoa-float!]
	/local
		r	[Cocoa-float!]
		g	[Cocoa-float!]
		b	[Cocoa-float!]
		a	[Cocoa-float!]
][
	r: (as Cocoa-float! color and FFh) / 255.0
	g: (as Cocoa-float! color >> 8 and FFh) / 255.0
	b: (as Cocoa-float! color >> 16 and FFh) / 255.0
	a: (as Cocoa-float! 255 - (color >>> 24)) / 255.0
	CGContextSetRGBFillColor ctx r g b a
	CGContextFillRect ctx x y width height
]

has-marked-text: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	return: [logic!]
][
	in-composition?
]

_marked-range-idx: 0
_marked-range-len: 0

#either ABI = 'apple-aarch64 [
	marked-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		return: [NSRange! value]
		/local
			range [NSRange! value]
	][
		range/idx: as NSUInteger! _marked-range-idx
		range/len: as NSUInteger! _marked-range-len
		range
	]

	selected-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		return: [NSRange! value]
		/local
			range [NSRange! value]
	][
		range/idx: as NSUInteger! 0
		range/len: as NSUInteger! 0
		range
	]
][
	marked-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
	][
		system/cpu/edx: _marked-range-len
		system/cpu/eax: _marked-range-idx
	]

	selected-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
	][
		system/cpu/edx: 0
		system/cpu/eax: 0
	]
]

get-text-styles: func [
	str		[Cocoa-handle!]
	styles	[red-block!]
][
	
]

set-marked-text*: func [
	self	[Cocoa-handle!]
	str		[Cocoa-handle!]
	idx		[integer!]
	/local
		attr-str?	[logic!]
		text		[Cocoa-handle!]
][
	in-composition?: yes
	attr-str?: as logic! objc_msgSend [
		str sel_getUid "isKindOfClass:" objc_getClass "NSAttributedString"
	]
	text: either attr-str? [objc_msgSend [str sel_getUid "string"]][str]
	make-event self text EVT_IME
	_marked-range-idx: idx
	_marked-range-len: as integer! objc_msgSend [text sel_length]
	if zero? _marked-range-len [
		objc_msgSend [self sel_getUid "unmarkText"]
	]
]

#either ABI = 'apple-aarch64 [
	set-marked-text: func [
		[cdecl]
		self			[Cocoa-handle!]
		cmd				[Cocoa-handle!]
		str				[Cocoa-handle!]
		selected-range	[NSRange! value]
		replace-range	[NSRange! value]
	][
		set-marked-text* self str as integer! selected-range/idx
	]
][
	set-marked-text: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		str		[Cocoa-handle!]
		idx1	[integer!]
		len1	[integer!]
		idx2	[integer!]
		len2	[integer!]
	][
		set-marked-text* self str idx1
	]
]

unmark-text: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
][
	in-composition?: no
	objc_msgSend [
		objc_msgSend [self sel_getUid "inputContext"]
		sel_getUid "discardMarkedText"
	]
]

valid-attrs-marked-text: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	return: [Cocoa-handle!]
	/local
		objects [Cocoa-handle-array!]
][
	objects: declare Cocoa-handle-array!
	objects/v1: NSMarkedClauseSegmentAttributeName
	objects/v2: NSGlyphInfoAttributeName
	objc_msgSend [
		objc_getClass "NSArray" sel_getUid "arrayWithObjects:count:"
		as Cocoa-handle-ptr! objects
		as NSUInteger! 2
	]
]

attr-str-range*: func [
	self	[Cocoa-handle!]
	return: [Cocoa-handle!]
][
	as Cocoa-handle! 0
]

#either ABI = 'apple-aarch64 [
	attr-str-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		range	[NSRange! value]
		actual	[NSRange!]
		return: [Cocoa-handle!]
	][
		attr-str-range* self
	]
][
	attr-str-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		idx		[integer!]
		len		[integer!]
		p-range	[int-ptr!]
		return: [Cocoa-handle!]
	][
		attr-str-range* self
	]
]

insert-text-range*: func [
	self	[Cocoa-handle!]
	str		[Cocoa-handle!]
	/local
		attr-str?	[logic!]
		text		[Cocoa-handle!]
		key			[integer!]
		idx			[integer!]
		len			[integer!]
][
	special-key: 0
	objc_msgSend [self sel_getUid "unmarkText"]
	attr-str?: as logic! objc_msgSend [
		str sel_getUid "isKindOfClass:" objc_getClass "NSAttributedString"
	]
	text: either attr-str? [objc_msgSend [str sel_getUid "string"]][str]
	len: as integer! objc_msgSend [text sel_length]
	idx: 0
	while [idx < len][
		key: as integer! objc_msgSend [text sel_getUid "characterAtIndex:" idx]
		make-event self key EVT_KEY
		idx: idx + 1
	]
]

#either ABI = 'apple-aarch64 [
	insert-text-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		str		[Cocoa-handle!]
		range	[NSRange! value]
	][
		insert-text-range* self str
	]
][
	insert-text-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		str		[Cocoa-handle!]
		idx		[integer!]
		len		[integer!]
	][
		insert-text-range* self str
	]
]

#either ABI = 'apple-aarch64 [
	char-idx-point: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		point	[CGPoint! value]
		return: [NSUInteger!]
	][
		as NSUInteger! 0
	]

	first-rect-range: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		range	[NSRange! value]
		actual	[NSRange!]
		return: [NSRect! value]
		/local
			rc		[NSRect! value]
			pt		[CGPoint! value]
			window	[Cocoa-handle!]
	][
		rc/x: F32_TO_COCOA caret-x
		rc/y: F32_TO_COCOA (caret-y + caret-h)
		rc/w: F32_TO_COCOA caret-w
		rc/h: F32_TO_COCOA caret-h
		pt: objc_msgSend_pt [self sel_getUid "convertPoint:toView:" rc/x rc/y 0]
		window: objc_msgSend [self sel_getUid "window"]
		pt: objc_msgSend_pt [window sel_getUid "convertPointToScreen:" pt/x pt/y]
		rc/x: pt/x
		rc/y: pt/y
		rc
	]
][
	char-idx-point: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		x		[float32!]
		y		[float32!]
		return: [integer!]
	][
		0
	]

	first-rect-range: func [
		[stdcall]
		base		[integer!]
	/local
		pc		[int-ptr!]
		rc		[NSRect!]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
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
]

do-cmd-selector: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	sel		[Cocoa-handle!]
	/local
		event [Cocoa-handle!]
][
	event: objc_msgSend [NSApp sel_getUid "currentEvent"]
	if all [
		event <> 0
		NSKeyDown = objc_msgSend [event sel_getUid "type"]
	][
		on-key-down self event
	]
]

hit-test*: func [
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	x		[Cocoa-float!]
	y		[Cocoa-float!]
	return: [Cocoa-handle!]
	/local
		img		[red-image!]
		sz		[red-pair!]
		pt		[CGPoint! value]
		super	[objc_super! value]
		v		[Cocoa-handle!]
		pixel	[Cocoa-handle!]
		pixel-value [integer!]
		w		[integer!]
		h		[integer!]
		ix		[integer!]
		iy		[integer!]
		ratio	[Cocoa-float!]
		vals	[red-value!]
		clr		[red-tuple!]
		rc		[NSRect! value]
		rep		[Cocoa-handle!]
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
			ratio: (as Cocoa-float! w) / (as Cocoa-float! sz/x)
			ix: as integer! (pt/x * ratio)
			ratio: (as Cocoa-float! h) / (as Cocoa-float! sz/y)
			iy: as integer! (pt/y * ratio)
			pixel-value: OS-image/get-pixel resolve-node img/node iy * w + ix
			if pixel-value >>> 24 = 0 [return as Cocoa-handle! 0]
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
			if alpha = 0.0 [return as Cocoa-handle! 0]
		]
	]
	v
]

#either ABI = 'apple-aarch64 [
	hit-test: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		point	[CGPoint! value]
		return: [Cocoa-handle!]
	][
		hit-test* self cmd point/x point/y
	]
][
	hit-test: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		x		[float32!]
		y		[float32!]
		return: [Cocoa-handle!]
	][
		hit-test* self cmd x y
	]
]

draw-rect*: func [
	self	[Cocoa-handle!]
	x		[Cocoa-float!]
	y		[Cocoa-float!]
	width	[Cocoa-float!]
	height	[Cocoa-float!]
	/local
		nsctx	[Cocoa-handle!]
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
		bounds	[NSRect! value]
		view-size [NSSize! value]
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
		CG-draw-image ctx as Cocoa-handle! OS-image/to-cgimage img 0 0 sx sy
	]
	bounds: objc_msgSend_rect [self sel_getUid "bounds"]
	view-size/w: bounds/w
	view-size/h: bounds/h
	case [
		sym = base [render-text ctx vals :view-size]
		sym = rich-text [
			pos/header: TYPE_POINT2D
			pos/x: F32_0 pos/y: F32_0
			draw-text-box null as red-pair! :pos get-face-obj self yes
		]
		true []
	]

	either TYPE_OF(draw) = TYPE_BLOCK [
		do-draw ctx null draw no yes no yes
	][
		system/thrown: 0
		DC: declare draw-ctx!								;@@ should declare it on stack
		draw-begin DC ctx null no no
		object_setInstanceVariable self IVAR_RED_DRAW_CTX as Cocoa-handle! DC
		make-event self 0 EVT_DRAWING
		draw-end DC ctx no no no
	]
]

#either ABI = 'apple-aarch64 [
	draw-rect: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		rc		[NSRect! value]
	][
		draw-rect* self rc/x rc/y rc/w rc/h
	]
][
	draw-rect: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		x		[float32!]
		y		[float32!]
		width	[float32!]
		height	[float32!]
	][
		draw-rect* self x y width height
	]
]

return-field-editor: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	sender	[Cocoa-handle!]
	obj		[Cocoa-handle!]
	return: [Cocoa-handle!]
][
	objc_setAssociatedObject sender RedFieldEditorKey obj OBJC_ASSOCIATION_ASSIGN
	0
]

perform-key-equivalent: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	event	[Cocoa-handle!]
	return: [logic!]
	/local
		type  [integer!]
		flags [integer!]
		mask  [integer!]
		obj   [Cocoa-handle!]
		sel   [Cocoa-handle!]
][
	type: as integer! objc_msgSend [event sel_getUid "type"]
	if type = NSKeyDown [
		flags: as integer! objc_msgSend [event sel_getUid "modifierFlags"]
		mask: 0
		if flags and NSAlternateKeyMask <> 0 [mask: mask or NSAlternateKeyMask]
		if flags and NSShiftKeyMask <> 0 [mask: mask or NSShiftKeyMask]
		if flags and NSControlKeyMask <> 0 [mask: mask or NSControlKeyMask]
		if flags and NSCommandKeyMask <> 0 [mask: mask or NSCommandKeyMask]
		sel: as Cocoa-handle! 0
		if mask = NSCommandKeyMask [
			flags: as integer! objc_msgSend [event sel_getUid "keyCode"]
			sel: switch flags [
				6 [sel_getUid "undo:"]				;-- Z
				7 [sel_getUid "cut:"]				;-- X
				8 [sel_getUid "copy:"]				;-- C
				9 [sel_getUid "paste:"]				;-- V
				0 [sel_getUid "selectAll:"]			;-- A
				default [as Cocoa-handle! 0]
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
