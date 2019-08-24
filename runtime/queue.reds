Red/System [
	Title:	"A FIFO Multi-Producer Multi-Consumer (MPMC) Queue"
	Author: "Xie Qingtian"
	File: 	%queue.reds
	Tabs:	4
	Rights: "Copyright (C) 2019 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

cacheLinePad!: alias struct! [		;-- 64 bytes
	float1			[float!]
	float2			[float!]
	float3			[float!]
	float4			[float!]
	float5			[float!]
	float6			[float!]
	float7			[float!]
	float8			[float!]
]

qnode!: alias struct! [
	value	[int-ptr!]
	status	[integer!]
]

queue!: alias struct! [
	capacity		[integer!]		;-- size of the data array
	capacityMask	[integer!]
	data			[qnode!]		;-- offset to the first element in data
	pad1			[cacheLinePad! value]
	tail			[integer!]
	pad2			[cacheLinePad! value]
	head			[integer!]
]

queue: context [

	create: func [
		len			[integer!]
		return:		[queue!]
		/local
			q		[queue!]
			ptr		[qnode!]
			i		[integer!]
	][
		if len < 4 [len: 4]
		len: 1 << (1 + log-b len)			;-- rounding up to next power of 2

		q: as queue! allocate size? queue!
		q/capacity: len
		q/capacityMask: len - 1
		q/tail: 0
		q/head: 0
		ptr: as qnode! allocate len * size? qnode!
		q/data: ptr
		i: 0
		loop len [
			ptr/status: i
			ptr: ptr + 1
			i: i + 1
		]
		q
	]

	destroy: func [
		qe	[queue!]
	][
		free as byte-ptr! qe/data
		free as byte-ptr! qe
	]

	push: func [
		qe			[queue!]
		val			[int-ptr!]
		return:		[logic!]
		/local
			node	[qnode!]
			next	[integer!]
			tail	[integer!]
	][
		until [
			next: system/atomic/load :qe/tail
			tail: next
			node: qe/data + tail
			if (system/atomic/load :node/status) <> tail [return false] ;-- queue is full
			system/atomic/cas :qe/tail tail tail + 1 and qe/capacityMask
		]
		node/value: val
		system/atomic/store :node/status not tail
		true
	]

	pop: func [
		qe			[queue!]
		return: 	[int-ptr!]
		/local
			node	[qnode!]
			head	[integer!]
			next	[integer!]
	][
		until [
			next: system/atomic/load :qe/head
			head: next
			node: qe/data + head
			if (system/atomic/load :node/status) = head [return null] ;-- queue is empty
			system/atomic/cas :qe/head head head + 1 and qe/capacityMask
		]
		system/atomic/store :node/status head
		node/value
	]

	s-push: func [
		"single producer push, no lock is needed"
		qe			[queue!]
		val			[int-ptr!]
		/local
			tail	[integer!]
			node	[qnode!]
	][
		if qe/capacity = qe/size [		;-- full, expand it
			make-space qe 1
		]
		tail: qe/tail
		qe/tail: tail + 1 and qe/capacityMask
		node: qe/data + tail
		node/value: val
		node/status: not tail
	]

	empty?: func [
		qe			[queue!]
		return: 	[logic!]
		/local
			tail	[integer!]
	][
		tail: system/atomic/load :qe/tail
		qe/head = tail
	]

	size: func [
		qe			[queue!]
		return: 	[integer!]
		/local
			tail	[integer!]
			head	[integer!]
	][
		tail: system/atomic/load :qe/tail
		head: system/atomic/load :qe/head
		if tail < head [tail: tail + qe/capacityMask]
		tail - head
	]

	make-space: func [
		queue	[queue!]
		len		[integer!]
		/local
			cap		[integer!]
			old-cap	[integer!]
			n		[integer!]
			ptr		[qnode!]
	][
		old-cap: qe/capacity
		cap: old-cap
		until [
			cap: cap << 1
			cap > (size + len)
		]
		qe/capacity: cap
		qe/data: as int-ptr! realloc as byte-ptr! qe/data cap * size? qnode!
		ptr: qe/data + old-cap
		while [old-cap < cap][
			ptr/status: old-cap
			ptr: ptr + 1
			old-cap: old-cap + 1
		]
	]
]