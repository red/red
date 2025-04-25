Red/System [
	Title:	"macOS GUI backend"
	Author: "Qingtian Xie"
	File: 	%gui.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

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
nsview-id:		0

;-- for IME support
in-composition?: no
ime-str-styles: as red-block! 0
caret-w:		as float32! 0.0
caret-h:		as float32! 0.0
caret-x:		as float32! 0.0
caret-y:		as float32! 0.0

win-array:		declare red-vector!
active-wins:	declare red-vector!			;-- last actives windows

red-face?: func [
	handle	[integer!]
	return: [logic!]
	/local
		id  [integer!]
][
	id: 0
	object_getInstanceVariable handle IVAR_RED_FACE :id
	id <> 0
]

get-face-values: func [
	handle	[integer!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		s	 [series!]
		id	 [integer!]
		face [red-object!]
][
	id: 0
	object_getInstanceVariable handle IVAR_RED_FACE :id
	face: as red-object! references/get id
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

get-face-obj: func [
	view	[integer!]
	return: [red-object!]
	/local
		id  [integer!]
][
	id: 0
	object_getInstanceVariable view IVAR_RED_FACE :id
	assert id <> 0
	as red-object! references/get id
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

get-ratio: func [face [red-object!] return: [red-float!]][
	as red-float! object/rs-select face as red-value! _ratio
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
	face 	[red-object!]		; TODO: implement face-dependent measurement for Mac
	str		[red-string!]
	pt		[red-point2D!]
	return: [tagSIZE]
	/local
		values	[red-value!]
		font	[red-object!]
		state	[red-block!]
		hFont	[handle!]
		attrs	[integer!]
		cf-str	[integer!]
		attr	[integer!]
		y		[integer!]
		x		[integer!]
		rc		[NSRect!]
		size	[tagSIZE]
][
	values: object/get-values face
	font: as red-object! values + FACE_OBJ_FONT
	hFont: null
	if TYPE_OF(font) = TYPE_OBJECT [
		state: as red-block! values + FONT_OBJ_STATE
		if TYPE_OF(state) <> TYPE_BLOCK [hFont: get-font-handle font 0]
		if null? hFont [hFont: make-font face font]
	]

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

	size/width: as-integer ceil as-float rc/x
	size/height: as-integer ceil as-float rc/y
	if pt <> null [
		pt/x: rc/x
		pt/y: rc/y
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
		post-quit-msg
	][
		unless close-window? [objc_msgSend [hWnd sel_getUid "removeFromSuperview"]]
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

set-defaults: func [/local n [float32!]][
	default-font: objc_msgSend [
		objc_getClass "NSFont" sel_getUid "systemFontOfSize:" 0
	]
	objc_msgSend [default-font sel_getUid "retain"]

	to-red-string
		objc_msgSend [default-font sel_getUid "familyName"]
		#get system/view/fonts/system

	n: objc_msgSend_f32 [default-font sel_getUid "pointSize"]
	n: n * as float32! 0.75
	n: n + as float32! 0.5
	integer/make-at
		#get system/view/fonts/size
		as-integer n
]

get-metrics: func [][
	copy-cell 
		as red-value! integer/push log-pixels-x
		#get system/view/metrics/dpi
]

on-gc-mark: does [
	collector/keep :flags-blk/node
	collector/keep :win-array/node
	collector/keep :active-wins/node
]

support-dark-mode?: func [
	return: [logic!]
][
	false
]

set-dark-mode: func [
	hWnd		[integer!]
	dark?		[logic!]
	top-level?	[logic!]
][
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
	vector/make-at as red-value! active-wins 8 TYPE_INTEGER 4
	init-selectors
	register-classes
	nsview-id: objc_getClass "NSView"

	NSApp: objc_msgSend [objc_getClass "RedApplication" sel_getUid "sharedApplication"]
	pool: objc_msgSend [objc_getClass "NSAutoreleasePool" sel_getUid "alloc"]
	objc_msgSend [pool sel_getUid "init"]

	delegate: objc_msgSend [objc_getClass "RedAppDelegate" sel_getUid "alloc"]
	delegate: objc_msgSend [delegate sel_getUid "init"]
	NSAppDelegate: delegate
	objc_msgSend [NSApp sel_getUid "setDelegate:" delegate]

	get-os-version
	#if type = 'exe [create-main-menu]

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

	get-metrics
	
	collector/register as int-ptr! :on-gc-mark
]

set-logic-state: func [
	handle [integer!]
	state  [red-logic!]
	check? [logic!]
	/local
		values [red-block!]
		flags  [integer!]
		type   [integer!]
		value  [integer!]
		tri?   [logic!]
][
	if check? [
		values: as red-block! get-face-values handle
		flags: get-flags as red-block! values + FACE_OBJ_FLAGS
		tri?: flags and FACET_FLAGS_TRISTATE <> 0
	]
	
	type: TYPE_OF(state)
	value: either all [check? tri? type = TYPE_NONE][NSMixedState][
		as integer! switch type [
			TYPE_NONE  [false]
			TYPE_LOGIC [state/value]					;-- returns 0/1, matches the state flag
			default	   [true]
		]
	]

	objc_msgSend [handle sel_getUid "setState:" value]
]

get-logic-state: func [
	handle [integer!]
	/local
		bool  [red-logic!]
		state [integer!]
][
	bool: as red-logic! (get-face-values handle) + FACE_OBJ_DATA
	state: objc_msgSend [handle sel_getUid "state"]
	
	either state = NSMixedState [
		bool/header: TYPE_NONE
	][
		bool/header: TYPE_LOGIC
		bool/value: state = NSOnState
	]
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
	face	[red-object!]
	/local
		id	 [integer!]
][
	id: references/store as red-value! face
	object_setInstanceVariable obj IVAR_RED_FACE id
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
			ts: tm/time
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
		rc		[NSRect!]
		frame	[NSRect! value]
		h		[float32!]
		pt		[red-point2D!]
		sx sy	[float32!]
][
	rc: make-rect 1 1 0 0
	GET_PAIR_XY(size rc/x rc/y)
	SET_PAIR_SIZE_FLAG(hWnd size)

	if all [any [type = button type = toggle] rc/y > as float32! 32.0][
		objc_msgSend [hWnd sel_getUid "setBezelStyle:" NSRegularSquareBezelStyle]
	]
	either type = window [
		frame: objc_msgSend_rect [hWnd sel_getUid "frame"]
		h: frame/h
		frame/w: rc/x
		frame/h: rc/y
		frame: objc_msgSend_rect [hWnd sel_getUid "frameRectForContentRect:" frame/x frame/y frame/w frame/h]
		frame/y: frame/y + h - frame/h
		objc_msgSend [hWnd sel_getUid "setFrame:display:animate:" frame/x frame/y frame/w frame/h yes yes]
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
		id		 [integer!]
][
	case [
		any [type = button type = toggle type = check type = radio][
			if TYPE_OF(image) <> TYPE_IMAGE [
				objc_msgSend [hWnd sel_getUid "setImage:" 0]
				exit
			]
			id: objc_msgSend [objc_getClass "NSImage" sel_getUid "alloc"]
			id: objc_msgSend [id sel_getUid "initWithCGImage:size:" OS-image/to-cgimage image 0 0]
			objc_msgSend [hWnd sel_getUid "setImage:" id]
			objc_msgSend [id sel_getUid "release"]
		]
		type = camera [snap-camera hWnd]
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
		t	 [integer!]
][
	t: TYPE_OF(color)
	if all [t <> TYPE_NONE t <> TYPE_TUPLE][exit]
	set?: yes
	case [
		type = area [
			hWnd: objc_msgSend [hWnd sel_getUid "documentView"]
			clr: either t = TYPE_NONE [00FFFFFFh][get-tuple-color color]
			set-caret-color hWnd clr
			if t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "textBackgroundColor"]]
		]
		type = text [
			if t = TYPE_NONE [set?: no]
			objc_msgSend [hWnd sel_getUid "setDrawsBackground:" set?]
		]
		any [type = check type = radio][
			hWnd: objc_msgSend [hWnd sel_getUid "cell"]
			if t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "controlColor"]]
		]
		type = field [
			if t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "textBackgroundColor"]]
		]
		type = window [
			either t = TYPE_NONE [clr: objc_msgSend [objc_getClass "NSColor" sel_getUid "windowBackgroundColor"]][
				if TUPLE_SIZE?(color) = 4 [
					color/array1: color/array1 and 00FFFFFFh		;-- No transparency, compitable with Windows
					;objc_msgSend [hWnd sel_getUid "setOpaque:" no]
				]
			]
		]
		true [
			set?: no
			objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
		]
	]
	if set? [
		if t = TYPE_TUPLE [clr: to-NSColor color]
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
	if any [type = window type = group-box] [parent: objc_msgSend [parent sel_getUid "contentView"]]
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
		nsfont	[integer!]
		lm		[integer!]
		pt		[CGPoint! value]
][
	if TYPE_OF(font) <> TYPE_OBJECT [return no]

	attrs: make-font-attrs font face type
	;objc_msgSend [attrs sel_getUid "autorelease"]

	either type = area [
		view: objc_msgSend [hWnd sel_getUid "documentView"]
		storage: objc_msgSend [view sel_getUid "textStorage"]
		objc_msgSend [
			storage sel_getUid "setAttributes:range:"
			attrs 0 objc_msgSend [storage sel_length]
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
		if type = text-list [
			nsfont: objc_msgSend [attrs sel_getUid "objectForKey:" NSFontAttributeName]
			lm: objc_msgSend [objc_msgSend [objc_getClass "NSLayoutManager" sel_alloc] sel_init]
			pt/x: (as float32! 1.0) + objc_msgSend_f32 [lm sel_getUid "defaultLineHeightForFont:" nsfont]
			objc_msgSend [lm sel_release]
			view: objc_msgSend [hWnd sel_getUid "documentView"]
			objc_msgSend [view sel_getUid "setRowHeight:" pt/x]
		]
		values: (object/get-values face) + FACE_OBJ_TEXT
		if TYPE_OF(values) <> TYPE_STRING [return no]			;-- accept any-string! ?

		title: to-NSString as red-string! values
		str: objc_msgSend [
			objc_msgSend [objc_getClass "NSAttributedString" sel_getUid "alloc"]
			sel_getUid "initWithString:attributes:" title attrs
		]
		case [
			any [type = button type = toggle type = check type = radio][
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
		pt [red-point2D!]
][
	rc: make-rect 1 1 0 0
	GET_PAIR_XY(pos rc/x rc/y)
	either type = window [
		rc/y: (as float32! screen-size-y) - rc/y
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
		any [type = button type = toggle type = check type = radio][
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

change-enabled: func [
	hWnd	 [integer!]
	enabled? [logic!]
	type	 [integer!]
	/local
		obj  [integer!]
][
	case [
		type = area [
			obj: objc_msgSend [hWnd sel_getUid "documentView"]
			objc_msgSend [obj sel_getUid "setSelectable:" enabled?]
			objc_msgSend [obj sel_getUid "setEditable:" enabled?]
			either enabled? [
				objc_msgSend [
					obj sel_getUid "setTextColor:"
					objc_msgSend [objc_getClass "NSColor" sel_getUid "controlTextColor"]
				]
			][
				objc_msgSend [
					obj sel_getUid "setTextColor:"
					objc_msgSend [objc_getClass "NSColor" sel_getUid "disabledControlTextColor"]
				]
			]
		]
		all [type <> base type <> window type <> panel][
			objc_msgSend [hWnd sel_getUid "setEnabled:" enabled?]
		]
		true [0]
	]
	either enabled? [obj: 0][obj: hWnd]
	objc_setAssociatedObject hWnd RedEnableKey obj OBJC_ASSOCIATION_ASSIGN
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
				any [type = button type = toggle type = radio type = check type = window type = group-box][
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
		font	[red-object!]
		ivar	[integer!]
		nsstr	[integer!]
		attr	[integer!]
		max-w	[float32!]
		view	[integer!]
		sz		[NSSize! value]
		rc		[NSRect!]
		face	[red-object!]
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
		any [
			type = check
			type = toggle
			type = radio
		][
			set-logic-state hWnd as red-logic! data type = check
		]
		type = tab-panel [
			set-tabs hWnd values
		]
		all [
			type = text-list
			TYPE_OF(data) = TYPE_BLOCK
		][
			len: block/rs-length? as red-block! data
			data: block/rs-head as red-block! data
			font: as red-object! values + FACE_OBJ_FONT
			ivar: 0
			object_getInstanceVariable hWnd IVAR_RED_FACE :ivar
			face: as red-object! references/get ivar
			either TYPE_OF(font) = TYPE_OBJECT [
				attr: make-font-attrs font face text-list
			][
				attr: objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
				attr: objc_msgSend [
					attr sel_getUid "initWithObjectsAndKeys:"
					default-font NSFontAttributeName
					0
				]
			]
			max-w: as float32! 2.0
			loop len [
				if TYPE_OF(data) <> TYPE_STRING [continue]
				nsstr: to-NSString as red-string! data
				sz: objc_msgSend_sz [nsstr sel_getUid "sizeWithAttributes:" attr]
				if sz/w > max-w [max-w: sz/w]
				data: data + 1
			]
			objc_msgSend [attr sel_release]
			size: as red-pair! values + FACE_OBJ_SIZE
			view: objc_msgSend [hWnd sel_getUid "documentView"]
			sz: objc_msgSend_sz [view sel_getUid "frameSize"]
			rc: make-rect 0 0 as-integer sz/w size/y
			either max-w > rc/w [
				rc/w: max-w + as float32! 16.0
				make-text-list
					face
					hWnd
					rc
					as red-block! values + FACE_OBJ_MENU
					NSNoBorder <> objc_msgSend [hWnd sel_getUid "borderType"]
			][
				objc_msgSend [view sel_getUid "reloadData"]
			]
		]
		any [type = drop-list type = drop-down][
			init-combo-box hWnd as red-block! data null type = drop-list
		]
		type = rich-text [
			objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
		]
		all [type = calendar TYPE_OF(data) = TYPE_DATE][
			objc_msgSend [hWnd sel_getUid "setDateValue:" to-NSDate as red-date! data]
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
		sel [red-pair!]
		win [integer!]
][
	if type <> window [
		idx: either TYPE_OF(int) = TYPE_INTEGER [int/value - 1][-1]
	]
	case [
		any [type = field type = area][
			sel: as red-pair! int
			either TYPE_OF(sel) = TYPE_NONE [
				idx: 0
				sz:  0
			][
				idx: sel/x - 1
				sz: sel/y - idx						;-- should point past the last selected char
			]
			either type = field [
				win: objc_msgSend [NSApp sel_getUid "mainWindow"]
				objc_msgSend [win sel_getUid "makeFirstResponder:" hWnd]
				wnd: objc_msgSend [hWnd sel_getUid "currentEditor"]
			][
				wnd: objc_msgSend [hWnd sel_getUid "documentView"]
			]
			objc_msgSend [wnd sel_getUid "setSelectedRange:" idx sz]
		]
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
			if idx = -1 [
				objc_msgSend [hWnd sel_getUid "deselectAll:" hWnd]
				exit
			]
			sz: -1 + objc_msgSend [hWnd sel_getUid "numberOfRows"]
			if any [sz < 0 sz < idx][exit]
			idx: objc_msgSend [objc_getClass "NSIndexSet" sel_getUid "indexSetWithIndex:" idx]
			objc_msgSend [
				hWnd sel_getUid "selectRowIndexes:byExtendingSelection:" idx no
			]
		]
		any [type = drop-list type = drop-down][
			sz: -1 + objc_msgSend [hWnd sel_getUid "numberOfItems"]
			if all [idx = -1 type = drop-down][		;-- deselect current item
				idx: objc_msgSend [hWnd sel_getUid "indexOfSelectedItem"]
				if idx <> -1 [
					objc_msgSend [hWnd sel_getUid "deselectItemAtIndex:" idx]
				]
				exit
			]
			if any [sz < 0 sz < idx][exit]
			either type = drop-list [
				objc_msgSend [hWnd sel_getUid "selectItemAtIndex:" idx + 1]
				idx: objc_msgSend [hWnd sel_getUid "titleOfSelectedItem"]
				objc_msgSend [hWnd sel_getUid "setTitle:" idx]
			][
				objc_msgSend [hWnd sel_getUid "selectItemAtIndex:" idx]
				idx: objc_msgSend [hWnd sel_getUid "objectValueOfSelectedItem"]
				objc_msgSend [hWnd sel_getUid "setObjectValue:" idx]
			]
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

same-type?: func [
	obj		[integer!]
	name	[c-string!]
	return: [logic!]
][
	(object_getClass obj) = objc_getClass name
]

set-content-view: func [
	obj		[integer!]
	face	[red-object!]
	/local
		rect [NSRect!]
		view [integer!]
		cls  [c-string!]
		id	 [integer!]
][
	cls: either null? face ["NSViewFlip"]["RedView"]
	id: objc_getClass cls
	view: objc_msgSend [id sel_getUid "alloc"]
	rect: make-rect 0 0 0 0
	view: objc_msgSend [view sel_getUid "initWithFrame:" rect/x rect/y rect/w rect/h]
	if face <> null [store-face-to-obj view face]
	objc_msgSend [obj sel_getUid "setContentView:" view]
]

insert-list-item: func [
	hWnd  [integer!]
	item  [red-string!]
	pos	  [integer!]
	list? [logic!]
	/local
		len [integer!]
		sel [integer!]
][
	unless TYPE_OF(item) = TYPE_STRING [exit]

	len: objc_msgSend [hWnd sel_getUid "numberOfItems"]
	sel: either list? [
		pos: pos + 1
		sel_getUid "insertItemWithTitle:atIndex:"
	][
		sel_getUid "insertItemWithObjectValue:atIndex:"
	]
	if pos > len [pos: len]
	objc_msgSend [hWnd sel to-NSString item pos]
]

init-combo-box: func [
	combo		[integer!]
	data		[red-block!]
	caption		[integer!]
	drop-list?	[logic!]
	/local
		str		[red-string!]
		tail	[red-string!]
		len		[integer!]
		val		[integer!]
		sel-add [integer!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		objc_msgSend [combo sel_getUid "removeAllItems"]
		either drop-list? [
			sel-add: sel_getUid "addItemWithTitle:"
			objc_msgSend [combo sel-add NSString("")]
		][
			sel-add: sel_getUid "addItemWithObjectValue:"
		]

		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data

		if str = tail [exit]

		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [
				len: -1
				val: NSString((unicode/to-utf8 str :len))
				objc_msgSend [combo sel-add val]
			]
			str: str + 1
		]
	]

	either drop-list? [
		objc_msgSend [combo sel_getUid "selectItemAtIndex:" -1]
	][
		either caption <> 0 [
			objc_msgSend [combo sel_getUid "setStringValue:" caption]
		][
			len: objc_msgSend [combo sel_getUid "numberOfItems"]
			if zero? len [objc_msgSend [combo sel_getUid "setStringValue:" NSString("")]]
		]
	]
]

cap-year: func [year [integer!] return: [integer!]][
	if year < 1601 [year: 1601]
	if year > 9999 [year: 9999]
	return year
]

to-NSDate: func [
	date 	[red-date!]
	return: [integer!]
	/local
		components [integer!]
		calendar   [integer!]
		NSDate 	   [integer!]
][	
	components: objc_msgSend [
		objc_msgSend [objc_getClass "NSDateComponents" sel_getUid "alloc"]
		sel_getUid "init"
	]
	
	objc_msgSend [components sel_getUid "setDay:" DATE_GET_DAY(date/date)]
	objc_msgSend [components sel_getUid "setMonth:" DATE_GET_MONTH(date/date)]
	objc_msgSend [components sel_getUid "setYear:" cap-year DATE_GET_YEAR(date/date)]
	
	calendar: objc_msgSend [
		objc_msgSend [objc_getClass "NSCalendar" sel_getUid "alloc"]
		sel_getUid "initWithCalendarIdentifier:"
		NSString("gregorian")
	]
	
	NSDate: objc_msgSend [calendar sel_getUid "dateFromComponents:" components]
	objc_msgSend [components sel_getUid "release"]
	objc_msgSend [calendar sel_getUid "release"]
	
	return NSDate
]

sync-calendar: func [
	handle [integer!]
	/local
		slot 	   [red-value!]
		calendar   [integer!]
		components [integer!]
		day 	   [integer!]
		month 	   [integer!]
		year	   [integer!]
][
	calendar: objc_msgSend [
		objc_msgSend [objc_getClass "NSCalendar" sel_getUid "alloc"]
		sel_getUid "initWithCalendarIdentifier:"
		NSString("gregorian")
	]
	
	components: objc_msgSend [
		calendar sel_getUid "components:fromDate:"
		NSCalendarUnitDay or NSCalendarUnitMonth or NSCalendarUnitYear
		objc_msgSend [handle sel_getUid "dateValue"]
	]
	
	day:   objc_msgSend [components sel_getUid "day"]
	month: objc_msgSend [components sel_getUid "month"]
	year:  objc_msgSend [components sel_getUid "year"]
	
	slot: (get-face-values handle) + FACE_OBJ_DATA
	date/make-at slot year month day 0.0 0 0 no no
	
	objc_msgSend [calendar sel_getUid "release"]
]

init-calendar: func [
	calendar [integer!]
	data	 [red-value!]
	/local
		dt [red-date! value]
][
	objc_msgSend [calendar sel_getUid "setDatePickerMode:" NSDatePickerModeSingle]
	objc_msgSend [calendar sel_getUid "setDatePickerStyle:" NSDatePickerStyleClockAndCalendar]
	objc_msgSend [calendar sel_getUid "setDatePickerElements:" NSDatePickerElementFlagYearMonthDay]
	
	objc_msgSend [calendar sel_getUid "setTarget:" calendar]
	objc_msgSend [calendar sel_getUid "setAction:" sel_getUid "calendar-change"]
	objc_msgSend [calendar sel_getUid "sendActionOn:" NSLeftMouseDown]
	
	date/make-at as red-value! dt 1601 01 01 0.0 0 0 no no
	objc_msgSend [calendar sel_getUid "setMinDate:" to-NSDate dt]
	date/make-at as red-value! dt 9999 12 31 0.0 0 0 no no
	objc_msgSend [calendar sel_getUid "setMaxDate:" to-NSDate dt]
	
	objc_msgSend [
		calendar
		sel_getUid "setDateValue:"
		either TYPE_OF(data) = TYPE_DATE [
			to-NSDate as red-date! data
		][
			objc_msgSend [objc_getClass "NSDate" sel_getUid "date"]
		]
	]
	
	unless TYPE_OF(data) = TYPE_DATE [sync-calendar calendar]
]

init-window: func [
	face	[red-object!]
	window	[integer!]
	title	[integer!]
	bits	[integer!]
	rect	[NSRect!]
	/local
		flags		[integer!]
		sel_Hidden	[integer!]
		main-win?	[logic!]
][
	flags: 0
	main-win?: yes
	either bits and FACET_FLAGS_NO_BORDER = 0 [
		flags: NSClosableWindowMask
		if bits and FACET_FLAGS_RESIZE <> 0 [flags: flags or NSResizableWindowMask]
		either bits and FACET_FLAGS_NO_TITLE = 0 [flags: flags or NSTitledWindowMask][main-win?: no]
		if bits and FACET_FLAGS_NO_MIN  = 0 [flags: flags or NSMiniaturizableWindowMask]
	][main-win?: no]
	window: objc_msgSend [
		window
		sel_getUid "initWithContentRect:styleMask:backing:defer:"
		rect/x rect/y rect/w rect/h flags 2 0
	]

	set-content-view window face

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
	;if main-win? [objc_msgSend [window sel_getUid "makeMainWindow"]]
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
	return: [integer!]
	/local
		color	[red-tuple!]
		opts	[red-block!]
		word	[red-word!]
		id		[integer!]
		obj		[integer!]
		sym		[integer!]
		len		[integer!]
		rc		[NSRect!]
		show?	[red-logic!]
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
		store-face-to-obj obj face

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
		if len % 2 <> 0 [return obj]
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
	;if transparent-base? color [objc_msgSend [obj sel_getUid "setWantsLayer:" yes]]
	obj
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

	x: either border? [NSBezelBorder][NSNoBorder]
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
	store-face-to-obj obj face

	rc/y: as float32! 1e37			;-- FLT_MAX
	objc_msgSend [obj sel_getUid "setVerticallyResizable:" yes]
	objc_msgSend [obj sel_getUid "setHorizontallyResizable:" yes]
	objc_msgSend [obj sel_getUid "setMinSize:" rc/x rc/h]
	objc_msgSend [obj sel_getUid "setMaxSize:" rc/y rc/y]
	objc_msgSend [obj sel_getUid "setAutomaticQuoteSubstitutionEnabled:" no]
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
	menu		[red-block!]
	border?		[logic!]
	return:		[integer!]
	/local
		id		[integer!]
		obj		[integer!]
		column	[integer!]
][
	rc/x: as float32! 0.0
	rc/y: as float32! 0.0
	rc/w: rc/w - as float32! 5.0

	id: CFString("RedCol1")
	column: objc_msgSend [objc_getClass "NSTableColumn" sel_getUid "alloc"]
	column: objc_msgSend [column sel_getUid "initWithIdentifier:" id]
	;CFRelease id
	objc_msgSend [column sel_getUid "setWidth:" rc/w]

	obj: either border? [NSBezelBorder][NSNoBorder]
	objc_msgSend [container sel_getUid "setBorderType:" obj]
	objc_msgSend [container sel_getUid "setAutohidesScrollers:" yes]
	objc_msgSend [container sel_getUid "setHasHorizontalScroller:" yes]
	objc_msgSend [container sel_getUid "setHasVerticalScroller:" yes]
	;objc_msgSend [container sel_getUid "setAutoresizingMask:" NSViewWidthSizable or NSViewHeightSizable]

	id: objc_getClass "RedTableView"
	obj: objc_msgSend [id sel_getUid "alloc"]

	assert obj <> 0
	obj: objc_msgSend [
		obj sel_getUid "initWithFrame:" rc/x rc/y rc/w rc/h
	]
	store-face-to-obj obj face

	if TYPE_OF(menu) = TYPE_BLOCK [set-context-menu obj menu]

	objc_msgSend [obj sel_getUid "setRowSizeStyle:" 0]
	objc_msgSend [obj sel_getUid "setHeaderView:" 0]
	objc_msgSend [obj sel_getUid "addTableColumn:" column]
	objc_msgSend [obj sel_getUid "setDelegate:" obj]
	objc_msgSend [obj sel_getUid "setDataSource:" obj]
	objc_msgSend [obj sel_getUid "reloadData"]

	objc_msgSend [container sel_getUid "setDocumentView:" obj]
	objc_msgSend [obj sel_getUid "release"]
	objc_msgSend [column sel_getUid "release"]
	obj
]

update-combo-box: func [
	face  [red-object!]
	value [red-value!]
	sym   [integer!]
	new	  [red-value!]
	index [integer!]
	part  [integer!]
	list? [logic!]										;-- TRUE: drop-list or drop-down widgets
	/local
		hWnd [integer!]
		nstr [integer!]
		str  [red-string!]
		sel  [red-integer!]
		blk  [red-block!]
		data [red-block!]
		val  [red-value!]
		i n	 [integer!]
][
	hWnd: get-face-handle face
	switch TYPE_OF(value) [
		TYPE_BLOCK [
			;-- caculate the index in native widget, e.g.
			;-- we have data: ["abc" 32 "zyz" 8 "xxx"]   index: 4
			;-- the actual insertion index: 2
			val: block/rs-head as red-block! (object/get-values face) + FACE_OBJ_DATA
			i: 0 n: 0
			while [n < index][
				if TYPE_OF(val) = TYPE_STRING [i: i + 1]
				val: val + 1
				n: n + 1
			]

			blk: as red-block! value
			case [
				any [
					sym = words/_remove/symbol
					sym = words/_take/symbol
					sym = words/_clear/symbol
					sym = words/_reverse/symbol
					sym = words/_put/symbol
					sym = words/_poke/symbol
					sym = words/_move/symbol
				][
					data: as red-block! new
					if all [
						sym = words/_move/symbol
						data/node <> blk/node		;-- move to another block
					][
						;@@ TBD handle it properly
						;@@ need to trigger event for origin block in `move` action
						exit
					]

					ownership/unbind-each as red-block! value index part

					either all [
						sym = words/_clear/symbol
						zero? index
					][
						objc_msgSend [hWnd sel_getUid "removeAllItems"]
						nstr: NSString("")
						either list? [
							objc_msgSend [hWnd sel_getUid "setTitle:" nstr]
						][
							objc_msgSend [hWnd sel_getUid "setStringValue:" nstr]
						]
					][
						if list? [i: i + 1]
						str: as red-string! block/rs-abs-at blk index
						loop part [
							if TYPE_OF(str) = TYPE_STRING [
								objc_msgSend [hWnd sel_getUid "removeItemAtIndex:" i]
							]
						]
					]
				]
				any [
					sym = words/_inserted/symbol
					sym = words/_appended/symbol
					sym = words/_poked/symbol
					sym = words/_put-ed/symbol
					sym = words/_reversed/symbol
					sym = words/_moved/symbol
				][
					str: as red-string! either any [
						null? new
						TYPE_OF(new) = TYPE_BLOCK
					][
						block/rs-abs-at as red-block! value index
					][
						new
					]

					ownership/unbind-each as red-block! value index part
					loop part [
						if TYPE_OF(str) = TYPE_STRING [
							insert-list-item hWnd str i list?
							i: i + 1
							ownership/bind as red-value! str face _data
						]
						str: str + 1
					]
				]
				true [0]
			]
		]
		TYPE_STRING [
			if any [sym = words/_lowercase/symbol sym = words/_uppercase/symbol][
				sel: as red-integer! (object/get-values face) + FACE_OBJ_SELECTED
				index: sel/value - 1
			]
			i: index
			if list? [index: index + 1]
			objc_msgSend [hWnd sel_getUid "removeItemAtIndex:" index]
			insert-list-item hWnd as red-string! value i list?
		]
		default [assert false]			;@@ raise a runtime error
	]
	objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
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
		objc_setAssociatedObject bar RedAttachedWidgetKey n OBJC_ASSOCIATION_RETAIN
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

update-rich-text: func [
	state	[red-block!]
	handles [red-block!]
	return: [logic!]
	/local
		redraw [red-logic!]
][
	if TYPE_OF(handles) = TYPE_BLOCK [
		redraw: as red-logic! (block/rs-tail handles) - 1
		redraw/value: true
	]
	TYPE_OF(state) <> TYPE_BLOCK
]

set-hint-text: func [
	hWnd		[integer!]
	options		[red-block!]
	/local
		text	[red-string!]
		cell	[integer!]
][
	if TYPE_OF(options) <> TYPE_BLOCK [exit]
	text: as red-string! block/select-word options word/load "hint" no
	if TYPE_OF(text) = TYPE_STRING [
		cell: objc_msgSend [hWnd sel_getUid "cell"]
		objc_msgSend [cell sel_getUid "setPlaceholderString:" to-NSString text]
	]
]

parse-common-opts: func [
	hWnd	[integer!]
	options [red-block!]
	type	[integer!]
	/local
		word	[red-word!]
		w		[red-word!]
		img		[red-image!]
		bool	[red-logic!]
		len		[integer!]
		sym		[integer!]
		cur		[c-string!]
		hcur	[integer!]
		nsimg	[integer!]
		btn?	[logic!]
		pt		[CGPoint! value]
][
	btn?: yes
	if TYPE_OF(options) = TYPE_BLOCK [
		word: as red-word! block/rs-head options
		len: block/rs-length? options
		if len % 2 <> 0 [exit]
		while [len > 0][
			if TYPE_OF(word) = TYPE_SET_WORD [
				sym: symbol/resolve word/symbol
				case [
					sym = _cursor [
						w: word + 1
						either TYPE_OF(w) = TYPE_IMAGE [
							img: as red-image! w
							nsimg: objc_msgSend [
								OBJC_ALLOC("NSImage")
								sel_getUid "initWithCGImage:size:" OS-image/to-cgimage img 0 0
							]
							pt/x: as float32! IMAGE_WIDTH(img/size) / 2
							pt/y: as float32! IMAGE_HEIGHT(img/size) / 2
							hcur: objc_msgSend [
								OBJC_ALLOC("NSCursor")
								sel_getUid "initWithImage:hotSpot:" nsimg pt/x pt/y
							]
							objc_msgSend [nsimg sel_release]
						][
							if TYPE_OF(w) = TYPE_WORD [
								sym: symbol/resolve w/symbol
								cur: case [
									sym = _I-beam	 ["IBeamCursor"]
									sym = _hand		 ["pointingHandCursor"]
									sym = _cross	 ["crosshairCursor"]
									sym = _resize-ns ["resizeUpDownCursor"]
									any [
										sym = _resize-ew
										sym = _resize-we
									]				 ["resizeLeftRightCursor"]
									true			 ["arrowCursor"]
								]
								hcur: objc_msgSend [objc_getClass "NSCursor" sel_getUid cur]
							]
						]
						if hcur <> 0 [objc_setAssociatedObject hWnd RedCursorKey hcur OBJC_ASSOCIATION_ASSIGN]
					]
					sym = _class [
						w: word + 1
						if TYPE_OF(w) = TYPE_WORD [
							sym: symbol/resolve w/symbol
							sym: case [
								sym = _regular	[0]			;-- 32
								sym = _small	[1]			;-- 28
								sym = _mini		[2]			;-- 16
								true			[0]
							]
							objc_msgSend [
								objc_msgSend [hWnd sel_getUid "cell"]
								sel_getUid "setControlSize:" sym
							]
							btn?: no
						]
					]
					sym = _accelerated [
						bool: as red-logic! word + 1
						if all [TYPE_OF(bool) = TYPE_LOGIC bool/value][
							objc_msgSend [hWnd sel_getUid "setWantsLayer:" yes]
						]
					]
					true [0]
				]
			]
			word: word + 2
			len: len - 2
		]
	]

	if any [type = button type = toggle][
		len: either btn? [NSRegularSquareBezelStyle][NSRoundedBezelStyle]
		objc_msgSend [hWnd sel_getUid "setBezelStyle:" len]
	]
]

OS-redraw: func [hWnd [integer!]][objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]]

OS-refresh-window: func [hWnd [integer!]][0]

OS-show-window: func [
	hWnd [integer!]
][
	;make-event hWnd 0 EVT_SIZE
	change-selection hWnd (as red-integer! get-face-values hWnd) + FACE_OBJ_SELECTED window
]

OS-make-view: func [
	face	[red-object!]
	parent	[integer!]
	return: [integer!]
	/local
		values	[red-value!]
		type	[red-word!]
		str		[red-string!]
		tail	[red-string!]
		offset	[red-point2D!]
		size	[red-pair!]
		data	[red-block!]
		int		[red-integer!]
		img		[red-image!]
		menu	[red-block!]
		show?	[red-logic!]
		open?	[red-logic!]
		rate	[red-value!]
		saved	[red-value!]
		font	[red-object!]
		flags	[integer!]
		bits	[integer!]
		sym		[integer!]
		id		[integer!]
		class	[c-string!]
		caption [integer!]
		len		[integer!]
		obj		[integer!]
		hWnd	[integer!]
		rc		[NSRect!]
		flt		[float!]
		p		[ext-class!]
		pt		[red-point2D!]
][
	stack/mark-native words/_body

	values: object/get-values face

	type:	  as red-word!		values + FACE_OBJ_TYPE
	str:	  as red-string!	values + FACE_OBJ_TEXT
	offset:   as red-point2D!	values + FACE_OBJ_OFFSET
	size:	  as red-pair!		values + FACE_OBJ_SIZE
	show?:	  as red-logic!		values + FACE_OBJ_VISIBLE?
	open?:	  as red-logic!		values + FACE_OBJ_ENABLED?
	data:	  as red-block!		values + FACE_OBJ_DATA
	img:	  as red-image!		values + FACE_OBJ_IMAGE
	menu:	  as red-block!		values + FACE_OBJ_MENU
	font:	  as red-object!	values + FACE_OBJ_FONT
	rate:						values + FACE_OBJ_RATE

	bits: 	  get-flags as red-block! values + FACE_OBJ_FLAGS
	sym: 	  symbol/resolve type/symbol
	p:		  null

	if TYPE_OF(offset) = TYPE_PAIR [as-point2D as red-pair! offset]

	case [
		any [
			sym = text-list
			sym = area
		][
			class: "RedScrollView"
		]
		sym = text [class: "RedTextField"]
		sym = field [
			class: either bits and FACET_FLAGS_PASSWORD = 0 ["RedTextField"][
				"RedSecureField"
			]
		]
		sym = button [
			class: "RedButton"
		]
		sym = toggle [
			class: "RedButton"
			flags: NSPushOnPushOffButton
		]
		sym = check [
			class: "RedButton"
			flags: NSSwitchButton
		]
		sym = radio [
			class: "RedButton"
			flags: NSRadioButton
		]
		sym = window [
			class: "RedWindow"
			if bits and FACET_FLAGS_MODAL <> 0 [
				obj: objc_msgSend [NSApp sel_getUid "mainWindow"]
				if obj <> 0 [vector/rs-append-int active-wins obj]
			]
		]
		sym = tab-panel [
			class: "RedTabView"
		]
		any [
			sym = panel
			sym = base
			sym = rich-text
		][
			class: either bits and FACET_FLAGS_SCROLLABLE = 0 ["RedBase"]["RedScrollBase"]
		]
		sym = drop-down [
			class: "RedComboBox"
		]
		sym = drop-list [
			class: "RedPopUpButton"
		]
		sym = slider [class: "RedSlider"]
		sym = progress [class: "RedProgress"]
		sym = group-box [
			class: "RedBox"
		]
		sym = camera [class: "RedCamera"]
		sym = calendar [class: "RedCalendar"]
		true [											;-- search in user-defined classes
			p: find-class type
			either null? p [
				fire [TO_ERROR(script face-type) type]
			][
				class: p/class
			]
		]
	]

	id: objc_getClass class
	obj: objc_msgSend [id sel_getUid "alloc"]
	if zero? obj [print-line "*** Error: Create Window failed!"]

	;-- store the face value in the extra space of the window struct
	assert TYPE_OF(face) = TYPE_OBJECT					;-- detect corruptions caused by CreateWindow unwanted events
	store-face-to-obj obj face

	;-- extra initialization
	caption: either TYPE_OF(str) = TYPE_STRING [
		len: -1
		CFString((unicode/to-utf8 str :len))
	][
		CFString("")
	]
	rc: make-rect 1 1 1 1
	GET_PAIR_XY(size rc/w rc/h)
	rc/x: offset/x
	rc/y: offset/y
	
	case [
		sym = window [
			rc/y: (as float32! screen-size-y) - rc/y - rc/h
			init-window face obj caption bits rc
		]
		sym = drop-list [
			objc_msgSend [obj sel_getUid "initWithFrame:pullsDown:" rc/x rc/y rc/w rc/h yes]
		]
		true [objc_msgSend [obj sel_getUid "initWithFrame:" rc/x rc/y rc/w rc/h]]
	]

	parse-common-opts obj as red-block! values + FACE_OBJ_OPTIONS sym

	case [
		sym = text [
			objc_msgSend [obj sel_getUid "setEditable:" false]
			objc_msgSend [obj sel_getUid "setBordered:" false]
			id: objc_msgSend [obj sel_getUid "cell"]
			objc_msgSend [obj sel_getUid "setDrawsBackground:" false]
			if caption <> 0 [objc_msgSend [obj sel_getUid "setStringValue:" caption]]
		]
		sym = field [
			if bits and FACET_FLAGS_NO_BORDER <> 0 [
				objc_msgSend [obj sel_getUid "setBordered:" false]
			]
			if bits and FACET_FLAGS_PASSWORD <> 0 [
				saved: values + FACE_OBJ_FLAGS
				saved/header: TYPE_NONE
				hWnd: OS-make-view face parent
				saved/header: TYPE_WORD
				objc_msgSend [hWnd sel_getUid "setHidden:" yes]
				objc_setAssociatedObject obj RedSecureFieldKey hWnd OBJC_ASSOCIATION_ASSIGN
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
			make-text-list face obj rc menu bits and FACET_FLAGS_NO_BORDER = 0
			integer/make-at values + FACE_OBJ_SELECTED 0
		]
		any [
			sym = button
			sym = toggle
			sym = check
			sym = radio
		][
			if sym <> button [
				if all [sym = check bits and FACET_FLAGS_TRISTATE <> 0][
					objc_msgSend [obj sel_getUid "setAllowsMixedState:" yes]
				]
				objc_msgSend [obj sel_getUid "setButtonType:" flags]
				set-logic-state obj as red-logic! data sym = check
			]
			if TYPE_OF(img) = TYPE_IMAGE [change-image obj img sym]
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
		sym = rich-text [
			hWnd: init-base-face face obj menu size values bits
			objc_setAssociatedObject hWnd RedRichTextKey hWnd OBJC_ASSOCIATION_ASSIGN
		]
		sym = tab-panel [
			set-tabs obj values
			objc_msgSend [obj sel_getUid "setDelegate:" obj]
		]
		sym = window [
			win-cnt: win-cnt + 1

			if all [						;@@ application menu ?
				zero? AppMainMenu
				menu-bar? menu window
			][
				AppMainMenu: objc_msgSend [NSApp sel_getUid "mainMenu"]
				build-menu menu AppMainMenu obj
			]
			if bits and FACET_FLAGS_MODAL <> 0 [vector/rs-append-int active-wins obj]
		]
		sym = slider [
			either rc/w > rc/h [flt: as-float rc/w][flt: as-float rc/h]
			objc_msgSend [obj sel_getUid "setMaxValue:" flt]
			flt: get-position-value as red-float! data flt
			objc_msgSend [obj sel_getUid "setDoubleValue:" flt]
			objc_msgSend [obj sel_getUid "setTarget:" obj]
			objc_msgSend [obj sel_getUid "setAction:" sel_getUid "slider-change:"]
		]
		sym = progress [
			objc_msgSend [obj sel_getUid "setIndeterminate:" false]
			if rc/h > rc/w [
				rc/x: as float32! -90.0
				objc_msgSend [obj sel_getUid "setBoundsRotation:" rc/x]
			]
			flt: get-position-value as red-float! data 100.0
			objc_msgSend [obj sel_getUid "setDoubleValue:" flt]
		]
		sym = group-box [
			set-content-view obj null
			either zero? caption [
				objc_msgSend [obj sel_getUid "setTitlePosition:" NSNoTitle]
			][
				objc_msgSend [obj sel_getUid "setTitle:" caption]
			]
		]
		sym = drop-down [
			init-combo-box obj data caption no
			objc_msgSend [obj sel_getUid "setDelegate:" obj]
		]
		sym = drop-list [
			init-combo-box obj data caption yes
			objc_msgSend [obj sel_getUid "setTarget:" obj]
			objc_msgSend [obj sel_getUid "setAction:" sel_getUid "popup-button-action:"]
		]
		sym = camera [
			init-camera obj rc data
		]
		sym = calendar [
			init-calendar obj as red-value! data
		]
		true [											;-- search in user-defined classes
			if p <> null [
				p/init-proc as int-ptr! obj values
			]
		]
	]

	SET_PAIR_SIZE_FLAG(obj size)

	change-selection obj as red-integer! values + FACE_OBJ_SELECTED sym
	change-para obj face as red-object! values + FACE_OBJ_PARA font sym

	unless show?/value [change-visible obj no sym]
	unless open?/value [change-enabled obj no sym]

	change-font obj face font sym
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
		hWnd2	[integer!]
		flags	[integer!]
		type	[integer!]
		nsstr	[integer!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	values: s/offset

	state: as red-block! values + FACE_OBJ_STATE
	word: as red-word! values + FACE_OBJ_TYPE
	type: symbol/resolve word/symbol

	if all [
		type = rich-text
		update-rich-text state as red-block! values + FACE_OBJ_EXT3
	][exit]

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
	if flags and FACET_FLAG_ENABLED? <> 0 [
		bool: as red-logic! values + FACE_OBJ_ENABLED?
		change-enabled hWnd bool/value type
	]
	if flags and FACET_FLAG_VISIBLE? <> 0 [
		bool: as red-logic! values + FACE_OBJ_VISIBLE?
		change-visible hWnd bool/value type
	]
	if flags and FACET_FLAG_SELECTED <> 0 [
		change-selection hWnd as red-integer! values + FACE_OBJ_SELECTED type
	]
	if flags and FACET_FLAG_FLAGS <> 0 [
		flags: get-flags as red-block! values + FACE_OBJ_FLAGS
		if type = field [
			hWnd2: objc_getAssociatedObject hWnd RedSecureFieldKey

			if flags and FACET_FLAGS_PASSWORD <> 0 [
				type: hWnd
				hWnd: hWnd2
				hWnd2: type
			]
			nsstr: objc_msgSend [hWnd sel_getUid "stringValue"]
			objc_msgSend [hWnd sel_getUid "setHidden:" yes]
			objc_msgSend [hWnd2 sel_getUid "setHidden:" no]
			objc_msgSend [hWnd2 sel_getUid "setStringValue:" nsstr]
			objc_msgSend [hWnd2 sel_getUid "becomeFirstResponder"]
			type: objc_msgSend [nsstr sel_getUid "length"]
			hWnd: objc_msgSend [hWnd2 sel_getUid "currentEditor"]
			objc_msgSend [hWnd sel_getUid "setSelectedRange:" type 0]
		]
	]
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
	if flags and FACET_FLAG_PARA <> 0 [
		change-para
			hWnd
			face
			as red-object! values + FACE_OBJ_PARA
			as red-object! values + FACE_OBJ_FONT
			type
	]
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
		if TYPE_OF(res) <> TYPE_NONE [_series/remove as red-series! res null null]
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
][
	sym: symbol/resolve facet/symbol

	case [
		;sym = facets/pane [0]
		sym = facets/data [
			word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
			type: symbol/resolve word/symbol
			sym: action/symbol
			case [
				any [
					type = drop-list
					type = drop-down
				][
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
		view	[integer!]
		cview	[integer!]
		data	[integer!]
		rect	[RECT_STRUCT value]
		rc		[NSRect! value]
		rc2		[NSRect! value]
		h		[float32!]
		sz		[red-pair!]
		bmp		[integer!]
		bmp2	[integer!]
		bmp3	[integer!]
		img		[integer!]
		ret		[red-image!]
		type	[integer!]
		word	[red-word!]
		rep		[integer!]
		id		[integer!]
][
	word: as red-word! get-node-facet face/ctx FACE_OBJ_TYPE
	type: symbol/resolve word/symbol
	case [
		type = screen [
			rect/left: 0 rect/top: 0 rect/right: 7F800000h rect/bottom: 7F800000h
			bmp: CGWindowListCreateImage as NSRect! rect 1 0 0		;-- INF
			ret: image/init-image as red-image! stack/push* OS-image/load-cgimage as int-ptr! bmp
			objc_msgSend [bmp sel_getUid "retain"]
		]
		type = camera [
			view: as-integer face-handle? face
			either zero? view [ret: as red-image! none-value][
				ret: as red-image! (object/get-values face) + FACE_OBJ_IMAGE
				ret/header: TYPE_NONE						;@@ TBD release old image?
				change-image view ret type
			]
		]
		true [
			view: as-integer face-handle? face
			either zero? view [ret: as red-image! none-value][
				sz: as red-pair! (object/get-values face) + FACE_OBJ_SIZE
				either type = window [
					rc: objc_msgSend_rect [view sel_getUid "frame"]
					cview: objc_msgSend [view sel_getUid "contentView"]
					rc2: objc_msgSend_rect [cview sel_getUid "frame"]
					h: rc/h - rc2/h
					rc/y: rc/y - h
					rc/h: h
					id: objc_msgSend [view sel_getUid "windowNumber"]
					;-- title
					bmp: CGWindowListCreateImage rc 8 id 1 or 8

					;-- content
					rep: objc_msgSend [cview sel_getUid "bitmapImageRepForCachingDisplayInRect:" rc2/x rc2/y rc2/w rc2/h]
					objc_msgSend [cview sel_getUid "cacheDisplayInRect:toBitmapImageRep:" rc2/x rc2/y rc2/w rc2/h rep]
					img: objc_msgSend [
						objc_msgSend [objc_getClass "NSImage" sel_alloc]
						sel_getUid "initWithSize:" as float! rc2/w as float! rc2/h
					]
					objc_msgSend [img sel_getUid "addRepresentation:" rep]
					bmp2: objc_msgSend [img sel_getUid "CGImageForProposedRect:context:hints:" 0 0 0]

					;-- combine
					bmp3: OS-image/combine-image bmp bmp2 0

					ret: image/init-image as red-image! stack/push* OS-image/load-cgimage as int-ptr! bmp3
					;CGImageRelease bmp
					;CGImageRelease bmp2
					objc_msgSend [img sel_release]
					objc_msgSend [bmp3 sel_getUid "retain"]
				][
					rc: objc_msgSend_rect [view sel_getUid "bounds"]
					rep: objc_msgSend [view sel_getUid "bitmapImageRepForCachingDisplayInRect:" rc/x rc/y rc/w rc/h]
					objc_msgSend [view sel_getUid "cacheDisplayInRect:toBitmapImageRep:" rc/x rc/y rc/w rc/h rep]
					img: objc_msgSend [
						objc_msgSend [objc_getClass "NSImage" sel_alloc]
						sel_getUid "initWithSize:" as float! rc/w as float! rc/h
					]
					objc_msgSend [img sel_getUid "addRepresentation:" rep]
					bmp: objc_msgSend [img sel_getUid "CGImageForProposedRect:context:hints:" 0 0 0]
					ret: image/init-image as red-image! stack/push* OS-image/load-cgimage as int-ptr! bmp
					objc_msgSend [bmp sel_getUid "retain"]
					objc_msgSend [img sel_release]
				]
			]
		]
	]
	ret
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
	/local
		rc	[NSRect!]
		ctx [int-ptr!]
][
	rc: make-rect IMAGE_WIDTH(img/size) IMAGE_HEIGHT(img/size) 0 0
	ctx: OS-image/to-bitmap-ctx OS-image/to-cgimage img
	do-draw ctx as red-image! rc cmds yes no no no
	OS-image/ctx-to-image img as-integer ctx
]

OS-draw-face: func [
	hWnd	[handle!]
	cmds	[red-block!]
	flags	[integer!]
	/local
		ctx [integer!]
		obj [integer!]
		doc [integer!]
][
	if TYPE_OF(cmds) = TYPE_BLOCK [
		assert system/thrown = 0

		obj: as-integer hWnd
		if flags and FACET_FLAGS_SCROLLABLE <> 0 [
			doc: objc_msgSend [obj sel_getUid "documentView"]
			if doc <> 0 [obj: doc]
		]

		ctx: 0
		object_getInstanceVariable obj IVAR_RED_DRAW_CTX :ctx
		catch RED_THROWN_ERROR [parse-draw as draw-ctx! ctx cmds yes]
	]
	if system/thrown = RED_THROWN_ERROR [system/thrown: 0]
]
