Red/System [
	Title:	"usb port! implementation for win32"
	Author: "bitbegin"
	File: 	%usb-win32.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %usbd-win32.reds

USB-DATA!: alias struct! [
	ovlap	[OVERLAPPED! value]		;-- the overlapped struct
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
			;set-memory as byte-ptr! :data/ovlap null-byte size? OVERLAPPED!
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
		iodata: as USB-DATA! get-port-data red-port
		if null? iodata/buffer [
			if iodata/dev/interface/hType = DRIVER-TYPE-WINUSB [
				size: iodata/dev/interface/interrupt-in-size
				iodata/buffer: allocate size
				iodata/buflen: size
			]
			if iodata/dev/interface/hType = DRIVER-TYPE-HIDUSB [
				size: iodata/dev/interface/input-size
				iodata/buffer: allocate size
				iodata/buflen: size
			]
		]
		print-line "read"
		print-line iodata/buflen
		print-line iodata/fd
		iocp/bind g-poller as DATA-COMMON! iodata
		set-memory as byte-ptr! :iodata/ovlap null-byte size? OVERLAPPED!

		iodata/code: IOCP_OP_READ
		;dump-hex iodata/buffer
		n: 0
		if 0 <> usb-device/read-data iodata/dev/interface iodata/buffer iodata/buflen :n as OVERLAPPED! iodata 0 [
			exit
		]

		probe "usb read OK"
	]
	
	write: func [
		red-port	[red-object!]
		data		[red-value!]
		/local
			bin		[red-binary!]
			buf		[byte-ptr!]
			len		[integer!]
			iodata	[USB-DATA!]
			n		[integer!]
	][
		iodata: as USB-DATA! get-port-data red-port
		iocp/bind g-poller as DATA-COMMON! iodata
		set-memory as byte-ptr! :iodata/ovlap null-byte size? OVERLAPPED!
		print-line "write"

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
		if 0 <> usb-device/write-data iodata/dev/interface buf len :n as OVERLAPPED! iodata 0 [
			exit
		]

		probe "usb Write OK"
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
