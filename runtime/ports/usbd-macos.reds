Red/System [
	Title:	"usb port! implementation on Macos"
	Author: "bitbegin"
	File: 	%usbd-macos.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %usbd-common.reds

USB-DEVICE-ID!: alias struct! [
	id1					[integer!]
	id2					[integer!]
]

usb-device: context [

	device-list: declare list-entry!
	#define kIOServicePlane						"IOService"
	#define kIOUSBInterfaceClassName			"IOUSBInterface"
	#define kCFNumberSInt8Type					1
	#define kCFNumberSInt32Type					3
	#define kCFAllocatorDefault					null
	#define kCFStringEncodingASCII				0600h
	#define kCFStringEncodingUTF8				08000100h
	#define kUSBProductName						"USB Product Name"
	#define kUSBInterfaceName					"USB Interface Name"
	#define kUSBSerialNum						"USB Serial Number"
	#define CFSTR(cStr)							[__CFStringMakeConstantString cStr]
	#define CFString(cStr)						[CFStringCreateWithCString kCFAllocatorDefault cStr kCFStringEncodingASCII]

	this!: alias struct! [vtbl [integer!]]

	UUID!: alias struct! [
		data1	[integer!]
		data2	[integer!]
		data3	[integer!]
		data4	[integer!]
	]

	QueryInterface!: alias function! [
		this		[this!]
		riid		[UUID! value]
		ppvObject	[int-ptr!]
		return:		[integer!]
	]

	AddRef!: alias function! [
		this		[this!]
		return:		[integer!]
	]

	Release!: alias function! [
		this		[this!]
		return:		[integer!]
	]

	IOUSBFindInterfaceRequest: alias struct! [
		class-subclass	 [integer!]
		protocol-setting [integer!]
	]

	#define IUNKNOWN_C_GUTS [
		_reserved			[int-ptr!]
		QueryInterface		[QueryInterface!]
		AddRef				[AddRef!]
		Release				[Release!]
	]

	IOUSBDeviceInterface: alias struct! [
		IUNKNOWN_C_GUTS
		CreateDeviceAsyncEventSource	[function! [this [this!] source [int-ptr!] return: [integer!]]]
		GetDeviceAsyncEventSource		[function! [this [this!] return: [int-ptr!]]]
		CreateDeviceAsyncPort			[function! [this [this!] port [int-ptr!] return: [integer!]]]
		GetDeviceAsyncPort				[function! [this [this!] return: [integer!]]]
		USBDeviceOpen					[function! [this [this!] return: [integer!]]]
		USBDeviceClose					[function! [this [this!] return: [int-ptr!]]]
		GetDeviceClass					[function! [this [this!] intfClass [c-string!] return: [integer!]]]
		GetDeviceSubClass				[function! [this [this!] intfClass [c-string!] return: [integer!]]]
		GetDeviceProtocol				[function! [this [this!] intfClass [c-string!] return: [integer!]]]
		GetDeviceVendor					[function! [this [this!] vender [int-ptr!] return: [integer!]]]
		GetDeviceProduct				[function! [this [this!] vender [int-ptr!] return: [integer!]]]
		GetDeviceReleaseNumber			[function! [this [this!] vender [int-ptr!] return: [integer!]]]
		GetDeviceAddress				[function! [this [this!] vender [int-ptr!] return: [integer!]]]
		GetDeviceBusPowerAvailable		[function! [this [this!] vender [int-ptr!] return: [integer!]]]
		GetDeviceSpeed					[function! [this [this!] vender [byte-ptr!] return: [integer!]]]
		GetNumberOfConfigurations		[function! [this [this!] vender [byte-ptr!] return: [integer!]]]
		GetLocationID					[function! [this [this!] vender [int-ptr!] return: [integer!]]]
		GetConfigurationDescriptorPtr	[integer!]
		GetConfiguration				[function! [this [this!] vender [byte-ptr!] return: [integer!]]]
		SetConfiguration				[function! [this [this!] vender [byte-ptr!] return: [integer!]]]
		GetBusFrameNumber				[integer!]
		ResetDevice						[function! [this [this!] return: [integer!]]]
		DeviceRequest					[function! [this [this!] req [int-ptr!] return: [integer!]]]
		DeviceRequestAsync				[integer!]
		CreateInterfaceIterator			[function! [this [this!] req [IOUSBFindInterfaceRequest] iter [int-ptr!] return: [integer!]]]
		USBDeviceOpenSeize				[function! [this [this!] return: [integer!]]]
		DeviceRequestTO					[integer!]
		DeviceRequestAsyncTO			[integer!]
		USBDeviceSuspend				[function! [this [this!] suspend [logic!] return: [integer!]]]
		USBDeviceAbortPipeZero			[integer!]
		USBGetManufacturerStringIndex	[function! [this [this!] req [byte-ptr!] return: [integer!]]]
		USBGetProductStringIndex		[function! [this [this!] req [byte-ptr!] return: [integer!]]]
		USBGetSerialNumberStringIndex	[function! [this [this!] req [byte-ptr!] return: [integer!]]]
		USBDeviceReEnumerate			[function! [this [this!] options [integer!] return: [integer!]]]
		GetBusMicroFrameNumber			[integer!]
		GetIOUSBLibVersion				[integer!]
		GetBusFrameNumberWithTime		[integer!]
		GetUSBDeviceInformation			[integer!]
		RequestExtraPower				[integer!]
		ReturnExtraPower				[integer!]
		GetExtraPowerAllocated			[integer!]
		GetBandwidthAvailableForDevice	[function! [this [this!] req [int-ptr!] return: [integer!]]]
	]

	IOUSBInterfaceInterface: alias struct! [	;IOUSBInterfaceInterface550
		IUNKNOWN_C_GUTS
		CreateInterfaceAsyncEventSource	[function! [this [this!] source [int-ptr!] return: [integer!]]]
		GetInterfaceAsyncEventSource	[int-ptr!]
		CreateInterfaceAsyncPort		[function! [this [this!] port [int-ptr!] return: [integer!]]]
		GetInterfaceAsyncPort			[function! [this [this!] return: [integer!]]]
		USBInterfaceOpen				[function! [this [this!] return: [integer!]]]
		USBInterfaceClose				[function! [this [this!] return: [integer!]]]
		GetInterfaceClass				[function! [this [this!] intfClass [c-string!] return: [integer!]]]
		GetInterfaceSubClass			[function! [this [this!] intfClass [c-string!] return: [integer!]]]
		GetInterfaceProtocol			[function! [this [this!] intfClass [c-string!] return: [integer!]]]
		GetDeviceVendor					[function! [this [this!] vender [int-ptr!] return: [integer!]]]
		GetDeviceProduct				[function! [this [this!] product [int-ptr!] return: [integer!]]]
		GetDeviceReleaseNumber			[function! [this [this!] relnum [int-ptr!] return: [integer!]]]
		GetConfigurationValue			[function! [this [this!] value [int-ptr!] return: [integer!]]]
		GetInterfaceNumber				[function! [this [this!] inum [int-ptr!] return: [integer!]]]
		GetAlternateSetting				[function! [this [this!] alt [int-ptr!] return: [integer!]]]
		GetNumEndpoints					[function! [this [this!] endpt [int-ptr!] return: [integer!]]]
		GetLocationID					[function! [this [this!] id [int-ptr!] return: [integer!]]]
		GetDevice						[function! [this [this!] device [int-ptr!] return: [integer!]]]
		SetAlternateInterface			[function! [this [this!] alt [byte!] return: [integer!]]]
		GetBusFrameNumber				[int-ptr!]
		ControlRequest					[function! [this [this!] pipeRef [integer!] req [int-ptr!] return: [integer!]]]
		ControlRequestAsync				[function! [this [this!] pipeRef [integer!] req [int-ptr!] callback [int-ptr!] refCon [int-ptr!] return: [integer!]]]
		GetPipeProperties				[function! [this [this!] pipeRef [integer!] dir [int-ptr!] num [int-ptr!] type [int-ptr!] size [int-ptr!] interval [int-ptr!] return: [integer!]]]
		GetPipeStatus					[function! [this [this!] pipeRef [integer!] return: [integer!]]]
		AbortPipe						[function! [this [this!] pipeRef [integer!] return: [integer!]]]
		ResetPipe						[function! [this [this!] pipeRef [integer!] return: [integer!]]]
		ClearPipeStall					[function! [this [this!] pipeRef [integer!] return: [integer!]]]
		ReadPipe						[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] size [int-ptr!] return: [integer!]]]
		WritePipe						[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] size [integer!] return: [integer!]]]
		ReadPipeAsync					[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] size [integer!] callback [int-ptr!] refCon [int-ptr!] return: [integer!]]]
		WritePipeAsync					[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] size [integer!] callback [int-ptr!] refCon [int-ptr!] return: [integer!]]]
		ReadIsochPipeAsync				[int-ptr!]
		WriteIsochPipeAsync				[int-ptr!]
		ControlRequestTO				[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] req [int-ptr!] return: [integer!]]]
		ControlRequestAsyncTO			[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] req [int-ptr!] callback [int-ptr!] refCon [int-ptr!] return: [integer!]]]
		ReadPipeTO						[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] size [int-ptr!] dataTimeout [integer!] completionTimeout [integer!] return: [integer!]]]
		WritePipeTO						[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] size [integer!] dataTimeout [integer!] completionTimeout [integer!] return: [integer!]]]
		ReadPipeAsyncTO					[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] size [integer!] dataTimeout [integer!] completionTimeout [integer!] callback [int-ptr!] refCon [int-ptr!] return: [integer!]]]
		WritePipeAsyncTO				[function! [this [this!] pipeRef [integer!] buf [byte-ptr!] size [integer!] dataTimeout [integer!] completionTimeout [integer!] callback [int-ptr!] refCon [int-ptr!] return: [integer!]]]
		USBInterfaceGetStringIndex		[function! [this [this!] si [byte-ptr!] return: [integer!]]]
		USBInterfaceOpenSeize			[function! [this [this!] return: [integer!]]]
		ClearPipeStallBothEnds			[function! [this [this!] pipeRef [integer!] return: [integer!]]]
		SetPipePolicy					[function! [this [this!] pipeRef [integer!] size [integer!] interval [byte!] return: [integer!]]]
		GetBandwidthAvailable			[function! [this [this!] bandwidth [int-ptr!] return: [integer!]]]
		GetEndpointProperties			[function! [this [this!] alt [byte!] endpt [byte!] dir [byte!] type [byte-ptr!] size [int-ptr!] interval [byte-ptr!] return: [integer!]]]
		LowLatencyReadIsochPipeAsync	[int-ptr!]
		LowLatencyWriteIsochPipeAsync	[int-ptr!]
		LowLatencyCreateBuffer			[int-ptr!]
		LowLatencyDestroyBuffer			[int-ptr!]
		GetBusMicroFrameNumber			[int-ptr!]
		GetFrameListTime				[int-ptr!]
		GetIOUSBLibVersion				[function! [this [this!] libver [int-ptr!] familiyver [int-ptr!] return: [integer!]]]
		FindNextAssociatedDescriptor	[int-ptr!]
		FindNextAltInterface			[int-ptr!]
		GetBusFrameNumberWithTime		[int-ptr!]
		GetPipePropertiesV2				[int-ptr!]
		GetPipePropertiesV3				[int-ptr!]
		GetEndpointPropertiesV3			[int-ptr!]
		SupportsStreams					[int-ptr!]
		CreateStreams					[int-ptr!]
		GetConfiguredStreams			[int-ptr!]
		ReadStreamsPipeTO				[int-ptr!]
		WriteStreamsPipeTO				[int-ptr!]
		ReadStreamsPipeAsyncTO			[int-ptr!]
		WriteStreamsPipeAsyncTO			[int-ptr!]
		AbortStreamsPipe				[int-ptr!]
	]

	#import [
		"/System/Library/Frameworks/IOKit.framework/IOKit" cdecl [
			IOServiceMatching: "IOServiceMatching" [
				name			[c-string!]
				return:			[integer!]
			]
			IOServiceGetMatchingServices: "IOServiceGetMatchingServices" [
				masterPort		[integer!]
				matching		[integer!]
				existing		[int-ptr!]
				return:			[integer!]
			]
			IOServiceGetMatchingService: "IOServiceGetMatchingService" [
				masterPort		[integer!]
				matching		[integer!]
				return:			[int-ptr!]
			]
			IOIteratorIsValid: "IOIteratorIsValid" [
				iter			[integer!]
				return:			[logic!]
			]
			IOIteratorNext: "IOIteratorNext" [
				iterate			[integer!]
				return:			[int-ptr!]
			]
			IORegistryEntryGetName: "IORegistryEntryGetName" [
				dev				[int-ptr!]
				name			[byte-ptr!]
				return:			[integer!]
			]
			IORegistryEntryGetPath: "IORegistryEntryGetPath" [
				entry			[int-ptr!]
				plane 			[c-string!]   ;--size is 128
				path 			[c-string!]   ;--size is 512
				return: 		[integer!]
			]
			IOCreatePlugInInterfaceForService: "IOCreatePlugInInterfaceForService" [
				dev				[int-ptr!]
				typeID			[int-ptr!]
				interfaceID		[int-ptr!]
				interface		[int-ptr!]
				score			[int-ptr!]
				return:			[integer!]
			]
			IORegistryEntryCreateCFProperty: "IORegistryEntryCreateCFProperty" [
				entry			[int-ptr!]
				key				[c-string!]
				allocator		[integer!]
				options			[integer!]
				return:			[int-ptr!]
			]
			IORegistryEntryGetRegistryEntryID: "IORegistryEntryGetRegistryEntryID" [
				entry			[int-ptr!]
				id				[int-ptr!]
				return:			[integer!]
			]
			IORegistryEntryGetChildIterator: "IORegistryEntryGetChildIterator" [
				entry			[int-ptr!]
				plane			[c-string!]
				iter			[int-ptr!]
				return:			[integer!]
			]
			IORegistryEntryIDMatching: "IORegistryEntryIDMatching" [
				id				[USB-DEVICE-ID!]
				return:			[integer!]
			]
			IOObjectRelease: "IOObjectRelease" [
				object			[int-ptr!]
				return:			[integer!]
			]
			IOObjectConformsTo: "IOObjectConformsTo" [
				object			[int-ptr!]
				name			[c-string!]
				return:			[logic!]
			]
		]
		"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
			kCFAllocatorDefault: "kCFAllocatorDefault" [integer!]
			kIOMasterPortDefault: "kIOMasterPortDefault" [integer!]
			CFStringCreateWithCString: "CFStringCreateWithCString" [
				allocator	[int-ptr!]
				cStr		[c-string!]
				encoding	[integer!]
				return:		[c-string!]
			]
			CFUUIDGetConstantUUIDWithBytes: "CFUUIDGetConstantUUIDWithBytes" [
				allocator	[int-ptr!]
				byte0		[byte!]
				byte1		[byte!]
				byte2		[byte!]
				byte3		[byte!]
				byte4		[byte!]
				byte5		[byte!]
				byte6		[byte!]
				byte7		[byte!]
				byte8		[byte!]
				byte9		[byte!]
				byte10		[byte!]
				byte11		[byte!]
				byte12		[byte!]
				byte13		[byte!]
				byte14		[byte!]
				byte15		[byte!]
				return:		[int-ptr!]
			]
			CFUUIDGetUUIDBytes: "CFUUIDGetUUIDBytes" [
				guid		[int-ptr!]
				return:		[UUID! value]
			]
			CFGetTypeID: "CFGetTypeID" [
				cf			[int-ptr!]
				return:		[integer!]
			]
			CFNumberGetTypeID: "CFNumberGetTypeID" [
				return:		[integer!]
			]
			CFStringGetTypeID: "CFStringGetTypeID" [
				return:		[integer!]
			]
			CFNumberGetValue: "CFNumberGetValue" [
				cf			[int-ptr!]
				theType		[integer!]
				valuePtr	[int-ptr!]
				return:		[logic!]
			]
			CFStringGetCString: "CFStringGetCString" [
				cf			[int-ptr!]
				buff		[byte-ptr!]
				size		[integer!]
				encode		[integer!]
				return:		[logic!]
			]
			__CFStringMakeConstantString: "__CFStringMakeConstantString" [
				str			[c-string!]
				return:		[c-string!]
			]
			CFRelease: "CFRelease" [
				cf			[int-ptr!]
			]
		]
	]

	kIOUSBDeviceUserClientTypeID: as int-ptr! 0
	kIOCFPlugInInterfaceID: as int-ptr! 0
	kIOUSBDeviceInterfaceID: as int-ptr! 0
	kIOUSBInterfaceUserClientTypeID: as int-ptr! 0
	kIOUSBInterfaceInterfaceID550: as int-ptr! 0

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
		clear-interface-list pNode/interface-entry
		free as byte-ptr! pNode
	]

	enum-usb-device: func [
		device-list			[list-entry!]
		/local
			dict			[integer!]
			iter			[integer!]
			service			[int-ptr!]
			path			[byte-ptr!]
			path-len		[integer!]
			name			[c-string!]
			serial-num		[c-string!]
			interface		[integer!]
			p-itf			[integer!]
			score			[integer!]
			this			[this!]
			itf				[IOUSBInterfaceInterface]
			guid			[UUID! value]
			vid				[integer!]
			pid				[integer!]
			dev-ifc			[IOUSBDeviceInterface]
			kr				[integer!]
			pNode			[DEVICE-INFO-NODE!]
			len				[integer!]
	][
		path: allocate 512
		if path = null [exit]
		iter: 0
		dict: IOServiceMatching "IOUSBDevice"
		if 0 <> IOServiceGetMatchingServices kIOMasterPortDefault dict :iter [free path exit]

		unless IOIteratorIsValid iter [free path exit]
		while [
			service: IOIteratorNext iter
			service <> null
		][
			path/1: null-byte
			kr: IORegistryEntryGetPath service kIOServicePlane as c-string! path
			if kr <> 0 [IOObjectRelease service continue]
			path-len: length? as c-string! path
			if path-len = 0 [IOObjectRelease service continue]
			name: get-string-property service kUSBProductName
			serial-num: get-string-property service kUSBSerialNum
			interface: 0
			p-itf: as-integer :interface
			score: 0
			kr: IOCreatePlugInInterfaceForService
					service
					kIOUSBDeviceUserClientTypeID
					kIOCFPlugInInterfaceID
					:p-itf
					:score

			if any [kr <> 0 zero? p-itf][IOObjectRelease service continue]
			this: as this! p-itf
			itf: as IOUSBInterfaceInterface this/vtbl
			guid: CFUUIDGetUUIDBytes kIOUSBDeviceInterfaceID
			kr: itf/QueryInterface this guid :interface
			itf/Release this
			if kr <> 0 [IOObjectRelease service continue]
			vid: 0 pid: 0
			this: as this! interface
			dev-ifc: as IOUSBDeviceInterface this/vtbl
			kr: dev-ifc/GetDeviceVendor this :vid
			if kr <> 0 [IOObjectRelease service continue]
			kr: dev-ifc/GetDeviceProduct this :pid
			if kr <> 0 [IOObjectRelease service continue]
			pNode: as DEVICE-INFO-NODE! allocate size? DEVICE-INFO-NODE!
			if pNode = null [IOObjectRelease service continue]
			set-memory as byte-ptr! pNode null-byte size? DEVICE-INFO-NODE!
			dlink/init pNode/interface-entry
			pNode/path: as c-string! allocate path-len + 1
			copy-memory as byte-ptr! pNode/path path path-len + 1
			if name <> null [
				pNode/name: as byte-ptr! name
				pNode/name-len: (length? name) + 1
			]
			if serial-num <> null [
				pNode/serial-num: serial-num
			]
			pNode/vid: vid
			pNode/pid: pid
			enum-children pNode/interface-entry service
			IOObjectRelease service
			dlink/append device-list as list-entry! pNode
		]
		IOObjectRelease as int-ptr! iter
		free path
	]

	get-service-from-id: func [
		id					[USB-DEVICE-ID! value]
		pserive				[int-ptr!]
		return:				[logic!]
		/local
			dict			[integer!]
			service			[int-ptr!]
	][
		dict: IORegistryEntryIDMatching id
		if dict = 0 [return false]
		service: IOServiceGetMatchingService kIOMasterPortDefault dict
		if service = null [return false]
		pserive/value: as integer! service
		true
	]

	get-int-property: func [
		entry			[int-ptr!]
		key				[c-string!]
		pvalue			[int-ptr!]
		return:			[logic!]
		/local
			cf-str		[c-string!]
			ref			[int-ptr!]
			value		[integer!]
	][
		pvalue/value: 0
		cf-str: CFSTR(key)
		ref: IORegistryEntryCreateCFProperty entry cf-str kCFAllocatorDefault 0
		if ref = null [return false]
		if (CFGetTypeID ref) = CFNumberGetTypeID [
			if CFNumberGetValue ref kCFNumberSInt32Type pvalue [
				CFRelease ref
				return true
			]
		]
		CFRelease ref
		false
	]

	get-string-property: func [
		entry			[int-ptr!]
		key				[c-string!]
		return:			[c-string!]
		/local
			cf-str		[c-string!]
			ref			[int-ptr!]
			buf			[byte-ptr!]
	][
		cf-str: CFSTR(key)
		ref: IORegistryEntryCreateCFProperty entry cf-str kCFAllocatorDefault 0
		if ref = null [
			return null
		]
		if (CFGetTypeID ref) = CFStringGetTypeID [
			buf: allocate 256
			if CFStringGetCString ref buf 256 kCFStringEncodingASCII [
				CFRelease ref
				return as c-string! buf
			]
		]
		CFRelease ref
		null
	]

	enum-children: func [
		list				[list-entry!]
		service				[int-ptr!]
		/local
			iter			[integer!]
			path			[byte-ptr!]
			path-len		[integer!]
			name			[c-string!]
			p-itf			[integer!]
			score			[integer!]
			kr				[integer!]
			itf-ser			[int-ptr!]
			actual-num		[integer!]
			this			[this!]
			itf				[IOUSBInterfaceInterface]
			guid			[UUID! value]
			interface		[integer!]
			pNode			[INTERFACE-INFO-NODE!]
			saved			[integer!]
			len				[integer!]
	][
		path: allocate 512
		if path = null [exit]
		iter: 0 p-itf: 0 score: 0 actual-num: 0 interface: 0
		kr: IORegistryEntryGetChildIterator service kIOServicePlane :iter
		if kr <> 0 [free path exit]
		while [
			itf-ser: IOIteratorNext iter
			itf-ser <> null
		][
			unless IOObjectConformsTo itf-ser kIOUSBInterfaceClassName [
				IOObjectRelease itf-ser
				continue
			]
			path/1: null-byte
			kr: IORegistryEntryGetPath itf-ser kIOServicePlane as c-string! path
			if kr <> 0 [IOObjectRelease itf-ser continue]
			path-len: length? as c-string! path
			if path-len = 0 [IOObjectRelease itf-ser continue]
			name: get-string-property itf-ser kUSBInterfaceName
			kr: IOCreatePlugInInterfaceForService
				itf-ser
				kIOUSBInterfaceUserClientTypeID
				kIOCFPlugInInterfaceID
				:p-itf
				:score
			IOObjectRelease itf-ser
			if any [kr <> 0 zero? p-itf][IOObjectRelease itf-ser continue]
			this: as this! p-itf
			itf: as IOUSBInterfaceInterface this/vtbl
			guid: CFUUIDGetUUIDBytes kIOUSBInterfaceInterfaceID550
			itf/QueryInterface this guid :interface
			itf/Release this
			this: as this! interface
			itf: as IOUSBInterfaceInterface this/vtbl
			;if 0 <> itf/USBInterfaceOpen this [print-line "open failed" continue]
			kr: itf/GetInterfaceNumber this :actual-num
			if kr <> 0 [IOObjectRelease itf-ser continue]

			pNode: as INTERFACE-INFO-NODE! allocate size? INTERFACE-INFO-NODE!
			if pNode = null [IOObjectRelease itf-ser continue]
			set-memory as byte-ptr! pNode null-byte size? INTERFACE-INFO-NODE!
			pNode/interface-num: actual-num
			pNode/path: as c-string! allocate path-len + 1
			copy-memory as byte-ptr! pNode/path path path-len + 1
			if name <> null [
				pNode/name: as byte-ptr! name
				pNode/name-len: (length? name) + 1
			]
			dlink/append list as list-entry! pNode
		]
		IOObjectRelease as int-ptr! iter
		free path
	]

	enum-all-devices: does [
		enum-usb-device device-list
	]

	init: does [
		kIOUSBDeviceUserClientTypeID: CFUUIDGetConstantUUIDWithBytes kCFAllocatorDefault
			#"^(9D)" #"^(C7)" #"^(B7)" #"^(80)" #"^(9E)" #"^(C0)" #"^(11)" #"^(D4)"
			#"^(A5)" #"^(4F)" #"^(00)" #"^(0A)" #"^(27)" #"^(05)" #"^(28)" #"^(61)"

		kIOCFPlugInInterfaceID: CFUUIDGetConstantUUIDWithBytes kCFAllocatorDefault
			#"^(C2)" #"^(44)" #"^(E8)" #"^(58)" #"^(10)" #"^(9C)" #"^(11)" #"^(D4)"
			#"^(91)" #"^(D4)" #"^(00)" #"^(50)" #"^(E4)" #"^(C6)" #"^(42)" #"^(6F)"

		kIOUSBDeviceInterfaceID: CFUUIDGetConstantUUIDWithBytes kCFAllocatorDefault
			#"^(5C)" #"^(81)" #"^(87)" #"^(D0)" #"^(9E)" #"^(F3)" #"^(11)" #"^(D4)"
			#"^(8B)" #"^(45)" #"^(00)" #"^(0A)" #"^(27)" #"^(05)" #"^(28)" #"^(61)"

		kIOUSBInterfaceUserClientTypeID: CFUUIDGetConstantUUIDWithBytes kCFAllocatorDefault
			#"^(2D)" #"^(97)" #"^(86)" #"^(C6)" #"^(9E)" #"^(F3)" #"^(11)" #"^(D4)"
			#"^(AD)" #"^(51)" #"^(00)" #"^(0A)" #"^(27)" #"^(05)" #"^(28)" #"^(61)"

		kIOUSBInterfaceInterfaceID550: CFUUIDGetConstantUUIDWithBytes kCFAllocatorDefault
			#"^(6A)" #"^(E4)" #"^(4D)" #"^(3F)" #"^(EB)" #"^(45)" #"^(48)" #"^(7F)"
			#"^(8E)" #"^(8E)" #"^(B9)" #"^(3B)" #"^(99)" #"^(F8)" #"^(EA)" #"^(9E)"

		dlink/init device-list

	]
]

