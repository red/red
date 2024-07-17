Red/System [
	File: 	 %vector.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

vector!: alias struct! [
	obj-sz		[integer!]
	capacity	[integer!]
	used		[integer!]
	data		[byte-ptr!]
]

vector: context [
	init: func [
		vec			[vector!]
		obj-sz		[integer!]
		capacity	[integer!]
	][
		if zero? capacity [capacity: 4]

		vec/obj-sz: obj-sz
		vec/capacity: capacity
		vec/used: 0
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

	new-item: func [vec [vector!] return: [int-ptr!] /local used [integer!]][
		used: vec/used + 1
		if used > vec/capacity [
			grow vec used
		]

		vec/used: used
		as int-ptr! (vec/data + (used - 1 * vec/obj-sz))
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
]