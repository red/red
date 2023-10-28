Red/System [
	Title:	"Timer with a naive implementation"
	Author: "Xie Qingtian"
	File: 	%timer.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

timer: context [

	timer-list:			as node! 0

	time-proc!: alias function! [
		w [widget!]
	]

	timer!: alias struct! [
		once?		[logic!]
		triggered?	[logic!]
		elapse		[integer!]		;-- in milliseconds
		timeout		[integer!]		;-- in milliseconds
		widget		[widget!]
		callback	[time-proc!]
	]

	init: does [
		timer-list: array/make 8 size? int-ptr!
	]

	on-gc-mark: does [
		collector/keep timer-list
	]

	timer-proc: func [
		widget	[widget!]
	][
		send-event EVT_TIME widget 0
	]

	add: func [
		widget		[widget!]
		timeout		[integer!]
		/local
			t		[int-ptr!]
	][
		t: make widget timeout as int-ptr! :timer-proc no
		array/append-ptr timer-list t
	]

	kill: func [
		widget		[widget!]
		/local
			len		[integer!]
			t		[timer!]
			i		[integer!]
	][
		len: array/length? timer-list
		i: len
		while [i > 0][
			t: as timer! array/pick-ptr timer-list i
			i: i - 1
			if t/widget = widget [
				array/remove-at timer-list i * size? int-ptr! size? int-ptr!
				break
			]
		]
	]

	update: func [
		elapse		[integer!]
		/local
			len		[integer!]
			t		[int-ptr!]
			i		[integer!]
	][
		len: array/length? timer-list
		i: 1
		while [i <= len][
			t: array/pick-ptr timer-list i
			tick t elapse
			i: i + 1
		]
	]

	make: func [
		widget		[widget!]
		timeout		[integer!]
		callback	[int-ptr!]
		once?		[logic!]
		return:		[int-ptr!]
		/local
			t		[timer!]
	][
		t: as timer! zero-alloc size? timer!
		t/widget: widget
		t/timeout: timeout
		t/callback: as time-proc! callback
		t/once?: once?
		as int-ptr! t
	]

	delete: func [
		tm	[int-ptr!]
	][
		free as byte-ptr! tm
	]

	reset: func [
		tm	[int-ptr!]
		/local
			t [timer!]
	][
		t: as timer! tm
		t/triggered?: no
		t/elapse: 0
	]

	tick: func [
		tm		[int-ptr!]
		ms		[integer!]
		return: [logic!]
		/local
			t	[timer!]
	][
		t: as timer! tm
		t/elapse: t/elapse + ms
		either all [not t/triggered? t/elapse >= t/timeout] [
			t/callback t/widget
			reset tm
			if t/once? [t/triggered?: yes]
			yes
		][no]
	]
]