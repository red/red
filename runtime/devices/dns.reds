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
			IO_EVT_RESOLVED	[
				probe "resolved"
			]
			default [data/event: IO_EVT_NONE]
		]

		io/call-awake p msg type
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

	make-resolver: func [
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
		create-dns-data port fd addr num/value
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

		make-resolver red-port host num

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
probe "dns/insert"
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
