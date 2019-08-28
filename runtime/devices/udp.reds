Red/System [
	Title:	"low-level UDP port"
	Author: "Xie Qingtian"
	File: 	%udp.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

udp-device: context [
	verbose: 1

	event-handler: func [
		data		[iocp-data!]
		/local
			p		[red-object!]
			msg		[red-object!]
			udp		[sockdata!]
			type	[integer!]
			bin		[red-binary!]
			s		[series!]
	][
		udp: as sockdata! data
		p: as red-object! :udp/port
		msg: p
		type: data/event

		switch type [
			IO_EVT_ACCEPT	[
				#either OS = 'Windows [
					msg: create-red-port p data/accept-sock
					iocp/bind g-iocp as int-ptr! data/accept-sock
					socket/acceptex as-integer data/device data
				][
					msg: create-red-port p socket/accept as-integer data/device
				]
			]
			IO_EVT_READ	[
				bin: as red-binary! (object/get-values p) + port/field-data
				s: GET_BUFFER(bin)
				s/tail: as cell! (as byte-ptr! s/tail) + data/transferred
				io/unpin-memory bin/node
				#if OS = 'Windows [
					either data/accept-sock = PENDING_IO_FLAG [
						free as byte-ptr! data
					][
						data/event: IO_EVT_NONE
					]
				]
			]
			IO_EVT_WRITE	[
				io/unpin-memory udp/send-buf
				#if OS = 'Windows [
					either data/accept-sock = PENDING_IO_FLAG [
						free as byte-ptr! data
					][
						data/event: IO_EVT_NONE
					]
				]
			]
			default [data/event: IO_EVT_NONE]
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
		
		create-udp-data proto sock
		proto
	]

	create-udp-data: func [
		port	[red-object!]
		sock	[integer!]
		return: [iocp-data!]
		/local
			data	[sockdata!]
	][
		data: as sockdata! alloc0 size? sockdata!
		data/iocp/event-handler: as iocp-event-handler! :event-handler
		data/iocp/device: as handle! sock
		copy-cell as cell! port as cell! :data/port
		#if OS <> 'Windows [data/iocp/io-port: g-iocp]

		;-- store low-level data into red port
		io/store-iocp-data as iocp-data! data port
		as iocp-data! data
	]

	get-udp-data: func [
		red-port	[red-object!]
		return:		[sockdata!]
		/local
			state	[red-handle!]
			data	[iocp-data!]
			new		[sockdata!]
	][
		state: as red-handle! (object/get-values red-port) + port/field-state
		if TYPE_OF(state) <> TYPE_HANDLE [
			probe "ERROR: No low-level handle"
			0 ;; TBD throw error
		]

		#either OS = 'Windows [
			data: as iocp-data! state/value
			either data/event = IO_EVT_NONE [		;-- we can reuse this one
				as sockdata! data
			][										;-- needs to create a new one
				new: as sockdata! alloc0 size? sockdata!
				new/iocp/event-handler: as iocp-event-handler! :event-handler
				new/iocp/device: data/device
				new/iocp/accept-sock: PENDING_IO_FLAG ;-- use it as a flag to indicate pending data
				copy-cell as cell! red-port as cell! :new/port
				new
			]
		][
			as sockdata! state/value
		]
	]

	udp-client: func [
		port	[red-object!]
		host	[red-string!]
		num		[red-integer!]
		/local
			fd		[integer!]
			n		[integer!]
			addr	[c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "udp client"]]

		fd: socket/create AF_INET SOCK_DGRAM IPPROTO_UDP
		iocp/bind g-iocp as int-ptr! fd
		socket/bind fd 0 AF_INET

		n: -1
		addr: unicode/to-utf8 host :n
		socket/connect fd addr num/value AF_INET create-udp-data port fd
	]

	udp-server: func [
		port	[red-object!]
		num		[red-integer!]
		/local
			fd	[integer!]
			acp [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "udp server"]]

		fd: socket/create AF_INET SOCK_DGRAM IPPROTO_UDP
		socket/bind fd num/value AF_INET
		socket/listen fd 1024 create-udp-data port fd
		iocp/bind g-iocp as int-ptr! fd
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
		#if debug? = yes [if verbose > 0 [print-line "udp/open"]]

		values: object/get-values red-port
		state: as red-handle! values + port/field-state
		if TYPE_OF(state) <> TYPE_NONE [return as red-value! red-port]

		spec:	as red-object! values + port/field-spec
		values: object/get-values spec
		host:	as red-string! values + 2
		num:	as red-integer! values + 3		;-- port number

		either zero? string/rs-length? host [	;-- e.g. open udp://:8000
			udp-server red-port num
		][
			udp-client red-port host num
		]
		as red-value! red-port
	]

	close: func [
		red-port	[red-object!]
		return:		[red-value!]
		/local
			data	[iocp-data!]
	][
		#if debug? = yes [if verbose > 0 [print-line "udp/close"]]

		data: io/get-iocp-data red-port
		if data <> null [socket/close as-integer data/device]
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
			data	[sockdata!]
			bin		[red-binary!]
			n		[integer!]
	][
		switch TYPE_OF(value) [
			TYPE_BINARY [
				bin: as red-binary! value
				io/pin-memory bin
			]
			default [return as red-value! port]
		]

		data: get-udp-data port
		data/send-buf: bin/node

		socket/send
			as-integer data/iocp/device
			binary/rs-head bin
			binary/rs-length? bin
			as iocp-data! data
		as red-value! port
	]

	copy: func [
		red-port	[red-object!]
		new			[red-value!]
		part		[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-value!]
		/local
			data	[iocp-data!]
			buf		[red-binary!]
			s		[series!]
	][
		buf: as red-binary! (object/get-values red-port) + port/field-data
		if TYPE_OF(buf) <> TYPE_BINARY [
			binary/make-at as cell! buf SOCK_READBUF_SZ
		]
		buf/head: 0
		io/pin-memory buf
		s: GET_BUFFER(buf)
		data: as iocp-data! get-udp-data red-port
		socket/recv as-integer data/device as byte-ptr! s/offset s/size data
		as red-value! red-port
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
