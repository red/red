Red/System [
	Title:	"usb port! implementation for macos"
	Author: "bitbegin"
	File: 	%usb-macos.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %usbd-macos.reds

USB-DATA!: alias struct! [
	cell	[cell! value]			;-- the port! cell
	fd		[integer!]
	port	[int-ptr!]				;-- the bound iocp port
	dev		[DEVICE-INFO-NODE!]
	buflen	[integer!]				;-- buffer length
	buffer	[byte-ptr!]				;-- buffer for iocp poller
	code	[integer!]				;-- operation code @@ change to uint8
	state	[integer!]				;-- @@ change to unit8
]

usb-list: declare list-entry!
usb: context [
	init: does [
		usb-device/init
		dlink/init usb-list
	]

	open: func [
		red-port		[red-object!]
		host			[red-string!]
		/local
			n			[integer!]
			s			[c-string!]
			vid			[integer!]
			pid			[integer!]
			sn			[c-string!]
			mi			[integer!]
			col			[integer!]
			node		[DEVICE-INFO-NODE!]
			data		[USB-DATA!]
	][
		sn: as c-string! alloc0 256
		n: -1
		s: unicode/to-utf8 host :n
		vid: 65535
		pid: 65535
		mi: 255
		col: 255
		sscanf [s "VID=%4hx&PID=%4hx&MI=%2hx&COL=%2hx&SN=%s"
			:vid :pid :mi :col sn]
		if all [
			vid <> 65535
			pid <> 65535
		][
			node: usb-device/open vid pid sn mi col
			if node = null [exit]
			dlink/append usb-list as list-entry! node
			data: as USB-DATA! alloc0 size? USB-DATA!
			copy-cell as cell! red-port as cell! :data/cell
			data/dev: node
			store-port-data as int-ptr! data red-port
			data/fd: node/interface/hDev
		]
	]
	read: func [
		red-port	[red-object!]
		/local
			iodata	[USB-DATA!]
			size	[integer!]
			n		[integer!]
	][

	]

	write: func [
		red-port	[red-object!]
		data		[red-value!]
		/local
			bin		[red-binary!]
			buf		[byte-ptr!]
			len		[integer!]
			iodata	[USB-DATA!]
			evalue	[kevent! value]
			hDev	[integer!]
			fflags	[integer!]
			n		[integer!]
	][
		iodata: as USB-DATA! get-port-data red-port
		print-line "write"
		hDev: iodata/dev/interface/hDev
		fflags: EV_ADD or EV_ENABLE or EV_CLEAR
		EV_SET(:evalue hDev EVFILT_USER fflags 0 NULL NULL)
		poll/_modify g-poller :evalue 1
		switch TYPE_OF(data) [
			TYPE_BINARY [
				bin: as red-binary! data
				len: binary/rs-length? bin
				buf: binary/rs-head bin
			]
			TYPE_STRING [0]
			default [0]
		]

		iodata/code: IOCP_OP_WRITE
		n: 0
		if 0 <> usb-device/write-data iodata/dev/interface buf len :n as int-ptr! :write-callback 0 as int-ptr! iodata [
			exit
		]

		probe "usb Write OK"
	]

	write-callback: func [
		[cdecl]
		context					[int-ptr!]
		result					[integer!]
		sender					[int-ptr!]
		report_type				[integer!]
		report_id				[integer!]
		report					[byte-ptr!]
		report_length			[integer!]
		/local
			iodata				[USB-DATA!]
			evalue				[kevent! value]
			hDev				[integer!]
	][
		iodata: as USB-DATA! context
		hDev: iodata/dev/interface/hDev
		EV_SET(evalue hDev EVFILT_USER 0 NOTE_TRIGGER NULL NULL)
		poll/_modify g-poller :evalue 1
	]

	close: func [
		red-port	[red-object!]
		/local
			iodata	[USB-DATA!]
	][
		iodata: as USB-DATA! get-port-data red-port
		if iodata/buffer <> null [
			free iodata/buffer
			iodata/buffer: null
		]
		usb-device/close-interface iodata/dev/interface
		dlink/remove usb-list as list-entry! iodata/dev
		free-device-info-node as DEVICE-INFO-NODE! iodata/dev
	]
]
