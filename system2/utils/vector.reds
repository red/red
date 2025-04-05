Red/System [
	File: 	 %vector.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

vector!: alias struct! [
	obj-sz		[integer!]
	capacity	[integer!]
	length		[integer!]
	data		[byte-ptr!]
]

#define VECTOR_DATA(v) [as ptr-ptr! v/data]
#define VECTOR_SIZE?(v) [v/length]

vector: context [
	init: func [
		vec			[vector!]
		obj-sz		[integer!]
		capacity	[integer!]
	][
		if zero? capacity [capacity: 4]

		vec/obj-sz: obj-sz
		vec/capacity: capacity
		vec/length: 0
		vec/data: allocate capacity * obj-sz
	]

	make: func [
		obj-sz		[integer!]
		capacity	[integer!]
		return:		[vector!]
		/local
			vec		[vector!]
	][
		vec: as vector! allocate size? vector!
		init vec obj-sz capacity
		vec
	]

	copy: func [
		vec			[vector!]
		return:		[vector!]
		/local
			v		[vector!]
	][
		v: make vec/obj-sz vec/capacity
		v/length: vec/length
		copy-memory v/data vec/data vec/length * vec/obj-sz
		v
	]

	clear: func [
		vec		[vector!]
	][
		vec/length: 0
	]

	pick: func [
		vec		[vector!]
		idx		[integer!]
		return: [int-ptr!]
	][
		as int-ptr! vec/data + (idx * vec/obj-sz)
	]

	grow: func [
		vec		[vector!]
		new-sz	[integer!]
		/local
			new-cap		[integer!]
	][
		if new-sz <= vec/capacity [exit]

		new-cap: either vec/capacity < (4096 / vec/obj-sz) [
			vec/capacity << 1					;-- factor 2 for small vector
		][
			vec/capacity + (vec/capacity >> 1)	;-- factor 1.5 for larger
		]
		if new-sz > new-cap [new-cap: new-sz]

		vec/data: realloc vec/data new-cap * vec/obj-sz
		vec/capacity: new-cap
	]

	acquire: func [vec [vector!] n [integer!] return: [byte-ptr!] /local new len [integer!]][
		len: vec/length
		new: len + n
		if new > vec/capacity [
			grow vec new
		]

		vec/length: new
		vec/data + (len * vec/obj-sz)
	]

	new-item: func [vec [vector!] return: [int-ptr!] /local length [integer!]][
		length: vec/length + 1
		if length > vec/capacity [
			grow vec length
		]

		vec/length: length
		as int-ptr! (vec/data + (length - 1 * vec/obj-sz))
	]

	append-v: func [
		vec		[vector!]
		v		[vector!]
		/local
			p	[byte-ptr!]
	][
		p: acquire vec v/length
		copy-memory p v/data v/length * v/obj-sz
	]

	append-ptr: func [
		vec		[vector!]
		ptr		[byte-ptr!]
		/local
			p	[ptr-ptr!]
	][
		p: as ptr-ptr! new-item vec
		p/value: as int-ptr! ptr
	]

	append-int: func [
		vec		[vector!]
		int		[integer!]
		/local
			p	[int-ptr!]
	][
		p: new-item vec
		p/value: int
	]

	remove-last: func [
		vec		[vector!]
	][
		assert vec/length > 0
		vec/length: vec/length - 1
	]

	pick-last-int: func [
		vec		[vector!]
		return: [integer!]
		/local
			p	[int-ptr!]
	][
		p: (as int-ptr! vec/data) + vec/length - 1
		p/value
	]

	pick-ptr: func [
		vec		[vector!]
		idx		[integer!]
		return: [int-ptr!]
		/local
			p	[ptr-ptr!]
	][
		p: (as ptr-ptr! vec/data) + idx
		p/value
	]

	poke-ptr: func [
		vec		[vector!]
		idx		[integer!]
		val		[int-ptr!]
		/local
			p	[ptr-ptr!]
	][
		p: (as ptr-ptr! vec/data) + idx
		p/value: val
	]

	pop-last-ptr: func [
		vec		[vector!]
		return: [int-ptr!]
		/local
			p	[ptr-ptr!]
	][
		vec/length: vec/length - 1
		p: (as ptr-ptr! vec/data) + vec/length
		p/value
	]

	destroy: func [
		vec		[vector!]
	][
		free vec/data
		free as byte-ptr! vec
	]
]

ptr-vector: context [
	make: func [size [integer!] return: [vector!]][
		vector/make size? int-ptr! size
	]

	tail: func [
		vec		[vector!]
	][
		(as ptr-ptr! vec/data) + vec/length
	]
]