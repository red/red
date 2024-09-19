Red/System [
	File: 	 %codegen.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define x86_EAX			1
#define x86_ECX			2
#define x86_EDX			3
#define x86_EBX			4
#define x86_ESP			5
#define x86_EBP			6
#define x86_ESI			7
#define x86_EDI			8
#define x86_XMM0		9
#define x86_XMM1		10
#define x86_XMM2		11
#define x86_XMM3		12
#define x86_XMM4		13
#define x86_XMM5		14
#define x86_XMM6		15
#define x86_XMM7		16
#define x86_GPR			17
#define x86_BYTE		18
#define x86_EAX_EDX		19
#define x86_NOT_EDX		20
#define x86_NOT_ECX		21
#define x86_CLS_GPR		22
#define x86_CLS_SSE		23
#define x86_REG_ALL		24
#define x86_SCRATCH		x86_EBP
#define SSE_SCRATCH		x86_XMM7

;-- REG: GPR
;-- OP: register or stack
;-- XOP: XMM register or stack
;-- RRSD: [Reg + Reg * Scale + Disp]
#enum x86-addr-mode! [
	_AM_NONE
	_AM_REG_OP
	_AM_RRSD_REG
	_AM_RRSD_IMM
	_AM_REG_RRSD
	_AM_OP
	_AM_OP_IMM
	_AM_OP_REG
	_AM_XMM_REG
	_AM_XMM_OP
	_AM_OP_XMM
	_AM_XMM_RRSD
	_AM_RRSD_XMM
	_AM_XMM_IMM 
	_AM_REG_XOP
	_AM_XMM_XMM
]

#define AM_SHIFT	10
#define COND_SHIFT	15
#define ROUND_SHIFT	19

#define x86_COND(i)		[i >> COND_SHIFT and 0Fh]

;-- x86-addr-mode! left-shift by AM_SHIFT
#define AM_NONE			0
#define AM_REG_OP		0400h
#define AM_RRSD_REG		0800h
#define AM_RRSD_IMM		0C00h
#define AM_REG_RRSD		1000h
#define AM_OP			1400h
#define AM_OP_IMM		1800h
#define AM_OP_REG		1C00h
#define AM_XMM_REG		2000h
#define AM_XMM_OP		2400h
#define AM_OP_XMM		2800h
#define AM_XMM_RRSD		2C00h
#define AM_RRSD_XMM		3000h
#define AM_XMM_IMM 		3400h
#define AM_REG_XOP		3800h
#define AM_XMM_XMM		3C00h

x86-cond!: alias struct! [
	index		[integer!]
	negate		[x86-cond!]
	commute		[x86-cond!]
]

x86-cond-pair!: alias struct! [
	and?		[logic!]
	cond1		[x86-cond!]
	cond2		[x86-cond!]
]

x86-cond: context [
	overflow:		as x86-cond! 0
	not-overflow:	as x86-cond! 0
	carry:			as x86-cond! 0
	not-carry:		as x86-cond! 0
	zero:			as x86-cond! 0
	not-zero:		as x86-cond! 0
	aux-carry:		as x86-cond! 0
	not-aux-carry:	as x86-cond! 0
	sign:			as x86-cond! 0
	not-sign:		as x86-cond! 0
	parity:			as x86-cond! 0
	not-parity:		as x86-cond! 0
	lesser:			as x86-cond! 0
	lesser-eq:		as x86-cond! 0
	greater:		as x86-cond! 0
	greater-eq:		as x86-cond! 0

	make: func [
		idx		[integer!]
		return: [x86-cond!]
		/local
			c	[x86-cond!]
	][
		c: xmalloc(x86-cond!)
		c/index: idx
		c
	]

	make-pair: func [
		c1		[x86-cond!]
		c2		[x86-cond!]
		and?	[logic!]
		return: [x86-cond-pair!]
		/local
			p	[x86-cond-pair!]
	][
		p: xmalloc(x86-cond-pair!)
		p/and?: and?
		p/cond1: c1
		p/cond2: c2
		p
	]

	pair-neg: func [
		p		[x86-cond-pair!]
		return: [x86-cond-pair!]
	][
		either p/cond2 <> null [
			make-pair p/cond1/negate p/cond2/negate not p/and?
		][
			make-pair p/cond1/negate null false
		]
	]

	neg: func [
		a		[x86-cond!]
		b		[x86-cond!]
	][
		a/negate: b
		b/negate: a
	]

	commute: func [
		a		[x86-cond!]
		b		[x86-cond!]
	][
		a/commute: b
		b/commute: a
	]
	
	init: does [
		overflow:		make 0
		not-overflow:	make 1
		carry:			make 2
		not-carry:		make 3
		zero:			make 4
		not-zero:		make 5
		not-aux-carry:	make 6
		aux-carry:		make 7
		sign:			make 8
		not-sign:		make 9
		parity:			make 10
		not-parity:		make 11
		lesser:			make 12
		greater-eq:		make 13
		lesser-eq:		make 14
		greater:		make 15

		;-- relations
		neg overflow not-overflow
		neg carry not-carry
		neg zero not-zero
		neg sign not-sign
		neg parity not-parity
		neg lesser greater-eq
		neg greater lesser-eq
		commute zero zero
		commute not-zero not-zero
		commute lesser greater
		commute lesser-eq greater-eq
		commute not-aux-carry not-carry
		commute aux-carry carry
	]
]

x86-reg-set: context [
	reg-set: as reg-set! 0

	a1:  [x86_EAX]
	a2:  [x86_EBX]
	a3:  [x86_ECX]
	a4:  [x86_EDX]
	a5:  [x86_ESI]
	a6:  [x86_EDI]
	a7:  [x86_XMM0]
	a8:  [x86_XMM1]
	a9:  [x86_XMM2]
	a10: [x86_XMM3]
	a11: [x86_XMM4]
	a12: [x86_XMM5]
	a13: [x86_XMM6]
	a14: [x86_EAX x86_EBX x86_ECX x86_EDX x86_ESI x86_EDI]
	a15: [x86_EDX x86_ECX x86_EAX x86_EBX]
	a16: [x86_EAX x86_EDX]
	a17: [x86_EAX x86_EBX x86_ECX x86_ESI x86_EDI]
	a18: [x86_EAX x86_EBX x86_EDX x86_ESI x86_EDI]
	a19: [x86_EAX x86_ECX x86_EDX x86_EBX x86_ESI x86_EDI]
	a20: [x86_XMM0 x86_XMM1 x86_XMM2 x86_XMM3 x86_XMM4 x86_XMM5 x86_XMM6]
	a21: [
		x86_EAX x86_EBX x86_ECX x86_EDX x86_ESI x86_EDI
		x86_XMM0 x86_XMM1 x86_XMM2 x86_XMM3 x86_XMM4 x86_XMM5 x86_XMM6
	]

	make-array: func [
		data	[int-ptr!]
		len		[integer!]
		return: [int-array!]
		/local
			arr [int-array!]
			p	[int-ptr!]
	][
		arr: int-array/make len
		p: as int-ptr! ARRAY_DATA(arr)
		loop len [
			p/value: data/value
			p: p + 1
			data: data + 1
		]
		arr
	]

	#define gpr-reg?(idx) [
		all [x86_EAX <= idx idx <= x86_EDI]
	]

	#define sse-reg?(idx) [
		all [x86_XMM0 <= idx idx <= x86_XMM7]
	]

	init: func [/local s [reg-set!] arr [ptr-array!] p pa [ptr-ptr!] pp [int-ptr!]][
		arr: ptr-array/make x86_REG_ALL + 1
		p: ARRAY_DATA(arr)
		pa: p + x86_EAX
		pa/value: as int-ptr! make-array a1 size? a1
		pa: p + x86_EBX
		pa/value: as int-ptr! make-array a2 size? a2
		pa: p + x86_ECX
		pa/value: as int-ptr! make-array a3 size? a3
		pa: p + x86_EDX
		pa/value: as int-ptr! make-array a4 size? a4
		pa: p + x86_ESI
		pa/value: as int-ptr! make-array a5 size? a5
		pa: p + x86_EDI
		pa/value: as int-ptr! make-array a6 size? a6
		pa: p + x86_XMM0
		pa/value: as int-ptr! make-array a7 size? a7
		pa: p + x86_XMM1
		pa/value: as int-ptr! make-array a8 size? a8
		pa: p + x86_XMM2
		pa/value: as int-ptr! make-array a9 size? a9
		pa: p + x86_XMM3
		pa/value: as int-ptr! make-array a10 size? a10
		pa: p + x86_XMM4
		pa/value: as int-ptr! make-array a11 size? a11
		pa: p + x86_XMM5
		pa/value: as int-ptr! make-array a12 size? a12
		pa: p + x86_XMM6
		pa/value: as int-ptr! make-array a13 size? a13
		pa: p + x86_GPR
		pa/value: as int-ptr! make-array a14 size? a14
		pa: p + x86_BYTE
		pa/value: as int-ptr! make-array a15 size? a15
		pa: p + x86_EAX_EDX
		pa/value: as int-ptr! make-array a16 size? a16
		pa: p + x86_NOT_EDX
		pa/value: as int-ptr! make-array a17 size? a17
		pa: p + x86_NOT_ECX
		pa/value: as int-ptr! make-array a18 size? a18
		pa: p + x86_CLS_GPR
		pa/value: as int-ptr! make-array a19 size? a19
		pa: p + x86_CLS_SSE
        pa/value: as int-ptr! make-array a20 size? a20
		pa: p + x86_REG_ALL
        pa/value: as int-ptr! make-array a21 size? a21

        pa: p + x86_SCRATCH
        pa/value: as int-ptr! empty-array
        pa: p + SSE_SCRATCH
        pa/value: as int-ptr! empty-array
        pa: p + x86_ESP
        pa/value: as int-ptr! empty-array

		s: xmalloc(reg-set!)
		s/n-regs: 16
		s/regs: arr
		s/spill-start: arr/length
		s/gpr-scratch: x86_SCRATCH
		s/sse-scratch: SSE_SCRATCH

		pp: as int-ptr! malloc 4 * size? integer!
		pp/1: x86_CLS_GPR
		pp/2: x86_CLS_GPR
		pp/3: x86_CLS_SSE
		pp/4: x86_CLS_SSE
		s/regs-cls: pp

		pp: as int-ptr! malloc 4 * size? integer!
		pp/1: x86_SCRATCH
		pp/2: x86_SCRATCH
		pp/3: SSE_SCRATCH
		pp/4: SSE_SCRATCH
		s/scratch: pp

		init-reg-set s
		reg-set: s
	]
]

x86-rs-cc: context [	;-- red/system internal call-conv!
	param-regs: [x86_EDI x86_EAX x86_EDX x86_ECX x86_ESI]
	ret-regs: [x86_EAX x86_EDX]
	float-params: [x86_XMM0 x86_XMM1 x86_XMM2 x86_XMM3 x86_XMM4 x86_XMM5 x86_XMM6]
	float-rets: [x86_XMM0 x86_XMM1]
	
	make: func [
		fn		[fn!]
		return: [call-conv!]
		/local
			spill-start [integer!]
			n-params	[integer!]
			param-locs	[rs-array!]
			ret-locs	[rs-array!]
			p			[ptr-ptr!]
			ploc rloc	[int-ptr!]
			cls			[reg-class!]
			i			[integer!]
			i-idx f-idx [integer!]
			p-spill		[integer!]
			r-spill		[integer!]
			cc			[call-conv!]
			ft			[fn-type!]
	][
		if fn/cc <> null [return fn/cc]

		ft: as fn-type! fn/type
		spill-start: x86-reg-set/reg-set/spill-start
		n-params: ft/n-params
		param-locs: int-array/make n-params
		ploc: as int-ptr! ARRAY_DATA(param-locs)

		;-- locations of each parameter
		p-spill: 0 i-idx: 0 f-idx: 0 i: 1
		p: ft/param-types
		loop n-params [
			cls: reg-class? as rst-type! p/value
			switch cls [
				class_i32 [
					either i-idx < size? param-regs [
						i-idx: i-idx + 1
						ploc/i: param-regs/i-idx
					][
						ploc/i: spill-start + p-spill
						p-spill: p-spill + 1
					]
				]
				class_f32 [
					either f-idx < size? float-params [
						f-idx: f-idx + 1
						ploc/i: float-params/f-idx
					][
						ploc/i: spill-start + p-spill
						p-spill: p-spill + 1
					]
				]
				class_f64 [
					either f-idx < size? float-params [
						f-idx: f-idx + 1
						ploc/i: float-params/f-idx
					][
						ploc/i: spill-start + p-spill
						p-spill: p-spill + 2
					]
				]
				class_i64 [
					ploc/i: spill-start + p-spill
					p-spill: p-spill + 2
				]
			]
			i: i + 1
			p: p + 1
		]

		;-- location of return value
		ret-locs: int-array/make 1
		rloc: as int-ptr! ARRAY_DATA(ret-locs)
		either ft/ret-type <> null [
			cls: reg-class? ft/ret-type
			i: 1 i-idx: 0 f-idx: 0 r-spill: 0
			switch cls [
				class_i32 [
					either i-idx < size? ret-regs [
						i-idx: i-idx + 1
						rloc/i: ret-regs/i-idx
					][
						rloc/i: spill-start + r-spill
						r-spill: r-spill + 1
					]
				]
				class_f32 [
					either f-idx < size? float-rets [
						f-idx: f-idx + 1
						rloc/i: float-rets/f-idx
					][
						rloc/i: spill-start + r-spill
						r-spill: r-spill + 1
					]
				]
				class_f64 [
					either f-idx < size? float-rets [
						f-idx: f-idx + 1
						rloc/i: float-rets/f-idx
					][
						rloc/i: spill-start + r-spill
						r-spill: r-spill + 2
					]
				]
				class_i64 [
					rloc/i: spill-start + r-spill
					r-spill: r-spill + 2
				]
			]
		][
			rloc/1: ret-regs/1
		]

		if p-spill > r-spill [r-spill: p-spill]
		cc: xmalloc(call-conv!)
		cc/reg-set: x86-reg-set/reg-set
		cc/param-types: ft/param-types
		cc/ret-type: ft/ret-type
		cc/param-locs: param-locs
		cc/ret-locs: ret-locs
		cc/n-spilled: r-spill
		fn/cc: cc
		cc
	]
]

x86: context [

	#include %assembler.reds

	int-op-width?: func [
		i		[instr-op!]
		return: [integer!]
		/local
			t	[int-type!]
	][
		t: as int-type! i/param-types/value		;-- type of first arg
		either TYPE_KIND(t) = RST_TYPE_INT [
			INT_WIDTH(t)
		][
			32
		]
	]

	op-with-width: func [
		op		[integer!]
		i		[instr-op!]
		return: [integer!]
		/local
			w	[integer!]
	][
		w: int-op-width? i
		either w > 32 [op + I_W_DIFF][op]
	]

	int-cmp-op: func [
		i		[instr-op!]
		return: [integer!]
		/local
			w	[integer!]
	][
		w: int-op-width? i
		switch w + 7 >> 3 [
			1 [I_CMPB]
			2 3 4 [I_CMPD]
			default [I_CMPQ]
		]
	]

	try-use-imm32: func [
		cg		[codegen!]
		i		[instr!]
		return: [logic!]
		/local
			val [cell!]
			b	[red-logic!]
			c	[instr-const!]
	][
		if null? i [
			use-imm-int cg 0
			return true
		]
		either INSTR_CONST?(i) [
			c: as instr-const! i
			val: c/value
			if null? val [
				use-imm cg null
				return true
			]
			switch TYPE_OF(val) [
				TYPE_INTEGER [use-imm cg val]
				TYPE_LOGIC [
					b: as red-logic! val
					use-imm-int cg either b/value [1][0]
				]
				default [return false]
			]
			true
		][false]
	]

	emit-simple-binop: func [
		cg		[codegen!]
		op		[integer!]
		i		[instr!]
	][
		overwrite-reg cg i cg/m/x
		op: either try-use-imm32 cg cg/m/y [
			op or AM_OP_IMM
		][
			use-reg cg cg/m/y
			op or AM_REG_OP
		]
		emit-instr cg op
	]

	emit-int-binop: func [
		cg		[codegen!]
		op		[integer!]
		i		[instr!]
	][
		op: op-with-width op as instr-op! i
		matcher/int-bin-op cg/m i		;-- init instr matcher with i
		emit-simple-binop cg op i
	]

	emit-call: func [
		cg		[codegen!]
		i		[instr!]
		/local
			o	[instr-op!]
			cc	[call-conv!]
			p	[ptr-ptr!]
			e	[df-edge!]
			n	[integer!]
	][
		o: as instr-op! i
		cc: x86-rs-cc/make as fn! o/target
		if cc/ret-type <> type-system/void-type [
			def-reg-fixed cg i callee-ret cc 0
		]

		kill cg x86_REG_ALL
		live-point cg cc
		use-ptr cg o/target

		n: 0
		p: ARRAY_DATA(i/inputs)
		loop i/inputs/length [
			e: as df-edge! p/value
			use-reg-fixed cg e/dst callee-param cc n
			n: n + 1
			p: p + 1
		]
		emit-instr cg I_CALL
	]

	emit-int-cmp: func [
		cg		[codegen!]
		i		[instr!]
		op		[integer!]
		cond	[x86-cond!]
		return: [x86-cond-pair!]
		/local
			p	[ptr-ptr!]
			e	[df-edge!]
			a b [instr!]
			t	[instr!]
			ob	[operand!]
	][
		p: ARRAY_DATA(i/inputs)
		e: as df-edge! p/value
		a: e/dst
		p: p + 1
		e: as df-edge! p/value
		b: e/dst

		if all [
			INSTR_CONST?(a)
			cond/commute <> null
		][
			t: a a: b b: t	;-- swap a and b
			cond: cond/commute
		]

		op: either try-use-imm32 cg b [
			ob: as operand! vector/pop-last-ptr cg/operands
			use-i cg a
			put-operand(ob)
			op or AM_OP_IMM
		][
			use-reg cg a
			use-i cg b
			op or AM_REG_OP
		]
		emit-instr cg op
		x86-cond/make-pair cond null no
	]

	emit-cmp: func [
		cg		[codegen!]
		i		[instr!]
		return: [x86-cond-pair!]
		/local
			op	[integer!]
			c	[x86-cond!]
			o	[instr-op!]
			t	[int-type!]
	][
		switch INSTR_OPCODE(i) [
			OP_BOOL_EQ
			OP_BOOL_NOT
			OP_INT_EQ
			OP_INT_LT	[
				o: as instr-op! i
				op: int-cmp-op o
				t: as int-type! o/param-types/value
				c: either INT_SIGNED?(t) [x86-cond/lesser][x86-cond/carry]
				emit-int-cmp cg i op c
			]
			OP_INT_LTEQ
			OP_PTR_EQ
			OP_PTR_LT
			OP_PTR_LTEQ
			OP_FLT_EQ
			OP_FLT_LT
			OP_FLT_LTEQ [null]
		]
	]

	emit-cond: func [
		cg		[codegen!]
		cond	[x86-cond!]
		target	[basic-block!]
	][
		use-label cg target
		emit-instr cg I_JC or M_FLAG_FIXED or (cond/index << COND_SHIFT)
	]

	gen-goto: func [
		cg		[codegen!]
		blk		[basic-block!]
		i		[instr-goto!]
		/local
			p	[ptr-ptr!]
			e	[cf-edge!]
			t	[basic-block!]
	][
		p: ARRAY_DATA(i/succs)
		e: as cf-edge! p/value
		t: e/dst

		unless directly-after? blk t [
			use-label cg t
			emit-instr cg I_JMP
		]
	]

	gen-if: func [
		cg		[codegen!]
		blk		[basic-block!]
		i		[instr-if!]
		/local
			conds	[x86-cond-pair!]
			p		[ptr-ptr!]
			e		[cf-edge!]
			jmp		[basic-block!]
			target	[basic-block!]
			fallthru [basic-block!]
			s0 s1 s2 [basic-block!]
	][
		conds: emit-cmp cg input0 as instr! i
		p: ARRAY_DATA(i/succs)
		e: as cf-edge! p/value
		s0: e/dst	;-- true block
		p: p + 1
		e: as cf-edge! p/value
		s1: e/dst	;-- false block

		jmp: null
		fallthru: null
		case [
			directly-after? blk s1 [	;-- fall thru to s1
				target: s0
				fallthru: s1
			]
			directly-after? blk s0 [
				target: s1
				fallthru: s0
				conds: x86-cond/pair-neg conds
			]
			true [
				target: s0
				jmp: s1
			]
		]

		case [
			null? conds/cond2 [
				emit-cond cg conds/cond1 target
			]
			conds/and? [
				s2: either jmp <> null [jmp][fallthru]
				emit-cond cg conds/cond1/negate s2
				emit-cond cg conds/cond2 target
			]
			true [
				emit-cond cg conds/cond1 target
				emit-cond cg conds/cond2 target
			]
		]
		if jmp <> null [
			use-label cg jmp
			emit-instr cg I_JMP or M_FLAG_FIXED
		]
	]

	gen-op: func [
		cg		[codegen!]
		blk		[basic-block!]
		i		[instr!]
	][
		switch INSTR_OPCODE(i) [
			OP_BOOL_EQ			[0]
			OP_BOOL_AND			[0]
			OP_BOOL_OR			[0]
			OP_BOOL_NOT			[0]
			OP_INT_ADD			[emit-int-binop cg I_ADDD i]
			OP_INT_SUB			[0]
			OP_INT_MUL			[0]
			OP_INT_DIV			[0]
			OP_INT_MOD			[0]
			OP_INT_REM			[0]
			OP_INT_AND			[0]
			OP_INT_OR			[0]
			OP_INT_XOR			[0]
			OP_INT_SHL			[0]
			OP_INT_SAR			[0]
			OP_INT_SHR			[0]
			OP_INT_EQ			[0]
			OP_INT_NE			[0]
			OP_INT_LT			[0]
			OP_INT_LTEQ			[0]
			OP_FLT_ADD			[0]
			OP_FLT_SUB			[0]
			OP_FLT_MUL			[0]
			OP_FLT_DIV			[0]
			OP_FLT_MOD			[0]
			OP_FLT_REM			[0]
			OP_FLT_ABS			[0]
			OP_FLT_CEIL			[0]
			OP_FLT_FLOOR		[0]
			OP_FLT_SQRT			[0]
			OP_FLT_UNUSED		[0]
			OP_FLT_BITEQ		[0]
			OP_FLT_EQ			[0]
			OP_FLT_NE			[0]
			OP_FLT_LT			[0]
			OP_FLT_LTEQ			[0]
			OP_DEFAULT_VALUE	[0]
			OP_CALL_FUNC		[emit-call cg i]
			OP_GET_GLOBAL		[0]
			OP_SET_GLOBAL		[0]
			default [
				prin "codegen: unknown op"
			]
		]
	]

	make-frame: func [
		ir		[ir-fn!]
		return: [frame!]
		/local
			f	[frame!]
	][
		f: xmalloc(frame!)
		f/cc: x86-rs-cc/make ir/fn
		f/align: target/addr-align
		f/slot-size: 4
		f/size: target/addr-size
		f/tmp-slot: -1
		f
	]

	long-to-reg: func [		;-- 64bit value to reg
		cg		[codegen!]
		val		[cell!]
		idx		[integer!]
	][
		;TBD
	]

	load-to-reg: func [		;-- load val into reg
		cg		[codegen!]
		v		[vreg!]
		idx		[integer!]		;-- reg index
		/local
			cls [integer!]
			op	[integer!]
			d	[def!]
			u	[use!]
			i	[instr-const!]
	][
		cls: v/reg-class
		op: either any [cls = class_i32 cls = class_f32][I_MOVD][I_MOVQ]
		either vreg-const?(v) [
			;TBD handle 64bit value
			d: make-def null idx
			i: as instr-const! v/instr
			u: as use! make-imm i/value
			op: op or AM_OP_IMM
		][
			d: make-def null idx
			u: make-use v v/spill
			op: op or AM_REG_OP		
		]
		emit-instr2 cg op d u
	]

	gen-restore: func [
		cg		[codegen!]
		v		[vreg!]		;-- from
		idx		[integer!]	;-- to
		/local
			s	[reg-set!]
			r	[integer!]
			op	[integer!]
			d	[def!]
			u	[use!]
			cls [integer!]
	][
		s: cg/reg-set
		cls: v/reg-class
		if on-stack? s idx [
			r: s/gpr-scratch
			op: either cls = class_i32 [I_MOVD][I_MOVQ]
			either all [
				vreg-const?(v)
				try-use-imm32 cg v/instr
			][
				u: as use! vector/pop-last-ptr cg/operands
				d: make-def null idx
				op: op or AM_OP_IMM
			][
				r: s/gpr-scratch
				load-to-reg cg v r
				d: make-def null idx
				u: make-use v r
				op: op or AM_OP_REG
			]
			emit-instr2 cg op d u
			exit
		]
		either sse-reg?(idx) [
			op: either cls = class_f32 [I_MOVSS][I_MOVSD]
			d: make-def null idx
			either vreg-const?(v) [
				r: s/gpr-scratch
				load-to-reg cg v r
				u: make-use v r
				op: op or AM_XMM_REG
			][
				u: make-use v v/spill
				op: op or AM_XMM_OP
			]
			emit-instr2 cg op d u
		][
			load-to-reg cg v idx
		]
	]

	gen-save: func [
		cg		[codegen!]
		v		[vreg!]		;-- to
		idx		[integer!]	;-- from
		/local
			s	[reg-set!]
			r	[integer!]
			op	[integer!]
			d	[def!]
			u	[use!]
			cls [integer!]
	][
		if on-caller-stack? idx [exit]
		s: cg/reg-set
		if on-stack? s idx [
			r: s/gpr-scratch
			op: either v/reg-class = class_i32 [I_MOVD][I_MOVQ]
			d: make-def null r
			u: make-use null idx
			emit-instr2 cg op or AM_REG_OP d u
			d: make-def v v/spill
			u: make-use null r
			emit-instr2 cg op or AM_OP_REG d u
			exit
		]
		cls: v/reg-class
		op: switch cls [
			class_i32 [I_MOVD or AM_OP_REG]
			class_i64 [I_MOVQ or AM_OP_REG]
			class_f32 [I_MOVSS or AM_OP_XMM]
			class_f64 [I_MOVSD or AM_OP_XMM]
		]
		d: make-def v v/spill
		u: make-use null idx
		emit-instr2 cg op d u
	]

	gen-move-loc: func [
		cg		[codegen!]
		arg		[move-arg!]
		/local
			op cls	[integer!]
			src dst [integer!]
			rset	[reg-set!]
			s-reg	[integer!]
			d		[def!]
			u		[use!]
	][
		rset: cg/reg-set
		s-reg: rset/gpr-scratch
		cls: arg/reg-cls
		src: arg/src-reg
		dst: arg/dst-reg
		op: either any [cls = class_i32 cls = class_f32][I_MOVD][I_MOVQ]
		either on-stack? rset dst [
			either on-stack? rset src [
				d: make-def null s-reg
				u: make-use arg/src-v src
				emit-instr2 cg op or AM_REG_OP d u
				d: make-def arg/dst-v dst
				u: make-use null s-reg
				emit-instr2 cg op or AM_OP_REG d u
			][
				d: make-def arg/dst-v dst
				u: make-use arg/src-v src
				op: either sse-reg?(src) [
					op: either cls = class_f32 [I_MOVSS][I_MOVSD]
					op or AM_OP_XMM
				][
					op or AM_OP_REG
				]
				emit-instr2 cg op d u
			]
		][
			d: make-def arg/dst-v dst
			u: make-use arg/src-v src
			op: either sse-reg?(dst) [
				op: either cls = class_f32 [I_MOVSS][I_MOVSD]
				op or AM_XMM_OP
			][
				op or AM_REG_OP
			]
			emit-instr2 cg op d u
		]
	]

	gen-move-imm: func [
		cg		[codegen!]
		arg		[move-arg!]
		/local
			op cls	[integer!]
			src-v	[vreg!]
			dst-v	[vreg!]
			dst		[integer!]
			rset	[reg-set!]
			s-reg	[integer!]
			d		[def!]
			u		[use!]
			imm32?	[logic!]
			imm		[operand!]
			val		[cell!]
			i		[instr-const!]
	][
		rset: cg/reg-set
		s-reg: rset/gpr-scratch
		cls: arg/reg-cls
		src-v: arg/src-v
		dst-v: arg/dst-v
		dst: arg/dst-reg
		imm32?: try-use-imm32 cg src-v/instr
		imm: either imm32? [as operand! vector/pop-last-ptr cg/operands][null]
		op: either any [cls = class_i32 cls = class_f32][I_MOVD][I_MOVQ]
		either on-stack? rset dst [
			if imm32? [
				d: make-def dst-v dst
				emit-instr2 cg op or AM_OP_IMM d as use! imm
				exit
			]
			arg/dst-v: null
			arg/dst-reg: s-reg
			gen-move-imm cg arg

			arg/src-v: null
			arg/src-reg: s-reg
			arg/dst-v: dst-v
			arg/dst-reg: dst
			gen-move-loc cg arg
		][
			either sse-reg?(dst) [
				arg/dst-v: null
				arg/dst-reg: s-reg
				gen-move-imm cg arg
				op: either cls = class_f32 [I_MOVSS][I_MOVSD]
				d: make-def dst-v dst
				u: make-use null s-reg
				emit-instr2 cg op or AM_XMM_REG d u
			][
				d: make-def dst-v dst
				either imm32? [
					emit-instr2 cg op or AM_OP_IMM d as use! imm
				][
					i: as instr-const! src-v/instr
					val: i/value
					emit-instr2 cg I_MOVD or AM_OP_IMM d as use! make-imm val
					;TBD handle 64bit value
				]
			]
		]
	]

	to-loc: func [
		o		[operand!]
		return: [integer!]
		/local
			d	[def!]
			u	[use!]
			w	[overwrite!]
	][
		switch o/header and FFh [
			OD_DEF [
				d: as def! o
				d/constraint
			]
			OD_USE [
				u: as use! o
				u/constraint
			]
			OD_OVERWRITE [
				w: as overwrite! o
				w/constraint
			]
			default [
				probe ["wrong operand type: " o/header and FFh]
				0
			]
		]
	]

	adjust-frame: func [
		frame	[frame!]
		add?	[logic!]
		/local
			n	[integer!]
			op	[integer!]
	][
		n: frame/size - target/addr-size		;-- return addr already pushed
		if n > 0 [
			op: either add? [asm/OP_ADD][asm/OP_SUB]
			asm/emit-r-i x86-regs/esp n op
		]
	]

	make-addr: func [
		base	[integer!]
		index	[integer!]
		scale	[integer!]
		disp	[integer!]
		return: [x86-addr!]
		/local
			a	[x86-addr!]
	][
		a: xmalloc(x86-addr!)
		a/base: base
		a/index: index
		a/scale: scale
		a/disp: disp
		a
	]

	loc-m: func [	;-- location idx to memory addr
		f		[frame!]
		r		[reg-set!]
		loc		[integer!]
		return:	[x86-addr!]
		/local
			word-sz [integer!]
			offset	[integer!]
	][
		loc: loc and (not FRAME_SLOT_64)	;-- remove flag
		offset: 0
		word-sz: target/addr-size
		case [
			loc >= r/callee-base [
				offset: word-sz * (loc - r/callee-base)
			]
			loc >= r/caller-base [
				offset: word-sz * (loc - r/caller-base) + f/size
			]
			loc >= r/spill-start [
				offset: word-sz * (loc - r/spill-start + f/spill-args)
			]
			true [probe ["invalid stack location: " loc]]
		]
		make-addr x86_ESP 0 1 offset
	]

	assemble-op: func [
		op		[integer!]
		p		[ptr-ptr!]
		/local
			l	[label!]
			c	[integer!]
	][
		switch x86_OPCODE(op) [
			I_JMP [
				l: as label! p/value
				either l/pos >= 0 [
					asm/jmp-rel l/pos - asm/pos
				][
					asm/jmp-rel-addr l
				]
			]
			I_JC [
				l: as label! p/value
				c: x86_COND(op)
				either l/pos >= 0 [
					asm/jc-rel c l/pos - asm/pos
				][
					asm/jc-rel-addr c l
				]
			]
			default [0]
		]
	]

	assemble-r-r: func [
		op		[integer!]
		a		[integer!]
		b		[integer!]
	][
	]

	assemble-r-m: func [
		op		[integer!]
		a		[integer!]
		m		[x86-addr!]
	][
		
	]

	assemble: func [
		cg		[codegen!]
		i		[mach-instr!]
		/local
			op	[integer!]
			m	[integer!]
			reg [integer!]
			loc [integer!]
			l	[label!]
			p	[ptr-ptr!]
			ins [integer!]
			rset [reg-set!]
	][
		rset: cg/reg-set
		ins: i/header
		op: x86_OPCODE(ins)
		p: as ptr-ptr! i + 1	;-- point to operands
		if op >= I_NOP [
			switch op [
				I_ENTRY [adjust-frame cg/frame no]
				I_BLK_BEG [
					l: as label! p/value
					l/pos: asm/pos
				]
				I_RET [
					adjust-frame cg/frame yes
					asm/ret
				]
				default [0]
			]
			exit
		]

		m: i/header >> AM_SHIFT and 1Fh
		switch m [
			_AM_NONE [assemble-op ins p]
			_AM_REG_OP [
				reg: to-loc as operand! p/value
				reg: reg - 1
				p: p + 1
				loc: to-loc as operand! p/value
				either gpr-reg?(loc) [
					assemble-r-r op reg loc - 1
				][
					assemble-r-m op reg loc-m cg/frame rset loc
				]
			]
			_AM_RRSD_REG
			_AM_RRSD_IMM
			_AM_REG_RRSD
			_AM_OP
			_AM_OP_IMM
			_AM_OP_REG
			_AM_XMM_REG
			_AM_XMM_OP
			_AM_OP_XMM
			_AM_XMM_RRSD
			_AM_RRSD_XMM
			_AM_XMM_IMM 
			_AM_REG_XOP
			_AM_XMM_XMM [0]
			default [0]
		]
	]
]