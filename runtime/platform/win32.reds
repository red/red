Red/System [
	Title:   "Red runtime win32 API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
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

platform: context [

	gui-print: 0										;-- `print` function used for gui-console

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

	gdiplus-token: 0
	page-size: 4096

	#import [
		LIBC-file cdecl [
			;putwchar: "putwchar" [
			;	wchar		[integer!]					;-- wchar is 16-bit on Windows
			;]
			wprintf: "wprintf" [
				[variadic]
				return: 	[integer!]
			]
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

	#either sub-system = 'gui [
		#either gui-console? = yes [
			#include %win32-gui.reds
		][
			#include %win32-cli.reds
		]
	][
		#include %win32-cli.reds
	]

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
		return: [logic!]			;-- true for success
	][
		SetEnvironmentVariable name value
	]

	get-env: func [
		;; Returns size of retrieved value for success or zero if missing
		;; If return size is greater than valsize then value contents are undefined
		name	[c-string!]
		value	[c-string!]
		valsize [integer!]			;-- includes null terminator
		return: [integer!]
	][
		GetEnvironmentVariable name value valsize
	]

	get-time: func [
		utc?	 [logic!]
		precise? [logic!]
		return:  [float!]
		/local
			time	[tagSYSTEMTIME]
			h		[integer!]
			m		[integer!]
			sec		[integer!]
			milli	[integer!]
			t		[float!]
	][
		time: declare tagSYSTEMTIME
		either utc? [GetSystemTime time][GetLocalTime time]
		h: time/hour-minute and FFFFh
		m: time/hour-minute >>> 16
		sec: time/second and FFFFh
		milli: either precise? [time/second >>> 16][0]
		t: as-float h * 3600 + (m * 60) + sec * 1000 + milli
		t * 1E6				;-- nano second
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