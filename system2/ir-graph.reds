Red/System [
	File: 	 %ir-graph.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum instr-kind! [
	INS_MAKE_PARAM
	INS_MAKE_VAR
	INS_MAKE_PHI
	INS_UPDATE_VAR
	INS_CALL
	INS_END
]

;; /header, instr-kind: 0 - 7 bits, flags: 8 - 31 bits
#define IR_NODE_FIELDS(type) [
	header	[integer!]
	uid		[integer!]
	next	[type]
	prev	[type]
]

#define IR_INSTR_FIELDS [
	inputs	[vector!]
	uses	[df-edge!]
]

#define INSTR_END?(i) (i/header and FFh = INS_END)

;; a control flow edge
cf-edge!: alias struct! [
	src		[instr-end!]
	dst		[basic-block!]
	dst-idx [integer!]
]

;; a data flow edge
df-edge!: alias struct! [
	src		[instr!]
	dst		[instr!]
	next	[df-edge!]
	prev	[df-edge!]
]

instr!: alias struct! [
	IR_NODE_FIELDS(instr!)
]

;-- end instruction of a basic block
instr-end!: alias struct! [
	IR_NODE_FIELDS(instr!)
	succs	[cf-edge!]
]

;-- instruction to create a function parameter
instr-param!: alias struct! [
	IR_NODE_FIELDS(instr!)
	type	[rst-type!]
]

;-- instruction to create a variable
instr-var!: alias struct! [
	IR_NODE_FIELDS(instr!)
	type	[rst-type!]
]

instr-update-var!: alias struct! [
	IR_NODE_FIELDS(instr!)
]

instr-phi!: alias struct! [
	type	[rst-type!]
	block	[basic-block!]
]

instr-call!: alias struct! [
	IR_NODE_FIELDS(instr-call!)
	op		[integer!]
]

basic-block!: alias struct! [
	;-- /next: point to the head instr
	;-- /prev: point to the last instr
	IR_NODE_FIELDS(instr!)
	preds	[cf-edge!]
]

ir-fn!: alias struct! [
	params		[instr-param!]
	ret-type	[rst-type!]
	start-bb	[basic-block!]
]

ssa-merge!: alias struct! [
	block		[basic-block!]
	cur-defs	[ptr-array!]
	pred-vals	[vector!]
]

ssa-ctx!: alias struct! [
	parent		[ssa-ctx!]
	graph		[ir-fn!]
	cur-bb		[basic-block!]
	cur-defs	[ptr-array!]
	ssa-vars	[ptr-array!]
	loop-start	[ssa-merge!]
	loop-end	[ssa-merge!]
	close-blk?	[logic!]			;-- true: close current block
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

instr-insert: func [		;-- insert instr! y before x
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

instr-remove: func [		;-- remove instr! x
	x		[instr!]
][
	if x/prev <> null [x/prev/next: x/next]
	if x/next <> null [x/next/prev: x/prev]
	x/prev: null
	x/next: null	
]

block-append: func [		;-- append instr to the end of a block
	bb		[basic-block!]
	ins		[instr!]
	/local
		p	[instr!]
][
	p: bb/prev
	unless INSTR_END?(p) [p: as instr! bb]
	
	instr-insert p ins
]

block-insert: func [		;-- insert instr to the start of a block
	bb		[basic-block!]
	ins		[instr!]
][
	instr-insert bb/next ins
]

;-- a graph of IR nodes in SSA form
ir-graph: context [

	builder: declare visitor!

	visit-assign: func [
		a [assignment!] ctx [ssa-ctx!] return: [instr!]
	][
		null
	]

	visit-literal: func [e [literal!] ctx [ssa-ctx!] return: [instr!]][
		null
	]

	visit-var: func [v [variable!] ctx [ssa-ctx!] return: [instr!]][
		null
	]

	visit-fn-call: func [fc [fn-call!] ctx [ssa-ctx!] return: [instr!]
		/local
			ft	 	[fn-type!]
			arg		[rst-expr!]
			pt		[ptr-ptr!]
	][
		null
	]

	visit-bin-op: func [bin [bin-op!] ctx [ssa-ctx!] return: [instr!]
		/local
			op	[fn-type!]
			ltype rtype [instr!]
	][
		null
	]

	builder/visit-assign:	as visit-fn! :visit-assign
	builder/visit-literal:	as visit-fn! :visit-literal
	builder/visit-bin-op:	as visit-fn! :visit-bin-op
	builder/visit-var:		as visit-fn! :visit-var
	builder/visit-fn-call:	as visit-fn! :visit-fn-call

	make-bb: func [		;-- create basic-block!
		return: [basic-block!]
		/local
			bb [basic-block!]
	][
		bb: as basic-block! malloc size? basic-block!
		bb/next: as instr! bb
		bb/prev: as instr! bb
		bb
	]

	make-ir-fn: func [
		fn			[fn!]
		return:		[ir-fn!]
		/local
			ir		[ir-fn!]
			ft		[fn-type!]
	][
		ir: as ir-fn! malloc size? ir-fn!
		ir/start-bb: make-bb
		either fn <> null [
			ft: as fn-type! fn/type
			ir/ret-type: ft/Ret-type
			fn/ir: ir
		][
			ir/ret-type: type-system/void-type
		]
		ir
	]

	make-ssa-ctx: func [
		parent	[ssa-ctx!]
		n-vars	[integer!]
		cur-blk [basic-block!]
		return: [ssa-ctx!]
		/local
			ctx [ssa-ctx!]
	][
		ctx: as ssa-ctx! malloc size? ssa-ctx!
		ctx/parent: parent
		ctx/cur-bb: cur-blk
		if n-vars > 0 [
			ctx/cur-defs: make-ptr-array n-vars
			ctx/ssa-vars: either parent <> null [
				parent/ssa-vars
			][
				make-ptr-array n-vars
			]
		]
		ctx
	]

	do-cast: func [
		from	[rst-type!]
		to-type	[rst-type!]
		value	[instr!]
		return: [instr!]
	][
		value
	]

	gen-expr: func [
		e		[rst-expr!]
		ctx		[ssa-ctx!]
		/local
			i	[instr!]
			cast [rst-type!]
			
	][
		unless ctx/close-blk? [
			i: as instr! e/accept as int-ptr! e builder as int-ptr! ctx
			if e/cast-type <> null [
				do-cast e/cast-type e/type i
			]
		]
	]
	
	generate: func [
		fn		[fn!]
		ctx		[context!]
		return: [ir-fn!]
		/local
			ssa-ctx [ssa-ctx!]
			graph	[ir-fn!]
			stmt	[rst-stmt!]
			n		[integer!]
			kv		[int-ptr!]
			var		[var-decl!]
			decls	[int-ptr!]
			ssa-var	[ptr-ptr!]
			p		[ptr-ptr!]
	][
		graph: make-ir-fn fn
		ssa-ctx: make-ssa-ctx null ctx/n-ssa-vars graph/start-bb

		if ctx/n-ssa-vars > 0 [
			ssa-var: ARRAY_DATA(ssa-ctx/ssa-vars)
			decls: ctx/decls
			n: hashmap/size? decls
			kv: null
			loop n [
				kv: hashmap/next decls kv
				var: as var-decl! kv/2
				if all [
					NODE_TYPE(var) = RST_VAR_DECL
					var/ssa <> null
				][
					p: ssa-var + var/ssa/index
					p/value: as int-ptr! var
				]
			]
		]

		stmt: ctx/stmts
		while [
			stmt: stmt/next
			stmt <> null
		][
			stmt/accept as int-ptr! stmt builder as int-ptr! ssa-ctx
		]

		graph
	]
]