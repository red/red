Red/System [
	File: 	 %array.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define ARRAY_DATA(arr) (as ptr-ptr! (arr + 1))
#define array-value! [array-1! value]
#define INIT_ARRAY_VALUE(a v) [a/length: 1 a/val-1: as byte-ptr! v]
#define INIT_ARRAY_2(a v1 v2) [a/length: 2 a/val-1: as byte-ptr! v1 a/val-2: as byte-ptr! v2]

rs-array!: alias struct! [
	length	[integer!]
	;--data
]

#define int-array! rs-array!
#define ptr-array! rs-array!

array-1!: alias struct! [		;-- ptr array with one value
	length	[integer!]
	val-1	[byte-ptr!]
]

array-2!: alias struct! [		;-- ptr array with two values
	length	[integer!]
	val-1	[byte-ptr!]
	val-2	[byte-ptr!]
]

empty-array: as ptr-array! 0

int-array: context [
	make: func [
		size	[integer!]
		return: [rs-array!]
		/local
			a	[rs-array!]
	][
		a: as rs-array! malloc (size * size? integer!) + size? rs-array!
		a/length: size
		a
	]

	pick: func [
		arr		[int-array!]
		i		[integer!]	;-- zero-based index
		return: [integer!]
		/local
			p	[int-ptr!]
	][
		p: as int-ptr! ARRAY_DATA(arr)
		p: p + i
		p/value
	]

	poke: func [
		arr		[int-array!]
		i		[integer!]
		val		[integer!]
		/local
			p	[int-ptr!]
	][
		p: as int-ptr! ARRAY_DATA(arr)
		p: p + i
		p/value: val
	]
]

ptr-array: context [
	make: func [
		size	[integer!]
		return: [ptr-array!]
		/local
			a	[ptr-array!]
	][
		a: as ptr-array! malloc (size * size? int-ptr!) + size? ptr-array!
		a/length: size
		a
	]

	copy-n: func [
		arr		[ptr-array!]
		n		[integer!]
		return: [ptr-array!]
		/local
			new [ptr-array!]
	][
		assert n <= arr/length
		new: make n
		copy-memory as byte-ptr! ARRAY_DATA(new) as byte-ptr! ARRAY_DATA(arr) n * size? int-ptr!
		new
	]

	copy: func [
		arr		[ptr-array!]
		return: [ptr-array!]
		/local
			new [ptr-array!]
	][
		new: make arr/length
		copy-memory as byte-ptr! ARRAY_DATA(new) as byte-ptr! ARRAY_DATA(arr) arr/length * size? int-ptr!
		new
	]

	grow: func [
		arr		[ptr-array!]
		length	[integer!]
		return: [ptr-array!]
		/local
			a	[ptr-array!]
	][
		either length > arr/length [
			a: make length
			copy-memory as byte-ptr! ARRAY_DATA(a) as byte-ptr! ARRAY_DATA(arr) arr/length * size? int-ptr!
			a
		][
			arr
		]
	]

	append: func [
		arr		[ptr-array!]
		ptr		[byte-ptr!]
		return: [ptr-array!]
		/local
			a	[ptr-array!]
			len [integer!]
			p	[ptr-ptr!]
			pp	[ptr-ptr!]
	][
		len: arr/length
		a: make len + 1
		p: ARRAY_DATA(a)
		pp: ARRAY_DATA(arr)
		loop len [
			p/value: pp/value
			p: p + 1
			pp: pp + 1
		]
		p/value: as int-ptr! ptr
		a
	]

	pick: func [
		arr		[ptr-array!]
		i		[integer!]	;-- zero-based index
		return: [int-ptr!]
		/local
			p	[ptr-ptr!]
	][
		p: ARRAY_DATA(arr) + i
		p/value
	]

	poke: func [
		arr		[ptr-array!]
		i		[integer!]
		val		[int-ptr!]
		/local
			p	[ptr-ptr!]
	][
		p: ARRAY_DATA(arr) + i
		p/value: val
	]
]

dyn-array!: alias struct! [
	length		[integer!]
	data		[ptr-array!]
]

dyn-array: context [
	init: func [
		arr		[dyn-array!]
		size	[integer!]
		return: [dyn-array!]
	][
		arr/length: 0
		arr/data: ptr-array/make size
		arr
	]

	make: func [
		size	[integer!]
		return: [dyn-array!]
	][
		init as dyn-array! malloc size? dyn-array! size
	]

	clear: func [
		arr		[dyn-array!]
	][
		arr/length: 0
	]

	grow: func [
		arr		[dyn-array!]
		new-sz	[integer!]
		/local
			new-cap [integer!]
	][
		if new-sz <= arr/data/length [exit]

		new-cap: arr/data/length << 1
		if new-sz > new-cap [new-cap: new-sz]

		arr/data: ptr-array/grow arr/data new-cap
	]

	append: func [
		arr		[dyn-array!]
		ptr		[int-ptr!]
		/local
			p	[ptr-ptr!]
			len [integer!]
	][
		len: arr/length + 1
		if len > arr/data/length [
			grow arr len
		]

		arr/length: len
		p: ARRAY_DATA(arr/data) + (len - 1)
		p/value: ptr
	]

	append-n: func [
		"append N values"
		arr		[dyn-array!]
		parr	[ptr-array!]
		/local
			n	[integer!]
			p	[ptr-ptr!]
			pp	[ptr-ptr!]
	][
		n: arr/length + parr/length
		if n > arr/data/length [
			grow arr n
		]

		p: ARRAY_DATA(arr/data) + arr/length
		pp: ARRAY_DATA(parr)
		loop parr/length [
			p/value: pp/value
			p: p + 1
			pp: pp + 1
		]
		arr/length: n
	]

	to-array: func [
		arr		[dyn-array!]
		return: [ptr-array!]
	][
		ptr-array/copy-n arr/data arr/length
	]
]