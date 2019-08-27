Red/System [
	Title:		"Red/System atomic operations test script"
	Author:		"Xie Qingtian"
	File:		%atomic-test.reds
	Tabs:		4
	Rights:		"Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License:	"BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#define handle! int-ptr!

#include %../../../../quick-test/quick-test.reds
#include %../../../../runtime/threads.reds
#include %../../../../runtime/queue.reds

#define A_N_THREADS		100
#define A_N_ITERS		100000

#define COND_CC [#if OS <> 'Windows [[cdecl]]]

~~~start-file~~~ "Queue Test"

===start-group=== "Queue Basic"

	--test-- "queue test 1"
		producer-func: func [
			COND_CC
			qe		[queue!]
			return:	[integer!]
		][
			loop A_N_ITERS [
				until [queue/push qe as int-ptr! 1]
			]
			0
		]
		consumer-func: func [
			COND_CC
			qe		[queue!]
			return: [integer!]
			/local
				n	[integer!]
				ret [integer!]
		][
			n: 0
			loop A_N_ITERS [
				until [
					ret: as-integer queue/pop qe
					ret <> 0
				]
				n: n + ret
			]
			n
		]

		run-queue-test: func [
			/local
				threads [int-ptr!]
				n		[integer!]
				ret		[integer!]
				qe		[queue!]
		][
			qe: queue/create 1024 * 8
			threads: system/stack/allocate 64
			n: 1
			until [			;-- start producer and consumer threads
				threads/n: as-integer thread/start as int-ptr! :producer-func as int-ptr! qe 0
				n: n + 1
				threads/n: as-integer thread/start as int-ptr! :consumer-func as int-ptr! qe 0
				n: n + 1
				n = 65
			]
			n: 1
			until [
				ret: 0
				thread/wait as int-ptr! threads/n -1 :ret
				if n % 2 = 0 [--assert ret = A_N_ITERS]
				n: n + 1
				n = 65
			]
		]

		run-queue-test

	--test-- "queue test 2 - single producer"
		s-producer-func: func [
			COND_CC
			qe		[queue!]
			return:	[integer!]
		][
			loop A_N_ITERS * 31 [
				until [queue/s-push qe as int-ptr! 1]
			]
			0
		]

		run-queue-test-2: func [
			/local
				threads [int-ptr!]
				n		[integer!]
				ret		[integer!]
				qe		[queue!]
		][
			qe: queue/create 1024 * 8
			threads: system/stack/allocate 32
			n: 1
			until [			;-- start consumer threads
				threads/n: as-integer thread/start as int-ptr! :consumer-func as int-ptr! qe 0
				n: n + 1
				n = 32
			]
			;-- start producer threads
			threads/n: as-integer thread/start as int-ptr! :s-producer-func as int-ptr! qe 0

			until [
				ret: 0
				thread/wait as int-ptr! threads/n -1 :ret
				if n <> 32 [--assert ret = A_N_ITERS]
				n: n - 1
				zero? n
			]
		]

		run-queue-test-2

===end-group===

~~~end-file~~~
