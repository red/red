Red/System [
	File: 	 %type-checker.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

type-checker: context [
	checker: declare visitor!

	infer-type: func [
		var		[var-decl!]
		ctx		[context!]
		/local
			type [rst-type!]
	][
		either var/init <> null [
			assert null? var/typeref
			var/type: as rst-type! var/init/accept as int-ptr! var/init checker null
		][
			assert var/typeref <> null
			var/type: fetch-type var/typeref ctx
		]
	]

	fetch-type: func [
		blk		[red-block!]
		ctx		[context!]
		return: [rst-type!]
		/local
			w	[red-word!]
			sym [integer!]
			val [ptr-ptr!]
	][
		w: as red-word! block/rs-head blk
		sym: symbol/resolve w/symbol
		until [
			val: hashmap/get ctx/typecache sym
			ctx: ctx/parent
			any [null? ctx val <> null]
		]
		if null? val [throw-error [blk "undefined type:" w]]
		as rst-type! val/value
	]

	resolve-fn-type: func [
		ft		[fn-type!]
		ctx		[context!]
		/local
			pt	[ptr-ptr!]
			v	[var-decl!]
			saved-blk [red-block!]
	][
		enter-block(ft/spec)

		assert ft/param-types = null
		pt: as ptr-ptr! malloc ft/n-params * size? int-ptr!
		ft/param-types: pt
		v: ft/params
		while [v <> null][
			pt/value: as int-ptr! fetch-type v/typeref ctx
			v: v/next
			pt: pt + 1
		]
		either ft/ret-typeref <> null [
			ft/ret-type: fetch-type ft/ret-typeref ctx
		][
			ft/ret-type: type-system/void-type
		]

		exit-block
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
	][
		type: e/type
		if null? type [
			type: as rst-type! e/accept as int-ptr! e checker as int-ptr! ctx
			e/type: type
		]
		if type/header = expected/header [exit]	;-- same type

		either NODE_TYPE(e) = RST_INT [		;-- int literal
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
				RST_TYPE_FLOAT [0]
				default [0]
			]
		][
			either type-system/promotable? type expected [
				e/cast-type: expected
			][
				throw-error [e/token msg "expected" type-name(expected) ", got" type-name(type)]
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
		var		[variable!]
		ctx		[context!]
		return: [rst-type!]
		/local
			decl	[var-decl!]
			ssa-v	[ssa-var!]
			flags	[integer!]
	][
		switch NODE_TYPE(var) [
			RST_VAR [
				decl: var/decl
				flags: NODE_FLAGS(decl)
				if flags and RST_VAR_LOCAL <> 0 [
					either NODE_FLAGS(decl) and RST_VAR_WRITE <> 0 [
						if null? decl/ssa [
							ssa-v: make-ssa-var
							ssa-v/index: ctx/n-ssa-vars
							decl/ssa: ssa-v
							ctx/n-ssa-vars: ctx/n-ssa-vars + 1
						]
					][
						ADD_NODE_FLAGS(decl RST_VAR_WRITE)
					]
				]
				decl/type
			]
			default [null]
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

	;; check assignment
	visit-assign: func [
		a [assignment!] ctx [context!] return: [rst-type!]
		/local
			ltype	[rst-type!]
			type	[rst-type!]
			var		[variable!]
	][
		var: a/target
		ltype: check-write var ctx
		check-expr "Assignment:" a/expr ltype ctx
		ltype
	]

	visit-literal: func [e [literal!] ctx [context!] return: [rst-type!]][
		e/type
	]

	visit-var: func [v [variable!] ctx [context!] return: [rst-type!]][
		v/decl/type
	]

	visit-if: func [e [if!] ctx [context!] return: [rst-type!]
		/local
			stmt		[rst-stmt!]
			saved-blk	[red-block!]
			tt			[rst-type!]
			tf			[rst-type!]
			ut			[rst-type!]
	][
		check-expr "Condition:" e/cond type-system/logic-type ctx
		tt: check-stmts e/t-branch e/true-blk ctx
		tf: either e/f-branch <> null [
			check-stmts e/f-branch e/false-blk ctx
		][null]
		either null? tf [tt][
			ut: type-system/unify tt tf
			either ut <> null [ut][type-system/void-type]
		]
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
		type-system/void-type
	]

	visit-break: func [b [break!] ctx [context!] return: [rst-type!]][
		type-system/void-type
	]

	visit-continue: func [v [continue!] ctx [context!] return: [rst-type!]][
		type-system/void-type
	]

	visit-fn-call: func [fc [fn-call!] ctx [context!] return: [rst-type!]
		/local
			ft	 	[fn-type!]
			arg		[rst-expr!]
			pt		[ptr-ptr!]
	][
		ft: as fn-type! fc/type
		if null? ft/param-types [resolve-fn-type ft ctx]

		arg: fc/args
		pt: ft/param-types
		while [arg <> null][
			check-expr "Function Call:" arg as rst-type! pt/value ctx
			arg: arg/next
			pt: pt + 1
		]

		ft/ret-type
	]

	visit-bin-op: func [bin [bin-op!] ctx [context!] return: [rst-type!]
		/local
			op	[fn-type!]
			ltype rtype [rst-type!]
	][
		ltype: as rst-type! bin/left/accept as int-ptr! bin/left checker as int-ptr! ctx
		rtype: as rst-type! bin/right/accept as int-ptr! bin/right checker as int-ptr! ctx
		either NODE_FLAGS(bin) and RST_INFIX_OP <> 0 [
			op: lookup-infix-op as-integer bin/op ltype rtype
			if null? op [throw-error [bin/left/token "argument type mismatch for:" bin/token]]
		][
			assert bin/op <> null
			op: as fn-type! bin/op
		]
		op/ret-type
	]

	checker/visit-assign:	as visit-fn! :visit-assign
	checker/visit-literal:	as visit-fn! :visit-literal
	checker/visit-bin-op:	as visit-fn! :visit-bin-op
	checker/visit-var:		as visit-fn! :visit-var
	checker/visit-fn-call:	as visit-fn! :visit-fn-call
	checker/visit-if:		as visit-fn! :visit-if
	checker/visit-while:	as visit-fn! :visit-while
	checker/visit-break:	as visit-fn! :visit-break
	checker/visit-continue:	as visit-fn! :visit-continue

	make-cmp-op: func [
		op			[rst-op!]
		ltype		[rst-type!]
		rtype		[rst-type!]
		return:		[fn-type!]
		/local
			ft		[fn-type!]
	][
		ft: as fn-type! malloc size? fn-type!
		ft/header: op << 8 or RST_TYPE_FUNC
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
	][
		swap?: no
		op: switch op [
			RST_OP_LT [RST_MIXED_LT]
			RST_OP_LTEQ [RST_MIXED_LTEQ]
			RST_OP_GT [swap?: yes RST_MIXED_LT]
			RST_OP_GTEQ [swap?: yes RST_MIXED_LTEQ]
		]
		if swap? [
			t: ltype
			ltype: rtype
			rtype: t
		]
		make-cmp-op op ltype rtype
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
						either op <= RST_OP_DIV [
							op-cache/get-float-op op utype
						][null]
					]
					RST_TYPE_PTR [null]
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
							op: either op = RST_OP_EQ [RST_MIXED_EQ][RST_MIXED_NE]
							ft: make-cmp-op op ltype rtype
						]
						FLOAT_TYPE?(ltype) [utype: ltype]
						FLOAT_TYPE?(rtype) [utype: rtype]
						true [0]
					]
				]
				if utype <> null [
					ft: switch TYPE_KIND(utype) [
						RST_TYPE_INT [op-cache/get-int-op op utype]
						RST_TYPE_FLOAT [
							either op <= RST_OP_DIV [
								op-cache/get-float-op op utype
							][null]
						]
						RST_TYPE_PTR [null]
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
					RST_TYPE_FLOAT [
						either op <= RST_OP_DIV [
							op-cache/get-float-op op utype
						][null]
					]
					RST_TYPE_PTR [null]
				]
			]
			true [null]
		]
		ft
	]

	check: func [
		ctx		[context!]
		/local
			stmt	[rst-stmt!]
			n		[integer!]
			kv		[int-ptr!]
			var		[var-decl!]
			decls	[int-ptr!]
			f		[fn!]
	][
		if null? ctx [exit]

		cur-blk: ctx/src-blk
		script: ctx/script

		decls: ctx/decls
		n: hashmap/size? decls
		kv: null
		loop n [
			kv: hashmap/next decls kv
			var: as var-decl! kv/2
			switch NODE_TYPE(var) [
				RST_VAR_DECL [infer-type var ctx]
				RST_FUNC	 [
					f: as fn! var
					resolve-fn-type as fn-type! f/type ctx
				]
				default		 [0]
			]
		]

		stmt: ctx/stmts
		while [
			stmt: stmt/next
			stmt <> null
		][
			stmt/accept as int-ptr! stmt checker as int-ptr! ctx
		]

		assert ctx/loop-stack <> null
		vector/destroy ctx/loop-stack
		ctx/loop-stack: null

		check ctx/child
		check ctx/next
	]
]