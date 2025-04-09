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

ssa-optimizer: context [
	block-state!: alias struct! [
		inits			[list!]
		non-null		[list!]
		pure-loads		[vector!]
		impure-loads	[vector!]
		ptr-loads		[vector!]
		end?			[logic!]
	]

	state!: alias struct! [
		block	[basic-block!]
		state	[block-state!]
	]

	optimizer!: alias struct! [
		ctx		[ssa-ctx!]
		graph	[ir-fn!]
		mark	[integer!]
		matcher	[instr-matcher!]
		prev-i	[instr!]
		next-i	[instr!]
		state	[block-state!]
	]

	make-block-state: func [return: [block-state!] /local s [block-state!]][
		s: xmalloc(block-state!)
		s/pure-loads: vector/make 4 1 
		s/impure-loads: vector/make 4 1
		s/ptr-loads: vector/make 4 1
		s
	]

	clear-block-state: func [
		s			[block-state!]
		return:		[block-state!]
	][
		s/inits: null
		s/non-null: null
		s/end?: false
		vector/clear s/pure-loads
		vector/clear s/impure-loads
		vector/clear s/ptr-loads
		s
	]

	copy-block-state: func [
		s			[block-state!]
		return:		[block-state!]
		/local
			new		[block-state!]
	][
		new: xmalloc(block-state!)
		new/inits: s/inits
		new/non-null: s/non-null
		new/end?: s/end?
		new/pure-loads: vector/copy s/pure-loads
		new/impure-loads: vector/copy s/impure-loads
		new/ptr-loads: vector/copy s/ptr-loads
		new
	]

	reset-mark: func [
		opt			[optimizer!]
		/local
			f		[ir-fn!]
	][
		f: opt/graph
		opt/mark: either null? f [-1][
			f/mark: f/mark + 1
			f/mark
		]
	]

	make-mark: func [
		opt			[optimizer!]
		blk			[basic-block!]
		return:		[integer!]
		/local
			m		[integer!]
	][
		m: opt/graph/mark
		blk/mark: m
		opt/graph/mark: m + 1
		m - opt/mark
	]

	set-mark: func [
		opt			[optimizer!]
		blk			[basic-block!]
		mark		[integer!]
		/local
			m		[integer!]
	][
		m: opt/mark + mark
		blk/mark: m
		m: m + 1
		if m > opt/graph/mark [opt/graph/mark: m]
	]

	get-mark: func [
		opt			[optimizer!]
		blk			[basic-block!]
		return:		[integer!]
	][
		either blk/mark < opt/mark [-1][
			blk/mark - opt/mark
		]
	]

	reduce-op: func [
		opt			[optimizer!]
		i			[instr!]
		return:		[instr!]
	][
		switch INSTR_OPCODE(i) [
			OP_INT_EQ [0]
			default [0]
		]
		i
	]

	reduce-if: func [
		opt			[optimizer!]
		i			[instr!]
		return:		[instr!]
		/local
			cond	[instr!]
	][
		cond: input0 i
		i
	]

	reduce-phi: func [
		opt			[optimizer!]
		i			[instr!]
		return:		[instr!]
		/local
			same-i?	[logic!]
			p		[ptr-ptr!]
			e		[df-edge!]
			flags	[integer!]
			len n	[integer!]
			i1 i2 i3 [instr!]
	][
		flags: 0
		n: 0
		i1: input0 i
		if i1 <> null [
			n: n + 1
			i3: i1
			flags: INSTR_FLAGS(i1)
		]
		same-i?: true
		p: ARRAY_DATA(i/inputs) + 1
		len: i/inputs/length - 1
		loop len [
			e: as df-edge! p/value
			i2: e/dst
			if i2 <> null [
				n: n + 1
				i3: i2
				flags: INSTR_FLAGS(i2) and flags
			]
			if i2 <> i1 [same-i?: false]
			p: p + 1
		]
		assert n > 0
		if same-i? [
			replace-instr i i1
			return i1
		]
		if n = 1 [
			replace-instr i i3
			return i3
		]
		ADD_INS_FLAGS(i flags)
		i
	]

	reduce-instr: func [
		opt			[optimizer!]
		i			[instr!]
		return:		[instr!]
		/local
			ii		[instr!]
	][
		opt/prev-i: i/prev
		either INSTR_OP?(i) [
			ii: reduce-op opt i
			if ii <> i [
				replace-instr i ii
				remove-instr i
			]
			return ii
		][
			i: switch INSTR_OPCODE(i) [
				INS_PHI		[reduce-phi opt i]
				INS_IF		[reduce-if opt i]
				INS_GOTO	[i]
				INS_SWITCH	[i]
				default		[i]
			]
		]
		i
	]

	reduce-block: func [
		opt			[optimizer!]
		blk			[basic-block!]
		/local
			i		[instr!]
			next	[instr!]
			s		[block-state!]
	][
		s: opt/state
		opt/ctx/block: blk
		i: blk/next
		while [i <> blk][
			next: i/next
			reduce-instr opt i
			if s/end? [break]
			i: next
		]
	]

	run: func [
		ctx			[ssa-ctx!]
		/local
			graph	[ir-fn!]
			opt		[optimizer!]
			queue	[vector!]
			s		[state!]
			mark i	[integer!]
			blk b	[basic-block!]
			bstate	[block-state!]
			succs	[ptr-array!]
			preds	[ptr-array!]
			e		[cf-edge!]
			pp		[ptr-ptr!]
	][
		graph: ctx/graph
		opt: xmalloc(optimizer!)
		opt/ctx: ctx
		opt/graph: graph
		opt/matcher: matcher/make
		reset-mark opt

		queue: vector/make size? state! 10
		s: as state! vector/new-item queue
		s/block: graph/start-bb
		s/state: make-block-state

		mark: make-mark opt graph/start-bb
		i: 0
		while [i < queue/length][
			s: as state! vector/pick queue i
			blk: s/block
			bstate: s/state
			opt/state: bstate
			if INSTR_ALIVE?(blk) [
				reduce-block opt blk
				succs: block-successors blk
				if succs <> null [
					pp: ARRAY_DATA(succs)
					loop succs/length [
						e: as cf-edge! pp/value
						b: e/dst
						if 0 > get-mark opt b [
							preds: b/preds
							bstate: either succs/length = 1 [
								either preds/length = 1 [opt/state][
									clear-block-state opt/state
								]
							][
								either preds/length = 1 [copy-block-state opt/state][
									make-block-state
								]
							]
							s: as state! vector/new-item queue
							s/block: b
							s/state: bstate
							set-mark opt b mark
						]
						pp: pp + 1
					]
				]
			]
			i: i + 1
		]
		prune-graph opt
	]

	prune-graph: func [
		opt		[optimizer!]
	][
		0
	]
]