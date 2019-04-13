Red/System [
	Title:	"usb port! implementation on Windows"
	Author: "bitbegin"
	File: 	%windows.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

usb-windows: context [

	GUID_DEVINTERFACE_USB_HOST_CONTROLLER: declare UUID!
	GUID_DEVINTERFACE_USB_DEVICE: declare UUID!
	GUID_DEVINTERFACE_USB_HUB: declare UUID!



	DEVICE-GUID-LIST!: alias struct! [
		list-head		[list-entry! value]
		dev-info		[int-ptr!]
	]

	DEVICE-INFO-NODE!: alias struct! [
		entry				[list-entry! value]
		dev-info			[int-ptr!]
		dev-info-data		[DEV-INFO-DATA! value]
		dev-interface-data	[DEV-INTERFACE-DATA! value]
		detail-data			[DEV-INTERFACE-DETAIL!]
		desc-name			[c-string!]
		desc-name-len		[integer!]
		driver-name			[c-string!]
		driver-name-len		[integer!]
		latest-power-state	[integer!]
	]

	#enum DEVICE-POWER-STATE! [
		PowerDeviceUnspecified: 0
		PowerDeviceD0
		PowerDeviceD1
		PowerDeviceD2
		PowerDeviceD3
		PowerDeviceMaximum
	]

	device-list: declare DEVICE-GUID-LIST!
	hub-list: declare DEVICE-GUID-LIST!

	clear-device-list: func [
		list		[DEVICE-GUID-LIST!]
		/local
			l		[list-entry!]
			p		[list-entry!]
			q		[list-entry!]
			node	[DEVICE-INFO-NODE!]
	][
		if list/dev-info <> null [
			SetupDiDestroyDeviceInfoList list/dev-info
			list/dev-info: null
		]
		l: list/list-head
		p: l/next
		while [p <> l][
			q: p/next
			free-device-info-node as DEVICE-INFO-NODE! p
			p: q
		]
		l/next: l
		l/prev: l
	]

	free-device-info-node: func [
		pNode		[DEVICE-INFO-NODE!]
	][
		if pNode = null [exit]
		if pNode/detail-data <> null [
			free as byte-ptr! pNode/detail-data
		]
		if pNode/desc-name <> null [
			free as byte-ptr! pNode/desc-name
		]
		if pNode/driver-name <> null [
			free as byte-ptr! pNode/driver-name
		]
		free as byte-ptr! pNode
	]

	enum-devices-with-guid: func [
		device-list		[DEVICE-GUID-LIST!]
		guid			[UUID!]
		/local
			index		[integer!]
			error		[integer!]
			success		[logic!]
			pNode		[DEVICE-INFO-NODE!]
			bResult		[logic!]
			reqLen		[integer!]
			pbuffer		[integer!]
			buf			[byte-ptr!]
	][
		if device-list/dev-info <> null [
			clear-device-list device-list
		]
		device-list/dev-info: SetupDiGetClassDevs guid null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		if device-list/dev-info = null [exit]
		index: 0 error: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			pNode: as DEVICE-INFO-NODE! allocate size? DEVICE-INFO-NODE!
			if pNode = null [break]
			pNode/dev-info: device-list/dev-info
			pNode/dev-info-data/cbSize: size? DEV-INFO-DATA!
			pNode/dev-interface-data/cbSize: size? DEV-INTERFACE-DATA!
			success: SetupDiEnumDeviceInfo device-list/dev-info index pNode/dev-info-data
			index: index + 1
			either success = false [
				error: GetLastError
				free-device-info-node pNode
			][
				pbuffer: 0
				bResult: get-device-property device-list/dev-info pNode/dev-info-data
							SPDRP_DEVICEDESC :pbuffer
				if bResult = false [
					free-device-info-node pNode
					break
				]
				pNode/desc-name: as c-string! pbuffer
				bResult: get-device-property device-list/dev-info pNode/dev-info-data
							SPDRP_DRIVER :pbuffer
				if bResult = false [
					free-device-info-node pNode
					break
				]
				pNode/driver-name: as c-string! pbuffer

				success: SetupDiEnumDeviceInterfaces device-list/dev-info 0 guid index - 1
							pNode/dev-interface-data
				if success <> true [
					free-device-info-node pNode
					break
				]

				reqLen: 0
				success: SetupDiGetDeviceInterfaceDetail device-list/dev-info pNode/dev-interface-data
							null 0 :reqLen null
				error: GetLastError
				if all [
					success <> true
					error <> ERROR_INSUFFICIENT_BUFFER
				][
					free-device-info-node pNode
					break
				]
				buf: allocate reqLen
				if buf = null [
					free-device-info-node pNode
					break
				]
				pNode/detail-data: as DEV-INTERFACE-DETAIL! buf
				pNode/detail-data/cbSize: 5				; don't use size? DEV-INTERFACE-DETAIL!, as it's actual size = 5
				success: SetupDiGetDeviceInterfaceDetail device-list/dev-info pNode/dev-interface-data
							pNode/detail-data reqLen :reqLen null
				if success <> true [
					free-device-info-node pNode
					break
				]
				dlink/append device-list/list-head as list-entry! pNode
			]
		]
	]

	get-device-property: func [
		dev-info		[int-ptr!]
		info-data		[DEV-INFO-DATA!]
		property		[integer!]
		ppBuffer		[int-ptr!]
		return:			[logic!]
		/local
			bResult		[logic!]
			reqLen		[integer!]
			lastError	[integer!]
			buf			[byte-ptr!]
	][
		if ppBuffer = null [return false]
		ppBuffer/value: 0
		reqLen: 0
		bResult: SetupDiGetDeviceRegistryProperty dev-info info-data property
					null null 0 :reqLen
		lastError: GetLastError
		if any [
			reqLen = 0
			all [
				bResult <> false
				lastError <> ERROR_INSUFFICIENT_BUFFER
			]
		][return false]
		buf: allocate reqLen
		if buf = null [return false]
		ppBuffer/value: as integer! buf
		bResult: SetupDiGetDeviceRegistryProperty dev-info info-data property
					null as c-string! buf reqLen :reqLen
		if bResult = false [
			free buf
			ppBuffer/value: 0
			return false
		]
		true
	]


	init: does [
		UuidFromString "3ABF6F2D-71C4-462A-8A92-1E6861E6AF27" GUID_DEVINTERFACE_USB_HOST_CONTROLLER
		UuidFromString "A5DCBF10-6530-11D2-901F-00C04FB951ED" GUID_DEVINTERFACE_USB_DEVICE
		UuidFromString "F18A0E88-C30C-11D0-8815-00A0C906BED8" GUID_DEVINTERFACE_USB_HUB
		dlink/init device-list/list-head
		dlink/init hub-list/list-head
		device-list/dev-info: null
		hub-list/dev-info: null

	]
]