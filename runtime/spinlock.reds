Red/System [
	Title:	"Spin-Lock Implementation"
	Author: "Xie Qingtian"
	File: 	%spinlock.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

spinlock: context [
	init: func [lock [int-ptr!]][
		lock/value: 0
	]

	exit: func [lock [int-ptr!]][
		lock/value: 0
	]

	enter: func [
		lock	[int-ptr!]
		/local
			n	[integer!]
	][
		n: 6
		while [0 < atomic/compare-exchange lock 0 1][
			n: n - 1
			if zero? n [
				cpu/yield
				n: 6
			]
		]
	]

	try-enter: func [
		lock	[int-ptr!]
		return: [logic!]
	][
		zero? atomic/compare-exchange lock 0 1
	]

	leave: func [
		lock	[int-ptr!]
	][
		lock/value: 0
	]
]