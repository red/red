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
#define INSTR_GET_PTR?(i) (i/header >> 8 and F_GET_PTR <> 0)
#define INSTR_RET_STRUCT?(i) (i/header >> 8 and F_RET_STRUCT <> 0)
#define INSTR_RET_NORMAL?(i) (i/header >> 8 and F_RET_STRUCT = 0)
#define INSTR_ALIVE?(i) (i/header >> 8 and F_INS_KILLED = 0)
#define INSTR_PURE?(i) (i/header >> 8 and F_INS_PURE <> 0)
#define INSTR_NOT_PURE?(i) (i/header >> 8 and F_INS_PURE = 0)
#define INSTR_KILLED?(i) (i/header >> 8 and F_INS_KILLED <> 0)
#define INSTR_END?(i) (i/header >>> 8 and F_INS_END <> 0)
#define INSTR_ASSIGN?(i) (i/header >> 8 and F_ASSIGN? <> 0)
#define INSTR_PHI?(i) (i/header and FFh = INS_PHI)
#define INSTR_CONST?(i) (i/header and FFh = INS_CONST)
#define INSTR_OP?(i) (i/header and FFh >= OP_BOOL_EQ)
#define INSTR_VAR?(i) (i/header and FFh = INS_VAR)

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
	type	[rst-type!]
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
	n-typed		[integer!]
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
	catch-end	[ssa-merge!]
	closed?		[logic!]			;-- block closed by exit, return, break, continue or goto
	st-var		[var-decl!]
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
	var			[var-decl!]
	return:		[ssa-var!]
	/local
		v		[ssa-var!]
][
	v: as ssa-var! malloc size? ssa-var!
	v/index: -1
	v/decl: var
	var/ssa: v
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

#define N_COMMON_CONST		10
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
		builder/visit-until:		as visit-fn! :visit-until
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
		builder/visit-context:		as visit-fn! :visit-context
		builder/visit-sys-alias:	as visit-fn! :visit-sys-alias
	]

	visit-assign: func [
		a [assignment!] ctx [ssa-ctx!] return: [instr!]
		/local
			lhs	[rst-expr!]
			rhs	[rst-expr!]
			val [instr!]
			ins [instr!]
			op	[instr-op!]
			var [variable!]
			args [array-2! value]
	][
		lhs: a/target
		rhs: a/expr
		val: gen-expr rhs ctx
		ADD_INS_FLAGS(val F_ASSIGN?)
		switch NODE_TYPE(lhs) [
			RST_VAR [
				var: as variable! lhs
				gen-var-write var/decl val rhs/type ctx
			]
			RST_PATH [
				either all [STRUCT_VALUE?(rhs/type) NOT_STRUCT_VALUE?(lhs/type)][
					ins: gen-path-read as path! lhs ctx 0
					op: make-op OP_SET_FIELD 2 null rhs/type
					INIT_ARRAY_2(args ins val)
					op/target: null
					add-op op as ptr-array! :args ctx
				][
					gen-path-write as path! lhs val ctx
				]
			]
			default [0]
		]
		val
	]

	make-global-literal: func [
		e		[literal!]
		t		[rst-type!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			decl [var-decl!]
			op	 [instr-op!]
	][
		decl: parser/make-var-decl e/token null
		decl/init: as rst-expr! e
		decl/type: t
		record-global decl
		op: make-op OP_GET_GLOBAL 0 null t
		op/target: as int-ptr! decl
		add-op op null ctx
	]

	visit-literal: func [e [literal!] ctx [ssa-ctx!] return: [instr!]
		/local t [rst-type!]
	][
		if NODE_TYPE(e) = RST_NULL [return as instr! const-null ctx/graph]
		t: e/type
		either FLOAT_TYPE?(t) [
			make-global-literal e t ctx
		][
			as instr! const-val t e/token ctx/graph
		]
	]

	visit-lit-array: func [e [literal!] ctx [ssa-ctx!] return: [instr!]][
		make-global-literal e e/type ctx
	]

	visit-var: func [v [variable!] ctx [ssa-ctx!] return: [instr!] /local val? [logic!]][
		val?: RST_VAR_VAL?(v)
		gen-var-read v/decl val? ctx
	]

	visit-get-ptr: func [g [get-ptr!] ctx [ssa-ctx!] return: [instr!]
		/local
			e		[rst-expr!]
			op		[instr-op!]
	][
		e: g/expr
		either NODE_TYPE(e) = RST_PATH [
			gen-path-read as path! e ctx F_GET_PTR
		][
			op: make-op OP_GET_PTR 0 null g/type
			op/target: as int-ptr! e
			add-op op null ctx
		]
	]

	visit-fn-call: func [fc [fn-call!] ctx [ssa-ctx!] return: [instr!]
		/local
			ft		[fn-type!]
			fn		[fn!]
			arg		[rst-expr!]
			op		[instr-op!]
			arr		[ptr-array!]
			op2		[instr-op!]
			int		[red-integer!]
			p pp	[ptr-ptr!]
			np n	[integer!]
			sz		[integer!]
			val		[instr!]
			fval	[instr!]
			extra	[integer!]
			ivar	[instr-var!]
			var		[var-decl!]
			cast	[integer!]
			ret-ty	[rst-type!]
	][
		fn: fc/fn
		ft: as fn-type! fn/type
		ret-ty: ft/ret-type
		np: ft/n-params
		op: make-op OP_CALL_FUNC np ft/param-types ret-ty
		op/target: as int-ptr! fn
		extra: either NODE_TYPE(fn) = RST_FUNC [0][
			fval: as instr! fn/accept as int-ptr! fn builder as int-ptr! ctx
			assert fval <> null
			1
		]

		either np < 0 [		;-- variadic/typed function
			arg: fc/args
			n: arg/header	;-- number of args
			if n > 0 [
				pp: as ptr-ptr! malloc n * size? int-ptr!
				p: pp
				arg: arg/next
				if all [STRUCT_VALUE?(ret-ty) 8 < type-size? ret-ty yes][arg: arg/next]
				while [arg <> null][
					p/value: as int-ptr! arg/type
					p: p + 1
					arg: arg/next
				]
				if np = -1 [	;-- variadic func
					op/n-params: n
					op/param-types: pp
				]
			]
		][
			n: np
		]

		val: null
		if all [STRUCT_VALUE?(ret-ty) 8 < type-size? ret-ty yes][
			n: n + 1
			if NODE_FLAGS(fc) and RST_ST_ARG = 0 [	;-- need to allocate struct on stack
				var: ctx/st-var
				either null? var [
					var: parser/make-var-decl fc/token null
					ADD_NODE_FLAGS(var RST_VAR_LOCAL)
					var/type: ret-ty
					ctx/st-var: var
					type-checker/make-local-var var ret-ty
				][
					sz: type-size? ret-ty yes 
					if sz > type-size? var/type yes [
						var/type: ret-ty
						ivar: as instr-var! var/ssa/instr
						ivar/type: ret-ty
					]
				]
				op2: make-op OP_GET_PTR 0 null var/type
				op2/target: as int-ptr! var
				val: add-op op2 null ctx
			]
		]
		arr: ptr-array/make n + extra
		p: ARRAY_DATA(arr)
		if val <> null [
			p/value: as int-ptr! val
			p: p + 1
		]

		if fc/args <> null [
			arg: fc/args/next
			while [arg <> null][
				val: as instr! arg/accept as int-ptr! arg builder as int-ptr! ctx
				if arg/cast-type <> null [
					cast: type-system/cast arg/type arg/cast-type val
					val: do-cast cast val arg/type arg/cast-type ctx
				]
				p/value: as int-ptr! val
				p: p + 1
				arg: arg/next
			]
		]
		if np = -2 [	;-- typed func
			p: ft/param-types + 1	;-- typed-value!
			op2: make-op OP_TYPED_VALUE n pp as rst-type! p/value
			add-op op2 arr ctx

			int: xmalloc(red-integer!)
			int/header: TYPE_INTEGER
			int/value: n
			arr: ptr-array/make 2 + extra
			p: ARRAY_DATA(arr)
			p/value: as int-ptr! const-int int ctx/graph
			p: p + 1
			p/value: as int-ptr! op2
			p: p + 1
		]
		if extra = 1 [p/value: as int-ptr! fval]
		add-op op arr ctx
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

		t-val: gen-stmts e/t-branch t-ctx
		f-val: either e/f-branch <> null [gen-stmts e/f-branch f-ctx][null]

		t-closed?: t-ctx/closed?	;-- save it as merge-ctx will close the block
		f-closed?: f-ctx/closed?

		init-merge :merge
		merge-ctx :merge :t-ctx
		merge-ctx :merge :f-ctx
		set-ssa-ctx :merge ctx

		case [
			not t-closed? [
				either f-closed? [t-val][
					either any [t-val = f-val null? f-val][t-val][
						either e/type <> type-system/void-type [
							INIT_ARRAY_2(arr2 t-val f-val)
							make-phi e/type merge/block as ptr-array! :arr2
						][nop ctx/graph]
					]
				]
			]
			all [not f-closed? f-val <> null][f-val]
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
		init-merge :m-start					;-- merge point at the start of the loop
		start-loop w/loop-idx :m-start ctx

		init-ssa-ctx :loop-ctx ctx 0 m-start/block
		loop-ctx/cur-vals: ptr-array/copy m-start/cur-vals

		cond: gen-stmts w/cond loop-ctx
		if loop-ctx/closed? [return null]	;-- return or exit in condition block

		init-merge :m-end					;-- merge point at the end of the loop
		loop-ctx/loop-start: :m-start
		loop-ctx/loop-end: :m-end

		split-ssa-ctx :loop-ctx :body-ctx
		add-if cond body-ctx/block m-end/block :loop-ctx
		merge-incoming :m-end :loop-ctx		;-- merge loop-ctx into m-end

		gen-stmts w/body :body-ctx
		merge-ctx :m-start :body-ctx		;-- merge body-ctx into m-start

		set-ssa-ctx :m-end ctx
		null
	]

	visit-until: func [w [while!] ctx [ssa-ctx!] return: [instr!]
		/local
			cond	[instr!]
			f-ctx	[ssa-ctx! value]
			m-start	[ssa-merge! value]
			m-end	[ssa-merge! value]
			body-ctx [ssa-ctx! value]
	][
		init-merge :m-start					;-- merge point at the start of the loop
		init-merge :m-end					;-- merge point at the end of the loop
		start-loop w/loop-idx :m-start ctx

		init-ssa-ctx :body-ctx ctx 0 m-start/block
		body-ctx/cur-vals: ptr-array/copy m-start/cur-vals
		body-ctx/loop-start: :m-start
		body-ctx/loop-end: :m-end

		cond: gen-stmts w/body :body-ctx
		unless body-ctx/closed? [
			split-ssa-ctx :body-ctx :f-ctx
			add-if cond m-end/block f-ctx/block :body-ctx
			merge-incoming :m-end :body-ctx
			merge-ctx :m-start :f-ctx
		]
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
		/local val [instr!] e [rst-expr!] type [rst-type!]
	][
		e: r/expr
		either e <> null [
			type: e/type
			if STRUCT_VALUE?(type) [ADD_NODE_FLAGS(e RST_VAR_VAL)]
			val: gen-expr e ctx
			ADD_INS_FLAGS(val F_ASSIGN?)
		][
			type: type-system/void-type
			val: null
		]
		add-return val type ctx
		null
	]

	visit-path: func [p [path!] ctx [ssa-ctx!] return: [instr!] /local flag [integer!]][
		flag: either RST_VAR_PTR?(p) [F_GET_PTR][0]
		gen-path-read p ctx flag
	]

	visit-any-all: func [e [any-all!] ctx [ssa-ctx!] return: [instr!]
		/local
			c		[rst-expr!]
			any?	[logic!]
			l-val	[instr!]
			m		[ssa-merge! value]
			f-ctx	[ssa-ctx!]
			t-ctx	[ssa-ctx!]
			old-ctx [ssa-ctx!]
			n		[integer!]
			arr		[ptr-array!]
			p		[ptr-ptr!]
	][
		old-ctx: ctx
		c: e/conds
		n: 0
		while [c <> null][
			n: n + 1
			c: c/next
		]
		arr: ptr-array/make n
		p: ARRAY_DATA(arr)
		f-ctx: as ssa-ctx! system/stack/allocate (size? ssa-ctx!) * n / 2 + 1
		t-ctx: f-ctx + n

		any?: NODE_TYPE(e) = RST_ANY
		init-merge :m
		c: e/conds
		while [c <> null][
			l-val: gen-expr c ctx
			p/value: as int-ptr! l-val
			p: p + 1
			c: c/next
			if null? c [
				merge-ctx :m ctx 
				break
			]

			;TBD fold if l-val is a const
			;if INSTR_CONST?(l-val) [return fold-left any? to logic!]

			split-ssa-ctx ctx f-ctx
			split-ssa-ctx ctx t-ctx
			either any? [
				add-if l-val t-ctx/block f-ctx/block ctx
			][
				add-if l-val f-ctx/block t-ctx/block ctx
			]
			merge-ctx :m t-ctx

			ctx: f-ctx
			f-ctx: f-ctx + 1
			t-ctx: t-ctx + 1
		]
		set-ssa-ctx :m old-ctx
		as instr! make-phi type-system/logic-type m/block arr
	]

	visit-comment: func [r [rst-stmt!] ctx [ssa-ctx!] return: [instr!]][
		null
	]

	visit-switch: func [s [switch!] ctx [ssa-ctx!] return: [instr!]
		/local
			key		[instr!]
			cond	[instr!]
			const	[instr-const!]
			op		[instr-op!]
			val		[instr!]
			ty		[rst-type!]
			c		[switch-case!]
			e		[rst-expr!]
			t-ctx	[ssa-ctx! value]
			f-ctx	[ssa-ctx! value]
			cur		[ssa-ctx!]
			end		[ssa-merge! value]
			args	[array-2! value]
			ret-val [ptr-array!]
			p		[ptr-ptr!]
			n		[integer!]
	][
		key: gen-expr s/expr ctx
		ty: s/expr/type
		if ctx/closed? [return null]	;@@ s/expr closed current block?

		init-merge :end
		cur: ctx
		c: s/cases
		n: 0
		while [c <> null][
			n: n + 1
			c: c/next
		]
		if s/defcase <> null [n: n + 1]
		ret-val: ptr-array/make n
		p: ARRAY_DATA(ret-val)

		c: s/cases
		while [c <> null][				;-- generate if cascade
			e: c/expr
			split-ssa-ctx ctx :t-ctx
			while [e <> null][
				split-ssa-ctx cur :f-ctx

				const: const-val e/type e/token ctx/graph
				INIT_ARRAY_2(args key const)
				op: typed-equal ty
				cond: add-op op as ptr-array! :args cur
				add-if cond t-ctx/block f-ctx/block cur

				cur/block: f-ctx/block
				cur/parent: f-ctx/parent
				cur/closed?: no
				e: e/next
			]
			p/value: as int-ptr! gen-stmts c/body :t-ctx
			p: p + 1
			merge-ctx :end :t-ctx
			c: c/next
		]

		if s/defcase <> null [
			c: s/defcase
			p/value: as int-ptr! gen-stmts c/body cur
			merge-ctx :end cur
		]
		val: either s/type = type-system/void-type [null][
			make-phi s/type end/block ret-val
		]
		set-ssa-ctx :end ctx
		val
	]

	visit-case: func [c [case!] ctx [ssa-ctx!] return: [instr!]][
		visit-if c/cases ctx
	]

	visit-not: func [e [unary!] ctx [ssa-ctx!] return: [instr!]
		/local val [instr!] op [instr-op!] arr [ptr-ptr!] args [array-value!]
	][
		arr: as ptr-ptr! malloc size? int-ptr!
		arr/value: as int-ptr! e/type
		op: make-op OP_BOOL_NOT 1 arr e/type
		val: gen-expr e/expr ctx
		INIT_ARRAY_VALUE(args val)
		add-op op as ptr-array! :args ctx
	]

	visit-size?: func [u [sizeof!] ctx [ssa-ctx!] return: [instr!]
		/local int [red-integer!] t [rst-type!] arr [array-type!]
	][
		t: u/etype
		int: as red-integer! u/token
		int/header: TYPE_INTEGER
		int/value: type-size? t yes
		as instr! const-int int ctx/graph
	]

	do-cast: func [
		cast [integer!] val [instr!] ft [rst-type!] tt [rst-type!] ctx [ssa-ctx!]
		return: [instr!]
		/local op [instr-op!] ptypes [ptr-ptr!] args [array-value!] code [integer!]
			fn [fn-type!] arr [array-2! value] rhs [instr!]
	][
		code: switch cast [
			conv_cast_if [OP_INT_TO_F]		;-- int to float
			conv_cast_fi [OP_FLT_TO_I]		;-- float to int
			conv_cast_ii conv_promote_ii [OP_INT_CAST]
			conv_promote_ff [OP_FLOAT_PROMOTE]
			conv_cast_ff [OP_FLOAT_CAST]
			conv_view_bits [OP_BITS_VIEW]
			default [0]
		]
		either code > 0 [
			ptypes: as ptr-ptr! malloc 1 * size? int-ptr!
			ptypes/value: as int-ptr! ft
			INIT_ARRAY_VALUE(args val)
			op: make-op code 1 ptypes tt
			add-op op as ptr-array! :args ctx 
		][
			either cast = conv_cast_logic [
				op: either INT_TYPE?(ft) [
					rhs: as instr! const-int-zero ctx/graph
					fn: op-cache/get-int-op RST_OP_NE ft
					make-op OP_INT_NE 2 fn/param-types fn/ret-type
				][
					rhs: as instr! const-null ctx/graph
					fn: op-cache/get-ptr-op RST_OP_NE as ptr-type! ft
					make-op OP_PTR_NE 2 fn/param-types fn/ret-type
				]
				INIT_ARRAY_2(arr val rhs)
				add-op op as ptr-array! :arr ctx
			][val]
		]
	]

	visit-cast: func [c [cast!] ctx [ssa-ctx!] return: [instr!]
		/local
			val [instr!]
	][
		val: gen-expr c/expr ctx
		do-cast c/cast val c/expr/type c/type ctx
	]

	visit-declare: func [d [declare!] ctx [ssa-ctx!] return: [instr!]
		/local op [instr-op!]
	][
		record-global as var-decl! d
		op: make-op OP_GET_GLOBAL 0 null d/type
		op/target: as int-ptr! d
		add-op op null ctx
	]

	visit-throw: func [t [unary!] ctx [ssa-ctx!] return: [instr!]
		/local op [instr-op!] e [int-literal!] p [ssa-ctx!]
	][
		e: as int-literal! t/expr
		op: make-op OP_THROW 0 null type-system/void-type
		op/target: as int-ptr! e/value
		add-op op null ctx
		p: ctx
		while [p <> null][
			if p/catch-end <> null [
				merge-ctx p/catch-end ctx
				return null
			]
			p: p/parent
		]
		null
	]

	visit-catch: func [c [catch!] ctx [ssa-ctx!] return: [instr!]
		/local
			op		[instr-op!]
			c-ctx	[ssa-ctx! value]
			c-end	[ssa-merge! value]
			arr		[int-ptr!]
			p		[int-ptr!]
			int		[red-integer!]
	][
		init-ssa-ctx :c-ctx ctx 0 ctx/block
		init-merge :c-end		;-- merge point at the end of the catch
		c-ctx/catch-end: :c-end

		arr: as int-ptr! malloc 4 * size? integer!
		p: arr + 1
		int: as red-integer! c/filter
		p/value: int/value
		
		op: make-op OP_CATCH_BEG 0 null type-system/void-type
		op/target: arr
		add-op op null ctx

		gen-stmts c/body c-ctx

		either c-end/n-preds > 0 [
			ctx/closed?: no
			ctx/block: c-end/block
			ctx/cur-vals: c-end/cur-vals
		][
			ctx/block: c-ctx/block
		]

		op: make-op OP_CATCH_END 0 null type-system/void-type
		op/target: arr
		add-op op null ctx
		null
	]

	visit-native-call: func [nc [native-call!] ctx [ssa-ctx!] return: [instr!]
		/local
			fn	[native!]
			np	[integer!]
			op	[instr-op!]
			arr [ptr-array!]
			p	[ptr-ptr!]
			arg [rst-expr!]
			id	[integer!]
			w	[red-word!]
			int [red-integer!]
	][
		fn: nc/native
		id: fn/id
		np: fn/n-params
		op: make-op OP_CALL_NATIVE np fn/param-types fn/ret-type
		op/target: as int-ptr! fn

		arr: ptr-array/make np
		p: ARRAY_DATA(arr)
		if any [id = N_GET_CPU_REG id = N_SET_CPU_REG][
			w: as red-word! nc/token
			id: symbol/resolve w/symbol
			int: as red-integer! nc/token
			int/header: TYPE_INTEGER
			int/value: id
			p/value: as int-ptr! const-int int ctx/graph
			p: p + 1
		]
		if nc/args <> null [
			arg: nc/args/next
			while [arg <> null][
				p/value: arg/accept as int-ptr! arg builder as int-ptr! ctx
				p: p + 1
				arg: arg/next
			]
		]
		add-op op arr ctx
	]

	visit-assert: func [r [case!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-sys-alias: func [e [sys-alias!] ctx [ssa-ctx!] return: [instr!]
		/local int [red-integer!]
	][
		int: as red-integer! e/token
		int/header: TYPE_INTEGER
		int/value: type-id? e/alias-type
		as instr! const-val e/type as cell! int ctx/graph
	]

	visit-context: func [c [context!] ctx [ssa-ctx!] return: [instr!]
		/local stmt [rst-stmt!]
	][
		stmt: c/stmts
		while [
			stmt: stmt/next
			stmt <> null
		][
			;rst-printer/print-stmt stmt
			stmt/accept as int-ptr! stmt builder as int-ptr! ctx
		]
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
		idx		[integer!]
		return: [instr-param!]
		/local
			p	[instr-param!]
	][
		p: as instr-param! malloc size? instr-param!
		p/header: INS_PARAM or (F_NOT_VOID << 8)
		p/index: idx
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
			ret-ty	[rst-type!]
			ret-st? [logic!]
			pm		[instr-param!]
			n i		[integer!]
	][
		ir: as ir-fn! malloc size? ir-fn!
		ir/fn: fn
		ir/start-bb: make-bb
		ir/const-idx: N_COMMON_CONST
		ctx/graph: ir
		ctx/block: ir/start-bb
		either fn <> null [
			ft: as fn-type! fn/type
			ret-ty: ft/ret-type
			n: ft/n-params
			if n < 0 [n: 2]		;-- variadic/typed func
			ret-st?: all [STRUCT_VALUE?(ret-ty) 8 < type-size? ret-ty yes]
			if ret-st? [n: n + 1]
			parr: ptr-array/make n
			if n > 0 [
				p: ARRAY_DATA(parr)
				i: 0
				if ret-st? [
					pm: as instr-param! malloc size? instr-param!
					pm/header: INS_PARAM or (F_NOT_VOID << 8)
					pm/index: 0
					pm/type: ret-ty
					p/value: as int-ptr! pm 
					p: p + 1
					i: 1
				]
				pp: ARRAY_DATA(ctx/ssa-vars)
				param: ft/params
				while [param <> null][
					ins: as instr! make-param param i
					p/value: as int-ptr! ins
					ssa: param/ssa
					if ssa/index > -1 [
						pv: pp + ssa/index
						pv/value: as int-ptr! param
						set-cur-val ssa param/type ins ctx
					]
					p: p + 1
					i: i + 1
					param: param/next
				]
			]
			ir/params: parr
			ir/param-types: ft/param-types
			ir/ret-type: ret-ty
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
			if all [var <> null written-in-loop? var/ssa loop-idx][
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
		init-ssa-ctx ctx p-ctx 0 make-bb
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
			new?	[logic!]
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
			new?: yes
			if all [v <> null INSTR_PHI?(v)][
				phi: as instr-phi! v
				if phi/block = m/block [
					e: make-df-edge v pred-v
					phi/inputs: ptr-array/append phi/inputs as byte-ptr! e
					new?: no
				]
			]
			;-- add a new phi
			if all [v <> pred-v new?][
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
				assert var <> null
				mp/value: as int-ptr! make-phi var/type m/block inputs
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
		while [all [stmt <> null not ctx/closed?]][
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
		either ctx/closed? [as instr! nop ctx/graph][
			i: as instr! e/accept as int-ptr! e builder as int-ptr! ctx
			i
		]
	]

	get-cur-val: func [
		var			[ssa-var!]
		cur-vals	[ptr-array!]
		return:		[instr!]
		/local
			p		[ptr-ptr!]
			ins		[instr!]
			decl	[var-decl!]
	][
		ins: either var/index >= 0 [
			p: ARRAY_DATA(cur-vals) + var/index
			as instr! p/value
		][
			var/instr
		]
		if null? ins [
			decl: var/decl
			cur-blk: decl/blkref
			throw-error [decl/token "local variable used before being initialized!"]
		]
		ins
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
					ctx/cur-vals: ptr-array/copy ctx/cur-vals	;-- copy-on-write
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

	typed-equal: func [
		t		[rst-type!]
		return: [instr-op!]
		/local
			code [integer!]
			arr	[ptr-ptr!]
			op	[instr-op!]
	][
		code: switch TYPE_KIND(t) [
			RST_TYPE_INT	[OP_INT_EQ]
			RST_TYPE_FLOAT	[OP_FLT_EQ]
			RST_TYPE_PTR	[OP_PTR_EQ]
			default [OP_INT_EQ]
		]
		arr: as ptr-ptr! malloc 2 * size? int-ptr!
		op: make-op code 2 arr type-system/logic-type
		arr/value: as int-ptr! t
		arr: arr + 1
		arr/value: as int-ptr! t
		op
	]

	const-default-value: func [
		type	[rst-type!]
		fn		[ir-fn!]
		return: [instr-const!]
	][
		switch TYPE_KIND(type) [
			RST_TYPE_LOGIC [const-false fn]
			RST_TYPE_INT [const-int-zero fn]
			RST_TYPE_NULL [const-null fn]
			default [nop fn]
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

	const-float32: func [
		val		[red-float32!]
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-const type-system/float32-type as cell! val fn
	]

	nop: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 0 type-system/void-type common-literals/void-cell fn
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

	const-null: func [
		fn		[ir-fn!]
		return: [instr-const!]
	][
		get-cached-const 9 type-system/null-type null fn
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
			i	[red-integer!]
	][
		either null? val [const-default-value type fn][
			switch TYPE_KIND(type) [
				RST_TYPE_LOGIC [
					b: as red-logic! val
					either b/value [const-true fn][const-false fn]
				]
				RST_TYPE_INT [
					i: as red-integer! val
					either INT_WIDTH(type) <= 32 [
						const-int as red-integer! val fn
					][
						const-int64 as red-integer! val fn
					]
				]
				RST_TYPE_FLOAT [
					either FLOAT_64?(type) [
						const-float as red-float! val fn
					][
						const-float32 as red-float32! val fn
					]
				]
				RST_TYPE_NULL [const-null fn]
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
			if idx = vals/length [
				map: token-map/make 50
				fn/const-map: map
			]
		]
		either idx < N_CACHED_CONST [
			p: ARRAY_DATA(vals) + idx
			p/value: as int-ptr! c
		][
			token-map/put map c/value as int-ptr! c
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

	copy-op: func [
		i		[instr-op!]
		return: [instr-op!]
		/local
			op	[instr-op!]
	][
		op: xmalloc(instr-op!)
		op/header: i/header
		op/n-params: i/n-params
		op/param-types: i/param-types
		op/ret-type: i/ret-type
		op/target: i/target
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
		as instr! const-default-value type ctx/graph
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
		type	[rst-type!]
		ctx		[ssa-ctx!]
		/local
			arr [array-value!]
			r	[instr-return!]
			f	[integer!]
			op	[instr-op!]
			p	[ptr-ptr!]
			obj [instr!]
			args [array-2! value]
	][
		if ctx/closed? [exit]

		either val <> null [
			INIT_ARRAY_VALUE(arr val)
		][
			arr/length: 0		;-- emtpy array
		]
		r: as instr-return! malloc size? instr-return!
		f: either all [STRUCT_VALUE?(type) 8 < type-size? type yes][
			op: make-op OP_SET_FIELD 2 null type
			obj: as instr! ptr-array/pick ctx/graph/params 0
			INIT_ARRAY_2(args obj val)
			op/target: null
			add-op op as ptr-array! :args ctx
			arr/length: 0
			F_RET_STRUCT or F_INS_END
		][F_INS_END]

		ctx/closed?: yes		
		r/header: f << 8 or INS_RETURN
		r/type: type
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
			m m1	[member!]
			obj		[instr!]
	][
		var: p/receiver
		obj: gen-var-read var no ctx

		type: var/type
		m: p/subs
		until [
			m1: m
			while [all [m <> null STRUCT_VALUE?(m/type)]][
				m: m/next
			]
			either any [null? m null? m/next][
				path-member-write val obj type m1 ctx
				break
			][
				obj: path-member-read obj type m1 ctx
				type: m/type
			]
			m: m/next
			null? m
		]
		val
	]

	path-member-write: func [
		val		[instr!]
		obj		[instr!]
		type	[rst-type!]
		m		[member!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			op		[instr-op!]
			pp		[ptr-ptr!]
			ptypes	[ptr-ptr!]
			args	[array-3! value]
			idx		[instr!]
			int		[red-integer!]
			arr		[array-type!]
	][
		ptypes: as ptr-ptr! malloc 2 * size? int-ptr!
		ptypes/value: as int-ptr! type
		pp: ptypes + 1
		pp/value: as int-ptr! m/type
		switch TYPE_KIND(type) [
			RST_TYPE_STRUCT [
				op: make-op OP_SET_FIELD 2 ptypes type-system/void-type
				INIT_ARRAY_2(args obj val)
			]
			RST_TYPE_PTR RST_TYPE_ARRAY [
				op: make-op OP_SET_FIELD 3 ptypes type-system/void-type
				idx: either m/expr <> null [gen-expr m/expr ctx][
					arr: as array-type! type
					int: as red-integer! m/token
					int/header: TYPE_INTEGER
					int/value: m/index * type-size? arr/type yes
					as instr! const-int int ctx/graph
				]
				INIT_ARRAY_3(args obj idx val)
			]
			default [
				dprint ["path-member-read error: " type]
				halt
			]
		]
		op/target: as int-ptr! m
		add-op op as ptr-array! :args ctx
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
			arr		[array-type!]
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
				op: make-op OP_GET_FIELD 2 ptypes m/type
				op/target: as int-ptr! m

				idx: either m/expr <> null [gen-expr m/expr ctx][
					arr: as array-type! type
					int: as red-integer! m/token
					int/header: TYPE_INTEGER
					int/value: m/index * type-size? arr/type yes
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
		p			[path!]
		ctx			[ssa-ctx!]
		flags		[integer!]
		return: 	[instr!]
		/local
			var		[var-decl!]
			type	[rst-type!]
			m		[member!]
			obj		[instr!]
	][
		var: p/receiver
		obj: gen-var-read var no ctx

		m: p/subs
		type: var/type
		until [
			obj: path-member-read obj type m ctx
			until [
				type: m/type
				m: m/next
				any [null? m NOT_STRUCT_VALUE?(type)]
			]
			null? m
		]
		ADD_INS_FLAGS(obj flags)
		obj
	]

	gen-var-read: func [
		decl	[var-decl!]
		val?	[logic!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			op	[instr-op!]
			t	[rst-type!]
			ins [instr!]
			args [array-value!]
	][
		t: decl/type
		ins: either LOCAL_VAR?(decl) [
			either all [STRUCT_VALUE?(t) NOT_PARAM_VAR?(decl)][
				op: make-op OP_GET_PTR 0 null t
				op/target: as int-ptr! decl
				add-op op null ctx
			][
				get-cur-val decl/ssa ctx/cur-vals
			]
		][
			record-global decl
			op: make-op OP_GET_GLOBAL 0 null t
			op/target: as int-ptr! decl
			add-op op null ctx
		]
		if val? [
			if t/header and FLAG_ST_VALUE = 0 [
				t: as rst-type! copy-struct-type as struct-type! t
				SET_STRUCT_VALUE(t)
			]
			op: make-op OP_GET_FIELD 0 null t
			op/target: as int-ptr! decl
			INIT_ARRAY_VALUE(args ins)
			ins: add-op op as ptr-array! :args ctx
		]
		ins
	]

	gen-var-write: func [
		var		[var-decl!]
		val		[instr!]
		vtype	[rst-type!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			op	[instr-op!]
			arr [ptr-ptr!]
			ins [instr!]
			args [array-2! value]
	][
		ins: null
		either LOCAL_VAR?(var) [
			either STRUCT_VALUE?(vtype) [
				ins: either NOT_PARAM_VAR?(var) [
					op: make-op OP_GET_PTR 0 null vtype
					op/target: as int-ptr! var
					add-op op null ctx
				][
					var/ssa/instr
				]
			][
				set-cur-val var/ssa var/type val ctx
			]
		][
			record-global var
			either NOT_STRUCT_VALUE?(vtype) [
				arr: as ptr-ptr! malloc size? int-ptr!
				arr/value: as int-ptr! var/type
				op: make-op OP_SET_GLOBAL 1 arr type-system/void-type
				op/target: as int-ptr! var
				INIT_ARRAY_VALUE(args val)
				add-op op as ptr-array! :args ctx
			][
				op: make-op OP_GET_GLOBAL 0 null var/type
				op/target: as int-ptr! var
				ins: add-op op null ctx
			]
		]
		if ins <> null [
			op: make-op OP_SET_FIELD 2 null vtype
			INIT_ARRAY_2(args ins val)
			op/target: null
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

		if ctx/dyn-alloc? [ADD_NODE_FLAGS(fn RST_DYN_ALLOC)]
		init-ssa-ctx :ssa-ctx null ctx/n-ssa-vars null
		graph: make-ir-fn fn :ssa-ctx
		graph/n-typed: ctx/n-typed

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
			if ctx/loop-counter <> null [gen-var ctx/loop-counter :ssa-ctx]
		]

		stmt: ctx/stmts
		while [
			stmt: stmt/next
			all [stmt <> null not ssa-ctx/closed?]
		][
			;rst-printer/print-stmt stmt
			stmt/accept as int-ptr! stmt builder as int-ptr! :ssa-ctx
		]

		fn/body: null
		graph
	]
]