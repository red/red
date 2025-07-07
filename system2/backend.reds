Red/System [
	File: 	 %backend.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define EXTRA_FRAME_SLOTS	2		;-- catch value + catch address
#define INIT_FRAME_SLOTS	4		;-- return address + ebp value + EXTRA_FRAME_SLOTS

#enum reg-class! [
	class_i32
	class_i64
	class_f32
	class_f64
	class_struct
]

#define M_FLAG_FIXED	80000000h	;-- cannot insert before this instr
#define M_FLAG_COPY		40000000h	;-- instr can be copied
#define M_FLAG_READ		20000000h	;-- a read instr
#define M_FLAG_WRITE	10000000h	;-- a write instr

#define OD_FLAG_LEA		0100h		;-- take effective address

;-- header: bits: 0 - 8 operand kind, bits: 8 - 31 flags
#define OPERAND_HEADER	[header [integer!]]

#enum operand-kind! [
	OD_USE
	OD_DEF
	OD_IMM
	OD_REG			;-- for special regs: esp, ebp, eip
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
	value		[cell!]
]

livepoint!: alias struct! [
	OPERAND_HEADER
	index		[integer!]
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

#define OPERAND_TYPE(o) [o/header and FFh]
#define OPERAND_DEF?(o) [o/header and FFh = OD_DEF]
#define OPERAND_IMM?(o) [o/header and FFh = OD_IMM]
#define OPERAND_USE?(o) [o/header and FFh = OD_USE]
#define OPERAND_LEA?(o) [o/header and OD_FLAG_LEA <> 0]
#define MACH_OPCODE(i)	[i/header and 03FFh]
#define INS_OPERANDS(i)	[as ptr-ptr! i + 1]
#define x86_OPCODE(i)	[i and 03FFh]

#enum divide-result! [
	div_quotient
	div_remainder
	div_modulo			;-- Euclidean division
]

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
	size		[integer!]		;-- number of vregs the var represents
	start		[integer!]
	end			[integer!]
	live?		[logic!]
	live-pos	[integer!]		;-- last live position
	spillable?	[logic!]
	spill-from	[vreg!]
	spill		[integer!]
	hint		[integer!]
	reg			[integer!]
	reg-class	[reg-class!]
	usage		[integer!]
	pmove		[integer!]		;-- parallel move state
	stack-idx	[integer!]
]

reg-set!: alias struct! [		;-- register set
	n-regs		[integer!]		;-- number of physical registers
	regs		[ptr-array!]	;-- array<array<int>>: registers in each set
	regs-cls	[int-ptr!]		;-- array<int>: registers in each class
	scratch		[int-ptr!]		;-- array<int>: scratch register in each class
	gpr-scratch	[integer!]
	sse-scratch [integer!]
	frame-start [integer!]
	spill-start	[integer!]
	caller-base	[integer!]
	callee-base	[integer!]
	bitmap		[bit-table!]	;-- bitmap to check if a reg in the reg set
]

call-conv!: alias struct! [
	reg-set			[reg-set!]
	param-types 	[ptr-ptr!]
	ret-type		[rst-type!]
	param-locs		[rs-array!]
	ret-locs		[rs-array!]
	n-spilled		[integer!]
	callee-clean?	[logic!]			;-- callee cleans the stack
	fpu?			[logic!]
]

frame!: alias struct! [
	cc			[call-conv!]
	align		[integer!]
	slot-size	[integer!]
	size		[integer!]				;-- total frame size
	spill-vars	[integer!]				;-- spilled variables
	spill-args	[integer!]				;-- spilled arguments
	tmp-slot	[integer!]
	typed-value [integer!]
]

assembler!: alias struct! [
	buf			[vector!]
]

codegen!: alias struct! [
	mark				[integer!]
	operands			[vector!]		;-- vector<operand!>
	vregs				[vector!]		;-- vector<vreg!>
	blocks				[vector!]		;-- vector<block-info!>
	instrs				[vector!]		;-- vector<mach-instr!>
	first-i				[mach-instr!]
	last-i				[mach-instr!]
	end-i				[mach-instr!]
	cur-i				[mach-instr!]
	cur-blk				[basic-block!]
	frame				[frame!]
	rpo					[rpo!]
	fn					[ir-fn!]
	reg-set				[reg-set!]
	ssa-ctx				[ssa-ctx!]
	liveness			[bit-table!]
	nlivepoints			[integer!]
	livepoints			[vector!]		;-- vector<(basic-block!, instr!, livepoint!)>
	compute-liveness?	[logic!]
	fixed-stack?		[logic!]
	m					[instr-matcher!]
]

move-arg!: alias struct! [
	src-v		[vreg!]
	dst-v		[vreg!]
	src-reg	 	[integer!]
	dst-reg		[integer!]
	reg-cls 	[reg-class!]
]

#define CALLER_SPILL_BASE	100000000
#define CALLEE_SPILL_BASE	200000000

#define put-operand(o) [
	vector/append-ptr cg/operands as byte-ptr! o
]

#define vreg-const?(v) [v/spill < 0]
#define vreg-not-const?(v) [v/spill >= 0]

directly-after?: func [ ;-- b directly after a?
	a	[basic-block!]
	b	[basic-block!]
	return: [logic!]
][
	a/mark + 1 = b/mark
]

#define FRAME_SLOT_64	40000000h	;-- flag for a 64-bit stack slot

frame-alloc: func [
	f		[frame!]
	sz		[integer!]
	return: [integer!]
	/local
		n s [integer!]
][
	n: sz + f/slot-size - 1 / f/slot-size
	s: f/cc/reg-set/spill-start + f/spill-vars
	f/spill-vars: f/spill-vars + n
	s
]

frame-alloc-slot: func [
	f		[frame!]
	cls		[reg-class!]
	return: [integer!]
	/local
		n s flag [integer!]
][
	flag: 0
	n: switch cls [
		class_i32 class_f32 [1]
		class_i64 class_f64 [
			flag: FRAME_SLOT_64
			8 / f/slot-size
		]
		default [1]
	]
	s: f/cc/reg-set/spill-start + f/spill-vars
	f/spill-vars: f/spill-vars + n
	s or flag
]

frame-tmp-slot: func [
	f		[frame!]
	cls		[reg-class!]
	return: [integer!]
	/local
		s flag [integer!]
][
	flag: either any [cls = class_i64 cls = class_f64][FRAME_SLOT_64][0]
	if f/tmp-slot < 0 [
		s: f/cc/reg-set/spill-start + f/spill-vars
		f/spill-vars: f/spill-vars + 2
	]
	f/tmp-slot: s
	s or flag
]

alloc-slot: func [
	f		[frame!]
	v		[vreg!]
][
	if zero? v/spill [v/spill: frame-alloc-slot f v/reg-class]
]

frame-slot-64?: func [
	s		[integer!]
	return: [logic!]
][
	s and FRAME_SLOT_64 <> 0
]

compute-frame-size: func [
	f		[frame!]
	return: [integer!]
	/local
		slots	[integer!]
		sz		[integer!]
][
	slots: f/spill-vars + f/spill-args
	sz: slots * f/slot-size + (target/addr-size * INIT_FRAME_SLOTS)
	sz: align-up sz f/align
	f/size: sz
	sz
]

alloc-caller-space: func [
	f		[frame!]
	cc		[call-conv!]
][
	if cc/n-spilled > f/spill-args [
		f/spill-args: cc/n-spilled
	]
]

#define START_INSERTION [
	saved-i: cg/cur-i
	compute-lv?: cg/compute-liveness?
	cg/compute-liveness?: false
	cg/cur-i: next-i
]

#define END_INSERTION [
	cg/compute-liveness?: compute-lv?
	cg/cur-i: saved-i
]

#include %block-order.reds

backend: context [
	int-imm-caches: as ptr-array! 0
	imm-false:		as immediate! 0
	imm-true:		as immediate! 0
	used-labels:	as list! 0

	label-ref!: alias struct! [
		label	[label!]
		ref		[integer!]
	]

	#include %x86/codegen.reds
	#include %simple-reg-alloc.reds
	#include %global-reg-alloc.reds

	remove-instr: func [		;-- remove mach-instr! x
		x		[mach-instr!]
	][
		if x/prev <> null [x/prev/next: x/next]
		if x/next <> null [x/next/prev: x/prev]
		x/prev: null
		x/next: null	
	]

	collect-pmove-dests: func [
		i		[mach-instr!]
		dests	[vector!]
		/local
			p	[ptr-ptr!]
			pp	[ptr-ptr!]
			n	[integer!]
			d	[def!]
			l	[list!]
			u	[use!]
			v	[vreg!]
			idx [integer!]
	][
		vector/clear dests
		p: as ptr-ptr! i + 1
		n: i/num / 2
		pp: p + n
		loop n [
			d: as def! p/value	
			u: as use! pp/value
			v: u/vreg
			either v/pmove <= 0 [
				v/pmove: dests/length / 2 + 1
				vector/append-ptr dests as byte-ptr! v
				vector/append-ptr dests as byte-ptr! make-list as int-ptr! d null
			][
				idx: (v/pmove - 1) * 2 + 1
				l: as list! vector/pick-ptr dests idx	;-- def list
				vector/poke-ptr dests idx as int-ptr! make-list as int-ptr! d l
			]
			p: p + 1
			pp: pp + 1
		]
	]

	insert-restore-var: func [
		cg		[codegen!]
		v		[vreg!]			;-- from
		reg		[integer!]		;-- to
		next-i	[mach-instr!]
		/local
			saved-i		[mach-instr!]
			compute-lv?	[logic!]
	][
		START_INSERTION
		target/gen-restore-var cg v reg
		END_INSERTION
	]

	insert-save-var: func [
		cg		[codegen!]
		reg		[integer!]		;-- from
		v		[vreg!]			;-- to
		next-i	[mach-instr!]
		/local
			saved-i		[mach-instr!]
			compute-lv?	[logic!]
	][
		START_INSERTION
		target/gen-save-var cg v reg
		END_INSERTION
	]

	insert-lea-loc: func [		;-- lea from loc to loc
		cg		[codegen!]
		arg		[move-arg!]
		next-i	[mach-instr!]
		/local
			saved-i		[mach-instr!]
			compute-lv?	[logic!]
	][
		START_INSERTION
		target/gen-lea-loc cg arg
		END_INSERTION
	]

	insert-move-loc: func [		;-- move from loc to loc
		cg		[codegen!]
		arg		[move-arg!]
		next-i	[mach-instr!]
		/local
			saved-i		[mach-instr!]
			compute-lv?	[logic!]
	][
		START_INSERTION
		target/gen-move-loc cg arg
		END_INSERTION
	]

	insert-move-imm: func [		;-- move from vreg to loc
		cg		[codegen!]
		arg		[move-arg!]
		next-i	[mach-instr!]
		/local
			saved-i		[mach-instr!]
			compute-lv?	[logic!]
	][
		START_INSERTION
		target/gen-move-imm cg arg
		END_INSERTION
	]

	insert-reload: func [
		cg		[codegen!]
		arg		[move-arg!]
		next-i	[mach-instr!]
		/local
			saved-i		[mach-instr!]
			compute-lv?	[logic!]
	][
		START_INSERTION
		emit-instr2 cg I_RELOAD make-def arg/dst-v arg/dst-reg make-use arg/src-v 0
		END_INSERTION
	]

	insert-restore: func [
		cg		[codegen!]
		arg		[move-arg!]
		next-i	[mach-instr!]
		/local
			saved-i		[mach-instr!]
			compute-lv?	[logic!]
	][
		START_INSERTION
		emit-instr2 cg I_RESTORE make-def arg/dst-v arg/dst-reg make-use null arg/src-reg
		END_INSERTION
	]

	init-reg-set: func [
		s		[reg-set!]
		/local
			p	[ptr-ptr!]
			ps	[int-array!]
			pp	[int-ptr!]
			i	[integer!]
			len [integer!]
			map [bit-table!]
	][
		len: s/regs/length
		map: bit-table/make s/n-regs + 1 len
		p: ARRAY_DATA(s/regs)
		i: 0
		while [i < len][
			ps: as int-array! p/value
			if ps <> null [
				pp: as int-ptr! ARRAY_DATA(ps)
				loop ps/length [
					bit-table/set map pp/value i
					pp: pp + 1
				]
			]
			p: p + 1
			i: i + 1
		]
		s/caller-base: CALLER_SPILL_BASE
		s/callee-base: CALLEE_SPILL_BASE
		s/bitmap: map
	]

	in-reg-set?: func [
		s		[reg-set!]
		reg-idx	[integer!]
		set-idx	[integer!]
		return: [logic!]
	][
		if any [reg-idx < 1 reg-idx >= s/regs/length][
			return false
		]
		bit-table/pick s/bitmap reg-idx set-idx
	]

	is-reg?: func [
		s	[reg-set!]
		i	[integer!]
		return: [logic!]
	][
		all [i > 0 i <= s/n-regs]
	]

	is-reg-set?: func [
		s	[reg-set!]
		i	[integer!]
		return: [logic!]
	][
		all [i > 0 i <= s/regs/length]
	]
	
	on-stack?: func [
		s		[reg-set!]
		i		[integer!]
		return: [logic!]
	][
		i >= s/spill-start
	]

	on-caller-stack?: func [
		i		[integer!]
		return: [logic!]
	][
		i: i and (not FRAME_SLOT_64)
		all [i >= CALLER_SPILL_BASE i < CALLEE_SPILL_BASE]
	]

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
		imm-false: make-imm-bool false
		imm-true: make-imm-bool true
	]

	#define CALC_REG_INDEX(base) [
		either idx <= cc/reg-set/n-regs [idx][
			idx - cc/reg-set/frame-start + base
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
				either w > 32 [class_i64][class_i32]
			]
			RST_TYPE_VOID
			RST_TYPE_LOGIC [class_i32]
			RST_TYPE_FLOAT [
				either FLOAT_64?(type) [class_f64][class_f32]
			]
			RST_TYPE_FUNC
			RST_TYPE_ARRAY
			RST_TYPE_PTR [class_i32]
			RST_TYPE_STRUCT [
				either NOT_STRUCT_VALUE?(type) [class_i32][class_struct]
			]
			default [class_i32]
		]
	]

	update-usage: func [
		reg		[vreg!]
	][
		if vreg-const?(reg) [exit]		;-- constant value
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

	make-imm: func [
		val		[cell!]
		return: [immediate!]
		/local
			i	[immediate!]
	][
		i: xmalloc(immediate!)
		i/header: OD_IMM
		i/value: val
		i
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
		i/value: as cell! int
		i
	]

	make-imm-bool: func [
		bool	[logic!]
		return: [immediate!]
		/local
			i	[immediate!]
			b	[red-logic!]
	][
		i: xmalloc(immediate!)
		i/header: OD_IMM
		b: xmalloc(red-logic!)
		b/header: TYPE_LOGIC
		b/value: bool
		i/value: as cell! b
		i
	]

	any-reg: func [
		cg		[codegen!]
		v		[vreg!]
		return: [integer!]
		/local
			p	[int-ptr!]
	][
		p: cg/reg-set/regs-cls + v/reg-class	;-- any regs in this class
		p/value
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
		l/index: cg/nlivepoints
		l/cc: cc
		cg/nlivepoints: cg/nlivepoints + 1
		vector/append-ptr cg/operands as byte-ptr! l
	]

	overwrite-reg: func [
		cg		[codegen!]
		dst		[instr!]
		src		[instr!]
		/local
			dreg [vreg!]
			sreg [vreg!]
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

	overwrite-reg-fixed: func [
		cg		[codegen!]
		dst		[instr!]
		src		[instr!]
		c		[integer!]		;-- constraint
		/local
			dreg [vreg!]
			sreg [vreg!]
	][
		dreg: get-vreg cg dst
		assert dreg <> null
		sreg: get-vreg cg src
		assert sreg <> null
		update-usage sreg
		vector/append-ptr cg/operands as byte-ptr! make-overwrite dreg sreg c
	]

	overwrite-vreg: func [
		cg		[codegen!]
		dst		[vreg!]
		src		[vreg!]
		c		[integer!]		;-- constraint
	][
		update-usage src
		vector/append-ptr cg/operands as byte-ptr! make-overwrite dst src c
	]

	use-special: func [
		cg			[codegen!]
		i			[instr!]
		reg			[integer!]
		/local
			u		[use!]
	][
		u: make-use get-vreg cg i reg
		u/header: OD_REG
		vector/append-ptr cg/operands as byte-ptr! u
	]

	use-vreg-special: func [
		cg			[codegen!]
		vreg		[vreg!]
		reg			[integer!]
		/local
			u		[use!]
	][
		u: make-use vreg reg
		u/header: OD_REG
		vector/append-ptr cg/operands as byte-ptr! u
	]

	def-reg-fixed: func [
		cg			[codegen!]
		i			[instr!]
		constraint	[integer!]
		return:		[def!]
		/local
			v		[vreg!]
			d		[def!]
	][
		v: get-vreg cg i
		either constraint < cg/reg-set/n-regs [v/hint: constraint][v/hint: 0]
		d: make-def v constraint
		vector/append-ptr cg/operands as byte-ptr! d
		d
	]

	def-reg: func [
		cg		[codegen!]
		i		[instr!]
		return: [def!]
		/local
			v	[vreg!]
			p	[int-ptr!]
			d	[def!]
	][
		v: get-vreg cg i
		p: cg/reg-set/regs-cls + v/reg-class	;-- any regs in this class
		d: make-def v p/value
		vector/append-ptr cg/operands as byte-ptr! d
		d
	]

	def-i: func [
		cg		[codegen!]
		i		[instr!]
		/local
			v	[vreg!]
			p	[int-ptr!]
	][
		v: get-vreg cg i
		vector/append-ptr cg/operands as byte-ptr! make-def v 0
	]

	def-vreg: func [
		cg			[codegen!]
		vreg		[vreg!]
		constraint	[integer!]
	][
		if vreg <> null [
			vreg/hint: either constraint < cg/reg-set/n-regs [constraint][0]
		]
		vector/append-ptr cg/operands as byte-ptr! make-def vreg constraint
	]

	use-i: func [
		cg		[codegen!]
		i		[instr!]
		/local
			v	[vreg!]
	][
		v: get-vreg cg i
		if null? v [exit]
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
		if null? v [exit]
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
		if null? v [exit]
		update-usage v
		vector/append-ptr cg/operands as byte-ptr! make-use v c
	]

	use-vreg: func [
		cg			[codegen!]
		v			[vreg!]
		constraint	[integer!]
	][
		update-usage v
		vector/append-ptr cg/operands as byte-ptr! make-use v constraint
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
		i/value: val
		vector/append-ptr cg/operands as byte-ptr! i	
	]

	use-ptr: func [
		cg		[codegen!]
		p		[int-ptr!]
		/local
			f	[val!]
	][
		f: xmalloc(val!)
		f/header: TYPE_FUNCTION
		f/ptr: p
		use-imm cg as cell! f
	]

	use-bool: func [
		cg		[codegen!]
		bool	[logic!]
		/local
			i	[immediate!]
	][
		i: either bool [imm-true][imm-false]
		vector/append-ptr cg/operands as byte-ptr! i
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

		if cg/compute-liveness? [update-liveness cg i]
	]

	emit-instr2: func [
		cg		[codegen!]
		op		[integer!]
		o1		[def!]
		o2		[use!]
	][
		put-operand(o1)
		put-operand(o2)
		emit-instr cg op
	]

	update-liveness: func [
		cg		[codegen!]
		i		[mach-instr!]
		/local
			row	[integer!]
			p	[ptr-ptr!]
			o	[operand!]
			d	[def!]
			u	[use!]
			w	[overwrite!]
			lp	[livepoint!]
			idx [integer!]
			lv	[bit-table!]
			v	[vector!]
	][
		row: either cg/cur-blk <> null [cg/cur-blk/mark][0]
		p: as ptr-ptr! i + 1
		lv: cg/liveness
		loop i/num [
			o: as operand! p/value
			switch o/header and FFh [
				OD_DEF [
					d: as def! o
					bit-table/clear lv row d/vreg/idx
				]
				OD_USE		[
					u: as use! o
					bit-table/set lv row u/vreg/idx
				]
				OD_OVERWRITE [
					w: as overwrite! o
					bit-table/clear lv row w/dst/idx
					bit-table/set lv row w/src/idx
				]
				OD_LIVEPOINT [
					lp: as livepoint! o
					if lp/index >= 0 [
						idx: cg/blocks/length + lp/index
						bit-table/grow-row lv idx + 1
						bit-table/or-rows lv idx row
						v: cg/livepoints
						vector/append-ptr v as byte-ptr! cg/cur-blk
						vector/append-ptr v as byte-ptr! i
						vector/append-ptr v as byte-ptr! o
					]
				]
				default [0]
			]
			p: p + 1
		]
	]

	make-codegen: func [
		fn		[ir-fn!]
		rpo		[rpo!]
		frame	[frame!]
		return: [codegen!]
		/local
			cg	[codegen!]
			f	[fn!]
	][
		cg: xmalloc(codegen!)
		f: fn/fn
		cg/fixed-stack?: NODE_FLAGS(f) and RST_DYN_ALLOC = 0
		cg/operands: ptr-vector/make 4
		cg/vregs: ptr-vector/make 8
		cg/fn: fn
		cg/frame: frame
		cg/rpo: rpo
		cg/blocks: rpo/blocks
		cg/instrs: ptr-vector/make rpo/blocks/length
		cg/liveness: bit-table/make rpo/blocks/length 32
		cg/reg-set: frame/cc/reg-set
		cg/livepoints: ptr-vector/make 6
		cg/compute-liveness?: yes
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
				type: instr-type? i
				cls: reg-class? type
				if cls = class_struct [cls: class_i32]
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
		v/stack-idx: -2
		vector/poke-ptr vregs idx as int-ptr! v
		if all [i <> null INSTR_CONST?(i)][
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
			probe ["get vreg error: invalid instr mark " i/mark " " cg/fn/mark]
			assert 1 = 0
			halt
		]
		;ir-printer/print-instr i
		if INSTR_FLAGS(i) and F_NOT_VOID = 0 [return null]

		either i/mark <= cg/mark [
			make-vreg cg i
		][
			as vreg! vector/pick-ptr cg/vregs i/mark - cg/mark
		]
	]

	make-tmp-vreg: func [
		cg		[codegen!]
		t		[rst-type!]
		return: [vreg!]
		/local
			v	[vreg!]
	][
		v: make-vreg cg null
		v/reg-class: reg-class? t
		v
	]

	gen-phi-moves: func [
		cg		[codegen!]
		edge	[cf-edge!]
		/local
			i	[instr!]
			ii	[instr!]
			idx [integer!]
	][
		i: edge/dst/next
		idx: edge/dst-idx
		while [all [i <> null INSTR_PHI?(i)]][
			ii: instr-input i idx
			if ii <> null [def-i cg i]
			i: i/next
		]

		i: edge/dst/next
		while [all [i <> null INSTR_PHI?(i)]][
			ii: instr-input i idx
			if ii <> null [use-i cg ii]
			i: i/next
		]
		emit-instr cg I_PMOVE
	]

	gen-return: func [
		cg		[codegen!]
		blk		[basic-block!]
		i		[instr!]
		/local
			n	[integer!]
			p	[ptr-ptr!]
			e	[df-edge!]
			cc	[call-conv!]
	][
		cc: cg/frame/cc
		n: 0
		p: ARRAY_DATA(i/inputs)
		loop i/inputs/length [
			e: as df-edge! p/value
			use-reg-fixed cg e/dst caller-ret cc n
			p: p + 1
			n: n + 1
		]
		emit-instr cg I_RET
	]

	select-instr: func [
		cg			[codegen!]
		blk			[basic-block!]
		i			[instr!]
		/local
			g		[instr-goto!]
			p		[ptr-ptr!]
	][
		;ir-printer/print-instr i print lf
		switch INSTR_OPCODE(i) [
			INS_IF		[target/gen-if cg blk i]
			INS_GOTO	[
				g: as instr-goto! i
				p: ARRAY_DATA(g/succs)
				gen-phi-moves cg as cf-edge! p/value
				target/gen-goto cg blk i
			]
			INS_RETURN	[gen-return cg blk i]
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
			if any [
				instr-live? cg i blk
				INSTR_NOT_PURE?(i)
			][
				select-instr cg blk i
				cg/cur-i: cg/first-i
			]
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

	instr-live?: func [
		cg		[codegen!]
		i		[instr!]
		blk		[basic-block!]
		return: [logic!]
	][
		assert i/mark < cg/fn/mark

		either i/mark <= cg/mark [false][
			bit-table/pick cg/liveness blk/mark i/mark - cg/mark
		]
	]

	gen-params: func [
		cg		[codegen!]
		blk		[basic-block!]
		/local
			arr [ptr-array!]
			pp	[ptr-ptr!]
			i	[instr!]
			n	[integer!]
			idx [integer!]
			cnt [integer!]
			v	[vreg!]
			ft	[fn-type!]
			ty	[rst-type!]
			p	[ptr-ptr!]
			d	[def!]
			op	[integer!]
			st? [logic!]
			p-idx [int-ptr!]
	][
		ft: as fn-type! cg/fn/fn/type
		p-idx: ft/arg-idx
		arr: cg/fn/params
		cnt: arr/length
		pp: ARRAY_DATA(arr)
		ty: ft/ret-type
		n: 0
		if all [STRUCT_VALUE?(ty) 8 < type-size? ty yes][
			i: as instr! pp/value
			v: get-vreg cg i
			idx: caller-param cg/frame/cc 0
			def-reg-fixed cg i idx
			if idx >= cg/reg-set/spill-start [v/spill: idx]
			n: 1
			pp: pp + 1
			cnt: cnt - 1
			if p-idx <> null [p-idx: p-idx + 1]
		]
		st?: no
		p: ft/param-types
		loop cnt [
			if p-idx <> null [
				ty: as rst-type! p/value
				st?: STRUCT_VALUE?(ty)
				n: p-idx/value
				p-idx: p-idx + 1
			]
			i: as instr! pp/value
			;if instr-live? cg i blk [
			idx: caller-param cg/frame/cc n
			d: def-reg-fixed cg i idx
			if all [not st? idx >= cg/reg-set/spill-start][
				v: get-vreg cg i
				v/spill: idx
			]
			;]
			n: n + 1
			pp: pp + 1
		]
		emit-instr cg I_ENTRY

		if p-idx <> null [
			p-idx: ft/arg-idx
			cnt: arr/length
			pp: ARRAY_DATA(arr)
			p: ft/param-types
			ty: ft/ret-type
			if all [STRUCT_VALUE?(ty) 8 < type-size? ty yes][
				pp: pp + 1
				cnt: cnt - 1
				p-idx: p-idx + 1
			]
			loop cnt [
				n: p-idx/value
				p-idx: p-idx + 1
				ty: as rst-type! p/value
				if STRUCT_VALUE?(ty) [
					i: as instr! pp/value
					def-reg cg i
					op: either target/arch = arch-x86 [I_LEAD][I_LEAQ]
					op: op or AM_REG_OP
					use-reg-fixed cg i caller-param cg/frame/cc n
					emit-instr cg op
				]
				p: p + 1
				pp: pp + 1
			]
		]
	]

	process-loop-liveness: func [
		cg		[codegen!]
		info	[block-info!]
		/local
			end	[integer!]
			p	[ptr-ptr!]
			len [integer!]
			i	[integer!]
			blk [basic-block!]
			lv	[livepoint!]
			tbl [bit-table!]
			v	[vector!]
			nblk [integer!]
			cur-mark [integer!]
			cur-blk [basic-block!]
	][
		nblk: cg/blocks/length
		cur-blk: info/block
		cur-mark: cur-blk/mark
		end: info/loop-info/end
		tbl: cg/liveness
		v: cg/livepoints
		p: as ptr-ptr! ptr-vector/tail v
		len: v/length / 3
		loop len [
			p: p - 1
			lv: as livepoint! p/value
			p: p - 2
			blk: as basic-block! p/value

			if blk/mark >= end [break]
			bit-table/or-rows tbl nblk + lv/index cur-mark
		]

		;-- propagate the liveness to all blocks in this loop
		i: cur-mark + 1
		while [i < end][
			bit-table/or-rows tbl i cur-mark
			i: i + 1
		]
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
		;bit-table/render cg/liveness

		p: VECTOR_DATA(cg/blocks)
		len: cg/blocks/length
		p: p + len
		while [len > 0][
			len: len - 1
			p: p - 1
			info: as block-info! p/value
			blk: info/block
			gather-liveness cg blk
			select-instrs cg blk
			if info/loop-info <> null [
				process-loop-liveness cg info
			]
			vector/poke-ptr cg/instrs len as int-ptr! cg/first-i
		]
		gen-params cg blk
		;bit-table/render cg/liveness
		cg/cur-i: cg/first-i
	]

	assemble-instrs: func [
		cg		[codegen!]
		/local
			i	[mach-instr!]
			pos [integer!]
	][
		pos: program/code-buf/length	;-- func position in code-buf
		cg/compute-liveness?: no
		i: cg/first-i
		while [i <> null][
			cg/cur-i: i/next
			target/assemble cg i
			i: i/next
		]
		cg/mark: pos
	]

	patch-labels: func [
		/local
			l	[list!]
			r	[label-ref!]
			pos [integer!]
			p	[byte-ptr!]
	][
		l: used-labels
		p: program/code-buf/data
		while [l <> null][
			r: as label-ref! l/head
			pos: r/ref
			change-at-32 p pos r/label/pos - pos - 4
			l: l/tail
		]
		used-labels: null
	]

	generate: func [
		fn		[ir-fn!]
		return: [codegen!]
		/local
			frm	[frame!]
			r	[rpo!]
			cg	[codegen!]
			pos [integer!]
	][
		frm: target/make-frame fn
		r: rpo/build fn
		cg: make-codegen fn r frm

		dprint "=> Generating low-level IR"
		gen-instrs cg
		if verbose >= 3 [print-fn cg/first-i]

		dprint "=> Do register allocation"
		simple-reg-alloc/alloc cg
		if verbose >= 3 [print-fn cg/first-i]

		compute-frame-size frm
		cg
	]

	record-label: func [
		l		[label!]
		pos		[integer!]
		/local
			r	[label-ref!]
	][
		r: xmalloc(label-ref!)
		r/label: l
		r/ref: pos
		used-labels: make-list as int-ptr! r used-labels
	]

	record-fn-call: func [
		f		[fn!]
		pos		[integer!]
		/local
			fn	[import-fn!]
			v	[red-handle!]
			fmap [int-ptr!]
			refs [vector!]
	][
		either NODE_FLAGS(f) and RST_IMPORT_FN <> 0 [
			fn: as import-fn! f
			v: token-map/get program/imports fn/import-lib no
			either v <> null [
				fmap: as int-ptr! v/value
			][
				fmap: token-map/make 50
				token-map/put program/imports fn/import-lib fmap
			]
			v: token-map/get fmap fn/import-name yes
			either v <> null [
				refs: as vector! v/value
			][
				refs: vector/make size? integer! 2
				token-map/put fmap fn/import-name as int-ptr! refs
			]
		][
			if null? f/body [
				f/body: as red-block! vector/make size? integer! 2
			]
			refs: as vector! f/body	;-- use fn!/body to save the ref idx
		]
		vector/append-int refs pos
	]

	record-fn-ref: func [		;-- for function pointer
		f		[fn!]
		pos		[integer!]
		/local
			refs [vector!]
	][
		if null? f/refs [
			f/refs: vector/make size? integer! 2
		]
		refs: f/refs
		vector/append-int refs pos
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
			val [cell!]
			t	[integer!]
			v	[val!]
			var [var-decl!]
	][
		switch a/header and FFh [
			OD_USE OD_REG [
				prin "use#"
				u: as use! a
				either null? u/vreg [
					prin "null"
				][
					print [u/vreg/idx ":" u/vreg/reg]
				]
				print [":" u/constraint]
			]
			OD_DEF [
				prin "def#"
				d: as def! a
				either null? d/vreg [
					prin "null"
				][
					print [d/vreg/idx ":" d/vreg/reg]
				]
				print [":" d/constraint]
			]
			OD_IMM [
				prin "imm#"
				imm: as immediate! a
				val: imm/value
				if val <> null [
					t: TYPE_OF(val)
					switch t [
						TYPE_INTEGER
						TYPE_FLOAT [prin-token val]
						TYPE_ADDR [
							v: as val! val
							var: as var-decl! v/ptr
							prin-token var/token
						]
						TYPE_FUNCTION [
							v: as val! val
							print v/ptr
						]
						default [
							prin "type:" print t
							prin ":"
							if t < 100 [prin-token val]
							0
						]
					]
				]
			]
			OD_OVERWRITE [
				prin "overwrite dst#"
				o: as overwrite! a
				print o/dst/idx
				print [":" o/constraint]
				prin " src#"
				print o/src/idx
				print [":" o/constraint]
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

	op-name: func [
		i		[mach-instr!]
		return: [c-string!]
	][
		switch MACH_OPCODE(i) [
			I_MOVB			["mov.b"]
			I_MOVBSX		["mov.bsx"]
			I_MOVBZX		["mov.bzx"]
			I_MOVW			["mov.w"]
			I_MOVWSX		["mov.wsx"]
			I_MOVWZX		["mov.wzx"]
			I_JMP			["jmp"]
			I_JC			["jc"]
			I_SETC			["setc"]
			I_CALL			["call"]
			I_GET_PC		["get-pc"]
			I_GET_SP		["get-sp"]
			I_SET_SP		["set-sp"]
			I_CMPB			["cmp.b"]
			I_CATCH			["catch"]
			I_THROW			["throw"]
			I_CMPXCHG8		["cmpxchg8"]
			I_CMPXCHG16		["cmpxchg16"]
			I_CMPXCHG32		["cmpxchg32"]
			I_CMPXCHG64		["cmpxchg64"]
			I_MOVD			["mov.d"]
			I_MOVQ			["mov.q"]
			I_SYSCALL		["syscall"]
			I_ADDD			["add.d"]
			I_ORD			["or.d"]
			I_ADCD			["adc.d"]
			I_ANDD			["and.d"]
			I_SUBD			["sub.d"]
			I_XORD			["xor.d"]
			I_CMPD			["cmp.d"]
			I_MULD			["mul.d"]
			I_NEGD			["neg.d"]
			I_NOTD			["not.d"]
			I_TESTD			["test.d"]
			I_LEAD			["lea.d"]
			I_DIVD			["div.d"]
			I_IDIVD			["idiv.d"]
			I_INCD			["inc.d"]
			I_ADDQ			["add.q"]
			I_ORQ			["or.q"]
			I_ADCQ			["adc.q"]
			I_ANDQ			["and.q"]
			I_SUBQ			["sub.q"]
			I_XORQ			["xor.q"]
			I_CMPQ			["cmp.q"]
			I_MULQ			["mul.q"]
			I_NEGQ			["neg.q"]
			I_NOTQ			["not.q"]
			I_TESTQ			["test.q"]
			I_LEAQ			["lea.q"]
			I_DIVQ			["div.q"]
			I_IDIVQ			["idiv.q"]
			I_INCQ			["inc.q"]
			I_DECD			["dec.d"]
			I_SHLD			["shl.d"]
			I_SARD			["sar.d"]
			I_SHRD			["shr.d"]
			I_CDQ			["cd.q"]
			I_SWITCHD		[".switch"]
			I_ADDSS			["add.ss"]
			I_SUBSS			["sub.ss"]
			I_MULSS			["mul.ss"]
			I_DIVSS			["div.ss"]
			I_SQRTSS		["sort.ss"]
			I_MOVSS			["mov.ss"]
			I_CVTSS2SD		["cvtss2sd"]
			I_PCMPEQD		["pcmpeq.d"]
			I_MOVSS			["movss"]
			I_MOVSD			["movsd"]
			I_UCOMISS		["ucomiss"]
			I_UCOMISD		["ucomisd"]
			I_ENTRY			["entry"]
			I_IMODD			["imod.d"]
			I_IMODQ			["imod.q"]
			I_FSTP			["fstp"]
			I_FUNC_PTR		["func-ptr"]
			I_DATA_PTR		["data-ptr"]
			I_PUSH			["push"]
			I_POP			["pop"]
			I_CVTSS2SD		["cvtss2sd"]
			I_CVTSD2SS		["cvtsd2ss"]
			I_CVTSS2SID I_CVTSS2SIQ ["cvtss2si"]
			I_CVTSD2SID I_CVTSD2SIQ ["cvtsd2si"]
			I_CVTSI2SSD I_CVTSI2SSQ ["cvtsi2ss"]
			I_CVTSI2SDD I_CVTSI2SDQ ["cvtsi2sd"]
			I_PUSH_ALL		["push all"]
			I_POP_ALL		["pop all"]
			I_STACK_ALLOC	["stack/allocate"]
			I_STACK_FREE	["stack/free"]
			I_STACK_ALIGN	["stack/align"]
			default 		[probe ["mach op " MACH_OPCODE(i)] "unknown op"]
		]
	]

	print-op: func [
		i		[mach-instr!]
		ident	[integer!]
		return: [integer!]
	][
		do-i ident
		print op-name i prin " "
		print-operands as ptr-ptr! i + 1 i/num
		ident
	]

	print-instr: func [
		i		[mach-instr!]
		ident	[integer!]
		return: [integer!]
		/local
			a b	[ptr-ptr!]
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
			I_PMOVE		[
				do-i ident + 1 prin "parallel move"
				n: n / 2
				b: a + n
				loop n [
					print lf
					do-i ident + 2
					prin-operand as operand! a/value
					prin " <- "
					a: a + 1
					prin-operand as operand! b/value
					b: b + 1
				]
			]
			default 	[ident: -1 + print-op i ident + 1]
		]
		print lf
		ident
	]

	print-fn: func [
		start-i	[mach-instr!]
		/local
			i	[mach-instr!]
			ident [integer!]
	][
		i: start-i
		ident: 1
		while [i <> null][
			ident: print-instr i ident
			i: i/next
		]
		print lf
	]
]