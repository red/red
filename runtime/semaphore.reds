Red/System [
	Title:	"Semaphore Implementation"
	Author: "Xie Qingtian"
	File: 	%semaphore.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

semaphore: context [

#case [
	OS = 'Windows [
		#define RED_MAX_SEMAPHORE		65536
		
		#import [
			"kernel32.dll" stdcall [
				CreateSemaphoreW: "CreateSemaphoreW" [
					lpSemaphoreAttributes	[int-ptr!]
					lInitialCount			[integer!]
					lMaximumCount			[integer!]
					lpName					[c-string!]
					return:					[handle!]
				]
				ReleaseSemaphore: "ReleaseSemaphore" [
					hSemaphore		[handle!]
					lReleaseCount	[integer!]
					lpPreviousCount	[int-ptr!]
					return:			[logic!]
				]
			]
		]

		semaphore!: alias struct! [
			sem		[handle!]
			value	[integer!]
		]

		init: func [
			value	[integer!]
			return: [handle!]
			/local
				s	[semaphore!]
				h	[handle!]
		][
			s: as semaphore! allocate size? semaphore!
			s/sem: CreateSemaphoreW null value RED_MAX_SEMAPHORE null
			assert (as-integer s/sem) > 0

			s/value: value
			as handle! s
		]

		exit: func [
			sem		[handle!]
			/local
				s	[semaphore!]
		][
			s: as semaphore! sem
			if sem <> null [
				CloseHandle s/sem
				free as byte-ptr! s
			]
		]

		post: func [
			sem		[handle!]
			post	[integer!]
			return: [logic!]
			/local
				s	 [semaphore!]
				prev [integer!]
		][
			s: as semaphore! sem
			atomic/add :s/value post

			prev: 0
			either all [
				not ReleaseSemaphore s/sem post :prev
				prev >= 0
			][
				atomic/subtract :s/value post
				false
			][
				atomic/set :s/value prev + post
				true
			]
		]

		get: func [
			sem		[handle!]
			return: [integer!]
		][
			atomic/get sem + 1
		]

		wait: func [
			sem		[handle!]
			timeout [integer!]
			return: [integer!]
			/local
				r	[integer!]
		][
			if timeout < 0 [timeout: -1]		;-- INFINITE
			r: WaitForSingleObject as handle! sem/value timeout
			case [
				r = WAIT_TIMEOUT	[0]
				r < WAIT_OBJECT_0	[-1]
				0 >= atomic/get sem + 1 [-1]
				true [
					atomic/decrement sem + 1
					1
				]
			]
		]
	]
	OS = 'macOS [
		init: func [
			value	[integer!]
			return: [handle!]
		][
			null
		]

		exit: func [
			sem		[handle!]
		][
		]

		post: func [
			sem		[handle!]
			post	[integer!]
			return: [logic!]
		][
			true
		]

		get: func [
			sem		[handle!]
			return: [integer!]
		][
			0
		]

		wait: func [
			sem		[handle!]
			timeout [integer!]
			return: [integer!]
			/local
				r	[integer!]
		][
			0
		]
	]
	true [				;-- Posix
		init: func [
			value	[integer!]
			return: [handle!]
		][
			null
		]

		exit: func [
			sem		[handle!]
		][
		]

		post: func [
			sem		[handle!]
			post	[integer!]
			return: [logic!]
		][
			true
		]

		get: func [
			sem		[handle!]
			return: [integer!]
		][
			0
		]

		wait: func [
			sem		[handle!]
			timeout [integer!]
			return: [integer!]
			/local
				r	[integer!]
		][
			0
		]
	]
]

]