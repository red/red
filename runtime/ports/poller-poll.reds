Red/System [
	Title:	"poll on Linux"
	Author: "Xie Qingtian"
	File: 	%poller.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

poll: context [

	init: func [
		return: [int-ptr!]
	][
		null
	]

	exit: func [
		ref		[int-ptr!]
	][
	]

	kill: func [][]

	add: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][
	]

	remove: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][
	]

	modify: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][

	]

	update: func [
		ref		[int-ptr!]
		sock	[integer!]
		events	[integer!]
		data	[int-ptr!]
	][
		
	]

	wait: func [
		ref			[int-ptr!]
		timeout		[integer!]
		return:		[integer!]
	][
		#if debug? = yes [print-line "poll/wait"]
		0
	]
]