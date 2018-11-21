Red/System [
	Title:	"Thread Pool Implementation"
	Author: "Xie Qingtian"
	File: 	%threadpool.reds
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
	ref		[integer!]			;-- the reference count, must be <= 2
	state	[integer!]
	entry	[list-entry!]
]

thread-worker!: alias struct! [
	id		[integer!]
	pool	[int-ptr!]
	do		[int-ptr!]
	tasks	[int-ptr!]
	pull	[integer!]
	stopped [integer!]
]

thread-pool!: alias struct! [
	stack-sz		[integer!]
	worker-maxn		[integer!]
	lock			[integer!]
	task-urgent		[list!]
	task-waiting 	[list!]
	task-pending	[list!]
	stopped?		[logic!]
	semaphore		[int-ptr!]
	worker-cnt		[integer!]
	workers			[int-ptr!]
]

threadpool: context [
	create: func [
		size	[integer!]
		stack	[integer!]
		return: [handle!]
	][
		
	]

]