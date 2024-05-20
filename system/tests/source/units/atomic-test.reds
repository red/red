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

#define A_N_THREADS		100
#define A_N_ITERS		100000

#define COND_CC [#either OS = 'Windows [[stdcall]][[cdecl]]]

~~~start-file~~~ "atomic operations"

===start-group=== "atomic operations path"
	st!: alias struct! [
		a	[integer!]
		b	[integer!]
	]
	st: declare st!
	st/a: 0
	st/b: 1

	--test-- "atomic load path"
		test-load: func [s [st!]][
			--assert (system/atomic/load :s/b) = 1
		]
		test-load st

	--test-- "atomic store path"
		test-store: func [s [st!]][
			system/atomic/store :s/a 1
			--assert s/a = s/b
		]
		test-store st

===end-group===

===start-group=== "atomic operations with multi threads"
	run-parallel: func [
		op-func		[int-ptr!]
		/local
			threads [int-ptr!]
			n		[integer!]
	][
		threads: system/stack/allocate A_N_THREADS
		n: 1
		until [			;-- start some threads
			threads/n: as-integer thread/start op-func null 0
			n: n + 1
			n > A_N_THREADS
		]
		loop A_N_THREADS [
			thread/wait as int-ptr! threads/value -1 null
			threads: threads + 1
		]
	]

	run-parallel-n: func [
		op-func		[int-ptr!]
		n-threads	[integer!]		;-- number of threads
		return:		[logic!]
		/local
			threads [int-ptr!]
			n		[integer!]
			ret		[integer!]
	][
		threads: system/stack/allocate n-threads
		n: 1
		until [			;-- start some threads
			threads/n: as-integer thread/start op-func as int-ptr! n 0
			n: n + 1
			n > n-threads
		]
		loop n-threads [
			ret: 0
			thread/wait as int-ptr! threads/value -1 :ret
			unless as logic! ret [return false]
			threads: threads + 1
		]
		true
	]

	--test-- "atomic load and store"
		counter1: 0
		counter2: 0

		atomic-load-store: func [			;-- thread-func!
			COND_CC
			udata	[int-ptr!]
			return: [logic!]
			/local
				p1	[int-ptr!]
				p2	[int-ptr!]
				me	[integer!]
				n	[integer!]
				c1	[integer!]
				c2	[integer!]
		][
			p1: :counter1
			p2: :counter2
			me: as-integer udata
			loop A_N_ITERS [
				either me = 1 [
					c1: system/atomic/load p1
					n: c1 + 1
					;-- the following 2 store instructions should be sequential
					;-- no reordering
					system/atomic/store p1 n
					system/atomic/store p2 n
				][
					c2:  system/atomic/load p2
					c1:  system/atomic/load p1
					if c1 < c2 [return false]
				]
			]
			true
		]
		--assert run-parallel-n as int-ptr! :atomic-load-store 10

	--test-- "atomic add"
		g-a: 0	;-- global variable

		atomic-add-func: func [COND_CC udata [int-ptr!]][	;-- thread-func!
			loop A_N_ITERS [
				;g-a: g-a + 1		;-- this will fail
				system/atomic/add :g-a 1
			]
		]
		run-parallel as int-ptr! :atomic-add-func
		--assert A_N_THREADS * A_N_ITERS = g-a

	--test-- "atomic sub"
		g-a: A_N_THREADS * A_N_ITERS

		atomic-sub-func: func [COND_CC udata [int-ptr!]][	;-- thread-func!
			loop A_N_ITERS [
				system/atomic/sub :g-a 1
			]
		]
		run-parallel as int-ptr! :atomic-sub-func
		--assert 0 = g-a

	--test-- "atomic CAS"
		g-a: 0	;-- global variable

		;fail-increment: func [val [int-ptr!] /local old [integer!] new [integer!]][
		;	until [		;-- non-atomic compare and swap
		;		old: val/value
		;		new: old + 1
		;		either old = val/value [
		;			val/value: new
		;			true
		;		][
		;			false
		;		]
		;	]
		;]
		cas-increment: func [val [int-ptr!] /local old [integer!] new [integer!]][
			until [
				old: system/atomic/load val
				new: old + 1
				system/atomic/cas val old new
			]
		]
		atomic-cas-increment: func [COND_CC udata [int-ptr!]][	;-- thread-func!
			;loop A_N_ITERS [fail-increment :g-a]		;-- this wil fail
			loop A_N_ITERS [cas-increment :g-a]
		]
		run-parallel as int-ptr! :atomic-cas-increment
		--assert A_N_THREADS * A_N_ITERS = g-a		

	run-parallel-2: func [
		op-func		[int-ptr!]
		init-value	[integer!]
		return:		[integer!]
		/local
			threads [int-ptr!]
			n		[integer!]
			a		[integer!]
	][
		a: init-value
		threads: system/stack/allocate A_N_THREADS
		n: 1
		until [			;-- start some threads
			threads/n: as-integer thread/start op-func :a 0
			n: n + 1
			n > A_N_THREADS
		]
		loop A_N_THREADS [
			thread/wait as int-ptr! threads/value -1 null
			threads: threads + 1
		]
		a
	]

	--test-- "atomic add 2"
		atomic-add-func2: func [COND_CC udata [int-ptr!]][	;-- thread-func!
			loop A_N_ITERS [
				system/atomic/add udata 1
			]
		]
		--assert A_N_THREADS * A_N_ITERS = run-parallel-2 as int-ptr! :atomic-add-func2 0

	--test-- "atomic sub 2"
		atomic-sub-func2: func [COND_CC udata [int-ptr!]][	;-- thread-func!
			loop A_N_ITERS [
				system/atomic/sub udata 1
			]
		]
		--assert 0 = run-parallel-2 as int-ptr! :atomic-sub-func2 A_N_THREADS * A_N_ITERS

===end-group===

~~~end-file~~~

][

~~~start-file~~~ "Queue Test"

===start-group=== "Queue Basic"
===end-group===

~~~end-file~~~

]