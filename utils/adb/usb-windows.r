REBOL [
	Title:   "Android Debug Bridge - USB Windows"
	Author:  "Qingtian Xie"
	File: 	 %usb-windows.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

context [
	sys-path: to-rebol-file get-env "SystemRoot"
	setupapi: load/library sys-path/System32/setupapi.dll
	winusb:   load/library sys-path/System32/winusb.dll
	kernel32: load/library sys-path/System32/kernel32.dll

	DIGCF_DEFAULT:           to-integer #{00000001}
	DIGCF_PRESENT:           to-integer #{00000002}
	DIGCF_ALLCLASSES:        to-integer #{00000004}
	DIGCF_PROFILE:           to-integer #{00000008}
	DIGCF_DEVICEINTERFACE:   to-integer #{00000010}

	GENERIC_READ:			 to-integer #{80000000}
	GENERIC_WRITE:			 to-integer #{40000000}
	GENERIC_EXECUTE:		 to-integer #{20000000}
	GENERIC_ALL:			 to-integer #{10000000}

	FILE_SHARE_READ:		 to-integer #{00000001}
	FILE_SHARE_WRITE:		 to-integer #{00000002}

	FILE_FLAG_OVERLAPPED:	 to-integer #{40000000}

	CREATE_NEW:		1
	CREATE_ALWAYS:	2
	OPEN_EXISTING:	3

    UsbdPipeTypeControl:	 0
    UsbdPipeTypeIsochronous: 1
    UsbdPipeTypeBulk:		 2
    UsbdPipeTypeInterrupt:	 3

	PIPE_TRANSFER_TIMEOUT:		 to-integer #{03}
	USB_ENDPOINT_DIRECTION_MASK: to-integer #{80}

	SECURITY_ATTRIBUTES: make struct! [
		nLength 			 [integer!]
		lpSecurityDescriptor [integer!]
		bInheritHandle 		 [integer!]
	] none

	GUID: make struct! guid-struct: [
		data1	[integer!]
		data2	[integer!]
		data3	[integer!]
		data4	[integer!]
	] none

	SP_DEVINFO_DATA: make struct! dev-info-data: [
		cbSize		[integer!]
		ClassGuid	[integer!]
		pad1		[integer!]
		pad2		[integer!]
		pad3		[integer!]
		DevInst		[integer!]
		reserved	[integer!]
	] none

	SP_DEVICE_INTERFACE_DATA: make struct! dev-interface-data: [
		cbSize		[integer!]
		ClassGuid	[integer!]
		pad1		[integer!]
		pad2		[integer!]
		pad3		[integer!]
		Flags		[integer!]
		reserved	[integer!]
	] none

	SP_DEVICE_INTERFACE_DETAIL_DATA: make struct! dev-interface-detail: [
		cbSize		[integer!]
		DevicePath	[string!]
	] none

	OVERLAPPED_STRUCT: make struct! overlapped-struct: [
		Internal	 [integer!]
		InternalHigh [integer!]
		Offset		 [integer!]
		OffsetHight  [integer!]
		hEvent		 [integer!]
	] none

	WINUSB_PIPE_INFORMATION: make struct! pipe-info-struct: [		;-- 12 Bytes
		pipeType	[integer!]
		pipeID		[char!]
		maxPackSize [integer!]
	;	interval	[char!]
	] none

	WinUsb_Initialize: make routine! [
		DeviceHandle	[integer!]
		InterfaceHandle	[struct! [num [integer!]]]
		return:			[integer!]
	] winusb "WinUsb_Initialize"

	WinUsb_Free: make routine! [
		InterfaceHandle [integer!]
		return:			[integer!]
	] winusb "WinUsb_Free"

	WinUsb_QueryPipe: make routine! compose/deep [
		InterfaceHandle			 [integer!]
		AlternateInterfaceNumber [char!]
		PipeIndex				 [char!]
		PipeInformation			 [struct! [(pipe-info-struct)]]
		return:					 [integer!]
	] winusb "WinUsb_QueryPipe"

	WinUsb_GetCurrentAlternateSetting: make routine! [
		DeviceHandle	[integer!]
		AltSetting		[struct! [value [char!]]]
		return:			[integer!]
	] winusb "WinUsb_GetCurrentAlternateSetting"

	WinUsb_WritePipe: make routine! compose/deep [
		handle		[integer!]
		pipeID		[char!]
		buffer		[string!]
		buf-len		[integer!]
		trans-len	[struct! [num [integer!]]]
		overlapped	[struct! [(overlapped-struct)]]
		return:		[integer!]
	] winusb "WinUsb_WritePipe"

	WinUsb_ReadPipe: make routine! compose/deep [
		handle		[integer!]
		pipeID		[char!]
		buffer		[string!]
		buf-len		[integer!]
		trans-len	[struct! [num [integer!]]]
		overlapped	[struct! [(overlapped-struct)]]
		return:		[integer!]
	] winusb "WinUsb_ReadPipe"

	WinUsb_GetOverlappedResult: make routine! compose/deep [
		handle		[integer!]
		overlapped	[struct! [(overlapped-struct)]]
		trans-len	[struct! [num [integer!]]]
		wait?		[integer!]
		return:		[integer!]
	] winusb "WinUsb_GetOverlappedResult"

	WinUsb_SetPipePolicy: make routine! [
		handle		[integer!]
		pipeID		[char!]
		policy		[integer!]
		value-len	[integer!]
		value		[struct! [num [integer!]]]
		return:		[integer!]
	] winusb "WinUsb_SetPipePolicy"

	CreateEvent: make routine! [
		lpEventAttributes	[integer!]
		bManualReset		[integer!]
		bInitialState		[integer!]
		lpName				[integer!]
		return:				[integer!]
	] kernel32 "CreateEventA"

	CloseHandle: make routine! [
		hObject	[integer!]
		return: [integer!]
	] kernel32 "CloseHandle"

	SetupDiGetClassDevs: make routine! compose/deep [
		ClassGuid		[struct! [(guid-struct)]]
		Enumerator		[integer!]
		hwndParent		[integer!]
		Flags			[integer!]
		return:			[integer!]
	] setupapi "SetupDiGetClassDevsA"

	SetupDiDestroyDeviceInfoList: make routine! [
		handle			[integer!]
		return:			[integer!]
	] setupapi "SetupDiDestroyDeviceInfoList"

	SetupDiEnumDeviceInterfaces: make routine! compose/deep [
		DeviceInfoSet 					[integer!]
		DeviceInfoData					[integer!]
		InterfaceClassGuid				[struct! [(guid-struct)]]
		MemberIndex						[integer!]
		DeviceInterfaceData				[struct! [(dev-interface-data)]]
		return: 						[integer!]
	] setupapi "SetupDiEnumDeviceInterfaces"

	SetupDiGetDeviceInterfaceDetail: make routine! compose/deep [
		DeviceInfoSet 					[integer!]
		DeviceInterfaceData				[struct! [(dev-interface-data)]]
		DeviceInterfaceDetailData		[string!]
		DeviceInterfaceDetailDataSize	[integer!]
		RequiredSize					[struct! [num [integer!]]]
		DeviceInfoData					[integer!]
		return: 						[integer!]
	] setupapi "SetupDiGetDeviceInterfaceDetailA"

	CreateFile: make routine! [
		lpFileName				[string!]
		dwDesiredAccess			[integer!]
		dwShareMode				[integer!]
		lpSecurityAttributes	[integer!]
		dwCreationDisposition	[integer!]
		dwFlagsAndAttributes	[integer!]
		hTemplateFile			[integer!]
		return:					[integer!]
	] kernel32 "CreateFileA"

	FORMAT_MESSAGE_FROM_SYSTEM:	   to-integer #{00001000}
	FORMAT_MESSAGE_IGNORE_INSERTS: to-integer #{00000200}

	fmt-msg-flags: FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS

	GetLastError: make routine! [
		return: [integer!]
	] kernel32 "GetLastError"

	FormatMessage: make routine! [
		dwFlags		 [integer!]
		lpSource	 [integer!]
		dwMessageId  [integer!]
		dwLanguageId [integer!]
		lpBuffer	 [string!]
		nSize		 [integer!]
		Arguments	 [integer!]
		return:		 [integer!]
	] kernel32 "FormatMessageA"

	get-error-msg: has [out][
		out: make-null-string 256
		FormatMessage fmt-msg-flags 0 last-error: GetLastError 0 out 256 0
		trim/tail out
	]

	ANDROID_USB_CLASS_ID: make struct! GUID reduce [
		to-integer #{F72FE0D4}
		to-integer #{407DCBCB}
		to-integer #{D69E1488}
		to-integer #{6BDDD073}
	]

	usb-info!: make object! [
		device-set: 0
		device:		0					;-- device handle
		interface:	0					;-- interface handle
		read-id:	null				;-- read pipe id
		write-id:	null				;-- write pipe id
		local-id:	1
		remote-id:	0
		zero-mask:  0
	]

	set-timeout: func [usb seconds /local time][
		time: make-lpDWORD
		time/int: seconds * 1000
		WinUsb_SetPipePolicy usb/interface usb/read-id PIPE_TRANSFER_TIMEOUT 4 time
		WinUsb_SetPipePolicy usb/interface usb/write-id PIPE_TRANSFER_TIMEOUT 4 time
	]

	init-device: func [
		/local dev-info interface-data required-size buffer interface-name
			   dev-handle interface-handle interface-number pipe-read pipe-write
			   pipe-info max-packet-size usb
	][
		;;-- open device
		dev-info: SetupDiGetClassDevs ANDROID_USB_CLASS_ID 0 0 DIGCF_DEVICEINTERFACE or DIGCF_PRESENT
		if -1 = dev-info [
			print get-error-msg
			print "**ADB**: Error: Can not get device information set" return
		]
		interface-data: make struct! SP_DEVICE_INTERFACE_DATA none
		interface-data/cbSize: length? third SP_DEVICE_INTERFACE_DATA
		if zero? SetupDiEnumDeviceInterfaces dev-info 0 ANDROID_USB_CLASS_ID 0 interface-data [
			print get-error-msg
			print "**ADB**: Error: No android devices"
			SetupDiDestroyDeviceInfoList dev-info return
		]
		required-size: make-lpDWORD
		buffer: make-null-string 500					;-- big enough
		buffer/1: to-char 5								;-- sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA)
		SetupDiGetDeviceInterfaceDetail dev-info interface-data buffer 500 required-size 0
		interface-name: copy skip trim buffer 4
		dev-handle: CreateFile interface-name
						GENERIC_READ or GENERIC_WRITE
						FILE_SHARE_READ or FILE_SHARE_WRITE
						0 OPEN_EXISTING FILE_FLAG_OVERLAPPED 0

		if -1 = dev-handle [
			print get-error-msg
			SetupDiDestroyDeviceInfoList dev-info
			print "**ADB**: Error: Can not open android device" return
		]

		;;-- get interface handle
		interface-handle: make-lpDWORD
		if zero? WinUsb_Initialize dev-handle interface-handle [
			print get-error-msg
			print "**ADB**: Error: Can not initialize interface"
			CloseHandle dev-handle
			SetupDiDestroyDeviceInfoList dev-info
			return
		]

		;;-- get write pipe id & read pipe id
		interface-number: make struct! [value [char!]] none
		WinUsb_GetCurrentAlternateSetting interface-handle/int interface-number

		read-id:  null
		write-id: null
		for idx 0 2 1 [
			pipe-info: make struct! WINUSB_PIPE_INFORMATION none
			if zero? WinUsb_QueryPipe
							interface-handle/int
							interface-number/value
							to-char idx
							pipe-info [break]
			if pipe-info/pipeType = UsbdPipeTypeBulk [
				either zero? (pipe-info/pipeID and USB_ENDPOINT_DIRECTION_MASK) [
					pipe-write: pipe-info/pipeID
					max-packet-size: to-integer reverse copy/part skip third pipe-info 6 2
				][
					pipe-read: pipe-info/pipeID
				]
			]
		]
		usb: make usb-info! [
			device-set: dev-info
			device: dev-handle
			interface: interface-handle/int
			read-id: pipe-read
			write-id: pipe-write
			zero-mask: max-packet-size - 1
		]
		set-timeout usb 1
		usb
	]

	close-device: func [
		usb		[object!]
	][
		unless zero? usb/interface [WinUsb_Free usb/interface]
		unless zero? usb/device [CloseHandle usb/device]
		unless zero? usb/device-set [SetupDiDestroyDeviceInfoList usb/device-set]
	]

	usb-pipe: func [
		usb		[object!]
		data	[string! binary!]
		/write /read
		/local ovlap interface data-len
	][
		interface: usb/interface
		if binary? data [data: to-string data]
		ovlap: make struct! OVERLAPPED_STRUCT none
		ovlap/hEvent: CreateEvent 0 1 0 0
		data-len: length? data
		transferred: make-lpDWORD

		either write [
			WinUsb_WritePipe interface usb/write-id data data-len transferred ovlap
			if all [
				positive? usb/zero-mask
				not empty? data
				zero? (usb/zero-mask and data-len)
			][
				usb-pipe/write usb ""
			]
		][
			WinUsb_ReadPipe interface usb/read-id data data-len transferred ovlap
		]
		WinUsb_GetOverlappedResult interface ovlap transferred 1
		if write [
			if transferred/int <> data-len [
				unless zero? ovlap/hEvent [CloseHandle ovlap/hEvent]
				close-device usb
				print ["**ADB**: Error: Write data failed"] halt
			]
		]
		unless zero? ovlap/hEvent [CloseHandle ovlap/hEvent]
	]

	receive-message: func [
		usb			[object!]
		cmd			[string!]
		/local buffer recv-cmd data
	][
		until [
			buffer: make-null-string PACKET_SIZE
			usb-pipe/read usb buffer
			buffer: trim buffer
			if empty? buffer [return buffer]
			recv-cmd: copy/part buffer 4
			any [cmd = "ALL" cmd = recv-cmd]
		]
		switch cmd [
			"ALL"  [buffer]
			"OKAY" [
				usb/remote-id: to-integer reverse to-binary copy/part skip buffer 4 4
			]
			"CNXN" [
				buffer: receive-message usb "ALL"
			]
			"WRTE" [
				data: receive-message usb "ALL"
				if "FAIL" = copy/part data 4 [
					close-device usb
					print ["**ADB**: Error:" data]
					halt
				]
				send-message usb A_OKAY ""
			]
			"CLSE" [
				send-message usb A_CLSE ""
			]
		]
		buffer
	]

	send-message: func [
		usb			[object!]
		cmd			[integer!]
		data		[string! binary!]
		/local len sum msg magic
	][
		if binary? data [data: to-string data]
		magic: cmd xor -1
		len: length? data
		sum: 0
		foreach c data [sum: sum + (to-integer c)]
		case [
			cmd = A_CNXN [
				msg: [cmd A_VERSION MAX_PAYLOAD len sum magic]
			]
			cmd = A_OPEN [
				msg: [cmd usb/local-id 0 len sum magic]
			]
			cmd = A_CLSE [
				msg: [cmd 0 usb/remote-id len sum magic]
			]
			any [cmd = A_WRTE cmd = A_OKAY] [
				msg: [cmd usb/local-id usb/remote-id len sum magic]
			]
		]
		usb-pipe/write usb third make struct! message reduce msg
		unless empty? data [usb-pipe/write usb data]
		if cmd = A_WRTE [
			if empty? receive-message device "OKAY" [
				print "**ADB**: Error: Send message failed"
				print ["message: " data]
				close-device usb
				halt
			]
		]
	]
]
