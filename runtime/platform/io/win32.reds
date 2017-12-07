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

OVERLAPPED: alias struct! [
	Internal		[int-ptr!]
	InternalHigh	[int-ptr!]
	Offset			[integer!]				;-- or Pointer [int-ptr!]
	OffsetHigh		[integer!]
	hEvent			[int-ptr!]
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
		CloseHandle:	"CloseHandle" [
			obj			[integer!]
			return:		[logic!]
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
			buf-len		[integer!]
			buffer		[byte-ptr!]
			return:		[integer!]
		]
	]
	"user32.dll" stdcall [
		SendMessage: "SendMessageW" [
			hWnd		[integer!]
			msg			[integer!]
			wParam		[integer!]
			lParam		[integer!]
			return: 	[integer!]
		]
		GetForegroundWindow: "GetForegroundWindow" [
			return:		[integer!]
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