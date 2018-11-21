Red/System [
	Title:	"Socket implementation on Windows"
	Author: "Xie Qingtian"
	File: 	%socket.reds
	Tabs: 	4
	Rights: "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

sockdata: context [

	data: as int-ptr! 0
	maxn: 0

	init: func [][
		maxn: 256
		data: as int-ptr! alloc0 maxn * size? int-ptr!
	]

	insert: func [
		sock	[integer!]
		priv	[int-ptr!]
		/local
			idx [integer!]
	][
		if null? data [init]
		idx: sock + 1
		if idx > maxn [
			maxn: idx + 256
			data: as int-ptr! realloc as byte-ptr! data maxn * size? int-ptr!
		]
		data/idx: as-integer priv
	]

	remove: func [
		sock	[integer!]
		/local
			idx	[integer!]
	][
		idx: sock + 1
		data/idx: 0
	]

	get: func [
		sock	[integer!]
		return: [int-ptr!]
		/local
			idx [integer!]
	][
		idx: sock + 1
		either idx > maxn [null][as int-ptr! data/idx]
	]

	destroy: func [][
		free as byte-ptr! data
		maxn: 0
	]
]