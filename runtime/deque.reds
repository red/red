Red/System [
	Title:	"A double-ended queue implementation"
	Author: "Xie Qingtian"
	File: 	%deque.reds
	Tabs:	4
	Rights: "Copyright (C) 2018 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define RED_DEQUE_VALUE_T	int-ptr!		;-- value type

deque!: alias struct! [
	capacity	[integer!]		;-- size of the data array
	offset		[integer!]		;-- offset to the first element in data
	size		[integer!]		;-- used size in data array
	data		[int-ptr!]
]

deque: context [

	create: func [
		len			[integer!]
		return:		[deque!]
		/local
			q		[deque!]
	][
		if len < 4 [len: 4]
		len: 1 << (1 + log-b len)			;-- rounding up to next power of 2

		q: as deque! allocate size? deque!
		q/capacity: len
		q/size: 0
		q/offset: 0
		q/data: as int-ptr! allocate len * size? RED_DEQUE_VALUE_T
		q
	]

	destroy: func [
		queue	[deque!]
	][
		free as byte-ptr! queue/data
		free as byte-ptr! queue
	]

	push: func [
		queue	[deque!]
		value	[int-ptr!]
		/local
			idx	[integer!]
	][
		if queue/capacity = queue/size [
			make-space queue 1
		]
		idx: queue/offset + queue/size and (queue/capacity - 1) + 1
		queue/data/idx: as-integer value
		queue/size: queue/size + 1
		probe ["queue/push: " queue/size]
	]

	pop: func [
		queue	[deque!]
		return: [RED_DEQUE_VALUE_T]
		/local
			idx	[integer!]
	][
		assert queue/size > 0
		idx: queue/offset + queue/size - 1 and (queue/capacity - 1) + 1
		queue/size: queue/size - 1
		as RED_DEQUE_VALUE_T queue/data/idx
	]

	insert: func [
		queue	[deque!]
		value	[int-ptr!]
		/local
			idx	[integer!]
			cap	[integer!]
	][
		if queue/capacity = queue/size [
			make-space queue 1
		]
		cap: queue/capacity - 1
		idx: queue/offset + cap and cap
		queue/offset: idx
		idx: idx + 1
		queue/data/idx: as-integer value
		queue/size: queue/size + 1
	]

	take: func [
		queue	[deque!]
		return: [RED_DEQUE_VALUE_T]
		/local
			idx	[integer!]
	][
		assert queue/size > 0
		idx: queue/offset + 1
		queue/offset: idx and (queue/capacity - 1)
		queue/size: queue/size - 1
		probe ["queue/take: " queue/size]
		as RED_DEQUE_VALUE_T queue/data/idx
	]

	pick: func [
		queue	[deque!]
		idx		[integer!]			;-- 1-based
		return: [RED_DEQUE_VALUE_T]
	][
		idx: queue/offset + idx - 1 and (queue/capacity - 1) + 1
		as RED_DEQUE_VALUE_T queue/data/idx
	]

	poke: func [
		queue	[deque!]
		idx		[integer!]			;-- 1-based
		value	[RED_DEQUE_VALUE_T]
	][
		idx: queue/offset + idx - 1 and (queue/capacity - 1) + 1
		queue/data/idx: as-integer value
	]

	empty?: func [
		queue	[deque!]
		return: [logic!]
	][
		zero? queue/size
	]
	
	make-space: func [
		queue	[deque!]
		len		[integer!]
		/local
			cap		[integer!]
			old-cap	[integer!]
			n		[integer!]
	][
		old-cap: queue/capacity
		cap: old-cap
		until [
			cap: cap << 1
			cap > (queue/size + len)
		]
		queue/capacity: cap
		queue/data: as int-ptr! realloc as byte-ptr! queue/data cap * size? RED_DEQUE_VALUE_T

		if queue/offset + queue/size > old-cap [
			n: queue/offset + queue/size and (old-cap - 1)
			copy-memory
				as byte-ptr! queue/data + old-cap
				as byte-ptr! queue/data
				n * size? RED_DEQUE_VALUE_T
		]
	]
]