Red/System [
	File: 	 %ir-graph.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum instr-kind! [
	INS_NEW_PARAM
	INS_NEW_VAR
	INS_NEW_PHI
	INS_UPDATE_VAR
	INS_CONST
	INS_CALL
	INS_GOTO
	INS_RETURN
	INS_THROW
	INS_END
]

#enum instr-flag! [
	INS_PURE:		1		;-- no side-effects
	INS_KILLED:		2		;-- instruction is dead
]

;; /header, instr-kind: 0 - 7 bits, flags: 8 - 31 bits
#define IR_NODE_FIELDS(type) [
	header	[integer!]
	uid		[integer!]
	next	[type]
	prev	[type]
]

#define IR_INSTR_FIELDS(type) [
	IR_NODE_FIELDS(type)
	inputs	[ptr-array!]
	uses	[df-edge!]
]

#define INSTR_KIND(i) [i/header and FFh]
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
	IR_INSTR_FIELDS(instr!)
]

;-- end instruction of a basic block
instr-end!: alias struct! [
	IR_NODE_FIELDS(instr!)
	succs	[ptr-array!]
]

;-- same as end
instr-return!: alias struct! [
	IR_NODE_FIELDS(instr!)
	succs	[ptr-array!]	
]

instr-goto!: alias struct! [
	IR_NODE_FIELDS(instr!)
	succs	[ptr-array!]
]

instr-if!: alias struct! [
	IR_NODE_FIELDS(instr!)
	succs	[ptr-array!]
	cond	[instr!]
	t-blk	[basic-block!]
	f-blk	[basic-block!]
]

instr-const!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	type	[rst-type!]
	val		[literal!]
]

;-- instruction to create a function parameter
instr-param!: alias struct! [
	IR_NODE_FIELDS(instr!)
	type	[rst-type!]
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

instr-call!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	op		[op!]
]

basic-block!: alias struct! [
	;-- /next: point to the head instr
	;-- /prev: point to the last instr
	IR_NODE_FIELDS(instr!)
	preds	[ptr-array!]
]

ir-fn!: alias struct! [
	params		[instr-param!]
	ret-type	[rst-type!]
	start-bb	[basic-block!]
]

ssa-merge!: alias struct! [
	block		[basic-block!]
	cur-vals	[ptr-array!]
	pred-vals	[ptr-array!]
]

ssa-ctx!: alias struct! [
	parent		[ssa-ctx!]
	graph		[ir-fn!]
	cur-bb		[basic-block!]
	cur-vals	[ptr-array!]
	ssa-vars	[ptr-array!]
	loop-start	[ssa-merge!]
	loop-end	[ssa-merge!]
	blk-closed?	[logic!]			;-- true: close current block
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
		bb/preds: empty-array
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
		bb		[basic-block!]
		return: [ssa-ctx!]
		/local
			ctx [ssa-ctx!]
	][
		ctx: as ssa-ctx! malloc size? ssa-ctx!
		ctx/parent: parent
		ctx/cur-bb: bb
		if n-vars > 0 [
			ctx/cur-vals: ptr-array/make n-vars
			ctx/ssa-vars: either parent <> null [
				parent/ssa-vars
			][
				ptr-array/make n-vars
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

	has-phi?: func [
		bb		[basic-block!]
	][
		INSTR_KIND(bb/next) = INS_NEW_PHI
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

	make-df-edge: func [
		src		[instr!]
		dest	[instr!]
		/local
			e	[df-edge!]
	][
		e: as df-edge! malloc size? df-edge!
		e/src: src
		e/dst: dest
		if dest <> null [insert-uses e dest]
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

	gen-expr: func [
		e		[rst-expr!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			i	[instr!]
			cast [rst-type!]
			
	][
		unless ctx/blk-closed? [
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
			var/value
		]
	]

	set-cur-val: func [
		var			[ssa-var!]
		val			[instr!]
		ctx			[ssa-ctx!]
		/local
			p		[ptr-ptr!]
	][
		either var/index >= 0 [
			if all [
				ctx/parent <> null
				ctx/parent/cur-vals = ctx/cur-vals
			][
				ctx/cur-vals: ptr-array/copy ctx/parent/cur-vals
			]
			p: ARRAY_DATA(ctx/cur-vals) + var/index
			p/value: as int-ptr! val
		][
			var/value: val
		]
	]

	add-call: func [
		op		[op!]
		args	[ptr-array!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			c	[instr-call!]
	][
		c: as instr-call! malloc size? instr-call!
		c/header: INS_CALL
		c/op: op
		set-inputs as instr! c args
		unless ctx/blk-closed? [block-append-instr ctx/cur-bb as instr! c]
		as instr! c
	]

	add-default-value: func [
		type		[rst-type!]
		ctx			[ssa-ctx!]
		return:		[instr!]
		/local
			ins		[instr!]
			op		[op!]
	][
		op: make-op op_default_value 0 null type
		add-call op null ctx
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
		v/header: INS_NEW_VAR
		v/type: type
		v/index: idx
		set-inputs as instr! v vals
		block-append-instr ctx/cur-bb as instr! v
		as instr! v
	]

	gen-var: func [
		var		[var-decl!]
		ctx		[ssa-ctx!]
		/local
			val [instr!]
			arr [array-value!]
			ssa [ssa-var!]
			idx [integer!]
			p	[ptr-ptr!]
	][
		ssa: var/ssa
		idx: ssa/index
		if idx > 0 [
			p: ARRAY_DATA(ctx/ssa-vars) + idx
			p/value: as int-ptr! var
		]
		unless ctx/blk-closed? [
			val: either var/init <> null [
				gen-expr var/init ctx
			][
				add-default-value var/type ctx
			]
			set-cur-val ssa val ctx
			INIT_ARRAY_VALUE(arr val)
			add-new-var var/type idx as ptr-array! :arr ctx
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
	][
		graph: make-ir-fn fn
		ssa-ctx: make-ssa-ctx null ctx/n-ssa-vars graph/start-bb

		if ctx/n-ssa-vars > 0 [
			decls: ctx/decls
			n: hashmap/size? decls
			kv: null
			loop n [
				kv: hashmap/next decls kv
				var: as var-decl! kv/2
				if NODE_TYPE(var) = RST_VAR_DECL [
					gen-var var ssa-ctx
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