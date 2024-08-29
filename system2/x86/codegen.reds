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

x86-reg-set: context [
	regs: as reg-set! 0

	init: func [/local arr [ptr-array!] p pa [ptr-ptr!]][
		arr: ptr-array/make x86_REG_ALL + 1
		p: ARRAY_DATA(arr)
		pa: p + x86_EAX

		regs: as reg-set! malloc size? reg-set!
		regs/n-regs: 14
		regs/regs: arr
		regs/spill-start: arr/length
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
			cls: backend/reg-class? param/type
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
			cls: backend/reg-class? fn/ret-type
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

x86-generate: func [
	ir		[ir-fn!]
	frame	[frame!]
][
	
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
