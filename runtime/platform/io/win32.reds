Red/System [
	Title:   "win32 I/O API imported functions definitions"
	Author:  "Xie Qingtian"
	File: 	 %win32.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
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

OVERLAPPED: alias struct! [
	Internal		[int-ptr!]
	InternalHigh	[int-ptr!]
	Offset			[integer!]				;-- or Pointer [int-ptr!]
	OffsetHigh		[integer!]
	hEvent			[int-ptr!]
]

WSADATA: alias struct! [					;-- varies from 32bit to 64bit, for 32bit: 400 bytes
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

WIN32_FIND_DATA: alias struct! [
	dwFileAttributes	[integer!]
	ftCreationTime		[float!]
	ftLastAccessTime	[float!]
	ftLastWriteTime		[float!]
	nFileSizeHigh		[integer!]
	nFileSizeLow		[integer!]
	dwReserved0			[integer!]
	dwReserved1			[integer!]
	;cFileName			[byte-ptr!]				;-- WCHAR  cFileName[ 260 ]
	;cAlternateFileName	[c-string!]				;-- cAlternateFileName[ 14 ]
]

AcceptEx!: alias function! [
	sListenSocket			[int-ptr!]
	sAcceptSocket			[int-ptr!]
	lpOutputBuffer			[byte-ptr!]
	dwReceiveDataLength		[integer!]
	dwLocalAddressLength	[integer!]
	dwRemoteAddressLength	[integer!]
	lpdwBytesReceived		[int-ptr!]
	lpOverlapped			[OVERLAPPED]
	return:					[logic!]
]

#import [
	"kernel32.dll" stdcall [
		GetFileAttributesW: "GetFileAttributesW" [
			path		[c-string!]
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
		CreateFileW: "CreateFileW" [
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
		ReadFile:	"ReadFile" [
			file		[integer!]
			buffer		[byte-ptr!]
			bytes		[integer!]
			read		[int-ptr!]
			overlapped	[int-ptr!]
			return:		[integer!]
		]
		WriteFile:	"WriteFile" [
			file		[integer!]
			buffer		[byte-ptr!]
			bytes		[integer!]
			written		[int-ptr!]
			overlapped	[int-ptr!]
			return:		[integer!]
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
		SetFilePointer: "SetFilePointer" [
			file		[integer!]
			distance	[integer!]
			pDistance	[int-ptr!]
			dwMove		[integer!]
			return:		[integer!]
		]
		SetEndOfFile: "SetEndOfFile" [
			file		[integer!]
			return:		[integer!]
		]
		lstrlen: "lstrlenW" [
			str			[byte-ptr!]
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
	]
	"ws2_32.dll" stdcall [
		WSAStartup: "WSAStartup" [
			version		[integer!]
			lpWSAData	[WSADATA]
			return:		[integer!]
		]
		WSASocketW: "WSASocketW" [
			af				[integer!]
			type			[integer!]
			protocol		[integer!]
			lpProtocolInfo	[WSAPROTOCOL_INFOW]
			g				[integer!]
			dwFlags			[integer!]
			return:			[int-ptr!]
		]
		WSASend: "WSASend" [
			s					[int-ptr!]
			lpBuffers			[byte-ptr!]
			dwBufferCount		[integer!]
			lpNumberOfBytesSent	[int-ptr!]
			dwFlags				[integer!]
			lpOverlapped		[OVERLAPPED]
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
			lpOverlapped		[OVERLAPPED]
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
		]
	]
	LIBC-file cdecl [
		wcsupr: "_wcsupr" [
			str		[c-string!]
			return:	[c-string!]
		]
	]
]
#import [
	"kernel32.dll" stdcall [
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
			lpOverlapped		[OVERLAPPED]
			dwMilliseconds		[integer!]
			return:				[logic!]
		]
		PostQueuedCompletionStatus: "PostQueuedCompletionStatus" [
			CompletionPort		[int-ptr!]
			nTransferred		[integer!]
			dwCompletionKey		[int-ptr!]
			lpOverlapped		[OVERLAPPED]
			return:				[logic!]
		]
	]
]