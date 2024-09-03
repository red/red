Red/System [
	Title:	"Events handling"
	Author: "Xie Qingtian"
	File: 	%events.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum event-action! [
	EVT_DISPATCH
	EVT_NO_DISPATCH										;-- no further msg processing allowed
]

flags-blk: declare red-block!							;-- static block value for event/flags
flags-blk/header:	TYPE_UNSET
flags-blk/head:		0
flags-blk/node:		alloc-cells 4
flags-blk/header:	TYPE_BLOCK

last-mouse-evt:		0
mouse-click-delta:	0
mouse-event?:		no
mouse-x:			as float32! 0
mouse-y:			as float32! 0
event-loop-cnt:		0

map-pt-from-win: func [
	g		[widget!]
	x		[float32!]
	y		[float32!]
	xx		[float32-ptr!]
	yy		[float32-ptr!]
	/local
		a	[float32!]
		b	[float32!]
][
	a: g/box/left
	b: g/box/top
	if g/parent <> null [
		g: g/parent
		while [g/parent <> null][
			a: a + g/box/left
			b: b + g/box/top
			g: g/parent
		]
	]
	xx/value: x - a
	yy/value: y - b
]

get-event-window: func [
	evt		[red-event!]
	return: [red-value!]
][
	null
]

get-event-face: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		widget-evt [widget-event!]
		g		[widget!]
][
	widget-evt: as widget-event! evt/msg
	g: widget-evt/widget
	assert g/face <> 0
	copy-cell as cell! :g/face stack/push*
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		widget-evt [widget-event!]
][
	widget-evt: as widget-event! evt/msg
	as red-value! pair/push as-integer widget-evt/pt/x as-integer widget-evt/pt/y
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		widget-evt [widget-event!]
][
	widget-evt: as widget-event! evt/msg
	as red-value! either evt/flags and SPECIAL_KEY = 0 [
		char/push widget-evt/data
	][
		switch widget-evt/data [
			KEY_PAGE_UP		[_page-up]
			KEY_PAGE_DOWN	[_page-down]
			KEY_END			[_end]
			KEY_HOME		[_home]
			KEY_LEFT		[_left]
			KEY_UP			[_up]
			KEY_RIGHT		[_right]
			KEY_DOWN		[_down]
			KEY_INSERT		[_insert]
			KEY_DELETE		[_delete]
			;KEY_PAUSE		[_pause]
			KEY_F1			[_F1]
			KEY_F2			[_F2]
			KEY_F3			[_F3]
			KEY_F4			[_F4]
			KEY_F5			[_F5]
			KEY_F6			[_F6]
			KEY_F7			[_F7]
			KEY_F8			[_F8]
			KEY_F9			[_F9]
			KEY_F10			[_F10]
			KEY_F11			[_F11]
			KEY_F12			[_F12]
			default			[none-value]
		]
	]
]

get-event-orientation: func [
	evt		[red-event!]
	return: [red-value!]
][
	as red-value! none-value
]

get-event-picked: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		e	[widget-event!]
][
	e: as widget-event! evt/msg
	as red-value! switch evt/type [
		EVT_WHEEL [float/push as float! e/fdata]
		default	  [integer/push e/data]
	]
]

get-event-flags: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		blk [red-block!]
][
	blk: flags-blk
	block/rs-clear blk	
	if evt/flags and EVT_FLAG_AWAY		 <> 0 [block/rs-append blk as red-value! _away]
	if evt/flags and EVT_FLAG_DOWN		 <> 0 [block/rs-append blk as red-value! _down]
	if evt/flags and EVT_FLAG_MID_DOWN	 <> 0 [block/rs-append blk as red-value! _mid-down]
	if evt/flags and EVT_FLAG_ALT_DOWN	 <> 0 [block/rs-append blk as red-value! _alt-down]
	if evt/flags and EVT_FLAG_AUX_DOWN	 <> 0 [block/rs-append blk as red-value! _aux-down]
	if evt/flags and EVT_FLAG_CTRL_DOWN	 <> 0 [block/rs-append blk as red-value! _control]
	if evt/flags and EVT_FLAG_SHIFT_DOWN <> 0 [block/rs-append blk as red-value! _shift]
	if evt/flags and EVT_FLAG_MENU_DOWN  <> 0 [block/rs-append blk as red-value! _alt]
	as red-value! blk
]

get-event-flag: func [
	flags	[integer!]
	flag	[integer!]
	return: [red-value!]
][
	as red-value! logic/push flags and flag <> 0
]

make-event: func [
	evt			[integer!]
	widget-evt	[widget-event!]
	flags		[integer!]
	return:		[integer!]
	/local
		res		[red-word!]
		word	[red-word!]
		sym		[integer!]
		state	[integer!]
		gui-evt	[red-event! value]
		t?		[logic!]
][
	gui-evt/header: TYPE_EVENT
	gui-evt/msg:    as byte-ptr! widget-evt
	gui-evt/flags:  flags
	gui-evt/type:   evt

	state: EVT_DISPATCH

	stack/mark-try-all words/_anon
	res: as red-word! stack/arguments

	t?: interpreter/tracing?
	interpreter/tracing?: no
	catch CATCH_ALL_EXCEPTIONS [
		#call [system/view/awake :gui-evt]
		stack/unwind
	]
	interpreter/tracing?: t?
	
	stack/adjust-post-try
	if system/thrown <> 0 [system/thrown: 0]

	if TYPE_OF(res) = TYPE_WORD [
		sym: symbol/resolve res/symbol
		if sym = done [state: EVT_NO_DISPATCH]		;-- pass event to widget
	]
	state
]

send-event: func [
	evt		[integer!]
	obj		[widget!]
	flags	[integer!]
	return: [integer!]
	/local
		w-evt	[widget-event! value]
		ret		[integer!]
][
	ret: EVT_DISPATCH
	if obj/flags and WIDGET_FLAG_DISABLE = 0 [
		w-evt/widget: obj
		obj/on-event evt :w-evt
		if 0 <> obj/face [
			ret: make-event evt :w-evt flags
		]
	]
	ret
]

make-red-event: func [
	evt		[integer!]
	obj		[widget!]
	data	[integer!]
	return: [integer!]
	/local
		w-evt	[widget-event! value]
		ret		[integer!]
][
	ret: EVT_DISPATCH
	if obj/flags and WIDGET_FLAG_DISABLE = 0 [
		w-evt/widget: obj
		w-evt/data: data
		if 0 <> obj/face [
			ret: make-event evt :w-evt 0
		]
	]
	ret
]

send-mouse-event: func [
	evt		[integer!]
	obj		[widget!]
	x		[float32!]
	y		[float32!]
	flags	[integer!]
	return: [integer!]
	/local
		g-evt	[widget-event! value]
		ret		[integer!]
][
	ret: EVT_DISPATCH
	if obj/flags and WIDGET_FLAG_DISABLE = 0 [
		g-evt/pt/x: x
		g-evt/pt/y: y
		g-evt/widget: obj
		obj/on-event evt :g-evt
		if 0 <> obj/face [
			ret: make-event evt :g-evt flags
		]
	]
	ret
]

send-key-event: func [
	obj		[widget!]
	char	[integer!]
	flags	[integer!]
	/local
		g-evt	[widget-event! value]
		result	[integer!]
][
	if null? obj [
		obj: screen/focus-widget
	]
	if obj/flags and WIDGET_FLAG_DISABLE = 0 [
		if flags <> 0 [
			either flags = KEY_BACKTAB [		;-- back tab
				flags: EVT_FLAG_SHIFT_DOWN
				char: as-integer #"^-"
			][
				char: flags
				flags: SPECIAL_KEY
			]
		]
		if zero? char [exit]
		g-evt/data: char
		g-evt/widget: obj
		result: make-event EVT_KEY_DOWN :g-evt flags
		if result = EVT_DISPATCH [
			result: make-event EVT_KEY :g-evt flags
		]
		if result = EVT_DISPATCH [
			obj/on-event EVT_KEY :g-evt
		]
	]
]

send-pt-event: func [
	evt		[integer!]
	obj		[widget!]
	x		[float32!]
	y		[float32!]
	flags	[integer!]
][
	send-mouse-event evt obj x y flags
]

hover-changed?: func [
	widget-1	[widget!]
	widget-2	[widget!]
	return: [logic!]
	/local
		g	[widget!]
		leave? [logic!]
][
	leave?: no
	g: widget-1
	until [
		g: g/parent
		if g = widget-2 [leave?: yes break]
		null? g
	]
	any [
		leave?
		widget-1/parent = widget-2/parent		;-- overlapped sibling widgets
	]
]

child?: func [
	child	[widget!]
	parent	[widget!]
	return: [logic!]
][
	while [child <> null][
		child: child/parent
		if child = parent [return true]
	]
	false
]

send-captured-event: func [
	evt		[integer!]
	x		[float32!]
	y		[float32!]
	flags	[integer!]
	filter	[integer!]
	/local
		captured [widget!]
][
	captured: screen/captured-widget
	if all [
		captured <> null
		captured/flags and WIDGET_FLAG_AWAY <> 0
		any [filter = -1 captured/flags and filter <> 0]
	][
		map-pt-from-win captured x y :x :y
		send-mouse-event evt captured x y flags
	]
]

do-mouse-move: func [
	evt		[integer!]
	obj		[widget!]
	x		[float32!]
	y		[float32!]
	flags	[integer!]
	root?	[logic!]
	return: [integer!]
	/local
		child	[widget!]
		ret		[integer!]
		hover	[widget!]
][
	ret: EVT_DISPATCH

	if null? screen/hover-widget [					;-- mouse enter a new window
		send-mouse-event evt obj x y flags
	]

	child: _widget/find-child obj x y
	either child <> null [
		ret: do-mouse-move evt child x - child/box/left y - child/box/top flags no
	][
		hover: screen/hover-widget
		if hover <> obj [
			if hover <> null [
				if hover-changed? hover obj [
					if screen/captured-widget = hover [
						WIDGET_SET_FLAG(hover WIDGET_FLAG_AWAY)
					]
					send-mouse-event
						evt
						hover
						mouse-x
						mouse-y
						flags or EVT_FLAG_AWAY
				]
				if hover-changed? obj hover [
					WIDGET_UNSET_FLAG(obj WIDGET_FLAG_AWAY)
					send-mouse-event evt obj x y flags
				]
			]
			screen/hover-widget: obj
		]
		mouse-x: x
		mouse-y: y
	]
	if all [
		obj/flags and WIDGET_FLAG_ALL_OVER <> 0
		ret = EVT_DISPATCH 
	][
		ret: send-mouse-event evt obj x y flags
	]
	if root? [send-captured-event evt x y flags WIDGET_FLAG_ALL_OVER]
	ret
]

_do-mouse-press: func [
	evt		[integer!]
	obj		[widget!]
	x		[float32!]
	y		[float32!]
	flags	[integer!]
	return: [integer!]		;-- high-word: return value of click event
	/local
		gb	[widget!]
		r0	[integer!]
		r1	[integer!]
		r2	[integer!]
][
	r0: EVT_DISPATCH

	gb: _widget/find-child obj x y
	if gb <> null [
		r0: _do-mouse-press evt gb x - gb/box/left y - gb/box/top flags
	]
	if r0 and FFh = EVT_DISPATCH [
		r1: send-mouse-event evt obj x y flags
	]
	switch evt [
		EVT_LEFT_DOWN [
			array/append-ptr screen/captured as int-ptr! obj
		]
		EVT_LEFT_UP [
			if all [
				r0 and FFFFh >>> 8 = EVT_DISPATCH
				-1 <> array/find-ptr screen/captured as int-ptr! obj
			][
				evt: either any [
					r0 >>> 16 = EVT_DBL_CLICK
					all [
						last-mouse-evt = EVT_LEFT_UP
						mouse-click-delta < 500
					]
				][
					send-mouse-event EVT_CLICK obj x y flags
					last-mouse-evt: EVT_DBL_CLICK
					EVT_DBL_CLICK
				][
					EVT_CLICK
				]
				r2: send-mouse-event evt obj x y flags
				if all [
					null? gb
					WIDGET_FOCUSABLE?(obj)
					obj/flags and WIDGET_FLAG_FOCUS = 0
				][
					screen/set-focus-widget obj null
				]
			]
		]
		default [0]
	]
	evt << 16 or (r2 << 8 or r1)
]

do-mouse-press: func [
	evt		[integer!]
	obj		[widget!]
	x		[float32!]
	y		[float32!]
	flags	[integer!]
][
	if evt = EVT_LEFT_DOWN [screen/captured-widget: screen/hover-widget]
	_do-mouse-press evt obj x y flags
	if evt = EVT_LEFT_UP [
		send-captured-event evt x y flags -1
		screen/captured-widget: null
		array/clear screen/captured
		last-mouse-evt: either last-mouse-evt = EVT_DBL_CLICK [0][EVT_LEFT_UP]
		mouse-click-delta: 0
	]
]

do-mouse-wheel: func [
	dir		[integer!]
	obj		[widget!]
	x		[float32!]
	y		[float32!]
	flags	[integer!]
	return: [integer!]
	/local
		evt [widget-event! value]
		w	[widget!]
		res [integer!]
][
	res: EVT_DISPATCH
	w: _widget/find-child obj x y
	if w <> null [
		res: do-mouse-wheel dir w x - w/box/left y - w/box/top flags
	]

	if all [
		obj <> null
		0 <> obj/face
		obj/flags and WIDGET_FLAG_DISABLE = 0
		res and FFFFh = EVT_DISPATCH
	][
		evt/fdata: as float32! dir
		evt/pt/x: x
		evt/pt/y: y
		evt/widget: obj
		make-event EVT_WHEEL :evt flags
	]
	res
]

post-quit-msg: does [
	event-loop-cnt: event-loop-cnt - 1
]

#define DELTA_TIME 33

try-events: func [][
	if tty/raw-mode? [
		do-events yes
	]
]

do-events: func [
	no-wait? [logic!]
	return:  [logic!]
	/local
		msg?	[logic!]
		n		[integer!]
		tm		[time-meter! value]
		t delta	[integer!]
		mouse?	[red-logic!]
		n-loop	[integer!]
		reenter? [logic!]
][
	reenter?: any [
		no-wait?
		1 < screen/windows-cnt
	]

	n-loop: event-loop-cnt
	unless no-wait? [event-loop-cnt: event-loop-cnt + 1]

	either reenter? [
		unless no-wait? [ansi-parser/clear-buffer]
	][
		tty/init
		screen/enter-alter-screen

		mouse?: as red-logic! #get system/view/platform/mouse-event?
		if mouse?/value <> mouse-event? [
			mouse-event?: mouse?/value
			either mouse-event? [tty/enable-mouse][tty/disable-mouse]
		]
	]

	t: 0
	until [
		catch CATCH_ALL_EXCEPTIONS [
			n: tty/read-input yes
			msg?: n > 0
			if all [no-wait? not msg?][break]

			delta: either t > DELTA_TIME [t][
				tty/wait DELTA_TIME - t
				DELTA_TIME
			]

			time-meter/start :tm

			timer/update delta
			screen/render
			ansi-parser/parse

			if all [
				last-mouse-evt = EVT_LEFT_UP
				mouse-click-delta < 800
			][
				mouse-click-delta: mouse-click-delta + DELTA_TIME
			]

			t: as-integer time-meter/elapse :tm
			assert t >= 0
		]
		if system/thrown <> 0 [
			system/thrown: 0
			post-quit-msg
		]

		any [no-wait? n-loop >= event-loop-cnt]
	]

	either reenter? [
		tty/read-input no	;-- clear stdin queue
		ansi-parser/clear-buffer
	][
		screen/set-cursor-bottom
		if mouse-event? [
			mouse-event?: no
			tty/disable-mouse
		]
		screen/exit-alter-screen
		tty/show-cursor
		tty/restore
		tty/read-input no	;-- clear stdin queue
		screen/reset
	]

	msg?
]