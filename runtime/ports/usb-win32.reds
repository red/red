Red/System [
	Title:	"usb port! implementation on Windows"
	Author: "bitbegin"
	File: 	%usb-win32.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

usb-device: context [

	GUID_DEVINTERFACE_USB_HOST_CONTROLLER: declare UUID!
	GUID_DEVINTERFACE_USB_DEVICE: declare UUID!
	GUID_DEVINTERFACE_USB_HUB: declare UUID!
	GUID_DEVINTERFACE_HID: declare UUID!
	GUID_DEVINTERFACE_VENDOR: declare UUID!

	#enum DRIVER-TYPE! [
		DRIVER-TYPE-NONE
		DRIVER-TYPE-GEN
		DRIVER-TYPE-WINUSB
		DRIVER-TYPE-HIDUSB
		DRIVER-TYPE-KBDHID
		DRIVER-TYPE-MOUHID
	]

	#enum USB-ERROR! [
		USB-ERROR-OK
		USB-ERROR-HANDLE
		USB-ERROR-UNSUPPORT
		USB-ERROR-OPEN
		USB-ERROR-INIT
		USB-ERROR-MAX
	]

	USB-DEVICE-PNP-STRINGS!: alias struct! [
		device-id			[c-string!]
		device-desc			[byte-ptr!]
		device-desc-len		[integer!]
		hw-id				[c-string!]
		service				[c-string!]
		dev-class			[c-string!]
		driver-name			[c-string!]
	]

	STRING-DESC-NODE!: alias struct! [
		next				[STRING-DESC-NODE!]
		index				[byte!]
		languageID			[integer!]
		string-desc			[USB-STRING-DESCRIPTOR! value]
	]

	INTERFACE-INFO-NODE!: alias struct! [
		entry				[list-entry! value]
		interface-num		[integer!]
		collection-num		[integer!]
		path				[c-string!]
		properties			[USB-DEVICE-PNP-STRINGS!]
		hDev				[integer!]
		hInf				[integer!]
		hType				[DRIVER-TYPE!]
		bulk-in				[integer!]
		bulk-out			[integer!]
		interrupt-in		[integer!]
		interrupt-out		[integer!]
	]

	DEVICE-INFO-NODE!: alias struct! [
		entry				[list-entry! value]
		port				[integer!]
		path				[c-string!]
		properties			[USB-DEVICE-PNP-STRINGS!]
		vid					[integer!]
		pid					[integer!]
		serial-num			[c-string!]
		hub-path			[c-string!]
		device-desc			[byte-ptr!]
		device-desc-len		[integer!]
		config-desc			[byte-ptr!]
		config-desc-len		[integer!]
		strings				[STRING-DESC-NODE!]
		interface-entry		[list-entry! value]
	]

	device-list: declare list-entry!

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

	free-device-pnp-string: func [
		props		[USB-DEVICE-PNP-STRINGS!]
	][
		if props <> null [
			if props/device-id <> null [
				free as byte-ptr! props/device-id
			]
			if props/device-desc <> null [
				free props/device-desc
			]
			if props/hw-id <> null [
				free as byte-ptr! props/hw-id
			]
			if props/service <> null [
				free as byte-ptr! props/service
			]
			if props/dev-class <> null [
				free as byte-ptr! props/dev-class
			]
			if props/driver-name <> null [
				free as byte-ptr! props/driver-name
			]
			free as byte-ptr! props
		]
	]

	free-interface-info-node: func [
		pNode		[INTERFACE-INFO-NODE!]
	][
		if pNode = null [exit]
		if pNode/path <> null [
			free as byte-ptr! pNode/path
		]
		free-device-pnp-string pNode/properties
		close-interface pNode
		free as byte-ptr! pNode
	]

	free-device-info-node: func [
		pNode		[DEVICE-INFO-NODE!]
		/local
			strings	[STRING-DESC-NODE!]
			next	[STRING-DESC-NODE!]
	][
		if pNode = null [exit]
		if pNode/path <> null [
			free as byte-ptr! pNode/path
		]
		free-device-pnp-string pNode/properties
		clear-interface-list pNode/interface-entry
		strings: pNode/strings
		while [strings <> null][
			next: strings/next
			free as byte-ptr! strings
			strings: next
		]
		free as byte-ptr! pNode
	]

	enum-devices-with-guid: func [
		device-list			[list-entry!]
		guid				[UUID!]
		/local
			dev-info		[int-ptr!]
			info-data		[DEV-INFO-DATA! value]
			interface-data	[DEV-INTERFACE-DATA! value]
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
			path			[byte-ptr!]
			dev-path		[c-string!]
			rint			[integer!]
			hHub			[integer!]
			strings			[STRING-DESC-NODE!]
	][
		clear-device-list device-list
		dev-info: SetupDiGetClassDevs guid null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		if dev-info = INVALID_HANDLE [exit]
		index: 0 error: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			pNode: as DEVICE-INFO-NODE! allocate size? DEVICE-INFO-NODE!
			if pNode = null [continue]
			set-memory as byte-ptr! pNode null-byte size? DEVICE-INFO-NODE!
			dlink/init pNode/interface-entry
			info-data/cbSize: size? DEV-INFO-DATA!
			interface-data/cbSize: size? DEV-INTERFACE-DATA!
			success: SetupDiEnumDeviceInfo dev-info index info-data
			index: index + 1
			either success = false [
				error: GetLastError
				free-device-info-node pNode
			][
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
				detail-data: as DEV-INTERFACE-DETAIL! buf
				detail-data/cbSize: 5				; don't use size? DEV-INTERFACE-DETAIL!, as it's actual size = 5
				success: SetupDiGetDeviceInterfaceDetail dev-info interface-data
							detail-data reqLen :reqLen null
				if success <> true [
					free-device-info-node pNode
					free buf
					continue
				]
				path: allocate reqLen
				if path = null [
					free-device-info-node pNode
					free buf
					continue
				]
				copy-memory path buf + 4 reqLen - 4
				pNode/path: as c-string! path
				free buf

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
				dev-props: get-pnp-props dev-info info-data
				pNode/properties: dev-props
				pid: 65535
				vid: 65535
				serial: null
				if dev-props <> null [
					serial: as c-string! allocate 256
					sscanf [dev-props/device-id "USB\VID_%x&PID_%x\%s"
						:vid :pid serial]
					pNode/vid: vid
					pNode/pid: pid
					pNode/serial-num: serial
					;print-line as c-string! dev-props/device-id
				]
				inst: 0
				rint: CM_Get_Parent :inst info-data/DevInst 0
				if all [
					rint = 0
					port <> -1
				][
					dev-path: get-dev-path-with-guid inst GUID_DEVINTERFACE_USB_HUB null
					pNode/hub-path: dev-path
					if dev-path <> null [
						hHub: CreateFileA dev-path GENERIC_WRITE FILE_SHARE_WRITE null
								OPEN_EXISTING 0 null
						if hHub <> -1 [
							buf: get-device-desc hHub port :plen
							if buf <> null [
								pNode/device-desc: buf
								pNode/device-desc-len: plen
							]
							buf: get-config-desc hHub port 0 :plen
							if buf <> null [
								pNode/config-desc: buf
								pNode/config-desc-len: plen
							]
							strings: get-all-string-desc hHub port pNode/device-desc pNode/config-desc
							pNode/strings: strings
						]
						CloseHandle as int-ptr! hHub
					]
				]
				dlink/init pNode/interface-entry
				if all [
					vid <> 65535
					pid <> 65535
				][
					enum-children pNode/interface-entry info-data/DevInst vid pid
				]

				dlink/append device-list as list-entry! pNode
			]
		]
		SetupDiDestroyDeviceInfoList dev-info
	]

	enum-children: func [
		list			[list-entry!]
		inst			[integer!]
		vid				[integer!]
		pid				[integer!]
		/local
			dev-info		[int-ptr!]
			info-data		[DEV-INFO-DATA! value]
			buf				[byte-ptr!]
			path			[byte-ptr!]
			len				[integer!]
			len2			[integer!]
			len3			[integer!]
			rint			[integer!]
			pNode			[INTERFACE-INFO-NODE!]
			reg				[integer!]
			guid			[UUID! value]
			pguid			[UUID!]
			index			[integer!]
			error			[integer!]
			success			[logic!]
			nvid			[integer!]
			npid			[integer!]
			nmi				[integer!]
			ncol			[integer!]
			nserial			[c-string!]
			prop			[integer!]
			driver			[integer!]
	][
		dev-info: SetupDiGetClassDevs null null 0 DIGCF_PRESENT or DIGCF_ALLCLASSES
		if dev-info = INVALID_HANDLE [
			exit
		]
		buf: allocate 256
		nserial: as c-string! allocate 256
		if buf = null [
			exit
		]
		index: 0 error: 0 len: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			info-data/cbSize: size? DEV-INFO-DATA!
			success: SetupDiEnumDeviceInfo dev-info index info-data
			index: index + 1
			either success = false [
				error: GetLastError
			][
				success: SetupDiGetDeviceInstanceId dev-info info-data buf 256 :len
				either success = false [
					error: GetLastError
				][
					unless inst-ancestor? info-data/DevInst inst [
						continue
					]
					nvid: 65535
					npid: 65535
					nmi: 255
					ncol: 255
					;print-line as c-string! buf
					either 0 = compare-memory buf as byte-ptr! "USB\" 4 [
						sscanf [buf "USB\VID_%4hx&PID_%4hx&MI_%2hx\%s"
							:nvid :npid :nmi nserial]
						if nmi = 255 [
							sscanf [buf "USB\VID_%4hx&PID_%4hx\%s"
								:nvid :npid nserial]
						]
						unless all [
							vid = nvid
							pid = npid
						][
							continue
						]
						reg: SetupDiOpenDevRegKey dev-info info-data DICS_FLAG_GLOBAL 0 DIREG_DEV KEY_READ
						if reg = -1 [
							continue
						]
						len3: 0
						len2: 80
						path: allocate 256
						rint: RegQueryValueExW reg #u16 "DeviceInterfaceGUIDs" null :len3 path :len2
						if rint = 2 [
							rint: RegQueryValueExW reg #u16 "DeviceInterfaceGUID" null :len3 path :len2
						]
						RegCloseKey reg
						if rint <> 0 [
							free path
							continue
						]
						if 0 <> IIDFromString as c-string! path guid [
							free path
							continue
						]
						free path
						pguid: guid
					][
						either 0 = compare-memory buf as byte-ptr! "HID\" 4 [
							sscanf [buf "HID\VID_%4hx&PID_%4hx&MI_%2hx&COL%2hx\%s"
								:nvid :npid :nmi :ncol nserial]
							if ncol = 255 [
								sscanf [buf "HID\VID_%4hx&PID_%4hx&MI_%2hx\%s"
									:nvid :npid :nmi nserial]
								if nmi = 255 [
									sscanf [buf "HID\VID_%4hx&PID_%4hx\%s"
										:nvid :npid nserial]
								]
							]
							unless all [
								vid = nvid
								pid = npid
							][
								continue
							]
							pguid: GUID_DEVINTERFACE_HID
						][continue]
					]
					pNode: as INTERFACE-INFO-NODE! allocate size? INTERFACE-INFO-NODE!
					if pNode = null [
						continue
					]
					set-memory as byte-ptr! pNode null-byte size? INTERFACE-INFO-NODE!
					pNode/interface-num: nmi
					pNode/collection-num: ncol
					prop: 0
					pNode/path: get-dev-path-with-guid info-data/DevInst pguid :prop
					pNode/properties: as USB-DEVICE-PNP-STRINGS! prop
					dlink/append list as list-entry! pNode
				]
			]
		]
		free buf
		free as byte-ptr! nserial
		SetupDiDestroyDeviceInfoList dev-info
	]

	inst-ancestor?: func [
		inst			[integer!]
		ancestor		[integer!]
		return:			[logic!]
		/local
			parent		[integer!]
			nparent		[integer!]
			rint		[integer!]
	][
		parent: 0 nparent: 0
		rint: CM_Get_Parent :parent inst 0
		if rint <> 0 [return false]
		if parent = ancestor [return true]
		rint: CM_Get_Parent :nparent parent 0
		if rint <> 0 [return false]
		nparent = ancestor
	]

	get-dev-path-with-guid: func [
		inst			[integer!]
		guid			[UUID!]
		prop			[int-ptr!]
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
		dev-info: SetupDiGetClassDevs guid null 0 DIGCF_PRESENT or DIGCF_DEVICEINTERFACE
		if dev-info = INVALID_HANDLE [
			return null
		]
		index: 0 error: 0
		while [error <> ERROR_NO_MORE_ITEMS][
			info-data/cbSize: size? DEV-INFO-DATA!
			success: SetupDiEnumDeviceInfo dev-info index info-data
			index: index + 1
			either success = false [
				error: GetLastError
			][
				if info-data/DevInst = inst [
					interface-data/cbSize: size? DEV-INTERFACE-DATA!
					success: SetupDiEnumDeviceInterfaces dev-info 0 guid index - 1
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
					if prop <> null [
						prop/value: as integer! get-pnp-props dev-info info-data
					]
					SetupDiDestroyDeviceInfoList dev-info
					return ret
				]
			]
		]
		SetupDiDestroyDeviceInfoList dev-info
		null
	]

	get-device-desc: func [
		hHub			[integer!]
		port			[integer!]
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
		desc-req/wValue1: #"^(00)"
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

	get-all-string-desc: func [
		hHub			[integer!]
		port			[integer!]
		dev-desc		[byte-ptr!]
		config-desc		[byte-ptr!]
		return:			[STRING-DESC-NODE!]
		/local
			string-node	[STRING-DESC-NODE!]
			numLangIDs	[integer!]
			langIDs		[byte-ptr!]
			descStart	[byte-ptr!]
			descEnd		[byte-ptr!]
			uIndex		[integer!]
			success		[logic!]
			more?		[logic!]
			res			[integer!]
	][
		string-node: get-string-desc hHub port null-byte 0
		if string-node = null [return null]
		numLangIDs: (as integer! string-node/string-desc/bLength) - 2 / 2
		langIDs: (as byte-ptr! string-node/string-desc) + 2
		more?: false
		if dev-desc/15 <> null-byte [
			get-string-descs hHub port dev-desc/15 numLangIDs langIDs string-node
		]
		if dev-desc/16 <> null-byte [
			get-string-descs hHub port dev-desc/16 numLangIDs langIDs string-node
		]
		if dev-desc/17 <> null-byte [
			get-string-descs hHub port dev-desc/17 numLangIDs langIDs string-node
		]
		descStart: config-desc
		descEnd: config-desc + (as integer! config-desc/3) + ((as integer! config-desc/4) << 8)
		while [
			all [
				(descStart + 2) < descEnd
				(descStart + as integer! descStart/1) <= descEnd
			]
		][
			switch descStart/2 [
				USB_CONFIGURATION_DESCRIPTOR_TYPE [
					if (as integer! descStart/1) <> 9 [
						break
					]
					if descStart/7 <> null-byte [
						get-string-descs hHub port descStart/7 numLangIDs langIDs string-node
					]
					descStart: descStart + as integer! descStart/1
				]
				USB_IAD_DESCRIPTOR_TYPE [
					if (as integer! descStart/1) <> 8 [
						break
					]
					if descStart/8 <> null-byte [
						get-string-descs hHub port descStart/8 numLangIDs langIDs string-node
					]
					descStart: descStart + as integer! descStart/1
				]
				USB_INTERFACE_DESCRIPTOR_TYPE [
					if all [
						(as integer! descStart/1) <> 7
						(as integer! descStart/1) <> 9
					][
						break
					]
					if (as integer! descStart/1) = 9 [
						if descStart/9 <> null-byte [
							get-string-descs hHub port descStart/9 numLangIDs langIDs string-node
						]
						if descStart/6 = USB_DEVICE_CLASS_VIDEO [
							more?: true
						]
					]
					descStart: descStart + as integer! descStart/1
				]
				default [
					descStart: descStart + as integer! descStart/1
				]
			]
		]
		if more? [
			uIndex: 1
			success: true
			while [
				all [
					success
					uIndex < NUM_STRING_DESC_TO_GET
				]
			][
				success: get-string-descs hHub port as byte! uIndex numLangIDs langIDs string-node
				uIndex: uIndex + 1
			]
		]
		string-node
	]

	get-string-descs: func [
		hHub			[integer!]
		port			[integer!]
		index			[byte!]
		numLangIDs		[integer!]
		langIDs			[byte-ptr!]
		node-head		[STRING-DESC-NODE!]
		return:			[logic!]
		/local
			tail		[STRING-DESC-NODE!]
			trailing	[STRING-DESC-NODE!]
			i			[integer!]
			t			[integer!]
			k			[integer!]
			id			[integer!]
	][
		tail: node-head
		while [tail <> null][
			if tail/index = index [
				return true
			]
			trailing: tail
			tail: tail/next
		]
		tail: trailing
		i: 0
		while [
			all [
				tail <> null
				i < numLangIDs
			]
		][
			t: i * 2 + 1
			k: t + 1
			id: (as integer! langIDs/k) << 8 + (as integer! langIDs/t)
			tail/next: get-string-desc hHub port index id
			i: i + 1
			tail: tail/next
		]
		if tail = null [
			return false
		]
		true
	]

	get-string-desc: func [
		hHub			[integer!]
		port			[integer!]
		index			[byte!]
		langID			[integer!]
		return:			[STRING-DESC-NODE!]
		/local
			success		[logic!]
			bytes		[integer!]
			bytes-ret	[integer!]
			req-buf		[byte-ptr!]
			desc-req	[USB-DESCRIPTOR-REQUEST!]
			desc		[USB-STRING-DESCRIPTOR!]
			node		[STRING-DESC-NODE!]
	][
		bytes: (size? USB-DESCRIPTOR-REQUEST!) + MAXIMUM_USB_STRING_LENGTH
		req-buf: allocate bytes
		if req-buf = null [return null]
		bytes-ret: 0
		set-memory req-buf null-byte 12
		bytes: 12 + MAXIMUM_USB_STRING_LENGTH
		desc-req: as USB-DESCRIPTOR-REQUEST! req-buf
		desc: as USB-STRING-DESCRIPTOR! (req-buf + 12)
		desc-req/port: port
		desc-req/wValue1: index
		desc-req/wValue2: USB_STRING_DESCRIPTOR_TYPE
		desc-req/wLength1: #"^(FF)"
		desc-req/wLength2: #"^(00)"
		desc-req/wIndex1: as byte! langID
		desc-req/wIndex2: as byte! (langID >> 8)

		success: DeviceIoControl as int-ptr! hHub IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION as byte-ptr! desc-req bytes
					as byte-ptr! desc-req bytes :bytes-ret null
		if success <> true [
			free req-buf
			return null
		]
		if bytes-ret < 2 [
			free req-buf
			return null
		]
		if desc/bDescType <> USB_STRING_DESCRIPTOR_TYPE [
			free req-buf
			return null
		]
		if (as integer! desc/bLength) <> (bytes-ret - 12) [
			free req-buf
			return null
		]
		if (as integer! desc/bLength) % 2 <> 0 [
			free req-buf
			return null
		]
		node: as STRING-DESC-NODE! allocate (size? STRING-DESC-NODE!) + as integer! desc/bLength
		if node = null [
			free req-buf
			return null
		]
		node/index: index
		node/languageID: langID
		node/next: null
		copy-memory as byte-ptr! node/string-desc as byte-ptr! desc as integer! desc/bLength
		free req-buf
		node
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

	get-pnp-props: func [
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
		dev-props/device-id: as c-string! buf
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
		get-device-property-a dev-info info-data SPDRP_HARDWAREID :nbuf :nlen
		dev-props/hw-id: as c-string! nbuf
		nbuf: 0 nlen: 0
		get-device-property-a dev-info info-data SPDRP_SERVICE :nbuf :nlen
		dev-props/service: as c-string! nbuf
		nbuf: 0 nlen: 0
		get-device-property-a dev-info info-data SPDRP_CLASS :nbuf :nlen
		dev-props/dev-class: as c-string! nbuf
		nbuf: 0 nlen: 0
		get-device-property-a dev-info info-data SPDRP_DRIVER :nbuf :nlen
		dev-props/driver-name: as c-string! nbuf
		dev-props
	]

	enum-all-devices: does [
		enum-devices-with-guid device-list GUID_DEVINTERFACE_USB_DEVICE
	]

	open-inteface: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
		/local
			prop				[USB-DEVICE-PNP-STRINGS!]
			ret					[USB-ERROR!]
	][
		prop: pNode/properties
		if prop = null [return USB-ERROR-HANDLE]
		if prop/service = null [return USB-ERROR-HANDLE]
		if prop/device-id = null [return USB-ERROR-HANDLE]
		if 0 = compare-memory as byte-ptr! prop/device-id as byte-ptr! "USB\" 4 [
			if 0 = compare-memory as byte-ptr! prop/service as byte-ptr! "WINUSB" 6 [
				return open-winusb pNode
			]
			if 0 = compare-memory as byte-ptr! prop/service as byte-ptr! "HidUsb" 6 [
				return open-hidusb pNode
			]
			return USB-ERROR-UNSUPPORT
		]
		if 0 <> compare-memory as byte-ptr! prop/device-id as byte-ptr! "HID\" 4 [
			return USB-ERROR-UNSUPPORT
		]
		if 0 = compare-memory as byte-ptr! prop/service as byte-ptr! "HidUsb" 6 [
			return open-hidusb pNode
		]
		if 0 = compare-memory as byte-ptr! prop/service as byte-ptr! "kbdhid" 6 [
			ret: open-hidusb pNode
			if ret = USB-ERROR-OK [
				pNode/hType: DRIVER-TYPE-KBDHID
			]
			return ret
		]
		if 0 = compare-memory as byte-ptr! prop/service as byte-ptr! "mouhid" 6 [
			ret: open-hidusb pNode
			if ret = USB-ERROR-OK [
				pNode/hType: DRIVER-TYPE-MOUHID
			]
			return ret
		]
		USB-ERROR-UNSUPPORT
	]

	close-interface: func [
		pNode					[INTERFACE-INFO-NODE!]
	][
		if pNode/hInf <> 0 [
			WinUsb_Free pNode/hInf
			pNode/hInf: 0
		]
		if pNode/hDev <> 0 [
			CloseHandle as int-ptr! pNode/hDev
			pNode/hDev: 0
		]
	]

	open-winusb: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
		/local
			index				[integer!]
			pipe-info			[PIPE-INFO! value]
			pipe-id				[integer!]
			pipe-type			[PIPE-TYPE!]
	][
		pNode/hDev: CreateFileA pNode/path GENERIC_WRITE or GENERIC_READ FILE_SHARE_READ null
				OPEN_EXISTING FILE_FLAG_OVERLAPPED null
		if pNode/hDev = -1 [
			return USB-ERROR-OPEN
		]
		if false = WinUsb_Initialize pNode/hDev :pNode/hInf [
			CloseHandle as int-ptr! pNode/hDev
			return USB-ERROR-INIT
		]
		pNode/hType: DRIVER-TYPE-WINUSB
		index: 0
		forever [
			unless WinUsb_QueryPipe pNode/hInf 0 index pipe-info [break]
			pipe-id: as integer! pipe-info/pipeID
			pipe-type: pipe-info/pipeType
			switch pipe-type [
				PIPE-TYPE-BULK [
					either (pipe-id and 80h) = 80h [
						pNode/bulk-in: pipe-id
					][
						pNode/bulk-out: pipe-id
					]
				]
				PIPE-TYPE-INTERRUPT [
					either (pipe-id and 80h) = 80h [
						pNode/interrupt-in: pipe-id
					][
						pNode/interrupt-out: pipe-id
					]
				]
			]
			index: index + 1
		]
		USB-ERROR-OK
	]

	open-hidusb: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
	][
		pNode/hDev: CreateFileA pNode/path GENERIC_WRITE FILE_SHARE_WRITE null
				OPEN_EXISTING 0 null
		if pNode/hDev = -1 [
			return USB-ERROR-OPEN
		]
		pNode/hType: DRIVER-TYPE-HIDUSB
		USB-ERROR-OK
	]

	async-pipo-setup: func [
		pNode					[INTERFACE-INFO-NODE!]
		pipe-id					[integer!]
		return:					[logic!]
		/local
			value				[integer!]
	][
		value: 1
		WinUsb_SetPipePolicy pNode/hInf pipe-id RAW-IO 1 :value
	]

	pipo-timeout: func [
		pNode					[INTERFACE-INFO-NODE!]
		pipe-id					[integer!]
		timeout					[integer!]
		return:					[logic!]
	][
		WinUsb_SetPipePolicy pNode/hInf pipe-id PIPE-TRANSFER-TIMEOUT 4 :timeout
	]

	init: does [
		UuidFromString "3ABF6F2D-71C4-462A-8A92-1E6861E6AF27" GUID_DEVINTERFACE_USB_HOST_CONTROLLER
		UuidFromString "A5DCBF10-6530-11D2-901F-00C04FB951ED" GUID_DEVINTERFACE_USB_DEVICE
		UuidFromString "F18A0E88-C30C-11D0-8815-00A0C906BED8" GUID_DEVINTERFACE_USB_HUB
		UuidFromString "4D1E55B2-F16F-11CF-88CB-001111000030" GUID_DEVINTERFACE_HID
		UuidFromString "88BAE032-5A81-49f0-BC3D-A4FF138216D6" GUID_DEVINTERFACE_VENDOR
		dlink/init device-list

	]
]
