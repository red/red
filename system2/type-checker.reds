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
			0
		]
	]

	resolve-fn-type: func [
		fn		[fn!]
		ctx		[context!]
	][
		0
	]

	;; check assignment
	visit-assign: func [
		a [assignment!] expected [rst-type!] return: [rst-type!]
		/local
			type	[rst-type!]
	][
		type: as rst-type! a/expr/accept as int-ptr! a/expr checker null	;-- expression's type
		
		null
	]

	visit-literal: func [e [literal!] expected [rst-type!] return: [rst-type!]][
		e/type
	]

	visit-var: func [v [variable!] expected [rst-type!] return: [rst-type!]][
		v/decl/type
	]

	visit-bin-op: func [bin [bin-op!] expected [rst-type!] return: [rst-type!]
		/local
			op	[fn-type!]
			ltype rtype [rst-type!]
	][
		ltype: as rst-type! bin/left/accept as int-ptr! bin/left checker as int-ptr! expected
		rtype: as rst-type! bin/right/accept as int-ptr! bin/right checker as int-ptr! expected
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
		ft/param-types: parser/make-params ltype rtype
		ft/ret-type: type-system/logic-type
		ft
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
			]
			all [op >= RST_OP_LT op <= RST_OP_GTEQ][	; <, <=, >, >=
				utype: type-system/unify ltype rtype
				if null? utype [
					case [
						all [INT_TYPE?(ltype) INT_TYPE?(rtype)][
							ft: null
						]
					]
					if FLOAT_TYPE?(rtype) [utype: rtype]
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
			type	[integer!]
			decls	[int-ptr!]
	][
		if null? ctx [exit]

		src-blk: ctx/src-blk
		script: ctx/script

		decls: ctx/decls
		n: hashmap/size? decls
		kv: null
		loop n [
			kv: hashmap/next decls kv
			var: as var-decl! kv/2
			switch NODE_TYPE(var) [
				RST_VAR_DECL [infer-type var ctx]
				RST_FUNC	 [resolve-fn-type as fn! var ctx]
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
		check ctx/child
		check ctx/next
	]
]