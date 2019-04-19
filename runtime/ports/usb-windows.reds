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
		vid					[integer!]
		pid					[integer!]
		serial-num			[c-string!]
		hub-path			[c-string!]
		hub-handle			[integer!]
		device-desc			[byte-ptr!]
		device-desc-len		[integer!]
		config-desc			[byte-ptr!]
		config-desc-len		[integer!]
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
		if pNode/serial-num <> null [
			free as byte-ptr! pNode/serial-num
		]
		if pNode/hub-path <> null [
			free as byte-ptr! pNode/hub-path
		]
		if pNode/config-desc <> null [
			free pNode/config-desc
		]
		if pNode/device-desc <> null [
			free pNode/device-desc
		]
		free as byte-ptr! pNode
	]

	enum-devices-with-guid: func [
		device-list			[DEVICE-GUID-LIST!]
		guid				[UUID!]
		/local
			dev-info		[int-ptr!]
			info-data		[DEV-INFO-DATA!]
			interface-data	[DEV-INTERFACE-DATA!]
			detail-data		[DEV-INTERFACE-DETAIL!]
			index			[integer!]
			error			[integer!]
			success			[logic!]
			pNode			[DEVICE-INFO-NODE!]
			bResult			[logic!]
			reqLen			[integer!]
			pbuffer			[integer!]
			plen			[integer!]
			buf				[byte-ptr!]
			port			[integer!]
			hub				[integer!]
			dev-props		[USB-DEVICE-PNP-STRINGS!]
			vid				[integer!]
			pid				[integer!]
			serial			[c-string!]
			inst			[integer!]
			dev-path		[c-string!]
			rint			[integer!]
			hHub			[integer!]
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
			set-memory as byte-ptr! pNode null-byte size? DEVICE-INFO-NODE!
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
				dev-props: driver-name-to-device-props dev-info info-data
				pNode/dev-properties: dev-props
				if dev-props <> null [
					pid: 0
					vid: 0
					serial: as c-string! allocate length? as c-string! dev-props/device-id
					sscanf [dev-props/device-id "USB\VID_%x&PID_%x\%s"
						:vid :pid serial]
					pNode/vid: vid
					pNode/pid: pid
					pNode/serial-num: serial
				]
				inst: 0
				rint: CM_Get_Parent :inst info-data/DevInst 0
				if all [
					rint = 0
					port <> -1
				][
					dev-path: get-hub-detail inst
					pNode/hub-path: dev-path
					if dev-path <> null [
						hHub: CreateFileA dev-path GENERIC_WRITE FILE_SHARE_WRITE null
								OPEN_EXISTING 0 null
						if hHub <> -1 [
							buf: get-config-desc hHub port 0 :plen
							if buf <> null [
								pNode/config-desc: buf
								pNode/config-desc-len: plen
							]
							buf: get-device-desc hHub port 0 :plen
							if buf <> null [
								pNode/device-desc: buf
								pNode/device-desc-len: plen
							]
						]
						CloseHandle as int-ptr! hHub
					]
				]
				dlink/append device-list/list-head as list-entry! pNode
			]
		]
	]

	get-hub-detail: func [
		inst			[integer!]
		return:			[c-string!]
		/local
			dev-info		[int-ptr!]
			info-data		[DEV-INFO-DATA! value]
			interface-data	[DEV-INTERFACE-DATA! value]
			detail-data		[DEV-INTERFACE-DETAIL!]
			index			[integer!]
			error			[integer!]
			success			[logic!]
			reqLen			[integer!]
			buf				[byte-ptr!]
			ret				[c-string!]
	][
		dev-info: SetupDiGetClassDevs GUID_DEVINTERFACE_USB_HUB null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		if dev-info = INVALID_HANDLE [
			return null
		]
		index: 0 error: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			info-data/cbSize: size? DEV-INFO-DATA!
			interface-data/cbSize: size? DEV-INTERFACE-DATA!
			success: SetupDiEnumDeviceInfo dev-info index info-data
			index: index + 1
			either success = false [
				error: GetLastError
			][
				if info-data/DevInst = inst [
					success: SetupDiEnumDeviceInterfaces dev-info 0 GUID_DEVINTERFACE_USB_HUB index - 1
								interface-data
					if success <> true [
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
						continue
					]
					buf: allocate reqLen
					if buf = null [
						continue
					]
					detail-data: as DEV-INTERFACE-DETAIL! buf
					detail-data/cbSize: 5				; don't use size? DEV-INTERFACE-DETAIL!, as it's actual size = 5
					success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
								detail-data reqLen :reqLen null
					if success <> true [
						free buf
						continue
					]
					ret: as c-string! allocate reqLen - 4
					copy-memory as byte-ptr! ret buf + 4 reqLen - 4
					free buf
					return ret
				]
			]
		]
		null
	]

	get-device-desc: func [
		hHub			[integer!]
		port			[integer!]
		config			[integer!]
		plen			[int-ptr!]
		return:			[byte-ptr!]
		/local
			success		[logic!]
			bytes		[integer!]
			bytes-ret	[integer!]
			req-buf		[byte-ptr!]
			desc-req	[USB-DESCRIPTOR-REQUEST!]
			desc		[USB-DEVICE-DESCRIPTOR!]
			ret			[byte-ptr!]
	][
		bytes: (size? USB-DESCRIPTOR-REQUEST!) + size? USB-DEVICE-DESCRIPTOR!
		req-buf: allocate bytes
		if req-buf = null [return null]
		bytes-ret: 0
		set-memory req-buf null-byte 12
		bytes: 12 + 18
		desc-req: as USB-DESCRIPTOR-REQUEST! req-buf
		desc: as USB-DEVICE-DESCRIPTOR! (req-buf + 12)
		desc-req/port: port
		desc-req/wValue1: as byte! config
		desc-req/wValue2: USB_DEVICE_DESCRIPTOR_TYPE
		desc-req/wLength1: #"^(12)"
		desc-req/wLength2: #"^(00)"

		success: DeviceIoControl as int-ptr! hHub IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION as byte-ptr! desc-req bytes
					as byte-ptr! desc-req bytes :bytes-ret null
		if success <> true [
			free req-buf
			return null
		]
		if bytes-ret <> 30 [
			free req-buf
			return null
		]
		plen/value: 18
		ret: allocate 18
		copy-memory ret req-buf + 12 18
		free req-buf
		ret
	]

	get-config-desc: func [
		hHub			[integer!]
		port			[integer!]
		config			[integer!]
		plen			[int-ptr!]
		return:			[byte-ptr!]
		/local
			success		[logic!]
			bytes		[integer!]
			bytes-ret	[integer!]
			req-buf		[byte-ptr!]
			desc-req	[USB-DESCRIPTOR-REQUEST!]
			desc		[USB-CONFIGURATION-DESCRIPTOR!]
			total		[integer!]
			total2		[integer!]
			ret			[byte-ptr!]
	][
		bytes: (size? USB-DESCRIPTOR-REQUEST!) + size? USB-CONFIGURATION-DESCRIPTOR!
		req-buf: allocate bytes
		if req-buf = null [return null]
		bytes-ret: 0
		set-memory req-buf null-byte 12
		bytes: 12 + 9
		desc-req: as USB-DESCRIPTOR-REQUEST! req-buf
		desc: as USB-CONFIGURATION-DESCRIPTOR! (req-buf + 12)
		desc-req/port: port
		desc-req/wValue1: as byte! config
		desc-req/wValue2: USB_CONFIGURATION_DESCRIPTOR_TYPE
		desc-req/wLength1: #"^(09)"
		desc-req/wLength2: #"^(00)"

		success: DeviceIoControl as int-ptr! hHub IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION as byte-ptr! desc-req bytes
					as byte-ptr! desc-req bytes :bytes-ret null
		if success <> true [
			free req-buf
			return null
		]
		if bytes <> bytes-ret [
			free req-buf
			return null
		]
		total: (as integer! desc/wTotalLen2) << 8 + (as integer! desc/wTotalLen1)
		if total < 9 [
			free req-buf
			return null
		]
		free req-buf
		bytes: 12 + total
		req-buf: allocate bytes
		if req-buf = null [return null]
		set-memory req-buf null-byte 12
		desc-req: as USB-DESCRIPTOR-REQUEST! req-buf
		desc: as USB-CONFIGURATION-DESCRIPTOR! (req-buf + 12)
		desc-req/port: port
		desc-req/wValue1: as byte! config
		desc-req/wValue2: USB_CONFIGURATION_DESCRIPTOR_TYPE
		desc-req/wLength1: #"^(09)"
		desc-req/wLength2: #"^(00)"
		success: DeviceIoControl as int-ptr! hHub IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION as byte-ptr! desc-req bytes
					as byte-ptr! desc-req bytes :bytes-ret null
		if success <> true [
			free req-buf
			return null
		]
		if bytes <> bytes-ret [
			free req-buf
			return null
		]
		total2: (as integer! desc/wTotalLen2) << 8 + (as integer! desc/wTotalLen1)
		if total <> total2 [
			free req-buf
			return null
		]
		plen/value: total2
		ret: allocate total2
		copy-memory ret req-buf + 12 total2
		free req-buf
		ret
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
