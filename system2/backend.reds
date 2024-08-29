Red/System [
	File: 	 %backend.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum reg-class! [
	class_i32
	class_i64
	class_f32
	class_f64
]

fn-alloc-regs!: alias function! [codegen [codegen!]]
fn-make-frame!: alias function! [ir [ir-fn!] return: [frame!]]
fn-generate!: alias function! [ir [ir-fn!] frame [frame!]]

operand!: alias struct! [
	header		[integer!]
	data		[int-ptr!]
]

mach-instr!: alias struct! [
	header		[integer!]
	operands	[ptr-array!]	;-- array<operand!>
	prev		[mach-instr!]
	next		[mach-instr!]
]

mach-fn!: alias struct! [
	code		[mach-instr!]
]

vreg!: alias struct! [			;-- virtual register
	instr		[instr!]
	num			[integer!]
	n-vars		[integer!]
	start		[integer!]
	end			[integer!]
	live?		[logic!]
]

reg-set!: alias struct! [		;-- register set
	n-regs		[integer!]		;-- number of physical registers
	regs		[ptr-array!]	;-- array<array<int>>: registers in each set
	regs-cls	[array!]		;-- array<int>: registers in each class
	scratch		[array!]		;-- array<int>: scratch registers in each class
	spill-start	[integer!]
]

call-conv!: alias struct! [
	reg-set		[reg-set!]
	param-types [ptr-ptr!]
	ret-type	[rst-type!]
	param-locs	[array!]
	ret-locs	[array!]
	n-spilled	[integer!]
]

frame!: alias struct! [
	cc			[call-conv!]
	align		[integer!]
	slot-size	[integer!]
	size		[integer!]
]

codegen!: alias struct! [
	mark		[integer!]
	operands	[vector!]		;-- vector<operand!>
	vars		[vector!]		;-- vector<vreg!>
	blocks		[vector!]		;-- vector<block-info!>
	instrs		[vector!]		;-- vector<mach-instr!>
	first-i		[mach-instr!]
	last-i		[mach-instr!]
	end-i		[mach-instr!]
	cur-i		[mach-instr!]
	cur-blk		[basic-block!]
	frame		[frame!]
	rpo			[rpo!]
	fn			[ir-fn!]
	ssa-ctx		[ssa-ctx!]
	liveness	[bit-table!]
]

loop-info!: alias struct! [
	index		[integer!]
	start		[integer!]
	end			[integer!]
	depth		[integer!]
	out-edges	[list!]			;-- list<cf-edge!>
]

block-info!: alias struct! [
	block		[basic-block!]
	start		[integer!]
	end			[integer!]
	label		[integer!]
	loop-info	[loop-info!]
]

;-- reverse post-order of basic blocks
rpo!: alias struct! [
	blocks		 [vector!]		;-- vector<block-info!>
	n-blocks	 [integer!]
	loops		 [vector!]		;-- vector<loop-info!>
	blk-list	 [list!]
	loop-edges	 [list!]
	loop-headers [ptr-array!]
	bitmap		 [bit-table!]
	start-bb	 [basic-block!]
]

rpo: context [
	#define RPO_NUMBERING -2
	#define RPO_DONE -3

	#define IN_LOOP?(blk loop-info) [
		bit-table/pick bitmap loop-info/index + 1 blk/mark
	]

	#define MARK_IN_LOOP(blk loop-info) [
		bit-table/set bitmap loop-info/index + 1 blk/mark
	]

	loop-block!: alias struct! [
		loop-info	[loop-info!]
		start		[list!]		;-- list<loop-block!>
		end			[list!]		;-- list<loop-block!>
		block		[basic-block!]
	]

	make-block-info: func [
		bb		[basic-block!]
		return:	[block-info!]
		/local
			b	[block-info!]
	][
		b: as block-info! malloc size? block-info!
		b/block: bb
		b/start: -1
		b/end: -1
		b
	]

	number-blocks: func [
		bb			[basic-block!]
		r			[rpo!]
		/local
			n		[integer!]
			succs	[ptr-array!]
			p		[ptr-ptr!]
			e		[cf-edge!]
			blk		[basic-block!]
	][
		bb/mark: RPO_NUMBERING
		succs: block-successors bb
		if succs <> null [
			p: ARRAY_DATA(succs) + succs/length
			loop succs/length [
				p: p - 1
				e: as cf-edge! p/value
				blk: e/dst
				either blk/mark = RPO_NUMBERING [
					LIST_INSERT(r/loop-edges e)
				][
					if blk/mark >= -1 [number-blocks blk r]
				]
			]
		]
		r/n-blocks: r/n-blocks + 1
		bb/mark: RPO_DONE
		LIST_INSERT(r/blk-list bb)
	]

	mark-blocks-loop: func [
		"mark all blocks inside a loop"
		bitmap			[bit-table!]
		loop-info		[loop-info!]
		header			[basic-block!]
		end				[basic-block!]
		/local
			p			[ptr-ptr!]
			e			[cf-edge!]
	][
		if IN_LOOP?(end loop-info) [exit]
		if end = header [exit]
		MARK_IN_LOOP(end loop-info)
		p: ARRAY_DATA(end/preds)
		loop end/preds/length [
			e: as cf-edge! p/value
			mark-blocks-loop bitmap loop-info header as basic-block! e/src/next
			p: p + 1
		]
	]

	make-loop-block: func [
		loop-info	[loop-info!]
		start		[list!]		;-- list<loop-block!>
		end			[list!]		;-- list<loop-block!>
		blk			[basic-block!]
		return:		[loop-block!]
		/local
			l		[loop-block!]
	][
		l: as loop-block! malloc size? loop-block!
		l/loop-info: loop-info
		l/start: start
		l/end: end
		l/block: blk
		l
	]

	number-succs: func [
		r		[rpo!]
		blk		[basic-block!]
		lp		[loop-info!]
		/local
			succs	[ptr-array!]
			p		[ptr-ptr!]
			e		[cf-edge!]
			l-blk	[loop-block!]
			bitmap	[bit-table!]
	][
		succs: block-successors blk
		if succs <> null [
			p: ARRAY_DATA(succs) + succs/length
			either null? lp [
				loop succs/length [
					p: p - 1
					e: as cf-edge! p/value
					number-block-loop r e/dst lp
				]
			][
				bitmap: r/bitmap
				loop succs/length [
					p: p - 1
					e: as cf-edge! p/value
					either IN_LOOP?(e/dst lp) [number-block-loop r e/dst lp][
						LIST_INSERT(lp/out-edges e)
					]
				]
			]
		]
		l-blk: make-loop-block null null null blk
		LIST_INSERT(r/blk-list l-blk)
	]

	number-loop: func [
		r		[rpo!]
		blk		[basic-block!]
		new-lp	[loop-info!]
		lp		[loop-info!]
		/local
			old-list [list!]
			new-list [list!]
			l		 [list!]
			e		 [cf-edge!]
			l-blk	 [loop-block!]
			bitmap	 [bit-table!]
	][
		old-list: r/blk-list
		number-succs r blk new-lp
		new-list: r/blk-list

		r/blk-list: old-list	;-- `pop` all the loop nodes
		l: new-lp/out-edges
		either null? lp [
			while [l <> null][
				e: as cf-edge! l/head
				number-block-loop r e/dst null
				l: l/tail
			]
		][	;-- process out edges in outer loop
			bitmap: r/bitmap
			while [l <> null][
				e: as cf-edge! l/head
				either IN_LOOP?(e/dst lp) [
					number-block-loop r e/dst lp
				][
					LIST_INSERT(lp/out-edges e)
				]
				l: l/tail
			]
		]
		l-blk: make-loop-block new-lp new-list old-list null
		LIST_INSERT(r/blk-list l-blk)
	]

	number-block-loop: func [
		r		[rpo!]
		blk		[basic-block!]
		lp		[loop-info!]
		/local
			new-lp [loop-info!]
	][
		if bit-table/set r/bitmap 0 blk/mark [exit]
		new-lp: as loop-info! ptr-array/pick r/loop-headers blk/mark
		either new-lp <> null [number-loop r blk new-lp lp][
			number-succs r blk lp
		]
	]

	extract-loop-block: func [
		vec			[vector!]
		l-blk		[loop-block!]
		depth		[integer!]
		/local
			bb		[basic-block!]
			lp		[loop-info!]
			blk		[block-info!]
			s e		[list!]
	][
		bb: l-blk/block
		either bb <> null [
			bb/mark: vec/length
			vector/append-ptr vec as byte-ptr! make-block-info bb
		][
			lp: l-blk/loop-info
			lp/start: vec/length
			lp/depth: depth

			s: l-blk/start
			e: l-blk/end
			while [s <> e][
				extract-loop-block vec as loop-block! s/head depth + 1
				s: s/tail
			]
			lp/end: vec/length

			blk: as block-info! vector/pick-ptr vec lp/start
			blk/loop-info: lp
		]
	]

	build-with-loops: func [
		r		[rpo!]
		/local
			bitmap		 [bit-table!]
			loop-headers [ptr-array!]
			loops		 [vector!]
			n-blks		 [integer!]
			list		 [list!]
			l-blk		 [loop-block!]
			vec			 [vector!]
			e			 [cf-edge!]
			d			 [basic-block!]
			s			 [instr-end!]
			lp			 [loop-info!]
	][
		n-blks: r/n-blocks
		bitmap: bit-table/make 1 n-blks
		loop-headers: ptr-array/make n-blks
		loops: vector/make size? int-ptr! 4
		r/loops: loops
		r/bitmap: bitmap
		r/loop-headers: loop-headers

		;-- mark all blocks in all loops
		list: r/loop-edges
		while [list <> null][
			e: as cf-edge! list/head
			s: e/src
			d: e/dst

			;-- get loop info
			lp: as loop-info! ptr-array/pick loop-headers d/mark
			if null? lp [
				lp: as loop-info! malloc size? loop-info!
				lp/index: loops/length
				bit-table/grow bitmap lp/index + 2
				vector/append-ptr loops as byte-ptr! lp
				ptr-array/poke loop-headers d/mark as int-ptr! lp
			]

			;-- mark all blocks in this loop
			MARK_IN_LOOP(d lp)
			mark-blocks-loop bitmap lp d as basic-block! s/next

			list: list/tail
		]

		;-- number blocks, loop-aware depth first
		number-block-loop r r/start-bb null
		vec: vector/make size? int-ptr! n-blks
		list: r/blk-list
		while [list <> null][
			l-blk: as loop-block! list/head
			extract-loop-block vec l-blk 1
			list: list/tail
		]
		r/blocks: vec
	]

	build: func [
		ir		[ir-fn!]
		return: [rpo!]
		/local
			r		[rpo!]
			bb		[basic-block!]
			succs	[ptr-array!]
			vec		[vector!]
			list	[list!]
			i		[integer!]
	][
		r: as rpo! malloc size? rpo!
		bb: ir/start-bb
		r/start-bb: bb

		succs: block-successors bb
		either any [null? succs zero? succs/length][
			bb/mark: 0
			vec: vector/make size? int-ptr! 1
			vector/append-ptr vec as byte-ptr! make-block-info bb
			r/blocks: vec
		][
			number-blocks bb r
			either r/loop-edges <> null [
				i: 0
				list: r/blk-list
				while [list <> null][
					bb: as basic-block! list/head
					bb/mark: i
					i: i + 1
					list: list/tail
				]
				r/blk-list: null
				build-with-loops r
			][
				vec: vector/make size? int-ptr! r/n-blocks
				i: 0
				list: r/blk-list
				while [list <> null][
					bb: as basic-block! list/head
					bb/mark: i
					i: i + 1
					vector/append-ptr vec as byte-ptr! make-block-info bb
					list: list/tail
				]
				r/blocks: vec
			]
		]
		r
	]
]

backend: context [

	reg-class?: func [
		type	[rst-type!]
		return: [reg-class!]
		/local
			w	[integer!]
	][
		switch TYPE_KIND(type) [
			RST_TYPE_INT		[
				w: INT_WIDTH(type)
				return either w > 32 [class_i64][class_i32]
			]
			RST_TYPE_VOID
			RST_TYPE_LOGIC [return class_i32]
			RST_TYPE_FLOAT [
				return either FLOAT_64?(type) [class_f64][class_f32]
			]
			RST_TYPE_C_STR
			RST_TYPE_FUNC
			RST_TYPE_STRUCT
			RST_TYPE_ARRAY
			RST_TYPE_PTR [return class_i32]
			default [class_i32]
		]
	]

	make-codegen: func [
		fn		[ir-fn!]
		rpo		[rpo!]
		frame	[frame!]
		return: [codegen!]
		/local
			cg	[codegen!]
	][
		cg: xmalloc(codegen!)
		cg/operands: ptr-vector/make 4
		cg/vars: ptr-vector/make 8
		cg/fn: fn
		cg/frame: frame
		cg/rpo: rpo
		cg/blocks: rpo/blocks
		cg/instrs: ptr-vector/make rpo/blocks/length
		cg/liveness: bit-table/make rpo/blocks/length 32
		cg/mark: fn/mark
		fn/mark: fn/mark + 1
		cg
	]

	gen-instrs: func [
		cg		[codegen!]
	][
		
	]

	generate: func [
		fn		[ir-fn!]
		return: [mach-fn!]
		/local
			frm	[frame!]
			r	[rpo!]
			cg	[codegen!]
			m	[mach-fn!]
	][
		m: xmalloc(mach-fn!)
		frm: target/make-frame fn
		r: rpo/build fn
		cg: make-codegen fn r frm
		gen-instrs cg
		m
	]
]