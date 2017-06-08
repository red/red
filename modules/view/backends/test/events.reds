Red/System [
	Title:	"Test events handling"
	Author: "Nenad Rakocevic"
	File: 	%events.reds
	Tabs: 	4
	Rights: "Copyright (C) 2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum event-action! [
	EVT_NO_DISPATCH										;-- no further msg processing allowed
	EVT_DISPATCH										;-- allow DispatchMessage call only
]

gui-evt: declare red-event!								;-- low-level event value slot
gui-evt/header: TYPE_EVENT

make-at: func [
	handle  [handle!]
	face	[red-object!]
	return: [red-object!]
][
	;face/header:		  GetWindowLong handle wc-offset
	;face/ctx:	 as node! GetWindowLong handle wc-offset + 4
	;face/class:			  GetWindowLong handle wc-offset + 8
	;face/on-set: as node! GetWindowLong handle wc-offset + 12
	;face
	null
]

push-face: func [
	handle  [handle!]
	return: [red-object!]
][
	make-at handle as red-object! stack/push*
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
][
	null
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
][
	null
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
][
	null
]

get-event-picked: func [
	evt		[red-event!]
	return: [red-value!]
][
	null
]

get-event-flags: func [
	evt		[red-event!]
	return: [red-value!]
][
	null
]

get-event-flag: func [
	flags	[integer!]
	flag	[integer!]
	return: [red-value!]
][
	null
]


do-events: func [
	no-wait? [logic!]
	return:  [logic!]
][
	true
]