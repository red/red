Red/System [
	Title:	"FILE port"
	Author: "Xie Qingtian"
	File: 	%file.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

file-device: context [
	verbose: 1

	event-handler: func [
		data		[iocp-data!]
		/local
			p		[red-object!]
			msg		[red-object!]
			file	[file-data!]
			type	[integer!]
			bin		[red-binary!]
			s		[series!]
			ser1	[red-series!]
			ser2	[red-series!]
	][
		file: as file-data! data
		p: as red-object! :file/port
		msg: p
		type: data/event
probe "FILE event-handler"
		switch type [
			IO_EVT_READ	[
				bin: as red-binary! (object/get-values p) + port/field-data
				s: GET_BUFFER(bin)
probe ["read data: " data/transferred]
				s/tail: as cell! (as byte-ptr! s/offset) + data/transferred
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
				io/unpin-memory file/buffer
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

	create-file-data: func [
		port	[red-object!]
		sock	[integer!]
		return: [file-data!]
		/local
			data	[file-data!]
			saddr	[sockaddr_in!]
	][
		data: as file-data! io/create-socket-data port sock as int-ptr! :event-handler size? file-data!
		data/type: IOCP_TYPE_FILE
		data
	]

	get-file-data: func [
		red-port	[red-object!]
		return:		[file-data!]
		/local
			state	[red-handle!]
			data	[iocp-data!]
			new		[file-data!]
	][
		state: as red-handle! (object/get-values red-port) + port/field-state
		if TYPE_OF(state) <> TYPE_HANDLE [
			probe "ERROR: No low-level handle"
			0 ;; TBD throw error
		]

		#either OS = 'Windows [
			data: as iocp-data! state/value
			either data/event = IO_EVT_NONE [		;-- we can reuse this one
				as file-data! data
			][										;-- needs to create a new one
				new: as file-data! alloc0 size? file-data!
				new/event-handler: as iocp-event-handler! :event-handler
				new/device: data/device
				new/accept-sock: PENDING_IO_FLAG	;-- use it as a flag to indicate pending data
				copy-cell as cell! red-port as cell! :new/port
				new
			]
		][
			as file-data! state/value
		]
	]

	open-file: func [
		port		[red-object!]
		pathname	[c-string!]
		flags		[integer!]
		/local
			fd		[integer!]
			data	[file-data!]
	][
		fd: simple-io/open-file pathname flags yes
		data: create-file-data port fd
		data/event: IO_EVT_CONNECT
		if fd > 0 [iocp/post g-iocp as iocp-data! data]
	]

	read-file: func [
		data		[file-data!]
		/local
			s		[series!]
			len		[integer!]
	][
		s: as series! data/buffer/value
		len: simple-io/read-data as-integer data/device as byte-ptr! s/offset 1024 * 64
		if zero? len[data/event: IO_EVT_ERROR]
		data/transferred: len
		iocp/post g-iocp as iocp-data! data
	]

	write-file: func [
		data		[file-data!]
		/local
			s		[series!]
			len		[integer!]
	][
		s: as series! data/buffer/value
		len: as-integer s/tail - s/offset
		len: simple-io/write-data as-integer data/device as byte-ptr! s/offset len
		if len < 0 [
			len: 0
			data/event: IO_EVT_ERROR
		]
		data/transferred: len
		iocp/post g-iocp as iocp-data! data
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
			fpath	[red-string!]
			flags	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/open"]]

		values: object/get-values red-port
		state: as red-handle! values + port/field-state
		if TYPE_OF(state) <> TYPE_NONE [return as red-value! red-port]

		spec:	as red-object! values + port/field-spec
		values: object/get-values spec
		fpath:	as red-string! values + 4

		string/concatenate fpath as red-string! values + 5 -1 0 yes no
		flags: 1
		if write? [flags: 2]
		open-file red-port file/to-OS-path fpath flags
		as red-value! red-port
	]

	close: func [
		red-port	[red-object!]
		return:		[red-value!]
		/local
			data	[iocp-data!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/close"]]

		data: io/get-iocp-data red-port
		if data <> null [simple-io/close-file as-integer data/device]
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
			data	[file-data!]
			bin		[red-binary!]
			n		[integer!]
	][
		switch TYPE_OF(value) [
			TYPE_BINARY [
				bin: as red-binary! value
				io/pin-memory bin/node
			]
			default [return as red-value! port]
		]

		data: get-file-data port
		data/buffer: bin/node
		data/event: IO_EVT_WRITE

		threadpool/add-task as int-ptr! :write-file as int-ptr! data

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
			fobj	[file-data!]
			buf		[red-binary!]
			s		[series!]
	][
		buf: as red-binary! (object/get-values red-port) + port/field-data
		if TYPE_OF(buf) <> TYPE_BINARY [
			binary/make-at as cell! buf 1024 * 64
		]
		buf/head: 0
		io/pin-memory buf/node
		fobj: get-file-data red-port
		fobj/buffer: buf/node
		fobj/event: IO_EVT_READ

		threadpool/add-task as int-ptr! :read-file as int-ptr! fobj

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
