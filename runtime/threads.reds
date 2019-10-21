Red/System [
	Title:	"Thread Implementation"
	Author: "Xie Qingtian"
	File: 	%threads.reds
	Tabs:	4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;#define handle! int-ptr!
;#include %queue.reds
;#include %platform/definitions.reds

thread-func!: alias function! [
	udata	[int-ptr!]			;-- user data
	return: [integer!]
]

thread: context [

#either OS = 'Windows [

	#define WAIT_TIMEOUT	258

	#import [
		LIBC-file cdecl [
			;-- use _beginthreadex to be sure libc functions work properly
	 		;-- use CreateThread Win32 API instead once we get rid of libc
			_beginthreadex: "_beginthreadex" [
				security	[int-ptr!]
				stack_size	[integer!]
				start		[int-ptr!]
				arglist		[int-ptr!]
				initflag	[integer!]
				thread_id	[int-ptr!]
				return:		[handle!]
			]
			_endthreadex: "_endthreadex" [
				retval		[integer!]
			]
		]
		"kernel32.dll" stdcall [
			;CreateThread: "CreateThread" [
			;	security	[int-ptr!]
			;	stack_size	[integer!]
			;	start		[int-ptr!]
			;	arglist		[int-ptr!]
			;	initflag	[integer!]
			;	thread_id	[int-ptr!]
			;	return:		[handle!]
			;]
			;ExitThread: "ExitThread" [
			;	retval		[integer!]
			;]
			SwitchToThread: "SwitchToThread" [return: [logic!]]
			CloseHandle: "CloseHandle" [
				hObject		[handle!]
				return:		[logic!]
			]
			WaitForSingleObject: "WaitForSingleObject" [
				hHandle		[handle!]
				dwMillisec	[integer!]
				return:		[integer!]
			]
			TerminateThread: "TerminateThread" [
				hThread		[handle!]
				retcode		[integer!]
				return:		[logic!]
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

	processor-count: func [
		return: [integer!]
		/local
			info [tagSYSTEM_INFO value]
			n	 [integer!]
	][
		set-memory as byte-ptr! :info null-byte size? tagSYSTEM_INFO
		GetNativeSystemInfo :info
		n: info/dwNumberOfProcessors		;-- maximum number of threads
		either zero? n [1][n]
	]

	start: func [
		routine		[int-ptr!]		;-- thread-func!
		args		[int-ptr!]
		stack-size	[integer!]		;-- stack size in bytes. 0: default stack size
		return:		[handle!]
		/local
			handle [handle!]
	][
		handle: _beginthreadex null stack-size routine args 0 null
		either handle <> as handle! -1 [handle][null]
	]

	detach: func [
		thread	[handle!]
	][
		CloseHandle thread
	]

	kill: func [
		thread	[handle!]
		return: [logic!]
	][
		TerminateThread thread -1
	]

	stop: func [
		retcode [integer!]
	][
		_endthreadex retcode
	]

	wait: func [
		thread	[handle!]
		timeout [integer!]
		ret		[int-ptr!]
		return: [integer!]	;-- 1: success, 0: timeout, -1: error
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

	id?: func [
		"return current thread id"
		return: [integer!]
	][
		GetCurrentThreadId
	]

	yield: func [][
		"relinquish the CPU for a moment"
		SwitchToThread
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

	timespec!: alias struct! [
		sec    [integer!] ;Seconds
		nsec   [integer!] ;Nanoseconds
	]

	#either OS = 'macOS [
		#define LIBPTHREAD-file "libpthread.dylib"
	][
		#define LIBPTHREAD-file "libpthread.so.0"
	]

	#import [
		LIBC-file cdecl [
			sched_yield: "sched_yield" [
				return: [integer!]
			]
		]
		LIBPTHREAD-file cdecl [
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
			;#if OS = 'Linux [
			;pthread_timedjoin_np: "pthread_timedjoin_np" [
			;	thread		[int-ptr!]
			;	retval		[int-ptr!]
			;	abstime		[timespec!]
			;	return:		[integer!]
			;]]
			pthread_detach: "pthread_detach" [
				thread		[int-ptr!]
				return:		[integer!]
			]
			pthread_join: "pthread_join" [
				thread		[int-ptr!]
				retval		[int-ptr!]
				return:		[integer!]
			]
			pthread_exit: "pthread_exit" [
				retval		[integer!]
			]
			pthread_cancel: "pthread_cancel" [
				thread		[int-ptr!]
				return:		[integer!]
			]
			pthread_self: "pthread_self" [
				return:		[integer!]
			]
		]
	]

	start: func [
		routine [int-ptr!]
		args	[int-ptr!]
		stack	[integer!]
		return: [handle!]
		/local
			attr [pthread_attr_t value]
			a	 [pthread_attr_t]
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
			a: :attr
		][a: null]

		ret: pthread_create :t a routine args
		if stack > 0 [pthread_attr_destroy a]
		either zero? ret [as handle! t][probe "pthread_create fail" null]
	]

	detach: func [
		thread	[handle!]
	][
		pthread_detach thread
	]

	kill: func [
		thread	[handle!]
		return:	[logic!]
	][
		zero? pthread_cancel thread
	]

	stop: func [
		retcode [integer!]
	][
		pthread_exit retcode
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

	id?: func [
		"return current thread id"
		return: [integer!]
	][
		pthread_self
	]

	yield: func [][
		sched_yield
	]
]

]

threadpool: context [
	task!: alias struct! [
		handler		[int-ptr!]	;-- thread-func!
		data		[int-ptr!]	;-- user data
		status		[integer!]	;-- status of the task
	]

	worker!: alias struct! [
		running?	[logic!]
		idle-tm		[integer!]	;-- if a worker idle too long, exit it
		handle		[handle!]	;-- thread handle
	]

	tasks: as queue! 0
	workers: as ptr-ptr! 0
	n-worker: 0
	n-max: 0

	worker-func: func [
		#if OS <> 'Windows [[cdecl]]
		self	[worker!]
		/local
			task	[task!]
			handler	[thread-func!]
	][
		while [self/running?][
			task: as task! queue/pop tasks
			either task <> null [
				self/idle-tm: 0
				handler: as thread-func! task/handler
				handler task/data
			][
				self/idle-tm: self/idle-tm + 1
				OS-Sleep 1
			]
		]
	]
	
	init: func [][
		tasks: queue/create 2000
		n-max: -1 + thread/processor-count		;-- max count - 1
		workers: as ptr-ptr! allocate n-max * size? int-ptr!
	]

	add-worker: func [/local w [worker!] pp [ptr-ptr!]][
		w: as worker! allocate size? worker!
		w/running?: yes
		w/idle-tm: 0
		pp: (as ptr-ptr! workers) + n-worker
		pp/value: as int-ptr! w
		n-worker: n-worker + 1
		w/handle: thread/start as int-ptr! :worker-func as int-ptr! w 0
	]

	add-task: func [
		handler [int-ptr!]
		data	[int-ptr!]
		return: [logic!]
		/local
			task	[task!]
			res		[logic!]
	][
		task: as task! allocate size? task!
		task/handler: handler
		task/data: data
		res: queue/push tasks as int-ptr! task
		if all [
			n-worker < n-max
			2 < queue/size tasks
		][
			add-worker
		]
		res
	]

	wait: func [
		/local
			pp	[ptr-ptr!]
			w	[worker!]
			n	[integer!]
			ret [integer!]
			sz	[integer!]
	][
		until [
			n: 0
			sz: queue/size tasks
			while [n < n-worker][
				pp: (as ptr-ptr! workers) + n
				w: as worker! pp/value
				ret: 0
				thread/wait w/handle -1 :ret
				if sz <= (n-max * 2) [w/running?: no]
				n: n + 1
			]
			zero? queue/size tasks
		]
	]

	destroy: func [][]
]

comment {
func1: func [data [int-ptr!]][
	probe "1"
	OS-Sleep 10000
	probe "11"
]

func2: func [data [int-ptr!]][
	probe "2"
	OS-Sleep 10000
	probe "22"
]

func3: func [data [int-ptr!]][
	probe "3"
	OS-Sleep 10000
	probe "33"
]

funcN: func [data [int-ptr!]][
	probe data/value
	OS-Sleep 2000
	probe data/value * 2
]

test: func [
	/local
		n	[integer!]
		p	[int-ptr!]
][
	threadpool/init
	threadpool/add-task as int-ptr! :func1 null
	threadpool/add-task as int-ptr! :func2 null
	threadpool/add-task as int-ptr! :func3 null
	n: 3
	loop 100 [
		n: n + 1
		p: as int-ptr! allocate size? int-ptr!
		p/value: n
		threadpool/add-task as int-ptr! :funcN p
	]
	probe "waiting..."
	threadpool/wait
	probe "done"
]

test
}