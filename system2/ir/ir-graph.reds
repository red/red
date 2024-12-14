Red/System [
	File: 	 %ir-graph.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;; /header, opcode: 0 - 7 bits, flags: 8 - 31 bits
#define IR_NODE_FIELDS(type) [
	header	[integer!]
	mark	[integer!]
	next	[type]
	prev	[type]
]

#define IR_INSTR_FIELDS(type) [
	IR_NODE_FIELDS(type)
	inputs	[ptr-array!]	;-- array<df-edge!>: [(src: self -> dst: input) ...]
	uses	[df-edge!]		;-- (src: user -> dst: self)
	instr	[instr!]		;-- map this instr -> instr
]

#define ADD_INS_FLAGS(i flags) [i/header: i/header or (flags << 8)]
#define INSTR_FLAGS(i) (i/header >>> 8)
#define INSTR_OPCODE(i) [i/header and FFh]
#define INSTR_END?(i) (i/header >>> 8 and F_INS_END <> 0)
#define INSTR_PHI?(i) (i/header and FFh = INS_PHI)
#define INSTR_CONST?(i) (i/header and FFh = INS_CONST)
#define INSTR_OP?(i) (i/header and FFh >= OP_BOOL_EQ)

;; a control flow edge
cf-edge!: alias struct! [
	src		[instr-end!]
	dst		[basic-block!]
	dst-idx [integer!]		;-- idx of this edge in dst's preds array
]

;; a data flow edge
df-edge!: alias struct! [
	src		[instr!]
	dst		[instr!]
	next	[df-edge!]
	prev	[df-edge!]
]

instr!: alias struct! [
	IR_INSTR_FIELDS(instr!)
]

;-- end instruction of a basic block
instr-end!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	succs	[ptr-array!]
]

;-- same as end
instr-return!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	succs	[ptr-array!]
]

instr-goto!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	succs	[ptr-array!]
]

instr-if!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	succs	[ptr-array!]
]

instr-const!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	type	[rst-type!]
	value	[cell!]
]

;-- instruction to create a function parameter
instr-param!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	type	[rst-type!]
	index	[integer!]
]

;-- instruction to create a variable
instr-var!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	type	[rst-type!]
	index	[integer!]
]

instr-update-var!: alias struct! [
	IR_INSTR_FIELDS(instr!)
]

instr-phi!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	type	[rst-type!]
	block	[basic-block!]
]

instr-op!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	target		[int-ptr!]
	n-params	[integer!]
	param-types	[ptr-ptr!]		;-- an array of types
	ret-type	[rst-type!]
]

basic-block!: alias struct! [
	;-- /next: point to the head instr
	;-- /prev: point to the last instr
	IR_NODE_FIELDS(instr!)
	preds	[ptr-array!]		;-- array<cf-edge!>
	marker	[integer!]
]

ir-fn!: alias struct! [
	mark		[integer!]		;-- mark generation
	params		[ptr-array!]	;-- array of instr-param!
	param-types	[ptr-ptr!]
	ret-type	[rst-type!]
	start-bb	[basic-block!]
	const-idx	[integer!]
	const-vals	[ptr-array!]	;-- array<instr-const!>
	const-map	[int-ptr!]
	fn			[fn!]
]

ir-module!: alias struct! [
	globals		[vector!]
	structs		[vector!]
	functions	[vector!]		;-- vector<ir-fn!>
]

ssa-merge!: alias struct! [
	block		[basic-block!]
	cur-vals	[ptr-array!]
	pred-vals	[ptr-array!]
	n-preds		[integer!]
]

ssa-ctx!: alias struct! [
	parent		[ssa-ctx!]
	graph		[ir-fn!]
	pt			[instr!]
	block		[basic-block!]
	cur-vals	[ptr-array!]		;-- array<instr!>
	ssa-vars	[ptr-array!]		;-- array<var-decl!>
	loop-start	[ssa-merge!]
	loop-end	[ssa-merge!]
	closed?		[logic!]			;-- block closed by exit, return, break, continue or goto
]

int-unbox: func [
	val		[cell!]
	return: [integer!]
	/local
		int [red-integer!]
][
	either null? val [0][
		either TYPE_OF(val) = TYPE_INTEGER [
			int: as red-integer! val
			int/value
		][
			probe "expected integer value"
			0
		]
	]
]

input0: func [
	i		[instr!]
	return: [instr!]
	/local
		p	[ptr-ptr!]
		e	[df-edge!]
][
	p: ARRAY_DATA(i/inputs)
	e: as df-edge! p/value
	e/dst
]

input1: func [
	i		[instr!]
	return: [instr!]
	/local
		p	[ptr-ptr!]
		e	[df-edge!]
][
	p: ARRAY_DATA(i/inputs)
	p: p + 1
	e: as df-edge! p/value
	e/dst
]

instr-type?: func [
	i		[instr!]
	return: [rst-type!]
	/local
		o	[instr-op!]
		v	[instr-var!]
][
	either INSTR_OP?(i) [
		o: as instr-op! i
		o/ret-type
	][
		v: as instr-var! i
		v/type
	]
]

instr-input: func [
	i		[instr!]
	idx		[integer!]
	return: [instr!]
	/local
		p	[ptr-ptr!]
		e	[df-edge!]
][
	p: ARRAY_DATA(i/inputs)
	p: p + idx
	e: as df-edge! p/value
	e/dst
]

make-ssa-var: func [
	return:		[ssa-var!]
	/local
		v		[ssa-var!]
][
	v: as ssa-var! malloc size? ssa-var!
	v/index: -1
	v
]

remove-uses: func [			;-- remove `edge` from `ins`'s use list
	edge	[df-edge!]
	ins		[instr!]
	/local
		n p	[df-edge!]
][
	p: edge/prev
	n: edge/next
	if ins/uses = edge [	;-- remove the head
		ins/uses: n
	]
	if p <> null [p/next: n]
	if n <> null [n/prev: p]
	edge/next: null
	edge/prev: null
]

insert-uses: func [			;-- insert `edge` into `ins`'s use list
	edge	[df-edge!]
	ins		[instr!]
	/local
		n p	[df-edge!]
][
	p: ins/uses
	edge/next: p
	if p <> null [p/prev: edge]
	ins/uses: edge
]

update-uses: func [
	edge	[df-edge!]
	dest	[instr!]
][
	if edge/dst <> null [remove-uses edge edge/dst]
	edge/dst: dest
	if dest <> null [insert-uses edge dest]
]

insert-instr: func [		;-- insert instr! y before x
	x		[instr!]
	y		[instr!]
	/local
		p	[instr!]
][
	p: x/prev
	if p <> null [
		p/next: y
		y/prev: p
	]
	x/prev: y
	y/next: x
]

remove-instr: func [		;-- remove instr! x
	x		[instr!]
][
	if x/prev <> null [x/prev/next: x/next]
	if x/next <> null [x/next/prev: x/prev]
	x/prev: null
	x/next: null	
]

replace-instr: func [
	"replace instr x with y in all uses"
	x		[instr!]
	y		[instr!]
][
	if x = y [exit]
	while [x/uses <> null][
		update-uses x/uses y ;-- update-uses modified x/uses
	]
]

kill-instr: func [			;-- remove x from the use list of its inputs
	x		[instr!]
	/local
		inputs	[ptr-array!]
		p		[ptr-ptr!]
][
	inputs: x/inputs
	p: ARRAY_DATA(inputs)
	loop inputs/length [
		update-uses as df-edge! p/value null
		p: p + 1
	]
]

block-append-instr: func [	;-- append instr to the end of a block
	bb		[basic-block!]
	ins		[instr!]
	/local
		p	[instr!]
][
	p: bb/prev
	unless INSTR_END?(p) [p: as instr! bb]
	insert-instr p ins
]

block-insert-instr: func [	;-- insert instr to the start of a block
	bb		[basic-block!]
	ins		[instr!]
][
	insert-instr bb/next ins
]

block-add-pred: func [		;-- add predecessor
	bb		[basic-block!]
	pred	[cf-edge!]
	return: [integer!]
][
	bb/preds: ptr-array/append bb/preds as byte-ptr! pred
	bb/preds/length - 1
]

block-successors: func [
	bb		[basic-block!]
	return: [ptr-array!]
	/local
		p	[instr-end!]
][
	p: as instr-end! bb/prev
	either INSTR_END?(p) [
		p/succs
	][
		null
	]
]

block-successor: func [
	bb		[basic-block!]
	idx		[integer!]
	return: [cf-edge!]
	/local
		succs	[ptr-array!]
		data	[ptr-ptr!]
][
	succs: block-successors bb
	if null? succs [return null]
	data: ARRAY_DATA(succs) + idx
	as cf-edge! data/value
]

block-end: func [
	bb		[basic-block!]
	return: [instr-end!]
	/local
		p	[instr!]
][
	p: bb/prev
	either INSTR_END?(p) [as instr-end! p][null]
]

bfs-blocks: func [		;-- breadth first search for a graph
	start-bb	[basic-block!]
	vec			[vector!]
	/local
		succs	[ptr-array!]
		i		[integer!]
		b		[basic-block!]
		e		[cf-edge!]
		pp		[ptr-ptr!]
][
	vector/clear vec
	succs: block-successors start-bb
	vector/append-ptr vec as byte-ptr! start-bb
	if any [null? succs zero? succs/length][exit]

	start-bb/marker: 1
	i: 0
	while [i < vec/length][
		b: as basic-block! vector/pick-ptr vec i
		succs: block-successors b
		if succs <> null [
			pp: ARRAY_DATA(succs)
			loop succs/length [
				e: as cf-edge! pp/value
				b: e/dst
				if b/marker < 1 [
					b/marker: 1
					vector/append-ptr vec as byte-ptr! b
				]
				pp: pp + 1
			]
		]
		i: i + 1
	]
	;-- clear mark
	pp: as ptr-ptr! vec/data
	loop vec/length [
		b: as basic-block! pp/value
		b/marker: -1
		pp: pp + 1
	]
]

#include %ir-printer.reds

#define N_COMMON_CONST		9
#define N_CACHED_CONST		13

;-- a graph of IR nodes in SSA form, machine independent
ir-graph: context [
	builder: declare visitor!
	init: does [
		builder/visit-assign:		as visit-fn! :visit-assign
		builder/visit-literal:		as visit-fn! :visit-literal
		builder/visit-lit-array:	as visit-fn! :visit-lit-array
		builder/visit-bin-op:		as visit-fn! :visit-bin-op
		builder/visit-var:			as visit-fn! :visit-var
		builder/visit-fn-call:		as visit-fn! :visit-fn-call
		builder/visit-native-call:	as visit-fn! :visit-native-call
		builder/visit-if:			as visit-fn! :visit-if
		builder/visit-while:		as visit-fn! :visit-while
		builder/visit-break:		as visit-fn! :visit-break
		builder/visit-continue:		as visit-fn! :visit-continue
		builder/visit-return:		as visit-fn! :visit-return
		builder/visit-comment:		as visit-fn! :visit-comment
		builder/visit-case:			as visit-fn! :visit-case
		builder/visit-switch:		as visit-fn! :visit-switch
		builder/visit-not:			as visit-fn! :visit-not
		builder/visit-size?:		as visit-fn! :visit-size?
		builder/visit-cast:			as visit-fn! :visit-cast
		builder/visit-declare:		as visit-fn! :visit-declare
		builder/visit-get-ptr:		as visit-fn! :visit-get-ptr
		builder/visit-path:			as visit-fn! :visit-path
		builder/visit-any-all:		as visit-fn! :visit-any-all
		builder/visit-throw:		as visit-fn! :visit-throw
		builder/visit-catch:		as visit-fn! :visit-catch
		builder/visit-assert:		as visit-fn! :visit-assert
	]

	visit-assign: func [
		a [assignment!] ctx [ssa-ctx!] return: [instr!]
		/local
			lhs	[rst-expr!]
			rhs	[rst-expr!]
			val [instr!]
			var [variable!]
	][
		lhs: a/target
		rhs: a/expr
		val: gen-expr rhs ctx
		switch NODE_TYPE(lhs) [
			RST_VAR [
				var: as variable! lhs
				gen-var-write var/decl val ctx
			]
			RST_PATH [
				gen-path-write as path! lhs val ctx
			]
			default [0]
		]
		val
	]

	visit-literal: func [e [literal!] ctx [ssa-ctx!] return: [instr!]][
		as instr! const-val e/type e/token ctx/graph
	]

	visit-lit-array: func [e [literal!] ctx [ssa-ctx!] return: [instr!]
		/local
			decl	[var-decl!]
			op		[instr-op!]
	][
		decl: parser/make-var-decl e/token null
		decl/init: as rst-expr! e
		decl/type: e/type
		record-global decl
		op: make-op OP_GET_GLOBAL 0 null decl/type
		op/target: as int-ptr! decl
		add-op op null ctx
	]

	visit-var: func [v [variable!] ctx [ssa-ctx!] return: [instr!]][
		gen-var-read v/decl ctx
	]

	visit-get-ptr: func [g [get-ptr!] ctx [ssa-ctx!] return: [instr!]
		/local
			e		[rst-expr!]
			op		[instr-op!]
	][
		e: g/expr
		op: make-op OP_GET_PTR 0 null g/type
		op/target: as int-ptr! e
		add-op op null ctx
	]

	visit-fn-call: func [fc [fn-call!] ctx [ssa-ctx!] return: [instr!]][
		add-fn-call fc ctx
	]

	visit-bin-op: func [bin [bin-op!] ctx [ssa-ctx!] return: [instr!]
		/local
			c	[integer!]
			ft	[fn-type!]
			op	[instr-op!]
			arr [array-2! value]
			lhs rhs tmp [instr!]
	][
		lhs: gen-expr bin/left ctx
		rhs: gen-expr bin/right ctx
		ft: bin/spec
		assert ft/n-params = 2
		op: make-op FN_OPCODE(ft) 2 ft/param-types ft/ret-type
		if FN_COMMUTE?(ft) [	;-- swap args
			tmp: lhs
			lhs: rhs
			rhs: tmp
		]
		INIT_ARRAY_2(arr lhs rhs)
		add-op op as ptr-array! :arr ctx
	]

	visit-if: func [e [if!] ctx [ssa-ctx!] return: [instr!]
		/local
			cond	[instr!]
			t-ctx	[ssa-ctx! value]
			f-ctx	[ssa-ctx! value]
			t-val	[instr!]
			f-val	[instr!]
			merge	[ssa-merge! value]
			arr2	[array-2! value]
			t-closed? [logic!]
			f-closed? [logic!]
	][
		cond: as instr! e/cond/accept as int-ptr! e/cond builder as int-ptr! ctx
		
		split-ssa-ctx ctx :t-ctx
		split-ssa-ctx ctx :f-ctx
		add-if cond t-ctx/block f-ctx/block ctx
		remove-instr cond

		t-val: gen-stmts e/t-branch t-ctx
		f-val: either e/f-branch <> null [gen-stmts e/f-branch f-ctx][add-default-value e/type f-ctx]

		t-closed?: t-ctx/closed?	;-- save it as merge-ctx will close the block
		f-closed?: f-ctx/closed?

		init-merge :merge
		merge-ctx :merge :t-ctx
		merge-ctx :merge :f-ctx
		set-ssa-ctx :merge ctx

		case [
			not t-closed? [
				either f-closed? [t-val][
					either t-val = f-val [t-val][
						INIT_ARRAY_2(arr2 t-val f-val)
						make-phi e/type merge/block as ptr-array! :arr2
					]
				]
			]
			not f-closed? [f-val]
			true [nop ctx/graph]
		]
	]

	visit-while: func [w [while!] ctx [ssa-ctx!] return: [instr!]
		/local
			cond	[instr!]
			m-start	[ssa-merge! value]
			m-end	[ssa-merge! value]
			loop-ctx [ssa-ctx! value]
			body-ctx [ssa-ctx! value]
			
	][
		init-merge :m-start		;-- merge point at the start of the loop
		start-loop w/loop-idx :m-start ctx

		init-ssa-ctx :loop-ctx ctx 0 m-start/block
		loop-ctx/cur-vals: ptr-array/copy m-start/cur-vals

		cond: gen-stmts w/cond loop-ctx
		if loop-ctx/closed? [return null]	;-- return or exit in condition block

		init-merge :m-end		;-- merge point at the end of the loop
		loop-ctx/loop-start: :m-start
		loop-ctx/loop-end: :m-end

		split-ssa-ctx loop-ctx :body-ctx
		add-if cond body-ctx/block m-end/block :loop-ctx
		merge-incoming :m-end :loop-ctx		;-- merge loop-ctx into m-end

		gen-stmts w/body :body-ctx
		merge-ctx :m-start :body-ctx		;-- merge body-ctx into m-start

		set-ssa-ctx :m-end ctx
		null
	]

	visit-break: func [b [break!] ctx [ssa-ctx!] return: [instr!]
		/local p [ssa-ctx!]
	][
		p: ctx
		while [p <> null][
			if p/loop-end <> null [
				merge-ctx p/loop-end ctx
				return null
			]
			p: p/parent
		]
		null
	]

	visit-continue: func [v [continue!] ctx [ssa-ctx!] return: [instr!]
		/local p [ssa-ctx!]
	][
		p: ctx
		while [p <> null][
			if p/loop-start <> null [
				merge-ctx p/loop-start ctx
				return null
			]
			p: p/parent
		]
		null
	]

	visit-return: func [r [return!] ctx [ssa-ctx!] return: [instr!]
		/local val [instr!]
	][
		val: either r/expr <> null [gen-expr r/expr ctx][null]
		add-return val ctx
		null
	]

	visit-path: func [p [path!] ctx [ssa-ctx!] return: [instr!]][
		gen-path-read p ctx
	]

	visit-any-all: func [p [path!] ctx [ssa-ctx!] return: [instr!]][
		null
	]

	visit-comment: func [r [rst-stmt!] ctx [ssa-ctx!] return: [instr!]][
		null
	]

	visit-switch: func [r [switch!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-case: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-not: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-size?: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-cast: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-declare: func [d [declare!] ctx [ssa-ctx!] return: [instr!]
		/local op [instr-op!]
	][
		record-global as var-decl! d
		op: make-op OP_GET_GLOBAL 0 null d/type
		op/target: as int-ptr! d
		add-op op null ctx
	]

	visit-throw: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-catch: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-native-call: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-assert: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	make-bb: func [		;-- create basic-block!
		return: [basic-block!]
		/local
			bb [basic-block!]
	][
		bb: as basic-block! malloc size? basic-block!
		bb/next: as instr! bb
		bb/prev: as instr! bb
		bb/preds: empty-array
		bb/mark: -1
		bb/marker: -1
		bb
	]

	make-param: func [
		param	[var-decl!]
		return: [instr-param!]
		/local
			p	[instr-param!]
	][
		p: as instr-param! malloc size? instr-param!
		p/header: INS_PARAM or (F_NOT_VOID << 8)
		p/index: param/ssa/index
		p/type: param/type
		param/ssa/instr: as instr! p
		p
	]

	make-ir-fn: func [
		fn			[fn!]
		ctx			[ssa-ctx!]
		return:		[ir-fn!]
		/local
			ir		[ir-fn!]
			ft		[fn-type!]
			param	[var-decl!]
			ssa		[ssa-var!]
			parr	[ptr-array!]
			p		[ptr-ptr!]
			pp		[ptr-ptr!]
			pv		[ptr-ptr!]
			ins		[instr!]
	][
		ir: as ir-fn! malloc size? ir-fn!
		ir/fn: fn
		ir/start-bb: make-bb
		ir/const-idx: N_COMMON_CONST
		ctx/graph: ir
		ctx/block: ir/start-bb
		either fn <> null [
			ft: as fn-type! fn/type
			parr: ptr-array/make ft/n-params
			p: ARRAY_DATA(parr)
			pp: ARRAY_DATA(ctx/ssa-vars)
			param: ft/params
			while [param <> null][
				ins: as instr! make-param param
				p/value: as int-ptr! ins
				ssa: param/ssa
				if ssa/index > -1 [
					pv: pp + ssa/index
					pv/value: as int-ptr! param
					set-cur-val ssa param/type ins ctx
				]
				p: p + 1
				param: param/next
			]
			ir/params: parr
			ir/param-types: ft/param-types
			ir/ret-type: ft/ret-type
			fn/ir: ir
		][
			ir/ret-type: type-system/void-type
		]
		ir
	]

	make-phi: func [
		type	[rst-type!]
		blk		[basic-block!]
		args	[ptr-array!]
		return: [instr-phi!]
		/local
			phi [instr-phi!]
	][
		phi: as instr-phi! malloc size? instr-phi!
		phi/header: INS_PHI or (F_NOT_VOID << 8)
		phi/type: type
		phi/block: blk
		set-inputs as instr! phi args
		block-insert-instr blk as instr! phi
		phi
	]

	init-ssa-ctx: func [
		ctx		[ssa-ctx!]
		parent	[ssa-ctx!]
		n-vars	[integer!]
		bb		[basic-block!]
		return: [ssa-ctx!]
	][
		set-memory as byte-ptr! ctx null-byte size? ssa-ctx!

		ctx/parent: parent
		ctx/block: bb
		either parent <> null [
			ctx/cur-vals: parent/cur-vals
			ctx/ssa-vars: parent/ssa-vars
			ctx/graph: parent/graph
		][
			ctx/cur-vals: ptr-array/make n-vars
			ctx/ssa-vars: ptr-array/make n-vars
		]
		ctx
	]

	start-loop: func [
		loop-idx	[integer!]
		m			[ssa-merge!]
		ctx			[ssa-ctx!]
		/local
			ssa-vars	[ptr-array!]
			p			[ptr-ptr!]
			pp			[ptr-ptr!]
			pv			[ptr-ptr!]
			var			[var-decl!]
			nctx		[ssa-ctx!]
	][
		m/cur-vals: ptr-array/copy ctx/cur-vals
		p: ARRAY_DATA(m/cur-vals)

		ssa-vars: ctx/ssa-vars
		pp: ARRAY_DATA(ssa-vars)
		loop ssa-vars/length [
			var: as var-decl! pp/value
			assert var <> null
			if written-in-loop? var/ssa loop-idx [
				pv: p + var/ssa/index
				pv/value: as int-ptr! make-phi var/type m/block null
			]
			pp: pp + 1
		]
		merge-ctx m ctx
	]

	init-merge: func [
		m		[ssa-merge!]
	][
		m/block: make-bb
		m/cur-vals: null
		m/pred-vals: ptr-array/make 2
		m/n-preds: 0
	]

	set-ssa-ctx: func [
		m		[ssa-merge!]
		ctx		[ssa-ctx!]
	][
		either m/n-preds > 0 [
			ctx/block: m/block
			ctx/cur-vals: m/cur-vals
			ctx/closed?: no
		][
			ctx/block: null
			ctx/cur-vals: null
			ctx/closed?: yes
		]
	]

	kill-var: func [
		v		[instr!]
		m		[ssa-merge!]
		/local
			p	[instr-phi!]
	][
		if INSTR_PHI?(v) [
			p: as instr-phi! v
			if p/block = m/block [
				kill-instr v
				remove-instr v
			]
		]
	]

	split-ssa-ctx: func [
		p-ctx	[ssa-ctx!]		;-- parent context
		ctx		[ssa-ctx!]
		return: [ssa-ctx!]
	][
		init-ssa-ctx ctx p-ctx p-ctx/cur-vals/length make-bb
	]

	merge-incoming: func [
		m		[ssa-merge!]
		ctx		[ssa-ctx!]
		/local
			succs	[ptr-array!]
			n		[integer!]
			p		[ptr-ptr!]
			e		[cf-edge!]
	][
		succs: block-successors ctx/block
		if succs <> null [
			p: ARRAY_DATA(succs)
			n: succs/length
			loop n [
				e: as cf-edge! p/value
				if e/dst = m/block [merge-edge e m ctx]
				p: p + 1
			]
		]
	]

	merge-latest: func [
		m		[ssa-merge!]
		ctx		[ssa-ctx!]
		/local
			n i		[integer!]
			n-preds	[integer!]
			vals	[ptr-array!]
			p		[ptr-ptr!]
			mp		[ptr-ptr!]
			pred-v	[instr!]
			v		[instr!]
			phi		[instr-phi!]
			e		[df-edge!]
			inputs	[ptr-array!]
			parr	[ptr-ptr!]
			pv		[ptr-ptr!]
			pp		[ptr-ptr!]
			var		[var-decl!]
	][
		;-- merge latest added predecessor's vals
		n-preds: m/n-preds
		p: ARRAY_DATA(m/pred-vals) + (n-preds - 1)
		vals: as ptr-array! p/value

		p: ARRAY_DATA(vals)
		mp: ARRAY_DATA(m/cur-vals)
		n: vals/length
		i: 0
		loop n [
			pred-v: as instr! p/value
			v: as instr! mp/value
			if v <> null [
				either null? pred-v [	;-- this var is dead on this edge
					kill-var v m
					mp/value: null
				][
					either INSTR_PHI?(v) [
						phi: as instr-phi! v
						if phi/block = m/block [
							e: make-df-edge v pred-v
							phi/inputs: ptr-array/append phi/inputs as byte-ptr! e
						]
					][
						;-- add a new phi
						if v <> pred-v [
							inputs: ptr-array/make n-preds
							parr: ARRAY_DATA(m/pred-vals)
							pp: ARRAY_DATA(inputs)
							loop n-preds [
								vals: as ptr-array! parr/value
								pv: ARRAY_DATA(vals) + i
								pp/value: pv/value
								parr: parr + 1
								pp: pp + 1
							]
							pp: ARRAY_DATA(ctx/ssa-vars) + i
							var: as var-decl! pp/value
							mp/value: as int-ptr! make-phi var/type m/block inputs
						]
					]
				]
			]
			i: i + 1
			p: p + 1
			mp: mp + 1
		]
	]

	merge-edge: func [
		e		[cf-edge!]
		m		[ssa-merge!]
		ctx		[ssa-ctx!]
		/local
			preds	[ptr-array!]
			p		[ptr-ptr!]
			i		[integer!]
	][
		assert e/dst = m/block

		preds: m/pred-vals
		i: m/n-preds
		if i >= preds/length [
			preds: ptr-array/grow preds preds/length + 4
			m/pred-vals: preds
		]
		p: ARRAY_DATA(preds) + i
		p/value: as int-ptr! ctx/cur-vals
		m/n-preds: i + 1

		either null? m/cur-vals [m/cur-vals: ptr-array/copy ctx/cur-vals][
			merge-latest m ctx
		]
	]

	merge-ctx: func [
		m		[ssa-merge!]
		ctx		[ssa-ctx!]
		/local
			e	[cf-edge!]
	][
		unless ctx/closed? [
			add-goto m/block ctx
			e: block-successor ctx/block 0
			merge-edge e m ctx
		]
	]

	do-cast: func [
		from-ty	[rst-type!]
		to-ty	[rst-type!]
		value	[instr!]
		return: [instr!]
	][
		value
	]

	append: func [
		i		[instr!]
		ctx		[ssa-ctx!]
	][
		either null? ctx/pt [
			block-append-instr ctx/block i
		][insert-instr ctx/pt i]
	]

	has-phi?: func [
		bb		[basic-block!]
	][
		INSTR_OPCODE(bb/next) = INS_PHI
	]

	make-df-edge: func [
		src		[instr!]
		dest	[instr!]
		return: [df-edge!]
		/local
			e	[df-edge!]
	][
		e: as df-edge! malloc size? df-edge!
		e/src: src
		e/dst: dest
		if dest <> null [insert-uses e dest]
		e
	]

	make-cf-edge: func [
		src		[instr-end!]
		dest	[basic-block!]
		return: [cf-edge!]
		/local
			e	[cf-edge!]
	][
		e: as cf-edge! malloc size? cf-edge!
		e/src: src
		e/dst: dest
		if dest <> null [
			e/dst-idx: block-add-pred dest e
		]
		e
	]

	set-inputs: func [			;-- set the inputs of an instruction
		ins		[instr!]
		vals	[ptr-array!]
		/local
			inputs	[ptr-array!]
			p		[ptr-ptr!]
			val		[ptr-ptr!]
	][
		if ins/inputs <> null [kill-instr ins]
		either all [vals <> null vals/length > 0][
			inputs: ptr-array/make vals/length
			p: ARRAY_DATA(inputs)
			val: ARRAY_DATA(vals)
			loop vals/length [
				p/value: as int-ptr! make-df-edge ins as instr! val/value
				p: p + 1
				val: val + 1
			]
			ins/inputs: inputs
		][
			ins/inputs: empty-array
		]
	]

	set-succs: func [
		ins		[instr-end!]
		dest	[ptr-array!]
		/local
			s	[ptr-array!]
			p	[ptr-ptr!]
			pp	[ptr-ptr!]
	][
		s: ptr-array/make dest/length
		p: ARRAY_DATA(s)
		pp: ARRAY_DATA(dest)
		loop s/length [
			p/value: as int-ptr! make-cf-edge ins as basic-block! pp/value
			p: p + 1
			pp: pp + 1
		]
		ins/succs: s
	]

	gen-stmts: func [
		stmt	[rst-stmt!]
		ctx		[ssa-ctx!]
		return: [instr!]		;-- return instr of last expression
		/local
			i	[instr!]
	][
		while [stmt <> null][
			i: as instr! stmt/accept as int-ptr! stmt builder as int-ptr! ctx
			stmt: stmt/next
		]
		i
	]

	gen-expr: func [
		e		[rst-expr!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			i	[instr!]
			cast [rst-type!]
			
	][
		unless ctx/closed? [
			i: as instr! e/accept as int-ptr! e builder as int-ptr! ctx
			if e/cast-type <> null [
				do-cast e/cast-type e/type i
			]
		]
		i
	]

	get-cur-val: func [
		var			[ssa-var!]
		cur-vals	[ptr-array!]
		return:		[instr!]
		/local
			p		[ptr-ptr!]
	][
		either var/index >= 0 [
			p: ARRAY_DATA(cur-vals) + var/index
			as instr! p/value
		][
			var/instr
		]
	]

	set-cur-val: func [
		var			[ssa-var!]
		type		[rst-type!]
		val			[instr!]
		ctx			[ssa-ctx!]
		/local
			p arr	[ptr-ptr!]
			idx		[integer!]
			op		[instr-op!]
			args	[array-value!]
	][
		idx: var/index
		case [
			idx >= 0 [
				if all [
					ctx/parent <> null
					ctx/parent/cur-vals = ctx/cur-vals
				][
					ctx/cur-vals: ptr-array/copy ctx/parent/cur-vals
				]
				p: ARRAY_DATA(ctx/cur-vals) + var/index
				p/value: as int-ptr! val
			]
			idx = -1 [var/instr: val]
			idx = -2 [		;-- local is forced on stack
				arr: as ptr-ptr! malloc size? int-ptr!
				arr/value: as int-ptr! type
				op: make-op OP_SET_LOCAL 1 arr type-system/void-type
				op/target: as int-ptr! var
				INIT_ARRAY_VALUE(args val)
				add-op op as ptr-array! :args ctx
			]
			true [probe ["set-cur-val: " idx]]
		]
	]

	make-goto: func [
		target	[basic-block!]
		return: [instr!]
		/local
			g	[instr-goto!]
			arr [array-value!]
	][
		g: as instr-goto! malloc size? instr-goto!
		g/header: F_INS_END << 8 or INS_GOTO
		INIT_ARRAY_VALUE(arr target)
		set-succs as instr-end! g as ptr-array! :arr
		as instr! g
	]

	add-goto: func [
		target	[basic-block!]
		ctx		[ssa-ctx!]
	][
		unless ctx/closed? [
			ctx/closed?: yes
			block-append-instr ctx/block make-goto target
		]
	]

	const-null: func [
		type	[rst-type!]
		fn		[ir-fn!]
		return: [instr-const!]
	][
		switch TYPE_KIND(type) [
			RST_TYPE_LOGIC [const-false fn]
			RST_TYPE_INT [const-int-zero fn]
			RST_TYPE_VOID [nop fn]
			default [get-const type null fn]
		]
	]

	const-int: func [
		val		[red-integer!]
		fn		[ir-fn!]
		return: [instr-const!]
	][
		switch val/value [
			0 [const-int-zero fn]
			1 [const-int-one fn]
			2 [const-int-two fn]
			4 [const-int-four fn]
			default [get-const type-system/integer-type as cell! val fn]
		]
	]

	const-int64: func [
		val		[red-integer!]
		fn		[ir-fn!]
		return: [instr-const!]
	][
		switch val/value [
			0 [const-int-zero fn]
			1 [const-int-one fn]
			2 [const-int-two fn]
			4 [const-int-four fn]
			default [get-const type-system/int64-type as cell! val fn]
		]
	]

	const-float: func [
		val		[red-float!]
		fn		[ir-fn!]
		return: [instr-const!]
		/local
			f	[float!]
	][
		f: val/value
		case [
			f = 0.0 [const-float-zero fn]
			f = 1.0 [const-float-one fn]
			true [get-const type-system/float-type as cell! val fn]
		]
	]

	nop: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 0 type-system/void-type null fn
	]

	const-true: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 1 type-system/logic-type common-literals/logic-true fn
	]

	const-false: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 2 type-system/logic-type common-literals/logic-false fn
	]

	const-int-zero: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 3 type-system/integer-type common-literals/int-zero fn
	]

	const-int-one: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 4 type-system/integer-type common-literals/int-one fn
	]

	const-int-two: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 5 type-system/integer-type common-literals/int-two fn
	]

	const-int-four: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 6 type-system/integer-type common-literals/int-four fn
	]

	const-float-zero: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 7 type-system/float-type common-literals/float-zero fn
	]

	const-float-one: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 8 type-system/float-type common-literals/float-one fn
	]

	get-cached-const: func [
		idx		[integer!]
		type	[rst-type!]
		val		[cell!]
		fn		[ir-fn!]
		return: [instr-const!]
		/local
			p	[ptr-ptr!]
	][
		if fn/const-vals <> null [
			p: ARRAY_DATA(fn/const-vals) + idx
			if p/value <> null [
				return as instr-const! p/value
			]
		]
		make-const idx type val fn
	]

	get-const: func [
		type	[rst-type!]
		val		[cell!]
		fn		[ir-fn!]
		return: [instr-const!]
		/local
			v	[red-handle!]
			c	[instr-const!]
			p	[ptr-ptr!]
			n	[integer!]
			vals [ptr-array!]
	][
		either fn/const-map <> null [
			v: token-map/get fn/const-map val yes
			if v <> null [return as instr-const! v/value]
		][
			vals: fn/const-vals
			if vals <> null [
				p: ARRAY_DATA(vals) + N_COMMON_CONST
				n: fn/const-idx - N_COMMON_CONST
				loop n [
					c: as instr-const! p/value
					if red/actions/compare c/value val COMP_STRICT_EQUAL [
						return c
					]
				]
			]
		]
		n: fn/const-idx
		fn/const-idx: n + 1
		make-const n type val fn
	]

	const-val: func [
		type	[rst-type!]
		val		[cell!]
		fn		[ir-fn!]
		return: [instr-const!]
		/local
			b	[red-logic!]
			i [red-integer!]
	][
		either null? val [const-null type fn][
			switch TYPE_KIND(type) [
				RST_TYPE_LOGIC [
					b: as red-logic! val
					either b/value [const-true fn][const-false fn]
				]
				RST_TYPE_INT [
					i: as red-integer! val
					either all [i/value >= 0 INT_WIDTH(type) <= 32] [
						const-int as red-integer! val fn
					][
						const-int64 as red-integer! val fn
					]
				]
				RST_TYPE_FLOAT [
					const-float as red-float! val fn
				]
				default [get-const type val fn]
			]
		]
	]

	make-const: func [
		idx		[integer!]
		type	[rst-type!]
		val		[cell!]
		fn		[ir-fn!]
		return: [instr-const!]
		/local
			c		[instr-const!]
			vals	[ptr-array!]
			map		[int-ptr!]
			p		[ptr-ptr!]
			v		[instr-const!]
			flags	[integer!]
	][
		c: as instr-const! malloc size? instr-const!
		flags: either type <> type-system/void-type [F_NOT_VOID << 8][0]
		c/header: INS_CONST or flags
		c/type: type
		c/value: val

		map: fn/const-map
		vals: fn/const-vals
		either null? vals [
			vals: ptr-array/make N_CACHED_CONST
			fn/const-vals: vals
		][
			if fn/const-idx = vals/length [
				map: token-map/make 50
				fn/const-map: map
				p: ARRAY_DATA(vals)
				loop vals/length [
					v: as instr-const! p/value
					if v <> null [
						token-map/put map v/value as int-ptr! v
					]
					p: p + 1
				]
			]
		]
		if map <> null [token-map/put map c/value as int-ptr! c]
		if idx < N_CACHED_CONST [
			p: ARRAY_DATA(vals) + idx
			p/value: as int-ptr! c
		]
		c
	]
	
	add-if: func [
		cond	[instr!]
		t-blk	[basic-block!]
		f-blk	[basic-block!]
		ctx		[ssa-ctx!]
		/local
			i	[instr-if!]
			arr [array-2! value]
	][
		i: as instr-if! malloc size? instr-if!
		i/header: F_INS_END << 8 or INS_IF

		INIT_ARRAY_VALUE(arr cond)
		set-inputs as instr! i as ptr-array! :arr

		INIT_ARRAY_2(arr t-blk f-blk)
		set-succs as instr-end! i as ptr-array! :arr

		ctx/closed?: yes
		append as instr! i ctx
	]

	add-fn-call: func [
		fc		[fn-call!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			ft	[fn-type!]
			fn	[fn!]
			arg [rst-expr!]
			op	[instr-op!]
			arr [ptr-array!]
			p	[ptr-ptr!]
			np	[integer!]
	][
		fn: fc/fn
		ft: as fn-type! fn/type
		np: ft/n-params
		op: make-op OP_CALL_FUNC np ft/param-types ft/ret-type
		op/target: as int-ptr! fn

		if np = -1 [		;-- variadic function, count args
			np: 0
			arg: fc/args
			while [arg <> null][
				np: np + 1
				arg: arg/next
			]
			op/n-params: np
			p: as ptr-ptr! malloc np * size? int-ptr!
			op/param-types: p
			arg: fc/args
			while [arg <> null][
				p/value: as int-ptr! arg/type
				p: p + 1
				arg: arg/next
			]
		]

		arr: ptr-array/make np
		p: ARRAY_DATA(arr)
		arg: fc/args
		while [arg <> null][
			p/value: arg/accept as int-ptr! arg builder as int-ptr! ctx
			p: p + 1
			arg: arg/next
		]
		add-op op arr ctx
	]

	make-op: func [
		opcode	 [opcode!]
		n-params [integer!]
		param-t	 [ptr-ptr!]
		ret-t	 [rst-type!]
		return:  [instr-op!]
		/local
			op	 [instr-op!]
			flags [integer!]
	][
		op: as instr-op! malloc size? instr-op!
		flags: either ret-t <> type-system/void-type [F_NOT_VOID << 8][0]
		op/header: opcode or flags
		op/n-params: n-params
		op/param-types: param-t
		op/ret-type: ret-t
		op
	]

	add-op: func [
		op		[instr-op!]
		args	[ptr-array!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			i flags [integer!]
	][
		set-inputs as instr! op args
		unless ctx/closed? [append as instr! op ctx]
		i: INSTR_OPCODE(op) + 1
		flags: instr-flags/i
		ADD_INS_FLAGS(op flags)
		as instr! op
	]

	add-default-value: func [
		type		[rst-type!]
		ctx			[ssa-ctx!]
		return:		[instr!]
		/local
			ins		[instr!]
			op		[instr-op!]
	][
		as instr! const-null type ctx/graph
		;op: make-op OP_DEFAULT_VALUE 0 null type
		;add-op op null ctx
	]

	add-int-cast: func [
		"cast the result of instr i, from int to int"
		i			[instr-op!]
		t-from		[rst-type!]
		t-to		[rst-type!]
		ctx			[ssa-ctx!]
		return:		[instr!]
		/local
			op		[instr-op!]
			param	[ptr-ptr!]
			args	[array-value!]
	][
		if t-from = t-to [return as instr! i]
		param: as ptr-ptr! malloc size? int-ptr!
		param/value: as int-ptr! t-from
		op: make-op OP_INT_CAST 1 param t-to
		INIT_ARRAY_VALUE(args i)
		add-op op as ptr-array! :args ctx
	]

	make-local-var: func [
		type	[rst-type!]
		return: [instr!]
		/local
			v	[instr-var!]
	][
		v: xmalloc(instr-var!)
		v/header: INS_VAR or (F_NOT_VOID << 8)
		v/type: type
		as instr! v
	]

	add-new-var: func [
		type	[rst-type!]
		idx		[integer!]
		vals	[ptr-array!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			v	[instr-var!]
	][
		v: as instr-var! malloc size? instr-var!
		v/header: INS_VAR or (F_NOT_VOID << 8)
		v/type: type
		v/index: idx
		set-inputs as instr! v vals
		block-append-instr ctx/block as instr! v
		as instr! v
	]

	add-return: func [
		val		[instr!]
		ctx		[ssa-ctx!]
		/local
			arr [array-value!]
			r	[instr-return!]
	][
		if ctx/closed? [exit]
		ctx/closed?: yes

		either val <> null [
			INIT_ARRAY_VALUE(arr val)
		][
			arr/length: 0		;-- emtpy array
		]
		r: as instr-return! malloc size? instr-return!
		r/header: F_INS_END << 8 or INS_RETURN
		set-inputs as instr! r as ptr-array! :arr
		block-append-instr ctx/block as instr! r
	]

	gen-path-write: func [
		p		[path!]
		val		[instr!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			var		[var-decl!]
			type	[rst-type!]
			m		[member!]
			obj		[instr!]
			op		[instr-op!]
			ptypes	[ptr-ptr!]
			args	[array-2! value]
	][
		var: p/receiver
		obj: gen-var-read var ctx

		type: var/type
		switch TYPE_KIND(type) [
			RST_TYPE_STRUCT [
				m: p/subs
				until [
					either null? m/next [
						ptypes: as ptr-ptr! malloc 2 * size? int-ptr!
						op: make-op OP_SET_FIELD 2 ptypes type-system/void-type
						ptypes/value: as int-ptr! type
						ptypes: ptypes + 1
						ptypes/value: as int-ptr! m/type
						INIT_ARRAY_2(args obj val)
						add-op op as ptr-array! :args ctx
					][
						ptypes: as ptr-ptr! malloc size? int-ptr!
						ptypes/value: as int-ptr! type
						op: make-op OP_GET_FIELD 1 ptypes m/type
						type: m/type
						INIT_ARRAY_VALUE(args obj)
						obj: add-op op as ptr-array! :args ctx
					]
					op/target: as int-ptr! m
					m: m/next
					null? m
				]
			]
			default [0]
		]
		val
	]

	path-member-read: func [
		obj		[instr!]
		type	[rst-type!]
		m		[member!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			op		[instr-op!]
			pp		[ptr-ptr!]
			ptypes	[ptr-ptr!]
			args	[array-2! value]
			idx		[instr!]
			int		[red-integer!]
	][
		switch TYPE_KIND(type) [
			RST_TYPE_STRUCT [
				ptypes: as ptr-ptr! malloc size? int-ptr!
				ptypes/value: as int-ptr! type
				op: make-op OP_GET_FIELD 1 ptypes m/type
				op/target: as int-ptr! m
				INIT_ARRAY_VALUE(args obj)
			]
			RST_TYPE_PTR RST_TYPE_ARRAY [
				ptypes: as ptr-ptr! malloc 2 * size? int-ptr!
				pp: ptypes
				pp/value: as int-ptr! type
				pp: pp + 1
				pp/value: as int-ptr! type-system/integer-type		;-- index type
				op: make-op OP_ARRAY_GET 2 ptypes m/type
				op/target: as int-ptr! m

				idx: either m/expr <> null [gen-expr m/expr ctx][
					int: as red-integer! m/token
					int/header: TYPE_INTEGER
					int/value: m/index
					as instr! const-int int ctx/graph
				]
				INIT_ARRAY_2(args obj idx)
			]
			default [
				dprint ["path-member-read error: " type]
				halt
			]
		]
		add-op op as ptr-array! :args ctx
	]

	gen-path-read: func [
		p		[path!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			var		[var-decl!]
			type	[rst-type!]
			m		[member!]
			obj		[instr!]
	][
		var: p/receiver
		obj: gen-var-read var ctx

		m: p/subs
		type: var/type
		until [
			obj: path-member-read obj type m ctx
			type: m/type
			m: m/next
			null? m
		]
		obj
	]

	gen-var-read: func [
		decl	[var-decl!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			op	[instr-op!]
			t	[rst-type!]
	][
		either LOCAL_VAR?(decl) [
			t: decl/type
			either STRUCT_VALUE?(t) [
				op: make-op OP_GET_PTR 0 null t
				op/target: as int-ptr! decl
				add-op op null ctx
			][
				get-cur-val decl/ssa ctx/cur-vals
			]
		][
			record-global decl
			op: make-op OP_GET_GLOBAL 0 null decl/type
			op/target: as int-ptr! decl
			add-op op null ctx
		]
	]

	gen-var-write: func [
		var		[var-decl!]
		val		[instr!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			op	[instr-op!]
			arr [ptr-ptr!]
			args [array-value!]
	][
		either LOCAL_VAR?(var) [
			set-cur-val var/ssa var/type val ctx
		][
			record-global var
			arr: as ptr-ptr! malloc size? int-ptr!
			arr/value: as int-ptr! var/type
			op: make-op OP_SET_GLOBAL 1 arr type-system/void-type
			op/target: as int-ptr! var
			INIT_ARRAY_VALUE(args val)
			add-op op as ptr-array! :args ctx
		]
		val
	]

	gen-var: func [
		var		[var-decl!]
		ctx		[ssa-ctx!]
		/local
			ssa [ssa-var!]
			idx [integer!]
			p	[ptr-ptr!]
	][
		ssa: var/ssa
		idx: ssa/index
		if idx > -1 [
			p: ARRAY_DATA(ctx/ssa-vars) + idx
			p/value: as int-ptr! var
		]
	]

	generate: func [
		fn		[fn!]
		ctx		[context!]
		return: [ir-fn!]
		/local
			ssa-ctx [ssa-ctx! value]
			graph	[ir-fn!]
			stmt	[rst-stmt!]
			n		[integer!]
			kv		[int-ptr!]
			var		[var-decl!]
			decls	[int-ptr!]
			val		[instr!]
	][
		assert fn/ir = null

		init-ssa-ctx :ssa-ctx null ctx/n-ssa-vars null
		graph: make-ir-fn fn :ssa-ctx

		if ctx/n-ssa-vars > 0 [
			decls: ctx/decls
			n: hashmap/size? decls
			kv: null
			loop n [
				kv: hashmap/next decls kv
				var: as var-decl! kv/2
				if all [
					NODE_TYPE(var) = RST_VAR_DECL
					NODE_FLAGS(var) and RST_VAR_PARAM = 0	;-- not a parameter
				][
					gen-var var :ssa-ctx
				]
			]
		]

		stmt: ctx/stmts
		while [
			stmt: stmt/next
			stmt <> null
		][
			stmt/accept as int-ptr! stmt builder as int-ptr! :ssa-ctx
		]

		fn/body: null
		graph
	]
]