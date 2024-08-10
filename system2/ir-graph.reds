Red/System [
	File: 	 %ir-graph.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum instr-flag! [
	INS_PURE:		1		;-- no side-effects
	INS_KILLED:		2		;-- instruction is dead
]

;; /header, opcode: 0 - 7 bits, flags: 8 - 31 bits
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

#define INSTR_OPCODE(i) [i/header and FFh]
#define INSTR_END?(i) (i/header and FFh = INS_END)
#define INSTR_PHI?(i) (i/header and FFh = INS_PHI)

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
	IR_INSTR_FIELDS(instr!)
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

instr-op!: alias struct! [
	IR_INSTR_FIELDS(instr!)
	n-params	[integer!]
	param-types	[ptr-ptr!]		;-- an array of types
	ret-type	[rst-type!]
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
	n-preds		[integer!]
]

ssa-ctx!: alias struct! [
	parent		[ssa-ctx!]
	graph		[ir-fn!]
	pt			[instr!]
	block		[basic-block!]
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

	visit-if: func [e [if!] ctx [ssa-ctx!] return: [instr!]
		/local
			cond	[instr!]
			t-ctx	[ssa-ctx! value]
			f-ctx	[ssa-ctx! value]
			t-val	[instr!]
			f-val	[instr!]
			merge	[ssa-merge! value]
	][
		cond: as instr! e/cond/accept as int-ptr! e/cond builder as int-ptr! ctx
		
		split-ssa-ctx ctx :t-ctx
		split-ssa-ctx ctx :f-ctx
		add-if cond t-ctx/block f-ctx/block ctx

		t-val: gen-stmts e/t-branch t-ctx
		f-val: either e/f-branch <> null [gen-stmts e/f-branch f-ctx][add-default-value e/type f-ctx]

		init-merge :merge
		merge-ctx :merge :t-ctx 
		
		null
	]

	visit-while: func [w [while!] ctx [ssa-ctx!] return: [instr!]][
		null
	]

	visit-break: func [b [break!] ctx [ssa-ctx!] return: [instr!]][
		null
	]

	visit-continue: func [v [continue!] ctx [ssa-ctx!] return: [instr!]][
		null
	]

	builder/visit-assign:	as visit-fn! :visit-assign
	builder/visit-literal:	as visit-fn! :visit-literal
	builder/visit-bin-op:	as visit-fn! :visit-bin-op
	builder/visit-var:		as visit-fn! :visit-var
	builder/visit-fn-call:	as visit-fn! :visit-fn-call
	builder/visit-if:		as visit-fn! :visit-if
	builder/visit-while:	as visit-fn! :visit-while
	builder/visit-break:	as visit-fn! :visit-break
	builder/visit-continue:	as visit-fn! :visit-continue

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

	make-phi: func [
		type	[rst-type!]
		blk		[basic-block!]
		args	[ptr-array!]
		return: [instr-phi!]
		/local
			phi [instr-phi!]
	][
		phi: as instr-phi! malloc size? instr-phi!
		phi/header: INS_PHI
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
		if n-vars > 0 [
			either parent <> null [
				ctx/cur-vals: parent/cur-vals
				ctx/ssa-vars: parent/ssa-vars
			][
				ctx/cur-vals: ptr-array/make n-vars
				ctx/ssa-vars: ptr-array/make n-vars
			]
		]
		ctx
	]

	init-merge: func [
		m		[ssa-merge!]
	][
		m/block: make-bb
		m/cur-vals: null
		m/pred-vals: ptr-array/make 2
		m/n-preds: 0
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
		unless ctx/blk-closed? [
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

	make-goto: func [
		target	[basic-block!]
		return: [instr!]
		/local
			g	[instr-goto!]
			arr [array-value!]
	][
		g: as instr-goto! malloc size? instr-goto!
		INIT_ARRAY_VALUE(arr target)
		set-succs as instr-end! g as ptr-array! :arr
		as instr! g
	]

	add-goto: func [
		target	[basic-block!]
		ctx		[ssa-ctx!]
	][
		unless ctx/blk-closed? [
			ctx/blk-closed?: yes
			block-append-instr ctx/block make-goto target
		]
	]

	add-if: func [
		cond	[instr!]
		t-blk	[basic-block!]
		f-blk	[basic-block!]
		ctx		[ssa-ctx!]
		/local
			i	[instr-if!]
			arr [array-value!]
	][
		i: as instr-if! malloc size? instr-if!
		i/header: INS_IF
		i/cond: cond
		i/t-blk: t-blk
		i/f-blk: f-blk

		INIT_ARRAY_VALUE(arr cond)
		set-inputs as instr! i as ptr-array! :arr

		ctx/blk-closed?: yes
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
	][
		op: as instr-op! malloc size? instr-op!
		op/header: opcode
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
	][
		set-inputs as instr! op args
		unless ctx/blk-closed? [append as instr! op ctx]
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
		op: make-op OP_DEFAULT_VALUE 0 null type
		add-op op null ctx
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
		block-append-instr ctx/block as instr! v
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
			ssa-ctx [ssa-ctx! value]
			graph	[ir-fn!]
			stmt	[rst-stmt!]
			n		[integer!]
			kv		[int-ptr!]
			var		[var-decl!]
			decls	[int-ptr!]
	][
		graph: make-ir-fn fn
		init-ssa-ctx :ssa-ctx null ctx/n-ssa-vars graph/start-bb

		if ctx/n-ssa-vars > 0 [
			decls: ctx/decls
			n: hashmap/size? decls
			kv: null
			loop n [
				kv: hashmap/next decls kv
				var: as var-decl! kv/2
				if NODE_TYPE(var) = RST_VAR_DECL [
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

		graph
	]
]