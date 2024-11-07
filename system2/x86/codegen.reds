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

#define x64_RAX			1
#define x64_RCX			2
#define x64_RDX			3
#define x64_RBX			4
#define x64_RSP			5
#define x64_RBP			6
#define x64_RSI			7
#define x64_RDI			8
#define x64_R8			9
#define x64_R9			10
#define x64_R10			11
#define x64_R11			12
#define x64_R12			13
#define x64_R13			14
#define x64_R14			15
#define x64_R15			16
#define x64_XMM0		17
#define x64_XMM1		18
#define x64_XMM2		19
#define x64_XMM3		20
#define x64_XMM4		21
#define x64_XMM5		22
#define x64_XMM6		23
#define x64_XMM7		24
#define x64_XMM8		25
#define x64_XMM9		26
#define x64_XMM10		27
#define x64_XMM11		28
#define x64_XMM12		29
#define x64_XMM13		30
#define x64_XMM14		31
#define x64_XMM15		32
#define x64_GPR			33
#define x64_XMM			34
#define x64_RAX_RDX		35
#define x64_NOT_RCX		36
#define x64_NOT_RAX		37
#define x64_NOT_RAX_RDX 38
#define x64_REG_ALL		39
#define x64_SCRATCH		x64_RBP
#define XMM_SCRATCH		x64_XMM7

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

#define ADD_REG_SET(idx arr) [
	pa: p + idx
	pa/value: as int-ptr! make-int-array arr size? arr
]

mach-reg-set: as reg-set! 0

x64-reg-set: context [
	reg-set: as reg-set! 0

	a1:  [x64_RAX]
	a2:  [x64_RCX]
	a3:  [x64_RDX]
	a4:  [x64_RBX]
	a5:  [x64_RSI]
	a6:  [x64_RDI]
	a7:  [x64_R8]
	a8:  [x64_R9]
	a9:  [x64_R10]
	a10: [x64_R11]
	a11: [x64_R12]
	a12: [x64_R13]
    a13: [x64_R14]
    a14: [x64_R15]
    a15: [x64_XMM0]
    a16: [x64_XMM1]
    a17: [x64_XMM2]
    a18: [x64_XMM3]
    a19: [x64_XMM4]
    a20: [x64_XMM5]
    a21: [x64_XMM6]
    a22: [x64_XMM8]
    a23: [x64_XMM9]
    a24: [x64_XMM10]
    a25: [x64_XMM11]
    a26: [x64_XMM12]
    a27: [x64_XMM13]
    a28: [x64_XMM14]
    a29: [x64_XMM15]
    a30: [
	    x64_RAX x64_RBX x64_RCX x64_RDX x64_RSI x64_RDI
	    x64_R8 x64_R9 x64_R10 x64_R11 x64_R12 x64_R13 x64_R14 x64_R15
	]
    a31: [
	    x64_XMM0 x64_XMM1 x64_XMM2 x64_XMM3 x64_XMM4 x64_XMM5 x64_XMM6
	    x64_XMM8 x64_XMM9 x64_XMM10 x64_XMM11 x64_XMM12 x64_XMM13 x64_XMM14 x64_XMM15
    ]
    a32: [x64_RAX x64_RDX]
    a33: [	;-- no rcx
	    x64_RAX x64_RBX x64_RDX x64_RSI x64_RDI
	    x64_R8 x64_R9 x64_R10 x64_R11 x64_R12 x64_R13 x64_R14 x64_R15
    ]
    a34: [	;-- no rax
	    x64_RBX x64_RCX x64_RDX x64_RSI x64_RDI
	    x64_R8 x64_R9 x64_R10 x64_R11 x64_R12 x64_R13 x64_R14 x64_R15
    ]
    a35: [	;-- no rax, rdx
	    x64_RBX x64_RCX x64_RSI x64_RDI
	    x64_R8 x64_R9 x64_R10 x64_R11 x64_R12 x64_R13 x64_R14 x64_R15
    ]

	_gpr-reg?: func [
		r		[integer!]
		return: [logic!]
	][
		all [x64_RAX <= r r <= x64_R15]
	]

	_xmm-reg?: func [
		r		[integer!]
		return: [logic!]
	][
		all [x64_XMM0 <= r r <= x64_XMM15]
	]

	init: func [/local s [reg-set!] arr [ptr-array!] p pa [ptr-ptr!] pp [int-ptr!]][
		arr: ptr-array/make x64_REG_ALL + 1
		p: ARRAY_DATA(arr)
		ADD_REG_SET(x64_RAX a1)
		ADD_REG_SET(x64_RCX a2)
		ADD_REG_SET(x64_RDX a3)
		ADD_REG_SET(x64_RBX a4)
		ADD_REG_SET(x64_RSI a5)
		ADD_REG_SET(x64_RDI a6)
		ADD_REG_SET(x64_R8  a7)
		ADD_REG_SET(x64_R9  a8)
		ADD_REG_SET(x64_R10 a9)
		ADD_REG_SET(x64_R11 a10)
		ADD_REG_SET(x64_R12 a11)
		ADD_REG_SET(x64_R13 a12)
		ADD_REG_SET(x64_R14 a13)
		ADD_REG_SET(x64_R15 a14)
		ADD_REG_SET(x64_XMM0 a15)
		ADD_REG_SET(x64_XMM1 a16)
		ADD_REG_SET(x64_XMM2 a17)
		ADD_REG_SET(x64_XMM3 a18)
		ADD_REG_SET(x64_XMM4 a19)
		ADD_REG_SET(x64_XMM5 a20)
		ADD_REG_SET(x64_XMM6 a21)
		ADD_REG_SET(x64_XMM8 a22)
		ADD_REG_SET(x64_XMM9 a23)
		ADD_REG_SET(x64_XMM10 a24)
		ADD_REG_SET(x64_XMM11 a25)
		ADD_REG_SET(x64_XMM12 a26)
		ADD_REG_SET(x64_XMM13 a27)
		ADD_REG_SET(x64_XMM14 a28)
		ADD_REG_SET(x64_XMM15 a29)
		ADD_REG_SET(x64_GPR a30)
		ADD_REG_SET(x64_XMM a31)
		ADD_REG_SET(x64_RAX_RDX a32)
		ADD_REG_SET(x64_NOT_RCX a33)
		ADD_REG_SET(x64_NOT_RAX a34)
		ADD_REG_SET(x64_NOT_RAX_RDX a35)

        pa: p + x64_SCRATCH
        pa/value: as int-ptr! empty-array
        pa: p + XMM_SCRATCH
        pa/value: as int-ptr! empty-array
        pa: p + x64_RSP
        pa/value: as int-ptr! empty-array

		s: xmalloc(reg-set!)
		s/n-regs: 32
		s/regs: arr
		s/spill-start: arr/length
		s/gpr-scratch: x64_SCRATCH
		s/sse-scratch: XMM_SCRATCH

		pp: as int-ptr! malloc 4 * size? integer!
		pp/1: x64_GPR
		pp/2: x64_GPR
		pp/3: x64_XMM
		pp/4: x64_XMM
		s/regs-cls: pp

		pp: as int-ptr! malloc 4 * size? integer!
		pp/1: x64_SCRATCH
		pp/2: x64_SCRATCH
		pp/3: XMM_SCRATCH
		pp/4: XMM_SCRATCH
		s/scratch: pp

		init-reg-set s
		reg-set: s
		target/gpr-reg?: as fn-is-reg! :_gpr-reg?
		target/xmm-reg?: :_xmm-reg?
	]
]

x64-win-cc: context [
	param-regs: as rs-array! 0
	ret-regs: as rs-array! 0
	float-params: as rs-array! 0
	float-rets: as rs-array! 0

	_param-regs: [x64_RCX x64_RDX x64_R8 x64_R9]
	_ret-regs: [x64_RAX]
	_float-params: [x64_XMM0 x64_XMM1 x64_XMM2 x64_XMM3]
	_float-rets: [x64_XMM0]

	init: does [
		param-regs: make-int-array _param-regs size? _param-regs
		ret-regs: make-int-array _ret-regs size? _ret-regs
		float-params: make-int-array _float-params size? _float-params
		float-rets: make-int-array _float-rets size? _float-rets
	]
]

x64-internal-cc: context [
	param-regs: as rs-array! 0
	ret-regs: as rs-array! 0
	float-params: as rs-array! 0
	float-rets: as rs-array! 0

	_param-regs: [x64_RDI x64_RSI x64_RDX x64_RCX x64_R8 x64_R9]
	_ret-regs: [x64_RAX x64_RDX]
	_float-params: [x64_XMM0 x64_XMM1 x64_XMM2 x64_XMM3 x64_XMM4 x64_XMM5 x64_XMM6]
	_float-rets: [x64_XMM0 x64_XMM1]

	init: does [
		param-regs: make-int-array _param-regs size? _param-regs
		ret-regs: make-int-array _ret-regs size? _ret-regs
		float-params: make-int-array _float-params size? _float-params
		float-rets: make-int-array _float-rets size? _float-rets
	]
]

x64-cc: context [
	make: func [
		fn		[fn!]
		op		[instr-op!]
		return: [call-conv!]
		/local
			spill-start 	[integer!]
			n-params		[integer!]
			param-locs		[rs-array!]
			ret-locs		[rs-array!]
			p				[ptr-ptr!]
			pp				[int-ptr!]
			ploc rloc		[int-ptr!]
			cls				[reg-class!]
			i				[integer!]
			i-idx f-idx 	[integer!]
			p-spill			[integer!]
			r-spill			[integer!]
			cc				[call-conv!]
			ft				[fn-type!]
			attr			[integer!]
			param-regs		[int-array!]
			ret-regs		[int-array!]
			float-params	[int-array!]
			float-rets		[int-array!]
			variadic?		[logic!]
			shadow-space	[integer!]
	][
		if fn/cc <> null [return fn/cc]

		shadow-space: 0
		ft: as fn-type! fn/type
		attr: FN_ATTRS(ft)
		variadic?: attr and FN_VARIADIC <> 0
		case [
			attr and (FN_CC_STDCALL or FN_CC_CDECL) <> 0 [
				param-regs: 	x64-win-cc/param-regs
				ret-regs: 		x64-win-cc/ret-regs
				float-params: 	x64-win-cc/float-params
				float-rets: 	x64-win-cc/float-rets
				shadow-space: 4
			]
			true [	;-- internal cc
				param-regs: 	x64-internal-cc/param-regs
				ret-regs:       x64-internal-cc/ret-regs
				float-params:   x64-internal-cc/float-params
				float-rets:     x64-internal-cc/float-rets
			]
		]
		
		spill-start: x64-reg-set/reg-set/spill-start
		n-params: either variadic? [op/n-params][ft/n-params]
		param-locs: int-array/make n-params
		ploc: as int-ptr! ARRAY_DATA(param-locs)

		;-- locations of each parameter
		p-spill: shadow-space i-idx: 0 f-idx: 0 i: 1
		p: either op <> null [op/param-types][ft/param-types]
		loop n-params [
			cls: reg-class? as rst-type! p/value
			switch cls [
				class_i32 class_i64 [
					either i-idx < param-regs/length [
						pp: as int-ptr! ARRAY_DATA(param-regs)
						i-idx: i-idx + 1
						ploc/i: pp/i-idx
					][
						ploc/i: spill-start + p-spill
						p-spill: p-spill + 1
					]
				]
				class_f32 class_f64 [
					either f-idx < float-params/length [
						pp: as int-ptr! ARRAY_DATA(float-params)
						f-idx: f-idx + 1
						ploc/i: pp/f-idx
					][
						ploc/i: spill-start + p-spill
						p-spill: p-spill + 1
					]
				]
			]
			i: i + 1
			p: p + 1
		]

		;-- location of return value
		r-spill: 0
		ret-locs: int-array/make 1
		rloc: as int-ptr! ARRAY_DATA(ret-locs)
		assert ft/ret-type <> null
		either ft/ret-type <> type-system/void-type [
			cls: reg-class? ft/ret-type
			i: 1 i-idx: 0 f-idx: 0
			switch cls [
				class_i32 class_i64 [
					either i-idx < ret-regs/length [
						pp: as int-ptr! ARRAY_DATA(ret-regs)
						i-idx: i-idx + 1
						rloc/i: pp/i-idx
					][
						rloc/i: spill-start + r-spill
						r-spill: r-spill + 1
					]
				]
				class_f32 class_f64 [
					either f-idx < float-rets/length [
						pp: as int-ptr! ARRAY_DATA(float-rets)
						f-idx: f-idx + 1
						rloc/i: pp/f-idx
					][
						rloc/i: spill-start + r-spill
						r-spill: r-spill + 1
					]
				]
			]
		][
			pp: as int-ptr! ARRAY_DATA(ret-regs)
			rloc/1: pp/value
		]

		if p-spill > r-spill [r-spill: p-spill]
		cc: xmalloc(call-conv!)
		cc/reg-set: x64-reg-set/reg-set
		cc/param-types: ft/param-types
		cc/ret-type: ft/ret-type
		cc/param-locs: param-locs
		cc/ret-locs: ret-locs
		cc/n-spilled: r-spill
		unless variadic? [fn/cc: cc]
		cc
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

	_gpr-reg?: func [
		r		[integer!]
		return: [logic!]
	][
		all [x86_EAX <= r r <= x86_EDI]
	]

	_xmm-reg?: func [
		r		[integer!]
		return: [logic!]
	][
		all [x86_XMM0 <= r r <= x86_XMM7]
	]

	init: func [/local s [reg-set!] arr [ptr-array!] p pa [ptr-ptr!] pp [int-ptr!]][
		arr: ptr-array/make x86_REG_ALL + 1
		p: ARRAY_DATA(arr)
		ADD_REG_SET(x86_EAX 	a1)	
		ADD_REG_SET(x86_EBX     a2)
		ADD_REG_SET(x86_ECX     a3)
		ADD_REG_SET(x86_EDX     a4)
		ADD_REG_SET(x86_ESI     a5)
		ADD_REG_SET(x86_EDI     a6)
		ADD_REG_SET(x86_XMM0    a7)
		ADD_REG_SET(x86_XMM1    a8)
		ADD_REG_SET(x86_XMM2    a9)
		ADD_REG_SET(x86_XMM3    a10)
		ADD_REG_SET(x86_XMM4    a11)
		ADD_REG_SET(x86_XMM5    a12)
		ADD_REG_SET(x86_XMM6    a13)
		ADD_REG_SET(x86_GPR     a14)
		ADD_REG_SET(x86_BYTE     a15)
		ADD_REG_SET(x86_EAX_EDX  a16)
		ADD_REG_SET(x86_NOT_EDX  a17)
		ADD_REG_SET(x86_NOT_ECX  a18)
		ADD_REG_SET(x86_CLS_GPR  a19)
		ADD_REG_SET(x86_CLS_SSE  a20)
		ADD_REG_SET(x86_REG_ALL  a21)

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
		target/gpr-reg?: as fn-is-reg! :_gpr-reg?
		target/xmm-reg?: :_xmm-reg?
	]
]

x86-cdecl: context [
	param-regs: as rs-array! 0
	ret-regs: as rs-array! 0
	float-params: as rs-array! 0
	float-rets: as rs-array! 0

	_ret-regs: [x86_EAX]

	init: does [
		param-regs: empty-array
		ret-regs: make-int-array _ret-regs size? _ret-regs
		float-params: empty-array
		float-rets: empty-array
	]
]

x86-stdcall: context [
	param-regs: as rs-array! 0
	ret-regs: as rs-array! 0
	float-params: as rs-array! 0
	float-rets: as rs-array! 0

	_ret-regs: [x86_EAX]

	init: does [
		param-regs: empty-array
		ret-regs: make-int-array _ret-regs size? _ret-regs
		float-params: empty-array
		float-rets: empty-array
	]
]

x86-internal-cc: context [	;-- red/system internal call-conv!
	param-regs: as rs-array! 0
	ret-regs: as rs-array! 0
	float-params: as rs-array! 0
	float-rets: as rs-array! 0

	_param-regs: [x86_EDI x86_EAX x86_EDX x86_ECX x86_ESI]
	_ret-regs: [x86_EAX x86_EDX]
	_float-params: [x86_XMM0 x86_XMM1 x86_XMM2 x86_XMM3 x86_XMM4 x86_XMM5 x86_XMM6]
	_float-rets: [x86_XMM0 x86_XMM1]

	init: does [
		param-regs: make-int-array _param-regs size? _param-regs
		ret-regs: make-int-array _ret-regs size? _ret-regs
		float-params: make-int-array _float-params size? _float-params
		float-rets: make-int-array _float-rets size? _float-rets
	]
]

x86-cc: context [
	make: func [
		fn		[fn!]
		op		[instr-op!]
		return: [call-conv!]
		/local
			spill-start 	[integer!]
			n-params		[integer!]
			param-locs		[rs-array!]
			ret-locs		[rs-array!]
			p				[ptr-ptr!]
			pp				[int-ptr!]
			ploc rloc		[int-ptr!]
			cls				[reg-class!]
			i				[integer!]
			i-idx f-idx 	[integer!]
			p-spill			[integer!]
			r-spill			[integer!]
			cc				[call-conv!]
			ft				[fn-type!]
			attr			[integer!]
			param-regs		[int-array!]
			ret-regs		[int-array!]
			float-params	[int-array!]
			float-rets		[int-array!]
			callee-clean?	[logic!]
			variadic?		[logic!]
	][
		if fn/cc <> null [return fn/cc]

		callee-clean?: yes
		ft: as fn-type! fn/type
		attr: FN_ATTRS(ft)
		variadic?: attr and FN_VARIADIC <> 0
		case [
			attr and FN_CC_STDCALL <> 0 [
				param-regs: 	x86-stdcall/param-regs
				ret-regs: 		x86-stdcall/ret-regs
				float-params: 	x86-stdcall/float-params
				float-rets: 	x86-stdcall/float-rets
			]
			attr and FN_CC_CDECL <> 0 [
				callee-clean?: no
				param-regs: 	x86-cdecl/param-regs
				ret-regs: 		x86-cdecl/ret-regs
				float-params: 	x86-cdecl/float-params
				float-rets: 	x86-cdecl/float-rets
			]
			true [	;-- internal cc
				param-regs: 	x86-internal-cc/param-regs
				ret-regs:       x86-internal-cc/ret-regs
				float-params:   x86-internal-cc/float-params
				float-rets:     x86-internal-cc/float-rets
			]
		]
		
		spill-start: x86-reg-set/reg-set/spill-start
		n-params: either variadic? [op/n-params][ft/n-params]
		param-locs: int-array/make n-params
		ploc: as int-ptr! ARRAY_DATA(param-locs)

		;-- locations of each parameter
		p-spill: 0 i-idx: 0 f-idx: 0 i: 1
		p: either op <> null [op/param-types][ft/param-types]
		loop n-params [
			cls: reg-class? as rst-type! p/value
			switch cls [
				class_i32 [
					either i-idx < param-regs/length [
						pp: as int-ptr! ARRAY_DATA(param-regs)
						i-idx: i-idx + 1
						ploc/i: pp/i-idx
					][
						ploc/i: spill-start + p-spill
						p-spill: p-spill + 1
					]
				]
				class_f32 [
					either f-idx < float-params/length [
						pp: as int-ptr! ARRAY_DATA(float-params)
						f-idx: f-idx + 1
						ploc/i: pp/f-idx
					][
						ploc/i: spill-start + p-spill
						p-spill: p-spill + 1
					]
				]
				class_f64 [
					either f-idx < float-params/length [
						pp: as int-ptr! ARRAY_DATA(float-params)
						f-idx: f-idx + 1
						ploc/i: pp/f-idx
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
		r-spill: 0
		ret-locs: int-array/make 1
		rloc: as int-ptr! ARRAY_DATA(ret-locs)
		assert ft/ret-type <> null
		either ft/ret-type <> type-system/void-type [
			cls: reg-class? ft/ret-type
			i: 1 i-idx: 0 f-idx: 0
			switch cls [
				class_i32 [
					either i-idx < ret-regs/length [
						pp: as int-ptr! ARRAY_DATA(ret-regs)
						i-idx: i-idx + 1
						rloc/i: pp/i-idx
					][
						rloc/i: spill-start + r-spill
						r-spill: r-spill + 1
					]
				]
				class_f32 [
					either f-idx < float-rets/length [
						pp: as int-ptr! ARRAY_DATA(float-rets)
						f-idx: f-idx + 1
						rloc/i: pp/f-idx
					][
						rloc/i: spill-start + r-spill
						r-spill: r-spill + 1
					]
				]
				class_f64 [
					either f-idx < float-rets/length [
						pp: as int-ptr! ARRAY_DATA(float-rets)
						f-idx: f-idx + 1
						rloc/i: pp/f-idx
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
			pp: as int-ptr! ARRAY_DATA(ret-regs)
			rloc/1: pp/value
		]

		if p-spill > r-spill [r-spill: p-spill]
		cc: xmalloc(call-conv!)
		cc/reg-set: x86-reg-set/reg-set
		cc/param-types: ft/param-types
		cc/ret-type: ft/ret-type
		cc/param-locs: param-locs
		cc/ret-locs: ret-locs
		cc/n-spilled: r-spill
		cc/callee-clean?: callee-clean?
		unless variadic? [fn/cc: cc]
		cc
	]
]

x86: context [

	rrsd!: alias struct! [
		base	[instr!]
		index	[instr!]
		scale	[integer!]
		disp	[cell!]
	]

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

	emit-int-div: func [
		cg		[codegen!]
		i		[instr!]
		mod?	[logic!]
		/local
			x	[instr!]
			op	[instr-op!]
			c	[instr-const!]
			p	[ptr-ptr!]
			int [integer!]
			ext [vreg!]
			val [red-integer!]
			reg [integer!]
			t	[int-type!]
			opcode [integer!]
	][
		x: input0 i
		op: as instr-op! i
		p: op/param-types
		t: as int-type! p/value			;-- type of x

		either INT_SIGNED?(t) [
			either INSTR_CONST?(x) [	;-- constant fold
				c: as instr-const! x
				int: int-unbox c/value
				ext: either int < 0 [
					val: xmalloc(red-integer!)
					val/header: TYPE_INTEGER
					val/value: -1
					c: either INT_WIDTH(t) > 32 [ir-graph/const-int64 val cg/fn][ir-graph/const-int val cg/fn]
					get-vreg cg as instr! c
				][
					get-vreg cg as instr! ir-graph/const-int-zero cg/fn
				]
			][
				ext: make-tmp-vreg cg as rst-type! t
				opcode: either INT_WIDTH(t) > 32 [I_CQO][I_CDQ]
				def-vreg cg ext x86_EDX
				use-reg-fixed cg x x86_EAX
				emit-instr cg opcode or AM_OP_REG
			]
		][
			ext: get-vreg cg as instr! ir-graph/const-int-zero cg/fn
		]

		reg: either mod? [x86_EDX][x86_EAX]
		def-reg-fixed cg i reg
		reg: either mod? [x86_EAX][x86_EDX]
		kill cg reg
		use-reg-fixed cg x x86_EAX
		use-vreg cg ext x86_EDX
		reg: either target/arch = arch-x86 [x86_NOT_EDX][x64_NOT_RAX_RDX]
		use-reg-fixed cg input1 i reg
		opcode: either INT_SIGNED?(t) [I_IDIVD][I_DIVD]
		if INT_WIDTH(t) > 32 [opcode: opcode + I_W_DIFF]
		emit-instr cg opcode
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
			fn	[fn!]
			ft	[fn-type!]
	][
		o: as instr-op! i
		use-ptr cg o/target

		fn: as fn! o/target
		cc: target/make-cc fn o
		alloc-caller-space cg/frame cc
		
		if cc/ret-type <> type-system/void-type [
			def-reg-fixed cg i callee-ret cc 0
		]

		kill cg x86_REG_ALL
		live-point cg cc

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

	emit-default-cmp: func [
		cg		[codegen!]
		i		[instr!]
		return: [x86-cond-pair!]
	][
		use-i cg i
		use-imm-int cg 0
		emit-instr cg I_CMPB or AM_OP_IMM
		x86-cond/make-pair x86-cond/not-zero null no
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
			OP_BOOL_EQ	[
				emit-int-cmp cg i I_CMPB x86-cond/zero
			]
			OP_BOOL_NOT	[
				x86-cond/pair-neg emit-cmp cg i
			]
			OP_INT_EQ	[
				op: int-cmp-op as instr-op! i
				emit-int-cmp cg i op x86-cond/zero
			]
			OP_INT_LT	[
				o: as instr-op! i
				op: int-cmp-op o
				t: as int-type! o/param-types/value
				c: either INT_SIGNED?(t) [x86-cond/lesser][x86-cond/carry]
				emit-int-cmp cg i op c
			]
			OP_INT_LTEQ	[
				o: as instr-op! i
				op: int-cmp-op o
				t: as int-type! o/param-types/value
				c: either INT_SIGNED?(t) [x86-cond/lesser-eq][x86-cond/not-aux-carry]
				emit-int-cmp cg i op c
			]
			OP_PTR_EQ
			OP_PTR_LT
			OP_PTR_LTEQ
			OP_FLT_EQ
			OP_FLT_LT
			OP_FLT_LTEQ [null]
			default [emit-default-cmp cg i]
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

	match-rrsd: func [
		i		[instr!]
		addr	[rrsd!]
		/local
			c	[instr-const!]
			v	[val!]
			var [var-decl!]
	][
		if INSTR_CONST?(i) [
			c: as instr-const! i
			addr/base: null
			addr/index: null
			addr/scale: 1
			addr/disp: c/value
			exit
		]
	]

	do-rrsd: func [
		cg		[codegen!]
		addr	[rrsd!]
	][
		either null? addr/base [use-imm-int cg 0][
			use-reg cg addr/base
		]
		either null? addr/index [use-imm-int cg 0][
			use-reg cg addr/index
		]
		use-imm-int cg addr/scale
		use-imm cg addr/disp
	]

	emit-ptr-load: func [
		cg		[codegen!]
		i		[instr!]
		/local
			o	[instr-op!]
			vt	[rst-type!]
			sz	[integer!]
			op	[integer!]
			addr [rrsd! value]
	][
		o: as instr-op! i
		vt: o/ret-type
		sz: type-size? vt
		match-rrsd input0 i :addr
		either zero? sz [
			0
		][
			switch sz [
				1 [
					op: either int-signed? vt [I_MOVBSX][I_MOVBZX]
					op: AM_REG_RRSD or op
				]
				2 [
					op: either int-signed? vt [I_MOVWSX][I_MOVWZX]
					op: AM_REG_RRSD or op
				]
				4 [op: either FLOAT_TYPE?(vt) [AM_XMM_RRSD or I_MOVSS][AM_REG_RRSD or I_MOVD]]
				8 [op: either FLOAT_TYPE?(vt) [AM_XMM_RRSD or I_MOVSD][AM_REG_RRSD or I_MOVQ]]
				default [probe "invalid size for ptr load"]
			]
			def-reg cg i
			do-rrsd cg :addr
			emit-instr cg op
		]
	]

	emit-ptr-store: func [
		cg		[codegen!]
		i		[instr!]
		/local
			o	[instr-op!]
			vt	[rst-type!]
			sz	[integer!]
			op	[integer!]
			val [instr!]
			addr [rrsd! value]
	][
		o: as instr-op! i
		vt: o/ret-type
		sz: type-size? vt
		match-rrsd input0 i :addr
		do-rrsd cg :addr

		val: instr-input i 1
		either try-use-imm32 cg val [
			op: switch sz [
				0 [I_TESTD]
				1 [I_MOVB]
				2 [I_MOVW]
				4 [I_MOVD]
				8 [I_MOVQ]
				default [probe "invaild size for ptr store" I_NOP]
			]
			op: op or AM_RRSD_IMM
		][
			op: switch sz [
				0 [I_TESTD or AM_RRSD_REG]
				1 [I_MOVB or AM_RRSD_REG]
				2 [I_MOVW or AM_RRSD_REG]
				4 [either FLOAT_TYPE?(vt) [I_MOVSS or AM_RRSD_XMM][I_MOVD or AM_RRSD_REG]]
				8 [either FLOAT_TYPE?(vt) [I_MOVSD or AM_RRSD_XMM][I_MOVQ or AM_RRSD_REG]]
				default [probe "invalid size for ptr store" I_NOP]
			]
			use-reg cg val
		]
		emit-instr cg op
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
		/local
			conds [x86-cond-pair!]
			m	  [instr-matcher!]
			op	  [integer!]
	][
		;ir-printer/print-instr i
		switch INSTR_OPCODE(i) [
			OP_BOOL_EQ			
			OP_BOOL_NOT			
			OP_INT_EQ			
			OP_INT_LT			
			OP_INT_LTEQ			[
				conds: emit-cmp cg i
			]
			OP_BOOL_AND			[emit-simple-binop cg I_ANDD i]
			OP_BOOL_OR			[emit-simple-binop cg I_ORD i]
			OP_INT_ADD			[emit-int-binop cg I_ADDD i]
			OP_INT_SUB			[
				m: cg/m
				matcher/int-bin-op m i
				either all [m/x-const? zero? m/int-x][
					overwrite-reg cg i m/y
					op: op-with-width I_NEGD as instr-op! i
					emit-instr cg op or AM_OP
				][
					emit-int-binop cg I_SUBD i
				]
			]
			OP_INT_MUL			[
				m: cg/m
				op: op-with-width I_MULD as instr-op! i
				matcher/int-bin-op m i
				overwrite-reg cg i m/x
				either try-use-imm32 cg m/y [
					emit-instr cg op or AM_OP_IMM
				][
					use-i cg m/y
					emit-instr cg op or AM_REG_OP
				]
			]
			OP_INT_DIV			[emit-int-div cg i no]
			OP_INT_MOD			[emit-int-div cg i yes]
			OP_INT_REM			[0]
			OP_INT_AND			[emit-int-binop cg I_ANDD i]
			OP_INT_OR			[emit-int-binop cg I_ORD i]
			OP_INT_XOR			[emit-int-binop cg I_XORD i]
			OP_INT_SHL			[0]
			OP_INT_SAR			[0]
			OP_INT_SHR			[0]
			OP_INT_NE			[0]
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
			OP_PTR_LOAD			[emit-ptr-load cg i]
			OP_PTR_STORE		[emit-ptr-store cg i]
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
		f/cc: target/make-cc ir/fn null
		f/align: target/addr-align
		f/slot-size: target/addr-size
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
		either target/xmm-reg? idx [
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
				op: either target/xmm-reg? src [
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
			op: either target/xmm-reg? dst [
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
			either target/xmm-reg? dst [
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

	patch-call: func [
		ref		[integer!]
		dst		[integer!]
	][
		change-at-32 program/code-buf/data ref dst - ref - 4
	]
]