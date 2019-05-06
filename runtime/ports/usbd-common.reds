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
	USB-ERROR-HANDLE
	USB-ERROR-UNSUPPORT
	USB-ERROR-OPEN
	USB-ERROR-INIT
	USB-ERROR-MAX
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

INTERFACE-INFO-NODE!: alias struct! [
	entry				[list-entry! value]
	path				[c-string!]
	name				[byte-ptr!]
	name-len			[integer!]

	;-- platform
	inst				[integer!]

	;-- info
	interface-num		[integer!]
	collection-num		[integer!]
	hDev				[integer!]
	hInf				[integer!]
	hType				[DRIVER-TYPE!]
	bulk-in				[integer!]
	bulk-in-size		[integer!]
	bulk-out			[integer!]
	bulk-out-size		[integer!]
	interrupt-in		[integer!]
	interrupt-in-size	[integer!]
	interrupt-out		[integer!]
	interrupt-out-size	[integer!]
	usage				[integer!]
	usage-page			[integer!]
	input-size			[integer!]
	output-size			[integer!]
]

DEVICE-INFO-NODE!: alias struct! [
	entry				[list-entry! value]
	vid					[integer!]
	pid					[integer!]
	path				[c-string!]
	name				[byte-ptr!]
	name-len			[integer!]

	;-- platform
	serial-num			[c-string!]
	inst				[integer!]
	port				[integer!]

	;-- interface info
	interface-entry		[list-entry! value]
	interface			[INTERFACE-INFO-NODE!]
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
	;-- close interface before free the node
	;close-interface pNode
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
	if pNode/serial-num <> null [
		free as byte-ptr! pNode/serial-num
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
