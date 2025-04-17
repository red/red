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
		mask: 1 << (col and 1Fh)
		either p/value and mask = 0 [
			p/value: p/value or mask
			false
		][true]
	]

	clear: func [b [bit-table!] row [integer!] col [integer!] return: [logic!]
		/local p [int-ptr!] mask [integer!]
	][
		p: b/bits + (row * b/width + (col >>> 5))
		mask: 1 << (col and 1Fh)
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
		col: col and 1Fh
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
		mask: 1 << (col and 1Fh)
		v: p/value
		either val [
			if v and mask = 0 [p/value: v or mask]
		][
			if v and mask <> 0 [p/value: v and (not mask)]
		]
	]

	grow-row: func [
		"grow this table to `rows` rows"
		b		[bit-table!]
		rows	[integer!]
		/local
			w	[integer!]
	][
		if b/rows < rows [
			w: b/width
			b/bits: as int-ptr! realloc as byte-ptr! b/bits rows * w * 4
			set-memory as byte-ptr! (b/bits + (b/rows * w)) null-byte (rows - b/rows) * w * 4
			b/rows: rows
		]
	]

	grow-column: func [
		b		[bit-table!]
		cols	[integer!]
		/local
			w	[integer!]
			bw	[integer!]
			i j [integer!]
			bits [int-ptr!]
			new	 [int-ptr!]
			rows [integer!]
			p pp [int-ptr!]
	][
		if cols <= b/cols [exit]
		w: cols + 31 >>> 5
		if w <= b/width [
			b/cols: cols
			exit
		]
		new: as int-ptr! zero-alloc b/rows * w * 4
		bits: b/bits
		rows: b/rows
		bw: b/width
		i: 0
		while [i < rows][
			p: new + (i * w)
			pp: bits + (i * bw)
			j: 0
			until [
				p/value: pp/value
				p: p + 1
				pp: pp + 1
				j: j + 1
				j = bw
			]
			i: i + 1
		]
		free as byte-ptr! bits
		b/width: w
		b/cols: cols
		b/bits: new
	]

	or-rows: func [
		"row a or row b into row a"
		b		[bit-table!]
		row-a	[integer!]
		row-b	[integer!]
		/local
			pa	[int-ptr!]
			pb	[int-ptr!]
			w	[integer!]
	][
		w: b/width
		pa: b/bits + (row-a * w)
		pb: b/bits + (row-b * w)
		loop w [
			pa/value: pa/value or pb/value
			pa: pa + 1
			pb: pb + 1
		]
	]

	and-rows: func [
		b		[bit-table!]
		row-a	[integer!]
		row-b	[integer!]
		/local
			pa	[int-ptr!]
			pb	[int-ptr!]
			w	[integer!]
	][
		w: b/width
		pa: b/bits + (row-a * w)
		pb: b/bits + (row-b * w)
		loop w [
			pa/value: pa/value and pb/value
			pa: pa + 1
			pb: pb + 1
		]
	]

	destroy: func [
		b	[bit-table!]
	][
		free as byte-ptr! b/bits
		free as byte-ptr! b
	]

	render-row: func [
		b	[bit-table!]
		row [integer!]
		/local
			i	[integer!]
			end [integer!]
			n	[integer!]
			p	[int-ptr!]
	][
		print [row ": "]
		i: row * b/width
		end: i + b/width
		while [i < end][
			p: b/bits + i
			n: p/value
			loop 32 [
				print n and 1
				n: n >> 1
			]
			prin " "
			i: i + 1
		]
		print lf
	]

	render: func [
		b	[bit-table!]
		/local
			i	[integer!]
	][
		i: 0
		while [i < b/rows][
			render-row b i
			i: i + 1
		]
	]
]