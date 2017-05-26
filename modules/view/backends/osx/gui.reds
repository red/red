Red/System [
	Title:	"MacOSX GUI backend"
	Author: "Qingtian Xie"
	File: 	%gui.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %../keycodes.reds
#include %cocoa.reds
#include %selectors.reds
#include %events.reds

#include %font.reds
#include %para.reds
#include %draw.reds

#include %classes.reds
#include %menu.reds
#include %tab-panel.reds
#include %comdlgs.reds

win-cnt:		0
loop-started?:	no
close-window?:	no

NSApp:			0
NSAppDelegate:	0
AppMainMenu:	0

current-widget: 0			;-- for mouse tracking: mouseEnter, mouseExit

default-font:	0
log-pixels-x:	0
log-pixels-y:	0
screen-size-x:	0
screen-size-y:	0
mac-version:	0

;-- for IME support
in-composition?: no
ime-str-styles: as red-block! 0
caret-w:		as float32! 0.0
caret-h:		as float32! 0.0
caret-x:		as float32! 0.0
caret-y:		as float32! 0.0

win-array:		declare red-vector!

red-face?: func [
	handle	[integer!]
	return: [logic!]
][
	0 <> class_getInstanceVariable object_getClass handle IVAR_RED_FACE
]

get-face-values: func [
	handle	[integer!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		s	 [series!]
		ivar [integer!]
		face [red-object!]
][
	ivar: class_getInstanceVariable object_getClass handle IVAR_RED_FACE
	assert ivar <> 0
	face: as red-object! handle + ivar_getOffset ivar
	ctx: TO_CTX(face/ctx)
	s: as series! ctx/values/value
	s/offset
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

get-face-flags: func [
	face	[handle!]
	return: [integer!]
][
	0
]

face-handle?: func [
	face	[red-object!]
	return: [handle!]									;-- returns NULL is no handle
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

get-face-handle: func [
	face	[red-object!]
	return: [integer!]
	/local
		state [red-block!]
		int	  [red-integer!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	assert TYPE_OF(state) = TYPE_BLOCK
	int: as red-integer! block/rs-head state
	assert TYPE_OF(int) = TYPE_HANDLE
	int/value
]

get-child-from-xy: func [
	parent	[handle!]
	x		[integer!]
	y		[integer!]
	return: [integer!]
	/local
		hWnd [handle!]
][
0
]

get-text-size: func [
	str		[red-string!]
	hFont	[handle!]
	pair	[red-pair!]
	return: [tagSIZE]
	/local
		attrs	[integer!]
		cf-str	[integer!]
		attr	[integer!]
		y		[integer!]
		x		[integer!]
		rc		[NSRect!]
		size	[tagSIZE]
][
	size: declare tagSIZE
	if null? hFont [hFont: as handle! default-font]

	attrs: objc_msgSend [
		objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
		sel_getUid "initWithObjectsAndKeys:"
		hFont NSFontAttributeName
		0
	]
	cf-str: to-CFString str
	attr: CFAttributedStringCreate 0 cf-str attrs
	x: objc_msgSend [attr sel_getUid "size"]		;-- string width on screen
	y: system/cpu/edx								;-- string height on screen
	rc: as NSRect! :x

	size/width: as-integer rc/x
	size/height: as-integer rc/y
	if pair <> null [
		pair/x: size/width
		pair/y: size/height
	]
	CFRelease cf-str
	CFRelease attr
	objc_msgSend [attrs sel_getUid "release"]
	size
]

free-handles: func [
	hWnd	[integer!]
	force?	[logic!]
	/local
		values [red-value!]
		type   [red-word!]
		face   [red-object!]
		tail   [red-object!]
		pane   [red-block!]
		state  [red-value!]
		rate   [red-value!]
		sym	   [integer!]
		handle [integer!]
][
	if hWnd = current-widget [current-widget: 0]

	values: get-face-values hWnd
	type: as red-word! values + FACE_OBJ_TYPE
	sym: symbol/resolve type/symbol

	if all [sym = window not force?][
		close-window?: yes
		vector/rs-append-int win-array hWnd
		exit
	]

	rate: values + FACE_OBJ_RATE
	if TYPE_OF(rate) <> TYPE_NONE [change-rate hWnd none-value]

	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [face < tail][
			handle: as-integer face-handle? face
			if handle <> 0 [free-handles handle force?]
			face: face + 1
		]
	]

	either sym = window [
		objc_msgSend [hWnd sel_getUid "close"]
		win-cnt: win-cnt - 1
	][
		objc_msgSend [hWnd sel_getUid "removeFromSuperview"]
	]

	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

get-os-version: func [
	/local
		ver		[red-tuple!]
		int		[red-integer!]
		v		[integer!]
		major	[integer!]
		minor	[integer!]
		bugfix	[integer!]
][
	v: 0 major: 0 minor: 0 bugfix: 0
	Gestalt gestaltSystemVersion :v
	Gestalt gestaltSystemVersionMajor :major
	Gestalt gestaltSystemVersionMinor :minor
	Gestalt gestaltSystemVersionBugFix :bugfix

	mac-version: major * 100 + minor

	ver: as red-tuple! #get system/view/platform/version
	ver/header: TYPE_TUPLE or (3 << 19)
	ver/array1: bugfix << 16 or (minor << 8) or major

	int: as red-integer! #get system/view/platform/build
	int/header: TYPE_INTEGER
	int/value:  v and FFFFh

	int: as red-integer! #get system/view/platform/product
	int/header: TYPE_INTEGER
	int/value:  0
]

set-defaults: func [][
	default-font: objc_msgSend [
		objc_getClass "NSFont" sel_getUid "systemFontOfSize:" 0
	]
	objc_msgSend [default-font sel_getUid "retain"]
]

get-metrics: func [][
	copy-cell 
		as red-value! integer/push log-pixels-x
		#get system/view/metrics/dpi
]

init: func [
	/local
		screen	 [integer!]
		rect	 [NSRect!]
		pool	 [integer!]
		delegate [integer!]
		lib		 [integer!]
		dict	 [integer!]
		y		 [integer!]
		x		 [integer!]
		sz		 [NSSize!]
		dpi		 [integer!]
		scaling  [float32!]
		p-int	 [int-ptr!]
][
	vector/make-at as red-value! win-array 8 TYPE_INTEGER 4
	init-selectors

	NSApp: objc_msgSend [objc_getClass "NSApplication" sel_getUid "sharedApplication"]

	pool: objc_msgSend [objc_getClass "NSAutoreleasePool" sel_getUid "alloc"]
	objc_msgSend [pool sel_getUid "init"]

	get-os-version
	register-classes

	delegate: objc_msgSend [objc_getClass "RedAppDelegate" sel_getUid "alloc"]
	delegate: objc_msgSend [delegate sel_getUid "init"]
	NSAppDelegate: delegate
	objc_msgSend [NSApp sel_getUid "setDelegate:" delegate]

	create-main-menu

	;dlopen "./FScript.framework/FScript" 1
	;objc_msgSend [
	;	objc_msgSend [NSApp sel_getUid "mainMenu"]
	;	sel_getUid "addItem:"
	;	objc_msgSend [objc_msgSend [objc_getClass "FScriptMenuItem" sel_alloc] sel_init]
	;]

	screen: objc_msgSend [objc_getClass "NSScreen" sel_getUid "mainScreen"]
	rect: as NSRect! (as int-ptr! screen) + 1
	screen-size-x: as-integer rect/w
	screen-size-y: as-integer rect/h

	dict: objc_msgSend [screen sel_getUid "deviceDescription"]
	dpi: objc_msgSend [dict sel_getUid "objectForKey:" NSDeviceResolution]

	x: objc_msgSend [dpi sel_getUid "sizeValue"]
	y: system/cpu/edx
	sz: as NSSize! :x

	scaling: as float32! 1.0
	if mac-version >= 1070 [
		scaling: objc_msgSend_f32 [screen sel_getUid "backingScaleFactor"]
	]

	log-pixels-x: as-integer sz/w / scaling
	log-pixels-y: as-integer sz/h / scaling

	set-defaults

	objc_msgSend [NSApp sel_getUid "setActivationPolicy:" 0]
	objc_msgSend [NSApp sel_getUid "finishLaunching"]

	get-metrics
]

set-logic-state: func [
	hWnd   [integer!]
	state  [red-logic!]
	check? [logic!]
	/local
		value [integer!]
][
	value: either TYPE_OF(state) <> TYPE_LOGIC [
		state/header: TYPE_LOGIC
		state/value: check?
		either check? [-1][0]
	][
		as-integer state/value							;-- returns 0/1, matches the messages
	]
	objc_msgSend [hWnd sel_getUid "setState:"  value]
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

	until [
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
			sym = editable	 [flags: flags or FACET_FLAGS_EDITABLE]
			sym = scrollable [flags: flags or FACET_FLAGS_SCROLLABLE]
			sym = Direct2D	 [0]
			true			 [fire [TO_ERROR(script invalid-arg) word]]
		]
		word: word + 1
		len: len - 1
		zero? len
	]
	flags
]

get-position-value: func [
	pos		[red-float!]
	maximun [float!]
	return: [float!]
	/local
		f	[float!]
][
	f: 0.0
	if any [
		TYPE_OF(pos) = TYPE_FLOAT
		TYPE_OF(pos) = TYPE_PERCENT
	][
		f: pos/value *  maximun
	]
	f
]

get-screen-size: func [
	id		[integer!]									;@@ Not used yet
	return: [red-pair!]
][
	pair/push screen-size-x screen-size-y
]

store-face-to-obj: func [
	obj		[integer!]
	class	[integer!]
	face	[red-object!]
	/local
		new  [red-object!]
		ivar [integer!]
][
	ivar: class_getInstanceVariable class IVAR_RED_FACE
	assert ivar <> 0
	new: as red-object! obj + ivar_getOffset ivar
	copy-cell as cell! face as cell! new
]

make-rect: func [
	x		[integer!]
	y		[integer!]
	w		[integer!]
	h		[integer!]
	return: [NSRect!]
	/local
		r	[NSRect!]
][
	r: declare NSRect!
	r/x: as float32! x
    r/y: as float32! y
    r/w: as float32! w
    r/h: as float32! h
    r
]

change-rate: func [
	hWnd [integer!]
	rate [red-value!]
	/local
		int		[red-integer!]
		tm		[red-time!]
		timer	[integer!]
		ts		[float!]
][
	timer: objc_getAssociatedObject hWnd RedTimerKey

	if timer <> 0 [								;-- cancel a preexisting timer
		objc_msgSend [timer sel_getUid "invalidate"]
		objc_setAssociatedObject hWnd RedTimerKey 0 OBJC_ASSOCIATION_ASSIGN
	]

	switch TYPE_OF(rate) [
		TYPE_INTEGER [
			int: as red-integer! rate
			if int/value <= 0 [fire [TO_ERROR(script invalid-facet-type) rate]]
			ts: 1.0 / as-float int/value
		]
		TYPE_TIME [
			tm: as red-time! rate
			if tm/time <= 0.0 [fire [TO_ERROR(script invalid-facet-type) rate]]
			ts: tm/time / 1E9
		]
		TYPE_NONE [exit]
		default	  [fire [TO_ERROR(script invalid-facet-type) rate]]
	]

	timer: objc_msgSend [
		objc_getClass "NSTimer"
		sel_getUid "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:"
		ts hWnd sel-on-timer 0 yes
	]
	objc_setAssociatedObject hWnd RedTimerKey timer OBJC_ASSOCIATION_ASSIGN
]

change-size: func [
	hWnd [integer!]
	size [red-pair!]
	type [integer!]
	/local
		h		[integer!]
		w		[integer!]
		y		[integer!]
		x		[integer!]
		rc		[NSRect!]
		frame	[NSRect!]
		saved	[int-ptr!]
		method	[integer!]
][
	rc: make-rect size/x size/y 0 0
	if all [type = button size/y > 32][
		objc_msgSend [hWnd sel_getUid "setBezelStyle:" NSRegularSquareBezelStyle]
	]
	either type = window [
		x: 0
		frame: as NSRect! :x
		method: sel_getUid "frame"
		saved: system/stack/align
		push 0
		push method push hWnd push frame
		objc_msgSend_stret 3
		system/stack/top: saved
		frame/y: frame/y + frame/h - rc/y
		objc_msgSend [hWnd sel_getUid "setFrame:display:animate:" frame/x frame/y rc/x rc/y yes yes]
	][
		objc_msgSend [hWnd sel_getUid "setFrameSize:" rc/x rc/y]
		objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
		object_getInstanceVariable hWnd IVAR_RED_DATA :type
		if type = caret [
			caret-w: rc/x
			caret-h: rc/y
		]
	]
]

change-image: func [
	hWnd	[integer!]
	image	[red-image!]
	type	[integer!]
	/local
		cg-image [integer!]
		id		 [integer!]
][
	case [
		type = camera [
			snap-camera hWnd
			until [TYPE_OF(image) = TYPE_IMAGE]			;-- wait
		]
		any [type = button type = check type = radio][
			if TYPE_OF(image) <> TYPE_IMAGE [
				objc_msgSend [hWnd sel_getUid "setImage:" 0]
				exit
			]
			cg-image: CGBitmapContextCreateImage as-integer image/node
			id: objc_msgSend [objc_getClass "NSImage" sel_getUid "alloc"]
			id: objc_msgSend [id sel_getUid "initWithCGImage:size:" cg-image 0 0]
			objc_msgSend [hWnd sel_getUid "setImage:" id]
			objc_msgSend [id sel_getUid "release"]
			CGImageRelease cg-image
		]
		true [
			objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
		]
	]
]

set-caret-color: func [
	hWnd	[integer!]
	color	[integer!]
	/local
		clr [integer!]
][
	clr: either any [
		color and FFh < 100
		color >> 8 and FFh < 100
		color >> 16 and FFh < 100
	][
		objc_msgSend [objc_getClass "NSColor" sel_getUid "whiteColor"]
	][
		objc_msgSend [objc_getClass "NSColor" sel_getUid "blackColor"]
	]
	objc_msgSend [hWnd sel_getUid "setInsertionPointColor:" clr]
]

change-color: func [
	hWnd	[integer!]
	color	[red-tuple!]
	type	[integer!]
	/local
		clr  [integer!]
		set? [logic!]
][
	if TYPE_OF(color) <> TYPE_TUPLE [exit]
	if transparent-color? color [
		objc_msgSend [hWnd sel_getUid "setDrawsBackground:" no]
		exit
	]
	set?: yes
	case [
		type = area [
			hWnd: objc_msgSend [hWnd sel_getUid "documentView"]
			set-caret-color hWnd color/array1
		]
		type = text [
			objc_msgSend [hWnd sel_getUid "setDrawsBackground:" yes]
		]
		any [type = check type = radio][
			hWnd: objc_msgSend [hWnd sel_getUid "cell"]
		]
		any [type = field type = window][0]				;-- no special process
		true [
			set?: no
			objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
		]
	]
	if set? [
		clr: to-NSColor color
		objc_msgSend [hWnd sel_getUid "setBackgroundColor:" clr]
	]
]

update-z-order: func [
	parent	[integer!]
	pane	[red-block!]
	type	[integer!]
	/local
		face [red-object!]
		tail [red-object!]
		hWnd [handle!]
		parr [int-ptr!]
		arr  [integer!]
		nb   [integer!]
		s	 [series!]
][
	s: GET_BUFFER(pane)
	face: as red-object! s/offset + pane/head
	tail: as red-object! s/tail
	nb: (as-integer tail - face) >> 4

	parr: as int-ptr! allocate nb * 4
	nb: 0
	while [face < tail][
		if TYPE_OF(face) = TYPE_OBJECT [
			hWnd: face-handle? face
			if hWnd <> null [
				nb: nb + 1
				parr/nb: as-integer hWnd
			]
		]
		face: face + 1
	]
	arr: objc_msgSend [
		objc_getClass "NSArray"
		sel_getUid "arrayWithObjects:count:"
		parr nb
	]
	free as byte-ptr! parr
	if type = window [parent: objc_msgSend [parent sel_getUid "contentView"]]
	objc_msgSend [parent sel_getUid "setSubviews:" arr]
]

change-font: func [
	hWnd	[integer!]
	face	[red-object!]
	font	[red-object!]
	type	[integer!]
	return: [logic!]
	/local
		values	[red-value!]
		nscolor	[integer!]
		attrs	[integer!]
		str		[integer!]
		title	[integer!]
		view	[integer!]
		storage [integer!]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return no]

	attrs: make-font-attrs font face type
	;objc_msgSend [attrs sel_getUid "autorelease"]

	either type = area [
		view: objc_msgSend [hWnd sel_getUid "documentView"]
		storage: objc_msgSend [view sel_getUid "textStorage"]
		objc_msgSend [
			storage sel_getUid "setAttributes:range:"
			attrs 0 objc_msgSend [storage sel_getUid "length"]
		]
		objc_msgSend [view sel_getUid "setTypingAttributes:" attrs]
	][
		if type = field [
			objc_msgSend [
				hWnd sel_getUid "setFont:"
				objc_msgSend [attrs sel_getUid "objectForKey:" NSFontAttributeName]
			]
			objc_msgSend [
				hWnd sel_getUid "setTextColor:"
				objc_msgSend [attrs sel_getUid "objectForKey:" NSForegroundColorAttributeName]
			]
		]
		values: (object/get-values face) + FACE_OBJ_TEXT
		if TYPE_OF(values) <> TYPE_STRING [return no]			;-- accept any-string! ?

		title: to-NSString as red-string! values
		str: objc_msgSend [
			objc_msgSend [objc_getClass "NSAttributedString" sel_getUid "alloc"]
			sel_getUid "initWithString:attributes:" title attrs
		]
		case [
			any [type = button type = check type = radio][
				objc_msgSend [hWnd sel_getUid "setAttributedTitle:" str]
			]
			any [type = field type = text][
				objc_msgSend [hWnd sel_getUid "setAttributedStringValue:" str]
			]
			true [0]
		]
	]
	yes
]

change-offset: func [
	hWnd [integer!]
	pos  [red-pair!]
	type [integer!]
	/local
		rc [NSRect!]
][
	rc: make-rect pos/x pos/y 0 0
	either type = window [
		rc/y: as float32! screen-size-y - pos/y
		objc_msgSend [hWnd sel_getUid "setFrameTopLeftPoint:" rc/x rc/y]
	][
		objc_msgSend [hWnd sel_getUid "setFrameOrigin:" rc/x rc/y]
		unless in-composition? [
			object_getInstanceVariable hWnd IVAR_RED_DATA :type
			if type = caret [
				caret-x: rc/x
				caret-y: rc/y
			]
		]
	]
]

change-visible: func [
	hWnd  [integer!]
	show? [logic!]
	type  [integer!]
][
	case [
		any [type = button type = check type = radio][
			objc_msgSend [hWnd sel_getUid "setEnabled:" show?]
			objc_msgSend [hWnd sel_getUid "setTransparent:" not show?]
		]
		type = window [
			either show? [
				objc_msgSend [hWnd sel_getUid "makeKeyAndOrderFront:" hWnd]
			][
				objc_msgSend [hWnd sel_getUid "orderOut:" hWnd]
			]
		]
		true [objc_msgSend [hWnd sel_getUid "setHidden:" not show?]]
	]
]

change-text: func [
	hWnd	[integer!]
	values	[red-value!]
	face	[red-object!]
	type	[integer!]
	/local
		len  [integer!]
		txt  [integer!]
		cstr [c-string!]
		str  [red-string!]
][
	if type = base [
		objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
		exit
	]

	str: as red-string! values + FACE_OBJ_TEXT
	cstr: switch TYPE_OF(str) [
		TYPE_STRING [len: -1 unicode/to-utf8 str :len]
		TYPE_NONE	[""]
		default		[null]									;@@ Auto-convert?
	]

	if null? cstr [exit]
	
	txt: CFString(cstr)
	either type = area [
		objc_msgSend [
			objc_msgSend [hWnd sel_getUid "documentView"]
			sel_getUid "setString:" txt
		]
	][
		unless change-font hWnd face as red-object! values + FACE_OBJ_FONT type [
			case [
				any [type = field type = text][
					objc_msgSend [hWnd sel_getUid "setStringValue:" txt]
				]
				any [type = button type = radio type = check] [
					objc_msgSend [hWnd sel_getUid "setTitle:" txt]
				]
				true [0]
			]
		]
	]
	CFRelease txt
]

change-data: func [
	hWnd   [integer!]
	values [red-value!]
	/local
		data 	[red-value!]
		word 	[red-word!]
		size	[red-pair!]
		f		[red-float!]
		str		[red-string!]
		caption [c-string!]
		type	[integer!]
		len		[integer!]
][
	data: as red-value! values + FACE_OBJ_DATA
	word: as red-word! values + FACE_OBJ_TYPE
	type: word/symbol

	case [
		all [
			type = progress
			TYPE_OF(data) = TYPE_PERCENT
		][
			f: as red-float! data
			objc_msgSend [hWnd sel_getUid "setDoubleValue:" f/value * 100.0]
		]
		all [
			type = slider
			TYPE_OF(data) = TYPE_PERCENT
		][
			f: as red-float! data
			size: as red-pair! values + FACE_OBJ_SIZE
			len: either size/x > size/y [size/x][size/y]
			objc_msgSend [hWnd sel_getUid "setDoubleValue:" f/value * (as-float len)]
		]
		type = check [
			set-logic-state hWnd as red-logic! data yes
		]
		type = radio [
			set-logic-state hWnd as red-logic! data no
		]
		type = tab-panel [
			set-tabs hWnd get-face-values hWnd
		]
		all [
			type = text-list
			TYPE_OF(data) = TYPE_BLOCK
		][
			objc_msgSend [objc_msgSend [hWnd sel_getUid "documentView"] sel_getUid "reloadData"]
		]
		any [type = drop-list type = drop-down][
			init-combo-box
				hWnd
				as red-block! data
				null
				as red-integer! values + FACE_OBJ_SELECTED
				type = drop-list
		]
		true [0]										;-- default, do nothing
	]
]

change-selection: func [
	hWnd   [integer!]
	int	   [red-integer!]								;-- can be also none! | object!
	type   [integer!]
	/local
		idx [integer!]
		sz	[integer!]
		wnd [integer!]
][
	if type <> window [
		idx: either TYPE_OF(int) = TYPE_INTEGER [int/value - 1][-1]
		if idx < 0 [exit]								;-- @@ should unselect the items ?
	]
	case [
		type = camera [
			either TYPE_OF(int) = TYPE_NONE [
				toggle-preview hWnd false
			][
				select-camera hWnd idx
				toggle-preview hWnd true
			]
		]
		type = text-list [
			hWnd: objc_msgSend [hWnd sel_getUid "documentView"]
			sz: -1 + objc_msgSend [hWnd sel_getUid "numberOfRows"]
			if sz < 0 [exit]
			if sz < idx [idx: sz]			;-- select the last one
			idx: objc_msgSend [objc_getClass "NSIndexSet" sel_getUid "indexSetWithIndex:" idx]
			objc_msgSend [
				hWnd sel_getUid "selectRowIndexes:byExtendingSelection:" idx no
			]
			objc_msgSend [idx sel_getUid "release"]
		]
		any [type = drop-list type = drop-down][
			sz: -1 + objc_msgSend [hWnd sel_getUid "numberOfItems"]
			if sz < 0 [exit]
			if sz < idx [idx: sz]
			objc_msgSend [hWnd sel_getUid "selectItemAtIndex:" idx]
			idx: objc_msgSend [hWnd sel_getUid "objectValueOfSelectedItem"]
			objc_msgSend [hWnd sel_getUid "setObjectValue:" idx]
		]
		type = tab-panel [select-tab hWnd int]
		type = window [
			wnd: either TYPE_OF(int) = TYPE_OBJECT [
				as-integer face-handle? as red-object! int
			][0]
			objc_msgSend [hWnd sel_getUid "makeFirstResponder:" wnd]
		]
		true [0]										;-- default, do nothing
	]
]

setup-tracking-area: func [
	obj		[integer!]
	face	[red-object!]
	rc		[NSRect!]
	flags	[integer!]
	/local
		actors	[red-object!]
		track	[integer!]
		options [integer!]
][
	actors: as red-object! object/rs-select face as red-value! _actors
	if TYPE_OF(actors) <> TYPE_OBJECT [exit]
	if -1 = _context/find-word GET_CTX(actors) on-over yes [exit]

	rc/x: as float32! 0
	rc/y: as float32! 0
	options: NSTrackingMouseEnteredAndExited or
		NSTrackingActiveInKeyWindow or
		NSTrackingInVisibleRect or
		NSTrackingEnabledDuringMouseDrag
	;if flags and FACET_FLAGS_ALL_OVER <> 0 [
	;	options: options or NSTrackingMouseMoved
	;]
	track: objc_msgSend [
		objc_msgSend [objc_getClass "NSTrackingArea" sel_getUid "alloc"]
		sel_getUid "initWithRect:options:owner:userInfo:"
		rc/x rc/y rc/w rc/h options obj 0
	]
	objc_msgSend [obj sel_getUid "addTrackingArea:" track]
	objc_setAssociatedObject obj RedAllOverFlagKey track OBJC_ASSOCIATION_RETAIN
]

same-type?: func [
	obj		[integer!]
	name	[c-string!]
	return: [logic!]
][
	(object_getClass obj) = objc_getClass name
]

set-content-view: func [
	obj		[integer!]
	/local
		rect [NSRect!]
		view [integer!]
][
	view: objc_msgSend [objc_getClass "RedView" sel_getUid "alloc"]
	rect: make-rect 0 0 0 0
	view: objc_msgSend [view sel_getUid "initWithFrame:" rect/x rect/y rect/w rect/h]
	objc_msgSend [obj sel_getUid "setContentView:" view]
]

insert-list-item: func [
	hWnd  [integer!]
	item  [red-string!]
	pos	  [integer!]
	/local
		len [integer!]
][
	unless TYPE_OF(item) = TYPE_STRING [exit]

	len: objc_msgSend [hWnd sel_getUid "numberOfItems"]
	if pos > len [pos: len]
	objc_msgSend [
		hWnd sel_getUid "insertItemWithObjectValue:atIndex:"
		to-CFString item pos
	]
]

init-combo-box: func [
	combo		[integer!]
	data		[red-block!]
	caption		[integer!]
	selected	[red-integer!]
	drop-list?	[logic!]
	/local
		str	 [red-string!]
		tail [red-string!]
		len  [integer!]
		val  [integer!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data

		objc_msgSend [combo sel_getUid "removeAllItems"]

		if str = tail [exit]

		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [
				len: -1
				val: CFString((unicode/to-utf8 str :len))
				objc_msgSend [combo sel_getUid "addItemWithObjectValue:" val]
			]
			str: str + 1
		]
	]

	len: objc_msgSend [combo sel_getUid "numberOfItems"]

	if TYPE_OF(selected) = TYPE_INTEGER [
		if len > 0 [
			if selected/value < len [len: selected/value]
			objc_msgSend [combo sel_getUid "selectItemAtIndex:" len - 1]
			val: objc_msgSend [combo sel_getUid "objectValueOfSelectedItem"]
			objc_msgSend [combo sel_getUid "setObjectValue:" val]
		]
	]

	if zero? len [objc_msgSend [combo sel_getUid "setStringValue:" NSString("")]]

	either drop-list? [
		objc_msgSend [combo sel_getUid "setEditable:" false]
	][
		if caption <> 0 [
			objc_msgSend [combo sel_getUid "setStringValue:" caption]
		]
	]
]

init-window: func [
	window	[integer!]
	title	[integer!]
	bits	[integer!]
	rect	[NSRect!]
	/local
		flags		[integer!]
		sel_Hidden	[integer!]
][
	flags: 0
	if bits and FACET_FLAGS_NO_BORDER = 0 [
		flags: NSClosableWindowMask
		if bits and FACET_FLAGS_RESIZE <> 0 [flags: flags or NSResizableWindowMask]
		if bits and FACET_FLAGS_NO_TITLE = 0 [flags: flags or NSTitledWindowMask]
		if bits and FACET_FLAGS_NO_MIN  = 0 [flags: flags or NSMiniaturizableWindowMask]
	]
	window: objc_msgSend [
		window
		sel_getUid "initWithContentRect:styleMask:backing:defer:"
		rect/x rect/y rect/w rect/h flags 2 0
	]

	set-content-view window

	if bits and FACET_FLAGS_NO_BORDER = 0 [
		sel_Hidden: sel_getUid "setHidden:"
		if bits and FACET_FLAGS_NO_MAX  <> 0 [
			objc_msgSend [objc_msgSend [window sel_getUid "standardWindowButton:" 2] sel_Hidden yes]
		]
		if bits and FACET_FLAGS_NO_BTNS <> 0 [
			objc_msgSend [objc_msgSend [window sel_getUid "standardWindowButton:" 0] sel_Hidden yes]
			objc_msgSend [objc_msgSend [window sel_getUid "standardWindowButton:" 1] sel_Hidden yes]
			objc_msgSend [objc_msgSend [window sel_getUid "standardWindowButton:" 2] sel_Hidden yes]
		]
		if all [
			bits and FACET_FLAGS_NO_TITLE = 0
			title <> 0
		][objc_msgSend [window sel_getUid "setTitle:" title]]
	]

	if bits and FACET_FLAGS_POPUP  <> 0 [
		objc_msgSend [window sel_getUid "setLevel:" CGWindowLevelForKey 5]		;-- FloatingWindowLevel
	]

	objc_msgSend [window sel_getUid "setDelegate:" window]
	objc_msgSend [window sel_getUid "setAcceptsMouseMovedEvents:" yes]
	objc_msgSend [window sel_getUid "becomeFirstResponder"]
	objc_msgSend [window sel_getUid "makeKeyAndOrderFront:" 0]
	objc_msgSend [window sel_getUid "makeMainWindow"]
]

transparent-base?: func [
	color	[red-tuple!]
	return: [logic!]
][
	either all [
		TYPE_OF(color) = TYPE_TUPLE
		TUPLE_SIZE?(color) = 3
	][false][true]
]

init-base-face: func [
	face	[red-object!]
	hwnd	[integer!]
	menu	[red-block!]
	size	[red-pair!]
	values	[red-value!]
	bits	[integer!]
	/local
		color	[red-tuple!]
		opts	[red-block!]
		word	[red-word!]
		id		[integer!]
		obj		[integer!]
		sym		[integer!]
		len		[integer!]
		rc		[NSRect!]
][
	color: as red-tuple! values + FACE_OBJ_COLOR
	opts: as red-block! values + FACE_OBJ_OPTIONS

	either bits and FACET_FLAGS_SCROLLABLE <> 0 [
		rc: make-rect 0 0 size/x size/y
		id: objc_getClass "RedBase"
		obj: objc_msgSend [
			objc_msgSend [id sel_getUid "alloc"]
			sel_getUid "initWithFrame:" rc/x rc/y rc/w rc/h
		]
		store-face-to-obj obj id face

		objc_msgSend [obj sel_getUid "setAutoresizingMask:" NSViewWidthSizable or NSViewHeightSizable]
		objc_msgSend [hwnd sel_getUid "setHasVerticalScroller:" yes]
		objc_msgSend [hwnd sel_getUid "setHasHorizontalScroller:" yes]
		objc_msgSend [hwnd sel_getUid "setDocumentView:" obj]
	][
		obj: hwnd
	]

	object_setInstanceVariable obj IVAR_RED_DATA base					;-- set a flag as we handle keyboard event differently in base face

	if TYPE_OF(opts) = TYPE_BLOCK [
		word: as red-word! block/rs-head opts
		len: block/rs-length? opts
		if len % 2 <> 0 [exit]
		while [len > 0][
			sym: symbol/resolve word/symbol
			case [
				sym = caret [
					object_setInstanceVariable obj IVAR_RED_DATA caret	;-- overwrite extra RED_DATA
					change-offset obj as red-pair! values + FACE_OBJ_OFFSET base
				]
				true [0]
			]
			word: word + 2
			len: len - 2
		]
	]

	if TYPE_OF(menu) = TYPE_BLOCK [set-context-menu obj menu]
	if transparent-base? color [objc_msgSend [obj sel_getUid "setWantsLayer:" yes]]
]

make-area: func [
	face		[red-object!]
	container	[integer!]
	rc			[NSRect!]
	text		[integer!]
	border?		[logic!]
	/local
		id		[integer!]
		obj		[integer!]
		tbox	[integer!]
		x		[integer!]
][
	rc/x: as float32! 0.0
	rc/y: as float32! 0.0

	x: either border? [NSGrooveBorder][NSNoBorder]
	objc_msgSend [container sel_getUid "setBorderType:" x]
	objc_msgSend [container sel_getUid "setAutohidesScrollers:" yes]
	objc_msgSend [container sel_getUid "setHasVerticalScroller:" yes]
	;objc_msgSend [container sel_getUid "setHasHorizontalScroller:" yes]
	;objc_msgSend [container sel_getUid "setAutoresizingMask:" NSViewWidthSizable or NSViewHeightSizable]

	id: objc_getClass "RedTextView"
	obj: objc_msgSend [id sel_getUid "alloc"]

	assert obj <> 0
	obj: objc_msgSend [
		obj sel_getUid "initWithFrame:" rc/x rc/y rc/w rc/h
	]
	store-face-to-obj obj id face

	rc/y: as float32! 1e37			;-- FLT_MAX
	objc_msgSend [obj sel_getUid "setVerticallyResizable:" yes]
	objc_msgSend [obj sel_getUid "setHorizontallyResizable:" yes]
	objc_msgSend [obj sel_getUid "setMinSize:" rc/x rc/h]
	objc_msgSend [obj sel_getUid "setMaxSize:" rc/y rc/y]
	;objc_msgSend [obj sel_getUid "setAutoresizingMask:" NSViewWidthSizable]

	tbox: objc_msgSend [obj sel_getUid "textContainer"]
	objc_msgSend [tbox sel_getUid "setContainerSize:" rc/w rc/y]

	if text <> 0 [objc_msgSend [obj sel_getUid "setString:" text]]

	objc_msgSend [obj sel_getUid "setAllowsUndo:" yes]
	objc_msgSend [obj sel_getUid "setDelegate:" obj]
	objc_msgSend [container sel_getUid "setDocumentView:" obj]
]

make-text-list: func [
	face		[red-object!]
	container	[integer!]
	rc			[NSRect!]
	/local
		id		[integer!]
		obj		[integer!]
		column	[integer!]
][
	rc/x: as float32! 0.0
	rc/y: as float32! 0.0
	rc/w: rc/w - 16.0

	id: CFString("RedCol1")
	column: objc_msgSend [objc_getClass "NSTableColumn" sel_getUid "alloc"]
	column: objc_msgSend [column sel_getUid "initWithIdentifier:" id]
	;CFRelease id
	objc_msgSend [column sel_getUid "setWidth:" rc/w]

	objc_msgSend [container sel_getUid "setAutohidesScrollers:" yes]
	;objc_msgSend [container sel_getUid "setHasHorizontalScroller:" yes]
	objc_msgSend [container sel_getUid "setHasVerticalScroller:" yes]
	;objc_msgSend [container sel_getUid "setAutoresizingMask:" NSViewWidthSizable or NSViewHeightSizable]

	id: objc_getClass "RedTableView"
	obj: objc_msgSend [id sel_getUid "alloc"]

	assert obj <> 0
	obj: objc_msgSend [
		obj sel_getUid "initWithFrame:" rc/x rc/y rc/w rc/h
	]
	store-face-to-obj obj id face

	objc_msgSend [obj sel_getUid "setHeaderView:" 0]
	objc_msgSend [obj sel_getUid "addTableColumn:" column]
	objc_msgSend [obj sel_getUid "setDelegate:" obj]
	objc_msgSend [obj sel_getUid "setDataSource:" obj]
	objc_msgSend [obj sel_getUid "reloadData"]

	objc_msgSend [container sel_getUid "setDocumentView:" obj]
	objc_msgSend [obj sel_getUid "release"]
	objc_msgSend [column sel_getUid "release"]
]

update-combo-box: func [
	face  [red-object!]
	value [red-value!]
	sym   [integer!]
	new	  [red-value!]
	index [integer!]
	part  [integer!]
	drop? [logic!]										;-- TRUE: drop-list or drop-down widgets
	/local
		hWnd [integer!]
		msg  [integer!]
		str  [red-string!]
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
						objc_msgSend [hWnd sel_getUid "removeAllItems"]
						objc_msgSend [hWnd sel_getUid "setStringValue:" NSString("")]
					][
						loop part [
							objc_msgSend [hWnd sel_getUid "removeItemAtIndex:" index]
						]
					]
				]
				any [
					sym = words/_insert/symbol
					sym = words/_poke/symbol
					sym = words/_put/symbol
					sym = words/_reverse/symbol
				][
					;ownership/unbind-each as red-block! value index part

					str: as red-string! either any [
						null? new
						TYPE_OF(new) = TYPE_BLOCK
					][
						block/rs-abs-at as red-block! value index
					][
						new
					]
					loop part [
						if sym <> words/_insert/symbol [
							objc_msgSend [hWnd sel_getUid "removeItemAtIndex:" index]
						]
						insert-list-item hWnd str index
						if sym = words/_reverse/symbol [index: index + 1]
						str: str + 1
					]
				]
				true [0]
			]
		]
		TYPE_STRING [
			objc_msgSend [hWnd sel_getUid "removeItemAtIndex:" index]
			insert-list-item hWnd as red-string! value index
		]
		default [assert false]			;@@ raise a runtime error
	]
]

update-scroller: func [
	scroller [red-object!]
	flag	 [integer!]
	/local
		parent		[red-object!]
		vertical?	[red-logic!]
		int			[red-integer!]
		values		[red-value!]
		container	[integer!]
		bar			[integer!]
		range		[integer!]
		sel			[integer!]
		pos			[integer!]
		page		[integer!]
		min			[integer!]
		max			[integer!]
		n			[integer!]
		frac		[float!]
		old-frac	[float!]
		knob		[float32!]
		pf32		[pointer! [float32!]]
		old-knob	[float32!]
][
	values: object/get-values scroller
	parent: as red-object! values + SCROLLER_OBJ_PARENT
	vertical?: as red-logic! values + SCROLLER_OBJ_VERTICAL?
	int: as red-integer! block/rs-head as red-block! (object/get-values parent) + FACE_OBJ_STATE
	container: int/value

	if flag = SCROLLER_OBJ_VISIBLE? [
		int: as red-integer! values + SCROLLER_OBJ_VISIBLE?
		sel: either vertical?/value [sel_getUid "setHasVerticalScroller:"][sel_getUid "setHasHorizontalScroller:"]
		objc_msgSend [container sel int/value]
		exit
	]

	sel: either vertical?/value [sel_getUid "verticalScroller"][sel_getUid "horizontalScroller"]
	bar: objc_msgSend [container sel]

	int: as red-integer! values + SCROLLER_OBJ_POS
	pos: int/value
	int: as red-integer! values + SCROLLER_OBJ_PAGE
	page: int/value
	int: as red-integer! values + SCROLLER_OBJ_MIN
	min: int/value
	int: as red-integer! values + SCROLLER_OBJ_MAX
	max: int/value

	n: objc_getAssociatedObject bar RedAttachedWidgetKey
	if any [
		zero? n
		values <> as red-value! objc_msgSend [n sel_getUid "unsignedIntValue"]
	][
		n: objc_msgSend [
			objc_getClass "NSNumber" sel_getUid "numberWithUnsignedInt:"
			values
		]
		objc_setAssociatedObject bar RedAttachedWidgetKey n OBJC_ASSOCIATION_ASSIGN
	]

	n: max - page
	if pos < n [n: pos]
	if pos < min [pos: min]
	range: max - min - page + 2
	frac: either range <= 0 [as float! 1.0][
		(as float! pos - min) / as float! range
	]

	sel: max - min
	knob: either range <= 0 [as float32! 1.0][
		(as float32! page) / as float32! sel
	]

	old-frac: objc_msgSend_fpret [bar sel_getUid "doubleValue"]
	old-knob: objc_msgSend_f32 [bar sel_getUid "knobProportion"]

	pf32: as pointer! [float32!] :sel
	pf32/value: knob
	objc_msgSend [bar sel_getUid "setDoubleValue:" frac]
	objc_msgSend [bar sel_getUid "setKnobProportion:" pf32/value]
	objc_msgSend [bar sel_getUid "setEnabled:" true]
	if any [
		knob <> old-knob
		frac <> old-frac
	][
		objc_msgSend [container sel_getUid "flashScrollers"]
	]
]

set-hint-text: func [
	hWnd		[integer!]
	options		[red-block!]
	/local
		text	[red-string!]
][
	if TYPE_OF(options) <> TYPE_BLOCK [exit]
	text: as red-string! block/select-word options word/load "hint" no
	if TYPE_OF(text) = TYPE_STRING [
		objc_msgSend [hWnd sel_getUid "setPlaceholderString:" to-NSString text]
	]
]

OS-redraw: func [hWnd [integer!]][objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]]

OS-refresh-window: func [hWnd [integer!]][0]

OS-show-window: func [
	hWnd [integer!]
][
	make-event hWnd 0 EVT_SIZE
]

OS-make-view: func [
	face	[red-object!]
	parent	[integer!]
	return: [integer!]
	/local
		values	  [red-value!]
		type	  [red-word!]
		str		  [red-string!]
		tail	  [red-string!]
		offset	  [red-pair!]
		size	  [red-pair!]
		data	  [red-block!]
		int		  [red-integer!]
		img		  [red-image!]
		menu	  [red-block!]
		show?	  [red-logic!]
		open?	  [red-logic!]
		selected  [red-integer!]
		para	  [red-object!]
		rate	  [red-value!]
		flags	  [integer!]
		bits	  [integer!]
		sym		  [integer!]
		id		  [integer!]
		class	  [c-string!]
		caption   [integer!]
		len		  [integer!]
		obj		  [integer!]
		rc		  [NSRect!]
		flt		  [float!]
][
	stack/mark-func words/_body

	values: object/get-values face

	type:	  as red-word!		values + FACE_OBJ_TYPE
	str:	  as red-string!	values + FACE_OBJ_TEXT
	offset:   as red-pair!		values + FACE_OBJ_OFFSET
	size:	  as red-pair!		values + FACE_OBJ_SIZE
	show?:	  as red-logic!		values + FACE_OBJ_VISIBLE?
	open?:	  as red-logic!		values + FACE_OBJ_ENABLE?
	data:	  as red-block!		values + FACE_OBJ_DATA
	img:	  as red-image!		values + FACE_OBJ_IMAGE
	menu:	  as red-block!		values + FACE_OBJ_MENU
	selected: as red-integer!	values + FACE_OBJ_SELECTED
	para:	  as red-object!	values + FACE_OBJ_PARA
	rate:						values + FACE_OBJ_RATE

	bits: 	  get-flags as red-block! values + FACE_OBJ_FLAGS
	sym: 	  symbol/resolve type/symbol

	case [
		any [
			sym = text-list
			sym = area
		][class: "RedScrollView"]
		sym = text [class: "RedTextField"]
		sym = field [class: "RedTextField"]
		sym = button [
			class: "RedButton"
		]
		sym = check [
			class: "RedButton"
			flags: NSSwitchButton
		]
		sym = radio [
			class: "RedButton"
			flags: NSRadioButton
		]
		sym = window [class: "RedWindow"]
		sym = tab-panel [
			class: "RedTabView"
		]
		any [
			sym = panel
			sym = base
		][
			class: either bits and FACET_FLAGS_SCROLLABLE = 0 ["RedBase"]["RedScrollBase"]
		]
		any [
			sym = drop-down
			sym = drop-list
		][
			class: "RedComboBox"
			size/y: 26									;@@ set to default height
		]
		sym = slider [class: "RedSlider"]
		sym = progress [class: "RedProgress"]
		sym = group-box [
			class: "RedBox"
		]
		sym = camera [class: "RedCamera"]
		true [											;-- search in user-defined classes
			fire [TO_ERROR(script face-type) type]
		]
	]

	id: objc_getClass class
	obj: objc_msgSend [id sel_getUid "alloc"]
	if zero? obj [print-line "*** Error: Create Window failed!"]

	;-- store the face value in the extra space of the window struct
	assert TYPE_OF(face) = TYPE_OBJECT					;-- detect corruptions caused by CreateWindow unwanted events
	store-face-to-obj obj id face

	;-- extra initialization
	caption: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		CFString((unicode/to-utf8 str :len))
	][
		0
	]
	rc: make-rect offset/x offset/y size/x size/y
	if sym <> window [
		obj: objc_msgSend [obj sel_getUid "initWithFrame:" rc/x rc/y rc/w rc/h]
	]

	case [
		sym = text [
			objc_msgSend [obj sel_getUid "setEditable:" false]
			objc_msgSend [obj sel_getUid "setBordered:" false]
			objc_msgSend [obj sel_getUid "setDrawsBackground:" false]
			if caption <> 0 [objc_msgSend [obj sel_getUid "setStringValue:" caption]]
		]
		sym = field [
			if bits and FACET_FLAGS_NO_BORDER <> 0 [
				objc_msgSend [obj sel_getUid "setBordered:" false]
			]
			id: objc_msgSend [obj sel_getUid "cell"]
			objc_msgSend [id sel_getUid "setWraps:" no]
			objc_msgSend [id sel_getUid "setScrollable:" yes]
			if caption <> 0 [objc_msgSend [obj sel_getUid "setStringValue:" caption]]
			set-hint-text obj as red-block! values + FACE_OBJ_OPTIONS
		]
		sym = area [
			make-area face obj rc caption bits and FACET_FLAGS_NO_BORDER = 0
		]
		sym = text-list [
			make-text-list face obj rc
		]
		any [sym = button sym = check sym = radio][
			len: either any [
				size/y > 32
				TYPE_OF(img) = TYPE_IMAGE
			][
				NSRegularSquareBezelStyle
			][
				NSRoundedBezelStyle
			]
			objc_msgSend [obj sel_getUid "setBezelStyle:" len]
			if sym <> button [
				objc_msgSend [obj sel_getUid "setButtonType:" flags]
				set-logic-state obj as red-logic! data no
			]
			if TYPE_OF(img) = TYPE_IMAGE [
				change-image obj img sym
			]
			if caption <> 0 [objc_msgSend [obj sel_getUid "setTitle:" caption]]
			;objc_msgSend [obj sel_getUid "setTarget:" obj]
			;objc_msgSend [obj sel_getUid "setAction:" sel_getUid "button-click:"]
		]
		any [
			sym = panel
			sym = base
		][
			init-base-face face obj menu size values bits
		]
		sym = tab-panel [
			set-tabs obj values
			objc_msgSend [obj sel_getUid "setDelegate:" obj]
		]
		sym = window [
			rc: make-rect offset/x screen-size-y - offset/y - size/y size/x size/y
			init-window obj caption bits rc
			win-cnt: win-cnt + 1

			if all [						;@@ application menu ?
				zero? AppMainMenu
				menu-bar? menu window
			][
				AppMainMenu: objc_msgSend [NSApp sel_getUid "mainMenu"]
				build-menu menu AppMainMenu obj
			]
		]
		sym = slider [
			len: either size/x > size/y [size/x][size/y]
			flt: as-float len
			objc_msgSend [obj sel_getUid "setMaxValue:" flt]
			flt: get-position-value as red-float! data flt
			objc_msgSend [obj sel_getUid "setDoubleValue:" flt]
			objc_msgSend [obj sel_getUid "setTarget:" obj]
			objc_msgSend [obj sel_getUid "setAction:" sel_getUid "slider-change:"]
		]
		sym = progress [
			objc_msgSend [obj sel_getUid "setIndeterminate:" false]
			if size/y > size/x [
				rc/x: as float32! -90.0
				objc_msgSend [obj sel_getUid "setBoundsRotation:" rc/x]
			]
			flt: get-position-value as red-float! data 100.0
			objc_msgSend [obj sel_getUid "setDoubleValue:" flt]
		]
		sym = group-box [
			set-content-view obj
			either zero? caption [
				objc_msgSend [obj sel_getUid "setTitlePosition:" NSNoTitle]
			][
				objc_msgSend [obj sel_getUid "setTitle:" caption]
			]
		]
		any [
			sym = drop-down
			sym = drop-list
		][
			init-combo-box obj data caption selected sym = drop-list
			objc_msgSend [obj sel_getUid "setDelegate:" obj]
		]
		sym = camera [
			init-camera obj rc data
		]
		true [0]
	]

	unless show?/value [change-visible obj no sym]

	change-font obj face as red-object! values + FACE_OBJ_FONT sym
	if TYPE_OF(rate) <> TYPE_NONE [change-rate obj rate]
	if sym <> base [change-color obj as red-tuple! values + FACE_OBJ_COLOR sym]

	if parent <> 0 [
		objc_msgSend [parent sel_getUid "addSubview:" obj]	;-- `addSubView:` will retain the obj
		objc_msgSend [obj sel_getUid "release"]
	]

	if caption <> 0 [CFRelease caption]
	;if all [sym <> area sym <> field sym <> drop-down][
	;	setup-tracking-area obj face rc bits
	;]

	stack/unwind
	obj
]

OS-update-view: func [
	face [red-object!]
	/local
		ctx		[red-context!]
		values	[red-value!]
		state	[red-block!]
		menu	[red-block!]
		word	[red-word!]
		int		[red-integer!]
		bool	[red-logic!]
		s		[series!]
		hWnd	[integer!]
		flags	[integer!]
		type	[integer!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	values: s/offset

	state: as red-block! values + FACE_OBJ_STATE
	word: as red-word! values + FACE_OBJ_TYPE
	type: symbol/resolve word/symbol
	s: GET_BUFFER(state)
	int: as red-integer! s/offset
	hWnd: int/value
	int: int + 1
	flags: int/value

	if flags and FACET_FLAG_OFFSET <> 0 [
		change-offset hWnd as red-pair! values + FACE_OBJ_OFFSET type
	]
	if flags and FACET_FLAG_SIZE <> 0 [
		change-size hWnd as red-pair! values + FACE_OBJ_SIZE type
	]
	if flags and FACET_FLAG_TEXT <> 0 [
		change-text hWnd values face type
	]
	if flags and FACET_FLAG_DATA <> 0 [
		change-data hWnd values
	]
	if flags and FACET_FLAG_ENABLE? <> 0 [
		bool: as red-logic! values + FACE_OBJ_ENABLE?
		if type <> window [
			objc_msgSend [hWnd sel_getUid "setEnabled:" bool/value]
		]
	]
	if flags and FACET_FLAG_VISIBLE? <> 0 [
		bool: as red-logic! values + FACE_OBJ_VISIBLE?
		change-visible hWnd bool/value type
	]
	if flags and FACET_FLAG_SELECTED <> 0 [
		change-selection hWnd as red-integer! values + FACE_OBJ_SELECTED type
	]
	;if flags and FACET_FLAG_FLAGS <> 0 [
	;	get-flags as red-block! values + FACE_OBJ_FLAGS
	;]
	if flags and FACET_FLAG_DRAW  <> 0 [
		objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
	]
	if flags and FACET_FLAG_COLOR <> 0 [
		change-color hWnd as red-tuple! values + FACE_OBJ_COLOR type
	]
	if all [flags and FACET_FLAG_PANE <> 0 type <> tab-panel][
		update-z-order hWnd as red-block! values + FACE_OBJ_PANE type
	]
	if flags and FACET_FLAG_RATE <> 0 [
		change-rate hWnd values + FACE_OBJ_RATE
	]
	if flags and FACET_FLAG_FONT <> 0 [
		change-font hWnd face as red-object! values + FACE_OBJ_FONT type
	]
	;if flags and FACET_FLAG_PARA <> 0 [
	;	update-para face 0
	;]
	if flags and FACET_FLAG_MENU <> 0 [
		menu: as red-block! values + FACE_OBJ_MENU
		if menu-bar? menu window [
			AppMainMenu: objc_msgSend [NSApp sel_getUid "mainMenu"]
			;objc_msgSend [AppMainMenu sel_getUid "removeAllItems"]
			;build-menu menu AppMainMenu hWnd
		]
	]
	if flags and FACET_FLAG_IMAGE <> 0 [
		change-image hWnd as red-image! values + FACE_OBJ_IMAGE type
	]

	int/value: 0										;-- reset flags
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
		if TYPE_OF(res) <> TYPE_NONE [_series/remove as red-series! res null]
		if all [
			field = FONT_OBJ_PARENT
			block/rs-tail? parent
		][
			free-font obj
		]
	]
]

OS-destroy-view: func [
	face	[red-object!]
	window? [logic!]
	/local
		handle [integer!]
		values [red-value!]
		obj	   [red-object!]
		flags  [integer!]
][
	handle: get-face-handle face
	values: object/get-values face
	flags: get-flags as red-block! values + FACE_OBJ_FLAGS
	if flags and FACET_FLAGS_MODAL <> 0 [
		0
		;;TBD
	]

	obj: as red-object! values + FACE_OBJ_FONT
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj FONT_OBJ_PARENT]

	obj: as red-object! values + FACE_OBJ_PARA
	if TYPE_OF(obj) = TYPE_OBJECT [unlink-sub-obj face obj PARA_OBJ_PARENT]

	free-handles handle no
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
		word [red-word!]
		sym	 [integer!]
		type [integer!]
		hWnd [handle!]
][
	sym: symbol/resolve facet/symbol

	case [
		sym = facets/pane [0]
		sym = facets/data [
			word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
			type: symbol/resolve word/symbol
			sym: action/symbol
			case [
				any [
					type = drop-list
					type = drop-down
				][
					if any [
						index and 1 = 1
						part  and 1 = 1
					][
						fire [TO_ERROR(script invalid-data-facet) value]
					]
					index: index / 2
					part:   part / 2
					if zero? part [exit]

					update-combo-box face value sym new index part yes
				]
				type = tab-panel [
					update-tabs face value sym new index part
				]
				true [OS-update-view face]
			]
		]
		true [OS-update-view face]
	]
]

OS-to-image: func [
	face	[red-object!]
	return: [red-image!]
	/local
		hWnd 	[handle!]
		dc		[handle!]
		mdc		[handle!]
		rect	[RECT_STRUCT]
		width	[integer!]
		height	[integer!]
		bmp		[handle!]
		bitmap	[integer!]
		img		[red-image!]
		word	[red-word!]
		type	[integer!]
		size	[red-pair!]
		screen? [logic!]
][
	as red-image! none-value
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
	/local
		rc	[NSRect!]
][
	rc: make-rect IMAGE_WIDTH(img/size) IMAGE_HEIGHT(img/size) 0 0
	do-draw img/node as red-image! rc cmds yes yes yes yes
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