REBOL [
	Name: "CALL for Win32"
	Author: "Nenad Rakocevic"
	Purpose: "Blocking execution of external commands for Windows OS"
]

context [
	sys-path: to-rebol-file get-env "SystemRoot"
	kernel32: load/library sys-path/System32/kernel32.dll

	SECURITY_ATTRIBUTES: make struct! [
		nLength 			 [integer!]
		lpSecurityDescriptor [integer!]
		bInheritHandle 		 [integer!]
	] none

	STARTUPINFO: make struct! startup-info-struct: [
		cb 				[integer!]
		lpReserved 		[integer!]
		lpDesktop		[integer!]
		lpTitle			[integer!]
		dwX				[integer!]
		dwY				[integer!]
		dwXSize			[integer!]
		dwYSize			[integer!]
		dwXCountChars 	[integer!]
		dwYCountChars 	[integer!]
		dwFillAttribute	[integer!]
		dwFlags			[integer!]
		wShowWindow		[short]
		cbReserved2		[short]
		lpReserved2		[integer!]
		hStdInput		[integer!]
		hStdOutput		[integer!]
		hStdError		[integer!]
	] none

	PROCESS_INFORMATION: make struct! [
		hProcess	[integer!]
		hThread 	[integer!]
		dwProcessID	[integer!]
		dwThreadID	[integer!]
	] none

	CreatePipe: make routine!  [
		phReadPipe 		 [struct! [num [integer!]]]
		phWritePipe 	 [struct! [num [integer!]]]
		lpPipeAttributes [struct! [a [integer!] b [integer!] c [integer!]]]
		nSize 			 [integer!]
		return:			 [integer!]
	] kernel32 "CreatePipe"

	ReadFile: make routine! [
		hFile 				 [integer!]
		lpBuffer 			 [string!]
		nNumberOfBytesToRead [integer!]
		lpNumberOfBytesRead  [struct! [num [integer!]]]
		lpOverlapped 		 [integer!]
		return:				 [integer!]
	] kernel32 "ReadFile"
	
	PeekNamedPipe: make routine! [
		hNamedPipe			[integer!]
		lpBuffer			[integer!]
		nBufferSize			[integer!]
		lpBytesRead			[integer!]
		lpTotalBytesAvail	[struct! [cnt [integer!]]]
		lpBytesLeftThisMessage [integer!]
		return: 			[integer!]
	] kernel32 "PeekNamedPipe"
	
	WriteFile: make routine! [
		hFile 					[integer!]
		lpBuffer				[string!]
		nNumberOfBytesToWrite   [integer!]
		lpNumberOfBytesWritten  [struct! [num [integer!]]]
		lpOverlapped			[integer!]
		return:					[integer!]
	] kernel32 "WriteFile"
	
	SetHandleInformation: make routine! [
		hObject 	[integer!]
		dwMask		[integer!]
		dwFlags		[integer!]
		return: 	[integer!]
	] kernel32 "SetHandleInformation"
	
	GetEnvironmentStrings: make routine! [
		return: [integer!]
	] kernel32 "GetEnvironmentStringsW"
	
	FreeEnvironmentStrings: make routine! [
		lpszEnvironmentBlock [integer!]
		return: [integer!]
	] kernel32 "FreeEnvironmentStringsW"
	
	CREATE_UNICODE_ENVIRONMENT: to-integer #{00000400}
	
	unless all [value? 'set-env native? :set-env][
		set 'set-env make routine! [
			name	[string!]
			value	[string!]
			return: [integer!]
		] kernel32 "SetEnvironmentVariableA"
	]

	CreateProcess: make routine! compose/deep [
		lpApplicationName	 [integer!]
		lpCommandLine		 [string!]	
		lpProcessAttributes	 [struct! [a [integer!] b [integer!] c [integer!]]]
		lpThreadAttributes	 [struct! [a [integer!] b [integer!] c [integer!]]]
		bInheritHandles		 [char!]
		dwCreationFlags		 [integer!]
		lpEnvironment		 [integer!]
		lpCurrentDirectory	 [integer!]
		lpStartupInfo		 [struct! [(startup-info-struct)]]
		lpProcessInformation [struct! [a [integer!] b [integer!] c [integer!] d [integer!]]]
		return:				 [integer!]
	] kernel32 "CreateProcessA"

	CloseHandle: make routine! [
		hObject	[integer!]
		return: [integer!]
	] kernel32 "CloseHandle"

	GetExitCodeProcess: make routine! [
		hProcess	[integer!]
		lpExitCode	[struct! [int [integer!]]] 
		return:		[integer!]
	] kernel32 "GetExitCodeProcess"
	
	Sleep: make routine! [
	  dwMilliseconds [long]
	] kernel32 "Sleep"
	
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

	STARTF_USESTDHANDLES: 	to-integer #{00000100}
	STARTF_USESHOWWINDOW: 	1
	SW_HIDE: 				0
	STILL_ACTIVE:			259

	null: to-char 0
	lpDWORD: make struct! [int [integer!]] none
	make-lpDWORD: does [make struct! lpDWORD [0]]
	
	sa: make struct! SECURITY_ATTRIBUTES [0 0 1]
	sa/nLength: length? third sa
	
	start-info: make struct! STARTUPINFO none
	start-info/cb: length? third start-info
	start-info/dwFlags: STARTF_USESTDHANDLES
	
	make-null-string!: func [len [integer!]][
		head insert/dup make string! len null len
	]
	
	get-error-msg: has [out][
		out: make-null-string! 256
		FormatMessage fmt-msg-flags 0 last-error: GetLastError 0 out 256 0
		trim/tail out
	]
	
	try*: func [body [block!] /local out err][
		if error? set/any 'err try body [
			out: get-error-msg
			err: disarm err
			if string? get in err 'arg1 [insert out rejoin [err/arg1 ": "]]
			return out
		]
		none
	]
	
	cmd: context [
		output: error: none
		show?: input?: no

		pipe-size: 10'000
		pipe-buffer: make-null-string! pipe-size

		si: make struct! start-info second start-info
		pi: make struct! PROCESS_INFORMATION none

		in-hRead:      make-lpDWORD
		in-hWrite:     make-lpDWORD
		out-hRead:     make-lpDWORD
		out-hWrite:    make-lpDWORD
		err-hRead:	   make-lpDWORD
		err-hWrite:	   make-lpDWORD
		bytes-avail:   make-lpDWORD
		bytes-read:    make-lpDWORD
		bytes-written: make-lpDWORD
		exit-code:     make-lpDWORD
	]

	launch-call: func [cmd-line [string!] /local ret env][
		cmd-line: join cmd-line null
		change/dup cmd/pipe-buffer null cmd/pipe-size
		
		ret: catch [
			;-- Create STDOUT pipe and ensure the read handle is not inherited
			if zero? CreatePipe cmd/out-hRead cmd/out-hWrite sa 0 [throw 1]
			if zero? SetHandleInformation cmd/out-hRead/int 1 0 [throw 3]
			cmd/si/hStdOutput: cmd/out-hWrite/int
			
			;-- Create STDERR pipe and ensure the read handle is not inherited			
			if zero? CreatePipe cmd/err-hRead cmd/err-hWrite sa 0 [throw 1]
			if zero? SetHandleInformation cmd/err-hRead/int 1 0 [throw 3]
			cmd/si/hStdError:  cmd/err-hWrite/int

			if cmd/input? [
				;-- Create STDIN pipe and ensure the write handle is not inherited
				if zero? CreatePipe cmd/in-hRead cmd/in-hWrite sa 0 [throw 1]
				if zero? SetHandleInformation cmd/in-hWrite/int 1 0 [throw 3]
				cmd/si/hStdInput: cmd/in-hRead/int
			]
			
			unless cmd/show? [cmd/si/dwFlags: cmd/si/dwFlags or STARTF_USESHOWWINDOW]			
			
			env: GetEnvironmentStrings
			ret: CreateProcess 0 cmd-line sa sa to char! 1 CREATE_UNICODE_ENVIRONMENT env 0 cmd/si cmd/pi
			FreeEnvironmentStrings env
			
			if zero? ret [throw 2]
			
			ret: none
		]
		if integer? ret [
			make error! join pick [
				"CreatePipe"
				"CreateProcess"
				"SetHandleInformation"
			] ret " failed!"
		]
	]
	
	read-pipe: func [buffer pipe /local remain][
		if zero? PeekNamedPipe pipe/int 0 0 0 cmd/bytes-avail 0 [throw 1]

		unless zero? remain: cmd/bytes-avail/int [ 
			until [
				if zero? ReadFile pipe/int cmd/pipe-buffer cmd/pipe-size cmd/bytes-read 0 [throw 2]

				insert/part tail buffer cmd/pipe-buffer cmd/bytes-read/int

				change/dup cmd/pipe-buffer null cmd/pipe-size
				remain: remain - cmd/bytes-read/int 
				zero? remain 
			]
		]
	]
	
	write-pipe: func [buffer pipe][
		until [
			if zero? WriteFile pipe/int buffer length? buffer cmd/bytes-written 0 [throw 4]		
			tail? buffer: skip buffer cmd/bytes-written/int
		]
		;-- Close the pipe handles so the child process stops reading
		CloseHandle cmd/in-hRead/int
		CloseHandle cmd/in-hWrite/int
	]

	get-process-info: has [ret][	
		;unless zero? cmd/pi/hProcess [
			ret: catch [
				if zero? GetExitCodeProcess cmd/pi/hProcess cmd/exit-code [throw 3]
				
				if cmd/output [read-pipe cmd/output cmd/out-hRead]
				if cmd/error  [read-pipe cmd/error  cmd/err-hRead]
				
				if cmd/exit-code/int <> STILL_ACTIVE [
					CloseHandle cmd/pi/hProcess
					CloseHandle cmd/pi/hThread
					CloseHandle cmd/out-hRead/int
					CloseHandle cmd/out-hWrite/int
					CloseHandle cmd/err-hRead/int
					CloseHandle cmd/err-hWrite/int
					cmd/pi/hProcess: 0
					return true
				]
				ret: none
			]
			if integer? ret [
				make error! join pick [
					"PeekNamedPipe"
					"ReadFile"
					"GetExitCodeProcess"
					"WriteFile"
				] ret " failed!"
			]
		;]
		false
	]

	; Patched from 2.7.8
	if not value? 'deline [
    	deline: func [
    		{Converts string terminators to standard format, e.g. CRLF to LF. (Modifies)}
    		string [any-string!]
    		/lines "Convert to block of lines (does not modify)"
    		/local linechar a b output
    	][
    		linechar: make bitset! #{
    			FFDBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    		}
    		
    		also case [
    			not lines [
    				parse/all/case either binary? string [as-string string] [string] [
    					any [to cr a: cr opt lf b: (
    							b: change/part a lf b
    						) :b] to end
    				]
    				string
    			]
    			empty? string [copy []]
    			'else [
    				output: make block! divide length? string 50
    				if binary? string [string: as-string string]
    				parse/all/case string [any [
    						copy a some linechar (output: insert output a) [crlf | cr | lf | end]
    						|
    						[crlf | cr | lf] (output: insert output copy "")
    					]]
    				head output
    			]
    		] set [string output a b] none
    	]
    ]
    
	set 'win-call func [
		command [string!]
		/input
			in [string! binary!]
		/output
			out [string! binary!]
		/error
			err [string! binary!]
		/wait						;-- placeholder, win-call is always waiting
		/show
		/local
			res msg
	][
		cmd/input?: to-logic input
		cmd/show?: to-logic show
		cmd/output: out
		cmd/error: err
		
		if msg: try* [launch-call command][return msg]
		if input [write-pipe in cmd/in-hWrite]
		
		until [
			Sleep 10
			if msg: try* [res: get-process-info][return msg]
			res
		]
		
		if all [out string? out][deline out]
		if all [err string? err][deline err]
		
		cmd/exit-code/int
	]
]
