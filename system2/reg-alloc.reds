Red/System [
	File: 	 %reg-alloc.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;-- simple reg allocator
;-- spills everything to the stack between basic blocks
reg-allocator: context [
	#define V_LIVE		 0
	#define V_ON_STACK	-1
	#define V_IN_CYCLE	-2
	#define V_DEAD		-3

	move-state!: alias struct! [
		vreg		[vreg!]
		src			[integer!]
		dst			[integer!]
		state		[integer!]
	]

	vreg-reg!: alias struct! [
		vreg		[vreg!]
		reg			[integer!]
	]
	
	reg-state!: alias struct! [
		cg			[codegen!]
		reg-set		[reg-set!]
		states		[int-array!]	;-- array<int>
		allocated	[ptr-array!]	;-- array<(vreg!, int)>
		move-dsts	[vector!]		;-- vector<(vreg!, list!)>
		cursor		[integer!]		;-- point to next free slot
		pos			[integer!]
		move-idx	[int-array!]
		reg-moves	[vector!]		;-- vector<move-state!>
		saves		[vector!]		;-- vector<move-state!>
		reloads		[vector!]		;-- vector<vreg-reg!>	
	]

	init-reg-state: func [
		s		[reg-state!]
		/local
			p	[int-ptr!]
			pp	[ptr-ptr!]
			n	[integer!]
	][
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
			pint	[int-ptr!]
			m-idx	[int-array!]
			moves	[vector!]
			saves	[vector!]
			reloads	[vector!]
			move-dsts [vector!]
	][
		frame: cg/frame
		rset: cg/reg-set
		rstate: xmalloc(reg-state!)
		rstate/cg: cg
		rstate/reg-set: rset
		rstate/states: int-array/make rset/n-regs
		rstate/allocated: ptr-array/make rset/n-regs * 2
		m-idx: int-array/make rset/n-regs
		moves: vector/make size? move-state! 2
		saves: vector/make size? move-state! 2
		reloads: vector/make size? vreg-reg! 2
		rstate/move-idx: m-idx
		rstate/reg-moves: moves
		rstate/saves: saves
		rstate/reloads: reloads
		init-reg-state rstate

		move-dsts: ptr-vector/make 4
		rstate/move-dsts: move-dsts

		cur: cg/last-i
		while [cur <> null][
			rstate/pos: rstate/pos + 1
			prev: cur/prev
			next: cur/next
			opcode: MACH_OPCODE(cur)

			if opcode = I_PMOVE [		;-- parallel move
				backend/remove-instr cur
				collect-pmove-dests cur move-dsts
				len: move-dsts/length
				n: 0
				while [n < len][
					emit-moves rstate n next
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

			n: 0
			loop len [
				o: as operand! p/value
				switch o/header and FFh [
					OD_DEF [
						d: as def! o
						
					]
					OD_OVERWRITE [
						
					]
					default [0]		;-- do nothing
				]
				p: p + 1
			]
			cur: prev
		]
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
		if zero? new-r [probe "no free registers" halt]
		new-r
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

	alloc-reg: func [
		s			[reg-state!]
		v			[vreg!]
		constraint	[integer!]
		/local
			reg		[integer!]
			loc		[integer!]
	][
		reg: v/reg
		v/reg: 0
		loc: reassign-reg s v find-best-loc s v/reg-class reg constraint
		
	]

	alloc-slot: func [
		f		[frame!]
		v		[vreg!]
	][
		if zero? v/spill [v/spill: frame-alloc-slot f v/reg-class]
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

	emit-moves: func [
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
			if i > 0 [emit-moves s i - 1 next-i]
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