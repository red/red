Red/System [
	Title:	"usb port! common"
	Author: "bitbegin"
	File: 	%usbd-common.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]
#enum USB-DRIVER-TYPE! [
	USB-DRIVER-TYPE-NONE
	;USB-DRIVER-TYPE-GEN
	USB-DRIVER-TYPE-WINUSB
	USB-DRIVER-TYPE-HIDUSB
	;USB-DRIVER-TYPE-KBDHID
	;USB-DRIVER-TYPE-MOUHID
]

#enum USB-ERROR! [
	USB-ERROR-OK
	USB-ERROR-PATH
	USB-ERROR-HANDLE
	USB-ERROR-UNSUPPORT
	USB-ERROR-OPEN
	USB-ERROR-INIT
	USB-ERROR-MAX
]

#enum USB-NODE-TYPE! [
	USB-NODE-TYPE-DEVICE
	USB-NODE-TYPE-INTERFACE
	USB-NODE-TYPE-COLLECTION
	USB-NODE-TYPE-ENDPOINT
]

#enum USB-PIPE-TYPE! [
	USB-PIPE-TYPE-CONTROL
	USB-PIPE-TYPE-ISOCH
	USB-PIPE-TYPE-BULK
	USB-PIPE-TYPE-INTERRUPT
	USB-PIPE-TYPE-INVALID
]

#enum HID-REPORT-TYPE! [
	HID-GET-FEATURE
	HID-SET-FEATURE
	HID-GET-REPORT
	HID-SET-REPORT
	HID-REPORT-TYPE-INVALID
]

USB-DESCRIPTION!: alias struct! [
	device-desc			[byte-ptr!]
	device-desc-len		[integer!]
	config-desc			[byte-ptr!]
	config-desc-len		[integer!]
	language-id			[integer!]
	vendor-str			[byte-ptr!]
	vendor-str-len		[integer!]
	product-str			[byte-ptr!]
	product-str-len		[integer!]
	serial-str			[byte-ptr!]
	serial-str-len		[integer!]
]

HID-COLLECTION-NODE!: alias struct! [
	entry				[list-entry! value]
	;-- collection index
	index				[integer!]
	;-- top usage/page
	usage				[integer!]
	usage-page			[integer!]
	;-- report size
	input-size			[integer!]
	output-size			[integer!]
	;-- for macos
	input-buffer		[byte-ptr!]
	;-- report id
	report-id			[integer!]
]

ENDPOINT-INFO-NODE!: alias struct! [
	entry				[list-entry! value]
	address				[integer!]
	type				[USB-PIPE-TYPE!]
	max-size			[integer!]
]

INTERFACE-INFO-NODE!: alias struct! [
	entry				[list-entry! value]
	;-- interface num
	index				[integer!]
	;-- for open
	path				[c-string!]
	;-- for display
	name				[byte-ptr!]
	name-len			[integer!]
	;-- syspath for linux
	syspath				[c-string!]
	;-- platform id for win32/macos
	inst				[integer!]
	;-- platform id 2 for macos
	inst2				[integer!]

	;-- open handle
	hDev				[integer!]
	;-- opend handle 2
	hInf				[integer!]
	;-- interface type
	hType				[USB-DRIVER-TYPE!]

	;-- endpoint info (for generic interface)
	endpoint-entry		[list-entry! value]
	;-- dynamic selected pipe
	endpoint			[ENDPOINT-INFO-NODE! value]

	;-- hid collection list
	collection-entry	[list-entry! value]
	;-- selected collection
	collection			[HID-COLLECTION-NODE! value]

	;-- for hid report
	report-type			[HID-REPORT-TYPE!]

	;-- read/write thread info
	read-thread			[int-ptr!]
	write-thread		[int-ptr!]
]

DEVICE-INFO-NODE!: alias struct! [
	entry				[list-entry! value]
	vid					[integer!]
	pid					[integer!]
	;-- for open
	path				[c-string!]
	;-- for display
	name				[byte-ptr!]
	name-len			[integer!]
	;-- syspath for linux
	syspath				[c-string!]

	;-- platform
	serial-num			[c-string!]
	inst				[integer!]
	inst2				[integer!]
	port				[integer!]

	;-- interface list or selected interface
	interface-entry		[list-entry! value]
	;-- selected interface
	interface			[INTERFACE-INFO-NODE!]
	;-- offline
	offline				[logic!]
]

clear-device-list: func [
	list		[list-entry!]
	/local
		p		[list-entry!]
		q		[list-entry!]
		node	[DEVICE-INFO-NODE!]
][
	p: list/next
	while [p <> list][
		q: p/next
		free-device-info-node as DEVICE-INFO-NODE! p
		p: q
	]
	list/next: list
	list/prev: list
]

clear-interface-list: func [
	list		[list-entry!]
	/local
		p		[list-entry!]
		q		[list-entry!]
		node	[INTERFACE-INFO-NODE!]
][
	p: list/next
	while [p <> list][
		q: p/next
		free-interface-info-node as INTERFACE-INFO-NODE! p
		p: q
	]
	list/next: list
	list/prev: list
]

clear-collection-list: func [
	list		[list-entry!]
	/local
		p		[list-entry!]
		q		[list-entry!]
		node	[HID-COLLECTION-NODE!]
][
	p: list/next
	while [p <> list][
		q: p/next
		free-collection-info-node as HID-COLLECTION-NODE! p
		p: q
	]
	list/next: list
	list/prev: list
]

free-collection-info-node: func [
	pNode		[HID-COLLECTION-NODE!]
][
	if pNode = null [exit]
	if pNode/input-buffer <> null [
		free pNode/input-buffer
	]
	free as byte-ptr! pNode
]

clear-endpoint-list: func [
	list		[list-entry!]
	/local
		p		[list-entry!]
		q		[list-entry!]
		node	[ENDPOINT-INFO-NODE!]
][
	p: list/next
	while [p <> list][
		q: p/next
		free-endpoint-info-node as ENDPOINT-INFO-NODE! p
		p: q
	]
	list/next: list
	list/prev: list
]

free-endpoint-info-node: func [
	pNode		[ENDPOINT-INFO-NODE!]
][
	if pNode = null [exit]
	free as byte-ptr! pNode
]

free-interface-info-node: func [
	pNode		[INTERFACE-INFO-NODE!]
][
	if pNode = null [exit]
	if pNode/path <> null [
		free as byte-ptr! pNode/path
	]
	if pNode/name <> null [
		free pNode/name
	]
	if pNode/syspath <> null [
		free as byte-ptr! pNode/syspath
	]
	if pNode/read-thread <> null [
		free as byte-ptr! pNode/read-thread
	]
	if pNode/write-thread <> null [
		free as byte-ptr! pNode/write-thread
	]
	clear-collection-list pNode/collection-entry
	clear-endpoint-list pNode/endpoint-entry
	free as byte-ptr! pNode
]

free-device-info-node: func [
	pNode		[DEVICE-INFO-NODE!]
][
	if pNode = null [exit]
	if pNode/path <> null [
		free as byte-ptr! pNode/path
	]
	if pNode/name <> null [
		free pNode/name
	]
	if pNode/syspath <> null [
		free as byte-ptr! pNode/syspath
	]
	if pNode/serial-num <> null [
		free as byte-ptr! pNode/serial-num
	]
	if pNode/interface <> null [
		free-interface-info-node pNode/interface
	]
	clear-interface-list pNode/interface-entry
	free as byte-ptr! pNode
]

free-description: func [
	desc				[USB-DESCRIPTION!]
][
	if desc/device-desc <> null [free desc/device-desc]
	if desc/config-desc <> null [free desc/config-desc]
	if desc/vendor-str <> null [free desc/vendor-str]
	if desc/product-str <> null [free desc/product-str]
	if desc/serial-str <> null [free desc/serial-str]
	free as byte-ptr! desc
]

usb-find-pipe-by-address: func [
	list					[list-entry!]
	address					[integer!]
	return:					[ENDPOINT-INFO-NODE!]
	/local
		p					[list-entry!]
		node				[ENDPOINT-INFO-NODE!]
][
	p: list/next
	while [p <> list][
		node: as ENDPOINT-INFO-NODE! p
		if node/address = address [
			return node
		]
		p: p/next
	]
	null
]

usb-find-pipe-by-type: func [
	list					[list-entry!]
	type					[USB-PIPE-TYPE!]
	read?					[logic!]
	return:					[ENDPOINT-INFO-NODE!]
	/local
		p					[list-entry!]
		node				[ENDPOINT-INFO-NODE!]
		read2?				[logic!]
][
	p: list/next
	while [p <> list][
		node: as ENDPOINT-INFO-NODE! p
		either node/address > 127 [read2?: true][read2?: false]
		if all [
			node/type = type
			read2? = read?
		][
			return node
		]
		p: p/next
	]
	null
]

usb-select-pipe: func [
	pNode					[INTERFACE-INFO-NODE!]
	address					[integer!]
	type					[integer!]
	read?					[logic!]
	return:					[logic!]
	/local
		node				[ENDPOINT-INFO-NODE!]
][
	if all [
		pNode/hType = USB-DRIVER-TYPE-HIDUSB
		any [
			address <> 0
			all [
				type <> USB-PIPE-TYPE-CONTROL
				type <> USB-PIPE-TYPE-INVALID
			]
		]
	][
		pNode/endpoint/address: 1
		pNode/endpoint/type: USB-PIPE-TYPE-INTERRUPT
		return true
	]
	if all [
		address > 0
		address < 256
	][
		either read? [
			address: address or 80h
		][
			address: address and 7Fh
		]
		node: usb-find-pipe-by-address pNode/endpoint-entry address
		if node <> null [
			copy-memory as byte-ptr! pNode/endpoint as byte-ptr! node size? ENDPOINT-INFO-NODE!
			return true
		]
	]
	if all [
		type > USB-PIPE-TYPE-CONTROL
		type < USB-PIPE-TYPE-INVALID
	][
		node: usb-find-pipe-by-type pNode/endpoint-entry type read?
		if node <> null [
			copy-memory as byte-ptr! pNode/endpoint as byte-ptr! node size? ENDPOINT-INFO-NODE!
			return true
		]
	]
	pNode/endpoint/address: 0
	pNode/endpoint/type: USB-PIPE-TYPE-CONTROL
	false
]
