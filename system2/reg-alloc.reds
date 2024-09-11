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
	
	reg-state!: alias struct! [
		cg			[codegen!]
		reg-set		[reg-set!]
		states		[int-array!]	;-- array<int>
		allocated	[ptr-array!]	;-- array<(vreg!, int)>
		move-dsts	[vector!]
		cursor		[integer!]
		pos			[integer!]
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

	allocate: func [
		cg		[codegen!]
		/local
			rstate	[reg-state!]
			rset	[reg-set!]
			cur		[mach-instr!]
			prev	[mach-instr!]
			next	[mach-instr!]
			n len	[integer!]
			opcode	[integer!]
			move-dsts [vector!]
	][
		rset: cg/reg-set
		rstate: xmalloc(reg-state!)
		rstate/cg: cg
		rstate/reg-set: rset
		rstate/states: int-array/make rset/n-regs
		rstate/allocated: ptr-array/make rset/n-regs * 2
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
			]
			cur: prev
		]
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
			l	[list!]
			d	[def!]
			dv	[vreg!]
			i	[integer!]
			r	[integer!]
			frame [frame!]
	][
		v: as vreg! vector/pick-ptr s/move-dsts idx
		l: as list! vector/pick-ptr s/move-dsts idx + 1
		if v/pmove <= 0 [exit]		;-- already emitted or on stack

		frame: s/cg/frame
		v/pmove: V_ON_STACK
		while [l <> null][
			d: as def! l/head
			dv: d/vreg
			i: dv/pmove
			alloc-slot frame dv
			if i = V_ON_STACK [
				dv/pmove: V_IN_CYCLE
				r: get-pmove-reg s/reg-set dv/reg-class 1
				
			]
			
			l: l/tail
		]
	]
]