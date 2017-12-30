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
][	;-- POSIX

	#define	ESRCH		3

	pthread_attr_t: alias struct! [		;-- 36 bytes
		_pad1	[integer!]
		_pad2	[integer!]
		_pad3	[integer!]
		_pad4	[integer!]
		_pad5	[integer!]
		_pad6	[integer!]
		_pad7	[integer!]
		_pad8	[integer!]
		_pad9	[integer!]
	]

	#import [
		"libpthread.so.0" cdecl [
			pthread_attr_init: "pthread_attr_init" [
				attr		[pthread_attr_t]
				return:		[integer!]
			]
			pthread_attr_destroy: "pthread_attr_destroy" [
				attr		[pthread_attr_t]
				return:		[integer!]
			]
			pthread_attr_setstacksize: "pthread_attr_setstacksize" [
				attr		[pthread_attr_t]
				stack_size	[integer!]
				return:		[integer!]
			]
			pthread_create: "pthread_create" [
				thread		[int-ptr!]
				attr		[pthread_attr_t]
				start		[int-ptr!]
				arglist		[int-ptr!]
				return:		[integer!]
			]
			pthread_kill: "pthread_kill" [
				thread		[int-ptr!]
				sig			[integer!]
				return:		[integer!]
			]
			pthread_join: "pthread_join" [
				thread		[int-ptr!]
				retval		[int-ptr!]
				return:		[integer!]
			]
			pthread_exit: "pthread_exit" [
				retval		[int-ptr!]
			]
			pthread_self: "pthread_self" [
				return:		[integer!]
			]
		]
	]

	create: func [
		name	[c-string!]
		address [int-ptr!]
		args	[int-ptr!]
		stack	[integer!]
		return: [handle!]
		/local
			attr [pthread_attr_t value]
			t	 [integer!]
			ret	 [integer!]
	][
		t: 0
		either stack > 0 [
			either zero? pthread_attr_init :attr [
				pthread_attr_setstacksize :attr stack
			][
				pthread_attr_destroy :attr
				return null
			]
		][attr: null]

		ret: pthread_create :t attr address args
		pthread_attr_destroy :attr
		either zero? ret [as handle! t][null]
	]

	kill: func [
		thread	[handle!]
	][
		pthread_kill thread 0
	]

	exit: func [
		retcode [integer!]
	][
		pthread_exit :retcode
	]

	wait: func [
		thread	[handle!]
		timeout [integer!]
		retval	[int-ptr!]
		return: [integer!]
		/local
			ret	[integer!]
			r	[integer!]
	][
		ret: 0
		r: pthread_join thread :ret
		either all [r = -1 r <> ESRCH][-1][
			if retval <> null [retval/value: ret]
			1
		]
	]

	suspend: func [
		thread	[handle!]
		return: [logic!]
	][
		false
	]

	resume: func [
		thread	[handle!]
		return:	[logic!]
	][
		false
	]

	self: func [
		"return current thread id"
		return: [integer!]
	][
		pthread_self
	]
]
	
]