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

	USB-DEVICE-PNP-STRINGS!: alias struct! [
		device-id			[byte-ptr!]
		device-id-len		[integer!]
		device-desc			[byte-ptr!]
		device-desc-len		[integer!]
		hw-id				[byte-ptr!]
		hw-id-len			[integer!]
		service				[byte-ptr!]
		service-len			[integer!]
		dev-class			[byte-ptr!]
		dev-class-len		[integer!]
	]

	DEVICE-INFO-NODE!: alias struct! [
		entry				[list-entry! value]
		dev-info			[int-ptr!]
		dev-info-data		[DEV-INFO-DATA! value]
		dev-interface-data	[DEV-INTERFACE-DATA! value]
		detail-data			[DEV-INTERFACE-DETAIL!]
		desc-name			[byte-ptr!]
		desc-name-len		[integer!]
		driver-name			[byte-ptr!]
		driver-name-len		[integer!]
		bus-number			[integer!]
		port				[integer!]
		dev-properties		[USB-DEVICE-PNP-STRINGS!]
	]

	device-list: declare DEVICE-GUID-LIST!

	clear-device-list: func [
		list		[DEVICE-GUID-LIST!]
		/local
			l		[list-entry!]
			p		[list-entry!]
			q		[list-entry!]
			node	[DEVICE-INFO-NODE!]
	][
		if list/dev-info <> INVALID_HANDLE [
			SetupDiDestroyDeviceInfoList list/dev-info
			list/dev-info: INVALID_HANDLE
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
		/local
			props	[USB-DEVICE-PNP-STRINGS!]
	][
		if pNode = null [exit]
		if pNode/detail-data <> null [
			free as byte-ptr! pNode/detail-data
		]
		if pNode/desc-name <> null [
			free pNode/desc-name
		]
		if pNode/driver-name <> null [
			free pNode/driver-name
		]
		props: pNode/dev-properties
		if props <> null [
			if props/device-id <> null [
				free props/device-id
			]
			if props/device-desc <> null [
				free props/device-desc
			]
			if props/hw-id <> null [
				free props/hw-id
			]
			if props/service <> null [
				free props/service
			]
			if props/dev-class <> null [
				free props/dev-class
			]
			free as byte-ptr! props
		]
		free as byte-ptr! pNode
	]

	enum-devices-with-guid: func [
		device-list		[DEVICE-GUID-LIST!]
		guid			[UUID!]
		/local
			dev-info	[int-ptr!]
			info-data	[DEV-INFO-DATA!]
			interface-data	[DEV-INTERFACE-DATA!]
			detail-data	[DEV-INTERFACE-DETAIL!]
			index		[integer!]
			error		[integer!]
			success		[logic!]
			pNode		[DEVICE-INFO-NODE!]
			bResult		[logic!]
			reqLen		[integer!]
			pbuffer		[integer!]
			plen		[integer!]
			buf			[byte-ptr!]
			port		[integer!]
			hub			[integer!]
	][
		if device-list/dev-info <> INVALID_HANDLE [
			clear-device-list device-list
		]
		dev-info: SetupDiGetClassDevs guid null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		device-list/dev-info: dev-info
		if dev-info = INVALID_HANDLE [exit]
		index: 0 error: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			pNode: as DEVICE-INFO-NODE! allocate size? DEVICE-INFO-NODE!
			if pNode = null [continue]
			pNode/dev-info: dev-info
			info-data: pNode/dev-info-data
			info-data/cbSize: size? DEV-INFO-DATA!
			interface-data: pNode/dev-interface-data
			interface-data/cbSize: size? DEV-INTERFACE-DATA!
			success: SetupDiEnumDeviceInfo dev-info index info-data
			index: index + 1
			either success = false [
				error: GetLastError
				free-device-info-node pNode
			][
				pbuffer: 0
				plen: 0
				bResult: get-device-property dev-info info-data
							SPDRP_DEVICEDESC :pbuffer :plen
				if bResult = false [
					free-device-info-node pNode
					continue
				]
				pNode/desc-name: as byte-ptr! pbuffer
				pNode/desc-name-len: plen
				bResult: get-device-property dev-info info-data
							SPDRP_DRIVER :pbuffer :plen
				if bResult = false [
					free-device-info-node pNode
					continue
				]
				pNode/driver-name: as byte-ptr! pbuffer
				pNode/driver-name-len: plen

				success: SetupDiEnumDeviceInterfaces dev-info 0 guid index - 1
							interface-data
				if success <> true [
					free-device-info-node pNode
					continue
				]

				reqLen: 0
				success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
							null 0 :reqLen null
				error: GetLastError
				if all [
					success <> true
					error <> ERROR_INSUFFICIENT_BUFFER
				][
					free-device-info-node pNode
					continue
				]
				buf: allocate reqLen
				if buf = null [
					free-device-info-node pNode
					continue
				]
				pNode/detail-data: as DEV-INTERFACE-DETAIL! buf
				detail-data: pNode/detail-data
				detail-data/cbSize: 5				; don't use size? DEV-INTERFACE-DETAIL!, as it's actual size = 5
				success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
							detail-data reqLen :reqLen null
				if success <> true [
					free-device-info-node pNode
					continue
				]
				pbuffer: 0
				plen: 0
				success: get-device-property-a dev-info info-data
							SPDRP_LOCATION_INFORMATION :pbuffer :plen
				either success <> true [
					hub: -1 port: -1
				][
					hub: 0 port: 0
					sscanf [pbuffer "Port_#%d.Hub_#%d" :port :hub]
				]
				pNode/port: port
				pNode/dev-properties: driver-name-to-device-props dev-info info-data
				dlink/append device-list/list-head as list-entry! pNode
			]
		]
	]

	get-device-property: func [
		dev-info		[int-ptr!]
		info-data		[DEV-INFO-DATA!]
		property		[integer!]
		ppBuffer		[int-ptr!]
		plen			[int-ptr!]
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
		bResult: SetupDiGetDeviceRegistryPropertyW dev-info info-data property
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
		bResult: SetupDiGetDeviceRegistryPropertyW dev-info info-data property
					null buf reqLen :reqLen
		if bResult = false [
			free buf
			ppBuffer/value: 0
			return false
		]
		plen/value: reqLen
		true
	]

	get-device-property-a: func [
		dev-info		[int-ptr!]
		info-data		[DEV-INFO-DATA!]
		property		[integer!]
		ppBuffer		[int-ptr!]
		plen			[int-ptr!]
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
					null buf reqLen :reqLen
		if bResult = false [
			free buf
			ppBuffer/value: 0
			return false
		]
		plen/value: reqLen
		true
	]

	driver-name-to-device-props: func [
		dev-info			[int-ptr!]
		info-data			[DEV-INFO-DATA!]
		return:					[USB-DEVICE-PNP-STRINGS!]
		/local
			len					[integer!]
			status				[logic!]
			dev-props			[USB-DEVICE-PNP-STRINGS!]
			last-error			[integer!]
			buf					[byte-ptr!]
			nbuf				[integer!]
			nlen				[integer!]
	][
		dev-props: as USB-DEVICE-PNP-STRINGS! allocate size? USB-DEVICE-PNP-STRINGS!
		if dev-props = null [
			return null
		]
		len: 0
		status: SetupDiGetDeviceInstanceId dev-info info-data null 0 :len
		last-error: GetLastError
		if all [
			status <> false
			last-error <> ERROR_INSUFFICIENT_BUFFER
		][
			free as byte-ptr! dev-props
			return null
		]
		len: len + 1
		buf: allocate len
		if buf = null [
			free as byte-ptr! dev-props
			return null
		]
		status: SetupDiGetDeviceInstanceId dev-info info-data
					buf len :len
		if status = false [
			free as byte-ptr! dev-props
			return null
		]
		dev-props/device-id: buf
		dev-props/device-id-len: len
		nbuf: 0
		nlen: 0
		status: get-device-property dev-info info-data
					SPDRP_DEVICEDESC :nbuf :nlen
		if status = false [
			free buf
			free as byte-ptr! dev-props
			return null
		]
		dev-props/device-desc: as byte-ptr! nbuf
		dev-props/device-desc-len: nlen
		nbuf: 0 nlen: 0
		get-device-property dev-info info-data SPDRP_HARDWAREID :nbuf :nlen
		dev-props/hw-id: as byte-ptr! nbuf
		dev-props/hw-id-len: nlen
		nbuf: 0 nlen: 0
		get-device-property dev-info info-data SPDRP_SERVICE :nbuf :nlen
		dev-props/service: as byte-ptr! nbuf
		dev-props/service-len: nlen
		nbuf: 0 nlen: 0
		get-device-property dev-info info-data SPDRP_CLASS :nbuf :nlen
		dev-props/dev-class: as byte-ptr! nbuf
		dev-props/dev-class-len: nlen
		dev-props
	]

	enum-all-devices: does [
		enum-devices-with-guid device-list GUID_DEVINTERFACE_USB_DEVICE
	]

	init: does [
		UuidFromString "3ABF6F2D-71C4-462A-8A92-1E6861E6AF27" GUID_DEVINTERFACE_USB_HOST_CONTROLLER
		UuidFromString "A5DCBF10-6530-11D2-901F-00C04FB951ED" GUID_DEVINTERFACE_USB_DEVICE
		UuidFromString "F18A0E88-C30C-11D0-8815-00A0C906BED8" GUID_DEVINTERFACE_USB_HUB
		dlink/init device-list/list-head
		device-list/dev-info: INVALID_HANDLE

	]
]
