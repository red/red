Red/System [
	Title:   "Red/System windows Binding"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %windows.reds
	Rights:  "Copyright (c) 2014-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#if OS = 'Windows [
	; Spawn enums
	#enum spawn-mode [
		P_WAIT:          0
		P_NOWAIT:        1
		P_OVERLAY:       2
		P_NOWAITO:       3
		P_DETACH:        4
	]

	#define O_TEXT      4000h                           ;-- file mode is text (translated)
	#define O_BINARY    8000h                           ;-- file mode is binary (untranslated)
	#define O_WTEXT     00010000h                       ;-- file mode is UTF16 (translated)
	#define O_U16TEXT   00020000h                       ;-- file mode is UTF16 no BOM (translated)
	#define O_U8TEXT    00040000h                       ;-- file mode is UTF8  no BOM (translated)

	#define INFINITE                FFFFFFFFh
	#define HANDLE_FLAG_INHERIT     00000001h
	#define STARTF_USESTDHANDLES    00000100h

	#define ERROR_BROKEN_PIPE 109

	#define IS_TEXT_UNICODE_UNICODE_MASK 	000Fh

	#define GENERIC_WRITE	40000000h
	#define GENERIC_READ	80000000h

	#define FILE_SHARE_READ		1
	#define FILE_SHARE_WRITE	2
	#define FILE_SHARE_DELETE	4

	#define CREATE_NEW			1
	#define CREATE_ALWAYS		2
	#define OPEN_EXISTING		3
	#define OPEN_ALWAYS			4
	#define TRUNCATE_EXISTING	5

	#define FILE_ATTRIBUTE_NORMAL		00000080h
	#define FILE_FLAG_SEQUENTIAL_SCAN	08000000h

	#define STD_INPUT_HANDLE	-10
	#define STD_OUTPUT_HANDLE	-11
	#define STD_ERROR_HANDLE	-12

	process-info!: alias struct! [
		hProcess        [integer!]
		hThread         [integer!]
		dwProcessId     [integer!]
		dwThreadId      [integer!]
	]
	startup-info!: alias struct! [
		cb                [integer!]
		lpReserved        [c-string!]
		lpDesktop         [c-string!]
		lpTitle           [c-string!]
		dwX               [integer!]
		dwY               [integer!]
		dwXSize           [integer!]
		dwYSize           [integer!]
		dwXCountChars     [integer!]
		dwYCountChars     [integer!]
		dwFillAttribute   [integer!]
		dwFlags           [integer!]
		wShowWindow-a     [byte!]           ; 16 bits integer needed here for windows WORD type
		wShowWindow-b     [byte!]
		cbReserved2-a     [byte!]
		cbReserved2-b     [byte!]
		lpReserved2       [byte-ptr!]
		hStdInput         [integer!]
		hStdOutput        [integer!]
		hStdError         [integer!]
	]
	security-attributes!: alias struct! [
		nLength              [integer!]
		lpSecurityDescriptor [integer!]
		bInheritHandle       [logic!]
	]

	#import [ "kernel32.dll" stdcall [
		create-process: "CreateProcessW" [ "Creates a new process and its primary thread"
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
		wait-for-single-object: "WaitForSingleObject" [ "Waits until the specified object is in the signaled state or the time-out interval elapses"
			hHandle                 [integer!]
			dwMilliseconds          [integer!]
			return:                 [integer!]
		]
		get-exit-code-process: "GetExitCodeProcess" [ "Retrieves the termination status of the specified process"
			hProcess				[integer!]
			lpExitCode				[int-ptr!]
			return:                 [logic!]
		]
		create-pipe: "CreatePipe" [ "Creates an anonymous pipe, and returns handles to the read and write ends of the pipe"
			hReadPipe               [int-ptr!]
			hWritePipe              [int-ptr!]
			lpPipeAttributes        [security-attributes!]
			nSize                   [integer!]
			return:                 [logic!]
		]
		create-file: "CreateFileW" [ "Creates or opens a file or I/O device"
			lpFileName				[c-string!]
			dwDesiredAccess			[integer!]
			dwShareMode				[integer!]
			lpSecurityAttributes	[security-attributes!]
			dwCreationDisposition	[integer!]
			dwFlagsAndAttributes	[integer!]
			hTemplateFile			[integer!]
			return:					[integer!]
		]
		close-handle: "CloseHandle" [ "Closes an open object handle"
			hObject                 [integer!]
			return:                 [logic!]
		]
		get-std-handle: "GetStdHandle" [
			nStdHandle				[integer!]
			return:					[integer!]
		]
		io-read: "ReadFile" [ "Reads data from the specified file or input/output device"
			hFile                   [integer!]
			lpBuffer                [byte-ptr!]
			nNumberOfBytesToRead    [integer!]
			lpNumberOfBytesRead     [int-ptr!]
			lpOverlapped            [integer!]
			return:                 [logic!]
		]
		io-write: "WriteFile" [ "Writes data to the specified file or input/output (I/O) device"
			hFile					[integer!]
			lpBuffer				[byte-ptr!]
			nNumberOfBytesToWrite   [integer!]
			lpNumberOfBytesWritten  [int-ptr!]
			lpOverlapped            [integer!]
			return:                 [logic!]
		]
		set-handle-information: "SetHandleInformation" [ "Sets certain properties of an object handle"
			hObject					[integer!]
			dwMask					[integer!]
			dwFlags					[integer!]
			return:					[logic!]
		]
		get-last-error: "GetLastError" [ "Retrieves the calling thread's last-error code value"
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
		lstrlen: "lstrlenW" [
			str						[c-string!]
			return:					[integer!]
		]
		] ; stdcall
	] ; #import
] ; OS = 'Windows
