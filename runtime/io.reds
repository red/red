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
	IO_EVT_NONE:		0
	IO_EVT_ERROR:		1
	IO_EVT_READ:		2
	IO_EVT_WRITE:		4
	IO_EVT_CLOSE:		8
	IO_EVT_ACCEPT:		10h
	IO_EVT_CONNECT:		20h
	IO_EVT_WROTE:		40h
	IO_EVT_LOOKUP:		80h
	IO_EVT_PULSE:		0200h
	;-- more IO Events
	;-- IO_EVT...
]

#define IODebug(msg) [#if debug? = yes [io/debug msg]]

#include %platform/io.reds

g-iocp: as iocp! 0			;-- global I/O completion port

ports-block: as red-block! 0

io: context [

	verbose: 2

	get-event-type: func [
		evt		[red-event!]
		return: [red-value!]
	][
		as red-value! switch (evt/type and FFFFh) [
			IO_EVT_ACCEPT	[words/_accept]
			IO_EVT_CONNECT	[words/_connect]
			IO_EVT_READ		[words/_read]
			IO_EVT_WRITE	[words/_wrote]
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
			evt		[red-event! value]
			actor	[red-function!]
			count	[integer!]
	][
		evt/header: TYPE_EVENT
		evt/type: EVT_CATEGORY_IO << 16 or op
		evt/msg: as byte-ptr! msg

		;-- call port/awake: func [event [event!]][]
		actor: as red-function! object/rs-select red-port as red-value! words/_awake
		if TYPE_OF(actor) = TYPE_FUNCTION [
			stack/mark-func words/_awake red-port/ctx
			stack/push as red-value! :evt
			count: _function/calc-arity null actor 0
			if positive? count [_function/init-locals count]
			_function/call actor red-port/ctx
			stack/unwind-last
			stack/reset
		]
		;stack/mark-func words/_awake red-port/ctx
		;stack/push as red-value! :evt
		;port/call-function red-port words/_awake
		;stack/reset
	]

	create-socket-data: func [
		red-port	[red-object!]
		sock		[integer!]
		handler		[int-ptr!]
		size		[integer!]
		return: 	[sockdata!]
		/local
			data	[sockdata!]
	][
		data: as sockdata! alloc0 size
		data/iocp/event-handler: as iocp-event-handler! handler
		data/iocp/device: as handle! sock
		copy-cell as cell! red-port as cell! :data/port
		#if OS <> 'Windows [
			data/iocp/io-port: g-iocp
		]
		;-- store low-level data into red port
		handle/make-at
			(object/get-values red-port) + port/field-state
			as-integer data
		data
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

	set-iocp-data: func [
		red-port	[red-object!]
		data		[iocp-data!]
		/local
			state	[red-handle!]
	][
		handle/make-at
			(object/get-values red-port) + port/field-state
			as-integer data
	]

	close-port: func [
		red-port	[red-object!]
		return:		[iocp-data!]
		/local
			state	[red-handle!]
			data	[iocp-data!]
	][
		data: get-iocp-data red-port
		IODebug(["close port: " data " " g-iocp/n-ports])
		if data <> null [
			#if OS <> 'Windows [
				if data/state <> 0 [iocp/remove data/io-port as-integer data/device data/state data]
			]
			socket/close as-integer data/device
			g-iocp/n-ports: g-iocp/n-ports - 1
			state: as red-handle! (object/get-values red-port) + port/field-state
			state/header: TYPE_NONE
		]
		IODebug("close port done")
		data
	]

	do-events: func [
		time	[integer!]		;-- milliseconds, -1: infinite time
	][
		forever [
			if zero? iocp/wait g-iocp time [exit]
			if time > -1 [exit]
		]
	]

	pin-memory: func [
		node	[node!]
		/local
			s	[series!]
	][
		s: as series! node/value
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

	log-file: "                                        "

	debug: func [
		[typed]	count [integer!] list [typed-value!]
		/local saved [integer!] file [integer!]
	][
		#if debug? = yes [if verbose > 1 [
			#if OS = 'Windows [platform/dos-console?: no]
			file: simple-io/open-file log-file simple-io/RIO_APPEND no
			saved: stdout
			stdout: file
		]]
		_print count list yes
		prin-byte lf
		#if debug? = yes [if verbose > 1 [	
			simple-io/close-file file
			stdout: saved
		]]
	]

	init: does [
		#if debug? = yes [if verbose > 1 [
			sprintf [log-file "red-log-%g.log" platform/get-time yes no]
		]]
		g-iocp: iocp/create
		ports-block: block/make-in root 16
	]
]

#include %devices/tcp.reds
#include %devices/tls.reds
#include %devices/udp.reds
#include %devices/file.reds
