Red/System [
	File: 	 %optimizer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

instr-matcher!: alias struct! [
	x			[instr!]
	y			[instr!]
	long-int?	[logic!]
	x-const?	[logic!]
	y-const?	[logic!]
	fold?		[logic!]
	y-zero?		[logic!]
	int-x		[integer!]
	int-y		[integer!]
	type		[int-type!]
]

matcher: context [
	make: func [
		return: [instr-matcher!]
	][
		xmalloc(instr-matcher!)
	]

	bin-op: func [
		m		[instr-matcher!]
		i		[instr!]
		return: [instr!]
		/local
			ex	[df-edge!]
			ey	[df-edge!]
			t	[instr!]
			x	[instr!]
			y	[instr!]
			ret [instr!]
			p	[ptr-ptr!]
	][
		p: ARRAY_DATA(i/inputs)
		ex: as df-edge! p/value
		x: ex/dst
		p: p + 1
		ey: as df-edge! p/value
		y: ey/dst
		m/y-zero?: INSTR_FLAGS(y) and F_ZERO <> 0
		m/x-const?: INSTR_CONST?(x)
		m/y-const?: INSTR_CONST?(y)
		either m/x-const? [
			case [
				m/y-const? [
					m/fold?: yes
					ret: y
				]
				INSTR_FLAGS(i) and F_COMMUTATIVE <> 0 [
					update-uses ex y
					update-uses ey x
					m/x-const?: no
					m/y-const?: yes
					t: x
					x: y
					y: t
					m/y-zero?: INSTR_FLAGS(y) and F_ZERO <> 0
					ret: y
				]
				true [ret: null]
			]
		][
			ret: either m/y-const? [y][null]
		]
		m/x: x
		m/y: y
		ret
	]

	int-bin-op: func [
		m		[instr-matcher!]
		i		[instr!]
		return: [integer!]
		/local
			p	[ptr-ptr!]
			op	[instr-op!]
			t	[int-type!]
			c	[instr-const!]
			int [red-integer!]
	][
		bin-op m i
		op: as instr-op! i
		p: op/param-types
		t: as int-type! p/value
		either INT_WIDTH(t) <= 32 [
			m/long-int?: no
			if m/x-const? [
				c: as instr-const! m/x
				int: as red-integer! c/value
				m/int-x: int/value
			]
			if m/y-const? [
				c: as instr-const! m/y
				int: as red-integer! c/value
				m/int-y: int/value
			]
		][
			m/long-int?: yes
		]
		m/int-y
	]
]