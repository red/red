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

#define M_FLAG_FIXED	80000000h	;-- cannot insert before this instr
#define M_FLAG_READ		40000000h	;-- a read instr
#define M_FLAG_WRITE	20000000h	;-- a write instr

fn-alloc-regs!: alias function! [codegen [codegen!]]
fn-make-frame!: alias function! [ir [ir-fn!] return: [frame!]]
fn-generate!: alias function! [cg [codegen!] blk [basic-block!] i [instr!]]

#define OPERAND_HEADER	[header [integer!]]

#enum operand-kind! [
	OD_USE
	OD_DEF
	OD_IMM
	OD_SCRATCH
	OD_KILL
	OD_LABEL
	OD_LIVEPOINT
	OD_OVERWRITE
]

operand!: alias struct! [
	OPERAND_HEADER
]

use!: alias struct! [
	OPERAND_HEADER
	vreg		[vreg!]
	constraint	[integer!]
]

def!: alias struct! [
	OPERAND_HEADER
	vreg		[vreg!]
	constraint	[integer!]
]

label!: alias struct! [
	OPERAND_HEADER
	block		[basic-block!]
	pos			[integer!]
	refs		[list!]		;-- list<int>
]

immediate!: alias struct! [
	OPERAND_HEADER
	val			[cell!]
]

livepoint!: alias struct! [
	OPERAND_HEADER
	livepoint	[integer!]
	cc			[call-conv!]
]

scratch!: alias struct! [
	OPERAND_HEADER
	reg-cls		[reg-class!]
]

kill!: alias struct! [
	OPERAND_HEADER
	constraint	[integer!]
]

overwrite!: alias struct! [
	OPERAND_HEADER
	dst			[vreg!]
	src			[vreg!]
	constraint	[integer!]
]

#define MACH_OPCODE(i)	[i/header and 03FFh]

;-- header: 31 - 28 flags | 
;-- x86: 20 - 19 rounding mode | 18 - 15 condition | 14 - 10 addressing mode | 9 - 0 opcode
;-- arm: 
mach-instr!: alias struct! [
	header		[integer!]
	prev		[mach-instr!]
	next		[mach-instr!]
	num			[integer!]		;-- num of the operands
	;-- followed by operands
	;operands	[operand!]
]

mach-fn!: alias struct! [
	code		[mach-instr!]
]

#enum vreg-usage! [
	USAGE_NONE
	USAGE_ONCE
	USAGE_MANY
]

vreg!: alias struct! [			;-- virtual register
	prev		[vreg!]
	next		[vreg!]
	block		[basic-block!]
	instr		[instr!]
	idx			[integer!]
	start		[integer!]
	end			[integer!]
	live?		[logic!]
	live-pos	[integer!]		;-- last live position
	spill		[integer!]
	hint		[integer!]
	reg			[integer!]
	reg-class	[reg-class!]
	usage		[integer!]
]

reg-set!: alias struct! [		;-- register set
	n-regs		[integer!]		;-- number of physical registers
	regs		[ptr-array!]	;-- array<array<int>>: registers in each set
	regs-cls	[int-ptr!]		;-- array<int>: registers in each class
	scratch		[rs-array!]		;-- array<int>: scratch registers in each class
	spill-start	[integer!]
]

call-conv!: alias struct! [
	reg-set		[reg-set!]
	param-types [ptr-ptr!]
	ret-type	[rst-type!]
	param-locs	[rs-array!]
	ret-locs	[rs-array!]
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
	vregs		[vector!]		;-- vector<vreg!>
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
	reg-set		[reg-set!]
	ssa-ctx		[ssa-ctx!]
	liveness	[bit-table!]
	livepoints	[integer!]
	m			[instr-matcher!]
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
	label		[label!]
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

make-label: func [
	blk		[basic-block!]
	return: [label!]
	/local
		l	[label!]
][
	l: xmalloc(label!)
	l/header: od_label
	l/block: blk
	l
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
		b/label: make-label bb
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
				bit-table/grow-row bitmap lp/index + 2
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

#define CALLER_SPILL_BASE	100000000
#define CALLEE_SPILL_BASE	200000000

#define put-operand(o) [
	vector/append-ptr cg/operands as byte-ptr! o
]

directly-after?: func [ ;-- b directly after a?
	a	[basic-block!]
	b	[basic-block!]
	return: [logic!]
][
	a/mark + 1 = b/mark
]

backend: context [
	int-imm-caches: as ptr-array! 0

	#include %x86/codegen.reds

	init: func [
		/local
			p	[ptr-ptr!]
			i	[integer!]
	][
		int-imm-caches: ptr-array/make 10
		p: ARRAY_DATA(int-imm-caches)
		i: -1
		loop 10 [
			p/value: as int-ptr! make-imm-int i
			p: p + 1
			i: i + 1
		]
	]

	#define CALC_REG_INDEX(base) [
		either idx <= cc/reg-set/n-regs [idx][
			idx - cc/reg-set/spill-start + base
		]
	]

	caller-param: func [
		cc		[call-conv!]
		i		[integer!]
		return: [integer!]
		/local
			p	[int-ptr!]
			idx [integer!]
	][
		p: as int-ptr! ARRAY_DATA(cc/param-locs)
		p: p + i
		idx: p/value
		CALC_REG_INDEX(CALLER_SPILL_BASE)
	]

	caller-ret: func [
		cc		[call-conv!]
		i		[integer!]
		return: [integer!]
		/local
			p	[int-ptr!]
			idx [integer!]
	][
		p: as int-ptr! ARRAY_DATA(cc/ret-locs)
		p: p + i
		idx: p/value
		CALC_REG_INDEX(CALLER_SPILL_BASE)
	]

	callee-param: func [
		cc		[call-conv!]
		i		[integer!]
		return: [integer!]
		/local
			p	[int-ptr!]
			idx [integer!]
	][
		p: as int-ptr! ARRAY_DATA(cc/param-locs)
		p: p + i
		idx: p/value
		CALC_REG_INDEX(CALLEE_SPILL_BASE)
	]

	callee-ret: func [
		cc		[call-conv!]
		i		[integer!]
		return: [integer!]		;-- reg idx or slot idx
		/local
			p	[int-ptr!]
			idx [integer!]
	][
		p: as int-ptr! ARRAY_DATA(cc/ret-locs)
		p: p + i
		idx: p/value
		CALC_REG_INDEX(CALLEE_SPILL_BASE)
	]

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

	update-usage: func [
		reg		[vreg!]
	][
		if reg/spill < 0 [exit]		;-- constant value
		either reg/usage = USAGE_NONE [
			reg/usage: USAGE_ONCE
		][
			reg/usage: USAGE_MANY
		]
	]

	make-overwrite: func [
		dst		[vreg!]
		src		[vreg!]
		c		[integer!]
		/local
			x	[overwrite!]
	][
		x: xmalloc(overwrite!)
		x/header: OD_OVERWRITE
		x/dst: dst
		x/src: src
		x/constraint: c
		x
	]

	make-def: func [
		reg		[vreg!]
		c		[integer!]
		return: [def!]
		/local
			d	[def!]
	][
		d: xmalloc(def!)
		d/header: OD_DEF
		d/vreg: reg
		d/constraint: c
		d
	]

	make-use: func [
		reg		[vreg!]
		c		[integer!]
		return: [use!]
		/local
			u	[use!]
	][
		u: xmalloc(use!)
		u/header: OD_USE
		u/vreg: reg
		u/constraint: c
		u
	]

	make-imm-int: func [
		n		[integer!]
		return: [immediate!]
		/local
			i	[immediate!]
			int [red-integer!]
	][
		i: xmalloc(immediate!)
		i/header: OD_IMM
		int: xmalloc(red-integer!)
		int/header: TYPE_INTEGER
		int/value: n
		i/val: as cell! int
		i
	]

	kill: func [
		cg		[codegen!]
		c		[integer!]
		/local
			k	[kill!]
	][
		k: xmalloc(kill!)
		k/header: OD_KILL
		k/constraint: c
		vector/append-ptr cg/operands as byte-ptr! k
	]

	live-point: func [
		cg		[codegen!]
		cc		[call-conv!]
		/local
			l	[livepoint!]
	][
		l: xmalloc(livepoint!)
		l/header: OD_LIVEPOINT
		l/livepoint: cg/livepoints
		l/cc: cc
		cg/livepoints: cg/livepoints + 1
		vector/append-ptr cg/operands as byte-ptr! l
	]

	overwrite-reg: func [
		cg		[codegen!]
		dst		[instr!]
		src		[instr!]
		/local
			dreg [vreg!]
			sreg [vreg!]
			o	 [overwrite!]
			p	 [int-ptr!]
	][
		dreg: get-vreg cg dst
		assert dreg <> null
		sreg: get-vreg cg src
		assert sreg <> null
		update-usage sreg
		p: cg/reg-set/regs-cls + dreg/reg-class
		vector/append-ptr cg/operands as byte-ptr! make-overwrite dreg sreg p/value
	]

	def-reg-fixed: func [
		cg			[codegen!]
		i			[instr!]
		constraint	[integer!]
		/local
			v		[vreg!]
	][
		v: get-vreg cg i
		if constraint < cg/reg-set/n-regs [v/hint: constraint]
		vector/append-ptr cg/operands as byte-ptr! make-def v constraint
	]

	def-reg: func [
		cg		[codegen!]
		i		[instr!]
		/local
			v	[vreg!]
			p	[int-ptr!]
	][
		v: get-vreg cg i
		p: cg/reg-set/regs-cls + v/reg-class	;-- any regs in this class
		vector/append-ptr cg/operands as byte-ptr! make-def v p/value
	]

	use-i: func [
		cg		[codegen!]
		i		[instr!]
		/local
			v	[vreg!]
	][
		v: get-vreg cg i
		update-usage v
		vector/append-ptr cg/operands as byte-ptr! make-use v 0
	]

	use-reg: func [
		cg		[codegen!]
		i		[instr!]
		/local
			v	[vreg!]
			p	[int-ptr!]
	][
		v: get-vreg cg i
		update-usage v
		p: cg/reg-set/regs-cls + v/reg-class	;-- any regs in this class
		vector/append-ptr cg/operands as byte-ptr! make-use v p/value
	]

	use-reg-fixed: func [
		cg		[codegen!]
		i		[instr!]
		c		[integer!]
		/local
			v	[vreg!]
	][
		v: get-vreg cg i
		update-usage v
		vector/append-ptr cg/operands as byte-ptr! make-use v c
	]

	use-label: func [
		cg		[codegen!]
		blk		[basic-block!]
		/local
			bi	[block-info!]
	][
		bi: as block-info! vector/pick-ptr cg/blocks blk/mark
		vector/append-ptr cg/operands as byte-ptr! bi/label
	]

	use-imm: func [
		cg		[codegen!]
		val		[cell!]
		/local
			i	[immediate!]
	][
		i: xmalloc(immediate!)
		i/header: OD_IMM
		i/val: val
		vector/append-ptr cg/operands as byte-ptr! i	
	]

	use-ptr: func [
		cg		[codegen!]
		p		[int-ptr!]
		/local
			f	[red-function!]
	][
		f: xmalloc(red-function!)
		f/header: TYPE_FUNCTION
		f/spec: p
		use-imm cg as cell! f
	]

	use-imm-int: func [
		cg		[codegen!]
		int		[integer!]
		/local
			i	[int-ptr!]
	][
		either all [int > -2 int < 9][
			i: ptr-array/pick int-imm-caches int + 1
		][
			i: as int-ptr! make-imm-int int
		]
		vector/append-ptr cg/operands as byte-ptr! i
	]

	emit-instr: func [
		cg		[codegen!]
		op		[integer!]
		/local
			n	[integer!]
			i	[mach-instr!]
			cur [mach-instr!]
			p	[ptr-ptr!]
			po	[ptr-ptr!]
			prev [mach-instr!]
			operands [vector!]
	][
		operands: cg/operands
		n: operands/length
		i: as mach-instr! malloc (n * size? int-ptr!) + size? mach-instr!
		i/header: op
		i/num: n

		p: as ptr-ptr! (i + 1)
		po: as ptr-ptr! operands/data
		loop n [
			p/value: po/value
			p: p + 1
			po: po + 1
		]
		operands/length: 0

		;-- insert before cur-i
		cur: cg/cur-i
		i/next: cur
		prev: cur/prev
		either prev <> null [
			prev/next: i
			i/prev: prev
		][
			cg/first-i: i
		]
		cur/prev: i
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
		cg/vregs: ptr-vector/make 8
		cg/fn: fn
		cg/frame: frame
		cg/rpo: rpo
		cg/blocks: rpo/blocks
		cg/instrs: ptr-vector/make rpo/blocks/length
		cg/liveness: bit-table/make rpo/blocks/length 32
		cg/reg-set: frame/cc/reg-set
		cg/m: matcher/make
		cg/mark: fn/mark
		fn/mark: fn/mark + 1
		cg
	]

	make-instr: func [
		op		 [integer!]
		operands [ptr-array!]
		return:	 [mach-instr!]
		/local
			i	 [mach-instr!]
			p po [ptr-ptr!]
	][
		i: xmalloc(mach-instr!)
		i/header: op
		i/num: operands/length
		p: as ptr-ptr! (i + 1)
		po: ARRAY_DATA(operands)
		loop i/num [
			p/value: po/value
			p: p + 1
			po: po + 1
		]
		i
	]

	make-vreg: func [
		cg		[codegen!]
		i		[instr!]
		return: [vreg!]
		/local
			v		[vreg!]
			mark	[integer!]
			len		[integer!]
			cls		[integer!]
			type	[rst-type!]
			ivar	[instr-var!]
			op		[instr-op!]
			idx		[integer!]
			vregs	[vector!]
	][
		mark: cg/fn/mark
		cg/fn/mark: mark + 1

		cls: class_i32
		if i <> null [
			either INSTR_FLAGS(i) and F_NOT_VOID = 0 [
				return null
			][
				type: either INSTR_OPCODE(i) >= OP_BOOL_EQ [
					op: as instr-op! i
					op/ret-type
				][
					ivar: as instr-var! i
					ivar/type
				]
				cls: reg-class? type
			]
			i/mark: mark
		]
	
		idx: mark - cg/mark
		len: idx + 2
		bit-table/grow-column cg/liveness len

		vregs: cg/vregs
		vector/grow vregs len
		vregs/length: len

		v: xmalloc(vreg!)
		v/instr: i
		v/idx: idx
		v/reg-class: cls
		vector/poke-ptr vregs idx as int-ptr! v
		if INSTR_OPCODE(i) and INS_CONST <> 0 [
			v/spill: -2 - idx		;-- use negative spill to mark constants
		]
		v
	]

	get-vreg: func [
		cg		[codegen!]
		i		[instr!]
		return: [vreg!]
	][
		if i/mark >= cg/fn/mark [
			probe "get vreg error: invalid instr mark"
			halt
		]
		if INSTR_FLAGS(i) and F_NOT_VOID = 0 [return null]

		either i/mark <= cg/mark [
			make-vreg cg i
		][
			as vreg! vector/pick-ptr cg/vregs i/mark - cg/mark
		]
	]

	select-instr: func [
		cg			[codegen!]
		blk			[basic-block!]
		i			[instr!]
	][
		switch INSTR_OPCODE(i) [
			INS_IF		[target/gen-if cg blk i]
			INS_GOTO
			INS_RETURN
			INS_SWITCH
			INS_THROW	[0]
			default		[target/gen-op cg blk i]
		]
	]

	select-instrs: func [
		cg			[codegen!]
		blk			[basic-block!]
		/local
			i		[instr!]
			vreg	[vreg!]
	][
		cg/cur-blk: blk
		cg/end-i: cg/cur-i

		i: blk/next
		while [i <> blk][
			vreg: get-vreg cg i
			if vreg <> null [vreg/block: blk]
			i: i/next
		]

		;-- select instr in reverse order
		use-label cg blk
		emit-instr cg I_BLK_END
		cg/cur-i: cg/first-i			;-- set cur-i to head
		i: blk/prev
		while [i <> blk][
			if INSTR_PHI?(i) [break]	;-- PHis are in the begin of the block
			select-instr cg blk i
			cg/cur-i: cg/first-i
			i: i/prev
		]
		use-label cg blk
		emit-instr cg I_BLK_BEG
		cg/cur-i: cg/first-i
	]

	gather-liveness: func [
		cg			[codegen!]
		blk			[basic-block!]
		/local
			succs	[ptr-array!]
			p		[ptr-ptr!]
			e		[cf-edge!]
	][
		succs: block-successors blk
		if succs <> null [
			p: ARRAY_DATA(succs)
			loop succs/length [
				e: as cf-edge! p/value	
				p: p + 1
				bit-table/or-rows cg/liveness blk/mark e/dst/mark
			]
		]
	]

	gen-params: func [
		cg		[codegen!]
	][
		
	]

	gen-instrs: func [
		cg		[codegen!]
		/local
			i		[integer!]
			p		[ptr-ptr!]
			len		[integer!]
			info	[block-info!]
			blk		[basic-block!]
	][
		cg/cur-i: make-instr I_END empty-array
		cg/last-i: cg/cur-i

		p: VECTOR_DATA(cg/blocks)
		len: cg/blocks/length
		p: p + len
		loop len [
			p: p - 1
			info: as block-info! p/value
			blk: info/block
			gather-liveness cg blk
			select-instrs cg blk
		]
		gen-params cg
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
		m/code: cg/first-i
		print-fn m
		m
	]

	do-i: func [i [integer!]][
		loop i [prin "  "]
	]

	prin-operand: func [
		a		[operand!]
		/local
			u	[use!]
			d	[def!]
			imm [immediate!]
			o	[overwrite!]
			l	[label!]
	][
		switch a/header and FFh [
			OD_USE		[
				prin "use#"
				u: as use! a
				print u/vreg/idx
			]
			OD_DEF [
				prin "def#"
				d: as def! a
				print d/vreg/idx
			]
			OD_IMM [
				prin "imm#"
				imm: as immediate! a
				prin-token imm/val
			]
			OD_OVERWRITE [
				prin "write #"
				o: as overwrite! a
				print o/dst/idx
				prin " #"
				print o/src/idx
			]
			OD_KILL [prin "kill"]
			OD_LABEL [
				l: as label! a
				print ["block#" l/block]
			]
			OD_LIVEPOINT [prin "livepoint"]
			OD_SCRATCH	[prin "<scratch>"]
		]
	]

	print-operands: func [
		a		[ptr-ptr!]
		n		[integer!]
		/local
			i	[integer!]
	][
		i: 0
		loop n [
			if i > 0 [prin ", "]
			prin-operand as operand! a/value
			a: a + 1
			i: i + 1
		]
	]

	print-op: func [
		i		[mach-instr!]
		ident	[integer!]
		return: [integer!]
	][
		do-i ident
		print ["opcode: " MACH_OPCODE(i) " "]
		print-operands as ptr-ptr! i + 1 i/num
		ident
	]

	print-instr: func [
		i		[mach-instr!]
		ident	[integer!]
		return: [integer!]
		/local
			a	[ptr-ptr!]
			n	[integer!]
	][
		n: i/num
		a: as ptr-ptr! i + 1
		switch MACH_OPCODE(i) [
			I_NOP		[do-i ident + 1 prin "nop"]
			I_BLK_BEG	[
				do-i ident prin "begin "
				print-operands a n
			]
			I_BLK_END	[
				do-i ident prin "end "
				print-operands a n
				print lf
			]
			I_END		[do-i ident prin "end"]
			I_RET		[do-i ident + 1 prin "ret " print-operands a n]
			default 	[ident: -1 + print-op i ident + 1]
		]
		print lf
		ident
	]

	print-fn: func [
		fn		[mach-fn!]
		/local
			i	[mach-instr!]
			ident [integer!]
	][
		print-line ["fn " fn]
		i: fn/code
		ident: 1
		while [i <> null][
			ident: print-instr i ident
			i: i/next
		]
		print lf
	]
]