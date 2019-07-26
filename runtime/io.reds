Red/System [
	Title:	"I/O facilities"
	Author: "Xie Qingtian"
	File: 	%io.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum io-event-type! [
	IO_EVT_NONE:	300
	IO_EVT_ERROR
	IO_EVT_ACCEPT
	IO_EVT_CONNECT
	IO_EVT_READ
	IO_EVT_WROTE
	IO_EVT_CLOSE
	IO_EVT_EXIT_LOOP
	;-- more IO Events
	;-- IO_EVT...
]

#include %platform/io.reds

g-iocp: as iocp! 0			;-- global I/O completion port

ports-block: as red-block! 0

io: context [

	get-event-type: func [
		evt		[red-event!]
		return: [red-value!]
	][
		as red-value! switch (evt/type and FFFFh) [
			IO_EVT_ACCEPT	[words/_accept]
			IO_EVT_CONNECT	[words/_connect]
			IO_EVT_READ		[words/_read]
			IO_EVT_WROTE	[words/_wrote]
			IO_EVT_CLOSE	[words/_close]
			IO_EVT_ERROR	[words/_error]
		]
	]

	get-event-port: func [
		evt		[red-event!]
		return: [red-value!]
	][
		as red-value! evt/msg
	]

	call-awake: func [
		red-port	[red-object!]
		msg			[red-object!]
		op			[io-event-type!]
		/local
			values	[red-value!]
			awake	[red-function!]
			evt		[red-event! value]
	][
		values: object/get-values red-port
		awake: as red-function! values + port/field-awake
		if TYPE_OF(awake) <> TYPE_FUNCTION [exit]

		evt/header: TYPE_EVENT
		evt/type: EVT_CATEGORY_IO << 16 or op
		evt/msg: as byte-ptr! msg

		;-- call port/awake: func [event [event!]][]
		stack/mark-func words/_awake awake/ctx
		stack/push as red-value! :evt
		port/call-function awake awake/ctx
		stack/reset
	]

	store-iocp-data: func [
		data		[iocp-data!]
		red-port	[red-object!]
	][
		handle/make-at
			(object/get-values red-port) + port/field-state
			as-integer data
	]

	get-iocp-data: func [
		red-port	[red-object!]
		return:		[iocp-data!]
		/local
			state	[red-handle!]
	][
		state: as red-handle! (object/get-values red-port) + port/field-state
		either TYPE_OF(state) = TYPE_NONE [null][as iocp-data! state/value]
	]

	do-events: func [
		time	[integer!]		;-- milliseconds, -1: infinite time
	][
		forever [
			iocp/wait g-iocp time
			if time > -1 [exit]
		]
	]

	pin-memory: func [
		bin		[red-binary!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(bin)
		s/flags: s/flags or flag-series-fixed
	]

	unpin-memory: func [
		node	[node!]
		/local
			s	[series!]
	][
		s: as series! node/value
		s/flags: s/flags and (not flag-series-fixed)
	]

	init: does [
		g-iocp: iocp/create
		ports-block: block/make-in root 16
	]
]

#include %devices/tcp.reds
