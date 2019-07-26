Red/System [
	Title:	"low-level TCP port"
	Author: "Xie Qingtian"
	File: 	%tcp.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

tcp-device: context [
	verbose: 1

	tcp-data!: alias struct! [
		iocp		[iocp-data! value]
		port		[red-object! value]		;-- red port! cell
		buflen		[integer!]
		buffer		[byte-ptr!]
		pin-buf		[node!]
	]

	event-handler: func [
		data		[iocp-data!]
		/local
			p		[red-object!]
			msg		[red-object!]
			tcp		[tcp-data!]
			type	[integer!]
			bin		[red-binary!]
	][
		tcp: as tcp-data! data
		p: as red-object! :tcp/port
		msg: p

		switch data/event [
			SOCK_EVT_ACCEPT	[
				msg: create-red-port p data/accept-sock
				iocp/bind g-iocp as int-ptr! data/accept-sock
				type: IO_EVT_ACCEPT
			]
			SOCK_EVT_CONNECT [type: IO_EVT_CONNECT]
			SOCK_EVT_READ	[
				bin: binary/load tcp/buffer data/transferred
				copy-cell as cell! bin (object/get-values p) + port/field-data
				stack/pop 1
				type: IO_EVT_READ
			]
			SOCK_EVT_WRITE	[
				io/unpin-memory tcp/pin-buf
				type: IO_EVT_WROTE
			]
			default			[probe ["wrong tcp event: " data/event]]
		]

		io/call-awake p msg type
	]

	create-red-port: func [
		proto		[red-object!]
		sock		[integer!]
		return:		[red-object!]
	][
		proto: port/make none-value object/get-values proto TYPE_NONE
		;; @@ add it to a block, so GC can mark it. Improve it later!!!
		block/rs-append ports-block as red-value! proto

		create-tcp-data proto sock
		proto
	]

	create-tcp-data: func [
		port	[red-object!]
		sock	[integer!]
		return: [iocp-data!]
		/local
			data [tcp-data!]
	][
		data: as tcp-data! alloc0 size? tcp-data!
		data/iocp/event-handler: as iocp-event-handler! :event-handler
		data/iocp/device: as handle! sock
		copy-cell as cell! port as cell! :data/port

		;-- store low-level data into red port
		io/store-iocp-data as iocp-data! data port

		as iocp-data! data
	]

	tcp-client: func [
		port	[red-object!]
		host	[red-string!]
		num		[red-integer!]
		/local
			fd		[integer!]
			n		[integer!]
			addr	[c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tcp client"]]

		fd: socket/create AF_INET SOCK_STREAM IPPROTO_TCP
		iocp/bind g-iocp as int-ptr! fd
		socket/bind fd 0 AF_INET

		n: -1
		addr: unicode/to-utf8 host :n
		socket/connect fd addr num/value AF_INET create-tcp-data port fd
	]

	tcp-server: func [
		port	[red-object!]
		num		[red-integer!]
		/local
			fd	[integer!]
			acp [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tcp server"]]

		fd: socket/create AF_INET SOCK_STREAM IPPROTO_TCP
		socket/bind fd num/value AF_INET
		socket/listen fd 1024
		iocp/bind g-iocp as int-ptr! fd
		socket/accept fd create-tcp-data port fd
	]

	;-- actions

	open: func [
		red-port	[red-object!]
		new?		[logic!]
		read?		[logic!]
		write?		[logic!]
		seek?		[logic!]
		allow		[red-value!]
		return:		[red-value!]
		/local
			values	[red-value!]
			spec	[red-object!]
			state	[red-handle!]
			host	[red-string!]
			num		[red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tcp/open"]]

		values: object/get-values red-port
		state: as red-handle! values + port/field-state
		if TYPE_OF(state) <> TYPE_NONE [return as red-value! red-port]

		spec:	as red-object! values + port/field-spec
		values: object/get-values spec
		host:	as red-string! values + 2
		num:	as red-integer! values + 3		;-- port number

		either zero? string/rs-length? host [	;-- e.g. open tcp://:8000
			tcp-server red-port num
		][
			tcp-client red-port host num
		]
		as red-value! red-port
	]

	close: func [
		red-port	[red-object!]
		return:		[red-value!]
		/local
			data	[tcp-data!]
	][
		#if debug? = yes [if verbose > 0 [print-line "tcp/close"]]

		data: as tcp-data! io/get-iocp-data red-port
		if data/buffer <> null [
			free data/buffer
			data/buffer: null
		]
		socket/close as-integer data/iocp/device
		as red-value! red-port
	]

	insert: func [
		port		[red-object!]
		value		[red-value!]
		part		[red-value!]
		only?		[logic!]
		dup			[red-value!]
		append?		[logic!]
		return:		[red-value!]
		/local
			data	[tcp-data!]
			bin		[red-binary!]
			pbuf	[WSABUF! value]
			n		[integer!]
	][
		switch TYPE_OF(value) [
			TYPE_BINARY [
				bin: as red-binary! value
				io/pin-memory bin
			]
			default [return as red-value! port]
		]

		data: as tcp-data! io/get-iocp-data port
		data/pin-buf: bin/node

		socket/write
			as-integer data/iocp/device
			binary/rs-head bin
			binary/rs-length? bin
			as iocp-data! data
		as red-value! port
	]

	copy: func [
		port		[red-object!]
		new			[red-value!]
		part		[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-value!]
		/local
			data	[tcp-data!]
	][
		data: as tcp-data! io/get-iocp-data port
		
		if null? data/buffer [
			data/buflen: 1024 * 1024
			data/buffer: allocate 1024 * 1024
		]

		socket/read as-integer data/iocp/device data/buffer data/buflen as iocp-data! data
		as red-value! port
	]

	table: [
		;-- Series actions --
		null			;append
		null			;at
		null			;back
		null			;change
		null			;clear
		:copy
		null			;find
		null			;head
		null			;head?
		null			;index?
		:insert
		null			;length?
		null			;move
		null			;next
		null			;pick
		null			;poke
		null			;put
		null			;remove
		null			;reverse
		null			;select
		null			;sort
		null			;skip
		null			;swap
		null			;tail
		null			;tail?
		null			;take
		null			;trim
		;-- I/O actions --
		null			;create
		:close
		null			;delete
		null			;modify
		:open
		null			;open?
		null			;query
		null			;read
		null			;rename
		null			;update
		null			;write
	]
]
