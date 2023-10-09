Red/System [
	Title:		"Red/System atomic operations test script"
	Author:		"Xie Qingtian"
	File:		%atomic-test.reds
	Tabs:		4
	Rights:		"Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License:	"BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

#either cpu-version > 5.0 [

#define handle! int-ptr!

#include %../../../../runtime/threads.reds
#include %../../../../runtime/queue.reds

#define A_N_THREADS		100
#define A_N_ITERS		100000
#define A_QE_SIZE		8192

#define COND_CC [#either OS = 'Windows [[stdcall]][[cdecl]]]

~~~start-file~~~ "Queue Test"

===start-group=== "Queue Basic"

	--test-- "queue test 1"
		producer-func: func [
			COND_CC
			qe		[queue!]
			return:	[integer!]
		][
			loop A_N_ITERS [
				while [not queue/push qe as int-ptr! 1][
					thread/yield
				]
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
				while [
					ret: as-integer queue/pop qe
					zero? ret
				][thread/yield]
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
			qe: queue/create A_QE_SIZE
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
				while [not queue/s-push qe as int-ptr! 1][
					thread/yield
				]
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
			qe: queue/create A_QE_SIZE
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

	--test-- "queue test 3 - single consumer"
		s-consumer-func: func [
			COND_CC
			qe		[queue!]
			return:	[integer!]
			/local
				n	[integer!]
				ret [integer!]
				val [integer!]
		][
			ret: 1
			loop 31 [
				n: 0
				loop A_N_ITERS [
					while [
						val: as-integer queue/s-pop qe
						zero? val
					][thread/yield]
					n: n + val
				]
				if n <> A_N_ITERS [ret: 0]
			]
			ret
		]

		run-queue-test-3: func [
			/local
				threads [int-ptr!]
				n		[integer!]
				ret		[integer!]
				qe		[queue!]
		][
			qe: queue/create A_QE_SIZE
			threads: system/stack/allocate 32

			;-- start consumer thread
			threads/1: as-integer thread/start as int-ptr! :s-consumer-func as int-ptr! qe 0

			n: 2
			until [			;-- start producer threads
				threads/n: as-integer thread/start as int-ptr! :producer-func as int-ptr! qe 0
				n: n + 1
				n = 33
			]

			ret: 0
			thread/wait as int-ptr! threads/1 -1 :ret

			--assert ret = 1
		]

		run-queue-test-3

===end-group===

~~~end-file~~~

][

~~~start-file~~~ "Queue Test"

===start-group=== "Queue Basic"
===end-group===

~~~end-file~~~

]