Red/System [
	Title:   "Red runtime win32 API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %windows.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2025 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#include %COM.reds

#define GENERIC_WRITE			40000000h
#define GENERIC_READ 			80000000h
#define FILE_SHARE_READ			00000001h
#define FILE_SHARE_WRITE		00000002h
#define FILE_SHARE_DELETE		00000004h
#define CREATE_NEW				00000001h
#define CREATE_ALWAYS			00000002h
#define OPEN_EXISTING			00000003h
#define OPEN_ALWAYS				00000004h
#define TRUNCATE_EXISTING		00000005h
#define FILE_ATTRIBUTE_NORMAL	00000080h
#define FILE_ATTRIBUTE_DIRECTORY  00000010h
#define FILE_FLAG_SEQUENTIAL_SCAN 08000000h

#define STD_INPUT_HANDLE		-10
#define STD_OUTPUT_HANDLE		-11
#define STD_ERROR_HANDLE		-12

#define SET_FILE_BEGIN			0
#define SET_FILE_CURRENT		1
#define SET_FILE_END			2

#define MAX_FILE_REQ_BUF		4000h			;-- 16 KB
#define OFN_HIDEREADONLY		0004h
#define OFN_NOCHANGEDIR			0008h
#define OFN_EXPLORER			00080000h
#define OFN_ALLOWMULTISELECT	00000200h

#define WIN32_FIND_DATA_SIZE	592

#define BIF_RETURNONLYFSDIRS	1
#define BIF_USENEWUI			50h
#define BIF_SHAREABLE			8000h

#define BFFM_INITIALIZED		1
#define BFFM_SELCHANGED			2
#define BFFM_SETSELECTION		1127

#define KEY_EVENT 				 			01h
#define MOUSE_EVENT 			 			02h
#define WINDOW_BUFFER_SIZE_EVENT 			04h
#define MENU_EVENT 				 			08h
#define FOCUS_EVENT 			 			10h
#define ENHANCED_KEY 			 			0100h
#define ENABLE_PROCESSED_INPUT				01h
#define ENABLE_LINE_INPUT 					02h
#define ENABLE_ECHO_INPUT 					04h
#define ENABLE_WINDOW_INPUT         		08h
#define ENABLE_QUICK_EDIT_MODE				40h
#define ENABLE_VIRTUAL_TERMINAL_INPUT		0200h
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING	04h
#define DISABLE_NEWLINE_AUTO_RETURN 		08h

#define VA_COMMIT_RESERVE		3000h						;-- MEM_COMMIT | MEM_RESERVE
#define VA_PAGE_RW				04h							;-- PAGE_READWRITE
#define VA_PAGE_RWX				40h							;-- PAGE_EXECUTE_READWRITE

#define _O_TEXT        	 		4000h  						;-- file mode is text (translated)
#define _O_BINARY       		8000h  						;-- file mode is binary (untranslated)
#define _O_WTEXT        		00010000h 					;-- file mode is UTF16 (translated)
#define _O_U16TEXT      		00020000h 					;-- file mode is UTF16 no BOM (translated)
#define _O_U8TEXT       		00040000h 					;-- file mode is UTF8  no BOM (translated)


#define FORMAT_MESSAGE_ALLOCATE_BUFFER    00000100h
#define FORMAT_MESSAGE_IGNORE_INSERTS     00000200h
#define FORMAT_MESSAGE_FROM_STRING        00000400h
#define FORMAT_MESSAGE_FROM_HMODULE       00000800h
#define FORMAT_MESSAGE_FROM_SYSTEM        00001000h

#define WEOF					FFFFh

#define INFINITE				FFFFFFFFh
#define HANDLE_FLAG_INHERIT		00000001h
#define STARTF_USESTDHANDLES	00000100h
#define STARTF_USESHOWWINDOW	00000001h

#define ERROR_BROKEN_PIPE 		109

#define IS_TEXT_UNICODE_UNICODE_MASK 	000Fh

#enum spawn-mode [
	P_WAIT:		0
	P_NOWAIT:	1
	P_OVERLAY:	2
	P_NOWAITO:	3
	P_DETACH:	4
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

tagFILETIME: alias struct! [
	dwLowDateTime	[integer!]
	dwHighDateTime	[integer!]
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

stat!: alias struct! [val [integer!]]

WIN32_FIND_DATA: alias struct! [
	dwFileAttributes	[integer!]
	ftCreationTime		[tagFILETIME value]
	ftLastAccessTime	[tagFILETIME value]
	ftLastWriteTime		[tagFILETIME value]
	nFileSizeHigh		[integer!]
	nFileSizeLow		[integer!]
	dwReserved0			[integer!]
	dwReserved1			[integer!]
	;cFileName			[byte-ptr!]				;-- WCHAR  cFileName[ 260 ]
	;cAlternateFileName	[c-string!]				;-- cAlternateFileName[ 14 ]
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
		strnicmp: "_strnicmp" [
			s1			[byte-ptr!]
			s2			[byte-ptr!]
			len			[integer!]
			return:		[integer!]
		]
		wcsupr: "_wcsupr" [
			str		[c-string!]
			return:	[c-string!]
		]
		_rename: "_wrename" [
			old		[c-string!]
			new		[c-string!]
			return:	[integer!]
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
		FileTimeToSystemTime: "FileTimeToSystemTime" [
			filetime	[tagFILETIME]
			systemtime	[tagSYSTEMTIME]
			return:		[integer!]
		]
		GetSystemTimeAsFileTime: "GetSystemTimeAsFileTime" [
			time			[tagFILETIME]
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
			hHandle                 [integer!]
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
		CloseHandle: "CloseHandle" [
			hObject                 [integer!]
			return:                 [logic!]
		]
		GetStdHandle: "GetStdHandle" [
			nStdHandle				[integer!]
			return:					[integer!]
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
			path        [c-string!]
			info-level  [integer!]
			info        [WIN32_FIND_DATA]
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
			lpFileName				[c-string!]
			dwDesiredAccess			[integer!]
			dwShareMode				[integer!]
			lpSecurityAttributes	[security-attributes!]
			dwCreationDisposition	[integer!]
			dwFlagsAndAttributes	[integer!]
			hTemplateFile			[integer!]
			return:					[integer!]
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
			buf-len		[integer!]
			buffer		[byte-ptr!]
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
]