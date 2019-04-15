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
		desc-name			[byte-ptr!]
		desc-name-len		[integer!]
		driver-name			[byte-ptr!]
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

	#enum USB-DEVICE-INFO-TYPE! [
		HOST-CONTROLLER-INFO
		ROOT-HUB-INFO
		EXT-HUB-INFO
		DEVICE-INFO
	]

	USB-CONTROLLER-INFO-0!: alias struct! [
		pci-vendor-id		[integer!]
		pci-device-id		[integer!]
		pci-revision		[integer!]
		num-root-ports		[integer!]
		controller-flavor	[integer!]
		hc-feature-flags	[integer!]
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
		power-state			[byte-ptr!]
		power-state-len		[integer!]
	]

	USB-HOST-CONTROLLER-INFO!: alias struct! [
		entry				[list-entry! value]
		dev-info-type		[integer!]
		driver-key-name		[byte-ptr!]
		driver-key-len		[integer!]
		vendor-id			[integer!]
		device-id			[integer!]
		subsys-id			[integer!]
		revision			[integer!]
		;usb-power-info
		bus-dev-func-valid	[integer!]
		bus-number			[integer!]
		bus-device			[integer!]
		bus-function		[integer!]
		controller-info		[USB-CONTROLLER-INFO-0!]
		usb-dev-properties	[USB-DEVICE-PNP-STRINGS!]
	]

	device-list: declare DEVICE-GUID-LIST!
	hub-list: declare DEVICE-GUID-LIST!
	tree-list: declare list-entry!

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
			plen		[integer!]
			buf			[byte-ptr!]
	][
		if device-list/dev-info <> INVALID_HANDLE [
			clear-device-list device-list
		]
		device-list/dev-info: SetupDiGetClassDevs guid null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		if device-list/dev-info = INVALID_HANDLE [exit]
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
				plen: 0
				bResult: get-device-property device-list/dev-info pNode/dev-info-data
							SPDRP_DEVICEDESC :pbuffer :plen
				if bResult = false [
					free-device-info-node pNode
					break
				]
				pNode/desc-name: as byte-ptr! pbuffer
				pNode/desc-name-len: plen
				bResult: get-device-property device-list/dev-info pNode/dev-info-data
							SPDRP_DRIVER :pbuffer :plen
				if bResult = false [
					free-device-info-node pNode
					break
				]
				pNode/driver-name: as byte-ptr! pbuffer
				pNode/driver-name-len: plen

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

	enum-all-devices: does [
		enum-devices-with-guid device-list GUID_DEVINTERFACE_USB_DEVICE
		enum-devices-with-guid hub-list GUID_DEVINTERFACE_USB_HUB
	]

	enum-host-controllers: func [
		tree				[list-entry!]
		/local
			hHCDev			[int-ptr!]
			dev-info		[int-ptr!]
			dev-info-data	[DEV-INFO-DATA! value]
			interface-data	[DEV-INTERFACE-DATA! value]
			detail-data		[DEV-INTERFACE-DETAIL!]
			buffer			[byte-ptr!]
			index			[integer!]
			reqLen			[integer!]
			success			[logic!]
			dev-path		[c-string!]
	][
		enum-all-devices

		dev-info: SetupDiGetClassDevs GUID_DEVINTERFACE_USB_HOST_CONTROLLER
					null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		dev-info-data/cbSize: size? DEV-INFO-DATA!
		reqLen: 0
		index: 0
		while [
			SetupDiEnumDeviceInfo dev-info index dev-info-data
		][
			interface-data/cbSize: size? DEV-INTERFACE-DATA!
			success: SetupDiEnumDeviceInterfaces dev-info 0 GUID_DEVINTERFACE_USB_HOST_CONTROLLER
						index interface-data
			if success <> true [
				break
			]
			success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
						null 0 :reqLen null
			if all [
				success <> true
				ERROR_INSUFFICIENT_BUFFER <> GetLastError
			][
				break
			]
			buffer: allocate reqLen
			if buffer = null [
				break
			]
			detail-data: as DEV-INTERFACE-DETAIL! buffer
			detail-data/cbSize: 5
			success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
						detail-data reqLen :reqLen null
			if success <> true [
				free buffer
				break
			]
			dev-path: as c-string! :detail-data/DevicePath
			;print-line dev-path
			hHCDev: as int-ptr! CreateFileA dev-path GENERIC_WRITE
						FILE_SHARE_WRITE null OPEN_EXISTING 0 null
			if hHCDev <> INVALID_HANDLE [
				enum-host-controller tree hHCDev dev-path dev-info dev-info-data
				CloseHandle hHCDev
			]

			free buffer
			index: index + 1
		]
		SetupDiDestroyDeviceInfoList dev-info
	]

	enum-host-controller: func [
		tree				[list-entry!]
		hHCDev				[int-ptr!]
		leafName			[c-string!]
		dev-info			[int-ptr!]
		dev-info-data		[DEV-INFO-DATA!]
		/local
			driver-key-name	[byte-ptr!]
			name-len		[integer!]
			root-hub-name	[c-string!]
			entry			[list-entry!]
			hc-info			[USB-HOST-CONTROLLER-INFO!]
			hc-list			[USB-HOST-CONTROLLER-INFO!]
			dw-success		[integer!]
			success			[logic!]
			dev-and-func	[integer!]
			dev-props		[USB-DEVICE-PNP-STRINGS!]
	][
		hc-info: as USB-HOST-CONTROLLER-INFO! allocate size? USB-HOST-CONTROLLER-INFO!
		if hc-info = null [exit]
		hc-info/dev-info-type: HOST-CONTROLLER-INFO
		name-len: 0
		driver-key-name: get-hcd-driver-key-name hHCDev :name-len
		if driver-key-name = null [
			free as byte-ptr! hc-info
			exit
		]
		entry: tree/next
		while [entry <> tree][
			hc-list: as USB-HOST-CONTROLLER-INFO! entry
			if all [
				name-len = hc-list/driver-key-len
				0 = compare-memory driver-key-name hc-list/driver-key-name name-len
			][
				free driver-key-name
				free as byte-ptr! hc-info
				exit
			]
			entry: entry/next
		]
		dev-props: driver-name-to-device-props driver-key-name name-len
		hc-info/driver-key-name: driver-key-name
		hc-info/driver-key-len: name-len
		if dev-props <> null [
			hc-info/usb-dev-properties: dev-props
		]
		dlink/append tree as list-entry! hc-info
	]

	driver-name-to-device-props: func [
		driver-name				[byte-ptr!]
		name-len				[integer!]
		return:					[USB-DEVICE-PNP-STRINGS!]
		/local
			dev-info			[int-ptr!]
			ndev-info			[integer!]
			info-data			[DEV-INFO-DATA! value]
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
		ndev-info: 0
		status: driver-name-to-device-inst driver-name name-len :ndev-info info-data
		if status = false [
			free as byte-ptr! dev-props
			return null
		]
		len: 0
		status: SetupDiGetDeviceInstanceId as int-ptr! ndev-info info-data null 0 :len
		last-error: GetLastError
		if all [
			status <> false
			last-error <> ERROR_INSUFFICIENT_BUFFER
		][
			SetupDiDestroyDeviceInfoList as int-ptr! ndev-info
			free as byte-ptr! dev-props
			return null
		]
		len: len + 1
		buf: allocate len
		if buf = null [
			SetupDiDestroyDeviceInfoList as int-ptr! ndev-info
			free as byte-ptr! dev-props
			return null
		]
		status: SetupDiGetDeviceInstanceId as int-ptr! ndev-info info-data
					buf len :len
		if status = false [
			SetupDiDestroyDeviceInfoList as int-ptr! ndev-info
			free as byte-ptr! dev-props
			return null
		]
		dev-props/device-id: buf
		dev-props/device-id-len: len
		nbuf: 0
		nlen: 0
		status: get-device-property as int-ptr! ndev-info info-data
					SPDRP_DEVICEDESC :nbuf :nlen
		if status = false [
			SetupDiDestroyDeviceInfoList as int-ptr! ndev-info
			free buf
			free as byte-ptr! dev-props
			return null
		]
		dev-props/device-desc: as byte-ptr! nbuf
		dev-props/device-desc-len: nlen
		nbuf: 0 nlen: 0
		get-device-property as int-ptr! ndev-info info-data SPDRP_HARDWAREID :nbuf :nlen
		dev-props/hw-id: as byte-ptr! nbuf
		dev-props/hw-id-len: nlen
		nbuf: 0 nlen: 0
		get-device-property as int-ptr! ndev-info info-data SPDRP_SERVICE :nbuf :nlen
		dev-props/service: as byte-ptr! nbuf
		dev-props/service-len: nlen
		nbuf: 0 nlen: 0
		get-device-property as int-ptr! ndev-info info-data SPDRP_CLASS :nbuf :nlen
		dev-props/dev-class: as byte-ptr! nbuf
		dev-props/dev-class-len: nlen
		SetupDiDestroyDeviceInfoList as int-ptr! ndev-info
		dev-props
	]

	get-hcd-driver-key-name: func [
		hcd					[int-ptr!]
		name-len			[int-ptr!]
		return:				[byte-ptr!]
		/local
			success			[logic!]
			bytes			[integer!]
			key-name		[USB-HCD-DRIVERKEY-NAME! value]
			key-name-w		[USB-HCD-DRIVERKEY-NAME!]
			buffer			[byte-ptr!]
	][
		set-memory as byte-ptr! key-name null-byte size? USB-HCD-DRIVERKEY-NAME!
		bytes: 0
		success: DeviceIoControl hcd IOCTL_GET_HCD_DRIVERKEY_NAME as byte-ptr! key-name
					6 as byte-ptr! key-name 6 :bytes null
		if success <> true [
			return null
		]
		bytes: key-name/actual-length
		if bytes <= 6 [
			return null
		]
		key-name-w: as USB-HCD-DRIVERKEY-NAME! allocate bytes
		if key-name-w = null [
			return null
		]
		success: DeviceIoControl hcd IOCTL_GET_HCD_DRIVERKEY_NAME as byte-ptr! key-name-w
					bytes as byte-ptr! key-name-w bytes :bytes null
		if success <> true [
			free as byte-ptr! key-name-w
			return null
		]
		name-len/value: bytes - 4
		buffer: allocate name-len/value
		copy-memory buffer as byte-ptr! :key-name-w/driver-key-name name-len/value
		free as byte-ptr! key-name-w
		buffer
	]

	driver-name-to-device-inst: func [
		driver-name				[byte-ptr!]
		name-len				[integer!]
		pdev-info				[int-ptr!]
		info-data				[DEV-INFO-DATA!]
		return:					[logic!]
		/local
			ndev-info			[int-ptr!]
			status				[logic!]
			dev-index			[integer!]
			ninfo-data			[DEV-INFO-DATA! value]
			result				[logic!]
			dname				[byte-ptr!]
			buf					[integer!]
			len					[integer!]
	][
		if pdev-info = null [return false]
		if info-data = null [return false]
		set-memory as byte-ptr! info-data null-byte size? DEV-INFO-DATA!
		pdev-info/value: -1
		ndev-info: SetupDiGetClassDevs null null 0 DIGCF_PRESENT or DIGCF_ALLCLASSES
		if ndev-info = INVALID_HANDLE [
			return false
		]
		dev-index: 0
		len: 0
		buf: 0
		ninfo-data/cbSize: size? DEV-INFO-DATA!
		forever [
			status: SetupDiEnumDeviceInfo ndev-info dev-index ninfo-data
			dev-index: dev-index + 1
			if status <> true [
				break
			]
			result: get-device-property ndev-info ninfo-data SPDRP_DRIVER :buf :len
			if all [
				result = true
				buf <> 0
				len = name-len
				0 = compare-memory driver-name as byte-ptr! buf len
			][
				pdev-info/value: as integer! ndev-info
				copy-memory as byte-ptr! info-data as byte-ptr! ninfo-data size? DEV-INFO-DATA!
				free as byte-ptr! buf
				break
			]
			if buf <> 0 [
				free as byte-ptr! buf
				buf: 0
			]
		]
		if result = false [
			if ndev-info = INVALID_HANDLE [
				SetupDiDestroyDeviceInfoList ndev-info
			]
		]
		status
	]

	init: does [
		UuidFromString "3ABF6F2D-71C4-462A-8A92-1E6861E6AF27" GUID_DEVINTERFACE_USB_HOST_CONTROLLER
		UuidFromString "A5DCBF10-6530-11D2-901F-00C04FB951ED" GUID_DEVINTERFACE_USB_DEVICE
		UuidFromString "F18A0E88-C30C-11D0-8815-00A0C906BED8" GUID_DEVINTERFACE_USB_HUB
		dlink/init device-list/list-head
		dlink/init hub-list/list-head
		dlink/init tree-list
		device-list/dev-info: INVALID_HANDLE
		hub-list/dev-info: INVALID_HANDLE

	]
]
