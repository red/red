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
#define x86_ESI			5
#define x86_EDI			6
#define x86_XMM0		7
#define x86_XMM1		8
#define x86_XMM2		9
#define x86_XMM3		10
#define x86_XMM4		11
#define x86_XMM5		12
#define x86_XMM6		13
#define x86_XMM7		14
#define x86_EBP			15
#define x86_GPR			16
#define x86_BYTE		17
#define x86_EAX_EDX		18
#define x86_NOT_EDX		19
#define x86_NOT_ECX		20
#define x86_CLS_GPR		21
#define x86_CLS_SSE		22
#define x86_REG_ALL		23
#define SCRATCH			x86_EBP
#define SSE_SCRATCH		x86_XMM7

;-- REG: GPR
;-- OP: register or stack
;-- XOP: XMM register or stack
;-- MRRSD: [reg + reg * scale + disp]
#enum x86-addr-mode! [
	AM_NONE
	AM_REG_OP
	AM_MRRSD_REG
	AM_MRRSD_IMM
	AM_REG_MRRSD
	AM_OP
	AM_OP_IMM
	AM_OP_REG
	AM_XMM_REG
	AM_XMM_OP
	AM_OP_XMM
	AM_XMM_MRRSD
	AM_MRRSD_XMM
	AM_XMM_IMM 
	AM_REG_XOP
	AM_XMM_XMM
]

#define AM_SHIFT	10
#define COND_SHIFT	15
#define ROUND_SHIFT	19

x86-reg-set: context [
	regs: as reg-set! 0

	init: func [/local arr [ptr-array!] p pa [ptr-ptr!] pp pint [int-ptr!]][
		arr: ptr-array/make x86_REG_ALL + 1
		p: ARRAY_DATA(arr)
		pa: p + x86_EAX

		regs: as reg-set! malloc size? reg-set!
		regs/n-regs: 14
		regs/regs: arr
		regs/spill-start: arr/length

		arr: int-array/make 4
		pp: as int-ptr! ARRAY_DATA(arr)
		pint: pp + class_i32
		pint/value: x86_CLS_GPR
	]
]

x86-rscall: context [	;-- red/system internal call-conv!
	param-regs: [x86_EDI x86_EAX x86_EDX x86_ECX x86_ESI]
	ret-regs: [x86_EAX x86_EDX]
	float-params: [x86_XMM0 x86_XMM1 x86_XMM2 x86_XMM3 x86_XMM4 x86_XMM5 x86_XMM6]
	float-rets: [x86_XMM0 x86_XMM1]
	
	make: func [
		fn		[ir-fn!]
		return: [call-conv!]
		/local
			spill-start [integer!]
			n-params	[integer!]
			param-locs	[array!]
			ret-locs	[array!]
			p			[ptr-ptr!]
			ploc rloc	[int-ptr!]
			param		[instr-param!]
			cls			[reg-class!]
			i			[integer!]
			i-idx f-idx [integer!]
			p-spill		[integer!]
			r-spill		[integer!]
			cc			[call-conv!]
	][
		spill-start: x86-reg-set/regs/spill-start
		n-params: fn/params/length
		param-locs: int-array/make n-params
		ploc: as int-ptr! ARRAY_DATA(param-locs)

		;-- locations of each parameter
		p-spill: 0 i-idx: 0 f-idx: 0 i: 1
		p: ARRAY_DATA(fn/params)
		loop n-params [
			param: as instr-param! p/value
			cls: reg-class? param/type
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
		either fn/ret-type <> null [
			cls: reg-class? fn/ret-type
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
		cc/reg-set: x86-reg-set/regs
		cc/param-types: fn/param-types
		cc/ret-type: fn/ret-type
		cc/param-locs: param-locs
		cc/ret-locs: ret-locs
		cc/n-spilled: r-spill
		cc
	]
]

int-op-width?: func [
	i		[instr-op!]
	return: [integer!]
	/local
		t	[int-type!]
][
	t: as int-type! i/ret-type
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
		op or (AM_OP_IMM << AM_SHIFT)
	][
		use-reg cg cg/m/y
		op or (AM_REG_OP << AM_SHIFT)
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

x86-gen-op: func [
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
		OP_CALL_FUNC		[0]
		OP_GET_GLOBAL		[0]
		OP_SET_GLOBAL		[0]
		default [
			prin "codegen: unknown op"
		]
	]
]

x86-make-frame: func [
	ir		[ir-fn!]
	return: [frame!]
	/local
		f	[frame!]
][
	f: xmalloc(frame!)
	f/cc: x86-rscall/make ir
	f/align: target/addr-align
	f/slot-size: target/addr-size
	f/size: target/addr-size
	f
]
