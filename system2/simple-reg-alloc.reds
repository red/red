Red/System [
	File: 	 %simple-reg-alloc.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define V_LIVE		 0
#define V_ON_STACK	-1
#define V_IN_CYCLE	-2
#define V_DEAD		-3

vreg-reg!: alias struct! [
	vreg		[vreg!]
	reg			[integer!]
]

move-state!: alias struct! [
	vreg		[vreg!]
	src			[integer!]
	dst			[integer!]
	state		[integer!]
]

reg-state!: alias struct! [
	cg			[codegen!]
	reg-set		[reg-set!]
	states		[int-array!]	;-- array<int>
	allocated	[ptr-array!]	;-- array<(vreg!, int)>
	move-dsts	[vector!]		;-- vector<(vreg!, list!)>
	cursor		[integer!]		;-- point to next free slot
	pos			[integer!]
	prev-i		[mach-instr!]
	next-i		[mach-instr!]
	move-idx	[int-array!]
	reg-moves	[vector!]		;-- vector<move-state!>
	saves		[vector!]		;-- vector<move-state!>
	reloads		[vector!]		;-- vector<vreg-reg!>	
]

init-reg-state: func [
	s		[reg-state!]
	cg		[codegen!]
	/local
		p	[int-ptr!]
		pp	[ptr-ptr!]
		n	[integer!]
][
	s/cg: cg
	s/reg-set: cg/reg-set
	n: cg/reg-set/n-regs + 1
	s/states: int-array/make n
	s/allocated: ptr-array/make n * 2
	s/cursor: 0
	s/pos: 0

	p: as int-ptr! ARRAY_DATA(s/states)
	loop s/states/length [
		p/value: -1
		p: p + 1
	]

	pp: ARRAY_DATA(s/allocated)
	n: s/allocated/length / 2
	loop n [
		pp/value: null				;-- vreg
		pp: pp + 1
		pp/value: as int-ptr! -1	;-- pos
		pp: pp + 1
	]
]

assign-reg: func [
	s		[reg-state!]
	v		[vreg!]
	reg		[integer!]
	return: [vreg!]
	/local
		i	[integer!]
		idx [integer!]
		p	[ptr-ptr!]
		r	[vreg!]
][
	assert reg <> 0
	i: int-array/pick s/states reg
	either i < 0 [
		idx: s/cursor
		s/cursor: idx + 1
		int-array/poke s/states reg idx
		p: ARRAY_DATA(s/allocated) + (idx * 2)
		p/value: as int-ptr! v
		p: p + 1
		p/value: as int-ptr! s/pos
		null
	][
		p: ARRAY_DATA(s/allocated) + (i * 2)
		r: as vreg! p/value
		p/value: as int-ptr! v
		p: p + 1
		p/value: as int-ptr! s/pos
		r
	]
]

spill-reg: func [
	s			[reg-state!]
	reg			[integer!]
	next-i		[mach-instr!]
	/local
		i		[integer!]
		p		[ptr-ptr!]
		v		[vreg!]
		cg		[codegen!]
][
	i: int-array/pick s/states reg
	if i < 0 [exit]
	p: ARRAY_DATA(s/allocated) + (i * 2)
	v: as vreg! p/value
	cg: s/cg
	alloc-slot cg/frame v
	insert-restore-var cg v reg next-i
]

free-reg: func [
	s			[reg-state!]
	reg			[integer!]
	clear?		[logic!]
	/local
		rset	[reg-set!]
		i		[integer!]
		p pa	[ptr-ptr!]
		states	[int-ptr!]
		ps		[int-ptr!]
		cursor	[integer!]
		v a		[vreg!]
][
	rset: s/reg-set
	unless is-reg? rset reg [exit]	;-- not a reg location

	states: as int-ptr! ARRAY_DATA(s/states)
	ps: states + reg
	i: ps/value
	if i < 0 [exit]		;-- this reg loc is not used

	p: ARRAY_DATA(s/allocated) + (i * 2)
	v: as vreg! p/value
	cursor: s/cursor - 1
	s/cursor: cursor
	pa: ARRAY_DATA(s/allocated) + (cursor * 2)
	a: as vreg! pa/value
	if cursor > 0 [
		p/value: as int-ptr! a
		p: p + 1
		pa: pa + 1
		p/value: pa/value
		ps: states + a/reg
		ps/value: i
	]
	ps: states + reg
	ps/value: -1
	if clear? [v/reg: 0]
]

get-pmove-reg: func [
	s		[reg-set!]
	cls		[reg-class!]
	idx		[integer!]
	return: [integer!]
	/local
		p	[int-ptr!]
		rset [int-array!]
][
	p: s/regs-cls + cls
	rset: as int-array! ptr-array/pick s/regs p/value
	int-array/pick rset idx
]

;-- simple reg allocator
;-- spills everything to the stack between basic blocks
simple-reg-alloc: context [
	alloc: func [
		cg		[codegen!]
		/local
			rstate	[reg-state!]
			rset	[reg-set!]
			cur		[mach-instr!]
			prev	[mach-instr!]
			next	[mach-instr!]
			n len	[integer!]
			opcode	[integer!]
			loc		[integer!]
			blk		[basic-block!]
			l		[label!]
			p pa	[ptr-ptr!]
			o		[operand!]
			d		[def!]
			u		[use!]
			w		[overwrite!]
			k		[kill!]
			v		[vreg!]
			reg		[integer!]
			frame	[frame!]
			arr		[int-array!]
			pint	[int-ptr!]
			m-idx	[int-array!]
			moves	[vector!]
			saves	[vector!]
			reloads	[vector!]
			arg		[move-arg! value]
			move-dsts [vector!]
	][
		frame: cg/frame
		rset: cg/reg-set
		rstate: xmalloc(reg-state!)
		n: rset/n-regs + 1
		m-idx: int-array/make n
		moves: vector/make size? move-state! 2
		saves: vector/make size? move-state! 2
		reloads: vector/make size? vreg-reg! 2
		rstate/move-idx: m-idx
		rstate/reg-moves: moves
		rstate/saves: saves
		rstate/reloads: reloads
		init-reg-state rstate cg

		move-dsts: ptr-vector/make 4
		rstate/move-dsts: move-dsts

		cur: cg/last-i
		while [cur <> null][
			rstate/pos: rstate/pos + 1
			prev: cur/prev
			next: cur/next
			rstate/prev-i: prev
			rstate/next-i: next
			opcode: MACH_OPCODE(cur)

			if opcode = I_PMOVE [		;-- parallel move
				backend/remove-instr cur
				collect-pmove-dests cur move-dsts
				len: move-dsts/length
				n: 0
				while [n < len][
					emit-pmoves rstate n next
					n: n + 2
				]
				cur: prev
				continue
			]
			if opcode = I_BLK_BEG [
				p: as ptr-ptr! cur + 1
				l: as label! p/value
				blk: l/block
				if blk/preds/length <> 0 [
					;-- load all live registers from their spill slot
					pa: ARRAY_DATA(rstate/allocated)
					n: 0
					while [n < rstate/cursor][
						p: pa + (n * 2)
						v: as vreg! p/value
						int-array/poke rstate/states v/reg -1
						alloc-slot frame v
						insert-restore-var cg v v/reg next
						v/reg: 0
						n: n + 1
					]
					rstate/cursor: 0
				]
				cur: prev
				continue
			]
			if opcode = I_BLK_END [
				cur: prev
				continue
			]

			pint: as int-ptr! ARRAY_DATA(m-idx)
			loop m-idx/length [
				pint/value: -1
				pint: pint + 1
			]
			vector/clear moves
			vector/clear saves
			vector/clear reloads

			len: cur/num			;-- number of operands
			p: as ptr-ptr! cur + 1	;-- point to operands

			;-- free regs in def! in this instruction
			loop len [
				o: as operand! p/value
				switch o/header and FFh [
					OD_DEF [
						d: as def! o
						free-reg rstate d/vreg/reg no
					]
					OD_OVERWRITE [
						w: as overwrite! o
						free-reg rstate w/dst/reg no
					]
					default [0]		;-- do nothing
				]
				p: p + 1
			]

			;-- allocate new regs for def!
			p: as ptr-ptr! cur + 1	;-- point to operands
			loop len [
				o: as operand! p/value
				switch o/header and FFh [
					OD_DEF [
						d: as def! o
						reg: alloc-def-reg rstate d/vreg d/constraint
						d/constraint: reg
					]
					OD_OVERWRITE [
						w: as overwrite! o
						reg: alloc-def-reg rstate w/dst w/constraint
						w/constraint: reg
					]
					default [0]		;-- do nothing
				]
				p: p + 1
			]

			rstate/pos: rstate/pos + 1
			p: as ptr-ptr! cur + 1	;-- point to operands
			loop len [
				o: as operand! p/value
				switch o/header and FFh [
					OD_DEF [
						d: as def! o
						free-reg rstate d/constraint yes
					]
					OD_OVERWRITE [
						w: as overwrite! o
						free-reg rstate w/constraint yes
						alloc-use-reg rstate w/src w/constraint
					]
					OD_KILL [
						k: as kill! o
						if k/constraint < rset/regs/length [
							arr: as int-array! ptr-array/pick rset/regs k/constraint
							pint: as int-ptr! ARRAY_DATA(arr)
							loop arr/length [
								reg: pint/value
								spill-reg rstate reg next
								free-reg rstate reg yes
								pint: pint + 1
							]
						]
					]
					OD_USE [
						u: as use! o
						reg: alloc-use-reg rstate u/vreg u/constraint
						u/constraint: reg
					]
					default [0]		;-- do nothing
				]
				p: p + 1
			]

			emit-moves rstate cur/next
			if opcode = I_ENTRY [
				pa: ARRAY_DATA(rstate/allocated)
				n: 0
				while [n < rstate/cursor][
					p: pa + (n * 2)
					v: as vreg! p/value
					if vreg-const?(v) [
						arg/src-v: v
						arg/dst-v: v
						arg/dst-reg: v/reg
						arg/reg-cls: v/reg-class
						insert-move-imm cg :arg next
					]
					n: n + 1
				]
			]

			cur: prev
		]
	]

	emit-moves: func [
		s		[reg-state!]
		next-i	[mach-instr!]
		/local
			cg		[codegen!]
			saves	[vector!]
			reloads [vector!]
			v		[vreg!]
			src		[integer!]
			dst		[integer!]
			i len	[integer!]
			p		[byte-ptr!]
			m		[move-state!]
			vr		[vreg-reg!]
			arg		[move-arg! value]
	][
		cg: s/cg
		saves: s/saves
		p: saves/data
		loop saves/length [
			m: as move-state! p
			v: m/vreg
			src: m/src
			dst: m/dst
			if src <> dst [
				arg/src-v: v
				arg/src-reg: src
				arg/dst-v: v
				arg/dst-reg: dst
				arg/reg-cls: v/reg-class
				insert-move-loc cg :arg next-i
			]
			p: p + size? move-state!
		]

		i: 0
		len: s/reg-moves/length
		while [i < len] [
			emit-move s i next-i
			i: i + 1
		]

		reloads: s/reloads
		p: reloads/data
		loop reloads/length [
			vr: as vreg-reg! p
			v: vr/vreg
			arg/src-v: v
			arg/dst-v: v
			arg/dst-reg: vr/reg
			arg/reg-cls: v/reg-class
			either vreg-const?(v) [
				insert-move-imm cg :arg next-i
			][
				arg/src-reg: v/spill
				insert-move-loc cg :arg next-i
			]
			p: p + size? vreg-reg!
		]
	]

	emit-move: func [
		s			[reg-state!]
		idx			[integer!]
		next-i		[mach-instr!]
		/local
			cg		[codegen!]
			rset	[reg-set!]
			i		[integer!]
			moves	[vector!]
			m		[move-state!]
			dm		[move-state!]
			v		[vreg!]
			src dst [integer!]
			state	[integer!]
			cls		[integer!]
			arg		[move-arg! value]
			p		[int-ptr!]
			scratch [integer!]
	][
		moves: s/reg-moves
		m: as move-state! vector/pick moves idx
		if m/state < V_LIVE [exit]

		m/state: V_ON_STACK
		v: m/vreg
		src: m/src
		dst: m/dst
		rset: s/reg-set
		cg: s/cg
		arg/src-v: v
		arg/dst-v: v
		i: int-array/pick s/move-idx dst
		if i >= 0 [
			dm: as move-state! vector/pick moves i
			state: dm/state
			case [
				state = V_ON_STACK [
					cls: dm/vreg/reg-class
					p: rset/scratch + cls
					scratch: p/value
					dm/state: V_IN_CYCLE
					dm/dst: scratch
					arg/src-reg: dst
					arg/dst-reg: scratch
					arg/reg-cls: cls
					insert-move-loc cg :arg next-i
				]
				state = V_LIVE [
					emit-move s i next-i
				]
				true [0]
			]
		]
		m: as move-state! vector/pick moves idx
		if m/state = V_IN_CYCLE [src: m/dst]	;-- scratch reg
		arg/src-reg: src
		arg/dst-reg: dst
		arg/reg-cls: v/reg-class
		insert-move-loc cg :arg next-i
		m/state: V_DEAD
		m/vreg: null
		m/src: 0
		m/dst: 0
	]

	reassign-reg: func [
		s		[reg-state!]
		v		[vreg!]
		reg		[integer!]
		return: [integer!]
		/local
			old [vreg!]
			r	[vreg-reg!]
	][
		if reg > s/reg-set/n-regs [return reg]		;-- spill on stack
		old: assign-reg s v reg		;-- return the old vreg
		if old <> null [
			alloc-slot s/cg/frame old
			r: as vreg-reg! vector/new-item s/reloads
			r/vreg: old
			r/reg: reg
			old/reg: 0
		]
		v/reg: reg
		reg
	]

	move-reg: func [
		s			[reg-state!]
		v			[vreg!]
		src			[integer!]
		dst			[integer!]
		/local
			moves	[vector!]
			m		[move-state!]
			idx		[integer!]
	][
		if src = dst [exit]
		moves: s/reg-moves
		idx: moves/length
		m: as move-state! vector/new-item moves
		m/vreg: v
		m/src: src
		m/dst: dst
		m/state: V_LIVE
		if is-reg? s/reg-set src [int-array/poke s/move-idx src idx]
	]

	update-pos: func [
		s			[reg-state!]
		reg			[integer!]
		/local
			i		[integer!]
			p		[ptr-ptr!]
	][
		i: int-array/pick s/states reg
		if i < 0 [exit]
		p: ARRAY_DATA(s/allocated) + (i * 2) + 1
		p/value: as int-ptr! s/pos
	]

	reg-is-used?: func [
		s			[reg-state!]
		reg			[integer!]
		return:		[logic!]
		/local
			idx		[integer!]
			p		[ptr-ptr!]
	][
		idx: int-array/pick s/states reg
		either idx < 0 [false][
			p: ARRAY_DATA(s/allocated) + (idx * 2) + 1
			s/pos = as-integer p/value
		]
	]

	find-best-loc: func [		;-- find the best location
		s			[reg-state!]
		cls			[reg-class!]
		hint		[integer!]
		constraint	[integer!]
		return:		[integer!]
		/local
			reg-set [reg-set!]
			p		[int-ptr!]
			i		[integer!]
	][
		reg-set: s/reg-set
		if constraint >= reg-set/regs/length [return constraint]	;-- spill
		if zero? constraint [
			p: reg-set/regs-cls + cls
			constraint: p/value
		]
		if hint <> 0 [
			i: int-array/pick s/states hint
			if all [
				i < 0		;-- hint reg is free
				in-reg-set? reg-set hint constraint
			][
				return hint
			]
		]
		choose-reg s constraint
	]

	choose-reg: func [
		s			[reg-state!]
		constraint	[integer!]
		return:		[integer!]
		/local
			pos		[integer!]
			min-pos [integer!]
			reg		[integer!]
			new-r	[integer!]
			i		[integer!]
			regs	[int-array!]
			p pp	[int-ptr!]
			states	[int-ptr!]
			pa		[ptr-ptr!]
			allocated [ptr-ptr!]
	][
		states: as int-ptr! ARRAY_DATA(s/states)
		allocated: ARRAY_DATA(s/allocated)
		min-pos: 7FFFFFFFh
		new-r: 0

		regs: as int-array! ptr-array/pick s/reg-set/regs constraint
		p: as int-ptr! ARRAY_DATA(regs)
		loop regs/length [
			reg: p/value
			pp: states + reg
			i: pp/value
			if i < 0 [return reg]	;-- the reg is free, return it
			pa: allocated + (i * 2) + 1
			pos: as-integer pa/value
			if pos < min-pos [
				min-pos: pos
				new-r: reg
			]
			p: p + 1
		]
		if zero? new-r [probe "no free registers" assert 0 = 1 halt]
		new-r
	]

	alloc-use-reg: func [
		s			[reg-state!]
		v			[vreg!]
		constraint	[integer!]
		return:		[integer!]
		/local
			reg		[integer!]
			loc		[integer!]
			m		[move-state!]
			rset	[reg-set!]
			prev	[mach-instr!]
			cg		[codegen!]
			arg		[move-arg! value]
	][
		cg: s/cg
		rset: s/reg-set
		prev: s/prev-i
		reg: v/reg
		loc: reg
		if on-stack? rset constraint [
			arg/src-v: v
			arg/dst-v: v
			arg/dst-reg: constraint
			arg/reg-cls: v/reg-class
			either vreg-const?(v) [
				insert-move-imm cg :arg prev/next
			][
				either reg <> 0 [
					update-pos s reg
					arg/src-reg: reg
				][
					alloc-slot cg/frame v
					if v/spill = constraint [return constraint]
					arg/src-reg: v/spill
				]
				insert-move-loc cg :arg prev/next
			]
			return constraint
		]
		either all [
			reg <> 0
			constraint < rset/regs/length
			any [
				zero? constraint
				in-reg-set? rset reg constraint
			]
		][
			update-pos s reg
		][
			either reg-is-used? s reg [
				free-reg s reg yes
				loc: reassign-reg s v find-best-loc s v/reg-class v/hint constraint
				arg/src-v: v
				arg/dst-v: v
				arg/src-reg: loc
				arg/dst-reg: reg
				arg/reg-cls: v/reg-class
				insert-move-loc cg :arg prev/next
			][
				spill-reg s reg s/next-i
				free-reg s reg yes
				loc: reassign-reg s v find-best-loc s v/reg-class v/hint constraint
			]
		]
		loc
	]

	alloc-def-reg: func [
		s			[reg-state!]
		v			[vreg!]
		constraint	[integer!]
		return:		[integer!]
		/local
			reg		[integer!]
			loc		[integer!]
			spill	[integer!]
			m		[move-state!]
	][
		reg: v/reg
		v/reg: 0
		loc: reassign-reg s v find-best-loc s v/reg-class reg constraint
		if reg <> 0 [move-reg s v loc reg]
		spill: v/spill
		if all [spill <> 0 spill <> loc][
			m: as move-state! vector/new-item s/saves
			m/vreg: v
			m/src: loc
			m/dst: spill
		]
		loc
	]

	emit-pmoves: func [
		s		[reg-state!]
		idx		[integer!]
		next-i	[mach-instr!]
		/local
			v	[vreg!]
			l 	[list!]
			dst [list!]
			d	[def!]
			dv	[vreg!]
			i	[integer!]
			r	[integer!]
			cg	[codegen!]
			rset  [reg-set!]
			frame [frame!]
	][
		v: as vreg! vector/pick-ptr s/move-dsts idx
		dst: as list! vector/pick-ptr s/move-dsts idx + 1
		if v/pmove <= 0 [exit]		;-- already emitted or on stack

		cg: s/cg
		frame: cg/frame
		rset: s/reg-set
		v/pmove: V_ON_STACK
		l: dst
		while [l <> null][
			d: as def! l/head
			dv: d/vreg
			i: dv/pmove
			alloc-slot frame dv
			if i = V_ON_STACK [
				dv/pmove: V_IN_CYCLE
				r: get-pmove-reg rset dv/reg-class 1
				insert-restore-var cg dv r next-i
			]
			if i > 0 [emit-pmoves s i - 1 next-i]
			l: l/tail
		]
		alloc-slot frame v
		either v/pmove = V_IN_CYCLE [
			idx: get-pmove-reg rset v/reg-class 1
		][
			idx: get-pmove-reg rset v/reg-class 0
			insert-restore-var cg v idx next-i
		]

		l: dst
		while [l <> null][
			d: as def! l/head
			insert-save-var cg idx d/vreg next-i
			l: l/tail
		]
		v/pmove: 0
	]
]