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

#define IO_INVALID_DEVICE		[as int-ptr! -1]

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

	_binary:	as red-word! 0
	_lines:		as red-word! 0
	_info:		as red-word! 0
	_as:		as red-refinement! 0

	wait-list:  as red-block! 0

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
			count: _function/count-locals actor/spec 0 yes
			if positive? count [_function/init-locals count]
			interpreter/call actor red-port/ctx as red-value! words/_awake CB_PORT
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
		data: as sockdata! zero-alloc size
		data/event-handler: as iocp-event-handler! handler
		data/device: as handle! sock
		data/addr-sz: size? sockaddr_in6!
		copy-cell as cell! red-port as cell! :data/port

		#if OS <> 'Windows [data/io-port: g-iocp]

		;-- store low-level data into red port
		handle/make-at
			(object/get-values red-port) + port/field-state
			as-integer data
			handle/CLASS_DEVICE
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
			handle/CLASS_DEVICE
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
			g-iocp/n-ports: g-iocp/n-ports - 1
			state: as red-handle! (object/get-values red-port) + port/field-state
			state/header: TYPE_NONE
		]
		IODebug("close port done")
		data
	]

	port-open?: func [
		red-port	[red-object!]
		return:		[red-value!]
		/local
			values	[red-value!]
			state	[red-handle!]
	][
		values: object/get-values red-port
		state: as red-handle! values + port/field-state
		as red-value! logic/box TYPE_OF(state) <> TYPE_NONE
	]

	make-port: func [
		proto		[red-object!]
		return:		[red-object!]
		/local
			s		[series!]
			value	[red-value!]
			tail	[red-value!]
			p		[red-value!]
			state	[red-value!]
			spec	[red-object!]
	][
		s: GET_BUFFER(ports-block)
		value: s/offset + ports-block/head
		tail:  s/tail

		p: null
		while [value < tail][
			state: (object/get-values as red-object! value) + port/field-state
			if state/header = TYPE_NONE [
				p: value
				break
			]
			value: value + 1
		]
		either p <> null [proto: as red-object! p][
			proto: port/make none-value object/get-values proto TYPE_NONE
			;-- copy spec
			spec: (as red-object! object/get-values proto) + port/field-spec
			object/copy spec spec null no null
			;; @@ add it to a block, so GC can mark it. Improve it later!!!
			block/rs-append ports-block as red-value! proto
		]
		proto
	]

	fill-client-info: func [
		red-port	[red-object!]
		data		[sockdata!]
		/local
			addr	[sockaddr_in!]
			spec	[red-object!]
			vals	[red-value!]
			host	[red-tuple!]
		#if OS = 'Windows [
			paddr	[ptr-value!]
			paddr2	[ptr-value!]
			n		[integer!]
			n2		[integer!]
			GetAcceptExSockAddrs [GetAcceptExSockAddrs!]
		]
	][
		;@@ TBD IPv6
		#either OS = 'Windows [
			GetAcceptExSockAddrs: as GetAcceptExSockAddrs! GetAcceptExSockaddrs-func
			n: 0 n2: 0
			GetAcceptExSockAddrs as byte-ptr! :data/addr 0 0 44 :paddr2 :n2 :paddr :n
			addr: as sockaddr_in! paddr/value
		][
			addr: as sockaddr_in! :data/addr
		]
		spec: (as red-object! object/get-values red-port) + port/field-spec
		vals: object/get-values spec
		host: as red-tuple! vals + 2
		host/header: TYPE_TUPLE or (4 << 19)
		host/array1: addr/sin_addr

		integer/make-at vals + 3 FFFFh and (ntohs addr/sin_family >>> 16)
		vals: vals + 8		;-- ref
		vals/header: TYPE_NONE
	]

	update-ports: func [
		time		[integer!]
		check?		[logic!]
		return:		[integer!]
		/local
			ports	[red-block!]
			type	[integer!]
			head	[red-value!]
			tail	[red-value!]
			data	[iocp-data!]
			ret		[integer!]
	][
		ports: as red-block! wait-list
		type: TYPE_OF(ports)

		if type = TYPE_NONE [return 0]

		if type = TYPE_PORT [
			data: get-iocp-data as red-object! ports
			either null? data [return 0][return 1]		;-- port was closed if data is null
		]

		ret: 0
		if type = TYPE_BLOCK [
			head: block/rs-head ports
			tail: block/rs-tail ports
			while [head < tail][
				if TYPE_OF(head) = TYPE_PORT [
					data: get-iocp-data as red-object! head
					if data <> null [
						either check? [
							ret: ret + 1
						][
							if data/timeout-cnt > 0 [
								data/timeout-cnt: data/timeout-cnt - time
								if data/timeout-cnt > 0 [ret: ret + 1]
							]
							if data/timeout-cnt = -1 [ret: ret + 1]
						]
					]
				]
				head: head + 1
			]
		]
		ret
	]

	set-timeout: func [
		port	[red-object!]
		time	[integer!]
		/local data [iocp-data!]
	][
		if TYPE_OF(port) = TYPE_PORT [
			data: get-iocp-data port
			assert data <> null

			data/timeout: time
			data/timeout-cnt: time
		]
	]

	do-events: func [
		time	[integer!]		;-- milliseconds, -1: infinite time
		ports	[red-value!]
		once?	[logic!]
		/local
			ret		[integer!]
			data 	[iocp-data!]
			head 	[red-value!]
			tail	[red-value!]
			pvalue	[cell! value]
	][
		copy-cell as cell! wait-list :pvalue
		either ports <> null [
			copy-cell ports as cell! wait-list
			either TYPE_OF(ports) = TYPE_PORT [
				set-timeout as red-object! ports time
			][
				head: block/rs-head as red-block! ports
				tail: block/rs-tail as red-block! ports
				while [head < tail][
					set-timeout as red-object! head time
					head: head + 1
				]
			]
		][
			set-type as cell! wait-list TYPE_NONE
		]
		forever [
			ret: iocp/wait g-iocp time
			if any [once? zero? ret][break]
		]
		copy-cell :pvalue as cell! wait-list
	]

	pin-memory: func [
		node	[node!]
	][
		b-allocator/increase-ref as series! node/value
	]

	unpin-memory: func [
		node	[node!]
	][
		b-allocator/decrease-ref as series! node/value
	]

	verbose: 0
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
		_binary:	word/load "binary"
		_lines:		word/load "lines"
		_info:		word/load "info"
		_as:		refinement/load "as"

		g-iocp: iocp/create
		ports-block: block/make-in root 16
		wait-list: as red-block! ALLOC_TAIL(root)
		set-type as cell! wait-list TYPE_NONE
	]
]

#include %devices/dns.reds
#include %devices/tcp.reds
#include %devices/tls.reds
#include %devices/udp.reds
#include %devices/file.reds
