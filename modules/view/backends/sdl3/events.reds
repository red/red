Red/System [
	Title:	"SDL3 events handling"
	File: 	%events.reds
	Tabs: 	4
]

flags-blk: declare red-block!
flags-blk/header:	TYPE_UNSET
flags-blk/head:		0
flags-blk/node:		alloc-cells 8
flags-blk/header:	TYPE_BLOCK

sdl-red-event!: alias struct! [
	window	[red-object!]
	face	[red-object!]
	type	[integer!]
	flags	[integer!]
	x		[integer!]
	y		[integer!]
	key		[integer!]
	picked	[integer!]
]

gui-evt: declare red-event!
gui-evt/header: TYPE_EVENT
sdl-red-evt: as sdl-red-event! zero-alloc size? sdl-red-event!

get-event-window: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		msg [sdl-red-event!]
][
	msg: as sdl-red-event! evt/msg
	as red-value! msg/window
]

get-event-face: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		msg [sdl-red-event!]
][
	msg: as sdl-red-event! evt/msg
	as red-value! msg/face
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		msg [sdl-red-event!]
][
	msg: as sdl-red-event! evt/msg
	as red-value! pair/push msg/x msg/y
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		msg [sdl-red-event!]
][
	msg: as sdl-red-event! evt/msg
	either msg/key > 0 [
		as red-value! char/push msg/key and FFFFh
	][
		as red-value! none-value
	]
]

get-event-picked: func [
	evt		[red-event!]
	return: [red-value!]
	/local
	msg [sdl-red-event!]
][
	msg: as sdl-red-event! evt/msg
	either evt/type = EVT_WHEEL [
		as red-value! float/push as float! msg/picked
	][
		as red-value! integer/push msg/picked
	]
]

get-event-orientation: func [
	evt		[red-event!]
	return: [red-value!]
][
	as red-value! none-value
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

dispatch-event: func [
	window	[red-object!]
	face	[red-object!]
	type	[integer!]
	flags	[integer!]
	x		[integer!]
	y		[integer!]
	key		[integer!]
	picked	[integer!]
	return: [integer!]
	/local
		res	 [red-word!]
		sym	 [integer!]
		rtype [integer!]
][
	if null? face [return EVT_DISPATCH]

	sdl-red-evt/window: window
	sdl-red-evt/face: face
	sdl-red-evt/type: type
	sdl-red-evt/flags: flags
	sdl-red-evt/x: x
	sdl-red-evt/y: y
	sdl-red-evt/key: key
	sdl-red-evt/picked: picked

	gui-evt/header: TYPE_EVENT
	gui-evt/type: type
	gui-evt/flags: flags
	gui-evt/msg: as byte-ptr! sdl-red-evt

	stack/mark-try-all words/_anon
	res: as red-word! stack/arguments
	catch CATCH_ALL_EXCEPTIONS [
		#call [system/view/awake gui-evt]
		stack/unwind
	]
	stack/adjust-post-try
	if system/thrown <> 0 [system/thrown: 0]
	rtype: TYPE_OF(res)
	if ANY_WORD?(rtype) [
		sym: symbol/resolve res/symbol
		if any [sym = stop sym = done][return EVT_NO_DISPATCH]
	]
	EVT_DISPATCH
]
