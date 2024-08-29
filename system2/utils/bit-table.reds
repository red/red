Red/System [
	File: 	 %bit-table.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

bit-table!: alias struct! [
	rows		[integer!]
	cols		[integer!]
	width		[integer!]
	bits		[int-ptr!]
]
	
bit-table: context [
	make: func [
		rows	[integer!]
		cols	[integer!]
		return: [bit-table!]
		/local
			bt	[bit-table!]
	][
		bt: as bit-table! allocate size? bit-table!
		bt/rows: rows
		bt/cols: cols
		bt/width: cols + 31 >>> 5
		bt/bits: as int-ptr! zero-alloc rows * bt/width * 4
		bt
	]

	set: func [b [bit-table!] row [integer!] col [integer!] return: [logic!]
		/local p [int-ptr!] mask [integer!]
	][
		p: b/bits + (row * b/width + (col >>> 5))
		mask: 1 << col
		either p/value and mask = 0 [
			p/value: p/value or mask
			false
		][true]
	]

	clear: func [b [bit-table!] row [integer!] col [integer!] return: [logic!]
		/local p [int-ptr!] mask [integer!]
	][
		p: b/bits + (row * b/width + (col >>> 5))
		mask: 1 << col
		either p/value and mask <> 0 [
			p/value: p/value and (not mask)
			true
		][false]
	]

	pick: func [b [bit-table!] row [integer!] col [integer!] return: [logic!]
		/local i [integer!] p [int-ptr!]
	][
		i: row * b/width + (col >>> 5)
		p: b/bits + i
		p/value and (1 << col) <> 0
	]

	poke: func [
		b	[bit-table!]
		row [integer!]
		col [integer!]
		val [logic!]
		/local p [int-ptr!] mask v [integer!]
	][
		p: b/bits + (row * b/width + (col >>> 5))
		mask: 1 << col
		v: p/value
		either val [
			if v and mask = 0 [p/value: v or mask]
		][
			if v and mask <> 0 [p/value: v and (not mask)]
		]
	]

	grow: func [
		"grow this table to `rows` rows"
		b		[bit-table!]
		rows	[integer!]
	][
		if b/rows < rows [
			b/bits: as int-ptr! realloc as byte-ptr! b/bits rows * b/width * 4
			set-memory as byte-ptr! (b/bits + (b/rows * b/width)) null-byte (rows - b/rows) * b/width * 4
			b/rows: rows
		]
	]

	destroy: func [
		b	[bit-table!]
	][
		free as byte-ptr! b/bits
		free as byte-ptr! b
	]
]