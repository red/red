Red/System [
	Title:   "Red runtime win32 API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %defs-win.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#include %COM.reds

#define VA_COMMIT_RESERVE	3000h						;-- MEM_COMMIT | MEM_RESERVE
#define VA_PAGE_RW			04h							;-- PAGE_READWRITE
#define VA_PAGE_RWX			40h							;-- PAGE_EXECUTE_READWRITE

#define _O_TEXT        	 	4000h  						;-- file mode is text (translated)
#define _O_BINARY       	8000h  						;-- file mode is binary (untranslated)
#define _O_WTEXT        	00010000h 					;-- file mode is UTF16 (translated)
#define _O_U16TEXT      	00020000h 					;-- file mode is UTF16 no BOM (translated)
#define _O_U8TEXT       	00040000h 					;-- file mode is UTF8  no BOM (translated)


#define FORMAT_MESSAGE_ALLOCATE_BUFFER	00000100h
#define FORMAT_MESSAGE_IGNORE_INSERTS	00000200h
#define FORMAT_MESSAGE_FROM_STRING		00000400h
#define FORMAT_MESSAGE_FROM_HMODULE		00000800h
#define FORMAT_MESSAGE_FROM_SYSTEM		00001000h

#define WEOF							FFFFh

#define INFINITE						FFFFFFFFh
#define HANDLE_FLAG_INHERIT				00000001h
#define STARTF_USESTDHANDLES			00000100h
#define STARTF_USESHOWWINDOW			00000001h

#define ERROR_BROKEN_PIPE				109
#define ERROR_INSUFFICIENT_BUFFER		122
#define ERROR_NO_MORE_ITEMS				259

#define IS_TEXT_UNICODE_UNICODE_MASK 	000Fh

#define WAIT_TIMEOUT					258
#define WAIT_OBJECT_0					0

#define FIONBIO							8004667Eh

#define INVALID_HANDLE					[as int-ptr! -1]

#define GENERIC_WRITE					40000000h
#define GENERIC_READ 					80000000h
#define FILE_SHARE_READ					00000001h
#define FILE_SHARE_WRITE				00000002h
#define FILE_SHARE_DELETE				00000004h
#define CREATE_NEW						00000001h
#define CREATE_ALWAYS					00000002h
#define OPEN_EXISTING					00000003h
#define OPEN_ALWAYS						00000004h
#define TRUNCATE_EXISTING				00000005h
#define FILE_ATTRIBUTE_NORMAL			00000080h
#define FILE_ATTRIBUTE_DIRECTORY		00000010h
#define FILE_FLAG_SEQUENTIAL_SCAN		08000000h

#define FILE_ANY_ACCESS					0
#define FILE_SPECIAL_ACCESS				FILE_ANY_ACCESS
#define FILE_READ_ACCESS				0001h
#define FILE_WRITE_ACCESS				0002h

#define FILE_FLAG_OVERLAPPED			40000000h

#define METHOD_BUFFERED					0
#define METHOD_IN_DIRECT				1
#define METHOD_OUT_DIRECT				2
#define METHOD_NEITHER					3

#define DIGCF_DEFAULT					00000001h
#define DIGCF_PRESENT					00000002h
#define DIGCF_ALLCLASSES				00000004h
#define DIGCF_PROFILE					00000008h
#define DIGCF_DEVICEINTERFACE			00000010h

#define SPDRP_DEVICEDESC				00000000h
#define SPDRP_HARDWAREID				00000001h
#define SPDRP_SERVICE					00000004h
#define SPDRP_CLASS						00000007h
#define SPDRP_DRIVER					00000009h
#define SPDRP_LOCATION_INFORMATION		0000000Dh
#define SPDRP_BUSNUMBER					00000015h
#define SPDRP_ADDRESS					0000001Ch

#define CTL_CODE(DeviceType Function* Method Access) [
	(DeviceType << 16) or (Access << 14) or (Function* << 2) or Method
]

#define FILE_DEVICE_UNKNOWN				00000022h
#define FILE_DEVICE_USB					FILE_DEVICE_UNKNOWN

#define HCD_GET_STATS_1										255
#define HCD_DIAGNOSTIC_MODE_ON								256
#define HCD_DIAGNOSTIC_MODE_OFF								257
#define HCD_GET_ROOT_HUB_NAME								258
#define HCD_GET_DRIVERKEY_NAME								265
#define HCD_GET_STATS_2										266
#define HCD_DISABLE_PORT									268
#define HCD_ENABLE_PORT										269
#define HCD_USER_REQUEST									270
#define HCD_TRACE_READ_REQUEST								275

#define USB_GET_NODE_INFORMATION							258
#define USB_GET_NODE_CONNECTION_INFORMATION					259
#define USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION				260
#define USB_GET_NODE_CONNECTION_NAME						261
#define USB_DIAG_IGNORE_HUBS_ON								262
#define USB_DIAG_IGNORE_HUBS_OFF							263
#define USB_GET_NODE_CONNECTION_DRIVERKEY_NAME				264
#define USB_GET_HUB_CAPABILITIES							271
#define USB_GET_NODE_CONNECTION_ATTRIBUTES					272
#define USB_HUB_CYCLE_PORT									273
#define USB_GET_NODE_CONNECTION_INFORMATION_EX				274
#define USB_RESET_HUB										275
#define USB_GET_HUB_CAPABILITIES_EX							276
#define USB_GET_HUB_INFORMATION_EX							277
#define USB_GET_PORT_CONNECTOR_PROPERTIES					278
#define USB_GET_NODE_CONNECTION_INFORMATION_EX_V2			279

#define USB_GET_TRANSPORT_CHARACTERISTICS					281
#define USB_REGISTER_FOR_TRANSPORT_CHARACTERISTICS_CHANGE	282
#define USB_NOTIFY_ON_TRANSPORT_CHARACTERISTICS_CHANGE		283
#define USB_UNREGISTER_FOR_TRANSPORT_CHARACTERISTICS_CHANGE	284

#define USB_START_TRACKING_FOR_TIME_SYNC					285
#define USB_GET_FRAME_NUMBER_AND_QPC_FOR_TIME_SYNC			286
#define USB_STOP_TRACKING_FOR_TIME_SYNC						287

#define USB_GET_DEVICE_CHARACTERISTICS						288
#define IOCTL_GET_HCD_DRIVERKEY_NAME	[CTL_CODE(FILE_DEVICE_USB HCD_GET_DRIVERKEY_NAME METHOD_BUFFERED FILE_ANY_ACCESS)]

#define USB_CTL(id)						[CTL_CODE(FILE_DEVICE_USB id METHOD_BUFFERED FILE_ANY_ACCESS)]

#define IOCTL_USB_USER_REQUEST			[USB_CTL(HCD_USER_REQUEST)]
#define IOCTL_USB_GET_ROOT_HUB_NAME		[CTL_CODE(FILE_DEVICE_USB HCD_GET_ROOT_HUB_NAME METHOD_BUFFERED FILE_ANY_ACCESS)]

#define IOCTL_USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION	[CTL_CODE(FILE_DEVICE_USB USB_GET_DESCRIPTOR_FROM_NODE_CONNECTION METHOD_BUFFERED FILE_ANY_ACCESS)]

#define USBUSER_GET_CONTROLLER_INFO_0						00000001h
#define USBUSER_GET_CONTROLLER_DRIVER_KEY					00000002h
#define USBUSER_PASS_THRU									00000003h
#define USBUSER_GET_POWER_STATE_MAP							00000004h
#define USBUSER_GET_BANDWIDTH_INFORMATION					00000005h
#define USBUSER_GET_BUS_STATISTICS_0						00000006h
#define USBUSER_GET_ROOTHUB_SYMBOLIC_NAME					00000007h
#define USBUSER_GET_USB_DRIVER_VERSION						00000008h
#define USBUSER_GET_USB2_HW_VERSION							00000009h
#define USBUSER_USB_REFRESH_HCT_REG							0000000Ah

#define USB_DEVICE_DESCRIPTOR_TYPE							#"^(01)"
#define USB_CONFIGURATION_DESCRIPTOR_TYPE					#"^(02)"
#define USB_STRING_DESCRIPTOR_TYPE							#"^(03)"
#define USB_INTERFACE_DESCRIPTOR_TYPE						#"^(04)"
#define USB_ENDPOINT_DESCRIPTOR_TYPE						#"^(05)"

#define USB_IAD_DESCRIPTOR_TYPE								#"^(0B)"
#define USB_DEVICE_CLASS_VIDEO								#"^(0E)" 

#define MAXIMUM_USB_STRING_LENGTH							255
#define NUM_STRING_DESC_TO_GET								32


#define DICS_FLAG_GLOBAL									00000001h
#define DICS_FLAG_CONFIGSPECIFIC							00000002h
#define DICS_FLAG_CONFIGGENERAL								00000004h

#define DIREG_DEV											00000001h
#define DIREG_DRV											00000002h
#define DIREG_BOTH											00000004h

#define DELETE												00010000h
#define READ_CONTROL										00020000h
#define WRITE_DAC											00040000h
#define WRITE_OWNER											00080000h
#define SYNCHRONIZE											00100000h

#define STANDARD_RIGHTS_REQUIRED							000F0000h

#define STANDARD_RIGHTS_READ								READ_CONTROL
#define STANDARD_RIGHTS_WRITE								READ_CONTROL
#define STANDARD_RIGHTS_EXECUTE								READ_CONTROL

#define STANDARD_RIGHTS_ALL									001F0000h

#define SPECIFIC_RIGHTS_ALL									0000FFFFh

#define KEY_QUERY_VALUE										0001h
#define KEY_SET_VALUE										0002h
#define KEY_CREATE_SUB_KEY									0004h
#define KEY_ENUMERATE_SUB_KEYS								0008h
#define KEY_NOTIFY											0010h
#define KEY_CREATE_LINK										0020h
#define KEY_WOW64_32KEY										0200h
#define KEY_WOW64_64KEY										0100h
#define KEY_WOW64_RES										0300h

#define KEY_READ		[(STANDARD_RIGHTS_READ or KEY_QUERY_VALUE or KEY_ENUMERATE_SUB_KEYS or KEY_NOTIFY) and (not SYNCHRONIZE)]

#enum spawn-mode [
	P_WAIT:		0
	P_NOWAIT:	1
	P_OVERLAY:	2
	P_NOWAITO:	3
	P_DETACH:	4
]

timeval!: alias struct! [
	tv_sec	[integer!]
	tv_usec [integer!]
]

SECURITY_ATTRIBUTES: alias struct! [
	nLength 			 [integer!]
	lpSecurityDescriptor [int-ptr!]
	bInheritHandle 		 [integer!]
]

OVERLAPPED!: alias struct! [
	Internal		[int-ptr!]
	InternalHigh	[int-ptr!]
	Offset			[integer!]				;-- or Pointer [int-ptr!]
	OffsetHigh		[integer!]
	hEvent			[int-ptr!]
]

OVERLAPPED_ENTRY!: alias struct! [
	lpCompletionKey				[int-ptr!]
	lpOverlapped				[int-ptr!]
	Internal					[int-ptr!]
	dwNumberOfBytesTransferred	[integer!]
]

WSADATA!: alias struct! [					;-- varies from 32bit to 64bit, for 32bit: 400 bytes
	wVersion		[integer!]
	;wHighVersion
	szDescription	[c-string!]
	szSystemStatus	[c-string!]
	iMaxSockets		[integer!]
	;iMaxUdpDg
	lpVendorInfo	[c-string!]
]

WSAPROTOCOL_INFOW: alias struct! [
	dwServiceFlags1		[integer!]
	dwServiceFlags2		[integer!]
	dwServiceFlags3		[integer!]
	dwServiceFlags4		[integer!]
	dwProviderFlags		[integer!]
	ProviderId			[integer!]
	dwCatalogEntryId	[integer!]
	ProtocolChain		[integer!]
	iVersion			[integer!]
	iAddressFamily		[integer!]
	iMaxSockAddr		[integer!]
	iMinSockAddr		[integer!]
	iSocketType			[integer!]
	iProtocol			[integer!]
	iProtocolMaxOffset	[integer!]
	iNetworkByteOrder	[integer!]
	iSecurityScheme		[integer!]
	dwMessageSize		[integer!]
	dwProviderReserved	[integer!]
	szProtocol			[integer!]
]

stat!: alias struct! [val [integer!]]

FILETIME!: alias struct! [
	dwLowDateTime		[integer!]
	dwHighDateTime		[integer!]
]

SYSTEMTIME!: alias struct! [
	data1				[integer!] ; year, month
	data2				[integer!] ; DayOfWeek, day
	data3				[integer!] ; hour, minute
	data4				[integer!] ; second, ms
]

WIN32_FIND_DATA: alias struct! [
	dwFileAttributes	[integer!]
	ftCreationTime		[FILETIME! value]
	ftLastAccessTime	[FILETIME! value]
	ftLastWriteTime		[FILETIME! value]
	nFileSizeHigh		[integer!]
	nFileSizeLow		[integer!]
	dwReserved0			[integer!]
	dwReserved1			[integer!]
	;cFileName			[byte-ptr!]				;-- WCHAR  cFileName[ 260 ]
	;cAlternateFileName	[c-string!]				;-- cAlternateFileName[ 14 ]
]

WSABUF!: alias struct! [
	len			[integer!]
	buf			[byte-ptr!]
]

process-info!: alias struct! [
	hProcess	[integer!]
	hThread		[integer!]
	dwProcessId	[integer!]
	dwThreadId	[integer!]
]

startup-info!: alias struct! [
	cb				[integer!]
	lpReserved		[c-string!]
	lpDesktop		[c-string!]
	lpTitle			[c-string!]
	dwX				[integer!]
	dwY				[integer!]
	dwXSize			[integer!]
	dwYSize			[integer!]
	dwXCountChars	[integer!]
	dwYCountChars	[integer!]
	dwFillAttribute	[integer!]
	dwFlags			[integer!]
	wShowWindow-a	[byte!]           ; 16 bits integer needed here for windows WORD type
	wShowWindow-b	[byte!]
	cbReserved2-a	[byte!]
	cbReserved2-b	[byte!]
	lpReserved2		[byte-ptr!]
	hStdInput		[integer!]
	hStdOutput		[integer!]
	hStdError		[integer!]
]

security-attributes!: alias struct! [
	nLength				 [integer!]
	lpSecurityDescriptor [integer!]
	bInheritHandle		 [logic!]
]

OSVERSIONINFO: alias struct! [
	dwOSVersionInfoSize [integer!]
	dwMajorVersion		[integer!]
	dwMinorVersion		[integer!]
	dwBuildNumber		[integer!]	
	dwPlatformId		[integer!]
	szCSDVersion		[integer!]						;-- array of 128 bytes
	szCSDVersion0		[integer!]
	szCSDVersion1		[integer!]
	szCSDVersion2		[integer!]
	szCSDVersion3		[integer!]
	szCSDVersion4		[integer!]
	szCSDVersion5		[integer!]
	szCSDVersion6		[integer!]
	szCSDVersion7		[integer!]
	szCSDVersion8		[integer!]
	szCSDVersion9		[integer!]
	szCSDVersion10		[integer!]
	szCSDVersion11		[integer!]
	szCSDVersion12		[integer!]
	szCSDVersion13		[integer!]
	szCSDVersion14		[integer!]
	szCSDVersion15		[integer!]
	szCSDVersion16		[integer!]
	szCSDVersion17		[integer!]
	szCSDVersion18		[integer!]
	szCSDVersion19		[integer!]
	szCSDVersion20		[integer!]
	szCSDVersion21		[integer!]
	szCSDVersion22		[integer!]
	szCSDVersion23		[integer!]
	szCSDVersion24		[integer!]
	szCSDVersion25		[integer!]
	szCSDVersion26		[integer!]
	szCSDVersion27		[integer!]
	szCSDVersion28		[integer!]
	szCSDVersion29		[integer!]
	szCSDVersion30		[integer!]
	wServicePack		[integer!]						;-- Major: 16, Minor: 16
	wSuiteMask0			[byte!]
	wSuiteMask1			[byte!]
	wProductType		[byte!]
	wReserved			[byte!]
]

GdiplusStartupInput!: alias struct! [
	GdiplusVersion				[integer!]
	DebugEventCallback			[integer!]
	SuppressBackgroundThread	[integer!]
	SuppressExternalCodecs		[integer!]
]

tagSYSTEMTIME: alias struct! [
	year-month	[integer!]
	week-day	[integer!]
	hour-minute	[integer!]
	second		[integer!]
]

tagTIME_ZONE_INFORMATION: alias struct! [
	Bias				[integer!]
	StandardName1		[float!]			;-- StandardName: 64 bytes
	StandardName2		[float!]
	StandardName3		[float!]
	StandardName4		[float!]
	StandardName5		[float!]
	StandardName6		[float!]
	StandardName7		[float!]
	StandardName8		[float!]
	StandardDate		[tagSYSTEMTIME value]
	StandardBias		[integer!]
	DaylightName1		[float!]			;-- DaylightName: 64 bytes
	DaylightName2		[float!]
	DaylightName3		[float!]
	DaylightName4		[float!]
	DaylightName5		[float!]
	DaylightName6		[float!]
	DaylightName7		[float!]
	DaylightName8		[float!]
	DaylightDate		[tagSYSTEMTIME value]
	DaylightBias		[integer!]
]

tagSYSTEM_INFO: alias struct! [
	dwOemId						[integer!]
	dwPageSize					[integer!]
	lpMinimumApplicationAddress	[int-ptr!]
	lpMaximumApplicationAddress	[int-ptr!]
	dwActiveProcessorMask		[int-ptr!]
	dwNumberOfProcessors		[integer!]
	dwProcessorType				[integer!]
	dwAllocationGranularity		[integer!]
	wProcessorLevel				[integer!]
]

DEV-INFO-DATA!: alias struct! [    ;--size: 28
	cbSize									[integer!]
	ClassGuid								[integer!]
	pad1									[integer!]
	pad2									[integer!]
	pad3									[integer!]
	DevInst									[integer!]
	reserved								[integer!]
]

DEV-INTERFACE-DATA!: alias struct! [  ;--size: 28
	cbSize									[integer!]
	ClassGuid								[integer!]
	pad1									[integer!]
	pad2									[integer!]
	pad3									[integer!]
	Flags									[integer!]
	reserved								[integer!]
]

DEV-INTERFACE-DETAIL!: alias struct! [  ;--size: 8
	cbSize									[integer!]
	DevicePath								[integer!]
]

UUID!: alias struct! [
	data1	[integer!]
	data2	[integer!]
	data3	[integer!]
	data4	[integer!]
]

USB-HCD-DRIVERKEY-NAME!: alias struct! [
	actual-length		[integer!]
	driver-key-name		[integer!]
]

USBUSER-REQUEST-HEADER!: alias struct! [
	request				[integer!]
	status				[integer!]
	ReqLen				[integer!]
	ActualLen			[integer!]
]

USB-CONTROLLER-INFO-0!: alias struct! [
	pci-vendor-id		[integer!]
	pci-device-id		[integer!]
	pci-revision		[integer!]
	num-root-ports		[integer!]
	controller-flavor	[integer!]
	hc-feature-flags	[integer!]
]
USBUSER-CONTROLLER-INFO-0!: alias struct! [
	Header				[USBUSER-REQUEST-HEADER! value]
	Info0				[USB-CONTROLLER-INFO-0! value]
]

USB-ROOT-HUB-NAME!: alias struct! [
	actual-len			[integer!]
	root-hub-name		[integer!]
]

USB-DESCRIPTOR-REQUEST!: alias struct! [
	port				[integer!]
	bmRequest			[byte!]
	bRequest			[byte!]
	wValue1				[byte!]
	wValue2				[byte!]
	wIndex1				[byte!]
	wIndex2				[byte!]
	wLength1			[byte!]
	wLength2			[byte!]
	Data				[integer!]
]

USB-DEVICE-DESCRIPTOR!: alias struct! [
	bLength				[byte!]
	bDescType			[byte!]
	bcdUSB1				[byte!]
	bcdUSB2				[byte!]
	bDeviceClass		[byte!]
	bDeviceSubClass		[byte!]
	bDeviceProtocol		[byte!]
	bMaxPacketSize0		[byte!]
	idVendor1			[byte!]
	idVendor2			[byte!]
	idProduct1			[byte!]
	idProduct2			[byte!]
	bcdDevice1			[byte!]
	bcdDevice2			[byte!]
	iManufacturer		[byte!]
	iProduct			[byte!]
	iSerialNumber		[byte!]
	bNumConfigs			[byte!]
]

USB-CONFIGURATION-DESCRIPTOR!: alias struct! [
	bLength				[byte!]
	bDescType			[byte!]
	wTotalLen1			[byte!]
	wTotalLen2			[byte!]
	bNumInfs			[byte!]
	bConfigValue		[byte!]
	iconfig				[byte!]
	bmAttr				[byte!]
	MaxPower			[byte!]
]

USB-STRING-DESCRIPTOR!: alias struct! [
	bLength				[byte!]
	bDescType			[byte!]
	resv1				[byte!]
	resv2				[byte!]
]

HIDD-ATTRIBUTES!: alias struct! [
		Size 			[integer!]
		ID 				[integer!] ;vendorID and productID
		VersionNumber 	[integer!]
]

HIDP-CAPS!: alias struct! [
		Usage 				[integer!] ;Usage and UsagePage
		ReportByteLength 	[integer!] ;InputReportByteLength and OutputReportByteLength
		pad1  				[integer!]
		pad2  				[integer!]
		pad3  				[integer!]
		pad4  				[integer!]
		pad5  				[integer!]
		pad6  				[integer!]
		pad7  				[integer!]
		pad8  				[integer!]
		pad9  				[integer!]
		pad10  				[integer!]
		pad11  				[integer!]
		pad12  				[integer!]
		pad13  				[integer!]
		pad14  				[integer!]
]

PIPE-INFO!: alias struct! [
	pipeType								[integer!]
	pipeID									[byte!]
	maxPackSize								[integer!]
	;interval								[byte!]
]

#import [
	LIBC-file cdecl [
		_setmode: "_setmode" [
			handle		[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		_fileno: "_fileno" [
			file		[int-ptr!]
			return:		[integer!]
		]
		__iob_func: "__iob_func" [return: [int-ptr!]]
		wcsupr: "_wcsupr" [
			str		[c-string!]
			return:	[c-string!]
		]
	]
	"kernel32.dll" stdcall [
		VirtualAlloc: "VirtualAlloc" [
			address		[byte-ptr!]
			size		[integer!]
			type		[integer!]
			protection	[integer!]
			return:		[int-ptr!]
		]
		VirtualFree: "VirtualFree" [
			address 	[int-ptr!]
			size		[integer!]
			type		[integer!]
			return:		[integer!]
		]
		AllocConsole: "AllocConsole" [return: [logic!]]
		FreeConsole: "FreeConsole" [return: [logic!]]
		WriteConsole: 	 "WriteConsoleW" [
			consoleOutput	[integer!]
			buffer			[byte-ptr!]
			charsToWrite	[integer!]
			numberOfChars	[int-ptr!]
			_reserved		[int-ptr!]
			return:			[integer!]
		]
		WriteFile: "WriteFile" [
			handle			[integer!]
			buffer			[byte-ptr!]
			len				[integer!]
			written			[int-ptr!]
			overlapped		[integer!]
			return:			[integer!]
		]
		GetConsoleMode:	"GetConsoleMode" [
			handle			[integer!]
			mode			[int-ptr!]
			return:			[integer!]
		]
		GetCurrentDirectory: "GetCurrentDirectoryW" [
			buf-len			[integer!]
			buffer			[byte-ptr!]
			return:			[integer!]
		]
		SetCurrentDirectory: "SetCurrentDirectoryW" [
			lpPathName		[c-string!]
			return:			[logic!]
		]
		GetCommandLine: "GetCommandLineW" [
			return:			[byte-ptr!]
		]
		GetEnvironmentStrings: "GetEnvironmentStringsW" [
			return:		[c-string!]
		]
		GetEnvironmentVariable: "GetEnvironmentVariableW" [
			name		[c-string!]
			value		[c-string!]
			valsize		[integer!]
			return:		[integer!]
		]
		SetEnvironmentVariable: "SetEnvironmentVariableW" [
			name		[c-string!]
			value		[c-string!]
			return:		[logic!]
		]
		FreeEnvironmentStrings: "FreeEnvironmentStringsW" [
			env			[c-string!]
			return:		[logic!]
		]
		GetSystemTime: "GetSystemTime" [
			time			[tagSYSTEMTIME]
		]
		GetLocalTime: "GetLocalTime" [
			time			[tagSYSTEMTIME]
		]
		GetTimeZoneInformation: "GetTimeZoneInformation" [
			tz				[tagTIME_ZONE_INFORMATION]
			return:			[integer!]
		]
		Sleep: "Sleep" [
			dwMilliseconds	[integer!]
		]
		lstrlen: "lstrlenW" [
			str			[byte-ptr!]
			return:		[integer!]
		]
		CreateProcessW: "CreateProcessW" [
			lpApplicationName       [c-string!]
			lpCommandLine           [c-string!]
			lpProcessAttributes     [integer!]
			lpThreadAttributes      [integer!]
			bInheritHandles         [logic!]
			dwCreationFlags         [integer!]
			lpEnvironment           [integer!]
			lpCurrentDirectory      [c-string!]
			lpStartupInfo           [startup-info!]
			lpProcessInformation    [process-info!]
			return:                 [logic!]
		]
		WaitForSingleObject: "WaitForSingleObject" [
			hHandle                 [handle!]
			dwMilliseconds          [integer!]
			return:                 [integer!]
		]
		GetExitCodeProcess: "GetExitCodeProcess" [
			hProcess				[integer!]
			lpExitCode				[int-ptr!]
			return:                 [logic!]
		]
		CreatePipe: "CreatePipe" [
			hReadPipe               [int-ptr!]
			hWritePipe              [int-ptr!]
			lpPipeAttributes        [security-attributes!]
			nSize                   [integer!]
			return:                 [logic!]
		]
		CreateFileW: "CreateFileW" [
			lpFileName				[c-string!]
			dwDesiredAccess			[integer!]
			dwShareMode				[integer!]
			lpSecurityAttributes	[security-attributes!]
			dwCreationDisposition	[integer!]
			dwFlagsAndAttributes	[integer!]
			hTemplateFile			[integer!]
			return:					[integer!]
		]
		CloseHandle: "CloseHandle" [
			hObject                 [int-ptr!]
			return:                 [logic!]
		]
		GetStdHandle: "GetStdHandle" [
			nStdHandle				[integer!]
			return:					[integer!]
		]
		ReadFile: "ReadFile" [
			hFile                   [integer!]
			lpBuffer                [byte-ptr!]
			nNumberOfBytesToRead    [integer!]
			lpNumberOfBytesRead     [int-ptr!]
			lpOverlapped            [integer!]
			return:                 [integer!]
		]
		SetHandleInformation: "SetHandleInformation" [
			hObject					[integer!]
			dwMask					[integer!]
			dwFlags					[integer!]
			return:					[logic!]
		]
		GetLastError: "GetLastError" [
			return:                 [integer!]
		]
		MultiByteToWideChar: "MultiByteToWideChar" [
			CodePage				[integer!]
			dwFlags					[integer!]
			lpMultiByteStr			[byte-ptr!]
			cbMultiByte				[integer!]
			lpWideCharStr			[byte-ptr!]
			cchWideChar				[integer!]
			return:					[integer!]
		]
		SetFilePointer: "SetFilePointer" [
			file		[integer!]
			distance	[integer!]
			pDistance	[int-ptr!]
			dwMove		[integer!]
			return:		[integer!]
		]
		GetNativeSystemInfo: "GetNativeSystemInfo" [
			lpSystemInfo	[tagSYSTEM_INFO]
		]
		IsWow64Process: "IsWow64Process" [
			hProcess	[int-ptr!]
			isWow64?	[int-ptr!]
			return:		[logic!]
		]
		GetVersionEx: "GetVersionExA" [
			lpVersionInfo [OSVERSIONINFO]
			return:		[integer!]
		]
		GetCurrentProcess: "GetCurrentProcess" [
			return:		[int-ptr!]
		]
		GetFileAttributesW: "GetFileAttributesW" [
			path		[c-string!]
			return:		[integer!]
		]
		GetFileAttributesExW: "GetFileAttributesExW" [
			path		[c-string!]
			info-level  [integer!]
			info		[WIN32_FIND_DATA]
			return:		[integer!]
		]
		FileTimeToSystemTime: "FileTimeToSystemTime" [
			lpFileTime	[FILETIME!]
			lpSystemTime [SYSTEMTIME!]
			return:		[integer!]
		]
		CreateFileA: "CreateFileA" [			;-- temporary needed by Red/System
			filename	[c-string!]
			access		[integer!]
			share		[integer!]
			security	[int-ptr!]
			disposition	[integer!]
			flags		[integer!]
			template	[int-ptr!]
			return:		[integer!]
		]
		CreateDirectory: "CreateDirectoryW" [
			pathname	[c-string!]
			sa			[int-ptr!]
			return:		[logic!]
		]
		DeleteFile: "DeleteFileW" [
			filename	[c-string!]
			return:		[integer!]
		]
		RemoveDirectory: "RemoveDirectoryW" [
			filename	[c-string!]
			return:		[integer!]
		]
		FindFirstFile: "FindFirstFileW" [
			filename	[c-string!]
			filedata	[WIN32_FIND_DATA]
			return:		[integer!]
		]
		FindNextFile: "FindNextFileW" [
			file		[integer!]
			filedata	[WIN32_FIND_DATA]
			return:		[integer!]
		]
		FindClose: "FindClose" [
			file		[integer!]
			return:		[integer!]
		]
		GetFileSize: "GetFileSize" [
			file		[integer!]
			high-size	[integer!]
			return:		[integer!]
		]
		SetEndOfFile: "SetEndOfFile" [
			file		[integer!]
			return:		[integer!]
		]
		WideCharToMultiByte: "WideCharToMultiByte" [
			CodePage			[integer!]
			dwFlags				[integer!]
			lpWideCharStr		[c-string!]
			cchWideChar			[integer!]
			lpMultiByteStr		[byte-ptr!]
			cbMultiByte			[integer!]
			lpDefaultChar		[c-string!]
			lpUsedDefaultChar	[integer!]
			return:				[integer!]
		]
		GetLogicalDriveStrings: "GetLogicalDriveStringsW" [
			buf-len				[integer!]
			buffer				[byte-ptr!]
			return:				[integer!]
		]
		CreateThread: "CreateThread" [
			lpThreadAttributes	[SECURITY_ATTRIBUTES]
			dwStackSize			[integer!]
			lpStartAddress		[int-ptr!]
			lpParameter			[int-ptr!]
			dwCreationFlags		[integer!]
			lpThreadID			[int-ptr!]
			return:				[int-ptr!]
		]
		CreateIoCompletionPort: "CreateIoCompletionPort" [
			FileHandle		[int-ptr!]
			ExistingPort	[int-ptr!]
			CompletionKey	[int-ptr!]
			nThreads		[integer!]
			return:			[int-ptr!]
		]
		GetQueuedCompletionStatus: "GetQueuedCompletionStatus" [
			CompletionPort		[int-ptr!]
			lpNumberOfBytes		[int-ptr!]
			lpCompletionKey		[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			dwMilliseconds		[integer!]
			return:				[integer!]
		]
		GetQueuedCompletionStatusEx: "GetQueuedCompletionStatusEx" [
			CompletionPort		[int-ptr!]
			entries				[OVERLAPPED_ENTRY!]
			ulCount				[integer!]
			entriesRemoved		[int-ptr!]
			dwMilliseconds		[integer!]
			alertable			[logic!]
			return:				[integer!]
		]
		PostQueuedCompletionStatus: "PostQueuedCompletionStatus" [
			CompletionPort		[int-ptr!]
			nTransferred		[integer!]
			dwCompletionKey		[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			return:				[integer!]
		]
		SetFileCompletionNotificationModes: "SetFileCompletionNotificationModes" [
			handle				[int-ptr!]
			flags				[integer!]
			return:				[logic!]
		]
		DeviceIoControl: "DeviceIoControl" [
			hDevice				[int-ptr!]
			dwIoControlCode		[integer!]
			lpInBuffer			[byte-ptr!]
			nInBufferSize		[integer!]
			lpOutBuffer			[byte-ptr!]
			nOutBufferSize		[integer!]
			lpBytesReturned		[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			return:				[logic!]
		]
		RegQueryValueExW: "RegQueryValueExW" [
			hKey			[integer!]
			lpValueName		[c-string!]
			lpReserved		[int-ptr!]
			lpType			[int-ptr!]
			lpData			[byte-ptr!]
			lpcbData		[int-ptr!]
			return:			[integer!]
		]
		RegCloseKey: "RegCloseKey" [
			hKey			[integer!]
			return:			[integer!]
		]
	]
	"rpcrt4.dll" stdcall [
		UuidFromString: "UuidFromStringA" [
			StringUuid		[c-string!]
			Uuid			[UUID!]
			return:			[integer!]
		]
		UuidToString: "UuidToStringA" [
			Uuid			[UUID!]
			StringUuid		[int-ptr!]
			return:			[integer!]
		]
	]
	"Ole32.dll" stdcall [
		IIDFromString: "IIDFromString" [
			str				[c-string!]
			ppiid			[UUID!]
			return:			[integer!]
		]
	]
	"setupapi.dll" stdcall [
		SetupDiGetClassDevs: "SetupDiGetClassDevsA" [
			ClassGuid						[UUID!]
			Enumerator						[c-string!]
			hwndParent						[integer!]
			Flags							[integer!]
			return: 						[int-ptr!]
		]
		SetupDiEnumDeviceInterfaces: "SetupDiEnumDeviceInterfaces" [
			DeviceInfoSet 					[int-ptr!]
			DeviceInfoData					[integer!]
			InterfaceClassGuid				[UUID!]
			MemberIndex						[integer!]
			DeviceInterfaceData				[DEV-INTERFACE-DATA!]
			return: 						[logic!]
		]
		SetupDiGetDeviceInterfaceDetail: "SetupDiGetDeviceInterfaceDetailA" [
			DeviceInfoSet 					[int-ptr!]
			DeviceInterfaceData				[DEV-INTERFACE-DATA!]
			DeviceInterfaceDetailData		[DEV-INTERFACE-DETAIL!]
			DeviceInterfaceDetailDataSize	[integer!]
			RequiredSize					[int-ptr!]
			DeviceInfoData					[DEV-INFO-DATA!]
			return: 						[logic!]
		]
		SetupDiDestroyDeviceInfoList: "SetupDiDestroyDeviceInfoList" [
			handle							[int-ptr!]
			return: 						[logic!]
		]
		SetupDiEnumDeviceInfo: "SetupDiEnumDeviceInfo" [
			DeviceInfoSet 					[int-ptr!]
			MemberIndex						[integer!]
			DeviceInfoData					[DEV-INFO-DATA!]
			return: 						[logic!]
		]
		SetupDiGetDeviceRegistryProperty: "SetupDiGetDeviceRegistryPropertyA" [
			DeviceInfoSet 					[int-ptr!]
			DeviceInfoData 					[DEV-INFO-DATA!]
			Property						[integer!]
			PropertyRegDataType				[int-ptr!]
			PropertyBuffer					[byte-ptr!]
			PropertyBufferSize				[integer!]
			RequiredSize					[int-ptr!]
			return: 						[logic!]
		]
		SetupDiGetDeviceRegistryPropertyW: "SetupDiGetDeviceRegistryPropertyW" [
			DeviceInfoSet 					[int-ptr!]
			DeviceInfoData 					[DEV-INFO-DATA!]
			Property						[integer!]
			PropertyRegDataType				[int-ptr!]
			PropertyBuffer					[byte-ptr!]
			PropertyBufferSize				[integer!]
			RequiredSize					[int-ptr!]
			return: 						[logic!]
		]
		SetupDiGetDeviceInstanceId: "SetupDiGetDeviceInstanceIdA" [
			DeviceInfoSet 					[int-ptr!]
			DeviceInfoData					[DEV-INFO-DATA!]
			buffer							[byte-ptr!]
			buffersize						[integer!]
			size							[int-ptr!]
			return:							[logic!]
		]
		SetupDiOpenDevRegKey: "SetupDiOpenDevRegKey" [
			DeviceInfoSet 					[int-ptr!]
			DeviceInfoData					[DEV-INFO-DATA!]
			scope							[integer!]
			HwProfile						[integer!]
			keyType							[integer!]
			samDesired						[integer!]
			return:							[integer!]
		]
	]

	"ws2_32.dll" stdcall [
		WSAStartup: "WSAStartup" [
			version		[integer!]
			lpWSAData	[int-ptr!]
			return:		[integer!]
		]
		WSASocketW: "WSASocketW" [
			af				[integer!]
			type			[integer!]
			protocol		[integer!]
			lpProtocolInfo	[WSAPROTOCOL_INFOW]
			g				[integer!]
			dwFlags			[integer!]
			return:			[integer!]
		]
		WSASend: "WSASend" [
			s					[integer!]
			lpBuffers			[WSABUF!]
			dwBufferCount		[integer!]
			lpNumberOfBytesSent	[int-ptr!]
			dwFlags				[integer!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutin	[int-ptr!]
			return:				[integer!]
		]
		WSARecv: "WSARecv" [
			s					[integer!]
			lpBuffers			[WSABUF!]
			dwBufferCount		[integer!]
			lpNumberOfBytesSent	[int-ptr!]
			dwFlags				[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutin	[int-ptr!]
			return:				[integer!]
		]
		GetAddrInfoExW: "GetAddrInfoExW" [
			pName				[c-string!]
			pServiceName		[c-string!]
			dwNameSpace			[integer!]
			lpNspId				[int-ptr!]
			pHints				[int-ptr!]
			ppResult			[int-ptr!]
			timeout				[timeval!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutine	[int-ptr!]
			lpNameHandle		[int-ptr!]
			return:				[integer!]
		]
		WSAWaitForMultipleEvents: "WSAWaitForMultipleEvents" [
			cEvents				[integer!]
			lphEvents			[int-ptr!]
			fWaitAll			[logic!]
			dwTimeout			[integer!]
			fAlertable			[logic!]
			return:				[integer!]
		]
		WSAIoctl: "WSAIoctl" [
			s					[integer!]
			dwIoControlCode		[integer!]
			lpvInBuffer			[int-ptr!]
			cbInBuffer			[integer!]
			lpvOutBuffer		[int-ptr!]
			cbOutBuffer			[integer!]
			lpcbBytesReturned	[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutine	[int-ptr!]
			return:				[integer!]
		]
		closesocket: "closesocket" [
			s			[integer!]
			return:		[integer!]
		]
		ioctlsocket: "ioctlsocket" [
			s			[integer!]
			cmd			[integer!]
			argp		[int-ptr!]
			return:		[integer!]
		]
		htons: "htons" [
			hostshort	[integer!]
			return:		[integer!]
		]
		inet_addr: "inet_addr" [
			cp			[c-string!]
			return:		[integer!]
		]
		_bind: "bind" [
			s			[integer!]
			addr		[int-ptr!]
			namelen		[integer!]
			return:		[integer!]
		]
		listen: "listen" [
			s			[integer!]
			backlog		[integer!]
			return:		[integer!]
		]
		setsockopt: "setsockopt" [
			s			[integer!]
			level		[integer!]
			optname		[integer!]
			optval		[c-string!]
			optlen		[integer!]
			return:		[integer!]
		]
	]
	"gdiplus.dll" stdcall [
		GdiplusStartup: "GdiplusStartup" [
			token		[int-ptr!]
			input		[integer!]
			output		[integer!]
			return:		[integer!]
		]
		GdiplusShutdown: "GdiplusShutdown" [
			token		[integer!]
		]
	]
	"shell32.dll" stdcall [
		ShellExecute: "ShellExecuteW" [
			hwnd		 [integer!]
			lpOperation	 [c-string!]
			lpFile		 [c-string!]
			lpParameters [integer!]
			lpDirectory	 [integer!]
			nShowCmd	 [integer!]
			return:		 [integer!]
		]
	]
	"CfgMgr32" stdcall [
		CM_Get_Parent: "CM_Get_Parent" [
			parent		[int-ptr!]
			child		[integer!]
			flags		[integer!]
			return:		[integer!]
		]
		CM_Get_Child: "CM_Get_Child" [
			child		[int-ptr!]
			parent		[integer!]
			flags		[integer!]
			return:		[integer!]
		]
		CM_Get_Sibling: "CM_Get_Sibling" [
			next		[int-ptr!]
			dev			[integer!]
			flags		[integer!]
			return:		[integer!]
		]
		CM_Get_Device_ID: "CM_Get_Device_IDA" [
			inst		[integer!]
			buffer		[c-string!]
			len			[integer!]
			flags		[integer!]
			return:		[integer!]
		]
	]
	"winusb.dll" stdcall [
		WinUsb_Initialize: "WinUsb_Initialize" [
			DeviceHandle					[integer!]
			InterfaceHandle					[int-ptr!]
			return:							[logic!]
		]
		WinUsb_Free: "WinUsb_Free" [
			InterfaceHandle					[integer!]
			return:							[logic!]
		]
		WinUsb_QueryPipe: "WinUsb_QueryPipe" [
			InterfaceHandle					[integer!]
			AlternateInterfaceNumber		[integer!]
			PipeIndex						[integer!]
			PipeInformation					[PIPE-INFO!]
			return:							[logic!]
		]
		WinUsb_GetCurrentAlternateSetting: "WinUsb_GetCurrentAlternateSetting" [
			DeviceHandle					[integer!]
			AltSetting						[int-ptr!]
			return:							[logic!]
		]
		WinUsb_WritePipe: "WinUsb_WritePipe" [
			handle							[integer!]
			pipeID							[integer!]
			buffer							[byte-ptr!]
			buf-len							[integer!]
			trans-len						[int-ptr!]
			overlapped						[OVERLAPPED!]
			return:							[logic!]
		]
		WinUsb_ReadPipe: "WinUsb_ReadPipe" [
			handle							[integer!]
			pipeID							[integer!]
			buffer							[byte-ptr!]
			buf-len							[integer!]
			trans-len						[int-ptr!]
			overlapped						[OVERLAPPED!]
			return:							[logic!]
		]
		WinUsb_GetOverlappedResult: "WinUsb_GetOverlappedResult" [
			handle							[integer!]
			overlapped						[OVERLAPPED!]
			trans-len						[int-ptr!]
			wait?							[logic!]
			return:							[logic!]
		]
		WinUsb_SetPipePolicy: "WinUsb_SetPipePolicy" [
			handle							[integer!]
			pipeID							[integer!]
			policy							[integer!]
			value-len						[integer!]
			value							[int-ptr!]
			return:							[logic!]
		]
	]
	"hid.dll" stdcall [
		HidD_GetAttributes: "HidD_GetAttributes" [
			device 		[int-ptr!]
			attrib 		[HIDD-ATTRIBUTES!] ;have been not defined
			return: 	[logic!]
		]
		HidD_GetSerialNumberString: "HidD_GetSerialNumberString" [
			handle		[int-ptr!]
			buffer 		[c-string!]
			bufferlen 	[integer!]   ;ulong
			return: 	[logic!]
		]
		HidD_GetManufacturerString: "HidD_GetManufacturerString" [
			handle		[int-ptr!]
			buffer 		[c-string!]
			bufferlen 	[integer!]   ;ulong
			return: 	[logic!]
		]
		HidD_GetProductString: "HidD_GetProductString" [
			handle		[int-ptr!]
			buffer 		[c-string!]
			bufferlen 	[integer!]   ;ulong
			return: 	[logic!]
		]
		HidD_SetFeature: "HidD_SetFeature" [
			handle		[int-ptr!]
			data  		[int-ptr!]
			length 		[integer!] ;ulong
			return: 	[logic!]
		]
		HidD_GetFeature: "HidD_GetFeature" [
			handle		[int-ptr!]
			data  		[int-ptr!]
			length 		[integer!] ;ulong
			return: 	[logic!]
		]
		HidD_GetIndexedString: "HidD_GetIndexedString" [
			handle			[int-ptr!]
			string-index	[integer!] ;ulong
			buffer 			[int-ptr!]
			bufferlen 		[integer!] ;ulong
			return: 		[logic!]
		]
		HidD_GetPreparsedData: "HidD_GetPreparsedData" [
			handle 			[int-ptr!]
			preparsed-data 	[int-ptr!]
			return: 		[logic!]
		]
		HidD_FreePreparsedData: "HidD_FreePreparsedData" [
			preparsed-data 	[int-ptr!]
			return: 		[logic!]
		]
		HidP_GetCaps: "HidP_GetCaps" [
			preparsed-data 	[int-ptr!]
			caps 			[HIDP-CAPS!] ;need to check
			return: 		[integer!] ;ulong
		]
		HidD_SetNumInputBuffers: "HidD_SetNumInputBuffers" [
			handle			[int-ptr!]
			number-buffers 	[integer!] ;ulong
			return: 		[logic!]
		]
	]
]

AcceptEx!: alias function! [
	sListenSocket			[integer!]
	sAcceptSocket			[integer!]
	lpOutputBuffer			[byte-ptr!]
	dwReceiveDataLength		[integer!]
	dwLocalAddressLength	[integer!]
	dwRemoteAddressLength	[integer!]
	lpdwBytesReceived		[int-ptr!]
	lpOverlapped			[int-ptr!]
	return:					[logic!]
]

ConnectEx!: alias function! [
	s						[integer!]
	name					[int-ptr!]
	namelen					[integer!]
	lpSendBuffer			[byte-ptr!]
	dwSendDataLength		[integer!]
	lpdwBytesSent			[int-ptr!]
	lpOverlapped			[int-ptr!]
	return:					[logic!]
]

DisconnectEx!: alias function! [
	hSocket					[integer!]
	lpOverlapped			[OVERLAPPED!]
	dwFlags					[integer!]
	reserved				[integer!]
	return:					[logic!]
]

TransmitFile!: alias function! [
	hSocket					[integer!]
	hFile					[int-ptr!]
	nNumberOfBytesToWrite	[integer!]
	nNumberOfBytesPerSend	[integer!]
	lpOverlapped			[OVERLAPPED!]
	lpTransmitBuffers		[int-ptr!]
	dwReserved				[integer!]
	return:					[logic!]
]

GetAcceptExSockaddrs!: alias function! [
	lpOutputBuffer			[byte-ptr!]
	dwReceiveDataLength		[integer!]
	dwLocalAddressLength	[integer!]
	dwRemoteAddressLength	[integer!]
	LocalSockaddr			[int-ptr!]
	LocalSockaddrLength		[int-ptr!]
	RemoteSockaddr			[int-ptr!]
	RemoteSockaddrLength	[int-ptr!]
]
