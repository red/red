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

INTERFACE-INFO-NODE!: alias struct! [
	entry				[list-entry! value]
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
	inst				[integer!]
	serial-num			[c-string!]
	device-desc			[byte-ptr!]
	device-desc-len		[integer!]
	config-desc			[byte-ptr!]
	config-desc-len		[integer!]
	interface-entry		[list-entry! value]
	interface			[INTERFACE-INFO-NODE!]
]

usb-device: context [

	device-list: declare list-entry!

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
				key				[int-ptr!]
				allocator		[integer!]
				options			[integer!]
				return:			[int-ptr!]
			]
			IOObjectRelease: "IOObjectRelease" [
				object 		[int-ptr!]
				return: 	[integer!]
			]
		]
		"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
			kIOMasterPortDefault: "kIOMasterPortDefault" [integer!]
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
		]
	]

	kIOUSBDeviceUserClientTypeID: as int-ptr! 0
	kIOCFPlugInInterfaceID: as int-ptr! 0
	kIOUSBDeviceInterfaceID: as int-ptr! 0
	kIOUSBInterfaceUserClientTypeID: as int-ptr! 0
	kIOUSBInterfaceInterfaceID550: as int-ptr! 0

	enum-all-devices: func [
		return:				[int-ptr!]
		/local
			dict			[integer!]
			iter			[integer!]
			dev				[int-ptr!]
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
	][
		iter: 0
		dict: IOServiceMatching "IOUSBDevice"
		IOServiceGetMatchingServices kIOMasterPortDefault dict :iter

		unless IOIteratorIsValid iter [return null]
		while [
			dev: IOIteratorNext iter
			dev <> null
		][
			interface: 0
			p-itf: as-integer :interface
			score: 0
			kr: IOCreatePlugInInterfaceForService
					dev
					kIOUSBDeviceUserClientTypeID
					kIOCFPlugInInterfaceID
					:p-itf
					:score
			IOObjectRelease dev

			if any [kr <> 0 zero? p-itf][continue]
			this: as this! p-itf
			itf: as IOUSBInterfaceInterface this/vtbl
			guid: CFUUIDGetUUIDBytes kIOUSBDeviceInterfaceID
			itf/QueryInterface this guid :interface
			itf/Release this

			vid: 0 pid: 0
			this: as this! interface
			dev-ifc: as IOUSBDeviceInterface this/vtbl
			dev-ifc/GetDeviceVendor this :vid
			dev-ifc/GetDeviceProduct this :pid
			print-line vid
			print-line pid
			pNode: as DEVICE-INFO-NODE! allocate size? DEVICE-INFO-NODE!
			if pNode = null [continue]
			set-memory as byte-ptr! pNode null-byte size? DEVICE-INFO-NODE!
			dlink/init pNode/interface-entry
			if all [
				vid <> 0
				pid <> 0
			][
				enum-children pNode/interface-entry this vid pid
			]
		]
		IOObjectRelease as int-ptr! iter
		null
	]

	enum-children: func [
		list				[list-entry!]
		this				[this!]
		vid					[integer!]
		pid					[integer!]
		/local
			dev-ifc			[IOUSBDeviceInterface]
			req				[IOUSBFindInterfaceRequest value]
			iter			[integer!]
			saved			[int-ptr!]
			interface		[integer!]
			p-itf			[integer!]
			score			[integer!]
			dev				[int-ptr!]
			kr				[integer!]
			itf				[IOUSBInterfaceInterface]
			guid			[UUID! value]
			itf-num			[integer!]
	][
		iter: 0 p-itf: 0 score: 0
		interface: 0 itf-num: 0
		dev-ifc: as IOUSBDeviceInterface this/vtbl
		saved: system/stack/align
		push 0
		dev-ifc/CreateInterfaceIterator this :req :iter
		system/stack/top: saved
		while [
			dev: IOIteratorNext iter
			dev <> null
		][
			kr: IOCreatePlugInInterfaceForService
				dev
				kIOUSBInterfaceUserClientTypeID
				kIOCFPlugInInterfaceID
				:p-itf
				:score
			IOObjectRelease dev
			if any [kr <> 0 zero? p-itf][continue]

			this: as this! p-itf
			itf: as IOUSBInterfaceInterface this/vtbl
			guid: CFUUIDGetUUIDBytes kIOUSBInterfaceInterfaceID550
			itf/QueryInterface this guid :interface
			itf/Release this
			this: as this! interface
			itf: as IOUSBInterfaceInterface this/vtbl
			itf/GetInterfaceNumber this :itf-num
			print-line itf-num
		]
		IOObjectRelease as int-ptr! iter


	]

	init: does [
		kIOUSBDeviceUserClientTypeID: CFUUIDGetConstantUUIDWithBytes null
			#"^(9D)" #"^(C7)" #"^(B7)" #"^(80)" #"^(9E)" #"^(C0)" #"^(11)" #"^(D4)"
			#"^(A5)" #"^(4F)" #"^(00)" #"^(0A)" #"^(27)" #"^(05)" #"^(28)" #"^(61)"

		kIOCFPlugInInterfaceID: CFUUIDGetConstantUUIDWithBytes null
			#"^(C2)" #"^(44)" #"^(E8)" #"^(58)" #"^(10)" #"^(9C)" #"^(11)" #"^(D4)"
			#"^(91)" #"^(D4)" #"^(00)" #"^(50)" #"^(E4)" #"^(C6)" #"^(42)" #"^(6F)"

		kIOUSBDeviceInterfaceID: CFUUIDGetConstantUUIDWithBytes null
			#"^(5C)" #"^(81)" #"^(87)" #"^(D0)" #"^(9E)" #"^(F3)" #"^(11)" #"^(D4)"
			#"^(8B)" #"^(45)" #"^(00)" #"^(0A)" #"^(27)" #"^(05)" #"^(28)" #"^(61)"

		kIOUSBInterfaceUserClientTypeID: CFUUIDGetConstantUUIDWithBytes null
			#"^(2D)" #"^(97)" #"^(86)" #"^(C6)" #"^(9E)" #"^(F3)" #"^(11)" #"^(D4)"
			#"^(AD)" #"^(51)" #"^(00)" #"^(0A)" #"^(27)" #"^(05)" #"^(28)" #"^(61)"

		kIOUSBInterfaceInterfaceID550: CFUUIDGetConstantUUIDWithBytes null
			#"^(6A)" #"^(E4)" #"^(4D)" #"^(3F)" #"^(EB)" #"^(45)" #"^(48)" #"^(7F)"
			#"^(8E)" #"^(8E)" #"^(B9)" #"^(3B)" #"^(99)" #"^(F8)" #"^(EA)" #"^(9E)"

		dlink/init device-list

	]
]

