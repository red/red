Red/System [
	Title:	"Thread Implementation"
	Author: "Xie Qingtian"
	File: 	%threads.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

thread-func!: alias function! [
	worker	[int-ptr!]			;-- task worker
	data	[int-ptr!]			;-- task private data
]

thread-task!: alias struct! [
	do		[thread-func!]		;-- func for doing what you want
	exit	[thread-func!]		;-- exit func for freeing the private data
	data	[int-ptr!]			;-- task private data
	urgent? [logic!]			;-- is urgent task?
]

thread: context [

#either OS = 'Windows [
	#import [
	;	LIBC-file cdecl [
	;		;-- use CreateThread Win32 API instead once we get rid of libc
	;		_beginthreadex: "_beginthreadex" [
	;			security	[int-ptr!]
	;			stack_size	[integer!]
	;			start		[int-ptr!]
	;			arglist		[int-ptr!]
	;			initflag	[integer!]
	;			thread_id	[int-ptr!]
	;			return:		[integer!]
	;		]
	;		_endthreadex: "_endthreadex" [
	;			retval		[integer!]
	;		]
	;	]
		"kernel32.dll" stdcall [
			CreateThread: "CreateThread" [
				security	[int-ptr!]
				stack_size	[integer!]
				start		[int-ptr!]
				arglist		[int-ptr!]
				initflag	[integer!]
				thread_id	[int-ptr!]
				return:		[handle!]
			]
			ExitThread: "ExitThread" [
				retval		[integer!]
			]
			SuspendThread: "SuspendThread" [
				hThread		[handle!]
				return:		[integer!]
			]
			ResumeThread: "ResumeThread" [
				hThread		[handle!]
				return:		[integer!]
			]
			GetCurrentThreadId: "GetCurrentThreadId" [
				return:		[integer!]
			]
			GetExitCodeThread: "GetExitCodeThread" [
				hThread		[handle!]
				lpExitCode	[int-ptr!]
				return:		[logic!]
			]
		]
	]

	create: func [
		name	[c-string!]
		address [int-ptr!]
		args	[int-ptr!]
		stack	[integer!]
		return: [handle!]
	][
		CreateThread null stack address args 0 null
	]

	kill: func [
		thread	[handle!]
	][
		CloseHandle thread
	]

	exit: func [
		retcode [integer!]
	][
		ExitThread retcode
	]

	wait: func [
		thread	[handle!]
		timeout [integer!]
		ret		[int-ptr!]
		return: [integer!]
		/local
			r	[integer!]
	][
		r: WaitForSingleObject thread timeout
		case [
			r = WAIT_TIMEOUT	[0]
			r < WAIT_OBJECT_0	[-1]
			ret <> null [
				GetExitCodeThread thread ret
				1
			]
			true [1]
		]
	]

	suspend: func [
		thread	[handle!]
		return: [logic!]
	][
		-1 <> SuspendThread thread
	]

	resume: func [
		thread	[handle!]
		return:	[logic!]
	][
		-1 <> ResumeThread thread
	]

	self: func [
		"return current thread id"
		return: [integer!]
	][
		GetCurrentThreadId
	]
][
	;TDB
]
	
]