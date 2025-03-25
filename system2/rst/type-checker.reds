Red/System [
	File: 	 %type-checker.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

mark-written-loop: func [
	ssa		[ssa-var!]
	idx		[integer!]
	/local
		n	[integer!]
		arr [ptr-array!]
		p	[int-ptr!]
][
	n: idx and 1Fh
	either n = idx [		;-- idx < 32
		ssa/loop-bset: ssa/loop-bset or (1 << n)
	][
		n: idx / 32
		arr: ssa/extra-bset
		either null? arr [
			arr: ptr-array/make n
			ssa/extra-bset: arr
		][
			if n > arr/length [
				arr: ptr-array/grow arr n
				ssa/extra-bset: arr
			]
		]
		p: as int-ptr! ARRAY_DATA(arr)
		p: p + (n - 1)
		n: idx % 32
		p/value: p/value or (1 << n)
	]
]

written-in-loop?: func [
	ssa		[ssa-var!]
	idx		[integer!]
	return: [logic!]
	/local
		n	[integer!]
		arr [ptr-array!]
		p	[int-ptr!]
][
	n: idx and 1Fh
	either n = idx [		;-- idx < 32
		ssa/loop-bset >>> n and 1 <> 0
	][
		n: idx / 32
		arr: ssa/extra-bset
		if any [
			null? arr
			n > arr/length
		][return false]
		p: as int-ptr! ARRAY_DATA(arr)
		p: p + (n - 1)
		n: idx % 32
		p/value >>> n and 1 <> 0
	]
]

parse-type: func [
	blk		[red-block!]
	ctx		[context!]
	return: [rst-type!]
	/local
		t	[rst-type!]
		saved-blk [red-block!]
][
	enter-block(blk)
	t: type-checker/resolve-type block/rs-head blk block/rs-tail blk ctx
	exit-block
	t
]

parse-struct: func [
	spec	[red-block!]
	ctx		[context!]
	return: [rst-type!]
	/local
		st	[struct-type!]
		val [cell!]
		end [cell!]
		n	[integer!]
		p	[struct-field!]
		ty	[rst-type!]
		saved-blk [red-block!]
][
	val: block/rs-head spec
	end: block/rs-tail spec
	n: (as-integer end - val) >> 5
	if zero? n [throw-error [spec "empty struct"]]

	enter-block(spec)
	p: as struct-field! malloc n * size? struct-field!
	st: xmalloc(struct-type!)
	SET_TYPE_KIND(st RST_TYPE_STRUCT)
	st/size: -1
	st/n-fields: n
	st/fields: p

	while [val < end][
		either T_WORD?(val) [
			p/name: as red-word! val
		][
			throw-error [val "expect a word!"]
		]
		val: parser/expect-next val end TYPE_BLOCK
		ty: parse-type as red-block! val ctx
		p/type: either ty <> TYPE_RESOLVING [ty][as rst-type! st]
		p: p + 1
		val: val + 1
	]
	exit-block

	as rst-type! st
]

resolve-typeref: func [
	tref	[cell!]
	ctx		[context!]
	return: [rst-type!]
][
	either T_BLOCK?(tref) [
		parse-type as red-block! tref ctx
	][
		type-checker/resolve-type tref tref ctx
	]
]

type-checker: context [
	checker: declare visitor!
	init: does [
		checker/visit-assign:		as visit-fn! :visit-assign
		checker/visit-literal:		as visit-fn! :visit-literal
		checker/visit-lit-array:	as visit-fn! :visit-lit-array
		checker/visit-bin-op:		as visit-fn! :visit-bin-op
		checker/visit-var:			as visit-fn! :visit-var
		checker/visit-fn-call:		as visit-fn! :visit-fn-call
		checker/visit-native-call:	as visit-fn! :visit-native-call
		checker/visit-if:			as visit-fn! :visit-if
		checker/visit-while:		as visit-fn! :visit-while
		checker/visit-until:		as visit-fn! :visit-until
		checker/visit-break:		as visit-fn! :visit-break
		checker/visit-continue:		as visit-fn! :visit-continue
		checker/visit-return:		as visit-fn! :visit-return
		checker/visit-comment:		as visit-fn! :visit-comment
		checker/visit-case:			as visit-fn! :visit-case
		checker/visit-switch:		as visit-fn! :visit-switch
		checker/visit-not:			as visit-fn! :visit-not
		checker/visit-size?:		as visit-fn! :visit-size?
		checker/visit-cast:			as visit-fn! :visit-cast
		checker/visit-declare:		as visit-fn! :visit-declare
		checker/visit-get-ptr:		as visit-fn! :visit-get-ptr
		checker/visit-path:			as visit-fn! :visit-path
		checker/visit-any-all:		as visit-fn! :visit-any-all
		checker/visit-throw:		as visit-fn! :visit-throw
		checker/visit-catch:		as visit-fn! :visit-catch
		checker/visit-assert:		as visit-fn! :visit-assert
		checker/visit-context:		as visit-fn! :visit-context
	]

	infer-type: func [
		var		[var-decl!]
		ctx		[context!]
		return: [rst-type!]
		/local
			saved-blk [red-block!]
	][
		if null? var/type [
			enter-block(var/blkref)
			var/type: case [
				var/typeref <> null [parse-type var/typeref ctx]
				var/init <> null [as rst-type! var/init/accept as int-ptr! var/init checker as int-ptr! ctx]
				true [
					throw-error [var/token "unused local variable" var/token]
					null
				]
			]
			exit-block
		]
		var/type
	]

	resolve-fn-type: func [
		ft		[fn-type!]
		ctx		[context!]
		/local
			pt	[ptr-ptr!]
			v	[var-decl!]
			n	[integer!]
			saved-blk [red-block!]
	][
		if ft/param-types <> null [exit]		;-- already resolved
		enter-block(ft/spec)

		n: ft/n-params
		if any [n > 0 n = -2][
			if n = -2 [n: 2]	;-- typed func
			pt: as ptr-ptr! malloc n * size? int-ptr!
			ft/param-types: pt
			v: ft/params
			while [v <> null][
				pt/value: as int-ptr! infer-type v ctx
				v: v/next
				pt: pt + 1
			]
		]
		either ft/ret-typeref <> null [
			ft/ret-type: parse-type ft/ret-typeref ctx
		][
			ft/ret-type: type-system/void-type
		]

		exit-block
	]

	resolve-type: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [rst-type!]
		/local
			c	[context!]
			w	[red-word!]
			sym [integer!]
			val	[ptr-ptr!]
			t	[rst-type!]
			ft	[fn-type!]
			t1	[unresolved-type!]
	][
		w: as red-word! pc
		sym: symbol/resolve w/symbol
		if sym = k_pointer! [
			t: parse-type as red-block! parser/expect-next pc end TYPE_BLOCK ctx
			return make-ptr-type t
		]
		if sym = k_struct! [
			t: parse-struct as red-block! parser/expect-next pc end TYPE_BLOCK ctx
			pc: pc + 2
			if pc < end [
				w: as red-word! pc
				if k_value = symbol/resolve w/symbol [SET_STRUCT_VALUE(t)]
			]
			return t
		]
		if sym = k_function! [
			ft: parser/parse-fn-spec as red-block! parser/expect-next pc end TYPE_BLOCK null
			resolve-fn-type ft ctx
			return as rst-type! ft
		]

		c: ctx
		until [
			val: hashmap/get c/typecache sym
			c: c/parent
			any [null? c val <> null]
		]
		if null? val [throw-error [pc "undefined type:" w]]

		pc: pc + 1
		t1: as unresolved-type! val/value
		switch TYPE_KIND(t1) [
			RST_TYPE_UNRESOLVED [
				SET_TYPE_KIND(t1 RST_TYPE_RESOLVING)
				val/value: as int-ptr! resolve-typeref t1/typeref ctx
			]
			RST_TYPE_RESOLVING [	;-- structure self-reference
				if pc < end [throw-error [pc "invalid syntax"]]
				return TYPE_RESOLVING
			]
			default [0]
		]
		t: as rst-type! val/value
		if all [pc < end TYPE_KIND(t) = RST_TYPE_STRUCT][
			w: as red-word! pc
			if k_value = symbol/resolve w/symbol [SET_STRUCT_VALUE(t)]
		]
		t
	]

	check-expr: func [
		msg			[c-string!]
		e			[rst-expr!]
		expected	[rst-type!]
		ctx			[context!]
		/local
			type	[rst-type!]
			int		[int-literal!]
			i		[integer!]
			t		[int-type!]
			f32		[red-float32!]
			f64		[red-float!]
	][
		type: e/type
		if null? type [
			type: as rst-type! e/accept as int-ptr! e checker as int-ptr! ctx
			e/type: type
		]
		if type/header = expected/header [exit]	;-- same type

		switch NODE_TYPE(e) [
			RST_INT [		;-- int literal
				int: as int-literal! e
				i: int/value
				switch TYPE_KIND(expected) [
					RST_TYPE_INT [
						t: as int-type! expected
						either all [i >= t/min i <= t/max][
							e/type: expected
						][
							if all [not INT_SIGNED?(t) i < 0][
								throw-error [e/token "negative number used as unsigned"]
							]
							if any [i < t/min i > t/max][
								throw-error [e/token "out of range:" t/min "-" t/max]
							]
						]
					]
					RST_TYPE_FLOAT [
						either FLOAT_32?(expected) [
							f32: as red-float32! e/token
							f32/header: TYPE_FLOAT
							f32/value: as float32! i
						][
							f64: as red-float! e/token
							f64/header: TYPE_FLOAT
							f64/value: as float! i
						]
						e/type: expected
					]
					default [0]
				]
			]
			RST_FLOAT [
				if all [FLOAT_TYPE?(expected) FLOAT_32?(expected)][
					f64: as red-float! e/token
					f32: as red-float32! f64
					f32/value: as float32! f64/value
					e/type: expected
				]
			]
			default [
				either type-system/promotable? type expected [
					e/cast-type: expected
				][
					throw-error [e/token msg "expected" type-name expected ", got" type-name type]
				]
			]
		]
	]

	check-stmts: func [
		stmt	[rst-stmt!]
		blk		[red-block!]
		ctx		[context!]
		return: [rst-type!]		;-- return type of last expression
		/local
			saved-blk [red-block!]
			t	[rst-type!]
	][
		enter-block(blk)
		while [stmt <> null][
			t: as rst-type! stmt/accept as int-ptr! stmt checker as int-ptr! ctx
			stmt: stmt/next
		]
		exit-block
		t
	]

	check-write: func [
		e		[rst-expr!]
		ctx		[context!]
		return: [rst-type!]
		/local
			decl	[var-decl!]
			len		[integer!]
			p		[int-ptr!]
			ssa		[ssa-var!]
			var		[variable!]
			path	[path!]
	][
		switch NODE_TYPE(e) [
			RST_VAR [
				var: as variable! e
				decl: var/decl
				if LOCAL_VAR?(decl) [
					ssa: decl/ssa
					if ssa/index = -1 [
						ssa/index: ctx/n-ssa-vars
						ctx/n-ssa-vars: ctx/n-ssa-vars + 1
					]
					p: as int-ptr! ctx/loop-stack/data
					len: ctx/loop-stack/length
					while [len > 0][
						mark-written-loop ssa p/len
						len: len - 1
					]
				]
				decl/type
			]
			RST_PATH [
				visit-path as path! e ctx
			]
			default [
				unreachable e/token
				null
			]
		]
	]

	push-loop: func [
		ctx		[context!]
		return: [integer!]
		/local
			n	[integer!]
	][
		n: ctx/n-loops
		vector/append-int ctx/loop-stack n
		ctx/n-loops: n + 1
		n
	]

	pop-loop: func [
		ctx		[context!]
	][
		vector/remove-last ctx/loop-stack
	]

	make-local-var: func [
		var		[var-decl!]
		t		[rst-type!]
		/local
			sv	[ssa-var!]
	][
		sv: var/ssa
		if null? sv [sv: make-ssa-var var]
		if sv/index <> -2 [
			sv/index: -2
			sv/instr: ir-graph/make-local-var t
		]
	]

	check-struct-value: func [
		var		[var-decl!]
		ctx		[context!]
		return: [rst-type!]
		/local t [rst-type!]
	][
		t: var/type
		if all [LOCAL_VAR?(var) STRUCT_VALUE?(t)][
			make-local-var var t
		]
		t
	]

	;; check assignment
	visit-assign: func [
		a [assignment!] ctx [context!] return: [rst-type!]
		/local
			ltype	[rst-type!]
			type	[rst-type!]
			var		[rst-expr!]
	][
		var: a/target
		ltype: check-write var ctx
		check-expr "Assignment:" a/expr ltype ctx
		ltype
	]

	visit-literal: func [e [literal!] ctx [context!] return: [rst-type!]][
		e/type
	]

	visit-lit-array: func [e [literal!] ctx [context!] return: [rst-type!]][
		e/type
	]

	visit-var: func [v [variable!] ctx [context!] return: [rst-type!] /local d [var-decl!]][
		d: v/decl
		infer-type d ctx
		check-struct-value d ctx
	]

	visit-if: func [e [if!] ctx [context!] return: [rst-type!]
		/local
			stmt		[rst-stmt!]
			tt			[rst-type!]
			tf			[rst-type!]
			ut			[rst-type!]
	][
		check-expr "Condition:" e/cond type-system/logic-type ctx
		tt: check-stmts e/t-branch e/true-blk ctx
		tf: either e/f-branch <> null [
			check-stmts e/f-branch e/false-blk ctx
		][null]
		ut: either null? tf [tt][type-system/unify tt tf]
		if null? ut [ut: type-system/void-type]
		e/type: ut
		ut
	]

	visit-while: func [w [while!] ctx [context!] return: [rst-type!]
		/local
			stmt		[rst-stmt!]
			saved-blk	[red-block!]
	][
		w/loop-idx: push-loop ctx
		stmt: w/cond
		enter-block(w/cond-blk)
		while [stmt/next <> null][		;-- check stmts except last one
			stmt/accept as int-ptr! stmt checker as int-ptr! ctx
			stmt: stmt/next
		]
		check-expr "While Condition:" as rst-expr! stmt type-system/logic-type ctx
		exit-block

		check-stmts w/body w/body-blk ctx

		pop-loop ctx
		type-system/void-type
	]

	visit-until: func [w [while!] ctx [context!] return: [rst-type!]
		/local
			stmt		[rst-stmt!]
			saved-blk	[red-block!]
	][
		w/loop-idx: push-loop ctx
		enter-block(w/body-blk)
	
		stmt: w/body
		while [stmt/next <> null][		;-- check stmts except last one
			stmt/accept as int-ptr! stmt checker as int-ptr! ctx
			stmt: stmt/next
		]
		w/cond: stmt
		check-expr "Until Condition:" as rst-expr! stmt type-system/logic-type ctx

		exit-block
		pop-loop ctx
		type-system/void-type
	]

	visit-break: func [b [break!] ctx [context!] return: [rst-type!]][
		if zero? ctx/loop-stack/length [throw-error [b/token "break must be in loop"]]
		type-system/void-type
	]

	visit-continue: func [v [continue!] ctx [context!] return: [rst-type!]][
		if zero? ctx/loop-stack/length [throw-error [v/token "continue must be in loop"]]
		type-system/void-type
	]

	visit-return: func [v [return!] ctx [context!] return: [rst-type!]][
		if NODE_FLAGS(ctx) and RST_FN_CTX = 0 [
			throw-error [v/token "exit/return is not allowed outside of a function"]
		]
		either v/expr <> null [check-expr "Return:" v/expr ctx/ret-type ctx][
			if ctx/ret-type <> type-system/void-type [
				throw-error [v/token "expected a return value"]
			]
		]
		type-system/void-type
	]

	visit-comment: func [v [rst-stmt!] ctx [context!] return: [rst-type!]][
		type-system/void-type
	]

	visit-throw: func [p [unary!] ctx [context!] return: [rst-type!]][
		check-expr "Throw:" p/expr type-system/integer-type ctx
		type-system/void-type
	]

	visit-catch: func [p [catch!] ctx [context!] return: [rst-type!]][
		check-stmts p/body as red-block! p/token ctx
		type-system/void-type
	]

	visit-native-call: func [nc [native-call!] ctx [context!] return: [rst-type!]
		/local
			pt [ptr-ptr!]
			fn [native!]
			arg [rst-expr!]
	][
		fn: nc/native
		pt: fn/param-types
		if nc/args <> null [
			arg: nc/args/next
			while [arg <> null][
				check-expr "Native Instr:" arg as rst-type! pt/value ctx
				arg: arg/next
				pt: pt + 1
			]
		]
		nc/type
	]

	visit-assert: func [p [unary!] ctx [context!] return: [rst-type!]][
		type-system/void-type
	]

	visit-context: func [c [context!] ctx [context!] return: [rst-type!]][
		check c
		type-system/void-type
	]

	visit-path: func [p [path!] ctx [context!] return: [rst-type!]
		/local var [var-decl!] type [rst-type!] t [integer!] m [member!]
	][
		var: p/receiver
		check-struct-value var ctx
		type: var/type
		t: TYPE_KIND(type)
		if any [t = RST_TYPE_PTR t = RST_TYPE_ARRAY][
			m: p/subs
			until [
				if m/expr <> null [check-expr "Path Index:" m/expr type-system/integer-type ctx]
				m: m/next
				null? m
			]
		]
		p/type
	]

	visit-any-all: func [e [any-all!] ctx [context!] return: [rst-type!] /local c [rst-expr!]][
		c: e/conds
		while [c <> null][
			check-expr "Any/All:" c type-system/logic-type ctx
			c: c/next
		]
		type-system/logic-type
	]

	visit-case: func [e [case!] ctx [context!] return: [rst-type!]][
		e/type: visit-if e/cases ctx
		e/type
	]

	visit-switch: func [s [switch!] ctx [context!] return: [rst-type!]
		/local
			cases		[switch-case!]
			t			[rst-type!]
			tt			[rst-type!]
			unified?	[logic!]
	][
		check-expr "Expr:" s/expr type-system/integer-type ctx

		unified?: yes
		tt: null
		cases: s/cases
		while [cases <> null][
			t: check-stmts cases/body as red-block! cases/token ctx
			either all [unified? tt <> null][
				tt: type-system/unify t tt
				if null? tt [unified?: no]
			][tt: t]
			cases: cases/next
		]

		if s/defcase <> null [
			cases: s/defcase
			t: check-stmts cases/body as red-block! cases/token ctx
			either all [unified? tt <> null][
				tt: type-system/unify t tt
				if null? tt [unified?: no]
			][tt: t]
		]
		t: either unified? [tt][type-system/void-type]
		s/type: t
		t
	]

	visit-not: func [u [unary!] ctx [context!] return: [rst-type!]
		/local
			t	[rst-type!]
			ty	[integer!]
	][
		t: as rst-type! u/expr/accept as int-ptr! u/expr checker as int-ptr! ctx
		ty: TYPE_KIND(t)
		if all [ty <> RST_TYPE_INT ty <> RST_TYPE_LOGIC][
			throw-error [u/token "expected type integer! or logic!"]
		]
		u/type: t
		t
	]

	visit-size?: func [u [unary!] ctx [context!] return: [rst-type!]][
		u/cast-type: either NODE_FLAGS(u) and RST_SIZE_TYPE <> 0 [
			resolve-typeref as cell! u/expr ctx
		][
			as rst-type! u/expr/accept as int-ptr! u/expr checker as int-ptr! ctx
		]
		type-system/integer-type
	]

	visit-get-ptr: func [g [get-ptr!] ctx [context!] return: [rst-type!]
		/local
			d	[var-decl!]
			e	[rst-expr!]
			t	[rst-type!]
			f	[fn!]
	][
		e: g/expr
		switch NODE_TYPE(e) [
			RST_VAR_DECL [
				d: as var-decl! e
				t: infer-type d ctx
				if LOCAL_VAR?(d) [make-local-var d t]
			]
			RST_FUNC [
				f: as fn! e
				t: f/type
			]
			default [t: as rst-type! g/expr/accept as int-ptr! e checker as int-ptr! ctx]
		]
		t: make-ptr-type t
		g/type: t
		t
	]

	visit-cast: func [c [cast!] ctx [context!] return: [rst-type!]
		/local
			t1 t2 [rst-type!]
	][
		;rst-printer/print-stmt as rst-stmt! c
		if c/type <> null [return c/type]

		t1: resolve-typeref c/typeref ctx
		c/type: t1
		t2: as rst-type! c/expr/accept as int-ptr! c/expr checker as int-ptr! ctx
		if conv_illegal = type-system/cast t2 t1 [
			throw-error [c/token "invalid type casting"]
		]
		c/expr/cast-type: t1
		t1
	]

	visit-declare: func [c [declare!] ctx [context!] return: [rst-type!]
		/local
			t1		[rst-type!]
	][
		t1: resolve-typeref c/typeref ctx
		c/type: t1
		t1
	]

	visit-fn-call: func [fc [fn-call!] ctx [context!] return: [rst-type!]
		/local
			ft	 	[fn-type!]
			arg		[rst-expr!]
			pt		[ptr-ptr!]
			type	[rst-type!]
			attr	[integer!]
	][
		;rst-printer/print-stmt as rst-stmt! fc
		;dprint "[Type Checker] visit-fn-call"
		if null? fc/type [resolve-fn-type as fn-type! fc/fn/type ctx]

		ft: as fn-type! fc/fn/type
		fc/type: ft/ret-type
		attr: FN_ATTRS(ft)
		either attr and (FN_VARIADIC or FN_TYPED) = 0 [
			pt: ft/param-types
			if fc/args <> null [
				arg: fc/args/next
				while [arg <> null][
					check-expr "Function Call:" arg as rst-type! pt/value ctx
					arg: arg/next
					pt: pt + 1
				]
			]
		][	;-- variadic/typed func, only infer type, no checking
			if fc/args <> null [
				arg: fc/args/next
				while [arg <> null][
					type: arg/type
					if null? type [
						type: as rst-type! arg/accept as int-ptr! arg checker as int-ptr! ctx
						arg/type: type
					]
					arg: arg/next
				]
			]
		]
		;dprint "[Type Checker] visit-fn-call done"
		fc/type
	]

	visit-bin-op: func [bin [bin-op!] ctx [context!] return: [rst-type!]
		/local
			op op2	[fn-type!]
			code sz [integer!]
			int 	[red-integer!]
			e right [rst-expr!]
			b		[bin-op!]
			ltype rtype [rst-type!]
	][
		;rst-printer/print-stmt as rst-stmt! bin
		right: bin/right
		ltype: as rst-type! bin/left/accept as int-ptr! bin/left checker as int-ptr! ctx
		rtype: as rst-type! right/accept as int-ptr! right checker as int-ptr! ctx
		either NODE_FLAGS(bin) and RST_INFIX_OP <> 0 [
			op: lookup-infix-op as-integer bin/op ltype rtype
			if null? op [throw-error [bin/left/token "argument type mismatch for:" bin/token]]

			code: FN_OPCODE(op)
			if any [code = OP_PTR_ADD code = OP_PTR_SUB][
				sz: ptr-value-size? ltype
				if sz > 1 [
					int: xmalloc(red-integer!)
					int/header: TYPE_INTEGER
					int/value: sz

					e: as rst-expr! parser/make-int as cell! int
					b: parser/make-bin-op as int-ptr! RST_OP_MUL right e right/token
					ADD_NODE_FLAGS(b RST_INFIX_OP)
					visit-bin-op b ctx
					bin/right: as rst-expr! b
				]
			]
		][
			assert bin/op <> null
			op: as fn-type! bin/op
		]
		bin/spec: op
		op/ret-type
	]

	make-cmp-op: func [
		op			[rst-op!]
		ltype		[rst-type!]
		rtype		[rst-type!]
		attrs		[integer!]
		return:		[fn-type!]
		/local
			ft		[fn-type!]
	][
		ft: as fn-type! malloc size? fn-type!
		ft/header: attrs << 16 or (op << 8) or RST_TYPE_FUNC
		ft/n-params: 2
		ft/param-types: parser/make-param-types ltype rtype
		ft/ret-type: type-system/logic-type
		ft
	]

	make-mixed-cmp: func [
		op			[rst-op!]
		ltype		[rst-type!]
		rtype		[rst-type!]
		return:		[fn-type!]
		/local
			swap?	[logic!]
			t		[rst-type!]
			attr	[integer!]
	][
		swap?: no
		attr: 0
		op: switch op [
			RST_OP_LT [OP_MIXED_LT]
			RST_OP_LTEQ [OP_MIXED_LTEQ]
			RST_OP_GT [swap?: yes OP_MIXED_LT]
			RST_OP_GTEQ [swap?: yes OP_MIXED_LTEQ]
		]
		if swap? [
			t: ltype
			ltype: rtype
			rtype: t
			attr: FN_COMMUTE
		]
		make-cmp-op op ltype rtype attr
	]

	commute: func [
		op		[rst-op!]
		ltype	[rst-type!]
		rtype	[rst-type!]
		return: [fn-type!]
	][
		make-cmp-op op rtype ltype FN_COMMUTE
	]

	lookup-infix-op: func [
		op			[integer!]
		ltype		[rst-type!]
		rtype		[rst-type!]
		return: 	[fn-type!]
		/local
			utype	[rst-type!]
			ft		[fn-type!]
	][
		ft: null
		case [
			all [op >= RST_OP_ADD op <= RST_OP_XOR][
				utype: type-system/unify ltype rtype
				if null? utype [utype: ltype]
				ft: switch TYPE_KIND(utype) [
					RST_TYPE_INT [op-cache/get-int-op op utype]
					RST_TYPE_FLOAT [
						either op <= RST_OP_REM [
							op-cache/get-float-op op utype
						][null]
					]
					default [
						op-cache/get-ptr-op op as ptr-type! utype
					]
				]
			]
			all [INT_TYPE?(ltype) op >= RST_OP_SHL op <= RST_OP_SHR][	; <<, >>, >>>
				ft: op-cache/get-int-op op ltype
			]
			any [op = RST_OP_EQ op = RST_OP_NE][		; =, <>
				utype: type-system/unify ltype rtype
				if null? utype [
					case [
						all [INT_TYPE?(ltype) INT_TYPE?(rtype)][
							op: either op = RST_OP_EQ [OP_MIXED_EQ][OP_MIXED_NE]
							ft: make-cmp-op op ltype rtype 0
						]
						FLOAT_TYPE?(ltype) [utype: ltype]
						FLOAT_TYPE?(rtype) [utype: rtype]
						true [0]
					]
				]
				if utype <> null [
					ft: switch TYPE_KIND(utype) [
						RST_TYPE_INT [op-cache/get-int-op op utype]
						RST_TYPE_FLOAT [op-cache/get-float-op op utype]
						RST_TYPE_LOGIC [op-cache/op-bool-eq]
						default [
							op-cache/get-ptr-op op as ptr-type! utype
						]
					]
				]
			]
			all [op >= RST_OP_LT op <= RST_OP_GTEQ][	; <, <=, >, >=
				utype: type-system/unify ltype rtype
				either null? utype [
					if all [INT_TYPE?(ltype) INT_TYPE?(rtype)][
						return make-mixed-cmp op ltype rtype
					]
					if FLOAT_TYPE?(rtype) [utype: rtype]
				][
					utype: ltype
				]
				ft: switch TYPE_KIND(utype) [
					RST_TYPE_INT [op-cache/get-int-op op utype]
					RST_TYPE_FLOAT [op-cache/get-float-op op utype]
					default [
						op-cache/get-ptr-op op as ptr-type! utype
					]
				]
			]
			true [null]
		]
		ft
	]

	resolve-types: func [
		ctx			[context!]
		/local
			types	[int-ptr!]
			n		[integer!]
			kv		[int-ptr!]
			t		[unresolved-type!]
	][
		types: ctx/typecache
		n: hashmap/size? types
		kv: null
		loop n [
			kv: hashmap/next types kv
			t: as unresolved-type! kv/2
			if TYPE_KIND(t) = RST_TYPE_UNRESOLVED [
				SET_TYPE_KIND(t RST_TYPE_RESOLVING)
				kv/2: as-integer resolve-typeref t/typeref ctx
			]
		]
	]

	check: func [
		ctx		[context!]
		/local
			stmt	[rst-stmt!]
			prev	[rst-stmt!]
			n		[integer!]
			kv		[int-ptr!]
			var		[var-decl!]
			decls	[int-ptr!]
			f		[fn!]
	][
		if null? ctx [exit]

		cur-blk: ctx/src-blk
		script: ctx/script

		resolve-types ctx

		decls: ctx/decls
		n: hashmap/size? decls
		kv: null
		loop n [
			kv: hashmap/next decls kv
			var: as var-decl! kv/2
			switch NODE_TYPE(var) [
				RST_VAR_DECL [
					infer-type var ctx
					if all [LOCAL_VAR?(var) null? var/ssa][make-ssa-var var]
				]
				RST_FUNC	 [
					f: as fn! var
					resolve-fn-type as fn-type! f/type ctx
				]
				default		 [0]
			]
		]

		stmt: ctx/stmts
		while [
			prev: stmt
			stmt: stmt/next
			stmt <> null
		][
			;rst-printer/print-stmt stmt
			stmt/accept as int-ptr! stmt checker as int-ptr! ctx
			if null? stmt/next [break]
		]

		if NODE_TYPE(stmt) <> RST_RETURN [
			either ctx/ret-type <> type-system/void-type [
				check-expr "Return:" as rst-expr! stmt ctx/ret-type ctx
				prev/next: as rst-stmt! parser/make-return stmt/token as rst-expr! stmt
			][
				if NODE_FLAGS(ctx) and RST_FN_CTX <> 0 [
					stmt/next: as rst-stmt! parser/make-return stmt/token null
				]
			]
		]

		assert ctx/loop-stack <> null
		vector/destroy ctx/loop-stack
		ctx/loop-stack: null
	]
]