Red/System [
	Title:	"DNS port"
	Author: "Xie Qingtian"
	File: 	%dns.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

dns-device: context [
	verbose: 1

	event-handler: func [
		data		[iocp-data!]
		/local
			p		[red-object!]
			msg		[red-object!]
			dns		[dns-data!]
			type	[integer!]
			bin		[red-binary!]
			s		[series!]
			ser1	[red-series!]
			ser2	[red-series!]
	][
		dns: as dns-data! data
		p: as red-object! :dns/port
		msg: p
		type: data/event
probe "dns event-handler"
		switch type [
			IO_EVT_READ	[
				bin: as red-binary! (object/get-values p) + port/field-data
				s: GET_BUFFER(bin)
				probe ["read data: " data/transferred]
probe as c-string! s/offset
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
				io/unpin-memory dns/send-buf
				#if OS = 'Windows [
					either data/accept-sock = PENDING_IO_FLAG [
						free as byte-ptr! data
					][
						data/event: IO_EVT_NONE
					]
				]
			]
			IO_EVT_ACCEPT	[ 
				msg: create-red-port p dns
				ser1: as red-series! (object/get-values p) + port/field-data
				ser2: as red-series! (object/get-values msg) + port/field-data
				s: GET_BUFFER(ser1)
				probe ["read data in accept: " data/transferred]
				s/tail: as cell! (as byte-ptr! s/tail) + data/transferred
				io/unpin-memory ser1/node
				_series/copy ser1 ser2 null no null
			]
			default [data/event: IO_EVT_NONE]
		]

		io/call-awake p msg type
	]

	create-red-port: func [
		proto		[red-object!]
		data		[dns-data!]
		return:		[red-object!]
		/local
			fd		[integer!]
	][
		proto: port/make none-value object/get-values proto TYPE_NONE

		;; @@ add it to a block, so GC can mark it. Improve it later!!!
		block/rs-append ports-block as red-value! proto

		fd: socket/create AF_INET SOCK_DGRAM IPPROTO_dns
		iocp/bind g-iocp as int-ptr! fd
		probe "create red port"
		dump4 :data/addr
		probe data/addr-sz
		probe WSAConnect fd as sockaddr_in! :data/addr data/addr-sz null null null null
		data: as dns-data! io/create-socket-data proto fd as int-ptr! :event-handler size? dns-data!
		data/iocp/type: IOCP_TYPE_dns
		proto
	]

	create-dns-data: func [
		port	[red-object!]
		sock	[integer!]
		addr	[c-string!]
		num		[integer!]			;-- port number
		return: [dns-data!]
		/local
			data	[dns-data!]
			saddr	[sockaddr_in!]
	][
		data: as dns-data! io/create-socket-data port sock as int-ptr! :event-handler size? dns-data!
		data/iocp/type: IOCP_TYPE_dns

		;@@ TBD add IPv6 support
		data/addr-sz: size? sockaddr_in6!
		saddr: as sockaddr_in! :data/addr
		num: htons num
		saddr/sin_family: num << 16 or AF_INET
		either addr <> null [
			saddr/sin_addr: inet_addr addr
		][
			saddr/sin_addr: 0
		]
		saddr/sa_data1: 0
		saddr/sa_data2: 0
		data
	]

	get-dns-data: func [
		red-port	[red-object!]
		return:		[dns-data!]
		/local
			state	[red-handle!]
			data	[iocp-data!]
			new		[dns-data!]
	][
		state: as red-handle! (object/get-values red-port) + port/field-state
		if TYPE_OF(state) <> TYPE_HANDLE [
			probe "ERROR: No low-level handle"
			0 ;; TBD throw error
		]

		#either OS = 'Windows [
			data: as iocp-data! state/value
			either data/event = IO_EVT_NONE [		;-- we can reuse this one
				as dns-data! data
			][										;-- needs to create a new one
				new: as dns-data! alloc0 size? dns-data!
				new/iocp/event-handler: as iocp-event-handler! :event-handler
				new/iocp/device: data/device
				new/iocp/accept-sock: PENDING_IO_FLAG ;-- use it as a flag to indicate pending data
				copy-cell as cell! red-port as cell! :new/port
				new
			]
		][
			as dns-data! state/value
		]
	]

	dns-client: func [
		port	[red-object!]
		host	[red-string!]
		num		[red-integer!]
		/local
			fd		[integer!]
			n		[integer!]
			addr	[c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "dns client"]]

		fd: socket/create AF_INET SOCK_DGRAM IPPROTO_dns
		iocp/bind g-iocp as int-ptr! fd
		n: -1
		addr: unicode/to-utf8 host :n
		socket/uconnect fd addr num/value AF_INET
		create-dns-data port fd addr num/value
	]

	dns-server: func [
		port	[red-object!]
		num		[red-integer!]
		/local
			fd	[integer!]
			acp [integer!]
			d	[dns-data!]
	][
		#if debug? = yes [if verbose > 0 [print-line "dns server"]]

		fd: socket/create AF_INET SOCK_DGRAM IPPROTO_dns
		d: create-dns-data port fd null num/value
		probe ["size.... " d/addr-sz]
		probe socket/bind fd num/value AF_INET
		iocp/bind g-iocp as int-ptr! fd
		copy-from port d
		d/iocp/event: IO_EVT_ACCEPT
	]

	copy-from: func [
		red-port	[red-object!]
		data		[dns-data!]
		/local
			buf		[red-binary!]
			s		[series!]
	][
		buf: as red-binary! (object/get-values red-port) + port/field-data
		if TYPE_OF(buf) <> TYPE_BINARY [
			binary/make-at as cell! buf SOCK_READBUF_SZ
		]
		buf/head: 0
		io/pin-memory buf/node
		s: GET_BUFFER(buf)
		socket/urecv
			as-integer data/iocp/device
			as byte-ptr! s/offset
			s/size
			as sockaddr_in! :data/addr
			:data/addr-sz
			as sockdata! data
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
		#if debug? = yes [if verbose > 0 [print-line "dns/open"]]

		values: object/get-values red-port
		state: as red-handle! values + port/field-state
		if TYPE_OF(state) <> TYPE_NONE [return as red-value! red-port]

		spec:	as red-object! values + port/field-spec
		values: object/get-values spec
		host:	as red-string! values + 2
		num:	as red-integer! values + 3		;-- port number

		either zero? string/rs-length? host [	;-- e.g. open dns://:8000
			dns-server red-port num
		][
			dns-client red-port host num
		]
		as red-value! red-port
	]

	close: func [
		red-port	[red-object!]
		return:		[red-value!]
		/local
			data	[iocp-data!]
	][
		#if debug? = yes [if verbose > 0 [print-line "dns/close"]]

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
			data	[dns-data!]
			bin		[red-binary!]
			n		[integer!]
	][
probe "dns/inser"
		switch TYPE_OF(value) [
			TYPE_BINARY [
				bin: as red-binary! value
				io/pin-memory bin/node
			]
			default [return as red-value! port]
		]

		data: get-dns-data port
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
		io/pin-memory buf/node
		s: GET_BUFFER(buf)
		data: as iocp-data! get-dns-data red-port
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
