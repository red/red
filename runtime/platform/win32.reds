Red/System [
	Title:   "Red runtime win32 API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
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


#define FORMAT_MESSAGE_ALLOCATE_BUFFER    00000100h
#define FORMAT_MESSAGE_IGNORE_INSERTS     00000200h
#define FORMAT_MESSAGE_FROM_STRING        00000400h
#define FORMAT_MESSAGE_FROM_HMODULE       00000800h
#define FORMAT_MESSAGE_FROM_SYSTEM        00001000h

#define WEOF				FFFFh

#define INFINITE				FFFFFFFFh
#define HANDLE_FLAG_INHERIT		00000001h
#define STARTF_USESTDHANDLES	00000100h
#define STARTF_USESHOWWINDOW	00000001h

#define ERROR_BROKEN_PIPE 109

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

platform: context [

	#enum file-descriptors! [
		fd-stdout: 1									;@@ hardcoded, safe?
		fd-stderr: 2									;@@ hardcoded, safe?
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

	gdiplus-token: 0
	page-size: 4096

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
				buffer			[c-string!]
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
				hObject                 [integer!]
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
				return:                 [logic!]
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
	]

	#include %win32-print.reds

	;-------------------------------------------
	;-- Allocate paged virtual memory region from OS
	;-------------------------------------------
	allocate-virtual: func [
		size 	[integer!]								;-- allocated size in bytes (page size multiple)
		exec? 	[logic!]								;-- TRUE => executable region
		return: [int-ptr!]								;-- allocated memory region pointer
		/local ptr prot
	][
		prot: either exec? [VA_PAGE_RWX][VA_PAGE_RW]

		ptr: VirtualAlloc null size VA_COMMIT_RESERVE prot
		if ptr = null [throw OS_ERROR_VMEM_OUT_OF_MEMORY]
		ptr
	]

	;-------------------------------------------
	;-- Free paged virtual memory region from OS
	;-------------------------------------------
	free-virtual: func [
		ptr [int-ptr!]									;-- address of memory region to release
	][
		if negative? VirtualFree ptr ptr/value [
			 throw OS_ERROR_VMEM_RELEASE_FAILED
		]
	]

	init-gdiplus: func [/local startup-input][
		startup-input: declare GdiplusStartupInput!
		startup-input/GdiplusVersion: 1
		startup-input/DebugEventCallback: 0
		startup-input/SuppressBackgroundThread: 0
		startup-input/SuppressExternalCodecs: 0
		GdiplusStartup :gdiplus-token as-integer startup-input 0
	]

	shutdown-gdiplus: does [
		GdiplusShutdown gdiplus-token 
	]

	get-current-dir: func [
		len		[int-ptr!]
		return: [c-string!]
		/local
			size [integer!]
			path [byte-ptr!]
	][
		size: GetCurrentDirectory 0 null				;-- include NUL terminator
		path: allocate size << 1
		GetCurrentDirectory size path
		len/value: size - 1
		as c-string! path
	]

	wait: func [time [integer!]][Sleep time]

	set-current-dir: func [
		path	[c-string!]
		return: [logic!]
	][
		SetCurrentDirectory path
	]

	set-env: func [
		name	[c-string!]
		value	[c-string!]
		return: [logic!]								;-- true for success
	][
		SetEnvironmentVariable name value
	]

	get-env: func [
		;; Returns size of retrieved value for success or zero if missing
		;; If return size is greater than valsize then value contents are undefined
		name	[c-string!]
		value	[c-string!]
		valsize [integer!]								;-- includes null terminator
		return: [integer!]
	][
		GetEnvironmentVariable name value valsize
	]

	get-time: func [
		utc?	 [logic!]
		precise? [logic!]
		return:  [float!]
		/local
			tm	[tagSYSTEMTIME value]
			h		[integer!]
			m		[integer!]
			sec		[integer!]
			milli	[integer!]
			t		[float!]
			mi		[float!]
	][
		GetSystemTime tm
		h: tm/hour-minute and FFFFh
		m: tm/hour-minute >>> 16
		sec: tm/second and FFFFh
		milli: either precise? [tm/second >>> 16][0]
		mi: as float! milli
		mi: mi / 1000.0
		t: as-float h * 3600 + (m * 60) + sec
		t: t + mi
		t
	]

	get-date: func [
		utc?	[logic!]
		return:	[integer!]
		/local
			tm		[tagSYSTEMTIME value]
			tzone	[tagTIME_ZONE_INFORMATION value]
			bias	[integer!]
			res		[integer!]
			y		[integer!]
			m		[integer!]
			d		[integer!]
			h		[integer!]
	][
		either utc? [GetSystemTime tm][GetLocalTime tm]
		y: tm/year-month and FFFFh
		m: tm/year-month >>> 16
		d: tm/week-day >>> 16

		either utc? [h: 0][
			res: GetTimeZoneInformation tzone
			bias: tzone/Bias
			if res = 2 [bias: bias + tzone/DaylightBias] ;-- TIME_ZONE_ID_DAYLIGHT: 2
			bias: 0 - bias
			h: bias / 60
			if h < 0 [h: 0 - h and 0Fh or 10h]			;-- properly set the sign bit
			h: h << 2 or (bias // 60 / 15 and 03h)
		]
		y << 17 or (m << 12) or (d << 7) or h
	]

	open-console: func [return: [logic!]][
		either AllocConsole [
			stdin:  win32-startup-ctx/GetStdHandle WIN_STD_INPUT_HANDLE
			stdout: win32-startup-ctx/GetStdHandle WIN_STD_OUTPUT_HANDLE
			stderr: win32-startup-ctx/GetStdHandle WIN_STD_ERROR_HANDLE
			yes
		][
			no
		]
	]

	close-console: func [return: [logic!]][
		FreeConsole
	]

	;-------------------------------------------
	;-- Do platform-specific initialization tasks
	;-------------------------------------------
	init: func [/local h [int-ptr!]] [
		init-gdiplus
		#either libRed? = no [
			CoInitializeEx 0 COINIT_APARTMENTTHREADED
		][
			#if export-ABI <> 'stdcall [
				CoInitializeEx 0 COINIT_APARTMENTTHREADED
			]
		]
		crypto/init-provider
		#if sub-system = 'console [init-dos-console]
		#if unicode? = yes [
			h: __iob_func
			_setmode _fileno h + 8 _O_U16TEXT				;@@ stdout, throw an error on failure
			_setmode _fileno h + 16 _O_U16TEXT				;@@ stderr, throw an error on failure
		]
	]
]