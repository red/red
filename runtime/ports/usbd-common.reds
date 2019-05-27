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
#enum DRIVER-TYPE! [
	DRIVER-TYPE-NONE
	;DRIVER-TYPE-GEN
	DRIVER-TYPE-WINUSB
	DRIVER-TYPE-HIDUSB
	;DRIVER-TYPE-KBDHID
	;DRIVER-TYPE-MOUHID
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
	;-- report id
	report-id			[integer!]
]

ENDPOINT-INFO!: alias struct! [
	;-- address
	bulk-in				[integer!]
	;-- max package size
	bulk-in-size		[integer!]
	bulk-out			[integer!]
	bulk-out-size		[integer!]
	interrupt-in		[integer!]
	interrupt-in-size	[integer!]
	interrupt-out		[integer!]
	interrupt-out-size	[integer!]
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
	hType				[DRIVER-TYPE!]

	;-- endpoint info (for generic interface)
	endpoints			[ENDPOINT-INFO! value]

	;-- hid collection list
	collection-entry	[list-entry! value]
	;-- selected collection
	collection			[HID-COLLECTION-NODE!]

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
	if pNode/collection <> null [
		free-collection-info-node pNode/collection
	]
	clear-collection-list pNode/collection-entry
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
