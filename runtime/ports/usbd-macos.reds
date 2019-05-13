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

#define pthread_t int-ptr!

pthread_cond_t: alias struct! [
	__sig		[integer!]
	opaque1		[integer!]	;opaque size =24
	opaque2		[integer!]
	opaque3		[integer!]
	opaque4		[integer!]
	opaque5		[integer!]
	opaque6		[integer!]
]

pthread_mutex_t: alias struct! [
	__sig		[integer!]
	opaque1		[integer!]	;opaque size =40
	opaque2		[integer!]
	opaque3		[integer!]
	opaque4		[integer!]
	opaque5		[integer!]
	opaque6		[integer!]
	opaque7		[integer!]
	opaque8		[integer!]
	opaque9		[integer!]
	opaque10	[integer!]
]
pthread_barrier_t: alias struct! [
	mutex		[pthread_mutex_t value]
	cond		[pthread_cond_t value]
	count		[integer!]
	trip_count	[integer!]
]

BARRIER-THREAD!: alias struct! [
	thread					[pthread_t]
	mutex					[pthread_mutex_t value]		; pthread_mutex_t is int
	condition				[pthread_cond_t value]
	barrier					[pthread_barrier_t value]
	shutdown_barrier		[pthread_barrier_t value]
	shutdown_thread			[integer!]
	run-loop				[int-ptr!]
	run-loop-mode			[int-ptr!]
	source					[int-ptr!]
	list					[list-entry! value]			;-- for input report list
	trigger?				[logic!]					;-- trigger kevent
	udata					[int-ptr!]					;-- for kqueue udata
]

WRITE-THREAD!: alias struct! [
	thread					[pthread_t]
	mutex					[pthread_mutex_t value]		; pthread_mutex_t is int
	trigger?				[logic!]					;-- trigger kevent
	buffer					[byte-ptr!]					;-- data
	buflen					[integer!]
	udata					[int-ptr!]					;-- for kqueue udata
]

INPUT-REPORT!: alias struct! [
	entry		[list-entry! value]
	type		[integer!]
	length		[integer!]								;-- data[0] = report id
]

usb-device: context [

	device-list: declare list-entry!

	#define kIOServicePlane						"IOService"
	#define kIOUSBDeviceClassName				"IOUSBDevice"
	#define kIOUSBDeviceClassNameNew			"IOUSBHostDevice"		;- Macos version >= 10.11
	#define kIOUSBInterfaceClassName			"IOUSBInterface"
	#define kIOHIDDevice						"IOHIDDevice"
	#define kCFNumberSInt8Type					1
	#define kCFNumberSInt32Type					3
	;#define kCFAllocatorDefault					null
	#define kCFStringEncodingASCII				0600h
	;#define kCFStringEncodingUTF8				08000100h
	#define kUSBProductName						"USB Product Name"
	#define kUSBInterfaceName					"USB Interface Name"
	#define kUSBSerialNum						"USB Serial Number"
	#define kIOHIDDeviceUsageKey				"DeviceUsage"
	#define kIOHIDDeviceUsagePageKey			"DeviceUsagePage"
	#define kIOHIDDeviceUsagePairsKey			"DeviceUsagePairs"
	#define kIOHIDLocationIDKey					"LocationID"
	#define kIOHIDMaxInputReportSizeKey			"MaxInputReportSize"
	#define kIOHIDMaxOutputReportSizeKey		"MaxOutputReportSize"
	#define kIOHIDMaxFeatureReportSizeKey		"MaxFeatureReportSize"
	#define kIOHIDOptionsTypeSeizeDevice		1

	#define CFSTR(cStr)							[__CFStringMakeConstantString cStr]
	;#define CFString(cStr)						[CFStringCreateWithCString kCFAllocatorDefault cStr kCFStringEncodingASCII]

	#define kUSBControl							0
	#define kUSBIsoc							1
	#define kUSBBulk							2
	#define kUSBInterrupt						3

	#define kIOHIDReportTypeInput				0
	#define kIOHIDReportTypeOutput				1
	#define kIOHIDReportTypeFeature				2
	#define kIOHIDReportTypeCount				3



	CFRunLoopSourceContext: alias struct! [
		version 			[integer!]
		info 				[int-ptr!]
		retain				[int-ptr!]
		release 			[int-ptr!]
		copyDescription		[int-ptr!]
		equal				[int-ptr!]
		hash 				[int-ptr!]
		schedule 			[int-ptr!]
		cancel 				[int-ptr!]
		perform 			[int-ptr!]
	]

	this!: alias struct! [vtbl [integer!]]

	UUID!: alias struct! [
		data1		[integer!]
		data2		[integer!]
		data3		[integer!]
		data4		[integer!]
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

	IOHIDDeviceDeviceInterface: alias struct! [
		IUNKNOWN_C_GUTS
		open							[function! [this [this!] options [integer!] return: [integer!]]]
		close							[function! [this [this!] options [integer!] return: [integer!]]]
		getProperty						[function! [this [this!] key [c-string!] ref [int-ptr!] return: [integer!]]]
		setProperty						[function! [this [this!] key [c-string!] ref [int-ptr!] return: [integer!]]]
		getAsyncEventSource				[function! [this [this!] source [int-ptr!] return: [integer!]]]
		copyMatchingElements			[function! [this [this!] dict [int-ptr!] elem [int-ptr!] options [integer!] return: [integer!]]]
		setValue						[function! [this [this!] elem [int-ptr!] value [int-ptr!] timeout [integer!] callback [integer!] ctx [int-ptr!] options [integer!] return: [integer!]]]
		getValue						[function! [this [this!] elem [int-ptr!] value [int-ptr!] timeout [integer!] callback [integer!] ctx [int-ptr!] options [integer!] return: [integer!]]]
		setInputReportCallback			[function! [this [this!] report [byte-ptr!] len [integer!] callback [integer!] ctx [int-ptr!] options [integer!] return: [integer!]]]
		setReport						[function! [this [this!] type [integer!] id [integer!] report [int-ptr!] len [integer!] timeout [integer!] callback [integer!] ctx [int-ptr!] options [integer!] return: [integer!]]]
		getReport						[function! [this [this!] type [integer!] id [integer!] report [int-ptr!] plen [int-ptr!] timeout [integer!] callback [integer!] ctx [int-ptr!] options [integer!] return: [integer!]]]
	]

	#import [
		LIBC-file cdecl [
				pthread_mutex_init: "pthread_mutex_init" [
					mutex 		[int-ptr!]
					attr 		[int-ptr!]
					return: 	[integer!]
				]
				pthread_cond_init: "pthread_cond_init" [
					cond 		[int-ptr!]
					attr 		[int-ptr!]
					return: 	[integer!]
				]
				pthread_mutex_destroy: "pthread_mutex_destroy" [
					mutex 		[int-ptr!]
					return: 	[integer!]
				]
				pthread_cond_destroy: "pthread_cond_destroy" [
					cond 		[int-ptr!]
					return: 	[integer!]
				]
				pthread_mutex_lock: "pthread_mutex_lock" [
					mutex 		[int-ptr!]
					return: 	[integer!]
				]
				pthread_mutex_unlock: "pthread_mutex_unlock" [
					mutex 		[int-ptr!]
					return: 	[integer!]
				]
				pthread_cond_broadcast: "pthread_cond_broadcast" [
					cond 		[int-ptr!]
					return: 	[integer!]
				]
				pthread_cond_wait: "pthread_cond_wait" [
					cond		[int-ptr!]
					mutex		[int-ptr!]
					return: 	[integer!]
				]
				pthread_create: "pthread_create" [
					restrict 	[int-ptr!]
					restrict1 	[int-ptr!]
					restrict2 	[int-ptr!]
					restrict3 	[int-ptr!]
					return: 	[integer!]
				]
				pthread_cond_signal: "pthread_cond_signal" [
					pthread_cond 	[int-ptr!]
					return: 		[integer!]
				]
				gettimeofday: "gettimeofday" [
					tv		[timeval!]
					tz		[integer!]			;-- obsolete
					return: [integer!]			;-- 0: success -1: failure
				]
				pthread_cond_timedwait: "pthread_cond_timedwait" [
					restrict	[int-ptr!]
					restrict1 	[int-ptr!]
					restrict3 	[timespec!]
					return: 	[integer!]
				]
				pthread_join: "pthread_join" [
					thread 		[pthread_t]
					retval 		[int-ptr!]
					return: 	[integer!]
				]
		]
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
				plane			[c-string!]   ;--size is 128
				path			[c-string!]   ;--size is 512
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
				key				[c-string!]
				allocator		[int-ptr!]
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
			IORegistryEntryFromPath: "IORegistryEntryFromPath" [
				masterPort 		[int-ptr!]
				path 			[c-string!]
				return: 		[int-ptr!]
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
			;-- HID API
			IOHIDDeviceCreate: "IOHIDDeviceCreate" [
				allocator		[int-ptr!]
				service			[int-ptr!]
				return:			[int-ptr!]
			]
			IOHIDDeviceGetProperty: "IOHIDDeviceGetProperty" [
				device			[int-ptr!]
				key				[c-string!]
				return:			[int-ptr!]
			]
			IOHIDDeviceOpen: "IOHIDDeviceOpen" [
				device			[int-ptr!]
				options			[integer!]
				return:			[integer!]
			]
			IOHIDDeviceClose: "IOHIDDeviceClose" [
				device			[int-ptr!]
				options			[integer!]
				return:			[integer!]
			]
			IOHIDDeviceRegisterRemovalCallback: "IOHIDDeviceRegisterRemovalCallback" [
				device			[int-ptr!]
				callback		[int-ptr!]
				context			[int-ptr!]
			]
			IOHIDDeviceRegisterInputReportCallback: "IOHIDDeviceRegisterInputReportCallback" [
				device			[int-ptr!]
				report			[byte-ptr!]
				reportlength	[integer!]
				callback		[int-ptr!]  ;--Pointer to a callback method of type IOHIDReportCallback.
				context			[int-ptr!]
			]
			IOHIDDeviceSetReportWithCallback: "IOHIDDeviceSetReportWithCallback" [
				device			[int-ptr!]
				type			[integer!]
				id				[integer!]
				report			[byte-ptr!]
				reportlength	[integer!]
				timeout			[float64!]
				callback		[int-ptr!]
				context			[int-ptr!]
				return:			[integer!]
			]
			IOHIDDeviceGetReportWithCallback: "IOHIDDeviceGetReportWithCallback" [
				device			[int-ptr!]
				type			[integer!]
				id				[integer!]
				report			[byte-ptr!]
				reportlength	[int-ptr!]
				timeout			[float64!]
				callback		[int-ptr!]
				context			[int-ptr!]
				return:			[integer!]
			]
			IOHIDDeviceSetReport: "IOHIDDeviceSetReport" [
				device			[int-ptr!]
				type			[integer!]
				id				[integer!]
				report			[byte-ptr!]
				reportlength	[integer!]
				return:			[integer!]
			]
			IOHIDDeviceScheduleWithRunLoop: "IOHIDDeviceScheduleWithRunLoop" [
				device 			[int-ptr!]
				runloop 		[int-ptr!]
				runLoopMode		[int-ptr!]
			]
			IOHIDDeviceUnscheduleFromRunLoop: "IOHIDDeviceUnscheduleFromRunLoop" [
				device 			[int-ptr!]
				runloop			[int-ptr!]
				runLoopMode		[int-ptr!]
			]
		]
		"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
			kCFRunLoopDefaultMode: "kCFRunLoopDefaultMode" [int-ptr!]
			kCFAllocatorDefault: "kCFAllocatorDefault" [int-ptr!]
			kIOMasterPortDefault: "kIOMasterPortDefault" [integer!]
			CFStringCreateWithCString: "CFStringCreateWithCString" [
				allocator		[int-ptr!]
				cStr			[c-string!]
				encoding		[integer!]
				return:			[c-string!]
			]
			CFUUIDGetConstantUUIDWithBytes: "CFUUIDGetConstantUUIDWithBytes" [
				allocator		[int-ptr!]
				byte0			[byte!]
				byte1			[byte!]
				byte2			[byte!]
				byte3			[byte!]
				byte4			[byte!]
				byte5			[byte!]
				byte6			[byte!]
				byte7			[byte!]
				byte8			[byte!]
				byte9			[byte!]
				byte10			[byte!]
				byte11			[byte!]
				byte12			[byte!]
				byte13			[byte!]
				byte14			[byte!]
				byte15			[byte!]
				return:			[int-ptr!]
			]
			CFUUIDGetUUIDBytes: "CFUUIDGetUUIDBytes" [
				guid			[int-ptr!]
				return:			[UUID! value]
			]
			CFGetTypeID: "CFGetTypeID" [
				cf				[int-ptr!]
				return:			[integer!]
			]
			CFNumberGetTypeID: "CFNumberGetTypeID" [
				return:			[integer!]
			]
			CFNumberGetValue: "CFNumberGetValue" [
				cf				[int-ptr!]
				theType			[integer!]
				valuePtr		[int-ptr!]
				return:			[logic!]
			]
			CFStringGetTypeID: "CFStringGetTypeID" [
				return:			[integer!]
			]
			CFStringGetCString: "CFStringGetCString" [
				cf				[int-ptr!]
				buff			[byte-ptr!]
				size			[integer!]
				encode			[integer!]
				return:			[logic!]
			]
			CFArrayGetTypeID: "CFArrayGetTypeID" [
				return:			[integer!]
			]
			CFArrayGetCount: "CFArrayGetCount" [
				cf				[int-ptr!]
				return:			[integer!]
			]
			CFArrayGetValueAtIndex: "CFArrayGetValueAtIndex" [
				cf				[int-ptr!]
				index			[integer!]
				return:			[int-ptr!]
			]
			CFDictionaryGetValue: "CFDictionaryGetValue" [
				dict			[int-ptr!]
				key				[c-string!]
				return:			[int-ptr!]
			]
			__CFStringMakeConstantString: "__CFStringMakeConstantString" [
				str				[c-string!]
				return:			[c-string!]
			]
			CFRelease: "CFRelease" [
				cf				[int-ptr!]
			]
			CFRunLoopGetCurrent: "CFRunLoopGetCurrent" [
				return:			[int-ptr!]
			]
			CFRunLoopGetMain: "CFRunLoopGetMain" [
				return:			[int-ptr!]
			]
			CFRunLoopStop: "CFRunLoopStop" [
				rl				[int-ptr!]
			]
			CFRunLoopSourceCreate: "CFRunLoopSourceCreate" [
				allocator		[int-ptr!]
				order			[integer!]
				context			[int-ptr!]
				return:			[int-ptr!]
			]
			CFRunLoopAddSource: "CFRunLoopAddSource" [
				rl				[int-ptr!]
				source			[int-ptr!]
				mode			[int-ptr!]
			]
			CFRunLoopSourceSignal: "CFRunLoopSourceSignal" [
				source			[int-ptr!]
			]
			CFRunLoopWakeUp: "CFRunLoopWakeUp" [
				rl				[int-ptr!]
			]
			CFRunLoopRunInMode: "CFRunLoopRunInMode" [
				mode 						[int-ptr!]
				seconds 					[float!]
				returnAfterSourceHandled	[logic!]
				return: 					[integer!]
			]
		]
	]

	kIOUSBDeviceUserClientTypeID: as int-ptr! 0
	kIOCFPlugInInterfaceID: as int-ptr! 0
	kIOUSBDeviceInterfaceID: as int-ptr! 0
	kIOUSBInterfaceUserClientTypeID: as int-ptr! 0
	kIOUSBInterfaceInterfaceID550: as int-ptr! 0
	kIOHIDDeviceTypeID: as int-ptr! 0
	kIOHIDDeviceDeviceInterfaceID: as int-ptr! 0

	pthread_barrier_init: func [
		barrier 	[pthread_barrier_t]
		count 		[integer!]
		return: 	[integer!]
	][
		if count = 0 [
			return -1
		]
		if (pthread_mutex_init :barrier/mutex null) < 0 [
			return -1
		]
		if (pthread_cond_init :barrier/cond null) < 0 [
			pthread_mutex_destroy :barrier/mutex
			return -1
		]
		barrier/trip_count: count
		barrier/count: 0
		0
	]

	pthread_barrier_destroy: func [
		barrier 		[pthread_barrier_t]
		return: 		[integer!]
	][
		pthread_cond_destroy :barrier/cond
		pthread_mutex_destroy :barrier/mutex
		0
	]

	pthread_barrier_wait: function [
		barrier			[pthread_barrier_t]
		return: 		[integer!]
	][
		pthread_mutex_lock :barrier/mutex
		barrier/count: barrier/count + 1
		either barrier/count >= barrier/trip_count [
			barrier/count: 0
			pthread_cond_broadcast :barrier/cond
			pthread_mutex_unlock :barrier/mutex
			return 1
		][
			pthread_cond_wait :barrier/cond :barrier/mutex
			pthread_mutex_unlock :barrier/mutex
			return 0
		]
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
			LocationID		[integer!]
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
		dict: IOServiceMatching kIOUSBDeviceClassNameNew
		if dict = 0 [
			dict: IOServiceMatching kIOUSBDeviceClassName
		]
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
			LocationID: 0
			kr: dev-ifc/GetLocationID this :LocationID
			if kr <> 0 [IOObjectRelease service continue]
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
			name: get-string-property service kUSBProductName
			if name <> null [
				pNode/name: as byte-ptr! name
				pNode/name-len: (length? name) + 1
			]
			serial-num: get-string-property service kUSBSerialNum
			if serial-num <> null [
				pNode/serial-num: serial-num
			]
			pNode/inst: LocationID
			pNode/vid: vid
			pNode/pid: pid
			enum-children pNode/interface-entry service LocationID
			IOObjectRelease service
			dlink/append device-list as list-entry! pNode
		]
		IOObjectRelease as int-ptr! iter
		free path
	]

	enum-children: func [
		list				[list-entry!]
		service				[int-ptr!]
		location-id			[integer!]
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
			;either 0 <> itf/USBInterfaceOpen this [print-line "busy"][print-line "not busy"]
			kr: itf/GetInterfaceNumber this :actual-num
			if kr <> 0 [IOObjectRelease itf-ser continue]

			pNode: as INTERFACE-INFO-NODE! allocate size? INTERFACE-INFO-NODE!
			if pNode = null [IOObjectRelease itf-ser continue]
			set-memory as byte-ptr! pNode null-byte size? INTERFACE-INFO-NODE!
			pNode/interface-num: actual-num
			pNode/path: as c-string! allocate path-len + 1
			copy-memory as byte-ptr! pNode/path path path-len + 1
			if hid-device? pNode location-id [
				dlink/append list as list-entry! pNode
				IOObjectRelease itf-ser
				continue
			]
			name: interface-name as c-string! path
			if name <> null [
				pNode/name: as byte-ptr! name
				pNode/name-len: (length? name) + 1
			]
			pNode/hType: DRIVER-TYPE-WINUSB
			dlink/append list as list-entry! pNode
		]
		IOObjectRelease as int-ptr! iter
		free path
	]

	interface-name: func [
		path				[c-string!]
		return:				[c-string!]
		/local
			p				[c-string!]
			len				[integer!]
			ret				[c-string!]
	][
		p: find-last-slash path
		if p = null [return null]
		len: length? p
		ret: as c-string! allocate len - 1
		if ret = null [return null]
		copy-memory as byte-ptr! ret as byte-ptr! p len - 2
		len: len - 1
		ret/len: null-byte
		ret
	]

	find-last-slash: func [
		path				[c-string!]
		return:				[c-string!]
		/local
			len				[integer!]
			p				[c-string!]
	][
		len: length? path
		if len = 0 [return null]
		p: path + len - 1
		loop len [
			if p/1 = #"/" [
				return p + 1
			]
			p: p - 1
		]
		null
	]

	find-second-last-slash: func [
		path				[c-string!]
		return:				[c-string!]
		/local
			len				[integer!]
			first?			[logic!]
			p				[c-string!]
	][
		len: length? path
		if len = 0 [return null]
		first?: true
		p: path + len - 1
		loop len [
			if p/1 = #"/" [
				either first? [
					first?: false
				][
					return p + 1
				]
			]
			p: p - 1
		]
		null
	]

	hid-path-contain?: func [
		hpath				[c-string!]
		ipath				[c-string!]
		return:				[logic!]
		/local
			hp				[c-string!]
			ip				[c-string!]
			hlen			[integer!]
			ilen			[integer!]
	][
		hp: find-second-last-slash hpath
		if hp = null [return false]
		ip: find-last-slash ipath
		if ip = null [return false]
		ilen: length? ip
		if 0 = compare-memory as byte-ptr! hp as byte-ptr! ip ilen [
			ilen: ilen + 1
			if hp/ilen = #"/" [
				return true
			]
		]
		false
	]

	hid-device?: func [
		pNode				[INTERFACE-INFO-NODE!]
		location-id			[integer!]
		return:				[logic!]
		/local
			dict			[integer!]
			iter			[integer!]
			service			[int-ptr!]
			path			[byte-ptr!]
			path-len		[integer!]
			interface		[integer!]
			p-itf			[integer!]
			score			[integer!]
			this			[this!]
			itf				[IOUSBInterfaceInterface]
			guid			[UUID! value]
			LocationID		[integer!]
			dev-ifc			[IOHIDDeviceDeviceInterface]
			kr				[integer!]
			ref				[integer!]
	][
		if pNode/path = null [return false]
		path: allocate 512
		if path = null [return false]
		iter: 0 ref: 0
		dict: IOServiceMatching kIOHIDDevice
		if 0 <> IOServiceGetMatchingServices kIOMasterPortDefault dict :iter [free path return false]

		unless IOIteratorIsValid iter [free path return false]
		while [
			service: IOIteratorNext iter
			service <> null
		][
			path/1: null-byte
			kr: IORegistryEntryGetPath service kIOServicePlane as c-string! path
			if kr <> 0 [IOObjectRelease service continue]
			path-len: length? as c-string! path
			if path-len = 0 [IOObjectRelease service continue]
			;
			interface: 0
			p-itf: as-integer :interface
			score: 0
			kr: IOCreatePlugInInterfaceForService
					service
					kIOHIDDeviceTypeID
					kIOCFPlugInInterfaceID
					:p-itf
					:score

			if any [kr <> 0 zero? p-itf][IOObjectRelease service continue]
			this: as this! p-itf
			itf: as IOUSBInterfaceInterface this/vtbl
			guid: CFUUIDGetUUIDBytes kIOHIDDeviceDeviceInterfaceID
			kr: itf/QueryInterface this guid :interface
			itf/Release this
			if kr <> 0 [IOObjectRelease service continue]
			this: as this! interface
			dev-ifc: as IOHIDDeviceDeviceInterface this/vtbl
			LocationID: 0
			kr: dev-ifc/getProperty this CFSTR(kIOHIDLocationIDKey) :ref
			if kr <> 0 [IOObjectRelease service continue]
			get-int-from-cfnumber as int-ptr! ref :LocationID
			if ref <> 0 [IOObjectRelease as int-ptr! ref]
			if LocationID <> location-id [IOObjectRelease service continue]
			unless hid-path-contain? as c-string! path pNode/path [
				IOObjectRelease service continue
			]
			free as byte-ptr! pNode/path
			pNode/path: as c-string! allocate path-len + 1
			copy-memory as byte-ptr! pNode/path path path-len + 1
			IOObjectRelease service
			IOObjectRelease as int-ptr! iter
			free path
			pNode/hType: DRIVER-TYPE-HIDUSB
			return true
		]
		IOObjectRelease as int-ptr! iter
		free path
		false
	]

	get-int-from-cfnumber: func [
		ref				[int-ptr!]
		pvalue			[int-ptr!]
		return:			[logic!]
	][
		if ref = null [return false]
		if (CFGetTypeID ref) = CFNumberGetTypeID [
			if CFNumberGetValue ref kCFNumberSInt32Type pvalue [
				return true
			]
		]
		false
	]

	get-int-property: func [
		entry			[int-ptr!]
		key				[c-string!]
		pvalue			[int-ptr!]
		return:			[logic!]
		/local
			cf-str		[c-string!]
			ref			[int-ptr!]
			success		[logic!]
	][
		pvalue/value: 0
		cf-str: CFSTR(key)
		ref: IORegistryEntryCreateCFProperty entry cf-str kCFAllocatorDefault 0
		success: get-int-from-cfnumber ref pvalue
		if ref <> null [CFRelease ref]
		success
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
		if ref = null [return null]
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

	get-hid-int-property: func [
		device			[int-ptr!]
		key				[c-string!]
		pvalue			[int-ptr!]
		return:			[logic!]
		/local
			cf-str		[c-string!]
			ref			[int-ptr!]
			success		[logic!]
	][
		pvalue/value: 0
		cf-str: CFSTR(key)
		ref: IOHIDDeviceGetProperty device cf-str
		success: get-int-from-cfnumber ref pvalue
		if ref <> null [CFRelease ref]
		success
	]

	get-hid-string-property: func [
		device			[int-ptr!]
		key				[c-string!]
		return:			[c-string!]
		/local
			cf-str		[c-string!]
			ref			[int-ptr!]
			buf			[byte-ptr!]
	][
		cf-str: CFSTR(key)
		ref: IOHIDDeviceGetProperty device cf-str
		if ref = null [return null]
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

	get-hid-usage-property: func [
		device			[int-ptr!]
		pnum			[int-ptr!]
		return:			[HID-COLLECTION!]
		/local
			cf-str		[c-string!]
			ref			[int-ptr!]
			num			[integer!]
			cols		[HID-COLLECTION!]
			col			[HID-COLLECTION!]
			i			[integer!]
			dict		[int-ptr!]
			ref-use		[int-ptr!]
			ref-page	[int-ptr!]
			usage		[integer!]
			page		[integer!]
			success		[logic!]
	][
		pnum/value: 0
		cf-str: CFSTR(kIOHIDDeviceUsagePairsKey)
		ref: IOHIDDeviceGetProperty device cf-str
		if ref = null [return null]
		if (CFGetTypeID ref) = CFArrayGetTypeID [
			num: CFArrayGetCount ref
			if num > 0 [
				pnum/value: num
				cols: as HID-COLLECTION! allocate num * size? HID-COLLECTION!
				if cols = null [CFRelease ref return null]
				i: 0
				loop num [
					dict: CFArrayGetValueAtIndex ref i
					if dict = null [break]
					ref-use: CFDictionaryGetValue dict CFSTR(kIOHIDDeviceUsageKey)
					col: cols + i
					col/index: i
					usage: 0
					success: get-int-from-cfnumber ref-use :usage
					;if ref-use <> null [CFRelease ref-use]
					col/usage: usage
					print-line usage

					ref-page: CFDictionaryGetValue dict CFSTR(kIOHIDDeviceUsagePageKey)
					page: 0
					success: get-int-from-cfnumber ref-page :page
					;if ref-page <> null [CFRelease ref-page]
					col/usage-page: page
					print-line page
					i: i + 1
				]
				if i <> 0 [
					CFRelease ref
					return cols
				]
				free as byte-ptr! cols
			]
		]
		CFRelease ref
		null
	]

	enum-all-devices: does [
		enum-usb-device device-list
	]

	find-usb: func [
		device-list				[list-entry!]
		vid						[integer!]
		pid						[integer!]
		sn						[c-string!]
		mi						[integer!]
		col						[integer!]
		return:					[DEVICE-INFO-NODE!]
		/local
			entry				[list-entry!]
			dnode				[DEVICE-INFO-NODE!]
			len					[integer!]
			len2				[integer!]
			children			[list-entry!]
			child-entry			[list-entry!]
			inode				[INTERFACE-INFO-NODE!]
	][
		entry: device-list/next
		while [entry <> device-list][
			dnode: as DEVICE-INFO-NODE! entry
			if all [
				dnode/vid = vid
				dnode/pid = pid
			][
				len: length? sn
				len2: length? dnode/serial-num
				if all [
					len <> 0
					len = len2
					0 = compare-memory as byte-ptr! sn as byte-ptr! dnode/serial-num len
				][
					children: dnode/interface-entry
					child-entry: children/next
					while [child-entry <> children][
						inode: as INTERFACE-INFO-NODE! child-entry
						if any [
							mi = 255
							inode/interface-num = 255
						][
							dlink/remove-entry device-list entry/prev entry/next
							clear-device-list device-list
							dnode/interface: inode
							return dnode
						]
						if mi = inode/interface-num [
							dlink/remove-entry device-list entry/prev entry/next
							clear-device-list device-list
							dnode/interface: inode
							return dnode
						]
						child-entry: child-entry/next
					]
				]
			]
			entry: entry/next
		]
		clear-device-list device-list
		null
	]

	open: func [
		vid						[integer!]
		pid						[integer!]
		sn						[c-string!]
		mi						[integer!]
		col						[integer!]
		return:					[DEVICE-INFO-NODE!]
		/local
			dnode				[DEVICE-INFO-NODE!]
			inode				[INTERFACE-INFO-NODE!]
	][
		clear-device-list device-list
		enum-usb-device device-list
		dnode: find-usb device-list vid pid sn mi col
		if dnode = null [return null]
		inode: dnode/interface
		if USB-ERROR-OK <> open-inteface inode [
			free-device-info-node dnode
			return null
		]
		print-line "open"
		print-line inode/hDev
		;print-line inode/hInf
		dnode
	]

	open-inteface: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
	][
		case [
			pNode/hType = DRIVER-TYPE-WINUSB [
				return open-winusb pNode
			]
			pNode/hType = DRIVER-TYPE-HIDUSB [
				return open-hidusb pNode
			]
			true [
				return USB-ERROR-UNSUPPORT
			]
		]
	]

	open-winusb: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
		/local
			index				[integer!]
			pipe-id				[integer!]
	][
		USB-ERROR-OK
	]

	open-hidusb: func [
		pNode					[INTERFACE-INFO-NODE!]
		return:					[USB-ERROR!]
		/local
			entry				[int-ptr!]
			hDev				[int-ptr!]
			num					[integer!]
			cols				[HID-COLLECTION!]
			input-size			[integer!]
			output-size			[integer!]
			kr					[integer!]
			rthread				[BARRIER-THREAD!]
	][
		entry: IORegistryEntryFromPath as int-ptr! kIOMasterPortDefault pNode/path
		if entry = null [
			return USB-ERROR-PATH
		]
		hDev: IOHIDDeviceCreate kCFAllocatorDefault entry
		if hDev = null [
			IOObjectRelease entry
			return USB-ERROR-HANDLE
		]
		IOObjectRelease entry
		num: 0
		cols: get-hid-usage-property hDev :num
		if cols <> null [
			pNode/collections: cols
			pNode/col-count: num
		]
		input-size: 0
		unless get-hid-int-property hDev kIOHIDMaxInputReportSizeKey :input-size [
			input-size: 64
		]
		pNode/input-size: input-size
		pNode/input-buffer: allocate pNode/input-size
		output-size: 0
		unless get-hid-int-property hDev kIOHIDMaxOutputReportSizeKey :output-size [
			output-size: 64
		]
		pNode/output-size: output-size
		kr: IOHIDDeviceOpen hDev kIOHIDOptionsTypeSeizeDevice
		if kr <> 0 [
			CFRelease hDev
			return USB-ERROR-PATH
		]
		pNode/hDev: as integer! hDev

		rthread: as BARRIER-THREAD! allocate size? BARRIER-THREAD!
		if rthread = null [
			CFRelease hDev
			pNode/hDev: 0
			return USB-ERROR-INIT
		]
		set-memory as byte-ptr! rthread null-byte size? BARRIER-THREAD!
		dlink/init rthread/list
		rthread/trigger?: false
		pthread_mutex_init :rthread/mutex null
		pthread_cond_init :rthread/condition null
		pthread_barrier_init as pthread_barrier_t :rthread/barrier 2
		pthread_barrier_init as pthread_barrier_t :rthread/shutdown_barrier 2
		pNode/read-thread: as int-ptr! rthread

		IOHIDDeviceRegisterInputReportCallback
			hDev pNode/input-buffer pNode/input-size
			as int-ptr! :hid-input-report-callback
			as int-ptr! pNode

		IOHIDDeviceRegisterRemovalCallback
			hDev
			as int-ptr! :hid-device-removal-callback
			as int-ptr! pNode

		rthread/run-loop-mode: kCFRunLoopDefaultMode
		;--start the read thread
		pthread_create :rthread/thread
			null
			as int-ptr! :hid-read-thread
			as int-ptr! pNode
		;--wait here for the read thread to be initialized
		pthread_barrier_wait as pthread_barrier_t :rthread/barrier

		print-line "ok"
		USB-ERROR-OK
	]

	hid-read-thread: func [
		[cdecl]
		param					[int-ptr!]
		return:					[int-ptr!]
		/local
			pNode				[INTERFACE-INFO-NODE!]
			rthread				[BARRIER-THREAD!]
			code				[integer!]
			ctx					[CFRunLoopSourceContext value]
			a					[integer!]
	][
		pNode: as INTERFACE-INFO-NODE! param
		rthread: as BARRIER-THREAD! pNode/read-thread
		IOHIDDeviceScheduleWithRunLoop
			as int-ptr! pNode/hDev
			CFRunLoopGetCurrent
			rthread/run-loop-mode

		set-memory as byte-ptr! ctx null-byte size? CFRunLoopSourceContext
		ctx/version: 0
		ctx/info: param
		ctx/perform: as int-ptr! :perform-signal-callback
		rthread/source: CFRunLoopSourceCreate kCFAllocatorDefault 0 as int-ptr! :ctx
		CFRunLoopAddSource CFRunLoopGetCurrent rthread/source rthread/run-loop-mode

		rthread/run-loop: CFRunLoopGetCurrent
		;--notify the main thread that the read thread is up and running
		a: pthread_barrier_wait as pthread_barrier_t :rthread/barrier

		while [all [rthread/shutdown_thread = 0 pNode/disconnected = 0]] [
			code: CFRunLoopRunInMode rthread/run-loop-mode 1000.0 false
			;--return if the device has been disconnected
			if code = 1 [
				pNode/disconnected: 1
				break
			]
			;--break if the run loop returns finished or stopped
			if all [code <> 3  code <> 4] [
				rthread/shutdown_thread: 1
				break
			]
		]
		pthread_mutex_lock :rthread/mutex
		pthread_cond_broadcast :rthread/condition
		pthread_mutex_unlock :rthread/mutex
		pthread_barrier_wait as pthread_barrier_t :rthread/shutdown_barrier

		null
	]

	perform-signal-callback: func [
		[cdecl]
		context					[int-ptr!]
		/local
			pNode				[INTERFACE-INFO-NODE!]
			rthread				[BARRIER-THREAD!]
	][
		pNode: as INTERFACE-INFO-NODE! context
		rthread: as BARRIER-THREAD! pNode/read-thread
		CFRunLoopStop rthread/run-loop
	]

	hid-input-report-callback: func [
		[cdecl]
		context					[int-ptr!]
		result					[integer!]
		sender					[int-ptr!]
		report_type				[integer!]
		report_id				[integer!]
		report					[byte-ptr!]
		report_length			[integer!]
		/local
			pNode				[INTERFACE-INFO-NODE!]
			rthread				[BARRIER-THREAD!]
			input				[INPUT-REPORT!]
			buffer				[byte-ptr!]
	][
		pNode: as INTERFACE-INFO-NODE! context
		rthread: as BARRIER-THREAD! pNode/read-thread
		;print-line "input"
		input: as INPUT-REPORT! allocate (size? INPUT-REPORT!) + report_length + 1
		if input = null [exit]
		buffer: as byte-ptr! (input + 1)
		buffer/1: as byte! report_id
		input/type: report_type
		input/length: report_length + 1
		copy-memory buffer + 1 report report_length

		pthread_mutex_lock :rthread/mutex
		dlink/append rthread/list as list-entry! input
		
		if rthread/trigger? [
			rthread/trigger?: false
			poll/trigger-user g-poller pNode/hDev rthread/udata
		]
		pthread_cond_signal :rthread/condition
		pthread_mutex_unlock :rthread/mutex
	]

	hid-device-removal-callback: func [
		[cdecl]
		context					[int-ptr!]
		result					[integer!]
		sender					[int-ptr!]
		/local
			pNode				[INTERFACE-INFO-NODE!]
			rthread				[BARRIER-THREAD!]
	][
		pNode: as INTERFACE-INFO-NODE! context
		rthread: as BARRIER-THREAD! pNode/read-thread
		pNode/disconnected: 1
		CFRunLoopStop rthread/run-loop
	]

	close-interface: func [
		pNode					[INTERFACE-INFO-NODE!]
		/local
			rthread				[BARRIER-THREAD!]
			list				[list-entry!]
			entry				[list-entry!]
			p					[list-entry!]
	][
		if pNode/hDev <> 0 [
			rthread: as BARRIER-THREAD! pNode/read-thread
			if pNode/disconnected = 0 [
				IOHIDDeviceRegisterInputReportCallback
					as int-ptr! pNode/hDev
					pNode/input-buffer
					pNode/input-size
					null
					as int-ptr! pNode
				IOHIDDeviceRegisterRemovalCallback
					as int-ptr! pNode/hDev
					null
					as int-ptr! pNode
				IOHIDDeviceUnscheduleFromRunLoop
					as int-ptr! pNode/hDev
					rthread/run-loop
					rthread/run-loop-mode
				IOHIDDeviceScheduleWithRunLoop
					as int-ptr! pNode/hDev
					CFRunLoopGetMain
					kCFRunLoopDefaultMode
			]
			print-line "close interface"
			list: rthread/list
			entry: list/next
			while [entry <> list][
				p: entry/next
				free as byte-ptr! entry
				entry: p
			]
			list/next: list
			list/prev: list

			rthread/shutdown_thread: 1
			CFRunLoopSourceSignal rthread/source
			CFRunLoopWakeUp	rthread/run-loop

			pthread_barrier_wait as pthread_barrier_t :rthread/shutdown_barrier
			pthread_join rthread/thread null

			pthread_barrier_destroy as pthread_barrier_t :rthread/shutdown_barrier
			pthread_barrier_destroy as pthread_barrier_t :rthread/barrier
			pthread_cond_destroy :rthread/condition
			pthread_mutex_destroy :rthread/mutex

			CFRelease rthread/run-loop-mode
			CFRelease rthread/source

			;CFRelease as int-ptr! pNode/hDev
			IOHIDDeviceClose as int-ptr! pNode/hDev
			pNode/hDev: 0
		]
	]

	write-data: func [
		pNode					[INTERFACE-INFO-NODE!]
		buf						[byte-ptr!]
		buflen					[integer!]
		plen					[int-ptr!]
		data					[int-ptr!]
		timeout					[integer!]
		return:					[integer!]
		/local
			wthread				[WRITE-THREAD!]
			ret					[integer!]
	][
		case [
			pNode/hType = DRIVER-TYPE-WINUSB [

			]
			pNode/hType = DRIVER-TYPE-HIDUSB [
				wthread: as WRITE-THREAD! allocate size?  WRITE-THREAD!
				if wthread = null [return -1]
				set-memory as byte-ptr! wthread null-byte size? WRITE-THREAD!
				pNode/write-thread: as int-ptr! wthread
				wthread/udata: data
				wthread/buffer: buf
				wthread/buflen: buflen
				pthread_create :wthread/thread
					null
					as int-ptr! :hid-write-thread
					as int-ptr! pNode
				return 0
			]
			true [
				return -1
			]
		]
		-1
	]

	hid-write-thread: func [
		[cdecl]
		param					[int-ptr!]
		return:					[int-ptr!]
		/local
			pNode				[INTERFACE-INFO-NODE!]
			wthread				[WRITE-THREAD!]
			buffer				[byte-ptr!]
			p					[byte-ptr!]
			len					[integer!]
	][
		pNode: as INTERFACE-INFO-NODE! param
		wthread: as WRITE-THREAD! pNode/write-thread
		buffer: wthread/buffer
		either buffer/1 = null-byte [
			p: buffer + 1
			len: wthread/buflen - 1
		][
			p: buffer
			len: wthread/buflen
		]
		IOHIDDeviceSetReport
			as int-ptr! pNode/hDev
			kIOHIDReportTypeOutput
			as integer! buffer/1
			p
			len
		poll/trigger-user g-poller pNode/hDev wthread/udata
		free as byte-ptr! wthread
		pNode/write-thread: null
		null
	]

	read-data: func [
		pNode					[INTERFACE-INFO-NODE!]
		buf						[byte-ptr!]
		buflen					[integer!]
		plen					[int-ptr!]
		data					[int-ptr!]
		timeout					[integer!]
		return:					[integer!]
		/local
			rthread				[BARRIER-THREAD!]
			list				[list-entry!]
			len					[integer!]
	][
		rthread: as BARRIER-THREAD! pNode/read-thread
		pthread_mutex_lock :rthread/mutex
		list: rthread/list
		len: dlink/length? list
		if len = 0 [
			rthread/trigger?: true
			rthread/udata: data
		]
		pthread_mutex_unlock :rthread/mutex
		if len <> 0 [
			poll/trigger-user g-poller pNode/hDev data
		]
		0
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
		kIOHIDDeviceTypeID: CFUUIDGetConstantUUIDWithBytes kCFAllocatorDefault
			#"^(7D)" #"^(DE)" #"^(EC)" #"^(A8)" #"^(A7)" #"^(B4)" #"^(11)" #"^(DA)"
			#"^(8A)" #"^(0E)" #"^(00)" #"^(14)" #"^(51)" #"^(97)" #"^(58)" #"^(EF)"

		kIOHIDDeviceDeviceInterfaceID: CFUUIDGetConstantUUIDWithBytes kCFAllocatorDefault
			#"^(47)" #"^(4B)" #"^(DC)" #"^(8E)" #"^(9F)" #"^(4A)" #"^(11)" #"^(DA)"
			#"^(B3)" #"^(66)" #"^(00)" #"^(0D)" #"^(93)" #"^(6D)" #"^(06)" #"^(D2)"

		dlink/init device-list

	]
]

