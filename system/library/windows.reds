Red/System [
	Title:   "Red/System windows Binding"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %window.reds
	Rights:  "Copyright (c) 2014 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#if target = 'IA-32 [
	system/fpu/mask/overflow: on
	system/fpu/mask/underflow: on
	system/fpu/mask/zero-divide: on
	system/fpu/mask/invalid-op: on
	system/fpu/update
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

	process-info!: alias struct! [
		hProcess        [opaque!]
		hThread         [opaque!]
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
		hStdInput         [opaque!]
		hStdOutput        [opaque!]
		hStdError         [opaque!]
	]
	security-attributes!: alias struct! [
		nLength              [integer!]
		lpSecurityDescriptor [opaque!]
		bInheritHandle       [logic!]
	]

	#import [ "kernel32.dll" stdcall [
		create-process: "CreateProcessA" [ "Creates a new process and its primary thread"
			lpApplicationName       [c-string!]
			lpCommandLine           [c-string!]
			lpProcessAttributes     [opaque!]
			lpThreadAttributes      [opaque!]
			bInheritHandles         [logic!]
			dwCreationFlags         [integer!]
			lpEnvironment           [opaque!]
			lpCurrentDirectory      [c-string!]
			lpStartupInfo           [startup-info!]
			lpProcessInformation    [process-info!]
			return:                 [logic!]
		]
		wait-for-single-object: "WaitForSingleObject" [ "Waits until the specified object is in the signaled state or the time-out interval elapses"
			hHandle                 [opaque!]
			dwMilliseconds          [integer!]
			return:                 [integer!]
		]
		create-pipe: "CreatePipe" [ "Creates an anonymous pipe, and returns handles to the read and write ends of the pipe"
			hReadPipe               [int-ptr!]
			hWritePipe              [int-ptr!]
			lpPipeAttributes        [security-attributes!]
			nSize                   [integer!]
			return:                 [logic!]
		]
		close-handle: "CloseHandle" [ "Closes an open object handle"
			hObject                 [opaque!]
			return:                 [logic!]
		]
		read-file: "ReadFile" [ "Reads data from the specified file or input/output device"
			hFile                   [opaque!]
			lpBuffer                [byte-ptr!]
			nNumberOfBytesToRead    [integer!]
			lpNumberOfBytesRead     [int-ptr!]
			lpOverlapped            [opaque!]
			return:                 [logic!]
		]
		write-file: "WriteFile" [ "Writes data to the specified file or input/output (I/O) device"
			hFile					[opaque!]
			lpBuffer				[byte-ptr!]
			nNumberOfBytesToWrite   [integer!]
			lpNumberOfBytesWritten  [int-ptr!]
			lpOverlapped            [opaque!]
			return:                 [logic!]
		]
		set-handle-information: "SetHandleInformation" [ "Sets certain properties of an object handle"
			hObject					[opaque!]
			dwMask					[integer!]
			dwFlags					[integer!]
			return:					[logic!]
		]
		get-last-error: "GetLastError" [ "Retrieves the calling thread's last-error code value"
			return:                 [integer!]
		]
		] ; stdcall
	] ; #import
	#import [ "advapi32.dll" stdcall [
		is-text-unicode: "IsTextUnicode" [ "Determines if a buffer is likely to contain a form of Unicode text"
			lpv						[byte-ptr!]
			iSize					[integer!]
			lpiResult				[int-ptr!]
		]
		] ; stdcall
	] ; #import

] ; OS = 'Windows
