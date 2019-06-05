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
	data?	[logic!]
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
			len			[integer!]
			node		[DEVICE-INFO-NODE!]
			data		[USB-DATA!]
	][
		sn: as c-string! alloc0 256
		n: -1
		s: unicode/to-utf8 host :n
		vid: 0 pid: 0 mi: 0
		len: sscanf [s "VID=%4hx&PID=%4hx&MI=%2hx&SN=%s"
			:vid :pid :mi sn]
		if len <> 4 [exit]
		node: usb-device/open vid pid sn mi
		if node = null [exit]
		dlink/append usb-list as list-entry! node
		data: as USB-DATA! alloc0 size? USB-DATA!
		copy-cell as cell! red-port as cell! :data/cell
		data/dev: node
		store-port-data as int-ptr! data red-port
	]

	read: func [
		red-port	[red-object!]
		/local
			iodata	[USB-DATA!]
			col		[integer!]
			size	[integer!]
			paddr	[integer!]
			ptype	[integer!]
			n		[integer!]
	][
		iodata: as USB-DATA! get-port-data red-port
		if all [
			iodata/dev/interface/type <> USB-DRIVER-TYPE-HIDUSB
			iodata/dev/interface/type <> USB-DRIVER-TYPE-WINUSB
		][exit]

		either iodata/dev/interface/type = USB-DRIVER-TYPE-HIDUSB [
			col: get-port-collection red-port
			usb-select-collection iodata/dev/interface col
			size: iodata/dev/interface/collection/input-size
			iodata/fd: iodata/dev/interface/collection/handle
		][
			paddr: -1 ptype: -1
			get-port-pipe red-port :paddr :ptype
			usb-select-pipe iodata/dev/interface paddr ptype yes
			iodata/dev/interface/report-type: get-port-feature red-port
			size: get-port-read-size red-port
			iodata/fd: iodata/dev/interface/handle
		]
		if any [
			null? iodata/buffer
			size > iodata/buflen
		][
			unless null? iodata/buffer [
				free iodata/buffer
			]
			iodata/buffer: allocate size
			iodata/buflen: size
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
			print-line "read failed"
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
			col		[integer!]
			size	[integer!]
			iodata	[USB-DATA!]
			paddr	[integer!]
			ptype	[integer!]
			n		[integer!]
	][
		iodata: as USB-DATA! get-port-data red-port
		if all [
			iodata/dev/interface/type <> USB-DRIVER-TYPE-HIDUSB
			iodata/dev/interface/type <> USB-DRIVER-TYPE-WINUSB
		][exit]

		either iodata/dev/interface/type = USB-DRIVER-TYPE-HIDUSB [
			col: get-port-collection red-port
			usb-select-collection iodata/dev/interface col
			size: iodata/dev/interface/collection/input-size
			iodata/fd: iodata/dev/interface/collection/handle
		][
			paddr: -1 ptype: -1
			get-port-pipe red-port :paddr :ptype
			usb-select-pipe iodata/dev/interface paddr ptype yes
			iodata/dev/interface/report-type: get-port-feature red-port
			size: get-port-read-size red-port
			iodata/fd: iodata/dev/interface/handle
		]

		len: 0
		switch TYPE_OF(data) [
			TYPE_BINARY [
				bin: as red-binary! data
				len: binary/rs-length? bin
				buf: binary/rs-head bin
			]
			TYPE_STRING [0]
			default [0]
		]

		if len = 0 [
			exit
		]

		iodata/data?: false
		if all [
			iodata/dev/interface/type = USB-DRIVER-TYPE-WINUSB
			any [
				iodata/dev/interface/endpoint/type = USB-PIPE-TYPE-CONTROL
				iodata/dev/interface/endpoint/address = 0
			]
		][
			either 80h <= as integer! buf/1 [
				;control read
				size: get-port-read-size red-port
				iodata/data?: true
			][
				size: 0
			]
			unless null? iodata/buffer [
				free iodata/buffer
			]
			iodata/buffer: allocate size + len
			iodata/buflen: size + len
			copy-memory iodata/buffer buf len
			buf: iodata/buffer
			len: iodata/buflen
		]
		if all [
			iodata/dev/interface/type = USB-DRIVER-TYPE-HIDUSB
			any [
				iodata/dev/interface/report-type = HID-GET-FEATURE
				iodata/dev/interface/report-type = HID-GET-REPORT
			]
		][
			unless null? iodata/buffer [
				free iodata/buffer
			]
			size: get-port-read-size red-port
			iodata/data?: true
			iodata/buffer: allocate size
			iodata/buflen: size
			iodata/buffer/1: buf/1
			buf: iodata/buffer
			len: iodata/buflen
		]

		print-line "write"
		iocp/bind g-poller as DATA-COMMON! iodata
		set-memory as byte-ptr! :iodata/ovlap null-byte size? OVERLAPPED!
		iodata/code: IOCP_OP_WRITE
		n: 0
		if 0 <> usb-device/write-data iodata/dev/interface buf len :n as OVERLAPPED! iodata 0 [
			print-line "write failed"
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
